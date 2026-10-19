/// `Field.productOf` / `Field.rankOf` and `./`-scoped `countOf` over the real
/// object model (uamtc10), on the full-model exercise sample, which holds a
/// key risk with an analysis form and a use case with steps.
///
/// Each case writes a wrong value first — which the instance tier must report —
/// and then the right one, which must leave the document clean, so the check
/// is proven to resolve its operands against the real model rather than to
/// skip them.
library;

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

void main() {
  final tree = buildSomMetaTree(somSpecModel, rootType: 'D00SolutionBlueprint');
  final refl = SpecReflection(somSpecModel);
  SpecDocument sample() => SpecDocument.fromFile(
    '../tom_som_conformance/samples/exercise_full_model.docspecs.yaml',
    tree,
  );

  List<SpecValidationError> findings(
    SpecDocument doc,
    SpecValidationCode code,
    String path,
  ) => [
    for (final e in validateDocument(somSpecModel, doc))
      if (e.code == code && e.path == path) e,
  ];

  /// The form member [member] of the first list item of class [classId].
  String formOf(SpecDocument doc, String classId, String member) {
    for (final list in doc.listPaths.toList()..sort()) {
      for (final item in doc.listItems(list)) {
        if (refl.resolve(item)?.targetClass?.sectionId == classId) {
          final path = '$item/$member';
          expect(refl.resolve(path)?.kind, SpecNodeKind.form, reason: path);
          return path;
        }
      }
    }
    throw StateError('the sample holds no $classId entry');
  }

  test('DV-1: a key risk score is probabilityValue × impactValue', () {
    final doc = sample();
    final rian = formOf(doc, 'RISENT', 'RIAN');
    doc.setFormField(rian, 'probabilityValue', '0.7');
    doc.setFormField(rian, 'impactValue', '4');
    doc.setFormField(rian, 'riskScore', '2.9');
    expect(
      findings(doc, SpecValidationCode.derivedValueMismatch, rian),
      hasLength(1),
    );
    doc.setFormField(rian, 'riskScore', '2.8');
    expect(
      findings(doc, SpecValidationCode.derivedValueMismatch, rian),
      isEmpty,
    );
  });

  test('DV-2: a lone ranked risk must rank 1', () {
    final doc = sample();
    final rian = formOf(doc, 'RISENT', 'RIAN');
    doc.setFormField(rian, 'riskScore', '2');
    doc.setFormField(rian, 'riskRanking', '2');
    final ranked = [
      for (final p in doc.formPaths)
        if (refl.resolve(p)?.field?.sectionId == 'RIAN' &&
            (doc.formField(p, 'riskRanking') ?? '').isNotEmpty &&
            (doc.formField(p, 'riskScore') ?? '').isNotEmpty)
          p,
    ];
    expect(ranked, [rian], reason: 'the sample ranks one risk');
    expect(
      findings(doc, SpecValidationCode.derivedValueMismatch, rian),
      hasLength(1),
    );
    doc.setFormField(rian, 'riskRanking', '1');
    expect(
      findings(doc, SpecValidationCode.derivedValueMismatch, rian),
      isEmpty,
    );
  });

  test("DV-3: a scenario's stepCount counts its own steps (./MNSST)", () {
    final doc = sample();
    final step = formOf(doc, 'MNSST', 'content');
    final owner = step.substring(0, step.indexOf('/MNSST-STEP-LST'));
    final form = '$owner/content';
    expect(refl.resolve(form)?.kind, SpecNodeKind.form);
    final own = [
      for (final list in doc.listPaths)
        if (list.startsWith('$owner/'))
          for (final item in doc.listItems(list))
            if (refl.resolve(item)?.targetClass?.sectionId == 'MNSST') item,
    ].length;
    expect(own, greaterThan(0));
    doc.setFormField(form, 'stepCount', '${own + 1}');
    expect(findings(doc, SpecValidationCode.countMismatch, form), hasLength(1));
    doc.setFormField(form, 'stepCount', '$own');
    expect(findings(doc, SpecValidationCode.countMismatch, form), isEmpty);
  });
}
