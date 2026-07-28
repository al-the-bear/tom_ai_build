#!/usr/bin/env node
'use strict';

/**
 * Tests for the consolidated DocSpecs parsing + validation module (SOM §14) —
 * a port of `tom_som_python_runtime/tests/docspecs_validator_test.py` (itself a
 * port of `tom_som_dart_runtime/test/docspecs_validator_test.dart`): the
 * generic schema-free parse, schema loading (with warnings for unsupported
 * features), the structured violation list, and the acceptance criterion —
 * the markdown-codec-emitted Solution Blueprint sample validates cleanly against the
 * generated `solution-blueprint` schema.
 *
 * Run with: `node tests/docspecs_validator_test.js`. Exit code 0 == green.
 */

const fs = require('fs');
const path = require('path');

const _HERE = __dirname;
const _PKG_ROOT = path.dirname(_HERE); // tom_som_javascript_runtime
const _SIBLINGS = path.dirname(_PKG_ROOT); // ai_build

const {
  DocSpecsDocument,
  DocSpecsSchema,
  DocSpecsValidator,
  DocSpecsViolationRule,
  SpecDocument,
  SpecModel,
  bindDocspecsMarkdown,
  buildSomMetaTree,
} = require('../tom_som_runtime');

let _passed = 0;
const _failed = [];

