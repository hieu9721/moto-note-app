---
gsd_state_version: 1.0
milestone: v1.0
current_phase: 4
current_phase_name: Local Notifications
status: planning
stopped_at: Phase 03 complete, ready to plan Phase 4
last_updated: "2026-08-30T13:31:33.877Z"
last_activity: 2026-08-30
last_activity_desc: Phase 03 complete, transitioned to Phase 4
state_head: fa77ce2fc40ef2b7247156c6a70c40a630be1951
progress:
  total_phases: 6
  completed_phases: 3
  total_plans: 18
  completed_plans: 18
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-30)

**Core value:** The user gets reminded on the right day that their bike needs something — accurately enough that they never turn the notifications off.
**Current focus:** Phase 03 — Home, Logging & Notes

## Current Position

Phase: 4 — Local Notifications
Plan: Not started
Status: Ready to plan
Last activity: 2026-08-30 — Phase 03 complete, transitioned to Phase 4

Progress: [████████████████████] 18/18 plans (Phases 01–03 of 6 complete)

**Next command:** `/gsd-discuss-phase 4` — Phase 4 (Local Notifications) is unplanned. Note that
§10.6's OEM battery-optimisation behaviour is only observable on the real SM-A066B, which must be
re-attached; and that D-30 forbids blocking any feature on the exact-alarm permission.

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

- Total plans completed: 18
- Average duration: —
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 6 | - | - |
| 02 | 5 | - | - |
| 03 | 7 | - | - |

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

- **D-33 was amended during Phase 3 planning (2026-08-30) — a locked project decision changed.** `gsd-plan-checker` blocked the first plan revision because `03-01`'s `DataIssueScreen` on a top-level `/data-issue` route is an eighth screen, and the planner had justified it by an invalid analogy to Phase 1/2's `_PostOnboardingPlaceholder` (those were temporary and scheduled for deletion; this is permanent product surface). The question was put to the user, who chose to amend D-33 to **7 + 1** rather than fold the state into an existing screen. `.planning/PROJECT.md` D-33 now names the read-only data-issue screen as a single explicit exception outside the seven-screen *feature* cap, and the Anti-Goals bullet points at it. `03-RESEARCH.md`'s original reasoning and its assumption **A3** were annotated as superseded. **The exception is not a precedent** — a new feature screen still needs a new decision. Phase 5 (restore, P1-D-09) may give this screen its first action.

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| Platform | iOS release (Appendix B iOS section) | Deferred past 1.0 | 2026-08-28 (project setup) | v1.0 |
| Feature | Fuel log — "Nhật ký đổ xăng" (D-36, §13.3) | Planned as first post-1.0 work | 2026-08-28 (project setup) | v1.0 |
| Catalog | `emission_check` entry, pending the emissions-inspection regulation | Awaiting external rules | 2026-08-28 (project setup) | v1.0 |

## Session Continuity

Last session: 2026-08-30T13:31:33.877Z
Stopped at: Phase 03 CLOSED — UAT 7/7 passed on device, SECURITY.md produced, transitioned to Phase 4
Resume file: none — Phase 4 is unplanned

Phase 03 is complete. Next action is `/gsd-discuss-phase 4`.

Session notes:

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
