---
gsd_state_version: 1.0
milestone: v1.0
current_phase: 05
current_phase_name: Google Drive Backup & Restore
status: executing
stopped_at: Phase 5 gap closure planned — 3 plans (05-08…05-10), waves 7–8
last_updated: "2026-09-01T12:46:12.182Z"
last_activity: 2026-09-01
last_activity_desc: Phase 05 execution started
state_head: d1ae92a1afd78a7aa6921474810f5fe70bcaa501
progress:
  total_phases: 6
  completed_phases: 4
  total_plans: 35
  completed_plans: 32
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-01)

**Core value:** The user gets reminded on the right day that their bike needs something — accurately enough that they never turn the notifications off.
**Current focus:** Phase 05 — Google Drive Backup & Restore

## Current Position

Phase: 05 (Google Drive Backup & Restore) — EXECUTING
Plan: 1 of 10
Status: Executing Phase 05
Last activity: 2026-09-01 — Phase 05 execution started

Progress: [████████████████░░░░] 32/35 plans (Phases 01–04 of 6 complete; Phase 05 executed with gaps — 3 closure plans ready)

**Next command:** `/gsd-execute-phase 05 --gaps-only` — 3 gap-closure plans across waves 7–8.

### Phase 05 planned (2026-09-01) — 7 plans, 6 waves, plan-checker passed

Research (`05-RESEARCH.md`, 105 KB) verified the `google_sign_in` 7.2.0 and `googleapis` 17.0.0 API
surfaces against the actual resolved pub-cache source rather than from memory — 6.x's `signIn()` /
`signInSilently()` / `AccessCredentials` do not exist in the resolved versions, which is why §7.4's
hand-built-credentials sketch is superseded by P5-D-12. Pattern mapping found analogs for 13/13
files. `05-VALIDATION.md` records that this phase's automated surface is unavoidably thin: only the
day-counting predicates in the new `lib/domain/backup_timing.dart` (P5-D-18, the third D-32
amendment) and the pre-restore snapshot file I/O are `dart test`-reachable; OAuth and Drive I/O are
manual-only, the same honest shape as Phase 4's OEM battery-hint gaps.

Tracer-first: `05-01` is one end-to-end slice (Cloud Console config → `google_auth.dart` →
`drive_service.dart` → a user-visible "Sao lưu ngay" result) verified before waves 2–6 expand on it.
`COVERAGE.md` decides all 49 Drive/Sign-In capabilities — 17 INTEGRATE, 32 reasoned OPT-OUT.
Spec-less probe fallback ran (no SPEC.md): 22 edges — 11 explicit + 3 backstop authored into
`must_haves.truths`, 8 unclassified surfaced as flagged assumptions. 22/22, no silent drops.

**Two things that need a human before or during execution:**

1. **`05-01` task 1 is a blocking human-action gate.** No Google Cloud project exists in this repo.
   It creates the project, enables the Drive API, registers the debug-keystore SHA-1 for
   `io.github.hieu9721.motonote`, and returns the Web client ID. Nothing downstream can be verified
   until it is done. BKP-01 closes **partial by design** (P5-D-11) — the release-keystore SHA-1
   (REL-03) and the Play App Signing SHA-1 (REL-09) are Phase 6 handover items.

2. **`05-02` task 1 is an unresolved `checkpoint:decision` that CONTEXT.md did not anticipate.**
   P5-D-15 requires `hydrate()` to stop calling `_mutate` on every open, but `_mutate` is also the
   only member allowed to assign `state` (DATA-06) *and* it stamps `updatedAt` — so today that field
   means "when the app was last opened", and §7.6's `Trên máy: … sửa 2 giờ trước` line plus the
   `⚠ Bản trên Drive CŨ HƠN` warning both read it. The planner's recommendation is
   `adoption-exception` (amend DATA-06 to name hydration as adoption, not mutation), tabled as
   **P5-D-27**. Per the Phase 3 D-33 precedent a locked decision is amended by the user, not
   reinterpreted by the planner — so this is deliberately left open.

