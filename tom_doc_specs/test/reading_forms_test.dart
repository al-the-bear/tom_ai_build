/// The reading forms of the DocSpecs specification as tom_doc_specs reads
/// them: form tables (*Form Types*, Form Tables), `refs` / `records` list
/// bodies and section tables (*List Bodies*), styled-div headings, section
/// anchors, the reading-notation findings of every document (RN-10) and the
/// prefix match of *Section Type Resolution*.
///
/// Each finding is written `<code or category>|<section>|<line>`; a finding
/// the specification gives a code carries it in [ValidationError.code].
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

late DocSpecSchema schema;

const _head =
    '<!-- docspec: reading-forms/1.0 -->\n'
    '# <!--[DOC]--> Reading Forms\n'
    '\n'
    '## <!--[OVR]--> Overview\n'
    '\n'
    'Some overview text.\n'
    '\n';

/// A document of the reading-forms schema: the overview, then [body].
String doc(String body) => '$_head$body';

/// The 1-based line of the first line of [md] containing [needle].
int at(String md, String needle, {int from = 1}) {
  final lines = md.split('\n');
  for (var i = from - 1; i < lines.length; i++) {
    if (lines[i].contains(needle)) return i + 1;
  }
  throw StateError('"$needle" not in the document');
}

/// [md] scanned with the DocSpecs factory.
SpecDoc scan(String md) {
  final dir = Directory.systemTemp.createTempSync('reading_forms');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File(p.join(dir.path, 'doc.md'))..writeAsStringSync(md);
  return DocScanner.scanDocumentSync(
        filepath: file.path,
        workspaceRoot: dir.path,
        factory: DocSpecsFactory(schema: schema),
      )
      as SpecDoc;
}

/// The findings of [md], each `<code or category>|<section>|<line>`.
List<String> findings(String md) => [
  for (final e in DocSpecsValidator(schema: schema).validate(scan(md)))
    '${e.code ?? e.category.name}|${e.sectionId}|${e.lineNumber}',
];

/// The section [id] anywhere in [d].
SpecSection section(SpecDoc d, String id) {
  SpecSection? find(List<Section>? list) {
    for (final s in list ?? const <Section>[]) {
      if (s.id == id) return s as SpecSection;
      final inner = find(s.sections);
      if (inner != null) return inner;
    }
    return null;
  }

  return find(d.sections) ?? (throw StateError('no section $id'));
}

