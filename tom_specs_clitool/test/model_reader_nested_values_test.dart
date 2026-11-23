// The model reader's annotation values (model_reader.dart, `_serialize`) and
// the three section-automation keys of a `formFields[]` entry
// (model_json_exporter.dart), as `tom_specs_model_meta_schema.md` describes
// them:
//
// - NV-1 a map argument is a JSON object with string keys, an enum inside it
//   qualified;
// - NV-2 a constant object of a `tom_specs_core` class is a JSON object of its
//   fields in declaration order, defaults written and null fields left out;
// - NV-3 `@Form`'s `fields` argument keeps the empty list it has always had;
// - NV-4 an argument the reader cannot serialize stops the run, naming the
//   class, the member and the argument;
// - NV-5 the exporter writes `derivedFrom`, `inverseOf` and `summaryOf` after
//   `rankOf`, each only when stated, and the meta validator's round trip
//   holds with them.
//
// The reader cases run on a throwaway package under the workspace's ztmp/,
// resolved against the sibling `tom_specs_core`.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Reads [source] as the only model file of a fresh package.
Future<ModelReader> _read(Directory scratch, String source) async {
  final pkg = Directory(
    p.normalize(
      scratch.createTempSync('tom_specs_clitool_nested_values_').absolute.path,
    ),
  );
  addTearDown(() => pkg.deleteSync(recursive: true));
  Directory(p.join(pkg.path, 'lib', 'src')).createSync(recursive: true);
  File(p.join(pkg.path, 'lib', 'src', 'model.dart')).writeAsStringSync(source);
  final core = p.normalize(
    p.join(Directory.current.path, '..', 'tom_specs_core'),
  );
  Directory(p.join(pkg.path, '.dart_tool')).createSync();
  File(p.join(pkg.path, '.dart_tool', 'package_config.json')).writeAsStringSync(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        {
          'name': 'fixture',
          'rootUri': '../',
          'packageUri': 'lib/',
          'languageVersion': '3.10',
        },
        {
          'name': 'tom_specs_core',
          'rootUri': Uri.directory(core).toString(),
          'packageUri': 'lib/',
          'languageVersion': '3.10',
        },
      ],
    }),
  );
  final reader = ModelReader(createAnalysisDriver(pkg.path));
  await reader.analyzePackage(p.join(pkg.path, 'lib'));
  return reader;
}

const _holder = '''
import 'package:tom_specs_core/tom_specs_core.dart';

/// An annotation of the fixture, holding any value.
class Holder {
  const Holder(this.value);
  final Object? value;
}
''';

Map<String, Object?> _args(ModelReader r, String cls, String annotation) => r
    .classes[cls]!
    .annotations
    .firstWhere((a) => a.name == annotation)
    .arguments;

