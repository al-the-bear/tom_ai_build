package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** An inline mark the scanner could not read; it is left as written. */
public final class SpecMarkIssue {
  /** The value's path. */
  public final String path;

  /** The form field, or null for content. */
  public final String field;

  /** The 0-based line within the value. */
  public final int line;

  /** {@code unclosed}, {@code nested} or {@code noArrow}. */
  public final String issue;

  public SpecMarkIssue(String path, String field, int line, String issue) {
    this.path = path;
    this.field = field;
    this.line = line;
    this.issue = issue;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("path", path);
    out.put("field", field);
    out.put("line", line);
    out.put("issue", issue);
    return out;
  }
}
