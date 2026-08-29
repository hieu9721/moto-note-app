// lib/domain/models/service_log.dart — transcribed verbatim from §4.2's
// "service_log.dart" block: ServiceLogEntry, ServiceLog. Pure Dart (D-31) —
// this directory must never import the Flutter SDK.
//
// resetsCycle: false is the inspection-without-replacement case LOG-02 relies
// on. photoPaths holds local paths only — never backed up (D-20).
import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_log.freezed.dart';
part 'service_log.g.dart';

@freezed
abstract class ServiceLogEntry with _$ServiceLogEntry {
  const factory ServiceLogEntry({
    required String itemId,
    int? costVnd,
    String? partBrand,
    String? partSpec,
    @Default(true) bool resetsCycle, // false = chỉ kiểm tra, chưa thay
  }) = _ServiceLogEntry;

  factory ServiceLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ServiceLogEntryFromJson(json);
}

@freezed
abstract class ServiceLog with _$ServiceLog {
  const factory ServiceLog({
    required String id,
    required String vehicleId,
    required DateTime date,
    required int odoKm,
    String? shopName,
    int? totalCostVnd,
    String? note,
    @Default([]) List<String> photoPaths, // cục bộ, không backup
    @Default([]) List<ServiceLogEntry> entries,
  }) = _ServiceLog;

  factory ServiceLog.fromJson(Map<String, dynamic> json) =>
      _$ServiceLogFromJson(json);
}
