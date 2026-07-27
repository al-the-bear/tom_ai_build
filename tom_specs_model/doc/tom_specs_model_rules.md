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
| **[`som_mapping.md`](som_mapping.md)** | **Mapping and mechanics.** How the authored model becomes bytes: md serialization, hierarchical yaml, DocSpecs schema generation, the metadata tree, the generated SOM surfaces, the embedded parse/validate API, the conformance requirements. |

`som_mapping.md` is the **single mapping authority**. Where a rule here has
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
`som_mapping.md` §8.2 and §9.2.

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
| **`content: String?` expected** | warning | Nearly every class carries a `content: String?` override — the section text between the headline and the next headline. Missing it is a warning, not a blocker. |

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
  The validator never flags kept classes; collapse candidacy is a codemod
  concern (`collapse_leaves.dart`, `collapse_list_leaves.dart`).
- **A wrapper stays a level** when its own content has meaning by itself:
  it (or a field) carries `@Form`; a leaf carries substantive `@ContentHelp` /
  `@StandardReferences` / non-Form `@ContentType`; it is shared; or it declares
  a named leaf besides `content`. Only when *none* of these hold is the
  wrapper pure indirection — the validator emits a `§6.1c collapsible-wrapper`
  **warning** for such candidates.

A **pure single-list wrapper** (`{content?}` plus exactly one list) is doubly
redundant under the §4 list-as-outer-section rule, because the list already
provides its own section level; it is kept only when a keep-a-level exemption
above applies to it. The model is at the steady state — the validator emits no
collapsible-wrapper warnings. Census tools:
`tom_specs_clitool/tool/keep_class_census.dart`, `tool/tsma4_census.dart`,
`tool/yrd10_list_wrapper_census.dart`.

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
  never followed in traversal.

### 6.2 Form decomposition

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

### 7.2 List container `@SectionId` — the field-suffixed rule

A `List<T>` field is a distinct document section (§4 rule 2) and needs its
**own** container id, formed as:

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
those with a same-type sibling. This gives one uniform three-token container-id
form across the model instead of two; there are no two-token `<elementId>-LST`
ids.

The field-name suffix works because Dart forbids duplicate field names within a
class — so two same-type lists in one class (e.g.
`ProcessScopeSummary.inScopeProcesses` and `outOfScopeProcesses`) get **distinct**
container ids (`PRSCEN-INSC-LST` vs `PRSCEN-OUTO-LST`) instead of colliding. The
element *type* is always recoverable as the first token before the first `-`.

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
  `§8.6 @SectionId per-class uniqueness`.
- **Type-consistency:** a given container id maps to **exactly one** element type.
- **Pattern pairing:** the `@SectionIdPattern` must mirror the container
  `@SectionId` (`-LST` ↔ `-xxx`). Error tag:
  `§8.6 @SectionId/@SectionIdPattern pairing`.

**Cross-class sharing is legitimate.** Two *different* classes that each declare a
list of the same element type *with the same field name* share one container id
(e.g. `CurrentWorkflowEntry.outputs` and `WorkflowStepEntry.outputs` → both
`WOOUEN-OUTP-LST`). They sit under different parents, so under sibling-scoped
addressing they never collide. Container ids are unique among **siblings**, not
globally.

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
| 7 | **The structural accessor is `$`-namespaced** (or the nearest per-language equivalent) so it can never collide with a model member name. |
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
   its heading (e.g. `FR-01 — Capture orders`), not in a form field.
5. **Editor strict mode** — headlines and ids are editable only for list-entry
   sections; fixed sections show their stored/default headline read-only.

The md parser compares parsed heading text against the *effective default*
(stored > `@Headline` > derivation) and stages a stored headline only on
difference, so untouched documents stay byte-stable.

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

The validator enforces the following structural invariants (implementation:
`tom_specs_clitool/lib/src/validator.dart`, exported as
`validateStructuralInvariants()`):

1. `@SectionId` **global uniqueness** (class-level namespace).
2. `@SectionIdPattern` uniqueness / container-id pairing (per §7.4).
3. **`@SectionId` coverage** — every reachable class carries one, *except*
   classes reached only through a `@SectionIdPattern` subtree (transitive
   exemption).
