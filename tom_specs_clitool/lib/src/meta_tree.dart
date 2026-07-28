/// The canonical language-neutral metadata tree (SOM §7.1).
///
/// [MetaTreeBuilder] projects the resolved [ModelClass] graph into one
/// fully-expanded [MetaNode] tree per document root. This tree is the single
/// source that the nine facade emitters and the schema generator (SOM §13) consume —
/// no emitter re-reads the Dart model. It carries *every* `tom_specs_core`
/// annotation: the ones this spec defines dedicated slots for, plus a lossless
/// [MetaNode.extra] catch-all for the rest.
library;

import 'model_reader.dart';

/// Field/section render kind (SOM §7.1: list | form | section | content |
/// enum | complex | scalar). `enum` is a Dart keyword, hence [enumValue].
enum MetaNodeKind { list, form, section, content, enumValue, complex, scalar }

/// `@ContentType(type, description)` — or the implied content type of a
/// known section type (`TextSection` → `text`, …) with an empty description.
class MetaContentType {
  final String type;
  final String description;

  const MetaContentType(this.type, [this.description = '']);
}

/// One `Field(...)` entry of a `@Form([...])` annotation.
class MetaFormField {
  final String name;
  final String typeName;

  /// Human-readable display label of the field; null when absent.
  final String? description;

  /// Whether the field is required (`Field.required`).
  final bool required;

  /// Optional hint text guiding valid values/formats; null when absent.
  final String? hint;

  /// The field's 0-based position within the `@Form` field list.
  final int order;

  /// Enum constant names when [typeName] is a model enum (YRD7); empty for
  /// non-enum field types.
  final List<String> enumValues;

  const MetaFormField({
    required this.name,
    required this.typeName,
    this.description,
    this.required = false,
    this.hint,
    required this.order,
    this.enumValues = const [],
  });
}

/// `@Form([...])` metadata for a `kind == form` node.
class MetaFormInfo {
  final List<MetaFormField> fields;

  const MetaFormInfo(this.fields);
}

/// `@Document(name, description, basedOn)` — present on document root nodes.
class MetaDocumentInfo {
  final String name;
  final String description;

  /// Class names of the upstream documents this one is based on.
  final List<String> basedOn;

  const MetaDocumentInfo({
    required this.name,
    required this.description,
    this.basedOn = const [],
  });
}

/// A captured annotation without a dedicated slot (SOM §7.1: `extra`), kept
/// losslessly as its name plus the analyzer-resolved constant arguments.
class MetaExtraAnnotation {
  final String name;
  final Map<String, Object?> arguments;

  const MetaExtraAnnotation(this.name, [this.arguments = const {}]);
}

/// One node of the canonical metadata tree (SOM §7.1).
///
/// Class-level annotations attach to the node where the class is
/// instantiated; field-level annotations attach to the node directly and win
/// on overlap (notably `@SectionId`).
class MetaNode {
  /// Exact model class name backing this node (`IntroductionAndScope`), or
  /// the scalar/section type name for leaves (`String`, `TextSection`).
  final String className;

  /// Exact field name in the parent class; null on the document root and on
  /// list element nodes.
  final String? memberName;

  /// Effective `@SectionId` (field-level wins over class-level).
  final String? sectionId;

  /// `@SectionIdPattern` on the field (list element ids).
  final String? sectionIdPattern;

  final MetaNodeKind kind;

  /// Dart type name of the field/class (`String`, `GoalEntry`,
  /// `List<GoalEntry>`, …). Nullability suffixes are preserved as declared.
  final String typeName;

  /// `@SerializationOrder(order)`.
  final int? serializationOrder;

  /// `@Min(count)`.
  final int? min;

  /// Whether `@Unused` is present (field- or class-level).
  final bool unused;

  final MetaContentType? contentType;

  /// `@ContentHelp(guidance)`.
  final String? contentHelp;

