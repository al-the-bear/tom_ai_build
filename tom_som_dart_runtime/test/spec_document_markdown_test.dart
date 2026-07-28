// Tests for the DocSpecs-conform Markdown codec (`spec_document_markdown.dart`,
// SOM §11).
//
// The generated `*.md` is a genuine DocSpecs document: line 1 is the
// `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
// section is a heading of the form `## <!--[SECTION-ID]--> Title` (headline
// comment carries the machine id, the text is the human-readable Title-Case
// member name), content sections are normal markdown text (no fences), `@Form`
// sections use the plain-text `FieldName: value` format, and a list emits its
// `-LST` container heading with the numbered items one level below it.
//
// Emit + parse round-trip is lossless per SOM §11, id comment
// placement and form rendering follow the spec, and content with embedded
// markdown formatting (including fenced code blocks) survives.

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A class graph covering content, enum, `@Form`, a complex sub-section and a
/// list of complex items, so the round-trip exercises every store.
Map<String, dynamic> _sampleJson() => {
      'roots': [
        {
          'type': 'DemoDoc',
          'title': 'Demo Document',
          'sectionId': 'D00',
          'description': 'A demo document.',
        },
      ],
      'classes': {
        'DemoDoc': {
          'name': 'DemoDoc',
          'sectionId': 'D00',
          'fields': [
            {'name': 'overview', 'kind': 'content', 'sectionId': 'D00-OVR'},
            {
              'name': 'status',
              'kind': 'enum',
              'sectionId': 'D00-ST',
              'enumValues': ['draft', 'final'],
            },
            {
              'name': 'header',
              'kind': 'form',
              'sectionId': 'D00-HDR',
              'formFields': [
                {'name': 'author', 'label': 'Author', 'type': 'String'},
                {'name': 'reviewer', 'label': 'Reviewer', 'type': 'String'},
              ],
            },
            {
              'name': 'meta',
              'kind': 'complex',
              'type': 'DemoMeta',
              'sectionId': 'D00-MET',
            },
            {
              'name': 'items',
              'kind': 'list',
              'elementType': 'DemoItem',
              'elementIsComplex': true,
              'sectionId': 'D00-ITM',
            },
            // A scalar sub-section list (`List<String>`, model shape 6): no
            // element class, so its item heading stem must be derived from the
            // field (member name) rather than the `String` element type (YRC5).
            {
              'name': 'tags',
              'kind': 'list',
              'elementType': 'String',
              'elementIsComplex': false,
              'sectionId': 'D00-TAG-LST',
              'sectionIdPattern': 'D00-TAG-xxx',
            },
          ],
        },
        'DemoMeta': {
          'name': 'DemoMeta',
          'sectionId': 'D00-MET',
          'fields': [
            {'name': 'note', 'kind': 'content', 'sectionId': 'D00-MET-NOTE'},
          ],
        },
        'DemoItem': {
          'name': 'DemoItem',
          'fields': [
            {'name': 'label', 'kind': 'content', 'sectionId': 'D01-LBL'},
            {'name': 'body', 'kind': 'content', 'sectionId': 'D01-BODY'},
          ],
        },
      },
    };

/// A d4rt-flutter body that is multi-line and embeds a run of three backticks
/// mid-line — must pass through the plain-text body verbatim.
const _d4rtBody = 'Column(\n'
    '  children: [\n'
    '    Text("hi"),\n'
    '  ],\n'
    ') // not a fence: ``` still inside the body';

/// Content that exercises embedded markdown formatting: emphasis, a bullet
/// list, a fenced code block containing heading-like lines, and a leading `#`
/// line at column 0 (which the emitter escapes as `\#`).
const _richMarkdown = 'Intro with **bold** and *italic*.\n'
    '\n'
    '- first bullet\n'
    '- second bullet\n'
    '\n'
    '```dart\n'
    '# not a heading — shielded by the fence\n'
    '## also shielded\n'
    'void main() {}\n'
    '```\n'
    '\n'
    '# looks like a heading at column 0\n'
    'trailing paragraph';

