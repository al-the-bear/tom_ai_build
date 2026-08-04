import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

/// A representative container [SpecNode] used to exercise tree-level structural
/// sharing: a scalar field, two single-child node slots holding real model
/// leaves ([DocumentHeader]), and a list slot of the same real model leaf.
class _Section with SpecNode {
  String? content;
  DocumentHeader headerA = DocumentHeader();
  DocumentHeader headerB = DocumentHeader();
  List<DocumentHeader> metas = [];

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => headerA, (v) => headerA = v as DocumentHeader),
        SpecSlot.node(() => headerB, (v) => headerB = v as DocumentHeader),
        SpecSlot.list(() => metas, (v) => metas = v.cast<DocumentHeader>()),
      ];

  @override
  _Section cloneShallow() => _Section()
    ..content = content
    ..headerA = headerA
    ..headerB = headerB
    ..metas = metas;
}

void main() {
  group('SpecSnapshotter — copy-on-write structural sharing (N5, U1)', () {
    test('unchanged leaves are shared by identity with the predecessor', () {
      final live = _Section()..content = 'root';
      live.headerA.content = 'A0';
      live.headerB.content = 'B0';
      live.metas = [
        DocumentHeader()..content = 'm0',
        DocumentHeader()..content = 'm1',
      ];

      // First snapshot: a full independent picture (shares nothing with live).
      final s1 = SpecSnapshotter.snapshot(live) as _Section;
      expect(s1.headerA.content, 'A0');
      expect(identical(s1.headerA, live.headerA), isFalse);

      // Edit exactly one leaf and route the change through markDirty (the
      // editor's shared controller does this on every edit, §8).
      live.headerA.content = 'A1';
      live.headerA.markDirty();

      final s2 = SpecSnapshotter.snapshot(live, previous: s1) as _Section;

      // The untouched sibling leaf is shared by identity across snapshots.
      expect(identical(s2.headerB, s1.headerB), isTrue);
      // The untouched list elements are shared by identity too.
      expect(identical(s2.metas[0], s1.metas[0]), isTrue);
      expect(identical(s2.metas[1], s1.metas[1]), isTrue);

      // The edited leaf is cloned, not shared, and the snapshots are isolated.
      expect(identical(s2.headerA, s1.headerA), isFalse);
      expect(s2.headerA.content, 'A1');
      expect(s1.headerA.content, 'A0');
      // The root changed (a descendant changed) so it is cloned.
      expect(identical(s2, s1), isFalse);
    });

    test('a no-op snapshot shares the whole predecessor tree by identity', () {
      final live = _Section()..content = 'root';
      live.headerA.content = 'A0';

      final s1 = SpecSnapshotter.snapshot(live);
      // No edits since s1 → the next snapshot is the very same object.
      final s2 = SpecSnapshotter.snapshot(live, previous: s1);
      expect(identical(s2, s1), isTrue);
    });

    test('real model leaves (DocumentHeader) snapshot and share correctly', () {
      final live = DocumentHeader()..content = 'x';

      final s1 = SpecSnapshotter.snapshot(live) as DocumentHeader;
      expect(s1.content, 'x');
      expect(identical(s1, live), isFalse);

      // Unchanged → shared with predecessor by identity.
      final s2 = SpecSnapshotter.snapshot(live, previous: s1);
      expect(identical(s2, s1), isTrue);

      // Changed → cloned; the old snapshot keeps its value.
      live.content = 'y';
      live.markDirty();
      final s3 = SpecSnapshotter.snapshot(live, previous: s2) as DocumentHeader;
      expect(identical(s3, s2), isFalse);
      expect(s3.content, 'y');
      expect((s2 as DocumentHeader).content, 'x');
    });

    test('restore produces an independent editable tree', () {
      final live = _Section()..content = 'root';
      live.headerA.content = 'A0';
      live.metas = [DocumentHeader()..content = 'm0'];

      final s1 = SpecSnapshotter.snapshot(live) as _Section;

      final restored = SpecSnapshotter.restore(s1) as _Section;
      expect(restored.content, 'root');
      expect(restored.headerA.content, 'A0');
      expect(restored.metas.single.content, 'm0');

      // Restore shares nothing with the snapshot — editing it leaves s1 intact.
      expect(identical(restored.headerA, s1.headerA), isFalse);
      restored.headerA.content = 'edited';
      expect(s1.headerA.content, 'A0');
    });
  });
}
