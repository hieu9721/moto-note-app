// Tests for isBackupDue/relativeVi (§7.5/§7.6, P5-D-18). Runs under plain
// `dart test`, no Flutter engine — package:test only (D-32, P1-D-11,
// P4-D-13). Two groups, one per function, mirroring `due_test.dart`'s
// group-per-function convention with Vietnamese `test(...)` descriptions.
// Fixtures build from a single fixed `now` declared at the top of each
// group and offset from it; the real clock is never called inside an
// expectation. Kept in two groups so 05-03/05-04 can append their own
// `driveCopyIsOlder`/`canUndoRestore` groups without touching these.
import 'package:motonote/domain/backup_timing.dart';
import 'package:test/test.dart';

void main() {
  group('isBackupDue', () {
    final now = DateTime.utc(2026, 9, 1, 12, 0, 0);

    test('chưa từng sao lưu thì luôn tới hạn', () {
      expect(isBackupDue(null, now: now), isTrue);
    });

    test('chưa tới hạn ở 23 giờ 59 phút 59 giây', () {
      final last = now.subtract(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
      expect(isBackupDue(last, now: now), isFalse);
    });

    test('chưa tới hạn ở đúng 24 giờ — biên không tính là quá 24h', () {
      final last = now.subtract(const Duration(hours: 24));
      expect(isBackupDue(last, now: now), isFalse);
    });

    test('tới hạn ngay sau 24 giờ 1 giây', () {
      final last = now.subtract(const Duration(hours: 24, seconds: 1));
      expect(isBackupDue(last, now: now), isTrue);
    });

    test('mốc sao lưu cuối ở tương lai thì không tới hạn, không throw', () {
      final last = now.add(const Duration(hours: 1));
      expect(isBackupDue(last, now: now), isFalse);
    });
  });

  group('relativeVi', () {
    final now = DateTime.utc(2026, 9, 1, 12, 0, 0);

    test('ngay bây giờ hiển thị "vừa xong"', () {
      expect(relativeVi(now, now: now), equals('vừa xong'));
    });

    test('59 giây trước vẫn là "vừa xong"', () {
      final then = now.subtract(const Duration(seconds: 59));
      expect(relativeVi(then, now: now), equals('vừa xong'));
    });

    test('60 giây trước là "1 phút trước"', () {
      final then = now.subtract(const Duration(seconds: 60));
      expect(relativeVi(then, now: now), equals('1 phút trước'));
    });

    test('59 phút 59 giây trước là "59 phút trước"', () {
      final then = now.subtract(
        const Duration(minutes: 59, seconds: 59),
      );
      expect(relativeVi(then, now: now), equals('59 phút trước'));
    });

    test('2 giờ trước — dạng verbatim §7.6', () {
      final then = now.subtract(const Duration(hours: 2));
      expect(relativeVi(then, now: now), equals('2 giờ trước'));
    });

    test('23 giờ 59 phút trước không bị làm tròn xuống 0 ngày', () {
      final then = now.subtract(
        const Duration(hours: 23, minutes: 59),
      );
      expect(relativeVi(then, now: now), equals('23 giờ trước'));
    });

    test('đúng 24 giờ trước là "1 ngày trước"', () {
      final then = now.subtract(const Duration(hours: 24));
      expect(relativeVi(then, now: now), equals('1 ngày trước'));
    });

    test('47 giờ 59 phút trước vẫn là "1 ngày trước"', () {
      final then = now.subtract(
        const Duration(hours: 47, minutes: 59),
      );
      expect(relativeVi(then, now: now), equals('1 ngày trước'));
    });

    test('72 giờ trước — dạng verbatim §7.5', () {
      final then = now.subtract(const Duration(hours: 72));
      expect(relativeVi(then, now: now), equals('3 ngày trước'));
    });

    test('mốc thời gian ở tương lai suy giảm về "vừa xong"', () {
      final then = now.add(const Duration(minutes: 5));
      expect(relativeVi(then, now: now), equals('vừa xong'));
    });
  });

  group('driveCopyIsOlder', () {
    final t = DateTime.utc(2026, 9, 1, 12, 0, 0);

    test('hai mốc bằng nhau — cùng một bản, không phải bản cũ hơn', () {
      expect(
        driveCopyIsOlder(driveModifiedAt: t, localUpdatedAt: t),
        isFalse,
      );
    });

    test('máy mới hơn Drive 1 phút vẫn nằm trong biên đồng hồ', () {
      expect(
        driveCopyIsOlder(
          driveModifiedAt: t,
          localUpdatedAt: t.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('máy mới hơn Drive đúng 2 phút — biên bao gồm cả điểm này', () {
      expect(
        driveCopyIsOlder(
          driveModifiedAt: t,
          localUpdatedAt: t.add(const Duration(minutes: 2)),
        ),
        isFalse,
      );
    });

    test('máy mới hơn Drive 2 phút 1 giây — vượt biên, tính là cũ hơn', () {
      expect(
        driveCopyIsOlder(
          driveModifiedAt: t,
          localUpdatedAt: t.add(const Duration(minutes: 2, seconds: 1)),
        ),
        isTrue,
      );
    });

    test('bản trên Drive mới hơn máy 5 ngày thì không bao giờ tính là cũ hơn', () {
      expect(
        driveCopyIsOlder(
          driveModifiedAt: t,
          localUpdatedAt: t.subtract(const Duration(days: 5)),
        ),
        isFalse,
      );
    });

    test('bản trên Drive cũ hơn máy 30 ngày thì tính là cũ hơn', () {
      expect(
        driveCopyIsOlder(
          driveModifiedAt: t.subtract(const Duration(days: 30)),
          localUpdatedAt: t,
        ),
        isTrue,
      );
    });
  });

  group('canUndoRestore', () {
    final now = DateTime.utc(2026, 9, 1, 12, 0, 0);

    test('snapshot 6 ngày trước vẫn còn trong hạn hoàn tác', () {
      expect(
        canUndoRestore(now.subtract(const Duration(days: 6)), now: now),
        isTrue,
      );
    });

    test('snapshot đúng 7 ngày trước vẫn còn trong hạn — biên bao gồm điểm này', () {
      expect(
        canUndoRestore(now.subtract(const Duration(days: 7)), now: now),
        isTrue,
      );
    });

    test('snapshot 7 ngày 1 giây trước thì đã hết hạn', () {
      expect(
        canUndoRestore(
          now.subtract(const Duration(days: 7, seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('mốc snapshot ở tương lai (đồng hồ máy vừa chỉnh) vẫn coi là gần đây', () {
      expect(
        canUndoRestore(now.add(const Duration(hours: 1)), now: now),
        isTrue,
      );
    });
  });
}
