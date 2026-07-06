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

### SBP/introductionAndScope/requirements — requirements

#### SBP/introductionAndScope/requirements/content — content
```text
The requirements below are the contract MOM is built and accepted against. IDs are stable and referenced from the use cases, screens, and data model so every downstream artifact traces back to a requirement.
```

#### SBP/introductionAndScope/requirements/functionalRequirements — functionalRequirements

##### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST — requirements

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1 — FunctionalRequirementEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/content — content
<!-- field: requirementId -->
```
FR-01
```

<!-- field: title -->
```
Capture orders from EDI and REST channels
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/details — details

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/details/content — content
<!-- field: description -->
```
The system must accept orders from the wholesale EDI adapter and the public REST order API, translating both into a single internal order-capture command so downstream processing is channel-agnostic.
```

<!-- field: requirementType -->
```
Functional
```

<!-- field: category -->
```
Order Capture
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/priority — priority

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/priority/content — content
<!-- field: priority -->
```
Must
```

<!-- field: businessValue -->
```
High
```

<!-- field: effort -->
```
M
```

<!-- field: riskLevel -->
```
Medium
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/source — source

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/source/content — content
<!-- field: source -->
```
VP Operations
```

<!-- field: requestDate -->
```
2026-04-02
```

<!-- field: rationale -->
```
Both channels must feed the same lifecycle to retire re-keying.
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/verification — verification

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/verification/content — content
<!-- field: fitCriterion -->
```
An EDI and a REST order both produce an Order in state Captured within 2s.
```

<!-- field: customerSatisfaction -->
```
5
```

<!-- field: customerDissatisfaction -->
```
1
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/acceptanceCriteria — acceptanceCriteria

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/acceptanceCriteria/ACCR-CRIT-LST — criteria

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/acceptanceCriteria/ACCR-CRIT-LST-1 — AcceptanceCriterionEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/acceptanceCriteria/ACCR-CRIT-LST-1/content — content
<!-- field: criterionId -->
```
FR-01-AC-1
```

<!-- field: criterionTitle -->
```
EDI order accepted
```

<!-- field: given -->
```
a well-formed EDI 850 purchase order
```

<!-- field: when -->
```
the EDI adapter submits it to the capture API
```

<!-- field: then -->
```
an Order is created in state Captured and a domain event is emitted
```

<!-- field: verificationMethod -->
```
Automated test
```

<!-- field: testType -->
```
Integration
```

<!-- field: priority -->
```
Must
```

<!-- field: status -->
```
Draft
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/acceptanceCriteria/ACCR-CRIT-LST-2 — AcceptanceCriterionEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-1/acceptanceCriteria/ACCR-CRIT-LST-2/content — content
<!-- field: criterionId -->
```
FR-01-AC-2
```

<!-- field: criterionTitle -->
```
REST order accepted
```

<!-- field: given -->
```
a valid REST order payload from an authenticated partner
```

<!-- field: when -->
```
POST /orders is called
```

<!-- field: then -->
```
an Order is created in state Captured with the same shape as EDI
```

<!-- field: verificationMethod -->
```
Automated test
```

<!-- field: testType -->
```
Integration
```

<!-- field: priority -->
```
Must
```

<!-- field: status -->
```
Draft
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2 — FunctionalRequirementEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/content — content
<!-- field: requirementId -->
```
FR-02
```

<!-- field: title -->
```
Price orders synchronously at capture time
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/details — details

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/details/content — content
<!-- field: description -->
```
Pricing must be computed synchronously during order processing and the resulting unit price snapshotted onto each order line, eliminating the nightly batch and making historical orders reproducible.
```

<!-- field: requirementType -->
```
Functional
```

<!-- field: category -->
```
Pricing
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/priority — priority

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/priority/content — content
<!-- field: priority -->
```
Must
```

<!-- field: businessValue -->
```
High
```

<!-- field: effort -->
```
M
```

<!-- field: riskLevel -->
```
Medium
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/verification — verification

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/verification/content — content
<!-- field: fitCriterion -->
```
Each confirmed line carries a unitPrice snapshot equal to the price list at pricing time.
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/acceptanceCriteria — acceptanceCriteria

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/acceptanceCriteria/ACCR-CRIT-LST — criteria

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/acceptanceCriteria/ACCR-CRIT-LST-1 — AcceptanceCriterionEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-2/acceptanceCriteria/ACCR-CRIT-LST-1/content — content
<!-- field: criterionId -->
```
FR-02-AC-1
```

<!-- field: criterionTitle -->
```
Price snapshotted onto line
```

<!-- field: given -->
```
an order with two lines
```

<!-- field: when -->
```
the order is priced
```

<!-- field: then -->
```
each line stores the resolved unit price as of the pricing timestamp
```

<!-- field: verificationMethod -->
```
Automated test
```

<!-- field: testType -->
```
Integration
```

<!-- field: priority -->
```
Must
```

<!-- field: status -->
```
Draft
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-3 — FunctionalRequirementEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-3/content — content
<!-- field: requirementId -->
```
FR-03
```

<!-- field: title -->
```
Reserve stock before confirmation
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-3/details — details

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-3/details/content — content
<!-- field: description -->
```
Before an order is confirmed the system must reserve stock for every line; insufficient stock places the affected line on Hold rather than failing the whole order.
```

<!-- field: requirementType -->
```
Functional
```

<!-- field: category -->
```
Fulfilment
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-3/priority — priority

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-3/priority/content — content
<!-- field: priority -->
```
Must
```

<!-- field: businessValue -->
```
High
```

<!-- field: effort -->
```
L
```

<!-- field: riskLevel -->
```
High
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-4 — FunctionalRequirementEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-4/content — content
<!-- field: requirementId -->
```
FR-04
```

<!-- field: title -->
```
Confirm orders within five minutes
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-4/details — details

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-4/details/content — content
<!-- field: description -->
```
An order that passes validation, pricing, and reservation must reach state Confirmed within five minutes of capture, with the confirmation communicated on the operations work list and the public tracking page.
```

<!-- field: requirementType -->
```
Functional
```

<!-- field: category -->
```
Order Lifecycle
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-4/priority — priority

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-4/priority/content — content
<!-- field: priority -->
```
Must
```

<!-- field: businessValue -->
```
High
```

<!-- field: effort -->
```
M
```

<!-- field: riskLevel -->
```
Medium
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-5 — FunctionalRequirementEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-5/content — content
<!-- field: requirementId -->
```
FR-05
```

<!-- field: title -->
```
Amend or cancel an order before dispatch
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-5/details — details

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-5/details/content — content
<!-- field: description -->
```
Until an order is dispatched, a clerk must be able to amend line quantities and cancel lines or the whole order; each amendment re-runs pricing and reservation for the affected lines and is fully audited.
```

<!-- field: requirementType -->
```
Functional
```

<!-- field: category -->
```
Order Amendment
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-5/priority — priority

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-5/priority/content — content
<!-- field: priority -->
```
Should
```

