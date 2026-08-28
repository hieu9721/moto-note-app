# Context

Narrative and planning content from the ingest set that is neither a decision statement nor a technical
constraint. No DOC-classified sources were present; the entries below come from the SPEC-classified
source's plan, risk and onboarding sections, retained here so they are not lost.

---

## Topic: product framing
- source: D:/Projects/moto-note/motonote-v3-flutter.md (header, lines 1–4)
- notes:
  "MotoNote — Kiến trúc & kế hoạch (Flutter)".
  Tagline: "App ghi chú + nhắc bảo trì xe máy · Không tài khoản · Lưu máy · Backup Google Drive"
  (a note-taking + motorcycle maintenance reminder app; no account; stored on device; Google Drive backup).
  Version 3.0, dated 2026-08-28. Replaces v2.0 (React Native).
  Target market signals appear throughout: Vietnamese-language UI copy, VND currency formatting, low-end
  Android devices, Hà Nội and TP.HCM low-mileage riders, Xiaomi/Oppo/Vivo/Samsung ROM behaviour.

## Topic: implementation plan — overall estimate
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Estimated for one person working part-time (~15–20 h/week) who has never written Dart.
  Total ~7 part-time weeks, of which roughly 2 weeks is the cost of learning Flutter.
  If already familiar with Dart, it shrinks to ~5 weeks.

## Topic: implementation plan — Week 0, getting familiar (3–5 days)
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Explicitly not skippable: going straight into the real project before knowing the language is the
  surest way to write an architecture that has to be thrown away in week three.
  Tasks: read the Dart language tour focusing on null safety, async/await, const constructors, sealed
  classes and pattern matching; finish Google's "Your first Flutter app" codelab; build a throwaway
  two-screen app using Riverpod and go_router; run freezed + build_runner once to learn the codegen
  workflow; install Flutter DevTools and learn the Widget Inspector.
  Milestone: understand why a StatelessWidget rebuilds, and when `const` is needed.

## Topic: implementation plan — Week 1, foundations and data
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Tasks: `flutter create`, lint config, directory structure per §12; all models with freezed +
  json_serializable; AppDataRepository with atomic write + fallback; Riverpod store with `_mutate`;
  due.dart + odo.dart with tests for both; onboarding welcome plus the 6-step setup.
  Milestone: a vehicle can be created and the data survives a force-stop.

## Topic: implementation plan — Weeks 2–3, core features
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Tasks: home screen with vehicle card, DueCard, sorted by urgency; ODO update modal sheet with the
  self-drawn numeric keypad; service-log modal sheet supporting multi-item selection; item detail screen
  with history; part-spec memory and prefill; notes CRUD with pinning.
  Milestone: usable for real on the developer's own bike.
  Warning recorded: this is the longest phase because Flutter layout has to be learned while building.
  Row/Column/Expanded/Flexible take a few days to become instinctive.

## Topic: implementation plan — Week 4, notifications
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Tasks: NotificationService init, timezone, channel; request permissions at the right moment (two
  separate permissions on Android); `rescheduleAll` cancel-all-and-reset; monthly ODO reminder; per-vehicle
  grouping; deep links including the app-closed case; per-manufacturer battery_hints.
  Milestone: change the device clock and receive the right notification at the right time. Test on at
  least one real Xiaomi or Samsung device.

## Topic: implementation plan — Week 5, Google Drive
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Tasks: create the Google Cloud project and enable the Drive API; OAuth clients for Android and iOS;
  google_sign_in v7 flow initialize -> authenticate -> authorizeScopes; DriveService peek/upload/download;
  automatic backup (silentToken only) plus a manual button; restore screen with comparison and undo;
  local file export.
  Milestone: reinstall the app on a different device and restore all data.
  Warning recorded: the OAuth part always takes longer than expected. The Android SHA-1 fingerprint must
  match across debug key, release key and Play App Signing key — three different keys, and a missing one
  makes sign-in FAIL SILENTLY with no clear error message.

## Topic: implementation plan — Weeks 6–7, polish and release
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13
- notes:
  Tasks: Settings for managing vehicles, items and intervals; empty states, error handling, loading
  states; theme, icon, splash; store screenshots; privacy policy (mandatory because OAuth is used);
  Play Data Safety / Apple App Privacy; basic OAuth verification with Google; submit to internal testing
  / TestFlight.
  Milestone: 5 real users within 2 weeks.

