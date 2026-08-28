# MotoNote — Kiến trúc & kế hoạch (Flutter)

> App ghi chú + nhắc bảo trì xe máy · Không tài khoản · Lưu máy · Backup Google Drive
> Phiên bản 3.0 · 2026-08-28 · Thay thế v2.0 (React Native)

---

## Mục lục

1. [Chốt phương án](#1-chốt-phương-án)
2. [Nguyên tắc thiết kế](#2-nguyên-tắc-thiết-kế)
3. [Kiến trúc & stack](#3-kiến-trúc--stack)
4. [Mô hình dữ liệu](#4-mô-hình-dữ-liệu)
5. [Lưu trữ cục bộ](#5-lưu-trữ-cục-bộ)
6. [Luồng mở app lần đầu](#6-luồng-mở-app-lần-đầu)
7. [Google Drive backup](#7-google-drive-backup)
8. [Chọn linh kiện & loại nhớt](#8-chọn-linh-kiện--loại-nhớt)
9. [Ước tính ODO & tính hạn](#9-ước-tính-odo--tính-hạn)
10. [Thông báo cục bộ](#10-thông-báo-cục-bộ)
11. [Màn hình & điều hướng](#11-màn-hình--điều-hướng)
12. [Cấu trúc dự án](#12-cấu-trúc-dự-án)
13. [Kế hoạch triển khai](#13-kế-hoạch-triển-khai)
14. [Ghi chú cho người mới Dart/Flutter](#14-ghi-chú-cho-người-mới-dartflutter)
15. [Rủi ro](#15-rủi-ro)
16. [Phụ lục A — Catalog linh kiện](#phụ-lục-a--catalog-linh-kiện)
17. [Phụ lục B — Checklist phát hành](#phụ-lục-b--checklist-phát-hành)

---

## 1. Chốt phương án

| Hạng mục | Quyết định |
|---|---|
| Framework | **Flutter** |
| Backend | Không có |
| Tài khoản app | Không có |
| Lưu trữ | Một file JSON trong thư mục app |
| Đồng bộ | Backup/khôi phục toàn bộ file lên Google Drive (`appDataFolder`) |
| Thông báo | `flutter_local_notifications`, không có push |
| Ước tính ODO | Km trung bình/ngày user nhập, tự hiệu chỉnh dần |
| **Nhập dữ liệu Google Maps** | **Đã loại bỏ** |

### 1.1. Vì sao bỏ nhập từ Google Maps

Ghi lại để sau này không phải nghiên cứu lại:

- **Không có API.** Google chưa từng cung cấp API đọc Timeline. Cách duy nhất là user tự xuất file `Timeline.json` từ Cài đặt điện thoại.
- Từ cuối 2024 Google chuyển Timeline xuống lưu trên máy, tắt Timeline trên web từ 09/06/2025, và Takeout không còn xuất Timeline nữa. Thời gian giữ mặc định rút xuống 3 tháng.
- Định dạng file không có tài liệu chính thức và khác nhau giữa Android với iOS. Google đã đổi định dạng ba lần trong ba năm.
- **Quan trọng nhất:** dữ liệu đó không dùng để đặt ODO được. Timeline chỉ ghi chuyến khi điện thoại bật định vị và mang theo người, đồng thời ghi cả lúc user ngồi sau xe người khác hoặc đi taxi. Sai theo cả hai chiều.

Nếu sau này muốn giảm số lần nhập ODO thủ công, làm **nhật ký đổ xăng** (§13.3) — rẻ hơn nhiều và hiệu quả hơn cho đúng mục tiêu đó.

### 1.2. Vì sao Flutter thay vì React Native

Đánh đổi đã cân nhắc và chấp nhận:

**Được:**
- Kiểm soát lịch thông báo Android ở mức chi tiết (`androidScheduleMode`) — quan trọng vì thông báo là tính năng cốt lõi của app này
- Package Google chính chủ cho Drive (`googleapis`), có kiểu dữ liệu đầy đủ
- App nhẹ hơn, khởi động nhanh hơn trên máy tầm thấp — đáng kể với thị trường Việt Nam
- Không phải chạy theo chu kỳ nâng cấp SDK 6 tháng một lần

**Mất:**
- Ngôn ngữ mới, mô hình widget mới, toolchain mới
- Thời gian tăng từ ~5 tuần lên ~7 tuần (§13)
- Lúc gặp lỗi platform-level sẽ mò lâu hơn

§14 tổng hợp những chỗ dễ vấp nhất khi chuyển từ React sang Flutter.

---

## 2. Nguyên tắc thiết kế

**1. Toàn bộ trạng thái app là một document JSON.**
Không phải database, không phải nhiều bảng. Một object. Dữ liệu rất nhỏ — 1 xe × 15 hạng mục × vài trăm log qua nhiều năm ≈ dưới 200 KB. Khi state là một document thì backup chính là *upload nguyên document đó*: không giao thức sync, không merge, không conflict resolution.

Đây là quyết định kiến trúc quan trọng nhất của toàn bộ dự án.

**2. Không có nguồn sự thật nào ngoài máy người dùng.**
Google Drive chỉ là nơi cất bản sao. App không bao giờ đọc Drive để lấy dữ liệu đang dùng — chỉ đọc đúng một lần lúc khôi phục.

**3. Ghi trước, backup sau.**
Mọi thao tác ghi xuống máy ngay. Backup lên Drive chạy nền, thất bại cũng không sao.

**4. App phải chạy đủ chức năng khi chưa từng đăng nhập Google.**
Đăng nhập chỉ để backup. Người không muốn thì dùng nút xuất file.

**5. Không màn hình nào chờ mạng.**
Mọi thứ đọc từ bộ nhớ, hiển thị tức thì.

---

## 3. Kiến trúc & stack

```
┌────────────────────────────────────────────────────────┐
│                     ĐIỆN THOẠI                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │                  Flutter                          │  │
│  │                                                   │  │
│  │  Widgets ◄──► Riverpod ◄──► AppDataRepository     │  │
│  │                              │                    │  │
│  │                              ▼                    │  │
│  │                    appdata.json (file)            │  │
│  │                                                   │  │
│  │      ┌───────────┬───────────┬───────────┐        │  │
│  │      ▼           ▼           ▼           ▼        │  │
│  │  due engine  notifier    backup     export        │  │
│  │  (Dart thuần) (flutter_  (googleapis) (share_plus)│  │
│  │               local_                              │  │
│  │               notifications)                      │  │
│  └──────────────────┬──────────────────┬─────────────┘  │
│                     │                  │                │
│                ┌────▼─────┐            │ HTTPS          │
│                │AlarmManager           │                │
│                │/ UNUserNC │           │                │
│                └───────────┘           │                │
└────────────────────────────────────────┼────────────────┘
                                         │
                     ┌───────────────────▼──────────────────┐
                     │  Google Drive — appDataFolder        │
                     │  motonote-backup.json (ẩn)           │
                     │  scope: drive.appdata                │
                     └──────────────────────────────────────┘
```

Không có server nào của mình trong sơ đồ này.

### 3.1. Phụ thuộc

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State & routing
  flutter_riverpod: ^2.6.0
  go_router: ^14.0.0

  # Model & serialize
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

  # Lưu trữ
  path_provider: ^2.1.0

  # Thông báo
  flutter_local_notifications: ^18.0.0
  timezone: ^0.10.0
  flutter_timezone: ^4.0.0
  permission_handler: ^11.3.0        # xin quyền + mở cài đặt hệ thống

  # Google Drive
  google_sign_in: ^7.1.0
  googleapis: ^13.2.0
  extension_google_sign_in_as_googleapis_auth: ^3.0.0

  # Tiện ích
  intl: ^0.19.0                      # định dạng ngày, số, tiền VND
  share_plus: ^10.0.0                # xuất file thủ công
  device_info_plus: ^11.0.0          # phát hiện hãng máy → hướng dẫn tắt tối ưu pin
  android_intent_plus: ^5.0.0        # mở đúng trang cài đặt của từng hãng

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^3.0.0
  json_serializable: ^6.8.0
  flutter_lints: ^5.0.0
  flutter_test:
    sdk: flutter
```

> **Kiểm tra phiên bản trước khi bắt đầu.** Số phiên bản ở trên là mốc tham chiếu, không phải cam kết. `google_sign_in` và `freezed` đều đã có breaking change lớn gần đây — chạy `flutter pub outdated` và đọc CHANGELOG của hai package này trước khi viết code, đừng chép code cũ trên mạng.

### 3.2. Vì sao chọn từng thứ

**Riverpod thay vì Provider/BLoC.** App này có đúng một khối state (`AppData`) và vài trạng thái UI tạm. BLoC là quá nặng cho quy mô này — nhiều event class, nhiều state class, nhiều boilerplate cho một app 7 màn hình. Riverpod với một `NotifierProvider` là đủ, và dễ test hơn vì logic nằm ở hàm thuần.

**Freezed dù có thêm bước codegen.** `Vehicle` có 14 trường. Viết `copyWith` bằng tay cho nó là công việc buồn chán và dễ sai — quên một trường thì dữ liệu mất âm thầm. Freezed sinh `copyWith`, `==`, `toString`, và cùng `json_serializable` sinh luôn `toJson`/`fromJson`. Đổi lại phải chạy `build_runner`, hơi phiền lúc đầu nhưng quen nhanh.

**File JSON thuần thay vì Hive/Isar/SQLite.** Toàn bộ dữ liệu vừa trong RAM thoải mái. Thêm một database chỉ để lưu 200 KB là thêm phụ thuộc, thêm schema migration, thêm một thứ có thể hỏng — mà lại làm phần backup phức tạp hơn (phải export ra JSON rồi mới upload được). Ghi thẳng file JSON là đơn giản nhất và cũng phù hợp nhất với kiến trúc backup.

**`go_router` thay vì Navigator thuần.** Cần deep link từ thông báo vào đúng màn hình. `go_router` xử lý việc này gọn hơn nhiều so với tự quản lý stack.

---

## 4. Mô hình dữ liệu

### 4.1. Document gốc

```dart
// lib/domain/models/app_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_data.freezed.dart';
part 'app_data.g.dart';

const int kSchemaVersion = 1;

@freezed
abstract class AppData with _$AppData {
  const factory AppData({
    @Default(kSchemaVersion) int schemaVersion,
    required DateTime updatedAt,
    @Default('') String deviceLabel,
    @Default([]) List<Vehicle> vehicles,
    @Default([]) List<MaintenanceItem> items,
    @Default([]) List<ServiceLog> logs,
    @Default([]) List<OdoReading> odoReadings,
    @Default([]) List<Note> notes,
    required Settings settings,
  }) = _AppData;

  factory AppData.fromJson(Map<String, dynamic> json) =>
      _$AppDataFromJson(json);

  factory AppData.empty() => AppData(
        updatedAt: DateTime.now(),
        settings: const Settings(),
      );
}
```

### 4.2. Các model con

```dart
// lib/domain/models/vehicle.dart

enum VehicleType {
  scooter,      // tay ga
  underbone,    // xe số
  manual,       // côn tay
}

enum OilGrade { mineral, semiSynthetic, fullSynthetic }

enum AvgKmSource { user, computed }

@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,               // nanoid / uuid v4
    required String name,
    required VehicleType type,
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? photoPath,                // đường dẫn cục bộ — KHÔNG backup
    required int currentOdoKm,
    required DateTime odoUpdatedAt,
    required double avgDailyKm,
    @Default(AvgKmSource.user) AvgKmSource avgDailyKmSource,
    required DateTime createdAt,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}
```

```dart
// lib/domain/models/maintenance_item.dart

@freezed
abstract class MaintenanceItem with _$MaintenanceItem {
  const factory MaintenanceItem({
    required String id,
    required String vehicleId,
    required String catalogCode,      // 'engine_oil' — tra catalog lấy icon, hint
    required String name,             // user sửa được
    int? intervalKm,
    int? intervalMonths,
    @Default(true) bool enabled,

    // Mốc gần nhất — cập nhật khi ghi log
    int? lastServiceOdo,
    DateTime? lastServiceDate,
    @Default(true) bool baselineIsGuess,

    // Quy cách phụ tùng đang dùng — điền sẵn cho lần ghi log sau
    String? partBrand,                // "Motul"
    String? partSpec,                 // "5100 10W-40"
    OilGrade? oilGrade,               // chỉ với hạng mục nhớt
    int? lastCostVnd,

    String? notes,
  }) = _MaintenanceItem;

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceItemFromJson(json);
}
```

```dart
// lib/domain/models/service_log.dart

@freezed
abstract class ServiceLogEntry with _$ServiceLogEntry {
  const factory ServiceLogEntry({
    required String itemId,
    int? costVnd,
    String? partBrand,
    String? partSpec,
    @Default(true) bool resetsCycle,  // false = chỉ kiểm tra, chưa thay
  }) = _ServiceLogEntry;

  factory ServiceLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ServiceLogEntryFromJson(json);
}

@freezed
abstract class ServiceLog with _$ServiceLog {
  const factory ServiceLog({
    required String id,
    required String vehicleId,
    required DateTime date,
    required int odoKm,
    String? shopName,
    int? totalCostVnd,
    String? note,
    @Default([]) List<String> photoPaths,   // cục bộ, không backup
    @Default([]) List<ServiceLogEntry> entries,
  }) = _ServiceLog;

  factory ServiceLog.fromJson(Map<String, dynamic> json) =>
      _$ServiceLogFromJson(json);
}
```

```dart
// lib/domain/models/misc.dart

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
    @Default(true)  bool notificationsEnabled,
    @Default(true)  bool odoReminderEnabled,
    @Default(1)     int  odoReminderDayOfMonth,   // 1–28
    @Default(8)     int  notifyHour,              // 0–23, giờ máy
    @Default(7)     int  leadDays,                // báo trước bao nhiêu ngày
    @Default(false) bool driveBackupEnabled,
    DateTime? lastBackupAt,
    String? lastBackupError,
    String? googleEmail,          // chỉ để hiển thị đang backup vào đâu
    DateTime? lastNotificationFiredAt,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
```

Chạy `dart run build_runner build --delete-conflicting-outputs` để sinh code. Trong lúc phát triển thì `dart run build_runner watch` tiện hơn.

### 4.3. Vì sao ảnh không nằm trong document

Ảnh hoá đơn lưu ở thư mục app, chỉ giữ đường dẫn trong JSON:

- `appDataFolder` tính vào quota Drive của user, vài chục ảnh sẽ phình nhanh.
- Upload ảnh cần multipart, resumable, retry — đúng loại phức tạp mà kiến trúc này đang tránh.
- Ảnh hoá đơn là dữ liệu "có thì tốt", mất không nghiêm trọng.

Hệ quả **phải nói rõ với user, ngay trên màn hình khôi phục**: khôi phục từ Drive lấy lại mọi dữ liệu trừ ảnh. Không giấu trong FAQ.

### 4.4. Migration

File backup trên Drive có thể cũ hơn app đang chạy. Hàm migrate phải chạy được cho cả dữ liệu local lẫn dữ liệu khôi phục:

```dart
// lib/data/migrations.dart

Map<String, dynamic> migrateRaw(Map<String, dynamic> raw) {
  var data = Map<String, dynamic>.from(raw);
  final from = (data['schemaVersion'] as int?) ?? 0;

  if (from < 2) {
    // v1 → v2: thêm avgDailyKmSource cho mọi xe
    final vehicles = (data['vehicles'] as List? ?? []).map((v) {
      final m = Map<String, dynamic>.from(v as Map);
      m.putIfAbsent('avgDailyKmSource', () => 'user');
      return m;
    }).toList();
    data['vehicles'] = vehicles;
  }

  // ... các bước sau

  data['schemaVersion'] = kSchemaVersion;
  return data;
}
```

Nguyên tắc: **chỉ thêm trường, không đổi tên, không xoá.** Trường thừa thì `json_serializable` tự bỏ qua. Như vậy file backup cũ luôn đọc được, và file backup mới cũng không làm app phiên bản cũ crash.

---

## 5. Lưu trữ cục bộ

### 5.1. Ghi file nguyên tử

Rủi ro lớn nhất khi lưu cả state vào một file: app bị kill giữa lúc đang ghi → file cụt → mất sạch dữ liệu.

Giải pháp là ghi ra file tạm rồi đổi tên. Trên hầu hết hệ thống tệp, `rename` là thao tác nguyên tử: hoặc thành công hoàn toàn, hoặc không xảy ra gì.

```dart
// lib/data/app_data_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppDataRepository {
  static const _fileName = 'appdata.json';
  static const _backupName = 'appdata.backup.json';

  Future<Directory> get _dir async => getApplicationDocumentsDirectory();

  Future<File> get _file async =>
      File('${(await _dir).path}/$_fileName');

  Future<AppData?> load() async {
    final file = await _file;
    if (!await file.exists()) return await _loadFallback();

    try {
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AppData.fromJson(migrateRaw(raw));
    } catch (e, st) {
      // File hỏng — thử bản dự phòng thay vì mất trắng
      debugPrint('appdata.json hỏng: $e\n$st');
      return await _loadFallback();
    }
  }

  Future<AppData?> _loadFallback() async {
    final f = File('${(await _dir).path}/$_backupName');
    if (!await f.exists()) return null;
    try {
      final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return AppData.fromJson(migrateRaw(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AppData data) async {
    final dir = await _dir;
    final target = File('${dir.path}/$_fileName');
    final tmp    = File('${dir.path}/$_fileName.tmp');
    final backup = File('${dir.path}/$_backupName');

    // 1. Ghi ra file tạm
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);

    // 2. Giữ lại bản hiện tại làm dự phòng
    if (await target.exists()) {
      await target.copy(backup.path);
    }

    // 3. Đổi tên — nguyên tử
    await tmp.rename(target.path);
  }
}
```

Bước 2 tạo ra một lớp bảo vệ nữa: nếu file chính hỏng vì lý do gì đó, vẫn còn bản ghi ngay trước đó. Mất tối đa một thao tác thay vì mất tất cả.

### 5.2. Store Riverpod

```dart
// lib/state/app_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final repositoryProvider = Provider((_) => AppDataRepository());

class AppNotifier extends Notifier<AppData> {
  late final AppDataRepository _repo;

  @override
  AppData build() {
    _repo = ref.read(repositoryProvider);
    return AppData.empty();   // thay bằng dữ liệu thật ở hydrate()
  }

  /// Gọi một lần lúc khởi động, trước khi hiện UI.
  Future<bool> hydrate() async {
    final loaded = await _repo.load();
    if (loaded == null) return false;      // chưa có dữ liệu → onboarding
    state = loaded;
    return true;
  }

  /// Mọi thay đổi đi qua đây. Ghi file + đặt lại lịch thông báo.
  Future<void> _mutate(AppData Function(AppData) f) async {
    state = f(state).copyWith(updatedAt: DateTime.now());
    await _repo.save(state);
    await ref.read(notificationSchedulerProvider).rescheduleAll(state);
    ref.read(backupServiceProvider).scheduleDebounced();   // §7.5
  }

  // ── Các thao tác ──

  Future<void> addOdoReading(String vehicleId, int odoKm, DateTime date) =>
      _mutate((d) {
        final vehicle = d.vehicles.firstWhere((v) => v.id == vehicleId);
        final prev = latestReadingFor(d, vehicleId);

        final reading = OdoReading(
          id: newId(), vehicleId: vehicleId, odoKm: odoKm, date: date,
        );

        final refined = refineAvgDailyKm(vehicle, reading, prev);

        return d.copyWith(
          odoReadings: [...d.odoReadings, reading],
          vehicles: d.vehicles.map((v) => v.id == vehicleId
              ? v.copyWith(
                  currentOdoKm: odoKm,
                  odoUpdatedAt: date,
                  avgDailyKm: refined.avgDailyKm,
                  avgDailyKmSource: refined.source,
                )
              : v).toList(),
        );
      });

  Future<void> addServiceLog(ServiceLog log) => _mutate((d) {
        // Cập nhật mốc cho các hạng mục có resetsCycle
        final resetIds = log.entries
            .where((e) => e.resetsCycle).map((e) => e.itemId).toSet();

        return d.copyWith(
          logs: [...d.logs, log],
          odoReadings: [...d.odoReadings, OdoReading(
            id: newId(), vehicleId: log.vehicleId,
            odoKm: log.odoKm, date: log.date, source: OdoSource.service,
          )],
          items: d.items.map((i) {
            if (!resetIds.contains(i.id)) return i;
            final entry = log.entries.firstWhere((e) => e.itemId == i.id);
            return i.copyWith(
              lastServiceOdo: log.odoKm,
              lastServiceDate: log.date,
              baselineIsGuess: false,
              partBrand: entry.partBrand ?? i.partBrand,
              partSpec:  entry.partSpec  ?? i.partSpec,
              lastCostVnd: entry.costVnd ?? i.lastCostVnd,
            );
          }).toList(),
        );
      });

  // ... các thao tác khác
}

final appProvider = NotifierProvider<AppNotifier, AppData>(AppNotifier.new);
```

Điểm mấu chốt: **mọi thay đổi đi qua đúng một hàm `_mutate`**, và hàm đó luôn làm ba việc — ghi file, đặt lại lịch thông báo, hẹn backup. Không có đường nào sửa state mà quên một trong ba việc đó.

### 5.3. Provider dẫn xuất

Widget không tự tính trạng thái hạng mục. Riverpod tính sẵn và cache:

```dart
/// Danh sách hạng mục của một xe kèm trạng thái, đã sắp theo độ gấp.
final dueItemsProvider = Provider.family<List<DueItem>, String>((ref, vehicleId) {
  final data = ref.watch(appProvider);
  final vehicle = data.vehicles.firstWhere((v) => v.id == vehicleId);

  final result = <DueItem>[];
  for (final item in data.items.where((i) => i.vehicleId == vehicleId)) {
    final due = computeDue(item, vehicle, data.settings.leadDays);
    if (due != null) result.add(DueItem(item: item, due: due));
  }

  result.sort((a, b) => a.due.daysLeft.compareTo(b.due.daysLeft));
  return result;
});
```

---

## 6. Luồng mở app lần đầu

```
        ┌─────────────────────────┐
        │  Màn hình chào          │
        │  MotoNote               │
        │  Nhắc bảo dưỡng xe máy  │
        │                         │
        │  ┌───────────────────┐  │
        │  │ Khôi phục từ      │  │
        │  │ Google Drive      │  │
        │  └───────────────────┘  │
        │  ┌───────────────────┐  │
        │  │ Bắt đầu mới       │  │
        │  └───────────────────┘  │
        └───────────┬─────────────┘
                    │
        ┌───────────┴────────────┐
        ▼                        ▼
┌───────────────┐      ┌──────────────────┐
│ Chọn tài khoản│      │ 1. Loại xe       │
│ Google        │      │   ○ Tay ga       │
└───────┬───────┘      │   ○ Xe số        │
        ▼              │   ○ Côn tay      │
┌───────────────┐      └────────┬─────────┘
│ Tìm backup    │               ▼
│               │      ┌──────────────────┐
│ Tìm thấy:     │      │ 2. Tên & biển số │
│ 24/08 · 1 xe  │      │   (bỏ qua được)  │
│ 34 log · 187KB│      └────────┬─────────┘
│               │               ▼
│ ⚠ Ảnh hoá đơn │      ┌──────────────────┐
│  không khôi   │      │ 3. Số km         │
│  phục được    │      │  ODO: [ 18420 ]  │
│               │      │  Mỗi ngày đi     │
│ [ Khôi phục ] │      │  khoảng:[ 25 ]km │
│ [ Bắt đầu mới]│      └────────┬─────────┘
└───────┬───────┘               ▼
        │              ┌──────────────────┐
        │              │ 4. Chọn hạng mục │
        │              │  (8 mục tích sẵn)│
        │              └────────┬─────────┘
        │                       ▼
        │              ┌──────────────────┐
        │              │ 5. Loại nhớt     │
        │              │  → tự đổi chu kỳ │
        │              └────────┬─────────┘
        │                       ▼
        │              ┌──────────────────┐
        │              │ 6. Lần cuối thay │
        │              │    nhớt?         │
        │              └────────┬─────────┘
        └───────────┬───────────┘
                    ▼
            ┌───────────────┐
            │  Xin quyền    │
            │  thông báo    │
            └───────┬───────┘
                    ▼
            ┌───────────────┐
            │  Trang chủ    │
            └───────────────┘
```

### 6.1. Bước 6 — giải quyết vấn đề "chưa biết gì về lịch sử xe"

App phải nhắc cho đúng ngay từ ngày đầu nhưng chưa có mốc thật nào.

| Chọn | `lastServiceDate` | `lastServiceOdo` |
|---|---|---|
| Dưới 1 tháng | hôm nay − 15 ngày | ODO − 15 × avgDaily |
| 1–3 tháng | hôm nay − 60 ngày | ODO − 60 × avgDaily |
| Trên 3 tháng | hôm nay − 100 ngày | ODO − 100 × avgDaily |
| Không nhớ | hôm nay | ODO hiện tại |

Cả bốn trường hợp đều đặt `baselineIsGuess = true`.

"Không nhớ" cố ý đặt mốc là hôm nay — app sẽ **không nhắc gì** cho tới hết một chu kỳ đầy đủ. Thà im lặng còn hơn nhắc bừa. Nhưng phải hiện badge "chưa có mốc thật" trên hạng mục đó kèm gợi ý *"Bạn vừa thay nhớt? Ghi lại để app tính đúng"*.

**Chỉ hỏi bước này cho nhớt máy.** Các hạng mục còn lại mặc định "không nhớ". Hỏi 12 câu là cách nhanh nhất để user thoát app.

---

## 7. Google Drive backup

### 7.1. Nói rõ ngay từ đầu

Không có tài khoản app, nhưng backup lên Drive thì bắt buộc phải đăng nhập **Google**. Diễn đạt đúng cho user:

- **Không có tài khoản MotoNote.** Không email, không mật khẩu, không server nào của app giữ dữ liệu.
- **Có đăng nhập Google, và chỉ khi bạn bật backup.** Dữ liệu đi thẳng từ điện thoại lên Drive của bạn.
- **App chỉ thấy đúng file của nó.** Không đọc được ảnh, tài liệu hay bất cứ thứ gì khác trong Drive.

Câu thứ ba là thật, không phải marketing — xem §7.2.

### 7.2. Scope `drive.appdata`

Drive có một thư mục đặc biệt gọi là application data folder:

- Mỗi app một thư mục riêng, **không app nào đọc được của app khác**.
- **Ẩn hoàn toàn** khỏi giao diện Drive — user không thấy, không xoá nhầm.
- Scope `https://www.googleapis.com/auth/drive.appdata` được Google phân loại **non-sensitive** — chỉ cần xác minh app cơ bản, **không phải qua duyệt scope nhạy cảm, không phải làm đánh giá bảo mật**.

Điểm cuối là lý do quyết định. Nếu dùng `drive` hay `drive.readonly` (đọc toàn bộ Drive) thì phải qua quy trình xác minh nặng, có thể phải thuê bên thứ ba đánh giá — không tương xứng với một app cá nhân.

**Đánh đổi:** user không nhìn thấy file backup, không copy sang tài khoản Google khác được. Bù bằng nút **"Xuất file"** ở Cài đặt (dùng `share_plus`) để user tự lưu file JSON đi đâu tuỳ ý. Hai cơ chế bổ sung cho nhau: Drive lo trường hợp đổi điện thoại, xuất file lo trường hợp đổi tài khoản.

### 7.3. Đăng nhập — API đã thay đổi lớn

`google_sign_in` v7 tách **xác thực** (bạn là ai) khỏi **uỷ quyền** (app được làm gì). Đây là thay đổi phá vỡ so với v6, và phần lớn hướng dẫn trên mạng vẫn viết theo v6.

Ba điểm khác biệt cần nắm:

1. Scope **không còn khai lúc khởi tạo** `GoogleSignIn` nữa. Phải xin riêng qua `authorizationClient`.
2. Phải gọi `initialize()` trước mọi thứ khác.
3. `authenticate()` **ném exception** thay vì trả `null` khi thất bại.

```dart
// lib/backup/google_auth.dart
import 'package:google_sign_in/google_sign_in.dart';

const _scopes = <String>['https://www.googleapis.com/auth/drive.appdata'];

class GoogleAuthService {
  bool _initialized = false;
  GoogleSignInAccount? _user;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    );
    _initialized = true;
  }

  /// Đăng nhập có tương tác. CHỈ gọi từ hành động của user (bấm nút).
  Future<String?> signInAndAuthorize() async {
    await _ensureInit();
    try {
      _user = await GoogleSignIn.instance.authenticate();
      final auth = await _user!.authorizationClient.authorizeScopes(_scopes);
      return auth.accessToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Lấy token KHÔNG tương tác. Dùng cho backup nền.
  /// Trả null nếu chưa được cấp quyền — lúc đó phải chờ user bấm nút.
  Future<String?> silentToken() async {
    await _ensureInit();
    _user ??= await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (_user == null) return null;

    final auth = await _user!.authorizationClient.authorizationForScopes(_scopes);
    return auth?.accessToken;
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _user = null;
  }

  String? get email => _user?.email;
}
```

> **Ràng buộc quan trọng cho thiết kế:** `authorizeScopes()` trên một số nền tảng **bắt buộc phải xuất phát từ thao tác của user**, không gọi được từ tiến trình nền. Nghĩa là backup tự động chỉ dùng được `silentToken()`. Nếu nó trả `null` (quyền bị thu hồi, token hỏng), app **không được** tự bật hộp thoại đăng nhập giữa chừng — phải ghi lỗi lại và hiện một dòng ở Cài đặt để user tự bấm. §7.5 xử lý việc này.

### 7.4. Đọc/ghi Drive

Dùng package `googleapis` chính chủ của Google thay vì gọi REST bằng tay:

```dart
// lib/backup/drive_service.dart
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const _fileName = 'motonote-backup.json';

class DriveService {
  drive.DriveApi _api(String accessToken) {
    final credentials = AccessCredentials(
      AccessToken('Bearer', accessToken,
          DateTime.now().toUtc().add(const Duration(minutes: 55))),
      null,
      _scopes,
    );
    return drive.DriveApi(authenticatedClient(http.Client(), credentials));
  }

  Future<drive.File?> _find(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id, modifiedTime, size, appProperties)',
    );
    final files = res.files;
    return (files == null || files.isEmpty) ? null : files.first;
  }

  /// Metadata để hiển thị ở màn hình khôi phục mà chưa cần tải cả file.
  Future<BackupInfo?> peek(String token) async {
    final f = await _find(_api(token));
    if (f == null) return null;
    return BackupInfo(
      modifiedAt: f.modifiedTime,
      sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
      vehicleCount: int.tryParse(f.appProperties?['vehicles'] ?? '0') ?? 0,
      logCount:     int.tryParse(f.appProperties?['logs'] ?? '0') ?? 0,
    );
  }

  Future<void> upload(String token, AppData data) async {
    final api = _api(token);
    final existing = await _find(api);
    final bytes = utf8.encode(jsonEncode(data.toJson()));

    final media = drive.Media(
      Stream.value(bytes), bytes.length,
      contentType: 'application/json',
    );

    // appProperties cho phép màn hình khôi phục hiện tóm tắt
    // mà không phải tải cả file về.
    final meta = drive.File()
      ..appProperties = {
        'vehicles': '${data.vehicles.length}',
        'logs':     '${data.logs.length}',
        'schema':   '${data.schemaVersion}',
      };

    if (existing != null) {
      await api.files.update(meta, existing.id!, uploadMedia: media);
    } else {
      meta
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await api.files.create(meta, uploadMedia: media);
    }
  }

  Future<AppData?> download(String token) async {
    final api = _api(token);
    final f = await _find(api);
    if (f == null) return null;

    final media = await api.files.get(
      f.id!, downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }

    final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return AppData.fromJson(migrateRaw(raw));
  }
}
```

### 7.5. Khi nào backup

```
Tự động (im lặng, không hiện gì):
  · Mở app, nếu lần backup cuối > 24h
  · Sau khi ghi service log hoặc nhập ODO  (gộp lại, chờ 30 giây)
  · Khi app vào nền (AppLifecycleState.paused)

Thủ công:
  · Nút "Sao lưu ngay" ở Cài đặt → hiện kết quả rõ ràng
```

```dart
class BackupService {
  Timer? _debounce;

  void scheduleDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 30), () => runSilent());
  }

  Future<void> runSilent() async {
    final settings = _read().settings;
    if (!settings.driveBackupEnabled) return;

    try {
      final token = await _auth.silentToken();
      if (token == null) {
        // Quyền bị thu hồi. KHÔNG tự bật hộp thoại đăng nhập —
        // chỉ ghi lại để hiện ở Cài đặt.
        await _setError('Cần đăng nhập lại Google');
        return;
      }
      await _drive.upload(token, _read());
      await _setSuccess(DateTime.now());
    } catch (e) {
      await _setError(e.toString());
    }
  }
}
```

Backup tự động **không bao giờ hiện toast hay spinner**. Thất bại thì ghi vào `settings.lastBackupError` và hiện một dòng nhỏ ở Cài đặt: *"Lần sao lưu cuối: 3 ngày trước · Có lỗi"*. Không làm phiền user giữa lúc họ đang làm việc khác.

### 7.6. Khôi phục — ba lớp bảo vệ

Khôi phục là thao tác **ghi đè toàn bộ**, không merge. Đây là chỗ dễ mất dữ liệu nhất trong app.

1. **Chỉ cho khôi phục ở màn hình onboarding**, khi máy chưa có dữ liệu. Sau đó phải vào Cài đặt và xác nhận riêng.
2. **Nếu máy đã có dữ liệu**, hiện đối chiếu rõ ràng trước khi ghi đè:

```
   ┌─────────────────────────────────────┐
   │  Khôi phục sẽ THAY THẾ dữ liệu      │
   │  hiện có trên máy.                  │
   │                                     │
   │  Trên máy:    1 xe · 34 log         │
   │               sửa 2 giờ trước       │
   │                                     │
   │  Trên Drive:  1 xe · 31 log         │
   │               sao lưu 5 ngày trước  │
   │                                     │
   │  ⚠ Bản trên Drive CŨ HƠN            │
   │  ⚠ Ảnh hoá đơn không khôi phục được │
   │                                     │
   │  [ Huỷ ]        [ Vẫn khôi phục ]   │
   └─────────────────────────────────────┘
```

3. **Trước khi ghi đè, lưu bản hiện tại** vào `appdata.pre-restore.json`. Nếu user nhận ra sai, có nút "Hoàn tác khôi phục" tồn tại 7 ngày.

### 7.7. Android Auto Backup — lớp miễn phí

Android có sẵn cơ chế sao lưu dữ liệu app lên Drive của user, tối đa 25 MB, tự động, không cần code và không cần OAuth. Bật bằng `android:allowBackup="true"` trong manifest.

Hạn chế: chỉ khôi phục khi cài lại app trên máy Android mới, không thấy được, không chủ động được, không có trên iOS. Nhưng nó miễn phí và bắt được trường hợp user đổi máy mà quên bật Drive backup. Cứ bật.

---

## 8. Chọn linh kiện & loại nhớt

### 8.1. Catalog

Catalog nằm **cứng trong app** (file Dart), không tải từ server — vì không có server. Cập nhật catalog nghĩa là phát hành bản mới. Với dữ liệu ít thay đổi như chu kỳ bảo dưỡng thì hoàn toàn chấp nhận được.

```dart
// lib/domain/catalog.dart

class CatalogEntry {
  final String code;
  final String nameVi;
  final Set<VehicleType> appliesTo;
  final int? intervalKm;
  final int? intervalMonths;
  final bool defaultOn;      // mặc định tích sẵn lúc onboarding
  final bool isOil;          // dùng picker loại nhớt
  final String? hint;
  final IconData icon;

  const CatalogEntry({
    required this.code,
    required this.nameVi,
    required this.appliesTo,
    required this.icon,
    this.intervalKm,
    this.intervalMonths,
    this.defaultOn = false,
    this.isOil = false,
    this.hint,
  });
}

const kCatalog = <CatalogEntry>[
  CatalogEntry(
    code: 'engine_oil', nameVi: 'Nhớt máy',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 2000, intervalMonths: 3,
    defaultOn: true, isOil: true, icon: Icons.water_drop,
    hint: 'Quan trọng nhất. Chu kỳ đổi theo loại nhớt.',
  ),
  // ... xem Phụ lục A
];

/// Lọc catalog theo loại xe.
List<CatalogEntry> catalogFor(VehicleType type) =>
    kCatalog.where((e) => e.appliesTo.contains(type)).toList();
```

### 8.2. Màn hình chọn hạng mục

Nguyên tắc: **mặc định tích sẵn 6–8 hạng mục quan trọng nhất, phần còn lại gấp lại.**

Hiện 15 checkbox cho người vừa mở app lần đầu là cách nhanh nhất để họ bỏ cuộc. Mặc định đúng quan trọng hơn nhiều so với cho nhiều lựa chọn.

```
┌──────────────────────────────────────┐
│  Theo dõi những gì?                  │
│  Chọn sau cũng được.                 │
│                                      │
│  ☑ Nhớt máy                          │
│     Quan trọng nhất                  │
│  ☑ Nhớt láp                          │
│  ☑ Lọc gió                           │
│  ☑ Bugi                              │
│  ☑ Dây curoa                         │
│  ☑ Má phanh trước                    │
│  ☑ Lốp trước · ☑ Lốp sau             │
│                                      │
│  ▸ 7 hạng mục nâng cao               │
│    Bi nồi, dầu phanh, phuộc,         │
│    bạc đạn, ắc quy...                │
│                                      │
│              [ Tiếp tục ]            │
└──────────────────────────────────────┘
```

Dùng `ExpansionTile` cho phần "hạng mục nâng cao" — Flutter có sẵn, không cần package.

### 8.3. Chọn loại nhớt — chu kỳ tự đổi theo

Đây là chi tiết nhỏ nhưng làm app hữu ích hơn hẳn: **loại nhớt quyết định chu kỳ thay**, và phần lớn người dùng không biết điều đó.

```dart
// lib/domain/oil_presets.dart

class OilPreset {
  final String label;
  final int km;
  final int months;
  final String hint;
  const OilPreset(this.label, this.km, this.months, this.hint);
}

const kOilPresets = <OilGrade, OilPreset>{
  OilGrade.mineral: OilPreset(
    'Nhớt khoáng', 1500, 3,
    'Rẻ nhất, phải thay dày. Nhớt "zin" theo xe thường loại này.',
  ),
  OilGrade.semiSynthetic: OilPreset(
    'Bán tổng hợp', 2500, 4,
    'Phổ biến nhất. Cân bằng giá và chu kỳ.',
  ),
  OilGrade.fullSynthetic: OilPreset(
    'Tổng hợp toàn phần', 3500, 6,
    'Đắt hơn nhưng đi được xa hơn. Hợp với người chạy nhiều.',
  ),
};
```

Khi user chọn loại nhớt ở bước 5, `intervalKm` và `intervalMonths` của hạng mục nhớt máy tự cập nhật, và hiển thị ngay:

> *"Với nhớt bán tổng hợp, app sẽ nhắc bạn mỗi ~2.500 km hoặc 4 tháng."*

User vẫn sửa được con số. Preset chỉ là điểm khởi đầu hợp lý.

**Lưu ý phải ghi trong app:** đây là khoảng khuyến nghị chung. Chạy nội đô kẹt xe, ngập nước, chở nặng thì nên rút ngắn. Sổ tay theo xe của hãng vẫn là căn cứ chính xác nhất cho từng model.

### 8.4. Nhớ quy cách phụ tùng

Mỗi `MaintenanceItem` giữ `partBrand` + `partSpec` của lần thay gần nhất. Lần ghi log sau, form điền sẵn:

```
┌──────────────────────────────────────┐
│  Ghi lại: Nhớt máy                   │
│                                      │
│  Ngày      [ 28/08/2026 ]            │
│  Số km     [ 18420 ]                 │
│  Chi phí   [ 130.000 ] ₫             │
│                                      │
│  Loại nhớt                           │
│  [ Motul 5100 10W-40        ] ▾      │
│    ↳ giống lần trước (02/06)         │
│                                      │
│  Tiệm      [ Tiệm anh Tuấn  ]        │
│                                      │
│              [ Lưu ]                 │
└──────────────────────────────────────┘
```

Ghi log trở thành thao tác vài giây thay vì gõ lại mọi thứ. Đây là kiểu chi tiết quyết định app có được dùng lâu dài hay không.

---

## 9. Ước tính ODO & tính hạn

### 9.1. Công thức

```
odoƯớcTính = odoLầnNhậpCuối + kmMỗiNgày × sốNgàyTừLầnNhậpCuối
```

Hết. Ba biến, một phép nhân.

### 9.2. Tự hiệu chỉnh km/ngày

Con số user khai lúc đầu chỉ là ước lượng thô. Mỗi lần user nhập ODO mới, tính lại con số thật:

```dart
// lib/domain/odo.dart

class RefinedAvg {
  final double avgDailyKm;
  final AvgKmSource source;
  const RefinedAvg(this.avgDailyKm, this.source);
}

RefinedAvg refineAvgDailyKm(
  Vehicle vehicle,
  OdoReading newReading,
  OdoReading? prevReading,
) {
  if (prevReading == null) {
    return RefinedAvg(vehicle.avgDailyKm, vehicle.avgDailyKmSource);
  }

  final days = newReading.date.difference(prevReading.date).inDays;
  final km = newReading.odoKm - prevReading.odoKm;

  // Khoảng cách quá ngắn thì mẫu không đại diện — một ngày đi phượt
  // không nói lên thói quen hàng ngày.
  if (days < 14 || km < 0) {
    return RefinedAvg(vehicle.avgDailyKm, vehicle.avgDailyKmSource);
  }

  final measured = km / days;

  // Lần đo thật đầu tiên: tin hẳn.
  // Các lần sau: làm mượt 70/30 để tránh nhảy giật khi user
  // vừa có một tháng bất thường.
  final smoothed = vehicle.avgDailyKmSource == AvgKmSource.user
      ? measured
      : 0.7 * measured + 0.3 * vehicle.avgDailyKm;

  return RefinedAvg(
    smoothed.clamp(0.5, 400).toDouble(),
    AvgKmSource.computed,
  );
}
```

Sau vài tháng dùng đều, con số này bám khá sát thực tế mà user không phải làm gì thêm.

### 9.3. Tính hạn

```dart
// lib/domain/due.dart

enum DueStatus { ok, dueSoon, dueToday, overdue }
enum DrivenBy { km, time }

class DueResult {
  final DueStatus status;
  final DateTime dueDate;
  final int daysLeft;
  final int? kmLeft;
  final double progress;      // 0..1+
  final DrivenBy drivenBy;
  final bool isEstimate;      // ODO đã cũ hoặc mốc là giả định

  const DueResult({
    required this.status, required this.dueDate, required this.daysLeft,
    required this.progress, required this.drivenBy, required this.isEstimate,
    this.kmLeft,
  });
}

DueResult? computeDue(
  MaintenanceItem item,
  Vehicle vehicle,
  int leadDays, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();

  if (!item.enabled) return null;
  if (item.lastServiceDate == null && item.lastServiceOdo == null) return null;

  final avg = vehicle.avgDailyKm <= 0 ? 0.5 : vehicle.avgDailyKm;
  final daysSinceOdo = n.difference(vehicle.odoUpdatedAt).inDays;
  final estOdo = vehicle.currentOdoKm + (avg * daysSinceOdo).round();

  DateTime? dueByKm;
  int? kmLeft;
  var progress = 0.0;

  if (item.intervalKm != null && item.lastServiceOdo != null) {
    final target = item.lastServiceOdo! + item.intervalKm!;
    kmLeft = target - estOdo;
    progress = 1 - kmLeft / item.intervalKm!;
    dueByKm = n.add(Duration(days: (kmLeft / avg).round()));
  }

  DateTime? dueByTime;
  if (item.intervalMonths != null && item.lastServiceDate != null) {
    final d = item.lastServiceDate!;
    dueByTime = DateTime(d.year, d.month + item.intervalMonths!, d.day);
    final p = _timeProgress(d, dueByTime, n);
    if (p > progress) progress = p;
  }

  // Cái nào tới trước
  final DateTime dueDate;
  final DrivenBy drivenBy;
  if (dueByKm != null && dueByTime != null) {
    if (dueByKm.isBefore(dueByTime)) {
      dueDate = dueByKm; drivenBy = DrivenBy.km;
    } else {
      dueDate = dueByTime; drivenBy = DrivenBy.time;
    }
  } else if (dueByKm != null) {
    dueDate = dueByKm; drivenBy = DrivenBy.km;
  } else {
    dueDate = dueByTime!; drivenBy = DrivenBy.time;
  }

  final daysLeft = _dateOnly(dueDate).difference(_dateOnly(n)).inDays;

  final status = daysLeft < 0
      ? DueStatus.overdue
      : daysLeft == 0
          ? DueStatus.dueToday
          : (daysLeft <= leadDays || progress >= 0.9)
              ? DueStatus.dueSoon
              : DueStatus.ok;

  return DueResult(
    status: status, dueDate: dueDate, daysLeft: daysLeft,
    kmLeft: kmLeft, progress: progress, drivenBy: drivenBy,
    isEstimate: daysSinceOdo > 45 || item.baselineIsGuess,
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
```

> **Bẫy Dart:** `DateTime.difference().inDays` cắt phần lẻ chứ không làm tròn — chênh 23 giờ vẫn ra 0 ngày. Với logic "còn mấy ngày nữa" thì phải chuẩn hoá về đầu ngày trước khi trừ, như hàm `_dateOnly` ở trên. Bỏ qua chi tiết này sẽ tạo ra lỗi lệch một ngày khó tìm.

### 9.4. Hai trục — vì sao không bỏ được trục thời gian

Nhớt biến chất theo thời gian kể cả khi xe đứng yên. Xe để 5 tháng không chạy vẫn phải thay nhớt dù chưa đi đủ km.

Đây là lý do mọi hạng mục có thể mang cả `intervalKm` lẫn `intervalMonths`, và ngày tới hạn luôn là **cái nào đến trước**. Bỏ trục thời gian sẽ làm app sai với những người đi ít — mà ở Hà Nội và TP.HCM thì rất nhiều xe chỉ chạy vài km mỗi ngày.

### 9.5. Nói thật với user khi không chắc

```
ODO cập nhật < 45 ngày, mốc là log thật:
   "Còn 12 ngày nữa tới hạn thay nhớt"

ODO cập nhật > 45 ngày:
   "Còn khoảng 12 ngày · số km đã cũ 2 tháng
    [ Cập nhật số km ]"

Mốc là giả định lúc khởi tạo:
   "Ước tính còn 12 ngày · chưa có mốc thay thật
    [ Tôi vừa thay ]"
```

App nói "khoảng" khi nó chỉ biết khoảng. Người dùng bị nhắc sai vài lần sẽ tắt thông báo, và một khi tắt thì gần như không bật lại.

### 9.6. Test — chỉ hai file này thôi

```dart
// test/domain/due_test.dart
void main() {
  group('computeDue', () {
    test('lấy mốc km khi km tới trước thời gian', () { ... });
    test('lấy mốc thời gian khi xe để lâu không chạy', () { ... });
    test('trả overdue khi đã quá ngày', () { ... });
    test('đánh dấu isEstimate khi ODO cũ hơn 45 ngày', () { ... });
    test('trả null khi hạng mục bị tắt', () { ... });
    test('không chia cho 0 khi avgDailyKm = 0', () { ... });
    test('không lệch 1 ngày khi chênh 23 giờ', () { ... });   // §9.3
  });
}

// test/domain/odo_test.dart
void main() {
  group('refineAvgDailyKm', () {
    test('bỏ qua khi khoảng cách dưới 14 ngày', () { ... });
    test('bỏ qua khi ODO mới nhỏ hơn ODO cũ', () { ... });
    test('tin hẳn lần đo thật đầu tiên', () { ... });
    test('làm mượt 70/30 ở các lần sau', () { ... });
    test('kẹp trong khoảng [0.5, 400]', () { ... });
  });
}
```

Cả hai đều là hàm thuần, không cần mock, không cần widget test. Phần UI kiểm tra bằng tay trên máy thật hiệu quả hơn ở quy mô này.

---

## 10. Thông báo cục bộ

Không có server, nên không có push. Tất cả là **local notification** do chính app lên lịch với hệ điều hành.

Điều này thực ra tốt hơn cho app này: hoạt động cả khi mất mạng, không cần FCM credential, không tốn gì để vận hành.

### 10.1. Ba loại thông báo

| Loại | Khi nào | Tần suất |
|---|---|---|
| **Nhắc cập nhật ODO** | Ngày cố định trong tháng do user chọn | 1 lần/tháng |
| **Sắp tới hạn** | Trước `leadDays` ngày (mặc định 7) | Gộp theo xe, tối đa 1/ngày |
| **Quá hạn** | Đúng ngày tới hạn, rồi mỗi 14 ngày, tối đa 3 lần | 1/2 tuần |

### 10.2. Khởi tạo

`flutter_local_notifications` cần timezone được nạp trước khi lên lịch, nếu không thông báo sẽ bắn sai giờ khi đổi múi giờ hoặc DST.

```dart
// lib/notifications/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,   // xin sau, ở cuối onboarding
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Android bắt buộc phải tạo channel, không thì thông báo im lặng biến mất
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'maintenance',
          'Nhắc bảo dưỡng',
          description: 'Nhắc khi tới hạn thay linh kiện và nhắc cập nhật số km',
          importance: Importance.high,
        ));
  }
}
```

### 10.3. Xin quyền

Hai quyền riêng biệt trên Android, dễ nhầm:

```dart
Future<bool> requestPermissions() async {
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (android != null) {
    // 1. Quyền hiện thông báo (Android 13+)
    final granted = await android.requestNotificationsPermission() ?? false;
    if (!granted) return false;

    // 2. Quyền đặt báo thức chính xác (Android 12+) — quyền RIÊNG.
    //    Không có nó thì thông báo vẫn bắn nhưng có thể trễ vài giờ.
    await android.requestExactAlarmsPermission();
    return true;
  }

  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  return await ios?.requestPermissions(alert: true, badge: true, sound: true)
      ?? false;
}
```

> Từ Android 14, quyền đặt báo thức chính xác **không được tự cấp** khi cài mới — phải xin và xử lý trường hợp bị từ chối. Nếu user từ chối, vẫn lên lịch bình thường nhưng dùng chế độ không chính xác (thông báo có thể trễ vài giờ). Với app nhắc bảo dưỡng thì trễ vài giờ hoàn toàn chấp nhận được — **đừng chặn tính năng chỉ vì thiếu quyền này**.

**Thời điểm xin:** ở cuối onboarding, sau khi user đã thấy xe của mình trên màn hình chính, kèm giải thích:

> *"Bật thông báo để app nhắc bạn khi tới hạn thay nhớt và nhắc cập nhật số km mỗi tháng. Không có thông báo, app chỉ nhắc khi bạn tự mở lên."*

Nếu từ chối, app vẫn phải dùng được đầy đủ — chỉ hiện một dòng nhắc nhẹ ở Cài đặt.

### 10.4. Chiến lược — huỷ hết rồi đặt lại

Đây là mấu chốt của việc làm notification không server cho đúng.

```dart
const _horizonDays = 120;
const _maxScheduled = 30;      // iOS giới hạn 64 tổng, chừa chỗ

Future<void> rescheduleAll(AppData data) async {
  await _plugin.cancelAll();
  if (!data.settings.notificationsEnabled) return;

  final planned = <_Planned>[];
  final now = DateTime.now();

  // ── 1. Nhắc cập nhật ODO hàng tháng ──
  if (data.settings.odoReminderEnabled && data.vehicles.isNotEmpty) {
    for (var m = 0; m < 6; m++) {          // đặt trước 6 tháng
      final v = data.vehicles.first;
      planned.add(_Planned(
        date: _nthMonthDay(now, m, data.settings.odoReminderDayOfMonth,
                           data.settings.notifyHour),
        title: 'Cập nhật số km',
        body: 'Xe ${v.name} đang ở khoảng ${_fmt(estimateOdo(v))} km. '
              'Số thật là bao nhiêu?',
        payload: 'odo:${v.id}',
      ));
    }
  }

  // ── 2. Hạng mục tới hạn, GỘP theo (xe, ngày) ──
  final byDay = <String, _Group>{};

  for (final v in data.vehicles) {
    for (final item in data.items.where((i) => i.vehicleId == v.id)) {
      final due = computeDue(item, v, data.settings.leadDays, now: now);
      if (due == null) continue;

      for (final d in _notifyDatesFor(due, data.settings)) {
        if (d.isBefore(now)) continue;
        if (d.difference(now).inDays > _horizonDays) continue;

        final key = '${v.id}|${_dateKey(d)}';
        byDay.putIfAbsent(key, () => _Group(v, d, []));
        byDay[key]!.itemNames.add(item.name);
      }
    }
  }

  for (final g in byDay.values) {
    final msg = _compose(g.vehicle, g.itemNames);
    planned.add(_Planned(
      date: _atHour(g.date, data.settings.notifyHour),
      title: msg.title, body: msg.body,
      payload: 'due:${g.vehicle.id}',
    ));
  }

  // ── 3. Sắp xếp, cắt theo hạn mức HĐH ──
  planned.sort((a, b) => a.date.compareTo(b.date));

  var id = 0;
  for (final p in planned.take(_maxScheduled)) {
    await _plugin.zonedSchedule(
      id++,
      p.title,
      p.body,
      tz.TZDateTime.from(p.date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance', 'Nhắc bảo dưỡng',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Bắn đúng giờ ngay cả khi máy vào chế độ tiết kiệm pin.
      // Đây là thứ expo-notifications không cho kiểm soát.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: p.payload,
    );
  }
}
```

Gọi `rescheduleAll()` mỗi khi:
- App mở lên (`AppLifecycleState.resumed`)
- Bất kỳ thay đổi state nào — đã tự động nhờ `_mutate` ở §5.2

Chi phí một lần chạy là vài chục mili-giây với dữ liệu ở quy mô này, nên chạy thừa còn hơn thiếu.

**Vì sao đặt từng ngày cụ thể chứ không dùng lịch lặp:** lịch lặp nghe gọn hơn nhưng không tính lại được nội dung thông báo (số km ước tính đổi mỗi ngày), và hành vi của nó không đồng nhất giữa iOS với các ROM Android. Đặt từng ngày rồi đặt lại mỗi lần mở app thì dễ đoán hơn nhiều.

### 10.5. Gộp thông báo

```dart
_Msg _compose(Vehicle v, List<String> items) {
  if (items.length == 1) {
    return _Msg('${v.name} sắp tới hạn', items[0]);
  }
  if (items.length == 2) {
    return _Msg('${v.name} sắp tới hạn', '${items[0]} và ${items[1]}');
  }
  return _Msg(
    '${v.name} có ${items.length} hạng mục sắp tới hạn',
    '${items[0]}, ${items[1]} và ${items.length - 2} mục khác',
  );
}
```

Một xe có thể có 4 hạng mục tới hạn cùng lúc. Gửi 4 thông báo là cách nhanh nhất để bị tắt thông báo.

### 10.6. Vấn đề ROM Android

Xiaomi, Oppo, Vivo, Samsung và nhiều ROM khác thêm một lớp quản lý pin riêng phía trên chế độ Doze chuẩn của Android. Lớp này có thể giết tiến trình app sau vài phút tắt màn hình, chặn báo thức chính xác đánh thức app, và im lặng tắt thông báo của app bị xếp vào diện "đang ngủ" — **kể cả khi đã đặt `exactAllowWhileIdle` đúng cách.**

Đây là vấn đề tầng hệ điều hành, không phải tầng framework. Flutter và React Native chịu như nhau. Không có cách sửa triệt để, chỉ có cách giảm thiểu:

**1. Đặt lại lịch mỗi lần mở app.** Đã có ở §10.4. User mở app định kỳ thì lịch luôn tươi.

**2. Onboarding có bước hướng dẫn tắt tối ưu pin**, phát hiện hãng máy và mở đúng trang cài đặt:

```dart
// lib/notifications/battery_hints.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';

Future<String?> batteryOptimizationHint() async {
  if (!Platform.isAndroid) return null;
  final info = await DeviceInfoPlugin().androidInfo;

  switch (info.manufacturer.toLowerCase()) {
    case 'xiaomi':
    case 'redmi':
    case 'poco':
      return 'Vào Cài đặt → Ứng dụng → MotoNote → Tiết kiệm pin '
             '→ chọn "Không giới hạn", và bật "Tự khởi động".';
    case 'oppo':
    case 'realme':
    case 'oneplus':
      return 'Vào Cài đặt → Pin → Tối ưu hoá pin → MotoNote '
             '→ chọn "Không tối ưu hoá".';
    case 'vivo':
      return 'Vào Cài đặt → Pin → Mức tiêu thụ nền cao → bật MotoNote.';
    case 'samsung':
      return 'Vào Cài đặt → Chăm sóc thiết bị → Pin → Giới hạn sử dụng nền '
             '→ bỏ MotoNote khỏi danh sách "Ứng dụng đang ngủ".';
    default:
      return null;
  }
}

Future<void> openBatterySettings() async {
  const intent = AndroidIntent(
    action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
  );
  await intent.launch();
}
```

**3. Tự phát hiện thông báo bị chết.** Lưu `settings.lastNotificationFiredAt` mỗi khi có thông báo được mở. Nếu quá 45 ngày mà chưa có gì dù đang có hạng mục tới hạn, hiện banner trong app:

> *"Có vẻ thông báo không hoạt động. Xem cách khắc phục."*

Điểm 3 quan trọng hơn vẻ ngoài của nó: nó biến một lỗi thầm lặng — app im re, user tưởng xe vẫn ổn — thành một lỗi nhìn thấy được.

### 10.7. Deep link từ thông báo

```dart
void _onTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;

  final [kind, id] = payload.split(':');
  switch (kind) {
    case 'due':  appRouter.go('/vehicle/$id?tab=due');
    case 'odo':  appRouter.go('/vehicle/$id?sheet=odo');
  }
}
```

Cần xử lý cả trường hợp app đang **bị đóng hoàn toàn** — lúc đó thông báo mở app từ đầu và callback chưa kịp đăng ký:

```dart
// trong main(), sau init()
final launch = await _plugin.getNotificationAppLaunchDetails();
if (launch?.didNotificationLaunchApp ?? false) {
  pendingDeepLink = launch!.notificationResponse?.payload;
  // xử lý sau khi router sẵn sàng
}
```

---

## 11. Màn hình & điều hướng

Bảy màn hình. Không hơn.

```
┌──────────────────────────────────────────────────────┐
│                    Onboarding                        │
│  chào → (khôi phục | thiết lập 6 bước) → quyền       │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│              BottomNavigationBar (3 tab)             │
├─────────────┬────────────────────┬───────────────────┤
│  Trang chủ  │      Ghi chú       │     Cài đặt       │
└──────┬──────┴─────────┬──────────┴─────────┬─────────┘
       │                │                    │
       ▼                ▼                    ▼
┌──────────────┐  ┌──────────┐  ┌──────────────────────┐
│ · thẻ xe     │  │ danh sách│  │ · thông báo          │
│ · hạng mục   │  │ note     │  │ · sao lưu Drive      │
│   gấp nhất   │  │ + ghim   │  │ · xuất file          │
│ · nút ODO    │  └────┬─────┘  │ · quản lý xe/hạng mục│
└──────┬───────┘       │        └──────────────────────┘
       │               ▼
       │        ┌──────────┐
       │        │ Sửa note │
       │        └──────────┘
       ├──────────────────┐
       ▼                  ▼
┌──────────────┐   ┌─────────────┐
│ Chi tiết     │   │ Ghi lại     │
│ hạng mục     │   │ bảo dưỡng   │
│ + lịch sử    │   │(modal sheet)│
└──────────────┘   └─────────────┘
```

### 11.1. Trang chủ

Trả lời một câu hỏi trong 2 giây: *xe tôi có cần làm gì không?*

```
┌────────────────────────────────────┐
│  Vision            29A1-234.56     │
│  ~18.665 km · cập nhật 10 ngày     │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ ⚠  Nhớt máy                  │  │
│  │    Quá hạn 7 ngày · 665 km   │  │
│  │              [ Tôi vừa thay ]│  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ ◔  Lọc gió                   │  │
│  │    Còn 14 ngày               │  │
│  └──────────────────────────────┘  │
│  ────────────────────────────────  │
│  9 hạng mục khác đang ổn        ›  │
│                                    │
│  📌 Xe kêu lạ bên trái, hỏi thợ    │
│                                    │
│           ╭──────────────────╮     │
│           │  Cập nhật số km  │     │
│           ╰──────────────────╯     │
└────────────────────────────────────┘
```

Quy tắc:

- **Chỉ hiện cái cần chú ý.** 9 hạng mục "ổn" gộp một dòng.
- **Nút cập nhật ODO nổi bật nhất** (`FloatingActionButton.extended`) — đó là hành động app cần nhất từ user, và mọi thứ khác phụ thuộc vào nó.
- **Note đang ghim hiện ở đây**, để lúc đi tiệm mở app ra là thấy điều cần nói với thợ.
- **Đỏ chỉ dành cho quá hạn.** Dùng đỏ cho cả "sắp tới hạn" thì user hết nhạy với đỏ.
- Dấu `~` trước số km khi `isEstimate == true`.

### 11.2. Cập nhật ODO — modal sheet, không phải màn hình

```
┌────────────────────────────────────┐
│  Số km hiện tại                    │
│                                    │
│      ┌──────────────────────┐      │
│      │      18 665          │      │
│      └──────────────────────┘      │
│      Lần trước: 18.420 (10 ngày)   │
│                                    │
│  ┌───┬───┬───┐                     │
│  │ 1 │ 2 │ 3 │   [ Lưu ]           │
│  ├───┼───┼───┤                     │
│  │ 4 │ 5 │ 6 │                     │
│  ├───┼───┼───┤                     │
│  │ 7 │ 8 │ 9 │                     │
│  ├───┼───┼───┤                     │
│  │   │ 0 │ ⌫ │                     │
│  └───┴───┴───┘                     │
└────────────────────────────────────┘
```

Điền sẵn giá trị ước tính để user chỉ cần sửa vài chữ số. Bàn phím số tự vẽ (`GridView` với 12 ô), không dùng bàn phím hệ thống — nhanh hơn và không nhảy layout.

Chặn nhập số nhỏ hơn lần trước, trừ khi user xác nhận đã thay đồng hồ.

Dùng `showModalBottomSheet` với `isScrollControlled: true`. Flutter có sẵn, không cần package.

---

## 12. Cấu trúc dự án

```
motonote/
├── lib/
│   ├── main.dart                     # init, hydrate, router
│   │
│   ├── domain/                       # Dart thuần — không import Flutter
│   │   ├── models/
│   │   │   ├── app_data.dart
│   │   │   ├── vehicle.dart
│   │   │   ├── maintenance_item.dart
│   │   │   ├── service_log.dart
│   │   │   └── misc.dart
│   │   ├── catalog.dart              # §8.1 + Phụ lục A
│   │   ├── oil_presets.dart          # §8.3
│   │   ├── due.dart                  # computeDue — §9.3
│   │   └── odo.dart                  # refineAvgDailyKm — §9.2
│   │
│   ├── data/
│   │   ├── app_data_repository.dart  # §5.1
│   │   └── migrations.dart           # §4.4
│   │
│   ├── state/
│   │   ├── app_state.dart            # §5.2
│   │   └── derived.dart              # §5.3
│   │
│   ├── backup/
│   │   ├── google_auth.dart          # §7.3
│   │   ├── drive_service.dart        # §7.4
│   │   ├── backup_service.dart       # §7.5
│   │   └── local_export.dart         # share_plus
│   │
│   ├── notifications/
│   │   ├── notification_service.dart # §10.2–10.4
│   │   └── battery_hints.dart        # §10.6
│   │
│   ├── ui/
│   │   ├── router.dart               # go_router
│   │   ├── onboarding/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── due_card.dart
│   │   │   └── odo_sheet.dart
│   │   ├── log/
│   │   ├── item/
│   │   ├── notes/
│   │   ├── settings/
│   │   └── widgets/                  # dùng chung
│   │
│   └── theme/
│       ├── app_theme.dart
│       └── colors.dart
│
├── test/
│   └── domain/
│       ├── due_test.dart
│       └── odo_test.dart
│
├── android/  ios/  assets/
└── pubspec.yaml
```

**Quy tắc quan trọng:** thư mục `domain/` **không được import `package:flutter/...`**. Nó là Dart thuần. Nhờ vậy toàn bộ logic nghiệp vụ test được bằng `dart test` thường, không cần `flutter test`, chạy nhanh hơn nhiều và không phụ thuộc widget tree.

Không có thư mục `services/`, `utils/`, `helpers/` với hàng chục file nhỏ. Ở quy mô này, chia nhỏ quá mức làm code khó theo dõi hơn chứ không dễ hơn.

---

## 13. Kế hoạch triển khai

Ước lượng cho 1 người làm bán thời gian (~15–20h/tuần), **chưa từng viết Dart**.

### Tuần 0 — Làm quen (3–5 ngày)

Đừng bỏ qua bước này. Vào thẳng dự án thật khi chưa quen ngôn ngữ là cách chắc chắn để viết ra một kiến trúc phải đập đi làm lại ở tuần thứ ba.

```
□ Đọc Dart language tour — tập trung: null safety, async/await,
  const constructor, sealed class, pattern matching
□ Làm xong codelab "Your first Flutter app" của Google
□ Dựng một app 2 màn hình có Riverpod và go_router, không cần đẹp
□ Chạy thử freezed + build_runner một lần cho quen quy trình codegen
□ Cài Flutter DevTools, biết dùng Widget Inspector

✓ Mốc: hiểu vì sao StatelessWidget rebuild, và khi nào cần const
```

### Tuần 1 — Nền móng và dữ liệu

```
□ flutter create, cấu hình lint, cấu trúc thư mục §12
□ Toàn bộ model với freezed + json_serializable
□ AppDataRepository ghi file nguyên tử + fallback
□ Riverpod store với _mutate
□ due.dart + odo.dart + test cho cả hai
□ Onboarding: chào, thiết lập 6 bước

✓ Mốc: tạo được xe, dữ liệu sống sót qua force-stop
```

### Tuần 2–3 — Chức năng chính

```
□ Trang chủ: thẻ xe, DueCard, sắp theo độ gấp
□ Modal sheet cập nhật ODO + bàn phím số tự vẽ
□ Modal sheet ghi bảo dưỡng, chọn nhiều hạng mục
□ Màn hình chi tiết hạng mục + lịch sử
□ Nhớ quy cách phụ tùng, điền sẵn lần sau
□ Ghi chú: CRUD + ghim

✓ Mốc: dùng thật cho xe của mình được rồi

⚠ Đây là giai đoạn dài nhất vì phải vừa học layout Flutter vừa làm.
  Row/Column/Expanded/Flexible sẽ mất vài ngày để có phản xạ.
```

### Tuần 4 — Thông báo

```
□ NotificationService: init, timezone, channel
□ Xin quyền đúng thời điểm (2 quyền riêng trên Android)
□ rescheduleAll: huỷ hết + đặt lại
□ Nhắc ODO hàng tháng
□ Gộp thông báo theo xe
□ Deep link, kể cả khi app đang đóng
□ battery_hints theo hãng máy

✓ Mốc: chỉnh đồng hồ máy, nhận đúng thông báo đúng giờ.
   Test trên ít nhất một máy Xiaomi hoặc Samsung thật.
```

### Tuần 5 — Google Drive

```
□ Tạo project Google Cloud, bật Drive API
□ OAuth client cho Android + iOS
□ google_sign_in v7: initialize → authenticate → authorizeScopes
□ DriveService: peek / upload / download
□ Backup tự động (chỉ silentToken) + nút thủ công
□ Màn hình khôi phục có đối chiếu + hoàn tác
□ Xuất file cục bộ

✓ Mốc: cài lại app trên máy khác, khôi phục đủ dữ liệu

⚠ Phần OAuth luôn tốn thời gian hơn dự kiến. SHA-1 fingerprint của
  Android phải khớp giữa debug key, release key và Play App Signing
  key — ba key khác nhau, thiếu cái nào thì đăng nhập THẤT BẠI IM LẶNG,
  không có thông báo lỗi rõ ràng.
```

### Tuần 6–7 — Hoàn thiện và phát hành

```
□ Cài đặt: quản lý xe, hạng mục, chu kỳ
□ Empty state, xử lý lỗi, trạng thái chờ
□ Theme, icon, splash
□ Ảnh chụp màn hình cho store
□ Chính sách quyền riêng tư (bắt buộc vì có OAuth)
□ Data Safety (Play) / App Privacy (Apple)
□ Xác minh OAuth cơ bản với Google
□ Nộp internal testing / TestFlight

✓ Mốc: 5 người dùng thật trong 2 tuần
```

**Tổng: ~7 tuần bán thời gian**, trong đó khoảng 2 tuần là chi phí học Flutter. Nếu đã quen Dart thì rút còn ~5 tuần.

### 13.1. Nếu cần ra sớm hơn

Cắt theo thứ tự này, cắt từ trên xuống:

```
4. Google Drive backup    ← thay tạm bằng nút xuất file cục bộ
3. Ghi chú                ← dù nó nằm trong tên app
2. Thông báo nâng cao     ← chỉ giữ nhắc ODO hàng tháng
1. Engine + ghi bảo dưỡng ← KHÔNG CẮT
```

Tuần 0 + 1 + 2–3 đã là app dùng được thật — khoảng 4 tuần.

### 13.2. Nguyên tắc chống phình scope

Bản v2 và v3 tồn tại chính vì v1 đã phình. Mọi ý tưởng mới trong lúc làm ghi vào một file `BACKLOG.md`, không chèn vào bản đang làm. Xem lại backlog sau khi app đã chạy được 2 tuần với người dùng thật — lúc đó mới biết cái nào thật sự cần.

### 13.3. Việc đầu tiên sau khi ra bản 1.0

**Nhật ký đổ xăng.** Nó giải quyết đúng vấn đề mà Google Maps định giải quyết — giảm số lần phải nhập ODO thủ công.

Người đi xe máy đổ xăng mỗi tuần, và lúc đó mắt đang nhìn thẳng vào đồng hồ. Nếu app có màn hình ghi đổ xăng thật nhanh (ngày, số tiền, số km), thì:

- User có lý do riêng để mở app (theo dõi tiền xăng, tính mức tiêu thụ L/100km)
- Nhập ODO trở thành **tác dụng phụ tự nhiên** của việc họ vốn muốn làm
- Tần suất nhập ODO tăng từ 1 lần/tháng lên ~4 lần/tháng → ước tính chính xác hơn hẳn

Chi phí: một màn hình form và một model class.

---

## 14. Ghi chú cho người mới Dart/Flutter

Những chỗ hay vấp nhất khi sang từ React/TypeScript.

### 14.1. Khác biệt tư duy

| React | Flutter | Ghi chú |
|---|---|---|
| Component + JSX | Widget + cây constructor | Mọi thứ là widget, kể cả padding và alignment |
| `useState` | `StatefulWidget` / Riverpod | Với app này gần như luôn dùng Riverpod, `StatefulWidget` chỉ cho animation và controller |
| CSS / Tailwind | Thuộc tính widget | Không có stylesheet. Style nằm trong constructor |
| Flexbox | `Row` / `Column` / `Expanded` | Gần giống nhưng `Expanded` bắt buộc trong nhiều tình huống mà flexbox không cần |
| `undefined` / `null` | Chỉ `null`, có null safety | `String?` khác `String`. Trình biên dịch bắt lỗi ngay, đây là điểm mạnh |
| `map()` trả JSX | `map().toList()` | **Dễ quên `.toList()`** — `map` trả `Iterable` lười, widget không nhận |
| Optional chaining `?.` | Giống hệt | Cộng thêm `??`, `??=`, `!` (khẳng định không null) |

### 14.2. Bảy lỗi sẽ gặp trong tuần đầu

**1. Quên `const`.** Widget không đổi mà không đánh dấu `const` sẽ rebuild vô ích. Bật lint `prefer_const_constructors` để IDE tự nhắc.

**2. `setState` trong `build()`.** Gây vòng lặp vô hạn. Với Riverpod thì hầu như không gặp, nhưng nếu gặp thì đây là nguyên nhân.

**3. Dùng `BuildContext` sau `await`.** Widget có thể đã bị gỡ khỏi cây. Luôn kiểm tra:
```dart
await doSomething();
if (!context.mounted) return;
Navigator.pop(context);
```
Đây là lỗi phổ biến nhất và lint sẽ cảnh báo — đừng bỏ qua cảnh báo đó.

**4. `Column` bên trong `Column` không có `Expanded`** → lỗi tràn layout với sọc vàng đen. Đọc kỹ khái niệm ràng buộc (constraints) một lần, sẽ tiết kiệm nhiều giờ.

**5. `ListView` bên trong `Column`** → cần `Expanded` bọc ngoài, hoặc `shrinkWrap: true`.

**6. Quên chạy `build_runner` sau khi sửa model freezed** → lỗi biên dịch khó hiểu. Dùng `dart run build_runner watch` trong lúc phát triển.

**7. `DateTime.difference().inDays` cắt phần lẻ.** Đã nói ở §9.3, nhưng nhắc lại vì nó sẽ gây lỗi lệch một ngày rất khó tìm.

### 14.3. Công cụ

```
flutter analyze                    # bắt buộc chạy trước mỗi commit
dart format .                      # định dạng, không tranh cãi
dart run build_runner watch        # sinh code freezed liên tục
flutter test                       # unit test
flutter run --release              # BẮT BUỘC test bản release riêng
```

Dòng cuối quan trọng: bản debug chạy JIT nên chậm hơn nhiều, còn bản release AOT có thể bộc lộ lỗi khác (nhất là phần OAuth và thông báo). **Đừng đánh giá hiệu năng hay kết luận về lỗi chỉ dựa trên bản debug.**

Cài thêm extension Flutter + Dart cho VS Code. Widget Inspector trong DevTools là công cụ hữu ích nhất để hiểu vì sao layout ra như vậy.

---

## 15. Rủi ro

| # | Rủi ro | Giảm thiểu |
|---|---|---|
| R1 | **User không cập nhật ODO** → mọi dự đoán trôi | Nhắc hàng tháng; nút ODO nổi bật nhất trang chủ; điền sẵn giá trị ước tính; làm nhật ký đổ xăng ở v1.1 (§13.3) |
| R2 | **Mất dữ liệu vì máy hỏng/mất mà chưa backup** | Nhắc bật Drive backup cuối onboarding; bật `allowBackup` Android làm lưới an toàn; hiện "lần sao lưu cuối" ngay ở Cài đặt |
| R3 | **File JSON hỏng giữa lúc ghi** | Ghi nguyên tử qua file tạm + rename; giữ bản dự phòng ngay trước đó (§5.1) |
| R4 | **Khôi phục ghi đè nhầm dữ liệu mới hơn** | Đối chiếu rõ ràng trước khi ghi đè; lưu bản trước khôi phục, cho hoàn tác 7 ngày (§7.6) |
| R5 | **Thông báo bị ROM Android giết** | Đặt lại lịch mỗi lần mở app; `exactAllowWhileIdle`; hướng dẫn theo hãng máy; tự phát hiện "lâu rồi không có thông báo nào" (§10.6) |
| R6 | **OAuth cấu hình sai** → đăng nhập thất bại im lặng | Test trên bản release thật, không chỉ debug; kiểm tra đủ ba SHA-1 |
| R7 | **`google_sign_in` v7 API khác hoàn toàn tài liệu cũ trên mạng** | Chỉ đọc README chính thức của package, bỏ qua mọi bài viết trước 2025 (§7.3) |
| R8 | **Đường học Dart/Flutter dài hơn dự kiến** | Tuần 0 dành riêng để học; giữ `domain/` là Dart thuần để phần logic khó nhất không bị vướng vào Flutter |
| R9 | **Chu kỳ mặc định sai với model xe cụ thể** | Cho sửa mọi chu kỳ; ghi rõ "khuyến nghị chung, sổ tay theo xe chính xác hơn"; preset theo loại nhớt để sát hơn |
| R10 | **Phình scope trở lại** | BACKLOG.md, không chèn ý tưởng mới vào bản đang làm (§13.2) |

---

## Phụ lục A — Catalog linh kiện

```dart
const kCatalog = <CatalogEntry>[
  // ══════════════ ĐỘNG CƠ ══════════════
  CatalogEntry(code: 'engine_oil', nameVi: 'Nhớt máy',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 2000, intervalMonths: 3, defaultOn: true, isOil: true,
    icon: Icons.water_drop,
    hint: 'Quan trọng nhất. Chu kỳ đổi theo loại nhớt.'),

  CatalogEntry(code: 'gear_oil', nameVi: 'Nhớt láp (hộp số)',
    appliesTo: {VehicleType.scooter},
    intervalKm: 8000, intervalMonths: 12, defaultOn: true, isOil: true,
    icon: Icons.opacity,
    hint: 'Thường thay sau mỗi 3–4 lần thay nhớt máy.'),

  CatalogEntry(code: 'oil_filter', nameVi: 'Lọc nhớt',
    appliesTo: {VehicleType.manual},
    intervalKm: 8000, intervalMonths: 12, defaultOn: true,
    icon: Icons.filter_alt),

  CatalogEntry(code: 'coolant', nameVi: 'Nước làm mát',
    appliesTo: {VehicleType.scooter, VehicleType.manual},
    intervalKm: 12000, intervalMonths: 24,
    icon: Icons.thermostat, hint: 'Chỉ xe có két nước.'),

  CatalogEntry(code: 'spark_plug', nameVi: 'Bugi',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 10000, intervalMonths: 12, defaultOn: true,
    icon: Icons.bolt),

  CatalogEntry(code: 'air_filter', nameVi: 'Lọc gió',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 10000, intervalMonths: 12, defaultOn: true,
    icon: Icons.air, hint: 'Chạy đường bụi nhiều thì thay sớm hơn.'),

  CatalogEntry(code: 'cvt_air_filter', nameVi: 'Lọc gió nồi',
    appliesTo: {VehicleType.scooter}, intervalKm: 8000, icon: Icons.air),

  CatalogEntry(code: 'injector', nameVi: 'Vệ sinh kim phun',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 15000, intervalMonths: 24, icon: Icons.cleaning_services),

  CatalogEntry(code: 'valve', nameVi: 'Chỉnh khe hở xu-páp',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 15000, icon: Icons.settings),

  // ══════════════ TRUYỀN ĐỘNG ══════════════
  CatalogEntry(code: 'cvt_belt', nameVi: 'Dây curoa',
    appliesTo: {VehicleType.scooter},
    intervalKm: 18000, intervalMonths: 24, defaultOn: true,
    icon: Icons.autorenew, hint: 'Đứt giữa đường là phải kéo xe về.'),

  CatalogEntry(code: 'cvt_rollers', nameVi: 'Bi nồi',
    appliesTo: {VehicleType.scooter}, intervalKm: 18000,
    icon: Icons.circle, hint: 'Thường thay cùng lúc với dây curoa.'),

  CatalogEntry(code: 'cvt_clutch', nameVi: 'Bố ba càng',
    appliesTo: {VehicleType.scooter}, intervalKm: 20000, icon: Icons.album),

  CatalogEntry(code: 'chain_lube', nameVi: 'Bôi trơn xích',
    appliesTo: {VehicleType.underbone, VehicleType.manual},
    intervalKm: 500, icon: Icons.link,
    hint: 'Chu kỳ ngắn, bật nếu bạn tự làm.'),

  CatalogEntry(code: 'chain_adjust', nameVi: 'Căng chỉnh xích',
    appliesTo: {VehicleType.underbone, VehicleType.manual},
    intervalKm: 2000, defaultOn: true, icon: Icons.link),

  CatalogEntry(code: 'chain_set', nameVi: 'Nhông xích đĩa',
    appliesTo: {VehicleType.underbone, VehicleType.manual},
    intervalKm: 18000, defaultOn: true, icon: Icons.settings_ethernet,
    hint: 'Thay cả bộ, không thay lẻ.'),

  // ══════════════ PHANH ══════════════
  CatalogEntry(code: 'brake_pad_f', nameVi: 'Má phanh trước',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 18000, defaultOn: true, icon: Icons.stop_circle),

  CatalogEntry(code: 'brake_pad_r', nameVi: 'Má phanh sau',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 22000, defaultOn: true, icon: Icons.stop_circle),

  CatalogEntry(code: 'brake_fluid', nameVi: 'Dầu phanh',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 20000, intervalMonths: 24,
    icon: Icons.water_drop, hint: 'Chỉ xe phanh đĩa.'),

  // ══════════════ LỐP & KHUNG GẦM ══════════════
  CatalogEntry(code: 'tire_front', nameVi: 'Lốp trước',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 20000, intervalMonths: 36, defaultOn: true,
    icon: Icons.trip_origin),

  CatalogEntry(code: 'tire_rear', nameVi: 'Lốp sau',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 18000, intervalMonths: 36, defaultOn: true,
    icon: Icons.trip_origin, hint: 'Mòn nhanh hơn lốp trước.'),

  CatalogEntry(code: 'fork_oil', nameVi: 'Dầu phuộc trước',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 25000, intervalMonths: 36, icon: Icons.height),

  CatalogEntry(code: 'bearings', nameVi: 'Bạc đạn cổ, bánh xe',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 25000, icon: Icons.circle_outlined),

  // ══════════════ ĐIỆN & KHÁC ══════════════
  CatalogEntry(code: 'battery', nameVi: 'Ắc quy',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalMonths: 30, defaultOn: true, icon: Icons.battery_full,
    hint: 'Chỉ tính theo thời gian, không theo km.'),

  CatalogEntry(code: 'insurance', nameVi: 'Bảo hiểm TNDS',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalMonths: 12, defaultOn: true, icon: Icons.description),
];
```

**Ghi chú:** đây là khoảng khuyến nghị chung cho điều kiện sử dụng đô thị. Chạy nội đô kẹt xe, ngập nước, chở nặng thì rút ngắn. Sổ tay theo xe của hãng vẫn là căn cứ chính xác nhất — nên ghi câu này trong app, ở màn hình chỉnh chu kỳ.

Về quy định kiểm định khí thải xe mô tô: nội dung pháp lý này đang trong quá trình triển khai theo lộ trình. Vì catalog nằm cứng trong app, khi có quy định cụ thể thì thêm một entry `emission_check` với `intervalMonths` phù hợp và phát hành bản mới. Nên kiểm tra quy định hiện hành tại thời điểm phát hành.

---

## Phụ lục B — Checklist phát hành

### Google Cloud & OAuth

```
□ Tạo project trên Google Cloud Console
□ Bật Google Drive API
□ OAuth consent screen: tên app, logo, email hỗ trợ
□ Khai đúng scope: CHỈ drive.appdata (non-sensitive)
□ URL chính sách quyền riêng tư công khai (BẮT BUỘC)
□ OAuth client Android: package name + SHA-1
   · SHA-1 của debug keystore (dev)
   · SHA-1 của release keystore
   · SHA-1 của Play App Signing (lấy sau khi upload lần đầu)
□ OAuth client iOS: bundle ID
□ Web client ID (dùng cho serverClientId trong google_sign_in v7)
□ Nộp xác minh app cơ bản
```

Thiếu SHA-1 nào thì đăng nhập trên bản build tương ứng sẽ **thất bại im lặng** — không báo lỗi rõ ràng. Đây là lỗi tốn thời gian nhất khi làm phần này.

### Android

```
□ minSdkVersion phù hợp với flutter_local_notifications
□ Quyền trong AndroidManifest:
   · POST_NOTIFICATIONS
   · SCHEDULE_EXACT_ALARM (và/hoặc USE_EXACT_ALARM)
   · RECEIVE_BOOT_COMPLETED  ← để lịch sống sót sau khi khởi động lại máy
□ android:allowBackup="true"
□ Bật minify/shrink cho bản release
□ Split ABI khi build appbundle để giảm dung lượng tải
```

Thiếu `RECEIVE_BOOT_COMPLETED` thì mọi thông báo đã lên lịch sẽ mất sau khi user khởi động lại điện thoại. Dễ quên vì lúc phát triển hiếm khi khởi động lại máy.

### iOS

```
□ Info.plist: mô tả rõ mục đích dùng thông báo
□ URL scheme cho Google Sign-In (REVERSED_CLIENT_ID)
□ Background modes nếu cần
```

### Kỹ thuật

```
□ flutter analyze không còn cảnh báo
□ Dữ liệu sống sót qua force-stop và khởi động lại máy
□ App chạy đủ chức năng khi CHƯA từng đăng nhập Google
□ Thông báo bắn đúng sau khi khởi động lại máy
□ Migration chạy đúng từ mọi phiên bản schema trước
□ Test bản --release, không chỉ debug
□ Test trên máy Android tầm thấp thật (RAM 3–4GB)
□ Test trên máy Xiaomi hoặc Samsung — thông báo có sống không
```

### Store

```
□ Icon 1024×1024, nền đục
□ Ảnh chụp màn hình cho cả iOS và Android
□ Chính sách quyền riêng tư (bắt buộc vì có OAuth)
□ Data Safety (Play): khai rõ dữ liệu chỉ lưu trên máy
   và trên Google Drive của chính user
□ App Privacy (Apple): tương tự
□ Nút xoá dữ liệu trong app (bắt buộc cả hai store)
□ Danh mục: Auto & Vehicles
□ Từ khoá: bảo dưỡng xe máy, nhắc thay nhớt, sổ tay xe máy
```

Vì app không có server, phần khai báo Data Safety rất gọn — không thu thập, không chia sẻ, dữ liệu ở trên máy và trên Drive của chính người dùng. Đây là lợi thế thật của kiến trúc này, và cũng là điểm nên nói rõ trong mô tả trên store.

---

*Hết. Phiên bản 3.0 — 2026-08-28*
