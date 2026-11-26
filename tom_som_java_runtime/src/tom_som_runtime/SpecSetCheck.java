package tom_som_runtime;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;

/**
 * The comparison behind {@link SpecDocumentSet#syncReport} (and
 * {@link SpecBackfill#backfill}, {@link SpecPrefill#prefill} and
 * {@link SpecDocumentSet#renameId}): one per run, with its caches
 * ({@code tom_specs_model_rules.md} §9.7).
 */
public final class SpecSetCheck {
  public final SpecDocumentSet set;
  public final SpecReflection refl;
  /** The findings collected so far. */
  public final List<SpecSetFound> out = new ArrayList<>();
  /** The pairs whose Phase 3 document exists but holds nothing beneath the pair's anchor. */
  public final List<String> notStartedPairs = new ArrayList<>();

  private final Map<SpecDocument, Map<String, String>> itemIds = new IdentityHashMap<>();
  private final Map<String, Boolean> items = new HashMap<>();
  private final Map<SpecDocument, Map<String, List<String>>> forms = new IdentityHashMap<>();
  private final Map<String, String> registryDocs = new HashMap<>();
  private final Map<String, Set<String>> reach = new HashMap<>();
  private final Map<SpecDocument, Map<String, Map<String, String>>> entries = new IdentityHashMap<>();
  private final Map<String, List<SpecSameAsBinding>> sameAs = new HashMap<>();

  private static final Pattern FLOAT_TEXT =
      Pattern.compile("(?i)^[+-]?(\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?$");
  private static final Pattern HEX_TEXT = Pattern.compile("(?i)^[+-]?0x[0-9a-f]+$");
  private static final Pattern SPECIAL_TEXT = Pattern.compile("^[+-]?(Infinity|NaN)$");
  private static final Pattern ITEM_BRACKETS = Pattern.compile("\\[[^\\]]*\\]");

  public SpecSetCheck(SpecDocumentSet set) {
    this.set = set;
    this.refl = set.refl;
  }

  void add(int order, String key, SpecSyncFinding finding, SpecSetSide b, SpecSetSide d) {
    out.add(new SpecSetFound(order, key, finding, b, d));
  }

  /** Sorts {@link #out} as the report lists it. */
  public void sortOut() {
    out.sort(
        (a, b) -> {
          if (a.order != b.order) {
            return Integer.compare(a.order, b.order);
          }
          int c = a.key.compareTo(b.key);
          if (c != 0) {
            return c;
          }
          c = Integer.compare(a.finding.code.ordinal(), b.finding.code.ordinal());
          if (c != 0) {
            return c;
          }
          return sortValue(a.finding).compareTo(sortValue(b.finding));
        });
  }

  private static String sortValue(SpecSyncFinding f) {
    return f.blueprint.value != null ? f.blueprint.value : f.detail.valueOr();
  }

  String rootSeg(String typeName) {
    for (SpecRoot r : refl.model.roots) {
      if (r.type.equals(typeName)) {
        return refl.rootSegment(r);
      }
    }
    throw new IllegalStateException("no root " + typeName);
  }

  // --- values -------------------------------------------------------------------

  /** {@code s}, {@code ""} for {@code null}. */
  static String or(String s) {
    return s == null ? "" : s;
  }

  /** The value at {@code path} / {@code field} ({@code null} content, {@code @headline} a headline), {@code ""} when unset. */
  static String getValue(SpecDocument doc, String path, String field) {
    if (field == null) {
      return or(doc.content(path));
    }
    if (field.equals(SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD)) {
      return or(doc.headline(path));
    }
    return or(doc.formField(path, field));
  }

  /** Writes {@code value} at {@code path} / {@code field} ({@code ""} clears it). */
  static void setValue(SpecDocument doc, String path, String field, String value) {
    if (field == null) {
      doc.setContent(path, value);
    } else if (field.equals(SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD)) {
      doc.setHeadline(path, value);
    } else {
      doc.setFormField(path, field, value);
    }
  }

  /** {@code raw} with every pending mark rejected, trimmed. */
  public static String reviewed(String raw) {
    return SpecReviewAnnotations.applyInlineMarksText(raw, false).strip();
  }

  /** Whether {@code raw} holds pending change marks. */
  public static boolean isPending(String raw) {
    return !SpecReviewAnnotations.applyInlineMarksText(raw, true)
        .equals(SpecReviewAnnotations.applyInlineMarksText(raw, false));
  }

  /** Dart's {@code num.tryParse}: decimal, hex, {@code Infinity} and {@code NaN}; {@code null} when it reads as none. */
  static Double numTryParse(String text) {
    String t = text.strip();
    if (FLOAT_TEXT.matcher(t).matches()) {
      return Double.parseDouble(t);
    }
    if (HEX_TEXT.matcher(t).matches()) {
      boolean neg = t.startsWith("-");
      String digits = t.replaceFirst("^[+-]", "").substring(2);
      double v = new BigInteger(digits, 16).doubleValue();
      return neg ? -v : v;
    }
    if (SPECIAL_TEXT.matcher(t).matches()) {
      if (t.endsWith("NaN")) {
        return Double.NaN;
      }
      return t.startsWith("-") ? Double.NEGATIVE_INFINITY : Double.POSITIVE_INFINITY;
    }
    return null;
  }

  /** Whether {@code a} and {@code b} are the same value of the field's type. */
  public static boolean sameTyped(String a, String b, FormFieldSpec spec) {
    String t = spec == null || spec.type == null ? "" : spec.type;
    switch (t) {
      case "int":
      case "double":
      case "num":
        {
          Double x = numTryParse(a);
          Double y = numTryParse(b);
          if (x != null && y != null) {
            return x.doubleValue() == y.doubleValue();
          }
          break;
        }
      case "bool":
        return a.toLowerCase(java.util.Locale.ROOT).equals(b.toLowerCase(java.util.Locale.ROOT));
      default:
        break;
    }
    return a.equals(b);
  }

  /** A value key ({@code c:} / {@code f:} / {@code h:} / {@code i:}) without its kind and field. */
  public static String stripKind(String key) {
    String k = key.length() > 2 && key.charAt(1) == ':' ? key.substring(2) : key;
    int hash = k.indexOf('#');
    return hash >= 0 ? k.substring(0, hash) : k;
  }

