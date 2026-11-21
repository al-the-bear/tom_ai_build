import 'package:tom_doc_scanner/tom_doc_scanner.dart';

import '../reading/reading_grammar.dart';
import '../validation/validation_error.dart';

/// Where a form value was written.
enum FormEntrySource {
  /// A `Fieldname: value` line of the section's body.
  label,

  /// A row of a form table (`TomSpecField | Value` / `DocSpecsField | Value`)
  /// in the section's body.
  row,

  /// A value the section was given from outside its body: a row of its
  /// parent's section table, a cell of a `records` table or an id of a `refs`
  /// line (DocSpecs specification, *List Bodies*).
  virtual,
}

/// One occurrence of a form value, in the order the section reads them.
class FormEntry {
  /// The field name as written (a `Fieldname:` label, a row's field cell, a
  /// record column's form field); empty for the bare reference id a `refs`
  /// line gives an item whose type has no one-field form.
  final String label;

  /// The value, trimmed; an empty row or cell value is no value.
  final String value;

  /// The line the value stands on in the file, when known.
  final int? line;

  /// Where the value was written.
  final FormEntrySource source;

  /// Records one occurrence.
  const FormEntry({
    required this.label,
    required this.value,
    required this.source,
    this.line,
  });

  /// The virtual body line this value stands for (`<Label>: <value>`, or the
  /// bare value without a label).
  String get bodyLine => label.isEmpty ? value : '$label: $value';

  @override
  String toString() => 'FormEntry($label: $value @$line, ${source.name})';
}

/// A section with schema type information.
///
/// Extends [Section] with DocSpecs-specific properties like type, tags,
/// and format. Provides methods for form field extraction and subsection access.
///
/// ## Example
///
/// ```dart
/// final section = spec['requirements']?.getSubsections().first as SpecSection;
/// print('Type: ${section.type}');
/// print('Tags: ${section.tags}');
///
/// // Access form fields
/// final method = section.getFormField('method');
/// final preamble = section.preamble;
/// ```
class SpecSection extends Section {
  /// The section type from the schema (determined by prefix matching, or by
  /// the schema for a virtual list item).
  final String? type;

  /// Tags parsed from `fields['tags']` (comma-separated in document).
  final List<String> tags;

  /// Format specification from schema (code block language or form type).
  final String? format;

  /// Whether the section has no heading of its own: a list item of a `refs`
  /// or `records` body, or a child a section table names (DocSpecs
  /// specification, *List Bodies*). Its [lineNumber] is the div's or row's.
  final bool isVirtual;

  /// The values the section was given from outside its body (see
  /// [FormEntrySource.virtual]), read before the body's own.
  final List<FormEntry> virtualValues;

  /// Findings made while the section's body was read into the tree — broken
  /// tables and divs of its list body or section table, fenced-div findings
  /// of the reading notation. The validator reports them.
  final List<ValidationError> readingFindings;

  /// Cached form fields extracted from text.
  Map<String, String>? _formFields;

  /// Cached preamble text.
  String? _preamble;

  /// Whether form fields have been parsed.
  bool _formFieldsParsed = false;

  /// Cached annotation blocks found after the first field.
  List<String> _misplacedAnnotations = const [];

  List<FormEntry> _formEntries = const [];
  List<FormEntry> _duplicateEntries = const [];
  List<ValidationError> _formTableFindings = const [];
  Map<String, int> _fieldLines = const {};

  /// Creates a new SpecSection.
  SpecSection({
    required super.index,
    required super.lineNumber,
    required super.rawHeadline,
    required super.name,
    required super.id,
    required super.text,
    super.fields = const {},
    super.sections,
    super.textLineNumber,
    this.type,
    List<String>? tags,
    this.format,
    this.isVirtual = false,
    List<FormEntry>? virtualValues,
    List<ValidationError>? readingFindings,
  }) : tags = tags ?? const [],
       virtualValues = List.unmodifiable(virtualValues ?? const []),
       readingFindings = List.unmodifiable(readingFindings ?? const []);

