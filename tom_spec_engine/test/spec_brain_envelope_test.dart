import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

import 'support/agent_test_fixture.dart';
import 'support/vector_runtime.dart';

/// `llm_and_d4rt_tools.md` §10 mode (b) — the **live
/// `tom_brain_memory`-backed** session envelope.
///
/// Where `brain_agent_substrate_test.dart` proves the substrate drives the same
/// loop under the in-memory [RecordingBrainEnvelope], this suite proves the
/// *live* [SpecBrainSessionEnvelope] does the real thing: it opens the
/// document's profile-isolated Tom Brain named memory, runs the loop, and
/// **persists the run as a node** (with its [RunEffort] metrics) recoverable by
/// recall.
///
/// Like the memory-façade suite, the store-touching tests are **skipped** (not
/// failed) when the host process has no vector runtime.
/// `support/vector_runtime.dart` names that precondition —
/// `package:tom_brain_memory` owns it — and explains why it is probed rather
/// than inferred from the binary's presence.
void main() {
  // Vector-runtime precondition — probed, not proxied: a present vec0 binary
  // does not imply a loadable one (see test/support/vector_runtime.dart).
  final skipNoBinary = vectorRuntime.skipReason;

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

  SpecMemory openMemory() {
    final root = Directory.systemTemp.createTempSync('tse_step8_');
    final memory = SpecMemory(
      memoryRoot: root.path,
      sqliteVecBinariesRoot: vectorRuntime.requireBinariesRoot,
      embedder: embedText,
    );
    addTearDown(() async {
      await memory.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return memory;
  }

  MemoryScope scope() => MemoryScope(
        application: 'docspecs',
        session: 'phase3',
        document: 'pd00',
      );

  const task = AgentTask(
    goal: 'platform',
    inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'},
  );

  group('RunEffort metrics (host-independent)', () {
    test('measure derives transcript size and outcome from the result', () {
      const result = AgentRunResult(
        ok: true,
        output: {'x': 1},
        transcript: 'line one\nline two\n',
      );
      final effort = RunEffort.measure(
        wallClock: const Duration(milliseconds: 12),
        result: result,
        inputCount: 2,
      );
      expect(effort.transcriptLines, 2);
      expect(effort.transcriptChars, result.transcript.length);
      expect(effort.inputCount, 2);
      expect(effort.ok, isTrue);
      expect(effort.produced, isTrue);
      expect(effort.toJson(), {
        'wallClockMs': 12,
        'transcriptChars': result.transcript.length,
        'transcriptLines': 2,
        'inputCount': 2,
        'ok': true,
        'produced': true,
      });
    });

    test('a failed run with no output is reflected in the metrics', () {
      const result = AgentRunResult(
        ok: false,
        transcript: '',
        error: 'boom',
      );
      final effort = RunEffort.measure(
        wallClock: Duration.zero,
        result: result,
        inputCount: 0,
      );
      expect(effort.ok, isFalse);
      expect(effort.produced, isFalse);
      expect(effort.transcriptLines, 0);
    });

    test('the recording envelope now stamps each run with its effort', () async {
      final fixture = buildAgentFixture();
      final envelope = RecordingBrainEnvelope();
      final substrate = BrainAgentSubstrate(
        tools: fixture.tools,
        envelope: envelope,
        scope: scope(),
      );
      await substrate.run(task);
      expect(envelope.runs, hasLength(1));
      expect(envelope.runs.single.effort.ok, isTrue);
      expect(envelope.runs.single.effort.inputCount, 2);
    });
  });

  group('SpecBrainSessionEnvelope (live)', () {
    test('drives the same loop and records the run into named memory', () async {
      final fixture = buildAgentFixture();
      final memory = openMemory();
      final envelope = SpecBrainSessionEnvelope(memory);
      final substrate = buildAgentSubstrate(
        mode: AgentSubstrateMode.tomBrain,
        tools: fixture.tools,
        envelope: envelope,
        scope: scope(),
      );

      final result = await substrate.run(task);

      // The loop ran identically to mode (a): the constrained add landed.
      expect(result.ok, isTrue, reason: result.error);
      expect(fixture.controller.log, [const Change('add', 'PD00/RSK-1')]);

      // The run was recorded into the document's named memory with effort.
      expect(envelope.runs, hasLength(1));
      final record = envelope.runs.single;
      expect(record.task.goal, 'platform');
      expect(record.effort.ok, isTrue);
      expect(record.effort.inputCount, 2);

      // The run node is recoverable by recall from the same document memory.
      final document = await memory.openDocument(scope());
      final hits = await document.recall('agent run');
      expect(hits, isNotEmpty);
      expect(hits.first.text, contains('agent run'));
      expect(hits.first.text, contains('platform'));
    }, skip: skipNoBinary);

    test('records a failing run too (the run trail never swallows failures)',
        () async {
      final fixture = buildAgentFixture();
      final memory = openMemory();
      final envelope = SpecBrainSessionEnvelope(memory);
      final substrate = BrainAgentSubstrate(
        tools: fixture.tools,
        envelope: envelope,
        scope: scope(),
        procedure: const AgentProcedure(
          name: 'broken',
          source: '''
import 'package:tom_spec_engine/agent.dart';
main(task) => undefinedSymbol();
''',
        ),
      );

      final result = await substrate.run(const AgentTask(goal: 'x'));
      expect(result.ok, isFalse);
      expect(envelope.runs, hasLength(1));
      expect(envelope.runs.single.effort.ok, isFalse);

      final document = await memory.openDocument(scope());
      final hits = await document.recall('agent run x failed');
      expect(hits, isNotEmpty);
    }, skip: skipNoBinary);

    test('two documents keep their run trails isolated', () async {
      final fixtureA = buildAgentFixture();
      final fixtureB = buildAgentFixture();
      final memory = openMemory();
      final envelope = SpecBrainSessionEnvelope(memory);

      final scopeA =
          MemoryScope(application: 'docspecs', session: 'p3', document: 'doc-a');
      final scopeB =
          MemoryScope(application: 'docspecs', session: 'p3', document: 'doc-b');

      await BrainAgentSubstrate(
        tools: fixtureA.tools,
        envelope: envelope,
        scope: scopeA,
      ).run(task);

      // doc-b's memory has no agent-run node from doc-a.
      final docB = await memory.openDocument(scopeB);
      final hits = await docB.recall('agent run platform');
      expect(hits, isEmpty);

      // Run on doc-b through the same envelope; the trail collects both.
      await BrainAgentSubstrate(
        tools: fixtureB.tools,
        envelope: envelope,
        scope: scopeB,
      ).run(task);
      expect(envelope.runs.map((r) => r.scope.document), ['doc-a', 'doc-b']);
    }, skip: skipNoBinary);
  });
}
