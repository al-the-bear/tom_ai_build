/* Stripped renditions (SOM §11.10; the reading view's part *Stripped
 * renditions and the merge back*): a copy of a value with the secondary prose
 * of named kinds dropped, unmarked or moved to an appendix.
 *
 * The kinds are the four the reading notation registers as secondary
 * (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5), `linked`, the
 * navigation marker (SOM §11.11), and `derived`, the generated parts (SOM
 * §11.12) — both removed by `drop` and `unmark` alike —, and `comments`, the
 * review annotations (SOM §11.9). A citation shape counts as a span of its
 * kind. `refs`, `records` and `rejected` are never secondary: no name drops or
 * unmarks them (RN-11).
 *
 * The C++ port of `spec_document_strip.dart` / `spec_document_strip.ts`: the
 * strip of one value (stripNotationText), the strip of a whole document
 * (SpecDocumentStrip) and the readable header of a stripped rendition
 * (SpecReadableHeader); `strip_cases.json` holds them to the same results.
 * Offsets (`SpecStripPiece::anchor` / `origin`) count UTF-16 code units, as
 * Dart and TypeScript count them; texts are UTF-8. */
#ifndef SPEC_DOCUMENT_STRIP_HPP
#define SPEC_DOCUMENT_STRIP_HPP

#include <optional>
#include <set>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_document.hpp"
#include "spec_model.hpp"
#include "spec_notation.hpp"

namespace som {

/* The kind names a strip takes, in report and header order. */
inline constexpr const char* specStripKindNames[] = {
    "provenance", "trace", "editorial", "aside", "linked", "derived", "comments",
};

/* The notation kinds a strip can drop, unmark or move to the appendix. */
inline constexpr const char* specStripNotationKinds[] = {
    "provenance", "trace", "editorial", "aside",
};

/* A strip asked for something it cannot do; the message says which. */
class SpecStripUsageError : public std::runtime_error {
 public:
  using std::runtime_error::runtime_error;
};

/* What a strip does with each kind. */
struct SpecStripOptions {
  std::set<std::string> drop;      // the kinds removed with their content
  std::set<std::string> unmark;    // the kinds whose markers go
  std::set<std::string> appendix;  // the kinds moved into the appendix *Notes*
  bool appendixReferences = false;  // each moved element leaves a link `[n]`
  bool headingDivs = false;  // sections deeper than level 6 are styled divs

  /* Whether the rendition leaves the `linked` markers out (SOM §11.11). */
  bool writesNoLinkedMarkers() const {
    return drop.count("linked") != 0 || unmark.count("linked") != 0;
  }
  /* Whether the rendition leaves the generated parts out (SOM §11.12). */
  bool writesNoGeneratedParts() const {
    return drop.count("derived") != 0 || unmark.count("derived") != 0;
  }

  /* The options from the names a user gives, each item possibly comma-joined.
   * `all` stands for every kind the list can hold that no other list names
   * explicitly. Throws SpecStripUsageError for an unknown name, a name in two
   * lists, `comments` to unmark or move, `linked` / `derived` to move, and
   * appendix references without an appendix. */
  static SpecStripOptions fromNames(const std::vector<std::string>& drop,
                                    const std::vector<std::string>& unmark,
                                    const std::vector<std::string>& appendix,
                                    bool appendixReferences = false,
                                    bool headingDivs = false);

  /* The options of the emptying rule: what would go is unmarked instead. */
  SpecStripOptions keeping() const;
  /* The options an appendix entry's own content is stripped with. */
  SpecStripOptions inEntry() const;

  /* `names` in the canonical order of specStripKindNames. */
  static std::vector<std::string> ordered(const std::set<std::string>& names);

  /* The options as the conformance corpus writes them. */
  std::string toJson() const;
};

/* The source a readable rendition was made from, for its header. */
struct SpecReadableSource {
  std::string file;
  std::optional<std::string> revision;  // unset when not known
  std::optional<std::string> commit;    // unset when not known
  bool dirty = false;
};

/* The readable header line of a stripped rendition (SOM §11.1): `<!--
 * readable: drop=…; unmark=…; appendix=…; appendix-references;
 * headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that
 * do not apply are left out; format and parse are inverse. */
struct SpecReadableHeader {
  SpecStripOptions options;
  std::optional<SpecReadableSource> source;  // unset when the header names none

  /* The header line for `options` and `source` (nullptr: none). */
  static std::string format(const SpecStripOptions& options,
                            const SpecReadableSource* source = nullptr);
  /* `line` read as a readable header; unset for a line that is none — an
   * unknown part, an unknown kind, a usage error, a commit without a file. */
  static std::optional<SpecReadableHeader> parse(const std::string& line);
};

/* A value of a document: a stored headline, a content value, or a form
 * field's value. */
struct SpecStripValueRef {
  std::string path;
  std::optional<std::string> field;  // set for a form field
  bool headline = false;

