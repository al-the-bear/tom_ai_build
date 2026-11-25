/* The merge back of an edited stripped rendition (SOM §11.10). The port of
 * `spec_document_merge.ts`; the texts are worked on as UTF-16 code units, as
 * TypeScript works on them, so every offset agrees with the corpus. */
#include "spec_document_merge.hpp"

#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <memory>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "som_json.hpp"
#include "spec_document_markdown.hpp"
#include "spec_document_strip_internal.hpp"
#include "spec_notation.hpp"
#include "spec_review_annotations.hpp"
#include "spec_text_pattern.hpp"

namespace som {

namespace {

using strip_internal::kDel;
using strip_internal::kIns;
using strip_internal::kKeep;
using strip_internal::Op;
using strip_internal::toUtf8;
using strip_internal::U16;

U16 u16(const std::string& s) { return somUtf16Units(s); }

bool blankU16(const U16& s) {
  for (char16_t c : s) {
    if (!strip_internal::jsSpace(c)) return false;
  }
  return true;
}

std::string visible(const U16& s) {
  std::string out = "\xc2\xab";  // «
  for (std::size_t i = 0, from = 0; i <= s.size(); i++) {
    if (i == s.size() || s[i] == u'\n') {
      out += toUtf8(s, from, i);
      if (i < s.size()) out += "\xe2\x8f\x8e";  // ⏎
      from = i + 1;
    }
  }
  return out + "\xc2\xbb";  // »
}

std::string visible(const std::string& s) { return visible(u16(s)); }

std::string excerpt(const U16& s, std::size_t at) {
  const std::size_t a = std::min(at, s.size()) >= 30 ? std::min(at, s.size()) - 30 : 0;
  const std::size_t z = std::min(s.size(), at + 30);
  return visible(s.substr(a, z > a ? z - a : 0));
}

std::size_t firstDifference(const U16& a, const U16& b) {
  const std::size_t n = std::min(a.size(), b.size());
  for (std::size_t i = 0; i < n; i++) {
    if (a[i] != b[i]) return i;
  }
  return n;
}

std::size_t trailingBreaks(const U16& s) {
  std::size_t n = 0;
  for (std::size_t i = s.size(); i > 0 && s[i - 1] == u'\n'; i--) n++;
  return n;
}

std::size_t leadingBreaks(const U16& s) {
  std::size_t n = 0;
  while (n < s.size() && s[n] == u'\n') n++;
  return n;
}

constexpr int kRoleWhole = 0;
constexpr int kRoleOpener = 1;
constexpr int kRoleCloser = 2;
constexpr int kRoleBoth = 3;

/* Where a gap of the baseline lies in the edited text. */
struct Gap {
  bool leftEdited = false;
  bool rightEdited = false;
  std::size_t start = 0;
  std::size_t end = 0;

  static Gap unchangedAt(std::size_t at) { return Gap{false, false, at, at}; }
  std::size_t at() const { return start; }
  bool unchanged() const { return !leftEdited && !rightEdited && start == end; }
};

/* An edit script from a baseline to an edited text, indexed by baseline
 * offset. */
struct EditMap {
  std::vector<Op> ops;
  std::vector<std::size_t> after;
  std::vector<std::size_t> eBefore;
  std::vector<bool> deleted;

  EditMap(std::vector<Op> script, std::size_t bLength)
      : ops(std::move(script)),
        after(bLength + 1, 0),
        eBefore(ops.size() + 1, 0),
        deleted(bLength, false) {
    std::size_t g = 0;
    for (std::size_t i = 0; i < ops.size(); i++) {
      eBefore[i + 1] = eBefore[i] + (ops[i].type == kDel ? 0 : 1);
      if (ops[i].type != kIns) {
        if (ops[i].type == kDel) deleted[g] = true;
        g++;
        after[g] = i + 1;
      }
    }
  }

  Gap gap(std::size_t g) const {
    const std::size_t p = after[g];
    const bool leftEdited = g > 0 && ops[p - 1].type == kDel;
    std::size_t r = p;
    while (r < ops.size() && ops[r].type == kIns) r++;
    const bool rightEdited = r < ops.size() && ops[r].type == kDel;
    if (!leftEdited && r == p && !rightEdited) return Gap::unchangedAt(eBefore[p]);
    std::size_t s = p;
    while (s > 0 && ops[s - 1].type != kKeep) s--;
    std::size_t t = p;
    while (t < ops.size() && ops[t].type != kKeep) t++;
    return Gap{leftEdited, rightEdited, eBefore[s], eBefore[t]};
  }

  /* The edited-text offset of baseline range `[a, z)` kept whole, else -1. */
  long long keptRange(std::size_t a, std::size_t z) const {
    const std::size_t first = after[a + 1] - 1;
    for (std::size_t k = a; k < z; k++) {
      const std::size_t i = after[k + 1] - 1;
      if (ops[i].type != kKeep || i != first + (k - a)) return -1;
    }
    return (long long)eBefore[first];
  }
};

/* A line edit script from a baseline to an edited text. */
struct LineEditMap {
  std::vector<std::pair<int, U16>> ops;
  std::vector<std::size_t> after;
  std::vector<std::size_t> eBefore;

