/// Generic, value-free traversal of a [SpecModel] class graph (the "reflection"
/// surface).
///
/// [SpecReflection] answers two kinds of question about a model:
///
///   * **enumeration** — what roots, classes, fields and annotations exist;
///   * **resolution** — which model node a concrete document *path* addresses.
///
/// It holds no document values; a [SpecResolution] describes the *schema* node
/// a path lands on, so the validator and any editor can decide what a value at
/// that path is allowed to be.
library;

import 'spec_model.dart';
import 'spec_paths.dart';

/// What a resolved path lands on in the model.
enum SpecNodeKind {
  /// The bare document root segment (the whole document).
  root,

  /// A `complex` field collapsed into its target class.
  complex,

  /// A `section` field collapsed into its target class.
  section,

  /// A `list` container field (the list itself, not an item).
  list,

  /// One complex item of a list (descended into its element class).
  listItemComplex,

  /// One scalar item of a list.
  listItemScalar,

  /// A `@Form` content section.
  form,

  /// A free-text `content` leaf.
  content,

  /// An `enum`-valued leaf.
  enumValue,

  /// A plain `scalar` leaf.
  scalar,
}

/// The outcome of resolving a document path against a [SpecModel].
class SpecResolution {
  /// The path that was resolved.
  final String path;

  /// What kind of node the path lands on.
  final SpecNodeKind kind;

  /// The document root the path descends from.
  final SpecRoot root;

  /// The field the path terminates on, or `null` for a bare-root resolution.
  final SpecField? field;

  /// For [SpecNodeKind.root]/[SpecNodeKind.complex]/[SpecNodeKind.section] and
  /// [SpecNodeKind.listItemComplex]: the class the node *is*. `null` for leaves
  /// and unresolved class references.
  final SpecClass? targetClass;

  const SpecResolution({
    required this.path,
    required this.kind,
    required this.root,
    this.field,
    this.targetClass,
  });

  /// Whether a single string value is stored directly at this path (a content,
  /// enum, scalar leaf, or a scalar list item).
  bool get isValueLeaf =>
      kind == SpecNodeKind.content ||
      kind == SpecNodeKind.enumValue ||
      kind == SpecNodeKind.scalar ||
      kind == SpecNodeKind.listItemScalar;
}

/// Read-only queries over a [SpecModel].
class SpecReflection {
  final SpecModel model;

  const SpecReflection(this.model);

  // --- enumeration --------------------------------------------------------

  /// Every document root in the model.
  Iterable<SpecRoot> get roots => model.roots;

  /// Every class in the model (each appears once — it is a graph, not a tree).
  Iterable<SpecClass> get classes => model.classes.values;

  /// The class named [name], or `null` when absent.
  SpecClass? classNamed(String? name) => model.classNamed(name);

  /// The fields declared on [className] (empty when the class is unknown).
  List<SpecField> fieldsOf(String className) =>
      classNamed(className)?.fields ?? const [];

  /// The class-level annotations on [className].
  List<SpecAnnotation> annotationsOf(String className) =>
      classNamed(className)?.annotations ?? const [];

  /// The annotations on field [fieldName] of [className].
  List<SpecAnnotation> fieldAnnotations(String className, String fieldName) =>
      classNamed(className)?.fieldNamed(fieldName)?.annotations ?? const [];

