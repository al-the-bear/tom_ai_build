/// **Mode (b)** — the Agent-SDK-through-`tom_brain` substrate (§10).
///
/// [BrainAgentSubstrate] is the second of §10's two [AgentSubstrate]
/// implementations. It drives the *same* complex agent procedure as mode (a)
/// ([DirectAgentSubstrate]) through the *same* headless procedure host
/// ([runAgentProcedure]) — so both modes pass the identical "same loop test" —
/// but wraps each run in a Tom Brain **session envelope** ([BrainSessionEnvelope]):
/// a profile (the application), a named session (the phase/task), and a named
/// memory (the document), recording the run into that named memory. That
/// envelope is the per-application/phase isolation §10 mode (b) buys; the loop
/// body is unchanged.
///
/// The conversational substrate (the live Agent SDK / LLM decision-maker) is, as
/// in mode (a), an editor/bridge concern (decision D72); what the engine owns is
/// the procedure host and — for mode (b) — the Tom Brain envelope around it.
library;

import 'agent_procedure.dart';
import 'agent_procedure_host.dart';
import 'agent_scope.dart';
import 'agent_substrate.dart';
import 'agent_tools_api.dart';
import 'brain_session_envelope.dart';
import '../memory/memory_scope.dart';
import '../scope/scope_registry.dart';

/// Runs the complex agent procedure wrapped by a Tom Brain session — §10 mode
/// (b).
final class BrainAgentSubstrate implements AgentSubstrate {
  /// Creates the substrate over the unified [tools] surface, wrapping each run in
  /// the Tom Brain [envelope] addressed by [scope] (application→profile /
  /// session→named session / document→named memory).
  ///
  /// [procedure] defaults to [AgentProcedure.searchRecallEditVerify]; [scopeName]
  /// is the label the `agent` scope is registered under (must match the
  /// procedure's import).
  BrainAgentSubstrate({
    required AgentToolsApi tools,
    required BrainSessionEnvelope envelope,
    required MemoryScope scope,
    AgentProcedure? procedure,
    String scopeName = agentScopeName,
  })  : _envelope = envelope,
        _scope = scope,
        _procedure = procedure ?? AgentProcedure.searchRecallEditVerify,
        _scopeName = scopeName,
        _registry = ScopeRegistry()
          ..register(agentScope(tools, name: scopeName));

  final BrainSessionEnvelope _envelope;
  final MemoryScope _scope;
  final AgentProcedure _procedure;
  final String _scopeName;
  final ScopeRegistry _registry;

  /// The complex agent procedure this substrate drives.
  AgentProcedure get procedure => _procedure;

  /// The Tom Brain addressing each run executes under.
  MemoryScope get scope => _scope;

  @override
  String get mode => 'tom_brain';

  @override
  Future<AgentRunResult> run(AgentTask task) => _envelope.runInSession(
        _scope,
        task,
        () => runAgentProcedure(
          registry: _registry,
          scopeNames: [_scopeName],
          procedure: _procedure,
          task: task,
        ),
      );
}
