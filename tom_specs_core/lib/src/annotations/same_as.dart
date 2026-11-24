/// Declares that the annotated section member holds a **copy** of a section
/// the same document holds at another position: the section of the same class
/// reached at the holder position.
///
/// The holder's values win and the two positions always agree
/// (`tom_specs_model_rules.md` §9.7). The copy is never edited where it stands:
/// `deriveFields` writes it from the holder, the validator reports a copy that
/// differs from its holder, and the Markdown rendition marks it as a copy of
/// the holder, so the MD Browser shows it read-only and points to the holder
/// (or edits both through `tomspecs`).
///
/// It stands on a member whose type is a section class reached at more than
/// one position of a document, as the acceptance criteria are inside their
/// summary and under the acceptance plan:
///
/// ```dart
/// @SameAs(note: 'The acceptance plan holds the criteria; this is its copy.')
/// AcceptanceCriteriaList detailedCriteria = AcceptanceCriteriaList();
/// ```
class SameAs {
  /// The holder position: the section ids of the path from the document root
  /// to it, `/`-joined, as far as needed to name it (`ACPLN/ACRITL`). Null:
  /// the one other position of the member's class in each document that
  /// reaches it.
  final String? holder;

  /// Free text for the reader of the model.
  final String? note;

  /// Declares that the annotated member is a copy of the section at [holder].
  const SameAs({this.holder, this.note});
}
