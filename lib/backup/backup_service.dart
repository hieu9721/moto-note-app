// lib/backup/backup_service.dart — the backup seam `_mutate` calls on every
// mutation (P1-D-05). This plan (05-01) adds the one manual path: "Sao lưu
// ngay" in Settings, wired through `runManual()`. `scheduleDebounced()`
// stays deliberately inert here — 05-02 owns the debounce timer, the >24h
// cold-start trigger, the paused-lifecycle flush, and the P5-D-19
// suppression that makes writing the backup result safe to call from
// inside `_mutate` without an unbounded reschedule loop.
import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
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

  /// The one path this plan builds — a user-triggered upload from Settings'
  /// "Sao lưu ngay" (BKP-07). `runSilent()` for the three automatic
  /// triggers is 05-02's job and does not exist yet.
  Future<BackupOutcome> runManual();
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
}

class RealBackupService implements BackupService {
  RealBackupService(this._ref);

  final Ref _ref;

  /// Non-reentrancy guard (RESEARCH Pitfall 6). Without it, two overlapping
  /// runs would each evaluate `DriveService`'s create-or-update decision
  /// against the same missing file and create two remote files.
  bool _inFlight = false;

  /// Deliberately inert in this plan — see the file header. `_mutate`
  /// calls this unconditionally after every write (P1-D-05); wiring a real
  /// timer here before 05-02's suppression exists would make the
  /// result-write below re-trigger itself in an unbounded loop.
  @override
  void scheduleDebounced() {}

  @override
  Future<BackupOutcome> runManual() async {
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
