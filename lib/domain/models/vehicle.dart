// lib/domain/models/vehicle.dart — transcribed verbatim from §4.2's "vehicle.dart"
// block: VehicleType, OilGrade, AvgKmSource, Vehicle. Pure Dart (D-31) — no
// package:flutter/... import.
//
// P2-D-06: avgDailyKm stays a plain `double` with avgDailyKmSource an
// AvgKmSource — no band enum, no extra field — because Phase 2 stores a
// band's midpoint into this same double.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

enum VehicleType {
  scooter, // tay ga
  underbone, // xe số
  manual, // côn tay
}

enum OilGrade { mineral, semiSynthetic, fullSynthetic }

enum AvgKmSource { user, computed }

@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id, // nanoid / uuid v4
    required String name,
    required VehicleType type,
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? photoPath, // đường dẫn cục bộ — KHÔNG backup
    required int currentOdoKm,
    required DateTime odoUpdatedAt,
    required double avgDailyKm,
    @Default(AvgKmSource.user) AvgKmSource avgDailyKmSource,
    required DateTime createdAt,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}
