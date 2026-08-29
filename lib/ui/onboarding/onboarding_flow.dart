// lib/ui/onboarding/onboarding_flow.dart — ConsumerStatefulWidget owning
// exactly one `OnboardingDraft` instance. Plan 02-01 rendered a single page
// (vehicle-type + ODO) to prove the tracer slice end to end; plan 02-02
// added item selection (step 4) and oil grade (step 5). This plan (02-05)
// inserts name/plate (step 2) and ODO + average km/day (step 3) between
// vehicle-type and item selection, moving the temporary ODO field off step
// 1 and replacing plan 01's hardcoded `avgDailyKm = 20.0` seed with real
// UI (P2-D-07's bands plus the P2-D-08 exact-entry escape).
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
import 'step2_name_plate.dart';
import 'step3_odo_avgkm.dart';
import 'step4_items.dart';
import 'step5_oil_grade.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final OnboardingDraft _draft;
  bool _submitting = false;
  String? _error;

  /// 0 = vehicle type, 1 = name/plate (plan 05), 2 = ODO + avg km/day
  /// (plan 05), 3 = item selection, 4 = oil grade — the current final step
  /// (commits on "Tiếp tục").
  int _step = 0;

  /// Tracks which [VehicleType] step 4's `draft.selectedCodes` was last
  /// seeded for, so re-entering step 4 for the SAME type never clobbers a
  /// user's manual toggles, but changing type re-seeds from the new type's
  /// `defaultOn` set.
  VehicleType? _step4SeededType;

  @override
  void initState() {
    super.initState();
    _draft = OnboardingDraft();
  }

  void _seedStep4IfNeeded() {
    if (_step4SeededType == _draft.type) return;
    _draft.selectedCodes = catalogFor(_draft.type!)
        .where((e) => e.defaultOn)
        .map((e) => e.code)
        .toSet();
    _step4SeededType = _draft.type;
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
      // has — no nested Navigator is introduced here.
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
    if (_step == 2) {
      // Leaving step 3 (ODO + avg km/day) for step 4 (item selection): the
      // vehicle type is known and stable by now, so this is the single
      // correct place to (re-)seed `draft.selectedCodes` — re-seeding only
      // when the type actually changed since the last seed.
      _seedStep4IfNeeded();
    }
    if (_step == 4) {
      _submit();
      return;
    }
    setState(() {
      _error = null;
      _step += 1;
    });
  }

  bool get _continueEnabled {
    if (_submitting) return false;
    return switch (_step) {
      0 => _draft.type != null,
      2 => _draft.currentOdoKm != null && _draft.avgDailyKm != null,
      3 => _draft.selectedCodes.isNotEmpty,
      _ => true, // step 1 (name/plate) is skippable; step 4 gates itself
    };
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
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    return switch (_step) {
      0 => _buildStep0(),
      1 => Step2NamePlate(draft: _draft, onChanged: () => setState(() {})),
      2 => Step3OdoAvgKm(draft: _draft, onChanged: () => setState(() {})),
      3 => Step4Items(draft: _draft, onChanged: () => setState(() {})),
      _ => Step5OilGrade(draft: _draft, onChanged: () => setState(() {})),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết lập xe')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildStepBody()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
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
