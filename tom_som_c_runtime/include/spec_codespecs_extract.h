/* spec_codespecs_extract — the Phase-4 **specification extract generator**, the
 * machine half of CodeSpecs production (`codespecs_mapping.md` §1.1.1), a
 * faithful port of the Dart `spec_codespecs_extract.dart`.
 *
 * Phase 4 runs in two passes. This surface is the first: for each CodeSpecs area
 * it collects everything in a filled specification document that `@CodeSpecKind`
 * routes to that area, **verbatim and with provenance**, so the second pass — an
 * authoring agent, one prompt per authoring step — writes against a bounded
 * extract rather than against a 652-section document.
 *
 * The boundary between the two passes is a rule, not a preference. This
 * generator may **copy and index**; it may not summarise, rephrase, compose a
 * sentence out of field values, or choose a name — the prohibitions of
 * `codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract
 * generator word for word. The consequence is checkable rather than trusted:
 * every `CodeSpecsExtractEntry.value` is a string the document stores, byte for
 * byte, and the conformance corpus asserts it.
 *
 * Three things follow from that and shape the API:
 *
 *   - **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
 *     class carries `@CodeSpecKind` (feeds code), sits under a `@FollowUpKind`
 *     root (feeds a non-generation process), or carries `@NoArtifact` (feeds
 *     nothing). The trio is exhaustive by construction, so a class carrying none
 *     of them is not "skipped": it is a `CodeSpecsExtractError`, the
 *     `ROUTE-TOTAL` invariant (`tom_specs_model_rules.md` §10.2) failing loudly
 *     at the one place that depends on it.
 *   - **`@CodeSpecKind` is list-valued** (§9.1), and extracts are **not**
 *     deduplicated across areas: a section feeding three areas appears, whole,
 *     in three extracts. Each area's prompt must be self-sufficient.
 *   - **Every entry carries its provenance** — section id, class, field, the
 *     routing marker that put it here and where that marker was declared — so
 *     the `@DocSpec`/`DocRef` back-links (§9.3) can be written from the extract
 *     alone.
 *
 * The area catalogue (`CodeSpecsAreaCatalog`) is an **input**, not a table baked
 * into the runtime: it is the machine-readable form of `codespecs_mapping.md`
 * §4.1 (the parts catalogue), §4.4.3 (the emission slices) and §4.4.6 (the
 * authoring steps), authored once and read by all nine runtimes. Carrying it
 * beside the content is what stops an agent having to open the mapping document
 * to find out what `CE-FM` means.
 *
 * Error idiom: C has no exceptions, so where the Dart reference throws this
 * fills a caller-owned `CodeSpecsExtractError` whose `failed == 0` state is the
 * C stand-in for "did not throw" — the same OK-sentinel shape
 * `SpecCreationError` uses — and returns 1/0 alongside it.
 *
 * Ownership: an extractor **borrows** its model, document and catalogue; all
 * three must outlive it, and it owns nothing (there is no
 * `spec_codespecs_extractor_free`). A `CodeSpecsExtract` likewise borrows its
 * `area` from the catalogue but owns every string it carries — release it with
 * `spec_codespecs_extract_free`, a list of them with
 * `spec_codespecs_extract_list_free`. The catalogue itself owns its whole
 * structure (`spec_codespecs_area_catalog_free`), and every `char *` returned by
 * a renderer is owned by the caller (`free`).
 */
#ifndef SPEC_CODESPECS_EXTRACT_H
#define SPEC_CODESPECS_EXTRACT_H

#include "som_json.h"
#include "som_util.h"
#include "spec_document.h"
#include "spec_model.h"
#include "spec_reflection.h"

/* The version of the emitted extract artifact's on-disk shape. Bumped when the
 * YAML or Markdown layout changes in a way a reader could notice. */
#define SPEC_CODESPECS_EXTRACT_FORMAT 1

/* The annotation names of the three routing verdicts (`codespecs_mapping.md`
 * §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
 * so they are read by name rather than through a meta slot. */
#define SPEC_CODE_SPEC_KIND_ANNOTATION "CodeSpecKind"

/* See SPEC_CODE_SPEC_KIND_ANNOTATION. */
#define SPEC_FOLLOW_UP_KIND_ANNOTATION "FollowUpKind"

/* See SPEC_CODE_SPEC_KIND_ANNOTATION. */
#define SPEC_NO_ARTIFACT_ANNOTATION "NoArtifact"

/* ---- routing verdicts ---------------------------------------------------- */

/* Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries. */
typedef enum {
  /* `@CodeSpecKind(List<CodeSpecPart>)` — the section's content is shown to
   * every named area's extract. */
  CODESPECS_VERDICT_FEEDS_CODE = 0,
  /* `@FollowUpKind(List<FollowUpProcess>)` — the section is delivered by a
   * non-generation process. The whole subtree is excluded from every extract. */
  CODESPECS_VERDICT_FEEDS_PROCESS = 1,
  /* `@NoArtifact(NoArtifactReason)` — the section deliberately produces no
   * downstream artifact. Its own leaves contribute nothing; its children are
   * still routed individually (that is what `container` means). */
  CODESPECS_VERDICT_FEEDS_NOTHING = 2,
  /* A `@Document` root carrying no verdict. Structurally exempt from
   * `ROUTE-TOTAL`: a root is the document, not a section of it. */
  CODESPECS_VERDICT_DOCUMENT_ROOT = 3,
  /* No verdict, and not a `@Document` root — a `ROUTE-TOTAL` violation, and the
   * reason `spec_codespecs_extractor_extract_all` fails. */
  CODESPECS_VERDICT_UNROUTED = 4,
} CodeSpecsRoutingVerdict;

/* The verdict's name as the other eight ports spell it (`"feedsCode"`, …), a
 * static literal. */
const char *spec_codespecs_verdict_name(CodeSpecsRoutingVerdict v);

/* The verdict recorded for one class node of the walked document, with the
 * provenance of the marker that decided it. Owns its strings. */
typedef struct {
  /* The document path of the node the verdict was computed for. */
  char *path;
  /* The model class at `path`. */
  char *class_name;
  /* Which verdict the class carries. */
  CodeSpecsRoutingVerdict verdict;
  /* The verdict's payload, verbatim from the annotation: the `CodeSpecPart.*`
   * values for CODESPECS_VERDICT_FEEDS_CODE, the `FollowUpProcess.*` values for
   * CODESPECS_VERDICT_FEEDS_PROCESS, the single `NoArtifactReason.*` for
   * CODESPECS_VERDICT_FEEDS_NOTHING, and empty for the two verdicts that have
   * no marker. */
  SomStrList values;
  /* The marker's optional `note`, verbatim; NULL when it carries none. */
  char *note;
  /* Where the marker was declared — the class name, or `Class.field` when a
   * field-level `@CodeSpecKind` overrode its class. Empty when there is no
   * marker. */
  char *declared_at;
} CodeSpecsRouting;

/* Frees the owned members of `*r`. Safe on a zeroed struct. */
void spec_codespecs_routing_free(CodeSpecsRouting *r);

/* `CodeSpecsRouting(<path>, <className>, <verdict>)` — the Dart `toString`.
 * Owned result. */
char *spec_codespecs_routing_string(const CodeSpecsRouting *r);

typedef struct {
  CodeSpecsRouting *items;
  size_t len;
  size_t cap;
} CodeSpecsRoutingList;

void spec_codespecs_routing_list_init(CodeSpecsRoutingList *l);
void spec_codespecs_routing_list_free(CodeSpecsRoutingList *l);

/* ---- extract entries ----------------------------------------------------- */

/* One extract entry: a single value the specification document stores, with
 * everything needed to trace it back (`codespecs_mapping.md` §1.1.1, "Entry").
 * Owns its strings. */
typedef struct {
  /* The `CE-*` code of the area this entry was collected for. */
  char *area_code;
  /* The section id of the leaf the value sits on (`@SectionId`, else the model
   * field name). */
  char *section_id;
  /* The document path of the leaf — the source location. */
  char *path;
  /* The model class declaring the leaf. */
  char *class_name;
  /* The model field name of the leaf. */
  char *field_name;
  /* The form-field name when the value is one field of a `@Form` section; NULL
   * for a content, enum, scalar or scalar-list leaf. */
  char *form_field;
  /* The `CodeSpecPart.*` value that routed this entry here, verbatim. */
  char *routed_by;
  /* Where that `@CodeSpecKind` was declared — the class name, or `Class.field`
   * for a field-level override. */
  char *routed_at;
  /* The `@CodeSpecKind` `note`, verbatim; NULL when it carries none. */
  char *routing_note;
  /* The stored value, **verbatim**. Never assembled, reformatted or trimmed. */
  char *value;
} CodeSpecsExtractEntry;

/* Frees the owned members of `*e`. Safe on a zeroed struct. */
void spec_codespecs_extract_entry_free(CodeSpecsExtractEntry *e);

