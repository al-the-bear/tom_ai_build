/// The script-facing **read-only** `memory` recall API and its D4rt bridge
/// (§4, §9).
///
/// [MemoryApi] is the single object a sandboxed script reaches under the
/// `memory` scope: a thin facade over the document's fused two-tier
/// [SpecRecall] (§9.2). It exposes recall and **nothing else** — there is no
/// mutation path, by design (§4: the `memory` scope's permission set is "none
/// beyond memory"). A script `await`s a recall and reads compact, JSON-friendly
/// results; it can never write a section, touch the filesystem, or reach the
/// editing API, because the `memory` scope registers only this library.
///
/// Recall is asynchronous (the vector tier is a `Future`), so the bridged
/// methods return `Future`s the script `await`s and the host auto-awaits off
/// `main()`.
///
/// Beyond the query text and the result cap [k], a script may pass an
/// **`options`** map to tune the fused recall — the fuller [SpecRecallQuery]
/// surface (RRF / MMR weights, facet filters, tier / GraphWalk selection) the
/// recall supports beyond the scope defaults.
/// [specRecallQueryFromArgs] is the single builder behind
/// the map, so the recognised knobs and their coercion live in one place.
library;

import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart' show SpecNodeKind;

import '../index/structural_lexical_index.dart'
    show IndexQuery, IndexStateFilter;
import '../memory/spec_recall.dart';

/// The library URI a script imports to bring the injected `memory` global (and
/// the `MemoryApi` type) into scope.
const String memoryApiLibrary = 'package:tom_spec_engine/memory.dart';

/// The name of the injected recall global (`memory`).
const String memoryApiGlobalName = 'memory';

/// The de-duplication name of the `memory_api` bridged-library building block.
const String memoryApiLibraryName = 'memory_api';

/// Builds a fused-recall [SpecRecallQuery] from the query [text], a result cap
/// [k], and an optional string-keyed [options] map — the single tuning-knob
/// builder behind the in-script `memory.recall` / `memory.recallPaths` facade.
/// Every recognised knob the recall supports is surfaced here, so a script can
/// override the scope defaults.
///
/// Recognised `options` keys (each falls back to the [SpecRecallQuery] default
/// when absent):
///
///   * **result shape** — `k` (post-fusion cap; overrides the [k] argument when
///     present), `perModeK` (per-mode candidate cap before fusion);
///   * **RRF** — `rrfK` (smoothing constant), `weights` (a `{modeName: weight}`
///     map; modes `lexical` / `vector` / `symbolic` / `graphWalk`);
///   * **MMR** — `diversify` (apply the diversity pass; default `true`),
///     `mmrLambda` (1.0 = pure relevance, 0.0 = pure diversity);
///   * **GraphWalk tier** — `graphWalk` (run the section-graph walk),
///     `graphWalkDepth` (max hops);
///   * **facet filters** (the symbolic tier) — `kinds` (a list, or
///     comma-separated string, of [SpecNodeKind] names), `className`,
///     `sectionIdExact`, `sectionIdPrefix`, `mapsTo`, `detailedIn`, and `state`
///     (an [IndexStateFilter] name).
///
/// Throws [ArgumentError] for an unrecognised mode name in `weights`, an
/// unrecognised `kinds` entry, or an unrecognised `state` — so a script error
/// names the bad input rather than silently dropping a knob.
SpecRecallQuery specRecallQueryFromArgs(
  String text,
  Map<Object?, Object?>? options, {
  int k = 10,
}) {
  final o = options ?? const <Object?, Object?>{};
  return SpecRecallQuery(
    text: text,
    facets: _facets(o),
    k: _int(o['k']) ?? k,
    perModeK: _int(o['perModeK']) ?? 64,
    rrfK: _int(o['rrfK']) ?? 60,
    weights: _weights(o['weights']),
    graphWalk: _bool(o['graphWalk']),
    graphWalkDepth: _int(o['graphWalkDepth']) ?? 1,
    diversify: o.containsKey('diversify') ? _bool(o['diversify']) : true,
    mmrLambda: _double(o['mmrLambda']) ?? 0.7,
  );
}

