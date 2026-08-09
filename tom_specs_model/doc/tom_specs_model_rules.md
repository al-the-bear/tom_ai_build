# TomSpecs Model Rules

**Quest:** tom_specs
**Status:** Normative. The single authority for how a class in the
`tom_specs_model` Dart package is written.
**Audience:** Anyone extending the `tom_specs_model` object model, authoring or
reviewing `@SectionId` / traceability annotations, running the CLI tooling, or
reading a generated outline.

---

## 1. Purpose and scope

This document is the **single, complete answer to "how do I write a class in
`tom_specs_model`"** — how a model class must be written, how section ids are
formed, what the annotations mean for the author, how the outliner renders the
result, and what the surrounding tools do with it. It is deliberately layered:

- **Authoring rules are detailed here.** The universal section structure, the
  legal member shapes, the field classification, the form-decomposition targets,
  the section-ID scheme, the annotation vocabulary, the outline notation, and the
  traceability invariants are stated in full so this document is sufficient to
  design or review a model change without opening the source.
- **Tools, wire formats, and annotation internals are *mentioned* here and
  *specified* elsewhere.** The CLI (`tom_specs_clitool`), the editor
  (`tom_specs_editor`), the reviewer (`tom_specs_reviewer`), the multi-platform
  generated component (`tom_som`), and the individual annotation contracts each
  have their own specification. This document points to those specs rather than
  restating their internals.

For tools and annotations this document is the map, not the territory — but it
**is** the territory for the model-design, section-ID, and outline-notation
rules it details.

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

### 1.2 Boundary — these rules vs. the mapping authority

Two documents cover the same object model from opposite ends and must not
duplicate each other:

| Document | Owns |
|----------|------|
| **This document** (`tom_specs_model_rules.md`) | **Authoring.** What an author may write and must write: legal member shapes, class style, naming, field categories, form size targets, how to choose a `@SectionId`, which annotations to reach for, what the validator will reject, how the outline renders. |
| **[`som_multiplatform_spec_model.md`](som_multiplatform_spec_model.md)** | **Mapping and mechanics.** How the authored model becomes generated code and bytes: the nine-language generation, the metadata tree, the generated SOM surfaces, md serialization, hierarchical yaml, DocSpecs schema generation, the embedded parse/validate API, packaging, the conformance requirements. |

`som_multiplatform_spec_model.md` is the **single mapping authority**. Where a rule here has
mapping consequences, this document states the rule an author needs and cites the
section there.

Where either document is silent, the Dart reference implementation
(`tom_som_dart_runtime`, `tom_specs_clitool`) is the tiebreaker and the document
must be amended to match it in the same change.

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

Document root class names carry a **`D00`–`D13` ordinal prefix**
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
with traceability annotations (§10). The document roots (`D01`–`D12`) and their
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
| `tom_specs_core` | `tom_ai/ai_build/` | Annotation library (the `@…` vocabulary) **and** the `DocSpecsSection` / `DocSpecsForm` section base types (§5.2). |
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

## 4. The universal section structure

**DocSpecs markdown is the key target format of the object model.** A TomSpecs
specification is a **document for human readers**; the DocSpecs `*.md` file is
the logically primary target format. Everything the model expresses must be
expressible as a DocSpecs document, and a DocSpecs document must be *parseable
back into* the model. That constrains the model to one universal shape. The SOM
document format is compatible with the doc_scanner / doc_specs format and
describable as a DocSpecs schema
(`_ai/quests/doc_specs/doc_specs_specification.md`).

Every document is a tree of **sections**. Always, at every level, a section is
exactly:

```
<headline (with <!--[ID]--> comment)>
<content (optional body text)>
<subsections…>
```

There are no other section kinds. Four rules follow, and an author must
internalise all four:

1. **Every section has a section id and a headline.** Both are first-class
   *stored* values on every section — fixed sections and list items alike —
   persisted in md and yaml, surviving modification through all three
   representations (object model, yaml, md).
2. **A list is always an outer section** containing the entry sections of the
   list. A `List<T>` field is **not** a bare repetition — it is a real section in
   its own right (the `-LST` container, §7.2) that *contains* one subsection per
   item. The content of the outer (container) section has **no meaning defined by
   the tom_specs description** — it may hold free narrative introducing the list,
   but the model assigns it no semantics and it is never data.
3. **Non-list sections and list entries follow the same uniform shape:**
   content (with or without `@Form`) plus optional subsections. A `@Form`
   structures the section's content — it only says *how the content text is laid
   out* (`FieldName: value` lines) and lets the runtime split the text into a
   pre-form narrative plus typed values. A form is never a different kind of
   node.
4. **Nesting depth is unbounded.** A subsection has the same shape as its
   parent, with no depth limit. There is no six-heading-level cap in the md
   format: heading levels beyond `######` are represented by continuing the `#`
   run, which the `tom_doc_scanner` grammar (`#{1,}`) accepts.

Terminology used throughout: *section id* = the `@SectionId` mnemonic
(`INSC`); *member name* = the exact field/class identifier in the model;
*path* = the runtime navigation path (`DEMO/introductionAndScope/GOAL-ITEM-1/content`);
*kind* = one of the seven `SpecFieldKind` values (`list`, `form`, `section`,
`content`, `enum`, `complex`, `scalar`).

### 4.1 Running example

All examples use this miniature model (a document root, a content section, a
nested content child, a form, and a list):

```dart
@Document('Demo Document', 'A miniature document used by the format examples.',
    basedOn: [])
@SectionId('DEMO')
class D99DemoDocument {
  @SerializationOrder(1)
  String? content; // document preamble

  @SerializationOrder(2)
  IntroductionAndScope introductionAndScope = IntroductionAndScope();

  @SerializationOrder(3)
  DocumentControl documentControl = DocumentControl();
}

@SectionId('INSC')
@ContentHelp('Describe what the system covers and what it explicitly '
    'does not cover.')
class IntroductionAndScope {
  @SerializationOrder(1)
  @ContentType('markdown', 'Scope narrative')
  String? content;

  @SerializationOrder(2)
  Goals goals = Goals();
}

@SectionId('GOAL')
class Goals {
  @SerializationOrder(1)
  String? content;

  @SerializationOrder(2)
  @SectionId('GOAL-ITEM-LST')
  @SectionIdPattern('GOAL-ITEM-xxx')
  @Min(1)
  List<GoalEntry> entries = [];
}

@SectionId('GOEN')
class GoalEntry {
  @SerializationOrder(1)
  String? content;
}

@SectionId('DOCO')
@Form([
  Field('version', String, hint: 'e.g. 1.0'),
  Field('approvedBy', String),
  Field('reviewCount', int),
])
class DocumentControl {
  String? version;
  String? approvedBy;
  int? reviewCount;
}
```

---

## 5. The object model

A TomSpecs document *is* a class instance graph. One `@Document` root class is
the top-level document section; each reachable class is a section; each member
is either the section's own content, a child section, or a list of child
sections. Serialization — to yaml or md — is a single depth-first walk of that
tree in `@SerializationOrder` order.

The validator (`tom_specs_clitool/lib/src/validator.dart`) checks every rule in
this section and classifies each violation as an **error** (blocks output) or a
**warning** (reported, does not block).

### 5.1 Canonical member shapes

A model class may contain **only** the following six member shapes — nothing
else. The validator enforces these as hard errors:

| # | Shape | Meaning |
|---|-------|---------|
| **(1)** | `String? content` (plain) | The section's OWN content. The section id comes from the **class**, not the field. |
| **(2)** | `String? content` with `@Form` | The `content` value is the pre-form narrative, followed by the form's field members. |
| **(3)** | `DocSpecsSection <name>` with a **field-level `@SectionId`** (optionally `@Form`) | An **inline sub-section** whose content IS this field. A `@Reference` field is this shape (its id is required). |
| **(4)** | `<SectionClass> field` | A sub-section class; the class owns the id (a field-level id may still override). |
| **(5)** | `List<SectionClass>` with `@SectionId` + `@SectionIdPattern` | A list of sub-section classes; each element gets a per-instance id from the pattern. |
| **(6)** | `List<DocSpecsSection>` with `@SectionId` + `@SectionIdPattern` (optionally `@Form`) | An **inline list** of content sub-sections. |

Hard error cases:

- **Non-String scalar** — any free `int`/`bool`/`double`/`num`/`DateTime`
  field. Typed scalars are legitimate only as `@Form` field members, never as
  free model fields.
- **Non-`content` section member without a field-level `@SectionId`** — every
  descriptively-named `DocSpecsSection?` field is an inline sub-section (shape
  (3)) and must be addressable.
- **Misused reserved name `content`** — a field named `content` that is not a
  plain `String`/`String?` value, or a `content` field carrying a field-level
  `@SectionId`. The name `content` is reserved for the section's own content;
  its id comes from the class.

Enum fields are outside these rules — neither required to carry an id nor
forbidden.

There is **no such thing as a bare `String` section member**, and `List<String>`
is not a legal section list; shapes (3) and (6) are the object forms those
members take.

### 5.2 `DocSpecsSection` — the section base type

**Every section-bearing member is an object, never a bare `String`.** The base
type is `DocSpecsSection`
(`tom_specs_core/lib/src/sections/docspecs_section.dart`):

```dart
class DocSpecsSection {
  String? headline;          // stored headline (overrides the @Headline default)
  String? id;                // stored section id — the <!--[ID]--> marker
  List<String> codeSpec;     // instance-level DocSpecs → CodeSpecs link
  String? content;           // body text
  DocSpecsForm? form;        // parsed @Form content, once split
}
```

- A `DocSpecsSection` holds **headline, id, content, an optional `codeSpec`
  forward link, and an optional parsed `DocSpecsForm form`** — representing a
  simple section with no subsections. `DocSpecsForm` holds the pre-form-field
  content (already split off) plus one parsed value per `@Form` field. Typed
  per-field members are generated onto the SOM classes; `DocSpecsForm` is the
  generic model-side holder.
- **Every model class extends `DocSpecsSection`** — including the section leaves
  in `tom_specs_core` and the `DocSpecsProject` container root — so the whole
  model is an object graph a `*.md` document can actually be **parsed into**:
  headline and id are stored *per node* rather than derived. The validator
  enforces this as a structural invariant.
- **The reserved `content` member stays `String?`**, re-declared with `@override`
  on each class to carry its per-class annotations. It is the section's own body
  text, not a sub-section, so it does not become an object.
- **Home:** both types live in `tom_specs_core`, not `tom_specs_model` — like
  `TextSection` and the other section leaves, the base type is metamodel
  infrastructure and must stay outside the analyzer-scanned package (§3).

**`List<String> codeSpec` — the concrete DocSpecs→CodeSpecs forward link.**
A per-section member recording the CodeSpec code location(s) a concrete section
maps to (e.g. `["CsOrder", "CsOrder.total", "CsOrderRepository"]`). This is the
*instance-level* half of the bidirectional DocSpecs↔CodeSpecs link defined in
`codespecs_mapping.md` §9.2 — the type-level `@CodeSpecKind` SOM annotation
(§9.1 there) is its general counterpart, and the code-side `@DocSpec` annotation
(§9.3 there) is its backward counterpart. It is **sparse and optional** (empty ⇒
no section maps to code), and it serializes exactly parallel to the stored
`headline`: the runtime holds it in a sparse per-section store (comma-joined in
state, fingerprint, json, yaml, md), it has **no effective default** (staged
whenever present), and it is emitted in md and yaml as documented in
`som_multiplatform_spec_model.md` §11.2 and §12.2.

