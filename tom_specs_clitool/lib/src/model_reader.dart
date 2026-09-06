import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:path/path.dart' as p;

/// Annotation data extracted from the analyzer element model.
class AnnotationData {
  /// The annotation's class name without the leading `@` (`SectionId`,
  /// `Form`, `MapsTo`). It is taken from the resolved constructor's
  /// enclosing element, so a prefixed or aliased import still yields the
  /// declaring class name. An annotation whose element does not resolve is
  /// dropped entirely rather than recorded under a guessed name.
  final String name;

  /// The constant-folded arguments, keyed by the annotation class's own
  /// *field* names rather than by the call-site parameter names — so a
  /// positional argument arrives under the field it initialises.
  ///
  /// Values are `String`, `int`, `bool` or `double`; a `Type` argument
  /// becomes its class name, so `@MapsTo(InformationModel)` yields
  /// `'InformationModel'`; an enum argument becomes the qualified
  /// `EnumType.constant`; and lists
  /// hold any of those. An argument that is null or does not constant-fold
  /// is **absent** from the map, so a missing key and a null value are the
  /// same fact here.
  final Map<String, Object?> arguments;

  /// [arguments] is optional so that marker annotations (`@Unused()`) need
  /// no empty map at the call site.
  AnnotationData(this.name, [this.arguments = const {}]);

  @override
  String toString() => '@$name${arguments.isEmpty ? '' : '($arguments)'}';
}

/// A form field extracted from a `@Form([Field(...)])` annotation.
class FormFieldInfo {
  /// The slot name declared as `Field('name', ...)`, used verbatim as the
  /// `Name: value` key of the serialized form section and as the resolution
  /// target of any `refersTo` entry naming it
  /// (`tom_specs_model_rules.md` §6.2 rule 1). A `Field` whose name does not
  /// constant-fold is skipped by the reader, so this is never empty.
  final String name;

  /// Dart type name of the slot's value, read from the `Field` type
  /// literal. Falls back to `String` when the literal is absent or does not
  /// resolve to an interface type — `String` being the model's default form
  /// field type — so a consumer always has a type to parse against. When it
  /// names a model enum, [enumValues] is populated too.
  final String typeName;

  /// The declared display label for the slot. Empty — not null — when the
  /// `Field` omitted it, in which case consumers derive the label by
  /// splitting [name] on PascalCase
  /// (`tom_specs_model_meta_schema.md`, `formFields[]` entry).
  final String description;

  /// Whether the slot must be filled in. Beyond marking the schema field
  /// required, this gates registry membership: only a `required` field may
  /// be named as a `refersTo` target, because an entry could omit an
  /// optional id and so it could never be a key
  /// (`tom_specs_model_rules.md` §6.2 rule 4).
  final bool required;

  /// Optional hint text guiding valid values/formats for this form field.
  final String hint;

  /// Enum constant names when [typeName] is a model enum (YRD7); empty for
  /// non-enum field types. Resolved at read time so every downstream consumer
  /// (meta JSON, meta emitters, facade emitters) sees the values without
  /// needing the analyzer.
  final List<String> enumValues;

  /// The registry key(s) this field's value is an id drawn from, each
  /// `<SECTIONID>.<formFieldName>` (csrb3). Empty for a field that is not a
  /// cross-registry reference. See `Field.refersTo` in `tom_specs_core`.
  final List<String> refersTo;

  /// [name] and [typeName] are required — a slot without either is not
  /// addressable and not parseable. Every remaining property defaults to
  /// its *empty* value (`''` / `const []`) rather than null, so consumers
  /// test with `isEmpty` throughout and an omitted `Field` argument is
  /// indistinguishable from an explicitly empty one.
  FormFieldInfo({
    required this.name,
    required this.typeName,
    this.description = '',
    this.required = false,
    this.hint = '',
    this.enumValues = const [],
    this.refersTo = const [],
  });
}

/// A resolved field from a model class.
class ModelField {
  /// The Dart member name exactly as declared. It is the identity used for
  /// `@SerializationOrder` stamping, for the path segment when no
  /// `@SectionId` overrides it, and for the PascalCase-split fallback
  /// headline — so renaming a member is an observable change to every
  /// generated surface, not a refactor.
  final String name;

