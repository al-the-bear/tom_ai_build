package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One element of the reading notation: a div, a span or a citation. */
public final class NotationElement {
  /** {@code "div"}, {@code "span"} or {@code "citation"}. */
  public final String type;
  /** The first class; {@code trace} / {@code provenance} for a citation; {@code null} without a class. */
  public final String kind;
  /** Every class, the kind first. */
  public final List<String> classes;
  /** The {@code #id} of the attributes (not a section id); {@code null} without one. */
  public final String id;
  /** The {@code key="value"} pairs, in their order. */
  public final Map<String, String> attributes;
  /** A citation's arrow: {@code ->}, {@code <-} or {@code <~}; {@code null} otherwise. */
  public final String shape;
  /** The UTF-16 offset of the first character. */
  public final int start;
  /** The UTF-16 offset after the last character. */
  public final int end;
  /** The UTF-16 offset of the content. */
  public final int contentStart;
  /** The UTF-16 offset after the content. */
  public final int contentEnd;
  /** The 1-based line of {@link #start}. */
  public final int line;
  /** The 1-based line of the last character. */
  public final int endLine;
  /** False for a div without a closing fence. */
  public final boolean closed;
  /** The elements nested in this one, in source order. */
  public final List<NotationElement> children = new ArrayList<>();

  public NotationElement(
      String type,
      String kind,
      List<String> classes,
      String id,
      Map<String, String> attributes,
      String shape,
      int start,
      int end,
      int contentStart,
      int contentEnd,
      int line,
      int endLine,
      boolean closed) {
    this.type = type;
    this.kind = kind;
    this.classes = classes;
    this.id = id;
    this.attributes = attributes;
    this.shape = shape;
    this.start = start;
    this.end = end;
    this.contentStart = contentStart;
    this.contentEnd = contentEnd;
    this.line = line;
    this.endLine = endLine;
    this.closed = closed;
  }

  /** Whether the kind is registered ({@link SpecNotation#registeredNotationKinds}). */
  public boolean isRegistered() {
    return kind != null && SpecNotation.registeredNotationKinds.contains(kind);
  }

  /** The element's source in {@code text}, the text it was scanned from. */
  public String source(String text) {
    return text.substring(start, end);
  }

  /** The element's content in {@code text}, the text it was scanned from. */
  public String content(String text) {
    return text.substring(contentStart, contentEnd);
  }

  /** The element as the conformance corpus writes it ({@code text}: the text it was scanned from). */
  public Map<String, Object> toJson(String text) {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("type", type);
    out.put("kind", kind);
    out.put("classes", new ArrayList<Object>(classes));
    out.put("id", id);
    out.put("attributes", new LinkedHashMap<String, Object>(attributes));
    out.put("shape", shape);
    out.put("start", start);
    out.put("end", end);
    out.put("line", line);
    out.put("endLine", endLine);
    out.put("closed", closed);
    out.put("source", source(text));
    out.put("content", content(text));
    List<Object> kids = new ArrayList<>();
    for (NotationElement c : children) {
      kids.add(c.toJson(text));
    }
    out.put("children", kids);
    return out;
  }
}
