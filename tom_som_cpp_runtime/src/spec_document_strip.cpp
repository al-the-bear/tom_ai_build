/* The strip of one value (SOM §11.10) — the C++ port of the value strip of
 * `spec_document_strip.dart` / `spec_document_strip.ts` (see
 * spec_document_strip.hpp). The plan works on the value's UTF-16 code units,
 * so offsets, the edit scripts and every "one character" step mean what they
 * mean in Dart and TypeScript. */
#include "spec_document_strip.hpp"

#include <algorithm>
#include <cstddef>
#include <iterator>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "som_json.hpp"
#include "spec_document_markdown.hpp"
#include "spec_review_annotations.hpp"
#include "spec_text_pattern.hpp"

namespace som {

namespace {

using U16 = std::u16string;

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

enum OpType { kKeep = 0, kDel = 1, kIns = 2 };

struct Op {
  int type;
  char16_t ch;
  std::string label;  // "" for a keep
};

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

struct MarkAt {
  std::size_t start, end, bodyStart, bodyEnd;
  long long sep;  // -1 when none
};

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

  SpecStripTextResult finish() const;

 private:
  const SpecStripOptions& options_;
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

SpecStripTextResult Plan::finish() const {
  SpecStripTextResult r;
  if (!findings_.empty()) {
    r.text = o8_;
    r.findings = findings_;
    return r;
  }
  const U16& t = t_;
  auto number = [](long long entry) { return entry + 1; };
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
        SpecAppendixEntry{number((long long)k), entries_[k].kind, entries_[k].text});
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

}  // namespace

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
