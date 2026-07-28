#!/usr/bin/env node
/**
 * Hierarchical `*.docspecs.yaml` v2 codec tests — a port of
 * `tom_som_javascript_runtime/tests/spec_document_yaml_test.js` (itself a port
 * of `tom_som_python_runtime/tests/spec_document_yaml_test.py` /
 * `tom_som_dart_runtime/test/spec_document_yaml_test.dart`).
 *
 * The codec walks the document root's SomMetaTree: sections nest, keys are
 * `<section-id> <member-name>`, list items key by stored section id (or an
 * anonymous positional `<member>-<n>`), body text uses the literal `content`
 * key, and form fields use their bare names. Round-trip is lossless modulo
 * the SOM §12.4 empty-line dedup; version-1 files and unmatched keys are
 * structured load errors.
 *
 * Build with `tsc`, then run `node dist/tests/spec_document_yaml_test.js`.
 * Exit code 0 == green.
 */

import {
  SpecDocument,
  SpecModel,
  SpecYamlFormatException,
  buildSomMetaTree,
  yamlDecode,
  yamlEncode,
} from '../src/index';

let _passed = 0;
const _failed: string[] = [];

function _check(name: string, condition: boolean, detail = ''): void {
  if (condition) {
    _passed++;
  } else {
    _failed.push(`${name}${detail ? ': ' + detail : ''}`);
  }
}

function _throwsFormat(fn: () => unknown, contains = ''): boolean {
  try {
    fn();
    return false;
  } catch (e) {
    if (e instanceof SpecYamlFormatException) {
      return e.message.includes(contains);
    }
    return false;
  }
}

/**
 * A model exercising every field kind: root body content, a content section
 * with a nested complex section, a complex list with `@SectionIdPattern`, a
 * scalar list, a `@Form` with a numeric field, enum and int leaves.
 */
function _model(): SpecModel {
  return SpecModel.fromJson({
    modelVersion: 1,
    roots: [{ type: 'Demo', title: 'Demo Document', sectionId: 'D00' }],
    classes: {
      Demo: {
        name: 'Demo',
        sectionId: 'D00',
        fields: [
          {
            name: 'overview',
            kind: 'content',
            sectionId: 'D00-OVR',
            serializationOrder: 0,
          },
          {
            name: 'scope',
            kind: 'complex',
            sectionId: 'D00-SCO',
            type: 'Scope',
            serializationOrder: 1,
          },
          {
            name: 'header',
            kind: 'form',
            sectionId: 'D00-HDR',
            serializationOrder: 2,
            formFields: [
              { name: 'author', label: 'Author', type: 'String' },
              { name: 'reviewer', label: 'Reviewer', type: 'String' },
              { name: 'revision', label: 'Revision', type: 'int' },
            ],
          },
          {
            name: 'requirements',
            kind: 'list',
            sectionId: 'D00-REQ',
            sectionIdPattern: 'REQ-xxx',
            elementType: 'Requirement',
            elementIsComplex: true,
            serializationOrder: 3,
          },
          {
            name: 'tags',
            kind: 'list',
            sectionId: 'D00-TAG',
            elementType: 'String',
            elementIsComplex: false,
            serializationOrder: 4,
          },
          {
            name: 'priority',
            kind: 'enum',
            sectionId: 'D00-PRI',
            enumType: 'Priority',
            enumValues: ['low', 'high'],
            serializationOrder: 5,
          },
          {
            name: 'count',
            kind: 'scalar',
            type: 'int',
            serializationOrder: 6,
          },
          {
            // Class-level-only @SectionId: the field carries no id, so its key
            // resolves to the target class's id (`CTRL control:`) — the SOM
            // SOM §12.2 fallback.
            name: 'control',
            kind: 'complex',
            type: 'Control',
            serializationOrder: 7,
          },
        ],
      },
      Control: {
        name: 'Control',
        sectionId: 'CTRL',
        fields: [
          { name: 'summary', kind: 'content', sectionId: 'CTRL-SUM' },
          { name: 'owner', kind: 'content' },
        ],
      },
      Scope: {
        name: 'Scope',
        fields: [
          { name: 'inScope', kind: 'content', sectionId: 'D00-INS' },
          { name: 'outOfScope', kind: 'content' },
        ],
      },
      Requirement: {
        name: 'Requirement',
        fields: [
          { name: 'text', kind: 'content' },
          {
            name: 'notes',
            kind: 'list',
            elementType: 'String',
            elementIsComplex: false,
          },
        ],
      },
    },
  });
}

