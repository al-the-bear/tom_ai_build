// D4rt Bridge - Generated file, do not edit
// Sources: 10 files
// Generated: 2026-06-24T15:53:12.085378

// ignore_for_file: unused_import, deprecated_member_use, prefer_function_declarations_over_variables, implementation_imports, sort_child_properties_last, non_constant_identifier_names, avoid_function_literals_in_foreach_calls, invalid_use_of_protected_member, unnecessary_non_null_assertion, invalid_use_of_visible_for_testing_member, unnecessary_cast, unused_local_variable, no_leading_underscores_for_local_identifiers, prefer_is_empty, unnecessary_question_mark, unreachable_switch_case, unintended_html_in_doc_comment, empty_constructor_bodies, prefer_const_constructors_in_immutables, prefer_final_fields, unused_field, must_call_super, no_logic_in_create_state, use_key_in_widget_constructors, annotate_overrides, non_const_argument_for_const_parameter, unnecessary_import

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/tom_d4rt.dart';

import 'package:tom_som_dart_runtime/src/som_facade.dart' as $tom_som_dart_runtime_1;
import 'package:tom_som_dart_runtime/src/spec_document.dart' as $tom_som_dart_runtime_2;
import 'package:tom_som_dart_runtime/src/spec_document_markdown.dart' as $tom_som_dart_runtime_3;
import 'package:tom_som_dart_runtime/src/spec_document_yaml.dart' as $tom_som_dart_runtime_4;
import 'package:tom_som_dart_runtime/src/spec_model.dart' as $tom_som_dart_runtime_5;
import 'package:tom_som_dart_runtime/src/spec_node_creation.dart' as $tom_som_dart_runtime_6;
import 'package:tom_som_dart_runtime/src/spec_paths.dart' as $tom_som_dart_runtime_7;
import 'package:tom_som_dart_runtime/src/spec_query.dart' as $tom_som_dart_runtime_8;
import 'package:tom_som_dart_runtime/src/spec_reflection.dart' as $tom_som_dart_runtime_9;
import 'package:tom_som_dart_runtime/src/spec_validator.dart' as $tom_som_dart_runtime_10;

/// Bridge class for som_runtime module.
class SomRuntimeBridge {
  /// Returns all bridge class definitions.
  ///
  /// Eager — building every class. Prefer [bridgeClassThunks] +
  /// [bridgeClassTypes] for lazy registration (Step #17); this remains
  /// for diagnostics and callers that need the full list.
  static List<BridgedClass> bridgeClasses() {
    return [
      _createSomNodeBridge(),
      _createSomScalarBridge(),
      _createSomListBridge(),
      _createSomVersionExceptionBridge(),
      _createSpecDocumentBridge(),
      _createSpecDocumentStateBridge(),
      _createSpecMarkdownRejectionBridge(),
      _createSpecMarkdownResultBridge(),
      _createSpecDocumentMarkdownBridge(),
      _createSpecYamlContentsBridge(),
      _createSpecDocumentYamlBridge(),
      _createSpecAnnotationBridge(),
      _createFormFieldSpecBridge(),
      _createSpecFieldBridge(),
      _createSpecClassBridge(),
      _createSpecRootBridge(),
      _createSpecModelBridge(),
      _createSpecCreationErrorBridge(),
      _createSpecNodeCreatorBridge(),
      _createSpecMatchSpanBridge(),
      _createSpecQueryMatchBridge(),
      _createSpecQueryBridge(),
      _createSpecQueryEngineBridge(),
      _createSpecQueryCursorBridge(),
      _createSpecResolutionBridge(),
      _createSpecReflectionBridge(),
      _createSpecValidationErrorBridge(),
    ];
  }

  /// Returns deferred factory thunks keyed by class name.
  ///
  /// Each thunk builds one class's [BridgedClass] on demand. Plugs into
  /// the interpreter's lazy registry via [registerBridges] (Step #17).
  static Map<String, BridgedClass Function()> bridgeClassThunks() {
    return {
      'SomNode': _createSomNodeBridge,
      'SomScalar': _createSomScalarBridge,
      'SomList': _createSomListBridge,
      'SomVersionException': _createSomVersionExceptionBridge,
      'SpecDocument': _createSpecDocumentBridge,
      'SpecDocumentState': _createSpecDocumentStateBridge,
      'SpecMarkdownRejection': _createSpecMarkdownRejectionBridge,
      'SpecMarkdownResult': _createSpecMarkdownResultBridge,
      'SpecDocumentMarkdown': _createSpecDocumentMarkdownBridge,
      'SpecYamlContents': _createSpecYamlContentsBridge,
      'SpecDocumentYaml': _createSpecDocumentYamlBridge,
      'SpecAnnotation': _createSpecAnnotationBridge,
      'FormFieldSpec': _createFormFieldSpecBridge,
      'SpecField': _createSpecFieldBridge,
      'SpecClass': _createSpecClassBridge,
      'SpecRoot': _createSpecRootBridge,
      'SpecModel': _createSpecModelBridge,
      'SpecCreationError': _createSpecCreationErrorBridge,
      'SpecNodeCreator': _createSpecNodeCreatorBridge,
      'SpecMatchSpan': _createSpecMatchSpanBridge,
      'SpecQueryMatch': _createSpecQueryMatchBridge,
      'SpecQuery': _createSpecQueryBridge,
      'SpecQueryEngine': _createSpecQueryEngineBridge,
      'SpecQueryCursor': _createSpecQueryCursorBridge,
      'SpecResolution': _createSpecResolutionBridge,
      'SpecReflection': _createSpecReflectionBridge,
      'SpecValidationError': _createSpecValidationErrorBridge,
    };
  }

  /// Returns native [Type]s keyed by class name, parallel to
  /// [bridgeClassThunks] (Step #17). Used to register the native-type
  /// lookup thunk without building the BridgedClass.
  static Map<String, Type> bridgeClassTypes() {
    return {
      'SomNode': $tom_som_dart_runtime_1.SomNode,
      'SomScalar': $tom_som_dart_runtime_1.SomScalar,
      'SomList': $tom_som_dart_runtime_1.SomList,
      'SomVersionException': $tom_som_dart_runtime_1.SomVersionException,
      'SpecDocument': $tom_som_dart_runtime_2.SpecDocument,
      'SpecDocumentState': $tom_som_dart_runtime_2.SpecDocumentState,
      'SpecMarkdownRejection': $tom_som_dart_runtime_3.SpecMarkdownRejection,
      'SpecMarkdownResult': $tom_som_dart_runtime_3.SpecMarkdownResult,
      'SpecDocumentMarkdown': $tom_som_dart_runtime_3.SpecDocumentMarkdown,
      'SpecYamlContents': $tom_som_dart_runtime_4.SpecYamlContents,
      'SpecDocumentYaml': $tom_som_dart_runtime_4.SpecDocumentYaml,
      'SpecAnnotation': $tom_som_dart_runtime_5.SpecAnnotation,
      'FormFieldSpec': $tom_som_dart_runtime_5.FormFieldSpec,
      'SpecField': $tom_som_dart_runtime_5.SpecField,
      'SpecClass': $tom_som_dart_runtime_5.SpecClass,
      'SpecRoot': $tom_som_dart_runtime_5.SpecRoot,
      'SpecModel': $tom_som_dart_runtime_5.SpecModel,
      'SpecCreationError': $tom_som_dart_runtime_6.SpecCreationError,
      'SpecNodeCreator': $tom_som_dart_runtime_6.SpecNodeCreator,
      'SpecMatchSpan': $tom_som_dart_runtime_8.SpecMatchSpan,
      'SpecQueryMatch': $tom_som_dart_runtime_8.SpecQueryMatch,
      'SpecQuery': $tom_som_dart_runtime_8.SpecQuery,
      'SpecQueryEngine': $tom_som_dart_runtime_8.SpecQueryEngine,
      'SpecQueryCursor': $tom_som_dart_runtime_8.SpecQueryCursor,
      'SpecResolution': $tom_som_dart_runtime_9.SpecResolution,
      'SpecReflection': $tom_som_dart_runtime_9.SpecReflection,
      'SpecValidationError': $tom_som_dart_runtime_10.SpecValidationError,
    };
  }

