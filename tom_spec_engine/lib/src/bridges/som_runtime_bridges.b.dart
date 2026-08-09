// D4rt Bridge - Generated file, do not edit
// Sources: 19 files
// Generated: 2026-08-09T17:09:28.702077

// ignore_for_file: unused_import, deprecated_member_use, prefer_function_declarations_over_variables, implementation_imports, sort_child_properties_last, non_constant_identifier_names, avoid_function_literals_in_foreach_calls, invalid_use_of_protected_member, unnecessary_non_null_assertion, invalid_use_of_visible_for_testing_member, unnecessary_cast, unused_local_variable, no_leading_underscores_for_local_identifiers, prefer_is_empty, unnecessary_question_mark, unreachable_switch_case, unintended_html_in_doc_comment, empty_constructor_bodies, prefer_const_constructors_in_immutables, prefer_final_fields, unused_field, must_call_super, no_logic_in_create_state, use_key_in_widget_constructors, annotate_overrides, non_const_argument_for_const_parameter, unnecessary_import

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/tom_d4rt.dart';

import 'package:tom_som_dart_runtime/src/docspecs_validator.dart' as $tom_som_dart_runtime_1;
import 'package:tom_som_dart_runtime/src/som_facade.dart' as $tom_som_dart_runtime_2;
import 'package:tom_som_dart_runtime/src/spec_annotation_display.dart' as $tom_som_dart_runtime_3;
import 'package:tom_som_dart_runtime/src/spec_document.dart' as $tom_som_dart_runtime_4;
import 'package:tom_som_dart_runtime/src/spec_document_markdown.dart' as $tom_som_dart_runtime_5;
import 'package:tom_som_dart_runtime/src/spec_document_yaml.dart' as $tom_som_dart_runtime_6;
import 'package:tom_som_dart_runtime/src/spec_editor.dart' as $tom_som_dart_runtime_7;
import 'package:tom_som_dart_runtime/src/spec_meta.dart' as $tom_som_dart_runtime_8;
import 'package:tom_som_dart_runtime/src/spec_meta_bridge.dart' as $tom_som_dart_runtime_9;
import 'package:tom_som_dart_runtime/src/spec_meta_diff.dart' as $tom_som_dart_runtime_10;
import 'package:tom_som_dart_runtime/src/spec_model.dart' as $tom_som_dart_runtime_11;
import 'package:tom_som_dart_runtime/src/spec_node_creation.dart' as $tom_som_dart_runtime_12;
import 'package:tom_som_dart_runtime/src/spec_paths.dart' as $tom_som_dart_runtime_13;
import 'package:tom_som_dart_runtime/src/spec_query.dart' as $tom_som_dart_runtime_14;
import 'package:tom_som_dart_runtime/src/spec_reflection.dart' as $tom_som_dart_runtime_15;
import 'package:tom_som_dart_runtime/src/spec_section_id.dart' as $tom_som_dart_runtime_16;
import 'package:tom_som_dart_runtime/src/spec_serialization_order.dart' as $tom_som_dart_runtime_17;
import 'package:tom_som_dart_runtime/src/spec_typed_values.dart' as $tom_som_dart_runtime_18;
import 'package:tom_som_dart_runtime/src/spec_validator.dart' as $tom_som_dart_runtime_19;

/// Bridge class for som_runtime module.
class SomRuntimeBridge {
  /// Returns all bridge class definitions.
  ///
  /// Eager — building every class. Prefer [bridgeClassThunks] +
  /// [bridgeClassTypes] for lazy registration (Step #17); this remains
  /// for diagnostics and callers that need the full list.
  static List<BridgedClass> bridgeClasses() {
    return [
      _createDocSpecsViolationBridge(),
      _createDocSpecsSectionBridge(),
      _createDocSpecsDocumentBridge(),
      _createDocSpecsPatternCheckBridge(),
      _createDocSpecsSubsectionRuleBridge(),
      _createDocSpecsSectionTypeBridge(),
      _createDocSpecsFormFieldBridge(),
      _createDocSpecsFormTypeBridge(),
      _createDocSpecsDocumentSectionBridge(),
      _createDocSpecsSchemaBridge(),
      _createDocSpecsValidatorBridge(),
      _createSpecChipBridge(),
      _createSpecRowExtrasBridge(),
      _createSomNodeBridge(),
      _createSomScalarBridge(),
      _createSomListBridge(),
      _createSomVersionExceptionBridge(),
      _createSpecDocumentBridge(),
      _createSpecDocumentStateBridge(),
      _createSpecMarkdownRejectionBridge(),
      _createSpecMarkdownResultBridge(),
      _createSpecDocumentMarkdownBridge(),
      _createMarkdownFenceTrackerBridge(),
      _createSpecYamlFormatExceptionBridge(),
      _createSpecYamlContentsBridge(),
      _createSpecDocumentYamlBridge(),
      _createSpecEditorBridge(),
      _createSomContentTypeMetaBridge(),
      _createSomFormFieldMetaBridge(),
      _createSomFormMetaBridge(),
      _createSomDocMetaBridge(),
      _createSomMetaExtraBridge(),
      _createSomMetaNodeBridge(),
      _createSomMetaTreeBridge(),
      _createSomMetaRefBridge(),
      _createSomListMetaRefBridge(),
      _createSpecAnnotationBridge(),
      _createFormFieldSpecBridge(),
      _createKindLinkBridge(),
      _createStandardReferencesBridge(),
      _createSpecFieldBridge(),
      _createOneOfGroupBridge(),
      _createSpecClassBridge(),
      _createSpecRootBridge(),
      _createSpecModelStampCheckBridge(),
      _createSpecModelBridge(),
      _createAnnotatedSpecNodeBridge(),
      _createSpecCreationErrorBridge(),
      _createSpecNodeCreatorBridge(),
      _createSpecMatchSpanBridge(),
      _createSpecNodeProjectionBridge(),
      _createSpecQueryMatchBridge(),
      _createSpecQueryBridge(),
      _createSpecQueryEngineBridge(),
      _createSpecQueryCursorBridge(),
      _createSpecSectionIdCollisionBridge(),
      _createSpecResolutionBridge(),
      _createSpecReflectionBridge(),
      _createSpecSerializationOrderBridge(),
      _createSpecValidationErrorBridge(),
    ];
  }

  /// Returns deferred factory thunks keyed by class name.
  ///
  /// Each thunk builds one class's [BridgedClass] on demand. Plugs into
  /// the interpreter's lazy registry via [registerBridges] (Step #17).
  static Map<String, BridgedClass Function()> bridgeClassThunks() {
    return {
      'DocSpecsViolation': _createDocSpecsViolationBridge,
      'DocSpecsSection': _createDocSpecsSectionBridge,
      'DocSpecsDocument': _createDocSpecsDocumentBridge,
      'DocSpecsPatternCheck': _createDocSpecsPatternCheckBridge,
      'DocSpecsSubsectionRule': _createDocSpecsSubsectionRuleBridge,
      'DocSpecsSectionType': _createDocSpecsSectionTypeBridge,
      'DocSpecsFormField': _createDocSpecsFormFieldBridge,
      'DocSpecsFormType': _createDocSpecsFormTypeBridge,
      'DocSpecsDocumentSection': _createDocSpecsDocumentSectionBridge,
      'DocSpecsSchema': _createDocSpecsSchemaBridge,
      'DocSpecsValidator': _createDocSpecsValidatorBridge,
      'SpecChip': _createSpecChipBridge,
      'SpecRowExtras': _createSpecRowExtrasBridge,
      'SomNode': _createSomNodeBridge,
      'SomScalar': _createSomScalarBridge,
      'SomList': _createSomListBridge,
      'SomVersionException': _createSomVersionExceptionBridge,
      'SpecDocument': _createSpecDocumentBridge,
      'SpecDocumentState': _createSpecDocumentStateBridge,
      'SpecMarkdownRejection': _createSpecMarkdownRejectionBridge,
      'SpecMarkdownResult': _createSpecMarkdownResultBridge,
      'SpecDocumentMarkdown': _createSpecDocumentMarkdownBridge,
      'MarkdownFenceTracker': _createMarkdownFenceTrackerBridge,
      'SpecYamlFormatException': _createSpecYamlFormatExceptionBridge,
      'SpecYamlContents': _createSpecYamlContentsBridge,
      'SpecDocumentYaml': _createSpecDocumentYamlBridge,
      'SpecEditor': _createSpecEditorBridge,
      'SomContentTypeMeta': _createSomContentTypeMetaBridge,
      'SomFormFieldMeta': _createSomFormFieldMetaBridge,
      'SomFormMeta': _createSomFormMetaBridge,
      'SomDocMeta': _createSomDocMetaBridge,
      'SomMetaExtra': _createSomMetaExtraBridge,
      'SomMetaNode': _createSomMetaNodeBridge,
      'SomMetaTree': _createSomMetaTreeBridge,
      'SomMetaRef': _createSomMetaRefBridge,
      'SomListMetaRef': _createSomListMetaRefBridge,
      'SpecAnnotation': _createSpecAnnotationBridge,
      'FormFieldSpec': _createFormFieldSpecBridge,
      'KindLink': _createKindLinkBridge,
      'StandardReferences': _createStandardReferencesBridge,
      'SpecField': _createSpecFieldBridge,
      'OneOfGroup': _createOneOfGroupBridge,
      'SpecClass': _createSpecClassBridge,
      'SpecRoot': _createSpecRootBridge,
      'SpecModelStampCheck': _createSpecModelStampCheckBridge,
      'SpecModel': _createSpecModelBridge,
      'AnnotatedSpecNode': _createAnnotatedSpecNodeBridge,
      'SpecCreationError': _createSpecCreationErrorBridge,
      'SpecNodeCreator': _createSpecNodeCreatorBridge,
      'SpecMatchSpan': _createSpecMatchSpanBridge,
      'SpecNodeProjection': _createSpecNodeProjectionBridge,
      'SpecQueryMatch': _createSpecQueryMatchBridge,
      'SpecQuery': _createSpecQueryBridge,
      'SpecQueryEngine': _createSpecQueryEngineBridge,
      'SpecQueryCursor': _createSpecQueryCursorBridge,
      'SpecSectionIdCollision': _createSpecSectionIdCollisionBridge,
      'SpecResolution': _createSpecResolutionBridge,
      'SpecReflection': _createSpecReflectionBridge,
      'SpecSerializationOrder': _createSpecSerializationOrderBridge,
      'SpecValidationError': _createSpecValidationErrorBridge,
    };
  }

  /// Returns native [Type]s keyed by class name, parallel to
  /// [bridgeClassThunks] (Step #17). Used to register the native-type
  /// lookup thunk without building the BridgedClass.
  static Map<String, Type> bridgeClassTypes() {
    return {
      'DocSpecsViolation': $tom_som_dart_runtime_1.DocSpecsViolation,
      'DocSpecsSection': $tom_som_dart_runtime_1.DocSpecsSection,
      'DocSpecsDocument': $tom_som_dart_runtime_1.DocSpecsDocument,
      'DocSpecsPatternCheck': $tom_som_dart_runtime_1.DocSpecsPatternCheck,
      'DocSpecsSubsectionRule': $tom_som_dart_runtime_1.DocSpecsSubsectionRule,
      'DocSpecsSectionType': $tom_som_dart_runtime_1.DocSpecsSectionType,
      'DocSpecsFormField': $tom_som_dart_runtime_1.DocSpecsFormField,
      'DocSpecsFormType': $tom_som_dart_runtime_1.DocSpecsFormType,
      'DocSpecsDocumentSection': $tom_som_dart_runtime_1.DocSpecsDocumentSection,
      'DocSpecsSchema': $tom_som_dart_runtime_1.DocSpecsSchema,
      'DocSpecsValidator': $tom_som_dart_runtime_1.DocSpecsValidator,
      'SpecChip': $tom_som_dart_runtime_3.SpecChip,
      'SpecRowExtras': $tom_som_dart_runtime_3.SpecRowExtras,
      'SomNode': $tom_som_dart_runtime_2.SomNode,
      'SomScalar': $tom_som_dart_runtime_2.SomScalar,
      'SomList': $tom_som_dart_runtime_2.SomList,
      'SomVersionException': $tom_som_dart_runtime_2.SomVersionException,
      'SpecDocument': $tom_som_dart_runtime_4.SpecDocument,
      'SpecDocumentState': $tom_som_dart_runtime_4.SpecDocumentState,
      'SpecMarkdownRejection': $tom_som_dart_runtime_5.SpecMarkdownRejection,
      'SpecMarkdownResult': $tom_som_dart_runtime_5.SpecMarkdownResult,
      'SpecDocumentMarkdown': $tom_som_dart_runtime_5.SpecDocumentMarkdown,
      'MarkdownFenceTracker': $tom_som_dart_runtime_5.MarkdownFenceTracker,
      'SpecYamlFormatException': $tom_som_dart_runtime_6.SpecYamlFormatException,
      'SpecYamlContents': $tom_som_dart_runtime_6.SpecYamlContents,
      'SpecDocumentYaml': $tom_som_dart_runtime_6.SpecDocumentYaml,
      'SpecEditor': $tom_som_dart_runtime_7.SpecEditor,
      'SomContentTypeMeta': $tom_som_dart_runtime_8.SomContentTypeMeta,
      'SomFormFieldMeta': $tom_som_dart_runtime_8.SomFormFieldMeta,
      'SomFormMeta': $tom_som_dart_runtime_8.SomFormMeta,
      'SomDocMeta': $tom_som_dart_runtime_8.SomDocMeta,
      'SomMetaExtra': $tom_som_dart_runtime_8.SomMetaExtra,
      'SomMetaNode': $tom_som_dart_runtime_8.SomMetaNode,
      'SomMetaTree': $tom_som_dart_runtime_8.SomMetaTree,
      'SomMetaRef': $tom_som_dart_runtime_8.SomMetaRef,
      'SomListMetaRef': $tom_som_dart_runtime_8.SomListMetaRef,
      'SpecAnnotation': $tom_som_dart_runtime_11.SpecAnnotation,
      'FormFieldSpec': $tom_som_dart_runtime_11.FormFieldSpec,
      'KindLink': $tom_som_dart_runtime_11.KindLink,
      'StandardReferences': $tom_som_dart_runtime_11.StandardReferences,
      'SpecField': $tom_som_dart_runtime_11.SpecField,
      'OneOfGroup': $tom_som_dart_runtime_11.OneOfGroup,
      'SpecClass': $tom_som_dart_runtime_11.SpecClass,
      'SpecRoot': $tom_som_dart_runtime_11.SpecRoot,
      'SpecModelStampCheck': $tom_som_dart_runtime_11.SpecModelStampCheck,
      'SpecModel': $tom_som_dart_runtime_11.SpecModel,
      'AnnotatedSpecNode': $tom_som_dart_runtime_11.AnnotatedSpecNode,
      'SpecCreationError': $tom_som_dart_runtime_12.SpecCreationError,
      'SpecNodeCreator': $tom_som_dart_runtime_12.SpecNodeCreator,
      'SpecMatchSpan': $tom_som_dart_runtime_14.SpecMatchSpan,
      'SpecNodeProjection': $tom_som_dart_runtime_14.SpecNodeProjection,
      'SpecQueryMatch': $tom_som_dart_runtime_14.SpecQueryMatch,
      'SpecQuery': $tom_som_dart_runtime_14.SpecQuery,
      'SpecQueryEngine': $tom_som_dart_runtime_14.SpecQueryEngine,
      'SpecQueryCursor': $tom_som_dart_runtime_14.SpecQueryCursor,
      'SpecSectionIdCollision': $tom_som_dart_runtime_16.SpecSectionIdCollision,
      'SpecResolution': $tom_som_dart_runtime_15.SpecResolution,
      'SpecReflection': $tom_som_dart_runtime_15.SpecReflection,
      'SpecSerializationOrder': $tom_som_dart_runtime_17.SpecSerializationOrder,
      'SpecValidationError': $tom_som_dart_runtime_19.SpecValidationError,
    };
  }