<!-- field: businessValue -->
```
Medium
```

<!-- field: effort -->
```
M
```

<!-- field: riskLevel -->
```
Medium
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6 — FunctionalRequirementEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/content — content
<!-- field: requirementId -->
```
FR-06
```

<!-- field: title -->
```
Release a manual hold
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/details — details

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/details/content — content
<!-- field: description -->
```
An Order Supervisor must be able to review an order on Hold and release it back into the lifecycle, recording a reason that is attached to the audit trail.
```

<!-- field: requirementType -->
```
Functional
```

<!-- field: category -->
```
Exception Handling
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/priority — priority

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/priority/content — content
<!-- field: priority -->
```
Must
```

<!-- field: businessValue -->
```
High
```

<!-- field: effort -->
```
S
```

<!-- field: riskLevel -->
```
Low
```

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/acceptanceCriteria — acceptanceCriteria

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/acceptanceCriteria/ACCR-CRIT-LST — criteria

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/acceptanceCriteria/ACCR-CRIT-LST-1 — AcceptanceCriterionEntry

###### SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST-6/acceptanceCriteria/ACCR-CRIT-LST-1/content — content
<!-- field: criterionId -->
```
FR-06-AC-1
```

<!-- field: criterionTitle -->
```
Supervisor releases hold
```

<!-- field: given -->
```
an order in state Hold
```

<!-- field: when -->
```
a supervisor releases it with a reason
```

<!-- field: then -->
```
the order resumes at the transition that placed it on Hold and the reason is audited
```

<!-- field: verificationMethod -->
```
Automated test
```

<!-- field: testType -->
```
Integration
```

<!-- field: priority -->
```
Must
```

<!-- field: status -->
```
Draft
```

#### SBP/introductionAndScope/requirements/technicalRequirements — technicalRequirements

##### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST — requirements

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-1 — TechnicalRequirementEntry

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-1/content — content
<!-- field: requirementId -->
```
TR-01
```

<!-- field: title -->
```
Confirmation latency budget
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-1/details — details

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-1/details/content — content
<!-- field: description -->
```
The 95th-percentile order-confirmation latency must stay within budget under peak load.
```

<!-- field: category -->
```
Performance
```

<!-- field: subcategory -->
```
Latency
```

<!-- field: priority -->
```
Must
```

<!-- field: source -->
```
Operations SLA
```

<!-- field: rationale -->
```
Sub-30s p95 keeps the five-minute business promise safe under 3x peak.
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-1/measurement — measurement

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-1/measurement/content — content
<!-- field: metric -->
```
p95 capture-to-confirmation latency
```

<!-- field: currentValue -->
```
4.2h (legacy)
```

<!-- field: targetValue -->
```
< 30s
```

<!-- field: measurementMethod -->
```
Distributed tracing over the confirmation span
```

<!-- field: measurementEnvironment -->
```
Load test at 3x peak-hour volume
```

<!-- field: measurementFrequency -->
```
Per release + continuous in production
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-2 — TechnicalRequirementEntry

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-2/content — content
<!-- field: requirementId -->
```
TR-02
```

<!-- field: title -->
```
Capture API availability
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-2/details — details

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-2/details/content — content
<!-- field: description -->
```
The order-capture API must meet a 99.9% monthly availability target.
```

<!-- field: category -->
```
Reliability
```

<!-- field: subcategory -->
```
Availability
```

<!-- field: priority -->
```
Must
```

<!-- field: source -->
```
Partner integration agreement
```

<!-- field: rationale -->
```
Marketplace partners depend on the capture API being continuously reachable.
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-2/measurement — measurement

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-2/measurement/content — content
<!-- field: metric -->
```
Monthly capture-API availability
```

<!-- field: targetValue -->
```
>= 99.9%
```

<!-- field: measurementMethod -->
```
Synthetic probes + gateway success-rate metrics
```

<!-- field: measurementFrequency -->
```
Monthly
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-3 — TechnicalRequirementEntry

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-3/content — content
<!-- field: requirementId -->
```
TR-03
```

<!-- field: title -->
```
Event-sourced order service
```

<!-- field: status -->
```
Approved
```

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-3/details — details

###### SBP/introductionAndScope/requirements/technicalRequirements/TERQ-REQU-LST-3/details/content — content
<!-- field: description -->
```
The order service must be event-sourced: the append-only event log is the system of record and all read models are projections rebuildable from the log.
```

<!-- field: category -->
```
Architecture
```

<!-- field: subcategory -->
```
Persistence
```

<!-- field: priority -->
```
Must
```

<!-- field: source -->
```
Enterprise Architecture Board
```

<!-- field: rationale -->
```
Reproducible history and rebuildable projections are core to auditability.
```

#### SBP/introductionAndScope/requirements/securityRequirements — securityRequirements

##### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST — requirements

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-1 — SecurityRequirementEntry

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-1/content — content
<!-- field: requirementId -->
```
SR-01
```

<!-- field: title -->
```
Role-based access control
```

<!-- field: description -->
```
Access is governed by the roles Order Clerk, Order Supervisor, Pricing Admin, and Integration (machine) accounts scoped to specific channels; every state transition is attributed to an authenticated principal.
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-1/classification — classification

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-1/classification/content — content
<!-- field: category -->
```
Access Control
```

<!-- field: subcategory -->
```
Authorization
```

<!-- field: priority -->
```
Must
```

<!-- field: source -->
```
Security chapter
```

<!-- field: rationale -->
```
Least privilege across human and machine actors.
```

<!-- field: threatMitigated -->
```
Unauthorized order manipulation
```

<!-- field: dataClassification -->
```
Internal
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-1/compliance — compliance

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-1/compliance/content — content
<!-- field: owaspCategory -->
```
A01:2021 Broken Access Control
```

<!-- field: nistControl -->
```
AC-6
```

<!-- field: complianceReference -->
```
Corporate IAM policy v3
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-2 — SecurityRequirementEntry

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-2/content — content
<!-- field: requirementId -->
```
SR-02
```

<!-- field: title -->
```
Encrypt customer PII at rest
```

<!-- field: description -->
```
All customer personally identifiable information must be encrypted at rest.
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-2/classification — classification

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-2/classification/content — content
<!-- field: category -->
```
Data Protection
```

<!-- field: subcategory -->
```
Encryption
```

<!-- field: priority -->
```
Must
```

<!-- field: source -->
```
Data Protection Officer
```

<!-- field: rationale -->
```
GDPR obligations on customer records with a 7-year retention.
```

<!-- field: threatMitigated -->
```
PII disclosure from storage compromise
```

<!-- field: dataClassification -->
```
Confidential
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-2/compliance — compliance

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-2/compliance/content — content
<!-- field: nistControl -->
```
SC-28
```

