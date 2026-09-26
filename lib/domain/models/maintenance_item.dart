// lib/domain/models/maintenance_item.dart — transcribed verbatim from §4.2's
// "maintenance_item.dart" block: MaintenanceItem. Pure Dart (D-31) — this
// directory must never import the Flutter SDK.
//
// Both interval fields are nullable ints because an item may carry only one
// axis (DUE-02 depends on that nullability). OilGrade is declared in
// vehicle.dart, where §4.2 places it.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'vehicle.dart';

part 'maintenance_item.freezed.dart';
part 'maintenance_item.g.dart';

@freezed
abstract class MaintenanceItem with _$MaintenanceItem {
  const factory MaintenanceItem({
    required String id,
    required String vehicleId,
    required String catalogCode, // 'engine_oil' — tra catalog lấy icon, hint
    required String name, // user sửa được
    int? intervalKm,
    int? intervalMonths,
    @Default(true) bool enabled,

    // Mốc gần nhất — cập nhật khi ghi log
    int? lastServiceOdo,
    DateTime? lastServiceDate,
    @Default(true) bool baselineIsGuess,

    // Quy cách phụ tùng đang dùng — điền sẵn cho lần ghi log sau
    String? partBrand, // "Motul"
    String? partSpec, // "5100 10W-40"
    OilGrade? oilGrade, // chỉ với hạng mục nhớt
    int? lastCostVnd,

    String? notes,
  }) = _MaintenanceItem;

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceItemFromJson(json);
}
