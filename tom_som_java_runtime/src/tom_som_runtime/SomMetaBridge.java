package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Bridge from the meta-JSON class graph ({@link SpecModel}) to the canonical
 * metadata tree ({@link SomMetaTree}, DR1 §3.1) — a faithful port of
 * {@code spec_meta_bridge.dart} / {@code spec_meta_bridge.ts}.
 *
 * <p>The generated facades (DR8) emit populated {@code SomMetaTree}s directly;
 * every consumer that only has the exported spec-model meta-data (the
 * conformance harness, tooling) builds its tree here. The expansion follows
 * the same walk {@link SpecReflection#resolve} performs — crucially, a node's
 * {@link SomMetaNode#sectionId} is the <b>field-level</b> id exactly as
 * exported ({@code field.sectionId}), so the tree's path grammar stays
 * byte-compatible with the paths a {@link SpecDocument} is keyed by. (DR1
 * §2.2's "field id, else target-class id" resolution is applied at
 * <i>export</i> time by the model exporter / DR8 generator, not re-derived
 * here.)
 *
 * <p>Recursive class references become terminal re-entry nodes
 * ({@link SomMetaNode#recursive}), mirroring how the generated chains
 * terminate.
 */
public final class SomMetaBridge {
  private SomMetaBridge() {}

  /**
   * Annotation names that have a dedicated {@link SomMetaNode} slot; everything
   * else is captured losslessly into {@link SomMetaNode#extra}.
   */
  private static final Set<String> SLOTTED_ANNOTATIONS =
      new HashSet<>(
          List.of(
              "SectionId",
              "SectionIdPattern",
              "SerializationOrder",
              "Min",
              "Unused",
              "ContentType",
              "ContentHelp",
              "Headline",
              "Comment",
              "Form",
              "Document",
              "MapsTo",
              "DetailedIn",
              "SecondLevelSectionId"));

  /**
   * Builds the wired {@link SomMetaTree} for one document root of
   * {@code model}.
   *
   * <p>When {@code rootType} is {@code null} (or empty) the model's first root
   * is used; otherwise the root is looked up via {@link SpecModel#rootByType}
   * (throwing its {@link IllegalArgumentException} for an unknown type).
   * Children are ordered by {@code @SerializationOrder} (annotated members
   * first, then declaration order), which is the sibling emission order of the
   * hierarchical YAML format (DR1 §2.3).
   */
  public static SomMetaTree buildSomMetaTree(SpecModel model, String rootType) {
    SpecRoot root;
    if (rootType == null || rootType.isEmpty()) {
      root = model.roots.isEmpty() ? model.rootByType("") : model.roots.get(0);
    } else {
      root = model.rootByType(rootType);
    }
    SpecClass cls = model.classNamed(root.type);

    String sectionId = root.sectionId;
    String docComment = root.doc;
    String classDoc = null;
    String classSectionId = null;
    String rootHeadline = null;
    String mapsTo = null;
    String detailedIn = null;
    List<SpecAnnotation> annotations = new ArrayList<>();
    List<SomMetaNode> children = new ArrayList<>();
    if (cls != null) {
      if (isAbsent(sectionId)) {
        sectionId = cls.sectionId;
      }
      if (isAbsent(docComment)) {
        docComment = cls.doc;
      }
      classDoc = cls.doc;
      classSectionId = cls.sectionId;
      rootHeadline = cls.headline;
      mapsTo = cls.mapsTo;
      detailedIn = cls.detailedIn;
      annotations = cls.annotations;
      Set<String> stack = new HashSet<>();
      stack.add(root.type);
      children = childNodes(model, cls, stack);
    }
    SomMetaNode rootNode = new SomMetaNode(root.type, SomMetaKind.SECTION, root.type);
    rootNode.sectionId = sectionId;
    rootNode.classSectionId = classSectionId;
    rootNode.headline = rootHeadline;
    rootNode.docComment = docComment;
    rootNode.classDocComment = classDoc;
    rootNode.mapsTo = mapsTo;
    rootNode.detailedIn = detailedIn;
    rootNode.document =
        new SomDocMeta(
            root.title, root.description != null ? root.description : "", basedOn(cls));
    rootNode.secondLevelIds = secondLevelIds(annotations);
    rootNode.extra = extras(annotations);
    rootNode.children = children;
    return new SomMetaTree(rootNode);
  }

  private static boolean isAbsent(String s) {
    return s == null || s.isEmpty();
  }

  private static List<String> basedOn(SpecClass cls) {
    List<String> out = new ArrayList<>();
    if (cls == null) {
      return out;
    }
    SpecAnnotation ann = cls.annotation("Document");
    if (ann == null) {
      return out;
    }
    Object raw = ann.argument("basedOn");
    if (raw instanceof List) {
      for (Object e : (List<?>) raw) {
        out.add(str(e));
      }
    }
    return out;
  }

  /**
   * Coerces an annotation argument value to its string form ({@code ""} for
   * {@code null}, matching the other ports' {@code String(x || '')}).
   */
  private static String str(Object v) {
    if (v instanceof String) {
      return (String) v;
    }
    if (v instanceof Integer) {
      return String.valueOf(v);
    }
    if (v instanceof Double) {
      double d = (Double) v;
      if (d == Math.rint(d) && !Double.isInfinite(d)) {
        return String.valueOf((int) d);
      }
      return "";
    }
    if (v instanceof Boolean) {
      return ((Boolean) v) ? "true" : "false";
    }
    return "";
  }

  private static List<SomMetaNode> childNodes(
      SpecModel model, SpecClass cls, Set<String> stack) {
    final int fallback = 1 << 30;
    List<int[]> order = new ArrayList<>(); // [declIndex, effectiveOrder]
    for (int i = 0; i < cls.fields.size(); i++) {
      Integer so = cls.fields.get(i).serializationOrder;
      order.add(new int[] {i, so != null ? so : fallback});
    }
    order.sort(
        (a, b) -> a[1] != b[1] ? Integer.compare(a[1], b[1]) : Integer.compare(a[0], b[0]));
    List<SomMetaNode> out = new ArrayList<>(order.size());
    for (int[] entry : order) {
      out.add(fieldNode(model, cls, cls.fields.get(entry[0]), stack));
    }
    return out;
  }

  private static SomMetaNode fieldNode(
      SpecModel model, SpecClass owner, SpecField field, Set<String> stack) {
    String kind = field.kind.raw; // SpecFieldKind raws equal the SomMetaKind values.
    SpecClass target = null;
    boolean recursive = false;
    List<SomMetaNode> children = new ArrayList<>();
    SomMetaNode elementNode = null;

    if (field.kind == SpecFieldKind.COMPLEX || field.kind == SpecFieldKind.SECTION) {
      target = model.classNamed(field.type);
      if (target != null) {
        if (stack.contains(target.name)) {
          recursive = true;
        } else {
          stack.add(target.name);
          children = childNodes(model, target, stack);
          stack.remove(target.name);
        }
      }
    } else if (field.kind == SpecFieldKind.LIST && field.elementIsComplex) {
      SpecClass element = model.classNamed(field.elementType);
      if (element != null) {
        List<SomMetaNode> elementChildren = new ArrayList<>();
        boolean elementRecursive = false;
        if (stack.contains(element.name)) {
          elementRecursive = true;
        } else {
          stack.add(element.name);
          elementChildren = childNodes(model, element, stack);
          stack.remove(element.name);
        }
        elementNode = new SomMetaNode(element.name, SomMetaKind.COMPLEX, element.name);
        elementNode.classSectionId = element.sectionId;
        elementNode.headline = element.headline;
        elementNode.docComment = element.doc;
        elementNode.classDocComment = element.doc;
        elementNode.mapsTo = element.mapsTo;
        elementNode.detailedIn = element.detailedIn;
        elementNode.recursive = elementRecursive;
        elementNode.children = elementChildren;
      }
    }

    SomContentTypeMeta contentType = null;
    if (!isAbsent(field.contentType)) {
      String description = "";
      SpecAnnotation ctAnn = field.annotation("ContentType");
      if (ctAnn != null) {
        description = str(ctAnn.argument("description"));
      }
      contentType = new SomContentTypeMeta(field.contentType, description);
    }

    String comment = null;
    SpecAnnotation commentAnn = field.annotation("Comment");
    if (commentAnn != null) {
      String text = str(commentAnn.argument("text"));
      comment = text.isEmpty() ? null : text;
    }

    SomFormMeta form = null;
    if (field.kind == SpecFieldKind.FORM) {
      List<SomFormFieldMeta> fields = new ArrayList<>(field.formFields.size());
      for (int i = 0; i < field.formFields.size(); i++) {
        FormFieldSpec ff = field.formFields.get(i);
        fields.add(new SomFormFieldMeta(ff.name, ff.type, ff.label, ff.required, ff.hint, i));
      }
      form = new SomFormMeta(fields);
    }

    String className = owner.name;
    String docComment = field.doc;
    String classDoc = null;
    String classSectionId = null;
    String mapsTo = null;
    String detailedIn = null;
    if (target != null) {
      className = target.name;
      if (isAbsent(docComment)) {
        docComment = target.doc;
      }
      classDoc = target.doc;
      classSectionId = target.sectionId;
      mapsTo = target.mapsTo;
      detailedIn = target.detailedIn;
    }
    String typeName = field.type;
    if (isAbsent(typeName)) {
      typeName = field.elementType;
    }
    if (isAbsent(typeName)) {
      typeName = field.enumType;
    }
    if (isAbsent(typeName)) {
      typeName = "String";
    }

    SomMetaNode node = new SomMetaNode(className, kind, typeName);
    node.memberName = field.name;
    node.sectionId = field.sectionId;
    node.classSectionId = classSectionId;
    node.sectionIdPattern = field.sectionIdPattern;
    node.serializationOrder = field.serializationOrder;
    node.min = field.min;
    node.unused = field.annotation("Unused") != null;
    node.contentType = contentType;
    node.contentHelp = field.help;
    // YRD4: the field-level @Headline wins over the target class's.
    node.headline = field.headline != null ? field.headline : (target != null ? target.headline : null);
    node.comment = comment;
    node.docComment = docComment;
    node.classDocComment = classDoc;
    node.form = form;
    node.mapsTo = mapsTo;
    node.detailedIn = detailedIn;
    node.secondLevelIds = secondLevelIds(field.annotations);
    node.extra = extras(field.annotations);
    node.recursive = recursive;
    node.children = children;
    node.elementNode = elementNode;
    return node;
  }

  private static List<SomSecondLevelId> secondLevelIds(List<SpecAnnotation> annotations) {
    List<SomSecondLevelId> out = new ArrayList<>();
    for (SpecAnnotation a : annotations) {
      if (!a.name.equals("SecondLevelSectionId")) {
        continue;
      }
      out.add(new SomSecondLevelId(str(a.argument("documentClass")), str(a.argument("id"))));
    }
    return out;
  }

  private static List<SomMetaExtra> extras(List<SpecAnnotation> annotations) {
    List<SomMetaExtra> out = new ArrayList<>();
    for (SpecAnnotation a : annotations) {
      if (SLOTTED_ANNOTATIONS.contains(a.name)) {
        continue;
      }
      Map<String, Object> args =
          a.arguments != null ? a.arguments : new LinkedHashMap<>();
      out.add(new SomMetaExtra(a.name, args));
    }
    return out;
  }
}
