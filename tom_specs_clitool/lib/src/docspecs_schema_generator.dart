import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show somModelVersionString;

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
/// Versioning (S2, CS2-D7): [generateAll]/[generateFor] take the integer model
/// stamp `modelVersion` and the optional full build `modelLabel` (the
/// `tom_specs_model` version stamp, e.g. `1.3.0+5.abc1234`). The emitted schema
/// `version` is routed through [somModelVersionString] — the *same*
/// single-source helper the `_v0` facades report through
/// `SpecModel.modelVersionString` — so a genuine authoring **minor** is
/// preserved (`1.3`) instead of the schema silently reporting `1.0` while the
/// facade reports `1.3`. When the model is unstamped (`modelLabel == null`) the
/// version falls back to `<modelVersion>.0`.
///
/// The on-disk **filename** ([fileNameFor]) stays keyed off the integer major
/// (`<id>.<major>.0.docspecs-schema.yaml`) — only the in-file `version` string
/// tracks the minor. This keeps the committed schema tree stable across a minor
/// bump (the DocSpecs filename grammar is `<id>.<major>.<minor>...`, and churning
/// the minor there would rename every file and defeat the [writeSchemaTree]
/// prune, which keys directories by schema id).
class DocSpecsSchemaGenerator {
  /// The full resolved class graph (as produced by [ModelReader]).
  final Map<String, ModelClass> classes;

  DocSpecsSchemaGenerator(this.classes);

  /// Builds every document-root schema, keyed by schema id.
  ///
  /// Throws [StateError] if two roots slugify to the same id (which would make
  /// the on-disk schema files collide).
  Map<String, DocSpecSchema> generateAll({
    int modelVersion = 1,
    String? modelLabel,
  }) {
    final rootNames = classes.values
        .where((c) => c.getAnnotation('Document') != null)
        .map((c) => c.name)
        .toList()
      ..sort();

    final result = <String, DocSpecSchema>{};
    for (final rootName in rootNames) {
      final schema = generateFor(
        rootName,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
      );
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
  DocSpecSchema generateFor(
    String rootName, {
    int modelVersion = 1,
    String? modelLabel,
  }) {
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
      // Single-sourced with the `_v0` facades (CS2-D7): a genuine authoring
      // minor from `modelLabel` is preserved; unstamped falls back to
      // `<modelVersion>.0`.
      version: somModelVersionString(modelVersion, modelLabel),
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
  ///
  /// The filename is keyed off the integer **major** only, with the minor
  /// pinned to `0` (`<id>.<major>.0.docspecs-schema.yaml`). A minor bump moves
  /// the in-file [DocSpecSchema.version] string (e.g. `1.3`) but leaves the
  /// filename at `<major>.0`, so the committed schema tree does not churn
  /// filenames — only the in-file version tracks the minor (CS2-D7).
  static String fileNameFor(DocSpecSchema schema) {
    final major = schema.version.split('.').first;
    return '${schema.id}.$major.0.docspecs-schema.yaml';
  }

  /// Writes the full DocSpecs schema tree under `<outputRoot>/schemas/` and
  /// returns the written file paths (sorted).
  ///
  /// The `schemas/` directory is owned wholesale by the generator, so any
  /// subdirectory whose name is not a current schema id is **pruned** first.
  /// Without this, a root that gets renamed or removed leaves a stale
  /// `*.docspecs-schema.yaml` orphan behind — the per-language emitters write
  /// new files but never delete obsolete ones, so regeneration was not
  /// idempotent. Pruning keeps the committed tree a faithful image of the model.
  static List<String> writeSchemaTree(
    String outputRoot,
    Map<String, DocSpecSchema> schemas,
  ) {
    final schemasDir = Directory(p.join(outputRoot, 'schemas'));
    final keepIds = schemas.values.map((s) => s.id).toSet();
    if (schemasDir.existsSync()) {
      for (final entity in schemasDir.listSync()) {
        if (entity is Directory && !keepIds.contains(p.basename(entity.path))) {
          entity.deleteSync(recursive: true);
        }
      }
    }
    final paths = <String>[];
    for (final schema in schemas.values) {
      final file = File(p.join(outputRoot, 'schemas', schema.id, fileNameFor(schema)))
        ..parent.createSync(recursive: true);
      file.writeAsStringSync(toYamlString(schema));
      paths.add(file.path);
    }
    paths.sort();
    return paths;
  }

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

    // List cardinality: @Min(n)/@Max(n) on the (patterned) list field map to the
    // document-level min/max-count of the element section-type. They only apply
    // to list fields, so single (non-pattern) fields never carry them.
    final minCount = f.getAnnotation('Min')?.arguments['count'] as int?;
    final maxCount = f.getAnnotation('Max')?.arguments['count'] as int?;

    _putSectionType(
      typeId,
      description: description,
      format: format,
      textRequired: textRequired,
      minCountInDocument: minCount,
      // List-element (pattern) types are uncapped unless @Max bounds them;
      // single fields cap at 1.
      maxCountInDocument: maxCount ?? (pattern != null ? null : 1),
      // Only @SectionIdPattern (list-element) types get an id pattern-check:
      // their document ids are numbered (`<prefix>-001`), so the regex pins
      // the prefix + numeric suffix. Single fields have a fixed id and need no
      // pattern. (OE-21)
      isPatternElement: pattern != null,
    );
  }

  /// Inserts or enriches a section-type keyed by its TomSpecs id.
  void _putSectionType(
    String id, {
    String? description,
    String? format,
    bool? textRequired,
    int? minCountInDocument,
    int? maxCountInDocument,
    bool isPatternElement = false,
  }) {
    final existing = _sectionTypes[id];
    final prefix = existing?.prefix ?? _prefixFor(id);
    // Numbered list-element ids match `<prefix>-NNN`; DocSpecs resolves the
    // section type by the prefix slug, so the regex is prefix-based (OE-21).
    final patternCheckId = isPatternElement
        ? PatternCheckDef(
            pattern: '^${RegExp.escape(prefix)}-\\d+\$',
            errorMessage: 'ID must match $prefix-NNN',
          )
        : existing?.patternCheckId;
    _sectionTypes[id] = SectionTypeDef(
      name: id,
      prefix: prefix,
      description: (description != null && description.isNotEmpty)
          ? description
          : existing?.description,
      format: format ?? existing?.format,
      textRequired: textRequired ?? existing?.textRequired,
      minCountInDocument: minCountInDocument ?? existing?.minCountInDocument,
      maxCountInDocument: maxCountInDocument ?? existing?.maxCountInDocument,
      patternCheckId: patternCheckId,
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
