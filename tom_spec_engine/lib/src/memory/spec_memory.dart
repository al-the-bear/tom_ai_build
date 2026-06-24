/// The engine-side Tom Brain memory façade (plan step 2).
///
/// A thin wrapper over the **embeddable** Tom Brain memory plane
/// (`SqliteTomBrainMemory` + its profile registry + the bundled sqlite-vec
/// vector index) that runs **in-process** — no client/server split, no
/// external provisioning. It establishes the TomSpecs addressing convention
/// ([MemoryScope]) and exposes the three operations the higher steps build on:
/// **embed** a string, **remember** it, and **recall** it.
///
/// Scope of step 2 (deliberately narrow — see `d4rt_and_llm_tools_decisions.md`):
///   * The embedding surface is an injected [SpecEmbedder]; the provider-backed
///     Tom Brain embedding API is wired in at the tier-2 vector step (step 11).
///   * Remembered text is carried on the bootstrap `Event` node type; the
///     section-level RAG node schema lands at step 10.
///   * The LLM substrate (`tom_brain_substrate`) is not pulled in — the memory
///     store takes the embedder directly, keeping the heavy provider/router
///     composition root out until the agent steps (15–17).
library;

import 'package:tom_brain_memory/tom_brain_memory.dart'
    show SqliteTomBrainMemory;
import 'package:tom_brain_shared/tom_brain_shared.dart'
    show
        DiversityPolicy,
        DiversityStrategy,
        EdgeDirection,
        EdgeType,
        ForgetReason,
        MemoryConfig,
        MultiRecallQuery,
        NodeDraft,
        NodeId,
        RecallMode,
        RecallSeed,
        Scope,
        Vec;

import 'memory_scope.dart';
import 'spec_rag_graph.dart';

export 'package:tom_brain_shared/tom_brain_shared.dart' show Vec;

export 'memory_scope.dart';

/// Produces an embedding for [text]. The façade's embedding surface and the
/// vector seed the store embeds a recall query with both route through one of
/// these, so persist-time and recall-time embeddings always agree.
typedef SpecEmbedder = Future<Vec> Function(String text);

/// One item recalled from a document's memory.
final class RememberedItem {
  /// The remembered text (the carrier node's `summary`).
  final String text;

  const RememberedItem({required this.text});

  @override
  String toString() => 'RememberedItem(${_preview(text)})';

  static String _preview(String s) =>
      s.length <= 48 ? s : '${s.substring(0, 45)}...';
}

/// What [SpecDocumentMemory.indexDocument] wrote: the section nodes persisted
/// and the tree/projection edges linked.
final class SpecRagIndexResult {
  /// Section nodes persisted (one per [SpecRagNode]).
  final int nodeCount;

  /// Edges linked (tree + resolved projections).
  final int edgeCount;

  const SpecRagIndexResult({required this.nodeCount, required this.edgeCount});

  @override
  String toString() =>
      'SpecRagIndexResult(nodes: $nodeCount, edges: $edgeCount)';
}

/// What [SpecDocumentMemory.indexChangedSections] did: how many sections were
/// re-embedded, how many edges were re-linked, and how many sections were
/// dropped. The headline figure is [embedded] — the **embed-changed-only**
/// guarantee of §9.2: a changed section whose content hash is unchanged is
/// skipped, so [embedded] counts only the sections that actually moved.
final class SpecRagRefreshResult {
  /// Sections re-embedded and re-persisted (content actually changed).
  final int embedded;

  /// Sections skipped because their content hash was unchanged.
  final int unchanged;

  /// Edges (re-)linked for the touched sections.
  final int edgeCount;

  /// Sections forgotten (removed from memory).
  final int removed;

  const SpecRagRefreshResult({
    required this.embedded,
    required this.unchanged,
    required this.edgeCount,
    required this.removed,
  });

  @override
  String toString() => 'SpecRagRefreshResult(embedded: $embedded, '
      'unchanged: $unchanged, edges: $edgeCount, removed: $removed)';
}

/// One section recalled from a document's RAG memory.
final class SpecRagHit {
  /// The section-id path of the recalled section.
  final String path;

  /// The rendered section text (metadata header + content).
  final String text;

  const SpecRagHit({required this.path, required this.text});

  @override
  String toString() => 'SpecRagHit($path)';
}

/// One persisted RAG edge, read back with its endpoints mapped to section
/// paths. The closed-alphabet [EdgeType] collapses to [partOf] (`part_of`,
/// the tree) versus a `mentions` projection — the original
/// `@MapsTo`/`@DetailedIn` distinction is not separable on read-back, since
/// both project to the same `mentions` label.
final class SpecRagStoredEdge {
  /// The destination section's path.
  final String toPath;

