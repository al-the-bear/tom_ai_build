/* Unit tests for the DocSpecs-conform Markdown codec
 * (`spec_document_markdown.cpp`, SOM §11) — an idiomatic-C++ port
 * of the C `tom_som_c_runtime/tests/spec_document_markdown_test.c` (itself a
 * port of the Go / TypeScript / Python / Dart reference suites). The check
 * *names* match the reference suites byte-for-byte.
 *
 * The generated `*.md` is a genuine DocSpecs document: line 1 is the
 * `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is a heading of the form `## <!--[SECTION-ID]--> Title`, content
 * sections are normal markdown text (no fences), `@Form` sections use the
 * plain-text `FieldName: value` format, and a `List<T>` field heads a
 * `<!--[FOO-LST]-->` container section with its numbered items one level
 * deeper and their item-element children one level deeper again.
 */
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_document_markdown.hpp"
#include "spec_model.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void mdCheck(const char* name, bool condition, const std::string& detail = "") {
  g_checks++;
  if (!condition) {
    g_failures++;
    if (!detail.empty()) {
      std::fprintf(stderr, "FAIL: %s: %s\n", name, detail.c_str());
    } else {
      std::fprintf(stderr, "FAIL: %s\n", name);
    }
  }
}

[[noreturn]] void fatal(const char* msg) {
  std::fprintf(stderr, "FATAL: %s\n", msg);
  std::exit(2);
}

/* ---- string helpers ------------------------------------------------------ */

bool hasPrefix(const std::string& s, const std::string& prefix) {
  return s.compare(0, prefix.size(), prefix) == 0;
}

bool hasSuffix(const std::string& s, const std::string& suffix) {
  return s.size() >= suffix.size() &&
         s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

bool contains(const std::string& s, const std::string& sub) {
  return s.find(sub) != std::string::npos;
}

std::string firstLine(const std::string& s) {
  std::size_t nl = s.find('\n');
  return nl != std::string::npos ? s.substr(0, nl) : s;
}

std::string contentOr(const som::SpecDocument& d, const std::string& path) {
  const std::string* v = d.contentOpt(path);
  return v != nullptr ? *v : "";
}

std::string formFieldOr(const som::SpecDocument& d, const std::string& path,
                        const std::string& field) {
  const std::string* v = d.formFieldOpt(path, field);
  return v != nullptr ? *v : "";
}

std::string itemSectionIdOr(const som::SpecDocument& d,
                            const std::string& itemPath) {
  const std::string* v = d.itemSectionIdOpt(itemPath);
  return v != nullptr ? *v : "";
}

/* Renders every rejection joined by "; " (mirrors mdRejStr). */
std::string mdRejStr(const som::SpecMarkdownResult& r) {
  std::string out;
  for (std::size_t i = 0; i < r.rejections.size(); i++) {
    if (i > 0) {
      out += "; ";
    }
    out += r.rejections[i].display();
  }
  return out;
}

/* map[string]string equality on the staged forms of `path` vs a single-field
 * expectation {field: value}. */
bool formMatchesSingle(const som::SpecMarkdownResult& r, const std::string& path,
                       const std::string& field, const std::string& value) {
  auto it = r.staged.forms.find(path);
  if (it == r.staged.forms.end()) {
    return false;
  }
  const auto& fields = it->second;
  if (fields.size() != 1) {
    return false;
  }
  auto fit = fields.find(field);
  return fit != fields.end() && fit->second == value;
}

/* The staged content value for `path`, or nullptr when absent. */
const std::string* stagedContent(const som::SpecMarkdownResult& r,
                                 const std::string& path) {
  auto it = r.staged.content.find(path);
  return it != r.staged.content.end() ? &it->second : nullptr;
}

std::size_t stagedContentLen(const som::SpecMarkdownResult& r) {
  return r.staged.content.size();
}

/* ---- fixtures (shared with one_line_export_test.cpp) --------------------- */

const char* DEMO_MODEL_JSON = R"({
  "roots": [
    {"type": "DemoDoc", "title": "Demo Document", "sectionId": "D00", "description": "A demo document."}
  ],
  "classes": {
    "DemoDoc": {
      "name": "DemoDoc",
      "sectionId": "D00",
      "fields": [
        {"name": "overview", "kind": "content", "sectionId": "D00-OVR"},
        {"name": "status", "kind": "enum", "sectionId": "D00-ST", "enumValues": ["draft", "final"]},
        {"name": "header", "kind": "form", "sectionId": "D00-HDR",
         "formFields": [
           {"name": "author", "label": "Author", "type": "String"},
           {"name": "reviewer", "label": "Reviewer", "type": "String"}
         ]},
        {"name": "meta", "kind": "complex", "type": "DemoMeta", "sectionId": "D00-MET"},
        {"name": "items", "kind": "list", "elementType": "DemoItem", "elementIsComplex": true, "sectionId": "D00-ITM"}
      ]
    },
    "DemoMeta": {
      "name": "DemoMeta",
      "sectionId": "D00-MET",
      "fields": [
        {"name": "note", "kind": "content", "sectionId": "D00-MET-NOTE"}
      ]
    },
    "DemoItem": {
      "name": "DemoItem",
      "fields": [
        {"name": "label", "kind": "content", "sectionId": "D01-LBL"},
        {"name": "body", "kind": "content", "sectionId": "D01-BODY"}
      ]
    }
  }
})";

