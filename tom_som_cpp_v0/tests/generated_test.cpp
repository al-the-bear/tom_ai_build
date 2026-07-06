// Behavioural test for the **actually-committed** generated C++ typed model.
//
// Unlike the emitter's golden test (which compiles the small emitter fixture),
// this harness exercises the real, full `tom_som_cpp_v0` translation unit
// (3000+ typed facade classes) against the generic `tom_som_cpp_runtime` and
// proves the typed facade is a faithful editing surface over the shared document
// (spec §3):
//
//   - the `D00SolutionBlueprint` root is anchored at the `PD` segment;
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
#include <vector>

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

// The SBP root, a content leaf, and a nested complex section round-trip in both
// directions between the typed facade and the generic document.
void testRootAndParity() {
  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint pd(doc);
  eqStr(pd.path(), "SBP", "root segment");

  // Typed write -> generic read.
  pd.setContent("A clear vision");
  eqStr(doc.content("SBP/content"), "A clear vision",
        "typed write visible generically");

  // Generic write -> typed read.
  doc.setContent("SBP/content", "Revised vision");
  eqStr(pd.content(), "Revised vision",
        "generic write visible through typed getter");

  // An unset leaf reads as the empty string.
  som::SpecDocument fresh;
  tom_som_v0::D00SolutionBlueprint pd2(fresh);
  eqStr(pd2.content(), "", "unset leaf reads as empty string");

  // Nested complex section path derivation (camelCase segment preserved).
  tom_som_v0::CurrentLandscape csa = pd.currentLandscape();
  eqStr(csa.path(), "SBP/currentLandscape", "nested section path");

  // A generic value under the nested typed node is addressable via the literal
  // path (typed path == generic path).
  doc.setContent("SBP/currentLandscape/probe", "x");
  eqStr(doc.content("SBP/currentLandscape/probe"), "x",
        "typed path is the generic path");
}

// The path-based typed list maps onto the generic list store; element facades
// are constructed from the item paths the list yields.
void testTypedList() {
  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint pd(doc);
  tom_som_v0::CurrentLandscape csa = pd.currentLandscape();
  som::SomList metrics = csa.operationalMetrics();

  // Append two items, constructing the element facade from each new path.
  const std::string p0 = metrics.add();
  tom_som_v0::CurrentOperationalMetric m0(doc, p0);
  m0.setContent("Average order turnaround: 4.2 days.");

  const std::string p1 = metrics.add();
  tom_som_v0::CurrentOperationalMetric m1(doc, p1);
  m1.setContent("Manual reconciliation: ~12 hours / week.");

  ok(metrics.length() == 2, "typed list length");

  // Read the first item back through an element facade over its item path.
  tom_som_v0::CurrentOperationalMetric r0(doc, metrics.itemPathAt(0));
  eqStr(r0.content(), "Average order turnaround: 4.2 days.",
        "typed list item content");

  // Typed list writes land in the generic list store under the same path.
  ok(doc.listItemCount("SBP/currentLandscape/CUOPME-OPER-LST") == 2,
     "generic list store mirrors typed list");
}

// The generated typed facade drives section-id generation and the delete rules
// (AA1 criteria 3–6) end-to-end. March 5 → the two-letter day code "CE"
// (C = month 3, E = day 5). Mirrors the C / Rust v0 `section_ids` tests, but in
// idiomatic C++: facades are values over a borrowed document, and a collision is
// signalled by a thrown som::SomSectionIdError rather than an out-param.
//
// A small helper builds the fixture: root -> currentLandscape -> the
// operationalMetrics list (which carries the "CUOPME-OPER-xxx" @SectionIdPattern).
struct MetricsFixture {
  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint pd{doc};
  tom_som_v0::CurrentLandscape csa{pd.currentLandscape()};
  som::SomList metrics{csa.operationalMetrics()};
};

// Appends a same-day item and asserts the generated section id (queried through
// a facade node over the new item's path).
void addOnExpect(MetricsFixture& f, long long month, long long day,
                 const std::string& want) {
  const std::string path = f.metrics.addOn(month, day);
  som::SomNode n(f.doc, path);
  eqStr(n.sectionId(), want, "addOn section id");
}

// Asserts the list's section ids equal `want` in order.
void expectSectionIds(MetricsFixture& f, const std::vector<std::string>& want,
                      const std::string& name) {
  ok(f.metrics.sectionIds() == want, name);
}

