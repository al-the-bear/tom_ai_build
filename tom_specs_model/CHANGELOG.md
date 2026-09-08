## 1.2.0

- **The four shared value enums are bound.** `Priority`, `Status`,
  `Probability` and `Impact` were declared with 160 documented constants
  between them and used by no field; they now type 20 form fields, so all 24 of
  the model's enums reach the emitted metadata (was 20) through 42 enum-typed
  `@Form` fields (was 22). A field takes an enum when the band set its label and
  hint document *is* that enum's band set — the two other qualitative scales the
  model uses (the four-band `Critical / High / Medium / Low`, the three-band
  `Low / Medium / High` matrix) are deliberately still `String`.
- **Breaking for a Dart consumer of the generated facade, not for a document.**
  Twenty accessors change from `String?` to an enum type in
  `tom_som_dart_v0` 1.2.0. The *document* format is unchanged: the same keys
  carry the same tokens, so a document authored under model 1.1 loads under 1.2
  — which is why the model **major** does not move. Values are stored as the
  constant name (`must`, `approved`), so a document that spelled them
  `Must` / `Approved` should be re-spelled; nothing rejects the old spelling
  yet, but the typed accessor reads it as `null`.
- The generated DocSpecs schemas now report the model's minor in their own
  version (`solution-blueprint/1.2`); the schema *filenames* stay keyed to the
  major, as before. Before this release every schema silently reported `1.0`
  whatever the model said.
- Depends on `tom_som_dart_runtime` ^1.2.0.

## 1.1.0

- Model additions in the SBP information and experience sections: the CE-EN
  domain-enum extract routing on `information_and_data_model` and the
  entity-typed shared-DTO member locus on `experience_and_interface_design`.
  Additive — documents authored under model 1.0 load unchanged.
- Depends on `tom_som_dart_runtime` ^1.1.0.

## 1.0.0

- Initial version.
