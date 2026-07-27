# TomSpecs SOM Guidelines

**Quest:** tom_specs
**Status:** Living document — the authoritative summary of the rules that govern
the Specification Object Model (SOM).
**Audience:** Anyone extending the `tom_specs_model` object model, authoring or
reviewing `@SectionId`/traceability annotations, running the CLI tooling, or
consuming the generated multi-platform SOM.

---

## 1. Purpose and scope

This document is the **single, complete overview of the guidelines we apply when
building and extending the SOM** — how a model class must be written, how
section IDs are formed, what the annotations mean for the author, and what the
surrounding tools do with the result. It is deliberately layered:

- **Authoring rules are detailed here.** The universal section structure, the
  legal member shapes, the field classification, the form-decomposition targets,
  the section-ID scheme, and the traceability invariants are stated in full so
  this document is sufficient to design or review a model change without opening
  the source.
- **Tools, wire formats, and annotation internals are *mentioned* here and
  *specified* elsewhere.** The CLI (`tom_specs_clitool`), the editor
  (`tom_specs_editor`), the reviewer (`tom_specs_reviewer`), the multi-platform
  generated component (`tom_som`), and the individual annotation contracts each
  have their own specification. This document points to those specs rather than
  restating their internals.

For tools and annotations this document is the map, not the territory — but it
**is** the territory for the model-design and section-ID authoring rules it
details.

### 1.1 What "SOM" means

**SOM = Specification Object Model.** It is the typed object model that
represents TomSpecs specification documents. Two representations coexist and must
be kept consistent:

| Representation | Role |
|----------------|------|
| **Dart object model** (`tom_specs_model`) | The **source of truth**. Typed classes with analyzer support; every structural rule is checked against it. |
| **Markdown templates** (e.g. the SBP template) | The **human-readable rendering** of the same structure. Templates follow the model, not the other way round. |

Everything downstream — DocSpecs schemas, the generated multi-platform access
API, the outliner documentation, the editor tree — is derived from the Dart
model. Change the model first; regenerate the rest.

### 1.2 Boundary — these guidelines vs. `som_mapping.md`

The two documents cover the same object model from opposite ends and must not
duplicate each other:

| Document | Owns |
|----------|------|
| **This document** (`tom_specs_som_guidelines.md`) | **Authoring.** What an author may write and must write: legal member shapes, class style, naming, field categories, form size targets, how to choose a `@SectionId`, which annotations to reach for, what the validator will reject. |
| **[`som_mapping.md`](../../../tom_ai/ai_build/tom_specs_model/doc/som_mapping.md)** | **Mapping and mechanics.** How the authored model becomes bytes: md serialization, hierarchical yaml, DocSpecs schema generation, the metadata tree, the generated SOM surfaces, the embedded parse/validate API, the conformance requirements. |

`som_mapping.md` is the **single mapping authority**. Where a rule here restates
something that has mapping consequences (member shapes, section IDs, annotation
semantics), `som_mapping.md` wins on the detail; this document states the rule an
author needs and cites the section there.

---

## 2. Standards the SOM is based on

The SOM is not an ad-hoc schema. Its document suite, layering, and section
vocabulary are grounded in established software-engineering and
business-analysis standards, and wrapped in the Tom document standards
(DocSpecs).

### 2.1 Public-standards foundation

The 13 documents are organised into six **layers** whose names and structure
follow public requirements-engineering and business-analysis practice. The
suite maps onto ISO/IEC/IEEE 29148, BABOK, ISO/IEC 25010, ISO/IEC/IEEE 42010,
ISO 9241, DAMA-DMBOK, PMBOK, and ISO 27001.

| Layer | Public basis |
|-------|--------------|
| **L1 Context & Governance** | ISO/IEC/IEEE 29148 §6 front matter; BABOK Strategy Analysis |
| **L2 Business Analysis** (current + target) | BABOK current-/future-state; DAMA-DMBOK (data) |
| **L3 Requirements** | ISO/IEC/IEEE 29148 (SRS / SyRS); Cockburn use cases |
| **L4 Solution Design** | ISO/IEC/IEEE 42010 (architecture); ISO 9241 (UX); ISO 27001 (access) |
| **L5 Quality & Acceptance** | ISO/IEC 25010; ISO/IEC 25040 |
| **L6 Delivery & Transition** | ISO/IEC/IEEE 29148 transition requirements; PMBOK phasing |

The **Solution Blueprint (D00 / SBP)** is the umbrella concept/summary document
that seeds the layered suite. Its 14 top-level sections lead with
purpose/scope and glossary and consolidate governance, following the public
convention: Document Control, Introduction & Scope, Glossary & Abbreviations,
Stakeholders & Governance, Current Landscape, Assumptions/Constraints/
Dependencies, Target Operating Model, Information & Data Model, Requirements,
Solution Architecture & Technology, Security & Access Model, Experience &
Interface Design, Quality & Acceptance Model, and Delivery/Transition/Rollout.
See `tom_specs_project_flow.md` §PF-FLW for the section-by-section expansion
map and the master process it serves.

