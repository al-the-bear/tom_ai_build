// Stripped renditions (SOM §11.10): styled-div headings, the readable header
// and the document strip's checks, over a model nine sections deep — the C++
// port of `tom_som_dart_runtime/test/spec_document_strip_test.dart`. The
// per-value rules and the corpus documents are the conformance cases of
// `strip_cases.json`, run by tests/conformance.cpp.
//
// Exit status is the number of failed checks (0 = green).

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_document.hpp"
#include "spec_document_markdown.hpp"
#include "spec_document_strip.hpp"
#include "spec_model.hpp"
#include "spec_review_annotations.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void check(const std::string& name, bool cond, const std::string& detail = "") {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  std::fprintf(stderr, "FAIL %s%s%s\n", name.c_str(),
               detail.empty() ? "" : ": ", detail.c_str());
}

/* A model nine sections deep: `L<n>` holds content `T<n>` and section
 * `L<n+1>`, so `T<n>` stands at depth n + 1. */
std::unique_ptr<som::SpecModel> deepModel() {
  std::string b =
      "{\"modelVersion\":1,\"modelVersionLabel\":\"0.1.0+1\","
      "\"roots\":[{\"type\":\"L1\",\"title\":\"Deep\",\"sectionId\":\"L1\"}],"
      "\"classes\":{";
  for (int n = 1; n <= 9; n++) {
    const std::string k = std::to_string(n);
    if (n > 1) b += ",";
    b += "\"L" + k + "\":{\"name\":\"L" + k + "\",\"sectionId\":\"L" + k + "\",";
    if (n == 1) {
      b += "\"annotations\":[{\"name\":\"Document\",\"arguments\":"
           "{\"title\":\"Deep\"}},{\"name\":\"SectionId\","
           "\"arguments\":{\"id\":\"L1\"}}],";
    }
    b += "\"fields\":[{\"name\":\"text\",\"kind\":\"content\",\"sectionId\":\"T" +
         k + "\",\"contentType\":\"text\"}";
    if (n < 9) {
      const std::string m = std::to_string(n + 1);
      b += ",{\"name\":\"next\",\"kind\":\"complex\",\"sectionId\":\"L" + m +
           "\",\"type\":\"L" + m + "\"}";
    }
    b += "]}";
  }
  b += "}}";
  std::string err;
  auto m = som::SpecModel::fromJsonStr(b, &err);
  if (m == nullptr) {
    std::fprintf(stderr, "fatal: deep model: %s\n", err.c_str());
    std::exit(2);
  }
  return m;
}

/* `L1/…/L<n>[/T<n>]`. */
std::string pathTo(int n, bool text) {
  std::string p;
  for (int k = 1; k <= n; k++) {
    if (k > 1) p += "/";
    p += "L" + std::to_string(k);
  }
  if (text) p += "/T" + std::to_string(n);
  return p;
}

som::SpecDocument deepDocument() {
  som::SpecDocument d;
  for (int n = 1; n <= 9; n++) {
    d.setContent(pathTo(n, true),
                 "Text " + std::to_string(n) + " [an aside]{.aside}.");
  }
  d.setHeadline(pathTo(7, false), "Seven & <more>\nsecond line");
  d.setContent(pathTo(8, true),
               "Before.\n\n<div class=\"heading9\" style=\"x\">Not a heading</div>"
               "\n\n\\<div class=\"heading7\" style=\"x\">Escaped once</div>");
  return d;
}

std::string docJson(const som::SpecDocument& d) {
  return som::documentJsonToCanonicalJson(d.toJson());
}

std::vector<std::string> linesOf(const std::string& md) {
  std::vector<std::string> out;
  std::size_t pos = 0;
  for (;;) {
    const std::size_t nl = md.find('\n', pos);
    out.push_back(md.substr(pos, nl == std::string::npos ? std::string::npos
                                                         : nl - pos));
    if (nl == std::string::npos) break;
    pos = nl + 1;
  }
  return out;
}

bool hasLine(const std::string& md, const std::string& line) {
  for (const std::string& l : linesOf(md)) {
    if (l == line) return true;
  }
  return false;
}

/* Whether `md` reads back as `want` without a rejection. */
void checkReadsBack(const std::string& name, const std::string& md,
                    const som::SpecModel& model, const som::SpecDocument& want) {
  const som::SpecMarkdownImport back = som::SpecDocument::fromMarkdown(md, model);
  check(name + ": no rejections", back.result.rejections.empty());
  const std::string g = docJson(back.document);
  check(name + ": reads back", g == docJson(want), g);
}

