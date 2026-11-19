// Fills each functional requirement's version metadata (`FREM`) from the
// document's history: the document revision of the git revision that last
// changed the requirement's section.
//
// Every git revision of a document has its own document revision, so the
// revision list at the start of the document (`RVENT-REVS-LST`) maps the two:
// a version's document revision is the entry it added to the list. A
// requirement's last change is found by comparing its section, by section id,
// across the versions; its own `FREM` is left out of the comparison, so
// filling it is not itself a change. The texts are given oldest first; the
// git walk that produces them is the caller's (`tomspecs :spec-fill-frem`).
import 'dart:convert';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:yaml/yaml.dart';

import 'sbp_yaml_locator.dart';
import 'sbp_yaml_writer.dart';

/// The section id of the version metadata form.
const String fremSectionId = 'FREM';

/// The section id of the revision list.
const String revisionListSectionId = 'RVENT-REVS-LST';

/// The `FREM` fields, in the order they are filled.
const List<String> fremFields = ['version', 'lastModified', 'modifiedBy'];

/// One version of the document: its text at a git revision.
class FremHistoryVersion {
  /// The text of the document at [revision] (a commit, or `working tree`).
  const FremHistoryVersion(this.revision, this.text);

  /// The git revision, or `working tree` for uncommitted changes.
  final String revision;

  /// The document's YAML text at that revision.
  final String text;
}

/// A document revision: one entry of the revision list.
class FremRevision {
  /// The entry [id] with its [version], [date] and [author].
  const FremRevision(this.id, this.version, this.date, this.author);

  /// The entry's section id, e.g. `RVENT-REVS-INITIAL-DRAFT`.
  final String id;

  /// The entry's version.
  final String version;

  /// The entry's date.
  final String date;

  /// The entry's author.
  final String author;
}

/// What the fill writes into one requirement's `FREM`.
class FremFill {
  /// The fill of the requirement [itemSectionId] at document [path].
  const FremFill({
    required this.itemSectionId,
    required this.fremPath,
    required this.gitRevision,
    required this.revision,
    required this.oldValues,
  });

  /// The requirement's section id, e.g. `FRE-REQU-ORDER-CAPTURE`.
  final String itemSectionId;

  /// The document path of its `FREM` form.
  final String fremPath;

  /// The git revision that last changed the requirement.
  final String gitRevision;

  /// That git revision's document revision.
  final FremRevision revision;

  /// The `FREM` values before the fill, by field (absent when empty).
  final Map<String, String> oldValues;

  /// The values the fill writes, by field.
  Map<String, String> get newValues => {
    'version': revision.version,
    'lastModified': revision.date,
    'modifiedBy': revision.author,
  };

  /// Whether the fill changes a value.
  bool get changes => fremFields.any((f) => oldValues[f] != newValues[f]);

  /// One report line: the requirement, the values, the git revision.
  String get reportLine {
    final short = _short(gitRevision);
    return '${changes ? 'FREM' : 'same'}      $itemSectionId  '
        '${revision.version} ${revision.date} ${revision.author} '
        '(${revision.id}, $short)';
  }
}

/// The result of [planFremFill]: the fills, the findings and the new text.
class FremFillPlan {
  /// A plan of [fills] with [findings]; [newText] is null when nothing
  /// changes.
  const FremFillPlan({
    required this.fills,
    required this.findings,
    required this.newText,
    required this.inPlace,
  });

  /// One fill per functional requirement that could be attributed.
  final List<FremFill> fills;

  /// What could not be attributed or breaks the revision rule.
  final List<String> findings;

  /// The document with the fills, or null when no value changes.
  final String? newText;

  /// Whether the values were rewritten in place (every other byte kept); else
  /// the document was re-encoded.
  final bool inPlace;

  /// The fills that change a value.
  List<FremFill> get changed => [
    for (final f in fills)
      if (f.changes) f,
  ];
}

/// Thrown when the filled document does not read back as planned.
class FremFillVerificationException implements Exception {
  /// Reports [message].
  FremFillVerificationException(this.message);

  /// What did not read back.
  final String message;

  @override
  String toString() => 'FREM fill did not verify: $message';
}

