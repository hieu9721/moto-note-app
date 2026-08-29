// lib/state/derived.dart — DUE-06. Transcribed from §5.3's `dueItemsProvider`
// listing, with two deliberate hardenings over the literal source text
// (each explained inline below). This provider is the read side: it never
// calls `_mutate` and never touches `AppNotifier` — §5.3's rule is that
// widgets never compute item status themselves, `computeDue` does.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/due.dart';
import '../domain/models/maintenance_item.dart';
import '../domain/models/vehicle.dart';
import 'app_state.dart';

/// A maintenance item paired with its already-computed due status.
class DueItem {
  final MaintenanceItem item;
  final DueResult due;

  const DueItem({required this.item, required this.due});
}

/// Danh sách hạng mục của một xe kèm trạng thái, đã sắp theo độ gấp (§5.3).
final dueItemsProvider = Provider.family<List<DueItem>, String>((
  ref,
  vehicleId,
) {
  final data = ref.watch(appProvider);

  // Hardening 1: §5.3's literal listing resolves the vehicle with a
  // throwing `firstWhere`, which raises a StateError for an id matching
  // nothing. A derived provider that throws takes the whole screen down,
  // and D-19 says no screen waits on anything — including a lookup that
  // may legitimately miss during a Phase 6 vehicle deletion. Use a
  // nullable lookup and return an empty list instead.
  Vehicle? vehicle;
  for (final v in data.vehicles) {
    if (v.id == vehicleId) {
      vehicle = v;
      break;
    }
  }
  if (vehicle == null) return const <DueItem>[];

  final result = <DueItem>[];
  for (final item in data.items.where((i) => i.vehicleId == vehicleId)) {
    final due = computeDue(item, vehicle, data.settings.leadDays);
    if (due != null) result.add(DueItem(item: item, due: due));
  }

  // Hardening 2: Dart's List.sort is not stable, so two items with the
  // same daysLeft would land in an unspecified order and could reshuffle
  // between frames. Give the comparator an explicit secondary key —
  // catalogCode — so the order is deterministic.
  result.sort((a, b) {
    final byDaysLeft = a.due.daysLeft.compareTo(b.due.daysLeft);
    if (byDaysLeft != 0) return byDaysLeft;
    return a.item.catalogCode.compareTo(b.item.catalogCode);
  });
  return result;
});