  /// Creates a SpecSection from a base Section with additional properties.
  factory SpecSection.fromSection(
    Section section, {
    String? type,
    List<String>? tags,
    String? format,
  }) {
    return SpecSection(
      index: section.index,
      lineNumber: section.lineNumber,
      rawHeadline: section.rawHeadline,
      name: section.name,
      id: section.id,
      text: section.text,
      fields: section.fields,
      sections: section.sections,
      textLineNumber: section.textLineNumber,
      type: type,
      tags: tags,
      format: format,
    );
  }

  /// Creates a SpecSection from a JSON map.
  factory SpecSection.fromJson(Map<String, dynamic> json) {
    return SpecSection(
      index: json['index'] as int,
      lineNumber: json['lineNumber'] as int,
      rawHeadline: json['rawHeadline'] as String? ?? '',
      name: json['name'] as String,
      id: json['id'] as String,
      text: json['text'] as String,
      fields: json['fields'] != null
          ? Map<String, String>.from(json['fields'] as Map)
          : const {},
      sections: json['sections'] != null
          ? (json['sections'] as List)
                .map((s) => SpecSection.fromJson(s as Map<String, dynamic>))
                .toList()
          : null,
      textLineNumber: json['textLineNumber'] as int?,
      type: json['type'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      format: json['format'] as String?,
      isVirtual: json['virtual'] as bool? ?? false,
      virtualValues: [
        for (final v in (json['virtualValues'] as List?) ?? const [])
          FormEntry(
            label: (v as Map)['label'] as String,
            value: v['value'] as String,
            line: v['line'] as int?,
            source: FormEntrySource.virtual,
          ),
      ],
    );
  }

  /// A copy with [sections] replaced and [addedValues] read after the
  /// section's [virtualValues].
  SpecSection copyWith({
    List<Section>? sections,
    List<FormEntry> addedValues = const [],
  }) {
    return SpecSection(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections ?? this.sections,
      textLineNumber: textLineNumber,
      type: type,
      tags: tags,
      format: format,
      isVirtual: isVirtual,
      virtualValues: [...virtualValues, ...addedValues],
      readingFindings: readingFindings,
    );
  }

  /// The section's content as the text checks see it: the virtual body
  /// lines of [virtualValues] (`<Label>: <value>`), then [text] — the text
  /// the same section has when its values are written in its own body.
  String get contentText {
    if (virtualValues.isEmpty) return text;
    return [
      for (final v in virtualValues) v.bodyLine,
      if (text.isNotEmpty) text,
    ].join('\n').trim();
  }

  /// Get a form field value from section text.
  ///
  /// Returns null if field not found.
  /// Equivalent to `${text[fieldname]}` placeholder syntax.
  String? getFormField(String fieldname) {
    _parseFormFields();
    return _formFields?[fieldname.toLowerCase()];
  }

  /// Get all form fields extracted from section text as a map.
  ///
  /// Keys are lowercase field names, values are the extracted text.
  Map<String, String> get formFields {
    _parseFormFields();
    return Map.unmodifiable(_formFields ?? const {});
  }

  /// Get the preamble text (text before first field or form table).
  ///
  /// Equivalent to `${text[]}` placeholder syntax.
  /// Returns null if no preamble exists.
  String? get preamble {
    _parseFormFields();
    return _preamble;
  }

  /// Review-annotation blocks (comment blocks `> ⬆️ …` and question blocks
  /// `> **❓ …`, SOM §11.9) that sit between or below the form fields. Such a
  /// block belongs in the preamble, above the first field; it is never read
  /// as part of a field value nor moved into the preamble, and is listed here
  /// so a caller can report it.
  List<String> get misplacedAnnotations {
    _parseFormFields();
    return List.unmodifiable(_misplacedAnnotations);
  }

  /// Every form value occurrence in reading order: the [virtualValues], then
  /// the body's `Fieldname:` lines and form-table rows as they stand.
  List<FormEntry> get formEntries {
    _parseFormFields();
    return List.unmodifiable(_formEntries);
  }

  /// The occurrences of a field already given that were not kept (Form
  /// Tables rule 6: the first occurrence wins). Two `Fieldname:` lines of the
  /// same field are the exception: the later one wins and none is listed, as
  /// tom_doc_specs always read them.
  List<FormEntry> get duplicateEntries {
    _parseFormFields();
    return List.unmodifiable(_duplicateEntries);
  }

  /// The broken form tables of the body: a missing or mismatched delimiter
  /// row, a row of another cell count (`malformedBlock`).
  List<ValidationError> get formTableFindings {
    _parseFormFields();
    return List.unmodifiable(_formTableFindings);
  }

  /// The file line of the occurrence of [fieldname] that was kept, when
  /// known.
  int? fieldLine(String fieldname) {
    _parseFormFields();
    return _fieldLines[fieldname.toLowerCase()];
  }

  /// Get all direct subsections of a specific type.
  ///
  /// Returns an empty list if no subsections match.
  List<SpecSection> getSubsectionsByType(String typeName) {
    if (sections == null) return [];
    return sections!
        .whereType<SpecSection>()
        .where((s) => s.type == typeName)
        .toList();
  }

  /// Get all direct subsections as SpecSection instances.
  ///
  /// Returns an empty list if no subsections exist.
  List<SpecSection> getSubsections() {
    if (sections == null) return [];
    return sections!.whereType<SpecSection>().toList();
  }

  static final _fieldPattern = RegExp(r'^([A-Za-z][A-Za-z0-9_-]*)\s*:\s*(.*)$');

  /// Parses form fields from the virtual values and the text content.
  ///
  /// Form syntax: `Fieldname: value`, or a form table
  /// (`| TomSpecField | Value |` / `| DocSpecsField | Value |`, one row per
  /// field; DocSpecs specification, *Form Tables*)
  /// - Field names are case-insensitive
  /// - Values continue until next field line, a blank line or a form table
  /// - Text before the first field or form table is the preamble
  void _parseFormFields() {
    if (_formFieldsParsed) return;
    _formFieldsParsed = true;

    final fields = <String, String>{};
    final givenBy = <String, FormEntrySource>{};
    final fieldLines = <String, int>{};
    final entries = <FormEntry>[];
    final duplicates = <FormEntry>[];
    final tableFindings = <ValidationError>[];

    void take(FormEntry e) {
      entries.add(e);
      if (e.label.isEmpty) return; // a bare reference id: no field
      // A `Fieldname:` line counts as given even with an empty value, a row
      // or a virtual value only with one.
      if (e.source != FormEntrySource.label && e.value.isEmpty) return;
      final key = e.label.toLowerCase();
      final prior = givenBy[key];
      if (prior == FormEntrySource.label && e.source == FormEntrySource.label) {
        // Two `Fieldname:` lines: the later wins, as it always did.
        fields[key] = e.value;
        if (e.line != null) fieldLines[key] = e.line!;
        return;
      }
      if (prior != null) {
        duplicates.add(e);
        return;
      }
      givenBy[key] = e.source;
      fields[key] = e.value;
      if (e.line != null) fieldLines[key] = e.line!;
    }

    virtualValues.forEach(take);

    final lines = text.isEmpty ? const <String>[] : text.split('\n');
    final base = textLineNumber;
    int? lineOf(int k) => base == null ? null : base + k;

    String? currentField;
    int? currentLine;
    final currentValue = StringBuffer();
    final preambleBuffer = StringBuffer();
    var foundFirstField = false;

    void flushField() {
      final field = currentField;
      if (field == null) return;
      take(
        FormEntry(
          label: field,
          value: currentValue.toString().trim(),
          line: currentLine,
          source: FormEntrySource.label,
        ),
      );
      currentValue.clear();
      currentField = null;
    }

    final misplaced = <String>[];
    StringBuffer? block; // the annotation block being skipped, if any
    final fence = FenceTracker();
    var escapedTable = false; // inside a content table written with `·|`

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      final wasInFence = fence.inFence;
      fence.feed(line);
      final fenced = wasInFence || fence.inFence;

      // A content line shaped like a layout header is written with one
      // escape space before its first `|`; the space is removed and the
      // table stays content (Form Tables rule 5).
      if (!fenced && ReadingGrammar.escapedLayoutTableHeader.hasMatch(line)) {
        escapedTable = true;
      } else if (escapedTable && !line.startsWith(' |')) {
        escapedTable = false;
      }
      if (escapedTable) line = line.substring(1);

      final quoted = line.trimLeft().startsWith('>');
      if (block != null) {
        if (quoted) {
          block.write('\n$line');
          continue;
        }
        misplaced.add(block.toString());
        block = null;
      }
      // A review annotation after the first field is not field text: it ends
      // the current field and is set aside (SOM §11.9.4).
      if (foundFirstField && quoted && _isAnnotationStart(line)) {
        flushField();
        block = StringBuffer(line);
        continue;
      }

      // A form table ends the preamble and the open field; its rows are
      // fields.
      final header = fenced || escapedTable
          ? null
          : ReadingGrammar.layoutTableHeader.firstMatch(line);
      if (header != null && header.group(1) == null) {
        flushField();
        foundFirstField = true;
        final table = ReadingGrammar.readTable(
          lines,
          i,
          (k) => lineOf(k) ?? lineNumber,
          id,
          tableFindings,
        );
        for (final (k, cells) in table.rows) {
          take(
            FormEntry(
              label: cells[0],
              value: ReadingGrammar.cellValue(cells[1]),
              line: lineOf(k),
              source: FormEntrySource.row,
            ),
          );
        }
        i = table.end - 1;
        continue;
      }

      final match = _fieldPattern.firstMatch(line);

      if (match != null) {
        flushField();
        // Start new field
        foundFirstField = true;
        currentField = match.group(1)!;
        currentLine = lineOf(i);
        currentValue.write(match.group(2));
      } else if (foundFirstField && currentField != null) {
        // A blank line terminates the current field value
        if (line.trim().isEmpty) {
          flushField();
        } else {
          // Continue current field value
          if (currentValue.isNotEmpty) {
            currentValue.write('\n');
          }
          currentValue.write(line);
        }
      } else {
        // Preamble text (before first field)
        if (preambleBuffer.isNotEmpty) {
          preambleBuffer.write('\n');
        }
        preambleBuffer.write(line);
      }
    }

    if (block != null) misplaced.add(block.toString());
    _misplacedAnnotations = misplaced;

    // Save last field
    flushField();

    _formFields = fields;
    _formEntries = entries;
    _duplicateEntries = duplicates;
    _formTableFindings = tableFindings;
    _fieldLines = fieldLines;
    final preambleText = preambleBuffer.toString().trim();
    _preamble = preambleText.isEmpty ? null : preambleText;
  }

  /// Whether [line] opens a comment block or a question block.
  static bool _isAnnotationStart(String line) {
    var inner = line.trimLeft().substring(1);
    if (inner.startsWith(' ')) inner = inner.substring(1);
    return inner.startsWith('\u2B06') || inner.startsWith('**\u2753');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      if (type != null) 'type': type,
      if (tags.isNotEmpty) 'tags': tags,
      if (format != null) 'format': format,
      if (isVirtual) 'virtual': true,
      if (virtualValues.isNotEmpty)
        'virtualValues': [
          for (final v in virtualValues)
            {
              'label': v.label,
              'value': v.value,
              if (v.line != null) 'line': v.line,
            },
        ],
    };
  }

  @override
  String toString() =>
      'SpecSection(name: $name, id: $id, type: $type, tags: $tags)';
}
