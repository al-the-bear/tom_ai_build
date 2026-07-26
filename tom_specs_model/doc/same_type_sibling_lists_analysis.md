# Analysis — same-type sibling `List<T>` fields and section-ID collision

**Quest:** tom_specs
**Package:** `tom_ai/ai_build/tom_specs_model`
**Created:** 2026-06-15
**Status:** Analysis / design discussion — no code change made yet
**Trigger:** "A list always implies a separate section, which must have its own ID. Scan for two lists of the same type in the same class and explain how this works out in the document structure now; think about problems and solutions."

## TL;DR

The flat, **type-scoped** `@SectionId` convention we finalized in
`section_id_pattern_plan.md` (D1.1) assigns every `List<T>` field the container
ID `'<E>-LST'` and pattern `'<E>-xxx'` derived from element type `T`'s own
`@SectionId`. When **two list fields of the same element type live in the same
class**, both fields receive the **identical** container ID and pattern. Within
a single rendered document instance, the two semantically-distinct sections then
collide on the same section IDs (e.g. in-scope vs. out-of-scope processes both
become `PRSCEN-LST` with elements `PRSCEN-001`, `PRSCEN-002`, …). The validator
does **not** catch this: §2b is *type-global* ("one `-LST` id ↔ exactly one
element type"), not *per-instance*, so two fields sharing one id is exactly the
case it tolerates.

The user's premise is correct: **a list is a distinct section and needs a
distinct ID.** For same-class siblings, the type-scoped scheme cannot provide
one.

## The scan (analyzer-based, authoritative)

Ran a scratch analyzer pass over the whole reachable model (not the line-lookback
`missing_pattern_scan.py`, which is unreliable — O6.1). **8 classes, 19 fields**
have ≥2 sibling list fields of the same element type:

| Class (`@SectionId`) | Same-type sibling fields | Shared container/pattern |
| --- | --- | --- |
| `ProcessScopeSummary` (PRSCSU) | `inScopeProcesses`, `outOfScopeProcesses` | `PRSCEN-LST` / `PRSCEN-xxx` |
| `ScopeBoundaries` | `inScopeItems`, `outOfScopeItems` | `SCITE-LST` / `SCITE-xxx` |
| `CurrentWorkflowEntry` | `steps`, `manualSteps`, `errorProneSteps` | `WSE-LST` / `WSE-xxx` |
| `CompetencyFramework` | `coreCompetencies`, `technicalCompetencies`, `leadershipCompetencies` | `COMPE-LST` / `COMPE-xxx` |
| `ChangedRoleCompetencies` | `newCompetencies`, `removedCompetencies` | `ROLCP-LST` / `ROLCP-xxx` |
| `ChangedRoleResponsibilities` | `addedResponsibilities`, `removedResponsibilities`, `modifiedResponsibilities` | `RSPCH-LST` / `RSPCH-xxx` |
| `NewRoleResponsibilities` | `primaryResponsibilities`, `secondaryResponsibilities` | `RSPDT-LST` / `RSPDT-xxx` |
| `StakeholdersAndBeneficiaries` | `primaryStakeholders`, `secondaryStakeholders` | `STKNT-LST` / `STKNT-xxx` |

Verified concretely in source — `ProcessScopeSummary`
(`current_state_analysis.dart` L926) carries both `inScopeProcesses` (L939–941)
and `outOfScopeProcesses` (L944–946), each annotated `@SectionId('PRSCEN-LST')`
+ `@SectionIdPattern('PRSCEN-xxx')`.

Note these are all **genuinely distinct sections**, not accidental duplication.
In every case the two/three lists carry opposite or partitioning semantics
(in/out of scope, added/removed/modified, core/technical/leadership,
primary/secondary, all-steps/manual/error-prone). The class deliberately wants
them as separate sections — which is exactly why each needs its own ID.

## How it materializes in the document today

For a `ProcessScopeSummary` instance the outline currently produces two sibling
sections that are **indistinguishable by ID**:

```
PRSCSU                         Process Scope Summary
├─ PRSCEN-LST                  (in-scope processes)
│   ├─ PRSCEN-001  …
│   └─ PRSCEN-002  …
└─ PRSCEN-LST                  (out-of-scope processes)   ← same container ID
    ├─ PRSCEN-001  …                                       ← same element IDs
    └─ PRSCEN-002  …
```

The only thing distinguishing the two sections is the **Dart field name**
(`inScopeProcesses` vs `outOfScopeProcesses`), which is *not* part of the section
ID scheme. The document loses the in/out distinction at the ID level entirely.

## Why §7.2's "type, not position" reasoning breaks here

§7.2 of `specs_model_outliner.md` justifies type-scoped container IDs by saying a
section ID "identifies the *type* of a section, not its position in the document
tree," and that reuse is fine because the *parent path* disambiguates. That holds
when the same element type appears in lists in **different** classes
(`CurrentWorkflowEntry.outputs` vs `WorkflowStepEntry.outputs` — different parent
instances). It **fails** for **same-class siblings**: both sections hang directly
off the *same* parent instance, so the parent path is identical too. There is no
disambiguator left — not the type, not the position, not the parent.

## Problems this creates

1. **Per-document ID uniqueness is violated.** Any consumer that assumes section
   IDs are unique within a document instance (cross-reference resolvers, anchor
   generators, diff/merge tooling) will mis-resolve or silently overwrite.
2. **`@MapsTo` / `@DetailedIn` traceability becomes ambiguous.** A downstream
   document that maps to `PRSCEN-001` cannot say *which* of the two `PRSCEN-001`
   elements it means. The whole point of the second-wave traceability work is
   defeated for these subtrees.
3. **Addressing / anchoring is ambiguous.** "Go to section `PRSCEN-LST`" has two
   answers. Deep links, review comments, and AI prompts that cite a section ID
   are non-deterministic.
4. **Render ambiguity.** A renderer driven purely by section ID cannot label the
   two sections differently; it must fall back to field names, which are not in
   the spec contract.
5. **The validator gives false assurance.** §2b passes these by design, so the
   model looks "clean" while carrying a real per-instance collision. The gap is
   structural, not a missing annotation.

## Candidate solutions (for discussion)

These are mutually exclusive options; each has a different cost/benefit. None is
implemented — surfacing for a decision.

### Option A — Field-discriminated container IDs (minimal change)

Allow same-class sibling lists to carry a **discriminated** container ID while
keeping the element-type prefix:

```dart
@SectionId('PRSCEN-LST-IN')   @SectionIdPattern('PRSCEN-IN-xxx')   List<ProcessScopeEntry> inScopeProcesses;
@SectionId('PRSCEN-LST-OUT')  @SectionIdPattern('PRSCEN-OUT-xxx')  List<ProcessScopeEntry> outOfScopeProcesses;
```

- **Pro:** smallest edit (19 fields), preserves the type prefix so "derive type
  from prefix" still works, restores per-instance uniqueness.
- **Con:** breaks the "all lists of type T share one `-LST`" invariant we just
  documented (D1.1); the discriminator suffix is a new naming sub-convention that
  must be specified; element pattern prefix is no longer simply `<E>`.
- **Validator impact:** §2b must change from "id → exactly one type" to "id →
  exactly one (type, field-role)"; add a per-class rule that same-type siblings
  must have distinct container IDs.

### Option B — Wrapper subtypes per role (most type-safe)

Forbid same-class same-type sibling lists; require a distinct element subtype per
role, each with its own `@SectionId`:

```dart
class InScopeProcessEntry  extends ProcessScopeEntry {}   // @SectionId('PRSCIN')
class OutScopeProcessEntry extends ProcessScopeEntry {}   // @SectionId('PRSCOUT')
```

- **Pro:** fully consistent with the existing flat scheme — every distinct
  section is a distinct type with a distinct ID; no new ID sub-grammar; §2b
  unchanged; traceability is unambiguous.
- **Con:** largest model change (8 classes, ~19 new subtypes); some "subtypes"
  are semantically identical to the base (in/out scope entries have the same
  fields) so it adds type boilerplate purely for ID purposes.
- **Validator impact:** add a new structural invariant *forbidding* same-class
  same-type sibling lists (turns the current silent tolerance into an error).

### Option C — Per-field section-role qualifier (annotation-level)

Keep one element type and one `-LST` base, but add a new annotation that
qualifies the section role and folds into the rendered ID:

```dart
@SectionId('PRSCEN-LST') @SectionIdPattern('PRSCEN-xxx') @SectionRole('in')  List<ProcessScopeEntry> inScopeProcesses;
@SectionId('PRSCEN-LST') @SectionIdPattern('PRSCEN-xxx') @SectionRole('out') List<ProcessScopeEntry> outOfScopeProcesses;
```

The renderer/outliner composes the effective per-instance ID as
`PRSCEN-LST#in` / `PRSCEN-001#in`.

- **Pro:** keeps the source `@SectionId` type-scoped (D1.1 intact at the
  annotation layer); makes the role explicit and machine-readable; one new
  annotation, applied only to the 19 affected fields.
- **Con:** introduces a two-layer ID (declared vs. effective); every consumer of
  IDs must learn the `#role` composition rule; new annotation in
  `tom_specs_core`.
- **Validator impact:** require `@SectionRole` on every member of a same-class
  same-type sibling group; require roles unique within the group.

### Option D — Promote siblings into a single container subtype

Replace the N sibling lists with one list of a tagged element, or one wrapper
object holding the partition:

```dart
class ProcessScopePartition {            // @SectionId('PRSCPT')
  @SectionId('PRSCEN-LST') @SectionIdPattern('PRSCEN-xxx')
  List<ProcessScopeEntry> processes;     // each entry already has scopeStatus
}
```

`ProcessScopeEntry` already has a `scopeStatus` field — in several of these cases
the in/out (or added/removed) distinction is **already a field on the element**,
so the two lists are arguably redundant modelling. Merging removes the collision
by removing the duplication.

- **Pro:** often the cleanest *data* model; eliminates the collision at the root;
  no ID-scheme change.
- **Con:** changes the document's section shape (one list instead of two) — a
  semantic change to the spec, not just an ID fix; not applicable where the two
  lists are truly independent sections the template wants rendered separately.
- **Validator impact:** none new; but each merge is a per-case modelling
  decision, not a mechanical pass.

## Recommendation (to confirm with user)

Two coherent end-states:

- If the priority is **scheme purity and unambiguous traceability**, **Option B**
  (wrapper subtypes) fits the existing flat "one type ⇒ one ID" model best and
  needs no new ID grammar — at the cost of subtype boilerplate.
- If the priority is **minimal churn**, **Option A** (discriminated `-LST`
  suffix) is the smallest correct fix, but it amends the D1.1 type-scoped
  invariant we just documented and adds a suffix sub-grammar.

**Option D** should be applied opportunistically *first* wherever the partition
is already encoded on the element (e.g. `ProcessScopeEntry.scopeStatus`,
`ScopeItemEntry` in/out), because those are genuine modelling redundancies; the
residual true-sibling cases then get A or B.

Whichever is chosen, the **validator must gain a per-class, per-instance rule**:
same-class same-type sibling lists must resolve to distinct effective section
IDs. The current §2b (type-global) is necessary but not sufficient, and its
silent tolerance is what let this through.

## Open questions for the user

1. Is per-*instance* section-ID uniqueness a hard requirement of the document
   model? (The whole analysis assumes yes — the user's premise — but it should be
   stated explicitly in `specs_model_outliner.md` if so.)
2. Preferred direction: A (suffix), B (subtypes), C (role annotation), or D
   (merge), or a mix (D-then-B)?
3. Should the validator's tolerance become an **error** (forbid the pattern) or a
   **warning** (allow with a documented discriminator)?
