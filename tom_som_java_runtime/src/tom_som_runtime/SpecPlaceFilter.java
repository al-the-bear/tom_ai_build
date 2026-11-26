package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * An entry filter of the link vocabulary ({@code tom_specs_model_rules.md}
 * §9.7): {@code <SECTIONID>}, {@code ./<SECTIONID>} or
 * {@code <SECTIONID>.<field>=<value>[|<value>…]}, optionally {@code ./}-scoped.
 *
 * <p>It selects the entries (list elements of the class with that section id)
 * one of whose own forms holds one of {@link #values} in {@link #field}; without
 * a field every entry. {@code countOf} counts the entries it selects, a
 * {@code where:} keeps the elements or rows it selects.
 */
public final class SpecPlaceFilter {
  /** The text it was parsed from. */
  public final String text;
  /**
   * Whether it is written {@code ./…}: only the entries beneath the nearest list
   * element (for {@code countOf}: beneath the section holding the form).
   */
  public final boolean scoped;
  /** The section id of the entries. */
  public final String sectionId;
  /** The form field compared, or {@code null} for every entry. */
  public final String field;
  /** The values accepted, in written order; empty exactly when {@link #field} is null. */
  public final List<String> values;

  public SpecPlaceFilter(
      String text, boolean scoped, String sectionId, String field, List<String> values) {
    this.text = text;
    this.scoped = scoped;
    this.sectionId = sectionId;
    this.field = field;
    this.values = values;
  }

  /** Parses {@code text}; throws a {@link SpecPlaceException} ({@code malformed}) when it is not a filter. */
  public static SpecPlaceFilter parse(String text) {
    SpecPlaceFilter f = tryParse(text);
    if (f != null) {
      return f;
    }
    throw new SpecPlaceException(
        SpecPlaceProblem.MALFORMED,
        text,
        "is not a filter (`<SECTIONID>[.<field>=<value>[|<value>…]]`, optionally `./`-scoped)");
  }

  /** Parses {@code text}, or returns {@code null} when it is not a filter. */
  public static SpecPlaceFilter tryParse(String text) {
    if (text == null) {
      return null;
    }
    boolean scoped = text.startsWith("./");
    String body = scoped ? text.substring(2) : text;
    int dot = body.indexOf('.');
    String id = dot < 0 ? body : body.substring(0, dot);
    if (!SpecPlace.SEGMENT.matcher(id).matches()) {
      return null;
    }
    if (dot < 0) {
      return new SpecPlaceFilter(text, scoped, id, null, Collections.emptyList());
    }
    int eq = body.indexOf('=', dot);
    if (eq < 0) {
      return null;
    }
    String name = body.substring(dot + 1, eq);
    if (!SpecPlace.FIELD.matcher(name).matches()) {
      return null;
    }
    List<String> values = Arrays.asList(body.substring(eq + 1).split("\\|", -1));
    for (String v : values) {
      if (v.isEmpty()) {
        return null;
      }
    }
    return new SpecPlaceFilter(
        text, scoped, id, name, Collections.unmodifiableList(new ArrayList<>(values)));
  }

  /**
   * Whether an entry whose {@link #field} holds {@code stored} (values trimmed,
   * as many as its forms hold) is selected.
   */
  public boolean matches(Collection<String> stored) {
    if (field == null) {
      return true;
    }
    if (stored == null) {
      return false;
    }
    for (String v : stored) {
      if (values.contains(v.trim())) {
        return true;
      }
    }
    return false;
  }

  /** The place of the entries: {@link #sectionId}, scoped as the filter is. */
  public SpecPlace place() {
    return new SpecPlace(
        scoped ? "./" + sectionId : sectionId, scoped, Collections.emptyList(), sectionId, null);
  }

  /**
   * Resolves the entries under {@code anchor} as {@link SpecPlace#resolve} does,
   * and checks that {@link #field} is a field of one of the entry's own forms (a
   * form member of the entry, or its content form). Throws a
   * {@link SpecPlaceException} when it does not resolve.
   */
  public SpecPlaceResolution resolve(SpecReflection refl, String anchor) {
    SpecPlaceResolution r;
    try {
      r = place().resolve(refl, anchor);
    } catch (SpecPlaceException e) {
      throw new SpecPlaceException(e.problem, text, e.detail);
    }
    if (field != null) {
      SpecClass cls = refl.classNamed(r.className);
      boolean found = false;
      if (r.kind == SpecPlaceKind.SECTION && cls != null) {
        for (SpecField f : cls.fields) {
          if (f.kind != SpecFieldKind.FORM) {
            continue;
          }
          for (FormFieldSpec ff : f.formFields) {
            if (ff.name.equals(field)) {
              found = true;
            }
          }
        }
      }
      if (!found) {
        throw new SpecPlaceException(
            SpecPlaceProblem.NO_SUCH_FIELD,
            text,
            "names " + sectionId + "." + field + ", which no form of " + sectionId + " holds");
      }
    }
    return r;
  }

  /** The parsed parts, for the corpus. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("scoped", scoped);
    out.put("sectionId", sectionId);
    if (field != null) {
      out.put("field", field);
      out.put("values", new ArrayList<Object>(values));
    }
    return out;
  }

  /** The filter as written. */
  @Override
  public String toString() {
    return text;
  }
}
