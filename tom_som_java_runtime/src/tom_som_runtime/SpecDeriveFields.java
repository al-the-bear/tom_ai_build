package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Supplier;

/**
 * {@code deriveFields}: the derived places of one document, written
 * ({@code tom_specs_model_rules.md} §9.7). A port of
 * {@code tom_som_dart_runtime/lib/src/spec_derive_fields.dart} (and the
 * TypeScript, JavaScript, Python and Go {@code spec_derive_fields} modules); it
 * applies the {@link SpecLinkFix} entries {@link SpecLinkValidator} collects, in
 * the order each records.
 */
public final class SpecDeriveFields {
  private SpecDeriveFields() {}

  /** {@link #deriveFields(SpecModel, SpecDocument, SpecDeriveOptions)} with the default options (marked, in place). */
  public static SpecDeriveResult deriveFields(SpecModel model, SpecDocument doc) {
    return deriveFields(model, doc, new SpecDeriveOptions());
  }

  /**
   * Recomputes the derived places of {@code doc} in three steps, each reading
   * the result of the one before:
   *
   * <ol>
   *   <li>the missing {@code inverseOf} ends inside the document, the missing
   *       {@code @ExtractsLinks} rows in {@code generate} mode, and the stale
   *       generated rows removed (a link row left with no value at all goes too);
   *   <li>{@code @DerivedFrom} values and lists, {@code @SummaryOf}
   *       {@code repeats}, and every {@code @SameAs} copy from its holder;
   *   <li>{@code countOf}, {@code productOf} and {@code rankOf}.
   * </ol>
   *
   * <p>With {@link SpecDeriveOptions#marked} (a document under review) every
   * change is written as inline marks attributed to the author at the time
   * given, and values are read as proposed (pending marks accepted); without it
   * values are written plain. A change it cannot mark exactly is left as it was
   * and listed as {@code unmarkable}. It never writes another document. A second
   * run right after the first writes nothing. {@link SpecDeriveOptions#dryRun}
   * works on a copy.
   */
  public static SpecDeriveResult deriveFields(
      SpecModel model, SpecDocument doc, SpecDeriveOptions options) {
    SpecDocument target = doc;
    if (options.dryRun) {
      target = new SpecDocument();
      target.loadJson(doc.toJson());
    }
    Deriver d = new Deriver(model, target, options);
    d.run();
    return new SpecDeriveResult(target, d.changes, d.unresolved);
  }

  private static String blankToNull(String s) {
    return s == null || s.isEmpty() ? null : s;
  }

  private static final class Deriver {
    final SpecModel model;
    final SpecDocument doc;
    final boolean marked;
    final String author;
    final String at;
    final SpecReviewAnnotations api;
    final List<SpecDeriveChange> changes = new ArrayList<>();
    final List<SpecValidationError> unresolved = new ArrayList<>();
    final Set<String> unresolvedKeys = new HashSet<>();

    Deriver(SpecModel model, SpecDocument doc, SpecDeriveOptions options) {
      this.model = model;
      this.doc = doc;
      this.marked = options.marked;
      this.author = blankToNull(options.author);
      this.at = blankToNull(options.at);
      String fixed = this.at;
      Supplier<String> clock = fixed == null ? null : () -> fixed;
      this.api = new SpecReviewAnnotations(doc, null, clock);
    }

    SpecLinkValidator check() {
      return new SpecLinkValidator(model, doc, marked).run();
    }

    void run() {
      // Step 1: link ends and rows. Removals first, so a row removed and a row
      // added for the same id do not cancel out.
      SpecLinkValidator v = check();
      List<SpecLinkFix> step1 = new ArrayList<>();
      for (SpecLinkFix f : v.fixes) {
        if (f.step == 1) {
          step1.add(f);
        }
      }
      for (SpecLinkFix f : step1) {
        if (f.kind.equals(SpecLinkFix.REMOVE_ROW)) {
          removeRow(1, f.path, f.empty);
        }
      }
      for (SpecLinkFix f : step1) {
        if (!f.kind.equals(SpecLinkFix.REMOVE_ROW)) {
          apply(f, v);
        }
      }

      // Step 2: derived values and lists, then (reading them) the repeats and
      // the copies; again until nothing moves, which DERIVE-ACYCLIC bounds.
      for (int i = 0; i < 4; i++) {
        v = check();
        int before = changes.size();
        for (SpecLinkFix f : v.fixes) {
          if (f.step == 2 && !f.kind.equals(SpecLinkFix.COPY)) {
            apply(f, v);
          }
        }
        v = check();
        for (SpecLinkFix f : v.fixes) {
          if (f.kind.equals(SpecLinkFix.COPY)) {
            apply(f, v);
          }
        }
        if (changes.size() == before) {
          break;
        }
      }
      for (SpecValidationError e : v.errors) {
        if (e.code == SpecValidationCode.DERIVED_LOOKUP_MISS) {
          addUnresolved(e);
        }
      }

      // Step 3: counts, products, ranks.
      for (SpecDerivedNumber n : SpecValidator.derivedNumbers(model, doc, marked)) {
        write(3, n.path, n.field, n.value);
      }
    }

