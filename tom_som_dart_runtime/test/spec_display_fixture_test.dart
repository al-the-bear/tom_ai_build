// Guards the annotation-showcase fixture that both Flutter surfaces render
// against.
//
// The fixture is only a divergence guard while it stays complete: an annotation
// missing from it cannot fail either app's rendering test, so the guard would
// silently stop guarding. These tests pin completeness against
// `kRenderedAnnotations` and pin the three-state kind semantics the fixture is
// built to exercise.

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_display_fixture.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  final model = showcaseModel();

  Set<String> annotationNames() {
    final names = <String>{};
    for (final cls in model.classes.values) {
      names.addAll(cls.annotations.map((a) => a.name));
      for (final f in cls.fields) {
        names.addAll(f.annotations.map((a) => a.name));
      }
    }
    return names;
  }

  test('DF1: the fixture carries every annotation the display layer renders',
      () {
    expect(
      kRenderedAnnotations.difference(annotationNames()),
      isEmpty,
      reason: 'an annotation absent from the fixture cannot fail either app’s '
          'rendering test — add it to kAnnotationShowcaseJson',
    );
  });

  test('DF2: the fixture invents no annotation the display layer cannot show',
      () {
    expect(annotationNames().difference(kRenderedAnnotations), isEmpty);
  });

  test('DF3: the fixture spreads the three @CodeSpecKind states', () {
    final labels = expectedShowcaseChipLabels(model);
    expect(labels, contains('cs?'), reason: 'undeclared');
    expect(labels, contains('cs:none'), reason: 'declared as mapping to none');
    expect(labels, contains('cs:form'), reason: 'declared with a kind');
  });

  test('DF4: the fixture spreads both @FollowUpKind states', () {
    final labels = expectedShowcaseChipLabels(model);
    expect(labels, contains('fu:trn'));
    expect(labels, contains('fu:none'));
  });

  test('DF5: the fixture carries a partially covered closed choice', () {
    final labels = expectedShowcaseChipLabels(model);
    // Two of the three discriminator values are cased, so the group states both
    // the arithmetic and which value is still uncovered.
    expect(labels, contains('covers 2/3'));
    expect(labels, contains('uncovered: gamma'));
    expect(labels, contains('case:alpha'));
    expect(labels, contains('case:beta'));
  });

  test('DF6: the fixture carries the projection, unused and refs markers', () {
    final labels = expectedShowcaseChipLabels(model);
    expect(labels, contains(projectionChip.label));
    expect(labels, contains(unusedChip.label));
    expect(labels, contains(referencesChip.label));
  });

  test('DF7: the fixture carries the non-chip row extras', () {
    final doc = model.classNamed('ShowcaseDoc')!;
    final overview = doc.fields.firstWhere((f) => f.name == 'overview');
    final extras = SpecRowExtras.of(field: overview);
    expect(extras.headline, kShowcaseHeadline);
    expect(extras.comment, kShowcaseComment);
    expect(extras.serializationOrder, kShowcaseSerializationOrder);

    final items = doc.fields.firstWhere((f) => f.name == 'items');
    expect(SpecRowExtras.of(field: items).sectionIdPattern,
        kShowcaseSectionIdPattern);

    final provenance = doc.fields.firstWhere((f) => f.name == 'provenance');
    final refs = SpecRowExtras.of(field: provenance);
    expect(refs.reference, kShowcaseReference);
    expect(refs.standardReferences?.connotation, kShowcaseConnotation);
    expect(refs.standardReferences?.standards, contains(kShowcaseStandard));
  });

  test('DF8: the fixture carries the third routing verdict, and that row does '
      'not also read as unmapped', () {
    final labels = expectedShowcaseChipLabels(model);
    expect(labels, contains('na:overview'));

    final doc = model.classNamed('ShowcaseDoc')!;
    final overview = doc.fields.firstWhere((f) => f.name == 'chapterOverview');
    expect(overview.noArtifact?.note, kShowcaseNoArtifactNote);
    // `cs?` would say "nobody got round to routing this", which is the one
    // thing `@NoArtifact` exists to deny.
    expect(fieldChips(overview).map((c) => c.label), ['na:overview']);
  });
}
