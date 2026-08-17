import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The Phase-4 extract generator (`codespecs_mapping.md` §1.1.1).
///
/// The four cases the surface exists to get right are the four this file is
/// organised around: a section routed to several areas appears in all of them,
/// a `@FollowUpKind` subtree appears in none, an unrouted section is a hard
/// error, and every scalar emitted occurs character-for-character in its source.
void main() {
  group('CodeSpecsExtractor', () {
    test('routes a multi-area section into every area it names', () {
      final extracts = _extractor().extractAll();
      final byCode = {for (final e in extracts) e.area.code: e};

      // `Order` carries @CodeSpecKind([form, viewState]) — the same value must
      // appear whole in both extracts, undeduplicated.
      final inForm = byCode['CE-FM']!.entries.where((e) => e.path == 'ORD/TTL');
      final inView = byCode['CE-ST']!.entries.where((e) => e.path == 'ORD/TTL');
      expect(inForm, hasLength(1));
      expect(inView, hasLength(1));
      expect(inForm.single.value, 'Place an order');
      expect(inView.single.value, 'Place an order');
      expect(inForm.single.routedBy, 'CodeSpecPart.form');
      expect(inView.single.routedBy, 'CodeSpecPart.viewState');
    });

    test('emits one extract per active area, empty ones included', () {
      final extracts = _extractor().extractAll();
      expect(
        extracts.map((e) => e.area.code),
        ['CE-FM', 'CE-ST', 'CE-TX', 'CE-ER'],
      );
      // CE-ER is in the catalogue but nothing in this document routes to it.
      // An area with no content still gets an extract: "no requirement stated"
      // is a finding the authoring agent must see, not a missing file.
      expect(extracts.last.entries, isEmpty);
    });

    test('excludes the whole subtree under a @FollowUpKind root', () {
      final extractor = _extractor();
      final everyValue = [
        for (final x in extractor.extractAll()) ...x.entries.map((e) => e.value),
      ];
      // `Handover` is populated, and populated with text distinctive enough
      // that its absence cannot be an accident of an empty section.
      expect(everyValue, isNot(contains('Train the counter staff')));
      expect(everyValue, isNot(contains('operations')));

      final handover = extractor
          .routings()
          .firstWhere((r) => r.className == 'Handover');
      expect(handover.verdict, CodeSpecsRoutingVerdict.feedsProcess);
      expect(handover.values, ['trn']);
    });

    test('lets a field-level @CodeSpecKind override its class', () {
      final byCode = {
        for (final e in _extractor().extractAll()) e.area.code: e,
      };
      // Order routes to form+viewState, but Order.helpText routes to text only.
      final text = byCode['CE-TX']!.entries.where((e) => e.path == 'ORD/HLP');
      expect(text, hasLength(1));
      expect(text.single.routedAt, 'Order.helpText');
      expect(
        byCode['CE-FM']!.entries.where((e) => e.path == 'ORD/HLP'),
        isEmpty,
      );
    });

    test('descends through a @NoArtifact container but emits none of its own',
        () {
      final byCode = {
        for (final e in _extractor().extractAll()) e.area.code: e,
      };
      // `Registry` is @NoArtifact(container): its own summary is not emitted…
      expect(
        [for (final x in byCode.values) ...x.entries.map((e) => e.path)],
        isNot(contains('ORD/REG/SUM')),
      );
      // …but the routed `Entry` below it is.
      expect(
        byCode['CE-FM']!.entries.map((e) => e.path),
        contains(startsWith('ORD/REG/ENT-')),
      );
    });

    test('throws on a section carrying none of the three verdicts', () {
      final extractor = CodeSpecsExtractor(
        model: _model(unroutedRegistry: true),
        document: _document(),
        catalog: _catalog(),
      );
      expect(
        () => extractor.extractAll(),
        throwsA(isA<CodeSpecsExtractError>()
            .having((e) => e.className, 'className', 'Registry')
            .having((e) => e.message, 'message', contains('ROUTE-TOTAL'))),
      );
      // The non-throwing diagnostic reports the same node instead.
      expect(
        extractor.routings().map((r) => r.verdict),
        contains(CodeSpecsRoutingVerdict.unrouted),
      );
    });

    test('carries resolvable provenance on every entry', () {
      final model = _model();
      final reflection = SpecReflection(model);
      for (final extract in _extractor().extractAll()) {
        for (final entry in extract.entries) {
          final cls = model.classNamed(entry.className);
          expect(cls, isNotNull, reason: '${entry.path}: unknown class');
          expect(cls!.fieldNamed(entry.fieldName), isNotNull,
              reason: '${entry.path}: unknown field ${entry.fieldName}');
          expect(reflection.resolve(entry.path), isNotNull,
              reason: '${entry.path}: unresolvable path');
          expect(entry.routedAt, isNotEmpty);
          expect(entry.routedBy, startsWith('CodeSpecPart.'));
        }
      }
    });

    test('every emitted value occurs verbatim in the source document', () {
      // The guard the contract rests on: the generator may copy and index, it
      // may not compose. Checking that each value *is* a value the document
      // stores — not merely a substring of one — is what makes "verbatim"
      // mean verbatim rather than "derived from".
      final document = _document();
      final json = document.toJson();
      final stored = <String>{
        ...(json['content'] as Map).values.cast<String>(),
        for (final section in (json['forms'] as Map).values)
          ...(section as Map).values.cast<String>(),
      };
      expect(stored, isNotEmpty);
      for (final extract in _extractor().extractAll()) {
        for (final entry in extract.entries) {
          expect(stored, contains(entry.value),
              reason: '${entry.path} was not copied from the document');
        }
      }
    });

    test('derives citable areas transitively from the slice graph', () {
      final catalog = _catalog();
      // CE-FM sits in slice 2, which cites slice 1 — so it reaches both areas
      // that live there, and the result is in catalogue order rather than
      // discovery order.
      expect(
        catalog.citableAreaCodes(catalog.byCode('CE-FM')!),
        ['CE-TX', 'CE-ER'],
      );
      // CE-ST is slice 5, which cites 2 and so reaches 1 transitively.
      expect(
        catalog.citableAreaCodes(catalog.byCode('CE-ST')!),
        ['CE-FM', 'CE-TX', 'CE-ER'],
      );
      // Slice 1 cites no other slice, so CE-TX reaches only its own slice —
      // within-slice citation is legal, hence its slice-mate but nothing above.
      expect(catalog.citableAreaCodes(catalog.byCode('CE-TX')!), ['CE-ER']);
    });
  });

  group('CodeSpecsExtract emission', () {
    test('YAML carries the area context and every entry', () {
      final yaml = _extractor().extractFor('CE-FM')!.toYaml();
      expect(yaml, contains('formatVersion: $kCodeSpecsExtractFormat'));
      expect(yaml, contains('code: "CE-FM"'));
      expect(yaml, contains('part: "CodeSpecPart.form"'));
      expect(yaml, contains('citableParts: ["CE-TX", "CE-ER"]'));
      expect(yaml, contains('value: "Place an order"'));
      expect(yaml, contains('routedAt: "Order"'));
    });

    test('YAML escapes a value that would otherwise break the document', () {
      final document = _document();
      document.setContent('ORD/TTL', 'a "quoted"\nline\\end');
      final extract = CodeSpecsExtractor(
        model: _model(),
        document: document,
        catalog: _catalog(),
      ).extractFor('CE-FM')!;
      expect(
        extract.toYaml(),
        contains(r'value: "a \"quoted\"\nline\\end"'),
      );
    });

    test('Markdown fences a value containing its own fence', () {
      final document = _document();
      document.setContent('ORD/TTL', 'see ```dart\nx();\n``` above');
      final extract = CodeSpecsExtractor(
        model: _model(),
        document: document,
        catalog: _catalog(),
      ).extractFor('CE-FM')!;
      final md = extract.toMarkdown();
      expect(md, contains('```` text'));
      expect(md, contains('see ```dart'));
    });

    test('Markdown says so when an area has no content', () {
      final md = _extractor().extractFor('CE-ER')!.toMarkdown();
      expect(md, contains('## Entries (0)'));
      expect(md, contains('No section of this document is routed to'));
    });

    test('names the file after the area code', () {
      expect(_extractor().extractFor('CE-FM')!.fileStem, 'CE-FM.extract');
    });
  });
}

