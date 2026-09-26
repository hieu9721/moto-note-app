# Constraints

All entries extracted from the single SPEC-classified source in the ingest set.
Source document is Vietnamese; content is rendered in English with Vietnamese domain terms and UI copy preserved verbatim.

---

## Dependency manifest (pubspec.yaml)
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3.1
- type: schema
- content:
  dependencies — flutter (sdk); flutter_riverpod ^2.6.0; go_router ^14.0.0; freezed_annotation ^3.0.0;
  json_annotation ^4.9.0; path_provider ^2.1.0; flutter_local_notifications ^18.0.0; timezone ^0.10.0;
  flutter_timezone ^4.0.0; permission_handler ^11.3.0 (request permissions + open system settings);
  google_sign_in ^7.1.0; googleapis ^13.2.0; extension_google_sign_in_as_googleapis_auth ^3.0.0;
  intl ^0.19.0 (date, number, VND formatting); share_plus ^10.0.0 (manual file export);
  device_info_plus ^11.0.0 (detect manufacturer for battery-optimisation guidance);
  android_intent_plus ^5.0.0 (open the right per-manufacturer settings page).
  dev_dependencies — build_runner ^2.4.0; freezed ^3.0.0; json_serializable ^6.8.0; flutter_lints ^5.0.0; flutter_test (sdk).
  Constraint: these version numbers are reference points, not commitments — verify with `flutter pub outdated`
  and read the `google_sign_in` and `freezed` CHANGELOGs before writing code.

## Architecture topology
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3
- type: protocol
- content:
  On-device: Widgets <-> Riverpod <-> AppDataRepository -> appdata.json (file).
  Four consumers hang off that: due engine (pure Dart), notifier (flutter_local_notifications),
  backup (googleapis), export (share_plus).
  Platform edges: AlarmManager / UNUserNotificationCenter; HTTPS to Google Drive appDataFolder
  holding `motonote-backup.json` (hidden), scope `drive.appdata`.
  Constraint: no first-party server appears anywhere in this diagram.

## Root document schema: AppData
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.1
- type: schema
- content:
  `const int kSchemaVersion = 1;`
  AppData (freezed, file lib/domain/models/app_data.dart):
    schemaVersion int, default kSchemaVersion
    updatedAt DateTime, required
    deviceLabel String, default ''
    vehicles List<Vehicle>, default []
    items List<MaintenanceItem>, default []
    logs List<ServiceLog>, default []
    odoReadings List<OdoReading>, default []
    notes List<Note>, default []
    settings Settings, required
  Factories: `AppData.fromJson`, and `AppData.empty()` = updatedAt now + const Settings().

## Sub-model schema: Vehicle
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.2
- type: schema
- content:
  enum VehicleType { scooter (tay ga), underbone (xe số), manual (côn tay) }
  enum OilGrade { mineral, semiSynthetic, fullSynthetic }
  enum AvgKmSource { user, computed }
  Vehicle: id String required (nanoid / uuid v4); name String required; type VehicleType required;
    plate String?; brand String?; model String?; year int?;
    photoPath String? (local path — NOT backed up);
    currentOdoKm int required; odoUpdatedAt DateTime required;
    avgDailyKm double required; avgDailyKmSource AvgKmSource default AvgKmSource.user;
    createdAt DateTime required.
  Note: Vehicle has 14 fields — the stated reason for adopting Freezed's generated `copyWith`.

## Sub-model schema: MaintenanceItem
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.2
- type: schema
- content:
  MaintenanceItem: id String required; vehicleId String required;
    catalogCode String required ('engine_oil' — looked up in the catalog for icon and hint);
    name String required (user-editable);
    intervalKm int?; intervalMonths int?; enabled bool default true;
    lastServiceOdo int?; lastServiceDate DateTime?; baselineIsGuess bool default true;
    partBrand String? ("Motul"); partSpec String? ("5100 10W-40");
    oilGrade OilGrade? (oil items only); lastCostVnd int?; notes String?.
  The last-service fields are updated when a log is recorded; the part fields prefill the next log form.

## Sub-model schema: ServiceLog and ServiceLogEntry
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.2
- type: schema
- content:
  ServiceLogEntry: itemId String required; costVnd int?; partBrand String?; partSpec String?;
    resetsCycle bool default true (false = inspected only, not yet replaced).
  ServiceLog: id String required; vehicleId String required; date DateTime required; odoKm int required;
    shopName String?; totalCostVnd int?; note String?;
    photoPaths List<String> default [] (local, not backed up);
    entries List<ServiceLogEntry> default [].

## Sub-model schema: OdoReading, Note, Settings
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.2
- type: schema
- content:
  enum OdoSource { manual, service, setup }
  OdoReading: id, vehicleId, odoKm int, date DateTime, source OdoSource default manual.
  Note: id required; vehicleId String?; itemId String?; title String?; body String default '';
    pinned bool default false; createdAt DateTime required; updatedAt DateTime required.
  Settings: notificationsEnabled bool default true; odoReminderEnabled bool default true;
    odoReminderDayOfMonth int default 1 (range 1–28); notifyHour int default 8 (range 0–23, device time);
    leadDays int default 7; driveBackupEnabled bool default false;
    lastBackupAt DateTime?; lastBackupError String?;
    googleEmail String? (display only — shows where backups go);
    lastNotificationFiredAt DateTime?.
  Codegen: `dart run build_runner build --delete-conflicting-outputs`, or `watch` during development.