function _check(name, condition, detail = '') {
  if (condition) {
    _passed++;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

// ---------------------------------------------------------------------------
// Fixture schema (hand-written in the exact schema-generator output shape , SOM §13).
// ---------------------------------------------------------------------------

const _SCHEMA_YAML = `title-format: "# <!--[D00]--> Demo Document"
section-types:
  goal-item:
    prefix: GOAL_ITEM_
    pattern-check-id:
      pattern: "^GOAL-ITEM-[0-9]+$"
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
`;

const _VALID_DOC = `<!-- docspec: demo-document/1.0 -->
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
`;

function _schema() {
  return DocSpecsSchema.fromYamlText(_SCHEMA_YAML);
}

function _validate(md) {
  return new DocSpecsValidator(_schema()).validateMarkdown(md);
}

function _detail(violations) {
  return violations.map((v) => String(v)).join('; ');
}

function _listEqual(a, b) {
  return a.length === b.length && a.every((x, i) => x === b[i]);
}

// --- DocSpecsDocument.parse (generic, schema-free) ----------------------------

function testParseTree() {
  const doc = DocSpecsDocument.parse(_VALID_DOC);
  _check('parse.declaredSchema', doc.declaredSchema === 'demo-document/1.0', String(doc.declaredSchema));
  _check('parse.noViolations', doc.violations.length === 0, _detail(doc.violations));
  _check('parse.oneRoot', doc.sections.length === 1, String(doc.sections.length));
  const root = doc.sections[0];
  _check('parse.root.id', root.id === 'D00', String(root.id));
  _check('parse.root.title', root.title === 'Demo Document', root.title);
  _check('parse.root.level', root.level === 1, String(root.level));
  _check('parse.root.text', root.text === 'Intro text.', JSON.stringify(root.text));
  _check(
    'parse.root.children',
    _listEqual(root.children.map((c) => c.id), ['D00-OVR', 'D00-HDR', 'GOALS']),
    String(root.children.map((c) => c.id)),
  );
  const goals = root.children[root.children.length - 1];
  _check(
    'parse.goals.children',
    _listEqual(goals.children.map((c) => c.id), ['GOAL-ITEM-1', 'GOAL-ITEM-2']),
    String(goals.children.map((c) => c.id)),
  );
  _check('parse.goal1.text', goals.children[0].text === 'First goal.', JSON.stringify(goals.children[0].text));
}

function testParseFenceShield() {
  const doc = DocSpecsDocument.parse(
    '# <!--[D00]--> Demo Document\n' +
      '\n' +
      '```md\n' +
      '## <!--[NOT-A-SECTION]--> shielded\n' +
      '```\n',
  );
  _check('parse.fence.noChildren', doc.sections[0].children.length === 0);
  _check('parse.fence.bodyKept', doc.sections[0].text.includes('NOT-A-SECTION'));
}

function testParseMalformedHeading() {
  const doc = DocSpecsDocument.parse(
    '# <!--[D00]--> Demo Document\n' + '\n' + '## Plain Heading\n',
  );
  _check('parse.malformed.count', doc.violations.length === 1, _detail(doc.violations));
  if (doc.violations.length > 0) {
    const v = doc.violations[0];
    _check('parse.malformed.rule', v.rule === DocSpecsViolationRule.MALFORMED_HEADING, String(v));
    _check('parse.malformed.line', v.line === 3, String(v.line));
  }
}

// --- DocSpecsSchema.fromYamlText --------------------------------------------

function testSchemaLoading() {
  const schema = _schema();
  _check('schema.noWarnings', schema.warnings.length === 0, String(schema.warnings));
  _check('schema.rootSectionId', schema.rootSectionId === 'D00', String(schema.rootSectionId));
  _check('schema.goalItem.present', 'goal-item' in schema.sectionTypesByName);
  const goalItem = schema.sectionTypesByName['goal-item'];
  _check('schema.goalItem.prefix', goalItem.prefix === 'GOAL_ITEM_', goalItem.prefix);
  _check(
    'schema.goalItem.pattern',
    goalItem.patternCheck != null && goalItem.patternCheck.pattern === '^GOAL-ITEM-[0-9]+$',
    String(goalItem.patternCheck && goalItem.patternCheck.pattern),
  );
  const goals = schema.sectionTypesByName['goals'];
  _check('schema.goals.min', goals.subsectionTypes['goal-item'].minCount === 1);
  _check('schema.goals.maxInfinite', goals.subsectionTypes['goal-item'].maxCount == null);
  _check('schema.gsum.max1', goals.subsectionTypes['gsum'].maxCount === 1);
  const form = schema.formTypes['header-form'];
  _check(
    'schema.form.fields',
    _listEqual(form.fields.map((f) => f.name), ['author', 'reviewer']),
    String(form.fields.map((f) => f.name)),
  );
  _check('schema.form.authorRequired', form.fields[0].required);
  _check('schema.doc.ovrRequired', !schema.documentSections['d00-ovr'].optional);
  _check('schema.doc.hdrOptional', schema.documentSections['d00-hdr'].optional);
}

function testSchemaResolution() {
  const schema = _schema();
  const nameOf = (id) => {
    const t = schema.resolveSectionType(id);
    return t != null ? t.name : null;
  };
  _check('resolve.goalItem', nameOf('GOAL-ITEM-7') === 'goal-item', String(nameOf('GOAL-ITEM-7')));
  _check('resolve.goals', nameOf('GOALS') === 'goals', String(nameOf('GOALS')));
  _check('resolve.ovr', nameOf('D00-OVR') === 'd00-ovr', String(nameOf('D00-OVR')));
  _check('resolve.none', nameOf('NOPE-1') === null, String(nameOf('NOPE-1')));
}

function testSchemaWarnings() {
  const schema = DocSpecsSchema.fromYamlText(
    'title-format: "# <!--[D00]--> Demo"\n' +
      'generators:\n' +
      '  something: true\n' +
      'section-types:\n' +
      '  d00-ovr:\n' +
      '    prefix: D00_OVR\n' +
      '    database-schema:\n' +
      '      table: t\n' +
      'document:\n' +
      '  sections:\n' +
      '    d00-ovr:\n' +
      '      section-type: d00-ovr\n' +
      '  custom-tag: x\n',
  );
  _check('warnings.count', schema.warnings.length === 3, String(schema.warnings));
  const joined = schema.warnings.join('\n');
  _check('warnings.generators', joined.includes('generators'), joined);
  _check('warnings.databaseSchema', joined.includes('database-schema'), joined);
  _check('warnings.customTag', joined.includes('custom-tag'), joined);
  // The supported parts still load.
  _check('warnings.stillLoads', schema.sectionTypesByName['d00-ovr'] != null);
}

// --- DocSpecsValidator.validate ------------------------------------------------

function testValidateValid() {
  const v = _validate(_VALID_DOC);
  _check('validate.valid.empty', v.length === 0, _detail(v));
}

function testValidateMissingRequiredSection() {
  const md = _VALID_DOC.replace(
    '## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n',
    '',
  );
  const v = _validate(md);
  _check('validate.missingSection.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check(
      'validate.missingSection.rule',
      v[0].rule === DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
      String(v[0]),
    );
    _check('validate.missingSection.id', v[0].sectionId === 'd00-ovr', String(v[0].sectionId));
    _check('validate.missingSection.msg', v[0].message.includes('d00-ovr'), v[0].message);
  }
}

function testValidateIdPatternMismatch() {
  const md = _VALID_DOC.replace('GOAL-ITEM-2', 'GOAL-ITEM-B');
  const v = _validate(md);
  _check('validate.idPattern.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check(
      'validate.idPattern.rule',
      v[0].rule === DocSpecsViolationRule.ID_PATTERN_MISMATCH,
      String(v[0]),
    );
    _check('validate.idPattern.id', v[0].sectionId === 'GOAL-ITEM-B', String(v[0].sectionId));
    _check(
      'validate.idPattern.msg',
      v[0].message === 'IDs of this section must match GOAL-ITEM-xxx',
      v[0].message,
    );
    _check('validate.idPattern.line', v[0].line === 21, String(v[0].line));
  }
}

