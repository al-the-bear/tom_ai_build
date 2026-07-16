# TomSpecs Mapping — Object Model ↔ SOM Classes ↔ DocSpecs md/yaml

**Status:** Normative. This is the **single authority** for how the document
structure of a DocSpecs document is described as an object model in
`tom_specs_model`, and how that model is mapped to the SOM classes — the
generated concrete (editing) classes, the runtime access classes, and the
meta-data classes — including the md/yaml serialization of every construct.

It consolidates and **supersedes**:

- `_ai/quests/tom_specs/som_document_formats_redesign.md` (DR1 — byte-level
  md/yaml format, schema generation, embedded validator),
- `tom_ai/ai_build/tom_som_conformance/som_file_mapping.md` (member-by-member
  mapping semantics),
- `tom_ai/ai_build/tom_specs_model/doc/specs_model_outliner.md` §6–§7 (model
  design rules and annotation semantics; the outliner doc keeps only the
  outliner *tool* rendering specification),

all three now reduced to redirect stubs. The doc-comment → annotation
derivation rules (`tom_specs_clitool/doc/comments_annotations_rules.md`)
describe the one-time historical migration campaign and are non-normative.

**Design authority.** This document describes the **decided target state**
fixated in `_ai/quests/tom_specs/headline_id_storage_decisions.md` and
`_ai/quests/tom_specs/docspecs_section_model_decisions.md`. Parts that are not
yet implemented are marked with a status tag:

| Tag | Meaning |
| --- | --- |
| *(implemented)* | Matches the current code (Dart reference + ports where stated). |
| *(DECIDED — YRDn)* | Fixated design, implementation tracked by the named quest todo in `_ai/quests/tom_specs/todos.tom_specs.todo.yaml`. Until the todo lands, the code follows the "current behaviour" noted alongside. |

Where this document is silent, the Dart reference implementation
(`tom_som_dart_runtime`, `tom_specs_clitool`) is the tiebreaker and this
document must be amended to match it in the same change.

---

## 1. The universal section structure

A TomSpecs specification is a **document for human readers**; the DocSpecs
`*.md` file is the logically primary target format. The SOM document format is
compatible with the doc_scanner / doc_specs format and describable as a
DocSpecs schema (`_ai/quests/doc_specs/doc_specs_specification.md`).

Every document is a tree of **sections**. Always, at every level, a section is:

```
<headline (with <!--[ID]--> comment)>
<content (optional body text)>
<subsections…>
```

1. **Every section has a section id and a headline.** Both are first-class
   *stored* values on every section — fixed sections and list items alike —
   persisted in md and yaml, surviving modification through all three
   representations (object model, yaml, md). *(DECIDED — YRD3; current
   behaviour: headlines are derived at render time and discarded on parse;
   list-item stored ids round-trip through yaml only.)*
2. **A list is always an outer section** containing the entry sections of the
   list. The content of the outer (container) section has **no meaning defined
   by the tom_specs description** — it may hold text, but the model assigns it
   no semantics. Each list entry is itself a regular section. *(implemented —
   the `*-LST` container level in model, md, and yaml; see §3.2, §8.5, §9.)*
3. **Non-list sections and list entries follow the same uniform shape:**
   content (with or without `@Form`) plus optional subsections. A `@Form`
   structures the section's content; it does not change the section shape.
4. **Nesting depth is unbounded.** There is no six-heading-level cap in the md
   format (§8.2); DocSpecs and its tooling must accept arbitrary nesting
   *(implemented — YRD2; `tom_doc_scanner` grammar is `#{1,}` and parses the
   shared SOM sample, which nests to level 12, end-to-end)*.

Terminology used throughout: *section id* = the `@SectionId` mnemonic
(`INSC`); *member name* = the exact field/class identifier in the model;
*path* = the runtime navigation path (`DEMO/introductionAndScope/GOAL-ITEM-1/content`);
*kind* = one of the seven `SpecFieldKind` values (`list`, `form`, `section`,
`content`, `enum`, `complex`, `scalar`).

### 1.1 Running example

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

## 2. The object model (`tom_specs_model`)

A TomSpecs document *is* a class instance graph. One `@Document` root class is
the top-level document section; each reachable class is a section; each member
is either the section's own content, a child section, or a list of child
sections. Serialization — to yaml or md — is a single depth-first walk of that
tree in `@SerializationOrder` order.

### 2.1 Canonical field shapes

A model class may contain **only** the following six member shapes — nothing
else. The clitool validator (`tom_specs_clitool/lib/src/validator.dart`)
enforces these as hard errors:

| # | Shape | Meaning |
|---|-------|---------|
| **(1)** | `String content` (plain) | The section's OWN content. The section id comes from the **class**, not the field. |
| **(2)** | `String content` with `@Form` | The `content` value is the pre-form narrative, followed by the form's field members. |
| **(3)** | `String <name>` with a **field-level `@SectionId`** (optionally `@Form`) | An inline sub-section whose content IS this field. A `@Reference` field is this shape (its id is required). |
| **(4)** | `<SectionClass> field` | A sub-section class; the class owns the id (a field-level id may still override). |
| **(5)** | `List<SectionClass>` with `@SectionId` + `@SectionIdPattern` | A list of sub-section classes; each element gets a per-instance id from the pattern. |
| **(6)** | `List<String>` with `@SectionId` + `@SectionIdPattern` (optionally `@Form`) | An inline list of content sub-sections. |

