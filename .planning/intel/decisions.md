# Decisions

Extracted from the ingest set. No ADR-classified sources were present; all entries below are
decision statements carried inside the SPEC-classified source `motonote-v3-flutter.md`, whose
§1 is titled "Chốt phương án" (decisions locked in) and whose §1.1/§1.2/§3.2 record rejected
alternatives with rationale.

`status: locked` = the source states the option as settled and records why alternatives were rejected.
`status: proposed` = the source states the choice but explicitly leaves it open to re-verification or
defers it to a later release.

---

## Version 3.0 supersedes the v2.0 React Native plan
- source: D:/Projects/moto-note/motonote-v3-flutter.md (header, line 4)
- status: locked
- decision: This document is version 3.0, dated 2026-08-28, and replaces v2.0 (React Native). The v2.0 document is not part of the ingest set. §13.2 notes v2 and v3 exist because v1 suffered scope creep.
- scope: document lineage, plan of record

## Framework: Flutter
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §1.2
- status: locked
- decision: Build with Flutter rather than React Native. Accepted gains: fine-grained control of Android notification scheduling (`androidScheduleMode`) — decisive because notifications are the core feature; first-party Google package for Drive (`googleapis`) with full typing; lighter app and faster startup on low-end devices, material for the Vietnamese market; no forced 6-month SDK upgrade cycle. Accepted costs: new language, new widget model, new toolchain; timeline grows from ~5 weeks to ~7 weeks (§13); platform-level bugs take longer to diagnose.
- scope: framework, mobile client

## No backend server
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §3
- status: locked
- decision: The system has no server owned by the project. The architecture diagram in §3 contains no first-party server component.
- scope: architecture, backend

## No app account
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §7.1
- status: locked
- decision: There is no MotoNote account — no email, no password, no app-controlled server holding data. Google sign-in exists only when the user turns on Drive backup, and data goes directly from the phone to the user's own Drive.
- scope: identity, accounts

## Storage: one JSON file in the app directory
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §5
- status: locked
- decision: All application state persists as a single JSON file (`appdata.json`) in the app documents directory.
- scope: persistence, local storage

## Sync: whole-file backup/restore to Google Drive `appDataFolder`
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §7
- status: locked
- decision: Synchronisation is backup/restore of the entire document to Google Drive `appDataFolder` (file `motonote-backup.json`). There is no sync protocol, no merge, no conflict resolution.
- scope: backup, sync

## Notifications: `flutter_local_notifications`, no push
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §10
- status: locked
- decision: All notifications are local notifications scheduled by the app with the OS. No push, because there is no server. Stated as better for this app: works offline, needs no FCM credential, costs nothing to operate.
- scope: notifications

## ODO estimation: user-entered average km/day, self-refining
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §9
- status: locked
- decision: Odometer is estimated from a user-supplied average km/day that the app progressively refines from real ODO readings.
- scope: odo estimation, due engine

## REJECTED: importing data from Google Maps Timeline
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1, §1.1
- status: locked
- decision: Google Maps Timeline import is removed. Recorded rationale so it need not be re-researched: (1) No API — Google has never provided a Timeline read API; the only path is the user manually exporting `Timeline.json` from phone settings. (2) Since late 2024 Google moved Timeline to on-device storage, disabled Timeline on the web from 2025-06-09, and Takeout no longer exports Timeline; default retention dropped to 3 months. (3) The file format is undocumented, differs between Android and iOS, and Google changed it three times in three years. (4) Most important — the data cannot be used to set ODO: Timeline only records trips when location is on and the phone is carried, and it also records rides as a passenger or in a taxi. Wrong in both directions. If reducing manual ODO entry is wanted later, build a fuel log instead (§13.3) — far cheaper and more effective for that specific goal.
- scope: data import, odo estimation

