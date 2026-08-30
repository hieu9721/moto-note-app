# Roadmap: MotoNote

## Overview

MotoNote v1.0 follows the §13 implementation plan of `motonote-v3-flutter.md` in full, targeting an
Android-only Play Store release. The journey starts from an empty repo with no Flutter toolchain
installed: Phase 1 stands up the SDKs, the project scaffold and the single-JSON-document data layer that
everything else depends on. Phase 2 makes the app know things — the parts catalog, oil presets, the
six-step onboarding that creates a bike, and the pure-Dart ODO and due engines that are the only code
covered by automated tests. Phase 3 makes it usable for real on the developer's own bike: home screen,
ODO capture, service logging with part-spec memory, item history and notes. Phase 4 makes it useful
without being opened — local notifications that survive reboots, grouped per vehicle, deep-linked, and
defended against OEM battery management. Phase 5 makes the data survivable: whole-document backup to the
user's own Drive `appDataFolder`, three-layer-safe restore with a 7-day undo, and a local export button
for users who never sign in. Phase 6 polishes and ships: Settings, empty and error states, theme and
icon, privacy policy and OAuth verification, the Appendix B acceptance checklist, a one-month real-use
soak, and Play Store review.

Week 0 "làm quen Dart/Flutter" is deliberately absent — the developer treats language familiarisation as
preparation outside this plan. The §13.1 descoping order is deliberately not applied: Google Drive backup
is in 1.0.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Toolchain, Scaffold & Data Layer** - Flutter installed, project created per §12, and one JSON document that survives a force-stop (completed 2026-08-29)
- [x] **Phase 2: Onboarding, Catalog & Estimation Engines** - A bike set up in six steps, and the pure-Dart engines that know when each item is due (completed 2026-08-30)
- [ ] **Phase 3: Home, Logging & Notes** - Usable for real on the developer's own bike
- [ ] **Phase 4: Local Notifications** - The right reminder on the right day, even on a Xiaomi
- [ ] **Phase 5: Google Drive Backup & Restore** - Lose the phone, get everything back
- [ ] **Phase 6: Polish & Play Store Release** - 1.0 live on the Play Store

## Phase Details

### Phase 1: Toolchain, Scaffold & Data Layer

**Goal**: The project exists, builds and runs on a real Android device, and anything written to disk survives a crash, a force-stop and a schema upgrade.
**Depends on**: Nothing (first phase)
**Requirements**: SETUP-01, SETUP-02, SETUP-03, SETUP-04, SETUP-05, SETUP-06, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05, DATA-06, DATA-07, DATA-08, DATA-09
**Success Criteria** (what must be TRUE):

  1. `flutter run --release` installs MotoNote on a real low-end Android device (3–4 GB RAM) and it starts without crashing.
  2. `flutter analyze` reports no warnings, `dart format .` produces no changes, and `dart run build_runner build --delete-conflicting-outputs` regenerates every model from a clean checkout.
  3. A document written to `appdata.json` is still intact after a force-stop and after a device reboot, and a deliberately corrupted primary file loads from `appdata.backup.json` instead of losing data.
  4. A JSON document stamped with an older `schemaVersion` loads through `migrateRaw` with no field lost and no crash.

**Plans:** 6/6 plans complete

Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Scaffold, resolve the §3.1 dependency set, and prove end to end that the state document round-trips through an atomic write

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — Android build target: frozen identity, minSdk 26, core library desugaring, and the Auto Backup exclusion that keeps receipt photos on the device
- [x] 01-03-PLAN.md — The remaining §4.2 models, the complete root document, and the committed fixture that turns the additive-only rule into a red test

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-04-PLAN.md — Repository hardening: three load outcomes, corrupt-file quarantine, forward-version refusal, serialised writes, and the 200 KB budget

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-05-PLAN.md — One serialised mutation funnel, hydrate before render, the two inert service seams, and the three device criteria recorded as pending UAT

**Wave 5** *(gap closure — blocked on Wave 4 completion and on UAT diagnosis)*

