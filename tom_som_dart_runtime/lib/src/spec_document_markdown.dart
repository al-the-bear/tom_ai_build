/// DocSpecs-conform Markdown codec for a TomSpecs document (DR1 §1).
///
/// The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
/// the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
/// section is one markdown heading whose machine-readable identity is the
/// DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
/// human-readable Title-Case member name. Content values are **normal markdown
/// text** under their heading (no fences, no anchors); `@Form` sections use the
/// DocSpecs plain-text `FieldName: value` format; list items are sub-headings
/// carrying the item's section id (stored id, else `<member>-<pos>`) directly
/// under the owning section — the list container gets no heading of its own.
///
/// Escaping (DR1 §1.3): a content line starting with `#` at column 0 is
/// emitted as `\#` (and a leading `\#`… run gains one more backslash), except
/// inside fenced code blocks, which shield their lines verbatim. Consecutive
/// blank lines are collapsed to one on emit; parse trims each value of
/// leading/trailing blank lines and does not re-collapse.
///
/// The codec is value-free of any UI: it reads from / resolves against a
/// [SpecModel] (through the [buildSomMetaTree] metadata tree) and a
/// [SpecDocument]. [parse] does **not** mutate the document — it returns staged
/// values keyed exactly like [SpecDocument.toJson] plus a rejection report; the
/// caller applies them. Anything that cannot be mapped — an unknown section id,
/// a child heading under a value leaf, orphaned text — is collected into
/// [SpecMarkdownResult.rejections] rather than dropped (DR1 §1.7).
library;

import 'spec_document.dart';
import 'spec_meta.dart';
import 'spec_meta_bridge.dart';
import 'spec_model.dart';

/// Why an imported Markdown block was rejected (DR1 §1.7 rejection protocol).
enum SpecMarkdownRejectReason {
  /// The heading's section id does not resolve against the schema tree at its
  /// nesting position.
  unknownSection,

  /// A structurally impossible combination — e.g. a child heading nested under
  /// a value-leaf (content/scalar/enum) section.
  kindMismatch,

  /// Body text with no owning value slot — e.g. prose inside a `@Form` section
  /// before the first `FieldName:` line.
  orphanContent,

  /// A value-leaf section heading with an empty body.
  missingValue,

  /// A heading line without a parseable `<!--[id]-->` headline comment.
  malformedHeading,
}

/// One rejected block in a Markdown import (DR1 §1.7). Reported, never silently
/// dropped: each carries the source [line], the offending [anchor] (section
/// path or id), the [reason], and a human-readable [message].
class SpecMarkdownRejection {
  SpecMarkdownRejection({
    required this.line,
    required this.reason,
    required this.message,
    this.anchor,
  });

  final int line;
  final SpecMarkdownRejectReason reason;
  final String message;
  final String? anchor;

  @override
  String toString() =>
      'line $line: ${reason.name}${anchor != null ? ' ($anchor)' : ''} — '
      '$message';
}

/// The outcome of parsing a Markdown document (DR1 §1.7): the staged values
/// plus every rejected block. The values are keyed exactly like
/// [SpecDocument.toJson] so a caller can merge them into a live document as a
/// full overwrite of the covered scope.
class SpecMarkdownResult {
  SpecMarkdownResult({
    required this.content,
    required this.forms,
    required this.lists,
    required this.rejections,
    required this.rootPrefixes,
  });

  /// Content/scalar/enum leaf values (and section body text): path → value.
  final Map<String, String> content;

  /// Form values: form path → (field name → value).
  final Map<String, Map<String, String>> forms;

  /// List membership: list path → `{seq, items, ids?}` (the
  /// [SpecDocument.toJson] shape), recovered from the item headings.
  final Map<String, Map<String, Object?>> lists;

  /// Every rejected block, in source order.
  final List<SpecMarkdownRejection> rejections;

  /// The root segment(s) the import covers (the first segment of each accepted
  /// path) — the scope a full-overwrite apply purges before writing.
  final Set<String> rootPrefixes;

  /// Whether the parse was clean (no rejections).
  bool get isClean => rejections.isEmpty;

