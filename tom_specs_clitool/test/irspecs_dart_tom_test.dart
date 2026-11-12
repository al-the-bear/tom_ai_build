/// The Dart + Tom mapper (`irspecs_ir.md` §7): trio → IR → trio is byte-equal
/// on both Meridian trios, and the reproduced trio passes validate_codespecs.
///
/// A difference here is a fact the IR does not carry — fixed in the IR and its
/// specification, never by a special case in the mapper.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

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

List<IrDocument> _ir(List<String> roots) {
  CsLocusProject read(CsLocus locus, String root) =>
      readCsLocusProjectFromDirectory(
        locus: locus,
        packageName: p.basename(root),
        root: root,
      );
  final documents = irFromCsModel(
    shared: read(CsLocus.shared, roots[0]),
    client: read(CsLocus.client, roots[1]),
    server: read(CsLocus.server, roots[2]),
    areas: IrAreaIndex(
      CodeSpecsAreaCatalog.fromJson(
        jsonDecode(File(_areasJson).readAsStringSync()) as Map<String, dynamic>,
      ),
    ),
  );
  // Through the file form, so the test proves what a document holds.
  return [for (final d in documents) readIrYaml(writeIrYaml(d))];
}

/// Every `.dart` file under each root's `lib/`, `<package>/<path>` → text.
Map<String, String> _sources(List<String> roots) => {
  for (final root in roots)
    if (Directory(p.join(root, 'lib')).existsSync())
      for (final f in Directory(
        p.join(root, 'lib'),
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          '${p.basename(root)}/'
              '${p.split(p.relative(f.path, from: root)).join('/')}': f
              .readAsStringSync(),
};

void main() {
  for (final MapEntry(key: name, value: roots) in _trios.entries) {
    group('IRDT1 ($name): trio → IR → trio', () {
      late Directory out;
      late Map<String, String> original;
      late Map<String, String> mapped;

      setUpAll(() async {
        out = Directory.systemTemp.createTempSync('irspecs_dart_tom');
        await writeDartTom(_ir(roots), out.path);
        original = _sources(roots);
        mapped = {
          for (final f in out.listSync(recursive: true).whereType<File>())
            p.split(p.relative(f.path, from: out.path)).join('/'): f
                .readAsStringSync(),
        };
      });
      tearDownAll(() => out.deleteSync(recursive: true));

      test('the same files', () {
        expect(mapped.keys.toList()..sort(), original.keys.toList()..sort());
      });

      test('every file byte for byte', () {
        final differing = [
          for (final key in original.keys)
            if (mapped[key] != original[key]) key,
        ];
        expect(
          differing,
          isEmpty,
          reason: differing.isEmpty
              ? null
              : 'first difference in ${differing.first}:\n'
                    '${_firstDifference(original[differing.first]!, mapped[differing.first] ?? '')}',
        );
      });

      test('the reproduced trio passes validate_codespecs', () async {
        final code = await runValidateCodespecs(
          [
            for (final (i, locus) in [
              'shared',
              'client',
              'server',
            ].indexed) ...['--$locus', p.join(out.path, p.basename(roots[i]))],
          ],
          out: StringBuffer(),
          err: StringBuffer(),
        );
        final originalCode = await runValidateCodespecs(
          [
            for (final (i, locus) in [
              'shared',
              'client',
              'server',
            ].indexed) ...['--$locus', roots[i]],
          ],
          out: StringBuffer(),
          err: StringBuffer(),
        );
        expect(code, originalCode);
        expect(code, 0);
      });
    });
  }

  test(
    'IRDT3: irspecs from-codespecs, then irspecs map, gives the trio',
    () async {
      final roots = _trios['meridian_codespecs']!;
      final work = Directory.systemTemp.createTempSync('irspecs_map_cli');
      addTearDown(() => work.deleteSync(recursive: true));
      final ir = p.join(work.path, 'irspecs');
      final code = p.join(work.path, 'code');
      expect(
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
          ir,
        ], out: StringBuffer()),
        0,
      );
      final out = StringBuffer();
      expect(
        await runIrspecs([
          'map',
          '--mapper',
          'dart-tom',
          '--ir',
          ir,
          '--out',
          code,
        ], out: out),
        0,
      );
      final original = _sources(roots);
      expect('$out', contains('${original.length} file(s)'));
      for (final MapEntry(key: key, value: text) in original.entries) {
        expect(
          File(p.joinAll([code, ...key.split('/')])).readAsStringSync(),
          text,
          reason: key,
        );
      }
      final err = StringBuffer();
      expect(await runIrspecs(['map', '--ir', ir], err: err), 2);
      expect('$err', contains('--mapper'));
    },
  );

  group('IRDT2: what the mapper refuses', () {
    test('a construct it has no rule for is refused, not approximated', () {
      final project = readCsLocusProject(
        locus: CsLocus.shared,
        packageName: 's',
        sources: {'lib/src/x.dart': 'mixin M {}\n'},
      );
      CsLocusProject empty(CsLocus l) =>
          readCsLocusProject(locus: l, packageName: l.name, sources: {});
      final documents = irFromCsModel(
        shared: project,
        client: empty(CsLocus.client),
        server: empty(CsLocus.server),
        areas: IrAreaIndex(
          CodeSpecsAreaCatalog.fromJson(
            jsonDecode(File(_areasJson).readAsStringSync())
                as Map<String, dynamic>,
          ),
        ),
      );
      expect(() => mapDartTom(documents), throwsA(isA<IrMapException>()));
    });
  });
}

String _firstDifference(String a, String b) {
  final al = a.split('\n');
  final bl = b.split('\n');
  for (var i = 0; i < al.length || i < bl.length; i++) {
    final x = i < al.length ? al[i] : '<end>';
    final y = i < bl.length ? bl[i] : '<end>';
    if (x != y) return 'line ${i + 1}\n  expected: $x\n  mapped:   $y';
  }
  return '(identical)';
}
