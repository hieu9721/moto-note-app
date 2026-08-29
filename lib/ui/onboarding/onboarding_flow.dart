// lib/ui/onboarding/onboarding_flow.dart — ConsumerStatefulWidget owning
// exactly one `OnboardingDraft` instance. Plan 02-01 rendered a single page
// (vehicle-type + ODO) to prove the tracer slice end to end; this plan
// (02-02) adds two more steps — item selection (step 4) and oil grade
// (step 5) — as a simple forward-only `_step` index. Plan 05 replaces this
// index with the full six-step `PageView`/`IndexedStack` flow, its shared
// progress bar, and the "Quay lại"/"Tiếp tục" bottom action row (steps 2,
// 3, 6 do not exist yet).
//
// "Tiếp tục" on the LAST step is the ONE commit point of the whole flow: it
// calls `AppNotifier.completeOnboarding`, the only legal persistence path
// (DATA-06). No step widget may reach the repository directly or persist
// anything on its own.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog.dart';
import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import 'onboarding_draft.dart';
import 'step4_items.dart';
import 'step5_oil_grade.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final OnboardingDraft _draft;
  final _odoController = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// 0 = vehicle-type + ODO (plan 02-01), 1 = item selection (step 4),
  /// 2 = oil grade (step 5, the current final step — commits on
  /// "Tiếp tục").
  int _step = 0;

  /// Tracks which [VehicleType] step 4's `draft.selectedCodes` was last
  /// seeded for, so re-entering step 4 for the SAME type never clobbers a
  /// user's manual toggles, but changing type re-seeds from the new type's
  /// `defaultOn` set.
  VehicleType? _step4SeededType;

  @override
  void initState() {
    super.initState();
    _draft = OnboardingDraft()
      // Seeded here until plan 05 (P2-D-07's avg-km/day bands) replaces
      // this — a functionality gap, not an architectural one.
      ..avgDailyKm = 20.0;
  }

  @override
  void dispose() {
    _odoController.dispose();
    super.dispose();
  }

  void _seedStep4IfNeeded() {
    if (_step4SeededType == _draft.type) return;
    _draft.selectedCodes = catalogFor(_draft.type!)
        .where((e) => e.defaultOn)
        .map((e) => e.code)
        .toSet();
    _step4SeededType = _draft.type;
  }

  void _goToStep4() {
    final odo = int.tryParse(_odoController.text);
    if (_draft.type == null || odo == null) {
      setState(() {
        _error = 'Vui lòng chọn loại xe và nhập số km hiện tại.';
      });
      return;
    }
    _draft.currentOdoKm = odo;
    _seedStep4IfNeeded();
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  void _goToStep5() {
    if (_draft.selectedCodes.isEmpty) {
      setState(() {
        _error = 'Vui lòng chọn ít nhất một hạng mục.';
      });
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(appProvider.notifier).completeOnboarding(_draft);
      if (!mounted) return;
      // `main.dart` watches `appProvider`'s vehicles list and its `home:`
      // has already swapped away from onboarding by the time this await
      // resolves — but `WelcomeScreen` reached this screen via
      // `Navigator.push`, so THIS route is still sitting on top of that
      // already-updated home route and must be popped explicitly, or the
      // user is stranded looking at a dead screen (on-device tracer
      // verification caught this — see 02-01-SUMMARY.md). A single pop
      // dismisses the whole flow regardless of how many internal steps it
      // grows to in plan 05 — no nested Navigator is introduced here.
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể lưu thông tin xe. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _onContinuePressed() {
    switch (_step) {
      case 0:
        _goToStep4();
      case 1:
        _goToStep5();
      default:
        _submit();
    }
  }

  bool get _continueEnabled {
    if (_submitting) return false;
    if (_step == 1) return _draft.selectedCodes.isNotEmpty;
    return true;
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Loại xe của bạn?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          RadioGroup<VehicleType>(
            groupValue: _draft.type,
            onChanged: (v) => setState(() => _draft.type = v),
            child: const Column(
              children: [
                RadioListTile<VehicleType>(
                  title: Text('Tay ga'),
                  value: VehicleType.scooter,
                ),
                RadioListTile<VehicleType>(
                  title: Text('Xe số'),
                  value: VehicleType.underbone,
                ),
                RadioListTile<VehicleType>(
                  title: Text('Côn tay'),
                  value: VehicleType.manual,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Số km hiện tại',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _odoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(suffixText: 'km'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_step) {
      0 => _buildStep0(),
      1 => Step4Items(draft: _draft, onChanged: () => setState(() {})),
      _ => Step5OilGrade(draft: _draft, onChanged: () => setState(() {})),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Thiết lập xe')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _continueEnabled ? _onContinuePressed : null,
                child: const Text('Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
