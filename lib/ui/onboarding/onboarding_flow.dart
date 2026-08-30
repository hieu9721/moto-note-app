// lib/ui/onboarding/onboarding_flow.dart — ConsumerStatefulWidget owning
// exactly one `OnboardingDraft` instance. Plan 02-01 rendered a single page
// (vehicle-type + ODO) to prove the tracer slice end to end; plan 02-02
// added item selection (step 4) and oil grade (step 5). This plan (02-05)
// inserts name/plate (step 2), ODO + average km/day (step 3) and the
// last-oil-change question (step 6), moving the temporary ODO field off
// step 1 and replacing plan 01's hardcoded `avgDailyKm = 20.0` seed with
// real UI (P2-D-07's bands plus the P2-D-08 exact-entry escape), and adds
// the shared six-step chrome (02-UI-SPEC.md "Shared step chrome"): a
// progress bar, and a "Quay lại"/"Tiếp tục" bottom action row.
//
// "Tiếp tục" on the LAST step is the ONE commit point of the whole flow: it
// calls the `AppNotifier` method this widget owns exclusively (see
// `_submit` below), the only legal persistence path (DATA-06). No step
// widget may reach the repository directly or persist anything on its own.
// Going back a step and forward again preserves every
// value already entered — `_draft` is owned by this widget for the whole
// flow and step widgets read it on build rather than starting empty
// (ONB-02); the one deliberate exception is `_seedStep4IfNeeded`, which
// re-seeds `draft.selectedCodes` only when the vehicle type actually
// changes, since the applicable catalog differs per type.
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
import 'step6_last_oil.dart';

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
  /// (plan 05), 3 = item selection, 4 = oil grade, 5 = last oil change
  /// (plan 05) — the final step, which commits on "Tiếp tục".
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
      // Post-await context guard (CLAUDE.md known trap: BuildContext used
      // after an await). `mounted` (the State getter) is the canonical
      // equivalent of `context.mounted` for a State's own context; it is
      // used here INSTEAD OF the literal `context.mounted` because, for
      // this exact try/catch/finally control-flow shape, `context.mounted`
      // is flagged by `use_build_context_synchronously` as an "unrelated"
      // guard (re-confirmed by `flutter analyze` this session — a real
      // exit-1 failure, not a hypothetical), while `mounted` satisfies the
      // lint and is functionally identical (both read the same underlying
      // `State._element != null`). See 02-01-SUMMARY.md's "Decisions Made"
      // for the original on-device finding this preserves.
      if (!mounted) return;
      // Under `go_router` (HOME-01, research Pitfall 2), `/onboarding` is
      // reached via the router's own `redirect` (`lib/ui/router.dart`), not
      // an imperative `Navigator.push` from a `home:` branch as it was
      // before this phase. The instant `completeOnboarding` above updates
      // `appProvider`, `_AppRefreshNotifier` fires and the redirect alone
      // sends the user to `/` — no imperative pop is needed here, and
      // calling one anyway risks popping the wrong route (or nothing, if the
      // redirect has already unmounted this one) depending on exact timing.
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
    if (_step == 5) {
      _submit();
      return;
    }
    setState(() {
      _error = null;
      _step += 1;
    });
  }

  void _goBack() {
    setState(() {
      _error = null;
      _step -= 1;
    });
  }

  bool get _continueEnabled {
    if (_submitting) return false;
    return switch (_step) {
      0 => _draft.type != null,
      2 => _draft.currentOdoKm != null && _draft.avgDailyKm != null,
      3 => _draft.selectedCodes.isNotEmpty,
      5 => _draft.lastOilChoice != null,
      // step 1 (name/plate) is skippable; step 4 (oil grade) was never
      // required to continue in plan 02 — an unpicked grade leaves the
      // engine-oil item on the catalog's own default interval.
      _ => true,
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
      4 => Step5OilGrade(draft: _draft, onChanged: () => setState(() {})),
      _ => Step6LastOil(draft: _draft, onChanged: () => setState(() {})),
    };
  }

  @override
  Widget build(BuildContext context) {
    const totalSteps = 6;
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết lập xe')),
      body: SafeArea(
        child: Column(
          children: [
            // Shared step chrome (02-UI-SPEC.md): the bar alone signals
            // progress — 1/6 on the first step, filled in `colorScheme
            // .primary`, the one non-CTA accent use permitted.
            LinearProgressIndicator(
              value: (_step + 1) / totalSteps,
              color: Theme.of(context).colorScheme.primary,
            ),
            Expanded(child: _buildStepBody()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // "Quay lại" is hidden on step 1 only, and deliberately
                  // NOT accent-colored — two teal buttons on one row would
                  // compete with the single CTA that matters.
                  if (_step > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: _submitting ? null : _goBack,
                        child: const Text('Quay lại'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _continueEnabled ? _onContinuePressed : null,
                      child: const Text('Tiếp tục'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
