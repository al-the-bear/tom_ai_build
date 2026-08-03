<!-- docspec: solution-blueprint/1.0 -->
# <!--[SBP]--> Solution Blueprint

Solution Blueprint for the **Meridian Order Management (MOM)** programme.

MOM replaces three ageing back-office systems with a single, event-driven order
platform serving the wholesale and e-commerce channels of a mid-market
distributor. This blueprint is the master specification from which the twelve
Phase 3 documents (CLA, TOM, IFM, RSP, ISC, ATS, IIS, SAS, XDS, QAP, DRM, TRP)
are derived.

## <!--[DOCTL]--> Document Control

- Version: 1.0
- Status: Approved
- Approval date: 2026-05-18
- Authors: Solution Architecture chapter
- Approvers: Programme Sponsor (VP Operations), Enterprise Architecture Board

Revision history is tracked in the programme wiki. This blueprint supersedes
the 2025 "Order Platform Vision" one-pager.

## <!--[INSC]--> Introduction And Scope

MOM covers order capture, validation, pricing, fulfilment orchestration, and
post-sale amendments across the wholesale (EDI) and e-commerce (REST) channels.

Out of scope:

- warehouse robotics control
- general-ledger posting (delegated to the existing finance ERP via a
  published interface)
- CRM lead management

### <!--[SYDSC]--> System Description

#### <!--[UCE-USER-LST]--> User Categories

##### <!--[UCE-USER-1]--> User Category 1

CategoryName: Order Operations Clerk
Description: Back-office staff who clear the order work list, amend lines, and cancel orders before dispatch across the wholesale and e-commerce channels.
UserType: Internal

###### <!--[SYTS-SYST-LST]--> System Tasks

####### <!--[SYTS-SYST-1]--> System Task 1

TaskId: TSK-01
TaskName: Clear the order work list
Description: Work the state-filtered order queue from capture through to confirmation, handling holds and amendments as they arise.

######## <!--[SYTS-WORK-LST]--> Workflow Steps

######### <!--[SYTS-WORK-1]--> Workflow Steps 1

Open the work list filtered to the Captured and Hold states.

######### <!--[SYTS-WORK-2]--> Workflow Steps 2

Select an order and review its lifecycle timeline.

######### <!--[SYTS-WORK-3]--> Workflow Steps 3

Release holds, amend lines, or confirm as the order allows.

### <!--[GOALS]--> Project Goals

Primary goals:

1. Cut median order-to-confirmation time from 4.2 hours to under 5 minutes.
2. Remove the nightly batch window entirely.
3. Give operations staff a single screen for the full order lifecycle.

Secondary goal: expose a stable public order API for third-party marketplace
integrators.

Three legacy systems are decommissioned:

- "OrderDesk" — green-screen order entry, 1998
- "PriceCalc" — a spreadsheet-derived pricing service
- "BatchSync" — the nightly file exchange with the warehouse

### <!--[RO]--> Requirements

The requirements below are the contract MOM is built and accepted against.

IDs are stable and referenced from the use cases, screens, and data model so
every downstream artifact traces back to a requirement.

#### <!--[FR] codeSpec="CsFunctionalRequirements"--> Functional Requirements (FR)

##### <!--[FRE-REQU-LST]--> Requirements

###### <!--[FRE-REQU-ORDER-CAPTURE] codeSpec="CsOrder,CsOrder.captureFromEdi,CsOrderRepository"--> FR-01 — Capture orders from EDI and REST channels

Status: Approved

####### <!--[FRED]--> Details

Description: The system must accept orders from the wholesale EDI adapter and the public REST order API, translating both into a single internal order-capture command so downstream processing is channel-agnostic.
RequirementType: Functional
Category: Order Capture

####### <!--[FREP]--> Priority

Priority: Must
BusinessValue: High
Effort: M
RiskLevel: Medium

####### <!--[FRES]--> Source

Source: VP Operations
RequestDate: 2026-04-02
Rationale: Both channels must feed the same lifecycle to retire re-keying.

####### <!--[FREV]--> Verification

FitCriterion: An EDI and a REST order both produce an Order in state Captured within 2s.
CustomerSatisfaction: 5
CustomerDissatisfaction: 1

####### <!--[RAC]--> Acceptance Criteria

######## <!--[ACE-CRIT-LST]--> Criteria

######### <!--[ACE-CRIT-1]--> Acceptance Criterion 1

CriterionId: FR-01-AC-1
CriterionTitle: EDI order accepted
Given: a well-formed EDI 850 purchase order
When: the EDI adapter submits it to the capture API
Then: an Order is created in state Captured and a domain event is emitted
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

######### <!--[ACE-CRIT-2]--> Acceptance Criterion 2

CriterionId: FR-01-AC-2
CriterionTitle: REST order accepted
Given: a valid REST order payload from an authenticated partner
When: POST /orders is called
Then: an Order is created in state Captured with the same shape as EDI
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

###### <!--[FRE-REQU-SYNC-PRICING]--> FR-02 — Price orders synchronously at capture time

Status: Approved

####### <!--[FRED]--> Details

Description: Pricing must be computed synchronously during order processing and the resulting unit price snapshotted onto each order line, eliminating the nightly batch and making historical orders reproducible.
RequirementType: Functional
Category: Pricing

####### <!--[FREP]--> Priority

Priority: Must
BusinessValue: High
Effort: M
RiskLevel: Medium

####### <!--[FREV]--> Verification

FitCriterion: Each confirmed line carries a unitPrice snapshot equal to the price list at pricing time.

####### <!--[RAC]--> Acceptance Criteria

######## <!--[ACE-CRIT-LST]--> Criteria

######### <!--[ACE-CRIT-1]--> Acceptance Criterion 1

CriterionId: FR-02-AC-1
CriterionTitle: Price snapshotted onto line
Given: an order with two lines
When: the order is priced
Then: each line stores the resolved unit price as of the pricing timestamp
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

###### <!--[FRE-REQU-STOCK-RESERVATION]--> FR-03 — Reserve stock before confirmation

Status: Approved

####### <!--[FRED]--> Details

Description: Before an order is confirmed the system must reserve stock for every line; insufficient stock places the affected line on Hold rather than failing the whole order.
RequirementType: Functional
Category: Fulfilment

####### <!--[FREP]--> Priority

