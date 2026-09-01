// lib/backup/google_auth.dart — wraps `GoogleSignIn.instance` (v7.2.0) with
// exactly the two authorization halves BKP-03/BKP-04 need. Only this file
// imports `package:google_sign_in` directly — mirrors Phase 4's "only the
// service layer imports the plugin" rule.
//
// Every call sequence below is transcribed from the actual resolved 7.2.0
// source read this session (05-RESEARCH.md Architecture Pattern 1), not from
// the source document's own v6-era §7.3 sample — v7 is a from-scratch
// rewrite splitting authentication (`authenticate`/
// `attemptLightweightAuthentication`) from authorization
// (`authorizationClient.authorizeScopes`/`authorizationForScopes`), and none
// of §7.3's `GoogleSignIn(scopes: [...])`/`.signIn()`/`.signInSilently()`
// exist in the resolved version (P5-D-12, RESEARCH Pitfall 1).
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// DriveApi comes from `drive_service.dart`'s re-export, not a direct
// import of the Drive API package itself — that package's Drive client
// type surface stays confined to `drive_service.dart` alone (acceptance
// criterion, task 2); only its one `driveAppdataScope` constant is needed
// here.
import 'drive_service.dart' show DriveApi;

/// The Web application OAuth client ID (task 1 of `05-01-PLAN.md`), used as
/// `initialize()`'s `serverClientId` on Android. Per P5-D-10 this is
/// committed as a real default, not left empty: an installed-app OAuth
/// client ID is not a secret — package name plus the registered SHA-1
/// fingerprint is the actual protection, not secrecy — and an empty value
/// fails with `GoogleSignInExceptionCode.clientConfigurationError`
/// (RESEARCH Pitfall 3), which is precisely the silent-looking build-time
/// failure this default exists to prevent. `--dart-define=
/// GOOGLE_SERVER_CLIENT_ID=...` can still override it below.
const kGoogleServerClientIdDefault =
    '163262363118-bv34ht6dt3lk94epcsob45p4kpiqfu64.apps.googleusercontent.com';

/// A single-element `const` list built from the package's own constant —
/// never a hand-typed scope URL, so a typo can never silently request a
/// different or broader scope (D-22, BKP-02). This is the one object every
/// authorization request in this file passes, so no code path can
/// accumulate, append to, or reorder the requested scopes.
const kDriveScopes = <String>[DriveApi.driveAppdataScope];

/// The result of a successful authorization — carries both the scoped
/// `accessToken` wrapper and the account email, because BKP-14 needs the
/// address the user signed in with and re-deriving it via a second
/// `attemptLightweightAuthentication()` round trip would cost an extra
/// platform call for something already known at authorization time.
class GoogleAuthResult {
  const GoogleAuthResult({required this.authorization, required this.email});

  final GoogleSignInClientAuthorization authorization;
  final String email;
}

/// Wraps `GoogleSignIn.instance` (a package-owned singleton — there is no
/// `GoogleSignIn()` constructor in 7.2.0) with BKP-03's interactive path,
/// BKP-04's silent path, live-account re-derivation, and sign-out.
class GoogleAuthService {
  /// Caches the initialisation `Future` itself, not a `bool`. Two callers
  /// racing on a boolean would both observe it unset and both call
  /// `initialize()`, which the package documents as call-exactly-once —
  /// caching the `Future` and awaiting it is the same three lines and is
  /// correct under concurrency (05-01-PLAN.md Flagged Assumption 4, a
  /// deliberate improvement on 05-RESEARCH.md/05-PATTERNS.md's sketched
  /// `bool _initialized` guard).
  Future<void>? _init;

  Future<void> _ensureInit() {
    return _init ??= GoogleSignIn.instance.initialize(
      serverClientId: const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: kGoogleServerClientIdDefault,
      ),
    );
  }

  /// BKP-04's silent half. Never interactive — at the default
  /// `reportAllExceptions: false`, `attemptLightweightAuthentication()`
  /// swallows cancel/interrupt/unavailable and resolves to null, exactly
  /// the "not signed in yet" case. Returning null here is an expected
  /// outcome, never an error.
  Future<GoogleAuthResult?> silentAuthorization() async {
    await _ensureInit();
    // The method's own return type is double-nullable: on some platforms
    // it returns null rather than a Future at all, so the return must be
    // null-checked before it is awaited.
    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    final account = future == null ? null : await future;
    if (account == null) return null;
    final authorization = await account.authorizationClient
        .authorizationForScopes(kDriveScopes);
    if (authorization == null) return null;
    return GoogleAuthResult(authorization: authorization, email: account.email);
  }

  /// BKP-03's interactive half — callable only from a user gesture handler.
  /// This is a real platform requirement documented on
  /// `authorizeScopes()` itself, not a house rule. Returns null only on
  /// user cancellation; every other `GoogleSignInException` is logged with
  /// both its code and its description and rethrown, since a wrong or
  /// missing SHA-1 surfaces as `unknownError` whose Dart code alone carries
  /// no signal (RESEARCH Pitfall 2) — the raw platform text in
  /// `.description` is the only readable evidence.
  Future<GoogleAuthResult?> signInAndAuthorize() async {
    await _ensureInit();
    late final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      _log('signInAndAuthorize failed: ${e.code} — ${e.description}');
      rethrow;
    }
    final authorization = await account.authorizationClient.authorizeScopes(
      kDriveScopes,
    );
    return GoogleAuthResult(authorization: authorization, email: account.email);
  }

  /// Re-derives the live signed-in account rather than trusting a stored
  /// value — the same "live OS state over stored intent" rule the
  /// exact-alarm row already follows (T-04-13/P4-D-08). Returns null when
  /// nobody is currently signed in.
  Future<String?> currentEmail() async {
    await _ensureInit();
    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    final account = future == null ? null : await future;
    return account?.email;
  }

  /// Does not touch Drive — deleting the user's only backup on sign-out is
  /// explicitly rejected (P5-D-13).
  Future<void> signOut() async {
    await _ensureInit();
    await GoogleSignIn.instance.signOut();
  }

  void _log(String message) {
    // ignore: avoid_print
    print('GoogleAuthService: $message');
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (_) => GoogleAuthService(),
);
