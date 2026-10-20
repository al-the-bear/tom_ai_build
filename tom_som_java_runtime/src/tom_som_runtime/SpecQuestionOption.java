package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * One option of a question (SOM §11.9.2): {@code - (a) text}, or {@code - **(b)** text} for the
 * recommended one.
 */
public final class SpecQuestionOption {
  /** The lowercase letter. */
  public final String letter;

  /** The option's text, its continuation lines joined with one space. */
  public final String text;

  /** Whether the option is written bold — the recommended one. */
  public final boolean bold;

  /** Creates an option. */
  public SpecQuestionOption(String letter, String text, boolean bold) {
    this.letter = letter;
    this.text = text;
    this.bold = bold;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("letter", letter);
    out.put("text", text);
    out.put("bold", bold);
    return out;
  }
}
