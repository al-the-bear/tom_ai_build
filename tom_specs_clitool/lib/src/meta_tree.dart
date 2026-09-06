/// The canonical language-neutral metadata tree (SOM §7.1).
///
/// [MetaTreeBuilder] projects the resolved [ModelClass] graph into one
/// fully-expanded [MetaNode] tree per document root, carrying *every*
/// `tom_specs_core` annotation: the ones SOM §7.1 defines dedicated slots for,
/// plus a lossless [MetaNode.extra] catch-all for the rest.
///
/// **Its one consumer in this package is the DocSpecs schema generator**
/// (SOM §13). The nine facade emitters do *not* read this tree — they build
/// from `SpecClass` / `SpecField`, the model decoded back out of the emitted
/// `meta/spec_model.meta.json`. Both routes originate in the same resolved
/// [ModelClass] graph, so they agree, but they are two projections of it and
/// not one: a slot added here reaches the schema, and reaches a facade only
/// once the meta-data emitters carry it too.
library;

import 'model_reader.dart';

/// Field/section render kind (SOM §7.1: list | form | section | content |
/// enum | complex | scalar). `enum` is a Dart keyword, hence [enumValue].
enum MetaNodeKind {
  /// A `List<T>` member: a repeating `-LST` container whose items are
  /// described once by [MetaNode.elementNode] rather than by one child per
  /// item. Tested before every other rule, so `List<TextSection>` is a list
  /// node, not a section node.
  list,

  /// A member — or a class — carrying `@Form([Field(...)])`: its value is a
  /// fixed set of named scalar slots serialized as `FieldName: value` lines
  /// instead of free prose (`tom_specs_model_rules.md` §9.2). The slots are
  /// in [MetaNode.form]; no slot ever holds the section title or id, which
  /// are stored by the heading and the id comment alone (SOM §7.1).
  form,

  /// A member whose declared type is one of the known typed section classes
  /// (`TextSection`, `ErDiagramSection`, `DartCodeSection`, …).
  /// Structurally a content leaf, but the class fixes the medium, so
  /// [MetaNode.contentType] is filled in from the class rather than from an
  /// explicit `@ContentType`.
  section,

  /// A free-prose content leaf: a plain `String` member, or a
  /// `DocSpecsSection` member (YRD5). The two classify identically — the
  /// runtime representation of a simple section *is* its String content — so
  /// the exported tree is unchanged by the YRD5 refactor.
  content,

  /// An enum-typed member. Its legal values are listed in
  /// [MetaNode.enumValues], resolved at read time so that no consumer needs
  /// the analyzer to validate a value. Exported under the SOM §7.1 label
  /// `enum` by [MetaNode.kindLabel]; `enum` is a Dart keyword, hence the
  /// constant name used here.
  enumValue,

  /// A member whose type is another model class, expanded in place into that
  /// class's own subtree. Also the kind of a class node that carries no
  /// class-level `@Form`, and of the reference node that breaks a cycle
  /// ([MetaNode.recursive] set, [MetaNode.children] empty).
  complex,

  /// A non-prose primitive leaf (`int`, `double`, `bool`, `num`,
  /// `DateTime`). Also the terminal fallback for a member whose type the
  /// reader could not resolve to a model class, so an unknown type degrades
  /// to a leaf instead of aborting the tree build.
  scalar,
}

/// `@ContentType(type, description)` — or the implied content type of a
/// known section type (`TextSection` → `text`, …) with an empty description.
class MetaContentType {
  /// The content medium token (`text`, `markdown`, `mermaid-er`,
  /// `code-dart`, …) that tells a renderer, an editor and the schema
  /// generator how the section body is to be interpreted
  /// (`tom_specs_model_rules.md` §9.2). Falls back to `text` when the
  /// annotation argument could not be constant-folded, so the value is
  /// always a usable medium rather than an empty string.
  final String type;

