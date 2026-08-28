// Tests for AppDataRepository — the atomic-write, backup-fallback data layer
// (§5.1, P1-D-11). Runs under plain `dart test`, no Flutter engine, against a
// real temp directory — no mocks, because the Directory is constructor-injected.
//
// Groups are kept separate ('round-trip', 'missing file', 'backup fallback',
// 'migration') so plans 01-03 and 01-04 can append their own groups without
// touching these.

import 'dart:io';

import 'package:motonote/data/app_data_repository.dart';
import 'package:motonote/data/migrations.dart';
import 'package:motonote/domain/id.dart';
import 'package:motonote/domain/models/app_data.dart';
import 'package:motonote/domain/models/misc.dart';
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
}
