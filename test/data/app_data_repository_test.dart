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
import 'package:motonote/data/serial_queue.dart';
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

/// DATA-09 fixed reference points — a real Vietnamese shop name / part spec
/// / note body per §4.2 example, cycled by index. No `Random`, no
/// `DateTime.now()`, no `newId()` anywhere in this factory: the whole point
/// of the size-budget assertion is that it never drifts between runs.
const _shopNames = [
  'Tiệm Anh Ba',
  'Cửa hàng Sửa xe Minh Phát',
  'Gara Thành Đạt',
  'Tiệm Sửa xe Hoàng Long',
  'Trung tâm Bảo dưỡng Yamaha Town',
];

const _partBrands = ['Motul', 'Castrol', 'Shell', 'Honda Genuine', 'Yamalube'];

const _partSpecs = [
  '5100 10W-40',
  '3000 10W-30',
  'X-Ride 15W-40',
  'BP 8000 5W-30',
  'Yamalube 4T 10W-40',
];

const _noteBodies = [
  'Đã thay nhớt và lọc gió, xe chạy êm hơn hẳn.',
  'Kiểm tra lốp trước, còn khoảng 40% gai, để ý thêm 2000km nữa.',
  'Nhắc thay bugi vào lần bảo dưỡng tới, hiện tại đề hơi khó nổ.',
  'Đã đăng kiểm xe, hẹn tái khám sau 2 năm.',
  'Sên dĩa hơi chùng, cần đi chỉnh trong tuần này.',
];

const _itemCatalogCodes = [
  'engine_oil',
  'air_filter',
  'spark_plug',
  'brake_pad_front',
  'brake_pad_rear',
  'chain_sprocket',
  'coolant',
  'brake_fluid',
  'battery',
  'tire_front',
  'tire_rear',
  'oil_filter',
  'drive_belt',
  'valve_clearance',
  'fuel_filter',
];

const _itemNames = [
  'Thay nhớt máy',
  'Vệ sinh lọc gió',
  'Thay bugi',
  'Má phanh trước',
  'Má phanh sau',
  'Nhông sên dĩa',
  'Nước làm mát',
  'Dầu phanh',
  'Ắc quy',
  'Lốp trước',
  'Lốp sau',
  'Lọc nhớt',
  'Dây curoa (xe ga)',
  'Khe hở xu-páp',
  'Lọc xăng',
];

