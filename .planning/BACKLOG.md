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
