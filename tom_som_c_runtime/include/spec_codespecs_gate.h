/* spec_codespecs_gate — the Phase-4 mechanical gate: Stage A of
 * `codespecs_prompt.md` §4, all five checks run as one over (model, document,
 * catalogue, schema). A faithful port of the Dart `spec_codespecs_gate.dart`.
 *
 * Every check runs; none stops the others. A project fixing one wants to see
 * the rest, and a gate that stopped at the first failure would report a
 * different set of problems on every run (`codespecs_prompt.md` §4).
 *
 * A check that could not run is reported as **not run**, with its reason, and
 * the gate does not pass: a skipped check must never read as a passed one.
 *
 *   - A1: the document, rendered to Markdown, is complete against its DocSpecs
 *     schema. Not run without a schema.
 *   - A2: the document's values are valid (`validate_document`).
 *   - A3: every section the walk reaches carries a routing verdict
 *     (ROUTE-TOTAL); when none is unrouted the extraction itself runs.
 *   - A4: every required marker argument of a used area has a populated
 *     source. Not run when A3 left no extracts or the catalogue has no gate
 *     tables.
 *   - A5: the model still offers every structured carrier. Not run without
 *     gate tables.
 *
 * Ownership: a `CodeSpecsGate` **borrows** its model, document, catalogue and
 * schema. A `CodeSpecsGateReport` owns its findings and its extracts; the
 * extracts borrow their areas from the catalogue, so the catalogue must outlive
 * the report. Release a report with `spec_codespecs_gate_report_free`.
 */
#ifndef SPEC_CODESPECS_GATE_H
#define SPEC_CODESPECS_GATE_H

#include <stddef.h>

#include "docspecs_validator.h"
#include "spec_codespecs_extract.h"
#include "spec_document.h"
#include "spec_model.h"

/* The five Stage-A checks, in check order. */
typedef enum {
  /* The document is complete against its DocSpecs schema. */
  CODESPECS_GATE_A1 = 0,
  /* The document's values are valid (`validate_document`). */
  CODESPECS_GATE_A2 = 1,
  /* Every section the walk reaches carries a routing verdict (ROUTE-TOTAL). */
  CODESPECS_GATE_A3 = 2,
  /* Every required marker argument of a used area has a populated source. */
  CODESPECS_GATE_A4 = 3,
  /* The model still offers every structured carrier. */
  CODESPECS_GATE_A5 = 4,
} CodeSpecsGateCheck;

/* How many checks there are. */
#define CODESPECS_GATE_CHECK_COUNT 5

/* `A1` … `A5`, as `codespecs_prompt.md` §4 names them. Static string. */
const char *spec_codespecs_gate_check_label(CodeSpecsGateCheck check);

/* One thing a check found wrong. Owns its strings. */
typedef struct {
  /* The check that found it. */
  CodeSpecsGateCheck check;
  /* What kind of finding — the DocSpecs rule (A1), the validation code (A2),
   * `unrouted` / `root` (A3), `missingSource` / `unresolvedReference` (A4),
   * `missingCarrier` (A5). */
  char *code;
  /* Where: a section id or document path (A1–A4), or the carrier
   * `Class.member[.formField]` (A5). */
  char *location;
  /* One sentence a user acts on. */
  char *message;
} CodeSpecsGateFinding;

/* `A3 unrouted <location>: <message>` — the Dart `toString`. Owned. */
char *spec_codespecs_gate_finding_string(const CodeSpecsGateFinding *f);

/* One check's outcome. */
typedef struct {
  /* Which check. */
  CodeSpecsGateCheck check;
  /* Whether it ran. A check that did not run never passes. */
  int ran;
  /* Why it did not run (a static string); NULL when it ran. */
  const char *not_run_reason;
  /* What it found, in the order found. Owned. */
  CodeSpecsGateFinding *findings;
  size_t findings_len;
  size_t findings_cap;
} CodeSpecsGateCheckResult;

/* Ran and found nothing. */
int spec_codespecs_gate_check_result_passed(const CodeSpecsGateCheckResult *r);

/* The gate's report: one result per check, A1 to A5. */
typedef struct {
  /* The five results, in check order (`results[check]`). */
  CodeSpecsGateCheckResult results[CODESPECS_GATE_CHECK_COUNT];
  /* Whether A3 passed and the extraction ran — the Dart `extracts != null`. */
  int has_extracts;
  /* The extraction run's extracts when `has_extracts` (A4 reads them; Stage B
   * is handed them); empty otherwise. Owned. */
  CodeSpecsExtractList extracts;
} CodeSpecsGateReport;

/* The result of `check`. */
const CodeSpecsGateCheckResult *
spec_codespecs_gate_report_result(const CodeSpecsGateReport *r,
                                  CodeSpecsGateCheck check);

/* Every check ran and found nothing — the run may begin. */
int spec_codespecs_gate_report_passed(const CodeSpecsGateReport *r);

/* The number of findings over all checks. */
size_t spec_codespecs_gate_report_finding_count(const CodeSpecsGateReport *r);

/* The `i`-th finding in check order (the Dart `findings[i]`), or NULL when out
 * of range. Borrowed. */
const CodeSpecsGateFinding *
spec_codespecs_gate_report_finding_at(const CodeSpecsGateReport *r, size_t i);

/* Releases everything the report owns and zeroes it. Safe on a zeroed report. */
void spec_codespecs_gate_report_free(CodeSpecsGateReport *r);

/* Stage A of `codespecs_prompt.md` §4. Borrows every input. */
typedef struct {
  /* The resolved object model. */
  const SpecModel *model;
  /* The document under Phase 4. */
  const SpecDocument *document;
  /* The area catalogue — its gate tables drive A4 and A5. */
  const CodeSpecsAreaCatalog *catalog;
  /* The DocSpecs schema of the document's root; A1 does not run without it
   * (NULL). */
  const DocSpecsSchema *schema;
  /* The document root to walk — type name or section id; NULL defaults to the
   * document's single populated root, as the extractor does. */
  const char *root_type;
} CodeSpecsGate;

/* Holds the inputs; `spec_codespecs_gate_run` does the work. */
CodeSpecsGate spec_codespecs_gate_make(const SpecModel *model,
                                       const SpecDocument *document,
                                       const CodeSpecsAreaCatalog *catalog,
                                       const DocSpecsSchema *schema,
                                       const char *root_type);

/* Runs all five checks into `*out` (initialised by the callee; release with
 * `spec_codespecs_gate_report_free`). Returns 1.
 *
 * Returns 0 — leaving `*out` zeroed and writing an owned message to `*err`
 * when non-NULL — only where the Dart reference's `run()` throws: A1's
 * Markdown rendering failing, or the extraction failing after the routing walk
 * found nothing unrouted. */
int spec_codespecs_gate_run(const CodeSpecsGate *g, CodeSpecsGateReport *out,
                            char **err);

#endif /* SPEC_CODESPECS_GATE_H */
