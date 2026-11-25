package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/** The result of {@link SpecNotation#scanNotation}. */
public final class NotationScan {
  /** The text that was scanned. */
  public final String text;
  /** The elements not nested in another, in source order. */
  public final List<NotationElement> elements;
  /** The findings, by offset. */
  public final List<NotationFinding> findings;

  public NotationScan(String text, List<NotationElement> elements, List<NotationFinding> findings) {
    this.text = text;
    this.elements = elements;
    this.findings = findings;
  }

  /** Every element, depth-first in source order. */
  public List<NotationElement> all() {
    List<NotationElement> out = new ArrayList<>();
    walk(elements, out);
    return out;
  }

  private static void walk(List<NotationElement> list, List<NotationElement> out) {
    for (NotationElement e : list) {
      out.add(e);
      walk(e.children, out);
    }
  }

  /** Whether a finding of severity {@code "error"} is present. */
  public boolean hasErrors() {
    for (NotationFinding f : findings) {
      if ("error".equals(f.severity())) {
        return true;
      }
    }
    return false;
  }
}
