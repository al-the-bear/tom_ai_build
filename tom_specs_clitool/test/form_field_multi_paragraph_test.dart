/// `Field(..., multiParagraph: true)` (`tom_specs_core`): a form field whose
/// values hold paragraphs or blocks. The exporter writes it as
/// `"multiParagraph": true` on the `formFields[]` entry and omits it when false
/// (`tom_specs_model_meta_schema.md`); the meta tree carries it the same way.
library;

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final List<FormFieldInfo> _fields = [
  FormFieldInfo(name: 'title', typeName: 'String'),
  FormFieldInfo(name: 'rationale', typeName: 'String', multiParagraph: true),
];

ModelClass _policy() => ModelClass(
  name: 'Policy',
  annotations: [
    AnnotationData('SectionId', {'id': 'POL'}),
  ],
  fields: [
    ModelField(
      name: 'terms',
      typeName: 'String',
      annotations: [
        AnnotationData('SectionId', {'id': 'POL-TRM'}),
        AnnotationData('Form', {}),
      ],
      formFields: _fields,
    ),
  ],
);

void main() {
  test('MPX1: the export writes multiParagraph only where it is true', () {
    final json = ModelJsonExporter(
      {'Policy': _policy()},
      modelVersion: 1,
      modelVersionLabel: '1.0.0',
    ).export();
    final classes = json['classes'] as Map<String, Object?>;
    final fields =
        ((classes['Policy'] as Map<String, Object?>)['fields'] as List)
            .cast<Map<String, Object?>>();
    final terms = fields.firstWhere((f) => f['name'] == 'terms');
    final formFields = (terms['formFields'] as List)
        .cast<Map<String, Object?>>();
    final byName = {for (final f in formFields) f['name']: f};
    expect(byName['rationale']!['multiParagraph'], isTrue);
    expect(byName['title']!.containsKey('multiParagraph'), isFalse);
  });

  test('MPX2: the meta tree carries the flag and writes it the same way', () {
    final root = MetaTreeBuilder({'Policy': _policy()}).build('Policy');
    final terms = root.children.firstWhere((c) => c.memberName == 'terms');
    final byName = {for (final f in terms.form!.fields) f.name: f};
    expect(byName['rationale']!.multiParagraph, isTrue);
    expect(byName['title']!.multiParagraph, isFalse);
    final json = (terms.toJson()['form'] as Map)['fields'] as List;
    final written = {for (final f in json.cast<Map>()) f['name']: f};
    expect(written['rationale']!['multiParagraph'], isTrue);
    expect(written['title']!.containsKey('multiParagraph'), isFalse);
  });
}
