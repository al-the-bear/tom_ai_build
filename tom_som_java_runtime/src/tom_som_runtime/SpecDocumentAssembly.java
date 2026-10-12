package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Assembling one spec document from fragments written in parallel — a port of
 * {@code spec_document_assembly.dart}.
 *
 * <p>A large document is often authored in parts — one group, or one agent, per
 * set of sections — each part a document of its own holding a subset of the
 * sections. References between parts can only be judged on the whole: the
 * instance tier resolves a {@code refersTo} against the document it is given, so
 * a part validated alone reports every reference into another part as dangling.
 * {@link #assemble} is the step that produces the whole.
 *
 * <p>The merge is over the plain-data stores ({@link SpecDocument#toJson}), and
 * it is <b>refusing</b>: a value two fragments both write — a content path, a
 * form field, a list, a headline, a code-spec location — is an overlap, and an
 * assembly with any overlap yields no document. Choosing a winner would make the
 * result depend on fragment order, and two parts writing one place is an
 * authoring conflict the parts' authors have to settle.
 */
public final class SpecDocumentAssembly {
  /** The stores whose entries are a single value at a path. */
  private static final List<String> PATH_STORES = Arrays.asList("content", "headlines", "codeSpecs");

  /** The fixed order overlaps are reported in. */
  private static final List<String> STORE_ORDER =
      Arrays.asList("content", "forms", "lists", "headlines", "codeSpecs");

  /** The assembled document; {@code null} when there is any overlap. */
  public final SpecDocument document;

  /** Every overlap, in store order and then path order. */
  public final List<SpecAssemblyOverlap> overlaps;

  /** Creates a result; {@code document} is null when {@code overlaps} is not empty. */
  public SpecDocumentAssembly(SpecDocument document, List<SpecAssemblyOverlap> overlaps) {
    this.document = document;
    this.overlaps = Collections.unmodifiableList(new ArrayList<>(overlaps));
  }

  /** Whether the fragments assembled. */
  public boolean ok() {
    return overlaps.isEmpty();
  }

  /**
   * Merges {@code fragments} — (name, document) pairs, in order — into one
   * document. A fragment name may be given only once.
   *
   * @throws IllegalArgumentException when two fragments share a name
   */
  @SuppressWarnings("unchecked")
  public static SpecDocumentAssembly assemble(
      List<? extends Map.Entry<String, SpecDocument>> fragments) {
    Set<String> names = new HashSet<>();
    for (Map.Entry<String, SpecDocument> f : fragments) {
      if (!names.add(f.getKey())) {
        throw new IllegalArgumentException("fragment name given twice: " + f.getKey());
      }
    }
    // store → key → writer fragments; key is the path, or `path\u0000field`.
    Map<String, Map<String, List<String>>> writers = new LinkedHashMap<>();
    Map<String, Map<String, Object>> merged = new LinkedHashMap<>();
    for (String s : STORE_ORDER) {
      writers.put(s, new TreeMap<>());
      merged.put(s, new LinkedHashMap<>());
    }

    for (Map.Entry<String, SpecDocument> fragment : fragments) {
      String name = fragment.getKey();
      Map<String, Object> json = fragment.getValue().toJson();
      for (String store : PATH_STORES) {
        Object entries = json.get(store);
        if (!(entries instanceof Map)) {
          continue;
        }
        for (Map.Entry<String, Object> e : ((Map<String, Object>) entries).entrySet()) {
          writers.get(store).computeIfAbsent(e.getKey(), k -> new ArrayList<>()).add(name);
          merged.get(store).putIfAbsent(e.getKey(), e.getValue());
        }
      }
      Object forms = json.get("forms");
      if (forms instanceof Map) {
        for (Map.Entry<String, Object> e : ((Map<String, Object>) forms).entrySet()) {
          String path = e.getKey();
          Map<String, Object> target =
              (Map<String, Object>)
                  merged.get("forms").computeIfAbsent(path, k -> new LinkedHashMap<String, Object>());
          for (Map.Entry<String, Object> fe : ((Map<String, Object>) e.getValue()).entrySet()) {
            writers
                .get("forms")
                .computeIfAbsent(path + "\u0000" + fe.getKey(), k -> new ArrayList<>())
                .add(name);
            target.putIfAbsent(fe.getKey(), fe.getValue());
          }
        }
      }
      Object lists = json.get("lists");
      if (lists instanceof Map) {
        for (Map.Entry<String, Object> e : ((Map<String, Object>) lists).entrySet()) {
          writers.get("lists").computeIfAbsent(e.getKey(), k -> new ArrayList<>()).add(name);
          merged.get("lists").putIfAbsent(e.getKey(), e.getValue());
        }
      }
    }

    // TreeMap keys are in UTF-16 code-unit order, the order Dart's sort gives.
    List<SpecAssemblyOverlap> overlaps = new ArrayList<>();
    for (String store : STORE_ORDER) {
      for (Map.Entry<String, List<String>> e : writers.get(store).entrySet()) {
        List<String> who = e.getValue();
        if (who.size() < 2) {
          continue;
        }
        String key = e.getKey();
        int sep = key.indexOf('\u0000');
        overlaps.add(
            new SpecAssemblyOverlap(
                store,
                sep < 0 ? key : key.substring(0, sep),
                sep < 0 ? null : key.substring(sep + 1),
                who));
      }
    }
    if (!overlaps.isEmpty()) {
      return new SpecDocumentAssembly(null, overlaps);
    }
    Map<String, Object> stores = new LinkedHashMap<>();
    for (String store : STORE_ORDER) {
      if (!merged.get(store).isEmpty()) {
        stores.put(store, merged.get(store));
      }
    }
    SpecDocument document = new SpecDocument();
    document.loadJson(stores);
    return new SpecDocumentAssembly(document, overlaps);
  }

  /**
   * Merges {@code fragments} — name → document, in the map's iteration order
   * (pass a {@link LinkedHashMap} to fix it) — into one document.
   */
  public static SpecDocumentAssembly assemble(Map<String, SpecDocument> fragments) {
    return assemble(new ArrayList<>(fragments.entrySet()));
  }
}
