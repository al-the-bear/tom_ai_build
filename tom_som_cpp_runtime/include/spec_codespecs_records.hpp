/* spec_codespecs_records — reading back what a Phase-4 run wrote: the per-area
 * **extract** files and the Stage-B **gate record** (`codespecs_mapping.md`
 * §1.1.1, `codespecs_prompt.md` §6.3), an idiomatic-C++ port of the Dart
 * `spec_codespecs_records.dart`.
 *
 * The extractor (CodeSpecsExtractor) writes `<CE-CODE>.extract.yaml`; this
 * module is the other half, so a consumer that did not run the extractor — a
 * validator, an editor tool, an agent asking which areas are in scope — reads
 * the files with the same rules everywhere instead of re-deriving the shape. The
 * gate record has a writer here too, because it is otherwise written by hand and
 * only checked when something reads it.
 *
 * Both readers **refuse** an unknown `formatVersion`: a later format that moved
 * a key would otherwise read as an extract with no entries, or a scope with no
 * verdicts, and a check with no input passes.
 *
 * YAML is read with the runtime's own `yaml` reader (the docspecs load path). It
 * is a reader for the constrained subset the writers emit, so two things are
 * handled here rather than by it: a non-empty flow list (`["a", "b"]`,
 * `[5, 6]`) — which the extract writer emits as JSON, so it is decoded as JSON —
 * and YAML's typing of plain scalars (`null` / `~` read as null, `true` /
 * `false` and plain floats as non-strings). A key written with no value at all
 * (`key:`) reads as null, as YAML says.
 *
 * Every failure throws CodeSpecsRecordError carrying the Dart message,
 * character for character.
 */
#ifndef SPEC_CODESPECS_RECORDS_HPP
#define SPEC_CODESPECS_RECORDS_HPP

#include <exception>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "spec_codespecs_extract.hpp"

namespace som {

/* The file name of the gate record, written beside the extracts.
 *
 * Fixed so a partial pass cannot hide its record under a name no reader looks
 * for. */
inline constexpr const char* kCodeSpecsGateRecordFile = "gate.verdicts.yaml";

/* The gate record `formatVersion` this runtime reads and writes. */
inline constexpr long long kCodeSpecsGateRecordFormat = 1;

/* The suffix every extract artifact of record carries. */
inline constexpr const char* kCodeSpecsExtractFileSuffix = ".extract.yaml";

/* The one resolution a gate record may carry: an insufficient area the user
 * decided to leave out. */
inline constexpr const char* kCodeSpecsGateDescoped = "descoped";

/* A malformed or unreadable extract file or gate record. */
class CodeSpecsRecordError : public std::exception {
 public:
  explicit CodeSpecsRecordError(std::string message);

  /* What is wrong, naming the file it was read from. */
  const std::string& message() const { return message_; }

  /* Renders as `CodeSpecsRecordError: <message>`. */
  const char* what() const noexcept override { return rendered_.c_str(); }

