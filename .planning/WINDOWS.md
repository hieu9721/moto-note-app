---
schema_version: 1
open_count: 3
waived_count: 0
fixed_count: 0
total_count: 3
last_updated: 2026-08-28T10:20:24.425Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | unrun-verify | android/app/build.gradle.kts |  | SETUP-06 on-device install/start (flutter run --release on a real 3-4GB-RAM Android device) not run — no hardware available; only the Gradle-configuration half (flutter build apk --debug) is proven by 01-02 | open |  | 2026-08-28T09:42:17.774Z |  |
| 2 | 01 | unrun-verify | lib/main.dart |  | Force-stop survival (kill app via Android Settings > Apps > MotoNote > Force stop, relaunch, appdata.json intact) not run — no real low-end Android device available (P1-D-13) | open |  | 2026-08-28T10:20:18.930Z |  |
| 3 | 01 | unrun-verify | lib/main.dart |  | Reboot survival (reboot device, relaunch MotoNote, same hydrate outcome) not run — no real low-end Android device available (P1-D-13) | open |  | 2026-08-28T10:20:24.425Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "android/app/build.gradle.kts",
    "line": null,
    "description": "SETUP-06 on-device install/start (flutter run --release on a real 3-4GB-RAM Android device) not run — no hardware available; only the Gradle-configuration half (flutter build apk --debug) is proven by 01-02",
    "status": "resolved",
    "reason": "PASSED on SM-A066B (3.43 GB RAM, Android 16/API 36): flutter run --release built, installed and started; hydrate outcome logged, no crash.",
    "recorded_at": "2026-08-28T09:42:17.774Z",
    "resolved_at": "2026-08-28T14:31:32.675Z"
  },
  {
    "id": 2,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "lib/main.dart",
    "line": null,
    "description": "Force-stop survival (kill app via Android Settings > Apps > MotoNote > Force stop, relaunch, appdata.json intact) not run — no real low-end Android device available (P1-D-13)",
    "status": "resolved",
    "reason": "PASSED: am force-stop left appdata.json byte-identical (sha256 89d3980c) with no .tmp residue; relaunch loaded with every data field identical, only updatedAt bumped per DATA-06.",
    "recorded_at": "2026-08-28T10:20:18.930Z",
    "resolved_at": "2026-08-28T14:31:32.675Z"
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "lib/main.dart",
    "line": null,
    "description": "Reboot survival (reboot device, relaunch MotoNote, same hydrate outcome) not run — no real low-end Android device available (P1-D-13)",
    "status": "resolved",
    "reason": "PASSED: adb reboot (uptime 10min confirms); appdata.json / appdata.backup.json / receipts probe all byte-identical across reboot; relaunch loaded, all fields intact incl. Vietnamese text.",
    "recorded_at": "2026-08-28T10:20:24.425Z",
    "resolved_at": "2026-08-28T14:31:32.675Z"
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "android/app/src/main/res/xml/data_extraction_rules.xml",
    "line": null,
    "description": "Receipt-photo backup exclusion (D-20) fix for 01-REVIEW.md CR-01 — domain changed file->root — not empirically verified. Needs on-device check: place a probe file at {dataDir}/app_flutter/receipts/probe.jpg, run `adb shell bmgr backupnow io.github.hieu9721.motonote`, unpack with abe, confirm the probe is absent. No real Android device available (P1-D-13).",
    "status": "resolved",
    "reason": "PASSED on API 36 via bmgr backupnow + LocalTransport, reading FullBackup_native measured lines: release build measured only appdata.json + appdata.backup.json under app_flutter; receipts/ and probe.jpg absent while probe verified present on disk. CAVEAT: only data_extraction_rules.xml (API 31+) exercised; auto_backup_rules.xml (API<=30) carries the same fix but remains unproven.",
    "recorded_at": "2026-08-28T10:40:16.037Z",
    "resolved_at": "2026-08-28T14:31:32.675Z"
  }
]
````
