/// SBP.6 — Assumptions, Constraints & Dependencies.
///
/// Consolidates into one register what is otherwise scattered across the
/// introduction (risks/assumptions), interface boundary assumptions, and
/// framework conditions. Closes the prior-review completeness gap (§5:
/// "Assumptions/constraints register").
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// SBP.6 Assumptions, Constraints & Dependencies.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — assumptions and constraints'],
  'The single register of assumptions the solution relies on, constraints it '
  'must operate within, and external dependencies.',
)
@SectionId('ACDP')
class AssumptionsConstraintsDependencies extends DocSpecsSection {
  @ContentType('description', 'Summarize the key assumptions the solution '
      'relies on and the constraints it must operate within.')
  @override
  @SerializationOrder(0)
  String? content;

  /// The consolidated assumption / constraint register.
  @SerializationOrder(1)
  AssumptionConstraintDependencyRegister register = AssumptionConstraintDependencyRegister();
}

/// A consolidated register of assumptions and constraints.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — assumptions and constraints'],
  'The consolidated register of assumptions, constraints, and dependencies.',
)
@SectionId('ACRG')
class AssumptionConstraintDependencyRegister extends DocSpecsSection {
  @Unused()
  @override
  @SerializationOrder(0)
  String? content;

  /// Assumptions the solution depends on being true.
  @SectionId('ACRG-ASMP-LST')
  @SectionIdPattern('ACRG-ASMP-xxx')
  @ContentHelp('Add one entry per assumption (ASM-NNN).')
  @SerializationOrder(1)
  List<AssumptionRegisterEntry> assumptions = [];

  /// Constraints the solution must operate within.
  @SectionId('ACRG-CONS-LST')
  @SectionIdPattern('ACRG-CONS-xxx')
  @ContentHelp('Add one entry per constraint (CON-NNN).')
  @SerializationOrder(2)
  List<ConstraintRegisterEntry> constraints = [];

  /// Dependencies the solution relies on (external systems, teams, vendors,
  /// prerequisite deliverables, framework conditions).
  @SectionId('ACRG-DEPS-LST')
  @SectionIdPattern('ACRG-DEPS-xxx')
  @ContentHelp('Add one entry per dependency (DEP-NNN).')
  @SerializationOrder(3)
  List<DependencyRegisterEntry> dependencies = [];
}

/// A single assumption register entry (form).
///
/// Named `AssumptionRegisterEntry` to avoid collision with the pre-existing
/// `AssumptionEntry` in `introduction_and_scope.dart` (D-IP6 deviation).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — assumptions and constraints'],
  'A single assumption the solution depends on, with its impact and validation '
  'approach.',
)
@SectionId('ASMRE')
class AssumptionRegisterEntry extends DocSpecsSection {
  @Form([
    Field('assumptionId', String, 'Assumption ID (ASM-NNN)', required: true),
    Field('description', String, 'Description', required: true),
    Field('impact', String, 'Impact if invalid'),
    Field('validation', String, 'Validation approach'),
    Field('status', String, 'Status (Open, Confirmed, Invalidated)'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single constraint register entry (form).
///
/// Named `ConstraintRegisterEntry` to avoid collision with the pre-existing
/// `ConstraintEntry` in `introduction_and_scope.dart` (D-IP6 deviation).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — assumptions and constraints'],
  'A single constraint the solution must operate within, with its type and '
  'source.',
)
@SectionId('CONRE')
class ConstraintRegisterEntry extends DocSpecsSection {
  @Form([
    Field('constraintId', String, 'Constraint ID (CON-NNN)', required: true),
    Field('description', String, 'Description', required: true),
    Field('type', String, 'Type (Technical, Regulatory, Budget, Schedule)'),
    Field('source', String, 'Source'),
    Field('impact', String, 'Impact on the solution'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single dependency register entry (form).
///
/// Captures an external dependency the solution relies on — another system, a
/// team, a vendor, a prerequisite deliverable, or a framework condition — so the
/// dependency content otherwise scattered across SBP.2 / framework conditions
/// has a canonical home in SBP.6 (the prerequisite destination for the L34C-4
/// dependency re-home).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — assumptions and constraints'],
  'A single external dependency the solution relies on, with its type and '
  'criticality.',
)
@SectionId('DEPRE')
class DependencyRegisterEntry extends DocSpecsSection {
  @Form([
    Field('dependencyId', String, 'Dependency ID (DEP-NNN)', required: true),
    Field('description', String, 'Description', required: true),
    Field('type', String, 'Type (System, Team, Vendor, Deliverable, Framework)'),
    Field('dependsOn', String, 'Depends on (the external party / artifact)'),
    Field('criticality', String, 'Criticality (Low, Medium, High, Blocking)'),
    Field('status', String, 'Status (Open, Confirmed, Resolved, At risk)'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
