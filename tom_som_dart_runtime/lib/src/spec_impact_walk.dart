/// The impact walk — the starting table of a change's impact evaluation (the
/// change mode of the `tom_specs` process, Phase 0 step `impact`).
///
/// For a specification it lists **every** section of **every** document root
/// of the model, filled or not, and roots the project never created as well:
/// each row with its section-id chain, its model class, whether it holds
/// values, and its CodeSpecs routing. The change analyst gives each row a
/// verdict (*affected*, *needed*, *unaffected*); a table built from the model
/// rather than from the document is what makes "nothing the SOM covers is
/// missed" checkable. Beside it, [specImpactLevel] records how far the project
/// has come (documents, extracts, IR, tests, code).
///
/// Rows: one per class node (the root, each `complex` / `section` field, each
/// list item) and one per list (with its item count). An empty list of a class
/// element gets one **template** row `<list>/*` with the element's subtree
/// below it, so a section a new item would need shows its routing too. Value
/// leaves (content, form fields) are counted in their row, not rows of their
/// own. A class already on the branch is not entered again (the model is a
/// graph), exactly as the CodeSpecs routing walk cuts recursion. Below a
/// `@FollowUpKind` section every row carries that routing: the whole subtree is
/// delivered by the process, as the CodeSpecs extractor treats it.
///
/// Pure: it reads a model and documents and writes nothing. Finding the files
/// and probing folders is the caller's (`tomspecs :spec-impact-walk`, the
/// extension's `tomAi_specImpactWalk`). Port of `spec_impact_walk.ts` in
/// `tom_som_typescript_runtime`; pinned by
/// `tom_som_conformance/corpus/impact_walk_cases.json`.
library;

import 'spec_codespecs_extract.dart';
import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';

/// What a row of the walk stands for. Its [value] is the JSON spelling.
enum SpecImpactRowKind {
  /// The document root.
  root('root'),

  /// A `complex` field's class node.
  complex('complex'),

  /// A `section` field's class node.
  section('section'),

  /// A list field (its items are rows of their own).
  list('list'),

  /// One item of a list of class elements.
  item('item'),

  /// The element class of an empty list, at `<list>/*`: what a new item holds.
  template('template');

  /// The JSON spelling.
  final String value;

  /// A kind with its JSON spelling.
  const SpecImpactRowKind(this.value);
}

/// One row of the impact walk.
class SpecImpactRow {
  /// The document path; a template's subtree has `*` for the item segment.
  final String path;

  /// The section-id chain, outer first, joined by ` > ` (a list item by its
  /// stored id).
  final String chain;

  /// What the row stands for.
  final SpecImpactRowKind kind;

  /// The model class; for a list, its element class (`''` for a list of
  /// scalars).
  final String className;

  /// Nesting below the root (the root is 0).
  final int depth;

  /// Whether the document holds anything at or below the path
  /// ([SpecDocument.hasValuesUnder]).
  final bool filled;

  /// Stored values at or below the path: content leaves plus form-field values.
  final int values;

  /// A list's item count; `null` for every other row.
  final int? items;

  /// The CodeSpecs routing: of the class (a class row), of the element class
  /// (a list of classes), or of the field, else its enclosing class (a list of
  /// scalars) — `feedsCode`, `feedsProcess`, `feedsNothing`, `documentRoot`,
  /// `unrouted`. Below a `feedsProcess` section, that section's routing.
  final String routing;

  /// The routing's values verbatim (`CodeSpecPart` / `FollowUpProcess` /
  /// `NoArtifactReason` names).
  final List<String> routingValues;

  /// Where the routing marker is declared (`Class` or `Class.field`); `''`
  /// when none.
  final String routingDeclaredAt;

  /// Creates a row from the routing it carries.
  SpecImpactRow({
    required this.path,
    required this.chain,
    required this.kind,
    required this.className,
    required this.depth,
    required this.filled,
    required this.values,
    required this.items,
    required CodeSpecsRouting routing,
  }) : routing = routing.verdict.name,
       routingValues = List.unmodifiable(routing.values),
       routingDeclaredAt = routing.declaredAt;