void main() {
  setUpAll(() {
    final root = Directory.current.path.endsWith('tom_doc_specs')
        ? Directory.current.path
        : p.join(Directory.current.path, 'tom_doc_specs');
    schema = SchemaLoader.loadSync(
      p.join(
        root,
        'test',
        'fixtures',
        'schemas',
        'reading-forms.1.0.docspecs-schema.yaml',
      ),
    );
  });

  test('the overview alone is valid', () {
    expect(findings(doc('')), isEmpty);
  });

  group('form tables', () {
    test('rows give the fields; both headers, mixing, unescaping, links', () {
      final md = doc(
        '## <!--[HDR]--> Header\n'
        '\n'
        'The header of the document.\n'
        '\n'
        '| TomSpecField | Value |\n'
        '| --- | --- |\n'
        '| author | Alice \\| Ann |\n'
        '\n'
        'Description: Written by\n'
        'two people.\n'
        '\n'
        '| DocSpecsField | value |\n'
        '| :-- | --: |\n'
        '| Reviewer | [Bob](people.md#bob) |\n',
      );
      expect(findings(md), isEmpty);
      final hdr = section(scan(md), 'HDR');
      expect(hdr.formFields, {
        'author': 'Alice | Ann',
        'description': 'Written by\ntwo people.',
        'reviewer': 'Bob',
      });
      expect(hdr.preamble, 'The header of the document.');
      expect(hdr.fieldLine('Reviewer'), at(md, '| Reviewer |'));
      expect(hdr.fieldLine('description'), at(md, 'Description:'));
    });

    test('a required field missing from table and paragraphs', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        '| TomSpecField | Value |\n| --- | --- |\n| Reviewer | Bob |\n',
      );
      expect(findings(md), ['format|HDR|${at(md, '[HDR]')}']);
    });

    test('fieldPatternMismatch points at the row', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        '| TomSpecField | Value |\n| --- | --- |\n'
        '| Author | Alice |\n| Reviewer | bob |\n',
      );
      expect(findings(md), ['format|HDR|${at(md, '| Reviewer |')}']);
    });

    test('a table without its delimiter row reads nothing', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        '| TomSpecField | Value |\n| Author | Alice |\n',
      );
      expect(findings(md), [
        'malformedBlock|HDR|${at(md, '| TomSpecField |')}',
        'format|HDR|${at(md, '[HDR]')}',
      ]);
    });

    test('a row of another cell count is skipped, the others read', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        '| TomSpecField | Value |\n| --- | --- |\n'
        '| Author | Alice |\n| Reviewer | Bob | x |\n',
      );
      expect(findings(md), ['malformedBlock|HDR|${at(md, '| Reviewer |')}']);
      expect(section(scan(md), 'HDR').getFormField('reviewer'), isNull);
    });

    test('a row naming no field is unknownField', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        '| TomSpecField | Value |\n| --- | --- |\n'
        '| Author | Alice |\n| Editor | Carol |\n',
      );
      expect(findings(md), ['unknownField|HDR|${at(md, '| Editor |')}']);
    });

    test('a field given twice keeps the first', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        '| TomSpecField | Value |\n| --- | --- |\n'
        '| Author | Alice |\n| Reviewer | Bob |\n\nReviewer: bob\n',
      );
      expect(findings(md), ['malformedBlock|HDR|${at(md, 'Reviewer: bob')}']);
      expect(section(scan(md), 'HDR').getFormField('reviewer'), 'Bob');
    });

    test('two Fieldname: lines still keep the later one, unreported', () {
      final md = doc('## <!--[HDR]--> Header\n\nAuthor: Alice\nAuthor: Ann\n');
      expect(findings(md), isEmpty);
      expect(section(scan(md), 'HDR').getFormField('author'), 'Ann');
    });

    test('an escaped layout header is content, its space removed', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\n'
        'Author: Alice\n'
        'Description: These two fields.\n'
        ' | TomSpecField | Value |\n'
        ' | --- | --- |\n'
        ' | Reviewer | the reviewer |\n',
      );
      expect(findings(md), isEmpty);
      final hdr = section(scan(md), 'HDR');
      expect(hdr.getFormField('reviewer'), isNull);
      expect(
        hdr.getFormField('description'),
        'These two fields.\n| TomSpecField | Value |\n| --- | --- |\n'
        '| Reviewer | the reviewer |',
      );
    });

    test('a table in fenced code is content', () {
      final md = doc(
        '## <!--[HDR]--> Header\n\nAuthor: Alice\n'
        'Description: an example\n'
        '```\n| TomSpecField | Value |\n| --- | --- |\n| Reviewer | x |\n```\n',
      );
      expect(findings(md), isEmpty);
      expect(section(scan(md), 'HDR').getFormField('reviewer'), isNull);
    });
  });

  group('refs bodies', () {
    test('a refs line below min-count', () {
      final md = doc(
        '## <!--[REFS-LST]--> References\n\n'
        '::: {.refs}\n[GOAL-ITEM-1](#GOAL-ITEM-1)\n:::\n',
      );
      expect(findings(md), ['countLimit|REFS-LST|${at(md, '[REFS-LST]')}']);
      final item = section(scan(md), 'REFS-1');
      expect(item.isVirtual, isTrue);
      expect(item.type, 'ref-item');
      expect(item.lineNumber, at(md, '::: {.refs}'));
      expect(item.getFormField('target'), 'GOAL-ITEM-1');
    });

    test('a refs container passes max-text-length 0', () {
      final md = doc(
        '## <!--[REFS-LST]--> References\n\n'
        '::: refs\n[GOAL-ITEM-1](#GOAL-ITEM-1), GOAL-ITEM-2\n:::\n',
      );
      expect(findings(md), isEmpty);
      final d = scan(md);
      expect(section(d, 'REFS-LST').text, isEmpty);
      expect(section(d, 'REFS-LST').sections!.map((s) => s.id), [
        'REFS-1',
        'REFS-2',
      ]);
      expect(section(d, 'REFS-2').getFormField('target'), 'GOAL-ITEM-2');
    });

    test("a reference's value is checked at the div", () {
      final md = doc(
        '## <!--[REFS-LST]--> References\n\n'
        '::: {.refs}\nGOAL-1, lower-case\n:::\n',
      );
      expect(findings(md), ['format|REFS-2|${at(md, '::: {.refs}')}']);
    });

    test('refs into a virtual child section', () {
      final md = doc(
        '## <!--[LINK-LST]--> Links\n\n::: {.refs}\nGOAL-ITEM-1\n:::\n',
      );
      expect(findings(md), isEmpty);
      final d = scan(md);
      final item = section(d, 'LINK-1');
      expect(item.type, 'link-item');
      final child = item.sections!.single as SpecSection;
      expect(child.id, 'LINK-1/LINK-REF');
      expect(child.type, 'link-ref');
      expect(child.getFormField('target'), 'GOAL-ITEM-1');
    });

    test('a refs div beside other text', () {
      final md = doc(
        '## <!--[REFS-LST]--> References\n\nSee below.\n\n'
        '::: {.refs}\nGOAL-ITEM-1, GOAL-ITEM-2\n:::\n',
      );
      final heading = at(md, '[REFS-LST]');
      expect(findings(md), [
        'countLimit|REFS-LST|$heading',
        'textContent|REFS-LST|$heading',
        'malformedBlock|REFS-LST|${at(md, '::: {.refs}')}',
      ]);
    });

    test('an unclosed refs fence: its lines stay text', () {
      final md = doc(
        '## <!--[REFS-LST]--> References\n\n'
        '::: {.refs}\nGOAL-ITEM-1, GOAL-ITEM-2\n',
      );
      final heading = at(md, '[REFS-LST]');
      final fence = at(md, '::: {.refs}');
      expect(findings(md), [
        'countLimit|REFS-LST|$heading',
        'textContent|REFS-LST|$heading',
        'unclosedDiv|REFS-LST|$fence',
        'malformedBlock|REFS-LST|$fence',
      ]);
    });
  });

  group('records bodies', () {
    const records =
        '## <!--[CRIT-LST]--> Acceptance Criteria\n'
        '\n'
        '::: {.records}\n'
        '| Id | Title | Given | When | Then |\n'
        '| --- | --- | --- | --- | --- |\n';

    test('a records table satisfies min-count; anchors and titles', () {
      final md = doc(
        '$records'
        '| <a id="CRIT-1"></a>CRIT-1 | Second<br>admin | a tenant | it '
        'invites | both confirm |\n'
        '| <a id="CRIT-2"></a>CRIT-2 | | an invitation | it expires | '
        'the user asks again |\n'
        ':::\n',
      );
      expect(findings(md), isEmpty);
      final d = scan(md);
      final first = section(d, 'CRIT-1');
      expect(first.isVirtual, isTrue);
      expect(first.name, 'Second\nadmin');
      expect(first.lineNumber, at(md, 'CRIT-1 |'));
      expect(first.formFields, {
        'given': 'a tenant',
        'when': 'it invites',
        'then': 'both confirm',
      });
      expect(section(d, 'CRIT-2').name, isEmpty);
      expect(section(d, 'CRIT-LST').text, isEmpty);
    });

    test('a records row below a list item carries the qualified anchor', () {
      final md = doc(
        '$records'
        '| <a id="FRE-X/CRIT-1"></a>CRIT-1 | | a tenant | it invites | '
        'both confirm |\n'
        '| <a id="FRE-X/CRIT-2"></a>CRIT-2 | | an invitation | it expires | '
        'the user asks again |\n'
        ':::\n',
      );
      expect(findings(md), isEmpty);
      expect(section(scan(md), 'CRIT-1').isVirtual, isTrue);
    });

    test('row findings point at their rows', () {
      final md = doc(
        '$records'
        '| CRIT-1 | | a tenant | | ok |\n'
        '| CRIT-X | | | | Bad |\n'
        ':::\n',
      );
      // The id pattern, the missing Given, the Then pattern: all at the row,
      // the virtual item's line.
      final row = at(md, '| CRIT-X |');
      expect(findings(md), [
        'sectionId|CRIT-X|$row',
        'format|CRIT-X|$row',
        'format|CRIT-X|$row',
      ]);
    });

    test('a records div holding no table', () {
      final md = doc(
        '## <!--[CRIT-LST]--> Criteria\n\n::: {.records}\nno table\n:::\n',
      );
      expect(findings(md), [
        'countLimit|CRIT-LST|${at(md, '[CRIT-LST]')}',
        'malformedBlock|CRIT-LST|${at(md, '::: {.records}')}',
      ]);
    });

    test('a records table whose first column is not Id', () {
      final md = doc(
        '## <!--[CRIT-LST]--> Criteria\n\n::: records\n'
        '| Key | Given |\n| --- | --- |\n| CRIT-1 | a |\n:::\n',
      );
      expect(findings(md), [
        'countLimit|CRIT-LST|${at(md, '[CRIT-LST]')}',
        'malformedBlock|CRIT-LST|${at(md, '::: records')}',
      ]);
    });

    test('a records column naming no field reads nothing', () {
      final md = doc(
        '## <!--[CRIT-LST]--> Criteria\n\n::: {.records}\n'
        '| Id | Given | Owner |\n| --- | --- | --- |\n'
        '| CRIT-1 | a | b |\n| CRIT-2 | a | b |\n:::\n',
      );
      expect(findings(md), [
        'countLimit|CRIT-LST|${at(md, '[CRIT-LST]')}',
        'unknownField|CRIT-LST|${at(md, '| Id |')}',
      ]);
    });

    test('a records div beside item headings', () {
      final md = doc(
        '## <!--[CRIT-LST]--> Criteria\n\n::: {.records}\n'
        '| Id | Given |\n| --- | --- |\n| CRIT-3 | a |\n:::\n\n'
        '### <!--[CRIT-1]--> One\n\nGiven: a\n\n'
        '### <!--[CRIT-2]--> Two\n\nGiven: b\n',
      );
      expect(findings(md), [
        'malformedBlock|CRIT-LST|${at(md, '::: {.records}')}',
      ]);
      expect(section(scan(md), 'CRIT-LST').sections!.map((s) => s.id), [
        'CRIT-1',
        'CRIT-2',
      ]);
    });
  });

  group('section tables', () {
    test('rows rebuild the children, a list item as <LIST> / <ITEM>', () {
      final md = doc(
        '## <!--[ATTR]--> Attribute\n'
        '\n'
        '| Section | TomSpecField | Value |\n'
        '| --- | --- | --- |\n'
        '| <a id="IDEN"></a>IDEN | ColumnName | name |\n'
        '| | Description | Display name. |\n'
        '| CONS-LST / CONS-NAME | Mandatory | Yes |\n',
      );
      expect(findings(md), isEmpty);
      final d = scan(md);
      final attr = section(d, 'ATTR');
      expect(attr.text, isEmpty);
      expect(attr.sections!.map((s) => s.id), ['IDEN', 'CONS-LST']);
      final iden = section(d, 'IDEN');
      expect(iden.isVirtual, isTrue);
      expect(iden.lineNumber, at(md, '| <a id="IDEN">'));
      expect(iden.formFields, {
        'columnname': 'name',
        'description': 'Display name.',
      });
      final item = section(d, 'CONS-NAME');
      expect(item.type, 'cons-item');
      expect(item.getFormField('mandatory'), 'Yes');
    });

    test('findings at their rows', () {
      final md = doc(
        '## <!--[ATTR]--> Attribute\n'
        '\n'
        '| Section | DocSpecsField | Value |\n'
        '| --- | --- | --- |\n'
        '| | ColumnName | orphan |\n'
        '| IDEN | Description | no column name |\n'
        '| CONS-LST / CONS-NAME | Mandatory | Maybe |\n'
        '| | Unique | Yes |\n',
      );
      // IDEN misses its ColumnName: at its line, the row that created it.
      expect(
        findings(md),
        unorderedEquals([
          'format|IDEN|${at(md, '| IDEN |')}',
          'format|CONS-NAME|${at(md, '| Maybe |')}',
          'unknownSection|ATTR|${at(md, '| orphan |')}',
          'unknownField|CONS-NAME|${at(md, '| Unique |')}',
        ]),
      );
    });

    test('a Section cell naming no child skips its rows', () {
      final md = doc(
        '## <!--[ATTR]--> Attribute\n'
        '\n'
        '| Section | TomSpecField | Value |\n'
        '| --- | --- | --- |\n'
        '| IDEN | ColumnName | name |\n'
        '| GOALS | Title | x |\n'
        '| | More | y |\n',
      );
      expect(findings(md), ['unknownSection|GOALS|${at(md, '| GOALS |')}']);
    });

    test('values go to a headed child too, above its own body', () {
      final md = doc(
        '## <!--[ATTR]--> Attribute\n'
        '\n'
        '| Section | TomSpecField | Value |\n'
        '| --- | --- | --- |\n'
        '| IDEN | ColumnName | name |\n'
        '\n'
        '### <!--[IDEN]--> Identity\n'
        '\n'
        'Description: from the heading\n'
        'ColumnName: again\n',
      );
      expect(findings(md), [
        'malformedBlock|IDEN|${at(md, 'ColumnName: again')}',
      ]);
      final iden = section(scan(md), 'IDEN');
      expect(iden.isVirtual, isFalse);
      expect(iden.getFormField('columnname'), 'name');
      expect(iden.getFormField('description'), 'from the heading');
    });

    test("the root's section table gives a top-level section", () {
      final md =
          '<!-- docspec: reading-forms/1.0 -->\n'
          '# <!--[DOC]--> Reading Forms\n'
          '\n'
          '| Section | TomSpecField | Value |\n'
          '| --- | --- | --- |\n'
          '| HDR | Author | Alice |\n'
          '\n'
          '## <!--[OVR]--> Overview\n'
          '\n'
          'Text.\n';
      expect(findings(md), isEmpty);
      final d = scan(md);
      expect(d.sections!.map((s) => s.id), ['OVR', 'HDR']);
      expect(section(d, 'HDR').getFormField('author'), 'Alice');
      expect(d.text, isEmpty);
    });
  });

  group('styled-div headings', () {
    const style = 'style="margin:1em 0 0.5em;padding-left:0.75em"';

    test('styled-div headings count at their level, anchors removed', () {
      final md = doc(
        '## <!--[GOALS]--> Goals\n\n'
        '<div class="heading7" $style><!--[GOAL-ITEM-1]--> '
        '<a id="GOAL-ITEM-1"></a> Goal &amp; aim</div>\n\nFirst goal.\n',
      );
      expect(findings(md), isEmpty);
      final goal = section(scan(md), 'GOAL-ITEM-1');
      expect(goal.name, 'Goal & aim');
      expect(goal.type, 'goal-item');
      expect(goal.text, 'First goal.');
    });

    test('a heading6 div is content', () {
      final md = doc(
        '## <!--[GOALS]--> Goals\n\n'
        '<div class="heading6" $style><!--[GOAL-ITEM-1]--> Goal</div>\n',
      );
      expect(findings(md), ['countLimit|GOALS|${at(md, '[GOALS]')}']);
      expect(section(scan(md), 'GOALS').text, contains('heading6'));
    });
  });

  group('fenced-div findings', () {
    test('unclosedDiv, strayClosingFence and rejectedBlock', () {
      final md = doc(
        '## <!--[GOALS]--> Goals\n'
        '\n'
        '::: {.provenance}\n'
        'Taken from the workshop.\n'
        '\n'
        '### <!--[GOAL-ITEM-1]--> Goal\n'
        '\n'
        'A paragraph.\n'
        ':::\n'
        '\n'
        '::: {.rejected reason="malformedBlock" line="3"}\n'
        'Owner: Platform team\n'
        ':::\n',
      );
      expect(findings(md), [
        'unclosedDiv|GOALS|${at(md, '::: {.provenance}')}',
        'strayClosingFence|GOAL-ITEM-1|${at(md, ':::', from: at(md, 'A paragraph.'))}',
        'rejectedBlock|GOAL-ITEM-1|${at(md, '::: {.rejected')}',
      ]);
    });

    test('closed and nested divs and divs in fenced code pass', () {
      final md = doc(
        '## <!--[GOALS]--> Goals\n'
        '\n'
        '::: aside\n'
        '::: {.editorial}\n'
        'Nested.\n'
        ':::\n'
        ':::\n'
        '\n'
        '```\n'
        ':::\n'
        '::: {.rejected}\n'
        '```\n'
        '\n'
        '### <!--[GOAL-ITEM-1]--> Goal\n',
      );
      expect(findings(md), isEmpty);
    });
  });

  group('span and annotation findings', () {
    /// A document whose `GOALS` section holds [body], then a goal.
    String goals(String body) => doc(
      '## <!--[GOALS]--> Goals\n\n$body\n'
      '### <!--[GOAL-ITEM-1]--> Goal\n\nA goal.\n',
    );

    test('unclosedSpan at the line its braces open', () {
      final md = goals(
        'The limit is 150 EUR [per order]{.aside label="scope".\n'
        '\n'
        'A span [opened]{.aside\n'
        '\n'
        'closes in no other paragraph}.\n'
        '\n'
        '| Field | Value |\n'
        '| --- | --- |\n'
        '| Format | `json` [or `yaml \\| toml`]{.aside |\n',
      );
      expect(findings(md), [
        'unclosedSpan|GOALS|${at(md, 'The limit is')}',
        'unclosedSpan|GOALS|${at(md, 'A span [opened]')}',
        'unclosedSpan|GOALS|${at(md, '| Format |')}',
      ]);
    });

    test('closed spans, wrapped spans and quoted braces pass', () {
      final md = goals(
        'The token lives 15 minutes [as the review\n'
        'asked in March]{.aside label="a } in a value"}.\n'
        '\n'
        '[outer [inner]{.trace} text]{.aside} and a [link](x.md).\n'
        '\n'
        '| Field | Value |\n'
        '| --- | --- |\n'
        '| Format | `json` [or `yaml \\| toml` on request]{.aside} |\n',
      );
      expect(findings(md), isEmpty);
    });

    test('markAcrossNotation at the line the mark opens', () {
      final md = goals(
        'Backed by [the review {++of March]{.aside} and April++}.\n'
        '\n'
        'A {--deleted [part--} of a span]{.aside}.\n'
        '\n'
        'Rights apply to the subtree (-> C2.1{++, C2.4)\n'
        'and more++}.\n',
      );
      expect(findings(md), [
        'markAcrossNotation|GOALS|${at(md, 'Backed by')}',
        'markAcrossNotation|GOALS|${at(md, 'A {--deleted')}',
        'markAcrossNotation|GOALS|${at(md, 'Rights apply')}',
      ]);
    });

    test('marks inside and around spans and citations pass', () {
      final md = goals(
        'The subtree inherits the rights (-> {++C2.1, ++}C2.4).\n'
        'Rights scoped to a node apply to its subtree{++ (-> C2.1)++}.\n'
        'An [aside {~~with~>without~~} change]{.aside} and '
        '{==[a span]{.aside}==}{>>why?<<}.\n'
        '\n'
        '::: {.editorial}\n'
        'Marks inside a {++div++} pass.\n'
        ':::\n',
      );
      expect(findings(md), isEmpty);
    });

    test('annotationInsideDiv and divInsideAnnotation', () {
      final md = goals(
        '::: {.editorial}\n'
        '> ⬆️ **C-12** (alice, 2026-11-19T10:05+01:00): Is this still true?\n'
        ':::\n'
        '\n'
        '::: aside\n'
        '> **❓ BQ-1 — Scope:** per order or per day?\n'
        '>\n'
        '> **Answer:**\n'
        ':::\n'
        '\n'
        '> ⬆️ **C-13** (alice, 2026-11-19T10:06+01:00): Move this note?\n'
        '> ::: {.aside}\n'
        '> A note.\n'
        '> :::\n',
      );
      expect(findings(md), [
        'annotationInsideDiv|GOALS|${at(md, '**C-12**')}',
        'annotationInsideDiv|GOALS|${at(md, '**❓ BQ-1')}',
        'divInsideAnnotation|GOALS|${at(md, '> ::: {.aside}')}',
      ]);
    });

    test('annotations beside a div and a div in a plain quote pass', () {
      final md = goals(
        '> ⬆️ **C-12** (alice): Is this still true?\n'
        '\n'
        '::: {.editorial}\n'
        'The note.\n'
        ':::\n'
        '\n'
        '> **❓ BQ-1 — Scope:** per order or per day?\n'
        '>\n'
        '> **Answer:**\n'
        '\n'
        '> A plain quotation.\n'
        '> ::: {.aside}\n'
        '> Quoted.\n'
        '> :::\n',
      );
      expect(findings(md), isEmpty);
    });

    test('escapes, code spans and fenced code keep text from being '
        'notation (RN-7, RN-8, RN-9)', () {
      final md = goals(
        '\\::: is how the notation opens a block.\n'
        '\n'
        '\\:::\n'
        '\n'
        'The array [0]\\{.x is not a span, nor is [text] {.aside or '
        '\\[x]{.aside.\n'
        '\n'
        'Write `[x]{.aside` or ``a `{++` [b]{.c``, and `{++[a]{.x} b++}`.\n'
        '\n'
        'Backed by [the review \\{++of March]{.aside} and April++}.\n'
        '\n'
        '```markdown\n'
        '[x]{.aside\n'
        'Backed by [the review {++of March]{.aside} and April++}.\n'
        '::: {.editorial}\n'
        '> ⬆️ **C-1** (alice): inside code\n'
        '```\n',
      );
      expect(findings(md), isEmpty);
    });

    test('the findings come with category notation', () {
      final d = scan(goals('A span [opened]{.aside\n'));
      final errors = DocSpecsValidator(schema: schema).validate(d);
      expect(errors.map((e) => e.category), [ValidationErrorCategory.notation]);
    });
  });

  group('prefix matching', () {
    test('an empty prefix is the catch-all type, declared last', () {
      final catchAll = DocSpecSchema.fromYaml(
        {
          'section-types': {
            'goal': {'prefix': 'GOAL'},
            'content': {'prefix': ''},
          },
        },
        id: 'catch-all',
        version: '1.0',
      );
      expect(catchAll.resolveSectionType('GOAL-1'), 'goal');
      expect(catchAll.resolveSectionType('ANYTHING-ELSE'), 'content');
      expect(
        () => SectionTypeDef.fromYaml('bad', {'prefix': 'a-b'}),
        throwsFormatException,
      );
    });

    test('a dashed id matches an underscore prefix, the raw id still '
        'counts', () {
      expect(DocSpecSchema.prefixMatches('D00-OVR', 'D00_OVR'), isTrue);
      expect(DocSpecSchema.prefixMatches('a.b c', 'A_B_C'), isTrue);
      expect(DocSpecSchema.prefixMatches('REQ__1', 'REQ__'), isTrue);
      expect(DocSpecSchema.prefixMatches('GOALS', 'GOAL_ITEM_'), isFalse);
      expect(schema.resolveSectionType('GOAL-ITEM-3'), 'goal-item');
      expect(schema.resolveSectionType('CRIT-LST'), 'crit-lst');
      expect(schema.resolveSectionType('CRIT-4'), 'crit-item');
    });
  });

  test('a virtual section survives a JSON round trip', () {
    final md = doc(
      '## <!--[REFS-LST]--> References\n\n::: {.refs}\nA-1, B-2\n:::\n',
    );
    final item = section(scan(md), 'REFS-1');
    final back = SpecSection.fromJson(item.toJson());
    expect(back.isVirtual, isTrue);
    expect(back.getFormField('target'), 'A-1');
    expect(back.virtualValues.single.line, item.lineNumber);
  });
}
