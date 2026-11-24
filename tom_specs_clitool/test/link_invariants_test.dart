// The static invariants of the link vocabulary (`tom_specs_model_rules.md`
// §9.7, §10.2 invariants SYNC-PLACE, SYNC-ANCHOR, SHARED-COVER,
// SHARED-ONE-HOLDER, SHARED-ANCHOR, SUMMARY-LINK, DERIVE-SOURCE,
// DERIVE-ACYCLIC, INVERSE-PAIR, EXTRACT-LINK), each held by a model that
// breaks it and one that keeps it.
//
// The fixture is one small model in the shape the idea section_automation
// works with: a Solution Blueprint and two Phase 3 documents, functional
// requirements with a constraints form and dependency rows, a key-requirement
// summary list, a screen registry and a note shared by two sections. Every
// case adds the annotations it is about to that model; the other invariants'
// findings are filtered out by id.
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

AnnotationData _id(String id) => AnnotationData('SectionId', {'id': id});

AnnotationData _pattern(String p) =>
    AnnotationData('SectionIdPattern', {'pattern': p});

ModelField _content(List<FormFieldInfo> form) => ModelField(
  name: 'content',
  typeName: 'DocSpecsSection?',
  isNullable: true,
  isContentSection: true,
  formFields: form,
);

ModelField _formMember(
  String name,
  String id,
  List<FormFieldInfo> form, [
  List<AnnotationData> more = const [],
]) => ModelField(
  name: name,
  typeName: 'DocSpecsSection?',
  isNullable: true,
  isContentSection: true,
  annotations: [_id(id), ...more],
  formFields: form,
);

ModelField _complex(String name, String type) =>
    ModelField(name: name, typeName: type);

ModelField _list(
  String name,
  String element,
  String listId, [
  List<AnnotationData> more = const [],
]) => ModelField(
  name: name,
  typeName: 'List<$element>',
  isList: true,
  listElementTypeName: element,
  listElementIsComplex: true,
  annotations: [
    _id(listId),
    _pattern(listId.replaceAll('-LST', '-xxx')),
    ...more,
  ],
);

FormFieldInfo _text(String name, {Map<String, Object?>? derivedFrom}) =>
    FormFieldInfo(name: name, typeName: 'String', derivedFrom: derivedFrom);

FormFieldInfo _ref(
  String name,
  List<String> refersTo, {
  bool multiple = true,
  Map<String, Object?>? inverseOf,
  Map<String, Object?>? derivedFrom,
  Map<String, Object?>? summaryOf,
}) => FormFieldInfo(
  name: name,
  typeName: 'String',
  refersTo: refersTo,
  multiple: multiple,
  inverseOf: inverseOf,
  derivedFrom: derivedFrom,
  summaryOf: summaryOf,
);

