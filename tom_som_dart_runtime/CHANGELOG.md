# Changelog

## 1.3.3

- Version follows the TomSpecs model to 1.3.3, which the generated
  `tom_som_dart_v0` facade pins.
- Markdown export (SOM §11.4 rule 2): consecutive `@Form` field groups are now
  separated by one blank line, also after a multi-line value, so a markdown
  viewer renders each `FieldName: value` group as its own paragraph and a
  markdown list ending a value no longer swallows the next `Field:` line as a
  lazy continuation. Parse and the DocSpecs validator accept the layout with
  or without the separator; values round-trip unchanged. Exported `*.md` files
  gain blank lines inside form blocks — nothing else about the format moves.

## 1.3.2

- Version realigned to TomSpecs model 1.3.2 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself: 1.3.2 carries a test-only fix in
  `tom_specs_model`, whose shipped tests read a workspace sibling and crashed in
  a hosted install.

## 1.3.1

- Version realigned to TomSpecs model 1.3.1 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself; 1.3.1 corrects dependency
  constraints across the release set so the published chain resolves to a set
  that actually compiles together.

## 1.3.0

- Version realigned to TomSpecs model 1.3 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself: the model-side work in this
  release (`ImportanceBand`, and the three-band risk entries moved onto the
  five-band matrix) reaches consumers through the regenerated facade and
  metadata, both of which this runtime reads generically.

## 1.2.0

- Version realigned to TomSpecs model 1.2 (lockstep with `tom_som_dart_v0`).
- No behavioural change to the runtime itself: the model-side work in this
  release (the four value enums bound to 20 form fields) reaches consumers
  through the regenerated facade and metadata, both of which this runtime reads
  generically.

## 1.1.0

- The CodeSpecs extractor (`spec_codespecs_extract`) emits extract format 3:
  entries additionally carry the enclosing section instance's `headline`
  (format 2) and the nearest enclosing list-item instance's stored
  `instanceId` (format 3). Both fields are copy-only and additive.
- Version realigned to TomSpecs model 1.1 (lockstep with `tom_som_dart_v0`).

## 1.0.0

- First packaged release of the generic Dart SOM runtime.
- Version tracks the TomSpecs model version; the typed `tom_som_dart_v0` facade
  pins the same version.
