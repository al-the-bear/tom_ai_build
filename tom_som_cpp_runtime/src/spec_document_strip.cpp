/* The strip of one value (SOM §11.10) — the C++ port of the value strip of
 * `spec_document_strip.dart` / `spec_document_strip.ts` (see
 * spec_document_strip.hpp). The plan works on the value's UTF-16 code units,
 * so offsets, the edit scripts and every "one character" step mean what they
 * mean in Dart and TypeScript. */
#include "spec_document_strip.hpp"
#include "spec_document_strip_internal.hpp"

#include <algorithm>
#include <cstddef>
#include <iterator>
#include <map>
#include <memory>
#include <set>
#include <optional>
#include <string>
#include <vector>

#include "som_json.hpp"
#include "spec_document_markdown.hpp"
#include "spec_review_annotations.hpp"
#include "spec_schema_validation.hpp"
#include "spec_validator.hpp"
#include "spec_text_pattern.hpp"

namespace som {

namespace strip_internal {

std::string toUtf8(const U16& s, std::size_t from, std::size_t to) {
  std::string out;
  for (std::size_t i = from; i < to; i++) {
    unsigned int cp = s[i];
    if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < to && s[i + 1] >= 0xDC00 &&
        s[i + 1] <= 0xDFFF) {
      cp = 0x10000 + ((cp - 0xD800) << 10) + (s[i + 1] - 0xDC00);
      i++;
    } else if (cp >= 0xD800 && cp <= 0xDFFF) {
      cp = 0xFFFD;
    }
    if (cp < 0x80) {
      out.push_back(static_cast<char>(cp));
    } else if (cp < 0x800) {
      out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else if (cp < 0x10000) {
      out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else {
      out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    }
  }
  return out;
}

std::string toUtf8(const U16& s) { return toUtf8(s, 0, s.size()); }

U16 asciiUnits(const std::string& s) { return somUtf16Units(s); }

/* JavaScript's `\s` / what `trim()` removes. */
bool jsSpace(char16_t c) {
  switch (c) {
    case 0x09: case 0x0A: case 0x0B: case 0x0C: case 0x0D: case 0x20:
    case 0xA0: case 0x1680: case 0x2028: case 0x2029: case 0x202F:
    case 0x205F: case 0x3000: case 0xFEFF:
      return true;
    default:
      return c >= 0x2000 && c <= 0x200A;
  }
}

/* `s.substring(from, to).trim() !== ''`. */
bool hasText(const U16& s, std::size_t from, std::size_t to) {
  for (std::size_t i = from; i < to && i < s.size(); i++) {
    if (!jsSpace(s[i])) return true;
  }
  return false;
}

bool space(char16_t c) { return c == u' ' || c == u'\t'; }

void countKind(std::vector<std::pair<std::string, long long>>& m,
               const std::string& k) {
  for (auto& e : m) {
    if (e.first == k) {
      e.second++;
      return;
    }
  }
  m.emplace_back(k, 1);
}

bool contains(const char* const* list, std::size_t n, const std::string& k) {
  for (std::size_t i = 0; i < n; i++) {
    if (k == list[i]) return true;
  }
  return false;
}

// ---- edit scripts ---------------------------------------------------------

/* Composes the scripts original -> middle (`s1`) and middle -> result
 * (`s2`). */
std::vector<Op> compose(const std::vector<Op>& s1, const std::vector<Op>& s2) {
  std::vector<Op> out;
  std::size_t j = 0;
  auto flushInserts = [&]() {
    while (j < s2.size() && s2[j].type == kIns) out.push_back(s2[j++]);
  };
  for (const Op& a : s1) {
    if (a.type == kDel) {
      out.push_back(a);
      continue;
    }
    flushInserts();
    const Op& b = s2[j++];
    if (a.type == kKeep) {
      out.push_back(b.type == kKeep ? a : Op{kDel, a.ch, b.label});
    } else if (b.type == kKeep) {
      out.push_back(a);
    }
  }
  flushInserts();
  return out;
}

std::vector<U16> lines(const U16& s) {
  std::vector<U16> out;
  std::size_t i = 0;
  while (i < s.size()) {
    std::size_t n = s.find(u'\n', i);
    std::size_t e = n == U16::npos ? s.size() : n + 1;
    out.push_back(s.substr(i, e - i));
    i = e;
  }
  return out;
}

int tokenKind(char16_t c) {
  if (c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d) return 2;
  if ((c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5a) ||
      (c >= 0x61 && c <= 0x7a) || c == 0x5f || c >= 0x80) {
    return 1;
  }
  return 0;
}

std::vector<U16> tokens(const U16& s) {
  std::vector<U16> out;
  std::size_t i = 0;
  while (i < s.size()) {
    int k = tokenKind(s[i]);
    std::size_t j = i + 1;
    if (k != 0) {
      while (j < s.size() && tokenKind(s[j]) == k) j++;
    }
    out.push_back(s.substr(i, j - i));
    i = j;
  }
  return out;
}

std::vector<std::pair<int, U16>> myers(const std::vector<U16>& a,
                                       const std::vector<U16>& b) {
  const long long n = (long long)a.size();
  const long long m = (long long)b.size();
  const long long max = n + m;
  std::vector<std::pair<int, U16>> rev;
  if (max == 0) return rev;
  const long long cap = 2000;
  const long long off = max + 1;
  std::vector<long long> v(2 * max + 3, 0);
  std::vector<std::vector<long long>> trace;
  long long found = -1;
  for (long long d = 0; d <= max && d <= cap; d++) {
    if (d > 0) {
      std::vector<long long> snap(2 * d - 1);
      for (long long k = -(d - 1); k <= d - 1; k++) snap[k + d - 1] = v[k + off];
      trace.push_back(std::move(snap));
    }
    for (long long k = -d; k <= d; k += 2) {
      long long x = (k == -d || (k != d && v[k - 1 + off] < v[k + 1 + off]))
                        ? v[k + 1 + off]
                        : v[k - 1 + off] + 1;
      long long y = x - k;
      while (x < n && y < m && a[x] == b[y]) {
        x++;
        y++;
      }
      v[k + off] = x;
      if (x >= n && y >= m) {
        found = d;
        break;
      }
    }
    if (found >= 0) break;
  }
  if (found < 0) {
    for (const auto& t : a) rev.emplace_back(kDel, t);
    for (const auto& t : b) rev.emplace_back(kIns, t);
    return rev;
  }
  long long x = n;
  long long y = m;
  for (long long d = found; d > 0; d--) {
    const std::vector<long long>& snap = trace[d - 1];
    auto at = [&snap, d](long long k) { return snap[k + d - 1]; };
    long long k = x - y;
    long long prevK =
        (k == -d || (k != d && at(k - 1) < at(k + 1))) ? k + 1 : k - 1;
    long long prevX = at(prevK);
    long long prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      rev.emplace_back(kKeep, a[x - 1]);
      x--;
      y--;
    }
    if (x == prevX) {
      rev.emplace_back(kIns, b[y - 1]);
    } else {
      rev.emplace_back(kDel, a[x - 1]);
    }
    x = prevX;
    y = prevY;
  }
  while (x > 0 && y > 0) {
    rev.emplace_back(kKeep, a[x - 1]);
    x--;
    y--;
  }
  std::reverse(rev.begin(), rev.end());
  return rev;
}

/* An edit script from `a` to `b`: Myers by line, then by word token. */
std::vector<Op> diff(const U16& a, const U16& b, const std::string& label) {
  std::vector<Op> out;
  auto chars = [&](int type, const U16& s) {
    for (char16_t ch : s) {
      out.push_back(Op{type, ch, type == kKeep ? std::string() : label});
    }
  };
  U16 deleted;
  U16 inserted;
  auto flush = [&]() {
    if (deleted.empty() && inserted.empty()) return;
    for (const auto& e : myers(tokens(deleted), tokens(inserted))) {
      chars(e.first, e.second);
    }
    deleted.clear();
    inserted.clear();
  };
  for (const auto& e : myers(lines(a), lines(b))) {
    if (e.first == kKeep) {
      flush();
      chars(kKeep, e.second);
    } else if (e.first == kDel) {
      deleted += e.second;
    } else {
      inserted += e.second;
    }
  }
  flush();
  return out;
}

// ---- inline review marks ---------------------------------------------------

std::vector<MarkAt> findMarks(const U16& t) {
  std::vector<bool> code(t.size(), false);
  SpecMarkdownFenceTracker fence;
  std::size_t s = 0;
  std::size_t from = 0;
  for (;;) {
    std::size_t nl = t.find(u'\n', from);
    U16 line = t.substr(from, nl == U16::npos ? U16::npos : nl - from);
    const bool inFence = fence.inFence();
    fence.feed(toUtf8(line));
    if (inFence || fence.inFence()) {
      for (std::size_t i = s; i < s + line.size(); i++) code[i] = true;
    } else {
      std::size_t i = 0;
      while (i < line.size()) {
        if (line[i] != u'`') {
          i++;
          continue;
        }
        std::size_t j = i;
        while (j < line.size() && line[j] == u'`') j++;
        const U16 ticks = line.substr(i, j - i);
        std::size_t close = line.find(ticks, j);
        if (close == U16::npos) {
          i = j;
          continue;
        }
        for (std::size_t k = s + i; k < s + close + ticks.size(); k++) {
          code[k] = true;
        }
        i = close + ticks.size();
      }
    }
    s += line.size() + 1;
    if (nl == U16::npos) break;
    from = nl + 1;
  }
  static const std::pair<U16, U16> kMarks[] = {
      {u"{++", u"++}"}, {u"{--", u"--}"}, {u"{~~", u"~~}"},
      {u"{==", u"==}"}, {u"{>>", u"<<}"},
  };
  std::vector<MarkAt> out;
  std::size_t i = 0;
  while (i + 3 <= t.size()) {
    const U16 opener = t.substr(i, 3);
    const U16* closer = nullptr;
    for (const auto& mk : kMarks) {
      if (mk.first == opener) closer = &mk.second;
    }
    if (closer == nullptr || code[i]) {
      i++;
      continue;
    }
    // `/\n[ \t]*\n/` from i: the paragraph's end.
    std::size_t limit = t.size();
    for (std::size_t p = t.find(u'\n', i); p != U16::npos;
         p = t.find(u'\n', p + 1)) {
      std::size_t q = p + 1;
      while (q < t.size() && space(t[q])) q++;
      if (q < t.size() && t[q] == u'\n') {
        limit = p;
        break;
      }
    }
    std::size_t close = t.find(*closer, i + 3);
    if (close == U16::npos || close + 3 > limit) {
      i++;
      continue;
    }
    long long sep = -1;
    if (opener == u"{~~") {
      std::size_t sp = t.find(u"~>", i + 3);
      if (sp == U16::npos || sp >= close) {
        i++;
        continue;
      }
      sep = (long long)sp;
    }
    out.push_back(MarkAt{i, close + 3, i + 3, close, sep});
    i = close + 3;
  }
  return out;
}

// ---- one value's strip -------------------------------------------------------

struct Insert {
  std::string label;
  std::optional<U16> text;
  long long entry = -1;
};

struct Entry {
  std::string kind;
  std::string text;
};

/* The strip of one value, planned once and finished for any numbering. */
class Plan {
 public:
  Plan(const std::string& value, const SpecStripOptions& options)
      : options_(options), o8_(value), o_(somUtf16Units(value)) {
    for (const auto& f : scanNotation(value, true).findings) {
      if (f.severity() == "error" &&
          f.code != NotationFindingCode::kRejectedBlock) {
        findings_.push_back(f);
      }
    }
    if (!findings_.empty()) {
      t_ = o_;
      del_.assign(t_.size(), std::string());
      blockDel_.assign(t_.size(), false);
      return;
    }
    std::string t8 = value;
    if (options.drop.count("comments") != 0) {
      t8 = stripAnnotationsText(value);
      if (t8 != value) {
        countKindTo(dropped_, "comments",
                    (long long)countAnnotationsText(value));
        t_ = somUtf16Units(t8);
        script1_ = diff(o_, t_, "comments");
        hasScript1_ = true;
      } else {
        t_ = o_;
      }
    } else {
      t_ = o_;
    }
    del_.assign(t_.size(), std::string());
    blockDel_.assign(t_.size(), false);
    process(scanNotation(t8, true).elements);
    if (options.drop.count("comments") == 0) marks();
    bool any = false;
    for (const auto& d : del_) {
      if (!d.empty()) any = true;
    }
    if (any) normalise();
  }

