// Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): an import
// accepting rejections keeps each rejected block as a `rejected` div in the
// text of the section it stood in (else its parent), at its place. The kept
// document re-exports and re-imports without a rejection and to the same
// document, and the validator reports each div as `rejectedBlock`. The single
// cases are pinned in the conformance corpus (`markdown_apply_cases.json`).

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  // Copies of the conformance corpus files (see the parse tables test).
  const corpus = 'test/fixtures/corpus';
  final model = SpecModel.fromJson(
    jsonDecode(File('$corpus/model.meta.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final golden = File('$corpus/expected.tables.md').readAsStringSync();

  String sub(String from, String to) {
    if (!golden.contains(from)) throw StateError('the golden has no "$from"');
    return golden.replaceFirst(from, to);
  }

  SpecMarkdownResult parse(String markdown) =>
      SpecDocumentMarkdown(model, SpecDocument()).parse(markdown);

  SpecDocument kept(String markdown) =>
      SpecDocument()
        ..applyMarkdownResult(parse(markdown), allowRejections: true);

  final variants = <String, String>{
    'unknown section':
        '$golden\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n',
    'near-miss row': sub(
      '| Owner | Bob |',
      '| Owner | Bob |\n| Ownr | Carol |',
    ),
    'row given twice': sub(
      '| Estimate | 8 |',
      '| Estimate | 8 |\n| Owner | Carol |',
    ),
    'paragraph given twice': sub(
      '- backup: alice@example.com\n',
      '- backup: alice@example.com\nContact: carol@example.com\n- line\n',
    ),
    'table without delimiter': sub(
      '| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |',
      '| TomSpecField | Value |\n| Owner | Bob |',
    ),
    'records column': sub('| Id | Title | Note |', '| Id | Title | Nte |'),
    'records row': sub(
      '| <a id="CARD-2"></a>CARD-2 |  | second card |',
      '| <a id="CARD-2"></a>CARD-2 | second card |',
    ),
    'unclosed records fence': sub(
      '| second card |\n:::\n',
      '| second card |\n',
    ),
    'section-table row': sub(
      '| <a id="DLR-1"></a>DLR-LST / DLR-1 | Area | CE-NV |\n'
          '|  | Mapping | dart-tom |\n\n### <!--[DLV-2]',
      '| <a id="DLR-1"></a>DLR-LS / DLR-1 | Area | CE-NV |\n'
          '|  | Mapping | dart-tom |\n\n### <!--[DLV-2]',
    ),
    'orphan text': 'Stray text.\n\n$golden',
    'child under a value leaf': sub(
      'high\n\n## <!--[CNT]-->',
      'high\n\n### <!--[X]--> Child\n\nchild text\n\n## <!--[CNT]-->',
    ),
    'nested unknown sections':
        '$golden\n## <!--[NOPE]--> A\n\nA text\n\n### <!--[NOPE2]--> B\n\nB\n',
  };

  test('a clean parse keeps nothing', () {
    expect(parse(golden).keptContent, isEmpty);
  });

  for (final MapEntry(key: name, value: markdown) in variants.entries) {
    test(
      '$name: every rejection is kept, re-imports clean and is reported',
      () {
        final result = parse(markdown);
        expect(result.rejections, isNotEmpty);
        final doc = kept(markdown);
        final values = (doc.toJson()['content'] as Map).values.join('\n');
        final divs = RegExp(
          r'^:{3,} \{\.rejected reason="(\w+)" line="(\d+)"',
          multiLine: true,
        ).allMatches(values).map((m) => '${m[1]}@${m[2]}').toList();
        expect(divs, [
          for (final r in result.rejections) '${r.reason.name}@${r.line}',
        ]);

        final rendition = doc.toMarkdown(model, rootType: 'Demo');
        final again = parse(rendition);
        expect(again.rejections, isEmpty);
        final reloaded = SpecDocument()..applyMarkdownResult(again);
        expect(jsonEncode(reloaded.toJson()), jsonEncode(doc.toJson()));

        final reported =
            DocSpecsValidator(
                  DocSpecsSchema.fromYamlText(
                    'title-format: "# <!--[DEMO]--> Demo"\n',
                  ),
                  tomSpecs: true,
                )
                .validateMarkdown(rendition)
                .where((v) => v.rule == DocSpecsViolationRule.rejectedBlock);
        expect(reported, hasLength(result.rejections.length));
      },
    );
  }

  test('a refused import never reads the kept blocks', () {
    final doc = SpecDocument()
      ..loadJson({
        'content': {'DEMO/TTL': 'base'},
      });
    expect(
      () => doc.applyMarkdownResult(parse(variants['unknown section']!)),
      throwsStateError,
    );
    expect(doc.toJson()['content'], {'DEMO/TTL': 'base'});
  });

  test('a near miss names the field or section a rename offers', () {
    final row = kept(variants['near-miss row']!).content('DEMO/DET')!;
    expect(row, contains('reason="unknownField" line="31" field="owner" '));
    final twice = kept(variants['row given twice']!).content('DEMO/DET')!;
    expect(twice, contains('field="owner" kept="DEMO/DET" '));
    final cell = kept(
      variants['section-table row']!,
    ).content('DEMO/DLV-LST-1/content')!;
    expect(cell, contains('section="DLR-LST / DLR-1" '));
    // The continuation row the rejected section skipped is in its block.
    expect(cell, contains('|  | Mapping | dart-tom |'));
  });

  test('a list container passes its block to its parent', () {
    final doc = kept(variants['unclosed records fence']!);
    expect(doc.content('DEMO/CARD-LST'), isNull);
    final root = doc.content('DEMO')!;
    // The fence the block leaves unclosed is escaped, so the div closes.
    expect(root, contains('\n\\::: {.records}\n'));
    expect(root.trimRight(), endsWith('\n:::'));
    final records = kept(variants['records column']!).content('DEMO')!;
    expect(records, startsWith(':::: {.rejected reason="unknownField"'));
    expect(records, contains('\n::: {.records}\n'));
  });

  test('a block keeps its place among the text it stood in', () {
    final doc = kept(variants['paragraph given twice']!);
    expect(doc.formField('DEMO/DET', 'contact'), startsWith('bob@example.com'));
    expect(
      doc.content('DEMO/DET'),
      'Captured during the November review.\n'
      'Owner: this line is prose, not the field.\n\n'
      '::: {.rejected reason="malformedBlock" line="35" field="contact" '
      'kept="DEMO/DET" label="field \'contact\' given twice"}\n'
      'Contact: carol@example.com\n- line\n:::',
    );
    final orphan = kept(variants['orphan text']!).content('DEMO')!;
    expect(
      orphan,
      startsWith('::: {.rejected reason="orphanContent" line="1"'),
    );
  });
}
