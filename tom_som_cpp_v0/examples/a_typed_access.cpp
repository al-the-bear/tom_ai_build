// Sample (a) — TYPED object-model access (som_multiplatform_spec_model.md §6).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the header/source pair (include/, src/), meta/, schemas/ and the
// Makefile).
//
// Demonstrates editing a TomSpecs document through the generated *typed* facade
// `tom_som_cpp_v0`: named accessor member functions, nested-section navigation,
// and the path-based `som::SomList` collection. The typed facade is a thin
// editing surface over a generic `som::SpecDocument` — every typed write lands
// in the same path-keyed store the generic API (sample b) reads, which the
// closing lines prove.
//
// Build & run from the project root:  ./run_tests.sh   (builds + runs all three)
// or compile directly (see examples/README.md).
//
// Ownership (RAII): the `som::SpecDocument` is a value that must outlive every
// facade bound to it (facades hold a borrowed `SpecDocument&`). Facades are
// themselves values — no manual free; getters return `std::string` by value.
#include "tom_som_cpp_v0.hpp"

#include <iostream>

int main() {
  // A typed root over a fresh, empty document. The constructor also runs the
  // §2.2 instantiation-time version check (an empty stamp is editable).
  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint pd(doc);

  std::cout << "Model version of this typed facade: "
            << pd.objectModelVersion() << "\n";
  std::cout << "Root path: " << pd.path() << "\n\n";

  // 1) A content leaf directly on the root.
  pd.setContent("A platform that unifies our fragmented order systems.");

  // 2) Navigate into a nested complex section and edit its own content leaf.
  tom_som_v0::CurrentLandscape csa = pd.currentLandscape();
  csa.setContent("Three legacy systems with no shared customer record.");

  // 3) The path-based collection API: append two list items and edit each.
  som::SomList metrics = csa.operationalMetrics();
  const std::string p0 = metrics.add();
  tom_som_v0::CurrentOperationalMetric m0(doc, p0);
  m0.setContent("Average order turnaround: 4.2 days.");

  const std::string p1 = metrics.add();
  tom_som_v0::CurrentOperationalMetric m1(doc, p1);
  m1.setContent("Manual reconciliation: ~12 hours / week.");

  // Read everything back through the typed accessors.
  std::cout << "SBP.content              = " << pd.content() << "\n";
  std::cout << "SBP.currentLandscape = " << csa.content() << "\n";
  std::cout << "operationalMetrics.length = " << metrics.length() << "\n";

  for (std::size_t i = 0; i < metrics.length(); i++) {
    tom_som_v0::CurrentOperationalMetric item(doc, metrics.itemPathAt(i));
    std::cout << "  metric[" << i << "] = " << item.content() << "\n";
  }

  // The typed path is the generic path: the same data is addressable through
  // the generic document API (this is exactly what sample (b) uses).
  std::cout << "\nSame value via the generic path (" << csa.path()
            << "/content):\n";
  std::cout << "  " << doc.content("SBP/currentLandscape/content") << "\n";

  return 0;
}
