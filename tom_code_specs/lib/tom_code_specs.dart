/// TomSpecs CodeSpecs & Implementation document models.
///
/// Typed object models for the two phase-2 creation phases — **CodeSpecs**
/// (Phase 4) and **Implementation** (Phase 6). Each root is an annotated
/// `@Document` whose structure mirrors the authoritative `SpecPhase` content
/// in `tom_specs_editor`, so the model-driven editor can render and author
/// these documents the same way it renders the Phase-3 DocSpec roots.
library;

export 'src/code_specs_document.dart';
export 'src/implementation_document.dart';
