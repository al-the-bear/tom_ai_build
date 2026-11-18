// TomSpecs sample — author a Solution Blueprint end to end (C++).
//
// The C++ port of `../bin/author_solution_blueprint.dart`: the same six steps,
// the same document, the same output (`../expected_output.txt`).
//
// Build and run (from this folder; see README.md):  make && ./build/sample
//
// Six steps, in the order a real authoring task takes them:
//
//   1. open a fresh document and a typed root
//   2. author a small but coherent Solution Blueprint
//   3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
//   4. round-trip the yaml back through the one-call typed loader and prove
//      the reload is equal to what was written
//   5. validate on the instance tier
//   6. break one rule deliberately and read the diagnostic
//
// MEMORY OWNERSHIP is RAII throughout: values are returned by value
// (`std::string`, `std::vector`, `std::optional`) and the model comes back as a
// `std::unique_ptr`. The one rule to keep is the facade's: a typed root or
// section BORROWS the `som::SpecDocument` it was built over (and `loadFile`
// fills a caller-owned document), so the document must outlive every facade
// bound to it. The sample runs clean under AddressSanitizer and a leak checker
// (`tool/validate.sh`).
#include "tom_som_cpp_v0.hpp"
#include "tom_som_cpp_v0_meta.hpp"

#include <sys/stat.h>

#include <cstdio>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>

#ifndef TOMSPECS_CHECKOUT
#define TOMSPECS_CHECKOUT "../../.."
#endif

namespace {

// Prints the section id a write landed under. The ids are the document's
// addressing system — the same tokens appear in the yaml keys and in the
// markdown `<!--[ID]-->` comments — so the sample shows them rather than
// describing them.
void wrote(const std::string& path, const std::string& what) {
  std::printf("   %-46s %s\n", path.c_str(), what.c_str());
}

int lines(const std::string& s) {
  std::size_t end = s.find_last_not_of(" \t\r\n");
  if (end == std::string::npos) return 1;
  int n = 1;
  for (std::size_t i = 0; i <= end; i++) {
    if (s[i] == '\n') n++;
  }
  return n;
}

std::string readFile(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  if (!in) throw std::runtime_error("cannot read " + path);
  std::stringstream text;
  text << in.rdbuf();
  return text.str();
}

void writeFile(const std::string& path, const std::string& text) {
  std::ofstream(path, std::ios::binary) << text;
}

// The whole model the facade project ships, read from the checkout:
// `tom_som_cpp_v0/meta/spec_model.meta.json`.
std::unique_ptr<som::SpecModel> loadModel() {
  std::string err;
  auto model = som::SpecModel::fromJsonStr(
      readFile(TOMSPECS_CHECKOUT "/tom_som_cpp_v0/meta/spec_model.meta.json"), &err);
  if (!model) throw std::runtime_error("model: " + err);
  return model;
}

}  // namespace