**Decision-coverage gate override (7th recurrence of the known parser mismatch).**
`check.decision-coverage-plan` returned `passed: false, reason: could-not-parse, total: 0,
uncovered: []` — the handler expects `- **D-NN:**` bullets and this project namespaces its
phase decisions `P5-D-NN`, so it extracts nothing and names no uncovered decision. This is a
false negative, not a coverage gap: verified independently by grep, **17/17** trackable decisions
(P5-D-01…P5-D-17, none under Claude's Discretion) appear in the plans, zero uncovered. The gate was
overridden on that evidence. `/gsd-verify-work` should re-surface it; the underlying handler bug is
recorded in `05-CONTEXT.md` § "Known parser issue".

Ten planner decisions (**P5-D-18…P5-D-30**) resolve CONTEXT.md's Claude's-Discretion items and three
things research left open; they are tabled in `05-01` (18–26), `05-02` (27), `05-05` (28–29) and
`05-06` (30). Two catch defects nobody had spotted: P5-D-19 (writing the backup result through
`_mutate` would itself schedule another backup, unbounded) and the `_ensureInit()` `Future`-not-`bool`
race that both RESEARCH and PATTERNS sketch wrongly.

### Phase 04 closed (2026-09-01) — UAT 5/5 passed, 0 issues

All seven plans executed (`04-01`…`04-04` original, `04-05`…`04-07` gap closure). `04-VERIFICATION.md`
advanced `gaps_found` → `human_needed` → `passed`; `04-SECURITY.md` `threats_open: 0`; `04-VALIDATION.md`
and `04-UI-REVIEW.md` (21/24) closed. On-device UAT ran on the real SM-A066B (Android 16, release APK)
on 2026-09-01 07:26–08:54 +07 and cleared all five success criteria — arrival + reboot survival (SC1),
one grouped notification for four same-day items (SC2), cold-start deep links to the due tab and the ODO
sheet (SC3), full functionality under a genuine POST_NOTIFICATIONS denial plus all three exact-alarm
round-trip legs (SC4), and the 45-day dead-notification banner (SC5).

One accepted limitation, recorded not hidden, under the standing P4-D-18 rule: **the Xiaomi/Oppo/Vivo
battery-hint branches ship unexercised** — only a Samsung device was available, so only the Samsung
branch and its `IGNORE_BATTERY_OPTIMIZATION_SETTINGS` intent were confirmed. Same standing as Phase 1's
un-exercisable API≤30 backup path.

Three observations were recorded in `04-UAT.md` and belong in BACKLOG.md under D-34, not in a Phase 4
gap plan — all three are consequences of decisions already locked in this phase:

1. `rescheduleAll()`'s opening `cancelAll()` (D-29) also clears *displayed* notifications, so opening the
   app for any reason wipes an unread reminder from the shade.

2. A cold start alone never reschedules — `_LifecycleRescheduler` registers its observer after the app is
   already resumed, so rescheduling happens only on a mutation or a real background→foreground trip.

3. The §10.4 ODO body can read "Xe Xe của Đạt" when the vehicle is itself named "Xe của Đạt". Copy is
   verbatim per spec; the doubling is data-driven, not a code defect.

### Gap-closure plan set (planned 2026-08-31, `/gsd-plan-phase 04 --gaps`) — all three executed and closed

Scope was **closed by the user** to exactly three items; the rest was routed to BACKLOG.md under D-34.

| Plan | Wave | Closes | Autonomous |
|------|------|--------|------------|
| `04-05` | 1 | CR-01 — strictly-after-now filter on the monthly ODO loop + offset-independent tests | yes |
| `04-06` | 1 | CR-02 — exact-alarm grant written from the resume path behind a consumable pending flag | **no** (one `checkpoint:decision`) |
| `04-07` | 2 (`depends_on: 04-05, 04-06`) | REQUIREMENTS.md NOTIF-04/-05/-07 checkbox + traceability sync | yes |

`gsd-plan-checker` returned **VERIFICATION PASSED on iteration 1**, zero blockers, zero warnings, and
independently re-derived the CR-01 arithmetic, the D-32 amendment count, and the 7-in/7-out edge-probe
accounting. `04-01`…`04-04` are byte-identical — commit `e128967` touches only the three new plans,
`COVERAGE.md` and `ROADMAP.md`.

Three things to know before dispatching:

1. **`04-06` task 1 is a blocking `checkpoint:decision` rated `one-way`, and `AUTO_MODE` is false, so it
   WILL surface.** The question: introduce this project's first `flutter_test` widget test for the
   exact-alarm round-trip (Option A — a third amendment to locked D-32, against the one clause its text
   still names explicitly), or route it to a scoped UAT row (Option B). The planner recommends **B** on a
   substantive argument, not a cost one: Option A's fake has to model
   `requestExactAlarmsPermission()`'s fire-and-forget semantics correctly to catch anything, and
   misreading that exact semantic is what *caused* CR-02 — a fake written from the same mental model
   passes against the broken code. If A is chosen, the plan records it as `P4-D-19`.
   Note the phase's own recorded anti-pattern: a `checkpoint:decision` whose answer was already in
   CONTEXT once burned ~147K tokens producing nothing. This one is genuinely unresolved in CONTEXT —
   embed the answer in the dispatch prompt via a `<checkpoint_resolution>` block once it is made.

2. **CR-01's fix changes an existing assertion from 6 to 5, and that is correct, not a regression.**
   Once the filter lands, `planNotifications` returns **5** ODO reminders whenever `now` is at or past
   the current month's `odoReminderDayOfMonth`/`notifyHour` — most days under the defaults. The
   `hasLength(6)` assertion is repaired to 5, and a new test at `now = 1 Aug 2026 07:00` local pins 6 so
   NOTIF-06's six-month span stays literally covered. The loop was deliberately NOT widened to seven
   months to preserve the count; the checker confirmed NOTIF-06 is not narrowed by this (the candidate
   window is intact, only an already-passed slot is dropped) and that NOTIF-06 is outside `04-07`'s
   re-tick scope anyway.

3. **A real latent defect was found and deliberately left out — file it to BACKLOG.** WR-02's timezone
   fragility is not confined to the one named test: fixtures throughout `notification_plan_test.dart`
   state `now`/`lastServiceDate` via `DateTime.utc(...)` while `due.dart` normalises through `toLocal()`,
   so several due-date assertions can shift by a calendar day at extreme offsets. Both the planner and
   the checker confirmed this by grep. `04-05` fixes only the ODO branch and the one named test; the
   four new/repaired tests are self-contained with local-clock fixtures, so they can still be trusted.
   Re-basing every fixture is a much larger repair than the closed scope allowed.

**Also written:** `04-local-notifications/COVERAGE.md` — a reasoned *no external API integration*
declaration. The api-coverage detector fired `detected: true` on the noun `sdk` inside `04-02-PLAN.md`'s
D-31 purity phrase *"imports no Flutter SDK library"* — i.e. it matched a claim of integrating with
**nothing**. Confirmed a false positive by re-reading scope; a declaration was written rather than a
fabricated matrix, which the seal-time gate accepts.

Deferred to BACKLOG under D-34, by explicit user decision, not oversight: WR-01 (the two independent
one-shot post-frame effects in `home_screen.dart:82-90`), the `Colors.grey` literal at
`settings_screen.dart:173`, merging the two near-duplicate battery-hint fallback strings, and the
UTC-fixture fragility in item 3. All five `behavior_unverified_items` were closed on-device on
2026-09-01 — see the Phase 04 closed block above.

### Planning gate note — §13a decision coverage (2026-08-31, Phase 04 gap closure — sixth recurrence)

`check.decision-coverage-plan` returned the same `passed: false`, `reason: could-not-parse`, `total: 0`,
`uncovered: []` against `04-CONTEXT.md`'s `P4-D-NN` namespace. **Parser mismatch, not a coverage gap** —
the gate named no missing decision because it extracted none. Coverage was verified twice
independently, by the orchestrator's grep and by `gsd-plan-checker`, and is **18/18** across all seven
plans: P4-D-01 (04-01, 04-05), P4-D-02/03/04 (04-01), P4-D-05/06 (04-03), P4-D-07 (04-01, 04-02, 04-03,
04-06), P4-D-08 (04-03), P4-D-09 (04-01, 04-04), P4-D-10/11 (04-04), P4-D-12 (04-02, 04-04),
P4-D-13 (04-01, 04-02, 04-05, 04-06, 04-07), P4-D-14 (04-02, 04-04, 04-05, 04-07), P4-D-15 (04-01,
04-05), P4-D-16 (04-01, 04-02, 04-05), P4-D-17 (04-01, 04-02, 04-05, 04-07), P4-D-18 (04-01, 04-02,
04-04). Proceeded on the precedent already recorded five times below rather than renaming the ids.
The advisory `gap-analysis.plan-post` gate reported the same `extracted 0 of N` for the same reason,
alongside `✓ All 11 items covered by plans`. Verify-phase should re-surface the *parser* issue.

Phase 04 ran clean mechanically: `flutter analyze` No issues, `dart test` 103/103, regression gate
64/64 on Phases 01–03, all three `execute:wave:post` capability gates green, `04-UI-REVIEW.md` 21/24.
What it did **not** do is work correctly in two places, both confirmed by reading the source three
times over (code reviewer, orchestrator, verifier) — see Blockers below.

Also still true for Phase 04: §10.6's OEM behaviour is only observable on the real SM-A066B, SC1's
clock-move must be asked for before it is done, and the decision-coverage gate fail-parses the
`P4-D-NN` namespace (verify by grep, do not rename ids).

### Planning gate note — §13a decision coverage (2026-08-30, Phase 03 — closed)

`query check.decision-coverage-plan` returned `passed: false`, `reason: could-not-parse`, `total: 0`.
**This is a parser namespace mismatch, not a coverage gap.** `03-CONTEXT.md` deliberately numbers its
decisions `P3-D-NN` (phase-scoped, stated at its line 29, to keep them distinct from PROJECT.md's
`D-01…D-36`); the gate's extractor only matches `- **D-NN:**` bullets, so it parsed zero decisions and
failed closed.

Equivalent check run by hand at plan time: **18 of 18** `P3-D-01…P3-D-18` are cited by at least one
`03-*-PLAN.md`; zero uncovered. `03-07-PLAN.md` cites `P3-D-10` and `P3-D-12`.

Recorded so verify-phase re-surfaces the *parser* issue, not a phantom dropped decision. Nothing was
overridden and no coverage gap was accepted. Fixing this properly means teaching the extractor the
`P{N}-D-NN` form — renaming the decisions is not an option, as six executed plans and their SUMMARYs
already cite the `P3-D-NN` ids.

## Performance Metrics

**Velocity:**

- Total plans completed: 25
- Average duration: —
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 6 | - | - |
| 02 | 5 | - | - |
| 03 | 7 | - | - |
| 04 | 7 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (`<decisions>` block, D-01 … D-36 —
34 locked, 2 proposed). Recent decisions affecting current work:

- D-05 / D-15: The entire app state is one JSON document — the source calls this the most important architectural decision of the project.
- D-31: `domain/` is pure Dart and must never import Flutter, so business logic runs under plain `dart test`.
- D-13: Freezed + `json_serializable` despite the codegen step — `Vehicle` has 14 fields.
- D-35 [proposed]: §3.1's dependency pins are reference points only; run `flutter pub outdated` and read the `google_sign_in` and `freezed` CHANGELOGs before writing code.

### Pending Todos

None yet.

### Blockers/Concerns

- **Phase 04 residual — three Xiaomi/Oppo/Vivo battery-hint branches ship unexercised.** UAT SC5 on
  2026-09-01 confirmed only the Samsung branch's verbatim copy and its
  `IGNORE_BATTERY_OPTIMIZATION_SETTINGS` intent, because the SM-A066B is the only device available.
  Accepted by the operator under the standing P4-D-18 "record, do not hide" rule, same standing as the
  Phase 1 API≤30 backup path below. Re-test if a Xiaomi/Redmi/Poco device ever becomes available.

- **Phase 04 residual — opening the app clears unread notifications from the shade.** `rescheduleAll()`
  opens with `cancelAll()` (D-29) and the plugin cancels *displayed* notifications as well as pending
  ones; since `rescheduleAll` runs on every mutation and every resume, an unread reminder vanishes the
  moment the user opens the app for any reason. Observed directly during UAT. A consequence of a locked
  decision, so it belongs in BACKLOG under D-34 — not a Phase 04 gap.

- **Phase 04 residual — a cold start alone never reschedules.** `_LifecycleRescheduler` registers its
  observer during the first build, by which point the app is already resumed, so
  `didChangeAppLifecycleState` never fires with `resumed` on a cold start. Rescheduling happens only on
  a mutation or a real background→foreground round trip; stale alarms were observed surviving a cold
  start and clearing only after a background/resume cycle. Matters for Phase 5: a restore must not
  assume a relaunch re-arms the schedule.

- **Phase 04 residual — the §10.4 ODO body can read "Xe Xe của Đạt".** The template is "Xe {name} …"
  and the test vehicle is itself named "Xe của Đạt". Copy is verbatim per spec and the doubling is
  data-driven, not a code defect, but it is user-visible. BACKLOG under D-34.

- **Latent, still open — UTC fixtures in `test/domain/notification_plan_test.dart`.** Fixtures state
  `now`/`lastServiceDate` via `DateTime.utc(...)` while `due.dart` normalises through `toLocal()`, so
  several due-date assertions can shift by a calendar day at extreme offsets. `04-05` fixed only the ODO
  branch and the one named test. Confirmed by both the planner and the checker; deferred to BACKLOG by
  explicit user decision, not oversight.

- **Android test device — RESOLVED in Phase 01.** SM-A066B (Galaxy A06 5G, Android 16 / API 36, 3.43 GB RAM) was used over wireless debugging and satisfied SETUP-06 on a real `--release` build. Keep in mind for later: the device must be re-attached for Phase 4's §10.6 OEM battery-optimisation work, which is still only observable on real hardware.
- **Phase 4 residual (from Phase 01 UAT test 4):** the legacy `auto_backup_rules.xml` (API ≤30) exclusion path carries the identical `domain="root"` fix as the API 31+ rules but has **never been exercised** — the test device is API 36, while `minSdk=26` keeps that path reachable in production. Recorded in `01-SECURITY.md` audit trail.
- **Phase 5 risk (§15 R6):** a missing SHA-1 fingerprint makes Google sign-in fail *silently*; all three keys (debug, release, Play App Signing) must be registered and tested on a `--release` build.
- **Phase 5 carry-forward (accepted risk R-01, `01-SECURITY.md`):** path strings inside a restored document (`ServiceLog.photoPaths`, `Vehicle.photoPath`) must be treated as untrusted and confined to the app-private directory. Zero surface in Phase 01; becomes real the moment restore exists.
- **Three advisory code-review warnings still open** — WR-01, WR-02, WR-04 in `01-REVIEW.md`. Non-blocking, carried forward; `/gsd-code-review 01 --fix` closes them.
- **Nothing is pushed.** 117 local commits, `origin/main` still at `3b41868`. All of Phases 01 and 02 exists only on this machine.
- **Phase 3 must fold in BL-01** (per P3-D-18 in `03-CONTEXT.md`): `lib/state/app_state.dart` imports `OnboardingDraft` from `lib/ui/onboarding/`, and the refactor is to be done *before* `addServiceLog` and the ODO-04 entry point are added, so the new code is written against the correct dependency direction.
- **Phase 3 carry-forward from Phase 02 UAT test 5:** `Vehicle.plate` round-trip is verified only by inference. No screen in the Phase 02 build renders the plate, and `run-as` is blocked on a non-debuggable release build, so "59-X1 123.45" was never observed after a force-stop. HOME-02's header ("Vision · 29A1-234.56 · ~18.665 km · cập nhật 10 ngày") is where it becomes observable — Phase 3's UAT must check it.
- **adb cannot type Vietnamese diacritics.** `input text` throws `NullPointerException: Attempt to get length of null array` because `KeyCharacterMap` cannot map the characters; the default IME is Gboard (not Telex) and `input text` bypasses IME composition anyway. Any future on-device UAT needing accented input requires a human keystroke or ADBKeyboard. Also note the soft keyboard shifts the onboarding button row from y≈1496 to y≈955 — the cause of Phase 02's four failed synthetic taps.
- **Decision-coverage gate override (Phase 1, 2026-08-28):** `check.decision-coverage-plan` returned `passed: false, reason: "could-not-parse", total: 0` when planning Phase 1. Its parser only extracts `- **D-NN:**` bullets, while `01-CONTEXT.md` deliberately namespaces its decisions as `- **P1-D-01:**` to avoid colliding with PROJECT.md's project-wide `D-01…D-36`. Actual coverage was verified two ways — by `gsd-plan-checker` and by direct grep — and is **13/13**: every `P1-D-01…P1-D-13` is cited in at least one plan body and `must_haves`. The user chose to proceed rather than renaming the ids. Verify-phase should re-surface this; the same mismatch will recur for `P2-D-NN` in Phase 2.
- **Decision-coverage gate override (Phase 2, 2026-08-29) — the recurrence predicted above.** `check.decision-coverage-plan` returned the identical `passed: false, reason: "could-not-parse", total: 0` when planning Phase 2, for the identical reason: `02-CONTEXT.md` namespaces its decisions as `- **P2-D-01:**`. Coverage was verified two ways — by `gsd-plan-checker` (VERIFICATION PASSED, 0 blockers) and by direct grep — and is **10/10**: P2-D-01 (02-02, 02-05), P2-D-02/03/04 (02-02), P2-D-05 (02-01, 02-02), P2-D-06 (02-01, 02-05), P2-D-07 (02-01, 02-05), P2-D-08 (02-01, 02-03, 02-05), P2-D-09 (02-01), P2-D-10 (02-01, 02-03). The user again chose to proceed rather than renaming the ids or disabling `workflow.context_coverage_gate`. Verify-phase should re-surface this. **This is now a standing pattern, not an incident** — it will recur for every `PN-D-NN` phase unless the gate's parser learns the namespace or the convention changes.

- **Decision-coverage gate override (Phase 3, 2026-08-30) — the third recurrence, predicted in this file before it happened.** `check.decision-coverage-plan` again returned `passed: false, reason: "could-not-parse", total: 0` against `03-CONTEXT.md`'s `P3-D-NN` namespace. Coverage was verified two ways — by `gsd-plan-checker` (VERIFICATION PASSED on iteration 2, 0 blockers) and by direct grep — and is **18/18**: P3-D-01 (03-01, 03-02, 03-06), P3-D-02 (03-06), P3-D-03 (03-06), P3-D-04 (03-01, 03-03), P3-D-05 (03-04, 03-05), P3-D-06/07/08 (03-04), P3-D-09/10 (03-03), P3-D-11 (03-02), P3-D-12 (03-01, 03-03), P3-D-13 (03-01), P3-D-14/15 (03-05), P3-D-16 (03-01, 03-05, 03-06), P3-D-17 (03-04), P3-D-18 (03-02). Proceeded on the established precedent rather than renaming the ids. Verify-phase should re-surface it.

- **Decision-coverage gate override (Phase 4, 2026-08-30) — the fifth recurrence, predicted in this file before it happened.** `check.decision-coverage-plan` again returned `passed: false, reason: "could-not-parse", total: 0` against `04-CONTEXT.md`'s `P4-D-NN` namespace; note `uncovered: []` — the gate named no actually-missing decision, it simply extracted none. Coverage was verified two ways — by `gsd-plan-checker` (VERIFICATION PASSED, 0 blockers, which grep-confirmed 18/18 independently) and by the orchestrator's own grep — and is **18/18**: every `P4-D-01…P4-D-18` is cited by at least one plan (04-01 cites 11 distinct, 04-02 cites 7, 04-03 cites 4, 04-04 cites 6). Proceeded on the established precedent rather than renaming the ids. Verify-phase should re-surface it. The pattern is now five phases old; it will recur for `P5-D-NN` unless the gate's parser learns the namespace or `workflow.context_coverage_gate` is turned off.

- **D-33 was amended during Phase 3 planning (2026-08-30) — a locked project decision changed.** `gsd-plan-checker` blocked the first plan revision because `03-01`'s `DataIssueScreen` on a top-level `/data-issue` route is an eighth screen, and the planner had justified it by an invalid analogy to Phase 1/2's `_PostOnboardingPlaceholder` (those were temporary and scheduled for deletion; this is permanent product surface). The question was put to the user, who chose to amend D-33 to **7 + 1** rather than fold the state into an existing screen. `.planning/PROJECT.md` D-33 now names the read-only data-issue screen as a single explicit exception outside the seven-screen *feature* cap, and the Anti-Goals bullet points at it. `03-RESEARCH.md`'s original reasoning and its assumption **A3** were annotated as superseded. **The exception is not a precedent** — a new feature screen still needs a new decision. Phase 5 (restore, P1-D-09) may give this screen its first action.

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| Platform | iOS release (Appendix B iOS section) | Deferred past 1.0 | 2026-08-28 (project setup) | v1.0 |
| Feature | Fuel log — "Nhật ký đổ xăng" (D-36, §13.3) | Planned as first post-1.0 work | 2026-08-28 (project setup) | v1.0 |
| Catalog | `emission_check` entry, pending the emissions-inspection regulation | Awaiting external rules | 2026-08-28 (project setup) | v1.0 |

## Session Continuity

Last session: 2026-09-01T03:05:51.851Z
Stopped at: Phase 5 context gathered
Resume file: .planning/phases/05-google-drive-backup-restore/05-CONTEXT.md

Phase 04 is closed. `04-UAT.md` is `complete` (5/5 passed, 0 issues), `04-VERIFICATION.md` is
`passed`, `04-SECURITY.md` has `threats_open: 0`, and ROADMAP.md/STATE.md have transitioned to
Phase 5. Next action is `/gsd-discuss-phase 5` — Google Drive Backup & Restore.

Session notes:

- **Phase 04 closed by `/gsd-verify-work 04` on 2026-09-01.** All five `behavior_unverified_items`
  ran on the real SM-A066B (Android 16 / API 36) against a release APK built from HEAD, 07:26–08:54
  +07, and all five passed with zero issues. One accepted limitation (the unexercised Xiaomi branch)
  and three observations were recorded in `04-UAT.md` rather than hidden; none caused a failure.

- **The installed APK was stale and would have produced a false SC1 failure.** The 2026-08-30 build
  on the device declared neither `RECEIVE_BOOT_COMPLETED` nor `SCHEDULE_EXACT_ALARM`. Always confirm
  the on-device build with `dumpsys package` before trusting an on-device UAT result — a rebuild from
  HEAD was required before SC1 could even be attempted.

- **`am kill`, not `am force-stop`, for cold-start deep-link tests.** `force-stop` also cancels the
  app's posted notifications, destroying the very notification under test. SC3 used `am kill` plus a
  `ps` check for zero processes to get a genuine cold start with the notification intact.

- **Staging constants beat moving the device clock.** SC1, SC2 and SC5 were staged with temporary
  constants (`kUatOdoOffsetMinutes`, `kUatSc2Minutes`, `kUatForceDeadBanner`) reverted with
  `git checkout` afterwards, leaving the real `computeDue`, the real `byDay` bucketing key, `_compose`,
  the sort/cap and `zonedSchedule` all running unmodified. The alternative — back-dating the operator's
  real maintenance history — was rejected as dishonest. SC5's banner was later re-confirmed with no
  staging at all, from the real predicate on real data.

- **The fresh-install leg required pulling and restoring the operator's `appdata.json`.** Done with
  explicit consent; both `appdata.json` and `appdata.backup.json` were restored byte-for-byte (7817
  bytes) and the app came back up with the original vehicle, 11 items, the note and the correct
  7-alarm schedule. Ask before uninstalling; verify the restore by content, not by the app launching.

- **Phase 04 execution started 2026-08-30 and paused inside Wave 1 (commits `ace598d` … `0341e81`).**
  Waves are W1 = 04-01, W2 = 04-02 + 04-03 (parallel — `files_modified` overlap check done, no
  overlap), W3 = 04-04. Resolved run config: `ISOLATION=harness-worktree`, `USE_WORKTREES=true`,
  `PARALLELIZATION=true`, `executor_model=sonnet`, `branching_strategy=none`, `AUTO_MODE=false`.

- **Phase 4's only one-way door is shut.** The notification payload grammar is fixed at `{kind}:{id}`
  — `due:{vehicleId}` → `/`, `odo:{vehicleId}` → `/?sheet=odo`, no `/vehicle/:id` route (P4-D-01,
  P4-D-02, §10.7). Confirmed by the user at 04-01 task 1's blocking checkpoint; the versioned and
  JSON alternatives were presented and declined. Now shipped in `ace598d` and covered by
  `test/domain/notification_plan_test.dart`.

- **04-01 has a production commit but no SUMMARY.md — the `safe_resume_gate` anomaly, live.** Read
  `.continue-here.md`'s Critical Anti-Patterns table before dispatching: its first row is `blocking`.

- **A `checkpoint:decision` whose answer is already in CONTEXT still costs a full agent.** The first
  04-01 executor burned ~147K tokens producing nothing — it hit task 1's blocking gate and stopped to
  ask a question P4-D-01 had already answered. `AUTO_MODE` is false, so a blocking gate always
  surfaces. Fix is to embed a `<checkpoint_resolution>` block in the dispatch prompt.

- **An executor committed past an unmet `<precondition>`.** 04-01 task 2 requires the SM-A066B
  attached (`adb devices` shows one device); no device is connected, and the executor implemented and
  committed anyway. Static checks pass on main (`flutter analyze` clean, 36/36 domain tests) but every
  on-device claim (SC1, SC3, NOTIF-09) is unobserved and belongs in `04-UAT.md`, not in a SUMMARY
  asserting verification.

- **Phase 03 closed by `/gsd-verify-work 03` on 2026-08-30, driven end-to-end over adb against the
  real SM-A066B on a fresh `--release` build of `7b08689`.** All five outstanding human-verification
  items ran and passed; `03-SECURITY.md` was produced by `/gsd-secure-phase 03` (38 threats, 0 open,
  1 documented accepted risk); `03-VERIFICATION.md` was canonicalised to `passed`.

- **The on-device UAT was scripted, not hand-driven, and the technique is worth reusing.**
  `adb exec-out screencap -p` into the scratchpad plus `adb shell input tap/swipe/text`, reading each
  screenshot back before deciding the next tap. Two things learned that will save time in Phase 4:
  `adb shell input text` splits on spaces unless they are written `%s` (a plain quoted string silently
  truncates at the first space — it produced a one-word note body before this was spotted); and the
  ODO sheet's keypad y-coordinates are stable whether or not the lower-than-previous warning is
  showing, because the sheet is bottom-anchored and only its top moves.

- **Two Phase-3 truths were not directly observable from the shipped data and had to be manufactured
  through legitimate in-app actions** — worth knowing before Phase 4's UAT is designed. The `~`
  prefix only appears when `estimateOdo > currentOdoKm`, which needs elapsed time since the last
  reading; and no item was overdue. Both were created without touching the device clock or the
  document: a back-dated `Chỉ kiểm tra` service log moves `odoUpdatedAt` into the past (it is the one
  entry shape that changes the vehicle's odometer while touching no item baseline), and an ODO update
  to 25.000 put an item overdue. `avgDailyKm` was measured at 20 km/day this way.

- **The cancelled-save guard was proven negatively, not just observed.** UAT 3(b) asserts a cancelled
  P3-D-12 confirmation writes nothing. Rather than trusting the absence of a visible change — the
  release build is not debuggable, so `run-as` cannot read `appdata.json` — the check was deferred
  until after the real save, then settled by counting `Lịch sử` rows: exactly one entry per item, and
  no reading at the cancelled value anywhere. Use this shape again; a "nothing happened" claim needs a
  positive count, not an eyeball.

- **Two cosmetic findings were routed to BACKLOG as BL-10, not treated as gaps** (D-34): the service-log
  sheet keeps a stale inline error on screen while the user corrects the field, where the ODO sheet
  clears its error on the first keystroke; and the ODO sheet's `[ Lưu ]` renders below the keypad
  rather than beside it on this device (352 dp of sheet content against its own 360 dp threshold —
  its documented responsive fallback, recorded so it is not re-reported as a defect later).

- **BL-09's promotion trigger did NOT fire.** That entry says to promote it sooner "if the on-device
  UAT for test 2 surfaces it in practice". Test 2's stated expectations never involve a 7-digit
  odometer, so no value above 1.000.000 was entered into the ODO sheet this session. BL-09 remains
  correctly deferred on its original reasoning, un-exercised.

- **Phase 03 plans were replanned on 2026-08-30 to carry the UI design contract (commit `97849e5`).**
  The six plans were authored at 08:37–08:56; `03-UI-SPEC.md` only appeared at 10:18, so a
  `grep "UI-SPEC"` over all six returned zero. The plan-phase `<downstream_consumer>` contract
  requires a UI-SPEC's `## UI Considerations` to be lifted into `must_haves` by the same rule as a
  SPEC's `## Edge Coverage`, and that lift had never happened — 42 resolved design decisions and 2
  backstop items were invisible to both the executor and the verifier. `03-01-PLAN.md` was left
  byte-identical because it is already executed and merged; only 03-02…03-06 were touched.
  `gsd-plan-checker` re-counted the UI-SPEC marks independently and confirmed 42 + 2 landed, each in
  exactly one plan, with no drops and no double-counting.

- **`03-UI-SPEC.md`'s own header count is wrong and was left as-is.** It states "54 applicable — 40
  resolved"; the actual table is 56 rows / 42 resolved / 12 dismissed / 2 backstop. Two rows (H3
  `overflow`, H6 `interactive-control (new-tap)`) were added at kind-confirmation after the probe
  ran, and the header was never updated. Both the planner and the checker arrived at 56/42
  independently. The plans lift from the table, not the header, so nothing downstream is affected —
  but the header should be corrected the next time that file is touched.

- **Three planner adjudications are recorded inside the plans, not just in the transcript** — the
  checker verified this specifically, because a judgment call that lives only in a chat log is
  invisible to `/gsd-execute-phase`:

  1. `03-05` contradicted the UI-SPEC in two places (a notes-tab `FloatingActionButton` and an inline
     per-row pin button, against H6's `AppBar` action and pin-only-from-the-editor). The UI-SPEC won —
     it is the later, checker-approved document, and the FAB slot plus accent colour are reserved for
     "Cập nhật số km". Recorded in that plan's `## Reconciliation with 03-UI-SPEC.md`.
     `toggleNotePinned` is still built and still called, now from the editor's pin button.

  2. `03-06` kept the plan's stricter `kmLeft` guard ("non-null **and negative**") over the UI-SPEC's
     `!= null`. A positive `kmLeft` on an item overdue on the time axis would render
     "Quá hạn 7 ngày · 400 km", which reads as *400 km remaining* — the exact opposite of the truth.
     Recorded in that plan's `## Flagged planner decisions`, item 3.

  3. `03-06`'s fourth (plain-line) branch keeps the oil / non-oil split, since the UI-SPEC's table
     quotes only P3-D-01's oil-specific line and does not contradict §11.1's generic form. Recorded
     in the same block, item 1.

- **A wave-ordering constraint was resolved by a deliberate two-step migration.** H5 `populated`
  requires the item-detail screen and the due card never to disagree on wording, but `due_card.dart`
  does not exist at Wave 4. So `03-05` builds the status-line resolver as a private helper inside
  `item_detail_screen.dart`, and `03-06` task 1 promotes it into `due_card.dart` and repoints the
  single call site. `lib/ui/item/item_detail_screen.dart` is therefore listed in `03-06`'s
  `files_modified` as well; Wave 5 contains only 03-06, so there is no concurrent writer.

- **`03-05` is now the heaviest plan in the phase** — 3 tasks, 21 lifted truths, ~84k token estimate.
  It was deliberately not split: splitting would renumber plans, which was out of scope for a
  revision run. Worth weighing before Wave 4 runs.

- **Two non-blocking checker warnings, both accepted:** `03-02` carries 11 `files_modified`, one over
  the 10-file threshold (seven are one-line import edits, each with its own acceptance criterion, and
  the plan justifies this in its own objective); and the `03-UI-SPEC.md` header discrepancy above.

- **Decision-coverage gate override (Phase 3, second occurrence — the replan).**
  `check.decision-coverage-plan` again returned `passed: false, reason: "could-not-parse", total: 0`
  against `03-CONTEXT.md`'s `P3-D-NN` namespace — the fourth recurrence of the pattern recorded below
  for Phases 1, 2 and 3. Coverage was re-verified by grep and is **18/18**, with a wider spread than
  before the revision: P3-D-01 (03-01, 03-02, 03-05, 03-06), P3-D-02 (03-06), P3-D-03 (03-06),
  P3-D-04 (03-01, 03-03), P3-D-05 (03-04, 03-05), P3-D-06/07/08 (03-04), P3-D-09/10 (03-03),
  P3-D-11 (03-02), P3-D-12 (03-01, 03-03), P3-D-13 (03-01), P3-D-14/15 (03-05),
  P3-D-16 (03-01, 03-05, 03-06), P3-D-17 (03-04), P3-D-18 (03-02). Proceeded on the override already
  recorded for this phase rather than re-litigating it. Verify-phase should re-surface it.

- Phase 02 closed by `/gsd-verify-work 02` on the real SM-A066B over wireless debugging: all five
  outstanding human-verification items ran and passed on a `--release` build, `02-SECURITY.md` was
  produced by `/gsd-secure-phase 02` (22 threats, 0 open, 2 documented accepted risks), and
  `02-VERIFICATION.md` was canonicalised to `passed`.

- **Phase 02's most-doubted item was fine.** `02-VERIFICATION.md` flagged the step-3
  "Tôi biết con số chính xác" affordance as UNCONFIRMED after four synthetic `adb` taps failed to
  open it. It opened on the first tap this session. Root cause found: the soft keyboard shifts the
  button row from y≈1496 to y≈955, so the earlier coordinates landed on the keyboard. An adb
  scripting limitation, exactly as the report guessed — no defect.

- Three things confirmed beyond the five UAT items: the manual-type 19/12/7 triple; the mineral-oil
  string rendering as "Với nhớt khoáng, …" without the duplicated word (commit `579b9af` holds on
  device); and the icon font tree-shaking from 1.645.184 to 3.944 bytes on a real release build,
  so `lib/ui/catalog_icons.dart`'s invariant survives and no `--no-tree-shake-icons` flag is needed.

- Phase 01 closed by `/gsd-verify-work 01`: UAT test 6 (the `build_runner` interrupt backstop) was
  run and passed, `01-SECURITY.md` was produced by `/gsd-secure-phase 01` (19 threats, 0 open,
  4 documented accepted risks), and `01-VERIFICATION.md` was canonicalised to `passed`.

- `.planning/config.json` now sets `build_command: flutter analyze` and `test_command: dart test`,
  which fixes the anti-pattern where the post-merge gate detected no command on this Flutter
  project and silently skipped integration checking.

- **Watch for this in Phase 03:** `check.decision-coverage-plan` will fail to parse `P3-D-NN`
  ids the same way it failed on `P1-D-NN` and `P2-D-NN` (see the entries above). Expect
  `could-not-parse` and verify coverage by grep instead of renaming the ids.