4. **`@DetailedIn` ⇒ ancestor `@MapsTo`**.
5. **`@SecondLevelSectionId` ⇒ `@DetailedIn`**.
6. **Per-`@Document` detail-count budget** (7–15 top-level entries).
   `@CodeSpecsProjection()` roots are exempt from *this check only* (§2.5).
7. **Root-independent section-id resolution** — a class reachable from more than
   one `@Document` root must resolve to the same id from every root. Both id
   mechanisms are root-independent by construction (a class-level `@SectionId` is
   fixed; a `@SectionIdPattern` list-instance id derives from the *element*
   class's own `@SectionId`, so an element class carrying a class-level
   `@SectionId` — the `<E>` prefix source — is by design, not a conflict). The
   case actually rejected is **structural-mode mixing**, i.e. a class reached
   both as the direct element of a `@SectionIdPattern` list *and* as a standalone
   complex section field (`@Reference` edges excluded).
8. **§5.1 member-shape legality**, `@ContentType` compatibility, and **cycle
   detection**.

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

### 11.2 Notation

#### 11.2.1 Indentation

Each nesting level adds **4 spaces** of indentation.

#### 11.2.2 Singular complex fields (`->`)

A field whose type is a single complex object (zero-or-one / exactly-one
relationship).

**Name-match rule:** if the field name matches the type name (equal except for
the first character being lowercase), only the **type name** is shown — the field
name would be redundant. If they do **not** match, both are shown as
`fieldName:TypeName`:

```
-> ExistingSystemsLandscape
    -> content, currentArchitecture
    -> DependenciesAndIntegrations
        ...
-> header:DocumentHeader
    -> content, documentId, project, version, date, author, status
```

In the first line, the field name `existingSystemsLandscape` matches type
`ExistingSystemsLandscape` → only the type is shown. In the last line, the field
name `header` does not match type `DocumentHeader` → both are shown.

If the field is a `@Reference`, both field name and type name are always shown
(see §11.2.9).

#### 11.2.3 List fields (`-:`) and count constraints

A field whose type is `List<ComplexType>` (zero-or-many relationship). Both the
**field name** and the **type name** are always shown as `fieldName:TypeName`,
because the field name (typically plural) differs from the type name (typically
singular). The field name is structurally significant — it represents a **section
level** in the target document, with each list item as a subsection.

When a list has `@Min` or `@Max` constraints, the bounds are shown as a
`(min,max)` prefix before the `-:`. If there are no constraints, just `-:` is
used. Omitted values mean "no constraint" (min defaults to 0, max defaults to ∞):

| Notation | Meaning |
|----------|---------|
| `-:` | Default: 0..∞ (no constraints) |
| `(1,)-:` | At least 1, no upper limit |
| `(,5)-:` | At most 5, min 0 |
| `(1,5)-:` | Between 1 and 5 items |

```
-: systems:ExistingSystemEntry
    -> content, systemName, technology, purpose
    (1,)-: knownLimitations:LimitationEntry
        -> content, limitation, impact
```

#### 11.2.4 Leaf fields

All scalar fields (`String?`, `String`, enum types) of a class are collected on a
**single line**, comma-separated, prefixed with `->`:

```
-> content, systemName, technology, purpose
```

**Line wrapping:** if the leaf line exceeds the configured max line length
(default **120 characters**, including indentation), it wraps to continuation
lines indented **one level deeper** than the original:

```
-> content, systemName, technology, purpose, activeUsers,
    dataVolume, operationalSince, supportStatus
```

Shape-(3) `DocSpecsSection` members render here too: they report `String` at the
meta boundary (§5.2), so the outline is unaffected by the object typing.

#### 11.2.5 Enum fields

Enums are shown inline with their values in parentheses:

```
-> Priority (must, should, could, wontThisTime)
```

If an enum field is among other leaf fields on the same line, it appears in-place
with the field name as prefix:

```
-> content, priority: Priority (must, should, could, wontThisTime), status
```

Enum values are shown at **every occurrence** — this keeps the outline
self-contained.

#### 11.2.6 Content field

