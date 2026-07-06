// Authoring tool for the shared cross-language SOM sample document.
//
// Builds a broad, coherent `D00SolutionBlueprint` (Solution Blueprint) for a
// fictional "Meridian Order Management" programme via the typed facade, then
// serialises it to the language-agnostic `*.docspecs.yaml` wire format (and a
// human-readable markdown rendition) under `tom_som_conformance/samples/`.
//
// The YAML file is the single artifact every language runtime loads for the
// `d_sample_*`/`e_sample_*` access examples, so it must be produced through the
// typed API to guarantee a valid wire format. Re-run after model changes:
//
//   dart run tool/build_shared_sample.dart
import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

/// The model version stamped into the sample. Sourced directly from the
/// generated facade's own `modelVersion` (`D00SolutionBlueprint.modelVersion`)
/// so it always tracks the current object-model version — the typed facade then
/// treats the sample as editable rather than cross-major read-only.
const String sampleModelVersion = D00SolutionBlueprint.modelVersion;

void main() {
  final doc = SpecDocument();
  final sbp = D00SolutionBlueprint(doc);

  sbp.content = _p('''
Solution Blueprint for the Meridian Order Management (MOM) programme. MOM
replaces three ageing back-office systems with a single, event-driven order
platform serving the wholesale and e-commerce channels of a mid-market
distributor. This blueprint is the master specification from which the twelve
Phase 3 documents (CLA, TOM, IFM, RSP, ISC, ATS, IIS, SAS, XDS, QAP, DRM, TRP)
are derived.''');

  // SBP.1 Document Control.
  sbp.documentControl.content = _p('''
Version 1.0, approved 2026-05-18. Authors: Solution Architecture chapter.
Approvers: Programme Sponsor (VP Operations), Enterprise Architecture Board.
Revision history is tracked in the programme wiki; this blueprint supersedes the
2025 "Order Platform Vision" one-pager.''');

  // SBP.2 Introduction & Scope.
  final intro = sbp.introductionAndScope;
  intro.content = _p('''
MOM covers order capture, validation, pricing, fulfilment orchestration, and
post-sale amendments across the wholesale (EDI) and e-commerce (REST) channels.
Out of scope: warehouse robotics control, general-ledger posting (delegated to
the existing finance ERP via a published interface), and CRM lead management.''');
  intro.goals.content = _p('''
Primary goals: (1) cut median order-to-confirmation time from 4.2 hours to under
5 minutes; (2) remove the nightly batch window entirely; (3) give operations
staff a single screen for the full order lifecycle. Secondary goal: expose a
stable public order API for third-party marketplace integrators. Three legacy
systems are decommissioned: "OrderDesk" (green-screen order entry, 1998),
"PriceCalc" (a spreadsheet-derived pricing service), and the nightly "BatchSync"
file exchange with the warehouse.''');

  // SBP.3 Glossary & Abbreviations.
  sbp.glossaryAndAbbreviations.content = _p('''
MOM — Meridian Order Management. Line — a single product/quantity within an
order. Hold — a state in which an order awaits manual review. Fulfilment window
— the committed dispatch date range communicated to the customer. EDI — the
wholesale electronic data interchange channel.''');

  // SBP.4 Stakeholders & Governance.
  sbp.stakeholdersAndGovernance.content = _p('''
Sponsor: VP Operations. Product owner: Head of Order Operations. Key stakeholder
groups: wholesale account managers, e-commerce merchandising, warehouse
operations, finance, and the external marketplace partners. Governance runs
through a fortnightly steering board; architectural decisions are recorded as
ADRs owned by the Enterprise Architecture Board.''');

  // SBP.5 Current Landscape. Seeds -> CLA.
  final landscape = sbp.currentLandscape;
  landscape.content = _p('''
Today, order entry is manual and channel-specific. Wholesale orders arrive by
EDI and are re-keyed into OrderDesk; e-commerce orders drop into a queue that a
clerk clears twice a day. Pricing is recomputed nightly, so intraday price
changes are invisible until the next morning. There is no single source of truth
for order status — staff reconcile three systems by phone.''');
  // A representative slice of the current operational metrics list.
  landscape.operationalMetrics.add().content =
      'Median order-to-confirmation time: 4.2 hours (wholesale), 9 hours (e-commerce).';
  landscape.operationalMetrics.add().content =
      'Nightly batch window: 2h10m, during which no orders can be confirmed.';
  landscape.operationalMetrics.add().content =
      'Manual price-override rate: 11% of wholesale lines, indicating pricing drift.';
  landscape.operationalMetrics.add().content =
      'Order-status enquiry calls: ~340/week to the operations desk.';

  // SBP.6 Assumptions, Constraints & Dependencies.
  sbp.assumptionsConstraintsDependencies.content = _p('''
Assumes the finance ERP order-posting interface remains stable for the
programme's duration. Constrained to the corporate AWS eu-central-1 landing zone
and the approved managed-database catalogue. Depends on the warehouse team
delivering the new dispatch-event webhook by the end of increment 2.''');

  // SBP.7 Target Operating Model concept. Seeds -> TOM.
  sbp.targetOperatingModelConcept.content = _p('''
Orders flow through a single event-driven pipeline: Captured -> Validated ->
Priced -> Reserved -> Confirmed -> Fulfilled -> Closed, with an orthogonal Hold
sub-state for manual review. Every transition emits a domain event; operations
staff work from one queue view filtered by state. Pricing becomes a synchronous
call, eliminating the batch window.''');

  // SBP.8 Information & Data Model. Seeds -> IFM.
  sbp.informationAndDataModel.content = _p('''
Core aggregates: Order (with Lines), Customer, Product, PriceList, and
FulfilmentPlan. Orders reference Customers and Products by stable IDs; prices are
snapshotted onto each Line at pricing time so historical orders remain
reproducible. The event log is the system of record; read models are projections.''');

  // SBP.9 Requirements. Seeds -> RSP.
  sbp.requirements.content = _p('''
Functional: capture orders from EDI and REST; validate against credit and stock;
price synchronously; reserve stock; confirm within 5 minutes; support partial
amendments and cancellations before dispatch. Non-functional: 99.9% capture-API
availability; p95 confirmation latency < 30s; full audit trail; GDPR-compliant
handling of customer data with a 7-year retention policy on order records.''');

  // SBP.11 Solution Architecture & Technology. Seeds -> ATS.
  sbp.solutionArchitectureAndTechnology.content = _p('''
Event-sourced order service (Dart/Flutter back office, Kotlin domain services)
on Kubernetes, backed by PostgreSQL for read models and a managed Kafka cluster
for the event backbone. The public order API is an API-gateway-fronted REST
surface; EDI ingestion runs as an adapter that translates to the same command
API. Infrastructure is provisioned as code.''');

  // SBP.12 Security & Access Model. Seeds -> SAS.
  sbp.securityAndAccessModel.content = _p('''
Access is role-based: Order Clerk, Order Supervisor (may release holds),
Pricing Admin, and Integration (machine) accounts scoped to specific channels.
All customer PII is encrypted at rest; the public API uses OAuth2 client
credentials with per-partner rate limits. Every state transition is attributed
to an authenticated principal in the audit log.''');

  // SBP.13 Experience & Interface Design. Seeds -> XDS.
  sbp.experienceAndInterfaceDesign.content = _p('''
The operations back office is a single-page application organised around the
order queue. The primary screen is a state-filtered work list; selecting an
order opens a lifecycle timeline with inline actions (release hold, amend line,
cancel). Design priorities: keyboard-first navigation for high-volume clerks and
an unambiguous status colour language shared with the public tracking page.''');

  // SBP.14 Quality & Acceptance Model. Seeds -> QAP.
  sbp.qualityAndAcceptanceModel.content = _p('''
Acceptance is gated on: a fully automated regression suite over the order
lifecycle; a two-week parallel run against OrderDesk with < 0.1% reconciliation
variance; and a load test sustaining 3x peak-hour order volume within the p95
latency budget. Business sign-off requires the operations desk to clear a full
day's orders on MOM alone.''');

  // SBP.15 Delivery, Transition & Rollout. Seeds -> DRM, TRP.
  sbp.deliveryTransitionAndRollout.content = _p('''
Five increments: (1) order capture + event backbone; (2) synchronous pricing +
warehouse webhook; (3) fulfilment orchestration + back office; (4) public API +
marketplace onboarding; (5) legacy decommission. Transition is channel-by-channel
(e-commerce first, then wholesale) with a parallel-run safety net and a
documented rollback to OrderDesk until the parallel-run gate passes.''');

  // The narrative above is the blueprint prose. The blocks below turn MOM into
  // a genuinely *implementable* specification: typed requirement lists, actors,
  // Cockburn-style use cases with full main/extension flows, fully-detailed
  // screens (sections, elements, actions, empty/error states), a coherent
  // relational data model, and an end-to-end key scenario.
  _authorRequirements(sbp);
  _authorActorsAndUseCases(sbp);
  _authorDataModel(sbp);
  _authorScreens(sbp);

  // --- Serialise ----------------------------------------------------------
  final samplesDir = Directory('../tom_som_conformance/samples');
  samplesDir.createSync(recursive: true);

  final yaml = SpecDocumentYaml.encode(
    document: doc,
    modelVersion: sampleModelVersion,
  );
  final yamlFile =
      File('${samplesDir.path}/meridian_order_management.docspecs.yaml');
  yamlFile.writeAsStringSync(yaml);

  // Human-readable markdown rendition of the SBP root, via the reflection model.
  final metaFile =
      File.fromUri(Platform.script.resolve('../meta/spec_model.meta.json'));
  final model = SpecModel.fromJson(
      jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>);
  final sbpRoot =
      model.roots.firstWhere((r) => r.type == 'D00SolutionBlueprint');
  final markdown = SpecDocumentMarkdown(model, doc).exportRoot(sbpRoot);
  final mdFile = File('${samplesDir.path}/meridian_order_management.md');
  mdFile.writeAsStringSync(markdown);

  stdout.writeln('Wrote sample to ${samplesDir.absolute.path}');
  stdout.writeln('  meridian_order_management.docspecs.yaml (${yaml.length} bytes)');
  stdout.writeln('  meridian_order_management.md (${markdown.length} bytes)');
}

