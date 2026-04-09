/// Declares a field as a reference to data owned elsewhere in the model tree.
///
/// Applied to singular or list fields. Relaxes the naming rule that requires
/// field name to match type name.
///
/// [description] is a human-readable label for the reference.
/// [field] is the symbol of the target field being referenced.
class Reference {
  final String description;
  final Symbol field;

  const Reference(this.description, this.field);
}
