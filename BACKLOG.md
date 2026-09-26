# Backlog

Ideas and defects raised mid-build that are deliberately NOT in the version being built
(D-34, §13.2). This project is on its third plan revision because of scope creep — an item
landing here is the machinery working, not a failure to act.

Each entry records what was found, why it was deferred, and what would have to be true to
promote it. Promote with `/gsd-review-backlog`.

---

## From Phase 02 — Onboarding, Catalog & Estimation Engines

### BL-01 — `lib/state/` depends on `lib/ui/onboarding/`

**Raised:** 2026-08-29, by the Phase 02 code review (finding WR-03).
**Severity:** Warning — layering, not behaviour. Nothing is wrong at runtime.

`lib/state/app_state.dart` imports a type from `lib/ui/onboarding/` so that
`completeOnboarding` can take the onboarding draft directly. That inverts the intended
dependency direction: the state layer should not know that an onboarding UI exists, and
today it cannot be reused or tested without dragging a UI file along.

**Why deferred:** it is a refactor with no user-visible symptom, and it surfaced at the
close of the phase alongside two real defects (a crash path and a wrong-due-date bug) that
took priority. Moving the draft type would touch `app_state.dart`, all six step widgets and
`onboarding_flow.dart` — a wide change to make while the phase was being signed off.

**What promoting it looks like:** move the draft (or a plain data structure it maps to) out
of `lib/ui/onboarding/` into `lib/domain/` or `lib/state/`, so the dependency points
inward. Note `lib/domain/` is pure Dart (D-31), so whatever moves must not carry any Flutter
import with it.

**Natural moment to do it:** Phase 3, when `lib/state/` grows the ODO-update and service-log
entry points and the same question will come up again for those flows.

---

## From Phase 02 — deferred verification

### BL-02 — On-device checks not yet run from the 02-05 checklist

**Raised:** 2026-08-29, during the Phase 02 on-device verification pass.

The full six-step flow, the P2-D-01 counts, the AND gate at step 3, the byte-exact step-5
copy, force-stop survival and the 11-item document were all verified on the real SM-A066B.
These items from plan 02-05's own 13-step checklist were not:

- The "Tôi biết con số chính xác" exact-entry escape would not open under four synthetic
  `adb input` taps, with the keyboard up. The widget is a plain `TextButton` calling a
  correct `_toggleExact`, and synthetic taps worked everywhere else in the app, so this is
  more likely an `adb` limitation than a defect — but it is UNCONFIRMED either way, and the
  out-of-range rejection cases (2000 / 0.2 / 25 km per day, P2-D-08) are behind it and so
  are also unverified on device.
- Back-navigation preserving already-entered values across a revisit.
- The second run using "Không nhớ" at step 6, confirming the item reads as `ok` on day zero.
- Switching vehicle type at step 1 and confirming step 4 re-seeds to 19/12/7 for Côn tay.
- A Vietnamese name and plate ("Xe của Đạt" / "59-X1 123.45") round-tripping byte-identically
  through a force-stop.

**What promoting it looks like:** run them during `/gsd-verify-work 02`, which is where UAT
belongs. One human finger settles the first item in about five seconds.

---

## From Phase 03 — Home, Logging & Notes

### BL-03 — Receipt photos in the service-log sheet

**Raised:** 2026-08-29, during `/gsd-discuss-phase 3` (recorded as P3-D-17 in `03-CONTEXT.md`).

The storage half already exists: DATA-08 shipped in Phase 1, `lib/data/receipt_storage.dart`
writes into the app directory, and `ServiceLog.photoPaths` is a live field on the model. The
service-log sheet built in Phase 3 is the only place a receipt photo would ever be attached.

**Why deferred:** no requirement in `.planning/REQUIREMENTS.md` covers photo capture. Adding it
pulls in a camera/gallery permission prompt, a picker, a full-screen viewer and a delete path —
four pieces of UI, none of them requirement-backed, into a phase that already carries fourteen
requirements. This is exactly the shape D-34 and §13.2 exist to stop.

