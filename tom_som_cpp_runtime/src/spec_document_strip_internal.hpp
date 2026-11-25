/* What the strip (spec_document_strip.cpp) shares with the merge back
 * (spec_document_merge.cpp): the UTF-16 text, the edit scripts and their
 * Myers diff, the inline-mark finder, the values of a document and the
 * finding keys of its instance and schema tiers. Not installed; the merge's
 * rules are those of the TypeScript `_stripInternals`. */
#ifndef SPEC_DOCUMENT_STRIP_INTERNAL_HPP
#define SPEC_DOCUMENT_STRIP_INTERNAL_HPP

#include <cstddef>
#include <string>
#include <utility>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_document.hpp"
#include "spec_document_strip.hpp"
#include "spec_model.hpp"

namespace som {
namespace strip_internal {

/* A text as UTF-16 code units, as Dart and TypeScript index it. */
using U16 = std::u16string;

/* `s[from, to)` as UTF-8; a lone surrogate becomes U+FFFD. */
std::string toUtf8(const U16& s, std::size_t from, std::size_t to);
std::string toUtf8(const U16& s);

/* JavaScript's `\s` / what `trim()` removes. */
bool jsSpace(char16_t c);

enum OpType { kKeep = 0, kDel = 1, kIns = 2 };

/* One step of an edit script over UTF-16 units. */
struct Op {
  int type;
  char16_t ch;
  std::string label;  // "" for a keep
};

/* `s` split after each `\n`, the breaks kept. */
std::vector<U16> lines(const U16& s);

/* The Myers script from `a` to `b`, item by item. */
std::vector<std::pair<int, U16>> myers(const std::vector<U16>& a,
                                       const std::vector<U16>& b);

/* An edit script from `a` to `b`: Myers by line, then by word token; each
 * change labelled `label`. */
std::vector<Op> diff(const U16& a, const U16& b, const std::string& label);

/* An inline review mark: its whole span, its body and the `~>` of a
 * substitution (-1 when none). */
struct MarkAt {
  std::size_t start, end, bodyStart, bodyEnd;
  long long sep;  // -1 when none
};

/* The inline review marks of `t`, outside code. */
std::vector<MarkAt> findMarks(const U16& t);

/* An ordered map of finding keys to the paths they concern (`Map<string,
 * string>`): a key set again keeps its place and takes the new path. */
struct KeyPaths {
  std::vector<std::string> keys;
  std::vector<std::string> paths;

  long find(const std::string& key) const {
    for (std::size_t i = 0; i < keys.size(); i++) {
      if (keys[i] == key) return (long)i;
    }
    return -1;
  }
  void set(const std::string& key, const std::string& path) {
    const long at = find(key);
    if (at >= 0) {
      paths[(std::size_t)at] = path;
      return;
    }
    keys.push_back(key);
    paths.push_back(path);
  }
};

/* Every value of `doc`: stored headlines, content, form fields, each group
 * sorted. */
std::vector<SpecStripValueRef> valueRefs(const SpecDocument& doc);

/* The instance tier's and (given a schema) the schema tier's findings of
 * `doc`, keyed as `instance <code> <path>: <message>` / `schema <rule>
 * <section id>: <message>`, each with the path it concerns. */
KeyPaths tierFindings(const SpecModel& model, const DocSpecsSchema* schema,
                      const std::string& rootType, const SpecDocument& doc);

}  // namespace strip_internal
}  // namespace som

#endif  // SPEC_DOCUMENT_STRIP_INTERNAL_HPP