  /// Whether the edge is a `part_of` tree edge (`false` = a `mentions`
  /// projection edge).
  final bool partOf;

  const SpecRagStoredEdge({required this.toPath, required this.partOf});

  @override
  String toString() =>
      'SpecRagStoredEdge(--${partOf ? 'part_of' : 'mentions'}--> $toPath)';
}

/// In-process, profile-isolated Tom Brain memory for the TomSpecs engine.
///
/// One instance owns a `<memory-root>` and an [SpecEmbedder]; each distinct
/// [MemoryScope.document] is opened as an isolated Tom Brain profile via
/// [openDocument]. Open document handles are cached and closed by [close].
final class SpecMemory {
  /// Root directory of the Tom Brain memory store (`<memory-root>`). Each
  /// document profile lives under `<memory-root>/profiles/<document>/`.
  final String memoryRoot;

  /// Directory holding the platform-tupled sqlite-vec (vec0) binaries
  /// (`<…>/tom_binaries/sqlite_vec`). Passed to Tom Brain so the bundled
  /// vector index loads in-process without external provisioning.
  final String sqliteVecBinariesRoot;

  final SpecEmbedder _embedder;
  final Map<String, SpecDocumentMemory> _open = <String, SpecDocumentMemory>{};
  bool _closed = false;

  SpecMemory({
    required this.memoryRoot,
    required this.sqliteVecBinariesRoot,
    required SpecEmbedder embedder,
  }) : _embedder = embedder;

  /// The façade's embedding surface (step 2). Delegates to the injected
  /// embedder; step 11 swaps in the Tom Brain substrate embedding API.
  Future<Vec> embed(String text) => _embedder(text);

  /// Opens (materialising on first use) the profile-isolated memory for
  /// [scope]'s document and returns a handle bound to it. Re-opening the same
  /// document returns the cached handle.
  Future<SpecDocumentMemory> openDocument(MemoryScope scope) async {
    _ensureOpen();
    final cached = _open[scope.profileName];
    if (cached != null) return cached;

    final store = SqliteTomBrainMemory(
      // The store embeds a recall query that carries only text through this
      // same embedder, so persist-time and recall-time vectors agree.
      embedder: _embedder,
    );
    await store.open(
      MemoryConfig.forTesting(
        root: memoryRoot,
        binariesRoot: sqliteVecBinariesRoot,
      ).withProfile(scope.profileName),
    );
    final handle = SpecDocumentMemory._(
      scope: scope,
      store: store,
      embedder: _embedder,
    );
    _open[scope.profileName] = handle;
    return handle;
  }

  /// Closes every open document handle. Idempotent.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final handle in _open.values) {
      await handle._store.close();
    }
    _open.clear();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('SpecMemory has been closed');
    }
  }
}

/// A handle bound to one document's profile-isolated Tom Brain memory.
///
/// Obtained from [SpecMemory.openDocument]; its lifecycle is owned by the
/// parent [SpecMemory] (closed by [SpecMemory.close]).
final class SpecDocumentMemory {
  /// The scope this handle is bound to.
  final MemoryScope scope;

  final SqliteTomBrainMemory _store;
  final SpecEmbedder _embedder;

  /// Section path → persisted node id, populated by [indexDocument]. Lets
  /// [edgesFrom] resolve a section path back to its Tom Brain node.
  final Map<String, NodeId> _nodeIdByPath = <String, NodeId>{};

  /// Persisted node id (string form) → section path — the inverse of
  /// [_nodeIdByPath], so a read-back edge's endpoints map to section paths.
  final Map<String, String> _pathByNodeId = <String, String>{};

  /// Section path → the content hash last embedded for it. Lets
  /// [indexChangedSections] honour the **embed-changed-only** rule (§9.2): a
  /// section whose content hash is unchanged is skipped, never re-embedded.
  final Map<String, String> _contentHashByPath = <String, String>{};

  SpecDocumentMemory._({
    required this.scope,
    required SqliteTomBrainMemory store,
    required SpecEmbedder embedder,
  })  : _store = store,
        _embedder = embedder;

  /// The producer stamp on every node this engine writes.
  static const Scope _producer = Scope(producer: 'tom_spec_engine');

  /// The built-in Tom Brain node type used for a spec section. `Concept`
  /// already permits exactly the edges §9.1 needs — `part_of` (the tree) and
  /// `mentions` (the `@MapsTo`/`@DetailedIn` projections) — on both its
  /// `allowedOutgoing` and `allowedIncoming` sets, so no custom node type has
  /// to be registered.
  static const String _sectionType = 'Concept';

