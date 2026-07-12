/// The canonical SOM **metadata tree** — the runtime's DR1 §3.1 node types.
///
/// One [SomMetaTree] exists per document root. Its nodes carry *every*
/// `tom_specs_core` annotation the model source declares, plus the exact
/// class and member names, so the tree is the single language-neutral
/// description of a document's structure:
///
///   * [SomMetaNode] — one node per navigable model position (§3.1), with
///     section id / pattern, kind, serialization order, `@Min`, content type,
///     help/comment/doc texts, form metadata, traceability links
///     (`@MapsTo` / `@DetailedIn` / `@SecondLevelSectionId`) and the lossless
///     `extra` annotation list;
///   * [SomMetaTree] — wires parent links and absolute paths (the §4 path
///     grammar shared with `spec_paths.dart`) and provides the two dynamic
///     lookups every runtime keeps: [SomMetaTree.byId] and
///     [SomMetaTree.byPath].
///
/// The runtime only *defines* these types; the generated facades (DR8) emit
/// the populated tree as statically initialized objects, and tests build
/// small fixture trees by hand. This tree supersedes the meta-JSON class
/// graph ([SpecModel]/[SpecReflection]) as the metadata access core; the
/// class graph remains only as the engine of the legacy document layer until
/// DR5–DR8 rewrite its consumers.
library;

import 'spec_paths.dart';

/// The structural kind of a metadata node, mirroring DR1 §3.1
/// (`list | form | section | content | enum | complex | scalar`).
enum SomMetaKind {
  /// A `List<T>` field; items are addressed by `-<seq>` path suffixes and
  /// described by [SomMetaNode.elementNode].
  list,

  /// A `@Form` content section (its fields live in [SomMetaNode.form]).
  form,

  /// A field rendered as a section of its own.
  section,

  /// A free-text (markdown) content leaf.
  content,

  /// An enum-valued leaf.
  enumValue,

  /// A field typed by another model class (collapses into that class:
  /// the node's children are the target class's fields).
  complex,

  /// A plain scalar leaf (`String`/`int`/`double`/`bool`).
  scalar,
}

/// The `@ContentType(type, description)` annotation captured on a node.
class SomContentTypeMeta {
  /// The declared content type (e.g. `code`, `diagram`).
  final String type;

  /// The human/AI-facing description of the expected content.
  final String description;

  const SomContentTypeMeta({required this.type, required this.description});
}

/// One field of a `@Form` section (DR1 §3.1 `FormMeta.fields`).
class SomFormFieldMeta {
  /// The exact model field name (`approvedBy`).
  final String name;

  /// The Dart type name of the field (`String`, `int`, …).
  final String typeName;

  /// The display label / description, when the form declares one.
  final String? description;

  /// Whether the form marks the field as required.
  final bool required;

  /// The authoring hint (e.g. `e.g. 1.0`), when present.
  final String? hint;

  /// Declaration order within the form.
  final int order;

  const SomFormFieldMeta({
    required this.name,
    required this.typeName,
    this.description,
    this.required = false,
    this.hint,
    required this.order,
  });
}

/// The form metadata of a `@Form` node (DR1 §3.1 `FormMeta`).
class SomFormMeta {
  /// The form's fields in declaration order.
  final List<SomFormFieldMeta> fields;

  const SomFormMeta({required this.fields});

  /// The field named [name], or `null` when absent.
  SomFormFieldMeta? fieldNamed(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }
}

/// The `@Document` metadata carried by a document root (DR1 §3.1 `DocMeta`).
class SomDocMeta {
  /// The document's display name (`Solution Blueprint`).
  final String name;

  /// The document's description.
  final String description;

  /// Class names of the documents this one is based on (`@Document.basedOn`).
  final List<String> basedOn;

  const SomDocMeta({
    required this.name,
    required this.description,
    this.basedOn = const [],
  });
}

/// One `@SecondLevelSectionId(documentClass, id)` entry (DR1 §3.1).
class SomSecondLevelId {
  /// The document class the second-level id applies within.
  final String documentClass;

  /// The section id used in that document.
  final String id;

  const SomSecondLevelId({required this.documentClass, required this.id});
}

