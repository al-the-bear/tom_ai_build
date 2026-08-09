import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

/// Exercises the generated `spec_ops.g.dart` registry (OE-2) end-to-end on the
/// **real** 3000-class model — not the synthetic leaves of `serialization_test`.
///
/// Constructing a [DocSpecsProject] runs `registerSpecOps()`, so the
/// reflection-free engine (`SpecSnapshotter` / `SpecYaml`) can snapshot, clone
/// and serialize every model class through `SpecRegistry` even though none of
/// them mixes in `SpecNode`.

/// Every class `registerSpecOps()` binds: the reflected model classes, minus
/// the two hand-written `SpecNode` leaves (`DocumentHeader`, `SectionMeta`)
/// that adopt the contract through the mixin fast-path rather than the
/// registry, plus the `tom_specs_core` section content leaves.
///
/// Asserted **exactly**, not as a floor. A `>=` bound only catches a class
/// vanishing from the registry; it is silent when one is added, which is the
/// direction the model actually moves in — and a silently-registered class is
/// a class that reached all nine generated languages without anyone looking at
/// it. When a model change moves this number, the number moves with it in the
/// same commit; that edit is the record that the growth was intended.
const int expectedRegisteredSpecClasses = 1262;

void main() {
  group('registry-backed engine on the real model (OE-2)', () {
    test('registerSpecOps registers ops for the whole model + section leaves',
        () {
      DocSpecsProject(); // idempotent registration
      expect(SpecRegistry.length, expectedRegisteredSpecClasses);
      // A representative deep model class resolves to real ops.
      expect(SpecRegistry.opsFor(CurrentLandscape), isNotNull);
    });

    test('toYaml serializes a content leaf reachable from the SBP root', () {
      final project = DocSpecsProject();
      project.solutionBlueprint.documentControl.header.content =
          'doc-id: SBP-DEMO';

      final yaml = project.toYaml();
      expect(yaml, contains('doc-id: SBP-DEMO'));
    });

    test('COW snapshot shares an unchanged tree but re-clones the edited path',
        () {
      final project = DocSpecsProject();
      final pd = project.solutionBlueprint;

      // First snapshot: a full independent copy.
      final s1 = SpecSnapshotter.snapshot(pd);

      // No edits → the next snapshot is the same object by identity.
      final s2 = SpecSnapshotter.snapshot(pd, previous: s1);
      expect(identical(s1, s2), isTrue,
          reason: 'an unchanged tree shares its predecessor by identity');

      // Edit one leaf and mark it dirty, then snapshot again.
      pd.documentControl.header.content = 'edited';
      markDirtyNode(pd.documentControl.header);
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
