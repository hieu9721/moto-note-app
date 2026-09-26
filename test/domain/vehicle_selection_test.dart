// Tests for selectedVehicle (06-01, P6-D-01/P6-D-02/P6-D-03). Runs under
// plain `dart test`, no Flutter engine — package:test only (D-32, P1-D-11).
// The fifth test file under test/domain/. Fixture shape copied field-for-
// field from test/domain/due_test.dart and test/domain/notification_plan_test.dart.
import 'package:motonote/domain/models/app_data.dart';
import 'package:motonote/domain/models/misc.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:motonote/domain/vehicle_selection.dart';
import 'package:test/test.dart';

Vehicle _vehicle({String id = 'v1', String name = 'Xe test'}) {
  return Vehicle(
    id: id,
    name: name,
    type: VehicleType.scooter,
    currentOdoKm: 10000,
    odoUpdatedAt: DateTime.utc(2026, 8, 29),
    avgDailyKm: 20,
    createdAt: DateTime.utc(2026, 8, 29),
  );
}

AppData _appData({List<Vehicle>? vehicles, Settings? settings}) {
  return AppData(
    updatedAt: DateTime.utc(2026, 8, 29),
    vehicles: vehicles ?? const [],
    settings: settings ?? const Settings(),
  );
}

void main() {
  group('selectedVehicle', () {
    test('selectedVehicleId khớp -> trả về đúng xe đó', () {
      final v1 = _vehicle(id: 'v1', name: 'Xe 1');
      final v2 = _vehicle(id: 'v2', name: 'Xe 2');
      final data = _appData(
        vehicles: [v1, v2],
        settings: const Settings(selectedVehicleId: 'v2'),
      );

      final result = selectedVehicle(data);

      expect(result, isNotNull);
      expect(result!.id, 'v2');
      // Trả về đúng instance trong danh sách — caller có thể dựa vào định
      // danh (identity), không cần tra cứu lại.
      expect(identical(result, v2), isTrue);
    });

    test('selectedVehicleId null, danh sách không rỗng -> trả về xe đầu tiên '
        '(quy tắc chuẩn hoá)', () {
      final v1 = _vehicle(id: 'v1', name: 'Xe 1');
      final v2 = _vehicle(id: 'v2', name: 'Xe 2');
      final data = _appData(
        vehicles: [v1, v2],
        settings: const Settings(selectedVehicleId: null),
      );

      final result = selectedVehicle(data);

      expect(result, isNotNull);
      expect(result!.id, 'v1');
      expect(identical(result, v1), isTrue);
    });

    test('selectedVehicleId trỏ tới xe không còn tồn tại -> chuẩn hoá về xe '
        'đầu tiên, không ném lỗi', () {
      final v1 = _vehicle(id: 'v1', name: 'Xe 1');
      final v2 = _vehicle(id: 'v2', name: 'Xe 2');
      final data = _appData(
        vehicles: [v1, v2],
        settings: const Settings(selectedVehicleId: 'ghost-id'),
      );

      expect(() => selectedVehicle(data), returnsNormally);
      final result = selectedVehicle(data);
      expect(result, isNotNull);
      expect(result!.id, 'v1');
      expect(identical(result, v1), isTrue);
    });

    test('danh sách xe rỗng -> trả về null, không ném lỗi', () {
      final data = _appData(
        vehicles: const [],
        settings: const Settings(selectedVehicleId: 'v1'),
      );

      expect(() => selectedVehicle(data), returnsNormally);
      expect(selectedVehicle(data), isNull);
    });
  });
}