### 2.2 Per-document standards anchors

Each of the 12 Phase 3 roots carries a `@SectionId` code, sits in one layer,
and anchors to a named public standard:

| Document root (class) | Code | Layer | Public anchor |
|-----------------------|------|-------|---------------|
| `D01CurrentLandscapeAssessment` | CLA | L2 | BABOK current-state |
| `D02TargetOperatingModel` | TOM | L2 | BABOK future-state |
| `D03InformationModel` | IFM | L2 | DAMA-DMBOK |
| `D04RequirementsSpecification` | RSP | L3 | ISO/IEC/IEEE 29148 SRS |
| `D05InteractionScenarios` | ISC | L3 | Cockburn use cases |
| `D06ArchitectureTechnologySpecification` | ATS | L4 | ISO/IEC/IEEE 42010 |
| `D07IntegrationInterfaceSpecification` | IIS | L4 | ISO/IEC/IEEE 29148 interfaces |
| `D08SecurityAccessSpecification` | SAS | L4 | ISO 27001 |
| `D09ExperienceDesignSpecification` | XDS | L4 | ISO 9241 |
| `D10QualityAcceptancePlan` | QAP | L5 | ISO/IEC 25010 |
| `D11DeliveryRoadmap` | DRM | L6 | PMBOK phasing |
| `D12TransitionRolloutPlan` | TRP | L6 | ISO/IEC/IEEE 29148 transition |

The **ISO/IEC 25010** eight product-quality characteristics form the quality
spine: the Quality & Acceptance model cross-maps each quality area onto the
eight characteristics so compatibility and portability cannot be missed.

#### The `Dxx` ordinal-prefix rule

Document root class names carry a **`D00`–`D12` ordinal prefix**
(`D00SolutionBlueprint`, `D04RequirementsSpecification`). The `Dxx` prefix is a
**sort key for class, file, and outline ordering only** — it **never** appears
in a `@SectionId` value. The section-ID code is the short mnemonic alone
(`SBP`, `RSP`), so ordering and identity stay independent.

### 2.3 Framework-uncovered concerns → public-standard anchors

The model covers what the tom_core framework does *not* provide. Three
cross-cutting concerns each anchor to a public standard and adopt that
standard's wording, appearing as named requirement sub-areas in the
Requirements section (NFR side), cross-referenced from Quality & Acceptance:

| Concern | Public-standard anchor | Wording |
|---------|------------------------|---------|
| Information for Use / documentation | ISO/IEC/IEEE 26511 / 26514 / 26515 | "Information for Use" / user-documentation requirements |
| Training & enablement | ISO/IEC/IEEE 29148 transition; PMBOK | "Training & Enablement requirements" |
| Localization & translation | ISO/IEC 25010 *Portability*; ISO 29148 i18n | "Localization & Translation requirements" |

Localization additionally cross-maps to the ISO 25010 portability/adaptability
characteristic in the Quality & Acceptance model.

### 2.4 The 8-phase creation process

The SOM exists to serve a defined, gated creation process (authoritative:
`tom_specs_project_flow.md`):

| # | Phase | Key output | Gate |
|---|-------|------------|------|
| 1 | Project Idea (PI) | Free-form vision | G1 |
| 2 | Solution Blueprint (D00 / SBP) | Structured overview (DocSpec) | G2 |
| 3 | Detailed Specifications | 12 DocSpec documents (see §2.5) | G3 |
| 4 | CodeSpecs | Skeletal application (compiles) | G4 |
| 5 | Test Derivation | Test cases from specs | G5 |
| 6 | Implementation | Working code + unit tests | G6 |
| 7 | Application Candidate | Business-accepted application | G7 |
| 8 | Release Candidate | Deployed, operable release | G8 |

Roles, quality gates, iteration rules, tooling, the issue workflow, and the
post-release upgrade cycle are all specified in `tom_specs_project_flow.md`
(§PF-ROL, §PF-GAT, §PF-ITR, §PF-TOO, §PF-ISS, §PF-UPG).

### 2.5 The 12 Phase 3 document roots, plus the CodeSpecs projection

Phase 3 expands the D00 Solution Blueprint into 12 typed document roots, each a
class annotated with `@Document(..., basedOn: [D00SolutionBlueprint])` and a
`@SectionId('<CODE>')`. Each aggregates existing SBP classes via typed fields
with traceability annotations (§6). The document roots (`D01`–`D12`) and their
section-ID codes are:
`CLA, TOM, IFM, RSP, ISC, ATS, IIS, SAS, XDS, QAP, DRM, TRP`.

