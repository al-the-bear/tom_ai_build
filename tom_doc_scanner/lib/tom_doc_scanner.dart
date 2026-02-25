/// Tom Doc Scanner - Parses markdown files into structured document trees.
///
/// Provides tools to scan markdown documents and convert their headline
/// structure into a traversable tree of sections.
///
/// ## Usage
///
/// ```dart
/// import 'package:tom_doc_scanner/tom_doc_scanner.dart';
///
/// final doc = await DocScanner.scanDocument(filepath: 'README.md');
/// print(doc.name);
/// ```
library;

export 'src/doc_scanner.dart' show DocScanner;
export 'src/doc_scanner_factory.dart' show DocScannerFactory;
export 'src/markdown_parser.dart' show ParsedHeadline, MarkdownParser;
export 'src/models/document.dart' show Document;
export 'src/models/document_folder.dart' show DocumentFolder;
export 'src/models/section.dart' show Section;
