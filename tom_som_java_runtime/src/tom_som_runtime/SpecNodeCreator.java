package tom_som_runtime;

import java.time.LocalDate;

/**
 * Meta-model-validated node creation for a live {@link SpecDocument}
 * ({@code llm_and_d4rt_tools.md} §5 "constrained node creation") — a faithful
 * port of {@code spec_node_creation.dart}.
 *
 * <p>Every node a script or tool adds passes through this single gate, so the
 * document can only grow in ways the {@link SpecModel} permits for the parent.
 * The rules are the {@code tom_specs_model_rules.md} §10.2 <i>structural</i>
 * rules — but read from the model meta-data the runtime already carries
 * ({@link SpecField#kind}, {@link SpecField#sectionIdPattern},
 * {@link SpecField#min}), <b>not</b> from the analyzer-backed authoring
 * validator in {@code tom_specs_clitool}. The clitool validates the <i>authored
 * model graph</i>; this validates a <i>document mutation against that model</i>.
 * They are different layers and the runtime keeps its lean dependency footprint.
 *
 * <p>{@link #checkAddNode} is the single, value-aware rule-check entry point
 * (static, so editors and the engine reuse it); {@link #add} applies it and
 * performs the mutation only when it returns {@code null}, so an illegal add
 * never touches the tree.
 */
public final class SpecNodeCreator {
  /** The meta-model the mutation is validated against. */
  public final SpecModel model;

  /** The live document the child is added to. */
  public final SpecDocument document;

  public SpecNodeCreator(SpecModel model, SpecDocument document) {
    this.model = model;
    this.document = document;
  }

  /** {@link #checkAddNode(SpecModel, SpecDocument, String, String, String)} with no proposed id. */
  public static SpecCreationError checkAddNode(
      SpecModel model, SpecDocument document, String parentPath, String childSegment) {
    return checkAddNode(model, document, parentPath, childSegment, null);
  }

  /**
   * Validates adding child {@code childSegment} under {@code parentPath} against
   * {@code model}, consulting {@code document} for cardinality. Returns
   * {@code null} when the add is legal, otherwise the {@link SpecCreationError}
   * describing the first rule it breaks.
   *
   * <p>This performs <b>no mutation</b>; it is the shared rule-check that
   * {@link #add} (and any editor) calls before touching the tree.
   */
  public static SpecCreationError checkAddNode(
      SpecModel model,
      SpecDocument document,
      String parentPath,
      String childSegment,
      String itemId) {
    SpecReflection refl = new SpecReflection(model);

    // 1. The parent must resolve to a class-bearing node (root / complex /
    //    section / complex list item). Leaves, lists and dangling paths cannot
    //    own named children.
    SpecResolution parent = refl.resolve(parentPath);
    if (parent == null || parent.targetClass == null) {
      String what = parent == null ? "does not resolve" : "is a " + parent.kind.value;
      return error(
          parentPath,
          childSegment,
          SpecCreationCode.NOT_A_CONTAINER,
          "parent path " + what + " and cannot own child nodes");
    }
    SpecClass parentClass = parent.targetClass;

    // 2. The child segment must name a declared field of the parent's class.
    SpecField field = fieldForSegment(parentClass, childSegment);
    if (field == null) {
      return error(
          parentPath,
          childSegment,
          SpecCreationCode.UNKNOWN_CHILD,
          "\"" + childSegment + "\" is not a child of " + parentClass.name);
    }

    String childPath = SpecPaths.join(parentPath, childSegment);

    if (field.kind == SpecFieldKind.LIST) {
      // 3. List item: validate a caller-proposed id. Lists have no upper bound,
      //    so there is no cardinality check. A missing id is generated later
      //    (criterion 3); an explicit override must keep the pattern prefix
      //    (criterion 3) and stay unique within the list (criterion 5).
      String pattern = field.sectionIdPattern;
      if (itemId != null && pattern != null) {
        String prefix = SpecSectionId.sectionIdPatternPrefix(pattern);
        if (!itemId.startsWith(prefix)) {
          return error(
              parentPath,
              childSegment,
              SpecCreationCode.PATTERN_MISMATCH,
              "item id \"" + itemId + "\" does not keep the pattern prefix \"" + prefix + "\"");
        }
        if (document.listItemSectionIds(childPath).contains(itemId)) {
          return error(
              parentPath,
              childSegment,
              SpecCreationCode.DUPLICATE_SECTION_ID,
              "item id \"" + itemId + "\" is already used in list \"" + childPath + "\"");
        }
      }
      return null;
    }

    // 4. Single-valued child (complex / section / form / content / enum /
    //    scalar): cardinality is exactly one, so reject if a value already
    //    exists at or beneath the child path.
    if (document.hasValuesUnder(childPath)) {
      return error(
          parentPath,
          childSegment,
          SpecCreationCode.CARDINALITY_EXCEEDED,
          "a " + field.kind.raw + " child already exists at \"" + childPath + "\"");
    }
    return null;
  }