/* mdD4rtBody — multi-line d4rt body with a run of three backticks mid-line. */
const char* MD_D4RT_BODY =
    "Column(\n"
    "  children: [\n"
    "    Text(\"hi\"),\n"
    "  ],\n"
    ") // not a fence: ``` still inside the body";

/* mdRichMarkdown — emphasis, a bullet list, a fenced code block containing
 * heading-like lines, and a leading `#` line at column 0. */
const char* MD_RICH_MARKDOWN =
    "Intro with **bold** and *italic*.\n"
    "\n"
    "- first bullet\n"
    "- second bullet\n"
    "\n"
    "```dart\n"
    "# not a heading — shielded by the fence\n"
    "## also shielded\n"
    "void main() {}\n"
    "```\n"
    "\n"
    "# looks like a heading at column 0\n"
    "trailing paragraph";

std::unique_ptr<som::SpecModel> demoModel() {
  std::string err;
  auto m = som::SpecModel::fromJsonStr(DEMO_MODEL_JSON, &err);
  if (m == nullptr) {
    std::fprintf(stderr, "demo_model parse failed: %s\n", err.c_str());
    fatal("demo_model");
  }
  return m;
}

/* populatedDemoDoc mirrors the Dart _populated() helper. */
som::SpecDocument populateDemoDoc() {
  som::SpecDocument doc;
  doc.setContent("D00/D00-OVR", "An overview paragraph.\nWith two lines.");
  doc.setContent("D00/D00-ST", "final");
  doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
  doc.setContent("D00/D00-MET/D00-MET-NOTE", "A note.");
  std::string item = doc.addListItem("D00/D00-ITM");
  doc.setContent(item + "/D01-LBL", "First item");
  doc.setContent(item + "/D01-BODY", MD_D4RT_BODY);
  std::string item2 = doc.addListItem("D00/D00-ITM");
  doc.setContent(item2 + "/D01-LBL", "Second item");
  return doc;
}

/* mdExport — export the single (first) root of `doc` against the demo model. */
std::string mdExport(const som::SpecModel& model, const som::SpecDocument& doc) {
  return som::markdownExportRoot(model, doc, model.roots[0]);
}

/* mdParse — parse md into a fresh result. */
som::SpecMarkdownResult mdParse(const som::SpecModel& model,
                                const std::string& md) {
  return som::markdownParse(model, md);
}

/* mdReload — parse md and load the staged values into a fresh document. */
som::SpecDocument mdReload(const som::SpecModel& model, const std::string& md,
                           som::SpecMarkdownResult& report) {
  report = mdParse(model, md);
  som::SpecDocument target;
  target.loadJson(report.staged);
  return target;
}

/* ---- export — DocSpecs format (SOM §11) ---------------------------------- */

