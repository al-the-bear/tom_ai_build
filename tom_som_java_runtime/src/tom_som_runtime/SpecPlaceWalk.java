package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * The addressable positions of a subtree of the model, value-free, the way the
 * place grammar resolves against them ({@code tom_specs_model_rules.md} §9.7):
 * every list item beneath the scope is written {@code <list>-*}.
 */
final class SpecPlaceWalk {
  private SpecPlaceWalk() {}

  /** The subtree a place is looked for in. */
  static final class Scope {
    final String path;
    final SpecClass cls;
    final boolean isListElement;

    Scope(String path, SpecClass cls, boolean isListElement) {
      this.path = path;
      this.cls = cls;
      this.isListElement = isListElement;
    }
  }

  /** One addressable node: a class's own node or a member with its own section id. */
  static final class Node {
    String id;
    String path;
    String className;
    String shape;
    boolean ownNode;
    List<FormFieldSpec> formFields = Collections.emptyList();
    String formPath;
    String contentPath;
    boolean isListElement;
  }

  /** A node with the section ids leading to it and the member it is reached through. */
  static final class Position {
    final Node node;
    final List<String> ids;
    final SpecField member;

    Position(Node node, List<String> ids, SpecField member) {
      this.node = node;
      this.ids = ids;
      this.member = member;
    }
  }

  /** The scope a place is looked for in under {@code anchor}. */
  static Scope scopeOf(SpecReflection refl, String anchor, boolean scoped, String text) {
    String[] segs = SpecPaths.segments(anchor);
    for (int n = segs.length; n > 0; n--) {
      String path = String.join("/", java.util.Arrays.copyOfRange(segs, 0, n));
      SpecResolution r = refl.resolve(path);
      if (n == segs.length && (r == null || r.targetClass == null)) {
        throw new SpecPlaceException(
            SpecPlaceProblem.ANCHOR_UNRESOLVED,
            text,
            "has the anchor " + anchor + ", which resolves to no section");
      }
      boolean isItem = r != null && r.kind == SpecNodeKind.LIST_ITEM_COMPLEX;
      if (!scoped || isItem) {
        // As in Dart (`r!.targetClass!`): an ancestor that resolves to no class
        // cannot be a scope.
        if (r == null || r.targetClass == null) {
          throw new IllegalStateException("no class at " + path);
        }
        return new Scope(path, r.targetClass, isItem);
      }
    }
    throw new SpecPlaceException(
        SpecPlaceProblem.NOT_SCOPED,
        text,
        "is `./`-scoped, but no list element lies at or above " + anchor);
  }

  /** The scope of the whole document root {@code rootType}, or {@code null}. */
  static Scope rootScope(SpecReflection refl, String rootType) {
    SpecRoot root = null;
    for (SpecRoot r : refl.model.roots) {
      if (r.type.equals(rootType)) {
        root = r;
        break;
      }
    }
    SpecClass cls = refl.classNamed(rootType);
    if (root == null || cls == null) {
      return null;
    }
    return new Scope(refl.rootSegment(root), cls, false);
  }

  /** The class a complex or section member reaches. */
  static SpecClass classOf(SpecReflection refl, SpecField f) {
    return f.type == null ? null : refl.classNamed(f.type.replace("?", ""));
  }

  /**
   * Every addressable position beneath (and including) {@code scope}, in model
   * order. A class reached again on its own path is not descended into, and a
   * {@code @Reference} member is a place whose target is not walked.
   */
  static List<Position> positions(SpecReflection refl, Scope scope) {
    List<Position> out = new ArrayList<>();
    walk(refl, scope.cls, scope.path, Collections.emptyList(), scope.isListElement, null,
        new HashSet<>(), out);
    return out;
  }