The `content: String?` field is present on nearly every class; it represents the
section content of a document section, the text between the section headline and
the next headline. It is shown as a regular leaf field (first in the comma list
by convention) — **not** hidden or implicit. Other scalar fields are inside this
section text in the actual document. If a class has additional scalar fields, the
`@ContentType` must be `Form`, which indicates this is the container for the data
fields. If `@ContentType` is not `Form` (`SQL`, `DDL`, `Dart`, …) the class
cannot have other scalar fields (§5.6).

#### 11.2.7 Nullable vs non-nullable

The outliner distinguishes `String?` from `String` and `Type?` from `Type`. The
types (or field names) are simply suffixed with a question mark, just as they are
in Dart.

#### 11.2.8 Field ordering

Fields are listed in **declaration order** as they appear in the source class.

#### 11.2.9 References

Fields annotated with `@Reference` are shown with both field name and type name,
plus reference information:

**Singular reference:**

```
-> fieldName:TypeName:<reference-path>
```

**List reference:**

```
-: fieldName:TypeName:<reference-path>
```

The reference path uses `-` to separate 1:1 relationships and `:` to separate 1:n
(List) relationships:

```
-> basedOnRequirement:FunctionalRequirementEntry:SolutionBlueprint-SystemOverview-RequirementsOverview:functionalRequirements
```

#### 11.2.10 Inline comments

Fields or classes annotated with `@Comment("text")` display the comment as a
trailing annotation:

```
-: systems:ExistingSystemEntry          ← (text from @Comment)
```

**Comment placement:** the `← (...)` marker starts at column **50** of the line
(counting from the beginning PLUS indentation), or immediately after the line
content plus one space if the content is longer than 50 characters.

#### 11.2.11 Position markers

The default position is **relative** — subsections appear in the order they are
declared in the class. When a field has a non-default `@Position` annotation, it
is shown as a trailing marker in square brackets:

```
-: preamble:PreambleEntry                [first]
-: items:ItemEntry                       [any]
-: appendices:AppendixEntry              [last]
```

Position markers are aligned at column 50 (same as comments). The `[relative]`
marker is never shown as it is the default.

#### 11.2.12 ForEach constraints

A list field annotated with `@ForEach` has a bidirectional relationship with a
registry section type. This is shown with a `⟷` marker:

```
-: implementations:ImplementationEntry   ⟷ RequirementEntry.requirementId
```

This means: for every entry of type `RequirementEntry` (matched by its
`requirementId` field), there must be a corresponding item in the
`implementations` list, and vice versa.

#### 11.2.13 Outline visibility

Not all annotations appear in the outline. Annotations are categorized as
**visible** (affect the outline rendering) or **schema-only** (used for schema
generation and validation but not shown in the outline):

| Annotation | Visible | Outline rendering |
|------------|---------|-------------------|
| `@Min`, `@Max` | Yes | `(min,max)-:` prefix on list lines |
| `@Position` | Yes | `[first]`, `[last]`, `[any]` marker (non-default only) |
| `@ForEach` | Yes | `⟷ Type.key` marker |
| `@TextRequired` | Yes | `!` suffix on `content` field |
| `@ContentType` | Yes | `@type` suffix on content |
| `@Unused` | Yes | Marks content as unused (no section text expected) |
| `@Comment` | Yes | `← (text)` marker |
| `@Reference` | Yes | Reference path notation (see §11.2.9) |
| `@SectionId` | Yes | Can be shown alongside type name |
| `@SectionIdPattern` | Yes | Can be shown alongside list field |
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
| `@MapsTo`, `@DetailedIn` | No | Meta-data only (Solution Blueprint → Phase 3 traceability) |
| `@StandardReferences` | No | Meta-data only (standard provenance + connotation) |
| `@CodeSpecKind`, `@FollowUpKind`, `@CodeSpecsProjection` | No | Meta-data only (CodeSpecs / follow-up mapping) |

#### 11.2.14 Inline schema annotations (`--show-schema-annotations`)

When the `--show-schema-annotations` flag is set, schema-only annotations (those
marked "No" in §11.2.13) are shown **inline** in the tree, directly above the
line they annotate. Each annotation appears on its own line, at the same
indentation as the annotated line, prefixed with `#` to distinguish it from
structural lines.

Without the flag, schema annotations are omitted.