/// Plans the `FREM` fill of the document whose versions are [history], oldest
/// first; its last version is the document as it is now, read against [tree].
///
/// A version that adds no revision entry breaks the rule that every git
/// revision has its own document revision: it is reported, and its changes
/// are attributed to the newest entry it holds. A requirement whose last
/// change is in a version without a revision list is reported and left as it
/// is.
FremFillPlan planFremFill(List<FremHistoryVersion> history, SomMetaTree tree) {
  if (history.isEmpty) {
    throw ArgumentError.value(history, 'history', 'no version');
  }
  final current = history.last.text;
  final decoded = SpecDocumentYaml.decode(current, tree);
  final doc = decoded.document;
  final requirements = _requirements(tree, doc);
  final findings = <String>[];

  // The document revision and the requirement sections of every version.
  final lastChange = <String, int>{};
  final revisionOf = <int, FremRevision?>{};
  Map<String, String?> previous = {};
  List<String> previousIds = const [];
  String? previousDocument;
  for (var k = 0; k < history.length; k++) {
    if (k > 0 && history[k].text == history[k - 1].text) continue;
    final index = _YamlIndex(history[k].text);
    final short = _short(history[k].revision);
    final entries = index.revisions();
    // A version that changes nothing but FREM values (a fill) needs no
    // revision entry of its own.
    final document = _canonical(index.root);
    final fremOnly = previousDocument == document;
    previousDocument = document;
    if (entries == null) {
      revisionOf[k] = null;
    } else {
      final added = [
        for (final e in entries)
          if (!previousIds.contains(e.id)) e,
      ];
      if (added.isNotEmpty) {
        revisionOf[k] = added.last;
      } else if (entries.isEmpty) {
        revisionOf[k] = null;
      } else {
        revisionOf[k] = entries.last;
        if (!fremOnly) {
          findings.add(
            'REVISION  $short changed the document without a revision entry of '
            'its own; its changes are attributed to ${entries.last.id}',
          );
        }
      }
      previousIds = [for (final e in entries) e.id];
    }
    final sections = <String, String?>{};
    for (final r in requirements) {
      final nodes = index.byId[r.itemSectionId];
      if (nodes != null && nodes.length > 1) {
        findings.add(
          'DUPLICATE ${r.itemSectionId} is in $short more than once; its '
          'last occurrence is compared',
        );
      }
      final canonical = nodes == null ? null : _canonical(nodes.last);
      sections[r.itemSectionId] = canonical;
      if (canonical != null && canonical != previous[r.itemSectionId]) {
        lastChange[r.itemSectionId] = k;
      }
    }
    previous = sections;
  }

  final fills = <FremFill>[];
  for (final r in requirements) {
    final k = lastChange[r.itemSectionId];
    if (k == null) continue;
    final revision = revisionOf[k];
    if (revision == null) {
      findings.add(
        'NOREVISION ${r.itemSectionId} last changed in '
        '${_short(history[k].revision)}, which has no revision list; FREM '
        'left as it is',
      );
      continue;
    }
    fills.add(
      FremFill(
        itemSectionId: r.itemSectionId,
        fremPath: r.fremPath,
        gitRevision: history[k].revision,
        revision: revision,
        oldValues: {
          for (final f in fremFields)
            if (doc.formField(r.fremPath, f) case final v?) f: v,
        },
      ),
    );
  }

  final changed = [
    for (final f in fills)
      if (f.changes) f,
  ];
  if (changed.isEmpty) {
    return FremFillPlan(
      fills: fills,
      findings: findings,
      newText: null,
      inPlace: true,
    );
  }

  final expected = SpecDocumentYaml.decode(current, tree).document;
  for (final f in changed) {
    f.newValues.forEach((field, value) {
      expected.setFormField(f.fremPath, field, value);
    });
  }
  var inPlace = true;
  String newText;
  try {
    newText = _rewriteInPlace(current, changed);
  } on YamlRewriteException {
    inPlace = false;
    newText = SpecDocumentYaml.encode(
      document: expected,
      tree: tree,
      modelVersion: decoded.modelVersion,
      review: decoded.review,
    );
  }
  final readBack = SpecDocumentYaml.decode(newText, tree).document;
  if (jsonEncode(readBack.toJson()) != jsonEncode(expected.toJson())) {
    throw FremFillVerificationException(
      'the written document differs from the document with the fills',
    );
  }
  return FremFillPlan(
    fills: fills,
    findings: findings,
    newText: newText,
    inPlace: inPlace,
  );
}

/// A commit's first eight characters; any other revision as it is.
String _short(String revision) => RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)
    ? revision.substring(0, 8)
    : revision;

/// A functional requirement of the current document.
class _Requirement {
  const _Requirement(this.itemSectionId, this.fremPath);
  final String itemSectionId;
  final String fremPath;
}