void testSectionIds() {
  const long long mar = 3, day = 5;

  // Generation: consecutive same-day items number CE1, CE2 (criteria 3–4).
  {
    MetricsFixture f;
    addOnExpect(f, mar, day, "CUOPME-OPER-CE1");
    addOnExpect(f, mar, day, "CUOPME-OPER-CE2");
  }

  // Override to an arbitrary suffix; a duplicate override or explicit add with
  // the same id throws a collision (criterion 5).
  {
    MetricsFixture f;
    f.metrics.addOn(mar, day);  // CE1
    f.metrics.addOn(mar, day);  // CE2

    som::SomNode n1(f.doc, f.metrics.itemPathAt(1));
    bool overrideOk = true;
    try {
      n1.setSectionId("CUOPME-OPER-ZZ9");
    } catch (const som::SomSectionIdError&) {
      overrideOk = false;
    }
    ok(overrideOk, "override succeeds");
    expectSectionIds(f, {"CUOPME-OPER-CE1", "CUOPME-OPER-ZZ9"},
                     "override applied, no renumber");

    som::SomNode n0(f.doc, f.metrics.itemPathAt(0));
    bool overrideCollision = false;
    try {
      n0.setSectionId("CUOPME-OPER-ZZ9");
    } catch (const som::SomSectionIdError& e) {
      overrideCollision = e.isCollision();
    }
    ok(overrideCollision, "override collision rejected");

    bool addCollision = false;
    try {
      f.metrics.addWithId("CUOPME-OPER-ZZ9");
    } catch (const som::SomSectionIdError& e) {
      addCollision = e.isCollision();
    }
    ok(addCollision, "add-with-id collision rejected");
  }

  // Delete a middle item: remaining ids never renumber, and a new same-day item
  // takes the next free number (criterion 6).
  {
    MetricsFixture f;
    for (int i = 0; i < 3; i++) {  // CE1, CE2, CE3
      f.metrics.addOn(mar, day);
    }
    f.metrics.removeAt(1);  // drop CE2
    expectSectionIds(f, {"CUOPME-OPER-CE1", "CUOPME-OPER-CE3"},
                     "delete-middle keeps ids");
    addOnExpect(f, mar, day, "CUOPME-OPER-CE4");
  }

  // Delete the last (max) item: a new same-day item reuses the freed number.
  {
    MetricsFixture f;
    for (int i = 0; i < 3; i++) {  // CE1, CE2, CE3
      f.metrics.addOn(mar, day);
    }
    f.metrics.removeAt(2);  // drop CE3 (the max)
    addOnExpect(f, mar, day, "CUOPME-OPER-CE3");
  }
}

// The generated model version is reported by both the constant and the accessor.
void testModelVersion() {
  eqStr(tom_som_v0::D00SolutionBlueprint::kModelVersion, "0.0",
        "kModelVersion constant");

  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint pd(doc);
  eqStr(pd.objectModelVersion(), "0.0", "objectModelVersion accessor");
}

// The instantiation-time §2.2 version check accepts editable stamps and rejects
// newer-minor / cross-major stamps by throwing som::SomVersionError.
void testVersionCheck() {
  som::SpecDocument doc;

  bool emptyOk = true;
  try {
    tom_som_v0::D00SolutionBlueprint a(doc, "");
  } catch (const som::SomVersionError&) {
    emptyOk = false;
  }
  ok(emptyOk, "empty stamp accepted");

  bool equalOk = true;
  try {
    tom_som_v0::D00SolutionBlueprint b(doc, "0.0");
  } catch (const som::SomVersionError&) {
    equalOk = false;
  }
  ok(equalOk, "equal stamp accepted");

  // Newer minor -> rejected.
  bool minorRejected = false;
  std::string minorMsg;
  try {
    tom_som_v0::D00SolutionBlueprint c(doc, "0.1");
  } catch (const som::SomVersionError& e) {
    minorRejected = true;
    minorMsg = e.what();
  }
  ok(minorRejected, "newer-minor stamp rejected");
  ok(!minorMsg.empty(), "rejection carries a message");

  // Different major -> rejected.
  bool majorRejected = false;
  try {
    tom_som_v0::D00SolutionBlueprint d(doc, "1.0");
  } catch (const som::SomVersionError&) {
    majorRejected = true;
  }
  ok(majorRejected, "cross-major stamp rejected");
}

}  // namespace

int main() {
  testRootAndParity();
  testTypedList();
  testSectionIds();
  testModelVersion();
  testVersionCheck();

  if (gFailed != 0) {
    std::cerr << "\n" << gFailed << " checks FAILED (" << gPassed << " passed)\n";
    return 1;
  }
  std::cout << "OK: " << gPassed << " checks passed\n";
  return 0;
}