    void addUnresolved(SpecValidationError e) {
      if (unresolvedKeys.add(e.code.value + " " + e.path + " " + e.message)) {
        unresolved.add(e);
      }
    }

    /**
     * Writes {@code value} at {@code path} / {@code field}: plainly, or marked
     * against the value there (compared from its original, so a change already
     * proposed is not proposed again).
     */
    void write(int step, String path, String field, String value) {
      String current = SpecSetCheck.getValue(doc, path, field);
      if (!marked) {
        if (current.strip().equals(value.strip())) {
          return;
        }
        SpecSetCheck.setValue(doc, path, field, value);
      } else {
        if (SpecReviewAnnotations.applyInlineMarksText(current, true).strip().equals(value.strip())) {
          return;
        }
        String original = SpecReviewAnnotations.applyInlineMarksText(current, false);
        if (!SpecReviewAnnotations.markChangeText(original, value).exact) {
          String what = field != null ? "form field \"" + field + "\"" : "the content";
          addUnresolved(
              new SpecValidationError(
                  path,
                  SpecValidationCode.UNMARKABLE,
                  what + " would become \"" + value + "\", a change that cannot "
                      + "be marked exactly; it is left for the agent"));
          return;
        }
        api.setMarked(path, field, value, author, at);
      }
      String now = SpecSetCheck.getValue(doc, path, field);
      if (!now.equals(current)) {
        changes.add(new SpecDeriveChange(step, SpecDeriveChange.VALUE, path, field, current, now));
      }
    }

    void addRow(int step, String lst, List<String> keys, Map<String, String> values) {
      String item = doc.addListItem(lst);
      changes.add(SpecDeriveChange.row(step, SpecDeriveChange.ROW_ADDED, item));
      for (String k : keys) {
        int hash = k.indexOf('#');
        String rel = hash >= 0 ? k.substring(0, hash) : k;
        String field = hash >= 0 ? k.substring(hash + 1) : null;
        write(step, item + "/" + rel, field, values.get(k));
      }
    }

    void removeRow(int step, String row, boolean empty) {
      if (!marked || empty) {
        if (!doc.removeListItem(row)) {
          return;
        }
        changes.add(SpecDeriveChange.row(step, SpecDeriveChange.ROW_REMOVED, row));
        return;
      }
      // Under review: every value of the row is proposed for deletion; once
      // accepted, the empty row goes with the next run.
      int before = changes.size();
      for (String p : new TreeSet<>(doc.contentPaths())) {
        if (inside(p, row)) {
          write(step, p, null, "");
        }
      }
      for (String p : new TreeSet<>(doc.formPaths())) {
        if (!inside(p, row)) {
          continue;
        }
        for (String f : new TreeSet<>(doc.formFieldNames(p))) {
          write(step, p, f, "");
        }
      }
      if (changes.size() > before) {
        changes.add(before, SpecDeriveChange.row(step, SpecDeriveChange.ROW_REMOVED, row));
      }
    }

    void apply(SpecLinkFix f, SpecLinkValidator v) {
      switch (f.kind) {
        case SpecLinkFix.SET:
          write(f.step, f.path, f.field, f.value);
          break;
        case SpecLinkFix.APPEND:
          {
            List<String> ids = SpecLinkValidator.linkIds(v.formValue(f.path, f.field));
            if (ids.contains(f.value)) {
              return;
            }
            ids.add(f.value);
            write(f.step, f.path, f.field, String.join(", ", ids));
            break;
          }
        case SpecLinkFix.ADD_ROW:
          addRow(f.step, f.path, f.orderedValueKeys(), f.values);
          break;
        case SpecLinkFix.REMOVE_ROW:
          removeRow(f.step, f.path, f.empty);
          break;
        case SpecLinkFix.LIST:
          applyList(f, v);
          break;
        case SpecLinkFix.COPY:
          applyCopy(f.path, f.holder, v);
          break;
        default:
          break;
      }
    }