  /// The row as JSON, in the conformance corpus's shape.
  Map<String, Object?> toJson() => {
    'path': path,
    'chain': chain,
    'kind': kind.value,
    'className': className,
    'depth': depth,
    'filled': filled,
    'values': values,
    'items': items,
    'routing': routing,
    'routingValues': routingValues,
    'routingDeclaredAt': routingDeclaredAt,
  };
}

/// The walk of one document root.
class SpecImpactRootWalk {
  /// The root's model type, e.g. `D00SolutionBlueprint`.
  final String type;

  /// The root's section id (its first path segment).
  final String sectionId;

  /// Whether the specification has this document; an absent root is walked
  /// over an empty document.
  final bool present;

  /// The rows, in walk order.
  final List<SpecImpactRow> rows;

  /// Creates the walk of one root.
  SpecImpactRootWalk(this.type, this.sectionId, this.present, this.rows);

  /// The root's walk as JSON.
  Map<String, Object?> toJson() => {
    'type': type,
    'sectionId': sectionId,
    'present': present,
    'rows': [for (final r in rows) r.toJson()],
  };
}

/// Walks every document root of [model], in model order: a root present in
/// [documents] (keyed by root type) over its document, any other over an empty
/// one. A document keyed by a type the model has no root for is refused
/// ([ArgumentError]).
List<SpecImpactRootWalk> specImpactWalk(
  SpecModel model,
  Map<String, SpecDocument> documents,
) {
  for (final type in documents.keys) {
    if (model.roots.every((r) => r.type != type)) {
      throw ArgumentError(
        'spec_impact_walk: the model has no document root $type',
      );
    }
  }
  final reflection = SpecReflection(model);
  return [
    for (final root in model.roots)
      SpecImpactRootWalk(
        root.type,
        reflection.rootSegment(root),
        documents.containsKey(root.type),
        _ImpactWalker(
          model,
          reflection,
          documents[root.type] ?? SpecDocument(),
        ).walkRoot(root),
      ),
  ];
}

class _ImpactWalker {
  final SpecModel model;
  final SpecReflection reflection;
  final SpecDocument doc;
  final List<SpecImpactRow> rows = [];

  /// Stored values per path prefix (a value counts at its own path and every
  /// ancestor).
  final Map<String, int> _counts = {};

  _ImpactWalker(this.model, this.reflection, this.doc) {
    for (final path in doc.contentPaths) {
      if (doc.content(path) != null) _count(path);
    }
    for (final path in doc.formPaths) {
      for (final field in doc.formFieldNames(path)) {
        if (doc.formField(path, field) != null) _count(path);
      }
    }
  }

  /// Adds one value at [path] to the path and each of its prefixes ending
  /// before `/` or `-`.
  void _count(String path) {
    void add(String p) => _counts[p] = (_counts[p] ?? 0) + 1;
    add(path);
    for (var i = path.length - 1; i > 0; i--) {
      if (path[i] == '/' || path[i] == '-') add(path.substring(0, i));
    }
  }

  List<SpecImpactRow> walkRoot(SpecRoot root) {
    final cls = model.classNamed(root.type);
    if (cls == null) return rows;
    final segment = reflection.rootSegment(root);
    _classNode(SpecImpactRowKind.root, segment, segment, cls, 0, {
      cls.name,
    }, null);
    return rows;
  }

