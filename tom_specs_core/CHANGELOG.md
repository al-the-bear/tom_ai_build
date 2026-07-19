## Unreleased

- csm2r8: reserve the 9 deferred CodeSpecs element candidates (§4.3) in the
  `CodeSpecPart` enum — `identity`, `schemaMigration`, `workflow`,
  `notification`, `backgroundJob`, `auditLog`, `featureFlag`, `fileStorage`,
  `reporting`. Mapping-only: a SOM section may carry `@CodeSpecKind` with these
  now, but each has no `Cs*` annotation, built-on `tom_core` class or generated
  code until promoted into §4.1. Enum now holds 29 values (20 active + 9
  deferred).

## 1.0.0

- Initial version.