**Meta-tree stability contract:** `DocSpecsSection`-typed members classify as
`content` nodes and report `String`/`String?`/`List<String>` at the
meta/JSON/outline boundary (`ModelField.metaTypeName`), and subclasses stay on
the `complex` expansion path — so the exported meta tree, the DocSpecs schemas,
`spec_model.json`, the outlines and all nine SOM emitter outputs are unaffected
by the object typing. The engine (`spec_ops.g.dart`) is the one consumer that
sees the real types: section members are `SpecSlot.node`/`SpecSlot.list` child
slots, and `DocSpecsSection` itself is registered as a content leaf.

### 5.3 The three member shapes on the serialization walk

Walking a class in serialization order, each member is exactly one of:

1. **`String? content` (the content member).** The section's body text —
   everything between the section's heading and its first sub-section. It is
   *not* a sub-section. Serialized as the `content` yaml key / the prose
   directly under the md heading. `@Form` classes replace the free content with
   `FieldName: value` lines. Always emitted **above** any child sections.
2. **A singleton complex member (`Foo field;`).** One child section. Recurse
   into `Foo`'s class, whose `@SectionId` becomes the child section id. One
   nesting level deeper in both formats.
3. **A list member (`List<Foo> field;`).** A **two-level** section hierarchy
   (§7.5).

### 5.4 Remaining type constraints

| Rule | Severity | Detail |
|------|----------|--------|
| **No primitive non-String scalars** | error | Form/scalar leaf values are `String`, `String?`, or an enum. No `int`, `double`, `bool`, `num`, `DateTime`. Dates and numbers are `String?` with a type hint on the `@Form` field. |
| **No `List<primitive>`** | error | A repeated section is `List<SectionClass>` or `List<DocSpecsSection>` (shapes 5/6), never a list of raw scalars. |
| **`content: String?` required** | error | Every section class carries a `content: String?` override (§5.2) — the section text between the headline and the next headline. The only exemption is the container root (T1), which is a structural node rather than a section. |

### 5.5 Class style and naming

| Rule | Description |
|------|-------------|
| No constructors | A default constructor is implied; classes are plain data holders. |
| No `final` / `const` | Plain mutable instance fields, like nested records. |
| Non-nullable defaults | Non-nullable fields get a valid default; nullable fields stay null. Lists default to `[]` (each instance owns its own mutable list). |
| No computed properties | Only concrete instance fields are model members — no getters, static fields, or derived properties. |
| Singular match preferred | Singular complex field names should match their type name, lowercase first letter (`SystemOverview systemOverview`). A mismatch (`header` for `DocumentHeader`) is allowed, not an error — the outliner then shows `fieldName:TypeName`. |
| List names always differ | List field names differ from the singular element type and are always shown as `fieldName:TypeName`. The plural field name is **structurally significant**: it names a document section level whose items are subsections. |
| Inheritance | Subclasses fully re-declare their fields (replacement, not augmentation); the structure is what each class declares plus non-redeclared inherited fields. |
| Reachability | Only types reachable from a document root are part of that document's structure. |

### 5.6 Content documentation rules

Every `String? content` field must be documented:

| Class type | Documentation source |
|------------|---------------------|
| `*Section` class (`TextSection`, `DiagramSection`, …) | `@ContentType` on the `content` field inside the section class declares the format; the human-readable description is the doc-comment on the **using field**. |
| Regular class with `String? content` | `@ContentType(type, 'description')` on the `content` field (mandatory description). |
| Container class (content unused) | `@Unused()` on the `content` field — no narrative text expected. |

ContentType constraints:

- **`@ContentType('Form')` (default):** the class's other scalar fields are the
  form fields inside the content.
- **Non-Form content** (`DDL`, `SQL`, `Dart`, `ER-Diagram`, `Mermaid`, …): the
  class **must not** have other scalar fields — the content occupies the full
  text. Complex children are still allowed but uncommon (diagrams and code are
  usually leaves).

### 5.7 Reachability and cycles

- Only types **reachable from a document root** are part of the model;
  unreachable utility types are silently omitted from the outline.
- **Cycles must not exist.** A structural cycle is a hard error naming the types
  involved. `@Reference`-marked links are *not* traversed and therefore never
  count as cycles.

### 5.8 Keep-a-class and keep-a-level criteria

Shapes (3)/(6) let a leaf sub-section be a *field* instead of a class, and a
single-subsection wrapper level can be *collapsed* — but only when safe:

- **A sub-section stays a class** when it is **shared** (referenced by more
  than one parent field across the model — e.g. `DocumentHeader`) or is a
  **form-bearing list element** (a `List<L>` element whose `L` carries
  `@Form`; a scalar list has no place for per-element form fields).
  The validator never flags kept classes — a kept class is the correct shape,
  not a deferred collapse.
- **A wrapper stays a level** when its own content has meaning by itself:
  it (or a field) carries `@Form`; a leaf carries substantive `@ContentHelp` /
  `@StandardReferences` / non-Form `@ContentType`; it is shared; or it declares
  a named leaf besides `content`. Only when *none* of these hold is the
  wrapper pure indirection — the validator emits a
  `tom_specs_model_rules.md §5.8 collapsible-wrapper` **warning** for such
  candidates.

A **pure single-list wrapper** (`{content?}` plus exactly one list) is doubly
redundant under the §4 list-as-outer-section rule, because the list already
provides its own section level; it is kept only when a keep-a-level exemption
above applies to it.

The model is at the steady state, and the steady state is **held by a gate**:
`validator.dart` emits the collapsible-wrapper warning, and a test asserts the
model emits none. So a wrapper level added tomorrow without an exemption fails
the suite rather than waiting for someone to run a survey.

### 5.9 List ownership — a subset is never a second list

A `List<T>` field **owns** its elements: each element is a document sub-section
that exists at exactly one place in the tree. Two same-type sibling lists in one
class must therefore **partition** their elements — no element may appear in
both.

A list holding a *subset* of a sibling list breaks that. It re-states sections
the sibling already owns, and neither the model nor either wire format keeps the
two copies in agreement: the author writes the element twice, then edits one of
them. The duplication is not merely wasteful, it is **unresolvable** — a reader
finding two differing copies has no rule saying which is current.

A subset takes one of two other shapes, chosen by what the subset actually *is*:

| The subset is… | Shape |
|----------------|-------|
| **A property of the element** — its members share an attribute the element itself carries (manual, error-prone, deprecated) | An `@Form` field on the element type. The subset is a **view**, computed by filtering; it is not a section. |
| **One end of a relation to a *different* owned collection** — its members are picked out by a link to some other section, not by anything intrinsic | A `@Reference` list (§6.1 **ref**) on the section at the other end. |

**The type boundary tells them apart.** A `@Reference` list points from a section
of type A at sections of type B ≠ A: `WorkflowActorEntry.participatingSteps`
records which steps *this actor* takes part in, a fact about the actor↔step pair
that is stored nowhere else. A subset list points from the owner of a `List<T>`
at part of that same `List<T>` — no second party, and so no fact beyond an
attribute the element can carry itself. Reaching for `@Reference` to express a
subset therefore misapplies it: it borrows the pointer semantics while there is
nothing at the far end to point *from*.

**An aggregate elsewhere does not justify a list.** A roll-up such as
`ProcessPerformanceSummary.errorProneStepsCount` counts a property, so the
property is what must exist per element; the aggregate reads it. A count with no
element-level property behind it is a symptom that a subset list is standing in
for a missing field.

---

## 6. Field classification and form decomposition

### 6.1 Field categories

Every non-`content` textual field falls into exactly one category:

| Category | Meaning | Modelled as |
|----------|---------|-------------|
| **form** | short value (a form field) | `String?` inside a `@Form` — a *value*, not a section |
| **text** | short description, 1–3 sentences | `DocSpecsSection?` with a field-level `@SectionId` (shape (3)) |
| **long** | multi-paragraph narrative | a `TextSection` (its own section class, shape (4)) |
| **ref** | cross-reference to data owned elsewhere | `@Reference` field |

How to choose:

- **form** if the value is a short, atomic datum that belongs *inside* a
  section's content — an id, a name, a date, a status, an enum. It is the only
  category that stays a bare `String?`: a form field is a value inside a
  section's content, not a section of its own.
- **text** if the author will write one to three sentences that deserve their own
  addressable heading. Every other category is an object (§5.1/§5.2).
- **long** if the author will write multiple paragraphs. A `TextSection` gives
  the narrative its own class, so it can carry `@ContentType`, `@ContentHelp`,
  and its own children later without a shape change.
- **ref** if the data is *owned by another section* and this field only points at
  it. A `@Reference` renders as an ordinary content-kind inline sub-section keyed
  by its field-level `…-REF` id whose value is the referenced section id, and is
  never followed in traversal. A `@Reference` **list** points at a *different*
  owned collection; it is never a subset of a sibling list in the same class
  (§5.9).

**`@Reference` is not the same thing as a reference-valued form field.**
`@Reference` sits on a *Dart member whose type is a section class*: it is a
structural edge between sections that the traversal deliberately does not
follow. A reference-valued form field is a **form** field — a bare `String`
inside a `@Form` — whose *value* is an id that some other section's registry
declares. Different carrier, different value kind, so the two never overlap and
neither replaces the other. The form field states its target with the `refersTo:`
parameter on `Field` (§6.2); an ordinary `@Reference` needs no such parameter,
because its target is its Dart type.

### 6.2 Reference-valued form fields (`refersTo:`)

A form field whose value is an id drawn from another section's registry declares
that contract with `refersTo:` on `Field`:

```dart
Field('sourceRouteId', String, required: true, refersTo: ['SCRTEN.routeId']),
Field('outcomeReference', String,
    refersTo: ['SYERCO.errorCode', 'VMT.@sectionId']),
Field('relatedRequirements', String, refersTo: ['FRE.@sectionId']),
```

Rules:

1. **A target is written `<SECTIONID>.<slot>`.** The section id alone says where
   to look but not what to compare against, so the qualified form is required,
   not optional. A slot is either a **form field name** (rules 4 and 5) or the
   reserved key **`@sectionId`** (rule 6).
2. **The section id names the registry *entry* class, never its `-LST`
   container.** The entries declare the ids; the container merely holds them —
   so the target is `MSGKE.key`, not `MSGKR.key`.
3. **The list is a disjunction.** A value is valid when it resolves in *any*
   listed registry — that is how `SCTREN.outcomeReference` can hold either a
   system error code or a validation message id. A single field value that names
   several ids writes them comma-separated; each part resolves independently.
4. **The named form field must exist and must be `required`.** An optional id
   cannot be a registry key, because entries could omit it.
