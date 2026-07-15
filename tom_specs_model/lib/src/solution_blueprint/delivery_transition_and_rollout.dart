/// SBP.15 — Delivery, Transition & Rollout.
///
/// Consolidates the staged delivery plan (from [SystemStagePlan]) with the
/// rollout and transition concept (from [SystemRollout]). Seeds the
/// Delivery Roadmap (DRM) and Transition & Rollout Plan (TRP) documents.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';
import 'delivery_roadmap.dart';
import 'experience_and_interface_design.dart'
    show LocalizationProcess, TranslationProcess;
import 'transition_and_rollout_plan.dart';

/// SBP.15 Delivery, Transition & Rollout.
@StandardReferences(
  [
    'PMBOK — phased delivery',
    'ISO/IEC/IEEE 29148:2018 — transition requirements',
  ],
  'How the solution is delivered, transitioned into operation, and rolled out '
  'in stages.',
)
@SectionId('DTRO')
class DeliveryTransitionAndRollout {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// Staged delivery / phase plan.
  @SerializationOrder(1)
  SystemStagePlan systemStagePlan = SystemStagePlan();

  /// Rollout and transition concept.
  @SerializationOrder(2)
  SystemRollout systemRollout = SystemRollout();

  /// Localization & translation *execution* processes (re-homed from MLAR in
  /// IP-6: the execution side of i18n, as opposed to the requirements that
  /// live in SBP.9).
  @SerializationOrder(3)
  LocalizationTranslationProcess localizationTranslationProcess =
      LocalizationTranslationProcess();

  /// Multi-language rollout sequencing by region and time (re-homed from MLAR).
  @SectionId('LOCRP')
  @StandardReferences(
    [
      'ISO 3166 — country and region codes define the geographic rollout order',
      'ISO 8601 — the standard representation for the rollout timeline and schedule',
    ],
    'The rollout strategy, timeline, and regional sequencing for locale availability.',
  )
  @MapsTo(D12TransitionRolloutPlan)
  @DetailedIn(D12TransitionRolloutPlan)
  @SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-RLP')
  @Form([
    Field(
      'rolloutStrategy',
      String,
      'Rollout Strategy',
      hint: 'Big bang, phased, pilot',
    ),
    Field(
      'rolloutTimeline',
      String,
      'Rollout Timeline',
      hint: 'High-level rollout schedule',
    ),
    Field(
      'rolloutRegions',
      String,
      'Rollout Regions',
      hint: 'Geographic rollout order',
    ),
  ])
  @SerializationOrder(4)
  String? localeRolloutPlan;
}

/// Localization & Translation execution processes.
///
/// Bundles the localization and translation *workflow* concerns re-homed from
/// the former `MultiLanguageSupport` cluster (their requirement counterparts
/// live in SBP.9 [LocalizationTranslationRequirements]).
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 — transition requirements'],
  'The execution-side localization and translation workflows that put the '
  'internationalization requirements into practice.',
)
@SectionId('LCTP')
class LocalizationTranslationProcess {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// Localization workflow (content identification, externalization, review).
  @SerializationOrder(1)
  LocalizationProcess localizationProcess = LocalizationProcess();

  /// Translation workflow (TMS, translation memory, vendors, QA).
  @SerializationOrder(2)
  TranslationProcess translationProcess = TranslationProcess();
}
