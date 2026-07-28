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
class _OrderListForm {
  // CE-VA (§5.19): the two rule shapes differ by signature, not merely by
  // scope. A field rule sees one value and nothing else — which is what makes
  // it composable into the per-field declaration string. A form rule is a
  // method on the form because it has to read siblings, which that string
  // grammar cannot express.
  @CsFieldRule(note: 'reference must carry the project prefix')
  static String? validateReference(String value) => null;

  @CsFormRule(note: 'discount may not exceed total')
  String? validateDiscountAgainstTotal() => null;
}

// CE-ID (§5.24): the app's identity-extension holder is an ordinary class whose
// members carry the placement discriminator — the same member-marker pattern as
// @CsColumn.
@CsIdentity()
@CodeSpec('ID-PROFILE', source: ['SAS-USATE'])
class _ProfileExtension {
  @CsIdentityAttribute(placement: IdentityAttributePlacement.public)
  String? department;

  @CsIdentityAttribute(placement: IdentityAttributePlacement.encrypted)
  String? costCentre;
}

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
      expect(const CsFieldRule().note, isNull);
      expect(const CsFormRule(note: 'cross-field').note, 'cross-field');
      expect(const CsAction().note, isNull);
      expect(const CsTrigger(kind: TriggerKind.userGesture).note, isNull);
      expect(const CsServerCall().note, isNull);
      expect(const CsViewModel().note, isNull);
      expect(const CsRoute().note, isNull);
    });

    test('CE-VA marks both rule shapes on their real declarations', () {
      // The markers annotate declarations of different *signatures*: a field
      // rule takes a value and returns a verdict; a form rule takes nothing
      // because it reads the form it hangs on. Both tear-offs resolving is the
      // assertion — it is what proves the annotations are usable where §5.19
      // says the rules live.
      expect(_OrderListForm.validateReference, isA<String? Function(String)>());
      expect(_OrderListForm().validateDiscountAgainstTotal,
          isA<String? Function()>());
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

  group('csra2: CE-AC trigger taxonomy', () {
    // §5.10/§5.20 record CE-AC as "no gap — full action implementation reused",
    // so the closed 5-kind taxonomy lands on the annotation as a documented
    // classification, NOT as a tom_core_codespecs class.
    test('TriggerKind is the closed §5.20 five', () {
      expect(TriggerKind.values, [
        TriggerKind.userGesture,
        TriggerKind.inFormEvent,
        TriggerKind.lifecycle,
        TriggerKind.serverEvent,
        TriggerKind.condition,
      ]);
    });

    // `kind` selects which per-kind attribute set the trigger carries (§5.20's
    // five-row table), so no arm can be a default — the csra1 `placement`
    // precedent.
    test('CsTrigger requires an explicit kind', () {
      expect(const CsTrigger(kind: TriggerKind.condition).kind,
          TriggerKind.condition);
      expect(
          const CsTrigger(kind: TriggerKind.inFormEvent, note: 'on submit')
              .note,
          'on submit');
    });
  });

  group('CSM2R5: client/config/settings/auth markers', () {
    test('client/config/auth markers construct with optional note', () {
      expect(const CsClient().note, isNull);
      expect(const CsClientConfig(note: 'per-install').note, 'per-install');
      expect(const CsAuth().note, isNull);
    });

    test('csra3: CsUserSetting is single-moded — no persistence discriminator',
        () {
      // §11: the scope key alone decides where a value lives, so the four
      // settings markers are distinguished by *which marker is used*, never by
      // a mode argument on one of them. The device-persisted arm the old
      // `SettingsPersistence.local` stood for is CE-DS `@CsDeviceSetting`.
      expect(const CsUserSetting().note, isNull);
      expect(const CsUserSetting(note: 'follows the user').note,
          'follows the user');
      expect(const CsDeviceSetting().note, isNull);
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

  group('CSRA1: the six §4.1 parts that had no marker', () {
    test('CsScreenFlow (CE-NV) constructs with optional note', () {
      expect(const CsScreenFlow().note, isNull);
      expect(const CsScreenFlow(note: 'popup overlay').note, 'popup overlay');
    });

    test('CsDeviceSetting (CE-DS) constructs with optional note', () {
      expect(const CsDeviceSetting().note, isNull);
      expect(const CsDeviceSetting(note: 'window layout').note, 'window layout');
    });

    test('CsIdentity (CE-ID) constructs with optional note', () {
      expect(const CsIdentity().note, isNull);
      expect(const CsIdentity(note: 'profile extension').note,
          'profile extension');
    });

    test('CsMigration (CE-MG) constructs with optional note', () {
      expect(const CsMigration().note, isNull);
      expect(const CsMigration(note: 'baseline DDL').note, 'baseline DDL');
    });

    test('CsJob (CE-JB) constructs with optional note', () {
      expect(const CsJob().note, isNull);
      expect(const CsJob(note: 'nightly reconciliation').note,
          'nightly reconciliation');
    });

    // §5.24: `placement` is the public/encrypted token-payload arm. It is a
    // REQUIRED argument — §5.16's fail-safe rule says broadening a value's blast
    // radius must be a deliberate authored act, so neither arm may be a default.
    test('CsIdentityAttribute requires an explicit placement', () {
      expect(
          const CsIdentityAttribute(placement: IdentityAttributePlacement.public)
              .placement,
          IdentityAttributePlacement.public);
      expect(
          const CsIdentityAttribute(
                  placement: IdentityAttributePlacement.encrypted)
              .placement,
          IdentityAttributePlacement.encrypted);
    });

    test('IdentityAttributePlacement is the closed public|encrypted pair', () {
      expect(IdentityAttributePlacement.values, [
        IdentityAttributePlacement.public,
        IdentityAttributePlacement.encrypted,
      ]);
    });

    test('the six kind values are reachable and distinct', () {
      const kinds = <CodeSpecPart>[
        CodeSpecPart.navigation,
        CodeSpecPart.deviceSettings,
        CodeSpecPart.identity,
        CodeSpecPart.schemaMigration,
        CodeSpecPart.backgroundJob,
      ];
      expect(kinds.toSet().length, kinds.length);
    });
  });

  group('csra7: the two parts promoted out of §4.3', () {
    // CE-LG is pure reuse — @CsAudited marks the framework's own @TomAudited
    // declaration, exactly as @CsServiceUnit marks a @tomService (§4.3.2).
    test('CsAudited (CE-LG) constructs with optional note', () {
      expect(const CsAudited().note, isNull);
      expect(const CsAudited(note: 'redacts iban').note, 'redacts iban');
    });

    test('CsNotification (CE-NT) constructs with optional note', () {
      expect(const CsNotification().note, isNull);
      expect(const CsNotification(note: 'order shipped').note, 'order shipped');
    });

    test('CsNotificationChannel (CE-NT) constructs with optional note', () {
      expect(const CsNotificationChannel().note, isNull);
      expect(const CsNotificationChannel(note: 'sms, critical only').note,
          'sms, critical only');
    });

    // The promoted parts keep the enum positions they held while reserved —
    // promotion is a readiness change, never a renumbering (§4.1).
    test('their kind values are reachable and distinct', () {
      const kinds = <CodeSpecPart>[
        CodeSpecPart.notification,
        CodeSpecPart.auditLog,
      ];
      expect(kinds.toSet().length, kinds.length);
      expect(const CodeSpecKind([CodeSpecPart.auditLog]).kinds,
          [CodeSpecPart.auditLog]);
    });
  });

  group('csra8: CE-RP promoted out of §4.3', () {
    test('CsReport constructs with optional note', () {
      expect(const CsReport().note, isNull);
      expect(const CsReport(note: 'sales by region').note, 'sales by region');
    });

    // Four markers, because a report authors four independently-shaped things:
    // the report itself, its output columns, its charts and its parameters.
    test('the three member markers construct with optional notes', () {
      expect(const CsReportColumn().note, isNull);
      expect(const CsReportColumn(note: 'currency, 2dp').note, 'currency, 2dp');
      expect(const CsReportChart().note, isNull);
      expect(
          const CsReportChart(note: 'bar, by quarter').note, 'bar, by quarter');
      expect(const CsReportParameter().note, isNull);
      expect(const CsReportParameter(note: 'date range').note, 'date range');
    });

    // Promotion is a readiness change, never a renumbering: CE-RP keeps the
    // enum position it held while reserved (§4.1).
    test('the reporting kind is reachable and unmoved', () {
      expect(const CodeSpecKind([CodeSpecPart.reporting]).kinds,
          [CodeSpecPart.reporting]);
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
    expect(_ProfileExtension(), isA<_ProfileExtension>());
  });
}
