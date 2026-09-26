// Tests for planNotifications/notificationRouteFor (§10.1, §10.4, §10.7).
// Runs under plain `dart test`, no Flutter engine — package:test only
// (D-32/P1-D-11, P4-D-13). Fixture shape copied field-for-field from
// test/domain/due_test.dart. This is the phase's fourth test file.
import 'package:motonote/domain/models/app_data.dart';
import 'package:motonote/domain/models/maintenance_item.dart';
import 'package:motonote/domain/models/misc.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:motonote/domain/notification_plan.dart';
import 'package:test/test.dart';

Vehicle _vehicle({
  String id = 'v1',
  String name = 'Xe test',
  int currentOdoKm = 10000,
  DateTime? odoUpdatedAt,
  double avgDailyKm = 20,
}) {
  return Vehicle(
    id: id,
    name: name,
    type: VehicleType.scooter,
    currentOdoKm: currentOdoKm,
    odoUpdatedAt: odoUpdatedAt ?? DateTime.utc(2026, 8, 29),
    avgDailyKm: avgDailyKm,
    createdAt: DateTime.utc(2026, 8, 29),
  );
}

// Sentinel distinguishing "caller omitted lastServiceDate" (falls back to
// the default below) from "caller explicitly passed null" (stays null, to
// exercise the km-only / no-baseline branches) — `DateTime.utc(...)` is not
// a compile-time constant, so it cannot be a normal default parameter
// value, and a plain `lastServiceDate ?? default` cannot tell the two
// apart.
const _unset = Object();

// Time-axis-by-default fixture — mirrors due_test.dart's own fixtures. A
// caller wanting the km axis instead passes `lastServiceDate: null,
// intervalMonths: null` alongside `intervalKm`/`lastServiceOdo`. The due
// date this planner reads back is always a predictable local civil date,
// never reconstructed here — the planner reads `DueResult.dueDate`, it
// never recomputes it.
MaintenanceItem _item({
  String id = 'i1',
  String vehicleId = 'v1',
  String name = 'Nhớt máy',
  int? intervalMonths = 3,
  Object? lastServiceDate = _unset,
  int? intervalKm,
  int? lastServiceOdo,
  bool enabled = true,
  bool baselineIsGuess = false,
}) {
  final DateTime? resolvedDate = identical(lastServiceDate, _unset)
      ? DateTime.utc(2026, 2, 1)
      : lastServiceDate as DateTime?;
  return MaintenanceItem(
    id: id,
    vehicleId: vehicleId,
    catalogCode: 'engine_oil',
    name: name,
    intervalMonths: intervalMonths,
    lastServiceDate: resolvedDate,
    intervalKm: intervalKm,
    lastServiceOdo: lastServiceOdo,
    enabled: enabled,
    baselineIsGuess: baselineIsGuess,
  );
}

// A km-axis item overdue by exactly [daysOverdue] days as of whatever `now`
// the caller passes to `computeDue`/`shouldShowDeadNotificationBanner`,
// PROVIDED the paired vehicle has `odoUpdatedAt: now` and `avgDailyKm: 1`
// (zeroes `daysSinceOdo` and makes `kmLeft` a 1:1 day count) — the same
// exact-day-offset trick the `planNotifications` horizon/cap tests use.
MaintenanceItem _overdueItem({
  required String id,
  required String vehicleId,
  required int daysOverdue,
}) {
  return _item(
    id: id,
    vehicleId: vehicleId,
    intervalMonths: null,
    lastServiceDate: null,
    intervalKm: -daysOverdue,
    lastServiceOdo: 10000,
  );
}

AppData _appData({
  List<Vehicle>? vehicles,
  List<MaintenanceItem>? items,
  Settings? settings,
}) {
  return AppData(
    updatedAt: DateTime.utc(2026, 8, 29),
    vehicles: vehicles ?? [_vehicle()],
    items: items ?? const [],
    settings: settings ?? const Settings(),
  );
}