<!-- field: complianceReference -->
```
GDPR Art. 32
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-3 — SecurityRequirementEntry

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-3/content — content
<!-- field: requirementId -->
```
SR-03
```

<!-- field: title -->
```
OAuth2 client credentials on the public API
```

<!-- field: description -->
```
The public order API must authenticate partners with OAuth2 client-credentials tokens and enforce per-partner rate limits at the gateway.
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-3/classification — classification

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-3/classification/content — content
<!-- field: category -->
```
API Security
```

<!-- field: subcategory -->
```
Authentication
```

<!-- field: priority -->
```
Must
```

<!-- field: source -->
```
Security chapter
```

<!-- field: rationale -->
```
Machine-to-machine partner access without shared secrets in code.
```

<!-- field: threatMitigated -->
```
Credential replay and partner impersonation
```

<!-- field: dataClassification -->
```
Internal
```

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-3/compliance — compliance

###### SBP/introductionAndScope/requirements/securityRequirements/SECRQ-REQU-LST-3/compliance/content — content
<!-- field: owaspCategory -->
```
API2:2023 Broken Authentication
```

<!-- field: nistControl -->
```
IA-5
```

#### SBP/introductionAndScope/requirements/organizationalRequirements — organizationalRequirements

##### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST — requirements

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-1 — OrganizationalRequirementEntry

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-1/content — content
<!-- field: requirementId -->
```
OR-01
```

<!-- field: title -->
```
Train the operations desk on MOM
```

<!-- field: description -->
```
Before cutover the order-operations desk must be trained to run the full order lifecycle on MOM alone, including hold release and amendments.
```

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-1/impact — impact

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-1/impact/content — content
<!-- field: impactedGroups -->
```
Order Operations desk
```

<!-- field: impactedUserCount -->
```
25
```

<!-- field: changeType -->
```
Process + tooling
```

<!-- field: changeComplexity -->
```
Medium
```

<!-- field: resistance -->
```
Low
```

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-2 — OrganizationalRequirementEntry

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-2/content — content
<!-- field: requirementId -->
```
OR-02
```

<!-- field: title -->
```
Staff the parallel run
```

<!-- field: description -->
```
The two-week parallel run against OrderDesk requires staffing to reconcile both systems daily until the < 0.1% variance gate passes.
```

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-2/impact — impact

###### SBP/introductionAndScope/requirements/organizationalRequirements/ORRQ-REQU-LST-2/impact/content — content
<!-- field: impactedGroups -->
```
Order Operations, Finance
```

<!-- field: impactedUserCount -->
```
30
```

<!-- field: changeType -->
```
Temporary dual-running
```

<!-- field: changeComplexity -->
```
Medium
```

<!-- field: resistance -->
```
Medium
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

### SBP/targetOperatingModelConcept/targetBusinessProcess — targetBusinessProcess

#### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions — processStepsAndActorInteractions

##### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview — actorOverview

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST — actors

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-1 — ActorEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-1/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-1/identification/content — content
<!-- field: actorId -->
```
ACT-01
```

<!-- field: actorName -->
```
Order Clerk
```

<!-- field: actorType -->
```
Human
```

<!-- field: category -->
```
Primary
```

<!-- field: description -->
```
Clears the order work list, amends lines, and cancels orders before dispatch.
```

<!-- field: organizationalUnit -->
```
Order Operations
```

<!-- field: estimatedCount -->
```
25
```

<!-- field: geographicDistribution -->
```
Single distribution centre
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-2 — ActorEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-2/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-2/identification/content — content
<!-- field: actorId -->
```
ACT-02
```

<!-- field: actorName -->
```
Order Supervisor
```

<!-- field: actorType -->
```
Human
```

<!-- field: category -->
```
Primary
```

<!-- field: description -->
```
Reviews orders on Hold and releases them back into the lifecycle.
```

<!-- field: organizationalUnit -->
```
Order Operations
```

<!-- field: estimatedCount -->
```
4
```

<!-- field: geographicDistribution -->
```
Single distribution centre
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-3 — ActorEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-3/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-3/identification/content — content
<!-- field: actorId -->
```
ACT-03
```

<!-- field: actorName -->
```
Pricing Admin
```

<!-- field: actorType -->
```
Human
```

<!-- field: category -->
```
Supporting
```

<!-- field: description -->
```
Maintains the price lists that the synchronous pricing step consumes.
```

<!-- field: organizationalUnit -->
```
Commercial
```

<!-- field: estimatedCount -->
```
3
```

<!-- field: geographicDistribution -->
```
Single distribution centre
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-4 — ActorEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-4/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/actorOverview/ACEN-ACTO-LST-4/identification/content — content
<!-- field: actorId -->
```
ACT-04
```

<!-- field: actorName -->
```
EDI Integration Account
```

<!-- field: actorType -->
```
System
```

<!-- field: category -->
```
Primary
```

<!-- field: description -->
```
Machine account through which the wholesale EDI adapter submits orders.
```

<!-- field: organizationalUnit -->
```
Integration
```

<!-- field: estimatedCount -->
```
1
```

<!-- field: geographicDistribution -->
```
Single distribution centre
```

##### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog — interactionCatalog

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST — interactions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1 — InteractionEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/identification/content — content
<!-- field: interactionId -->
```
UC-01
```

<!-- field: useCaseName -->
```
Capture Wholesale Order (EDI)
```

<!-- field: processReference -->
```
BP-Order-Capture
```

<!-- field: briefDescription -->
```
A wholesale EDI purchase order is captured, validated, priced, reserved, and confirmed.
```

<!-- field: fullDescription -->
```
The EDI adapter submits a translated purchase order to the capture command API. The system validates the customer and lines, prices each line synchronously, reserves stock, and confirms the order — emitting a domain event at every transition so the work list and public tracking page stay current.
```

<!-- field: primaryActor -->
```
ACT-04 EDI Integration Account
```

<!-- field: supportingActors -->
```
ACT-01 Order Clerk
```

<!-- field: goalLevel -->
```
User goal
```

<!-- field: designScope -->
```
System
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/PRANTR-PREC-LST — preconditions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/PRANTR-PREC-LST-1 — PreconditionsAndTriggers

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/PRANTR-PREC-LST-1/content — content
<!-- field: precondition -->
```
The submitting Integration account is authenticated and scoped to the wholesale channel.
```

<!-- field: trigger -->
```
An EDI 850 purchase order arrives at the wholesale adapter.
```

<!-- field: triggerType -->
```
External
```

<!-- field: triggerSource -->
```
EDI gateway
```

<!-- field: triggerData -->
```
EDI 850 document
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/POANGU-POST-LST — postconditions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/POANGU-POST-LST-1 — PostconditionsAndGuarantees

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/POANGU-POST-LST-1/content — content
<!-- field: minimalGuarantees -->
```
Either an Order exists in a well-defined state or the submission is rejected with a reason; no partial order is persisted.
```

