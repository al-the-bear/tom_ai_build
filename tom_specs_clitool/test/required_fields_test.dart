/// The instance tier reports a `required` form field left empty in every form
/// the document holds (uamtc16): a member form inside a list item, a member
/// form outside any list, and a class-level form. Before, only the schema
/// tier checked, and only class-level forms of the rendition.
///
/// RF-1 runs over the real model on the full-model exercise sample, which
/// fills every required field: clearing one in each shape must produce exactly
/// one `missingRequiredField` at that form, and the untouched sample none.
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

  List<SpecValidationError> missing(SpecDocument doc) => [
    for (final e in validateDocument(somSpecModel, doc))
      if (e.code == SpecValidationCode.missingRequiredField) e,
  ];

  /// The first held form whose shape matches [test], that fills a required
  /// field and declares an optional one: the required field and the optional
  /// one (written when the required one is cleared, so the form stays held —
  /// an absent form is absence, not an incomplete form).
  (String, String, String) find(
    SpecDocument doc,
    bool Function(String path, SpecField form) test,
  ) {
    for (final path in doc.formPaths.toList()..sort()) {
      final form = refl.resolve(path)?.field;
      if (form == null || !test(path, form)) continue;
      final optional = form.formFields
          .where((ff) => !ff.required && ff.enumValues.isEmpty)
          .where((ff) => ff.type == 'String')
          .firstOrNull;
      if (optional == null) continue;
      for (final ff in form.formFields) {
        final v = doc.formField(path, ff.name);
        if (ff.required && v != null && v.trim().isNotEmpty) {
          return (path, ff.name, optional.name);
        }
      }
    }
    throw StateError('no matching form');
  }

  bool inListItem(SpecDocument doc, String path) => doc.listPaths.any(
    (l) => doc.listItems(l).any((item) => path.startsWith('$item/')),
  );

  test('RF-1: the untouched sample fills every required field', () {
    expect(missing(sample()), isEmpty);
  });

  for (final (name, shape)
      in <(String, bool Function(SpecDocument, String, SpecField))>[
        (
          'a member form in a list item',
          (d, p, f) => f.name != 'content' && inListItem(d, p),
        ),
        (
          'a member form outside any list',
          (d, p, f) => f.name != 'content' && !inListItem(d, p),
        ),
        ('a class-level form', (d, p, f) => f.name == 'content'),
      ]) {
    test('RF-1: an empty required field of $name is reported', () {
      final doc = sample();
      final (path, field, keep) = find(doc, (p, f) => shape(doc, p, f));
      doc.setFormField(path, keep, 'kept');
      doc.setFormField(path, field, '');
      final found = missing(doc);
      expect(found.map((e) => e.path), [path]);
      expect(found.single.message, contains('"$field"'));
    });
  }
}
