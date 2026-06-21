/// IMPL — Implementation document (Phase 6).
///
/// Object model for the TomSpecs **Implementation** creation phase: the phase
/// that fills in the CodeSpec skeleton level by level, verifying each piece
/// (with its Phase-5 tests) before proceeding. The structure mirrors
/// `SpecPhase.implementation` in `tom_specs_editor` (the authoritative phase
/// content) so a model-driven editor can render and author Implementation
/// documents the same way it renders the Phase-3 DocSpec roots.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// IMPL00 Implementation.
///
/// Phase-6 document root. Implements the system incrementally, verifying each
/// piece before proceeding; dependency analysis fixes the implementation order
/// so each level builds only on already-verified levels below it.
@Document(
  name: 'Implementation',
  description: 'Incremental, dependency-ordered implementation of the CodeSpec '
      'skeleton — working code plus passing unit tests, built and verified '
      'level by level from the database schema up to the UI.',
)
@SectionId('IMPL')
class ImplementationDocument {
  @ContentHelp('Executive overview of the Implementation phase: how the '
      'CodeSpec skeleton is filled in level by level, each level verified '
      'against its Phase-5 tests before the next begins.')
  String? content;

  /// One-line characterisation of the phase's key output.
  @SectionId('IMPL-TAG')
  @ContentHelp('A single line characterising the phase output, e.g. '
      '"Working code + unit tests".')
  String? tagline;

  /// The phase purpose (a short prose paragraph).
  @SectionId('IMPL-PUR')
  @ContentHelp('The purpose of the Implementation phase: incremental '
      'verification and why dependency analysis fixes the build order.')
  String? purpose;

  /// What must exist before the phase begins.
  @SectionId('IMPL-INP-LST')
  @SectionIdPattern('IMPL-INP-xxx')
  List<ImplementationInput> inputs = [];

  /// What the phase produces.
  @SectionId('IMPL-PRD-LST')
  @SectionIdPattern('IMPL-PRD-xxx')
  List<ImplementationProduct> produces = [];

  /// The implementation levels, in dependency order.
  @SectionId('IMPL-LVL-LST')
  @SectionIdPattern('IMPL-LVL-xxx')
  List<ImplementationLevel> levels = [];

  /// What must be true before proceeding (the quality gate).
  @SectionId('IMPL-EXT-LST')
  @SectionIdPattern('IMPL-EXT-xxx')
  List<ImplementationExitCriterion> exitCriteria = [];

  /// A note on the phase's current editor status and phase-2 direction.
  @SectionId('IMPL-PH2')
  @ContentHelp('Notes on the phase-2 direction for this phase — e.g. the UI '
      'levels implemented against `tom_flutter_ui` components.')
  String? phase2Note;
}

/// A single Implementation input — a precondition that must exist before the
/// phase begins.
@SectionId('IMPL-INP')
class ImplementationInput {
  @ContentHelp('One required input, e.g. CodeSpec elements (Phase 4), derived '
      'tests (Phase 5), or the dependency analysis.')
  String? content;
}

/// A single Implementation output — an artifact the phase produces.
@SectionId('IMPL-PRD')
class ImplementationProduct {
  @ContentHelp('One artifact the Implementation phase produces, e.g. working '
      'code filling the skeleton or passing unit tests.')
  String? content;
}

/// A single implementation level — a dependency-ordered unit of work.
@SectionId('IMPL-LVL')
class ImplementationLevel {
  @Form([
    Field('name', String,
        'Name — the level title, e.g. "Level 1 · Database Schema"',
        required: true),
    Field('description', String,
        'Description — what the level covers and what it depends on',
        required: true),
  ])
  String? content;
}

/// A single Implementation exit criterion — part of the phase quality gate.
@SectionId('IMPL-EXT')
class ImplementationExitCriterion {
  @ContentHelp('One condition that must hold before the phase is complete, '
      'e.g. "All Phase 5 derived tests pass".')
  String? content;
}
