/// CDS — CodeSpecs document (Phase 4).
///
/// Object model for the TomSpecs **CodeSpecs** creation phase: the phase that
/// transforms the Phase-3 documentation into code-based artifacts — a skeletal
/// application that *compiles but does not execute*. The structure mirrors
/// `SpecPhase.codeSpecs` in `tom_specs_editor` (the authoritative phase
/// content) so a model-driven editor can render and author CodeSpecs documents
/// the same way it renders the Phase-3 DocSpec roots.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// CDS00 CodeSpecs.
///
/// Phase-4 document root. Transforms Phase-3 documentation into code-based
/// artifacts: a skeletal application that compiles but does not execute (every
/// method throws `UnimplementedError` pending the Implementation phase).
@Document(
  name: 'CodeSpecs',
  description: 'Code-based artifacts bridging Phase-3 specifications and the '
      'Implementation phase — a skeletal application that compiles but does '
      'not execute, with full traceability from each code element to its '
      'specification sources.',
)
@SectionId('CDS')
class CodeSpecsDocument {
  @ContentHelp('Executive overview of the CodeSpecs phase: how Phase-3 '
      'documentation is transformed into a compiling-but-not-executing '
      'skeleton with complete spec traceability.')
  String? content;

  /// One-line characterisation of the phase's key output.
  @SectionId('CDS-TAG')
  @ContentHelp('A single line characterising the phase output, e.g. '
      '"Skeletal application — compiles but does not execute".')
  String? tagline;

  /// The phase purpose (a short prose paragraph).
  @SectionId('CDS-PUR')
  @ContentHelp('The purpose of the CodeSpecs phase: what it transforms, what '
      'state the codebase is in when it ends, and why every method throws '
      '`UnimplementedError` at this point.')
  String? purpose;

  /// What must exist before the phase begins.
  @SectionId('CDS-INP-LST')
  @SectionIdPattern('CDS-INP-xxx')
  List<CodeSpecsInput> inputs = [];

  /// What the phase produces.
  @SectionId('CDS-PRD-LST')
  @SectionIdPattern('CDS-PRD-xxx')
  List<CodeSpecsProduct> produces = [];

  /// The phase's named components, with their Phase-3 sources.
  @SectionId('CDS-CMP-LST')
  @SectionIdPattern('CDS-CMP-xxx')
  List<CodeSpecsComponent> components = [];

  /// What must be true before proceeding to the next phase (quality gate).
  @SectionId('CDS-EXT-LST')
  @SectionIdPattern('CDS-EXT-xxx')
  List<CodeSpecsExitCriterion> exitCriteria = [];

  /// A note on the phase's current editor status and phase-2 direction.
  @SectionId('CDS-PH2')
  @ContentHelp('Notes on the phase-2 direction for this phase — e.g. the '
      'Flutter client layers targeting the `tom_flutter_ui` component '
      'library and the embedded analyzer summaries.')
  String? phase2Note;
}

/// A single CodeSpecs input — a precondition that must exist before the
/// phase begins.
@SectionId('CDS-INP')
class CodeSpecsInput {
  @ContentHelp('One required input, e.g. a Phase-3 document the CodeSpecs '
      'phase consumes.')
  String? content;
}

/// A single CodeSpecs output — an artifact the phase produces.
@SectionId('CDS-PRD')
class CodeSpecsProduct {
  @ContentHelp('One artifact the CodeSpecs phase produces, e.g. the skeletal '
      'application or the traceability report.')
  String? content;
}

/// A named CodeSpecs component, with the Phase-3 document(s) it derives from.
@SectionId('CDS-CMP')
class CodeSpecsComponent {
  @Form([
    Field('name', String,
        'Name — the component display name, e.g. "UI Elements"',
        required: true),
    Field('description', String,
        'Description — one line on what the component is', required: true),
    Field('source', String,
        'Source — the Phase-3 document(s) it derives from, e.g. '
            '"UP (UI Prototype)"; blank for derived/structural components'),
  ])
  String? content;
}

/// A single CodeSpecs exit criterion — part of the phase quality gate.
@SectionId('CDS-EXT')
class CodeSpecsExitCriterion {
  @ContentHelp('One condition that must hold before leaving the CodeSpecs '
      'phase, e.g. "Application compiles without errors".')
  String? content;
}
