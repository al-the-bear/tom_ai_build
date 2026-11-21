import 'dart:io';

import 'package:path/path.dart' as path;

import 'doc_scanner_factory.dart';
import 'markdown_parser.dart';
import 'models/document.dart';
import 'models/document_folder.dart';
import 'models/section.dart';

/// Default factory instance used when no custom factory is provided.
const _defaultFactory = DocScannerFactory();

/// DocScanner - Parses markdown files into structured data.
///
/// Provides static methods to scan individual documents, multiple documents,
/// or entire directory trees, converting markdown headline structure into
/// a traversable tree of sections.
///
/// ## Example
///
/// ```dart
/// // Scan a single document
/// final doc = await DocScanner.scanDocument(filepath: 'README.md');
///
/// // Scan multiple documents
/// final docs = await DocScanner.scanDocuments(
///   filepaths: ['doc1.md', 'doc2.md'],
/// );
///
/// // Scan a directory tree
/// final folder = await DocScanner.scanTree(path: 'docs/');
///
/// // Using a custom factory
/// final customDoc = await DocScanner.scanDocument(
///   filepath: 'README.md',
///   factory: MyCustomFactory(),
/// );
/// ```
class DocScanner {
  /// Scans a directory tree and returns a [DocumentFolder] structure.
  ///
  /// The [path] should be an absolute or relative path to a directory.
  /// The optional [workspaceRoot] specifies the workspace root for
  /// calculating relative paths. If not provided, it defaults to the
  /// current working directory.
  /// The optional [factory] allows customizing Document/Section creation.
  static Future<DocumentFolder> scanTree({
    required String path,
    String? workspaceRoot,
    DocScannerFactory? factory,
  }) async {
    final absolutePath = _toAbsolutePath(path);
    final wsRoot = workspaceRoot ?? Directory.current.path;
    final dir = Directory(absolutePath);
    final f = factory ?? _defaultFactory;

    if (!await dir.exists()) {
      throw ArgumentError('Directory does not exist: $absolutePath');
    }

    return _scanFolder(dir, wsRoot, f);
  }

  /// Synchronously scans a directory tree and returns a [DocumentFolder].
  ///
  /// The [path] should be an absolute or relative path to a directory.
  /// The optional [workspaceRoot] specifies the workspace root for
  /// calculating relative paths. If not provided, it defaults to the
  /// current working directory.
  /// The optional [factory] allows customizing Document/Section creation.
  static DocumentFolder scanTreeSync({
    required String path,
    String? workspaceRoot,
    DocScannerFactory? factory,
  }) {
    final absolutePath = _toAbsolutePath(path);
    final wsRoot = workspaceRoot ?? Directory.current.path;
    final dir = Directory(absolutePath);
    final f = factory ?? _defaultFactory;

    if (!dir.existsSync()) {
      throw ArgumentError('Directory does not exist: $absolutePath');
    }

    return _scanFolderSync(dir, wsRoot, f);
  }

  /// Scans multiple markdown files and returns a list of [Document]s.
  ///
  /// The [filepaths] should be paths to markdown files.
  /// The optional [workspaceRoot] specifies the workspace root for
  /// calculating relative paths.
  /// The optional [factory] allows customizing Document/Section creation.
  static Future<List<Document>> scanDocuments({
    required List<String> filepaths,
    String? workspaceRoot,
    DocScannerFactory? factory,
  }) async {
    final wsRoot = workspaceRoot ?? Directory.current.path;
    final f = factory ?? _defaultFactory;
    final documents = <Document>[];

    for (final filepath in filepaths) {
      final doc = await scanDocument(
        filepath: filepath,
        workspaceRoot: wsRoot,
        factory: f,
      );
      documents.add(doc);
    }

    return documents;
  }

