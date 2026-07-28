/// Generic YAML codec for the native `*.docspecs.yaml` document format —
/// **hierarchical format v2** (SOM §12).
///
/// One nested YAML tree whose indentation mirrors the document structure: every
/// model node becomes a mapping key (`<section-id> <member-name>`, SOM §12.2).
/// The section id is the field-level `@SectionId` when present; for a
/// section/complex node whose field carries none, it is the target **class**'s
/// `@SectionId` (the id its generated schema type is keyed by — the same "field
/// id, else target-class id" fallback the markdown codec's headings use).
/// Sections nest their children, list items appear under their container keyed
/// by their stored section id (or an anonymous positional `<member>-<n>` key),
/// a node's own body text uses the literal key `content`, a node's **stored
/// headline** (YRD3) uses the literal key `headline`, a node's **stored
/// codeSpec** (csmb1 — the codespecs_mapping.md §9.2 DocSpecs→CodeSpecs forward
/// link, a comma-joined list of code locations) uses the literal key
/// `codeSpec`, and form fields use their bare field names (no class fallback
/// for content/form/list/scalar/enum keys). A scalar-valued node
/// (content/scalar/enum leaf or scalar list item) that carries a stored
/// headline and/or codeSpec is emitted as a `{headline: …, codeSpec: …,
/// content: …}` mapping instead of a direct scalar. The former flat two-level
/// path-map format (`document: {content: {"A/b": …}}`) is **retired**; readers
/// reject `version: 1` files with a clear error (no compatibility path).
///
/// Text values are written as literal block scalars (`|2-`), with the SOM §12.4
/// escaping rules: the emitter is **self-verifying** (it re-parses each
/// scalar it produces and falls back to a double-quoted JSON-escaped flow
/// scalar when the parse differs), and **runs of 2+ consecutive empty lines are
/// collapsed to one before serialization** (a deliberate, documented lossy
/// normalization — round-trip guarantees are stated "modulo empty-line dedup").
/// Non-text values (`int`/`double`/`bool`, enum member names) are plain scalars
/// when they self-verify (SOM §12.5).
///
/// Both [SpecDocumentYaml.encode] and [SpecDocumentYaml.decode] walk the
/// [SomMetaTree] of the document root: the file carries **no paths** — the
/// runtime reconstructs them by matching keys against the metadata tree, and
/// a key that matches nothing at its position is a structured load error
/// ([SpecYamlFormatException]; no silent skips). Symmetrically, [encode]
/// throws when the document holds values the tree cannot place (nothing is
/// silently dropped).
///
/// The optional `review:` pass stays opaque to the runtime ([decode] returns
/// it as a raw map for the editor to interpret).
library;

import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'spec_document.dart';
import 'spec_meta.dart';
import 'spec_paths.dart';

/// A structural error in a `*.docspecs.yaml` file: wrong/unsupported format
/// version, a key that does not match the metadata tree at its position, a
/// malformed value shape, or (on encode) document values the tree cannot
/// place.
class SpecYamlFormatException implements Exception {
  /// What went wrong, naming the offending path/key where applicable.
  final String message;

  SpecYamlFormatException(this.message);

  @override
  String toString() => 'SpecYamlFormatException: $message';
}

/// The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
/// populated [SpecDocument], the `review:` pass as a raw map (the runtime is
/// review-agnostic), and the optional authoring model-version stamp.
class SpecYamlContents {
  SpecYamlContents({
    required this.document,
    required this.review,
    this.modelVersion,
  });

  /// The `document:` pass, loaded into a live document (its
  /// [SpecDocument.modelVersion] is already set from the file stamp).
  final SpecDocument document;

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
  /// Version 2 is the hierarchical tree format; version-1 flat files are
  /// rejected on read.
  static const int formatVersion = 2;

  // --- Encode -------------------------------------------------------------

  /// Serializes [document] to a header + `version:` (+ `modelVersion:`) +
  /// hierarchical `document:` pass, walking [tree] (the metadata tree of the
  /// document's root).
  ///
  /// Sibling order is the tree's child order (`@SerializationOrder`), list
  /// items follow their stored sequence; emission is sparse (only populated
  /// subtrees appear). Throws [SpecYamlFormatException] when the document
  /// holds values [tree] cannot place — nothing is silently dropped.
  static String encode({
    required SpecDocument document,
    required SomMetaTree tree,
    String? modelVersion,
  }) {
    final b = StringBuffer();
    writeHeader(b, modelVersion: modelVersion);
    _Encoder(document, tree).writeDocumentPass(b);
    return b.toString();
  }