void testMarkdownExportFormat() {
  auto m = demoModel();
  som::SpecDocument doc = populateDemoDoc();
  std::string md = mdExport(*m, doc);

  std::string first = firstLine(md);
  mdCheck("export.docspec.prefix",
          hasPrefix(first, "<!-- docspec: demo-document/"), first);
  mdCheck("export.docspec.suffix", hasSuffix(first, "-->"), first);

  mdCheck("export.heading.root", contains(md, "# <!--[D00]--> Demo Document"));
  mdCheck("export.heading.overview",
          contains(md, "## <!--[D00-OVR]--> Overview"));
  mdCheck("export.heading.status", contains(md, "## <!--[D00-ST]--> Status"));
  mdCheck("export.heading.header", contains(md, "## <!--[D00-HDR]--> Header"));
  mdCheck("export.heading.meta", contains(md, "## <!--[D00-MET]--> Meta"));
  mdCheck("export.heading.note",
          contains(md, "### <!--[D00-MET-NOTE]--> Note"));

  mdCheck("export.content.plain",
          contains(md, "An overview paragraph.\nWith two lines."));

  bool noFence = true;
  {
    std::size_t p = 0;
    while (p < md.size()) {
      if (md.compare(p, 3, "```") == 0) {
        noFence = false;
        break;
      }
      std::size_t nl = md.find('\n', p);
      if (nl == std::string::npos) {
        break;
      }
      p = nl + 1;
    }
  }
  mdCheck("export.content.noFence", noFence);
  mdCheck("export.content.noFieldAnchor", !contains(md, "<!-- field:"));
  mdCheck("export.content.noPathHeading", !contains(md, "D00/D00-OVR"));

  mdCheck("export.form.sparse.author", contains(md, "Author: Ada Lovelace"));
  mdCheck("export.form.sparse.noReviewer", !contains(md, "Reviewer"));

  mdCheck("export.item.container", contains(md, "## <!--[D00-ITM]--> Items"));
  mdCheck("export.item.1", contains(md, "### <!--[items-1]--> Demo Item 1"));
  mdCheck("export.item.2", contains(md, "### <!--[items-2]--> Demo Item 2"));
  mdCheck("export.item.label", contains(md, "#### <!--[D01-LBL]--> Label"));

  mdCheck("export.noSchemaDescription", !contains(md, "A demo document."));
}

void testMarkdownExportStoredItemId() {
  auto m = demoModel();
  som::SpecDocument doc;
  std::string item =
      doc.addListItemWithSectionId("D00/D00-ITM", "D01-CUSTOM");
  doc.setContent(item + "/D01-LBL", "Custom-id item");

  std::string md = mdExport(*m, doc);
  // YRD3: the STORED id is the item's md heading id; the positional id is only
  // the fallback for an item without one.
  mdCheck("export.storedId.container",
          contains(md, "## <!--[D00-ITM]--> Items"), md);
  mdCheck("export.storedId.heading",
          contains(md, "### <!--[D01-CUSTOM]--> Demo Item 1"), md);
  mdCheck("export.storedId.noPositional", !contains(md, "items-1"), md);
}

void testMarkdownExportUntermFenceErrors() {
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setContent("D00/D00-OVR", "before\n```dart\nnever closed");
  bool raised = false;
  std::string err;
  try {
    std::string out = som::markdownExportRoot(*m, doc, m->roots[0]);
    (void)out;
  } catch (const std::invalid_argument& e) {
    raised = true;
    err = e.what();
  }
  mdCheck("export.untermFence.raises", raised && contains(err, "unterminated"),
          raised ? err : std::string("(no error)"));
}

/* The export error message, or "(no error)" when the export succeeded. */
static std::string mdExportError(const som::SpecModel& m,
                                 const som::SpecDocument& doc) {
  try {
    (void)som::markdownExportRoot(m, doc, m.roots[0]);
    return "(no error)";
  } catch (const std::invalid_argument& e) {
    return e.what();
  }
}

/* SOM §9, "Form-field order": md refuses an undeclared stored field, as yaml
 * does (SOM §12.8). Omitting it would lose a stored value in a file that looks
 * complete — the silent drop the codecs must never do. */