Hard error cases:

- **Non-String scalar** — any free `int`/`bool`/`double`/`num`/`DateTime`
  field. Typed scalars are legitimate only as `@Form` field members, never as
  free model fields.
- **Non-`content` String without a field-level `@SectionId`** — every
  descriptively-named `String`/`String?` field is an inline sub-section
  (shape (3)) and must be addressable.
- **Misused reserved name `content`** — a field named `content` that is not a
  plain `String`/`String?` value, or a `content` field carrying a field-level
  `@SectionId`. The name `content` is reserved for the section's own content;
  its id comes from the class.

Enum fields are outside these rules — neither required to carry an id nor
forbidden. Missing `content: String?` on a class is a **warning**, not an
error.

### 2.2 `DocSpecsSection` base class *(DECIDED — YRD5)*

Per `docspecs_section_model_decisions.md` §4, the model is refactored so that:

- A `DocSpecsSection` class holds **headline, id, and content** — representing
  a simple section with no subsections.
- All uses of `String` members in `tom_specs_model` are replaced with
  `DocSpecsSection` (shape (3) fields become typed sections; a `@Form` or
  `@ContentType` annotation on the member continues to define details).
- All other model classes become **subclasses of `DocSpecsSection`**,
  overriding the `content` member where per-subclass annotations are needed.
- An optional **`DocSpecsForm form`** member holds the parsed form plus the
  pre-form-field content already split off.

Consequence: `tom_specs_model` becomes an object model into which a `*.md`
file can actually be **parsed**. Until YRD5 lands, shape-(3) members are plain
`String?` fields as described in §2.1.

### 2.3 The three member shapes on the serialization walk

Walking a class in serialization order, each member is exactly one of:

1. **`String? content` (the content member).** The section's body text —
   everything between the section's heading and its first sub-section. It is
   *not* a sub-section. Serialized as the `content` yaml key (§9) / the prose
   directly under the md heading (§8.3). `@Form` classes replace the free
   content with `FieldName: value` lines (§8.4). Always emitted **above** any
   child sections.
2. **A singleton complex member (`Foo field;`).** One child section. Recurse
   into `Foo`'s class, whose `@SectionId` becomes the child section id. One
   nesting level deeper in both formats.
3. **A list member (`List<Foo> field;`).** A **two-level** section hierarchy
   (§3.2).

### 2.4 Class style and naming

| Rule | Description |
|------|-------------|
| No constructors | A default constructor is implied. |
| No `final` / `const` | Plain mutable instance fields, like nested records. |
| Non-nullable defaults | Non-nullable fields get a valid default; nullable fields stay null. |
| No computed properties | Only concrete instance fields are model members. |
| Singular match preferred | Singular complex field names should match their type name (`SystemOverview systemOverview`); mismatch is allowed, not an error. |
| Inheritance | Subclasses fully re-declare their fields (replacement, not augmentation); the structure is what each class declares plus non-redeclared inherited fields. |
| Reachability | Only types reachable from the document root are part of that document's structure. |

### 2.5 Content documentation rules

Every `String? content` field must be documented:

| Class type | Documentation source |
|------------|---------------------|
| `*Section` class (`TextSection`, `DiagramSection`, …) | `@ContentType` on the `content` field inside the section class declares the format; the human-readable description is the doc-comment on the **using field**. |
| Regular class with `String? content` | `@ContentType(type, 'description')` on the `content` field (mandatory description). |
| Container class (content unused) | `@Unused()` on the `content` field — no narrative text expected. |

A non-Form `@ContentType` (e.g. `DDL`, `SQL`, `Dart`, `Mermaid`) forbids other
scalar fields on the class — the content occupies the full text.

### 2.6 Keep-a-class and keep-a-level criteria

Shapes (3)/(6) let a leaf sub-section be a *field* instead of a class, and a
single-subsection wrapper level can be *collapsed* — but only when safe:

- **A sub-section stays a class** when it is **shared** (referenced by more
  than one parent field across the model — e.g. `DocumentHeader`) or is a
  **form-bearing list element** (a `List<L>` element whose `L` carries
  `@Form`; a scalar `List<String>` has no place for per-element form fields).
  The validator never flags kept classes; collapse candidacy is a codemod
  concern (`collapse_leaves.dart`, `collapse_list_leaves.dart`).
- **A wrapper stays a level** when its own content has meaning by itself:
  it (or a field) carries `@Form`; a leaf carries substantive `@ContentHelp` /
  `@StandardReferences` / non-Form `@ContentType`; it is shared; or it declares
  a named leaf besides `content`. Only when *none* of these hold is the
  wrapper pure indirection — the validator emits a `§6.1c collapsible-wrapper`
  **warning** for such candidates. The model is at the steady state: zero
  candidates remain (census tools: `tom_specs_clitool/tool/keep_class_census.dart`,
  `tool/tsma4_census.dart`).

Note *(DECIDED — YRD10 audit)*: under the §1 list-as-outer-section rule, a
pure single-list wrapper is doubly redundant (the list already provides its
own section level); the YRD10 audit re-checks wrappers against this rule.

---

## 3. Section identity

### 3.1 Section ids

Section ids are short, flat mnemonics identifying the *type* of a section
(not its position). Uppercase alphanumerics and `-` (`[A-Z0-9-]+`).

