import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

/// A PD section leaf carrying scalar content — stands in for a real PD00
/// content-bearing node ([DocumentHeader]/[SectionMeta] behave identically).
class _PdSection with SpecNode {
  String? content;

  @override
  String? yamlScalar() => content;

  @override
  _PdSection cloneShallow() => _PdSection()..content = content;
}

/// A minimal Project Definition root owning one shared section.
class _PdRoot with SpecNode {
  _PdSection? section = _PdSection();

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => section, (v) => section = v as _PdSection?,
            label: 'section'),
      ];

  @override
  _PdRoot cloneShallow() => _PdRoot()..section = section;
}

/// A projection root: it owns no content of its own — its `section` slot is a
/// *reference* bound onto the live PD section by [connect] (N12, pure
/// projection). Between writes the reference may be stale/unset; the connect
/// pass re-points it to whatever PD currently holds, immediately before write.
class _Projection with SpecNode, SpecProjection {
  _PdSection? section;

  @override
  void connect(SpecNode source) {
    section = (source as _PdRoot).section;
  }

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => section, (v) => section = v as _PdSection?,
            label: 'section'),
      ];

  @override
  _Projection cloneShallow() => _Projection()..section = section;
}

void main() {
  group('SpecYaml — toYaml + connect pass (N11, N12)', () {
    test('(a) global save emits the shared section exactly once', () {
      final pd = _PdRoot()..section = (_PdSection()..content = 'shared');
      final projection = _Projection()..connect(pd);

      // Both roots now reference the same live section by identity.
      expect(identical(projection.section, pd.section), isTrue);

      // The global save serializes ONLY the Project Definition (N11), so the
      // shared content appears once — the projection's reference is not
      // emitted as a second copy.
      final yaml = SpecYaml.toYaml(pd);
      final occurrences = 'shared'.allMatches(yaml).length;
      expect(occurrences, 1);
    });

    test('(b) an individual projection write reflects current PD content', () {
      final pd = _PdRoot()..section = (_PdSection()..content = 'v1');
      final projection = _Projection();

      // Connect-before-write binds to the live PD section, so the projection
      // write reflects whatever PD currently holds.
      final firstWrite = SpecYaml.toYamlForProjection(projection, pd);
      expect(firstWrite, contains('v1'));

      // Edit PD, connect again before the next write: the projection write now
      // reflects the new content — no stale copy is kept in sync.
      pd.section!.content = 'v2';
      final secondWrite = SpecYaml.toYamlForProjection(projection, pd);
      expect(secondWrite, contains('v2'));
      expect(secondWrite, isNot(contains('v1')));
    });

    test('(c) a null PD section stays null in the projection', () {
      final pd = _PdRoot()..section = null;
      final projection = _Projection()..section = (_PdSection()..content = 'x');

      projection.connect(pd);

      // One shared tree: a null section in PD is null in the projection too —
      // the connect pass re-points, it never invents content (N12).
      expect(projection.section, isNull);
      final map = SpecYaml.toMap(projection);
      expect(map['section'], isNull);
    });

    test('toMap exposes scalar content and nested structure', () {
      final pd = _PdRoot()..section = (_PdSection()..content = 'hello');
      final map = SpecYaml.toMap(pd);
      expect((map['section'] as Map)['content'], 'hello');
    });

    test('real model leaves serialize their packed content', () {
      final header = DocumentHeader()..content = 'doc-id: X';
      final meta = SectionMeta()..content = 'sectionId: Y';
      expect(SpecYaml.toMap(header)['content'], 'doc-id: X');
      expect(SpecYaml.toMap(meta)['content'], 'sectionId: Y');
    });
  });
}
