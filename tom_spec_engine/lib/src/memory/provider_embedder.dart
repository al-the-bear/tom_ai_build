/// Provider-backed embedder for the tier-2 RAG vector store
/// (`llm_and_d4rt_tools.md` §9.2).
///
/// Wraps the Tom Brain substrate's [EmbeddingService] so the engine's memory
/// plane embeds through a real model (Ollama `nomic-embed-text` by default,
/// 768 dims, L2-normalised) instead of the editor's deterministic hash
/// placeholder. Exposes the two engine embedding surfaces — a per-text
/// [SpecEmbedder] and a bulk [SpecBatchEmbedder] — so a full-document index
/// issues one concurrency-capped fan-out (`embedBatch`) while recall-query and
/// incremental re-embed paths use the single-text call.
///
/// **Identity discipline.** Both surfaces produce vectors under the same
/// [EmbeddingModelIdentity] ([identity]); never mix this embedder's vectors
/// with another model's in one store (cosine math across identities is
/// meaningless — see `memory_specification.md` § 7.4). The consumer picks the
/// embedder **once** at boot via [probe] and keeps it for the store's lifetime;
/// it must not fall back to a different embedder per call.
///
/// The engine owns this adapter (and the substrate dependency) so the editor
/// needs only `tom_spec_engine` to wire provider-backed embeddings.
library;

import 'package:tom_brain_substrate/tom_brain_substrate.dart'
    show
        EmbeddingModelIdentity,
        EmbeddingProbeResult,
        EmbeddingResult,
        EmbeddingService,
        OllamaEmbeddingService,
        OllamaLlmProvider;

import 'spec_memory.dart' show SpecBatchEmbedder, SpecEmbedder;

// Re-export the value types a consumer needs to reason about identity / drift
// and the abstract contract a test fake implements, so the editor and tests
// bind against `tom_spec_engine` without a direct substrate import.
export 'package:tom_brain_substrate/tom_brain_substrate.dart'
    show
        EmbeddingModelIdentity,
        EmbeddingProbeResult,
        EmbeddingResult,
        EmbeddingService;

/// Adapts a Tom Brain [EmbeddingService] to the engine's embedding surfaces.
///
/// Construct directly from any [EmbeddingService] (tests pass a fake), or via
/// [SpecProviderEmbedder.ollama] for the prototype default backend. The adapter
/// does **not** open a network connection at construction — the first
/// reachability check happens when the consumer calls [probe].
final class SpecProviderEmbedder {
  /// The wrapped substrate embedding service. Owned by this adapter; [close]
  /// closes it (and, for the [SpecProviderEmbedder.ollama] factory, the
  /// provider it built).
  final EmbeddingService service;

  /// Extra teardown the factory registers (e.g. closing the Ollama provider the
  /// service composes over but does not own). `null` for the direct
  /// constructor, where the caller owns the service's collaborators.
  final Future<void> Function()? _onClose;

  SpecProviderEmbedder(this.service) : _onClose = null;

  SpecProviderEmbedder._({
    required this.service,
    required Future<void> Function()? onClose,
  }) : _onClose = onClose;

  /// Prototype-default adapter backed by Ollama's `/api/embeddings`.
  ///
  /// Builds an [OllamaLlmProvider] pointed at [baseUri] (default the local
  /// daemon) and an [OllamaEmbeddingService] for [model] ([dims] dimensions,
  /// L2-normalised when [normalize]). [batchConcurrency] caps the `embedBatch`
  /// fan-out (substrate default 4). Nothing connects until [probe] / [embedder]
  /// runs.
  factory SpecProviderEmbedder.ollama({
    Uri? baseUri,
    String providerId = 'ollama:local',
    String model = 'nomic-embed-text',
    int dims = 768,
    bool normalize = true,
    int batchConcurrency = 4,
  }) {
    final provider = OllamaLlmProvider(
      id: providerId,
      baseUri: baseUri ?? Uri.parse('http://127.0.0.1:11434/'),
      // The embedding model is sent per-call; the chat default is unused on the
      // embedding path but the provider requires one. Reuse the embed model so
      // the provider carries no stray second model id.
      defaultModel: model,
    );
    final service = OllamaEmbeddingService(
      provider: provider,
      model: model,
      dims: dims,
      normalize: normalize,
      batchConcurrency: batchConcurrency,
    );
    return SpecProviderEmbedder._(
      service: service,
      // The embedding service does not own the provider's HTTP client; the
      // factory built the provider, so the factory closes it. `close()` is a
      // synchronous teardown on the provider base — wrap it for the async hook.
      onClose: () async => provider.close(),
    );
  }

  /// The identity every vector this embedder produces is stamped with. Stable
  /// for the adapter's lifetime.
  EmbeddingModelIdentity get identity => service.currentModelIdentity;

  /// The model's embedding dimensionality — the width the bundled vector store
  /// must be created at.
  int get dims => identity.dims;

  /// Per-text surface for recall-query embedding and incremental re-embeds.
  SpecEmbedder get embedder =>
      (String text) async => (await service.embed(text)).vec;

  /// Bulk surface for full-document indexing — one order- and length-preserving
  /// fan-out over [service]. Bound into [SpecMemory] so `indexDocument` embeds
  /// all sections in a single call.
  SpecBatchEmbedder get batchEmbedder => (List<String> texts) async {
        final results = await service.embedBatch(texts);
        return results
            .map((EmbeddingResult r) => r.vec)
            .toList(growable: false);
      };

  /// Boot-time reachability + dimensionality check. Round-trips a probe string
  /// through the backend, surfacing an unreachable daemon or a dimension
  /// mismatch (silent model swap) before the first real embed corrupts the
  /// store. [previousIdentity] (the identity the store last persisted under)
  /// lets the probe flag identity drift. Throws when the backend path is
  /// broken — the consumer treats a throw as "provider unavailable" and may
  /// fall back to a different embedder for a *fresh* store.
  Future<EmbeddingProbeResult> probe({
    EmbeddingModelIdentity? previousIdentity,
  }) =>
      service.probeIdentity(previousIdentity: previousIdentity);

  /// Closes the wrapped service and any collaborator the factory built.
  Future<void> close() async {
    await service.close();
    final onClose = _onClose;
    if (onClose != null) await onClose();
  }
}