  /// Display name of the *declared* type: `?` preserved for nullable types,
  /// list types written `List<Inner>`, and interface types reduced to their
  /// bare class name (no library prefix, no type arguments beyond the list
  /// element). Use [metaTypeName] for what the exported meta tree should
  /// report — the two differ for `DocSpecsSection` members (YRD5).
  final String typeName;

  /// Whether the declared type is `List<T>`. This is tested before every
  /// other classification rule, so a `List<TextSection>` is a list member
  /// rather than a section member; the element type is in
  /// [listElementTypeName].
  final bool isList;

  /// Whether the declared type carries `?`. Nullability deliberately does
  /// not change a member's kind and is not shown in the outline
  /// (`tom_specs_model_rules.md` §11.2.7); its only structural effect is
  /// choosing `String?` over `String` in [metaTypeName].
  final bool isNullable;

  /// Whether the declared type resolves to an enum declaration. The flag is
  /// what keeps an enum-typed member off the class-expansion path — without
  /// it an enum would look like any other non-primitive class type.
  final bool isEnum;

  /// The enum's constant names in **declaration order**, resolved at read
  /// time so no downstream consumer needs the analyzer. The order is part
  /// of the contract: enum-valued annotation arguments are decoded by
  /// indexing this list with the constant's `index`, so reordering
  /// constants in the model reinterprets already-exported metadata. Empty
  /// unless [isEnum].
  final List<String> enumValues;

  /// Every annotation on the member, in source order, captured losslessly.
  /// The meta tree keeps the ones with dedicated slots and routes the rest
  /// into its `extra` list, and the exported meta file carries this whole
  /// block beside its curated projection
  /// (`tom_specs_model_meta_schema.md`, `fields[]` entry). Look one up with
  /// [getAnnotation].
  final List<AnnotationData> annotations;

  /// For list fields, the inner type name.
  final String? listElementTypeName;

  /// Whether the inner type of a list is a complex (class) type.
  final bool listElementIsComplex;

  /// Whether this field's type is a known section type (TextSection, etc.).
  final bool isSectionType;

  /// Whether this field's declared type is `DocSpecsSection` (YRD5): the
  /// universal simple-section base type from `tom_specs_core` that replaced
  /// the former `String` section members of the model. Such members are
  /// classified as **content** nodes — the runtime representation of a simple
  /// section is its String content (headline/id are stored per node by the
  /// YRD3 runtime) — so the exported meta tree stays identical to the
  /// pre-YRD5 String-member model (see [metaTypeName]).
  final bool isContentSection;

  /// Whether the inner type of a list is `DocSpecsSection` (the YRD5
  /// replacement of `List<String>` inline content lists).
  final bool listElementIsContentSection;

  /// The content type marker for section types (e.g., 'text', 'mermaid-er').
  final String? sectionContentType;

  /// Form fields extracted from a `@Form` annotation on this field.
  final List<FormFieldInfo> formFields;

  /// The cleaned doc-comment text on the field declaration, if any.
  final String docComment;

  /// [name] and [typeName] are the only required arguments — they are the
  /// two facts the analyzer can never fail to supply for a member it
  /// reported at all.
  ///
  /// Every classification flag defaults to its *unclassified* value
  /// (false / null / `const []`), so a member built from a type the reader
  /// did not recognise degrades to a plain scalar leaf rather than being
  /// mis-typed as a section, an enum or a content member.
  ModelField({
    required this.name,
    required this.typeName,
    this.isList = false,
    this.isNullable = false,
    this.isEnum = false,
    this.enumValues = const [],
    this.annotations = const [],
    this.listElementTypeName,
    this.listElementIsComplex = false,
    this.isSectionType = false,
    this.isContentSection = false,
    this.listElementIsContentSection = false,
    this.sectionContentType,
    this.formFields = const [],
    this.docComment = '',
  });

  /// Whether this member expands into its target class's own subtree rather
  /// than terminating the tree.
  ///
  /// This is deliberately a *negation* — not a leaf, not a list, not a
  /// section — rather than a positive test for "names a model class", so an
  /// unresolved type is treated as expandable. The consequence is that
  /// primitive members other than `String` (`int`, `bool`, `DateTime`, …)
  /// also report true here, because [isLeaf] does not admit them. Kind
  /// classification therefore applies a primitive guard *before* consulting
  /// this getter (`MetaTreeBuilder.classifyField`); any other caller must
  /// do the same or an `int` member will be expanded as a class.
  bool get isComplex =>
      !isLeaf && !isList && !isSectionType;

