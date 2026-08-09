package tom_som_runtime;

import java.time.LocalDate;
import java.util.List;

/**
 * The generic, meta-model-driven modification API (YRD7) — a faithful port of
 * {@code spec_editor.dart} / {@code spec_editor.py}.
 *
 * <p>{@code SpecEditor} lets a consumer walk any document's meta tree and
 * create/modify/delete sections, list items, headlines, ids, content and
 * <b>typed</b> form fields <i>without a generated facade</i>: every operation
 * resolves its path against the {@link SpecModel} first
 * ({@link SpecReflection#resolve}) and converts values at the store boundary
 * through the same {@link SpecTypedValues} helpers the generated accessors call
 * — so a typed facade is provably a thin layer over exactly this API.
 *
 * <p>Typed contract (mirrored by all nine runtimes):
 *
 * <ul>
 *   <li>{@code int} / {@code double} / {@code num} / {@code bool} values are
 *       native on both sides; Java has no dynamic value type, so they travel
 *       through the {@code Object} in/out positions as {@link Integer},
 *       {@link Double}, {@link Number} and {@link Boolean};
 *   <li>enum values travel as validated <b>constant-name strings</b> at this
 *       generic layer ({@code "high"}), because the generic API has no generated
 *       enum types — only the facade layer converts to native constants;
 *   <li>{@code null} (or {@code ""}) clears a value (D4);
 *   <li>reads are forgiving (unparsable stored text reads as {@code null}),
 *       writes are strict ({@link IllegalArgumentException} for a wrong type or
 *       an out-of-domain enum name).
 * </ul>
 */
public final class SpecEditor {
  /** The document being edited (the sparse value stores). */
  public final SpecDocument document;

  /** The value-free meta-model queries the editor validates against. */
  public final SpecReflection reflection;

  public SpecEditor(SpecDocument document, SpecReflection reflection) {
    this.document = document;
    this.reflection = reflection;
  }

  /** Convenience: builds the editor for {@code document} over {@code model}. */
  public static SpecEditor forModel(SpecDocument document, SpecModel model) {
    return new SpecEditor(document, new SpecReflection(model));
  }

  // --- resolution -----------------------------------------------------------

  /**
   * Resolves {@code path} against the meta-model, throwing
   * {@link IllegalArgumentException} for a dangling path — the strict companion
   * to {@link SpecReflection#resolve}.
   */
  public SpecResolution resolve(String path) {
    SpecResolution r = reflection.resolve(path);
    if (r == null) {
      throw new IllegalArgumentException(
          "\"" + path + "\" does not resolve against the model");
    }
    return r;
  }

  // --- value leaves (content / scalar / enum / scalar list item) -------------

  /**
   * The typed value at the value leaf {@code path}, or {@code null} when unset.
   *
   * <p>The runtime type follows the model: {@code int}/{@code double}/{@code num}
   * /{@code bool} scalars return the parsed native value, enum leaves the
   * validated constant name, everything else the raw string. Throws
   * {@link IllegalArgumentException} when {@code path} is not a value leaf.
   */
  public Object value(String path) {
    SpecResolution r = valueLeaf(path);
    String raw = document.content(path);
    if (raw == null || raw.isEmpty()) {
      return null;
    }
    if (r.kind == SpecNodeKind.ENUM_VALUE) {
      return SpecTypedValues.somParseEnumName(raw, enumValuesOf(r.field));
    }
    return parseScalar(raw, scalarBase(r.field != null ? r.field.type : null));
  }

  /**
   * Sets the value leaf at {@code path} to {@code v}, converting at the store
   * boundary.
   *
   * <p>{@code null} clears. For typed scalars {@code v} must be the native type
   * (or a {@link String}, taken verbatim); for enum leaves {@code v} must be one
   * of the field's constant names. Throws {@link IllegalArgumentException} for a
   * non-leaf path, a wrong value type, or an out-of-domain enum name.
   */
  public void setValue(String path, Object v) {
    SpecResolution r = valueLeaf(path);
    document.setContent(path, format(v, r.kind, r.field, path, null, null));
  }

