/// Declares a field as a reference to data owned elsewhere in the model tree.
///
/// Applied to a `DocSpecsSection` member that holds the referenced entry's
/// section id in a one-field `@Form` — `ref` for one id, `refs` for several,
/// comma-separated — whose [Field.refersTo] names the registry it is drawn
/// from, so the instance tier resolves it and reports a wrong id
/// (`tom_specs_model_rules.md` §6.1, **ref**). The outliner shows the
/// reference but does not recurse into the referenced tree.
///
/// [description] is a human-readable label for the reference.
class Reference {
  /// A human-readable label for what is being pointed at.
  ///
  /// This is what the outline shows in place of the referenced subtree, which
  /// it declines to recurse into — so it is the reader's only description of
  /// the target at this point in the tree.
  final String description;

  /// Declares the annotated member as a reference rather than an owning link.
  const Reference(this.description);
}