A **14th root** completes the set: `D13CodeSpecsProjection` (`@SectionId('CGP')`)
is the flat **CodeSpecs generation projection** — it references the
`@CodeSpecKind`-bearing subtree roots directly (no container classes), grouped by
`@Comment('locus: …')` into the shared / client-only / server-only project split.
Being a projection rather than an authored document, it carries
`@CodeSpecsProjection()`, which exempts it from the validator's per-`@Document`
detail-count check **only** (all other invariants still apply). So the outliner
and the validator work over **14 roots**: `SBP` + the 12 Phase 3 codes + `CGP`.

### 2.6 Tom document standards (DocSpecs)

Every SOM document type has a corresponding **DocSpecs schema**, emitted from the
model (`{id}-{version}.docspecs-schema.yaml`). DocSpecs give validation (required
sections present), programmatic extraction, and traceability. The SOM is the
generator of these schemas, not a consumer of a hand-written one. See the
`doc_specs` quest and workspace DocSpecs documentation for the schema format.

---

## 3. Object-model layout

The SOM spans five cooperating projects:

| Project | Location | Role |
|---------|----------|------|
| `tom_specs_core` | `tom_ai/ai_build/` | Annotation library (the `@…` vocabulary) **and** the `DocSpecsSection` / `DocSpecsForm` section base types (§4.1). |
| `tom_specs_model` | `tom_ai/ai_build/` | The typed model itself — the source of truth. |
| `tom_specs_clitool` | `tom_ai/ai_build/` | Analyzer-based tooling: outliner, validator, JSON exporter, multi-language SOM generator. |
| `tom_specs_reviewer` | `tom_ai/ai_build/` | Flutter app for **reviewing the object model** — browses the exported class graph and records structural observations. Not a spec editor. |
| `tom_specs_editor` | `tom_forge/` | The **spec authoring app** — a Tom Forge desktop app for authoring DocSpecs / CodeSpecs / Implementation specifications. |

The base types live in `tom_specs_core`, not in `tom_specs_model`, by design: the
clitool's analyzer-based `ModelReader` scans `tom_specs_model/lib/src` and
reflects **every** class it finds into the document meta tree, so metamodel
infrastructure must stay outside the scanned package.

`lib/src/` of `tom_specs_model` is organised by document: `common/` for shared
types (enums, `Requirement`, `Risk`, `DocumentHeader`, `SectionMeta`),
`solution_blueprint/` for the SBP root, and one folder per Phase 3 document root.
`document_stubs.dart` re-exports so SBP classes can reference target-doc types
with a single import.

---

## 4. Model design rules

These rules govern how model classes must be written. The validator
(`tom_specs_clitool/lib/src/validator.dart`) checks all of them and classifies
each violation as an **error** (blocks output) or a **warning** (reported, does
not block). Authoritative detail: `som_mapping.md` §2 (object model) and §12
(structural invariants).

### 4.1 The universal section structure

**DocSpecs markdown is the key target format of the object model.** Everything
the model expresses must be expressible as a DocSpecs document, and — since
YRD5 — a DocSpecs document must be *parseable back into* the model. That
constrains the model to one universal shape.

**Every section, at every level, is exactly:**

```
<headline>  <!--[SECTION-ID]-->
<optional content>
<zero or more subsections>
```

There are no other section kinds. Three consequences an author must internalise:

1. **Uniform recursion.** A subsection has the same shape as its parent, with no
   depth limit. The model may nest arbitrarily deep; markdown heading levels
   beyond `######` are represented by continuing the `#` run (`#{7,}`), which the
   `tom_doc_scanner` grammar accepts.
2. **A list is an outer section whose items are its subsections.** A `List<T>`
   field is **not** a bare repetition — it is a real section in its own right
   (the `-LST` container, §6.2) that *contains* one subsection per item. The
   container may carry content, but that content **has no model-defined
   meaning**: it is free narrative introducing the list, never data.
3. **`@Form` structures content; it does not change the shape.** A form section
   is still headline + content + subsections. `@Form` only says *how the content
   text is laid out* (`FieldName: value` lines) and lets the runtime split the
   text into a pre-form narrative plus typed values. A form is never a different
   kind of node.

### 4.2 `DocSpecsSection` — the section base type (YRD5)

**Every section-bearing member is an object, never a bare `String`.** The base
type is `DocSpecsSection` (`tom_specs_core/lib/src/sections/docspecs_section.dart`):

```dart
class DocSpecsSection {
  String? headline;          // stored headline (overrides the @Headline default)
  String? id;                // stored section id — the <!--[ID]--> marker
  List<String> codeSpec;     // instance-level DocSpecs → CodeSpecs link
  String? content;           // body text
  DocSpecsForm? form;        // parsed @Form content, once split
}
```

- **Every model class extends `DocSpecsSection`**, so the whole model is an
  object graph a `*.md` document can be parsed into — headline and id are stored
  *per node* rather than derived.
- Former `String? foo` section members became `DocSpecsSection? foo`; former
  `List<String>` members became `List<DocSpecsSection>`.
