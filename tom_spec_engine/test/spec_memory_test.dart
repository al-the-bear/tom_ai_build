import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

import 'support/vector_runtime.dart';

/// Conformance: the engine-side Tom Brain memory façade.
///
/// Proves the embeddable memory plane works **in-process** on the reference
/// host: a [MemoryScope] (application / session / document) opens a
/// profile-isolated store backed by the **bundled** sqlite-vec (vec0) binary,
/// a string is **embedded** through the façade's embedding surface, the
/// embedding is **remembered**, and the same string is **recalled** through
/// the vector index — with no external provisioning and no LLM/substrate
/// instantiation.
///
/// Store-touching tests are **skipped** (not failed) when the host process has
/// no vector runtime. `support/vector_runtime.dart` names that
/// precondition — `package:tom_brain_memory` owns it — and explains why it is
/// probed rather than inferred from the binary's presence.
void main() {
  // Vector-runtime precondition — probed, not proxied: a present vec0 binary
  // does not imply a loadable one (see test/support/vector_runtime.dart).
  final skipNoBinary = vectorRuntime.skipReason;

  /// A deterministic 768-dim embedder (the bootstrap nomic-embed-text
  /// dimensionality). Same text → identical vector, so a self-recall is an
  /// exact vector hit — a deterministic proof of the embed→vector-recall
  /// pipeline without an Ollama/OpenAI backend. The real provider-backed
  /// embedding API is wired in at the tier-2 vector step
  /// (`llm_and_d4rt_tools.md` §9.2).
  Future<Vec> embedText(String text) async {
    const dims = 768;
    final values = Float32List(dims);
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash = (hash ^ unit) * 0x01000193 & 0x7fffffff;
    }
    for (var i = 0; i < dims; i++) {
      values[i] = (((hash + i * 2654435761) & 0x7fffffff) % 1000) / 1000.0;
    }
    return Vec(values);
  }

  String freshRoot() {
    final root = Directory.systemTemp.createTempSync('tse_step2_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return root.path;
  }

  SpecMemory openMemory() {
    final memory = SpecMemory(
      memoryRoot: freshRoot(),
      sqliteVecBinariesRoot: vectorRuntime.requireBinariesRoot,
      embedder: embedText,
    );
    addTearDown(memory.close);
    return memory;
  }

  group('SpecMemory façade', () {
    test('MemoryScope validates its three levels and derives a profile name',
        () {
      final scope = MemoryScope(
        application: 'tomspecs',
        session: 'phase3-review',
        document: 'pd00-acme',
      );
      // The memory partition ("named memory") is the document.
      expect(scope.profileName, 'pd00-acme');
      expect(scope.application, 'tomspecs');
      expect(scope.session, 'phase3-review');

      // Components that could escape the profiles directory are rejected.
      expect(
        () => MemoryScope(
            application: 'a', session: 's', document: '../escape'),
        throwsArgumentError,
      );
      expect(
        () => MemoryScope(application: '', session: 's', document: 'd'),
        throwsArgumentError,
      );
    });

    test('embed() returns a fixed-dimension vector through the façade',
        () async {
      final memory = openMemory();
      final vec = await memory.embed('staged rollout concept');
      expect(vec.dimension, 768);
      // Never opens the store, so the weaker precondition is enough: this runs
      // wherever the packaged binary exists, working runtime or not.
    }, skip: vectorRuntime.binariesSkipReason);

    test('remember then recall the same string finds it in-process', () async {
      final memory = openMemory();
      final scope = MemoryScope(
        application: 'tomspecs',
        session: 'phase3-review',
        document: 'pd00-acme',
      );
      const text = 'The system rollout concept covers staged deployment.';

      final doc = await memory.openDocument(scope);
      await doc.remember(text);

      final hits = await doc.recall(text);
      expect(hits, isNotEmpty);
      expect(hits.map((h) => h.text), contains(text));
    }, skip: skipNoBinary);

    test('two documents never cross-talk (profile isolation)', () async {
      final memory = openMemory();
      const text = 'Authorization concept: role-based access control.';

      final docA = await memory.openDocument(
        MemoryScope(
            application: 'tomspecs', session: 'p3', document: 'doc-a'),
      );
      await docA.remember(text);

      final docB = await memory.openDocument(
        MemoryScope(
            application: 'tomspecs', session: 'p3', document: 'doc-b'),
      );
      final hits = await docB.recall(text);
      expect(hits, isEmpty);
    }, skip: skipNoBinary);
  });
}