// --- fixture ----------------------------------------------------------------

CodeSpecsExtractor _extractor() => CodeSpecsExtractor(
      model: _model(),
      document: _document(),
      catalog: _catalog(),
    );

SpecAnnotation _kind(List<String> kinds, {String? note}) => SpecAnnotation(
      name: 'CodeSpecKind',
      arguments: {
        'kinds': [for (final k in kinds) 'CodeSpecPart.$k'],
        if (note != null) 'note': note,
      },
    );

/// A four-class model: a routed root, a follow-up subtree, a container and a
/// routed list element.
SpecModel _model({bool unroutedRegistry = false}) => SpecModel(
      roots: [SpecRoot(type: 'Order', title: 'Order', sectionId: 'ORD')],
      classes: {
        'Order': SpecClass(
          name: 'Order',
          sectionId: 'ORD',
          annotations: [
            const SpecAnnotation(name: 'Document', arguments: {'title': 'Order'}),
            _kind(['form', 'viewState'], note: 'the order capture screen'),
          ],
          fields: [
            SpecField(
                name: 'title', kind: SpecFieldKind.content, sectionId: 'TTL'),
            SpecField(
              name: 'helpText',
              kind: SpecFieldKind.content,
              sectionId: 'HLP',
              annotations: [_kind(['text'])],
            ),
            SpecField(
              name: 'shape',
              kind: SpecFieldKind.form,
              sectionId: 'SHP',
              formFields: [
                FormFieldSpec(name: 'width', label: 'Width', type: 'String'),
                FormFieldSpec(name: 'height', label: 'Height', type: 'String'),
              ],
            ),
            SpecField(
              name: 'tags',
              kind: SpecFieldKind.list,
              sectionId: 'TAG',
              elementType: 'String',
            ),
            SpecField(
                name: 'registry',
                kind: SpecFieldKind.complex,
                sectionId: 'REG',
                type: 'Registry'),
            SpecField(
                name: 'handover',
                kind: SpecFieldKind.complex,
                sectionId: 'HND',
                type: 'Handover'),
          ],
        ),
        'Registry': SpecClass(
          name: 'Registry',
          sectionId: 'REG',
          annotations: unroutedRegistry
              ? const []
              : [
                  const SpecAnnotation(
                    name: 'NoArtifact',
                    arguments: {'reason': 'NoArtifactReason.container'},
                  ),
                ],
          fields: [
            SpecField(
                name: 'summary', kind: SpecFieldKind.content, sectionId: 'SUM'),
            SpecField(
              name: 'entries',
              kind: SpecFieldKind.list,
              sectionId: 'ENT',
              elementType: 'Entry',
              elementIsComplex: true,
            ),
          ],
        ),
        'Entry': SpecClass(
          name: 'Entry',
          sectionId: 'ENT',
          annotations: [_kind(['form'])],
          fields: [
            SpecField(
                name: 'label', kind: SpecFieldKind.content, sectionId: 'LBL'),
          ],
        ),
        'Handover': SpecClass(
          name: 'Handover',
          sectionId: 'HND',
          annotations: [
            const SpecAnnotation(
              name: 'FollowUpKind',
              arguments: {
                'processes': ['FollowUpProcess.trn'],
                'note': 'delivered as counter training, not as code',
              },
            ),
          ],
          fields: [
            SpecField(
                name: 'plan', kind: SpecFieldKind.content, sectionId: 'PLN'),
            SpecField(
                name: 'owner', kind: SpecFieldKind.content, sectionId: 'OWN'),
          ],
        ),
      },
    );