function testValidateUnknownSection() {
  const md = _VALID_DOC.replace('### <!--[GOAL-ITEM-2]--> Goal 2', '### <!--[XYZ-2]--> Goal 2');
  const v = _validate(md);
  _check('validate.unknown.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check('validate.unknown.rule', v[0].rule === DocSpecsViolationRule.UNKNOWN_SECTION, String(v[0]));
    _check('validate.unknown.id', v[0].sectionId === 'XYZ-2', String(v[0].sectionId));
  }
}

function testValidateDisallowedPosition() {
  const md = _VALID_DOC.replace('### <!--[GOAL-ITEM-2]--> Goal 2', '### <!--[DIAG]--> Diagram');
  const v = _validate(md);
  _check('validate.disallowed.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check(
      'validate.disallowed.rule',
      v[0].rule === DocSpecsViolationRule.UNKNOWN_SECTION,
      String(v[0]),
    );
    _check(
      'validate.disallowed.msg',
      v[0].message.includes('not an allowed subsection'),
      v[0].message,
    );
  }
}

function testValidateMissingRequiredField() {
  const md = _VALID_DOC.replace('Author: Alice\n', '');
  const v = _validate(md);
  _check('validate.missingField.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check(
      'validate.missingField.rule',
      v[0].rule === DocSpecsViolationRule.MISSING_REQUIRED_FIELD,
      String(v[0]),
    );
    _check('validate.missingField.id', v[0].sectionId === 'D00-HDR', String(v[0].sectionId));
    _check('validate.missingField.msg', v[0].message.includes('author'), v[0].message);
  }
}

function testValidateFieldPatternMismatch() {
  const md = _VALID_DOC.replace('Reviewer: Bob', 'Reviewer: bob');
  const v = _validate(md);
  _check('validate.fieldPattern.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check(
      'validate.fieldPattern.rule',
      v[0].rule === DocSpecsViolationRule.FIELD_PATTERN_MISMATCH,
      String(v[0]),
    );
    _check(
      'validate.fieldPattern.msg',
      v[0].message === 'Reviewer must start with an uppercase letter',
      v[0].message,
    );
    _check('validate.fieldPattern.line', v[0].line === 13, String(v[0].line));
  }
}

function testValidateTextRequired() {
  const md = _VALID_DOC.replace('Some overview text.\n\n', '');
  const v = _validate(md);
  _check('validate.textRequired.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check('validate.textRequired.rule', v[0].rule === DocSpecsViolationRule.TEXT_REQUIRED, String(v[0]));
    _check('validate.textRequired.id', v[0].sectionId === 'D00-OVR', String(v[0].sectionId));
  }
}

function testValidateTooManyItems() {
  const md =
    `${_VALID_DOC}\n` +
    '### <!--[GSUM]--> Summary\n\nOne.\n\n' +
    '### <!--[GSUM]--> Summary\n\nTwo.\n';
  const v = _validate(md);
  _check('validate.tooMany.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check('validate.tooMany.rule', v[0].rule === DocSpecsViolationRule.TOO_MANY_ITEMS, String(v[0]));
    _check('validate.tooMany.msg', v[0].message.includes('gsum'), v[0].message);
  }
}

function testValidateFormatMismatch() {
  const md = `${_VALID_DOC}\n## <!--[DIAG]--> Diagram\n\nno fence here\n`;
  const v = _validate(md);
  _check('validate.format.count', v.length === 1, _detail(v));
  if (v.length > 0) {
    _check('validate.format.rule', v[0].rule === DocSpecsViolationRule.FORMAT_MISMATCH, String(v[0]));
  }
  const ok = `${_VALID_DOC}\n## <!--[DIAG]--> Diagram\n\n` + '```mermaid\ngraph TD;\n```\n';
  const vOk = _validate(ok);
  _check('validate.format.fencedOk', vOk.length === 0, _detail(vOk));
}

