/// The **script tools** — the engine-side logic behind the `script_*` MCP tools
/// (§8.1, plan step 13).
///
/// [ScriptTools] is the in-process surface the editor's `AgentToolsModule` wraps
/// as `script_author` / `script_validate` / `script_run` / `script_list` /
/// `script_get`. It binds three things the previous steps built — a
/// [ScopeRegistry] (the named scope presets, step 6+), a [ScriptStore] (the
/// `agent/scripts/` persistence, this step), and the `tom_d4rt` interpreter — so
/// an agent can:
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
/// (§5, req c). Scripting is strictly more expressive than the single-shot MCP
/// tools, never a second source of truth (§8.3).
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

/// The result of `script_validate`: whether the script is acceptable and, if
/// not, the diagnostics the agent can iterate on.
final class ScriptValidation {
  /// Whether the script parsed and resolved against the granted scope.
  final bool ok;

  /// Human-readable diagnostics (empty when [ok]).
  final List<String> diagnostics;

  const ScriptValidation({required this.ok, required this.diagnostics});

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {'ok': ok, 'diagnostics': diagnostics};
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
/// (§8.1).
final class ScriptTools {
  /// Creates the toolset over a [registry] of scope presets and a [store].
  ///
  /// [defaultScopes] is applied when a run/validate targets a raw `source` with
  /// no explicit scopes (and a stored script records none) — the §8.1 default
  /// is the `spec` scope.
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
  ScriptValidation validate({
    String? source,
    String? name,
    List<String>? scopes,
  }) {
    final resolved = _resolve(source: source, name: name);
    final env = registry.build(scopes ?? resolved.scopes ?? defaultScopes);
    final interpreter = D4rt();
    env.applyTo(interpreter);
    try {
      interpreter.analyze(source: resolved.source);
      return const ScriptValidation(ok: true, diagnostics: []);
    } catch (error) {
      return ScriptValidation(ok: false, diagnostics: _diagnosticsOf(error));
    }
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
    final env = registry.build(scopes ?? resolved.scopes ?? defaultScopes);

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

  // --- helpers -------------------------------------------------------------

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

  static List<String> _diagnosticsOf(Object error) {
    final message = error is D4rtException ? error.message : error.toString();
    return [
      for (final line in const LineSplitter().convert(message))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }
}
