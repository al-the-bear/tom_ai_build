/// The per-application **AgentContext** — `{guidelines doc, tool set, scope
/// profile}` realised over Tom Brain profiles/sessions/memory
/// (`llm_and_d4rt_tools.md` §11).
///
/// `llm_and_d4rt_tools.md` §11 makes the *application* the unit of agent
/// configuration: each application (DocSpecs / CodeSpecs / Implementation …) is
/// a Tom Brain **profile** whose prompt is its guidelines document, whose tools
/// are its toolset, and whose enabled D4rt scripting surfaces are its scope
/// profile. A **named session** isolates one phase/task run and a **named
/// memory** isolates one document. Switching application therefore swaps, in
/// one move, the guidelines + tools + scopes + memory an agent runs under.
///
/// [AgentContext] is that datum, pure engine-plane value data:
///
///   * [application] → the Tom Brain **profile** name ([profileName]);
///   * [guidelinesName] → the profile **prompt** (the agent briefing document,
///     e.g. `llm_guidelines_specification.md`);
///   * [toolset] → the [AgentToolGroup]s the profile exposes;
///   * [scopeProfile] → the D4rt [ScopeProfile] the profile enables.
///
/// [memoryScope] layers the per-run session + per-document memory on top,
/// yielding the [MemoryScope] the mode-(b) substrate runs under;
/// [brainSubstrate] is the bridge that builds that substrate. The
/// **toolset ⊆ scopes** invariant is checked at construction so a context can
/// never expose a tool whose required scope its profile omits — the guarantee
/// that makes switching application safe.
library;

import 'agent_procedure.dart';
import 'agent_scope.dart';
import 'agent_tools_api.dart';
import 'brain_agent_substrate.dart';
import 'brain_session_envelope.dart';
import '../memory/memory_scope.dart';
import '../scope/scope_registry.dart';

/// The four agent toolset families (`llm_and_d4rt_tools.md` §8) an
/// [AgentContext] can expose.
///
/// Each group needs a specific base scope to operate; [requiredScope] names it.
/// A context's [AgentContext.toolset] must be covered by its
/// [AgentContext.scopeProfile] — the construction-time invariant that keeps a
/// tool from being exposed without its backing scope.
enum AgentToolGroup {
  /// The `doc_*` tools (search / iterate / reflect / add_node) — need `spec`.
  doc(requiredScope: 'spec'),

  /// The `mem_*` tools (recall / refresh) — need `memory`.
  memory(requiredScope: 'memory'),

  /// The `file_*` tools (read / find / write) — need `files`.
  file(requiredScope: 'files'),

  /// The `script_*` tools (author / validate / run / list / get) — author and
  /// run scripts against the live document, so they need `spec`.
  script(requiredScope: 'spec');

  const AgentToolGroup({required this.requiredScope});

  /// The base-scope name this tool family needs to operate.
  final String requiredScope;
}

/// The three canonical TomSpecs **applications** — each one Tom Brain
/// **profile** under the confirmed Q1 mapping (decision F1,
/// `llm_and_d4rt_tools.md` §11):
///
///   * **one profile per application** — these three names;
///   * **one named session per phase/task** — [MemoryScope.session];
///   * **one named memory per open document** — [MemoryScope.document].
///
/// The names are fixed here so the mapping — *which* applications exist and
/// that each addresses exactly one profile — is authoritative in code. All
/// three now have a fully-authored context ([docSpecsAgentContext],
/// [codeSpecsAgentContext], [implementationAgentContext]); register the full
/// set with [tomSpecsContextRegistry] (item 10, decision F10).
const String docSpecsApplication = 'docspecs';

/// The CodeSpecs application profile name (Q1 / F1) — context
/// [codeSpecsAgentContext].
const String codeSpecsApplication = 'codespecs';

/// The Implementation application profile name (Q1 / F1) — context
/// [implementationAgentContext].
const String implementationApplication = 'implementation';

/// The canonical application set in phase order
/// (DocSpecs → CodeSpecs → Implementation), each → one Tom Brain profile
/// (Q1 / F1).
const List<String> tomSpecsApplications = [
  docSpecsApplication,
  codeSpecsApplication,
  implementationApplication,
];

/// The DocSpecs application's guidelines document — the agent briefing prompt
/// the DocSpecs profile binds (`llm_and_d4rt_tools.md` §11).
const String docSpecsGuidelinesName = 'llm_guidelines_specification.md';

