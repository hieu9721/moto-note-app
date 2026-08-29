# MotoNote

## What This Is

MotoNote is a Vietnamese-language Android app for motorcycle owners: a note-taking and maintenance-reminder
app that tracks when each part on your bike is next due, estimates your odometer between manual entries,
and reminds you with local notifications. Tagline from the source plan:
"App ghi chú + nhắc bảo trì xe máy · Không tài khoản · Lưu máy · Backup Google Drive".
There is no account and no server — all state lives in one JSON file on the device, with an optional
whole-file backup to the user's own Google Drive.

Built with Flutter, targeting low-end Android phones in the Vietnamese market (Hà Nội / TP.HCM riders,
Xiaomi / Oppo / Vivo / Samsung ROMs, VND currency, Vietnamese UI copy).

## Core Value

The user gets reminded on the right day that their bike needs something — accurately enough that they
never turn the notifications off.

## Success Metric (v1.0)

All three must hold together for 1.0 to count as done:

1. **Correct real-world reminders** — after ~1 month of real use on the developer's own bike,
   notifications fire on the expected date, ODO estimation error stays within the documented threshold,
   and the scheduled work is not killed by OEM battery optimisation.
2. **Zero data loss** — reinstall the app, restore from Google Drive, and recover 100% of the
   maintenance history; migrations never corrupt an older document.
3. **Shipped** — 1.0 passes Play Store review and is live, with the Appendix B checklist complete
   (Google Cloud/OAuth + Android sections; the iOS section is excluded for this milestone).

## Requirements

### Validated

- ✓ Flutter toolchain, project scaffold per §12, and a single-JSON-document data layer with atomic
  writes, a fallback copy, corrupt-file quarantine, and additive-only migrations — **Phase 1**.
  Verified on real hardware (SM-A066B, 3.43 GB RAM): `appdata.json` survives a force-stop and a
  device reboot byte-identically, and the §5.1 write ordering was observed on-device — the backup
  copy holds the *previous target* content, never the tmp file.

### Active

Full requirement list with IDs and source traceability: `.planning/REQUIREMENTS.md` (86 v1 requirements).
Summarised by capability:

- [ ] Six-step onboarding, the 24-entry parts catalog, oil-grade presets, and the pure-Dart due /
      ODO-estimation engines with their two test files
- [ ] Home screen, ODO update sheet, service logging with part-spec memory, item history, and notes
      with pinning
- [ ] Local notifications — monthly ODO reminder, due-soon and overdue reminders, grouping, deep
      links, reboot survival, and Android OEM battery-optimisation handling
- [ ] Google Drive `appDataFolder` backup, three-layer-safe restore, undo, and local file export
- [ ] Settings, polish, and Play Store release including OAuth verification and Data Safety

### Out of Scope

- **Google Maps Timeline import** — no API; format undocumented and changed three times in three years;
  Takeout no longer exports it; and the data is directionally wrong for setting ODO (it records taxi and
  passenger trips, and misses rides without the phone). See D-09.
- **React Native** — `expo-notifications` gives no control over exact Android alarm scheduling, which is
  the core feature. See D-10.
- **Any first-party backend server** — the architecture has no server component. See D-03.
- **A MotoNote account** — no email, no password, no app-controlled store of user data. See D-04.
- **Hive / Isar / SQLite** — 200 KB of data does not justify a database, and it would complicate backup.
  See D-12.
- **Provider / BLoC** — one `NotifierProvider` covers the whole app. See D-11.
- **A sync protocol with merge or conflict resolution** — backup/restore of the whole document only.
  See D-06, D-24.
- **Receipt photo backup to Drive** — `appDataFolder` counts against the user's quota and multipart /
  resumable upload is exactly the complexity this architecture avoids. See D-20.
- **Push notifications** — there is no server; all notifications are scheduled locally. See D-07.
- **Widget tests and mocks** — only two pure-function test files; UI is checked by hand on a real device.
  See D-32.
- **More than seven screens** — the screen inventory is a scope-control device. See D-33.
- **The `drive` or `drive.readonly` scopes** — they trigger sensitive-scope review and possibly a paid
  security assessment. See D-22.
- **iOS release in 1.0** — deferred past 1.0 by decision at project setup. The code stays
  Flutter/cross-platform and no work is done to remove iOS support; only the release and verification
  surface is Android-only, so Appendix B's iOS checklist is out of scope for this milestone.
- **Week 0 "làm quen Dart/Flutter"** — the developer treats language familiarisation as preparation
  outside the plan; it is not a roadmap phase.

## Context

- **Source of record**: `motonote-v3-flutter.md` (Vietnamese, version 3.0, dated 2026-08-28), ingested
  via `/gsd-ingest-docs`. Synthesized intel lives in `.planning/intel/`; the conflict report is
  `.planning/INGEST-CONFLICTS.md`.
