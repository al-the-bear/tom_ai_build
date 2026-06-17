import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

/// Exercises the generated `spec_ops.g.dart` registry (OE-2) end-to-end on the
/// **real** 3000-class model — not the synthetic leaves of `serialization_test`.
///
/// Constructing a [DocSpecsProject] runs `registerSpecOps()`, so the
/// reflection-free engine (`SpecSnapshotter` / `SpecYaml`) can snapshot, clone
/// and serialize every model class through `SpecRegistry` even though none of
/// them mixes in `SpecNode`.
void main() {
  group('registry-backed engine on the real model (OE-2)', () {
    test('registerSpecOps registers ops for the whole model + section leaves',
        () {
      DocSpecsProject(); // idempotent registration
      // 3079 reflected model classes, minus the two hand-written `SpecNode`
      // leaves (DocumentHeader, SectionMeta) that adopt the contract via the
      // mixin fast-path, plus the 10 tom_specs_core section content leaves.
      expect(SpecRegistry.length, greaterThanOrEqualTo(3079 - 2 + 10));
      // A representative deep model class resolves to real ops.
      expect(SpecRegistry.opsFor(CurrentStateAnalysis), isNotNull);
    });

    test('toYaml serializes a content leaf reachable from the PD root', () {
      final project = DocSpecsProject();
      project.projectDefinition.header.content = 'doc-id: PD-DEMO';

      final yaml = project.toYaml();
      expect(yaml, contains('doc-id: PD-DEMO'));
    });

    test('COW snapshot shares an unchanged tree but re-clones the edited path',
        () {
      final project = DocSpecsProject();
      final pd = project.projectDefinition;

      // First snapshot: a full independent copy.
      final s1 = SpecSnapshotter.snapshot(pd);

      // No edits → the next snapshot is the same object by identity.
      final s2 = SpecSnapshotter.snapshot(pd, previous: s1);
      expect(identical(s1, s2), isTrue,
          reason: 'an unchanged tree shares its predecessor by identity');

      // Edit one leaf and mark it dirty, then snapshot again.
      pd.header.content = 'edited';
      markDirtyNode(pd.header);
      final s3 = SpecSnapshotter.snapshot(pd, previous: s2);

      // The root is re-cloned (the edited-leaf→root path changed) ...
      expect(identical(s3, s2), isFalse);

      // ... but a sibling top-level subtree that did not change is shared by
      // identity between the two snapshots (true copy-on-write).
      final s2Slots = specSlotsOf(s2);
      final s3Slots = specSlotsOf(s3);
      expect(s2Slots.length, s3Slots.length);
      final sharedSiblings = <int>[];
      for (var i = 0; i < s2Slots.length; i++) {
        if (s2Slots[i].isList) continue;
        final a = s2Slots[i].node;
        final b = s3Slots[i].node;
        if (a != null && identical(a, b)) sharedSiblings.add(i);
      }
      expect(sharedSiblings, isNotEmpty,
          reason: 'unchanged siblings must be shared, not deep-copied');
    });
  });
}
