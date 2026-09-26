// lib/ui/home/due_card.dart — HOME-05, HOME-03. The three §9.5 renderings
// plus the overdue form 03-UI-SPEC.md added, collapsed into one four-branch
// precedence, and the two actions that actually fix what a card complains
// about.
//
// **Promoted from item_detail_screen.dart (03-06 task 1).** Plan 05 built
// this same four-branch resolution as a private helper inside
// `item_detail_screen.dart` because this file did not exist at wave 4
// (03-05-SUMMARY.md). It is promoted here as the ONE public implementation
// so H5 `populated`'s "an item's detail screen and its home card never word
// the same state differently" is a structural fact, not a hope —
// `item_detail_screen.dart`'s single call site now calls this function
// instead of carrying its own private copy.
//
// **Branch 1 (overdue) supersedes this plan's original three-branch
// ordering.** `03-UI-SPEC.md` moved the overdue check to the front of the
// chain, short-circuiting before either honesty flag is read (this plan's
// "Flagged planner decisions" item 2): an overdue card reads
// "Quá hạn {n} ngày · {km} km" with no honesty qualifier appended, and
// always offers [ Tôi vừa thay ] — the one action that resolves a guessed
// baseline, regardless of which flag also happens to be true.
//
// **The kmLeft clause is guarded on non-null AND negative** — stricter than
// `03-UI-SPEC.md`'s own null-only rule (this plan's "Flagged planner
// decisions" item 3): a positive `kmLeft` on a time-overdue item would read
// as "overdue by 400 km" when the truth is the opposite.
//
// **The odometer-age clause ("... tháng") is COMPUTED, never the mockup's
// fixed "2 tháng" literal** — 03-06-PLAN.md's own task 1 explicitly overrides
// `03-UI-SPEC.md`'s per-screen-contract closing paragraph on this one point
// ("only the second [substring] is a computed value in this plan"). Computed
// from the vehicle's own `odoUpdatedAt` via `daysSinceOdoUpdate`
// (home_screen.dart) on LOCAL civil dates, never the domain's 45-day
// threshold re-derived here (§5.3, P3-D-01).
//
// **The plain (fourth) branch keeps the oil/non-oil split** (this plan's
// "Flagged planner decisions" item 1): §9.5's own sentence is oil-specific
// ("... tới hạn thay nhớt"); every other item uses §11.1's generic card form
// ("Còn {n} ngày"). Both are verbatim source strings used where the source
// uses them — the deleted `_DueItemTile` already special-cased engine oil
// for the identical reason.
//
// **The engine-oil guessed-baseline prompt is carried across unchanged**
// from the deleted `_DueItemTile` (main.dart, pre-03-01, 02-05-PLAN.md Task
// 2) — §6.1's own wording, already shipped and UAT-passed in Phase 2. Never
// reworded.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog.dart';
import '../../domain/due.dart';
import '../../domain/models/vehicle.dart';
import '../../state/derived.dart';
import '../catalog_icons.dart';
import '../log/service_log_sheet.dart';
import 'home_screen.dart' show daysSinceOdoUpdate;
import 'odo_sheet.dart';

/// Which action, if any, a due card's status line calls for.
enum DueCardActionKind { logService, updateOdo, none }

/// The status line plus the action identity the four-branch precedence
/// resolves to. A due card renders both; `item_detail_screen.dart`'s status
/// block reads only [line], since its own status text never tints or offers
/// an action (that screen's `[ Ghi lại ]`/`[ Thêm ghi chú ]` buttons are
/// fixed and unconditional, per P3-D-14).
class DueCardStatus {
  const DueCardStatus({required this.line, required this.action});

  final String line;
  final DueCardActionKind action;
}