- **Document lineage**: v3.0 replaces v2.0 (React Native). v2 and v3 of this plan exist because v1
  suffered scope creep — hence the explicit anti-scope-creep machinery (`BACKLOG.md`, seven screens,
  two test files).
- **Current repo state**: only the source planning document, a README, a `.gitignore` and the GSD
  installation. `flutter create` has not been run. The Flutter and Dart SDKs are **not** installed on
  this machine (`flutter` and `dart` are not on PATH); Node.js 24 and git are present. Toolchain setup
  and scaffolding are Phase 1 work.
- **Developer**: one person, part-time, new to Dart/Flutter, doing language familiarisation outside
  this plan.
- **Risk register (§15)**: R1 user does not update ODO → predictions drift; R2 data lost before any
  backup; R3 JSON corrupted mid-write; R4 restore overwrites newer data; R5 notifications killed by an
  OEM ROM; R6 OAuth misconfiguration causing silent sign-in failure; R7 `google_sign_in` v7 differs from
  all older online guidance; R8 the learning curve; R9 default intervals wrong for a specific model;
  R10 scope creep returning.
- **Known Dart traps called out by the source**: `DateTime.difference().inDays` truncates rather than
  rounds (off-by-one-day bugs); `BuildContext` used after an `await`; missing `const`; `Column` inside
  `Column` without `Expanded`; forgetting `build_runner` after editing a freezed model.

## Constraints

- **Tech stack**: Flutter + Dart, Riverpod (one `NotifierProvider`), `go_router`, Freezed +
  `json_serializable`, `flutter_local_notifications`, `googleapis` + `google_sign_in` v7, `share_plus`,
  `device_info_plus` + `android_intent_plus`, `intl` — because notifications and Drive are the two
  hard parts and Flutter gives first-party control over both.
- **Dependencies**: version pins in §3.1 are reference points, not commitments. `google_sign_in` and
  `freezed` both had recent major breaking changes — run `flutter pub outdated` and read both CHANGELOGs
  before writing code, and ignore any article written before 2025.
- **Platform (v1.0)**: Android only, shipped through the Play Store. The §10.6 Android OEM
  battery-optimisation handling is a first-class concern, not a nice-to-have.
- **Architecture**: `domain/` must be pure Dart and must never import `package:flutter/...`, so the
  whole business logic runs under plain `dart test`. No `services/`, `utils/` or `helpers/` directories
  full of tiny files.
- **Data**: one JSON document under 200 KB; additive-only schema migration; photos stored outside the
  document as paths only.
- **Performance**: no screen waits on the network — everything renders from memory.
- **Privacy / compliance**: only the non-sensitive `drive.appdata` scope; a public privacy policy is
  mandatory because OAuth is used; an in-app delete-data button is mandatory on the store.
- **Process**: every idea raised during the build goes to `BACKLOG.md`, never into the version being
  built. Review the backlog only after two weeks of real use.

## Key Decisions

All decisions below were carried in from the SPEC's §1 "Chốt phương án" (decisions locked in) and its
recorded rejections. No ADR-classified source exists in the ingest set — see the INFO entry
"SPEC classification carries ADR-like decision content" in `.planning/INGEST-CONFLICTS.md`. Entries
tagged `[locked]` are settled with rationale recorded; `[proposed]` entries are stated by the source but
explicitly left open to re-verification or deferred.

Full text with source line references: `.planning/intel/decisions.md`.

<decisions>

### Plan of record

- **D-01 [locked]:** This plan is version 3.0, dated 2026-08-28, and replaces v2.0 (React Native); the v2.0 document is not in the ingest set. Source: header line 4.
- **D-34 [locked]:** Scope-creep control runs through `BACKLOG.md` — every new idea that arises during the build goes there and is not inserted into the version being built; review the backlog only after the app has run for two weeks with real users. Source: §13.2.

### Framework and stack

- **D-02 [locked]:** Build with Flutter, accepting a new language, widget model and toolchain and a timeline that grows from ~5 to ~7 part-time weeks, in exchange for fine-grained Android notification scheduling (`androidScheduleMode`), a first-party typed Google package for Drive, a lighter and faster app on low-end devices, and no forced 6-month SDK upgrade cycle. Source: §1, §1.2.
- **D-10 [locked]:** REJECTED React Native — `expo-notifications` does not expose control over exact Android alarm scheduling (`exactAllowWhileIdle`), which is the decisive capability for this app. Source: §1.2.
- **D-11 [locked]:** REJECTED Provider/BLoC in favour of Riverpod — the app has exactly one state block (`AppData`) plus a few transient UI states, so a single `NotifierProvider` suffices and is easier to test because the logic lives in pure functions. Source: §3.2.
- **D-13 [locked]:** Use Freezed plus `json_serializable` despite the codegen step, because `Vehicle` has 14 fields and a hand-written `copyWith` that forgets one field silently loses data. Source: §3.2.
- **D-14 [locked]:** Use `go_router` rather than managing the Navigator stack by hand, because deep-linking from a notification into a specific screen is required. Source: §3.2.
- **D-35 [proposed]:** The dependency versions pinned in §3.1 are reference points, not commitments — run `flutter pub outdated` and read the `google_sign_in` and `freezed` CHANGELOGs before writing code, and ignore any article written before 2025. Source: §3.1, §7.3, §15 R7.