  /// The number of leaf values successfully parsed (content + form fields).
  int get appliedCount =>
      content.length + forms.values.fold<int>(0, (a, m) => a + m.length);
}

/// Codec binding a [SpecModel] and a concrete [SpecDocument] to the DocSpecs
/// Markdown import/export format (DR1 §1).
class SpecDocumentMarkdown {
  SpecDocumentMarkdown(this.model, this.document);

  final SpecModel model;
  final SpecDocument document;

  /// Metadata trees per root type, built lazily (DR8's generated facades will
  /// hand these in directly; until then the bridge derives them).
  final Map<String, SomMetaTree> _trees = {};

  SomMetaTree _treeFor(String rootType) => _trees.putIfAbsent(
      rootType, () => buildSomMetaTree(model, rootType: rootType));

  // --- Naming helpers (DR1 §1.2 / §1.5) ------------------------------------

  /// `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
  /// `Demo Item`: a camel/Pascal-case identifier expanded into Title Case.
  static String titleCase(String name) {
    final words = <String>[];
    final b = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      final c = name[i];
      final isUpper = c.toUpperCase() == c && c.toLowerCase() != c;
      if (isUpper && b.isNotEmpty) {
        words.add(b.toString());
        b.clear();
      }
      b.write(c);
    }
    if (b.isNotEmpty) words.add(b.toString());
    return [
      for (final w in words)
        w.isEmpty ? w : w[0].toUpperCase() + w.substring(1),
    ].join(' ');
  }

  /// `Demo Document` → `demo-document`: the DocSpecs schema id of a
  /// `@Document` name (DR1 §1.1).
  static String kebabCase(String title) => title
      .trim()
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '')
      .toLowerCase();

  /// The item heading title stem: Title-Case element class name with a
  /// trailing `Entry` dropped (DR1 §1.5, normative).
  static String itemTitleStem(String elementClassName) {
    var stem = elementClassName;
    if (stem.length > 5 && stem.endsWith('Entry')) {
      stem = stem.substring(0, stem.length - 5);
    }
    return titleCase(stem);
  }

  /// The `FieldName` label written for a form field: the model field name with
  /// the first letter upper-cased (DR1 §1.4.1).
  static String formLabel(String fieldName) => fieldName.isEmpty
      ? fieldName
      : fieldName[0].toUpperCase() + fieldName.substring(1);

  // --- Export (DR1 §1.1–§1.6) ----------------------------------------------

  /// Renders the populated subtree of [root] as a DocSpecs-conform Markdown
  /// document. Throws [ArgumentError] when a content value contains an
  /// unterminated fenced code block (which would shield the remainder of the
  /// document from heading detection and break the round-trip).
  String exportRoot(SpecRoot root) {
    final tree = _treeFor(root.type);
    final node = tree.root;
    final b = StringBuffer();
    b.writeln('<!-- docspec: ${kebabCase(root.title)}/'
        '${model.modelVersionString} -->');
    final rootSeg = node.segment;
    _writeHeading(b, 1, rootSeg, root.title);
    _writeBody(b, document.content(rootSeg), rootSeg);
    _writeChildren(b, node, rootSeg, 2);
    return b.toString();
  }

  void _writeChildren(
      StringBuffer b, SomMetaNode node, String basePath, int depth) {
    for (final child in node.children) {
      if (child.recursive) continue;
      final path = '$basePath/${child.segment}';
      if (!document.hasValuesUnder(path)) continue;
      switch (child.kind) {
        case SomMetaKind.content:
        case SomMetaKind.scalar:
        case SomMetaKind.enumValue:
          final value = document.content(path);
          if (value == null) break;
          _writeHeading(b, depth, child.segment, _titleOf(child));
          _writeBody(b, value, path);
        case SomMetaKind.form:
          if (!_formHasValues(child, path)) break;
          _writeHeading(b, depth, child.segment, _titleOf(child));
          _writeForm(b, child, path);
        case SomMetaKind.section:
        case SomMetaKind.complex:
          _writeHeading(b, depth, child.segment, _titleOf(child));
          _writeBody(b, document.content(path), path);
          _writeChildren(b, child, path, depth + 1);
        case SomMetaKind.list:
          _writeListItems(b, child, path, depth);
      }
    }
  }

  /// Emits the items of list [node] as headings **at the owner's child level**
  /// — the container itself gets no heading (DR1 §1.2).
  void _writeListItems(
      StringBuffer b, SomMetaNode node, String listPath, int depth) {
    final items = document.listItems(listPath);
    final stem = itemTitleStem(node.elementNode?.className ?? node.typeName);
    for (var i = 0; i < items.length; i++) {
      final itemPath = items[i];
      final pos = i + 1;
      final id = document.itemSectionId(itemPath) ??
          '${node.memberName ?? node.segment}-$pos';
      _writeHeading(b, depth, id, '$stem $pos');
      final element = node.elementNode;
      if (element == null) {
        // Scalar list: the item's value is its body.
        _writeBody(b, document.content(itemPath) ?? '', itemPath);
      } else {
        _writeBody(b, document.content(itemPath), itemPath);
        if (!element.recursive) {
          _writeChildren(b, element, itemPath, depth + 1);
        }
      }
    }
  }

  bool _formHasValues(SomMetaNode node, String path) {
    for (final f in node.form?.fields ?? const <SomFormFieldMeta>[]) {
      if (document.formField(path, f.name) != null) return true;
    }
    return false;
  }

  void _writeForm(StringBuffer b, SomMetaNode node, String path) {
    for (final f in node.form?.fields ?? const <SomFormFieldMeta>[]) {
      final value = document.formField(path, f.name);
      if (value == null) continue;
      final lines = _prepareValue(value, path).split('\n');
      b.writeln('${formLabel(f.name)}: ${lines.first}');
      for (final line in lines.skip(1)) {
        // §1.4.3 generalised: any continuation line that could be mistaken
        // for a field-label line gains one leading space; parse strips it.
        b.writeln(_labelShaped.hasMatch(line) ? ' $line' : line);
      }
    }
    b.writeln();
  }

  /// `## <!--[ID]--> Title` at [depth], capped at markdown's 6 levels.
  static void _writeHeading(StringBuffer b, int depth, String id, String title) {
    final hashes = '#' * (depth > 6 ? 6 : depth);
    b.writeln('$hashes <!--[$id]--> $title');
    b.writeln();
  }

  /// Writes [value] as a section body followed by a blank line; no-op for
  /// null/blank values.
  void _writeBody(StringBuffer b, String? value, String path) {
    if (value == null) return;
    final prepared = _prepareValue(value, path);
    if (prepared.isEmpty) return;
    b.writeln(prepared);
    b.writeln();
  }

  /// Emit-side value normalisation (DR1 §1.3): collapse 2+ blank lines to one,
  /// trim leading/trailing blank lines, escape heading-like lines outside
  /// fences. Throws [ArgumentError] for an unterminated fence.
  String _prepareValue(String value, String path) {
    final collapsed = value
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'^\n+'), '')
        .replaceAll(RegExp(r'\n+$'), '');
    final fence = _FenceTracker();
    final out = <String>[];
    for (final line in collapsed.split('\n')) {
      if (fence.inFence) {
        out.add(line); // §1.3.4: fences shield their lines.
      } else if (_escapable.hasMatch(line)) {
        out.add('\\$line');
      } else {
        out.add(line);
      }
      fence.feed(line);
    }
    if (fence.inFence) {
      throw ArgumentError('content at "$path" contains an unterminated '
          'fenced code block; it cannot be represented in the DocSpecs '
          'markdown format');
    }
    return out.join('\n');
  }

  static String _titleOf(SomMetaNode node) =>
      titleCase(node.memberName ?? node.className);

  // A line the emitter must escape: an optional run of backslashes followed by
  // `#` at column 0 (the escape itself must survive the round-trip).
  static final RegExp _escapable = RegExp(r'^\\*#');

  // A line that would parse as a form-field label: `Word:` at column 0
  // (optionally already space-prefixed — each emit pass adds one more space).
  static final RegExp _labelShaped = RegExp(r'^ *[A-Za-z][A-Za-z0-9_]*:');

  // --- Import (DR1 §1.7) ----------------------------------------------------

  /// Parses [text] into staged values + a rejection report, **without**
  /// mutating the document. The caller applies the result as a full overwrite.
  SpecMarkdownResult parse(String text) {
    final p = _Parser(this);
    p.run(text.split('\n'));
    return SpecMarkdownResult(
      content: p.content,
      forms: p.forms,
      lists: p.listsJson(),
      rejections: p.rejections,
      rootPrefixes: p.rootPrefixes,
    );
  }

  // Shared with _Parser.
  static final RegExp headingLine = RegExp(r'^(#{1,6})\s+(.*)$');
  static final RegExp headlineComment =
      RegExp(r'^<!--\[([^\]]+)\]-->\s*(.*)$');
  static final RegExp docspecComment =
      RegExp(r'^<!--\s*docspec:.*-->\s*$');
}

