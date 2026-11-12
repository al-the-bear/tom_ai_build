/// IR Specs (`irspecs_ir.md`): the IR of both Meridian CodeSpecs trios
/// validates against its JSON Schema, reads back equal, and keeps every
/// CsModel field.
///
/// The field test walks the CsModel objects reflectively, so it needs no list
/// of fields of its own: a field added to CsModel is compared as soon as it
/// exists, and it fails twice over until the IR carries it — once because the
/// read-back object lacks its value, once because it is in neither
/// [irCarriedCsModelFields] nor [irOmittedCsModelFields].
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';
import 'package:yaml/yaml.dart';

/// The two Meridian trios, as (name, shared, client, server) roots.
final _trios = {
  'phase4_codespecs_run': [
    for (final locus in ['shared', 'client', 'server'])
      p.absolute('../tom_specs_samples/phase4_codespecs_run/codespec/$locus'),
  ],
  'meridian_codespecs': [
    for (final locus in ['shared', 'client', 'server'])
      p.absolute(
        '../tom_som_conformance/samples/meridian_codespecs/'
        'meridian_codespec_$locus',
      ),
  ],
};

final _areasJson = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);

IrAreaIndex _areas() => IrAreaIndex(
  CodeSpecsAreaCatalog.fromJson(
    jsonDecode(File(_areasJson).readAsStringSync()) as Map<String, dynamic>,
  ),
);

({CsLocusProject shared, CsLocusProject client, CsLocusProject server})
_readTrio(List<String> roots) {
  CsLocusProject read(CsLocus locus, String root) =>
      readCsLocusProjectFromDirectory(
        locus: locus,
        packageName: p.basename(root),
        root: root,
      );
  return (
    shared: read(CsLocus.shared, roots[0]),
    client: read(CsLocus.client, roots[1]),
    server: read(CsLocus.server, roots[2]),
  );
}

/// Every difference between [a] and [b], field by field, reflectively.
/// `CsFile.source` is skipped: the IR omits it on purpose.
List<String> _differences(Object? a, Object? b, String path) {
  if (a == null || b == null) {
    return a == b ? const [] : ['$path: $a != $b'];
  }
  if (a is String || a is num || a is bool || a is Enum) {
    return a == b ? const [] : ['$path: $a != $b'];
  }
  if (a is List) {
    if (b is! List || a.length != b.length) {
      return ['$path: list of ${a.length} != ${b is List ? b.length : b}'];
    }
    return [
      for (var i = 0; i < a.length; i++)
        ..._differences(a[i], b[i], '$path[$i]'),
    ];
  }
  if (a is Map) {
    if (b is! Map || !_sameKeys(a.keys.toList(), b.keys.toList())) {
      return ['$path: map keys ${a.keys} != ${b is Map ? b.keys : b}'];
    }
    return [
      for (final key in a.keys) ..._differences(a[key], b[key], '$path.$key'),
    ];
  }
  if (a.runtimeType != b.runtimeType) {
    return ['$path: ${a.runtimeType} != ${b.runtimeType}'];
  }
  final className = MirrorSystem.getName(reflect(a).type.simpleName);
  return [
    for (final field in _fieldsOf(a))
      if (!(className == 'CsFile' && field == 'source'))
        ..._differences(
          reflect(a).getField(Symbol(field)).reflectee,
          reflect(b).getField(Symbol(field)).reflectee,
          '$path.$field',
        ),
  ];
}

