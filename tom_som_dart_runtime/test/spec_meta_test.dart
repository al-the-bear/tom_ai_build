import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Hand-built SOM §7.1 fixture tree mirroring the design doc's demo document
/// (acceptance: "the runtime compiles with a hand-built fixture tree").
///
/// Structure:
///
///   DEMO D99DemoDocument                      (@Document)
///     INSC introductionAndScope               (section, class-level id)
///       summary                               (content, no id)
///       GOAL goals                            (section)
///         GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
///           [element GoalEntry]
///             text                            (content)
///             subTasks                        (nested list of TaskEntry)
///               [element TaskEntry]  note     (content)
///     DOCO documentControl                    (form)
///     RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
///     PHASE-2 phaseTwo                        (hyphen+digit section id)
///     related                                 (recursive re-entry)
///     OLD legacy                              (@Unused content)
///     tags                                    (scalar list, no element node)
SomMetaTree buildFixtureTree() {
  final element = SomMetaNode(
    className: 'GoalEntry',
    kind: SomMetaKind.section,
    typeName: 'GoalEntry',
    docComment: 'One programme goal.',
    children: [
      SomMetaNode(
        className: 'GoalEntry',
        memberName: 'text',
        kind: SomMetaKind.content,
        typeName: 'String',
        serializationOrder: 1,
      ),
      SomMetaNode(
        className: 'GoalEntry',
        memberName: 'subTasks',
        sectionIdPattern: 'GOAL-TASK-xxx',
        kind: SomMetaKind.list,
        typeName: 'List<TaskEntry>',
        serializationOrder: 2,
        elementNode: SomMetaNode(
          className: 'TaskEntry',
          kind: SomMetaKind.section,
          typeName: 'TaskEntry',
          children: [
            SomMetaNode(
              className: 'TaskEntry',
              memberName: 'note',
              kind: SomMetaKind.content,
              typeName: 'String',
            ),
          ],
        ),
      ),
    ],
  );

  SomMetaNode risk(String member) => SomMetaNode(
        className: 'Risk',
        memberName: member,
        sectionId: 'RISK',
        kind: SomMetaKind.complex,
        typeName: 'Risk',
        classDocComment: 'A programme risk.',
        children: [
          SomMetaNode(
            className: 'Risk',
            memberName: 'probability',
            kind: SomMetaKind.enumValue,
            typeName: 'Probability',
          ),
        ],
      );

  final root = SomMetaNode(
    className: 'D99DemoDocument',
    sectionId: 'DEMO',
    kind: SomMetaKind.section,
    typeName: 'D99DemoDocument',
    document: const SomDocMeta(
      name: 'Demo Document',
      description: 'The demo specification document.',
      basedOn: ['D00SolutionBlueprint'],
    ),
    docComment: 'Root of the demo document.',
    children: [
      SomMetaNode(
        className: 'IntroductionAndScope',
        memberName: 'introductionAndScope',
        sectionId: 'INSC',
        kind: SomMetaKind.section,
        typeName: 'IntroductionAndScope',
        serializationOrder: 1,
        contentHelp: 'Describe why the system exists.',
        comment: 'Keep this short.',
        mapsTo: 'CurrentLandscape',
        detailedIn: 'D01RequirementsSpecification',
        children: [
          SomMetaNode(
            className: 'IntroductionAndScope',
            memberName: 'summary',
            kind: SomMetaKind.content,
            typeName: 'String',
            min: 1,
            serializationOrder: 1,
            contentType: const SomContentTypeMeta(
                type: 'diagram', description: 'A mermaid context diagram.'),
            docComment: 'What the system covers.',
          ),
          SomMetaNode(
            className: 'Goals',
            memberName: 'goals',
            sectionId: 'GOAL',
            kind: SomMetaKind.section,
            typeName: 'Goals',
            serializationOrder: 2,
            children: [
              SomMetaNode(
                className: 'Goals',
                memberName: 'entries',
                sectionId: 'GOAL-ITEM-LST',
                sectionIdPattern: 'GOAL-ITEM-xxx',
                kind: SomMetaKind.list,
                typeName: 'List<GoalEntry>',
                min: 1,
                extra: const [
                  SomMetaExtra(annotation: 'Max', args: {'count': 4}),
                ],
                elementNode: element,
              ),
            ],
          ),
        ],
      ),
      SomMetaNode(
        className: 'DocumentControl',
        memberName: 'documentControl',
        sectionId: 'DOCO',
        kind: SomMetaKind.form,
        typeName: 'DocumentControl',
        serializationOrder: 2,
        form: const SomFormMeta(fields: [
          SomFormFieldMeta(
            name: 'version',
            typeName: 'String',
            description: 'Version',
            required: true,
            hint: 'e.g. 1.0',
            order: 1,
          ),
          SomFormFieldMeta(name: 'approvedBy', typeName: 'String', order: 2),
          SomFormFieldMeta(name: 'reviewCount', typeName: 'int', order: 3),
        ]),
      ),
      risk('primaryRisk'),
      risk('fallbackRisk'),
      SomMetaNode(
        className: 'PhaseTwo',
        memberName: 'phaseTwo',
        sectionId: 'PHASE-2',
        kind: SomMetaKind.section,
        typeName: 'PhaseTwo',
        children: [
          SomMetaNode(
            className: 'PhaseTwo',
            memberName: 'outline',
            kind: SomMetaKind.content,
            typeName: 'String',
          ),
        ],
      ),
      SomMetaNode(
        className: 'D99DemoDocument',
        memberName: 'related',
        kind: SomMetaKind.complex,
        typeName: 'D99DemoDocument',
        recursive: true,
      ),
      SomMetaNode(
        className: 'D99DemoDocument',
        memberName: 'legacy',
        sectionId: 'OLD',
        kind: SomMetaKind.content,
        typeName: 'String',
        unused: true,
      ),
      SomMetaNode(
        className: 'D99DemoDocument',
        memberName: 'tags',
        kind: SomMetaKind.list,
        typeName: 'List<String>',
      ),
    ],
  );
  return SomMetaTree(root);
}

