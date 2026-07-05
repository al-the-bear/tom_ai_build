import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

const _list = 'DEMO/DACEN-ITEM-LST';
const _pattern = 'DACEN-ITEM-xxx';

void main() {
  group('SpecDocument section ids (AA1 criterion 1 read/write)', () {
    test('addListItem stores an explicit section id, itemSectionId reads it',
        () {
      final doc = SpecDocument();
      final p = doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      expect(doc.itemSectionId(p), 'DACEN-ITEM-AB1');
      expect(doc.listItemSectionIds(_list), ['DACEN-ITEM-AB1']);
    });

    test('addListItem without a section id leaves it null', () {
      final doc = SpecDocument();
      final p = doc.addListItem(_list);
      expect(doc.itemSectionId(p), isNull);
      expect(doc.listItemSectionIds(_list), isEmpty);
    });
  });

  group('SpecDocument section-id uniqueness (AA1 criterion 5)', () {
    test('addListItem rejects a duplicate id in the same list', () {
      final doc = SpecDocument();
      doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      expect(
        () => doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1'),
        throwsA(isA<SpecSectionIdCollision>()),
      );
    });

    test('setItemSectionId overrides an id', () {
      final doc = SpecDocument();
      final p = doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      doc.setItemSectionId(p, 'CUSTOM-ID');
      expect(doc.itemSectionId(p), 'CUSTOM-ID');
    });

    test('setItemSectionId rejects a collision with another item', () {
      final doc = SpecDocument();
      doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      final p2 = doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB2');
      expect(
        () => doc.setItemSectionId(p2, 'DACEN-ITEM-AB1'),
        throwsA(isA<SpecSectionIdCollision>()),
      );
    });

    test('setItemSectionId to the same value is a no-op (not a collision)', () {
      final doc = SpecDocument();
      final p = doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      doc.setItemSectionId(p, 'DACEN-ITEM-AB1');
      expect(doc.itemSectionId(p), 'DACEN-ITEM-AB1');
    });

    test('setItemSectionId on a non-item throws ArgumentError', () {
      final doc = SpecDocument();
      expect(
        () => doc.setItemSectionId('$_list-99', 'X'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SpecDocument delete behaviour (AA1 criterion 6)', () {
    final date = DateTime(2026, 1, 2); // AB

    String addGenerated(SpecDocument doc) {
      final id = generateListItemSectionId(
          _pattern, date, doc.listItemSectionIds(_list));
      return doc.addListItem(_list, sectionId: id);
    }

    test('delete middle -> ids stay put, numbering non-consecutive', () {
      final doc = SpecDocument();
      final p1 = addGenerated(doc); // AB1
      final p2 = addGenerated(doc); // AB2
      final p3 = addGenerated(doc); // AB3
      expect([doc.itemSectionId(p1), doc.itemSectionId(p2), //
        doc.itemSectionId(p3)], //
          ['DACEN-ITEM-AB1', 'DACEN-ITEM-AB2', 'DACEN-ITEM-AB3']);

      doc.removeListItem(p2); // delete the middle
      expect(doc.listItemSectionIds(_list),
          ['DACEN-ITEM-AB1', 'DACEN-ITEM-AB3']); // AB2 gap, no renumber

      final p4 = addGenerated(doc); // next uses max+1 = AB4, not AB2
      expect(doc.itemSectionId(p4), 'DACEN-ITEM-AB4');
    });

    test('delete last then add same day -> reuse the freed id', () {
      final doc = SpecDocument();
      addGenerated(doc); // AB1
      final p2 = addGenerated(doc); // AB2 (the last)

      doc.removeListItem(p2); // delete the last
      expect(doc.listItemSectionIds(_list), ['DACEN-ITEM-AB1']);

      final p3 = addGenerated(doc); // same day -> reuse AB2
      expect(doc.itemSectionId(p3), 'DACEN-ITEM-AB2');
    });
  });

  group('SpecDocument section-id persistence & undo', () {
    test('toJson/loadJson round-trips section ids', () {
      final doc = SpecDocument();
      final p = doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB2');

      final restored = SpecDocument()..loadJson(doc.toJson());
      expect(restored.itemSectionId(p), 'DACEN-ITEM-AB1');
      expect(restored.listItemSectionIds(_list),
          ['DACEN-ITEM-AB1', 'DACEN-ITEM-AB2']);
    });

    test('captureState/restoreState round-trips section ids', () {
      final doc = SpecDocument();
      final p = doc.addListItem(_list, sectionId: 'DACEN-ITEM-AB1');
      final snapshot = doc.captureState();

      doc.setItemSectionId(p, 'CHANGED');
      expect(doc.itemSectionId(p), 'CHANGED');

      doc.restoreState(snapshot);
      expect(doc.itemSectionId(p), 'DACEN-ITEM-AB1');
    });
  });
}
