// lib/ui/onboarding/step4_items.dart — ONB-03 item-selection step.
// Renders catalogFor(draft.type) split into a `defaultOn` top group
// (pre-checked) and a collapsed "advanced" group inside an `ExpansionTile`,
// per P2-D-01/02/03. `CatalogEntry` carries no `advanced` field (P2-D-02):
// both groups are derived from `defaultOn` here, never from a second list.
//
// Pure presentational widget — `draft.selectedCodes` (a `Set<String>`,
// owned by the parent `OnboardingFlow` via `OnboardingDraft`) is the single
// source of truth. Checkbox taps mutate it directly and call [onChanged]
// so the parent can rebuild (e.g. re-evaluate whether "Tiếp tục" should be
// enabled) — this widget never reaches the persistence layer itself
// (RESEARCH.md Anti-Patterns).
import 'package:flutter/material.dart';

import '../../domain/catalog.dart';
import '../catalog_icons.dart';
import 'onboarding_draft.dart';

class Step4Items extends StatelessWidget {
  const Step4Items({super.key, required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final VoidCallback onChanged;

  void _toggle(String code, bool? checked) {
    if (checked ?? false) {
      draft.selectedCodes.add(code);
    } else {
      draft.selectedCodes.remove(code);
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final entries = catalogFor(draft.type!);
    final topGroup = entries.where((e) => e.defaultOn).toList();
    final collapsedGroup = entries.where((e) => !e.defaultOn).toList();
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Theo dõi những gì?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn sau cũng được.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          for (final entry in topGroup)
            CheckboxListTile(
              value: draft.selectedCodes.contains(entry.code),
              onChanged: (v) => _toggle(entry.code, v),
              secondary: Icon(catalogIconFor(entry.iconKey), color: iconColor),
              title: Text(entry.nameVi),
              // P2-D-03: only engine_oil keeps its §8.2 mockup subtitle in
              // the top group — every other top-group item shows its name
              // only.
              subtitle: entry.code == 'engine_oil'
                  ? const Text('Quan trọng nhất')
                  : null,
            ),
          ExpansionTile(
            // The count is ALWAYS interpolated from the filtered list at
            // runtime — never the literal §8.2 mockup digit (7). P2-D-02.
            title: Text("▸ ${collapsedGroup.length} hạng mục nâng cao"),
            children: [
              for (final entry in collapsedGroup)
                CheckboxListTile(
                  value: draft.selectedCodes.contains(entry.code),
                  onChanged: (v) => _toggle(entry.code, v),
                  secondary: Icon(
                    catalogIconFor(entry.iconKey),
                    color: iconColor,
                  ),
                  title: Text(entry.nameVi),
                  // P2-D-03: hints render ONLY inside the collapsed group —
                  // this is where conditional-hardware hints actually
                  // change a user's decision.
                  subtitle: entry.hint != null ? Text(entry.hint!) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