const _TREE = buildSomMetaTree(_model());

function _enc(d: SpecDocument, stamp: string | null = null): string {
  return yamlEncode(d, _TREE, stamp);
}

function _dec(yaml: string) {
  return yamlDecode(yaml, _TREE);
}

function _roundTrip(d: SpecDocument): SpecDocument {
  return _dec(_enc(d)).document;
}

/** A populated document touching every store and the SOM §12.4 edge cases. */
function _populated(): SpecDocument {
  const doc = new SpecDocument();
  doc.setContent('D00', 'Preamble body text.');
  doc.setContent('D00/D00-OVR', 'line one\nline two\nline three');
  doc.setContent('D00/D00-SCO/D00-INS', '  indented first line\n    deeper');
  doc.setContent('D00/D00-SCO/outOfScope', 'ends with newline\n');
  doc.setContent('D00/D00-PRI', 'high');
  doc.setContent('D00/count', '3');
  doc.setFormField('D00/D00-HDR', 'author', 'Ada Lovelace');
  doc.setFormField('D00/D00-HDR', 'reviewer', 'Grace Hopper');
  doc.setFormField('D00/D00-HDR', 'revision', '7');
  const a = doc.addListItem('D00/D00-REQ', 'REQ-AB1');
  doc.setContent(`${a}/text`, 'value: with: colons # and hash');
  const n1 = doc.addListItem(`${a}/notes`);
  doc.setContent(n1, 'a nested scalar note');
  const b = doc.addListItem('D00/D00-REQ'); // anonymous item
  doc.setContent(`${b}/text`, 'second requirement');
  const t1 = doc.addListItem('D00/D00-TAG');
  doc.setContent(t1, 'alpha');
  return doc;
}