int main() {
  mkdir("build", 0755);

  // -------------------------------------------------------------- step 1
  // A typed root over a fresh, empty document. Constructing the root also
  // runs the instantiation-time model-version check (SOM §4.2): an unstamped
  // document is editable, a document from a newer model is refused.
  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint sbp(doc);

  std::cout << "1. A typed root over an empty document\n";
  std::cout << "   object model version : " << sbp.objectModelVersion() << "\n";
  std::cout << "   root path            : " << sbp.path() << "\n\n";

  // -------------------------------------------------------------- step 2
  // Author. Every write below goes through a NAMED accessor — no string
  // paths — and lands in the same path-keyed store the generic API reads.
  std::cout << "2. Authoring, printing each section id as it is written\n";

  sbp.setContent("Unify three legacy order systems behind one customer record.");
  wrote(sbp.path(), "the blueprint itself");

  tom_som_v0::IntroductionAndScope intro = sbp.introductionAndScope();
  intro.setContent("Replace per-region order intake with a single pipeline.");
  wrote(intro.path(), "introduction and scope");

  tom_som_v0::CurrentLandscape landscape = sbp.currentLandscape();
  landscape.setContent("Three systems, no shared customer record, manual reconciliation.");
  wrote(landscape.path(), "the current landscape");

  // A list section. `add()` appends an item and returns its path; the typed
  // item is a view bound to that path.
  som::SomList metrics = landscape.operationalMetrics();
  tom_som_v0::CurrentOperationalMetric(doc, metrics.add())
      .setContent("Average order turnaround: 4.2 days.");
  tom_som_v0::CurrentOperationalMetric(doc, metrics.add())
      .setContent("Manual reconciliation: about 12 hours a week.");
  wrote(metrics.path(), std::to_string(metrics.length()) + " operational metrics");
  std::cout << "\n";

  // -------------------------------------------------------------- step 3
  // Both renditions of the same document. They are two encodings of one
  // store, not two documents — which is why step 4 can round-trip either.
  //
  // `toMarkdown` and the validator both need a whole SpecModel: the facade
  // project ships it as `meta/spec_model.meta.json`.
  std::unique_ptr<som::SpecModel> model = loadModel();
  const som::SomMetaTree& tree = tom_som_v0_meta::d00SolutionBlueprintMetaTree();

  std::string err;
  const std::string yaml = som::encodeYaml(doc, tree, model->modelVersionString(), &err).value();
  const std::string markdown = doc.toMarkdown(*model, "D00SolutionBlueprint");

  writeFile("build/blueprint.docspecs.yaml", yaml);
  writeFile("build/blueprint.md", markdown);

  std::cout << "3. Serialised both renditions into build/\n";
  std::cout << "   blueprint.docspecs.yaml : " << lines(yaml) << " lines  (SOM §12)\n";
  std::cout << "   blueprint.md            : " << lines(markdown) << " lines  (SOM §11)\n\n";

  // -------------------------------------------------------------- step 4
  // The one-call typed loader: decode, apply the document's own authoring
  // stamp, and hand back a typed root. Re-encoding the reload and comparing
  // the two strings is the actual proof — comparing field by field would only
  // prove the fields somebody thought to compare. The loaded document is ours;
  // the root borrows it.
  som::SpecDocument reloadedDoc;
  tom_som_v0::D00SolutionBlueprint reloaded =
      tom_som_v0::D00SolutionBlueprint::loadFile(reloadedDoc, "build/blueprint.docspecs.yaml");
  const std::string reYaml = som::encodeYaml(reloadedDoc, tree, model->modelVersionString(), &err).value();

  som::SomList reMetrics = reloaded.currentLandscape().operationalMetrics();
  tom_som_v0::CurrentOperationalMetric first(reloadedDoc, reMetrics.itemPathAt(0));

  std::cout << "4. Round-tripped the yaml through D00SolutionBlueprint.loadFile\n";
  std::cout << "   reload equals original  : " << (reYaml == yaml ? "true" : "false") << "\n";
  std::cout << "   a value read back typed : \"" << first.content() << "\"\n\n";

  // -------------------------------------------------------------- step 5
  const auto errors = som::validateDocument(*model, doc);
  std::cout << "5. Instance-tier validation\n";
  std::cout << "   violations              : " << errors.size() << "\n\n";

  // -------------------------------------------------------------- step 6
  // What a violation looks like. Writing to a path the model does not declare
  // is the clearest break to stage: the store accepts it — it is a plain
  // path-keyed map — and the validator is what notices.
  som::SpecDocument broken = som::SpecDocument::fromYaml(yaml, tree, &err).value();
  broken.setContent("SBP/noSuchSection/content", "not part of the model");

  const auto brokenErrors = som::validateDocument(*model, broken);
  std::cout << "6. The same document with one rule deliberately broken\n";
  std::cout << "   violations              : " << brokenErrors.size() << "\n";
  for (const auto& e : brokenErrors) {
    std::cout << "   " << e.code << ": " << e.path << "\n";
    std::cout << "     " << e.message << "\n";
  }
  std::cout << "\n";
  std::cout << "Done. The two renditions are in build/.\n";
  return 0;
}
