/// The **script tools** — the engine-side logic behind the `script_*` MCP tools
/// (`llm_and_d4rt_tools.md` §8.1).
///
/// [ScriptTools] is the in-process surface the editor's `AgentToolsModule`
/// wraps as `script_author` / `script_validate` / `script_run` / `script_list`
/// / `script_get`. It binds three things the previous steps built — a
/// [ScopeRegistry] (the named scope presets, `llm_and_d4rt_tools.md` §4), a
/// [ScriptStore] (the `agent/scripts/` persistence, this step), and the
/// `tom_d4rt` interpreter — so an agent can:
///
///   * **author** a named `*.d4rt.dart` script, recording the scopes it targets;
///   * **validate** it (parse / declaration-resolve against the granted scope's
///     bridged surface) *without* running it, getting diagnostics back;
///   * **run** it under the named scopes, capturing **all three output
///     channels** — stdout, the auto-awaited `main()` return value, and any
///     error + stack.
///
/// A run mutation routes through the same [SpecController] a tool mutation does
/// (the `spec` scope binding), so it lands in the one change log identically
/// (`llm_and_d4rt_tools.md` §5, req c). Scripting is strictly more expressive
/// than the single-shot MCP tools, never a second source of truth
/// (`llm_and_d4rt_tools.md` §8.3).
/// @docImport '../scope/spec_controller.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:tom_d4rt/tom_d4rt.dart';

import '../scope/scope_registry.dart';
import 'script_store.dart';

/// The header marker line naming a stored script.
const String _nameHeader = '// tomspecs-script:';

/// The header marker line recording a stored script's target scopes.
const String _scopesHeader = '// tomspecs-scopes:';

/// A name is one safe path segment: letters, digits, `_`, `-` (no separators,
/// no leading dot), so it maps cleanly to an `agent/scripts/<name>.d4rt.dart`
/// file with no traversal risk.
final RegExp _validName = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_-]*$');

/// The result of `script_author`: the stored script's identity and location.
final class AuthoredScript {
  /// The script name.
  final String name;

  /// The stored file path.
  final String path;

  /// The scopes the script targets (recorded in its header).
  final List<String> scopes;