/// The CodeSpecs application's guidelines document — the agent briefing prompt
/// the CodeSpecs profile binds (`llm_and_d4rt_tools.md` §11, item 10). Like
/// [docSpecsGuidelinesName] the doc is authored downstream; the prompt registry
/// renders it lenient-empty until then.
const String codeSpecsGuidelinesName = 'guidelines_codespecs.md';

/// The Implementation application's guidelines document — the agent briefing
/// prompt the Implementation profile binds (`llm_and_d4rt_tools.md` §11, item
/// 10). Authored downstream; lenient-empty until then.
const String implementationGuidelinesName = 'guidelines_implementation.md';

/// The per-application agent context: guidelines + toolset + scope profile,
/// addressed as a Tom Brain profile (`llm_and_d4rt_tools.md` §11).
final class AgentContext {
  /// The application name — the Tom Brain **profile** ([profileName]).
  final String application;

  /// The guidelines document that is the profile's **prompt** (agent briefing).
  final String guidelinesName;

  /// The [AgentToolGroup]s this profile exposes.
  final Set<AgentToolGroup> toolset;

  /// The D4rt scope profile this application enables.
  final ScopeProfile scopeProfile;

  /// Creates a context, validating that every tool in [toolset] has its
  /// [AgentToolGroup.requiredScope] present in [scopeProfile] — a context that
  /// exposed a tool without its backing scope would be unsafe (the tool could
  /// be invoked with no capability to back it). Throws [ArgumentError]
  /// otherwise.
  AgentContext({
    required this.application,
    required this.guidelinesName,
    required Set<AgentToolGroup> toolset,
    required this.scopeProfile,
  }) : toolset = Set.unmodifiable(toolset) {
    final scopes = scopeProfile.scopeNames.toSet();
    for (final group in toolset) {
      if (!scopes.contains(group.requiredScope)) {
        throw ArgumentError(
          'tool group "${group.name}" needs scope '
          '"${group.requiredScope}", which application "$application" does not '
          'enable (${scopeProfile.scopeNames.join(', ')})',
        );
      }
    }
  }

  /// The Tom Brain profile this application binds to — the [application] itself.
  String get profileName => application;

  /// Addresses one run: the application profile + a per-run [session] (named
  /// session) + a per-document [document] (named memory).
  MemoryScope memoryScope({required String session, required String document}) =>
      MemoryScope(
        application: application,
        session: session,
        document: document,
      );

  /// Builds the [RunEnvironment] for this application's scope profile against
  /// [registry] — the union of its base scopes' libraries, globals, and grants.
  RunEnvironment buildEnvironment(ScopeRegistry registry) =>
      registry.buildProfile(scopeProfile);

  /// Builds the `llm_and_d4rt_tools.md` §10 **mode (b)**
  /// ([BrainAgentSubstrate]) for this application: the same agent procedure,
  /// wrapped in a Tom Brain session [envelope] addressed by this context's
  /// [memoryScope] for [session] + [document].
  ///
  /// [procedure] defaults to [AgentProcedure.searchRecallEditVerify];
  /// [scopeName] is the label the `agent` scope is registered under.
  BrainAgentSubstrate brainSubstrate({
    required AgentToolsApi tools,
    required BrainSessionEnvelope envelope,
    required String session,
    required String document,
    AgentProcedure? procedure,
    String scopeName = agentScopeName,
  }) =>
      BrainAgentSubstrate(
        tools: tools,
        envelope: envelope,
        scope: memoryScope(session: session, document: document),
        procedure: procedure,
        scopeName: scopeName,
      );

  @override
  String toString() =>
      'AgentContext($application: guidelines=$guidelinesName, '
      'tools=${toolset.map((g) => g.name).join('/')}, '
      'scopes=${scopeProfile.scopeNames.join(', ')})';
}

/// The DocSpecs application context (`llm_and_d4rt_tools.md` §11).
///
/// The DocSpecs profile is the reference application: it briefs the agent with
/// [docSpecsGuidelinesName], exposes **all four** tool groups, and enables the
/// **three base scopes** (`spec` / `files` / `memory`) — the full TomSpecs
/// editing surface.
AgentContext docSpecsAgentContext() => AgentContext(
      application: docSpecsApplication,
      guidelinesName: docSpecsGuidelinesName,
      toolset: {
        AgentToolGroup.doc,
        AgentToolGroup.memory,
        AgentToolGroup.file,
        AgentToolGroup.script,
      },
      scopeProfile: ScopeProfile(
        name: 'docspecs',
        scopeNames: ['spec', 'files', 'memory'],
      ),
    );

