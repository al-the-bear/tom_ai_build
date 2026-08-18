/// `SpecYaml` — the connect-before-write pass (N11, N12) and the document shape
/// the nine SOM runtimes read (SOM §12).
///
/// The shape is not asserted by describing it a second time here: `SpecYaml`
/// projects onto a [SpecDocument] and hands it to the runtime's
/// [SpecDocumentYaml], so what these tests check is that the projection is
/// *complete and faithful* — a document written through it decodes in the
/// runtime and re-encodes byte-for-byte. A value the projection dropped, or
/// keyed differently, cannot survive that trip.
library;

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show
        SomDocMeta,
        SomFormFieldMeta,
        SomFormMeta,
        SomMetaKind,
        SomMetaNode,
        SomMetaTree,
        SpecDocumentYaml,
        SpecYamlFormatException;
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';

/// An SBP section leaf carrying scalar content — stands in for a real Solution
/// Blueprint content-bearing node ([DocumentHeader] behaves identically).
class _SbpSection extends DocSpecsSection with SpecNode {
  @override
  String? yamlScalar() => content;

  @override
  _SbpSection cloneShallow() => _SbpSection()
    ..content = content
    ..headline = headline
    ..id = id
    ..codeSpec = List.of(codeSpec)
    ..form = form;
}

/// A minimal Solution Blueprint root owning one shared section.
class _SbpRoot extends DocSpecsSection with SpecNode {
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
class _Projection extends DocSpecsSection with SpecNode, SpecProjection {
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

/// Exercises the three key shapes on one node: an id-bearing child, an id-less
/// child, and an id-bearing list of sections.
class _KeyedRoot extends DocSpecsSection with SpecNode {
  _SbpSection? keyed;
  _SbpSection? unkeyed;
  List<_SbpSection> entries = [];

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => keyed, (v) => keyed = v as _SbpSection?,
            label: 'keyed', sectionId: 'SEC'),
        SpecSlot.node(() => unkeyed, (v) => unkeyed = v as _SbpSection?,
            label: 'unkeyed'),
        SpecSlot.list(() => entries, (v) => entries = v.cast<_SbpSection>(),
            label: 'entries', sectionId: 'ENT-LST'),
      ];

  @override
  _KeyedRoot cloneShallow() => _KeyedRoot()
    ..keyed = keyed
    ..unkeyed = unkeyed
    ..entries = entries;
}

/// A node whose slot carries no label at all — walked structurally only, and
/// therefore not serializable.
class _UnlabelledRoot extends DocSpecsSection with SpecNode {
  _SbpSection? child;

  @override
  List<SpecSlot> specSlots() =>
      [SpecSlot.node(() => child, (v) => child = v as _SbpSection?)];

  @override
  _UnlabelledRoot cloneShallow() => _UnlabelledRoot()..child = child;
}

/// A root owning one `@Form` section.
class _FormRoot extends DocSpecsSection with SpecNode {
  _SbpSection? header;

  @override
  List<SpecSlot> specSlots() => [
        SpecSlot.node(() => header, (v) => header = v as _SbpSection?,
            label: 'header', sectionId: 'HDR'),
      ];

  @override
  _FormRoot cloneShallow() => _FormRoot()..header = header;
}

// --- metadata fixtures ------------------------------------------------------
//
// A SomMetaNode belongs to exactly one tree, so every fixture is a *builder*:
// each test wires its own tree.

SomMetaNode _content(String member, {String? id}) => SomMetaNode(
      className: '_SbpSection',
      memberName: member,
      sectionId: id,
      kind: SomMetaKind.content,
      typeName: 'String',
    );

SomMetaTree _root(String id, String className, List<SomMetaNode> children) =>
    SomMetaTree(SomMetaNode(
      className: className,
      sectionId: id,
      kind: SomMetaKind.section,
      typeName: className,
      document: SomDocMeta(name: className, description: ''),
      children: children,
    ));

SomMetaTree _sbpTree() => _root('SBP', '_SbpRoot', [_content('section')]);

SomMetaTree _keyedTree({bool describeUnkeyed = true}) =>
    _root('KEY', '_KeyedRoot', [
      _content('keyed', id: 'SEC'),
      if (describeUnkeyed) _content('unkeyed'),
      SomMetaNode(
        className: '_KeyedRoot',
        memberName: 'entries',
        sectionId: 'ENT-LST',
        kind: SomMetaKind.list,
        typeName: '_SbpSection',
        elementNode: SomMetaNode(
          className: '_SbpSection',
          kind: SomMetaKind.complex,
          typeName: '_SbpSection',
          children: [_content('content')],
        ),
      ),
    ]);

