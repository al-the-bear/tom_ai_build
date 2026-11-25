// The merge back of one value (SOM §11.10) on text beyond ASCII, and the base
// read from git — what `strip_merge_cases.json` (run by tests/conformance.cpp)
// does not reach. The expectations were computed with the TypeScript runtime's
// `mergeStrippedValue` (`toJson`, the conflicts' `reportLines`), so the offsets
// (`placed.at`, UTF-16 code units) and the excerpts (thirty UTF-16 units either
// side) are held to the reference. The C++ port of the C runtime's
// tests/spec_document_merge_test.c, with the same cases.
//
// Exit status is the number of failed checks (0 = green).

#include <cstdio>
#include <string>
#include <vector>

#include "spec_document_merge.hpp"
#include "spec_document_strip.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void check(const std::string& name, bool cond, const std::string& detail = "") {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  std::fprintf(stderr, "FAIL %s%s%s\n", name.c_str(), detail.empty() ? "" : ": ",
               detail.c_str());
}

struct Case {
  const char* original;
  const char* list;  // "drop" or "unmark"
  const char* names;
  const char *find, *replace;
  const char* text;  // nullptr: conflicts
  long long restored;
  long placed_at;  // -1: nothing placed
  const char* placed_removed;
  const char* conflict;  // the one conflict's code, nullptr: none
  const char* lines[5];  // the conflict's report lines
  int lines_len;
};

static const Case kCases[] = {
  {"Die Gr\xc3""\xb6""\xc3""\x9f""e ist hoch (-> C2.1).", "drop", "trace", "hoch", "stark gestiegen \xf0""\x9f""\x98""\x80""", "Die Gr\xc3""\xb6""\xc3""\x9f""e ist stark gestiegen \xf0""\x9f""\x98""\x80"" (-> C2.1).", 1, 32, " (-> C2.1)", nullptr, {nullptr}, 0},
  {"Ein \xf0""\x9f""\x98""\x80"" [schnelles braunes]{.aside} Tier l\xc3""\xa4""uft.", "unmark", "aside", "braunes Tier", "Wesen", nullptr, 0, -1, nullptr, "crossesBoundary", {"CONFLICT (document) \xe2""\x80""\x94"" an edit crosses the boundary of an unmarked element", "  O: \xc2""\xab""Ein \xf0""\x9f""\x98""\x80"" [schnelles braunes]{.aside} Tier l\xc3""\xa4""uft.\xc2""\xbb""", "  B: \xc2""\xab""Ein \xf0""\x9f""\x98""\x80"" schnelles braunes Tier l\xc3""\xa4""uft.\xc2""\xbb""", "  E: \xc2""\xab""Ein \xf0""\x9f""\x98""\x80"" schnelles Wesen l\xc3""\xa4""uft.\xc2""\xbb""", "  piece: \xc2""\xab""]{.aside}\xc2""\xbb"""}, 5},
  {"\xc3""\x84"" Wort{>>Bemerkung \xc3""\xbc""ber \xc3""\x96""l<<} hier.", "drop", "comments", "Wort", "Begriff", "\xc3""\x84"" Begriff{>>Bemerkung \xc3""\xbc""ber \xc3""\x96""l<<} hier.", 2, -1, nullptr, nullptr, {nullptr}, 0},
  {"Gr\xc3""\xb6""\xc3""\x9f""e [weil \xf0""\x9f""\x98""\x80"" so]{.aside} gilt.\n\nZweiter Absatz.", "drop", "aside", "gilt", "bleibt", "Gr\xc3""\xb6""\xc3""\x9f""e [weil \xf0""\x9f""\x98""\x80"" so]{.aside} bleibt.\n\nZweiter Absatz.", 1, -1, nullptr, nullptr, {nullptr}, 0},
  {"Ein \xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc"" langer Satz mit [schnelles braunes]{.aside} Tier und noch viel mehr Text danach \xc3""\xa4""\xc3""\xb6""\xc3""\xbc"".", "unmark", "aside", "braunes Tier", "Wesen", nullptr, 0, -1, nullptr, "crossesBoundary", {"CONFLICT (document) \xe2""\x80""\x94"" an edit crosses the boundary of an unmarked element", "  O: \xc2""\xab""er Satz mit [schnelles braunes]{.aside} Tier und noch viel m\xc2""\xbb""", "  B: \xc2""\xab""ger Satz mit schnelles braunes Tier und noch viel mehr Text \xc2""\xbb""", "  E: \xc2""\xab""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc"" langer Satz mit schnelles Wesen und noch viel mehr Text \xc2""\xbb""", "  piece: \xc2""\xab""]{.aside}\xc2""\xbb"""}, 5},
};

