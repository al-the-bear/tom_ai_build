// The `Cs*` annotation family: a marker set AND an attribute surface.
//
// Two properties are under test, and they are asserted by different means:
//
//  1. **Placement** — that each marker is legal on the declaration shape the
//     part actually marks: a form field for CE-EL, a static const catalogue
//     member for CE-TX, a method for a CE-VA rule, an enum for a domain enum, a
//     class for CE-FM. This half is asserted by the DECLARATIONS BELOW
//     COMPILING; a bare stub class would prove the constructor exists and
//     nothing about whether it is usable where the part lives.
//  2. **Surface** — that each of the 24 attribute-bearing markers carries its
//     full `codespecs_derivation_contract.md` §5.1 argument set, and that the
//     15 note-only markers carry nothing beyond `note`. This half is asserted in
//     the test bodies, which const-construct the same full attribute sets.
//
// The note-only half is a design decision, not an omission:
// `codespecs_derivation_contract.md` §2.3's three tests make "the Dart
// declaration already says it" and "the `tom_core` substrate constructor already
// takes it" reasons NOT to add an argument. Pinning those markers at
// `{note}` is what stops a later pass from quietly adding the second,
// disagreeing source §2.3 exists to prevent.
//
// A CodeSpec is an ordinary class BUILT ON a `tom_core`-family class and MARKED
// by `Cs*` annotations — never extends a `Cs*` base. `tom_code_specs` does not
// depend on `tom_core` (`codespecs_mapping.md` §9.5), so the declarations below
// stand in for their substrate with plain Dart members; the annotation surface
// is what is under test, not the substrate.

import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:test/test.dart';

// ───────────────────────────── shared locus ─────────────────────────────────
// `codespecs_mapping.md` §4.2: visible to both client and server.

/// N7: the part that owns a referenceable element declares its identity exactly
/// once, as a `static const` on that part's catalogue class. Every citing
/// annotation below holds one of these consts — never a copy of its string.
class Operations {
  static const customerSave = CsOperationRef('customer.save');
  static const customerLoad = CsOperationRef('customer.load');
}

class Roles {
  static const sales = CsRoleRef('sales');
  static const salesManager = CsRoleRef('salesManager');
}

class ResourceKeys {
  static const customerIban = CsResourceKeyRef('customer.iban');
  static const costCentre = CsResourceKeyRef('employee.costCentre');
}

class Actions {
  static const saveCustomer = CsActionRef('saveCustomer');
}

/// CE-TX — the message-key catalogue. `@CsText` marks each **member**: the key
/// is the `CsMessageKey` const the member holds, so it is never an argument.
@CodeSpec('TX-CUSTOMER', source: ['XDS-COPY'])
@DocSpec([DocRef('XDS-COPY', 'Customer screen copy')])
class Messages {
  @CsText(baseCopy: 'Save customer')
  static const saveCustomerLabel = CsMessageKey('customer.save.label');

  // `role: error` constrains `category` to `errorCopy` — error copy is keyed by
  // the CE-ER error code, so the two cannot disagree
  // (`codespecs_derivation_contract.md` §6 check 10).
  @CsText(
    baseCopy: 'Customer {name} could not be saved',
    role: CsTextRole.error,
    category: CsTextCategory.errorCopy,
    note: 'keyed by CUST-409, not by a key of its own',
  )
  static const saveConflict = CsMessageKey('CUST-409');

  @CsText(
    baseCopy: 'Reference must carry the project prefix',
    role: CsTextRole.error,
    category: CsTextCategory.errorCopy,
  )
  static const badReference = CsMessageKey('validation.reference.prefix');

  @CsText(
    baseCopy: 'Discount may not exceed the total',
    role: CsTextRole.error,
    category: CsTextCategory.errorCopy,
  )
  static const discountTooHigh = CsMessageKey('validation.discount.tooHigh');

  @CsText(baseCopy: 'Order {id} has shipped', role: CsTextRole.notification)
  static const orderShipped = CsMessageKey('notification.order.shipped');

  @CsText(baseCopy: 'Nightly cleanup failed', role: CsTextRole.notification)
  static const cleanupFailed = CsMessageKey('job.cleanup.failed');
}

/// CE-ER — the error-code catalogue. `@CsError` is carried twice: plain on the
/// holder, and once per code member with that code's severity.
@CsError()
@CodeSpec('ER-CUSTOMER', source: ['IFM-ERR'])
class CustomerErrors {
  @CsError(severity: CsErrorSeverity.error, note: 'no customer with that id')
  static const notFound = CsErrorCode('CUST-404');

  @CsError(severity: CsErrorSeverity.warning)
  static const staleRead = CsErrorCode('CUST-409');

  @CsError(severity: CsErrorSeverity.fatal)
  static const storeUnavailable = CsErrorCode('CUST-500');
}

/// A domain enum — a **member marker**, authored within its owning part and
/// placed in the shared project because a shared contract type references it.
@CsEnum(note: 'cited by the customer DTO and the customer entity')
enum CustomerStatus { prospect, active, churned }

/// The aggregate root, cited by `Type` literal — entities are already Dart
/// types, so they need no ref const (`codespecs_mapping.md` §5.23).
class Customer {}

/// CE-API — the shared half: the operation catalogue and its ref consts. The
/// server half carries the **identical** operation string
/// (`codespecs_derivation_contract.md` §6 check 12).
@CsEndpoint('customer.save')
@CodeSpec('API-CUSTOMER-SAVE', source: ['IFM-OPS'])
class CustomerSaveContract {
  CustomerStatus? status;
}

// ───────────────────────────── client locus ─────────────────────────────────

/// CE-FM — the form. `@CsForm` is note-only: the bound view-model link is the
/// `TomForm<T>` generic, the id is `@CodeSpec`'s, and the submit target is
/// derived from the trigger rather than authored twice.
@CsForm(note: 'the customer master form')
@CodeSpec('UI-CUSTOMER-EDIT', source: ['XDS-CUSTFORM'])
@DocSpec([DocRef('XDS-CUSTFORM', 'Customer edit form fields')])
class CustomerEditForm {
  // CE-EL on a form member: the kind is the argument, because the declared Dart
  // type does not fix TextInput vs Choice. Label keys and grade defaults ride
  // the field's own `tom_flutter_ui` declaration.
  @CsElement(kind: CsElementKind.textInput)
  @CsValidation(rules: 'required, maxLength:80')
  String? name;

