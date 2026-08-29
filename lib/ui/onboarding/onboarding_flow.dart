// lib/ui/onboarding/onboarding_flow.dart — ConsumerStatefulWidget owning
// exactly one `OnboardingDraft` instance and a `PageController`. This plan
// (02-01) renders ONE page — the step-1 vehicle-type picker plus a numeric
// ODO field — to prove the tracer slice end to end. `_steps` is a list so
// plan 02 (steps 2, 4) and plan 05 (steps 3, 5, 6) insert their step
// widgets without restructuring this orchestrator.
//
// "Tiếp tục" is the ONE commit point of the whole flow: it calls
// `AppNotifier.completeOnboarding`, which is the only legal persistence
// path (DATA-06). No step widget may reach the repository directly or
// persist anything on its own.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/vehicle.dart';
import '../../state/app_state.dart';
import 'onboarding_draft.dart';

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

  @override
  void initState() {
    super.initState();
    _draft = OnboardingDraft()
      // Seeded here until plan 05 (P2-D-07's avg-km/day bands) and plan 02
      // (step 4's item-selection screen) replace these — functionality
      // gaps, not architectural ones.
      ..avgDailyKm = 20.0
      ..selectedCodes = {'engine_oil'};
  }

  @override
  void dispose() {
    _odoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final odo = int.tryParse(_odoController.text);
    if (_draft.type == null || odo == null) {
      setState(() {
        _error = 'Vui lòng chọn loại xe và nhập số km hiện tại.';
      });
      return;
    }
    _draft.currentOdoKm = odo;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết lập xe')),
      body: SafeArea(
        child: SingleChildScrollView(
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
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
