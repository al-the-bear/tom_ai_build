import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show somModelVersionString;

import 'meta_tree.dart';
import 'model_reader.dart';

/// Generates DocSpecs schemas (`*.docspecs-schema.yaml`) from the canonical
/// The metadata tree ([MetaTreeBuilder]/[MetaNode]), applying the SOM §13
/// generation rules (SOM §13).
///
/// One [DocSpecSchema] is produced per `@Document` root — the global Solution
/// Blueprint plus the twelve Phase-3 projection roots and the CodeSpecs
/// generation projection, 14 in all (S1). The
/// SOM §13 rules, with the exact spelling fixed against the `tom_doc_specs`
/// parser as SOM §13 delegates:
///
/// - every section-bearing node (`@SectionId`, non-root) becomes a
///   `section-types` entry **named by its section id lower-cased**
///   (`sbp01-goals`); list-element types are named by their
///   `@SectionIdPattern` stem (`daent-enti` from `DAENT-ENTI-xxx`);
/// - `prefix:` is the exact section id / pattern stem, transformed `-` → `_`
///   because the DocSpecs prefix grammar (`^[a-zA-Z0-9_]+$`) forbids the
///   dashes TomSpecs ids use (case is preserved); a class-level `@Prefix`
///   replaces the id-derived base and is transformed and uniquified on the
///   same terms;
/// - `pattern-check-id:` (list-element types only) is the exact
///   `@SectionIdPattern` with `xxx` compiled to `.+` (`^DAENT-ENTI-.+$`) —
///   a stem check, since YRD3 renders stored item ids in md; SOM §13 keeps the
///   untransformed id here. An explicit `@PatternCheckId` is the author's own
///   rule and overrides the derived stem check;
/// - `max-subsection-levels:` from `@MaxDepth`; `allowed-tags:` from
///   `@AllowedTags`;
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
/// - `pattern-check-text:` is **never** emitted — the model constrains sections
///   structurally and only *guides* their prose, so it carries no text-body
///   regex annotation to map from (`tom_specs_model_rules.md` §9.4);
/// - `@Unused` nodes are omitted entirely, subtree included. The model only
///   ever puts the annotation on a `content` member (`tom_specs_model_rules.md`
///   §5.6), which contributes no section ref in any case — so today the rule is
///   a no-op and the containers that carry it keep their section types and
///   their subsections, which is the point of the annotation: it says no prose
///   is *expected*, not that the section is absent;
/// - the `document:` structure lists the root's top-level sections with
///   `optional: true` unless the child carries `@Min` ≥ 1; `access-key:` from
///   `@AccessKey` and `for-each:` from `@ForEach` ride there too, because
///   DocSpecs declares both on the document's section entries rather than on
///   the section type. A `@ForEach` naming a registry the root does not
///   contain is a [StateError] — a dangling registry link would validate
///   nothing;
/// - `subsection-declarations:` carries `position:` from `@Position`, one
///   block per document section. DocSpecs keys these blocks by
///   document-section name, so a position binds one level below the root;
///   deeper ordering stays declaration order;
/// - the SOM §13 title format rides as the top-level custom tag
///   `title-format:` (the `tom_doc_specs` [DocumentStructure] has no such
///   property, but custom tags round-trip through
///   [DocSpecSchema.customTags]).
///
/// Which annotation feeds which key is declared once, in
/// `docspecs_annotation_mapping.dart`, and checked from both sides: an
/// annotation `tom_specs_core` declares must name a destination, and a
/// destination named there must actually be emitted here.
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
    // its top-level sections; @Min >= 1 makes a slot required (SOM §13 rule 4).
    // `access-key` and `for-each` ride here because DocSpecs declares them on
    // the document's section entries, not on the section type.
    final sectionTypes = builder.orderedSectionTypes();
    final sections = <String, SectionDef>{};
    for (final ref in topLevel) {
      final required = (ref.minCount ?? 0) >= 1;
      final forEach = builder.forEachFor(ref.typeName);
      if (forEach != null && !sectionTypes.containsKey(forEach.sectionType)) {
        throw StateError(
          "@ForEach on section '${ref.typeName}' names registry section type "
          "'${forEach.sectionType}', which document root '$rootName' does not "
          'contain. A for-each can only bind a registry reachable from the '
          'same document.',
        );
      }
      sections.putIfAbsent(
        ref.typeName,
        () => SectionDef(
          sectionType: ref.typeName,
          accessKey: builder.accessKeyFor(ref.typeName),
          optional: required ? null : true,
          forEach: forEach,
        ),
      );
    }

    // `subsection-declarations`: one top-level block per document section that
    // has @Position-constrained children. DocSpecs keys these blocks by
    // document-section name, so a position is only expressible one level down
    // — deeper ordering stays declaration order.
    final subsectionDeclarations = <String, Map<String, SubsectionDef>>{};
    for (final sectionName in sections.keys) {
      final childConstraints = sectionTypes[sectionName]?.subsectionTypes;
      if (childConstraints == null) continue;
      final declarations = <String, SubsectionDef>{};
      for (final childType in childConstraints.keys) {
        final position = builder.positionFor(childType);
        if (position == null) continue;
        final constraint = childConstraints[childType]!;
        declarations[childType] = SubsectionDef(
          sectionType: childType,
          required: (constraint.minCount ?? 0) >= 1 ? true : null,
          position: position,
        );
      }
      if (declarations.isNotEmpty) {
        subsectionDeclarations[sectionName] = declarations;
      }
    }

    // SOM §13 rule 4 title format: `# <!--[<ROOT-ID>]--> <name>`, carried as a
    // custom tag because DocumentStructure has no title property.
    final rootId =
        rootClass.getAnnotation('SectionId')?.arguments['id'] as String?;
    // YRD4: a root-class @Headline default wins over the @Document name and
    // the PascalCase-split fallback, mirroring the md exporter's H1 title.
    final docName =
        tree.headline ?? tree.document?.name ?? _splitPascal(rootName);
    final customTags = <String, dynamic>{
      if (rootId != null) 'title-format': '# <!--[$rootId]--> $docName',
    };

    return DocSpecSchema(
      id: _schemaId(rootClass),
      // Single-sourced with the `_v0` facades (CS2-D7): a genuine authoring
      // minor from `modelLabel` is preserved; unstamped falls back to
      // `<modelVersion>.0`.
      version: somModelVersionString(modelVersion, modelLabel),
      sectionTypes: sectionTypes,
      formTypes: builder.formTypes.isEmpty ? null : builder.formTypes,
      document: DocumentStructure(sections: sections),
      subsectionDeclarations:
          subsectionDeclarations.isEmpty ? null : subsectionDeclarations,
      customTags: customTags,
    );
  }

  /// Serialises a schema to YAML text for writing to `.tom/docspecs-schema/`.
  static String toYamlString(DocSpecSchema schema) {
    final header = '# Generated from the TomSpecs object model — do not edit.\n'
        '# Schema: ${schema.fullId}\n\n';
    return header + json2yaml(_escapeForJson2Yaml(schema.toYaml()));
  }

  /// Makes every string scalar survive `json2yaml` (3.0.1) → YAML → reload.
  ///
  /// json2yaml decides on its own whether to double-quote a single-line scalar,
  /// and gets it wrong in both directions. We cannot patch the package, so we
  /// mirror its predicate here and repair each direction before handing the
  /// value over:
  ///
  /// - **It quotes but does not escape.** A scalar containing a YAML special
  ///   character (`,`, `: `, `[`, …) is wrapped in `"` with any embedded `"` or
  ///   `\` left as-is, so `... (e.g., "orders", "payments").` becomes invalid
  ///   YAML. We escape `\` then `"` first; json2yaml wraps the already-escaped
  ///   text and the result is a valid double-quoted scalar.
  /// - **It leaves plain what YAML rejects.** Its predicate keys off `': '`
  ///   (colon-*space*), so a description ending in a colon — or starting with
  ///   `#` or `- `, or carrying edge whitespace — is emitted bare and reloads as
  ///   a parse error or a silently different string. Escaping cannot help,
  ///   because json2yaml will not quote it either way, so we **pre-quote it
  ///   ourselves**. Wrapping in `"` adds no character its predicate reacts to
  ///   (that is exactly why it declined to quote), so json2yaml passes our
  ///   quoted form through verbatim.
  ///
  /// Multi-line strings take json2yaml's block-scalar path, which is safe for
  /// any content, so they are left alone.
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
      if (isMultiline) return value;
      final escaped = value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
      if (_json2yamlWillQuote(value)) return escaped;
      if (_unsafeAsPlainScalar(value)) return '"$escaped"';
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

  /// Whether [s] cannot be emitted as a bare YAML scalar — the cases
  /// [_json2yamlWillQuote] misses.
  ///
  /// Only the hazards json2yaml's own special set does not already cover are
  /// listed; anything it does cover is quoted (and escaped) on the other branch.
  static bool _unsafeAsPlainScalar(String s) {
    if (s.isEmpty) return false;
    // A trailing colon reads as a mapping key: `description: text ending in:`.
    if (s.endsWith(':')) return true;
    // Leading indicators: comment, block-sequence entry, quote styles. (`#`
    // mid-string is covered by json2yaml's ' #'; a *leading* one is not.)
    if (s.startsWith('#') || s.startsWith('- ') || s == '-') return true;
    if (s.startsWith('"') || s.startsWith("'")) return true;
    // Edge whitespace is stripped by the plain-scalar reader, so the reloaded
    // string would differ from the emitted one without a parse error to say so.
    if (s.trimLeft().length != s.length || s.trimRight().length != s.length) {
      return true;
    }
    return false;
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
  /// The `schemas/` directory is owned wholesale by the generator, so anything
  /// it does not write on this run is **pruned**. Without this, a root that gets
  /// renamed or removed leaves a stale `*.docspecs-schema.yaml` orphan behind —
  /// the per-language emitters write new files but never delete obsolete ones,
  /// so regeneration was not idempotent. Pruning keeps the committed tree a
  /// faithful image of the model.
  ///
  /// Pruning is **two-level**, because a schema can go stale two ways. A
  /// subdirectory whose name is not a current schema id is dropped whole (the
  /// root is gone). Inside a kept directory, a `*.docspecs-schema.yaml` whose
  /// name is not the one [fileNameFor] produces is dropped too — since the
  /// filename carries the schema **major** (`<id>.<major>.0.…`), a major bump
  /// renames the file rather than overwriting it, so directory-level pruning
  /// alone would leave the previous major's file frozen at the model shape it
  /// happened to have when the version moved.
  static List<String> writeSchemaTree(
    String outputRoot,
    Map<String, DocSpecSchema> schemas,
  ) {
    final schemasDir = Directory(p.join(outputRoot, 'schemas'));
    final keepFiles = <String, String>{
      for (final schema in schemas.values) schema.id: fileNameFor(schema),
    };
    if (schemasDir.existsSync()) {
      for (final entity in schemasDir.listSync()) {
        if (entity is! Directory) continue;
        final id = p.basename(entity.path);
        final keep = keepFiles[id];
        if (keep == null) {
          entity.deleteSync(recursive: true);
          continue;
        }
        for (final child in entity.listSync()) {
          if (child is File &&
              child.path.endsWith('.docspecs-schema.yaml') &&
              p.basename(child.path) != keep) {
            child.deleteSync();
          }
        }
      }
    }
    final paths = <String>[];
    for (final schema in schemas.values) {
      final file =
          File(p.join(outputRoot, 'schemas', schema.id, fileNameFor(schema)))
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

/// Walks one root's [MetaNode] tree, accumulating SOM §13 section-types and
/// form-types with unique, DocSpecs-legal prefixes.
class _SchemaBuilder {
  /// section-type name (lower-cased section id / pattern stem) → definition.
  final Map<String, SectionTypeDef> _sectionTypes = {};

  /// form-type name → definition.
  final Map<String, FormTypeDef> formTypes = {};

  final Set<String> _usedPrefixes = {};

  /// section-type name → `@AccessKey`, the key the section is reached by in
  /// the DocSpecs access API.
  final Map<String, String> _accessKeys = {};

  /// section-type name → `@ForEach(registryType, key)`, the registry the
  /// section's entries must mirror 1:1.
  final Map<String, ForEachDef> _forEach = {};

  /// section-type name → `@Position`, the ordering constraint on the section
  /// within its parent.
  final Map<String, String> _positions = {};

  /// The `@AccessKey` recorded for [typeName], if any.
  String? accessKeyFor(String typeName) => _accessKeys[typeName];

  /// The `@ForEach` recorded for [typeName], if any.
  ForEachDef? forEachFor(String typeName) => _forEach[typeName];

  /// The `@Position` recorded for [typeName], if any.
  String? positionFor(String typeName) => _positions[typeName];

  /// Captures the annotations that belong to a section's *placement* rather
  /// than to its type — they land on `document: sections:` / the
  /// `subsection-declarations` block, both of which are assembled after the
  /// whole tree has been walked.
  ///
  /// Keyed by section-type name rather than by tree position because a
  /// section type's access key, registry link and ordering are properties of
  /// the type wherever it occurs; a model that wanted two different ones for
  /// the same type would be declaring two types.
  void _recordPlacement(String typeName, MetaNode node) {
    final accessKey = _extraString(node, 'AccessKey', 'key');
    if (accessKey != null) _accessKeys[typeName] = accessKey;

    final position = _extraString(node, 'Position', 'position');
    if (position != null) _positions[typeName] = position;

    for (final extra in node.extra) {
      if (extra.name != 'ForEach') continue;
      final registryType = extra.arguments['registryType'] as String?;
      final key = extra.arguments['key'] as String?;
      if (registryType == null || key == null) continue;
      _forEach[typeName] = ForEachDef(
        // The annotation names the registry by section id (the model's own
        // vocabulary); section types are named by the lower-cased id.
        sectionType: registryType.toLowerCase(),
        key: key,
      );
    }
  }

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

  /// A list field: two nesting levels (SOM §11.2, §13). The element class is the
  /// item section type, named by the `@SectionIdPattern` stem with a
  /// numbered-id pattern check (SOM §13 rule 2); its `*-LST` container is a real
  /// section type with no content (min/max-text-length 0) wrapping the item
  /// type. The parent references the container; the container references the
  /// item.
  List<_ChildRef> _visitList(MetaNode node) {
    final pattern = node.sectionIdPattern;
    final element = node.elementNode;
    // The element's own @SectionId is a fallback when the list carries no
    // pattern (the pattern is the `tom_specs_model_rules.md` §10.2-preferred
    // coverage mechanism).
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
      // SOM §13: the exact @SectionIdPattern with `xxx` compiled to `.+` (YRD3).
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
  /// forbidden (min/max-text-length 0, SOM §11.2/§13) and its single subsection
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
    final prefix = existing?.prefix ?? _prefixFor(exactId, node: node);
    // The list field's own annotations describe the container, which is what
    // the parent (and the document structure) references.
    _recordPlacement(typeName, node);
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
  /// section-bearing descendants, SOM §13 rule 2).
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
    final prefix = existing?.prefix ?? _prefixFor(exactId, node: node);
    _recordPlacement(typeName, node);
    if (listNode != null) _recordPlacement(typeName, listNode);

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

    // An explicit @PatternCheckId is the author's own id-format rule and wins
    // over the stem check derived from @SectionIdPattern: the derived form is
    // a fallback for lists that only declare their pattern.
    final explicitPatternCheckId = _explicitPatternCheckId(node) ??
        (listNode == null ? null : _explicitPatternCheckId(listNode));

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
      maxSubsectionLevels: _extraInt(node, 'MaxDepth', 'levels') ??
          existing?.maxSubsectionLevels,
      allowedTags: _extraStringList(node, 'AllowedTags', 'tags') ??
          existing?.allowedTags,
      validationPrompt: _extraString(node, 'ValidationPrompt', 'prompt') ??
          existing?.validationPrompt,
      patternCheckId:
          explicitPatternCheckId ?? patternCheckId ?? existing?.patternCheckId,
      subsectionTypes: merged.isEmpty ? null : merged,
    );
  }

  /// The `pattern-check-id` from an explicit class-level `@PatternCheckId`.
  static PatternCheckDef? _explicitPatternCheckId(MetaNode node) {
    for (final extra in node.extra) {
      if (extra.name != 'PatternCheckId') continue;
      final pattern = extra.arguments['pattern'] as String?;
      if (pattern == null) continue;
      return PatternCheckDef(
        pattern: pattern,
        errorMessage: (extra.arguments['errorMessage'] as String?) ??
            'IDs of this section must match $pattern',
      );
    }
    return null;
  }

  /// Registers the `form-types` entry for a `@Form` node and returns its name
  /// (`<type-name>-form`). Fieldnames keep the model field names (SOM §13 rule 3;
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

  /// Compiles a `@SectionIdPattern` to a regex body: `xxx` → `.+`, all
  /// other characters taken literally.
  ///
  /// YRD3: since the md format renders **stored** item section ids (AA1
  /// date-lettered generated ids like `GOAL-ITEM-GN1`, or criterion-5
  /// overrides) in the item headings, the schema's `pattern-check-id` is a
  /// **stem** check — anonymous positional numbering and stored-id shape are
  /// the runtime's list-scoped concern, not the schema's. This mirrors the md
  /// parser's own pattern matching (`xxx` → `.+`), so every facade-authored
  /// document validates against its own schema regardless of its stored ids.
  static String _compilePattern(String pattern) => pattern
      .split('xxx')
      .map(RegExp.escape)
      .join('.+');

  /// A unique, DocSpecs-legal prefix for a section id: the exact id with the
  /// TomSpecs dashes transformed to `_` (the prefix grammar `^[a-zA-Z0-9_]+$`
  /// forbids `-`); case is preserved.
  ///
  /// A class-level `@Prefix` on [node] replaces the id-derived base — the
  /// annotation exists precisely to let a section type be resolved by a
  /// heading prefix that is not its section id. It is transformed and
  /// uniquified on the same terms, so an author cannot write a prefix the
  /// DocSpecs grammar rejects or one that shadows a sibling.
  String _prefixFor(String exactId, {MetaNode? node}) {
    final declared =
        node == null ? null : _extraString(node, 'Prefix', 'prefix');
    var base = (declared ?? exactId).replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
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

  static List<String>? _extraStringList(
    MetaNode node,
    String name,
    String arg,
  ) {
    for (final e in node.extra) {
      if (e.name != name) continue;
      final value = e.arguments[arg];
      if (value is! Iterable) continue;
      return [for (final item in value) '$item'];
    }
    return null;
  }

  static String? _firstLine(String? doc) {
    if (doc == null || doc.isEmpty) return null;
    final line = doc.split('\n').first.trim();
    return line.isEmpty ? null : line;
  }
}