- [x] 01-06-PLAN.md — Gap closure for G-01-5 / G-01-W3 / G-01-W5: extract the mutation serialisation into a pure-Dart `SerialQueue` so DATA-03's ordering is testable under plain `dart test`, give the post-persist side effects a failure boundary that cannot reject the caller, and stamp `updatedAt` in UTC at every write site

**Notes**: Toolchain is ready — Flutter 3.47.2 / Dart 3.13.2 stable, Android SDK 36.1.0 with `cmdline-tools` and licences accepted; `flutter doctor` passes the Android check. `flutter create` has not been run, so scaffolding is part of this phase. Criterion 1 still needs a **real** low-end Android device (3–4 GB RAM) with USB debugging — none is connected, and an emulator does not satisfy it. §3.1's version pins are reference points only; verify with `flutter pub outdated` and read the `google_sign_in` and `freezed` CHANGELOGs first (§15 R7).

### Phase 2: Onboarding, Catalog & Estimation Engines

**Goal**: A first-time user sets up their bike in six steps, and the app can say — honestly, including when it is only guessing — when each maintenance item is next due.
**Depends on**: Phase 1
**Requirements**: CAT-01, CAT-02, CAT-03, ONB-01, ONB-02, ONB-03, ONB-04, ONB-05, ODO-01, ODO-02, ODO-03, DUE-01, DUE-02, DUE-03, DUE-04, DUE-05, DUE-06, DUE-07
**Success Criteria** (what must be TRUE):

  1. A first-time user completes the six-step setup — type, name and plate, ODO plus average km per day, item selection, oil grade, last oil change — and lands on the app with their bike and its enabled items created; that data survives a force-stop.
  2. Selecting an oil grade immediately changes the engine-oil interval and shows "Với nhớt bán tổng hợp, app sẽ nhắc bạn mỗi ~2.500 km hoặc 4 tháng.", alongside the statement that these are general recommendations.
  3. Answering "Không nhớ" at step 6 leaves the app silent for a full cycle rather than firing a wrong reminder, and the item is marked as a guessed baseline.
  4. `dart test test/domain/` passes every case listed in §9.6 — including the 23-hour no-drift case, the `avgDailyKm = 0` guard, and the under-14-day and negative-delta skips in `refineAvgDailyKm`.
  5. For a bike that has sat unused for months, the due date comes from the time axis rather than the km axis.

**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Tracer: one maintenance item end to end — welcome → type → ODO → single-`_mutate` commit → `computeDue` → a real due date on screen
- [x] 02-02-PLAN.md — *(wave 2)* The other 23 Phụ lục A entries, `kOilPresets`, the `iconKey` map that keeps `lib/domain/` Flutter-free, and steps 4 and 5
- [x] 02-03-PLAN.md — *(wave 2)* `refineAvgDailyKm` with the five §9.6 cases, `latestReadingFor`, and `addOdoReading`
- [x] 02-04-PLAN.md — *(wave 2)* `due_test.dart`: the six remaining §9.6 cases plus the six §9.6 leaves out — the status ladder, the axis tie-break, the guessed baseline, and `_timeProgress`'s locked formula
- [x] 02-05-PLAN.md — *(wave 3)* Steps 2, 3 and 6 — the P2-D-07 bands, the P2-D-08 bound, the §6.1 baseline table, and the force-stop UAT on real hardware

**Wave 2** *(blocked on Wave 1 completion; 02-02, 02-03 and 02-04 have no file overlap and run in parallel)*

**Wave 3** *(blocked on 02-02 and 02-03)*