/// The four-branch §9.5/§11.1 status-line-and-action precedence
/// (`03-UI-SPEC.md`'s due-card table), promoted from
/// `item_detail_screen.dart`'s former private `_statusLine` (see this file's
/// header). Reads only the two domain-computed booleans on [due] — never
/// re-derives the 45-day staleness threshold or reads an item's own guess
/// flag directly (§5.3, P3-D-01). [isEngineOil] selects the fourth branch's
/// oil-specific sentence and appends the carried-across oil prompt to the
/// second branch.
DueCardStatus resolveDueCardStatus(
  DueResult due,
  Vehicle vehicle, {
  required bool isEngineOil,
}) {
  if (due.status == DueStatus.overdue) {
    // Guarded non-null AND negative — stricter than 03-UI-SPEC.md's
    // null-only rule (see file header).
    final km = due.kmLeft;
    final kmClause = (km != null && km < 0) ? ' · ${km.abs()} km' : '';
    return DueCardStatus(
      line: 'Quá hạn ${-due.daysLeft} ngày$kmClause',
      action: DueCardActionKind.logService,
    );
  }

  if (due.baselineIsGuess) {
    var line = 'Ước tính còn ${due.daysLeft} ngày · chưa có mốc thay thật';
    if (isEngineOil) {
      // Carried across unchanged from the deleted _DueItemTile — §6.1's own
      // wording, already shipped and UAT-passed in Phase 2.
      line = '$line\nBạn vừa thay nhớt? Ghi lại để app tính đúng';
    }
    return DueCardStatus(line: line, action: DueCardActionKind.logService);
  }

  if (due.odoIsStale) {
    // Computed, never the mockup's fixed "2 tháng" — see file header.
    final months = (daysSinceOdoUpdate(vehicle) / 30).floor();
    return DueCardStatus(
      line: 'Còn khoảng ${due.daysLeft} ngày · số km đã cũ $months tháng',
      action: DueCardActionKind.updateOdo,
    );
  }

  return DueCardStatus(
    line: isEngineOil
        ? 'Còn ${due.daysLeft} ngày nữa tới hạn thay nhớt'
        : 'Còn ${due.daysLeft} ngày',
    action: DueCardActionKind.none,
  );
}

/// One card per [DueItem] — HOME-03/HOME-05. Tappable to `/item/{id}`; the
/// action button (if any) sits below the status line, outside the tappable
/// row so a tap on the button never also triggers the card's own navigation.
class DueCard extends ConsumerWidget {
  const DueCard({super.key, required this.dueItem, required this.vehicle});

  final DueItem dueItem;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = dueItem.item;
    final due = dueItem.due;
    final overdue = due.status == DueStatus.overdue;
    final colorScheme = Theme.of(context).colorScheme;
    final status = resolveDueCardStatus(
      due,
      vehicle,
      isEngineOil: item.catalogCode == 'engine_oil',
    );

    Widget? actionButton;
    switch (status.action) {
      case DueCardActionKind.logService:
        actionButton = FilledButton(
          onPressed: () => showServiceLogSheet(
            context,
            ref,
            vehicle: vehicle,
            preTickedItemId: item.id,
          ),
          child: const Text('Tôi vừa thay'),
        );
      case DueCardActionKind.updateOdo:
        actionButton = OutlinedButton(
          onPressed: () => showOdoSheet(context, ref, vehicle),
          child: const Text('Cập nhật số km'),
        );
      case DueCardActionKind.none:
        actionButton = null;
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('/item/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exactly one leading glyph per card: the warning icon
                  // REPLACES the catalog icon on an overdue card rather than
                  // joining it (§11.1's single ⚠ per card).
                  Icon(
                    overdue
                        ? Icons.warning_rounded
                        : _iconForCatalogCode(item.catalogCode),
                    color: overdue
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  // No maxLines/TextOverflow — a long user-edited name makes
                  // the card taller rather than truncating (H2 long-text).
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
              const SizedBox(height: 8),
              Text(
                status.line,
                style: TextStyle(
                  fontSize: 16,
                  color: overdue ? colorScheme.error : null,
                ),
              ),
              if (actionButton != null) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actionButton),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolves a [MaintenanceItem.catalogCode] to its icon — the identical
/// nullable-loop idiom `home_screen.dart`'s and `item_detail_screen.dart`'s
/// own private copies use, duplicated here rather than shared because each
/// is private to its file.
IconData _iconForCatalogCode(String catalogCode) {
  for (final entry in kCatalog) {
    if (entry.code == catalogCode) return catalogIconFor(entry.iconKey);
  }
  return catalogIconFor(catalogCode);
}