**What promoting it looks like:** give it a requirement id (PHOTO-01 or similar), decide where the
permission prompt sits and what happens when it is denied, and decide whether a deleted log removes
its photo files. D-20 stands regardless of when it lands: photo paths are stored in the document,
the image files themselves are never backed up to Drive, and the restore screen must say so.

**Natural moment to do it:** Phase 6, alongside the other polish work — or post-1.0, next to the
fuel log (D-36).

---

### BL-04 — `home_screen.dart` / `due_card.dart` / `odo_sheet.dart` circular import triangle (WR-01)

**Raised:** 2026-08-30, by `/gsd-code-review 03` and confirmed by `/gsd-verify-work 03`; routed here
rather than into the 03-07 gap-closure plan.

Both `due_card.dart` and `odo_sheet.dart` import `home_screen.dart show daysSinceOdoUpdate`, and
`home_screen.dart` imports both of them back.

**Why deferred:** it compiles and works correctly under Dart and `03-VERIFICATION.md` classifies it
as a maintainability cost, not a functional defect; the gap-closure plan touches `odo_sheet.dart`
only to repoint one dialog call and does not touch `home_screen.dart` or `due_card.dart` at all, so
breaking the cycle would mean opening two files the failed truth has nothing to do with.

**What promoting it looks like:** move `daysSinceOdoUpdate` and `vehicleHeaderLine` out of
`home_screen.dart` into a small standalone file both dependents can import without pointing back at
the screen widget — `lib/ui/widgets/odometer_confirm_dialog.dart`, created by 03-07, is the precedent
for where such a file goes.

**Natural moment to do it:** Phase 6 polish, or the next time a fourth file needs
`daysSinceOdoUpdate`.

---

### BL-05 — `_toggleExact` retains a stale `avgDailyKm` after the exact field is hidden again (WR-02)

**Raised:** 2026-08-30, by `/gsd-code-review 03` and confirmed by `/gsd-verify-work 03`; routed here
rather than into the 03-07 gap-closure plan.

Reveal the exact-entry field in `step3_odo_avgkm.dart`, type a valid value, tap the toggle again to
hide it without picking a band: `_showExact` flips back but `draft.avgDailyKm` keeps the typed value,
no radio appears selected, "Tiếp tục" stays enabled, and `completeOnboarding` commits an invisible
number the screen is no longer showing. This is a real defect that silently seeds the estimation
engine.

**Why deferred:** `03-VERIFICATION.md` classifies it as out of Phase 3 scope — it is Phase 2 logic in
`step3_odo_avgkm.dart`, which Phase 3 touched only for a one-line BL-01 import-path edit, and it is
not counted against Phase 3's score.

**What promoting it looks like:** clear `draft.avgDailyKm` on both transitions and clear the exact
controller when hiding, per WR-02's own fix.

**Natural moment to do it:** alongside BL-02's outstanding on-device onboarding checks, which is
where it would be observed.

---

### BL-06 — two hardcoded grey caption colour literals in the onboarding steps (WR-05)

**Raised:** 2026-08-30, by `/gsd-code-review 03` and confirmed by `/gsd-verify-work 03`; routed here
rather than into the 03-07 gap-closure plan.

The two call sites WR-05 names in `step4_items.dart` and `step5_oil_grade.dart` set caption colour
with a literal instead of resolving `Theme.of(context).colorScheme.onSurfaceVariant` the way every
other caption in the app does, so those two captions will not track contrast under a dark scheme.

**Why deferred:** Phase 2 code, out of Phase 3 scope per `03-VERIFICATION.md`, and the palette itself
is REL-02 in Phase 6 — fixing two literals now, against the placeholder teal-seeded
`ColorScheme.fromSeed(...)` in `lib/theme/app_theme.dart` that is itself scheduled for replacement,
is work done twice. Note explicitly that `settings_screen.dart`'s own grey caption is a deliberate,
plan-approved copy of `welcome_screen.dart`'s shipped idiom and is NOT part of this item.

**What promoting it looks like:** replace both literals with
`Theme.of(context).colorScheme.onSurfaceVariant`, in the same pass as REL-02.