void testMarkdownExportUndeclaredFormFieldErrors() {
  auto m = demoModel();

  som::SpecDocument doc = populateDemoDoc();
  doc.setFormField("D00/D00-HDR", "stale", "x");
  std::string msg = mdExportError(*m, doc);
  mdCheck("export.undeclaredField.raises", contains(msg, "stale"), msg);
  mdCheck("export.undeclaredField.namesPath", contains(msg, "D00/D00-HDR"), msg);

  /* The check has to run even when the form has nothing else, or the whole
   * section is skipped before the check is reached and the drop is silent
   * again. */
  som::SpecDocument only;
  only.setContent("D00/D00-OVR", "An overview paragraph.");
  only.setFormField("D00/D00-HDR", "stale", "x");
  std::string onlyMsg = mdExportError(*m, only);
  mdCheck("export.undeclaredFieldOnly.raises", contains(onlyMsg, "stale"),
          onlyMsg);

  /* Sorted, so the reported name is the same in all nine runtimes. */
  som::SpecDocument two = populateDemoDoc();
  two.setFormField("D00/D00-HDR", "zulu", "z");
  two.setFormField("D00/D00-HDR", "alpha", "a");
  std::string twoMsg = mdExportError(*m, two);
  mdCheck("export.undeclaredField.sortedFirst",
          contains(twoMsg, "alpha") && !contains(twoMsg, "zulu"), twoMsg);
}

/* ---- SpecDocument.ToMarkdown (one-line export, SOM §21) ------------------ */

void testMarkdownToMarkdown() {
  auto m = demoModel();
  som::SpecDocument doc = populateDemoDoc();

  std::string oneLiner = som::documentToMarkdown(doc, *m, "DemoDoc");
  const som::SpecRoot& root = m->rootByType("DemoDoc");
  std::string explicitMd = som::markdownExportRoot(*m, doc, root);
  mdCheck("toMarkdown.explicitRoot", oneLiner == explicitMd);

  std::string def = som::documentToMarkdown(doc, *m, "");
  mdCheck("toMarkdown.defaultRoot", def == oneLiner);

  {
    som::SpecDocument empty;
    bool threw = false;
    std::string emptyErr;
    try {
      std::string emptyMd = som::documentToMarkdown(empty, *m, "");
      (void)emptyMd;
    } catch (const std::runtime_error& e) {
      threw = true;
      emptyErr = e.what();
    }
    mdCheck("toMarkdown.emptyThrows",
            threw && contains(emptyErr, "no populated root"),
            threw ? emptyErr : std::string("(no error)"));
  }

  /* Two-root model: the default is ambiguous and names both candidates. */
  const char* twoJson = R"({
    "roots": [
      {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
      {"type": "Beta",  "title": "Beta Doc",  "sectionId": "B00"}
    ],
    "classes": {
      "Alpha": {"name": "Alpha", "sectionId": "A00",
        "fields": [{"name": "overview", "kind": "content", "sectionId": "A00-OVR"}]},
      "Beta": {"name": "Beta", "sectionId": "B00",
        "fields": [{"name": "overview", "kind": "content", "sectionId": "B00-OVR"}]}
    }
  })";
  std::string twoErr;
  auto twoModel = som::SpecModel::fromJsonStr(twoJson, &twoErr);
  if (twoModel == nullptr) {
    fatal("SpecModelFromJSON (two roots)");
  }
  som::SpecDocument doc2;
  doc2.setContent("A00/A00-OVR", "a");
  doc2.setContent("B00/B00-OVR", "b");
  bool threw2 = false;
  std::string twoMdErr;
  try {
    std::string twoMd = som::documentToMarkdown(doc2, *twoModel, "");
    (void)twoMd;
  } catch (const std::runtime_error& e) {
    threw2 = true;
    twoMdErr = e.what();
  }
  mdCheck("toMarkdown.twoRootsThrows.alpha",
          threw2 && contains(twoMdErr, "Alpha"),
          threw2 ? twoMdErr : std::string("(no error)"));
  mdCheck("toMarkdown.twoRootsThrows.beta", threw2 && contains(twoMdErr, "Beta"),
          threw2 ? twoMdErr : std::string("(no error)"));
}

/* ---- round-trip ---------------------------------------------------------- */

