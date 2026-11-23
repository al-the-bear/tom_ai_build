/// What `deriveFields` does with an id an `@ExtractsLinks` finds in text.
enum ExtractMode {
  /// `deriveFields` writes the missing rows.
  generate,

  /// The validator only reports an id named in the text without a row.
  warn,
}

/// Declares that the annotated list of **link rows** is kept in step with the
/// ids named in text places: an id found in [from] gets a row whose [ref]
/// holds it.
///
/// It stands on a `List<T>` member whose elements are link rows, and may be
/// repeated on one member, one use per kind of row. An id is found by exact
/// match of a registered section id, never a human code from a heading; the
/// element's own id is skipped; an id that already has a row of any type gets
/// no second row; a generated row whose id the text no longer names is
/// reported, and only rows whose [set] values match are touched
/// (`tom_specs_model_rules.md` §9.7).
///
/// ```dart
/// @ExtractsLinks(from: ['FRED.description'], ref: 'RQDEP-RELA-REF.ref',
///     set: {'RQDEP.dependencyType': 'namedInText'})
/// List<RequirementDependencyEntry> dependencies = [];
/// ```
class ExtractsLinks {
  /// The text places searched for ids, resolved beneath the nearest list
  /// element (the requirement the rows belong to).
  final List<String> from;

  /// The row's `refersTo` field that receives a found id; its `refersTo` says
  /// which registries' ids are searched.
  final String ref;

  /// The values every generated row gets (`RQDEP.dependencyType` →
  /// `namedInText`).
  final Map<String, String> set;

  /// Whether missing rows are written ([ExtractMode.generate]) or only
  /// reported ([ExtractMode.warn]).
  final ExtractMode mode;

  /// Free text for the reader of the model.
  final String? note;

  /// Declares the annotated list's rows extracted from the text places [from].
  const ExtractsLinks({
    required this.from,
    required this.ref,
    this.set = const {},
    this.mode = ExtractMode.generate,
    this.note,
  });
}
