/// TomSpecs CLI Tool — model outline generator.
library;

export 'src/analyzer_bootstrap.dart' show createAnalysisDriver;
export 'src/model_reader.dart'
    show
        ModelReader,
        ModelClass,
        ModelField,
        ModelEnum,
        AnnotationData,
        FormFieldInfo,
        findContainerRoot;
export 'src/model_json_exporter.dart' show ModelJsonExporter;
// The single source of the model version stamp, and the target/stamp pairing
// that keeps the two committed spec_model.json assets from being re-exported at
// each other's version.
export 'src/model_version_stamp.dart'
    show
        ModelVersionStamp,
        ModelVersionStampException,
        modelVersionStampPath,
        readModelVersionStamp;
export 'src/model_json_target.dart'
    show
        ModelJsonStamp,
        ModelJsonTarget,
        modelMajorOfLabel,
        targetForOutputPath;
// The freshness gate over the committed tom_som_*_v0 packages: fingerprints the
// model the generator reads, so a model edit without a regeneration fails a test
// rather than shipping. See _copilot_guidelines/som_regeneration.md.
export 'src/model_freshness.dart'
    show
        ModelSurface,
        LibrarySurface,
        modelSurfaceStampPath,
        fingerprintSources,
        computeModelSurface,
        readModelSurfaceStamp,
        writeModelSurfaceStamp,
        configuredPackageNames,
        somPackageCoverageMismatch;
// The doc-folder gate over inline quest-todo citations: a cited id that has
// been completed, archived, or never existed fails the check, so a document
// cannot go on pointing a reader at closed work.
export 'src/todo_citations.dart'
    show
        defaultCitedQuests,
        todoIdShape,
        TodoRecord,
        TodoCorpus,
        TodoCitation,
        TodoCitationReport,
        TodoCitationVocabulary,
        CitationVerdict,
        CitationExemption,
        classifyMarkdown,
        checkDocFolder;
export 'src/meta_tree.dart'
    show
        MetaTreeBuilder,
        MetaNode,
        MetaNodeKind,
        MetaContentType,
        MetaFormField,
        MetaFormInfo,
        MetaDocumentInfo,
        MetaExtraAnnotation;
export 'src/spec_model_meta_validator.dart'
    show
        validateSpecModelMeta,
        specModelMetaSchemaVersion,
        requiredSpecModelMetaKeys;
export 'src/spec_object_model_config.dart'
    show
        SpecObjectModelConfig,
        SpecObjectModelConfigException,
        SomLanguage,
        SomLanguageTarget;
export 'src/som_structural_accessors.dart'
    show
        SomStructuralMember,
        somStructuralAccessorNames,
        somReservedAccessorNames;
export 'src/som_dart_emitter.dart' show SomDartEmitter;
export 'src/som_dart_meta_emitter.dart' show SomDartMetaEmitter;
export 'src/som_python_emitter.dart' show SomPythonEmitter;
export 'src/som_python_meta_emitter.dart' show SomPythonMetaEmitter;
export 'src/som_java_emitter.dart' show SomJavaEmitter;
export 'src/som_java_meta_emitter.dart' show SomJavaMetaEmitter;
export 'src/som_javascript_emitter.dart' show SomJavaScriptEmitter;
export 'src/som_javascript_meta_emitter.dart' show SomJavaScriptMetaEmitter;
export 'src/som_typescript_emitter.dart' show SomTypeScriptEmitter;
export 'src/som_typescript_meta_emitter.dart' show SomTypeScriptMetaEmitter;
export 'src/som_go_emitter.dart' show SomGoEmitter;
export 'src/som_go_meta_emitter.dart' show SomGoMetaEmitter;
export 'src/som_rust_emitter.dart' show SomRustEmitter;
export 'src/som_rust_meta_emitter.dart' show SomRustMetaEmitter;
export 'src/som_c_emitter.dart' show SomCEmitter;
export 'src/som_c_meta_emitter.dart' show SomCMetaEmitter;
export 'src/som_cpp_emitter.dart' show SomCppEmitter;
export 'src/som_cpp_meta_emitter.dart' show SomCppMetaEmitter;
export 'src/som_generator.dart'
    show generateSomDartProject, writeSomDartProject, SomGenerationResult;