SpecDocument _populated() {
  final doc = SpecDocument()
    ..setContent('D00/D00-OVR', 'An overview paragraph.\nWith two lines.')
    ..setContent('D00/D00-ST', 'final')
    ..setFormField('D00/D00-HDR', 'author', 'Ada Lovelace')
    ..setContent('D00/D00-MET/D00-MET-NOTE', 'A note.');
  final item = doc.addListItem('D00/D00-ITM');
  doc.setContent('$item/D01-LBL', 'First item');
  doc.setContent('$item/D01-BODY', _d4rtBody);
  final item2 = doc.addListItem('D00/D00-ITM');
  doc.setContent('$item2/D01-LBL', 'Second item');
  // Populated scalar list: each item's value is its body (content at the item
  // path); heading identity is positional.
  final tag1 = doc.addListItem('D00/D00-TAG-LST');
  doc.setContent(tag1, 'first tag');
  final tag2 = doc.addListItem('D00/D00-TAG-LST');
  doc.setContent(tag2, 'second tag');
  return doc;
}

SpecModel _model() => SpecModel.fromJson(_sampleJson());

SpecRoot _root() => _model().roots.single;

String _export(SpecDocument doc) =>
    SpecDocumentMarkdown(_model(), doc).exportRoot(_root());

/// Parses [md] into a fresh document via the staged-values report.
(SpecDocument, SpecMarkdownResult) _reload(String md) {
  final target = SpecDocument();
  final report = SpecDocumentMarkdown(_model(), target).parse(md);
  target.loadJson({
    'content': report.content,
    'forms': report.forms,
    'lists': report.lists,
  });
  return (target, report);
}

