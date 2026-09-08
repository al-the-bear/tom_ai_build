/// @docImport 'models/spec_section.dart';
library;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:tom_doc_scanner/tom_doc_scanner.dart';
import 'doc_specs_factory.dart';
import 'models/schema/doc_spec_schema.dart';
import 'models/schema/schema_info.dart';
import 'models/spec_doc.dart';
import 'schema/schema_loader.dart';
import 'validation/ai_validator.dart';
import 'validation/validator.dart';

/// DocSpecs - Document schema validation system.
///
/// Provides static methods to scan, validate, and access structured markdown
/// documents against defined schemas. Extends DocScanner with schema definitions
/// and typed section access.
///
/// ## Example
///
/// ```dart
/// // Scan and validate a document
/// final doc = await DocSpecs.scanDocument(
///   filePath: 'quest_overview.docspec.md',
/// );
///
/// if (!doc.isValid) {
///   print('Validation errors: ${doc.validationErrors}');
/// }
///
/// // Access typed sections
/// final todos = doc.getSpecSectionType('todo').getAll();
/// for (final todo in todos) {
///   print('TODO: ${todo.id}');
/// }
///
/// // List available schemas
/// final schemas = await DocSpecs.listSchemas(documentPath: 'docs/');
/// for (final schema in schemas) {
///   print('Schema: ${schema.fullId}');
/// }
/// ```
class DocSpecs {
  /// Private constructor to prevent instantiation.
  DocSpecs._();

  /// Load and validate a single document (async).
  ///
  /// The schema is determined from:
  /// 1. The [schemaId] parameter if provided
  /// 2. The document's `schema` field in the first headline
  ///
  /// [schemaFolder] names a directory of `*.docspecs-schema.yaml` files to
  /// search *before* the `.tom/docspecs-schema/` folders found by walking up
  /// from the document. Without it a caller whose schemas live anywhere else
  /// cannot validate at all: `SchemaResolver` has always accepted the
  /// parameter, but nothing plumbed it through, so the resolve silently
  /// returned null and the document scanned as schemaless — which reports no
  /// errors and reads exactly like a pass. This package's own fixtures were in
  /// that position.
  static Future<SpecDoc> scanDocument({
    required String filePath,
    String? schemaId,
    String? workspaceRoot,
    String? schemaFolder,
  }) async {
    final absolutePath = _toAbsolutePath(filePath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    // Read document to extract schema ID
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw ArgumentError('Document not found: $absolutePath');
    }

    // Determine schema ID
    final effectiveSchemaId = schemaId ?? await _extractSchemaId(absolutePath);

    // Load schema
    DocSpecSchema? schema;
    if (effectiveSchemaId != null) {
      schema = await SchemaResolver.resolve(
        schemaId: effectiveSchemaId,
        documentPath: absolutePath,
        workspaceRoot: wsRoot,
        schemaFolder: schemaFolder,
      );
    }

    // Create factory with schema
    final factory = DocSpecsFactory(schema: schema);

    // Scan document using DocScanner
    final doc = await DocScanner.scanDocument(
      filepath: absolutePath,
      workspaceRoot: wsRoot,
      factory: factory,
    );

    // Cast to SpecDoc and validate
    final specDoc = doc as SpecDoc;

    if (schema != null) {
      final validator = DocSpecsValidator(schema: schema);
      final errors = validator.validate(specDoc);
      specDoc.validationErrors.addAll(errors.map((e) => e.toString()));
    }

    return specDoc;
  }