export 'src/som_python_generator.dart'
    show
        generateSomPythonProject,
        writeSomPythonProject,
        SomPythonGenerationResult;
export 'src/som_java_generator.dart'
    show
        generateSomJavaProject,
        writeSomJavaProject,
        SomJavaGenerationResult;
export 'src/som_javascript_generator.dart'
    show
        generateSomJavaScriptProject,
        writeSomJavaScriptProject,
        SomJavaScriptGenerationResult;
export 'src/som_typescript_generator.dart'
    show
        generateSomTypeScriptProject,
        writeSomTypeScriptProject,
        SomTypeScriptGenerationResult;
export 'src/som_go_generator.dart'
    show generateSomGoProject, writeSomGoProject, SomGoGenerationResult;
export 'src/som_rust_generator.dart'
    show generateSomRustProject, writeSomRustProject, SomRustGenerationResult;
export 'src/som_c_generator.dart'
    show generateSomCProject, writeSomCProject, SomCGenerationResult;
export 'src/som_cpp_generator.dart'
    show generateSomCppProject, writeSomCppProject, SomCppGenerationResult;
export 'src/spec_ops_generator.dart' show SpecOpsGenerator;
export 'src/docspecs_schema_generator.dart' show DocSpecsSchemaGenerator;
export 'src/docspecs_yaml_schema_generator.dart'
    show DocspecsYamlSchemaGenerator;
export 'src/outline_writer.dart' show OutlineWriter;
export 'src/serialization_order.dart'
    show
        stampSerializationOrder,
        SerializationStampResult,
        collectModelSourceFiles,
        unstampedMembers,
        findUnstampedModelMembers;
export 'src/validator.dart'
    show
        validateModel,
        validateStructuralInvariants,
        sectionIdCoverageGaps,
        unreachableClasses;
// The both-directions gate between §10.2's numbered invariant list and the
// validator's checks: neither side can grow an entry the other does not know
// about. See tom_specs_model_rules.md §10.2.
export 'src/invariant_correspondence.dart'
    show
        InvariantTag,
        InvariantEntry,
        InvariantCorrespondence,
        parseInvariantTags,
        parseInvariantEntries,
        compareInvariants,
        checkInvariantCorrespondence;
// The codespecs_derivation_contract.md §6 validation pass over an emitted
// CodeSpecs trio.
export 'src/codespecs/cs_model.dart';
export 'src/codespecs/cs_reader.dart'
    show readCsLocusProject, readCsLocusProjectFromDirectory, readEnumValues;
export 'src/codespecs/cs_checks.dart'
    show
        CodeSpecsCheck,
        CodeSpecsViolation,
        codeSpecsChecks,
        csMirroredEnumPairs,
        applyMigrations;
export 'src/codespecs/codespecs_validator.dart'
    show
        CodeSpecsValidationReport,
        CodeSpecsValidationException,
        runCodeSpecsChecks,
        assertCodeSpecsValid,
        readCsEnumMirrors;
export 'src/packaging.dart'
    show
        ManifestFormat,
        PackagingDescriptor,
        PackagingRoute,
        packageVersionFromModel,
        packagingDescriptorFor,
        renderFacadeReadme,
        renderHowToIntegrate,
        renderChangelog,
        licenseText,
        rewriteManifestVersion,
        ensureGitignoreContent,
        writeFacadePackaging,
        alignRuntimeManifestVersion;
// Summary package-config helpers now live in tom_analyzer_shared (the base-first
// home for analyzer-summary infrastructure). Re-exported here so existing
// consumers (and tests) keep the same import surface.
export 'package:tom_analyzer_shared/tom_analyzer_shared.dart'
    show readPackageRoots, mergePackageRootsForDirs, SummaryConfigException;