/// One annotation captured losslessly into the generic `extra` list —
/// annotations the tree defines no dedicated slot for (DR1 §3.1 note),
/// e.g. `@Max`, `@MinLength`, `@PatternCheck`, `@TextRequired`.
class SomMetaExtra {
  /// The annotation's class name (`Max`, `PatternCheck`, …).
  final String annotation;

  /// The resolved constructor arguments (`{'count': 4}`).
  final Map<String, Object?> args;

  const SomMetaExtra({required this.annotation, this.args = const {}});
}

/// One node of the SOM metadata tree (DR1 §3.1 `MetaNode`).
///
/// A node describes one navigable position of a document root's structure:
/// the document root itself, a field, or a list's element subtree. Class-level
/// annotations attach to the node where the class is *instantiated*;
/// field-level annotations attach to the node directly (field-level
/// `@SectionId` wins over the target class's).
///
/// Nodes are immutable value carriers; [SomMetaTree] wires the parent links
/// and absolute paths when the tree is constructed. A node instance belongs
/// to at most one tree.
class SomMetaNode {
  /// The exact model class name this node is (for root/complex/section nodes:
  /// the instantiated class; for leaves: the declaring class of the field).
  final String className;

  /// The exact field name in the parent class, or `null` on the document root
  /// and on list element subtrees.
  final String? memberName;

  /// The effective `@SectionId` (field-level wins over class-level), when any.
  final String? sectionId;

  /// The `@SectionIdPattern` on a list field (item ids), when any.
  final String? sectionIdPattern;

  /// The structural kind of the node.
  final SomMetaKind kind;

  /// The Dart type name of the field/class (`String`, `GoalEntry`, …).
  final String typeName;

  /// `@SerializationOrder(order)`, when annotated.
  final int? serializationOrder;

  /// `@Min(count)`, when annotated.
  final int? min;

  /// Whether `@Unused` is present on the node.
  final bool unused;

  /// `@ContentType`, when annotated.
  final SomContentTypeMeta? contentType;

  /// `@ContentHelp(guidance)`, when annotated.
  final String? contentHelp;

  /// `@Comment(text)`, when annotated.
  final String? comment;

  /// The cleaned `///` doc comment (member wins over class), when any.
  final String? docComment;

  /// The instantiated class's own doc comment, when it differs from
  /// [docComment].
  final String? classDocComment;

  /// Form metadata, for [SomMetaKind.form] nodes.
  final SomFormMeta? form;

  /// `@Document` metadata; non-null only on the document root.
  final SomDocMeta? document;

  /// `@MapsTo` target class name, when annotated.
  final String? mapsTo;

  /// `@DetailedIn` target class name, when annotated.
  final String? detailedIn;

  /// `@SecondLevelSectionId` entries, when annotated.
  final List<SomSecondLevelId> secondLevelIds;

  /// Annotations without a dedicated slot, captured losslessly (§3.1 note).
  final List<SomMetaExtra> extra;

  /// Whether this node is a recursive re-entry reference (a class already on
  /// the descent stack): `kind == complex`, no children.
  final bool recursive;

  /// The child nodes, in `@SerializationOrder` order. For complex/section
  /// nodes these are the target class's fields (the class collapses onto the
  /// node); empty for leaves and recursive references.
  final List<SomMetaNode> children;

  /// For [SomMetaKind.list] nodes: the element class subtree. Its children
  /// describe each item's structure; item positions have no static path
  /// (see [path]).
  final SomMetaNode? elementNode;

  SomMetaNode({
    required this.className,
    this.memberName,
    this.sectionId,
    this.sectionIdPattern,
    required this.kind,
    required this.typeName,
    this.serializationOrder,
    this.min,
    this.unused = false,
    this.contentType,
    this.contentHelp,
    this.comment,
    this.docComment,
    this.classDocComment,
    this.form,
    this.document,
    this.mapsTo,
    this.detailedIn,
    this.secondLevelIds = const [],
    this.extra = const [],
    this.recursive = false,
    this.children = const [],
    this.elementNode,
  });

  // --- tree wiring (set once by SomMetaTree) -------------------------------

  SomMetaTree? _tree;
  SomMetaNode? _parent;
  String? _path;

  /// The tree this node belongs to.
  ///
  /// Throws [StateError] when the node has not been attached to a
  /// [SomMetaTree] yet.
  SomMetaTree get tree {
    final t = _tree;
    if (t == null) {
      throw StateError(
          'SomMetaNode($debugName) is not attached to a SomMetaTree');
    }
    return t;
  }