### Architecture and data

- **D-03 [locked]:** There is no first-party server anywhere in the architecture. Source: §1, §3.
- **D-04 [locked]:** There is no MotoNote account — no email, no password, no app-controlled server holding data; Google sign-in exists only when the user turns on Drive backup. Source: §1, §7.1.
- **D-05 [locked]:** All application state persists as a single JSON file `appdata.json` in the app documents directory. Source: §1, §5.
- **D-12 [locked]:** REJECTED Hive/Isar/SQLite in favour of a plain JSON file — all data fits in RAM, a database adds a dependency plus schema migration plus another failure mode to store 200 KB, and it would force an export step before every backup. Source: §3.2.
- **D-15 [locked]:** Principle 1, called the most important architectural decision of the whole project — the entire app state is one JSON document, not a database and not multiple tables, which makes backup a single upload with no sync protocol, no merge and no conflict resolution. Source: §2.
- **D-16 [locked]:** Principle 2 — no source of truth outside the user's device; Drive is only a place to keep a copy, and the app reads Drive exactly once, during restore. Source: §2.
- **D-17 [locked]:** Principle 3 — write first, back up after; every write goes to the device immediately, backup runs in the background, and backup failure is acceptable. Source: §2.
- **D-18 [locked]:** Principle 4 — the app is fully functional without ever signing into Google; sign-in exists only for backup, and users who decline it use the export-file button. Source: §2, §7.1.
- **D-19 [locked]:** Principle 5 — no screen waits on the network; everything reads from memory and renders instantly. Source: §2.
- **D-20 [locked]:** Receipt photos live in the app directory with only their paths in the document and are never backed up, because `appDataFolder` counts against the user's Drive quota and photo upload needs multipart, resumable and retry; the consequence must be stated on the restore screen itself, not hidden in an FAQ. Source: §4.3.
- **D-21 [locked]:** Migration policy is additive only — only add fields, never rename, never delete; `json_serializable` ignores unknown fields, so old backups stay readable and new backups do not crash older app versions, and the migrate function must run on both local and restored data. Source: §4.4.
- **D-31 [locked]:** `domain/` is pure Dart and must not import `package:flutter/...`, so the whole business logic runs under plain `dart test`; no `services/`, `utils/` or `helpers/` directories full of tiny files. Source: §12.
- **D-33 [locked]:** Seven screens, no more — onboarding, home, notes list, note editor, settings, item detail, and the service-log modal sheet; ODO update is a modal sheet, not a screen. Source: §11, §3.2.

### Backup and restore

- **D-06 [locked]:** Synchronisation is whole-document backup/restore to Google Drive `appDataFolder` (file `motonote-backup.json`) — no sync protocol, no merge, no conflict resolution. Source: §1, §7.
- **D-22 [locked]:** Request only the `drive.appdata` scope, which Google classifies as non-sensitive and which needs only basic app verification rather than sensitive-scope review or a paid security assessment; the accepted trade-off is that the user cannot see or copy the backup file, compensated by an "Xuất file" button so Drive covers changing phone and export covers changing account. Source: §7.2, Appendix B.
- **D-23 [locked]:** Automatic backup may use `silentToken()` only, because `authorizeScopes()` must originate from a user action on some platforms; a null token records the error and shows one line in Settings instead of popping a sign-in dialog mid-flow, and automatic backup never shows a toast or a spinner. Source: §7.3, §7.5.
- **D-24 [locked]:** Restore is a full overwrite and never a merge, protected by three layers — offered in onboarding only when the device has no data, an explicit side-by-side comparison when it does, and a pre-restore snapshot with a 7-day "Hoàn tác khôi phục" button. Source: §7.6.
- **D-25 [locked]:** Set `android:allowBackup="true"` so Android Auto Backup acts as a free safety net for users who change phone without ever enabling Drive backup, accepting that it only restores on reinstall on a new Android device, is invisible, and cannot be triggered. Source: §7.7, Appendix B.

### Catalog and due engine