Priority: Must
BusinessValue: High
Effort: L
RiskLevel: High

####### <!--[RAC]--> Acceptance Criteria

######## <!--[ACE-CRIT-LST]--> Criteria

######### <!--[ACE-CRIT-1]--> Acceptance Criterion 1

CriterionId: FR-03-AC-1
CriterionTitle: Stock reserved when available
Given: an order whose lines all have sufficient stock on hand
When: the order is submitted for confirmation
Then: every line reserves its quantity and the order is eligible to confirm
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

######### <!--[ACE-CRIT-2]--> Acceptance Criterion 2

CriterionId: FR-03-AC-2
CriterionTitle: Short line placed on Hold
Given: an order with one line whose demand exceeds available stock
When: reservation runs before confirmation
Then: only the short line is placed on Hold while the remaining lines reserve normally
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

###### <!--[FRE-REQU-CONFIRM-SLA]--> FR-04 — Confirm orders within five minutes

Status: Approved

####### <!--[FRED]--> Details

Description: An order that passes validation, pricing, and reservation must reach state Confirmed within five minutes of capture, with the confirmation communicated on the operations work list and the public tracking page.
RequirementType: Functional
Category: Order Lifecycle

####### <!--[FREP]--> Priority

Priority: Must
BusinessValue: High
Effort: M
RiskLevel: Medium

####### <!--[RAC]--> Acceptance Criteria

######## <!--[ACE-CRIT-LST]--> Criteria

######### <!--[ACE-CRIT-1]--> Acceptance Criterion 1

CriterionId: FR-04-AC-1
CriterionTitle: Order confirmed within budget
Given: a captured order that passes validation, pricing, and reservation
When: the lifecycle processes it under normal load
Then: the order reaches state Confirmed within five minutes of capture
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

######### <!--[ACE-CRIT-2]--> Acceptance Criterion 2

CriterionId: FR-04-AC-2
CriterionTitle: Confirmation surfaced to operations and tracking
Given: an order that has just reached state Confirmed
When: the confirmation event is published
Then: the order appears as Confirmed on the operations work list and the public tracking page
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

###### <!--[FRE-REQU-AMEND-CANCEL]--> FR-05 — Amend or cancel an order before dispatch

Status: Approved

####### <!--[FRED]--> Details

Description: Until an order is dispatched, a clerk must be able to amend line quantities and cancel lines or the whole order; each amendment re-runs pricing and reservation for the affected lines and is fully audited.
RequirementType: Functional
Category: Order Amendment

####### <!--[FREP]--> Priority

Priority: Should
BusinessValue: Medium
Effort: M
RiskLevel: Medium

####### <!--[RAC]--> Acceptance Criteria

######## <!--[ACE-CRIT-LST]--> Criteria

######### <!--[ACE-CRIT-1]--> Acceptance Criterion 1

CriterionId: FR-05-AC-1
CriterionTitle: Amendment re-runs pricing and reservation
Given: a confirmed order that has not yet dispatched
When: a clerk changes a line quantity
Then: pricing and reservation re-run for the affected line and the change is written to the audit trail
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

######### <!--[ACE-CRIT-2]--> Acceptance Criterion 2

CriterionId: FR-05-AC-2
CriterionTitle: Cancellation blocked after dispatch
Given: an order that has already dispatched
When: a clerk attempts to cancel it
Then: the cancellation is rejected and the rejection is recorded in the audit trail
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

###### <!--[FRE-REQU-HOLD-RELEASE]--> FR-06 — Release a manual hold

Status: Approved

####### <!--[FRED]--> Details

Description: An Order Supervisor must be able to review an order on Hold and release it back into the lifecycle, recording a reason that is attached to the audit trail.
RequirementType: Functional
Category: Exception Handling

####### <!--[FREP]--> Priority

Priority: Must
BusinessValue: High
Effort: S
RiskLevel: Low

####### <!--[RAC]--> Acceptance Criteria

######## <!--[ACE-CRIT-LST]--> Criteria

######### <!--[ACE-CRIT-1]--> Acceptance Criterion 1

CriterionId: FR-06-AC-1
CriterionTitle: Supervisor releases hold
Given: an order in state Hold
When: a supervisor releases it with a reason
Then: the order resumes at the transition that placed it on Hold and the reason is audited
VerificationMethod: Automated test
TestType: Integration
Priority: Must
Status: Draft

#### <!--[TR1]--> Technical Requirements

##### <!--[TERQ-REQU-LST]--> Requirements

###### <!--[TERQ-REQU-1]--> Technical Requirement 1

RequirementId: TR-01
Title: Confirmation latency budget
Status: Approved

####### <!--[TRED]--> Details

Description: The 95th-percentile order-confirmation latency must stay within budget under peak load.
Category: Performance
Subcategory: Latency
Priority: Must
Source: Operations SLA
Rationale: Sub-30s p95 keeps the five-minute business promise safe under 3x peak.

####### <!--[TREM]--> Measurement

Metric: p95 capture-to-confirmation latency
CurrentValue: 4.2h (legacy)
TargetValue: < 30s
MeasurementMethod: Distributed tracing over the confirmation span
MeasurementEnvironment: Load test at 3x peak-hour volume
MeasurementFrequency: Per release + continuous in production

###### <!--[TERQ-REQU-2]--> Technical Requirement 2

RequirementId: TR-02
Title: Capture API availability
Status: Approved

####### <!--[TRED]--> Details

Description: The order-capture API must meet a 99.9% monthly availability target.
Category: Reliability
Subcategory: Availability
Priority: Must
Source: Partner integration agreement
Rationale: Marketplace partners depend on the capture API being continuously reachable.

####### <!--[TREM]--> Measurement

Metric: Monthly capture-API availability
TargetValue: >= 99.9%
MeasurementMethod: Synthetic probes + gateway success-rate metrics
MeasurementFrequency: Monthly

###### <!--[TERQ-REQU-3]--> Technical Requirement 3

RequirementId: TR-03
Title: Event-sourced order service
Status: Approved

####### <!--[TRED]--> Details

Description: The order service must be event-sourced: the append-only event log is the system of record and all read models are projections rebuildable from the log.
Category: Architecture
Subcategory: Persistence
Priority: Must
Source: Enterprise Architecture Board
Rationale: Reproducible history and rebuildable projections are core to auditability.

#### <!--[SR1]--> Security Requirements

