# CodeSpecs Starting Prompt

**Quest:** tom_specs · **Status:** normative — the single prompt that initiates
a Phase-4 run

**Authority for: how a Phase-4 run starts, and when it refuses to.** This
document holds one text — the **starting prompt** — plus the gate that text runs
before it does anything else. `codespecs_mapping.md` §1.1.2 says a run has six
stages; this document is stage 0. `codespecs_derivation_contract.md` §2.9 holds
the *other* Phase-4 prompt, the one that carries a single authoring step; the two
never overlap, because this one produces todos and no code, and that one produces
code and no todos.

**The gate is the prompt's first act, not a review after it.** PF-PHA-P4 defines
Phase 4 and PF-GAT-G4 reviews its output; between them there was nothing that
looked at the *input*. A specification with holes does not produce code with
holes — it produces code with **inventions**, because an agent filling a gap
fills it plausibly. A gap that stops the run is cheap. A gap that is silently
filled surfaces in Phase 6, after tests have been derived from the invention.

**Citing.** This document follows `index.md`'s convention: a bare `§N` is a
section of this file, `SOM §N` is `som_multiplatform_spec_model.md`, and every
other document is cited by file name plus section. `tom_specs_project_flow.md`
is cited by its `PF-*` section ids, which are not `§` citations.

---

## 1. What a run is handed, and what it hands back

A Phase-4 run is started by pasting §8's prompt with its placeholders bound. The
run is over a **specification document** — one filled TomSpecs document tree,
rooted at its own document root (`D00SolutionBlueprint` for a Solution
Blueprint) — and a **target trio** of project names per `codespecs_mapping.md`
§4.2.

The prompt executes three stages, in order, and stops at the first failure:

| Stage | Does | Fails how |
|-------|------|-----------|
| **A · Mechanical** (§4) | Runs every check a program can decide, over the document alone | Rejection, before a single area is read |
| **B · Per-area judgment** (§6) | For each of the 26 active areas of `codespecs_mapping.md` §4.1, reads that area's extract and returns one of three verdicts | Rejection, naming the missing inputs area by area |
| **C · Instantiation** (§7) | Creates the L0/L1/L2 rungs of `codespecs_mapping.md` §1.1.3's todo tree | — |

Between A and B sits the **pre-gate extraction run** (§5): stage B judges
extracts, so the extracts must exist before it. This does not reorder
`codespecs_mapping.md` §1.1.2's stages — the extraction there is stage 1, and
this is the same operation performed once early, over the same input, by the same
nine-runtime surface. If the run passes, stage 1 reuses these extracts rather
than recomputing them.

**On success the run has written no code.** It has written todos, and the queue
is paused on them by construction (§7).

## 2. Why the gate is per area, and why it names gaps

Two properties do all the work.

**Per area, not per document.** A verdict over a whole specification has one bit
of information and no starting point. A verdict per area is 26 bits, each
attached to a bounded body of text the reader can open. It is also the only
granularity at which the third verdict exists at all: a project with no
background jobs is not underspecified about background jobs, and a
whole-document verdict has no way to say so.

**Named gaps, not a grade.** A rejection that says *underspecified* and nothing
more sends the user back to a 652-section document with no starting point. The
output shape §6.3 fixes therefore carries, per missing input, the **section that
should have carried it** — which is exactly the coordinate the editor navigates
by, and exactly what an L0 todo needs to state.

The gate is deliberately **cheap to fail and expensive to pass**. Failing costs
one paste and produces a work list. Passing commits the project to a run whose
output Phases 5 and 6 read *instead of* the specification
(`codespecs_mapping.md` §9.6), so a gap that gets through the gate is a gap no
later phase is looking for.

## 3. Mechanical first, and not re-litigated by reading

Everything decidable by machine runs in stage A and is **not** asked again in
stage B. Two reasons, and the second is the load-bearing one:

1. A program is cheaper and does not tire on section 400.
2. An agent asked to re-decide a mechanical question will sometimes decide it
   differently, and a gate whose verdict depends on which day it ran is not a
   gate. Stage B's question (§6.1) is therefore phrased so that no mechanical
   fact is inside it.

Stage A's results are not discarded at the boundary — they are **handed to stage
B as input**. Where the instance-tier validator has already named eleven
unresolved message-key lookups, stage B does not rediscover them; it reads them
as evidence about the area they were routed from (§10.1 is exactly this case).

## 4. Stage A — the mechanical tier

Five checks. Each is a hard rejection; the run reports all five results rather
than stopping at the first, because a project fixing one will want to see the
rest.

### 4.1 A1 — the document is complete against its schema

