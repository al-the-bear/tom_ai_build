// Reading the Blueprint's YAML as a plain tree, for the checks that look at
// ids and text rather than at the decoded model.
//
// Keys are `<ID> <fieldName>` for sections and bare ids for list items;
// [child] finds a key by its id alone, as the checks name sections by id.
//
// Text is read as it stands once reviewed: [field] and [textOf] accept every
// inline review mark and drop comment and question blocks (the runtime's
// `stripAnnotationsText`, SOM §11.9), so a name a round struck out with
// `{--…--}` or `{~~old~>new~~}` no longer counts.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show stripAnnotationsText;
import 'package:yaml/yaml.dart';

/// The document root's single entry, `SBP D00SolutionBlueprint`.
YamlMap sbpRoot(String yamlText) {
  final doc = (loadYaml(yamlText) as YamlMap)['document'] as YamlMap;
  return doc.values.first as YamlMap;
}

/// The child of [node] whose key is [id] or starts with `[id] `, or `null`.
Object? child(Object? node, String id) {
  if (node is! YamlMap) return null;
  for (final entry in node.entries) {
    final key = '${entry.key}';
    if (key == id || key.split(' ').first == id) return entry.value;
  }
  return null;
}

/// [child] along [path].
Object? at(Object? node, List<String> path) {
  var current = node;
  for (final id in path) {
    current = child(current, id);
    if (current == null) return null;
  }
  return current;
}

/// The entries of a list section (or any mapping), keyed by their key.
Map<String, Object?> entriesOf(Object? node) => node is YamlMap
    ? {for (final e in node.entries) '${e.key}': e.value}
    : const <String, Object?>{};

/// A scalar as trimmed text; a mapping's values joined by blank lines, the way
/// a section's prose and its sub-sections read; `''` for null.
String textOf(Object? node) {
  if (node == null) return '';
  if (node is YamlMap) {
    return node.values.map(textOf).join('\n\n');
  }
  return reviewed('$node');
}

/// [text] with every inline review mark accepted and every comment and
/// question block removed; text without annotations is returned unchanged.
String reviewed(String text) =>
    _annotated.hasMatch(text) ? stripAnnotationsText(text) : text;

final _annotated = RegExp(r'\{(\+\+|--|~~|==|>>)|^\s*>', multiLine: true);

/// A field of a mapping as trimmed text.
String field(Object? node, String name) => node is YamlMap && node[name] != null
    ? reviewed('${node[name]}').trim()
    : '';