## Migration contract
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.4
- type: schema
- content:
  `migrateRaw(Map<String, dynamic> raw)` in lib/data/migrations.dart must run for both local data and
  restored data, because a Drive backup may be older than the running app.
  Reads `data['schemaVersion'] as int?` defaulting to 0, applies stepwise upgrades, then sets
  `data['schemaVersion'] = kSchemaVersion`.
  Illustrated step: `if (from < 2)` — v1 -> v2 adds `avgDailyKmSource` = 'user' to every vehicle.
  Rule: add fields only; never rename, never delete. Unknown fields are ignored by `json_serializable`.

## Atomic local write protocol
- source: D:/Projects/moto-note/motonote-v3-flutter.md §5.1
- type: protocol
- content:
  AppDataRepository (lib/data/app_data_repository.dart). Files in `getApplicationDocumentsDirectory()`:
  `appdata.json` (primary), `appdata.backup.json` (fallback), `appdata.json.tmp` (staging).
  save(data): (1) write JSON to `.tmp` with `flush: true`; (2) if the target exists, copy it to
  `appdata.backup.json`; (3) `tmp.rename(target)` — rename is atomic on most filesystems, so it either
  fully succeeds or does not happen.
  load(): if the primary file is missing, fall back. On decode failure, log and fall back.
  Both paths run `migrateRaw` before `AppData.fromJson`. Fallback returns null if it also fails.
  Stated risk being mitigated: the app is killed mid-write, the file is truncated, and all data is lost.
  Step 2 caps the worst case at losing one operation instead of everything.

## State mutation invariant (`_mutate`)
- source: D:/Projects/moto-note/motonote-v3-flutter.md §5.2
- type: protocol
- content:
  lib/state/app_state.dart. `AppNotifier extends Notifier<AppData>`; exposed as
  `final appProvider = NotifierProvider<AppNotifier, AppData>(AppNotifier.new);`
  `hydrate()` is called once at startup before the UI renders; returns false when no data exists,
  which routes to onboarding.
  Every change goes through exactly one function `_mutate`, which always does three things in order:
  set state with `updatedAt: DateTime.now()`, `await _repo.save(state)`,
  `await notificationScheduler.rescheduleAll(state)`, then `backupService.scheduleDebounced()`.
  Constraint: there must be no path that mutates state while skipping any of these.
  Defined operations include `addOdoReading` (appends an OdoReading, calls `refineAvgDailyKm`, updates
  the vehicle's currentOdoKm / odoUpdatedAt / avgDailyKm / avgDailyKmSource) and `addServiceLog`
  (appends the log, appends a derived OdoReading with `source: OdoSource.service`, and for entries with
  `resetsCycle` updates the item's lastServiceOdo, lastServiceDate, `baselineIsGuess = false`,
  partBrand, partSpec, lastCostVnd).

## Derived-state provider
- source: D:/Projects/moto-note/motonote-v3-flutter.md §5.3
- type: protocol
- content:
  `dueItemsProvider = Provider.family<List<DueItem>, String>` keyed by vehicleId. Computes `computeDue`
  for every enabled item of that vehicle and sorts by `due.daysLeft` ascending.
  Constraint: widgets must not compute item status themselves — Riverpod computes and caches it.

## Data-volume budget
- source: D:/Projects/moto-note/motonote-v3-flutter.md §2
- type: nfr
- content:
  1 vehicle x 15 maintenance items x a few hundred logs across several years is under 200 KB.
  The whole dataset is expected to fit comfortably in RAM. This budget is the stated justification for
  the single-document architecture and for rejecting an embedded database.

## First-run flow
- source: D:/Projects/moto-note/motonote-v3-flutter.md §6
- type: protocol
- content:
  Welcome screen ("MotoNote · Nhắc bảo dưỡng xe máy") offers two paths:
  A) "Khôi phục từ Google Drive" -> choose Google account -> find backup -> show summary
     (e.g. "24/08 · 1 xe · 34 log · 187KB") with the warning "⚠ Ảnh hoá đơn không khôi phục được"
     -> [ Khôi phục ] or [ Bắt đầu mới ].
  B) "Bắt đầu mới" -> 6 steps: (1) vehicle type — Tay ga / Xe số / Côn tay; (2) name and plate (skippable);
     (3) km — current ODO plus average km per day; (4) choose maintenance items; (5) oil grade, which
     auto-adjusts the interval; (6) when was the oil last changed.
  Both paths converge on the notification-permission request, then the home screen.

## Onboarding baseline seeding (step 6)
- source: D:/Projects/moto-note/motonote-v3-flutter.md §6.1
- type: protocol
- content:
  Problem: the app must remind correctly from day one but has no real service history.
  Mapping of the answer to seeded values:
    "Dưới 1 tháng"  -> lastServiceDate = today − 15 days;  lastServiceOdo = ODO − 15 × avgDaily
    "1–3 tháng"     -> lastServiceDate = today − 60 days;  lastServiceOdo = ODO − 60 × avgDaily
    "Trên 3 tháng"  -> lastServiceDate = today − 100 days; lastServiceOdo = ODO − 100 × avgDaily
    "Không nhớ"     -> lastServiceDate = today;            lastServiceOdo = current ODO
  All four cases set `baselineIsGuess = true`.
  "Không nhớ" deliberately anchors to today so the app stays silent for a full cycle — silence is
  preferred over a wrong reminder — but the item must show a "chưa có mốc thật" badge with the prompt
  "Bạn vừa thay nhớt? Ghi lại để app tính đúng".
  Constraint: ask this step for engine oil only. All other items default to "không nhớ". Asking 12
  questions is the fastest way to make the user quit.