##### <!--[SECRQ-REQU-LST]--> Requirements

###### <!--[SECRQ-REQU-1]--> Security Requirement 1

RequirementId: SR-01
Title: Role-based access control
Description: Access is governed by the roles Order Clerk, Order Supervisor, Pricing Admin, and Integration (machine) accounts scoped to specific channels; every state transition is attributed to an authenticated principal.

####### <!--[SEREENCL]--> Classification

Category: Access Control
Subcategory: Authorization
Priority: Must
Source: Security chapter
Rationale: Least privilege across human and machine actors.
ThreatMitigated: Unauthorized order manipulation
DataClassification: Internal

####### <!--[SEREENCO]--> Compliance

OwaspCategory: A01:2021 Broken Access Control
NistControl: AC-6
ComplianceReference: Corporate IAM policy v3

###### <!--[SECRQ-REQU-2]--> Security Requirement 2

RequirementId: SR-02
Title: Encrypt customer PII at rest
Description: All customer personally identifiable information must be encrypted at rest.

####### <!--[SEREENCL]--> Classification

Category: Data Protection
Subcategory: Encryption
Priority: Must
Source: Data Protection Officer
Rationale: GDPR obligations on customer records with a 7-year retention.
ThreatMitigated: PII disclosure from storage compromise
DataClassification: Confidential

####### <!--[SEREENCO]--> Compliance

NistControl: SC-28
ComplianceReference: GDPR Art. 32

###### <!--[SECRQ-REQU-3]--> Security Requirement 3

RequirementId: SR-03
Title: OAuth2 client credentials on the public API
Description: The public order API must authenticate partners with OAuth2 client-credentials tokens and enforce per-partner rate limits at the gateway.

####### <!--[SEREENCL]--> Classification

Category: API Security
Subcategory: Authentication
Priority: Must
Source: Security chapter
Rationale: Machine-to-machine partner access without shared secrets in code.
ThreatMitigated: Credential replay and partner impersonation
DataClassification: Internal

####### <!--[SEREENCO]--> Compliance

OwaspCategory: API2:2023 Broken Authentication
NistControl: IA-5

#### <!--[OR]--> Organizational Requirements

##### <!--[ORRQ-REQU-LST]--> Requirements

###### <!--[ORRQ-REQU-1]--> Organizational Requirement 1

RequirementId: OR-01
Title: Train the operations desk on MOM
Description: Before cutover the order-operations desk must be trained to run the full order lifecycle on MOM alone, including hold release and amendments.

####### <!--[OREI]--> Impact

ImpactedGroups: Order Operations desk
ImpactedUserCount: 25
ChangeType: Process + tooling
ChangeComplexity: Medium
Resistance: Low

###### <!--[ORRQ-REQU-2]--> Organizational Requirement 2

RequirementId: OR-02
Title: Staff the parallel run
Description: The two-week parallel run against OrderDesk requires staffing to reconcile both systems daily until the < 0.1% variance gate passes.

####### <!--[OREI]--> Impact

ImpactedGroups: Order Operations, Finance
ImpactedUserCount: 30
ChangeType: Temporary dual-running
ChangeComplexity: Medium
Resistance: Medium

## <!--[GLAB]--> Glossary And Abbreviations

- **MOM** — Meridian Order Management.
- **Line** — a single product/quantity within an order.
- **Hold** — a state in which an order awaits manual review.
- **Fulfilment window** — the committed dispatch date range communicated to
  the customer.
- **EDI** — the wholesale electronic data interchange channel.

## <!--[STKG]--> Stakeholders And Governance

- Sponsor: VP Operations
- Product owner: Head of Order Operations
- Key stakeholder groups: wholesale account managers, e-commerce
  merchandising, warehouse operations, finance, and the external marketplace
  partners

Governance runs through a fortnightly steering board; architectural decisions
are recorded as ADRs owned by the Enterprise Architecture Board.

## <!--[CULA]--> Current Landscape

Today, order entry is manual and channel-specific. Wholesale orders arrive by
EDI and are re-keyed into OrderDesk; e-commerce orders drop into a queue that a
clerk clears twice a day.

Pricing is recomputed nightly, so intraday price changes are invisible until
the next morning. There is no single source of truth for order status — staff
reconcile three systems by phone.

### <!--[CUOPME-OPER-LST]--> Operational Metrics

#### <!--[CUOPME-OPER-1]--> Current Operational Metric 1

Median order-to-confirmation time: 4.2 hours (wholesale), 9 hours (e-commerce).

#### <!--[CUOPME-OPER-2]--> Current Operational Metric 2

Nightly batch window: 2h10m, during which no orders can be confirmed.

#### <!--[CUOPME-OPER-3]--> Current Operational Metric 3

Manual price-override rate: 11% of wholesale lines, indicating pricing drift.

#### <!--[CUOPME-OPER-4]--> Current Operational Metric 4

Order-status enquiry calls: ~340/week to the operations desk.

## <!--[ACDP]--> Assumptions Constraints Dependencies

- **Assumption** — the finance ERP order-posting interface remains stable for
  the programme's duration.
- **Constraint** — the platform runs in the corporate AWS eu-central-1 landing
  zone and uses only the approved managed-database catalogue.
- **Dependency** — the warehouse team delivers the new dispatch-event webhook
  by the end of increment 2.

## <!--[TOMC]--> Target Operating Model Concept

Orders flow through a single event-driven pipeline:

Captured -> Validated -> Priced -> Reserved -> Confirmed -> Fulfilled -> Closed

An orthogonal Hold sub-state covers manual review. Every transition emits a
domain event; operations staff work from one queue view filtered by state.
Pricing becomes a synchronous call, eliminating the batch window.

### <!--[PSAAI]--> Process Steps And Actor Interactions

#### <!--[ACOV]--> Actor Overview

##### <!--[ACOVNA]--> Overview

TotalActorCount: 4
HumanActorCount: 3
SystemActorCount: 1
ExternalActorCount: 0

##### <!--[ACEN-ACTO-LST]--> Actors

###### <!--[ACEN-ACTO-1]--> Actor 1

####### <!--[ACID]--> Identification

ActorId: ACT-01
ActorName: Order Clerk
ActorType: Human
Category: Primary
Description: Clears the order work list, amends lines, and cancels orders before dispatch.
OrganizationalUnit: Order Operations
EstimatedCount: 25
GeographicDistribution: Single distribution centre