void testMarkdownRoundTripValues() {
  auto m = demoModel();
  som::SpecDocument src = populateDemoDoc();
  std::string md = mdExport(*m, src);

  som::SpecMarkdownResult report;
  som::SpecDocument target = mdReload(*m, md, report);

  mdCheck("roundTrip.clean", report.isClean(), mdRejStr(report));
  mdCheck("roundTrip.overview",
          contentOr(target, "D00/D00-OVR") ==
              "An overview paragraph.\nWith two lines.");
  mdCheck("roundTrip.status", contentOr(target, "D00/D00-ST") == "final");
  mdCheck("roundTrip.author",
          formFieldOr(target, "D00/D00-HDR", "author") == "Ada Lovelace");
  mdCheck("roundTrip.note",
          contentOr(target, "D00/D00-MET/D00-MET-NOTE") == "A note.");

  std::vector<std::string> items = target.listItems("D00/D00-ITM");
  mdCheck("roundTrip.itemCount", items.size() == 2);
  if (items.size() == 2) {
    mdCheck("roundTrip.item1.label",
            contentOr(target, items[0] + "/D01-LBL") == "First item");
    mdCheck("roundTrip.item1.body",
            contentOr(target, items[0] + "/D01-BODY") == MD_D4RT_BODY,
            contentOr(target, items[0] + "/D01-BODY"));
    mdCheck("roundTrip.item2.label",
            contentOr(target, items[1] + "/D01-LBL") == "Second item");
  }
}

void testMarkdownRoundTripByteStable() {
  auto m = demoModel();
  som::SpecDocument src = populateDemoDoc();
  std::string md1 = mdExport(*m, src);

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  std::string md2 = mdExport(*m, reloaded);
  mdCheck("roundTrip.byteStable", md2 == md1);
}

void testMarkdownRoundTripRichMarkdown() {
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setContent("D00/D00-OVR", MD_RICH_MARKDOWN);
  std::string md1 = mdExport(*m, doc);

  mdCheck("richMd.fenceShielded",
          contains(md1, "\n# not a heading — shielded by the fence\n"));
  mdCheck("richMd.escapedHeading",
          contains(md1, "\n\\# looks like a heading at column 0\n"));

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  mdCheck("richMd.clean", report.isClean(), mdRejStr(report));
  mdCheck("richMd.value", contentOr(reloaded, "D00/D00-OVR") == MD_RICH_MARKDOWN,
          contentOr(reloaded, "D00/D00-OVR"));
  std::string md2 = mdExport(*m, reloaded);
  mdCheck("richMd.byteStable", md2 == md1);
}

void testMarkdownRoundTripStoredItemId() {
  auto m = demoModel();
  som::SpecDocument doc;
  std::string item =
      doc.addListItemWithSectionId("D00/D00-ITM", "D01-CUSTOM");
  doc.setContent(item + "/D01-LBL", "Custom-id item");
  std::string md1 = mdExport(*m, doc);
  // YRD3: the stored id IS the md heading id and round-trips.
  mdCheck("storedId.inMd", contains(md1, "<!--[D01-CUSTOM]-->"), md1);

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  mdCheck("storedId.clean", report.isClean(), mdRejStr(report));

  std::vector<std::string> items = reloaded.listItems("D00/D00-ITM");
  mdCheck("storedId.itemCount", items.size() == 1);
  if (items.size() == 1) {
    mdCheck("storedId.sectionId",
            itemSectionIdOr(reloaded, items[0]) == "D01-CUSTOM",
            itemSectionIdOr(reloaded, items[0]));
    mdCheck("storedId.label",
            contentOr(reloaded, items[0] + "/D01-LBL") == "Custom-id item");
  }
  std::string md2 = mdExport(*m, reloaded);
  mdCheck("storedId.byteStable", md2 == md1);
}

void testMarkdownRoundTripLabelShapedContinuation() {
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setFormField("D00/D00-HDR", "author",
                   "Ada Lovelace\nNote: also a mathematician\nplain line");
  std::string md1 = mdExport(*m, doc);

  mdCheck("formCont.escaped",
          contains(md1, "\n Note: also a mathematician\n"), md1);

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  mdCheck("formCont.clean", report.isClean(), mdRejStr(report));
  mdCheck("formCont.value",
          formFieldOr(reloaded, "D00/D00-HDR", "author") ==
              "Ada Lovelace\nNote: also a mathematician\nplain line",
          formFieldOr(reloaded, "D00/D00-HDR", "author"));
  std::string md2 = mdExport(*m, reloaded);
  mdCheck("formCont.byteStable", md2 == md1);
}