  LineEditMap(const U16& b, const U16& e) {
    const std::vector<U16> bl = strip_internal::lines(b);
    const std::vector<U16> el = strip_internal::lines(e);
    ops = strip_internal::myers(bl, el);
    after.assign(bl.size() + 1, 0);
    eBefore.assign(ops.size() + 1, 0);
    std::size_t k = 0;
    for (std::size_t i = 0; i < ops.size(); i++) {
      eBefore[i + 1] = eBefore[i] + (ops[i].first == kDel ? 0 : ops[i].second.size());
      if (ops[i].first != kIns) {
        k++;
        after[k] = i + 1;
      }
    }
  }

  Gap gap(std::size_t k) const {
    const std::size_t p = after[k];
    const bool leftEdited = k > 0 && ops[p - 1].first == kDel;
    std::size_t r = p;
    while (r < ops.size() && ops[r].first == kIns) r++;
    const bool rightEdited = r < ops.size() && ops[r].first == kDel;
    if (!leftEdited && r == p && !rightEdited) return Gap::unchangedAt(eBefore[p]);
    std::size_t s = p;
    while (s > 0 && ops[s - 1].first != kKeep) s--;
    std::size_t t = p;
    while (t < ops.size() && ops[t].first != kKeep) t++;
    return Gap{leftEdited, rightEdited, eBefore[s], eBefore[t]};
  }

