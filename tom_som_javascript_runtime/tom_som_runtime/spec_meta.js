'use strict';

/**
 * The canonical SOM **metadata tree** — the runtime's DR1 §3.1 node types; a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_meta.dart` (and
 * `spec_meta.py`).
 *
 * One {@link SomMetaTree} exists per document root. Its nodes carry *every*
 * `tom_specs_core` annotation the model source declares, plus the exact class
 * and member names, so the tree is the single language-neutral description of a
 * document's structure:
 *
 *   * {@link SomMetaNode} — one node per navigable model position (§3.1), with
 *     section id / pattern, kind, serialization order, `@Min`, content type,
 *     help/comment/doc texts, form metadata, traceability links
 *     (`@MapsTo` / `@DetailedIn` / `@SecondLevelSectionId`) and the lossless
 *     `extra` annotation list;
 *   * {@link SomMetaTree} — wires parent links and absolute paths (the §4 path
 *     grammar shared with `spec_paths`) and provides the two dynamic lookups
 *     every runtime keeps: {@link SomMetaTree#byId} and
 *     {@link SomMetaTree#byPath}.
 *
 * The runtime only *defines* these types; the generated facades (DR8) emit the
 * populated tree as statically initialized objects, and tests build small
 * fixture trees by hand.
 */

const {
  listItemPath,
  specPathJoin,
  specPathSegments,
  splitListItemSegment,
} = require('./spec_paths');

/**
 * The structural kind of a metadata node, mirroring DR1 §3.1
 * (`list | form | section | content | enum | complex | scalar`).
 */
const SomMetaKind = Object.freeze({
  /** A `List<T>` field; items are addressed by `-<seq>` path suffixes and
   *  described by {@link SomMetaNode#elementNode}. */
  LIST: 'list',
  /** A `@Form` content section (its fields live in {@link SomMetaNode#form}). */
  FORM: 'form',
  /** A field rendered as a section of its own. */
  SECTION: 'section',
  /** A free-text (markdown) content leaf. */
  CONTENT: 'content',
  /** An enum-valued leaf. */
  ENUM_VALUE: 'enum',
  /** A field typed by another model class (collapses into that class: the
   *  node's children are the target class's fields). */
  COMPLEX: 'complex',
  /** A plain scalar leaf (`String`/`int`/`double`/`bool`). */
  SCALAR: 'scalar',
});

/** The `@ContentType(type, description)` annotation captured on a node. */
class SomContentTypeMeta {
  constructor(type, description) {
    /** The declared content type (e.g. `code`, `diagram`). */
    this.type = type;
    /** The human/AI-facing description of the expected content. */
    this.description = description;
  }
}

/** One field of a `@Form` section (DR1 §3.1 `FormMeta.fields`). */
class SomFormFieldMeta {
  constructor({
    name,
    typeName,
    order,
    description = null,
    required = false,
    hint = null,
  }) {
    /** The exact model field name (`approvedBy`). */
    this.name = name;
    /** The Dart type name of the field (`String`, `int`, …). */
    this.typeName = typeName;
    /** The display label / description, when the form declares one. */
    this.description = description;
    /** Whether the form marks the field as required. */
    this.required = required;
    /** The authoring hint (e.g. `e.g. 1.0`), when present. */
    this.hint = hint;
    /** Declaration order within the form. */
    this.order = order;
  }
}

/** The form metadata of a `@Form` node (DR1 §3.1 `FormMeta`). */
class SomFormMeta {
  constructor(fields) {
    /** The form's fields in declaration order. */
    this.fields = fields;
  }

  /** The field named `name`, or `null` when absent. */
  fieldNamed(name) {
    return this.fields.find((f) => f.name === name) || null;
  }
}

/** The `@Document` metadata carried by a document root (DR1 §3.1 `DocMeta`). */
class SomDocMeta {
  constructor({ name, description, basedOn = null }) {
    /** The document's display name (`Solution Blueprint`). */
    this.name = name;
    /** The document's description. */
    this.description = description;
    /** Class names of the documents this one is based on
     *  (`@Document.basedOn`). */
    this.basedOn = basedOn !== null && basedOn !== undefined ? basedOn : [];
  }
}

/** One `@SecondLevelSectionId(documentClass, id)` entry (DR1 §3.1). */
class SomSecondLevelId {
  constructor(documentClass, id) {
    /** The document class the second-level id applies within. */
    this.documentClass = documentClass;
    /** The section id used in that document. */
    this.id = id;
  }
}

/**
 * One annotation captured losslessly into the generic `extra` list —
 * annotations the tree defines no dedicated slot for (DR1 §3.1 note), e.g.
 * `@Max`, `@MinLength`, `@PatternCheck`, `@TextRequired`.
 */
