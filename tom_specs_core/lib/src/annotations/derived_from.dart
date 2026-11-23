/// The three shapes a derived value takes.
enum DerivationKind {
  /// The value is another place's value.
  copy,

  /// The value collects places from the rows that match a filter.
  rows,

  /// The value is read from the one row whose key matches this element.
  lookup,
}

/// Declares that the annotated place's value is **derived** from other places
/// of its document, so `deriveFields` writes it and a stored value that
/// disagrees is a finding.
///
/// Used as a member annotation on a section or list, and as the `Field`
/// qualifier `derivedFrom:`. A field carries at most one of `derivedFrom`,
/// `countOf`, `productOf` and `rankOf`, and a derived place is never shared
/// between documents: each document derives it from its own sources
/// (`tom_specs_model_rules.md` §9.7).
///
/// The value of a collection: one [take] place into a multi-valued reference
/// field writes the ids comma-separated; several [take] places into a text
/// field write one line per row, the values joined by ` — `; on a list member,
/// [map] builds one element per row.
///
/// ```dart
/// Field('conflictsWith', String, 'Conflicts with',
///     refersTo: ['FRE-REQU-ITEM.@sectionId'], multiple: true,
///     derivedFrom: DerivedFrom.rows('./RQDEP',
///         where: 'RQDEP.dependencyType=conflict',
///         take: ['RQDEP-RELA-REF.ref']))
/// ```
class DerivedFrom {
  /// Which of the three shapes the derivation takes.
  final DerivationKind kind;

  /// [DerivationKind.copy]: the place copied; [DerivationKind.rows] and
  /// [DerivationKind.lookup]: the rows read, `<SECTIONID>` or `./<SECTIONID>`.
  final String source;

  /// [DerivationKind.rows]: which rows count, in the filter grammar
  /// (`<SECTIONID>.<field>=<value>`, alternatives joined by `|`); null: every
  /// row.
  final String? where;

  /// [DerivationKind.rows] and [DerivationKind.lookup]: the row places
  /// collected.
  final List<String> take;

  /// [DerivationKind.lookup]: the row field compared with [by].
  final String? key;

  /// [DerivationKind.lookup]: the field of this element holding the key.
  final String? by;

  /// For a list member: target element place ← row place.
  final Map<String, String> map;

  /// Free text for the reader of the model.
  final String? note;

  /// The value is the value of the place [source].
  const DerivedFrom.copy(this.source, {this.note})
    : kind = DerivationKind.copy,
      where = null,
      take = const [],
      key = null,
      by = null,
      map = const {};

  /// The value collects the places [take] from the rows of [source] that match
  /// [where]; on a list member, [map] builds one element per row.
  const DerivedFrom.rows(
    this.source, {
    this.where,
    this.take = const [],
    this.map = const {},
    this.note,
  }) : kind = DerivationKind.rows,
       key = null,
       by = null;

  /// The value is read from the row of [source] whose field [key] equals this
  /// element's field [by]: the places [take] of that row. When several rows
  /// match, the last in list order wins.
  const DerivedFrom.lookup(
    this.source, {
    required String this.key,
    required String this.by,
    required this.take,
    this.note,
  }) : kind = DerivationKind.lookup,
       where = null,
       map = const {};
}