**UI hint**: yes
**Open questions** *(both RESOLVED in `02-CONTEXT.md` — kept for the audit trail)*:

  1. **RESOLVED by P2-D-01** in favour of Appendix A: `defaultOn` is the single source of truth, giving scooter 20/11/9, underbone 17/11/6, manual 19/12/7. *(Deferred by the user at ingest.)* The onboarding item-selection defaults have two incompatible definitions in the source. §8.2 states the principle "mặc định tích sẵn 6–8 hạng mục quan trọng nhất" and its mockup pre-checks exactly 8 of 15 items for a scooter, with a collapsed "▸ 7 hạng mục nâng cao" row; §6 step 4 repeats "(8 mục tích sẵn)". Appendix A's `defaultOn` flags filtered by `appliesTo` instead yield 11 pre-checked of 20 applicable for scooter, 11 of 17 for underbone and 12 of 19 for manual — and `battery` (Ắc quy) is listed inside §8.2's advanced group while carrying `defaultOn: true` in Appendix A (as do brake_pad_r and insurance). Both variants are preserved verbatim in `.planning/intel/constraints.md` under "Item-selection screen rules" and "Catalog data (Appendix A)". Full detail: `.planning/INGEST-CONFLICTS.md`.
  2. **RESOLVED by P2-D-09/P2-D-10**: the threshold is ±7 days of due-date drift, computed as `|estimated ODO − actual ODO| / avgDailyKm` and anchored to the `leadDays` default of 7; Phase 6 measures it offline by recomputing from `OdoReading` history, with no schema field and no in-app measurement feature. The v1.0 success metric requires ODO estimation error to stay "within the documented threshold", but the source document never defines one.

### Phase 3: Home, Logging & Notes

**Goal**: The app is usable for real on the developer's own bike — it answers "does my bike need anything?" in two seconds and recording a service takes seconds, not retyping.
**Depends on**: Phase 2
**Requirements**: HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06, ODO-04, LOG-01, LOG-02, LOG-03, LOG-04, LOG-05, NOTE-01, NOTE-02
**Success Criteria** (what must be TRUE):

  1. Opening the app answers "does my bike need anything?" at a glance — overdue items in red at the top, healthy items collapsed into one "9 hạng mục khác đang ổn ›" row, and estimated km prefixed with `~`.
  2. The user updates the odometer from the home FAB in a few taps on the self-drawn keypad, with the estimate prefilled, the previous reading shown, and a lower-than-previous value blocked unless they confirm the odometer was replaced.
  3. The user records one workshop visit covering several items at once, and each item with `resetsCycle` resets its cycle, stores its part brand, spec and cost, and stops being a guessed baseline.
  4. Recording the same item a second time prefills brand and spec from last time with "↳ giống lần trước", and the item detail screen shows the full history behind it.
  5. The user writes and pins a note and sees it on the home screen where it is visible at the workshop.

**Plans**: 4/6 plans executed

Plans:
**Wave 1**

