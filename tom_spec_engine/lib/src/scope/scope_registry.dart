/// The [ScopeRegistry] and the [RunEnvironment] it builds (§4, plan step 6).
///
/// The registry holds the application's scope *presets* keyed by name; building
/// an environment from one or several scope names unions their libraries,
/// globals, and grants into a single [RunEnvironment] that knows how to apply
/// itself to a `tom_d4rt` interpreter. A [ScopeProfile] is the declarative
/// "which scopes this application enables" datum — data, not code.
library;

import 'package:tom_d4rt/tom_d4rt.dart';

import 'scope.dart';

/// A declarative application profile: the named set of scopes an application
/// (DocSpecs / CodeSpecs / Implementation …) enables (§4).
///
/// This is pure data — a list of scope names — so adding a new application
/// profile never requires code, only a new [ScopeProfile] value. The richer
/// per-application context (tools, guidelines doc) is layered on later (§11);
/// step 6 owns only the scope dimension.
final class ScopeProfile {
  /// The application/profile name.
  final String name;

  /// The names of the scopes this profile enables, in priority order.
  final List<String> scopeNames;

  /// Creates a profile over an unmodifiable copy of [scopeNames].
  ScopeProfile({required this.name, required List<String> scopeNames})
      : scopeNames = List.unmodifiable(scopeNames);

  @override
  String toString() => 'ScopeProfile($name: ${scopeNames.join(', ')})';
}

/// The computed union of one or more scopes: the libraries, globals, and grants
/// a single script run receives.
///
/// Built by [ScopeRegistry.build]; [applyTo] is the only side-effecting step —
/// it registers every bridged library, injects every global, and grants every
/// permission on a fresh interpreter.
final class RunEnvironment {
  /// The scope names this environment was built from, in request order.
  final List<String> scopeNames;

  /// The de-duplicated union of bridged libraries.
  final List<BridgedLibrary> libraries;

  /// The de-duplicated union of injected globals.
  final List<ScopeGlobal> globals;

  /// The accumulated union of permission grants.
  final List<Permission> grants;

  RunEnvironment._({
    required List<String> scopeNames,
    required List<BridgedLibrary> libraries,
    required List<ScopeGlobal> globals,
    required List<Permission> grants,
  })  : scopeNames = List.unmodifiable(scopeNames),
        libraries = List.unmodifiable(libraries),
        globals = List.unmodifiable(globals),
        grants = List.unmodifiable(grants);

  /// Applies this environment to [interpreter]: registers each bridged library,
  /// injects each global, and grants each permission. Idempotent registrations
  /// (a library shared by two scopes) are already de-duplicated at build time.
  void applyTo(D4rt interpreter) {
    for (final library in libraries) {
      library.register(interpreter);
    }
    for (final global in globals) {
      interpreter.registerGlobalVariable(
        global.name,
        global.value,
        global.library,
      );
    }
    for (final grant in grants) {
      interpreter.grant(grant);
    }
  }
}

/// Holds named scope presets and unions them into [RunEnvironment]s (§4).
///
/// `ScopeRegistry` lives in the engine plane; scope definitions are registered
/// once (typically when an application profile boots) and resolved by name when
/// a run is set up.
final class ScopeRegistry {
  final Map<String, ScriptScope> _scopes = {};

  /// Registers a scope preset. Throws [ScopeError] if a scope with the same
  /// name is already registered (presets are unique by name).
  void register(ScriptScope scope) {
    if (_scopes.containsKey(scope.name)) {
      throw ScopeError('a scope named "${scope.name}" is already registered');
    }
    _scopes[scope.name] = scope;
  }

  /// Whether a scope named [name] is registered.
  bool has(String name) => _scopes.containsKey(name);

  /// The registered scope named [name]. Throws [ScopeError] if unknown.
  ScriptScope scope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw ScopeError('unknown scope "$name"');
    }
    return scope;
  }

  /// The names of all registered scopes.
  Iterable<String> get names => _scopes.keys;

  /// Builds a [RunEnvironment] from the union of the named scopes, in the order
  /// given.
  ///
  /// De-duplication rules:
  ///   * **libraries** — by [BridgedLibrary.name]; the first occurrence wins
  ///     (a library shared by two scopes is registered once);
  ///   * **globals** — by [ScopeGlobal.key] (`library::name`); an identical
  ///     re-injection is collapsed, but the *same* key bound to a *different*
  ///     value across scopes is a configuration fault → [ScopeError];
  ///   * **grants** — accumulated, de-duplicated by [Permission.toString].
  ///
  /// Throws [ScopeError] if any name is unknown.
  RunEnvironment build(Iterable<String> scopeNames) {
    final requested = scopeNames.toList();

    final libraries = <BridgedLibrary>[];
    final seenLibraries = <String>{};

    final globals = <ScopeGlobal>[];
    final globalByKey = <String, ScopeGlobal>{};

    final grants = <Permission>[];
    final seenGrants = <String>{};

    for (final name in requested) {
      final scope = this.scope(name); // throws ScopeError if unknown

      for (final library in scope.libraries) {
        if (seenLibraries.add(library.name)) {
          libraries.add(library);
        }
      }

      for (final global in scope.globals) {
        final existing = globalByKey[global.key];
        if (existing == null) {
          globalByKey[global.key] = global;
          globals.add(global);
        } else if (!identical(existing.value, global.value) &&
            existing.value != global.value) {
          throw ScopeError(
            'conflicting global "${global.key}" across scopes: '
            'different values from more than one scope',
          );
        }
      }

      for (final grant in scope.grants) {
        if (seenGrants.add(grant.toString())) {
          grants.add(grant);
        }
      }
    }

    return RunEnvironment._(
      scopeNames: requested,
      libraries: libraries,
      globals: globals,
      grants: grants,
    );
  }

  /// Builds a [RunEnvironment] from a declarative [profile] — sugar for
  /// `build(profile.scopeNames)`.
  RunEnvironment buildProfile(ScopeProfile profile) =>
      build(profile.scopeNames);
}
