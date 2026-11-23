import 'list_relation.dart';

/// Declares that the annotated section is **kept in sync** with the section
/// of the same id in [document]: every value both documents hold agrees, and
/// `backfill` carries the other document's values in.
///
/// It stands on a class, beside the `@DetailedIn` naming the same document,
/// or alone on a section that must be kept in sync without one; where the
/// synced section is a form member rather than a class, it stands on the
/// member.
///
/// The rules the runtimes read from it (`tom_specs_model_rules.md` §9.7):
/// every value both documents hold agrees; the holder's value wins, also when
/// it is empty; under a `subset` relation an element only in the other
/// document may be added; ids are never changed (a rename is global); a
/// derived place is never shared.
///
/// ```dart
/// @DetailedIn(D04RequirementsSpecification)
/// @SyncedWith(D04RequirementsSpecification,
///     detailOnly: ['REQDEP', 'RETRAR.relatedTestCases'],
///     relations: [
///       ListRelation('RETRAR.relatedScreens', LinkRelation.subset),
///     ])
/// class FunctionalRequirements extends DocSpecsSection { ... }
/// ```
class SyncedWith {
  /// The document holding the section of the same id: its `@Document` root
  /// class.
  final Type document;

  /// The places below this section that only [document] carries: the detail
  /// below this document's level beyond what `@DetailedIn` already cuts.
  /// Empty: the level is the `@DetailedIn` cut.
  final List<String> detailOnly;

  /// The places whose value this document holds; every other shared place is
  /// held by [document].
  final List<String> heldHere;

  /// The lists and multi-valued reference fields whose relation is not
  /// [LinkRelation.equal].
  final List<ListRelation> relations;

  /// Free text for the reader of the model.
  final String? note;

  /// Declares the annotated section kept in sync with [document].
  const SyncedWith(
    this.document, {
    this.detailOnly = const [],
    this.heldHere = const [],
    this.relations = const [],
    this.note,
  });
}