/* ---- a form section's preamble (SOM §11.4 rule 7) ------------------------ */

void testMarkdownFormPreambleParses() {
  auto m = demoModel();
  std::string md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-HDR]--> Header\n\n"
      "prose before any field label\n"
      "Author: Ada Lovelace\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("formPre.clean", report.isClean(), mdRejStr(report));
  const std::string* pre = stagedContent(report, "D00/D00-HDR");
  mdCheck("formPre.content",
          pre != nullptr && *pre == "prose before any field label",
          pre != nullptr ? *pre : std::string("(absent)"));
  mdCheck("formPre.fieldParsed",
          formMatchesSingle(report, "D00/D00-HDR", "author", "Ada Lovelace"));
}

void testMarkdownFormPreambleEmits() {
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setContent("D00/D00-HDR", "why this header exists");
  doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
  std::string md = mdExport(*m, doc);
  mdCheck("formPre.emitOrder",
          contains(md, "why this header exists\n\nAuthor: Ada Lovelace\n"), md);
}

void testMarkdownFormPreambleOnly() {
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setContent("D00/D00-HDR", "nothing filled in yet");
  std::string md1 = mdExport(*m, doc);
  mdCheck("formPreOnly.heading", contains(md1, "<!--[D00-HDR]-->"), md1);
  mdCheck("formPreOnly.emitted", contains(md1, "nothing filled in yet"), md1);

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  mdCheck("formPreOnly.clean", report.isClean(), mdRejStr(report));
  mdCheck("formPreOnly.value",
          contentOr(reloaded, "D00/D00-HDR") == "nothing filled in yet",
          contentOr(reloaded, "D00/D00-HDR"));
  mdCheck("formPreOnly.byteStable", mdExport(*m, reloaded) == md1,
          mdExport(*m, reloaded));
}

void testMarkdownFormPreambleRoundTrip() {
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setContent("D00/D00-HDR", "first paragraph\n\nsecond paragraph");
  doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
  std::string md1 = mdExport(*m, doc);

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  mdCheck("formPreRT.clean", report.isClean(), mdRejStr(report));
  mdCheck("formPreRT.content",
          contentOr(reloaded, "D00/D00-HDR") ==
              "first paragraph\n\nsecond paragraph",
          contentOr(reloaded, "D00/D00-HDR"));
  mdCheck("formPreRT.field",
          formFieldOr(reloaded, "D00/D00-HDR", "author") == "Ada Lovelace",
          formFieldOr(reloaded, "D00/D00-HDR", "author"));
  mdCheck("formPreRT.byteStable", mdExport(*m, reloaded) == md1,
          mdExport(*m, reloaded));
}

void testMarkdownFormPreambleLabelShaped() {
  // Without the escape the parser would read `Author: ...` as the first field
  // label and the line would leave the preamble.
  auto m = demoModel();
  som::SpecDocument doc;
  doc.setContent("D00/D00-HDR", "Author: is a field of this form");
  doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
  std::string md1 = mdExport(*m, doc);
  mdCheck("formPreLbl.escaped",
          contains(md1, "\n Author: is a field of this form\n"), md1);

  som::SpecMarkdownResult report;
  som::SpecDocument reloaded = mdReload(*m, md1, report);
  mdCheck("formPreLbl.clean", report.isClean(), mdRejStr(report));
  mdCheck("formPreLbl.content",
          contentOr(reloaded, "D00/D00-HDR") ==
              "Author: is a field of this form",
          contentOr(reloaded, "D00/D00-HDR"));
  mdCheck("formPreLbl.field",
          formFieldOr(reloaded, "D00/D00-HDR", "author") == "Ada Lovelace",
          formFieldOr(reloaded, "D00/D00-HDR", "author"));
  mdCheck("formPreLbl.byteStable", mdExport(*m, reloaded) == md1,
          mdExport(*m, reloaded));
}