**Natural moment to do it:** Phase 6, in the same pass as REL-02.

---

### BL-07 — `_iconForCatalogCode` duplicated verbatim across three files (IN-01)

**Raised:** 2026-08-30, by `/gsd-code-review 03` and confirmed by `/gsd-verify-work 03`; routed here
rather than into the 03-07 gap-closure plan.

Present in `due_card.dart`, `home_screen.dart` and `item_detail_screen.dart`; a change to the
fallback behaviour needs three edits in lockstep.

**Why deferred:** INFO severity, each file's own header comment records the duplication as
deliberate (each copy is private to its file), it is entangled with BL-04's import cycle, and none
of the three files is edited by the gap-closure plan.

**What promoting it looks like:** promote to a public `iconForCatalogCode` in
`lib/ui/catalog_icons.dart`, which already owns `catalogIconFor` and the icon tree-shaking
invariant.

**Natural moment to do it:** together with BL-04, since the cycle is what pushed the duplication in
the first place.

---

### BL-08 — find-by-id linear-search helpers duplicated across three files (IN-02)

**Raised:** 2026-08-30, by `/gsd-code-review 03` and confirmed by `/gsd-verify-work 03`; routed here
rather than into the 03-07 gap-closure plan.

`_findItem`, `_findVehicle`, `_findNote` and `_findDueItem` repeat the same nullable-loop shape in
`item_detail_screen.dart`, `note_editor_screen.dart` and `service_log_sheet.dart`.

**Why deferred:** INFO severity and consistent with this codebase's established non-throwing-lookup
convention — a deliberate choice, not an accident. Introducing a shared generic helper or adding
`package:collection` for `firstWhereOrNull` means a new dependency decision and three files edited,
in a run whose whole point is to not grow. Note that 03-07 deliberately reuses
`service_log_sheet.dart`'s existing `_findItem` rather than introducing a new lookup pattern
mid-fix.

**What promoting it looks like:** decide between a shared generic helper and `package:collection`,
then convert all sites in one pass.

**Natural moment to do it:** Phase 6 polish, or whenever `package:collection` is added for another
reason.

---

### BL-09 — `odo_sheet.dart` has no upper-bound odometer validation, only a 7-digit keypad cap (CR-01)

**Raised:** 2026-08-30, by the post-gap-closure `/gsd-code-review 03` re-run — i.e. AFTER 03-07 had
already shipped. Routed here rather than reopening the 03-07 plan.

`lib/ui/home/odo_sheet.dart:69` caps the digit *count* at 7 (`_maxDigits = 7`), which admits
`1.000.001` through `9.999.999`. The other two odometer entry points both enforce the real bound:
`step3_odo_avgkm.dart:49` and `service_log_sheet.dart:79` each declare `_maxOdo = 1000000` and reject
above it with `Số km không hợp lệ (0 – 1.000.000).`. 03-07's own comment treats the 7-digit keypad cap
as equivalent to that ceiling — it is not. This is the mirror image of WR-03: 03-07 made the two write
paths agree on the *confirmation dialog* but left them disagreeing on the *upper bound*, on the home
FAB, which is the most-used ODO entry point.

**Why deferred:** it arrived from a review run that post-dates the gap-closure plan, so it is not one
of `03-VERIFICATION.md`'s must-have truths and was never in 03-07's scope. D-34 (source §13.2) routes
mid-build findings here rather than growing the version being built — the same rule that put BL-04…BL-08
here. It is also not a silent-corruption-with-no-warning case in the way CR-01/WR-03 were: the ODO
sheet's own lower-than-previous confirmation still fires on the *next* reading after a bad entry.

**What promoting it looks like:** add `static const int _maxOdo = 1000000;` to `_OdoSheetState`,
reject `value > _maxOdo` in the save path with the byte-exact onboarding message, and delete the
"caps at seven digits at the keypad" comment in `service_log_sheet.dart` that treats the two as
equivalent. Small — one file, one branch, one shared string already in the tree.