5. **The target class must be *enumerated*.** It is either a list element type,
   or a singleton subsection of one. A registry entry usually decomposes — the
   list element is `BusinessProcessEntry`, but the id lives one level down in
   its `ProcessIdentification` section, so the target is `PRIDN.processId`.
   That subsection is instantiated exactly once per entry, so its required
   fields enumerate 1:1 with the entries. Naming the outer entry instead fails
   rule 4's existence half: the outer class declares no such form field. A form
   section that exists once per document is not a registry; nothing there ever
   declares a *set* of ids to resolve against.
6. **`@sectionId` targets the entry's own stored section id.** Some registries
   keep their id in no form field at all: a functional requirement's id *is* its
   section id, supplied by the owning list's `@SectionIdPattern` and deliberately
   not restated as a form field (§8 — exactly one storage slot per value).
   Without this slot those registries would be unreachable and every reference to
   them permanently unenforceable. The target still names the **entry class**
   (`FRE.@sectionId`), never the `-LST` container nor the pattern itself, so rule
   2 is unchanged; rules 3 (disjunction) and 4/5's intent carry over. Rules 4 and
   5 are replaced by a **stricter** requirement: the target class must be the
   direct element type of at least one `@SectionIdPattern`-bearing `List<T>`. A
   singleton subsection carries one *fixed* `@SectionId` — it names a single id
   rather than a set — so it cannot back a registry even though rule 5 would
   otherwise admit it. The value resolved against is the item's **effective id**
   (§7.6): its stored id when it has one, otherwise its positional pattern id.
   `@` is a reserved namespace — any other `@`-prefixed slot is a hard error, so
   a future slot can never be misread as a form field that merely does not exist.
7. **A target need only be co-reachable with the referrer from *some* `@Document`
   root.** Most references cross document boundaries by design — a delivery
   acceptance criterion cites a functional requirement, a screen cites an
   authorization role — so the standalone document holding the referrer often
   cannot see the registry at all. That is legal. What is not legal is a target
   reachable from **no** root that reaches the referring class: such a
   declaration is dead, since no document could ever exercise it. See §6.2.1.

Both validation tiers read this one declaration. The **static** tier
(`tom_specs_clitool/lib/src/validator.dart`) checks the class graph: the target
section id exists, it is reachable, and — for a form-field slot — it really does
declare that field as required and is enumerated; for `@sectionId`, that it is a
patterned list's element type. The **instance** tier (the runtimes' document
validator) checks a concrete document: every id a reference field holds is
actually declared by some entry of one of the named registries, and reports a
dangling id otherwise. `refersTo` is carried through the meta into all nine
language runtimes, and the instance-tier reference check is implemented in all
nine — like every other instance-tier check, it is part of the mirrored runtime
surface, not a Dart extra (`som_multiplatform_spec_model.md` §9).

#### 6.2.1 Document scope — how a cross-document reference validates

The instance tier resolves an id against the registries present in **one
document**, and a document holds exactly the classes its `@Document` root
reaches. A reference is therefore only *decidable* from a root that reaches both
the referring class and the target registry's owner. Since the majority of
references cross document boundaries, validating a standalone D02/D08/D10/D12 has
to have an answer for the undecidable case.

**The instance tier skips what it cannot decide.** A reference whose targets the
document's own root does not reach is passed over silently, not reported. The
registry is absent from that document *by construction*, not undeclared, and
reporting it would fail a specification the author wrote correctly. The skip is
silent rather than a warning because `SpecValidationError` carries no severity
axis: a second code would still make `validateDocument(...).isEmpty` false, which
is the same false-invalid problem in a new colour — and a standalone-document
author could not act on it anyway. The document's roots are read off the document
itself (every path begins with its root's segment), so a whole-`DocSpecsProject`
validation contributes the union of all roots and sees every sibling registry.

**The skip is all-or-nothing per declaration.** Because rule 3 makes the target
list a disjunction, one absent registry is enough to make "no registry declares
this id" unsound — the id may legitimately be declared by the registry this
document cannot see. So a reference is checked only when **every** one of its
targets is in scope.

**The static tier bounds the hole** (rule 7). Every target must be co-reachable
with its referrer from at least one `@Document` root, so no declaration ends up
unverifiable everywhere. The check walks the **whole** class map rather than the
Solution Blueprint subtree: within that subtree the pure-projection invariant
makes `D00SolutionBlueprint` reach both ends of every reference by construction,
so a check confined to it could never fire. The case it exists to catch — a
referring class reachable from no root at all — is only visible from the full map.

#### When *not* to annotate

The instance tier turns a `refersTo` mistake into a validation error on a
*specification the author wrote correctly*. So an id-shaped field is annotated
only when every legal value really is a key of the named registries. Three
classes of field stay bare, and staying bare is the right answer for them:

- **The value is deliberately mixed.** Whenever the field's own label or hint
  admits a non-id alternative — "Scenario IDs **or** categories", "recipient IDs
  **or** addresses", "template ID **or** description" — the field is free text
  by design. Annotating it would red-flag the alternative the field was written
  to allow.
- **The registry is owned outside the blueprint.** Some id families are
  referenced but deliberately not declared here, because the set of entries
  belongs to another system: issue ids to the project's issue tracker, help
  topic ids to the documentation system, user story ids to the delivery
  backlog. There is no register to point at, so there is nothing to check
  against. Such a field must **say so**: its label carries an `(external)`
  marker and its hint names the owning system. "Bare id field with an id-shaped
  name and a hint that says nothing about ownership" is not an outcome — it
  reads as a forgotten contract rather than a decided one.
- **Nothing enumerates the ids.** An entry that stores its id solely in its own
  section id is reachable through `@sectionId` (rule 6) — but only when that
  entry is a patterned list's element type. A section that occurs once, with one
  fixed `@SectionId`, names a single id rather than a set; there is no registry
  to resolve against, so a reference to it stays bare.

A bare id field therefore reads as "no registry contract claimed", which is
accurate, rather than as "contract forgotten".

### 6.3 Form decomposition

`@Form` sections target **3–10 fields**. Larger forms are decomposed so the
document stays readable:

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

## 7. Section identity

The section-ID scheme is the load-bearing addressing mechanism of the SOM.
Section ids are short, flat mnemonics identifying the *type* of a section (not
its position), written in uppercase alphanumerics and `-` (`[A-Z0-9-]+`).

### 7.1 Class-level `@SectionId` — the section *type* id

- **Every model class has exactly one `@SectionId`.** It is a globally-unique
  mnemonic of **≤6 uppercase letters** identifying the *type* of a section, not
  its position in the tree.
- Document roots use their short codes (`SBP`, `CLA`, `TOM`, `IFM`, `RSP`,
  `ISC`, `ATS`, `IIS`, `SAS`, `XDS`, `QAP`, `DRM`, `TRP`, `CGP`) — the mnemonic
  only, never the `Dxx` class-name ordinal (§2.2). Top-level section classes may
  use 3–4 letters (`SYOV`, `CURS`, `ORGA`); all others use up to 6 derived from
  the class name (`EXTSY` for `ExistingSystemEntry`).
- **Class-level ids are globally unique** across the whole model. When two class
  names would collide, the class closer to the root takes the shorter/cleaner id.

**The 6-letter cap is an error, not a style note** — the validator rejects a
longer class-level id (§10.2). The cap is what keeps a section id readable at a
glance in a docspecs comment, and since §7.2 derives every list container's
prefix from the element class's id, an over-long class id is not paid for once:
it propagates into every container id that points at the class and into all nine
generated SOM languages.

**The recommended mnemonic algorithm.** Left to judgement, three different
algorithms grow side by side — initials (`BackupPolicyEntry` → `BPE`), two
letters per word (`BAPOEN`), and three letters per word, which would spell
`BrowserRequirementEntry` as the nine-letter `BRO`+`REQ`+`ENT`. The third
overflows the cap on any name of three words, the second on four. Derive the
mnemonic like this instead:

1. Split the class name into its CamelCase words.
2. **Drop filler words** — `Of`, `And`, `For`, `To`, `The`, `A`, `In`, `On`.
   They carry no mnemonic weight and would spend a third of the budget.
3. **Drop a trailing generic suffix word** — `Entry`, `Summary`, `List`, `Spec`,
   `Specification` — when at least two significant words remain. It says what
   the class *is* in the model, not what it is *about*, and the container id
   (`…-LST`, §7.2) already says that.
4. Spend the six letters on the remaining words, front-loaded:
   **1 word → its first 6 letters; 2 words → 3 + 3; 3 or more → 2 + 2 + 2 over
   the first three**, later words not represented.
5. Uppercase.

So `AlertDefinitionEntry` → `ALEDEF`, `ExternalSystemContextEntry` → `EXSYCO`,
`OutOfScopeEntry` → `OUTSCO`, `UiComponentEntry` → `UICOM` (a short word spends
less than its share).

The algorithm is a **default, not a law**: it is what a new class should take
unless there is a reason to differ, and the validator enforces only the cap and
the uniqueness (it cannot know which mnemonic reads best). Where the derived id
is already taken, the existing collision rule above decides — the class closer
to the root keeps it and the other takes a hand-picked ≤6-letter variant. That
is how `PhaseGateReviewEntry` is `PHGREV`: its own derivation is `PHGARE`, which
its parent `PhaseGateReviews` already holds.

### 7.2 List container `@SectionId` — the field-suffixed rule

A `List<T>` field is a distinct document section (§4 rule 2) and needs its
**own** container id, formed as:

```
<elementId>-<FIELDSUFFIX>-LST     (container @SectionId)
<elementId>-<FIELDSUFFIX>-xxx     (numbering @SectionIdPattern)
```

- `<elementId>` is **not authored — it is derived**. It *is* the class-level
  `@SectionId` of the element type `T`, so the prefix is a key that resolves
  back to a class rather than a mnemonic that merely resembles one. Where `T`
  is the untyped `DocSpecsSection` there is no element class, and the prefix is
  the **owning class's** `@SectionId` — matching §7.3, since such a list holds
  free-text sub-sections of its parent and nothing else. The two cases together
  make the rule total: every list container id has exactly one correct prefix,
  and the validator computes it (§7.4). Renaming an element class's id
  therefore means updating every container id that points at it; the validator
  names each one.
- `<FIELDSUFFIX>` is a **hand-authored 4-character mnemonic for the field**,
  written in uppercase alphanumerics. The default is the first four letters of
  the field name (`systems` → `SYST`, `inScopeProcesses` → `INSC`), and most
  fields take it; where those four letters read badly or clash, a better
  4-character mnemonic is chosen instead (`assumptions` → `ASMP`,
  `revisionHistory` → `REVS`). The length is fixed at 4; the letters are a
  judgement call, following the same philosophy as the class-level `@SectionId`
  mnemonics.

```dart
@SectionId('EXTSY-SYST-LST')
@SectionIdPattern('EXTSY-SYST-xxx')
List<ExistingSystemEntry> systems = [];
```

**The scope is universal:** *every* list field carries a field suffix, not only
those with a same-type sibling. This gives one uniform three-token container-id
form across the model instead of two; there are no two-token `<elementId>-LST`
ids.

The field suffix is what makes the id unique, and it works because Dart forbids
duplicate field names within a class — so two same-type lists in one class (e.g.
`ProcessScopeSummary.inScopeProcesses` and `outOfScopeProcesses`) get **distinct**
container ids (`PRSCEN-INSC-LST` vs `PRSCEN-OUTO-LST`) instead of colliding.
Since the prefix is derived, the suffix carries the whole burden: where two
sibling lists share a prefix *and* their first four letters (`MigrationRisks`'s
`riskCategories` / `riskBasedDecisions`), one of them takes a hand-picked
mnemonic (`MIRI-RISK-LST` / `MIRI-RBDE-LST`). The per-class uniqueness check
(§7.4) is what forces that choice.

**The prefix is machine-verified; the suffix is not.** The validator recomputes
`<elementId>` from the element class — or from the owning class for a
`List<DocSpecsSection>` — and rejects any container id that does not match, so
the prefix cannot drift from the class it names. The 4-character suffix stays an
authoring judgement: the validator checks that it is unique among siblings
(§7.4), not that it reads well.

**`@Reference` list fields are outside this rule, not an omission.** A reference
list points at sections owned elsewhere, so it carries no container/pattern pair
at all (§7.4 list-coverage). Its field-level id is a §7.3 inline sub-section id
with a trailing `-REF` — `WorkflowActorEntry.participatingSteps` is
`WAE-PART-REF`: the *owning* class's `@SectionId` plus the field suffix, with no
`-LST`/`-xxx` twin and no element prefix.

### 7.3 Inline sub-section ids

A field-level `@SectionId` on a shape-(3) `DocSpecsSection` member is an inline
sub-section id, named `<PARENT_CLASS_SECTIONID>-<FIELD4>` — the parent class's
own id plus the same 4-character field suffix. A `@Reference` field takes a
trailing `-REF` (e.g. `KEATT-REFE-REF`).

### 7.4 Uniqueness namespaces (enforced by the validator)

The scheme rests on **sibling-scoped**, not globally-flat, addressing: a section
is addressed by **parent path + local container id**. That is the deliberate
choice (the rejected alternative was flat per-document uniqueness, which would
have needed an extra parent discriminator folded into every container id).

- **Class-level ids:** globally unique. Class-level and container ids live in
  **different namespaces** — a container id is never compared against class-level
  ids.
- **Container ids:** unique **within a class** (per-class uniqueness). The field
  suffix guarantees this by construction; the validator enforces it as a guard,
  so a later-added second list cannot silently collide. Error tag:
  `§10.2 @SectionId per-class uniqueness`.
- **Container prefix:** the `<elementId>` token of a container id **is** the
  element type's class-level `@SectionId` — or, for a `List<DocSpecsSection>`,
  the owning class's (§7.2). Recomputed, not merely shape-checked. Error tag:
  `§10.2 @SectionId container prefix`.
- **Type-consistency:** a given container id maps to **exactly one** element type.
  Error tag: `§10.2 @SectionId consistency`.
- **Pattern pairing:** the `@SectionIdPattern` must mirror the container
  `@SectionId` (`-LST` ↔ `-xxx`). Error tag:
  `§10.2 @SectionId/@SectionIdPattern pairing`.
- **List coverage:** every `List<T>` field of section elements — a complex `T`
  or the untyped `DocSpecsSection` — must carry the container/pattern pair. The
  only exemption is `@Reference` list fields, which are pointers rather than
  owned sub-sections. Error tag: `§10.2 @SectionIdPattern list-coverage`.

**Cross-class sharing is legitimate.** Two *different* classes that each declare a
list of the same element type *with the same field name* share one container id
(e.g. `CurrentWorkflowEntry.outputs` and `WorkflowStepEntry.outputs` → both
`WOOUEN-OUTP-LST`). They sit under different parents, so under sibling-scoped
addressing they never collide. Container ids are unique among **siblings**, not
globally. Sharing *within* one class is the case that is forbidden, and the
per-class uniqueness check is exactly what forbids it.

**Same-type sibling lists are resolved by the field suffix, not by the model
shape.** Two or more lists of the same element type in one class are a
legitimate, supported construct: the differing field suffixes give them distinct
container ids, and nothing further is required — no wrapper class, no
discriminator field, no renamed element type. Where a class holds same-type
sibling lists *and* the element type also carries a field naming which list it
belongs to, that field is redundant with its container id and is dropped in
favour of the list membership.

That redundancy holds only because sibling lists **partition** their elements
(§5.9) — membership determines the property exactly when each element sits in
one list and no other. §5.9 guarantees the partition, so one further condition
decides the field:

- **The field must add no state that is not otherwise expressible** — neither by
  the lists themselves nor by another field of the same element. A scope field
  offering "Deferred" alongside In-/Out-of-Scope adds nothing where the element
  already carries a target-phase field.

A field that survives that test is kept, and its hint is rewritten to describe
the state **intrinsically** rather than by restating which list the element is
in. The same applies where an element type is used by both a grouped and an
ungrouped list: the field carries the grouping only for the ungrouped entries,
and the hint says so.

### 7.5 Lists — the `*-LST` container is a real section

A `List<Foo> field` with `@SectionId('FOO-FLD-LST')` +
`@SectionIdPattern('FOO-FLD-xxx')` maps to **two** nesting levels:

```
<owning section>
└── FOO-FLD-LST         ← the list CONTAINER section (one per list field)
    ├── FOO-FLD-1       ← item 0, a full Foo sub-tree (1-based)
    ├── FOO-FLD-2       ← item 1
    └── …
```

- The container groups the whole list; a list is a distinct document section
  that must have its own id.
- Each item is a sub-section of the container, numbered from the
  `@SectionIdPattern` with a **plain 1-based counter** (`FOO-FLD-xxx` →
  `FOO-FLD-1`, `FOO-FLD-2`, …) — **not** zero-padded.
- Per §4 rule 2 the container's own content has no model-defined meaning. The
  generated schema pins it as always-empty (min/max-text-length 0), and the
  yaml container mapping holds only the item keys.
- The md heading tree, the yaml tree, and the object model are structurally
  isomorphic: the container is its own nesting level in all three.

### 7.6 Stored per-item section ids

List items can carry **stored** section ids: AA1 date-lettered generated ids
(`GOAL-ITEM-GL1`) or explicit overrides (`SpecDocument.setItemSectionId`,
`SomNode.$sectionId`, `SomList.add(sectionId:)`), validated for list-scoped
uniqueness. Items without a stored id are **anonymous** — identified by their
1-based positional pattern id.

Stored ids are persisted by **both** wire formats. The md exporter renders a
stored id in the item's `<!--[id]-->` comment (the positional pattern id is used
only as a fallback for anonymous items); the md parser accepts and keeps stored
ids. Parse-side positional matching of anonymous items is kept: `<member>-<n>`
and the `@SectionIdPattern` with `xxx` as a *number* both resolve to anonymous
item `<n>` (never stored); any other id under the container opens the next item
*with* that stored id.

