import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final model = fixtureModel();

  test('a well-formed document validates clean', () {
    final doc = SpecDocument();
    doc.setContent('PD00/vision', 'idea');
    doc.setFormField('PD00/owner', 'name', 'Ada');
    final r1 = doc.addListItem('PD00/risks');
    final r2 = doc.addListItem('PD00/risks');
    doc.setContent('$r1/title', 'first');
    doc.setContent('$r2/title', 'second');
    expect(validateDocument(model, doc), isEmpty);
  });

  test('a dangling content path is reported', () {
    final doc = SpecDocument()..setContent('PD00/ghost', 'x');
    final errors = validateDocument(model, doc);
    expect(errors, hasLength(1));
    expect(errors.single.code, SpecValidationCode.danglingPath);
    expect(errors.single.path, 'PD00/ghost');
  });

  test('an unknown form field is reported', () {
    final doc = SpecDocument()..setFormField('PD00/owner', 'phone', '123');
    final errors = validateDocument(model, doc);
    expect(errors, hasLength(1));
    expect(errors.single.code, SpecValidationCode.unknownFormField);
  });

  test('a populated list below its @Min is reported', () {
    final doc = SpecDocument();
    doc.addListItem('PD00/risks'); // 1 item, min is 2
    final errors = validateDocument(model, doc);
    expect(
      errors.where((e) => e.code == SpecValidationCode.minItems),
      hasLength(1),
    );
  });

  test('a value written where a list is expected is a kind mismatch', () {
    final doc = SpecDocument()..setContent('PD00/risks', 'oops');
    final errors = validateDocument(model, doc);
    expect(errors.single.code, SpecValidationCode.kindMismatch);
  });
}
