/// SBP.9 — Requirements.
///
/// Home for the framework-uncovered non-functional requirement sub-areas, cut
/// **by concern**: the requirement-side concerns live here, the
/// execution-side ones in TRP (below).
///
///  * Localization & Translation → [LocalizationTranslationRequirements]
///  * Information for Use         → [InformationForUseRequirements]
///  * Training & Enablement       → [TrainingEnablementRequirements]
///
/// The execution-side concerns (localization/translation *processes*, rollout
/// sequencing) re-home to SBP.15 (Delivery, Transition & Rollout) instead.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'experience_and_interface_design.dart'
    show
        UserDocumentationRequirements,
        TrainingDeliverableRequirements,
        LocaleHandlingRequirements,
        TranslationRequirements;

/// SBP.9 Requirements.
///
/// Functional requirements seed the Requirements Specification (RSP); this
/// section is the CodeSpecs **seed** subtree — its functional requirements plus
/// the validation/error NFRs drive CE-VA / CE-ER but are consumed *as
/// requirements*, not generated. Functional-requirement modelling is expanded
/// in a later IP step.
///
/// The framework-uncovered NFR follow-up sub-areas (localization,
/// information-for-use, training) are grouped out of the seed subtree into
/// [RequirementsFollowUp] (`codespecs_mapping.md` §8.3) so the seed
/// stays purely CodeSpecs-relevant.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148:2018 — SRS / SyRS',
    'ISO/IEC 25010:2023 — portability',
    'ISO/IEC/IEEE 26511/26514/26515 — information for use',
  ],
  'The functional and non-functional requirements of the system; the CodeSpecs '
  'seed subtree. Framework-uncovered follow-up NFR sub-areas (localization, '
  'information-for-use, training) are grouped under the follow-up subtree.',
)
@SectionId('REQS')
@NoArtifact(
  NoArtifactReason.container,
  note:
      'chapter node over the requirements follow-up subtree',
)
class Requirements extends DocSpecsSection {
  @ContentType('description', 'Summarize the functional and non-functional '
      'requirement landscape; seeds the Requirements Specification (RSP).')
  @override
  @SerializationOrder(0)
  String? content;

  /// Follow-up (non-generated) NFR sub-areas grouped out of the seed subtree.
  @SerializationOrder(1)
  RequirementsFollowUp requirementsFollowUp = RequirementsFollowUp();
}

/// SBP.9 Requirements — follow-up NFR sub-areas.
///
/// Groups the framework-uncovered non-functional requirement sub-areas that are
/// **follow-up** concerns (documentation, training, localization) rather than
/// CodeSpecs-generated behaviour. The root carries no `@CodeSpecKind`, so it is
/// not a generation projection root and nothing under it is reachable from
/// `D13CodeSpecsProjection` (`codespecs_mapping.md` §8.3), keeping the parent
/// [Requirements] seed subtree purely CodeSpecs-relevant. The translation and
/// locale-handling requirements *inside* it are nonetheless tagged CE-TX,
/// recording which part their material belongs to; that material reaches
/// generation through the shared `MessageKeyRegistry`, never through this
/// subtree (`codespecs_mapping.md` §4.3). The sub-areas:
///
///  * Localization & Translation → [LocalizationTranslationRequirements] (L10N)
///  * Information for Use         → [InformationForUseRequirements] (DOC)
///  * Training & Enablement       → [TrainingEnablementRequirements] (TRN)
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — portability',
    'ISO/IEC/IEEE 26511/26514/26515 — information for use',
  ],
  'The framework-uncovered follow-up NFR sub-areas — localization, '
  'information-for-use, and training — grouped out of the CodeSpecs seed '
  'subtree as non-generated requirements.',
)
@FollowUpKind([FollowUpProcess.l10n, FollowUpProcess.doc, FollowUpProcess.trn])
@SectionId('REQFU')
class RequirementsFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the follow-up (non-generated) NFR '
      'sub-areas: localization, information-for-use, and training.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Localization & Translation requirements (NFR-L10N-NNN).
  @SerializationOrder(1)
  LocalizationTranslationRequirements localizationTranslation =
      LocalizationTranslationRequirements();

  /// Information-for-Use (user documentation) requirements (NFR-DOC-NNN).
  @SerializationOrder(2)
  InformationForUseRequirements informationForUse =
      InformationForUseRequirements();

  /// Training & Enablement requirements (NFR-TRN-NNN).
  @SerializationOrder(3)
  TrainingEnablementRequirements trainingEnablement =
      TrainingEnablementRequirements();
}

