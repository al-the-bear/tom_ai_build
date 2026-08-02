/**
 * The canonical SOM **metadata tree** — the runtime's SOM §7.1 node types; a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_meta.dart` (and the
 * JavaScript `spec_meta.js`).
 *
 * One {@link SomMetaTree} exists per document root. Its nodes carry *every*
 * `tom_specs_core` annotation the model source declares, plus the exact class
 * and member names, so the tree is the single language-neutral description of a
 * document's structure:
 *
 *   * {@link SomMetaNode} — one node per navigable model position (SOM §7.1), with
 *     section id / pattern, kind, serialization order, `@Min`, content type,
 *     help/comment/doc texts, form metadata, traceability links
 *     (`@MapsTo` / `@DetailedIn`) and the lossless
 *     `extra` annotation list;
 *   * {@link SomMetaTree} — wires parent links and absolute paths (the SOM §8 path
 *     grammar shared with `spec_paths`) and provides the two dynamic lookups
 *     every runtime keeps: {@link SomMetaTree.byId} and
 *     {@link SomMetaTree.byPath}.
 *
 * The runtime only *defines* these types; the generated facades (SOM §8) emit the
 * populated tree as statically initialized objects, and tests build small
 * fixture trees by hand.
 */

import { listItemPath, specPathJoin, specPathSegments, splitListItemSegment } from './spec_paths';

/**
 * The structural kind of a metadata node, mirroring SOM §7.1
 * (`list | form | section | content | enum | complex | scalar`).
 */
export const SomMetaKind = {
  /** A `List<T>` field; items are addressed by `-<seq>` path suffixes and
   *  described by {@link SomMetaNode.elementNode}. */
  LIST: 'list',
  /** A `@Form` content section (its fields live in {@link SomMetaNode.form}). */
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
} as const;

export type SomMetaKindValue = (typeof SomMetaKind)[keyof typeof SomMetaKind];

/** The `@ContentType(type, description)` annotation captured on a node. */
export class SomContentTypeMeta {
  /** The declared content type (e.g. `code`, `diagram`). */
  type: string;
  /** The human/AI-facing description of the expected content. */
  description: string;

  constructor(type: string, description: string) {
    this.type = type;
    this.description = description;
  }
}

/** Constructor options for {@link SomFormFieldMeta}. */
export interface SomFormFieldMetaInit {
  name: string;
  typeName: string;
  order: number;
  description?: string | null;
  required?: boolean;
  hint?: string | null;
  enumValues?: string[] | null;
  refersTo?: string[] | null;
}

/** One field of a `@Form` section (SOM §7.1 `FormMeta.fields`). */
export class SomFormFieldMeta {
  /** The exact model field name (`approvedBy`). */
  name: string;
  /** The Dart type name of the field (`String`, `int`, …). */
  typeName: string;
  /** The display label / description, when the form declares one. */
  description: string | null;
  /** Whether the form marks the field as required. */
  required: boolean;
  /** The authoring hint (e.g. `e.g. 1.0`), when present. */
  hint: string | null;
  /** Declaration order within the form. */
  order: number;
  /**
   * Enum constant names when `typeName` is a model enum (YRD7); empty for
   * non-enum field types. The complete value domain of an enum-typed form
   * field, so editors and the generic modification API can validate and
   * convert without generated code.
   */
  enumValues: string[];
  /**
   * The registry key(s) this field's value is an *id drawn from*, each written
   * `<SECTIONID>.<formFieldName>` (csrb3); empty for a field that is not a
   * reference. A value is valid when it resolves in *any* listed registry; a
   * reference naming several ids writes them comma-separated.
   */
  refersTo: string[];

  constructor(init: SomFormFieldMetaInit) {
    this.name = init.name;
    this.typeName = init.typeName;
    this.description = init.description != null ? init.description : null;
    this.required = init.required != null ? init.required : false;
    this.hint = init.hint != null ? init.hint : null;
    this.order = init.order;
    this.enumValues = init.enumValues != null ? init.enumValues : [];
    this.refersTo = init.refersTo != null ? init.refersTo : [];
  }
}

/** The form metadata of a `@Form` node (SOM §7.1 `FormMeta`). */
export class SomFormMeta {
  /** The form's fields in declaration order. */
  fields: SomFormFieldMeta[];

  constructor(fields: SomFormFieldMeta[]) {
    this.fields = fields;
  }

  /** The field named `name`, or `null` when absent. */
  fieldNamed(name: string): SomFormFieldMeta | null {
    return this.fields.find((f) => f.name === name) || null;
  }
}