## REJECTED: React Native
- source: D:/Projects/moto-note/motonote-v3-flutter.md §1.2
- status: locked
- decision: React Native is rejected in favour of Flutter. `expo-notifications` in particular does not expose control over exact Android alarm scheduling (§10.4 notes `androidScheduleMode: exactAllowWhileIdle` as "the thing expo-notifications does not let you control").
- scope: framework

## REJECTED: Provider/BLoC — use Riverpod
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3.2
- status: locked
- decision: Use Riverpod instead of Provider/BLoC. This app has exactly one state block (`AppData`) plus a few transient UI states. BLoC is too heavy for this scale — many event classes, many state classes, much boilerplate for a 7-screen app. A single `NotifierProvider` suffices and is easier to test because the logic lives in pure functions.
- scope: state management

## REJECTED: Hive/Isar/SQLite — use a plain JSON file
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3.2
- status: locked
- decision: Use a plain JSON file rather than Hive, Isar or SQLite. All data fits comfortably in RAM. Adding a database just to store 200 KB adds a dependency, adds schema migration, adds another thing that can break — and makes backup more complex, because it would have to be exported to JSON before upload. Writing JSON directly is the simplest option and the best fit for the backup architecture.
- scope: persistence, local storage

## Freezed + json_serializable despite the codegen step
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3.2
- status: locked
- decision: Use Freezed even though it adds a codegen step. `Vehicle` has 14 fields; hand-writing `copyWith` for it is tedious and error-prone — forgetting one field silently loses data. Freezed generates `copyWith`, `==`, `toString`, and together with `json_serializable` generates `toJson`/`fromJson`. Cost: must run `build_runner`.
- scope: models, serialization

## `go_router` instead of bare Navigator
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3.2
- status: locked
- decision: Use `go_router` rather than managing the Navigator stack by hand, because deep-linking from a notification into a specific screen is required and `go_router` handles it far more cleanly.
- scope: navigation, deep linking

## Principle 1: the entire app state is one JSON document
- source: D:/Projects/moto-note/motonote-v3-flutter.md §2
- status: locked
- decision: Not a database, not multiple tables — one object. Data is very small: 1 vehicle x 15 items x a few hundred logs over several years is under 200 KB. When state is a single document, backup is simply uploading that document: no sync protocol, no merge, no conflict resolution. The source calls this "the most important architectural decision of the whole project".
- scope: architecture, data model

## Principle 2: no source of truth outside the user's device
- source: D:/Projects/moto-note/motonote-v3-flutter.md §2
- status: locked
- decision: Google Drive is only a place to keep a copy. The app never reads Drive to obtain the data it is using — it reads Drive exactly once, during restore.
- scope: architecture, backup

## Principle 3: write first, back up after
- source: D:/Projects/moto-note/motonote-v3-flutter.md §2
- status: locked
- decision: Every write operation goes to the device immediately. Backup to Drive runs in the background; failure is acceptable.
- scope: persistence, backup

## Principle 4: full functionality without ever signing into Google
- source: D:/Projects/moto-note/motonote-v3-flutter.md §2, §7.1
- status: locked
- decision: Sign-in exists only for backup. Users who do not want it use the export-file button.
- scope: identity, backup, export

## Principle 5: no screen waits on the network
- source: D:/Projects/moto-note/motonote-v3-flutter.md §2
- status: locked
- decision: Everything reads from memory and renders instantly.
- scope: ui, performance

## Photos live outside the document and are not backed up
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.3
- status: locked
- decision: Receipt photos are stored in the app directory; only their paths are kept in the JSON. Rationale: `appDataFolder` counts against the user's Drive quota and a few dozen photos would inflate it fast; photo upload needs multipart, resumable and retry — exactly the complexity this architecture avoids; receipt photos are "nice to have" data whose loss is not serious. Consequence that must be stated to the user on the restore screen itself, not hidden in an FAQ: restoring from Drive recovers everything except photos.
- scope: data model, backup, restore ui