    /**
     * Makes the list hold one element per wanted tuple: elements matching no
     * tuple removed, tuples matching no element added.
     */
    void applyList(SpecLinkFix f, SpecLinkValidator v) {
      List<String> places = f.orderedTupleKeys();
      List<String> wanted = new ArrayList<>();
      for (Map<String, String> t : f.tuples) {
        wanted.add(tupleKey(places, t));
      }
      List<String> keep = new ArrayList<>();
      for (String el : doc.listItems(f.path)) {
        Map<String, String> t = new LinkedHashMap<>();
        for (String p : places) {
          t.put(p, v.placeValue(p, el));
        }
        String k = tupleKey(places, t);
        if (wanted.remove(k)) {
          keep.add(k);
        } else {
          removeRow(2, el, false);
        }
      }
      for (Map<String, String> t : f.tuples) {
        if (keep.remove(tupleKey(places, t))) {
          continue;
        }
        Map<String, String> values = new LinkedHashMap<>();
        String probe = f.path + "-0";
        for (String p : places) {
          SpecPlaceResolution r = v.at(p, probe);
          if (r == null) {
            continue;
          }
          String rel = r.path.length() <= probe.length() + 1 ? "" : r.path.substring(probe.length() + 1);
          if (r.field() != null) {
            rel = rel + "#" + r.field();
          }
          values.put(rel, t.get(p));
        }
        addRow(2, f.path, new ArrayList<>(values.keySet()), values);
      }
    }

    /**
     * Writes the copy at {@code copyPath} from its holder: every value and
     * element the holder has, in the copy, and nothing else.
     */
    void applyCopy(String copyPath, String holder, SpecLinkValidator v) {
      Map<String, SpecLinkValidator.SubtreeValue> theirs = v.subtree(holder);
      Map<String, SpecLinkValidator.SubtreeValue> mine = v.subtree(copyPath);

      // Elements the holder lacks go first, and nothing beneath them is
      // written.
      List<String> gone = new ArrayList<>();
      for (String k : new TreeSet<>(mine.keySet())) {
        if (!k.startsWith("i:") || theirs.containsKey(k)) {
          continue;
        }
        String rel = k.substring(2);
        boolean beneath = false;
        for (String g : gone) {
          if (rel.startsWith(g + "/")) {
            beneath = true;
            break;
          }
        }
        if (beneath) {
          continue;
        }
        gone.add(rel);
        removeRow(2, mine.get(k).path, false);
      }

      for (String k : new TreeSet<>(theirs.keySet())) {
        if (k.startsWith("i:")) {
          pathIn(copyPath, k.substring(2), true, v);
          continue;
        }
        String[] split = split(k);
        if (split == null) {
          continue;
        }
        String path = pathIn(copyPath, split[0], true, v);
        if (path == null) {
          continue;
        }
        write(2, path, split[1], theirs.get(k).value);
      }
      for (String k : new TreeSet<>(mine.keySet())) {
        if (theirs.containsKey(k) || k.startsWith("i:")) {
          continue;
        }
        String[] split = split(k);
        if (split == null || beneathAny(split[0], gone)) {
          continue;
        }
        String path = pathIn(copyPath, split[0], false, v);
        if (path != null) {
          write(2, path, split[1], "");
        }
      }
    }

    /**
     * The path {@code rel} (list items {@code LIST[id]}) stands for in the copy;
     * a missing item created with {@code create}, else {@code null}.
     */
    String pathIn(String copyPath, String rel, boolean create, SpecLinkValidator v) {
      String cur = copyPath;
      if (rel.isEmpty()) {
        return cur;
      }
      for (String seg : rel.split("/", -1)) {
        int bracket = seg.indexOf('[');
        if (bracket < 0) {
          cur = cur + "/" + seg;
          continue;
        }
        String lst = cur + "/" + seg.substring(0, bracket);
        String id = seg.substring(bracket + 1, seg.length() - 1);
        String found = null;
        for (String i : doc.listItems(lst)) {
          if (v.itemId(i).equals(id)) {
            found = i;
            break;
          }
        }
        if (found != null) {
          cur = found;
        } else if (!create) {
          return null;
        } else {
          cur = doc.addListItem(lst, id);
          v.itemIds.put(cur, id);
          changes.add(SpecDeriveChange.row(2, SpecDeriveChange.ROW_ADDED, cur));
        }
      }
      return cur;
    }
  }

  private static String tupleKey(List<String> places, Map<String, String> t) {
    List<String> parts = new ArrayList<>();
    for (String p : places) {
      String v = t.get(p);
      parts.add(v == null ? "" : v);
    }
    return String.join(" | ", parts);
  }

  private static boolean inside(String p, String root) {
    return p.equals(root) || p.startsWith(root + "/");
  }

  private static boolean beneathAny(String rel, List<String> gone) {
    for (String g : gone) {
      if (rel.equals(g) || rel.startsWith(g + "/")) {
        return true;
      }
    }
    return false;
  }

  /** A subtree value key as {@code [rel, field]} (field {@code null}: content), {@code null} for an item key. */
  private static String[] split(String key) {
    String body = key.substring(2);
    switch (key.charAt(0)) {
      case 'f':
        {
          int hash = body.indexOf('#');
          return new String[] {body.substring(0, hash), body.substring(hash + 1)};
        }
      case 'c':
        return new String[] {body, null};
      case 'h':
        return new String[] {body, SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD};
      default:
        return null;
    }
  }
}