- **The reserved `content` member stays `String?`** (declared `@override`). It is
  the class's *own* body text, not a sub-section, so it does not become an
  object.
- `DocSpecsForm` holds the parsed form: the pre-field `content` plus one entry
  per `@Form` field in `values`. Typed per-field members are generated onto the
  SOM classes (YRD7); `DocSpecsForm` is the generic model-side holder.

### 4.3 Legal member shapes

A member of a model class must take one of **six** shapes. Anything else is a
validator error (`som_mapping.md` §2.1 is authoritative):

| # | Shape | Meaning |
|---|-------|---------|
| 1 | `String content` (plain) | The section's **own** content. The id comes from the class, not the field. |
| 2 | `String content` with `@Form` | The `content` value is the pre-form narrative; the form's field members follow. |
| 3 | `DocSpecsSection <name>` with a field-level `@SectionId` (optionally `@Form`) | An **inline sub-section** whose content *is* this field. |
| 4 | `<SectionClass> field` | A sub-section class; the **class** owns the id. |
| 5 | `List<SectionClass>` with `@SectionId` + `@SectionIdPattern` | A list of sub-section classes. |
| 6 | `List<DocSpecsSection>` with `@SectionId` + `@SectionIdPattern` (optionally `@Form`) | An **inline list** of content sub-sections. |

Shapes 3 and 6 are the YRD5 replacements for the former `String` and
`List<String>` members. There is therefore **no such thing as a bare `String`
section member** any more, and `List<String>` is not a legal section list — the
old "leaf fields are `String`, `String?`, or an enum" rule is superseded.

### 4.4 Remaining type constraints

| Rule | Severity | Detail |
|------|----------|--------|
| **No primitive non-String scalars** | error | Form/scalar leaf values are `String`, `String?`, or an enum. No `int`, `double`, `bool`, `num`, `DateTime`. Dates and numbers are `String?` with a type hint on the `@Form` field. |
| **No `List<primitive>`** | error | A repeated section is `List<SectionClass>` or `List<DocSpecsSection>` (shapes 5/6), never a list of raw scalars. |
| **`content: String?` expected** | warning | Nearly every class carries a `content: String?` override — the section text between the headline and the next headline. Missing it is a warning, not a blocker. |

### 4.5 Class style

- **No constructors.** A default constructor is implied; classes are plain data
  holders.
- **No `final` / `const`.** Fields are plain mutable instance fields, record-like.
- **Non-nullable fields get a valid default; nullable fields stay null.** Lists
  default to `[]` (each instance owns its own mutable list).
- **No computed properties.** Only concrete instance fields are part of the
  model — no getters, static fields, or derived properties.

### 4.6 Naming convention

- **Singular complex fields should match their type name** (lowercase first
  letter): `SystemOverview systemOverview`. A mismatch (`header` for
  `DocumentHeader`) is allowed — the outliner then shows `fieldName:TypeName`.
- **List field names always differ** from the singular element type and are
  always shown as `fieldName:TypeName`. The plural field name is
  **structurally significant**: it names a document section level whose items are
  subsections.

### 4.7 ContentType constraints

- **`@ContentType('Form')` (default):** the class's other scalar fields are the
  form fields inside the content.
- **Non-Form content** (`DDL`, `SQL`, `Dart`, `ER-Diagram`, `Mermaid`, …): the
  class **must not** have other scalar fields — the content occupies the full
  text. Complex children are still allowed but uncommon (diagrams/code are
  usually leaves).

### 4.8 Reachability and cycles

- Only types **reachable from a document root** are part of the model; unreachable
  utility types are silently omitted from the outline.
- **Cycles must not exist.** A structural cycle is a hard error naming the types
  involved. `@Reference`-marked links are *not* traversed and therefore never
  count as cycles.

---

## 5. Field classification and form decomposition

### 5.1 Field categories

Every non-`content` textual field falls into exactly one category (authoritative
inventory: `field_classification.md`):

| Category | Meaning | Modelled as |
|----------|---------|-------------|
| **form** | short value (a form field) | `String?` inside a `@Form` — a *value*, not a section |
| **text** | short description, 1–3 sentences | `DocSpecsSection?` with a field-level `@SectionId` (shape 3) |
| **long** | multi-paragraph narrative | a `TextSection` (its own section class, shape 4) |
| **ref** | cross-reference to data owned elsewhere | `@Reference` field |

The **form** category is the only one that stays a bare `String?`: a form field
is a value *inside* a section's content, not a section of its own. Every other
category is an object (§4.2/§4.3).

### 5.2 Form decomposition

`@Form` sections target **3–10 fields**. Larger forms are decomposed so the
document stays readable (authoritative: `form_decomposition.md`):