  /// The parent node, or `null` on the document root. The parent of a list's
  /// [elementNode] is the list node itself.
  SomMetaNode? get parent {
    tree; // attachment guard
    return _parent;
  }

  /// The node's absolute document path per the §4 path grammar
  /// (`<rootSegment>/<segment>/…`), or `null` for nodes inside a list element
  /// subtree — their concrete paths depend on the item sequence (see
  /// [itemPath] on the list node and [SomMetaTree.byPath]).
  String? get path {
    tree; // attachment guard
    return _path;
  }

  /// The path segment this node contributes: the effective [sectionId] when
  /// present, else the [memberName], else the [className] (document root).
  String get segment => sectionId ?? memberName ?? className;

  /// The path of the [seq]-th item of this list node (`<path>-<seq>`).
  ///
  /// Throws [StateError] when the node is not a list or has no static path.
  String itemPath(int seq) {
    if (kind != SomMetaKind.list) {
      throw StateError('itemPath() requires a list node, '
          '$debugName is ${kind.name}');
    }
    final p = path;
    if (p == null) {
      throw StateError('list $debugName sits inside a list element subtree '
          'and has no static path');
    }
    return listItemPath(p, seq);
  }

  /// The direct child whose [memberName] equals [name], or `null`.
  SomMetaNode? childByMember(String name) {
    for (final c in children) {
      if (c.memberName == name) return c;
    }
    return null;
  }

  /// The direct child whose [segment] equals [seg], or `null`.
  SomMetaNode? childBySegment(String seg) {
    for (final c in children) {
      if (c.segment == seg) return c;
    }
    return null;
  }

  /// A short identification for error messages.
  String get debugName =>
      memberName == null ? className : '$className.$memberName';
}

/// The metadata tree of one document root: parent/path wiring plus the two
/// dynamic lookups ([byId], [byPath]) DR1 §4.3 requires every runtime to keep.
class SomMetaTree {
  /// The document root node (must carry [SomMetaNode.document]).
  final SomMetaNode root;

  final Map<String, List<SomMetaNode>> _byId = {};
  final List<SomMetaNode> _allNodes = [];

  /// Wires [root]'s subtree: sets parent links, computes static paths, and
  /// indexes section ids.
  ///
  /// Throws [ArgumentError] when [root] carries no `@Document` metadata, and
  /// [StateError] when any node is already attached to another tree (nodes
  /// belong to exactly one tree).
  SomMetaTree(this.root) {
    if (root.document == null) {
      throw ArgumentError.value(root.debugName, 'root',
          'the tree root must carry @Document metadata (SomMetaNode.document)');
    }
    _wire(root, parent: null, path: root.segment);
  }

  void _wire(SomMetaNode node, {SomMetaNode? parent, String? path}) {
    if (node._tree != null) {
      throw StateError('SomMetaNode(${node.debugName}) is already attached '
          'to a SomMetaTree; nodes belong to exactly one tree');
    }
    node._tree = this;
    node._parent = parent;
    node._path = path;
    _allNodes.add(node);
    final id = node.sectionId;
    if (id != null) (_byId[id] ??= []).add(node);
    for (final child in node.children) {
      _wire(child, parent: node, path: _childPath(path, child));
    }
    final element = node.elementNode;
    if (element != null) {
      // Item positions are dynamic (`<listPath>-<seq>`), so the element
      // subtree carries no static paths.
      _wire(element, parent: node, path: null);
    }
  }

  static String? _childPath(String? parentPath, SomMetaNode child) =>
      parentPath == null ? null : specPathJoin(parentPath, child.segment);

  /// Every node of the tree (document order; element subtrees follow their
  /// list node).
  Iterable<SomMetaNode> get allNodes => _allNodes;

  // --- lookup by section id ------------------------------------------------

  /// All nodes whose effective section id equals [sectionId], in document
  /// order. A shared class instantiated at several positions yields several
  /// nodes (ids resolve within their parent chain, DR1 §1.2).
  List<SomMetaNode> allById(String sectionId) =>
      _byId[sectionId] ?? const [];

