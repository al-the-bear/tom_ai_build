## 1.6.17

- No model change. The chain moves with the runtimes, which gain writing
  changes as inline marks (SOM §11.9.3: `markChangeText`, `setMarked`,
  `markAgainst`).

## 1.6.16

- No model change. The chain moves with the runtimes, which gain the review of
  inline marks (SOM §11.9.3): listing marks with revision-stable ids,
  deciding them mark by mark (accept / reject / leave, with a stale revision
  refused), accepting or rejecting all under a path, and removing all
  annotations. Accept and reject follow the whitespace rules.

## 1.6.15

- No model change. The release aligns the model chain with the runtimes,
  which gain the review-annotation API (SOM §11.9: comment blocks, question
  blocks and CriticMarkup inline marks in content values) and the
  `annotationMisplaced`, `annotationMalformed` and `duplicateAnnotationId`
  findings. SOM §11.9 and `tom_specs_project_flow.md` PF-ITR-REV document
  the notation and the review round.

## 1.6.14

- Every reference field states whether it holds one id or several
  (`Field.multiple`, `tom_specs_model_rules.md` §6.2 rule 3): 68 list-valued
  reference fields are marked `multiple` — those whose hint or name says
  several ids, and four that documents showed to hold lists (a UAT scenario's
  interactions, an acceptance criterion's scenarios and deliverables, a
  responsive rule's screens). Requires `tom_specs_core` 0.4.0.

## 1.6.13

- Documentation: SOM §9 names the instance-tier `missingRequiredField` check;
  the model is unchanged.
- This file now carries the entries for 1.6.5 to 1.6.12, which those
  releases shipped without.

## 1.6.12

- Fields a pre-release, gate-driven plan cannot state are optional
  (`tom_specs_model_rules.md` §6.2.7): target dates of business goals and goal
  milestones; planned dates of stages, stage summaries and migration phases,
  and a stage's go-live date; every `minVersion` / `minimumVersion`; current
  active users and current data volume. Their hints accept a gate or a version
  policy and say empty means not yet known.
- The existing-system compatibility list (`LCE-LEGA-LST`) is described for
  predecessors and systems running beside the solution; audit-date hints
  allow "none yet" and a gate.

## 1.6.11

- `ScheduledJobTrigger.interval` with the `SCJOB-INTV` case (ISO 8601 period,
  optional anchor), mirroring `CsJobTrigger.interval` (`tom_code_specs`
  0.16.0).

## 1.6.10

- Members the domain needed: a RACI matrix (`RACIEN`) and policy ownership
  (`POLOWN`); operation controls (`SVOCT`); bounded-context owned operations
  and relationships (`CTXREL`); a database connection budget (`SRSDB`); key
  management (`KEYMGT`); application-node and database-server counts; an
  attribute's OpenID release (`USOIDC`); a role's membership source; a locale
  variant's review status; test levels (`TSLVL`); maintenance procedures as
  headlined entries (`MAPRO`, ids `MAPRO-PROC-…` replacing `SO-MAIN-…`).
- Not modelled, with reasons in `tom_specs_model_rules.md` §6.2.6.

## 1.6.9

- One home per fact (`tom_specs_model_rules.md` §6.2.5): places that held a
  copy of a fact refer to its home (`keyRiskRef`, `migrationRiskRef`,
  `userCategoryRef`, `stakeholderRefs`, `libraryRef`, `componentRef`,
  `protocolComplianceRef`, `environmentRef`, `browserRef` / `osRef` /
  `platformRef`, `standardRef`, `alertRuleRef`, `SDR-DECI-REF`,
  `SYARSP-DECI-REF`); data-protection classification levels and a migration
  phase's stage resolve. The MoSCoW analysis's tier and stage and the
  feature-stage matrix's stages are removed.

## 1.6.8

- Enum-like free text is typed: new enums `AlertSeverity`,
  `ConstraintEnforcement`, `OverridableBy`, `ConfigValueType`,
  `DecisionState`; alert, maintenance, role-rule, configuration, quality,
  process-exception, pipeline-timeout and network-flag fields use them (or
  `ImportanceBand`, `Probability`, `Impact`, `Iso25010Characteristic`, `int`).

## 1.6.7

- Counts and derived values are checked: `countOf` on the success-criteria
  summary, use-case step and extension counts (`./` scope), the must-pass
  count and the feature-dependency totals (`crossStageDependency` became a
  `bool` with `crossStageNote`); `productOf` on six risk scores and `rankOf`
  on the key-risk ranking. Requires `tom_specs_core` 0.3.0.

## 1.6.6

- References accept the registries the domain needs (`protocolErrorCodes`,
  wider risk targets, `proposedEnum`, `failureAlert`, wider prototype-feature
  and field-help targets).

## 1.6.5

- The access-handler catalogue (`AZHAN`); a custom authorization requirement
  names its handler from it.

## 1.6.4

- Links to the right registry (tom_uam findings): IOE gains `serverOperation`
  (`SVOPE.operationName`) beside the exposed `operationId`; the
  function-to-data matrix entry gains `functionRef` (`FUNCT`) and its
  `entityName` resolves (`DAENT.entityName`); DAATT-SECU `sensitivityLevel`
  names a data classification (`DCLSE`); a module's `owningContext` names
  bounded contexts (`BCE.contextName`, empty for a platform module); a component
  gains `libraryRef` to its framework or library (`FRREEN` / `THPALI`); a
  component risk may name several components; FAMREF `componentId` names a UI
  component (`UICOM`, not `CMPNT`); a screen gains `serverOperations`, a report
  `exportOperation` and `displayScreen` (`SCREN`); a report filter's
  `entityType` names an entity; a quality weight's `qualityCategory` names its
  category (`QCATE`). A wrong value is a `danglingReference` in every runtime.

## 1.6.3

- SCCO `relatedInteractions` resolves against the interactions (`INEN`).
  Fields that hold prose rather than ids now say so in their hints instead of
  promising `BR-xxx` / `INT-xxx` / `ISC-xxx` ids: the use-case rule lists
  (validation, calculation, authorization, workflow, notification,
  integration), MNSST `businessRuleApplied`, INTR `relatedUseCase` (ids of the
  Interaction Scenarios document) and `earliestPossibleStage`.
- Cross-references that were plain text resolve: `refersTo` on PICLS
  `parentProcess` (`BPREN`), PCRLT `sourceProcess` / `targetProcess` (`BPREN`
  or `CUBIPR`), INID `processReference` and INTR `relatedProcess` (`BPREN`),
  INTR `relatedDataEntities` (`DAENT.entityName`), `relatedBusinessObjects`
  (`BJOEN`), `relatedBusinessRules` (`BIRU`), `relatedIntegrations` (`EIE`),
  SSEC `interactionReference` (`INEN`), TMED `dependsOnPhases` (`TRPHE`) and
  `dependsOnMilestones` (`TRMIL`), TESCBU `businessProcessRef` (`BPREN`),
  TESCTR `acceptanceCriterionRef` (`DACEN`), and every `targetStage` /
  `fallbackStage` (`STAGE`). A wrong id is a `danglingReference` in every
  runtime. The feature priority register's `targetStage` is no longer required:
  a feature planned into no stage (Won't this time) leaves it empty.
- The remaining nine `@Reference` sections hold a resolvable id too:
  `KEATT-REFE-REF`, `ENRLE-SOUR-REF`, `ENRLE-TARG-REF` and `DAENRE-RELA-REF`
  (data entity, `DAENT`), `BIRURE-RULE-REF` (business rule, `BIRU`),
  `AFOB-OBJE-REF` (business object, `BJOEN`), `AFFN-FUNC-REF` (function,
  `FUNCT`), `RQDEP-RELA-REF` (requirement: `FRE`, `TERQ`, `SECRQ` or `ORRQ`) and
  `RQTSC-RELA-REF` (acceptance criterion, `ACE`) each have a one-field form `ref`
  whose field declares `refersTo` its registries. Every `@Reference` of the
  model now has that shape; a document that wrote the id as the section's text
  moves it into `ref`.

## 1.6.2

- Reference sections hold a resolvable id. `EXSDE-PRIM-REF`, `SYDE-SOUR-REF`,
  `SYDE-TARG-REF`, `SYIN-SOUR-REF`, `SYIN-TARG-REF`, `PME-PROC-REF`,
  `SYTS-RELA-REF` and `GOLDE-RELA-REF` are `DocSpecsSection` members with a
  one-field form `ref`; `WAE-PART-REF` has `refs` (comma-separated ids). Each
  field declares `refersTo` its registry (`ESENT`, `CUBIPR`, `INEN`, `BGE`,
  `WSE` — `.@sectionId`), so every runtime's instance tier resolves the id and
  reports a wrong one as `danglingReference`. Before, the typed ones expanded
  to the whole target class and the others held free text. A document that
  wrote the id as a form preamble or a plain value moves it into `ref`
  (`tom_specs_model_rules.md` §6.1, **ref**).

## 1.6.1

- Code-valued form fields: `patternRegex` and `constraintExpression`
  (`DATAA`), the text-input `pattern`, `transformationExpression` and both
  `ruleExpression` fields declare `code: true`. The markdown rendition writes
  their single-line values as inline code spans, so a regex's `](` stays
  literal instead of becoming a link (`som_multiplatform_spec_model.md` §11.4
  rule 8, `tom_specs_model_rules.md` §6.2.3). A stored value is the bare code:
  a document that wrapped a pattern in backticks by hand should drop them.
  Requires `tom_specs_core` 0.2.3 (`Field.code`).

## 1.6.0

- Protocol bindings: a `ServerOperationEntry` has a `bindings` list of
  `OperationBindingEntry` (`SVOBI`) — the HTTP method, path template, version
  prefix, success status, response headers, content types and error format a
  third-party caller reaches the operation under — each with a `parameters`
  list of `BindingParameterEntry` (`SVOBP`). The operation's own contract is
  unchanged. Enums `BindingHttpMethod`, `BindingParameterSource` and
  `BindingErrorFormat`.
- Framework protocol features: the server operation registry has a
  `protocolFeatures` list of `ProtocolFeatureEntry` (`PROTF`, enum
  `ProtocolFeatureKind`: an OIDC authorization server, a SCIM 2.0 server), each
  with the `hooks` the system implements (`FeatureHookEntry`, `FEHOK`) and, per
  hook, what each contract member does (`HookMethodEntry`, `FEHOM`: the
  operations it calls in order, the entities it reads and writes).
- `codespecs_prompt.md` gains the A4 rows and A5 carriers for both, and the
  Stage-B rule for a hook whose tom_core contract does not exist yet.
- `tom_specs_project_flow.md` G4 gains three criteria (bindings resolve, hooks
  complete, no protocol endpoint re-declared).
- The generic gate checklists G1 and G2 (`doc/gate_checklists/`) and their
  authority, `doc/tom_specs_gate_checklists.md`.

## 1.5.0

- **Document-breaking:** two section ids are renamed, because the old ones
  collided with a list's item pattern and no document could carry them validly:
  `CurrentWorkflowEntry`'s diagram is `CUWF-DIAG` (was `CUWF-WORK`), and
  `ErrorRecovery`'s mechanisms form is `ERRE-MECH` (was `ERRE-RECO`). A
  document written against 1.4.x that uses either section must rename the key
  (YAML) or heading id (markdown).
- Two additive CodeSpecs carriers: the `ActionTriggerKind` enum with
  `triggerKind` on `ScreenElementAction` and `ComponentActionEntry`, and
  `bodyMessageKey` (`refersTo` a message key) on `NotificationTypeEntry`.
- SOM text: §11.5 (a pattern-list item's heading id is stored on import), §11.6
  (a form-only section's prose is the form's preamble), §12.1 (an absent review
  pass decodes as null), §12.3 rule 4 (an empty document keeps its root key),
  §12.5 (one review-scalar rule) and §14 (DocSpecs findings carry their document
  path).
- `codespecs_prompt.md`: the extractor refuses a `@CodeSpecsProjection` root
  (§5), and the gate record carries an insufficient area's gap lines (§6.3).
- `tom_specs_model_meta_schema.md`: the meta's `modelHash`.

## 1.4.1

- Test-only. `test/real_model_round_trip_test.dart` asserted the reachable
  model's text-section and form counts as they were before a class-level
  `@Form` made its `content` a form (637 and 303, not 707 and 233). 1.4.0
  shipped the stale counts, so its archive's own test failed.

## 1.4.0

- SOM §9 documents moving a list item.

- The Solution Blueprint's stated counts are declared with `countOf` and checked
  against the lists they describe: the scale form (`SYSCL`) counts user
  categories, external interfaces, functional and non-functional (technical +
  security) requirements; the requirement summary forms (`FR-SUMM`,
  `TR1-SUMM`, `SR1-SUMM`, `OR-SUMM`) their totals and priority buckets.
  `tom_specs_model_rules.md` §6.2.2 states the rule.

- SOM §12.9 documents assembling a document from fragments.

- The area catalogue carries the Stage-A gate tables (`gate.requiredArguments`,
  `gate.carriers`), and `codespecs_prompt.md` §4.4/§4.5 pin A4 and A5
  mechanically: the rule, the 25-row required-argument table and the 26-row
  carrier table.

- `generated-doc/codespecs/codespecs_areas.json` (and the embedded accessor
  `lib/codespecs_areas.dart`) carries the 31 authoring steps of
  `codespecs_mapping.md` §4.4.6.

## 1.3.3

- An enumerated column's documentation now names the annotated field's Dart type
  as the column's value type, matching `tom_core_server`'s `TomDbColumn`, which
  no longer takes type parameters. Documentation of the model, carried into all
  nine language packages through the meta.
- The documentation moves with the CodeSpecs mapping and derivation contract to
  `tom_core_codespecs`; twelve of the fourteen subject-matter documents remain in
  `doc/`. `doc/` also gains the conformance driver's `editor` step and the
  documentation-generator provisioning (pdoc on Python 3.13 or newer).
- Test files formatted with the SDK formatter. No behaviour changes.

## 1.3.2

- **The shipped tests run from the published archive.** Three test groups read
  the generated `tom_som_dart_v0/meta/spec_model.meta.json`, which is a
  *workspace sibling*: present in a checkout, absent in a hosted install of this
  package. They threw `PathNotFoundException` there, so a consumer running
  `dart test` on what pub.dev carries saw seven crashes and no explanation.
  They now skip with the reason stated.
- The path was assembled from `Directory.current` rather than written as a
  literal, which is why the lexical shipped-path gate could not see it. Found by
  `tom_specs_clitool/tool/verify_published_tests.sh`, which downloads the
  published archive and runs its tests against hosted dependencies.
- Tests only; no library change.

## 1.3.1

- **Dependency constraints corrected, and this is a real fix rather than
  housekeeping.** 1.3.0 shipped with `tom_specs_core: ^0.1.0` while depending
  on annotations that package only gained in 0.2.0 — so the published 1.3.0
  resolved against a `tom_specs_core` it could not compile against. The
  constraint is now `^0.2.0`, and `tom_som_dart_runtime` moves to `^1.3.0`.
- Carries the `lib/codespecs_areas.dart` CHANGELOG entry and the
  `som_multiplatform_spec_model.md` §10.3 rewrite that landed after 1.3.0 was
  uploaded.
- No model change: the object model, the emitted metadata and the schemas are
  byte-identical to 1.3.0.

## 1.3.0

- **`lib/codespecs_areas.dart` — the CodeSpecs area catalogue as Dart.**
  `somCodeSpecsAreas` parses the 27-area catalogue on first use; the embedded
  `somCodeSpecsAreasJson` is the exact text of the shipped
  `generated-doc/codespecs/codespecs_areas.json`, which stays as the
  interchange artifact the eight non-Dart runtimes read. Its own library and
  not part of the barrel — a catalogue of CodeSpecs areas is not part of the
  object model. Generated by `tom_specs_clitool/bin/codespecs_areas.dart` in
  the same pass that writes the JSON, so the two cannot disagree.
- **`ImportanceBand` — the four-band qualitative scale gets a type.**
  `critical` / `high` / `medium` / `low` was the model's most-repeated
  vocabulary and had no type: a hundred form fields spelled it under a dozen
  labels (priority, criticality, severity, urgency, risk level, importance,
  weight, confidence, readiness, feasibility). They are one instrument, so they
  are now one enum. About a third of them document only the lower three bands;
  those bind too, under the existing subset rule — the same scale with its top
  band unused is not a second scale.
- **One risk matrix, not two.** `GoalRiskEntry`, `SystemMigrationRiskEntry` and
  `TransitionRiskEntry` rated probability and impact on their own three-band
  matrix while every other risk in the model rated on five bands. They now use
  `Probability` × `Impact` like the rest, so two risks from different documents
  are comparable and an author never has to work out which instrument an entry
  uses.
- Together: 106 more enum-typed form fields (42 → 148), and 25 enums now reach
  the emitted metadata (was 24).
- **Breaking for a Dart consumer of the generated facade, not for a document.**
  106 accessors change from `String?` to an enum type in `tom_som_dart_v0`
  1.3.0. The document format is unchanged — the same keys carry the same
  tokens — so the model **major** does not move. Values are stored as the
  constant name (`critical`, `high`), so a document that spelled a band
  `Critical` or wrote MoSCoW `Must` into one of these fields should be
  re-spelled; since 1.2.0 the instance validator reports the old spelling as
  `enumValueUnknown` rather than dropping it.
- Field labels and hints that merely listed the band names no longer do: the
  legal set travels with the enum, in every language, with each constant's own
  description.
- Depends on `tom_som_dart_runtime` ^1.3.0.

## 1.2.0

- **The four shared value enums are bound.** `Priority`, `Status`,
  `Probability` and `Impact` were declared with 160 documented constants
  between them and used by no field; they now type 20 form fields, so all 24 of
  the model's enums reach the emitted metadata (was 20) through 42 enum-typed
  `@Form` fields (was 22). A field takes an enum when the band set its label and
  hint document *is* that enum's band set — the two other qualitative scales the
  model uses (the four-band `Critical / High / Medium / Low`, the three-band
  `Low / Medium / High` matrix) are deliberately still `String`.
- **Breaking for a Dart consumer of the generated facade, not for a document.**
  Twenty accessors change from `String?` to an enum type in
  `tom_som_dart_v0` 1.2.0. The *document* format is unchanged: the same keys
  carry the same tokens, so a document authored under model 1.1 loads under 1.2
  — which is why the model **major** does not move. Values are stored as the
  constant name (`must`, `approved`), so a document that spelled them
  `Must` / `Approved` should be re-spelled; nothing rejects the old spelling
  yet, but the typed accessor reads it as `null`.
- The generated DocSpecs schemas now report the model's minor in their own
  version (`solution-blueprint/1.2`); the schema *filenames* stay keyed to the
  major, as before. Before this release every schema silently reported `1.0`
  whatever the model said.
- Depends on `tom_som_dart_runtime` ^1.2.0.

## 1.1.0

- Model additions in the SBP information and experience sections: the CE-EN
  domain-enum extract routing on `information_and_data_model` and the
  entity-typed shared-DTO member locus on `experience_and_interface_design`.
  Additive — documents authored under model 1.0 load unchanged.
- Depends on `tom_som_dart_runtime` ^1.1.0.

## 1.0.0

- Initial version.