  @CsElement(kind: CsElementKind.number, note: 'net, excluding VAT')
  @CsValidation(rules: 'required, min:0')
  num? total;

  @CsElement(kind: CsElementKind.choice)
  CustomerStatus? status;

  @CsElement(kind: CsElementKind.textInput)
  @CsValidation(rules: 'required, pattern:^[A-Z]{3}-')
  String? reference;

  // CE-VA (`codespecs_mapping.md` §5.19): the two rule shapes differ by
  // SIGNATURE, not merely by scope. A field rule sees one value and nothing
  // else — which is what makes it composable into the per-field declaration
  // string. A form rule is a method on the form because it has to read
  // siblings, which that string grammar cannot express.
  @CsFieldRule(errorKey: Messages.badReference, note: 'project prefix')
  static String? validateReference(String value) => null;

  @CsFormRule(errorKey: Messages.discountTooHigh)
  String? validateDiscountAgainstTotal() => null;
}

/// CE-EL — a **standalone** element, which is a class-level target rather than a
/// form member. `@CsWidget` marks the concrete widget realising the kind.
@CsElement(kind: CsElementKind.button, note: 'primary affordance')
@CsWidget(note: 'TomPrimaryButton')
@CodeSpec('EL-SAVE-BUTTON', source: ['XDS-CUSTFORM'])
class SaveButton {}

/// CE-LO — the layout node model. The node id is the one thing the `Acl*`
/// substrate lacks and is what the §5.22 delta grammar addresses nodes by.
@CsLayout('customerEditRoot', note: 'two-column above 900dp')
@CodeSpec('LO-CUSTOMER-EDIT', source: ['XDS-CUSTLAYOUT'])
class CustomerEditLayout {}

/// CE-AC — one action, several triggers. Each `@CsTrigger` fills exactly the
/// slots its `kind` declares (`codespecs_derivation_contract.md` §6 check 8) —
/// the annotation-level rendering of §8.2's `@OneOf`/`@Case` closed choice.
@CsAction(note: 'validates, then calls the server')
@CsTrigger(
  kind: TriggerKind.userGesture,
  action: Actions.saveCustomer,
  element: CsElementRef('save', form: 'customerEditForm'),
  gesture: CsGesture.tap,
)
@CsTrigger(
  kind: TriggerKind.inFormEvent,
  action: Actions.saveCustomer,
  form: CsFormRef('customerEditForm'),
  formEvent: CsFormEvent.fieldChange,
  formField: CsElementRef('total', form: 'customerEditForm'),
)
@CsTrigger(
  kind: TriggerKind.lifecycle,
  action: Actions.saveCustomer,
  scope: CsLifecycleScope.screen,
  phase: CsLifecyclePhase.leave,
  note: 'autosave on leave',
)
@CsTrigger(
  kind: TriggerKind.serverEvent,
  action: Actions.saveCustomer,
  channel: 'customer-events',
  eventType: 'customer.invalidated',
)
// `condition` carries no slot: its predicate over CE-ST state is real Dart — a
// closure the `TomActionTrigger` constructor takes.
@CsTrigger(kind: TriggerKind.condition, action: Actions.saveCustomer)
@CodeSpec('AC-SAVE-CUSTOMER', source: ['ISC-SAVECUST'])
class SaveCustomerAction {}

/// CE-SC — the middle hop of `codespecs_mapping.md` §5.3's chain:
/// `@CsAction ──triggers──▶ @CsServerCall ──operation──▶ @CsEndpoint`.
@CsServerCall(Operations.customerSave, note: 'optimistic, retried once')
@CodeSpec('SC-CUSTOMER-SAVE', source: ['ISC-SAVECUST'])
class CustomerSaveCall {}

/// CE-ST — the view model. `screen` is the narrowest scope and the default, so
/// widening a view model's lifetime is a deliberate authored act.
@CsViewModel(scope: CsLifecycleScope.route, note: 'survives the detail screen')
@CodeSpec('ST-CUSTOMER-LIST', source: ['XDS-CUSTLIST'])
class CustomerListState {}

/// CE-NV — the route registry: a plain annotated constants class. Both CE-NV
/// markers are note-only; the transition kind and the edges ride
/// `TomRouteDefinition` / `TomScreenFlowEdge`'s own constructors.
@CodeSpec('NV-ROUTES', source: ['XDS-NAV'])
class RouteCatalog {
  @CsRoute()
  static const customerEdit = CsRouteRef('customer/edit');

  @CsRoute(note: 'deep-linkable')
  static const customerList = CsRouteRef('customer/list');
}

@CsScreenFlow(note: 'save success returns, error overlays')
@CodeSpec('NV-CUSTOMER-FLOW', source: ['XDS-NAV'])
class CustomerScreenFlow {}

/// CE-CL — the client-application descriptor. The kind decides which *other*
/// parts the client can carry, so it is required and never defaulted.
@CsClient('backoffice', kind: CsClientKind.flutterApp, note: 'primary client')
@CodeSpec('CL-BACKOFFICE', source: ['ATS-CLIENTS'])
class BackofficeClient {
  // CE-CC — per-machine settings of a client app, keyed by (client, machine).
  @CsClientConfig(
    'client.server.url',
    envAlias: 'BACKOFFICE_SERVER_URL',
    note: 'per-install',
  )
  String serverUrl = 'https://localhost:8443';

  // CE-DS — a user-specific setting of a user-owned device, keyed by
  // (user, device) and never leaving the device.
  @CsDeviceSetting('device.lastOpenedTab', note: 'window state')
  int lastOpenedTab = 0;

  // CE-UP — keyed by the user and persisted server-side, so it follows the user
  // onto any device they sign into. Single-moded: the scope key alone decides
  // where the value lives (`codespecs_mapping.md` §11).
  @CsUserSetting('user.preferredLanguage', note: 'follows the user')
  String preferredLanguage = 'de';
}

/// CE-AU — the client half of the credential/token/session flow. Note-only:
/// there is one marked declaration per enabled method, so the set of
/// declarations *is* the enabled set.
@CsAuth(note: 'password + TOTP')
@CodeSpec('AU-LOGIN', source: ['SAS-AUTH'])
class LoginFlow {}

// ───────────────────────────── server locus ─────────────────────────────────

