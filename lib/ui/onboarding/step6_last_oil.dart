// lib/ui/onboarding/step6_last_oil.dart — ONB-04, the §6.1 last-oil-change
// question. Asked for engine oil ALONE — every other selected item keeps
// the "không nhớ" default `OnboardingDraft.buildSelectedItems` already
// applies, without being asked about (§6.1: asking about every item is the
// fastest way to make someone abandon onboarding).
//
// Selecting an option writes `draft.lastOilChoice`; nothing is committed
// here — `buildSelectedItems` turns the choice into the engine-oil
// baseline at the flow's single commit point (`completeOnboarding`, called
// once after this step's "Tiếp tục").
//
// "Không nhớ" carries its own explanatory line using §6.1's own framing —
// "Thà im lặng còn hơn nhắc bừa" — so the user understands they are
// choosing silence rather than being penalised for not remembering.
import 'package:flutter/material.dart';

import 'onboarding_draft.dart';

class Step6LastOil extends StatelessWidget {
  const Step6LastOil({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final OnboardingDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final captionColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lần cuối thay nhớt?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioGroup<LastOilChoice>(
            groupValue: draft.lastOilChoice,
            onChanged: (v) {
              draft.lastOilChoice = v;
              onChanged();
            },
            child: Column(
              children: [
                const RadioListTile<LastOilChoice>(
                  title: Text('Dưới 1 tháng'),
                  value: LastOilChoice.under1Month,
                ),
                const RadioListTile<LastOilChoice>(
                  title: Text('1–3 tháng'),
                  value: LastOilChoice.oneToThreeMonths,
                ),
                const RadioListTile<LastOilChoice>(
                  title: Text('Trên 3 tháng'),
                  value: LastOilChoice.over3Months,
                ),
                RadioListTile<LastOilChoice>(
                  title: const Text('Không nhớ'),
                  subtitle: Text(
                    'Thà im lặng còn hơn nhắc bừa.',
                    style: TextStyle(fontSize: 12, color: captionColor),
                  ),
                  value: LastOilChoice.dontRemember,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
