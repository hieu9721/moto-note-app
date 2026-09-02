// lib/ui/home/home_screen.dart — HOME-01/HOME-02/HOME-03/HOME-04/HOME-06.
// The finished Trang chủ: overdue in red at the top, everything needing
// attention as a card, everything healthy folded into one collapsed row
// that expands in place, and every pinned note above the FAB.
//
// Built as a plain, non-builder `ListView(children: [...])` rather than
// `ListView.builder` — the content is bounded at roughly one vehicle's
// fifteen items (03-RESEARCH.md Pattern 3), and the collapsed `ExpansionTile`
// row would otherwise walk straight into three still-open Flutter issues
// about builder-based recycling.
//
// §5.3's rule holds here: this widget neither sorts, filters nor recomputes
// any item's status — `dueItemsProvider` already returns the list sorted by
// urgency with a deterministic tie-break, and `DueResult` (plan 02) owns
// every status computation. This screen only PARTITIONS that already-sorted
// list at a fixed 30-day cut (P3-D-02) — it never re-sorts either half.
//
// HOME-04: a `FloatingActionButton.extended` opens `odo_sheet.dart`'s
// keypad sheet — 03-UI-SPEC.md names both the exact icon it uses below
// and Material's own (unmodified) FAB accent colour, since this is one of
// the phase's five reserved accent CTAs.
//
// 04-01 (P4-D-02/P4-D-03): converted from `ConsumerWidget` to
// `ConsumerStatefulWidget` solely to gain a lifecycle hook — a plain
// `ConsumerWidget.build` has no `initState`, and no way to schedule a
// one-shot callback for the first frame, so this screen needs the stateful
// form to consume the one-shot `?sheet=odo` deep-link query parameter
// exactly once per screen instance. This is the first widget in `lib/ui/`
// to need that hook; 04-03 hangs the notification-permission prompt trigger
// off the same lifecycle hook rather than converting the class a second
// time. Everything the screen *renders* is unchanged by this conversion —
// only the base class and the addition of `_consumeSheetParam` below are
// new.
//
// 05-07 (P5-D-25/P5-D-26/BKP-15): hangs a THIRD one-shot effect off the
// same hook — the Drive-backup offer, reusing home's first-render-after-
// onboarding moment rather than adding an onboarding step (the standing
// refusal to edit `onboarding_flow.dart`, P4-D-05/P4-D-11). `04-REVIEW.md`'s
// WR-01 already flags two independent one-shot effects on this hook that
// could open two modals at once; a third makes the case for consolidating
// them stronger, but that refactor belongs in `.planning/BACKLOG.md` under
// D-34 (filed by this plan), not in this plan itself.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backup/google_auth.dart';
import '../../domain/catalog.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/notification_plan.dart';
import '../../domain/odo.dart';
import '../../domain/vehicle_selection.dart';
import '../../notifications/notification_service.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../catalog_icons.dart';
import '../notes/notes_screen.dart' show noteDisplayTitle, sortedNotes;
import '../notifications/battery_hint_sheet.dart';
import '../widgets/formatters.dart';
import 'due_card.dart';
import 'odo_sheet.dart';

