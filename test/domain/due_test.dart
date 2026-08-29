// Tests for computeDue (§9.3, §9.6). Runs under plain `dart test`, no
// Flutter engine — package:test only (D-32, P1-D-11). Groups mirror the
// §9.6-named cases; this plan (02-01) authors the first one to prove the
// tracer slice's due engine on a real fixture. Later plans in this phase
// add the remaining §9.6 cases and their groups without touching this one.
import 'package:motonote/domain/due.dart';
import 'package:motonote/domain/models/maintenance_item.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:test/test.dart';

void main() {
  group('computeDue', () {
    test('lấy mốc km khi km tới trước thời gian', () {
      final vehicle = Vehicle(
        id: 'v1',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 10000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );

      // Km axis: lastServiceOdo 8500, intervalKm 2000 → target 10500, still
      // 500 km left at 20 km/day ≈ 25 days out. No intervalMonths/
      // lastServiceDate is set, so the time axis never activates — this
      // fixture exercises DUE-02's "only the km axis exists" branch.
      final item = const MaintenanceItem(
        id: 'i1',
        vehicleId: 'v1',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 8500,
        baselineIsGuess: false,
      );

      final result = computeDue(
        item,
        vehicle,
        7,
        now: DateTime.utc(2026, 8, 29),
      );

      expect(result, isNotNull);
      expect(result!.drivenBy, equals(DrivenBy.km));
      // 500 km left / 20 km/day = 25 days.
      expect(result.daysLeft, equals(25));
    });
  });
}