  /* Finishes the plan, numbering appendix entry `k` as `(*numbers)[k]`
   * (nullptr: `k + 1`). */
  SpecStripTextResult finish(const std::vector<long long>* numbers = nullptr) const;

  /* Whether the plan changes its value (`_Plan.changes`). */
  bool changes() const {
    if (!findings_.empty()) return false;
    if (hasScript1_ || !ins_.empty()) return true;
    for (const auto& d : del_) {
      if (!d.empty()) return true;
    }
    return false;
  }
  /* The appendix entries the plan moves. */
  std::size_t entryCount() const { return entries_.size(); }
  /* The error findings the value is refused for. */
  const std::vector<NotationFinding>& findings() const { return findings_; }

 private:
  SpecStripOptions options_;
  std::string o8_;
  U16 o_;
  U16 t_;
  std::vector<Op> script1_;
  bool hasScript1_ = false;
  std::vector<std::string> del_;  // "" = kept
  std::vector<bool> blockDel_;
  std::map<std::size_t, std::vector<Insert>> ins_;
  std::vector<std::pair<std::string, long long>> dropped_;
  std::vector<std::pair<std::string, long long>> unmarked_;
  std::vector<std::pair<std::string, long long>> appended_;
  long long marksDropped_ = 0;
  std::vector<Entry> entries_;
  std::vector<NotationFinding> findings_;

  static void countKindTo(std::vector<std::pair<std::string, long long>>& m,
                          const std::string& k, long long n) {
    m.emplace_back(k, n);
  }

  void mark(std::size_t s, std::size_t e, const std::string& label,
            bool block = false) {
    for (std::size_t i = s; i < e && i < t_.size(); i++) {
      if (del_[i].empty()) del_[i] = label;
      if (block) blockDel_[i] = true;
    }
  }

  void insert(std::size_t at, Insert i) { ins_[at].push_back(std::move(i)); }

  void process(const std::vector<NotationElement>& list) {
    for (const NotationElement& e : list) {
      const std::string k = e.kind.value_or("");
      // A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12) is
      // removed by `-drop:` and `-unmark:` alike: its text without its
      // markers would read back as content.
      if (e.isRegistered() && (k == "linked" || k == "derived") &&
          (options_.drop.count(k) != 0 || options_.unmark.count(k) != 0)) {
        remove(e, k + ":drop", -1);
        countKind(dropped_, k);
        continue;
      }
      const bool secondary =
          e.isRegistered() && e.kind.has_value() &&
          contains(specStripNotationKinds, std::size(specStripNotationKinds), k);
      if (!secondary) {
        process(e.children);
        continue;
      }
      if (options_.drop.count(k) != 0) {
        remove(e, k + ":drop", -1);
        countKind(dropped_, k);
        continue;
      }
      if (options_.appendix.count(k) != 0) {
        U16 content;
        if (e.type == "citation") {
          content = t_.substr(e.start, e.end - e.start);
        } else {
          content = t_.substr(e.contentStart, e.contentEnd - e.contentStart);
          while (!content.empty() && content.back() == u'\n') content.pop_back();
        }
        entries_.push_back(
            Entry{k, stripNotationText(toUtf8(content), options_.inEntry()).text});
        remove(e, k + ":appendix", (long long)entries_.size() - 1);
        countKind(appended_, k);
        continue;
      }
      if (options_.unmark.count(k) != 0) {
        unmark(e, k + ":unmark");
        countKind(unmarked_, k);
      }
      process(e.children);
    }
  }

