// lib/ui/home/home_screen.dart — HOME-01/HOME-02. The tracer's destination
// screen: a real vehicle header under P3-D-04's honesty rule plus the real
// `dueItemsProvider` list, replacing `main.dart`'s temporary
// `_PostOnboardingPlaceholder`/`_DueItemTile`.
//
// Built as a plain, non-builder `ListView(children: [...])` rather than
// `ListView.builder` — the content is bounded at roughly one vehicle's
// fifteen items (03-RESEARCH.md Pattern 3), and a future plan's collapsed
// `ExpansionTile` row would otherwise walk straight into three still-open
// Flutter issues about builder-based recycling.
//
// §5.3's rule holds here: this widget neither sorts, filters nor recomputes
// any item's status — `dueItemsProvider` already returns the list sorted by
// urgency with a deterministic tie-break, and `DueResult` (plan 02) owns
// every status computation. No floating action button yet — plan 03 adds it
// together with the sheet it opens, so this slice ships no button that does
// nothing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/odo.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../catalog_icons.dart';
import '../widgets/formatters.dart';

// Standalone literals rather than inlined interpolation fragments, so the
// zero-prefix and the "ngày" suffix are each a single, greppable source of
// truth for their exact rendering.
const _tildePrefix = '~';
const _daySuffix = ' ngày';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              vehicleHeaderLine(vehicle),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final dueItem in dueItems)
              ListTile(
                leading: Icon(_iconForCatalogCode(dueItem.item.catalogCode)),
                title: Text(dueItem.item.name),
                subtitle: Text('Còn ${dueItem.due.daysLeft}$_daySuffix'),
              ),
          ],
        ),
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
