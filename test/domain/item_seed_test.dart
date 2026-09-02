// test/domain/item_seed_test.dart — Phase 6 (SET-01, T-06-06-02). Pure
// `package:test`, no Flutter import (D-31/D-32) — proves
// `seedMaintenanceItem`'s baseline is real: an item enabled from the
// item-management screen with no prior onboarding selection must get a
// genuine baseline on both axes, or `computeDue` would return null for it
// forever (see lib/domain/item_seed.dart's header for the full argument).
//
// Local-clock `DateTime(...)` fixtures throughout, never `DateTime.utc(...)`
// — the standing UTC-fixture fragility note carried forward from Phase 4
// (STATE.md) applies to every new test file, not only the one it originally
// flagged.
import 'package:motonote/domain/catalog.dart';
import 'package:motonote/domain/item_seed.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:test/test.dart';

void main() {
  // A fixture entry deliberately distinct from every real kCatalog interval
  // pair, so a passing "intervals come from the entry" test proves the
  // function reads the entry's own fields rather than a hardcoded pair.
  const entry = CatalogEntry(
    code: 'fixture_code',
    nameVi: 'Fixture Item',
    appliesTo: {VehicleType.scooter},
    intervalKm: 4321,
    intervalMonths: 7,
    iconKey: 'water_drop',
  );

  Vehicle buildVehicle({int currentOdoKm = 12345}) => Vehicle(
    id: 'vehicle-1',
    name: 'Test Vehicle',
    type: VehicleType.scooter,
    currentOdoKm: currentOdoKm,
    odoUpdatedAt: DateTime(2026, 1, 1),
    avgDailyKm: 20,
    createdAt: DateTime(2026, 1, 1),
  );

  test('seeds every field against the fixture entry and vehicle', () {
    final now = DateTime(2026, 9, 2, 8, 30);
    final vehicle = buildVehicle();
    final item = seedMaintenanceItem(entry, vehicle, now: now);

    expect(item.vehicleId, vehicle.id);
    expect(item.catalogCode, entry.code);
    expect(item.name, entry.nameVi);
    expect(item.enabled, isTrue);
    expect(item.lastServiceDate, now);
    expect(item.lastServiceOdo, vehicle.currentOdoKm);
    expect(item.baselineIsGuess, isTrue);
    expect(item.oilGrade, isNull);
    expect(item.partBrand, isNull);
    expect(item.partSpec, isNull);
    expect(item.lastCostVnd, isNull);
    expect(item.notes, isNull);
  });

  test('intervals come from the entry, not a hardcoded pair', () {
    final vehicle = buildVehicle();
    final item = seedMaintenanceItem(entry, vehicle, now: DateTime(2026, 1, 1));

    expect(item.intervalKm, 4321);
    expect(item.intervalMonths, 7);
  });

  test('baselineIsGuess is always true', () {
    final vehicle = buildVehicle();
    final item = seedMaintenanceItem(entry, vehicle, now: DateTime(2026, 1, 1));
    expect(item.baselineIsGuess, isTrue);
  });

  test('two calls produce different ids', () {
    final vehicle = buildVehicle();
    final a = seedMaintenanceItem(entry, vehicle, now: DateTime(2026, 1, 1));
    final b = seedMaintenanceItem(entry, vehicle, now: DateTime(2026, 1, 1));
    expect(a.id, isNot(equals(b.id)));
  });

  test('a vehicle with odometer 0 seeds lastServiceOdo: 0, not null', () {
    final vehicle = buildVehicle(currentOdoKm: 0);
    final item = seedMaintenanceItem(entry, vehicle, now: DateTime(2026, 1, 1));
    expect(item.lastServiceOdo, 0);
    expect(item.lastServiceOdo, isNotNull);
  });

  test('omitting now falls back to the current UTC instant', () {
    final vehicle = buildVehicle();
    final before = DateTime.now().toUtc();
    final item = seedMaintenanceItem(entry, vehicle);
    final after = DateTime.now().toUtc();
    expect(
      item.lastServiceDate!.isAfter(
        before.subtract(const Duration(seconds: 5)),
      ),
      isTrue,
    );
    expect(
      item.lastServiceDate!.isBefore(after.add(const Duration(seconds: 5))),
      isTrue,
    );
  });
}
