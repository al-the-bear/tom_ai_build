/* Unit tests for the SOM §4.2 model-version guard in `som_facade`
 * (`somEditabilityFor` + `checkSomModelVersion`), an idiomatic-C++ port mirror
 * of the Dart reference cases in `tom_som_dart_runtime`'s `som_facade.dart`.
 *
 * Covers item 8: the non-throwing classifier `somEditabilityFor`, and confirms
 * the throwing `checkSomModelVersion` delegates to it — throwing exactly where
 * the classifier returns a non-editable value and staying silent where it
 * returns editable. Exit 0 == all green; non-zero on the first failed check.
 */
#include <cstdio>
#include <string>
#include <vector>

#include "som_facade.hpp"

namespace {

std::size_t g_passed = 0;
std::vector<std::string> g_failed;

void check(const std::string& name, bool cond) {
  if (cond) {
    g_passed++;
  } else {
    g_failed.push_back(name);
  }
}

// Runs checkSomModelVersion and reports whether it threw SomVersionError.
bool checkThrows(const std::string& generated, const std::string& documentVersion) {
  try {
    som::checkSomModelVersion(generated, documentVersion);
    return false;
  } catch (const som::SomVersionError&) {
    return true;
  }
}

// Runs somEditabilityFor, asserting it never throws for a valid `generated`.
bool classifierThrew = false;
som::SomEditability classify(const std::string& generated,
                             const std::string& documentVersion) {
  try {
    return som::somEditabilityFor(generated, documentVersion);
  } catch (const som::SomVersionError&) {
    classifierThrew = true;
    return som::SomEditability::invalidVersion;
  }
}

}  // namespace

int main() {
  using E = som::SomEditability;
  const std::string gen = "1.2";

  // ---- somEditabilityFor: mirror the Dart reference cases ----------------

  // "" (empty) -> editable, because C++ uses the empty-string sentinel for an
  // absent document version (CS4-D2). This is the port's analogue of the Dart
  // null/empty -> editable case.
  check("empty is editable", classify(gen, "") == E::editable);

  // Same major, older minor -> editable (upgraded on edit).
  check("same major older minor editable", classify(gen, "1.0") == E::editable);
  check("same major older minor editable 1", classify(gen, "1.1") == E::editable);

  // Same major, equal minor -> editable.
  check("same major equal minor editable", classify(gen, "1.2") == E::editable);

  // Same major, newer minor -> rejectedNewerMinor.
  check("same major newer minor rejected",
        classify(gen, "1.3") == E::rejectedNewerMinor);
  check("same major far newer minor rejected",
        classify(gen, "1.99") == E::rejectedNewerMinor);

  // Different major (lower or higher) -> readOnlyCrossMajor, regardless of minor.
  check("lower major cross-major", classify(gen, "0.9") == E::readOnlyCrossMajor);
  check("higher major cross-major", classify(gen, "2.0") == E::readOnlyCrossMajor);
  check("higher major newer minor still cross-major",
        classify(gen, "2.5") == E::readOnlyCrossMajor);

  // Unparseable document stamp -> invalidVersion (not a throw).
  check("garbage invalid", classify(gen, "not-a-version") == E::invalidVersion);
  check("one part invalid", classify(gen, "1") == E::invalidVersion);
  check("three parts invalid", classify(gen, "1.2.3") == E::invalidVersion);
  check("non-numeric minor invalid", classify(gen, "1.x") == E::invalidVersion);
  check("empty minor invalid", classify(gen, "1.") == E::invalidVersion);

  // The classifier must NOT throw for any of the above (valid `generated`).
  check("classifier never threw for valid generated", !classifierThrew);

  // ---- checkSomModelVersion delegates: throws iff not editable -----------

  // Editable cases -> no throw.
  check("check silent on empty", !checkThrows(gen, ""));
  check("check silent on older minor", !checkThrows(gen, "1.0"));
  check("check silent on equal minor", !checkThrows(gen, "1.2"));

  // Non-editable cases -> throw, matching the classifier.
  check("check throws on newer minor", checkThrows(gen, "1.3"));
  check("check throws on cross-major", checkThrows(gen, "2.0"));
  check("check throws on lower major", checkThrows(gen, "0.1"));
  check("check throws on invalid", checkThrows(gen, "garbage"));

  // Where checkSomModelVersion throws, somEditabilityFor must return the
  // matching non-editable value without throwing (item 8's core property).
  check("no throw where check throws (newer minor)",
        classify(gen, "1.3") == E::rejectedNewerMinor);
  check("no throw where check throws (cross-major)",
        classify(gen, "2.0") == E::readOnlyCrossMajor);
  check("no throw where check throws (invalid)",
        classify(gen, "garbage") == E::invalidVersion);

  // ---- report ------------------------------------------------------------
  if (g_failed.empty()) {
    std::printf("version_check_test: all %zu checks passed\n", g_passed);
    return 0;
  }
  std::printf("version_check_test: %zu passed, %zu FAILED:\n", g_passed,
              g_failed.size());
  for (const std::string& name : g_failed) {
    std::printf("  FAIL: %s\n", name.c_str());
  }
  return 1;
}