function testEncode(): void {
  // writes the v2 header, version and hierarchical structure
  const yaml = _enc(_populated(), '1.0');
  _check(
    'encode.header',
    yaml.startsWith(
      '# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n',
    ),
    yaml.split('\n')[0],
  );
  _check('encode.version', yaml.includes('version: 2\n'));
  _check('encode.stamp', yaml.includes('modelVersion: "1.0"\n'));
  _check('encode.rootKey', yaml.includes('\ndocument:\n  D00 Demo:\n'));
  _check(
    'encode.nesting',
    yaml.includes('\n    D00-SCO scope:\n      D00-INS inScope:'),
  );
  _check(
    'encode.rootContent',
    yaml.includes('\n    content: |2-\n      Preamble body text.\n'),
  );
  _check(
    'encode.storedItemId',
    yaml.includes('\n    D00-REQ requirements:\n      REQ-AB1:\n'),
  );
  _check('encode.anonItem', yaml.includes('\n      requirements-2:\n'));
  _check('encode.noFlatPaths', !yaml.includes('"D00/'));

  // sibling order follows @SerializationOrder, sparse emission
  const doc = new SpecDocument();
  doc.setContent('D00/D00-PRI', 'low'); // order 5
  doc.setContent('D00/D00-OVR', 'first'); // order 0
  const sparse = _enc(doc);
  _check(
    'encode.order',
    sparse.indexOf('D00-OVR overview:') < sparse.indexOf('D00-PRI priority:'),
  );
  _check('encode.sparse', !sparse.includes('D00-SCO'));

  // non-text values are plain scalars (SOM §12.5)
  const yaml2 = _enc(_populated());
  _check('encode.plainEnum', yaml2.includes('\n    D00-PRI priority: high\n'));
  _check('encode.plainInt', yaml2.includes('\n    count: 3\n'));
  _check('encode.plainFormInt', yaml2.includes('\n      revision: 7\n'));

  // YAML 1.1-special values are quoted, not plain (SOM §12.5). `on`/`no` are
  // 1.1-only booleans and `1:30` is a 1.1 sexagesimal int: plain strings under
  // YAML 1.2 but bool/number under YAML 1.1. They must emit as block scalars so
  // every runtime reads back the exact string; an ordinary token stays plain.
  const special = new SpecDocument();
  for (const v of ['on', 'no', '1:30', 'plain']) {
    special.setContent(special.addListItem('D00/D00-TAG'), v);
  }
  const yaml3 = _enc(special);
  _check('encode.yaml11.on', yaml3.includes('\n      tags-1: |2-\n        on\n'));
  _check('encode.yaml11.no', yaml3.includes('\n      tags-2: |2-\n        no\n'));
  _check(
    'encode.yaml11.sexagesimal',
    yaml3.includes('\n      tags-3: |2-\n        1:30\n'),
  );
  _check('encode.yaml11.plain', yaml3.includes('\n      tags-4: plain\n'));
  const outSpecial = _roundTrip(special);
  _check(
    'encode.yaml11.roundTrip',
    JSON.stringify(
      outSpecial.listItems('D00/D00-TAG').map((t) => outSpecial.content(t)),
    ) === JSON.stringify(['on', 'no', '1:30', 'plain']),
  );

  // an empty document emits `document: {}`
  _check('encode.emptyDoc', _enc(new SpecDocument()).includes('document: {}'));

  // the model-version stamp is omitted when absent
  _check(
    'encode.noStamp',
    !_enc(new SpecDocument()).includes('modelVersion:'),
  );

  // values the tree cannot place are a structured error
  const ghost = new SpecDocument();
  ghost.setContent('D00/ghost', 'x');
  _check('encode.leftoverError', _throwsFormat(() => _enc(ghost)));

  // an unknown form field is a structured error
  const bogus = new SpecDocument();
  bogus.setFormField('D00/D00-HDR', 'bogus', 'v');
  _check('encode.unknownFormField', _throwsFormat(() => _enc(bogus)));
}

