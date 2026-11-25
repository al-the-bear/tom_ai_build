package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The readable header line of a stripped rendition (SOM §11.1): {@code <!--
 * readable: drop=…; unmark=…; appendix=…; appendix-references; headings=divs;
 * of=<file>@<revision>; commit=<sha>[+dirty] -->}. Parts that do not apply are
 * left out; {@link #format} and {@link #parse} are inverse.
 */
public final class SpecReadableHeader {
  private static final Pattern LINE = Pattern.compile("^<!--\\s*readable:(.*)-->$");

  /** The switches the rendition was stripped with. */
  public final SpecStripOptions options;
  /** The source it was made from, or {@code null}. */
  public final SpecReadableSource source;

  public SpecReadableHeader(SpecStripOptions options) {
    this(options, null);
  }

  public SpecReadableHeader(SpecStripOptions options, SpecReadableSource source) {
    this.options = options;
    this.source = source;
  }

  /** The header line. */
  public String format() {
    SpecStripOptions o = options;
    SpecReadableSource s = source;
    List<String> parts = new ArrayList<>();
    if (!o.drop.isEmpty()) {
      parts.add("drop=" + String.join(",", SpecStripOptions.ordered(o.drop)));
    }
    if (!o.unmark.isEmpty()) {
      parts.add("unmark=" + String.join(",", SpecStripOptions.ordered(o.unmark)));
    }
    if (!o.appendix.isEmpty()) {
      parts.add("appendix=" + String.join(",", SpecStripOptions.ordered(o.appendix)));
    }
    if (o.appendixReferences) {
      parts.add("appendix-references");
    }
    if (o.headingDivs) {
      parts.add("headings=divs");
    }
    if (s != null) {
      parts.add("of=" + s.file + (s.revision != null ? "@" + s.revision : ""));
    }
    if (s != null && s.commit != null) {
      parts.add("commit=" + s.commit + (s.dirty ? "+dirty" : ""));
    }
    return parts.isEmpty()
        ? "<!-- readable: -->"
        : "<!-- readable: " + String.join("; ", parts) + " -->";
  }

  /** {@code line} read as a readable header, or {@code null}. */
  public static SpecReadableHeader parse(String line) {
    Matcher m = LINE.matcher(SpecNotation.jsTrim(line));
    if (!m.matches()) {
      return null;
    }
    List<String> drop = new ArrayList<>();
    List<String> unmark = new ArrayList<>();
    List<String> appendix = new ArrayList<>();
    boolean refs = false;
    boolean divs = false;
    String file = null;
    String revision = null;
    String commit = null;
    boolean dirty = false;
    for (String raw : m.group(1).split(";", -1)) {
      String part = SpecNotation.jsTrim(raw);
      if (part.isEmpty()) {
        continue;
      }
      int eq = part.indexOf('=');
      String key = eq < 0 ? part : part.substring(0, eq);
      String value = eq < 0 ? "" : part.substring(eq + 1);
      if (key.equals("drop")) {
        drop.add(value);
      } else if (key.equals("unmark")) {
        unmark.add(value);
      } else if (key.equals("appendix")) {
        appendix.add(value);
      } else if (key.equals("appendix-references") && eq < 0) {
        refs = true;
      } else if (key.equals("headings") && value.equals("divs")) {
        divs = true;
      } else if (key.equals("of")) {
        int at = value.lastIndexOf('@');
        file = at < 0 ? value : value.substring(0, at);
        revision = at < 0 ? null : value.substring(at + 1);
      } else if (key.equals("commit")) {
        dirty = value.endsWith("+dirty");
        commit = dirty ? value.substring(0, value.length() - 6) : value;
      } else {
        return null;
      }
    }
    if (file == null && commit != null) {
      return null;
    }
    try {
      return new SpecReadableHeader(
          SpecStripOptions.fromNames(drop, unmark, appendix, refs, divs),
          file == null ? null : new SpecReadableSource(file, revision, commit, dirty));
    } catch (SpecStripUsageError e) {
      return null;
    }
  }
}