<!-- field: successGuarantees -->
```
The Order is in state Confirmed with priced, reserved lines and a full event history.
```

<!-- field: dataPostcondition -->
```
Order and OrderLine rows persisted; reservation recorded against Product stock.
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario — mainScenario

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST — steps

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-1 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-1/content — content
<!-- field: stepNumber -->
```
1
```

<!-- field: actorAction -->
```
EDI adapter submits the translated order to the capture API.
```

<!-- field: systemResponse -->
```
System creates the Order in state Captured and emits OrderCaptured.
```

<!-- field: dataInvolved -->
```
Order, OrderLine
```

<!-- field: uiElementUsed -->
```
—
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-2 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-2/content — content
<!-- field: stepNumber -->
```
2
```

<!-- field: actorAction -->
```
System validates customer credit and line stock references.
```

<!-- field: systemResponse -->
```
Order moves to Validated; invalid references are flagged per line.
```

<!-- field: dataInvolved -->
```
Customer, Product
```

<!-- field: businessRuleApplied -->
```
Credit limit not exceeded
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-3 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-3/content — content
<!-- field: stepNumber -->
```
3
```

<!-- field: actorAction -->
```
System prices each line against the active price list.
```

<!-- field: systemResponse -->
```
Unit price is snapshotted onto each line; Order moves to Priced.
```

<!-- field: dataInvolved -->
```
PriceList, OrderLine
```

<!-- field: businessRuleApplied -->
```
FR-02 price snapshot
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-4 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-4/content — content
<!-- field: stepNumber -->
```
4
```

<!-- field: actorAction -->
```
System reserves stock for every line.
```

<!-- field: systemResponse -->
```
Reservations recorded; Order moves to Reserved.
```

<!-- field: dataInvolved -->
```
Product
```

<!-- field: businessRuleApplied -->
```
FR-03 reserve before confirm
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-5 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/mainScenario/MNSST-STEP-LST-5/content — content
<!-- field: stepNumber -->
```
5
```

<!-- field: actorAction -->
```
System confirms the order.
```

<!-- field: systemResponse -->
```
Order moves to Confirmed within five minutes and appears on the work list.
```

<!-- field: dataInvolved -->
```
Order
```

<!-- field: businessRuleApplied -->
```
FR-04 five-minute confirmation
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions — extensions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST — extensions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-1 — ExtensionEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-1/content — content
<!-- field: extensionId -->
```
2a
```

<!-- field: branchPoint -->
```
Step 2
```

<!-- field: condition -->
```
Customer credit limit would be exceeded
```

<!-- field: extensionType -->
```
Exception
```

<!-- field: description -->
```
Validation detects the order exceeds the customer credit limit.
```

<!-- field: outcome -->
```
Order is placed on Hold for supervisor review (see UC-02).
```

<!-- field: returnPoint -->
```
Step 3 after release
```

<!-- field: severity -->
```
High
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-1/EXTST-STEP-LST — steps

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-1/EXTST-STEP-LST-1 — ExtensionStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-1/EXTST-STEP-LST-1/content — content
<!-- field: stepNumber -->
```
2a.1
```

<!-- field: action -->
```
System places the Order on Hold and emits OrderHeld.
```

<!-- field: response -->
```
Order appears in the Hold filter of the work list with reason "Credit exceeded".
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-2 — ExtensionEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-2/content — content
<!-- field: extensionId -->
```
4a
```

<!-- field: branchPoint -->
```
Step 4
```

<!-- field: condition -->
```
Insufficient stock for one or more lines
```

<!-- field: extensionType -->
```
Exception
```

<!-- field: description -->
```
Reservation cannot be fully satisfied for a line.
```

<!-- field: outcome -->
```
The affected line is placed on Hold; other lines proceed.
```

<!-- field: returnPoint -->
```
Step 5 for satisfiable lines
```

<!-- field: severity -->
```
Medium
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-2/EXTST-STEP-LST — steps

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-2/EXTST-STEP-LST-1 — ExtensionStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-1/extensions/EXTEN-EXTE-LST-2/EXTST-STEP-LST-1/content — content
<!-- field: stepNumber -->
```
4a.1
```

<!-- field: action -->
```
System holds the unsatisfiable line and reserves the rest.
```

<!-- field: response -->
```
The order is partially reserved; the held line is flagged for follow-up.
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2 — InteractionEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/identification/content — content
<!-- field: interactionId -->
```
UC-02
```

<!-- field: useCaseName -->
```
Release Order Hold
```

<!-- field: processReference -->
```
BP-Order-Exception
```

<!-- field: briefDescription -->
```
A supervisor reviews an order on Hold and releases it back into the lifecycle.
```

<!-- field: fullDescription -->
```
A supervisor opens an order on Hold from the work list, reviews the hold reason, and either releases it — resuming the lifecycle at the transition that placed it on Hold — or cancels it, recording a reason in both cases.
```

<!-- field: primaryActor -->
```
ACT-02 Order Supervisor
```

<!-- field: goalLevel -->
```
User goal
```

<!-- field: designScope -->
```
System
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/PRANTR-PREC-LST — preconditions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/PRANTR-PREC-LST-1 — PreconditionsAndTriggers

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/PRANTR-PREC-LST-1/content — content
<!-- field: precondition -->
```
An order exists in state Hold and the actor holds the Order Supervisor role.
```

<!-- field: trigger -->
```
Supervisor selects a held order from the work list.
```

<!-- field: triggerType -->
```
User
```

<!-- field: triggerSource -->
```
Order Work List screen
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/POANGU-POST-LST — postconditions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/POANGU-POST-LST-1 — PostconditionsAndGuarantees

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/POANGU-POST-LST-1/content — content
<!-- field: successGuarantees -->
```
The order resumes at the transition that placed it on Hold, with the release reason audited.
```

<!-- field: auditTrail -->
```
Release attributed to the supervisor principal with timestamp and reason.
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/mainScenario — mainScenario

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/mainScenario/MNSST-STEP-LST — steps

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/mainScenario/MNSST-STEP-LST-1 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/mainScenario/MNSST-STEP-LST-1/content — content
<!-- field: stepNumber -->
```
1
```

<!-- field: actorAction -->
```
Supervisor opens the held order and reviews the reason.
```

<!-- field: systemResponse -->
```
System shows the lifecycle timeline and the hold reason.
```

<!-- field: dataInvolved -->
```
Order
```

<!-- field: uiElementUsed -->
```
Order Detail timeline
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/mainScenario/MNSST-STEP-LST-2 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-2/mainScenario/MNSST-STEP-LST-2/content — content
<!-- field: stepNumber -->
```
2
```