  /// Whether this member terminates the tree: a `DocSpecsSection` content
  /// member (YRD5), or a non-complex `String` / `String?` / enum member.
  ///
  /// Note the narrowness — this is *not* "any non-class type". Numeric,
  /// boolean and `DateTime` members are **not** leaves by this test; they
  /// reach their scalar classification through the primitive guard in kind
  /// classification instead. See [isComplex] for the other half of that
  /// split.
  bool get isLeaf =>
      !isList &&
      (isContentSection ||
          (!_isComplexType(typeName) &&
              (typeName == 'String' || typeName == 'String?' || isEnum)));

  /// Whether this is a String or String? field (not enum).
  bool get isString =>
      (typeName == 'String' || typeName == 'String?') && !isEnum;

  /// Whether this member is a content node: a plain `String` member (legacy
  /// shape) or a `DocSpecsSection` member (YRD5 shape). Classification,
  /// validation and export treat the two identically.
  bool get isContentLike => isString || isContentSection;

  /// The type name this member contributes to the exported meta tree.
  ///
  /// `DocSpecsSection` members report `String`/`String?` — the meta contract
  /// (SOM §7.1) models a simple section by its String content, and the YRD5
  /// refactor must keep the exported tree byte-identical. All other members
  /// report their declared [typeName].
  String get metaTypeName => isContentSection
      ? (isNullable ? 'String?' : 'String')
      : (listElementIsContentSection ? 'List<String>' : typeName);

  /// The list-element type name contributed to the exported meta tree:
  /// `String` for `List<DocSpecsSection>` (see [metaTypeName]), else the
  /// declared [listElementTypeName].
  String? get metaListElementTypeName =>
      listElementIsContentSection ? 'String' : listElementTypeName;

  /// The first annotation whose class name is [name] (written without the
  /// `@`), or null when the member carries none.
  ///
  /// First-wins, not last-wins: a member with a repeated annotation keeps
  /// the earliest declaration and the duplicate is silently ignored, so
  /// repeated annotations are an authoring error this does not report.
  /// Callers commonly use it as a presence test rather than a value lookup.
  AnnotationData? getAnnotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }

  /// The member's serialization ordinal from `@SerializationOrder(n)`, or null
  /// when the member is not stamped. The ordinal is the member's 0-based
  /// position in source declaration order within its declaring class.
  int? get serializationOrder =>
      getAnnotation('SerializationOrder')?.arguments['order'] as int?;

  static bool _isComplexType(String name) {
    final base = name.endsWith('?') ? name.substring(0, name.length - 1) : name;
    return base != 'String' &&
        base != 'int' &&
        base != 'double' &&
        base != 'bool' &&
        base != 'num' &&
        base != 'DateTime';
  }
}

/// A resolved model class.
class ModelClass {
  /// The exact declared class name. It is both the registry key this class
  /// is stored under and the name every complex member type, `@MapsTo` and
  /// `@DetailedIn` target is resolved against — so class names must be
  /// unique across the whole scanned source; a second declaration of the
  /// same name silently replaces the first in the registry.
  final String name;

  /// The class's **own** instance members, in declaration order.
  ///
  /// Statics and enum constants are skipped, and inherited members are not
  /// included: the members a class gains from the `DocSpecsSection` base
  /// type (YRD5) are runtime infrastructure, not document sections, and
  /// deliberately never appear as nodes. Pulling a member up into a base
  /// class therefore removes it from the model.
  final List<ModelField> fields;

  /// Every class-level annotation in source order, captured losslessly. The
  /// meta tree consults these as the *fallback* level for any slot the
  /// instantiating member did not supply, and the exported meta file
  /// carries the whole block beside its curated projection
  /// (`tom_specs_model_meta_schema.md`, `classes[name]` entry).
  final List<AnnotationData> annotations;

  /// The cleaned doc-comment text on the class declaration, if any.
  final String docComment;

  /// Form fields extracted from a class-level `@Form` annotation (form
  /// section classes such as `UserRegistrationProcess`). Field-level `@Form`
  /// lives on [ModelField.formFields].
  final List<FormFieldInfo> formFields;

  /// Whether this class (directly or transitively) extends the
  /// `DocSpecsSection` base type from `tom_specs_core` (YRD5). Every model
  /// class must; the structural validator enforces it once any class in the
  /// model has adopted the base.
  final bool extendsDocSpecsSection;

