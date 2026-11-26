package tom_som_runtime;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * {@code backfill}: the accepted end state of the Phase 3 documents, carried
 * into the Blueprint (DP-part-operations-2). A port of
 * {@code tom_som_dart_runtime/lib/src/spec_backfill.dart} (and the TypeScript,
 * JavaScript, Python and Go {@code spec_backfill} modules); it reads the
 * comparison internals of {@link SpecSetCheck}.
 */
public final class SpecBackfill {
  private SpecBackfill() {}

  /** {@link #backfill(SpecDocumentSet, SpecBackfillOptions)} with the default options. */
  public static SpecBackfillResult backfill(SpecDocumentSet set) {
    return backfill(set, new SpecBackfillOptions());
  }

  /**
   * Carries the end state of the Phase 3 documents into the Blueprint, as plain
   * values: for every shared place whose holder is the Phase 3 document, the
   * holder's value — a differing or missing value written, a value the Phase 3
   * document emptied cleared, an element only in the Phase 3 document added
   * (with its stored section id, after its nearest preceding neighbour the
   * Blueprint holds, or first), an element only in the Blueprint removed
   * (DP-part-operations-3).
   *
   * <p>It leaves {@code detailOnly} places, a {@code heldHere} place the
   * documents disagree on, an element that under {@code subset} may be added,
   * and every finding across two documents: each is listed in
   * {@link SpecBackfillResult#left} with the reason.
   *
   * <p>It refuses a set holding any inline mark or annotation block
   * ({@link SpecBackfillError}, {@code setHasMarks}, the places named). It
   * writes only the Blueprint; when it changed anything it adds one entry to the
   * Blueprint's revision history (the {@code RVENT} list) naming the pairs, and
   * rewrites the Blueprint's derived places ({@code deriveFields}, plain). A
   * second run right after the first writes nothing.
   */
  public static SpecBackfillResult backfill(SpecDocumentSet set, SpecBackfillOptions options) {
    Set<String> scope = SpecDocumentSet.pairScope(options.pairs);
    String bpName = set.nameOf(set.blueprintRoot);
    if (bpName == null) {
      throw new SpecBackfillError(
          SpecBackfillError.NO_BLUEPRINT, List.of(), "the set holds no Blueprint");
    }
    SpecReflection refl = set.refl;

    // No review in progress.
    List<SpecSyncPlace> marked = new ArrayList<>();
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      String rootType = set.rootOf(name);
      String root = "";
      for (SpecRoot r : refl.model.roots) {
        if (r.type.equals(rootType)) {
          root = refl.rootSegment(r);
          break;
        }
      }
      Set<String> seen = new HashSet<>();
      for (SpecReviewAnnotation a : new SpecReviewAnnotations(doc, null).list()) {
        if (!seen.add(a.path + "#" + SpecSetCheck.or(a.field))) {
          continue;
        }
        marked.add(new SpecSyncPlace(name, root, a.path, a.field, null, false));
      }
    }
    if (!marked.isEmpty()) {
      throw new SpecBackfillError(
          SpecBackfillError.SET_HAS_MARKS,
          marked,
          "the set holds " + marked.size() + " value(s) with inline marks or "
              + "annotation blocks; backfill carries the end state of an accepted "
              + "review, so decide them first");
    }

    SpecDocument bpDoc = set.get(bpName);
    SpecDocument target = bpDoc;
    if (options.dryRun) {
      target = new SpecDocument();
      target.loadJson(bpDoc.toJson());
    }
    SpecSetCheck c = new SpecSetCheck(set);
    int index = 0;
    for (SpecSyncPair p : set.pairs()) {
      if (scope == null || scope.contains(p.sectionId)) {
        c.comparePair(p, index);
      }
      index++;
    }
    // The links across two documents are the agent's; they are listed as left.
    c.crossChecks(scope, index);
    c.out.sort(
        (a, b) -> {
          if (a.order != b.order) {
            return Integer.compare(a.order, b.order);
          }
          int k = a.key.compareTo(b.key);
          return k != 0 ? k : Integer.compare(a.finding.code.ordinal(), b.finding.code.ordinal());
        });

