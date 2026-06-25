package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * A sparse, live instance of a TomSpecs document — a faithful port of
 * {@code spec_document.dart} / {@code spec_document.py}.
 *
 * <p>The structure is defined by the {@link SpecModel} class graph; this holds
 * only the <i>values</i> the user/agent has actually set, keyed by the
 * globally-unique section-ID path. Three sparse stores cover the writable field
 * kinds: content/scalar leaves, {@code @Form} sections, and lists. List item
 * paths are {@code "<listPath>-<seq>"} where {@code seq} is a per-list monotonic
 * counter that never reuses a number.
 */
public final class SpecDocument {
  private final Map<String, String> content = new LinkedHashMap<>();
  private final Map<String, Map<String, String>> form = new LinkedHashMap<>();
  private final Map<String, List<String>> listItems = new LinkedHashMap<>();
  private final Map<String, Integer> listSeq = new LinkedHashMap<>();

  // --- content ------------------------------------------------------------

  public String content(String path) {
    return content.get(path);
  }

  /** Sets the content string at {@code path}. An empty value clears it. */
  public void setContent(String path, String value) {
    if (value.isEmpty()) {
      content.remove(path);
    } else {
      content.put(path, value);
    }
  }

  // --- forms --------------------------------------------------------------

  public String formField(String path, String fieldName) {
    Map<String, String> fields = form.get(path);
    return fields == null ? null : fields.get(fieldName);
  }

  /**
   * Sets form {@code fieldName} at {@code path}. An empty value clears that field
   * (and the whole form entry once its last field is gone).
   */
  public void setFormField(String path, String fieldName, String value) {
    Map<String, String> fields = form.computeIfAbsent(path, k -> new LinkedHashMap<>());
    if (value.isEmpty()) {
      fields.remove(fieldName);
      if (fields.isEmpty()) {
        form.remove(path);
      }
    } else {
      fields.put(fieldName, value);
    }
  }

  // --- lists --------------------------------------------------------------

  public List<String> listItems(String listPath) {
    List<String> items = listItems.get(listPath);
    return items == null ? new ArrayList<>() : new ArrayList<>(items);
  }

  /** Appends a new item to the list at {@code listPath} and returns its path. */
  public String addListItem(String listPath) {
    int seq = listSeq.getOrDefault(listPath, 0) + 1;
    listSeq.put(listPath, seq);
    String itemPath = listPath + "-" + seq;
    listItems.computeIfAbsent(listPath, k -> new ArrayList<>()).add(itemPath);
    return itemPath;
  }

  /**
   * Removes the list item at {@code itemPath} along with every value nested
   * beneath it. The counter is left untouched so future items keep getting fresh
   * sequence numbers (no renumbering).
   */
  public boolean removeListItem(String itemPath) {
    String owningList = null;
    for (Map.Entry<String, List<String>> e : listItems.entrySet()) {
      if (e.getValue().contains(itemPath)) {
        owningList = e.getKey();
        break;
      }
    }
    if (owningList == null) {
      return false;
    }
    List<String> items = listItems.get(owningList);
    items.remove(itemPath);
    if (items.isEmpty()) {
      listItems.remove(owningList);
    }
    purgeUnder(itemPath);
    return true;
  }

  private boolean isUnder(String key, String prefix) {
    return key.equals(prefix)
        || key.startsWith(prefix + "/")
        || key.startsWith(prefix + "-");
  }

  private void purgeUnder(String prefix) {
    content.keySet().removeIf(k -> isUnder(k, prefix));
    form.keySet().removeIf(k -> isUnder(k, prefix));
    listItems.keySet().removeIf(k -> isUnder(k, prefix));
    listSeq.keySet().removeIf(k -> isUnder(k, prefix));
  }

  // --- queries ------------------------------------------------------------

  public boolean isEmpty() {
    return content.isEmpty() && form.isEmpty() && listItems.isEmpty();
  }

  /**
   * Whether any value exists at {@code prefix} or nested beneath it — the
   * structural "empty = no value" test (the exact inverse of the purge
   * predicate).
   */
  public boolean hasValuesUnder(String prefix) {
    for (String k : content.keySet()) {
      if (isUnder(k, prefix)) {
        return true;
      }
    }
    for (String k : form.keySet()) {
      if (isUnder(k, prefix)) {
        return true;
      }
    }
    for (String k : listItems.keySet()) {
      if (isUnder(k, prefix)) {
        return true;
      }
    }
    return false;
  }

