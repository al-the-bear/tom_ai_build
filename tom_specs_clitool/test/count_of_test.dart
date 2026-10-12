/// `Field.countOf` over the real object model: the stated counts of the
/// Solution Blueprint's `SYSCL` (scale) form are held to the entries the
/// document actually holds (vsctsa43).
///
/// The Meridian document states no count, so the test writes them: first
/// wrong, which the instance tier must report as `countMismatch`, then the
/// numbers the check itself reports, which must leave the document clean. That
/// round trip proves every target resolves and counts against the real model
/// rather than an empty set.
library;

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

void main() {
  final tree = buildSomMetaTree(somSpecModel, rootType: 'D00SolutionBlueprint');
  SpecDocument meridian() => SpecDocument.fromFile(
    '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
    tree,
  );
  final scalePath = tree.byId('SYSCL')!.path!;
  const counted = [
    'userCategoryCount',
    'externalInterfaceCount',
    'functionalRequirementCount',
    'nonFunctionalRequirementCount',
  ];

  List<SpecValidationError> countErrors(SpecDocument doc) => [
    for (final e in validateDocument(somSpecModel, doc))
      if (e.code == SpecValidationCode.countMismatch) e,
  ];

  test('the model declares the counts the scale form states', () {
    final form = somSpecModel
        .classNamed('SystemSummary')!
        .fields
        .firstWhere((f) => f.sectionId == 'SYSCL')
        .formFields;
    expect(
      {
        for (final f in form)
          if (f.countOf.isNotEmpty) f.name: f.countOf,
      },
      {
        'userCategoryCount': ['UCE'],
        'externalInterfaceCount': ['EIE'],
        'functionalRequirementCount': ['FRE'],
        'nonFunctionalRequirementCount': ['TERQ', 'SECRQ'],
      },
    );
  });

  test('a wrong count is reported, and the reported count is clean', () {
    final doc = meridian();
    expect(countErrors(doc), isEmpty, reason: 'no count stated yet');

    for (final f in counted) {
      doc.setFormField(scalePath, f, '9999');
    }
    final wrong = countErrors(doc);
    expect(wrong, hasLength(counted.length));
    expect(wrong.every((e) => e.path == scalePath), isTrue);

    // Write back the number each finding says the document holds.
    for (final e in wrong) {
      final field = RegExp(r'form field "(\w+)"').firstMatch(e.message)![1]!;
      final holds = RegExp(r'holds (\d+)').firstMatch(e.message)![1]!;
      doc.setFormField(scalePath, field, holds);
    }
    expect(countErrors(doc), isEmpty);
    // The real model counts real entries: the Blueprint holds requirements.
    expect(
      int.parse(doc.formField(scalePath, 'functionalRequirementCount')!),
      greaterThan(0),
    );
  });

  test('a count that is not a whole number is reported', () {
    final doc = meridian()
      ..setFormField(scalePath, 'functionalRequirementCount', 'about sixty');
    expect(countErrors(doc).single.message, contains('not a whole number'));
  });
}