 private:
  std::string message_;
  std::string rendered_;
};

/* Parses one `<CE-CODE>.extract.yaml` — the inverse of CodeSpecsExtract::toYaml
 * (also reachable as CodeSpecsExtract::fromYaml). `source` names the file in
 * errors (empty: "the extract").
 *
 * Only `extract.formatVersion` (== kCodeSpecsExtractFormat) and a non-empty
 * `extract.area.code` are required; any other absent key reads as empty (a
 * string as "", a list as empty, the optional entry fields `headline`,
 * `instanceId`, `formField`, `routingNote` as unset). A key present with the
 * wrong type is an error, and so is a `document.entryCount` that disagrees with
 * the entries. `area.part` loses a leading `CodeSpecPart.` prefix. For any
 * extract the extractor wrote, reading it and writing it again is byte-identical.
 */
CodeSpecsExtract parseCodeSpecsExtractYaml(const std::string& text,
                                           const std::string& source =
                                               std::string());

/* One of `codespecs_prompt.md` §6.2's three per-area verdicts. */
enum class CodeSpecsGateVerdict {
  /* The extract carries every input the derivation contract requires. */
  Sufficient,
  /* The area does not apply — nothing was routed, with positive evidence of
   * absence (`codespecs_prompt.md` §6.4). */
  NotApplicable,
  /* The extract is missing required inputs; only a recorded descope lets a run
   * continue without the area. */
  Insufficient,
};

/* The verdict word exactly as `codespecs_prompt.md` §6.2 states it —
 * `sufficient`, `not applicable`, `insufficient`. */
const char* codeSpecsGateVerdictWord(CodeSpecsGateVerdict verdict);

/* The verdict for `word`, or unset for a word §6.2 does not know. */
std::optional<CodeSpecsGateVerdict> parseCodeSpecsGateVerdict(
    const std::string& word);

/* One gap line of an insufficient area (`codespecs_prompt.md` §6.3): a missing
 * input, and the section field that should have carried it.
 *
 * Stage C creates one L0 `csopen` todo per gap line, so two sections missing
 * the same field are two gaps — which is why the record carries them as data
 * rather than leaving them in the note. Shape is checked by
 * CodeSpecsGateRecord. */
struct CodeSpecsGateGap {
  /* The section whose content is missing the input. */
  std::string sectionId;
  /* What the derivation contract required, in one line. */
  std::string required;
  /* `<section-id>.<field>` — the field that should have carried it. */
  std::string carrier;

  /* The gap as the §6.3 output line, without its indentation. */
  std::string line() const {
    return sectionId + " — " + required + " — should have been carried by " +
           carrier;
  }
};

/* One area's recorded verdict. */
struct CodeSpecsGateEntry {
  /* The area's `CE-*` code. */
  std::string area;
  /* The verdict. */
  CodeSpecsGateVerdict verdict = CodeSpecsGateVerdict::Sufficient;
  /* `descoped`, on an insufficient area only; otherwise unset. */
  std::optional<std::string> resolution;
  /* A free-text note — why the verdict was taken. Never read as data. */
  std::optional<std::string> note;
  /* The gap lines of an insufficient area, in the order Stage B found them;
   * empty for every other verdict, and for an insufficient area recorded
   * before its gaps were. */
  std::vector<CodeSpecsGateGap> gaps;

  /* Whether this is an insufficient area resolved by descoping. */
  bool descoped() const {
    return resolution.has_value() && *resolution == kCodeSpecsGateDescoped;
  }
};

/* The Stage-B gate record, `gate.verdicts.yaml` (`codespecs_prompt.md` §6.3).
 *
 * Constructing one checks it: every area is a `CE-*` code named once, and a
 * `resolution:` appears only as `descoped` on an insufficient area. So a record
 * that exists is a record of the checked shape, whether it was read or built to
 * be written. */
class CodeSpecsGateRecord {
 public:
  /* Creates and checks a record; throws CodeSpecsRecordError on a shape §6.3
   * does not allow. `source` names it in errors. */
  explicit CodeSpecsGateRecord(std::vector<CodeSpecsGateEntry> verdicts,
                               const std::string& source =
                                   kCodeSpecsGateRecordFile);

  /* Parses `gate.verdicts.yaml`. `source` names the file in errors. Rejects an
   * unknown key at gate and at entry level and a `formatVersion` other than
   * kCodeSpecsGateRecordFormat. */
  static CodeSpecsGateRecord fromYaml(const std::string& text,
                                      const std::string& source =
                                          kCodeSpecsGateRecordFile);

  /* The verdicts, in the order they were recorded. */
  const std::vector<CodeSpecsGateEntry>& verdicts() const { return verdicts_; }

  /* The entry for `area`, or null when the record says nothing about it.
   * Borrowed from the record. */
  const CodeSpecsGateEntry* verdictFor(const std::string& area) const;

  /* Throws CodeSpecsRecordError when an area is not an active area of
   * `catalog` — a verdict for an area that does not exist scopes nothing. */
  void checkAgainst(const CodeSpecsAreaCatalog& catalog,
                    const std::string& source = kCodeSpecsGateRecordFile) const;

  /* A copy with `entry` recorded — replacing the area's earlier verdict in
   * place, or appended when the area had none. Checked like any record. */
  CodeSpecsGateRecord withVerdict(const CodeSpecsGateEntry& entry) const;

