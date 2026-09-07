/// Tests for the consolidated DocSpecs parsing + validation module (SOM §14):
/// the generic schema-free parse, schema loading (with warnings for
/// unsupported features), the structured violation list, and the
/// acceptance criterion — the markdown-codec-emitted Solution Blueprint sample validates
/// cleanly against the generated `solution-blueprint` schema.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

// ---------------------------------------------------------------------------
// Fixture schema (hand-written in the schema-generator output shape , SOM §13). The
// `pattern-check-id` here deliberately uses `[0-9]+` — a stricter regex than
// the `.+` stem check the schema generator emits since YRD3 — because these
// tests exercise the regex *mechanism* (the validator is regex-agnostic; any
// authored pattern is legal in a schema).
// ---------------------------------------------------------------------------

const _schemaYaml = '''
title-format: "# <!--[D00]--> Demo Document"
section-types:
  goal-item:
    prefix: GOAL_ITEM_
    pattern-check-id:
      pattern: "^GOAL-ITEM-[0-9]+\$"
      error-message: IDs of this section must match GOAL-ITEM-xxx
  d00-ovr:
    prefix: D00_OVR
    text-required: true
  d00-hdr:
    prefix: D00_HDR
    format: header-form
  gsum:
    prefix: GSUM
  diag:
    prefix: DIAG
    format: mermaid
  goals:
    prefix: GOALS
    subsection-types:
      goal-item:
        min-count: 1
        max-count: infinite
      gsum:
        max-count: 1
form-types:
  header-form:
    fields:
      - fieldname: author
        required: true
      - fieldname: reviewer
        pattern-check:
          pattern: "^[A-Z]"
          error-message: Reviewer must start with an uppercase letter
document:
  sections:
    d00-ovr:
      section-type: d00-ovr
    d00-hdr:
      section-type: d00-hdr
      optional: true
    goals:
      section-type: goals
      optional: true
    diag:
      section-type: diag
      optional: true
''';

const _validDoc = '''
<!-- docspec: demo-document/1.0 -->
# <!--[D00]--> Demo Document

Intro text.

## <!--[D00-OVR]--> Overview

Some overview text.

## <!--[D00-HDR]--> Header

Author: Alice
Reviewer: Bob

## <!--[GOALS]--> Goals

### <!--[GOAL-ITEM-1]--> Goal 1

First goal.

### <!--[GOAL-ITEM-2]--> Goal 2

Second goal.
''';

DocSpecsSchema _schema() => DocSpecsSchema.fromYamlText(_schemaYaml);

List<DocSpecsViolation> _validate(String md) =>
    DocSpecsValidator(_schema()).validateMarkdown(md);

