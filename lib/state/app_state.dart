// lib/state/app_state.dart — the single mutation funnel (§5.2), rewritten
// per P1-D-05/P1-D-06/P1-D-07/P1-D-10 (plan 01-05). Every state CHANGE in
// MotoNote passes through `_mutate`; no other member of `AppNotifier` may
// MUTATE `state` (DATA-06).
//
// P5-D-27 (05-02): one named exception. `hydrate()`'s no-write branch
// ADOPTS a freshly-loaded document into `state` through the private
// `_adopt` below — nothing is persisted, `updatedAt` is not bumped, no
// reschedule and no backup are owed, because nothing changed. This is not a
// second writer of `state`: `build()` already establishes that the initial
// value of `state` does not come from `_mutate` either, so adoption was
// always narrower than "every assignment goes through `_mutate`" literally
// read. The distinction that matters is MUTATE vs ADOPT, not "assign" vs
// "don't assign" — see `_mutate`'s doc comment point 4 below for why.
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_service.dart';
import '../data/app_data_repository.dart';
import '../data/serial_queue.dart';
import '../domain/id.dart';
import '../domain/models/app_data.dart';
import '../domain/models/maintenance_item.dart';
import '../domain/models/misc.dart';
import '../domain/models/service_log.dart';
import '../domain/models/vehicle.dart';
import '../domain/odo.dart';
import '../notifications/notification_service.dart';
import 'onboarding_draft.dart';

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
        if (label == null) {
          // P5-D-27/P5-D-15: nothing to write — adopt, don't mutate. Every
          // app open used to reach `_mutate` unconditionally here, bumping
          // `updatedAt` and scheduling a silent ~200 KB upload 30 seconds
          // later on every cold start, regardless of whether anything
          // actually changed (RESEARCH Pitfall 9). `updatedAt` now means
          // "when the user last changed something", which is what 05-03's
          // "⚠ Bản trên Drive CŨ HƠN" comparison needs it to mean.
          _adopt(data);
        } else {
          await _mutate((_) => data.copyWith(deviceLabel: label));
        }
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

  /// P5-D-27: the hydration adoption exception's private, single-purpose
  /// step — the ONLY member of [AppNotifier] other than [_mutate] permitted
  /// to assign `state`, and permitted only because it does not constitute a
  /// mutation: no persist, no `updatedAt` bump, no reschedule, no backup.
  /// `hydrate()` is the sole caller. Do not reuse this for any future
  /// no-write case that skips a REAL change — [_mutate]'s "not
  /// short-circuiting" property (P1-D-06 point 5) still governs every path
  /// where something might have changed.
  void _adopt(AppData data) => state = data;

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
  /// 4. Sole mutator — this is the only member of [AppNotifier] that
  ///    MUTATES `state`. Every operation that commits a real change
  ///    (`addOdoReading`, `addServiceLog`, `recordBackupResult`, ...) goes
  ///    through this method. **P5-D-27 (05-02), one named exception:**
  ///    [_adopt] also assigns `state`, but only in `hydrate()`'s no-write
  ///    branch, where the freshly-loaded document is being ADOPTED, not
  ///    mutated — nothing changed, so nothing is persisted, `updatedAt` is
  ///    not bumped, and no reschedule/backup is owed. The distinction that
  ///    matters is mutate vs adopt, not "assigns `state`" read literally —
  ///    [build] already assigns the very first `state` outside this method
  ///    too, so the exception is narrower than it first reads.
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
  ///
  /// P3-D-11: also appends one [OdoReading] with `source: OdoSource.setup`,
  /// recording the odometer the user just typed at step 3. Before this,
  /// onboarding set `Vehicle.currentOdoKm` and created no reading at all, so
  /// the user's first real ODO update found a null previous reading,
  /// [refineAvgDailyKm] returned the average unchanged, and the P2-D-07 band
  /// seed survived at least one cycle longer than it should. `OdoSource.setup`
  /// has existed since Phase 1 and was written nowhere until now. This is an
  /// accepted, named modification of a function written in Phase 2 — not
  /// incidental drift — and Phase 6's offline error measurement (P2-D-10)
  /// reads the history this reading now heads. The reading's `date` reuses
  /// `vehicle.odoUpdatedAt` rather than a third `DateTime.now().toUtc()`
  /// call — `odoUpdatedAt` and `createdAt` above are each already their own
  /// separate `now()` call, and a third call here would put the reading
  /// microseconds ahead of the vehicle it describes.
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
      final setupReading = OdoReading(
        id: newId(),
        vehicleId: vehicle.id,
        odoKm: vehicle.currentOdoKm,
        date: vehicle.odoUpdatedAt,
        source: OdoSource.setup,
      );
      return current.copyWith(
        vehicles: [...current.vehicles, vehicle],
        items: [...current.items, ...items],
        odoReadings: [...current.odoReadings, setupReading],
      );
    });
  }

  /// ODO-03: appends a new [OdoReading] and moves all four of its
  /// [Vehicle] fields together (`currentOdoKm`, `odoUpdatedAt`,
  /// `avgDailyKm`, `avgDailyKmSource`) — updating the odometer without
  /// updating `odoUpdatedAt` would make [estimateOdo] add drift on top of
  /// a fresh reading. Built now even though nothing calls it until Phase
  /// 3's ODO-04 modal sheet (02-RESEARCH.md Pitfall 4), so that sheet finds
  /// this already shaped correctly instead of inventing a second
  /// persistence path.
  ///
  /// Two hardenings on §5.2's literal listing:
  ///
  /// 1. §5.2 resolves the vehicle with a throwing single-match search. A
  ///    `StateError` inside `_mutate`'s transform rejects the future this
  ///    method returns and, per P1-D-06's persist-before-assign contract,
  ///    correctly leaves `state` untouched — but it turns a caller mistake
  ///    into an unexplained failed save. Using a nullable index lookup and
  ///    returning the document unchanged on an unknown id is the honest
  ///    no-op instead.
  /// 2. `date` is caller-supplied wall-clock and gets persisted into
  ///    `OdoReading.date` and `Vehicle.odoUpdatedAt` — `.toUtc()` it at the
  ///    point of use, matching Phase 1's convention (`app_state.dart:162`,
  ///    `app_data.dart:40`) and keeping both sides of every later
  ///    `computeDue` comparison in the same frame (02-RESEARCH.md
  ///    Pitfall 2).
  Future<void> addOdoReading(String vehicleId, int odoKm, DateTime date) {
    return _mutate((current) {
      final vehicleIndex = current.vehicles.indexWhere(
        (v) => v.id == vehicleId,
      );
      if (vehicleIndex == -1) return current; // unknown id: honest no-op

      final vehicle = current.vehicles[vehicleIndex];
      // Take the previous reading BEFORE appending the new one, so the new
      // reading is never compared against itself.
      final prev = latestReadingFor(current, vehicleId);
      final utcDate = date.toUtc();
      final reading = OdoReading(
        id: newId(),
        vehicleId: vehicleId,
        odoKm: odoKm,
        date: utcDate,
        // source stays at its OdoSource.manual default here — Phase 3's
        // service-log path supplies OdoSource.service, and onboarding's
        // setup reading is Phase 3's ODO-04 territory too.
      );
      final refined = refineAvgDailyKm(vehicle, reading, prev);

      final vehicles = [...current.vehicles];
      vehicles[vehicleIndex] = vehicle.copyWith(
        currentOdoKm: odoKm,
        odoUpdatedAt: utcDate,
        avgDailyKm: refined.avgDailyKm,
        avgDailyKmSource: refined.source,
      );

      return current.copyWith(
        odoReadings: [...current.odoReadings, reading],
        vehicles: vehicles,
      );
    });
  }

  /// BKP-08/P5-D-04: the whole-document replace behind the restore sheet
  /// (`lib/ui/backup/restore_sheet.dart`). One `_mutate` call whose
  /// transform DISCARDS `current` entirely and returns the downloaded
  /// document, following `completeOnboarding`'s shape above — a real
  /// overwrite, not a merge (D-06, D-24).
  ///
  /// Two things this method deliberately does NOT do:
  /// 1. It does not suppress the backup. The restored data is now the
  ///    device's own canonical data and should go back up like any other
  ///    write; `_mutate`'s unconditional `scheduleDebounced()` call is
  ///    correct here — the backup-skip path belongs to undo (P5-D-08),
  ///    which is 05-05, not to restore.
  /// 2. It does not validate or migrate `downloaded`. `restoreFrom` takes a
  ///    fully constructed [AppData]; that boundary is
  ///    `DriveService.download()` (`migrateRaw` + `AppData.fromJson`), so
  ///    this method has exactly one job.
  ///
  /// T-05-04/P5-D-24: every `ServiceLog.photoPaths` and `Vehicle.photoPath`
  /// is stripped before the document is committed. The restore sheet tells
  /// the user in so many words that receipt photos are not restored (D-20),
  /// so keeping paths that point at files which do not exist on this device
  /// would make the document disagree with what the app just said — and it
  /// closes `01-SECURITY.md`'s carried-forward accepted risk R-01 while the
  /// fields are still empty in practice (photo capture is BL-03, backlog).
  Future<void> restoreFrom(AppData downloaded) async {
    await _mutate(
      (_) => downloaded.copyWith(
        logs: downloaded.logs
            .map((log) => log.copyWith(photoPaths: const []))
            .toList(),
        vehicles: downloaded.vehicles
            .map((v) => v.copyWith(photoPath: null))
            .toList(),
      ),
    );
    // What lets a restore started from `/data-issue` actually leave that
    // screen — the router's redirect re-reads this on every invocation
    // instead of a value captured once at `buildRouter()` call time
    // (P5-D-04, RESEARCH Pitfall 8).
    ref
        .read(hydrateOutcomeProvider.notifier)
        .setOutcome(HydrateOutcome.loaded);
  }

  /// LOG-01…03: records one workshop visit across however many items were
  /// actually touched, taking the domain [ServiceLog] type directly — never
  /// a draft/form type from `lib/ui/`. Plan 02 just finished removing exactly
  /// that inversion (BL-01, P3-D-18), and this method is the place research
  /// names as most likely to recreate it, so the sheet converts to
  /// [ServiceLog]/[ServiceLogEntry] only at save time and this signature
  /// never accepts anything else.
  ///
  /// Shares `addOdoReading`'s exact shape above it: a nullable vehicle
  /// lookup (honest no-op on an unknown id), the previous reading taken
  /// BEFORE the new one is built, `.toUtc()` at the point of use, and all
  /// four `Vehicle` fields moved together through [refineAvgDailyKm].
  ///
  /// **P3-D-08 — the deliberate hardening over §5.2's literal listing.**
  /// §5.2 only appends an `OdoReading`; it leaves `Vehicle` untouched. Under
  /// that listing, a user who logs "today, 18.420 km" at a workshop would
  /// return to a home screen still reading a stale, drifted estimate — the
  /// single most valuable measurement this app is ever likely to receive
  /// would refine nothing. Do not "fix" this back toward the source listing.
  ///
  /// **P3-D-06** — `ServiceLog.totalCostVnd` is derived here, once, as the
  /// sum of the entries' `costVnd` (null treated as zero) and stored via
  /// `copyWith` — never accepted as input, so the two figures can never
  /// disagree.
  ///
  /// **LOG-02** — only entries with `resetsCycle: true` update their item's
  /// baseline (`lastServiceOdo`, `lastServiceDate`, `baselineIsGuess`,
  /// `partBrand`, `partSpec`, `lastCostVnd`); a `resetsCycle: false` entry
  /// (inspection without replacement) touches nothing on its item even when
  /// it carries a brand, a spec or a cost (T-03-15). Each of the three
  /// part-data fields falls back to the item's existing value when the
  /// entry's own is null, so a blank brand field on save never erases what
  /// was already known (T-03-14).
  Future<void> addServiceLog(ServiceLog log) {
    return _mutate((current) {
      final vehicleIndex = current.vehicles.indexWhere(
        (v) => v.id == log.vehicleId,
      );
      if (vehicleIndex == -1) return current; // unknown id: honest no-op

      final vehicle = current.vehicles[vehicleIndex];
      // Take the previous reading BEFORE appending the new one, so the new
      // reading is never compared against itself.
      final prev = latestReadingFor(current, log.vehicleId);
      final reading = OdoReading(
        id: newId(),
        vehicleId: log.vehicleId,
        odoKm: log.odoKm,
        date: log.date.toUtc(),
        source: OdoSource.service, // LOG-03
      );
      final refined = refineAvgDailyKm(vehicle, reading, prev);

      final vehicles = [...current.vehicles];
      vehicles[vehicleIndex] = vehicle.copyWith(
        currentOdoKm: log.odoKm,
        odoUpdatedAt: reading.date,
        avgDailyKm: refined.avgDailyKm,
        avgDailyKmSource: refined.source,
      );

      // P3-D-06: the total is computed here, once — never accepted as
      // input, so ServiceLog.totalCostVnd and the sum of its entries'
      // costVnd can never disagree.
      final totalCost = log.entries.fold<int>(
        0,
        (sum, e) => sum + (e.costVnd ?? 0),
      );

      // LOG-02: only resetsCycle:true entries touch the item's baseline.
      final resetIds = log.entries
          .where((e) => e.resetsCycle)
          .map((e) => e.itemId)
          .toSet();
      final items = current.items.map((item) {
        if (!resetIds.contains(item.id)) return item;
        // This lookup is safe unlike an ordinary throwing search: entry.itemId
        // values come from THIS SAME log's own entries list, so a match is
        // guaranteed by construction. Every lookup against a caller-supplied
        // id (the vehicle, above) still uses the nullable indexWhere form.
        final entry = log.entries.firstWhere((e) => e.itemId == item.id);
        return item.copyWith(
          lastServiceOdo: log.odoKm,
          lastServiceDate: reading.date,
          baselineIsGuess: false, // LOG-02: no longer a guessed baseline
          partBrand: entry.partBrand ?? item.partBrand,
          partSpec: entry.partSpec ?? item.partSpec,
          lastCostVnd: entry.costVnd ?? item.lastCostVnd,
        );
      }).toList();

      return current.copyWith(
        logs: [
          ...current.logs,
          log.copyWith(totalCostVnd: totalCost),
        ],
        odoReadings: [...current.odoReadings, reading],
        items: items,
        vehicles: vehicles,
      );
    });
  }

  /// NOTE-01: appends a new [Note] to the document. The caller (the note
  /// editor) supplies both `id` and `createdAt`/`updatedAt` rather than this
  /// method fabricating them — the editor needs the id up front to tell a
  /// create from an edit before the mutation ever runs. A single `_mutate`
  /// call, no other lookup: an append can never fail on an unknown id the
  /// way an update/delete can.
  Future<void> addNote(Note note) {
    return _mutate(
      (current) => current.copyWith(notes: [...current.notes, note]),
    );
  }

  /// NOTE-01: replaces an existing [Note] **at its current index** rather
  /// than removing and re-appending, so editing a note never reorders
  /// `AppData.notes`. An unknown id is an honest no-op — same convention as
  /// `addOdoReading`'s vehicle lookup above — never an insert, since a
  /// caller passing an id this document does not have is a bug to surface,
  /// not paper over. `updatedAt` is set here to the current UTC instant
  /// rather than trusting whatever the caller's copy carried.
  Future<void> updateNote(Note note) {
    return _mutate((current) {
      final i = current.notes.indexWhere((n) => n.id == note.id);
      if (i == -1) return current; // unknown id: honest no-op, never an insert
      final notes = [...current.notes];
      notes[i] = note.copyWith(updatedAt: DateTime.now().toUtc());
      return current.copyWith(notes: notes);
    });
  }

  /// NOTE-01: removes a note by id. Deleting an id that is already gone is
  /// naturally a no-op under this shape (the filter simply keeps everything)
  /// — do not "fix" this into a throwing lookup; an absent id here is not an
  /// error, it is the same state the caller wanted.
  Future<void> deleteNote(String id) {
    return _mutate(
      (current) => current.copyWith(
        notes: current.notes.where((n) => n.id != id).toList(),
      ),
    );
  }

  /// NOTE-02: flips one note's `pinned` flag in place. Implemented as its
  /// own method rather than making the editor round-trip a whole [Note] for
  /// a one-field change — the editor's AppBar pin `IconButton` calls this
  /// directly for an already-saved note, so a single tap persists
  /// immediately with no save round-trip through the rest of the record.
  /// Same nullable-lookup, honest-no-op discipline as `updateNote` above.
  Future<void> toggleNotePinned(String id) {
    return _mutate((current) {
      final i = current.notes.indexWhere((n) => n.id == id);
      if (i == -1) return current; // unknown id: honest no-op
      final notes = [...current.notes];
      notes[i] = notes[i].copyWith(
        pinned: !notes[i].pinned,
        updatedAt: DateTime.now().toUtc(),
      );
      return current.copyWith(notes: notes);
    });
  }

  /// 04-03: the single `_mutate`-routed entry point for every settings
  /// write this phase's Cài đặt screen and home-screen permission prompt
  /// make — one general method rather than eight near-identical named
  /// setters (five toggles/pickers plus the two permission-flow flags),
  /// because that many one-field methods would be pure ceremony for what
  /// is structurally the same operation every time.
  ///
  /// Two things load-bearing here, neither obvious from the one-line body:
  /// 1. Because this goes through `_mutate` like every other mutation
  ///    (DATA-06 — `_mutate` is the sole writer; nothing here may assign
  ///    `state` directly), every settings change automatically persists
  ///    before it is assigned (P1-D-06) **and** triggers `rescheduleAll`
  ///    (P1-D-05). Changing `notifyHour` or `leadDays` therefore re-plans
  ///    every notification with no extra wiring — exactly what §10.4's
  ///    "call it on every state change" asks for, and why NOTIF-05's
  ///    second half needed no new code here.
  /// 2. `transform` receives `current.settings`, not `current` — callers
  ///    never need to reach through `AppData` themselves.
  Future<void> updateSettings(Settings Function(Settings) transform) {
    return _mutate(
      (current) => current.copyWith(settings: transform(current.settings)),
    );
  }

  /// NOTIF-11: records that a notification was *opened* — not that one
  /// fired. A local notification firing never wakes Dart code (there is no
  /// observable OS "fired" event), so the only two honest moments this can
  /// be written are the warm tap callback and the cold-start launch-details
  /// read, both wired in `main.dart`. Despite the field's name
  /// (`lastNotificationFiredAt`), this is deliberately "opened" — §10.6's
  /// own Vietnamese text says "được mở" (RESEARCH.md Assumption A3). Goes
  /// through `_mutate` like every other mutation (DATA-06).
  Future<void> recordNotificationOpened({DateTime? now}) {
    return _mutate(
      (current) => current.copyWith(
        settings: current.settings.copyWith(
          lastNotificationFiredAt: (now ?? DateTime.now()).toUtc(),
        ),
      ),
    );
  }

  /// BKP-06/BKP-07: the only writer of either `lastBackupAt` or
  /// `lastBackupError` — [RealBackupService.runSilent]'s `_recordResult`
  /// and the manual "Sao lưu ngay" row both call this, never `Settings`
  /// fields directly. On success, `lastBackupAt` moves to the outcome's
  /// timestamp and `lastBackupError` clears; on failure, `lastBackupError`
  /// is set to the mapped Vietnamese string from [kBackupErrorMessages]
  /// and `lastBackupAt` is left EXACTLY where it was — a failed attempt
  /// must never advance the timestamp, or the Settings line claims a
  /// backup that did not happen (prohibition P-05-03). Goes through
  /// `_mutate` like every other real change (DATA-06); the caller is
  /// responsible for calling `pauseNextAutomaticBackup()` first so this
  /// write's own post-persist debounce trigger does not start another cycle
  /// (P5-D-19).
  Future<void> recordBackupResult(BackupOutcome outcome) {
    return _mutate((current) {
      final settings = current.settings;
      return current.copyWith(
        settings: outcome.succeeded
            ? settings.copyWith(lastBackupAt: outcome.at, lastBackupError: null)
            : settings.copyWith(
                lastBackupError: outcome.code == null
                    ? settings.lastBackupError
                    : kBackupErrorMessages[outcome.code]!,
              ),
      );
    });
  }

  void _log(String message) {
    // ignore: avoid_print
    print('AppNotifier: $message');
  }
}

/// P5-D-04/RESEARCH Pitfall 8: promotes `HydrateOutcome` from a value
/// `buildRouter` used to capture once at router-construction time into live
/// state the router's `redirect` re-reads on every invocation. `main.dart`
/// seeds this with `hydrate()`'s return value before the router is built;
/// `AppNotifier.restoreFrom` above is the only method that advances it past
/// that seeded value.
class HydrateOutcomeNotifier extends Notifier<HydrateOutcome> {
  // Defaults to `notFound` deliberately: if anything ever fails to seed
  // this before the router is built, the app routes to onboarding, which
  // destroys nothing — the alternative defaults (`loaded` or either
  // data-issue variant) would route into a screen the user cannot leave.
  @override
  HydrateOutcome build() => HydrateOutcome.notFound;

  void setOutcome(HydrateOutcome outcome) => state = outcome;
}

final hydrateOutcomeProvider =
    NotifierProvider<HydrateOutcomeNotifier, HydrateOutcome>(
      HydrateOutcomeNotifier.new,
    );

final appProvider = NotifierProvider<AppNotifier, AppData>(AppNotifier.new);