/// The fixture model; every argument adds what one case is about.
Map<String, ModelClass> _model({
  List<AnnotationData> frAnnotations = const [],
  List<AnnotationData> scnAnnotations = const [],
  List<AnnotationData> kreqAnnotations = const [],
  List<AnnotationData> keyReqsAnnotations = const [],
  List<AnnotationData> depsAnnotations = const [],
  List<FormFieldInfo> reqForm = const [],
  List<FormFieldInfo> frecForm = const [],
  List<FormFieldInfo> kreqForm = const [],
  Map<String, Object?>? relatedScreensInverse,
  Map<String, Object?>? relatedRequirementsInverse,
  Map<String, Object?>? traceScreensInverse,
  Map<String, Object?>? dependencyInverse,
  bool sbpReachesFrTwice = false,
}) {
  ModelClass cls(
    String name,
    List<AnnotationData> annotations,
    List<ModelField> fields,
  ) => ModelClass(name: name, annotations: annotations, fields: fields);

  return {
    'D00SolutionBlueprint': cls(
      'D00SolutionBlueprint',
      [
        AnnotationData('Document', {'name': 'Solution Blueprint'}),
        _id('SBP'),
      ],
      [
        _complex('requirements', 'FunctionalRequirements'),
        if (sbpReachesFrTwice)
          _complex('moreRequirements', 'FunctionalRequirements'),
        _complex('scenarios', 'Scenarios'),
        _list('screens', 'Screen', 'SCR-ITEM-LST'),
      ],
    ),
    'D04Spec': cls(
      'D04Spec',
      [
        AnnotationData('Document', {'name': 'Requirements'}),
        _id('RSP'),
      ],
      [_complex('requirements', 'FunctionalRequirements')],
    ),
    'D05Spec': cls(
      'D05Spec',
      [
        AnnotationData('Document', {'name': 'Scenarios'}),
        _id('ISC'),
      ],
      [_complex('scenarios', 'Scenarios')],
    ),
    'FunctionalRequirements': cls(
      'FunctionalRequirements',
      [
        _id('FR'),
        AnnotationData('MapsTo', {'documentClass': 'D04Spec'}),
        AnnotationData('DetailedIn', {'documentClass': 'D04Spec'}),
        ...frAnnotations,
      ],
      [
        _content(const []),
        _list('items', 'Req', 'FRE-REQU-LST'),
        _list('keyRequirements', 'KeyReq', 'KREQ-ITEM-LST', keyReqsAnnotations),
        _complex('note', 'SharedNote'),
      ],
    ),
    'Scenarios': cls(
      'Scenarios',
      [
        _id('SCN'),
        AnnotationData('MapsTo', {'documentClass': 'D05Spec'}),
        AnnotationData('DetailedIn', {'documentClass': 'D05Spec'}),
        ...scnAnnotations,
      ],
      [_content(const []), _complex('note', 'SharedNote')],
    ),
    'Req': cls(
      'Req',
      [_id('FRE')],
      [
        _content([
          FormFieldInfo(
            name: 'status',
            typeName: 'Priority',
            enumValues: const ['must', 'should'],
          ),
          _ref('relatedScreens', [
            'SCR.@sectionId',
          ], inverseOf: relatedScreensInverse),
          ...reqForm,
        ]),
        _formMember('constraints', 'FREC', [_text('constraints'), ...frecForm]),
        _list('dependencies', 'Dep', 'RQDEP-ITEM-LST', depsAnnotations),
        _complex('traceability', 'Trace'),
        _complex('note', 'SharedNote'),
      ],
    ),
    // A section below the requirement holding a link form (`RT` / `RETRAR`):
    // its entry is the requirement above it.
    'Trace': cls(
      'Trace',
      [_id('RT')],
      [
        _content(const []),
        _formMember('artifacts', 'RETR', [
          _ref('screens', ['SCR.@sectionId'], inverseOf: traceScreensInverse),
        ]),
      ],
    ),
    'Dep': cls(
      'Dep',
      [_id('RQDEP')],
      [
        _content([
          FormFieldInfo(
            name: 'dependencyType',
            typeName: 'DependencyType',
            enumValues: const ['conflict', 'bidirectional', 'namedInText'],
          ),
          _text('description'),
        ]),
        // A `@Reference` member, as in the model: a place of the row whose
        // target is never followed.
        _formMember(
          'relatedRequirement',
          'RQDEP-RELA-REF',
          [
            _ref(
              'ref',
              ['FRE.@sectionId'],
              multiple: false,
              inverseOf: dependencyInverse,
            ),
          ],
          [
            AnnotationData('Reference', {'label': 'Related Requirement'}),
          ],
        ),
      ],
    ),
    'KeyReq': cls(
      'KeyReq',
      [_id('KREQ'), ...kreqAnnotations],
      [
        _content([
          _ref('reqRef', ['FRE.@sectionId'], multiple: false),
          _text('title'),
          ...kreqForm,
        ]),
      ],
    ),
    'Screen': cls(
      'Screen',
      [_id('SCR')],
      [
        _content([
          _ref('relatedRequirements', [
            'FRE.@sectionId',
          ], inverseOf: relatedRequirementsInverse),
        ]),
      ],
    ),
    'SharedNote': cls(
      'SharedNote',
      [_id('SHN')],
      [
        _content([_text('text')]),
      ],
    ),
  };
}