void main() {
  group('DocSpecsDocument.parse (generic, schema-free)', () {
    test('builds the section tree with ids, titles, levels, and lines', () {
      final doc = DocSpecsDocument.parse(_validDoc);
      expect(doc.declaredSchema, 'demo-document/1.0');
      expect(doc.violations, isEmpty);
      expect(doc.sections, hasLength(1));
      final root = doc.sections.single;
      expect(root.id, 'D00');
      expect(root.title, 'Demo Document');
      expect(root.level, 1);
      expect(root.text, 'Intro text.');
      expect(root.children.map((c) => c.id), ['D00-OVR', 'D00-HDR', 'GOALS']);
      final goals = root.children.last;
      expect(goals.children.map((c) => c.id), ['GOAL-ITEM-1', 'GOAL-ITEM-2']);
      expect(goals.children.first.text, 'First goal.');
    });

    test('fenced code blocks shield heading-like lines', () {
      final doc = DocSpecsDocument.parse('''
# <!--[D00]--> Demo Document

```md
## <!--[NOT-A-SECTION]--> shielded
```
''');
      expect(doc.sections.single.children, isEmpty);
      expect(doc.sections.single.text, contains('NOT-A-SECTION'));
    });

    test('a heading without a headline comment is a malformedHeading', () {
      final doc = DocSpecsDocument.parse('''
# <!--[D00]--> Demo Document

## Plain Heading
''');
      expect(doc.violations, hasLength(1));
      final v = doc.violations.single;
      expect(v.rule, DocSpecsViolationRule.malformedHeading);
      expect(v.line, 3);
    });
  });

  group('DocSpecsSchema.fromYamlText', () {
    test('loads section-types, form-types, and document sections', () {
      final schema = _schema();
      expect(schema.warnings, isEmpty);
      expect(schema.rootSectionId, 'D00');
      expect(schema.sectionTypesByName.keys, contains('goal-item'));
      final goalItem = schema.sectionTypesByName['goal-item']!;
      expect(goalItem.prefix, 'GOAL_ITEM_');
      expect(goalItem.patternCheckId!.pattern, r'^GOAL-ITEM-[0-9]+$');
      final goals = schema.sectionTypesByName['goals']!;
      expect(goals.subsectionTypes['goal-item']!.minCount, 1);
      expect(goals.subsectionTypes['goal-item']!.maxCount, isNull);
      expect(goals.subsectionTypes['gsum']!.maxCount, 1);
      final form = schema.formTypes['header-form']!;
      expect(form.fields.map((f) => f.name), ['author', 'reviewer']);
      expect(form.fields.first.required, isTrue);
      expect(schema.documentSections['d00-ovr']!.optional, isFalse);
      expect(schema.documentSections['d00-hdr']!.optional, isTrue);
    });

    test('resolution is first-startsWith-match on the transformed id', () {
      final schema = _schema();
      expect(schema.resolveSectionType('GOAL-ITEM-7')!.name, 'goal-item');
      expect(schema.resolveSectionType('GOALS')!.name, 'goals');
      expect(schema.resolveSectionType('D00-OVR')!.name, 'd00-ovr');
      expect(schema.resolveSectionType('NOPE-1'), isNull);
    });

    test('unsupported features are ignored and named in warnings', () {
      final schema = DocSpecsSchema.fromYamlText('''
title-format: "# <!--[D00]--> Demo"
generators:
  something: true
section-types:
  d00-ovr:
    prefix: D00_OVR
    database-schema:
      table: t
document:
  sections:
    d00-ovr:
      section-type: d00-ovr
  custom-tag: x
''');
      expect(schema.warnings, hasLength(3));
      expect(schema.warnings.join('\n'), contains('generators'));
      expect(schema.warnings.join('\n'), contains('database-schema'));
      expect(schema.warnings.join('\n'), contains('custom-tag'));
      // The supported parts still load.
      expect(schema.sectionTypesByName['d00-ovr'], isNotNull);
    });
  });

  group('DocSpecsValidator.validate', () {
    test('a valid document produces zero violations', () {
      expect(_validate(_validDoc), isEmpty);
    });

    test('missing required section → missingRequiredSection, precise', () {
      final md = _validDoc.replaceFirst(
        RegExp(r'## <!--\[D00-OVR\]--> Overview\n\nSome overview text.\n\n'),
        '',
      );
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.missingRequiredSection);
      expect(v.single.sectionId, 'd00-ovr');
      expect(v.single.message, contains('d00-ovr'));
    });

    test('wrong section id → idPatternMismatch with the authored message', () {
      final md = _validDoc.replaceFirst('GOAL-ITEM-2', 'GOAL-ITEM-B');
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.idPatternMismatch);
      expect(v.single.sectionId, 'GOAL-ITEM-B');
      expect(v.single.message, 'IDs of this section must match GOAL-ITEM-xxx');
      expect(v.single.line, 21);
    });

    test('an unresolvable id → unknownSection', () {
      final md = _validDoc.replaceFirst(
        '### <!--[GOAL-ITEM-2]--> Goal 2',
        '### <!--[XYZ-2]--> Goal 2',
      );
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.unknownSection);
      expect(v.single.sectionId, 'XYZ-2');
    });

    test('a resolvable id in a disallowed position → unknownSection', () {
      final md = _validDoc.replaceFirst(
        '### <!--[GOAL-ITEM-2]--> Goal 2',
        '### <!--[DIAG]--> Diagram',
      );
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.unknownSection);
      expect(v.single.message, contains('not an allowed subsection'));
    });

    test('missing required form field → missingRequiredField', () {
      final md = _validDoc.replaceFirst('Author: Alice\n', '');
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.missingRequiredField);
      expect(v.single.sectionId, 'D00-HDR');
      expect(v.single.message, contains('author'));
    });

    test('form field pattern violation → fieldPatternMismatch at its line', () {
      final md = _validDoc.replaceFirst('Reviewer: Bob', 'Reviewer: bob');
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.fieldPatternMismatch);
      expect(v.single.message, 'Reviewer must start with an uppercase letter');
      expect(v.single.line, 13);
    });

    test('empty text-required section → textRequired', () {
      final md = _validDoc.replaceFirst('Some overview text.\n\n', '');
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.textRequired);
      expect(v.single.sectionId, 'D00-OVR');
    });

    test('too many singleton subsections → tooManyItems', () {
      final md =
          '$_validDoc\n'
          '### <!--[GSUM]--> Summary\n\nOne.\n\n'
          '### <!--[GSUM]--> Summary\n\nTwo.\n';
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.tooManyItems);
      expect(v.single.message, contains('gsum'));
    });

    test('non-form format without a fenced block → formatMismatch', () {
      final md = '$_validDoc\n## <!--[DIAG]--> Diagram\n\nno fence here\n';
      final v = _validate(md);
      expect(v, hasLength(1));
      expect(v.single.rule, DocSpecsViolationRule.formatMismatch);
      final ok =
          '$_validDoc\n## <!--[DIAG]--> Diagram\n\n'
          '```mermaid\ngraph TD;\n```\n';
      expect(_validate(ok), isEmpty);
    });

    test('root id mismatch vs title-format → formatMismatch', () {
      final md = _validDoc.replaceFirst('# <!--[D00]-->', '# <!--[D99]-->');
      final v = _validate(md);
      expect(
        v.map((x) => x.rule),
        contains(DocSpecsViolationRule.formatMismatch),
      );
    });

    test('all violations are collected — never fail-fast', () {
      final md = _validDoc
          .replaceFirst('Author: Alice\n', '')
          .replaceFirst('Reviewer: Bob', 'Reviewer: bob')
          .replaceFirst('GOAL-ITEM-2', 'GOAL-ITEM-B');
      final v = _validate(md);
      expect(v.map((x) => x.rule).toSet(), {
        DocSpecsViolationRule.missingRequiredField,
        DocSpecsViolationRule.fieldPatternMismatch,
        DocSpecsViolationRule.idPatternMismatch,
      });
    });
  });

  group('bindDocSpecsMarkdown', () {
    test('binds the markdown onto the SOM tree via the SOM §11.7 parse', () {
      final model = SpecModel.fromJson(
        jsonDecode(
              File(
                '../tom_som_conformance/corpus/model.meta.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final md = File(
        '../tom_som_conformance/corpus/expected.md',
      ).readAsStringSync();
      final result = bindDocSpecsMarkdown(model, SpecDocument(), md);
      expect(result.isClean, isTrue);
      expect(result.appliedCount, greaterThan(0));
    });
  });

  group('acceptance: emitted sample vs generated schema', () {
    test(
      'the Solution Blueprint sample emitted by the markdown codec (SOM §11) validates '
      'cleanly against the generated solution-blueprint schema',
      () {
        final model = SpecModel.fromJson(
          jsonDecode(
                File(
                  '../tom_som_dart_v0/meta/spec_model.meta.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>,
        );
        // The shared sample is a hierarchical-v2 `*.docspecs.yaml` (SOM §12):
        // decode it against the metadata tree bridged from the exported model.
        final document = SpecDocument.fromFile(
          '../tom_som_dart_v0/documents/meridian_order_management'
          '.docspecs.yaml',
          buildSomMetaTree(model, rootType: 'D00SolutionBlueprint'),
        );
        final md = document.toMarkdown(model);

        final schema = DocSpecsSchema.fromYamlText(
          File(
            '../tom_som_dart_v0/schemas/solution-blueprint/'
            'solution-blueprint.1.0.docspecs-schema.yaml',
          ).readAsStringSync(),
        );
        expect(schema.rootSectionId, 'SBP');

        final violations = DocSpecsValidator(schema).validateMarkdown(md);
        expect(
          violations,
          isEmpty,
          reason: violations.take(20).map((v) => '\n$v').join(),
        );
      },
    );
  });

  group('DocSpecsViolation.path (SOM §14)', () {
    // Always null from `validate`, which works schema-to-markdown and never
    // consults a SpecModel. That is a property of the tier, not evidence the
    // field is dead: `path` is a member of the SOM §14 violation structure,
    // which is specified as uniform across the nine runtimes, and all nine
    // render it the same way. These two tests are what make "not dead"
    // checkable rather than merely asserted in a comment.

    test('the validate tier leaves it null on every finding', () {
      final schema = DocSpecsSchema.fromYamlText(_demoSchemaYaml);
      final violations = DocSpecsValidator(
        schema,
      ).validateMarkdown('# <!--[NOPE]--> Wrong\n\nbody\n');
      expect(violations, isNotEmpty);
      for (final v in violations) {
        expect(v.path, isNull, reason: '$v');
      }
    });

    test('the renderer includes it when a binding tier supplies one', () {
      // The shared `line N: rule [sid] (path) — message` form, byte-for-byte
      // what the Rust, Java and C ports emit.
      final withPath = DocSpecsViolation(
        rule: DocSpecsViolationRule.textRequired,
        sectionId: 'DEMO-BODY',
        path: 'DEMO/body',
        line: 7,
        message: 'needs body text',
      );
      expect(
        withPath.toString(),
        'line 7: textRequired [DEMO-BODY] (DEMO/body) — needs body text',
      );
      final withoutPath = DocSpecsViolation(
        rule: DocSpecsViolationRule.textRequired,
        sectionId: 'DEMO-BODY',
        line: 7,
        message: 'needs body text',
      );
      expect(
        withoutPath.toString(),
        'line 7: textRequired [DEMO-BODY] — needs body text',
        reason: 'an absent path contributes nothing, not an empty "()"',
      );
    });
  });

  group('schema identity and the pre-flight mismatch check', () {
    test('the generated header comment carries the schema identity', () {
      // A comment, so the YAML loader drops it — parsing it is the only way to
      // recover the identity of a generated schema file.
      expect(
        DocSpecsSchema.fromYamlText(_demoSchemaYaml).schemaId,
        'demo-doc/1.0',
      );
    });

    test('a structured `schema:` key wins over the header comment', () {
      final schema = DocSpecsSchema.fromYamlText(
        '$_demoSchemaYaml\nschema: hand-written/2.0\n',
      );
      expect(schema.schemaId, 'hand-written/2.0');
      expect(
        schema.warnings.where((w) => w.contains('schema')),
        isEmpty,
        reason: 'it is read now, so it must not also be reported as ignored',
      );
    });

    test('a document declaring a different schema is a mismatch', () {
      final v = DocSpecsValidator(DocSpecsSchema.fromYamlText(_demoSchemaYaml));
      final doc = DocSpecsDocument.parse(
        '<!-- docspec: other-doc/1.0 -->\n\n# <!--[DEMO]--> Demo\n\nbody\n',
      );
      expect(doc.declaredSchema, 'other-doc/1.0');
      expect(v.schemaMismatch(doc), contains('other-doc/1.0'));
      expect(v.schemaMismatch(doc), contains('demo-doc/1.0'));
    });

    test('a document declaring the same schema is not a mismatch', () {
      final v = DocSpecsValidator(DocSpecsSchema.fromYamlText(_demoSchemaYaml));
      final doc = DocSpecsDocument.parse(
        '<!-- docspec: demo-doc/1.0 -->\n\n# <!--[DEMO]--> Demo\n\nbody\n',
      );
      expect(v.schemaMismatch(doc), isNull);
    });

    test('absence of a claim on either side is not a mismatch', () {
      // Two ways to have nothing to compare, and neither is evidence of a
      // conflict: a document with no header, and a schema with no identity.
      final withId = DocSpecsValidator(
        DocSpecsSchema.fromYamlText(_demoSchemaYaml),
      );
      expect(
        withId.schemaMismatch(
          DocSpecsDocument.parse('# <!--[DEMO]--> Demo\n\nbody\n'),
        ),
        isNull,
      );
      final noId = DocSpecsValidator(
        DocSpecsSchema.fromYamlText(
          'title-format: "# <!--[DEMO]--> Demo"\nsection-types:\n  demo:\n'
          '    prefix: DEMO\n',
        ),
      );
      expect(noId.schema.schemaId, isNull);
      expect(
        noId.schemaMismatch(
          DocSpecsDocument.parse(
            '<!-- docspec: other-doc/1.0 -->\n\n# <!--[DEMO]--> Demo\n\nb\n',
          ),
        ),
        isNull,
      );
    });

    test('validate itself is unchanged — the check is the caller-s', () {
      // Deliberately NOT folded in: the SOM §14 rule set is closed and uniform
      // across the nine runtimes, and Dart is the golden reference the other
      // eight are measured against. Emitting a rule the others cannot produce
      // would break that contract rather than extend it.
      final v = DocSpecsValidator(DocSpecsSchema.fromYamlText(_demoSchemaYaml));
      final doc = DocSpecsDocument.parse(
        '<!-- docspec: other-doc/1.0 -->\n\n# <!--[DEMO]--> Demo\n\nbody\n',
      );
      expect(v.schemaMismatch(doc), isNotNull);

      // The sharper statement than "validate finds nothing": validate finds
      // exactly what it would have found without the header at all. The
      // wrong-schema fact does not leak into the violation list, which is the
      // nine-runtime contract.
      //
      // Compared on rule + sectionId + message rather than the rendered
      // string, because the header legitimately shifts every line number by
      // the two lines it occupies — a difference in position, not in finding.
      final withoutHeader = DocSpecsDocument.parse(
        '# <!--[DEMO]--> Demo\n\nbody\n',
      );
      String finding(DocSpecsViolation x) =>
          '${x.rule.name}|${x.sectionId}|${x.message}';
      expect(
        v.validate(doc).map(finding),
        v.validate(withoutHeader).map(finding),
      );
      expect(
        v.validate(doc).where((x) => x.message.contains('other-doc')),
        isEmpty,
      );
    });
  });

  group('a form-type with case-colliding field names is refused', () {
    // Form field labels are matched case-insensitively against the document
    // body, so two declared fields differing only in case are
    // indistinguishable once a document is parsed: the later one wins the
    // lookup, and the earlier can never receive a value — a spurious
    // `missingRequiredField` when required, and a silently unchecked pattern
    // when not. That is a schema defect, so it is refused at load, in the same
    // spirit as an invalid `pattern` regex.
    //
    // No generated schema can produce it: verified across all 4,964 form types
    // the model emits. It is reachable only from a hand-written file, which is
    // exactly the input that has nobody checking it.

    test('the collision is reported with both names and the form', () {
      expect(
        () => DocSpecsSchema.fromYamlText(
          'form-types:\n'
          '  demo-form:\n'
          '    fields:\n'
          '      - fieldname: Owner\n'
          '      - fieldname: owner\n',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('demo-form'),
              contains('"Owner"'),
              contains('"owner"'),
            ),
          ),
        ),
      );
    });

    test('distinct names load normally', () {
      final schema = DocSpecsSchema.fromYamlText(
        'form-types:\n'
        '  demo-form:\n'
        '    fields:\n'
        '      - fieldname: Owner\n'
        '      - fieldname: reviewer\n',
      );
      expect(schema.formTypes['demo-form']!.fields, hasLength(2));
    });
  });
}

/// A minimal generated-shape schema: the `# Schema:` header comment the
/// generator emits, a title-format and one section type.
const _demoSchemaYaml =
    '# Generated from the TomSpecs object model — do not edit.\n'
    '# Schema: demo-doc/1.0\n'
    '\n'
    'title-format: "# <!--[DEMO]--> Demo"\n'
    'section-types:\n'
    '  demo:\n'
    '    prefix: DEMO\n'
    'document:\n'
    '  sections:\n'
    '    demo: {}\n';
