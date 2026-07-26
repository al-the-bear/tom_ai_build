# Section ID Pattern Plan — fix missing `@SectionIdPattern` annotations

**Quest:** tom_specs
**Package:** `tom_ai/ai_build/tom_specs_model`
**Created:** 2026-06-15
**Status:** COMPLETE — all 10 todos done — see `section_id_pattern_plan_decisions.md`

## Problem

A structural scan (`ztmp/missing_pattern_scan.py`) found **32 `List<T>` fields**
that carry **no `@SectionIdPattern`** (and are not `@Reference`). Per the model's
ID scheme (`tom_specs_model/doc/specs_model_outliner.md` §7.2–7.3) every repeated
section (`List<T>` field) must carry:

```dart
@SectionId('<elemId>-LST')        // container section
@SectionIdPattern('<elemId>-xxx') // numbering template
List<T> field = [];
```

where `<elemId>` is the class-level `@SectionId` of element type `T`. Without
`@SectionIdPattern`, those list items get no per-element section IDs — the
"silent exemption" residue from the old hierarchical scheme (original Case 24 in
`doc/nested_lists_remodeling.md`).

## Blocker requiring a decision (do Todo 1 first)

The §7.3 claim that prefix uniqueness is "automatically satisfied" only holds when
each element type appears in **exactly one** list field. It does not here:
**16 element types are reused across >1 list field.** Among the 32 missing fields,
these reused types collide under the naive rule:

- `ProcessScopeEntry` (PRSCEN) — `inScopeProcesses`, `outOfScopeProcesses`
- `ProcessMetricEntry` (PME) — `keyMetrics`, `metrics`
- `WorkflowStepEntry` (WSE) — `manualSteps`, `errorProneSteps` (and `.steps`
  already annotated, but as `WFST`, deviating from the WSE rule)
- `WorkflowOutputEntry` (WOOUEN) — `CurrentWorkflowEntry.outputs`, `WorkflowStepEntry.outputs`
- `WorkflowBusinessRule` (WOBURU) — `CurrentWorkflowEntry.businessRules`, `WorkflowStepEntry.businessRules`
- `WorkflowInputEntry` (WOINEN) — `WorkflowStepEntry.inputs` (collides with already-annotated `CurrentWorkflowEntry.inputs`)
- `StakeholderEntry` (STKNT) — `secondaryStakeholders` (collides with annotated `primaryStakeholders`)

> **RESOLVED by Todo 1 (see `section_id_pattern_plan_decisions.md`).** The validator
> (`validator.dart` §2b) intentionally makes `-LST` IDs **type-scoped**: list fields
> of the same element type share one `<E>-LST`/`<E>-xxx` pair, which is valid and
> expected. The `DeliverableEntry` ×4 sharing of `DLVEN-LST` is therefore **correct**,
> not a deviation — do **not** change it. The only real deviation is
> `WorkflowStepEntry.steps` using `WFST` instead of `WSE` (reconcile in Todo 7).
> Consequence: the 32-field fix is **mechanical** — annotate each field
> `@SectionId('<E>-LST')` + `@SectionIdPattern('<E>-xxx')` using the element class's
> own `@SectionId`. The reused/unique distinction below no longer changes the edit.

## Todos

1. ~~Decide and document the disambiguation convention for an element type used by more than one list field.~~ **DONE 2026-06-15.** Decision: adopt the validator's existing **type-scoped** convention — every `List<T>` field uses `@SectionId('<E>-LST')` + `@SectionIdPattern('<E>-xxx')` from the element class's `@SectionId`; reused element types intentionally share IDs. `specs_model_outliner.md` §7.2/§7.3 corrected. Full rationale in `section_id_pattern_plan_decisions.md` (D1.1–D1.6, O1.1).

