/// In-memory representation of the exported TomSpecs class graph
/// (`assets/spec_model.json`, produced by `tom_specs_clitool/bin/model_json.dart`).
///
/// The model is a *class graph*, not an expanded tree: each class appears once
/// and field `elementType` / `type` references are followed on demand by the
/// tree UI (which does its own cycle detection).
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

/// A single field of a [SpecClass].
class SpecField {
  final String name;
  final SpecFieldKind kind;
  final String? doc;
  final String? help;
  final String? sectionId;
  final String? sectionIdPattern;

  // list
  final String? elementType;
  final bool elementIsComplex;
  final int? min;

  // section / content
  final String? contentType;
  final String? sectionType;

  // enum
  final List<String> enumValues;

  // complex / scalar
  final String? type;

  // form
  final List<FormFieldSpec> formFields;

  SpecField({
    required this.name,
    required this.kind,
    this.doc,
    this.help,
    this.sectionId,
    this.sectionIdPattern,
    this.elementType,
    this.elementIsComplex = false,
    this.min,
    this.contentType,
    this.sectionType,
    this.enumValues = const [],
    this.type,
    this.formFields = const [],
  });

  factory SpecField.fromJson(Map<String, dynamic> j) {
    return SpecField(
      name: j['name'] as String,
      kind: SpecFieldKind.parse(j['kind'] as String),
      doc: j['doc'] as String?,
      help: j['help'] as String?,
      sectionId: j['sectionId'] as String?,
      sectionIdPattern: j['sectionIdPattern'] as String?,
      elementType: j['elementType'] as String?,
      elementIsComplex: j['elementIsComplex'] as bool? ?? false,
      min: j['min'] as int?,
      contentType: j['contentType'] as String?,
      sectionType: j['sectionType'] as String?,
      enumValues:
          (j['enumValues'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      type: j['type'] as String?,
      formFields: (j['formFields'] as List?)
              ?.map((e) => FormFieldSpec.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Whether expanding this field reveals further tree nodes.
  bool get isExpandable =>
      kind == SpecFieldKind.list || kind == SpecFieldKind.complex;
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

/// A model class with its fields.
class SpecClass {
  final String name;
  final String? sectionId;
  final String? doc;
  final String? help;
  final String? mapsTo;
  final String? detailedIn;
  final List<SpecField> fields;

  SpecClass({
    required this.name,
    this.sectionId,
    this.doc,
    this.help,
    this.mapsTo,
    this.detailedIn,
    this.fields = const [],
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
      );
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

  SpecModel({required this.roots, required this.classes});

  SpecClass? classNamed(String? name) => name == null ? null : classes[name];

  factory SpecModel.fromJson(Map<String, dynamic> j) {
    final classes = <String, SpecClass>{};
    (j['classes'] as Map<String, dynamic>).forEach((name, value) {
      classes[name] = SpecClass.fromJson(value as Map<String, dynamic>);
    });
    final roots = (j['roots'] as List)
        .map((e) => SpecRoot.fromJson(e as Map<String, dynamic>))
        .toList();
    return SpecModel(roots: roots, classes: classes);
  }
}