  /// Writes the file header comment + `version:` line, and the optional
  /// `modelVersion:` stamp when [modelVersion] is non-empty.
  static void writeHeader(StringBuffer b, {String? modelVersion}) {
    b
      ..writeln(
          '# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.')
      ..writeln('version: $formatVersion');
    if (modelVersion != null && modelVersion.isNotEmpty) {
      b.writeln('modelVersion: ${jsonEncode(modelVersion)}');
    }
  }

  /// The mapping key a metadata node writes (SOM §12.2): its effective section
  /// id, one space, then the exact member name (class name on the document
  /// root); just the name when the node carries no id.
  ///
  /// The id is the field-level [SomMetaNode.sectionId] when present; for a
  /// section/complex node whose field carries none, the target **class**'s id
  /// ([SomMetaNode.classSectionId]) — the id its generated schema type is keyed by.
  /// This mirrors the markdown codec's heading rule exactly. Content, scalar,
  /// enum, form and list keys keep only their field-level id (no class
  /// fallback), and the path [SomMetaNode.segment] is unaffected in every case.
  static String nodeKey(SomMetaNode node) {
    final name = node.memberName ?? node.className;
    final id = node.sectionId ??
        ((node.kind == SomMetaKind.section || node.kind == SomMetaKind.complex)
            ? node.classSectionId
            : null);
    return id == null ? name : '$id $name';
  }

  // --- Shared scalar machinery (public for the editor's review writer) -----

  /// Writes `<indent><key>: <scalar>` where the scalar is a self-verified
  /// block scalar (or a JSON-quoted fallback). Block body lines, which the
  /// builder emits at a relative indent of 2, are re-indented past [keyIndent].
  static void writeScalar(
      StringBuffer b, int keyIndent, String key, String value) {
    _writeRendered(b, keyIndent, yamlKey(key), _scalar(value));
  }