  /// Embeds [text] through the same embedder the store recalls with.
  Future<Vec> embed(String text) => _embedder(text);

  /// Remembers [text] in this document's memory, embedding it so it is
  /// recoverable by both lexical (BM25) and vector recall.
  ///
  /// [metadata] is carried on the node's `payload`. The text is stored on the
  /// bootstrap `Event` carrier for step 2; the section-level RAG schema lands
  /// at step 10.
  Future<void> remember(
    String text, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final embedding = await _embedder(text);
    await _store.persist(
      NodeDraft(
        typeName: 'Event',
        values: <String, Object?>{
          'summary': text,
          'payload': metadata,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
        },
        embedding: embedding,
      ),
      scope: _producer,
    );
  }

  /// Recalls items matching [query] from this document's memory via the vector
  /// index (the store embeds [query] through the shared embedder). Returns at
  /// most [k] items, highest-ranked first.
  Future<List<RememberedItem>> recall(String query, {int k = 10}) async {
    final result = await _store.recallMulti(
      MultiRecallQuery(
        seeds: <RecallSeed>[
          RecallSeed(mode: RecallMode.vector, text: query, k: k),
        ],
        k: k,
        diversity: const DiversityPolicy(strategy: DiversityStrategy.off),
      ),
    );
    return result.nodes
        .map((node) => RememberedItem(text: node.values['summary'] as String))
        .toList(growable: false);
  }

  /// Indexes a document's section-level RAG [graph] into this document's named
  /// memory (plan step 10, §9.1): each [SpecRagNode] is persisted as a
  /// [_sectionType] node (`name` = section path, `description` = rendered text),
  /// embedded so it is recoverable by vector recall, then each [SpecRagEdge] is
  /// linked (`part_of` for the tree, `mentions` for projections).
  ///
  /// Idempotent: nodes carry a **content-addressed** idempotency key
  /// (`rag-node:<path>:<hash>`) and edges a **node-id-addressed** key, so
  /// re-indexing an unchanged document is a no-op that reuses the existing rows.
  Future<SpecRagIndexResult> indexDocument(SpecRagGraph graph) async {
    for (final node in graph.nodes) {
      await _persistSection(node);
    }
    final edgeCount = await _linkEdges(graph.edges);
    return SpecRagIndexResult(
      nodeCount: graph.nodes.length,
      edgeCount: edgeCount,
    );
  }

  /// Incrementally refreshes this document's RAG memory (plan step 11, §9.2):
  /// re-embeds **only** the sections in [changedPaths] whose content actually
  /// moved, forgets the sections in [removedPaths], and re-links the edges that
  /// touch any of them.
  ///
  /// This is the **embed-changed-only** path that feeds the tier-2 vector store
  /// after each prompt: a changed section whose rendered text hashes to the same
  /// value it last embedded is skipped (no model/embedding call), a section
  /// whose content moved is forgotten and re-persisted under a fresh
  /// content-addressed key, and a removed section is forgotten outright. Never a
  /// full re-embed — sections not named here are left exactly as they are.
  ///
  /// [graph] is the document's *current* RAG graph (post-edit); it supplies the
  /// new node text for the changed sections and the edge set to re-link. A
  /// `changedPath` absent from [graph] is treated as a removal.
  Future<SpecRagRefreshResult> indexChangedSections(
    SpecRagGraph graph, {
    Iterable<String> changedPaths = const <String>[],
    Iterable<String> removedPaths = const <String>[],
  }) async {
    final nodeByPath = <String, SpecRagNode>{
      for (final node in graph.nodes) node.path: node,
    };

    var removed = 0;
    for (final path in removedPaths) {
      if (await _forgetSection(path)) removed++;
    }

    final touched = <String>{};
    var embedded = 0;
    var unchanged = 0;
    for (final path in changedPaths) {
      final node = nodeByPath[path];
      if (node == null) {
        // Named as changed but gone from the current graph — treat as a removal.
        if (await _forgetSection(path)) removed++;
        continue;
      }
      if (_contentHashByPath[path] == _contentHash(node.text)) {
        unchanged++;
        continue;
      }
      // Content moved: drop the stale row, then persist a fresh one. The fresh
      // node id makes every edge that touches this section re-link below.
      await _forgetSection(path);
      await _persistSection(node);
      touched.add(path);
      embedded++;
    }

    // Re-link only the edges that touch a section whose node id just changed;
    // edges between untouched sections keep their node ids and so their keys.
    final edgeCount = await _linkEdges(
      graph.edges.where(
        (e) => touched.contains(e.fromPath) || touched.contains(e.toPath),
      ),
    );

    return SpecRagRefreshResult(
      embedded: embedded,
      unchanged: unchanged,
      edgeCount: edgeCount,
      removed: removed,
    );
  }