  private static boolean underAny(String path, Collection<String> prefixes) {
    for (String p : prefixes) {
      if (path.equals(p) || path.startsWith(p + "/")) {
        return true;
      }
    }
    return false;
  }

  private static List<String> sorted(Collection<String> c) {
    return new ArrayList<>(new TreeSet<>(c));
  }

  @SafeVarargs
  private static List<String> sortedKeysOf(Map<String, ?>... maps) {
    TreeSet<String> keys = new TreeSet<>();
    for (Map<String, ?> m : maps) {
      keys.addAll(m.keySet());
    }
    return new ArrayList<>(keys);
  }

  // --- items and keys -----------------------------------------------------------

  /** The effective section id of the list item at {@code itemPath} in {@code doc}. */
  public String itemId(SpecDocument doc, String itemPath) {
    Map<String, String> byDoc = itemIds.computeIfAbsent(doc, k -> new HashMap<>());
    String hit = byDoc.get(itemPath);
    if (hit == null) {
      hit = effectiveItemId(refl, doc, itemPath);
      byDoc.put(itemPath, hit);
    }
    return hit;
  }

  /** The stored section id of the item at {@code itemPath}, else the one its position and the list's pattern give it. */
  static String effectiveItemId(SpecReflection refl, SpecDocument doc, String itemPath) {
    String stored = doc.itemSectionId(itemPath);
    if (stored != null) {
      return stored;
    }
    int dash = itemPath.lastIndexOf('-');
    String lst = dash >= 0 ? itemPath.substring(0, dash) : itemPath;
    String pattern = null;
    String stem = lst.substring(lst.lastIndexOf('/') + 1);
    SpecResolution res = refl.resolve(lst);
    if (res != null && res.field != null) {
      pattern = res.field.sectionIdPattern;
      stem = res.field.name;
    }
    if (pattern != null && pattern.isEmpty()) {
      pattern = null;
    }
    int position = doc.listItems(lst).indexOf(itemPath) + 1;
    return SpecSectionId.effectiveListItemSectionId(null, pattern, position, stem);
  }

  /** Whether {@code path} is a list item (complex or scalar). */
  public boolean isItem(String path) {
    Boolean hit = items.get(path);
    if (hit != null) {
      return hit;
    }
    // A scalar list's items are elements too, keyed by their effective id like
    // a complex list's (`LIST[ID]`).
    SpecResolution r = refl.resolve(path);
    boolean is =
        r != null
            && (r.kind == SpecNodeKind.LIST_ITEM_COMPLEX || r.kind == SpecNodeKind.LIST_ITEM_SCALAR);
    items.put(path, is);
    return is;
  }

  /** The concrete paths a pattern (list items {@code <list>-*}) stands for in {@code doc}. */
  public List<String> expand(SpecDocument doc, String pattern) {
    return SpecLinkValidator.expandPattern(doc, pattern);
  }

  /** The key of {@code path} below {@code anchor}: item segments as {@code LIST[id]}. */
  public String key(SpecDocument doc, String anchor, String path) {
    if (path.equals(anchor)) {
      return "";
    }
    List<String> parts = new ArrayList<>();
    String at = anchor;
    for (String seg : path.substring(anchor.length() + 1).split("/", -1)) {
      at = at + "/" + seg;
      if (isItem(at)) {
        parts.add(seg.substring(0, seg.lastIndexOf('-')) + "[" + itemId(doc, at) + "]");
      } else {
        parts.add(seg);
      }
    }
    return String.join("/", parts);
  }

  /** The key of an anchor itself among its siblings: the ids of the list items on its path. */
  public String anchorKey(SpecDocument doc, String path) {
    List<String> parts = new ArrayList<>();
    String at = "";
    for (String seg : path.split("/", -1)) {
      at = at.isEmpty() ? seg : at + "/" + seg;
      if (isItem(at)) {
        parts.add(itemId(doc, at));
      }
    }
    return String.join("/", parts);
  }

  /** The places a set of place texts stands for under an anchor. */
  private static final class Places {
    final List<String> prefixes = new ArrayList<>();
    final Set<String> fields = new HashSet<>();
    final Set<String> headlines = new HashSet<>();
  }

  /** The paths {@code places} resolved under {@code anchor} stand for in {@code doc}. */
  private Places places(SpecDocument doc, Collection<String> places, String anchor) {
    Places o = new Places();
    for (String text : places) {
      SpecPlaceResolution r = SpecLinkValidator.resolvePlaceAt(refl, text, anchor);
      if (r == null) {
        continue;
      }
      for (String p : expand(doc, r.path)) {
        switch (r.kind) {
          case FORM_FIELD:
            o.fields.add(p + "#" + r.field());
            break;
          case HEADLINE:
            o.headlines.add(p);
            break;
          case SECTION_ID:
            break;
          default:
            o.prefixes.add(p);
            break;
        }
      }
    }
    return o;
  }

  private static boolean under(String p, String anchor) {
    return p.equals(anchor) || p.startsWith(anchor + "/");
  }

