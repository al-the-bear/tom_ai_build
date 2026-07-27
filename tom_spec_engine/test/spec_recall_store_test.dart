import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 11 / `d4rt_and_llm_tools.md` §9.2 + §9.3 — the **store-integrated**
/// half of fused recall: the tier-2 vector mode is the *real*
/// `SpecDocumentMemory.recallSections` over the in-process Tom Brain named
/// memory, and the incremental embedding path
/// (`indexChangedSections`) is exercised against a real store.
///
/// Two guarantees beyond the host-independent suite:
///   * fused [SpecRecall] over a real vector tier surfaces a section by both the
///     lexical and vector modes (tier 2 warm, not degraded);
///   * `indexChangedSections` **embeds changed sections only** — an unchanged
///     section's content hash short-circuits any embed call — and forgets a
///     removed section so it stops being recalled.
///
/// Skipped (not failed) when the running platform has no packaged vec0 binary
/// under `tom_binaries/sqlite_vec` — the store refuses to boot without it.
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
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
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

  // Counts embed calls so the embed-changed-only guarantee is observable.
  var embedCalls = 0;

  /// Deterministic 768-dim embedder (mirrors the step-10 suite): same text →
  /// identical vector, so a self-recall is an exact vector hit.
  Future<Vec> embedText(String text) async {
    embedCalls++;
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

  setUp(() => embedCalls = 0);

  String freshRoot() {
    final root = Directory.systemTemp.createTempSync('tse_step11_');
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

  ({SpecQueryEngine engine, SpecDocument doc}) fixture() {
    final doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview summary');
    doc.setContent('PD00/SIT/DET', 'current situation analysis');
    return (engine: SpecQueryEngine(model: _model(), document: doc), doc: doc);
  }

  MemoryScope scopeFor(String document) => MemoryScope(
        application: 'tomspecs',
        session: 'phase3-review',
        document: document,
      );

  group('SpecRecall step-11 (fused over a real vector tier)', () {
    test('a section is surfaced by both the lexical and vector modes', () async {
      final memory = openMemory();
      final f = fixture();
      final mem = await memory.openDocument(scopeFor('fused'));
      final graph = SpecRagGraph.fromProjections(f.engine.projectNodes());
      await mem.indexDocument(graph);

      final index = StructuralLexicalIndex()..rebuild(f.engine.projectNodes());
      final recall = SpecRecall(
        index: index,
        vectorRecall: (query, {k = 10}) => mem.recallSections(query, k: k),
        graph: graph,
      );

      // The query is VIS's exact text, so the deterministic embedder makes VIS
      // the top vector hit; it also matches "platform"/"rollout" lexically.
      final result =
          await recall.recall(const SpecRecallQuery(text: 'resilient rollout platform'));

      expect(result.tier2Warm, isTrue);
      expect(result.degraded, isFalse);
      final vis = result.hits.firstWhere((h) => h.path == 'PD00/VIS');
      expect(vis.modes,
          containsAll(<SpecRecallMode>{SpecRecallMode.lexical, SpecRecallMode.vector}));
    }, skip: skipNoBinary);
  });

  group('indexChangedSections step-11 (embed changed only)', () {
    test('only the section whose content moved is re-embedded', () async {
      final memory = openMemory();
      final f = fixture();
      final mem = await memory.openDocument(scopeFor('incremental'));
      await mem.indexDocument(
          SpecRagGraph.fromProjections(f.engine.projectNodes()));

      // Edit one section; SUM and DET are untouched.
      f.doc.setContent('PD00/VIS', 'a wholly different vision statement');
      final changedGraph =
          SpecRagGraph.fromProjections(f.engine.projectNodes());

      embedCalls = 0;
      final result = await mem.indexChangedSections(
        changedGraph,
        changedPaths: const ['PD00/VIS', 'PD00/SUM', 'PD00/SIT/DET'],
      );

      // VIS changed → 1 embed; SUM and DET hashed identically → skipped.
      expect(embedCalls, 1);
      expect(result.embedded, 1);
      expect(result.unchanged, 2);

      // The new text is now recallable on the changed section.
      final hits = await mem.recallSections('a wholly different vision statement');
      expect(hits.map((h) => h.path), contains('PD00/VIS'));
      expect(
        hits.firstWhere((h) => h.path == 'PD00/VIS').text,
        contains('wholly different vision'),
      );
    }, skip: skipNoBinary);

    test('a removed section is forgotten and stops being recalled', () async {
      final memory = openMemory();
      final f = fixture();
      final mem = await memory.openDocument(scopeFor('removal'));
      final graph = SpecRagGraph.fromProjections(f.engine.projectNodes());
      await mem.indexDocument(graph);

      final result = await mem.indexChangedSections(
        graph,
        removedPaths: const ['PD00/SIT/DET'],
      );
      expect(result.removed, 1);

      final hits = await mem.recallSections('current situation analysis');
      expect(hits.map((h) => h.path), isNot(contains('PD00/SIT/DET')));
      expect(await mem.edgesFrom('PD00/SIT/DET'), isEmpty);
    }, skip: skipNoBinary);

    test('re-running with no real changes embeds nothing', () async {
      final memory = openMemory();
      final f = fixture();
      final mem = await memory.openDocument(scopeFor('noop'));
      final graph = SpecRagGraph.fromProjections(f.engine.projectNodes());
      await mem.indexDocument(graph);

      embedCalls = 0;
      final result = await mem.indexChangedSections(
        graph,
        changedPaths: const ['PD00/VIS', 'PD00/SUM', 'PD00/SIT/DET'],
      );
      expect(embedCalls, 0);
      expect(result.embedded, 0);
      expect(result.unchanged, 3);
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