/// Collapses a hard-wrapped multi-line string literal into a single paragraph
/// so the authored content reads naturally on disk.
String _p(String raw) =>
    raw.trim().replaceAll('\n', ' ').replaceAll(RegExp(r' +'), ' ');

// ---------------------------------------------------------------------------
// Requirements: functional, technical, security, and organizational lists.
// These live under SBP.2 Introduction & Scope -> Requirements Overview, which
// is where the typed requirement lists actually hang (not SBP.9, which is the
// thin localization/training container).
// ---------------------------------------------------------------------------
void _authorRequirements(D00SolutionBlueprint sbp) {
  final reqs = sbp.introductionAndScope.requirements;
  reqs.content = _p('''
The requirements below are the contract MOM is built and accepted against. IDs
are stable and referenced from the use cases, screens, and data model so every
downstream artifact traces back to a requirement.''');

  // --- Functional requirements (FR) --------------------------------------
  final fr = reqs.functionalRequirements.requirements;

  final fr1 = fr.add();
  fr1.content
    ..requirementId = 'FR-01'
    ..title = 'Capture orders from EDI and REST channels'
    ..status = 'Approved';
  fr1.details.content
    ..description = _p('''
The system must accept orders from the wholesale EDI adapter and the public
REST order API, translating both into a single internal order-capture command
so downstream processing is channel-agnostic.''')
    ..requirementType = 'Functional'
    ..category = 'Order Capture';
  fr1.priority.content
    ..priority = 'Must'
    ..businessValue = 'High'
    ..effort = 'M'
    ..riskLevel = 'Medium';
  fr1.source.content
    ..source = 'VP Operations'
    ..requestDate = '2026-04-02'
    ..rationale = 'Both channels must feed the same lifecycle to retire re-keying.';
  fr1.verification.content
    ..fitCriterion = 'An EDI and a REST order both produce an Order in state Captured within 2s.'
    ..customerSatisfaction = '5'
    ..customerDissatisfaction = '1';
  _acceptance(fr1.acceptanceCriteria.criteria.add(), 'FR-01-AC-1',
      'EDI order accepted',
      given: 'a well-formed EDI 850 purchase order',
      when: 'the EDI adapter submits it to the capture API',
      then: 'an Order is created in state Captured and a domain event is emitted');
  _acceptance(fr1.acceptanceCriteria.criteria.add(), 'FR-01-AC-2',
      'REST order accepted',
      given: 'a valid REST order payload from an authenticated partner',
      when: 'POST /orders is called',
      then: 'an Order is created in state Captured with the same shape as EDI');

  final fr2 = fr.add();
  fr2.content
    ..requirementId = 'FR-02'
    ..title = 'Price orders synchronously at capture time'
    ..status = 'Approved';
  fr2.details.content
    ..description = _p('''
Pricing must be computed synchronously during order processing and the resulting
unit price snapshotted onto each order line, eliminating the nightly batch and
making historical orders reproducible.''')
    ..requirementType = 'Functional'
    ..category = 'Pricing';
  fr2.priority.content
    ..priority = 'Must'
    ..businessValue = 'High'
    ..effort = 'M'
    ..riskLevel = 'Medium';
  fr2.verification.content.fitCriterion =
      'Each confirmed line carries a unitPrice snapshot equal to the price list at pricing time.';
  _acceptance(fr2.acceptanceCriteria.criteria.add(), 'FR-02-AC-1',
      'Price snapshotted onto line',
      given: 'an order with two lines',
      when: 'the order is priced',
      then: 'each line stores the resolved unit price as of the pricing timestamp');

  final fr3 = fr.add();
  fr3.content
    ..requirementId = 'FR-03'
    ..title = 'Reserve stock before confirmation'
    ..status = 'Approved';
  fr3.details.content
    ..description = _p('''
Before an order is confirmed the system must reserve stock for every line;
insufficient stock places the affected line on Hold rather than failing the
whole order.''')
    ..requirementType = 'Functional'
    ..category = 'Fulfilment';
  fr3.priority.content
    ..priority = 'Must'
    ..businessValue = 'High'
    ..effort = 'L'
    ..riskLevel = 'High';

  final fr4 = fr.add();
  fr4.content
    ..requirementId = 'FR-04'
    ..title = 'Confirm orders within five minutes'
    ..status = 'Approved';
  fr4.details.content
    ..description = _p('''
An order that passes validation, pricing, and reservation must reach state
Confirmed within five minutes of capture, with the confirmation communicated on
the operations work list and the public tracking page.''')
    ..requirementType = 'Functional'
    ..category = 'Order Lifecycle';
  fr4.priority.content
    ..priority = 'Must'
    ..businessValue = 'High'
    ..effort = 'M'
    ..riskLevel = 'Medium';

  final fr5 = fr.add();
  fr5.content
    ..requirementId = 'FR-05'
    ..title = 'Amend or cancel an order before dispatch'
    ..status = 'Approved';
  fr5.details.content
    ..description = _p('''
Until an order is dispatched, a clerk must be able to amend line quantities and
cancel lines or the whole order; each amendment re-runs pricing and reservation
for the affected lines and is fully audited.''')
    ..requirementType = 'Functional'
    ..category = 'Order Amendment';
  fr5.priority.content
    ..priority = 'Should'
    ..businessValue = 'Medium'
    ..effort = 'M'
    ..riskLevel = 'Medium';

  final fr6 = fr.add();
  fr6.content
    ..requirementId = 'FR-06'
    ..title = 'Release a manual hold'
    ..status = 'Approved';
  fr6.details.content
    ..description = _p('''
An Order Supervisor must be able to review an order on Hold and release it back
into the lifecycle, recording a reason that is attached to the audit trail.''')
    ..requirementType = 'Functional'
    ..category = 'Exception Handling';
  fr6.priority.content
    ..priority = 'Must'
    ..businessValue = 'High'
    ..effort = 'S'
    ..riskLevel = 'Low';
  _acceptance(fr6.acceptanceCriteria.criteria.add(), 'FR-06-AC-1',
      'Supervisor releases hold',
      given: 'an order in state Hold',
      when: 'a supervisor releases it with a reason',
      then: 'the order resumes at the transition that placed it on Hold and the reason is audited');

  // --- Technical requirements (TR) ---------------------------------------
  final tr = reqs.technicalRequirements.requirements;

  final tr1 = tr.add();
  tr1.content
    ..requirementId = 'TR-01'
    ..title = 'Confirmation latency budget'
    ..status = 'Approved';
  tr1.details.content
    ..description = 'The 95th-percentile order-confirmation latency must stay within budget under peak load.'
    ..category = 'Performance'
    ..subcategory = 'Latency'
    ..priority = 'Must'
    ..source = 'Operations SLA'
    ..rationale = 'Sub-30s p95 keeps the five-minute business promise safe under 3x peak.';
  tr1.measurement.content
    ..metric = 'p95 capture-to-confirmation latency'
    ..currentValue = '4.2h (legacy)'
    ..targetValue = '< 30s'
    ..measurementMethod = 'Distributed tracing over the confirmation span'
    ..measurementEnvironment = 'Load test at 3x peak-hour volume'
    ..measurementFrequency = 'Per release + continuous in production';

  final tr2 = tr.add();
  tr2.content
    ..requirementId = 'TR-02'
    ..title = 'Capture API availability'
    ..status = 'Approved';
  tr2.details.content
    ..description = 'The order-capture API must meet a 99.9% monthly availability target.'
    ..category = 'Reliability'
    ..subcategory = 'Availability'
    ..priority = 'Must'
    ..source = 'Partner integration agreement'
    ..rationale = 'Marketplace partners depend on the capture API being continuously reachable.';
  tr2.measurement.content
    ..metric = 'Monthly capture-API availability'
    ..targetValue = '>= 99.9%'
    ..measurementMethod = 'Synthetic probes + gateway success-rate metrics'
    ..measurementFrequency = 'Monthly';

  final tr3 = tr.add();
  tr3.content
    ..requirementId = 'TR-03'
    ..title = 'Event-sourced order service'
    ..status = 'Approved';
  tr3.details.content
    ..description = _p('''
The order service must be event-sourced: the append-only event log is the system
of record and all read models are projections rebuildable from the log.''')
    ..category = 'Architecture'
    ..subcategory = 'Persistence'
    ..priority = 'Must'
    ..source = 'Enterprise Architecture Board'
    ..rationale = 'Reproducible history and rebuildable projections are core to auditability.';

  // --- Security requirements (SR) ----------------------------------------
  final sr = reqs.securityRequirements.requirements;

  final sr1 = sr.add();
  sr1.content
    ..requirementId = 'SR-01'
    ..title = 'Role-based access control'
    ..description = _p('''
Access is governed by the roles Order Clerk, Order Supervisor, Pricing Admin,
and Integration (machine) accounts scoped to specific channels; every state
transition is attributed to an authenticated principal.''');
  sr1.classification.content
    ..category = 'Access Control'
    ..subcategory = 'Authorization'
    ..priority = 'Must'
    ..source = 'Security chapter'
    ..rationale = 'Least privilege across human and machine actors.'
    ..threatMitigated = 'Unauthorized order manipulation'
    ..dataClassification = 'Internal';
  sr1.compliance.content
    ..owaspCategory = 'A01:2021 Broken Access Control'
    ..nistControl = 'AC-6'
    ..complianceReference = 'Corporate IAM policy v3';

  final sr2 = sr.add();
  sr2.content
    ..requirementId = 'SR-02'
    ..title = 'Encrypt customer PII at rest'
    ..description = 'All customer personally identifiable information must be encrypted at rest.';
  sr2.classification.content
    ..category = 'Data Protection'
    ..subcategory = 'Encryption'
    ..priority = 'Must'
    ..source = 'Data Protection Officer'
    ..rationale = 'GDPR obligations on customer records with a 7-year retention.'
    ..threatMitigated = 'PII disclosure from storage compromise'
    ..dataClassification = 'Confidential';
  sr2.compliance.content
    ..nistControl = 'SC-28'
    ..complianceReference = 'GDPR Art. 32';

  final sr3 = sr.add();
  sr3.content
    ..requirementId = 'SR-03'
    ..title = 'OAuth2 client credentials on the public API'
    ..description = _p('''
The public order API must authenticate partners with OAuth2 client-credentials
tokens and enforce per-partner rate limits at the gateway.''');
  sr3.classification.content
    ..category = 'API Security'
    ..subcategory = 'Authentication'
    ..priority = 'Must'
    ..source = 'Security chapter'
    ..rationale = 'Machine-to-machine partner access without shared secrets in code.'
    ..threatMitigated = 'Credential replay and partner impersonation'
    ..dataClassification = 'Internal';
  sr3.compliance.content
    ..owaspCategory = 'API2:2023 Broken Authentication'
    ..nistControl = 'IA-5';

  // --- Organizational requirements (OR) ----------------------------------
  final orq = reqs.organizationalRequirements.requirements;

  final or1 = orq.add();
  or1.content
    ..requirementId = 'OR-01'
    ..title = 'Train the operations desk on MOM'
    ..description = _p('''
Before cutover the order-operations desk must be trained to run the full order
lifecycle on MOM alone, including hold release and amendments.''');
  or1.impact.content
    ..impactedGroups = 'Order Operations desk'
    ..impactedUserCount = '25'
    ..changeType = 'Process + tooling'
    ..changeComplexity = 'Medium'
    ..resistance = 'Low';

  final or2 = orq.add();
  or2.content
    ..requirementId = 'OR-02'
    ..title = 'Staff the parallel run'
    ..description = _p('''
The two-week parallel run against OrderDesk requires staffing to reconcile both
systems daily until the < 0.1% variance gate passes.''');
  or2.impact.content
    ..impactedGroups = 'Order Operations, Finance'
    ..impactedUserCount = '30'
    ..changeType = 'Temporary dual-running'
    ..changeComplexity = 'Medium'
    ..resistance = 'Medium';
}