Validate the document's Markdown rendition against its generated DocSpecs schema
(SOM §13). This is the **completeness** check: it is what reports a required
form field that carries no value.

### 4.2 A2 — the document's values are valid

Run the runtime `validateDocument` (SOM §9) over the document. This is the
**instance tier**: every set path resolves to a node of a compatible kind, every
form sub-key names a real form field, every populated list meets its `@Min`, and
every typed reference resolves against its registry.

**A1 and A2 are both required, and neither implies the other.** They ask
disjoint questions, and the gap between them is precisely where an underspecified
project hides. `validateDocument` is explicitly not a completeness check — a
mandatory-but-absent node is not a value, so it holds no value that could be
invalid. Conversely the schema validator sees a filled field and asks nothing
about what it points at, so a reference into an empty registry passes it. §10.2
measures both halves of this on a real document: gutting four required form
fields moves A1 from 0 violations to 4 and moves A2 not at all.

### 4.3 A3 — the routing is total

Every section class reachable from the document root carries a routing verdict —
`@CodeSpecKind`, `@FollowUpKind` or `@NoArtifact` — which is
`tom_specs_model_rules.md` §10.2 invariant `ROUTE-TOTAL`.

This is checked **at runtime, over this document's own walk**, not only by the
model's static validator. Both tiers now walk the same shape — from every
`@Document` root, stopping at each `@FollowUpKind` — so a class is exempt only on
the paths that actually pass through a follow-up root. The runtime walk remains
the authority, because it is the walk the extraction run performs: a class it
reaches without a verdict would route nowhere and be silently absent from every
extract, whatever the static tier concluded.

Keeping A3 a *runtime* check is therefore not redundancy. The static tier decides
over the model's types, once, at generation time; A3 decides over **this
document's own instance tree**, which is the thing the extract is built from. A
model can pass `ROUTE-TOTAL` and a document still present a node the walk reaches
by a path the model's shape permits but no committed sample exercised.

### 4.4 A4 — every required marker argument has a source with content

For each part the project uses, take its `Cs*` markers' **required** arguments —
`codespecs_derivation_contract.md` §5.1 fixes their shapes and
`codespecs_derivation_contract.md` §3 their per-argument derivation — resolve
each to the SOM field it derives from, and check that the field is populated in
this document.

"For each part the project uses" is not circular with stage B: A4 runs over the
parts whose extracts are **non-empty**, which is a fact about the extraction run
and not a judgment. An area whose extract is empty has no elements and therefore
no required arguments to satisfy; whether that emptiness is legitimate is stage
B's question, not A4's.

A4 checks that the *document* fills the source field. Where the **model** offers
no field a required argument could resolve against, no document can pass and the
defect is not the project's: those cases are `codespecs_mapping.md` §10's index,
and a project using an affected part inherits that document's status rather than
receiving a rejection here.

### 4.5 A5 — no structured carrier is missing from the model

Several places in the model carry an explicitly structured field because prose
was found where structure was required. A5 checks that the **model** still offers
those carriers — not that every instance fills them.

That distinction is the whole content of the check. Most of the carriers were
added *additively*, with a documented fallback: an element that does not carry
the structure emits form 3a (`codespecs_derivation_contract.md` §2.4) rather than
failing. For those, absence in an instance is legitimate output and A5 has
nothing to say about it. What would be a defect is a model that no longer offers
the carrier at all — a project that *did* have the structured fact would then
have nowhere to put it and would write prose again, which is the condition the
carriers were introduced to end. A5 is therefore a check against the generated
meta rather than against the document, and it fails only when a carrier has been
removed.

## 5. The pre-gate extraction run

Run the nine-runtime `spec_codespecs_extract` surface
(`codespecs_mapping.md` §1.1.1 item 2) over the document, producing one extract
per active area at `codespecs_mapping.md` §1.1.1 item 1's location and names.

**The walk root is the specification document's own root**, and the extractor
resolves it once when it is constructed — so this is an API guarantee rather than
an instruction an operator has to remember. It takes an optional `rootType`
naming that root by type name or by section id; omitted, it defaults to the
document's single **populated** root, falling back to the model's only root when
the document is empty. Anything that does not resolve to exactly one root is a
`CodeSpecsExtractError` from the constructor: an unknown `rootType`, more than one
populated root, an empty document over a multi-root model, or a `rootType` that
holds no value while another root does.

Two wrong choices are worth naming because both look right, and because naming
them is what the API shape was chosen to close:

