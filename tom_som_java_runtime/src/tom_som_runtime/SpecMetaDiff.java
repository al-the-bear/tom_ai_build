package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Structural comparison of two {@link SomMetaNode} subtrees — a faithful port
 * of {@code spec_meta_diff.dart} / {@code spec_meta_diff.ts} /
 * {@code spec_meta_diff.go}.
 *
 * <p>{@link #somMetaNodeDiff} is the agreement oracle for DR8/DR24: the
 * generated facades embed populated metadata trees as static code (DR1 §3.2),
 * while {@link SomMetaBridge#buildSomMetaTree} derives the same tree from the
 * exported meta-JSON at runtime — the two must be field-for-field identical
 * for every node. Tests compare them with this method, which returns a
 * human-readable description of the <b>first</b> difference found (with the
 * node's position), or the empty string when the subtrees agree completely.
 *
 * <p>Java conventions (documented divergences from the sibling ports): the
 * "no difference" result is the empty string (the Go convention); optional
 * {@link Integer}s print as {@code null} when absent so the message strings
 * stay aligned with the sibling ports; and numeric annotation-argument values
 * compare by numeric value across {@code Integer}/{@code Long}/{@code Double}
 * (the JSON decoder yields boxed numbers where the generated literals are
 * Java constants).
 */
public final class SpecMetaDiff {
  private SpecMetaDiff() {}

  /**
   * Compares the {@code a} and {@code b} subtrees field by field (annotations,
   * names, kinds, form/document metadata, children and list element subtrees).
   *
   * <p>Returns {@code ""} when the subtrees are structurally identical, else a
   * description of the first difference, prefixed with the node's position (a
   * {@code /}-joined member-name chain rooted at the {@code <root>} marker).
   */
  public static String somMetaNodeDiff(SomMetaNode a, SomMetaNode b) {
    return diffAt(a, b, "<root>");
  }

  private static String diffAt(SomMetaNode a, SomMetaNode b, String at) {
    String d;
    d = diff(at, "className", a.className, b.className);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "memberName", a.memberName, b.memberName);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "sectionId", a.sectionId, b.sectionId);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "sectionIdPattern", a.sectionIdPattern, b.sectionIdPattern);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "kind", a.kind, b.kind);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "typeName", a.typeName, b.typeName);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "serializationOrder", a.serializationOrder, b.serializationOrder);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "min", a.min, b.min);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "unused", a.unused, b.unused);
    if (!d.isEmpty()) {
      return d;
    }
    d =
        diff(
            at,
            "contentType.type",
            contentTypeField(a.contentType, true),
            contentTypeField(b.contentType, true));
    if (!d.isEmpty()) {
      return d;
    }
    d =
        diff(
            at,
            "contentType.description",
            contentTypeField(a.contentType, false),
            contentTypeField(b.contentType, false));
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "contentHelp", a.contentHelp, b.contentHelp);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "headline", a.headline, b.headline);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "comment", a.comment, b.comment);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "docComment", a.docComment, b.docComment);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "classDocComment", a.classDocComment, b.classDocComment);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "mapsTo", a.mapsTo, b.mapsTo);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "detailedIn", a.detailedIn, b.detailedIn);
    if (!d.isEmpty()) {
      return d;
    }
    d = diff(at, "recursive", a.recursive, b.recursive);
    if (!d.isEmpty()) {
      return d;
    }
    d = metaFormDiff(at, a.form, b.form);
    if (!d.isEmpty()) {
      return d;
    }
    d = metaDocumentDiff(at, a.document, b.document);
    if (!d.isEmpty()) {
      return d;
    }
    d = metaSecondLevelDiff(at, a.secondLevelIds, b.secondLevelIds);
    if (!d.isEmpty()) {
      return d;
    }
    d = metaExtraDiff(at, a.extra, b.extra);
    if (!d.isEmpty()) {
      return d;
    }

    List<SomMetaNode> ac = a.children != null ? a.children : new ArrayList<>();
    List<SomMetaNode> bc = b.children != null ? b.children : new ArrayList<>();
    if (ac.size() != bc.size()) {
      return at
          + ": children count differs — "
          + ac.size()
          + " != "
          + bc.size()
          + " ("
          + jsonRepr(memberNames(ac))
          + " vs "
          + jsonRepr(memberNames(bc))
          + ")";
    }
    for (int i = 0; i < ac.size(); i++) {
      SomMetaNode ca = ac.get(i);
      String name = ca.memberName;
      if (name == null || name.isEmpty()) {
        name = ca.className;
      }
      d = diffAt(ca, bc.get(i), at + "/" + name);
      if (!d.isEmpty()) {
        return d;
      }
    }

    boolean aElem = a.elementNode != null;
    boolean bElem = b.elementNode != null;
    if (aElem != bElem) {
      return at + ": elementNode presence differs — " + aElem + " != " + bElem;
    }
    if (aElem) {
      return diffAt(a.elementNode, b.elementNode, at + "/§element");
    }
    return "";
  }

  private static String diff(String at, String field, Object va, Object vb) {
    if (metaValueEq(va, vb)) {
      return "";
    }
    return at + ": " + field + " differs — " + metaValueRepr(va) + " != " + metaValueRepr(vb);
  }

  private static List<String> memberNames(List<SomMetaNode> nodes) {
    List<String> names = new ArrayList<>(nodes.size());
    for (SomMetaNode n : nodes) {
      names.add(n.memberName);
    }
    return names;
  }

  private static Object contentTypeField(SomContentTypeMeta ct, boolean wantType) {
    if (ct == null) {
      return null;
    }
    return wantType ? ct.type : ct.description;
  }

  private static String metaFormDiff(String at, SomFormMeta a, SomFormMeta b) {
    boolean aSet = a != null;
    boolean bSet = b != null;
    if (aSet != bSet) {
      return at + ": form presence differs — " + aSet + " != " + bSet;
    }
    if (!aSet) {
      return "";
    }
    if (a.fields.size() != b.fields.size()) {
      return at + ": form field count differs — " + a.fields.size() + " != " + b.fields.size();
    }
    for (int i = 0; i < a.fields.size(); i++) {
      SomFormFieldMeta fa = a.fields.get(i);
      SomFormFieldMeta fb = b.fields.get(i);
      if (!Objects.equals(fa.name, fb.name)
          || !Objects.equals(fa.typeName, fb.typeName)
          || !Objects.equals(fa.description, fb.description)
          || fa.required != fb.required
          || !Objects.equals(fa.hint, fb.hint)
          || fa.order != fb.order) {
        return at + ": form field " + fa.name + " differs";
      }
    }
    return "";
  }

  private static String metaDocumentDiff(String at, SomDocMeta a, SomDocMeta b) {
    boolean aSet = a != null;
    boolean bSet = b != null;
    if (aSet != bSet) {
      return at + ": document presence differs — " + aSet + " != " + bSet;
    }
    if (!aSet) {
      return "";
    }
    if (!Objects.equals(a.name, b.name)) {
      return at + ": document.name differs — " + a.name + " != " + b.name;
    }
    if (!Objects.equals(a.description, b.description)) {
      return at + ": document.description differs";
    }
    if (!stringListEq(a.basedOn, b.basedOn)) {
      return at
          + ": document.basedOn differs — "
          + jsonRepr(a.basedOn)
          + " != "
          + jsonRepr(b.basedOn);
    }
    return "";
  }

  private static String metaSecondLevelDiff(
      String at, List<SomSecondLevelId> a, List<SomSecondLevelId> b) {
    List<SomSecondLevelId> al = a != null ? a : new ArrayList<>();
    List<SomSecondLevelId> bl = b != null ? b : new ArrayList<>();
    if (al.size() != bl.size()) {
      return at + ": secondLevelIds count differs — " + al.size() + " != " + bl.size();
    }
    for (int i = 0; i < al.size(); i++) {
      if (!Objects.equals(al.get(i).documentClass, bl.get(i).documentClass)
          || !Objects.equals(al.get(i).id, bl.get(i).id)) {
        return at + ": secondLevelIds[" + i + "] differs";
      }
    }
    return "";
  }

  private static String metaExtraDiff(String at, List<SomMetaExtra> a, List<SomMetaExtra> b) {
    List<SomMetaExtra> al = a != null ? a : new ArrayList<>();
    List<SomMetaExtra> bl = b != null ? b : new ArrayList<>();
    if (al.size() != bl.size()) {
      return at
          + ": extra annotation count differs — "
          + al.size()
          + " != "
          + bl.size()
          + " ("
          + jsonRepr(annotationNames(al))
          + " vs "
          + jsonRepr(annotationNames(bl))
          + ")";
    }
    for (int i = 0; i < al.size(); i++) {
      if (!Objects.equals(al.get(i).annotation, bl.get(i).annotation)
          || !metaValueEq(argsAsValue(al.get(i).args), argsAsValue(bl.get(i).args))) {
        return at
            + ": extra annotation "
            + al.get(i).annotation
            + " differs — "
            + jsonRepr(al.get(i).args)
            + " != "
            + jsonRepr(bl.get(i).args);
      }
    }
    return "";
  }

  private static List<String> annotationNames(List<SomMetaExtra> extras) {
    List<String> names = new ArrayList<>(extras.size());
    for (SomMetaExtra e : extras) {
      names.add(e.annotation);
    }
    return names;
  }

  /**
   * Widens a (possibly null) args map into an {@code Object} so the generic
   * {@link #metaValueEq} map branch applies (a null map equals an empty map).
   */
  private static Object argsAsValue(Map<String, Object> args) {
    if (args == null) {
      return new LinkedHashMap<String, Object>();
    }
    return args;
  }

  /**
   * Deep structural equality over JSON-shaped values (the annotation-argument
   * shapes: scalars, arrays, string-keyed maps). Numbers compare by numeric
   * value across {@code Integer}/{@code Long}/{@code Double} (see the class
   * doc).
   */
  private static boolean metaValueEq(Object a, Object b) {
    Double an = asDouble(a);
    if (an != null) {
      Double bn = asDouble(b);
      return bn != null && an.doubleValue() == bn.doubleValue();
    }
    if (a instanceof List) {
      if (!(b instanceof List)) {
        return false;
      }
      List<?> al = (List<?>) a;
      List<?> bl = (List<?>) b;
      if (al.size() != bl.size()) {
        return false;
      }
      for (int i = 0; i < al.size(); i++) {
        if (!metaValueEq(al.get(i), bl.get(i))) {
          return false;
        }
      }
      return true;
    }
    if (a instanceof Map) {
      if (!(b instanceof Map)) {
        return false;
      }
      Map<?, ?> am = (Map<?, ?>) a;
      Map<?, ?> bm = (Map<?, ?>) b;
      if (am.size() != bm.size()) {
        return false;
      }
      for (Map.Entry<?, ?> e : am.entrySet()) {
        if (!bm.containsKey(e.getKey()) || !metaValueEq(e.getValue(), bm.get(e.getKey()))) {
          return false;
        }
      }
      return true;
    }
    return Objects.equals(a, b);
  }

  private static Double asDouble(Object v) {
    if (v instanceof Integer) {
      return ((Integer) v).doubleValue();
    }
    if (v instanceof Long) {
      return ((Long) v).doubleValue();
    }
    if (v instanceof Double) {
      return (Double) v;
    }
    return null;
  }

  private static boolean stringListEq(List<String> a, List<String> b) {
    List<String> al = a != null ? a : new ArrayList<>();
    List<String> bl = b != null ? b : new ArrayList<>();
    if (al.size() != bl.size()) {
      return false;
    }
    for (int i = 0; i < al.size(); i++) {
      if (!Objects.equals(al.get(i), bl.get(i))) {
        return false;
      }
    }
    return true;
  }

  /**
   * Renders a scalar the way the sibling ports interpolate it into a diff
   * message ({@code null} for absent values).
   */
  private static String metaValueRepr(Object v) {
    if (v == null) {
      return "null";
    }
    if (v instanceof String) {
      return (String) v;
    }
    return String.valueOf(v);
  }

  /** Renders a value as compact JSON for diff messages. */
  private static String jsonRepr(Object v) {
    try {
      return Json.write(v);
    } catch (RuntimeException e) {
      return String.valueOf(v);
    }
  }
}
