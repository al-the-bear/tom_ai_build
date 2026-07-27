/// The script-facing **read-only** `search` grep facility and its D4rt bridge
/// (§6).
///
/// Where the `spec` global ([SpecApi]) is the controller-mediated *editing*
/// surface and the `model` global ([SpecModelApi]) is the *reflection* surface,
/// [SpecSearchApi] is the third companion the `spec` scope injects: the **§6
/// grep / query** facility a script runs over the *live* document. It opens a
/// [SpecQueryCursor] from a query and hands the script a paging [SpecSearchCursor]
/// — the same lexical/structural, embedding-free search the `doc_search` MCP tool
/// exposes, so a script's results and a tool's results agree by construction
/// (both project each match through [DocSearchMatch.from]).
///
/// It carries **no mutation path** by construction (§6 is read-only): it holds a
/// [SpecQueryEngine] and exposes only query/grep + cursor stepping, never the
/// engine, the document, or any setter. The cursor is edit-stable — it
/// re-validates each path on every step (§6) — so a script may interleave search
/// and `spec`-mediated edits without surfacing stale hits.
///
/// `SpecSearchApi` is never constructed from a script — the `spec` scope injects
/// a single engine-bound instance as the `search` global — so the bridge declares
/// no constructors, only the query accessors. Every result a script touches is a
/// compact, JSON-friendly value (`Map` / `List` / `int`).
library;

import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show
        SpecNodeKind,
        SpecQuery,
        SpecQueryCursor,
        SpecQueryEngine,
        SpecStateFilter;

import '../tools/doc_tools.dart' show DocSearchMatch;

/// The library URI a script imports to bring the injected `search` global (and
/// the `SpecSearchApi` / `SpecSearchCursor` types) into scope.
const String specSearchApiLibrary =
    'package:tom_spec_engine/spec_search_api.dart';

/// The name of the injected grep global (`search`).
const String specSearchApiGlobalName = 'search';

/// The de-duplication name of the `spec_search_api` bridged-library block.
const String specSearchApiLibraryName = 'spec_search_api';

/// Builds a §6 [SpecQuery] from a string-keyed argument map — the single shared
/// query builder behind both the `doc_search` MCP tool and the in-script
/// `search` facade, so the two surfaces accept the **same** dimensions and
/// coerce them identically.
///
/// Recognised keys (every supplied one is AND-combined): `text`, `regex`,
/// `caseInsensitive`, `kinds` (a list, or a comma-separated string, of
/// [SpecNodeKind] names), `className`, `sectionIdExact`, `sectionIdPrefix`,
/// `pathGlob`, `mapsTo`, `detailedIn`, and `state` (an [SpecStateFilter] name).
/// An all-empty map yields a query that matches every node.
///
/// Throws [ArgumentError] for an unrecognised `kinds` entry or `state` value, so
/// a script error (or a tool's coded failure) names the bad input.
SpecQuery specQueryFromArgs(Map<Object?, Object?> args) {
  Set<SpecNodeKind>? kinds;
  final kindNames = _stringList(args['kinds']);
  if (kindNames != null) {
    final parsed = <SpecNodeKind>{};
    for (final name in kindNames) {
      final kind = _enumByName(SpecNodeKind.values, name);
      if (kind == null) throw ArgumentError('Unknown node kind "$name".');
      parsed.add(kind);
    }
    kinds = parsed;
  }

  SpecStateFilter? state;
  final stateName = _string(args['state']);
  if (stateName != null) {
    state = _enumByName(SpecStateFilter.values, stateName);
    if (state == null) throw ArgumentError('Unknown state "$stateName".');
  }

  return SpecQuery(
    text: _string(args['text']),
    regex: _bool(args['regex']),
    caseInsensitive: _bool(args['caseInsensitive']),
    kinds: kinds,
    className: _string(args['className']),
    sectionIdExact: _string(args['sectionIdExact']),
    sectionIdPrefix: _string(args['sectionIdPrefix']),
    pathGlob: _string(args['pathGlob']),
    mapsTo: _string(args['mapsTo']),
    detailedIn: _string(args['detailedIn']),
    state: state,
  );
}

String? _string(Object? value) => value?.toString();

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return false;
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

