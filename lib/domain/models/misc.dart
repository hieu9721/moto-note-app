// lib/domain/models/misc.dart — transcribed verbatim from §4.2's "misc.dart"
// block: OdoSource, OdoReading, Note, Settings. Pure Dart (D-31) — this
// directory must never import the Flutter SDK.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'misc.freezed.dart';
part 'misc.g.dart';

enum OdoSource { manual, service, setup }

@freezed
abstract class OdoReading with _$OdoReading {
  const factory OdoReading({
    required String id,
    required String vehicleId,
    required int odoKm,
    required DateTime date,
    @Default(OdoSource.manual) OdoSource source,
  }) = _OdoReading;

  factory OdoReading.fromJson(Map<String, dynamic> json) =>
      _$OdoReadingFromJson(json);
}

@freezed
abstract class Note with _$Note {
  const factory Note({
    required String id,
    String? vehicleId,
    String? itemId,
    String? title,
    @Default('') String body,
    @Default(false) bool pinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}

// 04-03 (P4-D-05/P4-D-07): notificationPermissionAsked and exactAlarmsEnabled
// are [NEW, PROVISIONAL] field names (04-RESEARCH.md Assumptions Log A1) —
// the app has never released, so renaming either before 1.0 costs nothing,
// but D-21 makes it a one-way change after first release.
@freezed
abstract class Settings with _$Settings {
  const factory Settings({
    @Default(true) bool notificationsEnabled,
    @Default(true) bool odoReminderEnabled,
    @Default(1) int odoReminderDayOfMonth, // 1–28
    @Default(8) int notifyHour, // 0–23, giờ máy
    @Default(7) int leadDays, // báo trước bao nhiêu ngày
    @Default(false) bool driveBackupEnabled,
    DateTime? lastBackupAt,
    String? lastBackupError,
    String? googleEmail, // chỉ để hiển thị đang backup vào đâu
    DateTime? lastNotificationFiredAt,
    @Default(false)
    bool notificationPermissionAsked, // one-shot ask flag (P4-D-05)
    @Default(false)
    bool exactAlarmsEnabled, // user's exact-timing opt-in (P4-D-07)
    // 05-07 (P5-D-25/P5-D-26): gates the one-time Drive-backup offer shown on
    // home's first render after onboarding. [NEW, PROVISIONAL] — the app has
    // never released, so renaming this before 1.0 costs nothing; D-21 makes
    // it a migration concern the moment it does. Persisted deliberately: an
    // in-memory flag would let the prompt re-ask on every cold start, which
    // is the nag prohibition this field exists to prevent.
    @Default(false) bool driveBackupPromptShown,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
