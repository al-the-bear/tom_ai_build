/**
 * Generic, value-free traversal of a {@link SpecModel} class graph (the
 * "reflection" surface) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_reflection.dart` (and the JavaScript
 * `spec_reflection.js`).
 *
 * It answers two kinds of question about a model: **enumeration** (what roots,
 * classes, fields and annotations exist) and **resolution** (which model node a
 * concrete document *path* addresses). It holds no document values.
 */

import {
  SpecAnnotation,
  SpecClass,
  SpecField,
  SpecFieldKind,
  SpecModel,
  SpecRoot,
} from './spec_model';
import { specPathSegments, splitListItemSegment } from './spec_paths';

/** What a resolved path lands on in the model. */
export const SpecNodeKind = {
  ROOT: 'root',
  COMPLEX: 'complex',
  SECTION: 'section',
  LIST: 'list',
  LIST_ITEM_COMPLEX: 'listItemComplex',
  LIST_ITEM_SCALAR: 'listItemScalar',
  FORM: 'form',
  CONTENT: 'content',
  ENUM_VALUE: 'enumValue',
  SCALAR: 'scalar',
} as const;

export type SpecNodeKindValue =
  (typeof SpecNodeKind)[keyof typeof SpecNodeKind];

const _VALUE_LEAF_KINDS = new Set<string>([
  SpecNodeKind.CONTENT,
  SpecNodeKind.ENUM_VALUE,
  SpecNodeKind.SCALAR,
  SpecNodeKind.LIST_ITEM_SCALAR,
]);

/** The outcome of resolving a document path against a {@link SpecModel}. */
export class SpecResolution {
  path: string;
  kind: SpecNodeKindValue;
  root: SpecRoot;
  field: SpecField | null;
  targetClass: SpecClass | null;

  constructor(props: {
    path: string;
    kind: SpecNodeKindValue;
    root: SpecRoot;
    field?: SpecField | null;
    targetClass?: SpecClass | null;
  }) {
    this.path = props.path;
    this.kind = props.kind;
    this.root = props.root;
    this.field = props.field != null ? props.field : null;
    this.targetClass = props.targetClass != null ? props.targetClass : null;
  }

  /**
   * Whether a single string value is stored directly at this path (a content,
   * enum, scalar leaf, or a scalar list item).
   */
  get isValueLeaf(): boolean {
    return _VALUE_LEAF_KINDS.has(this.kind);
  }
}

const _LEAF_KINDS: Record<string, SpecNodeKindValue> = {
  [SpecFieldKind.FORM]: SpecNodeKind.FORM,
  [SpecFieldKind.CONTENT]: SpecNodeKind.CONTENT,
  [SpecFieldKind.ENUM]: SpecNodeKind.ENUM_VALUE,
  [SpecFieldKind.SCALAR]: SpecNodeKind.SCALAR,
};

/** Read-only queries over a {@link SpecModel}. */
export class SpecReflection {
  model: SpecModel;

  constructor(model: SpecModel) {
    this.model = model;
  }

  // --- enumeration --------------------------------------------------------

  get roots(): SpecRoot[] {
    return this.model.roots;
  }

  get classes(): SpecClass[] {
    return Array.from(this.model.classes.values());
  }

  classNamed(name: string | null | undefined): SpecClass | null {
    return this.model.classNamed(name);
  }

  fieldsOf(className: string): SpecField[] {
    const cls = this.classNamed(className);
    return cls ? cls.fields : [];
  }

  annotationsOf(className: string): SpecAnnotation[] {
    const cls = this.classNamed(className);
    return cls ? cls.annotations : [];
  }

  fieldAnnotations(className: string, fieldName: string): SpecAnnotation[] {
    const cls = this.classNamed(className);
    if (cls === null) {
      return [];
    }
    const f = cls.fieldNamed(fieldName);
    return f ? f.annotations : [];
  }

  // --- resolution ---------------------------------------------------------

  rootSegment(root: SpecRoot): string {
    return root.sectionId || root.type;
  }

  fieldSegment(field: SpecField): string {
    return field.sectionId || field.name;
  }

  rootForSegment(segment: string): SpecRoot | null {
    for (const r of this.model.roots) {
      if (this.rootSegment(r) === segment) {
        return r;
      }
    }
    return null;
  }

  private _matchField(cls: SpecClass, segment: string): SpecField | null {
    for (const f of cls.fields) {
      if (this.fieldSegment(f) === segment) {
        return f;
      }
    }
    return null;
  }

  /**
   * Resolves a document `path` to the model node it addresses, or `null` when the
   * path does not describe a reachable node.
   */
  resolve(path: string): SpecResolution | null {
    const segs = specPathSegments(path);
    if (segs.length === 0 || segs[0] === '') {
      return null;
    }

    const root = this.rootForSegment(segs[0]);
    if (root === null) {
      return null;
    }

    let curClass = this.classNamed(root.type);
    if (segs.length === 1) {
      return new SpecResolution({
        path,
        kind: SpecNodeKind.ROOT,
        root,
        targetClass: curClass,
      });
    }

    for (let i = 1; i < segs.length; i++) {
      const cls = curClass;
      if (cls === null) {
        return null; // cannot descend into a non-class
      }
      const seg = segs[i];
      const last = i === segs.length - 1;

      // Prefer an exact field-segment match; only then try a list-item suffix,
      // so a hyphenated @SectionId is never mis-read as an item.
      const field = this._matchField(cls, seg);
      if (field !== null) {
        if (
          field.kind === SpecFieldKind.COMPLEX ||
          field.kind === SpecFieldKind.SECTION
        ) {
          curClass = this.classNamed(field.type);
          if (last) {
            return new SpecResolution({
              path,
              kind:
                field.kind === SpecFieldKind.COMPLEX
                  ? SpecNodeKind.COMPLEX
                  : SpecNodeKind.SECTION,
              root,
              field,
              targetClass: curClass,
            });
          }
          continue; // descend into the collapsed class
        }
        if (field.kind === SpecFieldKind.LIST) {
          return last
            ? new SpecResolution({ path, kind: SpecNodeKind.LIST, root, field })
            : null; // a list path needs a -<seq> item suffix
        }
        // form / content / enum / scalar leaves
        return last
          ? new SpecResolution({
              path,
              kind: _LEAF_KINDS[field.kind],
              root,
              field,
            })
          : null; // a leaf cannot have further segments
      }

      const split = splitListItemSegment(seg);
      if (split === null) {
        return null;
      }
      const listField = this._matchField(cls, split.base);
      if (listField === null || listField.kind !== SpecFieldKind.LIST) {
        return null;
      }
      if (listField.elementIsComplex) {
        curClass = this.classNamed(listField.elementType);
        if (last) {
          return new SpecResolution({
            path,
            kind: SpecNodeKind.LIST_ITEM_COMPLEX,
            root,
            field: listField,
            targetClass: curClass,
          });
        }
        continue;
      }
      // Scalar list item: a value leaf, so it must be the final segment.
      if (last) {
        return new SpecResolution({
          path,
          kind: SpecNodeKind.LIST_ITEM_SCALAR,
          root,
          field: listField,
        });
      }
      return null;
    }
    return null;
  }
}
