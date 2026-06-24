/// The **document tools** — the engine-side logic behind the `doc_*` in-memory
/// MCP tools (§8.2, plan step 14).
///
/// [DocTools] is the in-process surface the editor's `AgentToolsModule` wraps as
/// `doc_search` / `doc_search_iterate` / `doc_reflect` / `doc_add_node`. It binds
/// two primitives the prior steps already built:
///
///   * a [SpecQueryEngine] (model + live [SpecDocument]) — the §6 grep facility
///     for `doc_search` / `doc_search_iterate` and the [SpecReflection] resolver
///     behind `doc_reflect`;
///   * a [SpecController] — the live-document mutation port `doc_add_node` routes
///     through, so a meta-model-validated add lands in the **one change log**
///     exactly like every other tool/script edit (§5, req c).
///
/// `doc_search` opens a [SpecQueryCursor] under a generated id and returns the
/// first page; `doc_search_iterate` advances the *same* cursor, so the §6
/// edit-stable lazy iteration is preserved across calls. Every result is a typed
/// value with a compact [toJson] — the JSON shape the MCP tool returns.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import '../scope/spec_controller.dart';

/// One match in a [DocSearchPage] — a §6 cursor record projected to JSON.
final class DocSearchMatch {
  /// The globally-unique section-id path the node lives at.
  final String path;

  /// What kind of node the path lands on.
  final SpecNodeKind kind;

  /// The model class the node *is* (`null` for value leaves / list containers).
  final String? classId;

  /// The node's doc-comment / label headline (`null` when none).
  final String? headline;

  /// The matched text when the query carried a `text` dimension (`null`
  /// otherwise).
  final String? snippet;

  /// The `[start, end)` spans within [snippet] the `text` pattern hit.
  final List<SpecMatchSpan> matchSpans;

  const DocSearchMatch({
    required this.path,
    required this.kind,
    this.classId,
    this.headline,
    this.snippet,
    this.matchSpans = const [],
  });

  /// Projects a §6 [SpecQueryMatch] to the compact `doc_*` match shape — the one
  /// shared projection behind both the `doc_search` MCP tool ([DocTools]) and the
  /// in-script `search` cursor facade (`SpecSearchCursor`, followup item 12), so
  /// a tool match and a script match render identically.
  factory DocSearchMatch.from(SpecQueryMatch m) => DocSearchMatch(
        path: m.path,
        kind: m.kind,
        classId: m.classId,
        headline: m.headline,
        snippet: m.snippet,
        matchSpans: m.matchSpans,
      );

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'path': path,
        'kind': kind.name,
        if (classId != null) 'classId': classId,
        if (headline != null) 'headline': headline,
        if (snippet != null) 'snippet': snippet,
        if (matchSpans.isNotEmpty)
          'spans': [for (final s in matchSpans) [s.start, s.end]],
      };
}

/// One page of `doc_search` / `doc_search_iterate` results plus the cursor id
/// to continue iterating with.
final class DocSearchPage {
  /// The cursor id to pass to `doc_search_iterate` for the next page. Dropped
  /// (and rejected on re-use) once [done].
  final String cursorId;

  /// This page's matches (at most the page size).
  final List<DocSearchMatch> matches;

  /// Whether the cursor is exhausted (no further pages).
  final bool done;

  /// How many further matches remain after this page (re-validated live).
  final int remaining;

  const DocSearchPage({
    required this.cursorId,
    required this.matches,
    required this.done,
    required this.remaining,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'cursorId': cursorId,
        'matches': [for (final m in matches) m.toJson()],
        'done': done,
        'remaining': remaining,
      };
}

/// A single annotation captured on a class or field (`doc_reflect`).
final class DocAnnotation {
  /// The annotation name (e.g. `MapsTo`).
  final String name;

  /// The resolved argument map.
  final Map<String, Object?> arguments;

  const DocAnnotation({required this.name, this.arguments = const {}});

  factory DocAnnotation._from(SpecAnnotation a) =>
      DocAnnotation(name: a.name, arguments: a.arguments);

  /// A compact JSON view.
  Map<String, Object?> toJson() => {
        'name': name,
        if (arguments.isNotEmpty) 'arguments': arguments,
      };
}

/// One model-permitted child of a reflected container node (`doc_reflect`): the
/// segment a `doc_add_node` would use plus the field's structural facts.
final class DocAllowedChild {
  /// The section segment the child is added under (`@SectionId` ?? field name).
  final String segment;

  /// The declared field name.
  final String field;

  /// The field's render kind.
  final SpecFieldKind kind;

  /// The single-valued field's target/scalar type (`null` for lists/leaves).
  final String? type;

  /// A list field's element type (`null` for non-lists).
  final String? elementType;

  /// Whether a list field's element is a complex (class) type.
  final bool elementIsComplex;

  /// The `@SectionIdPattern` a list item's id must match (`null` when none).
  final String? sectionIdPattern;

