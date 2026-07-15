import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show somModelVersionString;

import 'meta_tree.dart';
import 'model_reader.dart';

/// Generates DocSpecs schemas (`*.docspecs-schema.yaml`) from the canonical
/// DR2 metadata tree ([MetaTreeBuilder]/[MetaNode]), applying the DR1 §5
/// generation rules (DR3).
///
/// One [DocSpecSchema] is produced per `@Document` root — the global Solution
/// Blueprint plus the twelve Phase-3 projection roots, 13 in all (S1). The
/// §5 rules, with the exact spelling fixed against the `tom_doc_specs`
/// parser as §5 delegates:
///
/// - every section-bearing node (`@SectionId`, non-root) becomes a
///   `section-types` entry **named by its section id lower-cased**
///   (`sbp01-goals`); list-element types are named by their
///   `@SectionIdPattern` stem (`daent-enti` from `DAENT-ENTI-xxx`);
/// - `prefix:` is the exact section id / pattern stem, transformed `-` → `_`
///   because the DocSpecs prefix grammar (`^[a-zA-Z0-9_]+$`) forbids the
///   dashes TomSpecs ids use (case is preserved);
/// - `pattern-check-id:` (list-element types only) is the exact
///   `@SectionIdPattern` with `xxx` compiled to `[0-9]+`
///   (`^DAENT-ENTI-[0-9]+$`) — §5 keeps the untransformed id here;
/// - `subsection-types:` lists the nearest section-bearing descendants with
///   `min-count` from the child's `@Min` and `max-count` `1` for singleton
///   children / `infinite` for list elements (bounded by `@Max`);
/// - `@Form` nodes get `format: <type-name>-form` and a `form-types` entry
///   whose fields keep the **model field names** (camelCase is legal
///   fieldname grammar), `required` from `Field.required`, `description`
///   from the field hint, and `pattern-check` from a field-level
///   `@PatternCheck`;
/// - code/diagram `@ContentType`s map to `format:` (a `format` makes the
///   validator demand a fenced code block; prose sections carry none);
/// - `text-required:` from `@TextRequired` or `@Min(1)` on a content member;
///   `min-text-length`/`max-text-length` from `@MinLength`/`@MaxLength`;
/// - `description:` from `@ContentHelp` (first) or the doc comment;
///   `validation-prompt:` from `@ValidationPrompt`;
/// - `@Unused` nodes are omitted entirely, subtree included;
/// - the `document:` structure lists the root's top-level sections with
///   `optional: true` unless the child carries `@Min` ≥ 1; the §5 title
///   format rides as the top-level custom tag `title-format:` (the
///   `tom_doc_specs` [DocumentStructure] has no such property, but custom
///   tags round-trip through [DocSpecSchema.customTags]).
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

  /// Enum registry, forwarded to the [MetaTreeBuilder].
  final Map<String, ModelEnum> enums;

  DocSpecsSchemaGenerator(this.classes, {this.enums = const {}});

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
    final rootClass = classes[rootName];
    if (rootClass == null) {
      throw ArgumentError("Unknown root class '$rootName'.");
    }
    if (rootClass.getAnnotation('Document') == null) {
      throw ArgumentError("Class '$rootName' is not a @Document root.");
    }

    final tree = MetaTreeBuilder(classes, enums: enums).build(rootName);
    final builder = _SchemaBuilder();
    final topLevel = <_ChildRef>[];
    for (final child in tree.children) {
      topLevel.addAll(builder.visit(child));
    }

    // Document structure: the root's nearest section-bearing children become
    // its top-level sections; @Min >= 1 makes a slot required (§5 rule 4).
    final sections = <String, SectionDef>{};
    for (final ref in topLevel) {
      final required = (ref.minCount ?? 0) >= 1;
      sections.putIfAbsent(
        ref.typeName,
        () => SectionDef(
          sectionType: ref.typeName,
          optional: required ? null : true,
        ),
      );
    }

    // §5 rule 4 title format: `# <!--[<ROOT-ID>]--> <name>`, carried as a
    // custom tag because DocumentStructure has no title property.
    final rootId =
        rootClass.getAnnotation('SectionId')?.arguments['id'] as String?;
    final docName = tree.document?.name ?? _splitPascal(rootName);
    final customTags = <String, dynamic>{
      if (rootId != null) 'title-format': '# <!--[$rootId]--> $docName',
    };

    return DocSpecSchema(
      id: _schemaId(rootClass),
      // Single-sourced with the `_v0` facades (CS2-D7): a genuine authoring
      // minor from `modelLabel` is preserved; unstamped falls back to
      // `<modelVersion>.0`.
      version: somModelVersionString(modelVersion, modelLabel),
      sectionTypes: builder.orderedSectionTypes(),
      formTypes: builder.formTypes.isEmpty ? null : builder.formTypes,
      document: DocumentStructure(sections: sections),
      customTags: customTags,
    );
  }

  /// Serialises a schema to YAML text for writing to `.tom/docspecs-schema/`.
  static String toYamlString(DocSpecSchema schema) {
    final header = '# Generated from the TomSpecs object model — do not edit.\n'
        '# Schema: ${schema.fullId}\n\n';
    return header + json2yaml(_escapeForJson2Yaml(schema.toYaml()));
  }

  /// Pre-escapes string scalars that `json2yaml` (3.0.1) will render as a
  /// double-quoted YAML scalar.
  ///
  /// json2yaml double-quotes a single-line scalar when it looks numeric or
  /// boolean, or contains a YAML special character (`,`, `:`​ , `[`, …), but it
  /// never escapes an embedded `"` or `\` inside that quoted scalar — so a
  /// free-text description such as `... (e.g., "orders", "payments").` is
  /// emitted as invalid YAML and fails to reload. We cannot patch the package,
  /// so we mirror its quoting predicate here and escape `\` then `"` for
  /// exactly the strings it will quote; json2yaml then wraps the already-escaped
  /// text, yielding a valid double-quoted scalar. Multi-line strings take
  /// json2yaml's block-scalar path and need no escaping, so they are left alone.
  static dynamic _escapeForJson2Yaml(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
          (k, v) => MapEntry(k as String, _escapeForJson2Yaml(v)));
    }
    if (value is Iterable) {
      return value.map(_escapeForJson2Yaml).toList();
    }
    if (value is String) {
      final isMultiline = value.trim().contains('\n');
      if (!isMultiline && _json2yamlWillQuote(value)) {
        return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
      }
    }
    return value;
  }

  /// Replicates json2yaml's generic-style `_requiresQuotes` predicate: a scalar
  /// is double-quoted when it parses as a number, equals `true`/`false`, or
  /// contains one of json2yaml's YAML special-character markers.
  static bool _json2yamlWillQuote(String s) {
    if (s.isNotEmpty && num.tryParse(s) != null) return true;
    if (s == 'true' || s == 'false') return true;
    const specials = [
      ': ', '[', ']', '{', '}', '>', '!', '*', '&', '|', '%', ' #', '`', '@',
      ',', '?',
    ];
    return specials.any(s.contains);
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

/// A child's contribution to its nearest section-bearing ancestor: the child
/// section-type name plus its cardinality (`min-count` from `@Min`,
/// `max-count` 1 for singletons / `@Max`-bounded or infinite for lists).
class _ChildRef {
  final String typeName;
  final int? minCount;

  /// null = infinite (list without `@Max`).
  final int? maxCount;

  const _ChildRef(this.typeName, {this.minCount, this.maxCount});
}

/// Walks one root's [MetaNode] tree, accumulating §5 section-types and
/// form-types with unique, DocSpecs-legal prefixes.
class _SchemaBuilder {
  /// section-type name (lower-cased section id / pattern stem) → definition.
  final Map<String, SectionTypeDef> _sectionTypes = {};

  /// form-type name → definition.
  final Map<String, FormTypeDef> formTypes = {};

  final Set<String> _usedPrefixes = {};

  /// Visits [node] and returns the section-type refs it contributes to its
  /// nearest section-bearing ancestor. `@Unused` nodes vanish entirely; nodes
  /// without a section identity bubble their descendants' refs upward.
  List<_ChildRef> visit(MetaNode node) {
    if (node.unused) return const [];

    if (node.kind == MetaNodeKind.list) return _visitList(node);

    final id = node.sectionId;
    if (id == null) {
      // No section identity: transparent container — bubble descendants up.
      final refs = <_ChildRef>[];
      for (final child in node.children) {
        refs.addAll(visit(child));
      }
      return refs;
    }

    final typeName = id.toLowerCase();
    final subsections = _collectSubsections(node.children);
    _registerSectionType(
      typeName: typeName,
      exactId: id,
      node: node,
      subsections: subsections,
    );
    return [_ChildRef(typeName, minCount: node.min, maxCount: 1)];
  }

  /// A list field: two nesting levels (DR1 §1.2, §5). The element class is the
  /// item section type, named by the `@SectionIdPattern` stem with a
  /// numbered-id pattern check (§5 rule 2); its `*-LST` container is a real
  /// section type with no content (min/max-text-length 0) wrapping the item
  /// type. The parent references the container; the container references the
  /// item.
  List<_ChildRef> _visitList(MetaNode node) {
    final pattern = node.sectionIdPattern;
    final element = node.elementNode;
    // The element's own @SectionId is a fallback when the list carries no
    // pattern (the pattern is the §8.6-preferred coverage mechanism).
    final exactId = pattern != null ? _patternStem(pattern) : element?.sectionId;
    if (exactId == null || element == null || element.unused) {
      // Scalar/enum lists (or uncovered lists) have no section representation.
      return const [];
    }

    final itemTypeName = exactId.replaceAll(RegExp(r'-+$'), '').toLowerCase();
    final subsections = _collectSubsections(element.children);
    _registerSectionType(
      typeName: itemTypeName,
      exactId: exactId,
      node: element,
      listNode: node,
      // §5: the exact @SectionIdPattern with `xxx` compiled to `[0-9]+`.
      patternCheckId: pattern == null
          ? null
          : PatternCheckDef(
              pattern: '^${_compilePattern(pattern)}\$',
              errorMessage: 'IDs of this section must match $pattern',
            ),
      subsections: subsections,
    );
    final maxItemCount = _extraInt(node, 'Max', 'count');

    // The `*-LST` container. When the list has no own @SectionId (legacy
    // uncovered list) there is no container level, so hoist the item type
    // directly under the parent (pre-DRA1 behaviour).
    final containerId = node.sectionId;
    if (containerId == null) {
      return [_ChildRef(itemTypeName, minCount: node.min, maxCount: maxItemCount)];
    }

    final containerTypeName =
        containerId.replaceAll(RegExp(r'-+$'), '').toLowerCase();
    _registerListContainerType(
      typeName: containerTypeName,
      exactId: containerId,
      node: node,
      itemTypeName: itemTypeName,
      itemMinCount: node.min,
      itemMaxCount: maxItemCount,
    );
    // The container appears once under the owner; it is required whenever the
    // list itself is required (`@Min(1)` on the list → at least one item, so
    // the container must be present).
    final containerMin = (node.min ?? 0) >= 1 ? 1 : null;
    return [_ChildRef(containerTypeName, minCount: containerMin, maxCount: 1)];
  }

  /// Registers the synthetic `*-LST` list container section type: content is
  /// forbidden (min/max-text-length 0, DR1 §1.2/§5) and its single subsection
  /// is the item type. Merges (union) if the container id recurs.
  void _registerListContainerType({
    required String typeName,
    required String exactId,
    required MetaNode node,
    required String itemTypeName,
    int? itemMinCount,
    int? itemMaxCount,
  }) {
    final existing = _sectionTypes[typeName];
    final prefix = existing?.prefix ?? _prefixFor(exactId);
    final description = node.contentHelp ??
        _firstLine(node.docComment) ??
        existing?.description;
    final merged = <String, SubsectionConstraint>{
      ...?existing?.subsectionTypes,
      itemTypeName: SubsectionConstraint(
        typeName: itemTypeName,
        minCount: itemMinCount,
        maxCount: itemMaxCount,
      ),
    };
    _sectionTypes[typeName] = SectionTypeDef(
      name: typeName,
      prefix: prefix,
      description: description,
      minTextLength: 0,
      maxTextLength: 0,
      subsectionTypes: merged,
    );
  }

  /// The subsection-types map contributed by [children] (nearest
  /// section-bearing descendants, §5 rule 2).
  Map<String, SubsectionConstraint> _collectSubsections(
    List<MetaNode> children,
  ) {
    final result = <String, SubsectionConstraint>{};
    for (final child in children) {
      for (final ref in visit(child)) {
        result.putIfAbsent(
          ref.typeName,
          () => SubsectionConstraint(
            typeName: ref.typeName,
            minCount: ref.minCount,
            maxCount: ref.maxCount,
          ),
        );
      }
    }
    return result;
  }

  /// Inserts or enriches a section-type. Shared classes surface the same id
  /// at several tree positions; slots merge first-non-null and subsections
  /// union.
  void _registerSectionType({
    required String typeName,
    required String exactId,
    required MetaNode node,
    MetaNode? listNode,
    PatternCheckDef? patternCheckId,
    Map<String, SubsectionConstraint> subsections = const {},
  }) {
    final existing = _sectionTypes[typeName];
    final prefix = existing?.prefix ?? _prefixFor(exactId);

    // format: @Form → <type-name>-form; code/diagram @ContentType → the
    // content type (a `format` makes the validator demand a fenced code
    // block, so plain text sections get none).
    String? format;
    if (node.form != null) {
      format = _registerFormType(typeName, node);
    } else {
      final contentType = node.contentType?.type;
      if (contentType != null && contentType != 'text') {
        format = contentType;
      }
    }

    // text-required: @TextRequired, or @Min(1) on a content member.
    final textRequired = _extraPresent(node, 'TextRequired') ||
            (node.kind == MetaNodeKind.content && (node.min ?? 0) >= 1)
        ? true
        : null;

    final description = node.contentHelp ??
        listNode?.contentHelp ??
        _firstLine(node.docComment) ??
        _firstLine(listNode?.docComment);

    final merged = <String, SubsectionConstraint>{
      ...?existing?.subsectionTypes,
      ...subsections,
    };

    _sectionTypes[typeName] = SectionTypeDef(
      name: typeName,
      prefix: prefix,
      description: description ?? existing?.description,
      format: format ?? existing?.format,
      textRequired: textRequired ?? existing?.textRequired,
      minTextLength:
          _extraInt(node, 'MinLength', 'length') ?? existing?.minTextLength,
      maxTextLength:
          _extraInt(node, 'MaxLength', 'length') ?? existing?.maxTextLength,
      validationPrompt: _extraString(node, 'ValidationPrompt', 'prompt') ??
          existing?.validationPrompt,
      patternCheckId: patternCheckId ?? existing?.patternCheckId,
      subsectionTypes: merged.isEmpty ? null : merged,
    );
  }

  /// Registers the `form-types` entry for a `@Form` node and returns its name
  /// (`<type-name>-form`). Fieldnames keep the model field names (§5 rule 3;
  /// camelCase satisfies the parser's `^[a-zA-Z0-9-]+$` grammar); `required`
  /// comes from `Field.required`, `description` from the field hint, and
  /// `pattern-check` from a field-level `@PatternCheck` on the backing member.
  String _registerFormType(String typeName, MetaNode node) {
    final formName = '$typeName-form';
    formTypes.putIfAbsent(formName, () {
      final byMember = {
        for (final child in node.children)
          if (child.memberName != null) child.memberName!: child,
      };
      return FormTypeDef(
        name: formName,
        fields: [
          for (final ff in node.form!.fields)
            FormFieldDef(
              fieldname: ff.name,
              required: ff.required ? true : null,
              description: ff.hint,
              patternCheck: _patternCheckFor(byMember[ff.name]),
            ),
        ],
      );
    });
    return formName;
  }

  static PatternCheckDef? _patternCheckFor(MetaNode? member) {
    if (member == null) return null;
    for (final extra in member.extra) {
      if (extra.name != 'PatternCheck') continue;
      final pattern = extra.arguments['pattern'] as String?;
      if (pattern == null) continue;
      return PatternCheckDef(
        pattern: pattern,
        errorMessage: (extra.arguments['errorMessage'] as String?) ??
            'Value must match $pattern',
      );
    }
    return null;
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

  /// The `@SectionIdPattern` stem: the pattern with its `xxx` number
  /// placeholder removed (`DAENT-ENTI-xxx` → `DAENT-ENTI-`).
  static String _patternStem(String pattern) =>
      pattern.replaceAll(RegExp(r'xxx.*$'), '');

  /// Compiles a `@SectionIdPattern` to a regex body: `xxx` → `[0-9]+`, all
  /// other characters taken literally.
  static String _compilePattern(String pattern) => pattern
      .split('xxx')
      .map(RegExp.escape)
      .join('[0-9]+');

  /// A unique, DocSpecs-legal prefix for a section id: the exact id with the
  /// TomSpecs dashes transformed to `_` (the prefix grammar `^[a-zA-Z0-9_]+$`
  /// forbids `-`); case is preserved.
  String _prefixFor(String exactId) {
    var base = exactId.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    if (base.isEmpty) base = 'SEC';
    var candidate = base;
    var n = 2;
    while (_usedPrefixes.contains(candidate)) {
      candidate = '${base}_$n';
      n++;
    }
    _usedPrefixes.add(candidate);
    return candidate;
  }

  static bool _extraPresent(MetaNode node, String name) =>
      node.extra.any((e) => e.name == name);

  static int? _extraInt(MetaNode node, String name, String arg) {
    for (final e in node.extra) {
      if (e.name == name) return e.arguments[arg] as int?;
    }
    return null;
  }

  static String? _extraString(MetaNode node, String name, String arg) {
    for (final e in node.extra) {
      if (e.name == name) return e.arguments[arg] as String?;
    }
    return null;
  }

  static String? _firstLine(String? doc) {
    if (doc == null || doc.isEmpty) return null;
    final line = doc.split('\n').first.trim();
    return line.isEmpty ? null : line;
  }
}