/// Fence state machine (CommonMark-ish): a line whose first non-space run (up
/// to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
/// same-character run at least as long closes it.
class _FenceTracker {
  String? _char;
  int _len = 0;

  bool get inFence => _char != null;

  static final RegExp _open = RegExp(r'^ {0,3}(`{3,}|~{3,})');

  void feed(String line) {
    final m = _open.firstMatch(line);
    if (m == null) return;
    final run = m.group(1)!;
    if (_char == null) {
      _char = run[0];
      _len = run.length;
    } else if (run[0] == _char &&
        run.length >= _len &&
        line.trim() == run[0] * line.trim().length) {
      _char = null;
      _len = 0;
    }
  }
}

/// One open section during the parse: its heading level, resolved node (null
/// for an unresolvable/ignored section), path, and accumulated body lines.
class _Frame {
  _Frame({
    required this.level,
    required this.node,
    required this.path,
    required this.line,
    this.ignored = false,
  });

  final int level;
  final SomMetaNode? node;
  final String path;
  final int line;
  final bool ignored;
  final List<String> body = [];
}

/// Per-list bookkeeping while parsing: ordered item paths, stored ids, and the
/// highest item number handed out (drives both fresh numbers for stored-id
/// items and the resulting `seq`).
class _ListState {
  final List<String> items = [];
  final Map<String, String> ids = {};
  int maxN = 0;
}

