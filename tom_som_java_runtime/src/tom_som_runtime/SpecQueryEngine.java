package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Lexical/structural query over a live {@link SpecDocument}
 * ({@code llm_and_d4rt_tools.md} §6, {@code som_multiplatform_spec_model.md}
 * §15) — a faithful port of {@code spec_query.dart}.
 *
 * <p>This is the <b>grep-like</b> facility the downstream D4rt scripting layer
 * and the editor's search tools reuse. It is <b>embedding-free</b> — exact
 * substring or {@link SomTextPattern} match plus structural filters — so it is
 * always current and needs no model calls.
 *
 * <p>A {@link SpecQuery} composes (AND-combined) over five dimensions:
 *
 * <ul>
 *   <li><b>text</b> — substring or {@link SomTextPattern} over content +
 *       form-field values and over a node's headline, stored or doc-comment
 *       (optionally case-insensitive);
 *   <li><b>kind</b> — one or more {@link SpecNodeKind}s;
 *   <li><b>class</b> — the model class a node <i>is</i> (by class name);
 *   <li><b>id / path</b> — exact {@code @SectionId}, {@code @SectionId} prefix,
 *       path glob, or a {@code @MapsTo} / {@code @DetailedIn} target on the
 *       node's class;
 *   <li><b>state</b> — empty / non-empty (the structural "empty = no value"
 *       test).
 * </ul>
 *
 * <p>{@link #query} returns a {@link SpecQueryCursor} the caller iterates lazily
 * ({@code next} / {@code take} / {@code count}). The cursor captures the
 * <b>structural</b> candidate set when it is created, then <b>re-validates each
 * path against the live document on every step</b> — so a result whose list-item
 * ancestor was removed after the cursor was made is silently skipped (stable
 * against concurrent edits).
 */
public final class SpecQueryEngine {
  private static final char ASTERISK = '*';
  private static final char SLASH = '/';

  /** The meta-model describing the document's structure. */
  public final SpecModel model;

  /** The live document whose values are searched. */
  public final SpecDocument document;

  private final SpecReflection reflection;

  public SpecQueryEngine(SpecModel model, SpecDocument document) {
    this.model = model;
    this.document = document;
    this.reflection = new SpecReflection(model);
  }

  /**
   * Builds a cursor over the nodes matching {@code query}. The structural
   * candidate set is computed now (document order); value-dependent filters and
   * path liveness are re-checked as the cursor advances.
   *
   * <p>Throws {@link SomPatternError} when {@code query.regex} is set and
   * {@code query.text} is not in the portable subset. The pattern is compiled
   * <b>here</b>, not on first use, for two reasons: a malformed pattern is the
   * caller's mistake and should surface at the call that made it, and a cursor
   * that happens to visit no candidate would otherwise swallow the error
   * entirely.
   */
  public SpecQueryCursor query(SpecQuery query) {
    SomTextPattern pattern = query.text == null ? null : patternFor(query);
    List<String> candidates = new ArrayList<>();
    for (String path : enumeratePaths()) {
      SpecResolution resolution = reflection.resolve(path);
      if (resolution == null) {
        continue;
      }
      if (matchesStructural(query, resolution)) {
        candidates.add(path);
      }
    }
    return new SpecQueryCursor(this, query, pattern, candidates);
  }

  // --- flat node projection (tier-1 index source) ---------------------------

  /**
   * Projects every indexable node of the live document (the
   * {@code llm_and_d4rt_tools.md} §6 structural closure) as a flat
   * {@link SpecNodeProjection}, in document order. Reuses the same walk and value
   * extraction the query uses, so the index built from these projections and the
   * live {@code llm_and_d4rt_tools.md} §6 search agree on what a node is and what
   * text it carries. Pure object-model traversal — no model (LLM) calls.
   */
  public List<SpecNodeProjection> projectNodes() {
    List<SpecNodeProjection> out = new ArrayList<>();
    for (String path : enumeratePaths()) {
      SpecNodeProjection projection = projectNode(path);
      if (projection != null) {
        out.add(projection);
      }
    }
    return out;
  }

  /**
   * Projects the single node at {@code path}, or {@code null} when the path no
   * longer resolves against the model. Used for the index's incremental refresh:
   * a caller re-projects only the changed section paths.
   */
  public SpecNodeProjection projectNode(String path) {
    SpecResolution resolution = reflection.resolve(path);
    if (resolution == null) {
      return null;
    }
    return new SpecNodeProjection(
        path,
        resolution.kind,
        resolution.targetClass != null ? resolution.targetClass.name : null,
        sectionIdOf(resolution),
        resolution.targetClass != null ? resolution.targetClass.mapsTo : null,
        resolution.targetClass != null ? resolution.targetClass.detailedIn : null,
        headlineOf(resolution),
        searchableStrings(resolution),
        document.hasValuesUnder(path));
  }

  // --- structural-closure enumeration ---------------------------------------

  /**
   * Every addressable node of the document in document order: the root, each
   * singular complex/section node on the spine (bounded by cycle detection), each
   * list container, each <i>existing</i> list item, and every declared leaf.
   */
  private List<String> enumeratePaths() {
    List<String> out = new ArrayList<>();
    for (SpecRoot root : model.roots) {
      String segment = reflection.rootSegment(root);
      Set<String> ancestorTypes = new LinkedHashSet<>();
      ancestorTypes.add(root.type);
      walk(out, segment, model.classNamed(root.type), ancestorTypes);
    }
    return out;
  }

  private void walk(List<String> out, String path, SpecClass cls, Set<String> ancestorTypes) {
    out.add(path); // the node itself (root / complex / section container)
    if (cls == null) {
      return;
    }
    for (SpecField field : cls.fields) {
      String fieldPath = SpecPaths.join(path, reflection.fieldSegment(field));
      switch (field.kind) {
        case CONTENT:
        case ENUM:
        case SCALAR:
        case FORM:
          out.add(fieldPath); // a value leaf
          break;
        case LIST:
          out.add(fieldPath); // the list container node
          for (String itemPath : document.listItems(fieldPath)) {
            if (field.elementIsComplex
                && field.elementType != null
                && !ancestorTypes.contains(field.elementType)) {
              walk(
                  out,
                  itemPath,
                  model.classNamed(field.elementType),
                  extended(ancestorTypes, field.elementType));
            } else {
              out.add(itemPath); // scalar item, or a recursive/unknown element
            }
          }
          break;
        case COMPLEX:
        case SECTION:
        default:
          if (field.type != null && !ancestorTypes.contains(field.type)) {
            walk(out, fieldPath, model.classNamed(field.type), extended(ancestorTypes, field.type));
          } else {
            out.add(fieldPath); // recursive/unknown target: a terminal node
          }
          break;
      }
    }
  }

  private static Set<String> extended(Set<String> ancestorTypes, String type) {
    Set<String> next = new LinkedHashSet<>(ancestorTypes);
    next.add(type);
    return next;
  }

  // --- predicates -----------------------------------------------------------

  /** The model-fixed dimensions (kind / class / id / path / mapsTo / detailedIn). */
  private boolean matchesStructural(SpecQuery query, SpecResolution resolution) {
    if (query.kinds != null && !query.kinds.contains(resolution.kind)) {
      return false;
    }
    String className = resolution.targetClass != null ? resolution.targetClass.name : null;
    if (query.className != null && !query.className.equals(className)) {
      return false;
    }

    String sectionId = sectionIdOf(resolution);
    if (query.sectionIdExact != null && !query.sectionIdExact.equals(sectionId)) {
      return false;
    }
    if (query.sectionIdPrefix != null
        && !(sectionId != null && sectionId.startsWith(query.sectionIdPrefix))) {
      return false;
    }
    if (query.pathGlob != null && !globMatches(query.pathGlob, resolution.path)) {
      return false;
    }
    String mapsTo = resolution.targetClass != null ? resolution.targetClass.mapsTo : null;
    if (query.mapsTo != null && !query.mapsTo.equals(mapsTo)) {
      return false;
    }
    String detailedIn = resolution.targetClass != null ? resolution.targetClass.detailedIn : null;
    if (query.detailedIn != null && !query.detailedIn.equals(detailedIn)) {
      return false;
    }
    return true;
  }

  /**
   * The value-reading dimensions (text / state), re-evaluated against the live
   * document. Returns the built match (with snippet/spans) or {@code null} when
   * the node no longer satisfies the query. Assumes the path is structurally
   * valid.
   */
  SpecQueryMatch evaluateLive(SpecQuery query, SomTextPattern pattern, String path) {
    if (!isLivePath(path)) {
      return null;
    }
    SpecResolution resolution = reflection.resolve(path);
    if (resolution == null) {
      return null;
    }

    if (query.state != null) {
      boolean hasValue = document.hasValuesUnder(path);
      boolean wantValue = query.state == SpecStateFilter.NON_EMPTY;
      if (hasValue != wantValue) {
        return null;
      }
    }

    String snippet = null;
    List<SpecMatchSpan> spans = Collections.emptyList();
    if (pattern != null) {
      TextHit hit = matchText(pattern, resolution);
      if (hit == null) {
        return null;
      }
      snippet = hit.snippet;
      spans = hit.spans;
    }

    return new SpecQueryMatch(
        path,
        resolution.kind,
        resolution.targetClass != null ? resolution.targetClass.name : null,
        headlineOf(resolution),
        snippet,
        spans);
  }

  /** The searched string a pattern hit, with the spans it hit at. */
  private static final class TextHit {
    final String snippet;
    final List<SpecMatchSpan> spans;

    TextHit(String snippet, List<SpecMatchSpan> spans) {
      this.snippet = snippet;
      this.spans = spans;
    }
  }

  private TextHit matchText(SomTextPattern pattern, SpecResolution resolution) {
    // Search each candidate string in turn; the first that hits wins, so the
    // snippet is the actual text the pattern matched.
    for (String text : searchableStrings(resolution)) {
      List<SpecMatchSpan> spans = pattern.allMatches(text);
      if (!spans.isEmpty()) {
        return new TextHit(text, spans);
      }
    }
    return null;
  }

  /**
   * The strings a {@code text} query searches at {@code resolution}: stored values
   * first (content leaf, scalar list item, every form field), then the node's
   * headline.
   */
  private List<String> searchableStrings(SpecResolution resolution) {
    List<String> out = new ArrayList<>();
    String path = resolution.path;
    switch (resolution.kind) {
      case CONTENT:
      case ENUM_VALUE:
      case SCALAR:
      case LIST_ITEM_SCALAR: {
        String value = document.content(path);
        if (value != null) {
          out.add(value);
        }
        break;
      }
      case FORM:
        for (String name : document.formFieldNames(path)) {
          String value = document.formField(path, name);
          if (value != null) {
            out.add(value);
          }
        }
        break;
      default:
        break; // container nodes carry no direct value
    }
    String headline = headlineOf(resolution);
    if (headline != null) {
      out.add(headline);
    }
    return out;
  }

  private SomTextPattern patternFor(SpecQuery query) {
    return query.regex
        ? SomTextPattern.compile(query.text, query.caseInsensitive)
        : SomTextPattern.literal(query.text, query.caseInsensitive);
  }

  // --- path liveness (cursor stability) -------------------------------------

  /**
   * Whether {@code path} still exists in the live document: every {@code -<seq>}
   * list-item segment must still be present in its parent list. Model-fixed
   * segments (root, complex/section, declared leaves) are always structurally
   * live, so only list items can go stale (via
   * {@link SpecDocument#removeListItem}).
   */
  private boolean isLivePath(String path) {
    String[] segments = SpecPaths.segments(path);
    String prefix = "";
    for (int i = 0; i < segments.length; i++) {
      String previous = prefix;
      prefix = i == 0 ? segments[i] : SpecPaths.join(prefix, segments[i]);
      SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(segments[i]);
      if (split == null) {
        continue;
      }
      String listPath = i == 0 ? split.base : SpecPaths.join(previous, split.base);
      SpecResolution resolution = reflection.resolve(listPath);
      if (resolution != null
          && resolution.kind == SpecNodeKind.LIST
          && !document.listItems(listPath).contains(prefix)) {
        return false;
      }
    }
    return true;
  }

  // --- node descriptors -----------------------------------------------------

  private String sectionIdOf(SpecResolution resolution) {
    if (resolution.field != null && resolution.field.sectionId != null) {
      return resolution.field.sectionId;
    }
    if (resolution.targetClass != null && resolution.targetClass.sectionId != null) {
      return resolution.targetClass.sectionId;
    }
    return resolution.root.sectionId;
  }

  /**
   * The headline a node actually shows: the document's <b>stored</b> headline when
   * the author set one, otherwise the model's doc comment.
   *
   * <p>The stored value comes first because it is the one a reader sees and the
   * one an author would search for. Consulting only the doc comment made renamed
   * sections unfindable — {@code setHeadline("DEMO/SUM", "Executive Summary")}
   * stored text that no query could reach and that never entered the search index
   * built from {@link #projectNodes}.
   */
  private String headlineOf(SpecResolution resolution) {
    String stored = document.headline(resolution.path);
    if (stored != null) {
      return stored;
    }
    if (resolution.field != null && resolution.field.doc != null) {
      return resolution.field.doc;
    }
    if (resolution.targetClass != null && resolution.targetClass.doc != null) {
      return resolution.targetClass.doc;
    }
    return resolution.kind == SpecNodeKind.ROOT ? resolution.root.description : null;
  }

  /**
   * Glob match over a whole path: {@code **} spans {@code /}, a single {@code *}
   * stays within one segment, every other character is literal.
   *
   * <p>Matched directly rather than compiled to a regex, because two of the nine
   * runtimes have no regex engine and because a wildcard walk is a smaller, more
   * obviously identical thing to transcribe than an escaping rule plus somebody
   * else's matcher (see {@link SomTextPattern}).
   */
  private static boolean globMatches(String glob, String path) {
    return globAt(glob.toCharArray(), 0, path.toCharArray(), 0);
  }

  /**
   * Greedy wildcard walk with backtracking: at a {@code *}/{@code **} try the
   * longest remaining span first and give characters back until the tail fits.
   */
  private static boolean globAt(char[] glob, int g, char[] path, int p) {
    while (g < glob.length) {
      if (glob[g] != ASTERISK) {
        if (p >= path.length || path[p] != glob[g]) {
          return false;
        }
        g++;
        p++;
        continue;
      }
      boolean crossesSegments = g + 1 < glob.length && glob[g + 1] == ASTERISK;
      int afterWildcard = g + (crossesSegments ? 2 : 1);
      // Longest first, so `*` behaves greedily exactly as the regex did.
      int limit = path.length;
      if (!crossesSegments) {
        for (int i = p; i < path.length; i++) {
          if (path[i] == SLASH) {
            limit = i;
            break;
          }
        }
      }
      for (int take = limit; take >= p; take--) {
        if (globAt(glob, afterWildcard, path, take)) {
          return true;
        }
      }
      return false;
    }
    return p == path.length;
  }
}
