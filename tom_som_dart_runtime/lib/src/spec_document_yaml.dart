/// Generic YAML codec for the native `*.docspecs.yaml` document format (§15.1,
/// step 4).
///
/// This is the review-free, Flutter-free half of the format: a header comment,
/// `version:` (the on-disk format version), an optional `modelVersion:` stamp
/// (the authoring object-model `major.minor` the content conforms to), then the
/// `document:` pass — the live object-model values, sorted by full section path.
///
/// **All text values are written as literal block scalars (`|2-`)** so multi-
/// line content round-trips verbatim and the file reads cleanly without an
/// editor (IO2/N4). The emitter is **self-verifying**: it re-parses each block
/// it produces and falls back to a JSON-quoted scalar (always valid YAML,
/// guaranteed to round-trip) for any value a clean block can't represent —
/// values with two or more trailing newlines, or anything the parser doesn't
/// reproduce exactly. Because a [SpecDocument] keys every value by a globally-
/// unique section path with no projection copies, each section is emitted
/// exactly once (no duplicate subtrees).
///
/// The full editor format adds a second `review:` pass (structural review state)
/// composed on top by the editor's `DocSpecsFile`, which reuses the public
/// scalar helpers here ([writeScalar] / [yamlKey]) so the two passes stay
/// byte-compatible. [decode] returns that pass untouched as a raw map so the
/// editor can map it onto its Flutter-coupled review types.
library;

import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'spec_document.dart';

/// The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
/// [SpecDocument.loadJson]-shaped map, the `review:` pass as a raw map (the
/// runtime is review-agnostic), and the optional authoring model-version stamp.
class SpecYamlContents {
  SpecYamlContents({
    required this.document,
    required this.review,
    this.modelVersion,
  });

  /// The `document:` pass, ready for [SpecDocument.loadJson].
  final Map<dynamic, dynamic> document;

  /// The `review:` pass exactly as parsed (empty when absent). The runtime does
  /// not interpret it; the editor maps it onto its own review entries.
  final Map<dynamic, dynamic> review;

  /// The authoring object-model version (`major.minor`) this document was last
  /// written against, or `null` for an unstamped/hand-written file. Distinct
  /// from [SpecDocumentYaml.formatVersion] (the on-disk format version).
  final String? modelVersion;
}

/// Codec for the `document:` pass of the native `*.docspecs.yaml` format.
class SpecDocumentYaml {
  /// The on-disk format version (independent of the model-version stamp).
  static const int formatVersion = 1;

  // --- Encode -------------------------------------------------------------

  /// Serializes [document] to a header + `version:` (+ `modelVersion:`) +
  /// `document:` pass. The full editor file appends a `review:` pass via the
  /// shared [writeScalar] / [yamlKey] helpers; the runtime's own round-trip is
  /// document-only.
  static String encode({required SpecDocument document, String? modelVersion}) {
    final b = StringBuffer();
    writeHeader(b, modelVersion: modelVersion);
    writeDocumentPass(b, document.toJson());
    return b.toString();
  }

  /// Writes the file header comment + `version:` line, and the optional
  /// `modelVersion:` stamp when [modelVersion] is non-empty.
  static void writeHeader(StringBuffer b, {String? modelVersion}) {
    b
      ..writeln('# TomSpecs document (*.docspecs.yaml).')
      ..writeln('# `document:` holds the object-model values, sorted by section '
          'id; text')
      ..writeln('# values use block scalars so multi-line content round-trips '
          'verbatim (§15.1).')
      ..writeln('version: $formatVersion');
    if (modelVersion != null && modelVersion.isNotEmpty) {
      b.writeln('modelVersion: ${jsonEncode(modelVersion)}');
    }
  }

