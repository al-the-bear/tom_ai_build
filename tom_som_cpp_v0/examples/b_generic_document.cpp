// Sample (b) — GENERIC in-memory document access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the header/source pair (include/, src/), meta/, schemas/ and the
// Makefile).
//
// Demonstrates editing the *same* document shape as sample (a) using ONLY the
// generic `tom_som_cpp_runtime` — string paths, no generated typed classes.
// This is the language-independent core: a sparse, path-keyed store plus the
// list and serialization helpers. Anything the typed facade can express is
// expressible here; the typed facade just makes it type-safe and discoverable.
//
// Build & run from the project root:  ./run_tests.sh   (builds + runs all three)
// or compile directly (see examples/README.md).
//
// Ownership (RAII): every value is owned and returned by value (std::string,
// DocumentJson) — nothing to free by hand.
#include "tom_som_cpp_runtime.hpp"
// The generated metadata module: encodeYaml walks the document root's metadata
// tree (DR33). The generic store is edited with raw paths above; only the wire
// serialization needs the root's tree, threaded from the generated module.
#include "tom_som_cpp_v0_meta.hpp"

#include <iostream>
#include <optional>
#include <string>

int main() {
  som::SpecDocument doc;

  // Content leaves are addressed by their full path from the root segment.
  doc.setContent("SBP/content",
                 "A platform that unifies our fragmented order systems.");
  doc.setContent("SBP/currentLandscape/content",
                 "Three legacy systems with no shared customer record.");

  // A list: append items (each call returns the new item's path), then set a
  // content leaf under each. The list path mirrors the typed facade's
  // `operationalMetrics` accessor.
  const std::string listPath = "SBP/currentLandscape/CUOPME-OPER-LST";
  const std::string item0 = doc.addListItem(listPath);
  doc.setContent(som::joinPath(item0, "content"),
                 "Average order turnaround: 4.2 days.");
  const std::string item1 = doc.addListItem(listPath);
  doc.setContent(som::joinPath(item1, "content"),
                 "Manual reconciliation: ~12 hours / week.");

  // Read back generically.
  std::cout << "SBP/content = " << doc.content("SBP/content") << "\n";
  std::cout << "list item count = " << doc.listItemCount(listPath) << "\n";
  for (const std::string& item : doc.listItems(listPath)) {
    std::cout << "  " << item << "/content = "
              << doc.content(som::joinPath(item, "content")) << "\n";
  }

  // The whole document serializes losslessly to canonical JSON. Keys are
  // emitted in sorted order, so the dump is deterministic regardless of
  // insertion order (matching the Dart/Rust/Go/TS/C counterparts).
  const som::DocumentJson dj = doc.toJson();
  std::cout << "\nDocument JSON:\n"
            << som::documentJsonToCanonicalJson(dj) << "\n";

  // … and to the canonical YAML wire format (stamped with the model version),
  // walking the document root's metadata tree.
  std::string err;
  std::optional<std::string> yaml = som::encodeYaml(
      doc, tom_som_v0_meta::d00SolutionBlueprintMetaTree(), "0.0", &err);
  if (!yaml) {
    std::cerr << "encodeYaml failed: " << err << "\n";
    return 1;
  }
  std::cout << "\nDocument YAML:\n" << *yaml;

  return 0;
}
