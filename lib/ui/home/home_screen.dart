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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/odo.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../catalog_icons.dart';
import '../notes/notes_screen.dart' show noteDisplayTitle, sortedNotes;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeSheetParam());
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
    // this callback runs outside `build`, so it needs its own guard against
    // an empty vehicle list.
    final data = ref.read(appProvider);
    if (data.vehicles.isEmpty) return;
    // Set BEFORE opening — an await on `showOdoSheet` here would leave a
    // re-entrancy hole for a callback fired again before the sheet returns.
    _consumedSheetParam = true;
    showOdoSheet(context, ref, data.vehicles.first);
    // Prefer `replace` so the back gesture does not walk back into the
    // parameterised URL; `go` is an acceptable substitute if `replace`
    // misbehaves inside the StatefulShellRoute branch (untriggered here).
    context.replace('/');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    if (data.vehicles.isEmpty) {
      // The router's redirect never lets this screen build without a
      // vehicle (HOME-01) — this is a defensive no-op for the one frame
      // that could theoretically race it, never expected to render.
      return const Scaffold(body: SizedBox.shrink());
    }
    // The model is multi-vehicle; SET-01 (Phase 6) owns choosing among
    // them. This phase always shows the first one.
    final vehicle = data.vehicles.first;
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