## User-facing framing of Google sign-in
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.1
- type: protocol
- content:
  Three statements the app must make: (1) "Không có tài khoản MotoNote." — no email, no password, no
  app server holding data; (2) "Có đăng nhập Google, và chỉ khi bạn bật backup." — data goes straight
  from the phone to the user's Drive; (3) "App chỉ thấy đúng file của nó." — it cannot read photos,
  documents or anything else in Drive. The third statement is technically enforced by §7.2, not marketing.

## Drive `appDataFolder` scope properties
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.2
- type: api-contract
- content:
  Scope: `https://www.googleapis.com/auth/drive.appdata`. Properties relied upon:
  each app gets its own folder that no other app can read; the folder is completely hidden from the
  Drive UI so the user cannot see or accidentally delete it; Google classifies the scope as
  non-sensitive, requiring only basic app verification — no sensitive-scope review, no security assessment.
  Accepted trade-off: the user cannot see the backup file or copy it to another Google account.
  Mitigation: an "Xuất file" button in Settings using `share_plus`.

## google_sign_in v7 authorization contract
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.3
- type: api-contract
- content:
  v7 separates authentication (who you are) from authorization (what the app may do); this is a
  breaking change from v6 and most online guidance still describes v6.
  Three differences: (1) scopes are no longer declared when constructing `GoogleSignIn` — they must be
  requested via `authorizationClient`; (2) `initialize()` must be called before anything else;
  (3) `authenticate()` throws instead of returning null on failure.
  GoogleAuthService (lib/backup/google_auth.dart):
    `_ensureInit()` -> `GoogleSignIn.instance.initialize(serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'))`
    `signInAndAuthorize()` — interactive; ONLY callable from a user action. Calls `authenticate()` then
      `authorizationClient.authorizeScopes(_scopes)`; returns accessToken. Catches `GoogleSignInException`
      and returns null when `e.code == GoogleSignInExceptionCode.canceled`, otherwise rethrows.
    `silentToken()` — non-interactive, used for background backup. Calls
      `attemptLightweightAuthentication()` then `authorizationClient.authorizationForScopes(_scopes)`;
      returns null when not authorized.
    `signOut()`, `email` getter.
  Hard constraint: `authorizeScopes()` on some platforms must originate from a user gesture and cannot
  run in the background, so automatic backup may use `silentToken()` only.

## Drive read/write API surface
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.4
- type: api-contract
- content:
  lib/backup/drive_service.dart, using the first-party `googleapis` package rather than hand-rolled REST.
  Remote file name: `motonote-backup.json`.
  `_api(accessToken)` builds `drive.DriveApi` from `AccessCredentials(AccessToken('Bearer', token, now+55min), null, _scopes)`.
  `_find(api)` -> `api.files.list(spaces: 'appDataFolder', q: "name = '<file>'", $fields: 'files(id, modifiedTime, size, appProperties)')`, returns the first file or null.
  `peek(token)` -> BackupInfo { modifiedAt, sizeBytes, vehicleCount, logCount } read from metadata and
  `appProperties`, so the restore screen can show a summary without downloading the file.
  `upload(token, data)` -> encodes `data.toJson()` to UTF-8, builds `drive.Media` with contentType
  `application/json`, sets `appProperties = { vehicles, logs, schema }`; if the file exists uses
  `files.update(meta, id, uploadMedia:)`, otherwise `files.create` with `name` and `parents: ['appDataFolder']`.
  `download(token)` -> `files.get(id, downloadOptions: DownloadOptions.fullMedia)`, concatenates the
  stream, decodes UTF-8 JSON, and returns `AppData.fromJson(migrateRaw(raw))`.

## Backup trigger schedule
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.5
- type: protocol
- content:
  Automatic (silent, shows nothing): on app open when the last backup is older than 24h; after a service
  log or ODO entry, debounced 30 seconds; when the app goes to background (`AppLifecycleState.paused`).
  Manual: the "Sao lưu ngay" button in Settings, which reports its result clearly.
  `BackupService.scheduleDebounced()` cancels and restarts a 30-second Timer that calls `runSilent()`.
  `runSilent()` returns immediately when `settings.driveBackupEnabled` is false; gets `silentToken()`;
  if null, records the error "Cần đăng nhập lại Google" and must NOT open a sign-in dialog; otherwise
  uploads and records success. Any exception is recorded via `_setError(e.toString())`.
  Constraint: automatic backup never shows a toast or spinner. Failures surface only as one small line
  in Settings: "Lần sao lưu cuối: 3 ngày trước · Có lỗi".

