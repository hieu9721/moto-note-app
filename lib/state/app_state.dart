// lib/state/app_state.dart — the single mutation funnel (§5.2), rewritten
// per P1-D-05/P1-D-06/P1-D-07/P1-D-10 (plan 01-05). Every state change in
// MotoNote passes through `_mutate`; no other member of `AppNotifier` may
// assign `state` (DATA-06).
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_service.dart';
import '../data/app_data_repository.dart';
import '../data/serial_queue.dart';
import '../domain/id.dart';
import '../domain/models/app_data.dart';
import '../domain/models/maintenance_item.dart';
import '../domain/models/vehicle.dart';
import '../notifications/notification_service.dart';
import '../ui/onboarding/onboarding_draft.dart';

/// Supplies the [AppDataRepository]. P1-D-11 injects the `Directory` through
/// the repository's constructor instead of resolving it internally, so this
/// provider is the ONE place that needs the real documents directory —
/// `main.dart` overrides it with a repository built from what `path_provider`
/// returns. Left un-overridden, this throws loudly at startup instead of
/// silently resolving a wrong directory.
final repositoryProvider = Provider<AppDataRepository>(
  (_) => throw UnimplementedError(
    'repositoryProvider must be overridden in main.dart with an '
    'AppDataRepository built from the resolved application documents '
    'directory.',
  ),
);

/// What `hydrate()` found on disk, surfaced so the first frame (and Phase
/// 3's router) can decide where to go. Mirrors [AppDataLoadResult] exactly —
/// [schemaTooNew] must never be treated the same as [notFound] (P1-D-09),
/// since Phase 5's restore flow depends on that distinction surviving all
/// the way up from the repository.
enum HydrateOutcome {
  /// A document was loaded (primary or backup) and is now the current state.
  loaded,

  /// No document exists yet — first run. Route to onboarding.
  notFound,

  /// The primary document existed but could not be decoded; the repository
  /// has already quarantined it (P1-D-07). Route to onboarding — Phase 3 can
  /// say more once there is a screen for it.
  undecodable,

  /// The primary document is stamped with a schemaVersion newer than this
  /// build supports; the repository has already quarantined it. Do NOT
  /// route this like [notFound] — Phase 5's restore flow must stop a
  /// restore rather than overwrite existing good data with a document it
  /// cannot fully parse (P1-D-09). Phase 1 has no restore flow and no
  /// screen for this outcome yet, so state stays [AppData.empty] and the
  /// placeholder screen in `main.dart` reports it.
  schemaTooNew,
}

class AppNotifier extends Notifier<AppData> {
  late final AppDataRepository _repo;

  /// P1-D-06/T-01-11: serialises every [_mutate] call, so only one mutation
  /// is ever in flight against `appdata.json.tmp`. G-01-5: the serialisation
  /// mechanism itself is delegated to [SerialQueue], a pure-Dart class that
  /// can be tested under plain `dart test` — this field used to hold the
  /// future chain directly, which entangled the ordering property with
  /// `flutter_riverpod` and left DATA-03 with zero automated coverage.
  final SerialQueue _mutations = SerialQueue();

  @override
  AppData build() {
    _repo = ref.read(repositoryProvider);
    return AppData.empty(); // real data arrives via hydrate()
  }

  /// Called once at startup, before `runApp` (DATA-07). Handles all four
  /// [AppDataLoadResult] outcomes exhaustively — the switch below has no
  /// default clause, so the compiler forces every future variant to be
  /// handled here too.
  Future<HydrateOutcome> hydrate() async {
    final result = await _repo.load();
    switch (result) {
      case AppDataLoaded(:final data):
        final label = data.deviceLabel.isEmpty
            ? await _readDeviceLabel()
            : null;
        await _mutate(
          (_) => label == null ? data : data.copyWith(deviceLabel: label),
        );
        return HydrateOutcome.loaded;

      case AppDataNotFound():
        _log('no document found — routing to onboarding');
        return HydrateOutcome.notFound;

      case AppDataUndecodable(:final quarantinePath):
        _log(
          'primary undecodable, quarantined to $quarantinePath — routing '
          'to onboarding',
        );
        return HydrateOutcome.undecodable;

      case AppDataSchemaTooNew(
        :final found,
        :final supported,
        :final quarantinePath,
      ):
        // P1-D-09: do not start from empty as if this were a fresh install.
        // The document exists — this build is simply too old to read it.
        // Phase 5's restore flow must stop the restore rather than
        // overwrite good data with one it cannot fully parse; there is no
        // restore flow yet in Phase 1, so nothing more happens here than
        // logging and surfacing the outcome to the placeholder screen.
        _log(
          'primary schemaVersion $found is newer than supported $supported '
          '— quarantined to $quarantinePath',
        );
        return HydrateOutcome.schemaTooNew;
    }
  }

