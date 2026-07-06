/// The document-scoped (short) section ID for this class when used as a
/// top-level entry in a second-wave (Phase 3) DocSpec document.
///
/// Every class reachable from `D00SolutionBlueprint` carries a global
/// `@SectionId` — a short mnemonic code. When the class is also used as a
/// top-level entry in a Phase 3 document, it can additionally carry one or
/// more `@SecondLevelSectionId` annotations — one per target document —
/// supplying the document-prefixed short ID used within that document
/// (e.g. `QAP-FRA` for a class whose global ID is `QLFWK`).
///
/// Phase 3 documents initially inherit the global section ID as-is. This
/// annotation reserves the short-ID mechanism so it can be introduced
/// later without invalidating the model.
///
/// Example:
/// ```dart
/// @SectionId('QLFWK')
/// @DetailedIn(D10QualityAcceptancePlan)
/// @SecondLevelSectionId(D10QualityAcceptancePlan, 'QAP-FRA')
/// class QualityFramework { ... }
/// ```
class SecondLevelSectionId {
  /// The Phase 3 DocSpec document class this short ID applies to.
  final Type documentClass;

  /// The document-scoped section ID (document prefix + suffix from the
  /// global ID, e.g. `QAP-FRA`).
  final String id;

  const SecondLevelSectionId(this.documentClass, this.id);
}