  /// `@Headline(text)` — the predefined DEFAULT headline (YRD4). Field-level
  /// wins over the target class's class-level one. Render precedence is
  /// `stored headline > this default > name derivation`.
  final String? headline;

  /// `@Comment(text)`.
  final String? comment;

  /// Cleaned `///` doc comment; the member's wins over the class's.
  final String? docComment;

  /// The class doc comment, carried additionally when it exists and differs
  /// from [docComment] (SOM §7.1 note).
  final String? classDocComment;

  /// Present for `kind == form`.
  final MetaFormInfo? form;

  /// Present on document root nodes only.
  final MetaDocumentInfo? document;

  /// `@MapsTo` target class name.
  final String? mapsTo;

  /// `@DetailedIn` target class name.
  final String? detailedIn;

  /// Enum constant names for `kind == enumValue`.
  final List<String> enumValues;

  /// Annotations without a dedicated slot, kept losslessly.
  final List<MetaExtraAnnotation> extra;

  /// True when this class already appeared on the descent stack: the node is
  /// a reference (`kind == complex`, no [children]) breaking the cycle.
  final bool recursive;

  /// Child nodes in `@SerializationOrder` order (declaration order fallback).
  final List<MetaNode> children;

  /// For `kind == list`: the element class subtree.
  final MetaNode? elementNode;

  const MetaNode({
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
    this.headline,
    this.comment,
    this.docComment,
    this.classDocComment,
    this.form,
    this.document,
    this.mapsTo,
    this.detailedIn,
    this.enumValues = const [],
    this.extra = const [],
    this.recursive = false,
    this.children = const [],
    this.elementNode,
  });

  /// Depth-first pre-order walk over this node, its [children], and (for
  /// lists) the [elementNode] subtree.
  Iterable<MetaNode> walk() sync* {
    yield this;
    for (final child in children) {
      yield* child.walk();
    }
    if (elementNode != null) {
      yield* elementNode!.walk();
    }
  }

  /// Deterministic JSON-ready projection (stable key order, sparse: absent
  /// slots are omitted). Useful for tooling and golden tests; the facades
  /// embed the tree as generated code, not via this JSON (SOM §7.2).
  Map<String, Object?> toJson() => {
        'className': className,
        if (memberName != null) 'memberName': memberName,
        if (sectionId != null) 'sectionId': sectionId,
        if (sectionIdPattern != null) 'sectionIdPattern': sectionIdPattern,
        'kind': kindLabel,
        'typeName': typeName,
        if (serializationOrder != null)
          'serializationOrder': serializationOrder,
        if (min != null) 'min': min,
        if (unused) 'unused': true,
        if (contentType != null)
          'contentType': {
            'type': contentType!.type,
            if (contentType!.description.isNotEmpty)
              'description': contentType!.description,
          },
        if (contentHelp != null) 'contentHelp': contentHelp,
        if (headline != null) 'headline': headline,
        if (comment != null) 'comment': comment,
        if (docComment != null) 'docComment': docComment,
        if (classDocComment != null) 'classDocComment': classDocComment,
        if (form != null)
          'form': {
            'fields': form!.fields
                .map((f) => {
                      'name': f.name,
                      'typeName': f.typeName,
                      if (f.description != null) 'description': f.description,
                      if (f.required) 'required': true,
                      if (f.hint != null) 'hint': f.hint,
                      'order': f.order,
                      if (f.enumValues.isNotEmpty) 'enumValues': f.enumValues,
                    })
                .toList(),
          },
        if (document != null)
          'document': {
            'name': document!.name,
            'description': document!.description,
            if (document!.basedOn.isNotEmpty) 'basedOn': document!.basedOn,
          },
        if (mapsTo != null) 'mapsTo': mapsTo,
        if (detailedIn != null) 'detailedIn': detailedIn,
        if (enumValues.isNotEmpty) 'enumValues': enumValues,
        if (extra.isNotEmpty)
          'extra': extra
              .map((e) => {
                    'annotation': e.name,
                    if (e.arguments.isNotEmpty) 'args': e.arguments,
                  })
              .toList(),
        if (recursive) 'recursive': true,
        if (children.isNotEmpty)
          'children': children.map((c) => c.toJson()).toList(),
        if (elementNode != null) 'elementNode': elementNode!.toJson(),
      };