**Class-level `@SectionId`** — every model class carries exactly one:

- Document roots use their short document codes: `SBP`, `CLA`, `TOM`, `IFM`,
  `RSP`, `ISC`, `ATS`, `IIS`, `SAS`, `XDS`, `QAP`, `DRM`, `TRP`.
- Top-level section classes may use 3–4 letters (`SYOV`, `CURS`); all other
  classes use up to 6 letters derived from the class name (`EXTSY` for
  `ExistingSystemEntry`).
- Class-level ids are **globally unique** across the model (validator §2).

**Field-level `@SectionId` on a `List<T>` field** — the list **container** id,
pattern `<elementId>-<FIELDSUFFIX>-LST` where `<FIELDSUFFIX>` is the field
name uppercased and truncated to its first 4 alphanumerics (`systems` →
`SYST`):

```dart
@SectionId('EXTSY-SYST-LST')
@SectionIdPattern('EXTSY-SYST-xxx')
List<ExistingSystemEntry> systems = [];
```

The field-name suffix guarantees two list fields of the same element type in
one class get distinct container ids (`inScopeProcesses` → `PRSCEN-INSC-LST`,
`outOfScopeProcesses` → `PRSCEN-OUTO-LST`). The element type is recoverable
from any id by taking the first `-`-token.

**Field-level `@SectionId` on a `String` field** — shape (3): an inline
sub-section id, naming scheme `<PARENT_CLASS_SECTIONID>-<FIELD4>` (references:
`…-REF` suffix, e.g. `KEATT-REFE-REF`).

**Uniqueness namespaces** (validator §2/§2b):

- Class-level ids: globally unique. Container ids occupy a *different*
  namespace (never compared against class-level ids).
- Container ids: unique **within a class**; cross-class sharing is legitimate
  when both element type and field name coincide (addressing is
  parent-path + local id).
- A container id maps to exactly one element type.

### 3.2 Lists — the `*-LST` container is a real section *(implemented)*

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
  `FOO-FLD-1`, `FOO-FLD-2`, … — **not** zero-padded; the earlier outliner-doc
  `EXTSY-SYST-001` examples were wrong).
- Per §1.2 the container's own content has no model-defined meaning. The
  generated schema pins it as always-empty (min/max-text-length 0, §10), and
  the yaml container mapping holds only the item keys (§9.3.5).
- The md heading tree, the yaml tree, and the object model are structurally
  isomorphic: the container is its own nesting level in all three.

### 3.3 Stored per-item section ids

List items can carry **stored** section ids: AA1 date-lettered generated ids
(`GOAL-ITEM-GL1`) or explicit overrides (`SpecDocument.setItemSectionId`,
`SomNode.$sectionId`, `SomList.add(sectionId:)`), validated for list-scoped
uniqueness. Items without a stored id are **anonymous** — identified by their
1-based positional pattern id.

*(DECIDED — YRD3; reverses the earlier DRC5 rule)*: stored ids are persisted
by **both** wire formats. The md exporter renders a stored id in the item's
`<!--[id]-->` comment (positional pattern id only as fallback for anonymous
items); the md parser already accepts and keeps stored ids. Parse-side
positional matching of anonymous items is kept. *Current behaviour: the md
exporter emits only positional ids, so md round-trips lose id overrides;
yaml preserves them losslessly.*

Schema interaction: the generated `pattern-check-id` stays a clean
`^FOO-FLD-[0-9]+$`; stored non-positional ids are validated by the runtime's
list-scoped rules, not by the schema pattern.

---

## 4. Headlines *(DECIDED — YRD3/YRD4/YRD6/YRD9)*

Per `headline_id_storage_decisions.md`:

1. **Every section stores a headline** (fixed sections and list items),
   persisted in md and yaml. For list entries the headline is per-instance
   free text — the sections whose meaning cannot be predetermined.
2. **`@Headline(String text)`** *(YRD4)* — predefines the headline for
   fixed-meaning sections in the model. The predefined headline prefills the
   editor on section creation and is the render fallback; the **stored
   headline always wins** and remains editable.
3. **Render precedence:** `stored headline > @Headline default > name
   derivation`. The derivation fallback is the current behaviour: Title-Case
   of the member name for fields/containers (`introductionAndScope` →
   `Introduction And Scope`), `<ElementTitle> <seq>` for list items where the
   element title is the Title-Case element class name with a trailing `Entry`
   dropped.
4. **`TitleField` / `IdField` form-field roles** *(YRD6)* — a `@Form` `Field`
   can be marked as the section's *title field* or *id field*: the field's
   value **is** the section headline / section id — one storage slot, two
   views. The marker can predefine the field's initial content. Id fields are
   subject to the owning list's `@SectionIdPattern` validation. Serialization
   emits the value once (as the heading / id comment), never duplicated as a
   form line.
5. **Editor strict mode** *(YRD9)* — headlines and ids editable only for
   list-entry sections; fixed sections show their stored/default headline
   read-only.

*Current behaviour (bug, per decision (a)): there is no headline storage
anywhere — every md heading title is derived at render time and the md parser
discards heading text (`spec_document_markdown.dart` reads only the id
group). YRD3 fixes storage + round-trip in all nine runtimes.*

---

## 5. Annotations

Annotations live in `tom_specs_core`; the complete per-annotation reference is
[`tom_specs_core/README.md`](../../tom_specs_core/README.md). The
mapping-relevant semantics:

