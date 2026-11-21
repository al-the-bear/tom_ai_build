import 'models/document.dart';
import 'models/section.dart';

/// Factory for creating [Document] and [Section] objects.
///
/// This factory encapsulates the creation of DocScanner model objects,
/// allowing users to customize object creation when using DocScanner
/// via package import.
///
/// ## Example
///
/// ```dart
/// class MyDocScannerFactory extends DocScannerFactory {
///   const MyDocScannerFactory();
///
///   @override
///   Section createSection({
///     required int index,
///     required int lineNumber,
///     required String rawHeadline,
///     required String name,
///     required String id,
///     required String text,
///     required Map<String, String> fields,
///     List<Section>? sections,
///     int? textLineNumber,
///   }) {
///     // Custom section creation logic
///     return super.createSection(
///       index: index,
///       lineNumber: lineNumber,
///       rawHeadline: rawHeadline,
///       name: name,
///       id: id,
///       text: text,
///       fields: fields,
///       sections: sections,
///       textLineNumber: textLineNumber,
///     );
///   }
/// }
///
/// final doc = DocScanner.scanDocumentSync(
///   filepath: 'guide.md',
///   factory: const MyDocScannerFactory(),
/// );
/// ```
class DocScannerFactory {
  /// Creates a new [DocScannerFactory].
  const DocScannerFactory();

  /// Creates a [Section] with the given parameters.
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
    return Section(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections,
      textLineNumber: textLineNumber,
    );
  }

  /// Creates a [Document] with the given parameters.
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
    return Document(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections,
      textLineNumber: textLineNumber,
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
    );
  }
}