  /**
   * The values beneath {@code anchor} in {@code doc}, with what the pair does
   * not compare left out: {@code detailOnly} places, nested pairs,
   * {@code @SameAs} copies and derived places.
   */
  public SpecSetSide collect(
      String name, SpecDocument doc, String root, String anchor, SpecSyncPair pair, List<String> nested) {
    SpecSetSide side = new SpecSetSide(name, root, anchor);
    List<String> detailOnly = pair.sync != null ? pair.sync.detailOnly : List.of();
    Places skip = places(doc, detailOnly, anchor);
    List<SpecSameAsBinding> bindings =
        sameAs.computeIfAbsent(root, r -> SpecPlace.sameAsBindings(refl, r));
    List<String> excluded = new ArrayList<>(skip.prefixes);
    excluded.addAll(nested);
    for (SpecSameAsBinding b : bindings) {
      excluded.addAll(expand(doc, b.copyPath));
    }

    List<String> lists = sorted(doc.listPaths());
    // The values a summary row repeats are derived from its detail element
    // (`@SummaryOf` repeats): never shared, like every derived place.
    for (String lst : lists) {
      if (!under(lst, anchor)) {
        continue;
      }
      SpecResolution res = refl.resolve(lst);
      if (res == null || res.field == null) {
        continue;
      }
      SpecSummaryOf s = res.field.summaryOf();
      if (s == null || s.repeats.isEmpty()) {
        continue;
      }
      List<String> repeats = new ArrayList<>(s.repeats.keySet());
      for (String item : doc.listItems(lst)) {
        Places r = places(doc, repeats, item);
        excluded.addAll(r.prefixes);
        skip.fields.addAll(r.fields);
        skip.headlines.addAll(r.headlines);
      }
    }

    side.putItem("", anchor);
    for (String lst : lists) {
      if (!under(lst, anchor) || outside(lst, anchor, excluded)) {
        continue;
      }
      SpecResolution res = refl.resolve(lst);
      if (res != null && res.field != null && res.field.derivedFrom() != null) {
        excluded.add(lst);
        continue;
      }
      for (String item : doc.listItems(lst)) {
        side.putItem(key(doc, anchor, item), item);
      }
    }
    for (String p : sorted(doc.contentPaths())) {
      if (!under(p, anchor) || outside(p, anchor, excluded)) {
        continue;
      }
      SpecResolution res = refl.resolve(p);
      if (res != null && res.field != null && res.field.derivedFrom() != null) {
        continue;
      }
      String raw = or(doc.content(p));
      side.values.put(
          "c:" + key(doc, anchor, p), new SpecSetValue(p, null, reviewed(raw), isPending(raw), null));
    }
    for (String p : sorted(doc.formPaths())) {
      if (!under(p, anchor) || outside(p, anchor, excluded)) {
        continue;
      }
      SpecResolution res = refl.resolve(p);
      List<FormFieldSpec> specs = res != null && res.field != null ? res.field.formFields : List.of();
      for (String fname : sorted(doc.formFieldNames(p))) {
        if (skip.fields.contains(p + "#" + fname)) {
          continue;
        }
        FormFieldSpec spec = null;
        for (FormFieldSpec f : specs) {
          if (f.name.equals(fname)) {
            spec = f;
            break;
          }
        }
        if (spec != null
            && (spec.derivedFrom != null
                || !isEmpty(spec.countOf)
                || !isEmpty(spec.productOf)
                || (spec.rankOf != null && !spec.rankOf.isEmpty()))) {
          continue;
        }
        String raw = or(doc.formField(p, fname));
        side.values.put(
            "f:" + key(doc, anchor, p) + "#" + fname,
            new SpecSetValue(p, fname, reviewed(raw), isPending(raw), spec));
      }
    }
    for (String p : sorted(doc.headlinePaths())) {
      if (!under(p, anchor) || outside(p, anchor, excluded) || skip.headlines.contains(p)) {
        continue;
      }
      String raw = or(doc.headline(p));
      side.values.put(
          "h:" + key(doc, anchor, p),
          new SpecSetValue(
              p, SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD, reviewed(raw), isPending(raw), null));
    }
    return side;
  }

  private static boolean outside(String p, String anchor, List<String> excluded) {
    return !p.equals(anchor) && underAny(p, excluded);
  }

  /**
   * The path {@code key} stands for on {@code side}: the item paths it names as
   * far as the side holds them; where it stops, the list an element would go in.
   */
  String pathOn(SpecSetSide side, String key) {
    if (key.isEmpty()) {
      return side.anchor;
    }
    String path = side.anchor;
    String prefix = "";
    for (String s : key.split("/", -1)) {
      prefix = prefix.isEmpty() ? s : prefix + "/" + s;
      int bracket = s.indexOf('[');
      if (bracket > 0) {
        String item = side.items.get(prefix);
        if (item == null) {
          return path + "/" + s.substring(0, bracket);
        }
        path = item;
      } else {
        path = path + "/" + s;
      }
    }
    return path;
  }

  // --- one pair -----------------------------------------------------------------

  /** Compares one pair, adding its findings at {@code order}. */
  public void comparePair(SpecSyncPair pair, int order) {
    String bpName = set.nameOf(set.blueprintRoot);
    String dtName = set.nameOf(pair.detailRoot);
    if (bpName == null || dtName == null) {
      return; // not started
    }
    SpecDocument bp = set.get(bpName);
    SpecDocument dt = set.get(dtName);
    String bpRoot = set.blueprintRoot;

    Map<String, String> bpAnchors = new LinkedHashMap<>();
    for (String a : expand(bp, pair.blueprintAnchor)) {
      bpAnchors.put(anchorKey(bp, a), a);
    }
    Map<String, String> dtAnchors = new HashMap<>();
    for (String a : expand(dt, pair.detailAnchor)) {
      dtAnchors.put(anchorKey(dt, a), a);
    }
    // A pair the Phase 3 document has not written yet is not started, never
    // findings: it is what prefill fills, and backfill must not take its
    // emptiness for removals.
    boolean started = false;
    for (String a : dtAnchors.values()) {
      if (dt.hasValuesUnder(a)) {
        started = true;
        break;
      }
    }
    if (!started) {
      notStartedPairs.add(pair.sectionId);
      return;
    }
    List<String> bpNested = null;
    List<String> dtNested = null;
    for (Map.Entry<String, String> e : bpAnchors.entrySet()) {
      String ba = e.getValue();
      String da = dtAnchors.get(e.getKey());
      if (da == null) {
        continue; // the outer list reports it
      }
      if (bpNested == null) {
        bpNested = nested(pair, bp, true);
        dtNested = nested(pair, dt, false);
      }
      SpecSetSide b = collect(bpName, bp, bpRoot, ba, pair, beneath(bpNested, ba));
      SpecSetSide d = collect(dtName, dt, pair.detailRoot, da, pair, beneath(dtNested, da));
      new PairCompare(pair, order, b, d, bp, dt).run();
    }
  }

