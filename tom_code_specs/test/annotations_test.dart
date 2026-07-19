// CSM2R1: annotation-only CodeSpecs framework surface.
//
// These tests pin the csm2r1 exit criteria: `tom_code_specs` exports the `Cs*`
// annotation family + `@CodeSpec` / `@DocSpec` / `DocRef` and re-exports
// `CodeSpecKind` / `CodeSpecPart`, and every `Cs*` symbol is an annotation (a
// const-constructible marker), not a base class to extend.

import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:test/test.dart';

// A CodeSpec is an ordinary class BUILT ON a tom_core-family class (here a bare
// class stands in for that base) and MARKED by Cs* annotations — never extends a
// Cs* base. This declaration compiling is itself the annotations-only assertion.
@CsTable()
@CodeSpec('DB-ORDER', source: ['IMO-014'], requirements: ['RC-ORD-010'])
@DocSpec([DocRef('IMO-014', 'Order entity fields and constraints')])
class _OrderCodeSpec {}

@CsForm()
@CsValidation(note: 'total must be non-negative')
@CodeSpec('UI-ORDER-LIST', source: ['UP-ORDER-LIST'])
class _OrderListForm {}

void main() {
  group('CSM2R1: id/trace annotations', () {
    test('CodeSpec carries id, source, requirements', () {
      const spec = CodeSpec('DB-ORDER',
          source: ['IMO-014'], requirements: ['RC-ORD-010']);
      expect(spec.id, 'DB-ORDER');
      expect(spec.source, ['IMO-014']);
      expect(spec.requirements, ['RC-ORD-010']);
    });

    test('CodeSpec source/requirements default to empty lists', () {
      const spec = CodeSpec('X');
      expect(spec.source, isEmpty);
      expect(spec.requirements, isEmpty);
    });

    test('DocSpec holds DocRef back-trace tuples', () {
      const doc = DocSpec([DocRef('IMO-014', 'entity fields')]);
      expect(doc.refs.single.sectionId, 'IMO-014');
      expect(doc.refs.single.description, 'entity fields');
    });
  });

  group('CSM2R1: Cs* part markers are const annotations', () {
    test('client/UI markers construct with optional note', () {
      expect(const CsElement().note, isNull);
      expect(const CsWidget(note: 'w').note, 'w');
      expect(const CsForm().note, isNull);
      expect(const CsLayout().note, isNull);
      expect(const CsText().note, isNull);
      expect(const CsValidation(note: 'v').note, 'v');
      expect(const CsAction().note, isNull);
      expect(const CsTrigger().note, isNull);
      expect(const CsServerCall().note, isNull);
      expect(const CsViewModel().note, isNull);
      expect(const CsRoute().note, isNull);
    });

    test('server markers construct with optional note', () {
      expect(const CsEndpoint().note, isNull);
      expect(const CsServiceUnit().note, isNull);
      expect(const CsTable().note, isNull);
      expect(const CsColumn().note, isNull);
      expect(const CsRepository().note, isNull);
      expect(const CsAuthorize().note, isNull);
      expect(const CsServerConfig().note, isNull);
    });

    test('shared markers construct with optional note', () {
      expect(const CsError().note, isNull);
      expect(const CsEnum().note, isNull);
    });
  });

  group('CSM2R5: client/config/settings/auth markers', () {
    test('client/config/auth markers construct with optional note', () {
      expect(const CsClient().note, isNull);
      expect(const CsClientConfig(note: 'per-install').note, 'per-install');
      expect(const CsAuth().note, isNull);
    });

    test('CsUserSetting carries a persistence discriminator (default roaming)',
        () {
      expect(const CsUserSetting().persistence, SettingsPersistence.roaming);
      expect(
          const CsUserSetting(persistence: SettingsPersistence.local).persistence,
          SettingsPersistence.local);
    });

    test('the four new kind values are reachable and distinct', () {
      const kinds = <CodeSpecPart>[
        CodeSpecPart.serverConfiguration,
        CodeSpecPart.clientConfiguration,
        CodeSpecPart.userSettings,
        CodeSpecPart.client,
        CodeSpecPart.authentication,
      ];
      expect(kinds.toSet().length, kinds.length);
    });
  });

  group('CSM2R1: kind vocabulary re-exported', () {
    test('CodeSpecKind and CodeSpecPart are reachable via one import', () {
      const kind = CodeSpecKind([CodeSpecPart.form]);
      expect(kind.kinds, [CodeSpecPart.form]);
    });
  });

  test('CSM2R1: a class built-on-and-marked compiles and is annotated', () {
    // Instantiating proves the marked classes are ordinary classes, not
    // subclasses of any Cs* base.
    expect(_OrderCodeSpec(), isA<_OrderCodeSpec>());
    expect(_OrderListForm(), isA<_OrderListForm>());
  });
}
