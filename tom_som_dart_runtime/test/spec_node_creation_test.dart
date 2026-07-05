import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A self-contained model exercising every add-node rule:
///   * `risks`   — complex list with a `@SectionIdPattern` and `@Min`;
///   * `tags`    — scalar list with no pattern;
///   * `situation` — single-valued `complex` child (cardinality 1);
///   * `vision`  — single-valued `content` leaf (a non-container parent).
SpecModel _model() {
  final risk = SpecClass(
    name: 'Risk',
    fields: [
      SpecField(
        name: 'title',
        kind: SpecFieldKind.content,
        sectionId: 'RISK-TITLE',
      ),
    ],
  );
  final situation = SpecClass(
    name: 'CurrentSituation',
    sectionId: 'PD00-SIT',
    fields: [
      SpecField(
        name: 'summary',
        kind: SpecFieldKind.content,
        sectionId: 'PD00-SIT-SUM',
      ),
    ],
  );
  final projectDefinition = SpecClass(
    name: 'ProjectDefinition',
    sectionId: 'PD00',
    fields: [
      SpecField(
        name: 'vision',
        kind: SpecFieldKind.content,
        sectionId: 'PD00-VIS',
      ),
      SpecField(
        name: 'risks',
        kind: SpecFieldKind.list,
        sectionId: 'PD00-RISK',
        sectionIdPattern: 'PD00-RISK-xxx',
        elementType: 'Risk',
        elementIsComplex: true,
        min: 1,
      ),
      SpecField(
        name: 'tags',
        kind: SpecFieldKind.list,
        sectionId: 'PD00-TAG',
        elementType: 'String',
      ),
      SpecField(
        name: 'situation',
        kind: SpecFieldKind.complex,
        sectionId: 'PD00-SIT',
        type: 'CurrentSituation',
      ),
    ],
  );
  return SpecModel(
    roots: [SpecRoot(type: 'ProjectDefinition', title: 'PD', sectionId: 'PD00')],
    classes: {
      'ProjectDefinition': projectDefinition,
      'Risk': risk,
      'CurrentSituation': situation,
    },
  );
}