  /// Returns a map of class names to their canonical source URIs.
  ///
  /// Used for deduplication when the same class is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> classSourceUris() {
    return {
      'DocSpecsViolation': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsSection': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsDocument': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsPatternCheck': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsSubsectionRule': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsSectionType': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsFormField': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsFormType': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsDocumentSection': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsSchema': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'DocSpecsValidator': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'SpecChip': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'SpecRowExtras': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'SomNode': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SomScalar': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SomList': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SomVersionException': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SpecDocument': 'package:tom_som_dart_runtime/src/spec_document.dart',
      'SpecDocumentState': 'package:tom_som_dart_runtime/src/spec_document.dart',
      'SpecMarkdownRejection': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecMarkdownResult': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecDocumentMarkdown': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'MarkdownFenceTracker': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SpecYamlFormatException': 'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'SpecYamlContents': 'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'SpecDocumentYaml': 'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'SpecEditor': 'package:tom_som_dart_runtime/src/spec_editor.dart',
      'SomContentTypeMeta': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomFormFieldMeta': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomFormMeta': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomDocMeta': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomMetaExtra': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomMetaNode': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomMetaTree': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomMetaRef': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SomListMetaRef': 'package:tom_som_dart_runtime/src/spec_meta.dart',
      'SpecAnnotation': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'FormFieldSpec': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'KindLink': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'StandardReferences': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecField': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'OneOfGroup': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecClass': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecRoot': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecModelStampCheck': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecModel': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'AnnotatedSpecNode': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'SpecCreationError': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'SpecNodeCreator': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'SpecMatchSpan': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecNodeProjection': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQueryMatch': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQuery': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQueryEngine': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecQueryCursor': 'package:tom_som_dart_runtime/src/spec_query.dart',
      'SpecSectionIdCollision': 'package:tom_som_dart_runtime/src/spec_section_id.dart',
      'SpecResolution': 'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'SpecReflection': 'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'SpecSerializationOrder': 'package:tom_som_dart_runtime/src/spec_serialization_order.dart',
      'SpecValidationError': 'package:tom_som_dart_runtime/src/spec_validator.dart',
    };
  }

  /// Returns a map of class names to their flattened (transitive)
  /// native supertype names (superclasses, interfaces and mixins).
  ///
  /// Fed to `BridgedClass.registerSupertypes` so interpreted subclasses
  /// of bridged classes pass `is`/subtype checks against bridged
  /// ancestors and the interface-proxy supertype walk resolves up the
  /// chain.
  static Map<String, List<String>> classSupertypes() {
    return {
      'SomScalar': ['SomNode'],
      'SomVersionException': ['Exception'],
      'SpecYamlFormatException': ['Exception'],
      'SomListMetaRef': ['SomMetaRef'],
      'SpecField': ['AnnotatedSpecNode'],
      'SpecClass': ['AnnotatedSpecNode'],
      'SpecCreationError': ['Exception'],
      'SpecSectionIdCollision': ['Exception'],
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
      BridgedEnumDefinition<$tom_som_dart_runtime_1.DocSpecsViolationRule>(
        name: 'DocSpecsViolationRule',
        values: $tom_som_dart_runtime_1.DocSpecsViolationRule.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_3.SpecChipRole>(
        name: 'SpecChipRole',
        values: $tom_som_dart_runtime_3.SpecChipRole.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_2.SomEditability>(
        name: 'SomEditability',
        values: $tom_som_dart_runtime_2.SomEditability.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_5.SpecMarkdownRejectReason>(
        name: 'SpecMarkdownRejectReason',
        values: $tom_som_dart_runtime_5.SpecMarkdownRejectReason.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_8.SomMetaKind>(
        name: 'SomMetaKind',
        values: $tom_som_dart_runtime_8.SomMetaKind.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_11.SpecFieldKind>(
        name: 'SpecFieldKind',
        values: $tom_som_dart_runtime_11.SpecFieldKind.values,
        staticMethods: {
          'parse': (visitor, positional, named, typeArgs) {
            return Function.apply($tom_som_dart_runtime_11.SpecFieldKind.parse, positional, named.map((k, v) => MapEntry(Symbol(k), v)));
          },
        },
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_12.SpecCreationCode>(
        name: 'SpecCreationCode',
        values: $tom_som_dart_runtime_12.SpecCreationCode.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_14.SpecStateFilter>(
        name: 'SpecStateFilter',
        values: $tom_som_dart_runtime_14.SpecStateFilter.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_15.SpecNodeKind>(
        name: 'SpecNodeKind',
        values: $tom_som_dart_runtime_15.SpecNodeKind.values,
      ),
      BridgedEnumDefinition<$tom_som_dart_runtime_19.SpecValidationCode>(
        name: 'SpecValidationCode',
        values: $tom_som_dart_runtime_19.SpecValidationCode.values,
      ),
    ];
  }

  /// Returns a map of enum names to their canonical source URIs.
  ///
  /// Used for deduplication when the same enum is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> enumSourceUris() {
    return {
      'DocSpecsViolationRule': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'SpecChipRole': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'SomEditability': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'SpecMarkdownRejectReason': 'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'SomMetaKind': 'package:tom_som_dart_runtime/src/spec_meta.dart',
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
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/docspecs_validator.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/som_facade.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_document.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_document_markdown.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_document_yaml.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_editor.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_meta.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_meta_bridge.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_meta_diff.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_model.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_node_creation.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_paths.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_query.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_section_id.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_reflection.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_serialization_order.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_typed_values.dart', show: null, hide: null),
      (source: 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart', target: 'package:tom_som_dart_runtime/src/spec_validator.dart', show: null, hide: null),
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

    // Register the flattened native supertype table so
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

    // GEN-107: Register library re-exports
    for (final r in bridgeReExports()) {
      interpreter.registerLibraryReExport(r.source, r.target, show: r.show, hide: r.hide);
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
      interpreter.registerGlobalVariable('kListItemSegment', $tom_som_dart_runtime_3.kListItemSegment, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kListItemSegment": $e');
    }
    try {
      interpreter.registerGlobalVariable('kSectionContentSegment', $tom_som_dart_runtime_3.kSectionContentSegment, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kSectionContentSegment": $e');
    }
    try {
      interpreter.registerGlobalVariable('kOneOfSegment', $tom_som_dart_runtime_3.kOneOfSegment, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kOneOfSegment": $e');
    }
    try {
      interpreter.registerGlobalVariable('kProjectionLabel', $tom_som_dart_runtime_3.kProjectionLabel, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kProjectionLabel": $e');
    }
    try {
      interpreter.registerGlobalVariable('kProjectionExplanation', $tom_som_dart_runtime_3.kProjectionExplanation, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kProjectionExplanation": $e');
    }
    try {
      interpreter.registerGlobalVariable('kUnusedChipLabel', $tom_som_dart_runtime_3.kUnusedChipLabel, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kUnusedChipLabel": $e');
    }
    try {
      interpreter.registerGlobalVariable('kReferencesChipLabel', $tom_som_dart_runtime_3.kReferencesChipLabel, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kReferencesChipLabel": $e');
    }
    try {
      interpreter.registerGlobalVariable('kSerializationOrderToggleLabel', $tom_som_dart_runtime_3.kSerializationOrderToggleLabel, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kSerializationOrderToggleLabel": $e');
    }
    try {
      interpreter.registerGlobalVariable('kRenderedAnnotations', $tom_som_dart_runtime_3.kRenderedAnnotations, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "kRenderedAnnotations": $e');
    }
    try {
      interpreter.registerGlobalVariable('projectionChip', $tom_som_dart_runtime_3.projectionChip, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "projectionChip": $e');
    }
    try {
      interpreter.registerGlobalVariable('unusedChip', $tom_som_dart_runtime_3.unusedChip, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "unusedChip": $e');
    }
    try {
      interpreter.registerGlobalVariable('referencesChip', $tom_som_dart_runtime_3.referencesChip, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_annotation_display.dart');
    } catch (e) {
      errors.add('Failed to register variable "referencesChip": $e');
    }
    try {
      interpreter.registerGlobalVariable('defaultMaxSnapshotAge', $tom_som_dart_runtime_11.defaultMaxSnapshotAge, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_model.dart');
    } catch (e) {
      errors.add('Failed to register variable "defaultMaxSnapshotAge": $e');
    }
    try {
      interpreter.registerGlobalVariable('kSpecPathSeparator', $tom_som_dart_runtime_13.kSpecPathSeparator, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_paths.dart');
    } catch (e) {
      errors.add('Failed to register variable "kSpecPathSeparator": $e');
    }
    try {
      interpreter.registerGlobalVariable('kSectionIdSlot', $tom_som_dart_runtime_16.kSectionIdSlot, importPath, sourceUri: 'package:tom_som_dart_runtime/src/spec_section_id.dart');
    } catch (e) {
      errors.add('Failed to register variable "kSectionIdSlot": $e');
    }

    if (errors.isNotEmpty) {
      throw StateError('Bridge registration errors (som_runtime):\n${errors.join("\n")}');
    }
  }

  /// Returns a map of global function names to their native implementations.
  static Map<String, NativeFunctionImpl> globalFunctions() {
    return {
      'docSpecsIdTransform': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'docSpecsIdTransform');
        final id = D4.getRequiredArg<String>(positional, 0, 'id', 'docSpecsIdTransform');
        return $tom_som_dart_runtime_1.docSpecsIdTransform(id);
      },
      'bindDocSpecsMarkdown': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 3, 'bindDocSpecsMarkdown');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'bindDocSpecsMarkdown');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 1, 'document', 'bindDocSpecsMarkdown');
        final text = D4.getRequiredArg<String>(positional, 2, 'text', 'bindDocSpecsMarkdown');
        return $tom_som_dart_runtime_1.bindDocSpecsMarkdown(model, document, text);
      },
      'kindChips': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'kindChips');
        final codeSpec = D4.getRequiredArg<$tom_som_dart_runtime_11.KindLink?>(positional, 0, 'codeSpec', 'kindChips');
        final followUp = D4.getRequiredArg<$tom_som_dart_runtime_11.KindLink?>(positional, 1, 'followUp', 'kindChips');
        return $tom_som_dart_runtime_3.kindChips(codeSpec, followUp);
      },
      'codeSpecKindChips': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'codeSpecKindChips');
        final link = D4.getRequiredArg<$tom_som_dart_runtime_11.KindLink?>(positional, 0, 'link', 'codeSpecKindChips');
        final suppressUnmapped = D4.getNamedArgWithDefault<bool>(named, 'suppressUnmapped', false);
        return $tom_som_dart_runtime_3.codeSpecKindChips(link, suppressUnmapped: suppressUnmapped);
      },
      'followUpKindChips': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'followUpKindChips');
        final link = D4.getRequiredArg<$tom_som_dart_runtime_11.KindLink?>(positional, 0, 'link', 'followUpKindChips');
        return $tom_som_dart_runtime_3.followUpKindChips(link);
      },
      'caseChips': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'caseChips');
        final field = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecField>(positional, 0, 'field', 'caseChips');
        return $tom_som_dart_runtime_3.caseChips(field);
      },
      'fieldChips': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'fieldChips');
        final field = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecField>(positional, 0, 'field', 'fieldChips');
        return $tom_som_dart_runtime_3.fieldChips(field);
      },
      'oneOfChips': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'oneOfChips');
        final group = D4.getRequiredArg<$tom_som_dart_runtime_11.OneOfGroup>(positional, 0, 'group', 'oneOfChips');
        return $tom_som_dart_runtime_3.oneOfChips(group);
      },
      'somEditabilityFor': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'somEditabilityFor');
        final generated = D4.getRequiredArg<String>(positional, 0, 'generated', 'somEditabilityFor');
        final documentVersion = D4.getRequiredArg<String?>(positional, 1, 'documentVersion', 'somEditabilityFor');
        return $tom_som_dart_runtime_2.somEditabilityFor(generated, documentVersion);
      },
      'checkSomModelVersion': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'checkSomModelVersion');
        final generated = D4.getRequiredArg<String>(positional, 0, 'generated', 'checkSomModelVersion');
        final documentVersion = D4.getRequiredArg<String?>(positional, 1, 'documentVersion', 'checkSomModelVersion');
        return $tom_som_dart_runtime_2.checkSomModelVersion(generated, documentVersion);
      },
      'buildSomMetaTree': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'buildSomMetaTree');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'buildSomMetaTree');
        final rootType = D4.getOptionalNamedArg<String?>(named, 'rootType');
        return $tom_som_dart_runtime_9.buildSomMetaTree(model, rootType: rootType);
      },
      'somMetaNodeDiff': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'somMetaNodeDiff');
        final a = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaNode>(positional, 0, 'a', 'somMetaNodeDiff');
        final b = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaNode>(positional, 1, 'b', 'somMetaNodeDiff');
        final at = D4.getNamedArgWithDefault<String>(named, 'at', '<root>');
        return $tom_som_dart_runtime_10.somMetaNodeDiff(a, b, at: at);
      },
      'somModelVersionString': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'somModelVersionString');
        final major = D4.getRequiredArg<int>(positional, 0, 'major', 'somModelVersionString');
        final label = D4.getRequiredArg<String?>(positional, 1, 'label', 'somModelVersionString');
        return $tom_som_dart_runtime_11.somModelVersionString(major, label);
      },
      'parseStampTimestamp': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parseStampTimestamp');
        final raw = D4.getRequiredArg<String?>(positional, 0, 'raw', 'parseStampTimestamp');
        return $tom_som_dart_runtime_11.parseStampTimestamp(raw);
      },
      'checkAddNode': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 4, 'checkAddNode');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'checkAddNode');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 1, 'document', 'checkAddNode');
        final parentPath = D4.getRequiredArg<String>(positional, 2, 'parentPath', 'checkAddNode');
        final childSegment = D4.getRequiredArg<String>(positional, 3, 'childSegment', 'checkAddNode');
        final itemId = D4.getOptionalNamedArg<String?>(named, 'itemId');
        return $tom_som_dart_runtime_12.checkAddNode(model, document, parentPath, childSegment, itemId: itemId);
      },
      'specPathJoin': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'specPathJoin');
        final parent = D4.getRequiredArg<String>(positional, 0, 'parent', 'specPathJoin');
        final segment = D4.getRequiredArg<String>(positional, 1, 'segment', 'specPathJoin');
        return $tom_som_dart_runtime_13.specPathJoin(parent, segment);
      },
      'specPathSegments': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'specPathSegments');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'specPathSegments');
        return $tom_som_dart_runtime_13.specPathSegments(path);
      },
      'specParentPath': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'specParentPath');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'specParentPath');
        return $tom_som_dart_runtime_13.specParentPath(path);
      },
      'listItemPath': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'listItemPath');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItemPath');
        final seq = D4.getRequiredArg<int>(positional, 1, 'seq', 'listItemPath');
        return $tom_som_dart_runtime_13.listItemPath(listPath, seq);
      },
      'splitListItemSegment': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'splitListItemSegment');
        final segment = D4.getRequiredArg<String>(positional, 0, 'segment', 'splitListItemSegment');
        return $tom_som_dart_runtime_13.splitListItemSegment(segment);
      },
      'encodeTwoLetterDate': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'encodeTwoLetterDate');
        final date = D4.getRequiredArg<DateTime>(positional, 0, 'date', 'encodeTwoLetterDate');
        return $tom_som_dart_runtime_16.encodeTwoLetterDate(date);
      },
      'sectionIdPatternPrefix': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'sectionIdPatternPrefix');
        final pattern = D4.getRequiredArg<String>(positional, 0, 'pattern', 'sectionIdPatternPrefix');
        return $tom_som_dart_runtime_16.sectionIdPatternPrefix(pattern);
      },
      'effectiveListItemSectionId': (visitor, positional, named, typeArgs) {
        final storedId = D4.getRequiredNamedArg<String?>(named, 'storedId', 'effectiveListItemSectionId');
        final pattern = D4.getRequiredNamedArg<String?>(named, 'pattern', 'effectiveListItemSectionId');
        final position = D4.getRequiredNamedArg<int>(named, 'position', 'effectiveListItemSectionId');
        final fallbackStem = D4.getRequiredNamedArg<String>(named, 'fallbackStem', 'effectiveListItemSectionId');
        return $tom_som_dart_runtime_16.effectiveListItemSectionId(storedId: storedId, pattern: pattern, position: position, fallbackStem: fallbackStem);
      },
      'generateListItemSectionId': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 3, 'generateListItemSectionId');
        final pattern = D4.getRequiredArg<String>(positional, 0, 'pattern', 'generateListItemSectionId');
        final date = D4.getRequiredArg<DateTime>(positional, 1, 'date', 'generateListItemSectionId');
        final existingIds = D4.getRequiredArg<Iterable<String>>(positional, 2, 'existingIds', 'generateListItemSectionId');
        return $tom_som_dart_runtime_16.generateListItemSectionId(pattern, date, existingIds);
      },
      'somParseInt': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somParseInt');
        final raw = D4.getRequiredArg<String?>(positional, 0, 'raw', 'somParseInt');
        return $tom_som_dart_runtime_18.somParseInt(raw);
      },
      'somFormatInt': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somFormatInt');
        final value = D4.getRequiredArg<int?>(positional, 0, 'value', 'somFormatInt');
        return $tom_som_dart_runtime_18.somFormatInt(value);
      },
      'somParseDouble': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somParseDouble');
        final raw = D4.getRequiredArg<String?>(positional, 0, 'raw', 'somParseDouble');
        return $tom_som_dart_runtime_18.somParseDouble(raw);
      },
      'somFormatDouble': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somFormatDouble');
        final value = D4.getRequiredArg<double?>(positional, 0, 'value', 'somFormatDouble');
        return $tom_som_dart_runtime_18.somFormatDouble(value);
      },
      'somParseNum': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somParseNum');
        final raw = D4.getRequiredArg<String?>(positional, 0, 'raw', 'somParseNum');
        return $tom_som_dart_runtime_18.somParseNum(raw);
      },
      'somFormatNum': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somFormatNum');
        final value = D4.getRequiredArg<num?>(positional, 0, 'value', 'somFormatNum');
        return $tom_som_dart_runtime_18.somFormatNum(value);
      },
      'somParseBool': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somParseBool');
        final raw = D4.getRequiredArg<String?>(positional, 0, 'raw', 'somParseBool');
        return $tom_som_dart_runtime_18.somParseBool(raw);
      },
      'somFormatBool': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'somFormatBool');
        final value = D4.getRequiredArg<bool?>(positional, 0, 'value', 'somFormatBool');
        return $tom_som_dart_runtime_18.somFormatBool(value);
      },
      'somParseEnumName': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'somParseEnumName');
        final raw = D4.getRequiredArg<String?>(positional, 0, 'raw', 'somParseEnumName');
        final values = D4.getRequiredArg<List<String>>(positional, 1, 'values', 'somParseEnumName');
        return $tom_som_dart_runtime_18.somParseEnumName(raw, values);
      },
      'somFormatEnumName': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'somFormatEnumName');
        final name = D4.getRequiredArg<String?>(positional, 0, 'name', 'somFormatEnumName');
        final values = D4.getRequiredArg<List<String>>(positional, 1, 'values', 'somFormatEnumName');
        return $tom_som_dart_runtime_18.somFormatEnumName(name, values);
      },
      'validateDocument': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'validateDocument');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'validateDocument');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 1, 'doc', 'validateDocument');
        return $tom_som_dart_runtime_19.validateDocument(model, doc);
      },
    };
  }

  /// Returns a map of global function names to their canonical source URIs.
  ///
  /// Used for deduplication when the same function is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> globalFunctionSourceUris() {
    return {
      'docSpecsIdTransform': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'bindDocSpecsMarkdown': 'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'kindChips': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'codeSpecKindChips': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'followUpKindChips': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'caseChips': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'fieldChips': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'oneOfChips': 'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'somEditabilityFor': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'checkSomModelVersion': 'package:tom_som_dart_runtime/src/som_facade.dart',
      'buildSomMetaTree': 'package:tom_som_dart_runtime/src/spec_meta_bridge.dart',
      'somMetaNodeDiff': 'package:tom_som_dart_runtime/src/spec_meta_diff.dart',
      'somModelVersionString': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'parseStampTimestamp': 'package:tom_som_dart_runtime/src/spec_model.dart',
      'checkAddNode': 'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'specPathJoin': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'specPathSegments': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'specParentPath': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'listItemPath': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'splitListItemSegment': 'package:tom_som_dart_runtime/src/spec_paths.dart',
      'encodeTwoLetterDate': 'package:tom_som_dart_runtime/src/spec_section_id.dart',
      'sectionIdPatternPrefix': 'package:tom_som_dart_runtime/src/spec_section_id.dart',
      'effectiveListItemSectionId': 'package:tom_som_dart_runtime/src/spec_section_id.dart',
      'generateListItemSectionId': 'package:tom_som_dart_runtime/src/spec_section_id.dart',
      'somParseInt': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somFormatInt': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somParseDouble': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somFormatDouble': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somParseNum': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somFormatNum': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somParseBool': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somFormatBool': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somParseEnumName': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'somFormatEnumName': 'package:tom_som_dart_runtime/src/spec_typed_values.dart',
      'validateDocument': 'package:tom_som_dart_runtime/src/spec_validator.dart',
    };
  }

  /// Returns a map of global function names to their display signatures.
  static Map<String, String> globalFunctionSignatures() {
    return {
      'docSpecsIdTransform': 'String docSpecsIdTransform(String id)',
      'bindDocSpecsMarkdown': 'SpecMarkdownResult bindDocSpecsMarkdown(SpecModel model, SpecDocument document, String text)',
      'kindChips': 'List<SpecChip> kindChips(KindLink? codeSpec, KindLink? followUp)',
      'codeSpecKindChips': 'List<SpecChip> codeSpecKindChips(KindLink? link, {bool suppressUnmapped = false})',
      'followUpKindChips': 'List<SpecChip> followUpKindChips(KindLink? link)',
      'caseChips': 'List<SpecChip> caseChips(SpecField field)',
      'fieldChips': 'List<SpecChip> fieldChips(SpecField field)',
      'oneOfChips': 'List<SpecChip> oneOfChips(OneOfGroup group)',
      'somEditabilityFor': 'SomEditability somEditabilityFor(String generated, String? documentVersion)',
      'checkSomModelVersion': 'void checkSomModelVersion(String generated, String? documentVersion)',
      'buildSomMetaTree': 'SomMetaTree buildSomMetaTree(SpecModel model, {String? rootType})',
      'somMetaNodeDiff': 'String? somMetaNodeDiff(SomMetaNode a, SomMetaNode b, {String at = \'<root>\'})',
      'somModelVersionString': 'String somModelVersionString(int major, String? label)',
      'parseStampTimestamp': 'DateTime? parseStampTimestamp(String? raw)',
      'checkAddNode': 'SpecCreationError? checkAddNode(SpecModel model, SpecDocument document, String parentPath, String childSegment, {String? itemId})',
      'specPathJoin': 'String specPathJoin(String parent, String segment)',
      'specPathSegments': 'List<String> specPathSegments(String path)',
      'specParentPath': 'String specParentPath(String path)',
      'listItemPath': 'String listItemPath(String listPath, int seq)',
      'splitListItemSegment': '({String base, int seq})? splitListItemSegment(String segment)',
      'encodeTwoLetterDate': 'String encodeTwoLetterDate(DateTime date)',
      'sectionIdPatternPrefix': 'String sectionIdPatternPrefix(String pattern)',
      'effectiveListItemSectionId': 'String effectiveListItemSectionId({required String? storedId, required String? pattern, required int position, required String fallbackStem})',
      'generateListItemSectionId': 'String generateListItemSectionId(String pattern, DateTime date, Iterable<String> existingIds)',
      'somParseInt': 'int? somParseInt(String? raw)',
      'somFormatInt': 'String somFormatInt(int? value)',
      'somParseDouble': 'double? somParseDouble(String? raw)',
      'somFormatDouble': 'String somFormatDouble(double? value)',
      'somParseNum': 'num? somParseNum(String? raw)',
      'somFormatNum': 'String somFormatNum(num? value)',
      'somParseBool': 'bool? somParseBool(String? raw)',
      'somFormatBool': 'String somFormatBool(bool? value)',
      'somParseEnumName': 'String? somParseEnumName(String? raw, List<String> values)',
      'somFormatEnumName': 'String somFormatEnumName(String? name, List<String> values)',
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
      'package:tom_som_dart_runtime/src/docspecs_validator.dart',
      'package:tom_som_dart_runtime/src/som_facade.dart',
      'package:tom_som_dart_runtime/src/spec_annotation_display.dart',
      'package:tom_som_dart_runtime/src/spec_document.dart',
      'package:tom_som_dart_runtime/src/spec_document_markdown.dart',
      'package:tom_som_dart_runtime/src/spec_document_yaml.dart',
      'package:tom_som_dart_runtime/src/spec_editor.dart',
      'package:tom_som_dart_runtime/src/spec_meta.dart',
      'package:tom_som_dart_runtime/src/spec_meta_bridge.dart',
      'package:tom_som_dart_runtime/src/spec_meta_diff.dart',
      'package:tom_som_dart_runtime/src/spec_model.dart',
      'package:tom_som_dart_runtime/src/spec_node_creation.dart',
      'package:tom_som_dart_runtime/src/spec_paths.dart',
      'package:tom_som_dart_runtime/src/spec_query.dart',
      'package:tom_som_dart_runtime/src/spec_reflection.dart',
      'package:tom_som_dart_runtime/src/spec_section_id.dart',
      'package:tom_som_dart_runtime/src/spec_serialization_order.dart',
      'package:tom_som_dart_runtime/src/spec_typed_values.dart',
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
    'DocSpecsViolationRule',
    'SpecChipRole',
    'SomEditability',
    'SpecMarkdownRejectReason',
    'SomMetaKind',
    'SpecFieldKind',
    'SpecCreationCode',
    'SpecStateFilter',
    'SpecNodeKind',
    'SpecValidationCode',
  ];

}