  /// The first node whose effective section id equals [sectionId].
  ///
  /// A *resolved list-item id* (a list's `@SectionIdPattern` with the `xxx`
  /// placeholder replaced by digits, e.g. `GOAL-ITEM-3`) resolves to that
  /// list's element subtree. Returns `null` when nothing matches.
  SomMetaNode? byId(String sectionId) {
    final exact = _byId[sectionId];
    if (exact != null) return exact.first;
    for (final node in _allNodes) {
      final pattern = node.sectionIdPattern;
      if (pattern != null && _matchesPattern(pattern, sectionId)) {
        return node.elementNode ?? node;
      }
    }
    return null;
  }

  static bool _matchesPattern(String pattern, String id) {
    final regex = RegExp(
        '^${pattern.split('xxx').map(RegExp.escape).join('[0-9]+')}\$');
    return regex.hasMatch(id);
  }

  // --- lookup by path ------------------------------------------------------

  /// Resolves a document [path] (the §4 grammar: segments joined by `/`,
  /// list items as `-<seq>` suffixes) to the metadata node it addresses, or
  /// `null` when the path does not describe a reachable position.
  ///
  /// A list-item segment (`<listSegment>-<seq>`) resolves to the list's
  /// element subtree; segments below it match the element class's fields.
  /// A list *container* path is only valid as the final segment (descending
  /// past a list requires an item suffix).
  SomMetaNode? byPath(String path) {
    final segs = specPathSegments(path);
    if (segs.isEmpty || segs.first != root.segment) return null;

    var node = root;
    for (var i = 1; i < segs.length; i++) {
      final seg = segs[i];
      final last = i == segs.length - 1;

      // Prefer an exact segment match; only then try a list-item suffix, so
      // a hyphenated @SectionId is never mis-read as an item (spec_paths).
      final child = node.childBySegment(seg);
      if (child != null) {
        if (child.kind == SomMetaKind.list && !last) {
          return null; // a list path needs a `-<seq>` item suffix to go deeper
        }
        if (child.recursive && !last) {
          return null; // generated chains terminate at recursive re-entries
        }
        node = child;
        continue;
      }

      final split = splitListItemSegment(seg);
      if (split == null) return null;
      final listNode = node.childBySegment(split.base);
      if (listNode == null || listNode.kind != SomMetaKind.list) return null;
      final element = listNode.elementNode;
      if (element == null) {
        // Scalar list without an element subtree: the item is a value leaf.
        return last ? listNode : null;
      }
      node = element;
    }
    return node;
  }
}

/// One position of the generated **dot-notation / ID-tree access surfaces**
/// (DR1 §4): an absolute document [path] bound to the [tree] it belongs to.
///
/// The generated facades (DR8) emit one accessor class per model class whose
/// getters return further [SomMetaRef]s — `d00SolutionBlueprint
/// .introductionAndScope.path` / `SBP.INSC.path`. Every accessor exposes at
/// least [path] (identical to the retired flat path constant's value) and
/// [meta] (the [SomMetaNode] at that position). This base class is the leaf
/// accessor itself (content/scalar/enum/form positions).
class SomMetaRef {
  /// The metadata tree of the document root this position belongs to.
  final SomMetaTree tree;

  /// The absolute document path of this position (§4 path grammar).
  final String path;

  SomMetaRef(this.tree, this.path);

  /// The metadata node at [path].
  ///
  /// Throws [StateError] when the path resolves to no node — only possible
  /// past a recursive re-entry, where the generated chain has ended and the
  /// metadata tree carries no further nodes (DR1 §4.1 cycle rule).
  SomMetaNode get meta =>
      tree.byPath(path) ??
      (throw StateError('no metadata node at "$path" — the position lies '
          'beyond a recursive re-entry; use the dynamic tree lookups instead'));
}

/// The generated accessor for a **list** position (DR1 §4.1): [path] is the
/// list container path; [item] returns the accessor for the `seq`-th item
/// position (`<path>-<seq>`), whose children are the element class's
/// accessors.
class SomListMetaRef<E> extends SomMetaRef {
  final E Function(SomMetaTree tree, String path) _element;

  SomListMetaRef(super.tree, super.path, this._element);

  /// The accessor at the item position `<path>-<seq>`.
  E item(int seq) => _element(tree, listItemPath(path, seq));
}
