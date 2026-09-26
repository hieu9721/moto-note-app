// lib/domain/oil_presets.dart — transcribed verbatim from §8.3's
// `lib/domain/oil_presets.dart` block. Pure Dart (D-31) — this directory
// must never import the Flutter SDK.
//
// `OilPreset` is a plain `const`-constructor class, NOT `@freezed` — unlike
// every file under `lib/domain/models/`, this is compiled `const` data,
// never serialised into `appdata.json` and never `copyWith`'d
// (02-RESEARCH.md Pitfall 5). No `part` directive, no build_runner needed.
//
// CAT-03: `kOilPresets[grade]` is the single source both onboarding step 5
// (live confirmation string) and `OnboardingDraft.buildSelectedItems`
// (the committed engine-oil interval) read from — never a second
// hardcoded copy of these numbers.
import 'models/vehicle.dart';

class OilPreset {
  final String label;
  final int km;
  final int months;
  final String hint;
  const OilPreset(this.label, this.km, this.months, this.hint);
}

const kOilPresets = <OilGrade, OilPreset>{
  OilGrade.mineral: OilPreset(
    'Nhớt khoáng',
    1500,
    3,
    'Rẻ nhất, phải thay dày. Nhớt "zin" theo xe thường loại này.',
  ),
  OilGrade.semiSynthetic: OilPreset(
    'Bán tổng hợp',
    2500,
    4,
    'Phổ biến nhất. Cân bằng giá và chu kỳ.',
  ),
  OilGrade.fullSynthetic: OilPreset(
    'Tổng hợp toàn phần',
    3500,
    6,
    'Đắt hơn nhưng đi được xa hơn. Hợp với người chạy nhiều.',
  ),
};
