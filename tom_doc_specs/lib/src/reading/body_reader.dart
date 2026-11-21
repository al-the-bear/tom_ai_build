/// Reads the list bodies and section tables of a section's body into the
/// section tree (DocSpecs specification, *List Bodies*).
library;

import 'package:tom_doc_scanner/tom_doc_scanner.dart';

import '../models/schema/doc_spec_schema.dart';
import '../models/schema/form_type_def.dart';
import '../models/schema/section_type_def.dart';
import '../models/spec_section.dart';
import '../validation/validation_error.dart';
import 'reading_grammar.dart';

/// A section body after [BodyReader.read]: the text with the tables and divs
/// it read removed, the line of its first line, the children with the
/// virtual sections added and the values given, and the findings.
class ReadBody {
  /// The body text without the section tables and list-body divs read.
  final String text;

  /// The file line of [text]'s first line; `null` when [text] is empty.
  final int? textLineNumber;

  /// The children: the headed ones (with the values a section table gave
  /// them) and the virtual ones, in reading order.
  final List<Section>? sections;

  /// The findings of the tables and divs read.
  final List<ValidationError> findings;

  /// Records a read body.
  const ReadBody({
    required this.text,
    required this.textLineNumber,
    required this.sections,
    required this.findings,
  });
}

/// Turns the alternative spellings of child sections in a section's body
/// into sections of the tree, from the schema alone:
///
/// - a **section table** (`Section | TomSpecField | Value`, or
///   `DocSpecsField`): each row's values go to the child its `Section` cell
///   names — a headed child, or a virtual one created for an id that
///   resolves to a type allowed there;
/// - a **`refs` div** in a list container: one virtual item per reference
///   id, the id written as the item's virtual body line;
/// - a **`records` div** in a list container: one virtual item per table row,
///   its cells the item's form values.
///
/// The tables and divs read are blanked from the body, so a container
/// written with one has an empty body (`max-text-length: 0`). Every finding
/// of *Findings in list bodies and tables* is returned with its code.
class BodyReader {
  /// A reader for documents of [schema].
  BodyReader(this.schema);

  /// The schema the virtual sections come from.
  final DocSpecSchema schema;

  /// Reads the body [text] (first line at [textLineNumber]) of section [id]
  /// with [children]. [allowed] says which section types may stand below it;
  /// [type] is its section type, `null` for the document root (which has no
  /// list body).
  ReadBody read({
    required String id,
    required SectionTypeDef? type,
    required bool Function(String typeName) allowed,
    required String text,
    required int? textLineNumber,
    required List<Section>? children,
  }) {
    final base = textLineNumber;
    if (text.isEmpty || base == null) {
      return ReadBody(
        text: text,
        textLineNumber: textLineNumber,
        sections: children,
        findings: const [],
      );
    }
    final body = text.split('\n');
    int lineOf(int k) => base + k;
    final node = _Draft.root(id, [
      for (final c in children ?? const <Section>[]) _Draft.of(c),
    ]);
    final findings = <ValidationError>[];
    _readSectionTables(node, body, lineOf, allowed, findings);
    if (type != null) _readListBody(node, type, body, lineOf, findings);

    var start = 0;
    var end = body.length;
    while (start < end && body[start].trim().isEmpty) {
      start++;
    }
    while (end > start && body[end - 1].trim().isEmpty) {
      end--;
    }
    final readText = body.sublist(start, end).join('\n').trim();
    final changed = node.children.any((c) => c.changed) || node.added;
    return ReadBody(
      text: readText,
      textLineNumber: readText.isEmpty ? null : lineOf(start),
      sections: !changed
          ? children
          : node.children.isEmpty
          ? null
          : [for (final (i, c) in node.children.indexed) _build(c, i)],
      findings: findings,
    );
  }