  void remove(const NotationElement& e, const std::string& label,
              long long entry) {
    const bool reference = entry >= 0 && options_.appendixReferences;
    const std::size_t s = (std::size_t)e.start;
    const std::size_t en = (std::size_t)e.end;
    if (e.type == "div") {
      mark(s, en, label, true);
      if (reference) insert(s, Insert{label, std::nullopt, entry});
      return;
    }
    if (s > 0 && space(t_[s - 1]) && del_[s - 1].empty()) {
      del_[s - 1] = label;
    } else if (!reference && (s == 0 || t_[s - 1] == u'\n') && en < t_.size() &&
               space(t_[en])) {
      del_[en] = label;
    }
    mark(s, en, label);
    if (reference) insert(s, Insert{label, std::nullopt, entry});
  }

  void unmark(const NotationElement& e, const std::string& label) {
    const std::size_t s = (std::size_t)e.start;
    const std::size_t en = (std::size_t)e.end;
    const std::size_t cs = (std::size_t)e.contentStart;
    const std::size_t ce = (std::size_t)e.contentEnd;
    if (e.type == "div") {
      if (cs >= ce) {
        mark(s, en, label, true);
      } else {
        mark(s, cs, label, true);
        mark(ce - 1, en, label, true);
      }
    } else if (e.type == "span") {
      mark(s, s + 1, label);
      mark(ce, en, label);
    } else {
      mark(s + 1, cs, label);
    }
  }

  void marks() {
    for (const MarkAt& m : findMarks(t_)) {
      if (allDeleted(m.start, m.end)) {
        marksDropped_++;
        continue;
      }
      if (m.sep < 0) {
        if (hasText(t_, m.bodyStart, m.bodyEnd) &&
            !survives(m.bodyStart, m.bodyEnd)) {
          removeMark(m);
        }
        continue;
      }
      const std::size_t sep = (std::size_t)m.sep;
      const bool oldHad = hasText(t_, m.bodyStart, sep);
      const bool newHad = hasText(t_, sep + 2, m.bodyEnd);
      const bool oldLeft = survives(m.bodyStart, sep);
      const bool newLeft = survives(sep + 2, m.bodyEnd);
      if (!oldLeft && !newLeft && (oldHad || newHad)) {
        removeMark(m);
      } else if (oldHad && !oldLeft) {
        convert(m, u"++", m.bodyStart, sep + 2);
      } else if (newHad && !newLeft) {
        convert(m, u"--", sep, m.bodyEnd);
      }
    }
  }

  void removeMark(const MarkAt& m) {
    const std::size_t s = m.start;
    if (s > 0 && space(t_[s - 1]) && del_[s - 1].empty()) {
      del_[s - 1] = "mark";
    } else if ((s == 0 || t_[s - 1] == u'\n') && m.end < t_.size() &&
               space(t_[m.end])) {
      del_[m.end] = "mark";
    }
    mark(m.start, m.end, "mark");
  }

  void convert(const MarkAt& m, const U16& delimiter, std::size_t s,
               std::size_t e) {
    mark(m.start + 1, m.start + 3, "mark");
    insert(m.start + 3, Insert{"mark", delimiter, -1});
    mark(s, e, "mark");
    mark(m.end - 3, m.end - 1, "mark");
    insert(m.end - 1, Insert{"mark", delimiter, -1});
  }

  bool allDeleted(std::size_t s, std::size_t e) const {
    for (std::size_t i = s; i < e; i++) {
      if (del_[i].empty()) return false;
    }
    return true;
  }

  bool survives(std::size_t s, std::size_t e) const {
    for (std::size_t i = s; i < e; i++) {
      if (del_[i].empty() && !jsSpace(t_[i])) return true;
    }
    return false;
  }