// =============================================================================
// DocSpecsViolation Bridge
// =============================================================================

BridgedClass _createDocSpecsViolationBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsViolation,
    name: 'DocSpecsViolation',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsViolation,
    constructors: {
      '': (visitor, positional, named) {
        final rule = D4.getRequiredNamedArg<$tom_som_dart_runtime_1.DocSpecsViolationRule>(named, 'rule', 'DocSpecsViolation');
        final line = D4.getRequiredNamedArg<int>(named, 'line', 'DocSpecsViolation');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'DocSpecsViolation');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final path = D4.getOptionalNamedArg<String?>(named, 'path');
        return $tom_som_dart_runtime_1.DocSpecsViolation(rule: rule, line: line, message: message, sectionId: sectionId, path: path);
      },
    },
    getters: {
      'rule': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsViolation>(target, 'DocSpecsViolation').rule,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsViolation>(target, 'DocSpecsViolation').sectionId,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsViolation>(target, 'DocSpecsViolation').path,
      'line': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsViolation>(target, 'DocSpecsViolation').line,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsViolation>(target, 'DocSpecsViolation').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsViolation>(target, 'DocSpecsViolation');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'DocSpecsViolation({required DocSpecsViolationRule rule, required int line, required String message, String? sectionId, String? path})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'rule': 'DocSpecsViolationRule get rule',
      'sectionId': 'String? get sectionId',
      'path': 'String? get path',
      'line': 'int get line',
      'message': 'String get message',
    },
  );
}

// =============================================================================
// DocSpecsSection Bridge
// =============================================================================

BridgedClass _createDocSpecsSectionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsSection,
    name: 'DocSpecsSection',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsSection,
    constructors: {
      '': (visitor, positional, named) {
        final id = D4.getRequiredNamedArg<String?>(named, 'id', 'DocSpecsSection');
        final title = D4.getRequiredNamedArg<String>(named, 'title', 'DocSpecsSection');
        final level = D4.getRequiredNamedArg<int>(named, 'level', 'DocSpecsSection');
        final line = D4.getRequiredNamedArg<int>(named, 'line', 'DocSpecsSection');
        return $tom_som_dart_runtime_1.DocSpecsSection(id: id, title: title, level: level, line: line);
      },
    },
    getters: {
      'id': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').id,
      'title': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').title,
      'level': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').level,
      'line': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').line,
      'bodyLines': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').bodyLines,
      'children': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').children,
      'bodyStartLine': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').bodyStartLine,
      'text': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSection>(target, 'DocSpecsSection').text,
    },
    constructorSignatures: {
      '': 'DocSpecsSection({required String? id, required String title, required int level, required int line})',
    },
    getterSignatures: {
      'id': 'String? get id',
      'title': 'String get title',
      'level': 'int get level',
      'line': 'int get line',
      'bodyLines': 'List<String> get bodyLines',
      'children': 'List<DocSpecsSection> get children',
      'bodyStartLine': 'int get bodyStartLine',
      'text': 'String get text',
    },
  );
}

// =============================================================================
// DocSpecsDocument Bridge
// =============================================================================

BridgedClass _createDocSpecsDocumentBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsDocument,
    name: 'DocSpecsDocument',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsDocument,
    constructors: {
    },
    getters: {
      'declaredSchema': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsDocument>(target, 'DocSpecsDocument').declaredSchema,
      'sections': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsDocument>(target, 'DocSpecsDocument').sections,
      'violations': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsDocument>(target, 'DocSpecsDocument').violations,
    },
    setters: {
      'declaredSchema': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsDocument>(target, 'DocSpecsDocument').declaredSchema = D4.extractBridgedArgOrNull<String>(value, 'declaredSchema'),
    },
    staticMethods: {
      'parse': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parse');
        final text = D4.getRequiredArg<String>(positional, 0, 'text', 'parse');
        return $tom_som_dart_runtime_1.DocSpecsDocument.parse(text);
      },
    },
    getterSignatures: {
      'declaredSchema': 'String? get declaredSchema',
      'sections': 'List<DocSpecsSection> get sections',
      'violations': 'List<DocSpecsViolation> get violations',
    },
    setterSignatures: {
      'declaredSchema': 'set declaredSchema(dynamic value)',
    },
    staticMethodSignatures: {
      'parse': 'DocSpecsDocument parse(String text)',
    },
  );
}

// =============================================================================
// DocSpecsPatternCheck Bridge
// =============================================================================

BridgedClass _createDocSpecsPatternCheckBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsPatternCheck,
    name: 'DocSpecsPatternCheck',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsPatternCheck,
    constructors: {
      '': (visitor, positional, named) {
        final pattern = D4.getRequiredNamedArg<String>(named, 'pattern', 'DocSpecsPatternCheck');
        final errorMessage = D4.getOptionalNamedArg<String?>(named, 'errorMessage');
        return $tom_som_dart_runtime_1.DocSpecsPatternCheck(pattern: pattern, errorMessage: errorMessage);
      },
    },
    getters: {
      'pattern': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsPatternCheck>(target, 'DocSpecsPatternCheck').pattern,
      'errorMessage': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsPatternCheck>(target, 'DocSpecsPatternCheck').errorMessage,
    },
    methods: {
      'matches': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsPatternCheck>(target, 'DocSpecsPatternCheck');
        D4.requireMinArgs(positional, 1, 'matches');
        final value = D4.getRequiredArg<String>(positional, 0, 'value', 'matches');
        return t.matches(value);
      },
    },
    constructorSignatures: {
      '': 'DocSpecsPatternCheck({required String pattern, String? errorMessage})',
    },
    methodSignatures: {
      'matches': 'bool matches(String value)',
    },
    getterSignatures: {
      'pattern': 'String get pattern',
      'errorMessage': 'String? get errorMessage',
    },
  );
}

// =============================================================================
// DocSpecsSubsectionRule Bridge
// =============================================================================

BridgedClass _createDocSpecsSubsectionRuleBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsSubsectionRule,
    name: 'DocSpecsSubsectionRule',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsSubsectionRule,
    constructors: {
      '': (visitor, positional, named) {
        final minCount = D4.getRequiredNamedArg<int>(named, 'minCount', 'DocSpecsSubsectionRule');
        final maxCount = D4.getRequiredNamedArg<int?>(named, 'maxCount', 'DocSpecsSubsectionRule');
        return $tom_som_dart_runtime_1.DocSpecsSubsectionRule(minCount: minCount, maxCount: maxCount);
      },
    },
    getters: {
      'minCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSubsectionRule>(target, 'DocSpecsSubsectionRule').minCount,
      'maxCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSubsectionRule>(target, 'DocSpecsSubsectionRule').maxCount,
    },
    constructorSignatures: {
      '': 'DocSpecsSubsectionRule({required int minCount, required int? maxCount})',
    },
    getterSignatures: {
      'minCount': 'int get minCount',
      'maxCount': 'int? get maxCount',
    },
  );
}

// =============================================================================
// DocSpecsSectionType Bridge
// =============================================================================

BridgedClass _createDocSpecsSectionTypeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsSectionType,
    name: 'DocSpecsSectionType',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsSectionType,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'DocSpecsSectionType');
        final prefix = D4.getRequiredNamedArg<String>(named, 'prefix', 'DocSpecsSectionType');
        final patternCheckId = D4.getOptionalNamedArg<$tom_som_dart_runtime_1.DocSpecsPatternCheck?>(named, 'patternCheckId');
        final subsectionTypes = named.containsKey('subsectionTypes') && named['subsectionTypes'] != null
            ? D4.coerceMap<String, $tom_som_dart_runtime_1.DocSpecsSubsectionRule>(named['subsectionTypes'], 'subsectionTypes')
            : const <String, $tom_som_dart_runtime_1.DocSpecsSubsectionRule>{};
        final format = D4.getOptionalNamedArg<String?>(named, 'format');
        final textRequired = D4.getNamedArgWithDefault<bool>(named, 'textRequired', false);
        final minTextLength = D4.getOptionalNamedArg<int?>(named, 'minTextLength');
        final maxTextLength = D4.getOptionalNamedArg<int?>(named, 'maxTextLength');
        final description = D4.getOptionalNamedArg<String?>(named, 'description');
        final validationPrompt = D4.getOptionalNamedArg<String?>(named, 'validationPrompt');
        return $tom_som_dart_runtime_1.DocSpecsSectionType(name: name, prefix: prefix, patternCheckId: patternCheckId, subsectionTypes: subsectionTypes, format: format, textRequired: textRequired, minTextLength: minTextLength, maxTextLength: maxTextLength, description: description, validationPrompt: validationPrompt);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').name,
      'prefix': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').prefix,
      'patternCheckId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').patternCheckId,
      'subsectionTypes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').subsectionTypes,
      'format': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').format,
      'textRequired': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').textRequired,
      'minTextLength': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').minTextLength,
      'maxTextLength': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').maxTextLength,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').description,
      'validationPrompt': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSectionType>(target, 'DocSpecsSectionType').validationPrompt,
    },
    constructorSignatures: {
      '': 'DocSpecsSectionType({required String name, required String prefix, DocSpecsPatternCheck? patternCheckId, Map<String, DocSpecsSubsectionRule> subsectionTypes = const {}, String? format, bool textRequired = false, int? minTextLength, int? maxTextLength, String? description, String? validationPrompt})',
    },
    getterSignatures: {
      'name': 'String get name',
      'prefix': 'String get prefix',
      'patternCheckId': 'DocSpecsPatternCheck? get patternCheckId',
      'subsectionTypes': 'Map<String, DocSpecsSubsectionRule> get subsectionTypes',
      'format': 'String? get format',
      'textRequired': 'bool get textRequired',
      'minTextLength': 'int? get minTextLength',
      'maxTextLength': 'int? get maxTextLength',
      'description': 'String? get description',
      'validationPrompt': 'String? get validationPrompt',
    },
  );
}

// =============================================================================
// DocSpecsFormField Bridge
// =============================================================================

BridgedClass _createDocSpecsFormFieldBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsFormField,
    name: 'DocSpecsFormField',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsFormField,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'DocSpecsFormField');
        final required = D4.getNamedArgWithDefault<bool>(named, 'required', false);
        final description = D4.getOptionalNamedArg<String?>(named, 'description');
        final patternCheck = D4.getOptionalNamedArg<$tom_som_dart_runtime_1.DocSpecsPatternCheck?>(named, 'patternCheck');
        return $tom_som_dart_runtime_1.DocSpecsFormField(name: name, required: required, description: description, patternCheck: patternCheck);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsFormField>(target, 'DocSpecsFormField').name,
      'required': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsFormField>(target, 'DocSpecsFormField').required,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsFormField>(target, 'DocSpecsFormField').description,
      'patternCheck': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsFormField>(target, 'DocSpecsFormField').patternCheck,
    },
    constructorSignatures: {
      '': 'DocSpecsFormField({required String name, bool required = false, String? description, DocSpecsPatternCheck? patternCheck})',
    },
    getterSignatures: {
      'name': 'String get name',
      'required': 'bool get required',
      'description': 'String? get description',
      'patternCheck': 'DocSpecsPatternCheck? get patternCheck',
    },
  );
}

// =============================================================================
// DocSpecsFormType Bridge
// =============================================================================

BridgedClass _createDocSpecsFormTypeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsFormType,
    name: 'DocSpecsFormType',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsFormType,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'DocSpecsFormType');
        if (!named.containsKey('fields') || named['fields'] == null) {
          throw ArgumentError('DocSpecsFormType: Missing required named argument "fields"');
        }
        final fields = D4.coerceList<$tom_som_dart_runtime_1.DocSpecsFormField>(named['fields'], 'fields');
        return $tom_som_dart_runtime_1.DocSpecsFormType(name: name, fields: fields);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsFormType>(target, 'DocSpecsFormType').name,
      'fields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsFormType>(target, 'DocSpecsFormType').fields,
    },
    constructorSignatures: {
      '': 'DocSpecsFormType({required String name, required List<DocSpecsFormField> fields})',
    },
    getterSignatures: {
      'name': 'String get name',
      'fields': 'List<DocSpecsFormField> get fields',
    },
  );
}

// =============================================================================
// DocSpecsDocumentSection Bridge
// =============================================================================

BridgedClass _createDocSpecsDocumentSectionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsDocumentSection,
    name: 'DocSpecsDocumentSection',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsDocumentSection,
    constructors: {
      '': (visitor, positional, named) {
        final sectionType = D4.getRequiredNamedArg<String>(named, 'sectionType', 'DocSpecsDocumentSection');
        final optional = D4.getRequiredNamedArg<bool>(named, 'optional', 'DocSpecsDocumentSection');
        return $tom_som_dart_runtime_1.DocSpecsDocumentSection(sectionType: sectionType, optional: optional);
      },
    },
    getters: {
      'sectionType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsDocumentSection>(target, 'DocSpecsDocumentSection').sectionType,
      'optional': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsDocumentSection>(target, 'DocSpecsDocumentSection').optional,
    },
    constructorSignatures: {
      '': 'DocSpecsDocumentSection({required String sectionType, required bool optional})',
    },
    getterSignatures: {
      'sectionType': 'String get sectionType',
      'optional': 'bool get optional',
    },
  );
}

// =============================================================================
// DocSpecsSchema Bridge
// =============================================================================

BridgedClass _createDocSpecsSchemaBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsSchema,
    name: 'DocSpecsSchema',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsSchema,
    constructors: {
    },
    getters: {
      'titleFormat': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').titleFormat,
      'sectionTypes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').sectionTypes,
      'sectionTypesByName': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').sectionTypesByName,
      'formTypes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').formTypes,
      'documentSections': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').documentSections,
      'warnings': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').warnings,
      'rootSectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').rootSectionId,
    },
    setters: {
      'titleFormat': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema').titleFormat = D4.extractBridgedArgOrNull<String>(value, 'titleFormat'),
    },
    methods: {
      'resolveSectionType': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsSchema>(target, 'DocSpecsSchema');
        D4.requireMinArgs(positional, 1, 'resolveSectionType');
        final id = D4.getRequiredArg<String>(positional, 0, 'id', 'resolveSectionType');
        return t.resolveSectionType(id);
      },
    },
    staticMethods: {
      'fromYamlText': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'fromYamlText');
        final text = D4.getRequiredArg<String>(positional, 0, 'text', 'fromYamlText');
        return $tom_som_dart_runtime_1.DocSpecsSchema.fromYamlText(text);
      },
    },
    methodSignatures: {
      'resolveSectionType': 'DocSpecsSectionType? resolveSectionType(String id)',
    },
    getterSignatures: {
      'titleFormat': 'String? get titleFormat',
      'sectionTypes': 'List<DocSpecsSectionType> get sectionTypes',
      'sectionTypesByName': 'Map<String, DocSpecsSectionType> get sectionTypesByName',
      'formTypes': 'Map<String, DocSpecsFormType> get formTypes',
      'documentSections': 'Map<String, DocSpecsDocumentSection> get documentSections',
      'warnings': 'List<String> get warnings',
      'rootSectionId': 'String? get rootSectionId',
    },
    setterSignatures: {
      'titleFormat': 'set titleFormat(dynamic value)',
    },
    staticMethodSignatures: {
      'fromYamlText': 'DocSpecsSchema fromYamlText(String text)',
    },
  );
}

// =============================================================================
// DocSpecsValidator Bridge
// =============================================================================

BridgedClass _createDocSpecsValidatorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_1.DocSpecsValidator,
    name: 'DocSpecsValidator',
    isAssignable: (v) => v is $tom_som_dart_runtime_1.DocSpecsValidator,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'DocSpecsValidator');
        final schema = D4.getRequiredArg<$tom_som_dart_runtime_1.DocSpecsSchema>(positional, 0, 'schema', 'DocSpecsValidator');
        return $tom_som_dart_runtime_1.DocSpecsValidator(schema);
      },
    },
    getters: {
      'schema': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsValidator>(target, 'DocSpecsValidator').schema,
    },
    methods: {
      'validateMarkdown': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsValidator>(target, 'DocSpecsValidator');
        D4.requireMinArgs(positional, 1, 'validateMarkdown');
        final markdown = D4.getRequiredArg<String>(positional, 0, 'markdown', 'validateMarkdown');
        return t.validateMarkdown(markdown);
      },
      'validate': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_1.DocSpecsValidator>(target, 'DocSpecsValidator');
        D4.requireMinArgs(positional, 1, 'validate');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_1.DocSpecsDocument>(positional, 0, 'doc', 'validate');
        return t.validate(doc);
      },
    },
    constructorSignatures: {
      '': 'DocSpecsValidator(DocSpecsSchema schema)',
    },
    methodSignatures: {
      'validateMarkdown': 'List<DocSpecsViolation> validateMarkdown(String markdown)',
      'validate': 'List<DocSpecsViolation> validate(DocSpecsDocument doc)',
    },
    getterSignatures: {
      'schema': 'DocSpecsSchema get schema',
    },
  );
}

// =============================================================================
// SpecChip Bridge
// =============================================================================

BridgedClass _createSpecChipBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_3.SpecChip,
    name: 'SpecChip',
    isAssignable: (v) => v is $tom_som_dart_runtime_3.SpecChip,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecChip');
        final label = D4.getRequiredArg<String>(positional, 0, 'label', 'SpecChip');
        final role = D4.getRequiredArg<$tom_som_dart_runtime_3.SpecChipRole>(positional, 1, 'role', 'SpecChip');
        final tooltip = D4.getOptionalNamedArg<String?>(named, 'tooltip');
        return $tom_som_dart_runtime_3.SpecChip(label, role, tooltip: tooltip);
      },
    },
    getters: {
      'label': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecChip>(target, 'SpecChip').label,
      'role': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecChip>(target, 'SpecChip').role,
      'tooltip': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecChip>(target, 'SpecChip').tooltip,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_3.SpecChip>(target, 'SpecChip');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SpecChip(String label, SpecChipRole role, {String? tooltip})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'label': 'String get label',
      'role': 'SpecChipRole get role',
      'tooltip': 'String? get tooltip',
    },
  );
}