  /// Records a stored script's identity.
  ///
  /// [scopes] is echoed back from the header the store actually wrote, not from
  /// what the author call requested, so an agent can confirm which
  /// `llm_and_d4rt_tools.md` §4 scopes the script will really be granted at
  /// `script_run` — a scope named at authoring time but not registered would
  /// otherwise only surface as a resolution failure much later.
  const AuthoredScript({
    required this.name,
    required this.path,
    required this.scopes,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() =>
      {'name': name, 'path': path, 'scopes': scopes};
}

/// A stored script as returned by `script_get` / `script_list`.
final class StoredScript {
  /// The script name.
  final String name;

  /// The stored file path.
  final String path;

  /// The full stored contents (header + source).
  final String source;

  /// The scopes recorded in the header.
  final List<String> scopes;

  /// Records a stored script with its contents.
  ///
  /// [source] is the **full stored file** — the `// tomspecs-scopes:` header plus
  /// the script body — not the body alone, so a `script_get` followed by a
  /// `script_author` round-trips without losing the scope declaration. [scopes] is
  /// that header already parsed, so a caller never has to re-parse it.
  const StoredScript({
    required this.name,
    required this.path,
    required this.source,
    required this.scopes,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() =>
      {'name': name, 'path': path, 'scopes': scopes, 'source': source};
}

/// The declared `main()` entrypoint contract a [ScriptValidation] surfaces.
///
/// This is the **richer argument contract**: rather than only
/// reporting parse errors, validation introspects the script's entrypoint so
/// the agent knows *how* the script must be called — how many positional
/// arguments `main()` requires/accepts, its named parameters, and whether it is
/// async. The same contract is what `script_run` enforces fail-fast when an
/// `args` list is supplied.
final class ScriptEntrypoint {
  /// Whether a top-level `main` function is declared.
  final bool exists;

  /// Whether `main()` is declared `async` (the run auto-awaits either way).
  final bool isAsync;

  /// The number of **required** positional parameters `main()` declares.
  final int requiredPositional;

  /// The number of **total** positional parameters (required + optional).
  final int maxPositional;

  /// The names of `main()`'s named parameters, in declaration order.
  final List<String> namedParameters;

  /// Records an introspected `main()` contract.
  ///
  /// Not `const`: [namedParameters] is defensively copied into an unmodifiable
  /// list, so the contract cannot be mutated after validation reported it. Use
  /// [ScriptEntrypoint.absent] for a script with no `main()` rather than passing
  /// `exists: false` with zeroed counts.
  ///
  /// [requiredPositional] and [maxPositional] are a range, not one arity —
  /// `script_run` fail-fast-rejects an `args` list shorter than the first or
  /// longer than the second, which is how a mis-called script fails before it runs
  /// instead of throwing inside the interpreter (`llm_and_d4rt_tools.md` §8.1).
  ScriptEntrypoint({
    required this.exists,
    required this.isAsync,
    required this.requiredPositional,
    required this.maxPositional,
    required List<String> namedParameters,
  }) : namedParameters = List.unmodifiable(namedParameters);

  /// The entrypoint contract when no `main()` is declared.
  const ScriptEntrypoint.absent()
      : exists = false,
        isAsync = false,
        requiredPositional = 0,
        maxPositional = 0,
        namedParameters = const [];

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'exists': exists,
        if (exists) ...{
          'isAsync': isAsync,
          'requiredPositional': requiredPositional,
          'maxPositional': maxPositional,
          'namedParameters': namedParameters,
        },
      };
}

/// The result of `script_validate`: whether the script is acceptable, the
/// diagnostics the agent can iterate on, and the introspected entrypoint
/// contract (when analysis got far enough to read it).
final class ScriptValidation {
  /// Whether the script parsed, resolved against the granted scope, declared a
  /// `main()` entrypoint, and (when `args` were supplied) satisfied its
  /// argument contract.
  final bool ok;

  /// Human-readable diagnostics (empty when [ok]).
  final List<String> diagnostics;

  /// The declared `main()` contract, or `null` when the source failed to parse
  /// / resolve before it could be introspected.
  final ScriptEntrypoint? entrypoint;

  /// Records a validation outcome.
  ///
  /// [entrypoint] is `null` only when the source failed to parse or resolve before
  /// introspection could run, so a `null` entrypoint on an otherwise-`ok` result
  /// is a contradiction that should not occur. [diagnostics] is the agent's
  /// iteration surface: validation deliberately returns them instead of throwing,
  /// so a failed validate is a message to fix rather than an aborted tool call
  /// (`llm_and_d4rt_tools.md` §8.1).
  const ScriptValidation({
    required this.ok,
    required this.diagnostics,
    this.entrypoint,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'ok': ok,
        'diagnostics': diagnostics,
        if (entrypoint != null) 'entrypoint': entrypoint!.toJson(),
      };
}

/// The result of `script_run`: the three captured output channels.
final class ScriptRunResult {
  /// Everything the script `print`ed, in order (newline-separated).
  final String stdout;

  /// The auto-awaited `main()` return value, or `null` on error / void.
  final Object? result;

  /// The error message when the run threw, else `null`.
  final String? error;

  /// The stack trace when the run threw, else `null`.
  final String? stack;

  /// Records a run's three captured channels.
  ///
  /// All four fields are `required`, including the nullable ones, so no channel
  /// can be forgotten at a construction site — the whole point of the
  /// `llm_and_d4rt_tools.md` §8.1 host is that a run reports **stdout, the
  /// auto-awaited `main()` return, and the error + stack** together. A script that
  /// threw never escapes as a Dart exception: it comes back with [error] and
  /// [stack] populated and [ok] `false`. [stdout] is newline-separated print
  /// output in emission order, and is captured even for a failed run, so the
  /// prints leading up to a throw are still readable.
  const ScriptRunResult({
    required this.stdout,
    required this.result,
    required this.error,
    required this.stack,
  });

  /// Whether the run completed without throwing.
  bool get ok => error == null;

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'ok': ok,
        'stdout': stdout,
        'result': result,
        if (error != null) 'error': error,
        if (stack != null) 'stack': stack,
      };
}

/// Authors, validates, runs, and enumerates D4rt scripts under named scopes
/// (`llm_and_d4rt_tools.md` §8.1).
final class ScriptTools {
  /// Creates the toolset over a [registry] of scope presets and a [store].
  ///
  /// [defaultScopes] is applied when a run/validate targets a raw `source` with
  /// no explicit scopes (and a stored script records none) — the
  /// `llm_and_d4rt_tools.md` §8.1 default is the `spec` scope.
  ScriptTools({
    required this.registry,
    required this.store,
    List<String> defaultScopes = const ['spec'],
  }) : defaultScopes = List.unmodifiable(defaultScopes);

  /// The named scope presets a run is built from.
  final ScopeRegistry registry;

  /// The `agent/scripts/` persistence.
  final ScriptStore store;

  /// The scopes used when none are specified or recorded.
  final List<String> defaultScopes;

  /// `script_author` — stores [source] under [name] as a `*.d4rt.dart` file in
  /// `agent/scripts/`, recording the [scopes] it targets in a header. Returns
  /// the stored script's identity + path. Throws [ArgumentError] on an unsafe
  /// name.
  AuthoredScript author(
    String name,
    String source, {
    List<String> scopes = const ['spec'],
  }) {
    _assertValidName(name);
    final header = '$_nameHeader $name\n$_scopesHeader ${scopes.join(', ')}\n\n';
    final path = store.store(name, '$header$source');
    return AuthoredScript(
        name: name, path: path, scopes: List.unmodifiable(scopes));
  }

  /// `script_list` — every stored script, with its recorded scopes.
  List<StoredScript> list() =>
      [for (final name in store.names()) get(name)];

  /// `script_get` — the stored script named [name]. Throws [ArgumentError] when
  /// no such script exists.
  StoredScript get(String name) {
    final source = store.read(name);
    if (source == null) {
      throw ArgumentError.value(name, 'name', 'no such stored script');
    }
    return StoredScript(
      name: name,
      path: store.pathOf(name),
      source: source,
      scopes: _scopesFromHeader(source) ?? defaultScopes,
    );
  }

  /// `script_validate` — parse / declaration-resolve [source] or the stored
  /// script [name] against the granted scope's bridged surface **without**
  /// running `main()`; returns diagnostics so the agent can iterate.
  ///
  /// Beyond the parse/resolve check, validation now performs deeper static
  /// type-checking of the **entrypoint**: it confirms a `main()` is declared and
  /// introspects its argument contract (required/total positional params, named
  /// params, async). When [args] is supplied, it also checks them against that
  /// contract — too few or too many positional arguments is a diagnostic — so an
  /// agent can verify a planned `script_run` call statically. The introspected
  /// contract is returned on [ScriptValidation.entrypoint] regardless.
  ScriptValidation validate({
    String? source,
    String? name,
    List<String>? scopes,
    List<Object?>? args,
  }) {
    final resolved = _resolve(source: source, name: name);
    final env = registry.build(scopes ?? resolved.scopes ?? defaultScopes);
    final interpreter = D4rt();
    env.applyTo(interpreter);

    final IntrospectionResult introspection;
    try {
      introspection = interpreter.analyze(source: resolved.source);
    } catch (error) {
      // Parse / resolution failure — too broken to introspect the entrypoint.
      return ScriptValidation(ok: false, diagnostics: _diagnosticsOf(error));
    }

    final entrypoint = _entrypointOf(introspection);
    final diagnostics = <String>[];
    if (!entrypoint.exists) {
      diagnostics.add('no `main()` entrypoint is declared');
    } else if (args != null) {
      diagnostics.addAll(_argDiagnostics(entrypoint, args));
    }
    return ScriptValidation(
      ok: diagnostics.isEmpty,
      diagnostics: diagnostics,
      entrypoint: entrypoint,
    );
  }

  /// `script_run` — executes [source] or the stored script [name] via
  /// `D4rt.execute` under the resolved scopes, passing [args] to `main()`.
  /// Captures **all three channels**: stdout (every `print`), the auto-awaited
  /// `main()` return value, and any error + stack.
  Future<ScriptRunResult> run({
    String? source,
    String? name,
    List<String>? scopes,
    List<Object?>? args,
  }) async {
    final resolved = _resolve(source: source, name: name);
    final scopeNames = scopes ?? resolved.scopes ?? defaultScopes;
    final env = registry.build(scopeNames);

    // Richer argument contract: when an agent passes `args`,
    // reject an entrypoint mismatch up front with the same diagnostics
    // `validate` produces, instead of surfacing an opaque interpreter arity
    // error deep inside the run.
    if (args != null) {
      final contract =
          validate(source: resolved.source, scopes: scopeNames, args: args);
      if (!contract.ok) {
        return ScriptRunResult(
          stdout: '',
          result: null,
          error: contract.diagnostics.join('; '),
          stack: null,
        );
      }
    }

    final out = StringBuffer();
    Object? result;
    Object? error;
    StackTrace? stack;

    await runZoned(
      () async {
        final interpreter = D4rt();
        env.applyTo(interpreter);
        try {
          final returned =
              interpreter.execute(source: resolved.source, positionalArgs: args);
          result = returned is Future ? await returned : returned;
        } catch (e, s) {
          error = e;
          stack = s;
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => out.writeln(line),
      ),
    );

    final failed = error != null;
    return ScriptRunResult(
      stdout: out.toString(),
      result: failed ? null : result,
      error: failed ? error.toString() : null,
      stack: failed ? stack?.toString() : null,
    );
  }

  // --- helpers ---------------------------------------------------------------

  /// Resolves the source + recorded scopes from either a raw [source] or a
  /// stored [name]. Exactly one must be given.
  ({String source, List<String>? scopes}) _resolve({
    String? source,
    String? name,
  }) {
    if (source != null && name != null) {
      throw ArgumentError('pass exactly one of `source` or `name`, not both');
    }
    if (source != null) return (source: source, scopes: null);
    if (name != null) {
      final stored = store.read(name);
      if (stored == null) {
        throw ArgumentError.value(name, 'name', 'no such stored script');
      }
      return (source: stored, scopes: _scopesFromHeader(stored));
    }
    throw ArgumentError('pass either `source` or `name`');
  }

  void _assertValidName(String name) {
    if (!_validName.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'a script name must be one safe segment ([A-Za-z0-9_-], no separators)',
      );
    }
  }

  /// Parses the `// tomspecs-scopes:` header line, or `null` when absent.
  static List<String>? _scopesFromHeader(String contents) {
    for (final line in const LineSplitter().convert(contents)) {
      final trimmed = line.trim();
      if (trimmed.startsWith(_scopesHeader)) {
        final list = trimmed
            .substring(_scopesHeader.length)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return list.isEmpty ? null : list;
      }
      // The header block is at the very top; stop at the first code line.
      if (trimmed.isNotEmpty && !trimmed.startsWith('//')) break;
    }
    return null;
  }

  /// Introspects the `main()` entrypoint contract from an [analysis] result.
  /// Returns [ScriptEntrypoint.absent] when no top-level `main` is declared.
  static ScriptEntrypoint _entrypointOf(IntrospectionResult analysis) {
    for (final fn in analysis.functions) {
      if (fn.name == 'main') {
        return ScriptEntrypoint(
          exists: true,
          isAsync: fn.isAsync,
          requiredPositional: fn.arity,
          maxPositional: fn.parameterNames.length,
          namedParameters: fn.namedParameterNames,
        );
      }
    }
    return const ScriptEntrypoint.absent();
  }

  /// Checks supplied positional [args] against the entrypoint's positional
  /// contract, returning a diagnostic per violation (empty when they fit).
  static List<String> _argDiagnostics(
    ScriptEntrypoint entrypoint,
    List<Object?> args,
  ) {
    final n = args.length;
    if (n < entrypoint.requiredPositional) {
      return [
        'main() requires at least ${entrypoint.requiredPositional} positional '
            'argument(s) but $n were provided',
      ];
    }
    if (n > entrypoint.maxPositional) {
      return [
        'main() accepts at most ${entrypoint.maxPositional} positional '
            'argument(s) but $n were provided',
      ];
    }
    return const [];
  }

  static List<String> _diagnosticsOf(Object error) {
    final message = error is D4rtException ? error.message : error.toString();
    return [
      for (final line in const LineSplitter().convert(message))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }
}
