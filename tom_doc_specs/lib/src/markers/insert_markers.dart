/// Parses and processes `<!--$insert:{variable}-->` markers in markdown.
///
/// Insert markers define regions of content that can be programmatically
/// replaced. Each region is delimited by a start marker with a variable name
/// and an end marker.
///
/// ## Syntax
///
/// ```markdown
/// <!--$insert:chat.lastReply-->
/// ... replaceable content ...
/// <!--$end-insert-->
/// ```
///
/// See the specification for full syntax and validation rules.
library;

/// A parsed insert marker region.
class InsertMarker {
  /// The variable name (e.g., `chat.lastReply`, `meta.timestamp`).
  final String variable;

  /// The line number of the start marker (1-based).
  final int startLine;

  /// The line number of the end marker (1-based).
  final int endLine;

  /// The current content between the markers (excluding marker lines).
  final String content;

  const InsertMarker({
    required this.variable,
    required this.startLine,
    required this.endLine,
    required this.content,
  });

  @override
  String toString() =>
      'InsertMarker(variable: $variable, lines: $startLine-$endLine)';
}

/// Parses `<!--$insert:...-->` markers from markdown text.
class InsertMarkerParser {
  /// Start marker regex: `<!--$insert:{variable}-->`
  static final _startPattern =
      RegExp(r'^<!--\$insert:([a-zA-Z][a-zA-Z0-9_.]+)-->$');

  /// End marker regex: `<!--$end-insert-->`
  static final _endPattern = RegExp(r'^<!--\$end-insert-->$');

  /// Parses all insert marker regions from the given [text].
  ///
  /// Returns a list of [InsertMarker] instances in document order.
  /// Throws [FormatException] for malformed markers (unclosed, nested).
  List<InsertMarker> parse(String text) {
    final lines = text.split('\n');
    final markers = <InsertMarker>[];

    String? currentVariable;
    int? startLine;
    final contentLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineNumber = i + 1; // 1-based

      final startMatch = _startPattern.firstMatch(line);
      if (startMatch != null) {
        if (currentVariable != null) {
          throw FormatException(
            'Nested insert markers are not supported. '
            'Found <!--\$insert:${startMatch.group(1)}--> at line $lineNumber '
            'while <!--\$insert:$currentVariable--> (line $startLine) is still open.',
          );
        }
        currentVariable = startMatch.group(1)!;
        startLine = lineNumber;
        contentLines.clear();
        continue;
      }

      if (_endPattern.hasMatch(line)) {
        if (currentVariable == null) {
          throw FormatException(
            'Found <!--\$end-insert--> at line $lineNumber without a matching start marker.',
          );
        }
        markers.add(InsertMarker(
          variable: currentVariable,
          startLine: startLine!,
          endLine: lineNumber,
          content: contentLines.join('\n'),
        ));
        currentVariable = null;
        startLine = null;
        contentLines.clear();
        continue;
      }

      if (currentVariable != null) {
        contentLines.add(lines[i]);
      }
    }

    if (currentVariable != null) {
      throw FormatException(
        'Unclosed insert marker <!--\$insert:$currentVariable--> at line $startLine.',
      );
    }

    return markers;
  }
}

/// Replaces content within insert marker regions.
class InsertMarkerProcessor {
  final InsertMarkerParser _parser = InsertMarkerParser();

  /// Replaces content in all marker regions using the [replacements] map.
  ///
  /// The [replacements] map keys are variable names, values are the new content.
  /// Markers whose variable is not in [replacements] are left unchanged.
  ///
  /// Returns the modified text.
  String process(String text, Map<String, String> replacements) {
    final markers = _parser.parse(text);
    if (markers.isEmpty) return text;

    final lines = text.split('\n');
    final result = <String>[];
    var currentIndex = 0;

    for (final marker in markers) {
      // Add lines before this marker's start (0-based index)
      final startIndex = marker.startLine - 1;
      while (currentIndex < startIndex) {
        result.add(lines[currentIndex]);
        currentIndex++;
      }

      // Add the start marker line
      result.add(lines[currentIndex]);
      currentIndex++;

      // Skip old content lines (between start and end markers)
      final endIndex = marker.endLine - 1;

      // Add replacement content or keep original
      if (replacements.containsKey(marker.variable)) {
        final newContent = replacements[marker.variable]!;
        if (newContent.isNotEmpty) {
          result.add(newContent);
        }
      } else {
        // Keep original content
        while (currentIndex < endIndex) {
          result.add(lines[currentIndex]);
          currentIndex++;
        }
      }

      // Skip to end marker
      currentIndex = endIndex;

      // Add the end marker line
      result.add(lines[currentIndex]);
      currentIndex++;
    }

    // Add remaining lines after last marker
    while (currentIndex < lines.length) {
      result.add(lines[currentIndex]);
      currentIndex++;
    }

    return result.join('\n');
  }

  /// Parses markers from [text] without modifying it.
  ///
  /// Convenience method for inspecting marker regions.
  List<InsertMarker> parse(String text) => _parser.parse(text);
}
