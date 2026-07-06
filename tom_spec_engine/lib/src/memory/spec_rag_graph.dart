/// The **pure** section-level RAG graph behind the §9.1 RAG store (plan
/// step 10).
///
/// Chunk = section: one section-id path produces one [SpecRagNode]. The node's
/// payload is **rendered text + structural metadata** — the text a retriever
/// embeds, prefixed with the section's identity (path, section id, kind, class)
/// so a recalled node is self-describing. Edges mirror the document tree
/// (`part_of`, [SpecRagEdgeKind.tree]) plus the `@MapsTo` / `@DetailedIn`
/// projections (`mentions`, [SpecRagEdgeKind.mapsTo] / [SpecRagEdgeKind.detailedIn]).
///
/// This is the **build** half: it takes [SpecNodeProjection]s (the §6 object
/// model walk produced in step 9) and assembles nodes + edges with **zero I/O
/// and zero model (LLM) calls**. The persist-into-Tom-Brain + recall half lives
/// in `spec_memory.dart` (`SpecDocumentMemory.indexDocument` / `recallSections`),
/// which consumes a [SpecRagGraph] built here.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// How one section relates to another in the RAG graph.
enum SpecRagEdgeKind {
  /// Structural membership — a child section is `part_of` its parent
  /// (`d4rt_and_llm_tools.md` §9.1 "edges mirror the tree").
  tree,

  /// A `@MapsTo` projection — the source class declares it maps to the
  /// target section (a `mentions` reference).
  mapsTo,

  /// A `@DetailedIn` projection — the source class declares it is detailed
  /// in the target section (a `mentions` reference).
  detailedIn,
}

/// One section node in the RAG graph: a section-id path plus the rendered text
/// and structural metadata a retriever indexes.
final class SpecRagNode {
  /// The section-id path that uniquely identifies the section (and the node).
  final String path;

  /// The section's `@SectionId` (`null` for synthetic / unlabelled nodes).
  final String? sectionId;

  /// The node kind from the object-model projection.
  final SpecNodeKind kind;

  /// The model class the node *is* (`null` for leaves / containers).
  final String? classId;

  /// The doc-comment / label headline (`null` when none).
  final String? headline;

  /// The structural parent's path (`null` for the document root).
  final String? parentPath;

  /// The `@MapsTo` target section id declared on the node's class (`null` when
  /// none).
  final String? mapsTo;

  /// The `@DetailedIn` target section id declared on the node's class (`null`
  /// when none).
  final String? detailedIn;

  /// The rendered text a retriever embeds: a metadata header (path, section id,
  /// kind, class, headline) followed by the section's searchable content.
  final String text;

  const SpecRagNode({
    required this.path,
    required this.sectionId,
    required this.kind,
    required this.classId,
    required this.headline,
    required this.parentPath,
    required this.mapsTo,
    required this.detailedIn,
    required this.text,
  });

  @override
  String toString() => 'SpecRagNode($path, ${kind.name})';
}

/// One directed edge between two section nodes.
final class SpecRagEdge {
  /// The source section's path.
  final String fromPath;

  /// The destination section's path.
  final String toPath;

  /// What the edge represents.
  final SpecRagEdgeKind kind;

  const SpecRagEdge({
    required this.fromPath,
    required this.toPath,
    required this.kind,
  });

  @override
  String toString() => 'SpecRagEdge($fromPath --${kind.name}--> $toPath)';
}

/// The assembled section-level RAG graph for one document: a node per section
/// and the tree + projection edges between them.
final class SpecRagGraph {
  /// The section nodes, in projection (document) order.
  final List<SpecRagNode> nodes;

  /// The directed edges: tree membership plus resolved projections.
  final List<SpecRagEdge> edges;

  const SpecRagGraph({required this.nodes, required this.edges});

  /// Builds the graph from a document's [SpecNodeProjection]s (the whole
  /// structural closure produced by `SpecQueryEngine.projectNodes`).
  ///
  /// Tree edges connect every non-root node to its structural parent. A
  /// `@MapsTo` / `@DetailedIn` projection becomes a `mentions` edge **only when
  /// the target section id resolves to a node in this document** — a
  /// cross-document target (the common case for a single open spec) is left
  /// unlinked rather than dangling, since the §9.1 named memory is per-document.
  factory SpecRagGraph.fromProjections(Iterable<SpecNodeProjection> projections) {
    final list = projections.toList(growable: false);
    final paths = {for (final p in list) p.path};

    // First section id wins: the resolution target for a projection edge.
    final sectionIdToPath = <String, String>{};
    for (final p in list) {
      final id = p.sectionId;
      if (id != null) {
        sectionIdToPath.putIfAbsent(id, () => p.path);
      }
    }

    final nodes = <SpecRagNode>[];
    final edges = <SpecRagEdge>[];

    for (final p in list) {
      final parent = _parentOf(p.path, paths);
      nodes.add(SpecRagNode(
        path: p.path,
        sectionId: p.sectionId,
        kind: p.kind,
        classId: p.classId,
        headline: p.headline,
        parentPath: parent,
        mapsTo: p.mapsTo,
        detailedIn: p.detailedIn,
        text: _renderText(p),
      ));

      if (parent != null) {
        edges.add(SpecRagEdge(
          fromPath: p.path,
          toPath: parent,
          kind: SpecRagEdgeKind.tree,
        ));
      }

      _addProjectionEdge(
        edges, p.path, p.mapsTo, sectionIdToPath, SpecRagEdgeKind.mapsTo);
      _addProjectionEdge(
        edges, p.path, p.detailedIn, sectionIdToPath, SpecRagEdgeKind.detailedIn);
    }

    return SpecRagGraph(nodes: nodes, edges: edges);
  }

  static void _addProjectionEdge(
    List<SpecRagEdge> edges,
    String fromPath,
    String? targetSectionId,
    Map<String, String> sectionIdToPath,
    SpecRagEdgeKind kind,
  ) {
    if (targetSectionId == null) return;
    final toPath = sectionIdToPath[targetSectionId];
    if (toPath == null || toPath == fromPath) return;
    edges.add(SpecRagEdge(fromPath: fromPath, toPath: toPath, kind: kind));
  }

  /// Derives a node's structural parent path from the path string.
  ///
  /// A list-item segment ends with `-<n>`; its container is the path with that
  /// suffix removed (`SBP/RSK-1` → `SBP/RSK`). Every other node's parent is
  /// the path up to the last `/`. A candidate that is not itself a projected
  /// node is treated as no parent (the root, or a gap in the projection).
  static String? _parentOf(String path, Set<String> all) {
    final listItem = _listItemSuffix.firstMatch(path);
    if (listItem != null) {
      final container = listItem.group(1)!;
      if (all.contains(container)) return container;
    }
    final slash = path.lastIndexOf('/');
    if (slash < 0) return null;
    final parent = path.substring(0, slash);
    return all.contains(parent) ? parent : null;
  }

  /// Renders a section's text: a deterministic metadata header followed by its
  /// searchable content, so a recalled node is self-describing.
  static String _renderText(SpecNodeProjection p) {
    final header = StringBuffer('[${p.sectionId ?? p.kind.name}] ${p.path}');
    if (p.classId != null) header.write(' (${p.classId})');
    if (p.headline != null && p.headline!.isNotEmpty) {
      header.write(' — ${p.headline}');
    }
    final body = p.searchableStrings.where((s) => s.isNotEmpty).join('\n');
    return body.isEmpty ? header.toString() : '$header\n$body';
  }

  static final RegExp _listItemSuffix = RegExp(r'^(.*)-\d+$');
}
