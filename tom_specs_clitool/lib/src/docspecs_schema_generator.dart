import 'package:json2yaml/json2yaml.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

import 'model_reader.dart';

/// Generates DocSpecs schemas (`*.docspecs-schema.yaml`) from the TomSpecs
/// object-model annotations (§16, Q8).
///
/// One [DocSpecSchema] is produced per `@Document` root: the global Project
/// Definition schema plus the twelve Phase-3 projection roots — 13 in all (S1).
/// The mapping mirrors the §16 contract:
///
/// - class/field `@SectionId` and field `@SectionIdPattern` → `section-types`,
///   each with a sanitised `prefix` (the DocSpecs prefix grammar forbids the
///   `-` used in TomSpecs IDs, so dashes collapse to `_`);
/// - a non-list field caps `max-count-in-document: 1`; `@SectionIdPattern`
///   (list element) types stay uncapped;
/// - `@ContentType` for a *code/diagram* section → `format` (a plain `text`
///   section gets none — a `format` makes the validator demand a fenced code
///   block, which a prose section must not carry);
/// - `@Form` fields → `form-types`, and the owning section's `format`
///   becomes `<prefix>-form`;
/// - content/section text fields → `text-required: true`;
/// - `@ContentHelp` guidance (or the first doc-comment line) → `description`.
///
/// Document slots (the root's direct fields) are emitted **optional** so any
/// projection may legitimately carry a subset of the Project Definition: the PD
/// tree is the single source of content (N12), projections only re-point into
/// it. This also keeps a generated skeleton trivially valid.
///
/// Versioning (S2): [generateAll]/[generateFor] take the integer model stamp
/// `modelVersion`; the emitted schema `version` is `"<modelVersion>.0"` so it
/// both *counts up* with the model and stays parseable by the DocSpecs
/// filename grammar (`<id>.<major>.<minor>.docspecs-schema.yaml`).
class DocSpecsSchemaGenerator {
  /// The full resolved class graph (as produced by [ModelReader]).
  final Map<String, ModelClass> classes;

  DocSpecsSchemaGenerator(this.classes);

  /// Builds every document-root schema, keyed by schema id.
  ///
  /// Throws [StateError] if two roots slugify to the same id (which would make
  /// the on-disk schema files collide).
  Map<String, DocSpecSchema> generateAll({int modelVersion = 1}) {
    final rootNames = classes.values
        .where((c) => c.getAnnotation('Document') != null)
        .map((c) => c.name)
        .toList()
      ..sort();

    final result = <String, DocSpecSchema>{};
    for (final rootName in rootNames) {
      final schema = generateFor(rootName, modelVersion: modelVersion);
      if (result.containsKey(schema.id)) {
        throw StateError(
          "Duplicate schema id '${schema.id}' from root '$rootName'.",
        );
      }
      result[schema.id] = schema;
    }
    return result;
  }

  /// Builds the schema for a single `@Document` root class.
  DocSpecSchema generateFor(String rootName, {int modelVersion = 1}) {
    final root = classes[rootName];
    if (root == null) {
      throw ArgumentError("Unknown root class '$rootName'.");
    }
    if (root.getAnnotation('Document') == null) {
      throw ArgumentError("Class '$rootName' is not a @Document root.");
    }

    final rootSectionId =
        root.getAnnotation('SectionId')?.arguments['id'] as String?;

    final builder = _SchemaBuilder(classes, rootSectionId);
    builder.visit(root);

    // Document structure: the root's direct fields become (optional) slots.
    final sections = <String, SectionDef>{};
    for (final f in root.fields) {
      final typeId = builder.sectionTypeIdForField(f);
      if (typeId == null) continue;
      sections[_slugDash(f.name)] = SectionDef(
        sectionType: typeId,
        optional: true,
      );
    }

    return DocSpecSchema(
      id: _schemaId(root),
      version: '$modelVersion.0',
      sectionTypes: builder.orderedSectionTypes(),
      formTypes: builder.formTypes.isEmpty ? null : builder.formTypes,
      document: DocumentStructure(sections: sections),
    );
  }

  /// Serialises a schema to YAML text for writing to `.tom/docspecs-schema/`.
  static String toYamlString(DocSpecSchema schema) {
    final header = '# Generated from the TomSpecs object model — do not edit.\n'
        '# Schema: ${schema.fullId}\n\n';
    return header + json2yaml(schema.toYaml());
  }

  /// The on-disk filename for a schema (e.g. `project-definition.1.0`).
  static String fileNameFor(DocSpecSchema schema) =>
      '${schema.id}.${schema.version}.docspecs-schema.yaml';

  /// Schema id slug derived from the `@Document` name (fallback: class name).
  static String _schemaId(ModelClass root) {
    final docName =
        root.getAnnotation('Document')?.arguments['name'] as String?;
    final base = (docName != null && docName.trim().isNotEmpty)
        ? docName
        : _splitPascal(root.name);
    return _slugDash(base);
  }

