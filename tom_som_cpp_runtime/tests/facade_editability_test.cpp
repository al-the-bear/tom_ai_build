/* Behavioural test for a generated root facade's static `editabilityFor`
 * (§ item 8). The facade cannot be regenerated here (the generator runs
 * centrally, once, for all languages), so this hand-writes the exact shape the
 * `som_cpp_emitter` now emits per root — a static `editabilityFor` delegating to
 * `som::somEditabilityFor(kModelVersion, documentVersion)` — and asserts it
 * classifies correctly. This pins the emitter contract independently of a full
 * regeneration.
 */
#include <cstdio>
#include <string>

#include "som_facade.hpp"

namespace {

// Mirror of the generated root facade's editability surface (kModelVersion +
// the static editabilityFor the emitter now produces). kModelVersion "1.2" is a
// stand-in for the model version stamped into the real generated root.
struct GeneratedRootFacade {
  static constexpr const char* kModelVersion = "1.2";
  static som::SomEditability editabilityFor(const std::string& documentVersion) {
    return som::somEditabilityFor(kModelVersion, documentVersion);
  }
};

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

}  // namespace

int main() {
  using E = som::SomEditability;

  check("root editabilityFor empty -> editable",
        GeneratedRootFacade::editabilityFor("") == E::editable);
  check("root editabilityFor older minor -> editable",
        GeneratedRootFacade::editabilityFor("1.0") == E::editable);
  check("root editabilityFor equal -> editable",
        GeneratedRootFacade::editabilityFor("1.2") == E::editable);
  check("root editabilityFor newer minor -> rejected",
        GeneratedRootFacade::editabilityFor("1.5") == E::rejectedNewerMinor);
  check("root editabilityFor cross-major -> read-only",
        GeneratedRootFacade::editabilityFor("2.0") == E::readOnlyCrossMajor);
  check("root editabilityFor invalid -> invalidVersion",
        GeneratedRootFacade::editabilityFor("nope") == E::invalidVersion);

  if (g_failed == 0) {
    std::printf("facade_editability_test: all %zu checks passed\n", g_passed);
    return 0;
  }
  std::printf("facade_editability_test: %zu passed, %zu FAILED\n", g_passed,
              g_failed);
  return 1;
}
