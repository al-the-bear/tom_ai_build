/// The §10 substrate **selector** — *the application selects the mode* (plan
/// steps 15–16).
///
/// §10 mandates two interchangeable substrates behind one [AgentSubstrate]
/// interface, with the application choosing which to run. [AgentSubstrateMode]
/// names the two modes and [buildAgentSubstrate] builds the matching substrate
/// over a shared [AgentToolsApi] — so swapping modes is one enum value, never a
/// caller change.
library;

import 'agent_procedure.dart';
import 'agent_scope.dart';
import 'agent_substrate.dart';
import 'agent_tools_api.dart';
import 'brain_agent_substrate.dart';
import 'brain_session_envelope.dart';
import 'direct_agent_substrate.dart';
import '../memory/memory_scope.dart';

/// The two §10 agent substrate modes the application chooses between.
enum AgentSubstrateMode {
  /// Mode (a) — the direct Agent SDK substrate ([DirectAgentSubstrate]).
  direct,

  /// Mode (b) — the Agent-SDK-through-`tom_brain` substrate
  /// ([BrainAgentSubstrate]).
  tomBrain,
}

/// Builds the [AgentSubstrate] for [mode] over the shared [tools].
///
/// [procedure] (default [AgentProcedure.searchRecallEditVerify]) and [scopeName]
/// apply to both modes. Mode (b) additionally requires a Tom Brain [envelope]
/// and [scope]; supplying neither for [AgentSubstrateMode.tomBrain] is an
/// [ArgumentError] — the mode's defining feature is the envelope, so a silent
/// fall-through to a bare run would be wrong.
AgentSubstrate buildAgentSubstrate(
  AgentSubstrateMode mode, {
  required AgentToolsApi tools,
  AgentProcedure? procedure,
  BrainSessionEnvelope? envelope,
  MemoryScope? scope,
  String scopeName = agentScopeName,
}) {
  switch (mode) {
    case AgentSubstrateMode.direct:
      return DirectAgentSubstrate(
        tools: tools,
        procedure: procedure,
        scopeName: scopeName,
      );
    case AgentSubstrateMode.tomBrain:
      if (envelope == null || scope == null) {
        throw ArgumentError(
          'mode (b) (tomBrain) requires a Tom Brain envelope + scope',
        );
      }
      return BrainAgentSubstrate(
        tools: tools,
        envelope: envelope,
        scope: scope,
        procedure: procedure,
        scopeName: scopeName,
      );
  }
}