/* `CodeSpecsExtractEntry(<areaCode>, <path>)` — the Dart `toString`. Owned. */
char *spec_codespecs_extract_entry_string(const CodeSpecsExtractEntry *e);

/* ---- the area catalogue -------------------------------------------------- */

/* One emission slice of `codespecs_mapping.md` §4.4.3. */
typedef struct {
  /* The slice's number, 1–7. */
  long long number;
  /* The slice's name as §4.4.3 gives it. */
  char *title;
  /* The §4.2 project the slice emits into. */
  char *project;
  /* The slices this one may cite — §4.4.3's across-slice edges. Transitively
   * closed by `spec_codespecs_catalog_citable_area_codes`. */
  long long *cites;
  size_t cites_len;
} CodeSpecsSlice;

/* One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the §4.4.3
 * slice and §4.4.6 authoring steps that place it. This is the **per-area
 * context** an extract carries beside its content. */
typedef struct {
  /* The permanent registry key — `CE-FM`, `CE-API`. Never reused, never
   * renamed, and the extract file's name. */
  char *code;
  /* The §4.1 canonical id — the PascalCase noun (`Form`, `ServerApi`). */
  char *canonical_id;
  /* The `CodeSpecPart` value, camelCase and **without** the enum prefix
   * (`form`, `serverApi`). */
  char *part;
  /* The `Cs*` annotation names of the §4.1 row. */
  SomStrList annotations;
  /* The §4.1 "Built on" cell, verbatim. */
  char *built_on;
  /* Where the area's spec-authorable attribute surface is stated — a §5.x
   * citation. */
  char *attribute_surface;
  /* The §4.4.3 slice(s) the area's emission units sit in. More than one when
   * the area is split by locus. */
  long long *slices;
  size_t slices_len;
  /* The §4.4.6 authoring step(s) that write the area. */
  long long *authoring_steps;
  size_t authoring_steps_len;
  /* Whether the part is active. A deferred part (§4.3) holds a reserved
   * `CodeSpecPart` value but has no generated surface, so it gets no extract. */
  int active;
} CodeSpecsArea;

/* The fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`. Owned. */
char *spec_codespecs_area_kind_value(const CodeSpecsArea *a);

/* The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6.
 *
 * Authored once, read by all nine runtimes. It is an input rather than a baked
 * table because the catalogue is the mapping document's content: a copy per
 * runtime would be nine things to keep current, and the one thing this quest has
 * learned three times is that a vocabulary duplicated nine ways can be wrong in
 * agreement. */
typedef struct {
  /* Where the catalogue was transcribed from, for the extract header. */
  char *source;
  /* The §4.4.3 slices, in emission order. */
  CodeSpecsSlice *slices;
  size_t slices_len;
  /* The §4.1 areas, in catalogue order. Catalogue order is the tie-break §4.4.6
   * rule 2 uses, so it is load-bearing rather than cosmetic. */
  CodeSpecsArea *areas;
  size_t areas_len;
} CodeSpecsAreaCatalog;

/* Decodes a catalogue from its parsed JSON form into `*out` (initialised by the
 * callee, released with `spec_codespecs_area_catalog_free`). A NULL or
 * non-object node yields an empty catalogue rather than a failure — the shape
 * every optional block in this runtime decodes to. */
void spec_codespecs_area_catalog_from_json(const SomJson *v,
                                           CodeSpecsAreaCatalog *out);

void spec_codespecs_area_catalog_free(CodeSpecsAreaCatalog *c);

/* How many of the catalogue's areas are active — one extract each. */
size_t spec_codespecs_catalog_active_area_count(const CodeSpecsAreaCatalog *c);

/* The `i`-th active area in catalogue order, or NULL when `i` is out of range.
 * Borrowed from the catalogue. */
const CodeSpecsArea *
spec_codespecs_catalog_active_area_at(const CodeSpecsAreaCatalog *c, size_t i);

/* The area with this `CE-*` code, or NULL. Borrowed. */
const CodeSpecsArea *
spec_codespecs_catalog_by_code(const CodeSpecsAreaCatalog *c, const char *code);

/* The area a `@CodeSpecKind` value names, or NULL. Accepts both the bare value
 * (`form`) and the qualified one (`CodeSpecPart.form`), because the meta carries
 * the qualified spelling and callers reach for the bare one. Borrowed. */
const CodeSpecsArea *
spec_codespecs_catalog_by_part(const CodeSpecsAreaCatalog *c, const char *value);

