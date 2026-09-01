// lib/backup/backup_service.dart — the backup seam `_mutate` calls on every
// mutation (P1-D-05). 05-01 built the one manual path: "Sao lưu ngay" in
// Settings, wired through `runManual()`. This plan (05-02) fills in
// `scheduleDebounced()` for real, adds the three §7.5 automatic triggers
// (the debounce `Timer`, the `AppLifecycleState.paused` flush, and the
// cold-start >24h rule fired from `main.dart`) and the P5-D-19 one-shot
// suppression that makes writing the backup result safe to call from inside
// `_mutate` without an unbounded reschedule loop (P5-D-17).
import 'dart:async' show TimeoutException, Timer, unawaited;
import 'dart:io' show SocketException;

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart' show appProvider;
// `DetailedApiRequestError` arrives via `drive_service.dart`'s own
// re-export of the Drive v3 client library — this file never imports the
// Drive API package directly (acceptance criterion, task 2).
import 'drive_service.dart';
import 'google_auth.dart';

/// Schedules a debounced background backup after a mutation (§7.5). Real
/// implementations debounce for ~30s, then attempt a silent Drive upload
/// that never surfaces a dialog or a spinner (D-23).
abstract class BackupService {
  void scheduleDebounced();

  /// The one path 05-01 built — a user-triggered upload from Settings'
  /// "Sao lưu ngay" (BKP-07).
  Future<BackupOutcome> runManual();

  /// The silent path behind all three §7.5 automatic triggers (cold-start
  /// >24h, the debounce, the `paused` flush) — BKP-04/BKP-06. Structurally
  /// incapable of showing a dialog: it never reaches the interactive
  /// sign-in entry point.
  Future<void> runSilent();

  /// The P5-D-19 one-shot: consumed by the very next `scheduleDebounced()`
  /// call so that writing this cycle's own result (which itself routes
  /// through `_mutate`, whose unconditional post-persist call is
  /// `scheduleDebounced()`) cannot start an unbounded
  /// record-upload-record loop.
  void pauseNextAutomaticBackup();
}

/// The closed set P5-D-16 requires — only a value from this enum, mapped to
/// a Vietnamese string below, may ever reach `Settings.lastBackupError`.
/// Raw exception text never does: that field rides up to Drive and back
/// down onto another device, and a Drive API error object can carry
/// request URLs and account detail.
enum BackupErrorCode { needsReauth, networkError, unknown }

/// `needsReauth`'s string is BKP-04's verbatim mapped text. The other two
/// are invented — marked `[NEW, PROVISIONAL]` here and recorded verbatim in
/// `05-01-SUMMARY.md`.
const kBackupErrorMessages = <BackupErrorCode, String>{
  BackupErrorCode.needsReauth: 'Cần đăng nhập lại Google',
  // [NEW, PROVISIONAL]
  BackupErrorCode.networkError: 'Không có kết nối mạng',
  // [NEW, PROVISIONAL]
  BackupErrorCode.unknown: 'Lỗi không xác định',
};

/// A plain result the caller renders without re-deriving anything. `code`
/// is null both on success and on a user-cancelled sign-in — cancelling is
/// not a failure and has nothing to report.
class BackupOutcome {
  const BackupOutcome({required this.succeeded, required this.at, this.code});

  final bool succeeded;
  final DateTime? at;
  final BackupErrorCode? code;
}

/// Phase 1 placeholder, replaced by the real Google Drive-backed
/// implementation in Phase 5. Deliberately inert — no Google sign-in, no
/// Drive API call, no debounce timer belongs here yet.
class NoopBackupService implements BackupService {
  const NoopBackupService();

  @override
  void scheduleDebounced() {}

  @override
  Future<BackupOutcome> runManual() async =>
      const BackupOutcome(succeeded: false, at: null, code: null);

  @override
  Future<void> runSilent() async {}

  @override
  void pauseNextAutomaticBackup() {}
}