// Standalone literals rather than inlined interpolation fragments, so the
// zero-prefix and the "ngày" suffix are each a single, greppable source of
// truth for their exact rendering.
const _tildePrefix = '~';
const _daySuffix = ' ngày';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // One-shot guard for [_consumeSheetParam] — set to true immediately before
  // the sheet is opened (never after), so a rebuild triggered by the sheet
  // itself, or any other rebuild of this screen instance, can never open a
  // second sheet no matter how many times `build` re-runs.
  bool _consumedSheetParam = false;

  // In-memory one-shot guard for [_maybeShowNotificationPermissionPrompt] —
  // the persisted `Settings.notificationPermissionAsked` flag is what
  // actually stops the prompt from ever asking twice across restarts
  // (P4-D-05); this field only stops a rebuild of THIS screen instance
  // (e.g. the very rebuild `updateSettings` triggers) from re-entering the
  // dialog before that persisted write has propagated back through
  // `ref.watch`.
  bool _permissionPromptShown = false;

  // In-memory one-shot guard for [_maybeShowDriveBackupPrompt] — the
  // persisted `Settings.driveBackupPromptShown` flag is what actually stops
  // the offer from ever asking twice across restarts (P5-D-26); this field
  // only stops a rebuild of THIS screen instance from re-entering the sheet
  // before that persisted write has propagated back through `ref.watch`,
  // mirroring [_permissionPromptShown]'s role above.
  bool _driveBackupPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeSheetParam();
      // 04-03: a second one-shot effect on the same lifecycle hook 04-01
      // reserved for it, rather than converting this class a second time.
      _maybeShowNotificationPermissionPrompt();
      // 05-07: a third one-shot effect on the same hook — BKP-15's
      // Drive-backup offer. Called unawaited, same as the line above; its
      // own gate reads [_permissionPromptShown] to avoid stacking two
      // modals on the same frame (see the method's doc comment).
      _maybeShowDriveBackupPrompt();
    });
  }

  /// P4-D-02: consumes the `?sheet=odo` query parameter on `/` at most once
  /// per screen instance, opening the same modal the FAB opens and then
  /// clearing the parameter so a rebuild, a tab round-trip, or a
  /// process-restore does not re-open it. P4-D-03: because `main.dart`
  /// already folds a cold-start launch payload into the router's
  /// `initialLocation`, a cold start from an `odo:` notification builds `/`
  /// WITH this query parameter present on the very first frame, so the
  /// sheet appears over the first home render rather than after a visible
  /// jump.
  void _consumeSheetParam() {
    // Guards `context`/`GoRouterState.of(context)` below against the async
    // gap between this frame being scheduled and this callback running
    // (CLAUDE.md's context-after-await trap applies to post-frame callbacks
    // too).
    if (!context.mounted) return;
    final sheetParam = GoRouterState.of(context).uri.queryParameters['sheet'];
    if (sheetParam != 'odo') return;
    if (_consumedSheetParam) return;
    // The build-time defensive early return below covers the render path;
    // this callback runs outside `build`, so it needs its own guard —
    // 06-01: resolved through `selectedVehicle`, not indexed directly, so
    // this deep link opens against whichever vehicle is actually selected.
    final data = ref.read(appProvider);
    final vehicle = selectedVehicle(data);
    if (vehicle == null) return;
    // Set BEFORE opening — an await on `showOdoSheet` here would leave a
    // re-entrancy hole for a callback fired again before the sheet returns.
    _consumedSheetParam = true;
    showOdoSheet(context, ref, vehicle);
    // Prefer `replace` so the back gesture does not walk back into the
    // parameterised URL; `go` is an acceptable substitute if `replace`
    // misbehaves inside the StatefulShellRoute branch (untriggered here).
    context.replace('/');
  }

  /// P4-D-05/P4-D-06: the notification-permission prompt, at most once per
  /// app install — gated on the persisted `Settings.notificationPermissionAsked`
  /// flag, not on anything purely in-memory, so the ask survives every
  /// rebuild, tab switch and process restart once it has happened.
  Future<void> _maybeShowNotificationPermissionPrompt() async {
    // Guards `context` below against the async gap between this frame
    // being scheduled and this callback running (CLAUDE.md's
    // context-after-await trap; same guard `_consumeSheetParam` uses).
    if (!context.mounted) return;
    if (_permissionPromptShown) return;
    // The build-time defensive early return covers the render path; this
    // callback runs outside `build`, so it needs its own guard against an
    // empty vehicle list — §10.3's timing is "after the user has seen
    // their bike", and the router's redirect already guarantees a vehicle
    // before this screen builds, so this never fires in practice.
    final data = ref.read(appProvider);
    if (data.vehicles.isEmpty) return;
    if (data.settings.notificationPermissionAsked) return;

    // Set BEFORE awaiting the dialog — mirrors `_consumeSheetParam`'s
    // re-entrancy guard above: an await here would otherwise leave a hole
    // for the callback to fire again before the dialog returns.
    _permissionPromptShown = true;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // [NEW, PROVISIONAL] — not sourced in §10.3, which quotes only the
        // body sentence below verbatim. Recorded in 04-03-SUMMARY.md.
        title: const Text('Bật thông báo?'),
        // §10.3, byte-for-byte — do not reword, retranslate, reflow or
        // shorten.
        content: const Text(
          'Bật thông báo để app nhắc bạn khi tới hạn thay nhớt và nhắc cập '
          'nhật số km mỗi tháng. Không có thông báo, app chỉ nhắc khi bạn '
          'tự mở lên.',
        ),
        actions: [
          // [NEW, PROVISIONAL]
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Để sau'),
          ),
          // [NEW, PROVISIONAL]
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Bật thông báo'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    // Written on ALL THREE exit paths — accept (`true`), decline
    // (`false`), or a dismissed dialog / back gesture (`null`) — because
    // the flag records "we asked", not "they said yes". Writing it only on
    // acceptance would re-prompt every launch for the user who declined,
    // exactly the hostile behaviour P4-D-05 exists to prevent.
    await ref
        .read(appProvider.notifier)
        .updateSettings((s) => s.copyWith(notificationPermissionAsked: true));

    // Only on the affirmative action, only after the dialog's future has
    // resolved: Android grants exactly one chance at `POST_NOTIFICATIONS`,
    // and asking bare is the fastest way to lose it permanently (P4-D-06).
    // The exact-alarm permission is never requested from this screen — its
    // one and only call site is the Settings opt-in row task 3 builds
    // (P4-D-07).
    if (accepted == true) {
      if (!context.mounted) return;
      await ref
          .read(notificationSchedulerProvider)
          .requestNotificationsPermission();
    }
  }

  /// P5-D-25/P5-D-26 (BKP-15): the Drive-backup offer, at most once per app
  /// install — gated on the persisted `Settings.driveBackupPromptShown`
  /// flag, the identical shape [_maybeShowNotificationPermissionPrompt]
  /// uses above. Reuses home's first-render-after-onboarding moment rather
  /// than adding an onboarding step (P4-D-05/P4-D-11's standing refusal to
  /// edit `onboarding_flow.dart`).
  Future<void> _maybeShowDriveBackupPrompt() async {
    // Guards `context` below against the async gap between this frame
    // being scheduled and this callback running (CLAUDE.md's
    // context-after-await trap; same guard the two effects above use).
    if (!context.mounted) return;
    if (_driveBackupPromptShown) return;
    // The build-time defensive early return covers the render path; this
    // callback runs outside `build`, so it needs its own guard against an
    // empty vehicle list — the offer only makes sense once the user has
    // something worth protecting.
    final data = ref.read(appProvider);
    if (data.vehicles.isEmpty) return;
    if (data.settings.driveBackupPromptShown) return;
    if (data.settings.driveBackupEnabled) return;
    // Keep the two prompts from stacking on the same frame: when the
    // notification-permission prompt above is about to show for the first
    // time, it sets [_permissionPromptShown] synchronously, before its own
    // first `await` — and because both calls in `initState`'s callback run
    // synchronously up to their first suspension point, that flag already
    // reflects the outcome by the time this method runs. If it is already
    // set, the notification dialog is opening (or already open) this same
    // frame, so this offer waits for a later app open instead of piling a
    // second modal on top of it.
    if (_permissionPromptShown) return;

    // Set BEFORE opening the sheet — mirrors the two effects above: an
    // await here would otherwise leave a re-entrancy hole for the callback
    // to fire again before the sheet returns.
    _driveBackupPromptShown = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _DriveBackupPromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final vehicle = ref.watch(selectedVehicleProvider);
    if (vehicle == null) {
      // The router's redirect never lets this screen build without a
      // vehicle (HOME-01) — this is a defensive no-op for the one frame
      // that could theoretically race it (or the frame between a vehicle
      // deletion and the router's redirect, 06-01), never expected to
      // render for long.
      return const Scaffold(body: SizedBox.shrink());
    }
    final dueItems = ref.watch(dueItemsProvider(vehicle.id));
    final colorScheme = Theme.of(context).colorScheme;

    // P3-D-02: a fixed one-month horizon, deliberately independent of
    // Settings.leadDays (which defaults to 7 and would hide §11.1's own
    // 14-day card). One pass over the already-sorted provider output so no
    // item can land in both groups or in neither; neither half is re-sorted.
    final needsAttention = <DueItem>[];
    final healthy = <DueItem>[];
    for (final dueItem in dueItems) {
      if (dueItem.due.daysLeft <= 30) {
        needsAttention.add(dueItem);
      } else {
        healthy.add(dueItem);
      }
    }

    final pinnedNotes = sortedNotes(data.notes)
        .where((note) => note.pinned)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: SafeArea(
        child: ListView(
          // 96 = 2 × 2xl, sized to the FAB's own Material footprint so the
          // last pinned note is never obscured by it (H1 overflow) — the
          // one deliberate exception to the spacing token table.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              vehicleHeaderLine(vehicle),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // NOTIF-11/P4-D-12: visibility comes entirely from the domain
            // predicate below — this widget re-derives no threshold. Placed
            // above the due-card loop deliberately: the user whose
            // notifications have gone quiet is precisely the user who
            // never opens Cài đặt, so the banner has to be where they
            // already look.
            if (shouldShowDeadNotificationBanner(data)) ...[
              const DeadNotificationBanner(),
              const SizedBox(height: 16),
            ],
            for (var i = 0; i < needsAttention.length; i++) ...[
              DueCard(dueItem: needsAttention[i], vehicle: vehicle),
              if (i != needsAttention.length - 1) const SizedBox(height: 16),
            ],
            // H1 zero-one-many: the divider block and the collapsed row are
            // one conditional unit on the healthy group being non-empty —
            // omitted together at N == 0 rather than rendering a "0" count
            // or leaving the divider stranded above an absent row.
            if (healthy.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              ExpansionTile(
                // N is ALWAYS interpolated from the filtered list at
                // runtime — never the mockup's illustrative literal
                // (P2-D-02's rule, reapplied here per P3-D-03).
                title: Text('${healthy.length} hạng mục khác đang ổn ›'),
                // Claude's Discretion (03-RESEARCH.md Pitfall 4,
                // 03-UI-SPEC.md's resolution for this surface specifically):
                // the verbatim "›" is the only indicator on this
                // higher-visibility row — do NOT retroactively apply this to
                // step4_items.dart's already-shipped leading "▸" glyph.
                trailing: const SizedBox.shrink(),
                children: [
                  for (final dueItem in healthy)
                    ListTile(
                      leading: Icon(
                        _iconForCatalogCode(dueItem.item.catalogCode),
                      ),
                      title: Text(dueItem.item.name),
                      onTap: () => context.push('/item/${dueItem.item.id}'),
                    ),
                ],
              ),
            ],
            // P3-D-16/HOME-06: no cap, no "see more" row — every pinned
            // note renders, or the section is absent entirely.
            if (pinnedNotes.isNotEmpty) ...[
              const SizedBox(height: 32),
              for (final note in pinnedNotes)
                ListTile(
                  leading: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(noteDisplayTitle(note)),
                  onTap: () => context.push('/notes/${note.id}'),
                ),
            ],
          ],
        ),
      ),
      // HOME-04: the single most prominent control on this screen — the
      // extended (labelled) form, not a bare circular FAB, kept at
      // Material's default end-float position. Material's own FAB colour
      // is already `colorScheme.primary`-derived, so no `backgroundColor`
      // override is added here (03-UI-SPEC.md reserves the accent for
      // exactly five CTAs across this phase; this is the first).
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.speed),
        label: const Text('Cập nhật số km'),
        onPressed: () => showOdoSheet(context, ref, vehicle),
      ),
    );
  }
}

