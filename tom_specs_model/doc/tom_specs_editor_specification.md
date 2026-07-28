# TomSpecs Editor — Specification

**Quest:** tom_specs
**Status:** Complete design specification — the single source for the TomSpecs Editor. Model-driven document editing over the generated Dart SOM API (`tom_som_dart_v0` typed facade over `tom_som_dart_runtime`), Claude Code integration through the Anthropic Agent SDK over the VS Code bridge, projection-root semantics with a pure-projection invariant, and a buildkit-driven cross-platform build.
**Scope:** A full, Tom Forge–based specification editor with Claude Code integration through the Anthropic Agent SDK.

> This document specifies the **TomSpecs Editor**, the specification-authoring app at `tom_forge/tom_specs_editor`. It is a separate application from `tom_ai/ai_build/tom_specs_reviewer`, the object-model structure reviewer, which has its own specification (`tom_specs_reviewer_specification.md`). The editor carries its own **rendering** of the structure tree and review feature, styled to the Forge shell, over the model *readers* and *display semantics* it shares with the reviewer (requirement *Q1*, §4.4).

---

## 1. Goals & Intent

Build a desktop editor for authoring, reviewing, and AI-assisting the production of TomSpecs documents. The editor is driven by the **object model** (`tom_specs_model`), not free-form markdown. A Claude Code agent navigates and edits the specification through a focused tool surface, never needing to read the whole document; every agent change is logged and reviewable.

Objectives (with the originating requirement letters):

1. Tom Forge **shell** with **three apps** — *DocSpecs Specification*, *CodeSpecs Specification*, *Implementation* (only the first functional in phase 1) (*p*).
2. **Claude Code** via the Anthropic Agent SDK over the VS Code bridge; SDK owns history/memory (*a, d, h*).
3. **Chat / prompt-queue / prompt-trail** mirroring the VS Code extension's **Anthropic** panel only (*e.4, f, g*).
4. **Custom editors** for queue, queue templates, profiles, prompt templates, chat variables, timed requests — each with an **"open raw file"** button (*a, i, s*).
5. **Comprehensive settings** exposing the Agent SDK `Options` surface (*b-of-v1*, now §7).
6. **Navigation + mutation tools** giving the model three views (max model structure, actual instance structure, actual content) and the ability to edit freely (*c*).
7. **Full undo/redo** wired into the Forge undo protocol (*b*).
8. **Agent change log** with a three-way review per change (*Q5*).
9. **Generic markdown display widget** in every field label/content (*j*); inline **Flutter-layout fields** via `tom_d4rt_flutter` (*k*); embedded **Dart editor** via `tom_dart_editor` (*l*).
10. **Compact tree**: all sections shown, empty ones collapsed to clickable chips; list add/remove buttons (*d*).
11. **`*.docspecs.yaml`** save (object model + review, two-pass) and **Markdown import/export** with a parse-rejection protocol and per-/multi-/global-document options (*n, o, Q9, Q10*).
12. **DocSpecs schema generator** from the object model (*Q8*).
13. **Cross-platform build script** (Linux/Windows/macOS) that builds the app from scratch (*Q6*).

**No JavaScript placeholders** in this editor (*c*). Non-goals phase 1: own history/memory (SDK-owned, *h*); CodeSpecs/Implementation content; `tom_flutter_ui` migration (phase 2, *l*).

---

## 2. Resolved Decisions

| # | Decision |
| --- | --- |
| Q1 | The editor is its own project, `tom_forge/tom_specs_editor`, separate from `tom_specs_reviewer`. The tree renderer + review feature are **rendered separately** in each app and styled to their host; the model readers and the *display semantics* of the annotations are shared through `tom_som_dart_runtime`, and a shared fixture guards the two renderings against drift (§4.4). |
| Q2 | Shared agent code → **`tom_core_agentic`** (`tom_ai/core/tom_core_agentic`, exists, v1.5.0). |
| Q3 | Placeholder engine ported/reimplemented in Dart — reuse `tom_core_agentic`'s `PlaceholderResolver`; **no JS** (`${{…}}` expression evaluator left unwired). |
| Q4 | Assume a running VS Code CLI server. Port configurable; **scan 19900–19909 on startup**, show each live server's workspace, let user pick. Tests assume `19900`. |
| Q5 | Agent may change the document freely; every change is logged; each is reviewable in a **three-way view** (last-saved section content · this edit · current content). |
| Q6 | Bundle a generated `spec_model.json`; provide a **build script** that performs every step to build the app from scratch on Linux/Windows/macOS. |
| Q7 | Store the document **in the object model**, serialize on save. Undo = keep initial load + one snapshot per change, **max ~50**, discard oldest. |
| Q8 | Add a **DocSpecs schema generator** (none exists yet); bundle generated schemas in-app and write to the workspace schema location. |
| Q9 | A spec is **one document** with multiple entry points (document roots). **Solution Blueprint** is the top nav option; the other roots follow a separator, alphabetical. Import/export dialog offers **single / multiple / global** document selection. |
| Q10 | YAML reflects object model **plus** review info, restoring full UI state; serialize in **two passes** (document, then review) as two top-level entries; deserialize symmetrically. |
| a | Custom editors with raw-file open button (modelled on the VS Code editors). |
| b | Full undo/redo via Forge protocol. |
| c | No JavaScript placeholders. |
| d | Compact, variable-height tree; empty sections/fields as clickable chips; list add/remove buttons. |

### Connection, undo, layout & build decisions