###### <!--[ACEN-ACTO-2]--> Actor 2

####### <!--[ACID]--> Identification

ActorId: ACT-02
ActorName: Order Supervisor
ActorType: Human
Category: Primary
Description: Reviews orders on Hold and releases them back into the lifecycle.
OrganizationalUnit: Order Operations
EstimatedCount: 4
GeographicDistribution: Single distribution centre

###### <!--[ACEN-ACTO-3]--> Actor 3

####### <!--[ACID]--> Identification

ActorId: ACT-03
ActorName: Pricing Admin
ActorType: Human
Category: Supporting
Description: Maintains the price lists that the synchronous pricing step consumes.
OrganizationalUnit: Commercial
EstimatedCount: 3
GeographicDistribution: Single distribution centre

###### <!--[ACEN-ACTO-4]--> Actor 4

####### <!--[ACID]--> Identification

ActorId: ACT-04
ActorName: EDI Integration Account
ActorType: System
Category: Primary
Description: Machine account through which the wholesale EDI adapter submits orders.
OrganizationalUnit: Integration
EstimatedCount: 1
GeographicDistribution: Single distribution centre

#### <!--[INCA]--> Interaction Catalog

##### <!--[INEN-INTE-LST]--> Interactions

###### <!--[INEN-INTE-1]--> Interaction 1

####### <!--[INID]--> Identification

InteractionId: UC-01
UseCaseName: Capture Wholesale Order (EDI)
ProcessReference: BP-Order-Capture
BriefDescription: A wholesale EDI purchase order is captured, validated, priced, reserved, and confirmed.
FullDescription: The EDI adapter submits a translated purchase order to the capture command API. The system validates the customer and lines, prices each line synchronously, reserves stock, and confirms the order — emitting a domain event at every transition so the work list and public tracking page stay current.
PrimaryActor: ACT-04 EDI Integration Account
SupportingActors: ACT-01 Order Clerk
GoalLevel: User goal
DesignScope: System

####### <!--[PRANTR-PREC-LST]--> Preconditions

######## <!--[PRANTR-PREC-1]--> Preconditions And Triggers 1

Precondition: The submitting Integration account is authenticated and scoped to the wholesale channel.
Trigger: An EDI 850 purchase order arrives at the wholesale adapter.
TriggerType: External
TriggerSource: EDI gateway
TriggerData: EDI 850 document

####### <!--[POANGU-POST-LST]--> Postconditions

######## <!--[POANGU-POST-1]--> Postconditions And Guarantees 1

MinimalGuarantees: Either an Order exists in a well-defined state or the submission is rejected with a reason; no partial order is persisted.
SuccessGuarantees: The Order is in state Confirmed with priced, reserved lines and a full event history.
DataPostcondition: Order and OrderLine rows persisted; reservation recorded against Product stock.

####### <!--[MASUSC]--> Main Scenario

######## <!--[MNSST-STEP-LST]--> Steps

######### <!--[MNSST-STEP-1]--> Main Scenario Step 1

StepNumber: 1
ActorAction: EDI adapter submits the translated order to the capture API.
SystemResponse: System creates the Order in state Captured and emits OrderCaptured.
DataInvolved: Order, OrderLine
UiElementUsed: —

######### <!--[MNSST-STEP-2]--> Main Scenario Step 2

StepNumber: 2
ActorAction: System validates customer credit and line stock references.
SystemResponse: Order moves to Validated; invalid references are flagged per line.
DataInvolved: Customer, Product
BusinessRuleApplied: Credit limit not exceeded

######### <!--[MNSST-STEP-3]--> Main Scenario Step 3

StepNumber: 3
ActorAction: System prices each line against the active price list.
SystemResponse: Unit price is snapshotted onto each line; Order moves to Priced.
DataInvolved: PriceList, OrderLine
BusinessRuleApplied: FR-02 price snapshot

######### <!--[MNSST-STEP-4]--> Main Scenario Step 4

StepNumber: 4
ActorAction: System reserves stock for every line.
SystemResponse: Reservations recorded; Order moves to Reserved.
DataInvolved: Product
BusinessRuleApplied: FR-03 reserve before confirm

######### <!--[MNSST-STEP-5]--> Main Scenario Step 5

StepNumber: 5
ActorAction: System confirms the order.
SystemResponse: Order moves to Confirmed within five minutes and appears on the work list.
DataInvolved: Order
BusinessRuleApplied: FR-04 five-minute confirmation

####### <!--[USCAEX]--> Extensions

######## <!--[EXTEN-EXTE-LST]--> Extensions

######### <!--[EXTEN-EXTE-1]--> Extension 1

ExtensionId: 2a
BranchPoint: Step 2
Condition: Customer credit limit would be exceeded
ExtensionType: Exception
Description: Validation detects the order exceeds the customer credit limit.
Outcome: Order is placed on Hold for supervisor review (see UC-02).
ReturnPoint: Step 3 after release
Severity: High

########## <!--[EXTST-STEP-LST]--> Steps

########### <!--[EXTST-STEP-1]--> Extension Step 1

StepNumber: 2a.1
Action: System places the Order on Hold and emits OrderHeld.
Response: Order appears in the Hold filter of the work list with reason "Credit exceeded".

######### <!--[EXTEN-EXTE-2]--> Extension 2

ExtensionId: 4a
BranchPoint: Step 4
Condition: Insufficient stock for one or more lines
ExtensionType: Exception
Description: Reservation cannot be fully satisfied for a line.
Outcome: The affected line is placed on Hold; other lines proceed.
ReturnPoint: Step 5 for satisfiable lines
Severity: Medium

########## <!--[EXTST-STEP-LST]--> Steps

########### <!--[EXTST-STEP-1]--> Extension Step 1

StepNumber: 4a.1
Action: System holds the unsatisfiable line and reserves the rest.
Response: The order is partially reserved; the held line is flagged for follow-up.

###### <!--[INEN-INTE-2]--> Interaction 2

####### <!--[INID]--> Identification

InteractionId: UC-02
UseCaseName: Release Order Hold
ProcessReference: BP-Order-Exception
BriefDescription: A supervisor reviews an order on Hold and releases it back into the lifecycle.
FullDescription: A supervisor opens an order on Hold from the work list, reviews the hold reason, and either releases it — resuming the lifecycle at the transition that placed it on Hold — or cancels it, recording a reason in both cases.
PrimaryActor: ACT-02 Order Supervisor
GoalLevel: User goal
DesignScope: System

