/// Bridge from the meta-JSON class graph ([SpecModel]) to the canonical
/// metadata tree ([SomMetaTree], DR1 §3.1).
///
/// The generated facades (DR8) will emit populated [SomMetaTree]s directly;
/// until then, every consumer that only has the exported spec-model meta-data
/// (the conformance harness, the clitool, the editor) builds its tree here.
/// The expansion follows the same walk [SpecReflection.resolve] performs —
/// crucially, a node's [SomMetaNode.sectionId] is the **field-level** id
/// exactly as exported (`field.sectionId`), so the tree's path grammar stays
/// byte-compatible with the paths a [SpecDocument] is keyed by. DR1 §2.2's
/// "field id, else target-class id" resolution for a section/complex node's
/// display *key* is carried alongside it in [SomMetaNode.classSectionId] (the
/// target class's own id) — a codec renders `sectionId ?? classSectionId`
/// without re-consulting the model, and neither id enters [SomMetaNode.segment].
///
/// Recursive class references become terminal re-entry nodes
/// ([SomMetaNode.recursive]), mirroring how the generated chains terminate.
library;

import 'spec_meta.dart';
import 'spec_model.dart';

/// Annotation names that have a dedicated [SomMetaNode] slot; everything else
/// is captured losslessly into [SomMetaNode.extra].
const Set<String> _slottedAnnotations = {
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
};

/// Builds the wired [SomMetaTree] for one document root of [model].
///
/// When [rootType] is omitted the model's first root is used; otherwise the
/// root is looked up via [SpecModel.rootByType] (throwing [ArgumentError] for
/// an unknown type). Children are ordered by `@SerializationOrder` (annotated
/// members first, then declaration order), which is the sibling emission order
/// of the hierarchical YAML format (DR1 §2.3).
SomMetaTree buildSomMetaTree(SpecModel model, {String? rootType}) {
  final root = rootType == null && model.roots.isNotEmpty
      ? model.roots.first
      : model.rootByType(rootType ?? '');
  final cls = model.classNamed(root.type);
  final rootNode = SomMetaNode(
    className: root.type,
    sectionId: root.sectionId ?? cls?.sectionId,
    classSectionId: cls?.sectionId,
    kind: SomMetaKind.section,
    typeName: root.type,
    headline: cls?.headline,
    docComment: root.doc ?? cls?.doc,
    classDocComment: cls?.doc,
    mapsTo: cls?.mapsTo,
    detailedIn: cls?.detailedIn,
    document: SomDocMeta(
      name: root.title,
      description: root.description ?? '',
      basedOn: _basedOn(cls),
    ),
    secondLevelIds: _secondLevelIds(cls?.annotations ?? const []),
    extra: _extras(cls?.annotations ?? const []),
    children: cls == null
        ? const []
        : _childNodes(model, cls, <String>{root.type}),
  );
  return SomMetaTree(rootNode);
}

List<String> _basedOn(SpecClass? cls) {
  final raw = cls?.annotation('Document')?.argument('basedOn');
  if (raw is List) return raw.map((e) => '$e').toList();
  return const [];
}

List<SomMetaNode> _childNodes(
    SpecModel model, SpecClass cls, Set<String> stack) {
  final indexed = cls.fields.asMap().entries.toList()
    ..sort((a, b) {
      const fallback = 1 << 30;
      final oa = a.value.serializationOrder ?? fallback;
      final ob = b.value.serializationOrder ?? fallback;
      return oa != ob ? oa.compareTo(ob) : a.key.compareTo(b.key);
    });
  return [
    for (final e in indexed) _fieldNode(model, cls, e.value, stack),
  ];
}