| Annotation | Applies to | Meaning in the mapping |
|---|---|---|
| `@Document(name, description, basedOn:)` | root class | Top-level document section; supplies the schema id (kebab-case `name`) and `major.minor` version. |
| `@SectionId(id)` | class, `List<T>` field, or `String` field | §3.1: class id / `-LST` container id / inline sub-section id. |
| `@SectionIdPattern(pattern)` | `List<T>` field | Per-item numbering template, mirrors the container id with `-LST` → `-xxx`; validator enforces the pairing. |
| `@Headline(text)` | class or field | Predefined default headline (§4). *(DECIDED — YRD4)* |
| `@Form([Field…])` | class or `content` field | Form section: scalar fields serialize as `FieldName: value` lines. `Field(name, type, hint:, required:)`; `TitleField`/`IdField` roles per §4.4. |
| `@ContentType(type, description)` | `content` field | Content medium (`markdown`, `sql`, `dart`, …). Non-`form` types forbid sibling scalar fields. |
| `@ContentHelp(text)` | class or member | Authoring guidance → schema `description`. |
| `@Comment(text)` | class or field | Inline human note (outliner display; `Seeds → XX` provenance). |
| `@Min(n)` / `@Max(n)` | `List<T>` field | Item-count bounds → schema `min-count`/`max-count`. |
| `@Unused()` | `content` field | Structural container only; omitted from the schema, still walked for layout. |
| `@SerializationOrder(n)` | every member | Sibling emission order in every observable surface. Stamped in bulk by `tom_specs_clitool/bin/stamp_serialization_order.dart`. |
| `@Reference(description)` | field | Points at data owned elsewhere; renders as an ordinary content-kind inline sub-section keyed by its field-level `…-REF` id whose *value* is the referenced section id. Never followed in traversal; excluded from ownership/cycle/list coverage. |
| `@MapsTo(Type)` | class | Seed node of a Phase 3 DocSpec in the master model — the whole subtree flows to that document. |
| `@DetailedIn(Type)` | class | Promoted to a top-level entry of a Phase 3 DocSpec; must have a `@MapsTo` ancestor (§12). |
| `@SecondLevelSectionId(Type, id)` | class | Document-scoped short id within a Phase 3 document; implies `@DetailedIn` (§12). |
| `@StandardReferences(standards, connotation)` | class or field | Public-standard provenance + meaning; carried in the meta-data. |
| `@SeedFor(Type)` | class or field | Compile-time link for a single-target `Seeds → XX`. |
| `@Prefix`, `@PatternCheckId`, `@PatternCheck`, `@TextRequired`, `@MinLength`, `@MaxLength`, `@MaxDepth`, `@AllowedTags`, `@ValidationPrompt`, `@Position`, `@ForEach`, `@AccessKey` | various | Validation/schema constraints; captured into the meta tree's generic `extra` list and mapped by the schema generator where relevant (§10). |

---

## 6. The metadata tree

The clitool extracts, and every facade embeds, **one canonical
language-neutral metadata tree per document root**
(`tom_specs_clitool/lib/src/meta_tree.dart`, `MetaTreeBuilder`). It carries
every `tom_specs_core` annotation plus exact source names. Single source: the
nine emitters and the schema generator all consume this one tree.

### 6.1 Node structure

```
MetaNode
  className         String    exact model class name
  memberName        String?   exact field name in the parent; null on the root
  sectionId         String?   field-level @SectionId only; drives the path segment
  classSectionId    String?   the target class's own @SectionId; the yaml/md
                              key id falls back to this for a section/complex
                              node whose sectionId is null
  sectionIdPattern  String?   @SectionIdPattern on the field
  kind              Kind      list | form | section | content | enum | complex | scalar
  typeName          String    Dart type name
  serializationOrder Int?     @SerializationOrder
  min               Int?      @Min
  unused            Bool      @Unused present
  contentType       (type, description)?   @ContentType
  contentHelp       String?   @ContentHelp
  comment           String?   @Comment
  docComment        String?   cleaned /// doc comment (member wins; class
                              docComment carried as classDocComment when it differs)
  headline          String?   @Headline default (DECIDED — YRD4)
  form              FormMeta? for kind == form
  document          DocMeta?  for the document root only
  mapsTo            String?   @MapsTo target class name
  detailedIn        String?   @DetailedIn target class name
  secondLevelIds    [(documentClass, id)]  @SecondLevelSectionId
  extra             [(annotation, args)]   all remaining annotations
  children          [MetaNode]  in @SerializationOrder order
  elementNode       MetaNode?   for kind == list: the element class subtree

FormMeta
  fields: [(name, typeName, hint, order [, titleField, idField — DECIDED YRD6])]

DocMeta
  name, description, basedOn   (@Document)
```

Key rules:

- A field-level `@SectionId` populates `sectionId`; the target class's own
  `@SectionId` populates `classSectionId` — the two are **not merged**. The
  **path segment** uses `sectionId` (else member name; never the class
  fallback); the **yaml/md key id** prefers `sectionId` and falls back to
  `classSectionId` for section/complex nodes. A transparent section thus keys
  on its class id while pathing on its member name.
- **Recursion:** a class already on the descent stack is emitted as a
  reference node (`kind: complex`, `recursive: true`, no children).