<!-- field: actorAction -->
```
Supervisor releases the order with a reason.
```

<!-- field: systemResponse -->
```
System resumes the lifecycle and emits OrderHoldReleased.
```

<!-- field: dataInvolved -->
```
Order
```

<!-- field: businessRuleApplied -->
```
FR-06 hold release
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3 — InteractionEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/identification/content — content
<!-- field: interactionId -->
```
UC-03
```

<!-- field: useCaseName -->
```
Amend Order Line Before Dispatch
```

<!-- field: processReference -->
```
BP-Order-Amendment
```

<!-- field: briefDescription -->
```
A clerk changes a line quantity before dispatch, re-running pricing and reservation.
```

<!-- field: fullDescription -->
```
A clerk edits the quantity of a line on a not-yet-dispatched order. The system re-prices and re-reserves only the affected line and records the amendment on the audit trail.
```

<!-- field: primaryActor -->
```
ACT-01 Order Clerk
```

<!-- field: goalLevel -->
```
User goal
```

<!-- field: designScope -->
```
System
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/PRANTR-PREC-LST — preconditions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/PRANTR-PREC-LST-1 — PreconditionsAndTriggers

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/PRANTR-PREC-LST-1/content — content
<!-- field: precondition -->
```
The order is not yet dispatched and the actor holds the Order Clerk role.
```

<!-- field: trigger -->
```
Clerk edits a line quantity on the Order Detail screen.
```

<!-- field: triggerType -->
```
User
```

<!-- field: triggerSource -->
```
Order Detail screen
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/POANGU-POST-LST — postconditions

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/POANGU-POST-LST-1 — PostconditionsAndGuarantees

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/POANGU-POST-LST-1/content — content
<!-- field: successGuarantees -->
```
The amended line carries a fresh price snapshot and reservation; the amendment is audited.
```

<!-- field: dataPostcondition -->
```
OrderLine updated; prior values retained in the event history.
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/mainScenario — mainScenario

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/mainScenario/MNSST-STEP-LST — steps

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/mainScenario/MNSST-STEP-LST-1 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/mainScenario/MNSST-STEP-LST-1/content — content
<!-- field: stepNumber -->
```
1
```

<!-- field: actorAction -->
```
Clerk changes the quantity of a line and saves.
```

<!-- field: systemResponse -->
```
System validates the new quantity and re-prices the line.
```

<!-- field: dataInvolved -->
```
OrderLine, PriceList
```

<!-- field: businessRuleApplied -->
```
FR-05 amend before dispatch
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/mainScenario/MNSST-STEP-LST-2 — MainScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/interactionCatalog/INEN-INTE-LST-3/mainScenario/MNSST-STEP-LST-2/content — content
<!-- field: stepNumber -->
```
2
```

<!-- field: actorAction -->
```
System re-reserves stock for the amended line.
```

<!-- field: systemResponse -->
```
Reservation is adjusted; the order returns to Confirmed if fully satisfied.
```

<!-- field: dataInvolved -->
```
Product
```

<!-- field: businessRuleApplied -->
```
FR-03 reserve before confirm
```

##### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios — keyScenarios

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST — scenarios

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1 — ScenarioEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/identification — identification

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/identification/content — content
<!-- field: scenarioId -->
```
SCN-01
```

<!-- field: scenarioName -->
```
Happy-path wholesale order, capture to fulfilment
```

<!-- field: scenarioType -->
```
End-to-end
```

<!-- field: description -->
```
A clean wholesale order flows from EDI capture through to fulfilment with no holds.
```

<!-- field: businessGoal -->
```
Confirm and fulfil a wholesale order without manual intervention.
```

<!-- field: primaryActor -->
```
ACT-04 EDI Integration Account
```

<!-- field: supportingActors -->
```
ACT-01 Order Clerk
```

<!-- field: priority -->
```
High
```

<!-- field: complexity -->
```
Medium
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST — steps

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST-1 — ScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST-1/content — content
<!-- field: stepNumber -->
```
1
```

<!-- field: actor -->
```
ACT-04 EDI Integration Account
```

<!-- field: action -->
```
Submits a two-line wholesale order.
```

<!-- field: systemResponse -->
```
Order captured, validated, priced, reserved, and confirmed within five minutes.
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST-2 — ScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST-2/content — content
<!-- field: stepNumber -->
```
2
```

<!-- field: actor -->
```
ACT-01 Order Clerk
```

<!-- field: action -->
```
Observes the confirmed order on the work list.
```

<!-- field: systemResponse -->
```
Order shows state Confirmed with both lines priced and reserved.
```

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST-3 — ScenarioStepEntry

###### SBP/targetOperatingModelConcept/targetBusinessProcess/processStepsAndActorInteractions/keyScenarios/SCNRY-SCEN-LST-1/SCNST-STEP-LST-3/content — content
<!-- field: stepNumber -->
```
3
```

<!-- field: actor -->
```
System
```

<!-- field: action -->
```
Receives the warehouse dispatch webhook.
```

<!-- field: systemResponse -->
```
Order moves to Fulfilled and the public tracking page updates.
```

## SBP/informationAndDataModel — informationAndDataModel

### SBP/informationAndDataModel/content — content
```text
Core aggregates: Order (with Lines), Customer, Product, PriceList, and FulfilmentPlan. Orders reference Customers and Products by stable IDs; prices are snapshotted onto each Line at pricing time so historical orders remain reproducible. The event log is the system of record; read models are projections.
```

### SBP/informationAndDataModel/dataModel — dataModel

#### SBP/informationAndDataModel/dataModel/content — content
```text
The relational core of MOM. Order is the aggregate root; each Order owns its OrderLines and references a Customer and, per line, a Product. Prices are snapshotted onto lines so historical orders remain reproducible.
```

#### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST — entities

##### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1 — DataEntityEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/identity — identity
<!-- field: entityName -->
```
Order
```

<!-- field: tableName -->
```
mom_order
```

<!-- field: entityAlias -->
```
ORD
```

<!-- field: description -->
```
A customer order captured from EDI or REST and driven through the lifecycle.
```

<!-- field: entityStereoType -->
```
Aggregate Root
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/classification — classification
<!-- field: category -->
```
Transactional
```

<!-- field: boundedContext -->
```
Ordering
```

<!-- field: owningDomain -->
```
Order Management
```

<!-- field: dataOwner -->
```
Head of Order Operations
```

