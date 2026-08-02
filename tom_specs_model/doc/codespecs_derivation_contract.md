# CodeSpecs Derivation Contract

**Quest:** tom_specs · **Status:** normative for the Phase-4 generator

**Authority for: what code comes out.** `codespecs_mapping.md` §8 gives the
derivation *map* — which SOM section feeds which CodeSpecs part. This document
gives the derivation *contract*: for every active `Cs*` annotation, the exact
Dart a generator emits, argument by argument, name by name, file by file.

It is the last specification piece before Phase 4 (CodeSpecs generation) can be
implemented. Everything here is normative for the generator; where it decides
something `codespecs_mapping.md` had left open, that document cites this one
rather than restating it.

**Scope.** One contract entry per active `Cs*` part marker — **39 markers**,
plus the two facet value classes a marker carries (`CsFileReference` on
`CsColumn`, `CsGradedAccess` on `CsAuthorize`), for **41 classes** in
`tom_code_specs`. Deferred parts (§4.3) have no marker and therefore no entry.

**What this document decides.** It **decides** each annotation's argument shape.
The shapes below are **authored** in `tom_code_specs` — the constructors, the
`Cs*Ref` typed-reference family the arguments consume
(`lib/src/annotations/cross_part_refs.dart`) and the 15 closed catalogues they
select from (`lib/src/annotations/vocabulary.dart`) — so every annotation call
written to this contract compiles.

**Citing.** Sections of `som_multiplatform_spec_model.md` are cited as `SOM §N`;
everything else by file name plus section — `codespecs_mapping.md §5.13`,
`tom_specs_model_rules.md §6.1`. A bare `§N` in this document refers to *this*
document.

---

## 1. How to read a contract entry

Every entry answers the same seven points, in the same order.

| # | Point | Answers |
|---|-------|---------|
| **1** | **Input** | Which SOM class (and `@SectionId`) feeds generation, selected by `@CodeSpecKind`, and which of its fields/subsections are consumed. |
| **2** | **Output shape** | The exact Dart emitted: the declaration, its `tom_core`-family superclass or instantiated type (§1.1 pillar b — always named), its members, and the `Cs*` annotation with every argument filled. |
| **3** | **Argument derivation** | Per annotation argument: which SOM field supplies it and how it is transformed — verbatim, slugified, enum-mapped or defaulted. |
| **4** | **Naming** | How the Dart identifier derives from the SOM headline or id, on top of the universal rules of §2. |
| **5** | **Locus** | Which of the three §4.2 projects the file lands in. |
| **6** | **Cross-references** | Which outgoing reference edges the element emits, and which `Cs*Ref` type carries each. |
| **7** | **Back-link** | The `@DocSpec([DocRef(sectionId, description), …])` emitted on the element (`codespecs_mapping.md` §9.3). |

Entries are grouped by **generation slice** (`codespecs_mapping.md` §4.4.3), so
reading top to bottom is reading the order a generator emits in: nothing in an
entry references a part that has not already been emitted by an earlier entry.

---

## 2. Universal rules

These hold for every entry. An entry states only what it adds or overrides.

### 2.1 Identifier derivation (deterministic naming)

The same spec must produce the same code in every session, on every machine.
That requires the name to be a **pure function of the SOM content** — no
counters, no clocks, no dictionaries, no generator state.

**N1 — the source string.** Each entry names a **designated name field**: the
SOM field whose value names the thing (`DataEntityEntry.entityName`,
`InterfaceOperationEntry.operationName`, …). If the section type has no
designated name field, the source is the section's **headline text**. If both
are absent or empty, generation **fails** naming the section id — an unnamed
section is a spec defect, not a naming problem.

**N2 — tokenisation.** The source string becomes a token list:

1. Fold to ASCII: NFD-decompose, drop combining marks, map `ß` → `ss`.
2. Split on every run of characters that is neither a letter nor a digit.
3. Split each remaining run at a lower→upper boundary, and before the final
   upper of an upper-run followed by a lower (`HTTPServer` → `HTTP`, `Server`).
4. Digits stay attached to the token they follow (`address2` → `address2`).
5. Drop tokens that fold to empty.

**N3 — casing.** Each token is **lowercased in full, then its first character
uppercased**. No acronym dictionary: `ID` → `Id`, `HTTP` → `Http`. A dictionary
would be a hidden, mutable generator input and would break N-determinism the
first time someone edited it.

- **PascalCase** = the cased tokens concatenated.
- **camelCase** = PascalCase with its first character lowercased.
- **snake_case** = the lowercased tokens joined by `_` (used for file names only).

**N4 — collisions fail.** If two sections produce the same identifier in the same
locus project, generation **fails** naming both section ids. It never
auto-suffixes: a silent `Customer2` hides the spec defect that produced it, and
§4.4 already rejects the analogous shortcut for stubs.

**N5 — authored keys are verbatim.** Message keys, error codes, setting keys,
route ids, notification type ids and operation names are **authored strings**
taken **character-for-character** from the SOM. They are not derived and not
normalised — they are the §5.23 string-reference exemptions plus the operation
name (§5.14: the one required identifier). An absent authored key is a
generation error. The Dart *const* holding such a key is named by applying N2/N3
to the key itself: `order.shipped` → `orderShipped`.

**N6 — reserved words and leading digits.** If the identifier is a Dart reserved
word, the part's **canonical id** (§4.1, PascalCase) is appended:
`class` as an entity → `ClassDataAccess`. If it begins with a digit, `N` (Pascal)
or `n` (camel) is prefixed: `3dView` → `N3dView`.

**N7 — file layout.** One file per top-level CodeSpec declaration:

```
lib/src/<canonical id, snake_case>/<identifier, snake_case>.dart
```

so a `DataEntityEntry` named *Customer* lands at
`lib/src/data_access/customer.dart`. Member markers are emitted in their owner's
file. Catalogue holders (error codes, message keys, roles, resource keys,
operation refs) get exactly one file per catalogue,
`lib/src/<canonical>/<canonical>_catalog.dart`. Each project exports its files
from `lib/<project>.dart` in the same order §2.2 emits them.

**N8 — member order.** Members are emitted in **SOM document order** — the order
the contributing sections appear in the document, depth-first. A regeneration
over an unchanged spec is byte-identical; a diff therefore means the spec moved.

**N9 — reference const strings.** A `Cs*Ref` const's string argument is the
**camelCase declaration name of its target** (N2/N3 over the target's designated
name field), with two exceptions. Where the target is identified by an authored
key (N5) it is that key verbatim. Where the target is a **member** of another
declaration rather than a declaration in its own right, it is the dotted
`<owner>.<member>` path — the qualifiable `CsElementRef` of §2.6 is the one ref
in the family that has such targets, and `CsElementRef.path` composes it. A
generation-time validator resolves every ref string to a declaration; an
unresolved ref is a generation error, never a warning.

### 2.2 Locus assignment

Locus is not per-entry judgement — it is read off `codespecs_mapping.md` §4.2 by
part, and an entry's point 5 cites it rather than re-deciding it. Three parts
span two projects (CE-UP shape/persistence, CE-ID declaration/population, CE-AU
wire types/client flow/server flow); each has one entry per locus half, and the
entry says which half it is.

The **shared → {client, server}** dependency arrow is absolute. A generator that
would have to emit a client-project reference from a shared file has hit a spec
defect; it fails naming the offending section rather than relaxing the arrow.

### 2.3 What becomes an annotation argument

The one rule that shapes all 39 constructors:

> A spec-authorable attribute becomes a **constructor argument of the `Cs*`
> annotation if and only if the generated Dart cannot already carry it.**

Applied as three tests, in order — the first that matches wins:

**(a) Carried by the declaration.** The Dart declaration itself already states
it: a column's value type, a form's field list, a view model's fields, a
repository's entity and key type, a service unit's methods, a validation
function's signature. Not an argument. Duplicating it would create two sources
that can disagree.

**(b) Carried by a substrate constructor.** The CodeSpec instantiates or extends
a `tom_core`-family class whose constructor already takes it —
`TomNotificationType(typeId:, urgency:, defaultChannelIds:)`,
`TomReportColumn(...)`, `TomActionTrigger(guard:)`, `@TomAudited(enabled:,
includeReads:, redact:)`. Not an argument; the marker only says *which part*
this is. This is pillar (b) doing its job: reuse means the substrate holds the
data.

**(c) Otherwise — an annotation argument.** What is left is exactly §4.1.1's
"beyond what simple code can express": element kinds, maximum lengths, format
restrictions, placement, schedules, grades, physical table and column names,
setting keys, operation names, closed-catalogue selections.

Two shaping rules on top:

- **Required vs. defaulted.** An argument is `required` iff omitting it cannot be
  given a **fail-safe** default (§5.16's rule: broadening a value's blast radius
  must be a deliberate authored act). The two shipped precedents —
  `CsTrigger.kind` and `CsIdentityAttribute.placement` — are required for exactly
  this reason. Everything else defaults to its safest arm.
- **`String? note` is last, always.** Every marker keeps the optional
  part-specific note it has today, as its final parameter.
- **First positional = the authored identifier.** Where a part has an authored
  external identifier (§2.1 N5), it is the annotation's **first positional
  required** argument: `@CsEndpoint('customer.save')`, `@CsTable('customer')`.
  Everything else is named.

**Closed catalogues are mirrored enums.** `tom_code_specs` is annotations-only
and does **not** depend on `tom_core` (§9.5). So a closed catalogue a marker
selects from is declared **in `tom_code_specs`**, mirroring its `tom_core`
counterpart one-for-one where one exists (`CsErrorSeverity` ↔
`TomErrorSeverity`). A named validator check asserts the mirror is complete; a
`tom_core` catalogue that grows without its mirror growing is a build failure,
not a silent divergence.

**Per-kind argument slots.** Two markers select a kind and then carry that kind's
own attributes (`CsTrigger`, `CsAuthorize`). Dart annotations have no sum types,
so each kind's attributes are **separate optional arguments**, and a validator
asserts that only the slots belonging to the declared kind are non-null. This is
the annotation-level rendering of §8.2's `@OneOf`/`@Case` closed-choice design.

### 2.4 Stub bodies — skeletal, not executable

Phase 4 output **compiles and does not execute**. Per §4.1.1's coding-form
spectrum:

- **Forms 1 and 2** (framework subclass/instantiation, plain annotated model
  class) emit **no bodies at all**. Fields are declarations; a non-nullable field
  with no authored default is `late final`.
- **Form 3** (compilable pseudo-code) emits, as the *entire* body of every
  method:

  ```dart
  throw UnsupportedError('<explication>');
  ```

  `<explication>` is the contributing SOM section's description text,
  whitespace-collapsed to one line with `'` and `$` escaped. **An empty
  description is a generation error** — a body with no explication is an empty
  spec, and emitting one would let a hollow method pass as a specified one.
- **Form 4** (annotation-only modifier) emits no declaration of its own.

Three invariants make "compiles but does not execute" checkable rather than
aspirational:

1. **Real signatures.** Return types, parameter types and generics are the
   specified ones. Nothing is `dynamic` because the generator did not know.
2. **No fabricated values.** A stub never `return`s — no `null`, no `''`, no
   `const []`. The only exit is the `throw`.
3. **Async is declared, not faked.** An asynchronous operation declares
   `Future<T>` / `Stream<T>` and still throws; it is never `async` with a
   synthetic completed future.

CE-ST observable fields are the sole exception to (1)–(2)'s "no initialiser"
reading: `final TomString name = TomString('');` *is* the declaration — the
observable's identity is what the spec states, and an uninitialised observable
would not compile at its use sites.

### 2.5 Back-links — `@DocSpec` and `@CodeSpec`

Every generated top-level declaration, and every generated member that came from
a SOM section of its own, carries **both** code-side annotations. They are not
redundant; they answer different questions:

| Annotation | Carries | Used for |
|------------|---------|----------|
| `@CodeSpec('<canonical id>.<identifier>', source: [<section ids>])` | The element's stable CodeSpec id and the **flat set** of sections that fed it | §8's gap analysis as a set-difference over section ids |
| `@DocSpec([DocRef('<sectionId>', '<description>'), …])` | One tuple **per contributing section**, explaining what the code took from it | §9.3's reverse link, read by a human |

**Emission rules.**

