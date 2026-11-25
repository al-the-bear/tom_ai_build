/* spec_document_markdown — DocSpecs-conform Markdown codec for a TomSpecs
 * document (SOM §11), an idiomatic-C++ port of the C `spec_document_markdown`
 * module (a faithful port of the Go / Dart references).
 *
 * The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
 * the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is one markdown heading whose machine-readable identity is the
 * DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
 * human-readable Title-Case member name. Content values are **normal markdown
 * text** under their heading (no fences, no anchors); `@Form` sections use the
 * DocSpecs plain-text `FieldName: value` format; a `List<T>` field heads a
 * `<!--[FOO-LST]-->` container section (SOM §11.2/§11.5) at the owner's child
 * level, its numbered item sub-headings one level deeper and their item-element
 * children one level deeper again — the container itself carries no body.
 * Id-less members are **transparent**: a
 * transparent value member's text or form block is the owner's body region,
 * emitted without a heading and bound at its own path; a transparent
 * section/complex member never heads — its id-bearing descendants hoist to the
 * owner's child level (paths keep the transparent segments).
 *
 * Escaping (SOM §11.3): a content line starting with `#` at column 0 is emitted
 * as `\#`, except inside fenced code blocks, which shield their lines verbatim.
 * Blank lines inside a value are kept as written; parse trims each value of
 * leading/trailing blank lines only. A stored headline's line breaks travel as
 * `<br>` in the heading title. Body slots the parser would otherwise bind
 * elsewhere are preceded by a `<!-- slot: <rel> -->` marker (SOM §11.6).
 *
 * `markdownParse` does not mutate the document — it returns staged values keyed
 * exactly like DocumentJson plus a rejection report (SOM §11.7); the caller
 * applies them as a full overwrite.
 */
#ifndef SPEC_DOCUMENT_MARKDOWN_HPP
#define SPEC_DOCUMENT_MARKDOWN_HPP

#include <cstddef>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

/* Why an imported Markdown block was rejected (SOM §11.7 rejection protocol). */
/* The heading's section id does not resolve against the schema tree at its
 * nesting position. */
inline constexpr const char* kSpecMarkdownRejectUnknownSection =
    "unknownSection";
/* A structurally impossible combination, e.g. a child heading nested under a
 * value-leaf (content/scalar/enum) section. */
inline constexpr const char* kSpecMarkdownRejectKindMismatch = "kindMismatch";
/* Body text with no owning value slot: text before the document root
 * heading. */
inline constexpr const char* kSpecMarkdownRejectOrphanContent = "orphanContent";
/* A value-leaf section heading with an empty body. */
inline constexpr const char* kSpecMarkdownRejectMissingValue = "missingValue";
/* A heading line without a parseable `<!--[id]-->` headline comment. */
inline constexpr const char* kSpecMarkdownRejectMalformedHeading =
    "malformedHeading";
/* A form-table row, a section-table row or a records column names no field
 * the form declares. */
inline constexpr const char* kSpecMarkdownRejectUnknownField = "unknownField";
/* A block that breaks the layout grammar (SOM §11.4, §11.5): a table without
 * its delimiter row or with a row of another cell count, a field given twice,
 * a `refs` / `records` div beside other text or item headings or not holding
 * what it should, an unclosed `refs` / `records` fence. The message says
 * which. */
inline constexpr const char* kSpecMarkdownRejectMalformedBlock =
    "malformedBlock";

/* One rejected block in a Markdown import (SOM §11.7). Reported, never silently
 * dropped: each carries the source line, the offending anchor (section path or
 * id, "" when none), the reason, and a human-readable message. */
struct SpecMarkdownRejection {
  std::size_t line = 0;
  std::string reason;   // one of the reject literals
  std::string message;
  std::string anchor;   // "" when none

  /* Renders as `line N: reason (anchor) — message` (anchor part omitted when
   * empty; the dash is U+2014). */
  std::string display() const;
};

