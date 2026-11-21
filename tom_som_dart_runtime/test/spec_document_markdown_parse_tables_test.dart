// The parse of the Markdown layout (SOM §11.4, §11.5): `parse(emit(doc))`
// stages exactly the document's values and `emit(parse(emit(doc)))` is
// byte-identical — form tables, section tables, a record table and a
// reference line included; and the older `Field:`-line layout, which is no
// longer emitted, parses to the same document (the two corpus goldens). The
// single forms and their rejections are pinned case by case in the
// conformance corpus (`markdown_import_cases.json`, the `readingView` cases).

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  // Copies of the conformance corpus files, kept inside this package because
  // `test/` ships (tom_som_conformance/tool/check_corpus_copies.dart holds
  // them equal to the originals).
  const corpus = 'test/fixtures/corpus';
  final model = SpecModel.fromJson(
    jsonDecode(File('$corpus/model.meta.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  /// The corpus document plus a registry entry and a reference list, so the
  /// tables layout writes every form: form tables, section tables, the
  /// records table of `CARD-LST` and the reference line of `RGR-LST`.
  SpecDocument document() {
    final doc = SpecDocument()
      ..loadJson(
        jsonDecode(File('$corpus/state.json').readAsStringSync())
            as Map<String, dynamic>,
      );
    final entry = doc.addListItem('DEMO/REG/RGE-LST', sectionId: 'RGE-ALPHA');
    doc.setFormField('$entry/RGE-DET', 'code', 'ALPHA');
    var n = 0;
    for (final id in ['RGE-ALPHA', 'RGE-BETA']) {
      final item = doc.addListItem('DEMO/REG/RGR-LST', sectionId: 'RGR-${++n}');
      doc.setFormField('$item/RGR-REF', 'ref', id);
    }
    return doc;
  }

  String emit(SpecDocument doc) =>
      SpecDocumentMarkdown(model, doc).exportRoot(model.roots.first);

  SpecDocument landed(SpecMarkdownResult p) => SpecDocument()
    ..loadJson({
      'content': p.content,
      'forms': p.forms,
      'lists': p.lists,
      'headlines': p.headlines,
      'codeSpecs': p.codeSpecs,
      'units': p.units,
    });

  test('PT1: parse(emit(doc)) stages exactly the values', () {
    final doc = document();
    final markdown = emit(doc);
    final parsed = SpecDocumentMarkdown(model, SpecDocument()).parse(markdown);
    expect(parsed.rejections, isEmpty);
    expect(landed(parsed).toJson(), doc.toJson());
  });

  test('PT2: emit(parse(emit(doc))) is byte-identical', () {
    final markdown = emit(document());
    final again = landed(
      SpecDocumentMarkdown(model, SpecDocument()).parse(markdown),
    );
    expect(emit(again), markdown);
  });

  test('PT4: the Field:-line golden and the tables golden parse to the same '
      'document, the corpus state', () {
    final state = SpecDocument()
      ..loadJson(
        jsonDecode(File('$corpus/state.json').readAsStringSync())
            as Map<String, dynamic>,
      );
    for (final name in ['expected.tomspecs.md', 'expected.tables.md']) {
      final parsed = SpecDocumentMarkdown(
        model,
        SpecDocument(),
      ).parse(File('$corpus/$name').readAsStringSync());
      expect(parsed.rejections, isEmpty, reason: name);
      expect(landed(parsed).toJson(), state.toJson(), reason: name);
    }
  });

  test('PT3 the layout writes every form it can read back', () {
    final markdown = emit(document());
    expect(markdown, contains('| TomSpecField | Value |'));
    expect(markdown, contains('| Section | TomSpecField | Value |'));
    expect(markdown, contains('::: {.records}'));
    expect(markdown, contains('::: {.refs}'));
    expect(markdown, contains('<a id="DET"></a>'));
  });
}
