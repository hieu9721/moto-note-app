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
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver, AppLifecycleState;
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

  /// SET-03 (P6-D-11): deletes the remote backup file, but only when the
  /// user explicitly opted in via the delete-all-data flow's checkbox —
  /// the one and only call site is `AppNotifier.deleteAllData`
  /// (`lib/state/app_state.dart`). Returns whether it succeeded rather
  /// than throwing, so a Drive failure can never abort the local deletion
  /// already in progress around it. Uses the silent authorization bridge
  /// ONLY — see [_silentCycle]'s own comment on why that path is
  /// structurally incapable of popping a sign-in dialog mid-deletion
  /// (D-23) — never the interactive [GoogleAuthService.signInAndAuthorize]
  /// entry point `runManual`/`_manualCycle` legitimately use.
  Future<bool> deleteRemoteBackup();
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

  @override
  Future<bool> deleteRemoteBackup() async => false;
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
  ///
  /// Holds the cycle currently in flight, or null when idle. This was a bare
  /// `bool` until gap G-05-5: a manual tap that arrived while a run was in
  /// flight returned `BackupOutcome(succeeded: false, code: null)`, which
  /// the Settings caller reads as "nothing to report" and renders as
  /// NOTHING AT ALL — no spinner, no SnackBar, no status line change. On
  /// device that produced a `Sao lưu ngay` button that was completely dead
  /// to the touch for the rest of the session, because a hung automatic
  /// cycle had left the flag set and nothing could ever clear it.
  ///
  /// Holding the FUTURE instead lets a manual tap await the run that is
  /// already going and report ITS real outcome, so the button always
  /// answers. [_cycleTimeout] then bounds the pinning risk itself: a run
  /// that hangs in the platform auth layer now completes as a timeout
  /// rather than silently disabling backup until the app is restarted.
  Future<BackupOutcome>? _inFlightRun;

  /// Bounds the NON-INTERACTIVE steps of a cycle — the silent authorization
  /// probe and the Drive upload. Long enough for a slow mobile round trip,
  /// short enough that a hung platform call resolves as a normal
  /// `TimeoutException` (which `_classifyError` maps to `networkError`)
  /// instead of pinning [_inFlightRun] and silently disabling backup for
  /// the rest of the session, which is what G-05-5 was.
  ///
  /// It must never wrap the interactive sign-in: that step waits on a
  /// person reading Google's consent screens, and bounding it reported a
  /// network failure on a healthy connection.
  static const _cycleTimeout = Duration(seconds: 90);

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
    if (_inFlightRun != null) {
      return; // already running — this cycle has nothing to do
    }
    // The cycle is published as a future BEFORE it is awaited, so a manual
    // tap arriving mid-cycle can await this same run and report its real
    // outcome instead of being dropped (G-05-5).
    final run = _silentCycle();
    _inFlightRun = run;
    try {
      await run;
    } finally {
      _inFlightRun = null;
    }
  }

  /// One silent cycle, returning the outcome it recorded so a concurrent
  /// `runManual()` can report the same result. Every exit path returns an
  /// outcome; none returns null, because "no answer" is exactly the state
  /// G-05-5 was about.
  Future<BackupOutcome> _silentCycle() async {
    try {
      final authService = _ref.read(googleAuthServiceProvider);
      // Silent ONLY — this method never reaches the interactive sign-in
      // entry point that `runManual()` legitimately uses below. That is
      // what makes this path structurally incapable of showing a dialog,
      // not merely careful not to (T-05-03).
      final result = await authService.silentAuthorization().timeout(
        _cycleTimeout,
      );
      if (result == null) {
        // BKP-04's exact case: no cached/authorized account. Never a
        // dialog, never a toast — just the mapped Settings line.
        const outcome = BackupOutcome(
          succeeded: false,
          at: null,
          code: BackupErrorCode.needsReauth,
        );
        await _recordResult(outcome);
        return outcome;
      }
      // Bridge to an authenticated client and build a FRESH DriveService
      // every cycle — never cache the client or the service across calls.
      // The bridged credentials carry an arbitrary far-future expiry and no
      // refresh token, so re-deriving the authorization each cycle IS the
      // refresh mechanism (RESEARCH Pitfall 4), not a missed optimisation.
      final client = result.authorization.authClient(scopes: kDriveScopes);
      final driveService = DriveService(client);
      await driveService.upload(_ref.read(appProvider)).timeout(_cycleTimeout);
      final outcome = BackupOutcome(
        succeeded: true,
        at: DateTime.now().toUtc(),
        code: null,
      );
      await _recordResult(outcome);
      return outcome;
    } catch (e) {
      _log('runSilent failed: $e');
      final outcome = BackupOutcome(
        succeeded: false,
        at: null,
        code: _classifyError(e),
      );
      await _recordResult(outcome);
      return outcome;
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

  /// SET-03 (P6-D-11): builds the identical silent-authorization bridge
  /// [_silentCycle] above already uses — silent only, never
  /// [GoogleAuthService.signInAndAuthorize] — and calls
  /// [DriveService.deleteBackupFile]. Returns `false` on a null
  /// authorization result, on a timeout, or on any caught exception,
  /// logging through the same [_log] seam every other failure path in this
  /// class uses; never rethrows, so the caller (`AppNotifier.deleteAllData`)
  /// can continue its own sequence regardless of the outcome. Deliberately
  /// does NOT go through [_recordResult]/`recordBackupResult` — this is not
  /// a backup cycle and must not touch `Settings.lastBackupAt`/
  /// `lastBackupError`. Builds a FRESH [DriveService] rather than caching
  /// one across calls, matching [_silentCycle]/[_manualCycle]'s own
  /// discipline above.
  @override
  Future<bool> deleteRemoteBackup() async {
    try {
      final authService = _ref.read(googleAuthServiceProvider);
      final result = await authService.silentAuthorization().timeout(
        _cycleTimeout,
      );
      if (result == null) return false;
      final client = result.authorization.authClient(scopes: kDriveScopes);
      final driveService = DriveService(client);
      await driveService.deleteBackupFile().timeout(_cycleTimeout);
      return true;
    } catch (e) {
      _log('deleteRemoteBackup failed: $e');
      return false;
    }
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
    final existing = _inFlightRun;
    if (existing != null) {
      // G-05-5: this used to return `code: null`, which the Settings caller
      // reads as "nothing to report" and renders as nothing at all — the
      // user tapped a button and the app said absolutely nothing back.
      // Await the run that is already going and report ITS outcome, so the
      // tap always produces either the success SnackBar or a mapped error.
      return existing;
    }
    final run = _manualCycle();
    _inFlightRun = run;
    try {
      return await run;
    } finally {
      _inFlightRun = null;
    }
  }

  /// One manual cycle. Split out of [runManual] so the in-flight future can
  /// be published before it is awaited (G-05-5).
  Future<BackupOutcome> _manualCycle() async {
    try {
      final authService = _ref.read(googleAuthServiceProvider);
      // Silent first; only fall back to the interactive path when there is
      // no cached authorization. "Sao lưu ngay" is itself a user gesture,
      // so the interactive path is legitimate here — and only here in this
      // file.
      var result = await authService.silentAuthorization().timeout(
        _cycleTimeout,
      );
      // Deliberately NOT bounded by [_cycleTimeout]: this is the one call
      // in the class that waits on a HUMAN. Google's account picker,
      // unverified-app notice and consent screen are several taps of
      // reading, and a user who takes two minutes over them has not
      // failed — timing that out reported `Không có kết nối mạng` on a
      // perfectly good connection, which is exactly the class of lie
      // G-05-6 was about. The in-flight future is still published, so a
      // second tap arriving during the consent flow joins this run rather
      // than starting a competing one.
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
      await driveService.upload(_ref.read(appProvider)).timeout(_cycleTimeout);
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
      return BackupOutcome(succeeded: false, at: null, code: _classifyError(e));
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
    // G-05-6: a grant the user revoked from their Google Account page — the
    // likeliest real-world backup failure, and the only one they can fix —
    // never reaches the Drive API, so it never produces the 401/403 above.
    // It fails one layer earlier, in `authorizeScopes`. Without this branch
    // it fell through to `unknown` and the Settings line read `Lỗi không
    // xác định`, discarding the actionable `Cần đăng nhập lại Google` that
    // was already defined for exactly this case. `runSilent` above already
    // classified its own null-authorization case correctly; only the
    // interactive fallback in `runManual` was misreporting.
    final authFailure = classifyGoogleAuthFailure(error);
    if (authFailure != null) {
      return switch (authFailure) {
        GoogleAuthFailureKind.needsReauth => BackupErrorCode.needsReauth,
        GoogleAuthFailureKind.transient => BackupErrorCode.networkError,
      };
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
