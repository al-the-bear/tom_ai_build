// Locates the text of every content value of a hierarchical v2
// `*.docspecs.yaml` file, so that a value can be rewritten in place without
// re-serialising the document.
//
// The locator walks the YAML node tree (package:yaml, which keeps source
// spans) exactly the way `SpecDocumentYaml.decode` walks it — the same key
// matching against the metadata tree, the same `content` / `headline` /
// `codeSpec` literal keys, the same list-item path generation — and records,
// for every value the decoder would store with `setContent`, where its
// `key: |2-` block scalar sits in the text.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:yaml/yaml.dart';

/// What a located content value is, as far as answer import cares.
enum ValueRole {
  /// A `content` member, a section's own body text (`content:` key of a
  /// section) or a form's preamble (`content:` key of a form) — free
  /// narrative text where question blocks live.
  narrative,

  /// A scalar or enum leaf, or a scalar list item — not narrative.
  scalar,
}

/// Where one content value sits in the YAML text.
class ValueLocation {
  /// Records the value stored at document [path] under the key on line
  /// [keyLine].
  const ValueLocation({
    required this.path,
    required this.idPath,
    required this.role,
    required this.keyLine,
    required this.keyColumn,
    required this.value,
  });

  /// The document path (the key of `SpecDocument.toJson()['content']`).
  final String path;

  /// The section-id path: the id of every YAML key from the root down, the
  /// member name where a key carries no id (`SBP > INSC > ... > content`).
  final String idPath;

  /// Whether the value is narrative text.
  final ValueRole role;

  /// 0-based line of the value's key.
  final int keyLine;

  /// 0-based column of the value's key (its mapping's indentation).
  final int keyColumn;

  /// The decoded value.
  final String value;
}

/// Walks a v2 document's YAML text and returns every content value's
/// location, keyed by document path.
///
/// Throws [SpecYamlFormatException] when a key fits no member — the same
/// condition on which the decoder fails.
Map<String, ValueLocation> locateValues(String yamlText, SomMetaTree tree) {
  final root = loadYamlNode(yamlText);
  final docPass = _mapping(root, 'the file')['document'];
  final walker = _Walker(tree);
  final body = _mapping(docPass, '`document:`');
  final rootEntry = body.nodes.entries.single;
  final rootKey = rootEntry.key as YamlNode;
  walker.walkMapping(
    tree.root,
    tree.root.segment,
    _idOf(rootKey.value),
    rootEntry.value,
  );
  return walker.locations;
}

YamlMap _mapping(Object? node, String where) {
  final value = node is YamlNode ? node : null;
  if (value is YamlMap) return value;
  throw SpecYamlFormatException('$where must be a mapping');
}

/// The id part of a YAML key: `INSC introductionAndScope` → `INSC`; a key
/// without a space is its own id (list items, member names).
String _idOf(Object? key) {
  final text = '$key';
  final space = text.indexOf(' ');
  return space < 0 ? text : text.substring(0, space);
}

class _Walker {
  _Walker(this.tree);

  final SomMetaTree tree;

  /// Generates list-item paths in the decoder's order.
  final SpecDocument _scratch = SpecDocument();

  final Map<String, ValueLocation> locations = {};

  void walkMapping(
    SomMetaNode node,
    String path,
    String idPath,
    YamlNode body,
  ) {
    if (body is! YamlMap) return;
    for (final entry in body.nodes.entries) {
      final key = entry.key as YamlNode;
      final name = '${key.value}';
      final child = _childByKey(node, name);
      final childIds = '$idPath > ${_idOf(name)}';
      if (child != null) {
        _walkChild(child, specPathJoin(path, child.segment), childIds, entry);
      } else if (name == 'content') {
        _record(path, childIds, ValueRole.narrative, key, entry.value);
      }
    }
  }

  SomMetaNode? _childByKey(SomMetaNode node, String key) {
    for (final c in node.children) {
      if (SpecDocumentYaml.nodeKey(c) == key) return c;
    }
    return null;
  }

  void _walkChild(
    SomMetaNode child,
    String path,
    String idPath,
    MapEntry<dynamic, YamlNode> entry,
  ) {
    final key = entry.key as YamlNode;
    switch (child.kind) {
      case SomMetaKind.content:
        _scalarNode(path, idPath, ValueRole.narrative, key, entry.value);
      case SomMetaKind.scalar:
      case SomMetaKind.enumValue:
        _scalarNode(path, idPath, ValueRole.scalar, key, entry.value);
      case SomMetaKind.form:
        _walkForm(path, idPath, entry.value);
      case SomMetaKind.section:
      case SomMetaKind.complex:
        walkMapping(child, path, idPath, entry.value);
      case SomMetaKind.list:
        _walkList(child, path, idPath, entry.value);
    }
  }

  /// A leaf: a direct scalar, or a `{headline, codeSpec, content}` mapping.
  void _scalarNode(
    String path,
    String idPath,
    ValueRole role,
    YamlNode key,
    YamlNode value,
  ) {
    if (value is! YamlMap) {
      _record(path, idPath, role, key, value);
      return;
    }
    final inner = _contentEntry(value);
    if (inner != null) {
      _record(
        path,
        '$idPath > content',
        role,
        inner.key as YamlNode,
        inner.value,
      );
    }
  }

  void _walkForm(String path, String idPath, YamlNode value) {
    if (value is! YamlMap) return;
    final preamble = _contentEntry(value);
    if (preamble != null) {
      _record(
        path,
        '$idPath > content',
        ValueRole.narrative,
        preamble.key as YamlNode,
        preamble.value,
      );
    }
  }

  MapEntry<dynamic, YamlNode>? _contentEntry(YamlMap map) {
    for (final e in map.nodes.entries) {
      if ('${(e.key as YamlNode).value}' == 'content') return e;
    }
    return null;
  }

  void _walkList(SomMetaNode node, String path, String idPath, YamlNode items) {
    if (items is! YamlMap) return;
    final anonymous = RegExp(
      '^${RegExp.escape(node.memberName ?? '')}-[0-9]+\$',
    );
    for (final entry in items.nodes.entries) {
      final key = entry.key as YamlNode;
      final name = '${key.value}';
      if (name == 'headline' || name == 'codeSpec') continue;
      final itemPath = _scratch.addListItem(
        path,
        sectionId: anonymous.hasMatch(name) ? null : name,
      );
      final itemIds = '$idPath > $name';
      final element = node.elementNode;
      if (element == null) {
        _scalarNode(itemPath, itemIds, ValueRole.scalar, key, entry.value);
      } else {
        walkMapping(element, itemPath, itemIds, entry.value);
      }
    }
  }

  void _record(
    String path,
    String idPath,
    ValueRole role,
    YamlNode key,
    YamlNode value,
  ) {
    locations[path] = ValueLocation(
      path: path,
      idPath: idPath,
      role: role,
      keyLine: key.span.start.line,
      keyColumn: key.span.start.column,
      value: value.value == null ? '' : '${value.value}',
    );
  }
}
