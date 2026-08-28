## Conflict Detection Report

Mode: new · Precedence: ADR > SPEC > PRD > DOC · Sources classified: 1

### BLOCKERS (0)

None. No LOCKED-vs-LOCKED contradiction, no UNKNOWN/low-confidence classification, no cross-ref cycle.

### WARNINGS (1)

[WARNING] Competing default-item counts for the onboarding item-selection step
  Found: D:/Projects/moto-note/motonote-v3-flutter.md §8.2 states the principle "mặc định tích sẵn 6–8 hạng mục quan trọng nhất" and its mockup shows exactly 8 pre-checked items (Nhớt máy, Nhớt láp, Lọc gió, Bugi, Dây curoa, Má phanh trước, Lốp trước, Lốp sau) plus a collapsed "▸ 7 hạng mục nâng cao" row — 15 items total for a scooter.
  Found: D:/Projects/moto-note/motonote-v3-flutter.md §6 (first-run flow diagram, step 4) states "(8 mục tích sẵn)".
  Found: D:/Projects/moto-note/motonote-v3-flutter.md Appendix A defines 24 catalog entries. Filtered by `appliesTo` via `catalogFor(VehicleType)` (§8.1) this yields 20 applicable entries for scooter, 17 for underbone, 19 for manual — not 15. Entries carrying `defaultOn: true` yield 11 for scooter, 11 for underbone, 12 for manual — not 8.
  Found: the three scooter entries marked `defaultOn: true` in Appendix A but NOT pre-checked in the §8.2 mockup are brake_pad_r (Má phanh sau), battery (Ắc quy) and insurance (Bảo hiểm TNDS). §8.2 additionally lists "ắc quy" inside the collapsed advanced group, directly contradicting `battery`'s `defaultOn: true` in Appendix A.
  Impact: The onboarding item-selection screen has two incompatible definitions of its default state. Picking either one silently discards intent — either the stated 6–8 principle is violated, or three `defaultOn` flags in the catalog are wrong. The count shown in the collapsed "advanced" row and the total item count are also unreconcilable.
  → Choose one source of truth before routing: either correct the `defaultOn` flags in Appendix A to match the §8.2 mockup (clear defaultOn on brake_pad_r, battery, insurance), or update §8.2/§6 to describe 11–12 pre-checked items and restate the "6–8" principle. Both variants are preserved verbatim in .planning/intel/constraints.md ("Item-selection screen rules" and "Catalog data (Appendix A)").

### INFO (8)

[INFO] Single-source ingest — precedence ordering not exercised
  Note: Only one classification was present (D:/Projects/moto-note/.planning/intel/classifications/motonote-v3-flutter-3a7f1c92.json, type SPEC). Cross-document precedence resolution (ADR > SPEC > PRD > DOC) had nothing to arbitrate. All conflicts reported above are intra-document.

[INFO] Cycle detection completed clean
  Note: The classification's `cross_refs` array is empty, so the reference graph has one node and zero edges. No cycles; traversal depth 1, well under the cap of 50.

[INFO] SPEC classification carries ADR-like decision content — routed to decisions.md
  Note: The classification records `type: SPEC`, `confidence: medium`, `locked: false`, with the classifier noting that §1 "Chốt phương án" plus the trade-off rationale in §1.1/§1.2 reads ADR-like. Per the orchestrator's instruction, §1's settled choices and the recorded rejections (Google Maps Timeline import, React Native, Hive/Isar/SQLite, BLoC) were extracted into .planning/intel/decisions.md with their rationale rather than left as open options. They are marked `status: locked` because the source states them as settled; no ADR lock semantics were applied, since the doc-level `locked` flag is false and no ADR-classified source exists to lock against.

[INFO] v3.0 supersedes v2.0 (React Native) — superseded doc not in the ingest set
  Note: D:/Projects/moto-note/motonote-v3-flutter.md line 4 states "Phiên bản 3.0 · 2026-08-28 · Thay thế v2.0 (React Native)". The v2.0 document is not present in CLASSIFICATIONS_DIR and no file path is given for it, so there is nothing to reconcile. The React Native rejection is recorded as a locked decision rather than an open option.

[INFO] No PRD sources — requirements.md emitted with zero entries
  Note: The ingest set contains no PRD-classified document, so no `REQ-*` entries were derived. Deriving requirements from the SPEC would be inference rather than extraction. Downstream consumers should read .planning/intel/constraints.md as the behavioural contract and the "implementation plan" topics in .planning/intel/context.md for delivery sequencing.

[INFO] Internal inconsistency between kSchemaVersion and the migration example
  Note: §4.1 declares `const int kSchemaVersion = 1;` while the §4.4 example implements `if (from < 2)` labelled "v1 → v2" and then stamps `data['schemaVersion'] = kSchemaVersion`. With kSchemaVersion at 1, that branch would re-run on already-current data and stamp it back to 1. The §4.4 block is marked illustrative ("// ... các bước sau"), so this is recorded as an observation, not a gate. The migration rule itself — add fields only, never rename, never delete — is unambiguous and is captured in .planning/intel/constraints.md.

[INFO] Overdue-notification cadence is specified in prose but not in code
  Note: §10.1 specifies overdue notifications firing on the due date, then every 14 days, at most 3 times. The §10.4 `rescheduleAll` listing delegates this to `_notifyDatesFor(due, data.settings)`, whose body is not given in the source. The field is marked absent in .planning/intel/constraints.md rather than inferred.

[INFO] Dependency versions are self-declared as non-binding
  Note: §3.1 states the pinned versions are reference points, not commitments, and instructs running `flutter pub outdated` and reading the `google_sign_in` and `freezed` CHANGELOGs before writing code. Recorded in decisions.md with `status: proposed` rather than `locked`, consistent with risk R7 (§15) and §7.3.
