// Behavioural test for the **actually-committed** generated C++ typed model.
//
// Unlike the emitter's golden test (which compiles the small emitter fixture),
// this harness exercises the real, full `tom_som_cpp_v0` translation unit
// (3000+ typed facade classes) against the generic `tom_som_cpp_runtime` and
// proves the typed facade is a faithful editing surface over the shared document
// (spec §3):
//
//   - the `ProjectDefinition` root is anchored at the `PD` segment;
//   - a content leaf round-trips typed -> generic and generic -> typed;
//   - a nested complex section derives its path under the root;
//   - the path-based `som::SomList` collection maps onto the generic list store;
//   - the generated model-version accessor / constant return "0.0";
//   - the instantiation-time version check (§2.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp by throwing som::SomVersionError.
//
// Build & run via `./run_tests.sh` (compiles against the relative runtime
// checkout). Exit 0 == all green; it prints "OK: N checks passed".
//
// RAII does the memory management the C harness did by hand: a borrowed
// som::SpecDocument outlives every facade bound to it; facades are values.
#include "tom_som_cpp_v0.hpp"

#include <iostream>
#include <string>

namespace {

int gPassed = 0;
int gFailed = 0;

void ok(bool cond, const std::string& name) {
  if (cond) {
    ++gPassed;
  } else {
    ++gFailed;
    std::cerr << "FAIL: " << name << "\n";
  }
}

void eqStr(const std::string& got, const std::string& want,
           const std::string& name) {
  if (got == want) {
    ++gPassed;
  } else {
    ++gFailed;
    std::cerr << "FAIL: " << name << " — got \"" << got << "\" want \"" << want
              << "\"\n";
  }
}

// The PD root, a content leaf, and a nested complex section round-trip in both
// directions between the typed facade and the generic document.
void testRootAndParity() {
  som::SpecDocument doc;
  tom_som_v0::ProjectDefinition pd(doc);
  eqStr(pd.path(), "PD", "root segment");

  // Typed write -> generic read.
  pd.setContent("A clear vision");
  eqStr(doc.content("PD/content"), "A clear vision",
        "typed write visible generically");

  // Generic write -> typed read.
  doc.setContent("PD/content", "Revised vision");
  eqStr(pd.content(), "Revised vision",
        "generic write visible through typed getter");

  // An unset leaf reads as the empty string.
  som::SpecDocument fresh;
  tom_som_v0::ProjectDefinition pd2(fresh);
  eqStr(pd2.content(), "", "unset leaf reads as empty string");

  // Nested complex section path derivation (camelCase segment preserved).
  tom_som_v0::CurrentStateAnalysis csa = pd.currentStateAnalysis();
  eqStr(csa.path(), "PD/currentStateAnalysis", "nested section path");

  // A generic value under the nested typed node is addressable via the literal
  // path (typed path == generic path).
  doc.setContent("PD/currentStateAnalysis/probe", "x");
  eqStr(doc.content("PD/currentStateAnalysis/probe"), "x",
        "typed path is the generic path");
}

// The path-based typed list maps onto the generic list store; element facades
// are constructed from the item paths the list yields.
void testTypedList() {
  som::SpecDocument doc;
  tom_som_v0::ProjectDefinition pd(doc);
  tom_som_v0::CurrentStateAnalysis csa = pd.currentStateAnalysis();
  som::SomList metrics = csa.operationalMetrics();

  // Append two items, constructing the element facade from each new path.
  const std::string p0 = metrics.add();
  tom_som_v0::CurrentOperationalMetrics m0(doc, p0);
  m0.setContent("Average order turnaround: 4.2 days.");

  const std::string p1 = metrics.add();
  tom_som_v0::CurrentOperationalMetrics m1(doc, p1);
  m1.setContent("Manual reconciliation: ~12 hours / week.");

  ok(metrics.length() == 2, "typed list length");

  // Read the first item back through an element facade over its item path.
  tom_som_v0::CurrentOperationalMetrics r0(doc, metrics.itemPathAt(0));
  eqStr(r0.content(), "Average order turnaround: 4.2 days.",
        "typed list item content");

  // Typed list writes land in the generic list store under the same path.
  ok(doc.listItemCount("PD/currentStateAnalysis/CUOPME-OPER-LST") == 2,
     "generic list store mirrors typed list");
}

// The generated model version is reported by both the constant and the accessor.
void testModelVersion() {
  eqStr(tom_som_v0::ProjectDefinition::kModelVersion, "0.0",
        "kModelVersion constant");

  som::SpecDocument doc;
  tom_som_v0::ProjectDefinition pd(doc);
  eqStr(pd.objectModelVersion(), "0.0", "objectModelVersion accessor");
}

// The instantiation-time §2.2 version check accepts editable stamps and rejects
// newer-minor / cross-major stamps by throwing som::SomVersionError.
void testVersionCheck() {
  som::SpecDocument doc;

  bool emptyOk = true;
  try {
    tom_som_v0::ProjectDefinition a(doc, "");
  } catch (const som::SomVersionError&) {
    emptyOk = false;
  }
  ok(emptyOk, "empty stamp accepted");

  bool equalOk = true;
  try {
    tom_som_v0::ProjectDefinition b(doc, "0.0");
  } catch (const som::SomVersionError&) {
    equalOk = false;
  }
  ok(equalOk, "equal stamp accepted");

  // Newer minor -> rejected.
  bool minorRejected = false;
  std::string minorMsg;
  try {
    tom_som_v0::ProjectDefinition c(doc, "0.1");
  } catch (const som::SomVersionError& e) {
    minorRejected = true;
    minorMsg = e.what();
  }
  ok(minorRejected, "newer-minor stamp rejected");
  ok(!minorMsg.empty(), "rejection carries a message");

  // Different major -> rejected.
  bool majorRejected = false;
  try {
    tom_som_v0::ProjectDefinition d(doc, "1.0");
  } catch (const som::SomVersionError&) {
    majorRejected = true;
  }
  ok(majorRejected, "cross-major stamp rejected");
}

}  // namespace

int main() {
  testRootAndParity();
  testTypedList();
  testModelVersion();
  testVersionCheck();

  if (gFailed != 0) {
    std::cerr << "\n" << gFailed << " checks FAILED (" << gPassed << " passed)\n";
    return 1;
  }
  std::cout << "OK: " << gPassed << " checks passed\n";
  return 0;
}
