// lib/domain/models/misc.dart — transcribed verbatim from §4.2's "misc.dart"
// block: OdoSource, OdoReading, Note, Settings. Pure Dart (D-31) — no
// package:flutter/... import.
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
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
