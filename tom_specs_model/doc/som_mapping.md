# TomSpecs Mapping — Object Model ↔ SOM Classes ↔ DocSpecs md/yaml

**Status:** Normative. This is the **single authority** for how the
`tom_specs_model` object model is mapped to the SOM classes — the generated
concrete (editing) classes, the runtime access classes, and the meta-data
classes — including the md/yaml serialization of every construct, schema
generation, and the embedded validator.

The **model-authoring rules** — the universal section structure, legal member
shapes, field classification, section identity, headlines, the annotation
vocabulary, and the structural invariants — are stated in
`tom_specs_model_rules.md`, which is the authority for how to write a class in
`tom_specs_model`. This document maps that model outwards.

**Design authority.** This document is where the **decided target state** is
fixated for the mapping surfaces. Parts that are not yet implemented are marked
with a status tag:

| Tag | Meaning |
| --- | --- |
| *(implemented)* | Matches the current code (Dart reference + ports where stated). |
| *(DECIDED — YRDn)* | Fixated design, implementation tracked by the named quest todo in `_ai/quests/tom_specs/todos.tom_specs.todo.yaml`. Until the todo lands, the code follows the "current behaviour" noted alongside. |

Where this document is silent, the Dart reference implementation
(`tom_som_dart_runtime`, `tom_specs_clitool`) is the tiebreaker and this
document must be amended to match it in the same change.

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
  extra             [(annotation, args)]   all remaining annotations
  children          [MetaNode]  in @SerializationOrder order
  elementNode       MetaNode?   for kind == list: the element class subtree

FormMeta
  fields: [(name, typeName, hint, order)]   # no titleField/idField — YRD6 reversed

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
format** *(IMPLEMENTED — YRD3)*: it fully serializes **and** deserializes all
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
  headline (stored > `@Headline` default > derived,
  `tom_specs_model_rules.md` §8).
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
- **`codeSpec` forward link (`tom_specs_model_rules.md` §5.2):** a section carrying a non-empty
  `codeSpec` list rides in the **same headline comment** as one quoted
  `key=value` field between the id bracket and the closing `-->`:

  ```markdown
  ### <!--[IMO-014] codeSpec="CsOrder,CsOrder.total,CsOrderRepository"--> Order entity
  ```

  The comment grammar is therefore **three groups** —
  `<!--[<id>]<key=value region>--> <title>` — where the middle region is a
  possibly-empty run of key=value pairs (mirroring the tom_doc_scanner
  key=value grammar; today `codeSpec` is the only key). The emitter writes it
  double-quoted as ` codeSpec="a,b,c"` immediately after the id bracket; the
  parser accepts double-quoted, single-quoted, or bare (comma/whitespace-free)
  values. The list is comma-separated with no spaces. Like a stored headline it
  is **sparse** — staged only when present, so untouched documents stay
  byte-stable. See `codespecs_mapping.md` §9.2.

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
6. *(YRD6 — reversed)*: no form field carries the section title or id; the
   heading text and the id comment are the sole storage for those values, so a
   form line can never restate them (`tom_specs_model_rules.md` §8 rule 4).
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
  list), Title-Case member name as default title, **empty body**
  (`tom_specs_model_rules.md` §7.5).
- Item heading id: the item's **stored id** when one exists *(IMPLEMENTED — YRD3)*,
  else the positional pattern id (`GOAL-ITEM-<n>`, 1-based). Item heading
  title: stored headline, else `<ElementTitle> <seq>`
  (`tom_specs_model_rules.md` §8 rule 3).
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
   md" loss is reversed by YRD3 (`tom_specs_model_rules.md` §7.6).

### 8.7 Parsing

