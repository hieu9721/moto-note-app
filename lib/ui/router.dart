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
// `item/:id` (under `/`) and `:id` (under `/notes`) are deliberately NOT
// declared here — plan 05 adds both routes and their screens together, so no
// route ever points at a placeholder widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';
import 'home/home_screen.dart';
import 'notes/notes_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'settings/settings_screen.dart';

GoRouter buildRouter({
  required ProviderContainer container,
  required HydrateOutcome outcome,
}) {
  final refresh = _AppRefreshNotifier(container);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Pitfall 1 (research): `undecodable`/`schemaTooNew` must NEVER fall
      // into the same branch as `notFound` (P1-D-09) — all three leave
      // `AppData.vehicles` empty, so a vehicle-count-only check cannot tell
      // a quarantined document from a first run.
      final isDataIssue =
          outcome == HydrateOutcome.undecodable ||
          outcome == HydrateOutcome.schemaTooNew;
      if (isDataIssue) {
        return state.matchedLocation == '/data-issue' ? null : '/data-issue';
      }
      final hasVehicle = container.read(appProvider).vehicles.isNotEmpty;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!hasVehicle && !atOnboarding) return '/onboarding';
      if (hasVehicle && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/data-issue',
        builder: (context, state) => DataIssueScreen(outcome: outcome),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNavBar(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
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
  _AppRefreshNotifier(ProviderContainer container) {
    _sub = container.listen(appProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.close();
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

/// D-33's amended 7+1 exception: a read-only screen for the two
/// `HydrateOutcome`s that mean "a document exists but this build could not
/// read it" — reachable only from the redirect above, never from any normal
/// navigation flow. It takes no action and offers no button; Phase 5 owns
/// restore (P1-D-09) and may give this screen its first action.
class DataIssueScreen extends StatelessWidget {
  const DataIssueScreen({super.key, required this.outcome});

  final HydrateOutcome outcome;

  @override
  Widget build(BuildContext context) {
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
          child: Text(message, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