- **Kind classification** (`MetaTreeBuilder.classifyField`): `List` → `list`;
  `@Form` fields → `form`; section types → `section`; enums → `enum`;
  `String` → `content`; primitives → `scalar`; other classes → `complex`.

### 6.2 Embedded representation

Each facade embeds the populated tree as **generated static data structures in
code** (not a JSON asset) — one tree per document root, addressable from the
root constant. The meta-JSON (`spec_model.meta.json`) remains a build artifact
for tooling (e.g. the `tom_specs_editor` app consumes the exported class
graph), but is not the runtime's access path.

---

## 7. Generated SOM surfaces

Three class families are generated per document root, in each of the nine
language runtimes (Dart reference + Python, Java, JavaScript, TypeScript, Go,
Rust, C, C++):

1. **Concrete editing classes** — the typed facade (`D00SolutionBlueprint`
   etc.): typed getters/setters over the runtime `SpecDocument`, one member
   per model member. Lists are `SomList<T>` (scalar lists: `SomList<SomScalar>`
   with the item value at the item path). *(DECIDED — YRD7)*: every `@Form`
   becomes a section class with `String content` (the pre-field text) **plus
   one typed member per form field**.
2. **Runtime access classes** — `SpecDocument` (path-keyed value store,
   staged-change discipline), `SomNode`/`SomScalar`/`SomList` facade
   primitives, the md/yaml codecs, and the embedded parse/validate API (§11).
   *(DECIDED — YRD7)*: the runtime and meta classes represent all typed form
   fields plus all annotation-derived metadata and provide a **generic
   meta-model** through which any document can be modified via the API using
   only the basic structural rules (section = id + headline + content +
   subsections; list = container section + entry sections).
3. **Meta-data classes** — the embedded §6 tree plus two generated,
   discoverable access surfaces resolving to the same MetaNode and path
   strings:
   - **Dot-notation tree** (member names):
     `d99DemoDocument.introductionAndScope.path` / `.meta`; list accessors add
     `.item(int seq)`. A recursive re-entry position terminates the generated
     chain (`.path` valid, `.meta` throws past re-entry).
   - **ID-tree** (section ids, `-` → `_` where identifiers require):
     `DEMO.INSC.GOAL.meta.contentHelp`. Id-less members hoist their target's
     id-bearing fields onto the nearest id-bearing ancestor's id class.
   - Both surfaces must agree exhaustively (`.path` string-equal, `.meta`
     identical). Dynamic lookups `byId(sectionId)` / `byPath(path)` remain on
     every runtime.
   - Per-language conventions (Dart `$Nav`/`$Id` accessor classes with
     top-level `final` entry points; Go exported Title-Case; Rust snake_case
     statics; C nested `const` structs of pointers) follow the established
     generated-code conventions of each runtime.

---

## 8. The `*.md` format — strict DocSpecs, full fidelity

The generated/authored markdown **is a genuine DocSpecs document**, readable
and validatable by any DocSpecs-conform tool. **Markdown is a FULL-fidelity
format** *(DECIDED — YRD3)*: it fully serializes **and** deserializes all
headlines, content, form fields, and sections exactly as the yaml format and
the SOM do. (The earlier "md loses stored list-item ids / discards heading
titles" clauses are retired as bugs.)

### 8.1 Header

Line 1 is the DocSpecs schema declaration comment:

```markdown
<!-- docspec: demo-document/1.0 -->
```

Schema id = kebab-case of the `@Document` name; version = model `major.minor`.

### 8.2 Headings and section ids

- Every populated section becomes one heading:
  `## <!--[INSC]--> Introduction And Scope`. The machine identity is the
  DocSpecs headline comment `<!--[id]-->`; the heading text is the section's
  headline (stored > `@Headline` default > derived, §4).
- The heading id is the member's field-level `@SectionId` when present, else
  the target class's `@SectionId`; a member with neither is *transparent*
  (§8.6).
- Heading level = 1 + section depth, **uncapped**. Strict CommonMark renderers
  render `#######`+ as literal text — the machine format is authoritative, not
  the rendering. DocSpecs tooling must accept `#{7,}` *(implemented — YRD2)*.
- Emission is **sparse** (only populated subtrees); sibling order is
  `@SerializationOrder` order.
- Parse resolves a heading's id against the schema tree *at its nesting
  position* (ids resolve within their parent chain); a non-resolving id is a
  structured rejection.

### 8.3 Content sections

Content is normal markdown text directly under its owning heading — no fences,
no anchors:

1. A section's content is everything between its heading and the next heading
   (any level), trimmed of leading/trailing blank lines.
2. Embedded markdown (lists, emphasis, tables) is kept verbatim.
3. Content must not contain headings at column 0 — the emitter escapes a
   leading `#` as `\#`; the parser unescapes. (The only content escaping rule.)
4. Fenced code blocks pass through verbatim; heading-like lines inside a fence
   are not escaped.
5. Runs of blank lines collapse to one on emit (idempotent; mirrors §9.4);
   parse does not re-collapse.

### 8.4 Form sections

`@Form` content uses the DocSpecs plain-text form format:

```markdown
## <!--[DOCO]--> Document Control

Version: 1.0
ApprovedBy: Programme Sponsor
ReviewCount: 3
```

1. One `FieldName: value` group per populated field, in `@Form` order; the
   label is the field name with the first letter upper-cased; parse matching
   is case-insensitive.
2. Multi-line values run until the next `Fieldname:` line or the section end.
3. A value line that would mis-split as a field label is prefixed with a
   single space on emit (DocSpecs trims leading whitespace — lossless).
4. Unpopulated fields are omitted.
5. Enum/numeric fields serialize canonically (member name; decimal int /
   shortest round-trip double).
6. *(DECIDED — YRD6)*: a `TitleField`/`IdField` value is emitted once — as the
   heading text / id comment — never additionally as a form line.
7. Pre-form narrative content (shape (2)) precedes the first field line.

### 8.5 Lists

The container heads; items nest one level deeper *(implemented)*:

```markdown
## <!--[GOAL]--> Goals

Primary goals of the demo programme.

### <!--[GOAL-ITEM-LST]--> Entries

#### <!--[GOAL-ITEM-1]--> Goal 1

Cut median confirmation time below five minutes.

#### <!--[GOAL-ITEM-2]--> Goal 2

Remove the nightly batch window.
```

- Container heading: the list's `-LST` id (member name for a pattern-less
  list), Title-Case member name as default title, **empty body** (§3.2).