  void normalise() {
    const U16& t = t_;
    std::vector<std::size_t> starts{0};
    for (std::size_t i = 0; i < t.size(); i++) {
      if (t[i] == u'\n') starts.push_back(i + 1);
    }
    for (std::size_t l = 0; l < starts.size(); l++) {
      const std::size_t s = starts[l];
      const std::size_t e = l + 1 < starts.size() ? starts[l + 1] - 1 : t.size();
      if (!hasText(t, s, e)) continue;
      bool touched = false;
      bool surv = false;
      bool allBlock = true;
      for (std::size_t i = s; i < e; i++) {
        if (!del_[i].empty()) {
          touched = true;
        } else if (!jsSpace(t[i])) {
          surv = true;
        }
        if (!blockDel_[i]) allBlock = false;
      }
      for (std::size_t i = s; i <= e; i++) {
        if (ins_.count(i) != 0) surv = true;
      }
      if (!touched || surv || allBlock) continue;
      mark(s, e, "whitespace");
      if (e < t.size()) {
        if (del_[e].empty()) del_[e] = "whitespace";
      } else if (s > 0) {
        if (del_[s - 1].empty()) del_[s - 1] = "whitespace";
      }
    }
    // Blank-line runs, read on the text as it now stands.
    std::vector<long long> kept;
    U16 b;
    for (std::size_t i = 0; i <= t.size(); i++) {
      auto it = ins_.find(i);
      if (it != ins_.end()) {
        for (const Insert& x : it->second) {
          const U16 s = x.text.has_value() ? *x.text : U16(u"x");
          for (std::size_t k = 0; k < s.size(); k++) kept.push_back(-1);
          b += s;
        }
      }
      if (i < t.size() && del_[i].empty()) {
        kept.push_back((long long)i);
        b.push_back(t[i]);
      }
    }
    auto solid = [](char16_t c) { return !jsSpace(c); };
    std::size_t firstSolid = 0;
    while (firstSolid < b.size() && !solid(b[firstSolid])) firstSolid++;
    auto wipe = [&](long long idx) {
      if (idx >= 0 && del_[(std::size_t)idx].empty()) {
        del_[(std::size_t)idx] = "whitespace";
      }
    };
    if (firstSolid == b.size()) {
      for (long long i : kept) wipe(i);
      return;
    }
    std::size_t lastSolid = b.size() - 1;
    while (!solid(b[lastSolid])) lastSolid--;
    // `b.lastIndexOf('\n', firstSolid)`
    long long lead = -1;
    for (long long k = (long long)firstSolid; k >= 0; k--) {
      if (b[(std::size_t)k] == u'\n') {
        lead = k;
        break;
      }
    }
    for (long long k = 0; k <= lead; k++) wipe(kept[(std::size_t)k]);
    std::size_t trail = b.find(u'\n', lastSolid);
    if (trail != U16::npos) {
      for (std::size_t k = trail; k < b.size(); k++) wipe(kept[k]);
    }
    std::size_t k = firstSolid;
    while (k < lastSolid) {
      if (solid(b[k])) {
        k++;
        continue;
      }
      const std::size_t runStart = k;
      while (!solid(b[k])) k++;
      const std::size_t runEnd = k;
      std::vector<std::size_t> breaks;
      for (std::size_t j = runStart; j < runEnd; j++) {
        if (b[j] == u'\n') breaks.push_back(j);
      }
      if (breaks.size() <= 2) continue;
      const long long from = kept[runStart - 1];
      const long long to = kept[runEnd];
      bool atRemoval = false;
      if (from >= 0 && to >= 0) {
        for (long long i = from + 1; i < to; i++) {
          const std::string& d = del_[(std::size_t)i];
          if (!d.empty() && d != "whitespace") atRemoval = true;
        }
      } else {
        atRemoval = true;
      }
      if (!atRemoval) continue;
      for (std::size_t j = breaks.front() + 1; j + 1 <= breaks.back(); j++) {
        wipe(kept[j]);
      }
    }
  }
};

SpecStripTextResult Plan::finish(const std::vector<long long>* numbers) const {
  SpecStripTextResult r;
  if (!findings_.empty()) {
    r.text = o8_;
    r.findings = findings_;
    return r;
  }
  const U16& t = t_;
  auto number = [numbers](long long entry) {
    return numbers != nullptr ? (*numbers)[(std::size_t)entry] : entry + 1;
  };
  auto insertText = [&](const Insert& x) -> U16 {
    if (x.text.has_value()) return *x.text;
    const std::string n = std::to_string(number(x.entry));
    return asciiUnits("<a id=\"note-" + n + "-ref\"></a>[\\[" + n + "\\]](#note-" +
                      n + ")");
  };
  std::vector<Op> script2;
  for (std::size_t i = 0; i <= t.size(); i++) {
    auto it = ins_.find(i);
    if (it != ins_.end()) {
      for (const Insert& x : it->second) {
        for (char16_t ch : insertText(x)) script2.push_back(Op{kIns, ch, x.label});
      }
    }
    if (i < t.size()) {
      script2.push_back(del_[i].empty() ? Op{kKeep, t[i], std::string()}
                                        : Op{kDel, t[i], del_[i]});
    }
  }
  const std::vector<Op> ops = hasScript1_ ? compose(script1_, script2) : script2;
  U16 out;
  long long oPos = 0;
  long long bPos = 0;
  std::size_t i = 0;
  while (i < ops.size()) {
    if (ops[i].type == kKeep) {
      out.push_back(ops[i].ch);
      oPos++;
      bPos++;
      i++;
      continue;
    }
    SpecStripPiece piece;
    piece.anchor = bPos;
    piece.origin = oPos;
    U16 removed;
    U16 inserted;
    std::set<std::string> labels;
    while (i < ops.size() && ops[i].type != kKeep) {
      const Op& op = ops[i];
      if (!op.label.empty()) labels.insert(op.label);
      if (op.type == kDel) {
        removed.push_back(op.ch);
        oPos++;
      } else {
        inserted.push_back(op.ch);
        out.push_back(op.ch);
        bPos++;
      }
      i++;
    }
    piece.removed = toUtf8(removed);
    piece.inserted = toUtf8(inserted);
    piece.labels.assign(labels.begin(), labels.end());
    r.pieces.push_back(std::move(piece));
  }
  r.text = toUtf8(out);
  r.dropped = dropped_;
  r.unmarked = unmarked_;
  r.appended = appended_;
  r.marksDropped = marksDropped_;
  for (std::size_t k = 0; k < entries_.size(); k++) {
    r.appendix.push_back(
        SpecAppendixEntry{number((long long)k), entries_[k].kind, entries_[k].text,
                          std::nullopt});
  }
  return r;
}

std::string kindsJson(const std::vector<std::string>& kinds) {
  std::string out = "[";
  for (std::size_t i = 0; i < kinds.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(kinds[i]);
  }
  return out + "]";
}

std::string countsJson(const std::vector<std::pair<std::string, long long>>& m) {
  std::string out = "{";
  for (std::size_t i = 0; i < m.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(m[i].first) + ":" + std::to_string(m[i].second);
  }
  return out + "}";
}

}  // namespace strip_internal

using namespace strip_internal;

// ---- options -----------------------------------------------------------------

SpecStripOptions SpecStripOptions::fromNames(
    const std::vector<std::string>& drop, const std::vector<std::string>& unmark,
    const std::vector<std::string>& appendix, bool appendixReferences,
    bool headingDivs) {
  auto names = [](const std::vector<std::string>& list) {
    std::vector<std::string> out;
    for (const auto& item : list) {
      std::size_t from = 0;
      for (;;) {
        std::size_t comma = item.find(',', from);
        std::string n = item.substr(
            from, comma == std::string::npos ? std::string::npos : comma - from);
        // `n.trim()`
        std::size_t a = 0, b = n.size();
        while (a < b && (n[a] == ' ' || n[a] == '\t' || n[a] == '\n' ||
                         n[a] == '\r' || n[a] == '\f' || n[a] == '\v')) {
          a++;
        }
        while (b > a && (n[b - 1] == ' ' || n[b - 1] == '\t' || n[b - 1] == '\n' ||
                         n[b - 1] == '\r' || n[b - 1] == '\f' || n[b - 1] == '\v')) {
          b--;
        }
        if (b > a) out.push_back(n.substr(a, b - a));
        if (comma == std::string::npos) break;
        from = comma + 1;
      }
    }
    return out;
  };
  const std::pair<const char*, std::vector<std::string>> lists[] = {
      {"drop", names(drop)}, {"unmark", names(unmark)}, {"appendix", names(appendix)}};
  std::vector<std::string> known(std::begin(specStripKindNames),
                                 std::end(specStripKindNames));
  known.push_back("all");
  auto has = [](const std::vector<std::string>& v, const std::string& n) {
    return std::find(v.begin(), v.end(), n) != v.end();
  };
  for (const auto& l : lists) {
    for (const auto& n : l.second) {
      if (!has(known, n)) {
        std::string list;
        for (std::size_t i = 0; i < known.size(); i++) {
          if (i > 0) list += ", ";
          list += known[i];
        }
        throw SpecStripUsageError("unknown kind name \"" + n + "\" in " +
                                  l.first + "; known names: " + list);
      }
    }
  }
  for (std::size_t i = 0; i < 3; i++) {
    for (std::size_t j = i + 1; j < 3; j++) {
      for (const auto& n : lists[i].second) {
        if (has(lists[j].second, n)) {
          throw SpecStripUsageError("kind name \"" + n + "\" is in both " +
                                    lists[i].first + " and " + lists[j].first);
        }
      }
    }
  }
  if (has(lists[1].second, "comments")) {
    throw SpecStripUsageError(
        "comments cannot be unmarked: a review annotation has no reading "
        "without its markers; drop it or leave it");
  }
  if (has(lists[2].second, "comments")) {
    throw SpecStripUsageError(
        "comments cannot be moved to the appendix; drop them or leave them");
  }
  for (const char* k : {"linked", "derived"}) {
    if (has(lists[2].second, k)) {
      throw SpecStripUsageError(std::string(k) +
                                " cannot be moved to the appendix: the renderer "
                                "writes it from the document; drop it or leave it");
    }
  }
  std::set<std::string> explicitNames;
  for (const auto& l : lists) {
    for (const auto& n : l.second) {
      if (n != "all") explicitNames.insert(n);
    }
  }
  auto expand = [&](std::size_t list, const std::vector<std::string>& all) {
    std::set<std::string> out;
    for (const auto& n : lists[list].second) {
      if (n == "all") {
        for (const auto& k : all) {
          if (explicitNames.count(k) == 0) out.insert(k);
        }
      } else {
        out.insert(n);
      }
    }
    return out;
  };
  const std::vector<std::string> notation(std::begin(specStripNotationKinds),
                                          std::end(specStripNotationKinds));
  SpecStripOptions o;
  o.appendix = expand(2, notation);
  if (appendixReferences && o.appendix.empty()) {
    throw SpecStripUsageError("appendix references need an appendix: name its kinds");
  }
  o.drop = expand(0, std::vector<std::string>(std::begin(specStripKindNames),
                                              std::end(specStripKindNames)));
  std::vector<std::string> unmarkable = notation;
  unmarkable.push_back("linked");
  unmarkable.push_back("derived");
  o.unmark = expand(1, unmarkable);
  o.appendixReferences = appendixReferences;
  o.headingDivs = headingDivs;
  return o;
}

SpecStripOptions SpecStripOptions::keeping() const {
  SpecStripOptions o;
  if (drop.count("comments") != 0) o.drop.insert("comments");
  o.unmark = unmark;
  o.unmark.insert(appendix.begin(), appendix.end());
  for (const auto& k : drop) {
    if (k != "comments") o.unmark.insert(k);
  }
  o.headingDivs = headingDivs;
  return o;
}

SpecStripOptions SpecStripOptions::inEntry() const {
  SpecStripOptions o;
  o.drop = drop;
  o.drop.erase("comments");
  o.unmark = unmark;
  o.unmark.insert(appendix.begin(), appendix.end());
  return o;
}

std::vector<std::string> SpecStripOptions::ordered(
    const std::set<std::string>& names) {
  std::vector<std::string> out;
  for (const char* k : specStripKindNames) {
    if (names.count(k) != 0) out.push_back(k);
  }
  return out;
}

std::string SpecStripOptions::toJson() const {
  return "{\"drop\":" + kindsJson(ordered(drop)) +
         ",\"unmark\":" + kindsJson(ordered(unmark)) +
         ",\"appendix\":" + kindsJson(ordered(appendix)) +
         ",\"appendixReferences\":" + (appendixReferences ? "true" : "false") +
         ",\"headingDivs\":" + (headingDivs ? "true" : "false") + "}";
}

// ---- results -------------------------------------------------------------------

std::string SpecStripPiece::toJson() const {
  return "{\"anchor\":" + std::to_string(anchor) +
         ",\"origin\":" + std::to_string(origin) +
         ",\"removed\":" + jsonEncodeStr(removed) +
         ",\"inserted\":" + jsonEncodeStr(inserted) +
         ",\"labels\":" + kindsJson(labels) + "}";
}

std::string SpecAppendixEntry::toJson() const {
  return "{\"number\":" + std::to_string(number) +
         ",\"kind\":" + jsonEncodeStr(kind) + ",\"text\":" + jsonEncodeStr(text) +
         (value.has_value() ? ",\"value\":" + value->toJson() : std::string()) +
         "}";
}

std::string SpecStripTextResult::toJson() const {
  std::string out = "{\"text\":" + jsonEncodeStr(text) +
                    ",\"dropped\":" + countsJson(dropped) +
                    ",\"unmarked\":" + countsJson(unmarked) +
                    ",\"appended\":" + countsJson(appended) +
                    ",\"marksDropped\":" + std::to_string(marksDropped) +
                    ",\"appendix\":[";
  for (std::size_t i = 0; i < appendix.size(); i++) {
    if (i > 0) out += ",";
    out += appendix[i].toJson();
  }
  out += "],\"pieces\":[";
  for (std::size_t i = 0; i < pieces.size(); i++) {
    if (i > 0) out += ",";
    out += pieces[i].toJson();
  }
  out += "],\"refused\":[";
  for (std::size_t i = 0; i < findings.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(findings[i].code);
  }
  return out + "]}";
}

SpecStripTextResult stripNotationText(const std::string& value,
                                      const SpecStripOptions& options) {
  return Plan(value, options).finish();
}

}  // namespace som