| Size | Action |
|------|--------|
| 3–5 | ideal |
| 6–10 | acceptable, no action |
| 11–15 | **light split** — add a narrative `TextSection`, split into 3–4 sub-classes (one per comment group), parent keeps one field per sub-class |
| 16–35 | **standard decomposition** — each `// --- Group ---` block becomes its own `@Form` class; parent shrinks to one field per sub-class |
| 36+ | **deep decomposition** — apply splitting recursively; very large forms need 2+ levels |

Natural boundaries are the existing `// --- Group Name ---` comment markers. Each
extracted group becomes a new class with `@Form`, `@SectionId`, and
`@ContentHelp`.

---

## 6. Section-ID scheme

The section-ID scheme is the load-bearing addressing mechanism of the SOM. It is
detailed here in full. Mapping-side authority and worked examples:
`som_mapping.md` §3; the two design plans `section_id_pattern_plan.md` and
`field_suffix_list_id_plan.md` (both COMPLETE) record how the scheme was
arrived at.

### 6.1 Class-level `@SectionId` — the section *type* ID

- **Every model class has exactly one `@SectionId`.** It is a globally-unique
  mnemonic of **≤6 uppercase letters** identifying the *type* of a section, not
  its position in the tree.
- Document roots use their short codes (`SBP`, `CLA`, `TOM`, `IFM`, `RSP`,
  `ISC`, `ATS`, `IIS`, `SAS`, `XDS`, `QAP`, `DRM`, `TRP`) — the mnemonic only,
  never the `Dxx` class-name ordinal (§2.2). Top-level section classes may use
  3–4 letters (`SYOV`, `CURS`, `ORGA`); all others use up to 6 derived from the
  class name (`EXTSY` for `ExistingSystemEntry`).
- **Class-level IDs are globally unique** across the whole model. When two class
  names would collide, the class closer to the root takes the shorter/cleaner ID.

### 6.2 List container `@SectionId` — the field-suffixed rule

A `List<T>` field is a distinct document section (§4.1 consequence 2) and needs
its **own** container ID, formed as:

```
<elementId>-<FIELDSUFFIX>-LST     (container @SectionId)
<elementId>-<FIELDSUFFIX>-xxx     (numbering @SectionIdPattern)
```

- `<elementId>` is the class-level `@SectionId` of the element type `T`.
- `<FIELDSUFFIX>` is the **field name uppercased, non-alphanumerics dropped,
  truncated to the first 4 characters** (`systems` → `SYST`,
  `inScopeProcesses` → `INSC`). It is a **mechanical transform**, not a
  hand-authored mnemonic — the derivation is reproducible from the field name
  alone.

```dart
@SectionId('EXTSY-SYST-LST')
@SectionIdPattern('EXTSY-SYST-xxx')
List<ExistingSystemEntry> systems = [];
```

**The scope is universal:** *every* list field carries a field suffix, not only
those with a same-type sibling. This gives one uniform container-ID form across
the model instead of two. As of the current model that is **578 list containers,
all three-token, all with a 4-character suffix, all paired with a `-xxx`
pattern** — there are no legacy two-token `<elementId>-LST` IDs left.

The field-name suffix works because Dart forbids duplicate field names within a
class — so two same-type lists in one class (e.g.
`ProcessScopeSummary.inScopeProcesses` and `outOfScopeProcesses`) get **distinct**
container IDs (`PRSCEN-INSC-LST` vs `PRSCEN-OUTO-LST`) instead of colliding. The
element *type* is always recoverable as the first token before the first `-`.

### 6.3 Uniqueness namespaces (enforced by the validator)

The scheme rests on **sibling-scoped**, not globally-flat, addressing: a section
is addressed by **parent path + local container ID**. That is the deliberate
choice (the rejected alternative was flat per-document uniqueness, which would
have needed an extra parent discriminator folded into every container ID).

- **Class-level IDs:** globally unique. Class-level and container IDs live in
  **different namespaces** — a container ID is never compared against class-level
  IDs.
- **Container IDs:** unique **within a class** (per-class uniqueness). The field
  suffix guarantees this by construction; the validator enforces it as a guard,
  so a later-added second list cannot silently collide. Error tag:
  `§8.6 @SectionId per-class uniqueness`.
- **Type-consistency:** a given container ID maps to **exactly one** element type.
- **Pattern pairing:** the `@SectionIdPattern` must mirror the container
  `@SectionId` (`-LST` ↔ `-xxx`). Error tag:
  `§8.6 @SectionId/@SectionIdPattern pairing`.

**Cross-class sharing is legitimate.** Two *different* classes that each declare a
list of the same element type *with the same field name* share one container ID
(e.g. `CurrentWorkflowEntry.outputs` and `WorkflowStepEntry.outputs` → both
`WOOUEN-OUTP-LST`). They sit under different parents, so under sibling-scoped
addressing they never collide. Container IDs are unique among **siblings**, not
globally.

### 6.4 Instance numbering in live documents