  /** The anchors of the other pairs (nested pairs are compared on their own). */
  private List<String> nested(SpecSyncPair pair, SpecDocument doc, boolean blueprintSide) {
    List<String> o = new ArrayList<>();
    for (SpecSyncPair other : set.pairs()) {
      if (other != pair && (blueprintSide || other.detailRoot.equals(pair.detailRoot))) {
        o.addAll(expand(doc, blueprintSide ? other.blueprintAnchor : other.detailAnchor));
      }
    }
    return o;
  }

  private static List<String> beneath(List<String> all, String anchor) {
    List<String> o = new ArrayList<>();
    for (String p : all) {
      if (p.startsWith(anchor + "/")) {
        o.add(p);
      }
    }
    return o;
  }

  private static String shape(String key) {
    return ITEM_BRACKETS.matcher(key).replaceAll("[]");
  }

  /** The distinct entries of {@code a} not in {@code b}, sorted. */
  private static List<String> sortedMinus(List<String> a, List<String> b) {
    TreeSet<String> o = new TreeSet<>();
    for (String x : a) {
      if (!b.contains(x)) {
        o.add(x);
      }
    }
    return new ArrayList<>(o);
  }

  /** The comparison of one anchor pair's two sides. */
  private final class PairCompare {
    final SpecSyncPair pair;
    final int order;
    final SpecSetSide b;
    final SpecSetSide d;
    final SpecDocument bp;
    final SpecDocument dt;
    final Map<String, String[]> listRel = new HashMap<>();
    final Map<String, String> fieldRelByShape = new HashMap<>();
    Places held;

    PairCompare(SpecSyncPair pair, int order, SpecSetSide b, SpecSetSide d, SpecDocument bp, SpecDocument dt) {
      this.pair = pair;
      this.order = order;
      this.b = b;
      this.d = d;
      this.bp = bp;
      this.dt = dt;
    }

    boolean isHeld(String bpPath, String fld) {
      return underAny(bpPath, held.prefixes) || (fld != null && held.fields.contains(bpPath + "#" + fld));
    }

    SpecSyncPlace place(SpecSetSide s, String key, String fld, String value) {
      SpecSetValue v = s.values.get(key);
      String path;
      String field = fld;
      String val = value;
      boolean pending = false;
      if (v != null) {
        path = v.path;
        if (fld == null) {
          field = v.field;
        }
        if (value == null) {
          val = v.value;
        }
        pending = v.pending;
      } else if (key.startsWith("i:")) {
        path = pathOn(s, key.substring(2));
      } else {
        path = pathOn(s, stripKind(key));
      }
      return new SpecSyncPlace(s.name, rootSeg(s.root), path, field, val, pending);
    }

    void emit(
        SpecSyncCode code,
        String key,
        String message,
        boolean heldHere,
        String fld,
        String bValue,
        String dValue,
        SpecSyncResolution resolution) {
      SpecSyncHolder holder = heldHere ? SpecSyncHolder.BLUEPRINT : SpecSyncHolder.DETAIL;
      if (resolution == null) {
        resolution = heldHere ? SpecSyncResolution.AGENT : SpecSyncResolution.BACKFILL;
      }
      add(
          order,
          key,
          new SpecSyncFinding(
              code,
              pair.sectionId,
              place(b, key, fld, bValue),
              place(d, key, fld, dValue),
              holder,
              resolution,
              message),
          b,
          d);
    }

    void run() {
      SpecSync sync = pair.sync;
      Map<String, String> fieldRel = new HashMap<>();
      List<SpecListRelation> relations = sync != null ? sync.relations : List.of();
      List<String> heldHere = sync != null ? sync.heldHere : List.of();
      for (SpecListRelation r : relations) {
        SpecPlaceResolution res = SpecLinkValidator.resolvePlaceAt(refl, r.place, b.anchor);
        if (res == null) {
          continue;
        }
        for (String p : expand(bp, res.path)) {
          String k = key(bp, b.anchor, p);
          if (res.kind == SpecPlaceKind.LIST) {
            listRel.put(k, new String[] {r.relation, r.where});
          } else if (res.kind == SpecPlaceKind.FORM_FIELD) {
            fieldRel.put(k + "#" + res.field(), r.relation);
          }
        }
      }
      // A relation stated for a form field is the same for every element: match
      // it by its key with item ids dropped.
      for (Map.Entry<String, String> e : fieldRel.entrySet()) {
        fieldRelByShape.put(shape(e.getKey()), e.getValue());
      }
      held = places(bp, heldHere, b.anchor);
      List<String> oneSided = elements();
      values(oneSided);
    }

    /** The elements only one side holds; their keys. */
    List<String> elements() {
      List<String> oneSided = new ArrayList<>();
      for (String k : sortedKeysOf(b.items, d.items)) {
        if (k.isEmpty()) {
          continue;
        }
        boolean inB = b.items.containsKey(k);
        boolean inD = d.items.containsKey(k);
        if (inB == inD) {
          continue;
        }
        boolean beneathOther = false;
        for (String o : oneSided) {
          if (k.startsWith(o + "/")) {
            beneathOther = true;
            break;
          }
        }
        if (beneathOther) {
          continue;
        }
        oneSided.add(k);
        // `LIST[ID]` (every item key); a key without the brackets names its
        // element by its last segment.
        int bracket = k.lastIndexOf('[');
        String parentList;
        if (bracket < 0) {
          int slash = k.lastIndexOf('/');
          parentList = slash >= 0 ? k.substring(0, slash) : "";
        } else {
          parentList = k.substring(0, bracket);
        }
        String[] rel = listRel.get(parentList);
        String relation = rel != null ? rel[0] : "equal";
        String itemPath = inB ? b.items.get(k) : d.items.get(k);
        SpecDocument doc = inB ? bp : dt;
        if (rel != null && rel[1] != null && !rel[1].isEmpty()) {
          SpecPlaceFilter flt = SpecPlaceFilter.tryParse(rel[1]);
          if (flt != null && flt.field != null && !flt.field.isEmpty()
              && !flt.matches(ownValues(doc, itemPath, flt.field))) {
            relation = "equal";
          }
        }
        String id = bracket < 0 ? k.substring(k.lastIndexOf('/') + 1) : k.substring(bracket + 1, k.length() - 1);
        String heldPath = inB ? itemPath : pathOn(b, k);
        boolean heldHere = isHeld(heldPath, null);
        String key = "i:" + k;
        if (inD && relation.equals("subset")) {
          emit(SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED, key,
              id + " is only in " + d.name + "; under subset it may be added to " + b.name,
              heldHere, null, null, id, SpecSyncResolution.INFO);
        } else if (inD) {
          emit(SpecSyncCode.SHARED_ELEMENT_MISSING, key,
              id + " is in " + d.name + " and missing in " + b.name,
              heldHere, null, null, id, null);
        } else if (!relation.equals("superset")) {
          emit(SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT, key,
              id + " is only in " + b.name + "; " + d.name + " removed it",
              heldHere, null, id, null, null);
        }
      }
      return oneSided;
    }

