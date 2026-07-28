/// The script-facing **agent tool surface** and its D4rt bridge
/// (`llm_and_d4rt_tools.md` §8, §10).
///
/// [AgentToolsApi] is the single object the complex agent procedure (mode a)
/// reaches under the `agent` scope: a thin facade that unifies the three
/// `llm_and_d4rt_tools.md` §8.2 in-memory toolsets — [DocTools] (search /
/// reflect / add-node), [MemoryTools] (recall / refresh), and optionally
/// [FileTools] (read / find / write) — behind one bridged surface. Every method
/// returns a **JSON-able `Map`** (the tool result's own `toJson()`), so a D4rt
/// procedure works purely with maps / lists / strings and never needs a bridge
/// for each rich result type.
///
/// Because the document mutations (`addNode`) delegate to [DocTools], they
/// route through the same [SpecController] every other tool/script edit does —
/// so a procedure edit lands in the **one change log** identically
/// (`llm_and_d4rt_tools.md` §5, req c).
///
/// `recall` / `refresh` are asynchronous (the vector tier is a `Future`), so
/// those bridged methods return `Future`s the procedure `await`s and the host
/// auto-awaits off `main()`.
library;

import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart' show SpecQuery;

import '../tools/doc_tools.dart';
import '../tools/file_tools.dart';
import '../tools/memory_tools.dart';

/// The library URI a procedure imports to bring the injected `agent` global (and
/// the `AgentToolsApi` type) into scope.
const String agentToolsApiLibrary = 'package:tom_spec_engine/agent.dart';

/// The name of the injected agent-tools global (`agent`).
const String agentToolsApiGlobalName = 'agent';

/// The de-duplication name of the `agent_api` bridged-library building block.
const String agentToolsApiLibraryName = 'agent_api';

/// Raised when a `file_*` method is reached but no [FileTools] was bound to the
/// [AgentToolsApi] (the `files` surface is optional in mode a).
final class AgentFilesUnavailable implements Exception {
  /// The offending operation.
  final String operation;

  /// Creates the error for [operation].
  const AgentFilesUnavailable(this.operation);

  @override
  String toString() =>
      'AgentFilesUnavailable: no file tools bound for "$operation" '
      '(bind FileTools to enable the file_* surface)';
}

/// The unified, JSON-returning agent tool facade over the
/// `llm_and_d4rt_tools.md` §8.2 toolsets.
final class AgentToolsApi {
  /// The document tools (`doc_search` / `doc_search_iterate` / `doc_reflect` /
  /// `doc_add_node`).
  final DocTools doc;

  /// The memory tools (`mem_recall` / `mem_refresh`).
  final MemoryTools memory;

  /// The file tools (`file_read` / `file_find` / `file_write`), or `null` when
  /// the file surface is not granted in this profile.
  final FileTools? files;

  /// Binds the facade to the [doc] / [memory] toolsets and an optional [files].
  const AgentToolsApi({required this.doc, required this.memory, this.files});

  /// `doc_search` — opens a cursor for the text [query] and returns the first
  /// page as JSON (`cursorId`, `matches`, `done`, `remaining`).
  Map<String, Object?> search(String query, {int? pageSize}) =>
      doc.search(SpecQuery(text: query), pageSize: pageSize).toJson();

  /// `doc_search_iterate` — advances the cursor named [cursorId] by one page.
  Map<String, Object?> searchNext(String cursorId, {int? pageSize}) =>
      doc.iterate(cursorId, pageSize: pageSize).toJson();

  /// `doc_reflect` — the meta-model facts (kind / class / allowed children) the
  /// node at [path] addresses, as JSON.
  Map<String, Object?> reflect(String path) => doc.reflect(path).toJson();

  /// `doc_add_node` — the `llm_and_d4rt_tools.md` §5 meta-model-validated
  /// creation of child [childSegment] under [parentPath]; a rejected add is a
  /// coded `{ok:false, code, error}` map, never a throw.
  Map<String, Object?> addNode(String parentPath, String childSegment,
          {String? itemId}) =>
      doc.addNode(parentPath, childSegment, itemId: itemId).toJson();

  /// `mem_recall` — the fused two-tier recall for [query], as JSON
  /// (`hits`, `degraded`).
  Future<Map<String, Object?>> recall(String query, {int k = 10}) async =>
      (await memory.recallQuery(query, k: k)).toJson();

  /// `mem_refresh` — runs the bound re-index callback, as JSON.
  Future<Map<String, Object?>> refresh() async =>
      (await memory.refresh()).toJson();

  /// `file_read` — the file at [path] as JSON (`exists`, `content`).
  Map<String, Object?> fileRead(String path) {
    final f = files;
    if (f == null) throw const AgentFilesUnavailable('file_read');
    return f.read(path).toJson();
  }

  /// `file_find` — basename-glob matches under [dir] as JSON.
  Map<String, Object?> fileFind(String glob, {String dir = '.'}) {
    final f = files;
    if (f == null) throw const AgentFilesUnavailable('file_find');
    return f.find(glob, dir: dir).toJson();
  }

  /// `file_write` — writes [content] to [path] (whitelist-checked) as JSON; a
  /// rejected write is `{ok:false, error}`, never a throw.
  Map<String, Object?> fileWrite(String path, String content) {
    final f = files;
    if (f == null) throw const AgentFilesUnavailable('file_write');
    return f.write(path, content).toJson();
  }
}

/// The [BridgedClass] that exposes [AgentToolsApi]'s methods to a D4rt
/// procedure.
///
/// `AgentToolsApi` is never constructed from a procedure — the `agent` scope
/// injects a single bound instance as the `agent` global — so the bridge
/// declares no constructors, only the instance methods. Each returns a JSON-able
/// `Map` (or a `Future` of one), so the procedure never touches a rich Dart
/// result type.
BridgedClass agentToolsApiBridgedClass() => BridgedClass(
      nativeType: AgentToolsApi,
      name: 'AgentToolsApi',
      isAssignable: (v) => v is AgentToolsApi,
      methods: {
        'search': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).search(positionalArgs[0] as String,
                pageSize: namedArgs['pageSize'] as int?),
        'searchNext': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).searchNext(positionalArgs[0] as String,
                pageSize: namedArgs['pageSize'] as int?),
        'reflect': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).reflect(positionalArgs[0] as String),
        'addNode': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).addNode(
                positionalArgs[0] as String, positionalArgs[1] as String,
                itemId: namedArgs['itemId'] as String?),
        'recall': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).recall(positionalArgs[0] as String,
                k: (namedArgs['k'] as int?) ?? 10),
        'refresh': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).refresh(),
        'fileRead': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).fileRead(positionalArgs[0] as String),
        'fileFind': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).fileFind(positionalArgs[0] as String,
                dir: (namedArgs['dir'] as String?) ?? '.'),
        'fileWrite': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as AgentToolsApi).fileWrite(
                positionalArgs[0] as String, positionalArgs[1] as String),
      },
    );
