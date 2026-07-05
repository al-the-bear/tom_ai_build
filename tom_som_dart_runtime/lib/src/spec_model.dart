/// In-memory representation of the exported TomSpecs class graph (the
/// spec-model meta-data file produced by `tom_specs_clitool/bin/model_json.dart`,
/// schema documented in `tom_specs_clitool/doc/spec_model_meta_schema.md`).
///
/// The model is a *class graph*, not an expanded tree: each class appears once
/// and field `elementType` / `type` references are followed on demand by a
/// traversal (which does its own cycle detection). This is the "reflection"
/// surface — it describes any document's structure, independent of the values a
/// concrete [SpecDocument] holds.
library;

/// The render kind of a field, mirroring the exporter's classification.
enum SpecFieldKind {
  list,
  form,
  section,
  content,
  enumValue,
  complex,
  scalar;

  static SpecFieldKind parse(String raw) {
    switch (raw) {
      case 'list':
        return SpecFieldKind.list;
      case 'form':
        return SpecFieldKind.form;
      case 'section':
        return SpecFieldKind.section;
      case 'content':
        return SpecFieldKind.content;
      case 'enum':
        return SpecFieldKind.enumValue;
      case 'complex':
        return SpecFieldKind.complex;
      default:
        return SpecFieldKind.scalar;
    }
  }
}

/// A single annotation captured losslessly from the model source (§3.1): its
/// name and the resolved argument map (`{ '<arg>': <value> }`). This is the
/// `annotations[]` block emitted by `ModelJsonExporter` — the superset the
/// curated convenience accessors ([SpecClass.sectionId], [SpecField.min], …)
/// are projected from.
class SpecAnnotation {
  final String name;
  final Map<String, Object?> arguments;

  const SpecAnnotation({required this.name, this.arguments = const {}});