<!-- field: sourceSystem -->
```
MOM
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST — attributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-1 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-1/identity — identity
<!-- field: attributeName -->
```
orderId
```

<!-- field: columnName -->
```
order_id
```

<!-- field: description -->
```
Stable order identifier.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-1/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-1/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-2 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-2/identity — identity
<!-- field: attributeName -->
```
customerId
```

<!-- field: columnName -->
```
customer_id
```

<!-- field: description -->
```
Reference to the ordering customer.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-2/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-2/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-3 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-3/identity — identity
<!-- field: attributeName -->
```
channel
```

<!-- field: columnName -->
```
channel
```

<!-- field: description -->
```
Capture channel: EDI or REST.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-3/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
Enum
```

<!-- field: physicalType -->
```
varchar(8)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-3/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-4 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-4/identity — identity
<!-- field: attributeName -->
```
status
```

<!-- field: columnName -->
```
status
```

<!-- field: description -->
```
Lifecycle state (Captured..Closed, with Hold).
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-4/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
Enum
```

<!-- field: physicalType -->
```
varchar(16)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-4/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-5 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-5/identity — identity
<!-- field: attributeName -->
```
createdAt
```

<!-- field: columnName -->
```
created_at
```

<!-- field: description -->
```
Capture timestamp (UTC).
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-5/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
Timestamp
```

<!-- field: physicalType -->
```
timestamptz
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAATT-ATTR-LST-5/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/KEATT-KEYA-LST — keyAttributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/KEATT-KEYA-LST-1 — KeyAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/KEATT-KEYA-LST-1/content — content
<!-- field: keyName -->
```
pk_order
```

<!-- field: keyType -->
```
Primary
```

<!-- field: keyColumns -->
```
order_id
```

<!-- field: description -->
```
Primary key of the order.
```

##### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2 — DataEntityEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/identity — identity
<!-- field: entityName -->
```
OrderLine
```

<!-- field: tableName -->
```
mom_order_line
```

<!-- field: entityAlias -->
```
OLN
```

<!-- field: description -->
```
A single product/quantity within an order, with a snapshotted price.
```

<!-- field: entityStereoType -->
```
Entity
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/classification — classification
<!-- field: category -->
```
Transactional
```

<!-- field: boundedContext -->
```
Ordering
```

<!-- field: owningDomain -->
```
Order Management
```

<!-- field: dataOwner -->
```
Head of Order Operations
```

<!-- field: sourceSystem -->
```
MOM
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST — attributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-1 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-1/identity — identity
<!-- field: attributeName -->
```
lineId
```

<!-- field: columnName -->
```
line_id
```

<!-- field: description -->
```
Stable line identifier.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-1/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-1/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-2 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-2/identity — identity
<!-- field: attributeName -->
```
orderId
```

<!-- field: columnName -->
```
order_id
```

<!-- field: description -->
```
Owning order reference.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-2/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-2/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-3 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-3/identity — identity
<!-- field: attributeName -->
```
productId
```

<!-- field: columnName -->
```
product_id
```

<!-- field: description -->
```
Referenced product.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-3/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-3/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-4 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-4/identity — identity
<!-- field: attributeName -->
```
quantity
```

<!-- field: columnName -->
```
quantity
```

<!-- field: description -->
```
Ordered quantity.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-4/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
Integer
```

<!-- field: physicalType -->
```
int
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-4/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-5 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-5/identity — identity
<!-- field: attributeName -->
```
unitPrice
```

<!-- field: columnName -->
```
unit_price
```

<!-- field: description -->
```
Snapshotted unit price at pricing time.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-5/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
Decimal
```

<!-- field: physicalType -->
```
numeric(12,2)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/DAATT-ATTR-LST-5/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/KEATT-KEYA-LST — keyAttributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/KEATT-KEYA-LST-1 — KeyAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/KEATT-KEYA-LST-1/content — content
<!-- field: keyName -->
```
pk_order_line
```

<!-- field: keyType -->
```
Primary
```

<!-- field: keyColumns -->
```
line_id
```

<!-- field: description -->
```
Primary key of the order line.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/KEATT-KEYA-LST-2 — KeyAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/KEATT-KEYA-LST-2/content — content
<!-- field: keyName -->
```
fk_line_order
```

<!-- field: keyType -->
```
Foreign
```

<!-- field: keyColumns -->
```
order_id
```

<!-- field: description -->
```
References the owning order.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-2/KEATT-KEYA-LST-2/referencedEntityRef — referencedEntityRef
```text
Order
```

##### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3 — DataEntityEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/identity — identity
<!-- field: entityName -->
```
Customer
```

<!-- field: tableName -->
```
mom_customer
```

<!-- field: entityAlias -->
```
CUS
```

<!-- field: description -->
```
A wholesale or e-commerce customer that places orders.
```

<!-- field: entityStereoType -->
```
Aggregate Root
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/classification — classification
<!-- field: category -->
```
Master
```

<!-- field: boundedContext -->
```
Customer
```

<!-- field: owningDomain -->
```
Customer Management
```

<!-- field: dataOwner -->
```
Commercial
```

<!-- field: sourceSystem -->
```
MOM
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST — attributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-1 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-1/identity — identity
<!-- field: attributeName -->
```
customerId
```

<!-- field: columnName -->
```
customer_id
```

<!-- field: description -->
```
Stable customer identifier.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-1/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-1/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-2 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-2/identity — identity
<!-- field: attributeName -->
```
name
```

<!-- field: columnName -->
```
name
```

<!-- field: description -->
```
Customer legal name (PII).
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-2/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
String
```

<!-- field: physicalType -->
```
varchar(200)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-2/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Confidential
```

<!-- field: isPii -->
```
true
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-3 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-3/identity — identity
<!-- field: attributeName -->
```
creditLimit
```

<!-- field: columnName -->
```
credit_limit
```

<!-- field: description -->
```
Approved credit limit used by validation.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-3/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
Decimal
```

<!-- field: physicalType -->
```
numeric(14,2)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/DAATT-ATTR-LST-3/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Confidential
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/KEATT-KEYA-LST — keyAttributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/KEATT-KEYA-LST-1 — KeyAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-3/KEATT-KEYA-LST-1/content — content
<!-- field: keyName -->
```
pk_customer
```

<!-- field: keyType -->
```
Primary
```

<!-- field: keyColumns -->
```
customer_id
```

<!-- field: description -->
```
Primary key of the customer.
```

##### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4 — DataEntityEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/identity — identity
<!-- field: entityName -->
```
Product
```

<!-- field: tableName -->
```
mom_product
```

<!-- field: entityAlias -->
```
PRD
```

<!-- field: description -->
```
A sellable product referenced by order lines and priced by the price list.
```