/* The outcome of parsing a Markdown document (SOM §11.7): the staged values plus
 * every rejected block. The values are keyed exactly like DocumentJson so a
 * caller can merge them into a live document as a full overwrite. */
struct SpecMarkdownResult {
  DocumentJson staged;  // content/forms/lists staged values
  std::vector<SpecMarkdownRejection> rejections;
  std::set<std::string> rootPrefixes;  // byte-sorted set of root segments seen
  /* The rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): for every
   * path whose text a rejected block stood in, the value with each such block
   * written as a `rejected` div at its place. An apply that accepts
   * rejections (`applyMarkdownResult(result, true)`) writes these over the
   * staged content, so nothing written is lost; an empty value removes the
   * path's text. Empty for a clean parse. */
  std::map<std::string, std::string> keptContent;

  /* Reports whether no block was rejected. */
  bool isClean() const { return rejections.empty(); }

  /* The number of leaf values successfully parsed (content + form fields). */
  std::size_t appliedCount() const;

  /* The staged values as a DocumentJson (load via SpecDocument::loadJson). */
  const DocumentJson& document() const { return staged; }
};

/* What SpecDocument::fromMarkdown returns: the loaded document plus the parse
 * report it came from. */
struct SpecMarkdownImport {
  /* The document holding every value the parse accepted. */
  SpecDocument document;
  /* The parse report, rejections included. */
  SpecMarkdownResult result;

  /* The blocks the parse rejected, in source order; they are not in
   * `document`. */
  const std::vector<SpecMarkdownRejection>& rejections() const {
    return result.rejections;
  }
};

/* ---- fence tracking ------------------------------------------------------ */

/* A fence state machine (CommonMark-ish): a line whose first non-space run (up
 * to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
 * same-character run at least as long closes it.
 *
 * Public so other markdown-processing modules (the DocSpecs validator's generic
 * parser) share exactly the same fence semantics as this codec. */
class SpecMarkdownFenceTracker {
 public:
  /* Reports whether the tracker is currently inside a fence. */
  bool inFence() const { return ch_ != 0; }
  /* Advances the state machine by one line (`line` has no trailing '\n'). */
  void feed(const std::string& line);

 private:
  char ch_ = 0;         // the fence character, 0 when outside a fence
  std::size_t size_ = 0;  // the opening run length
};

/* ---- naming helpers (SOM §11.2 / §11.5) ---------------------------------- */

/* Expands a camel/Pascal-case identifier into Title Case:
 * `introductionAndScope` / `DemoItem` → `Introduction And Scope` / `Demo
 * Item`. */
std::string titleCase(const std::string& name);

/* Derives the DocSpecs schema id of a `@Document` name (SOM §11.1): `Demo
 * Document` → `demo-document`. */
std::string kebabCase(const std::string& title);

/* The item heading title stem: Title-Case element class name with a trailing
 * `Entry` dropped (SOM §11.5, normative). */
std::string itemTitleStem(const std::string& elementClassName);

/* The `FieldName` label written for a form field: the model field name with the
 * first letter upper-cased (SOM §11.4). */
std::string formLabel(const std::string& fieldName);

/* The `codeSpec="…"` value of a heading-comment key=value region
 * (codespecs_mapping.md §9.2; TS `SpecDocumentMarkdown.codeSpecOf`):
 * double-quoted, single-quoted or bare, trimmed; "" when absent. */
std::string markdownCodeSpecOf(const std::string& region);

/* The `units="…"` value of a heading-comment key=value region (SOM §11.2; TS
 * `SpecDocumentMarkdown.unitsOf`), with the same quoting; the key must start
 * the region or follow whitespace. "" when absent. */
std::string markdownUnitsOf(const std::string& region);

/* ---- export / import ----------------------------------------------------- */