  /// P1-D-10: reads the device model (e.g. "Redmi Note 12") to seed
  /// `deviceLabel` when it is empty. Guarded by platform and wrapped in
  /// try/catch — an unlabelled backup is a nuisance, a blocked launch is a
  /// bug.
  Future<String?> _readDeviceLabel() async {
    if (!Platform.isAndroid) return null;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.model;
    } catch (_) {
      return null;
    }
  }

  /// The single funnel every state change passes through (DATA-06). Five
  /// properties all matter here:
  ///
  /// 1. Serialised — delegated to [_mutations] (a [SerialQueue]) so two
  ///    overlapping calls can never interleave their writes to
  ///    `appdata.json.tmp` (T-01-11 / G-01-5).
  /// 2. Persist before assign (P1-D-06, inverting §5.2's order) — `next` is
  ///    computed and saved to disk before `state` is ever touched. The
  ///    future this method returns rejects IF AND ONLY IF the transform or
  ///    the save fails; a failed save leaves `state` untouched and rethrows
  ///    to the caller (T-01-12), so memory and disk never diverge silently.
  /// 3. Ordered — after the assignment, `state = next` has already
  ///    committed the mutation, so no later step can report it as a
  ///    failure (G-01-W3). The notification reschedule and the debounced
  ///    backup are each run behind their own [runReportingFailure] boundary
  ///    and are still called every time.
  /// 4. Sole writer — this is the only member of [AppNotifier] that assigns
  ///    `state`. Every future operation (`addOdoReading`, `addServiceLog`,
  ///    ...) goes through this method; none of them exist yet (Phases 2/3).
  /// 5. Not short-circuiting — an identity function still bumps `updatedAt`
  ///    and still writes. Whether anything "really" changed is not this
  ///    method's decision to make.
  Future<void> _mutate(AppData Function(AppData) f) {
    return _mutations.enqueue(() async {
      final next = f(state).copyWith(updatedAt: DateTime.now().toUtc());
      await _repo.save(next);
      state = next;
      await runReportingFailure(
        () => ref.read(notificationSchedulerProvider).rescheduleAll(state),
        onError: (e) =>
            _log('rescheduleAll failed after a successful save: $e'),
      );
      await runReportingFailure(
        () async => ref.read(backupServiceProvider).scheduleDebounced(),
        onError: (e) =>
            _log('scheduleDebounced failed after a successful save: $e'),
      );
    });
  }

  /// ONB-05: the six-step onboarding flow's single commit point. Builds one
  /// [Vehicle] plus the selected [MaintenanceItem] rows (P2-D-05 — only
  /// checked catalog codes, via [OnboardingDraft.buildSelectedItems]) and
  /// commits both through exactly one [_mutate] call — the same call shape
  /// [hydrate] already uses above. Appending (`[...current.vehicles,
  /// vehicle]`), never replacing: `AppData.vehicles` is a list of vehicles
  /// and Phase 6's SET-01 manages several.
  Future<void> completeOnboarding(OnboardingDraft draft) {
    return _mutate((current) {
      final vehicle = Vehicle(
        id: newId(),
        name: draft.name ?? '', // ONB-02: name/plate is skippable
        type: draft.type!,
        plate: draft.plate,
        currentOdoKm: draft.currentOdoKm!,
        odoUpdatedAt: DateTime.now().toUtc(),
        avgDailyKm: draft.avgDailyKm!,
        avgDailyKmSource: AvgKmSource.user, // P2-D-06
        createdAt: DateTime.now().toUtc(),
      );
      final items = draft.buildSelectedItems(vehicle.id);
      return current.copyWith(
        vehicles: [...current.vehicles, vehicle],
        items: [...current.items, ...items],
      );
    });
  }

  void _log(String message) {
    // ignore: avoid_print
    print('AppNotifier: $message');
  }
}

final appProvider = NotifierProvider<AppNotifier, AppData>(AppNotifier.new);
