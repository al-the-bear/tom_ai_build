# TomSpecs Editor — Specification Consolidation Plan

Follow-up items produced while consolidating the TomSpecs Editor design into the
single authoritative specification, `tom_specs_editor_specification.md`. The
specification itself documents the **current** design; this file tracks the
open work that the review surfaced. Items are grouped by whether they are
documentation follow-ups on the spec or implementation tasks for the editor
build.

## Consolidation status

- **Single source of truth.** `tom_specs_editor_specification.md` is now the
  only TomSpecs Editor design document. The two working files
  (`tom_specs_editor_specification_open_ends.md`,
  `tom_specs_editor_specification_open_ends_questions.md`) had their durable
  current-state facts folded in and were deleted.
- **Facts folded from the open-ends files:**
  - §3.8 — the generated Dart SOM API (`tom_som_dart_v0` typed facade over
    `tom_som_dart_runtime`) and the parallel-major (`_v0`/`_v1`/…) versioning
    property.
  - §11.5 — the file-injection folder-resolution table
    (`guidelines`/`role`/`quest`/`file` prefixes) and the lenient `${chat}` /
    `${file}` provider seam.
  - §13 — the two access layers (generic `SpecClass` graph for rendering, typed
    `tom_som_dart_v0` facade for correctness-checked edits).
  - §14 — the canonical-path projection-identity primitive
    (`canonicalPathFor` / `isProjectionRoot`) and its conflation guard.
  - §16 — the prefix-based `pattern-check-id` rule and the
    `min`/`max-count-in-document` cardinality semantics (optional-by-design
    projection slots per N12).
- **tom_brain reconciliation.** The provider layer is documented as it exists
  today: it lives in `tom_core_agentic` (v1.8.0) with the HTTP/stub providers
  remaining in `tom_brain_substrate`. The former "migration plan" framing (§4.3,
  §2 N7/N13, §19 T3, §20 Stage A) was rewritten to current state, and the class
  names were corrected to `AgentSdkSessionStrategy` / `AgentSdkSessionStore`.

## Documentation follow-ups (spec)

- **DOC-1 — Verify SOM package version stamps at build time.** The spec cites
  `tom_som_dart_runtime` v0.1.0, `tom_som_dart_v0` v0.0.0, and model stamp
  `modelVersion = '1.0'` (§3.8). Re-check these against the packages when the
  build script (§17) is wired, and keep the stamp reference in sync with the
  `buildkit.yaml` versioner output.
- **DOC-2 — Keep §3.6/§4.3 aligned with `tom_core_agentic` releases.** The
  provider-layer description is version-pinned to v1.8.0. If `tom_core_agentic`
  moves the session-strategy or provider surface, update §3.6, §4.3, §2 (N7/N13)
  and §20 Stage A together.

## Implementation tasks carried into the build (from spec §19–§20)

These are the confirmed build tasks the spec already names; listed here so the
plan is the single review checklist.

- **PLAN-1 — Canonical-container tree root (spec T1 / §20 step 4, 7).** Add the
  unannotated container root to `tom_specs_model` and teach `ModelJsonExporter`,
  the outliner, and the §8.6 validator to treat it as the tree root (exempt from
  `@SectionId` coverage/uniqueness).
- **PLAN-2 — Pure-projection validator invariant (spec T2 / §20 step 7).** Add
  the §8.6 invariant that every projection-root content-bearing node traces back
  via `@MapsTo`/`@DetailedIn` to a Solution Blueprint section.
- **PLAN-3 — `toYaml` + connect pass on the model (spec §15.1 / §20 step 6).**
  Global root `toYaml` emits SBP content once; projection roots' `toYaml` used
  only for individual-file writes, preceded by the connect pass.
- **PLAN-4 — Canonical-path value/review re-keying (deferred, from OE-18 /
  OE-2a).** `canonicalPathFor` ships as a read-only binding primitive (§14).
  Re-keying `SpecDocument`'s value store and `ReviewStore` onto canonical paths
  is deferred until the twelve concrete per-root `@MapsTo`/`@DetailedIn` →
  SBP-field-path bindings exist; the value-store purge/`hasValuesUnder` logic is
  prefix-based and is not prefix-preserving across the anchor boundary, so a
  naive re-key would break those invariants.
- **PLAN-5 — Precise list cardinality via `subsection-types` (deferred, from
  OE-20/OE-21).** `min`/`max-count-in-document` is emitted at the document level
  today (exact for a top-level list slot, an over-approximation when an element
  type recurs under multiple parents, §16). Move list `@Min`/`@Max` to a
  `subsection-types` min/max constraint on the parent section-type once the
  generator knows the parent→child section-type linkage (the connect-pass work).
- **PLAN-6 — `pattern-check-text` annotation (deferred).** There is no model
  annotation that constrains a section's text body, so nothing maps onto
  `pattern-check-text` (§16). Introducing one is a separate model-annotation
  decision, out of the current scope.
- **PLAN-7 — Adopt the typed `_v0` facade where the reviewer prototype edits.**
  The `tom_specs_reviewer` prototype consumes only the generic runtime today
  (§19.1); adopting the typed `tom_som_dart_v0` object model is the later step
  taken when the reviewer grows document editing (Stage D, §20).
