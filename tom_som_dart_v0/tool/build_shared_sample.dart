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
