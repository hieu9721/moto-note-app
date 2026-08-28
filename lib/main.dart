// lib/main.dart — hydrate-before-render entry point (DATA-07). `hydrate()`
// completes before `runApp` is ever called, so the first widget build
// already holds real data or has already decided which hydrate outcome
// occurred; nothing waits on the network (D-19) because `hydrate()` only
// touches the local filesystem for a sub-200 KB file.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'data/app_data_repository.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documentsDir = await getApplicationDocumentsDirectory();

  final container = ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(AppDataRepository(documentsDir)),
    ],
  );

  final outcome = await container.read(appProvider.notifier).hydrate();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MotoNoteApp(outcome: outcome),
    ),
  );
}

/// Phase 1's only screen — proves the hydrate-before-render wiring end to
/// end on a device. HOME-01 and the rest of the §11 seven-screen inventory
/// are Phase 3 (D-33 makes that inventory a deliberate scope-control
/// device), so this widget must not grow a bottom nav, a declarative
/// routing package, or any real UI.
class MotoNoteApp extends StatelessWidget {
  const MotoNoteApp({super.key, required this.outcome});

  final HydrateOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoNote',
      theme: appTheme,
      home: Scaffold(body: Center(child: Text('hydrate() outcome: $outcome'))),
    );
  }
}
