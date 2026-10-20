package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/** A question to insert (SOM §11.9.2). */
public final class SpecQuestionDraft {
  /** The question id ({@code BQ-90}). */
  public final String id;

  /** The topic. */
  public final String topic;

  /** The question text; may span lines. */
  public final String text;

  /** Option lines, written as {@code - <option>} (e.g. {@code (a) lower only}). */
  public final List<String> options;

  /** The recommendation, or empty. */
  public final String recommendation;

  /** The working assumption, or empty. */
  public final String assumption;

  /** Whether the question carries {@code ★}. */
  public final boolean starred;

  /** A draft with only an id, a topic and a text. */
  public SpecQuestionDraft(String id, String topic, String text) {
    this(id, topic, text, Collections.emptyList(), "", "", false);
  }

  public SpecQuestionDraft(
      String id,
      String topic,
      String text,
      List<String> options,
      String recommendation,
      String assumption,
      boolean starred) {
    this.id = id;
    this.topic = topic;
    this.text = text;
    this.options =
        options == null ? Collections.emptyList() : Collections.unmodifiableList(new ArrayList<>(options));
    this.recommendation = recommendation == null ? "" : recommendation;
    this.assumption = assumption == null ? "" : assumption;
    this.starred = starred;
  }

  /** Reads a draft from its corpus JSON form. */
  public static SpecQuestionDraft fromJson(Map<String, Object> j) {
    List<String> options = new ArrayList<>();
    Object raw = j.get("options");
    if (raw instanceof List) {
      for (Object o : (List<?>) raw) {
        options.add(String.valueOf(o));
      }
    }
    Object starred = j.get("starred");
    return new SpecQuestionDraft(
        (String) j.get("id"),
        (String) j.get("topic"),
        (String) j.get("text"),
        options,
        (String) j.get("recommendation"),
        (String) j.get("assumption"),
        Boolean.TRUE.equals(starred));
  }
}
