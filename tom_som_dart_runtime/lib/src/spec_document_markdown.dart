/// DocSpecs-conform Markdown codec for a TomSpecs document (SOM §11).
///
/// The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
/// the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
/// section is one markdown heading whose machine-readable identity is the
/// DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
/// section's **stored headline** when one exists, else the human-readable
/// Title-Case member name (YRD3: md is a full-fidelity format — stored
/// headlines round-trip). Content values are **normal markdown
/// text** under their heading (no fences, no anchors); `@Form` sections use the
/// DocSpecs plain-text `FieldName: value` format; a list emits its `-LST`
/// **container heading** (the id the generated schema keys its container type by),
/// with the numbered items one level deeper, each carrying the item's
/// **stored section id** when one exists (an AA1 date-lettered generated id or
/// a criterion-5 override), else the anonymous positional id — the
/// `@SectionIdPattern` resolved with the 1-based position (`GOAL-ITEM-xxx` →
/// `GOAL-ITEM-1`), else `<member>-<pos>` for a pattern-less list. The container
/// carries no content of its own. On parse, anonymous positional ids recover
/// list membership and order from position; stored ids are kept as stored ids
/// (`som_multiplatform_spec_model.md` §11.5).
/// Id-less members are **transparent** (mirroring
/// the schema generator , SOM §13): a transparent value member's text or form block
/// is the owner's body region, emitted without a heading and bound at its own
/// path; a transparent section/complex member never heads — its id-bearing
/// descendants hoist to the owner's child level (paths keep the transparent
/// segments). Section/complex headings without a field-level `@SectionId`
/// carry the target class's `@SectionId`.
///
/// Escaping (SOM §11.3): a content line starting with `#` at column 0 is
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
/// [SpecMarkdownResult.rejections] rather than dropped (SOM §11.7).
library;

import 'spec_document.dart';
import 'spec_meta.dart';
import 'spec_meta_bridge.dart';
import 'spec_model.dart';

/// Why an imported Markdown block was rejected (SOM §11.7 rejection protocol).
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

/// One rejected block in a Markdown import (SOM §11.7). Reported, never silently
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

/// The outcome of parsing a Markdown document (SOM §11.7): the staged values
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
    this.headlines = const {},
    this.codeSpecs = const {},
  });

  /// Content/scalar/enum leaf values (and section body text): path → value.
  final Map<String, String> content;

  /// Form values: form path → (field name → value).
  final Map<String, Map<String, String>> forms;

  /// List membership: list path → `{seq, items, ids?}` (the
  /// [SpecDocument.toJson] shape), recovered from the item headings.
  final Map<String, Map<String, Object?>> lists;

  /// Stored headlines (YRD3): path → heading text, staged only when the
  /// parsed heading text differs from the effective default title (keeping
  /// untouched documents byte-stable).
  final Map<String, String> headlines;

  /// Stored codeSpec mappings (codespecs_mapping.md §9.2): path → the
  /// comma-joined list of CodeSpecs code locations parsed from the
  /// `codeSpec="…"` key in the heading comment. Staged whenever present
  /// (codeSpec has no effective default).
  final Map<String, String> codeSpecs;

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
/// Markdown import/export format (SOM §11).
class SpecDocumentMarkdown {
  SpecDocumentMarkdown(this.model, this.document);

  final SpecModel model;
  final SpecDocument document;

  /// Metadata trees per root type, built lazily (the generated facades will
  /// hand these in directly; until then the bridge derives them).
  final Map<String, SomMetaTree> _trees = {};

  SomMetaTree _treeFor(String rootType) => _trees.putIfAbsent(
      rootType, () => buildSomMetaTree(model, rootType: rootType));

