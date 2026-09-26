# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository status

There is **no application code yet**. `flutter create` has not been run. The repo holds:

- `motonote-v3-flutter.md` — the sole source of authority (Vietnamese, v3.0, 2178 lines). Everything else derives from it.
- `.planning/` — the GSD planning tree (PROJECT.md, ROADMAP.md, REQUIREMENTS.md, STATE.md, `intel/`, `INGEST-CONFLICTS.md`).
- `.claude/` — GSD Core v1.11.0 install (agents, commands, hooks).

Read `.planning/STATE.md` and `.planning/.continue-here.md` first — they carry current position, blockers, and the resume instruction.

## Workflow (GSD Core)

This project is spec-driven through GSD. Do not start writing code ad hoc; work goes through the phase pipeline:

```
/gsd-discuss-phase N   →  /gsd-plan-phase N  →  /gsd-execute-phase N  →  /gsd-verify-work
```

- `/gsd-progress` — where things stand and what to do next.
- `/gsd-resume-work` — restore context from `.planning/HANDOFF.json`.
- `.planning/` is state, not documentation: phase execution updates STATE.md and ROADMAP.md.
- Every new idea raised mid-build goes to `BACKLOG.md` at the repository root, never into the version being built (D-34, §13.2). This project is on its third plan revision *because* of scope creep — the anti-scope-creep machinery is deliberate.

The roadmap is 6 phases: toolchain+data layer → onboarding/catalog/engines → home+logging+notes → local notifications → Drive backup/restore → polish+Play Store.

## Toolchain commands

Flutter 3.47.2 / Dart 3.13.2 stable at `C:/Users/nguye/AppData/Local/flutter`, on machine PATH. Android SDK 36.1.0, licences accepted.

```bash
flutter analyze                                          # required before every commit
dart format .
dart run build_runner build --delete-conflicting-outputs # after editing any freezed/json model
dart run build_runner watch                              # during development
dart test                                                 # whole tree (test_command in config.json) —
                                                         # 148 tests green as of 06-04
dart test test/domain/                                   # business logic — pure Dart, no Flutter
dart test test/data/                                     # file-I/O tests, run against a temp directory
dart test test/domain/due_test.dart                      # single test file
dart test test/domain/due_test.dart -n 'computeDue'       # single group/test by name
flutter run --release                                    # MANDATORY — debug is JIT; OAuth and
                                                         # notification bugs only show in release
```

`flutter pub outdated` and the `google_sign_in` / `freezed` CHANGELOGs must be read before writing code — the §3.1 version pins are reference points, not commitments, and both packages had recent major breaking changes. Ignore any article written before 2025 (§15 R7).

**No Android device is connected** (`flutter doctor` sees only Windows/Chrome/Edge). An emulator is fine for development, but Phase 1 sign-off and all §10.6 OEM battery-optimisation behaviour require a real low-end Android device (3–4 GB RAM).

## Architecture

Vietnamese-language Android app for motorcycle maintenance reminders. No account, no server, no push. Flutter + Riverpod + go_router + Freezed.

**Two facts dominate every decision:**

1. **All app state is ONE JSON document** — `appdata.json` (<200 KB) in the app documents directory. The source calls this the most important architectural decision in the project. It is why backup is a single whole-file upload with no sync protocol, no merge, and no conflict resolution. Do not introduce a database (Hive/Isar/SQLite are explicitly rejected — D-12).
2. **`lib/domain/` is pure Dart and must never import `package:flutter/...`** (D-31). That is what lets all business logic run under plain `dart test`.

```
lib/
├── main.dart              # init, hydrate, router
├── domain/                # PURE DART — models (freezed), catalog.dart, oil_presets.dart,
│                          # due.dart (computeDue), odo.dart (refineAvgDailyKm)
├── data/                  # app_data_repository.dart (atomic write), migrations.dart
├── state/                 # app_state.dart (one NotifierProvider), derived.dart
├── backup/                # google_auth, drive_service, backup_service, local_export
├── notifications/         # notification_service, battery_hints
├── ui/                    # router.dart + onboarding/ home/ log/ item/ notes/ settings/ widgets/
└── theme/
test/domain/               # pure-Dart business-logic tests, runnable under plain `dart test`
test/data/                 # file-I/O tests (app_data_repository, atomic writes) using a temp dir
```

