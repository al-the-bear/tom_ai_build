# Integration Plan — field-name-derived suffix for list section IDs

**Quest:** tom_specs
**Packages:** `tom_ai/ai_build/tom_specs_model`, `tom_ai/ai_build/tom_specs_clitool`
**Created:** 2026-06-15
**Status:** COMPLETE (2026-06-15) — user chose **universal** scope (all 433 list
fields) + interpretation X. Implemented, tested (25/25), docs updated, committed
& pushed. Decisions in `field_suffix_list_id_decisions.md` (FD1–FD8).
**Supersedes (partial):** D1.1 type-scoped sharing — see §F
**Background:** `same_type_sibling_lists_analysis.md`

## The proposal (user)

Because Dart forbids duplicate field names within a class, the field name is a
guaranteed-unique discriminator. So encode it into the list container ID:

```
<typename-derived-prefix>-<fieldname-derived-suffix>-LST     (container)
<typename-derived-prefix>-<fieldname-derived-suffix>-xxx     (pattern)
<typename-derived-prefix>-<fieldname-derived-suffix>-001…    (elements)
```

Example — `ProcessScopeSummary`:

```dart
@SectionId('PRSCEN-IN-LST')   @SectionIdPattern('PRSCEN-IN-xxx')   List<ProcessScopeEntry> inScopeProcesses;
@SectionId('PRSCEN-OUT-LST')  @SectionIdPattern('PRSCEN-OUT-xxx')  List<ProcessScopeEntry> outOfScopeProcesses;
```

This makes sibling lists distinct, solving the 8-class / 19-field collision.

## What it does and does NOT solve (be precise)

- **Solves:** same-class same-type sibling collision (the reported problem). The
  user's reasoning is exactly right — Dart's per-class field-name uniqueness ⇒
  per-class container-ID uniqueness.