/// §10.6 point 3 (NOTIF-11, P4-D-12) — the control that turns a silent
/// notification failure into a visible one. The domain predicate this
/// screen's `build` calls owns the whole decision of when this renders;
/// this widget re-derives nothing (§5.3, the same discipline
/// `due_card.dart` holds for `DueResult`'s booleans). Tapping it opens the
/// same battery-guidance sheet Cài đặt does — one implementation, two
/// entry points (P4-D-09).
///
/// Colour is the one hard constraint: never the error role. T-03-30
/// reserves red for overdue items only, verified on device this week, and
/// both home files carry a negative criterion against literal colour
/// constants. `tertiaryContainer`/`onTertiaryContainer` is a theme
/// container role that survives Phase 6's palette swap (REL-02) — the
/// specific choice of `tertiaryContainer` over `secondaryContainer` is
/// discretionary and flagged for UAT in 04-04-SUMMARY.md; the constraint
/// that binds is "not red", not which container role satisfies it.
class DeadNotificationBanner extends StatelessWidget {
  const DeadNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showBatteryHintSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // A neutral informational glyph, never the overdue card's
              // warning icon (T-03-30) — sharing it would dilute the
              // signal that icon protects.
              Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  // §10.6, byte-for-byte — do not reword, retranslate,
                  // reflow or shorten, and no exclamation mark: this
                  // reports a device setting the app cannot change on its
                  // own, not the user's neglect.
                  'Có vẻ thông báo không hoạt động. Xem cách khắc phục.',
                  style: TextStyle(color: colorScheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BKP-15's offer, opened by [_HomeScreenState._maybeShowDriveBackupPrompt].
/// A modal sheet, not a dialog and not a screen — D-33's cap is untouched,
/// the same call `battery_hint_sheet.dart` and `restore_sheet.dart` both
/// make, for the same reason P4-D-09/P5-D-01 give: accepting waits on the
/// network for sign-in, which a dialog is the wrong container for.
///
/// Both exit paths (accept, decline) write `driveBackupPromptShown: true`
/// and dismiss — the flag records "we asked", not "they said yes", the
/// identical rule [_HomeScreenState._maybeShowNotificationPermissionPrompt]
/// follows for its own persisted flag. A cancelled interactive sign-in is
/// the one path that changes nothing and leaves the sheet open: it is not a
/// decline, and spending the one-shot on it would deny the user the offer
/// they were in the middle of accepting.
class _DriveBackupPromptSheet extends ConsumerStatefulWidget {
  const _DriveBackupPromptSheet();

  @override
  ConsumerState<_DriveBackupPromptSheet> createState() =>
      _DriveBackupPromptSheetState();
}

class _DriveBackupPromptSheetState
    extends ConsumerState<_DriveBackupPromptSheet> {
  // Copies `restore_sheet.dart`'s `_working`/inline-error shape — the
  // closest existing precedent in this codebase for a sheet whose primary
  // action waits on a real network round trip (sign-in) rather than
  // resolving instantly.
  bool _working = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(googleAuthServiceProvider)
          .signInAndAuthorize();
      // CLAUDE.md trap: BuildContext/State used after an await.
      if (!mounted) return;
      if (result == null) {
        // A cancelled interactive sign-in is not a decline — leave the
        // sheet open and change nothing, so the user can try again.
        setState(() => _working = false);
        return;
      }
      // One updateSettings call sets all three fields together — no
      // intermediate state exists where the app believes backup is on
      // with no account, or where the prompt is spent but backup is not
      // actually enabled.
      await ref
          .read(appProvider.notifier)
          .updateSettings(
            (s) => s.copyWith(
              driveBackupEnabled: true,
              googleEmail: result.email,
              driveBackupPromptShown: true,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _driveBackupGenericFailureMessage;
      });
    }
  }