The `-xxx` placeholder is replaced at document-edit time by a generated suffix.
This behaviour is owned by the `tom_som_<lang>_runtime` generators and pinned by
the emitter/conformance tests; it is **not** something model authors hand-write.
Authors do, however, need to know the contract, because the editor and every
language binding expose it.

**Suffix format — two-letter date code + within-day sequence number:**

- **Month** → letter `A`…`L` (Jan = A … Dec = L).
- **Day** → `A`–`Z` for days 1–26, then `0`–`4` for days 27–31.
- **Sequence** → `max(existing number for that day) + 1`.

So a metric added on **March 5** yields `…-CE1` (C = month 3, E = day 5), the
next same-day item `…-CE2`, etc.

**The runtime rules (all nine languages behave identically):**

| # | Rule |
|---|------|
| 1 | **Max+1 within the day.** A new item takes `max(existing same-day number) + 1`. IDs **never renumber** on delete; deleting the current max frees that number for reuse. |
| 2 | **Section id and sequence path are decoupled.** The stored section id identifies the item; its position in the list is a separate, positional address. Reordering a list changes positions, never ids. |
| 3 | **An explicit id override keeps the pattern prefix.** Callers may supply the numbering suffix, but not a different prefix — the prefix is fixed by the `@SectionIdPattern`. |
| 4 | **The pattern prefix is the pattern minus its trailing `x` run** (`EXTSY-SYST-xxx` → `EXTSY-SYST-`). |
| 5 | **Duplicate ids are rejected**, not silently accepted — the add-with-id path raises a section-id-collision error. |
| 6 | **Serialization order is opt-in.** Emission order follows `@SerializationOrder`; nothing is reordered implicitly. |
| 7 | **The structural accessor is `$`-namespaced** (or the nearest per-language equivalent, §9.1) so it can never collide with a model member name. |
| 8 | **Conformance is corpus-pinned** — the numbering behaviour has its own golden corpus files, separate from the document-format corpus. |

**Add API — three variants per language:** a plain add (today's date, next
number), an add-on-date variant taking month + day, and an add-with-explicit-id
variant. Dart: `add` / `addOn` / `addWithId`; Go: `Add` / `AddOn` / `AddWithID`;
Rust: `add` / `add_on` / `add_with_id`; C: `som_list_add` / `som_list_add_on` /
`som_list_add_with_id`; C++: `add()` / `addOn()` / `addWithId()`.

---

## 7. Traceability and structural invariants

### 7.1 Traceability annotations

The 12 Phase 3 documents derive from the SBP, and that derivation is encoded:

- **`@Document(name, description, basedOn: [...])`** marks a class as a document
  root and names its upstream documents.
- **`@MapsTo`** records that a target-document section maps back to an SBP
  section (the shallowest SBP class whose whole subtree flows to one document).
- **`@DetailedIn`** records that an SBP section is elaborated in a downstream
  document; it must sit under an ancestor carrying `@MapsTo`.
- **`@SecondLevelSectionId`** (reserved) derives second-level IDs; it implies
  `@DetailedIn`.

### 7.2 The mechanical structural invariants

The validator enforces the following structural invariants (implementation:
`tom_specs_clitool/lib/src/validator.dart`, exported as
`validateStructuralInvariants()`; mapping-side statement: `som_mapping.md` §12):

1. `@SectionId` **global uniqueness** (class-level namespace).
2. `@SectionIdPattern` uniqueness / container-id pairing (per §6.3).
3. **`@SectionId` coverage** — every reachable class carries one, *except*
   classes reached only through a `@SectionIdPattern` subtree (transitive
   exemption).
4. **`@DetailedIn` ⇒ ancestor `@MapsTo`**.
5. **`@SecondLevelSectionId` ⇒ `@DetailedIn`**.
6. **Per-`@Document` detail-count budget** (7–15 top-level entries).
   `@CodeSpecsProjection()` roots are exempt from *this check only* (§2.5).
7. **Root-independent section-id resolution** — a class reachable from more than
   one `@Document` root must resolve to the same id from every root. Both id
   mechanisms are root-independent by construction; the case actually rejected is
   **structural-mode mixing**, i.e. a class reached both as the direct element of
   a `@SectionIdPattern` list *and* as a standalone complex section field
   (`@Reference` edges excluded).
8. **§4.3 member-shape legality**, `@ContentType` compatibility, and **cycle
   detection**.

The outliner runs the full invariant set before writing; it exits non-zero on any
error, so a clean outline is proof of a valid model.

---

## 8. Annotations (summary — see the annotation spec for detail)

The annotation vocabulary lives in `tom_specs_core`. The **per-annotation
reference** is `tom_specs_core/README.md`; the **mapping semantics** (what each
annotation does to the emitted document/schema) are `som_mapping.md` §5. This
section catalogues them so an author knows what exists and when to reach for
each.

**Identity & structure:** `@Document`, `@SectionId`, `@SectionIdPattern`,
`@Headline`, `@Form`, `@ContentType`, `@Unused`, `@Reference`,
`@SerializationOrder`.