**Class-level annotations** appear above the class/type line:

```
        -> ExistingSystemsLandscape
            # @Prefix("CSA-SYS")
            # @PatternCheckId(r'^CSA-SYS-\d{2}$', "Must be CSA-SYS-NN")
            # @MaxDepth(2)
            -> content!, currentArchitecture
            -: systems:ExistingSystemEntry
```

**Field-level annotations** appear above the field they annotate. For leaf fields
on a comma-separated `->` line, the annotation is placed above the entire leaf
line:

```
            -: systems:ExistingSystemEntry
                # @MinLength(50) content
                # @PatternCheck(r'^[A-Z]\w+$') systemName
                # @AccessKey("systemName") systemName
                -> content, systemName, technology, purpose
```

**Rules:**

- Only classes/fields that **have** schema-only annotations get `#` lines — no
  clutter when no schema annotations exist.
- Annotation lines use a `#` prefix to visually separate them from structural
  `->` and `-:` lines.
- Class-level annotations appear after the class type line, before the class's
  children.
- Field-level annotations appear before the leaf/child line they belong to, with
  the field name after the annotation to identify the target.
- When a class appears multiple times (inline expansion), its schema annotations
  are shown at **every** occurrence for self-containedness.

### 11.3 Type expansion

#### 11.3.1 Inline expansion

When a complex type is used, its full subtree is shown **inline at every usage
point**. There is no separate "type definitions" section — duplication is
intentional so the reader can see the full structure at each location without
jumping around.

#### 11.3.2 Cycle detection

Cycles **must not exist** in the model (§5.7). If a cycle is detected during tree
walking, the generator **fails with a clear error message** naming the types
involved. There is no soft handling (no `[circular — see above]`).
`@Reference`-marked links are not considered cycles: the annotation indicates
that the link should be shown, but not followed in traversal.

### 11.4 Output example

The example below shows the `tom_specs_model` tree with all notation features.
Hypothetical annotations are included to demonstrate the notation — they are not
all applied to the model.