  /// The SOM §7.1 kind label (`enum`, not `enumValue`).
  String get kindLabel =>
      kind == MetaNodeKind.enumValue ? 'enum' : kind.name;
}

/// Builds [MetaNode] trees from the resolved [ModelClass] graph.
class MetaTreeBuilder {
  final Map<String, ModelClass> classes;
  final Map<String, ModelEnum> enums;

  MetaTreeBuilder(this.classes, {this.enums = const {}});

  /// Annotation names that have dedicated [MetaNode] slots; everything else
  /// is captured into [MetaNode.extra].
  static const slottedAnnotationNames = {
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
  };

  /// Builds the tree for every `@Document`-annotated root class, keyed by
  /// root class name.
  Map<String, MetaNode> buildAllDocumentRoots() {
    final result = <String, MetaNode>{};
    final names = classes.keys.toList()..sort();
    for (final name in names) {
      if (classes[name]!.getAnnotation('Document') != null) {
        result[name] = build(name);
      }
    }
    return result;
  }

  /// Builds the fully-expanded tree rooted at [rootClassName].
  MetaNode build(String rootClassName) {
    final cls = classes[rootClassName];
    if (cls == null) {
      throw ArgumentError('Unknown model class: $rootClassName');
    }
    return _classNode(cls, memberName: null, stack: <String>{});
  }

  // -------------------------------------------------------------------------
  // Node construction
  // -------------------------------------------------------------------------

  /// A node standing for an instance of [cls] (document root, complex field
  /// target, or list element). [fieldAnnotations] / [field] carry the
  /// instantiating field's metadata when there is one.
  MetaNode _classNode(
    ModelClass cls, {
    required String? memberName,
    required Set<String> stack,
    ModelField? field,
  }) {
    final recursive = stack.contains(cls.name);
    final slots = _SlotCollector(
      fieldAnnotations: field?.annotations ?? const [],
      classAnnotations: cls.annotations,
    );

    List<MetaNode> children = const [];
    if (!recursive) {
      final nextStack = {...stack, cls.name};
      children = _orderedFields(cls)
          .map((f) => _fieldNode(f, stack: nextStack))
          .toList();
    }

    final fieldDoc = field?.docComment ?? '';
    final docComment = fieldDoc.isNotEmpty ? fieldDoc : cls.docComment;

    // Form section classes carry a class-level `@Form`; the field-level
    // variant (on `String?` members) is handled by [_fieldNode].
    final form = slots.form(
      (field?.formFields.isNotEmpty ?? false)
          ? field!.formFields
          : cls.formFields,
    );

    return MetaNode(
      className: cls.name,
      memberName: memberName,
      sectionId: slots.sectionId,
      sectionIdPattern: slots.sectionIdPattern,
      kind: form != null ? MetaNodeKind.form : MetaNodeKind.complex,
      typeName: field?.typeName ?? cls.name,
      serializationOrder: slots.serializationOrder,
      min: slots.min,
      unused: slots.unused,
      contentType: slots.contentType,
      contentHelp: slots.contentHelp,
      headline: slots.headline,
      comment: slots.comment,
      docComment: docComment.isEmpty ? null : docComment,
      classDocComment:
          cls.docComment.isNotEmpty && cls.docComment != docComment
              ? cls.docComment
              : null,
      form: form,
      document: slots.document,
      mapsTo: slots.mapsTo,
      detailedIn: slots.detailedIn,
      extra: slots.extra,
      recursive: recursive,
      children: children,
    );
  }