**Natural moment to do it:** the next gap-closure pass for Phase 3, or Phase 6 polish. Promote it
sooner if the on-device UAT for test 2 (ODO sheet keypad) surfaces it in practice.

---

### BL-10 — `service_log_sheet.dart` keeps a stale inline error on screen while the user corrects the field

**Raised:** 2026-08-30, during `/gsd-verify-work 03`'s on-device UAT (test 3, guard `(c)`). Routed
here rather than reopening Phase 3: every truth test 3 asserts held exactly, and this is a
presentation nit outside all of them.

`_ServiceLogFormState._error` is only cleared inside `_save()` (`service_log_sheet.dart:250`), so
after `Số km không hợp lệ (0 – 1.000.000).` is raised, the red line stays on screen while the user
edits `Số km` to a valid value, and is still visible *behind* the P3-D-12 confirmation dialog on the
next save attempt — the dialog and a contradicting error render together. `odo_sheet.dart` takes the
opposite approach: `_tapDigit` and `_backspace` both set `_error = null` (`:73`, `:81`), so its error
clears on the first correcting keystroke.

Observed on SM-A066B: entered `12345678` → error shown; corrected to `18000` → error still shown;
tapped Lưu → confirmation dialog opened with the stale error line visible underneath it.

**Why deferred:** D-34 (source §13.2) routes mid-build findings here rather than growing the version
being built. Nothing is mis-saved and no data is at risk — the guard itself works, and UAT test 3
passed on every stated criterion. The two sheets deliberately do NOT share scaffolding (research
Pitfall 3), so this is a genuine divergence to reconcile, not an accidental copy-paste drift.

**What promoting it looks like:** clear `_error` from the `Số km` field's `onChanged` (the field has
none today), or from a shared `_clearError()` called by the visit-level `TextField`s. One file, a few
lines. Consider doing it in the same pass as BL-09, which is the other odometer-validation
inconsistency between these same two sheets.

**Natural moment to do it:** Phase 6 polish, alongside BL-09.

---

## From Phase 05 — Google Drive Backup & Restore

### BL-11 — The undo's one-shot backup-pause is in-memory and does not survive a process death

**Raised:** 2026-09-01, by `05-05-PLAN.md`'s own "Flagged assumptions" item 2, filed here per the
plan's own `<output>` instruction rather than persisted into the document.

P5-D-09 chose an in-memory, consumable one-shot flag (`RealBackupService._suppressNextSchedule`) over
a `Settings` field for the reason RESEARCH Assumption A2 and Pitfall 11 both give: a `Settings` field
would cost a `build_runner` run and a D-21 commitment to spell its meaning forever, for a fact that
only has to survive until the very next mutation in the same process. The residual: if the user
undoes a restore, kills the app, and cold-starts more than 24 hours later without making any other
change, `main.dart`'s `>24h` automatic-backup rule uploads the just-undone document, and the Drive
copy the user restored from is then overwritten and gone.

**Why deferred:** the window is narrow (kill the app within the first 24 hours after an undo, and
never touch the app again in that window) and the outcome it produces — Drive matching the device —
is the normal steady state of this whole feature, not data loss. Persisting the flag was already
weighed and declined by P5-D-09 itself; recording it here is what P5-D-09's own "record, do not hide"
instruction requires, not a new finding.

**What promoting it looks like:** if this residual is ever judged worth closing, the fix is NOT to
persist the flag into `Settings` (that reopens the D-21/build_runner cost P5-D-09 declined). A
cheaper alternative worth evaluating first: have the `>24h` rule in `main.dart` also check
`preRestoreSnapshotModifiedAt()` and skip the automatic upload while a live pre-restore snapshot
still exists — the snapshot itself already carries the fact that an undo window is open, with no new
field.

**Natural moment to do it:** if `04-UAT.md`-style end-of-phase or later real-world use ever surfaces
this exact sequence (undo → kill within 24h → cold start past 24h → no other change) in practice,
promote it then rather than pre-emptively building for a sequence that may never occur.

---

### BL-12 — `home_screen.dart` now hangs three one-shot post-frame effects off the same `initState` hook

