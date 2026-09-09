# Changelog

## 0.2.0

The annotation catalogue grew with the model it annotates: 43 files, +2400
lines since 0.1.0.

- **New annotations.** `@CodeSpecKind` / `CodeSpecPart` (the type-level
  DocSpecs↔CodeSpecs routing), `@FollowUpKind` / `FollowUpProcess`,
  `@NoArtifact` / `NoArtifactReason` — the three routing verdicts that make the
  `ROUTE-TOTAL` structural invariant checkable — plus `@CodeSpecsProjection`,
  `@AccessKey`, `@AllowedTags`, `@Case`/`@CaseOf`, `@ValidationPrompt` and the
  `refersTo` target on `Field`, which turns a free-text id contract from hint
  prose into something both validation tiers can enforce.
- **`DocSpecsSection` gains `codeSpec`**, the concrete forward link from a
  section to the CodeSpecs code it was realised as.
- The package is documented: `doc/annotations.md`, `doc/sections.md` and
  `doc/index.md`, with the README as the annotation catalogue itself.
- No behaviour to break — these are annotations — but the catalogue is larger,
  so a consumer pinned to 0.1.0 sees none of it.

## 0.1.0

Initial development release (pub.dev 0.x channel, BSD-3-Clause).

- csra8: `CodeSpecPart.reporting` (CE-RP) is **active**, not deferred. Its doc
  comment now carries the live mapping — the grouped projection built on
  `TomReportDefinition` / `TomReportResult` (`tom_core_codespecs`) over the
  `tom_core_server` query and rendering substrate, marked by `@CsReport`,
  `@CsReportColumn`, `@CsReportChart` and `@CsReportParameter` — and records why
  CE-RP is not a composition of `serverApi` + `dataAccess` + `form`. The enum is
  unchanged at **28 values**; only the readiness split moves, to 26 active /
  1 deferred (`workflow`, deferred permanently).

- csm2r8: reserve the 9 deferred CodeSpecs element candidates
  (`codespecs_mapping.md` §4.3) in the `CodeSpecPart` enum — `identity`,
  `schemaMigration`, `workflow`, `notification`, `backgroundJob`, `auditLog`,
  `featureFlag`, `fileStorage`, `reporting`. Mapping-only: a SOM section may
  carry `@CodeSpecKind` with these now, but each has no `Cs*` annotation,
  built-on `tom_core` class or generated code until promoted into
  `codespecs_mapping.md` §4.1. Enum now holds 29 values (20 active + 9
  deferred).