function testValidateRootMismatch() {
  const md = _VALID_DOC.replace('# <!--[D00]-->', '# <!--[D99]-->');
  const v = _validate(md);
  _check(
    'validate.rootMismatch.rule',
    v.some((x) => x.rule === DocSpecsViolationRule.FORMAT_MISMATCH),
    _detail(v),
  );
}

function testValidateNeverFailFast() {
  const md = _VALID_DOC.replace('Author: Alice\n', '')
    .replace('Reviewer: Bob', 'Reviewer: bob')
    .replace('GOAL-ITEM-2', 'GOAL-ITEM-B');
  const v = _validate(md);
  const got = [...new Set(v.map((x) => x.rule))].sort();
  const want = [
    DocSpecsViolationRule.MISSING_REQUIRED_FIELD,
    DocSpecsViolationRule.FIELD_PATTERN_MISMATCH,
    DocSpecsViolationRule.ID_PATTERN_MISMATCH,
  ].sort();
  _check('validate.neverFailFast', _listEqual(got, want), `${got} != ${want}`);
}

// --- bindDocspecsMarkdown ----------------------------------------------------

function testBindDocspecsMarkdown() {
  const corpus = path.join(_SIBLINGS, 'tom_som_conformance', 'corpus');
  const model = SpecModel.fromJson(
    JSON.parse(fs.readFileSync(path.join(corpus, 'model.meta.json'), 'utf8')),
  );
  const md = fs.readFileSync(path.join(corpus, 'expected.md'), 'utf8');
  const result = bindDocspecsMarkdown(model, new SpecDocument(), md);
  _check('bind.clean', result.isClean, result.rejections.map((r) => String(r)).join('; '));
  _check('bind.appliedCount', result.appliedCount > 0, String(result.appliedCount));
}

// --- acceptance: emitted sample vs generated schema ----------------------------

// The Solution Blueprint sample emitted by the markdown codec (SOM §11) validates cleanly
// against the generated `solution-blueprint` schema.
function testDr7Acceptance() {
  const metaPath = path.join(_SIBLINGS, 'tom_som_dart_v0', 'meta', 'spec_model.meta.json');
  const model = SpecModel.fromJson(JSON.parse(fs.readFileSync(metaPath, 'utf8')));
  // The shared sample is a hierarchical-v2 `*.docspecs.yaml` (SOM §12): decode it
  // against the metadata tree bridged from the exported model.
  const samplePath = path.join(
    _SIBLINGS,
    'tom_som_conformance',
    'samples',
    'meridian_order_management.docspecs.yaml',
  );
  const document = SpecDocument.fromFile(
    samplePath,
    buildSomMetaTree(model, 'D00SolutionBlueprint'),
  );
  const md = document.toMarkdown(model);

  const schemaPath = path.join(
    _SIBLINGS,
    'tom_som_dart_v0',
    'schemas',
    'solution-blueprint',
    'solution-blueprint.1.0.docspecs-schema.yaml',
  );
  const schema = DocSpecsSchema.fromYamlText(fs.readFileSync(schemaPath, 'utf8'));
  _check('dr7.rootSectionId', schema.rootSectionId === 'SBP', String(schema.rootSectionId));

  const violations = new DocSpecsValidator(schema).validateMarkdown(md);
  _check(
    'dr7.violationsEmpty',
    violations.length === 0,
    violations.slice(0, 20).map((v) => `\n${v}`).join(''),
  );
}

function main() {
  testParseTree();
  testParseFenceShield();
  testParseMalformedHeading();
  testSchemaLoading();
  testSchemaResolution();
  testSchemaWarnings();
  testValidateValid();
  testValidateMissingRequiredSection();
  testValidateIdPatternMismatch();
  testValidateUnknownSection();
  testValidateDisallowedPosition();
  testValidateMissingRequiredField();
  testValidateFieldPatternMismatch();
  testValidateTextRequired();
  testValidateTooManyItems();
  testValidateFormatMismatch();
  testValidateRootMismatch();
  testValidateNeverFailFast();
  testBindDocspecsMarkdown();
  testDr7Acceptance();

  const total = _passed + _failed.length;
  if (_failed.length > 0) {
    process.stdout.write(`FAIL: ${_failed.length}/${total} checks failed\n`);
    for (const f of _failed) {
      process.stdout.write(`  - ${f}\n`);
    }
    return 1;
  }
  process.stdout.write(`OK: ${total} checks passed\n`);
  return 0;
}

process.exit(main());