## Migration policy: additive only
- source: D:/Projects/moto-note/motonote-v3-flutter.md §4.4
- status: locked
- decision: Only add fields — never rename, never delete. `json_serializable` ignores unknown fields. This keeps old backup files always readable and stops new backup files from crashing older app versions. The migrate function must run on both local data and restored data.
- scope: schema, migration

## Drive scope limited to `drive.appdata`
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.2, Appendix B
- status: locked
- decision: Request only `https://www.googleapis.com/auth/drive.appdata`. Google classifies this scope as non-sensitive — it needs only basic app verification, not sensitive-scope review and not a security assessment. This is the deciding point: using `drive` or `drive.readonly` would require heavy verification, possibly a paid third-party assessment, which is disproportionate for a personal app. Accepted trade-off: the user cannot see the backup file and cannot copy it to another Google account. Compensated by an "Export file" button in Settings (`share_plus`) so the user can save the JSON anywhere. The two mechanisms are complementary: Drive covers changing phone, export covers changing account.
- scope: oauth, drive api, backup

## Automatic backup uses `silentToken()` only
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.3, §7.5
- status: locked
- decision: `authorizeScopes()` on some platforms must originate from a user action and cannot be called from a background process. Automatic backup may therefore only use `silentToken()`. If it returns null (permission revoked, token broken) the app must NOT pop a sign-in dialog mid-flow — it records the error and shows one line in Settings for the user to act on. Automatic backup never shows a toast or spinner; failures are written to `settings.lastBackupError` and surfaced as "Lần sao lưu cuối: 3 ngày trước · Có lỗi".
- scope: oauth, backup, background work

## Restore is a full overwrite, never a merge
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.6
- status: locked
- decision: Restore replaces all data; there is no merge. Three protective layers: (1) restore is only offered on the onboarding screen when the device has no data — afterwards it requires going into Settings and confirming separately; (2) if the device already has data, show an explicit side-by-side comparison before overwriting, including warnings when the Drive copy is older and that receipt photos cannot be restored; (3) before overwriting, save the current state to `appdata.pre-restore.json` and offer an "Undo restore" button that lives for 7 days.
- scope: restore, data loss prevention

## Enable Android Auto Backup as a free safety net
- source: D:/Projects/moto-note/motonote-v3-flutter.md §7.7, Appendix B
- status: locked
- decision: Set `android:allowBackup="true"`. Android's built-in app-data backup to the user's Drive is up to 25 MB, automatic, needs no code and no OAuth. Limitations accepted: it only restores when reinstalling on a new Android device, is invisible, cannot be triggered, and does not exist on iOS. It is free and catches the case where the user changes phone without having enabled Drive backup.
- scope: android, backup

## Parts catalog is hardcoded in the app
- source: D:/Projects/moto-note/motonote-v3-flutter.md §8.1, Appendix A
- status: locked
- decision: The catalog lives in a Dart file inside the app, not fetched from a server — because there is no server. Updating the catalog means shipping a new release, which is acceptable for data that changes as rarely as maintenance intervals. Noted follow-on: when motorcycle emissions-inspection rules are finalised, add an `emission_check` entry with an appropriate `intervalMonths` and ship a new build.
- scope: catalog, release process

## Oil grade drives the service interval
- source: D:/Projects/moto-note/motonote-v3-flutter.md §8.3
- status: locked
- decision: Oil type determines the change interval, and most users do not know this. Choosing an oil grade at onboarding step 5 automatically updates `intervalKm`/`intervalMonths` on the engine-oil item and shows the result immediately ("Với nhớt bán tổng hợp, app sẽ nhắc bạn mỗi ~2.500 km hoặc 4 tháng"). The user can still edit the numbers; the preset is only a sensible starting point. The app must state that these are general recommendations and that the manufacturer's manual is the authoritative source per model.
- scope: catalog, oil presets, onboarding