/// Fills one acceptance-criterion form (Given/When/Then).
void _acceptance(dynamic ac, String id, String title,
    {required String given, required String when, required String then}) {
  ac.content
    ..criterionId = id
    ..criterionTitle = title
    ..given = given
    ..when = when
    ..then = then
    ..verificationMethod = 'Automated test'
    ..testType = 'Integration'
    ..priority = 'Must'
    ..status = 'Draft';
}

// ---------------------------------------------------------------------------
// Actors + Cockburn-style use cases with full main and extension flows.
// These hang under SBP.7 Target Operating Model -> Target Business Process ->
// Process Steps & Actor Interactions.
// ---------------------------------------------------------------------------
void _authorActorsAndUseCases(D00SolutionBlueprint sbp) {
  final psai = sbp.targetOperatingModelConcept.targetBusinessProcess
      .processStepsAndActorInteractions;

  // --- Actors ------------------------------------------------------------
  final actors = psai.actorOverview.actors;
  _actor(actors.add(), 'ACT-01', 'Order Clerk', 'Human', 'Primary',
      'Clears the order work list, amends lines, and cancels orders before dispatch.',
      unit: 'Order Operations', count: '25');
  _actor(actors.add(), 'ACT-02', 'Order Supervisor', 'Human', 'Primary',
      'Reviews orders on Hold and releases them back into the lifecycle.',
      unit: 'Order Operations', count: '4');
  _actor(actors.add(), 'ACT-03', 'Pricing Admin', 'Human', 'Supporting',
      'Maintains the price lists that the synchronous pricing step consumes.',
      unit: 'Commercial', count: '3');
  _actor(actors.add(), 'ACT-04', 'EDI Integration Account', 'System', 'Primary',
      'Machine account through which the wholesale EDI adapter submits orders.',
      unit: 'Integration', count: '1');

  // --- Use cases ---------------------------------------------------------
  final ucs = psai.interactionCatalog.interactions;

  // UC-01 Capture Wholesale Order (EDI).
  final uc1 = ucs.add();
  uc1.identification.content
    ..interactionId = 'UC-01'
    ..useCaseName = 'Capture Wholesale Order (EDI)'
    ..processReference = 'BP-Order-Capture'
    ..briefDescription = 'A wholesale EDI purchase order is captured, validated, priced, reserved, and confirmed.'
    ..fullDescription = _p('''
The EDI adapter submits a translated purchase order to the capture command API.
The system validates the customer and lines, prices each line synchronously,
reserves stock, and confirms the order — emitting a domain event at every
transition so the work list and public tracking page stay current.''')
    ..primaryActor = 'ACT-04 EDI Integration Account'
    ..supportingActors = 'ACT-01 Order Clerk'
    ..goalLevel = 'User goal'
    ..designScope = 'System';
  final uc1pre = uc1.preconditions.add();
  uc1pre.content
    ..precondition = 'The submitting Integration account is authenticated and scoped to the wholesale channel.'
    ..trigger = 'An EDI 850 purchase order arrives at the wholesale adapter.'
    ..triggerType = 'External'
    ..triggerSource = 'EDI gateway'
    ..triggerData = 'EDI 850 document';
  final uc1post = uc1.postconditions.add();
  uc1post.content
    ..minimalGuarantees = 'Either an Order exists in a well-defined state or the submission is rejected with a reason; no partial order is persisted.'
    ..successGuarantees = 'The Order is in state Confirmed with priced, reserved lines and a full event history.'
    ..dataPostcondition = 'Order and OrderLine rows persisted; reservation recorded against Product stock.';
  _step(uc1.mainScenario.steps.add(), '1',
      'EDI adapter submits the translated order to the capture API.',
      'System creates the Order in state Captured and emits OrderCaptured.',
      data: 'Order, OrderLine', ui: '—');
  _step(uc1.mainScenario.steps.add(), '2',
      'System validates customer credit and line stock references.',
      'Order moves to Validated; invalid references are flagged per line.',
      data: 'Customer, Product', rule: 'Credit limit not exceeded');
  _step(uc1.mainScenario.steps.add(), '3',
      'System prices each line against the active price list.',
      'Unit price is snapshotted onto each line; Order moves to Priced.',
      data: 'PriceList, OrderLine', rule: 'FR-02 price snapshot');
  _step(uc1.mainScenario.steps.add(), '4',
      'System reserves stock for every line.',
      'Reservations recorded; Order moves to Reserved.',
      data: 'Product', rule: 'FR-03 reserve before confirm');
  _step(uc1.mainScenario.steps.add(), '5',
      'System confirms the order.',
      'Order moves to Confirmed within five minutes and appears on the work list.',
      data: 'Order', rule: 'FR-04 five-minute confirmation');
  // Extension 2a: credit check fails.
  final ex2a = uc1.extensions.extensions.add();
  ex2a.content
    ..extensionId = '2a'
    ..branchPoint = 'Step 2'
    ..condition = 'Customer credit limit would be exceeded'
    ..extensionType = 'Exception'
    ..description = 'Validation detects the order exceeds the customer credit limit.'
    ..outcome = 'Order is placed on Hold for supervisor review (see UC-02).'
    ..returnPoint = 'Step 3 after release'
    ..severity = 'High';
  _extStep(ex2a.steps.add(), '2a.1',
      'System places the Order on Hold and emits OrderHeld.',
      'Order appears in the Hold filter of the work list with reason "Credit exceeded".');
  // Extension 4a: insufficient stock.
  final ex4a = uc1.extensions.extensions.add();
  ex4a.content
    ..extensionId = '4a'
    ..branchPoint = 'Step 4'
    ..condition = 'Insufficient stock for one or more lines'
    ..extensionType = 'Exception'
    ..description = 'Reservation cannot be fully satisfied for a line.'
    ..outcome = 'The affected line is placed on Hold; other lines proceed.'
    ..returnPoint = 'Step 5 for satisfiable lines'
    ..severity = 'Medium';
  _extStep(ex4a.steps.add(), '4a.1',
      'System holds the unsatisfiable line and reserves the rest.',
      'The order is partially reserved; the held line is flagged for follow-up.');

  // UC-02 Release Order Hold.
  final uc2 = ucs.add();
  uc2.identification.content
    ..interactionId = 'UC-02'
    ..useCaseName = 'Release Order Hold'
    ..processReference = 'BP-Order-Exception'
    ..briefDescription = 'A supervisor reviews an order on Hold and releases it back into the lifecycle.'
    ..fullDescription = _p('''
A supervisor opens an order on Hold from the work list, reviews the hold reason,
and either releases it — resuming the lifecycle at the transition that placed it
on Hold — or cancels it, recording a reason in both cases.''')
    ..primaryActor = 'ACT-02 Order Supervisor'
    ..goalLevel = 'User goal'
    ..designScope = 'System';
  final uc2pre = uc2.preconditions.add();
  uc2pre.content
    ..precondition = 'An order exists in state Hold and the actor holds the Order Supervisor role.'
    ..trigger = 'Supervisor selects a held order from the work list.'
    ..triggerType = 'User'
    ..triggerSource = 'Order Work List screen';
  final uc2post = uc2.postconditions.add();
  uc2post.content
    ..successGuarantees = 'The order resumes at the transition that placed it on Hold, with the release reason audited.'
    ..auditTrail = 'Release attributed to the supervisor principal with timestamp and reason.';
  _step(uc2.mainScenario.steps.add(), '1',
      'Supervisor opens the held order and reviews the reason.',
      'System shows the lifecycle timeline and the hold reason.',
      data: 'Order', ui: 'Order Detail timeline');
  _step(uc2.mainScenario.steps.add(), '2',
      'Supervisor releases the order with a reason.',
      'System resumes the lifecycle and emits OrderHoldReleased.',
      data: 'Order', rule: 'FR-06 hold release');

  // UC-03 Amend Order Line before dispatch.
  final uc3 = ucs.add();
  uc3.identification.content
    ..interactionId = 'UC-03'
    ..useCaseName = 'Amend Order Line Before Dispatch'
    ..processReference = 'BP-Order-Amendment'
    ..briefDescription = 'A clerk changes a line quantity before dispatch, re-running pricing and reservation.'
    ..fullDescription = _p('''
A clerk edits the quantity of a line on a not-yet-dispatched order. The system
re-prices and re-reserves only the affected line and records the amendment on the
audit trail.''')
    ..primaryActor = 'ACT-01 Order Clerk'
    ..goalLevel = 'User goal'
    ..designScope = 'System';
  final uc3pre = uc3.preconditions.add();
  uc3pre.content
    ..precondition = 'The order is not yet dispatched and the actor holds the Order Clerk role.'
    ..trigger = 'Clerk edits a line quantity on the Order Detail screen.'
    ..triggerType = 'User'
    ..triggerSource = 'Order Detail screen';
  final uc3post = uc3.postconditions.add();
  uc3post.content
    ..successGuarantees = 'The amended line carries a fresh price snapshot and reservation; the amendment is audited.'
    ..dataPostcondition = 'OrderLine updated; prior values retained in the event history.';
  _step(uc3.mainScenario.steps.add(), '1',
      'Clerk changes the quantity of a line and saves.',
      'System validates the new quantity and re-prices the line.',
      data: 'OrderLine, PriceList', rule: 'FR-05 amend before dispatch');
  _step(uc3.mainScenario.steps.add(), '2',
      'System re-reserves stock for the amended line.',
      'Reservation is adjusted; the order returns to Confirmed if fully satisfied.',
      data: 'Product', rule: 'FR-03 reserve before confirm');

  // --- Key end-to-end scenario ------------------------------------------
  final scn = psai.keyScenarios.scenarios.add();
  scn.identification.content
    ..scenarioId = 'SCN-01'
    ..scenarioName = 'Happy-path wholesale order, capture to fulfilment'
    ..scenarioType = 'End-to-end'
    ..description = 'A clean wholesale order flows from EDI capture through to fulfilment with no holds.'
    ..businessGoal = 'Confirm and fulfil a wholesale order without manual intervention.'
    ..primaryActor = 'ACT-04 EDI Integration Account'
    ..supportingActors = 'ACT-01 Order Clerk'
    ..priority = 'High'
    ..complexity = 'Medium';
  _scnStep(scn.steps.add(), '1', 'ACT-04 EDI Integration Account',
      'Submits a two-line wholesale order.',
      'Order captured, validated, priced, reserved, and confirmed within five minutes.');
  _scnStep(scn.steps.add(), '2', 'ACT-01 Order Clerk',
      'Observes the confirmed order on the work list.',
      'Order shows state Confirmed with both lines priced and reserved.');
  _scnStep(scn.steps.add(), '3', 'System',
      'Receives the warehouse dispatch webhook.',
      'Order moves to Fulfilled and the public tracking page updates.');
}

