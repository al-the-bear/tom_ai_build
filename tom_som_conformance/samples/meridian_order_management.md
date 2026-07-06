<!-- docspec: sbp/1 -->
# SBP — Solution Blueprint

Comprehensive specification document covering all aspects of the system from current landscape through target operating model, information model, solution architecture, security, experience design, quality & acceptance, and delivery / transition planning.
## SBP/content — content
```text
Solution Blueprint for the Meridian Order Management (MOM) programme. MOM replaces three ageing back-office systems with a single, event-driven order platform serving the wholesale and e-commerce channels of a mid-market distributor. This blueprint is the master specification from which the twelve Phase 3 documents (CLA, TOM, IFM, RSP, ISC, ATS, IIS, SAS, XDS, QAP, DRM, TRP) are derived.
```

## SBP/documentControl — documentControl

### SBP/documentControl/content — content
```text
Version 1.0, approved 2026-05-18. Authors: Solution Architecture chapter. Approvers: Programme Sponsor (VP Operations), Enterprise Architecture Board. Revision history is tracked in the programme wiki; this blueprint supersedes the 2025 "Order Platform Vision" one-pager.
```

## SBP/introductionAndScope — introductionAndScope

### SBP/introductionAndScope/content — content
```text
MOM covers order capture, validation, pricing, fulfilment orchestration, and post-sale amendments across the wholesale (EDI) and e-commerce (REST) channels. Out of scope: warehouse robotics control, general-ledger posting (delegated to the existing finance ERP via a published interface), and CRM lead management.
```

### SBP/introductionAndScope/goals — goals

#### SBP/introductionAndScope/goals/content — content
```text
Primary goals: (1) cut median order-to-confirmation time from 4.2 hours to under 5 minutes; (2) remove the nightly batch window entirely; (3) give operations staff a single screen for the full order lifecycle. Secondary goal: expose a stable public order API for third-party marketplace integrators. Three legacy systems are decommissioned: "OrderDesk" (green-screen order entry, 1998), "PriceCalc" (a spreadsheet-derived pricing service), and the nightly "BatchSync" file exchange with the warehouse.
```

## SBP/glossaryAndAbbreviations — glossaryAndAbbreviations

### SBP/glossaryAndAbbreviations/content — content
```description
MOM — Meridian Order Management. Line — a single product/quantity within an order. Hold — a state in which an order awaits manual review. Fulfilment window — the committed dispatch date range communicated to the customer. EDI — the wholesale electronic data interchange channel.
```

## SBP/stakeholdersAndGovernance — stakeholdersAndGovernance

### SBP/stakeholdersAndGovernance/content — content
```text
Sponsor: VP Operations. Product owner: Head of Order Operations. Key stakeholder groups: wholesale account managers, e-commerce merchandising, warehouse operations, finance, and the external marketplace partners. Governance runs through a fortnightly steering board; architectural decisions are recorded as ADRs owned by the Enterprise Architecture Board.
```

## SBP/currentLandscape — currentLandscape

### SBP/currentLandscape/content — content
```text
Today, order entry is manual and channel-specific. Wholesale orders arrive by EDI and are re-keyed into OrderDesk; e-commerce orders drop into a queue that a clerk clears twice a day. Pricing is recomputed nightly, so intraday price changes are invisible until the next morning. There is no single source of truth for order status — staff reconcile three systems by phone.
```

### SBP/currentLandscape/CUOPME-OPER-LST — operationalMetrics

#### SBP/currentLandscape/CUOPME-OPER-LST-1 — CurrentOperationalMetric

##### SBP/currentLandscape/CUOPME-OPER-LST-1/content — content
```text
Median order-to-confirmation time: 4.2 hours (wholesale), 9 hours (e-commerce).
```

#### SBP/currentLandscape/CUOPME-OPER-LST-2 — CurrentOperationalMetric

##### SBP/currentLandscape/CUOPME-OPER-LST-2/content — content
```text
Nightly batch window: 2h10m, during which no orders can be confirmed.
```

#### SBP/currentLandscape/CUOPME-OPER-LST-3 — CurrentOperationalMetric

##### SBP/currentLandscape/CUOPME-OPER-LST-3/content — content
```text
Manual price-override rate: 11% of wholesale lines, indicating pricing drift.
```