  /** {@link #add(String, String, String, Integer, Integer)} with no id override, dated today. */
  public String add(String parentPath, String childSegment) {
    return add(parentPath, childSegment, null, null, null);
  }

  /** {@link #add(String, String, String, Integer, Integer)} dated today. */
  public String add(String parentPath, String childSegment, String itemId) {
    return add(parentPath, childSegment, itemId, null, null);
  }

  /**
   * Adds child {@code childSegment} under {@code parentPath} and returns the new
   * node's path.
   *
   * <p>For a list field this appends a fresh item ({@code …/<segment>-<seq>}),
   * assigning its <b>section id</b> (AA1 criteria 3–5): {@code itemId} if given
   * (override), otherwise one generated from the field's
   * {@code @SectionIdPattern} using {@code month}/{@code day} (each defaulting to
   * today) for the two-letter-date component. Lists with no pattern (scalar
   * lists) get no section id. For a single-valued field it returns the child path
   * without mutating the sparse store (the caller then sets its value).
   *
   * <p>Throws {@link SpecCreationError} — leaving the document untouched — when
   * the add violates a structural rule (see {@link SpecCreationCode}).
   */
  public String add(
      String parentPath, String childSegment, String itemId, Integer month, Integer day) {
    SpecCreationError error = checkAddNode(model, document, parentPath, childSegment, itemId);
    if (error != null) {
      throw error;
    }

    String childPath = SpecPaths.join(parentPath, childSegment);
    SpecField field =
        fieldForSegment(
            new SpecReflection(model).resolve(parentPath).targetClass, childSegment);
    if (field.kind == SpecFieldKind.LIST) {
      String pattern = field.sectionIdPattern;
      if (pattern == null) {
        return document.addListItem(childPath);
      }
      String id = itemId;
      if (id == null) {
        LocalDate today = LocalDate.now();
        id =
            SpecSectionId.generateListItemSectionId(
                pattern,
                month != null ? month : today.getMonthValue(),
                day != null ? day : today.getDayOfMonth(),
                document.listItemSectionIds(childPath));
      }
      return document.addListItem(childPath, id);
    }
    return childPath;
  }

  private static SpecCreationError error(
      String parentPath, String childSegment, SpecCreationCode code, String message) {
    return new SpecCreationError(parentPath, childSegment, code, message);
  }

  /**
   * The field of {@code cls} whose section segment ({@code @SectionId} ?? name) is
   * {@code segment}, or {@code null} when the class declares no such child.
   */
  private static SpecField fieldForSegment(SpecClass cls, String segment) {
    for (SpecField f : cls.fields) {
      String seg = f.sectionId != null ? f.sectionId : f.name;
      if (seg.equals(segment)) {
        return f;
      }
    }
    return null;
  }
}