<!-- field: entityStereoType -->
```
Aggregate Root
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/classification — classification
<!-- field: category -->
```
Master
```

<!-- field: boundedContext -->
```
Catalogue
```

<!-- field: owningDomain -->
```
Merchandising
```

<!-- field: dataOwner -->
```
Merchandising
```

<!-- field: sourceSystem -->
```
MOM
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST — attributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-1 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-1/identity — identity
<!-- field: attributeName -->
```
productId
```

<!-- field: columnName -->
```
product_id
```

<!-- field: description -->
```
Stable product identifier.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-1/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
UUID
```

<!-- field: physicalType -->
```
uuid
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-1/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-2 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-2/identity — identity
<!-- field: attributeName -->
```
sku
```

<!-- field: columnName -->
```
sku
```

<!-- field: description -->
```
Stock-keeping unit.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-2/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
String
```

<!-- field: physicalType -->
```
varchar(40)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-2/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-3 — DataAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-3/identity — identity
<!-- field: attributeName -->
```
name
```

<!-- field: columnName -->
```
name
```

<!-- field: description -->
```
Product display name.
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-3/dataTypeSpec — dataTypeSpec
<!-- field: dataType -->
```
String
```

<!-- field: physicalType -->
```
varchar(200)
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/DAATT-ATTR-LST-3/securityClassification — securityClassification
<!-- field: sensitivityLevel -->
```
Internal
```

<!-- field: isPii -->
```
false
```

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/KEATT-KEYA-LST — keyAttributes

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/KEATT-KEYA-LST-1 — KeyAttributeEntry

###### SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-4/KEATT-KEYA-LST-1/content — content
<!-- field: keyName -->
```
pk_product
```

<!-- field: keyType -->
```
Primary
```

<!-- field: keyColumns -->
```
product_id
```

<!-- field: description -->
```
Primary key of the product.
```

#### SBP/informationAndDataModel/dataModel/entityRelationships — entityRelationships

##### SBP/informationAndDataModel/dataModel/entityRelationships/content — content
```text
The foreign-key relationships binding the ordering core together.
```

##### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST — items

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-1 — EntityRelationshipEntry

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-1/identity — identity
<!-- field: relationshipName -->
```
Order-owns-Lines
```

<!-- field: relationshipType -->
```
Composition
```

<!-- field: description -->
```
An order owns one or more order lines.
```

<!-- field: businessJustification -->
```
Maintains referential integrity across the ordering core.
```

<!-- field: implementationType -->
```
Foreign Key
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-1/cardinality — cardinality
<!-- field: sourceCardinality -->
```
1
```

<!-- field: targetCardinality -->
```
1..*
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-1/navigation — navigation
<!-- field: navigability -->
```
Bidirectional
```

<!-- field: foreignKeyLocation -->
```
mom_order_line.order_id
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-1/sourceEntityRef — sourceEntityRef
```text
Order
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-1/targetEntityRef — targetEntityRef
```text
OrderLine
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-2 — EntityRelationshipEntry

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-2/identity — identity
<!-- field: relationshipName -->
```
Order-placed-by-Customer
```

<!-- field: relationshipType -->
```
Association
```

<!-- field: description -->
```
Each order is placed by exactly one customer.
```

<!-- field: businessJustification -->
```
Maintains referential integrity across the ordering core.
```

<!-- field: implementationType -->
```
Foreign Key
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-2/cardinality — cardinality
<!-- field: sourceCardinality -->
```
*
```

<!-- field: targetCardinality -->
```
1
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-2/navigation — navigation
<!-- field: navigability -->
```
Bidirectional
```

<!-- field: foreignKeyLocation -->
```
mom_order.customer_id
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-2/sourceEntityRef — sourceEntityRef
```text
Order
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-2/targetEntityRef — targetEntityRef
```text
Customer
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-3 — EntityRelationshipEntry

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-3/identity — identity
<!-- field: relationshipName -->
```
Line-references-Product
```

<!-- field: relationshipType -->
```
Association
```

<!-- field: description -->
```
Each order line references exactly one product.
```

<!-- field: businessJustification -->
```
Maintains referential integrity across the ordering core.
```

<!-- field: implementationType -->
```
Foreign Key
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-3/cardinality — cardinality
<!-- field: sourceCardinality -->
```
*
```

<!-- field: targetCardinality -->
```
1
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-3/navigation — navigation
<!-- field: navigability -->
```
Bidirectional
```

<!-- field: foreignKeyLocation -->
```
mom_order_line.product_id
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-3/sourceEntityRef — sourceEntityRef
```text
OrderLine
```

###### SBP/informationAndDataModel/dataModel/entityRelationships/ENRLE-ITEM-LST-3/targetEntityRef — targetEntityRef
```text
Product
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

### SBP/experienceAndInterfaceDesign/screens — screens

#### SBP/experienceAndInterfaceDesign/screens/screenInventory — screenInventory

##### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1 — ScreenEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/content — content
<!-- field: screenId -->
```
SCR-01
```

<!-- field: screenName -->
```
Order Work List
```

<!-- field: purpose -->
```
The single, state-filtered queue from which clerks work every order.
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/classification — classification

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/classification/content — content
<!-- field: screenCategory -->
```
List
```

<!-- field: routePattern -->
```
/orders
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/access — access

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/access/content — content
<!-- field: accessLevel -->
```
Authenticated
```

<!-- field: requiredRoles -->
```
Order Clerk, Order Supervisor
```

<!-- field: permissionEffect -->
```
Allow
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/traceability — traceability

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/traceability/content — content
<!-- field: relatedUseCases -->
```
UC-01, UC-02
```

<!-- field: relatedRequirements -->
```
FR-01, FR-04, FR-06
```

<!-- field: dataEntities -->
```
Order
```

<!-- field: primaryAction -->
```
Open selected order
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/presentation — presentation

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/presentation/content — content
<!-- field: pageTitleResource -->
```
screen.orders.title
```

<!-- field: layout -->
```
Master-detail
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections — sections

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1 — ScreenSectionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/content — content
<!-- field: sectionId -->
```
SCR-01-SEC-1
```

<!-- field: sectionName -->
```
State filter bar
```

<!-- field: purpose -->
```
Filter the queue by lifecycle state.
```

<!-- field: sectionType -->
```
Toolbar
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/layout — layout

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/layout/content — content
<!-- field: layoutDirection -->
```
Horizontal
```

<!-- field: displayOrder -->
```
1
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/SCREL-ELEM-LST — elements

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/SCREL-ELEM-LST-1 — ScreenElementEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/SCREL-ELEM-LST-1/content — content
<!-- field: elementId -->
```
SCR-01-EL-1
```

<!-- field: elementName -->
```
State selector
```

<!-- field: elementType -->
```
SegmentedControl
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/SCREL-ELEM-LST-1/resources — resources

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-1/SCREL-ELEM-LST-1/resources/content — content
<!-- field: labelResource -->
```
screen.orders.filter.state
```

