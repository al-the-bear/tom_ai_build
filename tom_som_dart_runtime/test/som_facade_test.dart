import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A tiny hand-written facade subclass to exercise the [SomNode] base and the
/// list/scalar wrappers the generated code relies on.
class _Root extends SomNode {
  _Root(super.doc, super.path);

  String get title => doc.content('$path/title') ?? '';
  set title(String v) => doc.setContent('$path/title', v);

  SomList<_Item> get items =>
      SomList<_Item>(doc, '$path/items', (d, p) => _Item(d, p));

  SomList<SomScalar> get tags =>
      SomList<SomScalar>(doc, '$path/tags', (d, p) => SomScalar(d, p));

  /// A pattern-bearing list — mirrors what the emitter generates for a field
  /// carrying a `@SectionIdPattern`.
  SomList<_Item> get risks => SomList<_Item>(
        doc,
        '$path/RISK',
        (d, p) => _Item(d, p),
        pattern: 'RISK-ITEM-xxx',
      );
}

class _Item extends SomNode {
  _Item(super.doc, super.path);

  String get label => doc.content('$path/label') ?? '';
  set label(String v) => doc.setContent('$path/label', v);
}

void main() {
  group('SomNode', () {
    test('holds the document and its path', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      expect(root.doc, same(doc));
      expect(root.path, 'PD00');
    });

    test('a typed leaf mutation is visible through the generic path', () {
      final doc = SpecDocument();
      _Root(doc, 'PD00').title = 'Hello';
      expect(doc.content('PD00/title'), 'Hello');
    });

    test('a generic mutation is visible through the typed leaf', () {
      final doc = SpecDocument();
      doc.setContent('PD00/title', 'World');
      expect(_Root(doc, 'PD00').title, 'World');
    });
  });

  group('SomList', () {
    test('add appends an item reachable both ways', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.items.add();
      item.label = 'first';
      expect(root.items.length, 1);
      expect(root.items[0].label, 'first');
      // Visible through the generic document.
      expect(doc.listItemCount('PD00/items'), 1);
      expect(doc.content('${doc.listItems('PD00/items').single}/label'),
          'first');
    });

    test('removeAt drops the item and its nested values', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.items.add().label = 'a';
      root.items.add().label = 'b';
      expect(root.items.length, 2);
      root.items.removeAt(0);
      expect(root.items.length, 1);
      expect(root.items[0].label, 'b');
    });

    test('scalar list items carry a string value', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.tags.add().value = 'x';
      expect(root.tags[0].value, 'x');
      expect(doc.listItemCount('PD00/tags'), 1);
    });
  });

  group('SomList section ids (AA1 criteria 3–6)', () {
    final date = DateTime(2026, 1, 2); // AB

    test('add generates a section id from the pattern (criteria 3, 4)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.risks.add(date: date);
      expect(item.$sectionId, 'RISK-ITEM-AB1');
      // Visible both ways.
      expect(doc.itemSectionId(item.path), 'RISK-ITEM-AB1');
    });

    test('add accepts a section-id override, validated unique (criterion 5)',
        () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.risks.add(sectionId: 'RISK-ITEM-CUSTOM');
      expect(root.risks.sectionIds, ['RISK-ITEM-CUSTOM']);
      expect(
        () => root.risks.add(sectionId: 'RISK-ITEM-CUSTOM'),
        throwsA(isA<SpecSectionIdCollision>()),
      );
    });

    test(r'overriding an item id via SomNode.$sectionId (criterion 5)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.risks.add(date: date);
      item.$sectionId = 'RISK-ITEM-OVR';
      expect(root.risks.sectionIds, ['RISK-ITEM-OVR']);
    });

    test('delete-last then same-day add reuses the freed id (criterion 6)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.risks.add(date: date); // AB1
      root.risks.add(date: date); // AB2
      root.risks.removeAt(1); // delete last
      final reused = root.risks.add(date: date);
      expect(reused.$sectionId, 'RISK-ITEM-AB2');
    });

    test('delete-middle keeps ids, numbering non-consecutive (criterion 6)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.risks.add(date: date); // AB1
      root.risks.add(date: date); // AB2
      root.risks.add(date: date); // AB3
      root.risks.removeAt(1); // delete AB2
      expect(root.risks.sectionIds, ['RISK-ITEM-AB1', 'RISK-ITEM-AB3']);
      final next = root.risks.add(date: date);
      expect(next.$sectionId, 'RISK-ITEM-AB4');
    });
  });

  group('checkSomModelVersion', () {
    test('a null/empty document stamp is always accepted', () {
      expect(() => checkSomModelVersion('0.0', null), returnsNormally);
      expect(() => checkSomModelVersion('0.0', ''), returnsNormally);
    });

    test('an older or equal same-major document is editable', () {
      expect(() => checkSomModelVersion('1.3', '1.0'), returnsNormally);
      expect(() => checkSomModelVersion('1.3', '1.3'), returnsNormally);
    });

    test('a newer same-major document is rejected', () {
      expect(() => checkSomModelVersion('1.2', '1.5'),
          throwsA(isA<SomVersionException>()));
    });

    test('a different major version is rejected', () {
      expect(() => checkSomModelVersion('1.0', '2.0'),
          throwsA(isA<SomVersionException>()));
      expect(() => checkSomModelVersion('1.0', '0.9'),
          throwsA(isA<SomVersionException>()));
    });

    test('an unparseable document stamp is rejected', () {
      expect(() => checkSomModelVersion('1.0', 'not-a-version'),
          throwsA(isA<SomVersionException>()));
    });
  });

  group('somEditabilityFor (non-throwing §2.2 classification, item 8)', () {
    test('a null/empty document stamp is editable', () {
      expect(somEditabilityFor('0.0', null), SomEditability.editable);
      expect(somEditabilityFor('0.0', ''), SomEditability.editable);
    });

    test('an older or equal same-major document is editable', () {
      expect(somEditabilityFor('1.3', '1.0'), SomEditability.editable);
      expect(somEditabilityFor('1.3', '1.3'), SomEditability.editable);
    });

    test('a newer same-major document is rejectedNewerMinor', () {
      expect(somEditabilityFor('1.2', '1.5'),
          SomEditability.rejectedNewerMinor);
    });

    test('a different major version is readOnlyCrossMajor', () {
      expect(somEditabilityFor('1.0', '2.0'),
          SomEditability.readOnlyCrossMajor);
      expect(somEditabilityFor('1.0', '0.9'),
          SomEditability.readOnlyCrossMajor);
    });

    test('an unparseable document stamp is invalidVersion', () {
      expect(somEditabilityFor('1.0', 'not-a-version'),
          SomEditability.invalidVersion);
    });

    test('never throws where checkSomModelVersion would throw', () {
      for (final stamp in ['1.5', '2.0', '0.9', 'not-a-version']) {
        expect(() => somEditabilityFor('1.0', stamp), returnsNormally);
        expect(() => checkSomModelVersion('1.0', stamp),
            throwsA(isA<SomVersionException>()));
      }
    });

    test('classification agrees with the throwing checker', () {
      for (final stamp in [null, '', '1.0', '0.5', '1.5', '2.0', 'bad']) {
        final editable =
            somEditabilityFor('1.0', stamp) == SomEditability.editable;
        var threw = false;
        try {
          checkSomModelVersion('1.0', stamp);
        } on SomVersionException {
          threw = true;
        }
        expect(editable, !threw,
            reason: 'stamp "$stamp": editable=$editable threw=$threw');
      }
    });
  });
}