  /// The prose half of `@ContentType(type, description)`, explaining what
  /// belongs in the section. Empty — never null — when the content type was
  /// implied by a section class rather than annotated;
  /// [MetaNode.toJson] omits the key in that case.
  final String description;

  /// [type] is positional and required because a content type without a
  /// medium says nothing; [description] is optional so that the content
  /// types implied by a section class (which carry no prose) can be built
  /// with a single argument.
  const MetaContentType(this.type, [this.description = '']);
}

/// One `Field(...)` entry of a `@Form([...])` annotation.
class MetaFormField {
  /// The slot name declared as `Field('name', ...)`. It is written verbatim
  /// as the `Name: value` key of the serialized form section, and it is what
  /// a `refersTo` target of the form `<SECTIONID>.<slot>` resolves against
  /// (`tom_specs_model_rules.md` §6.2 rule 1).
  final String name;

  /// Dart type name of the slot's value (`String`, `int`, a model enum
  /// name), taken from the `Field` type literal; `String` when the literal
  /// was absent or unresolvable. When it names a model enum, [enumValues]
  /// carries the constants so a non-Dart runtime can validate the value
  /// without an analyzer.
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

  /// The registry key(s) this field's value is an id drawn from, each written
  /// `<SECTIONID>.<formFieldName>` (csrb3). Empty for a non-reference field.
  /// Carried into every language's meta so the eight non-Dart runtimes can run
  /// the instance-tier dangling-reference check too.
  final List<String> refersTo;

  /// [name], [typeName] and [order] are required: a slot is not addressable
  /// without a name and a type, and [order] is the authored position, which
  /// the caller knows and this class cannot recompute. Everything else
  /// defaults to the *declared-absent* value — nullable text slots to null,
  /// [required] to false, the lists to `const []` — so an omitted `Field`
  /// argument and an explicitly empty one behave identically.
  const MetaFormField({
    required this.name,
    required this.typeName,
    this.description,
    this.required = false,
    this.hint,
    required this.order,
    this.enumValues = const [],
    this.refersTo = const [],
  });
}

/// `@Form([...])` metadata for a `kind == form` node.
class MetaFormInfo {
  /// The form's slots in authored `@Form([...])` order.
  /// [MetaFormField.order] restates each position, so a consumer that
  /// re-sorts or re-keys the list can still recover the declared order. An
  /// empty list never reaches here — a node with no form fields gets a null
  /// [MetaNode.form] instead.
  final List<MetaFormField> fields;

  /// Single positional argument: the slot list is the entirety of a form's
  /// metadata, since the section title and id are deliberately not form
  /// fields (SOM §7.1).
  const MetaFormInfo(this.fields);
}

/// `@Document(name, description, basedOn)` — present on document root nodes.
class MetaDocumentInfo {
  /// The document's human title from `@Document(name:)`. Its kebab-case
  /// form is also the generated schema's id, so changing it renames a
  /// published artefact (`tom_specs_model_rules.md` §9.2).
  final String name;

  /// The document's one-line purpose from `@Document(description:)`. Empty
  /// rather than null when the annotation omitted it, because the exported
  /// document block always emits the key.
  final String description;

  /// Class names of the upstream documents this one is based on.
  final List<String> basedOn;

  /// [name] and [description] are required because the annotation always
  /// supplies both (missing arguments are degraded to `''` by the collector
  /// rather than dropped), while [basedOn] defaults to empty — most
  /// documents derive from nothing, and an empty list and an absent
  /// `basedOn:` mean the same thing.
  const MetaDocumentInfo({
    required this.name,
    required this.description,
    this.basedOn = const [],
  });
}

/// A captured annotation without a dedicated slot (SOM §7.1: `extra`), kept
/// losslessly as its name plus the analyzer-resolved constant arguments.
class MetaExtraAnnotation {
  /// The annotation's class name without the leading `@` (`Prefix`,
  /// `MaxLength`, `ValidationPrompt`, …) — anything not listed in
  /// [MetaTreeBuilder.slottedAnnotationNames]. Consumers dispatch on this
  /// string, so adding a dedicated slot for an annotation later removes it
  /// from here and is a breaking change for whoever matched on it.
  final String name;