  /// Every class name reachable from [typeName] by following class-bearing
  /// fields — `complex`/`section` fields through their `type`, complex list
  /// fields through their `elementType` — including [typeName] itself.
  ///
  /// This is the model's notion of **document scope**. A document rooted at a
  /// given `@Document` class can only ever hold sections of the classes that
  /// root reaches, so a class outside the set is not merely *unpopulated* in
  /// such a document — it is absent from it by construction. Any consumer that
  /// has to tell "the author did not write this" from "this document could not
  /// hold it in the first place" needs exactly this set.
  ///
  /// A name that resolves to no class contributes nothing and is not itself
  /// included: an unresolved reference is not evidence of a reachable class.
  Set<String> reachableClassNames(String typeName) {
    final seen = <String>{};
    final stack = <String>[typeName];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (seen.contains(current)) continue;
      final cls = classNamed(current);
      if (cls == null) continue;
      seen.add(current);
      for (final f in cls.fields) {
        final child = switch (f.kind) {
          SpecFieldKind.complex || SpecFieldKind.section => f.type,
          SpecFieldKind.list => f.elementIsComplex ? f.elementType : null,
          _ => null,
        };
        if (child != null) stack.add(child);
      }
    }
    return seen;
  }

  // --- resolution ---------------------------------------------------------

  /// The section segment a root contributes to a path (`@SectionId` ?? type).
  String rootSegment(SpecRoot root) => root.sectionId ?? root.type;

  /// The section segment a field contributes to a path (`@SectionId` ?? name).
  String fieldSegment(SpecField field) => field.sectionId ?? field.name;

  /// The root whose [rootSegment] equals [segment], or `null`.
  SpecRoot? rootForSegment(String segment) {
    for (final r in model.roots) {
      if (rootSegment(r) == segment) return r;
    }
    return null;
  }

  /// Resolves a document [path] to the model node it addresses, or `null` when
  /// the path does not describe a reachable node (a "dangling" path).
  ///
  /// The walk starts at the root segment and descends one segment at a time,
  /// matching each against the current class's fields by [fieldSegment].
  /// Complex/section fields collapse into their target class; a `-<seq>` suffix
  /// marks a list item and descends into the list's element type.
  SpecResolution? resolve(String path) {
    final segs = specPathSegments(path);
    if (segs.isEmpty || segs.first.isEmpty) return null;

    final root = rootForSegment(segs.first);
    if (root == null) return null;

    SpecClass? curClass = classNamed(root.type);
    if (segs.length == 1) {
      return SpecResolution(
        path: path,
        kind: SpecNodeKind.root,
        root: root,
        targetClass: curClass,
      );
    }

    for (var i = 1; i < segs.length; i++) {
      final cls = curClass;
      if (cls == null) return null; // cannot descend into a non-class
      final seg = segs[i];
      final last = i == segs.length - 1;

      // Prefer an exact field-segment match; only then try a list-item suffix,
      // so a hyphenated `@SectionId` is never mis-read as an item.
      final field = _matchField(cls, seg);
      if (field != null) {
        switch (field.kind) {
          case SpecFieldKind.complex:
          case SpecFieldKind.section:
            curClass = classNamed(field.type);
            if (last) {
              return SpecResolution(
                path: path,
                kind: field.kind == SpecFieldKind.complex
                    ? SpecNodeKind.complex
                    : SpecNodeKind.section,
                root: root,
                field: field,
                targetClass: curClass,
              );
            }
            continue; // descend into the collapsed class
          case SpecFieldKind.list:
            return last
                ? SpecResolution(
                    path: path,
                    kind: SpecNodeKind.list,
                    root: root,
                    field: field)
                : null; // a list path needs a `-<seq>` item suffix to go deeper
          case SpecFieldKind.form:
          case SpecFieldKind.content:
          case SpecFieldKind.enumValue:
          case SpecFieldKind.scalar:
            return last
                ? SpecResolution(
                    path: path,
                    kind: _leafKind(field.kind),
                    root: root,
                    field: field)
                : null; // a leaf cannot have further segments
        }
      }

      final split = splitListItemSegment(seg);
      if (split == null) return null;
      final listField = _matchField(cls, split.base);
      if (listField == null || listField.kind != SpecFieldKind.list) {
        return null;
      }
      if (listField.elementIsComplex) {
        curClass = classNamed(listField.elementType);
        if (last) {
          return SpecResolution(
            path: path,
            kind: SpecNodeKind.listItemComplex,
            root: root,
            field: listField,
            targetClass: curClass,
          );
        }
        continue;
      }
      // Scalar list item: a value leaf, so it must be the final segment.
      if (last) {
        return SpecResolution(
          path: path,
          kind: SpecNodeKind.listItemScalar,
          root: root,
          field: listField,
        );
      }
      return null;
    }
    return null;
  }

  /// The [SpecNodeKind] a terminal leaf field of [kind] resolves to.
  SpecNodeKind _leafKind(SpecFieldKind kind) {
    switch (kind) {
      case SpecFieldKind.form:
        return SpecNodeKind.form;
      case SpecFieldKind.content:
        return SpecNodeKind.content;
      case SpecFieldKind.enumValue:
        return SpecNodeKind.enumValue;
      case SpecFieldKind.scalar:
        return SpecNodeKind.scalar;
      case SpecFieldKind.list:
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        return SpecNodeKind.scalar; // unreachable: handled before this call
    }
  }

  SpecField? _matchField(SpecClass cls, String segment) {
    for (final f in cls.fields) {
      if (fieldSegment(f) == segment) return f;
    }
    return null;
  }
}