Schema interaction: the generated `pattern-check-id` compiles the
`@SectionIdPattern` `xxx` to `.+` — a **stem check** (`^FOO-FLD-.+$`). Numbering
and list-scoped uniqueness are runtime-owned, not schema-owned, so surfaced AA1
date-lettered ids and explicit overrides validate against their own schema.

### 7.7 Instance numbering in live documents

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
| 1 | **Max+1 within the day.** A new item takes `max(existing same-day number) + 1`. Ids **never renumber** on delete; deleting the current max frees that number for reuse. |
| 2 | **Section id and sequence path are decoupled.** The stored section id identifies the item; its position in the list is a separate, positional address. Reordering a list changes positions, never ids. |
| 3 | **An explicit id override keeps the pattern prefix.** Callers may supply the numbering suffix, but not a different prefix — the prefix is fixed by the `@SectionIdPattern`. |
| 4 | **The pattern prefix is the pattern minus its trailing `x` run** (`EXTSY-SYST-xxx` → `EXTSY-SYST-`). |
| 5 | **Duplicate ids are rejected**, not silently accepted — the add-with-id path raises a section-id-collision error. |
| 6 | **Serialization order is opt-in.** Emission order follows `@SerializationOrder`; nothing is reordered implicitly. |
| 7 | **Structural accessors never collide with a model member name.** The section id, headline and code-spec accessors are `$`-namespaced (or the nearest per-language equivalent); the plain-named ones (`doc`, `path`, `isEmpty`, `canHaveContent`) are protected by renaming the *generated* accessor instead. See `som_multiplatform_spec_model.md` §10.1. |
| 8 | **Conformance is corpus-pinned** — the numbering behaviour has its own golden corpus files, separate from the document-format corpus. |

**Add API — three variants per language:** a plain add (today's date, next
number), an add-on-date variant taking month + day, and an add-with-explicit-id
variant. Dart: `add` / `addOn` / `addWithId`; Go: `Add` / `AddOn` / `AddWithID`;
Rust: `add` / `add_on` / `add_with_id`; C: `som_list_add` / `som_list_add_on` /
`som_list_add_with_id`; C++: `add()` / `addOn()` / `addWithId()`.

---

## 8. Headlines

Headline storage and rendering are governed by five rules:

1. **Every section stores a headline** (fixed sections and list items),
   persisted in md and yaml. For list entries the headline is per-instance
   free text — those are the sections whose meaning cannot be predetermined.
2. **`@Headline(String text)`** predefines the headline for fixed-meaning
   sections in the model. The predefined headline prefills the editor on section
   creation and is the render fallback; the **stored headline always wins** and
   remains editable.
3. **Render precedence:** `stored headline > @Headline default > name
   derivation`. The derivation fallback is Title-Case of the member name for
   fields and containers (`introductionAndScope` → `Introduction And Scope`),
   and `<ElementTitle> <seq>` for list items, where the element title is the
   Title-Case element class name with a trailing `Entry` dropped.
   A field-level `@Headline` on a scalar list titles the **container** only —
   item stems stay name-derived unless the *element class* carries a class-level
   `@Headline`. The schema `title-format` document name resolves
   `root @Headline > @Document name > split-Pascal fallback`.
