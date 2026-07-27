import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 15 / `d4rt_and_llm_tools.md` §9.3 — the provider-backed embedder
/// adapter. These tests bind against a **fake** [EmbeddingService] (re-exported
/// from the engine), so they run on every platform — no Ollama daemon, no vec0
/// binary. They lock the adapter's contract: the two engine surfaces map onto
/// the service, order/length is preserved, identity/dims are surfaced, and the
/// boot probe + close delegate.
const _identity = EmbeddingModelIdentity(
  providerId: 'fake:test',
  modelId: 'fake-embed',
  dims: 4,
  normalized: true,
);

/// A minimal deterministic [EmbeddingService]: every text maps to a 4-dim
/// vector seeded by its length, and the spy counts each surface's calls.
final class _FakeEmbeddingService implements EmbeddingService {
  int embedCalls = 0;
  int batchCalls = 0;
  int probeCalls = 0;
  bool closed = false;
  EmbeddingModelIdentity? lastProbePrevious;

  Vec _vecFor(String text) {
    final values = Float32List(_identity.dims);
    for (var i = 0; i < values.length; i++) {
      values[i] = (text.length + i).toDouble();
    }
    return Vec(values);
  }

  @override
  EmbeddingModelIdentity get currentModelIdentity => _identity;

  @override
  Future<EmbeddingResult> embed(String text) async {
    embedCalls++;
    return EmbeddingResult(vec: _vecFor(text), modelIdentity: _identity);
  }

  @override
  Future<List<EmbeddingResult>> embedBatch(List<String> texts) async {
    batchCalls++;
    return [
      for (final t in texts)
        EmbeddingResult(vec: _vecFor(t), modelIdentity: _identity),
    ];
  }

  @override
  Future<EmbeddingProbeResult> probeIdentity({
    EmbeddingModelIdentity? previousIdentity,
    String probeText = 'tom-brain embedding probe',
  }) async {
    probeCalls++;
    lastProbePrevious = previousIdentity;
    final probe =
        EmbeddingResult(vec: _vecFor(probeText), modelIdentity: _identity);
    return EmbeddingProbeResult(
      currentIdentity: _identity,
      probeResult: probe,
    );
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  group('SpecProviderEmbedder', () {
    test('identity and dims are surfaced from the wrapped service', () {
      final embedder = SpecProviderEmbedder(_FakeEmbeddingService());
      expect(embedder.identity, _identity);
      expect(embedder.dims, 4);
    });

    test('the per-text embedder unwraps the service result to a Vec', () async {
      final fake = _FakeEmbeddingService();
      final embedder = SpecProviderEmbedder(fake);

      final vec = await embedder.embedder('alpha');

      expect(vec.dimension, 4);
      expect(fake.embedCalls, 1);
      expect(fake.batchCalls, 0);
    });

    test('the batch embedder preserves order and length, one service call',
        () async {
      final fake = _FakeEmbeddingService();
      final embedder = SpecProviderEmbedder(fake);

      final texts = ['a', 'bb', 'ccc'];
      final vecs = await embedder.batchEmbedder(texts);

      expect(fake.batchCalls, 1);
      expect(vecs, hasLength(texts.length));
      // result[i] is the embedding of texts[i] — seed is text length, so the
      // first component echoes the input length and proves the alignment.
      for (var i = 0; i < texts.length; i++) {
        expect(vecs[i].values.first, texts[i].length.toDouble());
      }
    });

    test('probe delegates to the service and threads previousIdentity',
        () async {
      final fake = _FakeEmbeddingService();
      final embedder = SpecProviderEmbedder(fake);

      const previous = EmbeddingModelIdentity(
        providerId: 'fake:test',
        modelId: 'fake-embed',
        dims: 4,
        normalized: false, // differs → would be drift if compared
      );
      final result = await embedder.probe(previousIdentity: previous);

      expect(fake.probeCalls, 1);
      expect(fake.lastProbePrevious, previous);
      expect(result.currentIdentity, _identity);
    });

    test('close delegates to the wrapped service', () async {
      final fake = _FakeEmbeddingService();
      final embedder = SpecProviderEmbedder(fake);

      await embedder.close();

      expect(fake.closed, isTrue);
    });

    // The `SpecProviderEmbedder.ollama()` factory is intentionally NOT exercised
    // here: `OllamaLlmProvider`'s constructor eagerly builds a
    // `tom_core_kernel` HTTP client, which needs the platform HTTP factory
    // initialised (available in the Flutter editor host, not in a bare
    // `dart test`). The factory is pure composition over the defaults asserted
    // above; the editor (`SpecMemoryPlane`) covers the live wiring, gated on
    // provider embeddings being enabled (see d4rt_and_llm_tools.md §9.3).
  });
}