/// Localization & Translation requirements (the requirement side of i18n).
///
/// Cross-mapped from SBP.14 via `Iso25010Coverage`.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — portability / adaptability',
    'ISO/IEC/IEEE 29148:2018 — internationalization constraints',
  ],
  'The requirement side of internationalization: supported locales, '
  'formatting, RTL, pluralization, and translation needs.',
)
@SectionId('LCTR')
class LocalizationTranslationRequirements extends DocSpecsSection {
  @ContentType('description', 'Localization and translation requirements: '
      'supported locales, i18n framework, formatting, RTL, pluralization.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Technical internationalization requirements (re-homed from MLAR).
  @SerializationOrder(1)
  TranslationRequirements translationRequirements = TranslationRequirements();

  /// Locale modeling and fallback requirements (re-homed from MLAR).
  @SerializationOrder(2)
  LocaleHandlingRequirements localeHandling =
      LocaleHandlingRequirements();
}

/// Information-for-Use (user documentation) requirements.
///
/// The documentation *quality criteria* cross-map lives in SBP.14
/// (`DocumentationQualityCriteria`).
///
/// Holds the documentation half of the former `DocumentationAndTraining`,
/// split out in L34C-7 ([UserDocumentationRequirements]). The training half
/// re-homed to [TrainingEnablementRequirements].
@StandardReferences(
  [
    'ISO/IEC/IEEE 26511 — managing information for users',
    'ISO/IEC/IEEE 26514 — designing and developing user documentation',
    'ISO/IEC/IEEE 26515 — developing user documentation in an agile environment',
  ],
  'The requirements for user-facing documentation: deliverables, formats, '
  'platforms, versioning, and documentation localization.',
)
@SectionId('IFUR')
class InformationForUseRequirements extends DocSpecsSection {
  @ContentType('description', 'User documentation requirements: deliverables, '
      'formats, platforms, versioning, and documentation localization.')
  @override
  @SerializationOrder(0)
  String? content;

  /// User documentation requirements (doc half of the former DOANTR).
  @SerializationOrder(1)
  UserDocumentationRequirements userDocumentation =
      UserDocumentationRequirements();
}

/// Training & Enablement requirements.
///
/// The training-materials *delivery* and rollout sequencing re-home to SBP.15.
/// The detailed training-material content and module catalogue is the training
/// half of the former `DocumentationAndTraining`, split out in L34C-7 and
/// re-homed here as [TrainingDeliverableRequirements].
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148:2018 — transition requirements',
    'PMBOK — transition / enablement',
  ],
  'The requirements for training and enabling users to adopt the solution.',
)
@SectionId('TREQ')
class TrainingEnablementRequirements extends DocSpecsSection {
  /// Training & enablement requirement form.
  @Form([
    Field('targetAudiences', String, 'Target Audiences',
        hint: 'End users, admins, power users, support'),
    Field('competencyOutcomes', String, 'Competency Outcomes',
        hint: 'What learners must be able to do'),
    Field('certificationRequired', bool, 'Certification Required'),
    Field('ongoingEnablement', String, 'Ongoing Enablement',
        hint: 'Refresher and continuous-enablement expectations'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Training deliverable requirements (training half of the former DOANTR).
  @SerializationOrder(1)
  TrainingDeliverableRequirements trainingDeliverables =
      TrainingDeliverableRequirements();
}
