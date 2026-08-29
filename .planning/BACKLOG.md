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