void _actor(dynamic a, String id, String name, String type, String category,
    String description,
    {required String unit, required String count}) {
  a.identification.content
    ..actorId = id
    ..actorName = name
    ..actorType = type
    ..category = category
    ..description = description
    ..organizationalUnit = unit
    ..estimatedCount = count
    ..geographicDistribution = 'Single distribution centre';
}

void _step(dynamic s, String number, String actorAction, String systemResponse,
    {String data = '', String rule = '', String ui = ''}) {
  s.content
    ..stepNumber = number
    ..actorAction = actorAction
    ..systemResponse = systemResponse
    ..dataInvolved = data
    ..businessRuleApplied = rule
    ..uiElementUsed = ui;
}

void _extStep(dynamic s, String number, String action, String response) {
  s.content
    ..stepNumber = number
    ..action = action
    ..response = response;
}

void _scnStep(dynamic s, String number, String actor, String action,
    String systemResponse) {
  s.content
    ..stepNumber = number
    ..actor = actor
    ..action = action
    ..systemResponse = systemResponse;
}

// ---------------------------------------------------------------------------
// Data model: a coherent relational core (Order, OrderLine, Customer, Product)
// with attributes, keys, and the relationships between them, under SBP.8.
// ---------------------------------------------------------------------------
void _authorDataModel(D00SolutionBlueprint sbp) {
  final dm = sbp.informationAndDataModel.dataModel;
  dm.content = _p('''
The relational core of MOM. Order is the aggregate root; each Order owns its
OrderLines and references a Customer and, per line, a Product. Prices are
snapshotted onto lines so historical orders remain reproducible.''');

  // Order.
  final order = dm.entities.add();
  order.identity
    ..entityName = 'Order'
    ..tableName = 'mom_order'
    ..entityAlias = 'ORD'
    ..description = 'A customer order captured from EDI or REST and driven through the lifecycle.'
    ..entityStereoType = 'Aggregate Root';
  order.classification
    ..category = 'Transactional'
    ..boundedContext = 'Ordering'
    ..owningDomain = 'Order Management'
    ..dataOwner = 'Head of Order Operations'
    ..sourceSystem = 'MOM';
  _attr(order.attributes.add(), 'orderId', 'order_id', 'Stable order identifier.',
      'UUID', 'uuid', pii: false, sensitivity: 'Internal');
  _attr(order.attributes.add(), 'customerId', 'customer_id',
      'Reference to the ordering customer.', 'UUID', 'uuid',
      pii: false, sensitivity: 'Internal');
  _attr(order.attributes.add(), 'channel', 'channel',
      'Capture channel: EDI or REST.', 'Enum', 'varchar(8)',
      pii: false, sensitivity: 'Internal');
  _attr(order.attributes.add(), 'status', 'status',
      'Lifecycle state (Captured..Closed, with Hold).', 'Enum', 'varchar(16)',
      pii: false, sensitivity: 'Internal');
  _attr(order.attributes.add(), 'createdAt', 'created_at',
      'Capture timestamp (UTC).', 'Timestamp', 'timestamptz',
      pii: false, sensitivity: 'Internal');
  _key(order.keyAttributes.add(), 'pk_order', 'Primary', 'order_id',
      'Primary key of the order.');

  // OrderLine.
  final line = dm.entities.add();
  line.identity
    ..entityName = 'OrderLine'
    ..tableName = 'mom_order_line'
    ..entityAlias = 'OLN'
    ..description = 'A single product/quantity within an order, with a snapshotted price.'
    ..entityStereoType = 'Entity';
  line.classification
    ..category = 'Transactional'
    ..boundedContext = 'Ordering'
    ..owningDomain = 'Order Management'
    ..dataOwner = 'Head of Order Operations'
    ..sourceSystem = 'MOM';
  _attr(line.attributes.add(), 'lineId', 'line_id', 'Stable line identifier.',
      'UUID', 'uuid', pii: false, sensitivity: 'Internal');
  _attr(line.attributes.add(), 'orderId', 'order_id',
      'Owning order reference.', 'UUID', 'uuid',
      pii: false, sensitivity: 'Internal');
  _attr(line.attributes.add(), 'productId', 'product_id',
      'Referenced product.', 'UUID', 'uuid',
      pii: false, sensitivity: 'Internal');
  _attr(line.attributes.add(), 'quantity', 'quantity',
      'Ordered quantity.', 'Integer', 'int', pii: false, sensitivity: 'Internal');
  _attr(line.attributes.add(), 'unitPrice', 'unit_price',
      'Snapshotted unit price at pricing time.', 'Decimal', 'numeric(12,2)',
      pii: false, sensitivity: 'Internal');
  _key(line.keyAttributes.add(), 'pk_order_line', 'Primary', 'line_id',
      'Primary key of the order line.');
  final lineFk = line.keyAttributes.add();
  _key(lineFk, 'fk_line_order', 'Foreign', 'order_id',
      'References the owning order.');
  lineFk.referencedEntityRef = 'Order';

  // Customer.
  final customer = dm.entities.add();
  customer.identity
    ..entityName = 'Customer'
    ..tableName = 'mom_customer'
    ..entityAlias = 'CUS'
    ..description = 'A wholesale or e-commerce customer that places orders.'
    ..entityStereoType = 'Aggregate Root';
  customer.classification
    ..category = 'Master'
    ..boundedContext = 'Customer'
    ..owningDomain = 'Customer Management'
    ..dataOwner = 'Commercial'
    ..sourceSystem = 'MOM';
  _attr(customer.attributes.add(), 'customerId', 'customer_id',
      'Stable customer identifier.', 'UUID', 'uuid',
      pii: false, sensitivity: 'Internal');
  _attr(customer.attributes.add(), 'name', 'name',
      'Customer legal name (PII).', 'String', 'varchar(200)',
      pii: true, sensitivity: 'Confidential');
  _attr(customer.attributes.add(), 'creditLimit', 'credit_limit',
      'Approved credit limit used by validation.', 'Decimal', 'numeric(14,2)',
      pii: false, sensitivity: 'Confidential');
  _key(customer.keyAttributes.add(), 'pk_customer', 'Primary', 'customer_id',
      'Primary key of the customer.');

  // Product.
  final product = dm.entities.add();
  product.identity
    ..entityName = 'Product'
    ..tableName = 'mom_product'
    ..entityAlias = 'PRD'
    ..description = 'A sellable product referenced by order lines and priced by the price list.'
    ..entityStereoType = 'Aggregate Root';
  product.classification
    ..category = 'Master'
    ..boundedContext = 'Catalogue'
    ..owningDomain = 'Merchandising'
    ..dataOwner = 'Merchandising'
    ..sourceSystem = 'MOM';
  _attr(product.attributes.add(), 'productId', 'product_id',
      'Stable product identifier.', 'UUID', 'uuid',
      pii: false, sensitivity: 'Internal');
  _attr(product.attributes.add(), 'sku', 'sku',
      'Stock-keeping unit.', 'String', 'varchar(40)',
      pii: false, sensitivity: 'Internal');
  _attr(product.attributes.add(), 'name', 'name',
      'Product display name.', 'String', 'varchar(200)',
      pii: false, sensitivity: 'Internal');
  _key(product.keyAttributes.add(), 'pk_product', 'Primary', 'product_id',
      'Primary key of the product.');

  // Relationships.
  final rels = dm.entityRelationships;
  rels.content = 'The foreign-key relationships binding the ordering core together.';
  _rel(rels.items.add(), 'Order-owns-Lines', 'Composition',
      'An order owns one or more order lines.', 'Order', 'OrderLine',
      source: '1', target: '1..*', fk: 'mom_order_line.order_id');
  _rel(rels.items.add(), 'Order-placed-by-Customer', 'Association',
      'Each order is placed by exactly one customer.', 'Order', 'Customer',
      source: '*', target: '1', fk: 'mom_order.customer_id');
  _rel(rels.items.add(), 'Line-references-Product', 'Association',
      'Each order line references exactly one product.', 'OrderLine', 'Product',
      source: '*', target: '1', fk: 'mom_order_line.product_id');
}