void main() {
  late SpecModel model;
  late SpecDocument doc;
  late SpecNodeCreator creator;

  setUp(() {
    model = _model();
    doc = SpecDocument();
    creator = SpecNodeCreator(model, doc);
  });

  group('legal adds', () {
    test('appends a complex list item and returns its seq path', () {
      final path = creator.add('PD00', 'PD00-RISK');
      expect(path, 'PD00/PD00-RISK-1');
      expect(doc.listItemCount('PD00/PD00-RISK'), 1);
      final path2 = creator.add('PD00', 'PD00-RISK');
      expect(path2, 'PD00/PD00-RISK-2');
      expect(doc.listItemCount('PD00/PD00-RISK'), 2);
    });

    test('appends a scalar list item with no pattern', () {
      final path = creator.add('PD00', 'PD00-TAG');
      expect(path, 'PD00/PD00-TAG-1');
      expect(doc.listItemCount('PD00/PD00-TAG'), 1);
    });

    test('a list item with a conforming explicit id is accepted', () {
      final path = creator.add('PD00', 'PD00-RISK', itemId: 'PD00-RISK-7');
      expect(path, 'PD00/PD00-RISK-1');
      expect(doc.itemSectionId(path), 'PD00-RISK-7');
    });

    test('an added list item without an id gets a generated section id', () {
      final path = creator.add('PD00', 'PD00-RISK', date: DateTime(2026, 1, 2));
      expect(doc.itemSectionId(path), 'PD00-RISK-AB1');
    });

    test('materialises a single-valued complex child without mutating', () {
      final path = creator.add('PD00', 'PD00-SIT');
      expect(path, 'PD00/PD00-SIT');
      expect(doc.isEmpty, isTrue);
    });

    test('checkAddNode returns null for a legal add', () {
      expect(checkAddNode(model, doc, 'PD00', 'PD00-RISK'), isNull);
    });
  });

  group('rejection: wrong kind (unknown child)', () {
    test('rejects a child the parent class does not declare', () {
      final err = checkAddNode(model, doc, 'PD00', 'NOPE');
      expect(err, isNotNull);
      expect(err!.code, SpecCreationCode.unknownChild);
    });

    test('add throws and leaves the tree untouched', () {
      expect(
        () => creator.add('PD00', 'NOPE'),
        throwsA(isA<SpecCreationError>()
            .having((e) => e.code, 'code', SpecCreationCode.unknownChild)),
      );
      expect(doc.isEmpty, isTrue);
    });
  });

  group('rejection: not a container', () {
    test('rejects a content leaf as parent', () {
      final err = checkAddNode(model, doc, 'PD00/PD00-VIS', 'x');
      expect(err!.code, SpecCreationCode.notAContainer);
    });

    test('rejects a list as parent (items are added via the owning field)', () {
      final err = checkAddNode(model, doc, 'PD00/PD00-RISK', 'x');
      expect(err!.code, SpecCreationCode.notAContainer);
    });

    test('rejects a dangling parent path', () {
      final err = checkAddNode(model, doc, 'PD00/GHOST', 'x');
      expect(err!.code, SpecCreationCode.notAContainer);
    });
  });

  group('rejection: pattern mismatch', () {
    test('rejects an explicit list-item id that drops the pattern prefix', () {
      final err = checkAddNode(model, doc, 'PD00', 'PD00-RISK', itemId: 'WRONG');
      expect(err!.code, SpecCreationCode.patternMismatch);
    });

    test('add throws on a bad id and does not append', () {
      expect(
        () => creator.add('PD00', 'PD00-RISK', itemId: 'WRONG'),
        throwsA(isA<SpecCreationError>()
            .having((e) => e.code, 'code', SpecCreationCode.patternMismatch)),
      );
      expect(doc.listItemCount('PD00/PD00-RISK'), 0);
    });
  });

  group('rejection: duplicate section id (AA1 criterion 5)', () {
    test('rejects an explicit id already used by another item', () {
      creator.add('PD00', 'PD00-RISK', itemId: 'PD00-RISK-7');
      final err =
          checkAddNode(model, doc, 'PD00', 'PD00-RISK', itemId: 'PD00-RISK-7');
      expect(err!.code, SpecCreationCode.duplicateSectionId);
    });

    test('add throws on a duplicate id and does not append', () {
      creator.add('PD00', 'PD00-RISK', itemId: 'PD00-RISK-7');
      expect(
        () => creator.add('PD00', 'PD00-RISK', itemId: 'PD00-RISK-7'),
        throwsA(isA<SpecCreationError>().having(
            (e) => e.code, 'code', SpecCreationCode.duplicateSectionId)),
      );
      expect(doc.listItemCount('PD00/PD00-RISK'), 1);
    });
  });

  group('rejection: over-cardinality', () {
    test('rejects a second single-valued child once one is populated', () {
      creator.add('PD00', 'PD00-SIT');
      doc.setContent('PD00/PD00-SIT/PD00-SIT-SUM', 'a summary');
      final err = checkAddNode(model, doc, 'PD00', 'PD00-SIT');
      expect(err!.code, SpecCreationCode.cardinalityExceeded);
    });

    test('add throws over-cardinality without disturbing the existing value',
        () {
      doc.setContent('PD00/PD00-SIT/PD00-SIT-SUM', 'a summary');
      expect(
        () => creator.add('PD00', 'PD00-SIT'),
        throwsA(isA<SpecCreationError>().having(
            (e) => e.code, 'code', SpecCreationCode.cardinalityExceeded)),
      );
      expect(doc.content('PD00/PD00-SIT/PD00-SIT-SUM'), 'a summary');
    });

    test('a populated list still accepts further items (no upper bound)', () {
      creator.add('PD00', 'PD00-RISK');
      expect(checkAddNode(model, doc, 'PD00', 'PD00-RISK'), isNull);
    });
  });
}
