/// A class-level `@Form` structures the class's `content` member.
///
/// `tom_specs_model_rules.md` §5.3: "`@Form` classes replace the free content
/// with `FieldName: value` lines". The schema generator always honoured that
/// (it gives such a section an `<id>-form` format), but the model JSON export
/// did not: it wrote `content` as plain text, so all nine runtimes, which are
/// generated from that export, saw no form, and no document could satisfy both
/// the schema tier and the instance tier. Found authoring tom_uam's Solution
/// Blueprint, on eleven of the 73 classes that carry a class-level `@Form`.
library;

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

ModelClass _formClass({List<FormFieldInfo> fieldLevel = const []}) =>
    ModelClass(
      name: 'Policy',
      annotations: [
        AnnotationData('SectionId', {'id': 'POL'}),
        AnnotationData('Form', {}),
      ],
      formFields: [
        FormFieldInfo(name: 'owner', typeName: 'String', required: true),
        FormFieldInfo(name: 'review', typeName: 'String'),
      ],
      fields: [
        ModelField(name: 'content', typeName: 'String', formFields: fieldLevel),
        ModelField(name: 'notes', typeName: 'String'),
      ],
    );

Map<String, Object?> _field(ModelClass cls, String name) {
  final json = ModelJsonExporter(
    {cls.name: cls},
    modelVersion: 1,
    modelVersionLabel: '1.0.0',
  ).export();
  final classes = json['classes'] as Map<String, Object?>;
  final fields = (classes[cls.name] as Map<String, Object?>)['fields'] as List;
  return fields.cast<Map<String, Object?>>().firstWhere(
    (f) => f['name'] == name,
  );
}

void main() {
  test('the class-level form becomes the content member\'s form', () {
    final content = _field(_formClass(), 'content');
    expect(content['kind'], 'form');
    final formFields = (content['formFields'] as List)
        .cast<Map<String, Object?>>();
    expect(formFields.map((f) => f['name']), ['owner', 'review']);
    expect(formFields.first['required'], isTrue);
  });

  test(
    'only the content member takes it; other members stay what they are',
    () {
      expect(_field(_formClass(), 'notes')['kind'], 'content');
    },
  );

  test('a field-level @Form on content wins over the class-level one', () {
    final cls = _formClass(
      fieldLevel: [FormFieldInfo(name: 'own', typeName: 'String')],
    );
    final formFields = (_field(cls, 'content')['formFields'] as List)
        .cast<Map<String, Object?>>();
    expect(formFields.map((f) => f['name']), ['own']);
  });
}
