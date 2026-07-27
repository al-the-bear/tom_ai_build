import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

import 'support/agent_test_fixture.dart';

/// §10 mode (a) — the **live conversational substrate** + **multi-turn complex
/// procedures** that the headless mode-(a) core leaves as an "editor concern".
///
/// The conversational substrate composes on top of a base [AgentSubstrate]
/// (here mode (a)'s [DirectAgentSubstrate] over the shared fixture): each turn it
/// recalls the RAG memory (the per-prompt augmentation), hands that recall to an
/// injected [ConversationalDriver] to decide the turn, and runs the existing
/// complex procedure through the base. The driver is the host-independent
/// [RecordingConversationalDriver] so the multi-turn loop is exercised without a
/// live bridge/LLM, exactly as the run-envelope test injects a recording
/// envelope.
void main() {
  late AgentFixture fixture;
  late DirectAgentSubstrate base;

  setUp(() {
    fixture = buildAgentFixture();
    base = DirectAgentSubstrate(tools: fixture.tools);
  });

  ConversationalAgentSubstrate substrateWith(
    List<ConversationalDecision> script, {
    int maxTurns = 8,
    bool stopOnError = true,
    AgentSubstrate? over,
  }) =>
      ConversationalAgentSubstrate(
        base: over ?? base,
        tools: fixture.tools,
        driver: RecordingConversationalDriver(script),
        maxTurns: maxTurns,
        stopOnError: stopOnError,
      );

  test('reports mode "conversational" over the base substrate mode', () {
    final substrate = substrateWith(const []);
    expect(substrate.mode, 'conversational');
    expect(substrate.baseMode, 'direct');
  });

  test('drives the complex procedure across multiple turns; each edit lands in '
      'the one change log', () async {
    final substrate = substrateWith(const [
      ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
      ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
      ConversationalDecision.stop(reason: 'done'),
    ]);

    final result = await substrate.run(const AgentTask(goal: 'platform'));

    expect(result.ok, isTrue, reason: result.error);
    final out = (result.output as Map).cast<String, Object?>();
    expect(out['turns'], 2);
    expect(out['stopReason'], 'done');

    // Two turns, two list items, two change-log entries — every turn's edit
    // landed on the one shared controller.
    expect(substrate.turns, hasLength(2));
    expect(fixture.document.listItems('PD00/RSK'),
        ['PD00/RSK-1', 'PD00/RSK-2']);
    expect(fixture.controller.log, const [
      Change('add', 'PD00/RSK-1'),
      Change('add', 'PD00/RSK-2'),
    ]);

    // The aggregate transcript carries each turn's section.
    expect(result.transcript, contains('— turn 0 —'));
    expect(result.transcript, contains('— turn 1 —'));
  });

  test('the per-turn RAG recall reaches the driver (the §10 mode-a '
      'augmentation)', () async {
    final driver = RecordingConversationalDriver(const [
      ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
      ConversationalDecision.stop(),
    ]);
    final substrate = ConversationalAgentSubstrate(
      base: base,
      tools: fixture.tools,
      driver: driver,
    );

    await substrate.run(const AgentTask(goal: 'platform'));

    // The driver saw a context before each decision (turn 0 + the stop turn).
    expect(driver.seenContexts, hasLength(2));
    final first = driver.seenContexts.first;
    expect(first.turnIndex, 0);
    expect(first.priorTurns, isEmpty);
    // The fixture indexes 'platform overview' / 'resilient rollout platform',
    // so recall over the goal surfaces the document sections to the driver.
    expect(first.recalledPaths, isNotEmpty);
    expect(first.recall['hits'], isNotNull);
    // The second decision saw the first completed turn.
    expect(driver.seenContexts[1].priorTurns, hasLength(1));
  });

  test('a driver that stops immediately is a successful no-op (no turns, empty '
      'change log)', () async {
    final substrate = substrateWith(const [
      ConversationalDecision.stop(reason: 'nothing to do'),
    ]);

    final result = await substrate.run(const AgentTask(goal: 'platform'));

    expect(result.ok, isTrue);
    final out = (result.output as Map).cast<String, Object?>();
    expect(out['turns'], 0);
    expect(out['stopReason'], 'nothing to do');
    expect(substrate.turns, isEmpty);
    expect(fixture.controller.log, isEmpty);
  });

  test('stopOnError ends the conversation after the first failed turn', () async {
    // A base whose procedure throws — so the turn's run reports ok:false.
    final broken = DirectAgentSubstrate(
      tools: fixture.tools,
      procedure: const AgentProcedure(
        name: 'broken',
        source: '''
import 'package:tom_spec_engine/agent.dart';
main(task) => undefinedSymbol();
''',
      ),
    );
    final substrate = substrateWith(
      const [
        ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
        ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
      ],
      over: broken,
    );

    final result = await substrate.run(const AgentTask(goal: 'platform'));

    expect(result.ok, isFalse);
    expect(result.error, 'one or more conversational turns failed');
    // Only the first (failing) turn ran; the second never started.
    expect(substrate.turns, hasLength(1));
    final out = (result.output as Map).cast<String, Object?>();
    expect(out['stopReason'], 'turn 0 failed');
  });

  test('maxTurns caps a non-stopping conversation', () async {
    // Three run-decisions, but maxTurns clamps the loop to two turns.
    final substrate = substrateWith(
      const [
        ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
        ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
        ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
      ],
      maxTurns: 2,
    );

    final result = await substrate.run(const AgentTask(goal: 'platform'));

    expect(substrate.turns, hasLength(2));
    final out = (result.output as Map).cast<String, Object?>();
    expect(out['turns'], 2);
    expect(out['stopReason'], 'reached maxTurns (2)');
    expect(fixture.controller.log, hasLength(2));
  });

  test('buildConversationalSubstrate is a thin builder for the same substrate',
      () async {
    final substrate = buildConversationalSubstrate(
      base: base,
      tools: fixture.tools,
      driver: RecordingConversationalDriver(const [
        ConversationalDecision.run(inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'}),
        ConversationalDecision.stop(),
      ]),
    );
    final result = await substrate.run(const AgentTask(goal: 'platform'));
    expect(result.ok, isTrue);
    expect(substrate.turns, hasLength(1));
  });
}
