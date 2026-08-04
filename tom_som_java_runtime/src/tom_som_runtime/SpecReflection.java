package tom_som_runtime;

import java.util.ArrayDeque;
import java.util.Collection;
import java.util.Collections;
import java.util.Deque;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Generic, value-free traversal of a {@link SpecModel} class graph — a faithful
 * port of {@code spec_reflection.dart} / {@code spec_reflection.py}.
 *
 * <p>It answers two kinds of question about a model: <b>enumeration</b> (what
 * roots, classes, fields and annotations exist) and <b>resolution</b> (which
 * model node a concrete document <i>path</i> addresses). It holds no document
 * values.
 */
public final class SpecReflection {
  public final SpecModel model;

  public SpecReflection(SpecModel model) {
    this.model = model;
  }

  // --- enumeration --------------------------------------------------------

  public List<SpecRoot> roots() {
    return model.roots;
  }

  public Collection<SpecClass> classes() {
    return model.classes.values();
  }

  public SpecClass classNamed(String name) {
    return model.classNamed(name);
  }

  public List<SpecField> fieldsOf(String className) {
    SpecClass cls = classNamed(className);
    return cls == null ? Collections.emptyList() : cls.fields;
  }

  public List<SpecAnnotation> annotationsOf(String className) {
    SpecClass cls = classNamed(className);
    return cls == null ? Collections.emptyList() : cls.annotations;
  }

  public List<SpecAnnotation> fieldAnnotations(String className, String fieldName) {
    SpecClass cls = classNamed(className);
    if (cls == null) {
      return Collections.emptyList();
    }
    SpecField f = cls.fieldNamed(fieldName);
    return f == null ? Collections.emptyList() : f.annotations;
  }

  /**
   * Every class name reachable from {@code typeName} by following class-bearing
   * fields — {@code complex}/{@code section} fields through their {@code type},
   * complex list fields through their {@code elementType} — including
   * {@code typeName} itself.
   *
   * <p>This is the model's notion of <b>document scope</b>. A document rooted at a
   * given {@code @Document} class can only ever hold sections of the classes that
   * root reaches, so a class outside the set is not merely <i>unpopulated</i> in
   * such a document — it is absent from it by construction. Any consumer that has
   * to tell "the author did not write this" from "this document could not hold it
   * in the first place" needs exactly this set.
   *
   * <p>A name that resolves to no class contributes nothing and is not itself
   * included: an unresolved reference is not evidence of a reachable class.
   */
  public Set<String> reachableClassNames(String typeName) {
    Set<String> seen = new LinkedHashSet<>();
    Deque<String> stack = new ArrayDeque<>();
    stack.push(typeName);
    while (!stack.isEmpty()) {
      String current = stack.pop();
      if (seen.contains(current)) {
        continue;
      }
      SpecClass cls = classNamed(current);
      if (cls == null) {
        continue;
      }
      seen.add(current);
      for (SpecField f : cls.fields) {
        String child = null;
        if (f.kind == SpecFieldKind.COMPLEX || f.kind == SpecFieldKind.SECTION) {
          child = f.type;
        } else if (f.kind == SpecFieldKind.LIST) {
          child = f.elementIsComplex ? f.elementType : null;
        }
        if (child != null) {
          stack.push(child);
        }
      }
    }
    return seen;
  }

  // --- resolution ---------------------------------------------------------

  public String rootSegment(SpecRoot root) {
    return (root.sectionId != null && !root.sectionId.isEmpty()) ? root.sectionId : root.type;
  }

  public String fieldSegment(SpecField field) {
    return (field.sectionId != null && !field.sectionId.isEmpty()) ? field.sectionId : field.name;
  }

  public SpecRoot rootForSegment(String segment) {
    for (SpecRoot r : model.roots) {
      if (rootSegment(r).equals(segment)) {
        return r;
      }
    }
    return null;
  }

  private SpecField matchField(SpecClass cls, String segment) {
    for (SpecField f : cls.fields) {
      if (fieldSegment(f).equals(segment)) {
        return f;
      }
    }
    return null;
  }

  private SpecNodeKind leafKind(SpecFieldKind kind) {
    switch (kind) {
      case FORM:
        return SpecNodeKind.FORM;
      case CONTENT:
        return SpecNodeKind.CONTENT;
      case ENUM:
        return SpecNodeKind.ENUM_VALUE;
      case SCALAR:
      default:
        return SpecNodeKind.SCALAR;
    }
  }

  /**
   * Resolves a document {@code path} to the model node it addresses, or
   * {@code null} when the path does not describe a reachable node.
   */
  public SpecResolution resolve(String path) {
    String[] segs = SpecPaths.segments(path);
    if (segs.length == 0 || segs[0].isEmpty()) {
      return null;
    }

    SpecRoot root = rootForSegment(segs[0]);
    if (root == null) {
      return null;
    }

    SpecClass curClass = classNamed(root.type);
    if (segs.length == 1) {
      return new SpecResolution(path, SpecNodeKind.ROOT, root, null, curClass);
    }

    for (int i = 1; i < segs.length; i++) {
      SpecClass cls = curClass;
      if (cls == null) {
        return null; // cannot descend into a non-class
      }
      String seg = segs[i];
      boolean last = i == segs.length - 1;

      // Prefer an exact field-segment match; only then try a list-item suffix,
      // so a hyphenated @SectionId is never mis-read as an item.
      SpecField field = matchField(cls, seg);
      if (field != null) {
        if (field.kind == SpecFieldKind.COMPLEX || field.kind == SpecFieldKind.SECTION) {
          curClass = classNamed(field.type);
          if (last) {
            return new SpecResolution(
                path,
                field.kind == SpecFieldKind.COMPLEX
                    ? SpecNodeKind.COMPLEX
                    : SpecNodeKind.SECTION,
                root,
                field,
                curClass);
          }
          continue; // descend into the collapsed class
        }
        if (field.kind == SpecFieldKind.LIST) {
          return last
              ? new SpecResolution(path, SpecNodeKind.LIST, root, field, null)
              : null; // a list path needs a -<seq> item suffix
        }
        // form / content / enum / scalar leaves
        return last
            ? new SpecResolution(path, leafKind(field.kind), root, field, null)
            : null; // a leaf cannot have further segments
      }

      SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(seg);
      if (split == null) {
        return null;
      }
      SpecField listField = matchField(cls, split.base);
      if (listField == null || listField.kind != SpecFieldKind.LIST) {
        return null;
      }
      if (listField.elementIsComplex) {
        curClass = classNamed(listField.elementType);
        if (last) {
          return new SpecResolution(
              path, SpecNodeKind.LIST_ITEM_COMPLEX, root, listField, curClass);
        }
        continue;
      }
      // Scalar list item: a value leaf, so it must be the final segment.
      if (last) {
        return new SpecResolution(path, SpecNodeKind.LIST_ITEM_SCALAR, root, listField, null);
      }
      return null;
    }
    return null;
  }
}
