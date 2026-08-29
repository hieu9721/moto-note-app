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

    test('lấy mốc thời gian khi xe để lâu không chạy', () {
      // Cả hai trục cùng tồn tại; avgDailyKm rất thấp khiến trục km còn xa
      // (~1000 ngày), trong khi trục thời gian (lastServiceDate + 3 tháng)
      // đã tới hạn từ trước. D-28: trục thời gian không được bỏ qua chỉ vì
      // trục km chưa tới — đây chính là ca "xe để lâu không chạy".
      final vehicle = Vehicle(
        id: 'v1',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 1.0,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final lastServiceDate = DateTime.utc(2026, 4, 29);
      final item = MaintenanceItem(
        id: 'i1',
        vehicleId: 'v1',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        intervalMonths: 3,
        lastServiceDate: lastServiceDate,
        baselineIsGuess: false,
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      expect(result, isNotNull);
      expect(result!.drivenBy, equals(DrivenBy.time));
      final expectedDueDate = DateTime(
        lastServiceDate.year,
        lastServiceDate.month + item.intervalMonths!,
        lastServiceDate.day,
      );
      expect(result.dueDate, equals(expectedDueDate));
    });

    test('trả overdue khi đã quá ngày', () {
      final vehicle = Vehicle(
        id: 'v2',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 11000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item = const MaintenanceItem(
        id: 'i2',
        vehicleId: 'v2',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 8000,
        baselineIsGuess: false,
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      expect(result, isNotNull);
      expect(result!.status, equals(DueStatus.overdue));
      expect(result.daysLeft, lessThan(0));
    });

    test('đánh dấu isEstimate khi ODO cũ hơn 45 ngày', () {
      final vehicle = Vehicle(
        id: 'v3',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 6, 30), // 60 ngày trước now
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item = const MaintenanceItem(
        id: 'i3',
        vehicleId: 'v3',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: false, // chỉ ODO cũ là nguyên nhân, không phải mốc giả định
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      expect(result, isNotNull);
      expect(result!.isEstimate, isTrue);
    });

    test('trả null khi hạng mục bị tắt', () {
      final vehicle = Vehicle(
        id: 'v4',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      // Mốc đầy đủ (cả km lẫn ngày) — chỉ enabled:false là lý do trả null.
      final item = MaintenanceItem(
        id: 'i4',
        vehicleId: 'v4',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        lastServiceDate: DateTime.utc(2026, 8, 29),
        intervalMonths: 3,
        enabled: false,
        baselineIsGuess: false,
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      expect(result, isNull);
    });

    test('không chia cho 0 khi avgDailyKm = 0', () {
      final vehicle = Vehicle(
        id: 'v5',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 0.0,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item = const MaintenanceItem(
        id: 'i5',
        vehicleId: 'v5',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: false,
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      // §9.3's guard floors avgDailyKm at 0.5 when <= 0 — proving it FIRES,
      // not merely trusting it's written: a NaN/Infinity progress would
      // compare false against `>= 0.9` and silently strand the item at `ok`
      // forever (see threat T-02-17).
      expect(result, isNotNull);
      expect(result!.progress.isFinite, isTrue);
      expect(result.daysLeft, isA<int>());
    });

    test('không lệch 1 ngày khi chênh 23 giờ', () {
      // §9.3 Dart-trap (CLAUDE.md "Known traps", flagged twice in the source
      // §9.3/§14.2): DateTime.difference().inDays TRUNCATES rather than
      // rounds. computeDue's daysLeft must go through _dateOnly first so a
      // sub-24h gap that crosses a calendar-date boundary still reads as 1
      // day left, not the naively-truncated 0.
      //
      // DEVIATION (reported — see 02-04-SUMMARY.md "Deviations from Plan"):
      // the plan names literal 23h/25h gaps. `due.dart`'s `dueByTime` is
      // built via the bare `DateTime(y, m, d)` constructor (LOCAL time), not
      // `DateTime.utc(...)`, so its absolute instant is pinned to
      // (target date − 1) at (24 − localOffsetHours):00 UTC. On this
      // machine (UTC+7, matching the app's Asia/Ho_Chi_Minh target locale),
      // that caps the raw now→dueDate gap achievable at daysLeft==1 to at
      // most 17h; 23h is unreachable here, and 25h is unreachable on ANY
      // machine's local offset because `dueByTime` always lands exactly at
      // local midnight (hour 00:00), which mathematically bounds the
      // achievable gap at daysLeft==1 to <= 24h everywhere. This test
      // proves the identical mechanism the plan was after — a sub-24h raw
      // gap crossing a calendar boundary still yields daysLeft==1, not 0 —
      // using the two extremes this implementation can actually reach (17h
      // and 11h), which equally "pins date-boundary semantics rather than
      // an hour count" since two different hour magnitudes land on the same
      // daysLeft.
      final vehicle = Vehicle(
        id: 'v6',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item = MaintenanceItem(
        id: 'i6',
        vehicleId: 'v6',
        catalogCode: 'battery',
        name: 'Ắc quy',
        intervalMonths: 3,
        // + 3 tháng = 29/8 (local midnight) — the fixed target this test's
        // two `now` values sit just under 24h before.
        lastServiceDate: DateTime.utc(2026, 5, 29),
        baselineIsGuess: false,
      );

      final now17h = DateTime.utc(2026, 8, 28, 0, 0);
      final result17h = computeDue(item, vehicle, 7, now: now17h);
      expect(result17h, isNotNull);
      // The bẫy (trap) made concrete: the RAW difference truncates to 0...
      expect(result17h!.dueDate.difference(now17h).inDays, equals(0));
      // ...but daysLeft (through _dateOnly) correctly reads 1.
      expect(result17h.daysLeft, equals(1));
      expect(result17h.status, equals(DueStatus.dueSoon));
      expect(result17h.status, isNot(equals(DueStatus.dueToday)));

      final now11h = DateTime.utc(2026, 8, 28, 6, 0);
      final result11h = computeDue(item, vehicle, 7, now: now11h);
      expect(result11h, isNotNull);
      expect(result11h!.dueDate.difference(now11h).inDays, equals(0));
      expect(result11h.daysLeft, equals(1));
      expect(result11h.status, equals(DueStatus.dueSoon));
      expect(result11h.status, isNot(equals(DueStatus.dueToday)));
    });
  });
}