  /// A node standing for [field] of its declaring class.
  MetaNode _fieldNode(ModelField field, {required Set<String> stack}) {
    final kind = classifyField(field);

    // Complex fields expand into the target class's node.
    if (kind == MetaNodeKind.complex) {
      final target = classes[_baseTypeName(field.typeName)];
      if (target != null) {
        return _classNode(
          target,
          memberName: field.name,
          stack: stack,
          field: field,
        );
      }
      // Unresolvable complex type — leaf reference node.
    }

    final slots = _SlotCollector(
      fieldAnnotations: field.annotations,
      classAnnotations: const [],
    );

    MetaNode? elementNode;
    if (kind == MetaNodeKind.list) {
      elementNode = _listElementNode(field, stack: stack);
    }

    return MetaNode(
      // metaTypeName keeps `DocSpecsSection` members byte-identical to the
      // former `String` members in the exported tree (YRD5).
      className: _baseTypeName(field.isList
          ? (field.metaListElementTypeName ?? 'Object')
          : field.metaTypeName),
      memberName: field.name,
      sectionId: slots.sectionId,
      sectionIdPattern: slots.sectionIdPattern,
      kind: kind,
      typeName: field.metaTypeName,
      serializationOrder: slots.serializationOrder,
      min: slots.min,
      unused: slots.unused,
      contentType: slots.contentType ?? _sectionContentType(field, kind),
      contentHelp: slots.contentHelp,
      headline: slots.headline,
      comment: slots.comment,
      docComment: field.docComment.isEmpty ? null : field.docComment,
      form: slots.form(field.formFields),
      mapsTo: slots.mapsTo,
      detailedIn: slots.detailedIn,
      enumValues: kind == MetaNodeKind.enumValue ? field.enumValues : const [],
      extra: slots.extra,
      elementNode: elementNode,
    );
  }

  /// The element subtree of a list field: the element class expanded (with
  /// cycle detection), or a leaf node for non-class element types.
  MetaNode? _listElementNode(ModelField field, {required Set<String> stack}) {
    // metaListElementTypeName maps `List<DocSpecsSection>` elements to the
    // `String` content leaf they replaced (YRD5).
    final elementTypeName = field.metaListElementTypeName;
    if (elementTypeName == null) return null;
    final target = classes[elementTypeName];
    if (target != null) {
      return _classNode(target, memberName: null, stack: stack);
    }
    final enumType = enums[elementTypeName];
    return MetaNode(
      className: elementTypeName,
      kind: enumType != null
          ? MetaNodeKind.enumValue
          : (elementTypeName == 'String'
              ? MetaNodeKind.content
              : MetaNodeKind.scalar),
      typeName: elementTypeName,
      enumValues: enumType?.values ?? const [],
    );
  }

  MetaContentType? _sectionContentType(ModelField field, MetaNodeKind kind) {
    if (kind == MetaNodeKind.section && field.sectionContentType != null) {
      return MetaContentType(field.sectionContentType!);
    }
    return null;
  }

  /// Classifies a field into its SOM §7.1 kind. Mirrors the JSON exporter's
  /// render-kind rules (including the primitive guard before `isComplex`).
  static MetaNodeKind classifyField(ModelField f) {
    if (f.isList) return MetaNodeKind.list;
    if (f.formFields.isNotEmpty) return MetaNodeKind.form;
    if (f.isSectionType) return MetaNodeKind.section;
    if (f.isEnum) return MetaNodeKind.enumValue;
    // Content nodes: plain `String` members and `DocSpecsSection` members
    // (YRD5) — a DocSpecsSection member IS a simple content section, so it
    // lands exactly where the former String member landed. DocSpecsSection
    // *subclasses* stay on the expandable class path below: they are the
    // sections with subsections, which this tree has always represented via
    // [MetaNodeKind.complex] class expansion.
    if (f.isContentLike) return MetaNodeKind.content;
    if (_isPrimitive(f.typeName)) return MetaNodeKind.scalar;
    if (f.isComplex) return MetaNodeKind.complex;
    return MetaNodeKind.scalar;
  }

  static const _primitiveTypes = {
    'int',
    'double',
    'bool',
    'num',
    'DateTime',
    'String',
  };