- Item heading id: the item's **stored id** when one exists *(DECIDED — YRD3)*,
  else the positional pattern id (`GOAL-ITEM-<n>`, 1-based). Item heading
  title: stored headline, else `<ElementTitle> <seq>` (§4.3).
- On parse, anonymous positional ids recover list membership and order from
  position; stored ids are kept as stored ids. Lists are never transparent.

### 8.6 Transparent (id-less) members

A member with no section id (neither field-level nor class-level on its
target) is **transparent** — not a section of its own:

- A transparent **value** member (content/scalar/enum/form) emits
  headinglessly into its owner's **body region**: content text, or the form's
  `FieldName: value` block. The body region is the owner's own content
  followed by every transparent body slot in model order (collected
  depth-first through transparent sections). Each slot still binds at its own
  document path.
- A transparent **section/complex** member emits no heading; its id-bearing
  descendants surface as the owner's direct child headings. Paths keep the
  transparent segments; only heading nesting collapses.
- **Lists are never transparent.**

Three canonicalisation losses are accepted and normative:

1. Multiple transparent content members of one owner merge on parse (all text
   binds to the first slot).
2. Colliding transparent-form labels bind to the nearest form in slot order.
3. *(retired)* — the former "list-item stored ids do not round-trip through
   md" loss is reversed by YRD3 (§3.3).

### 8.7 Parsing

`parse(md, metadataTree)` returns staged values keyed by runtime path plus a
rejection list: `unknownSection`, `kindMismatch`, `orphanContent`,
`missingValue`, `malformedHeading`. Nothing is silently dropped.
`emit(parse(emit(doc)))` is byte-identical (modulo the idempotent blank-line
collapse and the §8.6 transparency canonicalisations). Stored headlines are
staged only when they differ from the effective default, keeping untouched
documents byte-stable *(DECIDED — YRD3)*.

### 8.8 Complete example

```markdown
<!-- docspec: demo-document/1.0 -->
# <!--[DEMO]--> Demo Document

Preamble of the demo document.

## <!--[INSC]--> Introduction And Scope

The demo system covers order capture and pricing.

### <!--[GOAL]--> Goals

Primary goals of the demo programme.

#### <!--[GOAL-ITEM-LST]--> Entries

##### <!--[GOAL-ITEM-1]--> Goal 1

Cut median confirmation time below five minutes.

##### <!--[GOAL-ITEM-2]--> Goal 2

Remove the nightly batch window.

## <!--[DOCO]--> Document Control

Version: 1.0
ApprovedBy: Programme Sponsor
ReviewCount: 3
```

---

## 9. The hierarchical `*.docspecs.yaml` format

One nested YAML tree whose indentation mirrors the document structure.

### 9.1 File layout

```yaml
# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.
version: 2                # on-disk format version
modelVersion: "1.0"       # authoring object-model major.minor (optional)
document:
  <root tree>
review:                   # optional, opaque to the runtimes (editor-owned)
  …
```

Readers reject `version: 1` files with a clear error (no compatibility path).

### 9.2 Key syntax

Every model node becomes one mapping key. For a section/complex node (and the
root) the key is `<key-id> <member-or-class-name>`. The key id resolves as the
md heading id does (§8.2): field-level `@SectionId`, else the target class's
`@SectionId`, else (transparent) the bare member name alone. The class
fallback is section/complex-only; scalar/enum fields key on their field-level
id else bare name; `content` bodies and form-field values key on their literal
names with no id.

The key id is deliberately **not** the path segment (which stays strictly
field-level): `INSC introductionAndScope` keys with the class id while its
path segment is the bare `introductionAndScope`.

| Node | Key | Example |
| --- | --- | --- |
| Document root | `<root-id> <RootClassName>` | `DEMO D99DemoDocument` |
| Section/complex/form field | `<id> <fieldName>` | `INSC introductionAndScope` |
| List field (container) | `<container-id> <fieldName>` | `GOAL-ITEM-LST entries` |
| List item | resolved pattern id, or the stored id | `GOAL-ITEM-1` / `GOAL-ITEM-GL1` |
| Content value | literal key `content` | `content` |
| Form field value | literal field name | `approvedBy` |
| Scalar/enum field | `<id> <fieldName>` when the field carries an id, else the field name | `reviewCount` |
| Stored headline | literal key (Dart reference fixes the spelling; DECIDED — YRD3) | |