  void _classNode(
    SpecImpactRowKind kind,
    String path,
    String chain,
    SpecClass cls,
    int depth,
    Set<String> ancestors,
    CodeSpecsRouting? process,
  ) {
    final template = path.contains('*');
    final routing = process ?? codeSpecsClassRouting(cls, path);
    final below = routing.verdict == CodeSpecsRoutingVerdict.feedsProcess
        ? routing
        : null;
    rows.add(
      SpecImpactRow(
        path: path,
        chain: chain,
        kind: kind,
        className: cls.name,
        depth: depth,
        filled: !template && doc.hasValuesUnder(path),
        values: template ? 0 : (_counts[path] ?? 0),
        items: null,
        routing: routing,
      ),
    );
    for (final field in cls.fields) {
      final segment = reflection.fieldSegment(field);
      final fieldPath = specPathJoin(path, segment);
      final fieldChain = '$chain > $segment';
      switch (field.kind) {
        case SpecFieldKind.complex:
        case SpecFieldKind.section:
          final type = field.type;
          if (type == null || ancestors.contains(type)) break;
          final child = model.classNamed(type);
          if (child == null) break;
          _classNode(
            field.kind == SpecFieldKind.complex
                ? SpecImpactRowKind.complex
                : SpecImpactRowKind.section,
            fieldPath,
            fieldChain,
            child,
            depth + 1,
            {...ancestors, child.name},
            below,
          );
        case SpecFieldKind.list:
          _list(cls, field, fieldPath, fieldChain, depth + 1, ancestors, below);
        default:
          break; // a value leaf: counted in this row
      }
    }
  }

  void _list(
    SpecClass owner,
    SpecField field,
    String path,
    String chain,
    int depth,
    Set<String> ancestors,
    CodeSpecsRouting? process,
  ) {
    final template = path.contains('*');
    final items = template ? const <String>[] : doc.listItems(path);
    final element = field.elementIsComplex
        ? model.classNamed(field.elementType)
        : null;
    final routing =
        process ??
        (element != null
            ? codeSpecsClassRouting(element, path)
            : codeSpecsFieldRouting(owner, field) ??
                  codeSpecsClassRouting(owner, path));
    rows.add(
      SpecImpactRow(
        path: path,
        chain: chain,
        kind: SpecImpactRowKind.list,
        className: element?.name ?? '',
        depth: depth,
        filled: !template && doc.hasValuesUnder(path),
        values: template ? 0 : (_counts[path] ?? 0),
        items: items.length,
        routing: routing,
      ),
    );
    if (element == null || ancestors.contains(element.name)) return;
    final next = {...ancestors, element.name};
    if (items.isEmpty) {
      _classNode(
        SpecImpactRowKind.template,
        '$path/*',
        '$chain > *',
        element,
        depth + 1,
        next,
        process,
      );
      return;
    }
    for (final itemPath in items) {
      final id =
          doc.itemSectionId(itemPath) ??
          itemPath.substring(itemPath.lastIndexOf('/') + 1);
      _classNode(
        SpecImpactRowKind.item,
        itemPath,
        '$chain > $id',
        element,
        depth + 1,
        next,
        process,
      );
    }
  }
}

// --- the project's level -----------------------------------------------------

/// A folder the caller passed for tests or code, and whether it exists.
class SpecImpactFolder {
  /// The folder as the caller gave it.
  final String path;

  /// Whether it exists.
  final bool present;

  /// Creates a folder entry.
  const SpecImpactFolder(this.path, this.present);

  /// The folder as JSON.
  Map<String, Object?> toJson() => {'path': path, 'present': present};
}

/// One document root of the level: whether the specification has it.
class SpecImpactLevelDocument {
  /// The root's model type.
  final String type;

  /// The root's section id.
  final String sectionId;

  /// Whether the specification has the document.
  final bool present;

  /// Creates a level document entry.
  const SpecImpactLevelDocument(this.type, this.sectionId, this.present);

  /// The entry as JSON.
  Map<String, Object?> toJson() => {
    'type': type,
    'sectionId': sectionId,
    'present': present,
  };
}

/// How far the project has come (impact_evaluation.md § Level).
class SpecImpactLevel {
  /// Every document root: whether the specification has it.
  final List<SpecImpactLevelDocument> documents;

  /// `phase1_project_idea/` holds a Markdown file.
  final bool projectIdea;

  /// `CE-*.extract.yaml` files in `generated-doc/codespecs_extracts/`.
  final int extracts;