    void values(List<String> oneSided) {
      for (String k : sortedKeysOf(b.values, d.values)) {
        String rel = stripKind(k);
        boolean beneathOneSided = false;
        for (String o : oneSided) {
          if (rel.equals(o) || rel.startsWith(o + "/")) {
            beneathOneSided = true;
            break;
          }
        }
        if (beneathOneSided) {
          continue;
        }
        SpecSetValue vb = b.values.get(k);
        SpecSetValue vd = d.values.get(k);
        FormFieldSpec spec = null;
        String fld = null;
        String bValue = "";
        String dValue = "";
        if (vb != null) {
          spec = vb.spec;
          fld = vb.field;
          bValue = vb.value;
        }
        if (vd != null) {
          if (spec == null) {
            spec = vd.spec;
          }
          if (fld == null) {
            fld = vd.field;
          }
          dValue = vd.value;
        }
        String heldPath = vb != null ? vb.path : pathOn(b, stripKind(k));
        boolean heldHere = isHeld(heldPath, fld);
        if (spec != null && spec.multiple && !isEmpty(spec.refersTo)) {
          String relation = fieldRelByShape.getOrDefault(shape(k.substring(2)), "equal");
          List<String> ib = SpecLinkValidator.linkIds(bValue);
          List<String> idd = SpecLinkValidator.linkIds(dValue);
          for (String x : sortedMinus(idd, ib)) {
            boolean may = relation.equals("subset");
            emit(
                may ? SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED : SpecSyncCode.SHARED_ELEMENT_MISSING,
                k,
                x + " is named in " + d.name + " and not in " + b.name,
                heldHere, fld, nonEmpty(bValue), x, may ? SpecSyncResolution.INFO : null);
          }
          if (!relation.equals("superset")) {
            for (String x : sortedMinus(ib, idd)) {
              emit(SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT, k,
                  x + " is named only in " + b.name, heldHere, fld, x, nonEmpty(dValue), null);
            }
          }
          continue;
        }
        if (bValue.isEmpty() && dValue.isEmpty()) {
          continue;
        }
        if (sameTyped(bValue, dValue, spec)) {
          continue;
        }
        String what = fld != null ? "form field \"" + fld + "\"" : "the value";
        if (bValue.isEmpty()) {
          emit(SpecSyncCode.SHARED_VALUE_MISSING, k,
              what + " is filled in " + d.name + " and empty in " + b.name, heldHere, fld, null, null, null);
        } else if (dValue.isEmpty()) {
          emit(SpecSyncCode.SHARED_VALUE_ONLY_IN_BLUEPRINT, k,
              what + " is filled only in " + b.name + "; " + d.name + " emptied it",
              heldHere, fld, null, null, null);
        } else {
          String message =
              what + " differs: \"" + bValue + "\" in " + b.name + ", \"" + dValue + "\" in " + d.name;
          if (heldHere) {
            message += " (held in " + b.name + ")";
          }
          emit(SpecSyncCode.SHARED_VALUE_DIFFERS, k, message, heldHere, fld, null, null, null);
        }
      }
    }
  }

  private static boolean isEmpty(List<String> list) {
    return list == null || list.isEmpty();
  }

  private static String nonEmpty(String s) {
    return s.isEmpty() ? null : s;
  }

  /** The values a row's own forms ({@code <row>/<member>}) hold in {@code fld}. */
  List<String> ownValues(SpecDocument doc, String row, String fld) {
    Map<String, List<String>> index = forms.get(doc);
    if (index == null) {
      index = new HashMap<>();
      for (String p : sorted(doc.formPaths())) {
        int slash = p.lastIndexOf('/');
        if (slash > 0) {
          index.computeIfAbsent(p.substring(0, slash), k -> new ArrayList<>()).add(p);
        }
      }
      forms.put(doc, index);
    }
    List<String> o = new ArrayList<>();
    for (String p : index.getOrDefault(row, List.of())) {
      String v = doc.formField(p, fld);
      if (v != null) {
        o.add(reviewed(v));
      }
    }
    return o;
  }

  // --- unmarkable derived changes and pending marks -------------------------------

