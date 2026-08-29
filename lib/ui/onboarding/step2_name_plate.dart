// lib/ui/onboarding/step2_name_plate.dart — ONB-02's skippable name/plate
// step. Neither field is validated beyond whitespace trimming (T-02-06 in
// 02-05-PLAN.md's threat register): a real Vietnamese plate has several
// regional formats, and rejecting one the user actually has would be worse
// than storing it as typed. "Tiếp tục" is unconditionally enabled on this
// step in `onboarding_flow.dart` — skipping both fields is a first-class,
// documented outcome: `Vehicle.name` lands as `''` (`draft.name ?? ''` at
// commit), `Vehicle.plate` stays `null`.
//
// Reads its initial text from `draft` on construction rather than starting
// empty, so going back to this step and forward again preserves whatever
// was already typed — the draft is the single source of truth and is never
// reset or re-seeded on revisit.
import 'package:flutter/material.dart';

import 'onboarding_draft.dart';

class Step2NamePlate extends StatefulWidget {
  const Step2NamePlate({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final OnboardingDraft draft;
  final VoidCallback onChanged;

  @override
  State<Step2NamePlate> createState() => _Step2NamePlateState();
}

class _Step2NamePlateState extends State<Step2NamePlate> {
  late final TextEditingController _nameController;
  late final TextEditingController _plateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name ?? '');
    _plateController = TextEditingController(text: widget.draft.plate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    // Store the trimmed text as-is (possibly empty) — Vehicle.name is a
    // required non-null String, so `draft.name ?? ''` at commit already
    // handles an empty/never-typed name; no null-vs-empty distinction is
    // needed on this field.
    widget.draft.name = value.trim();
    widget.onChanged();
  }

  void _onPlateChanged(String value) {
    // Vehicle.plate is nullable — an empty plate must land as null, not
    // as an empty string, per ONB-02's skip contract.
    final trimmed = value.trim();
    widget.draft.plate = trimmed.isEmpty ? null : trimmed;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final captionColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tên & biển số',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '(bỏ qua được)',
            style: TextStyle(fontSize: 12, color: captionColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            onChanged: _onNameChanged,
            decoration: const InputDecoration(hintText: 'Tên xe'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _plateController,
            onChanged: _onPlateChanged,
            decoration: const InputDecoration(hintText: 'Biển số'),
          ),
        ],
      ),
    );
  }
}