No `services/`, `utils/` or `helpers/` directories of tiny files. Seven screens, no more (D-33) — ODO update is a modal sheet, not a screen.

A test file is added under `test/domain/` or `test/data/` whenever new pure-Dart-reachable logic is
added — the file count itself is not the invariant worth tracking, since it grows every phase. What
must hold: **no file under `test/` may import `package:flutter/...`**, because `dart test` runs the
whole tree and one Flutter import breaks every other test in it (mirrors D-31 for `lib/domain/`).

### Invariants that must not be violated

- **Atomic writes** (§5.1): write `appdata.json.tmp` → copy current file to `appdata.backup.json` → `rename` tmp over target. Load falls back to the backup copy when the primary is corrupt.
- **Migrations are additive only** (D-21): only add fields, never rename, never delete. `migrateRaw` must run on both local and Drive-restored data. Note the source's own inconsistency: §4.1 declares `kSchemaVersion = 1` while §4.4's example branches on `from < 2` — see `.planning/INGEST-CONFLICTS.md`.
- **Drive scope is `drive.appdata` only** (D-22) — `drive` / `drive.readonly` trigger sensitive-scope review. Backup file is `motonote-backup.json` in `appDataFolder`.
- **Automatic backup uses `silentToken()` only** (D-23) — never pop a sign-in dialog mid-flow, never show a toast or spinner; a null token records the error as one line in Settings.
- **Restore is full overwrite, never merge** (D-24), behind three protections: onboarding-only when the device has no data, side-by-side comparison when it does, and a 7-day "Hoàn tác khôi phục" snapshot.
- **Receipt photos are never backed up** — paths only in the document; the consequence must be stated on the restore screen itself (D-20).
- **The app is fully functional without ever signing into Google** (D-18); those users get the "Xuất file" export button.
- **No screen waits on the network** (D-19) — everything renders from memory.
- **Notifications**: `rescheduleAll()` = `cancelAll()` then schedule individual dated notifications; never repeating schedules (D-29). Never block a feature on the exact-alarm permission — fall back to inexact scheduling (D-30).
- **Due dates run on two axes** — `intervalKm` and `intervalMonths`, whichever comes first. The time axis cannot be dropped: oil degrades on an unridden bike, and low-mileage riders are the majority of the target market (D-28).

Full decision list with rationale: `.planning/PROJECT.md` (`<decisions>` block, D-01…D-36) and `.planning/intel/decisions.md`.

## Conventions

- **UI copy, catalog names and notification text are Vietnamese** and are quoted verbatim in the source doc and in `.planning/intel/constraints.md`. Use those strings exactly; do not translate or paraphrase them. Currency is VND, formatted with `intl`.
- Commit messages in this repo are English with a conventional prefix (`docs:`, `chore:`, `wip:`).
- Estimated odometer values are always shown prefixed with `~`; the app states when it is guessing rather than inventing precision (§9.5).

## Known traps

- `DateTime.difference().inDays` truncates instead of rounding — the source flags this twice as the source of hard-to-find off-by-one-day bugs (§9.3, §14.2).
- `BuildContext` used after an `await` — check `context.mounted`.
- Forgetting `build_runner` after editing a freezed model produces confusing compile errors.
- `Column` inside `Column`, or `ListView` inside `Column`, without `Expanded`.
- **Do not author files through Bash heredocs in this project.** A previous session had backslashes silently eaten, corrupting a Windows path written into `.planning/STATE.md`; quoting the heredoc delimiter did not prevent it. Use the Write tool.
- Write Windows paths with forward slashes (`C:/Users/...`) — Node, Flutter and git all accept them.

## Open questions blocking Phase 2

Both are deferred deliberately — do not resolve them unilaterally; surface them in `/gsd-discuss-phase 2`:

1. **Onboarding default-item count.** §8.2/§6 say 8 pre-checked of 15 (principle: "6–8"); Appendix A's `defaultOn` flags filtered by `appliesTo` yield 11 of 20 for scooter. `battery` is listed as advanced in §8.2 but carries `defaultOn: true` in Appendix A. Both variants preserved verbatim in `.planning/intel/constraints.md`.
2. **The ODO estimation error threshold.** The v1.0 success metric measures against it, but the source never defines one. It must be decided in Phase 2 so Phase 6's one-month soak has a target.