/// Every list item of the current document whose class has a `FREM` form.
List<_Requirement> _requirements(SomMetaTree tree, SpecDocument doc) {
  final found = <_Requirement>[];
  void walk(SomMetaNode node, String path) {
    if (node.recursive) return;
    for (final child in node.children) {
      final childPath = '$path/${child.segment}';
      if (!doc.hasValuesUnder(childPath)) continue;
      if (child.kind == SomMetaKind.list) {
        final element = child.elementNode;
        if (element == null) continue;
        final frem = element.children.where(
          (c) => c.kind == SomMetaKind.form && c.sectionId == fremSectionId,
        );
        for (final item in doc.listItems(childPath)) {
          final id = doc.itemSectionId(item);
          if (frem.isNotEmpty && id != null) {
            found.add(_Requirement(id, '$item/${frem.first.segment}'));
          }
          walk(element, item);
        }
      } else {
        walk(child, childPath);
      }
    }
  }

  walk(tree.root, tree.root.segment);
  return found;
}

/// The section id a YAML key carries: its first word.
String _idOfKey(Object? key) => '$key'.trim().split(RegExp(r'\s+')).first;

/// Every mapping value of a YAML text by the section id of its key.
class _YamlIndex {
  _YamlIndex(String text) : root = loadYamlNode(text) {
    _walk(root);
  }

  /// The parsed text.
  final YamlNode root;

  final Map<String, List<YamlNode>> byId = {};

  void _walk(YamlNode node) {
    if (node is YamlMap) {
      for (final e in node.nodes.entries) {
        final id = _idOfKey((e.key as YamlNode).value);
        (byId[id] ??= []).add(e.value);
        _walk(e.value);
      }
    } else if (node is YamlList) {
      node.nodes.forEach(_walk);
    }
  }

  /// The revision list's entries in list order, or null without a list.
  List<FremRevision>? revisions() {
    final list = byId[revisionListSectionId]?.first;
    if (list == null) return null;
    if (list is! YamlMap) return const [];
    return [
      for (final e in list.nodes.entries)
        _revision(_idOfKey((e.key as YamlNode).value), e.value),
    ];
  }

  FremRevision _revision(String id, YamlNode item) {
    String field(String name) {
      if (item is! YamlMap) return '';
      final direct = item.nodes[name];
      final content = item.nodes['content'];
      final node = direct ?? (content is YamlMap ? content.nodes[name] : null);
      return node is YamlScalar ? '${node.value ?? ''}'.trim() : '';
    }

    return FremRevision(id, field('version'), field('date'), field('author'));
  }
}

/// [node] without its `FREM` member, as text that ignores key order.
String _canonical(YamlNode node) {
  Object? plain(YamlNode n) {
    if (n is YamlMap) {
      final keys = [
        for (final k in n.nodes.keys)
          if (_idOfKey((k as YamlNode).value) != fremSectionId) k,
      ]..sort((a, b) => '${a.value}'.compareTo('${b.value}'));
      return {for (final k in keys) '${k.value}': plain(n.nodes[k]!)};
    }
    if (n is YamlList) return [for (final c in n.nodes) plain(c)];
    return '${(n as YamlScalar).value ?? ''}';
  }

  return jsonEncode(plain(node));
}

/// [text] with the changed `FREM` values rewritten in place.
///
/// Throws [YamlRewriteException] when a requirement has no `FREM`, a field is
/// missing, or a value is not a block scalar in the encoder's shape.
String _rewriteInPlace(String text, List<FremFill> fills) {
  final index = _YamlIndex(text);
  final edits = <ValueEdit>[];
  for (final f in fills) {
    final item = index.byId[f.itemSectionId]?.last;
    final frem = item is YamlMap ? _entry(item, fremSectionId) : null;
    if (frem == null || frem.value is! YamlMap) {
      throw YamlRewriteException(f.fremPath, 'no FREM form to rewrite');
    }
    final form = frem.value as YamlMap;
    for (final field in fremFields) {
      final e = _entry(form, field);
      if (e == null) {
        throw YamlRewriteException(f.fremPath, 'no `$field` to rewrite');
      }
      final key = e.key as YamlNode;
      edits.add(
        ValueEdit(
          ValueLocation(
            path: f.fremPath,
            idPath: '${f.itemSectionId} > FREM > $field',
            role: ValueRole.scalar,
            keyLine: key.span.start.line,
            keyColumn: key.span.start.column,
            value: f.oldValues[field] ?? '',
          ),
          f.newValues[field]!,
        ),
      );
    }
  }
  return rewriteValues(text, edits);
}

MapEntry<dynamic, YamlNode>? _entry(YamlMap map, String id) {
  for (final e in map.nodes.entries) {
    if (_idOfKey((e.key as YamlNode).value) == id) return e;
  }
  return null;
}
