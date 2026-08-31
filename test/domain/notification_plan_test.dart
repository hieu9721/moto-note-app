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

// Time-axis fixture — mirrors due_test.dart's own fixtures. Kept deliberately
// simple (intervalMonths + lastServiceDate only) so the due date this
// planner reads back is a predictable local civil date, never reconstructed
// here — the planner reads `DueResult.dueDate`, it never recomputes it.
MaintenanceItem _item({
  String id = 'i1',
  String vehicleId = 'v1',
  String name = 'Nhớt máy',
  int? intervalMonths = 3,
  DateTime? lastServiceDate,
  bool enabled = true,
  bool baselineIsGuess = false,
}) {
  return MaintenanceItem(
    id: id,
    vehicleId: vehicleId,
    catalogCode: 'engine_oil',
    name: name,
    intervalMonths: intervalMonths,
    lastServiceDate: lastServiceDate ?? DateTime.utc(2026, 2, 1),
    enabled: enabled,
    baselineIsGuess: baselineIsGuess,
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

    test('tạo đủ sáu nhắc ODO cho một fixture khỏe mạnh', () {
      final data = _appData();
      final result = planNotifications(data, now: DateTime.utc(2026, 8, 29));
      expect(result, hasLength(6));
      for (final p in result) {
        expect(p.payload, 'odo:v1');
      }
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

        // Đẩy now lùi 1 ngày (2/1/2026) để cùng mốc 1/5 rơi ra ngoài đúng
        // kNotificationHorizonDays + 1 ngày.
        final resultOut = planNotifications(
          dataIn,
          now: DateTime.utc(2026, 1, 2),
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
      final items = List.generate(
        40,
        (i) => _item(
          id: 'i$i',
          name: 'Hạng mục $i',
          // Rải đều mỗi hạng mục cách nhau 1 ngày trên trục lastServiceDate
          // để mỗi hạng mục rơi vào một bucket-ngày riêng biệt (khác ngày),
          // sinh ra 40 bucket độc lập thay vì gộp chung.
          lastServiceDate: DateTime.utc(2026, 2, 1).add(Duration(days: i)),
        ),
      );
      final data = _appData(
        settings: const Settings(odoReminderEnabled: false),
        items: items,
      );
      final result = planNotifications(data, now: DateTime.utc(2026, 1, 1));
      expect(result, hasLength(kMaxScheduledNotifications));
      expect(result.length, 30);
      // Kết quả phải là 30 mốc SỚM NHẤT: mỗi phần tử không muộn hơn phần
      // tử kế tiếp — sắp xếp theo scheduledAt.
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
  // "chỉ chạy exact mode" trở lại.
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
        final now = DateTime.utc(2026, 3, 1);
        final result = planNotifications(data, now: now);
        expect(result, isNotEmpty);
        for (final p in result) {
          expect(p.scheduledAt.isAfter(now), isTrue);
        }
      },
    );
  });
}