  factory SpecAnnotation.fromJson(Map<String, dynamic> j) => SpecAnnotation(
        name: j['name'] as String,
        arguments: (j['arguments'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  /// The argument named [key], or `null` when absent.
  Object? argument(String key) => arguments[key];

  static List<SpecAnnotation> listFromJson(Object? raw) =>
      (raw as List?)
          ?.map((e) => SpecAnnotation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}

/// A single form field within a `@Form` content section.
class FormFieldSpec {
  final String name;
  final String label;
  final String? hint;
  final String type;
  final bool required;

  FormFieldSpec({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.required = false,
  });

  factory FormFieldSpec.fromJson(Map<String, dynamic> j) => FormFieldSpec(
        name: j['name'] as String,
        label: j['label'] as String? ?? j['name'] as String,
        hint: j['hint'] as String?,
        type: j['type'] as String? ?? 'String',
        required: j['required'] as bool? ?? false,
      );
}

/// A single field of a [SpecClass].
class SpecField {
  final String name;
  final SpecFieldKind kind;
  final String? doc;
  final String? help;
  final String? sectionId;
  final String? sectionIdPattern;

  /// The member's serialization ordinal from `@SerializationOrder(n)` (SOM
  /// source declaration order), or `null` when unannotated. Drives the YAML
  /// member emission order (AA1 criterion 7).
  final int? serializationOrder;

  // list
  final String? elementType;
  final bool elementIsComplex;
  final int? min;

  // section / content
  final String? contentType;
  final String? sectionType;

  // enum
  /// The Dart enum type name backing an `enum` field (e.g. `Probability`), or
  /// `null` for non-enum fields. Mirrors the exporter's `enumType` key.
  final String? enumType;
  final List<String> enumValues;

  // complex / scalar
  final String? type;

  // form
  final List<FormFieldSpec> formFields;

  /// The lossless annotation list captured on this field (§3.1).
  final List<SpecAnnotation> annotations;

  SpecField({
    required this.name,
    required this.kind,
    this.doc,
    this.help,
    this.sectionId,
    this.sectionIdPattern,
    this.serializationOrder,
    this.elementType,
    this.elementIsComplex = false,
    this.min,
    this.contentType,
    this.sectionType,
    this.enumType,
    this.enumValues = const [],
    this.type,
    this.formFields = const [],
    this.annotations = const [],
  });

  factory SpecField.fromJson(Map<String, dynamic> j) {
    return SpecField(
      name: j['name'] as String,
      kind: SpecFieldKind.parse(j['kind'] as String),
      doc: j['doc'] as String?,
      help: j['help'] as String?,
      sectionId: j['sectionId'] as String?,
      sectionIdPattern: j['sectionIdPattern'] as String?,
      serializationOrder: (j['serializationOrder'] as num?)?.toInt(),
      elementType: j['elementType'] as String?,
      elementIsComplex: j['elementIsComplex'] as bool? ?? false,
      min: j['min'] as int?,
      contentType: j['contentType'] as String?,
      sectionType: j['sectionType'] as String?,
      enumType: j['enumType'] as String?,
      enumValues:
          (j['enumValues'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      type: j['type'] as String?,
      formFields: (j['formFields'] as List?)
              ?.map((e) => FormFieldSpec.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      annotations: SpecAnnotation.listFromJson(j['annotations']),
    );
  }

  /// Whether expanding this field reveals further tree nodes.
  bool get isExpandable =>
      kind == SpecFieldKind.list || kind == SpecFieldKind.complex;

  /// The annotation named [name], or `null` when absent.
  SpecAnnotation? annotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// A model class with its fields.
class SpecClass {
  final String name;
  final String? sectionId;
  final String? doc;
  final String? help;
  final String? mapsTo;
  final String? detailedIn;
  final List<SpecField> fields;

  /// The lossless annotation list captured on this class (§3.1).
  final List<SpecAnnotation> annotations;

  SpecClass({
    required this.name,
    this.sectionId,
    this.doc,
    this.help,
    this.mapsTo,
    this.detailedIn,
    this.fields = const [],
    this.annotations = const [],
  });

  factory SpecClass.fromJson(Map<String, dynamic> j) => SpecClass(
        name: j['name'] as String,
        sectionId: j['sectionId'] as String?,
        doc: j['doc'] as String?,
        help: j['help'] as String?,
        mapsTo: j['mapsTo'] as String?,
        detailedIn: j['detailedIn'] as String?,
        fields: (j['fields'] as List)
            .map((e) => SpecField.fromJson(e as Map<String, dynamic>))
            .toList(),
        annotations: SpecAnnotation.listFromJson(j['annotations']),
      );

  /// The field named [name], or `null` when absent.
  SpecField? fieldNamed(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }

  /// The annotation named [name], or `null` when absent.
  SpecAnnotation? annotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// A document root (a class carrying `@Document`).
class SpecRoot {
  final String type;
  final String title;
  final String? sectionId;
  final String? description;
  final String? doc;

  SpecRoot({
    required this.type,
    required this.title,
    this.sectionId,
    this.description,
    this.doc,
  });

  factory SpecRoot.fromJson(Map<String, dynamic> j) => SpecRoot(
        type: j['type'] as String,
        title: j['title'] as String,
        sectionId: j['sectionId'] as String?,
        description: j['description'] as String?,
        doc: j['doc'] as String?,
      );
}

/// The complete exported model.
class SpecModel {
  final List<SpecRoot> roots;
  final Map<String, SpecClass> classes;

  /// The model-version counter the meta-data was generated against. `0` means
  /// the file was produced by a manual, unstamped export rather than an
  /// official build.
  final int modelVersion;

  /// A human-readable build label for the same stamp (e.g. `1.0.0+3.abc1234`),
  /// or `null` when the meta-data is unstamped.
  final String? modelVersionLabel;

  SpecModel({
    required this.roots,
    required this.classes,
    this.modelVersion = 0,
    this.modelVersionLabel,
  });

  SpecClass? classNamed(String? name) => name == null ? null : classes[name];

  factory SpecModel.fromJson(Map<String, dynamic> j) {
    final classes = <String, SpecClass>{};
    (j['classes'] as Map<String, dynamic>).forEach((name, value) {
      classes[name] = SpecClass.fromJson(value as Map<String, dynamic>);
    });
    final roots = (j['roots'] as List)
        .map((e) => SpecRoot.fromJson(e as Map<String, dynamic>))
        .toList();
    final label = j['modelVersionLabel'] as String?;
    return SpecModel(
      roots: roots,
      classes: classes,
      modelVersion: (j['modelVersion'] as num?)?.toInt() ?? 0,
      modelVersionLabel: (label?.isNotEmpty ?? false) ? label : null,
    );
  }
}
