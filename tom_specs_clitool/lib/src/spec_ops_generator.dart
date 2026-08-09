import 'model_reader.dart';

/// One field reachable from the Solution Blueprint root by a static member
/// chain: its dotted [path], its own [member] name (the tie-breaker when a type
/// occurs more than once), the Dart [expr]ession that reads it from the local
/// `b`, and whether that expression can yield null.
class SbpPath {
  final String path;
  final String expr;
  final bool nullable;

  const SbpPath(this.path, this.expr, this.nullable);

  /// The last segment of [path] — the field's own member name.
  String get member => path.substring(path.lastIndexOf('.') + 1);
}

/// Emits the `spec_ops.g.dart` registry that adopts the snapshot/serialization
/// contract across every TomSpecs model class **without editing their source**
/// (OE-2).
///
/// ## Why a registry instead of a mixin
///
/// The engine ([SpecNode]/`SpecSnapshotter`/`SpecYaml` in `tom_specs_model`)
/// drives the model through a reflection-free per-class contract: child
/// relationships ([specSlots]), a shallow clone ([cloneShallow]) and a node's
/// own scalar ([yamlScalar]). Hand-written leaves adopt it by mixing in
/// `SpecNode`; the ~3000 generated model classes cannot — Dart 3.11 has no
/// augmentation support, so generated code cannot add a mixin or methods to a
/// hand-written class declaration. Instead, this generator emits one
/// `registerSpecOps()` that registers a `SpecClassOps` per concrete type,
/// closing over each class's **public fields**. The model classes stay pristine
/// (no new fields/getters), so the analyzer-based [ModelReader] that builds
/// `spec_model.json` and feeds the `tom_specs_model_rules.md` §10.2 validator
/// sees them unchanged.
///
/// ## Field classification (matches `ModelJsonExporter` kinds)
///
///  - **Child node slots** — recursed into by the snapshotter and serializer:
///    a single complex/section field → `SpecSlot.node`; a `List<Complex>` →
///    `SpecSlot.list` (narrowed back with `.cast<Element>()`). Each slot also
///    carries the child's `@SectionId` (see [_slotSectionId]), which is what
///    `SpecYaml` keys the child on — the member name is the Dart identifier,
///    the section id is the name the other eight runtimes share.
///  - **Scalars** — `String`/enum/primitive fields: copied by value in
///    `cloneShallow`; the canonical `content` scalar (or the lone scalar) is
///    returned by `yamlScalar`. Multi-scalar classes serialize only `content`
///    for now — the fuller multi-field YAML packing is not yet supported.
///
/// The two hand-written `SpecNode` leaves (`DocumentHeader`, `SectionMeta`) are
/// skipped: they adopt the contract via the mixin fast-path, which the resolver
/// checks before the registry.
///
/// ## Projection connect bindings (N11, N12)
///
/// A spec is **one document with fourteen entry points**: the
/// `D00SolutionBlueprint` master plus thirteen `@Document(basedOn:
/// [D00SolutionBlueprint])` *projection* roots that are views over the same SBP
/// sections. A projection root default-constructs its own children, so before
/// its individual file is written those references must be re-pointed onto the
/// live SBP sections. That is `SpecClassOps.connect`, and this generator emits
/// one for **every** projection root (see [_writeConnect] for the derivation
/// and [_documentLocalTypes] / [_sourceRoot] for the two decisions it encodes).
class SpecOpsGenerator {
  final Map<String, ModelClass> classes;

  /// Leaves that already mix in `SpecNode` — excluded from the registry because
  /// the resolver's `is SpecNode` fast-path serves them directly.
  static const _mixinLeaves = {'DocumentHeader', 'SectionMeta'};

  /// The Solution Blueprint master: the source of truth every projection root
  /// binds against (`tom_specs_editor_specification.md` §14).
  static const _sourceRoot = 'D00SolutionBlueprint';

  /// Child types that stay **document-local** and are therefore never bound to
  /// an SBP section.
  ///
  /// `DocumentHeader` is document *front matter* — id, project, version, date,
  /// author, status. Each of the fourteen entry points is a document in its own
  /// right with its own identity, so a projection's header must not be
  /// re-pointed at the SBP's. It resolves structurally (there is exactly one
  /// `DocumentHeader` under the SBP, at `documentControl.header`), which is why
  /// the exclusion has to be stated rather than derived.
  static const _documentLocalTypes = {'DocumentHeader'};

