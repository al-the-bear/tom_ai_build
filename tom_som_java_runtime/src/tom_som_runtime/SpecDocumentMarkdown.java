package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Generic, meta-data-driven Markdown codec for a TomSpecs document — a faithful
 * port of {@code spec_document_markdown.dart} / {@code spec_document_markdown.py}.
 *
 * <p>A {@code <!-- docspec: -->} header, then one heading per <b>populated</b>
 * section (sparse, in schema order), with each section's machine-readable section
 * path as the first token of its heading. Leaf values live in <b>fenced code
 * blocks</b> whose fence is widened past any backtick run in the value. Form
 * fields are introduced by a {@code <!-- field: name -->} anchor; list items
 * appear as nested {@code …-N} sections.
 *
 * <p>{@link #parse} does <b>not</b> mutate the document — it returns staged values
 * keyed exactly like {@link SpecDocument#toJson} plus a rejection report.
 */
public final class SpecDocumentMarkdown {
  private static final Pattern HEADING_RE = Pattern.compile("^(#{1,6})\\s+(\\S+)");
  private static final Pattern FIELD_ANCHOR_RE =
      Pattern.compile("^<!--\\s*field:\\s*(\\S+)\\s*-->$");
  private static final Pattern FENCE_OPEN_RE = Pattern.compile("^(`{3,})");
  private static final Pattern ITEM_SEG_RE = Pattern.compile("^(.+)-(\\d+)$");

  public final SpecModel model;
  public final SpecDocument document;
  private final SpecReflection reflection;

  public SpecDocumentMarkdown(SpecModel model, SpecDocument document) {
    this.model = model;
    this.document = document;
    this.reflection = new SpecReflection(model);
  }

  private String rootSeg(SpecRoot r) {
    return reflection.rootSegment(r);
  }

  private String fieldSeg(SpecField f) {
    return reflection.fieldSegment(f);
  }

  // --- Export -------------------------------------------------------------

  /**
   * Renders the populated subtree of {@code root} as a schema-conformant Markdown
   * document with a {@code <!-- docspec: -->} header.
   */
  public String exportRoot(SpecRoot root) {
    StringBuilder b = new StringBuilder();
    String seg = rootSeg(root);
    b.append("<!-- docspec: ").append(seg.toLowerCase()).append("/1 -->\n");
    b.append("# ").append(seg).append(" \u2014 ").append(root.title).append('\n');
    SpecClass cls = model.classNamed(root.type);
    if (root.description != null && !root.description.trim().isEmpty()) {
      b.append('\n');
      b.append(root.description.trim()).append('\n');
    }
    if (cls != null) {
      java.util.Set<String> seen = new java.util.HashSet<>();
      seen.add(root.type);
      exportClass(b, cls, seg, 2, seen);
    }
    return b.toString();
  }

  private void exportClass(
      StringBuilder b, SpecClass cls, String basePath, int depth, java.util.Set<String> seenTypes) {
    for (SpecField field : cls.fields) {
      String path = basePath + "/" + fieldSeg(field);
      if (!document.hasValuesUnder(path)) {
        continue;
      }
      SpecFieldKind kind = field.kind;
      if (kind == SpecFieldKind.CONTENT
          || kind == SpecFieldKind.SCALAR
          || kind == SpecFieldKind.ENUM) {
        String value = document.content(path);
        if (value == null) {
          continue;
        }
        heading(b, depth, path, field.name);
        b.append(fence(value, field.contentType != null ? field.contentType : "")).append('\n');
        b.append('\n');
      } else if (kind == SpecFieldKind.FORM) {
        heading(b, depth, path, field.name);
        for (FormFieldSpec ff : field.formFields) {
          String value = document.formField(path, ff.name);
          if (value == null) {
            continue;
          }
          b.append("<!-- field: ").append(ff.name).append(" -->\n");
          b.append(fence(value, "")).append('\n');
          b.append('\n');
        }
      } else if (kind == SpecFieldKind.LIST) {
        SpecClass elem = model.classNamed(field.elementType);
        boolean recursive =
            field.elementType != null && seenTypes.contains(field.elementType);
        heading(b, depth, path, field.name);
        b.append('\n');
        if (elem == null || recursive) {
          continue;
        }
        java.util.Set<String> nextSeen = new java.util.HashSet<>(seenTypes);
        nextSeen.add(field.elementType);
        for (String itemPath : document.listItems(path)) {
          heading(b, depth + 1, itemPath, field.elementType != null ? field.elementType : "item");
          b.append('\n');
          exportClass(b, elem, itemPath, depth + 2, nextSeen);
        }
      } else if (kind == SpecFieldKind.COMPLEX || kind == SpecFieldKind.SECTION) {
        SpecClass nested = model.classNamed(field.type);
        boolean recursive = field.type != null && seenTypes.contains(field.type);
        if (nested == null || recursive) {
          continue;
        }
        heading(b, depth, path, field.name);
        b.append('\n');
        java.util.Set<String> nextSeen = new java.util.HashSet<>(seenTypes);
        nextSeen.add(field.type);
        exportClass(b, nested, path, depth + 1, nextSeen);
      }
    }
  }

  private static void heading(StringBuilder b, int depth, String path, String name) {
    int n = depth > 6 ? 6 : depth;
    for (int i = 0; i < n; i++) {
      b.append('#');
    }
    b.append(' ').append(path).append(" \u2014 ").append(name).append('\n');
  }

  /**
   * A fenced code block holding {@code value} verbatim. The fence is one backtick
   * longer than the longest backtick run in {@code value} (min 3).
   */
  private static String fence(String value, String info) {
    int maxRun = 0;
    int run = 0;
    for (int i = 0; i < value.length(); i++) {
      if (value.charAt(i) == '`') {
        run++;
        if (run > maxRun) {
          maxRun = run;
        }
      } else {
        run = 0;
      }
    }
    int n = (maxRun + 1) >= 3 ? maxRun + 1 : 3;
    StringBuilder fenceBuilder = new StringBuilder();
    for (int i = 0; i < n; i++) {
      fenceBuilder.append('`');
    }
    String f = fenceBuilder.toString();
    StringBuilder parts = new StringBuilder();
    parts.append(f).append(info).append('\n');
    for (String line : splitOnNewline(value)) {
      parts.append(line).append('\n');
    }
    parts.append(f);
    return parts.toString();
  }

  // --- Import -------------------------------------------------------------

  private static final class Pending {
    final int line;
    final String path;
    final String field;
    boolean filled;

    Pending(int line, String path, String field) {
      this.line = line;
      this.path = path;
      this.field = field;
    }

    String anchor() {
      return field != null ? path + " :: " + field : path;
    }
  }

  /**
   * Parses {@code text} into staged values + a rejection report, <b>without</b>
   * mutating the document.
   */
  public SpecMarkdownResult parse(String text) {
    List<String> lines = splitOnNewline(text);
    SpecMarkdownResult result = new SpecMarkdownResult();

    Pending[] pendingBox = new Pending[1];

    int i = 0;
    SpecNodeKind currentKind = null;
    String currentPath = null;
    while (i < lines.size()) {
      String raw = lines.get(i);
      int lineNo = i + 1;
      String trimmed = rstrip(raw);

      // Heading.
      String heading = headingPath(trimmed);
      if (heading != null) {
        flushMissing(pendingBox, result);
        SpecResolution node = reflection.resolve(heading);
        if (node == null) {
          result.rejections.add(
              new SpecMarkdownRejection(
                  lineNo,
                  SpecMarkdownRejectReason.UNKNOWN_SECTION,
                  "section path does not resolve against the model",
                  heading));
          currentKind = null;
          currentPath = null;
          i++;
          continue;
        }
        currentKind = node.kind;
        currentPath = heading;
        result.rootPrefixes.add(heading.split("/", -1)[0]);
        if (node.isValueLeaf()) {
          pendingBox[0] = new Pending(lineNo, heading, null);
        }
        i++;
        continue;
      }

      // Form-field anchor.
      String fieldName = fieldAnchor(trimmed);
      if (fieldName != null) {
        flushMissing(pendingBox, result);
        if (currentPath == null || currentKind != SpecNodeKind.FORM) {
          result.rejections.add(
              new SpecMarkdownRejection(
                  lineNo,
                  SpecMarkdownRejectReason.KIND_MISMATCH,
                  "form-field anchor outside a `@Form` section",
                  fieldName));
          i++;
          continue;
        }
        pendingBox[0] = new Pending(lineNo, currentPath, fieldName);
        i++;
        continue;
      }

      // Fence opener.
      Integer fenceLen = fenceOpen(trimmed);
      if (fenceLen != null) {
        List<String> body = new ArrayList<>();
        int j = i + 1;
        StringBuilder closerBuilder = new StringBuilder();
        for (int c = 0; c < fenceLen; c++) {
          closerBuilder.append('`');
        }
        String closer = closerBuilder.toString();
        while (j < lines.size() && !rstrip(lines.get(j)).equals(closer)) {
          body.add(lines.get(j));
          j++;
        }
        String value = String.join("\n", body);
        Pending pending = pendingBox[0];
        if (pending == null) {
          result.rejections.add(
              new SpecMarkdownRejection(
                  lineNo,
                  SpecMarkdownRejectReason.ORPHAN_BLOCK,
                  "fenced value with no owning section or field",
                  null));
        } else if (pending.field != null) {
          result.forms.computeIfAbsent(pending.path, k -> new LinkedHashMap<>())
              .put(pending.field, value);
          pending.filled = true;
        } else {
          result.content.put(pending.path, value);
          pending.filled = true;
        }
        pendingBox[0] = null;
        i = j < lines.size() ? j + 1 : j;
        continue;
      }

      i++;
    }
    flushMissing(pendingBox, result);

    reconstructLists(result);
    return result;
  }

  private static void flushMissing(Pending[] pendingBox, SpecMarkdownResult result) {
    Pending pending = pendingBox[0];
    if (pending != null && !pending.filled) {
      result.rejections.add(
          new SpecMarkdownRejection(
              pending.line,
              SpecMarkdownRejectReason.MISSING_VALUE,
              "no fenced value followed this anchor",
              pending.anchor()));
    }
    pendingBox[0] = null;
  }

  /**
   * Recovers list membership from the leaf paths: any {@code <base>-<n>} segment
   * whose {@code <base>} ancestor resolves to a list field denotes item
   * {@code <n>} of that list.
   */
  private void reconstructLists(SpecMarkdownResult result) {
    Map<String, List<String>> items = new LinkedHashMap<>();
    Map<String, Integer> seq = new LinkedHashMap<>();

    for (String p : result.content.keySet()) {
      scanForLists(p, items, seq);
    }
    for (String p : result.forms.keySet()) {
      scanForLists(p, items, seq);
    }

    for (Map.Entry<String, List<String>> e : items.entrySet()) {
      Map<String, Object> spec = new LinkedHashMap<>();
      Integer s = seq.get(e.getKey());
      spec.put("seq", s != null ? s : e.getValue().size());
      spec.put("items", e.getValue());
      result.lists.put(e.getKey(), spec);
    }
  }

  private void scanForLists(
      String path, Map<String, List<String>> items, Map<String, Integer> seq) {
    String[] segs = path.split("/", -1);
    String prefix = segs[0];
    for (int k = 1; k < segs.length; k++) {
      String seg = segs[k];
      Matcher m = ITEM_SEG_RE.matcher(seg);
      if (m.matches()) {
        String listPath = prefix + "/" + m.group(1);
        String itemPath = prefix + "/" + seg;
        SpecResolution node = reflection.resolve(listPath);
        if (node != null && node.kind == SpecNodeKind.LIST) {
          List<String> bucket = items.computeIfAbsent(listPath, key -> new ArrayList<>());
          if (!bucket.contains(itemPath)) {
            bucket.add(itemPath);
          }
          int n = Integer.parseInt(m.group(2));
          if (n > seq.getOrDefault(listPath, 0)) {
            seq.put(listPath, n);
          }
        }
      }
      prefix = prefix + "/" + seg;
    }
  }

  // --- helpers ------------------------------------------------------------

  private static String headingPath(String line) {
    Matcher m = HEADING_RE.matcher(line);
    return m.lookingAt() ? m.group(2) : null;
  }

  private static String fieldAnchor(String line) {
    Matcher m = FIELD_ANCHOR_RE.matcher(line.trim());
    return m.matches() ? m.group(1) : null;
  }

  private static Integer fenceOpen(String line) {
    Matcher m = FENCE_OPEN_RE.matcher(line);
    return m.lookingAt() ? m.group(1).length() : null;
  }

  private static String rstrip(String s) {
    int end = s.length();
    while (end > 0 && Character.isWhitespace(s.charAt(end - 1))) {
      end--;
    }
    return s.substring(0, end);
  }

  private static List<String> splitOnNewline(String value) {
    List<String> out = new ArrayList<>();
    int start = 0;
    for (int i = 0; i < value.length(); i++) {
      if (value.charAt(i) == '\n') {
        out.add(value.substring(start, i));
        start = i + 1;
      }
    }
    out.add(value.substring(start));
    return out;
  }
}
