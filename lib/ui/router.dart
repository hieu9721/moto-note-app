// lib/ui/router.dart — HOME-01. The real navigation shell: a `go_router`
// `StatefulShellRoute.indexedStack` with three persistent tabs, built once in
// `main()` around the `ProviderContainer` that already exists there (not
// through a new Riverpod provider — 03-RESEARCH.md Pattern 1).
//
// Four load-bearing things here, each cited to the decision/research that
// requires it:
//
// 1. `redirect` checks `outcome` FIRST, before any vehicle-count check.
//    `undecodable` and `schemaTooNew` both route to `/data-issue`, never to
//    `/onboarding` — collapsing them into the same branch as a first run
//    would let a fresh setup silently overwrite a document the repository
//    already quarantined (research Pitfall 1, T-03-01, P1-D-09). This is the
//    single most consequential ordering decision in this file.
// 2. `_AppRefreshNotifier` bridges Riverpod's imperatively-built
//    `ProviderContainer` to go_router's `Listenable`-based `refreshListenable`
//    contract — without it the redirect never re-runs when
//    `completeOnboarding` updates `appProvider` (T-03-03: the subscription is
//    closed in `dispose()` so the listener cannot outlive the router).
// 3. `StatefulShellRoute.indexedStack` with exactly three branches — Trang
//    chủ / Ghi chú / Cài đặt — each holding its own navigation stack across
//    tab switches.
// 4. `/onboarding` and `/data-issue` sit OUTSIDE the shell as top-level
//    routes, so neither shows the bottom nav bar. `/data-issue` is D-33's
//    named 7+1 exception (amended 2026-08-30, Phase 3 planning): a read-only
//    screen naming which `HydrateOutcome` occurred, offering no action and no
//    navigation — Phase 5 owns restore (P1-D-09).
//
// `item/:id` (under `/`) and `:id` (under `/notes`) are added by plan 05
// alongside `item_detail_screen.dart` and `note_editor_screen.dart`, so
// neither route ever points at a placeholder widget. The notes branch also
// declares a literal `new` segment BEFORE its `:id` route — a `:id` route
// declared first would otherwise happily capture `new` as if it were an id.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';
import 'backup/restore_sheet.dart';
import 'home/home_screen.dart';
import 'item/item_detail_screen.dart';
import 'notes/note_editor_screen.dart';
import 'notes/notes_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'settings/settings_screen.dart';