/// CE-DB — the persistent entity. The physical table name is never derived: a
/// generator that slugified a class name could rename a table under a running
/// system.
@CsTable('customer', datasource: 'crm', schema: 'sales', note: 'partitioned')
@CodeSpec('DB-CUSTOMER', source: ['IMO-014'], requirements: ['RC-CUST-010'])
@DocSpec([DocRef('IMO-014', 'Customer entity fields and constraints')])
class CustomerEntity {
  @CsColumn(column: 'customer_id', columnType: 'bigint')
  int? id;

  @CsColumn(column: 'name', columnType: 'varchar', length: 80, note: 'indexed')
  String? name;

  // A `codespecs_mapping.md` §5.15 resource-key requirement attached to a FIELD
  // rather than an operation.
  @CsColumn(column: 'iban', length: 34, accessKey: ResourceKeys.customerIban)
  String? iban;

  // The facet's PRESENCE is the column kind: the cell holds a storage key and
  // the file lives in the blob store the facet names.
  @CsColumn(
    column: 'contract_pdf',
    fileReference: CsFileReference(
      keyPrefix: 'customer/contract',
      store: 'archive',
      cascadeDelete: false,
      defaultMediaType: 'application/octet-stream',
      acceptedMediaTypes: ['application/pdf'],
      note: 'signed original',
    ),
  )
  String? contract;

  @CsColumn()
  CustomerStatus? status;
}

/// CE-DB — the data-access surface. Note-only: entity and key type are the
/// class's generics, and each named-query intent is one form-3 method.
@CsRepository(note: 'read-through cached')
@CodeSpec('DB-CUSTOMER-REPO', source: ['IMO-014'])
class CustomerRepository {}

/// CE-SU — the service unit, bounded by its two required arguments: the owned
/// root aggregate and the context it sits in (`codespecs_mapping.md` §5.1).
@CsServiceUnit(
  rootAggregate: Customer,
  boundedContext: 'sales',
  note: 'owns customer and contact',
)
@CodeSpec('SU-CUSTOMER', source: ['TOM-SU'])
class CustomerService {
  // CE-API server half + CE-AZ + CE-LG. `@CsAudited` carries nothing of its own
  // — the declared half rides the framework's `@TomAudited`.
  @CsEndpoint('customer.save', note: 'idempotent on customerId')
  @CsAuthorize(
    requirement: CsAuthRequirement.role,
    roles: [Roles.sales, Roles.salesManager],
    note: 'either role admits',
  )
  @CsAudited(note: 'redacts iban')
  Object? save(Object? request) =>
      throw UnsupportedError('persist via CustomerRepository.save');

  @CsEndpoint('customer.load')
  @CsAuthorize(requirement: CsAuthRequirement.authenticated)
  Object? load(Object? request) =>
      throw UnsupportedError('read via CustomerRepository.findById');

  @CsEndpoint('customer.export')
  @CsAuthorize(
    requirement: CsAuthRequirement.resourceKey,
    resourceKey: ResourceKeys.customerIban,
  )
  Object? export(Object? request) =>
      throw UnsupportedError('render via SalesByRegionReport');

  @CsEndpoint('customer.merge')
  @CsAuthorize(requirement: CsAuthRequirement.group, groups: ['crm-admins'])
  Object? merge(Object? request) => throw UnsupportedError('merge two records');

  @CsEndpoint('customer.purge')
  @CsAuthorize(
    requirement: CsAuthRequirement.entitlement,
    entitlements: ['crm.customer.*'],
  )
  Object? purge(Object? request) => throw UnsupportedError('GDPR erasure');

  @CsEndpoint('customer.approve')
  @CsAuthorize(
    requirement: CsAuthRequirement.custom,
    handler: 'approvalChainHandler',
    resourceId: 'customer',
  )
  Object? approve(Object? request) =>
      throw UnsupportedError('delegate to the approval chain');

  // The graded arm is the only requirement kind reaching all four
  // `TomAuthState` values, so it is a tree: each slot is itself a requirement.
  // An omitted slot inherits from the next-higher one, so the common case
  // authors only `full`.
  @CsEndpoint('customer.creditLimit')
  @CsAuthorize(
    requirement: CsAuthRequirement.graded,
    graded: CsGradedAccess(
      full: CsAuthorize(
        requirement: CsAuthRequirement.role,
        roles: [Roles.salesManager],
      ),
      read: CsAuthorize(
        requirement: CsAuthRequirement.role,
        roles: [Roles.sales],
      ),
      disabled: CsAuthorize(requirement: CsAuthRequirement.authenticated),
    ),
  )
  Object? creditLimit(Object? request) =>
      throw UnsupportedError('read the credit limit');
}

/// CE-CF — server configuration. Type and default are the member declaration
/// and its initialiser, so neither is an argument; precedence is fixed by
/// `codespecs_mapping.md` §5.16 for every setting.
@CodeSpec('CF-SERVER', source: ['ATS-CONFIG'])
class AppServerConfig {
  @CsServerConfig(
    'smtp.host',
    envAlias: 'SMTP_HOST',
    cmdlineAlias: '--smtp-host',
  )
  String smtpHost = 'localhost';

  @CsServerConfig(
    'smtp.password',
    envAlias: 'SMTP_PASSWORD',
    note: 'secret-bearing: declaration authored, value never',
  )
  String smtpPassword = '';

  @CsServerConfig('audit.retentionDays', note: 'CE-LG sink setting, not CE-LG')
  int auditRetentionDays = 365;
}

/// CE-MG — the migration artifact set. Datasource + schema *are* the artifact
/// directory path; the kind decides what is generated, and generating an
/// initial DDL where an iteration was meant would rewrite a live schema.
@CsMigration(
  datasource: 'crm',
  schema: 'sales',
  kind: CsMigrationKind.initialDdl,
  note: 'baseline DDL',
)
@CodeSpec('MG-CRM-INITIAL', source: ['SCHMG'])
class CrmInitialSchema {}

@CsMigration(
  datasource: 'crm',
  schema: 'sales',
  kind: CsMigrationKind.baseData,
)
@CodeSpec('MG-CRM-SEED', source: ['SCHMG'])
class CrmSeedData {}

@CsMigration(
  datasource: 'crm',
  schema: 'sales',
  kind: CsMigrationKind.iteration,
)
@CodeSpec('MG-CRM-0007', source: ['SCHMG'])
class CrmAddCreditLimit {}

