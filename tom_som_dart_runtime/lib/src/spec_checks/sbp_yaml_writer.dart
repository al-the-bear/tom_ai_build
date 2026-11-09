// Rewrites individual `key: |2-` block scalars of a YAML text in place.
//
// Only the body lines of the rewritten scalars change; the key line, the
// `|2-` header, the indentation and every other byte of the file stay as
// they are. A value whose text does not have the exact shape the v2 encoder
// writes (`<indent><key>: |2-`, then each value line indented by the key's
// column plus two, empty lines empty) is not touched: the rewrite fails
// instead of guessing.
import 'sbp_yaml_locator.dart';

/// A located value and the text it is to hold.
class ValueEdit {
  /// Replaces the value at [location] with [newValue].
  const ValueEdit(this.location, this.newValue);

  /// Where the value sits.
  final ValueLocation location;

  /// The value to write.
  final String newValue;
}

/// Thrown when a value cannot be rewritten in place.
class YamlRewriteException implements Exception {
  /// Reports why the value at [path] cannot be rewritten.
  YamlRewriteException(this.path, this.message);

  /// The document path of the value.
  final String path;

  /// What is wrong.
  final String message;

  @override
  String toString() => 'cannot rewrite `$path` in place: $message';
}

/// [yamlText] with every edit's block scalar body replaced.
///
/// Throws [YamlRewriteException] when a value is not a `|2-` block scalar
/// written in the encoder's shape.
String rewriteValues(String yamlText, List<ValueEdit> edits) {
  final lines = yamlText.split('\n');
  final ordered = [...edits]
    ..sort((a, b) => b.location.keyLine.compareTo(a.location.keyLine));
  for (final edit in ordered) {
    final loc = edit.location;
    _checkShape(lines, loc);
    final oldBody = blockBody(loc.value, loc.keyColumn);
    lines.replaceRange(
      loc.keyLine + 1,
      loc.keyLine + 1 + oldBody.length,
      blockBody(edit.newValue, loc.keyColumn),
    );
  }
  return lines.join('\n');
}

/// The body lines of a `|2-` block scalar holding [value] under a key at
/// [keyColumn].
List<String> blockBody(String value, int keyColumn) {
  if (value.isEmpty) return const [];
  final indent = ' ' * (keyColumn + 2);
  return [
    for (final line in value.split('\n')) line.isEmpty ? '' : '$indent$line',
  ];
}

void _checkShape(List<String> lines, ValueLocation loc) {
  final header = lines[loc.keyLine];
  if (!header.endsWith(': |2-') ||
      header.substring(0, loc.keyColumn).trim().isNotEmpty) {
    throw YamlRewriteException(
      loc.path,
      'line ${loc.keyLine + 1} is not a `key: |2-` block scalar header',
    );
  }
  final body = blockBody(loc.value, loc.keyColumn);
  for (var i = 0; i < body.length; i++) {
    final lineIndex = loc.keyLine + 1 + i;
    if (lineIndex >= lines.length || lines[lineIndex] != body[i]) {
      throw YamlRewriteException(
        loc.path,
        'line ${lineIndex + 1} differs from the encoder\'s shape of the value',
      );
    }
  }
}