  /* Where a block goes back in a gap edited on both sides: before the
   * paragraph the edited text holds where the baseline had as many
   * paragraphs before the block as it removed. */
  std::size_t paragraphPlace(const Gap& gap, std::size_t k) const {
    const std::size_t p = after[k];
    std::size_t s = p;
    while (s > 0 && ops[s - 1].first != kKeep) s--;
    std::size_t before = 0;
    bool blank = true;
    for (std::size_t i = s; i < p; i++) {
      if (ops[i].first != kDel) continue;
      const bool isBlank = blankU16(ops[i].second);
      if (!isBlank && blank) before++;
      blank = isBlank;
    }
    if (before == 0) return gap.start;
    std::size_t count = 0;
    blank = true;
    for (std::size_t i = s; i < ops.size() && ops[i].first != kKeep; i++) {
      if (ops[i].first != kIns) continue;
      const bool isBlank = blankU16(ops[i].second);
      if (!isBlank && blank) {
        if (count == before) return eBefore[i];
        count++;
      }
      blank = isBlank;
    }
    return gap.end;
  }
};

/* The script with each run of whitespace edits slid to lead (`leading`) or
 * trail its unchanged neighbours, where the same whitespace stands there. */
std::vector<Op> slide(const std::vector<Op>& ops, bool leading) {
  std::vector<Op> out = ops;
  auto ws = [](char16_t c) { return strip_internal::jsSpace(c); };
  std::size_t s = 0;
  while (s < out.size()) {
    if (out[s].type == kKeep) {
      s++;
      continue;
    }
    std::size_t t = s;
    while (t < out.size() && out[t].type == out[s].type) t++;
    if (t < out.size() && out[t].type != kKeep) {
      while (t < out.size() && out[t].type != kKeep) t++;
      s = t;
      continue;
    }
    const int type = out[s].type;
    if (leading) {
      while (s > 0 && out[s - 1].type == kKeep && ws(out[t - 1].ch) &&
             out[s - 1].ch == out[t - 1].ch) {
        out[t - 1] = Op{kKeep, out[t - 1].ch, std::string()};
        out[s - 1] = Op{type, out[s - 1].ch, "edit"};
        s--;
        t--;
      }
    } else {
      while (t < out.size() && out[t].type == kKeep && ws(out[s].ch) &&
             out[s].ch == out[t].ch) {
        out[s] = Op{kKeep, out[s].ch, std::string()};
        out[t] = Op{type, out[t].ch, "edit"};
        s++;
        t++;
      }
    }
    s = t;
  }
  return out;
}

std::size_t lineIndex(const U16& b, std::size_t g) {
  std::size_t k = 0;
  for (std::size_t i = 0; i < g; i++) {
    if (b[i] == u'\n') k++;
  }
  if (g == b.size() && !b.empty() && b.back() != u'\n') k++;
  return k;
}

/* Whether the edit removed the whole sentence of `b` holding offset `g`. */
bool sentenceRemoved(const U16& b, std::size_t g, const EditMap& map) {
  auto ends = [&b](std::size_t i) {
    return (b[i] == u'.' || b[i] == u'!' || b[i] == u'?') &&
           (i + 1 >= b.size() || strip_internal::jsSpace(b[i + 1]));
  };
  std::size_t s = g;
  while (s > 0 && b[s - 1] != u'\n' && !(s < g && ends(s - 1))) {
    s--;
  }
  std::size_t e = g;
  while (e < b.size() && b[e] != u'\n') {
    if (ends(e)) {
      e++;
      break;
    }
    e++;
  }
  bool any = false;
  for (std::size_t i = s; i < e; i++) {
    if (strip_internal::jsSpace(b[i])) continue;
    any = true;
    if (!map.deleted[i]) return false;
  }
  return any;
}

/* What each piece is, read from the original `o`: a whole element, the
 * opening or the closing marker of an unmarked element, or both. */
std::vector<int> pieceRoles(const U16& o, const std::string& o8,
                            const std::vector<SpecStripPiece>& pieces,
                            const std::vector<U16>& removed) {
  std::vector<long long> at(o.size(), -1);
  for (std::size_t i = 0; i < pieces.size(); i++) {
    const std::size_t from = (std::size_t)pieces[i].origin;
    for (std::size_t k = from; k < from + removed[i].size() && k < o.size(); k++) {
      at[k] = (long long)i;
    }
  }
  std::vector<bool> opener(pieces.size(), false);
  std::vector<bool> closer(pieces.size(), false);
  auto first = [&](std::size_t s, std::size_t e) -> long long {
    for (std::size_t k = s; k < e && k < o.size(); k++) {
      if (!strip_internal::jsSpace(o[k])) return at[k];
    }
    return -1;
  };
  auto whole = [&](std::size_t start, std::size_t end) {
    if (!(start < end && start < o.size() && at[start] >= 0)) return false;
    for (std::size_t k = start; k < end; k++) {
      if (k >= o.size() || at[k] != at[start]) return false;
    }
    return true;
  };
  auto pair = [&](std::size_t start, std::size_t openEnd, std::size_t closeStart,
                  std::size_t end) {
    if (whole(start, end)) return;
    const long long po = first(start, openEnd);
    const long long pc = first(closeStart, end);
    if (po >= 0 && po != pc) opener[(std::size_t)po] = true;
    if (pc >= 0 && pc != po) closer[(std::size_t)pc] = true;
  };
  std::function<void(const std::vector<NotationElement>&)> walk =
      [&](const std::vector<NotationElement>& list) {
        for (const NotationElement& e : list) {
          if (e.type == "citation") {
            if (!whole((std::size_t)e.start, (std::size_t)e.end)) {
              const long long po =
                  first((std::size_t)e.start + 1, (std::size_t)e.contentStart);
              if (po >= 0) opener[(std::size_t)po] = true;
            } else {
              continue;
            }
          } else {
            pair((std::size_t)e.start, (std::size_t)e.contentStart,
                 (std::size_t)e.contentEnd, (std::size_t)e.end);
          }
          walk(e.children);
        }
      };
  walk(scanNotation(o8, true).elements);
  for (const auto& m : strip_internal::findMarks(o)) {
    pair(m.start, m.sep >= 0 ? (std::size_t)m.sep + 2 : m.bodyStart, m.bodyEnd, m.end);
  }
  std::vector<int> roles;
  for (std::size_t i = 0; i < pieces.size(); i++) {
    roles.push_back(opener[i] && closer[i] ? kRoleBoth
                    : opener[i]           ? kRoleOpener
                    : closer[i]           ? kRoleCloser
                                          : kRoleWhole);
  }
  return roles;
}

struct Put {
  std::size_t at;
  std::size_t order;
  U16 text;
  std::size_t replace = 0;
  bool normalize = false;
  std::size_t before = 2;
  std::size_t after = 2;
};

std::size_t notationErrors(const std::string& s) {
  std::size_t n = 0;
  for (const auto& f : scanNotation(s, true).findings) {
    if (f.severity() == "error" && f.code != NotationFindingCode::kRejectedBlock) n++;
  }
  return n;
}

std::string refKey(const SpecStripValueRef& r) {
  std::string k = r.headline ? "h" : r.field.has_value() ? "f" : "c";
  k.push_back('\0');
  k += r.path;
  k.push_back('\0');
  k += r.field.value_or("");
  return k;
}

std::string optionsText(const SpecStripOptions& o) {
  const std::string s = SpecReadableHeader::format(o);
  const std::size_t from = std::string("<!-- readable:").size();
  std::string t = s.substr(from, s.size() - 3 - from);
  std::size_t a = 0, b = t.size();
  while (a < b && (t[a] == ' ' || t[a] == '\t')) a++;
  while (b > a && (t[b - 1] == ' ' || t[b - 1] == '\t')) b--;
  return t.substr(a, b - a);
}

/* The section-id paths of `markdown`'s headings, in order. */
std::vector<std::string> headingPaths(const std::string& markdown) {
  std::vector<std::string> out;
  std::function<void(const std::vector<std::unique_ptr<DocSpecsSection>>&,
                     const std::string&)>
      walk = [&](const std::vector<std::unique_ptr<DocSpecsSection>>& list,
                 const std::string& prefix) {
        for (const auto& s : list) {
          const std::string id = s->id.empty() ? "?" : s->id;
          const std::string p = prefix.empty() ? id : prefix + "/" + id;
          out.push_back(p);
          walk(s->children, p);
        }
      };
  walk(docspecsParseDocument(markdown).sections, "");
  return out;
}

/* The lists of `doc` under the roots, each as its items and their ids. */
std::map<std::string, std::pair<std::vector<std::string>,
                                std::map<std::string, std::string>>>
listsUnder(const SpecDocument& doc,
           const std::function<bool(const std::string&)>& inRoot) {
  std::map<std::string,
           std::pair<std::vector<std::string>, std::map<std::string, std::string>>>
      out;
  for (const auto& kv : doc.toJson().lists) {
    if (inRoot(kv.first)) out[kv.first] = {kv.second.items, kv.second.ids};
  }
  return out;
}

SpecDocument docCopy(const SpecDocument& d) {
  SpecDocument c;
  c.loadJson(d.toJson());
  return c;
}

}  // namespace

// ---- results ------------------------------------------------------------------

std::string SpecStripMergePlaced::toJson() const {
  return "{\"at\":" + std::to_string(at) + ",\"removed\":" + jsonEncodeStr(piece.removed) +
         "}";
}

SpecStripMergeConflict SpecStripMergeConflict::about(
    const SpecStripValueRef& value) const {
  SpecStripMergeConflict c = *this;
  c.ref = value;
  return c;
}

std::vector<std::string> SpecStripMergeConflict::reportLines() const {
  std::vector<std::string> out{"CONFLICT " +
                               (ref.has_value() ? specStripMergeLabel(*ref)
                                                : std::string("(document)")) +
                               " \xe2\x80\x94 " + message};
  if (piece.has_value() || !excerptB.empty()) {
    out.push_back("  O: " + excerptO);
    out.push_back("  B: " + excerptB);
    out.push_back("  E: " + excerptE);
  }
  if (piece.has_value()) out.push_back("  piece: " + visible(piece->removed));
  return out;
}

std::string SpecStripMergeConflict::toJson() const {
  std::string out = "{\"code\":" + jsonEncodeStr(code);
  if (ref.has_value()) out += ",\"value\":" + ref->toJson();
  if (piece.has_value()) out += ",\"removed\":" + jsonEncodeStr(piece->removed);
  return out + "}";
}

std::string SpecStripValueMerge::toJson() const {
  std::string out = "{\"text\":" +
                    (text.has_value() ? jsonEncodeStr(*text) : std::string("null")) +
                    ",\"restored\":" + std::to_string(restored) + ",\"placed\":[";
  for (std::size_t i = 0; i < placed.size(); i++) {
    if (i > 0) out += ",";
    out += placed[i].toJson();
  }
  out += "],\"conflicts\":[";
  for (std::size_t i = 0; i < conflicts.size(); i++) {
    if (i > 0) out += ",";
    out += conflicts[i].toJson();
  }
  return out + "]}";
}

std::string specStripMergeLabel(const SpecStripValueRef& ref) {
  if (ref.headline) return ref.path + " (headline)";
  if (ref.field.has_value()) return ref.path + " / " + *ref.field;
  return ref.path;
}

std::string SpecStripMergeRefusal::reportLine() const {
  return "REFUSED " + (path.empty() ? std::string("(document)") : path) +
         " \xe2\x80\x94 " + message;
}

std::string SpecStripMergeRefusal::toJson() const {
  return "{\"code\":" + jsonEncodeStr(code) + ",\"path\":" + jsonEncodeStr(path) + "}";
}

std::vector<std::string> SpecStripMergeResult::report() const {
  std::vector<std::string> out;
  for (const auto& m : merged) {
    out.push_back("MERGED " + specStripMergeLabel(m.ref) + " \xe2\x80\x94 " +
                  std::to_string(m.restored) + " pieces put back");
    for (std::size_t k = 0; k < m.placed.size(); k++) {
      out.push_back("PLACED " + specStripMergeLabel(m.ref) + " \xe2\x80\x94 check");
    }
  }
  for (const auto& c : conflicts) {
    for (const auto& l : c.reportLines()) out.push_back(l);
  }
  for (const auto& r : refusals) out.push_back(r.reportLine());
  return out;
}

// ---- one value ------------------------------------------------------------------

SpecStripValueMerge mergeStrippedValue(const std::string& o8, const std::string& b8,
                                       const std::string& e8,
                                       const std::vector<SpecStripPiece>& pieces) {
  SpecStripValueMerge result;
  if (e8 == b8) {
    result.text = o8;
    result.restored = (long long)pieces.size();
    return result;
  }
  const U16 o = u16(o8), b = u16(b8), e = u16(e8);
  std::vector<U16> removedOf, insertedOf;
  for (const auto& p : pieces) {
    removedOf.push_back(u16(p.removed));
    insertedOf.push_back(u16(p.inserted));
  }
  const std::vector<int> roles = pieceRoles(o, o8, pieces, removedOf);
  const std::vector<Op> ops = strip_internal::diff(b, e, "edit");
  const EditMap map(ops, b.size());
  // An opening marker is judged on the script whose whitespace edits trail
  // their run, a closing one on the script whose whitespace edits lead it.
  const EditMap trailing(slide(ops, false), b.size());
  const EditMap leading(slide(ops, true), b.size());
  std::optional<LineEditMap> lines;
  std::vector<Put> puts;
  std::set<std::size_t> placedAt;
  std::vector<SpecStripMergeConflict> conflicts;
  long long restored = 0;
  for (std::size_t i = 0; i < pieces.size(); i++) {
    const SpecStripPiece& p = pieces[i];
    const std::size_t anchor = (std::size_t)p.anchor;
    auto conflict = [&](const std::string& code, const std::string& message,
                        std::size_t eAt) {
      SpecStripMergeConflict c;
      c.code = code;
      c.message = message;
      c.piece = p;
      c.excerptO = excerpt(o, (std::size_t)p.origin);
      c.excerptB = excerpt(b, anchor);
      c.excerptE = excerpt(e, eAt);
      conflicts.push_back(std::move(c));
    };

    if (!insertedOf[i].empty()) {
      const long long at = map.keptRange(anchor, anchor + insertedOf[i].size());
      if (at < 0) {
        conflict("stripTextEdited",
                 "the text the strip wrote in place of a piece was edited",
                 map.gap(anchor).start);
        continue;
      }
      Put put{(std::size_t)at, i, removedOf[i]};
      put.replace = insertedOf[i].size();
      puts.push_back(put);
      restored++;
      continue;
    }

    const int role = roles[i];
    std::size_t g = anchor;
    U16 text = removedOf[i];
    if (role == kRoleWhole && text.find(u'\n') != U16::npos) {
      while (g > 0 && b[g - 1] != u'\n' && g < b.size() && text[0] == b[g]) {
        text = text.substr(1) + text[0];
        g++;
      }
      if (g == 0 || b[g - 1] == u'\n' || g == b.size()) {
        if (!lines.has_value()) lines.emplace(b, e);
        const std::size_t k = lineIndex(b, g);
        const Gap gap = lines->gap(k);
        if (gap.unchanged()) {
          puts.push_back(Put{gap.at(), i, text});
          restored++;
          continue;
        }
        const std::size_t at = !gap.leftEdited    ? gap.start
                               : !gap.rightEdited ? gap.end
                                                  : lines->paragraphPlace(gap, k);
        if (at > 0 && at < e.size() && e[at - 1] != u'\n') {
          conflict("unplaceable", "the block has no line boundary to go back to", at);
          continue;
        }
        // The block keeps the distance it had from the text around it in the
        // original: a blank line, or none when it stood right against a line.
        const U16& rem = removedOf[i];
        const std::size_t core = (std::size_t)p.origin + leadingBreaks(rem);
        const std::size_t coreEnd =
            (std::size_t)p.origin + rem.size() - trailingBreaks(rem);
        auto distance = [](std::size_t breaks, bool edge) -> std::size_t {
          return edge ? 2 : std::min<std::size_t>(2, std::max<std::size_t>(1, breaks));
        };
        Put put{at, i, text};
        put.normalize = true;
        put.before = distance(trailingBreaks(o.substr(0, core)), core == 0);
        put.after = distance(leadingBreaks(coreEnd < o.size() ? o.substr(coreEnd) : U16()),
                             coreEnd >= o.size());
        puts.push_back(put);
        restored++;
        continue;
      }
      g = anchor;
      text = removedOf[i];
    }

    const EditMap& m = role == kRoleOpener ? trailing : role == kRoleCloser ? leading : map;
    const Gap gap = m.gap(g);
    if (gap.unchanged()) {
      puts.push_back(Put{gap.at(), i, text});
      restored++;
      continue;
    }
    if (blankU16(text)) continue;  // normalised whitespace at an edit
    if (role == kRoleOpener || role == kRoleCloser) {
      if (gap.leftEdited && gap.rightEdited) {
        conflict("crossesBoundary", "an edit crosses the boundary of an unmarked element",
                 gap.start);
        continue;
      }
      // The edit on the inner side of the marker goes inside the element.
      const std::size_t at = role == kRoleOpener
                                 ? (!gap.leftEdited ? gap.start : gap.end)
                                 : (!gap.rightEdited ? gap.end : gap.start);
      puts.push_back(Put{at, i, text});
      restored++;
    } else if (role == kRoleBoth) {
      conflict("crossesBoundary",
               "an edit touches the boundary between two unmarked elements", gap.start);
    } else {
      if (sentenceRemoved(b, g, map)) {
        conflict("sentenceRemoved", "the edit removed the whole sentence holding the piece",
                 gap.start);
        continue;
      }
      puts.push_back(Put{gap.end, i, text});
      placedAt.insert(i);
      restored++;
    }
  }
  if (!conflicts.empty()) {
    result.conflicts = std::move(conflicts);
    return result;
  }

  std::stable_sort(puts.begin(), puts.end(), [](const Put& x, const Put& y) {
    return x.at != y.at ? x.at < y.at : x.order < y.order;
  });
  U16 out;
  std::vector<SpecStripMergePlaced> placed;
  std::size_t pos = 0;
  for (const Put& put : puts) {
    if (put.at < pos) {
      SpecStripMergeConflict c;
      c.code = "stripTextEdited";
      c.message = "two pieces claim the same text";
      c.piece = pieces[put.order];
      conflicts.push_back(std::move(c));
      continue;
    }
    out += e.substr(pos, put.at - pos);
    pos = put.at;
    if (put.normalize) {
      std::size_t a = 0, z = put.text.size();
      while (a < z && put.text[a] == u'\n') a++;
      while (z > a && put.text[z - 1] == u'\n') z--;
      const U16 core = put.text.substr(a, z - a);
      if (!out.empty()) {
        const std::size_t have = trailingBreaks(out);
        if (put.before > have) out.append(put.before - have, u'\n');
      }
      if (placedAt.count(put.order) != 0) {
        placed.push_back(SpecStripMergePlaced{pieces[put.order], (long long)out.size()});
      }
      out += core;
      const U16 right = pos < e.size() ? e.substr(pos) : U16();
      if (!right.empty()) {
        const std::size_t have = leadingBreaks(right);
        if (put.after > have) out.append(put.after - have, u'\n');
      }
    } else {
      if (placedAt.count(put.order) != 0) {
        placed.push_back(SpecStripMergePlaced{pieces[put.order], (long long)out.size()});
      }
      out += put.text;
    }
    pos += put.replace;
  }
  if (pos < e.size()) out += e.substr(pos);
  const std::string merged = toUtf8(out);

  if (notationErrors(merged) > notationErrors(e8) + notationErrors(o8)) {
    SpecStripMergeConflict c;
    c.code = "notation";
    c.message =
        "the merged value has a notation error neither the original nor the edited text "
        "has";
    conflicts.push_back(std::move(c));
  }
  if (annotationIssuesText(merged).size() >
      annotationIssuesText(e8).size() + annotationIssuesText(o8).size()) {
    SpecStripMergeConflict c;
    c.code = "annotations";
    c.message =
        "the merged value has a malformed review annotation neither the original nor the "
        "edited text has";
    conflicts.push_back(std::move(c));
  }
  if (!conflicts.empty()) {
    result.conflicts = std::move(conflicts);
    return result;
  }
  result.text = merged;
  result.restored = restored;
  result.placed = std::move(placed);
  return result;
}

// ---- a document -------------------------------------------------------------------

SpecStripMergeResult SpecStripMerge::merge(const SpecDocument& original,
                                           const std::string& edited,
                                           const SpecStripMergeOptions& extra) {
  if (extra.model == nullptr) {
    throw SpecStripUsageError("a merge needs the model");
  }
  const SpecModel& model = *extra.model;
  const DocSpecsSchema* schema = extra.schema;
  const std::string& rootType = extra.rootType;
  const SpecMarkdownResult parsed = markdownParse(model, edited);
  std::optional<SpecReadableHeader> header;
  if (parsed.readableHeader.has_value()) {
    header = SpecReadableHeader::parse(*parsed.readableHeader);
    if (!header.has_value()) {
      throw SpecStripUsageError("the readable header cannot be read: " +
                                *parsed.readableHeader);
    }
  }
  SpecStripOptions opts;
  if (extra.options.has_value()) {
    if (header.has_value() && optionsText(header->options) != optionsText(*extra.options)) {
      throw SpecStripUsageError("the switches given (" + optionsText(*extra.options) +
                                ") disagree with the readable header (" +
                                optionsText(header->options) + ")");
    }
    opts = *extra.options;
  } else if (header.has_value()) {
    opts = header->options;
  } else {
    throw SpecStripUsageError(
        "the rendition has no readable header: name the switches it was stripped with");
  }

  auto refused = [&opts](std::vector<SpecStripMergeRefusal> r, bool stale) {
    SpecStripMergeResult res;
    res.options = opts;
    res.stale = stale;
    res.refusals = std::move(r);
    return res;
  };

  if (!parsed.rejections.empty()) {
    std::vector<SpecStripMergeRefusal> r;
    for (const auto& rej : parsed.rejections) {
      r.push_back(SpecStripMergeRefusal{
          "rejected", "", "line " + std::to_string(rej.line) + ": " + rej.message});
    }
    return refused(std::move(r), false);
  }

  const SpecReadableSource* source =
      header.has_value() && header->source.has_value() ? &*header->source : nullptr;
  const std::optional<std::string>& currentRevision = extra.currentRevision;
  const bool stale = extra.base != nullptr ||
                     (source != nullptr && source->revision.has_value() &&
                      currentRevision.has_value() && *source->revision != *currentRevision);
  std::optional<SpecDocument> loadedBase;
  const SpecDocument* origin = &original;
  if (stale) {
    if (extra.base != nullptr) {
      origin = extra.base;
    } else {
      if (source != nullptr && source->commit.has_value() && !source->dirty &&
          extra.loadBase) {
        loadedBase = extra.loadBase(*source);
      }
      if (!loadedBase.has_value()) {
        const std::string why = source == nullptr || !source->commit.has_value()
                                    ? "names no commit"
                                : source->dirty ? "names a dirty commit"
                                                : "names a commit that could not be read";
        const std::string then =
            source != nullptr && source->revision.has_value() ? *source->revision : "null";
        return refused({SpecStripMergeRefusal{
                           "stale", "",
                           "the original moved since the export (revision " + then +
                               " then, " + currentRevision.value_or("null") +
                               " now) and there is no base: the header " + why +
                               "; give the original as it was at the export"}},
                       true);
      }
      origin = &*loadedBase;
    }
  }

  SpecDocumentStripOptions stripExtra;
  stripExtra.model = &model;
  stripExtra.schema = schema;
  stripExtra.rootType = rootType;
  const SpecStripResult strip = SpecDocumentStrip::strip(*origin, opts, stripExtra);
  if (!strip.ok() || !strip.readable.has_value()) {
    std::vector<SpecStripMergeRefusal> r;
    for (const auto& f : strip.findings) {
      r.push_back(SpecStripMergeRefusal{"strip", f.ref.has_value() ? f.ref->label() : "",
                                        f.toString()});
    }
    if (r.empty()) {
      r.push_back(SpecStripMergeRefusal{"strip", "", "the base renders no rendition"});
    }
    return refused(std::move(r), stale);
  }
  const SpecDocument& bDoc = strip.document;
  SpecDocument eDoc;
  eDoc.applyMarkdownResult(parsed);
  const std::vector<std::string> roots(parsed.rootPrefixes.begin(),
                                       parsed.rootPrefixes.end());
  const std::function<bool(const std::string&)> inRoot = [&roots](const std::string& p) {
    for (const std::string& r : roots) {
      if (p == r || (p.size() > r.size() && p.compare(0, r.size(), r) == 0 &&
                     (p[r.size()] == '/' || p[r.size()] == '-'))) {
        return true;
      }
    }
    return false;
  };

  // Structural edits.
  std::vector<SpecStripMergeRefusal> refusals;
  const std::vector<std::string> bHeadings = headingPaths(*strip.readable);
  const std::vector<std::string> eHeadings = headingPaths(edited);
  if (bHeadings != eHeadings) {
    const std::set<std::string> bSet(bHeadings.begin(), bHeadings.end());
    const std::set<std::string> eSet(eHeadings.begin(), eHeadings.end());
    for (const auto& p : eHeadings) {
      if (bSet.count(p) == 0) refusals.push_back({"sectionAdded", p, "a section added"});
    }
    for (const auto& p : bHeadings) {
      if (eSet.count(p) == 0) refusals.push_back({"sectionRemoved", p, "a section removed"});
    }
    if (refusals.empty()) {
      std::vector<std::string> common, want;
      for (const auto& p : eHeadings) {
        if (bSet.count(p) != 0) common.push_back(p);
      }
      for (const auto& p : bHeadings) {
        if (eSet.count(p) != 0) want.push_back(p);
      }
      for (std::size_t i = 0; i < common.size(); i++) {
        if (common[i] != want[i]) {
          refusals.push_back({"sectionMoved", common[i], "a section moved"});
          break;
        }
      }
    }
  }
  const auto bLists = listsUnder(bDoc, inRoot);
  const auto eLists = listsUnder(eDoc, inRoot);
  std::set<std::string> listKeys;
  for (const auto& kv : bLists) listKeys.insert(kv.first);
  for (const auto& kv : eLists) listKeys.insert(kv.first);
  for (const std::string& l : listKeys) {
    auto bi = bLists.find(l);
    auto ei = eLists.find(l);
    if (bi == bLists.end() || ei == eLists.end() || bi->second != ei->second) {
      refusals.push_back({"listItems", l, "list items added, removed, moved or renamed"});
    }
  }
  for (const char* code : {"codeSpec", "units"}) {
    const bool isCode = std::string(code) == "codeSpec";
    auto read = [isCode](const SpecDocument& d, const std::string& p) {
      return isCode ? d.codeSpec(p) : d.units(p);
    };
    std::set<std::string> all;
    for (const SpecDocument* d : std::array<const SpecDocument*, 2>{&bDoc, &eDoc}) {
      for (const std::string& p : isCode ? d->codeSpecPaths() : d->unitsPaths()) {
        if (inRoot(p)) all.insert(p);
      }
    }
    for (const std::string& p : all) {
      if (read(bDoc, p) != read(eDoc, p)) {
        refusals.push_back({code, p, std::string("a changed ") + code});
      }
    }
  }
  std::map<std::string, SpecStripValueRef> byKey;
  for (const SpecDocument* d : std::array<const SpecDocument*, 2>{&bDoc, &eDoc}) {
    for (const SpecStripValueRef& r : strip_internal::valueRefs(*d)) {
      if (inRoot(r.path)) byKey[refKey(r)] = r;
    }
  }
  std::vector<SpecStripValueRef> refs;
  for (const auto& kv : byKey) refs.push_back(kv.second);
  std::stable_sort(refs.begin(), refs.end(),
                   [](const SpecStripValueRef& x, const SpecStripValueRef& y) {
                     if (x.path != y.path) return x.path < y.path;
                     if (x.headline != y.headline) return x.headline;
                     return x.field.value_or("") < y.field.value_or("");
                   });
  auto refusedAt = [&refusals](const std::string& path) {
    for (const auto& r : refusals) {
      if (r.path == path) return true;
    }
    return false;
  };
  for (const SpecStripValueRef& ref : refs) {
    if (ref.read(bDoc).empty() && !ref.read(eDoc).empty() &&
        !bDoc.hasValuesUnder(ref.path) && !refusedAt(ref.path)) {
      refusals.push_back(
          {"sectionAdded", ref.path, "a value in a section the rendition does not show"});
    }
  }

  // The values.
  std::map<std::string, const std::vector<SpecStripPiece>*> pieces;
  for (const auto& v : strip.values) pieces[refKey(v.ref)] = &v.pieces;
  const std::vector<SpecStripPiece> none;
  SpecStripMergeResult res;
  res.options = opts;
  res.stale = stale;
  for (const SpecStripValueRef& ref : refs) {
    const std::string bText = ref.read(bDoc);
    const std::string eText = ref.read(eDoc);
    // A wrapped paragraph written in a table cell reads back on one line
    // (SOM §11.4): that alone is no edit.
    if (bText == eText) continue;
    const auto joined = markdownWrappedParagraphJoined(bText);
    if (joined.has_value() && *joined == eText) continue;
    if (refusedAt(ref.path)) continue;
    // A value whose section came or went with a refused edit is that edit.
    if (!refusals.empty() &&
        (!bDoc.hasValuesUnder(ref.path) || !eDoc.hasValuesUnder(ref.path))) {
      continue;
    }
    const std::string o = ref.read(*origin);
    auto it = pieces.find(refKey(ref));
    const SpecStripValueMerge r =
        mergeStrippedValue(o, bText, eText, it != pieces.end() ? *it->second : none);
    const std::string now = ref.read(original);
    if (stale && now != o) {
      // The edit is already in the moved original (the same rendition merged
      // before): nothing to do for this value.
      if (r.ok() && r.text == now) continue;
      const U16 b16 = u16(bText), e16 = u16(eText), o16 = u16(o), now16 = u16(now);
      const std::size_t at = firstDifference(b16, e16);
      SpecStripMergeConflict c;
      c.code = "changedBothSides";
      c.message = "the value changed in the original since the export, and in the rendition";
      c.ref = ref;
      c.excerptO = excerpt(now16, firstDifference(o16, now16));
      c.excerptB = excerpt(b16, at);
      c.excerptE = excerpt(e16, at);
      res.conflicts.push_back(std::move(c));
      continue;
    }
    if (!r.ok()) {
      for (const auto& c : r.conflicts) res.conflicts.push_back(c.about(ref));
      continue;
    }
    res.merged.push_back(SpecStripMergedValue{ref, *r.text, r.restored, r.placed});
  }
  if (!res.conflicts.empty() || !refusals.empty()) {
    res.refusals = std::move(refusals);
    return res;
  }

  // Write and verify.
  SpecDocument out = docCopy(original);
  for (const auto& m : res.merged) m.ref.write(out, m.text);
  std::set<std::string> expected;
  for (const auto& m : res.merged) {
    if (m.text != m.ref.read(original)) expected.insert(refKey(m.ref));
  }
  std::set<std::string> changed;
  for (const SpecDocument* d : std::array<const SpecDocument*, 2>{&original, &out}) {
    for (const SpecStripValueRef& r : strip_internal::valueRefs(*d)) {
      if (r.read(original) != r.read(out)) changed.insert(refKey(r));
    }
  }
  if (changed != expected) {
    SpecStripMergeConflict c;
    c.code = "newFinding";
    c.message = "the merged document changes other values than the merged ones";
    res.conflicts.push_back(std::move(c));
  }
  const SpecStripResult again = SpecDocumentStrip::strip(out, opts, stripExtra);
  for (const auto& m : res.merged) {
    const std::string back = m.ref.read(again.document);
    const std::string want = m.ref.read(eDoc);
    if (back != want) {
      SpecStripMergeConflict c;
      c.code = "notStrippedBack";
      c.message = "the merged value does not strip back to the edited text";
      c.ref = m.ref;
      c.excerptO = excerpt(u16(m.text), 0);
      c.excerptB = excerpt(u16(back), 0);
      c.excerptE = excerpt(u16(want), 0);
      res.conflicts.push_back(std::move(c));
    }
  }
  const strip_internal::KeyPaths before =
      strip_internal::tierFindings(model, schema, rootType, original);
  for (const std::string& k :
       strip_internal::tierFindings(model, schema, rootType, out).keys) {
    if (before.find(k) < 0) {
      SpecStripMergeConflict c;
      c.code = "newFinding";
      c.message = "the merged document has a new finding: " + k;
      res.conflicts.push_back(std::move(c));
    }
  }
  if (res.conflicts.empty()) res.document = std::move(out);
  return res;
}

std::optional<std::string> SpecStripMerge::gitShowFile(const std::string& commit,
                                                       const std::string& filePath) {
  char* resolved = ::realpath(filePath.c_str(), nullptr);
  std::string file = resolved != nullptr ? std::string(resolved) : filePath;
  std::free(resolved);
  const std::size_t slash = file.rfind('/');
  const std::string dir = slash == std::string::npos ? "." : file.substr(0, slash);
  const std::string name = slash == std::string::npos ? file : file.substr(slash + 1);
  auto quote = [](const std::string& s) {
    std::string q = "'";
    for (char c : s) {
      if (c == '\'') {
        q += "'\\''";
      } else {
        q.push_back(c);
      }
    }
    return q + "'";
  };
  const std::string cmd = "git -C " + quote(dir) + " show " + quote(commit + ":./" + name) +
                          " 2>/dev/null";
  FILE* pipe = ::popen(cmd.c_str(), "r");
  if (pipe == nullptr) return std::nullopt;
  std::string out;
  std::array<char, 65536> buf{};
  std::size_t n;
  while ((n = std::fread(buf.data(), 1, buf.size(), pipe)) > 0) out.append(buf.data(), n);
  const int status = ::pclose(pipe);
  if (status != 0) return std::nullopt;
  return out;
}

}  // namespace som