function testRoundTrip(): void {
  // every value survives verbatim
  const out = _roundTrip(_populated());
  _check('rt.root', out.content('D00') === 'Preamble body text.');
  _check(
    'rt.overview',
    out.content('D00/D00-OVR') === 'line one\nline two\nline three',
  );
  _check(
    'rt.inScope',
    out.content('D00/D00-SCO/D00-INS') === '  indented first line\n    deeper',
  );
  _check(
    'rt.outOfScope',
    out.content('D00/D00-SCO/outOfScope') === 'ends with newline\n',
  );
  _check('rt.priority', out.content('D00/D00-PRI') === 'high');
  _check('rt.count', out.content('D00/count') === '3');
  _check('rt.author', out.formField('D00/D00-HDR', 'author') === 'Ada Lovelace');
  _check(
    'rt.reviewer',
    out.formField('D00/D00-HDR', 'reviewer') === 'Grace Hopper',
  );
  _check('rt.revision', out.formField('D00/D00-HDR', 'revision') === '7');
  _check('rt.reqCount', out.listItemCount('D00/D00-REQ') === 2);
  const items = out.listItems('D00/D00-REQ');
  _check('rt.item0.id', out.itemSectionId(items[0]) === 'REQ-AB1');
  _check('rt.item1.id', out.itemSectionId(items[1]) === null);
  _check(
    'rt.item0.text',
    out.content(`${items[0]}/text`) === 'value: with: colons # and hash',
  );
  _check(
    'rt.item1.text',
    out.content(`${items[1]}/text`) === 'second requirement',
  );
  const notes = out.listItems(`${items[0]}/notes`);
  _check(
    'rt.notes',
    notes.length === 1 && out.content(notes[0]) === 'a nested scalar note',
  );
  const tags = out.listItems('D00/D00-TAG');
  _check('rt.tags', tags.length === 1 && out.content(tags[0]) === 'alpha');

  // encode is byte-stable across decode → re-encode
  const yaml1 = _enc(_populated(), '1.2');
  const yaml2 = yamlEncode(_dec(yaml1).document, _TREE, '1.2');
  _check('rt.byteStable', yaml2 === yaml1);

  // the model-version stamp lands on the decoded document
  const decoded = _dec(_enc(_populated(), '2.5'));
  _check('rt.stamp.contents', decoded.modelVersion === '2.5');
  _check('rt.stamp.document', decoded.document.modelVersion === '2.5');

  // markdown edge cases survive
  const cases = [
    '\nleading blank line',
    'trailing blank line kept as one\n\nend',
    'two trailing newlines\n\n', // block cannot represent → JSON fallback
    'trailing space on a line \nnext',
    '\ttab\tpreserved',
    '- looks: like\n  yaml: [a, b]\n# comment-ish',
    '"double" and \'single\' quotes',
    'ends with newline\n',
    '   only-indentation-sensitive\n      nested deeper\n   back',
  ];
  for (let i = 0; i < cases.length; i++) {
    const doc = new SpecDocument();
    doc.setContent('D00/D00-OVR', cases[i]);
    const got = _roundTrip(doc).content('D00/D00-OVR');
    _check(
      `rt.edge[${i}]`,
      got === cases[i],
      `got ${JSON.stringify(got)} want ${JSON.stringify(cases[i])}`,
    );
  }

  // runs of 2+ empty lines collapse to one on write (SOM §12.4)
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'a\n\n\n\nb\n\n\nc');
  _check(
    'rt.emptyLineDedup',
    _roundTrip(doc).content('D00/D00-OVR') === 'a\n\nb\n\nc',
  );

  // an empty complex list item round-trips as `{}`
  const emptyItem = new SpecDocument();
  emptyItem.addListItem('D00/D00-REQ');
  const yaml3 = _enc(emptyItem);
  _check('rt.emptyItem.enc', yaml3.includes('requirements-1: {}'), yaml3);
  _check(
    'rt.emptyItem.count',
    _roundTrip(emptyItem).listItemCount('D00/D00-REQ') === 1,
  );
}

function testStrictDecode(): void {
  // version 1 files are rejected with a clear error
  _check(
    'decode.v1Rejected',
    _throwsFormat(() => _dec('version: 1\ndocument: {}\n'), 'version 1'),
  );

  // a missing version is rejected
  _check('decode.missingVersion', _throwsFormat(() => _dec('document: {}\n')));
  _check('decode.emptyText', _throwsFormat(() => _dec('')));

  // an unmatched key is a structured load error, not a silent skip
  const bad = 'version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n';
  _check('decode.unmatchedKey', _throwsFormat(() => _dec(bad), 'nonsense'));

  // a wrong root key is a structured load error
  _check(
    'decode.wrongRoot',
    _throwsFormat(() => _dec('version: 2\ndocument:\n  WRONG Other: {}\n')),
  );

  // an unknown form field on read is a structured load error
  const badForm =
    'version: 2\ndocument:\n  D00 Demo:\n' +
    '    D00-HDR header:\n      bogus: |-\n        v\n';
  _check('decode.unknownFormField', _throwsFormat(() => _dec(badForm)));

  // a missing/empty document pass decodes as an empty document
  _check('decode.noDocKey', _dec('version: 2\n').document.isEmpty);
  _check('decode.emptyDoc', _dec('version: 2\ndocument: {}\n').document.isEmpty);

  // the raw review pass is passed through untouched
  const fixture =
    'version: 2\n' +
    'document: {}\n' +
    'review:\n' +
    '  "D00/a":\n' +
    '    scope: global\n';
  const c = _dec(fixture);
  _check('decode.review', Object.keys(c.review).includes('D00/a'));
}