void main() {
  group('export — DocSpecs format (SOM §11)', () {
    test('line 1 is the docspec declaration with the kebab-cased title', () {
      final md = _export(_populated());
      expect(md.split('\n').first, startsWith('<!-- docspec: demo-document/'));
      expect(md.split('\n').first, endsWith('-->'));
    });

    test('headings carry the id as a headline comment plus a readable title',
        () {
      final md = _export(_populated());
      expect(md, contains('# <!--[D00]--> Demo Document'));
      expect(md, contains('## <!--[D00-OVR]--> Overview'));
      expect(md, contains('## <!--[D00-ST]--> Status'));
      expect(md, contains('## <!--[D00-HDR]--> Header'));
      expect(md, contains('## <!--[D00-MET]--> Meta'));
      expect(md, contains('### <!--[D00-MET-NOTE]--> Note'));
    });

    test('content sections are plain markdown text — no fences, no anchors',
        () {
      final md = _export(_populated());
      expect(md, contains('An overview paragraph.\nWith two lines.'));
      // No fenced leaf encoding: no line *starts* a fence (the d4rt body's
      // mid-line backtick run is plain text, not a fence).
      expect(md.split('\n').any((l) => l.startsWith('```')), isFalse);
      expect(md, isNot(contains('<!-- field:')));
      // No path-style headings either.
      expect(md, isNot(contains('D00/D00-OVR')));
    });

    test('form sections use FieldName: value plain-text lines, sparse', () {
      final md = _export(_populated());
      expect(md, contains('Author: Ada Lovelace'));
      // Empty fields (the reviewer form field) are not emitted.
      expect(md, isNot(contains('Reviewer')));
    });

    test('a list emits its -LST container heading with items one level deeper',
        () {
      final md = _export(_populated());
      // The list container heads (SOM §11.2): `D00-ITM` at the owner's child
      // level, its numbered items one level below it, item fields one deeper.
      expect(md, contains('## <!--[D00-ITM]--> Items'));
      expect(md, contains('### <!--[items-1]--> Demo Item 1'));
      expect(md, contains('### <!--[items-2]--> Demo Item 2'));
      expect(md, contains('#### <!--[D01-LBL]--> Label'));
    });

    test('a populated scalar list derives item headings from the field, not '
        'the String element type (YRC5)', () {
      final md = _export(_populated());
      // The `-LST` container heading uses the Title-Cased member name.
      expect(md, contains('## <!--[D00-TAG-LST]--> Tags'));
      // Item stem is the field name ("Tags N"), never the element `typeName`
      // ("String N") — the shape-6 heading defect this change fixes.
      expect(md, contains('### <!--[D00-TAG-1]--> Tags 1'));
      expect(md, contains('### <!--[D00-TAG-2]--> Tags 2'));
      expect(md, isNot(contains('String 1')));
      expect(md, isNot(contains('String 2')));
      // The scalar item values render as the item body.
      expect(md, contains('first tag'));
      expect(md, contains('second tag'));
    });

    test('the root schema description is not emitted (only stored content)',
        () {
      final md = _export(_populated());
      expect(md, isNot(contains('A demo document.')));
    });

    test('a stored item section id IS surfaced in the item heading '
        '(YRD3 — som_multiplatform_spec_model.md §11.5)', () {
      final doc = SpecDocument();
      final item = doc.addListItem('D00/D00-ITM', sectionId: 'D01-CUSTOM');
      doc.setContent('$item/D01-LBL', 'Custom-id item');
      final md = _export(doc);
      // YRD3: the stored id (`D01-CUSTOM` — an override, or equally an AA1
      // generated id) is the md heading id; the anonymous positional id is
      // only the fallback for items WITHOUT a stored id.
      expect(md, contains('## <!--[D00-ITM]--> Items'));
      expect(md, contains('### <!--[D01-CUSTOM]--> Demo Item 1'));
      expect(md, isNot(contains('items-1')));
    });

    test('a content value with an unterminated fence throws ArgumentError',
        () {
      final doc = SpecDocument()
        ..setContent('D00/D00-OVR', 'before\n```dart\nnever closed');
      expect(
        () => _export(doc),
        throwsA(isA<ArgumentError>().having(
            (e) => '${e.message}', 'message', contains('unterminated'))),
      );
    });
  });

  group('SpecDocument.toMarkdown (one-line export, SOM §21)', () {
    test('matches the explicit codec output for an explicit rootType', () {
      final model = _model();
      final doc = _populated();
      final oneLiner = doc.toMarkdown(model, rootType: 'DemoDoc');
      final explicit = SpecDocumentMarkdown(model, doc)
          .exportRoot(model.rootByType('DemoDoc'));
      expect(oneLiner, explicit);
    });

    test('defaults to the single populated root when rootType is omitted', () {
      final model = _model();
      final doc = _populated();
      expect(doc.toMarkdown(model), doc.toMarkdown(model, rootType: 'DemoDoc'));
    });

    test('throws when no root is populated', () {
      final model = _model();
      expect(
        () => SpecDocument().toMarkdown(model),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('no populated root'))),
      );
    });

    test('throws naming the candidates when more than one root is populated',
        () {
      final model = SpecModel.fromJson(<String, dynamic>{
        'roots': <dynamic>[
          {'type': 'Alpha', 'title': 'Alpha Doc', 'sectionId': 'A00'},
          {'type': 'Beta', 'title': 'Beta Doc', 'sectionId': 'B00'},
        ],
        'classes': <String, dynamic>{
          'Alpha': {
            'name': 'Alpha',
            'sectionId': 'A00',
            'fields': [
              {'name': 'overview', 'kind': 'content', 'sectionId': 'A00-OVR'},
            ],
          },
          'Beta': {
            'name': 'Beta',
            'sectionId': 'B00',
            'fields': [
              {'name': 'overview', 'kind': 'content', 'sectionId': 'B00-OVR'},
            ],
          },
        },
      });
      final doc = SpecDocument()
        ..setContent('A00/A00-OVR', 'a')
        ..setContent('B00/B00-OVR', 'b');
      expect(
        () => doc.toMarkdown(model),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'm', contains('Alpha'))
            .having((e) => e.message, 'm', contains('Beta'))),
      );
    });
  });

  group('round-trip', () {
    test('export → parse into a fresh document reproduces every value', () {
      final md = _export(_populated());
      final (target, report) = _reload(md);
      expect(report.isClean, isTrue, reason: report.rejections.toString());

      expect(target.content('D00/D00-OVR'),
          'An overview paragraph.\nWith two lines.');
      expect(target.content('D00/D00-ST'), 'final');
      expect(target.formField('D00/D00-HDR', 'author'), 'Ada Lovelace');
      expect(target.content('D00/D00-MET/D00-MET-NOTE'), 'A note.');
      final items = target.listItems('D00/D00-ITM');
      expect(items, hasLength(2));
      expect(target.content('${items[0]}/D01-LBL'), 'First item');
      // The embedded d4rt body survives verbatim, backticks and all.
      expect(target.content('${items[0]}/D01-BODY'), _d4rtBody);
      expect(target.content('${items[1]}/D01-LBL'), 'Second item');
    });

    test('Markdown → memory → Markdown is byte-stable for the fixture', () {
      final md1 = _export(_populated());
      final (reloaded, _) = _reload(md1);
      final md2 = _export(reloaded);
      expect(md2, md1);
    });

    test('content with embedded markdown formatting survives the round-trip',
        () {
      final doc = SpecDocument()..setContent('D00/D00-OVR', _richMarkdown);
      final md1 = _export(doc);
      // Fence-shielded heading-like lines are NOT escaped; the column-0 `#`
      // line outside the fence IS.
      expect(md1, contains('\n# not a heading — shielded by the fence\n'));
      expect(md1, contains('\n\\# looks like a heading at column 0\n'));

      final (reloaded, report) = _reload(md1);
      expect(report.isClean, isTrue, reason: report.rejections.toString());
      expect(reloaded.content('D00/D00-OVR'), _richMarkdown);
      // And the second pass is byte-stable.
      expect(_export(reloaded), md1);
    });

    test('a stored item section id round-trips through md '
        '(YRD3 — SOM §11.6)', () {
      final doc = SpecDocument();
      final item = doc.addListItem('D00/D00-ITM', sectionId: 'D01-CUSTOM');
      doc.setContent('$item/D01-LBL', 'Custom-id item');
      final md1 = _export(doc);
      expect(md1, contains('<!--[D01-CUSTOM]-->'));
      final (reloaded, report) = _reload(md1);
      expect(report.isClean, isTrue, reason: report.rejections.toString());
      final items = reloaded.listItems('D00/D00-ITM');
      expect(items, hasLength(1));
      // YRD3: the stored id is recovered from the heading.
      expect(reloaded.itemSectionId(items.single), 'D01-CUSTOM');
      expect(reloaded.content('${items.single}/D01-LBL'), 'Custom-id item');
      expect(_export(reloaded), md1);
    });

    test('a multi-line form value with a label-shaped continuation round-trips',
        () {
      final doc = SpecDocument()
        ..setFormField('D00/D00-HDR', 'author',
            'Ada Lovelace\nNote: also a mathematician\nplain line');
      final md1 = _export(doc);
      // The label-shaped continuation is space-escaped on emit.
      expect(md1, contains('\n Note: also a mathematician\n'));

      final (reloaded, report) = _reload(md1);
      expect(report.isClean, isTrue, reason: report.rejections.toString());
      expect(reloaded.formField('D00/D00-HDR', 'author'),
          'Ada Lovelace\nNote: also a mathematician\nplain line');
      expect(_export(reloaded), md1);
    });
  });

  group('parse-rejection protocol (SOM §11.7)', () {
    test('an unknown section id is reported; valid siblings still parsed', () {
      // The bogus heading is nested under `meta` (which has no list children);
      // directly under the root any unresolved id would be absorbed by the
      // single-list-child fallback as a stored-id item.
      const md = '<!-- docspec: demo-document/1.0 -->\n'
          '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-OVR]--> Overview\n\n'
          'kept\n\n'
          '## <!--[D00-MET]--> Meta\n\n'
          '### <!--[D00-NOPE]--> Bogus\n\n'
          'dropped\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(report.isClean, isFalse);
      expect(
        report.rejections.any((r) =>
            r.anchor == 'D00-NOPE' &&
            r.reason == SpecMarkdownRejectReason.unknownSection),
        isTrue,
      );
      expect(report.content['D00/D00-OVR'], 'kept');
    });

    test('a heading without a headline comment is malformed', () {
      const md = '<!-- docspec: demo-document/1.0 -->\n'
          '# <!--[D00]--> Demo Document\n\n'
          '## Overview without an id comment\n\n'
          'lost\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections
            .any((r) => r.reason == SpecMarkdownRejectReason.malformedHeading),
        isTrue,
      );
      expect(report.content, isEmpty);
    });

    test('text before the root heading is orphaned content', () {
      const md = 'stray preamble text\n'
          '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-OVR]--> Overview\n\n'
          'kept\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections
            .any((r) => r.reason == SpecMarkdownRejectReason.orphanContent),
        isTrue,
      );
      expect(report.content['D00/D00-OVR'], 'kept');
    });

    test('prose in a form section before the first label is orphaned', () {
      const md = '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-HDR]--> Header\n\n'
          'prose before any field label\n'
          'Author: Ada Lovelace\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections
            .any((r) => r.reason == SpecMarkdownRejectReason.orphanContent),
        isTrue,
      );
      // The labelled field still parses.
      expect(report.forms['D00/D00-HDR'], {'author': 'Ada Lovelace'});
    });

    test('a child heading under a content section is a kind mismatch', () {
      const md = '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-OVR]--> Overview\n\n'
          'kept\n\n'
          '### <!--[D00-MET-NOTE]--> Note\n\n'
          'misplaced\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections
            .any((r) => r.reason == SpecMarkdownRejectReason.kindMismatch),
        isTrue,
      );
      expect(report.content['D00/D00-OVR'], 'kept');
    });

    test('a value-leaf heading with an empty body is a missing value', () {
      const md = '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-OVR]--> Overview\n\n'
          '## <!--[D00-ST]--> Status\n\n'
          'final\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections.any((r) =>
            r.reason == SpecMarkdownRejectReason.missingValue &&
            r.anchor == 'D00/D00-OVR'),
        isTrue,
      );
      expect(report.content['D00/D00-ST'], 'final');
    });

    test('form field labels parse case-insensitively', () {
      const md = '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-HDR]--> Header\n\n'
          'author: lower-case label\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(report.isClean, isTrue, reason: report.rejections.toString());
      expect(report.forms['D00/D00-HDR'], {'author': 'lower-case label'});
    });

    test('heading-like lines inside a fenced block stay body text', () {
      const md = '# <!--[D00]--> Demo Document\n\n'
          '## <!--[D00-OVR]--> Overview\n\n'
          '```\n'
          '## <!--[D00-ST]--> not a real heading\n'
          '```\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(report.isClean, isTrue, reason: report.rejections.toString());
      expect(report.content['D00/D00-OVR'],
          '```\n## <!--[D00-ST]--> not a real heading\n```');
      expect(report.content.containsKey('D00/D00-ST'), isFalse);
    });
  });

  // YRD3: stored list-item ids — AA1 date-lettered ids
  // (`GOAL-ITEM-GN1`) or explicit overrides — ARE surfaced in the md item
  // heading and round-trip. The generated schema's `pattern-check-id` compiles
  // `@SectionIdPattern xxx` to `.+` (a STEM check, not a numbering check), so
  // a facade-authored document with generated ids exports to md that validates
  // cleanly against its own schema (som_multiplatform_spec_model.md §11.5, §13).
  group('YRD3 — AA1 generated ids export to schema-valid md', () {
    // A minimal document root whose only content is a patterned list, mirroring
    // the generated `goals` → `goal-item` structure the validator fixtures use.
    Map<String, dynamic> goalsJson() => {
          'roots': [
            {'type': 'GoalDoc', 'title': 'Goal Document', 'sectionId': 'D00'},
          ],
          'classes': {
            'GoalDoc': {
              'name': 'GoalDoc',
              'sectionId': 'D00',
              'fields': [
                {
                  'name': 'goals',
                  'kind': 'complex',
                  'type': 'Goals',
                  'sectionId': 'GOALS',
                },
              ],
            },
            'Goals': {
              'name': 'Goals',
              'sectionId': 'GOALS',
              'fields': [
                {
                  'name': 'goalItems',
                  'kind': 'list',
                  'sectionId': 'GOAL-ITEM-LST',
                  'sectionIdPattern': 'GOAL-ITEM-xxx',
                  'elementType': 'String',
                  'elementIsComplex': false,
                },
              ],
            },
          },
        };

    // The generated schema shape: `pattern-check-id` compiles `xxx` to
    // `.+` — a stem check (YRD3); numbering/uniqueness is runtime-owned. The
    // `-LST` container is a real section type (SOM §11.2/§13) with no content
    // (min/max-text-length 0) wrapping the element pattern type; section-types
    // are ordered longest-prefix-first so `GOAL_ITEM_LST` resolves to the
    // container and `GOAL_ITEM_1` to the item. Prefixes are in the DocSpecs
    // id-transform grammar (`-` → `_`); the pattern-check-id runs against the
    // raw heading id.
    const goalsSchemaYaml = '''
title-format: "# <!--[D00]--> Goal Document"
section-types:
  goal-item-lst:
    prefix: GOAL_ITEM_LST
    min-text-length: 0
    max-text-length: 0
    subsection-types:
      goal-item:
        min-count: 1
        max-count: infinite
  goal-item:
    prefix: GOAL_ITEM_
    pattern-check-id:
      pattern: "^GOAL-ITEM-.+\$"
      error-message: Goal item ids carry the GOAL-ITEM- stem
  goals:
    prefix: GOALS
    subsection-types:
      goal-item-lst:
        min-count: 1
        max-count: 1
document:
  sections:
    goals:
      section-type: goals
''';

    SpecModel model() => SpecModel.fromJson(goalsJson());

    // Author two items exactly as SomList.add does: AA1 date-lettered ids.
    SpecDocument authorWithAa1Ids() {
      final doc = SpecDocument();
      final date = DateTime(2026, 7, 14); // month 7 → G, day 14 → N
      const listPath = 'D00/GOALS/GOAL-ITEM-LST';
      final id1 = generateListItemSectionId('GOAL-ITEM-xxx', date, const []);
      final p1 = doc.addListItem(listPath, sectionId: id1);
      doc.setContent(p1, 'First goal.');
      final id2 = generateListItemSectionId('GOAL-ITEM-xxx', date, [id1]);
      final p2 = doc.addListItem(listPath, sectionId: id2);
      doc.setContent(p2, 'Second goal.');
      // Sanity: the generated ids carry the AA1 date-letter grammar, which
      // satisfies the `.+` stem check (`^GOAL-ITEM-.+$`) when surfaced.
      expect([id1, id2], ['GOAL-ITEM-GN1', 'GOAL-ITEM-GN2']);
      return doc;
    }

    test('the emitter surfaces stored AA1 ids in the item headings (YRD3)',
        () {
      final m = model();
      final md = SpecDocumentMarkdown(m, authorWithAa1Ids()).exportRoot(
        m.roots.single,
      );
      // The `-LST` container heads; items sit one level below it, each with
      // its stored id — the positional id is only the no-stored-id fallback.
      expect(md, contains('### <!--[GOAL-ITEM-LST]-->'));
      expect(md, contains('#### <!--[GOAL-ITEM-GN1]-->'));
      expect(md, contains('#### <!--[GOAL-ITEM-GN2]-->'));
      expect(md, isNot(contains('GOAL-ITEM-1]')));
      expect(md, isNot(contains('GOAL-ITEM-2]')));
    });

    test('the exported md validates cleanly against the .+ stem-check generated '
        'schema (YRD3 done-condition)', () {
      final m = model();
      final md = SpecDocumentMarkdown(m, authorWithAa1Ids()).exportRoot(
        m.roots.single,
      );
      final schema = DocSpecsSchema.fromYamlText(goalsSchemaYaml);
      expect(schema.warnings, isEmpty);
      final violations = DocSpecsValidator(schema).validateMarkdown(md);
      expect(violations, isEmpty, reason: violations.toString());
    });

    test('a stem-mismatched id is still rejected — the stem check has teeth',
        () {
      // Same document shape but one item id that does NOT carry the
      // `GOAL-ITEM-` stem; the `.+` stem check must flag it.
      const mdWithBogusId = '<!-- docspec: goal-document/1.0 -->\n'
          '# <!--[D00]--> Goal Document\n\n'
          '## <!--[GOALS]--> Goals\n\n'
          '### <!--[GOAL-ITEM-LST]--> Goal Items\n\n'
          '#### <!--[GOAL-ITEM-GN1]--> Goal Item 1\n\n'
          'First goal.\n\n'
          '#### <!--[GOAL-ITEM_BOGUS]--> Goal Item 2\n\n'
          'Second goal.\n';
      final schema = DocSpecsSchema.fromYamlText(goalsSchemaYaml);
      final violations =
          DocSpecsValidator(schema).validateMarkdown(mdWithBogusId);
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.rule == DocSpecsViolationRule.idPatternMismatch),
        isTrue,
        reason: violations.toString(),
      );
    });
  });
  group('YRD4 — @Headline default headlines', () {
    // A model with @Headline defaults on a field, an element class and a
    // list container; the precedence is stored headline > @Headline default >
    // name derivation, symmetric between export and import staging.
    Map<String, dynamic> headlineJson() => {
          'roots': [
            {
              'type': 'HDoc',
              'title': 'H Document',
              'sectionId': 'H00',
              'description': 'Headline demo.',
            },
          ],
          'classes': {
            'HDoc': {
              'name': 'HDoc',
              'sectionId': 'H00',
              'fields': [
                {
                  'name': 'overview',
                  'kind': 'content',
                  'sectionId': 'H00-OVR',
                  'headline': 'Executive Overview',
                },
                {
                  'name': 'plain',
                  'kind': 'content',
                  'sectionId': 'H00-PLN',
                },
                {
                  'name': 'items',
                  'kind': 'list',
                  'elementType': 'HItem',
                  'elementIsComplex': true,
                  'sectionId': 'H00-ITM',
                  'headline': 'Tracked Items',
                },
              ],
            },
            'HItem': {
              'name': 'HItem',
              'headline': 'Work Item',
              'fields': [
                {'name': 'label', 'kind': 'content', 'sectionId': 'H01-LBL'},
              ],
            },
          },
        };

    SpecModel model() => SpecModel.fromJson(headlineJson());

    SpecDocument populated() {
      final doc = SpecDocument()
        ..setContent('H00/H00-OVR', 'Overview body.')
        ..setContent('H00/H00-PLN', 'Plain body.');
      final item = doc.addListItem('H00/H00-ITM');
      doc.setContent('$item/H01-LBL', 'First');
      return doc;
    }

    String export(SpecDocument doc) =>
        SpecDocumentMarkdown(model(), doc).exportRoot(model().roots.single);

    test('@Headline default renders instead of the derived member title', () {
      final md = export(populated());
      expect(md, contains('## <!--[H00-OVR]--> Executive Overview'));
      // Unannotated sibling keeps the titleCase(memberName) derivation.
      expect(md, contains('## <!--[H00-PLN]--> Plain'));
      // List container + element-class @Headline drive container and stem.
      expect(md, contains('## <!--[H00-ITM]--> Tracked Items'));
      expect(md, contains('### <!--[items-1]--> Work Item 1'));
    });

    test('a stored headline wins over the @Headline default', () {
      final doc = populated()
        ..setHeadline('H00/H00-OVR', 'Custom Overview');
      final md = export(doc);
      expect(md, contains('## <!--[H00-OVR]--> Custom Overview'));
      expect(md, isNot(contains('Executive Overview')));
    });

    test('import stages a headline only when it differs from the default',
        () {
      final md = export(populated());
      final report = SpecDocumentMarkdown(model(), SpecDocument()).parse(md);
      // Rendering the defaults must not stage stored headlines (byte
      // stability, SOM §11.7): the parsed titles equal the effective defaults.
      expect(report.headlines, isEmpty, reason: report.headlines.toString());
      // A custom title in the md IS staged as a stored headline.
      final custom = md.replaceFirst('## <!--[H00-OVR]--> Executive Overview',
          '## <!--[H00-OVR]--> Renamed Overview');
      final report2 =
          SpecDocumentMarkdown(model(), SpecDocument()).parse(custom);
      expect(report2.headlines['H00/H00-OVR'], 'Renamed Overview');
    });

    test('stored → export → import round-trip is byte-stable', () {
      final doc = populated()
        ..setHeadline('H00/H00-OVR', 'Custom Overview');
      final md = export(doc);
      final report = SpecDocumentMarkdown(model(), SpecDocument()).parse(md);
      final target = SpecDocument()
        ..loadJson({
          'content': report.content,
          'forms': report.forms,
          'lists': report.lists,
          'headlines': report.headlines,
        });
      expect(export(target), md);
    });

    test('csmb1: a stored codeSpec rides in the headline comment', () {
      final doc = populated()
        ..setCodeSpec('H00/H00-OVR', 'CsOrder,CsOrder.total,CsOrderRepository');
      final md = export(doc);
      expect(
        md,
        contains('## <!--[H00-OVR] codeSpec="CsOrder,CsOrder.total,'
            'CsOrderRepository"--> Executive Overview'),
      );
      // Untouched sections stay byte-stable (no empty codeSpec attribute).
      expect(md, contains('## <!--[H00-PLN]--> Plain'));
    });

    test('csmb1: codeSpec is parsed back out of the headline comment', () {
      final doc = populated()
        ..setCodeSpec('H00/H00-OVR', 'CsOrder,CsOrder.total');
      final md = export(doc);
      final report = SpecDocumentMarkdown(model(), SpecDocument()).parse(md);
      expect(report.codeSpecs['H00/H00-OVR'], 'CsOrder,CsOrder.total');
    });

    test('csmb1: codeSpec + headline round-trip is byte-stable', () {
      final doc = populated()
        ..setHeadline('H00/H00-OVR', 'Custom Overview')
        ..setCodeSpec('H00/H00-OVR', 'CsOrder,CsOrder.total,CsOrderRepository');
      final md = export(doc);
      final report = SpecDocumentMarkdown(model(), SpecDocument()).parse(md);
      final target = SpecDocument()
        ..loadJson({
          'content': report.content,
          'forms': report.forms,
          'lists': report.lists,
          'headlines': report.headlines,
          'codeSpecs': report.codeSpecs,
        });
      expect(export(target), md);
      expect(target.codeSpec('H00/H00-OVR'),
          'CsOrder,CsOrder.total,CsOrderRepository');
    });
  });
}