  Future<void> _decline() async {
    await ref
        .read(appProvider.notifier)
        .updateSettings((s) => s.copyWith(driveBackupPromptShown: true));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // [NEW, PROVISIONAL] — sheet title, not sourced verbatim anywhere.
          Text(
            _driveBackupPromptTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // [NEW, PROVISIONAL] — the offer, framed as protection against
          // losing the phone. Deliberately does not say the app "stores"
          // anything — it never does (D-15/D-16); the data goes straight
          // to the user's own Drive.
          Text(
            _driveBackupPromptOfferLine,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          // §7.1, byte-for-byte — the single most likely reason to decline
          // is not knowing what access is being granted, and this is the
          // sentence that answers it. Do not reword, retranslate, reflow
          // or shorten; enforced by the drive.appdata scope (D-22), not
          // merely asserted here.
          Text(
            'App chỉ thấy đúng file của nó.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          // [NEW, PROVISIONAL] — states plainly that declining is not
          // final, so the choice does not feel like a one-way door.
          Text(
            _driveBackupPromptLaterLine,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              // A plain, neutral refusal — never framed as a loss (no
              // "skip and risk losing your data", no guilt). D-18 and
              // prohibition P-05-06 both live here: a user who never signs
              // into Google is a first-class user of this app, not one who
              // failed to finish setup. Reuses the identical "Để sau"
              // label [_HomeScreenState._maybeShowNotificationPermissionPrompt]
              // already established for a neutral decline in this codebase.
              TextButton(
                onPressed: _working ? null : _decline,
                child: const Text('Để sau'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _working ? null : _accept,
                child: _working
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(_driveBackupAcceptLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Invented Vietnamese strings for this sheet — [NEW, PROVISIONAL], recorded
// verbatim in 05-07-SUMMARY.md per this plan's own <output> requirement.
// The "Để sau" decline label is NOT invented here — it reuses
// `_maybeShowNotificationPermissionPrompt`'s existing decline label
// verbatim, the established neutral-refusal idiom in this codebase.
const _driveBackupPromptTitle = 'Sao lưu lên Google Drive?';
const _driveBackupPromptOfferLine =
    'Nếu mất máy, dữ liệu bảo dưỡng của bạn vẫn còn nguyên trên Google Drive '
    'của chính bạn.';
const _driveBackupPromptLaterLine =
    'Bạn có thể bật việc này bất cứ lúc nào trong Cài đặt.';
const _driveBackupAcceptLabel = 'Bật sao lưu';
const _driveBackupGenericFailureMessage =
    'Không thể kết nối tới Google Drive. Vui lòng thử lại.';

/// `{name} · {plate} · {km} km · cập nhật {N} ngày` — §11.1's own example:
/// "Vision · 29A1-234.56 · ~18.665 km · cập nhật 10 ngày".
///
/// Three rules, each cited to the decision that requires it:
/// - the plate segment and its separator are omitted entirely when
///   [Vehicle.plate] is null or empty, and the name falls back to
///   "Xe của bạn" when [Vehicle.name] is empty (both are skippable at
///   onboarding, ONB-02);
/// - the km figure carries the `~` prefix if and only if
///   `estimateOdo(vehicle) > vehicle.currentOdoKm` (P3-D-04) — a per-vehicle
///   drift test, deliberately NOT the per-item `DueResult.isEstimate` flag,
///   which carries a 45-day threshold and would print weeks of accrued
///   drift as though it were a measured figure;
/// - `N` comes from [daysSinceOdoUpdate], which subtracts LOCAL civil dates
///   — subtracting raw timestamps truncates (CLAUDE.md's `inDays` trap).
String vehicleHeaderLine(Vehicle vehicle, {DateTime? now}) {
  final parts = <String>[vehicle.name.isEmpty ? 'Xe của bạn' : vehicle.name];

  if (vehicle.plate != null && vehicle.plate!.isNotEmpty) {
    parts.add(vehicle.plate!);
  }

  final est = estimateOdo(vehicle, now: now);
  final showTilde = est > vehicle.currentOdoKm;
  final kmValue = showTilde ? est : vehicle.currentOdoKm;
  final kmText = '${showTilde ? _tildePrefix : ''}${formatKm(kmValue)} km';
  parts.add(kmText);

  final days = daysSinceOdoUpdate(vehicle, now: now);
  // The zero-day case has no verbatim source string — §11.1 only gives the
  // "cập nhật 10 ngày" shape, and "cập nhật 0 ngày" reads as a defect on the
  // day of an update. This exact string is a planner proposal, not sourced
  // (03-01-PLAN.md, Flagged Assumptions #1) — flag for UAT review.
  parts.add(days == 0 ? 'cập nhật hôm nay' : 'cập nhật $days$_daySuffix');

  return parts.join(' · ');
}

/// Whole days between [vehicle]'s last ODO update and [now], on LOCAL civil
/// dates. Subtracting the raw UTC timestamps would truncate at the wrong
/// boundary instead of at local midnight — `lib/domain/due.dart`'s own
/// `_dateOnly` documents the identical off-by-one-day risk (CLAUDE.md's
/// `inDays` trap, called out twice in the source document).
int daysSinceOdoUpdate(Vehicle vehicle, {DateTime? now}) {
  final n = (now ?? DateTime.now()).toLocal();
  final updated = vehicle.odoUpdatedAt.toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final updatedDay = DateTime(updated.year, updated.month, updated.day);
  return today.difference(updatedDay).inDays;
}

/// Resolves a [MaintenanceItem.catalogCode] to its icon through `kCatalog`'s
/// existing `iconKey` field and `catalogIconFor`'s existing map — a nullable
/// (loop, not throwing-`firstWhere`) lookup, matching this codebase's
/// established convention for any lookup against a caller-supplied id
/// (`derived.dart`'s vehicle lookup, `addOdoReading`'s vehicle lookup): an
/// unknown code renders `catalogIconFor`'s own placeholder icon rather than
/// crashing the whole list.
IconData _iconForCatalogCode(String catalogCode) {
  for (final entry in kCatalog) {
    if (entry.code == catalogCode) return catalogIconFor(entry.iconKey);
  }
  return catalogIconFor(catalogCode);
}