## Restore safety protocol
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.6
- type: protocol
- content:
  Restore is a whole-state overwrite with no merge, and is identified as the highest data-loss risk.
  Layer 1: restore is offered only in onboarding, when the device has no data. Afterwards it requires
  entering Settings and confirming separately.
  Layer 2: if the device already has data, show an explicit comparison before overwriting —
  "Khôi phục sẽ THAY THẾ dữ liệu hiện có trên máy.", device side ("Trên máy: 1 xe · 34 log, sửa 2 giờ
  trước") vs Drive side ("Trên Drive: 1 xe · 31 log, sao lưu 5 ngày trước"), plus warnings
  "⚠ Bản trên Drive CŨ HƠN" and "⚠ Ảnh hoá đơn không khôi phục được", with [ Huỷ ] / [ Vẫn khôi phục ].
  Layer 3: before overwriting, save the current state to `appdata.pre-restore.json`; expose a
  "Hoàn tác khôi phục" button that remains available for 7 days.

## Android Auto Backup fallback
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.7
- type: nfr
- content:
  Enabled via `android:allowBackup="true"` in the manifest. Up to 25 MB, automatic, no code, no OAuth.
  Limits: restores only on reinstall on a new Android device; invisible; cannot be triggered on demand;
  does not exist on iOS.

## Catalog entry schema
- source: D:/Projects/moto-note/motonote-v3-flutter.md §8.1
- type: schema
- content:
  lib/domain/catalog.dart. `class CatalogEntry` with final fields:
    code String; nameVi String; appliesTo Set<VehicleType>; intervalKm int?; intervalMonths int?;
    defaultOn bool = false (pre-checked during onboarding); isOil bool = false (uses the oil-grade picker);
    hint String?; icon IconData.
  `List<CatalogEntry> catalogFor(VehicleType type)` filters `kCatalog` by `appliesTo`.
  The catalog is a const Dart list compiled into the app; there is no server fetch.

## Catalog data (Appendix A)
- source: D:/Projects/moto-note/motonote-v3-flutter.md Appendix A
- type: schema
- content:
  24 entries in `kCatalog`, grouped as ĐỘNG CƠ / TRUYỀN ĐỘNG / PHANH / LỐP & KHUNG GẦM / ĐIỆN & KHÁC.
  Format below: code | nameVi | appliesTo | intervalKm | intervalMonths | defaultOn | isOil | hint.
    engine_oil | Nhớt máy | all | 2000 | 3 | yes | yes | "Quan trọng nhất. Chu kỳ đổi theo loại nhớt."
    gear_oil | Nhớt láp (hộp số) | scooter | 8000 | 12 | yes | yes | "Thường thay sau mỗi 3–4 lần thay nhớt máy."
    oil_filter | Lọc nhớt | manual | 8000 | 12 | yes | — | —
    coolant | Nước làm mát | scooter, manual | 12000 | 24 | no | — | "Chỉ xe có két nước."
    spark_plug | Bugi | all | 10000 | 12 | yes | — | —
    air_filter | Lọc gió | all | 10000 | 12 | yes | — | "Chạy đường bụi nhiều thì thay sớm hơn."
    cvt_air_filter | Lọc gió nồi | scooter | 8000 | — | no | — | —
    injector | Vệ sinh kim phun | all | 15000 | 24 | no | — | —
    valve | Chỉnh khe hở xu-páp | all | 15000 | — | no | — | —
    cvt_belt | Dây curoa | scooter | 18000 | 24 | yes | — | "Đứt giữa đường là phải kéo xe về."
    cvt_rollers | Bi nồi | scooter | 18000 | — | no | — | "Thường thay cùng lúc với dây curoa."
    cvt_clutch | Bố ba càng | scooter | 20000 | — | no | — | —
    chain_lube | Bôi trơn xích | underbone, manual | 500 | — | no | — | "Chu kỳ ngắn, bật nếu bạn tự làm."
    chain_adjust | Căng chỉnh xích | underbone, manual | 2000 | — | yes | — | —
    chain_set | Nhông xích đĩa | underbone, manual | 18000 | — | yes | — | "Thay cả bộ, không thay lẻ."
    brake_pad_f | Má phanh trước | all | 18000 | — | yes | — | —
    brake_pad_r | Má phanh sau | all | 22000 | — | yes | — | —
    brake_fluid | Dầu phanh | all | 20000 | 24 | no | — | "Chỉ xe phanh đĩa."
    tire_front | Lốp trước | all | 20000 | 36 | yes | — | —
    tire_rear | Lốp sau | all | 18000 | 36 | yes | — | "Mòn nhanh hơn lốp trước."
    fork_oil | Dầu phuộc trước | all | 25000 | 36 | no | — | —
    bearings | Bạc đạn cổ, bánh xe | all | 25000 | — | no | — | —
    battery | Ắc quy | all | — | 30 | yes | — | "Chỉ tính theo thời gian, không theo km."
    insurance | Bảo hiểm TNDS | all | — | 12 | yes | — | —
  ("all" = {scooter, underbone, manual}.)
  Stated caveat that must also appear in the app on the interval-editing screen: these are general
  recommendations for urban use; shorten them for congested city riding, flooding, or heavy loads; the
  manufacturer's manual per model remains the most accurate reference.
  Open item: motorcycle emissions-inspection regulation is still being rolled out — when specific rules
  exist, add an `emission_check` entry with a suitable `intervalMonths` and ship a new build; check the
  regulation in force at release time.

## Item-selection screen rules
- source: D:/Projects/moto-note/motonote-v3-flutter.md §8.2
- type: protocol
- content:
  Stated principle: pre-check the 6–8 most important items and collapse the rest.
  Showing 15 checkboxes to a first-time user is the fastest way to make them give up; correct defaults
  matter far more than offering many options.
  The mockup shows the header "Theo dõi những gì? / Chọn sau cũng được.", eight checked items —
  Nhớt máy ("Quan trọng nhất"), Nhớt láp, Lọc gió, Bugi, Dây curoa, Má phanh trước, Lốp trước, Lốp sau —
  then a collapsed row "▸ 7 hạng mục nâng cao / Bi nồi, dầu phanh, phuộc, bạc đạn, ắc quy...", and
  [ Tiếp tục ]. Use `ExpansionTile` for the advanced section; no extra package needed.
  See INGEST-CONFLICTS.md — these counts do not reconcile with the `defaultOn` flags in Appendix A.

## Oil grade presets
- source: D:/Projects/moto-note/motonote-v3-flutter.md §8.3
- type: schema
- content:
  lib/domain/oil_presets.dart. `class OilPreset { String label; int km; int months; String hint; }`
  `const kOilPresets = <OilGrade, OilPreset>{ ... }`:
    mineral        -> 'Nhớt khoáng', 1500 km, 3 months, "Rẻ nhất, phải thay dày. Nhớt \"zin\" theo xe thường loại này."
    semiSynthetic  -> 'Bán tổng hợp', 2500 km, 4 months, "Phổ biến nhất. Cân bằng giá và chu kỳ."
    fullSynthetic  -> 'Tổng hợp toàn phần', 3500 km, 6 months, "Đắt hơn nhưng đi được xa hơn. Hợp với người chạy nhiều."
  Selecting a grade at onboarding step 5 updates the engine-oil item's intervalKm and intervalMonths and
  immediately shows: "Với nhớt bán tổng hợp, app sẽ nhắc bạn mỗi ~2.500 km hoặc 4 tháng."
  The user can still edit the numbers; the preset is only a starting point.

## Part-spec memory and log prefill
- source: D:/Projects/moto-note/motonote-v3-flutter.md §8.4
- type: protocol
- content:
  Each MaintenanceItem retains `partBrand` + `partSpec` from the most recent change, and the next log
  form is prefilled from them. Mockup fields: Ngày, Số km, Chi phí (₫), Loại nhớt (dropdown showing
  "Motul 5100 10W-40" with the sub-line "↳ giống lần trước (02/06)"), Tiệm, [ Lưu ].
  Goal: recording a log becomes a few seconds of work rather than retyping everything.

## ODO estimation formula
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.1
- type: protocol
- content:
  odoƯớcTính = odoLầnNhậpCuối + kmMỗiNgày × sốNgàyTừLầnNhậpCuối
  (estimated ODO = last-entered ODO + km per day × days since last entry). Three variables, one multiplication.

## Average km/day self-refinement
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.2
- type: protocol
- content:
  lib/domain/odo.dart. `RefinedAvg { double avgDailyKm; AvgKmSource source; }`
  `RefinedAvg refineAvgDailyKm(Vehicle vehicle, OdoReading newReading, OdoReading? prevReading)`:
    if prevReading is null -> return the vehicle's existing value and source unchanged;
    days = newReading.date.difference(prevReading.date).inDays; km = newReading.odoKm − prevReading.odoKm;
    if days < 14 or km < 0 -> return unchanged (too short an interval is not representative — one
      touring day does not describe daily habit);
    measured = km / days;
    if the current source is AvgKmSource.user -> smoothed = measured (trust the first real measurement fully);
    else -> smoothed = 0.7 × measured + 0.3 × vehicle.avgDailyKm (avoid jumps after an unusual month);
    return RefinedAvg(smoothed.clamp(0.5, 400), AvgKmSource.computed).

## Due computation
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.3
- type: protocol
- content:
  lib/domain/due.dart.
  `enum DueStatus { ok, dueSoon, dueToday, overdue }`; `enum DrivenBy { km, time }`.
  `DueResult { DueStatus status; DateTime dueDate; int daysLeft; int? kmLeft; double progress (0..1+);
    DrivenBy drivenBy; bool isEstimate; }`
  `DueResult? computeDue(MaintenanceItem item, Vehicle vehicle, int leadDays, {DateTime? now})`:
    return null if `!item.enabled`, or if both lastServiceDate and lastServiceOdo are null;
    avg = vehicle.avgDailyKm <= 0 ? 0.5 : vehicle.avgDailyKm (guards divide-by-zero);
    daysSinceOdo = now − vehicle.odoUpdatedAt (in days);
    estOdo = vehicle.currentOdoKm + round(avg × daysSinceOdo);
    km axis (when intervalKm and lastServiceOdo exist): target = lastServiceOdo + intervalKm;
      kmLeft = target − estOdo; progress = 1 − kmLeft/intervalKm; dueByKm = now + (kmLeft/avg) days;
    time axis (when intervalMonths and lastServiceDate exist):
      dueByTime = DateTime(d.year, d.month + intervalMonths, d.day); progress = max(progress, timeProgress);
    dueDate/drivenBy = whichever axis comes first; if only one axis exists, use it;
    daysLeft = _dateOnly(dueDate) − _dateOnly(now);
    status = overdue if daysLeft < 0; dueToday if daysLeft == 0;
      dueSoon if daysLeft <= leadDays or progress >= 0.9; otherwise ok;
    isEstimate = daysSinceOdo > 45 || item.baselineIsGuess.
  Dart trap called out: `DateTime.difference().inDays` truncates rather than rounds — a 23-hour gap
  still yields 0 days. Normalise to start-of-day via `_dateOnly` before subtracting, or an off-by-one-day
  bug results.

## Honest-uncertainty display rules
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.5, §11.1
- type: protocol
- content:
  ODO updated < 45 days ago and the baseline is a real log:
    "Còn 12 ngày nữa tới hạn thay nhớt"
  ODO updated > 45 days ago:
    "Còn khoảng 12 ngày · số km đã cũ 2 tháng" with a [ Cập nhật số km ] action
  Baseline is a setup guess:
    "Ước tính còn 12 ngày · chưa có mốc thay thật" with a [ Tôi vừa thay ] action
  The app says "khoảng" only when it only knows approximately. Also: prefix km with `~` when
  `isEstimate == true`. Rationale: users who get reminded wrongly a few times turn notifications off,
  and once off they almost never turn them back on.

## Test surface
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.6
- type: protocol
- content:
  test/domain/due_test.dart — group 'computeDue': picks the km milestone when km comes first; picks the
  time milestone when the bike has sat unused; returns overdue past the date; sets isEstimate when the
  ODO is older than 45 days; returns null when the item is disabled; does not divide by zero when
  avgDailyKm = 0; no one-day drift on a 23-hour gap (§9.3).
  test/domain/odo_test.dart — group 'refineAvgDailyKm': skips when the interval is under 14 days; skips
  when the new ODO is lower than the old; fully trusts the first real measurement; applies 70/30
  smoothing afterwards; clamps to [0.5, 400].
  Both are pure functions — no mocks, no widget tests. UI is checked by hand on a real device.

## Notification taxonomy
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.1
- type: protocol
- content:
  Nhắc cập nhật ODO — on a fixed day of the month chosen by the user — once per month.
  Sắp tới hạn — `leadDays` days before the due date (default 7) — grouped per vehicle, at most 1 per day.
  Quá hạn — on the due date, then every 14 days, at most 3 times — once per fortnight.

## Notification initialisation
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.2
- type: protocol
- content:
  lib/notifications/notification_service.dart. `init()` must run before any scheduling:
    `tzdata.initializeTimeZones()`; `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))`
    — required, otherwise notifications fire at the wrong time across timezone changes or DST;
    `_plugin.initialize(InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false,
      requestSoundPermission: false)), onDidReceiveNotificationResponse: _onTap)`
    — iOS permissions are deliberately deferred to the end of onboarding;
    Android requires creating the channel or notifications silently disappear:
      AndroidNotificationChannel('maintenance', 'Nhắc bảo dưỡng',
        description: 'Nhắc khi tới hạn thay linh kiện và nhắc cập nhật số km', importance: Importance.high).

## Notification permissions
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.3
- type: protocol
- content:
  Android has two distinct permissions that are easy to confuse:
    (1) `requestNotificationsPermission()` — permission to display notifications (Android 13+). If denied, return false.
    (2) `requestExactAlarmsPermission()` — a SEPARATE permission for exact alarms (Android 12+). Without
        it notifications still fire but may be hours late.
  iOS: `requestPermissions(alert: true, badge: true, sound: true)`.
  From Android 14 the exact-alarm permission is not auto-granted on fresh install; handle refusal by
  scheduling in inexact mode. Do not gate features on this permission.
  Timing: ask at the end of onboarding, after the user has seen their vehicle on the home screen, with
  the explanation "Bật thông báo để app nhắc bạn khi tới hạn thay nhớt và nhắc cập nhật số km mỗi tháng.
  Không có thông báo, app chỉ nhắc khi bạn tự mở lên." If refused, the app must remain fully usable and
  show only a light reminder line in Settings.

## Rescheduling algorithm and OS limits
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.4
- type: nfr
- content:
  Constants: `_horizonDays = 120`; `_maxScheduled = 30` (iOS caps at 64 total — leave headroom).
  `rescheduleAll(AppData data)`: `cancelAll()` first; return immediately if
  `!data.settings.notificationsEnabled`.
  Part 1 — monthly ODO reminder: when `odoReminderEnabled` and vehicles exist, schedule 6 months ahead
  using `odoReminderDayOfMonth` and `notifyHour`; title "Cập nhật số km", body
  "Xe {name} đang ở khoảng {est} km. Số thật là bao nhiêu?", payload `odo:{vehicleId}`.
  Part 2 — due items grouped by (vehicle, day): for each item run `computeDue`, expand to notify dates,
  skip dates in the past and dates beyond `_horizonDays`, bucket by `'{vehicleId}|{dateKey}'`,
  accumulate item names, then compose one message per bucket with payload `due:{vehicleId}`.
  Part 3 — sort by date ascending, `take(_maxScheduled)`, and `zonedSchedule` each with sequential ids,
  `tz.TZDateTime.from(date, tz.local)`, channel 'maintenance' at Importance.high / Priority.high,
  `DarwinNotificationDetails()` for iOS, and
  `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` so it fires on time even in battery saver.
  Call `rescheduleAll()` on `AppLifecycleState.resumed` and on any state change (automatic via `_mutate`, §5.2).
  Cost is tens of milliseconds at this data scale, so over-calling is preferred to under-calling.

## Notification message composition
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.5
- type: protocol
- content:
  `_compose(Vehicle v, List<String> items)`:
    1 item  -> title "{name} sắp tới hạn", body "{item0}"
    2 items -> title "{name} sắp tới hạn", body "{item0} và {item1}"
    3+      -> title "{name} có {n} hạng mục sắp tới hạn", body "{item0}, {item1} và {n-2} mục khác"
  Rationale: one vehicle can have four items due at once; sending four notifications is the fastest way
  to get notifications turned off.

## Android OEM ROM battery-management tolerance
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.6
- type: nfr
- content:
  Xiaomi, Oppo, Vivo, Samsung and other ROMs add a battery layer above stock Doze that can kill the app
  process minutes after screen-off, block exact alarms from waking the app, and silently suppress
  notifications for apps marked "sleeping" — even with `exactAllowWhileIdle` set correctly. This is an
  OS-layer problem; Flutter and React Native suffer equally. There is no full fix, only mitigation:
  (1) reschedule on every app open (§10.4);
  (2) an onboarding step that detects the manufacturer and opens the right settings page —
      `batteryOptimizationHint()` via `device_info_plus`, returning null on non-Android:
        xiaomi/redmi/poco -> "Vào Cài đặt → Ứng dụng → MotoNote → Tiết kiệm pin → chọn \"Không giới hạn\", và bật \"Tự khởi động\"."
        oppo/realme/oneplus -> "Vào Cài đặt → Pin → Tối ưu hoá pin → MotoNote → chọn \"Không tối ưu hoá\"."
        vivo -> "Vào Cài đặt → Pin → Mức tiêu thụ nền cao → bật MotoNote."
        samsung -> "Vào Cài đặt → Chăm sóc thiết bị → Pin → Giới hạn sử dụng nền → bỏ MotoNote khỏi danh sách \"Ứng dụng đang ngủ\"."
        default -> null
      `openBatterySettings()` launches AndroidIntent action `android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS`.
  (3) self-detection of dead notifications: record `settings.lastNotificationFiredAt` whenever a
      notification is opened; if more than 45 days pass with items due and nothing fired, show an in-app
      banner "Có vẻ thông báo không hoạt động. Xem cách khắc phục." This turns a silent failure — the app
      quiet while the user assumes the bike is fine — into a visible one.

## Notification deep-link contract
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.7
- type: api-contract
- content:
  Payload format is `{kind}:{id}`. `_onTap(NotificationResponse)` splits on ':' and routes:
    'due' -> `appRouter.go('/vehicle/$id?tab=due')`
    'odo' -> `appRouter.go('/vehicle/$id?sheet=odo')`
  Cold-start case must also be handled: in `main()` after `init()`, call
  `_plugin.getNotificationAppLaunchDetails()`; if `didNotificationLaunchApp`, stash
  `launch.notificationResponse?.payload` as `pendingDeepLink` and process it once the router is ready.

## Screen inventory and navigation
- source: D:/Projects/moto-note/motonote-v3-flutter.md §11
- type: protocol
- content:
  Seven screens, no more. Onboarding (chào -> khôi phục | thiết lập 6 bước -> quyền) leads to a
  BottomNavigationBar with three tabs:
    Trang chủ — vehicle card, most-urgent items, ODO button
    Ghi chú — note list with pinning, leading to the note editor
    Cài đặt — thông báo, sao lưu Drive, xuất file, quản lý xe/hạng mục
  From Trang chủ: item detail with history, and the service-log modal sheet.

## Home screen rules
- source: D:/Projects/moto-note/motonote-v3-flutter.md §11.1
- type: protocol
- content:
  The home screen answers one question in two seconds: does my bike need anything?
  Rules: show only what needs attention — collapse the healthy items into a single row
  ("9 hạng mục khác đang ổn ›"); the ODO update button is the most prominent element
  (`FloatingActionButton.extended`), because it is the action the app most needs from the user and
  everything else depends on it; pinned notes appear here so they are visible at the workshop;
  red is reserved for overdue only — using red for "due soon" too desensitises the user;
  prefix km with `~` when `isEstimate == true`.
  Mockup shows the vehicle header ("Vision · 29A1-234.56 · ~18.665 km · cập nhật 10 ngày"), an overdue
  card ("⚠ Nhớt máy · Quá hạn 7 ngày · 665 km" with a [ Tôi vừa thay ] action), a due-soon card
  ("◔ Lọc gió · Còn 14 ngày"), the collapsed healthy row, a pinned note, and the "Cập nhật số km" FAB.

## ODO update sheet
- source: D:/Projects/moto-note/motonote-v3-flutter.md §11.2
- type: protocol
- content:
  ODO update is a modal sheet, not a screen: `showModalBottomSheet` with `isScrollControlled: true`.
  Prefill the estimated value so the user only edits a few digits. Show the previous reading
  ("Lần trước: 18.420 (10 ngày)"). Use a self-drawn numeric keypad (`GridView` of 12 cells) rather than
  the system keyboard — faster and no layout jump. Block entering a number lower than the previous
  reading unless the user confirms the odometer was replaced.

## Project structure
- source: D:/Projects/moto-note/motonote-v3-flutter.md §12
- type: protocol
- content:
  motonote/
    lib/main.dart — init, hydrate, router
    lib/domain/ — pure Dart, must not import Flutter: models/{app_data, vehicle, maintenance_item,
      service_log, misc}.dart, catalog.dart (§8.1 + Appendix A), oil_presets.dart (§8.3),
      due.dart (computeDue, §9.3), odo.dart (refineAvgDailyKm, §9.2)
    lib/data/ — app_data_repository.dart (§5.1), migrations.dart (§4.4)
    lib/state/ — app_state.dart (§5.2), derived.dart (§5.3)
    lib/backup/ — google_auth.dart (§7.3), drive_service.dart (§7.4), backup_service.dart (§7.5),
      local_export.dart (share_plus)
    lib/notifications/ — notification_service.dart (§10.2–10.4), battery_hints.dart (§10.6)
    lib/ui/ — router.dart (go_router), onboarding/, home/{home_screen, due_card, odo_sheet}.dart,
      log/, item/, notes/, settings/, widgets/
    lib/theme/ — app_theme.dart, colors.dart
    test/domain/ — due_test.dart, odo_test.dart
    android/ ios/ assets/ pubspec.yaml
  Constraints: `domain/` must stay Flutter-free; do not create `services/`, `utils/` or `helpers/`
  directories full of tiny files.

## Google Cloud and OAuth release constraints
- source: D:/Projects/moto-note/motonote-v3-flutter.md Appendix B
- type: api-contract
- content:
  Create a Google Cloud project; enable the Google Drive API; complete the OAuth consent screen
  (app name, logo, support email); declare ONLY the `drive.appdata` scope (non-sensitive); publish a
  public privacy-policy URL (mandatory); create an Android OAuth client with package name and SHA-1 for
  all three keys — debug keystore, release keystore, and Play App Signing (obtained after the first
  upload); create an iOS OAuth client with the bundle ID; create a Web client ID for `serverClientId` in
  google_sign_in v7; submit for basic app verification.
  Hard constraint: a missing SHA-1 makes sign-in fail SILENTLY on the corresponding build, with no clear
  error. Named as the most time-consuming failure mode in this area.

## Android platform release constraints
- source: D:/Projects/moto-note/motonote-v3-flutter.md Appendix B
- type: nfr
- content:
  `minSdkVersion` compatible with flutter_local_notifications.
  AndroidManifest permissions: POST_NOTIFICATIONS; SCHEDULE_EXACT_ALARM and/or USE_EXACT_ALARM;
  RECEIVE_BOOT_COMPLETED — without it every scheduled notification is lost after the user reboots the
  phone, and it is easy to miss because reboots are rare during development.
  `android:allowBackup="true"`. Enable minify/shrink for release. Split ABI when building the app bundle
  to reduce download size.

## iOS platform release constraints
- source: D:/Projects/moto-note/motonote-v3-flutter.md Appendix B
- type: nfr
- content:
  Info.plist must clearly describe the purpose of notifications. URL scheme for Google Sign-In
  (REVERSED_CLIENT_ID). Background modes if needed.

## Technical release acceptance checklist
- source: D:/Projects/moto-note/motonote-v3-flutter.md Appendix B
- type: nfr
- content:
  `flutter analyze` reports no warnings.
  Data survives force-stop and device reboot.
  The app is fully functional having NEVER signed into Google.
  Notifications still fire correctly after a device reboot.
  Migration runs correctly from every previous schema version.
  Test the `--release` build, not only debug.
  Test on a real low-end Android device (3–4 GB RAM).
  Test on a real Xiaomi or Samsung device — verify notifications survive.

## Store submission constraints
- source: D:/Projects/moto-note/motonote-v3-flutter.md Appendix B
- type: nfr
- content:
  Icon 1024x1024, opaque background. Screenshots for both iOS and Android. Privacy policy (mandatory
  because OAuth is used). Play Data Safety: declare that data is stored only on the device and in the
  user's own Google Drive. Apple App Privacy: the same. An in-app delete-data button (mandatory on both
  stores). Category: Auto & Vehicles. Keywords: bảo dưỡng xe máy, nhắc thay nhớt, sổ tay xe máy.
  Because there is no server the Data Safety declaration is very short — nothing collected, nothing
  shared — which is a genuine advantage of this architecture and should be stated in the store listing.

## Required development tooling commands
- source: D:/Projects/moto-note/motonote-v3-flutter.md §14.3
- type: protocol
- content:
  `flutter analyze` — mandatory before every commit
  `dart format .` — formatting, not up for debate
  `dart run build_runner watch` — continuous freezed codegen
  `flutter test` — unit tests
  `flutter run --release` — MANDATORY to test the release build separately, because debug runs on JIT
  and is much slower while the AOT release build can expose different bugs, particularly around OAuth
  and notifications. Do not judge performance or conclude anything about a bug from the debug build alone.
  Also: install the Flutter + Dart extensions for VS Code; the DevTools Widget Inspector is the most
  useful tool for understanding layout.
