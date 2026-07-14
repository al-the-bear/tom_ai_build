# SOM file mapping — object model ↔ `*.docspecs.yaml` ↔ `*.md`

How the annotated Dart classes in **`tom_specs_model`** map, member by member,
onto the two on-disk DocSpecs representations produced by every `tom_som_*`
runtime:

- the hierarchical **`*.docspecs.yaml`** (canonical machine form), and
- the strict-DocSpecs **`*.md`** (human-authorable form).

This document is the cross-language *contract*: all nine runtime ports
(Dart reference + Python, JS, TS, Go, Java, Rust, C, C++) must produce
byte-identical output for the same model. It is the model-centric companion to
the format spec `_ai/quests/tom_specs/som_document_formats_redesign.md` (the
"redesign doc", cited by section number below) and the model-design rules in
`tom_specs_model/doc/specs_model_outliner.md` (the "outliner doc").

> **Status note (2026-07-14).** The **object model** and the **`*.yaml`**
> emitter already implement the mapping described here in full. The **`*.md`**
> emitter and the **schema generator** do **not** yet emit the `*-LST` list
> *container* section — they currently hoist list items directly under the
> owning section (redesign doc §1.2/§1.5/§1.6/§5). Aligning them is a
> cross-language refactoring tracked by quest todos **DRA1–DRA9**. The rule
> stated in §4 below is the **target** contract.

---

## 1. The object model is a section tree

A TomSpecs document *is* a class instance graph. One `@Document` root class is
the top-level document section; each reachable class is a section; each member
is either the section's own content, a child section, or a list of child
sections. Serialization — to `*.yaml` or `*.md` — is a single depth-first walk
of that tree in **`@SerializationOrder`** order.

Every section carries a **section id** (the machine-readable identity used as
the YAML key and the md `<!--[id]-->` headline comment). The id comes from an
`@SectionId` annotation — class-level for singleton sections, field-level (the
`-LST` container id) for list sections. The section *title* (md heading text,
never persisted as identity) is derived from the member name in Title Case.

---

## 2. Member kinds and their annotations

Members are read from `tom_specs_core` annotations. The relevant ones:

| Annotation | Applies to | Meaning in the mapping |
|---|---|---|
| `@Document(name, basedOn:)` | root class | Marks the top-level document section; supplies the schema id (kebab-case `name`) and `major.minor` version. |
| `@SectionId(id)` | class **or** `List<T>` field | Class-level: the section's global id. Field-level: the list **container** id, pattern `<elementId>-<FIELDSUFFIX>-LST`. |
| `@SectionIdPattern(pattern)` | `List<T>` field | The per-item numbering template, `<elementId>-<FIELDSUFFIX>-xxx`; mirrors the container id with `-LST`→`-xxx`. |
| `@Form(...)` / `@ContentType('form', …)` | class | The class is a *form* section: its scalar fields serialize as `FieldName: value` lines rather than as sub-sections. |
| `@ContentType(type, description)` | `content` field | Declares the content medium (`markdown`, `sql`, `dart`, …). Non-`form` content types forbid sibling scalar fields. |
| `@ContentHelp(text)` | member | Authoring help; becomes the schema section/field `description`. |
| `@Min(n)` / `@Max(n)` | `List<T>` field | Item count bounds → schema `min-count`/`max-count`. |
| `@Unused()` | class/section | Structural container only; **omitted from the schema**, but still walked for layout. |
| `@MapsTo` / `@DetailedIn` / `@SecondLevelSectionId` | member | Traceability metadata; carried in the metadata tree, not part of the file body. |
| `@SerializationOrder` (implicit member order) | members | Sibling emission order in both formats. |

The single `content` field (type `String?`, present on nearly every class) is
**the section's own text** — everything between the section's heading and its
first sub-section (outliner doc §4.6). It is *not* a sub-section.

---

## 3. The three member shapes

Walking a class in serialization order, each member is exactly one of:

1. **`String? content` (the content member).**
   The section's body text. Serialized as formatting-preserving multi-line
   text: the `content` YAML key (redesign doc §2.2/§2.4) / the prose directly
   under the md heading (redesign doc §1.3). `@Form` classes replace the free
   content with `FieldName: value` lines (redesign doc §1.4). This is always
   emitted **above** any child sections.

2. **A singleton complex member (`Foo field;`).**
   One child **section**. Recurse into `Foo`'s class, whose `@SectionId`
   becomes the child section id. One nesting level deeper in both formats.

3. **A list member (`List<Foo> field;`).**
   A **two-level** section hierarchy (see §4). *Never* a `List<String>` /
   `List<scalar>` — list elements must be complex types (outliner doc §6.1).

---

## 4. List mapping — the `*-LST` container is a real section (target rule)