  /// Returns a map of class names to their canonical source URIs.
  ///
  /// Used for deduplication when the same class is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> classSourceUris() {
    return {
      'SomNode': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SomScalar': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SomList': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SomVersionException': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SpecDocument': 'package:tom_som_dart_runtime/src/spec_document.dart',
      'SpecDocumentState': 'package:tom_som_dart_runtime/src/spec_document.dart',
      'SpecMarkdownRejection': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecMarkdownResult': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecDocumentMarkdown': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecYamlContents': 'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'SpecDocumentYaml': 'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'SpecAnnotation': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'FormFieldSpec': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecField': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecClass': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecRoot': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecModel': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecCreationError': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'SpecNodeCreator': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'SpecMatchSpan': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQueryMatch': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQuery': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQueryEngine': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQueryCursor': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecResolution': 'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'SpecReflection': 'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'SpecValidationError': 'package:tom_som_dart_runtime/src/spec_validator.dart',
    };
  }

  /// Returns a map of class names to their flattened (transitive)
  /// native supertype names (superclasses, interfaces and mixins).
  ///
  /// Fed to `BridgedClass.registerSupertypes` so interpreted subclasses
  /// of bridged classes pass `is`/subtype checks against bridged
  /// ancestors and the interface-proxy supertype walk resolves up the
  /// chain (MCI#1 / A1).
  static Map<String, List<String>> classSupertypes() {
    return {
      'SomScalar': ['SomNode'],
      'SomVersionException': ['Exception'],
      'SpecCreationError': ['Exception'],
    };
  }

  /// Returns a map of type alias names to their target class names.
  ///
  /// Type aliases like `typedef MaterialStateProperty<T> = WidgetStateProperty<T>`
  /// are registered so that code using the alias name can resolve to the
  /// bridged class under its canonical name.
  static Map<String, String> classAliases() {
    return {
    };
  }

  /// Returns the list of function typedef names declared in this library.
  ///
  /// Function typedefs like `typedef VoidCallback = void Function()` are
  /// registered so that they can be used as type arguments in D4rt scripts.
  static List<String> functionTypedefs() {
    return [
    ];
  }

  /// Returns all bridged enum definitions.
  static List<BridgedEnumDefinition> bridgedEnums() {
    return [
      BridgedEnumDefinition<$tom_som_dart_runtime_3.SpecMarkdownRejectReason>(
        name: 'SpecMarkdownRejectReason',
        values: $tom_som_dart_runtime_3.SpecMarkdownRejectReason.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_5.SpecFieldKind>(
        name: 'SpecFieldKind',
        values: $tom_som_dart_runtime_5.SpecFieldKind.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_6.SpecCreationCode>(
        name: 'SpecCreationCode',
        values: $tom_som_dart_runtime_6.SpecCreationCode.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_8.SpecStateFilter>(
        name: 'SpecStateFilter',
        values: $tom_som_dart_runtime_8.SpecStateFilter.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_9.SpecNodeKind>(
        name: 'SpecNodeKind',
        values: $tom_som_dart_runtime_9.SpecNodeKind.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_10.SpecValidationCode>(
        name: 'SpecValidationCode',
        values: $tom_som_dart_runtime_10.SpecValidationCode.values,
      ),
    ];
  }

  /// Returns a map of enum names to their canonical source URIs.
  ///
  /// Used for deduplication when the same enum is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> enumSourceUris() {
    return {
      'SpecMarkdownRejectReason': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecFieldKind': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecCreationCode': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'SpecStateFilter': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecNodeKind': 'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'SpecValidationCode': 'package:tom_som_dart_runtime/src/spec_validator.dart',
    };
  }

  /// Returns all bridged extension definitions.
  static List<BridgedExtensionDefinition> bridgedExtensions() {
    return [
    ];
  }

  /// Returns a map of extension identifiers to their canonical source URIs.
  static Map<String, String> extensionSourceUris() {
    return {
    };
  }

  /// GEN-107: Library re-exports declared by the bridged source
  /// libraries. Each tuple mirrors a Dart `export '…'` directive.
  /// Consumed by `registerBridges` via `D4rt.registerLibraryReExport`
  /// (mirrored on `D4rtRunner` in tom_d4rt_ast).
  static List<({String source, String target, Set<String>? show, Set<String>? hide})>
  bridgeReExports() {
    return [
    ];
  }

  /// Registers all bridges with an interpreter.
  ///
  /// [importPath] is the package import path that D4rt scripts will use
  /// to access these classes (e.g., 'package:tom_build/tom.dart').
  static void registerBridges(D4rt interpreter, String importPath) {
    // Step #17 — register deferred factory thunks (not pre-built
    // BridgedClass objects): a script touching N of the M classes
    // materializes ≈N (each thunk builds its class on first resolve).
    final classThunks = bridgeClassThunks();
    final classTypes = bridgeClassTypes();
    final classSources = classSourceUris();
    for (final entry in classThunks.entries) {
      interpreter.registerBridgedClassLazy(
        entry.key,
        classTypes[entry.key]!,
        entry.value,
        importPath,
        sourceUri: classSources[entry.key],
      );
    }

    // MCI#1 / A1: Register the flattened native supertype table so
    // interpreted subclasses pass subtype checks against bridged
    // ancestors. Idempotent — safe to call per barrel.
    BridgedClass.registerSupertypes(classSupertypes());

    // Register bridged enums with source URIs for deduplication
    final enums = bridgedEnums();
    final enumSources = enumSourceUris();
    for (final enumDef in enums) {
      interpreter.registerBridgedEnum(enumDef, importPath, sourceUri: enumSources[enumDef.name]);
    }

    // Register global variables
    registerGlobalVariables(interpreter, importPath);

    // Register global functions with source URIs for deduplication
    final funcs = globalFunctions();
    final funcSources = globalFunctionSourceUris();
    final funcSigs = globalFunctionSignatures();
    for (final entry in funcs.entries) {
      interpreter.registertopLevelFunction(entry.key, entry.value, importPath, sourceUri: funcSources[entry.key], signature: funcSigs[entry.key]);
    }
  }

  /// Registers all global variables with the interpreter.
  ///
  /// [importPath] is the package import path for library-scoped registration.
  /// Collects all registration errors and throws a single exception
  /// with all error details if any registrations fail.
  static void registerGlobalVariables(D4rt interpreter, String importPath) {
    final errors = <String>[];

    try {
      interpreter.registerGlobalVariable('kSpecPathSeparator', $tom_som_dart_runtime_7.kSpecPathSeparator, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_paths.dart');
    } catch (e) {
      errors.add('Failed to register variable "kSpecPathSeparator": $e');
    }

    if (errors.isNotEmpty) {
      throw StateError('Bridge registration errors (som_runtime):\n${errors.join("\n")}');
    }
  }

  /// Returns a map of global function names to their native implementations.
  static Map<String, NativeFunctionImpl> globalFunctions() {
    return {
      'checkSomModelVersion': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'checkSomModelVersion');
        final generated = D4.getRequiredArg<String>(positional, 0, 'generated', 'checkSomModelVersion');
        final documentVersion = D4.getRequiredArg<String?>(positional, 1, 'documentVersion', 'checkSomModelVersion');
        return $tom_som_dart_runtime_1.checkSomModelVersion(generated, documentVersion);
      },
      'checkAddNode': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 4, 'checkAddNode');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecModel>(positional, 0, 'model', 'checkAddNode');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocument>(positional, 1, 'document', 'checkAddNode');
        final parentPath = D4.getRequiredArg<String>(positional, 2, 'parentPath', 'checkAddNode');
        final childSegment = D4.getRequiredArg<String>(positional, 3, 'childSegment', 'checkAddNode');
        final itemId = D4.getOptionalNamedArg<String?>(named, 'itemId');
        return $tom_som_dart_runtime_6.checkAddNode(model, document, parentPath, childSegment, itemId: itemId);
      },
      'specPathJoin': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'specPathJoin');
        final parent = D4.getRequiredArg<String>(positional, 0, 'parent', 'specPathJoin');
        final segment = D4.getRequiredArg<String>(positional, 1, 'segment', 'specPathJoin');
        return $tom_som_dart_runtime_7.specPathJoin(parent, segment);
      },
      'specPathSegments': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'specPathSegments');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'specPathSegments');
        return $tom_som_dart_runtime_7.specPathSegments(path);
      },
      'listItemPath': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'listItemPath');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItemPath');
        final seq = D4.getRequiredArg<int>(positional, 1, 'seq', 'listItemPath');
        return $tom_som_dart_runtime_7.listItemPath(listPath, seq);
      },
      'splitListItemSegment': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'splitListItemSegment');
        final segment = D4.getRequiredArg<String>(positional, 0, 'segment', 'splitListItemSegment');
        return $tom_som_dart_runtime_7.splitListItemSegment(segment);
      },
      'validateDocument': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'validateDocument');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecModel>(positional, 0, 'model', 'validateDocument');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocument>(positional, 1, 'doc', 'validateDocument');
        return $tom_som_dart_runtime_10.validateDocument(model, doc);
      },
    };
  }

  /// Returns a map of global function names to their canonical source URIs.
  ///
  /// Used for deduplication when the same function is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> globalFunctionSourceUris() {
    return {
      'checkSomModelVersion': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'checkAddNode': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'specPathJoin': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'specPathSegments': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'listItemPath': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'splitListItemSegment': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'validateDocument': 'package:tom_som_dart_runtime/src/spec_validator.dart',
    };
  }

  /// Returns a map of global function names to their display signatures.
  static Map<String, String> globalFunctionSignatures() {
    return {
      'checkSomModelVersion': 'void checkSomModelVersion(String generated, String? documentVersion)',
      'checkAddNode': 'SpecCreationError? checkAddNode(SpecModel model, SpecDocument document, String parentPath, String childSegment, {String? itemId})',
      'specPathJoin': 'String specPathJoin(String parent, String segment)',
      'specPathSegments': 'List<String> specPathSegments(String path)',
      'listItemPath': 'String listItemPath(String listPath, int seq)',
      'splitListItemSegment': '({String base, int seq})? splitListItemSegment(String segment)',
      'validateDocument': 'List<SpecValidationError> validateDocument(SpecModel model, SpecDocument doc)',
    };
  }

  /// Returns the list of canonical source library URIs.
  ///
  /// These are the actual source locations of all elements in this bridge,
  /// used for deduplication when the same libraries are exported through
  /// multiple barrels.
  static List<String> sourceLibraries() {
    return [
      'package:tom_som_dart_runtime/src/som_facade.dart',
      'package:tom_som_dart_runtime/src/spec_document.dart',
      'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'package:tom_som_dart_runtime/src/spec_model.dart',
      'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'package:tom_som_dart_runtime/src/spec_paths.dart',
      'package:tom_som_dart_runtime/src/spec_query.dart',
      'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'package:tom_som_dart_runtime/src/spec_validator.dart',
    ];
  }

  /// Returns the import statement needed for D4rt scripts.
  ///
  /// Use this in your D4rt initialization script to make all
  /// bridged classes available to scripts.
  static String getImportBlock() {
    return "import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';";
  }

  /// Returns barrel import URIs for sub-packages discovered through re-exports.
  ///
  /// When a module follows re-exports into sub-packages (e.g., dcli re-exports
  /// dcli_core), D4rt scripts may import those sub-packages directly.
  /// These barrels need to be registered with the interpreter separately
  /// so that module resolution finds content for those URIs.
  static List<String> subPackageBarrels() {
    return [];
  }

  /// Returns a list of bridged enum names.
  static List<String> get enumNames => [
    'SpecMarkdownRejectReason',
    'SpecFieldKind',
    'SpecCreationCode',
    'SpecStateFilter',
    'SpecNodeKind',
    'SpecValidationCode',
  ];

}

