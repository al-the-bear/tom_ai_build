package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** A single form field within a {@code @Form} content section. */
public final class FormFieldSpec {
  public final String name;
  public final String label;
  public final String type;
  public final String hint;
  public final boolean required;
  /**
   * Enum constant names when {@link #type} is a model enum; empty for non-enum
   * field types. Lets consumers validate and convert values without the
   * analyzer.
   */
  public final List<String> enumValues;
  /**
   * The registry key(s) this field's value is an id drawn from, each written
   * {@code <SECTIONID>.<formFieldName>}; empty for a non-reference field. A
   * reference field holds a free-text id that must already be declared by some
   * entry of the named registry, so a runtime can resolve it and report a
   * dangling id instead of generating broken code.
   */
  public final List<String> refersTo;
  /**
   * The entries this field's value counts ({@code Field.countOf}, vsctsa43),
   * each a section id {@code X} (every entry) or {@code X.f=v} (the entries one
   * of whose own forms holds {@code v} in form field {@code f}); empty for a
   * field that states no count. The instance tier checks the stated number
   * against the entries the document holds.
   */
  public final List<String> countOf;
  /**
   * The operands this field's value is the product of ({@code Field.productOf},
   * uamtc10), each a field of the same form or {@code FORMSID.field} of the
   * sibling form at {@code <owner>/FORMSID}; empty for a field that states no
   * product. The instance tier holds the stated number to it
   * ({@code derivedValueMismatch}).
   */
  public final List<String> productOf;
  /**
   * The field of the same form whose number this field ranks, highest first
   * ({@code Field.rankOf}, uamtc10); {@code null} for a field that states no
   * rank.
   */
  public final String rankOf;
  /**
   * Whether the value is code rather than prose ({@code Field.code}): the
   * markdown codec writes it as an inline code span and unwraps it on import
   * (SOM §11.4 rule 8). Omitted from the export when {@code false}.
   */
  public final boolean code;
  /**
   * Whether a reference field holds a comma-separated list of ids
   * ({@code Field.multiple}, uamtc17); a reference field without it holds one,
   * and the instance tier reports a list in it ({@code multipleReferences}).
   */
  public final boolean multiple;

  public FormFieldSpec(
      String name, String label, String type, String hint, boolean required) {
    this(name, label, type, hint, required, List.of(), List.of());
  }

  public FormFieldSpec(
      String name,
      String label,
      String type,
      String hint,
      boolean required,
      List<String> enumValues,
      List<String> refersTo) {
    this(name, label, type, hint, required, enumValues, refersTo, List.of());
  }

  public FormFieldSpec(
      String name,
      String label,
      String type,
      String hint,
      boolean required,
      List<String> enumValues,
      List<String> refersTo,
      List<String> countOf) {
    this(name, label, type, hint, required, enumValues, refersTo, countOf, false);
  }

  public FormFieldSpec(
      String name,
      String label,
      String type,
      String hint,
      boolean required,
      List<String> enumValues,
      List<String> refersTo,
      List<String> countOf,
      boolean code) {
    this(name, label, type, hint, required, enumValues, refersTo, countOf, code, List.of(), null);
  }

  public FormFieldSpec(
      String name,
      String label,
      String type,
      String hint,
      boolean required,
      List<String> enumValues,
      List<String> refersTo,
      List<String> countOf,
      boolean code,
      List<String> productOf,
      String rankOf) {
    this(name, label, type, hint, required, enumValues, refersTo, countOf, code, productOf, rankOf, false);
  }

  public FormFieldSpec(
      String name,
      String label,
      String type,
      String hint,
      boolean required,
      List<String> enumValues,
      List<String> refersTo,
      List<String> countOf,
      boolean code,
      List<String> productOf,
      String rankOf,
      boolean multiple) {
    this.name = name;
    this.label = label;
    this.type = type;
    this.hint = hint;
    this.required = required;
    this.enumValues = enumValues;
    this.refersTo = refersTo;
    this.countOf = countOf;
    this.code = code;
    this.productOf = productOf;
    this.rankOf = rankOf;
    this.multiple = multiple;
  }

  public static FormFieldSpec fromJson(Map<String, Object> j) {
    String name = (String) j.get("name");
    Object label = j.get("label");
    Object type = j.get("type");
    return new FormFieldSpec(
        name,
        label != null ? label.toString() : name,
        type != null ? type.toString() : "String",
        j.get("hint") != null ? j.get("hint").toString() : null,
        Boolean.TRUE.equals(j.get("required")),
        stringList(j.get("enumValues")),
        stringList(j.get("refersTo")),
        stringList(j.get("countOf")),
        Boolean.TRUE.equals(j.get("code")),
        stringList(j.get("productOf")),
        j.get("rankOf") != null ? j.get("rankOf").toString() : null,
        Boolean.TRUE.equals(j.get("multiple")));
  }

  private static List<String> stringList(Object raw) {
    List<String> out = new ArrayList<>();
    if (raw instanceof List) {
      for (Object e : (List<?>) raw) {
        out.add(e == null ? "" : e.toString());
      }
    }
    return out;
  }
}
