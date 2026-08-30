// Tests for planNotifications/notificationRouteFor (§10.1, §10.4, §10.7).
// Runs under plain `dart test`, no Flutter engine — package:test only
// (D-32/P1-D-11, P4-D-13). Fixture shape copied field-for-field from
// test/domain/due_test.dart. This is the phase's fourth test file.
import 'package:motonote/domain/models/app_data.dart';
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

AppData _appData({List<Vehicle>? vehicles, Settings? settings}) {
  return AppData(
    updatedAt: DateTime.utc(2026, 8, 29),
    vehicles: vehicles ?? [_vehicle()],
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
}