GoRouter buildRouter({
  required ProviderContainer container,
  // P4-D-03: cold start routes straight to the destination a notification
  // promised — main.dart resolves this from the launch payload before the
  // router is built, so the first frame is already correct with no flash of
  // plain home. Defaults to '/' so every existing caller stays correct.
  String initialLocation = '/',
}) {
  final refresh = _AppRefreshNotifier(container);
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Pitfall 1 (research): `undecodable`/`schemaTooNew` must NEVER fall
      // into the same branch as `notFound` (P1-D-09) — all three leave
      // `AppData.vehicles` empty, so a vehicle-count-only check cannot tell
      // a quarantined document from a first run.
      //
      // P5-D-04/RESEARCH Pitfall 8: read the LIVE outcome from the provider
      // on every invocation rather than a value closed over once at
      // `buildRouter()` call time — a restore triggered from `/data-issue`
      // updates this provider directly (`AppNotifier.restoreFrom`), and a
      // stale closed-over value would route back to `/data-issue` forever
      // even after the document is valid again.
      final outcome = container.read(hydrateOutcomeProvider);
      final isDataIssue =
          outcome == HydrateOutcome.undecodable ||
          outcome == HydrateOutcome.schemaTooNew;
      if (isDataIssue) {
        return state.matchedLocation == '/data-issue' ? null : '/data-issue';
      }
      final hasVehicle = container.read(appProvider).vehicles.isNotEmpty;
      final atOnboarding = state.matchedLocation == '/onboarding';
      final atDataIssue = state.matchedLocation == '/data-issue';
      if (!hasVehicle && !atOnboarding) return '/onboarding';
      // P5-D-02: this is the line that lets a restore committed from
      // `/data-issue` reach `Trang chủ` in the same session — without the
      // `atDataIssue` disjunct, a healthy outcome with at least one vehicle
      // falls through every branch above and the redirect returns `null`,
      // leaving the user parked on `/data-issue` after a successful restore.
      if (hasVehicle && (atOnboarding || atDataIssue)) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/data-issue',
        builder: (context, state) => const DataIssueScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNavBar(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'item/:id',
                    builder: (context, state) =>
                        ItemDetailScreen(itemId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
                routes: [
                  // Declared BEFORE the ':id' route below so a literal
                  // 'new' segment is matched first — a ':id' route would
                  // otherwise happily capture it as if it were an id.
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => NoteEditorScreen(
                      // P3-D-15: query parameters, not path segments — the
                      // item-detail screen's "Thêm ghi chú" action is the
                      // only caller that ever supplies these.
                      vehicleId: state.uri.queryParameters['vehicleId'],
                      itemId: state.uri.queryParameters['itemId'],
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        NoteEditorScreen(noteId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridges Riverpod's `ProviderContainer` (built imperatively in `main()`,
/// not via `ProviderScope`) to go_router's `Listenable`-based
/// `refreshListenable` contract, so the redirect above re-runs the instant
/// `appProvider` changes (e.g. the moment onboarding commits a vehicle).
class _AppRefreshNotifier extends ChangeNotifier {
  // Two subscriptions, not one. `AppNotifier.restoreFrom` calls `_mutate`
  // (which notifies `appProvider`) BEFORE it calls
  // `hydrateOutcomeProvider.notifier.setOutcome(...)` — so the `appProvider`
  // notification that `_mutate` produces arrives while the outcome is still
  // `undecodable`, and the redirect it triggers is a no-op. Without this
  // second subscription to `hydrateOutcomeProvider`, nothing ever re-runs
  // the redirect once the outcome itself flips to `loaded` (CR-01, gap #1
  // in 05-VERIFICATION.md).
  _AppRefreshNotifier(ProviderContainer container) {
    _appSub = container.listen(appProvider, (_, _) => notifyListeners());
    _outcomeSub = container.listen(hydrateOutcomeProvider, (_, _) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<dynamic> _appSub;
  late final ProviderSubscription<dynamic> _outcomeSub;

  @override
  void dispose() {
    _appSub.close();
    _outcomeSub.close();
    super.dispose();
  }
}

/// The shell's own chrome: the three-tab `BottomNavigationBar` wrapping
/// whichever branch's `Navigator` is currently active. Tab labels are
/// verbatim per §11 — "Trang chủ", "Ghi chú", "Cài đặt".
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Ghi chú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

/// D-33's amended 7+1 exception: a screen for the two `HydrateOutcome`s
/// that mean "a document exists but this build could not read it" —
/// reachable only from the redirect above, never from any normal
/// navigation flow. As of this plan (P5-D-02), the `undecodable` branch
/// offers one action — the restore sheet — so a user whose document is
/// corrupt has a route out. `schemaTooNew` stays read-only, with no
/// button, exactly as Phase 3 left it.
class DataIssueScreen extends ConsumerWidget {
  const DataIssueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // P5-D-04: reads the same live provider the redirect above reads, so a
    // restore that resolves this screen's outcome to `loaded` is reflected
    // here too on the one frame between the mutation committing and the
    // redirect navigating away.
    final outcome = ref.watch(hydrateOutcomeProvider);
    final message = switch (outcome) {
      HydrateOutcome.undecodable =>
        'Không đọc được dữ liệu trên máy. Tệp gốc vẫn được giữ lại, chưa bị '
            'xoá.',
      HydrateOutcome.schemaTooNew =>
        'Dữ liệu trên máy được lưu bởi một phiên bản mới hơn ứng dụng này. '
            'Tệp gốc vẫn được giữ lại, chưa bị xoá.',
      // Unreachable via the redirect above (only undecodable/schemaTooNew
      // route here), kept exhaustive so a future HydrateOutcome variant is
      // forced to be handled rather than silently falling through.
      HydrateOutcome.loaded ||
      HydrateOutcome.notFound => 'Không thể mở dữ liệu trên máy.',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Dữ liệu gặp sự cố')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              // P5-D-02: on the `undecodable` branch ONLY, a way out. The
              // redirect above sends both problem outcomes here
              // unconditionally, and this screen offered no action and no
              // navigation from Phase 3 through 05-02 — a user whose
              // document is corrupt was trapped with no route to
              // onboarding or Settings and no way out except clearing app
              // data from the OS. P1-D-09 left this open for this phase
              // deliberately.
              //
              // `schemaTooNew` stays read-only, no button: the Drive copy
              // was very likely written by the same newer build that wrote
              // the local document, so restoring it would fail in exactly
              // the same way, and offering the button would promise a way
              // out that does not exist.
              //
              // The sheet correctly derives its no-local-data mode here
              // even though a file exists on disk: the document is
              // quarantined and undecodable, so `appProvider` reads
              // `AppData.empty()` — there is nothing to compare against and
              // nothing a restore could destroy.
              if (outcome == HydrateOutcome.undecodable) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => showRestoreSheet(context),
                  child: const Text('Khôi phục từ Google Drive'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