// =============================================================================
// SpecRowExtras Bridge
// =============================================================================

BridgedClass _createSpecRowExtrasBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_3.SpecRowExtras,
    name: 'SpecRowExtras',
    isAssignable: (v) => v is $tom_som_dart_runtime_3.SpecRowExtras,
    constructors: {
      '': (visitor, positional, named) {
        final unused = D4.getNamedArgWithDefault<bool>(named, 'unused', false);
        final comment = D4.getOptionalNamedArg<String?>(named, 'comment');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final sectionIdPattern = D4.getOptionalNamedArg<String?>(named, 'sectionIdPattern');
        final reference = D4.getOptionalNamedArg<String?>(named, 'reference');
        final standardReferences = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.StandardReferences?>(named, 'standardReferences');
        final serializationOrder = D4.getOptionalNamedArg<int?>(named, 'serializationOrder');
        return $tom_som_dart_runtime_3.SpecRowExtras(unused: unused, comment: comment, headline: headline, sectionIdPattern: sectionIdPattern, reference: reference, standardReferences: standardReferences, serializationOrder: serializationOrder);
      },
      'of': (visitor, positional, named) {
        final field = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.SpecField?>(named, 'field');
        final cls = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.SpecClass?>(named, 'cls');
        return $tom_som_dart_runtime_3.SpecRowExtras.of(field: field, cls: cls);
      },
    },
    getters: {
      'unused': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').unused,
      'comment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').comment,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').headline,
      'sectionIdPattern': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').sectionIdPattern,
      'reference': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').reference,
      'standardReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').standardReferences,
      'serializationOrder': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').serializationOrder,
      'hasReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_3.SpecRowExtras>(target, 'SpecRowExtras').hasReferences,
    },
    staticGetters: {
      'none': (visitor) => $tom_som_dart_runtime_3.SpecRowExtras.none,
    },
    constructorSignatures: {
      '': 'const SpecRowExtras({bool unused = false, String? comment, String? headline, String? sectionIdPattern, String? reference, StandardReferences? standardReferences, int? serializationOrder})',
      'of': 'factory SpecRowExtras.of({SpecField? field, SpecClass? cls})',
    },
    getterSignatures: {
      'unused': 'bool get unused',
      'comment': 'String? get comment',
      'headline': 'String? get headline',
      'sectionIdPattern': 'String? get sectionIdPattern',
      'reference': 'String? get reference',
      'standardReferences': 'StandardReferences? get standardReferences',
      'serializationOrder': 'int? get serializationOrder',
      'hasReferences': 'bool get hasReferences',
    },
    staticGetterSignatures: {
      'none': 'SpecRowExtras get none',
    },
  );
}

// =============================================================================
// SomNode Bridge
// =============================================================================

BridgedClass _createSomNodeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_2.SomNode,
    name: 'SomNode',
    isAssignable: (v) => v is $tom_som_dart_runtime_2.SomNode,
    isAbstract: true,
    constructors: {
    },
    getters: {
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').doc,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').path,
      'isEmpty': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').isEmpty,
      'canHaveContent': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').canHaveContent,
      '\$sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').$sectionId,
      '\$headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').$headline,
      '\$codeSpec': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').$codeSpec,
    },
    setters: {
      '\$sectionId': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').$sectionId = D4.extractBridgedArgOrNull<String>(value, '\$sectionId'),
      '\$headline': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').$headline = D4.extractBridgedArgOrNull<String>(value, '\$headline'),
      '\$codeSpec': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomNode>(target, 'SomNode').$codeSpec = D4.extractBridgedArgOrNull<String>(value, '\$codeSpec'),
    },
    getterSignatures: {
      'doc': 'SpecDocument get doc',
      'path': 'String get path',
      'isEmpty': 'bool get isEmpty',
      'canHaveContent': 'bool get canHaveContent',
      '\$sectionId': 'String? get \$sectionId',
      '\$headline': 'String? get \$headline',
      '\$codeSpec': 'String? get \$codeSpec',
    },
    setterSignatures: {
      '\$sectionId': 'set \$sectionId(String? value)',
      '\$headline': 'set \$headline(String? value)',
      '\$codeSpec': 'set \$codeSpec(String? value)',
    },
  );
}

// =============================================================================
// SomScalar Bridge
// =============================================================================

BridgedClass _createSomScalarBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_2.SomScalar,
    name: 'SomScalar',
    isAssignable: (v) => v is $tom_som_dart_runtime_2.SomScalar,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SomScalar');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 0, 'doc', 'SomScalar');
        final path = D4.getRequiredArg<String>(positional, 1, 'path', 'SomScalar');
        return $tom_som_dart_runtime_2.SomScalar(doc, path);
      },
    },
    getters: {
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').doc,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').path,
      'isEmpty': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').isEmpty,
      'canHaveContent': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').canHaveContent,
      '\$sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').$sectionId,
      '\$headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').$headline,
      '\$codeSpec': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').$codeSpec,
      'value': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').value,
    },
    setters: {
      '\$sectionId': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').$sectionId = D4.extractBridgedArgOrNull<String>(value, '\$sectionId'),
      '\$headline': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').$headline = D4.extractBridgedArgOrNull<String>(value, '\$headline'),
      '\$codeSpec': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').$codeSpec = D4.extractBridgedArgOrNull<String>(value, '\$codeSpec'),
      'value': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_2.SomScalar>(target, 'SomScalar').value = D4.extractBridgedArg<String>(value, 'value'),
    },
    constructorSignatures: {
      '': 'SomScalar(SpecDocument doc, String path)',
    },
    getterSignatures: {
      'doc': 'SpecDocument get doc',
      'path': 'String get path',
      'isEmpty': 'bool get isEmpty',
      'canHaveContent': 'bool get canHaveContent',
      '\$sectionId': 'String? get \$sectionId',
      '\$headline': 'String? get \$headline',
      '\$codeSpec': 'String? get \$codeSpec',
      'value': 'String get value',
    },
    setterSignatures: {
      '\$sectionId': 'set \$sectionId(String? value)',
      '\$headline': 'set \$headline(String? value)',
      '\$codeSpec': 'set \$codeSpec(String? value)',
      'value': 'set value(String value)',
    },
  );
}

// =============================================================================
// SomList Bridge
// =============================================================================

BridgedClass _createSomListBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_2.SomList,
    name: 'SomList',
    isAssignable: (v) => v is $tom_som_dart_runtime_2.SomList,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 3, 'SomList');
        final doc = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 0, 'doc', 'SomList');
        final listPath = D4.getRequiredArg<String>(positional, 1, 'listPath', 'SomList');
        if (positional.length <= 2) {
          throw ArgumentError('SomList: Missing required argument "_factory" at position 2');
        }
        final factoryRaw = positional[2];
        final pattern = D4.getOptionalNamedArg<String?>(named, 'pattern');
        return $tom_som_dart_runtime_2.SomList(doc, listPath, ($tom_som_dart_runtime_4.SpecDocument p0, String p1) { return D4.castCallbackResult<dynamic>(D4.callInterpreterCallback(visitor!, factoryRaw, [p0, p1])); }, pattern: pattern);
      },
    },
    getters: {
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').doc,
      'listPath': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').listPath,
      'pattern': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').pattern,
      'length': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').length,
      'items': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').items,
      'sectionIds': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').sectionIds,
      'contents': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList').contents,
    },
    methods: {
      'add': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final date = D4.getOptionalNamedArg<DateTime?>(named, 'date');
        return t.add(sectionId: sectionId, date: date);
      },
      'addContent': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList');
        D4.requireMinArgs(positional, 1, 'addContent');
        final content = D4.getRequiredArg<String>(positional, 0, 'content', 'addContent');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final date = D4.getOptionalNamedArg<DateTime?>(named, 'date');
        return t.addContent(content, sectionId: sectionId, date: date);
      },
      'removeAt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList');
        D4.requireMinArgs(positional, 1, 'removeAt');
        final index = D4.getRequiredArg<int>(positional, 0, 'index', 'removeAt');
        t.removeAt(index);
        return null;
      },
      '[]': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SomList>(target, 'SomList');
        final index = D4.getRequiredArg<int>(positional, 0, 'index', 'operator[]');
        return t[index];
      },
    },
    constructorSignatures: {
      '': 'SomList(SpecDocument doc, String listPath, T Function(SpecDocument doc, String itemPath) _factory, {String? pattern})',
    },
    methodSignatures: {
      'add': 'T add({String? sectionId, DateTime? date})',
      'addContent': 'T addContent(String content, {String? sectionId, DateTime? date})',
      'removeAt': 'void removeAt(int index)',
    },
    getterSignatures: {
      'doc': 'SpecDocument get doc',
      'listPath': 'String get listPath',
      'pattern': 'String? get pattern',
      'length': 'int get length',
      'items': 'List<T> get items',
      'sectionIds': 'List<String> get sectionIds',
      'contents': 'Iterable<String> get contents',
    },
  );
}

// =============================================================================
// SomVersionException Bridge
// =============================================================================

BridgedClass _createSomVersionExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_2.SomVersionException,
    name: 'SomVersionException',
    isAssignable: (v) => v is $tom_som_dart_runtime_2.SomVersionException,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SomVersionException');
        final message = D4.getRequiredArg<String>(positional, 0, 'message', 'SomVersionException');
        return $tom_som_dart_runtime_2.SomVersionException(message);
      },
    },
    getters: {
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_2.SomVersionException>(target, 'SomVersionException').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_2.SomVersionException>(target, 'SomVersionException');
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
    nativeType: $tom_som_dart_runtime_4.SpecDocument,
    name: 'SpecDocument',
    isAssignable: (v) => v is $tom_som_dart_runtime_4.SpecDocument,
    constructors: {
      '': (visitor, positional, named) {
        return $tom_som_dart_runtime_4.SpecDocument();
      },
    },
    getters: {
      'modelVersion': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').modelVersion,
      'pathNormalizer': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').pathNormalizer,
      'headlinePaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').headlinePaths,
      'codeSpecPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').codeSpecPaths,
      'isEmpty': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').isEmpty,
      'contentPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').contentPaths,
      'formPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').formPaths,
      'listPaths': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').listPaths,
    },
    setters: {
      'modelVersion': (visitor, target, value) => 
        D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument').modelVersion = D4.extractBridgedArgOrNull<String>(value, 'modelVersion'),
    },
    methods: {
      'installPathNormalizer': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'installPathNormalizer');
        if (positional.isEmpty) {
          throw ArgumentError('installPathNormalizer: Missing required argument "normalizer" at position 0');
        }
        final normalizerRaw = positional[0];
        t.installPathNormalizer(((String p0) { return D4.callInterpreterCallback(visitor!, normalizerRaw, [p0]) as String; }) as String Function(String));
        return null;
      },
      'toMarkdown': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'toMarkdown');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'toMarkdown');
        final rootType = D4.getOptionalNamedArg<String?>(named, 'rootType');
        return t.toMarkdown(model, rootType: rootType);
      },
      'content': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'content');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'content');
        return t.content(path);
      },
      'hasContent': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'hasContent');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'hasContent');
        return t.hasContent(path);
      },
      'setContent': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'setContent');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setContent');
        final value = D4.getRequiredArg<String>(positional, 1, 'value', 'setContent');
        t.setContent(path, value);
        return null;
      },
      'headline': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'headline');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'headline');
        return t.headline(path);
      },
      'setHeadline': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'setHeadline');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setHeadline');
        final value = D4.getRequiredArg<String>(positional, 1, 'value', 'setHeadline');
        t.setHeadline(path, value);
        return null;
      },
      'codeSpec': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'codeSpec');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'codeSpec');
        return t.codeSpec(path);
      },
      'setCodeSpec': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'setCodeSpec');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setCodeSpec');
        final value = D4.getRequiredArg<String>(positional, 1, 'value', 'setCodeSpec');
        t.setCodeSpec(path, value);
        return null;
      },
      'formField': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'formField');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formField');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'formField');
        return t.formField(path, field);
      },
      'setFormField': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 3, 'setFormField');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setFormField');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'setFormField');
        final value = D4.getRequiredArg<String>(positional, 2, 'value', 'setFormField');
        t.setFormField(path, field, value);
        return null;
      },
      'listItems': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'listItems');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItems');
        return t.listItems(listPath);
      },
      'addListItem': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'addListItem');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'addListItem');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        return t.addListItem(listPath, sectionId: sectionId);
      },
      'itemSectionId': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'itemSectionId');
        final itemPath = D4.getRequiredArg<String>(positional, 0, 'itemPath', 'itemSectionId');
        return t.itemSectionId(itemPath);
      },
      'setItemSectionId': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 2, 'setItemSectionId');
        final itemPath = D4.getRequiredArg<String>(positional, 0, 'itemPath', 'setItemSectionId');
        final id = D4.getRequiredArg<String>(positional, 1, 'id', 'setItemSectionId');
        t.setItemSectionId(itemPath, id);
        return null;
      },
      'listItemSectionIds': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'listItemSectionIds');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItemSectionIds');
        return t.listItemSectionIds(listPath);
      },
      'removeListItem': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'removeListItem');
        final itemPath = D4.getRequiredArg<String>(positional, 0, 'itemPath', 'removeListItem');
        return t.removeListItem(itemPath);
      },
      'removeValuesUnder': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'removeValuesUnder');
        final prefix = D4.getRequiredArg<String>(positional, 0, 'prefix', 'removeValuesUnder');
        t.removeValuesUnder(prefix);
        return null;
      },
      'hasValuesUnder': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'hasValuesUnder');
        final prefix = D4.getRequiredArg<String>(positional, 0, 'prefix', 'hasValuesUnder');
        return t.hasValuesUnder(prefix);
      },
      'formFieldNames': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'formFieldNames');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formFieldNames');
        return t.formFieldNames(path);
      },
      'listItemCount': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'listItemCount');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'listItemCount');
        return t.listItemCount(listPath);
      },
      'toJson': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        return t.toJson();
      },
      'loadJson': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'loadJson');
        final json = D4.getRequiredArg<Map>(positional, 0, 'json', 'loadJson');
        t.loadJson(json);
        return null;
      },
      'captureState': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        return t.captureState();
      },
      'restoreState': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocument>(target, 'SpecDocument');
        D4.requireMinArgs(positional, 1, 'restoreState');
        final state = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocumentState>(positional, 0, 'state', 'restoreState');
        t.restoreState(state);
        return null;
      },
    },
    staticMethods: {
      'fromYaml': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'fromYaml');
        final yaml = D4.getRequiredArg<String>(positional, 0, 'yaml', 'fromYaml');
        final tree = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaTree>(positional, 1, 'tree', 'fromYaml');
        return $tom_som_dart_runtime_4.SpecDocument.fromYaml(yaml, tree);
      },
      'fromFile': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'fromFile');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'fromFile');
        final tree = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaTree>(positional, 1, 'tree', 'fromFile');
        return $tom_som_dart_runtime_4.SpecDocument.fromFile(path, tree);
      },
    },
    constructorSignatures: {
      '': 'SpecDocument()',
    },
    methodSignatures: {
      'installPathNormalizer': 'void installPathNormalizer(String Function(String path) normalizer)',
      'toMarkdown': 'String toMarkdown(SpecModel model, {String? rootType})',
      'content': 'String? content(String path)',
      'hasContent': 'bool hasContent(String path)',
      'setContent': 'void setContent(String path, String value)',
      'headline': 'String? headline(String path)',
      'setHeadline': 'void setHeadline(String path, String value)',
      'codeSpec': 'String? codeSpec(String path)',
      'setCodeSpec': 'void setCodeSpec(String path, String value)',
      'formField': 'String? formField(String path, String field)',
      'setFormField': 'void setFormField(String path, String field, String value)',
      'listItems': 'List<String> listItems(String listPath)',
      'addListItem': 'String addListItem(String listPath, {String? sectionId})',
      'itemSectionId': 'String? itemSectionId(String itemPath)',
      'setItemSectionId': 'void setItemSectionId(String itemPath, String id)',
      'listItemSectionIds': 'List<String> listItemSectionIds(String listPath)',
      'removeListItem': 'bool removeListItem(String itemPath)',
      'removeValuesUnder': 'void removeValuesUnder(String prefix)',
      'hasValuesUnder': 'bool hasValuesUnder(String prefix)',
      'formFieldNames': 'Iterable<String> formFieldNames(String path)',
      'listItemCount': 'int listItemCount(String listPath)',
      'toJson': 'Map<String, Object?> toJson()',
      'loadJson': 'void loadJson(Map json)',
      'captureState': 'SpecDocumentState captureState()',
      'restoreState': 'void restoreState(SpecDocumentState state)',
    },
    getterSignatures: {
      'modelVersion': 'String? get modelVersion',
      'pathNormalizer': 'String Function(String path)? get pathNormalizer',
      'headlinePaths': 'Iterable<String> get headlinePaths',
      'codeSpecPaths': 'Iterable<String> get codeSpecPaths',
      'isEmpty': 'bool get isEmpty',
      'contentPaths': 'Iterable<String> get contentPaths',
      'formPaths': 'Iterable<String> get formPaths',
      'listPaths': 'Iterable<String> get listPaths',
    },
    setterSignatures: {
      'modelVersion': 'set modelVersion(dynamic value)',
    },
    staticMethodSignatures: {
      'fromYaml': 'SpecDocument fromYaml(String yaml, SomMetaTree tree)',
      'fromFile': 'SpecDocument fromFile(String path, SomMetaTree tree)',
    },
  );
}

// =============================================================================
// SpecDocumentState Bridge
// =============================================================================

