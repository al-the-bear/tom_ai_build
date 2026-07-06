import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import tom_som_runtime.SomList;
import tom_som_runtime.SomNode;
import tom_som_runtime.SpecDocument;

/**
 * Dependency-free unit tests for {@link SomList#addContent} and
 * {@link SomList#contents} (§ item 9). Mirrors the Dart reference cases: JUnit is
 * unavailable on the build host, so this is a plain {@code main()} that exits 0
 * on success and 1 on failure — the same shape as {@code SomFacadeTest}.
 */
public final class SomListContentTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void eq(String name, Object got, Object want) {
    check(name, want == null ? got == null : want.equals(got), got + " != " + want);
  }

  /**
   * A content-only element facade fixture (mirrors a generated leaf-only node):
   * exposes its nested {@code <path>/content} leaf through the live document.
   */
  static final class ContentItem extends SomNode {
    ContentItem(SpecDocument doc, String path) {
      super(doc, path);
    }

    String content() {
      return doc.content(path + "/content");
    }
  }

  public static void main(String[] args) {
    final String listPath = "ROOT/items";
    final String pattern = "DACEN-ITEM-xxx";

    // (a) addContent appends + sets the content leaf, visible via the facade
    //     and via the generic document.
    {
      SpecDocument doc = new SpecDocument();
      SomList<ContentItem> list = new SomList<>(doc, listPath, ContentItem::new);
      ContentItem item = list.addContent("hello");
      eq("a-length", list.length(), 1);
      eq("a-facade-content", item.content(), "hello");
      // Generic doc view: exactly one item, its content leaf is set.
      List<String> paths = doc.listItems(listPath);
      eq("a-doc-item-count", paths.size(), 1);
      eq("a-doc-content", doc.content(paths.get(0) + "/content"), "hello");
    }

    // (b) honours the section-id pattern (generated from the date component).
    {
      SpecDocument doc = new SpecDocument();
      SomList<ContentItem> list =
          new SomList<>(doc, listPath, ContentItem::new, pattern);
      ContentItem item = list.addContent("body", null, LocalDate.of(2026, 3, 5));
      // March (3rd month) -> 'C', day 5 -> 'E', first same-day item -> 1.
      eq("b-generated-section-id", item.$sectionId(), "DACEN-ITEM-CE1");
      eq("b-content", item.content(), "body");
    }

    // (c) accepts an explicit section-id override.
    {
      SpecDocument doc = new SpecDocument();
      SomList<ContentItem> list =
          new SomList<>(doc, listPath, ContentItem::new, pattern);
      ContentItem item = list.addContent("body", "CUSTOM-9");
      eq("c-override-section-id", item.$sectionId(), "CUSTOM-9");
      eq("c-content", item.content(), "body");
    }

    // (d) contents() yields each item's content in order.
    {
      SpecDocument doc = new SpecDocument();
      SomList<ContentItem> list = new SomList<>(doc, listPath, ContentItem::new);
      list.addContent("first");
      list.addContent("second");
      list.addContent("third");
      eq("d-contents-ordered", list.contents(), List.of("first", "second", "third"));
    }

    // (e) contents() coalesces a missing content leaf to "".
    {
      SpecDocument doc = new SpecDocument();
      SomList<ContentItem> list = new SomList<>(doc, listPath, ContentItem::new);
      list.add(); // plain add: no content leaf written.
      list.addContent("present");
      eq("e-contents-coalesced", list.contents(), List.of("", "present"));
    }

    int total = passed + failed.size();
    if (!failed.isEmpty()) {
      System.out.println("FAIL: " + failed.size() + "/" + total + " checks failed");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
      return;
    }
    System.out.println("OK: " + total + " checks passed");
  }

  private SomListContentTest() {}
}