/* The slice numbered `number`, or NULL. Borrowed. */
const CodeSpecsSlice *
spec_codespecs_catalog_slice_numbered(const CodeSpecsAreaCatalog *c,
                                      long long number);

/* The §4.2 projects `area`'s code lands in, in slice order, written into `out`
 * (initialised by the callee; free with `som_strlist_free`).
 *
 * Derived from the area's slices rather than authored on the area: §4.4.3
 * already fixes one project per slice, so a per-area project column would be a
 * second place for the same fact to be stated — and the areas that would need it
 * are exactly the locus-split ones, where getting it wrong is easiest. */
void spec_codespecs_catalog_projects_for(const CodeSpecsAreaCatalog *c,
                                         const CodeSpecsArea *area,
                                         SomStrList *out);

/* The area codes `area` may cite — every other active area whose emission units
 * sit in a slice `area`'s slices reach, following §4.4.3's edges transitively.
 * Within-slice citation is legal, so an area's own slices are part of the
 * reachable set; the area itself is excluded. Written into `out` (initialised by
 * the callee; free with `som_strlist_free`).
 *
 * Derived rather than authored: a hand-kept per-area citation list is a second
 * source of truth for something the slice graph already decides. */
void spec_codespecs_catalog_citable_area_codes(const CodeSpecsAreaCatalog *c,
                                               const CodeSpecsArea *area,
                                               SomStrList *out);

/* ---- the extract --------------------------------------------------------- */

/* One area's extract: the area's context plus every routed entry, in SOM
 * document order. */
typedef struct {
  /* The area this extract is for — borrowed from the catalogue, which must
   * outlive the extract. */
  const CodeSpecsArea *area;
  /* The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names. */
  char *catalog_source;
  /* The section segment of the document root the entries were collected from. */
  char *document_root;
  /* The area codes this area may cite (§4.4.3), for the agent's prompt. */
  SomStrList citable_parts;
  /* The §4.2 projects the area's code lands in (§4.4.3, via the slices). */
  SomStrList projects;
  /* The routed entries, in SOM document order. */
  CodeSpecsExtractEntry *entries;
  size_t entries_len;
  size_t entries_cap;
} CodeSpecsExtract;

/* Frees the owned members of `*x` (not the borrowed `area`). Safe on a zeroed
 * struct. */
void spec_codespecs_extract_free(CodeSpecsExtract *x);

/* The extract's file name stem — `CE-FM.extract`. Owned result. */
char *spec_codespecs_extract_file_stem(const CodeSpecsExtract *x);

/* The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are emitted as
 * JSON strings, which are valid YAML 1.2 double-quoted scalars — so one escaping
 * rule, identical in all nine runtimes, covers every value a specification can
 * hold. Owned result. */
char *spec_codespecs_extract_to_yaml(const CodeSpecsExtract *x);

/* The rendered view. Regenerated from the YAML's own data — nothing reads the
 * Markdown as input — and exists because the agent reads it far better than it
 * reads YAML. Owned result. */
char *spec_codespecs_extract_to_markdown(const CodeSpecsExtract *x);

typedef struct {
  CodeSpecsExtract *items;
  size_t len;
  size_t cap;
} CodeSpecsExtractList;

void spec_codespecs_extract_list_init(CodeSpecsExtractList *l);
void spec_codespecs_extract_list_free(CodeSpecsExtractList *l);

/* ---- the error ----------------------------------------------------------- */

/* Reported when the document cannot be extracted from at all.
 *
 * Two causes: a section routed nowhere — `ROUTE-TOTAL`
 * (`tom_specs_model_rules.md` §10.2) failing — and a walk root that cannot be
 * resolved to exactly one (`codespecs_prompt.md` §5). Both are errors rather
 * than skips: a section routed nowhere is a section the agent writing that area
 * never sees, and a walk over the wrong root is every area empty. A silent
 * omission at this boundary is indistinguishable from a specification that
 * genuinely said nothing.
 *
 * Owns its strings; initialise with `spec_codespecs_extract_error_init` and
 * release with `spec_codespecs_extract_error_free`. */
typedef struct {
  /* 0 when the extraction succeeded — the C stand-in for the Dart port's "no
   * exception was thrown". */
  int failed;
  /* What went wrong, in one sentence. */
  char *message;
  /* The document path of the offending node. */
  char *path;
  /* The model class at `path`. */
  char *class_name;
} CodeSpecsExtractError;

/* Resets `*e` to the no-failure state with all fields NULL (does not free — free
 * first if the struct already owns strings). */
void spec_codespecs_extract_error_init(CodeSpecsExtractError *e);
/* Frees the owned strings of `*e` and resets it. Safe when it records no
 * failure. */
