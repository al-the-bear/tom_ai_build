part of 'spec_document_markdown.dart';

// ---------------------------------------------------------------------------
// Generated parts (SOM §11.12): tables the rendition derives completely from
// the links of a document, written at the start of the section they belong
// to as a `derived` block and read back as nothing.
// ---------------------------------------------------------------------------

/// Written by the emitter at a generated place without a table: replaced by
/// an empty `derived` block when the value written after it begins with a
/// `derived` block, else removed with its blank line (SOM §11.12).
const String _kDerivedPlaceholder = '\u0000derived\u0000';

/// The requirement classes whose elements are the rows of the requirement
/// views: every element `INTR.relatedRequirements` may name.
const List<String> _requirementClasses = ['FRE', 'TERQ', 'SECRQ', 'ORRQ'];

/// One column of a generated table.
class _GeneratedColumn {
  const _GeneratedColumn(this.header, {this.place, this.covered = false});

  /// The header cell.
  final String header;

  /// The value's place under the row (`RETRAR.relatedScreens`); null: the
  /// row's own id (or its owner's, see [_GeneratedTable.owner]).
  final String? place;

  /// `yes` when [place] holds a value, else `no`.
  final bool covered;
}

/// A generated table: where it stands, its rows, its columns.
class _GeneratedTable {
  const _GeneratedTable({
    required this.at,
    required this.label,
    required this.rows,
    required this.columns,
    this.owner = const [],
  });

  /// The section ids of the headings it opens.
  final List<String> at;

  /// The block's `label` (DocSpecs RN-6).
  final String label;

  /// The class section ids whose elements are its rows, in document order.
  final List<String> rows;

  /// When set, the first column names the nearest element above the row of
  /// one of these classes instead of the row itself.
  final List<String> owner;

  /// The columns.
  final List<_GeneratedColumn> columns;
}

/// The generated tables (SOM §11.12): the requirement views of
/// DP-part-model-links-5 / -11 (D1–D4) where the links hold a table.
const List<_GeneratedTable> _generatedTables = [
  _GeneratedTable(
    at: ['RSP-TRAC', 'RO-TRAC'],
    label: "Generated from each requirement's traceability; edit it there",
    rows: _requirementClasses,
    columns: [
      _GeneratedColumn('Requirement'),
      _GeneratedColumn('Use cases', place: 'RT-TRAC.relatedUseCases'),
      _GeneratedColumn('Screens', place: 'RETRAR.relatedScreens'),
      _GeneratedColumn('Data entities', place: 'RETRAR.relatedDataEntities'),
      _GeneratedColumn('Tests', place: 'RETRAR.relatedTestCases'),
    ],
  ),
  _GeneratedTable(
    at: ['REQCOV'],
    label: "Generated from each requirement's test cases; edit them there",
    rows: _requirementClasses,
    columns: [
      _GeneratedColumn('Requirement'),
      _GeneratedColumn(
        'Covered',
        place: 'RETRAR.relatedTestCases',
        covered: true,
      ),
      _GeneratedColumn('By', place: 'RETRAR.relatedTestCases'),
    ],
  ),
  _GeneratedTable(
    at: ['RERE-REQU-LST'],
    label: "Generated from each requirement's dependencies; edit them there",
    rows: ['RQDEP'],
    owner: _requirementClasses,
    columns: [
      _GeneratedColumn('Requirement'),
      _GeneratedColumn('Dependency', place: 'RQDEP.dependencyType'),
      _GeneratedColumn('Related requirement', place: 'RQDEP-RELA-REF.ref'),
    ],
  ),
  _GeneratedTable(
    at: ['USCATR'],
    label: "Generated from each use case's traceability; edit it there",
    rows: ['INEN'],
    columns: [
      _GeneratedColumn('Use case'),
      _GeneratedColumn('Process', place: 'INTR.relatedProcess'),
      _GeneratedColumn('Requirements', place: 'INTR.relatedRequirements'),
      _GeneratedColumn('Tests', place: 'INTR.relatedTestCases'),
    ],
  ),
];

/// The generated table opening a heading with section id [id], if any.
_GeneratedTable? _generatedTableAt(String id) {
  for (final t in _generatedTables) {
    if (t.at.contains(id)) return t;
  }
  return null;
}

/// One root's generated parts.
class _Generated {
  _Generated(this.nav);

  final _Navigation nav;

  SpecDocumentMarkdown get codec => nav.codec;
  SpecDocument get doc => nav.doc;

  /// Whether the heading at [path] is a generated place (structural: its
  /// section id opens a generated table).
  bool isPlace(String path) {
    final node = nav.tree.byPath(path);
    if (node == null || nav.walk(path, d: doc).headingPath != path) {
      return false;
    }
    return _generatedTableAt(codec._headingIdOf(node)) != null;
  }

