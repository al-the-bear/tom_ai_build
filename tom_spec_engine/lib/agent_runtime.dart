/// The **live agent-run surface** of the engine (`llm_and_d4rt_tools.md` §10 /
/// §11).
///
/// Where [`agent.dart`](agent.dart) re-exports the `llm_and_d4rt_tools.md` §11
/// **AgentContext** profile *binding* surface (memory-light, pure Dart), this
/// partial library re-exports the `llm_and_d4rt_tools.md` §10 **run** surface
/// the editor needs to actually *drive* a mode-(b) agent run in-process: the
/// [AgentSubstrate] modes ([buildAgentSubstrate] / [AgentSubstrateMode],
/// [BrainAgentSubstrate] / [DirectAgentSubstrate]), the [AgentTask] /
/// [AgentRunResult] values, the run-trail types ([RunEffort] / [BrainRunRecord]
/// / [BrainSessionEnvelope]), and — the heart of item 8 — the live
/// [SpecBrainSessionEnvelope] that records each run into a document's
/// profile-isolated Tom Brain named memory.
///
/// Because [SpecBrainSessionEnvelope] persists through [SpecMemory], this façade
/// (unlike [`agent.dart`](agent.dart)) **does** pull the `tom_brain_memory`
/// memory plane — exactly the dependency the editor already links for its
/// embeddable memory plane. Keeping the run surface in its own
/// façade lets a consumer that only needs the AgentContext *binding* stay
/// memory-light.
library;

export 'src/agent/agent_procedure.dart';
export 'src/agent/agent_procedure_host.dart';
export 'src/agent/agent_scope.dart';
export 'src/agent/agent_substrate.dart';
export 'src/agent/agent_substrate_factory.dart';
export 'src/agent/agent_tools_api.dart';
export 'src/agent/brain_agent_substrate.dart';
export 'src/agent/brain_session_envelope.dart';
export 'src/agent/conversational_substrate.dart';
export 'src/agent/direct_agent_substrate.dart';
export 'src/agent/spec_brain_envelope.dart';
