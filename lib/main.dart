// lib/main.dart — hydrate-before-render entry point (DATA-07), extended by
// HOME-01 to build the real navigation shell instead of a `home:`-branch
// placeholder. `hydrate()` completes before the app is ever rendered, so the
// first widget build already holds real data or has already decided which
// hydrate outcome occurred; nothing waits on the network (D-19) because
// `hydrate()` only touches the local filesystem for a sub-200 KB file. The
// router built by `buildRouter` (`lib/ui/router.dart`) owns everything past
// that point: the three-tab shell, the onboarding/data-issue redirect, and
// every screen this phase renders.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'data/app_data_repository.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documentsDir = await getApplicationDocumentsDirectory();

  final container = ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(AppDataRepository(documentsDir)),
    ],
  );

  final outcome = await container.read(appProvider.notifier).hydrate();

  // Defensive, cheap insurance for later phases (Settings' notification-hour
  // display, a future month-name string) — synchronous under the hood
  // (03-RESEARCH.md Pattern 7, verified against intl-0.20.3's own source:
  // `initializeDateSymbols`/`initializeDatePatterns` populate the map
  // immediately and the returned Future is already-completed), so this costs
  // nothing even though this phase's own `DateFormat` strings are purely
  // numeric and need no locale argument at all.
  await initializeDateFormatting('vi_VN');

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        title: 'MotoNote',
        theme: appTheme,
        routerConfig: buildRouter(container: container, outcome: outcome),
      ),
    ),
  );
}