**Cardinality & ordering:** `@Min`, `@Max`, `@Position`, `@ForEach`,
`@AccessKey`.

**Traceability:** `@MapsTo`, `@DetailedIn`, `@SecondLevelSectionId`, `@SeedFor`,
`@StandardReferences`.

**CodeSpecs link:** `@CodeSpecKind(List<CodeSpecPart>)` — the general,
type-level DocSpecs→CodeSpecs mapping on a SOM section class; and
`@CodeSpecsProjection()` — marks a generation-projection `@Document` (§2.5).
The concrete instance-level forward link is the `codeSpec` member on
`DocSpecsSection` (§4.2); the backward code→doc link is `@DocSpec`/`DocRef`,
which lives in `tom_code_specs`, not here.

**Follow-up taxonomy:** `@FollowUpKind(List<FollowUpProcess>)` — tags a SOM
follow-up subtree root with its process taxonomy.

**Validation & authoring guidance:** `@Prefix`, `@PatternCheckId`,
`@PatternCheck`, `@TextRequired`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`,
`@MinLength`, `@MaxLength`, `@ContentHelp`, `@Comment`.

Annotations are split into **visible** (affect outline rendering — `@Min`/`@Max`,
`@Position`, `@ForEach`, `@TextRequired`, `@ContentType`, `@Unused`, `@Comment`,
`@Reference`, `@SectionId`, `@SectionIdPattern`) and **schema-only** (all the
rest — used for schema generation/validation but not shown unless
`--show-schema-annotations` is passed). See `specs_model_outliner.md` §4.13.

Two authoring notes with model-wide consequences:

- **`@Headline` supplies a *default* only.** The stored `headline` on the node
  wins; the effective default chain is `stored > @Headline > name-derived`. A
  field-level `@Headline` on a scalar list titles the **container** only — item
  stems stay name-derived unless the *element class* carries a class-level
  `@Headline`.
- **`@SerializationOrder` is stamped in bulk**, not hand-maintained, by
  `tom_specs_clitool/bin/stamp_serialization_order.dart`.

---

## 9. The multi-platform SOM component (`tom_som`)

From `tom_specs_model` the toolchain generates a **multi-language specification
access API**. This is *mentioned* here; the authoritative specification is
`multiplatform_spec_model.md`.

- **Nine languages, all shipped:** Dart (reference), Python, Java, JavaScript,
  TypeScript, Go, Rust, C, C++ — ~3080 classes, 6 enums, and the full set of
  document roots (§2.5) in each language.
- **Two projects per language:** `tom_som_<lang>_v0` (generated typed facade,
  per major version) and `tom_som_<lang>_runtime` (hand-written generic runtime,
  unversioned).
- **Two parallel access paths** over the *same* document: a **type-safe** typed
  facade (code completion, compile-time safety) and a **generic / meta-model**
  path (the path-keyed `SpecDocument` + the emitted `meta/spec_model.meta.json`),
  which alone is sufficient for full read/write/validate/load/save. The meta-data
  file is **lossless** — every class, member, and annotation argument is exposed.
- **Versioning:** documents record the authoring `modelVersion`; a facade may
  edit older same-major documents (upgrading the stamp) but must reject newer
  ones; cross-major is read/convert-only. Instantiation performs the check.
- **Committed artefacts:** the generated trees are checked in, reviewable in
  diffs, and regeneration is idempotent.

### 9.1 Per-language structural-accessor surface

Rule 7 of §6.4 requires the structural accessor (the node's section id) to be
**collision-proof against model member names**. Each language resolves that in
its own idiomatic way; the names are fixed, not per-generator choices:

| Language | Accessor | Note |
|----------|----------|------|
| Dart | `SomNode.$sectionId` | `$` prefix — illegal as a generated member name |
| Python | `spec_section_id` | reserved `spec_` prefix |
| Java | `$sectionId` | `$` prefix |
| JavaScript / TypeScript | `$sectionId` getter + setter pair | `$` prefix |
| Go | `SectionID()` / `SetSectionID()` | method pair |
| Rust | named `node` field | struct field namespacing makes a guard unnecessary |
| C | plain struct field | struct field namespacing makes a guard unnecessary |
| C++ | `SomNode::sectionId()` / `setSectionId()` | method pair |

Supporting specs: `spec_object_model_config.md` (the `tom-spec-object-model`
generator config), `spec_model_meta_schema.md` (the meta-data format),
`som_toolchains.md` (per-language toolchain matrix).

---

## 10. The tools (mentioned — see each tool's spec)

The SOM is surrounded by tooling. These are *mentioned* here; each has its own
specification.

### 10.1 CLI — `tom_specs_clitool`

The analyzer-based generation host. It hosts the **outliner** (renders the class
tree from any root), the **validator** (all §4 and §7.2 invariants), the **model
JSON exporter** (the lossless meta-data), and the **multi-language SOM
generator** (`bin/generate_som.dart`). It runs against an embedded SDK summary,
so no installed Dart SDK is required. Specs:
`tom_specs_clitool/README.md`, `specs_model_outliner.md` (the outliner tool),
`som_mapping.md` (what it emits), `spec_object_model_config.md`,
`spec_model_meta_schema.md`, `analyzer_wo_sdk.md`.

### 10.2 Reviewer — `tom_specs_reviewer` (`tom_ai/ai_build/`)

A Flutter app for **reviewing the object model itself**. It browses the exported
class graph (`assets/spec_model.json`, produced by
`tom_specs_clitool/bin/model_json.dart`) as a tree and records per-node
observations, persisted to YAML keyed by structural path
(`TOM_SPECS_REVIEW_FILE` override; default
`<cwd>/review/structure_review.yaml`). The recordable axes are:

- **destination** — CodeSpecs / follow-up / both / neither, as one choice with
  an explicit undecided state, since the split is a decision rather than two
  independent flags;
- **scope and progress** — scope flags, `stop here` / `add details` markers, a
  reviewed checkmark, free-text comment;
- **structure** — list-vs-single, content-vs-form, and the closed-choice
  judgements (`@OneOf` set warranted, `@Case` set incomplete);
- **annotations** — section id / pattern wrong or colliding, `@MapsTo` /
  `@DetailedIn` handoff pointing at the wrong target, wrong `@ContentType`,
  wrong or missing `@StandardReferences`, and the keep-or-drop verdict on an
  `@Unused` marking;
- **CodeSpecs mapping** — kind missing, kind wrong/incomplete, the proposed
  `CodeSpecPart` kinds, or "not CodeSpecs at all";
- **follow-up mapping** — `@FollowUpKind` missing, declared processes
  wrong/incomplete, and the proposed `FollowUpProcess` codes.

The two vocabularies are validated differently, because they are different kinds
of set: a proposed `CodeSpecPart` is **rejected** if it is not in the enum,
whereas a proposed `FollowUpProcess` code outside the enum is **warned about and
kept** — that taxonomy is explicitly extensible, so proposing to extend it is
itself a finding. Its output feeds further development of the model. It is
explicitly **not** a specification editor.

### 10.3 Editor — `tom_specs_editor` (`tom_forge/`)

The **spec authoring app**: a Tom Forge desktop app for authoring DocSpecs /
CodeSpecs / Implementation specifications, built on the Forge shell and the
shared agent UI. It consumes the same generated `spec_model.json` and drives the
document editor from it, with DocSpecs + markdown import/export. It uses the
generic meta-model (`tom_som_dart_runtime`), not the typed facade. Spec:
`tom_specs_editor_specification.md` (and `multiplatform_spec_model.md` §7 for the
runtime relationship).

---

## 11. Reference index — where each rule is authoritative

| Subject | Authoritative document |
|---------|------------------------|
| **Mapping — object model ↔ md / yaml / schema, metadata tree, generated surfaces, parse+validate API** | **`tom_specs_model/doc/som_mapping.md`** (the single mapping authority) |
| Model-authoring rules (this document's subject) | `tom_specs_som_guidelines.md` (here) |
| Outliner tool — notation, type expansion, output | `tom_specs_model/doc/specs_model_outliner.md` §1–§5, §8–§11 |
| Per-annotation reference | `tom_specs_core/README.md` |
| Field categories inventory | `tom_specs_model/doc/field_classification.md` |
| Form-decomposition targets | `tom_specs_model/doc/form_decomposition.md` |
| How the section-ID scheme was arrived at (design record) | `section_id_pattern_plan.md`, `field_suffix_list_id_plan.md` (both COMPLETE) |
| Structural invariants (implementation) | `tom_specs_clitool/lib/src/validator.dart` (`validateStructuralInvariants()`), `som_mapping.md` §12 |
| Multi-platform SOM component | `multiplatform_spec_model.md` |
| Generator config / meta-schema / toolchains | `spec_object_model_config.md`, `spec_model_meta_schema.md`, `som_toolchains.md` |
| DocSpecs format itself (schemas, section types, validation) | `_ai/quests/doc_specs/doc_specs_specification.md` |
| DocSpecs ↔ CodeSpecs link, `@CodeSpecKind`, the parts catalogue | `codespecs_mapping.md` |
| Creation process / phases | `tom_specs_project_flow.md` §PF-PHA, `overview.tom_specs.md` |
| Roles / quality gates | `tom_specs_project_flow.md` §PF-ROL, §PF-GAT |
| Solution Blueprint → Phase 3 document mapping | `tom_specs_project_flow.md` §PF-FLW |
| Issue workflow / upgrade cycles | `tom_specs_project_flow.md` §PF-ISS, §PF-UPG |
| Editor / reviewer | `tom_specs_editor_specification.md` |