class SomMetaExtra {
  constructor(annotation, args = null) {
    /** The annotation's class name (`Max`, `PatternCheck`, …). */
    this.annotation = annotation;
    /** The resolved constructor arguments (`{count: 4}`). */
    this.args = args !== null && args !== undefined ? args : {};
  }
}

/**
 * One node of the SOM metadata tree (DR1 §3.1 `MetaNode`).
 *
 * A node describes one navigable position of a document root's structure: the
 * document root itself, a field, or a list's element subtree. Class-level
 * annotations attach to the node where the class is *instantiated*;
 * field-level annotations attach to the node directly (field-level
 * `@SectionId` wins over the target class's).
 *
 * Nodes are immutable value carriers; {@link SomMetaTree} wires the parent
 * links and absolute paths when the tree is constructed. A node instance
 * belongs to at most one tree.
 */
class SomMetaNode {
  constructor({
    className,
    kind,
    typeName,
    memberName = null,
    sectionId = null,
    classSectionId = null,
    sectionIdPattern = null,
    serializationOrder = null,
    min = null,
    unused = false,
    contentType = null,
    contentHelp = null,
    comment = null,
    docComment = null,
    classDocComment = null,
    form = null,
    document = null,
    mapsTo = null,
    detailedIn = null,
    secondLevelIds = null,
    extra = null,
    recursive = false,
    children = null,
    elementNode = null,
  }) {
    /** The exact model class name this node is (for root/complex/section
     *  nodes: the instantiated class; for leaves: the declaring class of the
     *  field). */
    this.className = className;
    /** The exact field name in the parent class, or `null` on the document
     *  root and on list element subtrees. */
    this.memberName = memberName;
    /** The effective `@SectionId` (field-level wins over class-level). */
    this.sectionId = sectionId;
    /** The target class's own `@SectionId` (DR1 §2.2 fallback): the id its
     *  DR3 schema type is keyed by, used only to build the mapping key of a
     *  section/complex node whose field carries no id. Never enters
     *  {@link segment} — the path stays field-level. */
    this.classSectionId = classSectionId;
    /** The `@SectionIdPattern` on a list field (item ids), when any. */
    this.sectionIdPattern = sectionIdPattern;
    /** The structural kind of the node. */
    this.kind = kind;
    /** The Dart type name of the field/class (`String`, `GoalEntry`, …). */
    this.typeName = typeName;
    /** `@SerializationOrder(order)`, when annotated. */
    this.serializationOrder = serializationOrder;
    /** `@Min(count)`, when annotated. */
    this.min = min;
    /** Whether `@Unused` is present on the node. */
    this.unused = unused;
    /** `@ContentType`, when annotated. */
    this.contentType = contentType;
    /** `@ContentHelp(guidance)`, when annotated. */
    this.contentHelp = contentHelp;
    /** `@Comment(text)`, when annotated. */
    this.comment = comment;
    /** The cleaned `///` doc comment (member wins over class), when any. */
    this.docComment = docComment;
    /** The instantiated class's own doc comment, when it differs from
     *  {@link docComment}. */
    this.classDocComment = classDocComment;
    /** Form metadata, for {@link SomMetaKind}.FORM nodes. */
    this.form = form;
    /** `@Document` metadata; non-`null` only on the document root. */
    this.document = document;
    /** `@MapsTo` target class name, when annotated. */
    this.mapsTo = mapsTo;
    /** `@DetailedIn` target class name, when annotated. */
    this.detailedIn = detailedIn;
    /** `@SecondLevelSectionId` entries, when annotated. */
    this.secondLevelIds =
      secondLevelIds !== null && secondLevelIds !== undefined
        ? secondLevelIds
        : [];
    /** Annotations without a dedicated slot, captured losslessly. */
    this.extra = extra !== null && extra !== undefined ? extra : [];
    /** Whether this node is a recursive re-entry reference (a class already
     *  on the descent stack): `kind == COMPLEX`, no children. */
    this.recursive = recursive;
    /** The child nodes, in `@SerializationOrder` order. For complex/section
     *  nodes these are the target class's fields (the class collapses onto
     *  the node); empty for leaves and recursive references. */
    this.children = children !== null && children !== undefined ? children : [];
    /** For {@link SomMetaKind}.LIST nodes: the element class subtree. Its
     *  children describe each item's structure; item positions have no static
     *  path (see {@link path}). */
    this.elementNode = elementNode;

    // --- tree wiring (set once by SomMetaTree) ---------------------------
    this._tree = null;
    this._parent = null;
    this._path = null;
  }

  /**
   * The tree this node belongs to.
   *
   * Throws an {@link Error} when the node has not been attached to a
   * {@link SomMetaTree} yet.
   */
  get tree() {
    const t = this._tree;
    if (t === null) {
      throw new Error(
        `SomMetaNode(${this.debugName}) is not attached to a SomMetaTree`,
      );
    }
    return t;
  }

