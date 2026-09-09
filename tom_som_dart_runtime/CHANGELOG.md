# Changelog

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
