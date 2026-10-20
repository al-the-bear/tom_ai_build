import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

SpecSection _section(String text) => SpecSection(
  index: 0,
  lineNumber: 1,
  rawHeadline: '## Header',
  name: 'Header',
  id: 'HDR',
  text: text,
);

void main() {
  group('review annotations in form text (SOM §11.9.4)', () {
    test('FAN-1: blocks in the preamble leave the field values alone', () {
      final plain = _section('Author: Alice\nReviewer: Bob');
      final annotated = _section(
        '> **❓ Open questions on these fields**\n>\n'
        '> **❓ BQ-1 — Reviewer:** who reviews?\n>\n'
        '> **Answer:** Bob\n\n'
        '> ⬆️ **C-1** (Alexis): Name the author too.\n\n'
        'Author: Alice\nReviewer: Bob',
      );
      expect(annotated.formFields, plain.formFields);
      expect(annotated.preamble, contains('BQ-1'));
      expect(annotated.preamble, contains('C-1'));
      expect(annotated.misplacedAnnotations, isEmpty);
    });

    test('FAN-2: a block after the last field is neither value nor '
        'preamble, and is reported', () {
      final s = _section(
        'Author: Alice\nReviewer: Bob\n\n'
        '> ⬆️ (Alexis): after the last field\n> second line',
      );
      expect(s.formFields, {'author': 'Alice', 'reviewer': 'Bob'});
      expect(s.preamble, isNull);
      expect(s.misplacedAnnotations, [
        '> ⬆️ (Alexis): after the last field\n> second line',
      ]);
    });

    test('FAN-3: a block between two fields ends the first field', () {
      final s = _section(
        'Author: Alice\n> **❓ BQ-2 — Author:** full name?\n'
        '> **Answer:**\nReviewer: Bob',
      );
      expect(s.formFields, {'author': 'Alice', 'reviewer': 'Bob'});
      expect(s.misplacedAnnotations, hasLength(1));
    });

    test('FAN-4: an inline mark in a field value is part of the value', () {
      final s = _section('Author: Alice {++ Smith ++}\nReviewer: Bob');
      expect(s.getFormField('author'), 'Alice {++ Smith ++}');
    });

    test('FAN-5: a plain quote after the fields is unaffected', () {
      final s = _section('Author: Alice\n> a quoted line');
      expect(s.getFormField('author'), 'Alice\n> a quoted line');
      expect(s.misplacedAnnotations, isEmpty);
    });
  });
}
