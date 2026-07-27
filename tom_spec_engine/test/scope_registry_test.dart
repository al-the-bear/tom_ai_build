import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 6 / `d4rt_and_llm_tools.md` §4: the D4rt scripting scope model
/// and [ScopeRegistry].
///
/// A scope is a named, immutable set of bridged libraries + injected globals +
/// permission grants; a run is granted the *union* of one or more scopes; and
/// an application profile (which scopes it enables) is declarative data. These
/// tests build a [RunEnvironment] from a single scope and from several, assert
/// the union/de-duplication rules, and prove the environment applies cleanly to
/// a real `tom_d4rt` interpreter.

/// A [BridgedLibrary] whose registrar appends its [name] to [log] so tests can
/// observe registration order and de-duplication.
BridgedLibrary _recordingLibrary(String name, List<String> log) =>
    BridgedLibrary(name, (_) => log.add(name));

void main() {
  group('ScriptScope value semantics', () {
    test('collections are immutable and copied', () {
      final libs = [_recordingLibrary('a', [])];
      final scope = ScriptScope(name: 'spec', libraries: libs);
      // Mutating the source list does not affect the scope.
      libs.add(_recordingLibrary('b', []));
      expect(scope.libraries, hasLength(1));
      // The scope's own list is unmodifiable.
      expect(() => scope.libraries.add(_recordingLibrary('c', [])),
          throwsUnsupportedError);
    });

    test('identity and equality are by name', () {
      expect(ScriptScope(name: 'spec'), equals(ScriptScope(name: 'spec')));
      expect(ScriptScope(name: 'spec'), isNot(equals(ScriptScope(name: 'files'))));
    });
  });

  group('ScopeRegistry registration', () {
    late ScopeRegistry registry;
    setUp(() => registry = ScopeRegistry());

    test('register / has / scope / names', () {
      final spec = ScriptScope(name: 'spec');
      registry.register(spec);
      expect(registry.has('spec'), isTrue);
      expect(registry.has('files'), isFalse);
      expect(registry.scope('spec'), same(spec));
      expect(registry.names, contains('spec'));
    });

    test('unknown scope name throws ScopeError', () {
      expect(() => registry.scope('nope'), throwsA(isA<ScopeError>()));
      expect(() => registry.build(['nope']), throwsA(isA<ScopeError>()));
    });

    test('duplicate registration throws ScopeError', () {
      registry.register(ScriptScope(name: 'spec'));
      expect(() => registry.register(ScriptScope(name: 'spec')),
          throwsA(isA<ScopeError>()));
    });
  });

  group('build — single scope', () {
    test('environment carries the scope libraries, globals and grants', () {
      final registry = ScopeRegistry();
      registry.register(ScriptScope(
        name: 'files',
        libraries: [_recordingLibrary('dcli', [])],
        globals: [
          const ScopeGlobal(
              name: 'root', value: '/work', library: 'package:x/x.dart'),
        ],
        grants: [FilesystemPermission.read],
      ));

      final env = registry.build(['files']);
      expect(env.scopeNames, ['files']);
      expect(env.libraries.map((l) => l.name), ['dcli']);
      expect(env.globals.single.name, 'root');
      expect(env.grants, contains(FilesystemPermission.read));
    });
  });

  group('build — union of several scopes', () {
    late ScopeRegistry registry;
    setUp(() {
      registry = ScopeRegistry();
    });

    test('unions libraries/globals/grants and preserves request order', () {
      registry.register(ScriptScope(
        name: 'spec',
        libraries: [_recordingLibrary('tom_som', [])],
        globals: [
          const ScopeGlobal(
              name: 'doc', value: 1, library: 'package:som/som.dart'),
        ],
        grants: [FilesystemPermission.read],
      ));
      registry.register(ScriptScope(
        name: 'files',
        libraries: [_recordingLibrary('dcli', [])],
        grants: [FilesystemPermission.write],
      ));

      final env = registry.build(['spec', 'files']);
      expect(env.scopeNames, ['spec', 'files']);
      expect(env.libraries.map((l) => l.name), ['tom_som', 'dcli']);
      expect(env.globals.map((g) => g.name), ['doc']);
      expect(env.grants,
          containsAll([FilesystemPermission.read, FilesystemPermission.write]));
    });

    test('a library shared by two scopes is de-duplicated by name', () {
      final shared = _recordingLibrary('tom_som', []);
      registry.register(ScriptScope(name: 'spec', libraries: [shared]));
      registry.register(ScriptScope(name: 'memory', libraries: [shared]));

      final env = registry.build(['spec', 'memory']);
      expect(env.libraries, hasLength(1));
      expect(env.libraries.single.name, 'tom_som');
    });

    test('an identical global injected by two scopes collapses', () {
      const g = ScopeGlobal(
          name: 'doc', value: 'D1', library: 'package:som/som.dart');
      registry.register(ScriptScope(name: 'spec', globals: [g]));
      registry.register(ScriptScope(name: 'memory', globals: [g]));
      final env = registry.build(['spec', 'memory']);
      expect(env.globals, hasLength(1));
    });

    test('the same global key bound to different values is a ScopeError', () {
      registry.register(ScriptScope(name: 'spec', globals: [
        const ScopeGlobal(
            name: 'doc', value: 'A', library: 'package:som/som.dart'),
      ]));
      registry.register(ScriptScope(name: 'memory', globals: [
        const ScopeGlobal(
            name: 'doc', value: 'B', library: 'package:som/som.dart'),
      ]));
      expect(() => registry.build(['spec', 'memory']),
          throwsA(isA<ScopeError>()));
    });

    test('duplicate grants are de-duplicated', () {
      registry.register(ScriptScope(
          name: 'spec', grants: [FilesystemPermission.read]));
      registry.register(ScriptScope(
          name: 'memory', grants: [FilesystemPermission.read]));
      final env = registry.build(['spec', 'memory']);
      expect(env.grants, hasLength(1));
    });
  });

  group('ScopeProfile — declarative', () {
    test('buildProfile builds from the profile scope names (data, not code)', () {
      final registry = ScopeRegistry();
      registry.register(ScriptScope(name: 'spec'));
      registry.register(ScriptScope(name: 'files'));
      registry.register(ScriptScope(name: 'memory'));

      final docSpecs = ScopeProfile(
        name: 'docspecs',
        scopeNames: ['spec', 'files', 'memory'],
      );
      final env = registry.buildProfile(docSpecs);
      expect(env.scopeNames, ['spec', 'files', 'memory']);
    });

    test('a profile carries opt-in asset dirs; default is empty (item 18)', () {
      final bare = ScopeProfile(name: 'bare', scopeNames: ['files']);
      expect(bare.assetDirs, isEmpty);

      final withAssets = ScopeProfile(
        name: 'docspecs',
        scopeNames: ['files'],
        assetDirs: const ['templates', 'schemas'],
      );
      expect(withAssets.assetDirs, ['templates', 'schemas']);
      // The list is unmodifiable, like scopeNames.
      expect(() => withAssets.assetDirs.add('x'), throwsUnsupportedError);
    });
  });

  group('applyTo — real interpreter integration', () {
    test('registers the SOM bridge, injects a global, grants permission; a '
        'script under the environment uses all three', () {
      const globalLib = 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
      final registry = ScopeRegistry();
      registry.register(ScriptScope(
        name: 'spec',
        libraries: [somBridgedLibrary()],
        globals: [
          const ScopeGlobal(
              name: 'runLabel', value: 'docspecs-run', library: globalLib),
        ],
        grants: [FilesystemPermission.read],
      ));

      final env = registry.build(['spec']);
      final d4rt = D4rt();
      env.applyTo(d4rt);

      // The grant landed on the interpreter.
      expect(d4rt.hasPermission(FilesystemPermission.read), isTrue);

      // A script reaches both the bridged SOM API and the injected global,
      // proving the scope's libraries + globals are both live.
      final result = d4rt.execute(source: r'''
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

main() {
  final doc = SpecDocument();
  doc.setContent('PD/content', 'via scope');
  return {'read': doc.content('PD/content'), 'label': runLabel};
}
''') as Map;

      expect(result['read'], 'via scope');
      expect(result['label'], 'docspecs-run');
    });
  });
}