#### SBP/currentLandscape/CUOPME-OPER-LST-4 — CurrentOperationalMetric

##### SBP/currentLandscape/CUOPME-OPER-LST-4/content — content
```text
Order-status enquiry calls: ~340/week to the operations desk.
```

## SBP/assumptionsConstraintsDependencies — assumptionsConstraintsDependencies

### SBP/assumptionsConstraintsDependencies/content — content
```description
Assumes the finance ERP order-posting interface remains stable for the programme's duration. Constrained to the corporate AWS eu-central-1 landing zone and the approved managed-database catalogue. Depends on the warehouse team delivering the new dispatch-event webhook by the end of increment 2.
```

## SBP/targetOperatingModelConcept — targetOperatingModelConcept

### SBP/targetOperatingModelConcept/content — content
```text
Orders flow through a single event-driven pipeline: Captured -> Validated -> Priced -> Reserved -> Confirmed -> Fulfilled -> Closed, with an orthogonal Hold sub-state for manual review. Every transition emits a domain event; operations staff work from one queue view filtered by state. Pricing becomes a synchronous call, eliminating the batch window.
```

## SBP/informationAndDataModel — informationAndDataModel

### SBP/informationAndDataModel/content — content
```text
Core aggregates: Order (with Lines), Customer, Product, PriceList, and FulfilmentPlan. Orders reference Customers and Products by stable IDs; prices are snapshotted onto each Line at pricing time so historical orders remain reproducible. The event log is the system of record; read models are projections.
```

## SBP/requirements — requirements

### SBP/requirements/content — content
```description
Functional: capture orders from EDI and REST; validate against credit and stock; price synchronously; reserve stock; confirm within 5 minutes; support partial amendments and cancellations before dispatch. Non-functional: 99.9% capture-API availability; p95 confirmation latency < 30s; full audit trail; GDPR-compliant handling of customer data with a 7-year retention policy on order records.
```

## SBP/solutionArchitectureAndTechnology — solutionArchitectureAndTechnology

### SBP/solutionArchitectureAndTechnology/content — content
```text
Event-sourced order service (Dart/Flutter back office, Kotlin domain services) on Kubernetes, backed by PostgreSQL for read models and a managed Kafka cluster for the event backbone. The public order API is an API-gateway-fronted REST surface; EDI ingestion runs as an adapter that translates to the same command API. Infrastructure is provisioned as code.
```

## SBP/securityAndAccessModel — securityAndAccessModel

### SBP/securityAndAccessModel/content — content
```text
Access is role-based: Order Clerk, Order Supervisor (may release holds), Pricing Admin, and Integration (machine) accounts scoped to specific channels. All customer PII is encrypted at rest; the public API uses OAuth2 client credentials with per-partner rate limits. Every state transition is attributed to an authenticated principal in the audit log.
```

## SBP/experienceAndInterfaceDesign — experienceAndInterfaceDesign

### SBP/experienceAndInterfaceDesign/content — content
```text
The operations back office is a single-page application organised around the order queue. The primary screen is a state-filtered work list; selecting an order opens a lifecycle timeline with inline actions (release hold, amend line, cancel). Design priorities: keyboard-first navigation for high-volume clerks and an unambiguous status colour language shared with the public tracking page.
```

## SBP/qualityAndAcceptanceModel — qualityAndAcceptanceModel

### SBP/qualityAndAcceptanceModel/content — content
```text
Acceptance is gated on: a fully automated regression suite over the order lifecycle; a two-week parallel run against OrderDesk with < 0.1% reconciliation variance; and a load test sustaining 3x peak-hour order volume within the p95 latency budget. Business sign-off requires the operations desk to clear a full day's orders on MOM alone.
```

## SBP/deliveryTransitionAndRollout — deliveryTransitionAndRollout

### SBP/deliveryTransitionAndRollout/content — content
```text
Five increments: (1) order capture + event backbone; (2) synchronous pricing + warehouse webhook; (3) fulfilment orchestration + back office; (4) public API + marketplace onboarding; (5) legacy decommission. Transition is channel-by-channel (e-commerce first, then wholesale) with a parallel-run safety net and a documented rollback to OrderDesk until the parallel-run gate passes.
```