  /// Only [name] is required: a class contributes its identity to the
  /// registry even when it declares nothing else, and a complex member
  /// pointing at such a class still resolves — to an empty subtree — rather
  /// than degrading to an unresolved leaf. Every other property defaults to
  /// the empty/false value, so "not annotated" and "annotation not read"
  /// are indistinguishable to consumers.
  ModelClass({
    required this.name,
    this.fields = const [],
    this.annotations = const [],
    this.docComment = '',
    this.formFields = const [],
    this.extendsDocSpecsSection = false,
  });

  /// The first class-level annotation named [name] (written without the
  /// `@`), or null. Same first-wins rule as `ModelField.getAnnotation`.
  ///
  /// It is used as a presence test at least as often as a value lookup:
  /// `getAnnotation('Document') != null` is exactly what marks a class a
  /// document root, both here and in [findContainerRoot].
  AnnotationData? getAnnotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// Finds the canonical container root of the TomSpecs model (V2, N9).
///
/// The container is the **unannotated** top-level class that owns the
/// `D00SolutionBlueprint` store plus the twelve projection roots, giving the
/// whole spec a single tree root for load/save/snapshot/undo. It is *not* a
/// document node — it carries no `@Document` and no `@SectionId` — so the
/// tooling must recognise it structurally rather than by annotation (T1).
///
/// Identification is by ownership: a non-`@Document` class that declares a
/// (non-list) field whose type is `D00SolutionBlueprint`. Only the container
/// holds SBP by value — the projection roots reference SBP00 *sections*, not the
/// SBP root itself — so this is unambiguous. Returns the class name, or `null`
/// if no container is present (e.g. a small synthetic model).
String? findContainerRoot(Map<String, ModelClass> classes) {
  for (final entry in classes.entries) {
    final cls = entry.value;
    if (cls.name == 'D00SolutionBlueprint') continue;
    if (cls.getAnnotation('Document') != null) continue;
    final ownsSolutionBlueprint = cls.fields.any(
      (f) =>
          !f.isList && f.typeName.replaceAll('?', '') == 'D00SolutionBlueprint',
    );
    if (ownsSolutionBlueprint) return entry.key;
  }
  return null;
}

/// A resolved enum type.
class ModelEnum {
  /// The declared enum type name and the key this enum is registered under.
  /// It is what a `List<T>` element type or a `Field` type literal is
  /// matched against when a consumer needs the constants without running
  /// the analyzer.
  final String name;

  /// The constant names in **declaration order**. The order is part of the
  /// contract: an enum-valued annotation argument is exported as
  /// `EnumType.constant` by indexing this list with the constant's `index`,
  /// so reordering constants in the model changes the meaning of metadata
  /// that was already exported.
  final List<String> values;

  /// Both properties are required: an enum with no name cannot be looked
  /// up, and one with no constants cannot validate a value, so neither has
  /// a meaningful default.
  ModelEnum({required this.name, required this.values});
}

/// Reads model classes from Dart source files using the analyzer.
class ModelReader {
  final AnalysisDriver _driver;

  /// Every class declaration read so far, keyed by class name.
  ///
  /// The map accumulates across all files of an [analyzePackage] run and is
  /// never cleared, so calling [analyzePackage] twice on one reader yields
  /// the union of both packages — reuse an instance only when that is what
  /// you want. Consumers treat it as the complete class graph: a type name
  /// missing from it is what makes a member degrade to a leaf.
  final Map<String, ModelClass> classes = {};

  /// Every enum declaration read so far, keyed by type name.
  ///
  /// Kept separate from [classes] because the two are consulted for
  /// different reasons — a class name resolves an expandable subtree, an
  /// enum name resolves a closed value set — and a given name legitimately
  /// appears in only one of them. Accumulates on the same terms as
  /// [classes].
  final Map<String, ModelEnum> enums = {};

  /// Known section types and their content type markers.
  static const _sectionTypes = {
    'TextSection': 'text',
    'DiagramSection': 'mermaid',
    'ErDiagramSection': 'mermaid-er',
    'FlowDiagramSection': 'mermaid-flow',
    'GanttDiagramSection': 'mermaid-gantt',
    'SequenceDiagramSection': 'mermaid-sequence',
    'CodeSection': 'code',
    'DartCodeSection': 'code-dart',
    'SqlCodeSection': 'code-sql',
    'DdlCodeSection': 'code-ddl',
  };