  Section _build(_Draft d, int index) {
    final section = d.section;
    if (section != null && !d.changed) return section;
    final kids = [for (final (i, c) in d.children.indexed) _build(c, i)];
    if (section != null) {
      final spec = section is SpecSection
          ? section
          : SpecSection.fromSection(section, type: d.typeName);
      return spec.copyWith(
        sections: kids.isEmpty ? null : kids,
        addedValues: d.values,
      );
    }
    final typeName = d.typeName;
    return SpecSection(
      index: index,
      lineNumber: d.line,
      rawHeadline: '',
      name: d.title,
      id: d.id,
      text: '',
      sections: kids.isEmpty ? null : kids,
      type: typeName,
      format: typeName == null ? null : schema.sectionTypes[typeName]?.format,
      isVirtual: true,
      virtualValues: d.values,
    );
  }

  // --- Section tables -------------------------------------------------------

  void _readSectionTables(
    _Draft node,
    List<String> body,
    int Function(int) lineOf,
    bool Function(String) allowed,
    List<ValidationError> findings,
  ) {
    final fence = FenceTracker();
    for (var i = 0; i < body.length; i++) {
      final line = body[i];
      final wasInFence = fence.inFence;
      fence.feed(line);
      if (wasInFence || fence.inFence) continue;
      final h = ReadingGrammar.layoutTableHeader.firstMatch(line);
      if (h == null || h.group(1) == null) continue;
      final table = ReadingGrammar.readTable(
        body,
        i,
        lineOf,
        node.id,
        findings,
      );
      _Draft? target;
      var skip = false;
      for (final (k, cells) in table.rows) {
        final cell = ReadingGrammar.cellId(cells[0]);
        if (cell.isNotEmpty) {
          target = _sectionTableTarget(node, cell, allowed, lineOf(k));
          skip = target == null;
          if (target == null) {
            findings.add(
              _unknownSection(
                cell,
                lineOf(k),
                'section-table row names no child section of "${node.id}"',
              ),
            );
            continue;
          }
        } else if (skip) {
          continue; // the rejected child's further rows
        } else if (target == null) {
          findings.add(
            _unknownSection(
              node.id,
              lineOf(k),
              'section-table row names no section',
            ),
          );
          continue;
        }
        target.values.add(
          FormEntry(
            label: cells[1],
            value: ReadingGrammar.cellValue(cells[2]),
            line: lineOf(k),
            source: FormEntrySource.virtual,
          ),
        );
      }
      for (var k = i; k < table.end; k++) {
        body[k] = '';
      }
      i = table.end - 1;
    }
  }

  /// The child a section-table `Section` cell names under [node]: a child by
  /// its id, or `<LIST> / <ITEM>` — an item of a child list. A child or item
  /// without a heading is created as a virtual section when its id resolves
  /// to a type allowed where it stands; `null` otherwise.
  _Draft? _sectionTableTarget(
    _Draft node,
    String cell,
    bool Function(String) allowed,
    int line,
  ) {
    final parts = cell.split(RegExp(r'\s*/\s*'));
    if (parts.length > 2) return null;
    _Draft? child(_Draft parent, String id, bool Function(String) ok) {
      for (final c in parent.children) {
        if (c.id == id) return c;
      }
      final t = schema.resolveSectionType(id);
      if (t == null || !ok(t)) return null;
      final created = _Draft.virtual(id, line, t);
      parent.children.add(created);
      parent.added = true;
      return created;
    }

    final first = child(node, parts[0], allowed);
    if (parts.length == 1 || first == null) return first;
    final listTypeName = first.typeName ?? schema.resolveSectionType(parts[0]);
    final listType = listTypeName == null
        ? null
        : schema.sectionTypes[listTypeName];
    if (listType == null) return null;
    return child(
      first,
      parts[1],
      (t) => listType.subsectionTypes?.containsKey(t) ?? false,
    );
  }

  // --- List bodies ----------------------------------------------------------