- **Every `@Document` root.** The D01–D12 projections re-enter subtrees that the
  D00 walk skips because a `@FollowUpKind` root sits above them, so a union walk
  reaches follow-up content by a path that carries no verdict and A3 rejects the
  run for a routing failure that is an artifact of the walk, not of the document.
  There is now no way to ask for that walk — the extractor has one root, not a
  list.
- **`D13CodeSpecsProjection`.** It is the CodeSpecs projection, so it reads like
  the right root for a CodeSpecs extraction. Its path space is `CGP/…` while the
  document's values are keyed under its own root, so every extract would come
  back empty — 26 areas, zero entries, and a run that would pass stage B only by
  declaring the entire project not applicable. This is the failure mode a bare
  required-root argument would leave intact, so it is the one the resolver
  reports: naming a root the document never populates is an error, not an empty
  result.

The extraction run is **not** a gate stage. Its own failures — an unrouted class,
a malformed catalogue — surface as A3 or as a tooling error, and a tooling error
is not a verdict about the specification.

## 6. Stage B — the per-area verdict

### 6.1 The fixed question

For each active area, exactly one question is asked, and it is asked in these
words:

> **Does this extract, alone, carry every input `codespecs_derivation_contract.md`
> §3 requires to author this area?**

Three properties of that phrasing are deliberate.

