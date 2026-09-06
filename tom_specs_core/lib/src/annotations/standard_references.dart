/// Records the public standard(s) a section or field is derived from, plus a
/// short statement of what the section means.
///
/// Applicable to classes and members. The `standards` list names the public
/// standards a section/field traces back to — each entry is the standard's ID
/// plus the clause/term in the standard's own wording (e.g.
/// `'ISO/IEC 25010:2023 §4.2 — Functional suitability'`). The `connotation`
/// states what the section *means* (its intent / what it owns), which is
/// distinct from the author-facing "how to fill this in" guidance carried by
/// [ContentHelp] and the `@Form` field `hint:`.
///
/// This supersedes the prose `**Standard anchor**:` doc-comment convention; the
/// captured values flow through `ModelReader` and `ModelJsonExporter` into the
/// SOM / `spec_model.json` so consumers can read provenance programmatically.
///
/// Example:
/// ```dart
/// @StandardReferences(
///   const ['ISO/IEC 25010:2023 §4.2 — Functional suitability'],
///   'The quality characteristics the system is measured against.',
/// )
/// class QualityModel { ... }
/// ```
class StandardReferences {
  /// The public standards this section/field derives from. Each entry is the
  /// standard ID plus the relevant clause/term in the standard's own wording.
  final List<String> standards;

  /// What this section means (intent / ownership), distinct from the
  /// author-facing guidance in [ContentHelp] / the `@Form` field `hint:`.
  final String connotation;

  /// Records the public [standards] the annotated section derives from and
  /// what the section means ([connotation]).
  const StandardReferences(this.standards, this.connotation);
}
