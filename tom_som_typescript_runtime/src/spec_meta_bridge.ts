/**
 * Bridge from the meta-JSON class graph ({@link SpecModel}) to the canonical
 * metadata tree ({@link SomMetaTree}, DR1 §3.1) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_meta_bridge.dart` (and the JavaScript
 * `spec_meta_bridge.js`).
 *
 * The generated facades (DR8) emit populated {@link SomMetaTree}s directly;
 * every consumer that only has the exported spec-model meta-data (the
 * conformance harness, tooling) builds its tree here. The expansion follows
 * the same walk {@link SpecReflection.resolve} performs — crucially, a node's
 * {@link SomMetaNode.sectionId} is the **field-level** id exactly as exported
 * (`field.sectionId`), so the tree's path grammar stays byte-compatible with
 * the paths a {@link SpecDocument} is keyed by. (DR1 §2.2's "field id, else
 * target-class id" resolution is applied at *export* time by the model
 * exporter / DR8 generator, not re-derived here.)
 *
 * Recursive class references become terminal re-entry nodes
 * ({@link SomMetaNode.recursive}), mirroring how the generated chains
 * terminate.
 */

import {
  SomContentTypeMeta,
  SomDocMeta,
  SomFormFieldMeta,
  SomFormMeta,
  SomMetaExtra,
  SomMetaKind,
  SomMetaKindValue,
  SomMetaNode,
  SomMetaTree,
  SomSecondLevelId,
} from './spec_meta';
import {
  SpecAnnotation,
  SpecClass,
  SpecField,
  SpecFieldKind,
  SpecFieldKindValue,
  SpecModel,
} from './spec_model';

/**
 * Annotation names that have a dedicated {@link SomMetaNode} slot; everything
 * else is captured losslessly into {@link SomMetaNode.extra}.
 */
const _SLOTTED_ANNOTATIONS = new Set([
  'SectionId',
  'SectionIdPattern',
  'SerializationOrder',
  'Min',
  'Unused',
  'ContentType',
  'ContentHelp',
  'Headline',
  'Comment',
  'Form',
  'Document',
  'MapsTo',
  'DetailedIn',
  'SecondLevelSectionId',
]);

const _KIND_OF: Record<SpecFieldKindValue, SomMetaKindValue> = {
  [SpecFieldKind.LIST]: SomMetaKind.LIST,
  [SpecFieldKind.FORM]: SomMetaKind.FORM,
  [SpecFieldKind.SECTION]: SomMetaKind.SECTION,
  [SpecFieldKind.CONTENT]: SomMetaKind.CONTENT,
  [SpecFieldKind.ENUM]: SomMetaKind.ENUM_VALUE,
  [SpecFieldKind.COMPLEX]: SomMetaKind.COMPLEX,
  [SpecFieldKind.SCALAR]: SomMetaKind.SCALAR,
};

/**
 * Builds the wired {@link SomMetaTree} for one document root of `model`.
 *
 * When `rootType` is omitted the model's first root is used; otherwise the
 * root is looked up via {@link SpecModel.rootByType} (throwing for an unknown
 * type). Children are ordered by `@SerializationOrder` (annotated members
 * first, then declaration order), which is the sibling emission order of the
 * hierarchical YAML format (DR1 §2.3).
 */
export function buildSomMetaTree(
  model: SpecModel,
  rootType: string | null = null,
): SomMetaTree {
  const root =
    rootType === null || rootType === undefined
      ? model.roots.length > 0
        ? model.roots[0]
        : model.rootByType('')
      : model.rootByType(rootType);
  const cls = model.classNamed(root.type);
  const rootNode = new SomMetaNode({
    className: root.type,
    sectionId:
      root.sectionId != null ? root.sectionId : cls !== null ? cls.sectionId : null,
    classSectionId: cls !== null ? cls.sectionId : null,
    kind: SomMetaKind.SECTION,
    typeName: root.type,
    headline: cls !== null ? cls.headline : null,
    docComment: root.doc != null ? root.doc : cls !== null ? cls.doc : null,
    classDocComment: cls !== null ? cls.doc : null,
    mapsTo: cls !== null ? cls.mapsTo : null,
    detailedIn: cls !== null ? cls.detailedIn : null,
    document: new SomDocMeta({
      name: root.title,
      description: root.description != null ? root.description : '',
      basedOn: _basedOn(cls),
    }),
    secondLevelIds: _secondLevelIds(cls !== null ? cls.annotations : []),
    extra: _extras(cls !== null ? cls.annotations : []),
    children: cls === null ? [] : _childNodes(model, cls, new Set([root.type])),
  });
  return new SomMetaTree(rootNode);
}

function _basedOn(cls: SpecClass | null): string[] {
  const ann = cls !== null ? cls.annotation('Document') : null;
  const raw = ann !== null ? ann.argument('basedOn') : null;
  if (Array.isArray(raw)) {
    return raw.map((e) => String(e));
  }
  return [];
}