```
# Solution Blueprint Outline

SolutionBlueprint
    -> header:DocumentHeader
        -> content, documentId, project, version,
            date @date, author, status
    -> CurrentStateAnalysis
        -> content
        -> ExistingSystemsLandscape
            -> content!, currentArchitecture
            -: systems:ExistingSystemEntry
                -> content, systemName, technology, purpose,
                    activeUsers @int, dataVolume,
                    operationalSince @date, supportStatus
                (1,)-: knownLimitations:LimitationEntry
                    -> content, limitation, impact
            -> DependenciesAndIntegrations
                -> content
                -: items:SystemDependencyEntry
                    -> content, sourceSystem, targetSystem,
                        dependencyType, protocol, dataExchanged,
                        criticality
        -> CurrentBusinessProcesses
            -> content
            (1,)-: workflows:CurrentWorkflowEntry
                -> content, processName, trigger, output,
                    cycleTime
                (1,)-: steps:WorkflowStepEntry
                    -> content, stepName, description
                -: actors:WorkflowActorEntry
                    -> content, actorName, role
                -: manualSteps:WorkflowStepEntry
                    -> content, stepName, description
                -: errorProneSteps:WorkflowStepEntry
                    -> content, stepName, description
            -> ProcessMetrics
                -> content
                -: items:ProcessMetricEntry
                    -> content, metricName, processReference,
                        currentValue, unit, measurementMethod,
                        frequency
        -> PainPointsAndGaps
            -> content
            -> OperationalPainPoints
                -> content
                (1,)-: items:PainPointEntry
                    -> content, painPoint, description, impact,
                        affectedProcess, severity, workaround
            -> BusinessPainPoints
                -> content
                -: items:PainPointEntry
                    -> content, painPoint, description, impact,
                        affectedProcess, severity, workaround
            -> TechnicalPainPoints
                -> content
                -: items:PainPointEntry
                    -> content, painPoint, description, impact,
                        affectedProcess, severity, workaround
        -> CurrentDataLandscape
            -> content, dataQualityAssessment
            -: dataSources:DataSourceEntry
                -> content, dataStoreName, storeType, technology,
                    dataFormat, estimatedVolume, growthRate,
                    qualityLevel, owner, retentionPolicy
    -> projectOrganizationProcess:ProjectOrganizationAndProcess
        ...
    -> Administrative
        ...
    -> SystemOverview
        -> content
        -> SystemDescription
            -> content!, systemPurpose, systemContext, taskArea
            (1,)-: userCategories:UserCategoryEntry
                -> content, categoryName, description,
                    typicalTasks, accessLevel, estimatedCount @int
            -> UserInteractionModel
                -> content, sessionModel, concurrencyModel
                -: channels:InteractionChannelEntry
                    -> content, channelName, description
                -: interactionPatterns:InteractionPatternEntry
                    -> content, patternName, description
        -> Goals
            -> content
            (1,)-: businessGoals:BusinessGoalEntry
                -> content, goalId, goalName, description,
                    measurableTarget, targetDate @date
            (1,)-: projectGoals:ProjectGoalEntry
                -> content, goalId, goalName, description,
                    successCriteria
        -> requirements:RequirementsOverview  ← (Seeds → RC)
            -> content
            (1,)-: functionalRequirements:FunctionalRequirementEntry
                -> content, requirementId, title, description,
                    priority: Priority (must, should, could, wontThisTime),
                    source, rationale, acceptanceCriteria,
                    status: Status (draft, proposed, approved,
                        implemented, verified, deferred, rejected),
                    relatedUseCase, relatedBusinessProcess,
                    affectedDataEntities
            -: nonFunctionalRequirements:NonFunctionalRequirementEntry
                -> content, requirementId, title, description,
                    priority: Priority (must, should, could, wontThisTime),
                    source, rationale, acceptanceCriteria,
                    status: Status (draft, proposed, approved,
                        implemented, verified, deferred, rejected),
                    qualityAttribute, measurableTarget
        -> systemsToReplace:SystemsToReplace  ← (Seeds → CS)
            ...
        -> SystemBoundaries
            ...
        -> FrameworkConditions
            ...
        -> RisksAndAssumptions
            ...
    -> OrganizationalFramework
        ...
    -> targetBusinessProcess:TargetBusinessProcessModel
        ...
    -> businessDataModel:BusinessObjectAndDataModel
        ...
    -> technicalFramework:TechnicalFrameworkConcept
        ...
    -> accessAuthorization:AccessAndAuthorizationConcept
        ...
    -> UserInterfaceDesign
        ...
    -> SystemQualityGoals
        ...
    -> ComponentsToUse
        ...
    -> SystemStagePlan
        ...
    -> deliveryAcceptance:DeliveryScopeAndAcceptance
        ...                                      [last]
```

**Features demonstrated:**

- **Name-match rule**: `CurrentStateAnalysis` (field matches type) vs
  `header:DocumentHeader` (field ≠ type).
- **Enum inline values**: `priority: Priority (must, should, could, wontThisTime)`.
- **`@Comment`**: `← (Seeds → RC)` on the requirements section.
- **`@Min`/`@Max` count constraints**: `(1,)-:` on lists requiring at least one
  item (`knownLimitations`, `workflows`, `steps`, `businessGoals`,
  `functionalRequirements`, …).
- **`@TextRequired`**: `content!` suffix on `ExistingSystemsLandscape` and
  `SystemDescription`.
- **`@Position`**: `[last]` on `deliveryAcceptance` (must appear after all other
  sibling sections).
- **Line wrapping**: long leaf lines wrap at 120 chars, continuation indented one
  level deeper.
- **Inline expansion**: `PainPointEntry` is expanded identically under all three
  pain-point subsections.
- **List fields**: always `fieldName:TypeName` (e.g. `-: items:SystemDependencyEntry`).
- **Mismatched section names**: `projectOrganizationProcess:ProjectOrganizationAndProcess`,
  `targetBusinessProcess:TargetBusinessProcessModel`, ….

### 11.5 Generator implementation notes

1. **Entry point:** `tom_specs_clitool/bin/outliner.dart`. The whole committed
   outline set is regenerated by `tom_specs_clitool/tool/regenerate_outlines.sh`,
   which wraps it.
