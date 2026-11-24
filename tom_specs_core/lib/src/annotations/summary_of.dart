import 'list_relation.dart';

/// Declares that the annotated list (or reference field) **summarizes** a
/// detailed list, inside one document or across documents.
///
/// Used as a member annotation on a `List<T>` whose elements are overview rows,
/// and as the `Field` qualifier `summaryOf:` on a multi-valued `refersTo` field
/// that names detail elements. A summary carries content: its elements say what
/// each entry is about, and the values it repeats from its detail element are
/// kept equal to the detail's (`tom_specs_model_rules.md` §9.7).
///
/// ```dart
/// @SummaryOf('SCRTEN-SCRE-LST',
///     match: 'SCROV.screenRef',
///     repeats: {'SCROV.@headline': 'SCRTEN.@headline'})
/// List<ScreenOverviewEntry> screenOverview = [];
/// ```
class SummaryOf {
  /// The detailed list: `<LIST-ID>`, or a `/` path from a section of the
  /// model where the list's id is reached at several places
  /// (`FUDI/DSRC-ITEM-LST`).
  final String detail;

  /// The document holding [detail]: its `@Document` root class; null: this
  /// document.
  final Type? document;

  /// The field of a summary element that names its detail element
  /// (`<FORMSECTIONID>.<field>`, a `refersTo` field); null: the summary element
  /// carries the detail element's own section id.
  final String? match;

  /// How the summary's elements relate to the detail's; by default
  /// [LinkRelation.subset], since a summary shows a selection.
  final LinkRelation relation;

  /// Summary place → detail place, for every value the summary repeats; the
  /// detail element holds each, and `deriveFields` refreshes the copy.
  final Map<String, String> repeats;

  /// Free text for the reader of the model.
  final String? note;

  /// Declares that the annotated place summarizes the list [detail].
  const SummaryOf(
    this.detail, {
    this.document,
    this.match,
    this.relation = LinkRelation.subset,
    this.repeats = const {},
    this.note,
  });
}