/* Renders the populated subtree of `root` as a DocSpecs-conform Markdown
 * document. Throws std::invalid_argument — the C++ analogue of the C port's
 * NULL+err — on the two conditions this format cannot represent without losing
 * the round-trip: a content value containing an unterminated fenced code block
 * (which would shield the remainder of the document from heading detection),
 * and a form holding a field the model does not declare (SOM §9,
 * "Form-field order"). */
std::string markdownExportRoot(const SpecModel& model,
                               const SpecDocument& document,
                               const SpecRoot& root);

/* A Markdown rendition of a document and the document path behind each of
 * its headings (markdownExportRootWithMap). The renderer is the one place that
 * knows which node a heading came from; a section id alone does not, since ids
 * repeat across a document. */
struct SpecMarkdownRendition {
  /* The rendered Markdown, identical to markdownExportRoot. */
  std::string markdown;
  /* Every heading line (1-based) and the document path it renders. */
  std::map<int, std::string> headingPaths;

  /* The document path of the section `line` belongs to: the path of the
   * heading on that line, else of the nearest heading above it. nullptr for a
   * line before the first heading. Borrowed from this rendition. */
  const std::string* pathAtLine(int line) const;
};

/* markdownExportRoot, plus the document path behind every heading it wrote. A
 * caller holding a rendition line (a DocSpecs schema finding, an editor
 * cursor) resolves it through SpecMarkdownRendition::pathAtLine instead of
 * re-deriving the renderer's layout. Throws as markdownExportRoot does. */
SpecMarkdownRendition markdownExportRootWithMap(const SpecModel& model,
                                                const SpecDocument& document,
                                                const SpecRoot& root);

/* Renders `document` to Markdown in one call (SOM §21).
 *
 * When `rootType` is non-empty, that root is exported (via
 * SpecModel::rootByType). Otherwise the document's single *populated* root is
 * used — a root is populated when `document` holds any value beneath its
 * segment (sectionId if present, else type). Throws std::runtime_error when the
 * default is ambiguous — zero populated roots, or more than one. */
std::string documentToMarkdown(const SpecDocument& document,
                               const SpecModel& model,
                               const std::string& rootType = "");

/* documentToMarkdown, plus the heading map (markdownExportRootWithMap). Same
 * root selection and failures. */
SpecMarkdownRendition documentToMarkdownWithMap(const SpecDocument& document,
                                                const SpecModel& model,
                                                const std::string& rootType = "");

/* Parses `text` into staged values + a rejection report. The parse never
 * mutates a document — `SpecDocument::applyMarkdownResult` applies the result as a full overwrite. */
SpecMarkdownResult markdownParse(const SpecModel& model, const std::string& text);

/* ---- reading-view layout lines (SOM §11.4, §11.5) ------------------------ */
/* The line grammar the parser and the DocSpecs validator share. */

/* `| TomSpecField | Value |` or `| Section | TomSpecField | Value |` at column
 * 0, any case; `*isSection` set for a section table. */
bool markdownLayoutTableHeader(const std::string& line, bool* isSection);
/* `^ {0,3}\|`: a line that starts a table row. */
bool markdownTableLine(const std::string& line);
/* `^:?-+:?$`: a cell of a delimiter row. */
bool markdownDelimiterCell(const std::string& cell);
/* The cells of a table row: split on every `|` not preceded by a backslash,
 * the outer pipes dropped, each cell trimmed; `\|` stays in the cell. */
std::vector<std::string> markdownTableRowCells(const std::string& line);
/* A cell of links only (`[a](x), [b](y)`); their texts in `*texts`. */
bool markdownLinkCell(const std::string& text, std::vector<std::string>* texts);
/* The text of the first link `[t](x)` in `s`. */
bool markdownFirstLinkText(const std::string& s, std::string* text);
/* The opening fence of a `refs` / `records` div; its kind in `*kind`. */
bool markdownListDivOpen(const std::string& line, std::string* kind);
/* `^:{3,}\s*$`: a closing fence. */
bool markdownDivCloseLine(const std::string& line);

}  // namespace som

#endif  // SPEC_DOCUMENT_MARKDOWN_HPP
