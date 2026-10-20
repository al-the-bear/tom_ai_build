/// Registry-driven test generation (uamtc18): the generator derives the
/// operation and screen suites from a specification's registries and
/// cross-checks them, and `--check` finds a suite that no longer matches.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

const _registries = RegistrySet(
  roles: [
    RegistryRole(name: 'admin', entitlements: ['app.*']),
    RegistryRole(name: 'clerk', entitlements: ['app.read']),
  ],
  errorCodes: ['E-READ'],
  operations: [
    RegistryOperation(
      name: 'readThing',
      errorCodes: ['E-READ'],
      requirement: RegistryRequirement(
        kind: 'entitlement',
        patterns: ['app.read'],
      ),
      idempotency: 'idempotent',
      auditEvent: 'thing.read',
      rateLimitClass: 'reads',
    ),
    RegistryOperation(
      name: 'deleteThing',
      errorCodes: ['E-GONE'],
      requirement: RegistryRequirement(kind: 'role', roles: ['admin']),
    ),
    RegistryOperation(
      name: 'ping',
      requirement: RegistryRequirement(kind: 'public'),
    ),
    RegistryOperation(
      name: 'decideThing',
      requirement: RegistryRequirement(kind: 'custom', handler: 'thingOwner'),
    ),
    RegistryOperation(
      name: 'archiveThing',
      requirement: RegistryRequirement(kind: 'role', roles: ['clerk']),
    ),
  ],
  screens: [
    RegistryScreen(id: 'SCREN-ITEM-LIST', operations: ['readThing', 'ghost']),
    RegistryScreen(id: 'SCREN-ITEM-EDIT', operations: ['deleteThing']),
  ],
);

void main() {
  final generation = generateRegistryTests(_registries);
  final ops = generation.files[operationsFile]!;
  final screens = generation.files[screensFile]!;

  group('RT-1: the operations suite', () {
    test(
      'a role requirement gives a permitted and a refused case per role',
      () {
        expect(ops, contains("OPS-deleteThing-admin: permitted"));
        expect(ops, contains("OPS-deleteThing-clerk: refused"));
        expect(ops, contains("OPS-deleteThing-anonymous: refused"));
      },
    );
    test(
      'an entitlement requirement matches the role entitlements as globs',
      () {
        expect(ops, contains("OPS-readThing-admin: permitted"));
        expect(ops, contains("OPS-readThing-clerk: permitted"));
        expect(ops, contains("OPS-readThing-anonymous: refused"));
      },
    );
    test('public, custom handler, error codes and controls', () {
      expect(ops, contains("OPS-ping-anonymous: permitted"));
      expect(ops, contains("OPS-decideThing-handler: decided by thingOwner"));
      expect(ops, isNot(contains('OPS-decideThing-admin')));
      expect(ops, contains("OPS-readThing-error-E-READ"));
      expect(ops, contains("OPS-readThing-idempotent"));
      expect(ops, contains("OPS-readThing-audit: records thing.read"));
      expect(ops, contains("OPS-readThing-rate: throttled as reads"));
    });
  });

  test('RT-2: the screens suite renders each screen per role and hides '
      'refused actions', () {
    expect(screens, contains('SCR-SCREN-ITEM-EDIT-clerk: renders'));
    expect(
      screens,
      contains('SCR-SCREN-ITEM-EDIT-clerk-hides-deleteThing: action hidden'),
    );
    expect(screens, isNot(contains('SCR-SCREN-ITEM-EDIT-admin-hides')));
  });

  test(
    'RT-3: the cross-check finds an undeclared error code, an action '
    'without an operation and a person-called operation without a screen',
    () {
      final byCode = {
        for (final f in generation.findings) '${f.code}|${f.message}': f,
      };
      expect(byCode.keys.where((k) => k.startsWith('undeclaredErrorCode')), [
        contains('E-GONE'),
      ]);
      expect(byCode.keys.where((k) => k.startsWith('unknownOperation')), [
        contains('ghost'),
      ]);
      expect(byCode.keys.where((k) => k.startsWith('operationWithoutScreen')), [
        contains('archiveThing'),
      ]);
    },
  );

  group('RT-4: --check against the files on disk', () {
    test('the generated files match themselves, formatting aside', () {
      final onDisk = {
        for (final e in generation.files.entries)
          e.key: e.value.replaceAll('\n', '\n\n'),
      };
      expect(checkRegistryTests(generation, onDisk), isEmpty);
    });
    test('a removed role case is detected', () {
      final onDisk = Map<String, String?>.of(generation.files);
      onDisk[operationsFile] = ops
          .split('\n')
          .where((l) => !l.contains('OPS-deleteThing-clerk'))
          .join('\n');
      final found = checkRegistryTests(generation, onDisk);
      expect(found.map((f) => f.code), ['missingCase']);
      expect(found.single.message, contains('OPS-deleteThing-clerk'));
    });
    test('ids are found in formatted output too', () {
      expect(
        registryTestIds("  test(\n    'OPS-a-b: permitted',\n    () => x);"),
        {'OPS-a-b'},
      );
    });
    test('a missing file is detected', () {
      final onDisk = Map<String, String?>.of(generation.files)
        ..[screensFile] = null;
      expect(checkRegistryTests(generation, onDisk).map((f) => f.code), [
        'missingFile',
      ]);
    });
  });

  test('RT-5: the registries are read from a real specification', () {
    final tree = buildSomMetaTree(
      somSpecModel,
      rootType: 'D00SolutionBlueprint',
    );
    final doc = SpecDocument.fromFile(
      '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
      tree,
    );
    final registries = readRegistries(somSpecModel, doc);
    expect(registries.operations, isNotEmpty);
    expect(registries.roles, isNotEmpty);
    expect(registries.screens, isNotEmpty);
    expect(
      registries.operations.where((o) => o.requirement.kind.isNotEmpty),
      isNotEmpty,
    );
  });

  test(
    'RT-6: the generated suites compile against an application harness',
    () async {
      final dir = Directory('rt6_generated_suites');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync();
      addTearDown(() => dir.deleteSync(recursive: true));
      for (final e in generation.files.entries) {
        File(p.join(dir.path, e.key)).writeAsStringSync(e.value);
      }
      File(p.join(dir.path, 'registry_harness.dart')).writeAsStringSync('''
import 'registry_harness.g.dart';

RegistryTestHarness createRegistryTestHarness() => _Stub();

class _Stub implements RegistryTestHarness {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
''');
      final result = await Process.run('dart', ['analyze', dir.path]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