## Topic: descoping order if an earlier release is needed
- source: D:/Projects/moto-note/motonote-v3-flutter.md §13.1
- notes:
  Cut in this order, from the top down:
    4. Google Drive backup — substitute a local file-export button for now
    3. Notes — even though it is in the app's name
    2. Advanced notifications — keep only the monthly ODO reminder
    1. Engine + service logging — DO NOT CUT
  Week 0 + 1 + 2–3 already yields a genuinely usable app, roughly 4 weeks.

## Topic: risk register
- source: D:/Projects/moto-note/motonote-v3-flutter.md §15
- notes:
  R1 — User does not update ODO, so every prediction drifts.
    Mitigation: monthly reminder; the ODO button is the most prominent thing on the home screen; prefill
    the estimated value; build the fuel log in v1.1 (§13.3).
  R2 — Data lost because the phone breaks or is lost before any backup.
    Mitigation: prompt to enable Drive backup at the end of onboarding; enable Android `allowBackup` as a
    safety net; show "last backup" directly in Settings.
  R3 — JSON file corrupted mid-write.
    Mitigation: atomic write via temp file + rename; keep the immediately-previous copy (§5.1).
  R4 — Restore overwrites newer data by mistake.
    Mitigation: explicit comparison before overwrite; save the pre-restore state and allow undo for 7 days (§7.6).
  R5 — Notifications killed by an Android OEM ROM.
    Mitigation: reschedule on every app open; `exactAllowWhileIdle`; per-manufacturer guidance;
    self-detection of "no notification for a long time" (§10.6).
  R6 — OAuth misconfiguration causing silent sign-in failure.
    Mitigation: test on a real release build, not just debug; verify all three SHA-1 fingerprints.
  R7 — `google_sign_in` v7's API differs completely from older online documentation.
    Mitigation: read only the package's official README; ignore any article written before 2025 (§7.3).
  R8 — The Dart/Flutter learning curve is longer than expected.
    Mitigation: dedicate week 0 to learning; keep `domain/` pure Dart so the hardest logic is not entangled
    with Flutter.
  R9 — Default intervals are wrong for a specific bike model.
    Mitigation: allow every interval to be edited; state plainly that these are general recommendations and
    the manufacturer's manual is more accurate; use oil-grade presets to get closer.
  R10 — Scope creep returning.
    Mitigation: BACKLOG.md; do not insert new ideas into the version being built (§13.2).

## Topic: React-to-Flutter mental model differences
- source: D:/Projects/moto-note/motonote-v3-flutter.md §14.1
- notes:
  Component + JSX -> Widget + constructor tree; everything is a widget, including padding and alignment.
  `useState` -> StatefulWidget / Riverpod; for this app it is almost always Riverpod, with StatefulWidget
    reserved for animation and controllers.
  CSS / Tailwind -> widget properties; there is no stylesheet, style lives in the constructor.
  Flexbox -> Row / Column / Expanded; similar, but `Expanded` is required in many situations where
    flexbox does not need it.
  `undefined` / `null` -> only `null`, with null safety; `String?` differs from `String` and the compiler
    catches it immediately, which is a strength.
  `map()` returning JSX -> `map().toList()`; easy to forget `.toList()` — `map` returns a lazy Iterable
    that widgets will not accept.
  Optional chaining `?.` -> identical, plus `??`, `??=` and `!` (non-null assertion).

## Topic: seven mistakes expected in the first week
- source: D:/Projects/moto-note/motonote-v3-flutter.md §14.2
- notes:
  1. Forgetting `const` — unchanging widgets rebuild pointlessly. Enable the `prefer_const_constructors` lint.
  2. `setState` inside `build()` — causes an infinite loop. Rare with Riverpod, but this is the cause when it happens.
  3. Using `BuildContext` after an `await` — the widget may have been removed from the tree. Always guard
     with `if (!context.mounted) return;`. Described as the most common mistake; the lint warns, do not ignore it.
  4. `Column` inside `Column` without `Expanded` — layout overflow with the yellow/black stripes. Read the
     constraints concept once properly; it saves hours.
  5. `ListView` inside `Column` — needs an `Expanded` wrapper or `shrinkWrap: true`.
  6. Forgetting to run `build_runner` after editing a freezed model — produces confusing compile errors.
     Use `dart run build_runner watch` while developing.
  7. `DateTime.difference().inDays` truncates — repeated from §9.3 because it produces a very hard-to-find
     off-by-one-day bug.
