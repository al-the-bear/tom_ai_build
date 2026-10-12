/* spec_codespecs_gate — the Phase-4 mechanical gate: Stage A of
 * `codespecs_prompt.md` §4, all five checks run as one over (model, document,
 * catalogue, schema). An idiomatic-C++ port of the Dart
 * `spec_codespecs_gate.dart`.
 *
 * Every check runs; none stops the others. A project fixing one wants to see
 * the rest, and a gate that stopped at the first failure would report a
 * different set of problems on every run (`codespecs_prompt.md` §4).
 *
 * A check that could not run is reported as **not run**, with its reason, and
 * the gate does not pass: a skipped check must never read as a passed one.
 *
 * A CodeSpecsGate borrows its model, document, catalogue and schema; all must
 * outlive run(). The report owns everything it carries.
 */
#ifndef SPEC_CODESPECS_GATE_HPP
#define SPEC_CODESPECS_GATE_HPP

#include <optional>
#include <string>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_codespecs_extract.hpp"
#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

/* The five Stage-A checks, in check order. */
enum class CodeSpecsGateCheck {
  /* The document is complete against its DocSpecs schema. */
  A1,
  /* The document's values are valid (`validateDocument`). */
  A2,
  /* Every section the walk reaches carries a routing verdict (ROUTE-TOTAL). */
  A3,
  /* Every required marker argument of a used area has a populated source. */
  A4,
  /* The model still offers every structured carrier. */
  A5,
};

/* `A1` … `A5`, as `codespecs_prompt.md` §4 names them. */
const char* codeSpecsGateCheckLabel(CodeSpecsGateCheck check);

/* One thing a check found wrong. */
struct CodeSpecsGateFinding {
  /* The check that found it. */
  CodeSpecsGateCheck check = CodeSpecsGateCheck::A1;
  /* What kind of finding — the DocSpecs rule (A1), the validation code (A2),
   * `unrouted` / `root` (A3), `missingSource` / `unresolvedReference` (A4),
   * `missingCarrier` (A5). */
  std::string code;
  /* Where: a section id or document path (A1–A4), or the carrier
   * `Class.member[.formField]` (A5). */
  std::string location;
  /* One sentence a user acts on. */
  std::string message;

  /* `A3 unrouted <location>: <message>` — the Dart `toString`. */
  std::string display() const;
};

/* One check's outcome. */
struct CodeSpecsGateCheckResult {
  /* Which check. */
  CodeSpecsGateCheck check = CodeSpecsGateCheck::A1;
  /* Whether it ran. A check that did not run never passes. */
  bool ran = true;
  /* Why it did not run; unset when it ran. */
  std::optional<std::string> notRunReason;
  /* What it found, in the order found. */
  std::vector<CodeSpecsGateFinding> findings;

  /* Ran and found nothing. */
  bool passed() const { return ran && findings.empty(); }
};

/* The gate's report: one result per check, A1 to A5. */
struct CodeSpecsGateReport {
  /* The five results, in check order. */
  std::vector<CodeSpecsGateCheckResult> results;
  /* The extraction run's extracts, when A3 passed (A4 reads them; Stage B is
   * handed them). Unset when the walk could not complete. */
  std::optional<std::vector<CodeSpecsExtract>> extracts;

  /* The result of `check`. Throws std::out_of_range when absent. */
  const CodeSpecsGateCheckResult& operator[](CodeSpecsGateCheck check) const;

  /* Every check ran and found nothing — the run may begin. */
  bool passed() const;

  /* Every finding, in check order. */
  std::vector<CodeSpecsGateFinding> findings() const;
};

/* Stage A of `codespecs_prompt.md` §4. */
class CodeSpecsGate {
 public:
  /* `catalog`'s gate tables drive A4 and A5; A1 does not run without
   * `schema` (null). `rootType` names the document root to walk — type name or
   * section id; empty defaults to the document's single populated root, as the
   * extractor does. */
  CodeSpecsGate(const SpecModel& model, const SpecDocument& document,
                const CodeSpecsAreaCatalog& catalog,
                const DocSpecsSchema* schema = nullptr,
                std::string rootType = std::string());

  /* Runs all five checks. Throws only where the Dart reference's run() does:
   * A1's Markdown rendering failing (std::runtime_error), or the extraction
   * failing after the routing walk found nothing unrouted
   * (CodeSpecsExtractError). */
  CodeSpecsGateReport run() const;

 private:
  CodeSpecsGateCheckResult a1() const;
  CodeSpecsGateCheckResult a2() const;
  CodeSpecsGateCheckResult a3(
      std::optional<std::vector<CodeSpecsExtract>>* extracts) const;
  CodeSpecsGateCheckResult a4(const std::vector<CodeSpecsExtract>& extracts) const;
  CodeSpecsGateCheckResult a5() const;

  const SpecModel* model_;
  const SpecDocument* document_;
  const CodeSpecsAreaCatalog* catalog_;
  const DocSpecsSchema* schema_;
  std::string rootType_;
};

}  // namespace som

#endif  // SPEC_CODESPECS_GATE_HPP