std::string replaceFirst(const std::string& s, const std::string& find,
                         const std::string& rep) {
  const std::size_t at = s.find(find);
  if (at == std::string::npos) return s;
  return s.substr(0, at) + rep + s.substr(at + find.size());
}

void testValues() {
  for (std::size_t i = 0; i < sizeof(kCases) / sizeof(kCases[0]); i++) {
    const Case& c = kCases[i];
    const std::string tag = "value " + std::to_string(i) + ": ";
    const bool drop = std::string(c.list) == "drop";
    const std::vector<std::string> names{c.names};
    const som::SpecStripOptions o = som::SpecStripOptions::fromNames(
        drop ? names : std::vector<std::string>{}, drop ? std::vector<std::string>{} : names,
        {});
    const som::SpecStripTextResult st = som::stripNotationText(c.original, o);
    const std::string edited = replaceFirst(st.text, c.find, c.replace);
    const som::SpecStripValueMerge m =
        som::mergeStrippedValue(c.original, st.text, edited, st.pieces);
    check(tag + "text",
          (c.text == nullptr && !m.text.has_value()) ||
              (c.text != nullptr && m.text.has_value() && *m.text == c.text),
          m.text.value_or("null"));
    check(tag + "restored", m.restored == c.restored, std::to_string(m.restored));
    if (c.placed_at < 0) {
      check(tag + "placed", m.placed.empty());
    } else {
      check(tag + "placed",
            m.placed.size() == 1 && m.placed[0].at == c.placed_at &&
                m.placed[0].piece.removed == c.placed_removed,
            m.placed.empty() ? "none" : std::to_string(m.placed[0].at));
    }
    if (c.conflict == nullptr) {
      check(tag + "conflicts", m.conflicts.empty());
    } else {
      check(tag + "conflicts", m.conflicts.size() == 1 && m.conflicts[0].code == c.conflict);
      if (m.conflicts.size() == 1) {
        const std::vector<std::string> lines = m.conflicts[0].reportLines();
        check(tag + "report lines", (int)lines.size() == c.lines_len,
              std::to_string(lines.size()));
        for (std::size_t k = 0; k < lines.size() && (int)k < c.lines_len; k++) {
          check(tag + "report line " + std::to_string(k), lines[k] == c.lines[k], lines[k]);
        }
      }
    }
  }
}

// The base read from git: the runner runs in the package root, a clone.
void testGitShow() {
  const auto readme = som::SpecStripMerge::gitShowFile("HEAD", "README.md");
  check("git: a committed file is read", readme.has_value() && !readme->empty() &&
                                             (*readme)[0] == '#');
  const auto nested =
      som::SpecStripMerge::gitShowFile("HEAD", "src/spec_document_strip.cpp");
  check("git: a file in a folder is read from its folder",
        nested.has_value() && nested->find("spec_document_strip") != std::string::npos);
  check("git: an unknown commit gives none",
        !som::SpecStripMerge::gitShowFile("0000000000000000000000000000000000000000",
                                          "README.md")
             .has_value());
  check("git: an unknown file gives none",
        !som::SpecStripMerge::gitShowFile("HEAD", "no_such_file.md").has_value());
}

}  // namespace

int main() {
  testValues();
  testGitShow();
  if (g_failures == 0) {
    std::printf("spec_document_merge_test: all %d checks passed\n", g_checks);
  }
  return g_failures;
}
