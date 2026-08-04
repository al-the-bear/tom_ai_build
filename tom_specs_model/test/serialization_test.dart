import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

/// An SBP section leaf carrying scalar content — stands in for a real Solution
/// Blueprint content-bearing node ([DocumentHeader]/[SectionMeta] behave
/// identically).
class _SbpSection with SpecNode {
  String? content;

  @override
  String? yamlScalar() => content;

  @override
  _SbpSection cloneShallow() => _SbpSection()..content = content;
}

/// A minimal Solution Blueprint root owning one shared section.
class _SbpRoot with SpecNode {
  _SbpSection? section = _SbpSection();

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => section, (v) => section = v as _SbpSection?,
            label: 'section'),
      ];

  @override
  _SbpRoot cloneShallow() => _SbpRoot()..section = section;
}

/// A projection root: it owns no content of its own — its `section` slot is a
/// *reference* bound onto the live SBP section by [connect] (N12, pure
/// projection). Between writes the reference may be stale/unset; the connect
/// pass re-points it to whatever SBP currently holds, immediately before write.
class _Projection with SpecNode, SpecProjection {
  _SbpSection? section;

  @override
  void connect(Object source) {
    section = (source as _SbpRoot).section;
  }

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => section, (v) => section = v as _SbpSection?,
            label: 'section'),
      ];

  @override
  _Projection cloneShallow() => _Projection()..section = section;
}

void main() {
  group('SpecYaml — toYaml + connect pass (N11, N12)', () {
    test('(a) global save emits the shared section exactly once', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'shared');
      final projection = _Projection()..connect(sbp);

      // Both roots now reference the same live section by identity.
      expect(identical(projection.section, sbp.section), isTrue);

      // The global save serializes ONLY the Solution Blueprint (N11), so the
      // shared content appears once — the projection's reference is not
      // emitted as a second copy.
      final yaml = SpecYaml.toYaml(sbp);
      final occurrences = 'shared'.allMatches(yaml).length;
      expect(occurrences, 1);
    });

    test('(b) an individual projection write reflects current SBP content', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'v1');
      final projection = _Projection();

      // Connect-before-write binds to the live SBP section, so the projection
      // write reflects whatever SBP currently holds.
      final firstWrite = SpecYaml.toYamlForProjection(projection, sbp);
      expect(firstWrite, contains('v1'));

      // Edit SBP, connect again before the next write: the projection write now
      // reflects the new content — no stale copy is kept in sync.
      sbp.section!.content = 'v2';
      final secondWrite = SpecYaml.toYamlForProjection(projection, sbp);
      expect(secondWrite, contains('v2'));
      expect(secondWrite, isNot(contains('v1')));
    });

    test('(c) a null SBP section stays null in the projection', () {
      final sbp = _SbpRoot()..section = null;
      final projection = _Projection()..section = (_SbpSection()..content = 'x');

      projection.connect(sbp);

      // One shared tree: a null section in SBP is null in the projection too —
      // the connect pass re-points, it never invents content (N12).
      expect(projection.section, isNull);
      final map = SpecYaml.toMap(projection);
      expect(map['section'], isNull);
    });

    test('toMap exposes scalar content and nested structure', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'hello');
      final map = SpecYaml.toMap(sbp);
      expect((map['section'] as Map)['content'], 'hello');
    });

    test('a real model leaf serializes its packed content', () {
      final header = DocumentHeader()..content = 'doc-id: X';
      expect(SpecYaml.toMap(header)['content'], 'doc-id: X');
    });
  });
}