SomMetaNode _fieldNode(
    SpecModel model, SpecClass owner, SpecField field, Set<String> stack) {
  final kind = _kindOf(field.kind);
  SpecClass? target;
  var recursive = false;
  List<SomMetaNode> children = const [];
  SomMetaNode? elementNode;

  if (field.kind == SpecFieldKind.complex ||
      field.kind == SpecFieldKind.section) {
    final typeName = field.type;
    target = model.classNamed(typeName);
    if (target != null) {
      if (stack.contains(target.name)) {
        recursive = true;
      } else {
        stack.add(target.name);
        children = _childNodes(model, target, stack);
        stack.remove(target.name);
      }
    }
  } else if (field.kind == SpecFieldKind.list && field.elementIsComplex) {
    final element = model.classNamed(field.elementType);
    if (element != null) {
      List<SomMetaNode> elementChildren = const [];
      var elementRecursive = false;
      if (stack.contains(element.name)) {
        elementRecursive = true;
      } else {
        stack.add(element.name);
        elementChildren = _childNodes(model, element, stack);
        stack.remove(element.name);
      }
      elementNode = SomMetaNode(
        className: element.name,
        classSectionId: element.sectionId,
        kind: SomMetaKind.complex,
        typeName: element.name,
        headline: element.headline,
        docComment: element.doc,
        classDocComment: element.doc,
        mapsTo: element.mapsTo,
        detailedIn: element.detailedIn,
        recursive: elementRecursive,
        children: elementChildren,
      );
    }
  }

  return SomMetaNode(
    className: target?.name ?? owner.name,
    memberName: field.name,
    sectionId: field.sectionId,
    classSectionId: target?.sectionId,
    sectionIdPattern: field.sectionIdPattern,
    kind: kind,
    typeName: field.type ?? field.elementType ?? field.enumType ?? 'String',
    serializationOrder: field.serializationOrder,
    min: field.min,
    unused: field.annotation('Unused') != null,
    contentType: field.contentType == null
        ? null
        : SomContentTypeMeta(
            type: field.contentType!,
            description:
                '${field.annotation('ContentType')?.argument('description') ?? ''}',
          ),
    contentHelp: field.help,
    headline: field.headline ?? target?.headline,
    comment: '${field.annotation('Comment')?.argument('text') ?? ''}'.isEmpty
        ? null
        : '${field.annotation('Comment')!.argument('text')}',
    docComment: field.doc ?? target?.doc,
    classDocComment: target?.doc,
    form: field.kind == SpecFieldKind.form
        ? SomFormMeta(fields: [
            for (var i = 0; i < field.formFields.length; i++)
              SomFormFieldMeta(
                name: field.formFields[i].name,
                typeName: field.formFields[i].type,
                description: field.formFields[i].label,
                required: field.formFields[i].required,
                hint: field.formFields[i].hint,
                order: i,
                enumValues: field.formFields[i].enumValues,
              ),
          ])
        : null,
    mapsTo: target?.mapsTo,
    detailedIn: target?.detailedIn,
    secondLevelIds: _secondLevelIds(field.annotations),
    extra: _extras(field.annotations),
    recursive: recursive,
    children: children,
    elementNode: elementNode,
  );
}

SomMetaKind _kindOf(SpecFieldKind kind) {
  switch (kind) {
    case SpecFieldKind.list:
      return SomMetaKind.list;
    case SpecFieldKind.form:
      return SomMetaKind.form;
    case SpecFieldKind.section:
      return SomMetaKind.section;
    case SpecFieldKind.content:
      return SomMetaKind.content;
    case SpecFieldKind.enumValue:
      return SomMetaKind.enumValue;
    case SpecFieldKind.complex:
      return SomMetaKind.complex;
    case SpecFieldKind.scalar:
      return SomMetaKind.scalar;
  }
}

List<SomSecondLevelId> _secondLevelIds(List<SpecAnnotation> annotations) => [
      for (final a in annotations)
        if (a.name == 'SecondLevelSectionId')
          SomSecondLevelId(
            documentClass: '${a.argument('documentClass') ?? ''}',
            id: '${a.argument('id') ?? ''}',
          ),
    ];

List<SomMetaExtra> _extras(List<SpecAnnotation> annotations) => [
      for (final a in annotations)
        if (!_slottedAnnotations.contains(a.name))
          SomMetaExtra(annotation: a.name, args: a.arguments),
    ];