// ============================================================================
// The readable header (SOM §11.1) and value references
// ============================================================================

namespace som {

namespace strip_internal {

bool jsWs(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

std::string trimJs(const std::string& s) {
  std::size_t a = 0, b = s.size();
  while (a < b && jsWs(s[a])) a++;
  while (b > a && jsWs(s[b - 1])) b--;
  return s.substr(a, b - a);
}

std::string joinedKinds(const std::set<std::string>& set) {
  std::string out;
  for (const std::string& k : SpecStripOptions::ordered(set)) {
    if (!out.empty()) out += ",";
    out += k;
  }
  return out;
}

}  // namespace strip_internal

std::string SpecReadableHeader::format(const SpecStripOptions& o,
                                       const SpecReadableSource* source) {
  std::vector<std::string> parts;
  if (!o.drop.empty()) parts.push_back("drop=" + joinedKinds(o.drop));
  if (!o.unmark.empty()) parts.push_back("unmark=" + joinedKinds(o.unmark));
  if (!o.appendix.empty()) parts.push_back("appendix=" + joinedKinds(o.appendix));
  if (o.appendixReferences) parts.push_back("appendix-references");
  if (o.headingDivs) parts.push_back("headings=divs");
  if (source != nullptr) {
    std::string of = "of=" + source->file;
    if (source->revision.has_value()) of += "@" + *source->revision;
    parts.push_back(of);
    if (source->commit.has_value()) {
      parts.push_back("commit=" + *source->commit +
                      (source->dirty ? "+dirty" : ""));
    }
  }
  if (parts.empty()) return "<!-- readable: -->";
  std::string out = "<!-- readable: ";
  for (std::size_t i = 0; i < parts.size(); i++) {
    if (i > 0) out += "; ";
    out += parts[i];
  }
  return out + " -->";
}

std::optional<SpecReadableHeader> SpecReadableHeader::parse(
    const std::string& line) {
  const std::string t = trimJs(line);
  // `^<!--\s*readable:(.*)-->$`
  if (t.compare(0, 4, "<!--") != 0) return std::nullopt;
  std::size_t p = 4;
  while (p < t.size() && jsWs(t[p])) p++;
  const std::size_t n = t.size();
  if (t.compare(p, 9, "readable:") != 0 || n < 3 ||
      t.compare(n - 3, 3, "-->") != 0 || p + 9 > n - 3) {
    return std::nullopt;
  }
  const std::string body = t.substr(p + 9, n - 3 - (p + 9));
  std::vector<std::string> lists[3];
  bool refs = false, divs = false, dirty = false;
  std::optional<std::string> file, revision, commit;
  std::size_t start = 0;
  while (start <= body.size()) {
    std::size_t end = body.find(';', start);
    if (end == std::string::npos) end = body.size();
    const std::string part = trimJs(body.substr(start, end - start));
    start = end + 1;
    if (part.empty()) continue;
    const std::size_t eq = part.find('=');
    const std::string key = eq == std::string::npos ? part : part.substr(0, eq);
    const std::string value =
        eq == std::string::npos ? std::string() : part.substr(eq + 1);
    if (key == "drop") {
      lists[0].push_back(value);
    } else if (key == "unmark") {
      lists[1].push_back(value);
    } else if (key == "appendix") {
      lists[2].push_back(value);
    } else if (key == "appendix-references" && eq == std::string::npos) {
      refs = true;
    } else if (key == "headings" && value == "divs") {
      divs = true;
    } else if (key == "of") {
      const std::size_t at = value.rfind('@');
      if (at == std::string::npos) {
        file = value;
        revision.reset();
      } else {
        file = value.substr(0, at);
        revision = value.substr(at + 1);
      }
    } else if (key == "commit") {
      dirty = value.size() >= 6 &&
              value.compare(value.size() - 6, 6, "+dirty") == 0;
      commit = dirty ? value.substr(0, value.size() - 6) : value;
    } else {
      return std::nullopt;
    }
  }
  if (!file.has_value() && commit.has_value()) return std::nullopt;
  SpecReadableHeader h;
  try {
    h.options =
        SpecStripOptions::fromNames(lists[0], lists[1], lists[2], refs, divs);
  } catch (const SpecStripUsageError&) {
    return std::nullopt;
  }
  if (file.has_value()) {
    h.source = SpecReadableSource{*file, revision, commit, dirty};
  }
  return h;
}

std::string SpecStripValueRef::read(const SpecDocument& doc) const {
  if (headline) return doc.headline(path);
  if (field.has_value()) return doc.formField(path, *field);
  return doc.content(path);
}

void SpecStripValueRef::write(SpecDocument& doc,
                              const std::string& value) const {
  if (headline) {
    doc.setHeadline(path, value);
  } else if (field.has_value()) {
    doc.setFormField(path, *field, value);
  } else {
    doc.setContent(path, value);
  }
}

std::string SpecStripValueRef::label() const {
  if (headline) return path + " (headline)";
  if (field.has_value()) return path + "/" + *field;
  return path;
}

std::string SpecStripValueRef::toJson() const {
  std::string out = "{\"path\":" + jsonEncodeStr(path);
  if (field.has_value()) out += ",\"field\":" + jsonEncodeStr(*field);
  if (headline) out += ",\"headline\":true";
  return out + "}";
}

std::string SpecStripFinding::toString() const {
  return kind + ": " + (ref.has_value() ? ref->label() + ": " : "") + message;
}

// ============================================================================
// The strip of a document (SOM §11.10)
// ============================================================================

namespace strip_internal {

using Counts = std::vector<std::pair<std::string, long long>>;

SpecDocument docCopy(const SpecDocument& d) {
  SpecDocument c;
  c.loadJson(d.toJson());
  return c;
}

bool blank(const std::string& s) {
  for (char c : s) {
    if (!jsWs(c)) return false;
  }
  return true;
}

bool startsWithSep(const std::string& s, const std::string& prefix, char sep) {
  return s.size() > prefix.size() &&
         s.compare(0, prefix.size(), prefix) == 0 && s[prefix.size()] == sep;
}

/* Whether a finding at `findingPath` concerns `path`. */
bool concerns(const std::string& findingPath, const std::string& path) {
  return findingPath.empty() || path == findingPath ||
         startsWithSep(path, findingPath, '/') ||
         startsWithSep(path, findingPath, '-') ||
         startsWithSep(findingPath, path, '/');
}

bool listHas(const std::vector<std::string>& v, const std::string& s) {
  return std::find(v.begin(), v.end(), s) != v.end();
}

void addCounts(Counts& into, const Counts& from) {
  for (const auto& kv : from) {
    auto it = std::find_if(into.begin(), into.end(), [&kv](const auto& e) {
      return e.first == kv.first;
    });
    if (it == into.end()) {
      into.push_back(kv);
    } else {
      it->second += kv.second;
    }
  }
}

/* The instance tier's and (given a schema) the schema tier's findings of
 * `doc`, keyed as `instance <code> <path>: <message>` / `schema <rule>
 * <section id>: <message>`, each with the path it concerns. */
KeyPaths tierFindings(const SpecModel& model, const DocSpecsSchema* schema,
                      const std::string& rootType, const SpecDocument& doc) {
  KeyPaths out;
  for (const SpecValidationError& e : validateDocument(model, doc)) {
    out.set("instance " + e.code + " " + e.path + ": " + e.message, e.path);
  }
  if (schema == nullptr) return out;
  std::vector<DocSpecsViolation> vl;
  try {
    vl = validateSpecDocument(model, doc, *schema, rootType);
  } catch (const std::exception&) {
    return out;  // No single root to render: the schema tier cannot judge it.
  }
  for (const DocSpecsViolation& v : vl) {
    out.set("schema " + v.rule + " " + v.sectionId + ": " + v.message, v.path);
  }
  return out;
}

/* The state of one strip of a document. */
struct Strip {
  const SpecDocument* document = nullptr;
  SpecDocument copy;
  const SpecStripOptions* options = nullptr;
  std::vector<SpecStripValueRef> refs;
  std::vector<std::string> originals;           // per ref
  std::vector<std::unique_ptr<Plan>> plans;     // per ref, set where planned
  std::vector<std::vector<long long>> numbers;  // per planned ref