  /// Synchronously scans multiple markdown files and returns a list of [Document]s.
  ///
  /// The [filepaths] should be paths to markdown files.
  /// The optional [workspaceRoot] specifies the workspace root for
  /// calculating relative paths.
  /// The optional [factory] allows customizing Document/Section creation.
  static List<Document> scanDocumentsSync({
    required List<String> filepaths,
    String? workspaceRoot,
    DocScannerFactory? factory,
  }) {
    final wsRoot = workspaceRoot ?? Directory.current.path;
    final f = factory ?? _defaultFactory;
    final documents = <Document>[];

    for (final filepath in filepaths) {
      final doc = scanDocumentSync(
        filepath: filepath,
        workspaceRoot: wsRoot,
        factory: f,
      );
      documents.add(doc);
    }

    return documents;
  }

  /// Scans a single markdown file and returns a [Document].
  ///
  /// The [filepath] should be a path to a markdown file.
  /// The optional [workspaceRoot] specifies the workspace root for
  /// calculating relative paths.
  /// The optional [factory] allows customizing Document/Section creation.
  static Future<Document> scanDocument({
    required String filepath,
    String? workspaceRoot,
    DocScannerFactory? factory,
  }) async {
    final absolutePath = _toAbsolutePath(filepath);
    final wsRoot = workspaceRoot ?? Directory.current.path;
    final f = factory ?? _defaultFactory;
    final file = File(absolutePath);

    if (!await file.exists()) {
      throw ArgumentError('File does not exist: $absolutePath');
    }

    final content = await file.readAsString();
    return _buildDocument(absolutePath, content, wsRoot, f);
  }

  /// Synchronously scans a single markdown file and returns a [Document].
  ///
  /// The [filepath] should be a path to a markdown file.
  /// The optional [workspaceRoot] specifies the workspace root for
  /// calculating relative paths.
  /// The optional [factory] allows customizing Document/Section creation.
  static Document scanDocumentSync({
    required String filepath,
    String? workspaceRoot,
    DocScannerFactory? factory,
  }) {
    final absolutePath = _toAbsolutePath(filepath);
    final wsRoot = workspaceRoot ?? Directory.current.path;
    final f = factory ?? _defaultFactory;
    final file = File(absolutePath);

    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $absolutePath');
    }

