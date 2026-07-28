/* Tests for the SOM §21 one-line export, mirroring the Dart reference groups:
 *   - SpecModel::rootByType  (spec_model_test.dart / 'SpecModel.rootByType')
 *   - SpecDocument::toMarkdown (spec_document_markdown_test.dart / 'toMarkdown')
 *
 * The full generated model is not regenerated here; the two class graphs are
 * hand-built from JSON strings via SpecModel::fromJsonStr, exactly as the Dart
 * tests build them from map literals.
 */
#include <cstdio>
#include <stdexcept>
#include <string>

#include "spec_document.hpp"
#include "spec_document_markdown.hpp"
#include "spec_model.hpp"

namespace {

std::size_t g_passed = 0;
std::size_t g_failed = 0;

void check(const char* name, bool cond) {
  if (cond) {
    g_passed++;
  } else {
    g_failed++;
    std::printf("  FAIL: %s\n", name);
  }
}

std::unique_ptr<som::SpecModel> parseModel(const std::string& json) {
  std::string err;
  auto m = som::SpecModel::fromJsonStr(json, &err);
  if (m == nullptr) {
    std::printf("  model parse error: %s\n", err.c_str());
  }
  return m;
}

// Two-root model with no populated content, for rootByType.
const char* kTwoRootJson = R"({
  "roots": [
    {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
    {"type": "Beta",  "title": "Beta Doc",  "sectionId": "B00"}
  ],
  "classes": {}
})";

// Single-root DemoDoc model with a content field, for toMarkdown defaults.
const char* kDemoJson = R"({
  "roots": [
    {"type": "DemoDoc", "title": "Demo Document", "sectionId": "D00",
     "description": "A demo document."}
  ],
  "classes": {
    "DemoDoc": {
      "name": "DemoDoc", "sectionId": "D00",
      "fields": [
        {"name": "overview", "kind": "content", "sectionId": "D00-OVR"}
      ]
    }
  }
})";

// Two populated roots, for the ambiguous-default case.
const char* kTwoPopulatedJson = R"({
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

bool contains(const std::string& hay, const std::string& needle) {
  return hay.find(needle) != std::string::npos;
}

}  // namespace

int main() {
  // ---- SpecModel::rootByType (one-line export, SOM §21) ----
  {
    auto model = parseModel(kTwoRootJson);
    check("rootByType returns the root whose type matches (Alpha)",
          model != nullptr && model->rootByType("Alpha").title == "Alpha Doc");
    check("rootByType returns the root whose type matches (Beta sectionId)",
          model != nullptr && model->rootByType("Beta").sectionId == "B00");

    bool threw = false;
    std::string msg;
    try {
      model->rootByType("Gamma");
    } catch (const std::invalid_argument& e) {
      threw = true;
      msg = e.what();
    }
    check("rootByType throws std::invalid_argument for a missing type", threw);
    check("rootByType message names the requested type", contains(msg, "Gamma"));
    check("rootByType message lists available type Alpha", contains(msg, "Alpha"));
    check("rootByType message lists available type Beta", contains(msg, "Beta"));
  }

  // ---- SpecDocument::toMarkdown (one-line export, SOM §21) ----
  auto demo = parseModel(kDemoJson);

  // matches the explicit codec output for an explicit rootType.
  {
    som::SpecDocument doc;
    doc.setContent("D00/D00-OVR", "An overview paragraph.\nWith two lines.");
    std::string oneLiner = doc.toMarkdown(*demo, "DemoDoc");
    std::string explicitOut =
        som::markdownExportRoot(*demo, doc, demo->rootByType("DemoDoc"));
    check("toMarkdown(rootType) matches explicit markdownExportRoot",
          oneLiner == explicitOut);
  }

  // defaults to the single populated root when rootType is omitted.
  {
    som::SpecDocument doc;
    doc.setContent("D00/D00-OVR", "An overview paragraph.");
    check("toMarkdown() default equals toMarkdown(rootType) for one populated root",
          doc.toMarkdown(*demo) == doc.toMarkdown(*demo, "DemoDoc"));
  }

  // throws when no root is populated.
  {
    som::SpecDocument empty;
    bool threw = false;
    std::string msg;
    try {
      empty.toMarkdown(*demo);
    } catch (const std::runtime_error& e) {
      threw = true;
      msg = e.what();
    }
    check("toMarkdown() throws std::runtime_error when no root is populated",
          threw);
    check("toMarkdown() message mentions 'no populated root'",
          contains(msg, "no populated root"));
  }

  // throws naming the candidates when more than one root is populated.
  {
    auto twoPop = parseModel(kTwoPopulatedJson);
    som::SpecDocument doc;
    doc.setContent("A00/A00-OVR", "a");
    doc.setContent("B00/B00-OVR", "b");
    bool threw = false;
    std::string msg;
    try {
      doc.toMarkdown(*twoPop);
    } catch (const std::runtime_error& e) {
      threw = true;
      msg = e.what();
    }
    check("toMarkdown() throws when more than one root is populated", threw);
    check("toMarkdown() ambiguous message names Alpha", contains(msg, "Alpha"));
    check("toMarkdown() ambiguous message names Beta", contains(msg, "Beta"));
  }

  if (g_failed == 0) {
    std::printf("one_line_export_test: all %zu checks passed\n", g_passed);
    return 0;
  }
  std::printf("one_line_export_test: %zu passed, %zu FAILED\n", g_passed,
              g_failed);
  return 1;
}