2. ~~Confirm the validator's actual `-LST`/`-xxx` uniqueness behaviour in `tom_specs_clitool/lib/src/validator.dart` against the §7.2 wording... scan §7.2/§7.3 for any *other* drift vs the validator and reconcile.~~ **DONE 2026-06-15.** Read `validator.dart` in full; §7.2/§7.3 already correct (Todo 1). Found and fixed 4 *other* drift points (D2.1–D2.4): validator's own docstring + §1 comment (false "-LST globally unique" / non-transitive coverage claims), `specs_model_outliner.md` §6 ("no warnings" / content "Missing = error"), and `second_wave_documents.md` §8.6 + Step 20 (`@SectionIdPattern` "globally unique"). Docs now follow the validator (D2.5). `dart analyze` clean. Full rationale in `section_id_pattern_plan_decisions.md` (Todo 2 section, D2.1–D2.5, O2.1).

3. ~~Commit the current (pre-edit) state of `tom_specs_model` and `tom_specs_clitool`, scoped to those projects only.~~ **DONE 2026-06-15.** Only pending change was an unexplained working-tree deletion of the tracked, referenced 524-line `tom_specs_model/doc/form_decomposition.md` — **restored** rather than committed (D3.1). After restore, both projects are byte-identical to HEAD `b7e924a` (the Todo 2 commit) with no untracked files, so the pre-edit checkpoint already exists and no new commit was needed (D3.2). Rationale in `section_id_pattern_plan_decisions.md` (Todo 3 section).

4. ~~Annotate the unique-element-type missing fields (no reuse — mechanical `<elemId>-LST`/`-xxx`). administrative.dart: `TeamMemberSkills.skillDetails` (TMSKE), `DocumentRelevantSections.sections` (RESEEN), `DocumentRelationships.relatedDocuments` (REDOEN), `CommitteeMemberEntry.responsibilities` (COMRS).~~ **DONE 2026-06-15.** All four annotated with `<E>-LST`/`<E>-xxx` derived from each element class's own `@SectionId` (re-verified in-file: COMRS, TMSKE, RESEEN, REDOEN). `dart analyze administrative.dart` clean; each new `-LST` id occurs exactly once in `lib/` (no §2b collision). Decisions in `section_id_pattern_plan_decisions.md` (Todo 4 section, D4.1).

5. ~~Annotate the unique-element-type missing fields in current_state_analysis.dart that have no reuse: ... (16 fields).~~ **DONE 2026-06-15.** All 16 annotated with `<E>-LST`/`<E>-xxx` derived from each element class's own `@SectionId` (all 16 re-verified in-file: PRDEEN, CPIE, WOSUEN, WODEPO, WOTREN, WOSTSY, WOSTIS, WOEXEN, MEBAEN, PPGCE, DSEE, DAOWEN, DAVOEN, DGPE, DCLE, DCSE). `dart analyze` on `lib/` clean; all 16 new `-LST` ids occur exactly once (no §2b collision). Six `@Min(1)` fields kept `@Min` (D5.1). Pre-existing, unrelated `BusinessGoals` test errors noted but out of scope (O5.1). Decisions in `section_id_pattern_plan_decisions.md` (Todo 5 section, D5.1–D5.2, O5.1).

6. ~~Annotate the reused-element-type missing fields using the Todo 1 convention: `ProcessScopeSummary.inScopeProcesses` + `outOfScopeProcesses` (PRSCEN), `ProcessPerformanceSummary.keyMetrics` + `ProcessMetricCategory.metrics` (PME), `CurrentWorkflowEntry.outputs` + `WorkflowStepEntry.outputs` (WOOUEN), `CurrentWorkflowEntry.businessRules` + `WorkflowStepEntry.businessRules` (WOBURU), `CurrentWorkflowEntry.manualSteps` + `CurrentWorkflowEntry.errorProneSteps` (WSE), `WorkflowStepEntry.inputs` (WOINEN), `StakeholdersAndBeneficiaries.secondaryStakeholders` (STKNT).~~ **DONE 2026-06-15.** 13 fields annotated (one more than listed — `CurrentWorkflowEntry.inputs`/WOINEN was wrongly assumed already-annotated by the plan; D6.2). Type-scoped convention applied mechanically; reused types share one `<E>-LST`/`<E>-xxx` pair (D6.1). `primaryStakeholders` confirmed already annotated, left untouched (D6.3). `dart analyze lib` clean; each new `-LST` maps to exactly one element type. **New deviation surfaced for Todo 7:** `items` (`List<ProcessMetricEntry>`) uses `PRME` instead of `PME` (O6.2). Scan undercounts (O6.1). Decisions in `section_id_pattern_plan_decisions.md` (Todo 6 section, D6.1–D6.3, O6.1–O6.2).

