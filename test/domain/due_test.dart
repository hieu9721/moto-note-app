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

    test('trả null khi chưa có mốc nào', () {
      final vehicle = Vehicle(
        id: 'v8',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );

      final bothNull = const MaintenanceItem(
        id: 'i8a',
        vehicleId: 'v8',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        intervalMonths: 3,
        baselineIsGuess: false,
      );
      expect(computeDue(bothNull, vehicle, 7, now: DateTime.utc(2026, 8, 29)), isNull);

      // Guard là "cả hai đều null" (AND), không phải "một trong hai null"
      // (OR) — một hạng mục có MỘT mốc vẫn phải tính được, nếu không sẽ
      // âm thầm tắt tiếng mọi nhắc nhở cho hạng mục chỉ dùng trục thời gian.
      final odoOnly = const MaintenanceItem(
        id: 'i8b',
        vehicleId: 'v8',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: false,
      );
      expect(
        computeDue(odoOnly, vehicle, 7, now: DateTime.utc(2026, 8, 29)),
        isNotNull,
      );

      final dateOnly = MaintenanceItem(
        id: 'i8c',
        vehicleId: 'v8',
        catalogCode: 'battery',
        name: 'Ắc quy',
        intervalMonths: 30,
        lastServiceDate: DateTime.utc(2026, 8, 29),
        baselineIsGuess: false,
      );
      expect(
        computeDue(dateOnly, vehicle, 7, now: DateTime.utc(2026, 8, 29)),
        isNotNull,
      );
    });

    test('trả dueToday khi còn đúng 0 ngày', () {
      final vehicle = Vehicle(
        id: 'v9',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item = const MaintenanceItem(
        id: 'i9',
        vehicleId: 'v9',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 1000,
        lastServiceOdo: 4000,
        baselineIsGuess: false,
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      expect(result, isNotNull);
      expect(result!.daysLeft, equals(0));
      expect(result.status, equals(DueStatus.dueToday));
      expect(result.status, isNot(equals(DueStatus.overdue)));
      expect(result.status, isNot(equals(DueStatus.dueSoon)));
    });

    test('trả dueSoon theo leadDays và theo progress', () {
      // Trigger 1: daysLeft nằm trong leadDays, progress còn thấp.
      final vehicleA = Vehicle(
        id: 'v10a',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final itemA = const MaintenanceItem(
        id: 'i10a',
        vehicleId: 'v10a',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 120,
        lastServiceOdo: 4940,
        baselineIsGuess: false,
      );
      final resultA = computeDue(itemA, vehicleA, 7, now: DateTime.utc(2026, 8, 29));
      expect(resultA, isNotNull);
      expect(resultA!.daysLeft, lessThanOrEqualTo(7));
      expect(resultA.progress, lessThan(0.9));
      expect(resultA.status, equals(DueStatus.dueSoon));

      // Trigger 2: daysLeft vượt xa leadDays nhưng progress >= 0.9 — ca này
      // là ca một triển khai ngây thơ dễ bỏ sót, và là ca quan trọng nhất
      // cho người chạy ít km/ngày mà trục thời gian đã gần cạn.
      final vehicleB = Vehicle(
        id: 'v10b',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 15000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final itemB = const MaintenanceItem(
        id: 'i10b',
        vehicleId: 'v10b',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 10000,
        lastServiceOdo: 5800,
        baselineIsGuess: false,
      );
      final resultB = computeDue(itemB, vehicleB, 7, now: DateTime.utc(2026, 8, 29));
      expect(resultB, isNotNull);
      expect(resultB!.daysLeft, greaterThan(7));
      expect(resultB.progress, greaterThanOrEqualTo(0.9));
      expect(resultB.status, equals(DueStatus.dueSoon));
    });

    test('trả ok khi còn xa hạn', () {
      final vehicle = Vehicle(
        id: 'v11',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item = const MaintenanceItem(
        id: 'i11',
        vehicleId: 'v11',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 1600,
        lastServiceOdo: 4200,
        baselineIsGuess: false,
      );

      final result = computeDue(item, vehicle, 7, now: DateTime.utc(2026, 8, 29));

      expect(result, isNotNull);
      expect(result!.daysLeft, greaterThan(7));
      expect(result.progress, lessThan(0.9));
      expect(result.status, equals(DueStatus.ok));
    });

    test('lấy mốc thời gian khi hai trục trùng ngày', () {
      final vehicle = Vehicle(
        id: 'v7',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final lastServiceDate = DateTime.utc(2026, 6, 28); // + 3 tháng = 28/9

      // dueByKm.isBefore(dueByTime) là so sánh strict, nên một tie đúng
      // nghĩa (cùng ngày lịch) phải rơi vào nhánh thời gian — pin lại để
      // một refactor sau này đổi thành `!isAfter` không thể âm thầm đảo
      // trục nào được báo cáo. lastServiceOdo == currentOdoKm nên
      // kmLeft == intervalKm chính xác, không có sai số làm tròn.
      final tieItem = MaintenanceItem(
        id: 'i7',
        vehicleId: 'v7',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 600, // 30 ngày * 20 km/ngày = số ngày lịch từ 29/8 đến 28/9
        lastServiceOdo: 5000,
        intervalMonths: 3,
        lastServiceDate: lastServiceDate,
        baselineIsGuess: false,
      );
      final tieResult = computeDue(tieItem, vehicle, 7, now: DateTime.utc(2026, 8, 29));
      expect(tieResult, isNotNull);
      expect(tieResult!.drivenBy, equals(DrivenBy.time));

      // Hình dạng đơn trục: chỉ intervalMonths (như battery) -> drivenBy.time, kmLeft null.
      final timeOnlyItem = MaintenanceItem(
        id: 'i7b',
        vehicleId: 'v7',
        catalogCode: 'battery',
        name: 'Ắc quy',
        intervalMonths: 30,
        lastServiceDate: lastServiceDate,
        baselineIsGuess: false,
      );
      final timeOnlyResult =
          computeDue(timeOnlyItem, vehicle, 7, now: DateTime.utc(2026, 8, 29));
      expect(timeOnlyResult, isNotNull);
      expect(timeOnlyResult!.drivenBy, equals(DrivenBy.time));
      expect(timeOnlyResult.kmLeft, isNull);

      // Chỉ intervalKm (như valve) -> drivenBy.km.
      final kmOnlyItem = const MaintenanceItem(
        id: 'i7c',
        vehicleId: 'v7',
        catalogCode: 'valve',
        name: 'Xupap',
        intervalKm: 600,
        lastServiceOdo: 5000,
        baselineIsGuess: false,
      );
      final kmOnlyResult = computeDue(kmOnlyItem, vehicle, 7, now: DateTime.utc(2026, 8, 29));
      expect(kmOnlyResult, isNotNull);
      expect(kmOnlyResult!.drivenBy, equals(DrivenBy.km));
    });

    test('đánh dấu isEstimate khi mốc là giả định', () {
      // OR, không phải AND: baselineIsGuess=true dù ODO vừa cập nhật (0
      // ngày) vẫn phải isEstimate=true — độ mới của ODO không được che
      // lấp một mốc giả định (§6.1).
      //
      // P3-D-01: hai nguyên nhân này giờ tách thành hai cờ độc lập,
      // odoIsStale và baselineIsGuess, với isEstimate là OR dẫn xuất của cả
      // hai (một getter, không còn là field lưu trữ). Bốn tổ hợp bên dưới
      // xác nhận cả hai cờ có thể kiểm tra riêng biệt — điều mà cờ
      // isEstimate cũ (một boolean duy nhất) không thể phân biệt, và là
      // tiền đề HOME-05 cần cho ba cách hiển thị với hai nút hành động khác
      // nhau.
      final vehicleGuess = Vehicle(
        id: 'v12a',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final itemGuess = const MaintenanceItem(
        id: 'i12a',
        vehicleId: 'v12a',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: true,
      );
      final resultGuess =
          computeDue(itemGuess, vehicleGuess, 7, now: DateTime.utc(2026, 8, 29));
      expect(resultGuess, isNotNull);
      expect(resultGuess!.isEstimate, isTrue);
      expect(resultGuess.baselineIsGuess, isTrue);
      expect(resultGuess.odoIsStale, isFalse); // 0 ngày kể từ odoUpdatedAt

      // Ranh giới 45 ngày: đúng 45 ngày -> false, 46 ngày -> true (điều
      // kiện là strictly greater than 45, không phải >=).
      final vehicle45 = Vehicle(
        id: 'v1245',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 7, 15), // 45 ngày trước 29/8
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item45 = const MaintenanceItem(
        id: 'i1245',
        vehicleId: 'v1245',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: false,
      );
      final result45 = computeDue(item45, vehicle45, 7, now: DateTime.utc(2026, 8, 29));
      expect(result45, isNotNull);
      expect(result45!.isEstimate, isFalse);
      expect(result45.odoIsStale, isFalse);
      expect(result45.baselineIsGuess, isFalse);

      final vehicle46 = Vehicle(
        id: 'v1246',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 7, 14), // 46 ngày trước 29/8
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final item46 = const MaintenanceItem(
        id: 'i1246',
        vehicleId: 'v1246',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: false,
      );
      final result46 = computeDue(item46, vehicle46, 7, now: DateTime.utc(2026, 8, 29));
      expect(result46, isNotNull);
      expect(result46!.isEstimate, isTrue);
      expect(result46.odoIsStale, isTrue);
      expect(result46.baselineIsGuess, isFalse);

      // Tổ hợp thứ tư: mốc giả định VÀ ODO đã cũ 46 ngày cùng lúc — cả hai
      // cờ true. Đây là tổ hợp mà cờ isEstimate cũ (một boolean duy nhất)
      // không thể diễn đạt, và là tiền đề cho quy tắc ưu tiên của P3-D-01
      // (baselineIsGuess thắng trong câu chữ khi cả hai đều true).
      final vehicleBoth = Vehicle(
        id: 'v1246b',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 7, 14), // 46 ngày trước 29/8
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final itemBoth = const MaintenanceItem(
        id: 'i1246b',
        vehicleId: 'v1246b',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalKm: 2000,
        lastServiceOdo: 4000,
        baselineIsGuess: true,
      );
      final resultBoth =
          computeDue(itemBoth, vehicleBoth, 7, now: DateTime.utc(2026, 8, 29));
      expect(resultBoth, isNotNull);
      expect(resultBoth!.baselineIsGuess, isTrue);
      expect(resultBoth.odoIsStale, isTrue);
      expect(resultBoth.isEstimate, isTrue);
    });

    // Regression. Before the fix this file's own suite provoked, `_dateOnly`
    // read `now`'s UTC calendar date, so at UTC+7 an item due on the 1st
    // reported daysLeft == 1 / dueSoon for the first SEVEN HOURS of the day
    // it came due, flipping to dueToday only at 07:00 local. "Reminds you on
    // the right day" is the product, so this is pinned at the exact boundary.
    //
    // Deliberately offset-independent: every instant below is built from a
    // LOCAL wall clock and converted with .toUtc(), so the case proves the
    // same property on a UTC machine, in Hanoi, or anywhere else — rather
    // than silently passing only where the author happened to sit.
    test('"hôm nay" theo ngày lịch địa phương, không theo ngày UTC', () {
      // Serviced at local midday on 1/6 — midday so the local calendar date
      // is unambiguous at any UTC offset. Time axis only: no intervalKm, so
      // the km axis never activates and dueByTime alone drives the result.
      final serviced = DateTime(2026, 6, 1, 12).toUtc();
      final vehicleTz = Vehicle(
        id: 'vtz',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 10000,
        odoUpdatedAt: serviced,
        avgDailyKm: 20,
        createdAt: serviced,
      );
      final itemTz = MaintenanceItem(
        id: 'itz',
        vehicleId: 'vtz',
        catalogCode: 'engine_oil',
        name: 'Nhớt máy',
        intervalMonths: 3,
        lastServiceDate: serviced,
        baselineIsGuess: false,
      );

      // One minute BEFORE local midnight on the due date: still tomorrow.
      final justBefore = computeDue(
        itemTz,
        vehicleTz,
        7,
        now: DateTime(2026, 8, 31, 23, 59).toUtc(),
      );
      expect(justBefore, isNotNull);
      expect(justBefore!.daysLeft, equals(1));
      expect(justBefore.status, equals(DueStatus.dueSoon));

      // One minute AFTER local midnight — the moment the user's calendar day
      // becomes the due date. This is the assertion that failed before the
      // fix: it reported daysLeft == 1 / dueSoon, because 00:01 local is
      // still the previous day in UTC at any positive offset.
      final justAfter = computeDue(
        itemTz,
        vehicleTz,
        7,
        now: DateTime(2026, 9, 1, 0, 1).toUtc(),
      );
      expect(justAfter, isNotNull);
      expect(justAfter!.daysLeft, equals(0));
      expect(justAfter.status, equals(DueStatus.dueToday));

      // And it must STAY dueToday across the whole local day, not flip at
      // some hour tied to the machine's offset.
      for (final hour in [3, 6, 7, 12, 23]) {
        final atHour = computeDue(
          itemTz,
          vehicleTz,
          7,
          now: DateTime(2026, 9, 1, hour).toUtc(),
        );
        expect(
          atHour!.daysLeft,
          equals(0),
          reason: 'daysLeft phải là 0 lúc $hour:00 giờ địa phương ngày đến hạn',
        );
        expect(atHour.status, equals(DueStatus.dueToday));
      }
    });

    // Regression (code review WR-01). `DateTime` NORMALISES an out-of-range
    // day rather than rejecting it, so `DateTime(y, m + n, 31)` silently rolled
    // the due date into the following month: 31/1 + 1 tháng landed on 3/3
    // instead of the end of February — a 1–3 day drift. Onboarding writes
    // lastServiceDate as commit-date minus N days, so anyone setting the app up
    // near a month end hit it.
    test('mốc cuối tháng không trôi sang tháng sau', () {
      Vehicle vehicleWith(DateTime created) => Vehicle(
            id: 'vme',
            name: 'Xe test',
            type: VehicleType.scooter,
            currentOdoKm: 10000,
            odoUpdatedAt: created,
            avgDailyKm: 20,
            createdAt: created,
          );

      // Each case: baseline date, interval in months, expected due date.
      // The expectation is always the LAST valid day of the target month when
      // the baseline day does not exist there — never a roll-forward.
      final cases = <List<Object>>[
        [DateTime(2026, 1, 31), 1, DateTime(2026, 2, 28)],
        [DateTime(2026, 1, 31), 3, DateTime(2026, 4, 30)],
        [DateTime(2026, 3, 31), 1, DateTime(2026, 4, 30)],
        [DateTime(2025, 11, 30), 3, DateTime(2026, 2, 28)],
        // Control: a day that exists in the target month is untouched, and the
        // year rolls over correctly.
        [DateTime(2026, 8, 29), 4, DateTime(2026, 12, 29)],
        [DateTime(2026, 11, 15), 3, DateTime(2027, 2, 15)],
      ];

      for (final c in cases) {
        final baseline = c[0] as DateTime;
        final months = c[1] as int;
        final expected = c[2] as DateTime;

        final item = MaintenanceItem(
          id: 'ime',
          vehicleId: 'vme',
          catalogCode: 'engine_oil',
          name: 'Nhớt máy',
          intervalMonths: months,
          lastServiceDate: baseline.toUtc(),
          baselineIsGuess: false,
        );
        final result = computeDue(
          item,
          vehicleWith(baseline.toUtc()),
          7,
          now: baseline.toUtc(),
        );

        expect(result, isNotNull);
        expect(
          _dateOf(result!.dueDate),
          equals(_dateOf(expected)),
          reason: '${baseline.toIso8601String().substring(0, 10)} + $months '
              'tháng phải đến hạn ${expected.toIso8601String().substring(0, 10)}',
        );
      }
    });

    // Regression (code review CR-01). An item can carry a baseline on an axis
    // it has no interval for — `lastServiceOdo` set while `intervalKm` is null
    // and `lastServiceDate` is null. The both-null guard is an AND, so such an
    // item reaches the axis-selection branch with BOTH axes null, where a bare
    // `dueByTime!` used to throw and take down the whole dueItemsProvider for
    // that vehicle. Unreachable through onboarding (it writes both baselines
    // together), but computeDue is a public API Phase 3/5/6 all call.
    test('không ném lỗi khi mốc không khớp trục nào — trả null', () {
      final vehicle = Vehicle(
        id: 'vmis',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 10000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );

      // Has an odometer baseline, but only a TIME interval — and no date
      // baseline to drive it. Neither axis is computable.
      const odoBaselineTimeInterval = MaintenanceItem(
        id: 'i-mismatch-a',
        vehicleId: 'vmis',
        catalogCode: 'battery',
        name: 'Ắc quy',
        intervalMonths: 24,
        lastServiceOdo: 8500,
        baselineIsGuess: false,
      );
      expect(
        () => computeDue(
          odoBaselineTimeInterval,
          vehicle,
          7,
          now: DateTime.utc(2026, 8, 29),
        ),
        returnsNormally,
      );
      expect(
        computeDue(
          odoBaselineTimeInterval,
          vehicle,
          7,
          now: DateTime.utc(2026, 8, 29),
        ),
        isNull,
      );

      // The mirror case: a date baseline with only a km interval.
      final dateBaselineKmInterval = MaintenanceItem(
        id: 'i-mismatch-b',
        vehicleId: 'vmis',
        catalogCode: 'chain_lube',
        name: 'Tra dầu xích',
        intervalKm: 500,
        lastServiceDate: DateTime.utc(2026, 6, 1),
        baselineIsGuess: false,
      );
      expect(
        () => computeDue(
          dateBaselineKmInterval,
          vehicle,
          7,
          now: DateTime.utc(2026, 8, 29),
        ),
        returnsNormally,
      );
      expect(
        computeDue(
          dateBaselineKmInterval,
          vehicle,
          7,
          now: DateTime.utc(2026, 8, 29),
        ),
        isNull,
      );
    });
  });

  group('_timeProgress (khoá theo A4)', () {
    test('progress ~0.5 giữa mốc và hạn, >1.0 khi đã quá hạn', () {
      final vehicle = Vehicle(
        id: 'v13',
        name: 'Xe test',
        type: VehicleType.scooter,
        currentOdoKm: 5000,
        odoUpdatedAt: DateTime.utc(2026, 8, 29),
        avgDailyKm: 20,
        createdAt: DateTime.utc(2026, 8, 29),
      );
      final lastServiceDate = DateTime.utc(2026, 2, 28);
      final item = MaintenanceItem(
        id: 'i13',
        vehicleId: 'v13',
        catalogCode: 'battery',
        name: 'Ắc quy',
        intervalMonths: 6,
        lastServiceDate: lastServiceDate,
        baselineIsGuess: false,
      );

      // 28/2 + 6 tháng = 28/8 -> tổng 181 ngày. 91 ngày sau mốc là số
      // nguyên gần nhất với nửa chặng (181/2 = 90.5).
      final halfwayNow = lastServiceDate.add(const Duration(days: 91));
      final halfwayResult = computeDue(item, vehicle, 7, now: halfwayNow);
      expect(halfwayResult, isNotNull);
      expect(halfwayResult!.progress, closeTo(0.5, 0.01));

      final dueByTime = DateTime(
        lastServiceDate.year,
        lastServiceDate.month + item.intervalMonths!,
        lastServiceDate.day,
      );
      final pastDueNow = dueByTime.add(const Duration(days: 30)).toUtc();
      final pastDueResult = computeDue(item, vehicle, 7, now: pastDueNow);
      expect(pastDueResult, isNotNull);
      // DueResult.progress được ghi tài liệu là 0..1+ — trục thời gian
      // KHÔNG bị kẹp ở đỉnh, giống trục km. Nếu một refactor sau này thêm
      // clamp, test này sẽ báo đỏ.
      expect(pastDueResult!.progress, greaterThan(1.0));
    });
  });
}

/// Calendar date only, for comparing a due date without its time component.
DateTime _dateOf(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}