2. **Analyzer setup:** `SummaryBasedDartSdk` with an embedded SDK summary bundle
   (no installed SDK required). The `sdk_summary.sum` file (~3 MB) is split into
   ~50 base64-encoded Dart source files in `lib/src/sdk_summary/`, reassembled at
   runtime. Model source files are analyzed directly from disk. See
   `analyzer_wo_sdk.md` for full details.
3. **Annotation reading:** read `@Reference`, `@SectionId`, `@SectionIdPattern`,
   `@Comment`, `@ContentType`, `@Form`, `@Unused`, `@Prefix`, `@PatternCheckId`,
   `@TextRequired`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`, `@Min`,
   `@Max`, `@Position`, `@ForEach`, `@AccessKey`, `@PatternCheck`, `@MinLength`,
   `@MaxLength`, `@SeedFor`, `@SerializationOrder`, `@Headline`, `@MapsTo`,
   `@DetailedIn`, `@StandardReferences` from the analyzer's element model. All
   model classes in the package are scanned — no marker annotation is required.
   The full annotation catalogue and the section base types are documented in
   [`tom_specs_core/README.md`](../../tom_specs_core/README.md).
4. **Tree walk:** start from the root type, recursively visiting each field:
   - `String` / `String?` → collect as leaf.
   - enum → format with values inline.
   - `List<T>` → emit `(min,max)-: fieldName:TypeName` (with constraints from
     `@Min`/`@Max`) and recurse into `T`.
   - complex type → emit `-> TypeName` and recurse.
   - `@Reference` → emit with reference notation.
5. **Validation pass** (before output): run the full rule set of §5 and §10.2 —
   member shapes, type constraints, naming, class style, content type, section-id
   invariants, cycle detection. Fail on the first error with a clear message.
6. **Line wrapping:** track current line length. When a leaf line exceeds the max
   (default 120), wrap at a comma boundary and indent the continuation one level
   deeper.
7. **Comment alignment:** pad `← (...)` annotations to start at column 50, or one
   space after content if content exceeds 50 chars.
8. **Inline schema annotations:** when `--show-schema-annotations` is set, emit
   `# @Annotation(...)` lines inline during the tree walk — class-level after the
   type line, field-level before the field line (§11.2.14).

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
`tom_specs_clitool/README.md`, `som_mapping.md` (what it emits),
`spec_object_model_config.md`, `spec_model_meta_schema.md`, `analyzer_wo_sdk.md`.

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
`tom_specs_editor_specification.md` (and `multiplatform_spec_model.md` §7 for the
runtime relationship).

---

## 13. Reference index — where each rule is authoritative

| Subject | Authoritative document |
|---------|------------------------|
| Model-authoring rules, section-ID scheme, annotations for the author, outline notation | `tom_specs_model_rules.md` (here) |
| **Mapping — object model ↔ md / yaml / schema, metadata tree, generated surfaces, parse+validate API** | **`som_mapping.md`** (the single mapping authority) |
| Per-annotation reference | `tom_specs_core/README.md` |
| Structural invariants (implementation) | `tom_specs_clitool/lib/src/validator.dart` (`validateStructuralInvariants()`) |
| How the section-ID scheme was arrived at (design record) | `section_id_pattern_plan.md`, `field_suffix_list_id_plan.md` |
| Multi-platform SOM component | `multiplatform_spec_model.md` |
| Generator config / meta-schema / toolchains | `spec_object_model_config.md`, `spec_model_meta_schema.md`, `som_toolchains.md` |
| DocSpecs format itself (schemas, section types, validation) | `_ai/quests/doc_specs/doc_specs_specification.md` |
| DocSpecs ↔ CodeSpecs link, `@CodeSpecKind`, the parts catalogue | `codespecs_mapping.md` |
| Creation process / phases | `tom_specs_project_flow.md` §PF-PHA, `overview.tom_specs.md` |
| Roles / quality gates | `tom_specs_project_flow.md` §PF-ROL, §PF-GAT |
| Solution Blueprint → Phase 3 document mapping | `tom_specs_project_flow.md` §PF-FLW |
| Issue workflow / upgrade cycles | `tom_specs_project_flow.md` §PF-ISS, §PF-UPG |
| Editor / reviewer | `tom_specs_editor_specification.md` |
