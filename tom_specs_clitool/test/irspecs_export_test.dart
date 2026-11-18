/// The JSON export of the IR (`irspecs_ir.md` §15): the Meridian IR written
/// as YAML, exported through `irspecs export --format json`, every file valid
/// against `tool/irspecs_ir.schema.json` and read back to the records of its
/// YAML document.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';
import 'package:yaml/yaml.dart';


final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);

IrAreaIndex _index() => IrAreaIndex(
  CodeSpecsAreaCatalog.fromJson(
    jsonDecode(File(_areas).readAsStringSync()) as Map<String, dynamic>,
  ),
);

void main() {
  late Directory scratch;
  late String ir;
  late String out;
  late String stdoutText;
  final schema = JsonSchema.create(
    jsonDecode(File('tool/irspecs_ir.schema.json').readAsStringSync()),
  );

  setUpAll(() async {
    scratch = Directory.systemTemp.createTempSync('irspecs_export');
    ir = p.join(scratch.path, 'irspecs');
    out = p.join(scratch.path, 'json');
    final made = await runIrspecs([
      'from-codespecs',
      for (final locus in ['shared', 'client', 'server']) ...[
        '--$locus',
        p.join(_meridian, 'meridian_codespec_$locus'),
      ],
      '--areas',
      _areas,
      '--out',
      ir,
    ], out: StringBuffer());
    expect(made, 0);
    final buffer = StringBuffer();
    final err = StringBuffer();
    final code = await runIrspecs(
      ['export', '--format', 'json', '--ir', ir, '--out', out],
      out: buffer,
      err: err,
    );
    expect(code, 0, reason: '$err');
    stdoutText = '$buffer';
  });
  tearDownAll(() => scratch.deleteSync(recursive: true));

  List<String> yamlNames() => [
    for (final f in Directory(ir).listSync().whereType<File>())
      if (f.path.endsWith('.ir.yaml')) p.basename(f.path),
  ]..sort();

  test('IREX1: one .ir.json per .ir.yaml, named like it', () {
    final names = [
      for (final f in Directory(out).listSync().whereType<File>())
        p.basename(f.path),
    ]..sort();
    expect(yamlNames(), contains('CE-DB_data_access.ir.yaml'));
    expect(names, [for (final n in yamlNames()) irJsonFileName(n)]..sort());
    expect(names, contains('CE-DB_data_access.ir.json'));
    expect(stdoutText, contains('CE-DB_data_access.ir.json'));
    expect(stdoutText, contains('new'));
  });

  test('IREX2: every file validates against the IR schema', () {
    for (final f in Directory(out).listSync().whereType<File>()) {
      final result = schema.validate(jsonDecode(f.readAsStringSync()));
      expect(
        result.isValid,
        isTrue,
        reason: '${p.basename(f.path)}: ${result.errors.join('\n')}',
      );
    }
  });

  test('IREX3: lossless — each file holds the data of its YAML document and '
      'reads back to the same records', () {
    for (final name in yamlNames()) {
      final yamlText = File(p.join(ir, name)).readAsStringSync();
      final jsonText = File(
        p.join(out, irJsonFileName(name)),
      ).readAsStringSync();
      // The same data, key for key and in the same order.
      final jsonData = jsonDecode(jsonText);
      final yamlData = plainYaml(loadYaml(yamlText));
      expect(jsonData, yamlData, reason: name);
      expect(
        jsonEncode(jsonData),
        jsonEncode(yamlData),
        reason: '$name: key order',
      );
      // The same records: written back, the YAML is byte for byte the same.
      final fromJson = readIrJson(jsonText, source: name);
      expect(writeIrYaml(fromJson), yamlText, reason: name);
      expect(writeIrJson(fromJson), jsonText, reason: name);
    }
  });

  test('IREX4: a second export leaves every file unchanged, and an export '
      'the IR no longer produces is deleted', () async {
    File(p.join(out, 'CE-XX_gone.ir.json')).writeAsStringSync('{}');
    final buffer = StringBuffer();
    expect(
      await runIrspecs([
        'export',
        '--format',
        'json',
        '--ir',
        ir,
        '--out',
        out,
      ], out: buffer),
      0,
    );
    expect('$buffer', isNot(contains(' new,')));
    expect('$buffer', isNot(contains(' changed,')));
    expect('$buffer', contains('CE-XX_gone.ir.json'));
    expect(File(p.join(out, 'CE-XX_gone.ir.json')).existsSync(), isFalse);
  });

  test('IREX5: bad usage is refused with exit 2', () async {
    Future<String> refused(List<String> args) async {
      final err = StringBuffer();
      expect(
        await runIrspecs(args, err: err),
        2,
        reason: args.join(' '),
      );
      return '$err';
    }

    expect(
      await refused(['export', '--ir', ir, '--out', out]),
      contains('Missing --format'),
    );
    expect(
      await refused(['export', '--format', 'yaml', '--ir', ir, '--out', out]),
      contains('"yaml" is not an allowed value'),
    );
    expect(
      await refused([
        'export',
        '--format',
        'json',
        '--ir',
        ir,
        '--out',
        out,
        '--areas',
        _areas,
      ]),
      contains('export takes no --areas'),
    );
    expect(
      await refused([
        'export',
        '--format',
        'json',
        '--ir',
        p.join(scratch.path, 'none'),
        '--out',
        out,
      ]),
      contains('IR folder not found'),
    );
  });

  test('IREX6: readIrJson refuses text that is not JSON', () {
    expect(
      () => readIrJson('not json', source: 'x.ir.json'),
      throwsA(isA<IrSpecsException>()),
    );
    expect(_index().fileNameOf('CE-DB'), 'CE-DB_data_access.ir.yaml');
  });
}