## Two due axes — the time axis cannot be dropped
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.4
- status: locked
- decision: Oil degrades over time even when the bike is not ridden; a bike parked five months still needs an oil change. Therefore every item may carry both `intervalKm` and `intervalMonths`, and the due date is always whichever comes first. Dropping the time axis would make the app wrong for low-mileage users, of whom there are many in Hà Nội and TP.HCM.
- scope: due engine

## Notification strategy: cancel everything, then reschedule concrete dates
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.4
- status: locked
- decision: `rescheduleAll()` calls `cancelAll()` then schedules individual dated notifications, rather than using repeating schedules. Repeating schedules sound tidier but cannot recompute notification content (the estimated km changes daily) and behave inconsistently between iOS and Android ROMs. Scheduling explicit dates and re-scheduling on every app open is far more predictable. Cost is a few tens of milliseconds per run at this data scale, so running it more often than strictly needed is preferred.
- scope: notifications

## Do not block features on the exact-alarm permission
- source: D:/Projects/moto-note/motonote-v3-flutter.md §10.3
- status: locked
- decision: From Android 14 the exact-alarm permission is not auto-granted on fresh install. If the user declines, still schedule normally using the inexact mode; notifications may be a few hours late, which is entirely acceptable for a maintenance reminder. If notification permission itself is declined, the app must remain fully usable, showing only a soft prompt line in Settings.
- scope: notifications, android permissions

## `domain/` is pure Dart and must not import Flutter
- source: D:/Projects/moto-note/motonote-v3-flutter.md §12
- status: locked
- decision: The `domain/` directory must not import `package:flutter/...`. This lets the entire business logic be tested with plain `dart test` instead of `flutter test` — much faster and independent of the widget tree. Also stated: no `services/`, `utils/` or `helpers/` directories full of tiny files; at this scale over-splitting makes code harder to follow.
- scope: project structure, testing

## Test scope: two pure-function test files only
- source: D:/Projects/moto-note/motonote-v3-flutter.md §9.6
- status: locked
- decision: Automated tests cover only `test/domain/due_test.dart` and `test/domain/odo_test.dart`. Both target pure functions — no mocks, no widget tests. UI is verified by hand on a real device, which is more effective at this scale.
- scope: testing

## Seven screens, no more
- source: D:/Projects/moto-note/motonote-v3-flutter.md §11, §3.2
- status: locked
- decision: The app has exactly seven screens: onboarding, home, notes list, note editor, settings, item detail, and the service-log modal sheet. ODO update is a modal sheet, not a screen (§11.2).
- scope: navigation, scope control

## Scope-creep control via BACKLOG.md
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13.2
- status: locked
- decision: v2 and v3 of this plan exist precisely because v1 grew out of control. Every new idea that arises during the build goes into `BACKLOG.md` and is not inserted into the version being built. Review the backlog after the app has run for two weeks with real users — only then is it clear what is actually needed.
- scope: process, scope control

## Dependency versions are reference points, not commitments
- source: D:/Projects/moto-note/motonote-v3-flutter.md §3.1
- status: proposed
- decision: The pinned versions in the pubspec listing are reference points, not commitments. `google_sign_in` and `freezed` both had recent major breaking changes — run `flutter pub outdated` and read both CHANGELOGs before writing code, and do not copy older code from the web. §7.3 and risk R7 reinforce this: read only the package's official README and ignore any article written before 2025.
- scope: dependencies

## First feature after 1.0: fuel log
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13.3
- status: proposed
- decision: The first post-1.0 work item is a fuel log ("Nhật ký đổ xăng"). It solves the exact problem Google Maps import was meant to solve — reducing manual ODO entry. Riders refuel weekly while looking straight at the odometer, so a fast fill-up form (date, amount, km) gives users their own reason to open the app (fuel spend, L/100km), makes ODO entry a natural side effect, and raises ODO entry frequency from ~1/month to ~4/month. Cost: one form screen and one model class.
- scope: roadmap, post-1.0