void spec_codespecs_extract_error_free(CodeSpecsExtractError *e);
/* Reports whether `e` records a successful extraction. */
int spec_codespecs_extract_error_is_ok(const CodeSpecsExtractError *e);
/* `CodeSpecsExtractError: <message> (<path>, <className>)` — the Dart
 * `toString`. Owned result. */
char *spec_codespecs_extract_error_string(const CodeSpecsExtractError *e);

/* ---- the extractor ------------------------------------------------------- */

/* Produces one `CodeSpecsExtract` per active area from a filled specification
 * document. Borrows the model, the document and the catalogue; all three must
 * outlive it.
 *
 * A Phase-4 run extracts from **one** specification document, so the walk has
 * exactly one root (`root`, `codespecs_prompt.md` §5). The two ways to get that
 * wrong are both closed here rather than left to the caller: the walk cannot
 * union every `@Document` root, because there is no way to ask for that; and
 * naming a root the document never populates — the `D13CodeSpecsProjection`
 * mistake, whose `CGP/…` path space misses a blueprint's `SBP/…` values and
 * yields every area silently empty — is a `CodeSpecsExtractError` rather than an
 * empty result. */
typedef struct {
  /* The model describing the document's structure and carrying the routing
   * verdicts. */
  const SpecModel *model;
  /* The filled specification document. */
  const SpecDocument *document;
  /* The area catalogue — `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6. */
  const CodeSpecsAreaCatalog *catalog;
  /* The one `@Document` root this extractor walks — resolved once, by
   * `spec_codespecs_extractor_make`, so `spec_codespecs_extractor_routings` and
   * `spec_codespecs_extractor_extract_all` cannot disagree about what was
   * walked. NULL when the factory failed; every other member is then unusable
   * too. */
  const SpecRoot *root;
  SpecReflection reflection;
} CodeSpecsExtractor;

/* Binds an extractor to a model / document / catalogue triple.
 *
 * `root_type` names the specification document's own root, by type name or by
 * section id. NULL or empty, it defaults to the document's single **populated**
 * root — the root under which the document holds any value — falling back to the
 * model's only root when the document is empty, so an unfilled single-root model
 * still reaches the routing walk.
 *
 * Fails — leaving `root` NULL and filling `*err` when `err` is non-NULL — when
 * the root cannot be resolved to exactly one: an unknown `root_type`, a
 * `root_type` holding no value while another root does, more than one populated
 * root, or an empty document over a multi-root model. The C stand-in for the
 * Dart port's constructor throw; check with
 * `spec_codespecs_extract_error_is_ok`. */
CodeSpecsExtractor
spec_codespecs_extractor_make(const SpecModel *model,
                              const SpecDocument *document,
                              const CodeSpecsAreaCatalog *catalog,
                              const char *root_type,
                              CodeSpecsExtractError *err);

/* The verdict of every class node the walk reaches, in document order, written
 * into `out` (initialised by the callee; free with
 * `spec_codespecs_routing_list_free`).
 *
 * Computed by the same walk `spec_codespecs_extractor_extract_all` uses, so
 * "what was routed where" and "what landed in which extract" cannot disagree.
 * Unlike that function this does **not** fail on an unrouted class — it reports
 * it, which is what a diagnostic is for. */
void spec_codespecs_extractor_routings(const CodeSpecsExtractor *e,
                                       CodeSpecsRoutingList *out);

/* One extract per active area, in catalogue order, written into `out`
 * (initialised by the callee; free with `spec_codespecs_extract_list_free`).
 *
 * Returns 1 on success. Returns 0 — leaving `out` empty — on the first class the
 * walk reaches that carries none of the three verdicts, filling `*err` when
 * `err` is non-NULL. */
int spec_codespecs_extractor_extract_all(const CodeSpecsExtractor *e,
                                         CodeSpecsExtractList *out,
                                         CodeSpecsExtractError *err);

/* The single extract for `area_code`, written into `*out` (free with
 * `spec_codespecs_extract_free`).
 *
 * Returns 1 on success. Returns 0 when the catalogue holds no such active area —
 * the Dart port's `null` return, with `*err` left recording no failure — or when
 * extraction failed, with `*err` naming the offending node. */
int spec_codespecs_extractor_extract_for(const CodeSpecsExtractor *e,
                                         const char *area_code,
                                         CodeSpecsExtract *out,
                                         CodeSpecsExtractError *err);

#endif /* SPEC_CODESPECS_EXTRACT_H */
