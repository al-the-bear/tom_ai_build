import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

import 'support/agent_test_fixture.dart';

/// Step 16 / `llm_and_d4rt_tools.md` §10 — **mode (b)**, the
/// **Agent-SDK-through-`tom_brain`** substrate.
///
/// Mode (b) drives the *same* complex agent procedure as mode (a) but wraps the
/// run in a Tom Brain **session envelope**: a profile (application) + named
/// session (phase/task) + named memory (document), recording the run into that
/// named memory. The done-criterion is *both modes selectable and passing the
/// same loop test* — so the loop assertions below are shared with mode (a) via
/// the `support/agent_test_fixture.dart` fixture and are asserted against a
/// substrate built **through the selector**.
void main() {
  /// The shared loop assertion both §10 modes must satisfy. Builds a fresh
  /// fixture, builds the substrate for [mode] through the selector, runs the
  /// canonical task, and asserts the search → recall → edit → verify outcome
  /// plus the single change-log entry.
  Future<void> assertSameLoop(AgentSubstrateMode mode) async {
    final fixture = buildAgentFixture();
    final substrate = buildAgentSubstrate(
      mode: mode,
      tools: fixture.tools,
      envelope: RecordingBrainEnvelope(),
      scope: MemoryScope(
        application: 'docspecs',
        session: 'phase3',
        document: 'PD00',
      ),
    );

    final result = await substrate.run(const AgentTask(
      goal: 'platform',
      inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'},
    ));

    expect(result.ok, isTrue, reason: result.error);
    final out = (result.output as Map).cast<String, Object?>();
    expect(out['searched'], contains('PD00/SUM'));
    expect(out['recalled'], isNotEmpty);
    expect(out['added'], 'PD00/RSK-1');
    expect(out['verified'], isTrue);
    expect(fixture.controller.log, [const Change('add', 'PD00/RSK-1')]);
    expect(fixture.document.listItems('PD00/RSK'), ['PD00/RSK-1']);
  }

  late AgentFixture fixture;
  late RecordingBrainEnvelope envelope;
  late MemoryScope scope;
  late BrainAgentSubstrate substrate;

  setUp(() {
    fixture = buildAgentFixture();
    envelope = RecordingBrainEnvelope();
    scope = MemoryScope(
      application: 'docspecs',
      session: 'phase3',
      document: 'PD00',
    );
    substrate = BrainAgentSubstrate(
      tools: fixture.tools,
      envelope: envelope,
      scope: scope,
    );
  });

  test('reports mode "tom_brain"', () {
    expect(substrate.mode, 'tom_brain');
  });

  group('the selector (application selects the mode)', () {
    test('builds both modes behind the one AgentSubstrate interface', () {
      final direct = buildAgentSubstrate(
        mode: AgentSubstrateMode.direct,
        tools: fixture.tools,
      );
      final brain = buildAgentSubstrate(
        mode: AgentSubstrateMode.tomBrain,
        tools: fixture.tools,
        envelope: envelope,
        scope: scope,
      );
      expect(direct, isA<AgentSubstrate>());
      expect(direct.mode, 'direct');
      expect(brain, isA<AgentSubstrate>());
      expect(brain.mode, 'tom_brain');
    });

    test('rejects mode (b) without a Tom Brain envelope + scope', () {
      expect(
        () => buildAgentSubstrate(
          mode: AgentSubstrateMode.tomBrain,
          tools: fixture.tools,
        ),
        throwsArgumentError,
      );
    });
  });

  group('mode (b) is the default (F2)', () {
    test('defaultAgentSubstrateMode is tomBrain', () {
      expect(defaultAgentSubstrateMode, AgentSubstrateMode.tomBrain);
    });

    test('omitting mode builds the tom_brain substrate', () {
      final substrate = buildAgentSubstrate(
        tools: fixture.tools,
        envelope: envelope,
        scope: scope,
      );
      expect(substrate.mode, 'tom_brain');
    });

    test('the default still requires its Tom Brain envelope + scope', () {
      // Proof the default is mode (b): omitting both mode *and* the envelope
      // throws exactly as an explicit mode-(b) build would.
      expect(
        () => buildAgentSubstrate(tools: fixture.tools),
        throwsArgumentError,
      );
    });

    test('opting into mode (a) needs no envelope', () {
      final direct =
          buildAgentSubstrate(mode: AgentSubstrateMode.direct, tools: fixture.tools);
      expect(direct.mode, 'direct');
    });
  });

  group('the same loop test passes for both modes', () {
    test('mode (a) — direct', () => assertSameLoop(AgentSubstrateMode.direct));
    test('mode (b) — tom_brain',
        () => assertSameLoop(AgentSubstrateMode.tomBrain));
  });

  group('the Tom Brain session envelope wraps the run', () {
    test('opens a session for the scope and records the run into named memory',
        () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'},
      ));

      expect(result.ok, isTrue, reason: result.error);
      // Exactly one session opened, for the scope this substrate was built with.
      expect(envelope.openedSessions, [scope]);
      // The run was recorded into the named memory: one record, carrying the
      // task goal and the run's own (successful) result.
      expect(envelope.runs, hasLength(1));
      final record = envelope.runs.single;
      expect(record.scope, scope);
      expect(record.task.goal, 'platform');
      expect(record.result.ok, isTrue);
    });

    test('records the run even when the loop edit is rejected', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00', 'childSegment': 'NOPE'},
      ));

      // The run did not throw; the procedure reported the rejection.
      expect(result.ok, isTrue);
      final out = (result.output as Map).cast<String, Object?>();
      expect(out['ok'], isFalse);
      expect(out['code'], 'unknownChild');
      // Nothing mutated, yet the envelope still recorded the (no-op) run.
      expect(fixture.controller.log, isEmpty);
      expect(envelope.runs, hasLength(1));
    });
  });

  test('a procedure that throws still surfaces on the error channel under the '
      'envelope', () async {
    final broken = BrainAgentSubstrate(
      tools: fixture.tools,
      envelope: envelope,
      scope: scope,
      procedure: const AgentProcedure(
        name: 'broken',
        source: '''
import 'package:tom_spec_engine/agent.dart';
main(task) => undefinedSymbol();
''',
      ),
    );

    final result = await broken.run(const AgentTask(goal: 'x'));
    expect(result.ok, isFalse);
    expect(result.error, isNotNull);
    // The failing run is still recorded into named memory.
    expect(envelope.runs, hasLength(1));
    expect(envelope.runs.single.result.ok, isFalse);
  });
}
