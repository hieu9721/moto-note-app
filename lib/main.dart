// lib/main.dart — hydrate-before-render entry point (DATA-07), extended by
// HOME-01 to build the real navigation shell instead of a `home:`-branch
// placeholder, and by Phase 4 (NOTIF-01/NOTIF-08/P4-D-03) to initialise the
// real notification service and resolve a cold-start deep link before the
// first frame. `hydrate()` still completes before the app is ever rendered,
// so the first widget build already holds real data or has already decided
// which hydrate outcome occurred; nothing waits on the network (D-19)
// because both `hydrate()` and the notification-plugin init only touch the
// local filesystem / local platform channels. The router built by
// `buildRouter` (`lib/ui/router.dart`) owns everything past that point.
//
// Provider-override note (04-PATTERNS.md, 04-RESEARCH.md): Riverpod 3.4.2's
// `ProviderContainer.updateOverrides()` can only UPDATE an override already
// present at construction — it cannot add one later ("It is not possible to
// remove or add new overrides, only update existing ones", per the SDK's own
// doc comment). So `notificationSchedulerProvider` is overridden with the
// inert `NoopNotificationService` at construction (a placeholder slot, not
// the provider's own default), `hydrate()` runs against it exactly as
// before, and only once the real `FlutterLocalNotificationService` has been
// constructed and initialised does `updateOverrides` swap that slot for the
// real service — this is what lets `init()` stay sequenced strictly AFTER
// `hydrate()`, matching this file's original ordering. `ref.read(
// notificationSchedulerProvider)` inside `_mutate` returns the real service,
// never the Noop, on every mutation from this point forward — asserted on
// device rather than merely assumed, since no mutation happens between the
// swap and the first real reschedule call.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'data/app_data_repository.dart';
import 'domain/notification_plan.dart';
import 'notifications/notification_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documentsDir = await getApplicationDocumentsDirectory();
  final repository = AppDataRepository(documentsDir);

  final container = ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(repository),
      // Placeholder — see the provider-override note above. Replaced by the
      // real service via updateOverrides() once it is initialised, below.
      notificationSchedulerProvider.overrideWithValue(
        const NoopNotificationService(),
      ),
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

  final notificationService = FlutterLocalNotificationService();
  await notificationService.init();
  container.updateOverrides([
    repositoryProvider.overrideWithValue(repository),
    notificationSchedulerProvider.overrideWithValue(notificationService),
  ]);

  // P4-D-03: read the cold-start launch payload and fold it into the
  // router's initialLocation BEFORE the router is built, so the first frame
  // is already the destination a notification promised — no flash of plain
  // home followed by a jump. This read is local-only (D-19).
  final launchPayload = await notificationService.consumeLaunchPayload();
  final initialLocation = notificationRouteFor(
    launchPayload,
    container.read(appProvider),
  );
  if (launchPayload != null) {
    // Cold-start half of NOTIF-11.
    await container.read(appProvider.notifier).recordNotificationOpened();
  }

  final router = buildRouter(
    container: container,
    outcome: outcome,
    initialLocation: initialLocation,
  );

  // Warm-tap half of NOTIF-08/NOTIF-11: the service never imports the
  // router or app_state.dart itself, so this closure is the only place that
  // wires the two together.
  notificationService.onNotificationOpened = (payload) {
    unawaited(container.read(appProvider.notifier).recordNotificationOpened());
    router.go(notificationRouteFor(payload, container.read(appProvider)));
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: _LifecycleRescheduler(
        container: container,
        child: MaterialApp.router(
          title: 'MotoNote',
          theme: appTheme,
          routerConfig: router,
        ),
      ),
    ),
  );
}

/// NOTIF-05's "runs on `AppLifecycleState.resumed`" half — the "every state
/// change" half already exists inside `_mutate` (P1-D-05) and needs no new
/// code. Wraps `MaterialApp.router` rather than living inside it, since a
/// `WidgetsBindingObserver` needs a `State` to register itself in `initState`
/// and remove itself in `dispose`.
class _LifecycleRescheduler extends StatefulWidget {
  const _LifecycleRescheduler({required this.container, required this.child});

  final ProviderContainer container;
  final Widget child;

  @override
  State<_LifecycleRescheduler> createState() => _LifecycleReschedulerState();
}

class _LifecycleReschedulerState extends State<_LifecycleRescheduler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        widget.container
            .read(notificationSchedulerProvider)
            .rescheduleAll(widget.container.read(appProvider)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