function _childNodes(
  model: SpecModel,
  cls: SpecClass,
  stack: Set<string>,
): SomMetaNode[] {
  const fallback = 1 << 30;
  const indexed: Array<[number, SpecField]> = cls.fields.map((f, i) => [i, f]);
  indexed.sort((a, b) => {
    const oa = a[1].serializationOrder !== null ? a[1].serializationOrder : fallback;
    const ob = b[1].serializationOrder !== null ? b[1].serializationOrder : fallback;
    if (oa !== ob) {
      return oa - ob;
    }
    return a[0] - b[0];
  });
  return indexed.map(([, f]) => _fieldNode(model, cls, f, stack));
}

function _fieldNode(
  model: SpecModel,
  owner: SpecClass,
  field: SpecField,
  stack: Set<string>,
): SomMetaNode {
  const kind = _KIND_OF[field.kind];
  let target: SpecClass | null = null;
  let recursive = false;
  let children: SomMetaNode[] = [];
  let elementNode: SomMetaNode | null = null;

  if (field.kind === SpecFieldKind.COMPLEX || field.kind === SpecFieldKind.SECTION) {
    target = model.classNamed(field.type);
    if (target !== null) {
      if (stack.has(target.name)) {
        recursive = true;
      } else {
        stack.add(target.name);
        children = _childNodes(model, target, stack);
        stack.delete(target.name);
      }
    }
  } else if (field.kind === SpecFieldKind.LIST && field.elementIsComplex) {
    const element = model.classNamed(field.elementType);
    if (element !== null) {
      let elementChildren: SomMetaNode[] = [];
      let elementRecursive = false;
      if (stack.has(element.name)) {
        elementRecursive = true;
      } else {
        stack.add(element.name);
        elementChildren = _childNodes(model, element, stack);
        stack.delete(element.name);
      }
      elementNode = new SomMetaNode({
        className: element.name,
        classSectionId: element.sectionId,
        kind: SomMetaKind.COMPLEX,
        typeName: element.name,
        headline: element.headline,
        docComment: element.doc,
        classDocComment: element.doc,
        mapsTo: element.mapsTo,
        detailedIn: element.detailedIn,
        recursive: elementRecursive,
        children: elementChildren,
      });
    }
  }

  let contentType: SomContentTypeMeta | null = null;
  if (field.contentType !== null && field.contentType !== undefined) {
    const ctAnn = field.annotation('ContentType');
    contentType = new SomContentTypeMeta(
      field.contentType,
      String((ctAnn !== null ? ctAnn.argument('description') : null) || ''),
    );
  }

  const commentAnn = field.annotation('Comment');
  const commentText = String(
    (commentAnn !== null ? commentAnn.argument('text') : null) || '',
  );

  let form: SomFormMeta | null = null;
  if (field.kind === SpecFieldKind.FORM) {
    form = new SomFormMeta(
      field.formFields.map(
        (ff, i) =>
          new SomFormFieldMeta({
            name: ff.name,
            typeName: ff.type,
            description: ff.label,
            required: ff.required,
            hint: ff.hint,
            order: i,
          }),
      ),
    );
  }

  return new SomMetaNode({
    className: target !== null ? target.name : owner.name,
    memberName: field.name,
    sectionId: field.sectionId,
    classSectionId: target !== null ? target.sectionId : null,
    sectionIdPattern: field.sectionIdPattern,
    kind,
    typeName: field.type || field.elementType || field.enumType || 'String',
    serializationOrder: field.serializationOrder,
    min: field.min,
    unused: field.annotation('Unused') !== null,
    contentType,
    contentHelp: field.help,
    headline:
      field.headline != null
        ? field.headline
        : target !== null
          ? target.headline
          : null,
    comment: commentText !== '' ? commentText : null,
    docComment: field.doc || (target !== null ? target.doc : null),
    classDocComment: target !== null ? target.doc : null,
    form,
    mapsTo: target !== null ? target.mapsTo : null,
    detailedIn: target !== null ? target.detailedIn : null,
    secondLevelIds: _secondLevelIds(field.annotations),
    extra: _extras(field.annotations),
    recursive,
    children,
    elementNode,
  });
}

function _secondLevelIds(annotations: SpecAnnotation[]): SomSecondLevelId[] {
  return annotations
    .filter((a) => a.name === 'SecondLevelSectionId')
    .map(
      (a) =>
        new SomSecondLevelId(
          String(a.argument('documentClass') || ''),
          String(a.argument('id') || ''),
        ),
    );
}

function _extras(annotations: SpecAnnotation[]): SomMetaExtra[] {
  return annotations
    .filter((a) => !_SLOTTED_ANNOTATIONS.has(a.name))
    .map((a) => new SomMetaExtra(a.name, a.arguments));
}