####### <!--[PRANTR-PREC-LST]--> Preconditions

######## <!--[PRANTR-PREC-1]--> Preconditions And Triggers 1

Precondition: An order exists in state Hold and the actor holds the Order Supervisor role.
Trigger: Supervisor selects a held order from the work list.
TriggerType: User
TriggerSource: Order Work List screen

####### <!--[POANGU-POST-LST]--> Postconditions

######## <!--[POANGU-POST-1]--> Postconditions And Guarantees 1

SuccessGuarantees: The order resumes at the transition that placed it on Hold, with the release reason audited.
AuditTrail: Release attributed to the supervisor principal with timestamp and reason.

####### <!--[MASUSC]--> Main Scenario

######## <!--[MNSST-STEP-LST]--> Steps

######### <!--[MNSST-STEP-1]--> Main Scenario Step 1

StepNumber: 1
ActorAction: Supervisor opens the held order and reviews the reason.
SystemResponse: System shows the lifecycle timeline and the hold reason.
DataInvolved: Order
UiElementUsed: Order Detail timeline

######### <!--[MNSST-STEP-2]--> Main Scenario Step 2

StepNumber: 2
ActorAction: Supervisor releases the order with a reason.
SystemResponse: System resumes the lifecycle and emits OrderHoldReleased.
DataInvolved: Order
BusinessRuleApplied: FR-06 hold release

###### <!--[INEN-INTE-3]--> Interaction 3

####### <!--[INID]--> Identification

InteractionId: UC-03
UseCaseName: Amend Order Line Before Dispatch
ProcessReference: BP-Order-Amendment
BriefDescription: A clerk changes a line quantity before dispatch, re-running pricing and reservation.
FullDescription: A clerk edits the quantity of a line on a not-yet-dispatched order. The system re-prices and re-reserves only the affected line and records the amendment on the audit trail.
PrimaryActor: ACT-01 Order Clerk
GoalLevel: User goal
DesignScope: System

####### <!--[PRANTR-PREC-LST]--> Preconditions

######## <!--[PRANTR-PREC-1]--> Preconditions And Triggers 1

Precondition: The order is not yet dispatched and the actor holds the Order Clerk role.
Trigger: Clerk edits a line quantity on the Order Detail screen.
TriggerType: User
TriggerSource: Order Detail screen

####### <!--[POANGU-POST-LST]--> Postconditions

######## <!--[POANGU-POST-1]--> Postconditions And Guarantees 1

SuccessGuarantees: The amended line carries a fresh price snapshot and reservation; the amendment is audited.
DataPostcondition: OrderLine updated; prior values retained in the event history.

####### <!--[MASUSC]--> Main Scenario

######## <!--[MNSST-STEP-LST]--> Steps

######### <!--[MNSST-STEP-1]--> Main Scenario Step 1

StepNumber: 1
ActorAction: Clerk changes the quantity of a line and saves.
SystemResponse: System validates the new quantity and re-prices the line.
DataInvolved: OrderLine, PriceList
BusinessRuleApplied: FR-05 amend before dispatch

######### <!--[MNSST-STEP-2]--> Main Scenario Step 2

StepNumber: 2
ActorAction: System re-reserves stock for the amended line.
SystemResponse: Reservation is adjusted; the order returns to Confirmed if fully satisfied.
DataInvolved: Product
BusinessRuleApplied: FR-03 reserve before confirm

#### <!--[KESC]--> Key Scenarios

##### <!--[SCNRY-SCEN-LST]--> Scenarios

###### <!--[SCNRY-SCEN-1]--> Scenario 1

####### <!--[SCID]--> Identification

ScenarioId: SCN-01
ScenarioName: Happy-path wholesale order, capture to fulfilment
ScenarioType: End-to-end
Description: A clean wholesale order flows from EDI capture through to fulfilment with no holds.
BusinessGoal: Confirm and fulfil a wholesale order without manual intervention.
PrimaryActor: ACT-04 EDI Integration Account
SupportingActors: ACT-01 Order Clerk
Priority: High
Complexity: Medium

####### <!--[SCNST-STEP-LST]--> Steps

######## <!--[SCNST-STEP-1]--> Scenario Step 1

StepNumber: 1
Actor: ACT-04 EDI Integration Account
Action: Submits a two-line wholesale order.
SystemResponse: Order captured, validated, priced, reserved, and confirmed within five minutes.

######## <!--[SCNST-STEP-2]--> Scenario Step 2

StepNumber: 2
Actor: ACT-01 Order Clerk
Action: Observes the confirmed order on the work list.
SystemResponse: Order shows state Confirmed with both lines priced and reserved.

######## <!--[SCNST-STEP-3]--> Scenario Step 3

StepNumber: 3
Actor: System
Action: Receives the warehouse dispatch webhook.
SystemResponse: Order moves to Fulfilled and the public tracking page updates.

## <!--[INDM]--> Information And Data Model

Core aggregates: Order (with Lines), Customer, Product, PriceList, and
FulfilmentPlan.

Orders reference Customers and Products by stable IDs; prices are snapshotted
onto each Line at pricing time so historical orders remain reproducible. The
event log is the system of record; read models are projections.

### <!--[DATMD]--> Data Model

The relational core of MOM.

Order is the aggregate root; each Order owns its OrderLines and references a
Customer and, per line, a Product. Prices are snapshotted onto lines so
historical orders remain reproducible.

#### <!--[DAENT-ENTI-LST]--> Entities

##### <!--[DAENT-ENTI-1]--> Data Entity 1

###### <!--[DAENT-IDEN]--> Identity

EntityName: Order
TableName: mom_order
EntityAlias: ORD
Description: A customer order captured from EDI or REST and driven through the lifecycle. Realizes FR-01, FR-04, FR-05, FR-06.
EntityStereoType: Aggregate Root

###### <!--[DAENT-CLAS]--> Classification

Category: Transactional
BoundedContext: Ordering
OwningDomain: Order Management
DataOwner: Head of Order Operations
SourceSystem: MOM

###### <!--[DAATT-ATTR-LST]--> Attributes

####### <!--[DAATT-ATTR-1]--> Data Attribute 1

