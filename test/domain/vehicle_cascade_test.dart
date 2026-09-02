// Tests for applyVehicleDeletion (06-02, P6-D-06/P6-D-25). Runs under plain
// `dart test`, no Flutter engine — package:test only (D-32/P1-D-11).
// Fixture shape follows test/domain/notification_plan_test.dart's style.
import 'package:motonote/domain/models/app_data.dart';
import 'package:motonote/domain/models/maintenance_item.dart';
import 'package:motonote/domain/models/misc.dart';
import 'package:motonote/domain/models/service_log.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:motonote/domain/vehicle_cascade.dart';
import 'package:test/test.dart';

Vehicle _vehicle(String id, {String name = 'Xe test'}) {
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

MaintenanceItem _item(String id, String vehicleId) {
  return MaintenanceItem(
    id: id,
    vehicleId: vehicleId,
    catalogCode: 'engine_oil',
    name: 'Nhớt máy',
    intervalMonths: 3,
    lastServiceDate: DateTime.utc(2026, 2, 1),
  );
}

ServiceLog _log(String id, String vehicleId) {
  return ServiceLog(
    id: id,
    vehicleId: vehicleId,
    date: DateTime.utc(2026, 2, 1),
    odoKm: 5000,
  );
}

OdoReading _odo(String id, String vehicleId) {
  return OdoReading(
    id: id,
    vehicleId: vehicleId,
    odoKm: 5000,
    date: DateTime.utc(2026, 2, 1),
  );
}

Note _note(String id, {String? vehicleId}) {
  return Note(
    id: id,
    vehicleId: vehicleId,
    body: 'ghi chú',
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );
}

AppData _twoVehicleData({String? selectedVehicleId}) {
  return AppData(
    updatedAt: DateTime.utc(2026, 8, 29),
    vehicles: [_vehicle('v1'), _vehicle('v2')],
    items: [_item('i1', 'v1'), _item('i2', 'v2')],
    logs: [_log('l1', 'v1'), _log('l2', 'v2')],
    odoReadings: [_odo('o1', 'v1'), _odo('o2', 'v2')],
    notes: [
      _note('n1', vehicleId: 'v1'),
      _note('n2', vehicleId: 'v2'),
      _note('n3'), // vehicle-less
    ],
    settings: Settings(selectedVehicleId: selectedVehicleId),
  );
}

void main() {
  group('applyVehicleDeletion', () {
    test('deleting one vehicle leaves the other vehicle\'s four collections '
        'with exactly their original contents', () {
      final data = _twoVehicleData(selectedVehicleId: 'v2');
      final result = applyVehicleDeletion(data, 'v1');

      expect(result.vehicles.map((v) => v.id).toSet(), {'v2'});
      expect(result.items.map((i) => i.id).toSet(), {'i2'});
      expect(result.logs.map((l) => l.id).toSet(), {'l2'});
      expect(result.odoReadings.map((o) => o.id).toSet(), {'o2'});
    });

    test('a note with vehicleId: null survives the deletion', () {
      final data = _twoVehicleData(selectedVehicleId: 'v2');
      final result = applyVehicleDeletion(data, 'v1');

      expect(result.notes.map((n) => n.id).toSet(), {'n2', 'n3'});
      expect(result.notes.any((n) => n.id == 'n3'), isTrue);
    });

    test('a note belonging to the deleted vehicle does not survive', () {
      final data = _twoVehicleData(selectedVehicleId: 'v2');
      final result = applyVehicleDeletion(data, 'v1');

      expect(result.notes.any((n) => n.id == 'n1'), isFalse);
    });

    test('deleting the selected vehicle re-points selectedVehicleId to a '
        'remaining vehicle', () {
      final data = _twoVehicleData(selectedVehicleId: 'v1');
      final result = applyVehicleDeletion(data, 'v1');

      expect(result.settings.selectedVehicleId, 'v2');
    });

    test(
      'deleting a non-selected vehicle leaves selectedVehicleId untouched',
      () {
        final data = _twoVehicleData(selectedVehicleId: 'v2');
        final result = applyVehicleDeletion(data, 'v1');

        expect(result.settings.selectedVehicleId, 'v2');
      },
    );

    test('deleting the last vehicle leaves vehicles empty and '
        'selectedVehicleId null', () {
      final data = AppData(
        updatedAt: DateTime.utc(2026, 8, 29),
        vehicles: [_vehicle('v1')],
        items: [_item('i1', 'v1')],
        logs: [_log('l1', 'v1')],
        odoReadings: [_odo('o1', 'v1')],
        notes: [
          _note('n1', vehicleId: 'v1'),
          _note('n2'),
        ],
        settings: const Settings(selectedVehicleId: 'v1'),
      );
      final result = applyVehicleDeletion(data, 'v1');

      expect(result.vehicles, isEmpty);
      expect(result.settings.selectedVehicleId, isNull);
      // vehicle-less note still survives even with zero vehicles left
      expect(result.notes.map((n) => n.id).toSet(), {'n2'});
    });

    test('an unknown id returns a document equal to the input', () {
      final data = _twoVehicleData(selectedVehicleId: 'v1');
      final result = applyVehicleDeletion(data, 'does-not-exist');

      expect(result, same(data));
    });
  });
}