void main() {
  group('odo reminder', () {
    test('notifications disabled trả về danh sách rỗng', () {
      final data = _appData(
        settings: const Settings(notificationsEnabled: false),
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 8, 29));
      expect(result, isEmpty);
    });

    test('vehicles rỗng không tạo nhắc ODO', () {
      final data = _appData(vehicles: const []);
      final result = planNotifications(data, now: DateTime.utc(2026, 8, 29));
      expect(result, isEmpty);
    });

    test('odoReminderEnabled = false không tạo nhắc ODO', () {
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 8, 29));
      expect(result, isEmpty);
    });

    test('mốc tháng hiện tại đã qua -> chỉ còn 5 nhắc ODO trong tương lai '
        '(CR-01)', () {
      // now đặt trên đồng hồ giờ địa phương (không phải DateTime.utc) để
      // cả hai vế của isAfter đều là giờ dân sự cục bộ — kết quả không
      // phụ thuộc múi giờ máy chạy test (WR-02).
      final now = DateTime(2026, 8, 29, 12);
      final data = _appData();
      final result = planNotifications(data, now: now);
      expect(result, hasLength(5));
      for (final p in result) {
        expect(p.payload, 'odo:v1');
      }
      for (final p in result) {
        expect(p.scheduledAt.isAfter(now), isTrue);
      }
      expect(result.first.scheduledAt, DateTime(2026, 9, 1, 8));
      expect(result.last.scheduledAt, DateTime(2027, 1, 1, 8));
    });

    test(
      'mốc tháng hiện tại chưa tới -> đủ 6 nhắc ODO, kể cả tháng hiện tại',
      () {
        final now = DateTime(2026, 8, 1, 7);
        final data = _appData();
        final result = planNotifications(data, now: now);
        expect(result, hasLength(6));
        expect(result.first.scheduledAt, DateTime(2026, 8, 1, 8));
        expect(result.last.scheduledAt, DateTime(2027, 1, 1, 8));
        for (final p in result) {
          expect(p.scheduledAt.isAfter(now), isTrue);
        }
      },
    );

    test('now trùng đúng mốc tháng hiện tại -> mốc đó bị loại (strictly-after, '
        'CR-01, cùng quy tắc với due-item loop)', () {
      final now = DateTime(2026, 8, 1, 8);
      final data = _appData();
      final result = planNotifications(data, now: now);
      expect(result, hasLength(5));
      expect(result.first.scheduledAt, DateTime(2026, 9, 1, 8));
    });

    test('body chứa đúng tên xe kèm dấu tiếng Việt', () {
      final data = _appData(vehicles: [_vehicle(name: 'Vision Hà Nội')]);
      final result = planNotifications(data, now: DateTime.utc(2026, 8, 29));
      expect(result, isNotEmpty);
      expect(result.first.body, contains('Vision Hà Nội'));
      expect(result.first.body, contains('~'));
      expect(result.first.body, contains('Số thật là bao nhiêu?'));
      expect(result.first.title, 'Cập nhật số km');
    });

    test('odoReminderDayOfMonth 31 chốt ngày 30 trong tháng 30 ngày', () {
      // now = 29/8/2026 (tháng 8 có 31 ngày). monthsAhead = 1 -> tháng 9
      // (30 ngày) -> ngày 31 phải chốt về ngày 30.
      final data = _appData(
        settings: const Settings(odoReminderDayOfMonth: 31, notifyHour: 8),
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 8, 29));
      final september = result.firstWhere((p) => p.scheduledAt.month == 9);
      expect(september.scheduledAt.day, 30);
    });

    test('odoReminderDayOfMonth 31 chốt ngày cuối tháng 2', () {
      // now = 29/12/2026. monthsAhead = 2 -> tháng 2/2027 (không nhuận,
      // 28 ngày) -> ngày 31 phải chốt về ngày 28, không lăn sang tháng 3.
      final data = _appData(
        settings: const Settings(odoReminderDayOfMonth: 31, notifyHour: 8),
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 12, 29));
      final february = result.firstWhere((p) => p.scheduledAt.month == 2);
      expect(february.scheduledAt.day, 28);
      expect(february.scheduledAt.year, 2027);
    });
  });

  // 06-01 (P6-D-04): every vehicle gets its own monthly ODO reminder, named
  // when there is more than one. `now` reused from the already-established
  // 'mốc tháng hiện tại chưa tới' fixture above — DateTime(2026, 8, 1, 7)
  // gives a known, deterministic per-vehicle count of 6 (no strictly-after
  // filtering kicks in for any of the 6 monthly slots at this `now`).
  group('odo reminder multi-vehicle (06-01, P6-D-04)', () {
    test('ba xe, odoReminderEnabled true -> số nhắc ODO gấp 3 lần một xe cùng '
        'now, đủ 3 payload odo: riêng biệt', () {
      final now = DateTime(2026, 8, 1, 7);
      final singleData = _appData(vehicles: [_vehicle(id: 'v1')]);
      final singleOdo = planNotifications(
        singleData,
        now: now,
      ).where((p) => p.payload.startsWith('odo:')).toList();

      final multiData = _appData(
        vehicles: [
          _vehicle(id: 'v1', name: 'Xe 1'),
          _vehicle(id: 'v2', name: 'Xe 2'),
          _vehicle(id: 'v3', name: 'Xe 3'),
        ],
      );
      final multiOdo = planNotifications(
        multiData,
        now: now,
      ).where((p) => p.payload.startsWith('odo:')).toList();

      expect(multiOdo.length, singleOdo.length * 3);
      final payloads = multiOdo.map((p) => p.payload).toSet();
      expect(payloads, hasLength(3));
      expect(payloads, containsAll(['odo:v1', 'odo:v2', 'odo:v3']));
    });

    test('ba xe -> mỗi nhắc ODO chứa đúng tên xe của chính nó, không xe nào '
        'trùng tiêu đề', () {
      final now = DateTime(2026, 8, 1, 7);
      final data = _appData(
        vehicles: [
          _vehicle(id: 'v1', name: 'Xe 1'),
          _vehicle(id: 'v2', name: 'Xe 2'),
          _vehicle(id: 'v3', name: 'Xe 3'),
        ],
      );
      final odo = planNotifications(
        data,
        now: now,
      ).where((p) => p.payload.startsWith('odo:')).toList();
      expect(odo, isNotEmpty);

      const namesById = {'v1': 'Xe 1', 'v2': 'Xe 2', 'v3': 'Xe 3'};
      final titleByVehicle = <String, String>{};
      for (final p in odo) {
        final vehicleId = p.payload.split(':')[1];
        expect(p.title, contains(namesById[vehicleId]!));
        titleByVehicle[vehicleId] = p.title;
      }
      // Ba xe tên khác nhau -> ba tiêu đề khác nhau, không trùng lặp.
      expect(titleByVehicle.values.toSet(), hasLength(3));
    });

    test('đúng một xe -> tiêu đề bằng đúng chuỗi Phase 04 đã ship, khớp chuỗi '
        'literal, không so với const mới', () {
      final now = DateTime(2026, 8, 1, 7);
      final data = _appData(
        vehicles: [_vehicle(id: 'v1', name: 'Xe test')],
      );
      final odo = planNotifications(
        data,
        now: now,
      ).where((p) => p.payload == 'odo:v1').toList();
      expect(odo, isNotEmpty);
      for (final p in odo) {
        // So sánh với literal, không phải const mới trong
        // notification_plan.dart — một sửa đổi tương lai với const đó
        // không được âm thầm đổi copy đã ship.
        expect(p.title, 'Cập nhật số km');
      }
    });

    test('không xe, odoReminderEnabled true -> không có nhắc ODO, không ném '
        'lỗi', () {
      final now = DateTime(2026, 8, 1, 7);
      final data = _appData(vehicles: const []);
      expect(() => planNotifications(data, now: now), returnsNormally);
      final result = planNotifications(data, now: now);
      expect(result.where((p) => p.payload.startsWith('odo:')), isEmpty);
    });
  });

  group('payload', () {
    test('odo:{id đã biết} trả về /?sheet=odo', () {
      final data = _appData();
      expect(notificationRouteFor('odo:v1', data), '/?sheet=odo');
    });

    test('due:{id đã biết} trả về /', () {
      final data = _appData();
      expect(notificationRouteFor('due:v1', data), '/');
    });

    test('odo:{id không tồn tại} trả về / (honest no-op, P4-D-04)', () {
      final data = _appData();
      expect(notificationRouteFor('odo:unknown', data), '/');
    });

    test('payload null trả về /', () {
      final data = _appData();
      expect(notificationRouteFor(null, data), '/');
    });

    test('payload rỗng trả về /', () {
      final data = _appData();
      expect(notificationRouteFor('', data), '/');
    });

    test('payload không có dấu hai chấm trả về /', () {
      final data = _appData();
      expect(notificationRouteFor('odov1', data), '/');
    });

    test('payload có hai dấu hai chấm trả về /', () {
      final data = _appData();
      expect(notificationRouteFor('odo:v1:extra', data), '/');
    });
  });

  // §10.1's cadence, read back through `planNotifications`'s public surface
  // — `_notifyDatesFor` itself is private to lib/domain/notification_plan.dart
  // and not reachable from this separate test library, exactly the same
  // indirection the existing 'odo reminder' group already uses for
  // `_nthMonthDay`.
  group('notifyDatesFor', () {
    test('due date item tạo đúng 4 mốc ứng viên: leadDays trước, đúng hạn, '
        '+14, +28', () {
      // lastServiceDate 1/2/2026 + 3 tháng -> hạn 1/5/2026. leadDays mặc
      // định 7 -> sắp tới hạn 24/4. Chọn now cách xa cả 4 mốc để tất cả
      // đều còn hiệu lực (trong 120 ngày, sau now).
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [_item()],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 3, 1));
      final due = result.where((p) => p.payload == 'due:v1').toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      expect(due, hasLength(4));
      expect(due[0].scheduledAt.month, 4);
      expect(due[0].scheduledAt.day, 24); // sắp tới hạn: 1/5 - 7 ngày
      expect(due[1].scheduledAt.month, 5);
      expect(due[1].scheduledAt.day, 1); // đúng hạn
      expect(due[2].scheduledAt.month, 5);
      expect(due[2].scheduledAt.day, 15); // +14
      expect(due[3].scheduledAt.month, 5);
      expect(due[3].scheduledAt.day, 29); // +28
    });

    test(
      'leadDays 0 gộp mốc sắp tới hạn và mốc đúng hạn vào cùng một bucket',
      () {
        final data = _appData(
          settings: const Settings(odoReminderEnabled: false, leadDays: 0),
          items: [_item()],
        );
        final result = planNotifications(data, now: DateTime.utc(2026, 3, 1));
        final due = result.where((p) => p.payload == 'due:v1').toList();
        // Với leadDays: 0, mốc "sắp tới hạn" trùng mốc "đúng hạn" -> gộp một
        // bucket duy nhất thay vì hai, và tên hạng mục không bị lặp lại.
        final may1 = due.where(
          (p) => p.scheduledAt.month == 5 && p.scheduledAt.day == 1,
        );
        expect(may1, hasLength(1));
        expect(may1.first.body, 'Nhớt máy');
        expect(may1.first.body, isNot(contains('và')));
      },
    );

    test('mốc đã qua bị loại (không strictly-after now)', () {
      // now đặt sau mốc "sắp tới hạn" và mốc "đúng hạn" nhưng trước mốc
      // +14 và +28 -> chỉ còn 2 mốc trong kết quả.
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [_item()],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 10));
      final due = result.where((p) => p.payload == 'due:v1').toList();
      expect(due, hasLength(2));
      for (final p in due) {
        expect(p.scheduledAt.isAfter(DateTime.utc(2026, 5, 10)), isTrue);
      }
    });

    test(
      'computeDue trả về null (hạng mục tắt) không tạo mốc và không ném lỗi',
      () {
        final data = _appData(
          settings: const Settings(odoReminderEnabled: false),
          items: [_item(enabled: false)],
        );
        expect(
          () => planNotifications(data, now: DateTime.utc(2026, 3, 1)),
          returnsNormally,
        );
        final result = planNotifications(data, now: DateTime.utc(2026, 3, 1));
        expect(result.where((p) => p.payload == 'due:v1'), isEmpty);
      },
    );

    test(
      'hạng mục không có mốc trên trục nào không tạo mốc và không ném lỗi',
      () {
        final data = _appData(
          settings: const Settings(odoReminderEnabled: false),
          items: [_item(intervalMonths: null, lastServiceDate: null)],
        );
        expect(
          () => planNotifications(data, now: DateTime.utc(2026, 3, 1)),
          returnsNormally,
        );
      },
    );
  });

  group('grouping', () {
    test('hai hạng mục, một xe, cùng một ngày -> đúng 1 thông báo', () {
      // Cả hai hạng mục có cùng lịch (đến hạn 1/5/2026). Chọn now = hạn +
      // 20 ngày (21/5) để 3 mốc đầu (sắp tới hạn, đúng hạn, +14) đều đã
      // qua và chỉ còn mốc +28 (29/5) — cô lập còn đúng MỘT bucket chung
      // cho cả hai hạng mục, tránh phép cộng dồn qua nhiều bucket.
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [
          _item(id: 'i1', name: 'Nhớt máy'),
          _item(id: 'i2', name: 'Lọc gió'),
        ],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload == 'due:v1').toList();
      expect(due, hasLength(1));
      expect(due.first.body, contains('Nhớt máy'));
      expect(due.first.body, contains('Lọc gió'));
      expect(due.first.body, contains(' và '));
      expect(due.first.title, 'Xe test sắp tới hạn');
    });

    test('hai hạng mục, hai xe, cùng một ngày -> đúng 2 thông báo', () {
      final data = _appData(
        vehicles: [
          _vehicle(),
          _vehicle(id: 'v2', name: 'Xe test 2'),
        ],
        settings: const Settings(odoReminderEnabled: false),
        items: [
          _item(id: 'i1', vehicleId: 'v1', name: 'Nhớt máy'),
          _item(id: 'i2', vehicleId: 'v2', name: 'Lọc gió'),
        ],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload.startsWith('due:')).toList();
      expect(due, hasLength(2));
      expect(due.map((p) => p.payload), containsAll(['due:v1', 'due:v2']));
    });

    test('một hạng mục trong bucket -> tiêu đề và nội dung dạng đơn', () {
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [_item(id: 'i1', name: 'Nhớt máy')],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload == 'due:v1').toList();
      expect(due, hasLength(1));
      expect(due.first.title, 'Xe test sắp tới hạn');
      expect(due.first.body, 'Nhớt máy');
    });

    test('hai hạng mục trong bucket -> dạng "và"', () {
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [
          _item(id: 'i1', name: 'Nhớt máy'),
          _item(id: 'i2', name: 'Lọc gió'),
        ],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload == 'due:v1').toList();
      expect(due, hasLength(1));
      expect(due.first.title, 'Xe test sắp tới hạn');
      expect(due.first.body, 'Nhớt máy và Lọc gió');
    });

    test('ba hạng mục trong bucket -> ranh giới sang dạng "N mục khác"', () {
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [
          _item(id: 'i1', name: 'Nhớt máy'),
          _item(id: 'i2', name: 'Lọc gió'),
          _item(id: 'i3', name: 'Bugi'),
        ],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload == 'due:v1').toList();
      expect(due, hasLength(1));
      expect(due.first.title, 'Xe test có 3 hạng mục sắp tới hạn');
      expect(due.first.body, 'Nhớt máy, Lọc gió và 1 mục khác');
    });

    test('bốn hạng mục trong bucket -> đếm đúng và "2 mục khác"', () {
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: [
          _item(id: 'i1', name: 'Nhớt máy'),
          _item(id: 'i2', name: 'Lọc gió'),
          _item(id: 'i3', name: 'Bugi'),
          _item(id: 'i4', name: 'Nước làm mát'),
        ],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload == 'due:v1').toList();
      expect(due, hasLength(1));
      expect(due.first.title, 'Xe test có 4 hạng mục sắp tới hạn');
      expect(due.first.body, endsWith('và 2 mục khác'));
    });
  });

  group('planNotifications', () {
    test(
      'mốc đúng bằng kNotificationHorizonDays được lên lịch, +1 ngày thì không',
      () {
        // now = 1/1/2026. now + 120 ngày = 1/5/2026 (31+28+31+30 = 120,
        // 2026 không nhuận). Đặt mốc "đúng hạn" của hạng mục vào đúng
        // 1/5/2026 để kiểm tra ranh giới chính xác ở biên trên/dưới.
        final dataIn = _appData(
          settings: const Settings(odoReminderEnabled: false),
          items: [
            _item(lastServiceDate: DateTime.utc(2026, 2, 1), intervalMonths: 3),
          ],
        );
        final resultIn = planNotifications(
          dataIn,
          now: DateTime.utc(2026, 1, 1),
        );
        final dueDayIn = resultIn.where(
          (p) =>
              p.payload == 'due:v1' &&
              p.scheduledAt.year == 2026 &&
              p.scheduledAt.month == 5 &&
              p.scheduledAt.day == 1,
        );
        expect(dueDayIn, hasLength(1)); // ngày 120 -> còn trong lịch

        // Để cùng mốc 1/5 rơi ra ngoài đúng kNotificationHorizonDays + 1
        // ngày, mốc phải cách "now" xa hơn — lùi "now" lại 1 ngày (31/12
        // /2025), không đẩy tới, vì khoảng cách ngày = mốc - now: now càng
        // sớm thì khoảng cách càng lớn.
        final resultOut = planNotifications(
          dataIn,
          now: DateTime.utc(2025, 12, 31),
        );
        final dueDayOut = resultOut.where(
          (p) =>
              p.payload == 'due:v1' &&
              p.scheduledAt.year == 2026 &&
              p.scheduledAt.month == 5 &&
              p.scheduledAt.day == 1,
        );
        expect(dueDayOut, isEmpty); // ngày 121 -> ngoài chân trời
      },
    );

    test('40 mốc khả lịch -> chỉ giữ đúng 30 mốc sớm nhất', () {
      // 40 xe riêng biệt, mỗi xe một hạng mục trên trục km (kmLeft = số
      // ngày chính xác vì avgDailyKm = 1) — khoá bucket gồm vehicleId nên
      // không xe nào gộp chung với xe khác, dù cùng ngày. leadDays: 0 gộp
      // "sắp tới hạn" vào "đúng hạn"; khoảng cách được chọn (>106 ngày)
      // đẩy cả +14 lẫn +28 ra ngoài chân trời 120 ngày, nên MỖI xe chỉ còn
      // đúng MỘT mốc sống sót — mốc "đúng hạn" của chính nó.
      //
      // 30 xe nhóm "sớm": mốc cách now đúng 107 ngày (còn trong chân trời,
      // +14 = 121 ngày thì bị loại).
      // 10 xe nhóm "muộn": mốc cách now đúng 120 ngày (đúng biên chân
      // trời).
      // Vì 107 < 120, toàn bộ 30 mốc "sớm" luôn xếp trước cả 10 mốc
      // "muộn" trong bản sắp xếp — phép cắt ở 30 phải giữ NGUYÊN nhóm sớm
      // và loại bỏ TOÀN BỘ nhóm muộn, không phụ thuộc vào tie-break.
      final now = DateTime.utc(2026, 1, 1);
      final earlyVehicles = List.generate(
        30,
        (i) => _vehicle(id: 'vE$i', odoUpdatedAt: now, avgDailyKm: 1),
      );
      final lateVehicles = List.generate(
        10,
        (i) => _vehicle(id: 'vL$i', odoUpdatedAt: now, avgDailyKm: 1),
      );
      final earlyItems = List.generate(
        30,
        (i) => _item(
          id: 'ie$i',
          vehicleId: 'vE$i',
          intervalMonths: null,
          lastServiceDate: null,
          intervalKm: 107,
          lastServiceOdo: 10000,
        ),
      );
      final lateItems = List.generate(
        10,
        (i) => _item(
          id: 'il$i',
          vehicleId: 'vL$i',
          intervalMonths: null,
          lastServiceDate: null,
          intervalKm: 120,
          lastServiceOdo: 10000,
        ),
      );
      final data = _appData(
        vehicles: [...earlyVehicles, ...lateVehicles],
        settings: const Settings(odoReminderEnabled: false, leadDays: 0),
        items: [...earlyItems, ...lateItems],
      );
      final result = planNotifications(data, now: now);
      expect(result, hasLength(kMaxScheduledNotifications));
      expect(result.length, 30);
      // Toàn bộ 30 kết quả phải thuộc nhóm "sớm" (vE*) — nhóm "muộn" (vL*)
      // bị loại hoàn toàn.
      expect(result.every((p) => p.payload.startsWith('due:vE')), isTrue);
      // Kết quả vẫn phải được sắp xếp không giảm dần theo scheduledAt.
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].scheduledAt.isBefore(result[i - 1].scheduledAt),
          isFalse,
        );
      }
    });

    test('hai mốc trùng scheduledAt -> thứ tự ổn định theo payload', () {
      // Hai hạng mục trên hai xe khác nhau, cùng lịch, để mốc "đúng hạn"
      // của cả hai trùng scheduledAt nhau (cùng ngày, cùng notifyHour).
      final data = _appData(
        vehicles: [
          _vehicle(id: 'vA'),
          _vehicle(id: 'vB', name: 'Xe B'),
        ],
        settings: const Settings(odoReminderEnabled: false),
        items: [
          _item(id: 'i1', vehicleId: 'vA', name: 'Nhớt máy'),
          _item(id: 'i2', vehicleId: 'vB', name: 'Nhớt máy'),
        ],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      final due = result.where((p) => p.payload.startsWith('due:')).toList();
      expect(due, hasLength(2));
      expect(due[0].scheduledAt, due[1].scheduledAt);
      // 'due:vA' < 'due:vB' theo so sánh chuỗi -> vA phải đứng trước.
      expect(due[0].payload, 'due:vA');
      expect(due[1].payload, 'due:vB');
    });

    test('notificationsEnabled: false trả về danh sách rỗng dù có hạng mục quá hạn', () {
      final data = _appData(
        settings: const Settings(notificationsEnabled: false),
        items: [_item()],
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 5, 21));
      expect(result, isEmpty);
    });

    test('AppData rỗng (không xe, không hạng mục) trả về danh sách rỗng, không ném lỗi', () {
      final data = _appData(vehicles: const [], items: const []);
      expect(
        () => planNotifications(data, now: DateTime.utc(2026, 5, 21)),
        returnsNormally,
      );
      expect(planNotifications(data, now: DateTime.utc(2026, 5, 21)), isEmpty);
    });
  });

  // Mã hoá lại ý định "generalized schedule mode" của 04-01's
  // `<assumption_delta_decision>`: `zonedSchedule`'s `validateDateIsInTheFuture`
  // là điều kiện tiên quyết DUY NHẤT đúng dưới MỌI `AndroidScheduleMode`, nên
  // đây là bài test chống hồi quy nếu một phase sau này vô tình đưa giả định
  // "chỉ chạy exact mode" trở lại. `now` được đặt lại trên giờ địa phương
  // (không còn DateTime.utc) để đóng WR-02 — kết quả không còn phụ thuộc múi
  // giờ máy chạy test.
  group('schedulable under either mode', () {
    test(
      'mọi PlannedNotification trả về đều có scheduledAt strictly sau now',
      () {
        final data = _appData(
          vehicles: [
            _vehicle(),
            _vehicle(id: 'v2', name: 'Xe 2'),
          ],
          settings: const Settings(),
          items: [
            _item(id: 'i1', vehicleId: 'v1', name: 'Nhớt máy'),
            _item(
              id: 'i2',
              vehicleId: 'v2',
              name: 'Lọc gió',
              lastServiceDate: DateTime.utc(2026, 4, 1),
              intervalMonths: 1,
            ),
          ],
        );
        final now = DateTime(2026, 3, 15, 12);
        final result = planNotifications(data, now: now);
        expect(result, isNotEmpty);
        for (final p in result) {
          expect(p.scheduledAt.isAfter(now), isTrue);
        }
      },
    );
  });

  group('dead notification', () {
    test('mới cài đặt, lastNotificationFiredAt null, không có hạng mục quá hạn '
        '-> false', () {
      final now = DateTime.utc(2026, 6, 1);
      final data = _appData(
        vehicles: [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)],
      );
      expect(shouldShowDeadNotificationBanner(data, now: now), isFalse);
    });

    test('notificationsEnabled: false -> false dù mọi điều kiện khác đúng', () {
      final now = DateTime.utc(2026, 6, 1);
      final data = _appData(
        vehicles: [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)],
        settings: const Settings(notificationsEnabled: false),
        items: [_overdueItem(id: 'i1', vehicleId: 'v1', daysOverdue: 90)],
      );
      expect(shouldShowDeadNotificationBanner(data, now: now), isFalse);
    });

    test(
      'quá hạn đúng 45 ngày, lastNotificationFiredAt null -> false (ranh giới)',
      () {
        final now = DateTime.utc(2026, 6, 1);
        final data = _appData(
          vehicles: [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)],
          items: [_overdueItem(id: 'i1', vehicleId: 'v1', daysOverdue: 45)],
        );
        expect(shouldShowDeadNotificationBanner(data, now: now), isFalse);
      },
    );

    test(
      'quá hạn 46 ngày, lastNotificationFiredAt null -> true (ranh giới)',
      () {
        final now = DateTime.utc(2026, 6, 1);
        final data = _appData(
          vehicles: [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)],
          items: [_overdueItem(id: 'i1', vehicleId: 'v1', daysOverdue: 46)],
        );
        expect(shouldShowDeadNotificationBanner(data, now: now), isTrue);
      },
    );

    test('quá hạn 90 ngày nhưng lastNotificationFiredAt cách đây 10 ngày '
        '-> false', () {
      final now = DateTime.utc(2026, 6, 1);
      final data = _appData(
        vehicles: [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)],
        settings: Settings(
          lastNotificationFiredAt: now.subtract(const Duration(days: 10)),
        ),
        items: [_overdueItem(id: 'i1', vehicleId: 'v1', daysOverdue: 90)],
      );
      expect(shouldShowDeadNotificationBanner(data, now: now), isFalse);
    });

    test(
      'quá hạn 90 ngày và lastNotificationFiredAt cách đây 60 ngày -> true',
      () {
        final now = DateTime.utc(2026, 6, 1);
        final data = _appData(
          vehicles: [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)],
          settings: Settings(
            lastNotificationFiredAt: now.subtract(const Duration(days: 60)),
          ),
          items: [_overdueItem(id: 'i1', vehicleId: 'v1', daysOverdue: 90)],
        );
        expect(shouldShowDeadNotificationBanner(data, now: now), isTrue);
      },
    );

    test('không xe, không hạng mục -> false, không ném lỗi', () {
      final data = _appData(vehicles: const [], items: const []);
      expect(() => shouldShowDeadNotificationBanner(data), returnsNormally);
      expect(shouldShowDeadNotificationBanner(data), isFalse);
    });

    test('hai hạng mục quá hạn, một đạt điều kiện một không -> cùng kết quả '
        'dù đổi thứ tự danh sách', () {
      final now = DateTime.utc(2026, 6, 1);
      final qualifying = _overdueItem(
        id: 'i1',
        vehicleId: 'v1',
        daysOverdue: 90,
      );
      final notQualifying = _overdueItem(
        id: 'i2',
        vehicleId: 'v1',
        daysOverdue: 10,
      );
      final vehicles = [_vehicle(odoUpdatedAt: now, avgDailyKm: 1)];
      final dataOrder1 = _appData(
        vehicles: vehicles,
        items: [qualifying, notQualifying],
      );
      final dataOrder2 = _appData(
        vehicles: vehicles,
        items: [notQualifying, qualifying],
      );
      expect(shouldShowDeadNotificationBanner(dataOrder1, now: now), isTrue);
      expect(shouldShowDeadNotificationBanner(dataOrder2, now: now), isTrue);
    });
  });
}
