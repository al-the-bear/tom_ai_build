/* Behavioural test for the structural `canHaveContent()` predicate (§ item 10):
 * "does this section TYPE declare the standard `content` text leaf?" — answered
 * at the type level, WITHOUT probing the document.
 *
 * `canHaveContent()` is a virtual member of the runtime base `som::SomNode`
 * returning the `false` default; the generated content-bearing facades override
 * it to `true`. The full generated model is not regenerated here (the generator
 * runs centrally), so this hand-writes the two facade shapes the emitter now
 * produces — a content-bearing section (override -> true) and a container-only
 * section (inherits -> false) — and pins:
 *   - the base default is false;
 *   - a content-bearing override reports true;
 *   - a container-only / scalar-only section inherits false;
 *   - it is STRUCTURAL — independent of whether content is written now, and
 *     distinct from the state predicates isEmpty() / hasContent();
 *   - it resolves polymorphically through a som::SomNode& reference.
 */
#include <cstdio>
#include <string>

#include "som_facade.hpp"
#include "spec_document.hpp"

namespace {

// A content-bearing section: it declares the standard `content` leaf, so the
// emitter emits the `canHaveContent() const override { return true; }` shape.
class ContentBearing : public som::SomNode {
 public:
  ContentBearing(som::SpecDocument& doc, std::string path)
      : som::SomNode(doc, std::move(path)) {}
  bool canHaveContent() const override { return true; }
  std::string content() const {
    return doc().content(som::joinPath(path(), "content"));
  }
  void setContent(const std::string& value) {
    doc().setContent(som::joinPath(path(), "content"), value);
  }
};

// A container-only section: no `content` leaf, so the emitter emits no override
// and it inherits the base `false` default.
class ContainerOnly : public som::SomNode {
 public:
  ContainerOnly(som::SpecDocument& doc, std::string path)
      : som::SomNode(doc, std::move(path)) {}
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
  som::SpecDocument doc;

  // The plain base node reports the structural default: false.
  {
    som::SomNode base(doc, "root/plain");
    check("base SomNode default canHaveContent == false",
          base.canHaveContent() == false);
  }

  // A content-bearing section overrides the default to true.
  {
    ContentBearing cb(doc, "root/goals");
    check("content-bearing section canHaveContent == true",
          cb.canHaveContent() == true);
  }

  // A container-only section inherits the false default (no override).
  {
    ContainerOnly co(doc, "root/systemsToReplace");
    check("container-only section inherits canHaveContent == false",
          co.canHaveContent() == false);
  }

  // Structural, not state: canHaveContent is independent of whether the content
  // leaf holds a value now — and distinct from isEmpty()/hasContent().
  {
    ContentBearing cb(doc, "root/goals2");
    check("empty content-bearing section still canHaveContent == true",
          cb.canHaveContent() == true);
    check("empty content-bearing section isEmpty() == true (state)",
          cb.isEmpty() == true);
    cb.setContent("Grow revenue");
    check("filled content-bearing section still canHaveContent == true",
          cb.canHaveContent() == true);
    check("filled content-bearing section isEmpty() == false (state changed)",
          cb.isEmpty() == false);
  }

  // A container-only section stays false even once a nested value fills it.
  {
    ContainerOnly co(doc, "root/container2");
    doc.setContent("root/container2/child/content", "x");
    check("filled container-only section still canHaveContent == false",
          co.canHaveContent() == false);
    check("filled container-only section isEmpty() == false (state)",
          co.isEmpty() == false);
  }

  // The predicate resolves polymorphically through a base reference.
  {
    ContentBearing cb(doc, "root/goals3");
    ContainerOnly co(doc, "root/container3");
    som::SomNode& cbRef = cb;
    som::SomNode& coRef = co;
    check("polymorphic canHaveContent through base ref (content-bearing)",
          cbRef.canHaveContent() == true);
    check("polymorphic canHaveContent through base ref (container-only)",
          coRef.canHaveContent() == false);
  }

  if (g_failed == 0) {
    std::printf("can_have_content_test: all %zu checks passed\n", g_passed);
    return 0;
  }
  std::printf("can_have_content_test: %zu passed, %zu FAILED\n", g_passed,
              g_failed);
  return 1;
}
