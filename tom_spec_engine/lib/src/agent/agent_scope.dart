/// The `agent` scope (`llm_and_d4rt_tools.md` §4, §8, §10).
///
/// Builds the [ScriptScope] that binds the unified [AgentToolsApi] tool surface
/// to the interpreter. The scope exposes exactly one bridged-library block,
/// `agent_api`, whose registrar:
///
///   1. registers the [AgentToolsApi] bridged class on the interpreter, and
///   2. injects the single bound [AgentToolsApi] instance as the `agent` global
///      under [agentToolsApiLibrary].
///
/// A procedure that imports `package:tom_spec_engine/agent.dart` then drives
/// the document through `agent` (`agent.search(...)`, `agent.recall(...)`,
/// `agent.addNode(...)`, …) — every call returning compact JSON, and every
/// mutation mediated by the [DocTools] controller so it lands in the one change
/// log (`llm_and_d4rt_tools.md` §5).
///
/// Like the `spec` scope, this scope grants **no extra `tom_d4rt` permission**:
/// document and memory access are in-memory operations gated by the toolsets,
/// not filesystem/network capabilities. (The file surface, when bound, is itself
/// whitelist-gated inside [AgentToolsApi.files]'s facade.)
/// @docImport '../tools/doc_tools.dart';
library;

import 'agent_tools_api.dart';
import '../scope/scope.dart';

/// The conventional name of the `agent` scope.
const String agentScopeName = 'agent';

/// Builds the `agent` scope bound to [tools].
///
/// [name] defaults to [agentScopeName]; override it only to register the same
/// tool binding under an alternate scope label.
ScriptScope agentScope(AgentToolsApi tools, {String name = agentScopeName}) =>
    ScriptScope(
      name: name,
      libraries: [
        BridgedLibrary(agentToolsApiLibraryName, (interpreter) {
          interpreter.registerBridgedClass(
              agentToolsApiBridgedClass(), agentToolsApiLibrary);
          interpreter.registerGlobalVariable(
              agentToolsApiGlobalName, tools, agentToolsApiLibrary);
        }),
      ],
    );