BridgedClass _createSpecDocumentStateBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_4.SpecDocumentState,
    name: 'SpecDocumentState',
    isAssignable: (v) => v is $tom_som_dart_runtime_4.SpecDocumentState,
    constructors: {
    },
    getters: {
      'fingerprint': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_4.SpecDocumentState>(target, 'SpecDocumentState').fingerprint,
    },
    methods: {
      'contentAt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocumentState>(target, 'SpecDocumentState');
        D4.requireMinArgs(positional, 1, 'contentAt');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'contentAt');
        return t.contentAt(path);
      },
      'formFieldAt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_4.SpecDocumentState>(target, 'SpecDocumentState');
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
    nativeType: $tom_som_dart_runtime_5.SpecMarkdownRejection,
    name: 'SpecMarkdownRejection',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecMarkdownRejection,
    constructors: {
      '': (visitor, positional, named) {
        final line = D4.getRequiredNamedArg<int>(named, 'line', 'SpecMarkdownRejection');
        final reason = D4.getRequiredNamedArg<$tom_som_dart_runtime_5.SpecMarkdownRejectReason>(named, 'reason', 'SpecMarkdownRejection');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'SpecMarkdownRejection');
        final anchor = D4.getOptionalNamedArg<String?>(named, 'anchor');
        return $tom_som_dart_runtime_5.SpecMarkdownRejection(line: line, reason: reason, message: message, anchor: anchor);
      },
    },
    getters: {
      'line': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').line,
      'reason': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').reason,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').message,
      'anchor': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownRejection>(target, 'SpecMarkdownRejection').anchor,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownRejection>(target, 'SpecMarkdownRejection');
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
    nativeType: $tom_som_dart_runtime_5.SpecMarkdownResult,
    name: 'SpecMarkdownResult',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecMarkdownResult,
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
        final rejections = D4.coerceList<$tom_som_dart_runtime_5.SpecMarkdownRejection>(named['rejections'], 'rejections');
        if (!named.containsKey('rootPrefixes') || named['rootPrefixes'] == null) {
          throw ArgumentError('SpecMarkdownResult: Missing required named argument "rootPrefixes"');
        }
        final rootPrefixes = D4.coerceSet<String>(named['rootPrefixes'], 'rootPrefixes');
        final headlines = named.containsKey('headlines') && named['headlines'] != null
            ? D4.coerceMap<String, String>(named['headlines'], 'headlines')
            : const <String, String>{};
        final codeSpecs = named.containsKey('codeSpecs') && named['codeSpecs'] != null
            ? D4.coerceMap<String, String>(named['codeSpecs'], 'codeSpecs')
            : const <String, String>{};
        return $tom_som_dart_runtime_5.SpecMarkdownResult(content: content, forms: forms, lists: lists, rejections: rejections, rootPrefixes: rootPrefixes, headlines: headlines, codeSpecs: codeSpecs);
      },
    },
    getters: {
      'content': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').content,
      'forms': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').forms,
      'lists': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').lists,
      'headlines': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').headlines,
      'codeSpecs': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').codeSpecs,
      'rejections': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').rejections,
      'rootPrefixes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').rootPrefixes,
      'isClean': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').isClean,
      'appliedCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecMarkdownResult>(target, 'SpecMarkdownResult').appliedCount,
    },
    constructorSignatures: {
      '': 'SpecMarkdownResult({required Map<String, String> content, required Map<String, Map<String, String>> forms, required Map<String, Map<String, Object?>> lists, required List<SpecMarkdownRejection> rejections, required Set<String> rootPrefixes, Map<String, String> headlines = const {}, Map<String, String> codeSpecs = const {}})',
    },
    getterSignatures: {
      'content': 'Map<String, String> get content',
      'forms': 'Map<String, Map<String, String>> get forms',
      'lists': 'Map<String, Map<String, Object?>> get lists',
      'headlines': 'Map<String, String> get headlines',
      'codeSpecs': 'Map<String, String> get codeSpecs',
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
    nativeType: $tom_som_dart_runtime_5.SpecDocumentMarkdown,
    name: 'SpecDocumentMarkdown',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.SpecDocumentMarkdown,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecDocumentMarkdown');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'SpecDocumentMarkdown');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 1, 'document', 'SpecDocumentMarkdown');
        return $tom_som_dart_runtime_5.SpecDocumentMarkdown(model, document);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown').model,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown').document,
    },
    methods: {
      'exportRoot': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown');
        D4.requireMinArgs(positional, 1, 'exportRoot');
        final root = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecRoot>(positional, 0, 'root', 'exportRoot');
        return t.exportRoot(root);
      },
      'parse': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.SpecDocumentMarkdown>(target, 'SpecDocumentMarkdown');
        D4.requireMinArgs(positional, 1, 'parse');
        final text = D4.getRequiredArg<String>(positional, 0, 'text', 'parse');
        return t.parse(text);
      },
    },
    staticGetters: {
      'headingLine': (visitor) => $tom_som_dart_runtime_5.SpecDocumentMarkdown.headingLine,
      'headlineComment': (visitor) => $tom_som_dart_runtime_5.SpecDocumentMarkdown.headlineComment,
      'docspecComment': (visitor) => $tom_som_dart_runtime_5.SpecDocumentMarkdown.docspecComment,
    },
    staticMethods: {
      'titleCase': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'titleCase');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'titleCase');
        return $tom_som_dart_runtime_5.SpecDocumentMarkdown.titleCase(name);
      },
      'kebabCase': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'kebabCase');
        final title = D4.getRequiredArg<String>(positional, 0, 'title', 'kebabCase');
        return $tom_som_dart_runtime_5.SpecDocumentMarkdown.kebabCase(title);
      },
      'itemTitleStem': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'itemTitleStem');
        final elementClassName = D4.getRequiredArg<String>(positional, 0, 'elementClassName', 'itemTitleStem');
        return $tom_som_dart_runtime_5.SpecDocumentMarkdown.itemTitleStem(elementClassName);
      },
      'formLabel': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'formLabel');
        final fieldName = D4.getRequiredArg<String>(positional, 0, 'fieldName', 'formLabel');
        return $tom_som_dart_runtime_5.SpecDocumentMarkdown.formLabel(fieldName);
      },
      'codeSpecOf': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'codeSpecOf');
        final region = D4.getRequiredArg<String>(positional, 0, 'region', 'codeSpecOf');
        return $tom_som_dart_runtime_5.SpecDocumentMarkdown.codeSpecOf(region);
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
      'titleCase': 'String titleCase(String name)',
      'kebabCase': 'String kebabCase(String title)',
      'itemTitleStem': 'String itemTitleStem(String elementClassName)',
      'formLabel': 'String formLabel(String fieldName)',
      'codeSpecOf': 'String codeSpecOf(String region)',
    },
    staticGetterSignatures: {
      'headingLine': 'RegExp get headingLine',
      'headlineComment': 'RegExp get headlineComment',
      'docspecComment': 'RegExp get docspecComment',
    },
  );
}

// =============================================================================
// MarkdownFenceTracker Bridge
// =============================================================================

BridgedClass _createMarkdownFenceTrackerBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_5.MarkdownFenceTracker,
    name: 'MarkdownFenceTracker',
    isAssignable: (v) => v is $tom_som_dart_runtime_5.MarkdownFenceTracker,
    constructors: {
      '': (visitor, positional, named) {
        return $tom_som_dart_runtime_5.MarkdownFenceTracker();
      },
    },
    getters: {
      'inFence': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_5.MarkdownFenceTracker>(target, 'MarkdownFenceTracker').inFence,
    },
    methods: {
      'feed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_5.MarkdownFenceTracker>(target, 'MarkdownFenceTracker');
        D4.requireMinArgs(positional, 1, 'feed');
        final line = D4.getRequiredArg<String>(positional, 0, 'line', 'feed');
        t.feed(line);
        return null;
      },
    },
    constructorSignatures: {
      '': 'MarkdownFenceTracker()',
    },
    methodSignatures: {
      'feed': 'void feed(String line)',
    },
    getterSignatures: {
      'inFence': 'bool get inFence',
    },
  );
}

// =============================================================================
// SpecYamlFormatException Bridge
// =============================================================================

BridgedClass _createSpecYamlFormatExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_6.SpecYamlFormatException,
    name: 'SpecYamlFormatException',
    isAssignable: (v) => v is $tom_som_dart_runtime_6.SpecYamlFormatException,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecYamlFormatException');
        final message = D4.getRequiredArg<String>(positional, 0, 'message', 'SpecYamlFormatException');
        return $tom_som_dart_runtime_6.SpecYamlFormatException(message);
      },
    },
    getters: {
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecYamlFormatException>(target, 'SpecYamlFormatException').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_6.SpecYamlFormatException>(target, 'SpecYamlFormatException');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'SpecYamlFormatException(String message)',
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
// SpecYamlContents Bridge
// =============================================================================

BridgedClass _createSpecYamlContentsBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_6.SpecYamlContents,
    name: 'SpecYamlContents',
    isAssignable: (v) => v is $tom_som_dart_runtime_6.SpecYamlContents,
    constructors: {
      '': (visitor, positional, named) {
        final document = D4.getRequiredNamedArg<$tom_som_dart_runtime_4.SpecDocument>(named, 'document', 'SpecYamlContents');
        final review = D4.getRequiredNamedArg<Map>(named, 'review', 'SpecYamlContents');
        final modelVersion = D4.getOptionalNamedArg<String?>(named, 'modelVersion');
        return $tom_som_dart_runtime_6.SpecYamlContents(document: document, review: review, modelVersion: modelVersion);
      },
    },
    getters: {
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecYamlContents>(target, 'SpecYamlContents').document,
      'review': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecYamlContents>(target, 'SpecYamlContents').review,
      'modelVersion': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_6.SpecYamlContents>(target, 'SpecYamlContents').modelVersion,
    },
    constructorSignatures: {
      '': 'SpecYamlContents({required SpecDocument document, required Map review, String? modelVersion})',
    },
    getterSignatures: {
      'document': 'SpecDocument get document',
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
    nativeType: $tom_som_dart_runtime_6.SpecDocumentYaml,
    name: 'SpecDocumentYaml',
    isAssignable: (v) => v is $tom_som_dart_runtime_6.SpecDocumentYaml,
    constructors: {
      '': (visitor, positional, named) {
        return $tom_som_dart_runtime_6.SpecDocumentYaml();
      },
    },
    staticGetters: {
      'formatVersion': (visitor) => $tom_som_dart_runtime_6.SpecDocumentYaml.formatVersion,
    },
    staticMethods: {
      'encode': (visitor, positional, named, typeArgs) {
        final document = D4.getRequiredNamedArg<$tom_som_dart_runtime_4.SpecDocument>(named, 'document', 'encode');
        final tree = D4.getRequiredNamedArg<$tom_som_dart_runtime_8.SomMetaTree>(named, 'tree', 'encode');
        final modelVersion = D4.getOptionalNamedArg<String?>(named, 'modelVersion');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.encode(document: document, tree: tree, modelVersion: modelVersion);
      },
      'writeHeader': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'writeHeader');
        final b = D4.getRequiredArg<StringBuffer>(positional, 0, 'b', 'writeHeader');
        final modelVersion = D4.getOptionalNamedArg<String?>(named, 'modelVersion');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.writeHeader(b, modelVersion: modelVersion);
      },
      'nodeKey': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'nodeKey');
        final node = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaNode>(positional, 0, 'node', 'nodeKey');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.nodeKey(node);
      },
      'writeScalar': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 4, 'writeScalar');
        final b = D4.getRequiredArg<StringBuffer>(positional, 0, 'b', 'writeScalar');
        final keyIndent = D4.getRequiredArg<int>(positional, 1, 'keyIndent', 'writeScalar');
        final key = D4.getRequiredArg<String>(positional, 2, 'key', 'writeScalar');
        final value = D4.getRequiredArg<String>(positional, 3, 'value', 'writeScalar');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.writeScalar(b, keyIndent, key, value);
      },
      'yamlKey': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'yamlKey');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'yamlKey');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.yamlKey(key);
      },
      'plainKey': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'plainKey');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'plainKey');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.plainKey(key);
      },
      'dedupEmptyLines': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'dedupEmptyLines');
        final value = D4.getRequiredArg<String>(positional, 0, 'value', 'dedupEmptyLines');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.dedupEmptyLines(value);
      },
      'decode': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'decode');
        final yaml = D4.getRequiredArg<String>(positional, 0, 'yaml', 'decode');
        final tree = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaTree>(positional, 1, 'tree', 'decode');
        return $tom_som_dart_runtime_6.SpecDocumentYaml.decode(yaml, tree);
      },
    },
    constructorSignatures: {
      '': 'SpecDocumentYaml()',
    },
    staticMethodSignatures: {
      'encode': 'String encode({required SpecDocument document, required SomMetaTree tree, String? modelVersion})',
      'writeHeader': 'void writeHeader(StringBuffer b, {String? modelVersion})',
      'nodeKey': 'String nodeKey(SomMetaNode node)',
      'writeScalar': 'void writeScalar(StringBuffer b, int keyIndent, String key, String value)',
      'yamlKey': 'String yamlKey(String key)',
      'plainKey': 'String plainKey(String key)',
      'dedupEmptyLines': 'String dedupEmptyLines(String value)',
      'decode': 'SpecYamlContents decode(String yaml, SomMetaTree tree)',
    },
    staticGetterSignatures: {
      'formatVersion': 'int get formatVersion',
    },
  );
}

// =============================================================================
// SpecEditor Bridge
// =============================================================================

BridgedClass _createSpecEditorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_7.SpecEditor,
    name: 'SpecEditor',
    isAssignable: (v) => v is $tom_som_dart_runtime_7.SpecEditor,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecEditor');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 0, 'document', 'SpecEditor');
        final reflection = D4.getRequiredArg<$tom_som_dart_runtime_15.SpecReflection>(positional, 1, 'reflection', 'SpecEditor');
        return $tom_som_dart_runtime_7.SpecEditor(document, reflection);
      },
      'forModel': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecEditor');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 0, 'document', 'SpecEditor');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 1, 'model', 'SpecEditor');
        return $tom_som_dart_runtime_7.SpecEditor.forModel(document, model);
      },
    },
    getters: {
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor').document,
      'reflection': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor').reflection,
    },
    methods: {
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'resolve');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'resolve');
        return t.resolve(path);
      },
      'value': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'value');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'value');
        return t.value(path);
      },
      'setValue': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 2, 'setValue');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setValue');
        final v = D4.getRequiredArg<Object?>(positional, 1, 'v', 'setValue');
        t.setValue(path, v);
        return null;
      },
      'headline': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'headline');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'headline');
        return t.headline(path);
      },
      'setHeadline': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 2, 'setHeadline');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setHeadline');
        final value = D4.getRequiredArg<String?>(positional, 1, 'value', 'setHeadline');
        t.setHeadline(path, value);
        return null;
      },
      'formValue': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 2, 'formValue');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formValue');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'formValue');
        return t.formValue(path, field);
      },
      'setFormValue': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 3, 'setFormValue');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'setFormValue');
        final field = D4.getRequiredArg<String>(positional, 1, 'field', 'setFormValue');
        final v = D4.getRequiredArg<Object?>(positional, 2, 'v', 'setFormValue');
        t.setFormValue(path, field, v);
        return null;
      },
      'formFields': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'formFields');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'formFields');
        return t.formFields(path);
      },
      'addListItem': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'addListItem');
        final listPath = D4.getRequiredArg<String>(positional, 0, 'listPath', 'addListItem');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final now = D4.getOptionalNamedArg<DateTime?>(named, 'now');
        return t.addListItem(listPath, sectionId: sectionId, now: now);
      },
      'removeListItem': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'removeListItem');
        final itemPath = D4.getRequiredArg<String>(positional, 0, 'itemPath', 'removeListItem');
        return t.removeListItem(itemPath);
      },
      'clearSection': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_7.SpecEditor>(target, 'SpecEditor');
        D4.requireMinArgs(positional, 1, 'clearSection');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'clearSection');
        t.clearSection(path);
        return null;
      },
    },
    constructorSignatures: {
      '': 'SpecEditor(SpecDocument document, SpecReflection reflection)',
      'forModel': 'SpecEditor.forModel(SpecDocument document, SpecModel model)',
    },
    methodSignatures: {
      'resolve': 'SpecResolution resolve(String path)',
      'value': 'Object? value(String path)',
      'setValue': 'void setValue(String path, Object? v)',
      'headline': 'String? headline(String path)',
      'setHeadline': 'void setHeadline(String path, String? value)',
      'formValue': 'Object? formValue(String path, String field)',
      'setFormValue': 'void setFormValue(String path, String field, Object? v)',
      'formFields': 'List<FormFieldSpec> formFields(String path)',
      'addListItem': 'String addListItem(String listPath, {String? sectionId, DateTime? now})',
      'removeListItem': 'bool removeListItem(String itemPath)',
      'clearSection': 'void clearSection(String path)',
    },
    getterSignatures: {
      'document': 'SpecDocument get document',
      'reflection': 'SpecReflection get reflection',
    },
  );
}

// =============================================================================
// SomContentTypeMeta Bridge
// =============================================================================

BridgedClass _createSomContentTypeMetaBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomContentTypeMeta,
    name: 'SomContentTypeMeta',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomContentTypeMeta,
    constructors: {
      '': (visitor, positional, named) {
        final type = D4.getRequiredNamedArg<String>(named, 'type', 'SomContentTypeMeta');
        final description = D4.getRequiredNamedArg<String>(named, 'description', 'SomContentTypeMeta');
        return $tom_som_dart_runtime_8.SomContentTypeMeta(type: type, description: description);
      },
    },
    getters: {
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomContentTypeMeta>(target, 'SomContentTypeMeta').type,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomContentTypeMeta>(target, 'SomContentTypeMeta').description,
    },
    constructorSignatures: {
      '': 'const SomContentTypeMeta({required String type, required String description})',
    },
    getterSignatures: {
      'type': 'String get type',
      'description': 'String get description',
    },
  );
}

// =============================================================================
// SomFormFieldMeta Bridge
// =============================================================================

BridgedClass _createSomFormFieldMetaBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomFormFieldMeta,
    name: 'SomFormFieldMeta',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomFormFieldMeta,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SomFormFieldMeta');
        final typeName = D4.getRequiredNamedArg<String>(named, 'typeName', 'SomFormFieldMeta');
        final description = D4.getOptionalNamedArg<String?>(named, 'description');
        final required = D4.getNamedArgWithDefault<bool>(named, 'required', false);
        final hint = D4.getOptionalNamedArg<String?>(named, 'hint');
        final order = D4.getRequiredNamedArg<int>(named, 'order', 'SomFormFieldMeta');
        final enumValues = named.containsKey('enumValues') && named['enumValues'] != null
            ? D4.coerceList<String>(named['enumValues'], 'enumValues')
            : const <String>[];
        final refersTo = named.containsKey('refersTo') && named['refersTo'] != null
            ? D4.coerceList<String>(named['refersTo'], 'refersTo')
            : const <String>[];
        return $tom_som_dart_runtime_8.SomFormFieldMeta(name: name, typeName: typeName, description: description, required: required, hint: hint, order: order, enumValues: enumValues, refersTo: refersTo);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').name,
      'typeName': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').typeName,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').description,
      'required': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').required,
      'hint': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').hint,
      'order': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').order,
      'enumValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').enumValues,
      'refersTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormFieldMeta>(target, 'SomFormFieldMeta').refersTo,
    },
    constructorSignatures: {
      '': 'const SomFormFieldMeta({required String name, required String typeName, String? description, bool required = false, String? hint, required int order, List<String> enumValues = const [], List<String> refersTo = const []})',
    },
    getterSignatures: {
      'name': 'String get name',
      'typeName': 'String get typeName',
      'description': 'String? get description',
      'required': 'bool get required',
      'hint': 'String? get hint',
      'order': 'int get order',
      'enumValues': 'List<String> get enumValues',
      'refersTo': 'List<String> get refersTo',
    },
  );
}

// =============================================================================
// SomFormMeta Bridge
// =============================================================================

BridgedClass _createSomFormMetaBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomFormMeta,
    name: 'SomFormMeta',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomFormMeta,
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('fields') || named['fields'] == null) {
          throw ArgumentError('SomFormMeta: Missing required named argument "fields"');
        }
        final fields = D4.coerceList<$tom_som_dart_runtime_8.SomFormFieldMeta>(named['fields'], 'fields');
        return $tom_som_dart_runtime_8.SomFormMeta(fields: fields);
      },
    },
    getters: {
      'fields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomFormMeta>(target, 'SomFormMeta').fields,
    },
    methods: {
      'fieldNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomFormMeta>(target, 'SomFormMeta');
        D4.requireMinArgs(positional, 1, 'fieldNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'fieldNamed');
        return t.fieldNamed(name);
      },
    },
    constructorSignatures: {
      '': 'const SomFormMeta({required List<SomFormFieldMeta> fields})',
    },
    methodSignatures: {
      'fieldNamed': 'SomFormFieldMeta? fieldNamed(String name)',
    },
    getterSignatures: {
      'fields': 'List<SomFormFieldMeta> get fields',
    },
  );
}

// =============================================================================
// SomDocMeta Bridge
// =============================================================================

BridgedClass _createSomDocMetaBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomDocMeta,
    name: 'SomDocMeta',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomDocMeta,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SomDocMeta');
        final description = D4.getRequiredNamedArg<String>(named, 'description', 'SomDocMeta');
        final basedOn = named.containsKey('basedOn') && named['basedOn'] != null
            ? D4.coerceList<String>(named['basedOn'], 'basedOn')
            : const <String>[];
        return $tom_som_dart_runtime_8.SomDocMeta(name: name, description: description, basedOn: basedOn);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomDocMeta>(target, 'SomDocMeta').name,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomDocMeta>(target, 'SomDocMeta').description,
      'basedOn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomDocMeta>(target, 'SomDocMeta').basedOn,
    },
    constructorSignatures: {
      '': 'const SomDocMeta({required String name, required String description, List<String> basedOn = const []})',
    },
    getterSignatures: {
      'name': 'String get name',
      'description': 'String get description',
      'basedOn': 'List<String> get basedOn',
    },
  );
}

// =============================================================================
// SomMetaExtra Bridge
// =============================================================================

