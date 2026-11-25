package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.IntUnaryOperator;
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
 * <b>normal markdown text</b> under their heading (no fences); every heading
 * carries its section id as an HTML anchor, qualified below a list item and in
 * a {@code @SameAs} copy (SOM §11.2). The emitter writes the reading-view
 * layout (SOM §11.4, §11.5): a {@code @Form} section as
 * {@code | TomSpecField | Value |} tables, a value no table cell holds as a
 * {@code Field:} paragraph, a list of one-form items as a record table, a list
 * of single references as a reference line, a section of one-form children as
 * a section table; the parser reads that layout and the older layout of
 * {@code Field:} lines alike. A list emits its {@code -LST} container heading (id = the list's
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

  /** Matches the readable header line of a stripped rendition (SOM §11.1). */
  public static final Pattern READABLE_COMMENT = Pattern.compile("^<!--\\s*readable:.*-->$");

  /**
   * The line a stripped rendition's appendix begins with (SOM §11.1): after a
   * readable header, the parsers stop reading at it.
   */
  public static final String APPENDIX_MARKER = "<!-- readable-appendix -->";

  /** The fixed start of a styled-div heading's style, up to its indent. */
  public static final String HEADING_DIV_STYLE_START = "margin:1em 0 0.5em;padding-left:";

  /**
   * A styled-div heading line (DocSpecs <em>Styled-div headings</em>): group 1
   * the level, group 2 the inner text. A level below 7 is content.
   */
  static final Pattern HEADING_DIV_LINE =
      Pattern.compile("^<div class=\"heading([0-9]+)\"[^>]*>(.*)</div>$");

  /** A line read as a styled-div heading ({@link #headingDiv}). */
  public static final class HeadingDiv {
    /** The heading level, 7 or more. */
    public final int level;
    /** The inner text with {@code &lt;}, {@code &gt;} and {@code &amp;} decoded. */
    public final String inner;

    HeadingDiv(int level, String inner) {
      this.level = level;
      this.inner = inner;
    }
  }

  /**
   * A styled-div heading's indent at {@code depth}: {@code (depth − 6) × 0.75},
   * written without a trailing {@code .0} ({@code 0.75}, {@code 1.5}, {@code 3}).
   */
  public static String headingDivIndent(int depth) {
    int quarter = (depth - 6) * 3;
    int whole = Math.floorDiv(quarter, 4);
    switch (Math.floorMod(quarter, 4)) {
      case 0:
        return String.valueOf(whole);
      case 1:
        return whole + ".25";
      case 2:
        return whole + ".5";
      default:
        return whole + ".75";
    }
  }

  /**
   * {@code line} read as a styled-div heading: its level (7 or more) and its
   * inner text with {@code &lt;}, {@code &gt;} and {@code &amp;} decoded, or
   * {@code null}.
   */
  public static HeadingDiv headingDiv(String line) {
    Matcher m = HEADING_DIV_LINE.matcher(line);
    if (!m.matches()) {
      return null;
    }
    int level;
    try {
      level = Integer.parseInt(m.group(1));
    } catch (NumberFormatException e) {
      level = Integer.MAX_VALUE; // more digits than an int holds: still 7 or more.
    }
    if (level < 7) {
      return null;
    }
    return new HeadingDiv(
        level, m.group(2).replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&"));
  }

  /**
   * Whether {@code line} would read as a styled-div heading after any run of
   * backslashes (SOM §11.3): such a value line is written escaped, as a
   * {@code #} line is.
   */
  public static boolean escapableDiv(String line) {
    int k = 0;
    while (k < line.length() && line.charAt(k) == '\\') {
      k++;
    }
    return headingDiv(TRAILING_WS.matcher(line.substring(k)).replaceAll("")) != null;
  }

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
  // The `units="…"` key (SOM §11.2): the same quoting rules as `codeSpec`, but
  // the key must start the region or follow whitespace, so a `units=` inside a
  // quoted codeSpec value is not read as the key.
  static final Pattern UNITS_PATTERN =
      Pattern.compile("(?:^|\\s)units=(?:\"([^\"]*)\"|'([^']*)'|([^,\\s>]+))");

  /**
   * Extracts the {@code units="…"} value from a heading-comment key=value region
   * (SOM §11.2): double-quoted, single-quoted or bare, trimmed. Returns the
   * empty string when the region carries no {@code units} key.
   */
  public static String unitsOf(String region) {
    Matcher m = UNITS_PATTERN.matcher(region);
    if (m.find()) {
      for (int g = 1; g <= 3; g++) {
        if (m.group(g) != null) {
          return m.group(g).trim();
        }
      }
    }
    return "";
  }

  /**
   * Extracts the {@code codeSpec="…"} value from a heading-comment key=value
   * region (codespecs_mapping.md §9.2): double-quoted, single-quoted or bare,
   * trimmed. Returns the empty string when the region carries no
   * {@code codeSpec} key.
   */
  public static String codeSpecOf(String region) {
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
  // Reading view (SOM §11.4, §11.5): a value line shaped like a layout table
  // header is escaped with one space on emit, and loses it on parse.
  private static final Pattern TABLE_HEADER_SHAPED = Pattern.compile(
      "^ *\\|\\s*(?:Section\\s*\\|\\s*)?TomSpecField\\s*\\|\\s*Value\\s*\\|?\\s*$",
      Pattern.CASE_INSENSITIVE);
  private static final Pattern ESCAPED_TABLE_HEADER = Pattern.compile(
      "^ +\\|\\s*(?:Section\\s*\\|\\s*)?TomSpecField\\s*\\|\\s*Value\\s*\\|?\\s*$",
      Pattern.CASE_INSENSITIVE);
  /**
   * A line that reads as the header of a form table or a section table (SOM
   * §11.4, §11.5): {@code | TomSpecField | Value |} or
   * {@code | Section | TomSpecField | Value |} at column 0, any case; group 1
   * is {@code Section} for a section table. The header alone makes a table
   * layout.
   */
  public static final Pattern LAYOUT_TABLE_HEADER = Pattern.compile(
      "^\\|\\s*(?:(Section)\\s*\\|\\s*)?TomSpecField\\s*\\|\\s*Value\\s*\\|?\\s*$",
      Pattern.CASE_INSENSITIVE);
  // A line that starts a table row: `|` after up to three spaces.
  private static final Pattern TABLE_LINE = Pattern.compile("^ {0,3}\\|");
  private static final Pattern DELIMITER_CELL = Pattern.compile("^:?-+:?$");
  private static final Pattern LINK_CELL = Pattern.compile(
      "^\\[[^\\]]+\\]\\([^)]*\\)(, \\[[^\\]]+\\]\\([^)]*\\))*$");
  private static final Pattern LINK_TEXT = Pattern.compile("\\[([^\\]]+)\\]\\([^)]*\\)");
  private static final Pattern LIST_DIV_OPEN =
      Pattern.compile("^:{3,}\\s*(?:\\{\\.(refs|records)\\}|(refs|records))\\s*$");
  private static final Pattern DIV_CLOSE = Pattern.compile("^:{3,}\\s*$");
  private static final Pattern CELL_ANCHOR = Pattern.compile("^<a id=\"[^\"]*\"></a>\\s*");
  private static final Pattern CELL_LINK = Pattern.compile("^\\[([^\\]]+)\\]\\([^)\\s]*\\)$");
  private static final Pattern SECTION_CELL_SEP = Pattern.compile("\\s*/\\s*");
  private static final Pattern REF_SEP = Pattern.compile("[,\\s]+");

  /** A heading's qualified anchor and the scope its descendants' anchors take. */
  private static final class QualifiedAnchor {
    final String anchor;
    final List<String> scope;

    QualifiedAnchor(String anchor, List<String> scope) {
      this.anchor = anchor;
      this.scope = scope;
    }
  }

  private enum AnchorRole { PLAIN, CONTAINER, ITEM, COPY }

  /**
   * The qualified anchor of a heading {@code id} (SOM §11.2) and the scope its
   * descendants' anchors are qualified with: below a list item, or in a
   * {@code @SameAs} copy, an anchor is the ids from the scope's start joined
   * by {@code /}; elsewhere it is the id itself. {@code section} is the id of
   * the nearest heading above that is no list container.
   */
  private static QualifiedAnchor qualifyAnchor(
      List<String> scope, String section, String id, AnchorRole role) {
    List<String> withId = new ArrayList<>();
    if (scope != null) {
      withId.addAll(scope);
    } else if (role == AnchorRole.COPY && section != null) {
      withId.add(section);
    }
    withId.add(id);
    if (role == AnchorRole.COPY) {
      return new QualifiedAnchor(String.join("/", withId), withId);
    }
    String joined = scope == null ? id : String.join("/", withId);
    switch (role) {
      case CONTAINER:
        return new QualifiedAnchor(joined, scope);
      case ITEM:
        return new QualifiedAnchor(joined, withId);
      default:
        return new QualifiedAnchor(joined, scope == null ? null : withId);
    }
  }

  // The whitespace JavaScript's `\s` and `trim()` know, which the reference
  // codecs decide by.
  private static final String WS =
      "[\\t\\n\\x0B\\f\\r \\u00A0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000\\uFEFF]";
  // A section id as a reference holds it: upper-case segments joined by `-`.
  private static final Pattern ID_SHAPE = Pattern.compile("[A-Z][A-Z0-9]*(-[A-Z0-9]+)*");
  // A one-line value that Markdown reads as a block: a list item, a block quote
  // (review comment and question blocks among them), a fence or a fenced div. A
  // table needs two lines, so it is caught by the line break.
  private static final Pattern BLOCK_START = Pattern.compile(
      "^" + WS + "*([-*+]" + WS + "|[0-9]+[.)]" + WS + "|>|```|~~~|:::)");
  // A line that is a block of its own, or would make the line above one, beyond
  // BLOCK_START: a table row, an ATX heading, a setext underline or a thematic
  // break, an HTML block.
  private static final Pattern WRAPPED_LINE_BLOCK = Pattern.compile(
      "^(?:\\||#{1,6}(?:" + WS + "|\\z)|=+\\z|(?:[-*_]" + WS + "*){3,}\\z|<)");

  private static boolean isJsWhitespace(char c) {
    switch (c) {
      case '\t':
      case '\n':
      case '\u000b':
      case '\f':
      case '\r':
      case ' ':
      case '\u00a0':
      case '\u1680':
      case '\u2028':
      case '\u2029':
      case '\u202f':
      case '\u205f':
      case '\u3000':
      case '\ufeff':
        return true;
      default:
        return c >= '\u2000' && c <= '\u200a';
    }
  }

  /** {@code s} without the leading and trailing whitespace the reference codecs trim. */
  private static String trimWs(String s) {
    int a = 0;
    int e = s.length();
    while (a < e && isJsWhitespace(s.charAt(a))) {
      a++;
    }
    while (e > a && isJsWhitespace(s.charAt(e - 1))) {
      e--;
    }
    return s.substring(a, e);
  }

  /**
   * The keys of {@code sorted} at or below {@code prefix}: a binary search to
   * the first key not before it, then the run sharing it as a prefix, so a
   * large document is not scanned once per list item.
   */
  private static List<String> under(List<String> sorted, String prefix) {
    int lo = 0;
    int hi = sorted.size();
    while (lo < hi) {
      int mid = (lo + hi) >>> 1;
      if (sorted.get(mid).compareTo(prefix) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    List<String> out = new ArrayList<>();
    for (int i = lo; i < sorted.size() && sorted.get(i).startsWith(prefix); i++) {
      String k = sorted.get(i);
      if (k.length() == prefix.length() || k.charAt(prefix.length()) == '/') {
        out.add(k);
      }
    }
    return out;
  }

  /**
   * One root's anchors (SOM §11.2): the anchor of the heading a path names,
   * qualified below a list item and in a {@code @SameAs} copy.
   */
  private final class Navigation {
    final SomMetaTree tree;
    private final Map<String, String> anchors = new HashMap<>();

    Navigation(SpecRoot root) {
      this.tree = treeFor(root.type);
    }

    /** The heading id of the item at {@code itemPath} of {@code listNode}, as the emitter writes it. */
    String itemId(SomMetaNode listNode, String itemPath) {
      int slash = itemPath.lastIndexOf('/');
      SpecPaths.ListItemSegment split =
          SpecPaths.splitListItemSegment(itemPath.substring(slash + 1));
      String listPath = itemPath.substring(0, slash + 1) + split.base;
      int pos = document.listItems(listPath).indexOf(itemPath) + 1;
      return SpecSectionId.effectiveListItemSectionId(
          document.itemSectionId(itemPath),
          itemPatternOf(listNode),
          pos == 0 ? split.seq : pos,
          memberStemOf(listNode));
    }

    /** The anchor of the heading {@code path} names in this document. */
    String anchorOf(String path) {
      String hit = anchors.get(path);
      if (hit != null) {
        return hit;
      }
      String[] segs = splitAll(path, "/");
      SomMetaNode node = tree.root;
      String cur = segs[0];
      String anchor = node.segment();
      List<String> scope = null;
      String section = node.segment();
      for (int i = 1; i < segs.length; i++) {
        String seg = segs[i];
        SomMetaNode child = node.childBySegment(seg);
        if (child != null) {
          cur = cur + "/" + seg;
          node = child;
          if (isTransparentSection(child) || isTransparentValue(child)) {
            continue;
          }
          String id = headingIdOf(child);
          boolean container = SomMetaKind.LIST.equals(child.kind);
          AnchorRole role = container
              ? AnchorRole.CONTAINER
              : (isCopyNode(child) ? AnchorRole.COPY : AnchorRole.PLAIN);
          QualifiedAnchor q = qualifyAnchor(scope, section, id, role);
          anchor = q.anchor;
          scope = q.scope;
          if (!container) {
            section = id;
          }
          continue;
        }
        SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(seg);
        SomMetaNode listNode = split == null ? null : node.childBySegment(split.base);
        if (listNode == null || !SomMetaKind.LIST.equals(listNode.kind)) {
          break;
        }
        String itemPath = cur + "/" + seg;
        String id = itemId(listNode, itemPath);
        QualifiedAnchor q = qualifyAnchor(scope, section, id, AnchorRole.ITEM);
        anchor = q.anchor;
        scope = q.scope;
        section = id;
        cur = itemPath;
        SomMetaNode element = listNode.elementNode;
        node = element != null ? element : listNode;
        if (element == null && i < segs.length - 1) {
          break;
        }
      }
      anchors.put(path, anchor);
      return anchor;
    }
  }

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

  /**
   * The stem of the files a reference to another document root links to
   * ({@code <fileStem>.<root id in lower case>.tomspecs.md}), or {@code null}.
   */
  public final String fileStem;
  /**
   * The rendition file of a document root, keyed by its section id or type;
   * a root it does not name takes the {@link #fileStem} name.
   */
  public final Map<String, String> documentFiles;
  /**
   * Whether every section deeper than level 6 is written as a styled-div
   * heading ({@code <div class="heading<N>" style="…">…</div>}, SOM §11.2);
   * the parser reads both forms whatever it says.
   */
  public final boolean headingDivs;
  /**
   * The readable header line of a stripped rendition, written after the
   * {@code docspec} declaration (SOM §11.1), or {@code null}; the parser
   * skips it.
   */
  public final String readableHeader;
  // The document's keys of one kind, sorted once per export for `under`.
  private final Map<String, List<String>> sortedKeys = new HashMap<>();
  // The root the current export renders (the target of same-document links).
  private SpecRoot currentRoot;
  // The anchors of the root the current export renders (SOM §11.2).
  private Navigation nav;
  // The class names each root reaches, for reference links.
  private final Map<String, Set<String>> reach = new HashMap<>();

  /** Binds {@code model} and {@code document} to the codec. */
  public SpecDocumentMarkdown(SpecModel model, SpecDocument document) {
    this(model, document, null, null);
  }

  /**
   * Binds {@code model} and {@code document} to the codec; {@code fileStem}
   * and {@code documentFiles} (either may be {@code null}) name the files a
   * reference to another document root links to.
   */
  public SpecDocumentMarkdown(SpecModel model, SpecDocument document, String fileStem,
      Map<String, String> documentFiles) {
    this(model, document, fileStem, documentFiles, false, null);
  }

  /**
   * {@link #SpecDocumentMarkdown(SpecModel, SpecDocument, String, Map)} with
   * the options of a stripped rendition: {@link #headingDivs} and {@link
   * #readableHeader} ({@code null} for none).
   */
  public SpecDocumentMarkdown(SpecModel model, SpecDocument document, String fileStem,
      Map<String, String> documentFiles, boolean headingDivs, String readableHeader) {
    this.model = model;
    this.document = document;
    this.fileStem = fileStem;
    this.documentFiles =
        documentFiles == null ? new LinkedHashMap<>() : new LinkedHashMap<>(documentFiles);
    this.headingDivs = headingDivs;
    this.readableHeader = readableHeader;
  }

  private List<String> sorted(String kind, Set<String> keys) {
    List<String> sorted = sortedKeys.get(kind);
    if (sorted == null) {
      sorted = new ArrayList<>(keys);
      Collections.sort(sorted);
      sortedKeys.put(kind, sorted);
    }
    return sorted;
  }

  /** The {@code @SectionIdPattern} the items of list {@code node} take their ids from, or {@code null}. */
  private static String itemPatternOf(SomMetaNode node) {
    String pattern = node.sectionIdPattern;
    if ((pattern == null || pattern.isEmpty()) && node.elementNode != null) {
      pattern = node.elementNode.sectionIdPattern;
    }
    return pattern == null || pattern.isEmpty() ? null : pattern;
  }

  /** The stem of the positional ids of a pattern-less list: its member name, else its segment. */
  private static String memberStemOf(SomMetaNode node) {
    String member = node.memberName;
    return member == null || member.isEmpty() ? node.segment() : member;
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
  private static final Pattern EMITTED_HEADING =
      Pattern.compile("^(?:#+ <!--\\[|<div class=\"heading[0-9]+\"[^>]*><!--\\[)");

  /** The paths of the headings written by the current export, in order. */
  private final List<String> headingPaths = new ArrayList<>();

  private String exportRootText(SpecRoot root) {
    currentRoot = root;
    nav = new Navigation(root);
    sortedKeys.clear();
    SomMetaTree tree = treeFor(root.type);
    SomMetaNode node = tree.root;
    StringBuilder b = new StringBuilder();
    writeln(b, "<!-- docspec: " + kebabCase(root.title) + "/"
        + model.modelVersionString() + " -->");
    if (readableHeader != null) {
      writeln(b, readableHeader);
    }
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
    nav = null;
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
   * Whether {@code n} is a {@code @SameAs} copy (SOM §11.2): its anchor and
   * its descendants' are qualified with the section above it.
   */
  private boolean isCopyNode(SomMetaNode n) {
    SomMetaNode parent = n.wiredParent;
    if (n.memberName == null || n.memberName.isEmpty() || parent == null) {
      return false;
    }
    SpecClass cls = model.classNamed(parent.className);
    SpecField f = cls != null ? cls.fieldNamed(n.memberName) : null;
    if (f == null) {
      return false;
    }
    for (SpecAnnotation a : f.annotations) {
      if ("SameAs".equals(a.name)) {
        return true;
      }
    }
    return false;
  }

  /**
   * The item class's own form (its class-level {@code @Form}, a transparent
   * body slot), or {@code null} when the class carries none or more than one.
   */
  private NodeRel itemForm(SomMetaNode element) {
    NodeRel found = null;
    for (NodeRel s : bodySlots(element)) {
      if (SomMetaKind.FORM.equals(s.node.kind)) {
        if (found != null) {
          return null;
        }
        found = s;
      }
    }
    return found;
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
        if (!writeSectionTable(b, child, path)) {
          writeChildren(b, child, path, depth + 1);
        }
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
    String pattern = itemPatternOf(node);
    String memberStem = memberStemOf(node);
    if (writeReferenceLine(b, node, items, pattern)
        || writeRecordTable(b, node, items, pattern)) {
      return;
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
        if (!element.recursive && !writeSectionTable(b, element, itemPath)) {
          writeChildren(b, element, itemPath, depth + 2);
        }
      }
    }
  }

  // --- Reading view: reference lines, record tables, section tables ----------

  private boolean hasKeys(String path) {
    String codeSpec = document.codeSpec(path);
    String units = document.units(path);
    return (codeSpec != null && !codeSpec.isEmpty()) || (units != null && !units.isEmpty());
  }

  private static List<SomFormFieldMeta> fieldsOf(SomMetaNode node) {
    return node.form != null ? node.form.fields : new ArrayList<>();
  }

  /** The anchor of the heading or table row standing for {@code path}. */
  private String anchorFor(String path, String id) {
    return nav != null ? nav.anchorOf(path) : id;
  }

  /**
   * Whether the item at {@code itemPath} holds values only in its form at
   * {@code formPath}, all of them table cells: no preamble, no other content,
   * form or list, no {@code codeSpec} / {@code units}, no headline other than
   * the item's own when {@code allowHeadline}.
   */
  private boolean isFormOnlyItem(
      SomMetaNode form, String itemPath, String formPath, boolean allowHeadline) {
    SpecDocument doc = document;
    if (!under(sorted("content", doc.contentPaths()), itemPath).isEmpty()) {
      return false;
    }
    if (!under(sorted("lists", doc.listPaths()), itemPath).isEmpty()) {
      return false;
    }
    if (!under(sorted("units", doc.unitsPaths()), itemPath).isEmpty()) {
      return false;
    }
    for (String k : under(sorted("forms", doc.formPaths()), itemPath)) {
      if (!k.equals(formPath)) {
        return false;
      }
    }
    for (String h : under(sorted("headlines", doc.headlinePaths()), itemPath)) {
      if (!allowHeadline || !h.equals(itemPath)) {
        return false;
      }
    }
    if (hasKeys(itemPath) || hasKeys(formPath)) {
      return false;
    }
    if (!undeclaredFormFields(form, formPath).isEmpty()) {
      return false;
    }
    boolean any = false;
    for (SomFormFieldMeta f : fieldsOf(form)) {
      String value = doc.formField(formPath, f.name);
      if (value == null) {
        continue;
      }
      if (!isCellValue(f, value)) {
        return false;
      }
      any = true;
    }
    return any;
  }

  /**
   * A list whose every item holds only one reference id becomes one
   * {@code refs} div of links in list order. All or nothing; returns whether
   * it was written.
   */
  private boolean writeReferenceLine(
      StringBuilder b, SomMetaNode node, List<String> items, String pattern) {
    SomMetaNode element = node.elementNode;
    if (element == null || element.recursive) {
      return false;
    }
    NodeRel ref = null;
    for (NodeRel c : effectiveChildren(element)) {
      List<SomFormFieldMeta> fields = fieldsOf(c.node);
      if (!SomMetaKind.FORM.equals(c.node.kind)
          || fields.size() != 1
          || fields.get(0).refersTo.isEmpty()) {
        continue;
      }
      boolean reference = false;
      for (SomMetaExtra e : c.node.extra) {
        if ("Reference".equals(e.annotation)) {
          reference = true;
          break;
        }
      }
      if (reference) {
        ref = c;
        break;
      }
    }
    if (ref == null) {
      return false;
    }
    SomFormFieldMeta field = ref.node.form.fields.get(0);
    SpecDocument doc = document;
    List<String> links = new ArrayList<>();
    for (int i = 0; i < items.size(); i++) {
      String itemPath = items.get(i);
      String refPath = itemPath + "/" + ref.rel;
      String stored = doc.itemSectionId(itemPath);
      String positional =
          SpecSectionId.effectiveListItemSectionId(null, pattern, i + 1, memberStemOf(node));
      if (stored != null && !stored.equals(positional)) {
        return false;
      }
      if (!under(sorted("content", doc.contentPaths()), itemPath).isEmpty()
          || !under(sorted("lists", doc.listPaths()), itemPath).isEmpty()
          || !under(sorted("units", doc.unitsPaths()), itemPath).isEmpty()
          || !under(sorted("headlines", doc.headlinePaths()), itemPath).isEmpty()
          || hasKeys(itemPath)
          || hasKeys(refPath)) {
        return false;
      }
      for (String k : under(sorted("forms", doc.formPaths()), itemPath)) {
        if (!k.equals(refPath)) {
          return false;
        }
      }
      Set<String> names = doc.formFieldNames(refPath);
      if (names.size() != 1 || !names.contains(field.name)) {
        return false;
      }
      String raw = doc.formField(refPath, field.name);
      String id = trimWs(raw == null ? "" : raw);
      if (!ID_SHAPE.matcher(id).matches()) {
        return false;
      }
      String link = link(field, id);
      links.add(link != null ? link : id);
    }
    writeln(b, "::: {.refs}");
    writeln(b, String.join(", ", links));
    writeln(b, ":::");
    writeln(b, "");
    return true;
  }

  /**
   * A list whose every item is one form of table cells becomes a
   * {@code records} div with one table: {@code Id} (with its anchor),
   * {@code Title} when any item has a stored headline, one column per declared
   * field any item populates. All or nothing; returns whether it was written.
   */
  private boolean writeRecordTable(
      StringBuilder b, SomMetaNode node, List<String> items, String pattern) {
    SomMetaNode element = node.elementNode;
    if (element == null || element.recursive) {
      return false;
    }
    NodeRel formSlot = itemForm(element);
    if (formSlot == null) {
      return false;
    }
    SomMetaNode form = formSlot.node;
    String rel = formSlot.rel;
    for (String itemPath : items) {
      if (!isFormOnlyItem(form, itemPath, itemPath + "/" + rel, true)) {
        return false;
      }
    }
    SpecDocument doc = document;
    List<SomFormFieldMeta> columns = new ArrayList<>();
    for (SomFormFieldMeta f : fieldsOf(form)) {
      for (String i : items) {
        if (doc.formField(i + "/" + rel, f.name) != null) {
          columns.add(f);
          break;
        }
      }
    }
    boolean withTitle = false;
    for (String i : items) {
      if (doc.headline(i) != null) {
        withTitle = true;
        break;
      }
    }
    List<String> header = new ArrayList<>();
    header.add("Id");
    if (withTitle) {
      header.add("Title");
    }
    for (SomFormFieldMeta f : columns) {
      header.add(formLabel(f.name));
    }
    writeln(b, "::: {.records}");
    writeln(b, "| " + String.join(" | ", header) + " |");
    writeln(b, "| " + String.join(" | ", Collections.nCopies(header.size(), "---")) + " |");
    for (int i = 0; i < items.size(); i++) {
      String itemPath = items.get(i);
      String id = SpecSectionId.effectiveListItemSectionId(
          doc.itemSectionId(itemPath), pattern, i + 1, memberStemOf(node));
      List<String> cells = new ArrayList<>();
      cells.add("<a id=\"" + anchorFor(itemPath, id) + "\"></a>" + id);
      if (withTitle) {
        String title = doc.headline(itemPath);
        cells.add((title == null ? "" : title).replace("\n", "<br>").replace("|", "\\|"));
      }
      for (SomFormFieldMeta f : columns) {
        String v = doc.formField(itemPath + "/" + rel, f.name);
        cells.add(v == null ? "" : linkedCellText(f, v));
      }
      writeln(b, "| " + String.join(" | ", cells) + " |");
    }
    writeln(b, ":::");
    writeln(b, "");
    return true;
  }

  private void addSectionRows(
      List<String> rows, String sectionCell, SomMetaNode form, String formPath) {
    boolean first = true;
    for (SomFormFieldMeta f : fieldsOf(form)) {
      String value = document.formField(formPath, f.name);
      if (value == null) {
        continue;
      }
      rows.add("| " + (first ? sectionCell : "") + " | " + formLabel(f.name) + " | "
          + linkedCellText(f, value) + " |");
      first = false;
    }
  }

  /**
   * A section whose populated children are all single forms of table cells
   * with default headlines (or lists of such single-form items) becomes one
   * {@code | Section | TomSpecField | Value |} table after its own body; the
   * children's headings are not written. All or nothing; returns whether it
   * was written.
   */
  private boolean writeSectionTable(StringBuilder b, SomMetaNode node, String path) {
    SpecDocument doc = document;
    List<String> rows = new ArrayList<>();
    int children = 0;
    for (NodeRel entry : effectiveChildren(node)) {
      SomMetaNode child = entry.node;
      String childPath = path + "/" + entry.rel;
      if (!doc.hasValuesUnder(childPath)) {
        continue;
      }
      children++;
      String childId = headingIdOf(child);
      if (SomMetaKind.FORM.equals(child.kind)) {
        if (!isFormOnlyItem(child, childPath, childPath, false)) {
          return false;
        }
        addSectionRows(rows,
            "<a id=\"" + anchorFor(childPath, childId) + "\"></a>" + childId, child, childPath);
      } else if (SomMetaKind.LIST.equals(child.kind)) {
        SomMetaNode element = child.elementNode;
        if (element == null || element.recursive) {
          return false;
        }
        if (doc.headline(childPath) != null || hasKeys(childPath)) {
          return false;
        }
        NodeRel formSlot = itemForm(element);
        if (formSlot == null) {
          return false;
        }
        List<String> items = doc.listItems(childPath);
        String pattern = itemPatternOf(child);
        for (int i = 0; i < items.size(); i++) {
          String itemPath = items.get(i);
          String formPath = itemPath + "/" + formSlot.rel;
          if (!isFormOnlyItem(formSlot.node, itemPath, formPath, false)) {
            return false;
          }
          String itemId = SpecSectionId.effectiveListItemSectionId(
              doc.itemSectionId(itemPath), pattern, i + 1, memberStemOf(child));
          addSectionRows(rows,
              "<a id=\"" + anchorFor(itemPath, itemId) + "\"></a>" + childId + " / " + itemId,
              formSlot.node, formPath);
        }
      } else {
        return false;
      }
    }
    if (children == 0 || rows.isEmpty()) {
      return false;
    }
    writeln(b, "| Section | TomSpecField | Value |");
    writeln(b, "| --- | --- | --- |");
    for (String row : rows) {
      writeln(b, row);
    }
    writeln(b, "");
    return true;
  }

  /**
   * {@code value} as a table cell, every reference id of a {@code refersTo}
   * field written as a link to its section.
   */
  private String linkedCellText(SomFormFieldMeta f, String value) {
    if (f.refersTo.isEmpty() || f.code) {
      return cellText(f, value);
    }
    String joined = wrappedParagraphJoined(value);
    if (joined != null) {
      value = joined;
    }
    List<String> links = new ArrayList<>();
    for (String part : splitAll(value, ",")) {
      String id = trimWs(part);
      if (!ID_SHAPE.matcher(id).matches()) {
        return cellText(f, value);
      }
      String link = link(f, id);
      if (link == null) {
        return cellText(f, value);
      }
      links.add(link);
    }
    return String.join(", ", links);
  }

  /**
   * {@code [ID](<file>#ID)} for a reference id of form field {@code f},
   * {@code [ID](#ID)} when the target lives in the document being rendered;
   * {@code null} when no target of {@code f} names a section id
   * ({@code <SECTIONID>.@sectionId}), which has no anchor.
   */
  private String link(SomFormFieldMeta f, String id) {
    List<String> classIds = new ArrayList<>();
    for (String t : f.refersTo) {
      if (t.endsWith(".@sectionId")) {
        classIds.add(t.substring(0, t.length() - 11));
      }
    }
    if (classIds.isEmpty()) {
      return null;
    }
    for (String classId : classIds) {
      String className = classBySectionId(classId);
      if (className != null && currentRoot != null
          && reachedBy(currentRoot).contains(className)) {
        return "[" + id + "](#" + id + ")";
      }
    }
    String file = fileFor(classBySectionId(classIds.get(0)));
    return file == null ? "[" + id + "](#" + id + ")" : "[" + id + "](" + file + "#" + id + ")";
  }

  private String classBySectionId(String sectionId) {
    for (SpecClass c : model.classes.values()) {
      if (sectionId.equals(c.sectionId)) {
        return c.name;
      }
    }
    return null;
  }

  /** The class names the meta tree of {@code root} reaches. */
  private Set<String> reachedBy(SpecRoot root) {
    Set<String> names = reach.get(root.type);
    if (names == null) {
      names = new HashSet<>();
      collectReach(treeFor(root.type).root, names);
      reach.put(root.type, names);
    }
    return names;
  }

  private static void collectReach(SomMetaNode n, Set<String> found) {
    found.add(n.className);
    if (n.recursive) {
      return;
    }
    for (SomMetaNode c : n.children) {
      collectReach(c, found);
    }
    if (n.elementNode != null) {
      collectReach(n.elementNode, found);
    }
  }

  /**
   * The rendition file of the root a reference to {@code className} points
   * into: the root other than the current one that reaches the class, the most
   * specific (fewest classes) first, so a detailed document wins over a
   * projection such as the Solution Blueprint. The CodeSpecs projection is no
   * document anyone renders, so it is never a target.
   */
  private String fileFor(String className) {
    if (className == null) {
      return null;
    }
    String currentType = currentRoot != null ? currentRoot.type : null;
    SpecRoot best = null;
    for (SpecRoot r : model.roots) {
      if (r.type.equals(currentType)) {
        continue;
      }
      SpecClass cls = model.classNamed(r.type);
      if (cls != null && cls.hasAnnotation("CodeSpecsProjection")) {
        continue;
      }
      if (!reachedBy(r).contains(className)) {
        continue;
      }
      if (best == null || reachedBy(r).size() < reachedBy(best).size()) {
        best = r;
      }
    }
    return best == null ? null : fileOfRoot(best);
  }

  /**
   * The rendition file of {@code root}: {@code <fileStem>.<root id>.tomspecs.md},
   * or the name {@link #documentFiles} gives it.
   */
  private String fileOfRoot(SpecRoot root) {
    String id = root.sectionId != null ? root.sectionId : root.type;
    String mapped = documentFiles.get(id);
    if (mapped == null) {
      mapped = documentFiles.get(root.type);
    }
    if (mapped != null) {
      return mapped;
    }
    String name = id.toLowerCase(Locale.ROOT) + ".tomspecs.md";
    return fileStem == null || fileStem.isEmpty() ? name : fileStem + "." + name;
  }

  /**
   * Whether {@code value} of form field {@code f} is written as a table row:
   * not when the model flags the field {@code multiParagraph}, nor when the
   * value holds a line break other than the soft breaks of one wrapped
   * paragraph ({@link #wrappedParagraphJoined}; a {@code code} value keeps
   * every line break), is a block of Markdown, holds a backslash directly
   * before {@code |}, or holds {@code <!--}. There is no length limit.
   */
  static boolean isCellValue(SomFormFieldMeta f, String value) {
    if (f.multiParagraph) {
      return false;
    }
    if (value.contains("\\|") || value.contains("<!--")) {
      return false;
    }
    if (value.indexOf('\n') >= 0 && (f.code || wrappedParagraphJoined(value) == null)) {
      return false;
    }
    return !BLOCK_START.matcher(value).find();
  }

  /**
   * {@code value} on one line when it is one paragraph wrapped over several
   * lines — no blank line, and no line that Markdown reads as a block or a
   * block's start (a list item, a quote, a fence, a fenced div, a table row, a
   * heading, a setext underline or a thematic break), that ends in a hard
   * break (a trailing backslash or spaces) or that starts with a space: its
   * soft line breaks, which Markdown reads as spaces, become spaces (SOM
   * §11.4 rule 13). {@code null} for any other value, a one-line value among
   * them.
   */
  public static String wrappedParagraphJoined(String value) {
    if (value.indexOf('\n') < 0) {
      return null;
    }
    String[] lines = splitLines(value);
    for (String l : lines) {
      if (l.isEmpty()
          || !l.equals(trimWs(l))
          || l.endsWith("\\")
          || BLOCK_START.matcher(l).find()
          || WRAPPED_LINE_BLOCK.matcher(l).find()) {
        return null;
      }
    }
    return String.join(" ", lines);
  }

  /**
   * The table cell for {@code value}: a {@code code: true} value as its inline
   * code span, every {@code |} written {@code \|}.
   */
  static String cellText(SomFormFieldMeta f, String value) {
    String joined = wrappedParagraphJoined(value);
    if (joined != null) {
      value = joined;
    }
    String text = f.code && isInlineCode(value) ? encodeCodeSpan(value) : value;
    return text.replace("|", "\\|");
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
   * Writes a {@code @Form} section body (SOM §11.4): the preamble, then the
   * declared fields in model order — each run of consecutive cell values one
   * {@code | TomSpecField | Value |} table, each paragraph value a
   * {@code Field:} group at its place (table – text – table). Groups are one
   * blank line apart. A value line that would read as a table header is
   * escaped by {@link #prepareValue}. Throws {@link IllegalStateException}
   * when the form holds a field the model does not declare.
   */
  private void writeForm(StringBuilder b, SomMetaNode node, String path) {
    checkFormDeclared(node, path);
    List<List<String>> groups = new ArrayList<>();
    List<String> table = null;
    for (SomFormFieldMeta f : fieldsOf(node)) {
      String value = document.formField(path, f.name);
      if (value == null) {
        continue;
      }
      String label = formLabel(f.name);
      if (isCellValue(f, value)) {
        if (table == null) {
          table = new ArrayList<>();
          table.add("| TomSpecField | Value |");
          table.add("| --- | --- |");
          groups.add(table);
        }
        table.add("| " + label + " | " + linkedCellText(f, value) + " |");
        continue;
      }
      table = null;
      // SOM §11.4 rule 8: a single-line code value is written as an inline
      // code span, so markdown leaves it literal (`](` is not a link).
      String[] lines = f.code && isInlineCode(value)
          ? new String[] {encodeCodeSpan(value)}
          : splitLines(prepareValue(value, path));
      List<String> group = new ArrayList<>();
      group.add(label + ": " + lines[0]);
      for (int i = 1; i < lines.length; i++) {
        // Any continuation line that could be mistaken for a field-label line
        // gains one leading space; parse strips it.
        group.add(LABEL_SHAPED.matcher(lines[i]).find() ? " " + lines[i] : lines[i]);
      }
      groups.add(group);
    }

    String preamble = document.content(path);
    if (preamble != null) {
      String prepared = prepareValue(preamble, path);
      if (!prepared.isEmpty()) {
        // Every preamble line gets the same label-shaped escape a continuation
        // line gets: the parser reaches a field label before it knows which
        // text is preamble, so a `Word:` line at column 0 would mis-split.
        for (String line : splitLines(prepared)) {
          writeln(b, LABEL_SHAPED.matcher(line).find() ? " " + line : line);
        }
        if (!groups.isEmpty()) {
          writeln(b, "");
        }
      }
    }
    for (int i = 0; i < groups.size(); i++) {
      if (i > 0) {
        writeln(b, "");
      }
      for (String line : groups.get(i)) {
        writeln(b, line);
      }
    }
    writeln(b, "");
  }

  /**
   * Writes {@code ## <!--[ID]--> <a id="ID"></a> Title} at {@code depth}. SOM §11.2 is
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
    // SOM §11.2: the section's generation units follow as a second key,
    // ` units="…"`, after `codeSpec`; absent when the section carries none.
    String units = document.units(path);
    if (units != null && !units.isEmpty()) {
      cs += " units=\"" + units + "\"";
    }
    // A heading is one line: a stored headline's line breaks travel as `<br>`.
    // The section id follows as an HTML anchor after the id comment and its
    // keys, so `#<ID>` links jump in every viewer; below a list item or in a
    // `@SameAs` copy the anchor is qualified (SOM §11.2).
    String anchor = anchorFor(path, id);
    if (headingDivs && depth > 6) {
      // A styled-div heading (SOM §11.2, DocSpecs *Styled-div headings*): one
      // line, the title HTML-escaped, the indent growing with the depth.
      String escaped = title.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
          .replace("\n", "<br>");
      writeln(b, "<div class=\"heading" + depth + "\" style=\"" + HEADING_DIV_STYLE_START
          + headingDivIndent(depth) + "em;font-weight:bold\"><!--[" + id + "]" + cs
          + "--> <a id=\"" + anchor + "\"></a> " + escaped + "</div>");
      writeln(b, "");
      return;
    }
    writeln(b, "#".repeat(depth) + " <!--[" + id + "]" + cs + "--> <a id=\""
        + anchor + "\"></a> " + title.replace("\n", "<br>"));
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
      } else if (ESCAPABLE.matcher(line).find() || escapableDiv(line)) {
        out.add("\\" + line);
      } else if (TABLE_HEADER_SHAPED.matcher(line).find()) {
        out.add(" " + line); // a value line is never a layout table.
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
    result.units.putAll(p.units);
    result.rejections.addAll(p.rejections);
    result.rootPrefixes.addAll(p.rootPrefixes);
    result.keptContent.putAll(p.keptContent);
    result.readableHeader = p.readableHeader;
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
    // Rejected blocks to keep in this frame's text (RN-11): the body index
    // they stand before, the block, and the end of the body lines it replaces
    // (the index itself when it replaces none).
    final List<KeptMark> kept = new ArrayList<>();
    // For an ignored frame: the blocks of its ignored children, kept after its
    // own block wherever that lands.
    final List<KeptBlock> deferred = new ArrayList<>();
    // The scope this heading's descendants' anchors are qualified with, and
    // the id of the nearest heading at or above it that is no list container
    // (SOM §11.2, qualifyAnchor).
    List<String> anchorScope;
    String anchorSection;

    MdFrame(int level, SomMetaNode node, String path, int line, boolean ignored) {
      this.level = level;
      this.node = node;
      this.path = path;
      this.line = line;
      this.ignored = ignored;
    }
  }

  private static final Pattern KEPT_DIV_OPEN = Pattern.compile(
      "^ {0,3}:{3,}[ \\t]*(?:\\{.*\\}|[A-Za-z][A-Za-z0-9_-]*)[ \\t]*\\z");
  private static final Pattern KEPT_DIV_CLOSE = Pattern.compile("^ {0,3}:{3,}[ \\t]*\\z");
  private static final Pattern KEPT_COLONS = Pattern.compile("^ {0,3}(:{3,})");
  private static final Pattern KEPT_FIRST_COLON = Pattern.compile("^( {0,3}):");
  private static final Pattern NEAR_MISS_SEPARATORS = Pattern.compile(WS + "|[_-]");

  /**
   * A rejected block an import that accepts rejections keeps for review
   * (SOM §11.7, DocSpecs RN-11): the source lines it held and what its
   * {@code rejected} div records for a resolution.
   */
  private static final class KeptBlock {
    final SpecMarkdownRejection rejection;
    /** The source lines of the block, as written. */
    List<String> lines;
    /** The field given twice, or the declared field a near-miss label names. */
    final String field;
    /** The child section a near-miss section-table cell names. */
    final String section;
    /** For a field given twice: the path of the form holding the kept value. */
    final String kept;

    KeptBlock(SpecMarkdownRejection rejection, List<String> lines, String field,
        String section, String kept) {
      this.rejection = rejection;
      this.lines = lines;
      this.field = field;
      this.section = section;
      this.kept = kept;
    }

    private static String quoted(String s) {
      return s.replace('"', '\'');
    }

    /**
     * The block as a {@code rejected} div: {@code reason}, {@code line}, then
     * {@code field} / {@code section} / {@code kept} where they apply, then
     * {@code label} (the report's message, its double quotes written as
     * single ones). A fence the block does not close, or closes without
     * opening, would pair with the div's own fences, so it is written escaped
     * ({@code \:::}, RN-9); the div's fences are longer than any fence inside
     * it, for the eye (RN-7).
     */
    List<String> div() {
      List<String> inner = new ArrayList<>(lines);
      while (!inner.isEmpty() && trimWs(inner.get(0)).isEmpty()) {
        inner.remove(0);
      }
      while (!inner.isEmpty() && trimWs(inner.get(inner.size() - 1)).isEmpty()) {
        inner.remove(inner.size() - 1);
      }
      MarkdownFenceTracker fence = new MarkdownFenceTracker();
      List<Integer> open = new ArrayList<>();
      Set<Integer> unpaired = new HashSet<>();
      for (int k = 0; k < inner.size(); k++) {
        String line = inner.get(k);
        if (!fence.inFence()) {
          if (KEPT_DIV_CLOSE.matcher(line).find()) {
            if (open.isEmpty()) {
              unpaired.add(k);
            } else {
              open.remove(open.size() - 1);
            }
          } else if (KEPT_DIV_OPEN.matcher(line).find()) {
            open.add(k);
          }
        }
        fence.feed(line);
      }
      unpaired.addAll(open);
      int longest = 0;
      for (int k = 0; k < inner.size(); k++) {
        if (unpaired.contains(k)) {
          inner.set(k, KEPT_FIRST_COLON.matcher(inner.get(k)).replaceFirst("$1\\\\:"));
          continue;
        }
        Matcher m = KEPT_COLONS.matcher(inner.get(k));
        int run = m.find() ? m.group(1).length() : 0;
        if (run > longest) {
          longest = run;
        }
      }
      String colons = ":".repeat(longest >= 3 ? longest + 1 : 3);
      StringBuilder attributes = new StringBuilder();
      attributes.append("reason=\"").append(rejection.reason.value).append('"');
      attributes.append(" line=\"").append(rejection.line).append('"');
      if (field != null) {
        attributes.append(" field=\"").append(quoted(field)).append('"');
      }
      if (section != null) {
        attributes.append(" section=\"").append(quoted(section)).append('"');
      }
      if (kept != null) {
        attributes.append(" kept=\"").append(quoted(kept)).append('"');
      }
      attributes.append(" label=\"").append(quoted(rejection.message)).append('"');
      List<String> out = new ArrayList<>(inner.size() + 2);
      out.add(colons + " {.rejected " + attributes + "}");
      out.addAll(inner);
      out.add(colons);
      return out;
    }
  }

  /** A kept block's place in a frame's body: before {@code at}, replacing the lines up to {@code end}. */
  private static final class KeptMark {
    final int at;
    final KeptBlock block;
    final int end;

    KeptMark(int at, KeptBlock block, int end) {
      this.at = at;
      this.block = block;
      this.end = end;
    }
  }

  /** A div written into a line list at position {@code at}. */
  private static final class KeptInsert {
    final int at;
    final List<String> div;

    KeptInsert(int at, List<String> div) {
      this.at = at;
      this.div = div;
    }
  }

  /**
   * Where the rejected blocks of one frame's body go (RN-11): each content
   * line list of the frame and the divs written into it, by position.
   */
  private static final class Keeper {
    private final List<KeptMark> marks;
    private int next;
    // Keyed by the line list itself, not by its lines.
    private final Map<List<String>, List<KeptInsert>> inserts = new IdentityHashMap<>();

    Keeper(MdFrame frame) {
      marks = new ArrayList<>(frame.kept);
      marks.sort((a, b) -> Integer.compare(a.at, b.at)); // stable
    }

    /** Writes {@code b} into {@code into} at its current end. */
    void keep(List<String> into, KeptBlock b) {
      inserts.computeIfAbsent(into, k -> new ArrayList<>())
          .add(new KeptInsert(into.size(), b.div()));
    }

    /** Writes the frame's blocks standing before body index {@code upTo} into {@code into}. */
    void drain(int upTo, List<String> into) {
      while (next < marks.size() && marks.get(next).at <= upTo) {
        keep(into, marks.get(next).block);
        next++;
      }
    }

    /**
     * The value of {@code parts} with the kept divs written in, joined as the
     * parts are; null when no part holds one.
     */
    String keptValue(List<List<String>> parts) {
      boolean any = false;
      for (List<String> part : parts) {
        any |= inserts.containsKey(part);
      }
      if (!any) {
        return null;
      }
      List<String> values = new ArrayList<>();
      for (List<String> part : parts) {
        List<KeptInsert> ins = inserts.get(part);
        String v = MdParser.restoreValue(
            ins == null ? part : MdParser.merge(part, ins, Collections.emptySet()));
        if (!v.isEmpty()) {
          values.add(v);
        }
      }
      return String.join("\n\n", values);
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
    // Stored generation units staged from the `units="…"` key (SOM §11.2).
    final Map<String, String> units = new LinkedHashMap<>();
    final Map<String, MdListState> lists = new LinkedHashMap<>();
    final List<String> listOrder = new ArrayList<>();
    final List<SpecMarkdownRejection> rejections = new ArrayList<>();
    final List<String> rootPrefixes = new ArrayList<>();
    final List<MdFrame> stack = new ArrayList<>();
    final MarkdownFenceTracker fence = new MarkdownFenceTracker();
    // The fields given so far per form path, for the given-twice rule.
    final Map<String, Set<String>> given = new LinkedHashMap<>();
    // Rolling pointer into a body region's transparent form slots — labels
    // bind to the nearest form at or after the last hit (wrapping), so
    // repeated field names across an owner's transparent forms follow emit
    // order.
    int currentFormIdx;
    final Map<String, String> keptContent = new LinkedHashMap<>();
    /** The readable header a stripped rendition carries (SOM §11.1). */
    String readableHeader;
    // The source lines, for the text of a rejected block.
    String[] source = new String[0];
    // Blocks reported by reject and not yet placed.
    List<KeptBlock> pending = new ArrayList<>();
    // Text before the root heading, kept at the start of the root's text.
    final List<KeptBlock> orphans = new ArrayList<>();

    MdParser(SpecDocumentMarkdown codec) {
      this.codec = codec;
    }

    /** The held blocks in source order, the hold emptied. */
    private List<KeptBlock> takePending() {
      List<KeptBlock> out = pending;
      pending = new ArrayList<>();
      out.sort((a, b) -> Integer.compare(a.rejection.line, b.rejection.line)); // stable
      return out;
    }

    /**
     * Places the held blocks before {@code frame}'s body index {@code at},
     * taking the place of the body lines up to {@code replaceEnd}
     * ({@code at} itself: none).
     */
    private void markPending(MdFrame frame, int at, int replaceEnd) {
      for (KeptBlock b : takePending()) {
        frame.kept.add(new KeptMark(at, b, replaceEnd));
      }
    }

    private static String nearMissNorm(String s) {
      return NEAR_MISS_SEPARATORS.matcher(s.toLowerCase(Locale.ROOT)).replaceAll("");
    }

    /**
     * The declared name one edit (or only case and separators) away from
     * {@code label}, when exactly one is: what a <i>Rename to</i> choice
     * offers (RN-11).
     */
    static String nearMiss(String label, List<String> names) {
      Set<String> hits = new LinkedHashSet<>();
      for (String n : names) {
        if (!n.equals(label)
            && (nearMissNorm(n).equals(nearMissNorm(label))
                || oneEdit(n.toLowerCase(Locale.ROOT), label.toLowerCase(Locale.ROOT)))) {
          hits.add(n);
        }
      }
      return hits.size() == 1 ? hits.iterator().next() : null;
    }

    /** Whether {@code a} becomes {@code b} by at most one insertion, deletion or substitution. */
    static boolean oneEdit(String a, String b) {
      if (Math.abs(a.length() - b.length()) > 1) {
        return false;
      }
      int i = 0;
      int j = 0;
      int edits = 0;
      while (i < a.length() && j < b.length()) {
        if (a.charAt(i) == b.charAt(j)) {
          i++;
          j++;
          continue;
        }
        if (++edits > 1) {
          return false;
        }
        if (a.length() > b.length()) {
          i++;
        } else if (b.length() > a.length()) {
          j++;
        } else {
          i++;
          j++;
        }
      }
      return edits + (a.length() - i) + (b.length() - j) <= 1;
    }

    private static List<String> fieldNames(List<SomFormFieldMeta> fields) {
      List<String> names = new ArrayList<>(fields.size());
      for (SomFormFieldMeta f : fields) {
        names.add(f.name);
      }
      return names;
    }

    /**
     * {@code part} with the divs of {@code ins} written in at their
     * positions, a blank line between a div and the text around it; the lines
     * at {@code replaced} positions are left out (a div took their place).
     */
    static List<String> merge(List<String> part, List<KeptInsert> ins, Set<Integer> replaced) {
      List<String> out = new ArrayList<>();
      boolean blankDue = false;
      for (int k = 0; k <= part.size(); k++) {
        for (KeptInsert in : ins) {
          if (in.at != k) {
            continue;
          }
          if (!out.isEmpty() && !trimWs(out.get(out.size() - 1)).isEmpty()) {
            out.add("");
          }
          out.addAll(in.div);
          blankDue = true;
        }
        if (k == part.size() || replaced.contains(k)) {
          continue;
        }
        String line = part.get(k);
        if (blankDue && !trimWs(line).isEmpty()) {
          out.add("");
        }
        blankDue = false;
        out.add(line);
      }
      return out;
    }

    /**
     * Whether a frame of {@code node} passes its rejected blocks to its
     * parent: a list container, which holds no text, and a scalar or enum
     * value, whose text is a typed value (RN-11).
     */
    private static boolean keptInParent(SomMetaNode node) {
      return node != null
          && (SomMetaKind.LIST.equals(node.kind)
              || SomMetaKind.SCALAR.equals(node.kind)
              || SomMetaKind.ENUM_VALUE.equals(node.kind));
    }

    /**
     * An ignored frame's heading and body, with its ignored children's blocks
     * after it, go to the text of the nearest section above it that was read,
     * after that section's own text (RN-11); with none above (an unknown
     * root) nothing holds them and only the report remains.
     */
    private void keepIgnored(MdFrame frame) {
      SpecMarkdownRejection own = null;
      for (SpecMarkdownRejection r : rejections) {
        if (r.line == frame.line) {
          own = r;
        }
      }
      List<KeptBlock> blocks = new ArrayList<>();
      if (own != null) {
        List<String> lines = new ArrayList<>(frame.body.size() + 1);
        lines.add(source[frame.line - 1]);
        lines.addAll(frame.body);
        blocks.add(new KeptBlock(own, lines, null, null, null));
      }
      blocks.addAll(frame.deferred);
      if (stack.isEmpty() || blocks.isEmpty()) {
        return;
      }
      MdFrame parent = stack.get(stack.size() - 1);
      if (parent.ignored) {
        parent.deferred.addAll(blocks);
        return;
      }
      for (KeptBlock b : blocks) {
        parent.kept.add(new KeptMark(parent.body.size(), b, parent.body.size()));
      }
    }

    void run(String[] lines) {
      source = lines;
      for (int i = 0; i < lines.length; i++) {
        String raw = lines[i];
        int lineNo = i + 1;
        String trimmed = TRAILING_WS.matcher(raw).replaceAll("");

        if (!fence.inFence()) {
          if (stack.isEmpty() && DOCSPEC_COMMENT.matcher(trimmed).matches()) {
            continue; // SOM §11.1 header — informational.
          }
          if (stack.isEmpty()
              && readableHeader == null
              && READABLE_COMMENT.matcher(trimmed).matches()) {
            readableHeader = trimmed; // SOM §11.1 readable header — skipped.
            continue;
          }
          if (readableHeader != null && trimmed.equals(APPENDIX_MARKER)) {
            break; // A stripped rendition's appendix is not the document.
          }
          Matcher h = HEADING_LINE.matcher(trimmed);
          if (h.matches()) {
            closeTo(h.group(1).length());
            openHeading(h.group(1).length(), h.group(2), lineNo);
            continue;
          }
          HeadingDiv div = headingDiv(trimmed);
          if (div != null) {
            closeTo(div.level);
            openHeading(div.level, div.inner, lineNo);
            continue;
          }
        }
        if (!stack.isEmpty()) {
          stack.get(stack.size() - 1).body.add(raw);
        } else if (!trimmed.isEmpty()) {
          SpecMarkdownRejection r = new SpecMarkdownRejection(
              lineNo,
              SpecMarkdownRejectReason.ORPHAN_CONTENT,
              "text before the document root heading",
              null);
          rejections.add(r);
          List<String> held = new ArrayList<>();
          held.add(raw);
          orphans.add(new KeptBlock(r, held, null, null, null));
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
      String unitIds = unitsOf(m.group(2));
      // Reading view: an anchor equal to the section id after the id comment,
      // or to its qualified form (SOM §11.2), is the renderer's, not part of
      // the title.
      String rawTitle = m.group(3).trim();
      String title = titleWithoutAnchor(rawTitle, id, id);

      if (stack.isEmpty()) {
        openRoot(level, id, title, codeSpec, unitIds, lineNo);
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
        QualifiedAnchor q = qualifyAnchor(
            parent.anchorScope, parent.anchorSection, id, AnchorRole.ITEM);
        openItemHeading(level, parent, pNode, id,
            titleWithoutAnchor(rawTitle, id, q.anchor), codeSpec, unitIds, lineNo);
        MdFrame last = stack.get(stack.size() - 1);
        last.anchorScope = q.scope;
        last.anchorSection = id;
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
          boolean container = SomMetaKind.LIST.equals(entry.node.kind);
          QualifiedAnchor q = qualifyAnchor(
              parent.anchorScope, parent.anchorSection, id,
              container
                  ? AnchorRole.CONTAINER
                  : codec.isCopyNode(entry.node) ? AnchorRole.COPY : AnchorRole.PLAIN);
          title = titleWithoutAnchor(rawTitle, id, q.anchor);
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
          // SOM §11.2: `units` is staged exactly like codeSpec.
          if (!unitIds.isEmpty()) {
            units.put(childPath, unitIds);
          }
          MdFrame frame = new MdFrame(level, entry.node, childPath, lineNo, false);
          frame.anchorScope = q.scope;
          frame.anchorSection = container ? parent.anchorSection : id;
          stack.add(frame);
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
        String id, String title, String codeSpec, String unitIds, int lineNo) {
      ItemIdentity identity = itemIdentity(listNode, id);
      openItem(level, container.path, listNode, identity.n, identity.storedId,
          title, codeSpec, unitIds, lineNo, true);
    }

    /**
     * How an item {@code id} of {@code listNode} is read, as a heading's, a
     * records row's or a section-table row's: the item number it names (or
     * {@code null} for the next free one) and the id it stores (or
     * {@code null}). The {@code <member>-<n>} fallback id is positional and
     * stores nothing; the {@code @SectionIdPattern} resolved with a number
     * names item {@code <n>} and is stored, the section id being the item's
     * identity and the path only its position (SOM §11.6); any other id is the
     * next item, carrying it (YRD3).
     */
    ItemIdentity itemIdentity(SomMetaNode listNode, String id) {
      String member = listNode.memberName;
      if (member == null || member.isEmpty()) {
        member = listNode.segment();
      }
      Matcher anon = Pattern
          .compile("^" + Pattern.quote(member) + "-([0-9]+)$")
          .matcher(id);
      if (anon.matches()) {
        return new ItemIdentity(Integer.valueOf(anon.group(1)), null);
      }
      SomMetaNode element = listNode.elementNode;
      String pattern = listNode.sectionIdPattern;
      if ((pattern == null || pattern.isEmpty()) && element != null) {
        pattern = element.sectionIdPattern;
      }
      if (pattern != null && !pattern.isEmpty()) {
        String[] parts = splitAll(pattern, "xxx");
        if (parts.length == 2) {
          Matcher numbered = Pattern
              .compile("^" + Pattern.quote(parts[0]) + "([0-9]+)"
                  + Pattern.quote(parts[1]) + "$")
              .matcher(id);
          if (numbered.matches()) {
            return new ItemIdentity(Integer.valueOf(numbered.group(1)), id);
          }
        }
      }
      return new ItemIdentity(null, id);
    }

    void openRoot(int level, String id, String title, String codeSpec, String unitIds,
        int lineNo) {
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
          // SOM §11.2: `units` is staged exactly like codeSpec.
          if (!unitIds.isEmpty()) {
            units.put(seg, unitIds);
          }
          MdFrame frame = new MdFrame(level, tree.root, seg, lineNo, false);
          frame.anchorSection = seg;
          // Text before the root heading is kept at the start of its text.
          for (KeptBlock b : orphans) {
            frame.kept.add(new KeptMark(0, b, 0));
          }
          orphans.clear();
          stack.add(frame);
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
     * Opens a list item, with its frame when {@code push} is set, and returns
     * its path. {@code n} is the anonymous heading number (also the path
     * number); {@code null} takes the next free number instead.
     */
    String openItem(int level, String listPath, SomMetaNode listNode,
        Integer n, String storedId, String title, String codeSpec,
        String unitIds, int lineNo, boolean push) {
      MdListState state = lists.get(listPath);
      if (state == null) {
        state = new MdListState();
        lists.put(listPath, state);
        listOrder.add(listPath);
      }
      int number = n != null ? n.intValue() : state.maxN + 1;
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
      // SOM §11.2: `units` is staged exactly like codeSpec.
      if (!unitIds.isEmpty()) {
        units.put(itemPath, unitIds);
      }
      if (push) {
        stack.add(new MdFrame(level, listNode.elementNode, itemPath, lineNo, false));
      }
      return itemPath;
    }

    static boolean isValueLeaf(String kind) {
      return SomMetaKind.CONTENT.equals(kind)
          || SomMetaKind.SCALAR.equals(kind)
          || SomMetaKind.ENUM_VALUE.equals(kind);
    }

    // --- Body finalisation ----------------------------------------------------

    void finalizeFrame(MdFrame frame) {
      if (frame.ignored) {
        keepIgnored(frame);
        return;
      }
      SomMetaNode node = frame.node;
      if (node != null && SomMetaKind.FORM.equals(node.kind)) {
        finalizeForm(frame, node, frame.path);
        return;
      }
      if (node != null && SomMetaKind.LIST.equals(node.kind)) {
        finalizeListBody(frame, node);
      } else if (node != null
          && (SomMetaKind.SECTION.equals(node.kind) || SomMetaKind.COMPLEX.equals(node.kind))) {
        extractSectionTables(frame, node);
      }
      List<NodeRel> slots =
          node != null ? codec.bodySlots(node) : new ArrayList<>();
      if (slots.isEmpty()) {
        String value = restoreValue(frame.body);
        if (!frame.kept.isEmpty()) {
          Set<Integer> replaced = new HashSet<>();
          for (KeptMark mark : frame.kept) {
            for (int k = mark.at; k < mark.end; k++) {
              replaced.add(k);
            }
          }
          MdFrame parent = stack.isEmpty() ? null : stack.get(stack.size() - 1);
          if (keptInParent(node) && parent != null) {
            // A list container (no text of its own, SOM §11.5) or a typed
            // value has no place for a block: its parent takes them, after
            // its own text (RN-11); the lines they replace leave this frame's
            // text.
            String own = restoreValue(merge(frame.body, new ArrayList<>(), replaced));
            if (!own.equals(value)) {
              keptContent.put(frame.path, own);
            }
            for (KeptMark mark : frame.kept) {
              parent.kept.add(new KeptMark(parent.body.size(), mark.block, parent.body.size()));
            }
          } else {
            List<KeptInsert> ins = new ArrayList<>();
            for (KeptMark mark : frame.kept) {
              ins.add(new KeptInsert(mark.at, mark.block.div()));
            }
            String kept = restoreValue(merge(frame.body, ins, replaced));
            if (!kept.isEmpty()) {
              keptContent.put(frame.path, kept);
            }
          }
        }
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

    /** An item id as read: the number it names and the id it stores, each or null. */
    private static final class ItemIdentity {
      final Integer n;
      final String storedId;

      ItemIdentity(Integer n, String storedId) {
        this.n = n;
        this.storedId = storedId;
      }
    }

    /**
     * A heading title without the renderer's anchor — {@code <a id="…"></a>}
     * naming {@code id} or its qualified form {@code anchor} (SOM §11.2) — and
     * with {@code <br>} read as a line break.
     */
    static String titleWithoutAnchor(String rawTitle, String id, String anchor) {
      Pattern p = Pattern.compile(
          "^<a id=\"(?:" + Pattern.quote(id) + "|" + Pattern.quote(anchor) + ")\"></a>\\s*");
      return p.matcher(rawTitle).replaceFirst("").replace("<br>", "\n");
    }

    // --- Layout tables (SOM §11.4, §11.5) --------------------------------------

    /** One body row of a table: its line index and its cells. */
    private static final class TableRow {
      final int index;
      final List<String> cells;

      TableRow(int index, List<String> cells) {
        this.index = index;
        this.cells = cells;
      }
    }

    /** A table as read: header cells, body rows, the index after the table. */
    private static final class Table {
      final List<String> header;
      final List<TableRow> rows = new ArrayList<>();
      final int end;

      Table(List<String> header, int end) {
        this.header = header;
        this.end = end;
      }
    }

    /** A form a table row binds to: its path and its declared fields. */
    private static final class FormTarget {
      final String formPath;
      final List<SomFormFieldMeta> fields;

      FormTarget(String formPath, List<SomFormFieldMeta> fields) {
        this.formPath = formPath;
        this.fields = fields;
      }
    }

    private static List<SomFormFieldMeta> fieldsOf(SomMetaNode node) {
      return node.form != null ? node.form.fields : new ArrayList<>();
    }

    private static SomFormFieldMeta fieldByLabel(List<SomFormFieldMeta> fields, String label) {
      String lower = label.toLowerCase(Locale.ROOT);
      for (SomFormFieldMeta f : fields) {
        if (f.name.toLowerCase(Locale.ROOT).equals(lower)) {
          return f;
        }
      }
      return null;
    }

    /** The 1-based source line of {@code frame}'s body line {@code i}. */
    static int bodyLine(MdFrame frame, int i) {
      return frame.line + 1 + i;
    }

    /**
     * Reports a rejection and holds its block — its own source line — for an
     * import that keeps rejected blocks (RN-11).
     */
    private KeptBlock reject(int line, SpecMarkdownRejectReason reason, String message,
        String anchor) {
      return reject(line, reason, message, anchor, null, null, null, null);
    }

    /**
     * Reports a rejection and holds its block: {@code lines} are the source
     * lines it held (null: its own line), {@code field} / {@code section} /
     * {@code kept} what its div records for a resolution.
     */
    private KeptBlock reject(int line, SpecMarkdownRejectReason reason, String message,
        String anchor, List<String> lines, String field, String section, String kept) {
      SpecMarkdownRejection r = new SpecMarkdownRejection(line, reason, message, anchor);
      rejections.add(r);
      List<String> held = new ArrayList<>();
      if (lines != null) {
        held.addAll(lines);
      } else if (line >= 1 && line <= source.length) {
        held.add(source[line - 1]);
      }
      KeptBlock b = new KeptBlock(r, held, field, section, kept);
      pending.add(b);
      return b;
    }

    /**
     * The cells of a table row: split on every {@code |} not preceded by a
     * backslash, the outer pipes dropped, each cell trimmed; {@code \|} stays
     * in the cell.
     */
    static List<String> rowCells(String line) {
      String t = line.trim();
      if (t.startsWith("|")) {
        t = t.substring(1);
      }
      if (t.endsWith("|") && !t.endsWith("\\|")) {
        t = t.substring(0, t.length() - 1);
      }
      List<String> cells = new ArrayList<>();
      StringBuilder b = new StringBuilder();
      for (int i = 0; i < t.length(); i++) {
        char c = t.charAt(i);
        if (c == '\\' && i + 1 < t.length() && t.charAt(i + 1) == '|') {
          b.append("\\|");
          i++;
        } else if (c == '|') {
          cells.add(b.toString().trim());
          b.setLength(0);
        } else {
          b.append(c);
        }
      }
      cells.add(b.toString().trim());
      return cells;
    }

    /**
     * Reads the table whose header is {@code lines[start]}: the header cells,
     * the body rows with their line indexes, and the index after the table; a
     * broken delimiter row or a row of another cell count is a
     * {@code malformedBlock}.
     */
    private Table readTable(List<String> lines, int start, IntUnaryOperator lineOf,
        String anchor) {
      int end = start + 1;
      while (end < lines.size() && TABLE_LINE.matcher(lines.get(end)).find()) {
        end++;
      }
      List<String> header = rowCells(lines.get(start));
      List<String> delimiter = start + 1 < end ? rowCells(lines.get(start + 1)) : null;
      boolean isDelimiter = delimiter != null;
      if (delimiter != null) {
        for (String c : delimiter) {
          if (!DELIMITER_CELL.matcher(c).find()) {
            isDelimiter = false;
            break;
          }
        }
      }
      Table table = new Table(header, end);
      if (!isDelimiter || delimiter.size() != header.size()) {
        reject(
            lineOf.applyAsInt(start),
            SpecMarkdownRejectReason.MALFORMED_BLOCK,
            !isDelimiter
                ? "table without its delimiter row"
                : "table whose delimiter row does not match its header",
            anchor, lines.subList(start, end), null, null, null);
        return table;
      }
      for (int i = start + 2; i < end; i++) {
        List<String> cells = rowCells(lines.get(i));
        if (cells.size() != header.size()) {
          reject(
              lineOf.applyAsInt(i),
              SpecMarkdownRejectReason.MALFORMED_BLOCK,
              "table row with " + cells.size() + " cells, the header has " + header.size(),
              anchor, lines.subList(i, i + 1), null, null, null);
          continue;
        }
        table.rows.add(new TableRow(i, cells));
      }
      return table;
    }

    /**
     * A cell's value for field {@code f}: {@code \|} unescaped, a reference
     * field's links read as their link texts, a {@code code} field's code span
     * decoded.
     */
    static String cellValue(String cell, SomFormFieldMeta f) {
      String text = cell.replace("\\|", "|");
      if (!f.refersTo.isEmpty() && !f.code && LINK_CELL.matcher(text).find()) {
        List<String> texts = new ArrayList<>();
        Matcher m = LINK_TEXT.matcher(text);
        while (m.find()) {
          texts.add(m.group(1));
        }
        return String.join(", ", texts);
      }
      return f.code ? decodeCodeSpan(text) : text;
    }

    /**
     * A cell's id with the renderer's anchor ({@code <a id="X"></a>X}) removed
     * and a link the cell is read as its text ({@code [X](<file>#X)}, SOM
     * §11.5).
     */
    static String cellId(String cell) {
      String id = CELL_ANCHOR.matcher(cell).replaceFirst("");
      Matcher m = CELL_LINK.matcher(id);
      return m.find() ? m.group(1) : id;
    }

    /**
     * Whether {@code field} of the form at {@code formPath} was given before;
     * reports the repeat ({@code malformedBlock}, the first occurrence kept)
     * when it was. The repeat's held block names the field and the form
     * holding the kept value (RN-11).
     */
    private boolean givenTwice(String formPath, String field, int line) {
      if (given.computeIfAbsent(formPath, k -> new HashSet<>()).add(field)) {
        return false;
      }
      reject(
          line,
          SpecMarkdownRejectReason.MALFORMED_BLOCK,
          "field \"" + field + "\" given twice",
          formPath, null, field, null, formPath);
      return true;
    }

    private void setField(String formPath, String field, String value) {
      forms.computeIfAbsent(formPath, k -> new LinkedHashMap<>()).put(field, value);
    }

    /** Stages one row of a form table (or a section table). */
    private void stageRow(String formPath, List<SomFormFieldMeta> fields, String label,
        String cell, int line) {
      SomFormFieldMeta f = fieldByLabel(fields, label);
      if (f == null) {
        reject(
            line,
            SpecMarkdownRejectReason.UNKNOWN_FIELD,
            "row \"" + label + "\" names no field of this form",
            formPath, null, nearMiss(label, fieldNames(fields)), null, null);
        return;
      }
      String value = cellValue(cell, f);
      if (value.isEmpty() || givenTwice(formPath, f.name, line)) {
        return;
      }
      setField(formPath, f.name, value);
    }

    /** Reads and removes every section table of {@code frame}'s body (SOM §11.5). */
    private void extractSectionTables(MdFrame frame, SomMetaNode node) {
      List<String> body = frame.body;
      MarkdownFenceTracker tableFence = new MarkdownFenceTracker();
      for (int i = 0; i < body.size(); i++) {
        String line = body.get(i);
        Matcher h = tableFence.inFence() ? null : LAYOUT_TABLE_HEADER.matcher(line);
        if (h == null || !h.find() || h.group(1) == null) {
          tableFence.feed(line);
          continue;
        }
        Table table = readTable(body, i, k -> bodyLine(frame, k), frame.path);
        FormTarget target = null;
        boolean skip = false;
        // The rejected section's block: its row and the rows continuing it.
        KeptBlock skipped = null;
        for (TableRow row : table.rows) {
          int rowLine = bodyLine(frame, row.index);
          String section = cellId(row.cells.get(0));
          if (section.isEmpty() && skip) {
            if (skipped != null) {
              skipped.lines.add(body.get(row.index));
            }
            continue;
          }
          if (!section.isEmpty()) {
            FormTarget named = sectionTableTarget(frame, node, section);
            skip = named == null;
            if (named == null) {
              skipped = reject(
                  rowLine,
                  SpecMarkdownRejectReason.UNKNOWN_SECTION,
                  "section-table row names no child section of \"" + frame.path + "\"",
                  section, body.subList(row.index, row.index + 1), null,
                  nearSection(node, section), null);
              continue;
            }
            target = named;
          } else if (target == null) {
            reject(
                rowLine,
                SpecMarkdownRejectReason.UNKNOWN_SECTION,
                "section-table row names no section",
                frame.path, body.subList(row.index, row.index + 1), null, null, null);
            continue;
          }
          stageRow(target.formPath, target.fields, row.cells.get(1), row.cells.get(2), rowLine);
        }
        for (int k = i; k < table.end; k++) {
          body.set(k, "");
        }
        // What the table rejected is kept where the table stood.
        markPending(frame, i, i);
        i = table.end - 1;
      }
    }

    /**
     * The child a section-table {@code Section} cell naming none is a near
     * miss of (RN-11): a child form section's id, or {@code <LIST> / <ITEM>}
     * with a near list id.
     */
    private String nearSection(SomMetaNode node, String section) {
      String[] parts = SECTION_CELL_SEP.split(section, -1);
      if (parts.length != 1 && parts.length != 2) {
        return null;
      }
      String kind = parts.length == 1 ? SomMetaKind.FORM : SomMetaKind.LIST;
      List<String> ids = new ArrayList<>();
      for (NodeRel entry : codec.effectiveChildren(node)) {
        if (kind.equals(entry.node.kind)) {
          String id = codec.headingIdOf(entry.node);
          if (id != null) {
            ids.add(id);
          }
        }
      }
      if (parts.length == 1) {
        return nearMiss(section, ids);
      }
      String list = nearMiss(parts[0], ids);
      return list == null ? null : list + " / " + parts[1];
    }

    /** The form a section-table {@code Section} cell names under {@code node}. */
    private FormTarget sectionTableTarget(MdFrame frame, SomMetaNode node, String section) {
      String[] parts = SECTION_CELL_SEP.split(section, -1);
      for (NodeRel entry : codec.effectiveChildren(node)) {
        SomMetaNode child = entry.node;
        String childId = codec.headingIdOf(child);
        if (parts.length == 1 && SomMetaKind.FORM.equals(child.kind)
            && childId.equals(section)) {
          return new FormTarget(frame.path + "/" + entry.rel, fieldsOf(child));
        }
        if (parts.length == 2 && SomMetaKind.LIST.equals(child.kind)
            && childId.equals(parts[0])) {
          SomMetaNode element = child.elementNode;
          NodeRel form = element != null ? codec.itemForm(element) : null;
          if (form == null) {
            return null;
          }
          ItemIdentity identity = itemIdentity(child, parts[1]);
          String listPath = frame.path + "/" + entry.rel;
          MdListState state = lists.get(listPath);
          String itemPath = null;
          if (state != null) {
            for (String p : state.items) {
              String itemId = state.ids.get(p);
              if (itemId == null) {
                itemId = p.substring(listPath.length() + 1);
              }
              if (itemId.equals(parts[1])) {
                itemPath = p;
                break;
              }
            }
          }
          if (itemPath == null) {
            itemPath = openItem(0, listPath, child, identity.n, identity.storedId,
                "", "", "", frame.line, false);
          }
          return new FormTarget(itemPath + "/" + form.rel, fieldsOf(form.node));
        }
      }
      return null;
    }

    // --- List bodies: `refs` and `records` (SOM §11.5) --------------------------

    private static void blank(List<String> body, int from, int to) {
      for (int k = from; k <= to; k++) {
        body.set(k, "");
      }
    }

    /**
     * A list container's body: one {@code refs} or {@code records} div stands
     * for its items.
     */
    private void finalizeListBody(MdFrame frame, SomMetaNode listNode) {
      List<String> body = frame.body;
      MarkdownFenceTracker divFence = new MarkdownFenceTracker();
      for (int i = 0; i < body.size(); i++) {
        String line = body.get(i);
        Matcher open = divFence.inFence() ? null : LIST_DIV_OPEN.matcher(line);
        if (open == null || !open.find()) {
          divFence.feed(line);
          continue;
        }
        String kind = open.group(1) != null ? open.group(1) : open.group(2);
        int close = -1;
        for (int k = i + 1; k < body.size(); k++) {
          if (DIV_CLOSE.matcher(body.get(k)).find()) {
            close = k;
            break;
          }
        }
        if (close < 0) {
          // The fence's lines read as text; kept, they are the rejected div
          // (the container's parent holds it, see finalizeFrame).
          reject(bodyLine(frame, i), SpecMarkdownRejectReason.MALFORMED_BLOCK,
              "unclosed " + kind + " fence", frame.path,
              body.subList(i, body.size()), null, null, null);
          markPending(frame, i, body.size());
          return;
        }
        List<String> divLines = new ArrayList<>(body.subList(i, close + 1));
        boolean besideText = false;
        for (int k = 0; k < body.size(); k++) {
          if ((k < i || k > close) && !body.get(k).trim().isEmpty()) {
            besideText = true;
          }
        }
        MdListState state = lists.get(frame.path);
        boolean hasItems = state != null && !state.items.isEmpty();
        if (besideText || hasItems) {
          reject(bodyLine(frame, i), SpecMarkdownRejectReason.MALFORMED_BLOCK,
              "a " + kind + " div beside " + (hasItems ? "item headings" : "other text")
                  + " in a list container",
              frame.path, divLines, null, null, null);
          blank(body, i, close);
          markPending(frame, close + 1, close + 1);
          return;
        }
        List<String> inner = new ArrayList<>(body.subList(i + 1, close));
        if ("refs".equals(kind)) {
          stageReferenceLine(frame, listNode, inner, i, divLines);
        } else {
          stageRecordTable(frame, listNode, inner, i, divLines);
        }
        blank(body, i, close);
        // What the div rejected is kept after it.
        markPending(frame, close + 1, close + 1);
        return;
      }
    }

    private static boolean isReferenceForm(SomMetaNode n) {
      if (!SomMetaKind.FORM.equals(n.kind) || n.form == null || n.form.fields.size() != 1
          || n.form.fields.get(0).refersTo.isEmpty()) {
        return false;
      }
      for (SomMetaExtra e : n.extra) {
        if ("Reference".equals(e.annotation)) {
          return true;
        }
      }
      return false;
    }

    /** The reference form of {@code element}'s items (its one field is the reference). */
    private NodeRel referenceForm(SomMetaNode element) {
      for (NodeRel s : codec.bodySlots(element)) {
        if (isReferenceForm(s.node)) {
          return s;
        }
      }
      for (NodeRel c : codec.effectiveChildren(element)) {
        if (isReferenceForm(c.node)) {
          return c;
        }
      }
      return null;
    }

    /**
     * A {@code refs} div: ids split on commas and whitespace, links read as
     * their texts.
     */
    private void stageReferenceLine(MdFrame frame, SomMetaNode listNode, List<String> inner,
        int at, List<String> divLines) {
      SomMetaNode element = listNode.elementNode;
      NodeRel ref = element != null ? referenceForm(element) : null;
      if (ref == null) {
        reject(bodyLine(frame, at), SpecMarkdownRejectReason.MALFORMED_BLOCK,
            "a refs div in a list whose items are not references", frame.path,
            divLines, null, null, null);
        return;
      }
      List<String> ids = new ArrayList<>();
      for (String t : REF_SEP.split(String.join(" ", inner))) {
        if (t.isEmpty()) {
          continue;
        }
        Matcher m = LINK_TEXT.matcher(t);
        ids.add(m.find() ? m.group(1) : t);
      }
      if (ids.isEmpty()) {
        reject(bodyLine(frame, at), SpecMarkdownRejectReason.MISSING_VALUE,
            "an empty refs div", frame.path, divLines, null, null, null);
        return;
      }
      String pattern = listNode.sectionIdPattern;
      if (pattern == null || pattern.isEmpty()) {
        pattern = element.sectionIdPattern;
      }
      if (pattern != null && pattern.isEmpty()) {
        pattern = null;
      }
      String member = listNode.memberName;
      if (member == null || member.isEmpty()) {
        member = listNode.segment();
      }
      String field = ref.node.form.fields.get(0).name;
      for (int n = 1; n <= ids.size(); n++) {
        String positional = SpecSectionId.effectiveListItemSectionId(null, pattern, n, member);
        ItemIdentity identity = itemIdentity(listNode, positional);
        String itemPath = openItem(0, frame.path, listNode, identity.n, identity.storedId,
            "", "", "", frame.line, false);
        setField(bodyPathOf(itemPath, ref.rel), field, ids.get(n - 1));
      }
    }

    /** A {@code records} div: one table, {@code Id} first, {@code Title} optionally second. */
    private void stageRecordTable(MdFrame frame, SomMetaNode listNode, List<String> inner,
        int at, List<String> divLines) {
      IntUnaryOperator lineOf = k -> bodyLine(frame, at + 1 + k);
      int divLine = bodyLine(frame, at);
      int start = -1;
      for (int k = 0; k < inner.size(); k++) {
        if (!inner.get(k).trim().isEmpty()) {
          start = k;
          break;
        }
      }
      if (start < 0 || !TABLE_LINE.matcher(inner.get(start)).find()) {
        reject(divLine, SpecMarkdownRejectReason.MALFORMED_BLOCK,
            "a records div holding no table", frame.path,
            divLines, null, null, null);
        return;
      }
      List<String> header = rowCells(inner.get(start));
      if (!"Id".equals(header.get(0))) {
        reject(divLine, SpecMarkdownRejectReason.MALFORMED_BLOCK,
            "a records table whose first column is not Id", frame.path,
            divLines, null, null, null);
        return;
      }
      SomMetaNode element = listNode.elementNode;
      NodeRel form = element != null ? codec.itemForm(element) : null;
      if (form == null) {
        reject(divLine, SpecMarkdownRejectReason.MALFORMED_BLOCK,
            "a records div in a list whose items have no single form", frame.path,
            divLines, null, null, null);
        return;
      }
      List<SomFormFieldMeta> fields = fieldsOf(form.node);
      boolean withTitle = header.size() > 1 && "Title".equals(header.get(1));
      int first = withTitle ? 2 : 1;
      List<SomFormFieldMeta> columns = new ArrayList<>();
      for (String label : header.subList(first, header.size())) {
        SomFormFieldMeta f = fieldByLabel(fields, label);
        if (f == null) {
          // The table is skipped whole, so the whole div is kept.
          reject(lineOf.applyAsInt(start), SpecMarkdownRejectReason.UNKNOWN_FIELD,
              "records column \"" + label + "\" names no field of the items", frame.path,
              divLines, nearMiss(label, fieldNames(fields)), null, null);
          return;
        }
        columns.add(f);
      }
      Table table = readTable(inner, start, lineOf, frame.path);
      String stem = itemStemOf(listNode);
      for (TableRow row : table.rows) {
        ItemIdentity identity = itemIdentity(listNode, cellId(row.cells.get(0)));
        String itemPath = openItem(0, frame.path, listNode, identity.n, identity.storedId,
            "", "", "", lineOf.applyAsInt(row.index), false);
        if (withTitle) {
          String title = row.cells.get(1).replace("\\|", "|").replace("<br>", "\n");
          String number = itemPath.substring(frame.path.length() + 1);
          if (!title.isEmpty() && !title.equals(stem + " " + number)) {
            headlines.put(itemPath, title);
          }
        }
        String formPath = itemPath + "/" + form.rel;
        for (int c = 0; c < columns.size(); c++) {
          String value = cellValue(row.cells.get(first + c), columns.get(c));
          if (!value.isEmpty()) {
            setField(formPath, columns.get(c).name, value);
          }
        }
      }
    }

    /**
     * The open {@code Field:} paragraph of a body region: its field, form and
     * lines, and — for a field given twice — the held block that keeps the
     * paragraph whole (RN-11).
     */
    private final class FieldRun {
      final MdFrame frame;
      final Keeper keeper;
      SomFormFieldMeta field;
      String formPath = "";
      boolean discard;
      List<String> lines = new ArrayList<>();
      KeptBlock discarded;
      int discardStart;

      FieldRun(MdFrame frame, Keeper keeper) {
        this.frame = frame;
        this.keeper = keeper;
      }

      /** Opens {@code field} of the form at {@code formPath} at body index {@code i}. */
      void open(SomFormFieldMeta field, String formPath, int i, String first) {
        this.field = field;
        this.formPath = formPath;
        discard = givenTwice(formPath, field.name, bodyLine(frame, i));
        if (discard) {
          discarded = pending.isEmpty() ? null : pending.remove(pending.size() - 1);
          discardStart = i;
        }
        lines.add(first);
      }

      /**
       * Ends the open field at body index {@code at}: its value is stored, or
       * — given twice — its paragraph kept in {@code into}.
       */
      void flush(int at, List<String> into) {
        if (field != null && !discard) {
          putField(formPath, field, lines);
        }
        if (discard && discarded != null) {
          discarded.lines = new ArrayList<>(frame.body.subList(discardStart, at));
          keeper.keep(into, discarded);
          discarded = null;
        }
        lines = new ArrayList<>();
        discard = false;
      }
    }

    /**
     * Binds a heading's body region against the owner's transparent body
     * slots (SOM §11.6): {@code FieldName:} lines and form-table rows matching
     * a transparent form's fields route to that form (nearest form in slot
     * order, wrapping); a slot marker ({@code <!-- slot: <rel> -->}) sends the
     * text after it to the named slot — a content slot, a form's preamble, or
     * the owner itself ({@code .}) — and ends any open field. Unmarked text
     * binds to the first content slot; with no content slot it is a form's
     * <b>preamble</b> (SOM §11.4 rule 7) — the form slot named
     * {@code content}, else the first form slot — which is where the YAML
     * codec keeps it; only an owner with no slot at all takes it on its own
     * path. In a region with forms every label-shaped text line carries one
     * escape space, which is stripped.
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
      // Unlabelled text per target path, in the order the targets were
      // opened; a target opened twice gets its parts joined by a blank line.
      Map<String, List<List<String>>> textParts = new LinkedHashMap<>();
      List<String> contentLines = new ArrayList<>();
      textParts.computeIfAbsent(bodyPathOf(frame.path, defaultRel), k -> new ArrayList<>())
          .add(contentLines);
      // Rejected blocks go to the unlabelled text at their place (RN-11); a
      // field given twice is kept whole, its label line and continuation.
      Keeper keeper = new Keeper(frame);
      FieldRun run = new FieldRun(frame, keeper);

      currentFormIdx = 0;
      for (int i = 0; i < frame.body.size(); i++) {
        String line = frame.body.get(i);
        keeper.drain(i, contentLines);
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
              run.flush(i, contentLines);
              run.field = null;
              if (slot != null && SomMetaKind.FORM.equals(slot.node.kind)) {
                currentFormIdx = formSlots.indexOf(slot);
              }
              contentLines = new ArrayList<>();
              textParts.computeIfAbsent(bodyPathOf(frame.path, rel), k -> new ArrayList<>())
                  .add(contentLines);
              continue;
            }
          }
          Matcher header = LAYOUT_TABLE_HEADER.matcher(line);
          if (header.find() && header.group(1) == null && !formSlots.isEmpty()) {
            // A form table ends the open field (SOM §11.4); its rows bind like
            // `Field:` labels, each to the nearest form declaring it.
            run.flush(i, contentLines);
            run.field = null;
            Table table = readTable(frame.body, i, k -> bodyLine(frame, k), frame.path);
            for (TableRow row : table.rows) {
              String label = row.cells.get(0);
              int rowLine = bodyLine(frame, row.index);
              int hit = findFormOf(formSlots, label);
              if (hit < 0) {
                List<String> names = new ArrayList<>();
                for (NodeRel s : formSlots) {
                  names.addAll(fieldNames(fieldsOf(s.node)));
                }
                reject(rowLine, SpecMarkdownRejectReason.UNKNOWN_FIELD,
                    "row \"" + label + "\" names no field of this form", frame.path,
                    frame.body.subList(row.index, row.index + 1),
                    nearMiss(label, names), null, null);
                continue;
              }
              currentFormIdx = hit;
              stageRow(frame.path + "/" + formSlots.get(hit).rel,
                  fieldsOf(formSlots.get(hit).node), label, row.cells.get(1), rowLine);
            }
            // What the table rejected is kept where the table stood.
            for (KeptBlock b : takePending()) {
              keeper.keep(contentLines, b);
            }
            i = table.end - 1;
            continue;
          }
          Matcher m = FIELD_LABEL.matcher(line);
          if (m.matches()) {
            int hit = findFormOf(formSlots, m.group(1));
            if (hit >= 0) {
              run.flush(i, contentLines);
              currentFormIdx = hit;
              run.open(
                  fieldByLabel(fieldsOf(formSlots.get(hit).node), m.group(1)),
                  frame.path + "/" + formSlots.get(hit).rel, i, m.group(2));
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
        if (run.field != null) {
          run.lines.add(text);
        } else {
          contentLines.add(text);
        }
        bodyFence.feed(line);
      }
      run.flush(frame.body.size(), contentLines);
      keeper.drain(frame.body.size(), contentLines);
      for (Map.Entry<String, List<List<String>>> e : textParts.entrySet()) {
        String value = joinParts(e.getValue());
        if (!value.isEmpty()) {
          content.put(e.getKey(), value);
        }
        String kept = keeper.keptValue(e.getValue());
        if (kept != null && !kept.isEmpty()) {
          keptContent.put(e.getKey(), kept);
        }
      }
    }

    /**
     * The index of the form slot declaring {@code label}: the nearest at or
     * after the last hit, wrapping; -1 when none declares it.
     */
    private int findFormOf(List<NodeRel> formSlots, String label) {
      for (int k = 0; k < formSlots.size(); k++) {
        int idx = (currentFormIdx + k) % formSlots.size();
        if (fieldByLabel(fieldsOf(formSlots.get(idx).node), label) != null) {
          return idx;
        }
      }
      return -1;
    }

    /** The restored, non-empty text parts joined by one blank line. */
    private static String joinParts(List<List<String>> parts) {
      List<String> values = new ArrayList<>();
      for (List<String> part : parts) {
        String v = restoreValue(part);
        if (!v.isEmpty()) {
          values.add(v);
        }
      }
      return String.join("\n\n", values);
    }

    /** Stores a field's restored value (unwrapping a code field's code span). */
    private void putField(String formPath, SomFormFieldMeta field, List<String> lines) {
      String restored = restoreValue(lines);
      String value = field.code ? decodeCodeSpan(restored) : restored;
      if (!value.isEmpty()) {
        setField(formPath, field.name, value);
      }
    }

    private static String bodyPathOf(String ownerPath, String rel) {
      return ".".equals(rel) ? ownerPath : ownerPath + "/" + rel;
    }

    /**
     * Parses an id-bearing {@code @Form} section's body: {@code FieldName:}
     * paragraphs and form-table rows bind to the named fields wherever they
     * stand (SOM §11.4); the text that belongs to no field — before the first
     * field, or after a table — is the form's preamble, its own content
     * (rule 7).
     */
    void finalizeForm(MdFrame frame, SomMetaNode node, String path) {
      List<SomFormFieldMeta> declared = fieldsOf(node);
      MarkdownFenceTracker bodyFence = new MarkdownFenceTracker();
      // The preamble's parts: the text before the first field, and text a
      // table interrupts; joined by one blank line.
      List<List<String>> preambleParts = new ArrayList<>();
      preambleParts.add(new ArrayList<>());
      // Rejected blocks go to the preamble at their place (RN-11).
      Keeper keeper = new Keeper(frame);
      FieldRun run = new FieldRun(frame, keeper);

      for (int i = 0; i < frame.body.size(); i++) {
        String line = frame.body.get(i);
        keeper.drain(i, preambleParts.get(preambleParts.size() - 1));
        if (!bodyFence.inFence()) {
          Matcher header = LAYOUT_TABLE_HEADER.matcher(line);
          if (header.find() && header.group(1) == null) {
            run.flush(i, preambleParts.get(preambleParts.size() - 1));
            run.field = null;
            preambleParts.add(new ArrayList<>());
            Table table = readTable(frame.body, i, k -> bodyLine(frame, k), path);
            for (TableRow row : table.rows) {
              stageRow(path, declared, row.cells.get(0), row.cells.get(1),
                  bodyLine(frame, row.index));
            }
            for (KeptBlock b : takePending()) {
              keeper.keep(preambleParts.get(preambleParts.size() - 1), b);
            }
            i = table.end - 1;
            continue;
          }
          Matcher m = FIELD_LABEL.matcher(line);
          SomFormFieldMeta field = m.matches() ? fieldByLabel(declared, m.group(1)) : null;
          if (field != null) {
            run.flush(i, preambleParts.get(preambleParts.size() - 1));
            run.open(field, path, i, m.group(2));
            bodyFence.feed(line);
            continue;
          }
        }
        // Continuation: strip the one escape space of a label-shaped line.
        List<String> target = run.field == null
            ? preambleParts.get(preambleParts.size() - 1)
            : run.lines;
        if (!bodyFence.inFence() && CONTINUATION_LABEL.matcher(line).find()) {
          target.add(line.substring(1));
        } else {
          target.add(line);
        }
        bodyFence.feed(line);
      }
      run.flush(frame.body.size(), preambleParts.get(preambleParts.size() - 1));
      keeper.drain(frame.body.size(), preambleParts.get(preambleParts.size() - 1));
      String value = joinParts(preambleParts);
      if (!value.isEmpty()) {
        content.put(path, value);
      }
      String kept = keeper.keptValue(preambleParts);
      if (kept != null && !kept.isEmpty()) {
        keptContent.put(path, kept);
      }
    }

    /**
     * The parse-side value restoration (SOM §11.3): trim leading/trailing
     * blank lines, unescape {@code \#}-escaped heading lines and strip the
     * one escape space of a line shaped like a layout table header (SOM
     * §11.4), outside fences.
     */
    static String restoreValue(List<String> body) {
      MarkdownFenceTracker restoreFence = new MarkdownFenceTracker();
      List<String> out = new ArrayList<>(body.size());
      for (String line : body) {
        if (!restoreFence.inFence()
            && (ESCAPED_HEADING.matcher(line).find()
                || (line.startsWith("\\") && escapableDiv(line)))) {
          out.add(line.substring(1));
        } else if (!restoreFence.inFence() && ESCAPED_TABLE_HEADER.matcher(line).find()) {
          out.add(line.substring(1)); // the emitter's one escape space.
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