/// The script-facing §6 grep facility over a live [SpecQueryEngine]: open a
/// cursor with [query] (full dimensions) or [grep] (text shorthand), then page
/// it through the returned [SpecSearchCursor]. Read-only — no mutation surface.
final class SpecSearchApi {
  /// The §6 query facility over the live (model, document) pair.
  final SpecQueryEngine engine;

  /// Binds the facade to [engine].
  const SpecSearchApi(this.engine);

  /// Opens a cursor over the nodes matching the §6 query described by [args]
  /// (see [specQueryFromArgs] for the recognised dimensions).
  SpecSearchCursor query(Map<Object?, Object?> args) =>
      SpecSearchCursor(engine.query(specQueryFromArgs(args)));

  /// Opens a cursor over the nodes whose content/headline matches [pattern] —
  /// the text-search shorthand for `query({'text': pattern, …})`. Pass
  /// [regex] to treat [pattern] as a regular expression and [caseInsensitive]
  /// to fold case.
  SpecSearchCursor grep(
    String pattern, {
    bool regex = false,
    bool caseInsensitive = false,
  }) =>
      SpecSearchCursor(engine.query(SpecQuery(
        text: pattern,
        regex: regex,
        caseInsensitive: caseInsensitive,
      )));
}

/// A script-facing paging view over a §6 [SpecQueryCursor]: each match is
/// projected to the same compact JSON map the `doc_search` MCP tool returns
/// (`path`, `kind`, `classId`, `headline`, `snippet`, `spans`). Forward-only and
/// edit-stable — the underlying cursor re-validates every path as it steps.
final class SpecSearchCursor {
  /// The underlying edit-stable §6 cursor.
  final SpecQueryCursor cursor;

  /// Wraps [cursor] for script consumption.
  const SpecSearchCursor(this.cursor);

  /// The next matching node as a JSON map, or `null` when exhausted.
  Map<String, Object?>? next() {
    final match = cursor.next();
    return match == null ? null : DocSearchMatch.from(match).toJson();
  }

  /// Up to [n] further matches (fewer when the cursor exhausts first).
  List<Map<String, Object?>> take(int n) =>
      [for (final m in cursor.take(n)) DocSearchMatch.from(m).toJson()];

  /// Every remaining match, draining the cursor.
  List<Map<String, Object?>> toList() =>
      [for (final m in cursor.toList()) DocSearchMatch.from(m).toJson()];

  /// How many matches remain from the current position, re-validated against the
  /// live document, without consuming any.
  int count() => cursor.count;
}

/// The [BridgedClass] that exposes [SpecSearchApi]'s query methods to a D4rt
/// script.
///
/// `SpecSearchApi` is injected as the `search` global by the `spec` scope, so the
/// bridge declares no constructors — only the read accessors. Each returns a
/// [SpecSearchCursor] the script pages; no setter or mutating method is exposed.
BridgedClass specSearchApiBridgedClass() => BridgedClass(
      nativeType: SpecSearchApi,
      name: 'SpecSearchApi',
      isAssignable: (v) => v is SpecSearchApi,
      methods: {
        'query': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecSearchApi)
                .query(positionalArgs[0] as Map<Object?, Object?>),
        'grep': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecSearchApi).grep(
              positionalArgs[0] as String,
              regex: (namedArgs['regex'] as bool?) ?? false,
              caseInsensitive: (namedArgs['caseInsensitive'] as bool?) ?? false,
            ),
      },
    );

/// The [BridgedClass] that exposes [SpecSearchCursor]'s paging methods to a D4rt
/// script. The cursor is returned by [SpecSearchApi.query] / [SpecSearchApi.grep]
/// — never constructed from a script — so the bridge declares no constructors.
BridgedClass specSearchCursorBridgedClass() => BridgedClass(
      nativeType: SpecSearchCursor,
      name: 'SpecSearchCursor',
      isAssignable: (v) => v is SpecSearchCursor,
      methods: {
        'next': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecSearchCursor).next(),
        'take': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecSearchCursor).take(positionalArgs[0] as int),
        'toList': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecSearchCursor).toList(),
        'count': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecSearchCursor).count(),
      },
    );