######## <!--[DAATT-IDEN]--> Identity

AttributeName: orderId
ColumnName: order_id
Description: Stable order identifier.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-2]--> Data Attribute 2

######## <!--[DAATT-IDEN]--> Identity

AttributeName: customerId
ColumnName: customer_id
Description: Reference to the ordering customer.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-3]--> Data Attribute 3

######## <!--[DAATT-IDEN]--> Identity

AttributeName: channel
ColumnName: channel
Description: Capture channel: EDI or REST.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: enumeration
PhysicalType: varchar(8)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-4]--> Data Attribute 4

######## <!--[DAATT-IDEN]--> Identity

AttributeName: status
ColumnName: status
Description: Lifecycle state (Captured..Closed, with Hold).

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: enumeration
PhysicalType: varchar(16)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-5]--> Data Attribute 5

######## <!--[DAATT-IDEN]--> Identity

AttributeName: createdAt
ColumnName: created_at
Description: Capture timestamp (UTC).

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: dateTime
PhysicalType: timestamptz

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

###### <!--[KEATT-KEYA-LST]--> Key Attributes

####### <!--[KEATT-KEYA-1]--> Key Attribute 1

KeyName: pk_order
KeyType: Primary
KeyColumns: order_id
Description: Primary key of the order.

##### <!--[DAENT-ENTI-2]--> Data Entity 2

###### <!--[DAENT-IDEN]--> Identity

EntityName: OrderLine
TableName: mom_order_line
EntityAlias: OLN
Description: A single product/quantity within an order, with a snapshotted price. Realizes FR-02, FR-03, FR-05.
EntityStereoType: Entity

###### <!--[DAENT-CLAS]--> Classification

Category: Transactional
BoundedContext: Ordering
OwningDomain: Order Management
DataOwner: Head of Order Operations
SourceSystem: MOM

###### <!--[DAATT-ATTR-LST]--> Attributes

####### <!--[DAATT-ATTR-1]--> Data Attribute 1

######## <!--[DAATT-IDEN]--> Identity

AttributeName: lineId
ColumnName: line_id
Description: Stable line identifier.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-2]--> Data Attribute 2

######## <!--[DAATT-IDEN]--> Identity

AttributeName: orderId
ColumnName: order_id
Description: Owning order reference.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-3]--> Data Attribute 3

######## <!--[DAATT-IDEN]--> Identity

AttributeName: productId
ColumnName: product_id
Description: Referenced product.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-4]--> Data Attribute 4

######## <!--[DAATT-IDEN]--> Identity

AttributeName: quantity
ColumnName: quantity
Description: Ordered quantity.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: integer
PhysicalType: int

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-5]--> Data Attribute 5

######## <!--[DAATT-IDEN]--> Identity

AttributeName: unitPrice
ColumnName: unit_price
Description: Snapshotted unit price at pricing time.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: decimal
PhysicalType: numeric(12,2)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

###### <!--[KEATT-KEYA-LST]--> Key Attributes

####### <!--[KEATT-KEYA-1]--> Key Attribute 1

KeyName: pk_order_line
KeyType: Primary
KeyColumns: line_id
Description: Primary key of the order line.

####### <!--[KEATT-KEYA-2]--> Key Attribute 2

KeyName: fk_line_order
KeyType: Foreign
KeyColumns: order_id
Description: References the owning order.

######## <!--[KEATT-REFE-REF]--> Referenced Entity Ref

Order

##### <!--[DAENT-ENTI-3]--> Data Entity 3

###### <!--[DAENT-IDEN]--> Identity

EntityName: Customer
TableName: mom_customer
EntityAlias: CUS
Description: A wholesale or e-commerce customer that places orders. Realizes FR-01.
EntityStereoType: Aggregate Root

###### <!--[DAENT-CLAS]--> Classification

Category: Master
BoundedContext: Customer
OwningDomain: Customer Management
DataOwner: Commercial
SourceSystem: MOM

###### <!--[DAATT-ATTR-LST]--> Attributes

####### <!--[DAATT-ATTR-1]--> Data Attribute 1

######## <!--[DAATT-IDEN]--> Identity

AttributeName: customerId
ColumnName: customer_id
Description: Stable customer identifier.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-2]--> Data Attribute 2

######## <!--[DAATT-IDEN]--> Identity

AttributeName: name
ColumnName: name
Description: Customer legal name (PII).

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: string
PhysicalType: varchar(200)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Confidential
IsPii: true

####### <!--[DAATT-ATTR-3]--> Data Attribute 3

######## <!--[DAATT-IDEN]--> Identity

AttributeName: creditLimit
ColumnName: credit_limit
Description: Approved credit limit used by validation.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: decimal
PhysicalType: numeric(14,2)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Confidential
IsPii: false

###### <!--[KEATT-KEYA-LST]--> Key Attributes

####### <!--[KEATT-KEYA-1]--> Key Attribute 1

KeyName: pk_customer
KeyType: Primary
KeyColumns: customer_id
Description: Primary key of the customer.

##### <!--[DAENT-ENTI-4]--> Data Entity 4

###### <!--[DAENT-IDEN]--> Identity

EntityName: Product
TableName: mom_product
EntityAlias: PRD
Description: A sellable product referenced by order lines and priced by the price list. Realizes FR-02, FR-03.
EntityStereoType: Aggregate Root

###### <!--[DAENT-CLAS]--> Classification

Category: Master
BoundedContext: Catalogue
OwningDomain: Merchandising
DataOwner: Merchandising
SourceSystem: MOM

###### <!--[DAATT-ATTR-LST]--> Attributes

####### <!--[DAATT-ATTR-1]--> Data Attribute 1

######## <!--[DAATT-IDEN]--> Identity

AttributeName: productId
ColumnName: product_id
Description: Stable product identifier.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: uuid
PhysicalType: uuid

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-2]--> Data Attribute 2

######## <!--[DAATT-IDEN]--> Identity

AttributeName: sku
ColumnName: sku
Description: Stock-keeping unit.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: string
PhysicalType: varchar(40)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

####### <!--[DAATT-ATTR-3]--> Data Attribute 3

######## <!--[DAATT-IDEN]--> Identity

AttributeName: name
ColumnName: name
Description: Product display name.

######## <!--[DAATT-DATA]--> Data Type Spec