  /// Writes the `document:` pass from a [SpecDocument.toJson]-shaped [doc].
  static void writeDocumentPass(StringBuffer b, Map<String, Object?> doc) {
    final content = doc['content'];
    final forms = doc['forms'];
    final lists = doc['lists'];
    if (content == null && forms == null && lists == null) {
      b.writeln('document: {}');
      return;
    }
    b.writeln('document:');

    if (content is Map && content.isNotEmpty) {
      b.writeln('  content:');
      for (final k in sortedStringKeys(content)) {
        writeScalar(b, 4, k, '${content[k]}');
      }
    }

    if (forms is Map && forms.isNotEmpty) {
      b.writeln('  forms:');
      for (final k in sortedStringKeys(forms)) {
        final fields = forms[k];
        if (fields is! Map || fields.isEmpty) continue;
        b.writeln('    ${yamlKey(k)}:');
        for (final f in sortedStringKeys(fields)) {
          writeScalar(b, 6, f, '${fields[f]}');
        }
      }
    }

    if (lists is Map && lists.isNotEmpty) {
      b.writeln('  lists:');
      for (final k in sortedStringKeys(lists)) {
        final spec = lists[k];
        if (spec is! Map) continue;
        b.writeln('    ${yamlKey(k)}:');
        b.writeln('      seq: ${spec['seq'] ?? 0}');
        final items = spec['items'];
        if (items is List && items.isNotEmpty) {
          b.writeln('      items:');
          for (final it in items) {
            b.writeln('        - ${yamlKey('$it')}');
          }
        } else {
          b.writeln('      items: []');
        }
      }
    }
  }

  // --- Shared scalar machinery (public for the editor's review writer) -----

  /// Writes `<indent><key>: <scalar>` where the scalar is a self-verified block
  /// scalar (or a JSON-quoted fallback). Block body lines, which the builder
  /// emits at a relative indent of 2, are re-indented to [keyIndent] + 2.
  static void writeScalar(
      StringBuffer b, int keyIndent, String key, String value) {
    final pad = ' ' * keyIndent;
    final repr = _scalar(value);
    final lines = repr.split('\n');
    b.writeln('$pad${yamlKey(key)}: ${lines.first}');
    for (final line in lines.skip(1)) {
      if (line.isEmpty) {
        b.writeln('');
      } else {
        b.writeln('$pad$line');
      }
    }
  }

  /// A safely-quoted mapping key. JSON strings are valid YAML flow scalars, so
  /// this both quotes and escapes any path/field name unambiguously.
  static String yamlKey(String key) => jsonEncode(key);

  /// The string keys of [map], sorted, so the file diffs/merges cleanly.
  static List<String> sortedStringKeys(Map map) =>
      map.keys.map((k) => '$k').toList()..sort();

  /// The scalar representation of [value]: a literal block at relative indent 2
  /// when that round-trips, else a JSON-quoted scalar.
  static String _scalar(String value) {
    final block = _literalBlock(value);
    if (block != null && _roundTrips(block, value)) return block;
    return jsonEncode(value);
  }

  /// Builds a literal block scalar (`|2<chomp>`) with body at relative indent
  /// 2, or `null` when chomping can't reproduce the value's trailing newlines
  /// (two or more) — those fall back to JSON quoting.
  static String? _literalBlock(String value) {
    final trailing = _trailingNewlines(value);
    final String chomp;
    final String core;
    if (trailing == 0) {
      chomp = '-';
      core = value;
    } else if (trailing == 1) {
      chomp = '';
      core = value.substring(0, value.length - 1);
    } else {
      return null;
    }
    final sb = StringBuffer('|2$chomp');
    for (final line in core.split('\n')) {
      sb.write('\n');
      if (line.isNotEmpty) sb.write('  $line');
    }
    return sb.toString();
  }

  /// Whether re-parsing `_v: <block>` yields exactly [value] (the emitter's
  /// correctness guard).
  static bool _roundTrips(String block, String value) {
    try {
      final parsed = loadYaml('_v: $block\n');
      return parsed is Map && parsed['_v'] == value;
    } catch (_) {
      return false;
    }
  }

  static int _trailingNewlines(String value) {
    var n = 0;
    var i = value.length;
    while (i > 0 && value.codeUnitAt(i - 1) == 0x0a) {
      n++;
      i--;
    }
    return n;
  }

  // --- Decode -------------------------------------------------------------

  /// Parses a `*.docspecs.yaml` document into its passes. A missing pass decodes
  /// as empty rather than failing, so a partial/hand-written file still loads
  /// what it has.
  static SpecYamlContents decode(String yaml) {
    final root = yaml.trim().isEmpty ? null : loadYaml(yaml);
    final doc = (root is Map ? root['document'] : null);
    final rev = (root is Map ? root['review'] : null);
    final stamp = (root is Map ? root['modelVersion'] : null);

    return SpecYamlContents(
      document: doc is Map ? doc : const {},
      review: rev is Map ? rev : const {},
      modelVersion:
          (stamp != null && '$stamp'.isNotEmpty) ? '$stamp' : null,
    );
  }
}