SomMetaTree _formTree() => _root('FRM', '_FormRoot', [
      SomMetaNode(
        className: '_SbpSection',
        memberName: 'header',
        sectionId: 'HDR',
        kind: SomMetaKind.form,
        typeName: 'String',
        form: const SomFormMeta(fields: [
          SomFormFieldMeta(name: 'author', typeName: 'String', order: 0),
          SomFormFieldMeta(name: 'version', typeName: 'String', order: 1),
        ]),
      ),
    ]);

/// Encodes [root] and asserts the result survives a runtime decode → re-encode
/// unchanged, then returns it. This is the DONE-WHEN check in one line: a
/// document `SpecYaml` writes parses in `tom_som_dart_runtime` and re-serializes
/// byte-identically.
String _roundTripped(Object root, SomMetaTree Function() tree) {
  final written = SpecYaml.toYaml(root, tree: tree());
  final reloaded = SpecDocumentYaml.decode(written, tree());
  final rewritten =
      SpecDocumentYaml.encode(document: reloaded.document, tree: tree());
  expect(rewritten, written, reason: 'the written document is not a fixed '
      'point of the runtime codec — SpecYaml and SpecDocumentYaml disagree');
  return written;
}

void main() {
  group('SpecYaml — the connect pass (N11, N12)', () {
    test('(a) global save emits the shared section exactly once', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'shared');
      final projection = _Projection()..connect(sbp);

      // Both roots now reference the same live section by identity.
      expect(identical(projection.section, sbp.section), isTrue);

      // The global save serializes ONLY the Solution Blueprint (N11), so the
      // shared content appears once — the projection's reference is not
      // emitted as a second copy.
      final yaml = _roundTripped(sbp, _sbpTree);
      expect('shared'.allMatches(yaml).length, 1);
    });

    test('(b) an individual projection write reflects current SBP content', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'v1');
      final projection = _Projection();

      // Connect-before-write binds to the live SBP section, so the projection
      // write reflects whatever SBP currently holds.
      final firstWrite =
          SpecYaml.toYamlForProjection(projection, sbp, tree: _sbpTree());
      expect(firstWrite, contains('v1'));

      // Edit SBP, connect again before the next write: the projection write now
      // reflects the new content — no stale copy is kept in sync.
      sbp.section!.content = 'v2';
      final secondWrite =
          SpecYaml.toYamlForProjection(projection, sbp, tree: _sbpTree());
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
      expect(SpecYaml.toDocument(projection, tree: _sbpTree()).isEmpty, isTrue);
    });
  });

  group('SpecYaml — the document shape the SOM runtimes read (SOM §12)', () {
    test('writes the v2 preamble and the document wrapper', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'hello');
      final yaml = _roundTripped(sbp, _sbpTree);

      expect(yaml, startsWith('# TomSpecs document'));
      expect(yaml, contains('version: ${SpecDocumentYaml.formatVersion}'));
      // The root node's map hangs under `document:`, never at top level, and
      // its key is the SOM §12.2 `<sectionId> <memberName>` pair like any
      // other — for a root the member half is the class name.
      expect(yaml, contains('document:\n  SBP _SbpRoot:\n'));
    });

    test('stamps the authoring model version when the caller knows it', () {
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'hello');
      final yaml =
          SpecYaml.toYaml(sbp, tree: _sbpTree(), modelVersion: '2.7');
      expect(yaml, contains('modelVersion: '));
      expect(SpecDocumentYaml.decode(yaml, _sbpTree()).modelVersion, '2.7');
    });

    test('omits an unset section rather than writing a null', () {
      final sbp = _SbpRoot()..section = null;
      final yaml = _roundTripped(sbp, _sbpTree);

      expect(yaml, isNot(contains('section')));
      expect(yaml, isNot(contains('null')));
    });

    test('omits an empty list rather than writing an empty sequence', () {
      final root = _KeyedRoot()..entries = [];
      final yaml = _roundTripped(root, _keyedTree);

      expect(yaml, isNot(contains('entries')));
      expect(yaml, isNot(contains('[]')));
    });

    test('writes list items as indexed keys, never YAML sequences', () {
      final root = _KeyedRoot()
        ..entries = [
          _SbpSection()..content = 'first',
          _SbpSection()..content = 'second',
        ];
      final yaml = _roundTripped(root, _keyedTree);

      expect(yaml, contains('ENT-LST entries:'));
      expect(yaml, contains('entries-1:'));
      expect(yaml, contains('entries-2:'));
      // A YAML sequence would make the item keys positional, and no runtime
      // reads them that way.
      expect(yaml, isNot(contains('\n      - ')));
    });

    test('a list item keyed by its own section id keeps that id', () {
      final root = _KeyedRoot()
        ..entries = [
          _SbpSection()
            ..id = 'ENT-ab1'
            ..content = 'first',
        ];
      final yaml = _roundTripped(root, _keyedTree);

      expect(yaml, contains('ENT-ab1:'));
      expect(yaml, isNot(contains('entries-1:')));
    });

    test('carries the stored headline and the codeSpec link', () {
      final sbp = _SbpRoot()
        ..section = (_SbpSection()
          ..content = 'body'
          ..headline = 'A Chosen Title'
          ..codeSpec = ['CE-FORM/x.dart', 'CE-TABLE/y.dart']);
      final yaml = _roundTripped(sbp, _sbpTree);

      expect(yaml, contains('A Chosen Title'));
      expect(yaml, contains('CE-FORM/x.dart,CE-TABLE/y.dart'));
    });

    test('writes a @Form section as its named field values', () {
      final root = _FormRoot()
        ..header = (_SbpSection()
          ..form = DocSpecsForm(values: {'author': 'AK', 'version': '1.0'}));
      final yaml = _roundTripped(root, _formTree);

      expect(yaml, contains('HDR header:'));
      expect(yaml, contains('author:'));
      expect(yaml, contains('version:'));
    });

    test('a @Form section\'s free text is its preamble, and it round-trips '
        '(SOM §11.4 rule 7 / §12.2)', () {
      // `DocSpecsSection.content` is the single home for a section's free
      // text, form or not — a form is not an exception, so a document caught
      // mid-import (fields not yet split out) is still saveable.
      final root = _FormRoot()
        ..header = (_SbpSection()..content = 'raw text\nnot yet split');
      final yaml = _roundTripped(root, _formTree);

      expect(yaml, contains('HDR header:'));
      expect(yaml, contains('content:'));
      final doc = SpecDocumentYaml.decode(yaml, _formTree()).document;
      expect(doc.content('FRM/HDR'), 'raw text\nnot yet split');
    });

    test('a @Form section carries preamble and fields side by side', () {
      final root = _FormRoot()
        ..header = (_SbpSection()
          ..content = 'why this header exists'
          ..form = DocSpecsForm(values: {'author': 'AK'}));
      final yaml = _roundTripped(root, _formTree);

      final doc = SpecDocumentYaml.decode(yaml, _formTree()).document;
      expect(doc.content('FRM/HDR'), 'why this header exists');
      expect(doc.formField('FRM/HDR', 'author'), 'AK');
    });

    test('a multi-line scalar survives the round trip', () {
      final sbp = _SbpRoot()
        ..section = (_SbpSection()..content = 'line one\n\nline two\n');
      final yaml = _roundTripped(sbp, _sbpTree);
      final doc = SpecDocumentYaml.decode(yaml, _sbpTree()).document;
      expect(doc.content('SBP/section'), 'line one\n\nline two\n');
    });

    test('a scalar no literal block can hold falls back to a quoted scalar',
        () {
      // Trailing spaces cannot be represented by a block scalar; the runtime
      // encoder detects that and quotes instead. The projection must not
      // pre-empt that decision — it hands over the string unchanged.
      final sbp = _SbpRoot()..section = (_SbpSection()..content = 'trails   ');
      final yaml = _roundTripped(sbp, _sbpTree);
      final doc = SpecDocumentYaml.decode(yaml, _sbpTree()).document;
      expect(doc.content('SBP/section'), 'trails   ');
    });
  });

  group('SpecYaml — values the format has no home for are refused', () {
    test('an unlabelled slot is refused rather than given a positional key', () {
      final root = _UnlabelledRoot()..child = (_SbpSection()..content = 'z');
      final tree = _root('UNL', '_UnlabelledRoot', [_content('child')]);
      expect(
        () => SpecYaml.toDocument(root, tree: tree),
        throwsA(isA<SpecYamlFormatException>()),
      );
    });

    test('a slot the metadata does not describe is refused', () {
      final root = _KeyedRoot()..unkeyed = (_SbpSection()..content = 'y');
      expect(
        () => SpecYaml.toDocument(root,
            tree: _keyedTree(describeUnkeyed: false)),
        throwsA(isA<SpecYamlFormatException>()),
      );
    });

    test('a key that disagrees with the metadata is refused', () {
      final root = _KeyedRoot()..keyed = (_SbpSection()..content = 'x');
      // The metadata says `keyed` has no section id; the slot says `SEC`.
      final tree = _root('KEY', '_KeyedRoot', [
        _content('keyed'),
        _content('unkeyed'),
      ]);
      expect(
        () => SpecYaml.toDocument(root, tree: tree),
        throwsA(isA<SpecYamlFormatException>()),
      );
    });
  });
}
