// Tests for AppDataRepository — the atomic-write, backup-fallback data layer
// (§5.1, P1-D-11). Runs under plain `dart test`, no Flutter engine, against a
// real temp directory — no mocks, because the Directory is constructor-injected.
//
// Groups are kept separate ('round-trip', 'missing file', 'backup fallback',
// 'migration') so plans 01-03 and 01-04 can append their own groups without
// touching these.

import 'dart:convert';
import 'dart:io';

import 'package:motonote/data/app_data_repository.dart';
import 'package:motonote/data/migrations.dart';
import 'package:motonote/domain/id.dart';
import 'package:motonote/domain/models/app_data.dart';
import 'package:motonote/domain/models/maintenance_item.dart';
import 'package:motonote/domain/models/misc.dart';
import 'package:motonote/domain/models/service_log.dart';
import 'package:motonote/domain/models/vehicle.dart';
import 'package:test/test.dart';

/// Asserts every key path present in [fixtureValue] is also present in
/// [reEncodedValue] with an equal value — a superset check, not equality.
/// A future version may legitimately ADD keys to the re-encode (D-21); this
/// never removes or renames one, and that is the failure this helper exists
/// to catch (P1-D-12). Kept as a small test-local helper rather than a new
/// production utility (§12 forbids a `utils/` directory of small files).
void assertNoFieldLost(
  dynamic fixtureValue,
  dynamic reEncodedValue,
  String path,
) {
  if (fixtureValue is Map) {
    expect(reEncodedValue, isA<Map>(), reason: 'expected a map at $path');
    final reEncodedMap = reEncodedValue as Map;
    for (final key in fixtureValue.keys) {
      expect(
        reEncodedMap.containsKey(key),
        isTrue,
        reason:
            'key "$key" from the fixture is missing at $path — a field '
            'was renamed or deleted',
      );
      assertNoFieldLost(fixtureValue[key], reEncodedMap[key], '$path.$key');
    }
  } else if (fixtureValue is List) {
    expect(reEncodedValue, isA<List>(), reason: 'expected a list at $path');
    final reEncodedList = reEncodedValue as List;
    expect(
      reEncodedList.length,
      equals(fixtureValue.length),
      reason: 'list length changed at $path',
    );
    for (var i = 0; i < fixtureValue.length; i++) {
      assertNoFieldLost(fixtureValue[i], reEncodedList[i], '$path[$i]');
    }
  } else {
    expect(
      reEncodedValue,
      equals(fixtureValue),
      reason: 'value changed at $path',
    );
  }
}