/* ---- parse-rejection protocol (SOM §11.7) -------------------------------- */

/* Reports whether any rejection matches (reason [+ anchor when non-null]). */
bool hasRejection(const som::SpecMarkdownResult& r, const std::string& reason,
                  const char* anchor) {
  for (const auto& rej : r.rejections) {
    if (rej.reason != reason) {
      continue;
    }
    if (anchor != nullptr && rej.anchor != anchor) {
      continue;
    }
    return true;
  }
  return false;
}

void testMarkdownRejectUnknownSection() {
  auto m = demoModel();
  std::string md =
      "<!-- docspec: demo-document/1.0 -->\n"
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "kept\n\n"
      "## <!--[D00-MET]--> Meta\n\n"
      "### <!--[D00-NOPE]--> Bogus\n\n"
      "dropped\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("reject.unknown.dirty", !report.isClean());
  mdCheck("reject.unknown.reason",
          hasRejection(report, som::kSpecMarkdownRejectUnknownSection,
                       "D00-NOPE"),
          mdRejStr(report));
  const std::string* kept = stagedContent(report, "D00/D00-OVR");
  mdCheck("reject.unknown.siblingsKept", kept != nullptr && *kept == "kept");
}

void testMarkdownRejectMalformedHeading() {
  auto m = demoModel();
  std::string md =
      "<!-- docspec: demo-document/1.0 -->\n"
      "# <!--[D00]--> Demo Document\n\n"
      "## Overview without an id comment\n\n"
      "lost\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("reject.malformed.reason",
          hasRejection(report, som::kSpecMarkdownRejectMalformedHeading,
                       nullptr),
          mdRejStr(report));
  mdCheck("reject.malformed.noContent", stagedContentLen(report) == 0);
}

void testMarkdownRejectOrphanPreamble() {
  auto m = demoModel();
  std::string md =
      "stray preamble text\n"
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "kept\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("reject.orphanPreamble.reason",
          hasRejection(report, som::kSpecMarkdownRejectOrphanContent, nullptr),
          mdRejStr(report));
  const std::string* kept = stagedContent(report, "D00/D00-OVR");
  mdCheck("reject.orphanPreamble.kept", kept != nullptr && *kept == "kept");
}

void testMarkdownRejectKindMismatch() {
  auto m = demoModel();
  std::string md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "kept\n\n"
      "### <!--[D00-MET-NOTE]--> Note\n\n"
      "misplaced\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("reject.kindMismatch.reason",
          hasRejection(report, som::kSpecMarkdownRejectKindMismatch, nullptr),
          mdRejStr(report));
  const std::string* kept = stagedContent(report, "D00/D00-OVR");
  mdCheck("reject.kindMismatch.kept", kept != nullptr && *kept == "kept");
}

void testMarkdownRejectMissingValue() {
  auto m = demoModel();
  std::string md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "## <!--[D00-ST]--> Status\n\n"
      "final\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("reject.missingValue.reason",
          hasRejection(report, som::kSpecMarkdownRejectMissingValue,
                       "D00/D00-OVR"),
          mdRejStr(report));
  const std::string* st = stagedContent(report, "D00/D00-ST");
  mdCheck("reject.missingValue.statusKept", st != nullptr && *st == "final");
}

void testMarkdownCaseInsensitiveLabels() {
  auto m = demoModel();
  std::string md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-HDR]--> Header\n\n"
      "author: lower-case label\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("labels.caseInsensitive.clean", report.isClean(), mdRejStr(report));
  mdCheck("labels.caseInsensitive.value",
          formMatchesSingle(report, "D00/D00-HDR", "author",
                            "lower-case label"));
}

void testMarkdownFenceShieldedHeadingsStayBody() {
  auto m = demoModel();
  std::string md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "```\n"
      "## <!--[D00-ST]--> not a real heading\n"
      "```\n";
  som::SpecMarkdownResult report = mdParse(*m, md);

  mdCheck("fenceShield.clean", report.isClean(), mdRejStr(report));
  const std::string* body = stagedContent(report, "D00/D00-OVR");
  mdCheck("fenceShield.body",
          body != nullptr &&
              *body == "```\n## <!--[D00-ST]--> not a real heading\n```",
          body != nullptr ? *body : std::string("(absent)"));
  mdCheck("fenceShield.noStatus",
          stagedContent(report, "D00/D00-ST") == nullptr);
}

