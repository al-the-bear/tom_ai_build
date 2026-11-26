package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * What {@code deriveFields} would write for one link finding, collected by
 * {@link SpecLinkValidator} beside the finding ({@code tom_specs_model_rules.md}
 * §9.7).
 *
 * <p>Kinds: {@link #SET} (the value at {@link #path} / {@link #field}, field
 * {@code null}: content), {@link #APPEND} (add {@link #value} to the ids of the
 * reference field), {@link #ADD_ROW} (add a row to the list at {@link #path}:
 * {@code <member>#<field>} → value in {@link #values}), {@link #REMOVE_ROW} (the
 * row at {@link #path}; {@link #empty}: it holds no value already),
 * {@link #LIST} (make the list at {@link #path} hold one element per tuple of
 * {@link #tuples}), {@link #COPY} (write the copy at {@link #path} from
 * {@link #holder}).
 *
 * <p>The order things are written in is recorded: {@link #values} keeps the
 * order an {@code addRow} writes its values in, {@link #tupleKeys} the
 * derivation's order of the target places of every tuple.
 */
public final class SpecLinkFix {
  public static final String SET = "set";
  public static final String APPEND = "append";
  public static final String ADD_ROW = "addRow";
  public static final String REMOVE_ROW = "removeRow";
  public static final String LIST = "list";
  public static final String COPY = "copy";

  /** The {@code deriveFields} step that writes it. */
  public final int step;
  /** One of {@link #SET}, {@link #APPEND}, {@link #ADD_ROW}, {@link #REMOVE_ROW}, {@link #LIST}, {@link #COPY}. */
  public final String kind;
  public final String path;
  /** The form field ({@link #SET}, {@link #APPEND}); {@code null}: the content. */
  public final String field;
  /** The value ({@link #SET}, {@link #APPEND}); {@code null} for the other kinds. */
  public final String value;
  /** {@code <member>#<field>} → value ({@link #ADD_ROW}), in the order written; empty otherwise. */
  public final Map<String, String> values;
  /** One target place → value map per wanted element ({@link #LIST}); empty otherwise. */
  public final List<Map<String, String>> tuples;
  /** The target places of every tuple, in the derivation's order ({@link #LIST}). */
  public final List<String> tupleKeys;
  /** The holder the copy is written from ({@link #COPY}); {@code null} otherwise. */
  public final String holder;
  /** Whether the row holds no value already ({@link #REMOVE_ROW}). */
  public final boolean empty;

  private SpecLinkFix(
      int step,
      String kind,
      String path,
      String field,
      String value,
      Map<String, String> values,
      List<Map<String, String>> tuples,
      List<String> tupleKeys,
      String holder,
      boolean empty) {
    this.step = step;
    this.kind = kind;
    this.path = path;
    this.field = field;
    this.value = value;
    this.values = values;
    this.tuples = tuples;
    this.tupleKeys = tupleKeys;
    this.holder = holder;
    this.empty = empty;
  }

  /** Sets the value at {@code path} / {@code field} ({@code null}: content) to {@code value}. */
  public static SpecLinkFix ofSet(int step, String path, String field, String value) {
    return new SpecLinkFix(step, SET, path, field, value, Collections.emptyMap(),
        Collections.emptyList(), Collections.emptyList(), null, false);
  }

  /** Adds {@code value} to the ids of the reference field at {@code path} / {@code field}. */
  public static SpecLinkFix ofAppend(String path, String field, String value) {
    return new SpecLinkFix(1, APPEND, path, field, value, Collections.emptyMap(),
        Collections.emptyList(), Collections.emptyList(), null, false);
  }

  /**
   * Adds a row to the list at {@code path}: {@code <member>#<field>} (or
   * {@code <member>}, a content value) → value, written in the map's order.
   */
  public static SpecLinkFix ofAddRow(int step, String path, Map<String, String> values) {
    return new SpecLinkFix(step, ADD_ROW, path, null, null,
        Collections.unmodifiableMap(new LinkedHashMap<>(values)), Collections.emptyList(),
        Collections.emptyList(), null, false);
  }

  /** Removes the row at {@code path}; {@code empty}: it holds no value already. */
  public static SpecLinkFix ofRemoveRow(String path, boolean empty) {
    return new SpecLinkFix(1, REMOVE_ROW, path, null, null, Collections.emptyMap(),
        Collections.emptyList(), Collections.emptyList(), null, empty);
  }

  /**
   * Makes the list at {@code path} hold one element per tuple (target place →
   * value); {@code tupleKeys} are the target places in the derivation's order.
   */
  public static SpecLinkFix ofList(
      String path, List<Map<String, String>> tuples, List<String> tupleKeys) {
    List<Map<String, String>> copied = new ArrayList<>();
    for (Map<String, String> t : tuples) {
      copied.add(Collections.unmodifiableMap(new LinkedHashMap<>(t)));
    }
    return new SpecLinkFix(2, LIST, path, null, null, Collections.emptyMap(),
        Collections.unmodifiableList(copied),
        Collections.unmodifiableList(new ArrayList<>(tupleKeys)), null, false);
  }

  /** Writes the copy at {@code path} from {@code holder}. */
  public static SpecLinkFix ofCopy(String path, String holder) {
    return new SpecLinkFix(2, COPY, path, null, null, Collections.emptyMap(),
        Collections.emptyList(), Collections.emptyList(), holder, false);
  }

  /** The keys of {@link #values} in their written order. */
  public List<String> orderedValueKeys() {
    return new ArrayList<>(values.keySet());
  }

  /** The target places of the tuples in the derivation's order. */
  public List<String> orderedTupleKeys() {
    return tupleKeys;
  }

  /** The fix as JSON, unset parts left out (for comparing runtimes). */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("step", step);
    out.put("kind", kind);
    out.put("path", path);
    switch (kind) {
      case SET:
      case APPEND:
        out.put("field", field);
        out.put("value", value);
        break;
      case ADD_ROW:
        out.put("values", new LinkedHashMap<String, Object>(values));
        break;
      case REMOVE_ROW:
        out.put("empty", empty);
        break;
      case LIST:
        {
          List<Object> ts = new ArrayList<>();
          for (Map<String, String> t : tuples) {
            ts.add(new LinkedHashMap<String, Object>(t));
          }
          out.put("tuples", ts);
          break;
        }
      case COPY:
        out.put("holder", holder);
        break;
      default:
        break;
    }
    return out;
  }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof SpecLinkFix)) {
      return false;
    }
    SpecLinkFix f = (SpecLinkFix) o;
    return toJson().equals(f.toJson())
        && orderedValueKeys().equals(f.orderedValueKeys())
        && tupleKeys.equals(f.tupleKeys);
  }

  @Override
  public int hashCode() {
    return toJson().hashCode();
  }

  @Override
  public String toString() {
    return Json.write(toJson());
  }
}