void main() {
  late Directory tempDir;
  late AppDataRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('motonote_test_');
    repo = AppDataRepository(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('round-trip', () {
    test('a document with one Note and non-default Settings round-trips through save/load', () async {
      final note = Note(
        id: newId(),
        title: 'Thay nhớt',
        body: 'Đã thay nhớt Motul 5100 10W-40',
        pinned: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final original = AppData.empty().copyWith(
        notes: [note],
        settings: const Settings(leadDays: 14, notifyHour: 20),
      );

      await repo.save(original);
      final loaded = await repo.load();

      expect(loaded, equals(original));
    });

    test('notes list [A, B] round-trips in the same order', () async {
      final noteA = Note(
        id: 'a',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final noteB = Note(
        id: 'b',
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      );
      final original = AppData.empty().copyWith(notes: [noteA, noteB]);

      await repo.save(original);
      final loaded = await repo.load();

      expect(loaded!.notes.map((n) => n.id).toList(), equals(['a', 'b']));
    });
  });

  group('missing file', () {
    test('load() against an empty directory reports the no-data outcome, not a crash', () async {
      final loaded = await repo.load();
      expect(loaded, isNull);
    });
  });

  group('backup fallback', () {
    test(
      'a corrupt primary falls back to the content of the FIRST of two saves',
      () async {
        final first = AppData.empty().copyWith(deviceLabel: 'first-save');
        final second = AppData.empty().copyWith(deviceLabel: 'second-save');

        await repo.save(first);
        await repo.save(second);

        final primary = File('${tempDir.path}/appdata.json');
        await primary.writeAsString('not json');

        final loaded = await repo.load();

        expect(loaded, isNotNull);
        expect(loaded!.deviceLabel, equals('first-save'));
      },
    );
  });

  group('migration', () {
    test(
      'migrateRaw stamps schemaVersion to 1 when no version key is present',
      () {
        final result = migrateRaw({'foo': 'bar'});
        expect(result['schemaVersion'], equals(1));
      },
    );

    test('a minimal map with only updatedAt and settings decodes tolerantly — '
        'every @Default([]) list arrives empty, never null', () {
      final raw = <String, dynamic>{
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        'settings': <String, dynamic>{},
      };

      final migrated = migrateRaw(raw);
      final data = AppData.fromJson(migrated);

      expect(data.odoReadings, isEmpty);
      expect(data.notes, isEmpty);
      expect(data.deviceLabel, equals(''));
      expect(data.schemaVersion, equals(1));
    });
  });

  group('§4.2 models — Vehicle, MaintenanceItem, ServiceLog(Entry)', () {
    test('Vehicle round-trips through its own toJson/fromJson unchanged', () {
      final vehicle = Vehicle(
        id: newId(),
        name: 'Winner X',
        type: VehicleType.manual,
        plate: '29H1-12345',
        brand: 'Honda',
        model: 'Winner X',
        year: 2022,
        photoPath: 'receipts/vehicle_photo.jpg',
        currentOdoKm: 12345,
        odoUpdatedAt: DateTime(2026, 1, 1),
        avgDailyKm: 22.5,
        avgDailyKmSource: AvgKmSource.computed,
        createdAt: DateTime(2025, 1, 1),
      );

      final roundTripped = Vehicle.fromJson(vehicle.toJson());

      expect(roundTripped, equals(vehicle));
    });

    test('a Vehicle JSON map omitting avgDailyKmSource decodes with the value '
        'user (the @Default), not null', () {
      final json = <String, dynamic>{
        'id': newId(),
        'name': 'Wave Alpha',
        'type': 'underbone',
        'currentOdoKm': 1000,
        'odoUpdatedAt': DateTime(2026, 1, 1).toIso8601String(),
        'avgDailyKm': 10.0,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.avgDailyKmSource, equals(AvgKmSource.user));
    });

    test(
      'MaintenanceItem round-trips through its own toJson/fromJson unchanged',
      () {
        final item = MaintenanceItem(
          id: newId(),
          vehicleId: newId(),
          catalogCode: 'engine_oil',
          name: 'Thay nhớt',
          intervalKm: 3000,
          intervalMonths: 6,
          enabled: false,
          lastServiceOdo: 9000,
          lastServiceDate: DateTime(2026, 1, 1),
          baselineIsGuess: false,
          partBrand: 'Motul',
          partSpec: '5100 10W-40',
          oilGrade: OilGrade.semiSynthetic,
          lastCostVnd: 250000,
          notes: 'Ghi chú',
        );

        final roundTripped = MaintenanceItem.fromJson(item.toJson());

        expect(roundTripped, equals(item));
      },
    );

    test('a MaintenanceItem JSON map omitting enabled and baselineIsGuess '
        'decodes with both true', () {
      final json = <String, dynamic>{
        'id': newId(),
        'vehicleId': newId(),
        'catalogCode': 'engine_oil',
        'name': 'Thay nhớt',
      };

      final item = MaintenanceItem.fromJson(json);

      expect(item.enabled, isTrue);
      expect(item.baselineIsGuess, isTrue);
    });

    test(
      'ServiceLogEntry round-trips through its own toJson/fromJson unchanged',
      () {
        final entry = ServiceLogEntry(
          itemId: newId(),
          costVnd: 150000,
          partBrand: 'Motul',
          partSpec: '5100 10W-40',
          resetsCycle: false,
        );

        final roundTripped = ServiceLogEntry.fromJson(entry.toJson());

        expect(roundTripped, equals(entry));
      },
    );

    test(
      'a ServiceLogEntry JSON map omitting resetsCycle decodes with it true',
      () {
        final json = <String, dynamic>{'itemId': newId()};

        final entry = ServiceLogEntry.fromJson(json);

        expect(entry.resetsCycle, isTrue);
      },
    );

    test(
      'ServiceLog round-trips through its own toJson/fromJson unchanged',
      () {
        final log = ServiceLog(
          id: newId(),
          vehicleId: newId(),
          date: DateTime(2026, 1, 1),
          odoKm: 12000,
          shopName: 'Tiệm Anh Ba',
          totalCostVnd: 300000,
          note: 'Thay nhớt + lọc gió',
          photoPaths: ['receipts/log1.jpg'],
          entries: [ServiceLogEntry(itemId: newId(), resetsCycle: true)],
        );

        // ServiceLog nests ServiceLogEntry objects in `entries`. toJson() does
        // not call ServiceLogEntry.toJson() on each item without
        // `explicitToJson: true` — Dart's jsonEncode() does that recursively
        // via its default toEncodable, which is the real save()/load() path
        // (§5.1). Route through the same jsonEncode/jsonDecode cycle here so
        // the test matches production, rather than calling fromJson(toJson())
        // directly with unencoded nested objects.
        final roundTripped = ServiceLog.fromJson(
          jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>,
        );

        expect(roundTripped, equals(log));
      },
    );

    test('a ServiceLog JSON map omitting photoPaths and entries decodes with '
        'both as empty lists', () {
      final json = <String, dynamic>{
        'id': newId(),
        'vehicleId': newId(),
        'date': DateTime(2026, 1, 1).toIso8601String(),
        'odoKm': 5000,
      };

      final log = ServiceLog.fromJson(json);

      expect(log.photoPaths, isEmpty);
      expect(log.entries, isEmpty);
    });

    test('AppData.fromJson accepts a map whose vehicles, items and logs keys '
        'are absent and yields empty lists for all three', () {
      final raw = <String, dynamic>{
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        'settings': <String, dynamic>{},
      };

      final data = AppData.fromJson(migrateRaw(raw));

      expect(data.vehicles, isEmpty);
      expect(data.items, isEmpty);
      expect(data.logs, isEmpty);
    });
  });

  group('P1-D-12 fixture — no field lost', () {
    // Loaded once per test (not setUpAll) — keeps each test independent and
    // the failure message local to the assertion that trips.
    Map<String, dynamic> readFixture() {
      final raw = File('test/fixtures/appdata_v1.json').readAsStringSync();
      return jsonDecode(raw) as Map<String, dynamic>;
    }

    test('the committed appdata_v1.json fixture is already stamped schemaVersion 1, '
        'and migrateRaw returns it stamped 1', () {
      final fixture = readFixture();
      final migrated = migrateRaw(fixture);

      expect(fixture['schemaVersion'], equals(1));
      expect(migrated['schemaVersion'], equals(1));
    });

    test('the fixture round-trips through migrateRaw and AppData.fromJson with '
        'a representative scalar from every model reading back at its fixture '
        'value, including at least one nullable field per model', () {
      final fixture = readFixture();
      final data = AppData.fromJson(migrateRaw(fixture));

      // AppData
      expect(data.deviceLabel, equals('Redmi Note 12'));

      // Vehicle — plate is nullable
      expect(data.vehicles, hasLength(1));
      expect(data.vehicles.first.plate, equals('29H1-12345'));
      expect(
        data.vehicles.first.avgDailyKmSource,
        equals(AvgKmSource.computed),
      );

      // MaintenanceItem — oilGrade is nullable
      expect(data.items, hasLength(2));
      expect(data.items.first.oilGrade, equals(OilGrade.semiSynthetic));
      expect(data.items.first.baselineIsGuess, isFalse);
      expect(data.items.last.intervalMonths, isNull);

      // ServiceLog — shopName is nullable
      expect(data.logs, hasLength(1));
      expect(data.logs.first.shopName, equals('Tiệm Anh Ba'));

      // ServiceLogEntry — partSpec is nullable
      expect(data.logs.first.entries, hasLength(2));
      expect(data.logs.first.entries.last.partSpec, equals('OEM'));
      expect(data.logs.first.entries.last.resetsCycle, isFalse);

      // OdoReading — two different OdoSource values
      expect(data.odoReadings, hasLength(2));
      expect(data.odoReadings.first.source, equals(OdoSource.service));
      expect(data.odoReadings.last.source, equals(OdoSource.manual));

      // Note — title is nullable, one pinned
      expect(data.notes, hasLength(2));
      expect(data.notes.first.title, equals('Ghi chú bảo dưỡng'));
      expect(data.notes.first.pinned, isTrue);
      expect(data.notes.last.vehicleId, isNull);

      // Settings — lastBackupError is nullable
      expect(data.settings.leadDays, equals(14));
      expect(data.settings.lastBackupError, equals('Network timeout'));
    });

    test('the re-encode is a superset of the fixture — no key present in the '
        'fixture is absent or renamed in the re-encode, and no fixture value '
        'changed', () {
      final fixture = readFixture();
      final data = AppData.fromJson(migrateRaw(fixture));

      // Route through jsonEncode/jsonDecode (not data.toJson() directly) —
      // this is the real save() path (§5.1), and it's what normalizes
      // nested Freezed model instances (vehicles, items, logs, entries,
      // odoReadings, notes) into plain Maps for comparison.
      final reEncoded =
          jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>;

      assertNoFieldLost(fixture, reEncoded, 'appdata_v1.json');
    });

    test('the fixture loads through the full repository path — written to a '
        'temp directory as appdata.json and read back by load()', () async {
      final fixtureBytes = File('test/fixtures/appdata_v1.json')
          .readAsStringSync();

      final tempDir = await Directory.systemTemp.createTemp(
        'motonote_fixture_test_',
      );
      try {
        final repo = AppDataRepository(tempDir);
        await File('${tempDir.path}/appdata.json').writeAsString(fixtureBytes);

        final loaded = await repo.load();

        expect(loaded, isNotNull);
        expect(loaded!.deviceLabel, equals('Redmi Note 12'));
        expect(loaded.vehicles, hasLength(1));
        expect(loaded.items, hasLength(2));
        expect(loaded.logs, hasLength(1));
        expect(loaded.odoReadings, hasLength(2));
        expect(loaded.notes, hasLength(2));
        expect(loaded.schemaVersion, equals(1));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
