/// SBP.15 — Delivery, Transition & Rollout.
///
/// Consolidates the staged delivery plan (from [SystemStagePlan]) with the
/// rollout and transition concept (from [SystemRollout]). Seeds the
/// Delivery Roadmap (DRM) and Transition & Rollout Plan (TRP) documents.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'experience_and_interface_design.dart'
    show LocalizationProcess, LocaleRolloutPlan, TranslationProcess;
import 'system_rollout.dart';
import 'system_stage_plan.dart';

/// SBP.15 Delivery, Transition & Rollout.
///
/// Public anchor: PMBOK phasing + ISO 29148 transition requirements.
@SectionId('DTRO')
class DeliveryTransitionAndRollout {
  @Unused()
  String? content;

  /// Staged delivery / phase plan.
  SystemStagePlan systemStagePlan = SystemStagePlan();

  /// Rollout and transition concept.
  SystemRollout systemRollout = SystemRollout();

  /// Localization & translation *execution* processes (re-homed from MLAR in
  /// IP-6: the execution side of i18n, as opposed to the requirements that
  /// live in SBP.9).
  LocalizationTranslationProcess localizationTranslationProcess =
      LocalizationTranslationProcess();

  /// Multi-language rollout sequencing by region and time (re-homed from MLAR).
  LocaleRolloutPlan localeRolloutPlan =
      LocaleRolloutPlan();
}

/// Localization & Translation execution processes.
///
/// Public anchor: ISO 29148 transition requirements. Bundles the localization
/// and translation *workflow* concerns re-homed from the former
/// `MultiLanguageSupport` cluster (their requirement counterparts live in
/// SBP.9 [LocalizationTranslationRequirements]).
@SectionId('LCTP')
class LocalizationTranslationProcess {
  @Unused()
  String? content;

  /// Localization workflow (content identification, externalization, review).
  LocalizationProcess localizationProcess = LocalizationProcess();

  /// Translation workflow (TMS, translation memory, vendors, QA).
  TranslationProcess translationProcess = TranslationProcess();
}