function testClassLevelOnlyKey(): void {
  // A section whose @SectionId lives only on the target class keys by that
  // class id (SOM §12.2 field-id-else-class-id). The `control` field carries no
  // id; its target class `Control` carries `CTRL`, so the key is `CTRL
  // control:`. The leaves keep their own content keys: `CTRL-SUM summary:`
  // (field id) and bare `owner:` (no id).
  const doc = new SpecDocument();
  doc.setContent('D00/control/CTRL-SUM', 'controlled summary');
  doc.setContent('D00/control/owner', 'the owner');
  const yaml = _enc(doc);
  _check('clskey.section', yaml.includes('\n    CTRL control:\n'), yaml);
  _check('clskey.leafId', yaml.includes('\n      CTRL-SUM summary:'), yaml);
  _check('clskey.leafBare', yaml.includes('\n      owner:'), yaml);
  const out = _roundTrip(doc);
  _check(
    'clskey.rt.summary',
    out.content('D00/control/CTRL-SUM') === 'controlled summary',
  );
  _check('clskey.rt.owner', out.content('D00/control/owner') === 'the owner');
}

// --- codespecs_mapping.md §9.2 codeSpec forward-link (csmc8)
// --------------------------------------

const _CODE_SPEC = 'CsOrder,CsOrder.total,CsOrderRepository';

function testCodeSpecRoundTrip(): void {
  // A stored codeSpec is emitted as a literal `codeSpec:` key mirroring the
  // stored headline — on the section's own mapping, next to `content`.
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'the overview body');
  doc.setCodeSpec('D00/D00-OVR', _CODE_SPEC);
  const yaml = _enc(doc);
  // The content leaf now serialises as a `{codeSpec: …, content: …}` mapping.
  _check('cs.enc.key', yaml.includes('codeSpec: |2-\n'), yaml);
  _check('cs.enc.value', yaml.includes(_CODE_SPEC), yaml);
  const out = _roundTrip(doc);
  _check('cs.rt.value', out.codeSpec('D00/D00-OVR') === _CODE_SPEC,
    String(out.codeSpec('D00/D00-OVR')));
  _check('cs.rt.content', out.content('D00/D00-OVR') === 'the overview body');
  // A sibling with no codeSpec stays null.
  _check('cs.rt.siblingNull', out.codeSpec('D00/D00-PRI') === null);
}

function testCodeSpecByteStable(): void {
  const doc = new SpecDocument();
  doc.setContent('D00/D00-OVR', 'body');
  doc.setCodeSpec('D00/D00-OVR', _CODE_SPEC);
  doc.setHeadline('D00/D00-OVR', 'Custom Overview');
  const yaml1 = _enc(doc, '1.0');
  const yaml2 = yamlEncode(_dec(yaml1).document, _TREE, '1.0');
  _check('cs.byteStable', yaml2 === yaml1, yaml2);
  const out = _dec(yaml1).document;
  _check('cs.byteStable.headline', out.headline('D00/D00-OVR') === 'Custom Overview');
  _check('cs.byteStable.codeSpec', out.codeSpec('D00/D00-OVR') === _CODE_SPEC);
}

function main(): number {
  testEncode();
  testRoundTrip();
  testStrictDecode();
  testClassLevelOnlyKey();
  testCodeSpecRoundTrip();
  testCodeSpecByteStable();

  const total = _passed + _failed.length;
  if (_failed.length > 0) {
    console.log(`FAIL: ${_failed.length}/${total} checks failed`);
    for (const f of _failed) {
      console.log(`  - ${f}`);
    }
    return 1;
  }
  console.log(`OK: ${total} checks passed`);
  return 0;
}

process.exit(main());