class RealBackupService with WidgetsBindingObserver implements BackupService {
  RealBackupService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;

  /// Non-reentrancy guard (RESEARCH Pitfall 6). Without it, two overlapping
  /// runs would each evaluate `DriveService`'s create-or-update decision
  /// against the same missing file and create two remote files. Shared by
  /// `runManual()` and `runSilent()` — only one Drive upload cycle may be
  /// in flight at a time regardless of which trigger started it.
  bool _inFlight = false;

  /// §7.5's 30-second debounce timer, owned by this service rather than by
  /// `app_state.dart` (P5-D-17) — `_LifecycleRescheduler` in `main.dart`
  /// registers its own observer too late to catch a cold start, which is
  /// exactly why this class needs its own `WidgetsBindingObserver` instead
  /// of reusing that one.
  Timer? _debounce;

  /// The P5-D-19 one-shot consumed by the very next `scheduleDebounced()`
  /// call. An in-memory field, deliberately not a `Settings` field — it
  /// only has to survive until the next mutation in this same process
  /// (RESEARCH Pitfall 11).
  bool _suppressNextSchedule = false;

  @override
  void pauseNextAutomaticBackup() => _suppressNextSchedule = true;

  @override
  void scheduleDebounced() {
    if (_suppressNextSchedule) {
      // The one-shot fires exactly once: this cycle's own result write
      // (`pauseNextAutomaticBackup()` immediately before
      // `recordBackupResult`) must not schedule another upload of the
      // document it just finished uploading.
      _suppressNextSchedule = false;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 30), () {
      _debounce = null;
      unawaited(runSilent());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    if (_debounce == null) return;
    // A flush, not an extra run (P5-D-17): Android can freeze the process
    // the instant it backgrounds, so a pending 30-second timer commonly
    // never fires at all. Cancel the pending cycle and run immediately
    // instead of waiting on it.
    _debounce!.cancel();
    _debounce = null;
    unawaited(runSilent());
  }

  /// Removes this service's lifecycle observer. `main.dart` owns a single
  /// long-lived `RealBackupService` for the app's process lifetime, so
  /// nothing calls this today — provided for symmetry with the
  /// registration above and for any future test harness that constructs
  /// and tears down a service per test.
  void dispose() => WidgetsBinding.instance.removeObserver(this);

  /// BKP-04/BKP-06's silent path — the reason D-23 exists. Every early
  /// return below happens before anything user-visible could occur.
  @override
  Future<void> runSilent() async {
    // BKP-12/D-18: nothing in this method may run for a user who has not
    // opted in — no network, no auth attempt, nothing.
    if (!_ref.read(appProvider).settings.driveBackupEnabled) return;
    if (_inFlight) return; // already running — this cycle has nothing to do
    _inFlight = true;
    try {
      final authService = _ref.read(googleAuthServiceProvider);
      // Silent ONLY — this method never reaches the interactive sign-in
      // entry point that `runManual()` legitimately uses below. That is
      // what makes this path structurally incapable of showing a dialog,
      // not merely careful not to (T-05-03).
      final result = await authService.silentAuthorization();
      if (result == null) {
        // BKP-04's exact case: no cached/authorized account. Never a
        // dialog, never a toast — just the mapped Settings line.
        await _recordResult(
          const BackupOutcome(succeeded: false, at: null, code: BackupErrorCode.needsReauth),
        );
        return;
      }
      // Bridge to an authenticated client and build a FRESH DriveService
      // every cycle — never cache the client or the service across calls.
      // The bridged credentials carry an arbitrary far-future expiry and no
      // refresh token, so re-deriving the authorization each cycle IS the
      // refresh mechanism (RESEARCH Pitfall 4), not a missed optimisation.
      final client = result.authorization.authClient(scopes: kDriveScopes);
      final driveService = DriveService(client);
      await driveService.upload(_ref.read(appProvider));
      await _recordResult(
        BackupOutcome(succeeded: true, at: DateTime.now().toUtc(), code: null),
      );
    } catch (e) {
      _log('runSilent failed: $e');
      await _recordResult(
        BackupOutcome(succeeded: false, at: null, code: _classifyError(e)),
      );
    } finally {
      _inFlight = false;
    }
  }

  /// The one call site every result write goes through (both success and
  /// failure). `pauseNextAutomaticBackup()` runs immediately before
  /// `recordBackupResult`, which itself routes through `_mutate` — whose
  /// unconditional post-persist call is `scheduleDebounced()` (P1-D-05).
  /// Without the pause, recording a result would schedule another upload,
  /// which would record another result, without bound (P5-D-19). This
  /// reasoning is invisible from either side alone, which is why it is
  /// written here rather than only at `scheduleDebounced()`'s check above.
  Future<void> _recordResult(BackupOutcome outcome) async {
    pauseNextAutomaticBackup();
    await _ref.read(appProvider.notifier).recordBackupResult(outcome);
  }

  @override
  Future<BackupOutcome> runManual() async {
    // P5-D-09's derived consequence: pressing "Sao lưu ngay" is explicit
    // user intent, and D-23 separates automatic from manual everywhere
    // else in this feature — this is no exception. The pause exists to
    // stop the AUTOMATIC upload machinery from undoing the user's
    // just-completed undo, not to stop the user from backing up when they
    // explicitly ask. Cleared before the in-flight guard, so even a manual
    // tap that arrives while another run is in flight still clears it.
    _suppressNextSchedule = false;
    if (_inFlight) {
      // Already running — not a failure, nothing new to report.
      return const BackupOutcome(succeeded: false, at: null, code: null);
    }
    _inFlight = true;
    try {
      final authService = _ref.read(googleAuthServiceProvider);
      // Silent first; only fall back to the interactive path when there is
      // no cached authorization. "Sao lưu ngay" is itself a user gesture,
      // so the interactive path is legitimate here — and only here in this
      // file.
      var result = await authService.silentAuthorization();
      result ??= await authService.signInAndAuthorize();
      if (result == null) {
        // The user cancelled the interactive sign-in — not a failure,
        // nothing to report or persist.
        return const BackupOutcome(succeeded: false, at: null, code: null);
      }
      // Bridge to an authenticated client and build a FRESH DriveService
      // every cycle — never cache the client or the service across calls.
      // The bridged credentials carry an arbitrary far-future expiry and no
      // refresh token, so re-deriving the authorization each cycle IS the
      // refresh mechanism (RESEARCH Pitfall 4), not a missed optimisation.
      final client = result.authorization.authClient(scopes: kDriveScopes);
      final driveService = DriveService(client);
      await driveService.upload(_ref.read(appProvider));
      return BackupOutcome(
        succeeded: true,
        at: DateTime.now().toUtc(),
        code: null,
      );
    } catch (e) {
      // Raw exception text is only ever logged locally through _log below
      // — never persisted. The mapped closed-set code is what the caller
      // (the Settings row) may write into Settings, and only the caller
      // does that write; this service never writes Settings itself.
      _log('runManual failed: $e');
      return BackupOutcome(
        succeeded: false,
        at: null,
        code: _classifyError(e),
      );
    } finally {
      _inFlight = false;
    }
  }

  BackupErrorCode _classifyError(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return BackupErrorCode.networkError;
    }
    if (error is DetailedApiRequestError &&
        (error.status == 401 || error.status == 403)) {
      return BackupErrorCode.needsReauth;
    }
    return BackupErrorCode.unknown;
  }

  void _log(String message) {
    // ignore: avoid_print
    print('RealBackupService: $message');
  }
}

/// Provider name is verbatim from §5.2 so `app_state.dart` never has to
/// change — only the implementation behind it changes, from
/// `NoopBackupService` (Phase 1) to `RealBackupService` (this plan).
final backupServiceProvider = Provider<BackupService>(
  (ref) => RealBackupService(ref),
);