  private SpecResolution valueLeaf(String path) {
    SpecResolution r = resolve(path);
    if (!r.isValueLeaf()) {
      throw new IllegalArgumentException(
          "\"" + path + "\" is a " + r.kind.value + " node, not a value leaf");
    }
    return r;
  }

  // --- headlines (YRD3) -----------------------------------------------------

  /**
   * The stored headline at {@code path}, or {@code null} when the section renders
   * its effective default title.
   */
  public String headline(String path) {
    resolve(path);
    return document.headline(path);
  }

  /**
   * Sets the stored headline at {@code path}; empty/{@code null} returns the
   * section to its default title.
   */
  public void setHeadline(String path, String value) {
    resolve(path);
    document.setHeadline(path, value == null ? "" : value);
  }

  // --- typed form fields ----------------------------------------------------

  /**
   * The typed value of form {@code field} at the {@code @Form} section
   * {@code path}, or {@code null} when unset.
   *
   * <p>Reads the form store and parses per the declared field type (enum fields
   * return the validated constant name). Throws {@link IllegalArgumentException}
   * for a non-form path or an unknown field name.
   */
  public Object formValue(String path, String field) {
    FormFieldSpec ff = formFieldSpec(path, field);
    String raw = document.formField(path, field);
    if (raw == null || raw.isEmpty()) {
      return null;
    }
    if (!ff.enumValues.isEmpty()) {
      return SpecTypedValues.somParseEnumName(raw, ff.enumValues);
    }
    return parseScalar(raw, scalarBase(ff.type));
  }

  /**
   * Sets form {@code field} at the {@code @Form} section {@code path} to the
   * typed value {@code v} ({@code null} clears), converting through the shared
   * boundary helpers.
   *
   * <p>Throws {@link IllegalArgumentException} for a wrong value type or an
   * out-of-domain enum name.
   */
  public void setFormValue(String path, String field, Object v) {
    FormFieldSpec ff = formFieldSpec(path, field);
    String stored;
    if (!ff.enumValues.isEmpty()) {
      stored = SpecTypedValues.somFormatEnumName(
          stringOrNull(v, path, field), ff.enumValues);
    } else {
      stored = format(v, SpecNodeKind.SCALAR, null, path, ff.type, field);
    }
    document.setFormField(path, field, stored);
  }

  /**
   * The form-field specs of the {@code @Form} section at {@code path}, in
   * declaration order — the meta a generic editor UI renders from.
   */
  public List<FormFieldSpec> formFields(String path) {
    SpecResolution r = resolve(path);
    if (r.kind != SpecNodeKind.FORM) {
      throw new IllegalArgumentException(
          "\"" + path + "\" is a " + r.kind.value + " node, not a @Form section");
    }
    return r.field != null && r.field.formFields != null ? r.field.formFields : List.of();
  }

  private FormFieldSpec formFieldSpec(String path, String field) {
    for (FormFieldSpec ff : formFields(path)) {
      if (ff.name.equals(field)) {
        return ff;
      }
    }
    throw new IllegalArgumentException("\"" + field + "\" is not a form field of " + path);
  }

  // --- structural operations ------------------------------------------------

  /**
   * Appends a new item to the list at {@code listPath}, dated today, and returns
   * its stable item path.
   */
  public String addListItem(String listPath) {
    return addListItem(listPath, null, null, null);
  }

  /**
   * Appends a new item to the list at {@code listPath} with an explicit
   * {@code sectionId} (uniqueness-checked against the list's other items) and
   * returns its stable item path.
   */
  public String addListItem(String listPath, String sectionId) {
    return addListItem(listPath, sectionId, null, null);
  }

  /**
   * Appends a new item to the list at {@code listPath} and returns its stable
   * item path.
   *
   * <p>When the list field carries a {@code @SectionIdPattern} and no explicit
   * {@code sectionId} is given, a fresh id is generated from the pattern
   * ({@link SpecSectionId#generateListItemSectionId}, dated {@code month}/{@code
   * day} — each defaulting to today). An explicit {@code sectionId} is
   * uniqueness-checked against the list's other items. Throws
   * {@link IllegalArgumentException} when {@code listPath} is not a list.
   */
  public String addListItem(String listPath, String sectionId, Integer month, Integer day) {
    SpecResolution r = resolve(listPath);
    if (r.kind != SpecNodeKind.LIST) {
      throw new IllegalArgumentException(
          "\"" + listPath + "\" is a " + r.kind.value + " node, not a list");
    }
    String id = sectionId;
    String pattern = r.field != null ? r.field.sectionIdPattern : null;
    if (id == null && pattern != null) {
      LocalDate today = LocalDate.now();
      id =
          SpecSectionId.generateListItemSectionId(
              pattern,
              month != null ? month : today.getMonthValue(),
              day != null ? day : today.getDayOfMonth(),
              document.listItemSectionIds(listPath));
    }
    return document.addListItem(listPath, id);
  }