4. **No title/id form fields.** The stored section headline and the `@SectionId`
   (or, for list entries, the owning list's `@SectionIdPattern` item id) are the
   **sole authoritative** title and id of a section. Neither is ever duplicated
   inside a `@Form` field, a scalar, or `content`: there is exactly one storage
   slot per value (the heading text; the id comment) and exactly one way to read
   it, so no role marker is needed. A list entry's short human code belongs in
   its heading (e.g. `FR-01 — Capture orders`), not in a form field. Such an id
   is still **referenceable**: `refersTo: ['FRE.@sectionId']` resolves against
   the stored item id directly (§6.2 rule 6), so the single-slot rule costs no
   enforceability. See §8.1 for what the rule does *not* cover — a name-shaped
   field is only a violation when the name it holds is the entry's own — and
   §8.2 for why only the name half of the rule is checked mechanically.
5. **Editor strict mode** — headlines and ids are editable only for list-entry
   sections; fixed sections show their stored/default headline read-only.

The md parser compares parsed heading text against the *effective default*
(stored > `@Headline` > derivation) and stages a stored headline only on
difference, so untouched documents stay byte-stable.

### 8.1 Which name fields rule 4 forbids

Rule 4 bites on **a name-shaped form field holding the name of the list entry
it sits in**. Most name-shaped fields hold something else and are perfectly
legal, and the two look identical in source — so the boundary is drawn
structurally, and the static tier draws it (§10.2 invariant 11).

**Where the rule applies.** Only beneath a **list-entry class**: the element
type of a complex list carrying `@SectionIdPattern`. Such a section's headline
is per-instance free text (rule 1) — it *is* the entry's name, so a form field
holding that same name is a second storage slot for one value. A field on a
**fixed** section is never a violation: its heading is predetermined by
`@Headline` or derivation, so it stores no name and the form field is the only
slot the name has. `SystemSummary.systemName` and `DomainOverview.domainName`
are legal for exactly this reason.

The scope is **transitive**. An entry's identification block is as often an
extracted class (`BusinessProcessEntry.identification` → `ProcessIdentification`)
as an inline `@Form` member (`ActorEntry.identification`), and the two must be
judged alike — otherwise extracting a class defeats the rule. A field is
therefore weighed against the nearest enclosing list-entry class, not against
the class that happens to declare it.

**What counts as name-shaped.** A form field named exactly `name`, `title` or
`label`, or whose name ends in `Name`, `Title` or `Label`.

**When it names the entry itself.** A bare `name`/`title`/`label` can mean
nothing else, so the shape alone decides. Otherwise the field's *stem* — its
name with the trailing `Name`/`Title`/`Label` removed — is compared against the
entry's *subject*, its class name with a trailing `Entry`, `Record`, `Spec`,
`Section`, `Item`, `Ref` or `Details` dropped. `ComponentEntry.componentName`
restates its heading; `ComponentEntry.vendorName` does not.

**Two exemptions**, both read off the field rather than declared, so neither can
drift out of step with what it describes:

- **(b) The field is a registry key** — some `refersTo` elsewhere in the model
  resolves to it (`AZRO.roleName`, `DAENT.entityName`). Its value is then a
  stable identifier other sections are matched against, not merely the entry's
  display title, and the exact-match contract it carries is not one a free-text
  heading can meet.
- **(c) The field is itself a reference** — it declares a `refersTo` of its own,
  so it names the section it points at rather than the one it sits in
  (`RoleReferenceEntry.roleName`). Where such a value reads like the entry's
  heading, the reference field is the authoritative slot and the heading renders
  it, so there is still exactly one authority.

Everything else name-shaped beneath a list entry is a duplicate, and the
headline carries it.

### 8.2 Why the id half of rule 4 is author-enforced

Rule 4 gives a section's id the same single-slot treatment as its headline, but
only the **name** half is checked statically (§10.2 invariant 11). The id half
is left to the author. That is a decision taken on the model's own evidence, not
an omission: the three discriminators that decide the name half do not transfer,
and one of them is actively **inverted** here.

**A list entry has one name, but may legitimately have two ids.** Its headline
is per-instance free text (rule 1), so a name-shaped field whose stem is the
entry's subject can only be that headline written twice. An id-shaped field has
a second honest reading — the identifier the **specified system** will carry.
`DomainEnumValueEntry.valueId` holds the enum constant (the `@Case` token);
`ScreenElementEntry.elementId` holds `btn-submit`; `NavigationItemEntry.itemId`
holds `nav-customers`; `TabItemEntry.tabId` is unique *within its tab bar*. None
of those is this document's numbering of the entry; each is specification
content the generated code carries.

**The two id namespaces are disjoint by construction**, so the section id cannot
absorb the domain one. §7.7 rule 3 keeps the pattern prefix on an explicit id
override, so a stored item id always reads `<PREFIX>-<suffix>` — `btn-submit`
and `ACTIVE` can never be one. The name half always has a fix available (move
the value into the heading); the id half has one for only *one* of its two
readings.

**Shape cannot tell them apart.** `AssumptionRegisterEntry.assumptionId`
(labelled `ASM-NNN`) and `ScreenElementEntry.elementId` (`btn-submit`) are the
same field shape beneath the same kind of class, with the same stem-to-subject
relation. What separates them is the prose of the label and hint — the author's
intent — not a structural property the validator can read. Binding the check to
that prose would be a heuristic dressed as an invariant.

**And exemption (b) is inverted for ids.** For names a registry key *must* be a
real field: there is no reserved slot for a headline, so a `refersTo` matching on
a name has nowhere else to point. For ids §6.2 rule 6 provides `@sectionId`, so
a registry key never *needs* a field — a reference that wants the entry's
document id points at `<SID>.@sectionId` and the field is redundant. "Something
refers to it" is therefore no evidence that an id field is legitimate: the four
requirement families are referenced from eight sites through
`<FAM>.@sectionId` and carry no id form field at all.

**What the author checks instead.** Would the value still mean something if this
document were thrown away and only the built system remained? If yes, it is the
system's identifier and the field is its only slot — keep it. If it is a serial
number for this document's own register (`ASM-001`, `STK-003`, `RISK-001`), it
is the entry's section id written a second time: it belongs in the heading,
where §6.2 rule 6 keeps it referenceable.

---

## 9. Annotations

The annotation vocabulary lives in `tom_specs_core`. The **per-annotation
reference** is [`tom_specs_core/README.md`](../../tom_specs_core/README.md). This
section catalogues the vocabulary so an author knows what exists and when to
reach for each, and states the mapping semantics of each.

### 9.1 The vocabulary by group

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
`DocSpecsSection` (§5.2); the backward code→doc link is `@DocSpec`/`DocRef`,
which lives in `tom_code_specs`, not here.

**Follow-up taxonomy:** `@FollowUpKind(List<FollowUpProcess>)` — tags a SOM
follow-up subtree root with its process taxonomy.

**Validation & authoring guidance:** `@Prefix`, `@PatternCheckId`,
`@PatternCheck`, `@TextRequired`, `@MaxDepth`, `@AllowedTags`,
`@ValidationPrompt`, `@MinLength`, `@MaxLength`, `@ContentHelp`, `@Comment`.

Two authoring notes with model-wide consequences:

- **`@Headline` supplies a *default* only** — see §8.
- **`@SerializationOrder` is stamped in bulk**, not hand-maintained, by
  `tom_specs_clitool/bin/stamp_serialization_order.dart`.

### 9.2 Mapping semantics

| Annotation | Applies to | Meaning in the mapping |
|---|---|---|
| `@Document(name, description, basedOn:)` | root class | Top-level document section; supplies the schema id (kebab-case `name`) and `major.minor` version. |
| `@SectionId(id)` | class, `List<T>` field, or `DocSpecsSection` field | §7: class id / `-LST` container id / inline sub-section id. |
| `@SectionIdPattern(pattern)` | `List<T>` field | Per-item numbering template, mirrors the container id with `-LST` → `-xxx`; validator enforces the pairing. |
| `@Headline(text)` | class or field | Predefined default headline (§8). |
| `@Form([Field…])` | class or `content` field | Form section: scalar fields serialize as `FieldName: value` lines. `Field(name, type, hint:, required:)`. No field carries the section title or id (§8 rule 4). |
| `@ContentType(type, description)` | `content` field | Content medium (`markdown`, `sql`, `dart`, …). Non-`form` types forbid sibling scalar fields. |
| `@ContentHelp(text)` | class or member | Authoring guidance → schema `description`. |
| `@Comment(text)` | class or field | Inline human note (outliner display; `Seeds → XX` provenance). |
| `@Min(n)` / `@Max(n)` | `List<T>` field | Item-count bounds → schema `min-count`/`max-count`. |
| `@Unused()` | `content` field | Structural container only; omitted from the schema, still walked for layout. |
| `@SerializationOrder(n)` | every member | Sibling emission order in every observable surface. Stamped in bulk by `tom_specs_clitool/bin/stamp_serialization_order.dart`. |
| `@Reference(description)` | field | Points at data owned elsewhere; renders as an ordinary content-kind inline sub-section keyed by its field-level `…-REF` id whose *value* is the referenced section id. Never followed in traversal; excluded from ownership/cycle/list coverage. |
| `@MapsTo(Type)` | class | Seed node of a Phase 3 DocSpec in the master model — the whole subtree flows to that document. |
| `@DetailedIn(Type)` | class | Promoted to a top-level entry of a Phase 3 DocSpec; must have a `@MapsTo` ancestor (§10.2). |
| `@StandardReferences(standards, connotation)` | class or field | Public-standard provenance + meaning; carried in the meta-data. |
| `@SeedFor(Type)` | class or field | Compile-time link for a single-target `Seeds → XX`. |
| `@Prefix`, `@PatternCheckId`, `@PatternCheck`, `@TextRequired`, `@MinLength`, `@MaxLength`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`, `@Position`, `@ForEach`, `@AccessKey` | various | Validation/schema constraints; captured into the meta tree's generic `extra` list and mapped by the schema generator where relevant. |

### 9.3 Visible vs schema-only

Annotations are split into **visible** (they affect outline rendering) and
**schema-only** (used for schema generation and validation but not shown in the
outline unless `--show-schema-annotations` is passed). The full split is the
table in §11.2.13.

### 9.4 What the model constrains, and what it does not

The model's contract with an author is **structural**: which sections exist,
what nests under what, how many of each (`@Min`/`@Max`), which ids they carry
(`@SectionId`/`@SectionIdPattern`), and — for form sections — which fields are
present and required (`@Form`/`Field`). Prose bodies are **guided, not
constrained**: `@ContentHelp` and `@ValidationPrompt` tell an author what to
write, and `@ContentType` says in what medium, but nothing rejects a body for
its wording.

That is a deliberate boundary, and it is why the model carries **no text-body
regex annotation**. The DocSpecs vocabulary offers one — a section type may
declare `pattern-check-text`, and every SOM runtime's validator enforces it
against the section's text — but TomSpecs never emits it, because there is no
model-side annotation to emit it from. A section's prose is where a human says
something the structure cannot say for them; a regex over that prose checks
spelling, not meaning, and buys a false sense of validation at the cost of
rejecting correct documents.

The wider point: the whole **validation & authoring guidance** group is
currently *available* rather than *exercised* — `tom_specs_model` has no call
site for any of `@Prefix`, `@PatternCheckId`, `@PatternCheck`, `@TextRequired`,
`@MinLength`, `@MaxLength`, `@MaxDepth`, `@AllowedTags` or `@ValidationPrompt`.
The generator maps the ones it can so that a model which *does* reach for them
gets a schema that enforces them, but the documents themselves lean entirely on
structure. An annotation added to close the `pattern-check-text` gap would
therefore have no call site at all, and an annotation with no call site is
speculative (see `clean_code_principles.md`). Should a document ever have a real
text-body pattern to enforce, the annotation is a small addition — declare it in
`tom_specs_core` beside `@PatternCheck`, and map it in the schema generator from
the meta tree's `extra` capture, exactly as `@PatternCheck` is mapped today.

---

## 10. Traceability and structural invariants

### 10.1 Traceability annotations

The 12 Phase 3 documents derive from the SBP, and that derivation is encoded:

- **`@Document(name, description, basedOn: [...])`** marks a class as a document
  root and names its upstream documents.
- **`@MapsTo`** records that a target-document section maps back to an SBP
  section (the shallowest SBP class whose whole subtree flows to one document).
- **`@DetailedIn`** records that an SBP section is elaborated in a downstream
  document; it must sit under an ancestor carrying `@MapsTo`.
- **`@SecondLevelSectionId`** (reserved) derives second-level ids; it implies
  `@DetailedIn`.

### 10.2 The mechanical structural invariants

Two meta-rules govern this section:

- **A structural rule lives in the validator, not only in a test.** Anything the
  model must satisfy structurally is implemented in
  `validateStructuralInvariants()`, so every consumer of the model — the
  outliner, the JSON exporter, the SOM generator — inherits the check rather
  than each re-deriving it. A test that asserts a structural property without a
  validator check behind it is a gap, not a rule.
- **The validator is the contract; this document follows it.** Where prose here
  and the validator disagree, the validator is right and the prose is corrected.
  Rules stated in this document are statements about what the code enforces
  today, not aspirations for what it should enforce.

The validator enforces the following structural invariants (implementation:
`tom_specs_clitool/lib/src/validator.dart`, exported as
`validateStructuralInvariants()`):

1. `@SectionId` **global uniqueness** (class-level namespace) and **length** —
   a class-level id is capped at 6 letters (§7.1). Container ids are exempt:
   they are three-token compounds and carry a `-`.
2. `@SectionIdPattern` uniqueness, container-id **type-consistency**,
   **per-class uniqueness**, and container/pattern **pairing** (per §7.4).
3. **`@SectionIdPattern` list-coverage** — every list field of section elements
   carries the container/pattern pair; `@Reference` lists are the only
   exemption.
4. **`@SectionId` coverage** — every reachable class carries one, *except*
   classes reached only through a `@SectionIdPattern` subtree (transitive
   exemption). This one is reported as a **warning**, not an error: it is a
   completeness signal, so a model with a gap still validates. Every other
   invariant in this list is an error.
5. **`@DetailedIn` ⇒ ancestor `@MapsTo`**.
6. **`@SecondLevelSectionId` ⇒ `@DetailedIn`**.
7. **Per-`@Document` detail-count budget** (7–15 top-level entries).
   `@CodeSpecsProjection()` roots are exempt from *this check only* (§2.5).
8. **Root-independent section-id resolution** — a class reachable from more than
   one `@Document` root must resolve to the same id from every root. Both id
   mechanisms are root-independent by construction (a class-level `@SectionId` is
   fixed; a `@SectionIdPattern` list-instance id derives from the *element*
   class's own `@SectionId`, so an element class carrying a class-level
   `@SectionId` — the `<E>` prefix source — is by design, not a conflict). The
   case actually rejected is **structural-mode mixing**, i.e. a class reached
   both as the direct element of a `@SectionIdPattern` list *and* as a standalone
   complex section field (`@Reference` edges excluded).
9. **§5.1 member-shape legality**, `@ContentType` compatibility, and **cycle
   detection**.
10. **The `refersTo` target contract** (§6.2) — target grammar, existence and
    unambiguity of the named section id, the required/enumerated form-field slot
    or the patterned-list element requirement for `@sectionId`, and
    **co-reachability**: every target must be reachable together with its
    referring class from at least one `@Document` root (§6.2.1). A non-`String`
    reference field is a warning; the rest are errors.
11. **No list entry restates its own headline** (§8 rule 4) — a name-shaped form
    field beneath a list-entry class, whose stem is that entry's own subject, is
    an error unless it is a registry key or carries a `refersTo` of its own
    (§8.1). This is the half of rule 4 that source alone cannot show: a
    self-naming field and a legitimate one are written identically. The rule's
    **id** half is deliberately not checked — see below and §8.2.
12. **`@CodeSpecKind` / `@FollowUpKind` mutual exclusion** — no class carries
    both. `@FollowUpKind` marks a subtree *root*, and `codespecs_mapping.md`
    §4.3 rules that only a section which must become a generation-projection
    root is hoisted out of a follow-up subtree; so a follow-up root is never
    itself generated, and a class claiming to be both is the one shape the
    CodeSpecs / follow-up split cannot express.
13. **Per-part generation routing** — every *active* `CodeSpecPart` named by any
    `@CodeSpecKind` has at least one **bearer** reachable from a
    `@CodeSpecsProjection()` root. This is what makes a `@CodeSpecKind` *inside*
    a follow-up subtree harmless: the annotation records which part the
    section's material belongs to, and the material reaches generation through a
    reachable bearer of that same part (CE-TX help copy under
    `ExperienceDesignFollowUp` through the shared `MessageKeyRegistry`). A part
    named only from unreachable sections would be specified and never
    generated. Parts listed in `deferredCodeSpecParts` (`tom_specs_core`) are
    exempt — they have no generated surface, so they have no bearer to reach;
    a deferred part that *acquires* a bearer is a warning that the deferral
    entry has gone stale. A model with no projection root is silent.
14. **Document reachability** — every class is reachable from at least one
    `@Document` root. The generator emits the whole class map, so an orphan is
    translated into all nine languages, registered in `spec_ops.g.dart` and
    described in nine metas, while no document can ever hold an instance of it.
    The canonical container root is exempt (it *is* the tree root, so nothing
    points at it), and a model with no `@Document` roots is silent, which keeps
    synthetic fixtures unaffected. This invariant exists because the outliner —
    the tool one would expect to surface an unused class — structurally cannot:
    it walks *from* the roots, so an orphan is exactly what it never visits.
    Exported separately as `unreachableClasses()` for callers that want the set
    rather than the message.

**Deliberately not an invariant:** *"a `@CodeSpecKind`-bearing class must itself
be reachable from the generation projection."* The model has 65 counterexamples
across six of its 18 follow-up roots, and `codespecs_mapping.md` §4.3 rules them
legitimate — enforcing it would forbid a follow-up process from recording which
part it produces material for. Invariants 12 and 13 are what that rule was
reaching for, stated so that they hold.

**Deliberately not an invariant:** *"no list entry restates its own section id"*
— the **id** half of §8 rule 4, the counterpart of invariant 11. Unlike a name,
an id-shaped field beneath a list entry has two honest readings — the document's
numbering of the entry, and the identifier the specified system will carry — and
they are written identically, distinguishable only by the prose of the label and
hint. Widening invariant 11's `Name|Title|Label` shape test to `Id` would
therefore convict specification content along with duplication. §8.2 states the
reasoning in full, including why the registry-key exemption is *inverted* for
ids rather than merely insufficient. A test pins the decision, so the shape test
cannot be widened by accident.

**What the validator does *not* check:** the two mnemonics themselves. It
recomputes a container id's `<elementId>` prefix from the element class (check
2b(iv)) and caps the class-level id's length, but it does not derive either
mnemonic's *letters* — neither the §7.1 class mnemonic nor the container id's
`<FIELDSUFFIX>`. Which letters read best is authoring judgement; §7.1 states the
recommended algorithm so the judgement starts from a default rather than from
nothing.

The outliner runs the full invariant set before writing; it exits non-zero on any
error, so a clean outline is proof of a valid model.

### 10.3 Cross-cutting requirements

Enforced by the conformance golden harness across all nine runtimes:

1. **Determinism** — same model + same document ⇒ byte-identical output in
   all nine languages.
2. **Sparseness** — nothing emitted for unpopulated subtrees, in any format.
3. **Ordering** — `@SerializationOrder` everywhere sibling order is
   observable.
4. **Naming fidelity** — exact model identifiers and annotation values; no
   case-mangling beyond documented per-language surface rules and headline
   derivation.
5. **Failure discipline** — structured errors everywhere (yaml load errors,
   md rejections, schema violations); nothing silently dropped.

---

## 11. The outliner

The **Specs Model Outliner** is a Dart generator that reads the `tom_specs_model`
source files via the Dart analyzer and produces a human-readable *outline
document* showing the full object-model tree, in a compact indented notation that
is easy to scan and validate.

### 11.1 Input and output

- **Source:** all Dart files under `lib/src/` of the `tom_specs_model` package.
- **Root type:** the root class name is the key parameter of the generator
  besides the Dart project it is in (`--root-type`). All classes in the
  dependency tree of the root class are included; for large projects these may
  live in other Dart projects. The committed set covers the 14 document roots
  (§2.5) plus the whole-model `DocSpecsProject` root.
- **Analyzer:** `package:analyzer` resolves types, enumerates fields, and
  inspects annotations.
- **Output:** a single markdown file containing the full model tree in the
  notation below, written to `generated-doc/outlines/` in the target package —
  deliberately outside `doc/`, so generated outlines never mix with hand-written
  documentation. The default file name is
  `<RootClassName-without-D<nn>>_outline.md`; see
  [`../generated-doc/outlines/index.md`](../generated-doc/outlines/index.md) for
  the committed set and the batch regeneration script.

**Options.** Besides `--package` (mandatory) and `--root-type`:

| Option | Effect |
|--------|--------|
| `--output` / `-o` | Override the output path (defaults as above) |
| `--max-line-length` | Leaf-line wrap width, default `120` |
| `--show-schema-annotations` | Emit schema-only annotations inline (§11.2.14) |
| `--stop-at-detailed-in` / `-c` | Compact mode: do not expand `@DetailedIn` subtrees (§11.3.3) |

### 11.2 Notation

The outline is **markdown**: every model member is a list item, so an outline
renders as a nested bullet list in any markdown viewer while staying readable as
plain text. This section is the specification of that notation; it describes
only what `OutlineWriter` emits today, and each rule below is pinned by a case
in `tom_specs_clitool/test/outline_writer_test.dart`.

#### 11.2.1 Lines and indentation

Every structural line is a markdown list item — `- ` — and each nesting level
adds **2 spaces** of indentation. The root class contributes no line of its own;
its members start at one level in (2 spaces), under the `# <Title> Outline`
heading.

The only non-bullet lines are the optional schema-annotation comments of
§11.2.14, and those are HTML comments, so they too disappear in a rendered
view.

#### 11.2.2 Singular complex members

A member whose type is a single complex object (zero-or-one / exactly-one
relationship). The type name is rendered in backticks, so it stands out from the
member name:

```
- header: `DocumentHeader`
```

**Name-match rule:** if the member name equals the type name with its first
character lowercased, only the **type name** is shown — the member name would be
redundant:

```
- `DocumentControl`
```

Here the member name is `documentControl`, which matches `DocumentControl`, so it
is dropped. `header` does not match `DocumentHeader`, so both are shown. The
comparison is exact after lowercasing the first character only — `header` vs
`DocumentHeader` differ, and no fuzzy or case-insensitive matching applies.

If the member is a `@Reference`, both names are always shown (see §11.2.9).

The **absence** of a `[]` suffix is what makes a member singular: a list always
carries one (§11.2.3), so a line without it is exactly-one or zero-or-one.

#### 11.2.3 List members and count constraints

A member whose type is a `List` (zero-or-many relationship), whether of a complex
type or a leaf one. Both the **member name** and the **type name** are always
shown, because the member name (typically plural) differs from the type name
(typically singular). The member name is structurally significant — it represents
a **section level** in the target document, with each list item as a subsection.

**A `[]` suffix on the type marks every list**, without exception:

```
- revisionHistory: `RevisionEntry`[]
```

The suffix sits **outside the backticks**, so the backticked span remains exactly
the class name and a type can still be lifted out of an outline by eye or by
grep. It binds to the type rather than to the member — the member is "many
`RevisionEntry`" — and so precedes every trailing annotation (§11.2.10–§11.2.12).

The marker is unconditional because without it the notation loses the very
distinction this section calls structurally significant: a name-mismatched
singular member (§11.2.2) and an unconstrained list render with the same shape,
``- name: `Type` ``. A plural member name is a convention, not a rule a reader
can rely on. Lists of leaf types are marked too — ``- relatedPainPoints:
`String`[] `` — since those are not expanded and would otherwise be a bare
backticked type with nothing beneath it.

**Count constraints are separate.** When a list has `@Min` or `@Max`, the bounds
are shown as a `[min,max]` tag between the bullet and the member name. If there
are no constraints, no tag is emitted. Omitted values mean "no constraint" (min
defaults to 0, max defaults to ∞). The `[]` says *this is a list*; the bracket
tag says *how many*, and only where the model constrains it:

| Notation | Meaning |
|----------|---------|
| ``- name: `T`[] `` | Default: 0..∞ (no constraints) |
| ``- [1,] name: `T`[] `` | At least 1, no upper limit |
| ``- [,5] name: `T`[] `` | At most 5, min 0 |
| ``- [1,5] name: `T`[] `` | Between 1 and 5 items |

<!-- outline-excerpt: SolutionBlueprint_outline.md -->
```
        - stakeholders: `StakeholdersAndBeneficiaries`
          - content @description
          - [1,] primaryStakeholders: `StakeholderEntry`[]
            - content @Form(stakeholderType, expectedBenefits)
```

`stakeholders` is one section; `primaryStakeholders` is a section whose items are
subsections, at least one of them. The suffix alone separates the two — the
bounds tag adds only the count.

#### 11.2.4 Leaf members

All scalar members (`String?`, `String`, enum types) of a class share a
**single bullet**, comma-separated:

```
  - content, systemName, technology, purpose
```

**Line wrapping:** if the leaf line exceeds the configured max line length
(default **120 characters**, including indentation), it wraps to continuation
lines indented **one level deeper** than the bullet. The comma stays at the end
of the broken line, and the continuation carries no bullet:

```
      - content @Form(systemName, systemAcronym, systemVersion, projectCodeName), classification, scale, status,
        complexity
```

A class with exactly one leaf member never wraps, however long the line.

Shape-(3) `DocSpecsSection` members render here too: they report `String` at the
meta boundary (§5.2), so the outline is unaffected by the object typing.

#### 11.2.5 Enum members

An enum member is shown in place among the other leaf members, with its values
inline:

```
  - content, priority: Priority (must, should, could), status
```

Enum values are shown at **every occurrence** — this keeps the outline
self-contained.

#### 11.2.6 Content field

The `content: String?` field is present on every section class; it represents the
section content of a document section, the text between the section headline and
the next headline. It is shown as a regular leaf field (first in the comma list
by convention) — **not** hidden or implicit. Other scalar fields are inside this
section text in the actual document. If a class has additional scalar fields, the
`@ContentType` must be `Form`, which indicates this is the container for the data
fields. If `@ContentType` is not `Form` (`SQL`, `DDL`, `Dart`, …) the class
cannot have other scalar fields (§5.6).

**The content field carries its form or content type inline.** A `content` field
is suffixed with the shape it declares, so a reader sees the section's data
fields without opening the class:

```
- content @Form(documentId, project, version, date, author, status)
- content @Dart
```

`@Form(…)` lists the `Field` names in declaration order. When there is no
`@Form`, a non-default `@ContentType` is shown as `@<type>` (`@Dart`, `@SQL`,
`@DDL`, …); a plain prose section shows neither. The two are mutually exclusive
— a `@Form` section's content type is `Form` by definition, so naming it again
would be redundant.

#### 11.2.7 Nullability is not shown

The outline does **not** distinguish `String?` from `String`, or `Type?` from
`Type`. A leaf member renders as its bare name, and a complex member's type name
has any `?` stripped before it is printed. Nullability is a model fact, read
from the source or from the generated meta — the outline is a structural map,
not a type signature.

#### 11.2.8 Member ordering

Members are listed in **declaration order** as they appear in the source class.
Within a class the leaf bullet comes first, then the complex and list members in
their declared order.

#### 11.2.9 References

A member annotated with `@Reference` shows both names — the name-match rule of
§11.2.2 does not apply — followed by the reference description in parentheses:

```
  - basedOn: `Requirement` (ref: Source System)
```

The referenced type is **not expanded**: the annotation says the link should be
shown but not followed, so the target's subtree does not appear (§11.3.2).

#### 11.2.10 Inline comments

Members or classes annotated with `@Comment("text")` display the comment as a
trailing marker:

<!-- outline-excerpt: SolutionBlueprint_outline.md -->
```
    - requirements: `RequirementsOverview` ← (Seeds → RSP)
```

The `← (...)` marker follows the line content after a single space. There is
**no column alignment**: the writer appends trailing markers directly, so a
marker's position depends on the length of the line it follows.

`requirements` is a singular member, so it carries no `[]` (§11.2.3); on a list
the comment follows the marker.

#### 11.2.11 Position markers

The default position is **relative** — subsections appear in the order they are
declared in the class. When a member has a non-default `@Position` annotation, it
is shown as a trailing marker in square brackets:

```
  - preamble: `Item`[] [first]
  - items: `Item`[]
  - appendices: `Item`[] [last]
```

The `[relative]` marker is never shown, as it is the default. Like comments,
position markers follow the content directly with no padding.

`@Position` applies to singular members as well as lists; the members above are
lists, hence the `[]`. Note that the two bracket forms are distinct and sit on
opposite sides of the member name: `[min,max]` (§11.2.3) precedes it, `[first]` /
`[last]` trails the type.

#### 11.2.12 ForEach constraints

A list member annotated with `@ForEach` has a bidirectional relationship with a
registry section type. This is shown with a `⟷` marker:

```
  - implementations: `Item`[] ⟷ PRIDN.processId
```

This means: for every entry identified by `PRIDN.processId`, there must be a
corresponding item in the `implementations` list, and vice versa. The key is a
form field, so it obeys §6.2 rules 4 and 5 — the field must exist, be
`required`, and be enumerated.

#### 11.2.13 Outline visibility

Not all annotations appear in the outline. Annotations are categorized as
**visible** (affect the outline rendering) or **schema-only** (used for schema
generation and validation but not shown in the outline):

| Annotation | Visible | Outline rendering |
|------------|---------|-------------------|
| `@Min`, `@Max` | Yes | `[min,max]` tag before the member name (§11.2.3) |
| `@Position` | Yes | `[first]` / `[last]` marker, non-default only (§11.2.11) |
| `@ForEach` | Yes | `⟷ Type.key` marker (§11.2.12) |
| `@TextRequired` | Yes | `!` suffix on the `content` member (`content!`) |
| `@ContentType` | Yes | `@type` suffix on content (§11.2.6) |
| `@Form` | Yes | `@Form(names…)` suffix on content (§11.2.6) |
| `@Comment` | Yes | `← (text)` marker (§11.2.10) |
| `@Reference` | Yes | `(ref: description)` suffix, target not expanded (§11.2.9) |
| `@DetailedIn` | Compact only | `→ DocId` suffix under `-c` (§11.3.3); nothing otherwise |
| `@Unused` | No | Not rendered |
| `@SectionId` | No | Not rendered |
| `@SectionIdPattern` | No | Not rendered |
| `@Prefix` | No | Schema constraint only |
| `@PatternCheckId` | No | Schema constraint only |
| `@PatternCheck` | No | Schema constraint only |
| `@MaxDepth` | No | Schema constraint only |
| `@AllowedTags` | No | Schema constraint only |
| `@ValidationPrompt` | No | Schema constraint only |
| `@AccessKey` | No | Schema constraint only |
| `@MinLength`, `@MaxLength` | No | Schema constraint only |
| `@SeedFor` | No | Schema constraint only (compile-time document link) |
| `@ContentHelp` | No | Schema constraint only (content authoring guidance) |
| `@Document` | No | Schema constraint only (document root metadata) |
| `@Headline` | No | Meta-data only (default headline) |
| `@SerializationOrder` | No | Meta-data only (member emission order) |
| `@MapsTo` | No | Meta-data only (Solution Blueprint → Phase 3 traceability) |
| `@StandardReferences` | No | Meta-data only (standard provenance + connotation) |
| `@CodeSpecKind`, `@FollowUpKind`, `@CodeSpecsProjection` | No | Meta-data only (CodeSpecs / follow-up mapping) |

#### 11.2.14 Inline schema annotations (`--show-schema-annotations`)

When the `--show-schema-annotations` flag is set, schema-only annotations are
shown **inline** in the tree as **HTML comments** — `<!-- @Annotation(args) -->`.
The HTML-comment form is what keeps the output valid markdown: the annotation
lines are invisible in a rendered view, so an outline stays a clean bullet list
while carrying the schema detail in its source.

Without the flag, schema annotations are omitted.

**Not every "No" row in §11.2.13 is shown by the flag.** The flag covers the
nine schema *constraint* annotations only:

`@Prefix`, `@PatternCheckId`, `@PatternCheck`, `@MaxDepth`, `@AllowedTags`,
`@ValidationPrompt`, `@AccessKey`, `@MinLength`, `@MaxLength`.

The meta-data annotations (`@Headline`, `@SerializationOrder`, `@MapsTo`,
`@SeedFor`, `@ContentHelp`, `@Document`, `@StandardReferences`,
`@CodeSpecKind`, …) are never emitted, with or without the flag.

**Class-level annotations** appear **after** the class line and **before** the
class's members, indented to the same level as the class line — so they sit one
level *out* from the members below them, which is what makes them read as
belonging to the class rather than to its first member:

```
  - general: `Settings`
  <!-- @Prefix('CSA-SYS') -->
  <!-- @MaxDepth(2) -->
    - content
```

**Member-level annotations** appear before the line they annotate, with the
member name after the annotation to identify the target — necessary because leaf
members share one bullet, so the annotation cannot be positioned against an
individual member:

```
  - record: `Entry`
    <!-- @MinLength(50) content -->
    <!-- @AccessKey('systemName') systemName -->
    - content, systemName
```

**Rules:**

- Only classes/members that **have** one of the nine constraint annotations get
  comment lines — no clutter when none exist.
- When a class appears multiple times (inline expansion), its schema annotations
  are shown at **every** occurrence for self-containedness.

#### 11.2.15 Notation the current model does not exercise

Several rules above have no instance in the committed outline set, because the
model does not currently use the annotation that triggers them. They are
specified and tested, but a reader will not find an example by grepping
`generated-doc/outlines/`:

| Notation | Why absent |
|----------|------------|
| Enum members (§11.2.5) | The model declares enums but no class holds an enum *member* |
| `content!` (§11.2.13) | `@TextRequired` is used nowhere in the model |
| `[,5]` / `[1,5]` (§11.2.3) | `@Max` is used nowhere; only `@Min(1)` occurs, so `[1,]` is the only tag emitted |
| `[first]` / `[last]` (§11.2.11) | `@Position` is used nowhere |
| `⟷` (§11.2.12) | `@ForEach` is used nowhere |

Each is pinned by a hand-built fixture in
`tom_specs_clitool/test/outline_writer_test.dart` rather than by a generated
sample — deliberately, so the notation stays specified after the model moves on,
and so these rules cannot rot unobserved the way they once did.

### 11.3 Type expansion

#### 11.3.1 Inline expansion

When a complex type is used, its full subtree is shown **inline at every usage
point**. There is no separate "type definitions" section — duplication is
intentional so the reader can see the full structure at each location without
jumping around.

#### 11.3.2 Cycle detection

Cycles **must not exist** in the model (§5.7). **Detecting and reporting them is
the validator's job**, not the writer's — `tom_specs_clitool/lib/src/validator.dart`
fails with a message naming the types involved, and the outliner runs it before
emitting (§11.5).

The writer itself carries only a **safety net**: it tracks the ancestors on the
current path and stops descending when it meets one again, so a cycle that
somehow reached it truncates the branch rather than looping forever. That
silence is deliberate — it is a backstop, not a diagnostic. A cycle should
never get this far, and if one does the validator is where the error belongs.

`@Reference`-marked links are not considered cycles: the annotation indicates
that the link should be shown, but not followed in traversal.

#### 11.3.3 Compact mode (`--stop-at-detailed-in`)

With `-c`, the walk **stops at every `@DetailedIn` boundary**: the section's own
line is emitted with a `→ <DocId>` suffix naming the document that details it,
and its subtree is not expanded. `<DocId>` is the `@SectionId` of the document
class named in the `@DetailedIn` annotation.

<!-- outline-excerpt: SolutionBlueprint_compact_outline.md -->
```
    - requirements: `RequirementsOverview` ← (Seeds → RSP)
      - content, requirementsForm, traceabilityMatrix
      - `FunctionalRequirements` → RSP
      - `TechnicalRequirements` → RSP
      - `SecurityRequirements` → RSP
```

This is what makes a Solution Blueprint outline readable at a glance: the SBP is
mostly a set of seeds for the Phase 3 documents, so expanding every detailed
subtree buries the blueprint's own structure. The committed
`SolutionBlueprint_compact_outline.md` is generated this way.

### 11.4 Output example

The block below is a **verbatim cut** of the head of
[`../generated-doc/outlines/SolutionBlueprint_outline.md`](../generated-doc/outlines/SolutionBlueprint_outline.md),
the outline of the `D00SolutionBlueprint` root. It is not a hand-written
illustration: the `<!-- outline-excerpt: ... -->` marker above it binds it to
that generated file, and `outline_writer_test.dart` asserts the block is a
contiguous substring of it. If the outliner's output changes, this example goes
red rather than quietly becoming a lie — which is exactly what it did before.

To refresh it, regenerate the outlines and re-cut the block; do not edit it by
hand.

<!-- outline-excerpt: SolutionBlueprint_outline.md -->
```
# Solution Blueprint Outline

  - content
  - `DocumentControl`
    - content
    - header: `DocumentHeader`
      - content @Form(documentId, project, version, date, author, status)
    - revisionHistory: `RevisionEntry`[]
      - content @Form(version, date, author, summary)
    - approvals: `ApprovalRecord`[]
      - content @Form(role, date, status)
    - `ReferenceDocuments`
      - content @description
      - documents: `ReferenceDocumentEntry`[]
        - content @Form(documentId, version), metadata, governance, lifecycle
        - relevantSections: `DocumentRelevantSections`
          - content @Form(sectionReference, sectionTitle, relevance, extractSummary)
          - sections: `RelevantSectionEntry`[]
            - content @Form(sectionReference, relevance, extractSummary, complianceRequired)
        - relationships: `DocumentRelationships`
          - content @description
          - relatedDocuments: `RelatedDocumentEntry`[]
            - content @Form(relatedDocumentId, relationshipType, relationshipDescription)
  - `IntroductionAndScope`
    - content, systemContextDiagram
    - summary: `SystemSummary`
      - content @Form(systemName, systemAcronym, systemVersion, projectCodeName), classification, scale, status,
        complexity
    - `SystemDescription`
```

**What the excerpt shows:**

- **Name-match rule** (§11.2.2): `` - `DocumentControl` `` (member name matches
  the type, so it is dropped) against ``- header: `DocumentHeader` `` (it does
  not, so both are shown).
- **List marker** (§11.2.3): ``- header: `DocumentHeader` `` and
  ``- revisionHistory: `RevisionEntry`[] `` sit on consecutive lines — one
  section against a section whose items are subsections. The `[]` is the only
  thing that separates them.
- **Leaf bullet** (§11.2.4): `- content, systemContextDiagram` — all scalars of a
  class on one line.
- **Line wrapping** (§11.2.4): the `SystemSummary` leaf line breaks after
  `status,` and continues with `complexity` one level deeper.
- **Content shape** (§11.2.6): `@Form(documentId, project, …)` naming the form
  members, and `@description` where a plain prose content type is declared.
- **Mixed content line**: `- content @Form(documentId, version), metadata,
  governance, lifecycle` — the form marker binds to `content` only; the rest are
  ordinary leaf members.
- **Inline expansion** (§11.3.1): `DocumentRelevantSections` and
  `DocumentRelationships` are expanded in place under `ReferenceDocumentEntry`.
- **2-space indentation** (§11.2.1) and backticked type names throughout.

For the count-constraint tag see the excerpt in §11.2.3, and for the compact
`→ DocId` form see §11.3.3. The notation forms no committed outline exercises are
listed in §11.2.15.

### 11.5 Generator implementation notes

1. **Entry point:** `tom_specs_clitool/bin/outliner.dart`. The whole committed
   outline set is regenerated by `tom_specs_clitool/tool/regenerate_outlines.sh`,
   which wraps it.
2. **Analyzer setup:** `SummaryBasedDartSdk` with an embedded SDK summary bundle
   (no installed SDK required). The `sdk_summary.sum` file (~3 MB) is split into
   69 base64-encoded Dart source files in `lib/src/sdk_summary/`, reassembled at
   runtime. Model source files are analyzed directly from disk. See
   `som_toolchains.md` "Dart host" for full details.
3. **Annotation reading:** read `@Reference`, `@SectionId`, `@SectionIdPattern`,
   `@Comment`, `@ContentType`, `@Form`, `@Unused`, `@Prefix`, `@PatternCheckId`,
   `@TextRequired`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`, `@Min`,
   `@Max`, `@Position`, `@ForEach`, `@AccessKey`, `@PatternCheck`, `@MinLength`,
   `@MaxLength`, `@SeedFor`, `@SerializationOrder`, `@Headline`, `@MapsTo`,
   `@DetailedIn`, `@StandardReferences` from the analyzer's element model. All
   model classes in the package are scanned — no marker annotation is required.
   The full annotation catalogue and the section base types are documented in
   [`tom_specs_core/README.md`](../../tom_specs_core/README.md).
4. **Tree walk:** start from the root type, recursively visiting each member.
   Within a class, leaf members are emitted first as one bullet, then complex and
   list members in declaration order:
   - `String` / `String?` / enum / section type → collect onto the leaf bullet.
   - `List<T>` → emit ``- [min,max] name: `T` `` (tag only when `@Min`/`@Max`
     are present) and recurse into `T`.
   - complex type → emit ``- name: `T` `` (or ``- `T` `` under the name-match
     rule) and recurse.
   - `@Reference` → emit with `(ref: …)` and **do not** recurse.
5. **Validation pass** (before output): run the full rule set of §5 and §10.2 —
   member shapes, type constraints, naming, class style, content type, section-id
   invariants, cycle detection. Fail on the first error with a clear message.
   Cycle *reporting* lives here, not in the writer (§11.3.2).
6. **Line wrapping:** track current line length. When a leaf line exceeds the max
   (default 120), wrap at a comma boundary and indent the continuation one level
   deeper than the bullet. A single-member leaf line is never wrapped.
7. **Trailing markers:** `← (comment)`, `[position]` and `⟷ registry.key` are
   appended directly after the line content, separated by one space. There is no
   column alignment.
8. **Inline schema annotations:** when `--show-schema-annotations` is set, emit
   `<!-- @Annotation(...) -->` lines inline during the tree walk — class-level
   after the class line at the class's own indent, member-level before the leaf
   bullet with the member name inside the comment (§11.2.14). Only the nine
   constraint annotations are emitted.
9. **Tests:** `tom_specs_clitool/test/outline_writer_test.dart` pins the notation
   — both the rules the model exercises (via excerpts cut from the committed
   outlines) and those it does not (via hand-built fixtures, §11.2.15).

---

## 12. The tools

The SOM is surrounded by tooling. These are *mentioned* here; each has its own
specification.

### 12.1 CLI — `tom_specs_clitool`

The analyzer-based generation host. It hosts the **outliner** (§11, renders the
class tree from any root), the **validator** (all §5 and §10.2 invariants), the
**model JSON exporter** (the lossless meta-data), and the **multi-language SOM
generator** (`bin/generate_som.dart`). It runs against an embedded SDK summary,
so no installed Dart SDK is required. Specs:
`tom_specs_clitool/README.md`, `som_multiplatform_spec_model.md` (what it emits),
`som_generator_config.md`, `tom_specs_model_meta_schema.md`, `som_toolchains.md`.

### 12.2 Reviewer — `tom_specs_reviewer` (`tom_ai/ai_build/`)

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

### 12.3 Editor — `tom_specs_editor` (`tom_forge/`)

The **spec authoring app**: a Tom Forge desktop app for authoring DocSpecs /
CodeSpecs / Implementation specifications, built on the Forge shell and the
shared agent UI. It consumes the same generated `spec_model.json` and drives the
document editor from it, with DocSpecs + markdown import/export. It uses the
generic meta-model (`tom_som_dart_runtime`), not the typed facade. Spec:
`tom_specs_editor_specification.md` (and `som_multiplatform_spec_model.md` §9 for the
runtime relationship).

---

## 13. Reference index — where each rule is authoritative

| Subject | Authoritative document |
|---------|------------------------|
| Model-authoring rules, section-ID scheme, annotations for the author, outline notation | `tom_specs_model_rules.md` (here) |
| **Mapping — object model ↔ md / yaml / schema, metadata tree, generated surfaces, parse+validate API, the multi-platform SOM component, packaging** | **`som_multiplatform_spec_model.md`** (the single mapping authority) |
| Per-annotation reference | `tom_specs_core/README.md` |
| Structural invariants (implementation) | `tom_specs_clitool/lib/src/validator.dart` (`validateStructuralInvariants()`) |
| Generator config / meta-schema / toolchains | `som_generator_config.md`, `tom_specs_model_meta_schema.md`, `som_toolchains.md` |
| DocSpecs format itself (schemas, section types, validation) | `_ai/quests/doc_specs/doc_specs_specification.md` |
| DocSpecs ↔ CodeSpecs link, `@CodeSpecKind`, the parts catalogue | `codespecs_mapping.md` |
| Creation process / phases | `tom_specs_project_flow.md` §PF-PHA, `overview.tom_specs.md` |
| Roles / quality gates | `tom_specs_project_flow.md` §PF-ROL, §PF-GAT |
| Solution Blueprint → Phase 3 document mapping | `tom_specs_project_flow.md` §PF-FLW |
| Issue workflow / upgrade cycles | `tom_specs_project_flow.md` §PF-ISS, §PF-UPG |
| Editor / reviewer | `tom_specs_editor_specification.md` |
