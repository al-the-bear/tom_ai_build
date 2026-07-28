/// The **per-application agent-context** façade of the engine
/// (`llm_and_d4rt_tools.md` §11).
///
/// Where [`scripting.dart`](scripting.dart) re-exports the Flutter-safe
/// scripting surface and [`memory.dart`](memory.dart) the embeddable memory
/// plane, this partial library re-exports the `llm_and_d4rt_tools.md` §11
/// **AgentContext** surface the editor needs to make the live **Tom Brain
/// profile binding** — one profile per application carrying that application's
/// guidelines prompt, tool set and scope profile (the application → profile
/// mapping).
///
/// It exposes exactly the context *value* surface: [AgentContext],
/// [AgentToolGroup], the canonical application names
/// ([docSpecsApplication] / [codeSpecsApplication] /
/// [implementationApplication] / [tomSpecsApplications]), the per-application
/// guidelines names and context factories ([docSpecsAgentContext] /
/// [codeSpecsAgentContext] / [implementationAgentContext], plus
/// [tomSpecsContextRegistry] holding all three), and the
/// [AgentContextRegistry] application switch. The agent-context types are pure
/// Dart (`tom_d4rt` + `tom_som_dart_runtime` only — no `tom_brain_*`), so the
/// editor links this façade in-process without pulling new dependencies.
///
/// It deliberately does **not** re-export the live **substrate runners**
/// ([BrainAgentSubstrate] / [BrainSessionEnvelope] / `buildAgentSubstrate`):
/// those — plus the live `tom_brain_memory`-backed `SpecBrainSessionEnvelope` —
/// live in [`agent_runtime.dart`](agent_runtime.dart), the run surface, which
/// pulls the memory plane. This façade is the profile
/// *binding* surface, not the run surface.
library;

export 'src/agent/agent_context.dart';
