// lib/ui/item/item_detail_screen.dart — LOG-05, P3-D-14, P3-D-15. Read-first:
// current due status, the item's full service history, its attached notes,
// and exactly two actions — record a service, add a note. Nothing here edits
// the item (no interval field, no enable/disable toggle, no rename, no
// delete); P3-D-14 keeps this screen read-first on purpose so Phase 6's
// SET-02 has somewhere to land, and this screen is the most tempting place
// in the phase to accidentally recreate that scope.
//
// **Status wording (03-UI-SPEC.md H5 `populated`).** The four-branch status
// precedence used to live here as a private `_statusLine` helper (before
// the home due-card widget's own file existed at wave 4 — see
// 03-05-SUMMARY.md). Plan 06 task 1 promoted it into that file as the ONE
// public `resolveDueCardStatus` implementation (see the import below); this
// screen now calls that function instead of carrying its own copy, so an
// item's detail screen and its home card can never word the same state
// differently.
//
// Deliberately does NOT tint the overdue status line with `colorScheme
// .error` — `03-UI-SPEC.md`'s design-system rule for these two new files
// reserves `colorScheme.error` for the note editor's delete-confirmation
// dialog alone; this screen's status line stays default text colour
// regardless of `DueStatus`, matching the locked truth verbatim ("colour
// resolves through colorScheme.*" is about wording consistency with the
// home due card, not colour consistency).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog.dart';
import '../../domain/due.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/service_log.dart';
import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../catalog_icons.dart';
import '../home/due_card.dart';
import '../log/service_log_sheet.dart';
import '../notes/notes_screen.dart';
import '../widgets/formatters.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  MaintenanceItem? _findItem(List<MaintenanceItem> items, String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Vehicle? _findVehicle(List<Vehicle> vehicles, String id) {
    for (final v in vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  DueItem? _findDueItem(List<DueItem> dueItems, String id) {
    for (final d in dueItems) {
      if (d.item.id == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appData = ref.watch(appProvider);
    final item = _findItem(appData.items, itemId);
    final vehicle = item == null
        ? null
        : _findVehicle(appData.vehicles, item.vehicleId);

    if (item == null || vehicle == null) {
      // A derived screen that throws on an unknown id takes the whole app
      // down; Phase 6's item deletion makes a stale id genuinely reachable.
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy hạng mục')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hạng mục này không còn tồn tại.'),
          ),
        ),
      );
    }

    final dueItem = _findDueItem(
      ref.watch(dueItemsProvider(vehicle.id)),
      itemId,
    );

    final logs =
        appData.logs
            .where((log) => log.entries.any((e) => e.itemId == itemId))
            .toList()
          ..sort((a, b) {
            final byDate = b.date.compareTo(a.date); // newest first
            if (byDate != 0) return byDate;
            // Dart's List.sort is not stable — an explicit tie-break keeps
            // two same-day visits from reshuffling between rebuilds, the
            // same hardening dueItemsProvider/sortedNotes already carry.
            return a.id.compareTo(b.id);
          });

    final attachedNotes = appData.notes
        .where((n) => n.itemId == itemId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 24),
            _buildStatusBlock(context, item, vehicle, dueItem?.due),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => showServiceLogSheet(
                context,
                ref,
                vehicle: vehicle,
                preTickedItemId: item.id,
              ),
              child: const Text('Ghi lại'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                // P3-D-15: the only way a note ever carries vehicleId/itemId
                // — via query parameters on the same 'new' route the AppBar
                // create action also uses, never a picker on the editor.
                final uri = Uri(
                  path: '/notes/new',
                  queryParameters: {'vehicleId': vehicle.id, 'itemId': item.id},
                );
                context.push(uri.toString());
              },
              child: const Text('Thêm ghi chú'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Lịch sử',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              // [NEW, PROVISIONAL] — no verbatim source string exists for
              // this surface; flagged in the SUMMARY for UAT.
              const Text('Chưa có lịch sử bảo dưỡng cho hạng mục này.')
            else
              for (final log in logs) _buildHistoryRow(context, log, itemId),
            if (attachedNotes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              // [NEW, PROVISIONAL] — no verbatim source label exists for
              // this section either; flagged in the SUMMARY for UAT.
              const Text(
                'Ghi chú đính kèm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final note in attachedNotes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(noteDisplayTitle(note)),
                  onTap: () => context.push('/notes/${note.id}'),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBlock(
    BuildContext context,
    MaintenanceItem item,
    Vehicle vehicle,
    DueResult? due,
  ) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final lastServiceLine = _lastServiceLine(item);
    final partLine = _partLine(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconForCatalogCode(item.catalogCode),
              color: onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (due != null) ...[
          const SizedBox(height: 8),
          Text(
            resolveDueCardStatus(
              due,
              vehicle,
              isEngineOil: item.catalogCode == 'engine_oil',
            ).line,
            style: const TextStyle(fontSize: 16),
          ),
        ],
        if (lastServiceLine != null) ...[
          const SizedBox(height: 8),
          Text(lastServiceLine, style: const TextStyle(fontSize: 16)),
        ],
        if (partLine != null) ...[
          const SizedBox(height: 4),
          Text(
            partLine,
            style: TextStyle(fontSize: 12, color: onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryRow(BuildContext context, ServiceLog log, String itemId) {
    final entry = _entryFor(log, itemId);
    if (entry == null) {
      // Unreachable: `logs` above is already filtered to only include
      // ServiceLogs whose entries contain this itemId (plan 04's id-keyed
      // sheet state guarantees at most one match). Kept as a nullable,
      // non-throwing lookup rather than assuming the filter can never drift.
      return const SizedBox.shrink();
    }

    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final line1 =
        '${formatDate(log.date.toLocal())} · ${formatKm(log.odoKm)} km · '
        '${formatVnd(entry.costVnd ?? 0)}';

    // H5 partial: line 2 depends ONLY on brand/spec presence — omitted
    // entirely (never a blank line, never a dangling " · ") when both are
    // null/empty, even when a shop name exists.
    final partText = [
      entry.partBrand,
      entry.partSpec,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
    String? line2;
    if (partText.isNotEmpty) {
      final shop = log.shopName;
      line2 = (shop != null && shop.isNotEmpty)
          ? '$partText · $shop'
          : partText;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // H5 long-text: neither line sets maxLines or an ellipsis — a
          // long shop name or spec wraps by default.
          Text(line1, style: const TextStyle(fontSize: 16)),
          if (line2 != null)
            Text(
              line2,
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  ServiceLogEntry? _entryFor(ServiceLog log, String itemId) {
    for (final e in log.entries) {
      if (e.itemId == itemId) return e;
    }
    return null;
  }

  String? _lastServiceLine(MaintenanceItem item) {
    final date = item.lastServiceDate;
    final odo = item.lastServiceOdo;
    if (date == null && odo == null) return null;
    final parts = <String>[];
    if (date != null) parts.add(formatDate(date.toLocal()));
    if (odo != null) parts.add('${formatKm(odo)} km');
    return 'Lần trước: ${parts.join(' · ')}';
  }

  String? _partLine(MaintenanceItem item) {
    final parts = <String>[];
    final brand = item.partBrand;
    final spec = item.partSpec;
    if (brand != null && brand.isNotEmpty) parts.add(brand);
    if (spec != null && spec.isNotEmpty) parts.add(spec);
    var line = parts.join(' ').trim();
    final cost = item.lastCostVnd;
    if (cost != null) {
      line = line.isEmpty ? formatVnd(cost) : '$line · ${formatVnd(cost)}';
    }
    return line.isEmpty ? null : line;
  }
}

/// Resolves a [MaintenanceItem.catalogCode] to its icon through `kCatalog`'s
/// `iconKey` field and `catalogIconFor`'s map — the identical nullable-loop
/// idiom `home_screen.dart`'s own `_iconForCatalogCode` uses, duplicated
/// here rather than shared because that one is private to its file.
IconData _iconForCatalogCode(String catalogCode) {
  for (final entry in kCatalog) {
    if (entry.code == catalogCode) return catalogIconFor(entry.iconKey);
  }
  return catalogIconFor(catalogCode);
}