  public Set<String> contentPaths() {
    return content.keySet();
  }

  public Set<String> formPaths() {
    return form.keySet();
  }

  public Set<String> listPaths() {
    return listItems.keySet();
  }

  public Set<String> formFieldNames(String path) {
    Map<String, String> fields = form.get(path);
    return fields == null ? Collections.emptySet() : fields.keySet();
  }

  public int listItemCount(String listPath) {
    List<String> items = listItems.get(listPath);
    return items == null ? 0 : items.size();
  }

  // --- persistence --------------------------------------------------------

  /**
   * A plain-data view of every value held, for persistence. Only non-empty
   * stores are included, and each is sorted by full section-ID path so the saved
   * file diffs/merges cleanly. The inverse of {@link #loadJson}.
   */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    if (!content.isEmpty()) {
      out.put("content", new TreeMap<>(content));
    }
    if (!form.isEmpty()) {
      Map<String, Object> forms = new TreeMap<>();
      for (Map.Entry<String, Map<String, String>> e : form.entrySet()) {
        forms.put(e.getKey(), new TreeMap<>(e.getValue()));
      }
      out.put("forms", forms);
    }
    if (!listItems.isEmpty()) {
      Map<String, Object> lists = new TreeMap<>();
      for (Map.Entry<String, List<String>> e : listItems.entrySet()) {
        Map<String, Object> spec = new LinkedHashMap<>();
        spec.put("seq", listSeq.getOrDefault(e.getKey(), e.getValue().size()));
        spec.put("items", new ArrayList<>(e.getValue()));
        lists.put(e.getKey(), spec);
      }
      out.put("lists", lists);
    }
    return out;
  }

  /**
   * Replaces every store from a {@link #toJson}-shaped map. Coerces leaf values
   * to strings and skips unknown/empty entries.
   */
  @SuppressWarnings("unchecked")
  public void loadJson(Map<String, Object> json) {
    content.clear();
    form.clear();
    listItems.clear();
    listSeq.clear();

    Object rawContent = json.get("content");
    if (rawContent instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawContent).entrySet()) {
        if (e.getValue() != null) {
          content.put(e.getKey(), e.getValue().toString());
        }
      }
    }

    Object rawForms = json.get("forms");
    if (rawForms instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawForms).entrySet()) {
        if (e.getValue() instanceof Map) {
          Map<String, String> entry = new LinkedHashMap<>();
          for (Map.Entry<String, Object> fe :
              ((Map<String, Object>) e.getValue()).entrySet()) {
            if (fe.getValue() != null) {
              entry.put(fe.getKey(), fe.getValue().toString());
            }
          }
          if (!entry.isEmpty()) {
            form.put(e.getKey(), entry);
          }
        }
      }
    }

    Object rawLists = json.get("lists");
    if (rawLists instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawLists).entrySet()) {
        if (e.getValue() instanceof Map) {
          Map<String, Object> spec = (Map<String, Object>) e.getValue();
          List<String> itemList = new ArrayList<>();
          Object items = spec.get("items");
          if (items instanceof List) {
            for (Object it : (List<Object>) items) {
              itemList.add(it.toString());
            }
          }
          if (!itemList.isEmpty()) {
            listItems.put(e.getKey(), itemList);
          }
          Object seq = spec.get("seq");
          if (seq instanceof Number) {
            listSeq.put(e.getKey(), ((Number) seq).intValue());
          } else if (seq instanceof String && isSignedInt((String) seq)) {
            listSeq.put(e.getKey(), Integer.parseInt((String) seq));
          } else {
            listSeq.put(e.getKey(), itemList.size());
          }
        }
      }
    }
  }

  private static boolean isSignedInt(String s) {
    String t = s.startsWith("-") ? s.substring(1) : s;
    if (t.isEmpty()) {
      return false;
    }
    for (int i = 0; i < t.length(); i++) {
      if (!Character.isDigit(t.charAt(i))) {
        return false;
      }
    }
    return true;
  }
}
