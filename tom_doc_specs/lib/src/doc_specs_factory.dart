import 'package:tom_doc_scanner/tom_doc_scanner.dart';
import 'models/spec_doc.dart';
import 'models/spec_section.dart';
import 'models/schema/doc_spec_schema.dart';
import 'reading/body_reader.dart';
import 'reading/reading_grammar.dart';
import 'validation/validation_error.dart';

/// Factory for creating [SpecDoc] and [SpecSection] objects.
///
/// Extends [DocScannerFactory] to inject DocSpecs-specific functionality
/// during document parsing. The factory receives a schema and uses it to
/// resolve section types by prefix matching.
///
/// ## Example
///
/// ```dart
/// final schema = DocSpecs.loadSchemaSync(
///   schemaId: 'quest-overview/1.0',
///   documentPath: 'quest_overview.md',
/// );
/// final factory = DocSpecsFactory(schema: schema);
///
/// final doc = DocScanner.scanDocumentSync(
///   filepath: 'quest_overview.md',
///   factory: factory,
/// ) as SpecDoc;
/// ```
class DocSpecsFactory extends DocScannerFactory {
  /// The schema used for section type resolution.
  final DocSpecSchema? schema;

  /// Access keys from the schema (section name -> access key).
  final Map<String, String> _accessKeys;

  /// Creates a new DocSpecsFactory.
  ///
  /// If [schema] is provided, section types will be resolved by prefix
  /// matching in YAML declaration order.
  ///
  /// [missingSchemaId] and [schemaSearchFolders] are given to every document
  /// it creates: the schema id that was looked for and not found, and where.
  DocSpecsFactory({
    this.schema,
    this.missingSchemaId,
    this.schemaSearchFolders = const [],
  }) : _accessKeys = _extractAccessKeys(schema);

  /// The schema id that was declared or given and not found, if any.
  final String? missingSchemaId;

  /// The folders searched for [missingSchemaId].
  final List<String> schemaSearchFolders;

  /// Extracts access keys from the schema's document structure.
  static Map<String, String> _extractAccessKeys(DocSpecSchema? schema) {
    if (schema?.document.sections == null) return const {};

    final keys = <String, String>{};
    for (final entry in schema!.document.sections.entries) {
      final accessKey = entry.value.accessKey;
      if (accessKey != null) {
        keys[entry.key] = accessKey;
      }
    }
    return keys;
  }

  @override
  Section createSection({
    required int index,
    required int lineNumber,
    required String rawHeadline,
    required String name,
    required String id,
    required String text,
    required Map<String, String> fields,
    List<Section>? sections,
    int? textLineNumber,
  }) {
    // Determine section type by matching ID against prefix (YAML declaration order)
    final schema = this.schema;
    final sectionType = schema?.resolveSectionType(id);
    final typeDef = sectionType == null
        ? null
        : schema!.sectionTypes[sectionType];

    // Parse tags from fields
    final tags =
        fields['tags']?.split(',').map((t) => t.trim()).toList() ?? <String>[];

    // The section's body as the schema reads it: its section tables and its
    // list body become sections of the tree (DocSpecs specification, List
    // Bodies), and the reading-notation findings are kept for the validator.
    var body = ReadBody(
      text: text,
      textLineNumber: textLineNumber,
      sections: sections,
      findings: const [],
    );
    final findings = <ValidationError>[];
    if (schema != null) {
      findings.addAll(
        ReadingGrammar.notationFindings(text, textLineNumber, id),
      );
      if (typeDef != null) {
        body = BodyReader(schema).read(
          id: id,
          type: typeDef,
          allowed: (t) => typeDef.subsectionTypes?.containsKey(t) ?? false,
          text: text,
          textLineNumber: textLineNumber,
          children: sections,
        );
        findings.addAll(body.findings);
      }
    }

    return SpecSection(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: body.text,
      fields: fields,
      sections: body.sections,
      textLineNumber: body.textLineNumber,
      type: sectionType,
      tags: tags,
      format: typeDef?.format,
      readingFindings: findings,
    );
  }

  @override
  Document createDocument({
    required int index,
    required int lineNumber,
    required String rawHeadline,
    required String name,
    required String id,
    required String text,
    required Map<String, String> fields,
    List<Section>? sections,
    required String filenameWithPath,
    required String loadTimestamp,
    required String filename,
    required String fullPath,
    required String workspacePath,
    required String project,
    required String projectPath,
    required String workspaceRoot,
    required String projectRoot,
    required int hierarchyDepth,
    int? textLineNumber,
  }) {
    // The root's body may hold a section table of its children.
    final schema = this.schema;
    var body = ReadBody(
      text: text,
      textLineNumber: textLineNumber,
      sections: sections,
      findings: const [],
    );
    final findings = <ValidationError>[];
    if (schema != null) {
      findings.addAll(
        ReadingGrammar.notationFindings(text, textLineNumber, id),
      );
      final topLevel = {
        for (final s in schema.document.sections.values) s.sectionType,
      };
      body = BodyReader(schema).read(
        id: id,
        type: null,
        allowed: topLevel.contains,
        text: text,
        textLineNumber: textLineNumber,
        children: sections,
      );
      findings.addAll(body.findings);
    }
    return SpecDoc(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: body.text,
      fields: fields,
      sections: body.sections,
      textLineNumber: body.textLineNumber,
      readingFindings: findings,
      filenameWithPath: filenameWithPath,
      loadTimestamp: loadTimestamp,
      filename: filename,
      fullPath: fullPath,
      workspacePath: workspacePath,
      project: project,
      projectPath: projectPath,
      workspaceRoot: workspaceRoot,
      projectRoot: projectRoot,
      hierarchyDepth: hierarchyDepth,
      schemaId:
          fields['schema'] ??
          (schema != null ? '${schema.id}/${schema.version}' : ''),
      accessKeys: _accessKeys,
      // The factory is constructed with the resolved schema and `DocSpecs`
      // validates iff that schema is non-null, so this is the same condition
      // read once rather than two that can drift.
      wasValidated: schema != null,
      missingSchemaId: missingSchemaId,
      schemaSearchFolders: schemaSearchFolders,
    );
  }
}
