package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * What a strip does with each kind (SOM §11.10): {@code -drop:}, {@code
 * -unmark:} and {@code -appendix:} per kind. {@link #fromNames} is the checked
 * form of the names a user gives.
 */
public final class SpecStripOptions {
  /** The kinds removed with their content. */
  public final Set<String> drop;
  /** The kinds whose markers go and whose content stays. */
  public final Set<String> unmark;
  /** The kinds moved, with their content, into the appendix <em>Notes</em>. */
  public final Set<String> appendix;
  /** Whether each moved element leaves a link {@code [n]} to its entry. */
  public final boolean appendixReferences;
  /** Whether sections deeper than level 6 are styled-div headings. */
  public final boolean headingDivs;

  /** Options that strip nothing. */
  public SpecStripOptions() {
    this(null, null, null, false, false);
  }

  /** The options as sets (a null set is empty); {@link #fromNames} is the checked form. */
  public SpecStripOptions(
      Set<String> drop,
      Set<String> unmark,
      Set<String> appendix,
      boolean appendixReferences,
      boolean headingDivs) {
    this.drop = drop != null ? drop : new LinkedHashSet<>();
    this.unmark = unmark != null ? unmark : new LinkedHashSet<>();
    this.appendix = appendix != null ? appendix : new LinkedHashSet<>();
    this.appendixReferences = appendixReferences;
    this.headingDivs = headingDivs;
  }

  /**
   * Whether the rendition leaves the {@code linked} markers out (SOM §11.11):
   * {@code linked} dropped or unmarked.
   */
  public boolean writesNoLinkedMarkers() {
    return drop.contains("linked") || unmark.contains("linked");
  }

  /**
   * Whether the rendition leaves the generated parts out (SOM §11.12): {@code
   * derived} dropped or unmarked.
   */
  public boolean writesNoGeneratedParts() {
    return drop.contains("derived") || unmark.contains("derived");
  }

  private static List<String> names(Iterable<String> list) {
    List<String> out = new ArrayList<>();
    if (list == null) {
      return out;
    }
    for (String item : list) {
      for (String n : item.split(",", -1)) {
        String t = SpecNotation.jsTrim(n);
        if (!t.isEmpty()) {
          out.add(t);
        }
      }
    }
    return out;
  }

  /**
   * The options from the names a user gives, each item possibly comma-joined
   * (a null list is empty). {@code all} stands for every kind the list can
   * hold that no other list names explicitly. Throws {@link
   * SpecStripUsageError} for an unknown name, a name in two lists, {@code
   * comments} to unmark or move, {@code linked} or {@code derived} to move,
   * and appendix references without an appendix.
   */
  public static SpecStripOptions fromNames(
      Iterable<String> drop,
      Iterable<String> unmark,
      Iterable<String> appendix,
      boolean appendixReferences,
      boolean headingDivs) {
    Map<String, List<String>> lists = new LinkedHashMap<>();
    lists.put("drop", names(drop));
    lists.put("unmark", names(unmark));
    lists.put("appendix", names(appendix));
    List<String> known = new ArrayList<>(SpecDocumentStrip.specStripKindNames);
    known.add("all");
    for (Map.Entry<String, List<String>> e : lists.entrySet()) {
      for (String n : e.getValue()) {
        if (!known.contains(n)) {
          throw new SpecStripUsageError(
              "unknown kind name \""
                  + n
                  + "\" in "
                  + e.getKey()
                  + "; known names: "
                  + String.join(", ", known));
        }
      }
    }
    List<String> keys = new ArrayList<>(lists.keySet());
    for (int i = 0; i < keys.size(); i++) {
      for (int j = i + 1; j < keys.size(); j++) {
        for (String n : lists.get(keys.get(i))) {
          if (lists.get(keys.get(j)).contains(n)) {
            throw new SpecStripUsageError(
                "kind name \"" + n + "\" is in both " + keys.get(i) + " and " + keys.get(j));
          }
        }
      }
    }
    if (lists.get("unmark").contains("comments")) {
      throw new SpecStripUsageError(
          "comments cannot be unmarked: a review annotation has no reading "
              + "without its markers; drop it or leave it");
    }
    if (lists.get("appendix").contains("comments")) {
      throw new SpecStripUsageError(
          "comments cannot be moved to the appendix; drop them or leave them");
    }
    for (String k : new String[] {"linked", "derived"}) {
      if (lists.get("appendix").contains(k)) {
        throw new SpecStripUsageError(
            k
                + " cannot be moved to the appendix: the renderer writes it from "
                + "the document; drop it or leave it");
      }
    }
    Set<String> explicit = new LinkedHashSet<>();
    for (List<String> l : lists.values()) {
      for (String n : l) {
        if (!n.equals("all")) {
          explicit.add(n);
        }
      }
    }
    List<String> unmarkable = new ArrayList<>(SpecDocumentStrip.specStripNotationKinds);
    unmarkable.add("linked");
    unmarkable.add("derived");
    Set<String> appendixSet =
        expand(lists.get("appendix"), SpecDocumentStrip.specStripNotationKinds, explicit);
    if (appendixReferences && appendixSet.isEmpty()) {
      throw new SpecStripUsageError("appendix references need an appendix: name its kinds");
    }
    return new SpecStripOptions(
        expand(lists.get("drop"), SpecDocumentStrip.specStripKindNames, explicit),
        expand(lists.get("unmark"), unmarkable, explicit),
        appendixSet,
        appendixReferences,
        headingDivs);
  }

  private static Set<String> expand(List<String> list, List<String> all, Set<String> explicit) {
    Set<String> out = new LinkedHashSet<>();
    for (String n : list) {
      if (n.equals("all")) {
        for (String k : all) {
          if (!explicit.contains(k)) {
            out.add(k);
          }
        }
      } else {
        out.add(n);
      }
    }
    return out;
  }

  /** The options of the emptying rule: what would go is unmarked instead. */
  public SpecStripOptions keeping() {
    Set<String> u = new LinkedHashSet<>(unmark);
    u.addAll(appendix);
    for (String k : drop) {
      if (!k.equals("comments")) {
        u.add(k);
      }
    }
    Set<String> d = new LinkedHashSet<>();
    if (drop.contains("comments")) {
      d.add("comments");
    }
    return new SpecStripOptions(d, u, null, false, headingDivs);
  }

  /** The options an appendix entry's own content is stripped with. */
  SpecStripOptions inEntry() {
    Set<String> d = new LinkedHashSet<>(drop);
    d.remove("comments");
    Set<String> u = new LinkedHashSet<>(unmark);
    u.addAll(appendix);
    return new SpecStripOptions(d, u, null, false, false);
  }

  /** {@code names} in the canonical order of {@link SpecDocumentStrip#specStripKindNames}. */
  public static List<String> ordered(Set<String> names) {
    List<String> out = new ArrayList<>();
    for (String k : SpecDocumentStrip.specStripKindNames) {
      if (names.contains(k)) {
        out.add(k);
      }
    }
    return out;
  }

  /** The switches as the corpus writes them: the lists in canonical order and the two flags. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("drop", new ArrayList<Object>(ordered(drop)));
    out.put("unmark", new ArrayList<Object>(ordered(unmark)));
    out.put("appendix", new ArrayList<Object>(ordered(appendix)));
    out.put("appendixReferences", appendixReferences);
    out.put("headingDivs", headingDivs);
    return out;
  }
}