<!-- field: hintResource -->
```
screen.orders.filter.state.hint
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2 — ScreenSectionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/content — content
<!-- field: sectionId -->
```
SCR-01-SEC-2
```

<!-- field: sectionName -->
```
Order table
```

<!-- field: purpose -->
```
The work list itself, keyboard-navigable for high-volume clerks.
```

<!-- field: sectionType -->
```
DataTable
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/layout — layout

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/layout/content — content
<!-- field: layoutDirection -->
```
Vertical
```

<!-- field: displayOrder -->
```
2
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST — elements

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1 — ScreenElementEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/content — content
<!-- field: elementId -->
```
SCR-01-EL-2
```

<!-- field: elementName -->
```
Order ID column
```

<!-- field: elementType -->
```
TextField
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/fieldSpec — fieldSpec

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/fieldSpec/content — content
<!-- field: fieldName -->
```
orderId
```

<!-- field: dataType -->
```
UUID
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-2 — ScreenElementEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-2/content — content
<!-- field: elementId -->
```
SCR-01-EL-3
```

<!-- field: elementName -->
```
Status column
```

<!-- field: elementType -->
```
StatusChip
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-2/fieldSpec — fieldSpec

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-2/fieldSpec/content — content
<!-- field: fieldName -->
```
status
```

<!-- field: dataType -->
```
Enum
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/actions — actions

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/actions/SCRAC-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/actions/SCRAC-ITEM-LST-1 — ScreenActionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/actions/SCRAC-ITEM-LST-1/content — content
<!-- field: actionId -->
```
SCR-01-ACT-1
```

<!-- field: actionName -->
```
Open order
```

<!-- field: actionType -->
```
Navigate
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/actions/SCRAC-ITEM-LST-1/visual — visual

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/actions/SCRAC-ITEM-LST-1/visual/content — content
<!-- field: labelResource -->
```
screen.orders.action.open
```

<!-- field: placement -->
```
Row
```

<!-- field: buttonStyle -->
```
Primary
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/states — states

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/states/SCRST-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/states/SCRST-ITEM-LST-1 — ScreenStateEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-1/states/SCRST-ITEM-LST-1/content — content
<!-- field: stateName -->
```
Empty queue
```

<!-- field: description -->
```
No orders match the selected state filter.
```

<!-- field: messageResource -->
```
screen.orders.empty
```

<!-- field: primaryActionLabel -->
```
Clear filter
```

<!-- field: primaryActionTarget -->
```
SCR-01-EL-1
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2 — ScreenEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/content — content
<!-- field: screenId -->
```
SCR-02
```

<!-- field: screenName -->
```
Order Detail
```

<!-- field: purpose -->
```
The lifecycle timeline and inline actions for a single order.
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/classification — classification

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/classification/content — content
<!-- field: screenCategory -->
```
Detail
```

<!-- field: parentScreenId -->
```
SCR-01
```

<!-- field: routePattern -->
```
/orders/:orderId
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/access — access

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/access/content — content
<!-- field: accessLevel -->
```
Authenticated
```

<!-- field: requiredRoles -->
```
Order Clerk, Order Supervisor
```

<!-- field: permissionEffect -->
```
Allow
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/traceability — traceability

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/traceability/content — content
<!-- field: relatedUseCases -->
```
UC-02, UC-03
```

<!-- field: relatedRequirements -->
```
FR-05, FR-06
```

<!-- field: dataEntities -->
```
Order, OrderLine
```

<!-- field: primaryAction -->
```
Amend line
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/presentation — presentation

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/presentation/content — content
<!-- field: pageTitleResource -->
```
screen.order.title
```

<!-- field: layout -->
```
Single column
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections — sections

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-1 — ScreenSectionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-1/content — content
<!-- field: sectionId -->
```
SCR-02-SEC-1
```

<!-- field: sectionName -->
```
Lifecycle timeline
```

<!-- field: purpose -->
```
Show every state transition with its authenticated actor.
```

<!-- field: sectionType -->
```
Timeline
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-1/layout — layout

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-1/layout/content — content
<!-- field: layoutDirection -->
```
Vertical
```

<!-- field: displayOrder -->
```
1
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2 — ScreenSectionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/content — content
<!-- field: sectionId -->
```
SCR-02-SEC-2
```

<!-- field: sectionName -->
```
Order lines
```

<!-- field: purpose -->
```
Editable list of lines with price and reservation status.
```

<!-- field: sectionType -->
```
EditableTable
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/layout — layout

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/layout/content — content
<!-- field: layoutDirection -->
```
Vertical
```

<!-- field: displayOrder -->
```
2
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST — elements

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1 — ScreenElementEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/content — content
<!-- field: elementId -->
```
SCR-02-EL-1
```

<!-- field: elementName -->
```
Quantity field
```

<!-- field: elementType -->
```
NumberField
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/behavior — behavior

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/behavior/content — content
<!-- field: readonlyCondition -->
```
order.status == "Dispatched"
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/fieldSpec — fieldSpec

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/sections/SCRSC-ITEM-LST-2/SCREL-ELEM-LST-1/fieldSpec/content — content
<!-- field: fieldName -->
```
quantity
```

<!-- field: dataType -->
```
Integer
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions — actions

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-1 — ScreenActionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-1/content — content
<!-- field: actionId -->
```
SCR-02-ACT-1
```

<!-- field: actionName -->
```
Amend line
```

<!-- field: actionType -->
```
Submit
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-1/visual — visual

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-1/visual/content — content
<!-- field: labelResource -->
```
screen.order.action.amend
```

<!-- field: placement -->
```
Row
```

<!-- field: buttonStyle -->
```
Primary
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-2 — ScreenActionEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-2/content — content
<!-- field: actionId -->
```
SCR-02-ACT-2
```

<!-- field: actionName -->
```
Release hold
```

<!-- field: actionType -->
```
Submit
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-2/visual — visual

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/actions/SCRAC-ITEM-LST-2/visual/content — content
<!-- field: labelResource -->
```
screen.order.action.release
```

<!-- field: placement -->
```
Header
```

<!-- field: buttonStyle -->
```
Secondary
```

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/states — states

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/states/SCRST-ITEM-LST — items

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/states/SCRST-ITEM-LST-1 — ScreenStateEntry

###### SBP/experienceAndInterfaceDesign/screens/screenInventory/SCREN-ITEM-LST-2/states/SCRST-ITEM-LST-1/content — content
<!-- field: stateName -->
```
Amendment rejected
```

<!-- field: description -->
```
The new quantity failed validation or reservation.
```

<!-- field: messageResource -->
```
screen.order.amend.error
```

<!-- field: primaryActionLabel -->
```
Retry
```

<!-- field: primaryActionTarget -->
```
SCR-02-ACT-1
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