  /**
   * The parent node, or `null` on the document root. The parent of a list's
   * {@link elementNode} is the list node itself.
   */
  get parent() {
    this.tree; // attachment guard
    return this._parent;
  }

  /**
   * The node's absolute document path per the §4 path grammar
   * (`<rootSegment>/<segment>/…`), or `null` for nodes inside a list element
   * subtree — their concrete paths depend on the item sequence (see
   * {@link itemPath} on the list node and {@link SomMetaTree#byPath}).
   */
  get path() {
    this.tree; // attachment guard
    return this._path;
  }

  /**
   * The path segment this node contributes: the effective {@link sectionId}
   * when present, else the {@link memberName}, else the {@link className}
   * (document root).
   */
  get segment() {
    return this.sectionId || this.memberName || this.className;
  }

  /**
   * The path of the `seq`-th item of this list node (`<path>-<seq>`).
   *
   * Throws an {@link Error} when the node is not a list or has no static
   * path.
   */
  itemPath(seq) {
    if (this.kind !== SomMetaKind.LIST) {
      throw new Error(
        `itemPath() requires a list node, ${this.debugName} is ${this.kind}`,
      );
    }
    const p = this.path;
    if (p === null) {
      throw new Error(
        `list ${this.debugName} sits inside a list element subtree and has ` +
          'no static path',
      );
    }
    return listItemPath(p, seq);
  }

  /** The direct child whose {@link memberName} equals `name`, or `null`. */
  childByMember(name) {
    return this.children.find((c) => c.memberName === name) || null;
  }

  /** The direct child whose {@link segment} equals `seg`, or `null`. */
  childBySegment(seg) {
    return this.children.find((c) => c.segment === seg) || null;
  }

  /** A short identification for error messages. */
  get debugName() {
    if (this.memberName === null || this.memberName === undefined) {
      return this.className;
    }
    return `${this.className}.${this.memberName}`;
  }
}

function _escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function _matchesPattern(pattern, id) {
  const regex = new RegExp(
    '^' + pattern.split('xxx').map(_escapeRegExp).join('[0-9]+') + '$',
  );
  return regex.test(id);
}

/**
 * The metadata tree of one document root: parent/path wiring plus the two
 * dynamic lookups ({@link byId}, {@link byPath}) DR1 §4.3 requires every
 * runtime to keep.
 */
class SomMetaTree {
  /**
   * Wires `root`'s subtree: sets parent links, computes static paths, and
   * indexes section ids.
   *
   * Throws an {@link Error} when `root` carries no `@Document` metadata, and
   * when any node is already attached to another tree (nodes belong to
   * exactly one tree).
   */
  constructor(root) {
    if (root.document === null || root.document === undefined) {
      throw new Error(
        'the tree root must carry @Document metadata ' +
          `(SomMetaNode.document): ${root.debugName}`,
      );
    }
    /** The document root node (carries {@link SomMetaNode#document}). */
    this.root = root;
    /** @type {Map<string, SomMetaNode[]>} */
    this._byId = new Map();
    /** @type {SomMetaNode[]} */
    this._allNodes = [];
    this._wire(root, null, root.segment);
  }

  _wire(node, parent, path) {
    if (node._tree !== null) {
      throw new Error(
        `SomMetaNode(${node.debugName}) is already attached to a ` +
          'SomMetaTree; nodes belong to exactly one tree',
      );
    }
    node._tree = this;
    node._parent = parent;
    node._path = path;
    this._allNodes.push(node);
    const id = node.sectionId;
    if (id !== null && id !== undefined) {
      let bucket = this._byId.get(id);
      if (!bucket) {
        bucket = [];
        this._byId.set(id, bucket);
      }
      bucket.push(node);
    }
    for (const child of node.children) {
      this._wire(child, node, SomMetaTree._childPath(path, child));
    }
    const element = node.elementNode;
    if (element !== null && element !== undefined) {
      // Item positions are dynamic (`<listPath>-<seq>`), so the element
      // subtree carries no static paths.
      this._wire(element, node, null);
    }
  }

  static _childPath(parentPath, child) {
    if (parentPath === null) {
      return null;
    }
    return specPathJoin(parentPath, child.segment);
  }

  /**
   * Every node of the tree (document order; element subtrees follow their
   * list node).
   */
  get allNodes() {
    return this._allNodes;
  }

  // --- lookup by section id ------------------------------------------------

  /**
   * All nodes whose effective section id equals `sectionId`, in document
   * order. A shared class instantiated at several positions yields several
   * nodes (ids resolve within their parent chain, DR1 §1.2).
   */
  allById(sectionId) {
    return this._byId.get(sectionId) || [];
  }

