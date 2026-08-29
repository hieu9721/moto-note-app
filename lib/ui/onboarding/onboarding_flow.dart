// lib/ui/onboarding/onboarding_flow.dart — ConsumerStatefulWidget owning
// exactly one `OnboardingDraft` instance. Plan 02-01 rendered a single page
// (vehicle-type + ODO) to prove the tracer slice end to end; this plan
// (02-02) adds oil grade (step 5) as a simple forward-only `_step` index.
// Task 3 of this same plan inserts item selection (step 4) between them.
// Plan 05 replaces this index with the full six-step `PageView`/
// `IndexedStack` flow, its shared progress bar, and the "Quay lại"/
// "Tiếp tục" bottom action row (steps 2, 3, 6 do not exist yet).
//
// "Tiếp tục" on the LAST step is the ONE commit point of the whole flow: it
// calls `AppNotifier.completeOnboarding`, the only legal persistence path
// (DATA-06). No step widget may reach the repository directly or persist
// anything on its own.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import 'onboarding_draft.dart';
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

  /// 0 = vehicle-type + ODO (plan 02-01), 1 = oil grade (step 5, the
  /// current final step — commits on "Tiếp tục"). Task 3 of this plan
  /// inserts item selection between them.
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _draft = OnboardingDraft()
      // Seeded here until plan 05 (P2-D-07's avg-km/day bands) and task 3
      // of this plan (step 4's item-selection screen) replace these —
      // functionality gaps, not architectural ones.
      ..avgDailyKm = 20.0
      ..selectedCodes = {'engine_oil'};
  }

  @override
  void dispose() {
    _odoController.dispose();
    super.dispose();
  }

  void _goToStep5() {
    final odo = int.tryParse(_odoController.text);
    if (_draft.type == null || odo == null) {
      setState(() {
        _error = 'Vui lòng chọn loại xe và nhập số km hiện tại.';
      });
      return;
    }
    _draft.currentOdoKm = odo;
    setState(() {
      _error = null;
      _step = 1;
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
        _goToStep5();
      default:
        _submit();
    }
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
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _submitting ? null : _onContinuePressed,
                child: const Text('Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