  /// The enum values for an `enum` field (empty otherwise).
  final List<String> enumValues;

  /// The field's annotations.
  final List<DocAnnotation> annotations;

  const DocAllowedChild({
    required this.segment,
    required this.field,
    required this.kind,
    this.type,
    this.elementType,
    this.elementIsComplex = false,
    this.sectionIdPattern,
    this.enumValues = const [],
    this.annotations = const [],
  });

  factory DocAllowedChild._from(SpecField f) => DocAllowedChild(
        segment: f.sectionId ?? f.name,
        field: f.name,
        kind: f.kind,
        type: f.type,
        elementType: f.elementType,
        elementIsComplex: f.elementIsComplex,
        sectionIdPattern: f.sectionIdPattern,
        enumValues: f.enumValues,
        annotations: [for (final a in f.annotations) DocAnnotation._from(a)],
      );

  /// A compact JSON view.
  Map<String, Object?> toJson() => {
        'segment': segment,
        'field': field,
        'kind': kind.name,
        if (type != null) 'type': type,
        if (elementType != null) 'elementType': elementType,
        if (elementIsComplex) 'elementIsComplex': true,
        if (sectionIdPattern != null) 'sectionIdPattern': sectionIdPattern,
        if (enumValues.isNotEmpty) 'enumValues': enumValues,
        if (annotations.isNotEmpty)
          'annotations': [for (final a in annotations) a.toJson()],
      };
}

/// The `doc_reflect` result: the meta-model facts a node addresses.
final class DocReflection {
  /// The path that was reflected.
  final String path;

  /// Whether [path] resolves to a model node.
  final bool resolved;

  /// What kind of node the path lands on (`null` when unresolved).
  final SpecNodeKind? kind;

  /// The model class the node *is* (`null` for leaves / unresolved).
  final String? classId;

  /// The node's `@SectionId`.
  final String? sectionId;

  /// The `@MapsTo` target on the node's class.
  final String? mapsTo;

  /// The `@DetailedIn` target on the node's class.
  final String? detailedIn;

  /// The node's doc-comment / label headline.
  final String? headline;

  /// The class-level annotations (empty for leaves / unresolved).
  final List<DocAnnotation> annotations;

  /// The model-permitted children (empty for leaves / unresolved).
  final List<DocAllowedChild> allowedChildren;

  const DocReflection({
    required this.path,
    required this.resolved,
    this.kind,
    this.classId,
    this.sectionId,
    this.mapsTo,
    this.detailedIn,
    this.headline,
    this.annotations = const [],
    this.allowedChildren = const [],
  });

  /// An unresolved-path reflection.
  const DocReflection.unresolved(this.path)
      : resolved = false,
        kind = null,
        classId = null,
        sectionId = null,
        mapsTo = null,
        detailedIn = null,
        headline = null,
        annotations = const [],
        allowedChildren = const [];

  /// Reflects the node at [path] against [model] — the read-only meta-model
  /// facts the path addresses: its kind/class, structural facets
  /// (`@SectionId` / `@MapsTo` / `@DetailedIn`), the class annotations, and the
  /// model-permitted children (the segments a `doc_add_node` accepts). Returns an
  /// [DocReflection.unresolved] when the path does not resolve against the model.
  ///
  /// This is the single reflection builder shared by the `doc_reflect` MCP tool
  /// ([DocTools.reflect]) and the in-script `model` reflection facade
  /// (`SpecModelApi`, followup item 11) — both read the same meta-model facts
  /// from the live controller's model, with no document (LLM) calls.
  factory DocReflection.resolve(SpecModel model, String path) {
    final res = SpecReflection(model).resolve(path);
    if (res == null) return DocReflection.unresolved(path);
    final cls = res.targetClass;
    return DocReflection(
      path: path,
      resolved: true,
      kind: res.kind,
      classId: cls?.name,
      sectionId: res.field?.sectionId ?? cls?.sectionId ?? res.root.sectionId,
      mapsTo: cls?.mapsTo,
      detailedIn: cls?.detailedIn,
      headline: res.field?.doc ??
          cls?.doc ??
          (res.kind == SpecNodeKind.root ? res.root.description : null),
      annotations: cls == null
          ? const []
          : [for (final a in cls.annotations) DocAnnotation._from(a)],
      allowedChildren: cls == null
          ? const []
          : [for (final f in cls.fields) DocAllowedChild._from(f)],
    );
  }

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'path': path,
        'resolved': resolved,
        if (kind != null) 'kind': kind!.name,
        if (classId != null) 'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        if (mapsTo != null) 'mapsTo': mapsTo,
        if (detailedIn != null) 'detailedIn': detailedIn,
        if (headline != null) 'headline': headline,
        if (annotations.isNotEmpty)
          'annotations': [for (final a in annotations) a.toJson()],
        if (allowedChildren.isNotEmpty)
          'allowedChildren': [for (final c in allowedChildren) c.toJson()],
      };
}