  void _readListBody(
    _Draft node,
    SectionTypeDef type,
    List<String> body,
    int Function(int) lineOf,
    List<ValidationError> findings,
  ) {
    final fence = FenceTracker();
    for (var i = 0; i < body.length; i++) {
      final line = body[i];
      final wasInFence = fence.inFence;
      fence.feed(line);
      if (wasInFence || fence.inFence) continue;
      final open = ReadingGrammar.listDivOpen.firstMatch(line);
      if (open == null) continue;
      final kind = open.group(1) ?? open.group(2)!;
      final at = lineOf(i);
      void reject(String message) =>
          findings.add(ReadingGrammar.malformedBlock(node.id, at, message));
      var close = -1;
      for (var k = i + 1; k < body.length; k++) {
        if (ReadingGrammar.listDivClose.hasMatch(body[k])) {
          close = k;
          break;
        }
      }
      if (close < 0) {
        reject('unclosed $kind fence'); // its lines stay text
        return;
      }
      var besideText = false;
      for (var k = 0; k < body.length; k++) {
        if ((k < i || k > close) && body[k].trim().isNotEmpty) {
          besideText = true;
          break;
        }
      }
      final hasItems = node.children.isNotEmpty;
      final inner = body.sublist(i + 1, close);
      for (var k = i; k <= close; k++) {
        body[k] = '';
      }
      if (besideText || hasItems) {
        reject(
          'a $kind div beside ${hasItems ? 'item headings' : 'other text'} '
          'in a list container',
        );
        return;
      }
      final subTypes = type.subsectionTypes;
      final itemType = subTypes != null && subTypes.length == 1
          ? schema.sectionTypes[subTypes.keys.single]
          : null;
      if (itemType == null) {
        reject('a $kind div in a section that is not a list container');
        return;
      }
      if (kind == 'refs') {
        _refsItems(node, itemType, inner, at);
      } else {
        _recordItems(
          node,
          itemType,
          inner,
          (k) => lineOf(i + 1 + k),
          reject,
          findings,
        );
      }
      return;
    }
  }

  /// The form an item of [itemType] holds its values in, with the type of
  /// the virtual child that carries them: the type's own form (no child),
  /// else the form of its one subsection type that has one. With
  /// [oneField], only forms of exactly one field count.
  (FormTypeDef, String?)? _itemForm(
    SectionTypeDef itemType, {
    bool oneField = false,
  }) {
    bool fits(FormTypeDef? f) =>
        f != null && (!oneField || f.fields.length == 1);
    final own = schema.formTypeFor(itemType.format);
    if (fits(own)) return (own!, null);
    final candidates = <(FormTypeDef, String?)>[];
    for (final name in itemType.subsectionTypes?.keys ?? const <String>[]) {
      final f = schema.formTypeFor(schema.sectionTypes[name]?.format);
      if (fits(f)) candidates.add((f!, name));
    }
    return candidates.length == 1 ? candidates.single : null;
  }

  /// A virtual item of [itemType] with [id] at [line], added to [node];
  /// returns the section its values go to — the item itself, or its virtual
  /// child of [childType], whose id is the path `<item id>/<CHILD-TYPE>`
  /// (the child type's name upper-cased), unique in the document.
  _Draft _addItem(
    _Draft node,
    SectionTypeDef itemType,
    String? childType,
    String id,
    int line, {
    String title = '',
  }) {
    final item = _Draft.virtual(id, line, itemType.name, title: title);
    node.children.add(item);
    node.added = true;
    if (childType == null) return item;
    final child = _Draft.virtual(
      '$id/${childType.toUpperCase()}',
      line,
      childType,
    );
    item.children.add(child);
    return child;
  }

  /// A `refs` div: its text split on commas and whitespace into ids, a link
  /// counting as its link text; item n gets the positional id (the
  /// container's id with `-LST` replaced by `-<n>`, else `<id>-<n>`) and the
  /// reference as its virtual body line — `<Label>: <id>` with the label of
  /// the item's one-field form, the bare id without one.
  void _refsItems(
    _Draft node,
    SectionTypeDef itemType,
    List<String> inner,
    int at,
  ) {
    final target = _itemForm(itemType, oneField: true);
    final ids = [
      for (final token in inner.join(' ').split(RegExp(r'[,\s]+')))
        if (token.isNotEmpty)
          ReadingGrammar.linkText.firstMatch(token)?.group(1) ?? token,
    ];
    final container = node.id;
    final stem = container.endsWith('-LST')
        ? container.substring(0, container.length - 4)
        : container;
    for (var n = 1; n <= ids.length; n++) {
      final holder = _addItem(node, itemType, target?.$2, '$stem-$n', at);
      holder.values.add(
        FormEntry(
          label: target?.$1.fields.single.fieldname ?? '',
          value: ids[n - 1],
          line: at,
          source: FormEntrySource.virtual,
        ),
      );
    }
  }

