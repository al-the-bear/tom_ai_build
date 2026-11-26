package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

/**
 * {@code prefill}: a Phase 3 document started from the Blueprint (BP-8). A
 * port of {@code tom_som_dart_runtime/lib/src/spec_prefill.dart} (and the
 * TypeScript, JavaScript, Python and Go {@code spec_prefill} modules); it reads
 * the comparison internals of {@link SpecSetCheck} and {@link SpecSetSide}.
 */
public final class SpecPrefill {
  private SpecPrefill() {}

  /** {@link #prefill(SpecDocumentSet, String, SpecPrefillOptions)} with the default options. */
  public static SpecPrefillResult prefill(SpecDocumentSet set, String rootType) {
    return prefill(set, rootType, new SpecPrefillOptions());
  }

  /**
   * Fills the pairs of {@code rootType} (a root's type name or section id) that
   * hold nothing yet from the Blueprint, once, at the start of a Phase 3
   * document (BP-8): every value, element (with its stored section id) and
   * headline beneath each pair's Blueprint anchor, outside {@code detailOnly},
   * copied as plain values. Derived places are not copied; they are derived in
   * the document ({@code deriveFields}, plain) after the copy.
   *
   * <p>A pair whose anchor already holds any value is skipped, not merged, so a
   * second run writes nothing. The document's front matter is left empty for
   * the agent. When the set has no document of the root, it is created as
   * {@link SpecPrefillOptions#name} (default: the root's type name) and added
   * to the set once it holds a value.
   */
  public static SpecPrefillResult prefill(
      SpecDocumentSet set, String rootType, SpecPrefillOptions options) {
    Set<String> scope = SpecDocumentSet.pairScope(options.pairs);
    String bpRoot = set.blueprintRoot;
    String bpName = bpRoot == null ? null : set.nameOf(bpRoot);
    if (bpName == null) {
      throw new SpecPrefillError(SpecPrefillError.NO_BLUEPRINT, "the set holds no Blueprint");
    }
    SpecRoot root = null;
    for (SpecRoot r : set.model.roots) {
      if (r.type.equals(rootType) || (rootType != null && rootType.equals(r.sectionId))) {
        root = r;
        break;
      }
    }
    if (root == null || root.type.equals(bpRoot)) {
      throw new SpecPrefillError(
          SpecPrefillError.UNKNOWN_ROOT, rootType + " names no Phase 3 root of the model");
    }
    String existing = set.nameOf(root.type);
    String docName = existing;
    if (existing == null) {
      docName = options.name == null || options.name.isEmpty() ? root.type : options.name;
    }
    SpecDocument doc = existing != null ? set.get(existing) : null;
    if (doc == null) {
      doc = new SpecDocument();
    }
    SpecDocument bp = set.get(bpName);
    SpecSetCheck c = new SpecSetCheck(set);

    List<String> filled = new ArrayList<>();
    List<String> skipped = new ArrayList<>();
    for (SpecSyncPair pair : set.pairs()) {
      if (!pair.detailRoot.equals(root.type)) {
        continue;
      }
      if (scope != null && !scope.contains(pair.sectionId)) {
        continue;
      }
      // Nested pairs are filled on their own (when they are this root's).
      List<String> nested = new ArrayList<>();
      for (SpecSyncPair other : set.pairs()) {
        if (other != pair) {
          nested.addAll(c.expand(bp, other.blueprintAnchor));
        }
      }
      boolean wrote = false;
      boolean held = false;
      for (String ba : c.expand(bp, pair.blueprintAnchor)) {
        String ids = c.anchorKey(bp, ba);
        List<String> createdItems = new ArrayList<>();
        String da = anchorIn(c, doc, pair.detailAnchor, ids, createdItems);
        if (doc.hasValuesUnder(da) && createdItems.isEmpty()) {
          held = true;
          continue;
        }
        List<String> beneath = new ArrayList<>();
        for (String p : nested) {
          if (p.startsWith(ba + "/")) {
            beneath.add(p);
          }
        }
        SpecSetSide side = c.collect(bpName, bp, bpRoot, ba, pair, beneath);
        if (copy(c, bp, side, doc, da)) {
          wrote = true;
        } else {
          // Nothing to copy: the anchor items made for it go again.
          for (int i = createdItems.size() - 1; i >= 0; i--) {
            doc.removeListItem(createdItems.get(i));
          }
        }
      }
      if (wrote) {
        filled.add(pair.sectionId);
      }
      if (held && !wrote) {
        skipped.add(pair.sectionId);
      }
    }

    boolean created = existing == null && doc.hasValuesUnder(set.refl.rootSegment(root));
    if (created) {
      set.put(docName, doc);
    }
    SpecDeriveResult derived = SpecDeriveFields.deriveFields(set.model, doc, SpecDeriveOptions.plain());
    List<SpecValidationError> findings = new ArrayList<>(SpecValidator.validateDocument(set.model, doc));
    findings.addAll(SpecValidator.validateLinks(set.model, doc));
    return new SpecPrefillResult(doc, docName, created, filled, skipped, derived, findings);
  }

