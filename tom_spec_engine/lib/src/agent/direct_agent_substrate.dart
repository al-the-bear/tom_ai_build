/// **Mode (a)** — the direct Agent SDK substrate (§10, plan step 15).
///
/// [DirectAgentSubstrate] is the first of §10's two [AgentSubstrate]
/// implementations. It is *augmented with the Tom-Brain-backed memory* (reached
/// through `agent.recall`) and *driven by the complex agent procedure* — the
/// D4rt [AgentProcedure] it runs under the `agent` scope, orchestrating the
/// search → recall → edit → verify loop over the §8 tools.
///
/// The *conversational substrate* (Claude Code over the VS Code bridge, the
/// editor's agent loop) is editor/bridge work this pure-Dart plane does not
/// host; what mode (a) contributes here is the headless **procedure host** that
/// actually drives the loop — the same execution machinery the §8.1 `script_*`
/// tools use (a permission-scoped `D4rt`, a print-intercepting `Zone`, the
/// auto-awaited `main()` return). Mode (b) (plan step 16) will run the *same*
/// procedure wrapped by `tom_brain`; both satisfy [AgentSubstrate].
library;

import 'dart:async';

import 'package:tom_d4rt/tom_d4rt.dart';

import 'agent_procedure.dart';
import 'agent_scope.dart';
import 'agent_tools_api.dart';
import 'agent_substrate.dart';
import '../scope/scope_registry.dart';

/// Runs the complex agent procedure directly — §10 mode (a).
final class DirectAgentSubstrate implements AgentSubstrate {
  /// Creates the substrate over the unified [tools] surface.
  ///
  /// [procedure] defaults to [AgentProcedure.searchRecallEditVerify]; pass a
  /// different one to drive an alternate loop body. [scopeName] is the label the
  /// `agent` scope is registered under (must match the procedure's import).
  DirectAgentSubstrate({
    required AgentToolsApi tools,
    AgentProcedure? procedure,
    String scopeName = agentScopeName,
  })  : _procedure = procedure ?? AgentProcedure.searchRecallEditVerify,
        _scopeName = scopeName,
        _registry = ScopeRegistry()
          ..register(agentScope(tools, name: scopeName));

  final AgentProcedure _procedure;
  final String _scopeName;
  final ScopeRegistry _registry;

  /// The complex agent procedure this substrate drives.
  AgentProcedure get procedure => _procedure;

  @override
  String get mode => 'direct';

  @override
  Future<AgentRunResult> run(AgentTask task) async {
    final env = _registry.build([_scopeName]);
    // The procedure's single Map argument: the goal plus the structured inputs.
    final taskArg = <String, Object?>{'goal': task.goal, ...task.inputs};

    final out = StringBuffer();
    Object? output;
    Object? error;
    StackTrace? stack;

    await runZoned(
      () async {
        final interpreter = D4rt();
        env.applyTo(interpreter);
        try {
          final returned = interpreter.execute(
            source: _procedure.source,
            positionalArgs: [taskArg],
          );
          output = returned is Future ? await returned : returned;
        } catch (e, s) {
          error = e;
          stack = s;
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => out.writeln(line),
      ),
    );

    final failed = error != null;
    return AgentRunResult(
      ok: !failed,
      output: failed ? null : output,
      transcript: out.toString(),
      error: failed ? error.toString() : null,
      stack: failed ? stack?.toString() : null,
    );
  }
}