/// CE-JB — background work, one per trigger kind. `@CsJob`'s head is the
/// trigger; the three schedule slots are per-kind
/// (`codespecs_derivation_contract.md` §6 check 8).
@CsJob(
  trigger: CsJobTrigger.cron,
  cron: '0 3 * * *',
  maxRetries: 2,
  backoff: Duration(minutes: 5),
  timeout: Duration(hours: 1),
  failureAlert: Messages.cleanupFailed,
  note: 'nightly reconciliation',
)
@CodeSpec('JB-NIGHTLY-CLEANUP', source: ['TOM-JOBS'])
class NightlyCleanupJob {}

@CsJob(trigger: CsJobTrigger.calendar, calendar: 'last-day-of-month 23:00')
@CodeSpec('JB-MONTH-END', source: ['TOM-JOBS'])
class MonthEndCloseJob {}

@CsJob(trigger: CsJobTrigger.event, event: 'customer.merged')
@CodeSpec('JB-REINDEX', source: ['TOM-JOBS'])
class ReindexOnMergeJob {}

/// CE-NT — the notification catalogue. The declaration is shared (the client
/// renders the preference UI against it); delivery is server-only. Body copy is
/// always a CE-TX key, never inline text.
@CodeSpec('NT-CATALOG', source: ['NM'])
class NotificationCatalog {
  @CsNotification(body: Messages.orderShipped, note: 'essential type')
  static const orderShipped = 'order.shipped';

  @CsNotificationChannel(note: 'sms, critical only')
  static const smsChannel = 'sms';
}

/// CE-RP — a report authors four independently-shaped things, so it has four
/// markers. All are note-only: §5.28's surface maps onto
/// `TomReportDefinition`'s constructor and its dimension/measure members.
@CsReport(note: 'sales by region, quarterly')
@CodeSpec('RP-SALES-BY-REGION', source: ['REPENT'])
class SalesByRegionReport {
  @CsReportColumn(note: 'currency, 2dp')
  Object? revenue;

  @CsReportChart(note: 'bar, by quarter')
  Object? revenueChart;

  @CsReportParameter(note: 'date range')
  Object? period;
}

/// CE-ID — the identity **extension**. The principal core (`TomUser` /
/// `TomPrincipal`) is framework-fixed and not spec input; what an app declares
/// is the extension riding on top, member by member.
@CsIdentity(note: 'employee profile extension')
@CodeSpec('ID-EMPLOYEE', source: ['SAS-USATE'])
class EmployeeProfile {
  @CsIdentityAttribute(placement: IdentityAttributePlacement.public)
  String? department;

  @CsIdentityAttribute(
    placement: IdentityAttributePlacement.encrypted,
    accessKey: ResourceKeys.costCentre,
    systemOfRecord: 'hr',
    required: true,
    note: 'sourced nightly from HR',
  )
  String? costCentre;
}