`parse(md, metadataTree)` returns staged values keyed by runtime path plus a
rejection list: `unknownSection`, `kindMismatch`, `orphanContent`,
`missingValue`, `malformedHeading`. Nothing is silently dropped.
`emit(parse(emit(doc)))` is byte-identical (modulo the idempotent blank-line
collapse and the §8.6 transparency canonicalisations). Stored headlines are
staged only when they differ from the effective default, keeping untouched
documents byte-stable *(IMPLEMENTED — YRD3)*.

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
| Stored headline | literal key `headline`, emitted **first** in its section/form/list-item mapping (IMPLEMENTED — YRD3) | `headline` |
| Stored `codeSpec` (`tom_specs_model_rules.md` §5.2) | literal key `codeSpec`, the comma-joined code-location list, emitted right after `headline` in its mapping (§9.3.6) | `codeSpec` |

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
6. Stored list-item ids, stored headlines, and stored `codeSpec` links persist
   here losslessly (yaml has always carried stored item ids; stored headlines
   are IMPLEMENTED — YRD3; `codeSpec` follows the same shape). A section whose
   value would otherwise be a plain scalar (a content leaf, or a scalar-keyed
   field) but which carries a stored headline **and/or** a stored `codeSpec`
   is emitted as a **`{headline?: …, codeSpec?: …, content?: …}` mapping**
   instead of the bare scalar (at least one of the optional keys present);
   decoders accept both shapes. `codeSpec`'s value is the same comma-joined
   code-location list as the md form (§8.2). Collision guards are errors: a
   model child key literally named `headline` or `codeSpec`, a form field of
   that name, or a list-item key of that name all refuse to serialize.

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
   types (`xxx` → `.+`, YRD3), `subsection-types:` with `min-count`/`max-count`
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

*(IMPLEMENTED — YRD3 reconciliation, fixed by the Dart reference)*: because
stored ids now render in md (`tom_specs_model_rules.md` §7.6), the generated `pattern-check-id` compiles
`@SectionIdPattern` `xxx` to **`.+`** — a *stem check* (`^GOAL-ITEM-.+$`),
mirroring the md parser's pattern matcher. Numbering of anonymous items and
list-scoped id uniqueness are **runtime-owned**, not schema-owned. Every
facade-authored document — anonymous positional ids, AA1 date-lettered ids,
or explicit overrides — therefore validates against its own schema; only an
id that drops the pattern stem is an `idPatternMismatch`.

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

## 13. Implementation status register

The decided-but-unimplemented parts of this document, by quest todo
(`_ai/quests/tom_specs/todos.tom_specs.todo.yaml`):

| Todo | Scope | Sections here |
| --- | --- | --- |
| **YRD4** | `@Headline` annotation defaults | §4.2, §5, §6.1 |
| **YRD5** | `DocSpecsSection` base class replaces `String`; `DocSpecsForm` | §2.2 |
| **YRD6** | *Reversed* — title/id form-field roles withdrawn; heading + `@SectionId` are the sole title/id, never a form field (dsa1 removed the model usage) | §4.4, §8.4.6 |
| **YRD7** | Typed form-field members + generic meta-model modification API, 9 runtimes | §7.1, §7.2 |
| **YRD8** | Conformance consistency pass (corpus, golden, shared sample, this doc's regeneration checks) | §9.7, §12 |
| **YRD9** | Editor strict mode | §4.5 |

Everything not listed above describes implemented behaviour (Dart reference;
ports per the conformance harness). YRD3 (universal stored headline + id,
full md/yaml round-trip, §1.1/§3.3/§4/§8.5–§8.7/§9.2/§9.3.6/§10) was
implemented 2026-07-16 across all nine runtimes, including the schema
`pattern-check-id` stem-check reconciliation. **YRD10** (wrapper audit against
the §1 list-as-outer-section rule, §2.6) was completed 2026-07-18: the census
and collapse codemods confirm zero collapsible pure single-list wrappers and
the validator emits zero `§6.1c collapsible-wrapper` warnings — the model is at
steady state, no collapse required. The **`codeSpec` forward link** (§2.2 member,
§8.2 md headline-comment field, §9.2/§9.3.6 yaml key) is likewise implemented:
the concrete `codeSpec` member and its Dart-reference md/yaml codec landed with
quest todo csmb1, and the codec was ported to the eight non-Dart runtimes with
FORMAT 8 golden-log parity by csmc8 (2026-07-20).

---

## 14. Provenance and reconciliation notes

Corrections carried over from the superseded sources this document consolidates:

1. The outliner doc §7.3's "zero-padded counter" (`EXTSY-SYST-001`) was
   **wrong**: item numbering is plain 1-based (`EXTSY-SYST-1`), per the DR1
   format spec and the implementation.
2. DR1's DRC5 rule and §1.2.1 "loss 3" (md never surfaces stored list-item
   ids) and the parse-side heading-title discard are **retired** as bugs by
   the headline/id storage decisions (YRD3); this document describes the
   decided target state with the current behaviour noted inline.

Format history inherited from DR1: v1 2026-07-07 (initial normative version);
2026-07-14 DRC3 (uncapped depth, transparency, rejection reasons), DRC5
(positional md list identity — now retired by YRD3), DRC6 (YAML 1.1/1.2
plain-scalar guard).