// =============================================================================
// SomNode Bridge
// =============================================================================

BridgedClass _createSomNodeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.SomNode,
    name: 'SomNode',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.SomNode,
    isAbstract: true,
    constructors: {
    },
    getters: {
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomNode>(target, 'SomNode').doc,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomNode>(target, 'SomNode').path,
    },
    getterSignatures: {
      'doc': 'SpecDocument get doc',
      'path': 'String get path',
    },
  );
}

// =============================================================================
// SomScalar Bridge
// =============================================================================

BridgedClass _createSomScalarBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.SomScalar,
    name: 'SomScalar',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.SomScalar,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SomScalar');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocument>(positional, 0, 'doc', 'SomScalar');
        final path = D4.getRequiredArg<String>(positional, 1, 'path', 'SomScalar');
        return $tom_som_dart_runtime_1.SomScalar(doc, path);
      },
    },
    getters: {
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomScalar>(target, 'SomScalar').doc,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomScalar>(target, 'SomScalar').path,
      'value': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomScalar>(target, 'SomScalar').value,
    },
    setters: {
      'value': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_1.SomScalar>(target, 'SomScalar').value = D4.extractBridgedArg<String>(value, 'value'),
    },
    constructorSignatures: {
      '': 'SomScalar(SpecDocument doc, String path)',
    },
    getterSignatures: {
      'doc': 'SpecDocument get doc',
      'path': 'String get path',
      'value': 'String get value',
    },
    setterSignatures: {
      'value': 'set value(String value)',
    },
  );
}

// =============================================================================
// SomList Bridge
// =============================================================================

BridgedClass _createSomListBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.SomList,
    name: 'SomList',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.SomList,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 3, 'SomList');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocument>(positional, 0, 'doc', 'SomList');
        final listPath = D4.getRequiredArg<String>(positional, 1, 'listPath', 'SomList');
        if (positional.length <= 2) {
          throw ArgumentError('SomList: Missing required argument "_factory" at position 2');
        }
        final factoryRaw = positional[2];
        return $tom_som_dart_runtime_1.SomList(doc, listPath, ($tom_som_dart_runtime_2.SpecDocument p0, String p1) { return D4.castCallbackResult<dynamic>(D4.callInterpreterCallback(visitor!, factoryRaw, [p0, p1])); });
      },
    },
    getters: {
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList').doc,
      'listPath': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList').listPath,
      'length': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList').length,
      'items': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList').items,
    },
    methods: {
      'add': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList');
        return t.add();
      },
      'removeAt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList');
        D4.requireMinArgs(positional, 1, 'removeAt');
        final index = D4.getRequiredArg<int>(positional, 0, 'index', 'removeAt');
        t.removeAt(index);
        return null;
      },
      '[]': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.SomList>(target, 'SomList');
        final index = D4.getRequiredArg<int>(positional, 0, 'index', 'operator[]');
        return t[index];
      },
    },
    constructorSignatures: {
      '': 'SomList(SpecDocument doc, String listPath, T Function(SpecDocument doc, String itemPath) _factory)',
    },
    methodSignatures: {
      'add': 'T add()',
      'removeAt': 'void removeAt(int index)',
    },
    getterSignatures: {
      'doc': 'SpecDocument get doc',
      'listPath': 'String get listPath',
      'length': 'int get length',
      'items': 'List<T> get items',
    },
  );
}

// =============================================================================
// SomVersionException Bridge
// =============================================================================

BridgedClass _createSomVersionExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.SomVersionException,
    name: 'SomVersionException',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.SomVersionException,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SomVersionException');
        final message = D4.getRequiredArg<String>(positional, 0, 'message', 'SomVersionException');
        return $tom_som_dart_runtime_1.SomVersionException(message);
      },
    },
    getters: {
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.SomVersionException>(target, 'SomVersionException').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.SomVersionException>(target, 'SomVersionException');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SomVersionException(String message)',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'message': 'String get message',
    },
  );
}

// =============================================================================
// SpecDocument Bridge
// =============================================================================

BridgedClass _createSpecDocumentBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_2.SpecDocument,
    name: 'SpecDocument',
    isAssignable: (v) => v is $tom_som_dart_runtime_2.SpecDocument,
    constructors: {
      '': (visitor, positional, named) {
        return $tom_som_dart_runtime_2.SpecDocument();
      },
    },
    getters: {
      'isEmpty': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument').isEmpty,
      'contentPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument').contentPaths,
      'formPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument').formPaths,
      'listPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument').listPaths,
    },
    methods: {
      'content': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'content');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'content');
        return t.content(path);
      },
      'setContent': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'setContent');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setContent');
        final value = D4.getRequiredArg<String>(positional, 1, 'value', 'setContent');
        t.setContent(path, value);
        return null;
      },
      'formField': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'formField');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formField');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'formField');
        return t.formField(path, field);
      },
      'setFormField': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 3, 'setFormField');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setFormField');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'setFormField');
        final value = D4.getRequiredArg<String>(positional, 2, 'value', 'setFormField');
        t.setFormField(path, field, value);
        return null;
      },
      'listItems': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'listItems');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItems');
        return t.listItems(listPath);
      },
      'addListItem': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'addListItem');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'addListItem');
        return t.addListItem(listPath);
      },
      'removeListItem': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'removeListItem');
        final itemPath = D4.getRequiredArg<String>(positional, 0, 'itemPath', 'removeListItem');
        return t.removeListItem(itemPath);
      },
      'hasValuesUnder': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'hasValuesUnder');
        final prefix = D4.getRequiredArg<String>(positional, 0, 'prefix', 'hasValuesUnder');
        return t.hasValuesUnder(prefix);
      },
      'formFieldNames': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'formFieldNames');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formFieldNames');
        return t.formFieldNames(path);
      },
      'listItemCount': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'listItemCount');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItemCount');
        return t.listItemCount(listPath);
      },
      'toJson': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        return t.toJson();
      },
      'loadJson': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'loadJson');
        final json = D4.getRequiredArg<Map>(positional, 0, 'json', 'loadJson');
        t.loadJson(json);
        return null;
      },
      'captureState': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        return t.captureState();
      },
      'restoreState': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'restoreState');
        final state = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocumentState>(positional, 0, 'state', 'restoreState');
        t.restoreState(state);
        return null;
      },
    },
    constructorSignatures: {
      '': 'SpecDocument()',
    },
    methodSignatures: {
      'content': 'String? content(String path)',
      'setContent': 'void setContent(String path, String value)',
      'formField': 'String? formField(String path, String field)',
      'setFormField': 'void setFormField(String path, String field, String value)',
      'listItems': 'List<String> listItems(String listPath)',
      'addListItem': 'String addListItem(String listPath)',
      'removeListItem': 'bool removeListItem(String itemPath)',
      'hasValuesUnder': 'bool hasValuesUnder(String prefix)',
      'formFieldNames': 'Iterable<String> formFieldNames(String path)',
      'listItemCount': 'int listItemCount(String listPath)',
      'toJson': 'Map<String, Object?> toJson()',
      'loadJson': 'void loadJson(Map json)',
      'captureState': 'SpecDocumentState captureState()',
      'restoreState': 'void restoreState(SpecDocumentState state)',
    },
    getterSignatures: {
      'isEmpty': 'bool get isEmpty',
      'contentPaths': 'Iterable<String> get contentPaths',
      'formPaths': 'Iterable<String> get formPaths',
      'listPaths': 'Iterable<String> get listPaths',
    },
  );
}