  /// Takes an already-configured analyzer `AnalysisDriver` rather than
  /// building one, because resolution needs the scanned package's own
  /// `package_config.json`, SDK and resource provider — facts only the
  /// caller knows. Passing a shared driver also reuses its file-resolution
  /// cache across readers, which dominates the cost of a whole-model scan.
  ModelReader(this._driver);

  /// Subtrees of `lib/src` that hold the snapshot/serialization engine
  /// (`SpecNode`, `SpecSlot`, `SpecSnapshotter`, `SpecYaml`, `SpecProjection`,
  /// `SpecRegistry`) and its generated registry — *infrastructure*, not the
  /// document model. They are excluded from the reflected model so the
  /// `tom_specs_model_rules.md` §10.2 validator, the outliner, and the JSON
  /// exporter never treat the engine's own classes as document sections (OE-2).
  /// Real model leaves that adopt `SpecNode` (`DocumentHeader`/`SectionMeta`)
  /// live under `common/` and are still read.
  /// Public because the freshness gate (`model_freshness.dart`) must fingerprint
  /// exactly the file set this reader consumes — a file the reader skips cannot
  /// change the generated output, and fingerprinting it would raise false alarms.
  static const excludedSrcDirs = ['snapshot', 'serialization', 'generated'];

  /// Analyzes all .dart files under [packageLibPath] and collects
  /// model classes and enums.
  Future<void> analyzePackage(String packageLibPath) async {
    final srcDir = Directory(p.join(packageLibPath, 'src'));
    if (!srcDir.existsSync()) {
      throw StateError('Source directory not found: ${srcDir.path}');
    }

    final dartFiles = srcDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !_isExcludedInfraFile(srcDir.path, f.path))
        .toList();

    for (final file in dartFiles) {
      _driver.addFile(file.path);
    }

    for (final file in dartFiles) {
      final result = await _driver.getResolvedUnit(file.path);
      if (result is ResolvedUnitResult) {
        _processResolvedUnit(result);
      }
    }
  }

  /// Whether [filePath] is engine/generated infrastructure rather than document
  /// model: it lives in one of the [excludedSrcDirs] directly under `lib/src`,
  /// or is a `*.versioner.dart` build-version artifact (a static-only class with
  /// a private constructor — not a spec node, and not zero-arg constructible).
  static bool _isExcludedInfraFile(String srcDirPath, String filePath) {
    if (filePath.endsWith('.versioner.dart')) return true;
    final rel = p.relative(filePath, from: srcDirPath);
    final firstSegment = p.split(rel).first;
    return excludedSrcDirs.contains(firstSegment);
  }