  void setNumbers(std::size_t i) {
    numbers[i].assign(plans[i]->entryCount(), 0);
  }
  void apply() {
    for (std::size_t i = 0; i < refs.size(); i++) {
      if (plans[i] == nullptr) continue;
      refs[i].write(copy, plans[i]->finish(&numbers[i]).text);
    }
  }

  /* The list items that are, or hold, a planned value. Sorted. */
  std::vector<std::string> itemsAbove() const {
    std::vector<std::string> items;
    for (const std::string& list : copy.listPaths()) {
      for (const std::string& it : copy.listItems(list)) {
        if (!listHas(items, it)) items.push_back(it);
      }
    }
    std::vector<std::string> out;
    for (std::size_t r = 0; r < refs.size(); r++) {
      if (plans[r] == nullptr) continue;
      const std::string& p = refs[r].path;
      if (listHas(items, p) && !listHas(out, p)) out.push_back(p);
      for (std::size_t i = 0; i < p.size(); i++) {
        if (p[i] != '/') continue;
        const std::string pre = p.substr(0, i);
        if (listHas(items, pre) && !listHas(out, pre)) out.push_back(pre);
      }
    }
    std::sort(out.begin(), out.end());
    return out;
  }

  std::vector<std::string> emptiedItems(
      const std::vector<std::string>& candidates,
      const std::vector<std::string>& keep) const {
    std::vector<std::string> out;
    for (const std::string& item : candidates) {
      if (!listHas(keep, item) && document->hasValuesUnder(item) &&
          !copy.hasValuesUnder(item)) {
        out.push_back(item);
      }
    }
    return out;
  }

  /* The emptying rule: a value whose strip adds an instance or schema finding
   * is stripped with the keeping options instead (or keeps its original when
   * even that empties it), and a list item it would empty stays; then the
   * list items left with nothing are removed and written into `removed`. */
  void emptyingRule(const SpecModel& model, const DocSpecsSchema* schema,
                    const std::string& rootType, const KeyPaths& base,
                    std::vector<SpecStripKept>& kept,
                    std::vector<std::string>& removed) {
    std::vector<bool> keptRefs(refs.size(), false);
    std::vector<std::string> keepItems;
    const std::vector<std::string> candidates = itemsAbove();
    const SpecStripOptions keeping = options->keeping();
    for (int round = 0; round < 8; round++) {
      const std::vector<std::string> items = emptiedItems(candidates, keepItems);
      KeyPaths now;
      if (items.empty()) {
        now = tierFindings(model, schema, rootType, copy);
      } else {
        SpecDocument scratch = docCopy(copy);
        for (const std::string& it : items) scratch.removeListItem(it);
        now = tierFindings(model, schema, rootType, scratch);
      }
      KeyPaths added;
      for (std::size_t i = 0; i < now.keys.size(); i++) {
        if (base.find(now.keys[i]) < 0) {
          added.keys.push_back(now.keys[i]);
          added.paths.push_back(now.paths[i]);
        }
      }
      if (added.keys.empty()) break;
      std::vector<std::size_t> emptied;
      for (std::size_t i = 0; i < refs.size(); i++) {
        if (plans[i] != nullptr && !keptRefs[i] && blank(refs[i].read(copy))) {
          emptied.push_back(i);
        }
      }
      bool changed = false;
      for (std::size_t a = 0; a < added.keys.size(); a++) {
        const std::string& key = added.keys[a];
        const std::string& findingPath = added.paths[a];
        for (const std::string& it : items) {
          if (concerns(findingPath, it) && !listHas(keepItems, it)) {
            keepItems.push_back(it);
            changed = true;
          }
        }
        for (std::size_t index : emptied) {
          const SpecStripValueRef& ref = refs[index];
          if (keptRefs[index] || !concerns(findingPath, ref.path)) continue;
          keptRefs[index] = true;
          kept.push_back(SpecStripKept{ref, key});
          auto k = std::make_unique<Plan>(originals[index], keeping);
          const std::string text = k->finish().text;
          if (blank(text)) {
            plans[index].reset();
            ref.write(copy, originals[index]);
          } else {
            plans[index] = std::move(k);
            setNumbers(index);
            ref.write(copy, text);
          }
          changed = true;
        }
      }
      if (!changed) break;
    }
    for (const std::string& it : emptiedItems(candidates, keepItems)) {
      copy.removeListItem(it);
      removed.push_back(it);
    }
  }
};

/* The headings of a rendition: the title of each heading path and its line,
 * in rendition order (a path written twice keeps its first place). */
struct Headings {
  std::vector<std::string> paths;
  std::vector<std::string> titles;
  std::vector<int> lines;