/** Constructor options for {@link SomDocMeta}. */
export interface SomDocMetaInit {
  name: string;
  description: string;
  basedOn?: string[] | null;
}

/** The `@Document` metadata carried by a document root (SOM §7.1 `DocMeta`). */
export class SomDocMeta {
  /** The document's display name (`Solution Blueprint`). */
  name: string;
  /** The document's description. */
  description: string;
  /** Class names of the documents this one is based on
   *  (`@Document.basedOn`). */
  basedOn: string[];

  constructor(init: SomDocMetaInit) {
    this.name = init.name;
    this.description = init.description;
    this.basedOn = init.basedOn != null ? init.basedOn : [];
  }
}

/**
 * One annotation captured losslessly into the generic `extra` list —
 * annotations the tree defines no dedicated slot for (SOM §7.1 note), e.g.
 * `@Max`, `@MinLength`, `@PatternCheck`, `@TextRequired`.
 */
export class SomMetaExtra {
  /** The annotation's class name (`Max`, `PatternCheck`, …). */
  annotation: string;
  /** The resolved constructor arguments (`{count: 4}`). */
  args: Record<string, unknown>;

  constructor(annotation: string, args: Record<string, unknown> | null = null) {
    this.annotation = annotation;
    this.args = args != null ? args : {};
  }
}

/** Constructor options for {@link SomMetaNode} (SOM §7.1 `MetaNode`). */
export interface SomMetaNodeInit {
  className: string;
  kind: SomMetaKindValue;
  typeName: string;
  memberName?: string | null;
  sectionId?: string | null;
  classSectionId?: string | null;
  sectionIdPattern?: string | null;
  serializationOrder?: number | null;
  min?: number | null;
  unused?: boolean;
  contentType?: SomContentTypeMeta | null;
  contentHelp?: string | null;
  headline?: string | null;
  comment?: string | null;
  docComment?: string | null;
  classDocComment?: string | null;
  form?: SomFormMeta | null;
  document?: SomDocMeta | null;
  mapsTo?: string | null;
  detailedIn?: string | null;
  extra?: SomMetaExtra[] | null;
  recursive?: boolean;
  children?: SomMetaNode[] | null;
  elementNode?: SomMetaNode | null;
}

