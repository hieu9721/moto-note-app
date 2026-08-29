// lib/main.dart — hydrate-before-render entry point (DATA-07). `hydrate()`
// completes before `runApp` is ever called, so the first widget build
// already holds real data or has already decided which hydrate outcome
// occurred; nothing waits on the network (D-19) because `hydrate()` only
// touches the local filesystem for a sub-200 KB file.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'data/app_data_repository.dart';
import 'domain/odo.dart';
import 'state/app_state.dart';
import 'state/derived.dart';
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
          ? const _PostOnboardingPlaceholder()
          : const WelcomeScreen(),
    );
  }
}

/// Closes the tracer loop: onboarding wrote a vehicle and its engine-oil
/// item, `dueItemsProvider` computes their due status, this screen shows
/// it. Temporary scaffolding, not one of D-33's seven screens — HOME-01
/// (Phase 3) replaces this widget's whole body with the real `HomeScreen`;
/// it must not grow a bottom nav or a declarative routing package before
/// then.
class _PostOnboardingPlaceholder extends ConsumerWidget {
  const _PostOnboardingPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final vehicle = data.vehicles.first;
    final estOdo = estimateOdo(vehicle);
    final dueItems = ref.watch(dueItemsProvider(vehicle.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name.isEmpty ? 'Xe của bạn' : vehicle.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // §9.5: an estimated odometer is never shown as a bare number.
            Text(
              '~$estOdo km',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (final dueItem in dueItems) _DueItemTile(dueItem: dueItem),
          ],
        ),
      ),
    );
  }
}

/// One row: the item's name plus its §9.5-honest due line. An estimated
/// figure carries the "khoảng" hedge; a guessed baseline additionally
/// carries the "chưa có mốc thật" marker (02-CONTEXT.md's badge text). Only
/// a non-estimate result gets a definite "Còn N ngày" line.
///
/// Plan 05 (02-05-PLAN.md Task 2 acceptance criteria): the engine-oil row's
/// guessed baseline also carries §6.1's full prompt string verbatim —
/// "Bạn vừa thay nhớt? Ghi lại để app tính đúng" — so a user who set up
/// with "Không nhớ" or any of the day-offset guesses sees the SAME
/// invitation to log a real reading that Phase 3's home cards will show.
/// Neither string is reworded here.
class _DueItemTile extends StatelessWidget {
  const _DueItemTile({required this.dueItem});

  final DueItem dueItem;

  @override
  Widget build(BuildContext context) {
    final due = dueItem.due;
    final item = dueItem.item;
    final label = due.isEstimate
        ? 'Còn khoảng ${due.daysLeft} ngày'
              '${item.baselineIsGuess ? ' · chưa có mốc thật' : ''}'
        : 'Còn ${due.daysLeft} ngày';
    final showOilPrompt =
        item.catalogCode == 'engine_oil' && item.baselineIsGuess;

    return ListTile(
      title: Text(item.name),
      subtitle: showOilPrompt
          ? Text('$label\nBạn vừa thay nhớt? Ghi lại để app tính đúng')
          : Text(label),
    );
  }
}
