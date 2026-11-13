package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * One extract entry: a single value the specification document stores, with
 * everything needed to trace it back ({@code codespecs_mapping.md} §1.1.1,
 * "Entry").
 */
public final class CodeSpecsExtractEntry {
  /** The {@code CE-*} code of the area this entry was collected for. */
  public final String areaCode;

  /**
   * The section id of the leaf the value sits on ({@code @SectionId}, else the
   * model field name).
   */
  public final String sectionId;

  /**
   * The enclosing section instance's headline, copy-only like {@link #value}:
   * the document's <b>stored</b> headline for the class node the leaf sits
   * under (YRD3), else the class's {@code @Headline} type default (YRD4), else
   * {@code null}. Gives naming rule N1 a real source — never a derivation.
   */
  public final String headline;

  /**
   * The nearest enclosing list-item instance's <b>stored</b> section id (the
   * {@code <!--[…]-->} id the document serializes), copy-only auxiliary trace
   * data; {@code null} when no enclosing instance stores one. The render-time
   * positional default is a derivation and is never carried. A {@code DocRef}
   * back-link still names the extract token, not this id
   * ({@code codespecs_mapping.md} §9.3).
   */
  public final String instanceId;

  /** The document path of the leaf — the source location. */
  public final String path;

  /** The model class declaring the leaf. */
  public final String className;

  /** The model field name of the leaf. */
  public final String fieldName;

  /**
   * The form-field name when the value is one field of a {@code @Form} section;
   * {@code null} for a content, enum, scalar or scalar-list leaf.
   */
  public final String formField;

  /** The {@code CodeSpecPart.*} value that routed this entry here, verbatim. */
  public final String routedBy;

  /**
   * Where that {@code @CodeSpecKind} was declared — the class name, or
   * {@code Class.field} for a field-level override.
   */
  public final String routedAt;

  /** The {@code @CodeSpecKind} {@code note}, verbatim; {@code null} when it carries none. */
  public final String routingNote;

  /**
   * The generation units the entry goes to (SOM §11.2,
   * {@code codespecs_mapping.md} §1.1.1): the nearest stored {@code units} at
   * the entry's path or any ancestor path, split at its commas; when no section
   * on the way stores one, the default — every unit of the document's register
   * with a mapping for the entry's area, in register order
   * ({@link SpecGenerationUnits#specGenerationUnits}). Empty when the document
   * declares no unit that holds the area.
   */
  public final List<String> units;

  /** The stored value, <b>verbatim</b>. Never assembled, reformatted or trimmed. */
  public final String value;

  /** An entry carrying no {@link #units}. */
  public CodeSpecsExtractEntry(
      String areaCode,
      String sectionId,
      String headline,
      String instanceId,
      String path,
      String className,
      String fieldName,
      String formField,
      String routedBy,
      String routedAt,
      String routingNote,
      String value) {
    this(areaCode, sectionId, headline, instanceId, path, className, fieldName,
        formField, routedBy, routedAt, routingNote, Collections.emptyList(), value);
  }

  public CodeSpecsExtractEntry(
      String areaCode,
      String sectionId,
      String headline,
      String instanceId,
      String path,
      String className,
      String fieldName,
      String formField,
      String routedBy,
      String routedAt,
      String routingNote,
      List<String> units,
      String value) {
    this.areaCode = areaCode;
    this.sectionId = sectionId;
    this.headline = headline;
    this.instanceId = instanceId;
    this.path = path;
    this.className = className;
    this.fieldName = fieldName;
    this.formField = formField;
    this.routedBy = routedBy;
    this.routedAt = routedAt;
    this.routingNote = routingNote;
    this.units = units == null
        ? Collections.emptyList()
        : Collections.unmodifiableList(new ArrayList<>(units));
    this.value = value;
  }

  @Override
  public String toString() {
    return "CodeSpecsExtractEntry(" + areaCode + ", " + path + ")";
  }
}
