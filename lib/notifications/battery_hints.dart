// lib/notifications/battery_hints.dart — transcribed from §10.6. NOT
// lib/domain/ (D-31): this file imports device_info_plus and
// android_intent_plus, both platform plugins, and D-31 forbids
// lib/domain/ from importing anything platform-bound. A reader who finds
// a pure-looking lookup function here should see immediately that the
// placement is deliberate, not an oversight — §10.6 names this exact
// path.
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// §10.6's return value: the matched (or generic) instruction text, and
/// whether it came from a genuine ROM match or the P4-D-10 fallback.
/// Modelled on `lib/domain/odo.dart`'s `RefinedAvg` — a plain `const`
/// class, never Freezed, never serialized on its own. [isGeneric] lets the
/// sheet phrase itself slightly differently when guessing at an
/// unrecognised ROM, and lets UAT tell the generic branch from a matched
/// one without reading the string.
class BatteryHint {
  final String text;
  final bool isGeneric;
  const BatteryHint({required this.text, required this.isGeneric});
}

/// §10.6, transcribed with one deliberate change: P4-D-10 replaces the
/// source's own `default: return null;` with a generic hint, because
/// [openBatterySettings]'s intent is a standard Android action that works
/// on every ROM — an unlisted manufacturer (Nokia, Sony, stock Android)
/// still has a fix available, and returning nothing would withhold it.
/// The only null this function ever returns is the non-Android guard
/// immediately below; every Android code path returns a [BatteryHint].
Future<BatteryHint?> batteryOptimizationHint() async {
  if (!Platform.isAndroid) return null;
  final info = await DeviceInfoPlugin().androidInfo;

  switch (info.manufacturer.toLowerCase()) {
    case 'xiaomi':
    case 'redmi':
    case 'poco':
      return const BatteryHint(
        text: 'Vào Cài đặt → Ứng dụng → MotoNote → Tiết kiệm pin → chọn "Không giới hạn", và bật "Tự khởi động".',
        isGeneric: false,
      );
    case 'oppo':
    case 'realme':
    case 'oneplus':
      return const BatteryHint(
        text: 'Vào Cài đặt → Pin → Tối ưu hoá pin → MotoNote → chọn "Không tối ưu hoá".',
        isGeneric: false,
      );
    case 'vivo':
      return const BatteryHint(
        text: 'Vào Cài đặt → Pin → Mức tiêu thụ nền cao → bật MotoNote.',
        isGeneric: false,
      );
    case 'samsung':
      return const BatteryHint(
        text: 'Vào Cài đặt → Chăm sóc thiết bị → Pin → Giới hạn sử dụng nền → bỏ MotoNote khỏi danh sách "Ứng dụng đang ngủ".',
        isGeneric: false,
      );
    default:
      // P4-D-10: never a dead end. [NEW, PROVISIONAL] — no source string
      // exists for an unlisted manufacturer; recorded verbatim in
      // 04-04-SUMMARY.md for UAT.
      return const BatteryHint(
        text: 'Máy của bạn có thể tự tắt thông báo của app để tiết kiệm pin. Mở phần tối ưu hoá pin và cho MotoNote chạy không giới hạn.',
        isGeneric: true,
      );
  }
}

/// §10.6, verbatim. Guarded the same way [batteryOptimizationHint] is so a
/// future iOS build never calls into a plugin that only supports Android.
/// A launch failure (a ROM with no matching settings activity) is
/// deliberately left to surface rather than being caught and swallowed
/// here — a button that silently does nothing is worse than a visible
/// failure, because the user concludes the instructions were wrong and
/// stops trying. Flutter's own top-level error zone reports an unhandled
/// async exception from a button handler without crashing the app process
/// (verified by reading the framework's Future/Zone error handling — not
/// exercised on a device without the matching activity, since only the
/// Samsung branch is reachable on this session's hardware, P4-D-18).
Future<void> openBatterySettings() async {
  if (!Platform.isAndroid) return;
  const intent = AndroidIntent(
    action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
  );
  await intent.launch();
}
