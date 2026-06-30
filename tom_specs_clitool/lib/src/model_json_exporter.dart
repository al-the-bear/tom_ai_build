import 'model_reader.dart';
import 'spec_model_meta_validator.dart';

/// Serializes the resolved [ModelClass] graph into a JSON-ready map that a
/// UI (e.g. the tom_specs_editor Flutter app) can expand lazily into a tree.
///
/// The output is a *class graph*, not a fully-expanded tree: each class is
/// emitted once with its fields, and the consumer walks `elementType` / `type`
/// references on demand (with its own cycle detection). This keeps the export
/// finite even though the model is recursive.
///
/// Section types (`TextSection`, diagram/code sections) live outside the model
/// package, so they are never resolvable as classes. Everything a renderer
/// needs for a section field (its `contentType`) is carried on the field of
/// kind `section`, mirroring how the outliner renders them inline.
class ModelJsonExporter {
  final Map<String, ModelClass> classes;

  /// The S2 model-version counter (counts up as the object model changes). The
  /// build (§17) feeds this from the `tom_specs_model` version stamp so the
  /// bundled `spec_model.json` records exactly which model version it was
  /// generated against (B2). `0` marks an unstamped export (e.g. a manual run).
  final int modelVersion;

  /// A human-readable build label for the same stamp (e.g.
  /// `TomSpecsModelVersionInfo.versionMedium`). Null when unstamped.
  final String? modelVersionLabel;

  ModelJsonExporter(
    this.classes, {
    this.modelVersion = 0,
    this.modelVersionLabel,
  });

  /// Builds the full JSON-ready map.
  Map<String, Object?> export() {
    final roots = <Map<String, Object?>>[];
    final classMap = <String, Object?>{};

    final sortedNames = classes.keys.toList()..sort();
    for (final name in sortedNames) {
      final cls = classes[name]!;
      classMap[name] = _exportClass(cls);

      final doc = cls.getAnnotation('Document');
      if (doc != null) {
        roots.add({
          'type': name,
          'title': (doc.arguments['name'] as String?) ?? _splitPascal(name),
          if (_sectionId(cls) != null) 'sectionId': _sectionId(cls),
          if ((doc.arguments['description'] as String?)?.isNotEmpty ?? false)
            'description': doc.arguments['description'],
          if (cls.docComment.isNotEmpty) 'doc': cls.docComment,
        });
      }
    }

    // Roots sort by their document number — the `Dxx` prefix parsed from the
    // root class name (D00SolutionBlueprint → 0, …, D12TransitionRolloutPlan →
    // 12) — so generated outlines and the editor navigator list documents in
    // D00→D12 order automatically. `Dxx` lives on the class name only, never on
    // a `@SectionId`. Roots without a `Dxx` prefix sort after the numbered ones,
    // alphabetically by title.
    roots.sort((a, b) {
      final ka = _docOrderKey(a['type'] as String);
      final kb = _docOrderKey(b['type'] as String);
      if (ka != kb) return ka.compareTo(kb);
      return (a['title'] as String).compareTo(b['title'] as String);
    });

    return {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      // The file format's own version, distinct from `modelVersion` (which
      // model version this was generated against). See [specModelMetaSchemaVersion].
      'metaSchemaVersion': specModelMetaSchemaVersion,
      'modelVersion': modelVersion,
      if (modelVersionLabel != null) 'modelVersionLabel': modelVersionLabel,
      'classCount': classes.length,
      'rootCount': roots.length,
      // The canonical container is the single true tree root (V2, N9): the
      // editor loads/saves/snapshots the whole spec through it. It is not a
      // document, so it stays out of `roots` (the navigator entry points) and
      // is surfaced separately here. Null when the model has no container
      // (e.g. a synthetic export).
      'containerRoot': findContainerRoot(classes),
      'roots': roots,
      'classes': classMap,
    };
  }

  Map<String, Object?> _exportClass(ModelClass cls) {
    return {
      'name': cls.name,
      if (_sectionId(cls) != null) 'sectionId': _sectionId(cls),
      if (cls.docComment.isNotEmpty) 'doc': cls.docComment,
      if (_help(cls.getAnnotation('ContentHelp')) != null)
        'help': _help(cls.getAnnotation('ContentHelp')),
      if (cls.getAnnotation('MapsTo') != null)
        'mapsTo': cls.getAnnotation('MapsTo')!.arguments['documentClass'],
      if (cls.getAnnotation('DetailedIn') != null)
        'detailedIn': cls.getAnnotation('DetailedIn')!.arguments['documentClass'],
      if (_standardRefs(cls.getAnnotation('StandardReferences')) != null)
        'standardReferences':
            _standardRefs(cls.getAnnotation('StandardReferences')),
      if (cls.annotations.isNotEmpty)
        'annotations': _exportAnnotations(cls.annotations),
      'fields': cls.fields.map(_exportField).toList(),
    };
  }