  static void _writeRendered(
      StringBuffer b, int keyIndent, String renderedKey, String repr) {
    final pad = ' ' * keyIndent;
    final lines = repr.split('\n');
    b.writeln('$pad$renderedKey: ${lines.first}');
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

  /// A plain key when the key is YAML-safe by construction (section ids,
  /// member names, `<id> <name>` pairs), else a JSON-quoted one.
  static String plainKey(String key) =>
      _plainKeyPattern.hasMatch(key) ? key : yamlKey(key);

  static final RegExp _plainKeyPattern =
      RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$');

  /// Collapses runs of two or more consecutive empty lines to a single empty
  /// line (SOM §12.4 — the deliberate lossy normalization applied to every
  /// text value before serialization).
  static String dedupEmptyLines(String value) =>
      value.replaceAll(_blankRuns, '\n\n');

  static final RegExp _blankRuns = RegExp(r'\n{3,}');

  /// The scalar representation of [value]: a literal block at relative indent 2
  /// when that round-trips, else a JSON-quoted scalar.
  static String _scalar(String value) {
    final block = _literalBlock(value);
    if (block != null && _roundTrips(block, value)) return block;
    return jsonEncode(value);
  }

  /// A plain one-line scalar for a non-text value (int/double/bool/enum member
  /// name, SOM §12.5) when writing it plainly re-parses to exactly [value] (string
  /// compare, matching the document's string-typed stores); `null` otherwise.
  ///
  /// The self-verification uses package:yaml, which is a **YAML 1.2** parser
  /// (only `true`/`false` are booleans, no sexagesimal numbers). A value whose
  /// text is a YAML **1.1** special — a 1.1-only boolean word (`yes`/`no`/
  /// `on`/`off`/`y`/`n` and case variants) or a sexagesimal int/float — parses
  /// as a plain string here yet would be mis-read as a bool/number by a 1.1
  /// parser (e.g. PyYAML). Emitting it plainly would break cross-language
  /// round-trips, so such values are forced to the quoted/block path
  /// (returns `null`). Reference rule for SOM §12.5; mirrored by every port.
  static String? _plainScalar(String value) {
    if (value.isEmpty || value.contains('\n')) return null;
    if (_isYaml11Special(value)) return null;
    try {
      final parsed = loadYaml('_v: $value\n');
      if (parsed is! Map) return null;
      final v = parsed['_v'];
      if (v == null || v is Map || v is List) return null;
      return '$v' == value ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// Whether [value]'s text is a YAML **1.1** special that a 1.1 parser would
  /// resolve to a non-string (so it must never be emitted as a plain scalar,
  /// SOM §12.5). Covers the 1.1-only boolean words (`y`/`yes`/`n`/`no`/`on`/
  /// `off` and their case variants — lowercase `true`/`false` are consistent
  /// across 1.1/1.2 and handled by the normal self-verify) and sexagesimal
  /// int/float literals.
  static bool _isYaml11Special(String value) =>
      _yaml11Bool.hasMatch(value) ||
      _yaml11SexagesimalInt.hasMatch(value) ||
      _yaml11SexagesimalFloat.hasMatch(value);

  /// YAML 1.1 boolean words that YAML 1.2 treats as plain strings.
  static final RegExp _yaml11Bool =
      RegExp(r'^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$');

  /// YAML 1.1 sexagesimal integer (e.g. `1:30`, `-12:00:00`).
  static final RegExp _yaml11SexagesimalInt =
      RegExp(r'^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$');

  /// YAML 1.1 sexagesimal float (e.g. `1:30.5`).
  static final RegExp _yaml11SexagesimalFloat =
      RegExp(r'^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$');

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

  /// Parses a `*.docspecs.yaml` file into its passes, matching every
  /// `document:` key against [tree].
  ///
  /// Throws [SpecYamlFormatException] for a missing/unsupported `version:`
  /// (version 1 is rejected explicitly — the flat format has no compatibility
  /// path), for any key the metadata tree cannot place, and for malformed
  /// value shapes. A missing/empty `document:` pass decodes as an empty
  /// document.
  static SpecYamlContents decode(String yaml, SomMetaTree tree) {
    final root = yaml.trim().isEmpty ? null : loadYaml(yaml);
    if (root is! Map) {
      throw SpecYamlFormatException(
          'not a *.docspecs.yaml mapping (expected version/document keys)');
    }
    final version = root['version'];
    if ('$version' != '$formatVersion') {
      throw SpecYamlFormatException(version == null
          ? 'missing `version:` (expected version: $formatVersion)'
          : '$version' == '1'
              ? 'format version 1 (flat path-map) is no longer supported; '
                  're-save the document in the hierarchical v2 format'
              : 'unsupported format version `$version` '
                  '(expected $formatVersion)');
    }

    final stampRaw = root['modelVersion'];
    final stamp =
        (stampRaw != null && '$stampRaw'.isNotEmpty) ? '$stampRaw' : null;
    final rev = root['review'];

    final document = SpecDocument()..modelVersion = stamp;
    final docPass = root['document'];
    if (docPass != null && docPass is! Map) {
      throw SpecYamlFormatException('`document:` must be a mapping');
    }
    if (docPass is Map && docPass.isNotEmpty) {
      final rootKey = nodeKey(tree.root);
      if (docPass.length != 1 || '${docPass.keys.first}' != rootKey) {
        throw SpecYamlFormatException(
            'expected the single document root key `$rootKey`, '
            'found: ${docPass.keys.map((k) => '`$k`').join(', ')}');
      }
      final body = docPass.values.first;
      if (body != null) {
        if (body is! Map) {
          throw SpecYamlFormatException(
              'root `$rootKey` must hold a mapping, not a scalar');
        }
        _Decoder(document, tree)
            .loadMapping(tree.root, tree.root.segment, body);
      }
    }

    return SpecYamlContents(
      document: document,
      review: rev is Map ? rev : const {},
      modelVersion: stamp,
    );
  }
}

// --- Encoder ----------------------------------------------------------------

/// One encode run: walks the metadata tree, consuming values from snapshots of
/// the document's stores so anything left unconsumed at the end is a
/// structured error (nothing is silently dropped).
class _Encoder {
  final SpecDocument doc;
  final SomMetaTree tree;
  final Map<String, String> _content;
  final Map<String, Map<String, String>> _forms;
  final Set<String> _lists;
  final Map<String, String> _headlines;
  final Map<String, String> _codeSpecs;

  _Encoder(this.doc, this.tree)
      : _content = {for (final p in doc.contentPaths) p: doc.content(p)!},
        _forms = {
          for (final p in doc.formPaths)
            p: {for (final f in doc.formFieldNames(p)) f: doc.formField(p, f)!},
        },
        _lists = doc.listPaths.toSet(),
        _headlines = {
          for (final p in doc.headlinePaths) p: doc.headline(p)!,
        },
        _codeSpecs = {
          for (final p in doc.codeSpecPaths) p: doc.codeSpec(p)!,
        };

  void writeDocumentPass(StringBuffer b) {
    final root = tree.root;
    final body = _mappingBody(root, root.segment, 4);
    _assertNothingLeft();
    if (body.isEmpty) {
      b.writeln('document: {}');
      return;
    }
    b
      ..writeln('document:')
      ..writeln('  ${SpecDocumentYaml.plainKey(SpecDocumentYaml.nodeKey(root))}:')
      ..write(body);
  }

  /// Renders the mapping body of [node] at [path] (root, a collapsed
  /// section/complex field, or a list item's element), one line per populated
  /// entry at [indent]. Empty when nothing under the node is populated.
  String _mappingBody(SomMetaNode node, String path, int indent) {
    final b = StringBuffer();

    // The node's own stored headline — the literal `headline` key (YRD3).
    final ownHeadline = _headlines.remove(path);
    if (ownHeadline != null) {
      if (node.children.any((c) => SpecDocumentYaml.nodeKey(c) == 'headline')) {
        throw SpecYamlFormatException(
            'cannot emit the stored headline at `$path`: a child of '
            '${node.debugName} also serializes as key `headline`');
      }
      _writeText(b, indent, 'headline', ownHeadline);
    }

    // The node's own codeSpec mapping — the literal `codeSpec` key
    // (codespecs_mapping.md §9.2).
    final ownCodeSpec = _codeSpecs.remove(path);
    if (ownCodeSpec != null) {
      if (node.children.any((c) => SpecDocumentYaml.nodeKey(c) == 'codeSpec')) {
        throw SpecYamlFormatException(
            'cannot emit the stored codeSpec at `$path`: a child of '
            '${node.debugName} also serializes as key `codeSpec`');
      }
      _writeText(b, indent, 'codeSpec', ownCodeSpec);
    }

    // The node's own body text — the literal `content` key (SOM §12.2).
    final own = _content.remove(path);
    if (own != null) {
      if (node.children.any((c) => SpecDocumentYaml.nodeKey(c) == 'content')) {
        throw SpecYamlFormatException(
            'cannot emit body text at `$path`: a child of '
            '${node.debugName} also serializes as key `content`');
      }
      _writeText(b, indent, 'content', own);
    }

    for (final child in node.children) {
      final childPath = specPathJoin(path, child.segment);
      final key = SpecDocumentYaml.nodeKey(child);
      switch (child.kind) {
        case SomMetaKind.content:
          final v = _content.remove(childPath);
          final h = _headlines.remove(childPath);
          final cs = _codeSpecs.remove(childPath);
          if (h != null || cs != null) {
            _writeScalarWithMeta(b, indent, key, h, cs, v, text: true);
          } else if (v != null) {
            _writeText(b, indent, key, v);
          }
        case SomMetaKind.scalar:
        case SomMetaKind.enumValue:
          final v = _content.remove(childPath);
          final h = _headlines.remove(childPath);
          final cs = _codeSpecs.remove(childPath);
          if (h != null || cs != null) {
            _writeScalarWithMeta(b, indent, key, h, cs, v, text: false);
          } else if (v != null) {
            _writeValue(b, indent, key, v);
          }
        case SomMetaKind.form:
          _writeForm(b, indent, key, child, childPath);
        case SomMetaKind.section:
        case SomMetaKind.complex:
          final sub = _mappingBody(child, childPath, indent + 2);
          if (sub.isNotEmpty) {
            b.writeln('${' ' * indent}${SpecDocumentYaml.plainKey(key)}:');
            b.write(sub);
          }
        case SomMetaKind.list:
          _writeList(b, indent, key, child, childPath);
      }
    }
    return b.toString();
  }

  /// Emits a scalar-valued node (content/scalar/enum leaf) that carries a
  /// stored headline and/or a codeSpec mapping as a `{headline?: …, codeSpec?:
  /// …, content?: …}` mapping (YRD3 + codespecs_mapping.md §9.2). At least one
  /// of [headline]/[codeSpec] is non-null at every call site.
  void _writeScalarWithMeta(StringBuffer b, int indent, String key,
      String? headline, String? codeSpec, String? value,
      {required bool text}) {
    b.writeln('${' ' * indent}${SpecDocumentYaml.plainKey(key)}:');
    if (headline != null) _writeText(b, indent + 2, 'headline', headline);
    if (codeSpec != null) _writeText(b, indent + 2, 'codeSpec', codeSpec);
    if (value != null) {
      if (text) {
        _writeText(b, indent + 2, 'content', value);
      } else {
        _writeValue(b, indent + 2, 'content', value);
      }
    }
  }

  void _writeForm(StringBuffer b, int indent, String key, SomMetaNode node,
      String path) {
    final fields = _forms.remove(path) ?? const <String, String>{};
    final headline = _headlines.remove(path);
    final codeSpec = _codeSpecs.remove(path);
    if (fields.isEmpty && headline == null && codeSpec == null) return;
    final meta = node.form ?? const SomFormMeta(fields: []);
    for (final name in fields.keys) {
      final field = meta.fieldNamed(name);
      if (field == null) {
        throw SpecYamlFormatException(
            'form `$path` holds a field `$name` unknown to the model');
      }
    }
    if (headline != null && meta.fieldNamed('headline') != null) {
      throw SpecYamlFormatException(
          'cannot emit the stored headline at `$path`: the form declares a '
          'field literally named `headline`');
    }
    if (codeSpec != null && meta.fieldNamed('codeSpec') != null) {
      throw SpecYamlFormatException(
          'cannot emit the stored codeSpec at `$path`: the form declares a '
          'field literally named `codeSpec`');
    }
    b.writeln('${' ' * indent}${SpecDocumentYaml.plainKey(key)}:');
    if (headline != null) _writeText(b, indent + 2, 'headline', headline);
    if (codeSpec != null) _writeText(b, indent + 2, 'codeSpec', codeSpec);
    for (final f in meta.fields) {
      final v = fields[f.name];
      if (v == null) continue;
      if (_isNumericOrBool(f.typeName)) {
        _writeValue(b, indent + 2, f.name, v);
      } else {
        _writeText(b, indent + 2, f.name, v);
      }
    }
  }

  void _writeList(StringBuffer b, int indent, String key, SomMetaNode node,
      String path) {
    _lists.remove(path);
    final headline = _headlines.remove(path);
    final codeSpec = _codeSpecs.remove(path);
    final items = doc.listItems(path);
    if (items.isEmpty && headline == null && codeSpec == null) return;
    b.writeln('${' ' * indent}${SpecDocumentYaml.plainKey(key)}:');
    if (headline != null) _writeText(b, indent + 2, 'headline', headline);
    if (codeSpec != null) _writeText(b, indent + 2, 'codeSpec', codeSpec);
    final used = <String>{'headline', 'codeSpec'};
    var pos = 0;
    for (final itemPath in items) {
      pos++;
      final storedId = doc.itemSectionId(itemPath);
      var itemKey = storedId ?? '${node.memberName}-$pos';
      if (storedId != null) {
        if (!used.add(itemKey)) {
          throw SpecYamlFormatException(
              'duplicate list item key `$itemKey` at `$path`');
        }
      } else {
        var bump = pos;
        while (!used.add(itemKey)) {
          bump++;
          itemKey = '${node.memberName}-$bump';
        }
      }
      final element = node.elementNode;
      if (element == null) {
        // Scalar list: the item is a direct value — unless it carries a stored
        // headline and/or codeSpec, in which case it becomes a `{headline?: …,
        // codeSpec?: …, content: …}` mapping (YRD3 + codespecs_mapping.md
        // §9.2).
        final v = _content.remove(itemPath);
        final ih = _headlines.remove(itemPath);
        final ics = _codeSpecs.remove(itemPath);
        if (ih != null || ics != null) {
          _writeScalarWithMeta(b, indent + 2, itemKey, ih, ics, v, text: false);
        } else {
          _writeValue(b, indent + 2, itemKey, v ?? '');
        }
      } else {
        final sub = _mappingBody(element, itemPath, indent + 4);
        if (sub.isEmpty) {
          b.writeln('${' ' * (indent + 2)}'
              '${SpecDocumentYaml.plainKey(itemKey)}: {}');
        } else {
          b.writeln(
              '${' ' * (indent + 2)}${SpecDocumentYaml.plainKey(itemKey)}:');
          b.write(sub);
        }
      }
    }
  }

  /// Text value: empty-line dedup, then a self-verified block scalar (or the
  /// JSON-quoted fallback).
  void _writeText(StringBuffer b, int indent, String key, String value) {
    SpecDocumentYaml._writeRendered(
        b,
        indent,
        SpecDocumentYaml.plainKey(key),
        SpecDocumentYaml._scalar(SpecDocumentYaml.dedupEmptyLines(value)));
  }

  /// Non-text value (SOM §12.5): plain when it self-verifies, else the text path.
  void _writeValue(StringBuffer b, int indent, String key, String value) {
    final plain = SpecDocumentYaml._plainScalar(value);
    if (plain != null) {
      b.writeln('${' ' * indent}${SpecDocumentYaml.plainKey(key)}: $plain');
    } else {
      _writeText(b, indent, key, value);
    }
  }

  static bool _isNumericOrBool(String typeName) =>
      typeName == 'int' ||
      typeName == 'double' ||
      typeName == 'num' ||
      typeName == 'bool';

  void _assertNothingLeft() {
    final leftovers = <String>[
      ..._content.keys.map((p) => 'content at `$p`'),
      ..._forms.keys.map((p) => 'form values at `$p`'),
      ..._lists.map((p) => 'list items at `$p`'),
      ..._headlines.keys.map((p) => 'headline at `$p`'),
      ..._codeSpecs.keys.map((p) => 'codeSpec at `$p`'),
    ]..sort();
    if (leftovers.isNotEmpty) {
      throw SpecYamlFormatException(
          'document holds values the metadata tree cannot place: '
          '${leftovers.join('; ')}');
    }
  }
}

// --- Decoder ----------------------------------------------------------------

/// One decode run: walks a parsed YAML mapping alongside the metadata tree and
/// populates [doc]. Any key that matches nothing at its position throws.
class _Decoder {
  final SpecDocument doc;
  final SomMetaTree tree;

  _Decoder(this.doc, this.tree);

  void loadMapping(SomMetaNode node, String path, Map body) {
    body.forEach((rawKey, value) {
      final key = '$rawKey';
      final child = _childByKey(node, key);
      if (child != null) {
        _loadChild(child, specPathJoin(path, child.segment), key, value);
        return;
      }
      if (key == 'content') {
        doc.setContent(path, _scalarOf(value, '$path/content'));
        return;
      }
      if (key == 'headline') {
        doc.setHeadline(path, _scalarOf(value, '$path (headline)'));
        return;
      }
      if (key == 'codeSpec') {
        doc.setCodeSpec(path, _scalarOf(value, '$path (codeSpec)'));
        return;
      }
      throw SpecYamlFormatException(
          'key `$key` under `$path` matches no member of ${node.debugName} '
          '(expected one of: ${_expectedKeys(node).join(', ')})');
    });
  }

  SomMetaNode? _childByKey(SomMetaNode node, String key) {
    for (final c in node.children) {
      if (SpecDocumentYaml.nodeKey(c) == key) return c;
    }
    return null;
  }

  Iterable<String> _expectedKeys(SomMetaNode node) => [
        for (final c in node.children) '`${SpecDocumentYaml.nodeKey(c)}`',
        '`content`',
        '`headline`',
        '`codeSpec`',
      ];

  void _loadChild(SomMetaNode child, String path, String key, Object? value) {
    switch (child.kind) {
      case SomMetaKind.content:
      case SomMetaKind.scalar:
      case SomMetaKind.enumValue:
        if (value is Map) {
          // Headline-extended scalar node (YRD3): `{headline: …, content: …}`.
          _loadScalarWithMeta(path, key, value);
        } else {
          doc.setContent(path, _scalarOf(value, path));
        }
      case SomMetaKind.form:
        if (value is! Map) {
          throw SpecYamlFormatException(
              'form `$key` at `$path` must hold a field mapping');
        }
        final meta = child.form ?? const SomFormMeta(fields: []);
        value.forEach((f, v) {
          final name = '$f';
          final field = meta.fieldNamed(name);
          if (field == null) {
            if (name == 'headline') {
              doc.setHeadline(path, _scalarOf(v, '$path (headline)'));
              return;
            }
            if (name == 'codeSpec') {
              doc.setCodeSpec(path, _scalarOf(v, '$path (codeSpec)'));
              return;
            }
            throw SpecYamlFormatException(
                'form `$path` has no field `$name` in the model');
          }
          doc.setFormField(path, name, _scalarOf(v, '$path.$name'));
        });
      case SomMetaKind.section:
      case SomMetaKind.complex:
        if (value == null) return;
        if (value is! Map) {
          throw SpecYamlFormatException(
              'section `$key` at `$path` must hold a mapping, not a scalar');
        }
        loadMapping(child, path, value);
      case SomMetaKind.list:
        if (value == null) return;
        if (value is! Map) {
          throw SpecYamlFormatException(
              'list `$key` at `$path` must hold an item mapping');
        }
        _loadList(child, path, value);
    }
  }

  void _loadList(SomMetaNode node, String path, Map items) {
    final anonymous =
        RegExp('^${RegExp.escape(node.memberName ?? '')}-[0-9]+\$');
    items.forEach((rawKey, value) {
      final key = '$rawKey';
      if (key == 'headline') {
        // The list container's own stored headline (YRD3), not an item.
        doc.setHeadline(path, _scalarOf(value, '$path (headline)'));
        return;
      }
      if (key == 'codeSpec') {
        // The list container's own codeSpec mapping (codespecs_mapping.md
        // §9.2), not an item.
        doc.setCodeSpec(path, _scalarOf(value, '$path (codeSpec)'));
        return;
      }
      final itemPath = doc.addListItem(path,
          sectionId: anonymous.hasMatch(key) ? null : key);
      final element = node.elementNode;
      if (element == null) {
        // Scalar list item: the value is the item itself — or a
        // `{headline: …, content: …}` mapping when it carries a stored
        // headline (YRD3).
        if (value is Map) {
          _loadScalarWithMeta(itemPath, key, value);
          return;
        }
        if (value is List) {
          throw SpecYamlFormatException(
              'scalar list item `$key` at `$path` must hold a scalar');
        }
        if (value != null) doc.setContent(itemPath, '$value');
        return;
      }
      if (value == null) return;
      if (value is! Map) {
        throw SpecYamlFormatException(
            'list item `$key` at `$path` must hold a mapping '
            '(use `{}` for an empty item)');
      }
      loadMapping(element, itemPath, value);
    });
  }

  /// Loads a headline-/codeSpec-extended scalar node (YRD3 +
  /// codespecs_mapping.md §9.2): a mapping holding only the literal keys
  /// `headline`, `codeSpec` and `content`.
  void _loadScalarWithMeta(String path, String key, Map value) {
    value.forEach((k, v) {
      final name = '$k';
      if (name == 'headline') {
        doc.setHeadline(path, _scalarOf(v, '$path (headline)'));
      } else if (name == 'codeSpec') {
        doc.setCodeSpec(path, _scalarOf(v, '$path (codeSpec)'));
      } else if (name == 'content') {
        doc.setContent(path, _scalarOf(v, '$path/content'));
      } else {
        throw SpecYamlFormatException(
            'scalar node `$key` at `$path` may only hold '
            '`headline`/`codeSpec`/`content` keys when written as a mapping, '
            'found `$name`');
      }
    });
  }

  String _scalarOf(Object? value, String where) {
    if (value == null) return '';
    if (value is Map || value is List) {
      throw SpecYamlFormatException('expected a scalar value at `$where`');
    }
    return '$value';
  }
}
