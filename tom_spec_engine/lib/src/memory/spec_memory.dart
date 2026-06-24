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
        MemoryConfig,
        MultiRecallQuery,
        NodeDraft,
        RecallMode,
        RecallSeed,
        Scope,
        Vec;

import 'memory_scope.dart';

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

  SpecDocumentMemory._({
    required this.scope,
    required SqliteTomBrainMemory store,
    required SpecEmbedder embedder,
  })  : _store = store,
        _embedder = embedder;

  /// The producer stamp on every node this engine writes.
  static const Scope _producer = Scope(producer: 'tom_spec_engine');

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
}