void main() {
  late SomMetaTree tree;

  setUp(() {
    tree = buildFixtureTree();
  });

  group('SomMetaTree wiring', () {
    test('root path is the root segment and parent is null', () {
      expect(tree.root.path, 'DEMO');
      expect(tree.root.segment, 'DEMO');
      expect(tree.root.parent, isNull);
      expect(tree.root.document!.name, 'Demo Document');
      expect(tree.root.document!.basedOn, ['D00SolutionBlueprint']);
    });

    test('child paths follow the SOM §8 grammar (sectionId ?? memberName)', () {
      final insc = tree.root.childByMember('introductionAndScope')!;
      expect(insc.path, 'DEMO/INSC');
      expect(insc.childByMember('summary')!.path, 'DEMO/INSC/summary');
      final entries =
          insc.childByMember('goals')!.childByMember('entries')!;
      expect(entries.path, 'DEMO/INSC/GOAL/GOAL-ITEM-LST');
    });

    test('parent links are wired for children and element subtrees', () {
      final insc = tree.root.childByMember('introductionAndScope')!;
      final entries =
          insc.childByMember('goals')!.childByMember('entries')!;
      expect(entries.parent!.segment, 'GOAL');
      expect(entries.elementNode!.parent, same(entries));
      expect(entries.elementNode!.children.first.parent,
          same(entries.elementNode));
    });

    test('element subtree nodes carry no static path', () {
      final entries = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST')!;
      final element = entries.elementNode!;
      expect(element.path, isNull);
      expect(element.childByMember('text')!.path, isNull);
      expect(element.childByMember('subTasks')!.path, isNull);
    });

    test('allNodes covers children and element subtrees in document order',
        () {
      final names = tree.allNodes.map((n) => n.debugName).toList();
      expect(names.first, 'D99DemoDocument');
      expect(names, contains('GoalEntry'));
      expect(names, contains('TaskEntry.note'));
      expect(names, contains('Risk.fallbackRisk'));
      // The element subtree follows its list node.
      expect(names.indexOf('GoalEntry'),
          greaterThan(names.indexOf('Goals.entries')));
    });

    test('a root without @Document metadata is rejected', () {
      expect(
        () => SomMetaTree(SomMetaNode(
            className: 'X', kind: SomMetaKind.section, typeName: 'X')),
        throwsArgumentError,
      );
    });

    test('a node belongs to exactly one tree', () {
      expect(() => SomMetaTree(tree.root), throwsStateError);
    });

    test('an unattached node refuses path/parent access', () {
      final loose = SomMetaNode(
          className: 'X', kind: SomMetaKind.scalar, typeName: 'int');
      expect(() => loose.path, throwsStateError);
      expect(() => loose.parent, throwsStateError);
    });
  });

  group('metadata slots (SOM §7.1)', () {
    test('section node carries help, comment and traceability links', () {
      final insc = tree.byId('INSC')!;
      expect(insc.contentHelp, 'Describe why the system exists.');
      expect(insc.comment, 'Keep this short.');
      expect(insc.mapsTo, 'CurrentLandscape');
      expect(insc.detailedIn, 'D01RequirementsSpecification');
      expect(insc.serializationOrder, 1);
    });

    test('content node carries @Min, @ContentType and doc comment', () {
      final summary = tree.byPath('DEMO/INSC/summary')!;
      expect(summary.kind, SomMetaKind.content);
      expect(summary.min, 1);
      expect(summary.contentType!.type, 'diagram');
      expect(summary.contentType!.description, 'A mermaid context diagram.');
      expect(summary.docComment, 'What the system covers.');
    });

    test('form node exposes fields with description/required/hint/order', () {
      final form = tree.byId('DOCO')!.form!;
      expect(form.fields.map((f) => f.name),
          ['version', 'approvedBy', 'reviewCount']);
      final version = form.fieldNamed('version')!;
      expect(version.required, isTrue);
      expect(version.hint, 'e.g. 1.0');
      expect(version.description, 'Version');
      expect(version.order, 1);
      expect(form.fieldNamed('approvedBy')!.required, isFalse);
      expect(form.fieldNamed('missing'), isNull);
    });

    test('list node carries @Min plus the lossless extra list (@Max)', () {
      final entries = tree.byId('GOAL-ITEM-LST')!;
      expect(entries.kind, SomMetaKind.list);
      expect(entries.min, 1);
      expect(entries.sectionIdPattern, 'GOAL-ITEM-xxx');
      final max = entries.extra.single;
      expect(max.annotation, 'Max');
      expect(max.args['count'], 4);
    });

    test('@Unused and recursive flags are carried', () {
      expect(tree.byId('OLD')!.unused, isTrue);
      final related = tree.root.childByMember('related')!;
      expect(related.recursive, isTrue);
      expect(related.children, isEmpty);
    });

    test('class doc comment is carried where it differs from the member one',
        () {
      final risk = tree.byId('RISK')!;
      expect(risk.classDocComment, 'A programme risk.');
    });
  });

  group('byId lookup', () {
    test('resolves an exact section id', () {
      expect(tree.byId('DEMO'), same(tree.root));
      expect(tree.byId('GOAL')!.memberName, 'goals');
    });

    test('a shared class at two positions: first wins, allById has both', () {
      expect(tree.byId('RISK')!.memberName, 'primaryRisk');
      expect(tree.allById('RISK').map((n) => n.memberName),
          ['primaryRisk', 'fallbackRisk']);
    });

    test('a resolved @SectionIdPattern id resolves to the element subtree',
        () {
      final element = tree.byId('GOAL-ITEM-3')!;
      expect(element.className, 'GoalEntry');
      expect(element, same(tree.byId('GOAL-ITEM-LST')!.elementNode));
      // A nested pattern inside the element subtree resolves too.
      expect(tree.byId('GOAL-TASK-12')!.className, 'TaskEntry');
    });

    test('unknown and non-matching ids return null / empty', () {
      expect(tree.byId('NOPE'), isNull);
      expect(tree.byId('GOAL-ITEM-'), isNull);
      expect(tree.byId('GOAL-ITEM-x'), isNull);
      expect(tree.allById('NOPE'), isEmpty);
    });
  });

  group('byPath lookup', () {
    test('resolves the bare root and nested sections', () {
      expect(tree.byPath('DEMO'), same(tree.root));
      expect(tree.byPath('DEMO/INSC')!.sectionId, 'INSC');
      expect(tree.byPath('DEMO/INSC/GOAL')!.memberName, 'goals');
      expect(tree.byPath('DEMO/DOCO')!.kind, SomMetaKind.form);
    });

    test('a list container resolves only as the final segment', () {
      expect(tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST')!.kind,
          SomMetaKind.list);
      expect(tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST/text'), isNull);
    });

    test('a `-<seq>` item suffix descends into the element subtree', () {
      final item = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-2')!;
      expect(item.className, 'GoalEntry');
      final text = tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text')!;
      expect(text.kind, SomMetaKind.content);
    });

    test('nested lists inside an element subtree resolve dynamically', () {
      final task =
          tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note')!;
      expect(task.className, 'TaskEntry');
      expect(task.kind, SomMetaKind.content);
    });

    test('a hyphen+digit section id is not mis-read as a list item', () {
      final phase = tree.byPath('DEMO/PHASE-2')!;
      expect(phase.kind, SomMetaKind.section);
      expect(phase.memberName, 'phaseTwo');
      expect(tree.byPath('DEMO/PHASE-2/outline')!.kind, SomMetaKind.content);
    });

    test('a scalar list item is a value leaf (resolves to the list node)', () {
      expect(tree.byPath('DEMO/tags-4'), same(tree.byPath('DEMO/tags')));
      expect(tree.byPath('DEMO/tags-4/deeper'), isNull);
    });

    test('descending past a recursive re-entry terminates', () {
      expect(tree.byPath('DEMO/related')!.recursive, isTrue);
      expect(tree.byPath('DEMO/related/INSC'), isNull);
    });

    test('dangling paths and foreign roots return null', () {
      expect(tree.byPath(''), isNull);
      expect(tree.byPath('OTHER'), isNull);
      expect(tree.byPath('DEMO/missing'), isNull);
      expect(tree.byPath('DEMO/INSC/summary/deeper'), isNull);
      expect(tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing'), isNull);
    });

    test('byId and byPath agree on the node they address (SOM §8)', () {
      expect(tree.byId('INSC'), same(tree.byPath('DEMO/INSC')));
      expect(tree.byId('GOAL-ITEM-LST'),
          same(tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST')));
      expect(tree.byId('GOAL-ITEM-1'),
          same(tree.byPath('DEMO/INSC/GOAL/GOAL-ITEM-LST-1')));
    });
  });

  group('itemPath', () {
    test('builds `<listPath>-<seq>` for a statically placed list', () {
      final entries = tree.byId('GOAL-ITEM-LST')!;
      expect(entries.itemPath(2), 'DEMO/INSC/GOAL/GOAL-ITEM-LST-2');
      expect(tree.byPath(entries.itemPath(2))!.className, 'GoalEntry');
    });

    test('rejects non-list nodes and lists inside element subtrees', () {
      expect(() => tree.byId('INSC')!.itemPath(1), throwsStateError);
      final nested =
          tree.byId('GOAL-ITEM-LST')!.elementNode!.childByMember('subTasks')!;
      expect(() => nested.itemPath(1), throwsStateError);
    });
  });
}
