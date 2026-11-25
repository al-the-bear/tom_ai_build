/* The merge back (SOM §11.10; the reading view's part *Stripped renditions and
 * the merge back*): an edited readable rendition merged onto the document of
 * record, every piece the strip removed put back.
 *
 * The C++ port of `spec_document_merge.dart` / `spec_document_merge.ts`;
 * `strip_merge_cases.json` holds them to the same results. Offsets (a placed
 * piece's `at`) count UTF-16 code units, as Dart and TypeScript count them;
 * texts are UTF-8. */
#ifndef SPEC_DOCUMENT_MERGE_HPP
#define SPEC_DOCUMENT_MERGE_HPP

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_document.hpp"
#include "spec_document_strip.hpp"
#include "spec_model.hpp"

namespace som {

/* A piece put back after an edited run rather than between unchanged
 * neighbours: an author confirms or moves it (`PLACED <value> — check`). */
struct SpecStripMergePlaced {
  SpecStripPiece piece;
  long long at = 0;  // the offset in the merged value the piece's text starts at

  /* `{at, removed}`. */
  std::string toJson() const;
};

/* Why a value, or the whole merge, cannot be merged. The codes:
 * `crossesBoundary`, `sentenceRemoved`, `stripTextEdited`, `unplaceable`,
 * `notation`, `annotations`, `changedBothSides`, `notStrippedBack` and
 * `newFinding`. */
struct SpecStripMergeConflict {
  std::string code;
  std::string message;
  std::optional<SpecStripValueRef> ref;  // unset when about no one value
  std::optional<SpecStripPiece> piece;   // unset when about no one piece
  std::string excerptO;  // the original around it
  std::string excerptB;  // the stripped text around it
  std::string excerptE;  // the edited text around it

  /* The conflict about value `value`. */
  SpecStripMergeConflict about(const SpecStripValueRef& value) const;
  /* `CONFLICT <value> — <reason>`, then the three excerpts and the piece. */
  std::vector<std::string> reportLines() const;
  /* `{code, value?, removed?}`. */
  std::string toJson() const;
};

/* The result of mergeStrippedValue. */
struct SpecStripValueMerge {
  std::optional<std::string> text;  // the merged value; unset on conflicts
  long long restored = 0;           // how many pieces were put back
  std::vector<SpecStripMergePlaced> placed;
  std::vector<SpecStripMergeConflict> conflicts;

  bool ok() const { return conflicts.empty(); }
  /* `{text, restored, placed, conflicts}`. */
  std::string toJson() const;
};

/* The name of a value in a merge report: `<path> (headline)`,
 * `<path> / <field>` or `<path>`. */
std::string specStripMergeLabel(const SpecStripValueRef& ref);

/* Merges the edited text `e` of one value back onto its original `o` (SOM
 * §11.10): `b` is `o` stripped and `pieces` what the strip removed, anchored
 * in `b`. A piece between unchanged neighbours goes back where it was; one at
 * an edit goes after it (placed) or is a conflict. */
SpecStripValueMerge mergeStrippedValue(const std::string& o,
                                       const std::string& b,
                                       const std::string& e,
                                       const std::vector<SpecStripPiece>& pieces);

/* One value a document merge changed. */
struct SpecStripMergedValue {
  SpecStripValueRef ref;
  std::string text;  // the merged value written into the document of record
  long long restored = 0;
  std::vector<SpecStripMergePlaced> placed;
};

/* An edit a merge refuses. The codes: `sectionAdded`, `sectionRemoved`,
 * `sectionMoved`, `listItems`, `codeSpec`, `units`, `rejected`, `stale` and
 * `strip`. */
struct SpecStripMergeRefusal {
  std::string code;
  std::string path;  // "" for the whole document
  std::string message;

  /* `REFUSED <path> — <message>`. */
  std::string reportLine() const;
  /* `{code, path}`. */
  std::string toJson() const;
};

/* The result of SpecStripMerge::merge. */
struct SpecStripMergeResult {
  std::optional<SpecDocument> document;  // the merged document; unset when
                                         // nothing may be written
  SpecStripOptions options;
  bool stale = false;  // whether the merge was three-way from the original
                       // at the export
  std::vector<SpecStripMergedValue> merged;
  std::vector<SpecStripMergeConflict> conflicts;
  std::vector<SpecStripMergeRefusal> refusals;

  bool ok() const { return conflicts.empty() && refusals.empty(); }
  /* `0` merged or nothing to merge, `1` conflicts or refusals. */
  int exitCode() const { return ok() ? 0 : 1; }
  /* `MERGED` / `PLACED` lines, then the conflicts' and the refusals'. */
  std::vector<std::string> report() const;
};

/* What SpecStripMerge::merge takes beyond the original and the edited text. */
struct SpecStripMergeOptions {
  const SpecModel* model = nullptr;        // required
  const DocSpecsSchema* schema = nullptr;  // the schema tier of the checks
  std::string rootType;                    // default the single populated root
  /* Switches given beside the readable header; they must agree with it. */
  std::optional<SpecStripOptions> options;
  /* The revision the original has now; a header naming another is stale. */
  std::optional<std::string> currentRevision;
  /* The original as it was at the export, given by hand. */
  const SpecDocument* base = nullptr;
  /* The base of a stale original from the header's source (its commit);
   * unset when it cannot be read. */
  std::function<std::optional<SpecDocument>(const SpecReadableSource&)> loadBase;
};

/* Merging an edited readable rendition back onto its document (SOM §11.10). */
class SpecStripMerge {
 public:
  /* Merges `edited`, a `.readable.md` made from `original` and changed by a
   * reader, back onto `original`: the switches from the readable header (or
   * `options`), a stale original merged three ways from the base, structural
   * edits refused, the result checked to strip back to the edited text and
   * to add no finding. Throws SpecStripUsageError when the switches cannot
   * be known or disagree with the header. */
  static SpecStripMergeResult merge(const SpecDocument& original,
                                    const std::string& edited,
                                    const SpecStripMergeOptions& extra);

  /* The file at `filePath` as it was at `commit` (`git show
   * <commit>:./<name>`, run in the file's folder); unset when git cannot give
   * it. */
  static std::optional<std::string> gitShowFile(const std::string& commit,
                                                const std::string& filePath);
};

}  // namespace som

#endif  // SPEC_DOCUMENT_MERGE_HPP
