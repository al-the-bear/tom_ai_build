package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One lettered alternative of a conflict block, {@code - (a) **alice:** text} (SOM §11.9.8). */
public final class SpecConflictAlternative {
  /** The lowercase letter. */
  public final String letter;

  /** The members who made this change. */
  public final List<String> members;

  /** The alternative's text; its continuation lines kept as lines. */
  public final String text;

  public SpecConflictAlternative(String letter, List<String> members, String text) {
    this.letter = letter;
    this.members = Collections.unmodifiableList(new ArrayList<>(members));
    this.text = text;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("letter", letter);
    out.put("members", new ArrayList<Object>(members));
    out.put("text", text);
    return out;
  }
}
