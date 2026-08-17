# TomSpecs Project Flow — From Idea to Running System

**Quest:** tom_specs
**Status:** Active

---

## PF-DOC Document Information

### PF-DOC-PUR Purpose

This is the **overarching description of the process TomSpecs is embedded into**.
It defines how a system is created with the Tom Architecture — from the first
free-form project idea through specification, code specification, test
derivation, implementation, business acceptance and release — and how the
process continues once the system is in production.

It is a single consolidated reference covering:

| Aspect | Section |
|--------|---------|
| The phase flow and its artifacts | [PF-FLW](#pf-flw-the-flow-at-a-glance), [PF-PHA](#pf-pha-the-phases) |
| The quality gates between phases | [PF-GAT](#pf-gat-quality-gates) |
| Quality work *inside* a phase | [PF-ITR](#pf-itr-quality-inside-a-phase) |
| Who does what | [PF-ROL](#pf-rol-roles) |
| The tooling that carries the process | [PF-TOO](#pf-too-tooling) |
| Issue and bug-fix handling during delivery | [PF-ISS](#pf-iss-issues-and-bug-fixes) |
| Life after release — upgrade cycles | [PF-UPG](#pf-upg-upgrade-cycles) |

### PF-DOC-SCP Scope

**In scope:** the end-to-end process, its phases, artifacts, gates, roles and
tooling; the per-deliverable and per-document quality loops; the issue workflow;
the upgrade cycle.

**Out of scope:**

- The **structure of the specification object model** — that is
  [`tom_specs_model/doc/som_multiplatform_spec_model.md`](som_multiplatform_spec_model.md),
  the SOM authority.
- The **DocSpecs document format** itself — see
  [`doc_specs_specification.md`](../../../../_ai/quests/doc_specs/doc_specs_specification.md).
- The **CodeSpecs annotation framework and part catalogue** — see
  [`codespecs_mapping.md`](codespecs_mapping.md).
- **Language-level coding standards** — see `_copilot_guidelines/dart/`.

### PF-DOC-BAS Basis

TomSpecs is a Tom-Architecture-native process. It assumes:

- **Client:** Flutter (cross-platform UI)
- **Server:** Dart (backend services)
- **Database:** SQL (relational persistence)
- **Standard components:** Tom Core, Tom UAM (user/access management),
  Tom Deploy, Tom Provisioning, Tom SQM

The architecture being **fixed** is what makes the process work: because every
system is built from the same component set with the same layering, the
specification can be mapped mechanically onto code, and the space in which an
implementer can go wrong is small and well understood.

### PF-DOC-PRI Key Principles

| Principle | Description |
|-----------|-------------|
| **Traceability** | Every implementation element traces back to a business requirement, and every requirement forward to code and tests |
| **Test-first** | Tests are derived from the specification *before* implementation begins |
| **Incremental** | Each piece is implemented and verified before the next is started |
| **Code-as-spec** | CodeSpecs bridge documentation and implementation: a compiling, non-executing skeleton is itself a specification artifact |
| **Model-as-truth** | The specification object model (SOM) is the source of truth; markdown and DocSpecs files are renderings of it |
| **AI-driven, human-gated** | AI agents produce and review the artifacts; humans decide at the gates |
| **Iterative, not linear** | Deliverables loop until quality is met; phases can be re-entered when a later phase reveals an upstream defect |

---

## PF-FLW The Flow at a Glance

### PF-FLW-OVE Eight Phases, Eight Gates

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        TOMSPECS PROJECT FLOW                                 │
└──────────────────────────────────────────────────────────────────────────────┘

  ①  PROJECT IDEA (PI)
     notes · documents · videos · transcripts · meeting minutes
        │
        ▼  ══ G1 ══  idea captured and confirmed
  ②  SOLUTION BLUEPRINT (SBP)
     one DocSpecs document, filled mostly by AI, strict schema
        │
        ▼  ══ G2 ══  human review (business)
  ③  DETAILED SPECIFICATIONS (DocSpecs)
     CLA · TOM · IFM · RSP · ISC · ATS · IIS · SAS · XDS · QAP · DRM · TRP
     derived from the SBP section mapping, with far more detail
        │
        ▼  ══ G3 ══  human review (business)
  ④  CODESPECS
     skeletal application: screens, forms, fields+types, validations,
     layouts, REST APIs / server methods, persistence classes, DB schema
        │
        ▼  ══ G4 ══  human review (software engineering), AI+script supported
  ⑤  TEST DERIVATION
     test suite for all parts of the system, derived from CodeSpecs code
     combined with the Phase-3 detailed specification
        │
        ▼  ══ G5 ══  human review (software engineering), AI+script supported
  ⑥  IMPLEMENTATION
     business code written until all tests pass
        │
        ▼  ══ G6 ══  human review (software engineering): code quality + security
  ⑦  APPLICATION CANDIDATE
     deployed to a test environment, tested per the QAP quality plan
        │
        ▼  ══ G7 ══  business acceptance, human sign-off (hard requirement)
  ⑧  RELEASE CANDIDATE
     ready for deployment · optional multi-tenant provisioning
        │
        ▼  ══ G8 ══  deployment readiness
     PRODUCTION  ──►  upgrade cycles (PF-UPG)
```

**Every gate can fail.** A failed gate returns the work to the current phase for
remediation, and only the failed criteria are re-checked on re-evaluation. This
rework loop is the normal case, not the exception.

### PF-FLW-ART The Artifact Chain

| # | Phase | Primary artifact | Form |
|---|-------|-----------------|------|
| 1 | Project Idea | PI | Free-form — notes, transcripts, sketches |
| 2 | Solution Blueprint | `SBP` (D00) | One DocSpecs document / SOM tree |
| 3 | Detailed Specifications | 12 documents (below) | DocSpecs documents / SOM trees |
| 4 | CodeSpecs | `<app>_codespec_{shared,client,server}` | Dart code that compiles, does not execute |
| 5 | Test Derivation | Test suite | Dart test files, initially RED/SKIP |
| 6 | Implementation | `<app>_{shared,client,server}` | Working Dart/Flutter code |
| 7 | Application Candidate | Deployed test system + test results | Deployment + QAP evidence |
| 8 | Release Candidate | Production deployment | Deployment + provisioning config |

### PF-FLW-DOC The Specification Document Set

Phase 2 produces **one** document; Phase 3 expands it into **twelve**. Each is a
root of the specification object model with a three-letter section ID.

| ID | Class | Document | Phase |
|----|-------|----------|-------|
| `SBP` | `D00SolutionBlueprint` | Solution Blueprint | 2 |
| `CLA` | `D01CurrentLandscapeAssessment` | Current Landscape Assessment | 3 |
| `TOM` | `D02TargetOperatingModel` | Target Operating Model | 3 |
| `IFM` | `D03InformationModel` | Information Model | 3 |
| `RSP` | `D04RequirementsSpecification` | Requirements Specification | 3 |
| `ISC` | `D05InteractionScenarios` | Interaction Scenarios | 3 |
| `ATS` | `D06ArchitectureTechnologySpecification` | Architecture & Technology Specification | 3 |
| `IIS` | `D07IntegrationInterfaceSpecification` | Integration & Interface Specification | 3 |
| `SAS` | `D08SecurityAccessSpecification` | Security & Access Specification | 3 |
| `XDS` | `D09ExperienceDesignSpecification` | Experience Design Specification | 3 |
| `QAP` | `D10QualityAcceptancePlan` | Quality & Acceptance Plan | 3 |
| `DRM` | `D11DeliveryRoadmap` | Delivery Roadmap | 3 |
| `TRP` | `D12TransitionRolloutPlan` | Transition & Rollout Plan | 3 |
| `CGP` | `D13CodeSpecsProjection` | CodeSpecs Generation Projection | 4 (derived) |

`CGP` is not authored: it is a **projection** over the other roots that routes
each section to its CodeSpecs part and deployment locus. See
[`codespecs_mapping.md`](codespecs_mapping.md) §9.

### PF-FLW-SBP The Solution Blueprint as the Expansion Point

The Solution Blueprint is the hinge of the whole process. It is a single,
schema-bound document that covers the entire system at overview depth. Every
Phase-3 document is **derived from a defined region of it**:

```
                       ┌──────────────────────────┐
                       │   SBP Solution Blueprint │
                       │   (overview depth)       │
                       └────────────┬─────────────┘
                                    │  section mapping
       ┌──────────┬──────────┬──────┴───┬──────────┬──────────┐
       ▼          ▼          ▼          ▼          ▼          ▼
     CLA        TOM        IFM        RSP        ISC        ATS
       ▼          ▼          ▼          ▼          ▼          ▼
     IIS        SAS        XDS        QAP        DRM        TRP
                       (specification depth)
```

The mapping is not editorial — it is encoded in the object model with
`@MapsTo` (SBP section → target document) and `@DetailedIn` (which target
document elaborates a given SBP subtree), and is enforced structurally by the
model validator. See
[`tom_specs_model_rules.md`](tom_specs_model_rules.md)
§10.2.

**Consequence for the process:** Phase 3 is not "write twelve documents from
scratch". It is "expand each mapped SBP region to specification depth", which is
a bounded, checkable, largely AI-executable task — and it is why the G2 gate on
the Blueprint matters so much. A defect in the SBP propagates into twelve
documents.

---

## PF-PHA The Phases

Each phase is described with **Purpose · Input · Activities · Output · Gate**.
The gate criteria themselves are in [PF-GAT](#pf-gat-quality-gates).

### PF-PHA-P1 Phase 1 — Project Idea (PI)

**Purpose.** Capture the initial vision completely, even where it is incomplete,
vague or self-contradictory. Nothing is filtered at this stage; filtering is the
Blueprint's job.

**Input.** A business decision that a system is needed, plus whatever exists:
stakeholder interviews, notes, sketches, existing documentation, recordings and
transcripts, meeting minutes, descriptions of the systems or processes being
replaced.

**Activities.**

1. **Gather** — interview stakeholders, collect existing material in any form
2. **Document** — write down all ideas, including the conflicting ones
3. **Bound** — rough in-scope / out-of-scope boundaries
4. **Identify** — who uses the system, who owns it, who runs it

**Output.** A free-form Project Idea document — no structured format required.
It should convey what problem the system solves, who the users are, the rough
feature set, known constraints, and any timeline or budget expectations.

**Gate G1** — the idea is captured in writing, stakeholders confirm the capture
is complete, and there are no unresolved clarifications blocking structured
refinement.

### PF-PHA-P2 Phase 2 — Solution Blueprint (SBP)

**Purpose.** Transform the free-form idea into a structured, schema-bound
overview of the whole system. This is the first binding definition of what will
be built.

**Input.** The Project Idea; stakeholder clarifications; domain material.

**Activities.**

1. **Fill the Blueprint** — AI populates the SBP sections from the PI material.
   This is largely an AI task: the model supplies the section structure, the
   content help and the field types, so the agent knows exactly what each
   section wants.
2. **Flag gaps** — every section the PI cannot answer is raised as an explicit
   clarification rather than being invented.
3. **Resolve with the business** — the human Business Analyst and Project
   Manager answer the flagged questions; answers flow back into the Blueprint.
4. **Iterate with quality review** — the specification quality role reviews each
   section against the quality criteria and drives rework until it holds
   (see [PF-ITR-DEL](#pf-itr-del-per-deliverable-quality-loop)).

**Output.** A complete `SBP` document: a DocSpecs document backed by the SOM
`D00SolutionBlueprint` tree, covering scope, stakeholders, landscape position,
target operating model, information model, requirements, architecture,
integrations, security, experience design, quality plan, roadmap and rollout —
all at **overview depth**.

**Gate G2** — human review by the **business** side. This gate is where the
business confirms that what was understood is what was meant.

### PF-PHA-P3 Phase 3 — Detailed Specifications (DocSpecs)

**Purpose.** Expand the Blueprint into the twelve specification documents, each
at the depth needed to derive code and tests without further interpretation.

**Input.** The accepted `SBP`; the SBP → target-document section mapping; the
clarifications from Phase 2.

**Activities.**

1. **Expand per mapped region** — for each `@MapsTo` target, generate the target
   document's sections from the corresponding SBP subtree, adding the detail the
   Blueprint deliberately omitted.
2. **Work the dependency order** — documents are not independent. `RSP` feeds
   `TOM`, `ISC`, `SAS` and `QAP`; `IFM` feeds `ATS` and the persistence design;
   `IIS` needs the external-system inventory from `CLA`. Producing a derived
   document routinely reveals a gap in its basis (see
   [PF-ITR-DEP](#pf-itr-dep-dependency-driven-iteration)).
3. **Resolve cross-document consistency** — same concept, same term, same value,
   everywhere.
4. **Maintain traceability** — every requirement carries an ID; every downstream
   element references it.
5. **Iterate each document through its quality sequence** — DRAFT → REVIEWED →
   VERIFIED → ACCEPTED (see
   [PF-ITR-DSQ](#pf-itr-dsq-document-quality-sequence)).

**Output.** Twelve accepted DocSpecs documents (`CLA`, `TOM`, `IFM`, `RSP`,
`ISC`, `ATS`, `IIS`, `SAS`, `XDS`, `QAP`, `DRM`, `TRP`), consistent with each
other and with the Blueprint.

**Gate G3** — human review by the **business** side again, now against the
detailed specification. Supported by automated schema validation,
cross-reference resolution and consistency checking.

### PF-PHA-P4 Phase 4 — CodeSpecs

**Purpose.** Turn the specification into **code**: a skeletal application that
**compiles but does not execute**. At the end of Phase 4 the shape of the entire
system exists in the type system.

**Input.** All twelve Phase-3 documents, plus the `CGP` projection that routes
each section to its CodeSpecs part and deployment locus.

**What a CodeSpec is.** An ordinary class built on an existing `tom_core`-family
class, marked with `Cs*` annotations. There is no separate CodeSpecs document
model and no `Cs*` base classes. Every class a CodeSpec instantiates comes from
`tom_core_kernel` / `tom_core_flutter` / `tom_core_server` / `tom_core_d4rt` /
`tom_flutter_ui`, with `tom_core_codespecs` filling only the genuine gaps. See
[`codespecs_mapping.md`](codespecs_mapping.md) §1.1.

**What is specified.**

| Area | Specified as |
|------|--------------|
| Screens and navigation | Screen, route and screen-flow CodeSpecs |
| Forms, fields and types | Form and field CodeSpecs with declared types |
| Validations | Validation-rule CodeSpecs, shared where both sides need them |
| Screen layouts | Layout CodeSpecs, separated so they can be overridden by hand |
| Client actions | Action CodeSpecs binding user interactions to server calls |
| REST API / server methods | Endpoint CodeSpecs with request/response contract types |
| Persistence classes | Database object-model CodeSpecs |
| Database schema | Table/column definitions plus the migration skeleton tree |
| Errors and messages | Error-result and message-key CodeSpecs |
| Authorization | Authorization CodeSpecs derived from `SAS` |

**How the code is produced.** Phase 4 is neither a compiler pass nor free
authoring. It runs in **two passes with a fixed boundary** between them
([`codespecs_mapping.md`](codespecs_mapping.md) §1.1, §1.1.1 — pillar (e) and
the production contract it fixes):

| Pass | Performed by | Produces |
|------|--------------|----------|
| **1 · Extract** | The **extract generator** — a `spec_codespecs_extract` surface present in all nine SOM runtimes, so Phase 4 is not a Dart-only phase | One bounded, cited **extract** per CodeSpecs area, holding every SOM field the section's `@CodeSpecKind` routes there, verbatim and with its provenance: `<CE-CODE>.extract.yaml` (the artifact of record) plus a rendered `.extract.md`, under `<spec-root>/generated-doc/codespecs_extracts/` |
| **2 · Author** | The **authoring agent** — one prompt pass per **authoring step**, working from that step's extract(s) alone and walking the thirty-one steps in [`codespecs_mapping.md`](codespecs_mapping.md) §4.4.6's order, so nothing is written before what it cites | The CodeSpecs Dart, written against [`codespecs_derivation_contract.md`](codespecs_derivation_contract.md), which is normative for it |

The generator may copy and index; it may not summarise, rephrase, compose a
sentence out of field values, or choose a name. The agent makes every judgement
natural-language input requires, and only where the derivation contract leaves
one open. The split exists because the two halves fail differently: a mechanical
rule applied to prose invents structure that is not there, and an author handed
the whole specification reads the wrong parts of it.

**Phase 4 has a gate at its start as well as at its end.** G4 below reviews the
output; the **starting prompt** ([`codespecs_prompt.md`](codespecs_prompt.md))
reviews the input, as its own first act and before any todo is created. It runs a
mechanical tier — the document is complete against its schema *and* valid under
the runtime instance-tier validator, the routing is total, every required
annotation argument has a populated source — and then asks, per CodeSpecs area,
whether that area's extract alone suffices to author it, answering `sufficient`,
`not applicable` or `insufficient` with the section named that should have
carried each missing input. The reason it sits before Phase 4 rather than inside
G4 is that a specification with holes does not produce code with holes: it
produces code with *inventions*, and by G4 the invention is already something
Phase 5 could derive tests from.

**Where the specification does not carry what a derivation needs**, the outcome
is neither an invention nor a silent omission: it is a `decision-needed` todo
that pauses the run. The generated todo tree has four levels — open questions,
scaffolding, per authoring step, per specification element — and the open questions run
first and to exhaustion, which is the mechanism by which an underspecified
project stops Phase 4 instead of being guessed through. Each level's generation
rule, and the criteria under which a generated todo is born blocked rather than
runnable, are [`codespecs_mapping.md`](codespecs_mapping.md) §1.1.3's; the run
procedure that instantiates them is §1.1.2 of `codespecs_mapping.md`.

**Output — three generated projects**, split by deployment locus:

| Project | Holds |
|---------|-------|
| `<app>_codespec_shared` | The contract both sides depend on: API request/response types, error results, shared enums, message keys, shared validation rules |
| `<app>_codespec_client` | Client-only: elements, forms, layouts, actions, screens, state, navigation, client config, design system |
| `<app>_codespec_server` | Server-only: services, database, API handlers, authorization, configuration, migrations, jobs |

**Gate G4** — human review by **software engineers**, with strong AI and script
support: coverage of every specification section, absence of ambiguity markers,
validity of cross-references, and implementability.

Because pass 2 has a judging producer, G4 reviews **the boundary as well as the
output**: that the extract copied rather than composed, that the trio obeys the
derivation contract, that it is what the contract determines rather than what an
author preferred, and that no open question was closed by an assumption in the
code instead of an answer in the specification. All four are mechanised — see
PF-GAT-G4 for the criteria and their check methods. What is left to the human
reviewer is the judgement no tool can make: whether the skeleton is a *faithful*
reading of the specification, and whether it is implementable.

### PF-PHA-P5 Phase 5 — Test Derivation

**Purpose.** Produce the test suite that defines "done" for every part of the
system — **before** any business logic is written.

**Input.** The CodeSpecs code from Phase 4 **combined with** the Phase-3 detailed
specification. Neither alone is sufficient: the CodeSpecs supply the surface
(what exists, with what types), the specification supplies the semantics (what
it must do, at what boundaries, with what errors).

**Activities.**

1. **Derive acceptance tests** from `ISC` interaction scenarios and the `QAP`
2. **Derive process tests** from the `TOM` target operating model
3. **Derive boundary tests** from `RSP` requirements and constraints
4. **Derive authorization tests** from `SAS`
5. **Derive data tests** from `IFM`
6. **Derive integration tests** from `IIS` external-system interactions
7. **Map every test to its CodeSpec element and source requirement**

**Output.** Test files covering every CodeSpec element. All tests initially
**FAIL or SKIP** — there is no implementation yet. A test baseline is recorded
for Phase 6.

**Gate G5** — human review by **software engineers** for **completeness and
correctness** of the suite, with strong AI and script support. Complete coverage
matters more here than elegance: a missing test is a missing requirement.

### PF-PHA-P6 Phase 6 — Implementation

**Purpose.** Implement the system until all tests pass.

**Input.** CodeSpec elements (Phase 4), derived tests (Phase 5), dependency
analysis.

**Implementation order.** Dependencies determine the sequence:

```
    Level 1: Database Schema        (no dependencies)
         ▼
    Level 2: Data Models            (depends on schema)
         ▼
    Level 3: Server Endpoints       (depends on data models)
         ▼
    Level 4: UI Data Models         (depends on server interface)
         ▼
    Level 5: UI Actions             (depends on UI data models, server)
         ▼
    Level 6: UI Elements & Layout   (depends on UI actions)
```

**Per-element loop.** For each CodeSpec element:

1. **Review** the CodeSpec annotations and the linked Phase-3 sections
2. **Run tests** — confirm RED. A test that passes before implementation is a
   defective test, not a head start.
3. **Implement** the minimum that makes them pass
4. **Verify** — GREEN
5. **Refactor** while staying GREEN
6. **Add unit tests** for implementation details the derived tests do not cover
7. **Commit** as a checkpoint

**Two test levels.**

| Level | Origin | Verifies | Owner |
|-------|--------|----------|-------|
| **Business tests** | Phase 5, derived from the specification | That the system does what the **business** wants | Business / test management |
| **Unit tests** | Phase 6, written during implementation | That the code does what the **developer** intended | Developer |

```
                    ┌───────────────────┐
                    │  Business Tests   │  ◄── derived from specs (Phase 5)
                    │  (Acceptance)     │      verify business requirements
                    └─────────┬─────────┘
                ┌─────────────┴─────────────┐
                │     Integration Tests     │  ◄── end-to-end workflows
                └─────────────┬─────────────┘
      ┌───────────────────────┴───────────────────────┐
      │                 Unit Tests                    │  ◄── developer tests (Phase 6)
      └───────────────────────────────────────────────┘
```

**Output.** A fully implemented system with business tests and unit tests
passing, and a clean static-analysis result.

**Gate G6** — human review by **software engineers** for **code quality and
security**, with strong AI and script support. Security review is materially
cheaper here than in conventional projects: because the Tom Framework supplies
authentication, authorization, transport, persistence and input handling, only
**business code** is written by hand, and the surface on which a security defect
can be introduced during generation is correspondingly small.

### PF-PHA-P7 Phase 7 — Application Candidate

**Purpose.** Prove the implemented system against the business's own acceptance
criteria in a real deployment.

Once G6 passes, the implementation is designated an **Application Candidate**
and deployed for testing.

**Input.** The implemented system, the `QAP` Quality & Acceptance Plan, the
`TRP` transition plan, deployment configuration.

**Activities.**

1. **Deploy to a test environment** using Tom Deploy
2. **Execute the QAP test programme** — the business-defined scenarios, in the
   business's own terms
3. **Record results** — pass/fail plus defects, in the evidence store
4. **Fix defects** — failures return to Phase 6 through the issue workflow
   ([PF-ISS](#pf-iss-issues-and-bug-fixes))
5. **Verify user flows** end to end, including the `IIS` external integrations
6. **Verify non-functional targets** — performance, availability, capacity —
   against the `RSP` and `ATS` numbers
7. **Derive user documentation** from the CodeSpecs configuration and
   preferences surfaces
8. **Obtain acceptance sign-off** from the business

**Output.** A tested Application Candidate, a completed QAP result set, business
acceptance documentation, and user/administrator documentation.

**Gate G7** — business acceptance. **This is the one gate where human sign-off is
a hard requirement.** The AI agents assemble every piece of evidence and produce
a recommendation, but the go/no-go is a human decision.

### PF-PHA-P8 Phase 8 — Release Candidate and Deployment

**Purpose.** Turn the accepted Application Candidate into a **Release
Candidate** that is ready for production deployment, and — where the system is
offered as a service — make it provisionable per client.

**Input.** The accepted Application Candidate; the `TRP` rollout plan;
multi-tenancy requirements from the `SBP` / `ATS`.

**Activities — release readiness (always).**

1. **Production deployment configuration** validated for every environment
2. **Rollback procedure** defined and actually tested
3. **Monitoring and alerting** configured — dashboards, alert rules, log routing
4. **Security hardening** completed against the production checklist
5. **Data migration** scripts verified against production-like data
6. **Rollout executed** per `TRP` — controlled rollout with rollback capability
7. **Go-live support** — Tom UAM integration active, internationalization in
   place, standard observability running

**Activities — multi-tenant provisioning (optional).**

1. **Tom Provisioning integration** — per-client database separation or
   isolation, client-specific configuration, automated provisioning on
   subscription
2. **Tom SQM integration** — subscription plans, per-plan quotas, user limits,
   plan-specific feature toggles
3. **Subscriber model** wired up:

```
    Subscriber (Company)
         ├── Subscription
         │       ├── Plan (features, quotas)
         │       └── Billing
         └── Users (1..n)
                 ├── Roles
                 └── Preferences
```

**Output.** A Release Candidate deployed to production; where applicable, a
system available for per-client provisioning with automated subscriber
onboarding.

**Gate G8** — deployment readiness. After it passes, the system leaves the
creation process and enters **upgrade cycles** ([PF-UPG](#pf-upg-upgrade-cycles)).
The `DRM` Delivery Roadmap defines when that transition occurs.

---

## PF-GAT Quality Gates

### PF-GAT-MOD The Gate Model

Quality gates are **mandatory checkpoints between phases**. An AI orchestrator
agent evaluates every gate criterion, collects the evidence, and produces a gate
report. The gate either passes — work proceeds to the next phase — or fails, and
work returns to the current phase for rework.

```
┌────────────────────────────────────────────────────────────────────┐
│                     QUALITY GATE FLOW                              │
│                                                                    │
│  Phase N Work ──► Trigger Gate ──► Orchestrator Collects Evidence  │
│                                         │                          │
│                                    ┌────┴────┐                     │
│                                    ▼         ▼                     │
│                              All criteria  One or more             │
│                                 met?       criteria fail           │
│                                    │              │                │
│                                    ▼              ▼                │
│                              GATE PASS     GATE FAIL               │
│                              ──► Phase N+1  ──► Remediation        │
│                                              ──► Re-evaluate       │
│                                                                    │
│  Re-evaluation: only failed criteria are re-checked.               │
│  After 3 consecutive failures on the same criterion,               │
│  escalation to human review is triggered.                          │
└────────────────────────────────────────────────────────────────────┘
```

**Gate failure is normal.** The gate exists to catch problems where they are
cheap. A gate that never fails is not evidence of quality — it is evidence that
the criteria are too weak.

**Rework scope.** A failed gate returns work to the **current** phase. When the
root cause lies in an **earlier** phase, the process re-enters that phase
instead — see [PF-ITR-REE](#pf-itr-ree-phase-re-entry).

### PF-GAT-PRI Framework Principles

1. **Automated verification over manual review** — every check that can be
   expressed as a rule is implemented as an automated agent task
2. **Prompt-driven consistency** — checks use versioned prompt templates so the
   evaluation criteria are identical across runs
3. **Repeated execution** — checks are designed to run many times (on change, on
   schedule, on gate trigger) with deterministic results
4. **Structured output** — every check produces machine-readable results
   (JSON/YAML) alongside a human-readable summary
5. **Layered defence** — several agents check different dimensions; no single
   check is a single point of failure
6. **Evidence-based decisions** — pass/fail rests on collected evidence, never on
   subjective assessment

### PF-GAT-OBJ Quality Objectives

| Objective | Target | Measurement |
|-----------|--------|-------------|
| Specification completeness | 100% required sections filled | DocSpecs schema validation |
| Cross-reference integrity | 0 broken references | Link resolution check |
| Spec → CodeSpec traceability | 100% of spec sections covered | `CGP` projection coverage |
| Test derivation coverage | 100% of CodeSpecs have tests | Test mapping analysis |
| Code quality | 0 analyzer errors, 0 warnings | `dart analyze` + workspace lints |
| Test pass rate | 100% before gate | Test execution results |
| Security compliance | 0 critical findings | Security pattern analysis |
| Documentation freshness | Docs match code | Doc–code drift detection |

### PF-GAT-AGE Agent Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    QUALITY AGENT ARCHITECTURE                       │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                   ORCHESTRATOR AGENT                          │  │
│  │  - Triggers quality checks per phase / gate                   │  │
│  │  - Collects results from specialist agents                    │  │
│  │  - Produces the aggregated quality report                     │  │
│  │  - Makes the gate pass/fail recommendation                    │  │
│  └──────────┬────────────────────────────────────────────────────┘  │
│             │                                                       │
│    ┌────────┼────────┬────────────┬────────────┬──────────┐         │
│    ▼        ▼        ▼            ▼            ▼          ▼         │
│ ┌──────┐┌──────┐ ┌──────┐    ┌──────┐    ┌──────┐   ┌──────┐        │
│ │ Spec ││Cross ││ Code │    │ Test │    │Secur.│   │ Doc  │        │
│ │Valid.││ Ref  ││Quality│    │Cover.│    │Audit │   │ Sync │        │
│ └──────┘└──────┘ └──────┘    └──────┘    └──────┘   └──────┘        │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │               EVIDENCE STORE (JSON/YAML files)                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              QUALITY DASHBOARD (generated report)              │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

Two families of measure run continuously alongside the gates:

- **Constructive** — standards enforcement, template readiness verification,
  generation guidelines, pre-generation review. These prevent defects.
- **Analytical** — static analysis, multi-pass AI code review (spec fidelity,
  code quality, security, performance, maintainability), traceability
  verification, test execution and failure diagnosis, security audit. These
  detect defects.

### PF-GAT-G1 G1 — Project Idea Captured

**Transition:** Phase 1 → Phase 2 · **Review type:** business (light)

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Idea document exists | File existence | A PI document exists with meaningful content |
| Problem statement present | Content check | What the system solves is stated |
| Users and stakeholders named | Content check | At least the primary user groups and the owner are identified |
| Rough scope stated | Content check | In-scope and out-of-scope boundaries are sketched |
| Sources recorded | Content check | The material the idea was drawn from is listed and retrievable |
| No blocking clarifications | Clarification check | No open items in `_ai/clarifications/` that prevent Blueprint work |

### PF-GAT-G2 G2 — Solution Blueprint Complete

**Transition:** Phase 2 → Phase 3 · **Review type:** business (human review of the document)

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Blueprint schema-valid | DocSpecs validation | `SBP` validates against its schema; no empty required sections |
| Scope defined | Content check | System boundaries, in/out of scope, and external actors are stated |
| Stakeholders identified | Content check | Each stakeholder has a role and an interest |
| Requirements traceable | Traceability check | Every requirement has an ID and a stated source |
| System context documented | Content check | Landscape position plus the external-system inventory |
| Non-functional targets set | Content check | Performance, security, availability and capacity targets are numeric |
| Integrations identified | Content check | Every external system interaction is at least named and typed |
| Architecture decisions recorded | Content check | Key technology and pattern decisions are stated with rationale |
| Delivery roadmap drafted | Content check | Initial phase structure with goals and gate criteria |
| Business review recorded | Sign-off check | The business review of the Blueprint is documented |

**Why this gate is heavy.** Twelve documents are derived from this one. Every
defect that survives G2 is multiplied by the Phase-3 expansion.

### PF-GAT-G3 G3 — Detailed Specifications Complete

**Transition:** Phase 3 → Phase 4 · **Review type:** business (human review of the specification)

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| All required documents present | Document-set check | Every document the project's scope requires exists |
| All documents schema-valid | DocSpecs validation | Each document validates against its schema |
| All documents ACCEPTED | Status board | Every document reached ACCEPTED in its own quality sequence |
| Cross-references resolved | Cross-reference agent | 0 broken references |
| No placeholder sections | Content check | No required section contains only placeholder text |
| Blueprint coverage complete | Mapping check | Every `@MapsTo` region of the `SBP` is expanded in its target document |
| Integrations fully specified | Content check | Every `IIS` interaction has protocol, payload, error handling and retry semantics |
| Roadmap phases fully defined | Content check | Every `DRM` phase has goals, deliverables and gate criteria |
| Acceptance plan complete | Content check | `QAP` defines the acceptance scenarios and their pass criteria |
| Cross-document consistency | Consistency check | No contradictions between related sections |

**Consistency check.** A dedicated agent compares related sections across
documents and reports four classes of defect:

| Class | Example |
|-------|---------|
| **Value contradiction** | "supports 1000 users" in one document, "500 users" in another |
| **Scope contradiction** | a feature declared in scope in one document and out of scope in another |
| **Missing coverage** | `IIS` lists an external system the `CLA` inventory does not mention |
| **Terminology drift** | the same concept named differently in different documents |

### PF-GAT-G4 G4 — CodeSpecs Complete

**Transition:** Phase 4 → Phase 5 · **Review type:** software engineering, AI+script supported

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Skeleton compiles | Build | All three CodeSpec projects compile; static analysis clean |
| Specification coverage complete | Traceability agent | 100% of spec sections carrying a `@CodeSpecKind` have CodeSpecs code |
| Back-trace complete | Traceability agent | Every CodeSpec carries a `@DocSpec` back-reference to its source section(s) |
| Built on `tom_core` | Structure check | Every class a CodeSpec instantiates is a `tom_core`-family class |
| Locus split correct | Structure check | Each part sits in the shared / client / server project the `CGP` projection assigns |
| No ambiguity markers | Pattern scan | No TODO / TBD / FIXME in CodeSpecs code |
| Cross-references valid | Cross-reference agent | Every referenced type and member exists |
| API contracts complete | Content check | Every endpoint has request, response and error-result types |
| Persistence complete | Content check | Every data entity has table and column definitions plus a migration skeleton |
| Validations declared | Content check | Every field constraint from `RSP` / `IFM` has a validation rule |
| Authorization declared | Content check | Every `SAS` rule maps to an authorization CodeSpec |
| Implementable | Feasibility review | Each CodeSpec has an unambiguous class/method/property shape |
| Trio is self-sufficient | Extract ↔ trio comparison | Every fact in every area extract is carried by the trio — as an annotation argument, a doc comment or a body — so Phases 5 and 6 read code, not documents (`codespecs_mapping.md` §9.6) |
| Extracts are verbatim | Extract check | Every scalar in every area extract occurs character-for-character in the source document — pass 1 copied and indexed, it did not compose |
| Derivation contract satisfied | `validate_codespecs.dart` | No violation of the `codespecs_derivation_contract.md` §6 checks: no invented name, composed comment, fabricated value, unresolved reference or forbidden statement |
| Output is determined, not preferred | `validate_codespecs.dart` (two runs) | Two production runs over one model yield the same file set and byte-identical contents |
| Open questions closed in the specification | Todo review | No `decision-needed` todo of the run's open-question level is left standing, and each was closed by an answer in the specification rather than an assumption in the code |

The last four are what PF-PHA-P4's two-pass production model makes checkable:
pass 1 is verified by comparing extracts against their source, pass 2 by the
validator and by the determinism the derivation contract obliges it to.

### PF-GAT-G5 G5 — Test Suite Derived

**Transition:** Phase 5 → Phase 6 · **Review type:** software engineering, AI+script supported

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Every CodeSpec has tests | Traceability agent | 100% CodeSpec → test coverage |
| Every requirement has tests | Traceability agent | Every `RSP` requirement is reachable from at least one test |
| Boundary conditions covered | Test analysis | Each specified limit and constraint has a test at the boundary |
| Error paths covered | Test analysis | Each specified error and failure mode has a test |
| Authorization covered | Test analysis | Each `SAS` rule has both a permitted and a denied case |
| Integration scenarios defined | Content check | Every `IIS` interaction has an integration test |
| Acceptance scenarios covered | Content check | Every `QAP` scenario has a corresponding test |
| Tests currently RED | Test execution | All derived tests fail or skip — none passes before implementation |
| Conventions followed | Standards agent | Test file naming, grouping and ID conventions are met |
| No redundant coverage | Redundancy check | Tests do not unnecessarily overlap |
| Baseline recorded | Baseline check | A test baseline exists for Phase 6 comparison |

### PF-GAT-G6 G6 — Implementation Complete

**Transition:** Phase 6 → Phase 7 · **Review type:** software engineering (code quality + security), AI+script supported

The most comprehensive gate — it evaluates the actual code.

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Static analysis clean | Static analysis agent | 0 errors, 0 warnings |
| Formatting clean | Formatter check | No formatting deviations |
| All tests pass | Test execution agent | 100% pass rate, business and unit |
| No regressions | Baseline comparison | No test that passed in the baseline now fails |
| Code review clear | Code review agent (multi-pass) | 0 MUST-FIX findings |
| Security audit clear | Security audit agent | 0 critical or high findings |
| Framework compliance | Structure check | No hand-rolled substitutes for Tom Framework services; no security-relevant workarounds |
| Traceability complete | Traceability agent | Unbroken chain requirement → spec section → CodeSpec → test → code |
| Documentation synced | Doc sync agent | No doc–code drift |
| No untracked markers | Pattern scan | 0 untracked TODO / FIXME |
| Coverage adequate | Coverage analysis | Line coverage above the project threshold (default 80%) |

**Execution order.** The orchestrator runs the checks fast-failure-first —
static analysis, tests, security audit, code review passes, traceability, doc
sync — but **runs them all even after the first failure**, so that one
remediation cycle addresses every finding instead of discovering them serially.

**Why the security criterion is tractable.** The Tom Framework owns
authentication, authorization enforcement, transport, serialization,
persistence access and input handling. Phase 6 writes **business code only**. It
is therefore virtually impossible to introduce a classic security defect during
generation — and the security audit can concentrate on the narrow band where
business logic can still leak data or bypass a rule.

### PF-GAT-G7 G7 — Business Acceptance Complete

**Transition:** Phase 7 → Phase 8 · **Review type:** business, **human sign-off is mandatory**

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Acceptance criteria met | Acceptance test agent | All `QAP` acceptance scenarios pass |
| User flows verified | Flow simulation | Every `ISC` scenario executes correctly end to end |
| Integrations verified | Integration test agent | Every `IIS` external integration verified against the real counterpart |
| Non-functional targets met | Performance test agent | Every `RSP` / `ATS` benchmark within target |
| Operability verified | Operations review | Monitoring, logging and support procedures are in place and usable |
| Documentation complete | Content check | User and administrator documentation exists and matches the delivered system |
| Open defects acceptable | Defect review | No open critical or high defect; remaining defects explicitly accepted |
| Human sign-off recorded | File check | A signed acceptance record exists |

**This is the only gate where human sign-off is a hard requirement.** The agents
assemble the evidence and recommend; the business decides.

### PF-GAT-G8 G8 — Release Readiness

**Transition:** Phase 8 → Production

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Deployment configuration valid | Config validation agent | Every environment configuration present and valid |
| Rollback tested | Deployment test | Rollback executed successfully in a rehearsal |
| Data migration verified | Migration test | Forward and backward migration tested with production-like data |
| Monitoring configured | Monitoring check | Alert rules, dashboards and log routing in place |
| Security hardening complete | Security audit (production mode) | Production security checklist passed |
| Rollout plan executable | Content check | `TRP` rollout steps, timing and communications are concrete |
| Tenant isolation verified *(multi-tenant only)* | Isolation test | All isolation tests pass |
| Provisioning verified *(multi-tenant only)* | Provisioning test | Sample subscriber provisioned and onboarded end to end |
| Quota enforcement verified *(multi-tenant only)* | SQM test | Plan quotas, user limits and feature toggles enforce correctly |

### PF-GAT-CHK Gate Checklists

The criteria tables above are the **generic** gate definition — they apply to
every TomSpecs project. In practice each gate is executed against a **checklist**
that expands each criterion into the concrete things to inspect.

| Level | Content | Lifecycle |
|-------|---------|-----------|
| **Gate criteria** (this document) | What must be true, and how it is measured | Stable across projects |
| **Generic checklist** | The standard inspection items per criterion | Maintained centrally; the starting point for every project |
| **Project checklist** | The generic checklist adapted to the project | Created at project start from the generic one, adjusted as the project's specifics emerge |

**Adaptation rules.**

1. A project checklist **starts** as a copy of the generic checklist.
2. Items may be **added** freely — project-specific regulatory checks, domain
   invariants, integration-partner requirements.
3. Items may be **narrowed** (made more specific) freely.
4. An item may only be **removed** with a recorded justification, approved by
   the gate's human approver. Removals are visible in the gate report.
5. Threshold values (coverage percentage, performance targets, acceptable defect
   counts) are **project parameters** set from the `QAP` and `ATS`, not
   hard-coded in the checklist.

Checklists are versioned alongside the prompt templates that execute them, so a
gate result can always be replayed against the criteria that were in force when
it was taken.

### PF-GAT-EVD Evidence Store

Every check writes structured evidence. Gate decisions are made from the store,
never from memory or narrative.

```
_ai/quality/
├── dashboard.md              # Generated quality dashboard
├── evidence/
│   ├── gates/                # G1_<timestamp>.yaml … one per gate evaluation
│   ├── static_analysis/
│   ├── test_results/
│   ├── code_reviews/
│   ├── security/
│   ├── traceability/
│   ├── documents/            # <doc_id>_accepted.yaml
│   └── issues/               # <issue_id>_closed.yaml
├── defects/                  # DEF-001.yaml, DEF-002.yaml, …
├── metrics/                  # weekly_<date>.yaml
├── prompts/                  # versioned check prompt templates
└── baselines/                # test_baseline_current.yaml
```

A gate report contains, for each criterion: its ID, its status, and the evidence
that produced the status. The overall result, the list of failed criteria, and
the required remediation are machine-readable; a markdown summary accompanies
them for human review.

**Reporting cadence.**

| Report | Produced by | When |
|--------|-------------|------|
| Gate report | Orchestrator agent | After each gate evaluation |
| Deliverable quality report | Quality role | After each quality loop iteration |
| Weekly quality report | Metrics agent | Weekly — trends, risks, recommended actions |
| Defect report | Generated from the defect store | On demand, grouped by severity and module |
| Security audit report | Security role | Per phase from Phase 3 onward |

### PF-GAT-DEF Defect Management

Defects are detected, diagnosed and frequently fixed by agents.

```
  ┌──────────┐   ┌───────────┐   ┌──────────┐   ┌──────────────┐
  │ Detected │──►│ Diagnosed │──►│Auto-Fixed│──►│  Verified    │
  │ by Agent │   │ by Agent  │   │ by Agent │   │  by Re-test  │
  └──────────┘   └─────┬─────┘   └──────────┘   └──────┬───────┘
                       │ cannot auto-diagnose          │
                       ▼                               │
                 ┌───────────┐                         │
                 │ Escalated │  human reviews,         │
                 │ to Human  │  provides direction     │
                 └─────┬─────┘                         │
                       ▼                               │
                 ┌───────────┐                         │
                 │ Agent Fix │  with human guidance    │
                 │ (guided)  │─────────────────────────┘
                 └───────────┘
```

**Escalation rules.**

| Condition | Action |
|-----------|--------|
| Diagnosis confidence HIGH | Auto-fix, verify by re-test |
| Diagnosis confidence MEDIUM | Auto-fix, flag the fix for human review |
| Diagnosis confidence LOW | Escalate with a diagnostic report; do not guess |
| Defect re-appears after a fix | Escalate — the real cause is deeper than the fix |
| Security defect, any severity | Auto-fix where possible, **always** flag for human review |
| 3+ related defects in one module | Escalate — this indicates a design problem, not bugs |

**Auto-collected defect metrics:** detection rate, auto-fix rate, fix
verification rate, mean time to detect, mean time to fix, recurrence rate, and
**escape rate** — defects found in a later phase that an earlier gate should
have caught. Escape rate is the primary feedback signal for tightening gate
criteria and checklists.

---

## PF-ITR Quality Inside a Phase

Gates evaluate whether a **phase** is complete. But a phase is not one lump of
work — it is a set of deliverables, each of which has its own quality loop. By
the time a gate is triggered, every deliverable behind it should already be
individually approved. The gate then verifies the *set*, not the parts.

### PF-ITR-PHI Hierarchical Iteration

The process operates at three iteration levels:

1. **Phase-level** — the overall flow runs 1 → 2 → … → 8, but a phase can be
   re-entered when a later phase exposes an upstream defect
2. **Deliverable-level** — inside a phase, each deliverable loops between its
   progress role and its quality role until the criteria are met
3. **Dependency-level** — producing a derived deliverable routinely reveals a
   gap in its basis, forcing an upstream correction and a downstream re-check

### PF-ITR-DEL Per-Deliverable Quality Loop

Every deliverable — a Blueprint section, a Phase-3 document, a CodeSpecs part, a
test group, an implementation unit — moves through this state machine:

```
                     ┌──────────┐
                     │  START   │
                     └────┬─────┘
                          ▼
                  ┌───────────────┐
          ┌──────►│  IN PROGRESS  │◄──────────────────────┐
          │       │  progress role│                       │
          │       │  creates /    │                       │
          │       │  updates      │                       │
          │       └───────┬───────┘                       │
          │               ▼                               │
          │       ┌───────────────┐                       │
          │       │  QUALITY      │                       │
          │       │  REVIEW       │                       │
          │       └───────┬───────┘                       │
          │        ┌──────┴──────┐                        │
          │   MUST-FIX      no MUST-FIX                   │
          │        │             │                        │
          │        ▼             ▼                        │
          │  ┌───────────┐  ┌────────────┐                │
          │  │  REWORK   │  │  HUMAN     │                │
          └──┤  progress │  │  REVIEW    │                │
             │  role     │  └──────┬─────┘                │
             └───────────┘         │                      │
                            ┌──────┴──────┐               │
                       APPROVED     CHANGES NEEDED ───────┘
                            ▼
                     ┌──────────┐
                     │ APPROVED │
                     └──────────┘
```

| State | Meaning | Who |
|-------|---------|-----|
| IN PROGRESS | Actively being created or updated | Progress role |
| QUALITY REVIEW | Being reviewed against the quality criteria | Quality role |
| REWORK | Feedback being addressed | Progress role |
| HUMAN REVIEW | Awaiting human sign-off or an answer to an escalation | PM / BA / SA |
| APPROVED | Meets all quality criteria and carries human sign-off where required | — |

**Four quality criteria** apply to every specification deliverable:

| Criterion | Question |
|-----------|----------|
| **Correct** | Does it accurately reflect the business intent? |
| **Consistent** | Does it contradict nothing, inside itself or against related deliverables? |
| **Comprehensive** | Are all aspects covered — edge cases, error paths, boundaries — with no unstated assumptions? |
| **Well-structured** | Does it follow the schema, use IDs correctly, and remain navigable? |

### PF-ITR-DSQ Document Quality Sequence

Within Phase 2 and Phase 3, each **document** passes through four states before
it can contribute to its phase gate:

```
  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐
  │  DRAFT   │──►│ REVIEWED │──►│ VERIFIED │──►│   ACCEPTED   │
  └──────────┘   └─────┬────┘   └─────┬────┘   └──────────────┘
       │               │              │
       ▼               ▼              ▼
  Schema valid?   Content quality  Cross-refs      All checks pass
  Structure ok?   Completeness     Consistency     Document ready
  No empty req.   Spec fidelity    Dependencies    for the phase gate
  sections?       Ambiguity scan   Doc-to-doc

  On failure at any stage: return to DRAFT with a findings report.
```

| Stage | Trigger | Checks |
|-------|---------|--------|
| **1 Draft validation** | Document created or significantly modified | DocSpecs schema validity; section-ID format; required sections present; no placeholder-only required sections; file naming |
| **2 Content review** | Draft validation passed | Completeness against the source; fidelity to the Blueprint region it expands; ambiguity scan; terminology consistency; specificity (is every statement testable?) |
| **3 Cross-document verification** | Content review passed | Cross-reference resolution; consistency with related documents; dependency satisfaction (does everything it relies on exist and agree?) |
| **4 Acceptance** | Verification passed | Human review where the phase requires it; acceptance record written to `_ai/quality/evidence/documents/` |

**Status board.** The orchestrator maintains a per-phase board:

```
# Document Status Board — Phase 3

| Document | Status   | Draft | Review | Verify | Accepted | Notes                    |
|----------|----------|-------|--------|--------|----------|--------------------------|
| CLA      | ACCEPTED | ✅    | ✅     | ✅     | ✅       |                          |
| RSP      | VERIFIED | ✅    | ✅     | ✅     | —        | Pending scope alignment  |
| TOM      | REVIEW   | ✅    | 🔄     | —      | —        | 2 ambiguities found      |
| IFM      | DRAFT    | 🔄    | —      | —      | —        | 3 empty sections         |
```

**The phase gate cannot pass until every required document is ACCEPTED.**

### PF-ITR-DEP Dependency-Driven Iteration

Deliverables depend on each other, and the dependency is not one-way in
practice: **creating a derived deliverable regularly reveals a defect in its
basis**.

```
  SBP Solution Blueprint
   │
   ├──► RSP Requirements ─────────────────────────────┐
   │     │                                             │
   │     ├──► TOM Target Operating Model ──┐           │
   │     │                                  │           │
   │     ├──► IFM Information Model ◄───────┤           │
   │     │        │                         │           │
   │     │        │  building IFM reveals   │           │
   │     │        │  a missing entity in RSP│           │
   │     │        ▼                         │           │
   │     │  RSP updated to add the entity ──┘           │
   │     │        │                                     │
   │     │        ▼                                     │
   │     │  TOM re-checked for impact                   │
   │     │                                              │
   │     ├──► SAS Security & Access ◄────────────────────┘
   │     │            needs the entity from RSP
   │     ├──► XDS Experience Design
   │     └──► ISC Interaction Scenarios
```

**Rule:** when a derived deliverable forces a change in its basis, every other
deliverable derived from the changed part of that basis must be re-verified. The
traceability data makes that impact set computable rather than a matter of
recall.

### PF-ITR-REE Phase Re-Entry

When a later phase exposes a defect belonging to an earlier phase, the process
re-enters that phase.

```
  Phase 3 (Specs)         Phase 4 (CodeSpecs)        Phase 5/6 (Tests, Impl.)
  ┌─────────────┐         ┌─────────────┐            ┌─────────────┐
  │  specify    │ ──────► │  codespec   │ ─────────► │  build      │
  └──────▲──────┘         └──────▲──────┘            └─────────────┘
         │                       │
         │  spec gap found       │  CodeSpec issue found
         │  during CodeSpec work │  during implementation
         └───── escalation ──────┴───── escalation
```

**Re-entry rules.**

1. The quality role that detects the issue escalates it to the quality role of
   the phase that owns it.
2. That role coordinates with its progress role to fix it.
3. The fix runs through the normal deliverable quality loop — review, rework,
   approve. It does not bypass the loop because it is "just a correction".
4. Once approved, the later phase resumes with the corrected input.
5. **Everything downstream of the changed element is re-verified**, not assumed
   still valid.
6. Re-entry is recorded: which phase, which deliverable, what changed, what was
   re-verified. Repeated re-entry into the same area is a signal that the gate
   which let the defect through needs tightening.

---

## PF-ROL Roles

### PF-ROL-PHI The Dual-Role Pattern

TomSpecs pairs, in every phase, a **progress role** that drives the deliverable
forward with a **quality role** that reviews, challenges and iterates with it
until the required quality is reached.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DUAL-ROLE PATTERN (per phase)                            │
│                                                                             │
│   ┌──────────────────────┐          ┌──────────────────────┐                │
│   │   PROGRESS ROLE      │ ◄──────► │   QUALITY ROLE       │                │
│   │                      │ iterate  │                      │                │
│   │   Creates, builds,   │          │   Reviews, checks,   │                │
│   │   advances the       │          │   challenges,        │                │
│   │   deliverable        │          │   validates quality  │                │
│   └──────────┬───────────┘          └──────────┬───────────┘                │
│              │        ┌─────────────┐          │                            │
│              └──────► │  HUMAN      │ ◄────────┘                            │
│                       │  COUNTERPART│                                       │
│                       │  consulted  │                                       │
│                       │  on ambigu- │                                       │
│                       │  ity, contra│                                       │
│                       │  diction,   │                                       │
│                       │  phase exit │                                       │
│                       └─────────────┘                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

The quality role is **not** an external tester and **not** an end-of-phase
gatekeeper. It is a real-time discussion partner embedded in the work:

| A quality role **is** | A quality role **is not** |
|-----------------------|---------------------------|
| A dialogue partner checking quality as work progresses | A gatekeeper who appears only when everything is done |
| An advocate for correctness, consistency, completeness, structure | An external tester who writes and runs test cases |
| The decider on whether the current deliverable meets its criteria | A passive commenter who does not drive iteration |
| The agent that decides when to consult a human | A substitute for human judgement at the gates |

**Independence requirement.** A quality role must be operated as a **separate
agent** from its paired progress role. Running both from the same agent instance
defeats the purpose of independent verification.

### PF-ROL-CAT Role Catalogue

| Category | Purpose | Roles |
|----------|---------|-------|
| **AI Progress** | Drive deliverable creation | SPEC, DES, DEV |
| **AI Quality** | Ensure quality through integrated review and iteration | QM-SPEC, QM-DES, QM-DEV |
| **AI Specialist** | Cross-cutting concerns spanning phases | TM, SEC |
| **Human** | Decisions, clarifications, approvals, domain expertise | PM, BA, SA, OPS, USR |

| ID | Name | Category | Phases | Paired with | One-line description |
|----|------|----------|--------|-------------|----------------------|
| `SPEC` | Specification Lead | AI Progress | 2–3 | `QM-SPEC` | Creates correct, consistent, comprehensive specifications |
| `DES` | System Designer | AI Progress | 4 | `QM-DES` | Maps specifications to CodeSpecs with end-to-end traceability |
| `DEV` | Developer | AI Progress | 5–6 | `QM-DEV` | Derives tests and implements code against them |
| `QM-SPEC` | Specification Quality Manager | AI Quality | 2–3 | `SPEC` | Reviews and iterates on specification quality |
| `QM-DES` | Design Quality Manager | AI Quality | 4 | `DES` | Reviews and iterates on CodeSpec quality |
| `QM-DEV` | Development Quality Manager | AI Quality | 5–6 | `DEV` | Reviews and iterates on test and implementation quality |
| `TM` | Test Manager | AI Specialist | 5–7 | — | Ensures test completeness, coverage and correctness |
| `SEC` | Security Responsible | AI Specialist | 3–8 | — | Verifies framework compliance and the absence of workarounds |
| `PM` | Project Manager | Human | 1–8 | all | Phase transitions, scope, priority, approvals |
| `BA` | Business Analyst | Human | 1–3, 7 | `SPEC`, `QM-SPEC` | Requirements, domain expertise, acceptance |
| `SA` | Solution Architect | Human | 3–6 | `DES`, `QM-DES` | Technical decisions, architecture, framework guidance |
| `OPS` | Operations | Human | 7–8 | — | Deployment, infrastructure, monitoring |
| `USR` | End User | Human | 1, 7 | — | Vision input, acceptance testing |

### PF-ROL-PHA Phase–Role Matrix

```
Phase │ Progress role  │ Quality role │ Specialists │ Human required
──────┼────────────────┼──────────────┼─────────────┼───────────────────
  1   │ (human-driven) │ —            │ —           │ PM, BA, USR
  2   │ SPEC           │ QM-SPEC      │ —           │ PM, BA
  3   │ SPEC           │ QM-SPEC      │ SEC         │ PM, BA, SA
  4   │ DES            │ QM-DES       │ SEC         │ SA
  5   │ DEV            │ QM-DEV       │ TM, SEC     │ SA
  6   │ DEV            │ QM-DEV       │ TM, SEC     │ SA
  7   │ (human-driven) │ —            │ TM, SEC     │ PM, BA, USR, OPS
  8   │ (human-driven) │ —            │ SEC         │ PM, OPS
```

### PF-ROL-MAT Responsibility Matrix

| Role | Ph.1 Idea | Ph.2 SBP | Ph.3 Specs | Ph.4 CodeSpec | Ph.5 Tests | Ph.6 Impl. | Ph.7 Accept. | Ph.8 Release |
|------|-----------|----------|------------|---------------|------------|------------|--------------|--------------|
| **SPEC** | — | **R** | **R** | C | — | — | — | — |
| **DES** | — | — | C | **R** | C | — | — | — |
| **DEV** | — | — | — | — | **R** | **R** | — | — |
| **QM-SPEC** | — | **V** | **V** | E | — | — | — | — |
| **QM-DES** | — | — | — | **V** | E | — | — | — |
| **QM-DEV** | — | — | — | — | **V** | **V** | — | — |
| **TM** | — | — | — | — | V | V | **V** | — |
| **SEC** | — | — | V | V | V | V | V | V |
| **PM** | **A** | A | A | I | I | I | **A** | **A** |
| **BA** | R | A | A | — | — | — | A | — |
| **SA** | — | — | A | A | A | A | I | — |
| **OPS** | — | — | — | — | — | — | A | **A** |
| **USR** | R | — | — | — | — | — | A | — |

**Legend:** **R** Responsible (does the work) · **V** Verifies (quality checks) ·
**A** Approves (sign-off) · **C** Consulted · **I** Informed · **E** Escalation
target · — not involved

### PF-ROL-GAT Gate Responsibility

| Gate | Evaluator | Approver | Escalation path |
|------|-----------|----------|-----------------|
| G1 Idea captured | PM | PM | — |
| G2 Blueprint complete | QM-SPEC | PM + BA | BA for requirements, PM for scope |
| G3 Specifications complete | QM-SPEC + SEC | PM + BA + SA | BA for business, SA for technical |
| G4 CodeSpecs complete | QM-DES + SEC | SA | SA for architecture, PM for scope |
| G5 Tests derived | QM-DEV + TM | SA | SA for coverage decisions |
| G6 Implementation complete | QM-DEV + TM + SEC | SA | SA for technical, PM for schedule |
| G7 Business accepted | TM + SEC | PM + BA + USR | PM for the go-live decision |
| G8 Release ready | SEC + OPS | PM + OPS | OPS for infrastructure |

### PF-ROL-ESC Escalation

Deciding **when to involve a human** is a core function of the quality roles.
They escalate on:

| Trigger | Description | Target |
|---------|-------------|--------|
| Ambiguity | Language that can be read more than one way | BA or PM |
| Contradiction | Two requirements or specifications that conflict | BA or PM |
| Technical impossibility | A requirement that cannot be implemented as specified | SA |
| Scope creep | Work drifting beyond the defined scope | PM |
| Framework limitation | Tom Architecture cannot support a requirement without a workaround | SA |
| Security concern | A design or implementation that could create a security issue | SA or PM |
| Missing information | Source material lacks what the current phase needs | BA |
| Quality plateau | Iterations no longer improve quality | PM |

**Flagging format.** AI roles flag issues "to whom it may concern" — they are not
required to know the human org chart. The PM (or a designated coordinator) routes
each flag.

```yaml
flag:
  severity: BLOCKING | IMPORTANT | INFORMATIONAL
  category: ambiguity | contradiction | impossibility | scope |
            security | quality_plateau | missing_info
  phase: {phase number}
  deliverable: {deliverable ID}
  role: {flagging role ID}
  description: {clear description of the issue}
  context: {relevant quotes or references from the specification}
  options: [{possible resolutions, if known}]
  addressed_to: "to whom it may concern"
```

### PF-ROL-DEC Decision Authority

| Decision | Authority | AI input |
|----------|-----------|----------|
| Phase transition | PM | Quality-role evaluation + specialist reports |
| Scope change | PM | `SPEC` or `DES` identification |
| Technical trade-off | SA | `DES` or `DEV` analysis |
| Requirement clarification | BA | `QM-SPEC` question |
| Security exception | SA + PM | `SEC` finding |
| Framework customization | SA | `DES` or `SEC` proposal |
| Production go-live | PM | `TM` + `SEC` final reports |

### PF-ROL-TEA Team Composition

**Minimum team.**

| Role | Count | Notes |
|------|-------|-------|
| AI Progress | 3 agents | `SPEC`, `DES`, `DEV` — may be one model under different prompts |
| AI Quality | 3 agents | `QM-SPEC`, `QM-DES`, `QM-DEV` — **must be separate agents** from their progress counterparts |
| AI Specialist | 2 agents | `TM`, `SEC` |
| Human PM | 1 | Required at every phase transition |
| Human BA | 1 | Required in Phases 1–3 and 7 |
| Human SA | 1 | Required in Phases 3–6 |

**Scaling.**

| Project size | AI agents | Human team |
|--------------|-----------|------------|
| Small (< 10 screens) | 8 (3 + 3 + 2) | 2–3 — PM plus a combined BA/SA |
| Medium (10–50 screens) | the same 8 | 3–5 — PM, BA, SA, OPS, user representative |
| Large (> 50 screens) | the same 8, parallelized | 5+ — dedicated PM, BA, SA, OPS and a user group |

AI capacity scales by **parallelizing deliverables**, not by inventing more
roles. The role set is fixed; the number of deliverables in flight is not.

---

## PF-TOO Tooling

The process is not a paper method. It is carried by a toolchain in which the
specification is a **typed object model** rather than prose, and the tools work
on that model.

### PF-TOO-OVE The Toolchain

| Tool / project | Location | Role in the flow |
|----------------|----------|------------------|
| **`tom_specs_editor`** | `tom_forge/tom_specs_editor` | The authoring application — the primary human/AI workbench for Phases 2–6 |
| `tom_specs_model` | `tom_ai/ai_build/tom_specs_model` | The specification object model: typed classes for all 14 document roots |
| `tom_specs_core` | `tom_ai/ai_build/tom_specs_core` | The annotation library the model is built from — section IDs, forms, content help, `@MapsTo` / `@DetailedIn`, `@CodeSpecKind` |
| `tom_specs_clitool` | `tom_ai/ai_build/tom_specs_clitool` | Model outliner, structural validator, the JSON export the editor consumes, and the Phase-4 CodeSpecs validator (`bin/validate_codespecs.dart`) behind Gate G4 |
| `tom_specs_reviewer` | `tom_ai/ai_build/tom_specs_reviewer` | Structural review of the object model itself — a methodology tool, not a project tool |
| `tom_code_specs` | `tom_ai/ai_build/tom_code_specs` | The CodeSpecs annotation framework — the `Cs*` family plus the `@DocSpec` back-trace |
| `tom_core_codespecs` | `tom_ai/core/tom_core_codespecs` | Gap-filler classes CodeSpecs needs that `tom_core` does not yet provide |
| **Extract generator** (`spec_codespecs_extract`) | The nine `tom_som_*_v0` runtimes | Phase 4's first pass: routes each specification section by `@CodeSpecKind` into the per-area extract the authoring agent works from. A surface of every runtime, not a Dart tool, so a project specified in TomSpecs is not thereby a Dart project |
| `tom_doc_specs` / `tom_doc_scanner` | `tom_ai/ai_build/` | DocSpecs schema assets and the markdown parser behind import/export |
| `testkit` | `tom_ai/devops/tom_test_kit` | Test execution and baseline tracking for Phases 5–7 |
| `Tom Deploy` | `tom_ai/devops/tom_deploy` | Deployment for Phases 7–8 |
| `Tom Provisioning` / `Tom SQM` | `tom_ai/cloud/`, `tom_sqm/` | Multi-tenant provisioning and subscription/quota management in Phase 8 |

### PF-TOO-EDT The Spec Editor

**`tom_specs_editor`** is the application the process is worked in. It is a Tom
Forge desktop app built on the Forge shell (`tom_forge_ui` / `tom_forge_core`)
with the shared agent UI (`tom_forge_agentic` / `tom_core_agentic`).

**Scope.** It is aimed at the whole delivery arc:

- **Now** — maintaining a SOM-based specification document, then working on the
  CodeSpecs code, test creation and implementation
- **Later** — acceptance and business testing, deployment, and operations

**Three applications, one shell.** The editor registers three top-level
applications behind a toolbar switcher, each with the same four-region layout —
*document · structure · navigator and change log · chat*:

| Application | Phase | State |
|-------------|-------|-------|
| **DocSpecs** | 2–3 | Fully functional — the model-driven specification editor |
| **CodeSpecs** | 4 | Phase-aware surface presenting the CodeSpecs methodology content |
| **Implementation** | 5–6 | Phase-aware surface presenting the implementation methodology content |

The CodeSpecs and Implementation applications render the real phase content —
purpose, inputs, produced artifacts, components, exit criteria — rather than
empty placeholders. Their own working surfaces are the next build-out step
(PF-TOO-ROA); for CodeSpecs that is a **run** surface over extracts and emitted
code, not an editor over a document model, because Phase 4 has no document model
of its own.

**Modules.**

| Module | Provides |
|--------|----------|
| `document/` | The model-driven document editor over the spec model, a root navigator with a model-version footer, and DocSpecs + markdown import/export |
| `structure/` | The structure browser and structural review, keyed by structural path |
| `agent/` | The embedded spec agent suite — chat composer, prompt queue, prompt trail — over a spec agent engine with a brain runtime, conversational runtime, memory plane, prompt composer, tools and a script runner |
| `config/` | Configuration editors with a config rail, editor preferences and raw-file editing |

Undo spans document edits, agent turns and editor actions — an agent turn is
undoable as a unit, which is what makes it safe to let an agent write directly
into the specification.

**Why an editor rather than markdown files.** The specification is a typed
object model. The editor therefore knows, for every position in the document:
which fields exist and of what type, what content help applies, which Blueprint
region a section expands, which CodeSpecs part it maps to, and whether the
structural invariants still hold. Prose in a text file supports none of that.

**How the agent fits.** The embedded agent works **on the model**, not on text:
it fills sections, expands a Blueprint region into a target document, flags
gaps, and answers questions against the specification — with the same
validation, undo and traceability as a human edit. This is what makes
"filled mostly by AI" (Phase 2) and "generated from the section mapping"
(Phase 3) practical rather than aspirational.

### PF-TOO-VAL Validation and Export

`tom_specs_clitool` is the non-interactive half of the toolchain:

- **Outliner** (`bin/outliner.dart`) — renders a compact outline of the class
  tree from any of the document roots
- **Validator** (`lib/src/validator.dart`) — enforces the field-type rules,
  content-type compatibility, cycle detection, and the structural invariants:
  section-ID uniqueness and coverage, pattern uniqueness, `@DetailedIn` →
  ancestor `@MapsTo`, root-independent section-ID resolution, and per-document
  detail counts
- **Model JSON export** (`bin/model_json.dart`) — serializes the resolved class
  graph for the editor and the reviewer. Both committed copies are refreshed by
  naming their target (`--target editor` / `--target reviewer`), which carries
  the version stamp each is pinned at; see `tom_specs_model_meta_schema.md`,
  "Refreshing the committed assets"

Because the validator runs on the model rather than on rendered output, a
structural defect is caught at the source — before it can propagate into twelve
documents, a schema, or nine generated language runtimes.

### PF-TOO-ROA Roadmap

The tooling gap that remains is the back half of the flow. In order:

1. **CodeSpecs application** — a Phase-4 run surface, replacing the phase-aware
   one: drive the extract generator, show each area's extract beside the code
   written from it, and work the generated todo tree with its open questions
   held in view. Deliberately **not** a model-driven editor over a CodeSpecs
   object model — there is none to edit. CodeSpecs is annotated `tom_core`
   classes and the extracts they are derived from, so the thing to build is a
   run surface over those two artifacts
2. **Implementation application** — the same for the implementation phase,
   including the test-derivation view
3. **Acceptance and business testing** — running the `QAP` programme from the
   editor, with results feeding the evidence store directly
4. **Deployment** — driving Tom Deploy from the release surface
5. **Operations** — the post-release view: monitoring, defects, and the upgrade
   cycle backlog

---

## PF-ISS Issues and Bug Fixes

From **Phase 3 onward**, individual issues — specification inconsistencies,
defects found during implementation, failures found during acceptance testing —
are worked through a lightweight per-issue sequence. This is **not** a phase
gate; it is a checklist that agents execute automatically for every issue.

The general workflow is the workspace-wide one in
[`_copilot_guidelines/issue_implementation.md`](../../../../_copilot_guidelines/issue_implementation.md).
What follows is how it plugs into the TomSpecs flow and what is checked at each
step.

### PF-ISS-SEQ The Issue Sequence

```
  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌────────┐  ┌────────┐
  │ TRIAGE   │─►│ TEST     │─►│ IMPLEMENT │─►│ VERIFY │─►│ CLOSE  │
  └──────────┘  └──────────┘  └───────────┘  └────────┘  └────────┘
       │              │             │             │           │
       ▼              ▼             ▼             ▼           ▼
  Root cause     Test exists   Code compiles  All tests   Commit
  identified     and fails     and is clean   pass        clean
  Scope clear    Issue ID ref  No warnings    No regress. Baseline
                                                          updated
```

**The test comes before the fix — always.** A defect that cannot be reproduced
in a test is not understood well enough to be fixed. This holds for one-line
changes.

### PF-ISS-CHK Per-Step Checks

**Triage** — trigger: the issue is picked up.

| Check | Pass condition |
|-------|----------------|
| Description exists | Non-empty, with expected vs actual behaviour |
| Reproduction steps present (defects) | Steps to reproduce are documented |
| Affected component identified | The files or modules are named |
| Scope assessed | Which tests, which modules, cross-project or not |
| Traced to specification | Where the behaviour is specified — or a note that it is not, which makes this a specification defect, not a code defect |
| Not a duplicate | No existing open issue covers it |

**Test** — trigger: after writing the failing test.

| Check | Pass condition |
|-------|----------------|
| At least one test exists | A test file references the issue ID |
| Test references the issue ID | Test name or description contains it, e.g. `[BUG-123]` |
| Test currently fails | Running it produces a failure — RED |
| Fails for the right reason | The failure relates to the reported issue, not to a setup error |
| Conventions followed | File location, naming and structure per the test guidelines |

**Implement** — trigger: after the fix (tests should now pass).

| Check | Pass condition |
|-------|----------------|
| Issue tests pass | The previously failing tests are GREEN |
| Existing tests still pass | No regressions |
| Static analysis clean | 0 errors, 0 warnings in the affected packages |
| Formatting clean | No formatting deviations |
| Minimal change | Changes are confined to the issue scope |
| Edge cases covered | The edge cases raised in triage are tested |

**Verify** — trigger: after the implementation checks pass.

| Check | Pass condition |
|-------|----------------|
| Full suite passes | All tests in the project, not just the affected package |
| Baseline comparison | No regressions against the most recent baseline |
| Cross-project impact | Dependent projects still compile and pass their tests |

**Close** — trigger: after verification passes.

| Check | Pass condition |
|-------|----------------|
| Commit references the issue ID | The commit message contains it |
| Nothing uncommitted | The working tree is clean |
| Baseline updated | The new baseline reflects the fix |
| Resolution recorded | The issue carries a resolution summary |
| Specification updated where needed | If the fix changed intended behaviour, the owning specification section was updated too |

The close record is written to `_ai/quality/evidence/issues/<issue_id>_closed.yaml`
with the timestamps of each check, the tests added, the files changed and the
commit.

### PF-ISS-CRO Cross-Project Issues

| Scenario | Handling |
|----------|----------|
| Same project group | Full sequence in the original project; inline fix in the related project |
| Different project group | Triage only in the original project → file a new issue for the other project → a fresh sequence there → resume the original when unblocked |
| Reassignment | Triage is re-run in the new project — the previous triage may not apply |
| Circular reassignment (max 3) | Escalate to a human; the sequence is suspended until ownership is resolved |

### PF-ISS-SPC Specification Defects

An issue whose root cause is in the specification is **not** fixed in code. It
is routed to the owning phase through
[phase re-entry](#pf-itr-ree-phase-re-entry): the specification is corrected,
the correction runs through the document quality sequence, the CodeSpecs and
tests derived from the changed section are regenerated or re-derived, and only
then is the code changed. Fixing the code and leaving the specification wrong
breaks the traceability chain the whole process rests on.

---

## PF-UPG Upgrade Cycles

Once a system passes G8 and enters production, it leaves the creation process
and enters **upgrade cycles**. The `DRM` Delivery Roadmap defines when that
transition occurs and what cadence applies afterwards.

### PF-UPG-DIF How an Upgrade Differs

| Aspect | Initial creation | Upgrade cycle |
|--------|-----------------|---------------|
| Phase 1 | Project Idea from scratch | Not applicable — the system exists |
| Phase 2 | Full Blueprint | Incremental Blueprint update, scoped to the change |
| Phase 3 | All twelve documents | Only the affected documents |
| Baseline | None exists | The previous release **is** the baseline |
| Regression | Not applicable | The primary concern |
| Gate scope | Full evaluation | Delta evaluation — changed areas plus regression |
| Test strategy | Build the suite | Extend the suite; run the full regression suite |
| Security | Initial audit | Delta audit plus a re-scan for newly published vulnerabilities |
| Deployment | First deployment | Rolling update with tested rollback |

### PF-UPG-TRG Triggers

An upgrade cycle is opened by any of: business feature requests; technology
updates (framework, language, platform); compliance or regulatory change;
security vulnerabilities; performance or capacity needs; new external systems
appearing in the integration landscape.

### PF-UPG-CYC The Cycle

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  UC-1        │   │  UC-2        │   │  UC-3        │   │  UC-4        │
│  Change      │──►│  Impact      │──►│  Spec        │──►│  CodeSpec    │
│  Collection  │   │  Analysis    │   │  Update      │   │  Update      │
└──────────────┘   └──────────────┘   └──────────────┘   └──────┬───────┘
        ┌─────────────────────────────────────────────────────────┘
        ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  UC-5        │   │  UC-6        │   │  UC-7        │
│  Test        │──►│  Implement   │──►│  Release     │
│  Update      │   │              │   │              │
└──────────────┘   └──────────────┘   └──────────────┘
```

**UC-1 Change Collection.** Collect change requests from every source — users,
operations, security, compliance. Categorize them (feature / defect /
technical debt / security / compliance), prioritize on business value against
effort, and group them into release candidates.

**UC-2 Impact Analysis.** Trace which specification documents change, which
CodeSpecs elements change, and which tests need updating. Assess backward
compatibility for API, data and UI. Assess risk per change and check whether
external integrations are affected. **The key difference from initial
development:** impact analysis must consider the *running* system, not only the
documents. The traceability chain makes the impact set computable.

**UC-3 Spec Update.** Update only the affected documents. Track the version and
the change — what changed, why, and when — inside each document. Re-run the
cross-reference and consistency checks over the whole set afterwards, because a
local change can break a distant reference.

**UC-4 CodeSpec Update.** Update existing CodeSpecs, add elements for new
functionality, mark removed functionality as deprecated, and add migration
declarations for changed data structures.

**UC-5 Test Update.** Add tests for new functionality, update tests for changed
functionality, freeze the existing suite as the regression baseline, and add
migration tests for data changes.

**UC-6 Implementation.** As Phase 6, scoped to the change. Two additional
constraints: existing functionality must not break, and database changes are
**migrations**, not a fresh schema. Feature flags may be used for gradual
rollout of user-visible change.

**UC-7 Release.** Versioned release with a changelog generated from the change
requests, a **mandatory** rollback plan, coordinated tenant upgrades where
multi-tenant, and a blue-green or canary deployment.

### PF-UPG-TYP Upgrade Types

| Type | Characteristics |
|------|-----------------|
| **Minor** (patch / feature) | No breaking changes; backward-compatible API; additive database changes only; applicable without downtime |
| **Major** | May break compatibility; requires migration steps; may require API versioning and coordinated client updates; extended testing phase |
| **Emergency** (hotfix) | Security vulnerability or critical defect; abbreviated process with fast-track approval; **tests are still mandatory**; documentation is updated after the fact |

The emergency path shortens the *process*, never the *evidence*. A hotfix
without a test that reproduces the defect is not permitted.

### PF-UPG-REG The Regression Gate

Every upgrade cycle carries a mandatory regression gate in addition to the
normal phase gates for the parts it touches:

| Criterion | Check method | Pass condition |
|-----------|--------------|----------------|
| Existing tests pass | Full suite execution | 0 regressions |
| No new static analysis issues | Baseline comparison | No new warnings or errors |
| No security regressions | Security delta scan | No new vulnerabilities |
| API backward compatibility | API diff analysis | No unplanned breaking change |
| Database migration tested | Migration test | Forward **and** rollback both successful |
| Performance not degraded | Benchmark comparison | Within 5% of the baseline |

### PF-UPG-MTN Multi-Tenant Upgrades

Where the system is provisioned per tenant, the release step carries additional
decisions, all of which belong in the `TRP`:

- Simultaneous upgrade of all tenants, or a phased rollout
- Tenant-specific feature flags
- Schema migration across every tenant database
- Backward compatibility for the duration of a rolling upgrade
- Tenant communication plan
- Opt-in versus mandatory upgrades, and the deadline for the former

---

## PF-SUP Supporting Processes

The phase flow is the spine, but four processes run continuously alongside it
and cross every phase boundary.

### PF-SUP-ISU Issue Tracking

Every defect — regardless of which phase discovered it — is recorded as an
issue and follows the sequence in [PF-ISS](#pf-iss-issues-and-bug-fixes). Issues
carry the phase in which they were **introduced** as well as the phase in which
they were **found**; the difference between those two is the escape distance
and feeds the metrics in [PF-GAT-DEF](#pf-gat-def-defect-management).

Gate failures produce issues. A gate does not fail silently: each unmet
criterion becomes a tracked item with an owner and a target, and the gate
re-runs only once all blocking items are closed.

### PF-SUP-TST Test Tracking

Test results are tracked against a **baseline** rather than evaluated in
isolation, so that a run is judged by its delta:

- `OK/OK` — passing, was passing
- `X/OK` — **regression**, blocks the gate
- `OK/X` — fix confirmed
- `X/X` — known failure, must have a tracked issue

A new baseline is established at each release; within a phase the most recent
baseline is the reference. Gates G5 through G8 read the baseline delta directly
rather than the raw pass count.

### PF-SUP-CHG Change Management

Once a document has reached `ACCEPTED` (see
[PF-ITR-DSQ](#pf-itr-dsq-document-quality-sequence)) it is no longer edited
freely. A change to an accepted document requires:

1. A change request stating the reason and the scope
2. An impact analysis across the dependency graph
   ([PF-ITR-DEP](#pf-itr-dep-dependency-driven-iteration))
3. Approval by the role holding decision authority for that document
   ([PF-ROL-DEC](#pf-rol-dec-decision-authority))
4. Re-entry into the owning phase and a re-run of its gate
   ([PF-ITR-REE](#pf-itr-ree-phase-re-entry))

Changes before acceptance need none of this — that is the point of the
DRAFT/REVIEWED stages.

### PF-SUP-DOC Documentation Derivation

User-facing and operational documentation is **derived**, not written in
parallel. The specification model is the source; the renderings are outputs:

| Output | Derived from |
|--------|--------------|
| User manual | `XDS` interaction flows + `ISC` scenarios |
| API documentation | `IIS` interface definitions + CodeSpecs endpoint parts |
| Operations runbook | `TOM` operating model + `TRP` rollout plan |
| Security documentation | `SAS` |
| Data dictionary | `IFM` |

Keeping documentation derived rather than authored is what prevents the
familiar drift between what a system does and what its manual claims it does.

---

## PF-REF Reference Index

This document describes the **process**. The mechanics of each artifact type
are specified elsewhere; that is the division of labour.

### PF-REF-SPC Specification Mechanics

| Document | Authority for |
|----------|---------------|
| `tom_specs_model_rules.md` | The model-authoring authority: object-model layout, field shapes, field classification, form decomposition, section IDs, headlines, annotations, structural invariants, and the outliner tool (§11) |
| `som_multiplatform_spec_model.md` | The SOM authority: the nine-language generation, the metadata tree, the generated SOM surfaces, markdown and YAML serialization, schema generation, the embedded validator, and packaging |
| `_ai/quests/doc_specs/doc_specs_specification.md` | The DocSpecs format itself: schemas, section types, validation |

### PF-REF-CSP CodeSpecs Mechanics

CodeSpecs is **two documents, split by question**.

| Document | Authority for |
|----------|---------------|
| `codespecs_mapping.md` | The **grounding** document — *which SOM section feeds which part*: the four pillars and `tom_core`-family basis (§1.1), the neutral vocabulary (§1.2), the parts catalogue and three-project output (§4), the per-part code-basis gap analysis and attribute surfaces (§5), the server contract (§7), the SOM derivation — the four walk questions, the document map, the closed-choice design, the CodeSpecs-versus-follow-up split and its taxonomy, and the per-part walk index in the section-coverage matrix (§8), the bidirectional DocSpecs↔CodeSpecs link (§9), and the open-work index (§10) |
| `codespecs_derivation_contract.md` | The **derivation contract** — *what code comes out*: one entry per active `Cs*` marker giving its input SOM fields, the exact Dart emitted and its `tom_core`-family superclass, per-argument derivation, locus, cross-references and back-links (§3), plus the universal naming rules N1–N10, the stub-body rules and the comment-derivation rule C1–C6 (§2), a worked end-to-end example (§4), the annotation constructor shapes (§5) and the validator checks (§6). Where the two appear to disagree about emitted code, the derivation contract wins |

### PF-REF-ENG Engineering Practice

| Document | Authority for |
|----------|---------------|
| `_copilot_guidelines/test_driven_development.md` | Red-Green-Refactor discipline |
| `_copilot_guidelines/issue_implementation.md` | The workspace-wide bug and feature workflow that [PF-ISS](#pf-iss-issues-and-bug-fixes) specialises |
| `_copilot_guidelines/dart/coding_guidelines.md` | Naming, structure, error handling |
| `_copilot_guidelines/dart/clean_code_principles.md` | DRY, abstractions, code smells |
| `_copilot_guidelines/dart/unit_tests.md` | Test structure, matchers, mocking |

### PF-REF-PLT Platform

| Component | Role in the process |
|-----------|--------------------|
| Tom Core | The runtime foundation every CodeSpec builds on |
| Tom UAM | Users, roles, permissions — consumed by `SAS` |
| Tom Deploy | Deployment automation, invoked at Phase 8 |
| Tom Provisioning | Cloud resource provisioning for multi-tenant systems |
| Tom SQM | Subscriptions and quotas for the subscriber model |
| Tom Forge | The shell hosting the specification editor |
