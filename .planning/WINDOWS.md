---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 0
total_count: 1
last_updated: 2026-08-28T09:42:17.774Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | unrun-verify | android/app/build.gradle.kts |  | SETUP-06 on-device install/start (flutter run --release on a real 3-4GB-RAM Android device) not run — no hardware available; only the Gradle-configuration half (flutter build apk --debug) is proven by 01-02 | open |  | 2026-08-28T09:42:17.774Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "android/app/build.gradle.kts",
    "line": null,
    "description": "SETUP-06 on-device install/start (flutter run --release on a real 3-4GB-RAM Android device) not run — no hardware available; only the Gradle-configuration half (flutter build apk --debug) is proven by 01-02",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T09:42:17.774Z",
    "resolved_at": null
  }
]
````