    final content = file.readAsStringSync();
    return _buildDocument(absolutePath, content, wsRoot, f);
  }

  /// Builds a Document from file content (shared by sync and async methods).
  static Document _buildDocument(
    String absolutePath,
    String content,
    String wsRoot,
    DocScannerFactory f,
  ) {
    final filename = path.basename(absolutePath);
    final fullPath = path.dirname(absolutePath);

    // Calculate workspace-relative paths
    final workspacePath = _relativePath(absolutePath, wsRoot);
    final (project, projectPath, projectRoot) = _extractProjectInfo(
      absolutePath,
      wsRoot,
    );

    // Parse the document
    final headlines = MarkdownParser.parseHeadlines(content);
    final hierarchyDepth = MarkdownParser.calculateMaxDepth(headlines);

    // Build section tree
    final sections = _buildSectionTree(content, headlines, filename, f);

    // Create document (the root section)
    final docName = _extractDocumentName(headlines, filename);
    final docId = _extractDocumentId(headlines, filename);
    final (docText, docTextLine) = _extractDocumentText(content, headlines);
    final docLineNumber = headlines.isNotEmpty
        ? headlines.first.$1.lineNumber
        : 1;
    final docRawHeadline = _extractDocumentRawHeadline(headlines, filename);
    final docFields = _extractDocumentFields(headlines);

    return f.createDocument(
      index: 0,
      lineNumber: docLineNumber,
      rawHeadline: docRawHeadline,
      name: docName,
      id: docId,
      text: docText,
      fields: docFields,
      sections: sections.isNotEmpty ? sections : null,
      textLineNumber: docTextLine,
      filenameWithPath: absolutePath,
      loadTimestamp: DateTime.now().toIso8601String(),
      filename: filename,
      fullPath: fullPath,
      workspacePath: workspacePath,
      project: project,
      projectPath: projectPath,
      workspaceRoot: wsRoot,
      projectRoot: projectRoot,
      hierarchyDepth: hierarchyDepth,
    );
  }

  /// Recursively scans a folder and its subfolders.
  static Future<DocumentFolder> _scanFolder(
    Directory dir,
    String workspaceRoot,
    DocScannerFactory factory,
  ) async {
    final documents = <Document>[];
    final folders = <DocumentFolder>[];

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final doc = await scanDocument(
            filepath: entity.path,
            workspaceRoot: workspaceRoot,
            factory: factory,
          );
          documents.add(doc);
        } catch (e) {
          // Skip files that can't be parsed
          continue;
        }
      } else if (entity is Directory) {
        final subfolder = await _scanFolder(entity, workspaceRoot, factory);
        folders.add(subfolder);
      }
    }

    // Sort documents by filename
    documents.sort((a, b) => a.filename.compareTo(b.filename));
    // Sort folders by name
    folders.sort((a, b) => a.foldername.compareTo(b.foldername));

    return DocumentFolder(
      foldername: path.basename(dir.path),
      workspaceFolderPath: _relativePath(dir.path, workspaceRoot),
      absoluteFolderPath: dir.path,
      documents: documents,
      folders: folders,
    );
  }

  /// Synchronously scans a folder and its subfolders.
  static DocumentFolder _scanFolderSync(
    Directory dir,
    String workspaceRoot,
    DocScannerFactory factory,
  ) {
    final documents = <Document>[];
    final folders = <DocumentFolder>[];

    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final doc = scanDocumentSync(
            filepath: entity.path,
            workspaceRoot: workspaceRoot,
            factory: factory,
          );
          documents.add(doc);
        } catch (e) {
          // Skip files that can't be parsed
          continue;
        }
      } else if (entity is Directory) {
        final subfolder = _scanFolderSync(entity, workspaceRoot, factory);
        folders.add(subfolder);
      }
    }

    // Sort documents by filename
    documents.sort((a, b) => a.filename.compareTo(b.filename));
    // Sort folders by name
    folders.sort((a, b) => a.foldername.compareTo(b.foldername));

    return DocumentFolder(
      foldername: path.basename(dir.path),
      workspaceFolderPath: _relativePath(dir.path, workspaceRoot),
      absoluteFolderPath: dir.path,
      documents: documents,
      folders: folders,
    );
  }

  /// Builds a tree of sections from parsed headlines.
  ///
  /// If the document starts with a level 1 headline, that becomes the Document
  /// and the headlines after it are its sections. Otherwise, all top-level
  /// headlines become sections.
  static List<Section> _buildSectionTree(
    String content,
    List<(ParsedHeadline, int, int)> headlines,
    String filename,
    DocScannerFactory factory,
  ) {
    if (headlines.isEmpty) return [];

    // Check if document has a level 1 headline at the start
    final hasDocHeadline = headlines.first.$1.level == 1;
    if (!hasDocHeadline) {
      return _buildSections(
        content,
        headlines,
        0,
        headlines.length,
        null,
        factory,
      );
    }

    // Skip the first headline (it's the document title)
    final docId =
        headlines.first.$1.explicitId ??
        MarkdownParser.generateId(headlines.first.$1.text, null, 0);
    return _buildSections(
      content,
      headlines,
      1,
      headlines.length,
      docId,
      factory,
    );
  }

  /// Builds the sections of the headlines `[start, end)`, all of which lie
  /// below one parent ([parentId]).
  ///
  /// A headline's subsections are the headlines after it up to the next one
  /// of its own level or shallower, so a headline's parent is the nearest
  /// shallower headline before it — a skipped level (a `####` straight under
  /// a `##`, a styled `heading7` div under a `##`) nests where it stands
  /// instead of being lost. A section's text is its own body: the lines up to
  /// the next headline of any level.
  static List<Section> _buildSections(
    String content,
    List<(ParsedHeadline, int, int)> headlines,
    int start,
    int end,
    String? parentId,
    DocScannerFactory factory,
  ) {
    final sections = <Section>[];
    var sectionIndex = 0;
    var i = start;

    while (i < end) {
      final (headline, startLine, endLine) = headlines[i];
      var next = i + 1;
      while (next < end && headlines[next].$1.level > headline.level) {
        next++;
      }
      final id =
          headline.explicitId ??
          MarkdownParser.generateId(headline.text, parentId, sectionIndex);
      final subsections = _buildSections(
        content,
        headlines,
        i + 1,
        next,
        id,
        factory,
      );

      sections.add(
        factory.createSection(
          index: sectionIndex,
          lineNumber: headline.lineNumber,
          rawHeadline: headline.rawHeadline,
          name: headline.text,
          id: id,
          text: MarkdownParser.extractText(content, startLine, endLine),
          fields: headline.fields,
          sections: subsections.isNotEmpty ? subsections : null,
          textLineNumber: MarkdownParser.textLineNumber(
            content,
            startLine,
            endLine,
          ),
        ),
      );

      sectionIndex++;
      i = next;
    }

    return sections;
  }

  /// Extracts the document name from headlines or filename.
  static String _extractDocumentName(
    List<(ParsedHeadline, int, int)> headlines,
    String filename,
  ) {
    if (headlines.isNotEmpty && headlines.first.$1.level == 1) {
      return headlines.first.$1.text;
    }
    // Use filename without extension
    return path.basenameWithoutExtension(filename);
  }

  /// Extracts the document ID from headlines or filename.
  static String _extractDocumentId(
    List<(ParsedHeadline, int, int)> headlines,
    String filename,
  ) {
    if (headlines.isNotEmpty && headlines.first.$1.level == 1) {
      final headline = headlines.first.$1;
      if (headline.explicitId != null) {
        return headline.explicitId!;
      }
      return MarkdownParser.generateId(headline.text, null, 0);
    }
    // Use filename without extension as ID
    return path.basenameWithoutExtension(filename).toLowerCase();
  }

  /// Extracts the document-level text (before first subsection) and the line
  /// number of its first line.
  static (String, int?) _extractDocumentText(
    String content,
    List<(ParsedHeadline, int, int)> headlines,
  ) {
    (String, int?) between(int startLine, int endLine) => (
      MarkdownParser.extractText(content, startLine, endLine),
      MarkdownParser.textLineNumber(content, startLine, endLine),
    );

    final lastLine = content.split('\n').length - 1;
    if (headlines.isEmpty) return between(-1, lastLine);

    // If first headline is level 1, get text between it and next headline
    if (headlines.first.$1.level == 1) {
      return between(
        headlines.first.$2,
        headlines.length == 1 ? lastLine : headlines[1].$2 - 1,
      );
    }

    // Get text before first headline
    if (headlines.first.$2 > 0) return between(-1, headlines.first.$2 - 1);

    return ('', null);
  }

  /// Extracts the raw headline for the document.
  static String _extractDocumentRawHeadline(
    List<(ParsedHeadline, int, int)> headlines,
    String filename,
  ) {
    if (headlines.isNotEmpty && headlines.first.$1.level == 1) {
      return headlines.first.$1.rawHeadline;
    }
    return path.basenameWithoutExtension(filename);
  }

  /// Extracts the metadata fields for the document.
  static Map<String, String> _extractDocumentFields(
    List<(ParsedHeadline, int, int)> headlines,
  ) {
    if (headlines.isNotEmpty && headlines.first.$1.level == 1) {
      return headlines.first.$1.fields;
    }
    return const {};
  }

  /// Converts a path to an absolute path.
  static String _toAbsolutePath(String p) {
    if (path.isAbsolute(p)) {
      return path.normalize(p);
    }
    return path.normalize(path.join(Directory.current.path, p));
  }

  /// Calculates a relative path from base to target.
  static String _relativePath(String target, String base) {
    return path.relative(target, from: base);
  }

  /// Extracts project information from a file path.
  static (String project, String projectPath, String projectRoot)
  _extractProjectInfo(String filepath, String workspaceRoot) {
    final relativePath = _relativePath(filepath, workspaceRoot);
    final parts = path.split(relativePath);

    if (parts.isEmpty) {
      return ('', relativePath, workspaceRoot);
    }

    final project = parts.first;
    final projectRoot = path.join(workspaceRoot, project);
    final projectPath = parts.length > 1
        ? path.joinAll(parts.sublist(1))
        : path.basename(filepath);

    return (project, projectPath, projectRoot);
  }
}