void main() {
  final scratch = Directory('../../../ztmp')..createSync(recursive: true);

  test(
    'NV-1: a map is a JSON object with string keys, enums qualified',
    () async {
      final r = await _read(scratch, '''
$_holder
@Holder({'kind': CodeSpecPart.validation, 'note': 'x', 'n': 2})
class MapCase {}
''');
      expect(_args(r, 'MapCase', 'Holder')['value'], {
        'kind': 'CodeSpecPart.validation',
        'note': 'x',
        'n': 2,
      });
    },
  );

  test('NV-2: a tom_specs_core object is its fields in declaration order, '
      'defaults written, nulls left out', () async {
    final r = await _read(scratch, '''
$_holder
@Holder([Field('owner', String, 'The owner', required: true)])
class ObjectCase {}
''');
    final list = _args(r, 'ObjectCase', 'Holder')['value'] as List;
    final field = list.single as Map<String, Object?>;
    expect(field.keys.toList(), [
      'name',
      'type',
      'description',
      'required',
      'refersTo',
      'countOf',
      'multiple',
      'productOf',
      'code',
      'multiParagraph',
    ]);
    expect(field['name'], 'owner');
    expect(field['type'], 'String');
    expect(field['required'], isTrue);
    expect(field['multiple'], isFalse);
    expect(field['refersTo'], isEmpty);
    expect(field.containsKey('hint'), isFalse, reason: 'null left out');
    expect(field.containsKey('rankOf'), isFalse, reason: 'null left out');
  });

  test("NV-3: @Form's fields argument stays the empty list", () async {
    final r = await _read(scratch, '''
import 'package:tom_specs_core/tom_specs_core.dart';

@Form([Field('owner', String, 'The owner')])
class FormCase {}
''');
    expect(_args(r, 'FormCase', 'Form')['fields'], isEmpty);
    expect(r.classes['FormCase']!.formFields.single.name, 'owner');
  });

  test('NV-4: an unserializable argument stops the run, named', () async {
    await expectLater(
      _read(scratch, '''
$_holder
class Foreign {
  const Foreign();
}

class BadCase {
  @Holder(Foreign())
  String? content;
}
'''),
      throwsA(
        isA<UnserializableAnnotationArgument>()
            .having((x) => x.className, 'className', 'BadCase')
            .having((x) => x.member, 'member', 'content')
            .having((x) => x.annotation, 'annotation', 'Holder')
            .having((x) => x.argument, 'argument', 'value')
            .having((x) => '$x', 'message', contains('Foreign')),
      ),
    );
    await expectLater(
      _read(scratch, '''
$_holder
class Foreign {
  const Foreign();
}

@Holder({'a': [Foreign()]})
class NestedBad {}
'''),
      throwsA(
        isA<UnserializableAnnotationArgument>()
            .having((x) => x.member, 'member', 'NestedBad')
            .having((x) => x.argument, 'argument', 'value.a'),
      ),
    );
  });

  group('NV-5: the three form-field keys', () {
    final fields = [
      FormFieldInfo(
        name: 'total',
        typeName: 'int',
        rankOf: 'weight',
        derivedFrom: const {
          'kind': 'rows',
          'source': 'RQDEP-ITEM-LST',
          'map': {'a': 'b'},
        },
        code: true,
      ),
      FormFieldInfo(
        name: 'peers',
        typeName: 'String',
        inverseOf: const {
          'fields': ['@self'],
        },
      ),
      FormFieldInfo(
        name: 'list',
        typeName: 'String',
        summaryOf: const {
          'detail': 'FRE-REQU-LST',
          'document': 'D04RequirementsSpecification',
          'relation': 'subset',
          'repeats': {'id': 'ref'},
        },
      ),
      FormFieldInfo(name: 'plain', typeName: 'String'),
    ];
    ModelClass model() => ModelClass(
      name: 'Doc',
      annotations: [
        AnnotationData('SectionId', {'id': 'DOC'}),
      ],
      fields: [
        ModelField(
          name: 'details',
          typeName: 'String',
          annotations: [
            AnnotationData('SectionId', {'id': 'DOC-DET'}),
            AnnotationData('Form', {'fields': <Object?>[]}),
          ],
          formFields: fields,
        ),
      ],
    );
    Map<String, Object?> export() => ModelJsonExporter(
      {'Doc': model()},
      modelVersion: 1,
      modelVersionLabel: '1.0.0',
    ).export();
    Map<String, Map<String, Object?>> byName(Map<String, Object?> json) {
      final cls = (json['classes'] as Map)['Doc'] as Map;
      final details = (cls['fields'] as List).cast<Map>().firstWhere(
        (f) => f['name'] == 'details',
      );
      return {
        for (final f in (details['formFields'] as List).cast<Map>())
          f['name'] as String: f.cast<String, Object?>(),
      };
    }

    test('each written as stated, after rankOf, absent when not', () {
      final f = byName(export());
      expect(f['total']!['derivedFrom'], {
        'kind': 'rows',
        'source': 'RQDEP-ITEM-LST',
        'map': {'a': 'b'},
      });
      final keys = f['total']!.keys.toList();
      expect(keys.indexOf('derivedFrom'), keys.indexOf('rankOf') + 1);
      expect(keys.indexOf('code'), greaterThan(keys.indexOf('derivedFrom')));
      expect(f['peers']!['inverseOf'], {
        'fields': ['@self'],
      });
      expect(f['list']!['summaryOf'], containsPair('relation', 'subset'));
      for (final k in ['derivedFrom', 'inverseOf', 'summaryOf']) {
        expect(f['plain']!.containsKey(k), isFalse, reason: k);
      }
    });

    test("the meta validator's round trip holds", () {
      final meta = export();
      meta['modelHash'] = specModelContentHash(meta);
      final again = jsonDecode(jsonEncode(meta)) as Map<String, Object?>;
      expect(validateSpecModelMeta(again), isEmpty);
      expect(specModelContentHash(again), meta['modelHash']);
      expect(byName(again)['total']!['derivedFrom'], isA<Map>());
    });
  });
}