void testHeadingDivs(const som::SpecModel& model, const som::SpecRoot& root) {
  const som::SpecDocument doc = deepDocument();
  som::SpecMarkdownExportOptions mo;
  mo.headingDivs = true;
  const som::SpecMarkdownRendition r =
      som::markdownExportRootWithOptions(model, doc, root, mo);
  bool deepHash = false;
  for (const std::string& l : linesOf(r.markdown)) {
    if (l.compare(0, 7, "#######") == 0) deepHash = true;
  }
  check("divs: no # heading deeper than 6", !deepHash);
  check("divs: level 7 with the title escaped",
        hasLine(r.markdown,
                "<div class=\"heading7\" style=\"margin:1em 0 0.5em;padding-left:"
                "0.75em;font-weight:bold\"><!--[L7]--> <a id=\"L7\"></a> "
                "Seven &amp; &lt;more&gt;<br>second line</div>"),
        r.markdown);
  check("divs: level 10 indent",
        r.markdown.find("<div class=\"heading10\" style=\"margin:1em 0 0.5em;"
                        "padding-left:3em;") != std::string::npos);
  check("divs: a div-shaped value line is escaped",
        hasLine(r.markdown,
                "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"));
  check("divs: an escaped one once more",
        hasLine(r.markdown,
                "\\\\<div class=\"heading7\" style=\"x\">Escaped once</div>"));
  // Every heading is in the map, the div ones included.
  int headings = 0, mapped = 0, line = 1;
  for (const std::string& l : linesOf(r.markdown)) {
    if ((l.compare(0, 1, "#") == 0 || l.compare(0, 19, "<div class=\"heading") == 0) &&
        l.find("<!--[") != std::string::npos) {
      headings++;
      if (r.headingPaths.count(line) != 0) mapped++;
    }
    line++;
  }
  check("divs: the heading map holds the div headings",
        headings > 9 && mapped == headings &&
            (std::size_t)mapped == r.headingPaths.size(),
        std::to_string(headings) + "/" + std::to_string(mapped));
  checkReadsBack("divs", r.markdown, model, doc);

  const std::string plain = som::markdownExportRoot(model, doc, root);
  check("no divs: # headings",
        plain.find("####### <!--[L7]-->") != std::string::npos &&
            plain.find("\n<div class=\"heading7\"") == std::string::npos);
  check("no divs: the value line is still escaped",
        hasLine(plain, "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"));
  checkReadsBack("no divs", plain, model, doc);

  const char* want[6] = {"0.75", "1.5", "2.25", "3", "3.75", "4.5"};
  for (int d = 7; d <= 12; d++) {
    const std::string got = som::markdownHeadingDivIndent(d);
    check("divs: indent", got == want[d - 7], got);
  }
  check("divs: a heading6 div is content",
        !som::markdownHeadingDiv("<div class=\"heading6\">x</div>", nullptr,
                                 nullptr));
  int level = 0;
  std::string inner;
  check("divs: a heading7 div is a heading",
        som::markdownHeadingDiv("<div class=\"heading7\">a &amp;lt;</div>",
                                &level, &inner) &&
            level == 7 && inner == "a &lt;",
        inner);
}