- [x] 03-01-PLAN.md — Tracer: `go_router` three-tab shell boots into the real vehicle header and due list (HOME-01, HOME-02, NOTE-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-02-PLAN.md — Foundations: BL-01 draft move, the `DueResult` honesty split, onboarding's setup `OdoReading` (HOME-05, ODO-04)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03-03-PLAN.md — ODO update sheet with the self-drawn keypad, and the home FAB (ODO-04, HOME-04)
- [x] 03-04-PLAN.md — `addServiceLog` and the multi-item service-log sheet (LOG-01…04)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 03-05-PLAN.md — Item detail with full history, note CRUD and the note editor (LOG-05, NOTE-01, NOTE-02)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 03-06-PLAN.md — Home assembled: §9.5 cards, the 30-day cut, the collapsed row, pinned notes (HOME-03, HOME-05, HOME-06)

**UI hint**: yes

### Phase 4: Local Notifications

**Goal**: The user is reminded on the right day without ever opening the app, on the Android ROMs that actively try to prevent it.
**Depends on**: Phase 3
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08, NOTIF-09, NOTIF-10, NOTIF-11
**Success Criteria** (what must be TRUE):

  1. With the device clock moved forward on a real Xiaomi or Samsung device, the expected notification arrives on the expected date — and still arrives after the device is rebooted.
  2. Four items due for the same bike on the same day arrive as one grouped notification, not four.
  3. Tapping a "sắp tới hạn" notification opens that vehicle's due tab, and tapping the monthly reminder opens the ODO sheet — including when the app was fully closed beforehand.
  4. Refusing the notification permission or the exact-alarm permission leaves every feature working, with only a soft prompt line in Settings and inexact scheduling as the fallback.
  5. On a Xiaomi device the app shows the Xiaomi-specific battery instructions and its button opens the system battery-optimisation page; if 45 days pass with items due and nothing fired, the "Có vẻ thông báo không hoạt động" banner appears.

**Plans**: TBD

### Phase 5: Google Drive Backup & Restore

**Goal**: The user can lose or replace their phone and get their entire maintenance history back — and a user who never signs into Google loses nothing else.
**Depends on**: Phase 4
**Requirements**: BKP-01, BKP-02, BKP-03, BKP-04, BKP-05, BKP-06, BKP-07, BKP-08, BKP-09, BKP-10, BKP-11, BKP-12, BKP-13, BKP-14, BKP-15
**Success Criteria** (what must be TRUE):

  1. Reinstalling the app on a different device, signing in and restoring recovers 100% of the maintenance history, with the photo exclusion stated on the restore screen itself rather than hidden in an FAQ.
  2. Google sign-in succeeds on a `--release` build, not only in debug — all three SHA-1 fingerprints registered.
  3. Automatic backup runs without ever showing a toast, a spinner or a sign-in dialog; a revoked permission surfaces only as "Lần sao lưu cuối: … · Có lỗi" in Settings, and "Sao lưu ngay" reports its result clearly.
  4. Restoring over existing data shows the side-by-side comparison first (including "⚠ Bản trên Drive CŨ HƠN" when it applies), and "Hoàn tác khôi phục" puts the previous data back within 7 days.
  5. Every feature still works for a user who has never signed into Google, and "Xuất file" hands them their JSON.

**Plans**: TBD
**UI hint**: yes
**Notes**: §15 R6 — a missing SHA-1 makes sign-in fail *silently* with no clear error, and §13 records that the OAuth work always takes longer than expected. §15 R7 — read only the `google_sign_in` official README; ignore any article written before 2025.

### Phase 6: Polish & Play Store Release

**Goal**: MotoNote 1.0 is live on the Play Store and has been proven correct by a month of real riding.
**Depends on**: Phase 5
**Requirements**: SET-01, SET-02, SET-03, REL-01, REL-02, REL-03, REL-04, REL-05, REL-06, REL-07, REL-08, REL-09, REL-10
**Success Criteria** (what must be TRUE):

  1. Every item on the Appendix B technical acceptance checklist passes on a `--release` build on a real low-end Android device and on a real Xiaomi or Samsung device.
  2. The user manages vehicles and items in Settings, edits any interval and sees the "these are general recommendations, the manufacturer's manual is more accurate" caveat, and can delete all their data from inside the app.
  3. After ~1 month of real use on the developer's own bike, notifications fired on the expected dates, ODO estimation error stayed within the documented threshold, and no scheduled work was killed by OEM battery optimisation.
  4. MotoNote 1.0 passes Play Store review and is live, with the Appendix B Google Cloud/OAuth and Android checklists complete and a public privacy policy published.

**Plans**: TBD
**UI hint**: yes
**Notes**: The Appendix B iOS section is out of scope for this milestone. `BACKLOG.md` must exist and absorb every idea raised during the build (§13.2, §15 R10).

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Toolchain, Scaffold & Data Layer | 6/6 | Complete    | 2026-08-29 |
| 2. Onboarding, Catalog & Estimation Engines | 5/5 | Complete    | 2026-08-30 |
| 3. Home, Logging & Notes | 4/6 | In Progress|  |
| 4. Local Notifications | 0/TBD | Not started | - |
| 5. Google Drive Backup & Restore | 0/TBD | Not started | - |
| 6. Polish & Play Store Release | 0/TBD | Not started | - |

---
*Roadmap created: 2026-08-28 from the ingest of motonote-v3-flutter.md*
*Coverage: 86 of 86 v1 requirements mapped, 0 unmapped*