  /* The record as `gate.verdicts.yaml`. Byte-stable: the same record always
   * writes the same text, and `fromYaml(r.toYaml()).toYaml() == r.toYaml()`.
   * `area`, `verdict` and `resolution` are written plain, a note and every
   * gap field as double-quoted scalars (codeSpecsYamlString). */
  std::string toYaml() const;

 private:
  void check(const std::string& source) const;

  std::vector<CodeSpecsGateEntry> verdicts_;
};

/* One area the gate record left out of scope.
 *
 * Kept visible rather than dropped, so a consumer can say so: a scoped-out area
 * must never read as a covered one. */
struct CodeSpecsExcludedArea {
  /* The `CE-*` code. */
  std::string area;
  /* NotApplicable, or Insufficient with a recorded descope. */
  CodeSpecsGateVerdict verdict = CodeSpecsGateVerdict::NotApplicable;
  /* Whether an insufficient verdict was resolved by descoping. */
  bool descoped = false;
  /* How many routed entries the excluded extract carried (0 with no file). */
  std::size_t entryCount = 0;
  /* The file the excluded extract was read from, or "" when there was none. */
  std::string source;
};

/* Every extract one run produced, read back and scoped by its gate record. */
class CodeSpecsExtractSet {
 public:
  /* Reads `files` — (file name, text) pairs, in the order given — into a
   * scoped set.
   *
   * The file whose basename is kCodeSpecsGateRecordFile is the gate record;
   * every other file is an extract. The area code comes from the file's
   * content, never its name. With a record, an area is in scope **iff** its
   * verdict is `sufficient`, and:
   *
   *   - the record must carry a verdict for every extract supplied — a scope
   *     silent about an area would let a skipped area read as a passed one;
   *   - a `not applicable` area whose extract has entries is an error — a
   *     routed value is evidence the area applies (`codespecs_prompt.md` §6.4);
   *   - an `insufficient` area without `resolution: descoped` is an error — the
   *     run may not have continued past it (`codespecs_prompt.md` §6.2).
   *
   * Two extracts for one area, or two gate records, are errors. */
  static CodeSpecsExtractSet fromFiles(
      const std::vector<std::pair<std::string, std::string>>& files);

  /* Reads a directory of extracts — `<CE-CODE>.extract.yaml` plus an optional
   * `gate.verdicts.yaml`; other files (the `.extract.md` views) are ignored.
   * Files are read in name order (byte order), so the set is the same on every
   * file system. */
  static CodeSpecsExtractSet fromDirectory(const std::string& path);

  /* The in-scope extracts. With a gate record: the areas it marks
   * `sufficient`, in the record's order. Without: every extract, in source
   * order. */
  const std::vector<CodeSpecsExtract>& extracts() const { return extracts_; }

  /* The file each in-scope extract was read from, parallel to extracts(). */
  const std::vector<std::string>& sources() const { return sources_; }

  /* The areas the gate record excluded — empty without a record. */
  const std::vector<CodeSpecsExcludedArea>& excluded() const {
    return excluded_;
  }

  /* The gate record, when one was among the sources. */
  const std::optional<CodeSpecsGateRecord>& gate() const { return gate_; }

  /* The in-scope extract for `area`, or null. Borrowed from the set. */
  const CodeSpecsExtract* byArea(const std::string& area) const;

  /* Every in-scope entry routed from `sectionId` — the back-link token a
   * `DocRef` names — across every area, in extract order. Borrowed. */
  std::vector<const CodeSpecsExtractEntry*> entriesForSection(
      const std::string& sectionId) const;

  /* Every in-scope entry read from document `path`, in extract order.
   * Borrowed. */
  std::vector<const CodeSpecsExtractEntry*> entriesAtPath(
      const std::string& path) const;

 private:
  CodeSpecsExtractSet() = default;

  std::vector<CodeSpecsExtract> extracts_;
  std::vector<std::string> sources_;
  std::vector<CodeSpecsExcludedArea> excluded_;
  std::optional<CodeSpecsGateRecord> gate_;
};

}  // namespace som

#endif  // SPEC_CODESPECS_RECORDS_HPP
