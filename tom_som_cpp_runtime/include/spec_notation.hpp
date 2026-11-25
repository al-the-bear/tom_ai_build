/* The reading notation's scanner: one call per text value, returning the
 * value's fenced divs, bracketed spans and citation shapes with their kind,
 * attributes, source ranges and nesting, and the findings the DocSpecs
 * specification lists for the notation (*Reading Notation*, RN-1 … RN-13).
 *
 * The C++ port of `tom_som_dart_runtime`'s `spec_notation.dart` (and its
 * TypeScript port `spec_notation.ts`): the same grammar, the same elements and
 * findings, and the same offsets — UTF-16 code units, as Dart and TypeScript
 * count them, over the UTF-8 text given. All three run
 * `tom_som_conformance/corpus/notation_cases.json`.
 *
 *   - a **fenced div** is a line of at least three colons, indented up to
 *     three spaces, then attribute braces (`::: {.provenance}`) or a bare kind
 *     word (`::: aside`); it closes at a line of at least three colons and
 *     nothing else, and a closing fence closes the innermost open div;
 *   - a **bracketed span** is `[text]` followed immediately by attribute
 *     braces, inside one paragraph;
 *   - a **citation shape** is `(-> ids)` (kind `trace`), `(<- source)` or
 *     `(<~ source)` (kind `provenance`);
 *   - fenced code and code spans are literal, and so are `\:::` and `]\{.`.
 *
 * An unknown kind passes through as an element like any other.
 */
#ifndef SPEC_NOTATION_HPP
#define SPEC_NOTATION_HPP

#include <cstddef>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace som {

/* The kinds the notation registers (RN-5); any other kind passes through. */
inline constexpr const char* registeredNotationKinds[] = {
    "provenance", "trace", "editorial", "aside",    "linked",
    "derived",    "refs",  "records",   "rejected",
};

/* Whether `kind` is one of registeredNotationKinds. */
bool isRegisteredNotationKind(const std::string& kind);

/* The notation's findings (RN-10); each is the rule's name in the DocSpecs
 * validator. */
namespace NotationFindingCode {
inline constexpr const char* kUnclosedDiv = "unclosedDiv";
inline constexpr const char* kStrayClosingFence = "strayClosingFence";
inline constexpr const char* kUnclosedSpan = "unclosedSpan";
inline constexpr const char* kDivWithoutKind = "divWithoutKind";
inline constexpr const char* kUnknownKind = "unknownKind";
inline constexpr const char* kMarkAcrossNotation = "markAcrossNotation";
inline constexpr const char* kAnnotationInsideDiv = "annotationInsideDiv";
inline constexpr const char* kDivInsideAnnotation = "divInsideAnnotation";
inline constexpr const char* kRejectedBlock = "rejectedBlock";
}  // namespace NotationFindingCode

/* Every finding code, in declaration order (the order findings at one offset
 * are listed in). */
inline constexpr const char* kNotationFindingCodes[] = {
    NotationFindingCode::kUnclosedDiv,
    NotationFindingCode::kStrayClosingFence,
    NotationFindingCode::kUnclosedSpan,
    NotationFindingCode::kDivWithoutKind,
    NotationFindingCode::kUnknownKind,
    NotationFindingCode::kMarkAcrossNotation,
    NotationFindingCode::kAnnotationInsideDiv,
    NotationFindingCode::kDivInsideAnnotation,
    NotationFindingCode::kRejectedBlock,
};

/* The severity of `code`: an unknown kind is a "warning", the rest "error". */
std::string notationSeverity(const std::string& code);

/* One element of the notation: a div, a span or a citation. Offsets are UTF-16
 * code units of the scanned text. */
struct NotationElement {
  std::string type;                 // "div", "span" or "citation"
  std::optional<std::string> kind;  // the first class; `trace` / `provenance`
                                    // for a citation; unset without a class
  std::vector<std::string> classes;  // every class, the kind first
  std::optional<std::string> id;     // the `#id` of the attributes
  std::vector<std::pair<std::string, std::string>> attributes;  // key="value"
                                                                // in order
  std::optional<std::string> shape;  // a citation's arrow: ->, <- or <~
  long long start = 0;               // the offset of the first character
  long long end = 0;                 // the offset after the last character
  long long contentStart = 0;        // the offset of the content
  long long contentEnd = 0;          // the offset after the content
  int line = 0;                      // the 1-based line of start
  int endLine = 0;                   // the 1-based line of the last character
  bool closed = true;                // false for a div without closing fence
  std::vector<NotationElement> children;  // nested elements, source order

  /* Whether the kind is registered. */
  bool isRegistered() const;
};

/* One finding of the scan. */
struct NotationFinding {
  std::string code;  // one of the NotationFindingCode values
  long long offset = 0;
  int line = 0;
  std::string message;

  /* The severity of the code. */
  std::string severity() const { return notationSeverity(code); }
  /* Renders as `line N: code — message`. */
  std::string toString() const;
};

/* The result of scanNotation. */
struct NotationScan {
  std::string text;                       // the scanned text (UTF-8)
  std::vector<NotationElement> elements;  // not nested in another, in order
  std::vector<NotationFinding> findings;  // by offset

  /* Every element, depth-first in source order (borrowed pointers). */
  std::vector<const NotationElement*> all() const;
  /* Whether a finding of severity error is present. */
  bool hasErrors() const;
  /* The element `e` as the conformance corpus writes it (JSON, with `source`
   * and `content` sliced from `text`). */
  std::string elementJson(const NotationElement& e) const;
  /* The top-level elements as a JSON array, as the corpus writes them. */
  std::string elementsJson() const;
  /* The findings as a JSON array of {code, severity, line}. */
  std::string findingsJson() const;
};

/* Scans one text value (UTF-8) for the reading notation. `tomSpecs` says the
 * value belongs to a TomSpecs rendition: only then are a div without a class
 * and an unregistered kind reported (RN-10). */
NotationScan scanNotation(const std::string& text, bool tomSpecs = false);

}  // namespace som

#endif  // SPEC_NOTATION_HPP
