/// The TomSpecs process checks: what a project runs on its specification at a
/// gate, as library functions over the document's text, with the project's
/// own data passed in (read from `<spec-root>/checks/`).
///
/// - three-tier validation and the markdown rendition ([SpecRootDefinition]);
/// - the answer import from the rendition into the YAML ([AnswerImporter]);
/// - the Solution Blueprint's gate checks: required fields
///   ([checkRequiredFields]), the question register ([checkQuestionRegister]),
///   the feature register ([checkFeatureRegister]), the Project Idea's
///   coverage ([measureProjectIdeaCoverage]), the authorization cross-check
///   ([crossCheckAuthorization]) and the model coverage ([measureCoverage]);
/// - accepting a document's change marks in place ([acceptMarksInPlace]);
/// - the layout-keeping YAML value rewrite they share ([locateValues],
///   [rewriteValues]).
///
/// A separate library from `tom_som_dart_runtime.dart`, which a document
/// reader needs without these checks: import both where both are used.
/// `tom_specs_clitool`'s `spec_checks` command is the CLI over them, and the
/// VS Code extension's tools call that command.
library;

export 'src/spec_checks/authorization_cross_check.dart'
    show
        Access,
        CrossCheckReport,
        Operation,
        RoleModel,
        Screen,
        Step,
        UseCase,
        crossCheckAuthorization;
export 'src/spec_checks/coverage_measurement.dart'
    show CoverageReport, UnfilledSection, measureCoverage;
export 'src/spec_checks/feature_register_check.dart'
    show FeatureRegisterFinding, FeatureRegisterReport, checkFeatureRegister;
export 'src/spec_checks/marks_in_place.dart'
    show MarksInPlaceResult, MarksSectionNotFound, acceptMarksInPlace;
export 'src/spec_checks/project_idea_coverage.dart'
    show
        CoverageClass,
        CoverageEntry,
        CoverageExclusion,
        ProjectIdea,
        ProjectIdeaCoverageReport,
        ProjectIdeaItem,
        citations,
        measureProjectIdeaCoverage,
        parseExclusions,
        parseProjectIdea,
        requirementSources;
export 'src/spec_checks/question_register_check.dart'
    show
        IndexRow,
        QuestionBlock,
        QuestionRegisterConfig,
        QuestionRegisterGroup,
        QuestionRegisterStatus,
        RegisterReport,
        checkQuestionRegister;
export 'src/spec_checks/required_fields_check.dart'
    show RequiredFieldsReport, checkRequiredFields;
export 'src/spec_checks/sbp_answers.dart' show withAnswer;
export 'src/spec_checks/sbp_answer_import.dart'
    show
        AnswerImporter,
        ImportPlan,
        ImportVerificationException,
        ImportedAnswer,
        ImportedValue;
export 'src/spec_checks/sbp_validation.dart'
    show SbpRenderException, SbpValidation, SpecRootDefinition;
export 'src/spec_checks/sbp_yaml_locator.dart'
    show ValueLocation, ValueRole, locateValues;
export 'src/spec_checks/sbp_yaml_writer.dart'
    show ValueEdit, YamlRewriteException, rewriteValues;
