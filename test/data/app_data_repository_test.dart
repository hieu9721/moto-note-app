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
}