  /// The annotation's constant-folded arguments, keyed by the annotation
  /// class's own field names rather than by call-site parameter names, so a
  /// positional argument still arrives under the field it initialises. An
  /// argument that is null or does not fold is absent from the map.
  final Map<String, Object?> arguments;

  /// [arguments] is optional so that marker annotations (`@Unused()`,
  /// `@CodeSpecsProjection()`) can be captured without constructing an empty
  /// map at every call site.
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

  /// How this node renders and serializes (SOM §7.1). Decided by
  /// [MetaTreeBuilder.classifyField] for member nodes, and by the presence
  /// of a class-level `@Form` for class nodes. It also decides which of the
  /// optional slots are meaningful: [form], [elementNode], [enumValues] and
  /// [contentType] are each populated for one kind only.
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

  /// The medium of this node's body: the explicit `@ContentType` when the
  /// member or class carries one, otherwise the marker implied by a known
  /// section class (`TextSection` → `text`). Null on nodes that hold no
  /// prose at all, which is how a consumer distinguishes a structural node
  /// from an unannotated content node defaulting to text.
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

  /// Only [className], [kind] and [typeName] are required — every node has
  /// a backing type name and a render kind, while every other slot is an
  /// annotation that most nodes do not carry. [memberName] is left null for
  /// the two node shapes that are not reached through a field: the document
  /// root and a list element node.
  ///
  /// The absent-value defaults are the *empty* value rather than null
  /// ([enumValues], [extra] and [children] to `const []`, [unused] and
  /// [recursive] to false), so "annotation absent" and "annotation present
  /// but empty" behave identically downstream — [toJson] omits both.
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
                      if (f.refersTo.isNotEmpty) 'refersTo': f.refersTo,
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
  /// The resolved class graph, keyed by exact class name. Complex members
  /// and complex list element types are expanded by looking their base type
  /// name up here; a name that is missing is not an error — the member
  /// degrades to a leaf node — so a partially resolvable model still yields
  /// a tree instead of throwing mid-walk.
  final Map<String, ModelClass> classes;

  /// The model's enums, keyed by type name. Consulted only for *list
  /// element* types (`List<SomeEnum>`), where there is no [ModelField] to
  /// read the constants from; the element node's kind and
  /// [MetaNode.enumValues] come from here. Left empty, such elements fall
  /// back to [MetaNodeKind.scalar] with no values.
  final Map<String, ModelEnum> enums;

  /// [classes] is positional and required because the class graph is the
  /// whole input — nothing can be expanded without it. [enums] is named and
  /// optional because only enum-element lists consult it, so a model without
  /// one can omit it entirely.
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
  /// target, or list element). `fieldAnnotations` / [field] carry the
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
  /// Annotations on the member through which the node is reached. Searched
  /// first, which is what makes a field-level `@SectionId` or `@Headline`
  /// win over the target class's. Empty for the document root and for list
  /// element nodes, neither of which is reached through a member.
  final List<AnnotationData> fieldAnnotations;

  /// Annotations on the class the node stands for, used as the fallback
  /// level. Empty for leaf member nodes, whose slots may legitimately come
  /// only from the member itself.
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

  /// The effective `@SectionId(id)` — the stable, human-readable id the
  /// `*.md` heading comment and the yaml key are written from
  /// (`tom_specs_model_rules.md` §7.1). Null when neither level carries the
  /// annotation, and also null rather than throwing when the `id` argument
  /// failed to constant-fold.
  String? get sectionId => _first('SectionId')?.arguments['id'] as String?;

  /// `@SectionIdPattern(pattern)` — the per-item numbering template of a
  /// `List<T>` member, mirroring the container's `-LST` id
  /// (`tom_specs_model_rules.md` §7.2). Independent of [sectionId]: a list
  /// routinely carries both, so this is never a fallback for a missing id.
  String? get sectionIdPattern =>
      _first('SectionIdPattern')?.arguments['pattern'] as String?;