| # | Decision |
| --- | --- |
| C1 | Workspace-identify handshake is available in the VS Code API — the scanner uses it to label each live port. |
| C2 | On a lost/changed server: show an informational popup and **retry 3× (after 10 s, 30 s, 60 s)**, keeping any running prompt/queue alive. If still gone or now a *different* workspace, show a modal telling the user what to do and **confirm** before failing — never auto-interrupt a running prompt; only fail if the user chooses to. |
| A1 | The agent `cwd` is the **specification's own folder** (which may hold subfolder assets like images shown in the document). |
| A2 | **Per-specification SDK session id**, refreshed automatically on "message id mismatch / invalid session" errors. |
| T1 | Everything is text *eventually*; diffs use the section's **YAML fragment** with **block (multi-line) scalars**, so line breaks survive 1:1. |
| T2 | Undo works **per agent turn and per individual change**. |
| M1 | Picking a pane in the 3-way merge **creates a new undo entry**; for now the user can only **pick one of the three panes** (no field-level merge). |
| M2 | The **change log resets on save**; ordinary undo still works after save. |
| U1 | Snapshots **share unchanged leaf objects** (structural sharing) → cheap full snapshots; a snapshot is taken **whenever an input field changes and there were changes**. |
| U2 | Agent changes are undoable via the **change log**; the user may edit the document freely at any time (accepting possible LLM confusion). |
| P1 | The **quest = workspace name**; placeholders resolve from that workspace's `_ai/` folder. SDK-owned concepts (e.g. memory) are simply unused. |
| P2 | A **single capability level** for now. |
| E1 | Editor files all live under the **Forge process's workspace folder** (which contains the specification): the spec YAML plus configuration / UI-state files. |
| E2 | The document editor has **no raw-file view** (it edits the object model); only the **configuration files** can be opened as raw files. |
| D2 | Chip click = **inline expand**. |
| D3 | The **section-ID path root→leaf is globally unique**; list items carry `-1`, `-2` index suffixes, so the full path stays unique. |
| D4 | **Empty = "no value"**. |
| D5 | **Review-state badges sit next to section headlines**; **empty-node chips render below**, under the section content (or under the last existing subsection). |
| V1 | Confirmed — all roots share a **single object tree**. |
| V2 | Add **one new top-level root class that points to all 14 document roots**, so the entire spec is a single object model/tree with one true root (resolves the root-local-data concern: everything hangs off the one tree). |
| IO1 | Import is always a **full overwrite** (of the whole document or the sub-document's covered part); approve-style merge is a possible *later* feature. |
| IO2 | Round-trip formatting preserved by using **multi-line YAML scalars for ALL keys** (eases diff/merge of small text changes too). |
| S1 | **One global schema plus one per projection root** (13 derived today). |
| S2 | Schema **version counts up (1, 2, …) when the object model changes**; aim to keep it backwards compatible. |
| B1 | Dart-editor **summaries are pre-generated and embedded** in the app. |
| B2 | Stamp a **model version**; introduce a **`buildkit.yaml` versioner** in the model project, bumped on official builds. |
| D1 | Reusable agent/chat views go in a new **`tom_forge_agentic`** project so all agent-inclusive tools share them. |

### Reconnect, serialization, projection-root & provider decisions

| # | Decision |
| --- | --- |
| N1 | On transport failure there is no way to hold the socket open; instead, **after reconnect re-send the interrupted prompt with an editable prefix** ("this was interrupted due to a technical error"). The prefix text is an editable template. |
| N2 | **No bridge/API key is involved.** The **VS Code workspace and the document workspace may and will differ** — that's expected. There is **no third root**; just those two. |
| N3 | A result is treated as a **session error** (→ refresh the session id) when its error text **contains `session`, `message`, or `msg`** (case-insensitive). Matched against `error_during_execution`/`is_error` results and thrown bridge errors (§7.2). |
| N4 | Confirmed — the YAML save is **human-readable**; the document can be read directly in YAML form because every key is a block scalar. |
| N5 | **Modify `tom_specs_model`** as needed to give the editor simple immutable/copy-on-write handling for snapshotting — implement whatever shape is cleanest for the editor. |
| N6 | **After a document save**, only entries in the **editor undo queue** can be undone (these can include edits that were earlier in the now-cleared change log); the change log itself is empty. |
| N7 | The generic provider abstraction (`LlmProvider` interface + `AgentSdkLlmProvider` + `AgentSdkSessionStrategy`/`AgentSdkSessionStore`) lives in **`tom_core_agentic`** (single source of truth); `tom_core_agentic` depends on `tom_vscode_scripting_api`. The HTTP/stub providers (`OllamaLlmProvider`, `OpenAiPassthroughProvider`, `StubLlmProvider`) stay in `tom_brain_substrate` and consume the abstraction from `tom_core_agentic`. **`tom_forge_agentic` holds UI only** (§4.3). |
| N8 | Use the **`buildkit` tool's `:versioner`** command, configured via a **`buildkit.yaml`** in the model project; buildkit drives **all** build steps (§17). |
| N9 | The new top-level class is the **canonical tree root**, **not a document node of its own** (no `@SectionId`, not an extra document sibling). Serialization must emit the document **once** — the projection roots must **not** produce duplicate copies of the shared SBP content (§14, §15.1). |
| N10 | The **interrupted-prompt re-send prefix** is a **field on the Anthropic profile**, edited in the profile editor. When copying profiles from the VS Code extension, set it to a **reasonable default** ("This was interrupted due to a technical error."). |
| N11 | Serialization via **`toYaml` methods on the model**. The **global root's `toYaml` writes only the Solution Blueprint content** (the native `*.docspecs.yaml`). Each other root also has a `toYaml`, used **only when writing that root's individual file**. **Before** writing an individual root, the global root runs a **connect pass** binding the projection root's (possibly-null) references to the live SBP sections — connecting *before write* (not after read) avoids keeping copies in sync and always binds to whatever is currently in SBP. |
| N12 | The connection is the existing **`@MapsTo` / `@DetailedIn`** links. A **null section is null in the SBP target too** (one shared tree — no divergence). This is only ever a question at the root level; the underlying **invariant** is that **a projection root contains no content that is not also in the Solution Blueprint** — this **must be validated** (added to the `tom_specs_model_rules.md` §10.2 validator). |
| N13 | `tom_core_agentic` (with the provider abstraction + `tom_vscode_scripting_api` dep) is published and consumed by `tom_brain_*`; the moved code is deleted and the HTTP providers re-export the abstraction from `tom_core_agentic`, so no `tom_assistant` consumer pins old provider classes. |

---

## 3. Source Material (verified facts the design builds on)

### 3.1 Tom Forge shell (`tom_forge/tom_forge_ui`, `tom_forge_core`, `tom_forge_app`)

- Facade `ForgeShellApi`; default impl `DefaultShellApi.withDefaultsAndFileSystem(...)` (`tom_forge_ui/lib/src/defaults/default_shell_api.dart`).
- `ForgeModule` (`…/shell/forge_module.dart`) contributes `editors` (`ForgeEditor`), `views` (`ForgeView`), `actions`, `shortcuts`, `applications`, `configPanels`. Lifecycle `activate(shell)`/`deactivate()`. Registration explicit & total via `DefaultModuleRegistry.register` — the hook for our custom module set (*m*).
- Multi-app: `ForgeApplication(title, icon, layout: ApplicationLayout(...), workspaceFolder?)`; launcher swaps active app. Layout regions: `leftPanel/rightPanel/bottomPanel/middlePanels` (up to 4 middle splits); `ForgePanelLocation{left,right,bottom,middle}`; runtime control `shell.layout.openPanel/closePanel/togglePanel/openFile/openEditor/splitMiddlePanel`.
- `ForgeEditor` is URI-routable (`canHandle(uri)`/`canHandleContent`), `getContent()`, `saveState()/restoreState()`, `isDirty`/`markClean`. `ForgeConfigPanel` lives in the Settings dialog only.

### 3.2 Forge undo/redo protocol (requirement *b*)

- `ForgeTextContext` (`tom_forge_ui/lib/src/components/forge_component.dart`): `bool isDirty`, `bool canUndo`, `bool canRedo`, `Stream<ForgeTextContext> onContextChanged`.
- `ShellEditorIntegration` (`…/integrations/shell_editor_integration.dart`): editor calls `registerAction(StandardEditingActions.undoActionId, handler, isEnabled: …)` and `…redoActionId`; the shell routes global **Cmd/Ctrl+Z / Cmd/Ctrl+Shift+Z** to the focused editor's handlers.
- Shell-level history `DefaultUndoManager` (`tom_forge_core/lib/src/defaults/default_undo_manager.dart`): `push(UndoEntry(undo, redo, label))`, `beginUndoGroup/endUndoGroup` → `CompositeUndoEntry`. Editors call `notifyTextEdit(label)` to register a bridge entry that delegates to the editor's own `undo()/redo()`.
- Editors implement **local** history (e.g. `tom_md_editor`'s `UndoHistory<MdEditOperation>`, maxDepth 100) and expose it through the contract. Dirty = current-content ≠ last-saved-content (computed).
- **Our binding:** snapshot-based local stack (Q7), exposed via `ShellEditorIntegration.registerAction` + `notifyTextEdit`. Agent edits use `beginUndoGroup`/`endUndoGroup` so one agent *turn* is one undo step (see §10).

### 3.3 Claude Code via the bridge (`tom_vscode_scripting_api`, `tom_vscode_bridge`, extension `agent-sdk-bridge.ts`)

- JSON-RPC 2.0 over TCP loopback, 4-byte BE length framing; CLI integration server ports **19900–19909** (one per VS Code window). Dart client `VSCodeBridgeClient.connect(host, port)`.
- `AgentSdkClient.query({required String prompt, Options? options}) → Stream<SdkMessage>`; bridge `agentSdk.queryVce` relays `agentSdk.chunk`; typed messages `SdkAssistantMessage/UserMessage/ResultMessage/SystemMessage/PartialAssistantMessage`.
- API key owned by the extension. Session/history owned by the SDK (`resume/sessionId/resumeSessionAt/forkSession/persistSession/continueSession`).
- Custom tools: `SdkMcpTool(name, description, inputSchema, handler)` in `McpSdkServerConfig` under `Options.mcpServers`; calls arrive via reverse RPC (`agentSdk.toolCall` → `AgentSdkToolRegistry`). Built-in CC tools via `ToolsClaudeCodePreset` + `allowedTools/disallowedTools`.
- Full `Options` surface for the settings screen — see §7.1.

### 3.4 Anthropic chat panel to mirror (`tom_ai/vscode/tom_vscode_extension`)

- Send: `AnthropicHandler.sendMessage()`; we use the **Agent SDK** leaf only. Queue: `PromptQueueManager` with `QueuedPrompt/QueuedPrePrompt/QueuedFollowUpPrompt` (statuses `pending/sending/sent/error`, repeat counts, pre-prompts, follow-ups); YAML `_ai/queue/*.entry.queue.yaml` + queue-settings. Trail: pairs (`requestId`, ts, sequence) under `_ai/trail/anthropic/{quest}/` + summary `.prompts.md`/`.answers.md`. Repeated prompts: `ReminderTemplate` + `TimedRequest`. Templates: `anthropic.userMessageTemplates`; queue templates per transport. Profiles: full field set at `anthropic.profiles`. Chat variables: built-ins + `custom.*`, per-window YAML. Placeholders: `${name}`, `${{js}}`, `{{name}}` alias; file-injection tokens + namespaces; capability levels.

### 3.5 VS Code custom editors to replicate (requirement *a*)

Seven webview editors, all reloading from disk and all exposing an **"open raw file"** affordance via `openPanelFile(type)` / `showFile` / `showTemplateFile` (`tom_vscode_extension/src/utils/panelYamlStore.ts`, handlers under `src/handlers/*Editor-handler.ts`):

| Editor | Backs onto | Notable controls | Raw-file button |
| --- | --- | --- | --- |
| Prompt Queue (`tomAi.editor.promptQueue`) | `_ai/queue/*.entry.queue.yaml` (one per entry) | list+detail; prompt, pre/follow-ups, reminder, transport; add/remove/move | `showFile`/`showEntryFile` |
| Queue Templates (`…queueTemplates`) | `<name>.template.queue.yaml` | shared entry editor; add/copy/rename/delete/save/queue | `showTemplateFile` |
| Reusable Prompts (`…reusablePrompts`) | scoped `*.prompt.md` | scope/subscope/file picker; md edit+preview | open `.prompt.md` |
| Global Templates (`…globalTemplates`) | `sendToChatConfig.json` | category dropdown; per-category fields; add/copy/rename/delete/save; placeholder help | *(none — config JSON)* |
| Chat Variables (`…chatVariables`) | `_ai/local/{ws}.chatvars.yaml` | key/value table + change log; project picker | `showFile` |
| Timed Requests (`…timedRequests`) | `{ws}.timed.yaml` | schedule (interval/scheduled), enabled, reminder | `showFile` |
| Context & Settings (`…contextSettings`) | composite | accordion: variables + quest/role + reminders | indirect |

### 3.6 Shared agent layer — `tom_core_agentic` (requirement *Q2*)

- `tom_ai/core/tom_core_agentic/`, pkg `tom_core_agentic` **v1.8.0**, "Generic building blocks for agentic systems". It **already depends on `tom_vscode_scripting_api` (`>=1.1.0`)** for the bridge provider implementation, alongside `tom_basics`, `yaml`, `yaml_edit`, `crypto`, `path`.
- **The generic provider/model API lives here now.** `tom_core_agentic/lib/src/llm/` defines the generic **`LlmProvider`** interface (`String get id`; `Future<LlmCallReport> complete(WirePrompt, LlmOptions)`; `Stream<LlmStreamEvent> completeStream(WirePrompt, LlmOptions)`), the Agent-SDK-over-bridge implementation **`AgentSdkLlmProvider`** (built on `AgentSdkClient` + `VSCodeBridgeAgentSdkTransport` from `tom_vscode_scripting_api`), and the session-lifecycle types **`AgentSdkSessionStrategy`** (interface, default `NoSessionStrategy`) + **`AgentSdkSessionStore`**. `promptSha256` is defined here (`lib/src/prompt_sha256.dart`).
- The HTTP/stub providers — `OllamaLlmProvider`, `OpenAiPassthroughProvider`, `StubLlmProvider` — remain in **`tom_brain_substrate`** (they extend a local `HttpLlmProviderBase`); `tom_brain_substrate`/`tom_brain_run` re-export `LlmProvider`/`AgentSdkLlmProvider` from `tom_core_agentic` for back-compat, so there is one source of truth (§4.3).
- Also reusable: **`PlaceholderResolver`** (forms `${name}`, `${name?}`, `${{ expr }}`, `${env:NAME}`; recursive; strict/lenient; async/sync; pluggable `PlaceholderExpressions`), `PlaceholderStack`, `PlaceholderError`; `YamlConfigReader`/`YamlConfigWriter`; `TtlCache`, `TokenBucket`, `CancellationToken`, `Deadline`, `AsyncShutdownCoordinator`; `mcp_auth/BearerAuthContract`; `ToolCallTextParser`; `DedupById`, `TextPreview`.
- `tom_forge_agentic` adds only the Flutter **UI** on top of these models/providers; the raw Agent-SDK transport stays in `tom_vscode_scripting_api`.

### 3.7 Spec object model & document format (`tom_ai/ai_build`)

- `tom_specs_core` annotations; `tom_specs_model` 14 roots — the `D00SolutionBlueprint` master, the 12 Phase 3 documents (`D01`…`D12`), and `D13CodeSpecsProjection`, the Phase 4 code-generation projection. **Crucial semantics:** the 12 Phase 3 roots are `@Document(basedOn:[SolutionBlueprint])` and aggregate **the same** SBP classes via typed fields with `@MapsTo`/`@DetailedIn`; `D13` is a projection by the same rule but reaches its subtrees directly, driven by `@CodeSpecKind` rather than `@DetailedIn` (its `@CodeSpecsProjection()` marker exempts it from the `tom_specs_model_rules.md` §10.2 detail-count check only). So a spec's single source of truth is the **SolutionBlueprint instance**; the other roots are **projections** over it (this underpins Q9 — see §14).
- `spec_model.json` (`ModelJsonExporter`, `tom_specs_clitool/bin/model_json.dart`): `{generatedAt, classCount, rootCount, roots[], classes{}}`; `SpecClass{name,sectionId,doc,help,mapsTo,detailedIn,fields[]}`; `SpecField.kind ∈ {list,form,section,content,enum,complex,scalar}` with kind metadata.
- DocSpecs (`tom_doc_specs`): `<!-- docspec: id/version -->`; schema YAML `{id}-{version}.docspecs-schema.yaml` (`section-types`{prefix,counts,pattern-check,format,text-required,allowed-tags,validation-prompt,required-fields}, `form-types`); runtime `DocSpecsFactory`→`SpecDoc` (`getSection/getSpecSectionType/getSectionsByTag/isValid`), `SpecSection{type,tags,format,fields,text,sections}`. Content joins to model by **section ID**.
- `tom_specs_reviewer`: `SpecModel.fromJson` over the asset; `spec_tree.dart`; `ReviewStore` (per-path YAML).

### 3.8 Generated Dart SOM API (`tom_som_dart_v0` over `tom_som_dart_runtime`)

The SOM language API generator emits a **typed Dart facade** over the object model, and the editor consumes it as the strongly-typed access layer for spec documents.

- **`tom_som_dart_runtime`** (pkg `tom_som_dart_runtime`, hand-written, versioned independently) is the **generic, unversioned runtime**: `SomNode` / `SomList` / `SomScalar` (`src/som_facade.dart`) plus the version-compatibility surface — `checkSomModelVersion`, `somEditabilityFor`, `SomEditability`, `SomVersionException`. All generated facades depend on it, and it is **shared across model majors** (not duplicated per version).
- **`tom_som_dart_v0`** (pkg `tom_som_dart_v0`, `publish_to: none`, generated `lib/tom_som_dart_v0.dart`) is the **typed facade for model major 0**: one class per SOM class (~3900 classes), each `extends SomNode`, mirroring the 14 roots (`D00SolutionBlueprint` … `D13CodeSpecsProjection`). Typed access reads/writes through the runtime, so it stays a thin, validated projection of the underlying document tree rather than a second copy of state. See `tom_som_dart_v0/example/a_typed_access.dart` (`D00SolutionBlueprint(doc)` over a live document).
- **Model version stamp:** the generated facade carries `modelVersion` (currently `'1.0'`); `checkSomModelVersion` / `SomEditability` decide whether a document loaded at a given stamp is fully editable, read-only, or rejected. The editor bundles the stamp with `spec_model.json` (§17 B2) so a built app reports exactly which model it was generated against.
- **Parallel major versions (`_v0`, `_v1`, …).** Each incompatible model major ships as a **separately-named package** — `tom_som_dart_v0`, and later `tom_som_dart_v1`, `tom_som_dart_v2`. Because the package *names* differ, their class symbols never collide, so **multiple majors can be depended on and used side-by-side in the same app with no conflict**. This is deliberate: it lets the editor open, compare, and migrate documents authored against different model majors simultaneously — a capability the project will need as the model evolves. The single shared `tom_som_dart_runtime` underpins all of them. **Today only `_v0` exists**; the parallel-version story is a designed-in property, not yet exercised.

---

## 4. Architecture

### 4.1 Project placement & shared code (Q1, Q2)

- **App:** `tom_forge/tom_specs_editor` (new Flutter Forge app).
- **Generic model/provider API + placeholder engine + agent models:** `tom_core_agentic` (extended — see §4.3).
- **Agent-SDK transport:** `tom_vscode_scripting_api` (existing `AgentSdkClient`/`VSCodeBridgeClient`/`VSCodeBridgeAgentSdkTransport`).
- **Reusable agent/chat *UI* → new `tom_forge/tom_forge_agentic`** (D1, N7). This project holds **UI only** — chat composer, prompt queue, prompt trail, agent settings, navigation/mutation tool surface, change-log + three-way review — so every agent/chat-enabled Forge tool renders an identical experience. **All non-UI logic (provider API, models, placeholder engine) lives in `tom_core_agentic`.** `tom_specs_editor` depends on both; the spec-specific document/structure modules stay in `tom_specs_editor`.

### 4.3 Generic provider/model API (N7)

The Agent SDK is wired behind a **generic provider abstraction**, not consumed directly by the UI — so the same chat/queue/trail UI can run on any agent backend (Agent-SDK-via-bridge being one implementation).

- **The abstraction lives in `tom_core_agentic`** (v1.8.0). `tom_core_agentic/lib/src/llm/` owns the generic **`LlmProvider`** interface (`String get id`; `Future<LlmCallReport> complete(WirePrompt, LlmOptions)`; `Stream<LlmStreamEvent> completeStream(WirePrompt, LlmOptions)`) with its message/stream-event models, the Agent-SDK-over-bridge implementation **`AgentSdkLlmProvider`** (built on `AgentSdkClient` + `VSCodeBridgeAgentSdkTransport` from `tom_vscode_scripting_api`, on which `tom_core_agentic` depends at `>=1.1.0`), and the session-lifecycle types **`AgentSdkSessionStrategy`** (default `NoSessionStrategy`) + **`AgentSdkSessionStore`**. `promptSha256` is defined here.
- **The HTTP/stub providers stay in `tom_brain_substrate`.** `OllamaLlmProvider`, `OpenAiPassthroughProvider`, and `StubLlmProvider` extend a local `HttpLlmProviderBase` and remain in `tom_brain_substrate`; `tom_brain_substrate`/`tom_brain_run` re-export `LlmProvider`/`AgentSdkLlmProvider` from `tom_core_agentic` so there is a single source of truth for the abstraction and the bridge provider.
- **Layering:**
  - `tom_core_agentic` — provider/model API + the Agent-SDK/bridge provider impl, placeholder engine, prompt-queue/trail/profile models (no Flutter).
  - `tom_forge_agentic` — Flutter UI over those models/providers (no transport specifics).
  - `tom_specs_editor` — spec-specific modules + the bundled model/schema assets.
  - `tom_brain_substrate`/`tom_brain_run` — consume `tom_core_agentic` for the abstraction; add only the HTTP provider impls.

### 4.2 Module set (custom, not Forge defaults)

| Module | Type | Responsibility |
| --- | --- | --- |
| `SpecsShellModule` | bootstrap | Registers the 3 `ForgeApplication`s; app switching; common layout skeleton. |
| `SpecDocumentModule` | editor | Model-driven document editor (Col 1); opens `*.docspecs.yaml`; compact tree; md/d4rt/dart fields; undo/redo; agent change log. |
| `SpecStructureModule` | editor/view | Structure browser + structural review, rendered for the Forge shell over the shared readers and display semantics (Q1, §4.4). |
| `AgentChatModule` | views+service | **From `tom_forge_agentic`.** Chat composer (bottom), queue (Col 2), trail (Col 3); Agent-SDK client; mirrors Anthropic panel. |
| `AgentToolsModule` | service | **From `tom_forge_agentic`** (host registers spec-specific tools). Navigation + mutation `SdkMcpTool`s; feeds the change log + three-way review. |
| `SpecsConfigModule` | editors+configPanels | Custom editors (queue, templates, profiles, variables, timed, agent settings) with raw-file buttons; basic prefs as `ForgeConfigPanel`. Agent-generic editors reuse `tom_forge_agentic` widgets. |
| `MarkdownFieldModule` | widget lib | Generic markdown display widget (reuses `MdPreviewPanel`) + field renderers. |
| `RawFileModule` | editor | Plain YAML/Markdown text `ForgeEditor` opened by the "open raw file" buttons. |

### 4.4 Structure tree — shared with the reviewer, rendered separately (Q1)

`SpecStructureModule` and `tom_specs_reviewer` draw the same class graph, one in
the dark Forge shell and one on a light standalone canvas. The boundary between
them is drawn at **meaning versus paint**:

| Layer | Home | Shared? |
| --- | --- | --- |
| Readers — `SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, `FormFieldSpec`, `SpecFieldKind` | `tom_som_dart_runtime` (re-exported by `src/structure/spec_model.dart`) | yes |
| Display semantics — `SpecChip`, `SpecChipRole`, `SpecRowExtras`, the chip descriptor functions, `kRenderedAnnotations`, the structural-path segments | `tom_som_dart_runtime/src/spec_annotation_display.dart` | yes |
| Rendering — `src/structure/spec_tree.dart`, the palette, the per-row affordances | this project | no |

**The two surfaces may not disagree about what a marker *means*; they may
disagree about what it *looks like*.** Whether `cs?` is suppressed on a
follow-up-tagged node, whether a closed choice reports coverage, whether a
`@SectionIdPattern` is a fallback for a section id — these are statements about
the model, and one app answering them differently would make the same tree say
two different things. Colour is the opposite: a value that reads as "attention"
on a light canvas is illegible on the Forge shell's dark one. So chips name a
`SpecChipRole` and each app maps roles to its own palette.

The renderings stay **separate** rather than merging into a shared Flutter
widget package. `tom_som_dart_runtime` is pure Dart and cannot host widgets, so
convergence would need a new package — and what it would hold is two trees whose
hosts (a four-region Forge layout versus a standalone `MaterialApp`) and per-row
affordances (authoring actions versus the reviewer's `ReviewControls`) differ at
every row. That widget would be a parameter list of differences rather than
shared behaviour. What is genuinely common is the semantics, and that is what is
extracted.

**The divergence guard.** Separate renderings would otherwise drift silently, so
`tom_som_dart_runtime/spec_display_fixture.dart` carries a class graph
exercising **every** annotation in `kRenderedAnnotations`, plus
`expectedShowcaseChipLabels`, which computes the labels the shared descriptors
produce for it. Both apps render that fixture in
`test/structure_annotation_rendering_test.dart` and assert every label reaches
the screen. A new annotation therefore passes three gates — `kRenderedAnnotations`,
the fixture, then **both** trees — and a rendering added to one tree alone fails
the other app's test rather than accumulating unnoticed.

---

## 5. Layout (requirement *e*)

DocSpecs app `ApplicationLayout`:

- **Left panel** — compact **icon rail** opening custom editors into the middle area; optional second tab = document/section explorer with the **root navigator** (§14).
- **Middle panels** (3 splits): **(1) Document** `SpecDocumentEditor`; **(2) Prompt/Todo Queue** `PromptQueueView`; **(3) Prompt Trail** `PromptTrailView`.
- **Bottom panel** — **Chat composer** `ChatComposerView` (profile picker, placeholder-aware input, send/queue, streaming output).
- **Right panel** (optional) — context tools: validation, outline, **agent change log** (§9), navigation-tool call log.

CodeSpecs/Implementation apps reuse the skeleton with an empty document editor.

---

## 6. Connection & Bridge (requirement *Q4*)

- On startup, `AgentChatModule` **scans ports 19900–19909** on the configured host (default `127.0.0.1`). For each responsive CLI server it issues the **workspace-identify** handshake (available in the VS Code API — C1) to learn the **workspace folder** it serves, and presents a picker: *port · workspace · status*. The user selects one; the choice persists per spec.
- Tests assume a single server on **19900**.
- Settings allow pinning host+port (skip scan) and a manual reconnect.

### 6.1 Reconnect protocol (C2)

When the bound server stops responding, the transport itself is gone — there is **no way to hold the live socket / in-flight exchange open** (N1). We therefore preserve the *user's intent*, not the connection, and re-issue on reconnect.

1. Show a **non-blocking informational popup** ("lost connection to VS Code server, retrying…").
2. **Retry 3 times** with back-off: after **10 s**, **30 s**, **60 s**.
3. **Same workspace comes back** → reconnect silently, dismiss the popup. The prompt that was interrupted is **re-sent automatically**, prefixed with the active **profile's `interruptRetryPrefix` field** (N10) — default *"This was interrupted due to a technical error."*, edited in the profile editor (§12). The SDK **session is resumed** (or refreshed per §7.2 if the session is no longer valid).
4. **Still gone after the 3 retries** → show a **modal** telling the user what to do; the user's prompt is preserved (re-sendable). Fail (abort) **only if the user explicitly chooses to**.
5. **A server returns on the port but serves a *different* workspace** → show a **confirmation notification**; only bind to it (and then re-send per step 3) if the user confirms.

---

## 7. Agent Integration & Settings (requirements *b-of-v1*, *d*, *h*)

### 7.1 Exposable Agent SDK `Options` (settings surface)

| Group | Fields |
| --- | --- |
| Model/prompt | `model`, `fallbackModel`, `systemPrompt` (text/list/preset) |
| Tools/MCP | `tools` (list or CC preset), `allowedTools`, `disallowedTools`, `mcpServers` |
| Permissions | `permissionMode`, `planModeInstructions`, `allowDangerouslySkipPermissions`, `permissionPromptToolName` |
| Cost/turns | `maxTurns`, `maxBudgetUsd`, `taskBudget.total` |
| Reasoning | `thinking` (adaptive/enabled{budgetTokens}/disabled), `effort` (low/medium/high/xhigh/max) |
| Workspace | `cwd`, `additionalDirectories`, `settingSources`, `settings`, `managedSettings` |
| Session | `resume`, `sessionId`, `resumeSessionAt`, `forkSession`, `persistSession`, `continueSession` |
| Streaming/output | `includePartialMessages`, `outputFormat.schema` |
| Extensibility | `skills`, `agents`, `plugins`, `betas`, `env`, `extraArgs`, `debug`, `debugFile` |
| Connection (ours) | bridge host, bridge port (scan/pin) |

Bridge-managed (not shown): `abortController`, `executable*`, `pathToClaudeCodeExecutable`, callback-bearing `canUseTool/hooks/onElicitation/onStderr`.

### 7.2 Send pipeline

`Options` are assembled from the active **profile** (§11.4) + global **agent settings** + the **navigation/mutation MCP tools** (§8) as one `McpSdkServerConfig` + the **built-in CC preset** with allow/deny lists (*d*). `query(prompt, options)` streams to the chat composer; pairs append to the trail (§11.3); mutations append to the change log (§9).

- **Two distinct workspace roots, no key (A1, N2):** there are exactly **two** relevant roots and they **may and will differ** — (1) the **document/spec folder** (the agent `cwd`; placeholder resolution; holds subfolder assets like images) and (2) the **picked VS Code window's workspace** (supplies only the bridge *transport*). **No bridge/API key is involved** at this layer, and there is **no third root**.
- **Session (A2, N3):** a **per-specification SDK session id** is held in a sidecar (kept out of `document:`). It is **auto-refreshed** on session errors. Since the SDK has **no dedicated "invalid session" subtype** (`SdkResultMessage.subtype ∈ {success, error_max_turns, error_during_execution}` + `is_error`), the rule is simple: any error result (or thrown bridge error) whose **error text contains `session`, `message`, or `msg`** (case-insensitive) is treated as a **session error** → drop the stored session id and start a fresh session on the next `query`.

### 7.3 Per-application AgentContext (D4rt scripting, tools, guidelines)

Each Forge **application** (DocSpecs / CodeSpecs / Implementation) owns an **AgentContext = `{llm_guidelines_specification.md`, tool set, D4rt scope profile`}`**. **Selecting the application** swaps all three: which `llm_guidelines_specification.md` briefs the agent (role + scripting guide, [`llm_and_d4rt_tools.md`](llm_and_d4rt_tools.md) §11), which §8 tools are registered, and which D4rt scripting **scopes** (`spec`/`files`/`memory`) are available. The DocSpecs app enables all three scopes; the other apps define their own profiles later. The scripting **engine plane** (D4rt host + scope registry + file facade + search index + RAG memory) is detailed in the linked spec; see §21 for the placement/unblock note.

---

## 8. Navigation & Mutation Tools (requirement *c*)

Registered by `AgentToolsModule` as in-process `SdkMcpTool`s; compact JSON results.

**Layer A — Maximum structure (object model)** from `SpecModel`:
`model_list_documents()`, `model_get_section(id|class)`, `model_children(id)`, `model_search(query)` — schema only.

**Layer B — Actual instance structure** from the live document:
`doc_outline(rootId?, depth?)`, `doc_section_meta(id)` — ids/types/cardinality/counts, no body.

**Layer C — Actual content** from the live document:
`doc_get_content(id)`, `doc_get_form_field(id, field)`.

**Mutation** (agent edits freely, *Q5*): `doc_set_content(id, value)`, `doc_set_form_field(id, field, value)`, `doc_add_list_item(listId)`, `doc_remove_list_item(id)`, `doc_set_review(path, …)`.

All mutations go through the **same document controller** the UI uses, are **undoable** (§10), and emit a **change-log entry** (§9). Keys are the **globally-unique section-ID path** (D3): Layer-A by class/section-id; B/C by section-id path; list items disambiguated by **`-1`, `-2` index suffixes** on the path.

- **Diff representation (T1):** every section is text *eventually*; the change log and three-way review use the section's **YAML fragment** as the diff unit, written with **block (multi-line) scalars** so line breaks match the document exactly. This applies uniformly to `content`, `form`, `list`, and `complex` — each mutation captures the before/after YAML fragment of the affected node.
- **Granularity (T2):** undo is possible **per individual change** (one mutation tool call = one change entry = one undoable snapshot) **and per agent turn** (a turn is an undo group wrapping its changes — §10). The user can step back either way.

**Extended tool surface (D4rt scripting, search, memory, files).** [`llm_and_d4rt_tools.md`](llm_and_d4rt_tools.md) adds the in-process `tom_spec_engine` scripting plane, all routed through the **same controller** (so the change log stays the single source — §9). The surface is organised into three D4rt **scopes**, each one global under one import, selected by the active application's **AgentContext** (§7.3):

- **`spec` scope** (`package:tom_spec_engine/spec_api.dart`) — one global `spec`, an **eight-method `SpecApi`** (`content`/`setContent`/`formField`/`setFormField`/`listItems`/`addListItem`/`removeListItem`/`addChild`) bound to the live `SpecDocumentController`, so scripted edits are **identical to tool edits** (one change log, undoable). `addChild` is **meta-model-validated** and throws on an illegal child.
- **`files` scope** (`package:tom_spec_engine/spec_files.dart`) — one global `files`, the `SpecFileFacade`: read anywhere, write only under the `agent/scratchpad` whitelist (out-of-whitelist writes throw).
- **`memory` scope** (`package:tom_spec_engine/memory.dart`) — one global `memory`: `recall(query, {k})` / `recallPaths(query, {k})`, read-only RAG recall over the embedding-free structural/lexical index (tier-1) fused with `vec0` vectors as they warm (§9).

**Author-time only (MCP tools, not in-script):** grep-like **search** (`model_search` over the Layer-A object model) and **reflection** (`model_get_section` / `model_children`). The draft's in-script `doc_search`/`doc_search_iterate`/`doc_reflect`/`doc_add_node` MCP tools and `script_author`/`validate`/`run` MCP tools, the in-script `tom_som` reflection/typed-facade layer, and `mem_refresh` are **deferred** (see `llm_guidelines_specification.md` §10). A script discovers structure by attempting `spec.addChild` (validates + throws), walking `spec.listItems`, and `memory.recall`; scripts run through the editor's in-process `SpecScriptRunner` (`AgentToolsModule.scriptRunner`).

---

## 9. Agent Change Log & Three-Way Review (requirement *Q5*)

- Every mutation tool call appends a `ChangeEntry { id, sectionId, kind, beforeThisEdit, afterThisEdit, baseAtLastSave, timestamp, turnId, toolCallId }`.
- The right-panel **Change Log** lists entries (newest first), grouped by agent turn, with section id + summary.
- Opening an entry shows a **three-pane review**: **(1)** section content at **last save** (`baseAtLastSave`), **(2)** **this edit** (before→after for the specific change), **(3)** **current** content (may include later edits). This is an inspection/merge view, not a blocking gate — the agent edits land immediately.
- **Pick-a-pane resolution (M1):** the review is a **choice of one pane**, not a field-level merge — the user picks pane 1, 2, or 3 as the section's new value. Applying a pick **creates a new undo entry** (it is an ordinary edit, fully undoable).
- `baseAtLastSave` is captured at load and refreshed on every save.
- **Log lifecycle (M2, N6):** the **change log resets on save** — once the document is saved the accumulated agent changes are cleared (the saved state becomes the new base). After a save the **only** way to undo is the **editor undo queue** (the snapshot stack, §10) — which may still contain edits that *were* described by the now-cleared change log. The log therefore does **not** persist across saves and is not part of the serialized `review:` pass.

---

## 10. Undo / Redo (requirements *b*, *Q7*)

- **Model (U1, N5):** snapshot-based with **structural sharing** — each snapshot shares all **unchanged leaf objects** with its predecessor, so a snapshot is a cheap full picture that is trivial to restore. To make this clean, **`tom_specs_model` is modified** to give the editor simple **immutable / copy-on-write** handling (whatever shape is cleanest for the editor; the model project owns the change). A snapshot is taken **whenever an input field changes *and* there were actual changes** (no-op edits don't snapshot). Keep the **initial loaded** document plus snapshots, capped at **~50** (configurable); discard the oldest beyond the cap (initial load is always retained as the floor).
- **Forge wiring:** the document editor registers `undo`/`redo` handlers via `ShellEditorIntegration.registerAction(StandardEditingActions.undo/redoActionId, …)` and exposes `canUndo/canRedo/isDirty` through `ForgeTextContext`; calls `notifyTextEdit(label)` per user edit. **Agent turns** are wrapped in `beginUndoGroup/endUndoGroup` so a multi-edit turn is a single undo step (while individual changes remain inspectable via the change log — §9).
- **Agent edits & free user editing (U2):** agent changes are undoable **via the change log** (§9); ordinary user edits are undoable via the snapshot stack. The **user may edit the document in any way at any time** — including during an in-flight agent turn — accepting that concurrent human edits can confuse the LLM's view of the document.
- **Dirty:** computed as current ≠ last-saved; undoing back to the saved snapshot clears dirty.

---

## 11. Chat, Queue, Trail & Placeholders (requirements *f*, *g*, *c*)

Faithful re-implementation of the **Anthropic** panel models (§3.4), Agent-SDK transport only.

### 11.1 Chat composer (bottom)
Profile picker, placeholder-aware multiline input, "Send now"/"Add to queue", streaming output with tool-call/result blocks.

### 11.2 Prompt/todo queue (Col 2)
`QueuedPrompt`/`QueuedPrePrompt`/`QueuedFollowUpPrompt`, statuses, repeats, pre-prompts, follow-ups; YAML persistence; send-next/reorder/retry; timed/repeated prompts (`TimedRequest`+`ReminderTemplate`).

### 11.3 Prompt trail (Col 3)
Request/answer **pairs** from SDK exchanges; summary markdown + raw per-round files mirroring `_ai/trail/anthropic/{quest}/`; click → full body.

### 11.4 Profiles / templates / queue templates / chat variables
All four data models first-class (§3.4), persisted as YAML in the spec workspace. The **profile** model gains one editor-specific field beyond the VS Code set: **`interruptRetryPrefix`** (N10) — the prefix prepended to an auto-resent interrupted prompt (§6.1); seeded to a reasonable default when profiles are copied from the VS Code extension.

### 11.5 Placeholder engine (port, no JS — *c*, *Q3*)
- Reuse `tom_core_agentic`'s `PlaceholderResolver` for `${name}`, `${name?}`, `${env:NAME}` and the `{{name}}` alias. **`${{ expr }}` is disabled** — no `PlaceholderExpressions` evaluator is wired (resolver runs in sync/lenient mode); encountering `${{…}}` yields a clear "expressions unsupported" error rather than executing JS.
- **Resolution context (P1):** the **quest = workspace name**; placeholders resolve against **that workspace's `_ai/` folder** (the workspace containing the document). This covers most existing placeholders — file-injection (`${guidelines-*}`, `${role-*}`, `${quest-*}`, `${file-*}`) and `date/time/quest/role/chat/file`. SDK-owned concepts that the Agent SDK manages itself — notably **`${memory}`** — are simply **not used** here. Editor/git/vscode namespaces remain out of scope unless reachable via the bridge.
- **File-injection folder resolution** (mirrors `tom_vscode_extension`'s `variableResolver.ts` `resolveFileInjectionKey`), with the editor's `_ai/`-relative base:

  | Prefix | Resolves to | Fallback |
  | --- | --- | --- |
  | `${guidelines-<name>}` | `<workspace>/_copilot_guidelines/<name>.md` | `<workspace>/_guidelines/<name>.md` |
  | `${role-<name>}` | `<workspace>/_ai/roles/<name>.md` | `<workspace>/_ai/roles/<name>/role.md` |
  | `${quest-<type>}` | first `<workspace>/_ai/quests/<quest>/<type>.<quest>.*` | — |
  | `${file-<relpath>}` | `<relpath>` relative to the **`_ai/` folder** | — |

  `<name>` for guidelines may already carry `.md` (no double extension); `${guidelines-index}` is the folder's `index.md`. The workspace root is **derived** as `aiFolder.parent` (the load-bearing invariant is `aiFolder == <workspace>/_ai`), not a separate field. `${file-*}` deliberately keeps its `_ai/`-relative base (unlike the VS Code `${file-PATH}`, which is workspace-root-relative). The single token regex matches `(?:file|guidelines|role|quest)-`; the trailing-dashless scalars `${role}`/`${quest}` are **not** matched by it.
- **Scalar built-ins `${chat}` / `${file}` — lenient providers.** `${chat}` (current transcript) and `${file}` (active document as markdown) are bound through **optional late-bound `String Function()` providers**, read at compose time so they reflect live state, not a stale snapshot. `${chat}` renders the `PromptTrailController` pairs chronologically (`User:` / `Assistant:` blocks; a still-streaming pair contributes only its request line); `${file}` exports the active root via `SpecDocumentController.exportMarkdown`. When unbound (or before the model loads, or on the default root with no section id), both resolve to **empty** rather than failing — matching the lenient contract used for missing `${file-<relpath>}` injections.
- **Capability levels (P2):** a **single capability level** for now (no full/path/reminder tiers).

---

## 12. Custom Editors (requirements *a*, *i*, *s*)

- **Basic prefs → Forge config section** (`ForgeConfigPanel`): theme, font, default app, default profile.
- **Everything else → custom `ForgeEditor`s** opened from the compact left rail, each modelled on its VS Code counterpart (§3.5) and each with an **"Open raw file"** button that opens the backing YAML/markdown in the `RawFileModule` text editor (replicating `openPanelFile`/`showFile`):
  - **Prompt Queue editor** — list+detail; add/remove/move; raw `*.entry.queue.yaml`.
  - **Queue Templates editor** — add/copy/rename/delete/save/queue; raw `*.template.queue.yaml`.
  - **Profiles editor** — full Anthropic profile fields + the editor-specific **`interruptRetryPrefix`** (N10); default toggle.
  - **Prompt Templates editor** (user-message + reusable prompts) — live placeholder preview; raw `*.prompt.md`.
  - **Chat Variables editor** — built-ins (read-only) + custom CRUD + change log; raw `*.chatvars.yaml`.
  - **Timed Requests editor** — schedule/enabled/reminder; raw `*.timed.yaml`.
  - **Agent Settings editor** — the §7.1 `Options` surface + bridge host/port.
- Each renders help text via the markdown widget (§13) and validates on edit.
- **File location (E1):** all these backing files live under the **Forge process's workspace folder** (the folder that also holds the specification) — the spec `*.docspecs.yaml` plus the configuration / UI-state files. There is no separate app-config dir for them.
- **Raw-file scope (E2):** the **document editor itself has no raw-file view** — it edits the object model, period. Only the **configuration files** (queue, templates, profiles, variables, timed, agent settings) expose an "Open raw file" button; that button opens the backing YAML/markdown in the `RawFileModule` text editor.

---

## 13. Document Model, Rendering & Compact Tree (requirements *j*, *k*, *l*, *m*, *d*)

The document editor walks the `SpecClass` graph for the active root and renders each `SpecField` by `kind`.

- **Two access layers.** *Structure* comes from the bundled `spec_model.json` (§3.7): the renderer walks the generic `SpecClass`/`SpecField` graph so it can display every kind uniformly without compile-time knowledge of any class. *Typed programmatic access* to the live document — mutation tools (§8), the connect pass (§15.1), validation — uses the **generated `tom_som_dart_v0` facade over `tom_som_dart_runtime`** (§3.8), whose typed classes read/write through the runtime onto the same underlying tree. The two layers agree because both are generated from `tom_specs_model`; the generic graph drives rendering, the typed facade drives correctness-checked edits.
- **Generic markdown widget (j):** `SpecMarkdown` wraps `MdPreviewPanel`; used for **every** label and content preview.
- **Inline Flutter-layout fields (k):** layout-typed `content` renders live via `SourceFlutterD4rt().build<Widget>(source, context)`.
- **In-document Dart editor (l):** code-typed fields embed `SummaryBackedDartCodeEditor` with **pre-generated, embedded summaries covering `tom_d4rt_flutter`** (B1); phase-2 → `tom_flutter_ui` summaries.
- **Renderer-only md (m):** `tom_md_editor` supplies the renderer; the document is model-driven, screen scaffolding is Flutter (+ d4rt-flutter for dynamic layout).

### 13.1 Compact, variable-height tree (requirement *d*)

- **Show everything, compactly.** **Empty = "no value" (D4)** — applied per kind: `content`/`scalar` = no value set; `enum` = no value selected (a default/first enum value still counts as *empty* until the user explicitly sets it); `form` = all fields empty; `list` = zero items; `complex`/`section` = empty iff all descendants empty.
- **Empty nodes render as a chip/tag**, not a full row (variable node height). **Clicking a chip inline-expands (D2)** the node in place — the editor for that node materialises within the tree, so authoring starts on demand without a separate pane.
- **Non-empty nodes** render expanded with their content/preview.
- **All-empty subtrees** collapse to a **single chip** at the subtree root (one click to begin), rather than a chip per empty leaf.
- **Lists** always show **add/remove** buttons; populated items render in full, plus an "add item" affordance. List item identity uses **`-1`, `-2` index suffixes** on the section-ID path (D3), keeping every node path globally unique.
- **Badge & chip placement (D5):** **review-state badges sit next to the section headline**; **empty-node chips render below** the node's content — under the section content, or under the **last existing subsection** when the section already has subsections.
- Mixed sections show filled fields expanded and empty fields as inline chips (placed per D5).

---

## 14. Single Document, Multiple Roots (requirement *Q9*)

- A spec is **one document** rooted in **one new top-level class** (`DocSpecsProject`, in `tom_specs_model`) that **references all 14 document roots** (V2). This gives the editor a single object model/tree with one true root; the SolutionBlueprint instance remains the source of truth for shared content, and the other roots hang off the same tree under that single root.
- **The container is the canonical tree root, not a document node (N9):** it carries **no `@SectionId`**, is **not** rendered as an extra sibling document, and never appears in the navigator as content. It exists purely to give load/save/undo/snapshot a single object to operate on, **owns the `toYaml` global save** (SBP-only, §15.1), and runs the **connect pass** that binds projection roots to live SBP sections before any individual-root write (N11). Tooling (`ModelJsonExporter`, validator, outliner) must treat it as the canonical root, not as another document (Q-N11).
- **Root navigator** (left panel / top nav): **Solution Blueprint** first, then a **separator**, then the other roots **alphabetically**. Selecting a root re-renders the document editor as that projection over shared data.
- Editing through any projection edits the shared underlying sections; the compact tree, change log, and review state are consistent across projections (keyed by **storage path** — see the storage-path key bullet below).
- **Projection→SBP binding (N12):** a projection root locates its target through the existing **`@MapsTo` / `@DetailedIn`** annotations — these links *are* the connection; there is no separate copy. Because every projection field resolves to a SBP section on the **one shared tree**, a **null section is null in the SBP target too** — there is no divergence to reconcile, and the question only ever arises at the root level.
- **Pure-projection invariant (N12) — must be validated.** A projection root **must contain no content that is not also present in the Solution Blueprint**. This is what makes the single-tree model sound (and what guarantees the global `toYaml` emits each section exactly once, §15.1). It is added as a **`tom_specs_model_rules.md` §10.2 validator invariant**: for every Phase 3 root, every reachable content-bearing node must trace back, via `@MapsTo`/`@DetailedIn`, to a SBP section — any projection-local content with no SBP counterpart is a validation error.
- **Canonical-path identity primitive.** Because an aggregated annotated class has a **globally-unique `@SectionId`**, the same underlying section is named identically no matter which root reaches it. `SpecDocumentController.canonicalPathFor(path)` walks a structural path and anchors on the **deepest** node whose resolved class carries **both** a section id **and** a projection annotation (`@MapsTo` *or* `@DetailedIn`), rewriting the path to `<anchor-section-id>/<segments-below>`. So a section reached via a projection route and via the SBP route collapse to the same canonical path (segments below the anchor are preserved verbatim, keeping list-item/nested-field positions). `SpecDocumentController.isProjectionRoot(rootSeg)` is `false` for the SBP master and unknown roots, `true` for the thirteen projection roots (the twelve Phase-3 documents and `D13CodeSpecsProjection`). **Conflation guard:** a class with a section id but **no** projection annotation (e.g. each document's own `DocumentHeader`) is *not* a projection node — every document genuinely owns its instance — so it keeps its route-local prefix and is never merged. **The anchor scan stops at the first list item:** below an item, identity is positional (*which* item), so anchoring there would collapse every item of a list onto one name; the item's suffix is instead carried verbatim under the anchor that owns the list.
- **Storage-path key — one section, one store entry.** `canonicalPathFor` is the **identity** primitive ("are these two routes the same section?"); the **storage key** is `SpecDocumentController.storagePathFor(path)`, which resolves the *same* anchor but re-roots it on where that anchored section sits in the **Solution Blueprint master** tree. So `RSP/functionalRequirements` and `SBP/systemOverview/requirements/functionalRequirements` both store as the latter: an edit made through any projection mutates the byte-identical value, and the change log, review decisions and undo snapshots fold with it. The master-path form is what makes this safe — the store's emptiness and purge logic (`hasValuesUnder` / `removeValuesUnder`, §13.1 D4) is a **prefix scan**, so its key space must be a tree: a subtree of paths must map to a subtree of keys. Anchor-id-rooted canonical paths are not (everything above the anchor is replaced); master structural paths are the fixed point — the rewrite is the identity on the master route, every projection route folds *into* the master tree rather than out of it, and prefix scans keep working unchanged. It is also the key space the `*.docspecs.yaml` codec, the validator, the markdown codec and `SpecNodeCreator` already walk, so they see projection edits for free. The mapping is **derived, not hand-authored**: the anchor class is literally the same class object on both routes, so its globally-unique `@SectionId` is the meeting point and a walk of the SBP tree supplies the field path.
- **Where the key is applied.** `SpecDocument` takes an injectable host-supplied **path normalizer** (`installPathNormalizer`) rather than knowing about projections itself — it is a generic pure-Dart store shared by the nine generated language facades, and unset means identity. `ReviewStore` takes the same mapper via `installKeyMapper`. Both are installed by `SpecDocumentController.ensureLoaded` and both **re-key whatever they already hold** at that moment, which is simultaneously the migration for review passes recorded before the fold: the mapping is derived from the model and so cannot exist at construction, and `storagePathFor` is the identity until the model resolves. A normalizer must be idempotent and prefix-preserving; where two old keys collapse onto one, the first in sorted-key order wins (they name the same section, so the loser is a duplicate, not a decision).
- **Confirmed (V1):** the projection model — one SolutionBlueprint store, 12 read/write views — is the intended semantics for **both authoring and agent mutation**. All roots share a single object tree.
- **Single true root (V2):** rather than leaving the 14 roots as 14 disconnected entry points, `tom_specs_model` gains a **new top-level container class** whose fields are the 14 document roots. The editor loads/serializes/snapshots **that one object**, so:
  - the whole spec is genuinely one tree (no special-casing of "which root am I in" for save/undo/snapshot);
  - any **root-local** data a Phase 3 root might carry (beyond pure SBP projections) has a guaranteed home on the single tree;
  - the **root navigator** simply selects which child of the top container to render (Solution Blueprint first, then separator, then the rest alphabetically).

---

## 15. Document Format: YAML Save & Markdown I/O (requirements *n*, *o*, *Q9*, *Q10*)

### 15.1 Native `*.docspecs.yaml` (two-pass — *Q10*)
- **Two top-level entries:** `document:` (the object-model instance, serialized; sorted by full section ID for stable diffs/merges) and `review:` (review/UI state keyed by structural path). Load deserializes both passes, restoring full UI state.
- **Serialization mechanism (N9, N11) — `toYaml` on the model.** Each root class has a `toYaml` method:
  - The **global root's `toYaml` writes only the Solution Blueprint content** — that *is* the native `*.docspecs.yaml` `document:` pass. Because the 12 Phase 3 roots are **projections** of the same SBP content, this guarantees each section is emitted **exactly once** (no duplicate subtrees).
  - The **projection roots' `toYaml`** methods exist but are used **only when writing that root's own individual file** (§15.2 per-root markdown/sub-document export), never in the global save.
  - **Connect before write, not after read (N11, N12):** projection roots reference SBP sections through their **`@MapsTo` / `@DetailedIn`** links, and a referenced section may be **null** — in which case it is null in the SBP target too (one shared tree, no divergence). Rather than wiring them at load time (which would force keeping copies in sync), the global root runs a **connect pass immediately before** serializing an individual projection root — binding that root's references to **whatever SBP sections currently exist**. So an individual-root write always reflects the live SBP state, and the in-memory projections stay reference-only between writes. Because of the **pure-projection invariant (§14, N12)** — no projection-root content exists outside the SBP — this connect pass never has to invent or drop content; it only re-points references.
- Load deserializes the `document:` pass into the SBP store under the global root; projections are (re)connected lazily/at write time as above.
- **All keys use multi-line (block) YAML scalars (IO2)** — every value, including short text, is written as a block scalar so formatting/line breaks round-trip exactly and small per-key changes diff/merge cleanly. A side benefit (N4): the saved `*.docspecs.yaml` is **directly human-readable** — the whole document can be read in YAML form without the editor.
- Empty sections omitted from `document:`; populated review entries kept under `review:`.
- **Not serialized:** the **agent change log** does *not* persist — it **resets on save (M2)**, so it is not part of the `review:` pass. The SDK **session id** lives in a **sidecar** (A2), not in `document:`, keeping the document YAML diff-clean.

### 15.2 Markdown import/export dialog (*Q9*, *o*)
- A dialog offers **scope**: **single** document (one root projection), **multiple** (subset of roots), or **global** (the Solution Blueprint master). Each selected root exports a schema-conformant `*.md` with its `<!-- docspec: -->` header. Before exporting a projection root, the global root runs the **connect pass** (§15.1, N11) so the root's `toYaml`/markdown reflects the **current** SBP content.
- **Import is a full overwrite (IO1).** Parsing `*.md` via `DocSpecsFactory`→`SpecDoc` maps `SpecSection`→`SpecClass` by section id and **replaces** the covered content wholesale — the **whole document** for a global import, or exactly the **sub-document's covered part** for a single/multiple-root import. There is **no conflict resolution** in phase 1; an approve-style merge view (human sees and accepts each change) is a **possible later feature**, not now. On unclean parse, a **parse-rejection protocol** lists each rejected/unmapped block, the reason (unknown id, schema violation, type mismatch), and source location.
- **Round-trip fidelity (IO2):** maintained by the same all-block-scalar discipline — embedded d4rt-flutter and Dart field bodies survive export→import because their text is preserved verbatim.

---

## 16. DocSpecs Schema Generator (requirement *Q8*)

- New generator (in `tom_specs_clitool`, beside `ModelJsonExporter`) producing a `*.docspecs-schema.yaml` per document root from the object-model annotations: `@SectionId`/`@SectionIdPattern`→`section-types`+prefixes; cardinality (`@Min`/`@Max` on lists)→`min-count`/`max-count` on the parent's `subsection-types`; `@ContentType`→`format`; `@Form`/`Field`→`form-types`; field validators→`pattern-check`/`required-fields`/`text-required`.
- **Patterned list-element ids → `pattern-check-id`.** A `@SectionIdPattern` list-element section-type emits a **prefix-based** `pattern-check-id` — `^<escaped-prefix>-\d+$` (e.g. `^d00_itm-\d+$`), matching the slugified DocSpecs-legal id form of a numbered list item (`d00_itm-001`), **not** the raw TomSpecs pattern (`D00-ITM`). Single (non-patterned) fields carry no `pattern-check-id`. Per-`@Form` `required` fields already flow through to `required-fields` enforcement.
- **Cardinality is a per-element content constraint, not a required-section contract.** It rides on the **parent** section-type's `subsection-types` map — `min-count` from the child's `@Min`, `max-count` `1` for a singleton child and `infinite` (or the `@Max` bound) for a list element — so the bound is scoped to the parent→child linkage rather than counted across the whole document. Because projection roots are **views, not authoring contracts (N12)**, every generated document slot is `optional: true` — no document-level required-section slot is emitted; the only required cardinality that ships is the per-element `@Min`. `pattern-check-text` is deliberately never emitted: the model constrains sections structurally and *guides* prose rather than constraining it, so it carries no text-body regex annotation for the generator to map from (`tom_specs_model_rules.md` §9.4).
- Output **bundled in-app** (for import validation) and written to the **workspace schema location** (`.tom/docspecs-schema/`).
- Runs as a step in the build script (§17).
- **Schema set (S1):** **one global schema** (Solution Blueprint) **plus one per projection root** (the 12 Phase 3 documents and `D13CodeSpecsProjection`) — 14 schemas total, one per `@Document` root. `generateAll` derives the set from the model, so a new root yields a new schema with no generator change.
- **Versioning (S2):** schema version **counts up — 1, 2, …** — whenever the **object model changes**; we keep changes **backwards compatible** wherever possible. The version is tied to the model version stamp (B2): the `buildkit.yaml` versioner in the model project drives both the bundled `spec_model.json` stamp and the schema version.

---

## 17. Build & Packaging (requirement *Q6*)

The build is driven by the **`buildkit`** tool (N8), which can run **all** build steps; cross-platform (Linux/Windows/macOS). `buildkit` itself is `tom_build_base`-based, satisfying the workspace policy.

- **Model version stamp (B2, N8):** `tom_specs_model` gains a **`buildkit.yaml`** with a **`versioner:`** block, e.g.:
  ```yaml
  versioner:
    variable-prefix: tomSpecsModel   # → TomSpecsModelVersionInfo
    includeGitCommit: true
  ```
  `buildkit :versioner` generates `lib/src/version.versioner.dart` (`TomSpecsModelVersionInfo.version/buildNumber/gitCommit/buildTime`); the **build number auto-increments** (persisted in `tom_build_state.json`) and **`version`** is bumped on **official builds**. This single stamp is the source for both the bundled `spec_model.json` version and the schema version (S2).
- **Build steps (each a buildkit command / script step):**
  1. `buildkit :versioner` in `tom_specs_model` → version stamp.
  2. Generate `spec_model.json` (`tom_specs_clitool/bin/model_json.dart`), tagged with the stamp.
  3. Generate DocSpecs schemas (§16), versioned from the stamp.
  4. **Embed pre-generated** `tom_dart_editor` analyzer **summaries** covering `tom_d4rt_flutter` (+ phase-2 `tom_flutter_ui`). Per **B1** the summaries are **pre-generated and committed/embedded as assets** — the build does *not* run the analyzer per-OS, so no per-platform analyzer toolchain is required at build time.
  5. Bundle assets (model json, schemas, embedded summaries).
  6. `flutter build {linux|windows|macos}`.
- **Model-drift control (B2):** the bundled `spec_model.json` carries the version stamp, so a built app reports exactly which model version it was generated against; rebuilds after a model change bump the stamp.

---

## 18. Phasing

1. **1a — Shell skeleton:** custom module set, 3 apps, 4-region layout, structure-editor view copied & restyled (Q1).
2. **1b — Connection & agent:** port scan/identify picker, Agent-SDK send + streaming, settings surface (§7), navigation+mutation tools (§8), change log + 3-way review (§9), undo/redo (§10).
3. **1c — Chat suite:** composer, queue, trail, profiles, templates, chat variables, placeholder engine, custom editors w/ raw-file buttons (§11–12).
4. **1d — Document editor:** model-driven rendering, compact tree, md/d4rt-flutter/dart fields, two-pass YAML save, md import/export + rejection protocol, schema generator, build script (§13–17).
5. **Phase 2:** `tom_flutter_ui` components; populate CodeSpecs & Implementation apps.

---

## 19. Open Questions

**No open design questions remain** — every decision is recorded in §2 and folded into the body. The items below are **confirmed implementation tasks** (no decision pending) to carry out during build:

- **T1 — Canonical-container tree root.** Make `ModelJsonExporter`, the `tom_specs_model_rules.md` §10.2 validator, and the outliner recognise the unannotated **canonical container** as the tree root (not an extra document): exempt it from `@SectionId` coverage/uniqueness, and have the exporter follow it as root. (`tom_specs_clitool` / `tom_specs_model`.)
- **T2 — Pure-projection validator invariant.** Add a `tom_specs_model_rules.md` §10.2 invariant that every Phase 3 projection root contains **no content absent from the Solution Blueprint**: every reachable content-bearing node must trace back via `@MapsTo`/`@DetailedIn` to a SBP section. The connect pass (§15.1) relies on this, so it only re-points references — never invents or drops content. The link mechanism is the existing `@MapsTo`/`@DetailedIn` annotations; a null target section is simply null in SBP too (one shared tree). (`tom_specs_clitool` validator.)
- **T3 — Provider layer location.** The provider abstraction (`LlmProvider`, `AgentSdkLlmProvider`, `AgentSdkSessionStrategy`/`AgentSdkSessionStore`) lives in `tom_core_agentic` (published, with the `tom_vscode_scripting_api` dependency); `tom_brain_*` consumes it and re-exports for back-compat, and the HTTP/stub providers remain in `tom_brain_substrate`. No `tom_assistant` consumer pins old `tom_brain` provider classes. The editor depends on `tom_core_agentic` for this layer.

### 19.1 Reviewer vs editor — scope boundary and runtime consumption

> **Naming note.** `tom_specs_reviewer` is the **structure reviewer** over the
> exported class graph: it browses the model as a tree and records structural
> review observations, and is explicitly **not** a specification editor. The
> canonical Flutter editor this specification describes is
> **`tom_forge/tom_specs_editor`** (the live document controller +
> `AgentToolsModule` + §8 tools), and `tom_spec_engine` links into *that*
> project. The paragraph below describes the reviewer's own runtime
> consumption, not the editor's; what the two apps share, and where the
> boundary between them runs, is §4.4.

`tom_specs_reviewer` consumes the **generic** meta-model access classes
(`SpecModel` / `SpecRoot` / `SpecClass` / `SpecField` / `FormFieldSpec` /
`SpecFieldKind`) from the official `tom_som_dart_runtime` package — see
`som_multiplatform_spec_model.md` §7 *The fixed (non-generated) runtime* — rather
than an in-tree copy, plus `tom_specs_core` for the canonical `CodeSpecPart`
vocabulary it proposes mappings from. `som_multiplatform_spec_model.md` §10
*Relationship to the editor* is the authority for this arrangement.

**The generic path is the reviewer's permanent shape, not a stage on the way to
the typed one.** The typed `_v0` object model (`D00SolutionBlueprint` over a
`SpecDocument`) exists to make document *edits* correctness-checked by the
generated model, and the reviewer has no document to edit: its whole input is
the exported **class graph**, and the only thing it writes is its review file.
Adopting the typed facade there would not route existing writes through a safer
door — there are none — it would mean giving the reviewer a document plane it
deliberately does not have, which is the editor this specification describes.
So `tom_specs_reviewer` carries no `tom_som_dart_v0` dependency by design, and
the boundary in §4.4 is where document editing stops.

---

## 20. Implementation Plan

Ordered, numbered steps to build the TomSpecs Editor from scratch. The order follows the dependency graph — each step's foundations are laid by earlier steps. Steps map onto the §18 phases (noted as `[1a]…[2]`). Every step lists its **done** condition; `dart analyze` clean + `testkit :test` green is an implicit gate for every code step. Tests are written **before** the implementation they cover (red→green→refactor).

### Stage A — Shared foundations (`tom_core_agentic`, model, tooling)

1. **Provider layer in `tom_core_agentic` (T3, N7) — done.** `tom_core_agentic` (v1.8.0) owns `LlmProvider` + message/stream-event models, `AgentSdkLlmProvider`, and `AgentSdkSessionStrategy`/`AgentSdkSessionStore`, and depends on `tom_vscode_scripting_api (>=1.1.0)`. The HTTP/stub providers (`OllamaLlmProvider`, `OpenAiPassthroughProvider`, `StubLlmProvider`) stay in `tom_brain_substrate` and consume the abstraction. **Verify:** the editor build resolves the provider API from `tom_core_agentic` with no duplicate copies.
2. **Add the agent data models to `tom_core_agentic`.** Anthropic profile/options model (incl. the editor-specific `interruptRetryPrefix`, N10), prompt-queue model (`QueuedPrompt`/`QueuedPrePrompt`/`QueuedFollowUpPrompt`), chat-message/trail model, `ReminderTemplate`/`TimedRequest`, and editor-facing placeholder bindings over the existing `PlaceholderResolver` (no JS — `${{…}}` left unwired, §11.5). **Done:** models round-trip through YAML in unit tests.
3. **`tom_brain_*` consumes `tom_core_agentic` (T3) — done.** `tom_brain_substrate`/`tom_brain_run` depend on the published `tom_core_agentic` and re-export the abstraction; the moved code is deleted, and no `tom_assistant` consumer pins old provider classes. **Verify:** `tom_brain_*` builds + tests green against `tom_core_agentic`; no duplicated provider code remains.
4. **Add the canonical container root to `tom_specs_model` (V2, N9).** New top-level class referencing all 14 document roots; **no `@SectionId`**, not a document node. **Done:** class compiles; the existing model test suite still passes.
5. **Give the model immutable / copy-on-write handling for snapshotting (N5, U1).** Reshape `tom_specs_model` nodes so the editor can take cheap structurally-shared snapshots. **Done:** a snapshot/restore unit test demonstrates unchanged leaves are shared by identity.
6. **Add `toYaml` + the connect pass to the model (N11, N12).** Global root `toYaml` writes **only** Solution Blueprint content (each section once); projection roots' `toYaml` used only for their individual-file write, preceded by the connect pass that binds `@MapsTo`/`@DetailedIn` references to live SBP sections. **Done:** unit tests prove (a) global save emits no duplicate subtrees, (b) an individual projection write reflects current SBP content, (c) a null SBP section stays null in the projection.
7. **Tooling: canonical-container root + pure-projection invariant (T1, T2).** Teach `ModelJsonExporter`, the outliner, and the `tom_specs_model_rules.md` §10.2 validator to treat the container as the tree root (exempt from `@SectionId` coverage/uniqueness) and add the invariant that **no projection-root content lacks a SBP counterpart**. **Done:** validator flags a synthetic violation; `model_json.dart` emits the container as root; existing outliner/validator tests pass.

### Stage B — Editor shell skeleton `[1a]`

8. **Scaffold `tom_forge/tom_forge_agentic` (UI only, D1/N7) and `tom_forge/tom_specs_editor`.** Two new Flutter projects; `tom_specs_editor` depends on `tom_forge_agentic` + `tom_core_agentic` + the bundled model/schema assets. **Done:** both projects build empty; `tom_specs_editor` launches a blank Forge shell.
9. **Custom module set + 3 applications (§4.2, §5).** `SpecsShellModule` registering the *DocSpecs / CodeSpecs / Implementation* `ForgeApplication`s with the 4-region `ApplicationLayout`; only DocSpecs functional. **Done:** app launcher switches between the three; DocSpecs shows the 4 regions.
10. **Port the structure browser + structural review (Q1).** Fork the reviewer's `spec_tree.dart` + `ReviewStore` into `SpecStructureModule`, restyle to match. **Done:** the structure view renders the bundled `spec_model.json` and persists review state, restyled.

### Stage C — Connection & agent `[1b]`

11. **Port-scan connection & picker (§6, Q4, C1).** `AgentChatModule` scans 19900–19909, runs the workspace-identify handshake, shows the *port · workspace · status* picker; choice persists per spec. **Done:** picker lists a live server (test assumes 19900) and binds it.
12. **Agent send + streaming over the provider (§7).** Assemble `Options` from profile + global settings + MCP tools; `query` streams to a minimal output view; per-spec session id in a sidecar with the §7.2 refresh rule (error text contains `session`/`message`/`msg`). **Done:** a prompt round-trips through the bridge and streams back; a forced session error refreshes the id.
13. **Reconnect protocol (§6.1, C2, N1, N10).** Informational popup → 3 retries (10 s/30 s/60 s) → silent reconnect + auto-resend with the profile `interruptRetryPrefix`; modal/confirm paths for still-gone / different-workspace. **Done:** simulated drop re-sends the prefixed prompt on reconnect.
14. **Navigation + mutation tools (§8).** `SdkMcpTool`s for Layers A/B/C + mutations, all routed through the shared document controller. **Done:** each tool returns compact JSON; a mutation tool edits the live model.
15. **Change log + three-way review (§9) and undo/redo (§10).** `ChangeEntry` log (resets on save), three-pane pick-a-pane review, snapshot stack (~50) wired via `ShellEditorIntegration.registerAction` + `notifyTextEdit`, agent turns as `beginUndoGroup`/`endUndoGroup`. **Done:** an agent turn is one undo step; individual changes are inspectable; pick-a-pane creates a new undo entry.

### Stage D — Chat suite `[1c]`

16. **Chat composer, queue, trail (§11.1–11.3).** `tom_forge_agentic` widgets: composer (bottom), `PromptQueueView` (Col 2), `PromptTrailView` (Col 3), YAML persistence in the spec workspace. **Done:** queue send-next/reorder/retry works; trail shows request/answer pairs.
17. **Profiles / templates / queue templates / chat variables + placeholder engine (§11.4–11.5).** Wire the §11.5 placeholder resolution (quest = workspace name, `_ai/` folder; `${{…}}` disabled). **Done:** placeholders resolve in a composed prompt; `${{…}}` yields the clear unsupported-error.
18. **Custom editors with raw-file buttons (§12).** Queue, queue-templates, profiles, prompt-templates, chat-variables, timed-requests, agent-settings editors via `SpecsConfigModule` + `RawFileModule`; basic prefs as `ForgeConfigPanel`. **Done:** each editor opens, validates, and its "Open raw file" button opens the backing YAML/markdown.

### Stage E — Document editor & packaging `[1d]`

19. **Model-driven document rendering + compact tree (§13).** Walk the `SpecClass` graph per active root; render each `SpecField` by kind; `SpecMarkdown` labels; inline d4rt-flutter layout fields; embedded `SummaryBackedDartCodeEditor`; compact variable-height tree with chips and list add/remove. **Done:** the bundled model renders; empty nodes collapse to clickable chips; lists add/remove.
20. **Root navigator over the single tree (§14).** Solution Blueprint first, separator, then roots alphabetically; editing any projection edits the shared sections. **Done:** switching roots re-renders the same underlying data consistently.
21. **Two-pass `*.docspecs.yaml` save/load (§15.1).** `document:` (via the global `toYaml`) + `review:` passes; block scalars for all keys; change log not serialized; session id in sidecar. **Done:** save→load round-trips full UI state; the YAML is human-readable; no duplicate subtrees.
22. **Markdown import/export + rejection protocol (§15.2).** Single/multiple/global dialog; connect pass before per-root export; full-overwrite import via `DocSpecsFactory`→`SpecDoc`; parse-rejection report. **Done:** a round-trip export→import preserves embedded d4rt/Dart bodies; bad input is reported, not silently dropped.
23. **DocSpecs schema generator (§16, Q8, S1/S2).** Generate one `*.docspecs-schema.yaml` per `@Document` root (1 global + 13 derived) from the model annotations; bundle in-app + write to `.tom/docspecs-schema/`; version counts up from the model stamp. **Done:** generated schemas validate a known-good export.
24. **Build & packaging via buildkit (§17, N8, B1/B2).** `buildkit.yaml` versioner in `tom_specs_model`; build steps: versioner → `spec_model.json` → schemas → embed pre-generated summaries → bundle assets → `flutter build {linux|windows|macos}`. **Done:** a from-scratch build produces a runnable app on each OS, stamped with the model version.

### Stage F — Phase 2 `[2]`

25. **`tom_flutter_ui` components + CodeSpecs / Implementation apps.** Swap phase-2 summaries to `tom_flutter_ui`; populate the two currently-empty applications. **Done:** CodeSpecs and Implementation apps render real content.

---

## 21. D4rt Scripting & In-Editor Agent Tooling

Full design and settled decisions in [`llm_and_d4rt_tools.md`](llm_and_d4rt_tools.md) (§14). Summary of how it lands in this editor:

- **Scopes (§8):** the in-process `tom_spec_engine` exposes three D4rt **scopes**, each one global under one import — `spec` (eight-method `SpecApi` bound to the live controller), `files` (read-anywhere / write-`agent/scratchpad` facade), and `memory` (read-only `recall`/`recallPaths`). All mutating paths route through the **one document controller** → the single change log (§9). Author-time **search**/**reflection** stay in the `model_search`/`model_get_section`/`model_children` MCP tools; in-script `doc_search`/`doc_reflect`/`doc_add_node` and `script_*` MCP tools are deferred.
- **Scripting API:** scripts use the `spec` scope's `SpecApi`; node creation (`spec.addChild`) is **constrained by the object model** (validates + throws), so scripted edits are identical to tool/UI edits. (The fuller `tom_som` generic+reflection+typed `tom_som_dart_v0` surface is bridged in the engine plane but **not** bound into the script scope today — deferred.)
- **AgentContext (§7.3):** the `spec`/`files`/`memory` scopes coexist; the active application selects the scope profile + tool set + `llm_guidelines_specification.md`. Per-application/phase isolation rides Tom Brain's **profiles + named sessions + named memory**.
- **Memory / RAG:** the spec is indexed **per section** in two tiers — a fast structural/lexical index rebuilt **after every prompt with no LLM calls** (the always-current path) and an incremental `vec0` vector index for semantic recall. Tom Brain is now **embeddable** (bundles `vec0`), so memory runs **in-process** in the engine plane — no server-only packaging, no separate `vec0` provisioning. The editor links the engine via a **memory-free** `scripting.dart` façade today; wiring the embeddable memory into the editor is the remaining integration.
- **Agent system:** the conversational agent **stays the Agent SDK** (§7); from `tom_brain` the design adopts the D4rt **procedure-host/scope** pattern and the embeddable `tom_brain_memory` (free-time/dream procedures **off**).
- **Engine placement:** `tom_d4rt` and `tom_dart_editor` are both on `analyzer ^10`, so the pure-Dart `tom_spec_engine` links **in-process**; D4rt and the §8 tools call `SpecDocumentController` directly — no companion process, no reverse-RPC hop. That placement is also what makes live d4rt-flutter rendering (§13) possible.
