// Tests for refineAvgDailyKm (§9.2, §9.6). Runs under plain `dart test`, no
// Flutter engine — package:test only (D-32, P1-D-11). One group holding all
// five §9.6-named cases; each test asserts both sides of its guard boundary
// where the case names one, not only the failing side.
import 'package:motonote/domain/models/misc.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:motonote/domain/odo.dart';
import 'package:test/test.dart';

Vehicle _vehicle({required double avgDailyKm, required AvgKmSource source}) {
  return Vehicle(
    id: 'v1',
    name: 'Xe test',
    type: VehicleType.scooter,
    currentOdoKm: 1000,
    odoUpdatedAt: DateTime.utc(2026, 8, 29),
    avgDailyKm: avgDailyKm,
    avgDailyKmSource: source,
    createdAt: DateTime.utc(2026, 8, 29),
  );
}

OdoReading _reading({required DateTime date, required int odoKm}) {
  return OdoReading(id: 'r', vehicleId: 'v1', odoKm: odoKm, date: date);
}

void main() {
  group('refineAvgDailyKm', () {
    test('bỏ qua khi khoảng cách dưới 14 ngày', () {
      // 13-day gap: skipped, values pass through unchanged.
      final vehicle13 = _vehicle(
        avgDailyKm: 20.0,
        source: AvgKmSource.computed,
      );
      final prev13 = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 1000);
      final next13 = _reading(date: DateTime.utc(2026, 1, 14), odoKm: 1300);
      final result13 = refineAvgDailyKm(vehicle13, next13, prev13);
      expect(result13.avgDailyKm, equals(20.0));
      expect(result13.source, equals(AvgKmSource.computed));

      // 14-day gap: the guard is `days < 14`, so exactly 14 days refines.
      final vehicle14 = _vehicle(
        avgDailyKm: 10.0,
        source: AvgKmSource.computed,
      );
      final prev14 = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 1000);
      final next14 = _reading(date: DateTime.utc(2026, 1, 15), odoKm: 1280);
      final result14 = refineAvgDailyKm(vehicle14, next14, prev14);
      // days=14, km=280, measured=20.0, smoothed=0.7*20+0.3*10=17.0
      expect(result14.avgDailyKm, equals(17.0));
      expect(result14.source, equals(AvgKmSource.computed));
    });

    test('bỏ qua khi ODO mới nhỏ hơn ODO cũ', () {
      // Negative delta: skipped regardless of the (ample) day gap.
      final vehicleNeg = _vehicle(
        avgDailyKm: 20.0,
        source: AvgKmSource.computed,
      );
      final prevNeg = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 1000);
      final nextNeg = _reading(date: DateTime.utc(2026, 1, 21), odoKm: 999);
      final resultNeg = refineAvgDailyKm(vehicleNeg, nextNeg, prevNeg);
      expect(resultNeg.avgDailyKm, equals(20.0));
      expect(resultNeg.source, equals(AvgKmSource.computed));

      // Exactly zero delta: the guard is `km < 0`, not `km <= 0`, so a
      // same-odometer pair still refines — producing measured=0, which
      // then clamps up to the 0.5 floor.
      final vehicleZero = _vehicle(
        avgDailyKm: 1.0,
        source: AvgKmSource.computed,
      );
      final prevZero = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 1000);
      final nextZero = _reading(date: DateTime.utc(2026, 1, 15), odoKm: 1000);
      final resultZero = refineAvgDailyKm(vehicleZero, nextZero, prevZero);
      // days=14, km=0, measured=0.0, smoothed=0.7*0+0.3*1=0.3, clamped to 0.5
      expect(resultZero.avgDailyKm, equals(0.5));
      expect(resultZero.source, equals(AvgKmSource.computed));
    });

    test('tin hẳn lần đo thật đầu tiên', () {
      // A user-sourced seed is REPLACED outright by the first real
      // measurement — no blending with the seed at all.
      final vehicle = _vehicle(avgDailyKm: 7.0, source: AvgKmSource.user);
      final prev = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 500);
      final next = _reading(date: DateTime.utc(2026, 1, 21), odoKm: 900);
      final result = refineAvgDailyKm(vehicle, next, prev);
      // days=20, km=400, measured=20.0 — no trace of the seed (7.0).
      expect(result.avgDailyKm, equals(20.0));
      expect(result.source, equals(AvgKmSource.computed));
    });

    test('làm mượt 70/30 ở các lần sau', () {
      // A vehicle already `computed` blends: 0.7*measured + 0.3*previous.
      final vehicle = _vehicle(avgDailyKm: 15.0, source: AvgKmSource.computed);
      final prev = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 1000);
      final next = _reading(date: DateTime.utc(2026, 1, 16), odoKm: 1300);
      final result = refineAvgDailyKm(vehicle, next, prev);
      // days=15, km=300, measured=20.0, smoothed=0.7*20+0.3*15=18.5
      expect(result.avgDailyKm, equals(18.5));
      expect(result.source, equals(AvgKmSource.computed));
    });

    test('kẹp trong khoảng [0.5, 400]', () {
      // High end: an absurd measured average clamps down to 400.
      final vehicleHigh = _vehicle(
        avgDailyKm: 300.0,
        source: AvgKmSource.computed,
      );
      final prevHigh = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 0);
      final nextHigh = _reading(date: DateTime.utc(2026, 1, 15), odoKm: 10000);
      final resultHigh = refineAvgDailyKm(vehicleHigh, nextHigh, prevHigh);
      // days=14, km=10000, measured=714.2857..., smoothed=0.7*measured+0.3*300=590.0
      expect(resultHigh.avgDailyKm, equals(400.0));
      expect(resultHigh.source, equals(AvgKmSource.computed));

      // Low end: the clamp is what floors the result, not the smoothing
      // itself — smoothed alone (0.2) is already below 0.5, proving the
      // clamp runs AFTER the 0.7/0.3 blend, not on its inputs.
      final vehicleLow = _vehicle(
        avgDailyKm: 0.5,
        source: AvgKmSource.computed,
      );
      final prevLow = _reading(date: DateTime.utc(2026, 1, 1), odoKm: 1000);
      final nextLow = _reading(date: DateTime.utc(2026, 1, 15), odoKm: 1001);
      final resultLow = refineAvgDailyKm(vehicleLow, nextLow, prevLow);
      // days=14, km=1, measured=1/14≈0.0714, smoothed≈0.05+0.15=0.2 → 0.5
      expect(resultLow.avgDailyKm, equals(0.5));
      expect(resultLow.source, equals(AvgKmSource.computed));
    });
  });
}