BridgedClass _createSomMetaExtraBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomMetaExtra,
    name: 'SomMetaExtra',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomMetaExtra,
    constructors: {
      '': (visitor, positional, named) {
        final annotation = D4.getRequiredNamedArg<String>(named, 'annotation', 'SomMetaExtra');
        final args = named.containsKey('args') && named['args'] != null
            ? D4.coerceMap<String, Object?>(named['args'], 'args')
            : const <String, Object?>{};
        return $tom_som_dart_runtime_8.SomMetaExtra(annotation: annotation, args: args);
      },
    },
    getters: {
      'annotation': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaExtra>(target, 'SomMetaExtra').annotation,
      'args': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaExtra>(target, 'SomMetaExtra').args,
    },
    constructorSignatures: {
      '': 'const SomMetaExtra({required String annotation, Map<String, Object?> args = const {}})',
    },
    getterSignatures: {
      'annotation': 'String get annotation',
      'args': 'Map<String, Object?> get args',
    },
  );
}

// =============================================================================
// SomMetaNode Bridge
// =============================================================================

BridgedClass _createSomMetaNodeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomMetaNode,
    name: 'SomMetaNode',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomMetaNode,
    constructors: {
      '': (visitor, positional, named) {
        final className = D4.getRequiredNamedArg<String>(named, 'className', 'SomMetaNode');
        final memberName = D4.getOptionalNamedArg<String?>(named, 'memberName');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final classSectionId = D4.getOptionalNamedArg<String?>(named, 'classSectionId');
        final sectionIdPattern = D4.getOptionalNamedArg<String?>(named, 'sectionIdPattern');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_8.SomMetaKind>(named, 'kind', 'SomMetaNode');
        final typeName = D4.getRequiredNamedArg<String>(named, 'typeName', 'SomMetaNode');
        final serializationOrder = D4.getOptionalNamedArg<int?>(named, 'serializationOrder');
        final min = D4.getOptionalNamedArg<int?>(named, 'min');
        final unused = D4.getNamedArgWithDefault<bool>(named, 'unused', false);
        final contentType = D4.getOptionalNamedArg<$tom_som_dart_runtime_8.SomContentTypeMeta?>(named, 'contentType');
        final contentHelp = D4.getOptionalNamedArg<String?>(named, 'contentHelp');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final comment = D4.getOptionalNamedArg<String?>(named, 'comment');
        final docComment = D4.getOptionalNamedArg<String?>(named, 'docComment');
        final classDocComment = D4.getOptionalNamedArg<String?>(named, 'classDocComment');
        final form = D4.getOptionalNamedArg<$tom_som_dart_runtime_8.SomFormMeta?>(named, 'form');
        final document = D4.getOptionalNamedArg<$tom_som_dart_runtime_8.SomDocMeta?>(named, 'document');
        final mapsTo = D4.getOptionalNamedArg<String?>(named, 'mapsTo');
        final detailedIn = D4.getOptionalNamedArg<String?>(named, 'detailedIn');
        final extra = named.containsKey('extra') && named['extra'] != null
            ? D4.coerceList<$tom_som_dart_runtime_8.SomMetaExtra>(named['extra'], 'extra')
            : const <$tom_som_dart_runtime_8.SomMetaExtra>[];
        final recursive = D4.getNamedArgWithDefault<bool>(named, 'recursive', false);
        final children = named.containsKey('children') && named['children'] != null
            ? D4.coerceList<$tom_som_dart_runtime_8.SomMetaNode>(named['children'], 'children')
            : const <$tom_som_dart_runtime_8.SomMetaNode>[];
        final elementNode = D4.getOptionalNamedArg<$tom_som_dart_runtime_8.SomMetaNode?>(named, 'elementNode');
        return $tom_som_dart_runtime_8.SomMetaNode(className: className, memberName: memberName, sectionId: sectionId, classSectionId: classSectionId, sectionIdPattern: sectionIdPattern, kind: kind, typeName: typeName, serializationOrder: serializationOrder, min: min, unused: unused, contentType: contentType, contentHelp: contentHelp, headline: headline, comment: comment, docComment: docComment, classDocComment: classDocComment, form: form, document: document, mapsTo: mapsTo, detailedIn: detailedIn, extra: extra, recursive: recursive, children: children, elementNode: elementNode);
      },
    },
    getters: {
      'className': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').className,
      'memberName': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').memberName,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').sectionId,
      'classSectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').classSectionId,
      'sectionIdPattern': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').sectionIdPattern,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').kind,
      'typeName': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').typeName,
      'serializationOrder': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').serializationOrder,
      'min': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').min,
      'unused': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').unused,
      'contentType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').contentType,
      'contentHelp': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').contentHelp,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').headline,
      'comment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').comment,
      'docComment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').docComment,
      'classDocComment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').classDocComment,
      'form': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').form,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').document,
      'mapsTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').mapsTo,
      'detailedIn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').detailedIn,
      'extra': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').extra,
      'recursive': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').recursive,
      'children': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').children,
      'elementNode': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').elementNode,
      'tree': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').tree,
      'parent': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').parent,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').path,
      'segment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').segment,
      'debugName': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode').debugName,
    },
    methods: {
      'itemPath': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode');
        D4.requireMinArgs(positional, 1, 'itemPath');
        final seq = D4.getRequiredArg<int>(positional, 0, 'seq', 'itemPath');
        return t.itemPath(seq);
      },
      'childByMember': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode');
        D4.requireMinArgs(positional, 1, 'childByMember');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'childByMember');
        return t.childByMember(name);
      },
      'childBySegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomMetaNode>(target, 'SomMetaNode');
        D4.requireMinArgs(positional, 1, 'childBySegment');
        final seg = D4.getRequiredArg<String>(positional, 0, 'seg', 'childBySegment');
        return t.childBySegment(seg);
      },
    },
    constructorSignatures: {
      '': 'SomMetaNode({required String className, String? memberName, String? sectionId, String? classSectionId, String? sectionIdPattern, required SomMetaKind kind, required String typeName, int? serializationOrder, int? min, bool unused = false, SomContentTypeMeta? contentType, String? contentHelp, String? headline, String? comment, String? docComment, String? classDocComment, SomFormMeta? form, SomDocMeta? document, String? mapsTo, String? detailedIn, List<SomMetaExtra> extra = const [], bool recursive = false, List<SomMetaNode> children = const [], SomMetaNode? elementNode})',
    },
    methodSignatures: {
      'itemPath': 'String itemPath(int seq)',
      'childByMember': 'SomMetaNode? childByMember(String name)',
      'childBySegment': 'SomMetaNode? childBySegment(String seg)',
    },
    getterSignatures: {
      'className': 'String get className',
      'memberName': 'String? get memberName',
      'sectionId': 'String? get sectionId',
      'classSectionId': 'String? get classSectionId',
      'sectionIdPattern': 'String? get sectionIdPattern',
      'kind': 'SomMetaKind get kind',
      'typeName': 'String get typeName',
      'serializationOrder': 'int? get serializationOrder',
      'min': 'int? get min',
      'unused': 'bool get unused',
      'contentType': 'SomContentTypeMeta? get contentType',
      'contentHelp': 'String? get contentHelp',
      'headline': 'String? get headline',
      'comment': 'String? get comment',
      'docComment': 'String? get docComment',
      'classDocComment': 'String? get classDocComment',
      'form': 'SomFormMeta? get form',
      'document': 'SomDocMeta? get document',
      'mapsTo': 'String? get mapsTo',
      'detailedIn': 'String? get detailedIn',
      'extra': 'List<SomMetaExtra> get extra',
      'recursive': 'bool get recursive',
      'children': 'List<SomMetaNode> get children',
      'elementNode': 'SomMetaNode? get elementNode',
      'tree': 'SomMetaTree get tree',
      'parent': 'SomMetaNode? get parent',
      'path': 'String? get path',
      'segment': 'String get segment',
      'debugName': 'String get debugName',
    },
  );
}

// =============================================================================
// SomMetaTree Bridge
// =============================================================================

BridgedClass _createSomMetaTreeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomMetaTree,
    name: 'SomMetaTree',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomMetaTree,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SomMetaTree');
        final root = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaNode>(positional, 0, 'root', 'SomMetaTree');
        return $tom_som_dart_runtime_8.SomMetaTree(root);
      },
    },
    getters: {
      'root': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaTree>(target, 'SomMetaTree').root,
      'allNodes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaTree>(target, 'SomMetaTree').allNodes,
    },
    methods: {
      'allById': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomMetaTree>(target, 'SomMetaTree');
        D4.requireMinArgs(positional, 1, 'allById');
        final sectionId = D4.getRequiredArg<String>(positional, 0, 'sectionId', 'allById');
        return t.allById(sectionId);
      },
      'byId': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomMetaTree>(target, 'SomMetaTree');
        D4.requireMinArgs(positional, 1, 'byId');
        final sectionId = D4.getRequiredArg<String>(positional, 0, 'sectionId', 'byId');
        return t.byId(sectionId);
      },
      'byPath': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomMetaTree>(target, 'SomMetaTree');
        D4.requireMinArgs(positional, 1, 'byPath');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'byPath');
        return t.byPath(path);
      },
    },
    constructorSignatures: {
      '': 'SomMetaTree(SomMetaNode root)',
    },
    methodSignatures: {
      'allById': 'List<SomMetaNode> allById(String sectionId)',
      'byId': 'SomMetaNode? byId(String sectionId)',
      'byPath': 'SomMetaNode? byPath(String path)',
    },
    getterSignatures: {
      'root': 'SomMetaNode get root',
      'allNodes': 'Iterable<SomMetaNode> get allNodes',
    },
  );
}

// =============================================================================
// SomMetaRef Bridge
// =============================================================================

BridgedClass _createSomMetaRefBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomMetaRef,
    name: 'SomMetaRef',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomMetaRef,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SomMetaRef');
        final tree = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaTree>(positional, 0, 'tree', 'SomMetaRef');
        final path = D4.getRequiredArg<String>(positional, 1, 'path', 'SomMetaRef');
        return $tom_som_dart_runtime_8.SomMetaRef(tree, path);
      },
    },
    getters: {
      'tree': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaRef>(target, 'SomMetaRef').tree,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaRef>(target, 'SomMetaRef').path,
      'meta': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomMetaRef>(target, 'SomMetaRef').meta,
    },
    constructorSignatures: {
      '': 'SomMetaRef(SomMetaTree tree, String path)',
    },
    getterSignatures: {
      'tree': 'SomMetaTree get tree',
      'path': 'String get path',
      'meta': 'SomMetaNode get meta',
    },
  );
}

// =============================================================================
// SomListMetaRef Bridge
// =============================================================================

BridgedClass _createSomListMetaRefBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_8.SomListMetaRef,
    name: 'SomListMetaRef',
    isAssignable: (v) => v is $tom_som_dart_runtime_8.SomListMetaRef,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 3, 'SomListMetaRef');
        final tree = D4.getRequiredArg<$tom_som_dart_runtime_8.SomMetaTree>(positional, 0, 'tree', 'SomListMetaRef');
        final path = D4.getRequiredArg<String>(positional, 1, 'path', 'SomListMetaRef');
        if (positional.length <= 2) {
          throw ArgumentError('SomListMetaRef: Missing required argument "_element" at position 2');
        }
        final elementRaw = positional[2];
        return $tom_som_dart_runtime_8.SomListMetaRef(tree, path, ($tom_som_dart_runtime_8.SomMetaTree p0, String p1) { return D4.castCallbackResult<dynamic>(D4.callInterpreterCallback(visitor!, elementRaw, [p0, p1])); });
      },
    },
    getters: {
      'tree': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomListMetaRef>(target, 'SomListMetaRef').tree,
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomListMetaRef>(target, 'SomListMetaRef').path,
      'meta': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_8.SomListMetaRef>(target, 'SomListMetaRef').meta,
    },
    methods: {
      'item': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_8.SomListMetaRef>(target, 'SomListMetaRef');
        D4.requireMinArgs(positional, 1, 'item');
        final seq = D4.getRequiredArg<int>(positional, 0, 'seq', 'item');
        return t.item(seq);
      },
    },
    constructorSignatures: {
      '': 'SomListMetaRef(SomMetaTree tree, String path, E Function(SomMetaTree tree, String path) _element)',
    },
    methodSignatures: {
      'item': 'E item(int seq)',
    },
    getterSignatures: {
      'tree': 'SomMetaTree get tree',
      'path': 'String get path',
      'meta': 'SomMetaNode get meta',
    },
  );
}

// =============================================================================
// SpecAnnotation Bridge
// =============================================================================

BridgedClass _createSpecAnnotationBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.SpecAnnotation,
    name: 'SpecAnnotation',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.SpecAnnotation,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SpecAnnotation');
        final arguments = named.containsKey('arguments') && named['arguments'] != null
            ? D4.coerceMap<String, Object?>(named['arguments'], 'arguments')
            : const <String, Object?>{};
        return $tom_som_dart_runtime_11.SpecAnnotation(name: name, arguments: arguments);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecAnnotation');
        if (positional.isEmpty) {
          throw ArgumentError('SpecAnnotation: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_11.SpecAnnotation.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecAnnotation>(target, 'SpecAnnotation').name,
      'arguments': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecAnnotation>(target, 'SpecAnnotation').arguments,
    },
    methods: {
      'argument': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecAnnotation>(target, 'SpecAnnotation');
        D4.requireMinArgs(positional, 1, 'argument');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'argument');
        return t.argument(key);
      },
    },
    staticMethods: {
      'listFromJson': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'listFromJson');
        final raw = D4.getRequiredArg<Object?>(positional, 0, 'raw', 'listFromJson');
        return $tom_som_dart_runtime_11.SpecAnnotation.listFromJson(raw);
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
    nativeType: $tom_som_dart_runtime_11.FormFieldSpec,
    name: 'FormFieldSpec',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.FormFieldSpec,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'FormFieldSpec');
        final label = D4.getRequiredNamedArg<String>(named, 'label', 'FormFieldSpec');
        final type = D4.getRequiredNamedArg<String>(named, 'type', 'FormFieldSpec');
        final hint = D4.getOptionalNamedArg<String?>(named, 'hint');
        final required = D4.getNamedArgWithDefault<bool>(named, 'required', false);
        final enumValues = named.containsKey('enumValues') && named['enumValues'] != null
            ? D4.coerceList<String>(named['enumValues'], 'enumValues')
            : const <String>[];
        final refersTo = named.containsKey('refersTo') && named['refersTo'] != null
            ? D4.coerceList<String>(named['refersTo'], 'refersTo')
            : const <String>[];
        return $tom_som_dart_runtime_11.FormFieldSpec(name: name, label: label, type: type, hint: hint, required: required, enumValues: enumValues, refersTo: refersTo);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'FormFieldSpec');
        if (positional.isEmpty) {
          throw ArgumentError('FormFieldSpec: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_11.FormFieldSpec.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').name,
      'label': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').label,
      'hint': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').hint,
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').type,
      'required': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').required,
      'enumValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').enumValues,
      'refersTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.FormFieldSpec>(target, 'FormFieldSpec').refersTo,
    },
    constructorSignatures: {
      '': 'FormFieldSpec({required String name, required String label, required String type, String? hint, bool required = false, List<String> enumValues = const [], List<String> refersTo = const []})',
      'fromJson': 'factory FormFieldSpec.fromJson(Map<String, dynamic> j)',
    },
    getterSignatures: {
      'name': 'String get name',
      'label': 'String get label',
      'hint': 'String? get hint',
      'type': 'String get type',
      'required': 'bool get required',
      'enumValues': 'List<String> get enumValues',
      'refersTo': 'List<String> get refersTo',
    },
  );
}

// =============================================================================
// KindLink Bridge
// =============================================================================

BridgedClass _createKindLinkBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.KindLink,
    name: 'KindLink',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.KindLink,
    constructors: {
      '': (visitor, positional, named) {
        final kinds = named.containsKey('kinds') && named['kinds'] != null
            ? D4.coerceList<String>(named['kinds'], 'kinds')
            : const <String>[];
        final note = D4.getOptionalNamedArg<String?>(named, 'note');
        return $tom_som_dart_runtime_11.KindLink(kinds: kinds, note: note);
      },
      'fromAnnotation': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'KindLink');
        final annotation = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecAnnotation>(positional, 0, 'annotation', 'KindLink');
        final listArgument = D4.getRequiredNamedArg<String>(named, 'listArgument', 'KindLink');
        return $tom_som_dart_runtime_11.KindLink.fromAnnotation(annotation, listArgument: listArgument);
      },
    },
    getters: {
      'kinds': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.KindLink>(target, 'KindLink').kinds,
      'note': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.KindLink>(target, 'KindLink').note,
    },
    constructorSignatures: {
      '': 'const KindLink({List<String> kinds = const [], String? note})',
      'fromAnnotation': 'factory KindLink.fromAnnotation(SpecAnnotation annotation, {required String listArgument})',
    },
    getterSignatures: {
      'kinds': 'List<String> get kinds',
      'note': 'String? get note',
    },
  );
}

// =============================================================================
// StandardReferences Bridge
// =============================================================================

BridgedClass _createStandardReferencesBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.StandardReferences,
    name: 'StandardReferences',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.StandardReferences,
    constructors: {
      '': (visitor, positional, named) {
        final standards = named.containsKey('standards') && named['standards'] != null
            ? D4.coerceList<String>(named['standards'], 'standards')
            : const <String>[];
        final connotation = D4.getOptionalNamedArg<String?>(named, 'connotation');
        return $tom_som_dart_runtime_11.StandardReferences(standards: standards, connotation: connotation);
      },
    },
    getters: {
      'standards': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.StandardReferences>(target, 'StandardReferences').standards,
      'connotation': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.StandardReferences>(target, 'StandardReferences').connotation,
    },
    staticMethods: {
      'fromJson': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'fromJson');
        final raw = D4.getRequiredArg<Object?>(positional, 0, 'raw', 'fromJson');
        return $tom_som_dart_runtime_11.StandardReferences.fromJson(raw);
      },
    },
    constructorSignatures: {
      '': 'const StandardReferences({List<String> standards = const [], String? connotation})',
    },
    getterSignatures: {
      'standards': 'List<String> get standards',
      'connotation': 'String? get connotation',
    },
    staticMethodSignatures: {
      'fromJson': 'StandardReferences? fromJson(Object? raw)',
    },
  );
}

// =============================================================================
// SpecField Bridge
// =============================================================================