DataType: string
PhysicalType: varchar(200)

######## <!--[DAATT-SECU]--> Security Classification

SensitivityLevel: Internal
IsPii: false

###### <!--[KEATT-KEYA-LST]--> Key Attributes

####### <!--[KEATT-KEYA-1]--> Key Attribute 1

KeyName: pk_product
KeyType: Primary
KeyColumns: product_id
Description: Primary key of the product.

#### <!--[ENREL]--> Entity Relationships

The foreign-key relationships binding the ordering core together.

##### <!--[ENRLE-ITEM-LST]--> Items

###### <!--[ENRLE-ITEM-1]--> Entity Relationship 1

####### <!--[ENRLE-IDEN]--> Identity

RelationshipName: Order-owns-Lines
RelationshipType: Composition
Description: An order owns one or more order lines.
BusinessJustification: Maintains referential integrity across the ordering core.
ImplementationType: Foreign Key

####### <!--[ENRLE-CARD]--> Cardinality

SourceCardinality: 1
TargetCardinality: 1..*

####### <!--[ENRLE-NAVI]--> Navigation

Navigability: Bidirectional
ForeignKeyLocation: mom_order_line.order_id

####### <!--[ENRLE-SOUR-REF]--> Source Entity Ref

Order

####### <!--[ENRLE-TARG-REF]--> Target Entity Ref

OrderLine

###### <!--[ENRLE-ITEM-2]--> Entity Relationship 2

####### <!--[ENRLE-IDEN]--> Identity

RelationshipName: Order-placed-by-Customer
RelationshipType: Association
Description: Each order is placed by exactly one customer.
BusinessJustification: Maintains referential integrity across the ordering core.
ImplementationType: Foreign Key

####### <!--[ENRLE-CARD]--> Cardinality

SourceCardinality: *
TargetCardinality: 1

####### <!--[ENRLE-NAVI]--> Navigation

Navigability: Bidirectional
ForeignKeyLocation: mom_order.customer_id

####### <!--[ENRLE-SOUR-REF]--> Source Entity Ref

Order

####### <!--[ENRLE-TARG-REF]--> Target Entity Ref

Customer

###### <!--[ENRLE-ITEM-3]--> Entity Relationship 3

####### <!--[ENRLE-IDEN]--> Identity

RelationshipName: Line-references-Product
RelationshipType: Association
Description: Each order line references exactly one product.
BusinessJustification: Maintains referential integrity across the ordering core.
ImplementationType: Foreign Key

####### <!--[ENRLE-CARD]--> Cardinality

SourceCardinality: *
TargetCardinality: 1

####### <!--[ENRLE-NAVI]--> Navigation

Navigability: Bidirectional
ForeignKeyLocation: mom_order_line.product_id

####### <!--[ENRLE-SOUR-REF]--> Source Entity Ref

OrderLine

####### <!--[ENRLE-TARG-REF]--> Target Entity Ref

Product

## <!--[REQS]--> Requirements

Functional:

- capture orders from EDI and REST
- validate against credit and stock
- price synchronously and reserve stock
- confirm within 5 minutes
- support partial amendments and cancellations before dispatch

Non-functional:

- 99.9% capture-API availability
- p95 confirmation latency < 30s
- full audit trail
- GDPR-compliant handling of customer data with a 7-year retention policy on
  order records

## <!--[SOAT]--> Solution Architecture And Technology

Event-sourced order service (Dart/Flutter back office, Kotlin domain services)
on Kubernetes, backed by PostgreSQL for read models and a managed Kafka cluster
for the event backbone.

The public order API is an API-gateway-fronted REST surface; EDI ingestion runs
as an adapter that translates to the same command API. Infrastructure is
provisioned as code.

## <!--[SAAM]--> Security And Access Model

Access is role-based:

- Order Clerk
- Order Supervisor (may release holds)
- Pricing Admin
- Integration (machine) accounts scoped to specific channels

All customer PII is encrypted at rest; the public API uses OAuth2 client
credentials with per-partner rate limits. Every state transition is attributed
to an authenticated principal in the audit log.

## <!--[XID]--> Experience And Interface Design

The operations back office is a single-page application organised around the
order queue. The primary screen is a state-filtered work list; selecting an
order opens a lifecycle timeline with inline actions (release hold, amend line,
cancel).

Design priorities:

- keyboard-first navigation for high-volume clerks
- an unambiguous status colour language shared with the public tracking page

### <!--[XCS]--> Experience Code Specs

#### <!--[SCRDZ]--> Screens

##### <!--[SCRINV]--> Screen Inventory

###### <!--[SCREN-ITEM-LST]--> Items

####### <!--[SCREN-ITEM-1]--> Screen 1

ScreenId: SCR-01
ScreenName: Order Work List
Purpose: The single, state-filtered queue from which clerks work every order.

######## <!--[SCECL]--> Classification

ScreenCategory: List
RoutePattern: /orders

######## <!--[AZREQ]--> Access

RequirementKind: role
Rationale: The work list exposes every open order, so it is limited to the two roles that work the queue.

######### <!--[AZREQ-ROLE]--> Role Requirement

Roles: Order Clerk, Order Supervisor

######## <!--[SCETR]--> Traceability

RelatedUseCases: UC-01, UC-02
RelatedRequirements: FR-01, FR-04, FR-06
DataEntities: Order
PrimaryAction: Open selected order

######## <!--[SCENPR]--> Presentation

PageTitleResource: screen.orders.title
Layout: Master-detail

######## <!--[SCSE]--> Sections

######### <!--[SCRSC-ITEM-LST]--> Items

########## <!--[SCRSC-ITEM-1]--> Screen Section 1

SectionId: SCR-01-SEC-1
SectionName: State filter bar
Purpose: Filter the queue by lifecycle state.
SectionType: Toolbar

########### <!--[SSEL]--> Layout

LayoutDirection: Horizontal
DisplayOrder: 1

########### <!--[SCREL-ELEM-LST]--> Elements

############ <!--[SCREL-ELEM-1]--> Screen Element 1

ElementId: SCR-01-EL-1
ElementName: State selector
ElementType: selectField

############# <!--[SEER]--> Resources

LabelResource: screen.orders.filter.state
HintResource: screen.orders.filter.state.hint

########## <!--[SCRSC-ITEM-2]--> Screen Section 2