7. ~~Reconcile the pre-existing deviations surfaced in Todos 1 & 6: `WorkflowStepEntry.steps` (`WFST` vs `WSE`), the `…items` field (`List<ProcessMetricEntry>`, `PRME` vs `PME`; O6.2), and the `DeliverableEntry` four-way `DLVEN` duplicate (which is **correct** per D1.5, not a deviation).~~ **DONE 2026-06-15.** `steps`: `WFST`→`WSE` (D7.1); `items`: `PRME`→`PME` (D7.2); both now share their element type's type-scoped pair (3 fields each), valid under §2b. `DeliverableEntry` ×4 `DLVEN-LST` confirmed correct and left untouched (D7.3). `WFST` and standalone `PRME` codes eliminated from `lib/`; `dart analyze lib` clean. Decisions in `section_id_pattern_plan_decisions.md` (Todo 7 section, D7.1–D7.3).

8. ~~Run the outliner/validator on every affected document root (at minimum the CS root and any Phase 3 root reaching current_state_analysis, administrative, system_overview) and confirm zero duplicate-ID / coverage errors.~~ **DONE 2026-06-15.** Ran the outliner (→ `validateModel`, all §8.6 invariants) on **all 12 Phase 3 roots** — `grep -c "ERROR:"` = 0, all 12 outlines written (proof of clean validation; outliner `exit(1)`s before writing on any error). Only pre-existing non-blocking §6.1 `content: String?` WARNs remain (D8.3). `ProjectDefinition` root excluded — pre-existing `@ContentType` violations, CS-03 (D8.2). Decisions in `section_id_pattern_plan_decisions.md` (Todo 8 section, D8.1–D8.4).

9. ~~Extend `tom_specs_clitool/test/tom_specs_clitool_test.dart` with a test asserting that no reachable `List<T>` field lacks `@SectionIdPattern` (excluding `@Reference`).~~ **DONE 2026-06-15.** Added the rule to the validator as §8.6 invariant §2c (error tag `§8.6 @SectionIdPattern list-coverage`, surfaced via `validateStructuralInvariants`) so it guards tooling too (D9.1), plus an e2e regression test + 3 unit tests (D9.4). The check **found 2 real gaps the scan missed** — `NewRoleResponsibilities.secondaryResponsibilities` (RSPDT) and `DataQualityAssessment.improvementInitiatives` (DQIE) — now annotated (D9.2). `@Reference` is the only exemption (D9.3). `dart test` → 20/20 passed, 0 skipped; baseline `doc/baseline_0615_1001.csv`. Decisions in `section_id_pattern_plan_decisions.md` (Todo 9 section, D9.1–D9.4).

10. ~~Re-run `ztmp/missing_pattern_scan.py` and confirm it reports 0 missing fields. Run `dart analyze` on both packages, then commit and push the scoped changes to tom_specs_model and tom_specs_clitool.~~ **DONE 2026-06-15.** Scan = 0 missing (D10.1; authoritative validator e2e also = 0). `dart analyze`: clitool clean, model `lib/` clean; 2 pre-existing `BusinessGoals` **test**-file errors left as-is (O5.1/D10.2, out of scope). `last_testrun.json` not committed (transient; D10.3). All 7 tom_specs-scoped commits pushed to origin (D10.4). Decisions in `section_id_pattern_plan_decisions.md` (Todo 10 section, D10.1–D10.4).