void main() {
  group('id/trace annotations', () {
    test('CodeSpec carries id, source, requirements', () {
      const spec = CodeSpec(
        'DB-CUSTOMER',
        source: ['IMO-014'],
        requirements: ['RC-CUST-010'],
      );
      expect(spec.id, 'DB-CUSTOMER');
      expect(spec.source, ['IMO-014']);
      expect(spec.requirements, ['RC-CUST-010']);
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

  // ── csrb4: the 24 attribute-bearing markers ───────────────────────────────
  //
  // One test per marker, constructing its FULL surface. Together with the
  // declarations above — which are the placement half of the assertion — this
  // is the exit criterion: every marker whose
  // `codespecs_derivation_contract.md` §5 surface specifies attributes takes
  // them as constructor parameters.

  group('csrb4: client/UI attribute surfaces', () {
    test('CsElement carries the required semantic kind', () {
      // Required with no default: the kind selects both the per-kind attribute
      // set and the default widget, and no kind is a sensible default. Every
      // per-kind extra maps onto a named `tom_flutter_ui` widget property, so it
      // rides `@CsWidget`, never this marker.
      const element = CsElement(
        kind: CsElementKind.multiChoice,
        note: 'tag picker',
      );
      expect(element.kind, CsElementKind.multiChoice);
      expect(element.note, 'tag picker');
    });

    test('CsLayout takes the node id as its first positional', () {
      const layout = CsLayout('customerEditRoot', note: 'two-column');
      expect(layout.nodeId, 'customerEditRoot');
      expect(layout.note, 'two-column');
    });

    test('CsText carries copy, role and category', () {
      const text = CsText(
        baseCopy: 'Customer {name} could not be saved',
        role: CsTextRole.error,
        category: CsTextCategory.errorCopy,
        note: 'keyed by CUST-409',
      );
      expect(text.baseCopy, 'Customer {name} could not be saved');
      expect(text.role, CsTextRole.error);
      expect(text.category, CsTextCategory.errorCopy);
      expect(text.note, 'keyed by CUST-409');
    });

    test('CsText defaults to generic UI copy', () {
      // The unmarked case is ordinary interface copy, so only the specialised
      // roles are authored.
      const text = CsText(baseCopy: 'Save customer');
      expect(text.role, CsTextRole.generic);
      expect(text.category, CsTextCategory.uiCopy);
    });

    // The one place a declaration string beats typed arguments: the rule set is
    // a composition of variable arity, which a fixed parameter list cannot
    // express, and the §5.19 grammar is specified and parsed rather than
    // free-form.
    test('CsValidation carries the §5.19 rule declaration string', () {
      const validation = CsValidation(
        rules: 'required, minLength:8, pattern:^[A-Z]',
        note: 'password policy',
      );
      expect(validation.rules, 'required, minLength:8, pattern:^[A-Z]');
      expect(validation.note, 'password policy');
    });

    // §5.1 specifies `rules` as an optional POSITIONAL argument, but Dart
    // forbids one signature carrying both optional-positional and named
    // parameters, and every marker keeps a named `note`. Named it is.
    test('CsValidation.rules is empty on a shared rule-library holder', () {
      expect(const CsValidation().rules, isEmpty);
    });

    test('the two CE-VA rule markers require an error key', () {
      // A rule that can fail without saying why is not authored, it is
      // unfinished — so neither key has a default.
      const fieldRule = CsFieldRule(
        errorKey: Messages.badReference,
        note: 'project prefix',
      );
      const formRule = CsFormRule(errorKey: Messages.discountTooHigh);
      expect(fieldRule.errorKey, Messages.badReference);
      expect(fieldRule.note, 'project prefix');
      expect(formRule.errorKey, Messages.discountTooHigh);
    });

    test('CsServerCall takes the operation ref as its first positional', () {
      const call = CsServerCall(Operations.customerSave, note: 'optimistic');
      expect(call.operation, Operations.customerSave);
      expect(call.operation.id, 'customer.save');
      expect(call.note, 'optimistic');
    });

    test('CsViewModel defaults to the narrowest lifecycle scope', () {
      expect(const CsViewModel().scope, CsLifecycleScope.screen);
      const viewModel = CsViewModel(
        scope: CsLifecycleScope.app,
        note: 'session-wide',
      );
      expect(viewModel.scope, CsLifecycleScope.app);
      expect(viewModel.note, 'session-wide');
    });
  });

  group('csrb4: CE-AC trigger per-kind slots', () {
    test('TriggerKind is the closed codespecs_mapping.md §5.20 five', () {
      expect(TriggerKind.values, [
        TriggerKind.userGesture,
        TriggerKind.inFormEvent,
        TriggerKind.lifecycle,
        TriggerKind.serverEvent,
        TriggerKind.condition,
      ]);
    });

    // `kind` selects which per-kind attribute set the trigger carries, so no arm
    // can be a default; `action` is required because a trigger with no target is
    // not a trigger.
    test('the common head is kind + action', () {
      const trigger = CsTrigger(
        kind: TriggerKind.condition,
        action: Actions.saveCustomer,
      );
      expect(trigger.kind, TriggerKind.condition);
      expect(trigger.action, Actions.saveCustomer);
      // `condition` fills no slot: its predicate over CE-ST state is real Dart.
      expect(trigger.element, isNull);
      expect(trigger.form, isNull);
      expect(trigger.scope, isNull);
      expect(trigger.channel, isNull);
    });

    test('userGesture fills element + gesture', () {
      const trigger = CsTrigger(
        kind: TriggerKind.userGesture,
        action: Actions.saveCustomer,
        element: CsElementRef('save', form: 'customerEditForm'),
        gesture: CsGesture.longPress,
      );
      expect(trigger.element?.path, 'customerEditForm.save');
      expect(trigger.gesture, CsGesture.longPress);
    });

    test('inFormEvent fills form + formEvent + formField', () {
      const trigger = CsTrigger(
        kind: TriggerKind.inFormEvent,
        action: Actions.saveCustomer,
        form: CsFormRef('customerEditForm'),
        formEvent: CsFormEvent.fieldChange,
        formField: CsElementRef('total', form: 'customerEditForm'),
      );
      expect(trigger.form?.id, 'customerEditForm');
      expect(trigger.formEvent, CsFormEvent.fieldChange);
      expect(trigger.formField?.path, 'customerEditForm.total');
    });

    test('lifecycle fills scope + phase', () {
      const trigger = CsTrigger(
        kind: TriggerKind.lifecycle,
        action: Actions.saveCustomer,
        scope: CsLifecycleScope.route,
        phase: CsLifecyclePhase.dispose,
      );
      expect(trigger.scope, CsLifecycleScope.route);
      expect(trigger.phase, CsLifecyclePhase.dispose);
    });

    // Channel names are open, deployment-declared values (§5.23), so there is no
    // Dart declaration to resolve a ref against.
    test('serverEvent fills channel + eventType, both strings', () {
      const trigger = CsTrigger(
        kind: TriggerKind.serverEvent,
        action: Actions.saveCustomer,
        channel: 'customer-events',
        eventType: 'customer.invalidated',
      );
      expect(trigger.channel, 'customer-events');
      expect(trigger.eventType, 'customer.invalidated');
    });
  });

  group('csrb4: server attribute surfaces', () {
    // A plain String and not a CsOperationRef, because this marker is what
    // DECLARES the operation; the ref const is what everything else cites.
    test('CsEndpoint takes the operation name as its first positional', () {
      const endpoint = CsEndpoint('customer.save', note: 'idempotent');
      expect(endpoint.operation, 'customer.save');
      expect(endpoint.note, 'idempotent');
    });

    test('CsServiceUnit requires both halves of the §5.1 boundary', () {
      const unit = CsServiceUnit(
        rootAggregate: Customer,
        boundedContext: 'sales',
        note: 'owns customer and contact',
      );
      expect(unit.rootAggregate, Customer);
      expect(unit.boundedContext, 'sales');
      expect(unit.note, 'owns customer and contact');
    });

    test('CsTable takes the physical table name plus its placement', () {
      const table = CsTable(
        'customer',
        datasource: 'crm',
        schema: 'sales',
        note: 'partitioned',
      );
      expect(table.table, 'customer');
      expect(table.datasource, 'crm');
      expect(table.schema, 'sales');
    });

    test('CsTable placement defaults to the deployment default', () {
      const table = CsTable('customer');
      expect(table.datasource, isNull);
      expect(table.schema, isNull);
    });

    test('CsColumn expresses what the Dart type cannot', () {
      const column = CsColumn(
        column: 'iban',
        columnType: 'varchar',
        length: 34,
        accessKey: ResourceKeys.customerIban,
        note: 'field-level guarded',
      );
      expect(column.column, 'iban');
      expect(column.columnType, 'varchar');
      expect(column.length, 34);
      expect(column.accessKey, ResourceKeys.customerIban);
    });

    // Null means "the same as the member name" / "the datasource's default
    // mapping" — the common case, so a column name is authored only where
    // storage and domain names genuinely differ.
    test('CsColumn defaults every argument to the derived value', () {
      const column = CsColumn();
      expect(column.column, isNull);
      expect(column.columnType, isNull);
      expect(column.length, isNull);
      expect(column.accessKey, isNull);
      expect(column.fileReference, isNull);
    });

    test('CsServerConfig carries the key and both aliases', () {
      const config = CsServerConfig(
        'smtp.host',
        envAlias: 'SMTP_HOST',
        cmdlineAlias: '--smtp-host',
        note: 'per-deployment',
      );
      expect(config.key, 'smtp.host');
      expect(config.envAlias, 'SMTP_HOST');
      expect(config.cmdlineAlias, '--smtp-host');
    });

    test('CsMigration requires datasource, schema and artifact kind', () {
      const migration = CsMigration(
        datasource: 'crm',
        schema: 'sales',
        kind: CsMigrationKind.iteration,
        note: 'adds credit_limit',
      );
      expect(migration.datasource, 'crm');
      expect(migration.schema, 'sales');
      expect(migration.kind, CsMigrationKind.iteration);
    });

    test('CsMigrationKind is the closed §5.27 three', () {
      expect(CsMigrationKind.values, [
        CsMigrationKind.initialDdl,
        CsMigrationKind.baseData,
        CsMigrationKind.iteration,
      ]);
    });

    test('CsNotification requires a message key, never inline text', () {
      const notification = CsNotification(
        body: Messages.orderShipped,
        note: 'essential type',
      );
      expect(notification.body, Messages.orderShipped);
      expect(notification.body.id, 'notification.order.shipped');
    });
  });

  group('csrb4: CE-JB trigger per-kind slots', () {
    test('CsJob defaults to no retries and the substrate policy', () {
      const job = CsJob(trigger: CsJobTrigger.event, event: 'customer.merged');
      expect(job.trigger, CsJobTrigger.event);
      expect(job.event, 'customer.merged');
      expect(job.maxRetries, 0);
      expect(job.backoff, isNull);
      expect(job.timeout, isNull);
      expect(job.failureAlert, isNull);
      expect(job.cron, isNull);
      expect(job.calendar, isNull);
    });

    test('the cron arm carries the full policy surface', () {
      const job = CsJob(
        trigger: CsJobTrigger.cron,
        cron: '0 3 * * *',
        maxRetries: 2,
        backoff: Duration(minutes: 5),
        timeout: Duration(hours: 1),
        failureAlert: Messages.cleanupFailed,
        note: 'nightly reconciliation',
      );
      expect(job.cron, '0 3 * * *');
      expect(job.maxRetries, 2);
      expect(job.backoff, const Duration(minutes: 5));
      expect(job.timeout, const Duration(hours: 1));
      expect(job.failureAlert, Messages.cleanupFailed);
    });

    test('the calendar arm fills only its own slot', () {
      const job = CsJob(
        trigger: CsJobTrigger.calendar,
        calendar: 'last-day-of-month 23:00',
      );
      expect(job.calendar, 'last-day-of-month 23:00');
      expect(job.cron, isNull);
      expect(job.event, isNull);
    });
  });

  group('csrb4: CE-AZ requirement kinds', () {
    // No arm is a default: defaulting an authorization requirement is the exact
    // failure §5.16's fail-safe rule exists to prevent.
    test('CsAuthRequirement folds six payload kinds and four presets', () {
      expect(CsAuthRequirement.values, hasLength(10));
      expect(
        CsAuthRequirement.values.take(6),
        [
          CsAuthRequirement.role,
          CsAuthRequirement.group,
          CsAuthRequirement.entitlement,
          CsAuthRequirement.resourceKey,
          CsAuthRequirement.custom,
          CsAuthRequirement.graded,
        ],
        reason: 'the payload-bearing kinds precede the presets',
      );
    });

    test('a preset fills no slot at all', () {
      const authorize = CsAuthorize(
        requirement: CsAuthRequirement.authenticated,
      );
      expect(authorize.roles, isEmpty);
      expect(authorize.groups, isEmpty);
      expect(authorize.entitlements, isEmpty);
      expect(authorize.resourceKey, isNull);
      expect(authorize.handler, isNull);
      expect(authorize.graded, isNull);
    });

    // Roles are typed refs; groups and entitlements are strings because they
    // reference runtime principal data, not Dart declarations (§5.23).
    test('role, group and entitlement fill their own list', () {
      const byRole = CsAuthorize(
        requirement: CsAuthRequirement.role,
        roles: [Roles.sales, Roles.salesManager],
      );
      const byGroup = CsAuthorize(
        requirement: CsAuthRequirement.group,
        groups: ['crm-admins'],
      );
      const byEntitlement = CsAuthorize(
        requirement: CsAuthRequirement.entitlement,
        entitlements: ['crm.customer.*'],
      );
      expect(byRole.roles.map((r) => r.id), ['sales', 'salesManager']);
      expect(byGroup.groups, ['crm-admins']);
      expect(byEntitlement.entitlements, ['crm.customer.*']);
    });

    test('resourceKey and custom fill their own slots', () {
      const byKey = CsAuthorize(
        requirement: CsAuthRequirement.resourceKey,
        resourceKey: ResourceKeys.customerIban,
      );
      const byHandler = CsAuthorize(
        requirement: CsAuthRequirement.custom,
        handler: 'approvalChainHandler',
        resourceId: 'customer',
      );
      expect(byKey.resourceKey, ResourceKeys.customerIban);
      expect(byHandler.handler, 'approvalChainHandler');
      expect(byHandler.resourceId, 'customer');
    });

    // The slots hold a whole CsAuthorize because §5.15 defines them as
    // recursion into the other requirement kinds. Reusing the annotation type
    // rather than declaring a parallel "requirement" value class is what keeps
    // the two from drifting.
    test('graded is a three-slot tree of requirements', () {
      const graded = CsAuthorize(
        requirement: CsAuthRequirement.graded,
        graded: CsGradedAccess(
          full: CsAuthorize(
            requirement: CsAuthRequirement.role,
            roles: [Roles.salesManager],
          ),
          read: CsAuthorize(
            requirement: CsAuthRequirement.role,
            roles: [Roles.sales],
          ),
          disabled: CsAuthorize(requirement: CsAuthRequirement.authenticated),
        ),
      );
      expect(graded.graded?.full?.roles.single, Roles.salesManager);
      expect(graded.graded?.read?.roles.single, Roles.sales);
      expect(
        graded.graded?.disabled?.requirement,
        CsAuthRequirement.authenticated,
      );
    });

    // The four states and the monotonic defaults `read ⇐ full`, `disabled ⇐
    // read` are DERIVED, which is why the slots are nullable with no defaults:
    // an omitted slot inherits from the next-higher one, so the common case
    // authors only `full`.
    test('an omitted graded slot is absent, not defaulted', () {
      const graded = CsGradedAccess(
        full: CsAuthorize(
          requirement: CsAuthRequirement.role,
          roles: [Roles.salesManager],
        ),
      );
      expect(graded.read, isNull);
      expect(graded.disabled, isNull);
    });
  });

  group('csrb4: shared attribute surfaces', () {
    test('CsError carries the severity, defaulting to error', () {
      expect(const CsError().severity, CsErrorSeverity.error);
      const fatal = CsError(
        severity: CsErrorSeverity.fatal,
        note: 'store unreachable',
      );
      expect(fatal.severity, CsErrorSeverity.fatal);
      expect(fatal.note, 'store unreachable');
    });

    test('CsErrorSeverity mirrors TomErrorSeverity value-for-value', () {
      expect(CsErrorSeverity.values, [
        CsErrorSeverity.info,
        CsErrorSeverity.warning,
        CsErrorSeverity.error,
        CsErrorSeverity.fatal,
      ]);
    });
  });

  group('csrb4: client/config/settings/identity attribute surfaces', () {
    test('CsClient carries the client id and its required kind', () {
      const client = CsClient(
        'backoffice',
        kind: CsClientKind.flutterApp,
        note: 'primary client',
      );
      expect(client.clientId, 'backoffice');
      expect(client.kind, CsClientKind.flutterApp);
      expect(client.note, 'primary client');
    });

    // A client app is launched by its platform, not by a command line the
    // specification controls — hence no cmdline alias on CE-CC.
    test('CsClientConfig carries the key and its env alias only', () {
      const config = CsClientConfig(
        'client.server.url',
        envAlias: 'BACKOFFICE_SERVER_URL',
      );
      expect(config.key, 'client.server.url');
      expect(config.envAlias, 'BACKOFFICE_SERVER_URL');
    });

    // §11: the scope key alone decides where a value lives, so the four settings
    // markers are distinguished by WHICH MARKER IS USED, never by a mode
    // argument on one of them.
    test('CsUserSetting and CsDeviceSetting carry a key and nothing else', () {
      const userSetting = CsUserSetting(
        'user.preferredLanguage',
        note: 'follows the user',
      );
      const deviceSetting = CsDeviceSetting(
        'device.lastOpenedTab',
        note: 'window state',
      );
      expect(userSetting.key, 'user.preferredLanguage');
      expect(deviceSetting.key, 'device.lastOpenedTab');
    });

    // §5.16's fail-safe rule: broadening a value's blast radius must be a
    // deliberate authored act, so neither placement arm is a default.
    test('CsIdentityAttribute requires an explicit placement', () {
      expect(
        const CsIdentityAttribute(
          placement: IdentityAttributePlacement.public,
        ).placement,
        IdentityAttributePlacement.public,
      );
      expect(
        const CsIdentityAttribute(
          placement: IdentityAttributePlacement.encrypted,
        ).placement,
        IdentityAttributePlacement.encrypted,
      );
    });

    test('CsIdentityAttribute carries the full §5.24 surface', () {
      const attribute = CsIdentityAttribute(
        placement: IdentityAttributePlacement.encrypted,
        accessKey: ResourceKeys.costCentre,
        systemOfRecord: 'hr',
        required: true,
        note: 'sourced nightly',
      );
      expect(attribute.placement, IdentityAttributePlacement.encrypted);
      expect(attribute.accessKey, ResourceKeys.costCentre);
      expect(attribute.systemOfRecord, 'hr');
      expect(attribute.required, isTrue);
    });

    // An identity extension is additive, so demanding an attribute is the
    // deliberate act; `null` systemOfRecord means this application owns it.
    test('an identity attribute is optional and app-owned by default', () {
      const attribute = CsIdentityAttribute(
        placement: IdentityAttributePlacement.public,
      );
      expect(attribute.required, isFalse);
      expect(attribute.systemOfRecord, isNull);
      expect(attribute.accessKey, isNull);
    });

    test('IdentityAttributePlacement is the closed public|encrypted pair', () {
      expect(IdentityAttributePlacement.values, [
        IdentityAttributePlacement.public,
        IdentityAttributePlacement.encrypted,
      ]);
    });
  });

  // ── csrb4: the 15 note-only markers ───────────────────────────────────────

  group('csrb4: the note-only markers carry nothing beyond note', () {
    // Pinning these is as load-bearing as pinning the 24: each is note-only
    // because §2.3's tests found an existing carrier — the declaration name, a
    // generic, or the `tom_core` substrate constructor — and adding an argument
    // later would create the second, disagreeing source those tests prevent.
    test('client/UI: CsWidget, CsForm, CsAction, CsRoute, CsScreenFlow', () {
      expect(const CsWidget(note: 'TomPrimaryButton').note, 'TomPrimaryButton');
      expect(const CsForm().note, isNull);
      expect(const CsAction(note: 'validates first').note, 'validates first');
      expect(const CsRoute().note, isNull);
      expect(const CsScreenFlow(note: 'popup overlay').note, 'popup overlay');
    });

    test('server: CsRepository, CsAudited, CsNotificationChannel', () {
      expect(const CsRepository(note: 'read-through').note, 'read-through');
      expect(const CsAudited(note: 'redacts iban').note, 'redacts iban');
      expect(const CsNotificationChannel().note, isNull);
    });

    test('server: the four CE-RP markers', () {
      expect(const CsReport(note: 'sales by region').note, 'sales by region');
      expect(const CsReportColumn(note: 'currency, 2dp').note, 'currency, 2dp');
      expect(const CsReportChart().note, isNull);
      expect(const CsReportParameter(note: 'date range').note, 'date range');
    });

    test('shared: CsEnum', () {
      expect(const CsEnum(note: 'shared contract type').note,
          'shared contract type');
    });

    test('identity/auth: CsIdentity, CsAuth', () {
      expect(const CsIdentity().note, isNull);
      expect(const CsAuth(note: 'password + TOTP').note, 'password + TOTP');
    });
  });

  group('CE-DB file-reference column kind', () {
    // The facet mirrors TomFileReference one-for-one, so a spec author declares
    // exactly what the substrate annotation can receive — no CodeSpecs-local
    // storage type (`codespecs_mapping.md` §1.1 pillar b).
    test('CsFileReference requires a keyPrefix and defaults the rest', () {
      const ref = CsFileReference(keyPrefix: 'customer/contract');
      expect(ref.keyPrefix, 'customer/contract');
      expect(ref.store, isNull);
      expect(ref.defaultMediaType, isNull);
      expect(ref.acceptedMediaTypes, isEmpty);
      expect(ref.note, isNull);
    });

    // The file belongs to the row: deleting the row deletes the blob unless the
    // spec deliberately says the blob outlives its reference.
    test('cascadeDelete defaults to true and is overridable', () {
      expect(const CsFileReference(keyPrefix: 'a').cascadeDelete, isTrue);
      expect(
        const CsFileReference(
          keyPrefix: 'a',
          cascadeDelete: false,
        ).cascadeDelete,
        isFalse,
      );
    });

    test('the full surface is the four substrate settings plus the guard', () {
      const ref = CsFileReference(
        keyPrefix: 'invoices/scan',
        store: 'archive',
        cascadeDelete: false,
        defaultMediaType: 'application/octet-stream',
        acceptedMediaTypes: ['application/pdf', 'image/png'],
        note: 'scanned original',
      );
      expect(ref.store, 'archive');
      expect(ref.defaultMediaType, 'application/octet-stream');
      expect(ref.acceptedMediaTypes, ['application/pdf', 'image/png']);
      expect(ref.note, 'scanned original');
    });

    // Presence IS the column kind — a plain column carries no facet, so no
    // parallel "kind" tag has to be kept in step with it.
    test('a column without the facet is an ordinary stored attribute', () {
      expect(const CsColumn().fileReference, isNull);
      expect(const CsColumn(column: 'iban').fileReference, isNull);
    });

    // `codespecs_mapping.md` §5.13 boundaries: CE-DB is server-only, so a
    // thumbnail/link choice is CE-EL, and whether a file may be fetched is the
    // column's own access key — never a second "downloadable" flag that could
    // disagree with it. What is pinned here is that the facet does not split
    // CE-DB into a second part.
    test('CE-DB is reachable as one kind value, unsplit by the facet', () {
      expect(const CodeSpecKind([CodeSpecPart.dataAccess]).kinds, [
        CodeSpecPart.dataAccess,
      ]);
    });
  });

  group('kind vocabulary re-exported', () {
    test('CodeSpecKind and CodeSpecPart are reachable via one import', () {
      const kind = CodeSpecKind([CodeSpecPart.form]);
      expect(kind.kinds, [CodeSpecPart.form]);
    });

    // Promotion out of §4.3 is a readiness change, never a renumbering: a
    // promoted part keeps the enum position it held while reserved.
    test('every part this suite marks has a distinct kind value', () {
      const kinds = <CodeSpecPart>[
        CodeSpecPart.serverConfiguration,
        CodeSpecPart.clientConfiguration,
        CodeSpecPart.userSettings,
        CodeSpecPart.deviceSettings,
        CodeSpecPart.client,
        CodeSpecPart.authentication,
        CodeSpecPart.identity,
        CodeSpecPart.navigation,
        CodeSpecPart.schemaMigration,
        CodeSpecPart.backgroundJob,
        CodeSpecPart.notification,
        CodeSpecPart.auditLog,
        CodeSpecPart.reporting,
      ];
      expect(kinds.toSet().length, kinds.length);
    });
  });

  // Instantiating proves the marked declarations are ordinary classes, not
  // subclasses of any Cs* base — the annotations-only assertion
  // (`codespecs_mapping.md` §1.1).
  test('a class built-on-and-marked compiles and is an ordinary class', () {
    expect(CustomerEditForm(), isA<CustomerEditForm>());
    expect(CustomerEntity(), isA<CustomerEntity>());
    expect(EmployeeProfile(), isA<EmployeeProfile>());
    expect(BackofficeClient(), isA<BackofficeClient>());
    expect(SaveCustomerAction(), isA<SaveCustomerAction>());
    expect(NightlyCleanupJob(), isA<NightlyCleanupJob>());
    expect(CrmInitialSchema(), isA<CrmInitialSchema>());
  });

  // The two CE-VA markers annotate declarations of different SIGNATURES: a
  // field rule takes a value and returns a verdict; a form rule takes nothing
  // because it reads the form it hangs on. Both tear-offs resolving is the
  // assertion — it proves the annotations are usable where §5.19 says the rules
  // live.
  test('CE-VA marks both rule shapes on their real declarations', () {
    expect(CustomerEditForm.validateReference, isA<String? Function(String)>());
    expect(
      CustomerEditForm().validateDiscountAgainstTotal,
      isA<String? Function()>(),
    );
  });

  // Form-3 stub bodies: Phase 4 output COMPILES BUT DOES NOT EXECUTE, and the
  // `UnsupportedError` explication is what a Phase 6 implementer fills in.
  test('an unimplemented endpoint body throws its explication', () {
    expect(
      () => CustomerService().save(null),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('marked catalogue members hold their authored keys verbatim', () {
    expect(Messages.saveConflict.id, 'CUST-409');
    expect(CustomerErrors.notFound.id, 'CUST-404');
    expect(Operations.customerSave.id, 'customer.save');
    expect(RouteCatalog.customerEdit.id, 'customer/edit');
    expect(NotificationCatalog.orderShipped, 'order.shipped');
    expect(NotificationCatalog.smsChannel, 'sms');
  });

  test('a marked domain enum is an ordinary Dart enum', () {
    expect(CustomerStatus.values, [
      CustomerStatus.prospect,
      CustomerStatus.active,
      CustomerStatus.churned,
    ]);
  });

  test('the report members and its parts are reachable', () {
    final report = SalesByRegionReport();
    expect(report.revenue, isNull);
    expect(report.revenueChart, isNull);
    expect(report.period, isNull);
    expect(CustomerSaveContract().status, isNull);
    expect(SaveButton(), isA<SaveButton>());
    expect(CustomerEditLayout(), isA<CustomerEditLayout>());
    expect(CustomerListState(), isA<CustomerListState>());
    expect(CustomerScreenFlow(), isA<CustomerScreenFlow>());
    expect(CustomerRepository(), isA<CustomerRepository>());
    expect(CustomerSaveCall(), isA<CustomerSaveCall>());
    expect(LoginFlow(), isA<LoginFlow>());
    expect(MonthEndCloseJob(), isA<MonthEndCloseJob>());
    expect(ReindexOnMergeJob(), isA<ReindexOnMergeJob>());
    expect(CrmSeedData(), isA<CrmSeedData>());
    expect(CrmAddCreditLimit(), isA<CrmAddCreditLimit>());
    expect(AppServerConfig().smtpHost, 'localhost');
  });
}
