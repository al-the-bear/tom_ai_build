/* Behavioural test for SomList::addContent* and SomList::contents() (the SOM
 * §21 content-only list convenience). These are pure runtime members on the
 * SomList base; the generated element facades are not regenerated here (the
 * generator runs centrally). This hand-writes a minimal content-only facade — the
 * exact shape the emitter produces for a `<item>/content` leaf — and asserts
 * addContent appends + writes the nested leaf, honours the section-id pattern,
 * accepts an explicit id, and that contents() yields the ordered content leaves
 * (coalescing a missing leaf to "").
 */
#include <cstdio>
#include <string>
#include <vector>

#include "som_facade.hpp"
#include "spec_document.hpp"

namespace {

// Minimal generated-style element facade over a list item's nested content leaf:
// content() reads / setContent() writes `<item>/content`, exactly what addContent
// targets and what contents() reads back.
class ContentItem : public som::SomNode {
 public:
  ContentItem(som::SpecDocument& doc, std::string path)
      : som::SomNode(doc, std::move(path)) {}
  std::string content() const {
    return doc().content(som::joinPath(path(), "content"));
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
  const std::string kList = "root/items";

  // (a) addContent appends + sets the content leaf, visible via facade and the
  // generic document.
  {
    som::SpecDocument doc;
    som::SomList list(doc, kList);  // no pattern
    std::string p = list.addContent("hello");
    check("addContent appends one item", list.length() == 1);
    ContentItem item(doc, p);
    check("addContent facade sees content", item.content() == "hello");
    check("addContent writes nested <item>/content leaf",
          doc.content(som::joinPath(p, "content")) == "hello");
  }

  // (b) honours the section-id pattern (deterministic clock-free variant).
  {
    som::SpecDocument doc;
    som::SomList list(doc, kList, "DACEN-ITEM-xxx");
    std::string p = list.addContentOn("patterned", /*month=*/1, /*day=*/1);
    // Jan -> 'A', day 1 -> 'A', first within the day -> 1.
    check("addContentOn honours section-id pattern",
          doc.itemSectionId(p) == "DACEN-ITEM-AA1");
    check("addContentOn still writes content leaf",
          doc.content(som::joinPath(p, "content")) == "patterned");
  }

  // (c) accepts an explicit section-id override.
  {
    som::SpecDocument doc;
    som::SomList list(doc, kList, "DACEN-ITEM-xxx");
    std::string p = list.addContentWithId("body", "MY-CUSTOM-ID");
    check("addContentWithId honours explicit id",
          doc.itemSectionId(p) == "MY-CUSTOM-ID");
    check("addContentWithId writes content leaf",
          doc.content(som::joinPath(p, "content")) == "body");
  }

  // (d) contents() yields the items' content leaves in order, and
  // (e) a missing leaf coalesces to "".
  {
    som::SpecDocument doc;
    som::SomList list(doc, kList);
    list.addContent("first");
    list.add();  // plain add: no content leaf written -> should read back as ""
    list.addContent("third");
    std::vector<std::string> got = list.contents();
    check("contents() length matches item count", got.size() == 3);
    check("contents()[0] ordered content",
          got.size() > 0 && got[0] == "first");
    check("contents()[1] missing leaf -> \"\"",
          got.size() > 1 && got[1].empty());
    check("contents()[2] ordered content",
          got.size() > 2 && got[2] == "third");
  }

  if (g_failed == 0) {
    std::printf("list_add_content_test: all %zu checks passed\n", g_passed);
    return 0;
  }
  std::printf("list_add_content_test: %zu passed, %zu FAILED\n", g_passed,
              g_failed);
  return 1;
}