**Raised:** 2026-09-01, by `05-07-PLAN.md`'s own "Flagged assumptions" item 3, filed here per the
plan's own `<output>` instruction rather than consolidated in this plan.

`04-REVIEW.md`'s WR-01 already flagged that two independent one-shot effects on `HomeScreen`'s single
`addPostFrameCallback` — `_consumeSheetParam` (04-01) and `_maybeShowNotificationPermissionPrompt`
(04-03) — could in principle open two modals on the same frame; the gap-closure round that produced
`04-REVIEW.md` did not touch `home_screen.dart` and left it unresolved. 05-07 adds a third,
`_maybeShowDriveBackupPrompt` (BKP-15), following the identical pattern rather than inventing a new
one. Its own gate reads `_permissionPromptShown` to avoid stacking with the notification prompt on the
same frame, which keeps this plan's addition safe on its own terms, but does not address the
underlying accumulation WR-01 named.

**Flagged plan-authoring discrepancy (not a defect in this backlog item, recorded for the record):**
`05-07-PLAN.md`'s own text cites this finding as "`01-REVIEW.md`'s WR-01" — but `01-REVIEW.md`'s own
`WR-01` is an unrelated finding (`_tryDecodeBackup` swallowing `SchemaTooNewException`). The actual
source, confirmed by reading both files, is `04-REVIEW.md`'s `WR-01`
("Hai postFrameCallback trong `HomeScreen.initState` vẫn có thể mở đồng thời hai modal"). This entry
cites the verified source rather than the plan's misattributed one.

**Why deferred:** each effect works correctly in isolation and 05-07's own gate prevents the one new
stacking risk it introduces; consolidating three independent one-shot effects into a single ordered
sequence is a structural refactor with no user-visible defect today, and D-34/§13.2 route exactly this
shape of finding here rather than into the version being built.

**What promoting it looks like:** replace the three independent boolean-guarded effects with one
ordered sequence (or a small state machine) inside a single method called from `initState`'s
`addPostFrameCallback`, so the ordering and mutual-exclusion rules between them are enforced in one
place instead of replicated pairwise (as `_maybeShowDriveBackupPrompt`'s read of
`_permissionPromptShown` does today).

**Natural moment to do it:** Phase 6 polish, or the next time a fourth one-shot effect needs to be
added to this same hook.

---

## From Phase 06 — Polish & Play Store Release

### BL-13 — the "không nhớ" baseline rule is written twice: `buildSelectedItems` and `seedMaintenanceItem`

**Raised:** 2026-09-02, by `06-06-PLAN.md`'s own task 1 instruction ("Do not refactor
`buildSelectedItems` to call this function in this plan... Note the duplication in the SUMMARY and
file it to `BACKLOG.md`.").

`lib/state/onboarding_draft.dart`'s `buildSelectedItems` and the new `lib/domain/item_seed.dart`'s
`seedMaintenanceItem` both implement §6.1's "không nhớ" default (`lastServiceDate = now`,
`lastServiceOdo = vehicle.currentOdoKm`, `baselineIsGuess = true`, intervals from the catalog entry)
— one baseline rule, two independent Dart implementations, each of which could drift from the other
under a future edit.

**Why deferred:** `buildSelectedItems` also carries onboarding's CAT-03 oil-preset branch and its
§6.1 day-offset arithmetic, both UAT'd, shipped behaviour from Phase 2. Folding the two together in
06-06 would be a change to shipped onboarding for no requirement this phase asks for — 06-06 needed
only the plain, no-offset baseline for a catalog entry enabled after onboarding, not the full
onboarding commit path.

**What promoting it looks like:** extract the shared "không nhớ" baseline fields (the four listed
above) into `seedMaintenanceItem`, then have `buildSelectedItems` call it for its own default case
and layer CAT-03's oil-preset override and the §6.1 day-offset arithmetic on top for `engine_oil`
alone — the same "shared base, oil is the one override" shape `seedMaintenanceItem`'s own doc comment
already assumes.

**Natural moment to do it:** the next time either function is touched for an unrelated reason, or a
future onboarding/catalog refactor.