  /* The value in `doc` ("" when unset). */
  std::string read(const SpecDocument& doc) const;
  /* Writes `value` to the value it names ("" clears it). */
  void write(SpecDocument& doc, const std::string& value) const;
  /* `<path> (headline)`, `<path>/<field>` or `<path>`. */
  std::string label() const;
  /* `{path, field?, headline?}`. */
  std::string toJson() const;
};

/* One piece a strip removed from a value, anchored in the stripped text. */
struct SpecStripPiece {
  long long anchor = 0;  // the offset in the stripped text it stands at
  long long origin = 0;  // the offset in the original text it starts at
  std::string removed;   // the original text the piece removed
  std::string inserted;  // the text the stripped value holds in its place
  std::vector<std::string> labels;  // what removed it, sorted

  std::string toJson() const;
};

/* One entry of a stripped rendition's appendix *Notes*. */
struct SpecAppendixEntry {
  long long number = 0;
  std::string kind;
  std::string text;
  /* The value it came from; unset for the strip of one value. */
  std::optional<SpecStripValueRef> value;

  std::string toJson() const;
};

/* The result of stripping one value (stripNotationText). */
struct SpecStripTextResult {
  std::string text;
  std::vector<SpecStripPiece> pieces;
  // kind -> count, in the order the kinds were first counted
  std::vector<std::pair<std::string, long long>> dropped;
  std::vector<std::pair<std::string, long long>> unmarked;
  std::vector<std::pair<std::string, long long>> appended;
  long long marksDropped = 0;
  std::vector<SpecAppendixEntry> appendix;
  std::vector<NotationFinding> findings;

  /* Whether the value was refused for its findings. */
  bool refused() const { return !findings.empty(); }
  /* The result as the conformance corpus writes it. */
  std::string toJson() const;
};

/* Strips one value with `options` (SOM §11.10): comments first, then the
 * notation from the outside in, then the whitespace the removals leave.
 * Appendix entries are numbered from 1. A value whose notation has an error
 * finding (other than `rejectedBlock`) is refused and returned unchanged. */
SpecStripTextResult stripNotationText(const std::string& value,
                                      const SpecStripOptions& options);

/* ---- the strip of a document ---------------------------------------------- */

/* One value a strip changed, with what went. */
struct SpecStrippedValue {
  SpecStripValueRef ref;
  std::string original;
  std::string stripped;
  std::vector<SpecStripPiece> pieces;
};

/* A value the emptying rule kept: stripping it would have added `finding`. */
struct SpecStripKept {
  SpecStripValueRef ref;
  std::string finding;
};

/* A reason a stripped document is not valid. */
struct SpecStripFinding {
  std::string kind;  // `notation`, `instance`, `schema` or `parse`
  std::string message;
  std::optional<SpecStripValueRef> ref;  // unset when about no one value

  /* `<kind>: [<ref>: ]<message>`. */
  std::string toString() const;
};

/* The result of SpecDocumentStrip::strip. */
struct SpecStripResult {
  SpecDocument document;  // the stripped copy
  std::vector<SpecStrippedValue> values;
  std::vector<SpecStripKept> kept;
  std::vector<std::string> removedItems;  // list items left empty and removed
  std::vector<SpecAppendixEntry> appendix;  // numbered through the rendition
  // kind -> count, in the order the kinds were first counted
  std::vector<std::pair<std::string, long long>> dropped;
  std::vector<std::pair<std::string, long long>> unmarked;
  std::vector<std::pair<std::string, long long>> appended;
  long long marksDropped = 0;
  std::string readableHeader;
  std::optional<std::string> readable;  // the rendition; unset without a model
  std::vector<SpecStripFinding> findings;

  /* Whether the stripped document is valid and may be written. */
  bool ok() const { return findings.empty(); }
  /* The report: what was dropped, unmarked, moved and kept per kind. */
  std::vector<std::string> report() const;
  /* The result as the corpus writes it (`document` as canonical document
   * JSON, `kept`, `removedItems`, `appendix`, `dropped`, `unmarked`,
   * `appended`, `marksDropped`, `readableHeader`, `readable`, `findings` by
   * kind). */
  std::string toJson() const;
};

/* What SpecDocumentStrip::strip takes beyond the switches. */
struct SpecDocumentStripOptions {
  const SpecModel* model = nullptr;        // the emptying rule, the rendition
  const DocSpecsSchema* schema = nullptr;  // the schema tier of both checks
  std::string rootType;  // the root rendered; default the single populated one
  const SpecReadableSource* source = nullptr;  // named in the readable header
};

/* The strip of a whole document (SOM §11.10). */
class SpecDocumentStrip {
 public:
  /* Strips every value of `document` — content, form-field values and stored
   * headlines — into a copy. Given a model it also applies the emptying rule
   * (a value whose strip would add an instance or schema finding is stripped
   * with the keeping options instead, or left as it was), removes list items
   * left with nothing, numbers the appendix through the rendition, renders the
   * readable rendition and checks that it reads back and validates. */
  static SpecStripResult strip(const SpecDocument& document,
                               const SpecStripOptions& options,
                               const SpecDocumentStripOptions& extra = {});
};

}  // namespace som

#endif  // SPEC_DOCUMENT_STRIP_HPP