  /// The blocks of this document, by heading path: only the places whose
  /// table has rows.
  late final Map<String, List<String>> blocks = () {
    final out = <String, List<String>>{};
    for (final n in nav.tree.allNodes) {
      final path = n.path;
      if (path == null) continue;
      if (codec._isTransparentSection(n) || codec._isTransparentValue(n)) {
        continue;
      }
      final table = _generatedTableAt(codec._headingIdOf(n));
      if (table == null) continue;
      final block = _block(table);
      if (block != null) out[path] = block;
    }
    return out;
  }();

  /// Whether a generated block stands at or beneath [path], so the heading
  /// is written even when the document holds no value there.
  bool forces(String path) =>
      blocks.keys.any((p) => p == path || p.startsWith('$path/'));

  /// Every element of the document, in rendition order.
  late final List<String> _items = () {
    final out = <String>[];
    void walk(SomMetaNode node, String path) {
      for (final (child, rel) in codec._effectiveChildren(node)) {
        final p = '$path/$rel';
        if (!doc.hasValuesUnder(p)) continue;
        if (child.kind == SomMetaKind.list) {
          for (final item in doc.listItems(p)) {
            out.add(item);
            final element = child.elementNode;
            if (element != null && !element.recursive) walk(element, item);
          }
        } else if (child.kind == SomMetaKind.section ||
            child.kind == SomMetaKind.complex) {
          walk(child, p);
        }
      }
    }

    walk(nav.tree.root, nav.rootSeg);
    return out;
  }();

  String? _classId(String item) =>
      nav.refl.resolve(item)?.targetClass?.sectionId;

  /// The block lines of [table], or null when it has no row.
  List<String>? _block(_GeneratedTable table) {
    final rows = <List<String>>[];
    for (final item in _items) {
      if (!table.rows.contains(_classId(item))) continue;
      final cells = <String>[];
      for (final c in table.columns) {
        final place = c.place;
        if (place == null) {
          cells.add(_idCell(_rowOwner(item, table)));
          continue;
        }
        final r = specResolvePlaceAt(nav.refl, place, item);
        final field = r?.field;
        final raw = r == null || field == null
            ? null
            : doc.formField(r.path, field)?.trim();
        final value = raw == null || raw.isEmpty ? null : raw;
        if (c.covered) {
          cells.add(value == null ? 'no' : 'yes');
          continue;
        }
        if (value == null) {
          cells.add('');
          continue;
        }
        final meta = nav.tree
            .byPath(r!.path)
            ?.form
            ?.fields
            .where((f) => f.name == field)
            .firstOrNull;
        cells.add(
          meta == null
              ? value.replaceAll('|', r'\|')
              : codec._linkedCellText(meta, value),
        );
      }
      rows.add(cells);
    }
    if (rows.isEmpty) return null;
    return [
      '::: {.derived label="${table.label}"}',
      '| ${[for (final c in table.columns) c.header].join(' | ')} |',
      '| ${List.filled(table.columns.length, '---').join(' | ')} |',
      for (final r in rows) '| ${r.join(' | ')} |',
      ':::',
    ];
  }

  /// The element a row names: itself, or its nearest owner of
  /// [_GeneratedTable.owner].
  String? _rowOwner(String item, _GeneratedTable table) {
    if (table.owner.isEmpty) return item;
    var p = item;
    while (p.contains('/')) {
      p = p.substring(0, p.lastIndexOf('/'));
      if (nav._itemParts(p) != null && table.owner.contains(_classId(p))) {
        return p;
      }
    }
    return null;
  }

  /// A link to the element at [item] by its id and anchor.
  String _idCell(String? item) {
    if (item == null) return '';
    final w = nav.walk(item, d: doc);
    return '[${w.headingId}](#${w.anchor})';
  }
}

/// Whether [line] opens a `derived` block.
bool _opensDerived(String line) =>
    RegExp(r'^ {0,3}:{3,}[ \t]*\{\.derived(?=[\s}])').hasMatch(line);

/// [markdown] with every derived placeholder resolved: an empty `derived`
/// block where the block after it opens a `derived` block, else removed with
/// its blank line.
String _resolveDerivedPlaceholders(String markdown) {
  if (!markdown.contains(_kDerivedPlaceholder)) return markdown;
  final lines = markdown.split('\n');
  final out = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i] != _kDerivedPlaceholder) {
      out.add(lines[i]);
      continue;
    }
    var k = i + 1;
    while (k < lines.length && lines[k].trim().isEmpty) {
      k++;
    }
    if (k < lines.length && _opensDerived(lines[k])) {
      out
        ..add('::: {.derived}')
        ..add(':::');
    } else {
      i++; // the blank line after the placeholder goes with it
    }
  }
  return out.join('\n');
}