  /// Section content leaves defined in `tom_specs_core` (outside the scanned
  /// model package). Each is a `String? content` leaf; registered by hand here
  /// so trees that embed them snapshot/serialize without a missing-ops error.
  static const _sectionLeafTypes = [
    'TextSection',
    'DiagramSection',
    'ErDiagramSection',
    'FlowDiagramSection',
    'GanttDiagramSection',
    'SequenceDiagramSection',
    'CodeSection',
    'DartCodeSection',
    'SqlCodeSection',
    'DdlCodeSection',
  ];

  SpecOpsGenerator(this.classes);

  String generate() {
    final buffer = StringBuffer();
    _writeHeader(buffer);

    final names = classes.keys.where((n) => !_mixinLeaves.contains(n)).toList()
      ..sort();

    buffer.writeln('  // --- Section content leaves (tom_specs_core) ---');
    // YRD5: the universal section base type itself is a content leaf — model
    // members typed `DocSpecsSection?` / `List<DocSpecsSection>` hold plain
    // instances of it unless a subclass was assigned.
    _writeContentLeaf(buffer, 'DocSpecsSection');
    for (final type in _sectionLeafTypes) {
      _writeContentLeaf(buffer, type);
    }
    buffer.writeln();
    buffer.writeln('  // --- Model classes (tom_specs_model) ---');
    for (final name in names) {
      _writeClassOps(buffer, classes[name]!);
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeHeader(StringBuffer b) {
    b.writeln('// GENERATED by tom_specs_clitool/bin/spec_ops.dart — '
        'do not edit by hand.');
    b.writeln('//');
    b.writeln('// Registers the snapshot/serialization contract '
        '(SpecClassOps) for every');
    b.writeln('// TomSpecs model class + section leaf, so the reflection-free '
        'engine can');
    b.writeln('// snapshot, clone and serialize the model without dart:mirrors '
        '(OE-2).');
    b.writeln('//');
    b.writeln('// ignore_for_file: type=lint, '
        'unnecessary_cast, prefer_const_constructors');
    b.writeln();
    b.writeln("import 'package:tom_specs_core/tom_specs_core.dart';");
    b.writeln("import 'package:tom_specs_model/tom_specs_model.dart';");
    b.writeln();
    b.writeln('bool _registered = false;');
    b.writeln();
    b.writeln('/// Registers [SpecClassOps] for every model class and section '
        'leaf.');
    b.writeln('/// Idempotent — safe to call more than once.');
    b.writeln('void registerSpecOps() {');
    b.writeln('  if (_registered) return;');
    b.writeln('  _registered = true;');
    b.writeln();
  }

  void _writeContentLeaf(StringBuffer b, String type) {
    // YRD5: section leaves extend DocSpecsSection, so the shallow clone copies
    // the full stored state — headline, id, content, the parsed form and the
    // csmb1 codeSpec forward link.
    b.writeln('  SpecRegistry.register($type, SpecClassOps(');
    b.writeln('    slots: (o) => const [],');
    b.writeln('    cloneShallow: (o) {');
    b.writeln('      final n = o as $type;');
    b.writeln('      return $type()');
    b.writeln('        ..headline = n.headline');
    b.writeln('        ..id = n.id');
    b.writeln('        ..content = n.content');
    b.writeln('        ..codeSpec = n.codeSpec');
    b.writeln('        ..form = n.form;');
    b.writeln('    },');
    b.writeln('    yamlScalar: (o) => (o as $type).content,');
    b.writeln('  ));');
  }

  void _writeClassOps(StringBuffer b, ModelClass cls) {
    final name = cls.name;
    final childNodes = cls.fields.where(_isChildNode).toList();
    final scalar = _yamlScalarField(cls);

    b.writeln('  SpecRegistry.register($name, SpecClassOps(');

    // slots
    if (childNodes.isEmpty) {
      b.writeln('    slots: (o) => const [],');
    } else {
      b.writeln('    slots: (o) {');
      b.writeln('      final n = o as $name;');
      b.writeln('      return [');
      for (final f in childNodes) {
        b.writeln('        ${_slotExpr(f)}');
      }
      b.writeln('      ];');
      b.writeln('    },');
    }

    // cloneShallow — copy every field (scalars by value, child refs shared).
    if (cls.fields.isEmpty) {
      b.writeln('    cloneShallow: (o) => $name(),');
    } else {
      b.writeln('    cloneShallow: (o) {');
      b.writeln('      final n = o as $name;');
      b.writeln('      return $name()');
      for (var i = 0; i < cls.fields.length; i++) {
        final f = cls.fields[i];
        final tail = i == cls.fields.length - 1 ? ';' : '';
        b.writeln('        ..${f.name} = n.${f.name}$tail');
      }
      b.writeln('    },');
    }

    // yamlScalar
    if (scalar != null) {
      b.writeln('    yamlScalar: (o) => (o as $name).$scalar,');
    }

    // connect — projection roots only.
    _writeConnect(b, cls);

    b.writeln('  ));');
  }

  // --- Projection connect bindings (N11, N12) -------------------------------

  /// Emits `connect:` when [cls] is a projection root, binding each of its
  /// children onto the Solution Blueprint section it projects.
  ///
  /// **Every** projection root gets a binding, `D13CodeSpecsProjection`
  /// included: it is a `@Document(basedOn: [D00SolutionBlueprint])` view over
  /// SBP sections exactly like the twelve Phase-3 roots, and its
  /// `@CodeSpecsProjection()` marker only exempts it from the validator's
  /// detail-count check — it says nothing about how the root is serialized.
  /// Every one of its children resolves to a unique SBP path, so exempting it
  /// would leave the Phase-4 generation input serializing unresolved
  /// default-constructed sections.
  void _writeConnect(StringBuffer b, ModelClass cls) {
    if (!_isProjectionRoot(cls)) return;
    final bindings = bindingsFor(cls);
    if (bindings.isEmpty) return;

    b.writeln('    connect: (o, s) {');
    b.writeln('      final n = o as ${cls.name};');
    b.writeln('      final b = s as $_sourceRoot;');
    var guard = 0;
    for (final entry in bindings.entries) {
      final field = entry.key;
      final path = entry.value;
      if (path.nullable && !field.isNullable) {
        // The projection slot cannot hold null, so a null SBP section leaves
        // the default-constructed instance in place (it serializes empty).
        final tmp = 'v${guard++}';
        b.writeln('      final $tmp = ${path.expr};');
        b.writeln('      if ($tmp != null) n.${field.name} = $tmp;');
      } else {
        b.writeln('      n.${field.name} = ${path.expr};');
      }
    }
    b.writeln('    },');
  }

  bool _isProjectionRoot(ModelClass cls) {
    if (cls.name == _sourceRoot) return false;
    final basedOn = cls.getAnnotation('Document')?.arguments['basedOn'];
    return basedOn is List && basedOn.contains(_sourceRoot);
  }

  /// The projection roots, sorted by name — the thirteen
  /// `@Document(basedOn: [D00SolutionBlueprint])` views over the master.
  List<ModelClass> projectionRoots() =>
      classes.values.where(_isProjectionRoot).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// The child fields of projection root [cls] that a connect binding must
  /// cover: its child nodes minus the [_documentLocalTypes].
  List<ModelField> bindableFields(ModelClass cls) => cls.fields
      .where(_isChildNode)
      .where((f) => !_documentLocalTypes.contains(_baseType(f)))
      .toList();

  /// Resolves each bindable field of projection root [cls] to the Solution
  /// Blueprint path it projects, by **type first, then member name**.
  ///
  /// Type identity carries most of the work: a section class is declared once
  /// and appears in exactly one place in the master, so a projection child of
  /// type `T` binds to the single SBP field of type `T`. That resolves without
  /// depending on the `@MapsTo` / `@DetailedIn` seed/promotion pair being kept
  /// in step with the roots by hand.
  ///
  /// Type alone is not always enough, for two different reasons, and the member
  /// name settles both:
  ///
  ///  - The shared **content-leaf section types** from `tom_specs_core`
  ///    (`DiagramSection` and its siblings) are not per-section classes — the
  ///    SBP holds fourteen `DiagramSection`s. A projection carries the section
  ///    over under the same member name, so
  ///    `D03InformationModel.objectDiagram` binds to the one SBP
  ///    `DiagramSection` also called `objectDiagram`.
  ///  - A **flattened** projection can pull in a class that also appears nested
  ///    under one of its own siblings. `D10QualityAcceptancePlan` holds both an
  ///    `acceptanceCriteriaSummary` and the flattened `acceptanceCriteria`, and
  ///    the summary contains an `AcceptanceCriteriaList` of its own; the name
  ///    picks the flattened acceptance-plan list rather than the nested detail.
  ///
  /// A field left unresolved is omitted from the emitted binding — and caught
  /// by the coverage test rather than shipped as a silent gap.
  Map<ModelField, SbpPath> bindingsFor(ModelClass cls) {
    final resolved = <ModelField, SbpPath>{};
    for (final f in bindableFields(cls)) {
      final candidates = _sbpPaths[_typeKey(f)] ?? const <SbpPath>[];
      final match = candidates.length == 1
          ? candidates.single
          : _singleWhereMember(candidates, f.name);
      if (match != null) resolved[f] = match;
    }
    // Emit in declaration order so the generated binding reads like the root.
    return {
      for (final f in bindableFields(cls))
        if (resolved.containsKey(f)) f: resolved[f]!,
    };
  }

  /// The one candidate whose own member name is [member], or `null` when none
  /// or several are.
  SbpPath? _singleWhereMember(List<SbpPath> candidates, String member) {
    final named = [
      for (final c in candidates)
        if (c.member == member) c,
    ];
    return named.length == 1 ? named.single : null;
  }

  /// Every field reachable from [_sourceRoot] by a **static** member chain,
  /// indexed by type key. List fields are indexed but not descended into —
  /// there is no stable field path through a list element.
  late final Map<String, List<SbpPath>> _sbpPaths = _indexSbpPaths();

  Map<String, List<SbpPath>> _indexSbpPaths() {
    final index = <String, List<SbpPath>>{};

    void walk(
      ModelClass cls,
      String path,
      String expr,
      bool nullable,
      Set<String> seen,
    ) {
      for (final f in cls.fields.where(_isChildNode)) {
        final childPath = path.isEmpty ? f.name : '$path.${f.name}';
        final childExpr = '$expr${nullable ? '?' : ''}.${f.name}';
        final childNullable = nullable || f.isNullable;
        index
            .putIfAbsent(_typeKey(f), () => [])
            .add(SbpPath(childPath, childExpr, childNullable));
        if (f.isList) continue;
        final target = _baseType(f);
        final targetClass = classes[target];
        if (targetClass == null || seen.contains(target)) continue;
        walk(targetClass, childPath, childExpr, childNullable, {
          ...seen,
          target,
        });
      }
    }

    final root = classes[_sourceRoot];
    if (root != null) walk(root, '', 'b', false, {_sourceRoot});
    return index;
  }

  /// The key a field is matched on: its element type for a list, else its own
  /// type with the nullable suffix stripped.
  String _typeKey(ModelField f) =>
      f.isList ? 'List<${f.listElementTypeName}>' : _baseType(f);

  String _baseType(ModelField f) => f.typeName.replaceAll('?', '');

  String _slotExpr(ModelField f) {
    final id = _slotSectionId(f);
    final idArg = id == null ? '' : ", sectionId: '$id'";
    if (f.isList && (f.listElementIsComplex || f.listElementIsContentSection)) {
      final elem = f.listElementTypeName;
      return 'SpecSlot.list(() => n.${f.name}, '
          "(v) => n.${f.name} = v.cast<$elem>(), label: '${f.name}'$idArg),";
    }
    final base = f.typeName.replaceAll('?', '');
    final cast = f.isNullable ? '$base?' : base;
    return 'SpecSlot.node(() => n.${f.name}, '
        "(v) => n.${f.name} = v as $cast, label: '${f.name}'$idArg),";
  }

  /// The effective section id of [f]'s child, which `SpecYaml` keys the child
  /// on (SOM §12.2): the member's own `@SectionId`, else — for a **single**
  /// section/complex child only — the target class's `@SectionId`.
  ///
  /// The class fallback is the load-bearing path: most complex members declare
  /// no id of their own and are named by the id of the class they hold (a
  /// transparent section keys on its class id while pathing on its member
  /// name). A list keeps only its member-level id — its `@SectionId('…-LST')`
  /// names the list, and its elements are named by the paired
  /// `@SectionIdPattern`, so falling back to the element class's id would key
  /// the list under its element's name.
  String? _slotSectionId(ModelField f) {
    final own = f.getAnnotation('SectionId')?.arguments['id'] as String?;
    if (own != null || f.isList) return own;
    final target = f.typeName.replaceAll('?', '');
    return classes[target]?.getAnnotation('SectionId')?.arguments['id']
        as String?;
  }

  bool _isChildNode(ModelField f) {
    // YRD5: `DocSpecsSection` members are child nodes of the object tree (the
    // engine recurses into them), even though the *meta* tree renders them as
    // content leaves.
    if (f.isList) return f.listElementIsComplex || f.listElementIsContentSection;
    return f.isSectionType || f.isComplex || f.isContentSection;
  }

  /// The String field used for [yamlScalar]: the canonical `content`, or the
  /// lone String scalar when the class has exactly one. Multi-scalar classes
  /// without a `content` field return `null` (deferred fuller packing).
  String? _yamlScalarField(ModelClass cls) {
    final strings =
        cls.fields.where((f) => f.isString && !_isChildNode(f)).toList();
    if (strings.isEmpty) return null;
    final content = strings.where((f) => f.name == 'content').toList();
    if (content.isNotEmpty) return 'content';
    if (strings.length == 1) return strings.single.name;
    return null;
  }
}