A `List<Foo> field` annotated `@SectionId('FOO-FLD-LST')` +
`@SectionIdPattern('FOO-FLD-xxx')` maps to **two** nesting levels:

```
<owning section>
└── FOO-FLD-LST         ← the list CONTAINER section (one per list field)
    ├── FOO-FLD-1       ← item 0, a full Foo sub-tree (@SectionIdPattern, 1-based)
    ├── FOO-FLD-2       ← item 1
    └── …
```

- The **container** (`-LST`) groups the whole list. It exists because *a list
  is a distinct document section that must have its own id* (outliner doc
  §7.2). Its id is field-suffixed so two list fields of the same element type
  in one class stay distinct (`inScopeProcesses` → `PRSCEN-INSC-LST`,
  `outOfProcesses` → `PRSCEN-OUTO-LST`).
- Each **item** is a sub-section of the container, numbered from the
  `@SectionIdPattern` with a 1-based counter (`FOO-FLD-xxx` → `FOO-FLD-1`),
  and expanded by recursing into `Foo`.
- **The container has no content of its own** — the object model has no member
  for it. In the generated schema this is expressed as content
  **min-length 0 and max-length 0** (an always-empty body), so a hand-authored
  document that puts prose on the `-LST` heading fails validation.

### 4.1 `*.docspecs.yaml`

The container is the YAML key `<container-id> <fieldName>`; items nest beneath
it keyed by their resolved id (redesign doc §2.2, key form
`GOAL-ITEM-LST entries`). Already implemented:

```yaml
GOALS:                       # owning section
  GOAL-ITEM-LST goals:       # the -LST container, key = "<id> <fieldName>"
    GOAL-ITEM-1:             # item 0
      content: |2-
        Cut confirmation time below five minutes.
    GOAL-ITEM-2:
      content: |2-
        Remove the nightly batch window.
```

Content is emitted as a formatting-preserving `|2-` block scalar (JSON-string
fallback when a value would not survive as a block), keyed by the section id.

### 4.2 `*.md`

The container becomes its **own heading**, one level above the items:

```markdown
## <!--[GOALS]--> Goals

### <!--[GOAL-ITEM-LST]--> Goals

#### <!--[GOAL-ITEM-1]--> Goal 1

Cut confirmation time below five minutes.

#### <!--[GOAL-ITEM-2]--> Goal 2

Remove the nightly batch window.
```

The `-LST` heading carries no body (§4, content-length 0). Item heading titles
are `<ElementTitle> <seq>` (Title-Case element class name, trailing `Entry`
dropped; redesign doc §1.5).

> **Current md output (to be fixed by DRA):** the `<!--[GOAL-ITEM-LST]-->`
> heading is omitted and `GOAL-ITEM-1`/`-2` sit directly under `GOALS`
> (redesign doc §1.2 as originally written). The internal runtime path already
> routes through the `-LST` segment (the list meta node's path segment *is* its
> `-LST` section id), so this is a heading emit/parse + schema change, not a
> path/JSON change.

---

## 5. Schema generation (`*.docspecs-schema.yaml`)

DR3 generates one DocSpecs schema per `@Document` root (redesign doc §5). Under
the target rule each list field contributes **two** `section-types`:

- the **container** type (`goal-item-lst`), `prefix:` the `-LST` id,
  `min-text-length: 0` / `max-text-length: 0`, `subsection-types:` the single
  element pattern type with `min-count`/`max-count` from `@Min`/`@Max`;
- the **element** type (`goal-item`), `prefix:` the `-xxx` stem,
  `pattern-check-id:` the `@SectionIdPattern` with `xxx`→`[0-9]+`.

`@Unused` sections are omitted; `@Form` classes emit a `form-types` entry.

> **Current schema output (to be fixed by DRA):** the generator emits only the
> element pattern type as a direct `subsection-type` of the owning section and
> omits the `-LST` container type entirely (redesign doc §5.1 example:
> `goal → goal-item`).

---

## 6. Round-trip contract

For every runtime: `emit(parse(emit(doc)))` is byte-identical (modulo the
idempotent blank-line collapse), and the shared sample
`samples/meridian_order_management.*` round-trips and validates against
`tom_som_dart_v0/schemas/solution-blueprint/solution-blueprint.1.0
.docspecs-schema.yaml` with zero violations. The `*-LST` container level must
survive that round-trip identically in md, yaml, and schema across all nine
languages.

---

## 7. Cross-references

- Format spec: `_ai/quests/tom_specs/som_document_formats_redesign.md`
  (§1 md, §2 yaml, §3 metadata tree, §5 schema, §6 validator).
- Model-design rules: `tom_specs_model/doc/specs_model_outliner.md`
  (§4 notation, §6 model rules, §7 annotations incl. §7.2/§7.3 `-LST`/`-xxx`).
- Refactoring todos: quest `tom_specs`, ids **DRA1–DRA9**.
