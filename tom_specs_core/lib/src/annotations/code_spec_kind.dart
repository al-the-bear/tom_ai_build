/// The general, type-level half of the DocSpecs ↔ CodeSpecs link
/// (`codespecs_mapping.md` §9.1).
///
/// `@CodeSpecKind` is applied to a SOM section class in `tom_specs_model` to
/// declare which **kind** of CodeSpec element every section of that type must be
/// realised as during Phase 4. It is the *type-level* forward link: "a section
/// of this type maps to a CodeSpec of that kind" (e.g. an information-model
/// entity → `dataAccess`; a form section → `form`; an interface operation →
/// `serverApi`).
///
/// It lives in `tom_specs_core` — not the `tom_code_specs` framework — because it
/// annotates the *model* (SOM) classes, and `tom_specs_model` already depends on
/// `tom_specs_core`. Keeping it here preserves the model → core dependency
/// direction (the model never depends on the CodeSpecs framework) and puts it
/// alongside the other cross-phase link annotations (`@MapsTo`, `@DetailedIn`).
///
/// The concrete, instance-level forward link (`codeSpec` on `DocSpecsSection`,
/// §9.2) and the code-side back-trace (`@DocSpec`/`DocRef`, §9.3) are separate.
/// The `@DocSpec`/`DocRef` annotations annotate CodeSpecs *code* and therefore
/// live in the `tom_code_specs` framework package.
///
/// "CodeSpecsMapping" (used in the csm todo descriptions) is the descriptive
/// alias for this general type-level mapping concept; the annotation type itself
/// is `@CodeSpecKind` (the one canonical symbol — csm1).
///
/// Example:
/// ```dart
/// @CodeSpecKind(CodeSpecPart.form)
/// class OrderForm { ... }
///
/// // A section type may realise several kinds:
/// @CodeSpecKind(CodeSpecPart.serverApi)
/// @CodeSpecKind(CodeSpecPart.authorization, note: 'roles gate the operation')
/// class OrderSubmitOperation { ... }
/// ```
class CodeSpecKind {
  /// The CodeSpecs part this section type must be realised as.
  final CodeSpecPart part;

  /// Optional explanation of the general influence (why/how this section type
  /// shapes the named CodeSpecs part).
  final String? note;

  const CodeSpecKind(this.part, {this.note});
}

/// The finalized catalogue of CodeSpecs "parts" (`codespecs_mapping.md` §4.1).
///
/// Each value is the camelCase form of a part's **canonical id**. The enum is
/// the single source of the kind vocabulary shared by:
///
/// 1. `@CodeSpecKind(CodeSpecPart.x)` — the type-level mapping declared here;
/// 2. the `@Cs<Id>` annotation that marks a CodeSpec class as realising the part
///    (in `tom_code_specs`) — the framework carries **annotations only, no base
///    classes** (`codespecs_mapping.md` §0). A CodeSpec is an ordinary class
///    built on an existing `tom_core`-family class and enriched by that marker.
///
/// The cross-cutting **CE-TR (Traceability)** part is intentionally **absent**:
/// traceability is not a mappable kind — it rides on every element via
/// `@CodeSpec`/`@DocSpec`, so no section type ever maps *to* it.
///
/// Two parts still have open *modeling* questions (their ids are final):
/// `serviceUnit` (boundary criterion — csm-2-1) and `layout` (node model —
/// csm-2-2). Those do not affect this enum's values.
enum CodeSpecPart {
  /// CE-EL — screen element by semantic type, then concrete implementation.
  screenElement,

  /// CE-FM — grouping of elements into forms and subforms.
  form,

  /// CE-LO — screen layout (Flutter layout primitives).
  layout,

  /// CE-TX — texts per element (placeholder, help, error copy).
  text,

  /// CE-VA — validation (per-field and cross-field/form rules).
  validation,

  /// CE-AC — actions and their triggers.
  action,

  /// CE-SC — actions that issue a server call.
  serverCall,

  /// CE-API — server API (operation name + request/response + error contract).
  serverApi,

  /// CE-SU — server-side logical units (cohesive operation grouping).
  serviceUnit,

  /// CE-DB — database access object model (tables, columns, repositories).
  dataAccess,

  /// CE-ST — view-model / UI state.
  viewState,

  /// CE-NV — navigation / routing.
  navigation,

  /// CE-AZ — authorization per operation (realised as a modifier on an endpoint).
  authorization,

  /// CE-ER — the single canonical structured error-result envelope.
  errorResult,

  /// CE-EN — domain enums / value types.
  domainEnum,

  /// CE-CF — configuration and preferences.
  configuration,
}