  void _processResolvedUnit(ResolvedUnitResult result) {
    final unit = result.unit;
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        _processClass(declaration);
      } else if (declaration is EnumDeclaration) {
        _processEnum(declaration);
      }
    }
  }

  void _processClass(ClassDeclaration node) {
    final fragment = node.declaredFragment;
    if (fragment == null) return;
    final element = fragment.element;

    final className = element.name ?? '';
    if (className.isEmpty) return;

    final classAnnotations = _readAnnotations(element.metadata);
    final fields = <ModelField>[];

    for (final field in element.fields) {
      if (field.isStatic) continue;
      if (field.isEnumConstant) continue;

      final fieldName = field.name ?? '';
      if (fieldName.isEmpty) continue;

      final fieldType = field.type;
      final fieldAnnotations = _readAnnotations(field.metadata);

      // Extract @Form fields if present
      final formFields = fieldAnnotations.any((a) => a.name == 'Form')
          ? _extractFormFields(field.metadata)
          : const <FormFieldInfo>[];

      fields.add(
        _buildModelField(
          fieldName,
          fieldType,
          fieldAnnotations,
          formFields,
          _cleanDocComment(field.documentationComment),
        ),
      );
    }

    classes[className] = ModelClass(
      name: className,
      fields: fields,
      annotations: classAnnotations,
      docComment: _cleanDocComment(element.documentationComment),
      formFields: classAnnotations.any((a) => a.name == 'Form')
          ? _extractFormFields(element.metadata)
          : const <FormFieldInfo>[],
      extendsDocSpecsSection: _extendsDocSpecsSection(element),
    );
  }

  /// Whether [element] extends `DocSpecsSection` anywhere in its superclass
  /// chain (YRD5). The base type lives in `tom_specs_core`, outside the
  /// scanned package, so the walk is over resolved supertypes.
  static bool _extendsDocSpecsSection(ClassElement element) {
    var supertype = element.supertype;
    while (supertype != null) {
      if (supertype.element.name == _contentSectionType) return true;
      supertype = supertype.element.supertype;
    }
    return false;
  }

  /// Strips `///` / `/** */` markers from a raw doc comment, returning the
  /// joined prose (single line breaks preserved).
  static String _cleanDocComment(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final lines = raw.split('\n');
    final cleaned = <String>[];
    for (var line in lines) {
      line = line.trimLeft();
      if (line.startsWith('///')) {
        line = line.substring(3);
      } else if (line.startsWith('/**')) {
        line = line.substring(3);
      } else if (line.startsWith('*/')) {
        line = line.substring(2);
      } else if (line.startsWith('*')) {
        line = line.substring(1);
      }
      if (line.startsWith(' ')) line = line.substring(1);
      cleaned.add(line.trimRight());
    }
    return cleaned.join('\n').trim();
  }

  void _processEnum(EnumDeclaration node) {
    final fragment = node.declaredFragment;
    if (fragment == null) return;
    final element = fragment.element;

    final enumName = element.name ?? '';
    if (enumName.isEmpty) return;

    final values = <String>[];
    for (final constant in element.constants) {
      final name = constant.name;
      if (name != null) values.add(name);
    }

    enums[enumName] = ModelEnum(name: enumName, values: values);
  }

  ModelField _buildModelField(
    String name,
    DartType type,
    List<AnnotationData> annotations, [
    List<FormFieldInfo> formFields = const [],
    String docComment = '',
  ]) {
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

    // Check for List<T>
    if (type is InterfaceType && type.element.name == 'List') {
      final typeArgs = type.typeArguments;
      if (typeArgs.isNotEmpty) {
        final innerType = typeArgs.first;
        final innerTypeName = _typeDisplayName(innerType);
        final innerIsEnum = _isEnumType(innerType);
        final innerIsContentSection = innerTypeName == _contentSectionType;
        final innerIsComplex = !innerIsEnum &&
            !innerIsContentSection &&
            innerTypeName != 'String' &&
            innerType is InterfaceType &&
            innerType.element is ClassElement;

        return ModelField(
          name: name,
          typeName: 'List<$innerTypeName>',
          isList: true,
          isNullable: isNullable,
          listElementTypeName: innerTypeName,
          listElementIsComplex: innerIsComplex,
          listElementIsContentSection: innerIsContentSection,
          annotations: annotations,
          docComment: docComment,
        );
      }
    }

    // Check for enum
    if (_isEnumType(type)) {
      final enumValues = _getEnumValues(type);
      return ModelField(
        name: name,
        typeName: _typeDisplayName(type),
        isNullable: isNullable,
        isEnum: true,
        enumValues: enumValues,
        annotations: annotations,
        docComment: docComment,
      );
    }

    // Check for known section types (TextSection, DiagramSection, etc.)
    final displayName = _typeDisplayName(type);
    final baseName = displayName.endsWith('?')
        ? displayName.substring(0, displayName.length - 1)
        : displayName;
    final sectionType = _sectionTypes[baseName];

    // Scalar, content section (YRD5) or complex
    return ModelField(
      name: name,
      typeName: displayName,
      isNullable: isNullable,
      annotations: annotations,
      isSectionType: sectionType != null,
      isContentSection: baseName == _contentSectionType,
      sectionContentType: sectionType,
      formFields: formFields,
      docComment: docComment,
    );
  }

  /// The universal simple-section base type (YRD5, `tom_specs_core`).
  static const _contentSectionType = 'DocSpecsSection';

  String _typeDisplayName(DartType type) {
    if (type is InterfaceType) {
      final name = type.element.name ?? 'Unknown';
      return type.nullabilitySuffix == NullabilitySuffix.question
          ? '$name?'
          : name;
    }
    return type.getDisplayString();
  }

  bool _isEnumType(DartType type) {
    if (type is InterfaceType) {
      return type.element is EnumElement;
    }
    return false;
  }

  List<String> _getEnumValues(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;
      if (element is EnumElement) {
        return element.constants
            .map((c) => c.name)
            .whereType<String>()
            .toList();
      }
    }
    return [];
  }

  List<AnnotationData> _readAnnotations(Metadata metadata) {
    final result = <AnnotationData>[];
    for (final annotation in metadata.annotations) {
      final element = annotation.element;
      if (element == null) continue;

      String? name;
      if (element is ConstructorElement) {
        name = element.enclosingElement.name;
      }

      if (name == null) continue;

      final arguments = <String, Object?>{};
      final value = annotation.computeConstantValue();
      if (value != null) {
        // Use the DartObject's type element to iterate fields
        final typeElement = value.type?.element;
        if (typeElement is InterfaceElement) {
          for (final field in typeElement.fields) {
            final fieldName = field.name;
            if (fieldName == null || field.isStatic || field.isEnumConstant) {
              continue;
            }
            final fieldValue = value.getField(fieldName);
            if (fieldValue != null && !fieldValue.isNull) {
              final dartValue = _extractDartValue(fieldValue);
              if (dartValue != null) {
                arguments[fieldName] = dartValue;
              }
            }
          }
        }
      }

      result.add(AnnotationData(name, arguments));
    }
    return result;
  }

  Object? _extractDartValue(dynamic obj) {
    // DartObject
    if (obj.hasKnownValue != true) return null;

    final stringVal = obj.toStringValue();
    if (stringVal != null) return stringVal;

    final intVal = obj.toIntValue();
    if (intVal != null) return intVal;

    final boolVal = obj.toBoolValue();
    if (boolVal != null) return boolVal;

    final doubleVal = obj.toDoubleValue();
    if (doubleVal != null) return doubleVal;

    // Try type value — handles Type arguments such as @MapsTo(InformationModel)
    // and @DetailedIn(ArchitectureTechnologySpecification).
    final typeVal = obj.toTypeValue();
    if (typeVal != null && typeVal is InterfaceType) {
      return typeVal.element.name ?? '';
    }

    // Try enum constant — handles enum-valued arguments such as
    // @CodeSpecKind(CodeSpecPart.dataAccess). Returned as the qualified
    // `EnumType.constant` so the exported model is self-describing without an
    // analyzer. The constant's `index` field maps into the declaration-ordered
    // enum values.
    final enumType = obj.type;
    if (enumType is InterfaceType && _isEnumType(enumType)) {
      final index = obj.getField('index')?.toIntValue();
      final values = _getEnumValues(enumType);
      if (index != null && index >= 0 && index < values.length) {
        return '${enumType.element.name ?? ''}.${values[index]}';
      }
    }

    // Try list
    final listVal = obj.toListValue();
    if (listVal != null) {
      return listVal
          .map((e) => _extractDartValue(e))
          .where((e) => e != null)
          .toList();
    }

    return null;
  }

  /// Extracts [FormFieldInfo] entries from a `@Form([Field(...)])` annotation.
  List<FormFieldInfo> _extractFormFields(Metadata metadata) {
    for (final annotation in metadata.annotations) {
      final element = annotation.element;
      if (element is! ConstructorElement) continue;
      if (element.enclosingElement.name != 'Form') continue;

      final value = annotation.computeConstantValue();
      if (value == null) continue;

      final fieldsList = value.getField('fields');
      if (fieldsList == null) continue;

      final items = fieldsList.toListValue();
      if (items == null) continue;

      final result = <FormFieldInfo>[];
      for (final item in items) {
        final name = item.getField('name')?.toStringValue();
        if (name == null) continue;

        final description =
            item.getField('description')?.toStringValue() ?? '';
        final required = item.getField('required')?.toBoolValue() ?? false;
        final hint = item.getField('hint')?.toStringValue() ?? '';
        final refersTo = item
                .getField('refersTo')
                ?.toListValue()
                ?.map((e) => e.toStringValue())
                .whereType<String>()
                .toList() ??
            const <String>[];

        // Extract type name from the Type literal; resolve enum constant
        // names right here (YRD7) so downstream consumers need no analyzer.
        String typeName = 'String';
        var enumValues = const <String>[];
        final typeVal = item.getField('type')?.toTypeValue();
        if (typeVal is InterfaceType) {
          typeName = typeVal.element.name ?? 'String';
          if (_isEnumType(typeVal)) {
            enumValues = _getEnumValues(typeVal);
          }
        }

        result.add(FormFieldInfo(
          name: name,
          typeName: typeName,
          description: description,
          required: required,
          hint: hint,
          enumValues: enumValues,
          refersTo: refersTo,
        ));
      }
      return result;
    }
    return const [];
  }
}
