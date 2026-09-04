# Changelog

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
