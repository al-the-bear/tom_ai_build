/// The document-scoped (short) section ID for this class when used as a
/// top-level entry in a second-wave (Phase 3) DocSpec document.
///
/// Every class reachable from `ProjectDefinition` carries a global
/// `@SectionId` with the `PD00-…` prefix. When the class is also used as a
/// top-level entry in a Phase 3 document, it can additionally carry one or
/// more `@SecondLevelSectionId` annotations — one per target document —
/// supplying the document-prefixed short ID used within that document
/// (e.g. `BDM-DAT` for a class whose global ID is `PD00-BUS-DAT`).
///
/// Phase 3 documents initially inherit the global section ID as-is. This
/// annotation reserves the short-ID mechanism so it can be introduced
/// later without invalidating the model.
///
/// Example:
/// ```dart
/// @SectionId('PD00-BUS-DAT')
/// @DetailedIn(BusinessDataModel)
/// @SecondLevelSectionId(BusinessDataModel, 'BDM-DAT')
/// class DataModel { ... }
/// ```
class SecondLevelSectionId {
  /// The Phase 3 DocSpec document class this short ID applies to.
  final Type documentClass;

  /// The document-scoped section ID (document prefix + suffix from the
  /// global ID, e.g. `BDM-DAT`).
  final String id;

  const SecondLevelSectionId(this.documentClass, this.id);
}