  /**
   * Removes the list item at {@code itemPath} with every value beneath it.
   * Returns {@code true} when an item was found and removed.
   */
  public boolean removeListItem(String itemPath) {
    return document.removeListItem(itemPath);
  }

  /**
   * Clears every value at {@code path} and beneath it — content, form entries,
   * nested list items, stored headlines and ids — returning the subtree to the
   * untouched "empty = no value" state (D4). The node itself remains addressable
   * (structure lives in the model, not the document).
   */
  public void clearSection(String path) {
    resolve(path);
    document.removeValuesUnder(path);
  }

  // --- conversion -----------------------------------------------------------

  /** Strips a trailing {@code ?} from a declared type name. */
  private static String scalarBase(String typeName) {
    if (typeName == null) {
      return null;
    }
    return typeName.endsWith("?")
        ? typeName.substring(0, typeName.length() - 1)
        : typeName;
  }

  /** Parses stored text per the declared scalar base type. */
  private static Object parseScalar(String raw, String base) {
    if ("int".equals(base)) {
      return SpecTypedValues.somParseInt(raw);
    }
    if ("double".equals(base)) {
      return SpecTypedValues.somParseDouble(raw);
    }
    if ("num".equals(base)) {
      return SpecTypedValues.somParseNum(raw);
    }
    if ("bool".equals(base)) {
      return SpecTypedValues.somParseBool(raw);
    }
    return raw;
  }

  private static List<String> enumValuesOf(SpecField field) {
    return field != null && field.enumValues != null ? field.enumValues : List.of();
  }

  /**
   * Formats {@code v} for the store per the leaf's declared type; strings pass
   * through verbatim (the plain-text serialization is authoritative).
   *
   * <p>{@code typeName} overrides the field's own type (the form-field route,
   * which carries its type on the {@link FormFieldSpec} rather than the
   * {@link SpecField}), and {@code where} names the offending slot in the error.
   */
  private String format(
      Object v, SpecNodeKind kind, SpecField field, String path, String typeName, String where) {
    if (v == null) {
      return "";
    }
    if (kind == SpecNodeKind.ENUM_VALUE) {
      return SpecTypedValues.somFormatEnumName(
          stringOrNull(v, path, where != null ? where : path), enumValuesOf(field));
    }
    String base = scalarBase(typeName != null ? typeName : (field != null ? field.type : null));
    if ("int".equals(base)) {
      if (v instanceof Integer) {
        return SpecTypedValues.somFormatInt((Integer) v);
      }
    } else if ("double".equals(base)) {
      if (v instanceof Double) {
        return SpecTypedValues.somFormatDouble((Double) v);
      }
      if (v instanceof Integer) {
        return SpecTypedValues.somFormatDouble(((Integer) v).doubleValue());
      }
    } else if ("num".equals(base)) {
      if (v instanceof Number) {
        return SpecTypedValues.somFormatNum((Number) v);
      }
    } else if ("bool".equals(base)) {
      if (v instanceof Boolean) {
        return SpecTypedValues.somFormatBool((Boolean) v);
      }
    }
    if (v instanceof String) {
      return (String) v;
    }
    throw new IllegalArgumentException(
        "\"" + v + "\" at " + (where != null ? where : path)
            + ": wrong value type for a " + (base != null ? base : "String") + " field");
  }

  private String stringOrNull(Object v, String path, String field) {
    if (v == null) {
      return null;
    }
    if (v instanceof String) {
      return (String) v;
    }
    throw new IllegalArgumentException(
        "\"" + field + "\": expected a String for this field of " + path);
  }
}