- **"This extract, alone."** It is the authoring agent's actual situation
  (`codespecs_derivation_contract.md` §2.9: *"Do NOT open the Phase-3
  specification documents"*). A judgment made with the whole document open would
  approve an area whose facts live somewhere the authoring agent will never look.
- **"Every input the derivation contract requires."** The bar is a written
  contract, not an impression: `codespecs_derivation_contract.md` §3 lists per
  marker what feeds it, and the judgment is a lookup against that list.
- **Nothing about quality, length or style.** Whether a description is *good* is
  not asked, because the answer varies by reader and by day. Thin prose is not a
  gap; a **missing input** is.

### 6.2 The three verdicts

| Verdict | Means | Run continues? |
|---------|-------|----------------|
| **sufficient** | Every input `codespecs_derivation_contract.md` §3 requires, for every element in the extract, is present | yes |
| **not applicable** | This project has no elements of this area at all | yes |
| **insufficient** | At least one required input is absent | **no** |

### 6.3 The output shape

Fixed, so that *sufficient* means the same thing on two different days:

```text
<CE-CODE>  <verdict>
```

and for `insufficient` only, one line per missing input:

```text
  <section-id> — <what the derivation contract required> — should have been carried by <section-id>.<field>
```

The trailing coordinate is the point of the line. It is what the user opens, and
it is verbatim what the L0 todo created for it states.

### 6.4 An empty extract is a candidate, never the verdict

*Not applicable* is the verdict most likely to be reached by accident, because
its mechanical shadow — an extract with zero entries — is easy to observe and
means less than it appears to.

Zero entries has two causes, and they are opposites: the project has no elements
of this area, or the project has them and **routed them nowhere**. The second is
the more common failure in a young specification and is exactly what the gate
exists to catch, so the run may never conclude *not applicable* from emptiness
alone. It must find positive evidence of absence, and the evidence available is
mechanical:

- **Stage A2's dangling references.** An unresolved reference *into* an area's
  registry is proof the project has elements of that area — the referring
  section is asking for one. §10.1 is this case: an area whose extract is empty
  while eleven sections hold unresolved lookups into it is **insufficient**, and
  the verdict names the registry section that should have carried the entries.
- **Cross-area citation.** `codespecs_mapping.md` §4.4.3's `cites` edges say
  which areas an area's parts reference. An area cited by a populated area's
  entries has elements.

Absent both, an empty extract is *not applicable*, and the run says so per area
rather than silently.

## 7. Stage C — instantiating the todo tree

On pass, the prompt creates the todo tree's upper rungs per
`codespecs_mapping.md` §1.1.3, using ids from `tomAi_generateIdPrefix` per
`CLAUDE.md`:

| Rung | Created | From |
|------|---------|------|
| **L0** `csopen<n>` | one per open question the gate surfaced, all `decision-needed` | stage B's insufficient lines, plus any question raised at stage A that a reading resolved into a decision rather than a defect |
| **L1** `csproj<n>` | the trio scaffolding | `codespecs_mapping.md` §4.2 alone |
| **L2** `csgen<n>` | the thirty-one authoring steps | `codespecs_mapping.md` §4.4.6's step table alone |

**Why L1 and L2 are created here even though the run "stops at L0".** They are
document-independent — `codespecs_mapping.md` §1.1.3 derives them from
`codespecs_mapping.md` §4.2 and `codespecs_mapping.md` §4.4.6, neither of which
varies by project — so there is nothing to learn by deferring
them, and creating them makes the whole run visible in the todo panel from the
start. The stop is not achieved by withholding them. It is achieved by L0 being
`decision-needed`: `CLAUDE.md` rules that `<prefix>*` iteration refuses a
`decision-needed` todo and pauses the queue, so `csopen*` must be exhausted
before `csproj*` or `csgen*` can be reached. The queue pauses for the user **by
construction rather than by accident**, which is the property that matters.

L3 is not created here. `codespecs_mapping.md` §1.1.3 makes each L2 todo create
its own L3 rung as that todo's first act, from its own extracts and
`codespecs_mapping.md` §4.4.8's order — so an L3 rung is never built from a stale
extract.

A run that passes with **no** insufficient areas creates no L0 todos at all. The
queue then starts at `csproj*` and is not paused — which is the correct outcome
for a specification that is genuinely complete, and is rare enough on a first run
that it is worth double-checking the walk root (§5) before believing it.

## 8. The prompt

### 8.1 Placeholder binding

Every placeholder is read off something this design already fixes; none is
composed.

| Placeholder | Bound from | Which is |
|---|---|---|
| `<DOC>` | path to the filled specification document | the run's input |
| `<ROOT>` | its document root type | §5 — the document's own root, never all fourteen and never `D13CodeSpecsProjection` |
| `<EXTRACTS>` | the extract folder | `codespecs_mapping.md` §1.1.1 item 1 fixes name and location |
| `<AREAS>` | the active-area catalogue | `codespecs_mapping.md` §4.1, as `generated-doc/codespecs/codespecs_areas.json` |
| `<TRIO>` | the three target project names | `codespecs_mapping.md` §4.2 |

### 8.2 The prompt text

```text
You are the Phase-4 starting agent for the specification at <DOC>, root <ROOT>.
You will create todos. You will not write a line of CodeSpecs code.

FIRST — the quality gate. Run it before creating any todo.

STAGE A — mechanical. Run all five, report all five, and reject on any:
  A1  The document validates against its generated DocSpecs schema
      (completeness — a required field with no value).
  A2  The document passes the runtime validateDocument (values — kinds, form
      keys, list minima, reference resolution).
  A3  The routing is total over THIS document's walk: every reachable section
      class carries @CodeSpecKind, @FollowUpKind or @NoArtifact
      (tom_specs_model_rules.md §10.2 invariant ROUTE-TOTAL).
  A4  Every required Cs* marker argument, for every part with a non-empty
      extract, resolves to a populated source field
      (codespecs_derivation_contract.md §5.1 and §3).
  A5  The model still offers every structured carrier; a documented fallback
      in an instance is output, not a gap (§4.5).
  A mechanical failure is a rejection. Do not read a single area.

THEN — extract. Run spec_codespecs_extract over <DOC> at root <ROOT>, writing
  one extract per active area of <AREAS> into <EXTRACTS>. Walk from <ROOT> and
  from nothing else (§5 names the two wrong roots and what each does).

STAGE B — per area. For each active area, read that area's extract and answer
  exactly this question, in these words:
      Does this extract, alone, carry every input
      codespecs_derivation_contract.md §3 requires to author this area?
  Answer with one of exactly three verdicts:
      sufficient       — every input that contract requires is present
      not applicable   — this project has no elements of this area
      insufficient     — at least one required input is absent
  Output shape, one line per area:
      <CE-CODE>  <verdict>
  and for insufficient only, one line per missing input:
      <section-id> — <what the derivation contract required> — should have
      been carried by <section-id>.<field>

  An empty extract is a CANDIDATE for "not applicable", never the verdict.
  Before concluding it, look for positive evidence that the area has elements:
  an unresolved A2 reference into the area's registry, or a cites edge from a
  populated area (codespecs_mapping.md §4.4.3). Either makes it insufficient.

  Do not re-decide anything stage A decided. Do not judge prose quality,
  length or style. Thin prose is not a gap; a missing input is.

ON REJECTION:
  Hand back the stage-A results and the per-area table with its gap lines.
  Create no todos. The gate has produced the work list; that is its output.

ON PASS — create todos, and stop:
  L0  csopen<n>, status decision-needed, one per gap line, stating the section
      id and the input the derivation required, verbatim from stage B.
  L1  csproj<n> for the <TRIO> scaffolding (codespecs_mapping.md §4.2).
  L2  csgen<n> for each of the thirty-one authoring steps, <n> its ordinal
      (codespecs_mapping.md §4.4.6).
  Take every id from tomAi_generateIdPrefix. Create no L3 todos: each L2 todo
  creates its own as its first act (codespecs_mapping.md §1.1.3).

NEVER:
  - Fill a gap. A plausible value is the one failure mode this gate exists for.
  - Soften "insufficient" to "sufficient with notes". There are three verdicts.
  - Conclude "not applicable" from an empty extract without §6.4's evidence.
  - Start an authoring step. codespecs_derivation_contract.md §2.9 carries
    those; this prompt hands them their todos and stops.

HAND BACK:
  - The stage-A results, all five.
  - The per-area table, all 26 rows, with gap lines beneath any insufficient.
  - The todos created, by rung.
```

### 8.3 What the prompt deliberately does not carry

It states no derivation rule, no naming rule and no part catalogue inline — it
cites them, for the reason `codespecs_derivation_contract.md` §2.9 gives about
its own prompt: an inlined rule is a second place the rule lives, and the two
copies drift silently.

It also carries **no threshold, no score and no rubric**. A gate with a numeric
bar invites tuning the bar instead of the specification, and a rubric an agent
scores against is a rubric it can satisfy while the input stays unusable. The
question of §6.1 is binary against a written contract, which is the only shape
that means the same thing twice.

## 9. What the gate does not do

Naming the non-goals keeps the gate from growing into a review.

- **It does not judge whether the specification is *right*.** Only whether it
  carries what Phase 4 reads. A completely specified system that solves the wrong
  problem passes this gate; that is PF-GAT-G3's question and a human's.
- **It does not review generated code.** There is none. Reviewing Phase 4's
  output is PF-GAT-G4, and its self-sufficiency criteria are enforced by
  `codespecs_derivation_contract.md` §6's checks 32 and 34–36
  (`codespecs_mapping.md` §9.6).
- **It does not answer its own questions.** An L0 todo is `decision-needed` and
  waits for the user. An agent that answers one has re-created the invention the
  gate exists to prevent, one level up.
- **It does not run twice per project.** It runs when Phase 4 starts. A
  re-entry after a specification change (PF-ITR-REE) re-runs it, because the
  input changed; a mid-run question does not, because
  `codespecs_mapping.md` §1.1.3 already routes mid-run questions to `csopen<n>`
  directly.

## 10. Worked fixtures

Both cases are measured against shipped artifacts, not asserted.

### 10.1 A project that genuinely uses none of an area

Two independent fixtures carry this case.

**The conformance corpus.** `tom_som_conformance`'s extract cases ship two areas
with `entries: []` over the DEMO document, verified identically by all nine SOM
runtimes. Emptiness is therefore a first-class, cross-language outcome of the
extraction surface and not a Dart accident.

**The Meridian sample.** Extracting the shipped
`meridian_order_management` Solution Blueprint from `D00SolutionBlueprint` walks
327 classes and yields **627 entries across 11 areas**, leaving **15 areas with
zero entries**. Most are correctly *not applicable* — the sample specifies no
migrations, no background jobs and no reporting, and the run says so per area.

One of the fifteen is **not** — and it is the fixture that makes §6.4 necessary.
The message-key area's extract is empty while stage A2 reports **eleven
unresolved `MSGKE.key` lookups** from screen sections. Those eleven sections are
asking for message keys that the registry does not carry. The correct verdict is
therefore **insufficient**, with eleven gap lines naming `MSGKE` as the section
that should have carried them — and the evidence for it came out of stage A, not
out of re-reading the document, which is §3's point.

### 10.2 A deliberately gutted specification is rejected

Take the same sample and clear the four `aggregateRoot` form fields — one
required structured field, populated as shipped.

| | as shipped | gutted |
|---|---|---|
| **A1** — DocSpecs schema (completeness) | **0** violations | **4** violations, each `missingRequiredField [DAENT-CLAS] — required form field "aggregateRoot" of "daent-clas-form" is missing` |
| **A2** — `validateDocument` (values) | 23 violations | **23** violations — unchanged |

The gutted document is rejected at A1 before any area is read, which is the DONE
condition. The row that matters more is the second one: **A2 does not move.**
Clearing a required field removes a value, and a validator that checks values
has nothing left to object to. A gate built on `validateDocument` alone would
have passed this document and handed the authoring agent four aggregate roots to
invent. That is why §4.1 and §4.2 are two checks and not one.

(The 23 standing A2 violations on the sample as shipped — 22 dangling references
and one `oneOfCaseMismatch` — are a real finding about that sample, tracked in
`_ai/quests/tom_specs/todos.tom_specs.todo.yaml`. Eleven of them are §10.1's
message keys. The sample is gated on its DocSpecs schema and has never been gated
on the instance tier, which is precisely the blind spot §4.2 closes.)