// =============================================================================
// SpecDocumentState Bridge
// =============================================================================

BridgedClass _createSpecDocumentStateBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_2.SpecDocumentState,
    name: 'SpecDocumentState',
    isAssignable: (v) => v is $tom_som_dart_runtime_2.SpecDocumentState,
    constructors: {
    },
    getters: {
      'fingerprint': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SpecDocumentState>(target, 'SpecDocumentState').fingerprint,
    },
    methods: {
      'contentAt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocumentState>(target, 'SpecDocumentState');
        D4.requireMinArgs(positional, 1, 'contentAt');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'contentAt');
        return t.contentAt(path);
      },
      'formFieldAt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SpecDocumentState>(target, 'SpecDocumentState');
        D4.requireMinArgs(positional, 2, 'formFieldAt');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formFieldAt');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'formFieldAt');
        return t.formFieldAt(path, field);
      },
    },
    methodSignatures: {
      'contentAt': 'String? contentAt(String path)',
      'formFieldAt': 'String? formFieldAt(String path, String field)',
    },
    getterSignatures: {
      'fingerprint': 'String get fingerprint',
    },
  );
}

// =============================================================================
// SpecMarkdownRejection Bridge
// =============================================================================

BridgedClass _createSpecMarkdownRejectionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_3.SpecMarkdownRejection,
    name: 'SpecMarkdownRejection',
    isAssignable: (v) => v is $tom_som_dart_runtime_3.SpecMarkdownRejection,
    constructors: {
      '': (visitor, positional, named) {
        final line = D4.getRequiredNamedArg<int>(named, 'line', 'SpecMarkdownRejection');
        final reason = D4.getRequiredNamedArg<$tom_som_dart_runtime_3.SpecMarkdownRejectReason>(named, 'reason', 'SpecMarkdownRejection');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'SpecMarkdownRejection');
        final anchor = D4.getOptionalNamedArg<String?>(named, 'anchor');
        return $tom_som_dart_runtime_3.SpecMarkdownRejection(line: line, reason: reason, message: message, anchor: anchor);
      },
    },
    getters: {
      'line': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').line,
      'reason': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').reason,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').message,
      'anchor': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').anchor,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownRejection>(target, 'SpecMarkdownRejection');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'SpecMarkdownRejection({required int line, required SpecMarkdownRejectReason reason, required String message, String? anchor})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'line': 'int get line',
      'reason': 'SpecMarkdownRejectReason get reason',
      'message': 'String get message',
      'anchor': 'String? get anchor',
    },
  );
}

// =============================================================================
// SpecMarkdownResult Bridge
// =============================================================================

BridgedClass _createSpecMarkdownResultBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_3.SpecMarkdownResult,
    name: 'SpecMarkdownResult',
    isAssignable: (v) => v is $tom_som_dart_runtime_3.SpecMarkdownResult,
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('content') || named['content'] == null) {
          throw ArgumentError('SpecMarkdownResult: Missing required named argument "content"');
        }
        final content = D4.coerceMap<String, String>(named['content'], 'content');
        if (!named.containsKey('forms') || named['forms'] == null) {
          throw ArgumentError('SpecMarkdownResult: Missing required named argument "forms"');
        }
        final forms = D4.coerceMap<String, Map<String, String>>(named['forms'], 'forms');
        if (!named.containsKey('lists') || named['lists'] == null) {
          throw ArgumentError('SpecMarkdownResult: Missing required named argument "lists"');
        }
        final lists = D4.coerceMap<String, Map<String, Object?>>(named['lists'], 'lists');
        if (!named.containsKey('rejections') || named['rejections'] == null) {
          throw ArgumentError('SpecMarkdownResult: Missing required named argument "rejections"');
        }
        final rejections = D4.coerceList<$tom_som_dart_runtime_3.SpecMarkdownRejection>(named['rejections'], 'rejections');
        if (!named.containsKey('rootPrefixes') || named['rootPrefixes'] == null) {
          throw ArgumentError('SpecMarkdownResult: Missing required named argument "rootPrefixes"');
        }
        final rootPrefixes = D4.coerceSet<String>(named['rootPrefixes'], 'rootPrefixes');
        return $tom_som_dart_runtime_3.SpecMarkdownResult(content: content, forms: forms, lists: lists, rejections: rejections, rootPrefixes: rootPrefixes);
      },
    },
    getters: {
      'content': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').content,
      'forms': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').forms,
      'lists': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').lists,
      'rejections': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').rejections,
      'rootPrefixes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').rootPrefixes,
      'isClean': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').isClean,
      'appliedCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecMarkdownResult>(target, 'SpecMarkdownResult').appliedCount,
    },
    constructorSignatures: {
      '': 'SpecMarkdownResult({required Map<String, String> content, required Map<String, Map<String, String>> forms, required Map<String, Map<String, Object?>> lists, required List<SpecMarkdownRejection> rejections, required Set<String> rootPrefixes})',
    },
    getterSignatures: {
      'content': 'Map<String, String> get content',
      'forms': 'Map<String, Map<String, String>> get forms',
      'lists': 'Map<String, Map<String, Object?>> get lists',
      'rejections': 'List<SpecMarkdownRejection> get rejections',
      'rootPrefixes': 'Set<String> get rootPrefixes',
      'isClean': 'bool get isClean',
      'appliedCount': 'int get appliedCount',
    },
  );
}

// =============================================================================
// SpecDocumentMarkdown Bridge
// =============================================================================

BridgedClass _createSpecDocumentMarkdownBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_3.SpecDocumentMarkdown,
    name: 'SpecDocumentMarkdown',
    isAssignable: (v) => v is $tom_som_dart_runtime_3.SpecDocumentMarkdown,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecDocumentMarkdown');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecModel>(positional, 0, 'model', 'SpecDocumentMarkdown');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocument>(positional, 1, 'document', 'SpecDocumentMarkdown');
        return $tom_som_dart_runtime_3.SpecDocumentMarkdown(model, document);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown').model,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown').document,
    },
    methods: {
      'exportRoot': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_3.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown');
        D4.requireMinArgs(positional, 1, 'exportRoot');
        final root = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecRoot>(positional, 0, 'root', 'exportRoot');
        return t.exportRoot(root);
      },
      'parse': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_3.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown');
        D4.requireMinArgs(positional, 1, 'parse');
        final text = D4.getRequiredArg<String>(positional, 0, 'text', 'parse');
        return t.parse(text);
      },
    },
    staticMethods: {
      'fence': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'fence');
        final value = D4.getRequiredArg<String>(positional, 0, 'value', 'fence');
        final info = D4.getNamedArgWithDefault<String>(named, 'info', '');
        return $tom_som_dart_runtime_3.SpecDocumentMarkdown.fence(value, info: info);
      },
    },
    constructorSignatures: {
      '': 'SpecDocumentMarkdown(SpecModel model, SpecDocument document)',
    },
    methodSignatures: {
      'exportRoot': 'String exportRoot(SpecRoot root)',
      'parse': 'SpecMarkdownResult parse(String text)',
    },
    getterSignatures: {
      'model': 'SpecModel get model',
      'document': 'SpecDocument get document',
    },
    staticMethodSignatures: {
      'fence': 'String fence(String value, {String info = \'\'})',
    },
  );
}

// =============================================================================
// SpecYamlContents Bridge
// =============================================================================

BridgedClass _createSpecYamlContentsBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_4.SpecYamlContents,
    name: 'SpecYamlContents',
    isAssignable: (v) => v is $tom_som_dart_runtime_4.SpecYamlContents,
    constructors: {
      '': (visitor, positional, named) {
        final document = D4.getRequiredNamedArg<Map>(named, 'document', 'SpecYamlContents');
        final review = D4.getRequiredNamedArg<Map>(named, 'review', 'SpecYamlContents');
        final modelVersion = D4.getOptionalNamedArg<String?>(named, 'modelVersion');
        return $tom_som_dart_runtime_4.SpecYamlContents(document: document, review: review, modelVersion: modelVersion);
      },
    },
    getters: {
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecYamlContents>(target, 'SpecYamlContents').document,
      'review': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecYamlContents>(target, 'SpecYamlContents').review,
      'modelVersion': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecYamlContents>(target, 'SpecYamlContents').modelVersion,
    },
    constructorSignatures: {
      '': 'SpecYamlContents({required Map document, required Map review, String? modelVersion})',
    },
    getterSignatures: {
      'document': 'Map get document',
      'review': 'Map get review',
      'modelVersion': 'String? get modelVersion',
    },
  );
}

