package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
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
 * verbatim. Blank lines inside a value are kept as written; parse trims each
 * value of leading/trailing blank lines only.
 *
 * <p>The codec is free of any UI: it reads from / resolves against a
 * {@link SpecModel} (through the {@link SomMetaBridge#buildSomMetaTree}
 * metadata tree) and a {@link SpecDocument}. {@link #parse} does <b>not</b>
 * mutate the document — it returns staged values keyed exactly like
 * {@link SpecDocument#toJson} plus a rejection report; {@link SpecDocument#applyMarkdownResult} applies
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
  // A slot marker line (SOM §11.6): `<rel>` a body slot's path relative to its
  // owner, or `.` for the owner itself.
  private static final Pattern SLOT_MARKER = Pattern.compile("^<!-- slot: (\\S+) -->$");
  private static final Pattern ESCAPED_HEADING = Pattern.compile("^\\\\+#");

  private static final Pattern TRAILING_WS = Pattern.compile("\\s+$");
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
    // The class id is the node's classSectionId, as the YAML key uses — never
    // classNamed(node.className): a wrapper section (TextSection, ...) carries
    // its OWNER's class name, and that lookup returned the owner's id.
    if (SomMetaKind.SECTION.equals(node.kind) || SomMetaKind.COMPLEX.equals(node.kind)) {
      if (node.classSectionId != null && !node.classSectionId.isEmpty()) {
        return node.classSectionId;
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
    // classSectionId, not classNamed(n.className): see headingIdOf. A wrapper
    // section (TextSection, ...) has neither id, so it is transparent (SOM §11.6).
    return n.classSectionId == null || n.classSectionId.isEmpty();
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
   * Markdown document. Throws {@link IllegalStateException} on the two
   * conditions this format cannot represent without losing the round-trip: a
   * content value containing an unterminated fenced code block (which would
   * shield the remainder of the document from heading detection), and a form
   * holding a field the model does not declare (SOM §9, "Form-field order").
   */
  public String exportRoot(SpecRoot root) {
    return exportRootWithMap(root).markdown;
  }

  /**
   * {@link #exportRoot}, plus the document path behind every heading it wrote
   * — the one place that knows which node a heading came from.
   *
   * <p>A caller holding a rendition line (a DocSpecs schema finding, an editor
   * cursor) resolves it through {@link SpecMarkdownRendition#pathAtLine}
   * instead of re-deriving the renderer's layout. Section ids repeat across a
   * document, so the id alone does not say which node a line belongs to.
   */
  public SpecMarkdownRendition exportRootWithMap(SpecRoot root) {
    headingPaths.clear();
    String markdown = exportRootText(root);
    Map<Integer, String> map = new LinkedHashMap<>();
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    String[] lines = markdown.split("\n", -1);
    int next = 0;
    for (int i = 0; i < lines.length && next < headingPaths.size(); i++) {
      String line = lines[i];
      if (!fence.inFence() && EMITTED_HEADING.matcher(line).find()) {
        map.put(i + 1, headingPaths.get(next++));
      }
      fence.feed(line);
    }
    return new SpecMarkdownRendition(markdown, map);
  }

  /**
   * A heading line as {@link #writeHeading} writes it. Body text never
   * matches: heading-like body lines are escaped (SOM §11.3) and fenced ones
   * skipped.
   */
  private static final Pattern EMITTED_HEADING = Pattern.compile("^#+ <!--\\[");

  /** The paths of the headings written by the current export, in order. */
  private final List<String> headingPaths = new ArrayList<>();

  private String exportRootText(SpecRoot root) {
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
    writeHeading(b, 1, rootSeg, rootTitle, rootSeg, document.codeSpec(rootSeg));
    writeSectionBody(b, node, rootSeg);
    writeChildren(b, node, rootSeg, 2);
    return b.toString();
  }

  /**
   * Writes the body region of a section heading: the section path's own
   * content value plus every transparent body slot (id-less content text and
   * form blocks, hoisted through transparent sections) in model order.
   *
   * <p>A slot whose text the parser would otherwise bind elsewhere is preceded
   * by a slot marker (SOM §11.6): text after anything already written, a form
   * preamble that is not the region's default target, and a form whose labels
   * another form of the region shares. A body the parser reads correctly
   * without markers gets none, so such documents render as before.
   */
  private void writeSectionBody(StringBuilder b, SomMetaNode node, String path) {
    List<NodeRel> slots = bodySlots(node);
    if (slots.isEmpty()) {
      String value = document.content(path);
      if (value != null) {
        writeBody(b, value, path);
      }
      return;
    }
    List<NodeRel> formSlots = new ArrayList<>();
    for (NodeRel s : slots) {
      if (SomMetaKind.FORM.equals(s.node.kind)) {
        formSlots.add(s);
      }
    }
    boolean hasForms = !formSlots.isEmpty();
    String defaultRel = defaultBodyRel(slots);
    boolean[] written = {false};

    writeBodyText(b, ".", document.content(path), path, defaultRel, hasForms, written);
    for (NodeRel slot : slots) {
      String slotPath = path + "/" + slot.rel;
      if (!SomMetaKind.FORM.equals(slot.node.kind)) {
        writeBodyText(b, slot.rel, document.content(slotPath), slotPath, defaultRel,
            hasForms, written);
        continue;
      }
      if (!formHasValues(slot.node, slotPath)) {
        continue;
      }
      String preamble = document.content(slotPath);
      boolean hasPreamble =
          preamble != null && !prepareValue(preamble, slotPath).isEmpty();
      Set<String> labels = new HashSet<>();
      if (slot.node.form != null) {
        for (SomFormFieldMeta f : slot.node.form.fields) {
          labels.add(f.name.toLowerCase(Locale.ROOT));
        }
      }
      boolean collides = false;
      for (NodeRel o : formSlots) {
        if (o.rel.equals(slot.rel) || o.node.form == null) {
          continue;
        }
        for (SomFormFieldMeta f : o.node.form.fields) {
          if (labels.contains(f.name.toLowerCase(Locale.ROOT))) {
            collides = true;
            break;
          }
        }
        if (collides) {
          break;
        }
      }
      boolean needsMarker = hasPreamble
          ? (written[0] || !slot.rel.equals(defaultRel))
          : (collides && (written[0] || !formSlots.get(0).rel.equals(slot.rel)));
      if (needsMarker) {
        writeSlotMarker(b, slot.rel);
      }
      writeForm(b, slot.node, slotPath);
      written[0] = true;
    }
  }

  /** Writes a slot marker line (SOM §11.6) and the blank line after it. */
  private static void writeSlotMarker(StringBuilder b, String rel) {
    writeln(b, "<!-- slot: " + rel + " -->");
    writeln(b, "");
  }

  /**
   * Writes one text unit of a body region (the owner's content or a content
   * slot): a marker when something precedes it or it is not the default
   * target, then its lines — label-shaped ones escaped by one space in a
   * region with forms — and a blank line.
   */
  private void writeBodyText(StringBuilder b, String rel, String value, String valuePath,
      String defaultRel, boolean hasForms, boolean[] written) {
    if (value == null) {
      return;
    }
    String prepared = prepareValue(value, valuePath);
    if (prepared.isEmpty()) {
      return;
    }
    if (written[0] || !rel.equals(defaultRel)) {
      writeSlotMarker(b, rel);
    }
    for (String line : splitLines(prepared)) {
      writeln(b, hasForms && LABEL_SHAPED.matcher(line).find() ? " " + line : line);
    }
    writeln(b, "");
    written[0] = true;
  }

  /**
   * The body slot unmarked body text binds to on import (SOM §11.6): the
   * first non-form slot; with none, the form on the {@code content} member,
   * else the first form; with no slot at all the owner itself ({@code .}).
   */
  String defaultBodyRel(List<NodeRel> slots) {
    for (NodeRel s : slots) {
      if (!SomMetaKind.FORM.equals(s.node.kind)) {
        return s.rel;
      }
    }
    for (NodeRel s : slots) {
      if ("content".equals(s.rel)) {
        return s.rel;
      }
    }
    return slots.isEmpty() ? "." : slots.get(0).rel;
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
        writeHeading(b, depth, headingIdOf(child), headingTitle(path, child), path,
            document.codeSpec(path));
        writeBody(b, value, path);
      } else if (SomMetaKind.FORM.equals(child.kind)) {
        if (!formHasValues(child, path)) {
          continue;
        }
        writeHeading(b, depth, headingIdOf(child), headingTitle(path, child), path,
            document.codeSpec(path));
        writeForm(b, child, path);
      } else if (SomMetaKind.SECTION.equals(child.kind)
          || SomMetaKind.COMPLEX.equals(child.kind)) {
        writeHeading(b, depth, headingIdOf(child), headingTitle(path, child), path,
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
        listPath, document.codeSpec(listPath));
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
    if (pattern != null && pattern.isEmpty()) {
      pattern = null;
    }
    String memberStem = node.memberName;
    if (memberStem == null || memberStem.isEmpty()) {
      memberStem = node.segment();
    }
    for (int i = 0; i < items.size(); i++) {
      String itemPath = items.get(i);
      int pos = i + 1;
      // YRD3: a list item's STORED section id is the md
      // heading id when present; the `@SectionIdPattern` resolved with the
      // 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`) and the
      // `<member>-<pos>` fallback are positional derivations for id-less items.
      String itemId =
          SpecSectionId.effectiveListItemSectionId(
              document.itemSectionId(itemPath), pattern, pos, memberStem);
      // Items sit one level below the container. A stored headline overrides
      // the derived `<stem> <pos>` title (YRD3).
      String itemTitle = document.headline(itemPath);
      if (itemTitle == null || itemTitle.isEmpty()) {
        itemTitle = stem + " " + pos;
      }
      writeHeading(b, depth + 1, itemId, itemTitle, itemPath,
          document.codeSpec(itemPath));
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

  /**
   * The stored field names at form {@code path} that {@code node} does not
   * declare, sorted (SOM §9, "Form-field order").
   *
   * <p>The emit walk is meta-driven — it iterates the model's declared fields —
   * so a stored field the model does not know is invisible to it and cannot be
   * dropped <em>loudly</em>. Seeing it at all needs this deliberate reverse
   * check: store keys minus meta keys, which is the check the yaml codec
   * already has (SOM §12.8).
   */
  private List<String> undeclaredFormFields(SomMetaNode node, String path) {
    Set<String> declared = new HashSet<>();
    if (node.form != null) {
      for (SomFormFieldMeta f : node.form.fields) {
        declared.add(f.name);
      }
    }
    List<String> out = new ArrayList<>();
    for (String name : document.formFieldNames(path)) {
      if (!declared.contains(name)) {
        out.add(name);
      }
    }
    Collections.sort(out);
    return out;
  }

  /**
   * Throws when the form at {@code path} holds a field the model does not
   * declare (SOM §9, "Form-field order" — md refuses, matching yaml).
   *
   * <p>Emitting it is impossible: the DocSpecs markdown grammar has no spelling
   * for a field outside the model, and omitting it would lose a stored value in
   * a file that looks complete. On import a partial document is normal and the
   * codec reports-and-skips (SOM §11.7); on export the document is complete and
   * a lossy rendering is a trap, so the codec refuses instead.
   */
  private void checkFormDeclared(SomMetaNode node, String path) {
    List<String> undeclared = undeclaredFormFields(node, path);
    if (undeclared.isEmpty()) {
      return;
    }
    throw new IllegalStateException(
        "form at \"" + path + "\" holds a field \"" + undeclared.get(0)
            + "\" unknown to the model; it cannot be represented in the "
            + "DocSpecs markdown format");
  }

  /**
   * Whether the {@code @Form} node at {@code path} has anything to emit: its
   * preamble content (SOM §11.4 rule 7 — the DocSpecs {@code ${text[]}}
   * region), or any populated field.
   *
   * <p>An undeclared stored field counts too — not because it can be emitted,
   * but so the section is still <em>visited</em> and {@link #writeForm}
   * refuses. Without it a form holding nothing but undeclared fields would
   * vanish unseen, which is the silent drop this check exists to prevent.
   */
  private boolean formHasValues(SomMetaNode node, String path) {
    if (document.hasContent(path)) {
      return true;
    }
    if (node.form != null) {
      for (SomFormFieldMeta f : node.form.fields) {
        if (document.formField(path, f.name) != null) {
          return true;
        }
      }
    }
    return !undeclaredFormFields(node, path).isEmpty();
  }

  /**
   * Writes a {@code @Form} section body: the preamble content (when set)
   * followed by one {@code FieldName: value} group per populated field
   * (SOM §11.4), consecutive groups separated by one blank line. Throws
   * {@link IllegalStateException} when the form holds a field the model does
   * not declare.
   */
  private void writeForm(StringBuilder b, SomMetaNode node, String path) {
    checkFormDeclared(node, path);
    List<SomFormFieldMeta> fields =
        node.form != null ? node.form.fields : new ArrayList<>();
    StringBuilder fieldBuf = new StringBuilder();
    for (SomFormFieldMeta f : fields) {
      String value = document.formField(path, f.name);
      if (value == null) {
        continue;
      }
      // SOM §11.4 rule 2: one blank line between consecutive field groups, so
      // a markdown viewer renders each field as its own paragraph (and a list
      // ending a value cannot swallow the next label as a lazy continuation).
      // Parse trims each value's trailing blank lines, so it is lossless.
      if (fieldBuf.length() > 0) {
        writeln(fieldBuf, "");
      }
      // SOM §11.4 rule 8: a single-line code value is written as an inline
      // code span, so markdown leaves it literal (`](` is not a link).
      String[] lines = f.code && isInlineCode(value)
          ? new String[] {encodeCodeSpan(value)}
          : splitLines(prepareValue(value, path));
      writeln(fieldBuf, formLabel(f.name) + ": " + lines[0]);
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i];
        // SOM §11.4 generalised: any continuation line that could be mistaken
        // for a field-label line gains one leading space; parse strips it.
        if (LABEL_SHAPED.matcher(line).find()) {
          writeln(fieldBuf, " " + line);
        } else {
          writeln(fieldBuf, line);
        }
      }
    }

    String preamble = document.content(path);
    if (preamble != null) {
      String prepared = prepareValue(preamble, path);
      if (!prepared.isEmpty()) {
        // Every preamble line gets the same label-shaped escape a continuation
        // line gets: the parser reaches a field label before it knows which
        // text is preamble, so a `Word:` line at column 0 would mis-split.
        for (String line : splitLines(prepared)) {
          if (LABEL_SHAPED.matcher(line).find()) {
            writeln(b, " " + line);
          } else {
            writeln(b, line);
          }
        }
        if (fieldBuf.length() > 0) {
          writeln(b, "");
        }
      }
    }
    b.append(fieldBuf);
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
  private void writeHeading(
      StringBuilder b, int depth, String id, String title, String path,
      String codeSpec) {
    headingPaths.add(path);
    // codespecs_mapping.md §9.2: emit ` codeSpec="…"` inside the same comment
    // when a mapping is stored; byte-identical to the plain form when
    // absent/empty.
    String cs = (codeSpec != null && !codeSpec.isEmpty())
        ? " codeSpec=\"" + codeSpec + "\""
        : "";
    // A heading is one line: a stored headline's line breaks travel as `<br>`.
    writeln(b, "#".repeat(depth) + " <!--[" + id + "]" + cs + "--> "
        + title.replace("\n", "<br>"));
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

  private static final Pattern BACKTICK_RUN = Pattern.compile("`+");
  private static final Pattern CODE_PAD_NEEDED = Pattern.compile("^[` ]|[` ]$");
  private static final Pattern CODE_SPAN =
      Pattern.compile("^(`+)([\\s\\S]*[^`])(`+)$");

  /**
   * Whether a code field's {@code value} is written as an inline code span: it
   * is non-empty and on one line. A multi-line value keeps the prose rendering
   * — a code span cannot cross a line break without markdown joining the lines.
   */
  static boolean isInlineCode(String value) {
    return !value.isEmpty() && value.indexOf('\n') < 0;
  }

  /**
   * {@code value} as a CommonMark inline code span: delimited by one backtick
   * more than the longest backtick run inside it, and padded with one space on
   * each side when it begins or ends with a backtick or a space — the padding
   * CommonMark strips again, so the span's content is exactly {@code value}.
   */
  static String encodeCodeSpan(String value) {
    int longest = 0;
    Matcher m = BACKTICK_RUN.matcher(value);
    while (m.find()) {
      longest = Math.max(longest, m.group().length());
    }
    String fence = "`".repeat(longest + 1);
    String pad = CODE_PAD_NEEDED.matcher(value).find() ? " " : "";
    return fence + pad + value + pad + fence;
  }

  /**
   * The inverse of the emitter's code span (SOM §11.4 rule 8): a single-line
   * {@code value} delimited by equal backtick runs loses them, and one padding
   * space on each side when both are present. Anything else — a value written
   * by hand without a span — is kept as written.
   */
  static String decodeCodeSpan(String value) {
    if (value.indexOf('\n') >= 0) {
      return value;
    }
    Matcher m = CODE_SPAN.matcher(value);
    if (!m.matches() || m.group(1).length() != m.group(3).length()) {
      return value;
    }
    String inner = m.group(2);
    if (inner.length() >= 2
        && inner.startsWith(" ")
        && inner.endsWith(" ")
        && !inner.trim().isEmpty()) {
      return inner.substring(1, inner.length() - 1);
    }
    return inner;
  }

  /**
   * The emit-side value normalisation (SOM §11.3): blank lines inside the
   * value are kept as written; trim leading/trailing blank lines, escape heading-like lines outside
   * fences. Throws {@link IllegalStateException} for an unterminated fence.
   */
  private String prepareValue(String value, String path) {
    String collapsed = LEADING_NL.matcher(value).replaceAll("");
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
   * <b>without</b> mutating the document. {@link SpecDocument#applyMarkdownResult} applies the result as a
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
      String title = m.group(3).trim().replace("<br>", "\n");

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
     * list: the {@code <member>-<n>} fallback id (positional, nothing stored),
     * the {@code @SectionIdPattern} resolved with a number
     * ({@code GOAL-ITEM-3}, parses back as item {@code <n>} carrying that id),
     * a pattern-shaped stored id, or — for any other id — an anonymous next
     * item carrying the stored id.
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
        // The pattern with `xxx` as a number parses back as item <n> AND is
        // stored: the section id is the item's identity and the path only its
        // position, so an id that happens to equal the positional default must
        // survive a later move or insert (SOM §11.6).
        String[] parts = splitAll(pattern, "xxx");
        if (parts.length == 2) {
          Matcher numbered = Pattern
              .compile("^" + Pattern.quote(parts[0]) + "([0-9]+)"
                  + Pattern.quote(parts[1]) + "$")
              .matcher(id);
          if (numbered.matches()) {
            openItem(level, listPath, listNode, Integer.parseInt(numbered.group(1)),
                id, true, title, codeSpec, lineNo);
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
      if (storedId != null) {
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
     * slots (SOM §11.6): {@code FieldName:} lines matching a transparent
     * form's fields route to that form (nearest form in slot order, wrapping);
     * a slot marker ({@code <!-- slot: <rel> -->}) sends the text after it to
     * the named slot — a content slot, a form's preamble, or the owner itself
     * ({@code .}) — and ends any open field. Unmarked text binds to the first
     * content slot; with no content slot it is a form's <b>preamble</b> (SOM
     * §11.4 rule 7) — the form slot named {@code content}, else the first form
     * slot — which is where the YAML codec keeps it; only an owner with no
     * slot at all takes it on its own path. In a region with forms every
     * label-shaped text line carries one escape space, which is stripped.
     */
    void finalizeBodySlots(MdFrame frame, List<NodeRel> slots) {
      List<NodeRel> formSlots = new ArrayList<>();
      for (NodeRel s : slots) {
        if (SomMetaKind.FORM.equals(s.node.kind)) {
          formSlots.add(s);
        }
      }
      String defaultRel = codec.defaultBodyRel(slots);

      MarkdownFenceTracker bodyFence = new MarkdownFenceTracker();
      String currentField = "";
      String currentFormPath = "";
      boolean currentCode = false;
      boolean haveField = false;
      List<String> currentLines = new ArrayList<>();
      // Unlabelled text per target path, in the order the targets were
      // opened; a target opened twice gets its parts joined by a blank line.
      Map<String, List<List<String>>> textParts = new LinkedHashMap<>();
      String contentTarget = bodyPathOf(frame.path, defaultRel);
      List<String> contentLines = new ArrayList<>();
      textParts.computeIfAbsent(contentTarget, k -> new ArrayList<>()).add(contentLines);

      currentFormIdx = 0;
      for (int i = 0; i < frame.body.size(); i++) {
        String line = frame.body.get(i);
        if (!bodyFence.inFence()) {
          Matcher mk = SLOT_MARKER.matcher(line);
          if (mk.matches()) {
            String rel = mk.group(1);
            NodeRel slot = null;
            if (!".".equals(rel)) {
              for (NodeRel s : slots) {
                if (s.rel.equals(rel)) {
                  slot = s;
                  break;
                }
              }
            }
            if (".".equals(rel) || slot != null) {
              if (haveField) {
                putField(currentFormPath, currentField, currentLines, currentCode);
              }
              haveField = false;
              currentField = "";
              currentFormPath = "";
              currentLines = new ArrayList<>();
              if (slot != null && SomMetaKind.FORM.equals(slot.node.kind)) {
                currentFormIdx = formSlots.indexOf(slot);
              }
              contentTarget = bodyPathOf(frame.path, rel);
              contentLines = new ArrayList<>();
              textParts.computeIfAbsent(contentTarget, k -> new ArrayList<>())
                  .add(contentLines);
              continue;
            }
          }
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
                putField(currentFormPath, currentField, currentLines, currentCode);
              }
              currentLines = new ArrayList<>();
              currentFormIdx = foundIdx;
              haveField = true;
              currentField = found.name;
              currentCode = found.code;
              currentFormPath = frame.path + "/" + formSlots.get(foundIdx).rel;
              currentLines.add(m.group(2));
              bodyFence.feed(line);
              continue;
            }
          }
        }
        // In a region with forms every label-shaped text line carries the one
        // escape space the emitter adds (SOM §11.4 rule 3); strip it.
        String text = line;
        if (!bodyFence.inFence()
            && !formSlots.isEmpty()
            && CONTINUATION_LABEL.matcher(line).find()) {
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
        putField(currentFormPath, currentField, currentLines, currentCode);
      }
      for (Map.Entry<String, List<List<String>>> e : textParts.entrySet()) {
        List<String> values = new ArrayList<>();
        for (List<String> part : e.getValue()) {
          String v = restoreValue(part);
          if (!v.isEmpty()) {
            values.add(v);
          }
        }
        String value = String.join("\n\n", values);
        if (!value.isEmpty()) {
          content.put(e.getKey(), value);
        }
      }
    }

    /** Stores a body-region field's restored value (unwrapping a code span). */
    private void putField(String formPath, String field, List<String> lines, boolean code) {
      String restored = restoreValue(lines);
      String value = code ? decodeCodeSpan(restored) : restored;
      if (!value.isEmpty()) {
        forms.computeIfAbsent(formPath, k -> new LinkedHashMap<>()).put(field, value);
      }
    }

    private static String bodyPathOf(String ownerPath, String rel) {
      return ".".equals(rel) ? ownerPath : ownerPath + "/" + rel;
    }

    /**
     * Parses an id-bearing {@code @Form} section's body: the preamble text
     * before the first field label binds to the form's own content (SOM §11.4
     * rule 7); everything from the first label on binds to the named fields.
     */
    void finalizeForm(MdFrame frame, SomMetaNode node, String path) {
      List<SomFormFieldMeta> fields =
          node.form != null ? node.form.fields : new ArrayList<>();
      Map<String, String> fieldsByLower = new LinkedHashMap<>();
      Set<String> codeFields = new HashSet<>();
      for (SomFormFieldMeta f : fields) {
        fieldsByLower.put(f.name.toLowerCase(), f.name);
        if (f.code) {
          codeFields.add(f.name);
        }
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
              flushForm(haveField, currentField, currentLines, path, frame.line + i,
                  codeFields);
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
          frame.line + frame.body.size(), codeFields);
    }

    private void flushForm(boolean[] haveField, String[] currentField,
        List<String> currentLines, String path, int lineNo,
        Set<String> codeFields) {
      String restored = restoreValue(currentLines);
      String value = haveField[0] && codeFields.contains(currentField[0])
          ? decodeCodeSpan(restored)
          : restored;
      if (haveField[0]) {
        if (!value.isEmpty()) {
          forms.computeIfAbsent(path, k -> new LinkedHashMap<>())
              .put(currentField[0], value);
        }
      } else if (!value.isEmpty()) {
        content.put(path, value);
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