  /// `@SerializationOrder(order)` — the member's sibling emission position
  /// in every observable surface (`*.md`, yaml, schema, all nine facades).
  /// It is stamped in bulk by `bin/stamp_serialization_order.dart`, not
  /// hand-written; null on an unstamped model, where declaration order is
  /// the fallback.
  int? get serializationOrder =>
      _first('SerializationOrder')?.arguments['order'] as int?;

  /// `@Min(count)` — the minimum number of items a `List<T>` member must
  /// hold, forwarded to the generated schema as `min-count`
  /// (`tom_specs_model_rules.md` §9.2). Null means *no declared bound*,
  /// which is not the same as a declared bound of zero.
  int? get min => _first('Min')?.arguments['count'] as int?;

  /// Whether `@Unused()` is present at either level: the section is a
  /// structural container, so no prose is *expected* in it
  /// (`tom_specs_model_rules.md` §5.6). Advisory only — the section, its
  /// content slot and its ability to hold content are untouched; only
  /// authoring and review tooling reacts to it.
  bool get unused => _present('Unused');

  /// `@ContentType(type, description)` as a [MetaContentType], or null when
  /// unannotated — in which case a `section` member still picks up the
  /// medium implied by its section class. Both arguments are defaulted here
  /// rather than propagated as null (`text` and `''`), so consumers never
  /// have to null-check inside the pair.
  MetaContentType? get contentType {
    final a = _first('ContentType');
    if (a == null) return null;
    return MetaContentType(
      (a.arguments['type'] as String?) ?? 'text',
      (a.arguments['description'] as String?) ?? '',
    );
  }

  /// `@ContentHelp(guidance)` — authoring guidance for whoever fills the
  /// section in. The schema generator emits it as the node's `description`
  /// (`tom_specs_model_rules.md` §9.2), so it reaches authors through the
  /// schema even when the outline is not rendered.
  String? get contentHelp =>
      _first('ContentHelp')?.arguments['guidance'] as String?;

  /// `@Headline(text)` — a *default* headline only
  /// (`tom_specs_model_rules.md` §8): a headline stored in the document
  /// always wins over it, and where neither exists the headline is derived
  /// from the member or class name. A field-level annotation beats the
  /// target class's.
  String? get headline => _first('Headline')?.arguments['text'] as String?;

  /// `@Comment(text)` — an inline note for humans, surfaced by the outliner
  /// and used for `Seeds → XX` provenance (`tom_specs_model_rules.md`
  /// §9.2). It is metadata about the section, never part of its content.
  String? get comment => _first('Comment')?.arguments['text'] as String?;

  /// `@MapsTo(Type)` target class name — the reader has already reduced the
  /// `Type` literal to its class name. Marks the node as the seed of a
  /// Phase 3 DocSpec: its whole subtree flows into that document
  /// (`tom_specs_model_rules.md` §9.2).
  String? get mapsTo =>
      _first('MapsTo')?.arguments['documentClass'] as String?;

  /// `@DetailedIn(Type)` target class name — promotes the node to a
  /// top-level entry of that Phase 3 DocSpec. The structural validator
  /// requires such a node to have a `@MapsTo` ancestor
  /// (`tom_specs_model_rules.md` §10.2), so this slot is never meaningful
  /// on its own.
  String? get detailedIn =>
      _first('DetailedIn')?.arguments['documentClass'] as String?;

  /// `@Document(name, description, basedOn)` projected into a
  /// [MetaDocumentInfo]; null on every node that is not a document root, so
  /// this doubles as the root test. Unresolvable arguments degrade — `name`
  /// and `description` to `''`, a non-`List` `basedOn` to `const []` —
  /// rather than failing the build on a malformed annotation.
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
        refersTo: f.refersTo,
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