  static String _splitPascal(String name) => name
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}')
      .trim();

  static String _slugDash(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Walks the reachable class graph of one root, accumulating section-types and
/// form-types with unique, DocSpecs-legal prefixes.
class _SchemaBuilder {
  final Map<String, ModelClass> classes;
  final String? rootSectionId;

  /// section-type name (the TomSpecs section id) → definition.
  final Map<String, SectionTypeDef> _sectionTypes = {};

  /// form-type name → definition.
  final Map<String, FormTypeDef> formTypes = {};

  final Set<String> _usedPrefixes = {};
  final Set<String> _visited = {};

  _SchemaBuilder(this.classes, this.rootSectionId);

  void visit(ModelClass cls) {
    if (!_visited.add(cls.name)) return;

    final clsId = cls.getAnnotation('SectionId')?.arguments['id'] as String?;
    if (clsId != null && clsId != rootSectionId) {
      // Container section — no text requirement, no format.
      _putSectionType(
        clsId,
        description: _help(cls.getAnnotation('ContentHelp')) ??
            _firstLine(cls.docComment),
      );
    }

    for (final f in cls.fields) {
      _collectField(f);
      final target = _targetClassName(f);
      if (target != null) {
        final tc = classes[target];
        if (tc != null) visit(tc);
      }
    }
  }

  /// The section-type id this field represents, if any (for document slots).
  String? sectionTypeIdForField(ModelField f) {
    final own = (f.getAnnotation('SectionId')?.arguments['id'] as String?) ??
        (f.getAnnotation('SectionIdPattern')?.arguments['pattern'] as String?);
    if (own != null) return own;
    final target = _targetClassName(f);
    if (target != null) {
      return classes[target]?.getAnnotation('SectionId')?.arguments['id']
          as String?;
    }
    return null;
  }

  void _collectField(ModelField f) {
    final secId = f.getAnnotation('SectionId')?.arguments['id'] as String?;
    final pattern =
        f.getAnnotation('SectionIdPattern')?.arguments['pattern'] as String?;
    final typeId = secId ?? pattern;
    if (typeId == null) return;

    final description =
        _help(f.getAnnotation('ContentHelp')) ?? _firstLine(f.docComment);

    // Determine format + form-type registration.
    String? format;
    if (f.formFields.isNotEmpty) {
      final prefix = _prefixFor(typeId);
      final formName = '$prefix-form';
      formTypes[formName] = FormTypeDef(
        name: formName,
        fields: [
          for (final ff in f.formFields)
            FormFieldDef(
              fieldname: _slugDash(ff.name),
              required: ff.required ? true : null,
            ),
        ],
      );
      format = formName;
    } else {
      final contentType =
          (f.getAnnotation('ContentType')?.arguments['type'] as String?) ??
              f.sectionContentType;
      // A `format` makes the validator require a fenced code block, so only
      // attach it for genuine code/diagram sections — never for prose.
      if (contentType != null && contentType != 'text') {
        format = contentType;
      }
    }

    // Text is required for prose/section fields (no format), not for forms or
    // code blocks (those are governed by `format`).
    final textRequired =
        format == null && (f.isString || f.isSectionType) ? true : null;

    _putSectionType(
      typeId,
      description: description,
      format: format,
      textRequired: textRequired,
      // List-element (pattern) types are uncapped; single fields cap at 1.
      maxCountInDocument: pattern != null ? null : 1,
    );
  }

  /// Inserts or enriches a section-type keyed by its TomSpecs id.
  void _putSectionType(
    String id, {
    String? description,
    String? format,
    bool? textRequired,
    int? maxCountInDocument,
  }) {
    final existing = _sectionTypes[id];
    final prefix = existing?.prefix ?? _prefixFor(id);
    _sectionTypes[id] = SectionTypeDef(
      name: id,
      prefix: prefix,
      description: (description != null && description.isNotEmpty)
          ? description
          : existing?.description,
      format: format ?? existing?.format,
      textRequired: textRequired ?? existing?.textRequired,
      maxCountInDocument: maxCountInDocument ?? existing?.maxCountInDocument,
    );
  }

  /// Section-types ordered by descending prefix length so the DocSpecs factory
  /// (first `startsWith` match) resolves the most specific prefix first.
  Map<String, SectionTypeDef> orderedSectionTypes() {
    final entries = _sectionTypes.entries.toList()
      ..sort((a, b) {
        final byLen =
            (b.value.prefix?.length ?? 0).compareTo(a.value.prefix?.length ?? 0);
        return byLen != 0 ? byLen : a.key.compareTo(b.key);
      });
    return {for (final e in entries) e.key: e.value};
  }

  /// A unique, DocSpecs-legal prefix (`^[a-zA-Z0-9_]+$`) for a section id.
  String _prefixFor(String id) {
    var base = id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    base = base.replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'sec';
    var candidate = base;
    var n = 2;
    while (_usedPrefixes.contains(candidate)) {
      candidate = '${base}_$n';
      n++;
    }
    _usedPrefixes.add(candidate);
    return candidate;
  }

  String? _targetClassName(ModelField f) {
    if (f.isList) {
      return f.listElementIsComplex ? f.listElementTypeName : null;
    }
    if (f.isComplex) return f.typeName.replaceAll('?', '');
    return null;
  }

  static String _slugDash(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static String? _help(AnnotationData? anno) {
    if (anno == null) return null;
    final g = anno.arguments['guidance'] as String?;
    return (g != null && g.isNotEmpty) ? g : null;
  }

  static String? _firstLine(String doc) {
    if (doc.isEmpty) return null;
    final line = doc.split('\n').first.trim();
    return line.isEmpty ? null : line;
  }
}