  /**
   * The first node whose effective section id equals `sectionId`.
   *
   * A *resolved list-item id* (a list's `@SectionIdPattern` with the `xxx`
   * placeholder replaced by digits, e.g. `GOAL-ITEM-3`) resolves to that
   * list's element subtree. Returns `null` when nothing matches.
   */
  byId(sectionId) {
    const exact = this._byId.get(sectionId);
    if (exact && exact.length > 0) {
      return exact[0];
    }
    for (const node of this._allNodes) {
      const pattern = node.sectionIdPattern;
      if (
        pattern !== null &&
        pattern !== undefined &&
        _matchesPattern(pattern, sectionId)
      ) {
        return node.elementNode || node;
      }
    }
    return null;
  }

  // --- lookup by path ------------------------------------------------------

  /**
   * Resolves a document `path` (the §4 grammar: segments joined by `/`, list
   * items as `-<seq>` suffixes) to the metadata node it addresses, or `null`
   * when the path does not describe a reachable position.
   *
   * A list-item segment (`<listSegment>-<seq>`) resolves to the list's
   * element subtree; segments below it match the element class's fields. A
   * list *container* path is only valid as the final segment (descending past
   * a list requires an item suffix).
   */
  byPath(path) {
    const segs = specPathSegments(path);
    if (segs.length === 0 || segs[0] !== this.root.segment) {
      return null;
    }

    let node = this.root;
    for (let i = 1; i < segs.length; i++) {
      const seg = segs[i];
      const last = i === segs.length - 1;

      // Prefer an exact segment match; only then try a list-item suffix, so
      // a hyphenated @SectionId is never mis-read as an item.
      const child = node.childBySegment(seg);
      if (child !== null) {
        if (child.kind === SomMetaKind.LIST && !last) {
          return null; // a list path needs a `-<seq>` item suffix
        }
        if (child.recursive && !last) {
          return null; // chains terminate at recursive re-entries
        }
        node = child;
        continue;
      }

      const split = splitListItemSegment(seg);
      if (split === null) {
        return null;
      }
      const listNode = node.childBySegment(split.base);
      if (listNode === null || listNode.kind !== SomMetaKind.LIST) {
        return null;
      }
      const element = listNode.elementNode;
      if (element === null || element === undefined) {
        // Scalar list without an element subtree: the item is a value leaf.
        return last ? listNode : null;
      }
      node = element;
    }
    return node;
  }
}

/**
 * One position of the generated **dot-notation / ID-tree access surfaces**
 * (DR1 §4): an absolute document {@link path} bound to the {@link tree} it
 * belongs to.
 *
 * The generated facades (DR8) emit one accessor class per model class whose
 * getters return further {@link SomMetaRef}s. Every accessor exposes at least
 * {@link path} and {@link meta} (the {@link SomMetaNode} at that position).
 * This base class is the leaf accessor itself (content/scalar/enum/form
 * positions).
 */
class SomMetaRef {
  constructor(tree, path) {
    /** The metadata tree of the document root this position belongs to. */
    this.tree = tree;
    /** The absolute document path of this position (§4 path grammar). */
    this.path = path;
  }

  /**
   * The metadata node at {@link path}.
   *
   * Throws an {@link Error} when the path resolves to no node — only possible
   * past a recursive re-entry, where the generated chain has ended and the
   * metadata tree carries no further nodes (DR1 §4.1 cycle rule).
   */
  get meta() {
    const node = this.tree.byPath(this.path);
    if (node === null) {
      throw new Error(
        `no metadata node at "${this.path}" — the position lies beyond a ` +
          'recursive re-entry; use the dynamic tree lookups instead',
      );
    }
    return node;
  }
}

/**
 * The generated accessor for a **list** position (DR1 §4.1): {@link path} is
 * the list container path; {@link item} returns the accessor for the `seq`-th
 * item position (`<path>-<seq>`), whose children are the element class's
 * accessors.
 */
class SomListMetaRef extends SomMetaRef {
  /**
   * @param {SomMetaTree} tree
   * @param {string} path
   * @param {(tree: SomMetaTree, path: string) => any} element
   */
  constructor(tree, path, element) {
    super(tree, path);
    this._element = element;
  }

  /** The accessor at the item position `<path>-<seq>`. */
  item(seq) {
    return this._element(this.tree, listItemPath(this.path, seq));
  }
}

module.exports = {
  SomMetaKind,
  SomContentTypeMeta,
  SomFormFieldMeta,
  SomFormMeta,
  SomDocMeta,
  SomSecondLevelId,
  SomMetaExtra,
  SomMetaNode,
  SomMetaTree,
  SomMetaRef,
  SomListMetaRef,
};
