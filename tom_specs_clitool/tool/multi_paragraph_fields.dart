/// Lists the form fields whose values hold paragraphs or blocks, and proposes
/// a field order for the forms that have one (reading view, 02a_rdv4).
///
/// Usage (from tom_specs_clitool):
///
/// ```text
///   dart run tool/multi_paragraph_fields.dart --dir <folder> ... [<file.tomspecs.yaml> ...] [--out <proposal.md>]
///
///   e.g. --dir ../../../tom_uam/tom_specs/phase2_solution_blueprint
///        --dir ../../../tom_uam/tom_specs/phase3_detailed_specifications
///        --dir ../tom_som_conformance/samples
///        ../tom_som_dart_v0/documents/meridian_order_management.tomspecs.yaml
///        --out <quest>/ideas/reading_view/field_order_proposal.md
/// ```
///
/// A `--dir` contributes the `*.tomspecs.yaml` files directly in it (not its
/// step folders). Each document is read through the SOM runtime against the
/// embedded model; a document of another model (the demo corpus) is skipped
/// and named. A value is *multi-paragraph* when it holds a blank line, a
/// *block* when it holds a list item, a table or fenced code. For every form
/// with such a field the report gives each field's counts and one example
/// path, the form's current field order, the proposed order (identifying and
/// summary fields first, the fields to flag last, the rest in their present
/// relative order) and the fields to flag `multiParagraph`. Without `--out`
/// the report goes to stdout. Changes no model file.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart'
    show resolveSpecDocumentRoot;

/// One form field's observations across the documents.
class _FieldStat {
  int values = 0;
  int multiParagraph = 0;
  int block = 0;
  String? example;

  bool get flagged => multiParagraph > 0 || block > 0;
}

/// One form (a class's form member) and its fields' observations.
class _FormStat {
  _FormStat(this.className, this.member, this.fields);

  final String className;
  final String member;
  final List<SomFormFieldMeta> fields;
  final Map<String, _FieldStat> stats = {};
}

final RegExp _blankLine = RegExp(r'\n[ \t]*\n');
final RegExp _listLine = RegExp(r'^\s{0,3}([-*+]|\d+[.)])\s', multiLine: true);
final RegExp _fenceLine = RegExp(r'^\s{0,3}(```|~~~)', multiLine: true);
final RegExp _tableSeparator = RegExp(
  r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$',
  multiLine: true,
);

bool _isBlock(String value) =>
    _listLine.hasMatch(value) ||
    _fenceLine.hasMatch(value) ||
    (value.contains('|') && _tableSeparator.hasMatch(value));

/// Identifying and summary fields: ids, labels, names, titles, keys,
/// summaries, and enum-typed fields.
bool _isIdentifying(SomFormFieldMeta f) {
  final n = f.name.toLowerCase();
  return f.enumValues.isNotEmpty ||
      n == 'id' ||
      n == 'name' ||
      n == 'ref' ||
      n.endsWith('id') ||
      n.endsWith('name') ||
      n.endsWith('label') ||
      n.endsWith('title') ||
      n.endsWith('key') ||
      n.contains('summary');
}

