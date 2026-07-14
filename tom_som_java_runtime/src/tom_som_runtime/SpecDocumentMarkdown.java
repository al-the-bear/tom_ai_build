package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * SpecDocumentMarkdown — DocSpecs-conform Markdown codec for a TomSpecs
 * document (DR1 §1), a faithful port of
 * {@code tom_som_go_runtime/spec_document_markdown.go} (itself a port of the
 * Dart/TypeScript reference codec).
 *
 * <p>The generated/authored {@code *.md} <b>is a genuine DocSpecs document</b>:
 * line 1 is the {@code <!-- docspec: <schema-id>/<version> -->} declaration,
 * every populated section is one markdown heading whose machine-readable
 * identity is the DocSpecs headline comment {@code <!--[SECTION-ID]-->} and
 * whose text is the human-readable Title-Case member name. Content values are
 * <b>normal markdown text</b> under their heading (no fences, no anchors);
 * {@code @Form} sections use the DocSpecs plain-text {@code FieldName: value}
 * format; list items are sub-headings carrying the item's section id (stored
 * id, else the {@code @SectionIdPattern} resolved with the 1-based position —
 * {@code GOAL-ITEM-xxx} → {@code GOAL-ITEM-1} — else {@code <member>-<pos>})
 * directly under the owning section — the list container gets no heading of
 * its own. Id-less members are <b>transparent</b> (mirroring the DR3 schema
 * generator): a transparent value member's text or form block is the owner's
 * body region, emitted without a heading and bound at its own path; a
 * transparent section/complex member never heads — its id-bearing descendants
 * hoist to the owner's child level (paths keep the transparent segments).
 * Section/complex headings without a field-level {@code @SectionId} carry the
 * target class's {@code @SectionId}.
 *
 * <p>Escaping (DR1 §1.3): a content line starting with {@code #} at column 0
 * is emitted as {@code \#} (and a leading {@code \#}… run gains one more
 * backslash), except inside fenced code blocks, which shield their lines
 * verbatim. Consecutive blank lines are collapsed to one on emit; parse trims
 * each value of leading/trailing blank lines and does not re-collapse.
 *
 * <p>The codec is free of any UI: it reads from / resolves against a
 * {@link SpecModel} (through the {@link SomMetaBridge#buildSomMetaTree}
 * metadata tree) and a {@link SpecDocument}. {@link #parse} does <b>not</b>
 * mutate the document — it returns staged values keyed exactly like
 * {@link SpecDocument#toJson} plus a rejection report; the caller applies
 * them. Anything that cannot be mapped — an unknown section id, a child
 * heading under a value leaf, orphaned text — is collected into
 * {@link SpecMarkdownResult#rejections} rather than dropped (DR1 §1.7).
 *
 * <p>Java conventions (DR22): where Go returns an error, {@link #exportRoot}
 * throws {@link IllegalStateException} (the unterminated-fence case); a null
 * anchor stands in for Go's empty string.
 */
public final class SpecDocumentMarkdown {
  // Shared with the parser and the DocSpecs validator.
  static final Pattern HEADING_LINE = Pattern.compile("^(#+)\\s+(.*)$");
  static final Pattern HEADLINE_COMMENT =
      Pattern.compile("^<!--\\[([^\\]]+)\\]-->\\s*(.*)$");
  static final Pattern DOCSPEC_COMMENT = Pattern.compile("^<!--\\s*docspec:.*-->\\s*$");

  // A line the emitter must escape: an optional run of backslashes followed by
  // `#` at column 0 (the escape itself must survive the round-trip).
  private static final Pattern ESCAPABLE = Pattern.compile("^\\\\*#");

  // A line that would parse as a form-field label: `Word:` at column 0
  // (optionally already space-prefixed — each emit pass adds one more space).
  private static final Pattern LABEL_SHAPED = Pattern.compile("^ *[A-Za-z][A-Za-z0-9_]*:");

  private static final Pattern FIELD_LABEL =
      Pattern.compile("^([A-Za-z][A-Za-z0-9_]*): ?(.*)$");
  private static final Pattern CONTINUATION_LABEL =
      Pattern.compile("^ +[A-Za-z][A-Za-z0-9_]*:");
  private static final Pattern ESCAPED_HEADING = Pattern.compile("^\\\\+#");

  private static final Pattern TRAILING_WS = Pattern.compile("\\s+$");
  private static final Pattern BLANK_RUN = Pattern.compile("\\n{3,}");
  private static final Pattern LEADING_NL = Pattern.compile("^\\n+");
  private static final Pattern TRAILING_NL = Pattern.compile("\\n+$");
  private static final Pattern LEADING_BLANK_LN = Pattern.compile("^([ \\t]*\\n)+");
  private static final Pattern TRAILING_BLANK_LN = Pattern.compile("(\\n[ \\t]*)+$");

  public final SpecModel model;
  public final SpecDocument document;
  // Metadata trees per root type, built lazily (DR8's generated facades will
  // hand these in directly; until then the bridge derives them).
  private final Map<String, SomMetaTree> trees = new LinkedHashMap<>();

  /** Binds {@code model} and {@code document} to the codec. */
  public SpecDocumentMarkdown(SpecModel model, SpecDocument document) {
    this.model = model;
    this.document = document;
  }

  private SomMetaTree treeFor(String rootType) {
    SomMetaTree tree = trees.get(rootType);
    if (tree == null) {
      tree = SomMetaBridge.buildSomMetaTree(model, rootType);
      trees.put(rootType, tree);
    }
    return tree;
  }

  // --- Naming helpers (DR1 §1.2 / §1.5) --------------------------------------

  /**
   * Expands a camel/Pascal-case identifier into Title Case:
   * {@code introductionAndScope} / {@code DemoItem} →
   * {@code Introduction And Scope} / {@code Demo Item}.
   */
  public static String titleCase(String name) {
    List<String> words = new ArrayList<>();
    StringBuilder buf = new StringBuilder();
    for (int i = 0; i < name.length(); i++) {
      char c = name.charAt(i);
      if (Character.isUpperCase(c) && buf.length() > 0) {
        words.add(buf.toString());
        buf.setLength(0);
      }
      buf.append(c);
    }
    if (buf.length() > 0) {
      words.add(buf.toString());
    }
    List<String> out = new ArrayList<>();
    for (String w : words) {
      if (w.isEmpty()) {
        out.add(w);
      } else {
        out.add(Character.toUpperCase(w.charAt(0)) + w.substring(1));
      }
    }
    return String.join(" ", out);
  }

  private static final Pattern KEBAB_SPACE = Pattern.compile("[\\s_]+");
  private static final Pattern KEBAB_DROP = Pattern.compile("[^A-Za-z0-9-]");

  /**
   * Derives the DocSpecs schema id of a {@code @Document} name (DR1 §1.1):
   * {@code Demo Document} → {@code demo-document}.
   */
  public static String kebabCase(String title) {
    String s = title.trim();
    s = KEBAB_SPACE.matcher(s).replaceAll("-");
    s = KEBAB_DROP.matcher(s).replaceAll("");
    return s.toLowerCase();
  }

  /**
   * The item heading title stem: Title-Case element class name with a trailing
   * {@code Entry} dropped (DR1 §1.5, normative).
   */
  public static String itemTitleStem(String elementClassName) {
    String stem = elementClassName;
    if (stem.length() > 5 && stem.endsWith("Entry")) {
      stem = stem.substring(0, stem.length() - 5);
    }
    return titleCase(stem);
  }

  /**
   * The {@code FieldName} label written for a form field: the model field name
   * with the first letter upper-cased (DR1 §1.4.1).
   */
  public static String formLabel(String fieldName) {
    if (fieldName.isEmpty()) {
      return fieldName;
    }
    return Character.toUpperCase(fieldName.charAt(0)) + fieldName.substring(1);
  }

  // --- Export (DR1 §1.1–§1.6) -------------------------------------------------

  /**
   * The section id written into (and matched from) a heading for {@code node}
   * (DR1 §1.2/§1.6): the field-level {@code @SectionId} when present; for
   * section/complex nodes whose field carries none, the target <b>class</b>'s
   * {@code @SectionId} (the id the DR3 schema types are keyed by); else the
   * path segment (the member name).
   */
  private String headingIdOf(SomMetaNode node) {
    if (node.sectionId != null && !node.sectionId.isEmpty()) {
      return node.sectionId;
    }
    if (SomMetaKind.SECTION.equals(node.kind) || SomMetaKind.COMPLEX.equals(node.kind)) {
      SpecClass cls = model.classNamed(node.className);
      if (cls != null && cls.sectionId != null && !cls.sectionId.isEmpty()) {
        return cls.sectionId;
      }
    }
    return node.segment();
  }

  // --- Transparency (DR1 §1.2, mirroring the DR3 schema generator) -------------
  //
  // The DR3 `docspecs-schema` generator is normative: only **section-bearing**
  // nodes (those with a real `@SectionId`, field- or class-level) become
  // section types; id-less members are *transparent* — they are not sections
  // of their own. The markdown format mirrors that exactly:
  //
  //   - a transparent value member (content/scalar/enum/form without an id)
  //     is emitted headinglessly into its owner's *body region* (text, or a
  //     `FieldName: value` form block);
  //   - a transparent section/complex member gets no heading; its id-bearing
  //     descendants surface as the owner's direct child headings (the
  //     schema's "nearest section-bearing descendant" hoisting), with document
  //     paths still running through the transparent segments;
  //   - lists are never transparent — the container never heads, the items
  //     always do (stored id / `@SectionIdPattern` / `<member>-<pos>`).
  //
  // Principled canonicalisation losses (documented, accepted): multiple
  // transparent content members of one owner merge into the first on parse,
  // and a form-field label colliding across an owner's transparent forms
  // binds to the nearest form in slot order.

  /** A body slot / effective child: the node plus its relative path. */
  private static final class NodeRel {
    final SomMetaNode node;
    final String rel;

    NodeRel(SomMetaNode node, String rel) {
      this.node = node;
      this.rel = rel;
    }
  }

  /**
   * Whether {@code n} is a section/complex member with no field- or
   * class-level {@code @SectionId}: heading-less, its children hoist to the
   * owner.
   */
  private boolean isTransparentSection(SomMetaNode n) {
    if (!SomMetaKind.SECTION.equals(n.kind) && !SomMetaKind.COMPLEX.equals(n.kind)) {
      return false;
    }
    if (n.sectionId != null && !n.sectionId.isEmpty()) {
      return false;
    }
    SpecClass cls = model.classNamed(n.className);
    return cls == null || cls.sectionId == null || cls.sectionId.isEmpty();
  }

  /**
   * Whether {@code n} is a value member (content/scalar/enum/form) with no
   * {@code @SectionId}: emitted into the owner's body region instead of under
   * an own heading.
   */
  private static boolean isTransparentValue(SomMetaNode n) {
    return (n.sectionId == null || n.sectionId.isEmpty())
        && (SomMetaKind.CONTENT.equals(n.kind)
            || SomMetaKind.SCALAR.equals(n.kind)
            || SomMetaKind.ENUM_VALUE.equals(n.kind)
            || SomMetaKind.FORM.equals(n.kind));
  }

  /**
   * The ordered <i>body slots</i> of {@code node}: every transparent value
   * member and every transparent section (whose own path may carry body text),
   * collected depth-first through transparent sections. These are the value
   * positions that share the owner's heading body.
   */
  private List<NodeRel> bodySlots(SomMetaNode node) {
    List<NodeRel> out = new ArrayList<>();
    collectBodySlots(node, "", out);
    return out;
  }

  private void collectBodySlots(SomMetaNode n, String prefix, List<NodeRel> out) {
    for (SomMetaNode child : n.children) {
      if (child.recursive) {
        continue;
      }
      String rel = prefix.isEmpty() ? child.segment() : prefix + "/" + child.segment();
      if (isTransparentValue(child)) {
        out.add(new NodeRel(child, rel));
      } else if (isTransparentSection(child)) {
        out.add(new NodeRel(child, rel));
        collectBodySlots(child, rel, out);
      }
    }
  }

  /**
   * The ordered <i>effective children</i> of {@code node}: every
   * section-bearing child and every list, hoisted through transparent sections
   * — exactly the headings (and item-heading owners) the DR3 schema knows at
   * this position. Each entry carries the relative path from {@code node}
   * (which runs through the transparent segments).
   */
  private List<NodeRel> effectiveChildren(SomMetaNode node) {
    List<NodeRel> out = new ArrayList<>();
    collectEffectiveChildren(node, "", out);
    return out;
  }

  private void collectEffectiveChildren(SomMetaNode n, String prefix, List<NodeRel> out) {
    for (SomMetaNode child : n.children) {
      if (child.recursive) {
        continue;
      }
      String rel = prefix.isEmpty() ? child.segment() : prefix + "/" + child.segment();
      if (isTransparentValue(child)) {
        continue; // body region
      }
      if (isTransparentSection(child)) {
        collectEffectiveChildren(child, rel, out);
      } else {
        out.add(new NodeRel(child, rel));
      }
    }
  }

  /**
   * Renders the populated subtree of {@code root} as a DocSpecs-conform
   * Markdown document. Throws {@link IllegalStateException} when a content
   * value contains an unterminated fenced code block (which would shield the
   * remainder of the document from heading detection and break the
   * round-trip).
   */
  public String exportRoot(SpecRoot root) {
    SomMetaTree tree = treeFor(root.type);
    SomMetaNode node = tree.root;
    StringBuilder b = new StringBuilder();
    writeln(b, "<!-- docspec: " + kebabCase(root.title) + "/"
        + model.modelVersionString() + " -->");
    String rootSeg = node.segment();
    writeHeading(b, 1, rootSeg, root.title);
    writeSectionBody(b, node, rootSeg);
    writeChildren(b, node, rootSeg, 2);
    return b.toString();
  }

  /**
   * Writes the body region of a section heading: the section path's own
   * content value plus every transparent body slot (id-less content text and
   * form blocks, hoisted through transparent sections) in model order.
   */
  private void writeSectionBody(StringBuilder b, SomMetaNode node, String path) {
    String value = document.content(path);
    if (value != null) {
      writeBody(b, value, path);
    }
    for (NodeRel slot : bodySlots(node)) {
      String slotPath = path + "/" + slot.rel;
      if (SomMetaKind.FORM.equals(slot.node.kind)) {
        if (formHasValues(slot.node, slotPath)) {
          writeForm(b, slot.node, slotPath);
        }
      } else {
        String slotValue = document.content(slotPath);
        if (slotValue != null) {
          writeBody(b, slotValue, slotPath);
        }
      }
    }
  }

  private void writeChildren(StringBuilder b, SomMetaNode node, String basePath, int depth) {
    for (NodeRel entry : effectiveChildren(node)) {
      SomMetaNode child = entry.node;
      String path = basePath + "/" + entry.rel;
      if (!document.hasValuesUnder(path)) {
        continue;
      }
      if (SomMetaKind.CONTENT.equals(child.kind)
          || SomMetaKind.SCALAR.equals(child.kind)
          || SomMetaKind.ENUM_VALUE.equals(child.kind)) {
        String value = document.content(path);
        if (value == null) {
          continue;
        }
        writeHeading(b, depth, headingIdOf(child), titleOf(child));
        writeBody(b, value, path);
      } else if (SomMetaKind.FORM.equals(child.kind)) {
        if (!formHasValues(child, path)) {
          continue;
        }
        writeHeading(b, depth, headingIdOf(child), titleOf(child));
        writeForm(b, child, path);
      } else if (SomMetaKind.SECTION.equals(child.kind)
          || SomMetaKind.COMPLEX.equals(child.kind)) {
        writeHeading(b, depth, headingIdOf(child), titleOf(child));
        writeSectionBody(b, child, path);
        writeChildren(b, child, path, depth + 1);
      } else if (SomMetaKind.LIST.equals(child.kind)) {
        writeListItems(b, child, path, depth);
      }
    }
  }

  /**
   * Emits the items of list {@code node} as headings <b>at the owner's child
   * level</b> — the container itself gets no heading (DR1 §1.2).
   */
  private void writeListItems(StringBuilder b, SomMetaNode node, String listPath, int depth) {
    List<String> items = document.listItems(listPath);
    SomMetaNode element = node.elementNode;
    String stemSource = element != null ? element.className : node.typeName;
    String stem = itemTitleStem(stemSource);
    String pattern = node.sectionIdPattern;
    if ((pattern == null || pattern.isEmpty()) && element != null) {
      pattern = element.sectionIdPattern;
    }
    for (int i = 0; i < items.size(); i++) {
      String itemPath = items.get(i);
      int pos = i + 1;
      // DR1 §1.2: an anonymous item's heading id is the resolved
      // `@SectionIdPattern` id (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`); only
      // pattern-less lists fall back to `<member>-<pos>`.
      String stored = document.itemSectionId(itemPath);
      String itemId;
      if (stored != null) {
        itemId = stored;
      } else if (pattern != null && !pattern.isEmpty()) {
        itemId = String.join(String.valueOf(pos), splitAll(pattern, "xxx"));
      } else {
        String member = node.memberName;
        if (member == null || member.isEmpty()) {
          member = node.segment();
        }
        itemId = member + "-" + pos;
      }
      writeHeading(b, depth, itemId, stem + " " + pos);
      if (element == null) {
        // Scalar list: the item's value is its body.
        String value = document.content(itemPath);
        writeBody(b, value == null ? "" : value, itemPath);
      } else {
        writeSectionBody(b, element, itemPath);
        if (!element.recursive) {
          writeChildren(b, element, itemPath, depth + 1);
        }
      }
    }
  }

  private boolean formHasValues(SomMetaNode node, String path) {
    if (node.form == null) {
      return false;
    }
    for (SomFormFieldMeta f : node.form.fields) {
      if (document.formField(path, f.name) != null) {
        return true;
      }
    }
    return false;
  }

  private void writeForm(StringBuilder b, SomMetaNode node, String path) {
    List<SomFormFieldMeta> fields =
        node.form != null ? node.form.fields : new ArrayList<>();
    for (SomFormFieldMeta f : fields) {
      String value = document.formField(path, f.name);
      if (value == null) {
        continue;
      }
      String prepared = prepareValue(value, path);
      String[] lines = splitLines(prepared);
      writeln(b, formLabel(f.name) + ": " + lines[0]);
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i];
        // §1.4.3 generalised: any continuation line that could be mistaken
        // for a field-label line gains one leading space; parse strips it.
        if (LABEL_SHAPED.matcher(line).find()) {
          writeln(b, " " + line);
        } else {
          writeln(b, line);
        }
      }
    }
    writeln(b, "");
  }

  /**
   * Writes {@code ## <!--[ID]--> Title} at {@code depth}. DR1 §1.2 is
   * normative — heading level = 1 + section depth, <b>uncapped</b>: deep
   * models (the Solution Blueprint nests past markdown's native 6 levels) keep
   * their structure; the parse grammar accepts {@code #{7,}} accordingly.
   * Capping would silently flatten distinct nesting positions into siblings
   * and break schema validation.
   */
  private static void writeHeading(StringBuilder b, int depth, String id, String title) {
    writeln(b, "#".repeat(depth) + " <!--[" + id + "]--> " + title);
    writeln(b, "");
  }

  /**
   * Writes {@code value} as a section body followed by a blank line; no-op for
   * blank values.
   */
  private void writeBody(StringBuilder b, String value, String path) {
    String prepared = prepareValue(value, path);
    if (prepared.isEmpty()) {
      return;
    }
    writeln(b, prepared);
    writeln(b, "");
  }

  /**
   * The emit-side value normalisation (DR1 §1.3): collapse 2+ blank lines to
   * one, trim leading/trailing blank lines, escape heading-like lines outside
   * fences. Throws {@link IllegalStateException} for an unterminated fence.
   */
  private String prepareValue(String value, String path) {
    String collapsed = BLANK_RUN.matcher(value).replaceAll("\n\n");
    collapsed = LEADING_NL.matcher(collapsed).replaceAll("");
    collapsed = TRAILING_NL.matcher(collapsed).replaceAll("");
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    List<String> out = new ArrayList<>();
    for (String line : splitLines(collapsed)) {
      if (fence.inFence()) {
        out.add(line); // §1.3.4: fences shield their lines.
      } else if (ESCAPABLE.matcher(line).find()) {
        out.add("\\" + line);
      } else {
        out.add(line);
      }
      fence.feed(line);
    }
    if (fence.inFence()) {
      throw new IllegalStateException(
          "content at \"" + path + "\" contains an unterminated fenced "
              + "code block; it cannot be represented in the DocSpecs markdown format");
    }
    return String.join("\n", out);
  }

  private static String titleOf(SomMetaNode node) {
    String name = node.memberName;
    if (name == null || name.isEmpty()) {
      name = node.className;
    }
    return titleCase(name);
  }

  private static void writeln(StringBuilder b, String text) {
    b.append(text).append('\n');
  }

  /** Splits {@code value} on {@code \n}, keeping trailing empty parts. */
  private static String[] splitLines(String value) {
    return value.split("\n", -1);
  }

  /** Splits {@code value} on {@code sep}, keeping trailing empty parts. */
  private static String[] splitAll(String value, String sep) {
    return value.split(Pattern.quote(sep), -1);
  }

  // --- Import (DR1 §1.7) --------------------------------------------------------

  /**
   * Parses {@code text} into staged values + a rejection report,
   * <b>without</b> mutating the document. The caller applies the result as a
   * full overwrite.
   */
  public SpecMarkdownResult parse(String text) {
    MdParser p = new MdParser(this);
    p.run(splitLines(text));
    SpecMarkdownResult result = new SpecMarkdownResult();
    result.content.putAll(p.content);
    result.forms.putAll(p.forms);
    result.lists.putAll(p.listsJson());
    result.rejections.addAll(p.rejections);
    result.rootPrefixes.addAll(p.rootPrefixes);
    return result;
  }

  /**
   * One open section during the parse: its heading level, resolved node (null
   * for an unresolvable/ignored section), path, and accumulated body lines.
   */
  private static final class MdFrame {
    final int level;
    final SomMetaNode node;
    final String path;
    final int line;
    final boolean ignored;
    final List<String> body = new ArrayList<>();

    MdFrame(int level, SomMetaNode node, String path, int line, boolean ignored) {
      this.level = level;
      this.node = node;
      this.path = path;
      this.line = line;
      this.ignored = ignored;
    }
  }

  /**
   * Per-list bookkeeping while parsing: ordered item paths, stored ids, and
   * the highest item number handed out (drives both fresh numbers for
   * stored-id items and the resulting seq).
   */
  private static final class MdListState {
    final List<String> items = new ArrayList<>();
    final Map<String, String> ids = new LinkedHashMap<>();
    int maxN;
  }

  private static final class MdParser {
    final SpecDocumentMarkdown codec;
    final Map<String, String> content = new LinkedHashMap<>();
    final Map<String, Map<String, String>> forms = new LinkedHashMap<>();
    final Map<String, MdListState> lists = new LinkedHashMap<>();
    final List<String> listOrder = new ArrayList<>();
    final List<SpecMarkdownRejection> rejections = new ArrayList<>();
    final List<String> rootPrefixes = new ArrayList<>();
    final List<MdFrame> stack = new ArrayList<>();
    final MarkdownFenceTracker fence = new MarkdownFenceTracker();
    // Rolling pointer into a body region's transparent form slots — labels
    // bind to the nearest form at or after the last hit (wrapping), so
    // repeated field names across an owner's transparent forms follow emit
    // order.
    int currentFormIdx;

    MdParser(SpecDocumentMarkdown codec) {
      this.codec = codec;
    }

    void run(String[] lines) {
      for (int i = 0; i < lines.length; i++) {
        String raw = lines[i];
        int lineNo = i + 1;
        String trimmed = TRAILING_WS.matcher(raw).replaceAll("");

        if (!fence.inFence()) {
          if (stack.isEmpty() && DOCSPEC_COMMENT.matcher(trimmed).matches()) {
            continue; // §1.1 header — informational.
          }
          Matcher h = HEADING_LINE.matcher(trimmed);
          if (h.matches()) {
            closeTo(h.group(1).length());
            openHeading(h.group(1).length(), h.group(2), lineNo);
            continue;
          }
        }
        if (!stack.isEmpty()) {
          stack.get(stack.size() - 1).body.add(raw);
        } else if (!trimmed.isEmpty()) {
          rejections.add(new SpecMarkdownRejection(
              lineNo,
              SpecMarkdownRejectReason.ORPHAN_CONTENT,
              "text before the document root heading",
              null));
        }
        fence.feed(raw);
      }
      closeTo(1);
      if (!stack.isEmpty()) {
        finalizeFrame(pop());
      }
    }

    MdFrame pop() {
      return stack.remove(stack.size() - 1);
    }

    /** Pops (and finalizes) every frame at {@code level} or deeper. */
    void closeTo(int level) {
      while (!stack.isEmpty() && stack.get(stack.size() - 1).level >= level) {
        finalizeFrame(pop());
      }
    }

    void openHeading(int level, String rest, int lineNo) {
      Matcher m = HEADLINE_COMMENT.matcher(rest.trim());
      if (!m.matches()) {
        rejections.add(new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.MALFORMED_HEADING,
            "heading carries no <!--[SECTION-ID]--> headline comment",
            rest.trim()));
        stack.add(new MdFrame(level, null, null, lineNo, true));
        return;
      }
      String id = m.group(1);

      if (stack.isEmpty()) {
        openRoot(level, id, lineNo);
        return;
      }

      MdFrame parent = stack.get(stack.size() - 1);
      if (parent.ignored) {
        rejections.add(new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.UNKNOWN_SECTION,
            "section nested under an unresolvable parent",
            id));
        stack.add(new MdFrame(level, null, null, lineNo, true));
        return;
      }
      SomMetaNode pNode = parent.node;
      if (pNode == null || isValueLeaf(pNode.kind)) {
        rejections.add(new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.KIND_MISMATCH,
            "child heading under a value-leaf or form section",
            id));
        stack.add(new MdFrame(level, null, null, lineNo, true));
        return;
      }

      // 1. A regular (non-list) *effective* child — section-bearing children
      //    hoisted through transparent sections — whose heading id (field/class
      //    section id) matches. Transparent value members never head, so they
      //    never match here; the bound path runs through transparent segments.
      List<NodeRel> effective = codec.effectiveChildren(pNode);
      for (NodeRel entry : effective) {
        if (!SomMetaKind.LIST.equals(entry.node.kind)
            && codec.headingIdOf(entry.node).equals(id)) {
          stack.add(new MdFrame(
              level, entry.node, parent.path + "/" + entry.rel, lineNo, false));
          return;
        }
      }

      // 2. A list item: anonymous (`<member>-<n>` or the pattern with a numeric
      //    sequence, e.g. `GOAL-ITEM-3`), pattern-shaped stored id, or
      //    (fallback) any id when the parent has exactly one effective list.
      List<NodeRel> listChildren = new ArrayList<>();
      for (NodeRel entry : effective) {
        if (SomMetaKind.LIST.equals(entry.node.kind)) {
          listChildren.add(entry);
        }
      }
      for (NodeRel entry : listChildren) {
        SomMetaNode lc = entry.node;
        String listPath = parent.path + "/" + entry.rel;
        String member = lc.memberName;
        if (member == null || member.isEmpty()) {
          member = lc.segment();
        }
        Matcher anon = Pattern
            .compile("^" + Pattern.quote(member) + "-([0-9]+)$")
            .matcher(id);
        if (anon.matches()) {
          openItem(level, listPath, lc, Integer.parseInt(anon.group(1)), null, true, lineNo);
          return;
        }
        SomMetaNode element = lc.elementNode;
        String pattern = lc.sectionIdPattern;
        if ((pattern == null || pattern.isEmpty()) && element != null) {
          pattern = element.sectionIdPattern;
        }
        if (pattern != null && !pattern.isEmpty()) {
          // Canonical anonymous id: the pattern with `xxx` as a number —
          // parses back as item <n>, NOT as a stored id (DR1 §1.2
          // round-trip).
          String[] parts = splitAll(pattern, "xxx");
          if (parts.length == 2) {
            Matcher numbered = Pattern
                .compile("^" + Pattern.quote(parts[0]) + "([0-9]+)"
                    + Pattern.quote(parts[1]) + "$")
                .matcher(id);
            if (numbered.matches()) {
              openItem(level, listPath, lc, Integer.parseInt(numbered.group(1)),
                  null, true, lineNo);
              return;
            }
          }
          if (patternMatches(pattern, id)) {
            openItem(level, listPath, lc, 0, id, false, lineNo);
            return;
          }
        }
      }
      if (listChildren.size() == 1) {
        NodeRel entry = listChildren.get(0);
        openItem(level, parent.path + "/" + entry.rel, entry.node, 0, id, false, lineNo);
        return;
      }

      rejections.add(new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.UNKNOWN_SECTION,
          "section id does not resolve against the schema tree at this "
              + "position (under \"" + parent.path + "\")",
          id));
      stack.add(new MdFrame(level, null, null, lineNo, true));
    }

    void openRoot(int level, String id, int lineNo) {
      for (SpecRoot root : codec.model.roots) {
        String seg = root.sectionId;
        if (seg == null || seg.isEmpty()) {
          seg = root.type;
        }
        if (seg.equals(id)) {
          SomMetaTree tree;
          try {
            tree = codec.treeFor(root.type);
          } catch (RuntimeException e) {
            break;
          }
          rootPrefixes.add(seg);
          stack.add(new MdFrame(level, tree.root, seg, lineNo, false));
          return;
        }
      }
      List<String> known = new ArrayList<>();
      for (SpecRoot r : codec.model.roots) {
        String seg = r.sectionId;
        if (seg == null || seg.isEmpty()) {
          seg = r.type;
        }
        known.add(seg);
      }
      rejections.add(new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.UNKNOWN_SECTION,
          "no document root with this section id (known: "
              + String.join(", ", known) + ")",
          id));
      stack.add(new MdFrame(level, null, null, lineNo, true));
    }

    /**
     * Opens a list-item frame. {@code n} (with {@code hasN} true) is the
     * anonymous heading number (also the path number); a stored-id item gets
     * the next free number instead.
     */
    void openItem(int level, String listPath, SomMetaNode listNode,
        int n, String storedId, boolean hasN, int lineNo) {
      MdListState state = lists.get(listPath);
      if (state == null) {
        state = new MdListState();
        lists.put(listPath, state);
        listOrder.add(listPath);
      }
      int number = hasN ? n : state.maxN + 1;
      if (number > state.maxN) {
        state.maxN = number;
      }
      String itemPath = listPath + "-" + number;
      state.items.add(itemPath);
      if (!hasN) {
        state.ids.put(itemPath, storedId);
      }
      stack.add(new MdFrame(level, listNode.elementNode, itemPath, lineNo, false));
    }

    /**
     * {@code GOAL-ITEM-xxx} → {@code ^GOAL-ITEM-.+$} — the
     * {@code @SectionIdPattern} wildcard.
     */
    static boolean patternMatches(String pattern, String id) {
      String[] parts = splitAll(pattern, "xxx");
      List<String> quoted = new ArrayList<>();
      for (String part : parts) {
        quoted.add(Pattern.quote(part));
      }
      return Pattern.compile("^" + String.join(".+", quoted) + "$").matcher(id).matches();
    }

    static boolean isValueLeaf(String kind) {
      return SomMetaKind.CONTENT.equals(kind)
          || SomMetaKind.SCALAR.equals(kind)
          || SomMetaKind.ENUM_VALUE.equals(kind);
    }

    // --- Body finalisation ----------------------------------------------------

    void finalizeFrame(MdFrame frame) {
      if (frame.ignored) {
        return;
      }
      SomMetaNode node = frame.node;
      if (node != null && SomMetaKind.FORM.equals(node.kind)) {
        finalizeForm(frame, node, frame.path);
        return;
      }
      List<NodeRel> slots =
          node != null ? codec.bodySlots(node) : new ArrayList<>();
      if (slots.isEmpty()) {
        String value = restoreValue(frame.body);
        if (!value.isEmpty()) {
          content.put(frame.path, value);
        } else if (node != null && isValueLeaf(node.kind)) {
          rejections.add(new SpecMarkdownRejection(
              frame.line,
              SpecMarkdownRejectReason.MISSING_VALUE,
              "no value text under this section heading",
              frame.path));
        }
        return;
      }
      finalizeBodySlots(frame, slots);
    }

    /**
     * Binds a heading's body region against the owner's transparent body
     * slots (DR1 §1.2 transparency): {@code FieldName:} lines matching a
     * transparent form's fields route to that form (nearest form in slot
     * order, wrapping); all other text binds to the first non-form slot — or
     * to the owner's own path when no such slot exists.
     */
    void finalizeBodySlots(MdFrame frame, List<NodeRel> slots) {
      List<NodeRel> formSlots = new ArrayList<>();
      List<NodeRel> contentSlots = new ArrayList<>();
      for (NodeRel s : slots) {
        if (SomMetaKind.FORM.equals(s.node.kind)) {
          formSlots.add(s);
        } else {
          contentSlots.add(s);
        }
      }
      String contentPath = frame.path;
      if (!contentSlots.isEmpty()) {
        contentPath = frame.path + "/" + contentSlots.get(0).rel;
      }

      if (formSlots.isEmpty()) {
        String value = restoreValue(frame.body);
        if (!value.isEmpty()) {
          content.put(contentPath, value);
        }
        return;
      }

      MarkdownFenceTracker bodyFence = new MarkdownFenceTracker();
      String currentField = "";
      String currentFormPath = "";
      boolean haveField = false;
      List<String> currentLines = new ArrayList<>();
      List<String> contentLines = new ArrayList<>();

      currentFormIdx = 0;
      for (String line : frame.body) {
        if (!bodyFence.inFence()) {
          Matcher m = FIELD_LABEL.matcher(line);
          if (m.matches()) {
            int foundIdx = -1;
            String foundName = null;
            String lower = m.group(1).toLowerCase();
            outer:
            for (int k = 0; k < formSlots.size(); k++) {
              int idx = (currentFormIdx + k) % formSlots.size();
              SomFormMeta form = formSlots.get(idx).node.form;
              if (form == null) {
                continue;
              }
              for (SomFormFieldMeta f : form.fields) {
                if (f.name.toLowerCase().equals(lower)) {
                  foundIdx = idx;
                  foundName = f.name;
                  break outer;
                }
              }
            }
            if (foundIdx >= 0) {
              if (haveField) {
                String value = restoreValue(currentLines);
                if (!value.isEmpty()) {
                  forms.computeIfAbsent(currentFormPath, k -> new LinkedHashMap<>())
                      .put(currentField, value);
                }
              }
              currentLines = new ArrayList<>();
              currentFormIdx = foundIdx;
              haveField = true;
              currentField = foundName;
              currentFormPath = frame.path + "/" + formSlots.get(foundIdx).rel;
              currentLines.add(m.group(2));
              bodyFence.feed(line);
              continue;
            }
          }
        }
        // Continuation: strip the one escape space of a label-shaped line.
        String text = line;
        if (!bodyFence.inFence() && haveField && CONTINUATION_LABEL.matcher(line).find()) {
          text = line.substring(1);
        }
        if (haveField) {
          currentLines.add(text);
        } else {
          contentLines.add(text);
        }
        bodyFence.feed(line);
      }
      if (haveField) {
        String value = restoreValue(currentLines);
        if (!value.isEmpty()) {
          forms.computeIfAbsent(currentFormPath, k -> new LinkedHashMap<>())
              .put(currentField, value);
        }
      }
      String value = restoreValue(contentLines);
      if (!value.isEmpty()) {
        content.put(contentPath, value);
      }
    }

    void finalizeForm(MdFrame frame, SomMetaNode node, String path) {
      List<SomFormFieldMeta> fields =
          node.form != null ? node.form.fields : new ArrayList<>();
      Map<String, String> fieldsByLower = new LinkedHashMap<>();
      for (SomFormFieldMeta f : fields) {
        fieldsByLower.put(f.name.toLowerCase(), f.name);
      }
      MarkdownFenceTracker bodyFence = new MarkdownFenceTracker();
      String[] currentField = {""};
      boolean[] haveField = {false};
      List<String> currentLines = new ArrayList<>();

      for (int i = 0; i < frame.body.size(); i++) {
        String line = frame.body.get(i);
        if (!bodyFence.inFence()) {
          Matcher m = FIELD_LABEL.matcher(line);
          if (m.matches()) {
            String fieldName = fieldsByLower.get(m.group(1).toLowerCase());
            if (fieldName != null) {
              flushForm(haveField, currentField, currentLines, path, frame.line + i);
              haveField[0] = true;
              currentField[0] = fieldName;
              currentLines.add(m.group(2));
              bodyFence.feed(line);
              continue;
            }
          }
        }
        // Continuation: strip the one escape space of a label-shaped line.
        if (!bodyFence.inFence() && CONTINUATION_LABEL.matcher(line).find()) {
          currentLines.add(line.substring(1));
        } else {
          currentLines.add(line);
        }
        bodyFence.feed(line);
      }
      flushForm(haveField, currentField, currentLines, path, frame.line + frame.body.size());
    }

    private void flushForm(boolean[] haveField, String[] currentField,
        List<String> currentLines, String path, int lineNo) {
      if (haveField[0]) {
        String value = restoreValue(currentLines);
        if (!value.isEmpty()) {
          forms.computeIfAbsent(path, k -> new LinkedHashMap<>())
              .put(currentField[0], value);
        }
      } else {
        for (String l : currentLines) {
          if (!l.trim().isEmpty()) {
            rejections.add(new SpecMarkdownRejection(
                lineNo,
                SpecMarkdownRejectReason.ORPHAN_CONTENT,
                "text in a @Form section before the first field label",
                path));
            break;
          }
        }
      }
      currentLines.clear();
    }

    /**
     * The parse-side value restoration (DR1 §1.3): trim leading/trailing
     * blank lines and unescape {@code \#}-escaped heading lines outside
     * fences.
     */
    static String restoreValue(List<String> body) {
      MarkdownFenceTracker restoreFence = new MarkdownFenceTracker();
      List<String> out = new ArrayList<>(body.size());
      for (String line : body) {
        if (!restoreFence.inFence() && ESCAPED_HEADING.matcher(line).find()) {
          out.add(line.substring(1));
        } else {
          out.add(line);
        }
        restoreFence.feed(line);
      }
      String joined = String.join("\n", out);
      joined = LEADING_BLANK_LN.matcher(joined).replaceAll("");
      joined = TRAILING_BLANK_LN.matcher(joined).replaceAll("");
      return joined;
    }

    Map<String, Object> listsJson() {
      Map<String, Object> out = new LinkedHashMap<>();
      for (String key : listOrder) {
        MdListState state = lists.get(key);
        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("seq", state.maxN);
        entry.put("items", new ArrayList<>(state.items));
        if (!state.ids.isEmpty()) {
          entry.put("ids", new LinkedHashMap<>(state.ids));
        }
        out.put(key, entry);
      }
      return out;
    }
  }
}
