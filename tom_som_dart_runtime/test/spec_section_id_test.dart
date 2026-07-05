import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('encodeTwoLetterDate (AA1 criterion 4)', () {
    test('Jan 1 -> AA', () {
      expect(encodeTwoLetterDate(DateTime(2026, 1, 1)), 'AA');
    });

    test('Feb 1 -> BA (month letter advances)', () {
      expect(encodeTwoLetterDate(DateTime(2026, 2, 1)), 'BA');
    });

    test('Dec 1 -> LA (Dec is L)', () {
      expect(encodeTwoLetterDate(DateTime(2026, 12, 1)), 'LA');
    });

    test('day 26 -> Z', () {
      expect(encodeTwoLetterDate(DateTime(2026, 1, 26)), 'AZ');
    });

    test('day 27 -> 0', () {
      expect(encodeTwoLetterDate(DateTime(2026, 1, 27)), 'A0');
    });

    test('day 31 -> 4', () {
      expect(encodeTwoLetterDate(DateTime(2026, 1, 31)), 'A4');
    });

    test('Dec 31 -> L4 (both extremes)', () {
      expect(encodeTwoLetterDate(DateTime(2026, 12, 31)), 'L4');
    });
  });

  group('sectionIdPatternPrefix (AA1 criterion 3)', () {
    test('strips trailing x-run', () {
      expect(sectionIdPatternPrefix('DACEN-ITEM-xxx'), 'DACEN-ITEM-');
    });

    test('leaves non-x tail untouched', () {
      expect(sectionIdPatternPrefix('FOO-BAR'), 'FOO-BAR');
    });

    test('single x placeholder', () {
      expect(sectionIdPatternPrefix('ITEM-x'), 'ITEM-');
    });
  });

  group('generateListItemSectionId (AA1 criteria 3, 4, 6)', () {
    final date = DateTime(2026, 1, 2); // two-letter-date = AB

    test('first item on a day -> prefix + date + 1', () {
      expect(
        generateListItemSectionId('DACEN-ITEM-xxx', date, const []),
        'DACEN-ITEM-AB1',
      );
    });

    test('second item on same day -> +2', () {
      expect(
        generateListItemSectionId(
          'DACEN-ITEM-xxx',
          date,
          const ['DACEN-ITEM-AB1'],
        ),
        'DACEN-ITEM-AB2',
      );
    });

    test('uses max-for-day + 1, ignoring gaps (criterion 6 non-consecutive)', () {
      // AB2 deleted, AB1 and AB3 remain -> next is AB4, not AB2.
      expect(
        generateListItemSectionId(
          'DACEN-ITEM-xxx',
          date,
          const ['DACEN-ITEM-AB1', 'DACEN-ITEM-AB3'],
        ),
        'DACEN-ITEM-AB4',
      );
    });

    test('same-day reuse after last deleted (criterion 6 reuse)', () {
      // AB1, AB2 existed; AB2 (the last) deleted -> only AB1 remains ->
      // next same-day add reuses AB2.
      expect(
        generateListItemSectionId(
          'DACEN-ITEM-xxx',
          date,
          const ['DACEN-ITEM-AB1'],
        ),
        'DACEN-ITEM-AB2',
      );
    });

    test('ignores ids from other days', () {
      // A prior day's ids do not affect today's numbering.
      expect(
        generateListItemSectionId(
          'DACEN-ITEM-xxx',
          date,
          const ['DACEN-ITEM-AA5'],
        ),
        'DACEN-ITEM-AB1',
      );
    });
  });
}
