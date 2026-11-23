/// Declares that a reference field is **one end of a link stored at both
/// ends**: every id it holds is answered by an id pointing back from the other
/// end.
///
/// A `Field` qualifier only (`inverseOf:`): both ends of a link are `refersTo`
/// fields, so there is nothing else to annotate. Both ends declare it, each
/// naming the other, so each end's meta stands alone. A registry of the
/// field's `refersTo` without a field pointing back is not listed: that half
/// of the link is one-way (`tom_specs_model_rules.md` §9.7).
///
/// ```dart
/// Field('relatedScreens', String, 'Related screens',
///     refersTo: ['SCRTEN.@sectionId'], multiple: true,
///     inverseOf: InverseOf(['SCRREQ.relatedRequirements']))
/// ```
class InverseOf {
  /// The other ends, `<FORMSECTIONID>.<field>`: one per registry of this
  /// field's `refersTo` that has a field pointing back; `['@self']` for the
  /// symmetric form.
  final List<String> fields;

  /// Only the values (or rows) matching this filter have an inverse; null:
  /// every value.
  final String? where;

  /// Declares the fields [fields] the other ends of this link.
  const InverseOf(this.fields, {this.where});

  /// The link is stored on both entries in the same field: a row on A naming B
  /// requires a row on B naming A, with the same values in the [where] fields.
  const InverseOf.symmetric({this.where}) : fields = const ['@self'];
}
