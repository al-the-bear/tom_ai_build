/// `validate_spec`: one project's document on all three tiers.
///
/// The clean subject is the Meridian Solution Blueprint shipped with
/// `tom_som_dart_v0`; each failing case is a copy broken in exactly one tier's
/// way, and every one of the model's fourteen roots is detected and run.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_schemas.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final String _meridian = p.normalize(
  p.absolute(
    '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
  ),
);

final Directory _tmp = Directory(p.join('.dart_tool', 'test_tmp', 'vsctsa41'));

String _write(String name, String text) {
  _tmp.createSync(recursive: true);
  final f = File(p.join(_tmp.path, name))..writeAsStringSync(text);
  return f.path;
}

Future<(int, String, String)> _run(List<String> args) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = await runValidateSpec(args, out: out, err: err);
  return (code, '$out', '$err');
}

Future<Map<String, dynamic>> _json(List<String> args, {int? exit}) async {
  final (code, out, err) = await _run([...args, '--json']);
  if (exit != null) expect(code, exit, reason: err);
  return jsonDecode(out) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _violations(
  Map<String, dynamic> json,
  String tier,
) => [
  for (final v in (json['violations'] as List).cast<Map<String, dynamic>>())
    if (v['tier'] == tier) v,
];

void main() {
  test('the Meridian Blueprint is clean on all three tiers', () async {
    final json = await _json([_meridian], exit: 0);
    expect(json['format'], kSpecValidationFormat);
    expect(json['passed'], isTrue);
    expect(json['root'], {
      'type': 'D00SolutionBlueprint',
      'sectionId': 'SBP',
      'title': 'Solution Blueprint',
      'schemaId': 'solution-blueprint',
    });
    expect(
      [for (final t in json['tiers'] as List) (t as Map)['ran']],
      [true, true, true],
    );
  });

  test('the text report names each tier and exits 0', () async {
    final (code, out, _) = await _run([_meridian]);
    expect(code, 0);
    expect(out, contains('decode   0 finding(s)'));
    expect(out, contains('schema   0 finding(s)'));
    expect(out, contains('instance 0 finding(s)'));
  });

  test('--markdown-out writes the rendition, and the rendition reads back '
      'with its root detected from the title', () async {
    final md = p.join(_tmp.path, 'meridian.md');
    _tmp.createSync(recursive: true);
    final (code, _, _) = await _run([_meridian, '--markdown-out', md]);
    expect(code, 0);
    final json = await _json([md]);
    expect((json['root'] as Map)['type'], 'D00SolutionBlueprint');
    expect(_violations(json, 'decode'), isEmpty);
    expect(_violations(json, 'schema'), isEmpty);
  });

  test('decode: a key the model does not have fails, and the other tiers '
      'are reported not run', () async {
    final text = File(_meridian).readAsStringSync().replaceFirst(
      '    DOCTL documentControl:',
      '    NOPE notAMember:\n      content: x\n    DOCTL documentControl:',
    );
    final json = await _json([
      _write('bad_decode.docspecs.yaml', text),
    ], exit: 1);
    expect(_violations(json, 'decode'), isNotEmpty);
    expect(
      [for (final n in json['notRun'] as List) (n as Map)['tier']],
      ['schema', 'instance'],
    );
  });

  test('schema: a required form field removed fails completeness, which '
      'the instance tier cannot see', () async {
    // Every entity's `aggregateRoot` (DAENT-CLAS) removed, key and value.
    final text = File(_meridian).readAsStringSync().replaceAll(
      RegExp(r'\n( *)aggregateRoot: \|2-\n\1  [^\n]*'),
      '',
    );
    final json = await _json([
      _write('no_aggregate.docspecs.yaml', text),
    ], exit: 1);
    expect(_violations(json, 'decode'), isEmpty);
    final schema = _violations(json, 'schema');
    expect(schema, isNotEmpty);
    expect(schema.first['code'], 'missingRequiredField');
    expect(schema.first['location'], 'DAENT-CLAS');
    expect(_violations(json, 'instance'), isEmpty);
  });

  test('instance: a reference to no registry entry fails, which the schema '
      'tier cannot see', () async {
    final text = File(_meridian).readAsStringSync().replaceFirstMapped(
      RegExp(r'(\n( *)boundedContext: \|2-\n\2  )[^\n]*'),
      (m) => '${m[1]}NoSuchContext',
    );
    final json = await _json([_write('bad_ref.docspecs.yaml', text)], exit: 1);
    expect(_violations(json, 'decode'), isEmpty);
    expect(_violations(json, 'schema'), isEmpty);
    final instance = _violations(json, 'instance');
    expect(instance.single['code'], 'danglingReference');
  });

  test('every root of the model is detected, has its schema, and runs all '
      'three tiers', () async {
    expect(somSpecModel.roots, hasLength(14));
    for (final root in somSpecModel.roots) {
      final text =
          'version: 2\n'
          'document:\n'
          '  ${root.sectionId} ${root.type}:\n'
          '    content: "A ${root.title}."\n';
      final json = await _json([
        _write('${root.sectionId}.docspecs.yaml', text),
      ]);
      expect(
        (json['root'] as Map)['type'],
        root.type,
        reason: 'root of ${root.sectionId}',
      );
      expect(
        somDocSpecsSchemaIds,
        contains(specSchemaIdFor(root)),
        reason: '${root.type} has no shipped schema',
      );
      expect(json['notRun'], isEmpty, reason: '${root.type}: $json');
      expect(_violations(json, 'decode'), isEmpty, reason: root.type);
    }
  });

  group('usage', () {
    test('--root overrides detection; an unknown root is exit 2', () async {
      final json = await _json([_meridian, '--root', 'SBP'], exit: 0);
      expect((json['root'] as Map)['type'], 'D00SolutionBlueprint');
      final (code, _, err) = await _run([_meridian, '--root', 'NOPE']);
      expect(code, 2);
      expect(err, contains('names no root'));
    });

    test('no document, or a missing one, is exit 2', () async {
      expect((await _run([])).$1, 2);
      expect((await _run(['no_such.docspecs.yaml'])).$1, 2);
    });
  });
}
