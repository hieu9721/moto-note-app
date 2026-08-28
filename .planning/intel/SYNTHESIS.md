# Synthesis

Entry point for downstream consumers (`gsd-roadmapper`). Produced by `gsd-doc-synthesizer`.

Mode: new · Precedence applied: ADR > SPEC > PRD > DOC · Existing context: none (`.planning/` bootstrapped)

---

## Doc counts by type

- SPEC: 1 — D:/Projects/moto-note/motonote-v3-flutter.md (confidence: medium, locked: false, cross_refs: none)
- ADR: 0
- PRD: 0
- DOC: 0
- UNKNOWN: 0

Total classifications consumed: 1
Classification file: D:/Projects/moto-note/.planning/intel/classifications/motonote-v3-flutter-3a7f1c92.json

Source language is Vietnamese. Synthesized intel is written in English with Vietnamese domain terms,
catalog item names and UI copy preserved verbatim.

## Cycle detection

Ran on the `cross_refs` graph: 1 node, 0 edges, no cycles. Traversal depth 1 (cap 50).

## Decisions

33 entries — D:/Projects/moto-note/.planning/intel/decisions.md

- locked: 31
- proposed: 2 (dependency version pins; fuel log as the first post-1.0 feature)

No ADR-classified sources exist, so no ADR lock semantics were applied. The entries come from the SPEC's
§1 "Chốt phương án" (decisions locked in), §1.1/§1.2 (rejected options with rationale), §2 (five design
principles), §3.2 (stack rationale), and the decision statements embedded in §4.3, §4.4, §7.2, §7.3,
§7.5, §7.6, §7.7, §8.1, §8.3, §9.4, §9.6, §10.3, §10.4, §11, §12, §13.2 and §13.3.

Rejections recorded as locked decisions rather than open options, per orchestrator instruction:
- Google Maps Timeline import (§1.1) — no API, format undocumented and thrice-changed, Takeout no longer
  exports it, and the data is directionally wrong for setting ODO.
- React Native (§1.2) — superseded by the Flutter choice; v3.0 replaces the v2.0 React Native plan.
- Hive / Isar / SQLite (§3.2) — a plain JSON file is simpler and fits the backup architecture.
- Provider / BLoC (§3.2) — Riverpod with one `NotifierProvider` is sufficient at this scale.

## Requirements

0 entries — D:/Projects/moto-note/.planning/intel/requirements.md

No PRD-classified sources in the ingest set. Requirement extraction is PRD-fed by contract, so nothing
was derived. Use `constraints.md` as the behavioural contract and the implementation-plan topics in
`context.md` for delivery sequencing.

## Constraints

40 entries — D:/Projects/moto-note/.planning/intel/constraints.md

Type breakdown:
- schema: 9 — dependency manifest; AppData root; Vehicle; MaintenanceItem; ServiceLog/ServiceLogEntry;
  OdoReading/Note/Settings; migration contract; CatalogEntry; catalog data (24 entries, Appendix A);
  oil grade presets
- api-contract: 5 — Drive `appDataFolder` scope properties; google_sign_in v7 authorization;
  Drive read/write surface; notification deep-link payload; Google Cloud / OAuth release configuration
- protocol: 19 — architecture topology; atomic local write; `_mutate` invariant; derived-state provider;
  first-run flow; onboarding baseline seeding; sign-in framing; backup triggers; restore safety;
  item-selection rules; part-spec prefill; ODO formula; avg km/day refinement; due computation;
  honest-uncertainty display; test surface; notification taxonomy/init/permissions/composition;
  screen inventory; home screen rules; ODO sheet; project structure; tooling commands
- nfr: 7 — data-volume budget (<200 KB); Android Auto Backup fallback; rescheduling OS limits
  (`_horizonDays` 120, `_maxScheduled` 30, iOS cap 64); Android OEM ROM battery tolerance;
  Android platform release constraints; iOS platform release constraints; technical release acceptance;
  store submission

## Context topics

11 topics — D:/Projects/moto-note/.planning/intel/context.md

Product framing; overall estimate (~7 part-time weeks, ~2 of them learning Flutter, ~5 if Dart is known);
Week 0 familiarisation; Week 1 foundations and data; Weeks 2–3 core features; Week 4 notifications;
Week 5 Google Drive; Weeks 6–7 polish and release; descoping order if an earlier release is needed;
risk register R1–R10; React-to-Flutter mental model differences; seven first-week mistakes.

## Conflicts

- 0 blockers
- 1 competing-variant (WARNING)
- 8 auto-resolved / informational (INFO)

The single WARNING is an intra-document contradiction on the onboarding item-selection defaults: §8.2
and §6 state 8 pre-checked items out of 15 (and a stated principle of 6–8), while Appendix A's
`defaultOn` flags filtered by `appliesTo` yield 11 pre-checked out of 20 for scooter, 11/17 for
underbone and 12/19 for manual — with `battery` (Ắc quy) explicitly listed as advanced in §8.2 while
carrying `defaultOn: true` in Appendix A. Both variants are preserved in `constraints.md`; neither was
picked.

Detail: D:/Projects/moto-note/.planning/INGEST-CONFLICTS.md

## Intel files

- D:/Projects/moto-note/.planning/intel/decisions.md
- D:/Projects/moto-note/.planning/intel/requirements.md
- D:/Projects/moto-note/.planning/intel/constraints.md
- D:/Projects/moto-note/.planning/intel/context.md
- D:/Projects/moto-note/.planning/INGEST-CONFLICTS.md