bool _sameKeys(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((s) => s);

/// The instance fields [object]'s class declares (CsModel classes extend no
/// class with fields of its own but `CsValue`, which has none).
List<String> _fieldsOf(Object object) => [
  for (final d in reflect(object).type.declarations.values)
    if (d is VariableMirror && !d.isStatic) MirrorSystem.getName(d.simpleName),
];

/// Every (class, field) pair of the CsModel objects reachable from [root].
Map<String, Set<String>> _modelFields(Object? root) {
  final out = <String, Set<String>>{};
  void walk(Object? o) {
    if (o == null || o is String || o is num || o is bool || o is Enum) return;
    if (o is List) return o.forEach(walk);
    if (o is Map) return o.values.forEach(walk);
    final name = MirrorSystem.getName(reflect(o).type.simpleName);
    final fields = out.putIfAbsent(name, () => {});
    for (final field in _fieldsOf(o)) {
      fields.add(field);
      walk(reflect(o).getField(Symbol(field)).reflectee);
    }
  }

  walk(root);
  return out;
}

void main() {
  final schema = JsonSchema.create(
    jsonDecode(File('tool/irspecs_ir.schema.json').readAsStringSync()),
  );

  for (final MapEntry(key: name, value: roots) in _trios.entries) {
    group('IRS1 ($name): the trio through the IR', () {
      final trio = _readTrio(roots);
      final documents = irFromCsModel(
        shared: trio.shared,
        client: trio.client,
        server: trio.server,
        areas: _areas(),
      );

      test('every file of the trio is in exactly one document', () {
        final inIr = [
          for (final d in documents)
            for (final f in d.files) '${f.locus.name}:${f.file.path}',
        ];
        final inTrio = [
          for (final project in [trio.shared, trio.client, trio.server])
            for (final f in project.files) '${project.locus.name}:${f.path}',
        ];
        expect(inTrio, isNotEmpty);
        expect(inIr..sort(), inTrio..sort());
      });

      test('every document validates against the schema', () {
        for (final document in documents) {
          final data = plainYaml(loadYaml(writeIrYaml(document)));
          final result = schema.validate(data);
          expect(
            result.isValid,
            isTrue,
            reason: '${document.fileName}: ${result.errors.join('\n')}',
          );
        }
      });

      test('every document reads back to the same text', () {
        for (final document in documents) {
          final text = writeIrYaml(document);
          expect(
            writeIrYaml(readIrYaml(text, source: document.fileName)),
            text,
            reason: document.fileName,
          );
        }
      });

      test('the trio read back from the IR has every CsModel field', () {
        final back = csModelFromIr([
          for (final document in documents)
            readIrYaml(writeIrYaml(document), source: document.fileName),
        ]);
        expect(_differences(trio.shared, back.shared, 'shared'), isEmpty);
        expect(_differences(trio.client, back.client, 'client'), isEmpty);
        expect(_differences(trio.server, back.server, 'server'), isEmpty);
      });

      test('every CsModel field is carried or omitted with a reason', () {
        final fields = _modelFields([trio.shared, trio.client, trio.server]);
        for (final MapEntry(key: cls, value: names) in fields.entries) {
          final known = {
            ...?irCarriedCsModelFields[cls],
            ...?irOmittedCsModelFields[cls]?.keys,
          };
          expect(
            names.difference(known),
            isEmpty,
            reason:
                '$cls has fields the IR neither carries nor omits; add them '
                'to ir_codec.dart and irspecs_ir.md',
          );
        }
      });
    });
  }

  group('IRS2: the document set', () {
    test('the meridian trio fills the areas it has files for', () {
      final trio = _readTrio(_trios['meridian_codespecs']!);
      final documents = irFromCsModel(
        shared: trio.shared,
        client: trio.client,
        server: trio.server,
        areas: _areas(),
      );
      expect(documents.map((d) => d.area), [
        'CE-EN',
        'CE-LO',
        'CE-TX',
        'CE-SC',
        'CE-API',
        'CE-SU',
        'CE-DB',
        'CE-NV',
        'CE-AZ',
        'CE-ER',
        kIrPackageArea,
      ]);
      // Only the three barrel libraries belong to no area, and a barrel is
      // its exports — which the reader keeps for the IR.
      expect(
        documents.last.files.map((f) => f.file.path),
        everyElement(isNot(contains('/src/'))),
      );
      expect(
        documents.last.files.map((f) => f.file.exports),
        everyElement(isNotEmpty),
      );
    });

    test('a document naming a different package is refused', () {
      const a = IrDocument(
        area: 'CE-DB',
        projects: [
          IrProject(CsLocus.shared, 's'),
          IrProject(CsLocus.client, 'c'),
          IrProject(CsLocus.server, 'x'),
        ],
        files: [],
      );
      const b = IrDocument(
        area: 'CE-SU',
        projects: [
          IrProject(CsLocus.shared, 's'),
          IrProject(CsLocus.client, 'c'),
          IrProject(CsLocus.server, 'y'),
        ],
        files: [],
      );
      expect(() => csModelFromIr([a, b]), throwsA(isA<IrSpecsException>()));
      expect(() => csModelFromIr([]), throwsA(isA<IrSpecsException>()));
    });

    test('a wrong format or version is refused', () {
      expect(
        () => readIrYaml('format: "x"\nformatVersion: 1\n'),
        throwsA(isA<IrSpecsException>()),
      );
      expect(
        () => readIrYaml('format: "irspecs-ir"\nformatVersion: 2\n'),
        throwsA(isA<IrSpecsException>()),
      );
    });

    test('strings that YAML would misread are written quoted', () {
      const tricky = [
        'a: b',
        '# not a comment',
        "it's \"quoted\" \\ back",
        '  leading',
        'yes',
        '',
        'line\nbreak',
        'ünïcödé — dash',
      ];
      final document = IrDocument(
        area: 'CE-TX',
        projects: const [
          IrProject(CsLocus.shared, 's'),
          IrProject(CsLocus.client, 'c'),
          IrProject(CsLocus.server, 'v'),
        ],
        files: [
          IrFile(
            CsLocus.shared,
            CsFile(
              path: 'lib/src/text/t.dart',
              source: '',
              imports: tricky,
              declarations: const [],
              constructions: const [],
            ),
          ),
        ],
      );
      final back = readIrYaml(writeIrYaml(document));
      expect(back.files.single.file.imports, tricky);
    });
  });

  group('IRS3: the irspecs command', () {
    test(
      'from-codespecs writes one file per area and deletes stale ones',
      () async {
        final roots = _trios['meridian_codespecs']!;
        final out = Directory.systemTemp.createTempSync('irspecs_cli');
        addTearDown(() => out.deleteSync(recursive: true));
        File(p.join(out.path, 'CE-XX.ir.yaml')).writeAsStringSync('stale');
        final stdoutBuffer = StringBuffer();
        final code = await runIrspecs([
          'from-codespecs',
          '--shared',
          roots[0],
          '--client',
          roots[1],
          '--server',
          roots[2],
          '--areas',
          _areasJson,
          '--out',
          out.path,
        ], out: stdoutBuffer);
        expect(code, 0);
        final names = out.listSync().map((e) => p.basename(e.path)).toList()
          ..sort();
        expect(names, contains('CE-DB.ir.yaml'));
        expect(names, contains('package.ir.yaml'));
        expect(names, isNot(contains('CE-XX.ir.yaml')));
        expect('$stdoutBuffer', contains('CE-XX.ir.yaml'));

        // A second run over the same trio changes nothing.
        final second = StringBuffer();
        await runIrspecs([
          'from-codespecs',
          '--shared',
          roots[0],
          '--client',
          roots[1],
          '--server',
          roots[2],
          '--areas',
          _areasJson,
          '--out',
          out.path,
        ], out: second);
        expect(
          '$second'.trim().split('\n'),
          everyElement(contains('unchanged')),
        );
      },
    );

    test('a missing option or subcommand is bad usage', () async {
      final err = StringBuffer();
      expect(await runIrspecs(['from-codespecs'], err: err), 2);
      expect('$err', contains('--shared'));
      expect(await runIrspecs([], err: StringBuffer()), 2);
    });
  });
}