// =============================================================================
// SpecDocumentYaml Bridge
// =============================================================================

BridgedClass _createSpecDocumentYamlBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_4.SpecDocumentYaml,
    name: 'SpecDocumentYaml',
    isAssignable: (v) => v is $tom_som_dart_runtime_4.SpecDocumentYaml,
    constructors: {
      '': (visitor, positional, named) {
        return $tom_som_dart_runtime_4.SpecDocumentYaml();
      },
    },
    staticGetters: {
      'formatVersion': (visitor) => $tom_som_dart_runtime_4.SpecDocumentYaml.formatVersion,
    },
    staticMethods: {
      'encode': (visitor, positional, named, typeArgs) {
        final document = D4.getRequiredNamedArg<$tom_som_dart_runtime_2.SpecDocument>(named, 'document', 'encode');
        final modelVersion = D4.getOptionalNamedArg<String?>(named, 'modelVersion');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.encode(document: document, modelVersion: modelVersion);
      },
      'writeHeader': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'writeHeader');
        final b = D4.getRequiredArg<StringBuffer>(positional, 0, 'b', 'writeHeader');
        final modelVersion = D4.getOptionalNamedArg<String?>(named, 'modelVersion');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.writeHeader(b, modelVersion: modelVersion);
      },
      'writeDocumentPass': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'writeDocumentPass');
        final b = D4.getRequiredArg<StringBuffer>(positional, 0, 'b', 'writeDocumentPass');
        if (positional.length <= 1) {
          throw ArgumentError('writeDocumentPass: Missing required argument "doc" at position 1');
        }
        final doc = D4.coerceMap<String, Object?>(positional[1], 'doc');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.writeDocumentPass(b, doc);
      },
      'writeScalar': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 4, 'writeScalar');
        final b = D4.getRequiredArg<StringBuffer>(positional, 0, 'b', 'writeScalar');
        final keyIndent = D4.getRequiredArg<int>(positional, 1, 'keyIndent', 'writeScalar');
        final key = D4.getRequiredArg<String>(positional, 2, 'key', 'writeScalar');
        final value = D4.getRequiredArg<String>(positional, 3, 'value', 'writeScalar');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.writeScalar(b, keyIndent, key, value);
      },
      'yamlKey': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'yamlKey');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'yamlKey');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.yamlKey(key);
      },
      'sortedStringKeys': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'sortedStringKeys');
        final map = D4.getRequiredArg<Map>(positional, 0, 'map', 'sortedStringKeys');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.sortedStringKeys(map);
      },
      'decode': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'decode');
        final yaml = D4.getRequiredArg<String>(positional, 0, 'yaml', 'decode');
        return $tom_som_dart_runtime_4.SpecDocumentYaml.decode(yaml);
      },
    },
    constructorSignatures: {
      '': 'SpecDocumentYaml()',
    },
    staticMethodSignatures: {
      'encode': 'String encode({required SpecDocument document, String? modelVersion})',
      'writeHeader': 'void writeHeader(StringBuffer b, {String? modelVersion})',
      'writeDocumentPass': 'void writeDocumentPass(StringBuffer b, Map<String, Object?> doc)',
      'writeScalar': 'void writeScalar(StringBuffer b, int keyIndent, String key, String value)',
      'yamlKey': 'String yamlKey(String key)',
      'sortedStringKeys': 'List<String> sortedStringKeys(Map map)',
      'decode': 'SpecYamlContents decode(String yaml)',
    },
    staticGetterSignatures: {
      'formatVersion': 'int get formatVersion',
    },
  );
}

// =============================================================================
// SpecAnnotation Bridge
// =============================================================================

BridgedClass _createSpecAnnotationBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.SpecAnnotation,
    name: 'SpecAnnotation',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecAnnotation,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SpecAnnotation');
        final arguments = named.containsKey('arguments') && named['arguments'] != null
            ? D4.coerceMap<String, Object?>(named['arguments'], 'arguments')
            : const <String, Object?>{};
        return $tom_som_dart_runtime_5.SpecAnnotation(name: name, arguments: arguments);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecAnnotation');
        if (positional.isEmpty) {
          throw ArgumentError('SpecAnnotation: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_5.SpecAnnotation.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecAnnotation>(target, 'SpecAnnotation').name,
      'arguments': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecAnnotation>(target, 'SpecAnnotation').arguments,
    },
    methods: {
      'argument': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecAnnotation>(target, 'SpecAnnotation');
        D4.requireMinArgs(positional, 1, 'argument');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'argument');
        return t.argument(key);
      },
    },
    staticMethods: {
      'listFromJson': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'listFromJson');
        final raw = D4.getRequiredArg<Object?>(positional, 0, 'raw', 'listFromJson');
        return $tom_som_dart_runtime_5.SpecAnnotation.listFromJson(raw);
      },
    },
    constructorSignatures: {
      '': 'const SpecAnnotation({required String name, Map<String, Object?> arguments = const {}})',
      'fromJson': 'factory SpecAnnotation.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'argument': 'Object? argument(String key)',
    },
    getterSignatures: {
      'name': 'String get name',
      'arguments': 'Map<String, Object?> get arguments',
    },
    staticMethodSignatures: {
      'listFromJson': 'List<SpecAnnotation> listFromJson(Object? raw)',
    },
  );
}

// =============================================================================
// FormFieldSpec Bridge
// =============================================================================

BridgedClass _createFormFieldSpecBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.FormFieldSpec,
    name: 'FormFieldSpec',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.FormFieldSpec,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'FormFieldSpec');
        final label = D4.getRequiredNamedArg<String>(named, 'label', 'FormFieldSpec');
        final type = D4.getRequiredNamedArg<String>(named, 'type', 'FormFieldSpec');
        final hint = D4.getOptionalNamedArg<String?>(named, 'hint');
        final required = D4.getNamedArgWithDefault<bool>(named, 'required', false);
        return $tom_som_dart_runtime_5.FormFieldSpec(name: name, label: label, type: type, hint: hint, required: required);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'FormFieldSpec');
        if (positional.isEmpty) {
          throw ArgumentError('FormFieldSpec: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_5.FormFieldSpec.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.FormFieldSpec>(target, 'FormFieldSpec').name,
      'label': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.FormFieldSpec>(target, 'FormFieldSpec').label,
      'hint': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.FormFieldSpec>(target, 'FormFieldSpec').hint,
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.FormFieldSpec>(target, 'FormFieldSpec').type,
      'required': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.FormFieldSpec>(target, 'FormFieldSpec').required,
    },
    constructorSignatures: {
      '': 'FormFieldSpec({required String name, required String label, required String type, String? hint, bool required = false})',
      'fromJson': 'factory FormFieldSpec.fromJson(Map<String, dynamic> j)',
    },
    getterSignatures: {
      'name': 'String get name',
      'label': 'String get label',
      'hint': 'String? get hint',
      'type': 'String get type',
      'required': 'bool get required',
    },
  );
}

// =============================================================================
// SpecField Bridge
// =============================================================================

