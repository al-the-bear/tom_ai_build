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

/// The order of content keys as they appear in the emitted `content:` block.
List<String> _contentKeyOrder(String yaml) {
  final out = <String>[];
  var inContent = false;
  for (final line in yaml.split('\n')) {
    if (line == '  content:') {
      inContent = true;
      continue;
    }
    if (inContent) {
      final m = RegExp(r'^    "([^"]+)":').firstMatch(line);
      if (m != null) {
        out.add(m.group(1)!);
      } else if (line.startsWith('  ') && !line.startsWith('    ')) {
        break; // next top-level document child (forms:/lists:)
      }
    }
  }
  return out;
}

void main() {
  late SpecModel model;
  late SpecDocument doc;

  setUp(() {
    model = _model();
    doc = SpecDocument();
    // Populate content out of declaration order on purpose.
    doc.setContent('DEMO/ALPHA', 'a');
    doc.setContent('DEMO/ZETA', 'z');
    doc.setContent('DEMO/MID', 'm');
  });

  group('content ordering (AA1 criterion 7)', () {
    test('default (no model) emits alphabetical keys', () {
      final yaml = SpecDocumentYaml.encode(document: doc);
      expect(_contentKeyOrder(yaml),
          ['DEMO/ALPHA', 'DEMO/MID', 'DEMO/ZETA']);
    });

    test('with model, emits @SerializationOrder order (ZETA, MID, ALPHA)', () {
      final yaml = SpecDocumentYaml.encode(
          document: doc, order: SpecSerializationOrder(model));
      expect(_contentKeyOrder(yaml),
          ['DEMO/ZETA', 'DEMO/MID', 'DEMO/ALPHA']);
    });
  });

  group('form-field ordering (AA1 criterion 7)', () {
    test('form fields follow the form-field declaration order', () {
      doc.setFormField('DEMO/HEAD', 'author', 'me');
      doc.setFormField('DEMO/HEAD', 'title', 'T');
      final yaml = SpecDocumentYaml.encode(
          document: doc, order: SpecSerializationOrder(model));
      final titleAt = yaml.indexOf('"title":');
      final authorAt = yaml.indexOf('"author":');
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
  });

  group('round-trip preserves order (AA1 criterion 7)', () {
    test('read -> write reproduces the same member order', () {
      final order = SpecSerializationOrder(model);
      final yaml1 = SpecDocumentYaml.encode(document: doc, order: order);
      final reloaded = SpecDocument()
        ..loadJson(SpecDocumentYaml.decode(yaml1).document);
      final yaml2 = SpecDocumentYaml.encode(document: reloaded, order: order);
      expect(_contentKeyOrder(yaml2), _contentKeyOrder(yaml1));
    });
  });
}