  static bool _isPrimitive(String typeName) =>
      _primitiveTypes.contains(_baseTypeName(typeName));

  static String _baseTypeName(String typeName) => typeName.endsWith('?')
      ? typeName.substring(0, typeName.length - 1)
      : typeName;

  /// Fields in `@SerializationOrder` order; unstamped members keep their
  /// declaration position as a stable fallback.
  static List<ModelField> _orderedFields(ModelClass cls) {
    final indexed = cls.fields.asMap().entries.toList();
    indexed.sort((a, b) {
      final oa = a.value.serializationOrder ?? a.key;
      final ob = b.value.serializationOrder ?? b.key;
      if (oa != ob) return oa.compareTo(ob);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }
}

/// Merges field- and class-level annotations into the SOM §7.1 slots with
/// field-first precedence, routing everything unslotted into `extra`.
class _SlotCollector {
  final List<AnnotationData> fieldAnnotations;
  final List<AnnotationData> classAnnotations;

  _SlotCollector({
    required this.fieldAnnotations,
    required this.classAnnotations,
  });

  AnnotationData? _first(String name) {
    for (final a in fieldAnnotations) {
      if (a.name == name) return a;
    }
    for (final a in classAnnotations) {
      if (a.name == name) return a;
    }
    return null;
  }

  bool _present(String name) => _first(name) != null;

  String? get sectionId => _first('SectionId')?.arguments['id'] as String?;

  String? get sectionIdPattern =>
      _first('SectionIdPattern')?.arguments['pattern'] as String?;

  int? get serializationOrder =>
      _first('SerializationOrder')?.arguments['order'] as int?;

  int? get min => _first('Min')?.arguments['count'] as int?;

  bool get unused => _present('Unused');

  MetaContentType? get contentType {
    final a = _first('ContentType');
    if (a == null) return null;
    return MetaContentType(
      (a.arguments['type'] as String?) ?? 'text',
      (a.arguments['description'] as String?) ?? '',
    );
  }

  String? get contentHelp =>
      _first('ContentHelp')?.arguments['guidance'] as String?;

  String? get headline => _first('Headline')?.arguments['text'] as String?;

  String? get comment => _first('Comment')?.arguments['text'] as String?;

  String? get mapsTo =>
      _first('MapsTo')?.arguments['documentClass'] as String?;

  String? get detailedIn =>
      _first('DetailedIn')?.arguments['documentClass'] as String?;

  MetaDocumentInfo? get document {
    final a = _first('Document');
    if (a == null) return null;
    final basedOn = a.arguments['basedOn'];
    return MetaDocumentInfo(
      name: (a.arguments['name'] as String?) ?? '',
      description: (a.arguments['description'] as String?) ?? '',
      basedOn: basedOn is List
          ? basedOn.whereType<String>().toList()
          : const [],
    );
  }

  /// `@Form` field list from the reader's parsed form fields (field-level
  /// [ModelField.formFields] or class-level [ModelClass.formFields]).
  MetaFormInfo? form(List<FormFieldInfo> formFields) {
    if (formFields.isEmpty) return null;
    final fields = <MetaFormField>[];
    for (var i = 0; i < formFields.length; i++) {
      final f = formFields[i];
      fields.add(MetaFormField(
        name: f.name,
        typeName: f.typeName,
        description: f.description.isEmpty ? null : f.description,
        required: f.required,
        hint: f.hint.isEmpty ? null : f.hint,
        order: i,
        enumValues: f.enumValues,
      ));
    }
    return MetaFormInfo(fields);
  }

  /// Every annotation without a dedicated slot, field-level first, in source
  /// declaration order — the lossless completeness guarantee (SOM §7.1).
  List<MetaExtraAnnotation> get extra => [
        for (final a in [...fieldAnnotations, ...classAnnotations])
          if (!MetaTreeBuilder.slottedAnnotationNames.contains(a.name))
            MetaExtraAnnotation(a.name, a.arguments),
      ];
}