  /// Embeds [node]'s text and persists it as a section node under a
  /// content-addressed idempotency key, updating the path/id/hash tracking.
  Future<void> _persistSection(SpecRagNode node) async {
    final hash = _contentHash(node.text);
    final embedding = await _embedder(node.text);
    final id = await _store.persist(
      NodeDraft(
        typeName: _sectionType,
        values: <String, Object?>{
          'name': node.path,
          'description': node.text,
        },
        embedding: embedding,
      ),
      scope: Scope(
        producer: _producer.producer,
        idempotencyKey: 'rag-node:${node.path}:$hash',
      ),
    );
    _nodeIdByPath[node.path] = id;
    _pathByNodeId[id.toString()] = node.path;
    _contentHashByPath[node.path] = hash;
  }

  /// Forgets the section at [path] (the only row-deletion path), dropping its
  /// path/id/hash tracking. Returns whether a tracked node was forgotten.
  Future<bool> _forgetSection(String path) async {
    final id = _nodeIdByPath.remove(path);
    _contentHashByPath.remove(path);
    if (id == null) return false;
    _pathByNodeId.remove(id.toString());
    await _store.forget(id, ForgetReason.userRequested);
    return true;
  }

  /// Links each [edges] entry whose endpoints are both currently tracked, under
  /// a node-id-addressed idempotency key (so unchanged edges no-op and edges
  /// touching a re-persisted node get a fresh key). Returns the count linked.
  Future<int> _linkEdges(Iterable<SpecRagEdge> edges) async {
    var edgeCount = 0;
    for (final edge in edges) {
      final from = _nodeIdByPath[edge.fromPath];
      final to = _nodeIdByPath[edge.toPath];
      // A missing endpoint means the section was not (re-)persisted; skip
      // defensively rather than throw mid-link.
      if (from == null || to == null) continue;
      await _store.edge(
        from,
        _edgeTypeOf(edge.kind),
        to,
        scope: Scope(
          producer: _producer.producer,
          idempotencyKey: 'rag-edge:${edge.kind.name}:$from->$to',
        ),
      );
      edgeCount++;
    }
    return edgeCount;
  }

  /// A stable 63-bit FNV-1a content hash (hex) for the embed-changed-only
  /// guard. Content-addresses a section node so unchanged content reuses its
  /// row while a content edit yields a fresh key.
  static String _contentHash(String text) {
    var hash = 0xcbf29ce484222325; // FNV-1a 64-bit offset basis.
    const prime = 0x100000001b3;
    for (final unit in text.codeUnits) {
      hash = (hash ^ unit) * prime;
    }
    return (hash & 0x7fffffffffffffff).toRadixString(16);
  }

  /// Recalls the sections most relevant to [query] from this document's RAG
  /// memory via the vector index (the store embeds [query] through the shared
  /// embedder). Returns at most [k] sections, highest-ranked first.
  Future<List<SpecRagHit>> recallSections(String query, {int k = 10}) async {
    final result = await _store.recallMulti(
      MultiRecallQuery(
        seeds: <RecallSeed>[
          RecallSeed(mode: RecallMode.vector, text: query, k: k),
        ],
        k: k,
        diversity: const DiversityPolicy(strategy: DiversityStrategy.off),
      ),
    );
    return result.nodes
        .where((node) => node.typeName == _sectionType)
        .map((node) => SpecRagHit(
              path: node.values['name'] as String,
              text: node.values['description'] as String,
            ))
        .toList(growable: false);
  }

  /// Returns the outgoing RAG edges of the section at [path] (the edges this
  /// section *emits*), with endpoints mapped back to section paths. Returns an
  /// empty list when [path] was not indexed.
  Future<List<SpecRagStoredEdge>> edgesFrom(String path) async {
    final id = _nodeIdByPath[path];
    if (id == null) return const <SpecRagStoredEdge>[];
    final edges = await _store.edgesOf(id, direction: EdgeDirection.outgoing);
    final out = <SpecRagStoredEdge>[];
    for (final edge in edges) {
      final toPath = _pathByNodeId[edge.to.toString()];
      if (toPath == null) continue;
      out.add(SpecRagStoredEdge(
        toPath: toPath,
        partOf: edge.type == EdgeType.partOf,
      ));
    }
    return out;
  }

  static EdgeType _edgeTypeOf(SpecRagEdgeKind kind) => switch (kind) {
        SpecRagEdgeKind.tree => EdgeType.partOf,
        SpecRagEdgeKind.mapsTo => EdgeType.mentions,
        SpecRagEdgeKind.detailedIn => EdgeType.mentions,
      };
}