  /// `generated-doc/codespecs_extracts/gate.verdicts.yaml` exists.
  final bool gateRecord;

  /// `*.ir.yaml` files in `irspecs/`.
  final int ir;

  /// Gate checklists and reports under `gates/` and `quality/evidence/gates/`.
  final List<String> gates;

  /// The test folders the caller passed; `null`: none given.
  final List<SpecImpactFolder>? tests;

  /// The code folders the caller passed; `null`: none given.
  final List<SpecImpactFolder>? code;

  /// The phases (1–6) the project has reached.
  final List<int> phasesReached;

  /// The phases (1–6) it has not, which a change leaves out (they run later in
  /// initial mode).
  final List<int> phasesLeftOut;

  /// Creates a level.
  const SpecImpactLevel({
    required this.documents,
    required this.projectIdea,
    required this.extracts,
    required this.gateRecord,
    required this.ir,
    required this.gates,
    required this.tests,
    required this.code,
    required this.phasesReached,
    required this.phasesLeftOut,
  });

  /// The level as JSON, in the conformance corpus's shape.
  Map<String, Object?> toJson() => {
    'documents': [for (final d in documents) d.toJson()],
    'projectIdea': projectIdea,
    'extracts': extracts,
    'gateRecord': gateRecord,
    'ir': ir,
    'gates': gates,
    'tests': tests == null ? null : [for (final t in tests!) t.toJson()],
    'code': code == null ? null : [for (final c in code!) c.toJson()],
    'phasesReached': phasesReached,
    'phasesLeftOut': phasesLeftOut,
  };
}

