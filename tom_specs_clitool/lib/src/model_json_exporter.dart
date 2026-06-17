import 'model_reader.dart';

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

    roots.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));

    return {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
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

  String? _sectionId(ModelClass cls) =>
      cls.getAnnotation('SectionId')?.arguments['id'] as String?;

  String? _help(AnnotationData? anno) {
    if (anno == null) return null;
    final g = anno.arguments['guidance'] as String?;
    return (g != null && g.isNotEmpty) ? g : null;
  }

  String _splitPascal(String name) => name
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());
}