  /// A `records` div: one table, `Id` first, `Title` optionally second, then
  /// field names of the item's form; each row one virtual item in row order.
  void _recordItems(
    _Draft node,
    SectionTypeDef itemType,
    List<String> inner,
    int Function(int) lineOf,
    void Function(String) reject,
    List<ValidationError> findings,
  ) {
    final start = inner.indexWhere((l) => l.trim().isNotEmpty);
    if (start < 0 || !ReadingGrammar.tableLine.hasMatch(inner[start])) {
      reject('a records div holding no table');
      return;
    }
    final header = ReadingGrammar.rowCells(inner[start]);
    if (header.first != 'Id') {
      reject('a records table whose first column is not Id');
      return;
    }
    // The item's form decides the columns; an item type without a form takes
    // its columns as virtual body lines unchecked.
    final target = _itemForm(itemType);
    final withTitle = header.length > 1 && header[1] == 'Title';
    final columns = <String>[];
    for (final label in header.skip(withTitle ? 2 : 1)) {
      final lower = label.toLowerCase();
      final field = target == null
          ? label
          : target.$1.fields
                .where((f) => f.fieldname.toLowerCase() == lower)
                .firstOrNull
                ?.fieldname;
      if (field == null) {
        findings.add(
          ValidationError(
            message: 'records column "$label" names no field of the items',
            lineNumber: lineOf(start),
            sectionId: node.id,
            category: ValidationErrorCategory.format,
            code: 'unknownField',
          ),
        );
        return;
      }
      columns.add(field);
    }
    final table = ReadingGrammar.readTable(
      inner,
      start,
      lineOf,
      node.id,
      findings,
    );
    final offset = withTitle ? 2 : 1;
    for (final (k, cells) in table.rows) {
      final holder = _addItem(
        node,
        itemType,
        target?.$2,
        ReadingGrammar.cellId(cells[0]),
        lineOf(k),
        title: withTitle ? cells[1].replaceAll(_lineBreak, '\n') : '',
      );
      for (var c = 0; c < columns.length; c++) {
        final value = ReadingGrammar.cellValue(cells[offset + c]);
        if (value.isEmpty) continue;
        holder.values.add(
          FormEntry(
            label: columns[c],
            value: value,
            line: lineOf(k),
            source: FormEntrySource.virtual,
          ),
        );
      }
    }
  }

  static final RegExp _lineBreak = RegExp(r'<br\s*/?>');

  static ValidationError _unknownSection(String id, int line, String message) =>
      ValidationError(
        message: message,
        lineNumber: line,
        sectionId: id,
        category: ValidationErrorCategory.structure,
        code: 'unknownSection',
      );
}

/// A section while its parent's body is read: a headed section (kept as is
/// unless it gains values or children) or a virtual one.
class _Draft {
  _Draft.root(this.id, this.children)
    : section = null,
      line = 0,
      typeName = null,
      title = '';

  _Draft.of(Section s)
    : section = s,
      id = s.id,
      line = s.lineNumber,
      typeName = s is SpecSection ? s.type : null,
      title = s.name,
      children = [
        for (final c in s.sections ?? const <Section>[]) _Draft.of(c),
      ];

  _Draft.virtual(this.id, this.line, this.typeName, {this.title = ''})
    : section = null,
      children = [];

  final Section? section;
  final String id;
  final int line;
  final String? typeName;
  final String title;
  final List<_Draft> children;
  final List<FormEntry> values = [];

  /// Whether children were added below it.
  bool added = false;

  /// Whether the built section differs from [section].
  bool get changed =>
      section == null ||
      values.isNotEmpty ||
      added ||
      children.any((c) => c.changed);
}
