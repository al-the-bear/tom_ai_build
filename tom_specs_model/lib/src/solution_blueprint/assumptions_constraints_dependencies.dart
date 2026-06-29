/// SBP.6 — Assumptions, Constraints & Dependencies.
///
/// Consolidates into one register what is otherwise scattered across the
/// introduction (risks/assumptions), interface boundary assumptions, and
/// framework conditions. Closes the prior-review completeness gap (§5:
/// "Assumptions/constraints register").
///
/// Public anchor: ISO/IEC/IEEE 29148 assumptions & constraints.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// SBP.6 Assumptions, Constraints & Dependencies.
@SectionId('ACDP')
class AssumptionsConstraintsDependencies {
  @ContentType('description', 'Summarize the key assumptions the solution '
      'relies on and the constraints it must operate within.')
  String? content;

  /// The consolidated assumption / constraint register.
  AssumptionConstraintRegister register = AssumptionConstraintRegister();
}

/// A consolidated register of assumptions and constraints.
@SectionId('ACRG')
class AssumptionConstraintRegister {
  @Unused()
  String? content;

  /// Assumptions the solution depends on being true.
  @SectionId('ACRG-ASMP-LST')
  @SectionIdPattern('ACRG-ASMP-xxx')
  @ContentHelp('Add one entry per assumption (ASM-NNN).')
  List<AssumptionRegisterEntry> assumptions = [];

  /// Constraints the solution must operate within.
  @SectionId('ACRG-CONS-LST')
  @SectionIdPattern('ACRG-CONS-xxx')
  @ContentHelp('Add one entry per constraint (CON-NNN).')
  List<ConstraintRegisterEntry> constraints = [];
}

/// A single assumption register entry (form).
///
/// Named `AssumptionRegisterEntry` to avoid collision with the pre-existing
/// `AssumptionEntry` in `introduction_and_scope.dart` (D-IP6 deviation).
@SectionId('ASMRE')
class AssumptionRegisterEntry {
  @Form([
    Field('assumptionId', String, 'Assumption ID (ASM-NNN)', required: true),
    Field('description', String, 'Description', required: true),
    Field('impact', String, 'Impact if invalid'),
    Field('validation', String, 'Validation approach'),
    Field('status', String, 'Status (Open, Confirmed, Invalidated)'),
  ])
  String? content;
}

/// A single constraint register entry (form).
///
/// Named `ConstraintRegisterEntry` to avoid collision with the pre-existing
/// `ConstraintEntry` in `introduction_and_scope.dart` (D-IP6 deviation).
@SectionId('CONRE')
class ConstraintRegisterEntry {
  @Form([
    Field('constraintId', String, 'Constraint ID (CON-NNN)', required: true),
    Field('description', String, 'Description', required: true),
    Field('type', String, 'Type (Technical, Regulatory, Budget, Schedule)'),
    Field('source', String, 'Source'),
    Field('impact', String, 'Impact on the solution'),
  ])
  String? content;
}