### 9.3 Structure rules

1. **Nesting = structure.** Children are nested mappings under their key.
2. **Sibling order** is `@SerializationOrder` order (list items by sequence);
   emission is sparse.
3. **Values** are YAML scalars per §9.4/§9.5.
4. The tree carries no paths; the runtime reconstructs paths by walking keys
   against the metadata tree. A key that does not match the tree at its
   position is a structured load error.
5. **The `*-LST` container is a pure structural level** — it never carries a
   `content` key; its mapping holds only the item keys.
6. Stored list-item ids and stored headlines persist here losslessly
   (yaml has always carried stored item ids; stored headlines are DECIDED —
   YRD3).

### 9.4 Text values

All string values are literal block scalars `|-`/`|2-` indented past their
key. Normative escaping:

1. The emitter is **self-verifying**: after writing a block scalar it
   re-parses it; on any difference it falls back to a double-quoted
   JSON-escaped flow scalar (always valid, always round-trips). Covers
   trailing newlines/spaces, whitespace-only values, BOM/control characters.
2. Newline-free, YAML-safe values may be plain one-line scalars; when in doubt
   the emitter uses `|-`. Parsers accept plain, quoted, and block scalars
   interchangeably.
3. **Runs of 2+ blank lines collapse to one before serialization** — the
   deliberate, documented lossy normalization shared with the md emitter
   (§8.3.5). Round-trip guarantees are stated "modulo empty-line dedup".
4. Tabs are preserved verbatim.

### 9.5 Non-text values and the YAML 1.1/1.2 rule

`int`/`double` are plain numbers; `bool` is `true`/`false`; enums are the
member name.

**Owning-layer rule:** a value may render as a *plain* scalar only when
re-parsing yields the identical string — checked against YAML 1.2, **and**
additionally every emitter treats YAML-1.1-special strings as *not plainable*
(forced to block scalars): the extra boolean words
`y/Y/yes/Yes/YES/n/N/no/No/NO/on/On/ON/off/Off/OFF` and sexagesimal ints/floats
(`1:30`, `1:30.5`). This makes the on-disk form version-independent (PyYAML is
1.1-only). Lowercase `true`/`false` stay unguarded (booleans in both
versions). The conformance corpus pins this with a `Meta.tags` case
(`on`, `no`, `1:30`, `plain`).

### 9.6 Complete example

```yaml
# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.
version: 2
modelVersion: "1.0"
document:
  DEMO D99DemoDocument:
    content: |-
      Preamble of the demo document.
    INSC introductionAndScope:
      content: |-
        The demo system covers order capture and pricing.
      GOAL goals:
        content: |-
          Primary goals of the demo programme.
        GOAL-ITEM-LST entries:
          GOAL-ITEM-1:
            content: |-
              Cut median confirmation time below five minutes.
          GOAL-ITEM-2:
            content: |-
              Remove the nightly batch window.
    DOCO documentControl:
      version: |-
        1.0
      approvedBy: |-
        Programme Sponsor
      reviewCount: 3
```

### 9.7 Round-trip contract

`decode(encode(doc))` reproduces every value byte-identically, except the
blank-line collapse. `encode` output is deterministic (stable key order,
stable scalar styles). The shared conformance sample
(`tom_som_conformance/samples/meridian_order_management.*`) must round-trip in
md, yaml, and the schema identically across all nine languages.

---

## 10. Schema generation (`*.docspecs-schema.yaml`)

One DocSpecs schema per document root, generated from the §6 tree:

1. **Schema id/version**: kebab-case `@Document` name + model `major.minor`,
   matching the md header.
2. **`section-types:`** — one type per distinct section-bearing class, named
   by its section id lower-cased. Per type: `prefix:` (exact id;
   list-element types use the pattern stem), `pattern-check-id:` for element
   types (`xxx` → `[0-9]+`), `subsection-types:` with `min-count`/`max-count`
   from `@Min`/`@Max`, `format: <id>-form` for `@Form` classes,
   `text-required`/`min-text-length`/`max-text-length` from
   `@TextRequired`/`@MinLength`/`@MaxLength`, `description:` from
   `@ContentHelp` or the docComment, `validation-prompt:` from
   `@ValidationPrompt`.
3. **List containers get their own section type**: a `List<T>` field emits
   **two** types — the item type *and* a container type named by the `-LST`
   id lower-cased, with `min-text-length: 0` / `max-text-length: 0`
   (always-empty body), `subsection-types:` exactly the item type
   (`min-count` from `@Min`, `max-count` `infinite`/`@Max`). The owner
   references the *container* (`max-count: 1`). Container prefixes order
   longest-first so `GOAL-ITEM-LST` resolves before `GOAL-ITEM-1`.
4. **`form-types:`** — one per `@Form` class (`<id>-form`), fields in `@Form`
   order with `fieldname:`, `required:`, `pattern-check:`; `hint` → field
   `description`.
5. **`document:`** — the root type, required top-level sections (`@Min` ≥ 1),
   title format `# <!--[<ROOT-ID>]--> <name>`.
6. `@Unused` nodes are omitted entirely.
7. Output: each facade's
   `schemas/<schema-id>/<schema-id>.<ver>.docspecs-schema.yaml`; must be
   parseable by the existing DocSpecs schema consumer (`tom_doc_specs`).

