import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

import 'support/agent_test_fixture.dart';

/// `llm_and_d4rt_tools.md` §10 — the **`AgentSubstrate`**
/// abstraction + **mode (a)** (direct Agent SDK, augmented with Tom Brain
/// named memory, driven by a **complex agent procedure**: a D4rt procedure over
/// the §8 tools).
///
/// Done-criterion: the procedure drives a **search → recall → edit → verify**
/// loop in a test harness, and the edit (the mutating tool) lands in the **one
/// change log**. The model / controller / tools are the shared fixture in
/// `support/agent_test_fixture.dart` so mode (b) drives the identical
/// loop.
void main() {
  late AgentFixture fixture;
  late DirectAgentSubstrate substrate;

  setUp(() {
    fixture = buildAgentFixture();
    substrate = DirectAgentSubstrate(tools: fixture.tools);
  });

  test('reports mode "direct"', () {
    expect(substrate.mode, 'direct');
  });

  group('the complex agent procedure', () {
    test('drives search → recall → edit → verify and the edit lands in the '
        'one change log', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'},
      ));

      expect(result.ok, isTrue, reason: result.error);
      // The procedure's `main()` returns a D4rt map literal
      // (`Map<Object?, Object?>` with String keys) — JSON-able, but cast
      // through the dynamic Map view like every other D4rt return.
      final out = (result.output as Map).cast<String, Object?>();

      // SEARCH surfaced the matching content sections.
      expect(out['searched'], contains('PD00/SUM'));
      // RECALL surfaced at least one section from memory.
      expect(out['recalled'], isNotEmpty);
      // EDIT created the list item …
      expect(out['added'], 'PD00/RSK-1');
      // … VERIFY confirmed it resolves in the model.
      expect(out['verified'], isTrue);

      // The mutation landed in the controller's change log exactly once.
      expect(fixture.controller.log, [const Change('add', 'PD00/RSK-1')]);
      expect(fixture.document.listItems('PD00/RSK'), ['PD00/RSK-1']);

      // The result is JSON-able for the MCP surface.
      expect(result.toJson()['ok'], isTrue);
    });

    test('autonomously picks the first model-permitted child when none is '
        'given', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00'},
      ));

      expect(result.ok, isTrue, reason: result.error);
      final out = (result.output as Map).cast<String, Object?>();
      // The first allowed child of PD00 is the risks list (segment RSK).
      expect(out['childSegment'], 'RSK');
      expect(out['added'], 'PD00/RSK-1');
      expect(fixture.controller.log, [const Change('add', 'PD00/RSK-1')]);
    });

    test('a meta-model-rejected edit is handled gracefully (ok:false output, '
        'no throw, empty change log)', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00', 'childSegment': 'NOPE'},
      ));

      // The run itself did not throw …
      expect(result.ok, isTrue);
      final out = (result.output as Map).cast<String, Object?>();
      // … but the procedure reports the rejected edit with its code.
      expect(out['ok'], isFalse);
      expect(out['code'], 'unknownChild');
      // Nothing was mutated.
      expect(fixture.controller.log, isEmpty);
    });
  });

  test('a procedure that throws surfaces on the error channel', () async {
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

    final result = await broken.run(const AgentTask(goal: 'x'));
    expect(result.ok, isFalse);
    expect(result.error, isNotNull);
  });
}
