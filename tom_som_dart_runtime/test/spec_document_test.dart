import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('SpecDocument content/scalar leaves', () {
    test('reads back a value written by path', () {
      final doc = SpecDocument();
      expect(doc.content('PD00/vision'), isNull);
      doc.setContent('PD00/vision', 'A bold idea');
      expect(doc.content('PD00/vision'), 'A bold idea');
      expect(doc.contentPaths, contains('PD00/vision'));
    });

    test('an empty value clears the path (D4)', () {
      final doc = SpecDocument();
      doc.setContent('PD00/vision', 'x');
      doc.setContent('PD00/vision', '');
      expect(doc.content('PD00/vision'), isNull);
      expect(doc.isEmpty, isTrue);
    });

    test('hasContent is the null-free "is this leaf filled?" answer (SOM §21)',
        () {
      final doc = SpecDocument();
      // Unset: content is null, hasContent is false — a single boolean answer.
      expect(doc.content('PD00/vision'), isNull);
      expect(doc.hasContent('PD00/vision'), isFalse);
      // Set: content is the value, hasContent is true.
      doc.setContent('PD00/vision', 'A bold idea');
      expect(doc.hasContent('PD00/vision'), isTrue);
      // Cleared: back to false, matching the null content.
      doc.setContent('PD00/vision', '');
      expect(doc.hasContent('PD00/vision'), isFalse);
      // hasContent is leaf-exact: a value under the path does not fill it.
      doc.setContent('PD00/vision/nested', 'x');
      expect(doc.hasContent('PD00/vision'), isFalse);
    });
  });

  group('SpecDocument form fields', () {
    test('writes and reads form sub-fields independently', () {
      final doc = SpecDocument();
      doc.setFormField('PD00/owner', 'name', 'Ada');
      doc.setFormField('PD00/owner', 'role', 'Lead');
      expect(doc.formField('PD00/owner', 'name'), 'Ada');
      expect(doc.formField('PD00/owner', 'role'), 'Lead');
      expect(doc.formFieldNames('PD00/owner'),
          containsAll(<String>['name', 'role']));
    });

    test('clearing the last sub-field removes the whole form entry', () {
      final doc = SpecDocument();
      doc.setFormField('PD00/owner', 'name', 'Ada');
      doc.setFormField('PD00/owner', 'name', '');
      expect(doc.formField('PD00/owner', 'name'), isNull);
      expect(doc.formPaths, isNot(contains('PD00/owner')));
    });
  });

  group('SpecDocument lists', () {
    test('append yields stable monotonic item paths', () {
      final doc = SpecDocument();
      final a = doc.addListItem('PD00/risks');
      final b = doc.addListItem('PD00/risks');
      expect(a, 'PD00/risks-1');
      expect(b, 'PD00/risks-2');
      expect(doc.listItems('PD00/risks'), <String>[a, b]);
      expect(doc.listItemCount('PD00/risks'), 2);
    });

    test('removing an item purges nested values and never renumbers', () {
      final doc = SpecDocument();
      final a = doc.addListItem('PD00/risks');
      doc.setContent('$a/title', 'first');
      final removed = doc.removeListItem(a);
      expect(removed, isTrue);
      expect(doc.content('$a/title'), isNull);
      // The next append keeps counting up — no reuse of seq 1.
      final c = doc.addListItem('PD00/risks');
      expect(c, 'PD00/risks-2');
    });

    test('hasValuesUnder spans descendants and list items', () {
      final doc = SpecDocument();
      final a = doc.addListItem('PD00/risks');
      doc.setContent('$a/title', 'x');
      expect(doc.hasValuesUnder('PD00'), isTrue);
      expect(doc.hasValuesUnder('PD00/risks'), isTrue);
      expect(doc.hasValuesUnder('PD00/unrelated'), isFalse);
    });
  });

  group('SpecDocument persistence', () {
    test('toJson/loadJson round-trips every store', () {
      final doc = SpecDocument();
      doc.setContent('PD00/vision', 'idea');
      doc.setFormField('PD00/owner', 'name', 'Ada');
      final item = doc.addListItem('PD00/risks');
      doc.setContent('$item/title', 'risk');

      final restored = SpecDocument()..loadJson(doc.toJson());
      expect(restored.content('PD00/vision'), 'idea');
      expect(restored.formField('PD00/owner', 'name'), 'Ada');
      expect(restored.listItems('PD00/risks'), <String>[item]);
      expect(restored.content('$item/title'), 'risk');
      // Seq counter survives a load so a later add does not collide.
      expect(restored.addListItem('PD00/risks'), 'PD00/risks-2');
    });
  });

  group('SpecDocument undo snapshots', () {
    test('captureState/restoreState is an absolute round-trip', () {
      final doc = SpecDocument();
      doc.setContent('PD00/vision', 'first');
      final snap = doc.captureState();
      doc.setContent('PD00/vision', 'second');
      doc.setContent('PD00/extra', 'noise');
      doc.restoreState(snap);
      expect(doc.content('PD00/vision'), 'first');
      expect(doc.content('PD00/extra'), isNull);
    });

    test('fingerprint changes only when values change', () {
      final doc = SpecDocument();
      doc.setContent('PD00/vision', 'first');
      final fp1 = doc.captureState().fingerprint;
      final fp2 = doc.captureState().fingerprint;
      expect(fp1, fp2);
      doc.setContent('PD00/vision', 'second');
      expect(doc.captureState().fingerprint, isNot(fp1));
    });
  });
}