  static Headings from(const SpecMarkdownRendition& r) {
    Headings h;
    std::vector<std::string> text;
    std::size_t pos = 0;
    for (;;) {
      const std::size_t nl = r.markdown.find('\n', pos);
      text.push_back(r.markdown.substr(
          pos, nl == std::string::npos ? std::string::npos : nl - pos));
      if (nl == std::string::npos) break;
      pos = nl + 1;
    }
    for (const auto& kv : r.headingPaths) {
      const int line = kv.first;
      const std::string title = markdownHeadingTitle(
          line >= 1 && (std::size_t)line <= text.size() ? text[line - 1] : "");
      auto it = std::find(h.paths.begin(), h.paths.end(), kv.second);
      if (it != h.paths.end()) {
        const std::size_t at = (std::size_t)(it - h.paths.begin());
        h.titles[at] = title;
        h.lines[at] = line;
      } else {
        h.paths.push_back(kv.second);
        h.titles.push_back(title);
        h.lines.push_back(line);
      }
    }
    return h;
  }

  /* The index of the longest heading path that is `path` or above it, or
   * -1. */
  long section(const std::string& path) const {
    long best = -1;
    std::size_t bestLen = 0;
    for (std::size_t k = 0; k < paths.size(); k++) {
      const std::string& p = paths[k];
      if ((path == p || startsWithSep(path, p, '/')) &&
          (best < 0 || p.size() > bestLen)) {
        best = (long)k;
        bestLen = p.size();
      }
    }
    return best;
  }
};

/* The rendition with the appendix *Notes* after its marker. */
std::string withAppendix(const std::string& markdown,
                         const std::vector<SpecAppendixEntry>& entries,
                         const Headings& titles, bool references) {
  std::size_t len = markdown.size();
  while (len > 0 && markdown[len - 1] == '\n') len--;
  std::string b = markdown.substr(0, len);
  b += "\n\n";
  b += kSpecMarkdownAppendixMarker;
  b += "\n\n## Notes\n";
  std::optional<std::string> section;
  for (const SpecAppendixEntry& e : entries) {
    std::string path, title;
    if (e.value.has_value()) {
      const long k = titles.section(e.value->path);
      path = k >= 0 ? titles.paths[(std::size_t)k] : e.value->path;
      title = k >= 0 ? titles.titles[(std::size_t)k] : e.value->path;
    }
    if (!section.has_value() || path != *section) {
      b += "\n### " + title + "\n";
      section = path;
    }
    std::string text;
    std::size_t from = 0;
    for (;;) {
      if (from < e.text.size() && e.text[from] == '#') text += '\\';
      const std::size_t nl = e.text.find('\n', from);
      if (nl == std::string::npos) {
        text += e.text.substr(from);
        break;
      }
      text += e.text.substr(from, nl - from + 1);
      from = nl + 1;
    }
    const std::string num = std::to_string(e.number);
    if (references) {
      b += "\n<a id=\"note-" + num + "\"></a>**[" + num + "]** " + text +
           " [\xe2\x86\xa9](#note-" + num + "-ref)\n";
    } else {
      b += "\n**[" + num + "]** " + text + "\n";
    }
  }
  return b;
}

bool inRoot(const std::string& prefix, const std::string& p) {
  return p == prefix || startsWithSep(p, prefix, '/');
}

void pushFinding(SpecStripResult& out, const std::string& kind,
                 const std::string& message,
                 const SpecStripValueRef* ref = nullptr) {
  SpecStripFinding f;
  f.kind = kind;
  f.message = message;
  if (ref != nullptr) f.ref = *ref;
  out.findings.push_back(std::move(f));
}

/* Compares what the rendition reads back as (`got`) with what the stripped
 * document holds (`want`), both keyed by path, under the root. */
void compareReadBack(const std::string& what, const std::string& prefix,
                     const std::map<std::string, std::string>& want,
                     const std::map<std::string, std::string>& got,
                     SpecStripResult& out) {
  std::set<std::string> keys;
  for (const auto& kv : want) keys.insert(kv.first);
  for (const auto& kv : got) keys.insert(kv.first);
  for (const std::string& k : keys) {
    if (!inRoot(prefix, k)) continue;
    auto w = want.find(k);
    auto g = got.find(k);
    if (w != want.end() && g != got.end()) {
      if (w->second == g->second) continue;
      // A wrapped paragraph written in a table cell reads back on one line
      // (SOM §11.4).
      const auto joined = markdownWrappedParagraphJoined(w->second);
      if (joined.has_value() && *joined == g->second) continue;
    }
    pushFinding(out, "parse",
                what + " at " + k + " reads back as " +
                    (g == got.end() ? std::string("nothing")
                                    : "\"" + g->second + "\"") +
                    " instead of " +
                    (w == want.end() ? std::string("nothing")
                                     : "\"" + w->second + "\""));
  }
}

/* The readable rendition reads back as the stripped document, and neither it
 * nor the stripped document adds a finding. */
void checkOutput(const SpecModel& model, const DocSpecsSchema* schema,
                 const SpecRoot& root, const std::string& rootType,
                 const KeyPaths& before, const SpecDocument& document,
                 const SpecDocument& copy, const std::string& readable,
                 SpecStripResult& out) {
  const SpecMarkdownResult parsed = markdownParse(model, readable);
  for (const SpecMarkdownRejection& r : parsed.rejections) {
    pushFinding(out, "parse", "the rendition rejects: " + r.display());
  }
  const std::string prefix =
      !root.sectionId.empty() ? root.sectionId : root.type;
  std::map<std::string, std::string> want;
  for (const std::string& p : copy.contentPaths()) want[p] = copy.content(p);
  compareReadBack("content", prefix, want, parsed.staged.content, out);
  want.clear();
  for (const std::string& p : copy.formPaths()) {
    for (const std::string& f : copy.formFieldNames(p)) {
      want[p + "/" + f] = copy.formField(p, f);
    }
  }
  std::map<std::string, std::string> got;
  for (const auto& form : parsed.staged.forms) {
    for (const auto& field : form.second) {
      got[form.first + "/" + field.first] = field.second;
    }
  }
  compareReadBack("the form field", prefix, want, got, out);

  const KeyPaths after = tierFindings(model, schema, rootType, copy);
  for (const std::string& key : after.keys) {
    if (before.find(key) >= 0) continue;
    pushFinding(out, key.compare(0, 6, "schema") == 0 ? "schema" : "instance",
                key);
  }
  if (schema == nullptr) return;
  std::string original;
  try {
    original = markdownExportRoot(model, document, root);
  } catch (const std::exception&) {
    return;
  }
  const DocSpecsValidator val(*schema, true);
  std::vector<DocSpecsViolation> had, now;
  val.validateMarkdown(original, had);
  val.validateMarkdown(readable, now);
  auto key = [](const DocSpecsViolation& v) {
    return v.rule + " " + v.sectionId + ": " + v.message;
  };
  std::set<std::string> hadKeys;
  for (const auto& v : had) hadKeys.insert(key(v));
  for (const auto& v : now) {
    const std::string k = key(v);
    if (hadKeys.count(k) == 0) {
      pushFinding(out, "schema",
                  "the rendition: line " + std::to_string(v.line) + ": " + k);
    }
  }
}

/* Every value of `doc`: stored headlines, content, form fields, each group
 * sorted. */
std::vector<SpecStripValueRef> valueRefs(const SpecDocument& doc) {
  std::vector<SpecStripValueRef> refs;
  auto sorted = [](std::vector<std::string> v) {
    std::sort(v.begin(), v.end());
    return v;
  };
  for (const std::string& p : sorted(doc.headlinePaths())) {
    refs.push_back(SpecStripValueRef{p, std::nullopt, true});
  }
  for (const std::string& p : sorted(doc.contentPaths())) {
    refs.push_back(SpecStripValueRef{p, std::nullopt, false});
  }
  for (const std::string& p : sorted(doc.formPaths())) {
    for (const std::string& f : sorted(doc.formFieldNames(p))) {
      refs.push_back(SpecStripValueRef{p, f, false});
    }
  }
  return refs;
}

struct EntryAt {
  std::size_t index;
  std::size_t entry;
  int line;
};

}  // namespace strip_internal

SpecStripResult SpecDocumentStrip::strip(const SpecDocument& document,
                                         const SpecStripOptions& options,
                                         const SpecDocumentStripOptions& extra) {
  SpecStripResult out;
  const SpecModel* model = extra.model;
  const DocSpecsSchema* schema = extra.schema;
  const std::string& rootType = extra.rootType;

  Strip s;
  s.document = &document;
  s.options = &options;
  s.refs = valueRefs(document);
  s.originals.assign(s.refs.size(), std::string());
  s.plans.resize(s.refs.size());
  s.numbers.assign(s.refs.size(), std::vector<long long>());
  for (std::size_t i = 0; i < s.refs.size(); i++) {
    const std::string text = s.refs[i].read(document);
    if (text.empty()) continue;
    s.originals[i] = text;
    auto plan = std::make_unique<Plan>(text, options);
    if (!plan->findings().empty()) {
      for (const NotationFinding& f : plan->findings()) {
        pushFinding(out, "notation",
                    f.code + " (line " + std::to_string(f.line) +
                        "): " + f.message,
                    &s.refs[i]);
      }
      continue;
    }
    if (plan->changes()) s.plans[i] = std::move(plan);
  }

  s.copy = docCopy(document);
  long long next = 1;
  for (std::size_t i = 0; i < s.refs.size(); i++) {
    if (s.plans[i] == nullptr) continue;
    s.setNumbers(i);
    for (long long& n : s.numbers[i]) n = next++;
  }
  s.apply();
  KeyPaths base;
  if (model != nullptr) {
    base = tierFindings(*model, schema, rootType, document);
    s.emptyingRule(*model, schema, rootType, base, out.kept, out.removedItems);
  }

  // The appendix, numbered through the rendition.
  std::vector<EntryAt> entries;
  for (std::size_t i = 0; i < s.refs.size(); i++) {
    if (s.plans[i] == nullptr) continue;
    for (std::size_t k = 0; k < s.plans[i]->entryCount(); k++) {
      entries.push_back(EntryAt{i, k, 0});
    }
  }
  const SpecRoot* root = nullptr;
  if (model != nullptr) {
    try {
      root = &documentRootToExport(*model, s.copy, rootType);
    } catch (const std::exception& e) {
      pushFinding(out, "parse", e.what());
    }
  }
  Headings titles;
  if (!entries.empty() && root != nullptr) {
    try {
      titles = Headings::from(markdownExportRootWithMap(*model, s.copy, *root));
      for (EntryAt& e : entries) {
        const long sec = titles.section(s.refs[e.index].path);
        e.line = sec >= 0 ? titles.lines[(std::size_t)sec] : 0;
      }
      std::stable_sort(entries.begin(), entries.end(),
                       [](const EntryAt& x, const EntryAt& y) {
                         if (x.line != y.line) return x.line < y.line;
                         if (x.index != y.index) return x.index < y.index;
                         return x.entry < y.entry;
                       });
    } catch (const std::exception& e) {
      pushFinding(out, "parse", e.what());
    }
  }
  for (std::size_t k = 0; k < entries.size(); k++) {
    s.numbers[entries[k].index][entries[k].entry] = (long long)k + 1;
  }
  s.apply();

  for (std::size_t i = 0; i < s.refs.size(); i++) {
    if (s.plans[i] == nullptr) continue;
    SpecStripTextResult r = s.plans[i]->finish(&s.numbers[i]);
    out.values.push_back(
        SpecStrippedValue{s.refs[i], s.originals[i], r.text, r.pieces});
    addCounts(out.dropped, r.dropped);
    addCounts(out.unmarked, r.unmarked);
    addCounts(out.appended, r.appended);
    out.marksDropped += r.marksDropped;
    for (SpecAppendixEntry& a : r.appendix) {
      a.value = s.refs[i];
      out.appendix.push_back(std::move(a));
    }
  }
  std::stable_sort(out.appendix.begin(), out.appendix.end(),
                   [](const SpecAppendixEntry& x, const SpecAppendixEntry& y) {
                     return x.number < y.number;
                   });

  out.readableHeader = SpecReadableHeader::format(options, extra.source);
  if (root != nullptr) {
    try {
      SpecMarkdownExportOptions mo;
      mo.headingDivs = options.headingDivs;
      mo.readableHeader = out.readableHeader;
      const SpecMarkdownRendition rendition =
          markdownExportRootWithOptions(*model, s.copy, *root, mo);
      if (titles.paths.empty() && !out.appendix.empty()) {
        titles = Headings::from(rendition);
      }
      out.readable = out.appendix.empty()
                         ? rendition.markdown
                         : withAppendix(rendition.markdown, out.appendix,
                                        titles, options.appendixReferences);
    } catch (const std::exception& e) {
      pushFinding(out, "parse", e.what());
    }
    if (out.readable.has_value()) {
      checkOutput(*model, schema, *root, rootType, base, document, s.copy,
                  *out.readable, out);
    }
  }
  out.document = std::move(s.copy);
  return out;
}

std::vector<std::string> SpecStripResult::report() const {
  std::vector<std::string> out;
  auto get = [](const Counts& m, const std::string& k) {
    for (const auto& kv : m) {
      if (kv.first == k) return kv.second;
    }
    return 0LL;
  };
  for (const char* k : specStripKindNames) {
    const long long d = get(dropped, k), u = get(unmarked, k),
                    a = get(appended, k);
    if (d + u + a <= 0) continue;
    out.push_back(std::string(k) + ": " + std::to_string(d) + " dropped, " +
                  std::to_string(u) + " unmarked, " + std::to_string(a) +
                  " moved");
  }
  if (marksDropped > 0) {
    out.push_back("review marks inside dropped elements: " +
                  std::to_string(marksDropped));
  }
  for (const SpecStripKept& k : kept) {
    out.push_back("KEPT (would empty a required value): " + k.ref.label() +
                  " \xe2\x80\x94 " + k.finding);
  }
  return out;
}

std::string SpecStripResult::toJson() const {
  std::string out = "{\"document\":" +
                    documentJsonToCanonicalJson(document.toJson()) +
                    ",\"kept\":[";
  for (std::size_t i = 0; i < kept.size(); i++) {
    if (i > 0) out += ",";
    out += kept[i].ref.toJson();
  }
  out += "],\"removedItems\":[";
  for (std::size_t i = 0; i < removedItems.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(removedItems[i]);
  }
  out += "],\"appendix\":[";
  for (std::size_t i = 0; i < appendix.size(); i++) {
    if (i > 0) out += ",";
    out += appendix[i].toJson();
  }
  out += "],\"dropped\":" + countsJson(dropped) +
         ",\"unmarked\":" + countsJson(unmarked) +
         ",\"appended\":" + countsJson(appended) +
         ",\"marksDropped\":" + std::to_string(marksDropped) +
         ",\"readableHeader\":" + jsonEncodeStr(readableHeader) +
         ",\"readable\":" +
         (readable.has_value() ? jsonEncodeStr(*readable)
                               : std::string("null")) +
         ",\"findings\":[";
  for (std::size_t i = 0; i < findings.size(); i++) {
    if (i > 0) out += ",";
    out += jsonEncodeStr(findings[i].kind);
  }
  return out + "]}";
}

}  // namespace som
