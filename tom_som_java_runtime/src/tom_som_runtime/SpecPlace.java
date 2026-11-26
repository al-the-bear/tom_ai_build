package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Pattern;

/**
 * A place of the link vocabulary as written ({@code tom_specs_model_rules.md}
 * §9.7): {@code ./} scope, {@code /} segments, section id and slot — a port of
 * {@code spec_place.dart}.
 *
 * <p>A place names a section, a list, a form field, a heading, a content value
 * or a registry id: {@code FRED.description}, {@code FRE.@headline},
 * {@code FRE-REQU-LST}, {@code ./RQDEP}, {@code FRE/REQDEP/RQDEP.description},
 * {@code <SECTIONID>.@content}, {@code <SECTIONID>.@sectionId}. Resolution is
 * value-free, like {@link SpecReflection}: it says where in a document the place
 * is stored, with every list item below the anchor written {@code <list>-*}, and
 * never reads a value.
 */
public final class SpecPlace {
  static final Pattern SEGMENT = Pattern.compile("[A-Za-z0-9][A-Za-z0-9-]*");
  static final Pattern SLOT = Pattern.compile("@?[A-Za-z_][A-Za-z0-9_]*");
  static final Pattern FIELD = Pattern.compile("[A-Za-z_][A-Za-z0-9_]*");

  /** The text it was parsed from. */
  public final String text;
  /**
   * Whether it is written {@code ./…}: resolved beneath the nearest list element
   * at or above the anchor.
   */
  public final boolean scoped;
  /** The section ids written before the last {@code /}, which the path to the place holds in order. */
  public final List<String> prefix;
  /** The section id the place names. */
  public final String sectionId;
  /**
   * The part after the dot: a form field name, {@code @headline}, {@code @content},
   * {@code @sectionId}; {@code null} for the section, list or form itself.
   */
  public final String slot;

  public SpecPlace(String text, boolean scoped, List<String> prefix, String sectionId, String slot) {
    this.text = text;
    this.scoped = scoped;
    this.prefix = prefix;
    this.sectionId = sectionId;
    this.slot = slot;
  }

  /** Parses {@code text}; throws a {@link SpecPlaceException} ({@code malformed}) when it is not a place. */
  public static SpecPlace parse(String text) {
    SpecPlace p = tryParse(text);
    if (p != null) {
      return p;
    }
    throw new SpecPlaceException(
        SpecPlaceProblem.MALFORMED,
        text,
        "is not a place (`<SECTIONID>[.<field>|.@headline|.@content|.@sectionId]`, "
            + "optionally `./`-scoped or a `/` path)");
  }

  /** Parses {@code text}, or returns {@code null} when it is not a place. */
  public static SpecPlace tryParse(String text) {
    if (text == null) {
      return null;
    }
    boolean scoped = text.startsWith("./");
    String body = scoped ? text.substring(2) : text;
    if (body.isEmpty()) {
      return null;
    }
    List<String> segments = new ArrayList<>(Arrays.asList(body.split("/", -1)));
    String last = segments.remove(segments.size() - 1);
    String id = last;
    String slot = null;
    int dot = last.indexOf('.');
    if (dot >= 0) {
      id = last.substring(0, dot);
      slot = last.substring(dot + 1);
    }
    if (!SEGMENT.matcher(id).matches()) {
      return null;
    }
    for (String s : segments) {
      if (!SEGMENT.matcher(s).matches()) {
        return null;
      }
    }
    if (slot != null && !SLOT.matcher(slot).matches()) {
      return null;
    }
    return new SpecPlace(text, scoped, Collections.unmodifiableList(segments), id, slot);
  }

  /** The parsed parts, for the corpus. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("scoped", scoped);
    out.put("prefix", new ArrayList<Object>(prefix));
    out.put("sectionId", sectionId);
    if (slot != null) {
      out.put("slot", slot);
    }
    return out;
  }

  /** The place as written. */
  @Override
  public String toString() {
    return text;
  }

  /**
   * Resolves the place under {@code anchor}, a document path of a section (a
   * root, a complex or section member, or a list item); throws a
   * {@link SpecPlaceException} when it does not resolve.
   *
   * <p>The place is looked for in the subtree of the anchor's class — beneath the
   * nearest list element at or above the anchor when it is {@code ./}-scoped —
   * among the positions whose section id is {@link #sectionId} and whose path
   * holds the {@link #prefix} ids in order (only {@code -LST} containers and the
   * scope's own id may lie between them). More than one such position is
   * {@code ambiguous}.
   */
  public SpecPlaceResolution resolve(SpecReflection refl, String anchor) {
    SpecPlaceWalk.Scope scope = SpecPlaceWalk.scopeOf(refl, anchor, scoped, text);
    Map<String, SpecPlaceWalk.Position> byPath = new TreeMap<>();
    for (SpecPlaceWalk.Position pos : SpecPlaceWalk.positions(refl, scope)) {
      if (pos.node.id.equals(sectionId)
          && SpecPlaceWalk.pathMatches(pos.ids.subList(0, pos.ids.size() - 1), prefix)) {
        byPath.put(pos.node.path, pos);
      }
    }
    if (byPath.isEmpty()) {
      throw new SpecPlaceException(
          SpecPlaceProblem.UNRESOLVED, text, "resolves to no section beneath " + scope.path);
    }
    if (byPath.size() > 1) {
      throw new SpecPlaceException(
          SpecPlaceProblem.AMBIGUOUS,
          text,
          "is ambiguous: " + sectionId + " is reached at " + String.join(", ", byPath.keySet())
              + " — write it as a `/` path");
    }
    return withSlot(byPath.values().iterator().next());
  }