BridgedClass _createSpecFieldBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.SpecField,
    name: 'SpecField',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecField,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SpecField');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_5.SpecFieldKind>(named, 'kind', 'SpecField');
        final doc = D4.getOptionalNamedArg<String?>(named, 'doc');
        final help = D4.getOptionalNamedArg<String?>(named, 'help');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final sectionIdPattern = D4.getOptionalNamedArg<String?>(named, 'sectionIdPattern');
        final elementType = D4.getOptionalNamedArg<String?>(named, 'elementType');
        final elementIsComplex = D4.getNamedArgWithDefault<bool>(named, 'elementIsComplex', false);
        final min = D4.getOptionalNamedArg<int?>(named, 'min');
        final contentType = D4.getOptionalNamedArg<String?>(named, 'contentType');
        final sectionType = D4.getOptionalNamedArg<String?>(named, 'sectionType');
        final enumType = D4.getOptionalNamedArg<String?>(named, 'enumType');
        final enumValues = named.containsKey('enumValues') && named['enumValues'] != null
            ? D4.coerceList<String>(named['enumValues'], 'enumValues')
            : const <String>[];
        final type = D4.getOptionalNamedArg<String?>(named, 'type');
        final formFields = named.containsKey('formFields') && named['formFields'] != null
            ? D4.coerceList<$tom_som_dart_runtime_5.FormFieldSpec>(named['formFields'], 'formFields')
            : const <$tom_som_dart_runtime_5.FormFieldSpec>[];
        final annotations = named.containsKey('annotations') && named['annotations'] != null
            ? D4.coerceList<$tom_som_dart_runtime_5.SpecAnnotation>(named['annotations'], 'annotations')
            : const <$tom_som_dart_runtime_5.SpecAnnotation>[];
        return $tom_som_dart_runtime_5.SpecField(name: name, kind: kind, doc: doc, help: help, sectionId: sectionId, sectionIdPattern: sectionIdPattern, elementType: elementType, elementIsComplex: elementIsComplex, min: min, contentType: contentType, sectionType: sectionType, enumType: enumType, enumValues: enumValues, type: type, formFields: formFields, annotations: annotations);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecField');
        if (positional.isEmpty) {
          throw ArgumentError('SpecField: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_5.SpecField.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').name,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').kind,
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').doc,
      'help': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').help,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').sectionId,
      'sectionIdPattern': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').sectionIdPattern,
      'elementType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').elementType,
      'elementIsComplex': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').elementIsComplex,
      'min': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').min,
      'contentType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').contentType,
      'sectionType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').sectionType,
      'enumType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').enumType,
      'enumValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').enumValues,
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').type,
      'formFields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').formFields,
      'annotations': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').annotations,
      'isExpandable': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField').isExpandable,
    },
    methods: {
      'annotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecField>(target, 'SpecField');
        D4.requireMinArgs(positional, 1, 'annotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotation');
        return t.annotation(name);
      },
    },
    constructorSignatures: {
      '': 'SpecField({required String name, required SpecFieldKind kind, String? doc, String? help, String? sectionId, String? sectionIdPattern, String? elementType, bool elementIsComplex = false, int? min, String? contentType, String? sectionType, String? enumType, List<String> enumValues = const [], String? type, List<FormFieldSpec> formFields = const [], List<SpecAnnotation> annotations = const []})',
      'fromJson': 'factory SpecField.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'annotation': 'SpecAnnotation? annotation(String name)',
    },
    getterSignatures: {
      'name': 'String get name',
      'kind': 'SpecFieldKind get kind',
      'doc': 'String? get doc',
      'help': 'String? get help',
      'sectionId': 'String? get sectionId',
      'sectionIdPattern': 'String? get sectionIdPattern',
      'elementType': 'String? get elementType',
      'elementIsComplex': 'bool get elementIsComplex',
      'min': 'int? get min',
      'contentType': 'String? get contentType',
      'sectionType': 'String? get sectionType',
      'enumType': 'String? get enumType',
      'enumValues': 'List<String> get enumValues',
      'type': 'String? get type',
      'formFields': 'List<FormFieldSpec> get formFields',
      'annotations': 'List<SpecAnnotation> get annotations',
      'isExpandable': 'bool get isExpandable',
    },
  );
}

// =============================================================================
// SpecClass Bridge
// =============================================================================

BridgedClass _createSpecClassBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.SpecClass,
    name: 'SpecClass',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecClass,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SpecClass');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final doc = D4.getOptionalNamedArg<String?>(named, 'doc');
        final help = D4.getOptionalNamedArg<String?>(named, 'help');
        final mapsTo = D4.getOptionalNamedArg<String?>(named, 'mapsTo');
        final detailedIn = D4.getOptionalNamedArg<String?>(named, 'detailedIn');
        final fields = named.containsKey('fields') && named['fields'] != null
            ? D4.coerceList<$tom_som_dart_runtime_5.SpecField>(named['fields'], 'fields')
            : const <$tom_som_dart_runtime_5.SpecField>[];
        final annotations = named.containsKey('annotations') && named['annotations'] != null
            ? D4.coerceList<$tom_som_dart_runtime_5.SpecAnnotation>(named['annotations'], 'annotations')
            : const <$tom_som_dart_runtime_5.SpecAnnotation>[];
        return $tom_som_dart_runtime_5.SpecClass(name: name, sectionId: sectionId, doc: doc, help: help, mapsTo: mapsTo, detailedIn: detailedIn, fields: fields, annotations: annotations);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecClass');
        if (positional.isEmpty) {
          throw ArgumentError('SpecClass: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_5.SpecClass.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').name,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').sectionId,
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').doc,
      'help': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').help,
      'mapsTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').mapsTo,
      'detailedIn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').detailedIn,
      'fields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').fields,
      'annotations': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass').annotations,
    },
    methods: {
      'fieldNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'fieldNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'fieldNamed');
        return t.fieldNamed(name);
      },
      'annotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'annotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotation');
        return t.annotation(name);
      },
    },
    constructorSignatures: {
      '': 'SpecClass({required String name, String? sectionId, String? doc, String? help, String? mapsTo, String? detailedIn, List<SpecField> fields = const [], List<SpecAnnotation> annotations = const []})',
      'fromJson': 'factory SpecClass.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'fieldNamed': 'SpecField? fieldNamed(String name)',
      'annotation': 'SpecAnnotation? annotation(String name)',
    },
    getterSignatures: {
      'name': 'String get name',
      'sectionId': 'String? get sectionId',
      'doc': 'String? get doc',
      'help': 'String? get help',
      'mapsTo': 'String? get mapsTo',
      'detailedIn': 'String? get detailedIn',
      'fields': 'List<SpecField> get fields',
      'annotations': 'List<SpecAnnotation> get annotations',
    },
  );
}

// =============================================================================
// SpecRoot Bridge
// =============================================================================

BridgedClass _createSpecRootBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.SpecRoot,
    name: 'SpecRoot',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecRoot,
    constructors: {
      '': (visitor, positional, named) {
        final type = D4.getRequiredNamedArg<String>(named, 'type', 'SpecRoot');
        final title = D4.getRequiredNamedArg<String>(named, 'title', 'SpecRoot');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final description = D4.getOptionalNamedArg<String?>(named, 'description');
        final doc = D4.getOptionalNamedArg<String?>(named, 'doc');
        return $tom_som_dart_runtime_5.SpecRoot(type: type, title: title, sectionId: sectionId, description: description, doc: doc);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecRoot');
        if (positional.isEmpty) {
          throw ArgumentError('SpecRoot: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_5.SpecRoot.fromJson(j);
      },
    },
    getters: {
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecRoot>(target, 'SpecRoot').type,
      'title': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecRoot>(target, 'SpecRoot').title,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecRoot>(target, 'SpecRoot').sectionId,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecRoot>(target, 'SpecRoot').description,
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecRoot>(target, 'SpecRoot').doc,
    },
    constructorSignatures: {
      '': 'SpecRoot({required String type, required String title, String? sectionId, String? description, String? doc})',
      'fromJson': 'factory SpecRoot.fromJson(Map<String, dynamic> j)',
    },
    getterSignatures: {
      'type': 'String get type',
      'title': 'String get title',
      'sectionId': 'String? get sectionId',
      'description': 'String? get description',
      'doc': 'String? get doc',
    },
  );
}

// =============================================================================
// SpecModel Bridge
// =============================================================================

BridgedClass _createSpecModelBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.SpecModel,
    name: 'SpecModel',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecModel,
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('roots') || named['roots'] == null) {
          throw ArgumentError('SpecModel: Missing required named argument "roots"');
        }
        final roots = D4.coerceList<$tom_som_dart_runtime_5.SpecRoot>(named['roots'], 'roots');
        if (!named.containsKey('classes') || named['classes'] == null) {
          throw ArgumentError('SpecModel: Missing required named argument "classes"');
        }
        final classes = D4.coerceMap<String, $tom_som_dart_runtime_5.SpecClass>(named['classes'], 'classes');
        final modelVersion = D4.getNamedArgWithDefault<int>(named, 'modelVersion', 0);
        final modelVersionLabel = D4.getOptionalNamedArg<String?>(named, 'modelVersionLabel');
        return $tom_som_dart_runtime_5.SpecModel(roots: roots, classes: classes, modelVersion: modelVersion, modelVersionLabel: modelVersionLabel);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecModel');
        if (positional.isEmpty) {
          throw ArgumentError('SpecModel: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_5.SpecModel.fromJson(j);
      },
    },
    getters: {
      'roots': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecModel>(target, 'SpecModel').roots,
      'classes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecModel>(target, 'SpecModel').classes,
      'modelVersion': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecModel>(target, 'SpecModel').modelVersion,
      'modelVersionLabel': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecModel>(target, 'SpecModel').modelVersionLabel,
    },
    methods: {
      'classNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecModel>(target, 'SpecModel');
        D4.requireMinArgs(positional, 1, 'classNamed');
        final name = D4.getRequiredArg<String?>(positional, 0, 'name', 'classNamed');
        return t.classNamed(name);
      },
    },
    constructorSignatures: {
      '': 'SpecModel({required List<SpecRoot> roots, required Map<String, SpecClass> classes, int modelVersion = 0, String? modelVersionLabel})',
      'fromJson': 'factory SpecModel.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'classNamed': 'SpecClass? classNamed(String? name)',
    },
    getterSignatures: {
      'roots': 'List<SpecRoot> get roots',
      'classes': 'Map<String, SpecClass> get classes',
      'modelVersion': 'int get modelVersion',
      'modelVersionLabel': 'String? get modelVersionLabel',
    },
  );
}