  // --- Naming helpers (SOM §11.2 / §11.5) ----------------------------------

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
  /// `@Document` name (SOM §11.1).
  static String kebabCase(String title) => title
      .trim()
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '')
      .toLowerCase();

  /// The item heading title stem: Title-Case element class name with a
  /// trailing `Entry` dropped (SOM §11.5, normative).
  static String itemTitleStem(String elementClassName) {
    var stem = elementClassName;
    if (stem.length > 5 && stem.endsWith('Entry')) {
      stem = stem.substring(0, stem.length - 5);
    }
    return titleCase(stem);
  }

  /// The `FieldName` label written for a form field: the model field name with
  /// the first letter upper-cased (SOM §11.4).
  static String formLabel(String fieldName) => fieldName.isEmpty
      ? fieldName
      : fieldName[0].toUpperCase() + fieldName.substring(1);

  // --- Export (SOM §11.1–§11.8) --------------------------------------------

  /// The section id written into (and matched from) a heading for [node]
  /// (SOM §11.2/§11.8): the field-level `@SectionId` when present; for
  /// section/complex nodes whose field carries none, the target **class**'s
  /// `@SectionId` (the id the generated schema types are keyed by); else the path
  /// segment (the member name).
  String _headingIdOf(SomMetaNode node) =>
      node.sectionId ??
      ((node.kind == SomMetaKind.section || node.kind == SomMetaKind.complex)
          ? model.classNamed(node.className)?.sectionId
          : null) ??
      node.segment;

  // --- Transparency (SOM §11.2, mirroring the schema generator , SOM §13) ----------
  //
  // The `docspecs-schema` generator (SOM §13) is normative: only **section-bearing**
  // nodes (those with a real `@SectionId`, field- or class-level) become
  // section types; id-less members are *transparent* — they are not sections
  // of their own. The markdown format mirrors that exactly:
  //
  //   * a transparent value member (content/scalar/enum/form without an id)
  //     is emitted headinglessly into its owner's *body region* (text, or a
  //     `FieldName: value` form block);
  //   * a transparent section/complex member gets no heading; its id-bearing
  //     descendants surface as the owner's direct child headings (the schema's
  //     "nearest section-bearing descendant" hoisting), with document paths
  //     still running through the transparent segments;
  //   * lists are never transparent — the `-LST` container heads (SOM §11.2) and
  //     the items head one level below it (positional id / `<member>-<pos>`).
  //
  // Principled canonicalisation losses (documented, accepted): multiple
  // transparent content members of one owner merge into the first on parse,
  // and a form-field label colliding across an owner's transparent forms binds
  // to the nearest form in slot order.

  /// A section/complex member with no field- or class-level `@SectionId`:
  /// heading-less, its children hoist to the owner.
  bool _isTransparentSection(SomMetaNode n) =>
      (n.kind == SomMetaKind.section || n.kind == SomMetaKind.complex) &&
      n.sectionId == null &&
      model.classNamed(n.className)?.sectionId == null;

  /// A value member (content/scalar/enum/form) with no `@SectionId`: emitted
  /// into the owner's body region instead of under an own heading.
  bool _isTransparentValue(SomMetaNode n) =>
      n.sectionId == null &&
      (n.kind == SomMetaKind.content ||
          n.kind == SomMetaKind.scalar ||
          n.kind == SomMetaKind.enumValue ||
          n.kind == SomMetaKind.form);

  /// The ordered *body slots* of [node]: every transparent value member and
  /// every transparent section (whose own path may carry body text), collected
  /// depth-first through transparent sections. These are the value positions
  /// that share the owner's heading body.
  List<(SomMetaNode, String)> _bodySlots(SomMetaNode node) {
    final out = <(SomMetaNode, String)>[];
    void collect(SomMetaNode n, String prefix) {
      for (final c in n.children) {
        if (c.recursive) continue;
        final rel = prefix.isEmpty ? c.segment : '$prefix/${c.segment}';
        if (_isTransparentValue(c)) {
          out.add((c, rel));
        } else if (_isTransparentSection(c)) {
          out.add((c, rel));
          collect(c, rel);
        }
      }
    }

    collect(node, '');
    return out;
  }

  /// The ordered *effective children* of [node]: every section-bearing child
  /// and every list, hoisted through transparent sections — exactly the
  /// headings (and item-heading owners) the generated schema knows at this position.
  /// Each entry carries the relative path from [node] (which runs through the
  /// transparent segments).
  List<(SomMetaNode, String)> _effectiveChildren(SomMetaNode node) {
    final out = <(SomMetaNode, String)>[];
    void collect(SomMetaNode n, String prefix) {
      for (final c in n.children) {
        if (c.recursive) continue;
        final rel = prefix.isEmpty ? c.segment : '$prefix/${c.segment}';
        if (_isTransparentValue(c)) continue; // body region
        if (_isTransparentSection(c)) {
          collect(c, rel);
        } else {
          out.add((c, rel));
        }
      }
    }

    collect(node, '');
    return out;
  }

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
    _writeHeading(b, 1, rootSeg,
        document.headline(rootSeg) ?? node.headline ?? root.title,
        codeSpec: document.codeSpec(rootSeg));
    _writeSectionBody(b, node, rootSeg);
    _writeChildren(b, node, rootSeg, 2);
    return b.toString();
  }

  /// Writes the body region of a section heading: the section path's own
  /// content value plus every transparent body slot (id-less content text and
  /// form blocks, hoisted through transparent sections) in model order.
  void _writeSectionBody(StringBuffer b, SomMetaNode node, String path) {
    _writeBody(b, document.content(path), path);
    for (final (slot, rel) in _bodySlots(node)) {
      final slotPath = '$path/$rel';
      if (slot.kind == SomMetaKind.form) {
        if (_formHasValues(slot, slotPath)) _writeForm(b, slot, slotPath);
      } else {
        _writeBody(b, document.content(slotPath), slotPath);
      }
    }
  }

  void _writeChildren(
      StringBuffer b, SomMetaNode node, String basePath, int depth) {
    for (final (child, rel) in _effectiveChildren(node)) {
      final path = '$basePath/$rel';
      if (!document.hasValuesUnder(path)) continue;
      switch (child.kind) {
        case SomMetaKind.content:
        case SomMetaKind.scalar:
        case SomMetaKind.enumValue:
          final value = document.content(path);
          if (value == null) break;
          _writeHeading(b, depth, _headingIdOf(child),
              document.headline(path) ?? _titleOf(child),
              codeSpec: document.codeSpec(path));
          _writeBody(b, value, path);
        case SomMetaKind.form:
          if (!_formHasValues(child, path)) break;
          _writeHeading(b, depth, _headingIdOf(child),
              document.headline(path) ?? _titleOf(child),
              codeSpec: document.codeSpec(path));
          _writeForm(b, child, path);
        case SomMetaKind.section:
        case SomMetaKind.complex:
          _writeHeading(b, depth, _headingIdOf(child),
              document.headline(path) ?? _titleOf(child),
              codeSpec: document.codeSpec(path));
          _writeSectionBody(b, child, path);
          _writeChildren(b, child, path, depth + 1);
        case SomMetaKind.list:
          _writeList(b, child, path, depth);
      }
    }
  }

  /// Emits list [node] as its `-LST` container heading (SOM §11.2/§11.5) at
  /// [depth], wrapping the numbered item headings one level deeper. The
  /// container is a real section — the id the generated schema keys its container
  /// type by — but carries **no content of its own** (schema content
  /// min/max-text-length 0). Item identity is the stored id when one exists,
  /// else positional (YRD3).
  void _writeList(
      StringBuffer b, SomMetaNode node, String listPath, int depth) {
    final items = document.listItems(listPath);
    if (items.isEmpty) return;
    // The container heading: its id is the list's `-LST` `@SectionId` (else the
    // member segment for a pattern-less list); its title is the stored
    // headline, else the member name.
    _writeHeading(b, depth, _headingIdOf(node),
        document.headline(listPath) ?? _titleOf(node),
        codeSpec: document.codeSpec(listPath));
    // Item heading stem. Complex lists derive it from the element class name
    // (SOM §11.5, `Entry` dropped). A scalar list (`List<String>`, shape 6) has
    // no element class — its element `typeName` is literally `String`, which
    // would render "String 1", "String 2". Derive the stem from the list FIELD
    // instead (its member name, Title-Cased like the container heading) so a
    // populated scalar list gets meaningful per-item headings (YRC5).
    final stem = _itemStemOf(node);
    final pattern = node.sectionIdPattern ?? node.elementNode?.sectionIdPattern;
    for (var i = 0; i < items.length; i++) {
      final itemPath = items[i];
      final pos = i + 1;
      // YRD3: the heading id is the item's STORED section
      // id when one exists (an AA1 generated id or a criterion-5 override);
      // only anonymous items fall back to the positional id — the
      // `@SectionIdPattern` resolved with the 1-based position
      // (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`), else `<member>-<pos>` for a
      // pattern-less list. On parse, numbered-pattern ids recover membership
      // and order from position; other pattern-shaped ids parse back as stored
      // ids. Items sit one level below the container.
      final id = document.itemSectionId(itemPath) ??
          pattern?.replaceAll('xxx', '$pos') ??
          '${node.memberName ?? node.segment}-$pos';
      _writeHeading(b, depth + 1, id,
          document.headline(itemPath) ?? '$stem $pos',
          codeSpec: document.codeSpec(itemPath));
      final element = node.elementNode;
      if (element == null) {
        // Scalar list: the item's value is its body.
        _writeBody(b, document.content(itemPath) ?? '', itemPath);
      } else {
        _writeSectionBody(b, element, itemPath);
        if (!element.recursive) {
          _writeChildren(b, element, itemPath, depth + 2);
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
        // SOM §11.4 generalised: any continuation line that could be mistaken
        // for a field-label line gains one leading space; parse strips it.
        b.writeln(_labelShaped.hasMatch(line) ? ' $line' : line);
      }
    }
    b.writeln();
  }

  /// `## <!--[ID]--> Title` at [depth]. SOM §11.2 is normative — heading level
  /// = 1 + section depth, **uncapped**: deep models (the Solution Blueprint
  /// nests past markdown's native 6 levels) keep their structure; the parse
  /// grammar accepts `#{7,}` accordingly. Capping would silently flatten
  /// distinct nesting positions into siblings and break schema validation.
  ///
  /// When [codeSpec] is non-empty it is emitted as a `codeSpec="…"` key inside
  /// the same headline comment (codespecs_mapping.md §9.2): `## <!--[ID]
  /// codeSpec="A,B"--> Title`.
  static void _writeHeading(StringBuffer b, int depth, String id, String title,
      {String? codeSpec}) {
    final code =
        (codeSpec != null && codeSpec.isNotEmpty) ? ' codeSpec="$codeSpec"' : '';
    b.writeln('${'#' * depth} <!--[$id]$code--> $title');
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

  /// Emit-side value normalisation (SOM §11.3): collapse 2+ blank lines to one,
  /// trim leading/trailing blank lines, escape heading-like lines outside
  /// fences. Throws [ArgumentError] for an unterminated fence.
  String _prepareValue(String value, String path) {
    final collapsed = value
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'^\n+'), '')
        .replaceAll(RegExp(r'\n+$'), '');
    final fence = MarkdownFenceTracker();
    final out = <String>[];
    for (final line in collapsed.split('\n')) {
      if (fence.inFence) {
        out.add(line); // SOM §11.3: fences shield their lines.
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

  /// The effective DEFAULT title of [node] (YRD4): the `@Headline` default
  /// when authored, else the name derivation. The stored headline (checked by
  /// callers first) always wins over this.
  static String _titleOf(SomMetaNode node) =>
      node.headline ?? titleCase(node.memberName ?? node.className);

  /// The effective default item-title stem of list [node] (YRD4): the element
  /// class's `@Headline` default when authored, else the SOM §11.5 derivation
  /// (element class name with `Entry` dropped; member name for scalar lists).
  static String _itemStemOf(SomMetaNode node) {
    final element = node.elementNode;
    return element != null
        ? (element.headline ?? itemTitleStem(element.className))
        : titleCase(node.memberName ?? node.segment);
  }

  // A line the emitter must escape: an optional run of backslashes followed by
  // `#` at column 0 (the escape itself must survive the round-trip).
  static final RegExp _escapable = RegExp(r'^\\*#');

  // A line that would parse as a form-field label: `Word:` at column 0
  // (optionally already space-prefixed — each emit pass adds one more space).
  static final RegExp _labelShaped = RegExp(r'^ *[A-Za-z][A-Za-z0-9_]*:');

  // --- Import (SOM §11.7) ---------------------------------------------------

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
      headlines: p.headlines,
      codeSpecs: p.codeSpecs,
    );
  }

  // Shared with _Parser.
  static final RegExp headingLine = RegExp(r'^(#+)\s+(.*)$');

  /// The heading HTML comment: `<!--[ID]--> Title` with an optional key=value
  /// region between the id bracket and the closing `-->` (codespecs_mapping.md
  /// §9.2 `codeSpec`). Group 1 = the section id, group 2 = the raw key=value
  /// region (possibly empty), group 3 = the heading title. The middle group is
  /// `[^>]*` — safe because the region's only values are quoted code locations
  /// / identifiers, never a raw `>`.
  static final RegExp headlineComment =
      RegExp(r'^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$');

  /// Extracts the `codeSpec="…"` value from a heading-comment key=value region
  /// (codespecs_mapping.md §9.2), mirroring the tom_doc_scanner key=value
  /// grammar. Returns the empty string when the region carries no `codeSpec`
  /// key.
  static String codeSpecOf(String region) {
    final m = _codeSpecPattern.firstMatch(region);
    if (m == null) return '';
    return (m.group(1) ?? m.group(2) ?? m.group(3) ?? '').trim();
  }

  static final RegExp _codeSpecPattern =
      RegExp(r'''codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))''');

  static final RegExp docspecComment =
      RegExp(r'^<!--\s*docspec:.*-->\s*$');
}

/// Fence state machine (CommonMark-ish): a line whose first non-space run (up
/// to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
/// same-character run at least as long closes it.
///
/// Public so other markdown-processing modules (the DocSpecs validator's
/// generic parser) share exactly the same fence semantics as this codec.
class MarkdownFenceTracker {
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
  final headlines = <String, String>{};
  final codeSpecs = <String, String>{};
  final rejections = <SpecMarkdownRejection>[];
  final rootPrefixes = <String>{};

  final List<_Frame> _stack = [];
  final _fence = MarkdownFenceTracker();

  void run(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final lineNo = i + 1;
      final trimmed = raw.trimRight();

      if (!_fence.inFence) {
        if (_stack.isEmpty &&
            SpecDocumentMarkdown.docspecComment.hasMatch(trimmed)) {
          continue; // SOM §11.1 header — informational.
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
    final codeSpec = SpecDocumentMarkdown.codeSpecOf(m.group(2)!);
    final title = m.group(3)!.trim();

    if (_stack.isEmpty) {
      _openRoot(level, id, title, codeSpec, lineNo);
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

    // 1. Under a `-LST` container frame (SOM §11.2), every child heading is one
    //    of that list's items — resolved positionally, not by the schema tree.
    if (pNode.kind == SomMetaKind.list) {
      _openItemHeading(level, parent, pNode, id, title, codeSpec, lineNo);
      return;
    }

    // 2. A regular (non-list) or list-**container** *effective* child —
    //    section-bearing children hoisted through transparent sections — whose
    //    heading id matches. A list heads its `-LST` container here; its items
    //    are resolved above once the container frame is open. Transparent value
    //    members never head, so they never match; the bound path runs through
    //    the transparent segments.
    final effective = codec._effectiveChildren(pNode);
    for (final (c, rel) in effective) {
      if (codec._headingIdOf(c) == id) {
        final path = '${parent.path}/$rel';
        // YRD3: stage the heading text as a stored headline only when it
        // differs from the effective default title (byte-stability).
        if (title.isNotEmpty && title != SpecDocumentMarkdown._titleOf(c)) {
          headlines[path] = title;
        }
        // codespecs_mapping.md §9.2: stage the codeSpec mapping whenever
        // present (no default).
        if (codeSpec.isNotEmpty) codeSpecs[path] = codeSpec;
        _stack.add(_Frame(level: level, node: c, path: path, line: lineNo));
        return;
      }
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

  /// Opens a list-item frame under a `-LST` container frame (SOM §11.2). The
  /// heading [id] is matched positionally against the container's list:
  /// the `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a
  /// number (`GOAL-ITEM-3`, parses back as item `<n>`), a pattern-shaped stored
  /// id, or — for any other id — an anonymous next item carrying the stored id.
  void _openItemHeading(int level, _Frame container, SomMetaNode listNode,
      String id, String title, String codeSpec, int lineNo) {
    final listPath = container.path;
    final anon =
        RegExp('^${RegExp.escape(listNode.memberName ?? listNode.segment)}'
                '-([0-9]+)\$')
            .firstMatch(id);
    if (anon != null) {
      _openItem(level, listPath, listNode, int.parse(anon.group(1)!), null,
          title, codeSpec, lineNo);
      return;
    }
    final pattern =
        listNode.sectionIdPattern ?? listNode.elementNode?.sectionIdPattern;
    if (pattern != null) {
      // Canonical anonymous id: the pattern with `xxx` as a number — parses
      // back as item <n>, NOT as a stored id (YRD3 round-trip, SOM §11.5).
      final numbered = RegExp(
              '^${pattern.split('xxx').map(RegExp.escape).join('([0-9]+)')}\$')
          .firstMatch(id);
      if (numbered != null && numbered.groupCount == 1) {
        _openItem(level, listPath, listNode, int.parse(numbered.group(1)!),
            null, title, codeSpec, lineNo);
        return;
      }
      if (_patternMatches(pattern, id)) {
        _openItem(level, listPath, listNode, null, id, title, codeSpec, lineNo);
        return;
      }
    }
    // Any other id under the container is an anonymous next item carrying the
    // stored id (YRD3: stored ids round-trip through md as well as yaml).
    _openItem(level, listPath, listNode, null, id, title, codeSpec, lineNo);
  }

  void _openRoot(int level, String id, String title, String codeSpec,
      int lineNo) {
    for (final root in codec.model.roots) {
      final seg = root.sectionId ?? root.type;
      if (seg == id) {
        final tree = codec._treeFor(root.type);
        rootPrefixes.add(seg);
        // YRD3: stage a renamed root heading as a stored headline —
        // "renamed" relative to the effective default (YRD4: `@Headline`
        // default, else the `@Document` title).
        if (title.isNotEmpty && title != (tree.root.headline ?? root.title)) {
          headlines[seg] = title;
        }
        // codespecs_mapping.md §9.2: stage the root codeSpec mapping whenever
        // present.
        if (codeSpec.isNotEmpty) codeSpecs[seg] = codeSpec;
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
  /// path number); a stored-id item gets the next free number instead. The
  /// heading [title] is staged as a stored headline when it differs from the
  /// default item title `<stem> <number>` (YRD3).
  void _openItem(int level, String listPath, SomMetaNode listNode, int? n,
      String? storedId, String title, String codeSpec, int lineNo) {
    final state = lists.putIfAbsent(listPath, _ListState.new);
    final number = n ?? state.maxN + 1;
    if (number > state.maxN) state.maxN = number;
    final itemPath = '$listPath-$number';
    state.items.add(itemPath);
    if (storedId != null) state.ids[itemPath] = storedId;
    final element = listNode.elementNode;
    final stem = SpecDocumentMarkdown._itemStemOf(listNode);
    if (title.isNotEmpty && title != '$stem $number') {
      headlines[itemPath] = title;
    }
    // codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever
    // present.
    if (codeSpec.isNotEmpty) codeSpecs[itemPath] = codeSpec;
    _stack.add(
        _Frame(level: level, node: element, path: itemPath, line: lineNo));
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
      _finalizeForm(frame, node, frame.path);
      return;
    }
    final slots =
        node == null ? const <(SomMetaNode, String)>[] : codec._bodySlots(node);
    if (slots.isEmpty) {
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
      return;
    }
    _finalizeBodySlots(frame, slots);
  }

  /// Binds a heading's body region against the owner's transparent body slots
  /// (SOM §11.2 transparency): `FieldName:` lines matching a transparent form's
  /// fields route to that form (nearest form in slot order, wrapping); all
  /// other text binds to the first non-form slot — or to the owner's own path
  /// when no such slot exists.
  void _finalizeBodySlots(_Frame frame, List<(SomMetaNode, String)> slots) {
    final formSlots = [
      for (final s in slots)
        if (s.$1.kind == SomMetaKind.form) s,
    ];
    final contentSlots = [
      for (final s in slots)
        if (s.$1.kind != SomMetaKind.form) s,
    ];
    final contentPath = contentSlots.isNotEmpty
        ? '${frame.path}/${contentSlots.first.$2}'
        : frame.path;

    if (formSlots.isEmpty) {
      final value = _restoreValue(frame.body);
      if (value.isNotEmpty) content[contentPath] = value;
      return;
    }

    (int, SomFormFieldMeta)? findField(String label) {
      final lower = label.toLowerCase();
      for (var k = 0; k < formSlots.length; k++) {
        final idx = (_currentFormIdx + k) % formSlots.length;
        for (final f
            in formSlots[idx].$1.form?.fields ?? const <SomFormFieldMeta>[]) {
          if (f.name.toLowerCase() == lower) return (idx, f);
        }
      }
      return null;
    }

    final fence = MarkdownFenceTracker();
    String? currentField;
    String? currentFormPath;
    var currentLines = <String>[];
    final contentLines = <String>[];

    void flush() {
      final field = currentField;
      final formPath = currentFormPath;
      if (field != null && formPath != null) {
        final value = _restoreValue(currentLines);
        if (value.isNotEmpty) {
          forms.putIfAbsent(formPath, () => {})[field] = value;
        }
      }
      currentLines = <String>[];
    }

    _currentFormIdx = 0;
    for (var i = 0; i < frame.body.length; i++) {
      final line = frame.body[i];
      if (!fence.inFence) {
        final m = RegExp(r'^([A-Za-z][A-Za-z0-9_]*): ?(.*)$').firstMatch(line);
        if (m != null) {
          final hit = findField(m.group(1)!);
          if (hit != null) {
            flush();
            _currentFormIdx = hit.$1;
            currentField = hit.$2.name;
            currentFormPath = '${frame.path}/${formSlots[hit.$1].$2}';
            currentLines = [m.group(2)!];
            fence.feed(line);
            continue;
          }
        }
      }
      final target = currentField == null ? contentLines : currentLines;
      // Continuation: strip the one escape space of a label-shaped line.
      target.add(!fence.inFence &&
              currentField != null &&
              RegExp(r'^ +[A-Za-z][A-Za-z0-9_]*:').hasMatch(line)
          ? line.substring(1)
          : line);
      fence.feed(line);
    }
    flush();
    final value = _restoreValue(contentLines);
    if (value.isNotEmpty) content[contentPath] = value;
  }

  /// Rolling pointer into a body region's transparent form slots — labels bind
  /// to the nearest form at or after the last hit (wrapping), so repeated field
  /// names across an owner's transparent forms follow emit order.
  int _currentFormIdx = 0;

  void _finalizeForm(_Frame frame, SomMetaNode node, String path) {
    final fieldsByLower = {
      for (final f in node.form?.fields ?? const <SomFormFieldMeta>[])
        f.name.toLowerCase(): f.name,
    };
    final fence = MarkdownFenceTracker();
    String? currentField;
    var currentLines = <String>[];

    void flush(int lineNo) {
      if (currentField != null) {
        final value = _restoreValue(currentLines);
        if (value.isNotEmpty) {
          forms.putIfAbsent(path, () => {})[currentField] = value;
        }
      } else if (currentLines.any((l) => l.trim().isNotEmpty)) {
        rejections.add(SpecMarkdownRejection(
          line: lineNo,
          reason: SpecMarkdownRejectReason.orphanContent,
          anchor: path,
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

  /// Parse-side value restoration (SOM §11.3): trim leading/trailing blank
  /// lines and unescape `\#`-escaped heading lines outside fences.
  static String _restoreValue(List<String> body) {
    final fence = MarkdownFenceTracker();
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
