/* spec_answers — the answers of a review round for a step folder (SOM
 * §11.9.7), an idiomatic-C++ port of the Dart `spec_answers.dart`. See the
 * header for the contract. */
#include "spec_answers.hpp"

#include <algorithm>
#include <map>
#include <set>
#include <stdexcept>
#include <utility>

#include "som_json.hpp"
#include "spec_document_markdown.hpp"

namespace som {
namespace {

const std::string kEmDashSep = " \xE2\x80\x94 ";  // ` — `

/* Decodes one UTF-8 code point at `i`, advancing it. Malformed bytes decode
 * to themselves, one byte at a time. */
unsigned long nextCp(const std::string& s, std::size_t& i) {
  unsigned char c0 = static_cast<unsigned char>(s[i]);
  unsigned long c = c0;
  std::size_t n = 1;
  std::size_t left = s.size() - i;
  auto b = [&](std::size_t k) {
    return static_cast<unsigned long>(static_cast<unsigned char>(s[i + k]) &
                                      0x3F);
  };
  if (c0 >= 0xF0 && left >= 4) {
    c = ((c & 0x07UL) << 18) | (b(1) << 12) | (b(2) << 6) | b(3);
    n = 4;
  } else if (c0 >= 0xE0 && c0 < 0xF0 && left >= 3) {
    c = ((c & 0x0FUL) << 12) | (b(1) << 6) | b(2);
    n = 3;
  } else if (c0 >= 0xC0 && c0 < 0xE0 && left >= 2) {
    c = ((c & 0x1FUL) << 6) | b(1);
    n = 2;
  }
  i += n;
  return c;
}

/* The whitespace Dart's `String.trim` removes. */
bool dartIsSpace(unsigned long c) {
  return (c >= 0x09 && c <= 0x0D) || c == 0x20 || c == 0x85 || c == 0xA0 ||
         c == 0x1680 || (c >= 0x2000 && c <= 0x200A) || c == 0x2028 ||
         c == 0x2029 || c == 0x202F || c == 0x205F || c == 0x3000 ||
         c == 0xFEFF;
}

/* `s.trim()`, Dart semantics. */
std::string dartTrim(const std::string& s) {
  std::size_t i = 0, first = 0, last = 0;
  bool any = false;
  while (i < s.size()) {
    std::size_t st = i;
    unsigned long c = nextCp(s, i);
    if (!dartIsSpace(c)) {
      if (!any) {
        first = st;
        any = true;
      }
      last = i;
    }
  }
  return any ? s.substr(first, last - first) : std::string();
}

/* `s.split('\n')`. */
std::vector<std::string> splitLines(const std::string& s) {
  std::vector<std::string> out;
  std::size_t st = 0;
  for (;;) {
    std::size_t p = s.find('\n', st);
    if (p == std::string::npos) {
      out.push_back(s.substr(st));
      return out;
    }
    out.push_back(s.substr(st, p - st));
    st = p + 1;
  }
}

std::string jsonOpt(const std::optional<std::string>& v) {
  return v ? jsonEncodeStr(*v) : "null";
}

/* `^(#+) <!--\[([^\]]+)\]-->`: the level and the id, or level 0. */
std::pair<std::size_t, std::string> matchHeading(const std::string& s) {
  std::size_t n = 0;
  while (n < s.size() && s[n] == '#') n++;
  if (n == 0 || s.compare(n, 6, " <!--[") != 0) return {0, ""};
  std::size_t st = n + 6;
  std::size_t p = st;
  while (p < s.size() && s[p] != ']') p++;
  if (p == st || s.compare(p, 4, "]-->") != 0) return {0, ""};
  return {n, s.substr(st, p - st)};
}

std::string rootSegment(const SpecRoot& r) {
  return r.sectionId.empty() ? r.type : r.sectionId;
}

}  // namespace

const char* specAnswerKindName(SpecAnswerKind kind) {
  switch (kind) {
    case SpecAnswerKind::Answered:
      return "answered";
    case SpecAnswerKind::Open:
      return "open";
    case SpecAnswerKind::Comment:
      return "comment";
    case SpecAnswerKind::Mark:
      return "mark";
  }
  return "answered";
}

std::string SpecAnswerEntry::toJson() const {
  return std::string("{\"kind\":") + jsonEncodeStr(specAnswerKindName(kind)) +
         ",\"id\":" + jsonOpt(id) + ",\"section\":" + jsonEncodeStr(section) +
         ",\"line\":" + std::to_string(line) +
         ",\"path\":" + jsonEncodeStr(path) + ",\"field\":" + jsonOpt(field) +
         ",\"topic\":" + jsonOpt(topic) +
         ",\"combined\":" + (combined ? "true" : "false") +
         ",\"text\":" + jsonEncodeStr(text) +
         ",\"answer\":" + jsonEncodeStr(answer) +
         ",\"author\":" + jsonOpt(author) + ",\"markKind\":" +
         (markKind ? jsonEncodeStr(specMarkKindName(*markKind)) : "null") +
         ",\"oldText\":" + jsonOpt(oldText) +
         ",\"newText\":" + jsonOpt(newText) +
         ",\"comment\":" + jsonOpt(comment) + "}";
}

SpecAnswerCounts SpecAnswerCounts::operator+(const SpecAnswerCounts& o) const {
  SpecAnswerCounts c;
  c.answered = answered + o.answered;
  c.open = open + o.open;
  c.comments = comments + o.comments;
  c.marks = marks + o.marks;
  return c;
}

std::string SpecAnswerCounts::toJson() const {
  return "{\"answered\":" + std::to_string(answered) +
         ",\"open\":" + std::to_string(open) +
         ",\"comments\":" + std::to_string(comments) +
         ",\"marks\":" + std::to_string(marks) + "}";
}

SpecAnswerCounts SpecAnswerExtract::counts() const {
  SpecAnswerCounts c;
  for (const auto& e : entries) {
    switch (e.kind) {
      case SpecAnswerKind::Answered:
        c.answered++;
        break;
      case SpecAnswerKind::Open:
        c.open++;
        break;
      case SpecAnswerKind::Comment:
        c.comments++;
        break;
      case SpecAnswerKind::Mark:
        c.marks++;
        break;
    }
  }
  return c;
}

std::string SpecAnswerExtract::toJson() const {
  std::string out = "{\"label\":" + jsonEncodeStr(label) +
                    ",\"qualifier\":" + jsonEncodeStr(qualifier) +
                    ",\"entries\":[";
  for (std::size_t i = 0; i < entries.size(); i++) {
    if (i > 0) out += ',';
    out += entries[i].toJson();
  }
  out += "],\"counts\":" + counts().toJson() + "}";
  return out;
}

SpecAnswerExtract extractAnswers(const SpecModel& model, SpecDocument& doc,
                                 const std::string& label,
                                 const std::optional<std::string>& path) {
  if (model.roots.empty()) {
    throw std::runtime_error("the model has no roots");
  }
  const SpecRoot* root = &model.roots.front();
  for (const auto& r : model.roots) {
    if (doc.hasValuesUnder(rootSegment(r))) {
      root = &r;
      break;
    }
  }
  const std::string qualifier = rootSegment(*root);
  const SpecMarkdownRendition rendition =
      markdownExportRootWithMap(model, doc, *root);
  const std::vector<std::string> lines = splitLines(rendition.markdown);

  // The section-id chain of every heading line (1-based).
  std::map<std::size_t, std::string> chains;
  std::vector<std::pair<std::size_t, std::string>> stack;
  for (std::size_t i = 0; i < lines.size(); i++) {
    auto [level, id] = matchHeading(lines[i]);
    if (level == 0) continue;
    while (!stack.empty() && stack.back().first >= level) stack.pop_back();
    stack.emplace_back(level, id);
    std::string chain;
    for (std::size_t k = 0; k < stack.size(); k++) {
      if (k > 0) chain += " > ";
      chain += stack[k].second;
    }
    chains[i + 1] = chain;
  }

  // The heading line of a value: the heading whose path is the longest
  // prefix of the value's path (on equal length, the first).
  auto headingLine = [&](const std::string& valuePath) -> std::size_t {
    std::size_t best = 0;
    long long bestLen = -1;
    for (const auto& [l, hp] : rendition.headingPaths) {
      bool match = valuePath == hp ||
                   (valuePath.size() > hp.size() &&
                    valuePath.compare(0, hp.size(), hp) == 0 &&
                    valuePath[hp.size()] == '/');
      if (match && static_cast<long long>(hp.size()) > bestLen) {
        best = static_cast<std::size_t>(l);
        bestLen = static_cast<long long>(hp.size());
      }
    }
    return best;
  };

  auto chainAt = [&](std::size_t line) -> std::string {
    for (std::size_t l = line; l >= 1; l--) {
      auto it = chains.find(l);
      if (it != chains.end()) return it->second;
    }
    return qualifier;
  };

  std::set<std::size_t> claimed;
  // The rendition line of an annotation: the first unclaimed line after the
  // value's heading whose trimmed text is the annotation's first line. A form
  // field's first line renders behind its label (`Owner: …`).
  auto locate = [&](const std::string& valuePath,
                    const std::optional<std::string>& field,
                    std::size_t valueLine,
                    const std::string& firstLine) -> std::size_t {
    const std::size_t h = headingLine(valuePath);
    const std::string want = dartTrim(firstLine);
    std::optional<std::string> labelled;
    if (field && !field->empty() && valueLine == 0) {
      std::string f = *field;
      if (f[0] >= 'a' && f[0] <= 'z') f[0] = static_cast<char>(f[0] - 'a' + 'A');
      labelled = dartTrim(f + ": " + want);
    }
    for (std::size_t i = h; i < lines.size(); i++) {
      const std::size_t l = i + 1;
      if (l <= h || claimed.count(l)) continue;
      const std::string t = dartTrim(lines[i]);
      if (t == want || (labelled && t == *labelled)) {
        claimed.insert(l);
        return l;
      }
    }
    return h == 0 ? 1 : h;
  };

  auto inScope = [&](const std::string& p) {
    return !path || p == *path ||
           (p.size() > path->size() && p.compare(0, path->size(), *path) == 0 &&
            p[path->size()] == '/');
  };

  SpecReviewAnnotations api(doc);
  // `list()` and `listMarks()` give the marks in the same order.
  const std::vector<SpecMarkEntry> marks = api.listMarks();
  std::size_t markIndex = 0;
  std::vector<SpecAnswerEntry> entries;
  for (const auto& a : api.list()) {
    // Every mark consumes its listing entry before the scope check, so marks
    // in a subtree keep their document-wide `M-<n>` ids.
    const SpecMarkEntry* m = a.kind == SpecReviewAnnotationKind::Mark
                                 ? &marks.at(markIndex++)
                                 : nullptr;
    if (!inScope(a.path)) continue;
    const std::string value =
        a.field ? doc.formField(a.path, *a.field) : doc.content(a.path);
    const std::vector<std::string> vlines = splitLines(value);
    const std::string first = a.line < vlines.size() ? vlines[a.line] : "";
    SpecAnswerEntry e;
    e.path = a.path;
    e.field = a.field;
    switch (a.kind) {
      case SpecReviewAnnotationKind::Question: {
        e.line = locate(a.path, a.field, a.line, first);
        e.kind = a.open() ? SpecAnswerKind::Open : SpecAnswerKind::Answered;
        e.id = a.id;
        e.topic = a.topic;
        e.combined = a.combined;
        e.text = a.text;
        e.answer = a.answer;
        break;
      }
      case SpecReviewAnnotationKind::Comment: {
        e.line = locate(a.path, a.field, a.line, first);
        e.kind = SpecAnswerKind::Comment;
        e.id = a.id;
        e.text = a.text;
        e.author = a.author;
        break;
      }
      case SpecReviewAnnotationKind::Mark: {
        e.line = locate(a.path, a.field, a.line, first);
        // A line holding several marks is found once; later marks on it
        // share the line.
        claimed.erase(e.line);
        e.kind = SpecAnswerKind::Mark;
        e.id = m->id;
        e.text = m->markup;
        e.markKind = a.markKind;
        e.oldText = m->oldText;
        e.newText = m->newText;
        e.comment = a.comment;
        break;
      }
    }
    e.section = chainAt(e.line);
    entries.push_back(std::move(e));
  }
  // Rendition order: by line; entries on one line keep their order.
  std::stable_sort(entries.begin(), entries.end(),
                   [](const SpecAnswerEntry& x, const SpecAnswerEntry& y) {
                     return x.line < y.line;
                   });
  SpecAnswerExtract out;
  out.label = label;
  out.qualifier = qualifier;
  out.entries = std::move(entries);
  return out;
}

namespace {

/* A labelled value: `- **Label:** first line`, further lines indented two
 * spaces. */
std::string item(const std::string& label, const std::string& value) {
  const std::vector<std::string> ls = splitLines(value);
  std::string b = "- **" + label + ":**";
  if (!ls.front().empty()) b += " " + ls.front();
  for (std::size_t i = 1; i < ls.size(); i++) {
    b += ls[i].empty() ? std::string("\n") : "\n  " + ls[i];
  }
  return b;
}

std::string countPart(std::size_t n, const std::string& noun) {
  return std::to_string(n) + " " + noun + (n == 1 ? "" : "s");
}

std::string countLine(const SpecAnswerCounts& c,
                      const SpecAnswerRenderOptions& o) {
  std::string s = countPart(c.answered, "answered question") + ", " +
                  countPart(c.open, "open question") + ", " +
                  countPart(c.comments, "comment");
  if (o.includeMarks) s += ", " + countPart(c.marks, "inline mark");
  return s + ".";
}

std::string orNull(const std::optional<std::string>& v) {
  return v ? *v : "null";
}

std::string entryHeading(const SpecAnswerExtract& x, const SpecAnswerEntry& e) {
  switch (e.kind) {
    case SpecAnswerKind::Answered:
    case SpecAnswerKind::Open:
      return orNull(e.id) + kEmDashSep + orNull(e.topic);
    case SpecAnswerKind::Comment:
      return e.id ? x.qualifier + " " + *e.id
                  : "Comment without id (line " + std::to_string(e.line) + ")";
    case SpecAnswerKind::Mark:
      return orNull(e.id) + kEmDashSep +
             (e.markKind ? specMarkKindName(*e.markKind) : "null");
  }
  return "";
}

}  // namespace

std::string renderAnswers(const std::vector<SpecAnswerExtract>& extracts,
                          const SpecAnswerRenderOptions& options) {
  SpecAnswerCounts total;
  for (const auto& x : extracts) total = total + x.counts();
  std::vector<std::string> out = {"# " + options.title, "",
                                  countLine(total, options)};
  for (const auto& x : extracts) {
    out.push_back("");
    out.push_back("## " + x.label);
    out.push_back("");
    out.push_back(countLine(x.counts(), options));
    auto section = [&](const std::string& heading, SpecAnswerKind kind) {
      std::vector<const SpecAnswerEntry*> es;
      for (const auto& e : x.entries) {
        if (e.kind == kind) es.push_back(&e);
      }
      out.push_back("");
      out.push_back("### " + heading);
      if (es.empty()) {
        out.push_back("");
        out.push_back("None.");
        return;
      }
      for (const SpecAnswerEntry* e : es) {
        out.push_back("");
        out.push_back("#### " + entryHeading(x, *e));
        out.push_back("");
        out.push_back(item("Section", "`" + e->section + "`"));
        out.push_back(item("Line", std::to_string(e->line)));
        if (e->field) out.push_back(item("Field", "`" + *e->field + "`"));
        switch (kind) {
          case SpecAnswerKind::Answered:
          case SpecAnswerKind::Open:
            out.push_back(item("Question", e->text));
            if (kind == SpecAnswerKind::Answered) {
              out.push_back(item("Answer", e->answer));
            }
            break;
          case SpecAnswerKind::Comment:
            if (e->author) out.push_back(item("Author", *e->author));
            out.push_back(item("Comment", e->text));
            break;
          case SpecAnswerKind::Mark:
            out.push_back(item("Markup", "`" + e->text + "`"));
            out.push_back(item("Old", e->oldText.value_or("")));
            out.push_back(item("New", e->newText.value_or("")));
            if (e->comment) out.push_back(item("Note", *e->comment));
            break;
        }
      }
    };
    section("Answered questions", SpecAnswerKind::Answered);
    section("Comments", SpecAnswerKind::Comment);
    if (options.includeOpen) section("Open questions", SpecAnswerKind::Open);
    if (options.includeMarks) section("Inline marks", SpecAnswerKind::Mark);
  }
  std::string joined;
  for (std::size_t i = 0; i < out.size(); i++) {
    if (i > 0) joined += '\n';
    joined += out[i];
  }
  return joined + "\n";
}

}  // namespace som