  /**
   * The concrete detail anchor of {@code pattern} in {@code doc} for a
   * Blueprint anchor whose list items carry {@code ids} ({@code a/b}, in
   * order): each {@code <list>-*} taken as the item of that id, created with it
   * when missing (and recorded in {@code created}).
   */
  private static String anchorIn(
      SpecSetCheck c, SpecDocument doc, String pattern, String ids, List<String> created) {
    String[] want = ids.isEmpty() ? new String[0] : ids.split("/", -1);
    int k = 0;
    String cur = "";
    for (String seg : pattern.split("/", -1)) {
      if (!seg.endsWith("-*")) {
        cur = cur.isEmpty() ? seg : cur + "/" + seg;
        continue;
      }
      String lst = cur + "/" + seg.substring(0, seg.length() - 2);
      String id = "";
      if (k < want.length) {
        id = want[k];
        k++;
      }
      String hit = null;
      for (String i : doc.listItems(lst)) {
        if (c.itemId(doc, i).equals(id)) {
          hit = i;
          break;
        }
      }
      if (hit != null) {
        cur = hit;
      } else {
        cur = doc.addListItem(lst, id);
        created.add(cur);
      }
    }
    return cur;
  }

  /**
   * Copies the Blueprint values of {@code side} beneath {@code anchor} of
   * {@code doc}: list items first, in the Blueprint's order and with their
   * section ids, then every value. Whether anything was written.
   */
  private static boolean copy(
      SpecSetCheck c, SpecDocument bp, SpecSetSide side, SpecDocument doc, String anchor) {
    boolean wrote = false;
    Map<String, String> mapped = new LinkedHashMap<>();
    mapped.put(side.anchor, anchor);

    // Items, outer lists first, each list in the Blueprint's order.
    List<String> lists = new ArrayList<>();
    Set<String> itemPaths = new HashSet<>();
    for (String k : side.itemKeys) {
      String item = side.items.get(k);
      itemPaths.add(item);
      if (!item.equals(side.anchor)) {
        String lst = item.substring(0, item.lastIndexOf('-'));
        if (!lists.contains(lst)) {
          lists.add(lst);
        }
      }
    }
    lists.sort((a, b) -> Integer.compare(a.length(), b.length()));
    for (String lst : lists) {
      String target = into(mapped, lst);
      if (target == null) {
        continue;
      }
      for (String item : bp.listItems(lst)) {
        if (!itemPaths.contains(item)) {
          continue;
        }
        mapped.put(item, doc.addListItem(target, c.itemId(bp, item)));
        wrote = true;
      }
    }
    for (String k : new TreeSet<>(side.values.keySet())) {
      SpecSetValue v = side.values.get(k);
      if (v.value.isEmpty()) {
        continue;
      }
      String p = into(mapped, v.path);
      if (p == null) {
        continue;
      }
      SpecSetCheck.setValue(doc, p, v.field, v.value);
      wrote = true;
    }
    return wrote;
  }

  /** {@code bpPath} mapped through its longest mapped prefix, {@code null} when none maps it. */
  private static String into(Map<String, String> mapped, String bpPath) {
    String best = null;
    for (String k : mapped.keySet()) {
      if ((bpPath.equals(k) || bpPath.startsWith(k + "/")) && (best == null || k.length() > best.length())) {
        best = k;
      }
    }
    return best == null ? null : mapped.get(best) + bpPath.substring(best.length());
  }
}
