package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The link checks of one document ({@code tom_specs_model_rules.md} §9.7):
 * {@link #validateLinks} holds a document's values to the link annotations of
 * the model — derived values to their sources, summaries to their detail lists,
 * each end of a link to the other, the ids named in a text to the link rows, and
 * a {@code @SameAs} copy to its holder. A port of
 * {@code spec_links_validator.dart} (and the TypeScript, JavaScript, Python and
 * Go modules).
 *
 * <p>Values are read in their reviewed state: a value holding pending change
 * marks is read with every mark rejected, and listed as
 * {@code linkValuePending}. A {@code @SummaryOf} naming another document is
 * skipped here; the document set checks it.
 *
 * <p>{@code deriveFields} reads the {@link #fixes} collected beside the findings
 * and the value readers.
 */
public final class SpecLinkValidator {
  private static final Pattern INT_TEXT = Pattern.compile("[+-]?[0-9]+");
  private static final Pattern FLOAT_TEXT =
      Pattern.compile("[+-]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][+-]?[0-9]+)?");
  private static final Pattern HEX_TEXT = Pattern.compile("0[xX][0-9a-fA-F]+");
  /** An id as text names it: letters, digits and inner hyphens. */
  private static final Pattern ID_TOKEN =
      Pattern.compile("[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]|[A-Za-z0-9]");

  /** What {@code deriveFields} would write for each finding, collected beside it. */
  public final List<SpecLinkFix> fixes = new ArrayList<>();
  /** The findings, in the order they were found. */
  public final List<SpecValidationError> errors = new ArrayList<>();
  /** The effective section id per list item path (writable by {@code deriveFields}). */
  public final Map<String, String> itemIds = new HashMap<>();
  /**
   * Whether values are read with their pending marks accepted (the proposal), as
   * {@code deriveFields} does in a document under review, instead of the reviewed
   * state; no value is then listed as pending.
   */
  public final boolean readProposed;

  public final SpecModel model;
  public final SpecDocument doc;
  public final SpecReflection refl;

  private final Set<String> reported = new HashSet<>();
  private final Set<String> pending = new HashSet<>();
  /**
   * The derived values computed so far ({@code path#field} → value), read before
   * the stored value so a derivation from a derived place sees its derived value.
   */
  private Map<String, String> derived = new HashMap<>();
  private final Map<String, Boolean> items = new HashMap<>();
  private Map<String, List<String>> formsByOwner;
  private final Map<String, Map<String, String>> entriesCache = new HashMap<>();
  private Set<String> valued;

  /** The link checker of {@code doc} against {@code model}. */
  public SpecLinkValidator(SpecModel model, SpecDocument doc, boolean readProposed) {
    this.model = model;
    this.doc = doc;
    this.readProposed = readProposed;
    this.refl = new SpecReflection(model);
  }

  /** One section instance of the document. */
  private static final class Instance {
    final String path;
    final SpecClass cls;
    final String root;

    Instance(String path, SpecClass cls, String root) {
      this.path = path;
      this.cls = cls;
      this.root = root;
    }
  }

  /** One scalar derivation: a content member or a form field. */
  private static final class Scalar {
    final String path;
    final String field; // null for content
    final SpecDerivation d;
    final String anchor;
    final String root;
    final FormFieldSpec spec;

    Scalar(String path, String field, SpecDerivation d, String anchor, String root,
        FormFieldSpec spec) {
      this.path = path;
      this.field = field;
      this.d = d;
      this.anchor = anchor;
      this.root = root;
      this.spec = spec;
    }
  }

  /** One value of a subtree: its path and its value. */
  public static final class SubtreeValue {
    public final String path;
    public final String value;

    public SubtreeValue(String path, String value) {
      this.path = path;
      this.value = value;
    }
  }

  // --- the entry points -----------------------------------------------------

  /**
   * Runs the link checks of {@code doc} against {@code model}; the findings
   * sorted by path, then by code (declaration order), then by message.
   */
  public static List<SpecValidationError> validateLinks(SpecModel model, SpecDocument doc) {
    SpecLinkValidator v = new SpecLinkValidator(model, doc, false);
    v.run();
    List<SpecValidationError> out = new ArrayList<>(v.errors);
    out.sort(
        (a, b) -> {
          int c = a.path.compareTo(b.path);
          if (c != 0) {
            return c;
          }
          c = Integer.compare(a.code.ordinal(), b.code.ordinal());
          return c != 0 ? c : a.message.compareTo(b.message);
        });
    return out;
  }

  /** Every concrete path of {@code pattern} in {@code doc}: each {@code <list>-*} segment expanded. */
  public static List<String> expandPattern(SpecDocument doc, String pattern) {
    List<String> paths = new ArrayList<>();
    paths.add("");
    for (String seg : pattern.split("/", -1)) {
      List<String> next = new ArrayList<>();
      for (String p : paths) {
        String base = p.isEmpty() ? seg : p + "/" + seg;
        if (seg.endsWith("-*")) {
          next.addAll(doc.listItems(base.substring(0, base.length() - 2)));
        } else {
          next.add(base);
        }
      }
      paths = next;
    }
    return paths;
  }

  /** {@code place} resolved under {@code anchor}, or {@code null} when it does not resolve. */
  public static SpecPlaceResolution resolvePlaceAt(
      SpecReflection refl, String place, String anchor) {
    SpecPlace p = SpecPlace.tryParse(place);
    if (p == null) {
      return null;
    }
    try {
      return p.resolve(refl, anchor);
    } catch (SpecPlaceException e) {
      return null;
    }
  }

  /**
   * {@code place} resolved for a link annotated at {@code anchor}, as the link
   * checks and the rendition's {@code linked} marker (SOM §11.11) read it: a
   * {@code ./} place beneath the nearest list element of {@code anchor}; any
   * other place inside {@code anchor}'s subtree when it is there, else anywhere
   * beneath the document root {@code root} — a bare id wherever it is reached
   * once, a {@code /} path from the section its first segment names, through the
   * first item {@code doc} holds of a list there ({@code doc} null: such a path
   * does not resolve). {@code null} when it does not resolve.
   */
  public static SpecPlaceResolution resolveLinkPlace(
      SpecReflection refl, SpecDocument doc, String place, String root, String anchor) {
    if (place.startsWith("./")) {
      return resolvePlaceAt(refl, place, anchor);
    }
    // The grammar's own scope first: the subtree of the annotated section.
    if (!anchor.equals(root)) {
      SpecPlaceResolution local = resolvePlaceAt(refl, place, anchor);
      if (local != null) {
        return local;
      }
    }
    int slash = place.indexOf('/');
    if (slash < 0) {
      return resolvePlaceAt(refl, place, root);
    }
    SpecPlaceResolution head = resolvePlaceAt(refl, place.substring(0, slash), root);
    if (head == null) {
      return null;
    }
    String scope = head.kind == SpecPlaceKind.LIST ? head.path + "-*" : head.path;
    // A pattern anchor resolves through its first concrete instance; the rest of
    // the place is relative, so the pattern is rebuilt below.
    List<String> concrete;
    if (doc != null) {
      concrete = expandPattern(doc, scope);
    } else if (!scope.contains("-*")) {
      concrete = Collections.singletonList(scope);
    } else {
      concrete = Collections.emptyList();
    }
    if (concrete.isEmpty()) {
      return null;
    }
    SpecPlaceResolution rest = resolvePlaceAt(refl, place.substring(slash + 1), concrete.get(0));
    if (rest == null) {
      return null;
    }
    return new SpecPlaceResolution(
        rest.place,
        rest.kind,
        scope + tailFrom(rest.path, concrete.get(0).length()),
        rest.className,
        rest.sectionIds,
        rest.formField);
  }

  /** The comma-separated ids of {@code value}, trimmed, empty ones dropped. */
  public static List<String> linkIds(String value) {
    List<String> out = new ArrayList<>();
    for (String s : value.split(",", -1)) {
      String t = s.strip();
      if (!t.isEmpty()) {
        out.add(t);
      }
    }
    return out;
  }

  /**
   * The field a resolved value place names for a write: the form field, the
   * headline's reserved field ({@link SpecReviewAnnotations#K_SPEC_HEADLINE_FIELD}),
   * or {@code null} for content.
   */
  public static String linkFieldOf(SpecPlaceResolution r) {
    switch (r.kind) {
      case FORM_FIELD:
        return r.field();
      case HEADLINE:
        return SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD;
      default:
        return null;
    }
  }

  /** Records one finding, once. */
  public void report(SpecValidationCode code, String path, String message) {
    String key = code.value + " " + path + " " + message;
    if (!reported.add(key)) {
      return;
    }
    errors.add(new SpecValidationError(path, code, message));
  }

  // --- the document's instances ---------------------------------------------

  /** Runs every link check and returns this validator. */
  public SpecLinkValidator run() {
    List<Instance> instances = new ArrayList<>();
    for (SpecRoot root : model.roots) {
      String seg = refl.rootSegment(root);
      if (!populated(seg)) {
        continue;
      }
      SpecClass cls = refl.classNamed(root.type);
      if (cls == null) {
        continue;
      }
      walk(cls, seg, seg, instances, new HashSet<>());
    }
    checkDerivations(instances);
    for (Instance i : instances) {
      for (SpecField f : i.cls.fields) {
        checkSummary(i, f);
        checkExtracts(i, f);
        for (FormFieldSpec ff : f.formFields) {
          String form = formPath(i, f);
          if (ff.inverseOf != null) {
            checkInverse(form, ff);
          }
          if (ff.summaryOf != null) {
            checkFieldSummary(i, form, ff);
          }
        }
      }
    }
    for (SpecRoot root : model.roots) {
      if (populated(refl.rootSegment(root))) {
        checkSameAs(root.type);
      }
    }
    return this;
  }

  private boolean populated(String seg) {
    return under(doc.contentPaths(), seg)
        || under(doc.formPaths(), seg)
        || under(doc.listPaths(), seg)
        || under(doc.headlinePaths(), seg);
  }

  private static boolean under(Set<String> paths, String seg) {
    for (String p : paths) {
      if (p.equals(seg) || p.startsWith(seg + "/")) {
        return true;
      }
    }
    return false;
  }

  private void walk(
      SpecClass cls, String path, String root, List<Instance> out, Set<String> onPath) {
    out.add(new Instance(path, cls, root));
    for (SpecField f : cls.fields) {
      String memberPath = path + "/" + refl.fieldSegment(f);
      if (f.hasAnnotation("Reference")) {
        continue;
      }
      if (f.kind == SpecFieldKind.LIST && f.elementIsComplex) {
        SpecClass el = f.elementType == null ? null : refl.classNamed(f.elementType);
        if (el == null) {
          continue;
        }
        for (String item : doc.listItems(memberPath)) {
          walk(el, item, root, out, new HashSet<>());
        }
      } else if (f.kind == SpecFieldKind.COMPLEX || f.kind == SpecFieldKind.SECTION) {
        SpecClass child = SpecPlaceWalk.classOf(refl, f);
        if (child == null || onPath.contains(child.name)) {
          continue;
        }
        Set<String> next = new HashSet<>(onPath);
        next.add(cls.name);
        walk(child, memberPath, root, out, next);
      }
    }
  }

  private String formPath(Instance i, SpecField f) {
    return i.path + "/" + refl.fieldSegment(f);
  }

  // --- reading values -------------------------------------------------------

  /** The reviewed reading of a raw value; a value with pending marks is listed once. */
  private String reviewed(String raw, String path, String what) {
    if (raw == null) {
      return "";
    }
    if (readProposed) {
      return SpecReviewAnnotations.applyInlineMarksText(raw, true).strip();
    }
    String rejected = SpecReviewAnnotations.applyInlineMarksText(raw, false);
    String key = path + " " + what;
    if (!SpecReviewAnnotations.applyInlineMarksText(raw, true).equals(rejected)
        && pending.add(key)) {
      report(
          SpecValidationCode.LINK_VALUE_PENDING,
          path,
          what + " holds pending change marks; it is read with every mark rejected");
    }
    return rejected.strip();
  }

  /** The value of form field {@code field} at {@code path} (derived first, then reviewed). */
  public String formValue(String path, String field) {
    String d = derived.get(path + "#" + field);
    if (d != null) {
      return d;
    }
    return reviewed(doc.formField(path, field), path, "form field \"" + field + "\"");
  }

  /** The content value at {@code path} (derived first, then reviewed). */
  public String contentValue(String path) {
    String d = derived.get(path + "#");
    if (d != null) {
      return d;
    }
    return reviewed(doc.content(path), path, "the content");
  }

  /** The headline at {@code path}, reviewed. */
  public String headlineValue(String path) {
    return reviewed(doc.headline(path), path, "the headline");
  }

  /** The effective section id of the list item at {@code itemPath}. */
  public String itemId(String itemPath) {
    String id = itemIds.get(itemPath);
    if (id != null) {
      return id;
    }
    id = computeItemId(itemPath);
    itemIds.put(itemPath, id);
    return id;
  }

  private String computeItemId(String itemPath) {
    String stored = doc.itemSectionId(itemPath);
    if (stored != null) {
      return stored;
    }
    String lst = itemPath.substring(0, itemPath.lastIndexOf('-'));
    List<String> its = doc.listItems(lst);
    int position = its.indexOf(itemPath) + 1;
    String pattern = null;
    String stem = lst.substring(lst.lastIndexOf('/') + 1);
    SpecResolution res = refl.resolve(lst);
    if (res != null && res.field != null) {
      pattern = res.field.sectionIdPattern;
      stem = res.field.name;
    }
    return SpecSectionId.effectiveListItemSectionId(null, pattern, position, stem);
  }

  /** Whether {@code path} is a complex list item. */
  public boolean isItem(String path) {
    Boolean hit = items.get(path);
    if (hit != null) {
      return hit;
    }
    SpecResolution r = refl.resolve(path);
    boolean is = r != null && r.kind == SpecNodeKind.LIST_ITEM_COMPLEX;
    items.put(path, is);
    return is;
  }

  /** The value a resolved place holds at its concrete {@code path}. */
  public String value(SpecPlaceResolution r, String path) {
    switch (r.kind) {
      case FORM_FIELD:
        return formValue(path, r.field());
      case CONTENT:
        return contentValue(path);
      case HEADLINE:
        return headlineValue(path);
      case SECTION_ID:
        return isItem(path) ? itemId(path) : "";
      default:
        return "";
    }
  }

  /** Every concrete path of a resolved pattern. */
  public List<String> expand(String pattern) {
    return expandPattern(doc, pattern);
  }

  /** {@code place} resolved under {@code anchor}, or {@code null} when it does not resolve. */
  public SpecPlaceResolution at(String place, String anchor) {
    return resolvePlaceAt(refl, place, anchor);
  }

  /** {@code place} resolved for a link annotated at {@code anchor} ({@link #resolveLinkPlace}). */
  private SpecPlaceResolution global(String place, String root, String anchor) {
    return resolveLinkPlace(refl, doc, place, root, anchor);
  }

  /** The values a row's own forms ({@code <row>/<member>}) hold in {@code field}. */
  public List<String> ownValues(String row, String field) {
    if (formsByOwner == null) {
      formsByOwner = new HashMap<>();
      for (String p : new TreeSet<>(doc.formPaths())) {
        int slash = p.lastIndexOf('/');
        if (slash > 0) {
          formsByOwner.computeIfAbsent(p.substring(0, slash), k -> new ArrayList<>()).add(p);
        }
      }
    }
    List<String> out = new ArrayList<>();
    for (String p : formsByOwner.getOrDefault(row, Collections.emptyList())) {
      if (doc.formField(p, field) != null) {
        out.add(formValue(p, field));
      }
    }
    return out;
  }

  private boolean passes(String where, String row) {
    if (!present(where)) {
      return true;
    }
    SpecPlaceFilter f = SpecPlaceFilter.tryParse(where);
    if (f == null || f.field == null) {
      return true;
    }
    return f.matches(ownValues(row, f.field));
  }

  /** The nearest list item at or above {@code path} (itself included), {@code null} when there is none. */
  public String nearestItem(String path) {
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

  private static boolean present(String s) {
    return s != null && !s.isEmpty();
  }

  // --- @DerivedFrom and derivedFrom: ----------------------------------------

  private void checkDerivations(List<Instance> instances) {
    List<Scalar> scalar = new ArrayList<>();
    for (Instance i : instances) {
      for (SpecField f : i.cls.fields) {
        SpecDerivation d = f.derivedFrom();
        String memberPath = formPath(i, f);
        if (d != null) {
          if (f.kind == SpecFieldKind.LIST) {
            checkDerivedList(i, memberPath, d);
          } else if (f.kind == SpecFieldKind.CONTENT) {
            scalar.add(new Scalar(memberPath, null, d, i.path, i.root, null));
          }
        }
        for (FormFieldSpec ff : f.formFields) {
          if (ff.derivedFrom == null) {
            continue;
          }
          scalar.add(new Scalar(memberPath, ff.name, ff.derivedFrom, i.path, i.root, ff));
        }
      }
    }
    // Dependency order: every derivation is recomputed from the values the ones
    // before it gave, until nothing moves. DERIVE-ACYCLIC bounds the rounds by
    // the number of derivations. An undecidable derivation is absent (null).
    Map<Integer, String> expected = new HashMap<>();
    for (int round = 0; round <= scalar.size(); round++) {
      boolean moved = false;
      for (int k = 0; k < scalar.size(); k++) {
        Scalar t = scalar.get(k);
        String value = derive(t.d, t.anchor, t.root, t.spec, t.path);
        if (!Objects.equals(expected.get(k), value)) {
          if (value == null) {
            expected.remove(k);
          } else {
            expected.put(k, value);
            derived.put(t.path + "#" + (t.field == null ? "" : t.field), value);
          }
          moved = true;
        }
      }
      if (!moved) {
        break;
      }
    }
    derived = new HashMap<>();
    for (int k = 0; k < scalar.size(); k++) {
      Scalar t = scalar.get(k);
      String want = expected.get(k);
      if (want == null) {
        continue;
      }
      String have = t.field == null ? contentValue(t.path) : formValue(t.path, t.field);
      boolean same = sameValue(have, want, t.spec);
      if (!same) {
        fixes.add(SpecLinkFix.ofSet(2, t.path, t.field, want));
      }
      if (have.isEmpty()) {
        continue; // not derived yet: deriveFields writes it
      }
      if (!same) {
        String what = t.field == null ? "the content" : "form field \"" + t.field + "\"";
        report(
            SpecValidationCode.DERIVED_VALUE_MISMATCH,
            t.path,
            what + " is derived (" + t.d.kind + " of " + t.d.source + ") as \"" + want
                + "\", but holds \"" + have + "\"");
      }
    }
  }

  /** Dart's {@code num.tryParse} (decimal forms; surrounding whitespace allowed), or {@code null}. */
  private static Double numTryParse(String text) {
    String t = text.strip();
    if (INT_TEXT.matcher(t).matches() || FLOAT_TEXT.matcher(t).matches()) {
      try {
        return Double.parseDouble(t);
      } catch (NumberFormatException e) {
        return null;
      }
    }
    if (HEX_TEXT.matcher(t).matches()) {
      try {
        return (double) Long.parseLong(t.substring(2), 16);
      } catch (NumberFormatException e) {
        return null;
      }
    }
    switch (t) {
      case "NaN":
        return Double.NaN;
      case "Infinity":
        return Double.POSITIVE_INFINITY;
      case "-Infinity":
        return Double.NEGATIVE_INFINITY;
      default:
        return null;
    }
  }

  /**
   * Whether two values agree: as id sets for a multi-valued reference, as
   * numbers for a numeric field, else as text with trailing whitespace ignored.
   */
  private static boolean sameValue(String a, String b, FormFieldSpec spec) {
    if (spec != null && spec.multiple && !spec.refersTo.isEmpty()) {
      return new HashSet<>(linkIds(a)).equals(new HashSet<>(linkIds(b)));
    }
    if (spec != null
        && ("int".equals(spec.type) || "double".equals(spec.type) || "num".equals(spec.type))) {
      Double x = numTryParse(a);
      Double y = numTryParse(b);
      if (x != null && y != null) {
        return x.doubleValue() == y.doubleValue();
      }
    }
    return normalized(a).equals(normalized(b));
  }

  private static String normalized(String s) {
    String[] lines = s.split("\n", -1);
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].stripTrailing();
    }
    return String.join("\n", lines).strip();
  }

  /**
   * The rows a {@code rows} / {@code lookup} derivation reads, in document
   * order; {@code null} when the document's root does not reach the source
   * (undecidable here).
   */
  private List<String> rows(SpecDerivation d, String anchor, String root) {
    SpecPlaceResolution src = global(d.source, root, anchor);
    if (src == null) {
      return null;
    }
    boolean keyBy = present(d.key) && present(d.by);
    String byValue = keyBy ? placeValue(d.by, anchor) : "";
    List<String> out = new ArrayList<>();
    for (String row : expand(src.path)) {
      if (!passes(d.where, row)) {
        continue;
      }
      if (keyBy && !placeValue(d.key, row).equals(byValue)) {
        continue;
      }
      out.add(row);
    }
    return out;
  }

  /** The value of {@code place} resolved under the concrete {@code anchor}. */
  public String placeValue(String place, String anchor) {
    SpecPlaceResolution r = at(place, anchor);
    if (r == null) {
      return "";
    }
    List<String> paths = expand(r.path);
    if (paths.size() != 1) {
      return "";
    }
    return value(r, paths.get(0));
  }

  private static String joinNonEmpty(List<String> values, String sep) {
    List<String> kept = new ArrayList<>();
    for (String s : values) {
      if (!s.isEmpty()) {
        kept.add(s);
      }
    }
    return String.join(sep, kept);
  }

  /** The value a scalar derivation gives, {@code null} when undecidable. */
  private String derive(
      SpecDerivation d, String anchor, String root, FormFieldSpec spec, String targetPath) {
    switch (d.kind) {
      case "copy":
        {
          SpecPlaceResolution src = global(d.source, root, anchor);
          if (src == null) {
            return null;
          }
          List<String> paths = expand(src.path);
          if (paths.size() != 1) {
            return null;
          }
          return value(src, paths.get(0));
        }
      case "rows":
        {
          List<String> rows = rows(d, anchor, root);
          if (rows == null) {
            return null;
          }
          if (spec != null && spec.multiple) {
            List<String> out = new ArrayList<>();
            for (String row : rows) {
              for (String t : d.take) {
                out.addAll(linkIds(placeValue(t, row)));
              }
            }
            return String.join(", ", out);
          }
          List<String> lines = new ArrayList<>();
          for (String row : rows) {
            List<String> vals = new ArrayList<>();
            for (String t : d.take) {
              vals.add(placeValue(t, row));
            }
            String line = joinNonEmpty(vals, " — ");
            if (!line.isEmpty()) {
              lines.add(line);
            }
          }
          return String.join("\n", lines);
        }
      case "lookup":
        {
          List<String> rows = rows(d, anchor, root);
          if (rows == null) {
            return null;
          }
          boolean keyBy = present(d.key) && present(d.by);
          if (keyBy && rows.size() != 1) {
            report(
                SpecValidationCode.DERIVED_LOOKUP_MISS,
                targetPath,
                "the lookup in " + d.source + " by " + d.key + " = \"" + placeValue(d.by, anchor)
                    + "\" finds " + rows.size() + " rows, not one");
            return null;
          }
          if (rows.isEmpty()) {
            return "";
          }
          String row = rows.get(rows.size() - 1);
          List<String> vals = new ArrayList<>();
          for (String t : d.take) {
            vals.add(placeValue(t, row));
          }
          return joinNonEmpty(vals, " — ");
        }
      default:
        return null;
    }
  }

  /** Checks a {@code @DerivedFrom.rows} with {@code map} on a list: one element per row. */
  private void checkDerivedList(Instance i, String listPath, SpecDerivation d) {
    if (!d.kind.equals("rows") || d.map.isEmpty()) {
      return;
    }
    List<String> elements = doc.listItems(listPath);
    List<String> rows = rows(d, i.path, i.root);
    if (rows == null) {
      return; // the source is not in this document
    }
    List<Map<String, String>> wanted = new ArrayList<>();
    for (String row : rows) {
      Map<String, String> t = new LinkedHashMap<>();
      for (Map.Entry<String, String> e : d.map.entrySet()) {
        t.put(e.getKey(), placeValue(e.getValue(), row));
      }
      wanted.add(t);
    }
    List<Map<String, String>> current = new ArrayList<>();
    for (String el : elements) {
      Map<String, String> t = new LinkedHashMap<>();
      for (String k : d.map.keySet()) {
        t.put(k, placeValue(k, el));
      }
      current.add(t);
    }
    if (!sortedTupleKeys(wanted, d).equals(sortedTupleKeys(current, d))) {
      fixes.add(SpecLinkFix.ofList(listPath, wanted, new ArrayList<>(d.map.keySet())));
    }
    if (elements.isEmpty()) {
      return; // not derived yet
    }
    List<String> want = new ArrayList<>();
    for (String row : rows) {
      List<String> parts = new ArrayList<>();
      for (String v : d.map.values()) {
        parts.add(placeValue(v, row));
      }
      want.add(String.join(" | ", parts));
    }
    List<String> have = new ArrayList<>();
    for (String el : elements) {
      List<String> parts = new ArrayList<>();
      for (String k : d.map.keySet()) {
        parts.add(placeValue(k, el));
      }
      have.add(String.join(" | ", parts));
    }
    Collections.sort(want);
    Collections.sort(have);
    if (!want.equals(have)) {
      report(
          SpecValidationCode.DERIVED_VALUE_MISMATCH,
          listPath,
          "the list is derived (rows of " + d.source + ") as [" + String.join("; ", want)
              + "], but holds [" + String.join("; ", have) + "]");
    }
  }

  private static List<String> sortedTupleKeys(List<Map<String, String>> ts, SpecDerivation d) {
    List<String> out = new ArrayList<>();
    for (Map<String, String> t : ts) {
      List<String> parts = new ArrayList<>();
      for (String k : d.map.keySet()) {
        String v = t.get(k);
        parts.add(v == null ? "null" : v);
      }
      out.add(String.join(" | ", parts));
    }
    Collections.sort(out);
    return out;
  }

  /** {@code s} from index {@code n} on, {@code ""} when it is shorter. */
  private static String tailFrom(String s, int n) {
    return n >= s.length() ? "" : s.substring(n);
  }

  // --- @SummaryOf and summaryOf: --------------------------------------------

  /** One detail element: its item path and id. */
  private static final class Detail {
    final String item;
    final String id;

    Detail(String item, String id) {
      this.item = item;
      this.id = id;
    }
  }

  /** The detail elements of a summary, in document order; {@code null} when the list does not resolve. */
  private List<Detail> detailElements(SpecSummaryOf s, String root) {
    SpecPlaceResolution r = global(s.detail, root, root);
    if (r == null || r.kind != SpecPlaceKind.LIST) {
      return null;
    }
    List<Detail> out = new ArrayList<>();
    Set<String> seen = new HashSet<>();
    for (String lst : expand(r.path)) {
      for (String item : doc.listItems(lst)) {
        if (seen.add(item)) {
          out.add(new Detail(item, itemId(item)));
        }
      }
    }
    return out;
  }

  private void checkSummary(Instance i, SpecField f) {
    SpecSummaryOf s = f.summaryOf();
    if (s == null || present(s.document) || f.kind != SpecFieldKind.LIST) {
      return;
    }
    List<Detail> detail = detailElements(s, i.root);
    if (detail == null) {
      return;
    }
    Map<String, String> byId = new HashMap<>();
    for (Detail d : detail) {
      byId.put(d.id, d.item);
    }
    Map<String, String> named = new HashMap<>();
    for (String el : doc.listItems(formPath(i, f))) {
      List<String> ids =
          present(s.match) ? linkIds(placeValue(s.match, el)) : List.of(itemId(el));
      for (String id : ids) {
        String target = byId.get(id);
        if (target == null) {
          report(
              SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
              el,
              "the summary row names " + id + ", which is no element of " + s.detail);
          continue;
        }
        String first = named.get(id);
        if (first != null) {
          report(
              SpecValidationCode.SUMMARY_DUPLICATE,
              el,
              "the summary row names " + id + ", which " + first + " names already");
          continue;
        }
        named.put(id, el);
        checkRepeats(s, el, target);
      }
    }
    if (s.relation.equals("equal")) {
      for (Detail d : detail) {
        if (!named.containsKey(d.id)) {
          report(
              SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
              d.item,
              "the detail element " + d.id + " is named by no row of the summary "
                  + formPath(i, f) + " (relation: equal)");
        }
      }
    }
  }

  /** Checks that the values a summary row repeats agree with its detail element's. */
  private void checkRepeats(SpecSummaryOf s, String row, String detail) {
    for (Map.Entry<String, String> rep : s.repeats.entrySet()) {
      String mineAt = rep.getKey();
      String theirsAt = rep.getValue();
      SpecPlaceResolution mine = at(mineAt, row);
      SpecPlaceResolution theirs = at(theirsAt, detail);
      if (mine == null || theirs == null) {
        continue;
      }
      List<String> mp = expand(mine.path);
      List<String> tp = expand(theirs.path);
      if (mp.size() != 1 || tp.size() != 1) {
        continue;
      }
      String have = value(mine, mp.get(0));
      String want = value(theirs, tp.get(0));
      if (!have.equals(want)) {
        fixes.add(SpecLinkFix.ofSet(2, mp.get(0), linkFieldOf(mine), want));
      }
      if (have.isEmpty()) {
        continue; // not repeated yet: deriveFields writes it
      }
      if (!have.equals(want)) {
        report(
            SpecValidationCode.DERIVED_VALUE_MISMATCH,
            mp.get(0),
            mineAt + " repeats " + theirsAt + " of " + detail + " as \"" + have
                + "\", but the detail element holds \"" + want + "\"");
      }
    }
  }

  private void checkFieldSummary(Instance i, String form, FormFieldSpec ff) {
    SpecSummaryOf s = ff.summaryOf;
    if (s == null || present(s.document)) {
      return;
    }
    if (doc.formField(form, ff.name) == null) {
      return;
    }
    List<Detail> detail = detailElements(s, i.root);
    if (detail == null) {
      return;
    }
    Set<String> known = new HashSet<>();
    for (Detail d : detail) {
      known.add(d.id);
    }
    Set<String> seen = new HashSet<>();
    for (String id : linkIds(formValue(form, ff.name))) {
      if (!known.contains(id)) {
        report(
            SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
            form,
            "form field \"" + ff.name + "\" names " + id + ", which is no element of " + s.detail);
      } else if (seen.contains(id)) {
        report(
            SpecValidationCode.SUMMARY_DUPLICATE,
            form,
            "form field \"" + ff.name + "\" names " + id + " twice");
      } else {
        seen.add(id);
      }
    }
    if (s.relation.equals("equal")) {
      for (Detail d : detail) {
        if (!seen.contains(d.id)) {
          report(
              SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
              d.item,
              "the detail element " + d.id + " is not named in \"" + ff.name + "\" of " + form
                  + " (relation: equal)");
        }
      }
    }
  }

  // --- inverseOf: -----------------------------------------------------------

  /**
   * The entries a reference field names, by its {@code refersTo} registries: id
   * → item path. An entry of {@code <X>.@sectionId} is named by its section id,
   * one of {@code <X>.<field>} by the value its own forms hold in that field.
   */
  public Map<String, String> entries(List<String> refersTo) {
    String key = String.join(",", refersTo);
    Map<String, String> hit = entriesCache.get(key);
    if (hit != null) {
      return hit;
    }
    Map<String, String> out = new LinkedHashMap<>();
    for (String lst : new TreeSet<>(doc.listPaths())) {
      for (String item : doc.listItems(lst)) {
        SpecResolution r = refl.resolve(item);
        if (r == null || r.targetClass == null) {
          continue;
        }
        String id = r.targetClass.sectionId;
        for (String t : refersTo) {
          if (!t.split("\\.", -1)[0].equals(id)) {
            continue;
          }
          String name = identity(item, t);
          if (name == null || name.isEmpty()) {
            continue;
          }
          out.putIfAbsent(name, item);
        }
      }
    }
    entriesCache.put(key, out);
    return out;
  }

  /**
   * How the registry key {@code target} ({@code <X>.@sectionId} or
   * {@code <X>.<field>}) names the entry at {@code item}; {@code null} when it
   * does not.
   */
  public String identity(String item, String target) {
    String name = target.substring(target.indexOf('.') + 1);
    if (name.equals(SpecSectionId.K_SECTION_ID_SLOT)) {
      return itemId(item);
    }
    List<String> values = ownValues(item, name);
    return values.isEmpty() ? null : values.get(0);
  }

  /** The nearest item at or above {@code path} whose class is one of {@code classes}, or {@code null}. */
  private String owner(String path, Set<String> classes) {
    String p = nearestItem(path);
    while (p != null) {
      SpecResolution r = refl.resolve(p);
      if (r != null && r.targetClass != null && classes.contains(r.targetClass.sectionId)) {
        return p;
      }
      int slash = p.lastIndexOf('/');
      if (slash < 0) {
        return null;
      }
      p = nearestItem(p.substring(0, slash));
    }
    return null;
  }

  private static Set<String> registryClasses(List<String> refersTo) {
    Set<String> out = new HashSet<>();
    for (String t : refersTo) {
      out.add(t.split("\\.", -1)[0]);
    }
    return out;
  }

  private String firstIdentity(String owner, List<String> refersTo) {
    for (String t : refersTo) {
      String id = identity(owner, t);
      if (id != null) {
        return id;
      }
    }
    return null;
  }

  private void checkInverse(String form, FormFieldSpec ff) {
    if (doc.formField(form, ff.name) == null) {
      return;
    }
    String value = formValue(form, ff.name);
    if (value.isEmpty()) {
      return;
    }
    SpecInverseOf inv = ff.inverseOf;
    Map<String, String> entries = entries(ff.refersTo);
    if (inv.symmetric()) {
      checkSymmetric(form, ff, inv, value, entries);
      return;
    }
    // The entry this field belongs to, as the other ends name it.
    for (String b : linkIds(value)) {
      String bPath = entries.get(b);
      if (bPath == null) {
        continue; // a registry this document does not hold
      }
      boolean resolved = false;
      boolean namesBack = false;
      String aId = null;
      String writablePath = null;
      String writableField = null;
      for (String end : inv.fields) {
        SpecPlaceResolution r = at(end, bPath);
        if (r == null || r.formField == null) {
          continue;
        }
        String owner = owner(form, registryClasses(r.formField.refersTo));
        if (owner == null) {
          continue;
        }
        if (present(inv.where) && !passes(inv.where, owner)) {
          return;
        }
        aId = firstIdentity(owner, r.formField.refersTo);
        if (aId == null) {
          continue;
        }
        resolved = true;
        List<String> ends = expand(r.path);
        if (!ends.isEmpty() && writablePath == null) {
          writablePath = ends.get(0);
          writableField = r.field();
        }
        for (String p : ends) {
          if (linkIds(formValue(p, r.field())).contains(aId)) {
            namesBack = true;
          }
        }
      }
      if (resolved && !namesBack && writablePath != null && aId != null) {
        fixes.add(SpecLinkFix.ofAppend(writablePath, writableField, aId));
      }
      if (resolved && !namesBack) {
        report(
            SpecValidationCode.INVERSE_MISSING,
            form,
            "form field \"" + ff.name + "\" names " + b + ", but " + b + " does not name "
                + (aId == null ? "" : aId) + " back (" + String.join(", ", inv.fields) + ")");
      }
    }
  }

  private void checkSymmetric(
      String form,
      FormFieldSpec ff,
      SpecInverseOf inv,
      String value,
      Map<String, String> entries) {
    String row = nearestItem(form);
    if (row == null || !passes(inv.where, row)) {
      return;
    }
    String a = owner(row.substring(0, row.lastIndexOf('/')), registryClasses(ff.refersTo));
    if (a == null) {
      return;
    }
    String aId = firstIdentity(a, ff.refersTo);
    if (aId == null) {
      return;
    }
    String filterField = null;
    if (present(inv.where)) {
      SpecPlaceFilter filt = SpecPlaceFilter.tryParse(inv.where);
      if (filt != null) {
        filterField = filt.field;
      }
    }
    Set<String> whereValues = new HashSet<>();
    if (filterField != null) {
      whereValues.addAll(ownValues(row, filterField));
    }

    // The same place beneath the named entry, every row of it.
    String[] segs = form.substring(a.length()).split("/", -1);
    for (int k = 0; k < segs.length; k++) {
      segs[k] = generalise(segs[k]);
    }
    String rel = String.join("/", segs);
    for (String b : linkIds(value)) {
      String bPath = entries.get(b);
      if (bPath == null || bPath.equals(a)) {
        continue;
      }
      boolean counterpart = false;
      for (String p : expand(bPath + rel)) {
        if (isCounterpart(p, inv, filterField, whereValues, ff, aId)) {
          counterpart = true;
          break;
        }
      }
      if (counterpart) {
        continue;
      }
      int star = rel.indexOf("-*");
      if (star > 0) {
        String lst = bPath + rel.substring(0, star);
        String below = star + 3 <= rel.length() ? rel.substring(star + 3) : "";
        Map<String, String> values = new LinkedHashMap<>();
        values.put(below + "#" + ff.name, aId);
        if (filterField != null) {
          for (String p : ownForms(row)) {
            if (doc.formField(p, filterField) != null) {
              values.put(
                  p.substring(row.length() + 1) + "#" + filterField, formValue(p, filterField));
            }
          }
        }
        fixes.add(SpecLinkFix.ofAddRow(1, lst, values));
      }
      String suffix = present(inv.where) ? " (" + inv.where + ")" : "";
      report(
          SpecValidationCode.INVERSE_MISSING,
          form,
          "the row names " + b + ", but " + b + " holds no row naming " + aId + " back" + suffix);
    }
  }

  private boolean isCounterpart(
      String p,
      SpecInverseOf inv,
      String filterField,
      Set<String> whereValues,
      FormFieldSpec ff,
      String aId) {
    String r = nearestItem(p);
    if (r == null || !passes(inv.where, r)) {
      return false;
    }
    if (filterField != null) {
      Set<String> own = new HashSet<>(ownValues(r, filterField));
      if (!own.containsAll(whereValues)) {
        return false;
      }
    }
    return linkIds(formValue(p, ff.name)).contains(aId);
  }

  /** A list-item segment written as its pattern ({@code X-LST-3} → {@code X-LST-*}). */
  private static String generalise(String s) {
    int dash = s.lastIndexOf('-');
    if (dash > 0 && INT_TEXT.matcher(s.substring(dash + 1).strip()).matches()) {
      return s.substring(0, dash) + "-*";
    }
    return s;
  }

  // --- @ExtractsLinks and the link rows -------------------------------------

  private void checkExtracts(Instance i, SpecField f) {
    List<SpecExtractsLinks> all = f.extractsLinks();
    if (all.isEmpty() || f.kind != SpecFieldKind.LIST) {
      return;
    }
    String listPath = formPath(i, f);
    List<String> rows = doc.listItems(listPath);
    String element = nearestItem(i.path);
    String own = element == null ? null : itemId(element);

    // A link row holding no value at all (what accepting the marked removal of a
    // row leaves) is removed.
    for (String row : rows) {
      if (!holdsValue(row)) {
        fixes.add(SpecLinkFix.ofRemoveRow(row, true));
      }
    }

    // The ids each row names, and its type (the values `set` writes).
    Set<String> setKeySet = new TreeSet<>();
    for (SpecExtractsLinks e : all) {
      setKeySet.addAll(e.set.keySet());
    }
    List<String> setKeys = new ArrayList<>(setKeySet);
    Map<String, List<String>> named = new HashMap<>();
    Map<String, String> seen = new HashMap<>();
    Set<String> rowed = new HashSet<>();
    for (String row : rows) {
      List<String> unique = new ArrayList<>();
      for (SpecExtractsLinks e : all) {
        SpecPlaceResolution r = at(e.ref, row);
        if (r == null) {
          continue;
        }
        for (String p : expand(r.path)) {
          for (String id : linkIds(value(r, p))) {
            if (!unique.contains(id)) {
              unique.add(id);
            }
          }
        }
      }
      named.put(row, unique);
      List<String> types = new ArrayList<>();
      for (String k : setKeys) {
        types.add(placeValue(k, row));
      }
      String type = String.join(" | ", types);
      for (String id : unique) {
        rowed.add(id);
        String key = id + " // " + type;
        String first = seen.get(key);
        if (first != null) {
          report(
              SpecValidationCode.DUPLICATE_LINK_ROW,
              row,
              "the row names " + id + " with the type \"" + type + "\", as " + first + " does");
        } else {
          seen.put(key, row);
        }
      }
    }

    for (SpecExtractsLinks e : all) {
      FormFieldSpec refSpec = null;
      if (rows.isEmpty()) {
        refSpec = refSpecFromModel(f, e.ref);
      } else {
        SpecPlaceResolution r = at(e.ref, rows.get(0));
        if (r != null) {
          refSpec = r.formField;
        }
      }
      if (refSpec == null) {
        continue;
      }
      Set<String> registry = entries(refSpec.refersTo).keySet();
      List<String> found = new ArrayList<>();
      for (String place : e.from) {
        String p = place.startsWith("./") ? place : "./" + place;
        SpecPlaceResolution r = at(p, i.path);
        if (r == null) {
          continue;
        }
        for (String path : expand(r.path)) {
          for (String id : idsIn(value(r, path), registry)) {
            boolean excluded = own != null && id.equals(own);
            if (!excluded && !found.contains(id)) {
              found.add(id);
            }
          }
        }
      }
      for (String id : found) {
        if (rowed.contains(id)) {
          continue;
        }
        if (e.mode.equals("generate")) {
          Map<String, String> values = new LinkedHashMap<>();
          List<String[]> writes = new ArrayList<>();
          writes.add(new String[] {e.ref, id});
          for (Map.Entry<String, String> w : e.set.entrySet()) {
            writes.add(new String[] {w.getKey(), w.getValue()});
          }
          String first = listPath + "-0";
          for (String[] w : writes) {
            SpecPlaceResolution r = at(w[0], first);
            if (r == null || r.formField == null) {
              continue;
            }
            String rel = r.path.substring(first.length() + 1);
            values.put(rel + "#" + r.field(), w[1]);
          }
          fixes.add(SpecLinkFix.ofAddRow(1, listPath, values));
        }
        String warn = e.mode.equals("warn") ? " (warn: the agent adds it)" : "";
        report(
            SpecValidationCode.EXTRACTED_LINK_MISSING,
            listPath,
            id + " is named in " + String.join(" / ", e.from) + " but has no row" + warn);
      }
    }
    // A generated row: every `set` value of a generate-mode use matches.
    for (SpecExtractsLinks e : all) {
      if (!e.mode.equals("generate")) {
        continue;
      }
      Set<String> mine = new HashSet<>();
      for (String place : e.from) {
        String p = place.startsWith("./") ? place : "./" + place;
        SpecPlaceResolution r = at(p, i.path);
        if (r == null) {
          continue;
        }
        Set<String> registry = new HashSet<>();
        if (!rows.isEmpty()) {
          SpecPlaceResolution refR = at(e.ref, rows.get(0));
          if (refR != null && refR.formField != null) {
            registry.addAll(entries(refR.formField.refersTo).keySet());
          }
        }
        for (String path : expand(r.path)) {
          mine.addAll(idsIn(value(r, path), registry));
        }
      }
      for (String row : rows) {
        boolean generated = true;
        for (Map.Entry<String, String> s : e.set.entrySet()) {
          if (!placeValue(s.getKey(), row).equals(s.getValue())) {
            generated = false;
            break;
          }
        }
        if (!generated) {
          continue;
        }
        for (String id : named.get(row)) {
          if (!mine.contains(id)) {
            fixes.add(SpecLinkFix.ofRemoveRow(row, false));
            report(
                SpecValidationCode.EXTRACTED_LINK_STALE,
                row,
                "the generated row names " + id + ", which " + String.join(" / ", e.from)
                    + " no longer names");
          }
        }
      }
    }
  }

  private FormFieldSpec refSpecFromModel(SpecField lst, String ref) {
    SpecClass el = lst.elementType == null ? null : refl.classNamed(lst.elementType);
    if (el == null) {
      return null;
    }
    int dot = ref.indexOf('.');
    if (dot < 0) {
      return null;
    }
    String id = ref.substring(0, dot);
    String name = ref.substring(dot + 1);
    for (SpecField f : el.fields) {
      String fid = "content".equals(f.name) ? el.sectionId : f.sectionId;
      if (!id.equals(fid)) {
        continue;
      }
      for (FormFieldSpec ff : f.formFields) {
        if (ff.name.equals(name)) {
          return ff;
        }
      }
    }
    return null;
  }

  /**
   * The ids of {@code registry} named in {@code text}, each matched exactly (not
   * as a part of a longer id), in order of first appearance.
   */
  private static List<String> idsIn(String text, Set<String> registry) {
    List<String> out = new ArrayList<>();
    Matcher m = ID_TOKEN.matcher(text);
    while (m.find()) {
      String id = m.group();
      if (registry.contains(id) && !out.contains(id)) {
        out.add(id);
      }
    }
    return out;
  }

  // --- @SameAs --------------------------------------------------------------

  private void checkSameAs(String rootType) {
    for (SpecSameAsBinding b : SpecPlace.sameAsBindings(refl, rootType)) {
      if (b.holderPath == null) {
        continue;
      }
      List<String> copies = expand(b.copyPath);
      List<String> holders = expand(b.holderPath);
      if (copies.size() != holders.size()) {
        continue;
      }
      for (int k = 0; k < copies.size(); k++) {
        if (compareSubtrees(copies.get(k), holders.get(k))) {
          fixes.add(SpecLinkFix.ofCopy(copies.get(k), holders.get(k)));
        }
      }
    }
  }

  /**
   * Every value beneath {@code root} (itself included), keyed by its path
   * relative to {@code root} with list items written by their section id, so two
   * subtrees compare element by element.
   */
  public Map<String, SubtreeValue> subtree(String root) {
    Map<String, SubtreeValue> out = new TreeMap<>();
    for (String p : new TreeSet<>(doc.contentPaths())) {
      if (inside(p, root)) {
        putValue(out, "c:" + subtreeKey(root, p), p, contentValue(p));
      }
    }
    for (String p : new TreeSet<>(doc.formPaths())) {
      if (!inside(p, root)) {
        continue;
      }
      for (String name : new TreeSet<>(doc.formFieldNames(p))) {
        putValue(out, "f:" + subtreeKey(root, p) + "#" + name, p, formValue(p, name));
      }
    }
    for (String p : new TreeSet<>(doc.headlinePaths())) {
      if (inside(p, root)) {
        putValue(out, "h:" + subtreeKey(root, p), p, headlineValue(p));
      }
    }
    for (String lst : new TreeSet<>(doc.listPaths())) {
      if (!inside(lst, root)) {
        continue;
      }
      for (String item : doc.listItems(lst)) {
        putValue(out, "i:" + subtreeKey(root, item), item, itemId(item));
      }
    }
    return out;
  }

  private static boolean inside(String p, String root) {
    return p.equals(root) || p.startsWith(root + "/");
  }

  private static void putValue(Map<String, SubtreeValue> out, String k, String path, String v) {
    if (!v.isEmpty()) {
      out.put(k, new SubtreeValue(path, v));
    } else {
      out.remove(k);
    }
  }

  private String subtreeKey(String root, String path) {
    String rel = path.equals(root) ? "" : path.substring(root.length() + 1);
    if (rel.isEmpty()) {
      return "";
    }
    List<String> out = new ArrayList<>();
    String at = root;
    for (String seg : rel.split("/", -1)) {
      at = at + "/" + seg;
      if (isItem(at)) {
        out.add(seg.substring(0, seg.lastIndexOf('-')) + "[" + itemId(at) + "]");
      } else {
        out.add(seg);
      }
    }
    return String.join("/", out);
  }

  /** Reports every difference of the copy from the holder; whether there is one. */
  private boolean compareSubtrees(String copyPath, String holder) {
    Map<String, SubtreeValue> mine = subtree(copyPath);
    Map<String, SubtreeValue> theirs = subtree(holder);
    Set<String> keys = new TreeSet<>(mine.keySet());
    keys.addAll(theirs.keySet());
    // An element on one side only is one finding; its values are not compared.
    List<String> oneSided = new ArrayList<>();
    for (String k : keys) {
      if (k.startsWith("i:") && mine.containsKey(k) != theirs.containsKey(k)) {
        oneSided.add(k.substring(2));
      }
    }
    boolean differs = false;
    for (String k : keys) {
      SubtreeValue a = mine.get(k);
      SubtreeValue b = theirs.get(k);
      String av = a == null ? "" : a.value;
      String bv = b == null ? "" : b.value;
      if (((a == null) == (b == null) && av.equals(bv)) || beneath(k, oneSided)) {
        continue;
      }
      differs = true;
      String what;
      if (k.startsWith("i:")) {
        what = "element " + (a != null ? av : bv);
      } else if (k.startsWith("h:")) {
        what = "the headline";
      } else if (k.startsWith("c:")) {
        what = "the content";
      } else {
        what = "form field \"" + k.substring(k.indexOf('#') + 1) + "\"";
      }
      String at = a != null ? a.path : copyPath;
      report(
          SpecValidationCode.SAME_AS_MISMATCH,
          at,
          "the copy of " + holder + " differs in " + what + ": the copy holds \"" + av
              + "\", the holder \"" + bv + "\"");
    }
    return differs;
  }

  private static boolean beneath(String k, List<String> oneSided) {
    if (k.startsWith("i:")) {
      return false;
    }
    String rel = k.substring(2).split("#", 2)[0];
    for (String o : oneSided) {
      if (rel.equals(o) || rel.startsWith(o + "/")) {
        return true;
      }
    }
    return false;
  }

  // --- helpers of the fixes -------------------------------------------------

  /** The forms directly beneath {@code row} ({@code <row>/<member>}). */
  private List<String> ownForms(String row) {
    List<String> out = new ArrayList<>();
    for (String p : new TreeSet<>(doc.formPaths())) {
      if (p.startsWith(row + "/") && p.indexOf('/', row.length() + 1) < 0) {
        out.add(p);
      }
    }
    return out;
  }

  /** Whether anything beneath {@code path} holds a value (marks included). */
  public boolean holdsValue(String path) {
    if (valued == null) {
      Set<String> v = new HashSet<>();
      for (String p : doc.contentPaths()) {
        String c = doc.content(p);
        if (c != null && !c.strip().isEmpty()) {
          markUp(v, p, true);
        }
      }
      for (String p : doc.formPaths()) {
        for (String name : doc.formFieldNames(p)) {
          String c = doc.formField(p, name);
          if (c != null && !c.strip().isEmpty()) {
            markUp(v, p, true);
            break;
          }
        }
      }
      for (String p : doc.headlinePaths()) {
        String h = doc.headline(p);
        if (h != null && !h.isEmpty()) {
          markUp(v, p, false);
        }
      }
      for (String lst : doc.listPaths()) {
        if (!doc.listItems(lst).isEmpty()) {
          markUp(v, lst, true);
        }
      }
      valued = v;
    }
    return valued.contains(path);
  }

  private static void markUp(Set<String> valued, String p, boolean self) {
    String cur = p;
    if (!self) {
      int slash = p.lastIndexOf('/');
      cur = slash >= 0 ? p.substring(0, slash) : "";
    }
    while (!cur.isEmpty() && valued.add(cur)) {
      int slash = cur.lastIndexOf('/');
      cur = slash < 0 ? "" : cur.substring(0, slash);
    }
  }
}
