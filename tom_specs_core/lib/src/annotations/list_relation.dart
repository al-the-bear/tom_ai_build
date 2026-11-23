/// How the elements of the annotated place relate to those of the other place.
///
/// Read from the side that carries the annotation. A relation other than
/// [equal] applies only to a list (a `-LST` container) or to a multi-valued
/// reference field (`Field(multiple: true)`): the Phase 3 document naming more
/// screens than the Blueprint is [subset] on the Blueprint side, not a text
/// drift (`tom_specs_model_rules.md` §9.7).
enum LinkRelation {
  /// Both places hold the same elements; an element on one side only is a
  /// finding.
  equal,

  /// The annotated side may hold fewer: every element it holds must be on the
  /// other side (key requirements ⊆ the full list; a Blueprint sketch ⊆ the
  /// Phase 3 list). An element on the annotated side only is a finding; an
  /// element on the other side only may be added.
  subset,

  /// The annotated side may hold more: every element of the other side must be
  /// on the annotated side.
  superset,
}

/// How the elements of a list relate on the two sides of a `@SyncedWith`,
/// optionally for the elements matching [where] only (a "key" subset, a subset
/// of one type).
///
/// A value object, not an annotation: it stands in [SyncedWith.relations].
///
/// ```dart
/// ListRelation('RETRAR.relatedScreens', LinkRelation.subset)
/// ```
class ListRelation {
  /// The list or multi-valued reference field: a place
  /// (`tom_specs_model_rules.md` §9.7), `<LIST-ID>` or
  /// `<FORMSECTIONID>.<field>`.
  final String place;

  /// How the annotated side's elements relate to the other side's.
  final LinkRelation relation;

  /// Only the elements matching this filter (`<SECTIONID>.<field>=<value>`,
  /// alternatives joined by `|`) are compared; null: every element.
  final String? where;

  /// Declares that the elements of [place] stand in [relation] to the other
  /// side's.
  const ListRelation(this.place, this.relation, {this.where});
}
