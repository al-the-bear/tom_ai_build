/// The `llm_and_d4rt_tools.md` §10 substrate **selector** — *the application
/// selects the mode* (`llm_and_d4rt_tools.md` §10).
///
/// `llm_and_d4rt_tools.md` §10 mandates two interchangeable substrates behind
/// one [AgentSubstrate] interface, with the application choosing which to run.
/// [AgentSubstrateMode] names the two modes and [buildAgentSubstrate] builds
/// the matching substrate over a shared [AgentToolsApi] — so swapping modes is
/// one enum value, never a caller change.
library;

import 'agent_procedure.dart';
import 'agent_scope.dart';
import 'agent_substrate.dart';
import 'agent_tools_api.dart';
import 'brain_agent_substrate.dart';
import 'brain_session_envelope.dart';
import 'direct_agent_substrate.dart';
import '../memory/memory_scope.dart';

/// The two `llm_and_d4rt_tools.md` §10 agent substrate modes the application
/// chooses between.
///
/// **Mode (b) ([tomBrain]) is the default** ([defaultAgentSubstrateMode]): it
/// gives the per-application **profile / named session / named memory**
/// isolation for free, which is exactly what the multi-application /
/// multi-phase application mapping (`llm_and_d4rt_tools.md` §11) needs.
/// **Mode (a) ([direct]) is opt-in** for the
/// lightest single-application use, where the Tom Brain session envelope would
/// be overhead.
enum AgentSubstrateMode {
  /// Mode (a) — the direct Agent SDK substrate ([DirectAgentSubstrate]).
  /// **Opt-in** (the lightest single-application use); see [tomBrain] for the
  /// default.
  direct,

  /// Mode (b) — the Agent-SDK-through-`tom_brain` substrate
  /// ([BrainAgentSubstrate]). **The default** ([defaultAgentSubstrateMode]).
  tomBrain,
}

/// The default `llm_and_d4rt_tools.md` §10 substrate mode: mode
/// (b), Agent-SDK-through-`tom_brain`. The application gets the profile /
/// session / memory isolation unless it explicitly opts into
/// [AgentSubstrateMode.direct].
const AgentSubstrateMode defaultAgentSubstrateMode = AgentSubstrateMode.tomBrain;

/// Builds the [AgentSubstrate] for [mode] over the shared [tools].
///
/// [mode] defaults to [defaultAgentSubstrateMode] — **mode (b)** — so an
/// application that does not explicitly choose gets the Tom Brain
/// profile/session/memory isolation; pass [AgentSubstrateMode.direct] to opt
/// into the lighter mode (a).
///
/// [procedure] (default [AgentProcedure.searchRecallEditVerify]) and [scopeName]
/// apply to both modes. Mode (b) — the default — additionally requires a Tom
/// Brain [envelope] and [scope]; supplying neither is an [ArgumentError]: the
/// mode's defining feature is the envelope, so a silent fall-through to a bare
/// run would be wrong. (This is also why the default mode is *not* a silent
/// catch-all — a default-mode build still has to provide its envelope + scope.)
AgentSubstrate buildAgentSubstrate({
  AgentSubstrateMode mode = defaultAgentSubstrateMode,
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