  /// Load and validate a single document (sync).
  /// The synchronous twin of [scanDocument]; [schemaFolder] means the same.
  static SpecDoc scanDocumentSync({
    required String filePath,
    String? schemaId,
    String? workspaceRoot,
    String? schemaFolder,
  }) {
    final absolutePath = _toAbsolutePath(filePath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    // Read document to extract schema ID
    final file = File(absolutePath);
    if (!file.existsSync()) {
      throw ArgumentError('Document not found: $absolutePath');
    }

    // Determine schema ID
    final effectiveSchemaId = schemaId ?? _extractSchemaIdSync(absolutePath);

    // Load schema
    DocSpecSchema? schema;
    if (effectiveSchemaId != null) {
      schema = SchemaResolver.resolveSync(
        schemaId: effectiveSchemaId,
        documentPath: absolutePath,
        workspaceRoot: wsRoot,
        schemaFolder: schemaFolder,
      );
    }

    // Create factory with schema
    final factory = DocSpecsFactory(schema: schema);

    // Scan document using DocScanner
    final doc = DocScanner.scanDocumentSync(
      filepath: absolutePath,
      workspaceRoot: wsRoot,
      factory: factory,
    );

    // Cast to SpecDoc and validate
    final specDoc = doc as SpecDoc;

    if (schema != null) {
      final validator = DocSpecsValidator(schema: schema);
      final errors = validator.validate(specDoc);
      specDoc.validationErrors.addAll(errors.map((e) => e.toString()));
    }

    return specDoc;
  }

  /// Load and validate multiple documents (async).
  static Future<List<SpecDoc>> scanDocuments({
    required List<String> filePaths,
    String? workspaceRoot,
  }) async {
    final results = <SpecDoc>[];
    for (final filePath in filePaths) {
      results.add(
        await scanDocument(filePath: filePath, workspaceRoot: workspaceRoot),
      );
    }
    return results;
  }

  /// Load and validate multiple documents (sync).
  static List<SpecDoc> scanDocumentsSync({
    required List<String> filePaths,
    String? workspaceRoot,
  }) {
    final results = <SpecDoc>[];
    for (final filePath in filePaths) {
      results.add(
        scanDocumentSync(filePath: filePath, workspaceRoot: workspaceRoot),
      );
    }
    return results;
  }

  /// Scan a directory tree (async).
  ///
  /// Returns a [DocumentFolder] with [SpecDoc] instances.
  /// Each document found is re-scanned with a [DocSpecsFactory] so
  /// sections are created as [SpecSection] with type resolution.
  static Future<DocumentFolder> scanTree({
    required String dirPath,
    String? workspaceRoot,
  }) async {
    final absolutePath = _toAbsolutePath(dirPath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    // First scan tree to discover documents
    final folder = await DocScanner.scanTree(
      path: absolutePath,
      workspaceRoot: wsRoot,
    );

    // Re-scan each document with our factory
    await _rescanFolderDocuments(folder, wsRoot);

    return folder;
  }

  /// Scan a directory tree (sync).
  static DocumentFolder scanTreeSync({
    required String dirPath,
    String? workspaceRoot,
  }) {
    final absolutePath = _toAbsolutePath(dirPath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    final folder = DocScanner.scanTreeSync(
      path: absolutePath,
      workspaceRoot: wsRoot,
    );

    _rescanFolderDocumentsSync(folder, wsRoot);

    return folder;
  }

  /// Re-scans all documents in a folder tree with DocSpecsFactory.
  static Future<void> _rescanFolderDocuments(
    DocumentFolder folder,
    String wsRoot,
  ) async {
    for (var i = 0; i < folder.documents.length; i++) {
      final doc = folder.documents[i];
      try {
        final specDoc = await scanDocument(
          filePath: doc.fullPath,
          workspaceRoot: wsRoot,
        );
        folder.documents[i] = specDoc;
      } catch (_) {
        // Keep original document on error
      }
    }

    for (final subFolder in folder.folders) {
      await _rescanFolderDocuments(subFolder, wsRoot);
    }
  }

  /// Re-scans all documents in a folder tree synchronously.
  static void _rescanFolderDocumentsSync(DocumentFolder folder, String wsRoot) {
    for (var i = 0; i < folder.documents.length; i++) {
      final doc = folder.documents[i];
      try {
        final specDoc = scanDocumentSync(
          filePath: doc.fullPath,
          workspaceRoot: wsRoot,
        );
        folder.documents[i] = specDoc;
      } catch (_) {
        // Keep original document on error
      }
    }

    for (final subFolder in folder.folders) {
      _rescanFolderDocumentsSync(subFolder, wsRoot);
    }
  }

  /// Load a schema definition by ID.
  ///
  /// The [schemaId] can be:
  /// - Full ID with version: `quest-overview-1.0`
  /// - ID with version separator: `quest-overview/1.0`
  static Future<DocSpecSchema> loadSchema({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final schema = await SchemaResolver.resolve(
      schemaId: schemaId,
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );

    if (schema == null) {
      throw ArgumentError('Schema not found: $schemaId');
    }

    return schema;
  }

  /// Load a schema definition synchronously.
  static DocSpecSchema loadSchemaSync({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) {
    final schema = SchemaResolver.resolveSync(
      schemaId: schemaId,
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );

    if (schema == null) {
      throw ArgumentError('Schema not found: $schemaId');
    }

    return schema;
  }

  /// Validate a document against its declared schema.
  ///
  /// Returns a list of validation error messages.
  static List<String> validate(SpecDoc doc, {DocSpecSchema? schema}) {
    if (schema == null) {
      return ['No schema provided for validation'];
    }

    final validator = DocSpecsValidator(schema: schema);
    final errors = validator.validate(doc);
    return errors.map((e) => e.toString()).toList();
  }

  /// Validate a document asynchronously, including AI validation.
  ///
  /// If [aiValidator] is provided, sections with `validationPrompt` in their
  /// type definition will be validated using the AI. Otherwise, this is
  /// identical to [validate].
  static Future<List<String>> validateAsync(
    SpecDoc doc, {
    DocSpecSchema? schema,
    AiValidator? aiValidator,
  }) async {
    if (schema == null) {
      return ['No schema provided for validation'];
    }

    final validator = DocSpecsValidator(
      schema: schema,
      aiValidator: aiValidator,
    );
    final errors = await validator.validateAsync(doc);
    return errors.map((e) => e.toString()).toList();
  }

  /// List all available schemas from all locations.
  static Future<List<SchemaInfo>> listSchemas({
    String? documentPath,
    String? workspaceRoot,
  }) {
    return SchemaDiscovery.listSchemas(
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );
  }

  /// List schemas synchronously.
  static List<SchemaInfo> listSchemasSync({
    String? documentPath,
    String? workspaceRoot,
  }) {
    return SchemaDiscovery.listSchemasSync(
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );
  }

  /// List schemas from a specific location only.
  static Future<List<SchemaInfo>> listSchemasIn({required String dirPath}) {
    return SchemaDiscovery.listSchemasIn(dirPath);
  }

  /// List schemas from a specific location synchronously.
  static List<SchemaInfo> listSchemasInSync({required String dirPath}) {
    return SchemaDiscovery.listSchemasInSync(dirPath);
  }

  /// Converts a path to absolute if relative.
  static String _toAbsolutePath(String filePath) {
    if (path.isAbsolute(filePath)) return filePath;
    return path.join(Directory.current.path, filePath);
  }

  /// Extracts schema ID from document's first headline (async).
  static Future<String?> _extractSchemaId(String filePath) async {
    final file = File(filePath);
    final lines = await file.readAsLines();
    return _parseSchemaIdFromLines(lines);
  }

  /// Extracts schema ID from document's first headline (sync).
  static String? _extractSchemaIdSync(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    return _parseSchemaIdFromLines(lines);
  }

  /// The standalone comment form: `<!-- docspec: <id>/<version> -->`.
  ///
  /// What `DocSpecsSkeletonGenerator` emits, what `CLAUDE.md` documents as the
  /// workspace convention, and what every document in `test/fixtures/documents`
  /// is written with.
  static final RegExp _docspecComment = RegExp(
    r'<!--\s*docspec:\s*([^\s>]+)\s*-->',
  );

  /// The in-headline form: `# <!-- schema=<id> --> Title`.
  ///
  /// What `doc_specs_specification.md` documents and what this parser read
  /// before it read anything else.
  static final RegExp _schemaField = RegExp(r'schema\s*=\s*([^\s>]+)');

  /// Parses a document's schema declaration out of its preamble.
  ///
  /// **Both declaration forms are accepted**, because both are documented and
  /// both are written. Reading only the in-headline one made a generated
  /// skeleton — and every fixture document in this package — scan as
  /// schemaless, and a schemaless scan reports no errors, which reads exactly
  /// like a pass.
  ///
  /// **Where it looks: the preamble, meaning everything up to the second
  /// headline.** The declaration belongs to the *document*, so it sits before
  /// the first content section — in practice immediately above or below the
  /// title, and both placements occur in this package's own fixtures. Bounding
  /// the search there is what keeps a `<!-- docspec: … -->` quoted inside some
  /// section's body from being mistaken for the document's own declaration, and
  /// it means the cost does not grow with the file.
  ///
  /// **Precedence is document order**: whichever form appears first wins. A
  /// document carrying both and meaning two different schemas is malformed, and
  /// a positional rule needs no table to explain it.
  ///
  /// Returns `null` when the preamble declares nothing.
  static String? _parseSchemaIdFromLines(List<String> lines) {
    var headlines = 0;
    for (final line in lines) {
      if (line.startsWith('#')) {
        headlines++;
        if (headlines > 1) return null;
        final inHeadline = _schemaField.firstMatch(line);
        if (inHeadline != null) return inHeadline.group(1);
        continue;
      }
      final comment = _docspecComment.firstMatch(line);
      if (comment != null) return comment.group(1);
    }
    return null;
  }
}
