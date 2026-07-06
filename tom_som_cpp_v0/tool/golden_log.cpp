// Cross-language golden-log generator for C++ (roadmap item 7b).
//
// Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Build & run (from the project root): see run_tests.sh / examples/README.md.
//   g++ -std=c++17 -Iinclude -I../tom_som_cpp_runtime/include tool/golden_log.cpp
//     build/libtom_som_cpp_v0.a ../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a
//     -o build/golden_log
//   ./build/golden_log [samplePath] [outputPath]
#include "tom_som_cpp_v0.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

// Escapes a value so it occupies exactly one log line: backslash first (so the
// other escapes are unambiguous), then the three whitespace controls.
static std::string esc(const std::string& s) {
  std::string out;
  out.reserve(s.size());
  for (const char c : s) {
    switch (c) {
      case '\\': out += "\\\\"; break;
      case '\n': out += "\\n"; break;
      case '\r': out += "\\r"; break;
      case '\t': out += "\\t"; break;
      default: out += c; break;
    }
  }
  return out;
}

[[noreturn]] static void die(const std::string& msg) {
  std::cerr << msg << "\n";
  std::exit(2);
}

int main(int argc, char** argv) {
  const std::string sample =
      argc > 1 ? argv[1]
               : "../tom_som_conformance/samples/"
                 "meridian_order_management.docspecs.yaml";
  const std::string output =
      argc > 2 ? argv[2] : "../tom_som_conformance/golden/cpp.log";

  // Generic view.
  som::SpecDocument doc = som::SpecDocument::fromFile(sample);
  // Typed view — the facade borrows a separate caller-owned document loaded from
  // the same file, so its reads must agree with the generic `doc` byte-for-byte.
  som::SpecDocument typedDoc;
  tom_som_v0::D00SolutionBlueprint sbp =
      tom_som_v0::D00SolutionBlueprint::loadFile(typedDoc, sample);

  std::vector<std::string> out;
  out.push_back("# TomSpecs SOM golden log — canonical cross-language reading.");
  out.push_back(
      "# All nine per-language generators must emit byte-identical output.");
  out.push_back("FORMAT\t1");
  out.push_back("MODELVERSION\t" + esc(doc.modelVersion));

  // --- Generic: every content leaf, sorted by path. ---
  out.push_back("SECTION\tgeneric-content");
  {
    std::vector<std::string> paths = doc.contentPaths();  // byte-sorted by runtime
    for (const std::string& p : paths) {
      out.push_back("C\t" + p + "\t" + esc(doc.content(p)));
    }
  }

  // --- Generic: every form section + field, sorted by path then field. ---
  out.push_back("SECTION\tgeneric-forms");
  {
    std::vector<std::string> paths = doc.formPaths();
    for (const std::string& p : paths) {
      std::vector<std::string> fields = doc.formFieldNames(p);
      for (const std::string& f : fields) {
        out.push_back("F\t" + p + "\t" + f + "\t" + esc(doc.formField(p, f)));
      }
    }
  }

  // --- Generic: every list container + its item paths (document order). ---
  out.push_back("SECTION\tgeneric-lists");
  {
    std::vector<std::string> paths = doc.listPaths();
    for (const std::string& p : paths) {
      std::vector<std::string> items = doc.listItems(p);
      out.push_back("L\t" + p + "\t" + std::to_string(items.size()));
      for (const std::string& item : items) {
        out.push_back("I\t" + item);
      }
    }
  }

  // --- Typed: a curated traversal of the facade that must agree with the
  // generic reads. ---
  out.push_back("SECTION\ttyped");

  auto typedContent = [&](const std::string& path, const std::string& value) {
    const std::string leaf = path + "/content";
    const std::string generic = doc.content(leaf);
    if (value != generic) {
      die("TYPED MISMATCH at " + leaf + ": typed=\"" + value + "\" generic=\"" +
          generic + "\"");
    }
    out.push_back("T\t" + leaf + "\t" + esc(value));
  };

  typedContent(sbp.path(), sbp.content());
  { auto s = sbp.documentControl(); typedContent(s.path(), s.content()); }
  { auto s = sbp.introductionAndScope(); typedContent(s.path(), s.content()); }
  { auto s = sbp.glossaryAndAbbreviations(); typedContent(s.path(), s.content()); }
  { auto s = sbp.stakeholdersAndGovernance(); typedContent(s.path(), s.content()); }
  { auto s = sbp.currentLandscape(); typedContent(s.path(), s.content()); }
  { auto s = sbp.assumptionsConstraintsDependencies(); typedContent(s.path(), s.content()); }
  { auto s = sbp.targetOperatingModelConcept(); typedContent(s.path(), s.content()); }
  { auto s = sbp.informationAndDataModel(); typedContent(s.path(), s.content()); }
  { auto s = sbp.requirements(); typedContent(s.path(), s.content()); }
  { auto s = sbp.solutionArchitectureAndTechnology(); typedContent(s.path(), s.content()); }
  { auto s = sbp.securityAndAccessModel(); typedContent(s.path(), s.content()); }
  { auto s = sbp.experienceAndInterfaceDesign(); typedContent(s.path(), s.content()); }
  { auto s = sbp.qualityAndAcceptanceModel(); typedContent(s.path(), s.content()); }
  { auto s = sbp.deliveryTransitionAndRollout(); typedContent(s.path(), s.content()); }

  // Nested section reached through two typed hops.
  {
    auto intro = sbp.introductionAndScope();
    auto goals = intro.goals();
    typedContent(goals.path(), goals.content());
  }

  // A typed list traversal: length + each element's content, each asserted
  // against the generic list-item read.
  {
    auto cl = sbp.currentLandscape();
    som::SomList metrics = cl.operationalMetrics();
    const std::vector<std::string> metricItems = doc.listItems(metrics.path());
    if (metrics.length() != metricItems.size()) {
      die("TYPED LIST LENGTH MISMATCH at " + metrics.path());
    }
    out.push_back("TL\t" + metrics.path() + "\t" +
                  std::to_string(metrics.length()));
    for (std::size_t i = 0; i < metrics.length(); i++) {
      tom_som_v0::CurrentOperationalMetric elem(typedDoc, metrics.itemPathAt(i));
      const std::string leaf = elem.path() + "/content";
      const std::string generic = doc.content(leaf);
      if (elem.content() != generic) {
        die("TYPED LIST ITEM MISMATCH at " + leaf);
      }
      out.push_back("TI\t" + leaf + "\t" + esc(elem.content()));
    }
  }

  // Join with LF and terminate with a single trailing LF — fixed regardless of
  // host platform so the bytes match on every machine.
  std::string body;
  for (std::size_t i = 0; i < out.size(); i++) {
    if (i != 0) body += '\n';
    body += out[i];
  }
  body += '\n';

  std::ofstream fp(output, std::ios::binary);
  if (!fp) die("write failed");
  fp.write(body.data(), static_cast<std::streamsize>(body.size()));
  fp.close();
  std::cout << "wrote " << out.size() << " lines to " << output << "\n";
  return 0;
}