Future<void> main(List<String> args) async {
  final dirs = <String>[];
  final files = <String>[];
  String? out;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--dir' && i + 1 < args.length) {
      dirs.add(args[++i]);
    } else if (a == '--out' && i + 1 < args.length) {
      out = args[++i];
    } else if (a == '-h' || a == '--help') {
      stdout.writeln(
        'Usage: dart run tool/multi_paragraph_fields.dart --dir <folder> ... '
        '[<file.tomspecs.yaml> ...] [--out <proposal.md>]',
      );
      return;
    } else {
      files.add(a);
    }
  }
  for (final d in dirs) {
    final entries =
        Directory(d)
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.tomspecs.yaml'))
            .map((f) => f.path)
            .toList()
          ..sort();
    files.addAll(entries);
  }
  if (files.isEmpty) {
    stderr.writeln('multi_paragraph_fields: no documents (use --dir or files)');
    exitCode = 2;
    return;
  }

  final model = somSpecModel;
  final forms = <String, _FormStat>{};
  final read = <String>[];
  final skipped = <String>[];
  for (final file in files) {
    final text = File(file).readAsStringSync();
    final SpecRoot root;
    try {
      root = resolveSpecDocumentRoot(model, null, text, isMarkdown: false);
    } on ArgumentError catch (e) {
      skipped.add('${p.basename(file)} (${e.message})');
      continue;
    }
    final tree = buildSomMetaTree(model, rootType: root.type);
    final SpecDocument doc;
    try {
      doc = SpecDocument.fromYaml(text, tree);
    } on Object catch (e) {
      skipped.add('${p.basename(file)} ($e)');
      continue;
    }
    read.add(p.basename(file));

    void walk(SomMetaNode node, String path) {
      final form = node.form;
      if (node.kind == SomMetaKind.form && form != null) {
        final key = '${node.className}.${node.memberName ?? node.segment}';
        final stat = forms.putIfAbsent(
          key,
          () => _FormStat(
            node.className,
            node.memberName ?? node.segment,
            form.fields,
          ),
        );
        for (final f in form.fields) {
          final value = doc.formField(path, f.name);
          if (value == null) continue;
          final s = stat.stats.putIfAbsent(f.name, _FieldStat.new);
          s.values++;
          final mp = _blankLine.hasMatch(value.trim());
          final block = _isBlock(value);
          if (mp) s.multiParagraph++;
          if (block) s.block++;
          if ((mp || block) && s.example == null) {
            s.example = '${p.basename(file)}: $path';
          }
        }
      }
      if (node.recursive) return;
      for (final child in node.children) {
        final childPath = '$path/${child.segment}';
        if (!doc.hasValuesUnder(childPath)) continue;
        if (child.kind == SomMetaKind.list) {
          final element = child.elementNode;
          if (element == null) continue;
          for (final item in doc.listItems(childPath)) {
            walk(element, item);
          }
        } else {
          walk(child, childPath);
        }
      }
    }

    walk(tree.root, tree.root.segment);
  }

  final flaggedForms =
      [
        for (final f in forms.values)
          if (f.stats.values.any((s) => s.flagged)) f,
      ]..sort(
        (a, b) => '${a.className}.${a.member}'.compareTo(
          '${b.className}.${b.member}',
        ),
      );

  final b = StringBuffer()
    ..writeln('## Documents read')
    ..writeln()
    ..writeln('${read.length} documents: ${read.join(', ')}.')
    ..writeln();
  if (skipped.isNotEmpty) {
    b
      ..writeln(
        'Skipped (another model, or unreadable): ${skipped.join('; ')}.',
      )
      ..writeln();
  }
  final flagCount = flaggedForms.fold<int>(
    0,
    (n, f) => n + f.stats.values.where((s) => s.flagged).length,
  );
  b
    ..writeln('## Summary')
    ..writeln()
    ..writeln(
      '${flaggedForms.length} forms in ${{for (final f in flaggedForms) f.className}.length} '
      'classes have $flagCount fields to flag.',
    )
    ..writeln();
  for (final form in flaggedForms) {
    final toFlag = [
      for (final f in form.fields)
        if (form.stats[f.name]?.flagged ?? false) f,
    ];
    final first = [
      for (final f in form.fields)
        if (!toFlag.contains(f) && _isIdentifying(f)) f,
    ];
    final middle = [
      for (final f in form.fields)
        if (!toFlag.contains(f) && !_isIdentifying(f)) f,
    ];
    final proposed = [...first, ...middle, ...toFlag];
    final unchanged = [
      for (var i = 0; i < proposed.length; i++)
        proposed[i].name == form.fields[i].name,
    ].every((x) => x);
    b
      ..writeln('## `${form.className}` — `${form.member}`')
      ..writeln()
      ..writeln('| Field | Values | Multi-paragraph | Block | Example |')
      ..writeln('| --- | ---: | ---: | ---: | --- |');
    for (final f in toFlag) {
      final s = form.stats[f.name]!;
      b.writeln(
        '| `${f.name}` | ${s.values} | ${s.multiParagraph} | ${s.block} | '
        '`${s.example}` |',
      );
    }
    b
      ..writeln()
      ..writeln(
        '- **Current order:** ${form.fields.map((f) => f.name).join(', ')}',
      )
      ..writeln(
        '- **Proposed order:** ${proposed.map((f) => f.name).join(', ')}'
        '${unchanged ? ' (unchanged)' : ''}',
      )
      ..writeln(
        '- **Flag `multiParagraph`:** ${toFlag.map((f) => f.name).join(', ')}',
      )
      ..writeln();
  }

  if (out == null) {
    stdout.write(b);
  } else {
    File(out)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(b.toString());
    stdout.writeln(
      'multi_paragraph_fields: ${read.length} documents, '
      '${flaggedForms.length} forms, $flagCount fields -> $out',
    );
  }
}