/// The CodeSpecs application context (`llm_and_d4rt_tools.md` §11, item 10;
/// decision F10).
///
/// CodeSpecs (Phase 4) reads the structured specifications (`mem_*` recall +
/// `doc_*` search), edits its own CodeSpecs document (`doc_*` + `script_*`), and
/// emits skeletal code (`file_*` writes). Those needs are the **same four** tool
/// groups and **three** base scopes as DocSpecs — so the contexts differ not by
/// capability but by their **guidelines prompt** and their isolated Tom Brain
/// **profile / memory** (the application name addresses both). Per-application
/// tool *narrowing* is deliberately not invented here (no concrete need; the
/// toolset ⊆ scopes invariant already bounds capability) — see decision F10.
AgentContext codeSpecsAgentContext() => AgentContext(
      application: codeSpecsApplication,
      guidelinesName: codeSpecsGuidelinesName,
      toolset: {
        AgentToolGroup.doc,
        AgentToolGroup.memory,
        AgentToolGroup.file,
        AgentToolGroup.script,
      },
      scopeProfile: ScopeProfile(
        name: 'codespecs',
        scopeNames: ['spec', 'files', 'memory'],
      ),
    );

/// The Implementation application context (`llm_and_d4rt_tools.md` §11, item
/// 10; decision F10).
///
/// Implementation (Phase 6) writes working code + unit tests (`file_*` writes),
/// edits its own Implementation document (`doc_*` + `script_*`), and recalls the
/// spec / CodeSpecs context (`mem_*`). Like CodeSpecs it exposes the full
/// four-group surface and three base scopes, differentiated by its own
/// guidelines prompt and isolated Tom Brain profile / memory (decision F10).
AgentContext implementationAgentContext() => AgentContext(
      application: implementationApplication,
      guidelinesName: implementationGuidelinesName,
      toolset: {
        AgentToolGroup.doc,
        AgentToolGroup.memory,
        AgentToolGroup.file,
        AgentToolGroup.script,
      },
      scopeProfile: ScopeProfile(
        name: 'implementation',
        scopeNames: ['spec', 'files', 'memory'],
      ),
    );

/// A registry holding **all three** canonical TomSpecs application contexts —
/// the full Q1 mapping authored (DocSpecs → CodeSpecs → Implementation,
/// `llm_and_d4rt_tools.md` §11, item 10). This is the registry the editor binds
/// so every canonical application resolves to its own profile (guidelines +
/// tools + scopes + isolated memory) rather than falling back to DocSpecs.
AgentContextRegistry tomSpecsContextRegistry() => AgentContextRegistry()
  ..register(docSpecsAgentContext())
  ..register(codeSpecsAgentContext())
  ..register(implementationAgentContext());

/// Holds the application [AgentContext]s and resolves the active one by name —
/// the `llm_and_d4rt_tools.md` §11 **application switch**.
///
/// Registering DocSpecs / CodeSpecs / Implementation contexts and resolving by
/// application name is how *the application selects its profile*: one
/// [context] call swaps guidelines + tools + scopes + memory together.
final class AgentContextRegistry {
  final Map<String, AgentContext> _contexts = {};

  /// Registers [context] under its [AgentContext.application] name. Throws
  /// [ArgumentError] if an application of that name is already registered.
  void register(AgentContext context) {
    if (_contexts.containsKey(context.application)) {
      throw ArgumentError.value(
        context.application,
        'application',
        'an agent context is already registered for this application',
      );
    }
    _contexts[context.application] = context;
  }

  /// Whether an application named [application] is registered.
  bool has(String application) => _contexts.containsKey(application);

  /// The context for [application]. Throws [ArgumentError] if unknown.
  AgentContext context(String application) {
    final context = _contexts[application];
    if (context == null) {
      throw ArgumentError.value(
        application,
        'application',
        'no agent context registered',
      );
    }
    return context;
  }

  /// The names of all registered applications.
  Iterable<String> get applications => _contexts.keys;
}