SpecDocument _document() {
  final d = SpecDocument();
  d.setContent('ORD/TTL', 'Place an order');
  d.setContent('ORD/HLP', 'Pick a size, then confirm.');
  d.setFormField('ORD/SHP', 'width', '640');
  d.setFormField('ORD/SHP', 'height', '480');
  d.setContent('ORD/REG/SUM', 'Every order kind we know about.');
  final entry = d.addListItem('ORD/REG/ENT');
  d.setContent('$entry/LBL', 'Standing order');
  // Populated on purpose: its absence from every extract is the assertion.
  d.setContent('ORD/HND/PLN', 'Train the counter staff');
  d.setContent('ORD/HND/OWN', 'operations');
  return d;
}

/// Four areas over three slices, so `citableAreaCodes` has a graph to walk.
///
/// The `CE-*` codes, canonical ids and kind values are the real registry keys
/// (they are permanent, so inventing one here would put a key in circulation
/// that means nothing); the slice numbers and authoring steps are a cut-down
/// synthetic graph, not §4.4.3's.
CodeSpecsAreaCatalog _catalog() => const CodeSpecsAreaCatalog(
      source: 'codespecs_mapping.md §4.1 (test fixture)',
      slices: [
        CodeSpecsSlice(
            number: 1, title: 'Shared const catalogues', project: 'shared'),
        CodeSpecsSlice(
            number: 2, title: 'Shared contract', project: 'shared', cites: [1]),
        CodeSpecsSlice(
            number: 5,
            title: 'Client interaction core',
            project: 'client',
            cites: [2]),
      ],
      areas: [
        CodeSpecsArea(
          code: 'CE-FM',
          canonicalId: 'Form',
          part: 'form',
          annotations: ['@CsForm'],
          builtOn: 'TomForm',
          attributeSurface: 'codespecs_mapping.md §5.7.2',
          slices: [2],
          authoringSteps: [4],
        ),
        CodeSpecsArea(
          code: 'CE-ST',
          canonicalId: 'ViewState',
          part: 'viewState',
          annotations: ['@CsViewModel'],
          builtOn: 'TomObservable',
          attributeSurface: 'codespecs_mapping.md §5.4',
          slices: [5],
          authoringSteps: [21],
        ),
        CodeSpecsArea(
          code: 'CE-TX',
          canonicalId: 'Text',
          part: 'text',
          annotations: ['@CsText'],
          builtOn: 'TomText',
          attributeSurface: 'codespecs_mapping.md §5.21',
          slices: [1],
          authoringSteps: [1],
        ),
        CodeSpecsArea(
          code: 'CE-ER',
          canonicalId: 'ErrorResult',
          part: 'errorResult',
          annotations: ['@CsError'],
          builtOn: 'TomResult',
          attributeSurface: 'codespecs_mapping.md §7',
          slices: [1],
          authoringSteps: [2],
        ),
      ],
    );
