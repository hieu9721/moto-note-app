// lib/ui/onboarding/step5_oil_grade.dart — CAT-03 oil-grade picker. Renders
// `kOilPresets` in declaration order (mineral first, cheapest first per
// §8.3) as a `RadioGroup<OilGrade>` — the same ancestor + `RadioListTile<T>`
// shape step 1 already established (RadioGroup<T> pattern,
// 02-01-SUMMARY.md "patterns-established").
//
// Picking a grade writes `draft.oilGrade` and calls [onChanged] so the
// parent `OnboardingFlow` can rebuild; nothing is committed here — the flow
// still persists exactly once, at its single commit point (RESEARCH.md
// Pattern 2 / Anti-Patterns: no per-step writes to the notifier). The
// confirmation line below the picker is always built from the selected
// `OilPreset`'s own fields (`preset.km`/`preset.months`), never a second
// hardcoded copy of the numbers.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/vehicle.dart';
import '../../domain/oil_presets.dart';
import 'onboarding_draft.dart';

class Step5OilGrade extends StatelessWidget {
  const Step5OilGrade({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final OnboardingDraft draft;
  final VoidCallback onChanged;

  static final _kmFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final selectedGrade = draft.oilGrade;
    final preset = selectedGrade == null ? null : kOilPresets[selectedGrade];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Loại nhớt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioGroup<OilGrade>(
            groupValue: selectedGrade,
            onChanged: (v) {
              draft.oilGrade = v;
              onChanged();
            },
            child: Column(
              children: [
                for (final entry in kOilPresets.entries)
                  RadioListTile<OilGrade>(
                    value: entry.key,
                    title: Text(entry.value.label),
                    subtitle: Text(
                      '${_kmFormat.format(entry.value.km)} km · '
                      '${entry.value.months} tháng\n'
                      '${entry.value.hint}',
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
          ),
          if (preset != null) ...[
            const SizedBox(height: 16),
            Text(
              'Với nhớt ${preset.label.toLowerCase()}, app sẽ nhắc bạn mỗi '
              '~${_kmFormat.format(preset.km)} km hoặc ${preset.months} '
              'tháng.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Đây là khoảng khuyến nghị chung. Chạy nội đô kẹt xe, ngập '
            'nước, chở nặng thì nên rút ngắn. Sổ tay theo xe của hãng vẫn '
            'là căn cứ chính xác nhất cho từng model.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