  private static void walk(
      SpecReflection refl,
      SpecClass cls,
      String path,
      List<String> ids,
      boolean isItem,
      SpecField via,
      Set<String> onPath,
      List<Position> out) {
    if (!onPath.add(cls.name)) {
      return;
    }
    SpecField content = cls.fieldNamed("content");
    List<String> here = ids;
    String ownId = cls.sectionId;
    if (ownId != null && !ownId.isEmpty()) {
      here = appendId(ids, ownId);
      Node node = new Node();
      node.id = ownId;
      node.path = path;
      node.className = cls.name;
      node.shape = "section";
      node.ownNode = true;
      node.isListElement = isItem;
      if (content != null) {
        String seg = path + "/" + refl.fieldSegment(content);
        if (content.kind == SpecFieldKind.FORM) {
          node.formFields = content.formFields;
          node.formPath = seg;
        } else if (content.kind == SpecFieldKind.CONTENT) {
          node.contentPath = seg;
        }
      }
      out.add(new Position(node, here, via));
    }
    for (SpecField f : cls.fields) {
      String memberPath = path + "/" + refl.fieldSegment(f);
      List<String> below = here;
      String sid = f.sectionId;
      if (!"content".equals(f.name) && sid != null && !sid.isEmpty()) {
        below = appendId(here, sid);
        String shape;
        switch (f.kind) {
          case LIST:
            shape = "list";
            break;
          case FORM:
            shape = "form";
            break;
          case COMPLEX:
          case SECTION:
            shape = "section";
            break;
          default:
            shape = "content";
        }
        Node node = new Node();
        node.id = sid;
        node.path = memberPath;
        node.className = cls.name;
        node.shape = shape;
        node.ownNode = false;
        if (f.kind == SpecFieldKind.FORM) {
          node.formFields = f.formFields;
          node.formPath = memberPath;
        }
        if (shape.equals("content")) {
          node.contentPath = memberPath;
        }
        out.add(new Position(node, below, f));
      }
      if (f.hasAnnotation("Reference")) {
        continue;
      }
      if (f.kind == SpecFieldKind.LIST && f.elementIsComplex) {
        SpecClass el = f.elementType == null ? null : refl.classNamed(f.elementType);
        if (el != null) {
          walk(refl, el, memberPath + "-*", below, true, f, onPath, out);
        }
      } else if (f.kind == SpecFieldKind.COMPLEX || f.kind == SpecFieldKind.SECTION) {
        SpecClass child = classOf(refl, f);
        if (child != null) {
          walk(refl, child, memberPath, below, false, f, onPath, out);
        }
      }
    }
    onPath.remove(cls.name);
  }

  /** {@code ids} with {@code id} appended, as a new list. */
  static List<String> appendId(List<String> ids, String id) {
    List<String> out = new ArrayList<>(ids);
    out.add(id);
    return Collections.unmodifiableList(out);
  }

  /**
   * Whether the {@code /} segments lead to a position whose ancestors are
   * {@code path}: they name every section on the way, leaving out only
   * {@code -LST} containers and the scope's own id. No segments: any position.
   */
  static boolean pathMatches(List<String> path, List<String> segments) {
    if (segments.isEmpty()) {
      return true;
    }
    return pathMatchesFrom(path, segments, 0)
        || (!path.isEmpty() && pathMatchesFrom(path, segments, 1));
  }

  private static boolean pathMatchesFrom(List<String> path, List<String> segments, int start) {
    int j = 0;
    for (int i = start; i < path.size(); i++) {
      if (j < segments.size() && path.get(i).equals(segments.get(j))) {
        j++;
      } else if (!path.get(i).endsWith("-LST")) {
        return false;
      }
    }
    return j == segments.size();
  }

  /** Whether {@code path} ends with exactly the ids of {@code tail}. */
  static boolean endsWith(List<String> path, List<String> tail) {
    if (path.size() < tail.size()) {
      return false;
    }
    int off = path.size() - tail.size();
    for (int i = 0; i < tail.size(); i++) {
      if (!path.get(off + i).equals(tail.get(i))) {
        return false;
      }
    }
    return true;
  }
}
