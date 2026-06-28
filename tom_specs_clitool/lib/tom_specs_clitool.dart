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
export 'src/som_dart_emitter.dart' show SomDartEmitter;
export 'src/som_python_emitter.dart' show SomPythonEmitter;
export 'src/som_java_emitter.dart' show SomJavaEmitter;
export 'src/som_javascript_emitter.dart' show SomJavaScriptEmitter;
export 'src/som_typescript_emitter.dart' show SomTypeScriptEmitter;
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
export 'src/spec_ops_generator.dart' show SpecOpsGenerator;
export 'src/docspecs_schema_generator.dart' show DocSpecsSchemaGenerator;
export 'src/outline_writer.dart' show OutlineWriter;
export 'src/validator.dart' show validateModel, validateStructuralInvariants;
export 'src/summary_package_config.dart'
    show readPackageRoots, mergePackageRootsForDirs, SummaryConfigException;