BridgedClass _createSpecFieldBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.SpecField,
    name: 'SpecField',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.SpecField,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SpecField');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_11.SpecFieldKind>(named, 'kind', 'SpecField');
        final doc = D4.getOptionalNamedArg<String?>(named, 'doc');
        final help = D4.getOptionalNamedArg<String?>(named, 'help');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final sectionIdPattern = D4.getOptionalNamedArg<String?>(named, 'sectionIdPattern');
        final serializationOrder = D4.getOptionalNamedArg<int?>(named, 'serializationOrder');
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
            ? D4.coerceList<$tom_som_dart_runtime_11.FormFieldSpec>(named['formFields'], 'formFields')
            : const <$tom_som_dart_runtime_11.FormFieldSpec>[];
        final annotations = named.containsKey('annotations') && named['annotations'] != null
            ? D4.coerceList<$tom_som_dart_runtime_11.SpecAnnotation>(named['annotations'], 'annotations')
            : const <$tom_som_dart_runtime_11.SpecAnnotation>[];
        final standardReferences = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.StandardReferences?>(named, 'standardReferences');
        return $tom_som_dart_runtime_11.SpecField(name: name, kind: kind, doc: doc, help: help, headline: headline, sectionId: sectionId, sectionIdPattern: sectionIdPattern, serializationOrder: serializationOrder, elementType: elementType, elementIsComplex: elementIsComplex, min: min, contentType: contentType, sectionType: sectionType, enumType: enumType, enumValues: enumValues, type: type, formFields: formFields, annotations: annotations, standardReferences: standardReferences);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecField');
        if (positional.isEmpty) {
          throw ArgumentError('SpecField: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_11.SpecField.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').name,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').kind,
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').doc,
      'help': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').help,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').headline,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').sectionId,
      'sectionIdPattern': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').sectionIdPattern,
      'serializationOrder': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').serializationOrder,
      'elementType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').elementType,
      'elementIsComplex': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').elementIsComplex,
      'min': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').min,
      'contentType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').contentType,
      'sectionType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').sectionType,
      'enumType': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').enumType,
      'enumValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').enumValues,
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').type,
      'formFields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').formFields,
      'annotations': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').annotations,
      'standardReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').standardReferences,
      'isExpandable': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').isExpandable,
      'caseValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').caseValues,
      'isCase': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').isCase,
      'isUnused': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').isUnused,
      'comment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').comment,
      'reference': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').reference,
      'hasReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').hasReferences,
      'codeSpecKind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').codeSpecKind,
      'followUpKind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField').followUpKind,
    },
    methods: {
      'annotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField');
        D4.requireMinArgs(positional, 1, 'annotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotation');
        return t.annotation(name);
      },
      'annotationsNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField');
        D4.requireMinArgs(positional, 1, 'annotationsNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotationsNamed');
        return t.annotationsNamed(name);
      },
      'hasAnnotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecField>(target, 'SpecField');
        D4.requireMinArgs(positional, 1, 'hasAnnotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'hasAnnotation');
        return t.hasAnnotation(name);
      },
    },
    constructorSignatures: {
      '': 'SpecField({required String name, required SpecFieldKind kind, String? doc, String? help, String? headline, String? sectionId, String? sectionIdPattern, int? serializationOrder, String? elementType, bool elementIsComplex = false, int? min, String? contentType, String? sectionType, String? enumType, List<String> enumValues = const [], String? type, List<FormFieldSpec> formFields = const [], List<SpecAnnotation> annotations = const [], StandardReferences? standardReferences})',
      'fromJson': 'factory SpecField.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'annotation': 'SpecAnnotation? annotation(String name)',
      'annotationsNamed': 'List<SpecAnnotation> annotationsNamed(String name)',
      'hasAnnotation': 'bool hasAnnotation(String name)',
    },
    getterSignatures: {
      'name': 'String get name',
      'kind': 'SpecFieldKind get kind',
      'doc': 'String? get doc',
      'help': 'String? get help',
      'headline': 'String? get headline',
      'sectionId': 'String? get sectionId',
      'sectionIdPattern': 'String? get sectionIdPattern',
      'serializationOrder': 'int? get serializationOrder',
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
      'standardReferences': 'StandardReferences? get standardReferences',
      'isExpandable': 'bool get isExpandable',
      'caseValues': 'List<String> get caseValues',
      'isCase': 'bool get isCase',
      'isUnused': 'bool get isUnused',
      'comment': 'String? get comment',
      'reference': 'String? get reference',
      'hasReferences': 'bool get hasReferences',
      'codeSpecKind': 'KindLink? get codeSpecKind',
      'followUpKind': 'KindLink? get followUpKind',
    },
  );
}

// =============================================================================
// OneOfGroup Bridge
// =============================================================================

BridgedClass _createOneOfGroupBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.OneOfGroup,
    name: 'OneOfGroup',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.OneOfGroup,
    constructors: {
      '': (visitor, positional, named) {
        final discriminator = D4.getRequiredNamedArg<String>(named, 'discriminator', 'OneOfGroup');
        if (!named.containsKey('caseFields') || named['caseFields'] == null) {
          throw ArgumentError('OneOfGroup: Missing required named argument "caseFields"');
        }
        final caseFields = D4.coerceList<$tom_som_dart_runtime_11.SpecField>(named['caseFields'], 'caseFields');
        final note = D4.getOptionalNamedArg<String?>(named, 'note');
        final discriminatorField = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.FormFieldSpec?>(named, 'discriminatorField');
        return $tom_som_dart_runtime_11.OneOfGroup(discriminator: discriminator, caseFields: caseFields, note: note, discriminatorField: discriminatorField);
      },
    },
    getters: {
      'discriminator': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').discriminator,
      'note': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').note,
      'discriminatorField': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').discriminatorField,
      'caseFields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').caseFields,
      'discriminatorValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').discriminatorValues,
      'coveredValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').coveredValues,
      'uncoveredValues': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').uncoveredValues,
      'isComplete': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.OneOfGroup>(target, 'OneOfGroup').isComplete,
    },
    constructorSignatures: {
      '': 'const OneOfGroup({required String discriminator, required List<SpecField> caseFields, String? note, FormFieldSpec? discriminatorField})',
    },
    getterSignatures: {
      'discriminator': 'String get discriminator',
      'note': 'String? get note',
      'discriminatorField': 'FormFieldSpec? get discriminatorField',
      'caseFields': 'List<SpecField> get caseFields',
      'discriminatorValues': 'List<String> get discriminatorValues',
      'coveredValues': 'List<String> get coveredValues',
      'uncoveredValues': 'List<String> get uncoveredValues',
      'isComplete': 'bool get isComplete',
    },
  );
}

// =============================================================================
// SpecClass Bridge
// =============================================================================

BridgedClass _createSpecClassBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.SpecClass,
    name: 'SpecClass',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.SpecClass,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(named, 'name', 'SpecClass');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final doc = D4.getOptionalNamedArg<String?>(named, 'doc');
        final help = D4.getOptionalNamedArg<String?>(named, 'help');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final mapsTo = D4.getOptionalNamedArg<String?>(named, 'mapsTo');
        final detailedIn = D4.getOptionalNamedArg<String?>(named, 'detailedIn');
        final fields = named.containsKey('fields') && named['fields'] != null
            ? D4.coerceList<$tom_som_dart_runtime_11.SpecField>(named['fields'], 'fields')
            : const <$tom_som_dart_runtime_11.SpecField>[];
        final annotations = named.containsKey('annotations') && named['annotations'] != null
            ? D4.coerceList<$tom_som_dart_runtime_11.SpecAnnotation>(named['annotations'], 'annotations')
            : const <$tom_som_dart_runtime_11.SpecAnnotation>[];
        final standardReferences = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.StandardReferences?>(named, 'standardReferences');
        return $tom_som_dart_runtime_11.SpecClass(name: name, sectionId: sectionId, doc: doc, help: help, headline: headline, mapsTo: mapsTo, detailedIn: detailedIn, fields: fields, annotations: annotations, standardReferences: standardReferences);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecClass');
        if (positional.isEmpty) {
          throw ArgumentError('SpecClass: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_11.SpecClass.fromJson(j);
      },
    },
    getters: {
      'name': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').name,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').sectionId,
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').doc,
      'help': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').help,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').headline,
      'mapsTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').mapsTo,
      'detailedIn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').detailedIn,
      'fields': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').fields,
      'annotations': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').annotations,
      'standardReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').standardReferences,
      'oneOf': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').oneOf,
      'isCodeSpecsProjection': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').isCodeSpecsProjection,
      'isUnused': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').isUnused,
      'comment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').comment,
      'reference': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').reference,
      'hasReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').hasReferences,
      'codeSpecKind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').codeSpecKind,
      'followUpKind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass').followUpKind,
    },
    methods: {
      'fieldNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'fieldNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'fieldNamed');
        return t.fieldNamed(name);
      },
      'formFieldNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'formFieldNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'formFieldNamed');
        return t.formFieldNamed(name);
      },
      'annotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'annotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotation');
        return t.annotation(name);
      },
      'annotationsNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'annotationsNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotationsNamed');
        return t.annotationsNamed(name);
      },
      'hasAnnotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecClass>(target, 'SpecClass');
        D4.requireMinArgs(positional, 1, 'hasAnnotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'hasAnnotation');
        return t.hasAnnotation(name);
      },
    },
    constructorSignatures: {
      '': 'SpecClass({required String name, String? sectionId, String? doc, String? help, String? headline, String? mapsTo, String? detailedIn, List<SpecField> fields = const [], List<SpecAnnotation> annotations = const [], StandardReferences? standardReferences})',
      'fromJson': 'factory SpecClass.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'fieldNamed': 'SpecField? fieldNamed(String name)',
      'formFieldNamed': 'FormFieldSpec? formFieldNamed(String name)',
      'annotation': 'SpecAnnotation? annotation(String name)',
      'annotationsNamed': 'List<SpecAnnotation> annotationsNamed(String name)',
      'hasAnnotation': 'bool hasAnnotation(String name)',
    },
    getterSignatures: {
      'name': 'String get name',
      'sectionId': 'String? get sectionId',
      'doc': 'String? get doc',
      'help': 'String? get help',
      'headline': 'String? get headline',
      'mapsTo': 'String? get mapsTo',
      'detailedIn': 'String? get detailedIn',
      'fields': 'List<SpecField> get fields',
      'annotations': 'List<SpecAnnotation> get annotations',
      'standardReferences': 'StandardReferences? get standardReferences',
      'oneOf': 'OneOfGroup? get oneOf',
      'isCodeSpecsProjection': 'bool get isCodeSpecsProjection',
      'isUnused': 'bool get isUnused',
      'comment': 'String? get comment',
      'reference': 'String? get reference',
      'hasReferences': 'bool get hasReferences',
      'codeSpecKind': 'KindLink? get codeSpecKind',
      'followUpKind': 'KindLink? get followUpKind',
    },
  );
}

// =============================================================================
// SpecRoot Bridge
// =============================================================================

BridgedClass _createSpecRootBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.SpecRoot,
    name: 'SpecRoot',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.SpecRoot,
    constructors: {
      '': (visitor, positional, named) {
        final type = D4.getRequiredNamedArg<String>(named, 'type', 'SpecRoot');
        final title = D4.getRequiredNamedArg<String>(named, 'title', 'SpecRoot');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final description = D4.getOptionalNamedArg<String?>(named, 'description');
        final doc = D4.getOptionalNamedArg<String?>(named, 'doc');
        return $tom_som_dart_runtime_11.SpecRoot(type: type, title: title, sectionId: sectionId, description: description, doc: doc);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecRoot');
        if (positional.isEmpty) {
          throw ArgumentError('SpecRoot: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_11.SpecRoot.fromJson(j);
      },
    },
    getters: {
      'type': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecRoot>(target, 'SpecRoot').type,
      'title': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecRoot>(target, 'SpecRoot').title,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecRoot>(target, 'SpecRoot').sectionId,
      'description': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecRoot>(target, 'SpecRoot').description,
      'doc': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecRoot>(target, 'SpecRoot').doc,
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
// SpecModelStampCheck Bridge
// =============================================================================

BridgedClass _createSpecModelStampCheckBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.SpecModelStampCheck,
    name: 'SpecModelStampCheck',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.SpecModelStampCheck,
    constructors: {
      '': (visitor, positional, named) {
        final age = D4.getRequiredNamedArg<Duration?>(named, 'age', 'SpecModelStampCheck');
        final maxAge = D4.getRequiredNamedArg<Duration>(named, 'maxAge', 'SpecModelStampCheck');
        final declaredClassCount = D4.getRequiredNamedArg<int?>(named, 'declaredClassCount', 'SpecModelStampCheck');
        final actualClassCount = D4.getRequiredNamedArg<int>(named, 'actualClassCount', 'SpecModelStampCheck');
        final declaredRootCount = D4.getRequiredNamedArg<int?>(named, 'declaredRootCount', 'SpecModelStampCheck');
        final actualRootCount = D4.getRequiredNamedArg<int>(named, 'actualRootCount', 'SpecModelStampCheck');
        return $tom_som_dart_runtime_11.SpecModelStampCheck(age: age, maxAge: maxAge, declaredClassCount: declaredClassCount, actualClassCount: actualClassCount, declaredRootCount: declaredRootCount, actualRootCount: actualRootCount);
      },
    },
    getters: {
      'age': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').age,
      'maxAge': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').maxAge,
      'declaredClassCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').declaredClassCount,
      'actualClassCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').actualClassCount,
      'declaredRootCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').declaredRootCount,
      'actualRootCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').actualRootCount,
      'isAged': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').isAged,
      'classCountDisagrees': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').classCountDisagrees,
      'rootCountDisagrees': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').rootCountDisagrees,
      'countsDisagree': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').countsDisagree,
      'isStale': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').isStale,
      'warnings': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModelStampCheck>(target, 'SpecModelStampCheck').warnings,
    },
    constructorSignatures: {
      '': 'const SpecModelStampCheck({required Duration? age, required Duration maxAge, required int? declaredClassCount, required int actualClassCount, required int? declaredRootCount, required int actualRootCount})',
    },
    getterSignatures: {
      'age': 'Duration? get age',
      'maxAge': 'Duration get maxAge',
      'declaredClassCount': 'int? get declaredClassCount',
      'actualClassCount': 'int get actualClassCount',
      'declaredRootCount': 'int? get declaredRootCount',
      'actualRootCount': 'int get actualRootCount',
      'isAged': 'bool get isAged',
      'classCountDisagrees': 'bool get classCountDisagrees',
      'rootCountDisagrees': 'bool get rootCountDisagrees',
      'countsDisagree': 'bool get countsDisagree',
      'isStale': 'bool get isStale',
      'warnings': 'List<String> get warnings',
    },
  );
}

// =============================================================================
// SpecModel Bridge
// =============================================================================

BridgedClass _createSpecModelBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.SpecModel,
    name: 'SpecModel',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.SpecModel,
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('roots') || named['roots'] == null) {
          throw ArgumentError('SpecModel: Missing required named argument "roots"');
        }
        final roots = D4.coerceList<$tom_som_dart_runtime_11.SpecRoot>(named['roots'], 'roots');
        if (!named.containsKey('classes') || named['classes'] == null) {
          throw ArgumentError('SpecModel: Missing required named argument "classes"');
        }
        final classes = D4.coerceMap<String, $tom_som_dart_runtime_11.SpecClass>(named['classes'], 'classes');
        final modelVersion = D4.getNamedArgWithDefault<int>(named, 'modelVersion', 0);
        final modelVersionLabel = D4.getOptionalNamedArg<String?>(named, 'modelVersionLabel');
        final generatedAt = D4.getOptionalNamedArg<DateTime?>(named, 'generatedAt');
        final metaSchemaVersion = D4.getOptionalNamedArg<int?>(named, 'metaSchemaVersion');
        final classCount = D4.getOptionalNamedArg<int?>(named, 'classCount');
        final rootCount = D4.getOptionalNamedArg<int?>(named, 'rootCount');
        final containerRoot = D4.getOptionalNamedArg<String?>(named, 'containerRoot');
        return $tom_som_dart_runtime_11.SpecModel(roots: roots, classes: classes, modelVersion: modelVersion, modelVersionLabel: modelVersionLabel, generatedAt: generatedAt, metaSchemaVersion: metaSchemaVersion, classCount: classCount, rootCount: rootCount, containerRoot: containerRoot);
      },
      'fromJson': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecModel');
        if (positional.isEmpty) {
          throw ArgumentError('SpecModel: Missing required argument "j" at position 0');
        }
        final j = D4.coerceMap<String, dynamic>(positional[0], 'j');
        return $tom_som_dart_runtime_11.SpecModel.fromJson(j);
      },
    },
    getters: {
      'roots': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').roots,
      'classes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').classes,
      'modelVersion': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').modelVersion,
      'modelVersionLabel': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').modelVersionLabel,
      'generatedAt': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').generatedAt,
      'metaSchemaVersion': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').metaSchemaVersion,
      'classCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').classCount,
      'rootCount': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').rootCount,
      'containerRoot': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').containerRoot,
      'modelVersionString': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel').modelVersionString,
    },
    methods: {
      'checkStamp': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel');
        final now = D4.getOptionalNamedArg<DateTime?>(named, 'now');
        if (!named.containsKey('maxAge')) {
          return t.checkStamp(now: now);
        }
        if (named.containsKey('maxAge')) {
          final maxAge = D4.getRequiredNamedArg<Duration>(named, 'maxAge', 'checkStamp');
          return t.checkStamp(now: now, maxAge: maxAge);
        }
        throw StateError('Unreachable: all named parameter combinations should be covered');
      },
      'classNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel');
        D4.requireMinArgs(positional, 1, 'classNamed');
        final name = D4.getRequiredArg<String?>(positional, 0, 'name', 'classNamed');
        return t.classNamed(name);
      },
      'isGenerationInput': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel');
        D4.requireMinArgs(positional, 1, 'isGenerationInput');
        final root = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecRoot>(positional, 0, 'root', 'isGenerationInput');
        return t.isGenerationInput(root);
      },
      'rootByType': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.SpecModel>(target, 'SpecModel');
        D4.requireMinArgs(positional, 1, 'rootByType');
        final type = D4.getRequiredArg<String>(positional, 0, 'type', 'rootByType');
        return t.rootByType(type);
      },
    },
    constructorSignatures: {
      '': 'SpecModel({required List<SpecRoot> roots, required Map<String, SpecClass> classes, int modelVersion = 0, String? modelVersionLabel, DateTime? generatedAt, int? metaSchemaVersion, int? classCount, int? rootCount, String? containerRoot})',
      'fromJson': 'factory SpecModel.fromJson(Map<String, dynamic> j)',
    },
    methodSignatures: {
      'checkStamp': 'SpecModelStampCheck checkStamp({Duration maxAge = defaultMaxSnapshotAge, DateTime? now})',
      'classNamed': 'SpecClass? classNamed(String? name)',
      'isGenerationInput': 'bool isGenerationInput(SpecRoot root)',
      'rootByType': 'SpecRoot rootByType(String type)',
    },
    getterSignatures: {
      'roots': 'List<SpecRoot> get roots',
      'classes': 'Map<String, SpecClass> get classes',
      'modelVersion': 'int get modelVersion',
      'modelVersionLabel': 'String? get modelVersionLabel',
      'generatedAt': 'DateTime? get generatedAt',
      'metaSchemaVersion': 'int? get metaSchemaVersion',
      'classCount': 'int? get classCount',
      'rootCount': 'int? get rootCount',
      'containerRoot': 'String? get containerRoot',
      'modelVersionString': 'String get modelVersionString',
    },
  );
}

// =============================================================================
// AnnotatedSpecNode Bridge
// =============================================================================

BridgedClass _createAnnotatedSpecNodeBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_11.AnnotatedSpecNode,
    name: 'AnnotatedSpecNode',
    isAssignable: (v) => v is $tom_som_dart_runtime_11.AnnotatedSpecNode,
    canBeUsedAsMixin: true,
    isAbstract: true,
    constructors: {
    },
    getters: {
      'annotations': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').annotations,
      'standardReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').standardReferences,
      'isUnused': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').isUnused,
      'comment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').comment,
      'reference': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').reference,
      'hasReferences': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').hasReferences,
      'codeSpecKind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').codeSpecKind,
      'followUpKind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode').followUpKind,
    },
    methods: {
      'annotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode');
        D4.requireMinArgs(positional, 1, 'annotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotation');
        return t.annotation(name);
      },
      'annotationsNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode');
        D4.requireMinArgs(positional, 1, 'annotationsNamed');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'annotationsNamed');
        return t.annotationsNamed(name);
      },
      'hasAnnotation': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_11.AnnotatedSpecNode>(target, 'AnnotatedSpecNode');
        D4.requireMinArgs(positional, 1, 'hasAnnotation');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'hasAnnotation');
        return t.hasAnnotation(name);
      },
    },
    methodSignatures: {
      'annotation': 'SpecAnnotation? annotation(String name)',
      'annotationsNamed': 'List<SpecAnnotation> annotationsNamed(String name)',
      'hasAnnotation': 'bool hasAnnotation(String name)',
    },
    getterSignatures: {
      'annotations': 'List<SpecAnnotation> get annotations',
      'standardReferences': 'StandardReferences? get standardReferences',
      'isUnused': 'bool get isUnused',
      'comment': 'String? get comment',
      'reference': 'String? get reference',
      'hasReferences': 'bool get hasReferences',
      'codeSpecKind': 'KindLink? get codeSpecKind',
      'followUpKind': 'KindLink? get followUpKind',
    },
  );
}

