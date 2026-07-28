/// The **complex agent procedure** (`llm_and_d4rt_tools.md` §10).
///
/// `llm_and_d4rt_tools.md` §10 mode (a) is *driven by a complex agent procedure
/// — a D4rt procedure that orchestrates the multi-step search → recall → edit →
/// verify loop over the `llm_and_d4rt_tools.md` §8 tools*. [AgentProcedure] is
/// that procedure as a value: a [name] plus the D4rt [source] an
/// [AgentSubstrate] executes under the `agent` scope. The canonical instance is
/// [AgentProcedure.searchRecallEditVerify].
///
/// The procedure is intentionally a real D4rt script (the `tom_brain_procedure`
/// host pattern, `llm_and_d4rt_tools.md` §2) rather than hard-coded Dart, so it
/// is the same artefact an agent could author/inspect via the
/// `llm_and_d4rt_tools.md` §8.1 `script_*` tools, and so both
/// `llm_and_d4rt_tools.md` §10 modes drive the *identical* loop body (the "same
/// loop test").
library;

import 'agent_scope.dart';

/// The canonical search → recall → edit → verify procedure source.
///
/// Its `task` argument (a `Map`) carries `goal` (the search/recall text),
/// `parentPath` (the container to grow), and an optional `childSegment`. When
/// `childSegment` is absent the procedure **reflects the parent and picks the
/// first model-permitted child** — a genuine meta-model-driven decision step.
/// Every value it returns is JSON-able.
const String searchRecallEditVerifyProcedureSource = r'''
import 'package:tom_spec_engine/agent.dart';

/// One search → recall → edit → verify pass over the `llm_and_d4rt_tools.md` §8
/// tools (`llm_and_d4rt_tools.md` §10, mode a).
main(task) async {
  final goal = task['goal'];
  final parentPath = task['parentPath'];

  // 1. SEARCH — grep the live document for sections relevant to the goal.
  final searchPage = agent.search(goal);
  final searched = [];
  for (final m in searchPage['matches']) {
    searched.add(m['path']);
  }

  // 2. RECALL — pull related sections from the fused two-tier memory.
  final recallResult = await agent.recall(goal);
  final recalled = [];
  for (final h in recallResult['hits']) {
    recalled.add(h['path']);
  }

  // 3. EDIT — reflect the parent, choose the child segment (explicit or the
  //    first the meta-model permits), and add it through the one change log.
  var childSegment = task['childSegment'];
  if (childSegment == null) {
    final parent = agent.reflect(parentPath);
    final allowed = parent['allowedChildren'];
    if (allowed == null || allowed.isEmpty) {
      return {
        'ok': false,
        'reason': 'no model-permitted children under ' + parentPath,
        'searched': searched,
        'recalled': recalled,
      };
    }
    childSegment = allowed[0]['segment'];
  }
  final added = agent.addNode(parentPath, childSegment);
  if (added['ok'] != true) {
    return {
      'ok': false,
      'reason': added['error'],
      'code': added['code'],
      'searched': searched,
      'recalled': recalled,
    };
  }

  // 4. VERIFY — reflect the new node to confirm it resolves in the model.
  final verify = agent.reflect(added['path']);

  return {
    'ok': true,
    'searched': searched,
    'recalled': recalled,
    'added': added['path'],
    'childSegment': childSegment,
    'verified': verify['resolved'],
  };
}
''';

/// A named complex agent procedure — D4rt [source] run under the [scopes] it
/// targets (the `agent` scope by default).
final class AgentProcedure {
  /// The procedure's identity / label.
  final String name;

  /// The D4rt source executed under the agent scope.
  final String source;

  /// The scope names the procedure runs under.
  final List<String> scopes;

  /// Creates a procedure over [source].
  const AgentProcedure({
    required this.name,
    required this.source,
    this.scopes = const [agentScopeName],
  });

  /// The canonical search → recall → edit → verify procedure
  /// (`llm_and_d4rt_tools.md` §10, mode a).
  static const AgentProcedure searchRecallEditVerify = AgentProcedure(
    name: 'search_recall_edit_verify',
    source: searchRecallEditVerifyProcedureSource,
  );
}
