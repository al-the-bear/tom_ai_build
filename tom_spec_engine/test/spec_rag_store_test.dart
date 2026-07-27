import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 10 / `llm_and_d4rt_tools.md` §9.1 — the **in-process** half of
/// the section-level RAG store: a document's [SpecRagGraph] (built in
/// `spec_rag_graph_test.dart`) is persisted as section nodes + tree/projection
/// edges into the document's profile-isolated Tom Brain **named memory**
/// (step 2), and the same sections are recalled back.
///
/// Done-criterion (plan step 10): *nodes/edges build from a document and recall
/// returns them.*
///
/// Like the step-2 façade suite, these are **skipped** (not failed) when the
/// running platform has no packaged vec0 binary under
/// `tom_binaries/sqlite_vec` — the store refuses to boot without it.
SpecModel _model() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition', 'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS', 'doc': 'Why the system exists.'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
            {'name': 'situation', 'kind': 'complex', 'sectionId': 'SIT', 'type': 'CurrentSituation'},
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'mapsTo': 'PD00',
          'fields': [
            {'name': 'detail', 'kind': 'content', 'sectionId': 'DET'},
          ],
        },
      },
    });

void main() {
  final vecRoot = _findSqliteVecRoot();
  final skipNoBinary = vecRoot == null
      ? 'No packaged vec0 binary found under tom_binaries/sqlite_vec — the '
          'memory store refuses to boot without it.'
      : null;

  /// Deterministic 768-dim embedder: same text → identical vector, so a
  /// self-recall is an exact vector hit (mirrors the step-2 façade suite).
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
    final root = Directory.systemTemp.createTempSync('tse_step10_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return root.path;
  }

  SpecMemory openMemory() {
    final memory = SpecMemory(
      memoryRoot: freshRoot(),
      sqliteVecBinariesRoot: vecRoot!,
      embedder: embedText,
    );
    addTearDown(memory.close);
    return memory;
  }

  SpecRagGraph buildGraph() {
    final doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'a platform overview');
    doc.setContent('PD00/SIT/DET', 'current platform situation');
    final engine = SpecQueryEngine(model: _model(), document: doc);
    return SpecRagGraph.fromProjections(engine.projectNodes());
  }

  MemoryScope scopeFor(String document) => MemoryScope(
        application: 'tomspecs',
        session: 'phase3-review',
        document: document,
      );

  group('SpecRagStore step-10 (index + recall)', () {
    test('indexes every section node and every resolvable edge', () async {
      final memory = openMemory();
      final graph = buildGraph();
      final doc = await memory.openDocument(scopeFor('pd00-index'));

      final result = await doc.indexDocument(graph);

      expect(result.nodeCount, graph.nodes.length);
      // Every graph edge is writable: tree edges always resolve, and a
      // projection edge is only present when its target node was built.
      expect(result.edgeCount, graph.edges.length);
    }, skip: skipNoBinary);

    test('recall returns the section whose text matches the query', () async {
      final memory = openMemory();
      final graph = buildGraph();
      final doc = await memory.openDocument(scopeFor('pd00-recall'));
      await doc.indexDocument(graph);

      final vis = graph.nodes.firstWhere((n) => n.path == 'PD00/VIS');
      final hits = await doc.recallSections(vis.text);

      expect(hits, isNotEmpty);
      expect(hits.map((h) => h.path), contains('PD00/VIS'));
      expect(hits.firstWhere((h) => h.path == 'PD00/VIS').text,
          contains('resilient rollout platform'));
    }, skip: skipNoBinary);

    test('persisted edges round-trip: a tree edge and a mentions edge', () async {
      final memory = openMemory();
      final graph = buildGraph();
      final doc = await memory.openDocument(scopeFor('pd00-edges'));
      await doc.indexDocument(graph);

      // Tree: PD00/VIS is part_of PD00.
      final visEdges = await doc.edgesFrom('PD00/VIS');
      expect(
        visEdges.any((e) => e.toPath == 'PD00' && e.partOf),
        isTrue,
        reason: 'expected a part_of tree edge PD00/VIS -> PD00',
      );

      // Projection: CurrentSituation (PD00/SIT) mentions PD00 via @MapsTo.
      final sitEdges = await doc.edgesFrom('PD00/SIT');
      expect(
        sitEdges.any((e) => e.toPath == 'PD00' && !e.partOf),
        isTrue,
        reason: 'expected a mentions projection edge PD00/SIT -> PD00',
      );
    }, skip: skipNoBinary);

    test('two documents never cross-talk (profile isolation)', () async {
      final memory = openMemory();
      final graph = buildGraph();

      final docA = await memory.openDocument(scopeFor('rag-a'));
      await docA.indexDocument(graph);

      final vis = graph.nodes.firstWhere((n) => n.path == 'PD00/VIS');
      final docB = await memory.openDocument(scopeFor('rag-b'));
      final hits = await docB.recallSections(vis.text);
      expect(hits, isEmpty);
    }, skip: skipNoBinary);
  });

  // Step 15 / `llm_and_d4rt_tools.md` §9.3 — a full-document index batch-
  // embeds when a `SpecBatchEmbedder` is bound: one fan-out for all sections
  // rather than one round-trip per section, and the batched vectors persist /
  // recall identically to the per-section path.
  group('SpecRagStore step-15 (batch embedding)', () {
    test('indexDocument issues one batch embed for all sections, no per-section'
        ' calls', () async {
      final batchCalls = <List<String>>[];
      var singleCalls = 0;

      Future<List<Vec>> countingBatch(List<String> texts) async {
        batchCalls.add(List<String>.of(texts));
        return [for (final t in texts) await embedText(t)];
      }

      Future<Vec> countingSingle(String text) async {
        singleCalls++;
        return embedText(text);
      }

      final memory = SpecMemory(
        memoryRoot: freshRoot(),
        sqliteVecBinariesRoot: vecRoot!,
        embedder: countingSingle,
        batchEmbedder: countingBatch,
      );
      addTearDown(memory.close);

      final graph = buildGraph();
      final doc = await memory.openDocument(scopeFor('pd00-batch'));
      final result = await doc.indexDocument(graph);

      // One batch call carrying every section's text; zero per-section embeds.
      expect(batchCalls, hasLength(1));
      expect(batchCalls.single, hasLength(graph.nodes.length));
      expect(batchCalls.single, containsAll(graph.nodes.map((n) => n.text)));
      expect(singleCalls, 0);

      // The batched vectors are real postings: recall still finds the section.
      expect(result.nodeCount, graph.nodes.length);
      final vis = graph.nodes.firstWhere((n) => n.path == 'PD00/VIS');
      final hits = await doc.recallSections(vis.text);
      expect(hits.map((h) => h.path), contains('PD00/VIS'));
    }, skip: skipNoBinary);

    test('with no batch embedder bound, indexDocument uses the per-section path',
        () async {
      var singleCalls = 0;
      Future<Vec> countingSingle(String text) async {
        singleCalls++;
        return embedText(text);
      }

      final memory = SpecMemory(
        memoryRoot: freshRoot(),
        sqliteVecBinariesRoot: vecRoot!,
        embedder: countingSingle,
      );
      addTearDown(memory.close);

      final graph = buildGraph();
      final doc = await memory.openDocument(scopeFor('pd00-no-batch'));
      await doc.indexDocument(graph);

      // One embed per section — the fallback path, unchanged from step 10.
      expect(singleCalls, graph.nodes.length);
    }, skip: skipNoBinary);
  });
}

/// Locates `<workspace>/tom_binaries/sqlite_vec`, walking up from the cwd.
String? _findSqliteVecRoot() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 10; i++) {
    final candidate = Directory(
        '${dir.path}${Platform.pathSeparator}tom_binaries'
        '${Platform.pathSeparator}sqlite_vec');
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}
