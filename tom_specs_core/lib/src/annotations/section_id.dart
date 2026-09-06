/// Declares the section ID that the annotated class has in the target
/// specification document.
///
/// Applied to model classes.
///
/// Example: `@SectionId('INDM')` maps the class to section INDM.
class SectionId {
  /// The section id, e.g. `'INDM'`.
  ///
  /// Uppercase, and **globally unique** across the whole model — not merely
  /// unique within a document (`tom_specs_model_rules.md` §10.2 invariant
  /// `ID-UNIQUE`). The id is the stable handle a document, a review file and a
  /// CodeSpecs back-link all address the section by, so reusing one silently
  /// merges two unrelated sections in every one of them.
  final String id;

  /// Declares [id] as the annotated class's section id.
  const SectionId(this.id);
}