SectionId: SCR-01-SEC-2
SectionName: Order table
Purpose: The work list itself, keyboard-navigable for high-volume clerks.
SectionType: DataTable

########### <!--[SSEL]--> Layout

LayoutDirection: Vertical
DisplayOrder: 2

########### <!--[SCREL-ELEM-LST]--> Elements

############ <!--[SCREL-ELEM-1]--> Screen Element 1

ElementId: SCR-01-EL-2
ElementName: Order ID column
ElementType: textField

############# <!--[SEFS]--> Field Spec

FieldName: orderId
DataType: string

############ <!--[SCREL-ELEM-2]--> Screen Element 2

ElementId: SCR-01-EL-3
ElementName: Status column
ElementType: statusIndicator

############# <!--[SEFS]--> Field Spec

FieldName: status
DataType: enumeration

######## <!--[SCAC]--> Actions

######### <!--[SCRAC-ITEM-LST]--> Items

########## <!--[SCRAC-ITEM-1]--> Screen Action 1

ActionId: SCR-01-ACT-1
ActionName: Open order
ActionType: Navigate

########### <!--[SAEV]--> Visual

LabelResource: screen.orders.action.open
Placement: Row
ButtonStyle: Primary

######## <!--[SCST]--> States

######### <!--[SCRST-ITEM-LST]--> Items

########## <!--[SCRST-ITEM-1]--> Screen State 1

StateName: Empty queue
Description: No orders match the selected state filter.
MessageResource: screen.orders.empty
PrimaryActionLabel: Clear filter
PrimaryActionTarget: SCR-01-EL-1

####### <!--[SCREN-ITEM-2]--> Screen 2

ScreenId: SCR-02
ScreenName: Order Detail
Purpose: The lifecycle timeline and inline actions for a single order.

######## <!--[SCECL]--> Classification

ScreenCategory: Detail
ParentScreenId: SCR-01
RoutePattern: /orders/:orderId

######## <!--[AZREQ]--> Access

RequirementKind: role
Rationale: Order detail carries the amendment actions, so it is held to the same two roles as the work list it is reached from.

######### <!--[AZREQ-ROLE]--> Role Requirement

Roles: Order Clerk, Order Supervisor

######## <!--[SCETR]--> Traceability

RelatedUseCases: UC-02, UC-03
RelatedRequirements: FR-05, FR-06
DataEntities: Order, OrderLine
PrimaryAction: Amend line

######## <!--[SCENPR]--> Presentation

PageTitleResource: screen.order.title
Layout: Single column

######## <!--[SCSE]--> Sections

######### <!--[SCRSC-ITEM-LST]--> Items

########## <!--[SCRSC-ITEM-1]--> Screen Section 1

SectionId: SCR-02-SEC-1
SectionName: Lifecycle timeline
Purpose: Show every state transition with its authenticated actor.
SectionType: Timeline

########### <!--[SSEL]--> Layout

LayoutDirection: Vertical
DisplayOrder: 1

########## <!--[SCRSC-ITEM-2]--> Screen Section 2

SectionId: SCR-02-SEC-2
SectionName: Order lines
Purpose: Editable list of lines with price and reservation status.
SectionType: EditableTable

########### <!--[SSEL]--> Layout

LayoutDirection: Vertical
DisplayOrder: 2

########### <!--[SCREL-ELEM-LST]--> Elements

############ <!--[SCREL-ELEM-1]--> Screen Element 1

ElementId: SCR-02-EL-1
ElementName: Quantity field
ElementType: numberField

############# <!--[SEEB]--> Behavior

ReadonlyCondition: order.status == "Dispatched"

############# <!--[SEFS]--> Field Spec

FieldName: quantity
DataType: integer

######## <!--[SCAC]--> Actions

######### <!--[SCRAC-ITEM-LST]--> Items

########## <!--[SCRAC-ITEM-1]--> Screen Action 1

ActionId: SCR-02-ACT-1
ActionName: Amend line
ActionType: Submit

########### <!--[SAEV]--> Visual

LabelResource: screen.order.action.amend
Placement: Row
ButtonStyle: Primary

########## <!--[SCRAC-ITEM-2]--> Screen Action 2

ActionId: SCR-02-ACT-2
ActionName: Release hold
ActionType: Submit

########### <!--[SAEV]--> Visual

LabelResource: screen.order.action.release
Placement: Header
ButtonStyle: Secondary

######## <!--[SCST]--> States

######### <!--[SCRST-ITEM-LST]--> Items

########## <!--[SCRST-ITEM-1]--> Screen State 1

StateName: Amendment rejected
Description: The new quantity failed validation or reservation.
MessageResource: screen.order.amend.error
PrimaryActionLabel: Retry
PrimaryActionTarget: SCR-02-ACT-1

### <!--[XDFU]--> Design Follow Up

#### <!--[ACCESS]--> Accessibility

##### <!--[ACCESS-ACCE]--> Accessibility Overview Content

AccessibilityStatement: true

## <!--[QACM]--> Quality And Acceptance Model

Acceptance is gated on:

1. a fully automated regression suite over the order lifecycle;
2. a two-week parallel run against OrderDesk with < 0.1% reconciliation
   variance;
3. a load test sustaining 3x peak-hour order volume within the p95 latency
   budget.

Business sign-off requires the operations desk to clear a full day's orders on
MOM alone.

### <!--[I25CV]--> Iso25010 Coverage

#### <!--[I25CE-CHAR-LST]--> Characteristics

##### <!--[I25CE-CHAR-1]--> Iso25010 Coverage 1

Characteristic: performanceEfficiency
AddressedBy: NFR load test at 3x peak-hour order volume
TargetMetric: p95 order-capture latency within budget at 3x peak

##### <!--[I25CE-CHAR-2]--> Iso25010 Coverage 2

Characteristic: reliability
AddressedBy: Two-week parallel run against OrderDesk
TargetMetric: < 0.1% reconciliation variance over the parallel run

## <!--[DTRO]--> Delivery Transition And Rollout

Five increments:

1. order capture + event backbone
2. synchronous pricing + warehouse webhook
3. fulfilment orchestration + back office
4. public API + marketplace onboarding
5. legacy decommission

Transition is channel-by-channel (e-commerce first, then wholesale) with a
parallel-run safety net and a documented rollback to OrderDesk until the
parallel-run gate passes.