IndexQuery _facets(Map<Object?, Object?> o) {
  Set<SpecNodeKind>? kinds;
  final kindNames = _stringList(o['kinds']);
  if (kindNames != null) {
    final parsed = <SpecNodeKind>{};
    for (final name in kindNames) {
      final kind = _enumByName(SpecNodeKind.values, name);
      if (kind == null) throw ArgumentError('Unknown node kind "$name".');
      parsed.add(kind);
    }
    kinds = parsed;
  }

  IndexStateFilter? state;
  final stateName = _string(o['state']);
  if (stateName != null) {
    state = _enumByName(IndexStateFilter.values, stateName);
    if (state == null) throw ArgumentError('Unknown state "$stateName".');
  }

  return IndexQuery(
    kinds: kinds,
    className: _string(o['className']),
    sectionIdExact: _string(o['sectionIdExact']),
    sectionIdPrefix: _string(o['sectionIdPrefix']),
    mapsTo: _string(o['mapsTo']),
    detailedIn: _string(o['detailedIn']),
    state: state,
  );
}

Map<SpecRecallMode, double> _weights(Object? value) {
  if (value is! Map) return const <SpecRecallMode, double>{};
  final parsed = <SpecRecallMode, double>{};
  value.forEach((key, raw) {
    final name = key?.toString();
    if (name == null) return;
    final mode = _enumByName(SpecRecallMode.values, name);
    if (mode == null) throw ArgumentError('Unknown recall mode "$name".');
    final weight = _double(raw);
    if (weight != null) parsed[mode] = weight;
  });
  return parsed;
}

String? _string(Object? value) => value?.toString();

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return false;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String>? _stringList(Object? value) {
  if (value is List) return [for (final e in value) e.toString()];
  if (value is String && value.isNotEmpty) {
    return [for (final e in value.split(',')) e.trim()];
  }
  return null;
}

T? _enumByName<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

/// The script-facing recall facade: every call delegates to the bound
/// [SpecRecall]. Read-only — there is no mutation surface here.
final class MemoryApi {
  /// The fused two-tier recall every query routes through.
  final SpecRecall recall;

  /// Binds the facade to [recall].
  const MemoryApi(this.recall);

  /// Recalls up to [k] sections relevant to [query], as compact JSON-friendly
  /// hit maps (`path`, `score`, `modes`, `kind`, `headline`). Pass [options] to
  /// tune the fused recall (see [specRecallQueryFromArgs]); an explicit
  /// `options['k']` overrides [k].
  Future<List<Map<String, Object?>>> recallHits(
    String query, {
    int k = 10,
    Map<Object?, Object?>? options,
  }) async {
    final result =
        await recall.recall(specRecallQueryFromArgs(query, options, k: k));
    return [for (final hit in result.hits) _hitMap(hit)];
  }

  /// Recalls up to [k] sections relevant to [query], returning just their
  /// section-id paths (best first). Pass [options] to tune the fused recall
  /// (see [specRecallQueryFromArgs]); an explicit `options['k']` overrides [k].
  Future<List<String>> recallPaths(
    String query, {
    int k = 10,
    Map<Object?, Object?>? options,
  }) async {
    final result =
        await recall.recall(specRecallQueryFromArgs(query, options, k: k));
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
/// mutating method is exposed. Both accept an optional `options` map carrying
/// the fuller [SpecRecallQuery] tuning surface.
BridgedClass memoryApiBridgedClass() => BridgedClass(
      nativeType: MemoryApi,
      name: 'MemoryApi',
      isAssignable: (v) => v is MemoryApi,
      methods: {
        'recall': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as MemoryApi).recallHits(
              positionalArgs[0] as String,
              k: (namedArgs['k'] as int?) ?? 10,
              options: namedArgs['options'] as Map<Object?, Object?>?,
            ),
        'recallPaths': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as MemoryApi).recallPaths(
              positionalArgs[0] as String,
              k: (namedArgs['k'] as int?) ?? 10,
              options: namedArgs['options'] as Map<Object?, Object?>?,
            ),
      },
    );