// =============================================================================
// SpecCreationError Bridge
// =============================================================================

BridgedClass _createSpecCreationErrorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_12.SpecCreationError,
    name: 'SpecCreationError',
    isAssignable: (v) => v is $tom_som_dart_runtime_12.SpecCreationError,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        final parentPath = D4.getRequiredNamedArg<String>(named, 'parentPath', 'SpecCreationError');
        final childSegment = D4.getRequiredNamedArg<String>(named, 'childSegment', 'SpecCreationError');
        final code = D4.getRequiredNamedArg<$tom_som_dart_runtime_12.SpecCreationCode>(named, 'code', 'SpecCreationError');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'SpecCreationError');
        return $tom_som_dart_runtime_12.SpecCreationError(parentPath: parentPath, childSegment: childSegment, code: code, message: message);
      },
    },
    getters: {
      'parentPath': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_12.SpecCreationError>(target, 'SpecCreationError').parentPath,
      'childSegment': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_12.SpecCreationError>(target, 'SpecCreationError').childSegment,
      'code': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_12.SpecCreationError>(target, 'SpecCreationError').code,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_12.SpecCreationError>(target, 'SpecCreationError').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_12.SpecCreationError>(target, 'SpecCreationError');
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
    nativeType: $tom_som_dart_runtime_12.SpecNodeCreator,
    name: 'SpecNodeCreator',
    isAssignable: (v) => v is $tom_som_dart_runtime_12.SpecNodeCreator,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecNodeCreator');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'SpecNodeCreator');
        final document = D4.getRequiredArg<$tom_som_dart_runtime_4.SpecDocument>(positional, 1, 'document', 'SpecNodeCreator');
        return $tom_som_dart_runtime_12.SpecNodeCreator(model, document);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_12.SpecNodeCreator>(target, 'SpecNodeCreator').model,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_12.SpecNodeCreator>(target, 'SpecNodeCreator').document,
    },
    methods: {
      'add': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_12.SpecNodeCreator>(target, 'SpecNodeCreator');
        D4.requireMinArgs(positional, 2, 'add');
        final parentPath = D4.getRequiredArg<String>(positional, 0, 'parentPath', 'add');
        final childSegment = D4.getRequiredArg<String>(positional, 1, 'childSegment', 'add');
        final itemId = D4.getOptionalNamedArg<String?>(named, 'itemId');
        final date = D4.getOptionalNamedArg<DateTime?>(named, 'date');
        return t.add(parentPath, childSegment, itemId: itemId, date: date);
      },
    },
    constructorSignatures: {
      '': 'const SpecNodeCreator(SpecModel model, SpecDocument document)',
    },
    methodSignatures: {
      'add': 'String add(String parentPath, String childSegment, {String? itemId, DateTime? date})',
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
    nativeType: $tom_som_dart_runtime_14.SpecMatchSpan,
    name: 'SpecMatchSpan',
    isAssignable: (v) => v is $tom_som_dart_runtime_14.SpecMatchSpan,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecMatchSpan');
        final start = D4.getRequiredArg<int>(positional, 0, 'start', 'SpecMatchSpan');
        final end = D4.getRequiredArg<int>(positional, 1, 'end', 'SpecMatchSpan');
        return $tom_som_dart_runtime_14.SpecMatchSpan(start, end);
      },
    },
    getters: {
      'start': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecMatchSpan>(target, 'SpecMatchSpan').start,
      'end': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecMatchSpan>(target, 'SpecMatchSpan').end,
      'hashCode': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecMatchSpan>(target, 'SpecMatchSpan').hashCode,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecMatchSpan>(target, 'SpecMatchSpan');
        return t.toString();
      },
      '==': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecMatchSpan>(target, 'SpecMatchSpan');
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
// SpecNodeProjection Bridge
// =============================================================================

BridgedClass _createSpecNodeProjectionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_14.SpecNodeProjection,
    name: 'SpecNodeProjection',
    isAssignable: (v) => v is $tom_som_dart_runtime_14.SpecNodeProjection,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecNodeProjection');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_15.SpecNodeKind>(named, 'kind', 'SpecNodeProjection');
        final classId = D4.getOptionalNamedArg<String?>(named, 'classId');
        final sectionId = D4.getOptionalNamedArg<String?>(named, 'sectionId');
        final mapsTo = D4.getOptionalNamedArg<String?>(named, 'mapsTo');
        final detailedIn = D4.getOptionalNamedArg<String?>(named, 'detailedIn');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final searchableStrings = named.containsKey('searchableStrings') && named['searchableStrings'] != null
            ? D4.coerceList<String>(named['searchableStrings'], 'searchableStrings')
            : const <String>[];
        final hasValue = D4.getNamedArgWithDefault<bool>(named, 'hasValue', false);
        return $tom_som_dart_runtime_14.SpecNodeProjection(path: path, kind: kind, classId: classId, sectionId: sectionId, mapsTo: mapsTo, detailedIn: detailedIn, headline: headline, searchableStrings: searchableStrings, hasValue: hasValue);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').path,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').kind,
      'classId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').classId,
      'sectionId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').sectionId,
      'mapsTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').mapsTo,
      'detailedIn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').detailedIn,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').headline,
      'searchableStrings': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').searchableStrings,
      'hasValue': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection').hasValue,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecNodeProjection>(target, 'SpecNodeProjection');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SpecNodeProjection({required String path, required SpecNodeKind kind, String? classId, String? sectionId, String? mapsTo, String? detailedIn, String? headline, List<String> searchableStrings = const [], bool hasValue = false})',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'path': 'String get path',
      'kind': 'SpecNodeKind get kind',
      'classId': 'String? get classId',
      'sectionId': 'String? get sectionId',
      'mapsTo': 'String? get mapsTo',
      'detailedIn': 'String? get detailedIn',
      'headline': 'String? get headline',
      'searchableStrings': 'List<String> get searchableStrings',
      'hasValue': 'bool get hasValue',
    },
  );
}

// =============================================================================
// SpecQueryMatch Bridge
// =============================================================================

BridgedClass _createSpecQueryMatchBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_14.SpecQueryMatch,
    name: 'SpecQueryMatch',
    isAssignable: (v) => v is $tom_som_dart_runtime_14.SpecQueryMatch,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecQueryMatch');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_15.SpecNodeKind>(named, 'kind', 'SpecQueryMatch');
        final classId = D4.getOptionalNamedArg<String?>(named, 'classId');
        final headline = D4.getOptionalNamedArg<String?>(named, 'headline');
        final snippet = D4.getOptionalNamedArg<String?>(named, 'snippet');
        final matchSpans = named.containsKey('matchSpans') && named['matchSpans'] != null
            ? D4.coerceList<$tom_som_dart_runtime_14.SpecMatchSpan>(named['matchSpans'], 'matchSpans')
            : const <$tom_som_dart_runtime_14.SpecMatchSpan>[];
        return $tom_som_dart_runtime_14.SpecQueryMatch(path: path, kind: kind, classId: classId, headline: headline, snippet: snippet, matchSpans: matchSpans);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch').path,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch').kind,
      'classId': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch').classId,
      'headline': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch').headline,
      'snippet': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch').snippet,
      'matchSpans': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch').matchSpans,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryMatch>(target, 'SpecQueryMatch');
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
    nativeType: $tom_som_dart_runtime_14.SpecQuery,
    name: 'SpecQuery',
    isAssignable: (v) => v is $tom_som_dart_runtime_14.SpecQuery,
    constructors: {
      '': (visitor, positional, named) {
        final text = D4.getOptionalNamedArg<String?>(named, 'text');
        final regex = D4.getNamedArgWithDefault<bool>(named, 'regex', false);
        final caseInsensitive = D4.getNamedArgWithDefault<bool>(named, 'caseInsensitive', false);
        final kinds = D4.coerceSetOrNull<$tom_som_dart_runtime_15.SpecNodeKind>(named['kinds'], 'kinds');
        final className = D4.getOptionalNamedArg<String?>(named, 'className');
        final sectionIdExact = D4.getOptionalNamedArg<String?>(named, 'sectionIdExact');
        final sectionIdPrefix = D4.getOptionalNamedArg<String?>(named, 'sectionIdPrefix');
        final pathGlob = D4.getOptionalNamedArg<String?>(named, 'pathGlob');
        final mapsTo = D4.getOptionalNamedArg<String?>(named, 'mapsTo');
        final detailedIn = D4.getOptionalNamedArg<String?>(named, 'detailedIn');
        final state = D4.getOptionalNamedArg<$tom_som_dart_runtime_14.SpecStateFilter?>(named, 'state');
        return $tom_som_dart_runtime_14.SpecQuery(text: text, regex: regex, caseInsensitive: caseInsensitive, kinds: kinds, className: className, sectionIdExact: sectionIdExact, sectionIdPrefix: sectionIdPrefix, pathGlob: pathGlob, mapsTo: mapsTo, detailedIn: detailedIn, state: state);
      },
    },
    getters: {
      'text': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').text,
      'regex': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').regex,
      'caseInsensitive': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').caseInsensitive,
      'kinds': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').kinds,
      'className': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').className,
      'sectionIdExact': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').sectionIdExact,
      'sectionIdPrefix': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').sectionIdPrefix,
      'pathGlob': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').pathGlob,
      'mapsTo': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').mapsTo,
      'detailedIn': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').detailedIn,
      'state': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQuery>(target, 'SpecQuery').state,
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
    nativeType: $tom_som_dart_runtime_14.SpecQueryEngine,
    name: 'SpecQueryEngine',
    isAssignable: (v) => v is $tom_som_dart_runtime_14.SpecQueryEngine,
    constructors: {
      '': (visitor, positional, named) {
        final model = D4.getRequiredNamedArg<$tom_som_dart_runtime_11.SpecModel>(named, 'model', 'SpecQueryEngine');
        final document = D4.getRequiredNamedArg<$tom_som_dart_runtime_4.SpecDocument>(named, 'document', 'SpecQueryEngine');
        return $tom_som_dart_runtime_14.SpecQueryEngine(model: model, document: document);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryEngine>(target, 'SpecQueryEngine').model,
      'document': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryEngine>(target, 'SpecQueryEngine').document,
    },
    methods: {
      'query': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryEngine>(target, 'SpecQueryEngine');
        D4.requireMinArgs(positional, 1, 'query');
        final query = D4.getRequiredArg<$tom_som_dart_runtime_14.SpecQuery>(positional, 0, 'query', 'query');
        return t.query(query);
      },
      'projectNodes': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryEngine>(target, 'SpecQueryEngine');
        return t.projectNodes();
      },
      'projectNode': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryEngine>(target, 'SpecQueryEngine');
        D4.requireMinArgs(positional, 1, 'projectNode');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'projectNode');
        return t.projectNode(path);
      },
    },
    constructorSignatures: {
      '': 'SpecQueryEngine({required SpecModel model, required SpecDocument document})',
    },
    methodSignatures: {
      'query': 'SpecQueryCursor query(SpecQuery query)',
      'projectNodes': 'Iterable<SpecNodeProjection> projectNodes()',
      'projectNode': 'SpecNodeProjection? projectNode(String path)',
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
    nativeType: $tom_som_dart_runtime_14.SpecQueryCursor,
    name: 'SpecQueryCursor',
    isAssignable: (v) => v is $tom_som_dart_runtime_14.SpecQueryCursor,
    constructors: {
    },
    getters: {
      'count': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryCursor>(target, 'SpecQueryCursor').count,
    },
    methods: {
      'next': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryCursor>(target, 'SpecQueryCursor');
        return t.next();
      },
      'take': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryCursor>(target, 'SpecQueryCursor');
        D4.requireMinArgs(positional, 1, 'take');
        final n = D4.getRequiredArg<int>(positional, 0, 'n', 'take');
        return t.take(n);
      },
      'toList': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_14.SpecQueryCursor>(target, 'SpecQueryCursor');
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
// SpecSectionIdCollision Bridge
// =============================================================================

BridgedClass _createSpecSectionIdCollisionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_16.SpecSectionIdCollision,
    name: 'SpecSectionIdCollision',
    isAssignable: (v) => v is $tom_som_dart_runtime_16.SpecSectionIdCollision,
    hierarchyDepth: 1,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'SpecSectionIdCollision');
        final id = D4.getRequiredArg<String>(positional, 0, 'id', 'SpecSectionIdCollision');
        final listPath = D4.getRequiredArg<String>(positional, 1, 'listPath', 'SpecSectionIdCollision');
        return $tom_som_dart_runtime_16.SpecSectionIdCollision(id, listPath);
      },
    },
    getters: {
      'id': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_16.SpecSectionIdCollision>(target, 'SpecSectionIdCollision').id,
      'listPath': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_16.SpecSectionIdCollision>(target, 'SpecSectionIdCollision').listPath,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_16.SpecSectionIdCollision>(target, 'SpecSectionIdCollision');
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const SpecSectionIdCollision(String id, String listPath)',
    },
    methodSignatures: {
      'toString': 'String toString()',
    },
    getterSignatures: {
      'id': 'String get id',
      'listPath': 'String get listPath',
    },
  );
}

// =============================================================================
// SpecResolution Bridge
// =============================================================================

BridgedClass _createSpecResolutionBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_15.SpecResolution,
    name: 'SpecResolution',
    isAssignable: (v) => v is $tom_som_dart_runtime_15.SpecResolution,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecResolution');
        final kind = D4.getRequiredNamedArg<$tom_som_dart_runtime_15.SpecNodeKind>(named, 'kind', 'SpecResolution');
        final root = D4.getRequiredNamedArg<$tom_som_dart_runtime_11.SpecRoot>(named, 'root', 'SpecResolution');
        final field = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.SpecField?>(named, 'field');
        final targetClass = D4.getOptionalNamedArg<$tom_som_dart_runtime_11.SpecClass?>(named, 'targetClass');
        return $tom_som_dart_runtime_15.SpecResolution(path: path, kind: kind, root: root, field: field, targetClass: targetClass);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecResolution>(target, 'SpecResolution').path,
      'kind': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecResolution>(target, 'SpecResolution').kind,
      'root': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecResolution>(target, 'SpecResolution').root,
      'field': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecResolution>(target, 'SpecResolution').field,
      'targetClass': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecResolution>(target, 'SpecResolution').targetClass,
      'isValueLeaf': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecResolution>(target, 'SpecResolution').isValueLeaf,
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
    nativeType: $tom_som_dart_runtime_15.SpecReflection,
    name: 'SpecReflection',
    isAssignable: (v) => v is $tom_som_dart_runtime_15.SpecReflection,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecReflection');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'SpecReflection');
        return $tom_som_dart_runtime_15.SpecReflection(model);
      },
    },
    getters: {
      'model': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection').model,
      'roots': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection').roots,
      'classes': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection').classes,
    },
    methods: {
      'classNamed': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'classNamed');
        final name = D4.getRequiredArg<String?>(positional, 0, 'name', 'classNamed');
        return t.classNamed(name);
      },
      'fieldsOf': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'fieldsOf');
        final className = D4.getRequiredArg<String>(positional, 0, 'className', 'fieldsOf');
        return t.fieldsOf(className);
      },
      'annotationsOf': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'annotationsOf');
        final className = D4.getRequiredArg<String>(positional, 0, 'className', 'annotationsOf');
        return t.annotationsOf(className);
      },
      'fieldAnnotations': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 2, 'fieldAnnotations');
        final className = D4.getRequiredArg<String>(positional, 0, 'className', 'fieldAnnotations');
        final fieldName = D4.getRequiredArg<String>(positional, 1, 'fieldName', 'fieldAnnotations');
        return t.fieldAnnotations(className, fieldName);
      },
      'reachableClassNames': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'reachableClassNames');
        final typeName = D4.getRequiredArg<String>(positional, 0, 'typeName', 'reachableClassNames');
        return t.reachableClassNames(typeName);
      },
      'rootSegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'rootSegment');
        final root = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecRoot>(positional, 0, 'root', 'rootSegment');
        return t.rootSegment(root);
      },
      'fieldSegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'fieldSegment');
        final field = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecField>(positional, 0, 'field', 'fieldSegment');
        return t.fieldSegment(field);
      },
      'rootForSegment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
        D4.requireMinArgs(positional, 1, 'rootForSegment');
        final segment = D4.getRequiredArg<String>(positional, 0, 'segment', 'rootForSegment');
        return t.rootForSegment(segment);
      },
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_15.SpecReflection>(target, 'SpecReflection');
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
      'reachableClassNames': 'Set<String> reachableClassNames(String typeName)',
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
// SpecSerializationOrder Bridge
// =============================================================================

BridgedClass _createSpecSerializationOrderBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_17.SpecSerializationOrder,
    name: 'SpecSerializationOrder',
    isAssignable: (v) => v is $tom_som_dart_runtime_17.SpecSerializationOrder,
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'SpecSerializationOrder');
        final model = D4.getRequiredArg<$tom_som_dart_runtime_11.SpecModel>(positional, 0, 'model', 'SpecSerializationOrder');
        return $tom_som_dart_runtime_17.SpecSerializationOrder(model);
      },
    },
    methods: {
      'orderKey': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_17.SpecSerializationOrder>(target, 'SpecSerializationOrder');
        D4.requireMinArgs(positional, 1, 'orderKey');
        final path = D4.getRequiredArg<String>(positional, 0, 'path', 'orderKey');
        return t.orderKey(path);
      },
      'orderPaths': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_17.SpecSerializationOrder>(target, 'SpecSerializationOrder');
        D4.requireMinArgs(positional, 1, 'orderPaths');
        if (positional.isEmpty) {
          throw ArgumentError('orderPaths: Missing required argument "paths" at position 0');
        }
        final paths = D4.coerceList<String>(positional[0], 'paths');
        return t.orderPaths(paths);
      },
      'orderFormFields': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_17.SpecSerializationOrder>(target, 'SpecSerializationOrder');
        D4.requireMinArgs(positional, 2, 'orderFormFields');
        final formPath = D4.getRequiredArg<String>(positional, 0, 'formPath', 'orderFormFields');
        if (positional.length <= 1) {
          throw ArgumentError('orderFormFields: Missing required argument "fieldNames" at position 1');
        }
        final fieldNames = D4.coerceList<String>(positional[1], 'fieldNames');
        return t.orderFormFields(formPath, fieldNames);
      },
    },
    constructorSignatures: {
      '': 'SpecSerializationOrder(SpecModel model)',
    },
    methodSignatures: {
      'orderKey': 'List<int> orderKey(String path)',
      'orderPaths': 'List<String> orderPaths(Iterable<String> paths)',
      'orderFormFields': 'List<String> orderFormFields(String formPath, Iterable<String> fieldNames)',
    },
  );
}

// =============================================================================
// SpecValidationError Bridge
// =============================================================================

BridgedClass _createSpecValidationErrorBridge() {
  return BridgedClass(
    nativeType: $tom_som_dart_runtime_19.SpecValidationError,
    name: 'SpecValidationError',
    isAssignable: (v) => v is $tom_som_dart_runtime_19.SpecValidationError,
    constructors: {
      '': (visitor, positional, named) {
        final path = D4.getRequiredNamedArg<String>(named, 'path', 'SpecValidationError');
        final code = D4.getRequiredNamedArg<$tom_som_dart_runtime_19.SpecValidationCode>(named, 'code', 'SpecValidationError');
        final message = D4.getRequiredNamedArg<String>(named, 'message', 'SpecValidationError');
        return $tom_som_dart_runtime_19.SpecValidationError(path: path, code: code, message: message);
      },
    },
    getters: {
      'path': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_19.SpecValidationError>(target, 'SpecValidationError').path,
      'code': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_19.SpecValidationError>(target, 'SpecValidationError').code,
      'message': (visitor, target) => D4.validateTarget<$tom_som_dart_runtime_19.SpecValidationError>(target, 'SpecValidationError').message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_som_dart_runtime_19.SpecValidationError>(target, 'SpecValidationError');
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