// =============================================================================
// SpecCreationError Bridge
// =============================================================================

BridgedClass _createSpecCreationErrorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_6.SpecCreationError,
    name: 'SpecCreationError',
    isAssignable: (v) => v is $tom_som_dart_runtime_6.SpecCreationError,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        final parentPath = D4.getRequiredNamedArg<String>(named, 'parentPath', 'SpecCreationError');
        final childSegment = D4.getRequiredNamedArg<String>(named, 'childSegment', 'SpecCreationError');
        final code = D4.getRequiredNamedArg<$tom_som_dart_runtime_6.SpecCreationCode>(named, 'code', 'SpecCreationError');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'SpecCreationError');
        return $tom_som_dart_runtime_6.SpecCreationError(parentPath: parentPath, childSegment: childSegment, code: code, message: message);
      },
    },
    getters: {
      'parentPath': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecCreationError>(target, 'SpecCreationError').parentPath,
      'childSegment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecCreationError>(target, 'SpecCreationError').childSegment,
      'code': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecCreationError>(target, 'SpecCreationError').code,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecCreationError>(target, 'SpecCreationError').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_6.SpecCreationError>(target, 'SpecCreationError');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SpecCreationError({required String parentPath, required String childSegment, required SpecCreationCode code, required String message})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'parentPath': 'String get parentPath',
      'childSegment': 'String get childSegment',
      'code': 'SpecCreationCode get code',
      'message': 'String get message',
    },
  );
}

// =============================================================================
// SpecNodeCreator Bridge
// =============================================================================

BridgedClass _createSpecNodeCreatorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_6.SpecNodeCreator,
    name: 'SpecNodeCreator',
    isAssignable: (v) => v is $tom_som_dart_runtime_6.SpecNodeCreator,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecNodeCreator');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecModel>(positional, 0, 'model', 'SpecNodeCreator');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_2.SpecDocument>(positional, 1, 'document', 'SpecNodeCreator');
        return $tom_som_dart_runtime_6.SpecNodeCreator(model, document);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecNodeCreator>(target, 'SpecNodeCreator').model,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecNodeCreator>(target, 'SpecNodeCreator').document,
    },
    methods: {
      'add': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_6.SpecNodeCreator>(target, 'SpecNodeCreator');
        D4.requireMinArgs(positional, 2, 'add');
        final parentPath = D4.getRequiredArg<String>(positional, 0, 'parentPath', 'add');
        final childSegment = D4.getRequiredArg<String>(positional, 1, 'childSegment', 'add');
        final itemId = D4.getOptionalNamedArg<String?>(named, 'itemId');
        return t.add(parentPath, childSegment, itemId: itemId);
      },
    },
    constructorSignatures: {
      '': 'const SpecNodeCreator(SpecModel model, SpecDocument document)',
    },
    methodSignatures: {
      'add': 'String add(String parentPath, String childSegment, {String? itemId})',
    },
    getterSignatures: {
      'model': 'SpecModel get model',
      'document': 'SpecDocument get document',
    },
  );
}

// =============================================================================
// SpecMatchSpan Bridge
// =============================================================================

BridgedClass _createSpecMatchSpanBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SpecMatchSpan,
    name: 'SpecMatchSpan',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SpecMatchSpan,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecMatchSpan');
        final start = D4.getRequiredArg<int>(positional, 0, 'start', 'SpecMatchSpan');
        final end = D4.getRequiredArg<int>(positional, 1, 'end', 'SpecMatchSpan');
        return $tom_som_dart_runtime_8.SpecMatchSpan(start, end);
      },
    },
    getters: {
      'start': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecMatchSpan>(target, 'SpecMatchSpan').start,
      'end': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecMatchSpan>(target, 'SpecMatchSpan').end,
      'hashCode': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecMatchSpan>(target, 'SpecMatchSpan').hashCode,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecMatchSpan>(target, 'SpecMatchSpan');
        return t.toString();
      },
      '==': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecMatchSpan>(target, 'SpecMatchSpan');
        // GEN-103: Dart spec — non-null == null is always false.
        if (positional.isEmpty || positional[0] == null) return false;
        final other = D4.getRequiredArg<Object>(positional, 0, 'other', 'operator==');
        return t == other;
      },
    },
    constructorSignatures: {
      '': 'const SpecMatchSpan(int start, int end)',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'start': 'int get start',
      'end': 'int get end',
      'hashCode': 'int get hashCode',
    },
  );
}

// =============================================================================
// SpecQueryMatch Bridge
// =============================================================================

BridgedClass _createSpecQueryMatchBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SpecQueryMatch,
    name: 'SpecQueryMatch',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SpecQueryMatch,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecQueryMatch');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_9.SpecNodeKind>(named, 'kind', 'SpecQueryMatch');
        final classId = D4.getOptionalNamedArg<String?>(named, 'classId');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final snippet = D4.getOptionalNamedArg<String?>(named, 'snippet');
        final matchSpans = named.containsKey('matchSpans') && named['matchSpans'] != null
            ? D4.coerceList<$tom_som_dart_runtime_8.SpecMatchSpan>(named['matchSpans'], 'matchSpans')
            : const <$tom_som_dart_runtime_8.SpecMatchSpan>[];
        return $tom_som_dart_runtime_8.SpecQueryMatch(path: path, kind: kind, classId: classId, headline: headline, snippet: snippet, matchSpans: matchSpans);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch').path,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch').kind,
      'classId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch').classId,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch').headline,
      'snippet': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch').snippet,
      'matchSpans': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch').matchSpans,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryMatch>(target, 'SpecQueryMatch');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SpecQueryMatch({required String path, required SpecNodeKind kind, String? classId, String? headline, String? snippet, List<SpecMatchSpan> matchSpans = const []})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'path': 'String get path',
      'kind': 'SpecNodeKind get kind',
      'classId': 'String? get classId',
      'headline': 'String? get headline',
      'snippet': 'String? get snippet',
      'matchSpans': 'List<SpecMatchSpan> get matchSpans',
    },
  );
}

// =============================================================================
// SpecQuery Bridge
// =============================================================================

BridgedClass _createSpecQueryBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SpecQuery,
    name: 'SpecQuery',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SpecQuery,
    constructors: {
      '': (visitor, positional, named) {
        final text = D4.getOptionalNamedArg<String?>(named, 'text');
        final regex = D4.getNamedArgWithDefault<bool>(named, 'regex', false);
        final caseInsensitive = D4.getNamedArgWithDefault<bool>(named, 'caseInsensitive', false);
        final kinds = D4.coerceSetOrNull<$tom_som_dart_runtime_9.SpecNodeKind>(named['kinds'], 'kinds');
        final className = D4.getOptionalNamedArg<String?>(named, 'className');
        final sectionIdExact = D4.getOptionalNamedArg<String?>(named, 'sectionIdExact');
        final sectionIdPrefix = D4.getOptionalNamedArg<String?>(named, 'sectionIdPrefix');
        final pathGlob = D4.getOptionalNamedArg<String?>(named, 'pathGlob');
        final mapsTo = D4.getOptionalNamedArg<String?>(named, 'mapsTo');
        final detailedIn = D4.getOptionalNamedArg<String?>(named, 'detailedIn');
        final state = D4.getOptionalNamedArg<$tom_som_dart_runtime_8.SpecStateFilter?>(named, 'state');
        return $tom_som_dart_runtime_8.SpecQuery(text: text, regex: regex, caseInsensitive: caseInsensitive, kinds: kinds, className: className, sectionIdExact: sectionIdExact, sectionIdPrefix: sectionIdPrefix, pathGlob: pathGlob, mapsTo: mapsTo, detailedIn: detailedIn, state: state);
      },
    },
    getters: {
      'text': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').text,
      'regex': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').regex,
      'caseInsensitive': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').caseInsensitive,
      'kinds': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').kinds,
      'className': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').className,
      'sectionIdExact': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').sectionIdExact,
      'sectionIdPrefix': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').sectionIdPrefix,
      'pathGlob': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').pathGlob,
      'mapsTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').mapsTo,
      'detailedIn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').detailedIn,
      'state': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQuery>(target, 'SpecQuery').state,
    },
    constructorSignatures: {
      '': 'const SpecQuery({String? text, bool regex = false, bool caseInsensitive = false, Set<SpecNodeKind>? kinds, String? className, String? sectionIdExact, String? sectionIdPrefix, String? pathGlob, String? mapsTo, String? detailedIn, SpecStateFilter? state})',
    },
    getterSignatures: {
      'text': 'String? get text',
      'regex': 'bool get regex',
      'caseInsensitive': 'bool get caseInsensitive',
      'kinds': 'Set<SpecNodeKind>? get kinds',
      'className': 'String? get className',
      'sectionIdExact': 'String? get sectionIdExact',
      'sectionIdPrefix': 'String? get sectionIdPrefix',
      'pathGlob': 'String? get pathGlob',
      'mapsTo': 'String? get mapsTo',
      'detailedIn': 'String? get detailedIn',
      'state': 'SpecStateFilter? get state',
    },
  );
}