- **Does NOT by itself solve:** *global* per-document flat uniqueness. The suffix
  only guarantees uniqueness **within a class**, not across classes. Three
  (element-type, field-name) pairs repeat across two co-occurring classes —
  `CurrentWorkflowEntry` and its nested `WorkflowStepEntry` both have
  `outputs` (WOOUEN), `inputs` (WOINEN), `businessRules` (WOBURU). Under the new
  scheme those become `WOOUEN-OUTPUTS-LST` in *both* classes — still identical,
  because both the type prefix and the field suffix match.
  - This only matters under **Interpretation Y** below. Under **Interpretation X**
    (which is the model the user's reasoning assumes) it is fine.

### Interpretation X vs Y — the framing question

- **X — container IDs must be unique among *siblings* (within a parent section
  instance).** Addressing a section uses parent-path + local container ID. This
  is the model §7.2 already describes ("parent path disambiguates"); the only
  bug was same-class siblings, which the suffix fixes. **The 3 cross-class pairs
  are fine** (different parent sections). ✅ Field suffix is *sufficient and
  exactly right.*
- **Y — container IDs must be globally unique within a document (flat
  addressing, no path).** Then the 3 cross-class pairs still collide and need an
  extra discriminator (e.g. fold the parent class mnemonic in). Larger change.

**The user's stated rationale ("field names must differ per Dart rules") is a
per-class guarantee → Interpretation X.** This plan assumes X. If Y is actually
required, add Todo Y (§E) — but recommend confirming X first; X matches the
existing scheme and is what the proposal naturally delivers.

## A. Scope decision (the one thing to confirm) — RECOMMENDED: sibling-only

| | Sibling-only (suffix only where a same-class same-type sibling exists) | Universal (every list field gets a field suffix) |
| --- | --- | --- |
| Fields to re-annotate | **19** (the 8 classes) | **~433** (every `@SectionIdPattern` in `lib`) |
| Suffix authoring | 19 short mnemonics | 433 short mnemonics (heavy judgement) |
| ID churn | 19 IDs change; 414 unchanged | all 433 change |
| Format uniformity | two forms (`<E>-LST` and `<E>-<F>-LST`) | one form (`<E>-<F>-LST`) |
| Regression safety | **validator errors** on any new same-class collision, forcing a suffix → not fragile | n/a (always suffixed) |
| Cross-class type sharing (e.g. `DLVEN-LST` ×4) | preserved (interpretation X) | replaced by per-field IDs |

**Recommendation: sibling-only.** The validator gains a hard rule that *errors*
when two same-class same-type lists share a container ID (§C), so "remember to
add a suffix when adding a second list later" is enforced by the build, not by
discipline — removing the only real downside of sibling-only. 19 well-chosen
mnemonics beat 433 mechanical ones, and 414 existing IDs stay put. Universal's
only edge is format uniformity, which the validator rule makes unnecessary.

## B. The 19 fields and their proposed suffixes

| Class (`@SectionId`) | Field → suffix | New container / pattern |
| --- | --- | --- |
| `ProcessScopeSummary` (elem PRSCEN) | `inScopeProcesses`→`IN`, `outOfScopeProcesses`→`OUT` | `PRSCEN-IN-LST`/`-IN-xxx`, `PRSCEN-OUT-LST`/`-OUT-xxx` |
| `ScopeBoundaries` (elem SCITE) | `inScopeItems`→`IN`, `outOfScopeItems`→`OUT` | `SCITE-IN-*`, `SCITE-OUT-*` |
| `CurrentWorkflowEntry` (elem WSE) | `steps`→`STP`, `manualSteps`→`MAN`, `errorProneSteps`→`ERR` | `WSE-STP-*`, `WSE-MAN-*`, `WSE-ERR-*` |
| `CompetencyFramework` (elem COMPE) | `coreCompetencies`→`CORE`, `technicalCompetencies`→`TECH`, `leadershipCompetencies`→`LEAD` | `COMPE-CORE-*`, `COMPE-TECH-*`, `COMPE-LEAD-*` |
| `ChangedRoleCompetencies` (elem ROLCP) | `newCompetencies`→`NEW`, `removedCompetencies`→`REM` | `ROLCP-NEW-*`, `ROLCP-REM-*` |
| `ChangedRoleResponsibilities` (elem RSPCH) | `addedResponsibilities`→`ADD`, `removedResponsibilities`→`REM`, `modifiedResponsibilities`→`MOD` | `RSPCH-ADD-*`, `RSPCH-REM-*`, `RSPCH-MOD-*` |
| `NewRoleResponsibilities` (elem RSPDT) | `primaryResponsibilities`→`PRI`, `secondaryResponsibilities`→`SEC` | `RSPDT-PRI-*`, `RSPDT-SEC-*` |
| `StakeholdersAndBeneficiaries` (elem STKNT) | `primaryStakeholders`→`PRI`, `secondaryStakeholders`→`SEC` | `STKNT-PRI-*`, `STKNT-SEC-*` |

Suffixes are **hand-authored short mnemonics** (same philosophy as the class
`@SectionId` codes), not an algorithmic transform — keeps IDs short/readable.
The validator enforces *per-class uniqueness*, which is the actual invariant; it
does not need to verify a derivation formula.

## C. Validator changes (`tom_specs_clitool/lib/src/validator.dart`, §2b)

Current §2b enforces: "a given `-LST` id maps to exactly one element type"
(type-consistency) and *tolerates* many fields → one id (type-scoped sharing).

Change to:
1. **Keep** type-consistency (a container id still maps to exactly one element
   type — `PRSCEN-IN-LST` is only ever `ProcessScopeEntry`).
2. **Add** *per-class container-ID uniqueness*: within a single class, no two
   list fields may share a container `@SectionId`. Error tag e.g.
   `§8.6 @SectionId per-class uniqueness`. This is the rule that makes the whole
   scheme self-enforcing.
3. **Keep** cross-class sharing allowed (two *different* classes may share
   `<E>-LST` — interpretation X).
4. (Optional, recommended) **Add** a pairing check: a field's
   `@SectionIdPattern` prefix must equal its `@SectionId` container prefix
   (`<E>-<SUF>-LST` ↔ `<E>-<SUF>-xxx`).

§2c (list-coverage) and §1 (pattern coverage) are unchanged.

## D. Documentation changes (`tom_specs_model/doc/specs_model_outliner.md` §7.2/§7.3)

- Replace the "all `List<DeliverableEntry>` fields share `DLVEN-LST`" cross-class
  example framing with: container IDs are `<E>[-<FIELDSUF>]-LST`; the field
  suffix is **required** when a class has >1 list of the same element type and
  **omitted** otherwise; cross-class sharing of the bare `<E>-LST` remains valid.
- State the invariant: container IDs are unique **within a class**; document
  addressing is parent-path + local ID (interpretation X).
- Note the suffix is a hand-authored short mnemonic derived from the field name.

## E. (Conditional) Todo Y — only if Interpretation Y is required

If full per-document flat uniqueness is mandated, additionally disambiguate the
3 cross-class pairs (`outputs`/`inputs`/`businessRules` in `CurrentWorkflowEntry`
vs `WorkflowStepEntry`) — e.g. prefix the parent class mnemonic — and tighten the
validator rule from per-class to global container-ID uniqueness. **Do not do this
unless the user confirms Y.**

## F. Decision-log / D1.1 reconciliation

D1.1 ("type-scoped sharing") is **narrowed, not deleted**: cross-class sharing of
`<E>-LST` stays valid; *within-class* sharing of same-type lists is now
forbidden and must carry a field suffix. Record this in
`section_id_pattern_plan_decisions.md` (or a new decisions file for this plan).

## Todos

1. Confirm scope (§A: sibling-only ✓ recommended) and interpretation (§X ✓
   recommended). [needs user]
2. Re-annotate the 19 fields per §B (38 string edits across
   `current_state_analysis.dart`, `organizational_framework.dart`,
   `system_overview.dart`). `dart analyze lib` clean.
3. Update validator §2b per §C (per-class uniqueness error + optional pairing
   check). Export already covers `validateStructuralInvariants`.
4. Update tests in `tom_specs_clitool_test.dart`: flip the type-scoped-sharing
   expectation to assert *same-class* sharing is an error; add per-class
   uniqueness unit tests + an e2e regression. `testkit :test` green; new
   baseline.
5. Update `specs_model_outliner.md` §7.2/§7.3 per §D.
6. Run the outliner on all 12 Phase 3 roots; confirm 0 ERROR lines and that the
   8 affected classes now render distinct sibling section IDs.
7. Record the D1.1 narrowing (§F). Commit scoped to `tom_ai_build` (model +
   clitool) and `_ai` (quest docs); push.
8. (Conditional) Todo Y (§E) only if the user selects interpretation Y.

## Effort summary

~19 fields (38 annotation strings), one validator block, a handful of tests, one
doc section. Outliner/renderer: **no code change** (it prints `@SectionId`
strings verbatim; confirmed `outline_writer.dart` contains no `-LST`/`-xxx`
logic). No external references to the changed IDs exist (`@MapsTo`/`@DetailedIn`
take *class* arguments, not ID strings; the affected ID strings appear only where
declared). Low-risk, half-day mechanical change once §A/§X are confirmed.