- **D-08 [locked]:** The odometer is estimated from a user-supplied average km/day that the app progressively refines from real ODO readings. Source: §1, §9.
- **D-09 [locked]:** REJECTED importing data from Google Maps Timeline, recorded so it need not be re-researched — there has never been a read API; Google moved Timeline on-device in late 2024, disabled it on the web on 2025-06-09 and dropped it from Takeout with retention cut to 3 months; the file format is undocumented, differs per platform and changed three times in three years; and most importantly the data cannot set ODO because it only records trips when location is on and the phone is carried, and it also records taxi and passenger rides. Source: §1, §1.1.
- **D-26 [locked]:** The parts catalog is hardcoded in a Dart file inside the app rather than fetched, because there is no server and maintenance intervals change rarely enough that shipping a release to update them is acceptable. Source: §8.1, Appendix A.
- **D-27 [locked]:** Oil grade drives the service interval — choosing a grade at onboarding step 5 automatically updates the engine-oil `intervalKm`/`intervalMonths` and shows the result immediately, while stating that these are general recommendations and the manufacturer's manual is authoritative per model. Source: §8.3.
- **D-28 [locked]:** Every item may carry both `intervalKm` and `intervalMonths` and the due date is whichever comes first; the time axis cannot be dropped because oil degrades even when the bike is not ridden, and dropping it would make the app wrong for the many low-mileage riders in Hà Nội and TP.HCM. Source: §9.4.
- **D-32 [locked]:** Automated tests cover exactly three files — `test/domain/due_test.dart`, `test/domain/odo_test.dart`, and `test/data/app_data_repository_test.dart` — all targeting pure functions or a constructor-injected repository with no mocks and no widget tests; UI is verified by hand on a real device. Source: §9.6. **Amended by P1-D-11** (Phase 1): §9.6's own rationale is about widget tests and mocks and about the UI being better checked by hand, not about the data layer; with `AppDataRepository`'s `Directory` injected through its constructor, the repository is plain `dart:io` with no mock and no widget tree, so it runs under the same plain `dart test` this decision already endorses — without the amendment, the single code path standing between the user and total data loss would be exercised once by hand and never again across the remaining five phases.

### Notifications

- **D-07 [locked]:** All notifications are local notifications scheduled by the app with the OS via `flutter_local_notifications` — no push, because there is no server; this works offline, needs no FCM credential and costs nothing to operate. Source: §1, §10.
- **D-29 [locked]:** `rescheduleAll()` calls `cancelAll()` and then schedules individual dated notifications rather than using repeating schedules, because repeating schedules cannot recompute content that changes daily and behave inconsistently across iOS and Android ROMs; the cost is tens of milliseconds, so over-calling is preferred to under-calling. Source: §10.4.
- **D-30 [locked]:** Do not block features on the exact-alarm permission — from Android 14 it is not auto-granted on fresh install, so a refusal falls back to inexact scheduling (a few hours late is acceptable for a maintenance reminder), and a refused notification permission leaves the app fully usable with only a soft prompt line in Settings. Source: §10.3.

### Post-1.0

- **D-36 [proposed]:** The first work item after 1.0 is a fuel log ("Nhật ký đổ xăng"), which solves the exact problem the Google Maps import was meant to solve — riders refuel weekly while looking straight at the odometer, so a fast fill-up form makes ODO entry a natural side effect and lifts entry frequency from about once a month to about four times a month, at a cost of one form screen and one model class. Source: §13.3.

</decisions>

## Open Questions

Both questions below were **resolved in `.planning/phases/02-onboarding-catalog-estimation-engines/02-CONTEXT.md`**
during `/gsd-discuss-phase 2` and are kept here only as a record of what was decided and why:

- ✓ **Onboarding default item set → P2-D-01.** `defaultOn` in `kCatalog` is the single source of
  truth for which items are pre-checked; §8.2's "8 of 15" reading is superseded. This also resolves
  the one WARNING in `.planning/INGEST-CONFLICTS.md`.
- ✓ **ODO estimation error threshold → P2-D-09.** Defined as **±7 days of due-date error**, which is
  what Phase 6's one-month soak (REL-08) now measures against.

<details>
<summary>Original wording of both questions</summary>

- **Onboarding default item set (deferred by the user, do not resolve unilaterally).** §8.2 and §6 specify
  8 pre-checked items out of 15 with a stated "6–8" principle, while Appendix A's `defaultOn` flags
  filtered by `appliesTo` yield 11 of 20 for scooter, 11 of 17 for underbone and 12 of 19 for manual — and
  `battery` (Ắc quy) is listed as advanced in §8.2 while carrying `defaultOn: true` in Appendix A. Both
  variants are preserved verbatim in `.planning/intel/constraints.md` under "Item-selection screen rules"
  and "Catalog data (Appendix A)". Surfaces in Phase 2's `/gsd-discuss-phase`.
- **The ODO estimation error threshold.** The 1.0 success metric requires estimation error to stay "within
  the documented threshold", but the source document never defines one. It must be decided and written
  down in Phase 2 so Phase 6's one-month soak has something to measure against.

</details>

---
*Last updated: 2026-08-29 after Phase 1*
