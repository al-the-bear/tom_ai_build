package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * SpecDocumentMarkdown — DocSpecs-conform Markdown codec for a TomSpecs
 * document (SOM §11), a faithful port of
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
 * format; a list emits its {@code -LST} container heading (id = the list's
 * {@code @SectionId}, else the member segment) at the owner's child level,
 * wrapping the numbered item headings one level deeper — each item carrying the
 * {@code @SectionIdPattern} resolved with the 1-based position
 * ({@code GOAL-ITEM-xxx} → {@code GOAL-ITEM-1}, else {@code <member>-<pos>}).
 * The container itself carries no body. Id-less members are <b>transparent</b>
 * (mirroring the generated schema
 * generator): a transparent value member's text or form block is the owner's
 * body region, emitted without a heading and bound at its own path; a
 * transparent section/complex member never heads — its id-bearing descendants
 * hoist to the owner's child level (paths keep the transparent segments).
 * Section/complex headings without a field-level {@code @SectionId} carry the
 * target class's {@code @SectionId}.
 *
 * <p>Escaping (SOM §11.3): a content line starting with {@code #} at column 0
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
 * {@link SpecMarkdownResult#rejections} rather than dropped (SOM §11.7).
 *
 * <p>Java conventions: where Go returns an error, {@link #exportRoot}
 * throws {@link IllegalStateException} (the unterminated-fence case); a null
 * anchor stands in for Go's empty string.
 */
public final class SpecDocumentMarkdown {
  // Shared with the parser and the DocSpecs validator.
  static final Pattern HEADING_LINE = Pattern.compile("^(#+)\\s+(.*)$");
  // Three-group heading comment: g1 = section id, g2 = the key=value region
  // between the id bracket and the closing `-->` (codespecs_mapping.md §9.2
  // `codeSpec`), g3 = title.
  static final Pattern HEADLINE_COMMENT =
      Pattern.compile("^<!--\\[([^\\]]+)\\]([^>]*)-->\\s*(.*)$");
  static final Pattern DOCSPEC_COMMENT = Pattern.compile("^<!--\\s*docspec:.*-->\\s*$");

  // The `codeSpec="…"` (single/double-quoted or bare) key inside a heading
  // comment's key=value region (codespecs_mapping.md §9.2).
  static final Pattern CODE_SPEC_PATTERN =
      Pattern.compile("codeSpec=(?:\"([^\"]*)\"|'([^']*)'|([^,\\s>]+))");

  /**
   * Extracts the {@code codeSpec="…"} value from a heading-comment key=value
   * region (codespecs_mapping.md §9.2), returning the first non-null
   * quoted/bare group trimmed, or the empty string when the region carries no
   * {@code codeSpec} key.
   */
  static String codeSpecOf(String region) {
    Matcher m = CODE_SPEC_PATTERN.matcher(region);
    if (m.find()) {
      for (int g = 1; g <= 3; g++) {
        if (m.group(g) != null) {
          return m.group(g).trim();
        }
      }
    }
    return "";
  }

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
  // Metadata trees per root type, built lazily (the generated facades will
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

  // --- Naming helpers (SOM §11.2 / §11.5) ------------------------------------

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
   * Derives the DocSpecs schema id of a {@code @Document} name (SOM §11.1):
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
   * {@code Entry} dropped (SOM §11.5, normative).
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
   * with the first letter upper-cased (SOM §11.4).
   */
  public static String formLabel(String fieldName) {
    if (fieldName.isEmpty()) {
      return fieldName;
    }
    return Character.toUpperCase(fieldName.charAt(0)) + fieldName.substring(1);
  }

  // --- Export (SOM §11.1–§11.8) -----------------------------------------------

  /**
   * The section id written into (and matched from) a heading for {@code node}
   * (SOM §11.2/§11.8): the field-level {@code @SectionId} when present; for
   * section/complex nodes whose field carries none, the target <b>class</b>'s
   * {@code @SectionId} (the id the generated schema types are keyed by); else the
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

  // --- Transparency (SOM §11.2, mirroring the schema generator , SOM §13) ------
  //
  // The `docspecs-schema` generator (SOM §13) is normative: only **section-bearing**
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
  //   - lists are never transparent — the `-LST` container always heads (SOM
  //     §11.2) at the owner's child level and the items sit one level below it
  //     (`@SectionIdPattern` / `<member>-<pos>`).
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
   * — exactly the headings (and item-heading owners) the generated schema knows at
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
    // YRD3: a stored headline overrides the derived title at every heading.
    // YRD4: the @Headline default wins over the @Document title.
    String rootTitle = document.headline(rootSeg);
    if (rootTitle == null || rootTitle.isEmpty()) {
      rootTitle = node.headline;
    }
    if (rootTitle == null || rootTitle.isEmpty()) {
      rootTitle = root.title;
    }
    writeHeading(b, 1, rootSeg, rootTitle, document.codeSpec(rootSeg));
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
        writeHeading(b, depth, headingIdOf(child), headingTitle(path, child),
            document.codeSpec(path));
        writeBody(b, value, path);
      } else if (SomMetaKind.FORM.equals(child.kind)) {
        if (!formHasValues(child, path)) {
          continue;
        }
        writeHeading(b, depth, headingIdOf(child), headingTitle(path, child),
            document.codeSpec(path));
        writeForm(b, child, path);
      } else if (SomMetaKind.SECTION.equals(child.kind)
          || SomMetaKind.COMPLEX.equals(child.kind)) {
        writeHeading(b, depth, headingIdOf(child), headingTitle(path, child),
            document.codeSpec(path));
        writeSectionBody(b, child, path);
        writeChildren(b, child, path, depth + 1);
      } else if (SomMetaKind.LIST.equals(child.kind)) {
        writeListItems(b, child, path, depth);
      }
    }
  }

  /**
   * Emits list {@code node} as its {@code -LST} container heading (SOM
   * §11.2/§11.5) at {@code depth}, wrapping the numbered item headings one level
   * deeper. The container is a real section — the id the generated schema keys its
   * container type by — but carries <b>no content of its own</b> (schema
   * content min/max-text-length 0). Item identity is purely positional.
   */
  private void writeListItems(StringBuilder b, SomMetaNode node, String listPath, int depth) {
    List<String> items = document.listItems(listPath);
    if (items.isEmpty()) {
      return;
    }
    // The container heading: its id is the list's `-LST` `@SectionId` (else the
    // member segment for a pattern-less list); its title is the member name —
    // unless a stored headline overrides it (YRD3).
    writeHeading(b, depth, headingIdOf(node), headingTitle(listPath, node),
        document.codeSpec(listPath));
    // Item heading stem. Complex lists derive it from the element class name
    // (SOM §11.5, `Entry` dropped). A scalar list (shape 6) has no element class
    // — its element typeName is literally `String`, which would render
    // "String 1", "String 2". Derive the stem from the list FIELD instead (its
    // member name, Title-Cased like the container heading) so a populated
    // scalar list gets meaningful per-item headings (YRC5).
    SomMetaNode element = node.elementNode;
    String stem = itemStemOf(node);
    String pattern = node.sectionIdPattern;
    if ((pattern == null || pattern.isEmpty()) && element != null) {
      pattern = element.sectionIdPattern;
    }
    for (int i = 0; i < items.size(); i++) {
      String itemPath = items.get(i);
      int pos = i + 1;
      // YRD3: a list item's STORED section id is the md
      // heading id when present; the `@SectionIdPattern` resolved with the
      // 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`) and the
      // `<member>-<pos>` fallback are positional derivations for id-less items.
      String itemId;
      String storedItemId = document.itemSectionId(itemPath);
      if (storedItemId != null) {
        itemId = storedItemId;
      } else if (pattern != null && !pattern.isEmpty()) {
        itemId = String.join(String.valueOf(pos), splitAll(pattern, "xxx"));
      } else {
        String member = node.memberName;
        if (member == null || member.isEmpty()) {
          member = node.segment();
        }
        itemId = member + "-" + pos;
      }
      // Items sit one level below the container. A stored headline overrides
      // the derived `<stem> <pos>` title (YRD3).
      String itemTitle = document.headline(itemPath);
      if (itemTitle == null || itemTitle.isEmpty()) {
        itemTitle = stem + " " + pos;
      }
      writeHeading(b, depth + 1, itemId, itemTitle, document.codeSpec(itemPath));
      if (element == null) {
        // Scalar list: the item's value is its body.
        String value = document.content(itemPath);
        writeBody(b, value == null ? "" : value, itemPath);
      } else {
        writeSectionBody(b, element, itemPath);
        if (!element.recursive) {
          writeChildren(b, element, itemPath, depth + 2);
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
        // SOM §11.4 generalised: any continuation line that could be mistaken
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
   * Writes {@code ## <!--[ID]--> Title} at {@code depth}. SOM §11.2 is
   * normative — heading level = 1 + section depth, <b>uncapped</b>: deep
   * models (the Solution Blueprint nests past markdown's native 6 levels) keep
   * their structure; the parse grammar accepts {@code #{7,}} accordingly.
   * Capping would silently flatten distinct nesting positions into siblings
   * and break schema validation.
   */
  private static void writeHeading(
      StringBuilder b, int depth, String id, String title, String codeSpec) {
    // codespecs_mapping.md §9.2: emit ` codeSpec="…"` inside the same comment
    // when a mapping is stored; byte-identical to the plain form when
    // absent/empty.
    String cs = (codeSpec != null && !codeSpec.isEmpty())
        ? " codeSpec=\"" + codeSpec + "\""
        : "";
    writeln(b, "#".repeat(depth) + " <!--[" + id + "]" + cs + "--> " + title);
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
   * The emit-side value normalisation (SOM §11.3): collapse 2+ blank lines to
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
        out.add(line); // SOM §11.3: fences shield their lines.
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

  /**
   * The heading title for {@code node} at {@code path}: the stored headline
   * when set (YRD3), else the derived Title-Case member name.
   */
  private String headingTitle(String path, SomMetaNode node) {
    String h = document.headline(path);
    if (h != null && !h.isEmpty()) {
      return h;
    }
    return titleOf(node);
  }

  /**
   * The effective DEFAULT title of {@code node} (YRD4): the {@code @Headline}
   * default when authored, else the name derivation. The stored headline
   * (checked by callers first) always wins over this.
   */
  private static String titleOf(SomMetaNode node) {
    if (node.headline != null && !node.headline.isEmpty()) {
      return node.headline;
    }
    String name = node.memberName;
    if (name == null || name.isEmpty()) {
      name = node.className;
    }
    return titleCase(name);
  }

  /**
   * The effective default item-title stem of list {@code node} (YRD4): the
   * element class's {@code @Headline} default when authored, else the SOM §11.5
   * derivation (element class name with {@code Entry} dropped; member name for
   * scalar lists).
   */
  private static String itemStemOf(SomMetaNode node) {
    SomMetaNode element = node.elementNode;
    if (element != null) {
      if (element.headline != null && !element.headline.isEmpty()) {
        return element.headline;
      }
      return itemTitleStem(element.className);
    }
    String member = node.memberName;
    if (member == null || member.isEmpty()) {
      member = node.segment();
    }
    return titleCase(member);
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

  // --- Import (SOM §11.7) -------------------------------------------------------

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
    result.headlines.putAll(p.headlines);
    result.codeSpecs.putAll(p.codeSpecs);
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
    // Stored headlines staged from heading titles that differ from their
    // effective default (SOM §11.7) — byte-stability: a default title stages
    // nothing.
    final Map<String, String> headlines = new LinkedHashMap<>();
    // Stored codeSpec mappings staged from the `codeSpec="…"` key in heading
    // comments (codespecs_mapping.md §9.2) — staged whenever present (no
    // effective default).
    final Map<String, String> codeSpecs = new LinkedHashMap<>();
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
            continue; // SOM §11.1 header — informational.
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
      String codeSpec = codeSpecOf(m.group(2));
      String title = m.group(3).trim();

      if (stack.isEmpty()) {
        openRoot(level, id, title, codeSpec, lineNo);
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

      // 1. Under a `-LST` container frame (SOM §11.2), every child heading is one
      //    of that list's items — resolved positionally, not by the schema tree.
      if (SomMetaKind.LIST.equals(pNode.kind)) {
        openItemHeading(level, parent, pNode, id, title, codeSpec, lineNo);
        return;
      }

      // 2. A regular (non-list) or list-**container** *effective* child —
      //    section-bearing children hoisted through transparent sections —
      //    whose heading id matches. A list heads its `-LST` container here; its
      //    items are resolved above once the container frame is open.
      //    Transparent value members never head, so they never match; the bound
      //    path runs through the transparent segments.
      for (NodeRel entry : codec.effectiveChildren(pNode)) {
        if (codec.headingIdOf(entry.node).equals(id)) {
          String childPath = parent.path + "/" + entry.rel;
          // Stage the heading text as a stored headline ONLY when it differs
          // from the effective default title (SOM §11.7, byte-stability).
          if (!title.isEmpty() && !title.equals(titleOf(entry.node))) {
            headlines.put(childPath, title);
          }
          // codespecs_mapping.md §9.2: stage the codeSpec mapping whenever
          // present (no default).
          if (!codeSpec.isEmpty()) {
            codeSpecs.put(childPath, codeSpec);
          }
          stack.add(new MdFrame(
              level, entry.node, childPath, lineNo, false));
          return;
        }
      }

      rejections.add(new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.UNKNOWN_SECTION,
          "section id does not resolve against the schema tree at this "
              + "position (under \"" + parent.path + "\")",
          id));
      stack.add(new MdFrame(level, null, null, lineNo, true));
    }

    /**
     * Opens a list-item frame under a {@code -LST} container frame (SOM §11.2).
     * The heading {@code id} is matched positionally against the container's
     * list: the {@code <member>-<n>} fallback id, the {@code @SectionIdPattern}
     * resolved with a number ({@code GOAL-ITEM-3}, parses back as item
     * {@code <n>}), a pattern-shaped stored id, or — for any other id — an
     * anonymous next item carrying the stored id.
     */
    void openItemHeading(int level, MdFrame container, SomMetaNode listNode,
        String id, String title, String codeSpec, int lineNo) {
      String listPath = container.path;
      String member = listNode.memberName;
      if (member == null || member.isEmpty()) {
        member = listNode.segment();
      }
      Matcher anon = Pattern
          .compile("^" + Pattern.quote(member) + "-([0-9]+)$")
          .matcher(id);
      if (anon.matches()) {
        openItem(level, listPath, listNode, Integer.parseInt(anon.group(1)),
            null, true, title, codeSpec, lineNo);
        return;
      }
      SomMetaNode element = listNode.elementNode;
      String pattern = listNode.sectionIdPattern;
      if ((pattern == null || pattern.isEmpty()) && element != null) {
        pattern = element.sectionIdPattern;
      }
      if (pattern != null && !pattern.isEmpty()) {
        // Canonical anonymous id: the pattern with `xxx` as a number — parses
        // back as item <n>, NOT as a stored id (SOM §11.2 round-trip).
        String[] parts = splitAll(pattern, "xxx");
        if (parts.length == 2) {
          Matcher numbered = Pattern
              .compile("^" + Pattern.quote(parts[0]) + "([0-9]+)"
                  + Pattern.quote(parts[1]) + "$")
              .matcher(id);
          if (numbered.matches()) {
            openItem(level, listPath, listNode, Integer.parseInt(numbered.group(1)),
                null, true, title, codeSpec, lineNo);
            return;
          }
        }
        if (patternMatches(pattern, id)) {
          openItem(level, listPath, listNode, 0, id, false, title, codeSpec, lineNo);
          return;
        }
      }
      // Any other id under the container is a stored-id item (YRD3 — the
      // stored id round-trips through md as the heading id).
      openItem(level, listPath, listNode, 0, id, false, title, codeSpec, lineNo);
    }

    void openRoot(int level, String id, String title, String codeSpec, int lineNo) {
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
          // Stage the root heading text as a stored headline when it differs
          // from the effective default (SOM §11.7): the @Headline default
          // (YRD4), else the document title.
          String defaultTitle = tree.root.headline != null && !tree.root.headline.isEmpty()
              ? tree.root.headline
              : root.title;
          if (!title.isEmpty() && !title.equals(defaultTitle)) {
            headlines.put(seg, title);
          }
          // codespecs_mapping.md §9.2: stage the root codeSpec mapping whenever
          // present.
          if (!codeSpec.isEmpty()) {
            codeSpecs.put(seg, codeSpec);
          }
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
        int n, String storedId, boolean hasN, String title, String codeSpec,
        int lineNo) {
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
      // Stage the item heading text as a stored headline when it differs from
      // the derived `<stem> <n>` default (SOM §11.7).
      String stem = itemStemOf(listNode);
      if (!title.isEmpty() && !title.equals(stem + " " + number)) {
        headlines.put(itemPath, title);
      }
      // codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever
      // present.
      if (!codeSpec.isEmpty()) {
        codeSpecs.put(itemPath, codeSpec);
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
     * slots (SOM §11.2 transparency): {@code FieldName:} lines matching a
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
      for (int i = 0; i < frame.body.size(); i++) {
        String line = frame.body.get(i);
        if (!bodyFence.inFence()) {
          Matcher m = FIELD_LABEL.matcher(line);
          if (m.matches()) {
            int foundIdx = -1;
            SomFormFieldMeta found = null;
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
                  found = f;
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
              currentField = found.name;
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
      flushForm(haveField, currentField, currentLines, path,
          frame.line + frame.body.size());
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
     * The parse-side value restoration (SOM §11.3): trim leading/trailing
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