class _Parser {
  _Parser(this.codec);

  final SpecDocumentMarkdown codec;

  final content = <String, String>{};
  final forms = <String, Map<String, String>>{};
  final lists = <String, _ListState>{};
  final rejections = <SpecMarkdownRejection>[];
  final rootPrefixes = <String>{};

  final List<_Frame> _stack = [];
  final _fence = _FenceTracker();

  void run(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final lineNo = i + 1;
      final trimmed = raw.trimRight();

      if (!_fence.inFence) {
        if (_stack.isEmpty &&
            SpecDocumentMarkdown.docspecComment.hasMatch(trimmed)) {
          continue; // §1.1 header — informational.
        }
        final h = SpecDocumentMarkdown.headingLine.firstMatch(trimmed);
        if (h != null) {
          _closeTo(h.group(1)!.length);
          _openHeading(h.group(1)!.length, h.group(2)!, lineNo);
          continue;
        }
      }
      if (_stack.isNotEmpty) {
        _stack.last.body.add(raw);
      } else if (trimmed.isNotEmpty) {
        rejections.add(SpecMarkdownRejection(
          line: lineNo,
          reason: SpecMarkdownRejectReason.orphanContent,
          message: 'text before the document root heading',
        ));
      }
      _fence.feed(raw);
    }
    _closeTo(1);
    if (_stack.isNotEmpty) _finalize(_stack.removeLast());
  }

  /// Pops (and finalizes) every frame at [level] or deeper.
  void _closeTo(int level) {
    while (_stack.isNotEmpty && _stack.last.level >= level) {
      _finalize(_stack.removeLast());
    }
  }

  void _openHeading(int level, String rest, int lineNo) {
    final m = SpecDocumentMarkdown.headlineComment.firstMatch(rest.trim());
    if (m == null) {
      rejections.add(SpecMarkdownRejection(
        line: lineNo,
        reason: SpecMarkdownRejectReason.malformedHeading,
        anchor: rest.trim(),
        message: 'heading carries no <!--[SECTION-ID]--> headline comment',
      ));
      _stack.add(_Frame(
          level: level, node: null, path: '', line: lineNo, ignored: true));
      return;
    }
    final id = m.group(1)!;

    if (_stack.isEmpty) {
      _openRoot(level, id, lineNo);
      return;
    }

    final parent = _stack.last;
    if (parent.ignored) {
      rejections.add(SpecMarkdownRejection(
        line: lineNo,
        reason: SpecMarkdownRejectReason.unknownSection,
        anchor: id,
        message: 'section nested under an unresolvable parent',
      ));
      _stack.add(_Frame(
          level: level, node: null, path: '', line: lineNo, ignored: true));
      return;
    }
    final pNode = parent.node;
    if (pNode == null || _isValueLeaf(pNode.kind)) {
      rejections.add(SpecMarkdownRejection(
        line: lineNo,
        reason: SpecMarkdownRejectReason.kindMismatch,
        anchor: id,
        message: 'child heading under a value-leaf or form section',
      ));
      _stack.add(_Frame(
          level: level, node: null, path: '', line: lineNo, ignored: true));
      return;
    }

    // 1. A regular (non-list) child field whose segment matches the id.
    for (final c in pNode.children) {
      if (c.kind != SomMetaKind.list && c.segment == id) {
        _stack.add(_Frame(
            level: level,
            node: c,
            path: '${parent.path}/${c.segment}',
            line: lineNo));
        return;
      }
    }

    // 2. A list item: anonymous (`<member>-<n>`), pattern-shaped stored id,
    //    or (fallback) any id when the parent has exactly one list child.
    final listChildren =
        pNode.children.where((c) => c.kind == SomMetaKind.list).toList();
    for (final lc in listChildren) {
      final anon = RegExp(
              '^${RegExp.escape(lc.memberName ?? lc.segment)}-([0-9]+)\$')
          .firstMatch(id);
      if (anon != null) {
        _openItem(level, parent, lc, int.parse(anon.group(1)!), null, lineNo);
        return;
      }
      final pattern = lc.sectionIdPattern ?? lc.elementNode?.sectionIdPattern;
      if (pattern != null && _patternMatches(pattern, id)) {
        _openItem(level, parent, lc, null, id, lineNo);
        return;
      }
    }
    if (listChildren.length == 1) {
      _openItem(level, parent, listChildren.single, null, id, lineNo);
      return;
    }

    rejections.add(SpecMarkdownRejection(
      line: lineNo,
      reason: SpecMarkdownRejectReason.unknownSection,
      anchor: id,
      message: 'section id does not resolve against the schema tree at this '
          'position (under "${parent.path}")',
    ));
    _stack.add(_Frame(
        level: level, node: null, path: '', line: lineNo, ignored: true));
  }

  void _openRoot(int level, String id, int lineNo) {
    for (final root in codec.model.roots) {
      final seg = root.sectionId ?? root.type;
      if (seg == id) {
        final tree = codec._treeFor(root.type);
        rootPrefixes.add(seg);
        _stack.add(
            _Frame(level: level, node: tree.root, path: seg, line: lineNo));
        return;
      }
    }
    rejections.add(SpecMarkdownRejection(
      line: lineNo,
      reason: SpecMarkdownRejectReason.unknownSection,
      anchor: id,
      message: 'no document root with this section id '
          '(known: ${codec.model.roots.map((r) => r.sectionId ?? r.type).join(', ')})',
    ));
    _stack.add(_Frame(
        level: level, node: null, path: '', line: lineNo, ignored: true));
  }

  /// Opens a list-item frame. [n] is the anonymous heading number (also the
  /// path number); a stored-id item gets the next free number instead.
  void _openItem(int level, _Frame parent, SomMetaNode listNode, int? n,
      String? storedId, int lineNo) {
    final listPath = '${parent.path}/${listNode.segment}';
    final state = lists.putIfAbsent(listPath, _ListState.new);
    final number = n ?? state.maxN + 1;
    if (number > state.maxN) state.maxN = number;
    final itemPath = '$listPath-$number';
    state.items.add(itemPath);
    if (storedId != null) state.ids[itemPath] = storedId;
    _stack.add(_Frame(
        level: level, node: listNode.elementNode, path: itemPath, line: lineNo));
  }

  /// `GOAL-ITEM-xxx` → `^GOAL-ITEM-.+$` — the `@SectionIdPattern` wildcard.
  static bool _patternMatches(String pattern, String id) {
    final regex =
        '^${pattern.split('xxx').map(RegExp.escape).join('.+')}\$';
    return RegExp(regex).hasMatch(id);
  }

  static bool _isValueLeaf(SomMetaKind kind) =>
      kind == SomMetaKind.content ||
      kind == SomMetaKind.scalar ||
      kind == SomMetaKind.enumValue;

  // --- Body finalisation ----------------------------------------------------

  void _finalize(_Frame frame) {
    if (frame.ignored) return;
    final node = frame.node;
    if (node != null && node.kind == SomMetaKind.form) {
      _finalizeForm(frame, node);
      return;
    }
    final value = _restoreValue(frame.body);
    if (value.isNotEmpty) {
      content[frame.path] = value;
    } else if (node != null && _isValueLeaf(node.kind)) {
      rejections.add(SpecMarkdownRejection(
        line: frame.line,
        reason: SpecMarkdownRejectReason.missingValue,
        anchor: frame.path,
        message: 'no value text under this section heading',
      ));
    }
  }

  void _finalizeForm(_Frame frame, SomMetaNode node) {
    final fieldsByLower = {
      for (final f in node.form?.fields ?? const <SomFormFieldMeta>[])
        f.name.toLowerCase(): f.name,
    };
    final fence = _FenceTracker();
    String? currentField;
    var currentLines = <String>[];

    void flush(int lineNo) {
      if (currentField != null) {
        final value = _restoreValue(currentLines);
        if (value.isNotEmpty) {
          forms.putIfAbsent(frame.path, () => {})[currentField] = value;
        }
      } else if (currentLines.any((l) => l.trim().isNotEmpty)) {
        rejections.add(SpecMarkdownRejection(
          line: lineNo,
          reason: SpecMarkdownRejectReason.orphanContent,
          anchor: frame.path,
          message: 'text in a @Form section before the first field label',
        ));
      }
      currentLines = <String>[];
    }

    for (var i = 0; i < frame.body.length; i++) {
      final line = frame.body[i];
      if (!fence.inFence) {
        final m = RegExp(r'^([A-Za-z][A-Za-z0-9_]*): ?(.*)$').firstMatch(line);
        final fieldName =
            m != null ? fieldsByLower[m.group(1)!.toLowerCase()] : null;
        if (fieldName != null) {
          flush(frame.line + i);
          currentField = fieldName;
          currentLines = [m!.group(2)!];
          fence.feed(line);
          continue;
        }
      }
      // Continuation: strip the one escape space of a label-shaped line.
      currentLines.add(!fence.inFence &&
              RegExp(r'^ +[A-Za-z][A-Za-z0-9_]*:').hasMatch(line)
          ? line.substring(1)
          : line);
      fence.feed(line);
    }
    flush(frame.line + frame.body.length);
  }

  /// Parse-side value restoration (DR1 §1.3): trim leading/trailing blank
  /// lines and unescape `\#`-escaped heading lines outside fences.
  static String _restoreValue(List<String> body) {
    final fence = _FenceTracker();
    final out = <String>[];
    for (final line in body) {
      if (!fence.inFence && RegExp(r'^\\+#').hasMatch(line)) {
        out.add(line.substring(1));
      } else {
        out.add(line);
      }
      fence.feed(line);
    }
    return out
        .join('\n')
        .replaceAll(RegExp(r'^([ \t]*\n)+'), '')
        .replaceAll(RegExp(r'(\n[ \t]*)+$'), '');
  }

  Map<String, Map<String, Object?>> listsJson() => {
        for (final e in lists.entries)
          e.key: {
            'seq': e.value.maxN,
            'items': List<String>.of(e.value.items),
            if (e.value.ids.isNotEmpty) 'ids': Map.of(e.value.ids),
          },
      };
}