  /**
   * Lists every change {@code deriveFields} would write in a document under
   * review that cannot be marked exactly: left for the agent.
   */
  void unmarkableScan(int order) {
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      String root = rootSeg(set.rootOf(name));
      SpecDeriveOptions options = new SpecDeriveOptions();
      options.marked = true;
      options.dryRun = true;
      SpecDeriveResult derived = SpecDeriveFields.deriveFields(set.model, doc, options);
      for (SpecValidationError u : derived.unresolved) {
        if (u.code != SpecValidationCode.UNMARKABLE) {
          continue;
        }
        SpecSyncPlace p = new SpecSyncPlace(name, root, u.path, null, null, false);
        add(
            order,
            name + " " + u.path,
            new SpecSyncFinding(
                SpecSyncCode.UNMARKABLE, "", p, p, SpecSyncHolder.DETAIL, SpecSyncResolution.AGENT,
                u.message + " (in " + name + ")"),
            null,
            null);
      }
    }
  }

  /** Lists every value of every document that holds pending change marks. */
  void pendingScan(int order) {
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      String root = rootSeg(set.rootOf(name));
      for (String p : sorted(doc.contentPaths())) {
        flagPending(order, name, root, p, null, or(doc.content(p)));
      }
      for (String p : sorted(doc.formPaths())) {
        for (String f : sorted(doc.formFieldNames(p))) {
          flagPending(order, name, root, p, f, or(doc.formField(p, f)));
        }
      }
      for (String p : sorted(doc.headlinePaths())) {
        flagPending(order, name, root, p, null, or(doc.headline(p)));
      }
    }
  }

  private void flagPending(int order, String name, String root, String path, String fld, String raw) {
    if (!isPending(raw)) {
      return;
    }
    SpecSyncPlace p = new SpecSyncPlace(name, root, path, fld, reviewed(raw), true);
    String what = fld != null ? "form field \"" + fld + "\"" : "the value";
    add(
        order,
        name + " " + path + " " + or(fld),
        new SpecSyncFinding(
            SpecSyncCode.PENDING_REVIEW, "", p, p, SpecSyncHolder.DETAIL, SpecSyncResolution.INFO,
            what + " at " + path + " in " + name + " holds pending change marks"),
        null,
        null);
  }

  // --- links across two documents ------------------------------------------------

  /** Every class instance of a document of root {@code typeName}: path and class. */
  private List<Map.Entry<String, SpecClass>> instances(SpecDocument doc, String typeName) {
    List<Map.Entry<String, SpecClass>> o = new ArrayList<>();
    SpecClass cls = refl.classNamed(typeName);
    if (cls != null) {
      walk(doc, cls, rootSeg(typeName), new HashSet<>(), o);
    }
    return o;
  }

  private void walk(
      SpecDocument doc, SpecClass cls, String path, Set<String> onPath, List<Map.Entry<String, SpecClass>> o) {
    o.add(Map.entry(path, cls));
    for (SpecField f : cls.fields) {
      if (f.hasAnnotation("Reference")) {
        continue;
      }
      String member = path + "/" + refl.fieldSegment(f);
      if (f.kind == SpecFieldKind.LIST && f.elementIsComplex) {
        SpecClass el = refl.classNamed(f.elementType);
        if (el == null) {
          continue;
        }
        for (String item : doc.listItems(member)) {
          walk(doc, el, item, new HashSet<>(), o);
        }
      } else if (f.kind == SpecFieldKind.COMPLEX || f.kind == SpecFieldKind.SECTION) {
        SpecClass child = refl.classNamed(f.type == null ? "" : f.type.replace("?", ""));
        if (child == null || onPath.contains(child.name)) {
          continue;
        }
        Set<String> next = new HashSet<>(onPath);
        next.add(cls.name);
        walk(doc, child, member, next, o);
      }
    }
  }

  /**
   * The document a registry class is read in: the one whose root details it (a
   * populated root other than the Blueprint's that reaches it), else the
   * Blueprint ({@code null} for none).
   */
  private String registryDocument(String sectionId) {
    if (registryDocs.containsKey(sectionId)) {
      return registryDocs.get(sectionId);
    }
    String hit = computeRegistryDocument(sectionId);
    registryDocs.put(sectionId, hit);
    return hit;
  }

  private String computeRegistryDocument(String sectionId) {
    Set<String> classes = new HashSet<>();
    for (SpecClass cls : refl.model.classes.values()) {
      if (sectionId != null && sectionId.equals(cls.sectionId)) {
        classes.add(cls.name);
      }
    }
    String blueprint = null;
    for (String name : set.names()) {
      String root = set.rootOf(name);
      Set<String> r = reach.computeIfAbsent(root, refl::reachableClassNames);
      boolean reaches = false;
      for (String c : r) {
        if (classes.contains(c)) {
          reaches = true;
          break;
        }
      }
      if (!reaches) {
        continue;
      }
      if (root.equals(set.blueprintRoot)) {
        blueprint = name;
      } else {
        return name;
      }
    }
    return blueprint;
  }

  /** The identity of {@code item} as {@code target} ({@code SID.field}) names it, {@code null} when it has none. */
  private String identity(SpecDocument doc, String item, String target) {
    String fld = target.substring(target.indexOf('.') + 1);
    if (fld.equals(SpecSectionId.K_SECTION_ID_SLOT)) {
      return itemId(doc, item);
    }
    List<String> values = ownValues(doc, item, fld);
    return values.isEmpty() ? null : values.get(0);
  }

  /** The entry of {@code doc} that {@code refersTo} names {@code id} by, {@code null} when none. */
  private String entry(SpecDocument doc, List<String> refersTo, String id) {
    Map<String, Map<String, String>> byTarget = entries.computeIfAbsent(doc, k -> new HashMap<>());
    for (String t : refersTo) {
      Map<String, String> index = byTarget.get(t);
      if (index == null) {
        index = new HashMap<>();
        String sid = t.split("\\.", -1)[0];
        for (String lst : sorted(doc.listPaths())) {
          for (String item : doc.listItems(lst)) {
            SpecResolution r = refl.resolve(item);
            if (r == null || r.targetClass == null || !sid.equals(r.targetClass.sectionId)) {
              continue;
            }
            String name = identity(doc, item, t);
            if (name != null) {
              index.putIfAbsent(name, item);
            }
          }
        }
        byTarget.put(t, index);
      }
      String hit = index.get(id);
      if (hit != null) {
        return hit;
      }
    }
    return null;
  }

  private String nearestItem(String path) {
    String p = path;
    while (true) {
      if (isItem(p)) {
        return p;
      }
      int slash = p.lastIndexOf('/');
      if (slash < 0) {
        return null;
      }
      p = p.substring(0, slash);
    }
  }

  /**
   * Adds the findings of the links across two documents, summaries and
   * inverses, at {@code order}; {@code pairs} (non-null) keeps those of the
   * classes with those section ids.
   */
  public void crossChecks(Set<String> pairs, int order) {
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      String root = set.rootOf(name);
      for (Map.Entry<String, SpecClass> in : instances(doc, root)) {
        SpecClass cls = in.getValue();
        String pairId = cls.sectionId == null || cls.sectionId.isEmpty() ? cls.name : cls.sectionId;
        if (pairs != null && !pairs.contains(pairId)) {
          continue;
        }
        for (SpecField f : cls.fields) {
          String member = in.getKey() + "/" + refl.fieldSegment(f);
          SpecSummaryOf s = f.summaryOf();
          if (s != null && present(s.document) && f.kind == SpecFieldKind.LIST) {
            crossSummaryRows(order, pairId, name, doc, member, s);
          }
          for (FormFieldSpec ff : f.formFields) {
            if (ff.summaryOf != null && present(ff.summaryOf.document)) {
              crossSummaryField(order, pairId, name, doc, member, ff);
            }
            if (ff.inverseOf != null && !ff.inverseOf.symmetric()) {
              crossInverse(order, pairId, name, doc, member, ff);
            }
          }
        }
      }
    }
  }

  private static boolean present(String s) {
    return s != null && !s.isEmpty();
  }

  /** One detail element of a cross summary: its item and id. */
  private static final class Element {
    final String item;
    final String id;

    Element(String item, String id) {
      this.item = item;
      this.id = id;
    }
  }

  /** The detail elements of a cross summary. */
  private static final class Detail {
    final String name;
    final SpecDocument doc;
    final List<Element> elements;

    Detail(String name, SpecDocument doc, List<Element> elements) {
      this.name = name;
      this.doc = doc;
      this.elements = elements;
    }
  }

  /** The detail of a cross summary, {@code null} when the detail is not started or does not resolve. */
  private Detail crossDetail(SpecSummaryOf s) {
    String name = set.nameOf(s.document);
    if (name == null) {
      return null; // not started
    }
    SpecDocument doc = set.get(name);
    String seg = rootSeg(set.rootOf(name));
    SpecPlaceResolution r = null;
    int slash = s.detail.indexOf('/');
    if (slash < 0) {
      r = SpecLinkValidator.resolvePlaceAt(refl, s.detail, seg);
    } else {
      SpecPlaceResolution head = SpecLinkValidator.resolvePlaceAt(refl, s.detail.substring(0, slash), seg);
      if (head == null) {
        return null;
      }
      String scope = head.kind == SpecPlaceKind.LIST ? head.path + "-*" : head.path;
      List<String> concrete = expand(doc, scope);
      if (!concrete.isEmpty()) {
        SpecPlace p = SpecPlace.tryParse(s.detail.substring(slash + 1));
        if (p == null) {
          return null;
        }
        try {
          r = p.resolve(refl, concrete.get(0));
        } catch (SpecPlaceException e) {
          return null;
        }
      }
    }
    if (r == null || r.kind != SpecPlaceKind.LIST) {
      return null;
    }
    List<Element> elements = new ArrayList<>();
    Map<String, Integer> seen = new HashMap<>();
    for (String lst : expand(doc, r.path)) {
      for (String item : doc.listItems(lst)) {
        Element e = new Element(item, itemId(doc, item));
        Integer at = seen.get(item);
        if (at != null) {
          elements.set(at, e);
          continue;
        }
        seen.put(item, elements.size());
        elements.add(e);
      }
    }
    return new Detail(name, doc, elements);
  }

  private SpecSyncPlace place(String name, String path, String fld, String value) {
    String root = name != null ? rootSeg(set.rootOf(name)) : "";
    return new SpecSyncPlace(name, root, path, fld, value, false);
  }

  private void cross(int order, SpecSyncCode code, String pair, SpecSyncPlace here, SpecSyncPlace there, String message) {
    String document = here.document == null ? "None" : here.document;
    add(
        order,
        document + " " + here.path + " " + or(here.field) + " " + there.valueOr(),
        new SpecSyncFinding(code, pair, here, there, SpecSyncHolder.DETAIL, SpecSyncResolution.AGENT, message),
        null,
        null);
  }

  private static String listOf(List<Element> elements) {
    if (elements.isEmpty()) {
      return "";
    }
    String first = elements.get(0).item;
    return first.substring(0, first.lastIndexOf('-'));
  }

  private void crossSummaryRows(int order, String pair, String name, SpecDocument doc, String lst, SpecSummaryOf s) {
    Detail det = crossDetail(s);
    if (det == null) {
      return;
    }
    Map<String, String> byId = new HashMap<>();
    for (Element e : det.elements) {
      byId.put(e.id, e.item);
    }
    Map<String, String> named = new HashMap<>();
    for (String row : doc.listItems(lst)) {
      List<String> ids = present(s.match) ? matchIds(doc, s.match, row) : List.of(itemId(doc, row));
      for (String id : ids) {
        String target = byId.get(id);
        if (target == null) {
          cross(order, SpecSyncCode.CROSS_SUMMARY_MISMATCH, pair,
              place(name, row, null, id),
              place(det.name, listOf(det.elements), null, id),
              "the summary row names " + id + ", which is no element of " + s.detail + " in " + det.name);
          continue;
        }
        String prev = named.get(id);
        if (prev != null) {
          cross(order, SpecSyncCode.CROSS_SUMMARY_MISMATCH, pair,
              place(name, row, null, id),
              place(det.name, target, null, id),
              "the summary row names " + id + ", which " + prev + " names already");
          continue;
        }
        named.put(id, row);
        for (Map.Entry<String, String> rp : s.repeats.entrySet()) {
          ValueAt mine = valueAt(doc, rp.getKey(), row);
          ValueAt theirs = valueAt(det.doc, rp.getValue(), target);
          if (mine == null || theirs == null || mine.value.isEmpty()) {
            continue;
          }
          if (!mine.value.equals(theirs.value)) {
            cross(order, SpecSyncCode.CROSS_SUMMARY_MISMATCH, pair,
                place(name, mine.path, mine.field, mine.value),
                place(det.name, theirs.path, theirs.field, theirs.value),
                rp.getKey() + " repeats " + rp.getValue() + " of " + id + " as \"" + mine.value
                    + "\", but " + det.name + " holds \"" + theirs.value + "\"");
          }
        }
      }
    }
    if ("equal".equals(s.relation)) {
      for (Element e : det.elements) {
        if (named.containsKey(e.id)) {
          continue;
        }
        cross(order, SpecSyncCode.CROSS_SUMMARY_MISMATCH, pair,
            place(name, lst, null, null),
            place(det.name, e.item, null, e.id),
            "the detail element " + e.id + " of " + det.name + " is named by no row of " + lst
                + " (relation: equal)");
      }
    }
  }

  private List<String> matchIds(SpecDocument doc, String place, String row) {
    ValueAt v = valueAt(doc, place, row);
    return v == null ? List.of() : SpecLinkValidator.linkIds(v.value);
  }

  /** The value of a place under a concrete anchor. */
  private static final class ValueAt {
    final String path;
    final String value;
    final String field;

    ValueAt(String path, String value, String field) {
      this.path = path;
      this.value = value;
      this.field = field;
    }
  }

  /** The value of {@code place} under the concrete {@code anchor}, {@code null} when it does not resolve to one path. */
  private ValueAt valueAt(SpecDocument doc, String place, String anchor) {
    SpecPlaceResolution r = SpecLinkValidator.resolvePlaceAt(refl, place, anchor);
    if (r == null) {
      return null;
    }
    List<String> paths = expand(doc, r.path);
    if (paths.size() != 1) {
      return null;
    }
    String p = paths.get(0);
    String raw = "";
    switch (r.kind) {
      case FORM_FIELD:
        raw = or(doc.formField(p, r.field()));
        break;
      case CONTENT:
        raw = or(doc.content(p));
        break;
      case HEADLINE:
        raw = or(doc.headline(p));
        break;
      case SECTION_ID:
        if (isItem(p)) {
          raw = itemId(doc, p);
        }
        break;
      default:
        break;
    }
    return new ValueAt(p, reviewed(raw), r.field());
  }

  private void crossSummaryField(int order, String pair, String name, SpecDocument doc, String form, FormFieldSpec ff) {
    String raw = doc.formField(form, ff.name);
    if (raw == null) {
      return;
    }
    SpecSummaryOf s = ff.summaryOf;
    Detail det = crossDetail(s);
    if (det == null) {
      return;
    }
    Set<String> known = new HashSet<>();
    for (Element e : det.elements) {
      known.add(e.id);
    }
    Set<String> seen = new HashSet<>();
    for (String id : SpecLinkValidator.linkIds(reviewed(raw))) {
      boolean fresh = seen.add(id);
      if (!known.contains(id) || !fresh) {
        String message =
            known.contains(id)
                ? "form field \"" + ff.name + "\" names " + id + " twice"
                : "form field \"" + ff.name + "\" names " + id + ", which is no element of " + s.detail
                    + " in " + det.name;
        cross(order, SpecSyncCode.CROSS_SUMMARY_MISMATCH, pair,
            place(name, form, ff.name, id),
            place(det.name, listOf(det.elements), null, id),
            message);
      }
    }
    if ("equal".equals(s.relation)) {
      for (Element e : det.elements) {
        if (seen.contains(e.id)) {
          continue;
        }
        cross(order, SpecSyncCode.CROSS_SUMMARY_MISMATCH, pair,
            place(name, form, ff.name, null),
            place(det.name, e.item, null, e.id),
            "the detail element " + e.id + " of " + det.name + " is not named in \"" + ff.name
                + "\" (relation: equal)");
      }
    }
  }

  private String sidOf(String p) {
    SpecResolution res = refl.resolve(p);
    return res != null && res.targetClass != null ? res.targetClass.sectionId : null;
  }

  private static List<String> refersTo(FormFieldSpec ff) {
    return ff.refersTo == null ? List.of() : ff.refersTo;
  }

  private static String head(String target) {
    return target.split("\\.", -1)[0];
  }

  private void crossInverse(int order, String pair, String name, SpecDocument doc, String form, FormFieldSpec ff) {
    String raw = doc.formField(form, ff.name);
    if (raw == null) {
      return;
    }
    String value = reviewed(raw);
    if (value.isEmpty()) {
      return;
    }
    SpecInverseOf inv = ff.inverseOf;
    for (String b : SpecLinkValidator.linkIds(value)) {
      // The document the named entry is read in.
      List<String> registries = new ArrayList<>();
      for (String t : refersTo(ff)) {
        String r = head(t);
        if (!registries.contains(r)) {
          registries.add(r);
        }
      }
      for (String registry : registries) {
        String other = registryDocument(registry);
        if (other == null || other.equals(name)) {
          continue;
        }
        SpecDocument oDoc = set.get(other);
        List<String> targets = new ArrayList<>();
        for (String t : refersTo(ff)) {
          if (head(t).equals(registry)) {
            targets.add(t);
          }
        }
        String bPath = entry(oDoc, targets, b);
        if (bPath == null) {
          continue;
        }
        for (String end : inv.fields) {
          SpecPlaceResolution r = SpecLinkValidator.resolvePlaceAt(refl, end, bPath);
          if (r == null || r.formField == null) {
            continue;
          }
          // This field's entry, named as the other end names it, and read in
          // its own registry document only.
          Set<String> aClasses = new HashSet<>();
          for (String t : refersTo(r.formField)) {
            aClasses.add(head(t));
          }
          String a = nearestItem(form);
          while (a != null && !aClasses.contains(sidOf(a))) {
            int slash = a.lastIndexOf('/');
            a = slash < 0 ? null : nearestItem(a.substring(0, slash));
          }
          if (a == null) {
            continue;
          }
          if (!name.equals(registryDocument(sidOf(a)))) {
            continue;
          }
          String aId = null;
          for (String t : refersTo(r.formField)) {
            String v = identity(doc, a, t);
            if (v != null) {
              aId = v;
              break;
            }
          }
          if (aId == null) {
            continue;
          }
          List<String> ends = expand(oDoc, r.path);
          String fld = r.field();
          boolean namesBack = false;
          for (String p : ends) {
            if (SpecLinkValidator.linkIds(reviewed(or(oDoc.formField(p, fld)))).contains(aId)) {
              namesBack = true;
              break;
            }
          }
          if (!namesBack) {
            String endPath = ends.isEmpty() ? bPath : ends.get(0);
            cross(order, SpecSyncCode.CROSS_INVERSE_MISSING, pair,
                place(name, form, ff.name, b),
                place(other, endPath, r.field(), aId),
                "form field \"" + ff.name + "\" in " + name + " names " + b + ", but " + b + " in "
                    + other + " does not name " + aId + " back (" + String.join(", ", inv.fields) + ")");
          }
        }
      }
    }
  }
}