/**
 * One node of the SOM metadata tree (SOM §7.1 `MetaNode`).
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
export class SomMetaNode {
  /** The exact model class name this node is (for root/complex/section
   *  nodes: the instantiated class; for leaves: the declaring class of the
   *  field). */
  className: string;
  /** The exact field name in the parent class, or `null` on the document
   *  root and on list element subtrees. */
  memberName: string | null;
  /** The effective `@SectionId` (field-level wins over class-level). */
  sectionId: string | null;
  /** The target class's own `@SectionId` (SOM §12.2 fallback): the id its generated
   *  schema type is keyed by, used only to build the mapping key of a
   *  section/complex node whose field carries no id. Never enters
   *  {@link segment} — the path stays field-level. */
  classSectionId: string | null;
  /** The `@SectionIdPattern` on a list field (item ids), when any. */
  sectionIdPattern: string | null;
  /** The structural kind of the node. */
  kind: SomMetaKindValue;
  /** The Dart type name of the field/class (`String`, `GoalEntry`, …). */
  typeName: string;
  /** `@SerializationOrder(order)`, when annotated. */
  serializationOrder: number | null;
  /** `@Min(count)`, when annotated. */
  min: number | null;
  /** Whether `@Unused` is present on the node. */
  unused: boolean;
  /** `@ContentType`, when annotated. */
  contentType: SomContentTypeMeta | null;
  /** `@ContentHelp(guidance)`, when annotated. */
  contentHelp: string | null;
  /**
   * The `@Headline(text)` predefined DEFAULT headline (YRD4; field-level
   * wins over the target class's), when annotated.
   *
   * Render precedence: `stored headline > this default > name derivation`.
   * Editors prefill a new section's headline from this; a stored headline
   * always wins and stays editable.
   */
  headline: string | null;
  /** `@Comment(text)`, when annotated. */
  comment: string | null;
  /** The cleaned `///` doc comment (member wins over class), when any. */
  docComment: string | null;
  /** The instantiated class's own doc comment, when it differs from
   *  {@link docComment}. */
  classDocComment: string | null;
  /** Form metadata, for {@link SomMetaKind}.FORM nodes. */
  form: SomFormMeta | null;
  /** `@Document` metadata; non-`null` only on the document root. */
  document: SomDocMeta | null;
  /** `@MapsTo` target class name, when annotated. */
  mapsTo: string | null;
  /** `@DetailedIn` target class name, when annotated. */
  detailedIn: string | null;
  /** Annotations without a dedicated slot, captured losslessly. */
  extra: SomMetaExtra[];
  /** Whether this node is a recursive re-entry reference (a class already
   *  on the descent stack): `kind == COMPLEX`, no children. */
  recursive: boolean;
  /** The child nodes, in `@SerializationOrder` order. For complex/section
   *  nodes these are the target class's fields (the class collapses onto
   *  the node); empty for leaves and recursive references. */
  children: SomMetaNode[];
  /** For {@link SomMetaKind}.LIST nodes: the element class subtree. Its
   *  children describe each item's structure; item positions have no static
   *  path (see {@link path}). */
  elementNode: SomMetaNode | null;

  // --- tree wiring (set once by SomMetaTree) -----------------------------
  /** @internal */
  _tree: SomMetaTree | null = null;
  /** @internal */
  _parent: SomMetaNode | null = null;
  /** @internal */
  _path: string | null = null;

  constructor(init: SomMetaNodeInit) {
    this.className = init.className;
    this.memberName = init.memberName != null ? init.memberName : null;
    this.sectionId = init.sectionId != null ? init.sectionId : null;
    this.classSectionId =
      init.classSectionId != null ? init.classSectionId : null;
    this.sectionIdPattern =
      init.sectionIdPattern != null ? init.sectionIdPattern : null;
    this.kind = init.kind;
    this.typeName = init.typeName;
    this.serializationOrder =
      init.serializationOrder != null ? init.serializationOrder : null;
    this.min = init.min != null ? init.min : null;
    this.unused = init.unused != null ? init.unused : false;
    this.contentType = init.contentType != null ? init.contentType : null;
    this.contentHelp = init.contentHelp != null ? init.contentHelp : null;
    this.headline = init.headline != null ? init.headline : null;
    this.comment = init.comment != null ? init.comment : null;
    this.docComment = init.docComment != null ? init.docComment : null;
    this.classDocComment =
      init.classDocComment != null ? init.classDocComment : null;
    this.form = init.form != null ? init.form : null;
    this.document = init.document != null ? init.document : null;
    this.mapsTo = init.mapsTo != null ? init.mapsTo : null;
    this.detailedIn = init.detailedIn != null ? init.detailedIn : null;
    this.extra = init.extra != null ? init.extra : [];
    this.recursive = init.recursive != null ? init.recursive : false;
    this.children = init.children != null ? init.children : [];
    this.elementNode = init.elementNode != null ? init.elementNode : null;
  }

  /**
   * The tree this node belongs to.
   *
   * Throws an {@link Error} when the node has not been attached to a
   * {@link SomMetaTree} yet.
   */
  get tree(): SomMetaTree {
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
  get parent(): SomMetaNode | null {
    this.tree; // attachment guard
    return this._parent;
  }

  /**
   * The node's absolute document path per the SOM §8 path grammar
   * (`<rootSegment>/<segment>/…`), or `null` for nodes inside a list element
   * subtree — their concrete paths depend on the item sequence (see
   * {@link itemPath} on the list node and {@link SomMetaTree.byPath}).
   */
  get path(): string | null {
    this.tree; // attachment guard
    return this._path;
  }

  /**
   * The path segment this node contributes: the effective {@link sectionId}
   * when present, else the {@link memberName}, else the {@link className}
   * (document root).
   */
  get segment(): string {
    return this.sectionId || this.memberName || this.className;
  }

  /**
   * The path of the `seq`-th item of this list node (`<path>-<seq>`).
   *
   * Throws an {@link Error} when the node is not a list or has no static
   * path.
   */
  itemPath(seq: number): string {
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
  childByMember(name: string): SomMetaNode | null {
    return this.children.find((c) => c.memberName === name) || null;
  }

  /** The direct child whose {@link segment} equals `seg`, or `null`. */
  childBySegment(seg: string): SomMetaNode | null {
    return this.children.find((c) => c.segment === seg) || null;
  }

  /** A short identification for error messages. */
  get debugName(): string {
    if (this.memberName === null || this.memberName === undefined) {
      return this.className;
    }
    return `${this.className}.${this.memberName}`;
  }
}

function _escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function _matchesPattern(pattern: string, id: string): boolean {
  const regex = new RegExp(
    '^' + pattern.split('xxx').map(_escapeRegExp).join('[0-9]+') + '$',
  );
  return regex.test(id);
}

/**
 * The metadata tree of one document root: parent/path wiring plus the two
 * dynamic lookups ({@link byId}, {@link byPath}) SOM §10 requires every
 * runtime to keep.
 */
export class SomMetaTree {
  /** The document root node (carries {@link SomMetaNode.document}). */
  root: SomMetaNode;
  private _byId: Map<string, SomMetaNode[]> = new Map();
  private _allNodes: SomMetaNode[] = [];

  /**
   * Wires `root`'s subtree: sets parent links, computes static paths, and
   * indexes section ids.
   *
   * Throws an {@link Error} when `root` carries no `@Document` metadata, and
   * when any node is already attached to another tree (nodes belong to
   * exactly one tree).
   */
  constructor(root: SomMetaNode) {
    if (root.document === null || root.document === undefined) {
      throw new Error(
        'the tree root must carry @Document metadata ' +
          `(SomMetaNode.document): ${root.debugName}`,
      );
    }
    this.root = root;
    this._wire(root, null, root.segment);
  }

  private _wire(
    node: SomMetaNode,
    parent: SomMetaNode | null,
    path: string | null,
  ): void {
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

  private static _childPath(
    parentPath: string | null,
    child: SomMetaNode,
  ): string | null {
    if (parentPath === null) {
      return null;
    }
    return specPathJoin(parentPath, child.segment);
  }

  /**
   * Every node of the tree (document order; element subtrees follow their
   * list node).
   */
  get allNodes(): SomMetaNode[] {
    return this._allNodes;
  }

  // --- lookup by section id ------------------------------------------------

  /**
   * All nodes whose effective section id equals `sectionId`, in document
   * order. A shared class instantiated at several positions yields several
   * nodes (ids resolve within their parent chain, SOM §11.2).
   */
  allById(sectionId: string): SomMetaNode[] {
    return this._byId.get(sectionId) || [];
  }

  /**
   * The first node whose effective section id equals `sectionId`.
   *
   * A *resolved list-item id* (a list's `@SectionIdPattern` with the `xxx`
   * placeholder replaced by digits, e.g. `GOAL-ITEM-3`) resolves to that
   * list's element subtree. Returns `null` when nothing matches.
   */
  byId(sectionId: string): SomMetaNode | null {
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
   * Resolves a document `path` (the SOM §8 grammar: segments joined by `/`, list
   * items as `-<seq>` suffixes) to the metadata node it addresses, or `null`
   * when the path does not describe a reachable position.
   *
   * A list-item segment (`<listSegment>-<seq>`) resolves to the list's
   * element subtree; segments below it match the element class's fields. A
   * list *container* path is only valid as the final segment (descending past
   * a list requires an item suffix).
   */
  byPath(path: string): SomMetaNode | null {
    const segs = specPathSegments(path);
    if (segs.length === 0 || segs[0] !== this.root.segment) {
      return null;
    }

    let node: SomMetaNode = this.root;
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
 * (SOM §8): an absolute document {@link path} bound to the {@link tree} it
 * belongs to.
 *
 * The generated facades (SOM §8) emit one accessor class per model class whose
 * getters return further {@link SomMetaRef}s. Every accessor exposes at least
 * {@link path} and {@link meta} (the {@link SomMetaNode} at that position).
 * This base class is the leaf accessor itself (content/scalar/enum/form
 * positions).
 */
export class SomMetaRef {
  /** The metadata tree of the document root this position belongs to. */
  tree: SomMetaTree;
  /** The absolute document path of this position (SOM §8 path grammar). */
  path: string;

  constructor(tree: SomMetaTree, path: string) {
    this.tree = tree;
    this.path = path;
  }

  /**
   * The metadata node at {@link path}.
   *
   * Throws an {@link Error} when the path resolves to no node — only possible
   * past a recursive re-entry, where the generated chain has ended and the
   * metadata tree carries no further nodes (SOM §8 cycle rule).
   */
  get meta(): SomMetaNode {
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
 * The factory a {@link SomListMetaRef} uses to build the accessor for an item
 * position: `(tree, path) => ref`, where `ref` is the element class's
 * generated accessor.
 */
export type SomMetaRefFactory<T> = (tree: SomMetaTree, path: string) => T;

/**
 * The generated accessor for a **list** position (SOM §8): {@link path} is
 * the list container path; {@link item} returns the accessor for the `seq`-th
 * item position (`<path>-<seq>`), whose children are the element class's
 * accessors.
 */
export class SomListMetaRef<T = SomMetaRef> extends SomMetaRef {
  private _element: SomMetaRefFactory<T>;

  constructor(tree: SomMetaTree, path: string, element: SomMetaRefFactory<T>) {
    super(tree, path);
    this._element = element;
  }

  /** The accessor at the item position `<path>-<seq>`. */
  item(seq: number): T {
    return this._element(this.tree, listItemPath(this.path, seq));
  }
}
