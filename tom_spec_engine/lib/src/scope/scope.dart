/// The D4rt scripting **scope** model
/// (`llm_and_d4rt_tools.md` §4).
///
/// A *scope* is a named, immutable set of three things a script run is granted:
///
///   * **bridged D4rt libraries** — the registrar callbacks that expose a
///     bridged API surface to the interpreter (e.g. the generated `TomSomBridge`
///     for the `spec` scope, the `dcli` facade for `files`);
///   * **injected globals** — `(name, value)` pairs registered under a library
///     URI a script imports to reach them;
///   * **permission grants** — `tom_d4rt` [Permission]s (filesystem / network /
///     process …) the run is allowed to exercise.
///
/// Scopes are *presets*: they are registered once in a [ScopeRegistry] and a run
/// names the ones it needs. They are composable — see [ScopeRegistry.build],
/// which unions several scopes into a single [RunEnvironment]. The scope itself
/// is pure value data (plus opaque registrar callbacks), so an application's
/// *profile* — which scopes it enables — is declarative data, not code.
///
/// This `ScriptScope` is deliberately distinct from [MemoryScope] (the Tom
/// Brain memory-addressing key) and from `tom_brain`'s own `Scope`: it names a
/// *D4rt scripting surface*, not a memory partition. See
/// `llm_and_d4rt_tools.md` §4.
library;

import 'package:tom_d4rt/tom_d4rt.dart';

/// Registers a bridged-library surface with a D4rt [interpreter].
///
/// The callback is opaque to the scope model — it is exactly what `tom_d4rt`
/// needs to expose one importable library (e.g. `TomSomBridge.register`).
typedef LibraryRegistrar = void Function(D4rt interpreter);

/// A named, reusable bridged-library building block.
///
/// The [name] is the building block's identity used for de-duplication when
/// several scopes share the same library (it also doubles as the human-facing
/// label of the surface, conventionally the import path it exposes). [register]
/// performs the actual `tom_d4rt` registration against an interpreter.
final class BridgedLibrary {
  /// Identity / label of this library (conventionally the import path exposed).
  final String name;

  final LibraryRegistrar _registrar;

  /// Creates a bridged-library block bound to its [name] and [registrar].
  const BridgedLibrary(this.name, LibraryRegistrar registrar)
      : _registrar = registrar;

  /// Registers this library's bridged surface with [interpreter].
  void register(D4rt interpreter) => _registrar(interpreter);

  @override
  bool operator ==(Object other) =>
      other is BridgedLibrary && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'BridgedLibrary($name)';
}

/// An injected global variable: [value] bound to [name], visible to a script
/// that imports [library] (the registration-key URI).
final class ScopeGlobal {
  /// The variable name a script references.
  final String name;

  /// The value captured at registration time.
  final Object? value;

  /// The library URI a script imports to bring [name] into scope.
  final String library;

  /// Creates an injected-global descriptor.
  const ScopeGlobal({
    required this.name,
    required this.value,
    required this.library,
  });

  /// The composite identity used to detect cross-scope conflicts: two globals
  /// collide only when both [library] and [name] match.
  String get key => '$library::$name';

  @override
  String toString() => 'ScopeGlobal($library::$name)';
}

/// A named, immutable D4rt scripting scope (`llm_and_d4rt_tools.md` §4).
///
/// Holds the [libraries], [globals], and [grants] a run is given when this scope
/// is active. All three collections are unmodifiable; scopes are identified and
/// de-duplicated by [name].
final class ScriptScope {
  /// The scope's unique name (e.g. `spec`, `files`, `memory`).
  final String name;

  /// The bridged D4rt libraries this scope exposes.
  final List<BridgedLibrary> libraries;

  /// The globals this scope injects.
  final List<ScopeGlobal> globals;

  /// The permission grants this scope confers.
  final List<Permission> grants;

  /// Creates a scope, copying each collection into an unmodifiable view so the
  /// scope is immutable once built.
  ScriptScope({
    required this.name,
    List<BridgedLibrary>? libraries,
    List<ScopeGlobal>? globals,
    List<Permission>? grants,
  })  : libraries = List.unmodifiable(libraries ?? const []),
        globals = List.unmodifiable(globals ?? const []),
        grants = List.unmodifiable(grants ?? const []);

  @override
  bool operator ==(Object other) => other is ScriptScope && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'ScriptScope($name, libraries: ${libraries.length}, '
      'globals: ${globals.length}, grants: ${grants.length})';
}

/// Raised for scope-configuration faults: an unknown scope name, a duplicate
/// registration, or a conflicting injected global across unioned scopes.
final class ScopeError implements Exception {
  /// Human-readable description of the fault.
  final String message;

  /// Creates a scope error with [message].
  ScopeError(this.message);

  @override
  String toString() => 'ScopeError: $message';
}
