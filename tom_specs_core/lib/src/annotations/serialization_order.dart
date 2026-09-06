/// Declares the serialization ordinal of a member within its declaring class.
///
/// Applied to members. The ordinal is the member's position in **source
/// declaration order** within its class (0-based). It pins the order in which a
/// document's members are emitted when the spec is serialized (e.g. to YAML),
/// so the on-disk form follows the model's authored order rather than a hash,
/// insertion, or alphabetical order.
///
/// Every member of every spec-model class carries this annotation; it is
/// stamped in bulk by `tom_specs_clitool/bin/stamp_serialization_order.dart`.
/// The captured ordinal flows through `ModelReader` (as
/// `ModelField.serializationOrder`) and `ModelJsonExporter` into the SOM /
/// `spec_model.json` so generators can preserve member order across languages.
class SerializationOrder {
  /// The member's 0-based position in source declaration order within its class.
  final int order;

  /// Stamps the annotated member with its declaration [order].
  ///
  /// Never written by hand: `stamp_serialization_order.dart` renumbers every
  /// member of every class from source order, and the SOM generator refuses to
  /// run past an unstamped member. Insert a new member where it belongs in the
  /// source and re-run the stamper rather than choosing an ordinal.
  const SerializationOrder(this.order);
}