void _attr(dynamic a, String name, String column, String description,
    String dataType, String physicalType,
    {required bool pii, required String sensitivity}) {
  a.identity
    ..attributeName = name
    ..columnName = column
    ..description = description;
  a.dataTypeSpec
    ..dataType = dataType
    ..physicalType = physicalType;
  a.securityClassification
    ..sensitivityLevel = sensitivity
    ..isPii = pii ? 'true' : 'false';
}

void _key(dynamic k, String name, String type, String columns,
    String description) {
  k.content
    ..keyName = name
    ..keyType = type
    ..keyColumns = columns
    ..description = description;
}

void _rel(dynamic r, String name, String type, String description,
    String sourceEntity, String targetEntity,
    {required String source, required String target, required String fk}) {
  r.identity
    ..relationshipName = name
    ..relationshipType = type
    ..description = description
    ..businessJustification = 'Maintains referential integrity across the ordering core.'
    ..implementationType = 'Foreign Key';
  r.cardinality
    ..sourceCardinality = source
    ..targetCardinality = target;
  r.navigation
    ..navigability = 'Bidirectional'
    ..foreignKeyLocation = fk;
  r.sourceEntityRef = sourceEntity;
  r.targetEntityRef = targetEntity;
}

// ---------------------------------------------------------------------------
// Screens: two fully-detailed screens (work list + order detail) with sections,
// elements, actions, and empty/error states, under SBP.13 Experience & Design.
// ---------------------------------------------------------------------------
void _authorScreens(D00SolutionBlueprint sbp) {
  final screens =
      sbp.experienceAndInterfaceDesign.screens.screenInventory.items;

  // SCR-01 Order Work List.
  final wl = screens.add();
  wl.content
    ..screenId = 'SCR-01'
    ..screenName = 'Order Work List'
    ..purpose = 'The single, state-filtered queue from which clerks work every order.';
  wl.classification.content
    ..screenCategory = 'List'
    ..routePattern = '/orders';
  wl.access.content
    ..accessLevel = 'Authenticated'
    ..requiredRoles = 'Order Clerk, Order Supervisor'
    ..permissionEffect = 'Allow';
  wl.traceability.content
    ..relatedUseCases = 'UC-01, UC-02'
    ..relatedRequirements = 'FR-01, FR-04, FR-06'
    ..dataEntities = 'Order'
    ..primaryAction = 'Open selected order';
  wl.presentation.content
    ..pageTitleResource = 'screen.orders.title'
    ..layout = 'Master-detail';

  final filters = wl.sections.items.add();
  filters.content
    ..sectionId = 'SCR-01-SEC-1'
    ..sectionName = 'State filter bar'
    ..purpose = 'Filter the queue by lifecycle state.'
    ..sectionType = 'Toolbar';
  filters.layout.content
    ..layoutDirection = 'Horizontal'
    ..displayOrder = '1';
  final stateFilter = filters.elements.add();
  stateFilter.content
    ..elementId = 'SCR-01-EL-1'
    ..elementName = 'State selector'
    ..elementType = 'SegmentedControl';
  stateFilter.resources.content
    ..labelResource = 'screen.orders.filter.state'
    ..hintResource = 'screen.orders.filter.state.hint';

  final list = wl.sections.items.add();
  list.content
    ..sectionId = 'SCR-01-SEC-2'
    ..sectionName = 'Order table'
    ..purpose = 'The work list itself, keyboard-navigable for high-volume clerks.'
    ..sectionType = 'DataTable';
  list.layout.content
    ..layoutDirection = 'Vertical'
    ..displayOrder = '2';
  final idCol = list.elements.add();
  idCol.content
    ..elementId = 'SCR-01-EL-2'
    ..elementName = 'Order ID column'
    ..elementType = 'TextField';
  idCol.fieldSpec.content
    ..fieldName = 'orderId'
    ..dataType = 'UUID';
  final statusCol = list.elements.add();
  statusCol.content
    ..elementId = 'SCR-01-EL-3'
    ..elementName = 'Status column'
    ..elementType = 'StatusChip';
  statusCol.fieldSpec.content
    ..fieldName = 'status'
    ..dataType = 'Enum';

  final openAction = wl.actions.items.add();
  openAction.content
    ..actionId = 'SCR-01-ACT-1'
    ..actionName = 'Open order'
    ..actionType = 'Navigate';
  openAction.visual.content
    ..labelResource = 'screen.orders.action.open'
    ..placement = 'Row'
    ..buttonStyle = 'Primary';

  final emptyState = wl.states.items.add();
  emptyState.content
    ..stateName = 'Empty queue'
    ..description = 'No orders match the selected state filter.'
    ..messageResource = 'screen.orders.empty'
    ..primaryActionLabel = 'Clear filter'
    ..primaryActionTarget = 'SCR-01-EL-1';

  // SCR-02 Order Detail / Lifecycle Timeline.
  final detail = screens.add();
  detail.content
    ..screenId = 'SCR-02'
    ..screenName = 'Order Detail'
    ..purpose = 'The lifecycle timeline and inline actions for a single order.';
  detail.classification.content
    ..screenCategory = 'Detail'
    ..parentScreenId = 'SCR-01'
    ..routePattern = '/orders/:orderId';
  detail.access.content
    ..accessLevel = 'Authenticated'
    ..requiredRoles = 'Order Clerk, Order Supervisor'
    ..permissionEffect = 'Allow';
  detail.traceability.content
    ..relatedUseCases = 'UC-02, UC-03'
    ..relatedRequirements = 'FR-05, FR-06'
    ..dataEntities = 'Order, OrderLine'
    ..primaryAction = 'Amend line';
  detail.presentation.content
    ..pageTitleResource = 'screen.order.title'
    ..layout = 'Single column';

  final timeline = detail.sections.items.add();
  timeline.content
    ..sectionId = 'SCR-02-SEC-1'
    ..sectionName = 'Lifecycle timeline'
    ..purpose = 'Show every state transition with its authenticated actor.'
    ..sectionType = 'Timeline';
  timeline.layout.content
    ..layoutDirection = 'Vertical'
    ..displayOrder = '1';

  final lines = detail.sections.items.add();
  lines.content
    ..sectionId = 'SCR-02-SEC-2'
    ..sectionName = 'Order lines'
    ..purpose = 'Editable list of lines with price and reservation status.'
    ..sectionType = 'EditableTable';
  lines.layout.content
    ..layoutDirection = 'Vertical'
    ..displayOrder = '2';
  final qty = lines.elements.add();
  qty.content
    ..elementId = 'SCR-02-EL-1'
    ..elementName = 'Quantity field'
    ..elementType = 'NumberField';
  qty.fieldSpec.content
    ..fieldName = 'quantity'
    ..dataType = 'Integer';
  qty.behavior.content.readonlyCondition = 'order.status == "Dispatched"';

  final amend = detail.actions.items.add();
  amend.content
    ..actionId = 'SCR-02-ACT-1'
    ..actionName = 'Amend line'
    ..actionType = 'Submit';
  amend.visual.content
    ..labelResource = 'screen.order.action.amend'
    ..placement = 'Row'
    ..buttonStyle = 'Primary';
  final release = detail.actions.items.add();
  release.content
    ..actionId = 'SCR-02-ACT-2'
    ..actionName = 'Release hold'
    ..actionType = 'Submit';
  release.visual.content
    ..labelResource = 'screen.order.action.release'
    ..placement = 'Header'
    ..buttonStyle = 'Secondary';

  final errorState = detail.states.items.add();
  errorState.content
    ..stateName = 'Amendment rejected'
    ..description = 'The new quantity failed validation or reservation.'
    ..messageResource = 'screen.order.amend.error'
    ..primaryActionLabel = 'Retry'
    ..primaryActionTarget = 'SCR-02-ACT-1';
}