    String path = options.path == null || options.path.isEmpty() ? null : options.path;
    Writer w = new Writer(set, target, bpName);
    List<SpecBackfillLeft> left = new ArrayList<>();
    List<SpecSetFound> apply = new ArrayList<>();
    for (SpecSetFound o : c.out) {
      SpecSyncFinding f = o.finding;
      if (path != null && !f.blueprint.path.equals(path) && !f.blueprint.path.startsWith(path + "/")) {
        continue;
      }
      if (f.resolution == SpecSyncResolution.BACKFILL) {
        apply.add(o);
        continue;
      }
      String reason = f.resolution.value;
      if (f.holder == SpecSyncHolder.BLUEPRINT) {
        reason = SpecBackfillLeft.HELD_HERE;
      } else if (f.code == SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED) {
        reason = SpecBackfillLeft.MAY_BE_ADDED;
      }
      left.add(new SpecBackfillLeft(f, reason));
    }
    w.apply(apply);
    if (!w.changes.isEmpty()) {
      String author = options.author == null || options.author.isEmpty() ? "backfill" : options.author;
      String date =
          options.date == null || options.date.isEmpty() ? LocalDate.now().toString() : options.date;
      w.revisionEntry(author, date);
      for (SpecDeriveChange d :
          SpecDeriveFields.deriveFields(set.model, target, SpecDeriveOptions.plain()).changes) {
        w.changes.add(
            new SpecBackfillChange("", SpecBackfillChange.DERIVED, d.path, d.field, d.oldValue, d.newValue));
      }
    }
    return new SpecBackfillResult(target, w.changes, left);
  }

  /**
   * The version after {@code v}: its last number raised by one ({@code 1.2} →
   * {@code 1.3}), {@code 1} when it is empty, {@code <v>.1} when it holds no
   * number.
   */
  public static String bump(String v) {
    int end = -1;
    for (int i = v.length() - 1; i >= 0; i--) {
      if (isDigit(v.charAt(i))) {
        end = i + 1;
        break;
      }
    }
    if (end < 0) {
      return v.isEmpty() ? "1" : v + ".1";
    }
    int start = end;
    while (start > 0 && isDigit(v.charAt(start - 1))) {
      start--;
    }
    long n;
    try {
      n = Long.parseLong(v.substring(start, end));
    } catch (NumberFormatException e) {
      return v + ".1";
    }
    return v.substring(0, start) + (n + 1) + v.substring(end);
  }

  private static boolean isDigit(char c) {
    return c >= '0' && c <= '9';
  }

  private static String listOf(String item) {
    return item.substring(0, item.lastIndexOf('-'));
  }

  private static String idInKey(String key) {
    return key.substring(key.lastIndexOf('[') + 1, key.length() - 1);
  }

  private static String rel(String key) {
    String body = key.substring(2);
    int hash = body.indexOf('#');
    return hash >= 0 ? body.substring(0, hash) : body;
  }

  /** The longest key of {@code mapped} that {@code path} is or lies beneath ({@code strict}: beneath only). */
  private static String longestPrefix(Map<String, String> mapped, String path, boolean strict) {
    String best = null;
    for (String from : mapped.keySet()) {
      boolean hit = path.startsWith(from + "/") || (!strict && path.equals(from));
      if (hit && (best == null || from.length() > best.length())) {
        best = from;
      }
    }
    return best;
  }

  /** The ids to add to and drop from one reference field. */
  private static final class Ids {
    final String pair;
    final List<String> add = new ArrayList<>();
    final List<String> drop = new ArrayList<>();

    Ids(String pair) {
      this.pair = pair;
    }
  }

  private static final class Writer {
    final SpecDocumentSet set;
    final SpecDocument doc;
    final String name;
    final List<SpecBackfillChange> changes = new ArrayList<>();
    final Set<String> pairs = new HashSet<>();

    Writer(SpecDocumentSet set, SpecDocument doc, String name) {
      this.set = set;
      this.doc = doc;
      this.name = name;
    }

    void write(String pair, String path, String field, String value) {
      String old = SpecSetCheck.getValue(doc, path, field);
      if (old.strip().equals(value.strip())) {
        return;
      }
      SpecSetCheck.setValue(doc, path, field, value);
      pairs.add(pair);
      changes.add(new SpecBackfillChange(pair, SpecBackfillChange.VALUE, path, field, old, value));
    }

    String idOf(String item) {
      return SpecSetCheck.effectiveItemId(set.refl, doc, item);
    }

    void apply(List<SpecSetFound> found) {
      // 1. Elements only in the Blueprint go, first.
      for (SpecSetFound o : found) {
        if (o.finding.code != SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT || !o.key.startsWith("i:")) {
          continue;
        }
        String item = o.b.items.get(o.key.substring(2));
        if (item == null || !doc.removeListItem(item)) {
          continue;
        }
        pairs.add(o.finding.pair);
        changes.add(
            new SpecBackfillChange(
                o.finding.pair, SpecBackfillChange.ELEMENT_REMOVED, item, null,
                o.finding.blueprint.valueOr(), ""));
      }

      // 2. Values, and the ids of reference fields.
      Map<String, Ids> ids = new LinkedHashMap<>();
      for (SpecSetFound o : found) {
        SpecSyncFinding f = o.finding;
        if (o.key.startsWith("i:")) {
          continue;
        }
        String field = f.blueprint.field;
        String idKey = f.blueprint.path + "#" + SpecSetCheck.or(field);
        switch (f.code) {
          case SHARED_VALUE_DIFFERS:
          case SHARED_VALUE_MISSING:
            write(f.pair, f.blueprint.path, field, o.d.values.get(o.key).value);
            break;
          case SHARED_VALUE_ONLY_IN_BLUEPRINT:
            write(f.pair, f.blueprint.path, field, "");
            break;
          case SHARED_ELEMENT_MISSING:
            {
              Ids e = ids.computeIfAbsent(idKey, k -> new Ids(f.pair));
              if (!e.add.contains(f.detail.valueOr())) {
                e.add.add(f.detail.valueOr());
              }
              break;
            }
          case SHARED_ELEMENT_ONLY_IN_BLUEPRINT:
            {
              Ids e = ids.computeIfAbsent(idKey, k -> new Ids(f.pair));
              if (!e.drop.contains(f.blueprint.valueOr())) {
                e.drop.add(f.blueprint.valueOr());
              }
              break;
            }
          default:
            break;
        }
      }
      for (Map.Entry<String, Ids> entry : ids.entrySet()) {
        Ids e = entry.getValue();
        String key = entry.getKey();
        int hash = key.lastIndexOf('#');
        String p = key.substring(0, hash);
        String field = key.substring(hash + 1);
        if (field.isEmpty()) {
          field = null;
        }
        List<String> now = new ArrayList<>();
        for (String s : SpecSetCheck.getValue(doc, p, field).split(",", -1)) {
          String t = s.strip();
          if (!t.isEmpty() && !e.drop.contains(t)) {
            now.add(t);
          }
        }
        for (String x : e.add) {
          if (!now.contains(x)) {
            now.add(x);
          }
        }
        write(e.pair, p, field, String.join(", ", now));
      }

      // 3. Elements only in the Phase 3 document come in, each with every value
      // the pair shares beneath it, then take their place.
      Map<String, List<String[]>> byList = new LinkedHashMap<>(); // list -> [id], with order
      Map<String, List<List<String>>> ordersByList = new LinkedHashMap<>();
      for (SpecSetFound o : found) {
        if (o.finding.code != SpecSyncCode.SHARED_ELEMENT_MISSING || !o.key.startsWith("i:")) {
          continue;
        }
        SpecSetSide d = o.d;
        String rel = o.key.substring(2);
        String id = idInKey(rel);
        String lst = o.finding.blueprint.path;
        String detailItem = d.items.get(rel);
        String item = doc.addListItem(lst, id);
        pairs.add(o.finding.pair);
        changes.add(
            new SpecBackfillChange(o.finding.pair, SpecBackfillChange.ELEMENT_ADDED, item, null, "", id));
        // Nested elements first (shortest key first), then the values.
        Map<String, String> mapped = new LinkedHashMap<>();
        mapped.put(detailItem, item);
        List<String> nested = new ArrayList<>();
        for (String k : d.itemKeys) {
          if (k.startsWith(rel + "/")) {
            nested.add(k);
          }
        }
        nested.sort((x, y) -> Integer.compare(x.length(), y.length()));
        for (String k : nested) {
          String dPath = d.items.get(k);
          String parentFrom = longestPrefix(mapped, dPath, true);
          if (parentFrom == null) {
            continue;
          }
          String parentTo = mapped.get(parentFrom);
          String seg = dPath.substring(parentFrom.length() + 1);
          mapped.put(dPath, doc.addListItem(parentTo + "/" + seg.substring(0, seg.lastIndexOf('-')), idInKey(k)));
        }
        for (Map.Entry<String, SpecSetValue> ve : d.values.entrySet()) {
          String r = rel(ve.getKey());
          if (!r.equals(rel) && !r.startsWith(rel + "/")) {
            continue;
          }
          SpecSetValue v = ve.getValue();
          String from = longestPrefix(mapped, v.path, false);
          if (from == null || v.value.isEmpty()) {
            continue;
          }
          SpecSetCheck.setValue(doc, mapped.get(from) + v.path.substring(from.length()), v.field, v.value);
        }
        // The detail list's order, by id.
        SpecDocument detailDoc = set.get(o.finding.detail.document);
        List<String> order = new ArrayList<>();
        for (String it : detailDoc.listItems(listOf(detailItem))) {
          order.add(SpecSetCheck.effectiveItemId(set.refl, detailDoc, it));
        }
        byList.computeIfAbsent(lst, k -> new ArrayList<>()).add(new String[] {id});
        ordersByList.computeIfAbsent(lst, k -> new ArrayList<>()).add(order);
      }
      // Each list takes its new elements in one reorder: an element goes after
      // its nearest preceding neighbour (in the Phase 3 order) the Blueprint
      // holds, or first.
      List<String> listOrder = new ArrayList<>(byList.keySet());
      Map<String, List<String>> orders = new HashMap<>();
      for (String lst : listOrder) {
        List<String[]> entries = byList.get(lst);
        List<List<String>> entryOrders = ordersByList.get(lst);
        Set<String> newIds = new HashSet<>();
        for (String[] a : entries) {
          newIds.add(a[0]);
        }
        List<String> items = doc.listItems(lst);
        List<String> orderNow = new ArrayList<>();
        for (String i : items) {
          if (!newIds.contains(idOf(i))) {
            orderNow.add(i);
          }
        }
        for (int n = 0; n < entries.size(); n++) {
          String aId = entries.get(n)[0];
          List<String> aOrder = entryOrders.get(n);
          String item = null;
          for (String i : items) {
            if (idOf(i).equals(aId)) {
              item = i;
              break;
            }
          }
          List<String> before;
          int at = aOrder.indexOf(aId);
          if (at >= 0) {
            before = aOrder.subList(0, at);
          } else if (!aOrder.isEmpty()) {
            before = aOrder.subList(0, aOrder.size() - 1);
          } else {
            before = List.of();
          }
          int pos = 0;
          for (int j = before.size() - 1; j >= 0; j--) {
            int k = -1;
            for (int m = 0; m < orderNow.size(); m++) {
              if (idOf(orderNow.get(m)).equals(before.get(j))) {
                k = m;
                break;
              }
            }
            if (k >= 0) {
              pos = k + 1;
              break;
            }
          }
          orderNow.add(pos, item);
        }
        orders.put(lst, orderNow);
      }
      reorder(listOrder, orders);
      // Each added element is reported at the place it took.
      for (int i = 0; i < changes.size(); i++) {
        SpecBackfillChange ch = changes.get(i);
        if (!ch.kind.equals(SpecBackfillChange.ELEMENT_ADDED)) {
          continue;
        }
        String nowPath = null;
        for (String x : doc.listItems(listOf(ch.path))) {
          if (idOf(x).equals(ch.newValue)) {
            nowPath = x;
            break;
          }
        }
        if (nowPath == null || nowPath.equals(ch.path)) {
          continue;
        }
        changes.set(
            i, new SpecBackfillChange(ch.pair, ch.kind, nowPath, null, ch.oldValue, ch.newValue));
      }
    }

    /**
     * Puts the items of each list in {@code orders} in the order given, in one
     * pass over the document's stores: the lists renumbered
     * {@code <list>-1 … <list>-n}, every value beneath an item travelling with
     * it, an anonymous item whose positional id would change keeping its old id
     * (as {@code moveListItem} does). Inner lists go first, so an outer rename
     * carries their new paths.
     */
    @SuppressWarnings("unchecked")
    void reorder(List<String> listOrder, Map<String, List<String>> orders) {
      if (listOrder.isEmpty()) {
        return;
      }
      List<String> lists = new ArrayList<>(listOrder);
      lists.sort((a, b) -> Integer.compare(b.split("/", -1).length, a.split("/", -1).length));
      Map<String, String> idsNow = new HashMap<>();
      for (String lst : lists) {
        for (String i : doc.listItems(lst)) {
          idsNow.put(i, idOf(i));
        }
      }
      Map<String, Object> j = doc.toJson();
      for (String lst : lists) {
        List<String> order = orders.get(lst);
        Map<String, String> m = new LinkedHashMap<>();
        for (int i = 0; i < order.size(); i++) {
          String to = lst + "-" + (i + 1);
          if (!order.get(i).equals(to)) {
            m.put(order.get(i), to);
          }
        }
        if (m.isEmpty()) {
          continue;
        }
        Map<String, Object> lists0 = (Map<String, Object>) j.get("lists");
        Map<String, Object> listJson = (Map<String, Object>) lists0.get(lst);
        Map<String, Object> storedIds = new LinkedHashMap<>();
        Object rawIds = listJson == null ? null : listJson.get("ids");
        if (rawIds instanceof Map) {
          storedIds.putAll((Map<String, Object>) rawIds);
        }
        List<String> original = doc.listItems(lst);
        for (int i = 0; i < order.size(); i++) {
          String it = order.get(i);
          if (original.indexOf(it) != i && !storedIds.containsKey(it) && idsNow.containsKey(it)) {
            storedIds.put(it, idsNow.get(it));
          }
        }
        for (String store : List.of("content", "headlines", "codeSpecs", "units", "forms")) {
          Object raw = j.get(store);
          if (raw instanceof Map) {
            Map<String, Object> renamed = new TreeMap<>();
            for (Map.Entry<String, Object> e : ((Map<String, Object>) raw).entrySet()) {
              renamed.put(rename(e.getKey(), m), e.getValue());
            }
            j.put(store, renamed);
          }
        }
        Map<String, Object> newLists = new TreeMap<>();
        for (Map.Entry<String, Object> e : lists0.entrySet()) {
          Map<String, Object> value = (Map<String, Object>) e.getValue();
          Map<String, Object> spec = new LinkedHashMap<>();
          spec.put("seq", value.get("seq"));
          List<Object> items = new ArrayList<>();
          Map<String, Object> idMap = new TreeMap<>();
          if (e.getKey().equals(lst)) {
            for (String i : order) {
              items.add(rename(i, m));
              Object id = storedIds.get(i);
              if (id != null) {
                idMap.put(rename(i, m), id);
              }
            }
          } else {
            for (Object i : (List<Object>) value.get("items")) {
              items.add(rename((String) i, m));
            }
            Object vIds = value.get("ids");
            if (vIds instanceof Map) {
              for (Map.Entry<String, Object> ie : ((Map<String, Object>) vIds).entrySet()) {
                idMap.put(rename(ie.getKey(), m), ie.getValue());
              }
            }
          }
          spec.put("items", items);
          if (!idMap.isEmpty()) {
            spec.put("ids", idMap);
          }
          newLists.put(rename(e.getKey(), m), spec);
        }
        j.put("lists", newLists);
      }
      doc.loadJson(j);
    }

    private static String rename(String key, Map<String, String> m) {
      for (Map.Entry<String, String> e : m.entrySet()) {
        if (key.equals(e.getKey())) {
          return e.getValue();
        }
        if (key.startsWith(e.getKey() + "/")) {
          return e.getValue() + key.substring(e.getKey().length());
        }
      }
      return key;
    }

    /** Adds one entry to the Blueprint's revision history naming the pairs. */
    void revisionEntry(String author, String date) {
      SpecReflection refl = set.refl;
      String lst = null;
      for (SpecSectionPosition p : SpecPlace.sectionPositions(refl, set.blueprintRoot)) {
        if (!p.isMember || p.member == null || p.member.kind != SpecFieldKind.LIST) {
          continue;
        }
        if (p.path.contains("-*")) {
          continue;
        }
        SpecClass el = refl.classNamed(p.member.elementType);
        if (el == null || !"RVENT".equals(el.sectionId)) {
          continue;
        }
        lst = p.path;
        break;
      }
      if (lst == null) {
        return;
      }
      List<String> items = doc.listItems(lst);
      String last =
          items.isEmpty() ? "" : SpecSetCheck.or(doc.formField(items.get(items.size() - 1) + "/content", "version"));
      String version = bump(last);
      String item = doc.addListItem(lst);
      List<String> names = new ArrayList<>();
      for (SpecSyncPair p : set.pairs()) {
        if (pairs.contains(p.sectionId) && !names.contains(p.sectionId)) {
          names.add(p.sectionId);
        }
      }
      List<String> others = new ArrayList<>();
      for (String n : set.names()) {
        if (!n.equals(name)) {
          others.add(n);
        }
      }
      String summary =
          "Backfilled from " + String.join(", ", others) + ": " + String.join(", ", names);
      doc.setFormField(item + "/content", "version", version);
      doc.setFormField(item + "/content", "date", date);
      doc.setFormField(item + "/content", "author", author);
      doc.setFormField(item + "/content", "summary", summary);
      changes.add(new SpecBackfillChange("", SpecBackfillChange.REVISION, item, null, "", version));
    }
  }
}