/// The `doc_add_node` result: the new node's path, or the coded reason the
/// meta-model rejected the add.
final class DocAddNodeResult {
  /// Whether the add was legal and performed.
  final bool ok;

  /// The new node's path (when [ok]).
  final String? path;

  /// The human-readable rejection message (when not [ok]).
  final String? error;

  /// The [SpecCreationCode] name when the add violated a §5 rule (`null` for
  /// other failures).
  final String? code;

  const DocAddNodeResult({
    required this.ok,
    this.path,
    this.error,
    this.code,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'ok': ok,
        if (path != null) 'path': path,
        if (error != null) 'error': error,
        if (code != null) 'code': code,
      };
}

/// Searches, reflects, and grows a live document under the §8.2 `doc_*` tools.
final class DocTools {
  /// Creates the toolset over a query [engine] (read/search/reflect) and a
  /// [controller] (the §5 mutation port `doc_add_node` routes through).
  DocTools({
    required this.engine,
    required this.controller,
    this.pageSize = 20,
  });

  /// The §6 query facility over the live (model, document) pair.
  final SpecQueryEngine engine;

  /// The live-document mutation port (the one change log).
  final SpecController controller;

  /// The default page size for `doc_search` / `doc_search_iterate`.
  final int pageSize;

  final Map<String, SpecQueryCursor> _cursors = <String, SpecQueryCursor>{};
  int _cursorSeq = 0;

  /// `doc_search` — runs [query] (the §6 grep facility), opens a cursor under a
  /// fresh id, and returns the first page. Continue with [iterate] using the
  /// returned [DocSearchPage.cursorId].
  DocSearchPage search(SpecQuery query, {int? pageSize}) {
    final cursor = engine.query(query);
    final id = 'cur-${++_cursorSeq}';
    _cursors[id] = cursor;
    return _page(id, cursor, pageSize ?? this.pageSize);
  }

  /// `doc_search_iterate` — advances the cursor named [cursorId] by one page.
  /// Throws [ArgumentError] for an unknown or already-exhausted cursor.
  DocSearchPage iterate(String cursorId, {int? pageSize}) {
    final cursor = _cursors[cursorId];
    if (cursor == null) {
      throw ArgumentError.value(cursorId, 'cursorId', 'no such (or exhausted) cursor');
    }
    return _page(cursorId, cursor, pageSize ?? this.pageSize);
  }

  /// `doc_reflect` — the meta-model facts the node at [path] addresses: its
  /// kind/class, structural facets (`@SectionId` / `@MapsTo` / `@DetailedIn`),
  /// the class annotations, and the model-permitted children (allowed
  /// `doc_add_node` segments + their types). Delegates to the shared
  /// [DocReflection.resolve] builder the in-script `model` facade also uses.
  DocReflection reflect(String path) =>
      DocReflection.resolve(engine.model, path);

  /// `doc_add_node` — the §5 meta-model-validated creation of child
  /// [childSegment] under [parentPath], routed through [controller] so it lands
  /// in the one change log. A model violation is returned as a coded failed
  /// result, never thrown.
  ///
  /// An optional **initial payload** populates the new node in the same call,
  /// instead of leaving it empty (followup item 17): [content] sets a leaf's
  /// content value and [fields] sets a form section's named fields. Each
  /// populated value routes through the same [controller] mutation port, so the
  /// create + its initial values land in the **one change log** as a coherent
  /// burst (an `add` entry followed by one `content`/`form` entry per applied
  /// value). The create runs first to obtain the path; a populate failure
  /// surfaces as a failed result, leaving the legally-created (empty) node in
  /// place — recoverable via the controller's undo stack.
  DocAddNodeResult addNode(
    String parentPath,
    String childSegment, {
    String? itemId,
    String? content,
    Map<String, String>? fields,
  }) {
    try {
      final path =
          controller.addChild(parentPath, childSegment, itemId: itemId);
      if (content != null && content.isNotEmpty) {
        controller.setContent(path, content);
      }
      if (fields != null) {
        for (final entry in fields.entries) {
          controller.setFormField(path, entry.key, entry.value);
        }
      }
      return DocAddNodeResult(ok: true, path: path);
    } on SpecCreationError catch (e) {
      return DocAddNodeResult(ok: false, error: e.message, code: e.code.name);
    } catch (e) {
      return DocAddNodeResult(ok: false, error: e.toString());
    }
  }

  // --- helpers -------------------------------------------------------------

  DocSearchPage _page(String id, SpecQueryCursor cursor, int size) {
    final matches = [
      for (final m in cursor.take(size)) DocSearchMatch.from(m),
    ];
    final remaining = cursor.count;
    final done = remaining == 0;
    if (done) _cursors.remove(id);
    return DocSearchPage(
      cursorId: id,
      matches: matches,
      done: done,
      remaining: remaining,
    );
  }
}
