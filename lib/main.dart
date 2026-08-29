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
import 'ui/onboarding/welcome_screen.dart';

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

/// Phase 1's placeholder, extended by Phase 2 with an onboarding-vs-
/// post-onboarding branch. `home:` reads `appProvider`'s vehicles list —
/// watching (not reading) so the screen changes the instant
/// `completeOnboarding` returns — via `isNotEmpty`, never a check tied to
/// exactly one vehicle (the model is multi-vehicle, see 02-01-PLAN.md's
/// assumption-delta decision). Both branches remain temporary scaffolding:
/// neither is one of D-33's seven screens. HOME-01 (Phase 3) replaces this
/// widget's whole body with the real `HomeScreen`, and this widget must
/// not grow a bottom nav or a declarative routing package before then.
class MotoNoteApp extends ConsumerWidget {
  const MotoNoteApp({super.key, required this.outcome});

  final HydrateOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVehicle = ref.watch(appProvider).vehicles.isNotEmpty;
    return MaterialApp(
      title: 'MotoNote',
      theme: appTheme,
      home: hasVehicle
          ? const Scaffold(
              body: Center(child: Text('Đã tạo xe. (Phase 3 thay màn hình này)')),
            )
          : const WelcomeScreen(),
    );
  }
}