void testReadable(const som::SpecModel& model) {
  som::SpecReadableSource source{"deep.tomspecs.yaml", "r3", "8e1d2a7", true};
  som::SpecDocumentStripOptions extra;
  extra.model = &model;
  extra.source = &source;
  const som::SpecStripOptions o =
      som::SpecStripOptions::fromNames({"aside"}, {}, {}, false, true);
  som::SpecDocument doc = deepDocument();
  som::SpecStripResult r = som::SpecDocumentStrip::strip(doc, o, extra);
  std::string findings;
  for (const auto& f : r.findings) findings += f.toString() + "; ";
  check("readable: no findings", r.ok(), findings);
  check("readable: the header",
        r.readableHeader ==
            "<!-- readable: drop=aside; headings=divs; "
            "of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->",
        r.readableHeader);
  const std::string readable = r.readable.value_or("");
  const std::size_t nl = readable.find('\n');
  check("readable: the header follows the docspec line",
        readable.compare(0, 14, "<!-- docspec: ") == 0 && nl != std::string::npos &&
            readable.compare(nl + 1, r.readableHeader.size(), r.readableHeader) == 0,
        readable);
  check("readable: divs and no aside",
        readable.find("<div class=\"heading8\"") != std::string::npos &&
            readable.find("{.aside}") == std::string::npos);
  const som::SpecMarkdownResult parsed = som::markdownParse(model, readable);
  check("readable: the parse reads the header",
        parsed.readableHeader.has_value() &&
            *parsed.readableHeader == r.readableHeader);
  const auto h = som::SpecReadableHeader::parse(parsed.readableHeader.value_or(""));
  check("readable: the header parses", h.has_value());
  if (h.has_value()) {
    const std::string again = som::SpecReadableHeader::format(
        h->options, h->source.has_value() ? &*h->source : nullptr);
    check("readable: format and parse are inverse", again == r.readableHeader,
          again);
    check("readable: the header's switches and source",
          h->options.drop == std::set<std::string>{"aside"} &&
              h->options.headingDivs && h->source.has_value() && h->source->dirty);
  }
  checkReadsBack("readable", readable, model, r.document);

  // The appendix lists the moved prose under its section titles.
  const som::SpecStripOptions a =
      som::SpecStripOptions::fromNames({}, {}, {"aside"}, true, true);
  extra.source = nullptr;
  r = som::SpecDocumentStrip::strip(doc, a, extra);
  check("appendix: no findings", r.ok());
  check("appendix: eight entries", r.appendix.size() == 8,
        std::to_string(r.appendix.size()));
  for (std::size_t i = 0; i < r.appendix.size(); i++) {
    const int n = (int)i + 1 + (i >= 7 ? 1 : 0);  // T8 holds no aside
    const std::string p = pathTo(n, true);
    check("appendix: numbered in order, one value each",
          r.appendix[i].number == (long long)i + 1 && r.appendix[i].value.has_value() &&
              r.appendix[i].value->path == p,
          p);
  }
  const std::string text = r.readable.value_or("");
  const std::string marker = std::string(som::kSpecMarkdownAppendixMarker) + "\n";
  const std::size_t at = text.find(marker);
  check("appendix: after the marker", at != std::string::npos);
  if (at != std::string::npos) {
    const std::string notes = text.substr(at + marker.size());
    check("appendix: the Notes heading", notes.compare(0, 10, "\n## Notes\n") == 0,
          notes);
    int sections = 0;
    for (std::size_t q = notes.find("### Text\n"); q != std::string::npos;
         q = notes.find("### Text\n", q + 1)) {
      sections++;
    }
    check("appendix: a section each", sections == 8, std::to_string(sections));
    check("appendix: the entry with its back link",
          notes.find("<a id=\"note-1\"></a>**[1]** an aside "
                     "[\xe2\x86\xa9](#note-1-ref)") != std::string::npos,
          notes);
  }
  const std::string first = r.document.content(pathTo(1, true));
  check("appendix: the reference in the value",
        first == "Text 1<a id=\"note-1-ref\"></a>[\\[1\\]](#note-1).", first);
  // The DocSpecs parse stops at the marker: no Notes section.
  const som::DocSpecsDocument dd = som::docspecsParseDocument(text);
  bool notesSection = false;
  for (const som::DocSpecsSection* s : dd.allSections()) {
    if (s->title == "Notes") notesSection = true;
  }
  check("appendix: the validator does not read it", !notesSection);

  // A value with a notation error is refused and reported.
  doc.setContent(pathTo(2, true), "::: {.aside}\nopen");
  r = som::SpecDocumentStrip::strip(doc, o, extra);
  check("refused: not ok", !r.ok());
  check("refused: one notation finding",
        r.findings.size() == 1 && r.findings[0].kind == "notation" &&
            r.findings[0].ref.has_value());
  check("refused: the value is kept",
        r.document.content(pathTo(2, true)) == "::: {.aside}\nopen");

  // Without a model nothing is rendered or checked.
  const som::SpecStripOptions every =
      som::SpecStripOptions::fromNames({"all"}, {}, {}, false, false);
  r = som::SpecDocumentStrip::strip(deepDocument(), every);
  check("no model: no rendition", !r.readable.has_value());
  check("no model: stripped", r.document.content(pathTo(1, true)) == "Text 1.",
        r.document.content(pathTo(1, true)));
  const std::vector<std::string> report = r.report();
  check("no model: the report",
        report.size() == 1 && report[0] == "aside: 8 dropped, 0 unmarked, 0 moved",
        report.empty() ? "none" : report[0]);
}

void testStripped() {
  som::SpecDocument doc;
  doc.setContent("L1/T1",
                 "Keep {++this++}.\n\n> \xe2\xac\x86\xef\xb8\x8f **C-1** (Al): ok");
  doc.setHeadline("L1/L2", "Two {--old--}");
  const som::SpecDocument s = som::SpecReviewAnnotations(doc).stripped();
  check("stripped(): content", s.content("L1/T1") == "Keep this.",
        s.content("L1/T1"));
  check("stripped(): headlines too", s.headline("L1/L2") == "Two",
        s.headline("L1/L2"));
}

}  // namespace

int main() {
  const auto model = deepModel();
  const som::SpecRoot& root = model->rootByType("L1");
  testHeadingDivs(*model, root);
  testReadable(*model);
  testStripped();
  if (g_failures == 0) {
    std::printf("spec_document_strip_test: all %d checks passed\n", g_checks);
  }
  return g_failures;
}
