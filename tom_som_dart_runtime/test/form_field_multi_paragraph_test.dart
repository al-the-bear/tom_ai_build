// The `multiParagraph` flag of a form field (`Field.multiParagraph`): read
// from the model meta, carried into the meta tree, and shown as a chip. The
// renderer that acts on it comes later; this pins the plumbing.

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_display_fixture.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Every form field of every node under [node], depth first.
Iterable<SomFormFieldMeta> _formFields(SomMetaNode node) sync* {
  final form = node.form;
  if (form != null) yield* form.fields;
  for (final child in node.children) {
    yield* _formFields(child);
  }
  final element = node.elementNode;
  if (element != null) yield* _formFields(element);
}

void main() {
  test('MP1: the meta key is read, and absent means false', () {
    final flagged = FormFieldSpec.fromJson({
      'name': 'rationale',
      'label': 'Rationale',
      'type': 'String',
      'multiParagraph': true,
    });
    final plain = FormFieldSpec.fromJson({
      'name': 'title',
      'label': 'Title',
      'type': 'String',
    });
    expect(flagged.multiParagraph, isTrue);
    expect(plain.multiParagraph, isFalse);
  });

  test('MP2: the meta tree carries the flag onto SomFormFieldMeta', () {
    final model = showcaseModel();
    final tree = buildSomMetaTree(model, rootType: 'ShowcaseDoc');
    final fields = {for (final f in _formFields(tree.root)) f.name: f};
    expect(fields['rationale']?.multiParagraph, isTrue);
    expect(fields['kind']?.multiParagraph, isFalse);
  });

  test('MP3: a flagged field shows the paragraphs chip, a plain one none', () {
    final flagged = FormFieldSpec.fromJson({
      'name': 'rationale',
      'label': 'Rationale',
      'multiParagraph': true,
    });
    final plain = FormFieldSpec.fromJson({'name': 'title', 'label': 'Title'});
    expect(formFieldChips(flagged), [multiParagraphChip]);
    expect(formFieldChips(plain), isEmpty);
    expect(kRenderedAnnotations, contains('multiParagraph'));
  });
}
