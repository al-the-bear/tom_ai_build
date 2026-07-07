import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A model whose fields declare `@SerializationOrder` in an order that is the
/// REVERSE of alphabetical, so a correct emission is visibly different from the
/// default alphabetical one.
///
/// `Root` (root `DEMO`) has three content fields:
///   * `zeta`  @SectionId ZETA  order 1
///   * `mid`   @SectionId MID   order 2
///   * `alpha` @SectionId ALPHA order 3
/// plus a `@Form` `head` (order 0) with fields declared last→first, and a list
/// `items` (order 4) of a complex `Item` with two ordered content fields.
SpecModel _model() {
  final item = SpecClass(
    name: 'Item',
    fields: [
      SpecField(
          name: 'second',
          kind: SpecFieldKind.content,
          sectionId: 'SECOND',
          serializationOrder: 1),
      SpecField(
          name: 'first',
          kind: SpecFieldKind.content,
          sectionId: 'FIRST',
          serializationOrder: 2),
    ],
  );
  final root = SpecClass(
    name: 'Root',
    sectionId: 'DEMO',
    fields: [
      SpecField(
        name: 'head',
        kind: SpecFieldKind.form,
        sectionId: 'HEAD',
        serializationOrder: 0,
        formFields: [
          FormFieldSpec(name: 'title', label: 'Title', type: 'String'),
          FormFieldSpec(name: 'author', label: 'Author', type: 'String'),
        ],
      ),
      SpecField(
          name: 'zeta',
          kind: SpecFieldKind.content,
          sectionId: 'ZETA',
          serializationOrder: 1),
      SpecField(
          name: 'mid',
          kind: SpecFieldKind.content,
          sectionId: 'MID',
          serializationOrder: 2),
      SpecField(
          name: 'alpha',
          kind: SpecFieldKind.content,
          sectionId: 'ALPHA',
          serializationOrder: 3),
      SpecField(
        name: 'items',
        kind: SpecFieldKind.list,
        sectionId: 'ITEM',
        sectionIdPattern: 'ITEM-xxx',
        elementType: 'Item',
        elementIsComplex: true,
        serializationOrder: 4,
      ),
    ],
  );
  return SpecModel(
    roots: [SpecRoot(type: 'Root', title: 'Demo', sectionId: 'DEMO')],
    classes: {'Root': root, 'Item': item},
  );
}

/// Index of the first line whose trimmed form starts with [prefix], or -1.
int _lineIndexOf(String yaml, String prefix) {
  final lines = yaml.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith(prefix)) return i;
  }
  return -1;
}

void main() {
  late SpecModel model;
  late SomMetaTree tree;
  late SpecDocument doc;

  setUp(() {
    model = _model();
    tree = buildSomMetaTree(model);
    doc = SpecDocument();
    // Populate content out of declaration order on purpose.
    doc.setContent('DEMO/ALPHA', 'a');
    doc.setContent('DEMO/ZETA', 'z');
    doc.setContent('DEMO/MID', 'm');
  });

  group('content ordering (AA1 criterion 7)', () {
    test('emits siblings in @SerializationOrder order (ZETA, MID, ALPHA)', () {
      final yaml = SpecDocumentYaml.encode(document: doc, tree: tree);
      final zeta = _lineIndexOf(yaml, 'ZETA zeta:');
      final mid = _lineIndexOf(yaml, 'MID mid:');
      final alpha = _lineIndexOf(yaml, 'ALPHA alpha:');
      expect(zeta, greaterThan(0));
      expect(mid, greaterThan(zeta));
      expect(alpha, greaterThan(mid));
    });

    test('form (order 0) precedes all content fields', () {
      doc.setFormField('DEMO/HEAD', 'title', 'T');
      final yaml = SpecDocumentYaml.encode(document: doc, tree: tree);
      final head = _lineIndexOf(yaml, 'HEAD head:');
      final zeta = _lineIndexOf(yaml, 'ZETA zeta:');
      expect(head, greaterThan(0));
      expect(zeta, greaterThan(head));
    });
  });

  group('form-field ordering (AA1 criterion 7)', () {
    test('form fields follow the form-field declaration order', () {
      doc.setFormField('DEMO/HEAD', 'author', 'me');
      doc.setFormField('DEMO/HEAD', 'title', 'T');
      final yaml = SpecDocumentYaml.encode(document: doc, tree: tree);
      final titleAt = _lineIndexOf(yaml, 'title:');
      final authorAt = _lineIndexOf(yaml, 'author:');
      expect(titleAt, greaterThan(0));
      // title (declared first) precedes author (declared second).
      expect(titleAt, lessThan(authorAt));
    });
  });

  group('list-item ordering (AA1 criterion 7)', () {
    test('complex list items order by sequence, fields by declared order', () {
      final order = SpecSerializationOrder(model);
      // Two items; within each, `second` (order 1) precedes `first` (order 2).
      final i1 = doc.addListItem('DEMO/ITEM', sectionId: 'ITEM-AB1');
      final i2 = doc.addListItem('DEMO/ITEM', sectionId: 'ITEM-AB2');
      doc.setContent('$i1/FIRST', 'i1-first');
      doc.setContent('$i1/SECOND', 'i1-second');
      doc.setContent('$i2/SECOND', 'i2-second');

      final keys = order.orderPaths([
        '$i2/SECOND',
        '$i1/FIRST',
        '$i1/SECOND',
      ]);
      expect(keys, ['$i1/SECOND', '$i1/FIRST', '$i2/SECOND']);
    });

    test('emitted list item fields follow @SerializationOrder', () {
      final i1 = doc.addListItem('DEMO/ITEM', sectionId: 'ITEM-AB1');
      doc.setContent('$i1/FIRST', 'i1-first');
      doc.setContent('$i1/SECOND', 'i1-second');
      final yaml = SpecDocumentYaml.encode(document: doc, tree: tree);
      final second = _lineIndexOf(yaml, 'SECOND second:');
      final first = _lineIndexOf(yaml, 'FIRST first:');
      expect(second, greaterThan(0));
      expect(first, greaterThan(second));
    });
  });

  group('round-trip preserves order (AA1 criterion 7)', () {
    test('read -> write reproduces the same member order', () {
      final yaml1 = SpecDocumentYaml.encode(document: doc, tree: tree);
      final reloaded = SpecDocumentYaml.decode(yaml1, tree).document;
      final yaml2 = SpecDocumentYaml.encode(document: reloaded, tree: tree);
      expect(yaml2, yaml1);
    });
  });
}
