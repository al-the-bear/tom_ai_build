# SOM file mapping — superseded

**Status:** Superseded / redirect stub (2026-07-16, YRD1 consolidation).

The member-by-member mapping contract between the annotated Dart classes in
`tom_specs_model` and the two on-disk DocSpecs representations
(`*.docspecs.yaml`, `*.md`) has been consolidated into the single mapping
authority:

> **`../tom_specs_model/doc/som_mapping.md`**
> *TomSpecs Mapping — Object Model ↔ SOM Classes ↔ DocSpecs md/yaml*

All nine runtime ports (Dart reference + Python, JS, TS, Go, Java, Rust, C,
C++) implement against that document; the conformance corpus and shared sample
(`samples/meridian_order_management.*`) are validated against it. Do not
extend this file.

Note: this file's 2026-07-14 status note (md emitter / schema generator not
yet emitting the `*-LST` container) was already stale at consolidation time —
the container level is fully implemented; see `som_mapping.md` §14.

Historical full text: git history of this file (last full revision before
2026-07-16).