  Map<String, Object?> _exportField(ModelField f) {
    final out = <String, Object?>{
      'name': f.name,
      'kind': _kind(f),
    };
    if (f.docComment.isNotEmpty) out['doc'] = f.docComment;

    final help = _help(f.getAnnotation('ContentHelp'));
    if (help != null) out['help'] = help;

    final sectionId = f.getAnnotation('SectionId')?.arguments['id'] as String?;
    if (sectionId != null) out['sectionId'] = sectionId;
    final pattern =
        f.getAnnotation('SectionIdPattern')?.arguments['pattern'] as String?;
    if (pattern != null) out['sectionIdPattern'] = pattern;

    final standardRefs = _standardRefs(f.getAnnotation('StandardReferences'));
    if (standardRefs != null) out['standardReferences'] = standardRefs;

    if (f.serializationOrder != null) {
      out['serializationOrder'] = f.serializationOrder;
    }

    if (f.annotations.isNotEmpty) {
      out['annotations'] = _exportAnnotations(f.annotations);
    }

    switch (out['kind']) {
      case 'list':
        out['elementType'] = f.listElementTypeName;
        out['elementIsComplex'] = f.listElementIsComplex;
        final min = f.getAnnotation('Min')?.arguments['count'];
        if (min != null) out['min'] = min;
        break;
      case 'form':
        out['formFields'] = f.formFields
            .map((ff) => {
                  'name': ff.name,
                  'label': ff.description.isNotEmpty
                      ? ff.description
                      : _splitPascal(ff.name),
                  if (ff.hint.isNotEmpty) 'hint': ff.hint,
                  'type': ff.typeName,
                  'required': ff.required,
                })
            .toList();
        break;
      case 'section':
        out['contentType'] = f.sectionContentType ?? 'text';
        out['sectionType'] = f.typeName.replaceAll('?', '');
        break;
      case 'content':
        out['contentType'] =
            (f.getAnnotation('ContentType')?.arguments['type'] as String?) ??
                'text';
        break;
      case 'enum':
        out['enumType'] = f.typeName.replaceAll('?', '');
        out['enumValues'] = f.enumValues;
        break;
      case 'complex':
        out['type'] = f.typeName.replaceAll('?', '');
        break;
      case 'scalar':
        out['type'] = f.typeName.replaceAll('?', '');
        break;
    }
    return out;
  }

  /// Classifies a field into a render kind for the editor tree.
  ///
  /// Note the explicit primitive guard before the `isComplex` check: the shared
  /// [ModelField.isComplex] only treats `String`/enum as leaf, so numeric and
  /// boolean fields would otherwise be misclassified as `complex` (and the
  /// editor would try to resolve them as classes). The validator's semantics
  /// are left untouched — the correction lives here, at the render boundary.
  String _kind(ModelField f) {
    if (f.isList) return 'list';
    if (f.formFields.isNotEmpty) return 'form';
    if (f.isSectionType) return 'section';
    if (f.isEnum) return 'enum';
    if (f.isString) return 'content';
    if (_isPrimitive(f.typeName)) return 'scalar';
    if (f.isComplex) return 'complex';
    return 'scalar';
  }

  static const _primitiveTypes = {
    'int',
    'double',
    'bool',
    'num',
    'DateTime',
    'String',
  };

  bool _isPrimitive(String typeName) {
    final base =
        typeName.endsWith('?') ? typeName.substring(0, typeName.length - 1) : typeName;
    return _primitiveTypes.contains(base);
  }

  /// Emits the full, lossless annotation list for a class or field: **every**
  /// annotation [ModelReader] captured, each as `{name, arguments}` with its
  /// resolved argument map intact (plan §A.1 / spec §3.1). The curated keys
  /// above (`sectionId`, `mapsTo`, `min`, `contentType`, …) are a redundant
  /// projection of this same data, kept for existing consumers (the editor
  /// tree); this block is the lossless source the generic runtime's meta-model
  /// loader (plan §B.3) reads. Source declaration order is preserved so the
  /// output is stable across runs. The argument values are the analyzer's
  /// resolved constants (String/int/double/bool/Type-name/List), so the block
  /// stays JSON-serializable.
  List<Map<String, Object?>> _exportAnnotations(List<AnnotationData> annos) =>
      annos
          .map((a) => <String, Object?>{
                'name': a.name,
                if (a.arguments.isNotEmpty) 'arguments': a.arguments,
              })
          .toList();

  String? _sectionId(ModelClass cls) =>
      cls.getAnnotation('SectionId')?.arguments['id'] as String?;

  String? _help(AnnotationData? anno) {
    if (anno == null) return null;
    final g = anno.arguments['guidance'] as String?;
    return (g != null && g.isNotEmpty) ? g : null;
  }

  /// Projects a `@StandardReferences` annotation into a curated
  /// `{standards, connotation}` map for first-class consumer access (mirroring
  /// the `mapsTo` / `detailedIn` projection). The lossless `annotations` block
  /// still carries the same data; this is the convenient view. Returns null
  /// when the annotation is absent or carries no usable values.
  Map<String, Object?>? _standardRefs(AnnotationData? anno) {
    if (anno == null) return null;
    final standards = anno.arguments['standards'];
    final connotation = anno.arguments['connotation'] as String?;
    final hasStandards = standards is List && standards.isNotEmpty;
    final hasConnotation = connotation != null && connotation.isNotEmpty;
    if (!hasStandards && !hasConnotation) return null;
    return {
      if (hasStandards) 'standards': standards,
      if (hasConnotation) 'connotation': connotation,
    };
  }

  String _splitPascal(String name) => name
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());

  /// Parses the leading `Dxx` document number from a root class name (e.g.
  /// `D07IntegrationInterfaceSpecification` → `7`). Returns a large sentinel
  /// for class names without a `Dxx` prefix so they sort after the numbered
  /// document roots.
  static final RegExp _docNumberPattern = RegExp(r'^D(\d+)');
  int _docOrderKey(String className) {
    final m = _docNumberPattern.firstMatch(className);
    return m == null ? 1 << 30 : int.parse(m.group(1)!);
  }
}