// =============================================================================
// SpecQueryEngine Bridge
// =============================================================================

BridgedClass _createSpecQueryEngineBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SpecQueryEngine,
    name: 'SpecQueryEngine',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SpecQueryEngine,
    constructors: {
      '': (visitor, positional, named) {
        final model = D4.getRequiredNamedArg<$tom_som_dart_runtime_5.SpecModel>(named, 'model', 'SpecQueryEngine');
        final document = D4.getRequiredNamedArg<$tom_som_dart_runtime_2.SpecDocument>(named, 'document', 'SpecQueryEngine');
        return $tom_som_dart_runtime_8.SpecQueryEngine(model: model, document: document);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryEngine>(target, 'SpecQueryEngine').model,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryEngine>(target, 'SpecQueryEngine').document,
    },
    methods: {
      'query': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryEngine>(target, 'SpecQueryEngine');
        D4.requireMinArgs(positional, 1, 'query');
        final query = D4.getRequiredArg<$tom_som_dart_runtime_8.SpecQuery>(positional, 0, 'query', 'query');
        return t.query(query);
      },
    },
    constructorSignatures: {
      '': 'SpecQueryEngine({required SpecModel model, required SpecDocument document})',
    },
    methodSignatures: {
      'query': 'SpecQueryCursor query(SpecQuery query)',
    },
    getterSignatures: {
      'model': 'SpecModel get model',
      'document': 'SpecDocument get document',
    },
  );
}

// =============================================================================
// SpecQueryCursor Bridge
// =============================================================================

BridgedClass _createSpecQueryCursorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SpecQueryCursor,
    name: 'SpecQueryCursor',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SpecQueryCursor,
    constructors: {
    },
    getters: {
      'count': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryCursor>(target, 'SpecQueryCursor').count,
    },
    methods: {
      'next': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryCursor>(target, 'SpecQueryCursor');
        return t.next();
      },
      'take': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryCursor>(target, 'SpecQueryCursor');
        D4.requireMinArgs(positional, 1, 'take');
        final n = D4.getRequiredArg<int>(positional, 0, 'n', 'take');
        return t.take(n);
      },
      'toList': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SpecQueryCursor>(target, 'SpecQueryCursor');
        return t.toList();
      },
    },
    methodSignatures: {
      'next': 'SpecQueryMatch? next()',
      'take': 'List<SpecQueryMatch> take(int n)',
      'toList': 'List<SpecQueryMatch> toList()',
    },
    getterSignatures: {
      'count': 'int get count',
    },
  );
}

// =============================================================================
// SpecResolution Bridge
// =============================================================================

BridgedClass _createSpecResolutionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_9.SpecResolution,
    name: 'SpecResolution',
    isAssignable: (v) => v is $tom_som_dart_runtime_9.SpecResolution,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecResolution');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_9.SpecNodeKind>(named, 'kind', 'SpecResolution');
        final root = D4.getRequiredNamedArg<$tom_som_dart_runtime_5.SpecRoot>(named, 'root', 'SpecResolution');
        final field = D4.getOptionalNamedArg<$tom_som_dart_runtime_5.SpecField?>(named, 'field');
        final targetClass = D4.getOptionalNamedArg<$tom_som_dart_runtime_5.SpecClass?>(named, 'targetClass');
        return $tom_som_dart_runtime_9.SpecResolution(path: path, kind: kind, root: root, field: field, targetClass: targetClass);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecResolution>(target, 'SpecResolution').path,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecResolution>(target, 'SpecResolution').kind,
      'root': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecResolution>(target, 'SpecResolution').root,
      'field': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecResolution>(target, 'SpecResolution').field,
      'targetClass': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecResolution>(target, 'SpecResolution').targetClass,
      'isValueLeaf': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecResolution>(target, 'SpecResolution').isValueLeaf,
    },
    constructorSignatures: {
      '': 'const SpecResolution({required String path, required SpecNodeKind kind, required SpecRoot root, SpecField? field, SpecClass? targetClass})',
    },
    getterSignatures: {
      'path': 'String get path',
      'kind': 'SpecNodeKind get kind',
      'root': 'SpecRoot get root',
      'field': 'SpecField? get field',
      'targetClass': 'SpecClass? get targetClass',
      'isValueLeaf': 'bool get isValueLeaf',
    },
  );
}

// =============================================================================
// SpecReflection Bridge
// =============================================================================

BridgedClass _createSpecReflectionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_9.SpecReflection,
    name: 'SpecReflection',
    isAssignable: (v) => v is $tom_som_dart_runtime_9.SpecReflection,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecReflection');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecModel>(positional, 0, 'model', 'SpecReflection');
        return $tom_som_dart_runtime_9.SpecReflection(model);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection').model,
      'roots': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection').roots,
      'classes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection').classes,
    },
    methods: {
      'classNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'classNamed');
        final name = D4.getRequiredArg<String?>(positional, 0, 'name', 'classNamed');
        return t.classNamed(name);
      },
      'fieldsOf': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'fieldsOf');
        final className = D4.getRequiredArg<String>(positional, 0, 'className', 'fieldsOf');
        return t.fieldsOf(className);
      },
      'annotationsOf': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'annotationsOf');
        final className = D4.getRequiredArg<String>(positional, 0, 'className', 'annotationsOf');
        return t.annotationsOf(className);
      },
      'fieldAnnotations': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 2, 'fieldAnnotations');
        final className = D4.getRequiredArg<String>(positional, 0, 'className', 'fieldAnnotations');
        final fieldName = D4.getRequiredArg<String>(positional, 1, 'fieldName', 'fieldAnnotations');
        return t.fieldAnnotations(className, fieldName);
      },
      'rootSegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'rootSegment');
        final root = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecRoot>(positional, 0, 'root', 'rootSegment');
        return t.rootSegment(root);
      },
      'fieldSegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'fieldSegment');
        final field = D4.getRequiredArg<$tom_som_dart_runtime_5.SpecField>(positional, 0, 'field', 'fieldSegment');
        return t.fieldSegment(field);
      },
      'rootForSegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'rootForSegment');
        final segment = D4.getRequiredArg<String>(positional, 0, 'segment', 'rootForSegment');
        return t.rootForSegment(segment);
      },
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_9.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'resolve');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'resolve');
        return t.resolve(path);
      },
    },
    constructorSignatures: {
      '': 'const SpecReflection(SpecModel model)',
    },
    methodSignatures: {
      'classNamed': 'SpecClass? classNamed(String? name)',
      'fieldsOf': 'List<SpecField> fieldsOf(String className)',
      'annotationsOf': 'List<SpecAnnotation> annotationsOf(String className)',
      'fieldAnnotations': 'List<SpecAnnotation> fieldAnnotations(String className, String fieldName)',
      'rootSegment': 'String rootSegment(SpecRoot root)',
      'fieldSegment': 'String fieldSegment(SpecField field)',
      'rootForSegment': 'SpecRoot? rootForSegment(String segment)',
      'resolve': 'SpecResolution? resolve(String path)',
    },
    getterSignatures: {
      'model': 'SpecModel get model',
      'roots': 'Iterable<SpecRoot> get roots',
      'classes': 'Iterable<SpecClass> get classes',
    },
  );
}

// =============================================================================
// SpecValidationError Bridge
// =============================================================================

BridgedClass _createSpecValidationErrorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_10.SpecValidationError,
    name: 'SpecValidationError',
    isAssignable: (v) => v is $tom_som_dart_runtime_10.SpecValidationError,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecValidationError');
        final code = D4.getRequiredNamedArg<$tom_som_dart_runtime_10.SpecValidationCode>(named, 'code', 'SpecValidationError');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'SpecValidationError');
        return $tom_som_dart_runtime_10.SpecValidationError(path: path, code: code, message: message);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_10.SpecValidationError>(target, 'SpecValidationError').path,
      'code': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_10.SpecValidationError>(target, 'SpecValidationError').code,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_10.SpecValidationError>(target, 'SpecValidationError').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_10.SpecValidationError>(target, 'SpecValidationError');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SpecValidationError({required String path, required SpecValidationCode code, required String message})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'path': 'String get path',
      'code': 'SpecValidationCode get code',
      'message': 'String get message',
    },
  );
}

