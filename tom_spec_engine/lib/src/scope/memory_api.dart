/// The script-facing **read-only** `memory` recall API and its D4rt bridge
/// (§4, §9, plan step 12).
///
/// [MemoryApi] is the single object a sandboxed script reaches under the
/// `memory` scope: a thin facade over the document's fused two-tier
/// [SpecRecall] (step 11). It exposes recall and **nothing else** — there is no
/// mutation path, by design (§4: the `memory` scope's permission set is "none
/// beyond memory"). A script `await`s a recall and reads compact, JSON-friendly
/// results; it can never write a section, touch the filesystem, or reach the
/// editing API, because the `memory` scope registers only this library.
///
/// Recall is asynchronous (the vector tier is a `Future`), so the bridged
/// methods return `Future`s the script `await`s and the host auto-awaits off
/// `main()`.
library;

import 'package:tom_d4rt/tom_d4rt.dart';

import '../memory/spec_recall.dart';

/// The library URI a script imports to bring the injected `memory` global (and
/// the `MemoryApi` type) into scope.
const String memoryApiLibrary = 'package:tom_spec_engine/memory.dart';

/// The name of the injected recall global (`memory`).
const String memoryApiGlobalName = 'memory';

/// The de-duplication name of the `memory_api` bridged-library building block.
const String memoryApiLibraryName = 'memory_api';

/// The script-facing recall facade: every call delegates to the bound
/// [SpecRecall]. Read-only — there is no mutation surface here.
final class MemoryApi {
  /// The fused two-tier recall every query routes through.
  final SpecRecall recall;

  /// Binds the facade to [recall].
  const MemoryApi(this.recall);

  /// Recalls up to [k] sections relevant to [query], as compact JSON-friendly
  /// hit maps (`path`, `score`, `modes`, `kind`, `headline`).
  Future<List<Map<String, Object?>>> recallHits(String query,
      {int k = 10}) async {
    final result = await recall.recall(SpecRecallQuery(text: query, k: k));
    return [for (final hit in result.hits) _hitMap(hit)];
  }

  /// Recalls up to [k] sections relevant to [query], returning just their
  /// section-id paths (best first).
  Future<List<String>> recallPaths(String query, {int k = 10}) async {
    final result = await recall.recall(SpecRecallQuery(text: query, k: k));
    return [for (final hit in result.hits) hit.path];
  }

  /// Renders one recall hit as a JSON-friendly map.
  static Map<String, Object?> _hitMap(SpecRecallHit hit) => <String, Object?>{
        'path': hit.path,
        'score': hit.score,
        'modes': [for (final m in hit.modes) m.name],
        'kind': hit.kind?.name,
        'headline': hit.headline,
      };
}

/// The [BridgedClass] that exposes [MemoryApi]'s read-only methods to a D4rt
/// script.
///
/// `MemoryApi` is never constructed from a script — the `memory` scope injects
/// a single recall-bound instance as the `memory` global — so the bridge
/// declares no constructors, only the recall methods. The script-facing method
/// names (`recall`, `recallPaths`) are intentionally minimal; no setter or
/// mutating method is exposed.
BridgedClass memoryApiBridgedClass() => BridgedClass(
      nativeType: MemoryApi,
      name: 'MemoryApi',
      isAssignable: (v) => v is MemoryApi,
      methods: {
        'recall': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as MemoryApi).recallHits(positionalArgs[0] as String,
                k: (namedArgs['k'] as int?) ?? 10),
        'recallPaths': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as MemoryApi).recallPaths(positionalArgs[0] as String,
                k: (namedArgs['k'] as int?) ?? 10),
      },
    );
