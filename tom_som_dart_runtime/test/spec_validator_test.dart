import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final model = fixtureModel();

  test('a well-formed document validates clean', () {
    final doc = SpecDocument();
    doc.setContent('PD00/vision', 'idea');
    doc.setFormField('PD00/owner', 'name', 'Ada');
    final r1 = doc.addListItem('PD00/risks');
    final r2 = doc.addListItem('PD00/risks');
    doc.setContent('$r1/title', 'first');
    doc.setContent('$r2/title', 'second');
    expect(validateDocument(model, doc), isEmpty);
  });

  test('a dangling content path is reported', () {
    final doc = SpecDocument()..setContent('PD00/ghost', 'x');
    final errors = validateDocument(model, doc);
    expect(errors, hasLength(1));
    expect(errors.single.code, SpecValidationCode.danglingPath);
    expect(errors.single.path, 'PD00/ghost');
  });

  test('an unknown form field is reported', () {
    final doc = SpecDocument()..setFormField('PD00/owner', 'phone', '123');
    final errors = validateDocument(model, doc);
    expect(errors, hasLength(1));
    expect(errors.single.code, SpecValidationCode.unknownFormField);
  });

  test('a populated list below its @Min is reported', () {
    final doc = SpecDocument();
    doc.addListItem('PD00/risks'); // 1 item, min is 2
    final errors = validateDocument(model, doc);
    expect(
      errors.where((e) => e.code == SpecValidationCode.minItems),
      hasLength(1),
    );
  });

  test('a value written where a list is expected is a kind mismatch', () {
    final doc = SpecDocument()..setContent('PD00/risks', 'oops');
    final errors = validateDocument(model, doc);
    expect(errors.single.code, SpecValidationCode.kindMismatch);
  });

  group('@OneOf/@Case instance tier (csmb6)', () {
    // A minimal model: root Widget → Element (@OneOf on the `kind` discriminator)
    // with `action` (Case action), `input` (Case input) and `common` (no case)
    // subsections. `action2` also binds Case action to exercise the "more than
    // one populated case subsection" rule.
    SpecModel oneOfModel() => SpecModel.fromJson({
          'modelVersion': 1,
          'roots': [
            {'type': 'Widget', 'title': 'Widget', 'sectionId': 'WD00'},
          ],
          'classes': {
            'Widget': {
              'name': 'Widget',
              'sectionId': 'WD00',
              'annotations': [
                {'name': 'Document', 'arguments': {'title': 'Widget'}},
                {'name': 'SectionId', 'arguments': {'id': 'WD00'}},
              ],
              'fields': [
                {
                  'name': 'element',
                  'kind': 'complex',
                  'sectionId': 'ELM',
                  'type': 'Element',
                },
              ],
            },
            'Element': {
              'name': 'Element',
              'sectionId': 'ELM',
              'annotations': [
                {'name': 'SectionId', 'arguments': {'id': 'ELM'}},
                {'name': 'OneOf', 'arguments': {'discriminator': 'kind'}},
              ],
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'formFields': [
                    {
                      'name': 'kind',
                      'label': 'Kind',
                      'type': 'ElementKind',
                      'enumValues': ['action', 'input', 'display'],
                    },
                  ],
                },
                {
                  'name': 'action',
                  'kind': 'complex',
                  'sectionId': 'ACT',
                  'type': 'ActionSub',
                  'annotations': [
                    {'name': 'Case', 'arguments': {'value': 'ElementKind.action'}},
                  ],
                },
                {
                  'name': 'action2',
                  'kind': 'complex',
                  'sectionId': 'AC2',
                  'type': 'ActionSub',
                  'annotations': [
                    {'name': 'Case', 'arguments': {'value': 'ElementKind.action'}},
                  ],
                },
                {
                  'name': 'input',
                  'kind': 'complex',
                  'sectionId': 'INP',
                  'type': 'InputSub',
                  'annotations': [
                    {'name': 'Case', 'arguments': {'value': 'ElementKind.input'}},
                  ],
                },
                {
                  'name': 'common',
                  'kind': 'complex',
                  'sectionId': 'CMN',
                  'type': 'CommonSub',
                },
              ],
            },
            'ActionSub': {
              'name': 'ActionSub',
              'sectionId': 'ACT',
              'fields': [
                {'name': 'detail', 'kind': 'content', 'sectionId': 'detail'},
              ],
            },
            'InputSub': {
              'name': 'InputSub',
              'sectionId': 'INP',
              'fields': [
                {'name': 'detail', 'kind': 'content', 'sectionId': 'detail'},
              ],
            },
            'CommonSub': {
              'name': 'CommonSub',
              'sectionId': 'CMN',
              'fields': [
                {'name': 'detail', 'kind': 'content', 'sectionId': 'detail'},
              ],
            },
          },
        });

    final m = oneOfModel();

    List<SpecValidationError> oneOf(SpecDocument doc) => validateDocument(m, doc)
        .where((e) => e.code == SpecValidationCode.oneOfCaseMismatch)
        .toList();

    test('the subsection matching the chosen case validates clean', () {
      final doc = SpecDocument()
        ..setFormField('WD00/ELM/content', 'kind', 'action')
        ..setContent('WD00/ELM/ACT/detail', 'go');
      expect(oneOf(doc), isEmpty);
    });

    test('a subsection not selected by the chosen case is reported', () {
      final doc = SpecDocument()
        ..setFormField('WD00/ELM/content', 'kind', 'action')
        ..setContent('WD00/ELM/INP/detail', 'typed');
      final errors = oneOf(doc);
      expect(errors, hasLength(1));
      expect(errors.single.path, 'WD00/ELM/INP');
      expect(errors.single.message, contains('input'));
    });

    test('a common (un-@Case) subsection is allowed under any case', () {
      final doc = SpecDocument()
        ..setFormField('WD00/ELM/content', 'kind', 'input')
        ..setContent('WD00/ELM/CMN/detail', 'shared');
      expect(oneOf(doc), isEmpty);
    });

    test('more than one populated subsection for the chosen case is reported',
        () {
      final doc = SpecDocument()
        ..setFormField('WD00/ELM/content', 'kind', 'action')
        ..setContent('WD00/ELM/ACT/detail', 'a')
        ..setContent('WD00/ELM/AC2/detail', 'b');
      final errors = oneOf(doc);
      expect(errors, hasLength(1));
      expect(errors.single.path, 'WD00/ELM');
      expect(errors.single.message, contains('more than one'));
    });

    test('no discriminator chosen yet suppresses the case check', () {
      final doc = SpecDocument()..setContent('WD00/ELM/INP/detail', 'typed');
      expect(oneOf(doc), isEmpty);
    });
  });

  group('refersTo instance tier (csrb3)', () {
    // A minimal two-registry model: `routes` (RTEN entries declaring `routeId`)
    // and `screens` (SCEN entries declaring `screenId`), plus `links` whose form
    // holds one single-target and one two-target reference field.
    SpecModel refModel() => SpecModel.fromJson({
          'modelVersion': 1,
          'roots': [
            {'type': 'Catalog', 'title': 'Catalog', 'sectionId': 'CT00'},
          ],
          'classes': {
            'Catalog': {
              'name': 'Catalog',
              'sectionId': 'CT00',
              'annotations': [
                {'name': 'Document', 'arguments': {'title': 'Catalog'}},
                {'name': 'SectionId', 'arguments': {'id': 'CT00'}},
              ],
              'fields': [
                {
                  'name': 'routes',
                  'kind': 'list',
                  'sectionId': 'RT-LST',
                  'elementType': 'RouteEntry',
                  'elementIsComplex': true,
                },
                {
                  'name': 'screens',
                  'kind': 'list',
                  'sectionId': 'SC-LST',
                  'elementType': 'ScreenEntry',
                  'elementIsComplex': true,
                },
                {
                  'name': 'links',
                  'kind': 'list',
                  'sectionId': 'LK-LST',
                  'elementType': 'LinkEntry',
                  'elementIsComplex': true,
                },
              ],
            },
            'RouteEntry': {
              'name': 'RouteEntry',
              'sectionId': 'RTEN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {'name': 'routeId', 'label': 'Route ID', 'type': 'String'},
                  ],
                },
              ],
            },
            'ScreenEntry': {
              'name': 'ScreenEntry',
              'sectionId': 'SCEN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {'name': 'screenId', 'label': 'Screen ID', 'type': 'String'},
                  ],
                },
              ],
            },
            'LinkEntry': {
              'name': 'LinkEntry',
              'sectionId': 'LKEN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {
                      'name': 'targetRoute',
                      'label': 'Target route',
                      'type': 'String',
                      'refersTo': ['RTEN.routeId'],
                    },
                    {
                      'name': 'appliesTo',
                      'label': 'Applies to',
                      'type': 'String',
                      'refersTo': ['RTEN.routeId', 'SCEN.screenId'],
                    },
                  ],
                },
              ],
            },
          },
        });

    final m = refModel();

    /// A document declaring route `r-home` and screen `s-home`, plus one empty
    /// link entry whose form path is returned for the caller to fill in.
    (SpecDocument, String) seeded() {
      final doc = SpecDocument();
      final route = doc.addListItem('CT00/RT-LST');
      doc.setFormField('$route/content', 'routeId', 'r-home');
      final screen = doc.addListItem('CT00/SC-LST');
      doc.setFormField('$screen/content', 'screenId', 's-home');
      final link = doc.addListItem('CT00/LK-LST');
      return (doc, '$link/content');
    }

    List<SpecValidationError> refs(SpecDocument doc) => validateDocument(m, doc)
        .where((e) => e.code == SpecValidationCode.danglingReference)
        .toList();

    test('a reference to a declared id validates clean', () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'targetRoute', 'r-home');
      expect(refs(doc), isEmpty);
    });

    test('a reference to an undeclared id is reported', () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'targetRoute', 'r-ghost');
      final errors = refs(doc);
      expect(errors, hasLength(1));
      expect(errors.single.path, link);
      expect(errors.single.message, contains('r-ghost'));
      expect(errors.single.message, contains('RTEN.routeId'));
    });

    test('a multi-target reference resolves in any listed registry', () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'appliesTo', 's-home');
      expect(refs(doc), isEmpty);
    });

    test('a multi-target reference in no registry is reported once', () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'appliesTo', 'x-none');
      final errors = refs(doc);
      expect(errors, hasLength(1));
      expect(errors.single.message, contains('registries'));
    });

    test('a comma-separated value resolves each segment independently', () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'appliesTo', 'r-home, s-home , x-none');
      final errors = refs(doc);
      expect(errors, hasLength(1));
      expect(errors.single.message, contains('x-none'));
    });

    test('an empty reference is not a dangling reference', () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'targetRoute', '   ');
      expect(refs(doc), isEmpty);
    });

    test('an id declared in the wrong registry does not satisfy the reference',
        () {
      final (doc, link) = seeded();
      doc.setFormField(link, 'targetRoute', 's-home');
      expect(refs(doc), hasLength(1));
    });
  });

  group('refersTo @sectionId slot (csrd1)', () {
    // The functional-requirement shape: `requirements` is a @SectionIdPattern
    // list of REQN entries that declare NO id form field at all — the id is the
    // item's section id. `links` references them as `REQN.@sectionId`.
    SpecModel slotModel() => SpecModel.fromJson({
          'modelVersion': 1,
          'roots': [
            {'type': 'Catalog', 'title': 'Catalog', 'sectionId': 'CT00'},
          ],
          'classes': {
            'Catalog': {
              'name': 'Catalog',
              'sectionId': 'CT00',
              'annotations': [
                {'name': 'Document', 'arguments': {'title': 'Catalog'}},
                {'name': 'SectionId', 'arguments': {'id': 'CT00'}},
              ],
              'fields': [
                {
                  'name': 'requirements',
                  'kind': 'list',
                  'sectionId': 'RQ-LST',
                  'sectionIdPattern': 'RQ-REQU-xxx',
                  'elementType': 'RequirementEntry',
                  'elementIsComplex': true,
                },
                {
                  'name': 'links',
                  'kind': 'list',
                  'sectionId': 'LK-LST',
                  'elementType': 'LinkEntry',
                  'elementIsComplex': true,
                },
              ],
            },
            'RequirementEntry': {
              'name': 'RequirementEntry',
              'sectionId': 'REQN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {'name': 'title', 'label': 'Title', 'type': 'String'},
                  ],
                },
              ],
            },
            'LinkEntry': {
              'name': 'LinkEntry',
              'sectionId': 'LKEN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {
                      'name': 'relatedRequirements',
                      'label': 'Related requirements',
                      'type': 'String',
                      'refersTo': ['REQN.@sectionId'],
                    },
                  ],
                },
              ],
            },
          },
        });

    final m = slotModel();

    List<SpecValidationError> refs(SpecDocument doc) => validateDocument(m, doc)
        .where((e) => e.code == SpecValidationCode.danglingReference)
        .toList();

    String addLink(SpecDocument doc) =>
        '${doc.addListItem('CT00/LK-LST')}/content';

    test('a stored item section id is declared under the @sectionId slot', () {
      final doc = SpecDocument();
      doc.addListItem('CT00/RQ-LST', sectionId: 'RQ-REQU-HA1');
      final link = addLink(doc);
      doc.setFormField(link, 'relatedRequirements', 'RQ-REQU-HA1');
      expect(refs(doc), isEmpty);
    });

    test('an anonymous item is declared under its positional pattern id', () {
      // Authors who never touched the editor's id generation still have
      // referenceable requirements — the item's effective id is the pattern
      // resolved with its 1-based position.
      final doc = SpecDocument();
      doc.addListItem('CT00/RQ-LST');
      doc.addListItem('CT00/RQ-LST');
      final link = addLink(doc);
      doc.setFormField(link, 'relatedRequirements', 'RQ-REQU-2');
      expect(refs(doc), isEmpty);
    });

    test('an undeclared requirement id is reported', () {
      final doc = SpecDocument();
      doc.addListItem('CT00/RQ-LST', sectionId: 'RQ-REQU-HA1');
      final link = addLink(doc);
      doc.setFormField(link, 'relatedRequirements', 'RQ-REQU-HA9');
      final errors = refs(doc);
      expect(errors, hasLength(1));
      expect(errors.single.message, contains('RQ-REQU-HA9'));
      expect(errors.single.message, contains('REQN.@sectionId'));
    });

    test('a stored id does not also resolve as its positional id', () {
      // The item carries a stored id, so `RQ-REQU-1` names nothing — treating
      // both as valid would let a document reference an item by an id that
      // silently changes when a sibling is inserted.
      final doc = SpecDocument();
      doc.addListItem('CT00/RQ-LST', sectionId: 'RQ-REQU-HA1');
      final link = addLink(doc);
      doc.setFormField(link, 'relatedRequirements', 'RQ-REQU-1');
      expect(refs(doc), hasLength(1));
    });

    test('a comma-separated value resolves each requirement independently', () {
      final doc = SpecDocument();
      doc.addListItem('CT00/RQ-LST', sectionId: 'RQ-REQU-HA1');
      doc.addListItem('CT00/RQ-LST', sectionId: 'RQ-REQU-HA2');
      final link = addLink(doc);
      doc.setFormField(
          link, 'relatedRequirements', 'RQ-REQU-HA1, RQ-REQU-HA2, RQ-REQU-HA3');
      final errors = refs(doc);
      expect(errors, hasLength(1));
      expect(errors.single.message, contains('RQ-REQU-HA3'));
    });

    test('an empty requirement list leaves every reference dangling', () {
      final doc = SpecDocument();
      final link = addLink(doc);
      doc.setFormField(link, 'relatedRequirements', 'RQ-REQU-HA1');
      expect(refs(doc), hasLength(1));
    });
  });

  group('refersTo cross-document scope (csre2)', () {
    // Two document roots over one class graph, the real shape of a Phase 3
    // projection: the whole-project root reaches both the requirement registry
    // and the plans that cite it, while the standalone `Plan` root reaches only
    // the plans. A reference from a plan to a requirement is therefore
    // resolvable in the project document and *out of scope* in the standalone
    // one — the case the instance tier must not call an error.
    SpecModel twoRootModel() => SpecModel.fromJson({
          'modelVersion': 1,
          'roots': [
            {'type': 'Project', 'title': 'Project', 'sectionId': 'PR00'},
            {'type': 'Plan', 'title': 'Plan', 'sectionId': 'PL00'},
          ],
          'classes': {
            'Project': {
              'name': 'Project',
              'sectionId': 'PR00',
              'annotations': [
                {'name': 'Document', 'arguments': {'title': 'Project'}},
              ],
              'fields': [
                {
                  'name': 'requirements',
                  'kind': 'list',
                  'sectionId': 'RQ-LST',
                  'sectionIdPattern': 'RQ-REQU-xxx',
                  'elementType': 'RequirementEntry',
                  'elementIsComplex': true,
                },
                {
                  'name': 'plans',
                  'kind': 'list',
                  'sectionId': 'PL-LST',
                  'elementType': 'PlanEntry',
                  'elementIsComplex': true,
                },
              ],
            },
            'Plan': {
              'name': 'Plan',
              'sectionId': 'PL00',
              'annotations': [
                {'name': 'Document', 'arguments': {'title': 'Plan'}},
              ],
              'fields': [
                {
                  'name': 'plans',
                  'kind': 'list',
                  'sectionId': 'PL-LST',
                  'elementType': 'PlanEntry',
                  'elementIsComplex': true,
                },
              ],
            },
            'RequirementEntry': {
              'name': 'RequirementEntry',
              'sectionId': 'REQN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {'name': 'title', 'label': 'Title', 'type': 'String'},
                  ],
                },
              ],
            },
            'PlanEntry': {
              'name': 'PlanEntry',
              'sectionId': 'PLEN',
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'sectionId': 'content',
                  'formFields': [
                    {'name': 'planId', 'label': 'Plan ID', 'type': 'String'},
                    {
                      'name': 'requirementRef',
                      'label': 'Requirement',
                      'type': 'String',
                      'refersTo': ['REQN.@sectionId'],
                    },
                    {
                      'name': 'dependsOn',
                      'label': 'Depends on',
                      'type': 'String',
                      'refersTo': ['REQN.@sectionId', 'PLEN.planId'],
                    },
                  ],
                },
              ],
            },
          },
        });

    final m = twoRootModel();

    List<SpecValidationError> refs(SpecDocument doc) => validateDocument(m, doc)
        .where((e) => e.code == SpecValidationCode.danglingReference)
        .toList();

    /// A plan entry under [root]'s plan list, returning its form path.
    String addPlan(SpecDocument doc, String root) =>
        '${doc.addListItem('$root/PL-LST')}/content';

    test('a reference to an out-of-scope registry is not reported', () {
      final doc = SpecDocument();
      final plan = addPlan(doc, 'PL00');
      doc.setFormField(plan, 'requirementRef', 'RQ-REQU-HA1');
      expect(refs(doc), isEmpty);
    });

    test('the same reference is checked when the registry is in scope', () {
      final doc = SpecDocument();
      doc.addListItem('PR00/RQ-LST', sectionId: 'RQ-REQU-HA1');
      final plan = addPlan(doc, 'PR00');
      doc.setFormField(plan, 'requirementRef', 'RQ-REQU-HA1');
      expect(refs(doc), isEmpty);

      doc.setFormField(plan, 'requirementRef', 'RQ-REQU-GHOST');
      final errors = refs(doc);
      expect(errors, hasLength(1));
      expect(errors.single.message, contains('RQ-REQU-GHOST'));
    });

    test('an in-scope registry with no entries still reports a dangling id', () {
      // Scope is a property of the *model*, not of what the author happened to
      // fill in: the project root reaches the requirement registry, so an
      // unresolved id there is a real defect even with the list left empty.
      final doc = SpecDocument();
      final plan = addPlan(doc, 'PR00');
      doc.setFormField(plan, 'requirementRef', 'RQ-REQU-HA1');
      expect(refs(doc), hasLength(1));
    });

    test('one out-of-scope target suppresses the whole disjunction', () {
      // `dependsOn` accepts a requirement id *or* a plan id. From the
      // standalone plan document only the plan registry is visible, so an id
      // matching neither cannot be judged — it may well be a requirement id
      // this document cannot see.
      final doc = SpecDocument();
      final plan = addPlan(doc, 'PL00');
      doc.setFormField(plan, 'planId', 'p-first');
      doc.setFormField(plan, 'dependsOn', 'x-none');
      expect(refs(doc), isEmpty);
    });

    test('the same disjunction is judged from the project root', () {
      final doc = SpecDocument();
      doc.addListItem('PR00/RQ-LST', sectionId: 'RQ-REQU-HA1');
      final plan = addPlan(doc, 'PR00');
      doc.setFormField(plan, 'planId', 'p-first');
      doc.setFormField(plan, 'dependsOn', 'x-none');
      expect(refs(doc), hasLength(1));

      doc.setFormField(plan, 'dependsOn', 'p-first');
      expect(refs(doc), isEmpty);
    });
  });

  group('SpecReflection.reachableClassNames (csre2)', () {
    final m = SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'RT00'},
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'RT00',
          'fields': [
            {'name': 'detail', 'kind': 'complex', 'type': 'Detail'},
            {
              'name': 'items',
              'kind': 'list',
              'elementType': 'Item',
              'elementIsComplex': true,
            },
            {
              'name': 'tags',
              'kind': 'list',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {'name': 'ghost', 'kind': 'complex', 'type': 'Absent'},
          ],
        },
        'Detail': {
          'name': 'Detail',
          'fields': [
            {'name': 'nested', 'kind': 'section', 'type': 'Nested'},
          ],
        },
        'Nested': {
          'name': 'Nested',
          // Back-edge to the root: the walk must terminate on a cycle.
          'fields': [
            {'name': 'up', 'kind': 'complex', 'type': 'Root'},
          ],
        },
        'Item': {'name': 'Item', 'fields': <Object>[]},
        'Orphan': {'name': 'Orphan', 'fields': <Object>[]},
      },
    });

    test('follows complex, section and complex-list edges transitively', () {
      expect(SpecReflection(m).reachableClassNames('Root'),
          {'Root', 'Detail', 'Nested', 'Item'});
    });

    test('excludes unreached classes and unresolvable type names', () {
      final reachable = SpecReflection(m).reachableClassNames('Root');
      expect(reachable, isNot(contains('Orphan')));
      expect(reachable, isNot(contains('Absent')));
      expect(reachable, isNot(contains('String')));
    });

    test('an unknown start type reaches nothing at all', () {
      expect(SpecReflection(m).reachableClassNames('Nope'), isEmpty);
    });
  });
}