  private SpecPlaceResolution result(
      SpecPlaceWalk.Position pos, SpecPlaceKind kind, String path, FormFieldSpec formField) {
    return new SpecPlaceResolution(this, kind, path, pos.node.className, pos.ids, formField);
  }

  private SpecPlaceResolution withSlot(SpecPlaceWalk.Position pos) {
    SpecPlaceWalk.Node n = pos.node;
    if (slot == null) {
      switch (n.shape) {
        case "list":
          return result(pos, SpecPlaceKind.LIST, n.path, null);
        case "form":
          return result(pos, SpecPlaceKind.FORM, n.path, null);
        case "content":
          return result(pos, SpecPlaceKind.CONTENT, n.path, null);
        default:
          return result(pos, SpecPlaceKind.SECTION, n.path, null);
      }
    }
    if (slot.equals("@headline")) {
      return result(pos, SpecPlaceKind.HEADLINE, n.path, null);
    }
    if (slot.equals("@content")) {
      if (n.contentPath == null) {
        throw new SpecPlaceException(
            SpecPlaceProblem.NO_CONTENT,
            text,
            "names @content of " + sectionId + ", which holds no content value");
      }
      return result(pos, SpecPlaceKind.CONTENT, n.contentPath, null);
    }
    if (slot.equals(SpecSectionId.K_SECTION_ID_SLOT)) {
      if (!n.isListElement) {
        throw new SpecPlaceException(
            SpecPlaceProblem.NOT_LIST_ELEMENT,
            text,
            "names @sectionId of " + sectionId + ", which is no list element");
      }
      return result(pos, SpecPlaceKind.SECTION_ID, n.path, null);
    }
    if (slot.startsWith("@")) {
      throw new SpecPlaceException(
          SpecPlaceProblem.RESERVED_SLOT,
          text,
          "names the slot " + slot + " — \"@\" is reserved for @headline, @content and @sectionId");
    }
    FormFieldSpec ff = null;
    for (FormFieldSpec f : n.formFields) {
      if (f.name.equals(slot)) {
        ff = f;
        break;
      }
    }
    if (ff == null || n.formPath == null) {
      throw new SpecPlaceException(
          SpecPlaceProblem.NO_SUCH_FIELD,
          text,
          "names " + sectionId + "." + slot + ", which is no form field");
    }
    return result(pos, SpecPlaceKind.FORM_FIELD, n.formPath, ff);
  }

  /**
   * Every {@code @SameAs} copy the document root {@code rootType} reaches, each
   * with its holder ({@code tom_specs_model_rules.md} §9.7, invariant
   * {@code SAME-AS}): among the positions of the copy's class in the root that
   * are no copy themselves, the one whose section-id path ends with
   * {@code holder}, or — without {@code holder} — the one there is. In position
   * order.
   */
  public static List<SpecSameAsBinding> sameAsBindings(SpecReflection refl, String rootType) {
    List<SpecSameAsBinding> out = new ArrayList<>();
    SpecPlaceWalk.Scope scope = SpecPlaceWalk.rootScope(refl, rootType);
    if (scope == null) {
      return out;
    }
    List<SpecPlaceWalk.Position> sections = new ArrayList<>();
    for (SpecPlaceWalk.Position p : SpecPlaceWalk.positions(refl, scope)) {
      if (p.node.shape.equals("section") && p.node.ownNode) {
        sections.add(p);
      }
    }
    for (SpecPlaceWalk.Position copy : sections) {
      if (copy.member == null) {
        continue;
      }
      SpecSameAs sameAs = copy.member.sameAs();
      if (sameAs == null) {
        continue;
      }
      String type = copy.node.className;
      List<String> holderTail =
          sameAs.holder == null || sameAs.holder.isEmpty()
              ? null
              : Arrays.asList(sameAs.holder.split("/", -1));
      List<SpecPlaceWalk.Position> holders = new ArrayList<>();
      for (SpecPlaceWalk.Position p : sections) {
        if (!p.node.className.equals(type)) {
          continue;
        }
        if (p.member != null && p.member.sameAs() != null) {
          continue;
        }
        if (holderTail != null && !SpecPlaceWalk.endsWith(p.ids, holderTail)) {
          continue;
        }
        holders.add(p);
      }
      if (holders.size() == 1) {
        out.add(
            new SpecSameAsBinding(
                rootType, type, copy.node.path, copy.ids,
                holders.get(0).node.path, holders.get(0).ids, null));
      } else {
        out.add(
            new SpecSameAsBinding(
                rootType, type, copy.node.path, copy.ids, null, null,
                holders.isEmpty() ? SpecPlaceProblem.UNRESOLVED : SpecPlaceProblem.AMBIGUOUS));
      }
    }
    return out;
  }

  /**
   * Every section position of the document root {@code rootType}, in walk order:
   * a class reached again on its own path is not descended into, and a
   * {@code @Reference} member's target is not walked.
   */
  public static List<SpecSectionPosition> sectionPositions(SpecReflection refl, String rootType) {
    List<SpecSectionPosition> out = new ArrayList<>();
    SpecPlaceWalk.Scope scope = SpecPlaceWalk.rootScope(refl, rootType);
    if (scope == null) {
      return out;
    }
    for (SpecPlaceWalk.Position p : SpecPlaceWalk.positions(refl, scope)) {
      out.add(
          new SpecSectionPosition(
              p.node.path, p.node.className, p.ids, !p.node.ownNode, p.member));
    }
    return out;
  }
}