1. One `DocRef` per contributing section, in the order the sections were
   consumed (which is N8's order).
2. `sectionId` is the SOM `@SectionId` **verbatim**.
3. `description` is one sentence stating *what the code takes from that section*,
   generated from the per-entry template in each entry's point 7. It describes the
   **edge**, not the section — "supplies the operation name and request type", not
   "the interface operation entry".
4. **`@CodeSpec.source` must equal the set of `sectionId`s in `@DocSpec`.** A
   named validator check enforces it; drift between the two is otherwise
   undetectable and would silently corrupt the set-difference gap analysis.
5. A member that adds no section of its own (a derived back-reference, a
   materialised ownership list) carries neither — it is covered by its owner's.

### 2.6 Cross-references — which type carries which edge

Reference edges use the typed `Cs*Ref` family of `codespecs_mapping.md` §5.23 —
never id strings. The thirteen types and their edges:

| Ref type | Points at | Declared in |
|----------|-----------|-------------|
| `CsOperationRef` | a CE-API operation | shared |
| `CsMessageKey` | a CE-TX message key | shared |
| `CsErrorCode` | a CE-ER error code | shared |
| `CsRoleRef` | a CE-AZ role | shared |
| `CsResourceKeyRef` | a CE-AZ resource key | shared |
| `CsCallRef` | a CE-SC server call | client |
| `CsActionRef` | a CE-AC action | client |
| `CsRouteRef` | a CE-NV route | client |
| `CsElementRef` | a CE-EL screen element | client |
| `CsFormRef` | a CE-FM form | client |
| `CsServiceUnitRef` | a CE-SU unit | server |
| `CsReportRef` | a CE-RP report | server |
| `CsJobRef` | a CE-JB job | server |

**Entities and request/response DTOs are already Dart types** — they are
referenced by `Type` literal (`rootAggregate: Customer`), with no ref const, per
§5.23.

**`CsElementRef` is the one qualifiable ref.** CE-EL's closed catalogue has both
standalone kinds (*Button*, *MenuEntry*, *Label*, *FormHost*), which are
class-level targets, and form-member kinds (*TextInput*, *Number*, *Toggle*,
*DateInput*, *Choice*, *MultiChoice*, *FileInput*), which are members of the
`@CsForm` class.
One type covers both, carrying an optional `form` qualifier, because §5.1's
`@CsTrigger` takes a `CsElementRef` in **both** its element and its form-field
slot — two types could not fill one parameter. Its N9 const-string form is the
bare declaration name when standalone and the dotted `<form>.<element>` path
when it is a form member.

Declaration pattern for every ref const, unchanged from §5.23:

```dart
static const login = CsOperationRef('login');
```

### 2.7 What a generated file looks like

Every emitted file has the same five-part shape, in this order:

1. A generated-file banner naming the generator, the source document and the
   spec-model version — and **no timestamp** (a timestamp would defeat N8's
   byte-identical regeneration).
2. `library;` where the file needs a library-level doc comment.
3. Imports: `package:tom_code_specs/tom_code_specs.dart`, the `tom_core`-family
   packages the declarations are built on, and — in client/server projects only —
   `<app>_codespec_shared`.
4. The declaration, annotated `@CodeSpec` then `@DocSpec` then its `Cs*` marker,
   in that order (§9.5's placement, outermost-provenance-first).
5. Nothing else. One top-level declaration per file (N7).

---

## 3. The contract entries

Thirty-nine part markers plus one facet class, grouped by generation slice
(§4.4.3). Slice 1–2 emit into `<app>_codespec_shared`, 3–4 and 7 into
`<app>_codespec_server`, 5–6 into `<app>_codespec_client`.

**Where an entry sits.** At the slice of the declaration its marker is attached
to — not at the slice of every symbol the part emits. Two cases need the
distinction. A marker may ride hosts in two slices (`@CsAudited`, over both the
CE-DB write path and the CE-API handler); it is entered once, at the earlier, and
its Locus point names the other. And a part may emit an unmarked half in a later
slice (CE-NT delivery, CE-UP server persistence); that half has no marker, so it
has no entry, and again the Locus point carries it.

### 3.1 Slice 1 — shared const catalogues

Nothing here references another part; every `Cs*Ref` catalogue bottoms out in
this slice.

#### 3.1.1 `@CsEnum` — domain enum (member kind, not a part)

| Point | Contract |
|-------|----------|
| **1 Input** | `DomainEnumEntry` (`DMENE`) under `DOMEN`, with its child `DomainEnumValueEntry` (`DMEVA`) list. Consumed: the enum's designated name field, its description, and each value's name + description. **Value *labels* are not consumed here** — display copy for a domain-enum value is CE-TX, catalogued in the message-key registry like every other label (`codespecs_mapping.md` §1.2 consequence 1, §5.21), so it reaches code through §3.1.3, not through this entry. |
| **2 Output** | A **plain Dart `enum`** — no superclass, no `tom_core` basis; §4.1 records `domainEnum` as a *member kind*, so there is nothing to build on. Doc comments carry the descriptions. **No enhanced-enum members are emitted**: the constant's identifier *is* the value token, the display label is CE-TX copy (see point 1) and a default belongs to the enum-typed member, so the enum has no field to hold (`codespecs_mapping.md` §4.1). Emitted only into `shared` **iff** a shared contract type references it (§4.1); otherwise into the single project that does. |
| **3 Arguments** | None. `@CsEnum({String? note})` is unchanged: the enum's name and its complete value list are the declaration (test **a**). |
| **4 Naming** | Enum type = PascalCase of `DMENE`'s name field; each constant = camelCase of `DMEVA`'s name field. N6 applies per constant (`default` → `defaultDomainEnum`). |
| **5 Locus** | `shared` when any shared contract type (CE-API DTO, CE-ER, CE-RP envelope) names it; otherwise the referencing project. A domain enum referenced from **both** client and server is shared by that rule, never duplicated. |
| **6 Cross-refs** | None outgoing. Incoming edges are plain Dart type references. |
| **7 Back-link** | `@DocSpec([DocRef('DMENE', 'declares the enum and its value set')])` on the enum; per-constant refs are not emitted — N8 order plus the doc comment already identifies each `DMEVA`. |

#### 3.1.2 `@CsError` — CE-ER error code

| Point | Contract |
|-------|----------|
| **1 Input** | `ErrorCodeEntry` (`ERCEN`); the envelope shape comes from `ResultEnvelope` (`RSLTE`). Consumed per entry: the authored error code, the severity, the description. |
| **2 Output** | One **error-code catalogue holder** per document, marked `@CsError()` plain, holding one `static const CsErrorCode` member per `ERCEN`, each marked with its own `@CsError(severity: …)`. Built on `TomResult<T>` / `TomErrorResult` / `TomFieldError` / `TomErrorSeverity` (`tom_core_kernel`) — the holder is form 2, a plain annotated model class over those types. |
| **3 Arguments** | `severity` ← `ERCEN`'s severity field, **enum-mapped** onto `CsErrorSeverity {info, warning, error, fatal}`, mirroring `TomErrorSeverity` (§2.3); defaults to `error`. The **code itself is not an argument** — it is already the `CsErrorCode` const's string (test **a**). No `messageKey` argument: §5.21 keys error copy *by the error code*, so the message key is derived, not authored. |
| **4 Naming** | Holder = `<Document>ErrorCodes` (PascalCase of the document root's name + `ErrorCodes`). Member = N5 over the authored code: `order.not_found` → `orderNotFound`. |
| **5 Locus** | `shared` — §4.2 lists the error result **and** the error-code catalogue as shared. |
| **6 Cross-refs** | None outgoing. `CsErrorCode` is the incoming ref type, cited by CE-VA rules, CE-API operations and CE-NV `outcomeReference`. |
| **7 Back-link** | Per member: `@DocSpec([DocRef('ERCEN', 'supplies the error code and its severity')])`. On the holder: one `DocRef('RSLTE', 'fixes the result-envelope shape the codes are returned in')`. |

#### 3.1.3 `@CsText` — CE-TX message key

| Point | Contract |
|-------|----------|
| **1 Input** | `MessageKeyEntry` (`MSGKE`) and `ValidationMessageTemplate` (`VMT`). Consumed: message key, base copy, role, category. **Derived text is not input** — §5.21's derived source (element `basePath` + role suffix) produces **no** catalogue entry and **no** `@CsText`; only the catalogued source reaches this entry. |
| **2 Output** | One **message-key catalogue holder** per document, `@CsText`-marked members of type `CsMessageKey`. Built on `TomTextResourceProvider` (`tom_core_kernel`), which resolves the keys at runtime; the catalogue itself is form 2. |
| **3 Arguments** | `baseCopy` (**required**) ← `MSGKE`'s base copy, verbatim. `role` ← enum-mapped onto `CsTextRole {error, notification, email, report, generic}`, default `generic`. `category` ← `CsTextCategory {uiCopy, errorCopy}`, default `uiCopy`. Key not an argument (test **a** — it is the `CsMessageKey` const's string). Parameters are **not** an argument: §5.21 marks them derived, read out of the base copy's placeholders. A validator asserts `role == error ⇒ category == errorCopy`. |
| **4 Naming** | Holder = `<Document>Messages`. Member = N5 over the dotted key: `checkout.title` → `checkoutTitle`. |
| **5 Locus** | `shared` for the keys; the **copy** half (§4.4.3 slice 5) is client, and is the same catalogue read through the client's resource provider — one declaration, not two. |
| **6 Cross-refs** | None outgoing. `CsMessageKey` is the incoming ref type, cited by CE-VA error keys, CE-NT bodies, CE-RP labels and CE-JB failure alerts. |
| **7 Back-link** | `@DocSpec([DocRef('MSGKE', 'supplies the message key, its base copy and its role')])`, plus `DocRef('VMT', …)` where the key came from a validation-message template. |

### 3.2 Slice 2 — shared contract

Cites slice 1 only.

#### 3.2.1 `@CsEndpoint` — CE-API, shared half (operation catalogue + DTOs)

| Point | Contract |
|-------|----------|
| **1 Input** | `ServerOperationEntry` (`SVOPE`) under the `ServerOperationRegistry` (`SVOPR`) — the application's own operation surface. Consumed: `operationName`, and the `ServerOperationMemberEntry` (`SVOPM`) lists that make up the request and response shapes. `InterfaceOperationEntry` (`IOE`) is **not** an input here: it describes a foreign contract and carries `serverCall` only (`codespecs_mapping.md` §8.5). |
| **2 Output** | Two things in shared: (i) the **operation-ref catalogue** — one `static const CsOperationRef` per operation; (ii) the **request/response DTOs** — form-2 plain annotated model classes. The endpoint declaration itself is built on `TomApiEndpoint<R,Q>` within a `TomApi` (`tom_core_kernel`), with `R` the response type and `Q` the request type. The response type **is** `TomResult<T>` (§7); a generator that emits a bare `T` has violated the server contract. |
| **3 Arguments** | `operation` — **first positional, required** ← `SVOPE.operationName`, **verbatim** (N5). §5.14 drops the HTTP method (fixed POST) and the error-response type (5xx only) as spec inputs, and `SVOPE` authors neither, so neither is an argument. `descriptionKey` → CE-TX (not an argument); `authorizationRequirement` + its role/resource-key refs → the `@CsAuthorize` modifier. |
| **4 Naming** | Catalogue = `<Document>Operations`; member = N5 over the operation name. DTOs = PascalCase of the operation name + `Request` / `Response`. |
| **5 Locus** | `shared` (§4.2: request/response types **and** the operation-ref catalogue). The handler half is §3.4.2, server. |
| **6 Cross-refs** | Emits `CsOperationRef` consts (the edge everything else cites). A member typed by a domain enum (`SVOPM.domainEnum`) or a data entity (`SVOPM.dataEntity`) references that declaration by plain type rather than restating it. |
| **7 Back-link** | `@DocSpec([DocRef('SVOPE', 'supplies the operation name')])`, plus one `DocRef('SVOPM', …)` per member of the shape the DTO realises. |

#### 3.2.2 `@CsValidation` — CE-VA, the declaration string

| Point | Contract |
|-------|----------|
| **1 Input** | `ElementValidationRuleEntry` (`ELVARUEN`), `DataAttributeConstraintEntry` (`DATAA`), `IntegrityConstraints` (`INCO`). Consumed: which of the ten standard rules apply, and each rule's arguments. |
| **2 Output** | **No declaration of its own** for the standard rules — the marker rides the field it constrains, carrying the §5.19 declaration string. Built on `Validators` (`tom_flutter_ui`), whose named rules the string selects. A shared rule *library* class also carries a plain `@CsValidation()`. |
| **3 Arguments** | `rules` — **first positional, optional** (`''`), the §5.19 comma-separated grammar: `<name>` / `<name>:<arg>` / `<name>:<arg1>:<arg2>`, e.g. `'required, minLength:8, pattern:^[A-Z]'`. Rule names are the nine declarable tokens; `compose` is **not** declarable (§5.19) and a generator that emits it has produced an invalid string. Argument values are verbatim from the SOM constraint. Empty on a library holder. |
| **4 Naming** | No identifier — the marker sits on an existing field. A shared rule library is named `<Document>Rules`. |
| **5 Locus** | `shared` where the same rule constrains a shared DTO; otherwise `client` with the field it rides (§4.2 lists "shared CE-VA rules"). |
| **6 Cross-refs** | None from the string itself; the error key of a standard rule is derived per §5.21. |
| **7 Back-link** | `@DocSpec([DocRef('ELVARUEN', 'supplies the rule set and its arguments')])` — `DATAA` / `INCO` substituted when the constraint came from the data model. |

#### 3.2.3 `@CsFieldRule` — CE-VA, project-specific single-field rule

| Point | Contract |
|-------|----------|
| **1 Input** | `ElementValidationRuleEntry` (`ELVARUEN`) whose rule is **not** one of the ten standard rules. Consumed: the rule's description (which becomes the stub explication) and its error key. |
| **2 Output** | A standalone `Validator<T>` — `FutureOr<ValidationResult> Function(T)` (`tom_flutter_ui`) — as a **form-3** compilable pseudo-code function whose entire body is `throw UnsupportedError('<description>')` (§2.4), or a registered entry in `TomValidatorRegistry`. The typed value in / `ValidationResult` out signature is what makes it composable into a declaration string. |
| **3 Arguments** | `errorKey` (**required**) ← the SOM rule's error key, resolved to a `CsMessageKey` const by N9. Rule kind and rule arguments are **not** arguments — the function signature and body are the rule (test **a**). "Async/slow" is marked N in §5.19 and is read off the declared `Future` return type. |
| **4 Naming** | camelCase of `ELVARUEN`'s name field, suffixed `Rule` where N6 would otherwise collide with the field it validates. |
| **5 Locus** | Follows §3.2.2 — `shared` when it constrains a shared DTO, else `client`. |
| **6 Cross-refs** | `CsMessageKey` (its error key). |
| **7 Back-link** | `@DocSpec([DocRef('ELVARUEN', 'supplies the rule semantics and its error key')])`. |

#### 3.2.4 `@CsFormRule` — CE-VA, cross-field rule

| Point | Contract |
|-------|----------|
| **1 Input** | `ElementValidationRuleEntry` (`ELVARUEN`) naming **two or more** fields — the discriminator against §3.2.3. Consumed: the involved fields, the rule description, the cross-field error key. |
| **2 Output** | A **method on the `TomForm` subclass** (`tom_flutter_ui`) returning `FormValidationError?`, form 3: body `throw UnsupportedError('<description>')`. It is deliberately not expressible in the per-field declaration string — the grammar cannot name a second field — which is why the rule is authored on the form. |
| **3 Arguments** | `errorKey` (**required**) ← the cross-field error key as a `CsMessageKey`. Involved fields are **not** an argument: the method reads them, so the declaration carries them (test **a**). Per-field error keys are marked N in §5.19 — they are derived from `FormValidationError.fieldErrorKeys` at implementation time. |
| **4 Naming** | camelCase of `ELVARUEN`'s name field, prefixed `validate` when the name is not already a verb phrase — determined by N2 producing a leading token that is not in the closed verb set `{validate, check, ensure, require}`. |
| **5 Locus** | `client` — a form rule lives on the form. |
| **6 Cross-refs** | `CsMessageKey`. |
| **7 Back-link** | `@DocSpec([DocRef('ELVARUEN', 'supplies the cross-field invariant and its error key')])`. |

#### 3.2.5 `@CsIdentity` — CE-ID, the extension declaration holder

| Point | Contract |
|-------|----------|
| **1 Input** | `UserCategoryDefinition` (`USCDF`) for the holder; its `UserAttributeEntry` (`USATE`) children become members (§3.2.6). `UserLifecycleTransitionEntry` (`ULTRE`) contributes to CE-AU, not here. |
| **2 Output** | An **ordinary class** (form 2) whose members are `@CsIdentityAttribute`-marked. It is **not** a `TomUser` subclass: the principal core — `TomUser` wrapped by `TomPrincipal` (`tom_core_kernel`) — is framework-fixed and not spec input. The extension is carried as JSON via reflection into the user-profile carrier, so the typing comes from this app-authored class. |
| **3 Arguments** | None; `@CsIdentity({String? note})` unchanged. The attribute set is the class's members (test **a**). |
| **4 Naming** | PascalCase of `USCDF`'s name field + `Identity` (`Employee` → `EmployeeIdentity`). |
| **5 Locus** | `shared` — the declaration is contract, read by both sides from the token. Population is server (§3.4.4). |
| **6 Cross-refs** | None outgoing from the holder. |
| **7 Back-link** | `@DocSpec([DocRef('USCDF', 'delimits the user category whose identity extension this declares')])`. |

#### 3.2.6 `@CsIdentityAttribute` — CE-ID, one declared attribute (member marker)

| Point | Contract |
|-------|----------|
| **1 Input** | `UserAttributeEntry` (`USATE`). Consumed: name, type, placement, access guard, system of record, required. |
| **2 Output** | One **member** of the §3.2.5 holder, typed by the SOM attribute's type. Same member-marker pattern as `@CsColumn`. Carried at runtime by `TomUser.attributes` (public) or `TomPrincipal.currentContext` (encrypted) — the two carriers `tom_core`'s principal already has, so this is a placement decision, not a new mechanism. |
| **3 Arguments** | `placement` (**required**, unchanged) ← `USATE`'s placement, enum-mapped onto `IdentityAttributePlacement {public, encrypted}`; required because §5.16's fail-safe rule forbids broadening a value's blast radius by omission. **Added by this contract:** `accessKey` ← the access guard, as a `CsResourceKeyRef`; `systemOfRecord` ← the source field, verbatim; `required` ← the required flag, default `false`. The attribute's **type** stays on the member declaration (test **a**). |
| **4 Naming** | camelCase of `USATE`'s name field. |
| **5 Locus** | `shared` with its holder. |
| **6 Cross-refs** | `CsResourceKeyRef` (its access guard). |
| **7 Back-link** | `@DocSpec([DocRef('USATE', 'supplies the attribute, its placement and its access guard')])`. |

#### 3.2.7 `@CsAuth` — CE-AU, shared wire/token half

| Point | Contract |
|-------|----------|
| **1 Input** | `AuthenticationMethodEntry` (`ATME`) — **one marked declaration per entry**, which is why the marker needs no method list. `LoginFlowStepEntry` (`LGFLS`) feeds the client and server flow halves (§3.5.10, §3.4.4). |
| **2 Output** | The reused kernel wire types, declared as the app's binding: `TomServerEndpoint<TomAuthenticationMessage, TomAuthenticationResult>` plus `TomBearerAuthentication` / `TomClientJwtToken` (`tom_core_kernel`). Form 1. §5.25's six framework-fixed mechanics are **not** emitted — they are not spec input. |
| **3 Arguments** | None; `@CsAuth({String? note})` unchanged. One declaration per `ATME` means the enabled-method set is the set of declarations (test **a**), which avoids inventing a closed method catalogue the SOM does not carry. Session / token / credential policies are values on the CE-CF holder, not annotation arguments. |
| **4 Naming** | PascalCase of `ATME`'s name field + `Authentication`. |
| **5 Locus** | `shared` here; `client` for the login flow (§3.5.10); `server` for the flow and the CE-ID population (§3.4.4). |
| **6 Cross-refs** | `CsOperationRef` for the login operation. Consumes the §3.2.5 identity declaration by plain type. |
| **7 Back-link** | `@DocSpec([DocRef('ATME', 'supplies the authentication method this binding realises')])`. |

#### 3.2.8 `@CsNotification` — CE-NT notification type

| Point | Contract |
|-------|----------|
| **1 Input** | `NotificationModel` (`NM`) → `NTFTY` for types, `UNP` for user preferences. Consumed: which types exist, their urgency, their default channels, their body copy. |
| **2 Output** | A `TomNotificationType` (`tom_core_codespecs` **gap class**) const, form 1 — e.g. `TomNotificationType(typeId: 'order.shipped', urgency: high, defaultChannelIds: ['email'])`. Delivery is `TomMessage` / `TomMessageRouter` / `TomMessageOutbox` (`tom_core_server` `messaging`) and is pure reuse; the gap this marker names is *which types exist and how preferences narrow them*. |
| **3 Arguments** | `body` (**required**) ← the body copy as a `CsMessageKey` — **never inline text**, and required because a notification with no body is not a notification. Type id, urgency and default channels are all `TomNotificationType`'s own constructor parameters (test **b**), and `TomNotificationPreferences` / `TomNotificationCatalog` carry the preference narrowing. |
| **4 Naming** | camelCase of `NTFTY`'s type-id field (N5: `order.shipped` → `orderShipped`). |
| **5 Locus** | **Declaration `shared`**, this slice — the client renders the preference UI against the same catalogue the server dispatches from. **Delivery is `server` at slice 4**: channel routing and the outbox emit no marked declaration of their own, so they have no entry here, and they sit in 4 rather than 7 because the service units that raise a notification cite them. |
| **6 Cross-refs** | `CsMessageKey` (body) — the only slice-1 citation, which is why this entry sits in slice 2 with the rest of the shared contract. Channels are cited by `channelId` **string**, per §3.2.9. |
| **7 Back-link** | `@DocSpec([DocRef('NTFTY', 'supplies the notification type, its urgency and its default channels')])`, plus `UNP` where preferences narrow it. |

#### 3.2.9 `@CsNotificationChannel` — CE-NT channel

| Point | Contract |
|-------|----------|
| **1 Input** | `NotificationModel` (`NM`) → `NTFCH`. Consumed: which delivery routes the deployment declares. |
| **2 Output** | A `TomNotificationChannelDeclaration` (`tom_core_codespecs` **gap class**) const, form 1. Kept separate from §3.2.8 because the two are authored independently: the channel catalogue is a property of the *deployment*, the type catalogue a property of the *domain*. |
| **3 Arguments** | None; `@CsNotificationChannel({String? note})` unchanged. `channelId` rides the gap class's constructor (test **b**) and is the name of a `TomMessageChannel` — an **open** named value, so a deployment can declare a channel the framework never anticipated. That openness is also why no `CsChannelRef` type exists and why a type references channels by id string. |
| **4 Naming** | camelCase of the channel id. |
| **5 Locus** | Declaration `shared`, delivery `server` at slice 4 (as §3.2.8). |
| **6 Cross-refs** | None typed. The channel's **fallback edge** points at a **sibling channel** — `NTFCH` authors it as "Alternative channel if delivery fails" beside its retry policy, the two being different mechanisms: retry re-attempts *this* channel, the fallback substitutes another. It is therefore **intra-part**, which `codespecs_mapping.md` §5.23 rules a local coordinate outside the `Cs*Ref` family rather than a reference lacking a type; it stays an id string on `TomNotificationChannelDeclaration.fallbackChannelId`, and check 17 resolves it. A `Cs*Ref` could not hold it in any case: the field is on a `tom_core_codespecs` gap class, which declares no dependencies, so a typed ref could only ride an annotation argument and would duplicate a field the substrate already carries (test **b**). |
| **7 Back-link** | `@DocSpec([DocRef('NTFCH', 'supplies the delivery channel this declaration registers')])`. |

#### 3.2.10 `@CsReportParameter` — CE-RP runtime parameter

| Point | Contract |
|-------|----------|
| **1 Input** | The parameter subsections of `ReportEntry` (`REPENT`). Consumed: the parameter's type, bound and presentation. |
| **2 Output** | A `TomReportParameter` member, form 1. Distinct from a CE-DB row filter authored into the query — a parameter is **supplied per execution**, so it is part of the report's request shape; and distinct from a CE-FM field for the same reason a report column is: a form field belongs to a form the user submits, a parameter to the report's own request contract. |
| **3 Arguments** | None; unchanged. Type, bound and presentation are `TomReportParameter`'s parameters (test **b**). |
| **4 Naming** | camelCase of the parameter-name field. |
| **5 Locus** | **`shared`** — the parameter shape crosses to the client with the result envelope, even though the definition stays server-side at slice 3 (§3.3.8). It is emitted here, with the `TomReportResult` envelope that carries it, because both travel as a CE-API response DTO. |
| **6 Cross-refs** | `CsMessageKey` (its label); domain enums by plain type. |
| **7 Back-link** | `@DocSpec([DocRef('REPENT', 'supplies the runtime parameter and its bound')])`. |

### 3.3 Slice 3 — server persistence & configuration

Cites slice 1 (domain enums, `CsResourceKeyRef`) and slice 2 — the report
definition's result envelope and parameter shapes are emitted there (§3.2.10).
Never cites the client.

#### 3.3.1 `@CsTable` — CE-DB entity

| Point | Contract |
|-------|----------|
| **1 Input** | `DataEntityEntry` (`DAENT`), with `EntityRelationshipEntry` (`ENRLE`) supplying relationship columns. Consumed at entity level (§5.13): entity name, table, datasource, schema, identity attribute, row-scope rule. |
| **2 Output** | A **persistent entity class** built on the Tom persistence model (`tom_core_server`), form 1. Its stored fields are `@CsColumn`-marked members (§3.3.2). The row-scope rule is emitted as the framework's own `@TomDbScope`, carried alongside — the same "framework annotation beside the marker" pattern CE-LG and CE-SU use. |
| **3 Arguments** | `table` — **first positional, required** ← `DAENT`'s table field, **verbatim** (a physical table name is not derived; a generator that slugified it could rename a table under a running system). `datasource` / `schema` ← the corresponding `DAENT` fields, verbatim, `null` meaning the deployment default. The identity attribute is **not** an argument — it is the member carrying the framework's identity annotation (test **a**). |
| **4 Naming** | Class = PascalCase of `DAENT`'s entity-name field — **not** of the table name; the table is a storage fact and the class is the domain name. N6 applies. |
| **5 Locus** | `server` — CE-DB is server-only (§4.2), which is also why a rendering attribute cannot be declared on a column (§5.13.1). |
| **6 Cross-refs** | Relationship columns reference other entities by **`Type` literal**, never a ref const (§5.23). Domain enums by plain type. |
| **7 Back-link** | `@DocSpec([DocRef('DAENT', 'supplies the entity, its table and its storage placement')])`, plus one `DocRef('ENRLE', …)` per relationship the entity carries. |

#### 3.3.2 `@CsColumn` — CE-DB column (member marker)

| Point | Contract |
|-------|----------|
| **1 Input** | `DataAttributeEntry` (`DAATT`), with `DataAttributeConstraintEntry` (`DATAA`) supplying length and format constraints. Consumed (§5.13 attribute level): name, column, value type, column type, read-only, not-loaded, json-encoded, column-access key, converters, and the `DataAttributeKind.fileReference` facet. |
| **2 Output** | One **member** of the §3.3.1 entity, typed by the SOM value type. `read-only`, `not-loaded`, `json-encoded` and converters are emitted as the framework's own persistence annotations beside the marker (test **b**), not as marker arguments. |
| **3 Arguments** | `column` ← `DAATT`'s column field, verbatim; `null` means "same as the member name". `columnType` ← the SOM column type, verbatim. `length` ← the maximum length from `DATAA` — §4.1.1 names maximum lengths as exactly the kind of thing simple code cannot express. `accessKey` ← the column-access key as a `CsResourceKeyRef`. `fileReference` ← a `CsFileReference` value **iff** `DAATT`'s kind is `fileReference` (§3.3.3); its **presence is the column kind**. The Dart **value type** is never an argument (test **a**). |
| **4 Naming** | camelCase of `DAATT`'s attribute-name field. |
| **5 Locus** | `server`, with its entity. |
| **6 Cross-refs** | `CsResourceKeyRef`; `Type` literals for relationship targets. |
| **7 Back-link** | `@DocSpec([DocRef('DAATT', 'supplies the stored attribute, its column and its storage type')])`, plus `DocRef('DATAA', …)` where a constraint supplied the length or format. |

#### 3.3.3 `CsFileReference` — CE-DB file-reference facet (value class)

| Point | Contract |
|-------|----------|
| **1 Input** | `DataAttributeEntry` (`DAATT`) whose kind is `DataAttributeKind.fileReference`, with the `@OneOf` case `fileReferenceOptions` (`DAATT-DTFR`) supplying the facet fields. |
| **2 Output** | Not a declaration — a **const value** passed to `@CsColumn(fileReference:)`. Built on `TomFileReference` (`tom_core_server`, `object_persistence`), whose four settings it mirrors one-for-one; storage is `TomBlobStore` and key generation `TomFileReferenceKeys`. Per pillar (b) there is no CodeSpecs-local file-reference type. |
| **3 Arguments** | **Unchanged — already fully shaped by §5.13.1.** `keyPrefix` (**required**) ← the storage group, verbatim; there is no default because a shared prefix would put unrelated retention classes in one partition. `store` ← the file store, `null` = the deployment default. `cascadeDelete` ← *delete with record*, default `true` (the file belongs to the row). `defaultMediaType` ← the default content kind. `acceptedMediaTypes` ← the permitted content kinds, `const []` = unrestricted; it has no `TomFileReference` counterpart by design and is enforced at the CE-API upload endpoint. The **stored address** is derived (`<keyPrefix>/<yyyy>/<mm>/<uuid>`) and never authored. |
| **4 Naming** | None — the facet has no identifier of its own. |
| **5 Locus** | `server`, with its column. |
| **6 Cross-refs** | None. Downloadability is the column's own authorization (`accessKey`); rendering is CE-EL; upload/serve is CE-API. |
| **7 Back-link** | Covered by its column's `@DocSpec`; `DocRef('DAATT-DTFR', 'supplies the file-reference facet settings')` is appended to it. |

#### 3.3.4 `@CsRepository` — CE-DB repository

| Point | Contract |
|-------|----------|
| **1 Input** | `DataEntityEntry` (`DAENT`) for the entity and key type; the named queries come from the operations that read the entity (`SVOPE`, matched by `primaryDataEntity` and by the members typed by the entity). Consumed (§5.13 repository level): entity + key type, named queries, predicates, sort, row cap, distinct, transaction scope. |
| **2 Output** | A repository over the `tom_core_server` CRUD / MariaDB repositories, form 1, with one **form-3 method per named query** — a real signature and `throw UnsupportedError('<query description>')`. Query composition uses `TomQueryBuilder`; the §5.13 predicate vocabulary (`eq`, `like`, `between`, `isIn`, `and`, `or`), sort, row cap and distinct are that builder's own surface (test **b**), not annotation arguments. |
| **3 Arguments** | None; `@CsRepository({String? note})` unchanged. Entity and key type are the class's generics (test **a**); transaction scope is the framework's transaction annotation beside the marker (test **b**). |
| **4 Naming** | PascalCase of the entity name + `Repository`. |
| **5 Locus** | `server`. |
| **6 Cross-refs** | `Type` literals for the entity; `CsOperationRef` where a named query realises a declared operation. |
| **7 Back-link** | `@DocSpec([DocRef('DAENT', 'supplies the entity and key this repository reads')])`, plus one `DocRef('SVOPE', …)` per named query. |

#### 3.3.5 `@CsMigration` — CE-MG schema-migration artifacts

| Point | Contract |
|-------|----------|
| **1 Input** | `SCHMG` — its `MIGTG` migration-target list (the datasource/schema placement) and its `SCMST` artifact list (kind, version, environment restriction, and the kind-specific body in `SCMST-BASE` / `SCMST-REFD` / `SCMST-CHNG`). Additional input: the §3.3.1/§3.3.2 entity model, which the cumulative DDL must converge on. |
| **2 Output** | Two things: (i) **numbered SQL file assets**, not Dart — under `<databaseMigrationsDirectory>/<datasource>/<schema>/`, named `[<version>]-<description>[@<env>[,<env>…]].<ext>` per §5.27's grammar, applied in ascending version order; (ii) the **spec-side declaration** carrying this marker, over the reused `TomDbMigrations` / `TomDbMigrator` / `TomMigrationFileName` / `@TomDbMigrationAdaptor` / `MariadbMigrationAdaptor` engine (`tom_core_server`) — no gap class. |
| **3 Arguments** | `datasource` and `schema` (**both required**) ← the `MIGTG` entry that `SCMST.migrationTarget` names, verbatim — they are the directory path and cannot be defaulted without silently retargeting a database. Authoring them once per target and referencing the target per artifact is what keeps them required without repeating the pair down a whole chain. `kind` (**required**) ← `CsMigrationKind {initialDdl, baseData, iteration}` from `SCMST.artifactKind`, one-to-one over §5.27's three artifact kinds (`initialDdl` → `initialDdl`, `referenceData` → `baseData`, `schemaChange` → `iteration`; the SOM names stay neutral per `codespecs_mapping.md` §1.2, the marker keeps the CodeSpecs vocabulary). No arm is a safe default, since generating an initial DDL where an iteration was meant would rewrite a live schema. Filenames are **not** arguments — they are file-system facts and one of the four §5.23 string exemptions. |
| **4 Naming** | Declaration = `<Datasource><Schema>Migrations`, PascalCase, one per `MIGTG` entry. **Artifact filenames are authored, never derived** (N5): the version is the author's ordering decision and a derived one would renumber on every spec edit. `SCMST.version` and `SCMST.environments` are the author's `[<version>]` and `@<env>` filename segments, carried through unchanged. |
| **5 Locus** | `server` — the migrations tree ships with the server project as file assets. |
| **6 Cross-refs** | None typed. `SCMST.migrationTarget` → `MIGTG.targetName` is a *doc-side* reference resolved during derivation, not a `Cs*Ref`: it selects the two path strings before generation, so nothing survives into the emitted code to point at. The convergence obligation — cumulative DDL vs. the `@CsTable`/`@CsColumn` model — is a **named generation-time validator check**, precisely because the filename exemption means it cannot be a compile-time edge. |
| **7 Back-link** | `@DocSpec([DocRef('SCHMG', 'supplies the migration artifact set this declaration ships')])`. Applied artifacts are immutable; a schema change is a new numbered artifact, never an edit to an existing one. |

#### 3.3.6 `@CsServerConfig` — CE-CF server configuration

| Point | Contract |
|-------|----------|
| **1 Input** | `ServerConfigurationSettingEntry` (`SCSET`), the declaration list under `SystemConfigurationManagement` (`SYCOMA`) — one entry per server setting (`codespecs_mapping.md` §5.16). A second CE-CF band arrives differently: the audit-sink settings under `AuditLogFormat` (`AULOFO`) — record shape (`EVATPO`), storage (`LOSTPO`), tamper protection (`LOPRPO`) and retention (`LOREPO`) — are fixed-name form fields rather than a key/type/default list, so their member names come from the form, not from N5 over a key. |
| **2 Output** | A **configuration holder** (form 2) built on `TomBaseServerConfiguration` with `TomServerConfigResourceProvider` (`tom_core_server`), one `@CsServerConfig`-marked member per setting. Feature flags take the same shape — §5.5 lists them as a settings sub-case, not a separate mechanism. |
| **3 Arguments** | `key` — **first positional, required** ← `SCSET`'s setting key, **verbatim** (§5.23 exemption 1). `envAlias` / `cmdlineAlias` ← `SCSET`'s environment variable and command-line option, verbatim (same exemption). `secret` ← the secret mark, default `false` — the safe arm: a setting wrongly marked secret is merely stripped, one wrongly left unmarked ships its value. `overridableBy` (**required**, `CsOverridableBy {none, client, user, device}`) ← `SCSET`'s overridability opt-in; no default, because choosing a value's blast radius by omission is the exact failure §5.16's fail-safe rule prevents. The setting's **type** is the member type and its **default** the member initialiser (test **a**). *Precedence* is not an argument — §5.16 fixes intra- and cross-scope precedence for everyone; `overridableBy` grants the **permission** to contest, it does not order the contest. |
| **4 Naming** | Holder = `<App>ServerConfig`; member = N5 over the setting key. |
| **5 Locus** | `server`. Deployment-environment names appearing in values are §5.23 exemption 2 — verbatim strings, not refs. |
| **6 Cross-refs** | None typed. Log format, storage, protection and retention land here rather than on CE-LG — they are sink deployment settings. The compliance *report* lands on neither: reviewing and reporting from the log is a follow-up process, not generated code (`codespecs_mapping.md` §4.3.2). |
| **7 Back-link** | `@DocSpec([DocRef('SCSET', 'supplies the setting key, type, default, sources, secret mark and overridability')])`. |

#### 3.3.7 `@CsAudited` — CE-LG audited element

| Point | Contract |
|-------|----------|
| **1 Input** | The `SecurityEventsDefinition` (`SEEVDE`) band under `AuditAndLogging` (`AUANLO`): `SecurityEventLoggingPolicy` (`SELP`), the four per-category event policies, and `SecurityEventEntry` (`SEVT`). Consumed: which invocations are auditable, whether reads count, which fields must never appear. The sibling `AuditLogFormat` (`AULOFO`) band is **not** an input here — it is CE-CF (§3.3.6). |
| **2 Output** | **No declaration of its own** — a marker on an entity or endpoint, carrying the framework's own `@TomAudited(enabled:, includeReads:, redact:)` beside it. Pure reuse of `tom_core_server`'s `audit` module (`TomAuditTrail` / `TomAuditRecord` / `TomAuditSink`); recording happens automatically at two chokepoints no handler can opt out of — `TomEndpointHandler.handleMethodCall` and `TomSqlDatasourceRepository`'s write path. |
| **3 Arguments** | None; `@CsAudited({String? note})` unchanged. The three authored decisions are **exactly** `@TomAudited`'s three parameters (test **b**) — the same pattern CE-SU uses with `@tomService`. Retention and log format are **not** CE-LG: they are sink deployment settings and belong to `@CsServerConfig` (§3.3.6). The compliance report is not CodeSpecs at all — it is an ops/compliance follow-up. |
| **4 Naming** | None — the marker rides an existing declaration. |
| **5 Locus** | `server` — the trail is a server chokepoint. It emits in **two slices**, because it is annotation-only and a marker cannot precede the thing it marks: with the CE-DB write path here, and with the CE-API handler at slice 4. Entered once, at the earlier, per §3's placement rule. |
| **6 Cross-refs** | None typed. Nothing outbound at all, which is why the two-slice split costs no ordering. |
| **7 Back-link** | Appended to the audited element's own `@DocSpec`: `DocRef('SEVT', 'marks this element auditable and fixes its redaction set')`. |

#### 3.3.8 `@CsReport` — CE-RP report definition

| Point | Contract |
|-------|----------|
| **1 Input** | `ReportEntry` (`REPENT`) under the `ReportDefinitions` (`REDF`) projection root. Consumed: §5.28's 22-row attribute surface — the grouped projection, dimension by dimension and measure by measure. |
| **2 Output** | A `TomReportDefinition` with `TomReportDimension` / `TomReportMeasure` members (`tom_core_codespecs` **gap classes**), form 1. Query execution (`TomGroupedSelect`, `TomAggregate`) and rendering (`TomTabularResult` + its CSV / XLSX / PDF renderers) are pure `tom_core_server` reuse. CE-RP is a part and **not** a composition of CE-API + CE-DB + CE-FM: none of those can hold a dimension or a measure. |
| **3 Arguments** | None; `@CsReport({String? note})` unchanged. The whole 22-row surface maps onto `TomReportDefinition`'s constructor and its dimension/measure members (test **b**) — the gap was the *classes*, and §5.28 closed it, so nothing is left for the annotation to carry. Its outbound references do not change that: the source entity is a `Type` literal and the schedule a recurrence expression, both constructor parameters; authorization rides a separate `@CsAuthorize` beside this marker (point 6). §5.28's three generation-time consistency checks are validator checks, not arguments. |
| **4 Naming** | PascalCase of `REPENT`'s report-name field + `Report`. |
| **5 Locus** | **Definition `server`**, this slice — that is where the report runs, and it sits with CE-DB because it is a declaration *over* the persistence model rather than server behaviour. **Result envelope and parameter shapes are `shared` at slice 2** (§3.2.10). Emitting the definition here also puts it ahead of both its citers: the slice-4 endpoint that returns it and the slice-7 job that schedules it. |
| **6 Cross-refs** | Emits `CsReportRef` — and CE-JB is its **only** citer, since the ref is server-owned. Every label is a `CsMessageKey`, never inline text. Its four outbound targets each land differently (`codespecs_mapping.md` §5.28): **source entity** ← the source-entity field, as a **`Type` literal** on `TomReportDefinition.sourceEntity` — an entity is already a Dart type, §5.23 gives it no ref const, and a `Type` costs the gap package no dependency; **schedule** ← the report-schedule section's schedule-expression field, **verbatim** onto `.scheduleExpression`, which is not a reference at all (§5.29 realises the CE-JB job *from* the schedule, so a job id here would be the second source that rule forbids, and the schedule's time zone, effective dates and window lower onto the derived `TomJobDefinition`); **authorization** ← the security section's access level and permitted roles, emitted as a **`@CsAuthorize` beside this marker** per `codespecs_mapping.md` §5.15 — `Public`→`public`, `Authenticated`→`authenticated`, `Role-specific`→`role` with the roles as `CsRoleRef` consts, `Confidential`→`resourceKey`; **drill-through** stays an open route id string on the column (§3.3.9). |
| **7 Back-link** | `@DocSpec([DocRef('REPENT', 'supplies the grouped projection this report defines')])`. |

#### 3.3.9 `@CsReportColumn` — CE-RP output column

| Point | Contract |
|-------|----------|
| **1 Input** | `ReportColumnEntry` (`REPCOLENT`). Consumed: which declared dimension or measure the column displays, its aggregate and its format. |
| **2 Output** | A `TomReportColumn` member of the §3.3.8 definition, form 1. A column **displays** a declared dimension or measure and never introduces data of its own — which is why it names a source key rather than an entity column, and why it is not `@CsColumn` (a stored attribute, a different level entirely). |
| **3 Arguments** | None; unchanged. Source key, aggregate and format are `TomReportColumn`'s parameters (test **b**). |
| **4 Naming** | camelCase of `REPCOLENT`'s column-name field. |
| **5 Locus** | `server` with its definition. The `TomReportColumn` *class* is also reachable from the shared `TomReportResult` envelope, but that is a gap-package type in `tom_core_codespecs` — which is not one of the three generated projects — so it fixes no locus for the authored declaration. |
| **6 Cross-refs** | `CsMessageKey` (its label). Its **drill-through** target is an open route id string on `TomReportColumn.drillThroughRouteId` — the one CE-RP edge a typed ref can never carry, because `codespecs_mapping.md` §5.23's locus rule bars a server-owned definition from citing a client-owned route. Unlike the four §5.23 string exemptions, whose referents are not Dart declarations, a route **is** one, so the compile-time guarantee is lost to locus rather than absent by nature and is **replaced** by check 18 (§6) — the same substitution check 17 makes for a CE-NT fallback. |
| **7 Back-link** | `@DocSpec([DocRef('REPCOLENT', 'supplies the projected column and its aggregate')])`. |

#### 3.3.10 `@CsReportChart` — CE-RP chart

| Point | Contract |
|-------|----------|
| **1 Input** | `ReportChartEntry` (`REPCHAENT`). Consumed: chart type, series, axes — the SOM carries all three as structured fields. |
| **2 Output** | A `TomReportChart` member, form 1. **Declared here, rendered by whoever can:** the declaration is authored input, while rendering is implementation-owned — a client draws charts natively, and an export format that cannot express one **omits it rather than failing**. A chart plots columns the report already projects, so it never adds a second query. |
| **3 Arguments** | None; unchanged. Type, series and axes are `TomReportChart`'s parameters (test **b**). |
| **4 Naming** | camelCase of `REPCHAENT`'s chart-name field + `Chart`. |
| **5 Locus** | `server` with its definition. |
| **6 Cross-refs** | References the report's own columns by member, not by ref const — they are siblings in one declaration. |
| **7 Back-link** | `@DocSpec([DocRef('REPCHAENT', 'supplies the chart type, series and axes')])`. |

### 3.4 Slice 4 — server behaviour

Cites slices 1, 2 and 3. CE-NT **delivery** — channel routing and the outbox —
emits here too, but authors no marked declaration, so it has no entry of its own
(§3.2.8); `@CsAudited` reappears here over the CE-API handler chokepoint
(§3.3.7).

#### 3.4.1 `@CsServiceUnit` — CE-SU service unit

| Point | Contract |
|-------|----------|
| **1 Input** | `ArchitectureComponentEntry` (`ARCM`) — §8.5 records this as COVERED but **weak**. Consumed (§5.17): unit id, root aggregate, process-cohesion adjustment, bounded context. |
| **2 Output** | An **ordinary abstract class** carrying the framework's own `@tomService` / `TomApiImplementation` (`tom_core_server`) beside the marker — §5.6.2 records CE-SU as reuse with *no new class*. It **co-emits the CE-API handler methods** (§3.4.2), which is why slice 4 emits both together. Its derived ownership lists — owned entities, repositories, operations — are materialised as `Type` literals and `CsOperationRef` consts, never re-authored. |
| **3 Arguments** | `rootAggregate` (**required**) ← the §5.1 owned-aggregate primary criterion, as a **`Type` literal**. `boundedContext` (**required**) ← the §5.1 outer bound, verbatim. The unit id is **not** an argument — it is the class name (test **a**), fixed by §5.1 as `<RootAggregate>Service`. The process-cohesion adjustment is marked **D** (derived) in §5.17: it shows up as which operations the unit owns, not as a field. |
| **4 Naming** | PascalCase of the root aggregate + `Service`, per §5.1 — **not** of `ARCM`'s headline, so two documents naming the same aggregate cannot produce two unit names. |
| **5 Locus** | `server`. |
| **6 Cross-refs** | Emits `CsServiceUnitRef` (its own citable const). References entities and repositories by `Type`, operations by `CsOperationRef`. |
| **7 Back-link** | `@DocSpec([DocRef('ARCM', 'supplies the component boundary this service unit realises')])`. |

#### 3.4.2 `@CsEndpoint` — CE-API, server handler half

| Point | Contract |
|-------|----------|
| **1 Input** | The same `ServerOperationEntry` (`SVOPE`) as §3.2.1 — one section, two loci. Consumed here: `purpose` (the operation's behaviour, which becomes the stub explication), `primaryDataEntity` (which service unit the handler lands on, §5.17) and `errorCodes` (the `CsErrorCode` cross-refs below). |
| **2 Output** | A **handler method on the §3.4.1 service unit**, form 3: real signature `Future<TomResult<T>> <op>(<Request> request)`, body `throw UnsupportedError('<behaviour description>')`. Routed by `TomEndpoint` / `TomEndpointHandler` / `TomEndpointRouting` / `TomServer` (`tom_core_server`). All operations are POST and only 5xx are transport errors (§7); a generator emitting a non-POST verb or a 4xx contract has violated it. |
| **3 Arguments** | `operation` — first positional, required, **the identical verbatim string** as the shared half's `CsOperationRef` (§3.2.1). A validator asserts the two match; they are one operation named once. |
| **4 Naming** | Method = camelCase of the operation name's last dotted segment (`customer.save` → `save`) — the unit already supplies the `customer` half, and repeating it would give `CustomerService.customerSave`. |
| **5 Locus** | `server` (§4.2: handlers). |
| **6 Cross-refs** | `CsOperationRef` (the shared const it realises); `Type` literals for the shared DTOs; one `CsErrorCode` per code in `SVOPE.errorCodes`. |
| **7 Back-link** | `@DocSpec([DocRef('SVOPE', 'supplies the operation behaviour this handler implements')])`. |

#### 3.4.3 `@CsAuthorize` — CE-AZ authorization requirement (modifier)

| Point | Contract |
|-------|----------|
| **1 Input** | `RoleMatrix` (`ROMA`), `RolePermissionEntry` (`ROLPERM`), `EntitlementEntry` (`ENT`). Consumed: which of the §5.15 requirement kinds applies and its payload. |
| **2 Output** | **No declaration of its own** — coding form 4, a modifier on the `@CsEndpoint` it gates (§5.6.3), or on a field for the field-level `authorizer` (slice 5). It feeds `TomEndpointHandler.checkAccess`, over the `TomAccessControl` family + `TomGradedAccess` + `TomPrincipal` (`tom_core_kernel`) and `TomResourceGrant` (`tom_core_server`). Slice 1 separately emits the **role and resource-key catalogues** into shared, since both sides cite them. |
| **3 Arguments** | `requirement` (**required**) ← `CsAuthRequirement {role, group, entitlement, resourceKey, custom, graded, none, public, authenticated, guest}` — §5.15's six requirement kinds plus its four attribute-less presets (`TomNoAccess`, `TomPublicAccess`, `TomAuthenticatedAccess`, `TomGuestAccess`) folded into one closed enum. Required, and no arm is a default: defaulting an authorization requirement is the exact failure §5.16's fail-safe rule exists to prevent. Per-kind slots, only the declared kind's being non-null (§2.3): `roles: List<CsRoleRef>` (→ `TomRoleAccess.roles`), `groups: List<String>`, `entitlements: List<String>` (the §5.15 patterns), `resourceKey: CsResourceKeyRef`, `handler` + `resourceId: String` for custom, and `graded: CsGradedAccess` — a nested facet value class holding the three slots `full` / `read` / `disabled`, since §5.15's graded arm is a requirement tree, not a scalar. The four states `none < disabled < read < full` and the monotonic defaults `read ⇐ full`, `disabled ⇐ read` are **derived**, not authored. |
| **4 Naming** | None — the modifier has no identifier. Catalogue consts are named by N9 over the role / resource-key name. |
| **5 Locus** | `server` for operation-level; `client` for the field-level `authorizer` (slice 5); the **catalogues** are `shared` (§4.2). |
| **6 Cross-refs** | `CsRoleRef`, `CsResourceKeyRef`. Groups and entitlement patterns stay strings — they name external directory objects, not generated declarations. |
| **7 Back-link** | `@DocSpec([DocRef('ROLPERM', 'supplies the requirement this operation is gated by')])`, with `ROMA` / `ENT` substituted by source. |

#### 3.4.4 `@CsAuth` — CE-AU server flow + CE-ID population

| Point | Contract |
|-------|----------|
| **1 Input** | `LoginFlowStepEntry` (`LGFLS`) for the flow; `UserAttributeEntry` (`USATE`) for which attributes are populated into which token half; `UserLifecycleTransitionEntry` (`ULTRE`) for the account state transitions. |
| **2 Output** | The app's `TomAuthenticationService` bound into `TomAuthenticationServer`, issuing `TomServerJwtToken` (`tom_core_server`), form 1 + form 3 — one method per `LGFLS` step, each `throw UnsupportedError('<step description>')`. The **CE-ID population** is part of this flow: it projects the §3.2.5 identity declaration into the public (`TomUser.attributes`) and encrypted (`TomPrincipal.currentContext`) halves, per each attribute's `placement`. CE-AU consumes CE-ID; it never redeclares it. |
| **3 Arguments** | None — `@CsAuth` stays note-only for the same reason as §3.2.7: one marked declaration per method/flow, so the set of declarations *is* the enabled set. |
| **4 Naming** | PascalCase of `ATME`'s name field + `AuthenticationService`. |
| **5 Locus** | `server`. |
| **6 Cross-refs** | `CsOperationRef` (the login operation); `Type` literal for the identity declaration; `CsRoleRef` where a flow step grants a role. |
| **7 Back-link** | `@DocSpec([DocRef('LGFLS', 'supplies the flow step this method performs'), DocRef('USATE', 'supplies the attribute projected into the token')])`. |

### 3.5 Slice 5 — client interaction core

Cites slices 1 and 2 **and never 3 or 4**: the client project depends on shared
only. The six parts CE-ST, CE-EL, CE-FM, CE-AC, CE-SC, CE-NV form §4.4.2's
**SCC-B** — they reference each other cyclically and are therefore emitted as one
unit, which is why they share a slice rather than an order.

#### 3.5.1 `@CsViewModel` — CE-ST view state

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenStateEntry` (`SCRST`), `ScreenElementDataDisplay` (`SEDD`), `ComponentStateEntry` (`COMSTAENT`). Consumed (§5.4): the fields as `(name, T, kind)`, their derivation, their binding, the lifecycle scope. |
| **2 Output** | A view-model class holding `TomObservable` / `TomObject<T>` members — `TomString`, `TomInt`, `TomDouble`, `TomBool`, `TomClass`, `TomList`, `TomMap` (`tom_core_kernel`) — bound in the UI by `TomObservingWidget` / `ValueListenableObserver` (`tom_core_flutter`). Form 1. **Observable fields are initialised declarations** (`final TomString name = TomString('');`) — §2.4's sole exception, because an uninitialised observable would not compile at its use sites. Derived fields are form-3 getters that throw. |
| **3 Arguments** | `scope` ← the lifecycle scope, enum-mapped onto `CsLifecycleScope {screen, route, app}`, default `screen` — the narrowest arm, so widening a view model's lifetime is a deliberate act. Fields, their types and their binding are the declaration (test **a**); binding to a widget is `TomObservingWidget`'s own surface (test **b**). |
| **4 Naming** | PascalCase of `SCRST`'s name field + `ViewModel`; members camelCase of their own name field. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | Referenced **by** `CsTrigger`'s condition kind (its predicate reads these fields). Emits none. |
| **7 Back-link** | `@DocSpec([DocRef('SCRST', 'supplies the view state this model holds')])`, plus `SEDD` / `COMSTAENT` per contributing field. |

#### 3.5.2 `@CsElement` — CE-EL semantic element

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenElementEntry` (`SCREL`), `UiComponentEntry` (`UICOMENT`), `ComponentVariantEntry` (`CVE`). Consumed (§5.18 field base): element id, semantic kind, value type; the N-marked rows (initial value, label/hint, validators, authorization, auto-validate) come from other parts and are **not** consumed here. |
| **2 Output** | A **standalone element declaration** built on the `Tom*` element family through `TomScreenElementsProvider` (`tom_flutter_ui`), form 1. The element id rides `TomField.tomId` (test **b**). Elements that are *members of a form* are emitted by CE-FM instead (§5.7.2): `@CsElement` proper covers standalone elements. |
| **3 Arguments** | `kind` (**required**) ← the semantic kind, enum-mapped onto `CsElementKind {textInput, number, toggle, dateInput, choice, multiChoice, fileInput, label, button, menuEntry, formHost}` — §5.18's closed eleven-kind catalogue. Required because it selects the per-kind attribute set and the default widget; no kind is a sensible default. The value type `T` is the declaration's generic (test **a**); every per-kind extra (`maxLength`, `keyboardType`, `maxLines`, `obscureText`, `variant`, `icon`, `allowedExtensions`, `maxSizeBytes`, `pickKind`, `autoUpload`, …) maps onto a named `tom_flutter_ui` widget property and is therefore carried by the `@CsWidget` instantiation (test **b**), never duplicated here — `fileInput`'s `presentation` included, since like `button`'s `variant` it selects the concrete (`TomFormFileUpload` / `TomFormFileDropzone` / `TomFormFileThumbnail`) rather than configuring one. |
| **4 Naming** | camelCase of `SCREL`'s element-id field. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsMessageKey` for catalogued label/hint copy; `CsResourceKeyRef` via its field-level `@CsAuthorize`. Its **action edge is a derived back-reference** (§5.18) — read off the triggers, never authored here. Emits `CsElementRef` (§2.6). |
| **7 Back-link** | `@DocSpec([DocRef('SCREL', 'supplies the element, its semantic kind and its value type')])`. |

#### 3.5.3 `@CsWidget` — CE-EL concrete widget

| Point | Contract |
|-------|----------|
| **1 Input** | The same `SCREL` / `UICOMENT` / `CVE` sections as §3.5.2, plus `ComponentVariantEntry` (`CVE`) for a non-default widget choice. |
| **2 Output** | The **concrete `tom_flutter_ui` widget instantiation** realising the semantic kind — `TomTextField` for `textInput`, a `TomButtonBase` variant for `button`, and so on down §5.18's per-kind table. Form 1. This is step two of §5.7.1's two-step semantic → widget derivation: the kind is the spec, the widget is the realisation. |
| **3 Arguments** | None; `@CsWidget({String? note})` unchanged. Every per-kind attribute is a named parameter of the widget constructor (test **b**) — which is the whole reason the two-step split exists: it lets the spec stay at the semantic level while the code stays typed. |
| **4 Naming** | None of its own — the marker sits on the element's widget member. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsMessageKey` for its copy. |
| **7 Back-link** | Covered by the element's `@DocSpec`; `DocRef('CVE', 'selects the widget variant')` is appended when a variant entry chose a non-default widget. |

#### 3.5.4 `@CsForm` — CE-FM form

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenElementFieldSpec` (`SEFS`). Consumed: the form/subform tree **and its member input elements** — §5.7.2 gives CE-FM ownership of both, which is what distinguishes it from §3.5.2. |
| **2 Output** | A `TomForm<T>` subclass with `TomFormChildContainer` for subforms and `TomField<T>` members (`tom_flutter_ui`), form 1. It mirrors the SOM `@Form` field-group one-for-one — a form section and a form class are the same shape at two resolutions. Member fields carry their own `@CsElement` + `@CsWidget` markers. |
| **3 Arguments** | None; `@CsForm({String? note})` unchanged. The field list, the subform tree and the form's value type are the declaration (test **a**); everything else `TomForm` takes is its own constructor (test **b**). |
| **4 Naming** | PascalCase of `SEFS`'s name field + `Form`. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | Emits `CsFormRef` (§2.6). Cites `CsMessageKey` for copy and its `@CsFormRule` methods for cross-field invariants. |
| **7 Back-link** | `@DocSpec([DocRef('SEFS', 'supplies the form, its subform tree and its fields')])`. |

#### 3.5.5 `@CsAction` — CE-AC action

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenActionEntry` (`SCRAC`), `ScreenElementAction` (`SCELAC`), and the ISC step entries `MNSST` / `ALST` / `EXTST` / `SCNST`. Consumed (§5.20): action id, owning controller, context requirement `TContext`. |
| **2 Output** | A `TomAction` on a `TomActionController`, with `TomActionTransaction` / `TomActionContext` as needed (`tom_flutter_ui`), form 1. Declared as a named member, since N9 makes the **declaration name** the action's identity. |
| **3 Arguments** | None; `@CsAction({String? note})` unchanged. The action id is the declaration name (test **a**, and what `CsActionRef` resolves against); the owning controller is the declaration site; `TContext` is the generic. §5.20 marks undoable/`TUndo`, transaction grouping, authorization, copy and the server-bound edge as **N** — the first three are `TomAction`'s own surface, copy is CE-TX, and the server edge is derived from the trigger. |
| **4 Naming** | camelCase of `SCRAC`'s action-id field. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | Emits `CsActionRef`. Cites `CsCallRef` where the action is server-bound — **derived from the trigger**, never authored twice. |
| **7 Back-link** | `@DocSpec([DocRef('SCRAC', 'supplies the action and its context requirement')])`, plus one `DocRef` per contributing ISC step. |

#### 3.5.6 `@CsTrigger` — CE-AC trigger

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenElementAction` (`SCELAC`) and the ISC step entries. The trigger is the **single authoring home of the element→action edge** (§5.10): it names both endpoints, and the element's action edge is derived from it. |
| **2 Output** | A `TomActionTrigger` (`tom_flutter_ui`) instantiation, form 1. One action may carry several triggers of different kinds. |
| **3 Arguments** | `kind` (**required**, unchanged) ← `TriggerKind {userGesture, inFormEvent, lifecycle, serverEvent, condition}`; it selects which per-kind attribute set applies, so it cannot be inferred and no arm is a default. **Added by this contract:** `action: CsActionRef` (**required**) — the common head's target endpoint; then one optional slot per kind (§2.3), validated so only the declared kind's are non-null: `element: CsElementRef` + `gesture: CsGesture {tap, press, longPress}` for `userGesture`; `form: CsFormRef` + `formEvent: CsFormEvent {fieldChange, submit, validationPass, validationFail}` + `formField: CsElementRef` for `inFormEvent`; `scope: CsLifecycleScope` + `phase: CsLifecyclePhase {enter, leave, init, dispose}` for `lifecycle`; `channel` + `eventType: String` for `serverEvent`. The `condition` kind carries **no** slot: its predicate over CE-ST state is real Dart, so it is a closure the `TomActionTrigger` constructor takes (test **b**) — as is the optional guard on every kind. |
| **4 Naming** | camelCase of the action name + the kind (`saveOnTap`, `saveOnSubmit`), so several triggers on one action cannot collide under N4. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsActionRef`, `CsElementRef`, `CsFormRef`. Endpoints are typed references to the generated declarations, never id strings (§5.10) — which is why the §5.23 family carries `CsElementRef` / `CsFormRef` at all. |
| **7 Back-link** | `@DocSpec([DocRef('SCELAC', 'supplies the invocation path and the action it fires')])`. |

#### 3.5.7 `@CsServerCall` — CE-SC server call

| Point | Contract |
|-------|----------|
| **1 Input** | The ISC step entries `MNSST` / `ALST` / `EXTST` / `SCNST`. Consumed (§5.3): the operation called, request assembly, response handling, error handling, call options. |
| **2 Output** | A `TomServerEndpoint<T, R>` call over `TomServerCallSpecs` / `TomServerChannel` (`tom_core_kernel`), form 1 + form 3 — request assembly, response handling and error handling are methods that `throw UnsupportedError('<step description>')`. This is the middle hop of §5.3's chain: `@CsAction ──triggers──▶ @CsServerCall ──operation──▶ @CsEndpoint` (client / client / shared). |
| **3 Arguments** | `operation` — **first positional, required** ← the `CsOperationRef` const of the shared operation it calls. It is the one edge the code cannot carry itself: the call site is client, the operation is shared, and nothing in the Dart declaration names the link. Call options are `TomServerCallSpecs`'s own surface (test **b**); the three handling steps are the methods (test **a**). |
| **4 Naming** | camelCase of the operation name's last segment + `Call`. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsOperationRef` outbound; emits `CsCallRef` for the action edge. Cites `CsErrorCode` for each error it handles. |
| **7 Back-link** | `@DocSpec([DocRef('MNSST', 'supplies the interaction step this call performs')])`, with the actual step section id substituted. |

#### 3.5.8 `@CsRoute` — CE-NV route

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenRouteEntry` (`SCRTEN`) under `SCRTMP` (D09 XDS). §5.11 maps the three registries 1:1, and this is the first: route entries → `TomRouteDefinition`. |
| **2 Output** | A route declaration built on `TomPageRoute<T>` with `TomNavigationDestination` (`tom_flutter_ui`), registered in the route-id registry `TomRouteDefinition` — a `tom_core_codespecs` **gap class**, because the substrate has no stable route id of its own. Form 1. |
| **3 Arguments** | None; `@CsRoute({String? note})` unchanged. The route id and its parameters ride `TomRouteDefinition`'s constructor (test **b**), and the route id itself is an authored key taken verbatim (N5). |
| **4 Naming** | camelCase of `SCRTEN`'s route-id field + `Route`. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | Emits `CsRouteRef`. Cites the form it presents by `CsFormRef`. |
| **7 Back-link** | `@DocSpec([DocRef('SCRTEN', 'supplies the route and its stable id')])`. |

#### 3.5.9 `@CsScreenFlow` — CE-NV screen flow

| Point | Contract |
|-------|----------|
| **1 Input** | `FormScreenAssignmentEntry` (`FMSCAS`) and `ScreenTransitionEntry` (`SCTREN`), both under `SCRTMP` — §5.11's second and third 1:1 mappings. Consumed: which form a screen presents and whether it replaces or overlays; which action fires an edge and which outcome selects its target. |
| **2 Output** | `TomFormScreenAssignment` and `TomScreenFlowEdge` instantiations (`tom_core_codespecs` **gap classes**, §4.1), form 1. Where `@CsRoute` names *a* screen, this records the edges that combine the D05 ISC scenarios into interactions with screens. |
| **3 Arguments** | None; `@CsScreenFlow({String? note})` unchanged. Both gap classes carry the full surface on their constructors (test **b**): `ScreenPresentationMode {replace, popupOverlay}`, `ScreenFlowOutcome {success, error, validationError}`, and the `outcomeReference` that joins to `SYERCOEN` (CE-ER) or `VMT` (CE-VA). Adding the same values as marker arguments would create the second, disagreeing source §2.3 exists to prevent. |
| **4 Naming** | Assignment = camelCase of the route name + `FormAssignment`; edge = camelCase of the action name + the outcome (`saveOnSuccess`). |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsRouteRef` (both endpoints), `CsFormRef` (the presented form), `CsActionRef` (the firing action), and `CsErrorCode` / `CsMessageKey` for the `outcomeReference`. |
| **7 Back-link** | `@DocSpec([DocRef('FMSCAS', 'assigns the form to the screen and its presentation mode')])` or `DocRef('SCTREN', 'supplies the transition, its firing action and its outcome')`. |

#### 3.5.10 `@CsAuth` — CE-AU, client login flow half

| Point | Contract |
|-------|----------|
| **1 Input** | `LoginFlowStepEntry` (`LGFLS`), read **per client** — §5.25 makes the login flow a per-client decision, so one client's flow is not another's. |
| **2 Output** | The client's login flow over the `TomServerEndpoint<TomAuthenticationMessage, TomAuthenticationResult>` triple (`tom_core_kernel`), form 3 — one method per step, each `throw UnsupportedError('<step description>')`. |
| **3 Arguments** | None (as §3.2.7 and §3.4.4). |
| **4 Naming** | PascalCase of the client name + `LoginFlow`. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsOperationRef` (the login operation), `CsRouteRef` (where the flow lands), `CsErrorCode` (failure outcomes). |
| **7 Back-link** | `@DocSpec([DocRef('LGFLS', 'supplies the login step this method performs')])`. |

### 3.6 Slice 6 — client presentation & shell

Cites slice 5 (and 1). Nothing here is referenced by an earlier slice.

#### 3.6.1 `@CsLayout` — CE-LO layout node

| Point | Contract |
|-------|----------|
| **1 Input** | `ScreenSectionEntry` (`SCRSC`), `ScreenResponsiveRuleEntry` (`SCRERUEN`), `ComponentSlotEntry` (`CMSL`). Consumed (§5.2, §5.22): the container tree, its kinds, the slot hints, and the override deltas. |
| **2 Output** | Two layers, both id-addressed. The **base** is an `AclContainer` / `AclRow` / `AclFlowContainer` / `AclComponent` tree (`tom_flutter_ui`) rendered through `TomObservingWidget`; when the SOM authors no explicit layout, the default base is **a single `column` of the form's fields in SOM order** — never an empty tree. The **override layer** is a delta list over §5.22's closed five-op grammar: `reparent`, `set-container-prop`, `set-slot-hint`, `insert-container`, `remove-container`. Generated rows are addressable as `<containerId>.r<n>`. |
| **3 Arguments** | `nodeId` — **first positional, required** ← the section's node id, verbatim. It is the one thing the substrate genuinely lacks: §4.1 records the layout **node model** as a gap, the ACL classes carry no id, and the whole override-delta grammar addresses nodes by id. Container kind is **not** an argument — it is which Acl class is instantiated (test **b**); slot hints are `AclComponent` properties (test **b**). |
| **4 Naming** | Node ids are authored (N5). The generated Dart holder is PascalCase of `SCRSC`'s name field + `Layout`. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | `CsElementRef` / `CsFormRef` for the elements a slot hosts. Deltas address nodes by **id string**, which is not a §5.23 violation: a delta targets a node *within the same layout declaration*, so the id is a local coordinate, not a cross-part reference. |
| **7 Back-link** | `@DocSpec([DocRef('SCRSC', 'supplies the container tree this layout arranges')])`, plus `SCRERUEN` per responsive delta and `CMSL` per slot. |

#### 3.6.2 `@CsClient` — CE-CL client application

| Point | Contract |
|-------|----------|
| **1 Input** | One `ClientApplicationEntry` **CLIAPP** — an entry of the client-application list under `ClientRequirementsSection` CLRESE (D06 ATS). `clientId` and `clientName` give the identity, `clientKind` the kind, `platformTargets` / `entryRoute` / `includedScreens` the three reference-by-id sets. `purpose` is the reason the client exists and is emitted as the class doc comment, not as a member. |
| **2 Output** | A **client descriptor** — a class extending `TomClientApplication` (`tom_core_codespecs`, `client_application.dart`), setting `clientId` / `displayName` / `platforms` / `entryRoute` / `screenIds` in its constructor. `serverBaseUrl` is **not** emitted: the descriptor's own doc records it as wired by CE-CC at runtime, so a generated literal would be a second, staler source. |
| **3 Arguments** | `clientId` ← CLIAPP `clientId`, **first positional, required**, verbatim (N5). `kind` (**required**) ← CLIAPP `clientKind`, mapped arm-for-arm onto `CsClientKind`: `graphicalApplication → flutterApp`, `commandLine → cli`, `server → server`. The names differ **by design** — the SOM keeps §1.2's neutral vocabulary and names no framework, and the technology choice is exactly the deeper CodeSpecs level the mapping adds. Required because the kind decides which other parts the client can carry (a CLI has no CE-EL) and defaulting it would silently admit impossible combinations. Platforms, entry route and screens are members of the descriptor (test **a**). |
| **4 Naming** | PascalCase of the client id + `Client`. |
| **5 Locus** | `client`. A multi-client system generates one client project per `@CsClient`; the descriptor names which. |
| **6 Cross-refs** | `CsRouteRef` for its entry route, from CLIAPP `entryRoute` (a `SCRTEN.routeId`). `includedScreens` lowers onto `screenIds` as plain screen ids — §5.23 has no screen ref type, and the ids are already resolved against `SCREN.screenId` at authoring time. `platformTargets` lowers onto `platforms` verbatim; the ids resolve against the three requirement registries (`BROREQENT.browserName`, `DEOSREEN.osName`, `MODEREEN.platform`) in the same section, so the minimum a platform must meet is stated once and referenced, never restated. Referenced **by** CE-CC (a `CCSET` setting names its owning client) and CE-AU (per-client login flow). |
| **7 Back-link** | `@DocSpec([DocRef('CLIAPP', 'supplies the client application, its kind, platform targets, entry route and screens')])`. |

#### 3.6.3 `@CsClientConfig` — CE-CC client configuration

| Point | Contract |
|-------|----------|
| **1 Input** | `ClientConfigurationSettingEntry` (`CCSET`), the declaration list under `ClientConfiguration` (`CLICON`) — keyed by **(client app, machine)**, no user in the key, which is the discriminator against CE-DS (`codespecs_mapping.md` §5.16). The client half of that key is `CCSET`'s `client`, a `CLIAPP.clientId`; it groups the settings into one holder per client, and is the reason the owning client is stated on the **setting** rather than listed on the client (a setting belongs to one client, a client to many settings). Empty where the system has a single client. |
| **2 Output** | A configuration holder built on `TomBaseClientConfiguration` + `TomSetting<T>` + `TomClientConfigurationStore` (`tom_core_flutter`) over `TomConfigResourceProvider` (`tom_core_kernel`), form 2, one marked member per setting. |
| **3 Arguments** | `key` — **first positional, required**, verbatim (§5.23 exemption 1). `envAlias` ← the environment alias, verbatim. `overridableBy` (**required**, undefaulted) ← `CCSET`'s opt-in, naming which narrower scope may shadow the key — see §3.3.6 for why it has no default. Type and default are the member (test **a**). |
| **4 Naming** | Holder = `<Client>Config`; member = N5 over the key. |
| **5 Locus** | `client`. |
| **6 Cross-refs** | Cites its client by `Type`. |
| **7 Back-link** | `@DocSpec([DocRef('CCSET', 'supplies the per-install setting key, type, default and overridability')])`. |

#### 3.6.4 `@CsDeviceSetting` — CE-DS device setting

| Point | Contract |
|-------|----------|
| **1 Input** | `DeviceSettingEntry` (`DSSET`), the declaration list under `DeviceSettings` (`DEVSET`) — keyed by **(user, device)** and persisted on the device (`codespecs_mapping.md` §5.16). |
| **2 Output** | A settings holder over the existing `tom_core` property/settings classes — §4.1 records CE-DS as reuse with **no new class**. Form 2. Device binding is implicit-by-storage: the store lives on the device and is keyed by the signed-in user; there is no wire-level device identity. |
| **3 Arguments** | `key` — **first positional, required**, verbatim. Nothing else: type and default are the member. There is **no persistence mode argument** — §11 splits the four scopes by owner key, so the choice is *which marker you use*, never a mode on one of them. There is also **no `overridableBy`**, and `DSSET` authors none: the opt-in is granted by the *wider* scope, and CE-DS is the narrowest, so the lattice bottoms out here and "shadowable by something narrower" is unsayable rather than merely wrong. |
| **4 Naming** | Holder = `<App>DeviceSettings`; member = N5 over the key. |
| **5 Locus** | `client` — a device setting never leaves the device. |
| **6 Cross-refs** | None. |
| **7 Back-link** | `@DocSpec([DocRef('DSSET', 'supplies the per-user-per-device setting key, type and default')])`. |

#### 3.6.5 `@CsUserSetting` — CE-UP user setting (both loci)

| Point | Contract |
|-------|----------|
| **1 Input** | `UserSettingEntry` (`USSET`), the declaration list under `UserSettings` (`USRSET`) — keyed by the **user** alone, so the value follows the user onto any device (`codespecs_mapping.md` §5.16). `LanguageCountrySelection` (`LACOSE`, D09 XDS) is **not** an input: it is the language/country picker screen that *edits* a CE-UP preference, and the preference itself is declared in `USSET`. |
| **2 Output** | Two halves from one declaration. **Client:** the settings holder over `TomUserSettings` (`tom_core_codespecs`), reading `TomGetSettingsMessage` / `TomGetSettingsResult` (`tom_core_kernel`). **Server:** the persistence, over `TomUserSettingsStore` (`tom_core_codespecs`) backed by the slice-3 repositories. Form 2 both sides. |
| **3 Arguments** | `key` — **first positional, required**, verbatim. `overridableBy` (**required**, undefaulted) ← `USSET`'s opt-in; the only narrower scope it can name is `device`. Single-moded, for the same §11 reason as §3.6.4: a setting that must stay on the machine is `@CsDeviceSetting`, not this marker with a flag. |
| **4 Naming** | Holder = `<App>UserSettings`; member = N5 over the key. Both halves use the **same** member names, so the wire mapping is identity. |
| **5 Locus** | `client` for the shape (slice 6) **and** `server` for the persistence (slice 7). The other parts whose halves are both marked declarations take **one entry per half** — CE-API at §3.2.1/§3.4.2, CE-AU at §3.2.7/§3.4.4/§3.5.10. This one contracts both in a single entry because both derive from one `USSET` declaration and the wire mapping between them is identity, so splitting the entry would state the same derivation twice. |
| **6 Cross-refs** | Server half cites its store repository by `Type`. |
| **7 Back-link** | `@DocSpec([DocRef('USSET', 'supplies the per-user setting key, type, default and overridability')])` on both halves. |

### 3.7 Slice 7 — server operational

Cites slices 3 and 4. One entry: CE-UP's server persistence is the other half of
this slice, contracted with its client shape at §3.6.5.

#### 3.7.1 `@CsJob` — CE-JB background job

| Point | Contract |
|-------|----------|
| **1 Input** | One `ScheduledJobEntry` (`SCJOB`) from the per-job declaration list under `BatchJobManagement` (`BAJOMA`). Consumed (§5.29): the head form (`jobName`, `purpose`, `triggerKind`, `primaryDataEntity`, `enabled`, `environments`); the promoted trigger case subsection — `SCJOB-CRON`, `SCJOB-CAL` or `SCJOB-EVNT`; `SCJOB-WORK` (work intent, read/written entities, target reports); `SCJOB-FAIL` (the per-job overrides of the `BJME` defaults). `BAJOMA`'s own policy sections supply the **defaults** an entry may override, never a job. |
| **2 Output** | A `TomJobDeclaration` (`tom_core_codespecs` **narrow gap class** — the deployment-and-ownership envelope only) on a class that also extends `tom_core_kernel`'s `TomJobBase`, whose work body is **form-3 compilable pseudo-code over a later-injected abstract service class**, dispatched by `TomJobDispatcher` on the `TomCommand` / `TomExecutor` / `TomWorker` isolate-pooling substrate. `TomJobDeclaration` carries `enabled` (opt-out), `environments` (empty = every environment), `serviceUnitId` and its entity targets — `readEntities` / `writtenEntities` as `List<Type>`, with `targetEntities` the deduplicated union — on its constructor (test **b**); everything a job needs to *run* is reused from `tom_core_kernel` `tombase/scheduling/` (`codespecs_mapping.md` §5.29). |
| **3 Arguments** | `trigger` (**required**) ← `SCJOB.triggerKind` (`ScheduledJobTrigger`) onto `CsJobTrigger {cron, calendar, event}`, §5.29's three trigger kinds; required because a job with no declared trigger is a job that never runs. Per-kind slots (§2.3): `cron` ← `SCJOB-CRON.cronExpression`, `calendar` ← `SCJOB-CAL.calendarRule`, `event` ← `SCJOB-EVNT.eventName` — each a verbatim authored string, and each meaningless for the other two kinds; the SOM guarantees only one is present by promoting exactly the `@Case` subsection the discriminator selects. Policy ← `SCJOB-FAIL`, falling back to the `BJME` / `BJMM` defaults where the entry is silent: `maxRetries` (default `0` — a job retries only when the spec says so), `backoff` and `timeout` as `Duration` consts, `failureAlert` ← `SCJOB-FAIL.failureAlertMessage` as a `CsMessageKey`. `targetReports` ← `SCJOB-WORK.targetReports` as `CsReportRef` consts (default `const []` — most jobs produce no report); the CE-DB half of the same SOM form goes to the declaration, not here, since entities are `Type` literals and need no ref const (§5.23). Each lowers onto a reused `tom_core_kernel` class: the trigger onto the matching `TomSchedule` (`TomCronSchedule` / `TomCalendarSchedule` / `TomEventSchedule`) on `TomJobDefinition.schedule`, the policy onto `TomRetryPolicy` + `TomJobDefinition.timeout`, and `failureAlert` onto the message `TomJobAlert` carries to the deployment's `TomScheduler.onAlert` sink. The trigger is a **wired** schedule, not a name. |
| **4 Naming** | PascalCase of `SCJOB.jobName` + `Job` (N1). |
| **5 Locus** | `server` — work that runs *off* the request thread is the axis separating CE-JB from CE-API. |
| **6 Cross-refs** | Emits `CsJobRef`. Cites `CsServiceUnitRef` — **derived** from `SCJOB.primaryDataEntity` per the §5.17 rule, never hand-listed — plus `CsReportRef` (`SCJOB-WORK.targetReports`), `CsMessageKey`, and its target entities by `Type` (`SCJOB-WORK.readEntities` / `writtenEntities`) — typed const refs, never strings (§5.29). The two target kinds sit in different holders: reports as `@CsJob(targetReports:)`, because §5.23 makes the `Cs*Ref` family the annotation *parameter* vocabulary (where `failureAlert`'s `CsMessageKey` already sits); entities on `TomJobDeclaration`, because a `Type` literal needs nothing but `dart:core` and so leaves `tom_core_codespecs` dependency-free. |
| **7 Back-link** | `@DocSpec([DocRef('SCJOB', 'supplies the job, its trigger and its target set'), DocRef('BJME', 'supplies the execution defaults this job inherits or overrides')])`. |

---

## 4. Worked example — one SOM section to one generated file

The acceptance illustration for §2 and §3.3: a CE-DB entity, chosen because
§5.13 has the most fully verified attribute surface of any part and exercises
every universal rule at once — designated name fields, verbatim keys, member
markers, a facet value, a `Cs*Ref`, both back-link annotations and the
no-fabricated-values stub rule.

### 4.1 The input

Two SOM sections in the D06 information model. Shown as the outliner renders
them, with the field values the generator reads:

```
DataEntityEntry <!--[IMO-014]--> Customer
  entityName ......... "Customer"
  table .............. "customer"
  datasource ......... "core"
  schema ............. null            → deployment default
  description ........ "A person or organisation that places orders."

  DataAttributeEntry <!--[IMO-014-a]--> Customer name
    attributeName .... "name"
    column ........... "cust_name"
    valueType ........ String
    columnType ....... "VARCHAR"
    accessKey ........ "customer.pii"        → a CE-AZ resource key
    kind ............. value
    → DataAttributeConstraintEntry [DATAA] maxLength = 80

  DataAttributeEntry <!--[IMO-014-b]--> Signed contract
    attributeName .... "signedContract"
    column ........... "signed_contract"
    valueType ........ String
    kind ............. fileReference
    → fileReferenceOptions [DAATT-DTFR]
        keyPrefix .......... "contracts"
        cascadeDelete ...... true
        acceptedMediaTypes . ["application/pdf"]
```

### 4.2 The derivation, rule by rule

| Decision | Rule | Result |
|----------|------|--------|
| Class name | N1 designated name field `entityName`, N2/N3 | `Customer` — **not** `Cust` or `CustomerEntity`; the SOM name is the domain name |
| Table argument | §3.3.1, verbatim | `'customer'` — never re-derived from the class name |
| File path | N7 | `lib/src/data_access/customer.dart` |
| Member order | N8 | `name`, then `signedContract` — SOM document order |
| `length: 80` | §3.3.2 test **(c)** | a maximum length is not expressible in Dart, so it is an argument |
| `String` type | test **(a)** | carried by the member declaration, never repeated in `@CsColumn` |
| `accessKey` | §2.6 | `CsResourceKeyRef`, resolved by N9 against the shared CE-AZ catalogue |
| File facet | §3.3.3 | its **presence** is the column kind; `store` and `defaultMediaType` omitted → deployment defaults |
| `@CodeSpec.source` | §2.5 rule 4 | must equal the `@DocSpec` section-id set: `{IMO-014, IMO-014-a, IMO-014-b, DAATT-DTFR}` |
| Locus | §3.3.1 point 5 | `<app>_codespec_server` — CE-DB is server-only |

### 4.3 The output

`<app>_codespec_server/lib/src/data_access/customer.dart`:

```dart
// GENERATED by tom_specs codespecs generator — do not edit.
// Source document: information_model.md (D06)
// Spec model version: 1.4.0

import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:tom_core_server/tom_core_server.dart';

import '../authorization/resource_keys.dart';

/// A person or organisation that places orders.
@CodeSpec(
  'dataAccess.Customer',
  source: ['IMO-014', 'IMO-014-a', 'IMO-014-b', 'DAATT-DTFR'],
)
@DocSpec([
  DocRef('IMO-014', 'supplies the entity, its table and its storage placement'),
])
@CsTable('customer', datasource: 'core')
class Customer {
  @DocSpec([
    DocRef('IMO-014-a', 'supplies the stored attribute, its column and its storage type'),
    DocRef('DATAA', 'supplies the maximum length'),
  ])
  @CsColumn(
    column: 'cust_name',
    columnType: 'VARCHAR',
    length: 80,
    accessKey: ResourceKeys.customerPii,
  )
  late final String name;

  @DocSpec([
    DocRef('IMO-014-b', 'supplies the stored attribute, its column and its storage type'),
    DocRef('DAATT-DTFR', 'supplies the file-reference facet settings'),
  ])
  @CsColumn(
    column: 'signed_contract',
    fileReference: CsFileReference(
      keyPrefix: 'contracts',
      acceptedMediaTypes: ['application/pdf'],
    ),
  )
  late final String signedContract;
}
```

### 4.4 What the example demonstrates

- **Determinism.** Every identifier traces to a named SOM field through N1–N3.
  Re-running the generator over an unchanged document reproduces this file
  byte-for-byte — there is no timestamp in the banner and no counter anywhere.
- **No duplication.** `String` appears once (the declaration), `'customer'`
  appears once (the annotation), `'contracts'` appears once (the facet). Each of
  the three §2.3 tests is visible doing its job.
- **Compiles, does not execute.** There are no method bodies to stub here — a
  CE-DB entity is coding form 1/2. `late final` is §2.4's shape for a
  non-nullable field with no authored default: it compiles, and it throws if
  anything reads it before Phase 6 fills it in.
- **Both back-links agree.** `@CodeSpec.source` is exactly the union of the
  `@DocSpec` section ids across the class and its members — the invariant §2.5
  rule 4 makes a validator check.
- **The one ref const.** `ResourceKeys.customerPii` is a `CsResourceKeyRef`
  imported from shared. A rename in the CE-AZ catalogue is a compile break here,
  which is the entire point of §5.23's typed references.

---

## 5. Constructor-shape summary

The 39 part markers, with the shape §3 decides for each — the shape each
constructor in `tom_code_specs/lib/src/annotations/` carries. The `Cs*Ref` types
they consume ship in `cross_part_refs.dart` and the closed catalogues in
`vocabulary.dart`. Every marker keeps `String? note` as its final parameter and
it is omitted below.

### 5.1 Markers that gain arguments (24)

| Marker | Shape decided by §3 |
|--------|---------------------|
| `@CsError` | `{CsErrorSeverity severity = CsErrorSeverity.error}` |
| `@CsText` | `{required String baseCopy, CsTextRole role = CsTextRole.generic, CsTextCategory category = CsTextCategory.uiCopy}` |
| `@CsValidation` | `({String rules = ''})` — named, not positional: Dart forbids one signature carrying both optional-positional and named parameters, and every marker keeps a named `note` |
| `@CsFieldRule` | `{required CsMessageKey errorKey}` |
| `@CsFormRule` | `{required CsMessageKey errorKey}` |
| `@CsElement` | `{required CsElementKind kind}` |
| `@CsTrigger` | `{required TriggerKind kind, required CsActionRef action, CsElementRef? element, CsGesture? gesture, CsFormRef? form, CsFormEvent? formEvent, CsElementRef? formField, CsLifecycleScope? scope, CsLifecyclePhase? phase, String? channel, String? eventType}` |
| `@CsServerCall` | `(CsOperationRef operation)` |
| `@CsViewModel` | `{CsLifecycleScope scope = CsLifecycleScope.screen}` |
| `@CsLayout` | `(String nodeId)` |
| `@CsEndpoint` | `(String operation)` |
| `@CsServiceUnit` | `{required Type rootAggregate, required String boundedContext}` |
| `@CsTable` | `(String table, {String? datasource, String? schema})` |
| `@CsColumn` | `{String? column, String? columnType, int? length, CsResourceKeyRef? accessKey, CsFileReference? fileReference}` |
| `@CsAuthorize` | `{required CsAuthRequirement requirement, List<CsRoleRef> roles = const [], List<String> groups = const [], List<String> entitlements = const [], CsResourceKeyRef? resourceKey, String? handler, String? resourceId, CsGradedAccess? graded}` |
| `@CsServerConfig` | `(String key, {required CsOverridableBy overridableBy, String? envAlias, String? cmdlineAlias, bool secret = false})` |
| `@CsClientConfig` | `(String key, {required CsOverridableBy overridableBy, String? envAlias})` |
| `@CsDeviceSetting` | `(String key)` — the narrowest scope, so no `overridableBy` |
| `@CsUserSetting` | `(String key, {required CsOverridableBy overridableBy})` |
| `@CsClient` | `(String clientId, {required CsClientKind kind})` |
| `@CsIdentityAttribute` | `{required IdentityAttributePlacement placement, CsResourceKeyRef? accessKey, String? systemOfRecord, bool required = false}` — extends the shipped shape |
| `@CsMigration` | `{required String datasource, required String schema, required CsMigrationKind kind}` |
| `@CsJob` | `{required CsJobTrigger trigger, String? cron, String? calendar, String? event, int maxRetries = 0, Duration? backoff, Duration? timeout, CsMessageKey? failureAlert, List<CsReportRef> targetReports = const []}` |
| `@CsNotification` | `{required CsMessageKey body}` |

### 5.2 Markers that stay note-only (15)

`@CsEnum`, `@CsWidget`, `@CsForm`, `@CsAction`, `@CsRoute`, `@CsScreenFlow`,
`@CsRepository`, `@CsIdentity`, `@CsAuth`, `@CsAudited`,
`@CsNotificationChannel`, `@CsReport`, `@CsReportColumn`, `@CsReportChart`,
`@CsReportParameter`.

Each is note-only for a stated reason, not by omission: every attribute it might
have carried is already held by the declaration (test **a**) or by a substrate
constructor (test **b**). `@CsReport` is the clearest case — §5.28's 22-row
surface is large, and *all* of it landed on `TomReportDefinition` and its
dimension/measure members, leaving the marker nothing to hold.

`@CsEnum` is the opposite extreme and the only marker with **no substrate at
all**: there is nothing on either side of the test, because a domain enum has no
authored attribute of its own (§3.1.1, `codespecs_mapping.md` §4.1). It is
note-only *and* generates a plain `enum` for the same reason.

### 5.3 Value classes and closed enums `tom_code_specs` must add

`tom_code_specs` is annotations-only and must not depend on `tom_core` (§9.5), so
every closed catalogue a marker selects from is declared locally, mirroring its
`tom_core` counterpart where one exists.

| Type | Values | Mirrors |
|------|--------|---------|
| `CsErrorSeverity` | `info, warning, error, fatal` | `TomErrorSeverity` |
| `CsTextRole` | `error, notification, email, report, generic` | §5.21 |
| `CsTextCategory` | `uiCopy, errorCopy` | §5.21 |
| `CsElementKind` | `textInput, number, toggle, dateInput, choice, multiChoice, fileInput, label, button, menuEntry, formHost` | §5.18's eleven-kind catalogue |
| `CsGesture` | `tap, press, longPress` | §5.20 |
| `CsFormEvent` | `fieldChange, submit, validationPass, validationFail` | §5.20 |
| `CsLifecycleScope` | `screen, route, app` | §5.20, §5.4 |
| `CsLifecyclePhase` | `enter, leave, init, dispose` | §5.20 |
| `CsAuthRequirement` | `role, group, entitlement, resourceKey, custom, graded, none, public, authenticated, guest` | §5.15's six kinds + four presets |
| `CsGradedAccess` | value class `{full, read, disabled}` | §5.15's three-slot tree |
| `CsClientKind` | `flutterApp, cli, server` | §4.1 |
| `CsMigrationKind` | `initialDdl, baseData, iteration` | §5.27's three artifact kinds; SOM `MigrationArtifactKind` `{initialDdl, referenceData, schemaChange}` maps one-to-one (§3.3.5) |
| `CsJobTrigger` | `cron, calendar, event` | §5.29 |
| `CsOverridableBy` | `none, client, user, device` | §5.16's opt-in cross-scope lattice `CE-DS ▸ CE-UP ▸ CE-CC ▸ CE-CF` |

A named validator check asserts each mirror is complete: a `tom_core` catalogue
that grows without its mirror growing is a build failure, not a silent
divergence.

### 5.4 Reference types this contract consumes

All thirteen of §5.23, enumerated with their edges in §2.6. Two of them serve
this contract alone: `CsElementRef` and `CsFormRef`, both client-declared,
carrying the §5.20 trigger endpoints that §5.10 mandates be typed references
rather than id strings.

---

## 6. Validator checks this contract creates

Each is named here so the generator implements them as a check rather than as a
convention.

**Why none of them is a const-constructor `assert`.** Checks 8, 10, 14, 15 and
16 are per-instance constraints on a single annotation's arguments, so the obvious
home looks like an `assert` in the marker's const constructor. It does not work:
Dart const-evaluates a const *expression* and reports a failing assert as a
compile-time error, but it does **not** const-evaluate an **annotation**. A
violating `@CsTrigger(kind: userGesture, form: …)` therefore passes `dart
analyze` untouched — and the annotation is the only site these markers are ever
written at. An assert there would enforce nothing while reading as if it did,
which is worse than no guard, so the enforcement point is the generator's
validation pass over the resolved annotation for **all** eighteen.

| # | Check | Defined in |
|---|-------|------------|
| 1 | Identifier collisions within a locus project **fail** generation, naming both section ids | §2.1 N4 |
| 2 | Every `Cs*Ref` string resolves to a generated declaration | §2.1 N9 |
| 3 | A missing designated name field / headline **fails**, naming the section | §2.1 N1 |
| 4 | A missing authored key (message key, error code, setting key, operation name, route id) **fails** | §2.1 N5 |
| 5 | A form-3 body with an empty SOM description **fails** | §2.4 |
| 6 | No generated stub returns a fabricated value | §2.4 |
| 7 | `@CodeSpec.source` equals the `@DocSpec` section-id set | §2.5 rule 4 |
| 8 | Only the slots of a marker's declared kind are non-null (`@CsTrigger`, `@CsAuthorize`, `@CsJob`) | §2.3 |
| 9 | Every mirrored enum matches its `tom_core` counterpart value-for-value | §5.3 |
| 10 | `@CsText` with `role == error` has `category == errorCopy` | §3.1.3 |
| 11 | The shared → {client, server} dependency arrow is never inverted | §2.2 |
| 12 | A server handler's operation string equals its shared `CsOperationRef` | §3.4.2 |
| 13 | Cumulative CE-MG DDL converges on the `@CsTable` / `@CsColumn` model | §3.3.5 |
| 14 | `@CsValidation` never emits the non-declarable `compose` token | §3.2.2 |
| 15 | `overridableBy` names a scope **strictly narrower** than the marker's own — `@CsUserSetting` may open only `device`, `@CsClientConfig` only `user`/`device`, `@CsServerConfig` any; `none` is always valid | §3.3.6, §5.3 |
| 16 | A `@CsServerConfig(secret: true)` member has **no initialiser** — a secret declares presence and shape only, so a default is a credential in the source tree | §3.3.6 |
| 17 | Every `TomNotificationChannelDeclaration.fallbackChannelId` resolves to a channel declared in the same catalogue | §3.2.9 |
| 18 | Every `TomReportColumn.drillThroughRouteId` resolves to a CE-NV route declared in the **client** project | §3.3.9 |

**Checks 17 and 18 each carry a whole edge on its own.** Checks 2 and 13 back up
a compile-time or structural guarantee; these two replace one. The fallback is a
`codespecs_mapping.md` §5.23 **local coordinate**, so no `Cs*Ref` will ever make
it a compile error, and the substrate is deliberately forgiving at delivery
time — `TomNotificationCatalog.fallbackChainFrom` returns an empty chain for an
unknown id rather than throwing, on the stated grounds that a dangling fallback
is a specification defect to *report*, not a crash to suffer. This check is where
it gets reported.

A declaration **cycle** is not a violation. `fallbackChainFrom` stops at the
first channel already visited, so `a → b → a` terminates by construction; a
deployment that genuinely wants two channels to cover for each other is
expressing something coherent, and the runtime already handles it.

**Check 18 is the reverse case, and that is why it is a separate check.** The
drill-through is not a local coordinate: it is a genuine cross-part edge whose
referent *is* a Dart declaration, and §5.23 would give it a `CsRouteRef` were it
not for the **locus** rule — a server-owned report definition may not cite a
client-owned route. So the check has to look **across projects**, in the one
direction the generated dependency arrow forbids code from taking (§2.2 check
11): it resolves the id against the client project's CE-NV routes without the
server project ever depending on them. A dangling drill-through is likewise a
defect to report rather than a failure to suffer — a column whose target does
not resolve simply does not drill through.
