/// Generation units in the IR (`irspecs_ir.md` §8.1):
/// `irspecs map --spec <document> --unit <id>` writes one unit's package —
/// the share of the IR its locus, its mapped areas and the files' own `units`
/// give it.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecGenerationUnit, SpecGenerationUnitMapping;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _spec = p.absolute(
  '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
const _units = [
  'meridian_codespec_shared',
  'meridian_codespec_client',
  'meridian_codespec_server',
];

/// Every `.dart` file under [root]'s `lib/`, path → text.
Map<String, String> _lib(String root) => {
  for (final f in Directory(
    p.join(root, 'lib'),
  ).listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart'))
      p.split(p.relative(f.path, from: root)).join('/'): f.readAsStringSync(),
};

IrFile _file(CsLocus locus, String path, [List<String> units = const []]) =>
    IrFile(
      locus,
      CsFile(
        path: path,
        source: '',
        imports: const [],
        exports: const [],
        comments: const [],
        declarations: const [],
        constructions: const [],
      ),
      const [],
      units,
    );

void main() {
  group('IRU1: the Meridian trio, written unit by unit', () {
    late Directory scratch;
    setUpAll(() async {
      scratch = Directory.systemTemp.createTempSync('irspecs_units');
      final ir = p.join(scratch.path, 'ir');
      expect(
        await runIrspecs([
          'from-codespecs',
          '--shared',
          p.join(_meridian, _units[0]),
          '--client',
          p.join(_meridian, _units[1]),
          '--server',
          p.join(_meridian, _units[2]),
          '--areas',
          _areas,
          '--out',
          ir,
        ], out: StringBuffer()),
        0,
      );
      for (final unit in _units) {
        expect(
          await runIrspecs([
            'map',
            '--mapper',
            'dart-tom',
            '--ir',
            ir,
            '--out',
            p.join(scratch.path, 'out'),
            '--spec',
            _spec,
            '--unit',
            unit,
          ], out: StringBuffer()),
          0,
          reason: unit,
        );
      }
    });
    tearDownAll(() => scratch.deleteSync(recursive: true));

    for (final unit in _units) {
      test('$unit is byte-equal to its committed package', () {
        expect(
          _lib(p.join(scratch.path, 'out', unit)),
          _lib(p.join(_meridian, unit)),
        );
      });
    }

    test('a unit writes into its own folder and no other', () {
      expect(
        Directory(
          p.join(scratch.path, 'out'),
        ).listSync().map((e) => p.basename(e.path)).toSet(),
        _units.toSet(),
      );
    });
  });

  group('IRU2: what a unit takes', () {
    final docs = [
      IrDocument(
        area: 'CE-TX',
        projects: const [
          IrProject(CsLocus.shared, 'shared'),
          IrProject(CsLocus.client, 'client'),
          IrProject(CsLocus.server, 'server'),
        ],
        files: [
          _file(CsLocus.client, 'lib/a.dart'),
          _file(CsLocus.client, 'lib/b.dart', ['web']),
          _file(CsLocus.client, 'lib/c.dart', ['mobile']),
          _file(CsLocus.shared, 'lib/d.dart'),
        ],
      ),
      IrDocument(
        area: 'CE-DB',
        projects: const [IrProject(CsLocus.server, 'server')],
        files: [_file(CsLocus.server, 'lib/e.dart')],
      ),
      IrDocument(
        area: kIrPackageArea,
        projects: const [IrProject(CsLocus.client, 'client')],
        files: [_file(CsLocus.client, 'lib/client.dart')],
      ),
    ];
    const web = IrUnit(
      unitId: 'web',
      locus: CsLocus.client,
      mappings: {'CE-TX': 'dart-tom'},
    );

    test('its locus, its mapped areas, the files naming it, the package', () {
      final share = irDocumentsForUnit(docs, web, mapper: 'dart-tom');
      expect([for (final d in share) d.area], ['CE-TX', kIrPackageArea]);
      expect(
        [for (final f in share.first.files) f.file.path],
        ['lib/a.dart', 'lib/b.dart'],
      );
      expect(
        [
          for (final d in share)
            for (final pr in d.projects) pr.packageName,
        ],
        ['web', 'web'],
      );
    });

    test('an area another mapper holds for the unit is left out', () {
      final share = irDocumentsForUnit(docs, web, mapper: 'ts-react');
      expect([for (final d in share) d.area], [kIrPackageArea]);
    });

    test('a unit of kind other is refused; the first mapping wins', () {
      expect(
        () => IrUnit.fromRegister(
          const SpecGenerationUnit(
            unitId: 'docs',
            kind: 'other',
            path: 'X',
            mappings: [],
          ),
        ),
        throwsA(isA<IrSpecsException>()),
      );
      final unit = IrUnit.fromRegister(
        const SpecGenerationUnit(
          unitId: 'web',
          kind: 'client',
          path: 'X',
          mappings: [
            SpecGenerationUnitMapping(area: 'CE-TX', mapping: 'dart-tom'),
            SpecGenerationUnitMapping(area: 'CE-TX', mapping: 'ts-react'),
          ],
        ),
      );
      expect(unit.locus, CsLocus.client);
      expect(unit.mappings, {'CE-TX': 'dart-tom'});
    });

    test('file units round-trip through YAML, absent when empty', () {
      final yaml = writeIrYaml(docs.first);
      expect('units:'.allMatches(yaml), hasLength(2));
      final back = readIrYaml(yaml);
      expect(
        [for (final f in back.files) f.units],
        [
          <String>[],
          ['web'],
          ['mobile'],
          <String>[],
        ],
      );
    });
  });

  test('IRU3: an unknown unit and a lone --unit are usage errors', () async {
    final err = StringBuffer();
    expect(
      await runIrspecs(
        [
          'map',
          '--mapper',
          'dart-tom',
          '--ir',
          '.',
          '--out',
          '.',
          '--spec',
          _spec,
          '--unit',
          'nope',
        ],
        out: StringBuffer(),
        err: err,
      ),
      2,
    );
    expect(err.toString(), contains('declares no generation unit "nope"'));
    expect(
      await runIrspecs(
        [
          'map',
          '--mapper',
          'dart-tom',
          '--ir',
          '.',
          '--out',
          '.',
          '--unit',
          'x',
        ],
        out: StringBuffer(),
        err: StringBuffer(),
      ),
      2,
    );
  });
}