String _normalised(String p) {
  final slashed = p.replaceAll(r'\', '/');
  return slashed.startsWith('./') ? slashed.substring(2) : slashed;
}

/// The project's level from the walk and a listing of the spec root (paths
/// relative to it, `/`-separated). Phase 2 is reached when the root with
/// section id `SBP` is present, Phase 3 when any other root is that is not a
/// generation input, Phase 4 when extracts or IR exist, Phases 5 and 6 when a
/// test or code folder the caller passed exists. Phases 7–8 (acceptance,
/// deployment) are not visible on disk and are not reported.
SpecImpactLevel specImpactLevel(
  SpecModel model,
  List<SpecImpactRootWalk> walk,
  List<String> listing,
  List<SpecImpactFolder>? tests,
  List<SpecImpactFolder>? code,
) {
  final files = listing.map(_normalised).toList();
  final projectIdea = files.any(
    (f) => RegExp(r'^phase1_[^/]*/[^/]+\.md$').hasMatch(f),
  );
  final extracts = files
      .where(
        (f) => RegExp(
          r'^generated-doc/codespecs_extracts/CE-[^/]+\.extract\.yaml$',
        ).hasMatch(f),
      )
      .length;
  final gateRecord = files.contains(
    'generated-doc/codespecs_extracts/gate.verdicts.yaml',
  );
  final ir = files
      .where((f) => RegExp(r'^irspecs/[^/]+\.ir\.yaml$').hasMatch(f))
      .length;
  final gates =
      files
          .where(
            (f) =>
                RegExp(r'^gates/G[^/]*\.checklist\.yaml$').hasMatch(f) ||
                RegExp(r'^quality/evidence/gates/[^/]+\.md$').hasMatch(f),
          )
          .toList()
        ..sort();
  bool present(bool Function(SpecRoot root) test) => walk.any((w) {
    final root = model.roots.where((r) => r.type == w.type).firstOrNull;
    return w.present && root != null && test(root);
  });
  final reached = <int>[
    if (projectIdea) 1,
    if (present((r) => r.sectionId == 'SBP')) 2,
    if (present((r) => r.sectionId != 'SBP' && !model.isGenerationInput(r))) 3,
    if (extracts > 0 || ir > 0) 4,
    if (tests != null && tests.any((t) => t.present)) 5,
    if (code != null && code.any((c) => c.present)) 6,
  ];
  return SpecImpactLevel(
    documents: [
      for (final w in walk)
        SpecImpactLevelDocument(w.type, w.sectionId, w.present),
    ],
    projectIdea: projectIdea,
    extracts: extracts,
    gateRecord: gateRecord,
    ir: ir,
    gates: gates,
    tests: tests,
    code: code,
    phasesReached: reached,
    phasesLeftOut: [
      for (final p in [1, 2, 3, 4, 5, 6])
        if (!reached.contains(p)) p,
    ],
  );
}

/// The specification's current documents in a listing of the spec root: the
/// `*.docspecs.yaml` files directly in a `phase*` folder. The numbered step
/// folders below hold round copies and are not the specification.
List<String> specImpactDocumentFiles(List<String> listing) =>
    listing
        .map(_normalised)
        .where((f) => RegExp(r'^phase[^/]*/[^/]+\.docspecs\.yaml$').hasMatch(f))
        .toList()
      ..sort();

// --- the Markdown table ------------------------------------------------------

String _cell(String text) => text.replaceAll('|', r'\|');

/// The walk as Markdown, for a round folder's `walk/` (one table per root,
/// then § Level): the table the change analyst gives verdicts to.
String specImpactWalkMarkdown(
  List<SpecImpactRootWalk> walk,
  SpecImpactLevel? level,
) {
  final out = <String>['# Impact walk', ''];
  out.addAll([
    'Every section of every document root, filled or not: the section-id '
        'chain, the model class, whether it holds values, and its CodeSpecs '
        'routing. A list counts its items; an empty list of sections shows what '
        'a new item holds at `<list>/*`.',
    '',
  ]);
  for (final root in walk) {
    final filled = root.rows.where((r) => r.filled).length;
    out.addAll([
      '## ${root.sectionId} — ${root.type}${root.present ? '' : ' (absent)'}',
      '',
      '${root.rows.length} rows, $filled holding values.',
      '',
      '| Section-id chain | Path | Kind | Class | Values | Items | Routing |',
      '| --- | --- | --- | --- | --- | --- | --- |',
    ]);
    for (final r in root.rows) {
      final routing = r.routingValues.isNotEmpty
          ? '${r.routing}: ${r.routingValues.join(', ')}'
          : r.routing;
      out.add(
        '| ${_cell(r.chain)} | `${_cell(r.path)}` | ${r.kind.value} | '
        '${_cell(r.className)} | ${r.filled ? r.values : '—'} | '
        '${r.items ?? ''} | ${_cell(routing)} |',
      );
    }
    out.add('');
  }
  if (level != null) {
    String yes(bool b) => b ? 'yes' : 'no';
    String folders(List<SpecImpactFolder>? f) => f == null
        ? 'not given'
        : f.isEmpty
        ? 'none'
        : f
              .map((x) => '`${x.path}` (${x.present ? 'present' : 'absent'})')
              .join(', ');
    String ids(bool present) {
      final list = [
        for (final d in level.documents)
          if (d.present == present) d.sectionId,
      ];
      return list.isEmpty ? 'none' : list.join(', ');
    }

    out.addAll([
      '## Level',
      '',
      '- Documents present: ${ids(true)}',
      '- Documents absent: ${ids(false)}',
      '- Project Idea: ${yes(level.projectIdea)}',
      '- CodeSpecs extracts: ${level.extracts}; gate record: ${yes(level.gateRecord)}',
      '- IR Specs: ${level.ir}',
      '- Gates: ${level.gates.isNotEmpty ? level.gates.map((g) => '`$g`').join(', ') : 'none'}',
      '- Tests: ${folders(level.tests)}',
      '- Code: ${folders(level.code)}',
      '- Phases reached: ${level.phasesReached.isEmpty ? 'none' : level.phasesReached.join(', ')}; '
          'left out by a change: ${level.phasesLeftOut.isEmpty ? 'none' : level.phasesLeftOut.join(', ')} '
          '(Phases 7–8 are not visible on disk)',
      '',
    ]);
  }
  return out.join('\n');
}