Because md item identity for anonymous items is positional, and stored ids are
runtime-validated (§3.3), every facade-authored document validates against its
own schema regardless of stored ids. *(YRD3 note: once stored ids render in
md, schema validation of a stored-id heading follows the runtime's
list-scoped rules; the schema `pattern-check-id` remains `[0-9]+` for
anonymous items — the exact reconciliation is fixed by the Dart reference in
YRD3 and this section amended to match.)*

---

## 11. Embedded per-runtime docspecs parse/validate API

Each runtime ships one consolidated module that can, without any external
tool:

1. **Parse** any DocSpecs `*.md` (§8 format) into a generic in-memory document
   (section tree with ids, titles, levels, content, form fields) — no schema
   or metadata tree needed.
2. **Validate** a parsed document against a generated `docspecs-schema.yaml`,
   producing a structured violation list.
3. **Bind** a parsed document onto the SOM metadata tree, yielding staged
   values by path (the §8.7 `parse` entry point).

Scope: a consolidated clean design, **not** a port of `tom_doc_scanner` /
`tom_doc_specs` internals (those packages are not touched by SOM work; their
own arbitrary-nesting upgrade landed with YRD2). Supported schema features are exactly
what §10 can generate; unsupported features load ignored plus a `warnings`
list. `@Reference` sections parse as ordinary content sections (the id-string
stored verbatim, never dereferenced).

Violation structure (uniform across the nine languages):

```
Violation
  rule      unknownSection | missingRequiredSection | idPatternMismatch |
            tooFewItems | tooManyItems | missingRequiredField |
            fieldPatternMismatch | textRequired | textLengthOut |
            formatMismatch | malformedHeading
  sectionId String?
  path      String?
  line      Int (1-based)
  message   String
```

`validate` returns the full list (never fail-fast); a document is valid iff
the list is empty. The Dart implementation's rule/section/line triples are the
golden reference.

---

## 12. Cross-cutting requirements and structural invariants

**Cross-cutting** (enforced by the conformance golden harness):

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

**Structural invariants** (enforced by
`tom_specs_clitool/lib/src/validator.dart`, exported as
`validateStructuralInvariants()`):

- `@SectionId` global uniqueness (class-level namespace).
- `@SectionIdPattern` uniqueness / container-id pairing (§3.1).
- `@SectionId` coverage — every reachable class carries one (transitive
  `@SectionIdPattern` subtrees exempt).
- `@DetailedIn` requires an ancestor `@MapsTo`.
- `@SecondLevelSectionId` implies `@DetailedIn`.
- Per-`@Document` detail-count budget (7–15 top-level entries).
- §2.1 field-shape legality; `@ContentType` compatibility; cycle detection.

---

## 13. Implementation status register

The decided-but-unimplemented parts of this document, by quest todo
(`_ai/quests/tom_specs/todos.tom_specs.todo.yaml`):

| Todo | Scope | Sections here |
| --- | --- | --- |
| **YRD3** | Universal stored headline + id, full md/yaml round-trip in all 9 runtimes | §1.1, §3.3, §4, §8.5–§8.7, §9.2/§9.3.6, §10 |
| **YRD4** | `@Headline` annotation defaults | §4.2, §5, §6.1 |
| **YRD5** | `DocSpecsSection` base class replaces `String`; `DocSpecsForm` | §2.2 |
| **YRD6** | `TitleField` / `IdField` form-field roles | §4.4, §6.1, §8.4.6 |
| **YRD7** | Typed form-field members + generic meta-model modification API, 9 runtimes | §7.1, §7.2 |
| **YRD8** | Conformance consistency pass (corpus, golden, shared sample, this doc's regeneration checks) | §9.7, §12 |
| **YRD9** | Editor strict mode | §4.5 |

Everything not listed above describes implemented behaviour (Dart reference;
ports per the conformance harness).

---

## 14. Provenance and reconciliation notes

Consolidated 2026-07-16 (quest todo YRD1) from the three superseded documents
plus the fixated decisions. Staleness corrected during consolidation:

1. `som_file_mapping.md`'s status note ("the md emitter and schema generator
   do not yet emit the `*-LST` container — DRA1–DRA9 pending") was **stale**:
   the container heading is emitted and parsed (verified against
   `spec_document_markdown.dart` and the conformance sample).
2. The outliner doc §7.3's "zero-padded counter" (`EXTSY-SYST-001`) was
   **wrong**: item numbering is plain 1-based (`EXTSY-SYST-1`), per the DR1
   format spec and the implementation.
3. DR1's DRC5 rule and §1.2.1 "loss 3" (md never surfaces stored list-item
   ids) and the parse-side heading-title discard are **retired** as bugs by
   the headline/id storage decisions (YRD3); this document describes the
   decided target state with the current behaviour noted inline.
4. `comments_annotations_rules.md` predates the current id scheme (it uses
   hierarchical `[SBP-XXX-YYY]` ids, `-nn`/`-xx` patterns, and "entry classes
   carry no `@SectionId`") — it documents the one-time derivation campaign and
   is historical, not normative.

Format history inherited from DR1: v1 2026-07-07 (initial normative version);
2026-07-14 DRC3 (uncapped depth, transparency, rejection reasons), DRC5
(positional md list identity — now retired by YRD3), DRC6 (YAML 1.1/1.2
plain-scalar guard).
