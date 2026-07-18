#!/usr/bin/env node
'use strict';

/**
 * DR4 metadata-core tests — a port of
 * `tom_som_python_runtime/tests/spec_meta_test.py` (itself a port of
 * `tom_som_dart_runtime/test/spec_meta_test.dart`).
 *
 * Hand-built DR1 §3.1 fixture tree mirroring the design doc's demo document
 * (DR4 acceptance: "the runtime compiles with a hand-built fixture tree").
 *
 * Structure:
 *
 *   DEMO D99DemoDocument                      (@Document)
 *     INSC introductionAndScope               (section, class-level id)
 *       summary                               (content, no id)
 *       GOAL goals                            (section)
 *         GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
 *           [element GoalEntry]
 *             text                            (content)
 *             subTasks                        (nested list of TaskEntry)
 *               [element TaskEntry]  note     (content)
 *     DOCO documentControl                    (form)
 *     RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
 *     PHASE-2 phaseTwo                        (hyphen+digit section id)
 *     related                                 (recursive re-entry)
 *     OLD legacy                              (@Unused content)
 *     tags                                    (scalar list, no element node)
 *
 * Run with: `node tests/spec_meta_test.js`. Exit code 0 == all green.
 */

const {
  SomContentTypeMeta,
  SomDocMeta,
  SomFormFieldMeta,
  SomFormMeta,
  SomMetaExtra,
  SomMetaKind,
  SomMetaNode,
  SomMetaTree,
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

function _raises(fn) {
  try {
    fn();
    return false;
  } catch (e) {
    return e instanceof Error;
  }
}

function buildFixtureTree() {
  const element = new SomMetaNode({
    className: 'GoalEntry',
    kind: SomMetaKind.SECTION,
    typeName: 'GoalEntry',
    docComment: 'One programme goal.',
    children: [
      new SomMetaNode({
        className: 'GoalEntry',
        memberName: 'text',
        kind: SomMetaKind.CONTENT,
        typeName: 'String',
        serializationOrder: 1,
      }),
      new SomMetaNode({
        className: 'GoalEntry',
        memberName: 'subTasks',
        sectionIdPattern: 'GOAL-TASK-xxx',
        kind: SomMetaKind.LIST,
        typeName: 'List<TaskEntry>',
        serializationOrder: 2,
        elementNode: new SomMetaNode({
          className: 'TaskEntry',
          kind: SomMetaKind.SECTION,
          typeName: 'TaskEntry',
          children: [
            new SomMetaNode({
              className: 'TaskEntry',
              memberName: 'note',
              kind: SomMetaKind.CONTENT,
              typeName: 'String',
            }),
          ],
        }),
      }),
    ],
  });

  const risk = (member) =>
    new SomMetaNode({
      className: 'Risk',
      memberName: member,
      sectionId: 'RISK',
      kind: SomMetaKind.COMPLEX,
      typeName: 'Risk',
      classDocComment: 'A programme risk.',
      children: [
        new SomMetaNode({
          className: 'Risk',
          memberName: 'probability',
          kind: SomMetaKind.ENUM_VALUE,
          typeName: 'Probability',
        }),
      ],
    });

  const root = new SomMetaNode({
    className: 'D99DemoDocument',
    sectionId: 'DEMO',
    kind: SomMetaKind.SECTION,
    typeName: 'D99DemoDocument',
    document: new SomDocMeta({
      name: 'Demo Document',
      description: 'The demo specification document.',
      basedOn: ['D00SolutionBlueprint'],
    }),
    docComment: 'Root of the demo document.',
    children: [
      new SomMetaNode({
        className: 'IntroductionAndScope',
        memberName: 'introductionAndScope',
        sectionId: 'INSC',
        kind: SomMetaKind.SECTION,
        typeName: 'IntroductionAndScope',
        serializationOrder: 1,
        contentHelp: 'Describe why the system exists.',
        comment: 'Keep this short.',
        mapsTo: 'CurrentLandscape',
        detailedIn: 'D01RequirementsSpecification',
        children: [
          new SomMetaNode({
            className: 'IntroductionAndScope',
            memberName: 'summary',
            kind: SomMetaKind.CONTENT,
            typeName: 'String',
            min: 1,
            serializationOrder: 1,
            contentType: new SomContentTypeMeta(
              'diagram',
              'A mermaid context diagram.',
            ),
            docComment: 'What the system covers.',
          }),
          new SomMetaNode({
            className: 'Goals',
            memberName: 'goals',
            sectionId: 'GOAL',
            kind: SomMetaKind.SECTION,
            typeName: 'Goals',
            serializationOrder: 2,
            children: [
              new SomMetaNode({
                className: 'Goals',
                memberName: 'entries',
                sectionId: 'GOAL-ITEM-LST',
                sectionIdPattern: 'GOAL-ITEM-xxx',
                kind: SomMetaKind.LIST,
                typeName: 'List<GoalEntry>',
                min: 1,
                extra: [new SomMetaExtra('Max', { count: 4 })],
                elementNode: element,
              }),
            ],
          }),
        ],
      }),
      new SomMetaNode({
        className: 'DocumentControl',
        memberName: 'documentControl',
        sectionId: 'DOCO',
        kind: SomMetaKind.FORM,
        typeName: 'DocumentControl',
        serializationOrder: 2,
        form: new SomFormMeta([
          new SomFormFieldMeta({
            name: 'version',
            typeName: 'String',
            description: 'Version',
            required: true,
            hint: 'e.g. 1.0',
            order: 1,
          }),
          new SomFormFieldMeta({
            name: 'approvedBy',
            typeName: 'String',
            order: 2,
          }),
          new SomFormFieldMeta({
            name: 'reviewCount',
            typeName: 'int',
            order: 3,
          }),
        ]),
      }),
      risk('primaryRisk'),
      risk('fallbackRisk'),
      new SomMetaNode({
        className: 'PhaseTwo',
        memberName: 'phaseTwo',
        sectionId: 'PHASE-2',
        kind: SomMetaKind.SECTION,
        typeName: 'PhaseTwo',
        children: [
          new SomMetaNode({
            className: 'PhaseTwo',
            memberName: 'outline',
            kind: SomMetaKind.CONTENT,
            typeName: 'String',
          }),
        ],
      }),
      new SomMetaNode({
        className: 'D99DemoDocument',
        memberName: 'related',
        kind: SomMetaKind.COMPLEX,
        typeName: 'D99DemoDocument',
        recursive: true,
      }),
      new SomMetaNode({
        className: 'D99DemoDocument',
        memberName: 'legacy',
        sectionId: 'OLD',
        kind: SomMetaKind.CONTENT,
        typeName: 'String',
        unused: true,
      }),
      new SomMetaNode({
        className: 'D99DemoDocument',
        memberName: 'tags',
        kind: SomMetaKind.LIST,
        typeName: 'List<String>',
      }),
    ],
  });
  return new SomMetaTree(root);
}

function testWiring() {
  const tree = buildFixtureTree();

  // root path is the root segment and parent is null
  _check('wiring.root.path', tree.root.path === 'DEMO', String(tree.root.path));
  _check('wiring.root.segment', tree.root.segment === 'DEMO');
  _check('wiring.root.parent', tree.root.parent === null);
  _check('wiring.root.doc.name', tree.root.document.name === 'Demo Document');
  _check(
    'wiring.root.doc.basedOn',
    JSON.stringify(tree.root.document.basedOn) ===
      JSON.stringify(['D00SolutionBlueprint']),
  );

  // child paths follow the §4 grammar (sectionId ?? memberName)
  const insc = tree.root.childByMember('introductionAndScope');
  _check('wiring.insc.path', insc.path === 'DEMO/INSC', String(insc.path));
  _check(
    'wiring.summary.path',
    insc.childByMember('summary').path === 'DEMO/INSC/summary',
  );
  const entries = insc.childByMember('goals').childByMember('entries');
  _check(
    'wiring.entries.path',
    entries.path === 'DEMO/INSC/GOAL/GOAL-ITEM-LST',
    String(entries.path),
  );

  // parent links are wired for children and element subtrees
  _check('wiring.entries.parent', entries.parent.segment === 'GOAL');
  _check('wiring.element.parent', entries.elementNode.parent === entries);
  _check(
    'wiring.element.child.parent',
    entries.elementNode.children[0].parent === entries.elementNode,
  );

  // element subtree nodes carry no static path
  const entries2 = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST');
  const element = entries2.elementNode;
  _check('wiring.element.path', element.path === null);
  _check(
    'wiring.element.text.path',
    element.childByMember('text').path === null,
  );
  _check(
    'wiring.element.subTasks.path',
    element.childByMember('subTasks').path === null,
  );

  // allNodes covers children and element subtrees in document order
  const names = tree.allNodes.map((n) => n.debugName);
  _check('wiring.allNodes.first', names[0] === 'D99DemoDocument', names[0]);
  _check('wiring.allNodes.goalEntry', names.includes('GoalEntry'));
  _check('wiring.allNodes.taskNote', names.includes('TaskEntry.note'));
  _check('wiring.allNodes.fallbackRisk', names.includes('Risk.fallbackRisk'));
  _check(
    'wiring.allNodes.elementAfterList',
    names.indexOf('GoalEntry') > names.indexOf('Goals.entries'),
  );

  // a root without @Document metadata is rejected
  _check(
    'wiring.noDocumentRejected',
    _raises(
      () =>
        new SomMetaTree(
          new SomMetaNode({
            className: 'X',
            kind: SomMetaKind.SECTION,
            typeName: 'X',
          }),
        ),
    ),
  );

  // a node belongs to exactly one tree
  _check('wiring.oneTreeRule', _raises(() => new SomMetaTree(tree.root)));

  // an unattached node refuses path/parent access
  const loose = new SomMetaNode({
    className: 'X',
    kind: SomMetaKind.SCALAR,
    typeName: 'int',
  });
  _check('wiring.loose.path', _raises(() => loose.path));
  _check('wiring.loose.parent', _raises(() => loose.parent));
}

function testMetadataSlots() {
  const tree = buildFixtureTree();

  // section node carries help, comment and traceability links
  const insc = tree.byId('INSC');
  _check(
    'slots.insc.help',
    insc.contentHelp === 'Describe why the system exists.',
  );
  _check('slots.insc.comment', insc.comment === 'Keep this short.');
  _check('slots.insc.mapsTo', insc.mapsTo === 'CurrentLandscape');
  _check(
    'slots.insc.detailedIn',
    insc.detailedIn === 'D01RequirementsSpecification',
  );
  _check('slots.insc.order', insc.serializationOrder === 1);

  // content node carries @Min, @ContentType and doc comment
  const summary = tree.byPath('DEMO/INSC/summary');
  _check('slots.summary.kind', summary.kind === SomMetaKind.CONTENT);
  _check('slots.summary.min', summary.min === 1);
  _check('slots.summary.ct.type', summary.contentType.type === 'diagram');
  _check(
    'slots.summary.ct.desc',
    summary.contentType.description === 'A mermaid context diagram.',
  );
  _check('slots.summary.doc', summary.docComment === 'What the system covers.');

  // form node exposes fields with description/required/hint/order
  const form = tree.byId('DOCO').form;
  _check(
    'slots.form.fields',
    JSON.stringify(form.fields.map((f) => f.name)) ===
      JSON.stringify(['version', 'approvedBy', 'reviewCount']),
  );
  const version = form.fieldNamed('version');
  _check('slots.form.version.required', version.required === true);
  _check('slots.form.version.hint', version.hint === 'e.g. 1.0');
  _check('slots.form.version.desc', version.description === 'Version');
  _check('slots.form.version.order', version.order === 1);
  _check(
    'slots.form.approvedBy.required',
    form.fieldNamed('approvedBy').required === false,
  );
  _check('slots.form.missing', form.fieldNamed('missing') === null);

  // list node carries @Min plus the lossless extra list (@Max)
  const entries = tree.byId('GOAL-ITEM-LST');
  _check('slots.entries.kind', entries.kind === SomMetaKind.LIST);
  _check('slots.entries.min', entries.min === 1);
  _check('slots.entries.pattern', entries.sectionIdPattern === 'GOAL-ITEM-xxx');
  _check(
    'slots.entries.extra',
    entries.extra.length === 1 &&
      entries.extra[0].annotation === 'Max' &&
      entries.extra[0].args['count'] === 4,
  );

  // @Unused and recursive flags are carried
  _check('slots.old.unused', tree.byId('OLD').unused === true);
  const related = tree.root.childByMember('related');
  _check('slots.related.recursive', related.recursive === true);
  _check('slots.related.children', related.children.length === 0);

  // class doc comment is carried where it differs from the member one
  _check(
    'slots.risk.classDoc',
    tree.byId('RISK').classDocComment === 'A programme risk.',
  );
}

function testById() {
  const tree = buildFixtureTree();

  // resolves an exact section id
  _check('byId.demo', tree.byId('DEMO') === tree.root);
  _check('byId.goal', tree.byId('GOAL').memberName === 'goals');

  // a shared class at two positions: first wins, allById has both
  _check('byId.risk.first', tree.byId('RISK').memberName === 'primaryRisk');
  _check(
    'byId.risk.all',
    JSON.stringify(tree.allById('RISK').map((n) => n.memberName)) ===
      JSON.stringify(['primaryRisk', 'fallbackRisk']),
  );

  // a resolved @SectionIdPattern id resolves to the element subtree
  const element = tree.byId('GOAL-ITEM-3');
  _check('byId.pattern.class', element.className === 'GoalEntry');
  _check(
    'byId.pattern.element',
    element === tree.byId('GOAL-ITEM-LST').elementNode,
  );
  _check(
    'byId.nestedPattern',
    tree.byId('GOAL-TASK-12').className === 'TaskEntry',
  );

  // unknown and non-matching ids return null / empty
  _check('byId.nope', tree.byId('NOPE') === null);
  _check('byId.dangling', tree.byId('GOAL-ITEM-') === null);
  _check('byId.nonNumeric', tree.byId('GOAL-ITEM-x') === null);
  _check('byId.allNope', tree.allById('NOPE').length === 0);
}

function testByPath() {
  const tree = buildFixtureTree();

  // resolves the bare root and nested sections
  _check('byPath.root', tree.byPath('DEMO') === tree.root);
  _check('byPath.insc', tree.byPath('DEMO/INSC').sectionId === 'INSC');
  _check('byPath.goal', tree.byPath('DEMO/INSC/GOAL').memberName === 'goals');
  _check('byPath.doco', tree.byPath('DEMO/DOCO').kind === SomMetaKind.FORM);

  // a list container resolves only as the final segment
  _check(
    'byPath.list.final',
    tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST').kind === SomMetaKind.LIST,
  );
  _check(
    'byPath.list.notFinal',
    tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST/text') === null,
  );

  // a `-<seq>` item suffix descends into the element subtree
  const item = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-2');
  _check('byPath.item.class', item.className === 'GoalEntry');
  const text = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text');
  _check('byPath.item.text', text.kind === SomMetaKind.CONTENT);

  // nested lists inside an element subtree resolve dynamically
  const task = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note');
  _check(
    'byPath.nested',
    task !== null &&
      task.className === 'TaskEntry' &&
      task.kind === SomMetaKind.CONTENT,
  );

  // a hyphen+digit section id is not mis-read as a list item
  const phase = tree.byPath('DEMO/PHASE-2');
  _check(
    'byPath.phase',
    phase.kind === SomMetaKind.SECTION && phase.memberName === 'phaseTwo',
  );
  _check(
    'byPath.phase.outline',
    tree.byPath('DEMO/PHASE-2/outline').kind === SomMetaKind.CONTENT,
  );

  // a scalar list item is a value leaf (resolves to the list node)
  _check(
    'byPath.scalarItem',
    tree.byPath('DEMO/tags-4') === tree.byPath('DEMO/tags'),
  );
  _check('byPath.scalarItem.deeper', tree.byPath('DEMO/tags-4/deeper') === null);

  // descending past a recursive re-entry terminates
  _check('byPath.recursive', tree.byPath('DEMO/related').recursive === true);
  _check('byPath.recursive.past', tree.byPath('DEMO/related/INSC') === null);

  // dangling paths and foreign roots return null
  _check('byPath.empty', tree.byPath('') === null);
  _check('byPath.other', tree.byPath('OTHER') === null);
  _check('byPath.missing', tree.byPath('DEMO/missing') === null);
  _check('byPath.pastLeaf', tree.byPath('DEMO/INSC/summary/deeper') === null);
  _check(
    'byPath.itemMissing',
    tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing') === null,
  );

  // byId and byPath agree on the node they address (DR1 §4.2)
  _check('agree.insc', tree.byId('INSC') === tree.byPath('DEMO/INSC'));
  _check(
    'agree.list',
    tree.byId('GOAL-ITEM-LST') === tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST'),
  );
  _check(
    'agree.item',
    tree.byId('GOAL-ITEM-1') ===
      tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-1'),
  );
}

function testItemPath() {
  const tree = buildFixtureTree();

  // builds `<listPath>-<seq>` for a statically placed list
  const entries = tree.byId('GOAL-ITEM-LST');
  _check(
    'itemPath.build',
    entries.itemPath(2) === 'DEMO/INSC/GOAL/GOAL-ITEM-LST-2',
    entries.itemPath(2),
  );
  _check(
    'itemPath.resolves',
    tree.byPath(entries.itemPath(2)).className === 'GoalEntry',
  );

  // rejects non-list nodes and lists inside element subtrees
  _check('itemPath.nonList', _raises(() => tree.byId('INSC').itemPath(1)));
  const nested = tree.byId('GOAL-ITEM-LST').elementNode.childByMember(
    'subTasks',
  );
  _check('itemPath.nestedList', _raises(() => nested.itemPath(1)));
}

function main() {
  testWiring();
  testMetadataSlots();
  testById();
  testByPath();
  testItemPath();

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