/// DATA-09 synthetic worst case: 1 vehicle, 15 maintenance items, 300
/// service logs (each with 2 entries) and 300 odo readings — built entirely
/// from the loop index and a fixed epoch, so the byte count this produces
/// is deterministic across runs (no `Random`, no `DateTime.now`, no
/// `newId`).
AppData buildSyntheticAppData() {
  final epoch = DateTime.utc(2026, 1, 1);
  const vehicleId = 'vehicle-0';

  final vehicle = Vehicle(
    id: vehicleId,
    name: 'Winner X',
    type: VehicleType.manual,
    plate: '29H1-12345',
    brand: 'Honda',
    model: 'Winner X',
    year: 2022,
    photoPath: 'receipts/vehicle_photo.jpg',
    currentOdoKm: 18000,
    odoUpdatedAt: epoch,
    avgDailyKm: 24.5,
    avgDailyKmSource: AvgKmSource.computed,
    createdAt: epoch,
  );

  final items = List.generate(15, (i) {
    return MaintenanceItem(
      id: 'item-$i',
      vehicleId: vehicleId,
      catalogCode: _itemCatalogCodes[i],
      name: _itemNames[i],
      intervalKm: 3000 + i * 500,
      intervalMonths: i.isEven ? 6 : null,
      lastServiceOdo: 15000 + i * 100,
      lastServiceDate: epoch.add(Duration(days: i * 10)),
      baselineIsGuess: i.isOdd,
      partBrand: _partBrands[i % _partBrands.length],
      partSpec: _partSpecs[i % _partSpecs.length],
      oilGrade: i % 3 == 0 ? OilGrade.semiSynthetic : null,
      lastCostVnd: 100000 + i * 15000,
      notes: 'Ghi chú cho hạng mục bảo dưỡng số $i, theo dõi thêm lần sau.',
    );
  });

  final logs = List.generate(300, (i) {
    final entries = List.generate(2, (j) {
      final idx = i * 2 + j;
      return ServiceLogEntry(
        itemId: 'item-${idx % 15}',
        costVnd: 50000 + idx * 1000,
        partBrand: _partBrands[idx % _partBrands.length],
        partSpec: _partSpecs[idx % _partSpecs.length],
        resetsCycle: idx.isEven,
      );
    });
    return ServiceLog(
      id: 'log-$i',
      vehicleId: vehicleId,
      date: epoch.add(Duration(days: i)),
      odoKm: 5000 + i * 40,
      shopName: _shopNames[i % _shopNames.length],
      totalCostVnd: 200000 + i * 3000,
      note: _noteBodies[i % _noteBodies.length],
      photoPaths: ['receipts/log_$i.jpg'],
      entries: entries,
    );
  });

  final odoReadings = List.generate(300, (i) {
    return OdoReading(
      id: 'odo-$i',
      vehicleId: vehicleId,
      odoKm: 4000 + i * 45,
      date: epoch.add(Duration(days: i)),
      source: i.isEven ? OdoSource.manual : OdoSource.service,
    );
  });

  final notes = List.generate(5, (i) {
    return Note(
      id: 'note-$i',
      vehicleId: vehicleId,
      itemId: i.isEven ? 'item-$i' : null,
      title: 'Ghi chú số $i',
      body: _noteBodies[i % _noteBodies.length],
      pinned: i == 0,
      createdAt: epoch.add(Duration(days: i)),
      updatedAt: epoch.add(Duration(days: i)),
    );
  });

  final settings = Settings(
    notificationsEnabled: true,
    odoReminderEnabled: true,
    odoReminderDayOfMonth: 5,
    notifyHour: 20,
    leadDays: 14,
    driveBackupEnabled: true,
    lastBackupAt: epoch,
    googleEmail: 'nguoi.dung.demo@gmail.com',
    lastNotificationFiredAt: epoch,
  );

  return AppData(
    updatedAt: epoch,
    deviceLabel: 'Redmi Note 12',
    vehicles: [vehicle],
    items: items,
    logs: logs,
    odoReadings: odoReadings,
    notes: notes,
    settings: settings,
  );
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
      final result = await repo.load();

      expect(result, isA<AppDataLoaded>());
      expect((result as AppDataLoaded).data, equals(original));
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
      final result = await repo.load();

      final loaded = (result as AppDataLoaded).data;
      expect(loaded.notes.map((n) => n.id).toList(), equals(['a', 'b']));
    });
  });

  group('missing file', () {
    test('load() against an empty directory reports the no-data outcome, not a crash', () async {
      final result = await repo.load();
      expect(result, isA<AppDataNotFound>());
    });

    test(
      'load() against an empty directory writes nothing and renames nothing',
      () async {
        await repo.load();

        final entries = await tempDir.list().toList();
        expect(entries, isEmpty);
      },
    );
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

        final result = await repo.load();

        expect(result, isA<AppDataLoaded>());
        expect(
          (result as AppDataLoaded).data.deviceLabel,
          equals('first-save'),
        );
      },
    );
  });

  group('save', () {
    test('saving the same document twice leaves appdata.json byte-identical, '
        'and appdata.backup.json then holds an identical copy', () async {
      final document = AppData.empty().copyWith(deviceLabel: 'same-twice');

      await repo.save(document);
      final primary = File('${tempDir.path}/appdata.json');
      final firstBytes = await primary.readAsBytes();

      await repo.save(document);
      final secondBytes = await primary.readAsBytes();
      final backup = File('${tempDir.path}/appdata.backup.json');
      final backupBytes = await backup.readAsBytes();

      expect(secondBytes, equals(firstBytes));
      expect(backupBytes, equals(firstBytes));
    });

    test('saving two different documents leaves appdata.json holding the '
        'second and appdata.backup.json holding the first, with no '
        'appdata.json.tmp left behind', () async {
      final first = AppData.empty().copyWith(deviceLabel: 'first-save');
      final second = AppData.empty().copyWith(deviceLabel: 'second-save');

      await repo.save(first);
      await repo.save(second);

      final primary = File('${tempDir.path}/appdata.json');
      final backup = File('${tempDir.path}/appdata.backup.json');
      final tmp = File('${tempDir.path}/appdata.json.tmp');

      final primaryData = AppData.fromJson(
        jsonDecode(await primary.readAsString()) as Map<String, dynamic>,
      );
      final backupData = AppData.fromJson(
        jsonDecode(await backup.readAsString()) as Map<String, dynamic>,
      );

      expect(primaryData.deviceLabel, equals('second-save'));
      expect(backupData.deviceLabel, equals('first-save'));
      expect(await tmp.exists(), isFalse);
    });

    test(
      'ten save() calls issued in a tight loop without awaiting each one '
      'leave an appdata.json that decodes successfully once all complete',
      () async {
        final futures = <Future<void>>[];
        for (var i = 0; i < 10; i++) {
          futures.add(
            repo.save(AppData.empty().copyWith(deviceLabel: 'write-$i')),
          );
        }
        await Future.wait(futures);

        final primary = File('${tempDir.path}/appdata.json');
        final decoded =
            jsonDecode(await primary.readAsString()) as Map<String, dynamic>;
        final data = AppData.fromJson(decoded);

        expect(data.deviceLabel, equals('write-9'));

        final tmp = File('${tempDir.path}/appdata.json.tmp');
        expect(await tmp.exists(), isFalse);
      },
    );
  });

  group('quarantine', () {
    test(
      'primary undecodable with a healthy backup: load() returns the loaded '
      'outcome carrying the backup document, and the primary is renamed to '
      'a quarantine file starting appdata.corrupt. and ending .json',
      () async {
        final first = AppData.empty().copyWith(deviceLabel: 'first-save');
        final second = AppData.empty().copyWith(deviceLabel: 'second-save');

        await repo.save(first);
        await repo.save(second);

        final primary = File('${tempDir.path}/appdata.json');
        await primary.writeAsString('not json');

        final result = await repo.load();

        expect(result, isA<AppDataLoaded>());
        expect(
          (result as AppDataLoaded).data.deviceLabel,
          equals('first-save'),
        );

        expect(await primary.exists(), isFalse);
        final quarantineFiles = await tempDir
            .list()
            .where(
              (e) =>
                  e is File &&
                  e.uri.pathSegments.last.startsWith('appdata.corrupt.') &&
                  e.uri.pathSegments.last.endsWith('.json'),
            )
            .toList();
        expect(quarantineFiles, hasLength(1));
      },
    );

    test('primary undecodable with no backup: load() returns the undecodable '
        'outcome, no appdata.json remains, and the quarantine file holds the '
        'original bytes byte-for-byte', () async {
      final primary = File('${tempDir.path}/appdata.json');
      const originalBytes = 'not json at all, {"truncated": tr';
      await primary.writeAsString(originalBytes);

      final result = await repo.load();

      expect(result, isA<AppDataUndecodable>());
      final quarantinePath = (result as AppDataUndecodable).quarantinePath;

      expect(await primary.exists(), isFalse);
      final quarantineFile = File(quarantinePath);
      expect(await quarantineFile.exists(), isTrue);
      expect(await quarantineFile.readAsString(), equals(originalBytes));

      final remainingAppdataJson = await tempDir
          .list()
          .where((e) => e.uri.pathSegments.last == 'appdata.json')
          .toList();
      expect(remainingAppdataJson, isEmpty);
    });

    test('two successive corrupt loads produce two distinct quarantine files; '
        'neither overwrites the other', () async {
      final primary = File('${tempDir.path}/appdata.json');

      await primary.writeAsString('not json (first)');
      final firstResult = await repo.load() as AppDataUndecodable;

      await primary.writeAsString('not json (second)');
      final secondResult = await repo.load() as AppDataUndecodable;

      expect(
        firstResult.quarantinePath,
        isNot(equals(secondResult.quarantinePath)),
      );
      expect(
        await File(firstResult.quarantinePath).readAsString(),
        equals('not json (first)'),
      );
      expect(
        await File(secondResult.quarantinePath).readAsString(),
        equals('not json (second)'),
      );
    });
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

    test('migrateRaw on a map whose schemaVersion is 2 throws the typed '
        'forward-version error and does not mutate the input map', () {
      final input = <String, dynamic>{'schemaVersion': 2, 'foo': 'bar'};
      final inputSnapshot = Map<String, dynamic>.from(input);

      expect(
        () => migrateRaw(input),
        throwsA(
          isA<SchemaTooNewException>()
              .having((e) => e.found, 'found', 2)
              .having((e) => e.supported, 'supported', 1),
        ),
      );
      expect(input, equals(inputSnapshot));
    });

    test('load() against a primary stamped schemaVersion 2 reports the '
        'forward-version outcome, quarantines the file, and does NOT fall '
        'through to a fresh empty document', () async {
      final primary = File('${tempDir.path}/appdata.json');
      await primary.writeAsString(
        jsonEncode({
          'schemaVersion': 2,
          'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
          'settings': <String, dynamic>{},
        }),
      );

      final result = await repo.load();

      expect(result, isA<AppDataSchemaTooNew>());
      final schemaTooNew = result as AppDataSchemaTooNew;
      expect(schemaTooNew.found, equals(2));
      expect(schemaTooNew.supported, equals(1));

      expect(await primary.exists(), isFalse);
      final quarantineFile = File(schemaTooNew.quarantinePath);
      expect(await quarantineFile.exists(), isTrue);
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

        final result = await repo.load();

        expect(result, isA<AppDataLoaded>());
        final loaded = (result as AppDataLoaded).data;
        expect(loaded.deviceLabel, equals('Redmi Note 12'));
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

  group('size budget', () {
    test('a synthetic document of 1 vehicle, 15 maintenance items and 300 '
        'service logs encodes to strictly fewer than 204800 bytes', () {
      final data = buildSyntheticAppData();
      final bytes = utf8.encode(jsonEncode(data.toJson()));

      // DATA-09: the plan requires the measured byte count recorded in
      // the SUMMARY — printed here so it can be captured from test output.
      // ignore: avoid_print
      print('DATA-09 synthetic document size: ${bytes.length} bytes');

      expect(bytes.length, lessThan(204800));
    });

    test('the synthetic document produces exactly the same byte count on a '
        'second construction — no random source, no wall-clock timestamp', () {
      final firstSize = utf8
          .encode(jsonEncode(buildSyntheticAppData().toJson()))
          .length;
      final secondSize = utf8
          .encode(jsonEncode(buildSyntheticAppData().toJson()))
          .length;

      expect(secondSize, equals(firstSize));
    });

    test('an empty document encodes to under one kilobyte', () {
      final empty = AppData(
        updatedAt: DateTime.utc(2026, 1, 1),
        settings: const Settings(),
      );
      final bytes = utf8.encode(jsonEncode(empty.toJson()));

      expect(bytes.length, lessThan(1024));
    });
  });

  group('serial queue ordering (DATA-03, G-01-5)', () {
    test(
      'two enqueues issued without awaiting the first apply in issue order',
      () async {
        final queue = SerialQueue();
        final order = <String>[];

        final firstFuture = queue.enqueue(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          order.add('first');
        });
        final secondFuture = queue.enqueue(() async {
          order.add('second');
        });

        await Future.wait([firstFuture, secondFuture]);

        expect(order, equals(['first', 'second']));
      },
    );

    test("the second task observes the first task's committed result — "
        'neither change is lost (DATA-03)', () async {
      final queue = SerialQueue();
      var value = 'v0';

      final firstFuture = queue.enqueue(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        value = '$value+a';
      });
      final secondFuture = queue.enqueue(() async {
        value = '$value+b';
      });

      await Future.wait([firstFuture, secondFuture]);

      expect(value, equals('v0+a+b'));
    });

    test(
      'the future returned to the caller still rejects on its own failure',
      () async {
        final queue = SerialQueue();

        final future = queue.enqueue(() async {
          throw StateError('boom');
        });

        await expectLater(future, throwsA(isA<StateError>()));
      },
    );

    test('a failing task does not poison the chain — the next task still '
        'completes normally', () async {
      final queue = SerialQueue();

      final failingFuture = queue.enqueue(() async {
        throw StateError('boom');
      });
      final failureExpectation = expectLater(
        failingFuture,
        throwsA(isA<StateError>()),
      );

      var flagSet = false;
      final secondFuture = queue.enqueue(() async {
        flagSet = true;
      });

      await secondFuture;
      await failureExpectation;

      expect(flagSet, isTrue);
    });

    test('ten enqueues issued in a tight loop without awaiting each one run in '
        'strict issue order', () async {
      final queue = SerialQueue();
      final order = <int>[];

      final futures = <Future<void>>[];
      for (var i = 0; i < 10; i++) {
        final delayMs = 10 - i;
        futures.add(
          queue.enqueue(() async {
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            order.add(i);
          }),
        );
      }
      await Future.wait(futures);

      expect(order, equals(List<int>.generate(10, (i) => i)));
    });
  });

  group('post-persist failure boundary (G-01-W3)', () {
    test('an effect that throws ASYNCHRONOUSLY (after an await) is reported, '
        'not propagated', () async {
      Object? capturedError;

      await runReportingFailure(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        throw StateError('async boom');
      }, onError: (error) => capturedError = error);

      expect(capturedError, isA<StateError>());
    });

    test('an effect that throws SYNCHRONOUSLY, before its first await, is also '
        'reported, not propagated', () async {
      Object? capturedError;

      await runReportingFailure(() async {
        throw StateError('sync boom');
      }, onError: (error) => capturedError = error);

      expect(capturedError, isA<StateError>());
    });

    test('an effect that succeeds completes normally and the error callback is '
        'never invoked', () async {
      var effectRan = false;
      Object? capturedError;

      await runReportingFailure(() async {
        effectRan = true;
      }, onError: (error) => capturedError = error);

      expect(effectRan, isTrue);
      expect(capturedError, isNull);
    });
  });

  group('updatedAt is UTC (G-01-W5)', () {
    test('AppData.empty() stamps updatedAt as a UTC instant', () {
      final data = AppData.empty();

      expect(data.updatedAt.isUtc, isTrue);
    });

    test('the persisted updatedAt string ends with Z — the bytes Phase 5 will '
        'compare', () async {
      await repo.save(AppData.empty());

      final primary = File('${tempDir.path}/appdata.json');
      final decoded =
          jsonDecode(await primary.readAsString()) as Map<String, dynamic>;

      expect(decoded['updatedAt'], endsWith('Z'));
    });

    test('a document round-tripped through save() and load() comes back with '
        'updatedAt.isUtc true', () async {
      await repo.save(AppData.empty());

      final result = await repo.load();

      expect(result, isA<AppDataLoaded>());
      expect((result as AppDataLoaded).data.updatedAt.isUtc, isTrue);
    });
  });

  group('pre-restore snapshot', () {
    test(
      'writePreRestoreSnapshot creates appdata.pre-restore.json and leaves '
      'appdata.json/appdata.backup.json byte-identical',
      () async {
        final first = AppData.empty().copyWith(deviceLabel: 'first-save');
        final second = AppData.empty().copyWith(deviceLabel: 'second-save');
        await repo.save(first);
        await repo.save(second);

        final primary = File('${tempDir.path}/appdata.json');
        final backup = File('${tempDir.path}/appdata.backup.json');
        final primaryBefore = await primary.readAsBytes();
        final backupBefore = await backup.readAsBytes();

        await repo.writePreRestoreSnapshot(
          AppData.empty().copyWith(deviceLabel: 'snapshot'),
        );

        final snapshot = File('${tempDir.path}/appdata.pre-restore.json');
        expect(await snapshot.exists(), isTrue);
        expect(await primary.readAsBytes(), equals(primaryBefore));
        expect(await backup.readAsBytes(), equals(backupBefore));
      },
    );

    test(
      'writePreRestoreSnapshot leaves no appdata.pre-restore.json.tmp behind',
      () async {
        await repo.writePreRestoreSnapshot(AppData.empty());

        final tmp = File('${tempDir.path}/appdata.pre-restore.json.tmp');
        expect(await tmp.exists(), isFalse);
      },
    );

    test(
      'a second snapshot write replaces the first content and moves the '
      "file's modification time forward (P5-D-07)",
      () async {
        await repo.writePreRestoreSnapshot(
          AppData.empty().copyWith(deviceLabel: 'first-snapshot'),
        );
        final firstMtime = await repo.preRestoreSnapshotModifiedAt();

        await Future<void>.delayed(const Duration(milliseconds: 1100));
        await repo.writePreRestoreSnapshot(
          AppData.empty().copyWith(deviceLabel: 'second-snapshot'),
        );
        final secondMtime = await repo.preRestoreSnapshotModifiedAt();

        final loaded = await repo.readPreRestoreSnapshot();
        expect(loaded!.deviceLabel, equals('second-snapshot'));
        expect(secondMtime!.isAfter(firstMtime!), isTrue);
      },
    );

    test(
      'preRestoreSnapshotModifiedAt returns null when no snapshot file '
      'exists, and does not throw',
      () async {
        expect(await repo.preRestoreSnapshotModifiedAt(), isNull);
      },
    );

    test(
      'readPreRestoreSnapshot returns null when no snapshot file exists',
      () async {
        expect(await repo.readPreRestoreSnapshot(), isNull);
      },
    );

    test(
      'readPreRestoreSnapshot round-trips a written document with no field '
      'lost',
      () async {
        final note = Note(
          id: 'a',
          title: 'Thay nhớt',
          body: 'Đã thay nhớt Motul 5100 10W-40',
          pinned: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
        final original = AppData.empty().copyWith(notes: [note]);

        await repo.writePreRestoreSnapshot(original);
        final loaded = await repo.readPreRestoreSnapshot();

        expect(loaded, equals(original));
      },
    );

    test(
      'a snapshot stamped with a future schemaVersion throws '
      'SchemaTooNewException rather than returning a partially-parsed '
      'document',
      () async {
        final snapshot = File('${tempDir.path}/appdata.pre-restore.json');
        await snapshot.writeAsString(
          jsonEncode({
            'schemaVersion': 2,
            'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
            'settings': <String, dynamic>{},
          }),
        );

        expect(
          () => repo.readPreRestoreSnapshot(),
          throwsA(isA<SchemaTooNewException>()),
        );
      },
    );

    test(
      'deletePreRestoreSnapshot removes an existing snapshot and leaves '
      'appdata.json/appdata.backup.json byte-identical',
      () async {
        final first = AppData.empty().copyWith(deviceLabel: 'first-save');
        final second = AppData.empty().copyWith(deviceLabel: 'second-save');
        await repo.save(first);
        await repo.save(second);
        await repo.writePreRestoreSnapshot(
          AppData.empty().copyWith(deviceLabel: 'snapshot'),
        );

        final primary = File('${tempDir.path}/appdata.json');
        final backup = File('${tempDir.path}/appdata.backup.json');
        final primaryBefore = await primary.readAsBytes();
        final backupBefore = await backup.readAsBytes();

        await repo.deletePreRestoreSnapshot();

        final snapshot = File('${tempDir.path}/appdata.pre-restore.json');
        expect(await snapshot.exists(), isFalse);
        expect(await primary.readAsBytes(), equals(primaryBefore));
        expect(await backup.readAsBytes(), equals(backupBefore));
      },
    );

    test(
      'deletePreRestoreSnapshot when no snapshot exists throws nothing and '
      'leaves the directory otherwise unchanged',
      () async {
        final first = AppData.empty().copyWith(deviceLabel: 'first-save');
        await repo.save(first);

        final entriesBefore = (await tempDir.list().toList())
            .map((e) => e.path)
            .toSet();

        await repo.deletePreRestoreSnapshot();

        final entriesAfter = (await tempDir.list().toList())
            .map((e) => e.path)
            .toSet();
        expect(entriesAfter, equals(entriesBefore));
      },
    );

    test(
      'preRestoreSnapshotModifiedAt returns null after deletePreRestoreSnapshot',
      () async {
        await repo.writePreRestoreSnapshot(AppData.empty());
        expect(await repo.preRestoreSnapshotModifiedAt(), isNotNull);

        await repo.deletePreRestoreSnapshot();

        expect(await repo.preRestoreSnapshotModifiedAt(), isNull);
      },
    );
  });
}
