// lib/ui/onboarding/step3_odo_avgkm.dart — ODO capture plus P2-D-07's three
// average-km/day bands and the P2-D-08 exact-entry escape.
//
// `lastServiceOdo = ODO − days × avgDaily` is written once at step 6's
// commit and never recomputed (02-05-PLAN.md objective), so both fields
// here are validated at ENTRY and rejected visibly when out of range —
// never silently clamped or defaulted. Per the UI-SPEC's E3 state coverage
// (a developer decision, not this file's own judgement): "Tiếp tục" stays
// disabled in `onboarding_flow.dart` until BOTH a valid odometer AND an
// average-km answer are present — an AND, not an OR — because a missing or
// defaulted average would permanently skew the engine-oil baseline.
//
// Both numeric fields are parsed with an explicit, locale-independent
// approach (T-02-03): Vietnamese formats thousands with `.` and decimals
// with `,`, so a locale-aware number-formatting parse of "18.420" could
// silently read as 18.42. The odometer strips every non-digit character
// before `int.tryParse`; the exact-average field accepts either `.` or `,`
// as its decimal mark before `double.tryParse`. Neither field's parse goes
// through `intl`, and no out-of-range input is coerced into range —
// rejected with a visible message instead (P2-D-08, T-02-02).
//
// Reads its initial state from `draft` in `initState`, never from empty —
// going back to this step and forward again preserves the odometer text
// and the selected band/exact value, since the draft is the single source
// of truth and is never reset on revisit.
import 'package:flutter/material.dart';

import '../../state/onboarding_draft.dart';

class Step3OdoAvgKm extends StatefulWidget {
  const Step3OdoAvgKm({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final OnboardingDraft draft;
  final VoidCallback onChanged;

  @override
  State<Step3OdoAvgKm> createState() => _Step3OdoAvgKmState();
}

class _Step3OdoAvgKmState extends State<Step3OdoAvgKm> {
  // T-02-01: bounds a motorcycle odometer must satisfy — never negative,
  // capped at a sane upper bound so an accidental extra digit is caught at
  // entry rather than becoming a permanent offset.
  static const int _minOdo = 0;
  static const int _maxOdo = 1000000;

  // P2-D-08: the same [0.5, 400] bound `refineAvgDailyKm` clamps its own
  // result to — a declared value can never sit outside the range the
  // engine accepts.
  static const double _minAvg = 0.5;
  static const double _maxAvg = 400;

  /// A bound as it should READ in the error message. Both bounds are `double`,
  /// so plain interpolation rendered the upper one as "400.0" — a number no
  /// user typed and no copy asked for. Whole values lose the trailing ".0";
  /// 0.5 keeps its decimal.
  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  // P2-D-07's three band midpoints, in display order.
  static const List<double> _bands = [7, 20, 45];

  late final TextEditingController _odoController;
  late final TextEditingController _exactController;
  String? _odoError;
  String? _avgError;
  bool _showExact = false;

  @override
  void initState() {
    super.initState();
    _odoController = TextEditingController(
      text: widget.draft.currentOdoKm?.toString() ?? '',
    );
    final current = widget.draft.avgDailyKm;
    _showExact = current != null && !_bands.contains(current);
    _exactController = TextEditingController(
      text: _showExact ? current!.toString() : '',
    );
  }

  @override
  void dispose() {
    _odoController.dispose();
    _exactController.dispose();
    super.dispose();
  }

  void _onOdoChanged(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      setState(() {
        widget.draft.currentOdoKm = null;
        _odoError = null;
      });
      widget.onChanged();
      return;
    }
    final parsed = int.tryParse(digitsOnly, radix: 10);
    if (parsed == null || parsed < _minOdo || parsed > _maxOdo) {
      setState(() {
        widget.draft.currentOdoKm = null;
        _odoError = 'Số km không hợp lệ (0 – 1.000.000).';
      });
    } else {
      setState(() {
        widget.draft.currentOdoKm = parsed;
        _odoError = null;
      });
    }
    widget.onChanged();
  }

  void _onBandSelected(double? band) {
    setState(() {
      _showExact = false;
      _avgError = null;
      widget.draft.avgDailyKm = band;
    });
    widget.onChanged();
  }

  void _toggleExact() {
    setState(() {
      _showExact = !_showExact;
      if (_showExact) {
        // Revealing the exact field drops any band selection — the two
        // paths are mutually exclusive, and nothing is a valid average
        // until the user finishes typing one.
        widget.draft.avgDailyKm = null;
        _avgError = null;
      }
    });
    widget.onChanged();
  }

  void _onExactChanged(String raw) {
    final normalized = raw.replaceAll(',', '.');
    if (normalized.trim().isEmpty) {
      setState(() {
        widget.draft.avgDailyKm = null;
        _avgError = null;
      });
      widget.onChanged();
      return;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < _minAvg || parsed > _maxAvg) {
      setState(() {
        widget.draft.avgDailyKm = null;
        _avgError =
            'Giá trị phải trong khoảng ${_plain(_minAvg)} – ${_plain(_maxAvg)} km/ngày.';
      });
    } else {
      setState(() {
        widget.draft.avgDailyKm = parsed;
        _avgError = null;
      });
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBand = _showExact ? null : widget.draft.avgDailyKm;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Số km hiện tại',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _odoController,
            keyboardType: TextInputType.number,
            onChanged: _onOdoChanged,
            decoration: InputDecoration(suffixText: 'km', errorText: _odoError),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mỗi ngày đi khoảng bao nhiêu km?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          RadioGroup<double?>(
            groupValue: selectedBand,
            onChanged: _onBandSelected,
            child: const Column(
              children: [
                RadioListTile<double?>(
                  title: Text('Ít · dưới 10 km'),
                  value: 7.0,
                ),
                RadioListTile<double?>(
                  title: Text('Vừa · 10–30 km'),
                  value: 20.0,
                ),
                RadioListTile<double?>(
                  title: Text('Nhiều · trên 30 km'),
                  value: 45.0,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _toggleExact,
              child: const Text('Tôi biết con số chính xác'),
            ),
          ),
          if (_showExact)
            TextField(
              controller: _exactController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onExactChanged,
              decoration: InputDecoration(
                suffixText: 'km/ngày',
                errorText: _avgError,
              ),
            ),
        ],
      ),
    );
  }
}
