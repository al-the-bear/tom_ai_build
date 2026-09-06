# TomSpecs Engine API Reference: Agent Module

The pluggable agent substrate and the per-application agent context — the seam
between the engine's tool surface and whatever model runtime drives it.

For what the substrate *is*, see
[`llm_and_d4rt_tools.md`](../../../tom_specs_model/doc/llm_and_d4rt_tools.md)
§10 and §11.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [AgentTask](#agenttask)
  - [AgentRunResult](#agentrunresult)
  - [AgentContext](#agentcontext)
  - [AgentContextRegistry](#agentcontextregistry)
  - [AgentProcedure](#agentprocedure)
  - [AgentFilesUnavailable](#agentfilesunavailable)
  - [AgentToolsApi](#agenttoolsapi)
  - [BrainAgentSubstrate](#brainagentsubstrate)
  - [ConversationalTurn](#conversationalturn)
  - [ConversationContext](#conversationcontext)
  - [ConversationalDecision](#conversationaldecision)
  - [RecordingConversationalDriver](#recordingconversationaldriver)
  - [ConversationalAgentSubstrate](#conversationalagentsubstrate)
  - [DirectAgentSubstrate](#directagentsubstrate)
  - [RunEffort](#runeffort)
  - [BrainRunRecord](#brainrunrecord)
  - [RecordingBrainEnvelope](#recordingbrainenvelope)
  - [SpecBrainSessionEnvelope](#specbrainsessionenvelope)
- [Enums](#enums)
  - [AgentSubstrateMode](#agentsubstratemode)
  - [AgentToolGroup](#agenttoolgroup)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **18 classes** and **2 enums** across 12 source file(s).

| Source file | Holds |
|-------------|-------|
| `agent_substrate.dart` | The substrate contract — `AgentTask`, `AgentRunResult` |
| `agent_substrate_factory.dart` | Substrate selection — `AgentSubstrateMode` |
| `agent_context.dart` | The per-application context — `AgentContext`, `AgentContextRegistry`, `AgentToolGroup` |
| `agent_scope.dart` | The agent scope binding — *(no public types)* |
| `agent_procedure.dart` | Procedures — `AgentProcedure` |
| `agent_procedure_host.dart` | The procedure host — *(no public types)* |
| `agent_tools_api.dart` | The tools API surface — `AgentFilesUnavailable`, `AgentToolsApi` |
| `brain_agent_substrate.dart` | The Tom Brain substrate — `BrainAgentSubstrate` |
| `conversational_substrate.dart` | The conversational substrate — `ConversationalTurn`, `ConversationContext`, `ConversationalDecision`, `RecordingConversationalDriver`, `ConversationalAgentSubstrate` |
| `direct_agent_substrate.dart` | The direct substrate — `DirectAgentSubstrate` |
| `brain_session_envelope.dart` | Brain session envelope — `RunEffort`, `BrainRunRecord`, `RecordingBrainEnvelope` |
| `spec_brain_envelope.dart` | Spec brain envelope — `SpecBrainSessionEnvelope` |

## Class Hierarchy

```
Object
├── AgentTask
├── AgentRunResult
├── AgentContext
├── AgentContextRegistry
├── AgentProcedure
├── AgentFilesUnavailable  implements Exception
├── AgentToolsApi
├── BrainAgentSubstrate  implements AgentSubstrate
├── ConversationalTurn
├── ConversationContext
├── ConversationalDecision
├── RecordingConversationalDriver  implements ConversationalDriver
├── ConversationalAgentSubstrate  implements AgentSubstrate
├── DirectAgentSubstrate  implements AgentSubstrate
├── RunEffort
├── BrainRunRecord
├── RecordingBrainEnvelope  implements BrainSessionEnvelope
└── SpecBrainSessionEnvelope  implements BrainSessionEnvelope
```

## Classes

### AgentTask

A unit of agent work: a natural-language [goal] plus structured [inputs].

#### Constructors
```dart
const AgentTask({required this.goal, this.inputs = const {}});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `goal` | `String` | The free-text intent driving the run. |
| `inputs` | `Map<String, Object?>` | Structured parameters merged into the procedure's task argument under their own keys (alongside `goal`). |

### AgentRunResult

The outcome of an [AgentSubstrate.run]: the procedure's auto-awaited return, everything it printed, and the error channel.

#### Constructors
```dart
const AgentRunResult({
  required this.ok,
  this.output,
  required this.transcript,
  this.error,
  this.stack,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ok` | `bool` | Whether the run completed without the procedure throwing. |
| `output` | `Object?` | The procedure's auto-awaited `main()` return value (JSON-able), or `null` on error. |
| `transcript` | `String` | Everything the procedure `print`ed, in order (newline-separated). |
| `error` | `String?` | The error message when the run threw, else `null`. |
| `stack` | `String?` | The stack trace when the run threw, else `null`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP / agent-loop surface. |

### AgentContext

The per-application agent context: guidelines + toolset + scope profile, addressed as a Tom Brain profile (`llm_and_d4rt_tools.md` §11).

#### Constructors
```dart
AgentContext({
  required this.application,
  required this.guidelinesName,
  required Set<AgentToolGroup> toolset,
  required this.scopeProfile,
}) : toolset = Set.unmodifiable(toolset) {
  final scopes = scopeProfile.scopeNames.toSet();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `application` | `String` | The application name — the Tom Brain **profile** ([profileName]). |
| `guidelinesName` | `String` | The guidelines document that is the profile's **prompt** (agent briefing). |
| `toolset` | `Set<AgentToolGroup>` | The [AgentToolGroup]s this profile exposes. |
| `scopeProfile` | `ScopeProfile` | The D4rt scope profile this application enables. |
| `profileName` | `String get` | The Tom Brain profile this application binds to — the [application] itself. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `memoryScope({required String session, required String document})` | `MemoryScope` | Addresses one run: the application profile + a per-run [session] (named session) + a per-document [document] (named memory). |
| `buildEnvironment(ScopeRegistry registry)` | `RunEnvironment` | Builds the [RunEnvironment] for this application's scope profile against [registry] — the union of its base scopes' libraries, globals, and grants. |
| `toString()` | `String` | A compact diagnostic rendering. |

### AgentContextRegistry

Holds the application [AgentContext]s and resolves the active one by name — the `llm_and_d4rt_tools.md` §11 **application switch**.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `applications` | `Iterable<String> get` | The names of all registered applications. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `register(AgentContext context)` | `void` | Registers [context] under its [AgentContext.application] name. |
| `has(String application)` | `bool` | Whether an application named [application] is registered. |
| `context(String application)` | `AgentContext` | The context for [application]. |

### AgentProcedure

A named complex agent procedure — D4rt [source] run under the [scopes] it targets (the `agent` scope by default).

#### Constructors
```dart
const AgentProcedure({
  required this.name,
  required this.source,
  this.scopes = const [agentScopeName],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The procedure's identity / label. |
| `source` | `String` | The D4rt source executed under the agent scope. |
| `scopes` | `List<String>` | The scope names the procedure runs under. |

### AgentFilesUnavailable

Raised when a `file_*` method is reached but no [FileTools] was bound to the [AgentToolsApi] (the `files` surface is optional in mode a).

**implements Exception**

#### Constructors
```dart
const AgentFilesUnavailable(this.operation);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `operation` | `String` | The offending operation. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### AgentToolsApi

The unified, JSON-returning agent tool facade over the `llm_and_d4rt_tools.md` §8.2 toolsets.

#### Constructors
```dart
const AgentToolsApi({required this.doc, required this.memory, this.files});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `doc` | `DocTools` | The document tools (`doc_search` / `doc_search_iterate` / `doc_reflect` / `doc_add_node`). |
| `memory` | `MemoryTools` | The memory tools (`mem_recall` / `mem_refresh`). |
| `files` | `FileTools?` | The file tools (`file_read` / `file_find` / `file_write`), or `null` when the file surface is not granted in this profile. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `search(String query, {int? pageSize})` | `Map<String, Object?>` | `doc_search` — opens a cursor for the text [query] and returns the first page as JSON (`cursorId`, `matches`, `done`, `remaining`). |
| `searchNext(String cursorId, {int? pageSize})` | `Map<String, Object?>` | `doc_search_iterate` — advances the cursor named [cursorId] by one page. |
| `reflect(String path)` | `Map<String, Object?>` | `doc_reflect` — the meta-model facts (kind / class / allowed children) the node at [path] addresses, as JSON. |
| `recall(String query, {int k = 10})` | `Future<Map<String, Object?>>` | `mem_recall` — the fused two-tier recall for [query], as JSON (`hits`, `degraded`). |
| `refresh()` | `Future<Map<String, Object?>>` | `mem_refresh` — runs the bound re-index callback, as JSON. |
| `fileRead(String path)` | `Map<String, Object?>` | `file_read` — the file at [path] as JSON (`exists`, `content`). |
| `fileFind(String glob, {String dir = '.'})` | `Map<String, Object?>` | `file_find` — basename-glob matches under [dir] as JSON. |
| `fileWrite(String path, String content)` | `Map<String, Object?>` | `file_write` — writes [content] to [path] (whitelist-checked) as JSON; a rejected write is `{ok:false, error}`, never a throw. |

### BrainAgentSubstrate

Runs the complex agent procedure wrapped by a Tom Brain session — `llm_and_d4rt_tools.md` §10 mode (b).

**implements AgentSubstrate**

#### Constructors
```dart
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
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `procedure` | `AgentProcedure get` | The complex agent procedure this substrate drives. |
| `scope` | `MemoryScope get` | The Tom Brain addressing each run executes under. |
| `mode` | `String` | The substrate's mode label, as it appears in a run record. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(AgentTask task)` | `Future<AgentRunResult>` | Runs `task` on this substrate and returns its outcome. |

### ConversationalTurn

One completed conversational turn: the [task] the driver chose, the procedure [result] the base substrate produced, and the [recalledPaths] that informed the turn.

#### Constructors
```dart
const ConversationalTurn({
  required this.index,
  required this.task,
  required this.result,
  required this.recalledPaths,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `index` | `int` | The zero-based turn index in the conversation. |
| `task` | `AgentTask` | The task the driver chose for this turn (goal + structured inputs). |
| `result` | `AgentRunResult` | The procedure's outcome for this turn (run through the base substrate). |
| `recalledPaths` | `List<String>` | The memory paths the per-turn RAG recall surfaced before the driver decided this turn — the per-prompt augmentation `llm_and_d4rt_tools.md` §10 mode (a) calls for. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the trail / MCP surface. |

### ConversationContext

The running context handed to a [ConversationalDriver] to decide the next turn: the standing [goal], the [turnIndex] about to run, the [priorTurns] already completed, and the [recall] (and flattened [recalledPaths]) the substrate pulled for this turn.

#### Constructors
```dart
const ConversationContext({
  required this.goal,
  required this.turnIndex,
  required this.priorTurns,
  required this.recall,
  required this.recalledPaths,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `goal` | `String` | The standing free-text goal driving the whole conversation. |
| `turnIndex` | `int` | The zero-based index of the turn the driver is about to decide. |
| `priorTurns` | `List<ConversationalTurn>` | The turns completed so far (read-only), oldest first. |
| `recall` | `Map<String, Object?>` | The raw per-turn recall JSON (`hits`, `degraded`) the substrate pulled before this decision — the RAG augmentation the driver reasons over. |
| `recalledPaths` | `List<String>` | The flattened recall hit paths, oldest-ranked first — the cheap view a driver usually needs. |

### ConversationalDecision

A driver's decision for one turn: either **stop** the conversation, or **run** the complex procedure with chosen [inputs] (and an optional per-turn [goal] override).

#### Constructors
```dart
const ConversationalDecision._({
  required this.stop,
  this.reason,
  this.goal,
  this.inputs = const <String, Object?>{},
});
const ConversationalDecision.run({
  Map<String, Object?> inputs = const <String, Object?>{},
  String? goal,
}) : this._(stop: false, inputs: inputs, goal: goal);
const ConversationalDecision.stop({String? reason})
    : this._(stop: true, reason: reason);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `stop` | `bool` | Whether the conversation should stop *before* running this turn. |
| `reason` | `String?` | Why the driver stopped (only meaningful when [stop] is `true`). |
| `goal` | `String?` | An optional per-turn goal override; when `null` the standing goal is used. |
| `inputs` | `Map<String, Object?>` | The structured inputs merged into the procedure's task argument (e.g. |

### RecordingConversationalDriver

A host-independent [ConversationalDriver] that replays a scripted list of [ConversationalDecision]s and records every [ConversationContext] it saw.

**implements ConversationalDriver**

#### Constructors
```dart
RecordingConversationalDriver(List<ConversationalDecision> decisions)
    : _decisions = List.of(decisions);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `seenContexts` | `List<ConversationContext>` | The contexts handed to the driver, in order — the per-turn decision inputs. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `nextTurn(ConversationContext context)` | `Future<ConversationalDecision>` | Decides the next turn from the conversation so far. |

### ConversationalAgentSubstrate

Runs the complex agent procedure across **multiple conversational turns** — the live mode-(a) realisation (`llm_and_d4rt_tools.md` §10).

**implements AgentSubstrate**

#### Constructors
```dart
ConversationalAgentSubstrate({
  required AgentSubstrate base,
  required AgentToolsApi tools,
  required ConversationalDriver driver,
  int maxTurns = 8,
  bool stopOnError = true,
  int recallK = 10,
})  : _base = base,
      _tools = tools,
      _driver = driver,
      _maxTurns = maxTurns,
      _stopOnError = stopOnError,
      _recallK = recallK;

final AgentSubstrate _base;
final AgentToolsApi _tools;
final ConversationalDriver _driver;
final int _maxTurns;
final bool _stopOnError;
final int _recallK;

final List<ConversationalTurn> _turns = [];
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `baseMode` | `String get` | The mode of the base substrate each turn runs through (`direct` or `tom_brain`). |
| `turns` | `List<ConversationalTurn> get` | The completed turns of the most recent [run], oldest first. |
| `mode` | `String` | The substrate's mode label, as it appears in a run record. |
| `stopReason` | `String?` | Why the run stopped, or `null` while it is still going. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(AgentTask task)` | `Future<AgentRunResult>` | Runs `task` on this substrate and returns its outcome. |

### DirectAgentSubstrate

Runs the complex agent procedure directly — `llm_and_d4rt_tools.md` §10 mode (a).

**implements AgentSubstrate**

#### Constructors
```dart
DirectAgentSubstrate({
  required AgentToolsApi tools,
  AgentProcedure? procedure,
  String scopeName = agentScopeName,
})  : _procedure = procedure ?? AgentProcedure.searchRecallEditVerify,
      _scopeName = scopeName,
      _registry = ScopeRegistry()
        ..register(agentScope(tools, name: scopeName));
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `procedure` | `AgentProcedure get` | The complex agent procedure this substrate drives. |
| `mode` | `String` | The substrate's mode label, as it appears in a run record. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(AgentTask task)` | `Future<AgentRunResult>` | Runs `task` on this substrate and returns its outcome. |

### RunEffort

The **effort metrics** of one agent run — the quantitative trail the run envelope records alongside each [BrainRunRecord].

#### Constructors
```dart
const RunEffort({
  required this.wallClock,
  required this.transcriptChars,
  required this.transcriptLines,
  required this.inputCount,
  required this.ok,
  required this.produced,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `wallClock` | `Duration` | Wall-clock time the loop body took. |
| `transcriptChars` | `int` | Characters the run printed (the captured transcript length). |
| `transcriptLines` | `int` | Lines the run printed (newline-delimited transcript lines; `0` for an empty transcript). |
| `inputCount` | `int` | Number of structured inputs the task carried. |
| `ok` | `bool` | Whether the run completed without throwing. |
| `produced` | `bool` | Whether the run produced a non-null `main()` output. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A JSON-able view of the metrics — the run node's `payload`. |
| `toString()` | `String` | A compact diagnostic rendering. |

### BrainRunRecord

One recorded agent run inside a Tom Brain named memory (the run trail).

#### Constructors
```dart
const BrainRunRecord({
  required this.scope,
  required this.task,
  required this.result,
  required this.effort,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `scope` | `MemoryScope` | The Tom Brain addressing the run executed under. |
| `task` | `AgentTask` | The task the run was given. |
| `result` | `AgentRunResult` | The run's captured result. |
| `effort` | `RunEffort` | The run's effort metrics (wall-clock, transcript size, outcome). |

### RecordingBrainEnvelope

An in-memory [BrainSessionEnvelope] that records the sessions it opens and the runs it captures.

**implements BrainSessionEnvelope**

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `openedSessions` | `List<MemoryScope>` | The scopes sessions were opened for, in order. |
| `runs` | `List<BrainRunRecord>` | The runs recorded into named memory, in order (the run trail). |
| `recordedRuns` | `List<BrainRunRecord>` | Every run this substrate recorded, in order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|

### SpecBrainSessionEnvelope

A [BrainSessionEnvelope] that records each run into the document's live, profile-isolated Tom Brain named memory.

**implements BrainSessionEnvelope**

#### Constructors
```dart
SpecBrainSessionEnvelope(this._memory);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `runs` | `List<BrainRunRecord>` | The runs recorded into named memory this session, in order — the live run trail (mirrors what was persisted, for in-process inspection). |
| `recordedRuns` | `List<BrainRunRecord>` | Every run this substrate recorded, in order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|

## Enums

### AgentSubstrateMode

The two `llm_and_d4rt_tools.md` §10 agent substrate modes the application chooses between.

| Value | Meaning |
|-------|---------|
| `direct` | Mode (a) — the direct Agent SDK substrate ([DirectAgentSubstrate]). |
| `tomBrain` | Mode (b) — the Agent-SDK-through-`tom_brain` substrate ([BrainAgentSubstrate]). |

### AgentToolGroup

The four agent toolset families (`llm_and_d4rt_tools.md` §8) an [AgentContext] can expose.

| Value | Meaning |
|-------|---------|
| `doc` | The `doc_*` tools (search / iterate / reflect / add_node) — need `spec`. |
| `memory` | The `mem_*` tools (recall / refresh) — need `memory`. |
| `file` | The `file_*` tools (read / find / write) — need `files`. |
| `script` | The `script_*` tools (author / validate / run / list / get) — author and run scripts against the live document, so they need `spec`. |

## Global Functions and Constants