/* ---- codespecs_mapping.md §9.2 codeSpec forward-link (mirror of stored headline) -------------- */

/* The stored codeSpec of a section rides inside its heading comment as a
 * `codeSpec="…"` key, and untouched sections stay byte-stable. */
void testMarkdownCodeSpecRidesInHeadlineComment() {
  auto m = demoModel();
  som::SpecDocument doc = populateDemoDoc();
  doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository");
  std::string md = mdExport(*m, doc);
  mdCheck("codeSpec.md.attribute",
          contains(md,
                   "## <!--[D00-OVR] codeSpec=\"CsOrder,CsOrder.total,"
                   "CsOrderRepository\"--> Overview"),
          md);
  // Untouched sections stay byte-stable (no empty codeSpec attribute).
  mdCheck("codeSpec.md.untouched", contains(md, "## <!--[D00-ST]--> Status"));
}

/* The codeSpec parses back out of the heading comment into the staged map. */
void testMarkdownCodeSpecParsedBackOut() {
  auto m = demoModel();
  som::SpecDocument doc = populateDemoDoc();
  doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total");
  std::string md = mdExport(*m, doc);
  som::SpecMarkdownResult report = mdParse(*m, md);
  auto it = report.staged.codeSpecs.find("D00/D00-OVR");
  mdCheck("codeSpec.md.parsed",
          it != report.staged.codeSpecs.end() &&
              it->second == "CsOrder,CsOrder.total",
          it != report.staged.codeSpecs.end() ? it->second
                                              : std::string("(absent)"));
}

/* A headline + codeSpec together round-trip byte-stably through export/parse. */
void testMarkdownCodeSpecAndHeadlineRoundTripByteStable() {
  auto m = demoModel();
  som::SpecDocument doc = populateDemoDoc();
  doc.setHeadline("D00/D00-OVR", "Custom Overview");
  doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository");
  std::string md = mdExport(*m, doc);
  som::SpecMarkdownResult report;
  som::SpecDocument target = mdReload(*m, md, report);
  mdCheck("codeSpec.md.byteStable", mdExport(*m, target) == md,
          mdExport(*m, target));
  mdCheck("codeSpec.md.stored",
          target.codeSpec("D00/D00-OVR") ==
              "CsOrder,CsOrder.total,CsOrderRepository",
          target.codeSpec("D00/D00-OVR"));
}

}  // namespace

int main() {
  testMarkdownExportFormat();
  testMarkdownExportStoredItemId();
  testMarkdownExportUntermFenceErrors();
  testMarkdownExportUndeclaredFormFieldErrors();
  testMarkdownToMarkdown();
  testMarkdownRoundTripValues();
  testMarkdownRoundTripByteStable();
  testMarkdownRoundTripRichMarkdown();
  testMarkdownRoundTripStoredItemId();
  testMarkdownRoundTripLabelShapedContinuation();
  testMarkdownFormPreambleParses();
  testMarkdownFormPreambleEmits();
  testMarkdownFormPreambleOnly();
  testMarkdownFormPreambleRoundTrip();
  testMarkdownFormPreambleLabelShaped();
  testMarkdownRejectUnknownSection();
  testMarkdownRejectMalformedHeading();
  testMarkdownRejectOrphanPreamble();
  testMarkdownRejectKindMismatch();
  testMarkdownRejectMissingValue();
  testMarkdownCaseInsensitiveLabels();
  testMarkdownFenceShieldedHeadingsStayBody();
  testMarkdownCodeSpecRidesInHeadlineComment();
  testMarkdownCodeSpecParsedBackOut();
  testMarkdownCodeSpecAndHeadlineRoundTripByteStable();

  if (g_failures == 0) {
    std::printf("spec_document_markdown: all %d checks passed\n", g_checks);
    return 0;
  }
  std::fprintf(stderr, "spec_document_markdown: %d/%d check(s) failed\n",
               g_failures, g_checks);
  return 1;
}