AnnotationData _synced(
  String document, {
  List<String> detailOnly = const [],
  List<String> heldHere = const [],
  List<Map<String, Object?>> relations = const [],
}) => AnnotationData('SyncedWith', {
  'document': document,
  'detailOnly': detailOnly,
  'heldHere': heldHere,
  'relations': relations,
});

/// The findings of invariant [id] over [classes].
List<String> _findings(Map<String, ModelClass> classes, String id) {
  final result = validateStructuralInvariants(classes);
  return [
    for (final f in [...result.errors, ...result.warnings])
      if (f.contains('§10.2 $id:')) f,
  ];
}

void main() {
  test('the fixture itself keeps every link invariant', () {
    final result = validateStructuralInvariants(_model());
    final link = [
      for (final e in result.errors)
        if (RegExp(
          r'§10\.2 (SYNC|SHARED|SUMMARY|DERIVE|INVERSE|EXTRACT)-',
        ).hasMatch(e))
          e,
    ];
    expect(link, isEmpty, reason: link.join('\n'));
  });

  group('SYNC-PLACE', () {
    test('places that resolve, a subset on a list and on a multiple '
        'reference field, a / path through a twice-reached section', () {
      final found = _findings(
        _model(
          frAnnotations: [
            _synced(
              'D04Spec',
              detailOnly: ['RQDEP-ITEM-LST', 'FREC', 'FRE/SHN.text'],
              heldHere: ['FRE.status', 'FR.@headline'],
              relations: [
                {
                  'place': 'FRE-REQU-LST',
                  'relation': 'LinkRelation.subset',
                  'where': 'FRE.status=must|should',
                },
                {
                  'place': 'FRE.relatedScreens',
                  'relation': 'LinkRelation.subset',
                },
              ],
            ),
          ],
        ),
        'SYNC-PLACE',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('an unknown place, an ambiguous one, a place named twice, a subset '
        'on a single value and a filter on no constant are errors', () {
      final found = _findings(
        _model(
          frAnnotations: [
            _synced(
              'D04Spec',
              detailOnly: ['NOPE', 'SHN.text', 'FREC'],
              heldHere: ['FREC', 'FRE.@sectionId'],
              relations: [
                {'place': 'FRE.status', 'relation': 'LinkRelation.subset'},
                {
                  'place': 'FRE-REQU-LST',
                  'relation': 'LinkRelation.subset',
                  'where': 'FRE.status=could',
                },
              ],
            ),
          ],
        ),
        'SYNC-PLACE',
      );
      expect(found, hasLength(6), reason: found.join('\n'));
      expect(found[0], contains('"NOPE"'));
      expect(found[1], contains('ambiguous'));
      expect(found[2], contains('names "FREC" twice'));
      expect(found[3], contains('never synced'));
      expect(found[4], contains('relation other than equal'));
      expect(found[5], contains('"could"'));
    });
  });

  group('SYNC-ANCHOR', () {
    test('the document of the @DetailedIn beside it; a section without one '
        'reached from both roots', () {
      final found = _findings(
        _model(
          frAnnotations: [_synced('D04Spec')],
          kreqAnnotations: [_synced('D04Spec')],
        ),
        'SYNC-ANCHOR',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('another document than its @DetailedIn, no @Document, and a root '
        'that does not reach the section are errors', () {
      final found = _findings(
        _model(
          frAnnotations: [_synced('D05Spec')],
          scnAnnotations: [_synced('Req')],
          kreqAnnotations: [_synced('D05Spec')],
        ),
        'SYNC-ANCHOR',
      );
      expect(found, hasLength(3), reason: found.join('\n'));
      expect(found[0], contains('beside @DetailedIn(D04Spec)'));
      expect(found[1], contains('KeyReq is reachable from'));
      expect(found[2], contains('"Req", which is no @Document'));
    });
  });

  group('SHARED-COVER', () {
    test('a @DetailedIn without @SyncedWith is a warning, not an error', () {
      final result = validateStructuralInvariants(_model());
      final warnings = result.warnings
          .where((w) => w.contains('§10.2 SHARED-COVER:'))
          .toList();
      expect(warnings, hasLength(2));
      expect(warnings.first, contains('FunctionalRequirements'));
      expect(result.errors.where((e) => e.contains('SHARED-COVER')), isEmpty);
    });

    test('a @SyncedWith beside every @DetailedIn leaves none', () {
      final found = _findings(
        _model(
          frAnnotations: [_synced('D04Spec')],
          scnAnnotations: [_synced('D05Spec')],
        ),
        'SHARED-COVER',
      );
      expect(found, isEmpty);
    });
  });

  group('SHARED-ONE-HOLDER', () {
    test('a class reused beneath pairs of two documents is two sets of '
        'places, each with its own holder', () {
      final found = _findings(
        _model(
          frAnnotations: [_synced('D04Spec')],
          scnAnnotations: [_synced('D05Spec')],
        ),
        'SHARED-ONE-HOLDER',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('one anchor synced towards two documents is an error', () {
      final found = _findings(
        _model(frAnnotations: [_synced('D04Spec'), _synced('D05Spec')]),
        'SHARED-ONE-HOLDER',
      );
      expect(found, hasLength(1));
      expect(
        found.single,
        contains('carries @SyncedWith(D04Spec) and @SyncedWith(D05Spec)'),
      );
      expect(found.single, contains('would be held by both documents'));
    });

    test('held here by one of them, it has one holder', () {
      final found = _findings(
        _model(
          frAnnotations: [
            _synced('D04Spec', heldHere: ['FR']),
            _synced('D05Spec'),
          ],
        ),
        'SHARED-ONE-HOLDER',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });
  });

  group('SHARED-ANCHOR', () {
    test('one position beneath each root pairs', () {
      expect(_findings(_model(), 'SHARED-ANCHOR'), isEmpty);
    });

    test('two positions beneath the Blueprint root cannot be paired', () {
      final found = _findings(_model(sbpReachesFrTwice: true), 'SHARED-ANCHOR');
      expect(found, hasLength(1));
      expect(found.single, contains('FunctionalRequirements (anchored to '));
      expect(found.single, contains('<root> ×2'));
    });
  });

  group('SUMMARY-LINK', () {
    test('a summary list matched to its detail list, repeating its '
        'headline; a summaryOf: field naming the detail element', () {
      final found = _findings(
        _model(
          keyReqsAnnotations: [
            AnnotationData('SummaryOf', {
              'detail': 'FRE-REQU-LST',
              'match': 'KREQ.reqRef',
              'relation': 'LinkRelation.subset',
              'repeats': {'KREQ.@headline': 'FRE.@headline'},
            }),
          ],
          kreqForm: [
            _ref(
              'others',
              ['FRE.@sectionId'],
              summaryOf: {'detail': 'FRE-REQU-LST', 'relation': 'subset'},
            ),
          ],
        ),
        'SUMMARY-LINK',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('a detail that is no list, a match without refersTo, repeats of '
        'two types and a summaryOf: on a single reference are errors', () {
      final found = _findings(
        _model(
          keyReqsAnnotations: [
            AnnotationData('SummaryOf', {
              'detail': 'FRE',
              'relation': 'LinkRelation.subset',
            }),
            AnnotationData('SummaryOf', {
              'detail': 'FRE-REQU-LST',
              'match': 'KREQ.title',
              'relation': 'LinkRelation.subset',
              'repeats': {'KREQ.title': 'FRE.status'},
            }),
          ],
          kreqForm: [
            FormFieldInfo(
              name: 'one',
              typeName: 'String',
              refersTo: const ['FRE.@sectionId'],
              summaryOf: const {'detail': 'FRE-REQU-LST'},
            ),
          ],
        ),
        'SUMMARY-LINK',
      );
      expect(found, hasLength(4), reason: found.join('\n'));
      expect(found[0], contains('no -LST container'));
      expect(found[1], contains('is no reference field'));
      expect(found[2], contains('one type of value'));
      expect(found[3], contains('multiple reference field'));
    });
  });

  group('DERIVE-SOURCE', () {
    test('rows of the requirement\'s own dependency rows into a multiple '
        'reference field; a copy of the headline into a text field', () {
      final found = _findings(
        _model(
          frecForm: [
            _ref(
              'conflictsWith',
              ['FRE.@sectionId'],
              derivedFrom: {
                'kind': 'rows',
                'source': './RQDEP',
                'where': 'RQDEP.dependencyType=conflict|bidirectional',
                'take': ['RQDEP-RELA-REF.ref'],
              },
            ),
            _text(
              'title',
              derivedFrom: {'kind': 'copy', 'source': './FRE.@headline'},
            ),
          ],
        ),
        'DERIVE-SOURCE',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('a required derived field, two derivations on one field, a filter '
        'on no constant and a text take into a reference field are errors', () {
      final found = _findings(
        _model(
          frecForm: [
            FormFieldInfo(
              name: 'conflictsWith',
              typeName: 'String',
              required: true,
              refersTo: const ['FRE.@sectionId'],
              multiple: true,
              countOf: const ['RQDEP'],
              derivedFrom: const {
                'kind': 'rows',
                'source': './RQDEP',
                'where': 'RQDEP.dependencyType=clash',
                'take': ['RQDEP.description'],
              },
            ),
          ],
        ),
        'DERIVE-SOURCE',
      );
      expect(found, hasLength(4), reason: found.join('\n'));
      expect(found[0], contains('carries 2 of derivedFrom'));
      expect(found[1], contains('derived and required'));
      expect(found[2], contains('"clash"'));
      expect(found[3], contains('takes one reference place'));
    });
  });

  group('DERIVE-ACYCLIC', () {
    test('a derivation reading a plain field', () {
      final found = _findings(
        _model(
          reqForm: [
            _text('a', derivedFrom: {'kind': 'copy', 'source': 'FRE.b'}),
            _text('b'),
          ],
        ),
        'DERIVE-ACYCLIC',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('two derivations reading each other are a cycle', () {
      final found = _findings(
        _model(
          reqForm: [
            _text('a', derivedFrom: {'kind': 'copy', 'source': 'FRE.b'}),
            _text('b', derivedFrom: {'kind': 'copy', 'source': 'FRE.a'}),
          ],
        ),
        'DERIVE-ACYCLIC',
      );
      expect(found, hasLength(1));
      expect(found.single, contains('FRE.a (Req)'));
      expect(found.single, contains('FRE.b (Req)'));
    });
  });

  group('INVERSE-PAIR', () {
    test('both ends declared, each naming the other; a symmetric link on '
        'a field referring to its own entry class', () {
      final found = _findings(
        _model(
          relatedScreensInverse: {
            'fields': ['SCR.relatedRequirements'],
          },
          relatedRequirementsInverse: {
            'fields': ['FRE.relatedScreens'],
          },
          reqForm: [
            _ref(
              'conflicts',
              ['FRE.@sectionId'],
              inverseOf: {
                'fields': ['@self'],
                'where': 'FRE.status=must',
              },
            ),
          ],
        ),
        'INVERSE-PAIR',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('a one-sided declaration and a symmetric link to another class are '
        'errors', () {
      final found = _findings(
        _model(
          relatedScreensInverse: {
            'fields': ['SCR.relatedRequirements'],
          },
          reqForm: [
            _ref(
              'screens',
              ['SCR.@sectionId'],
              inverseOf: {
                'fields': ['@self'],
              },
            ),
          ],
        ),
        'INVERSE-PAIR',
      );
      expect(found, hasLength(2), reason: found.join('\n'));
      expect(found[0], contains('does not list FRE.relatedScreens'));
      expect(found[1], contains('symmetric needs a refersTo naming its own'));
    });
  });

  group('DERIVE-SOURCE, a lookup of the last row', () {
    test('a lookup without key and by reads the last row', () {
      final found = _findings(
        _model(
          frecForm: [
            _text(
              'lastDependency',
              derivedFrom: {
                'kind': 'lookup',
                'source': './RQDEP',
                'take': ['RQDEP.description'],
              },
            ),
          ],
        ),
        'DERIVE-SOURCE',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('a lookup naming a key without a by is an error', () {
      final found = _findings(
        _model(
          frecForm: [
            _text(
              'lastDependency',
              derivedFrom: {
                'kind': 'lookup',
                'source': './RQDEP',
                'key': 'RQDEP.description',
                'take': ['RQDEP.description'],
              },
            ),
          ],
        ),
        'DERIVE-SOURCE',
      );
      expect(found, hasLength(1), reason: found.join('\n'));
      expect(found.single, contains('a key and a by, or neither'));
    });
  });

  group('INVERSE-PAIR, entries above the form', () {
    test('a link form on a section below its entry pairs with the entry; a '
        'symmetric link row names the entry holding its list', () {
      final found = _findings(
        _model(
          traceScreensInverse: {
            'fields': ['SCR.relatedRequirements'],
          },
          relatedRequirementsInverse: {
            'fields': ['RETR.screens'],
          },
          dependencyInverse: {
            'fields': ['@self'],
            'where': 'RQDEP.dependencyType=conflict|bidirectional',
          },
        ),
        'INVERSE-PAIR',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('the reference row is a place, its target is not walked', () {
      final found = _findings(
        _model(
          frecForm: [
            _ref(
              'conflictsWith',
              ['FRE.@sectionId'],
              derivedFrom: {
                'kind': 'rows',
                'source': './RQDEP',
                'where': 'RQDEP.dependencyType=conflict',
                'take': ['RQDEP-RELA-REF.ref'],
              },
            ),
          ],
        ),
        'DERIVE-SOURCE',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });
  });

  group('EXTRACT-LINK', () {
    test('rows extracted from the constraints text, twice on one list', () {
      final found = _findings(
        _model(
          depsAnnotations: [
            AnnotationData('ExtractsLinks', {
              'from': ['FREC.constraints'],
              'ref': 'RQDEP-RELA-REF.ref',
              'set': {'RQDEP.dependencyType': 'namedInText'},
              'mode': 'ExtractMode.generate',
            }),
            AnnotationData('ExtractsLinks', {
              'from': ['FREC.constraints'],
              'ref': 'RQDEP-RELA-REF.ref',
              'set': {'RQDEP.dependencyType': 'conflict'},
              'mode': 'ExtractMode.warn',
            }),
          ],
        ),
        'EXTRACT-LINK',
      );
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('a non-text from, a ref without refersTo, a set on no constant and '
        'a list of no rows are errors', () {
      final found = _findings(
        _model(
          depsAnnotations: [
            AnnotationData('ExtractsLinks', {
              'from': ['FRE.status'],
              'ref': 'RQDEP.description',
              'set': {'RQDEP.dependencyType': 'whatever'},
              'mode': 'ExtractMode.generate',
            }),
          ],
          frAnnotations: const [],
        )..update(
          'Screen',
          (c) => ModelClass(
            name: c.name,
            annotations: c.annotations,
            fields: [
              ...c.fields,
              ModelField(
                name: 'tags',
                typeName: 'String?',
                annotations: [
                  AnnotationData('ExtractsLinks', {
                    'from': ['SCR.relatedRequirements'],
                    'ref': 'X.y',
                  }),
                ],
              ),
            ],
          ),
        ),
        'EXTRACT-LINK',
      );
      expect(found, hasLength(4), reason: found.join('\n'));
      expect(found[0], contains('"FRE.status" is no text field'));
      expect(found[1], contains('is no refersTo field'));
      expect(found[2], contains('"whatever"'));
      expect(found[3], contains('stands on a list of link rows'));
    });
  });
}
