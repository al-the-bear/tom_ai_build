/// The IR's file form (`irspecs_ir.md`, § The file): an [IrDocument] as YAML
/// text and back.
///
/// The writer prints block YAML with **every string double-quoted and JSON
/// escaped**. That is a deliberate narrowing of YAML: a doc comment carries
/// `:`, `#`, quotes, backslashes and leading spaces, and a writer that decided
/// per string whether it needed quoting would be a second place for the IR to
/// lose a character. A JSON string literal is a valid YAML double-quoted
/// scalar and reads back exactly, so one rule covers every string. Empty
/// lists and maps are written in flow form (`[]`, `{}`). Output is
/// deterministic: the codec fixes key order, and nothing here sorts or wraps.
library;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'ir_codec.dart';
import 'ir_model.dart';

/// [document] as YAML text, ending in one newline.
String writeIrYaml(IrDocument document) {
  final out = StringBuffer();
  _writeMap(out, irDocumentToData(document), 0);
  return out.toString();
}

/// The document [text] holds. [source] names it in errors.
///
/// Throws [IrSpecsException] when [text] is not YAML or not an IR document.
IrDocument readIrYaml(String text, {String source = 'IR document'}) {
  final Object? yaml;
  try {
    yaml = loadYaml(text, sourceUrl: Uri.file(source));
  } on YamlException catch (e) {
    throw IrSpecsException('$source: not YAML (${e.message})');
  }
  return irDocumentFromData(plainYaml(yaml), source: source);
}

/// [yaml] as plain Dart maps, lists and scalars — the shape the codec and a
/// JSON Schema validator read.
Object? plainYaml(Object? yaml) => switch (yaml) {
  final YamlMap map => {
    for (final e in map.entries) '${e.key}': plainYaml(e.value),
  },
  final YamlList list => [for (final e in list) plainYaml(e)],
  _ => yaml,
};

void _writeMap(StringBuffer out, Map<String, Object?> map, int indent) {
  final pad = ' ' * indent;
  for (final e in map.entries) {
    final value = e.value;
    if (_isBlock(value)) {
      out.writeln('$pad${e.key}:');
      _writeBlock(out, value, indent + 2);
    } else {
      out.writeln('$pad${e.key}: ${_scalar(value)}');
    }
  }
}

void _writeList(StringBuffer out, List<Object?> list, int indent) {
  final pad = ' ' * indent;
  for (final value in list) {
    if (value is Map<String, Object?> && value.isNotEmpty) {
      // The first entry shares the dash's line; the rest align under it.
      final lines = StringBuffer();
      _writeMap(lines, value, indent + 2);
      final text = lines.toString();
      out.write('$pad- ${text.substring(indent + 2)}');
    } else if (value is List<Object?> && value.isNotEmpty) {
      out.writeln('$pad-');
      _writeList(out, value, indent + 2);
    } else {
      out.writeln('$pad- ${_scalar(value)}');
    }
  }
}

bool _isBlock(Object? value) =>
    (value is Map && value.isNotEmpty) || (value is List && value.isNotEmpty);

void _writeBlock(StringBuffer out, Object? value, int indent) {
  if (value is Map<String, Object?>) {
    _writeMap(out, value, indent);
  } else {
    _writeList(out, value! as List<Object?>, indent);
  }
}

String _scalar(Object? value) => switch (value) {
  null => 'null',
  final String s => jsonEncode(s),
  final bool b => '$b',
  final int i => '$i',
  final List<Object?> l when l.isEmpty => '[]',
  final Map<Object?, Object?> m when m.isEmpty => '{}',
  _ => throw ArgumentError.value(value, 'value', 'not an IR scalar'),
};

/// Every `*.ir.yaml` document in [dir], in file-name order.
///
/// Throws [IrSpecsException] when [dir] does not exist, holds no IR document,
/// or holds one that does not read.
List<IrDocument> readIrFolder(String dir) {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    throw IrSpecsException('IR folder not found: $dir');
  }
  final files =
      folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.ir.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) throw IrSpecsException('No *.ir.yaml in $dir.');
  return [
    for (final f in files) readIrYaml(f.readAsStringSync(), source: f.path),
  ];
}
