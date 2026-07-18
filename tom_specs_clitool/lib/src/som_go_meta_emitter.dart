/// Emits the generated **metadata module** of the Go `v0` facade (DR21, the Go
/// counterpart of `som_typescript_meta_emitter.dart` /
/// `som_javascript_meta_emitter.dart` / `som_python_meta_emitter.dart` /
/// `som_dart_meta_emitter.dart`): the populated `SomMetaTree`s as generated
/// static data structures in code (DR1 §3.2) plus the two discoverable access
/// surfaces of DR1 §4 — the **dot-notation tree** (model member names, §4.1)
/// and the **ID-tree** (section ids, §4.2). This module replaces the retired
/// flat path-constant holders (`SbpPaths.…`) in the Go facade.
///
/// The emitted node values mirror `tom_som_go_runtime`'s `BuildSomMetaTree`
/// (the meta-JSON bridge) **field for field**, sourced from the same
/// [SpecModel], so the generated trees and the bridge-built trees are
/// structurally identical — the facade test suite asserts this exhaustively
/// with `som.SomMetaNodeDiff`. Cycle handling matches the bridge: a class
/// already on the descent stack becomes a terminal re-entry node
/// (`Recursive: true`), which the generated `metaCx` helper reproduces at
/// tree-construction time.
///
/// Go divergences from the TypeScript blueprint (all naming — the emitted
/// values and path strings are byte-identical):
///
///   * `$` is not a legal Go identifier character and the meta module shares
///     the facade's **flat package namespace**, so the accessor types are
///     `<Class>Nav` / `<Class>ID` (with **unexported** `new<Class>Nav` /
///     `new<Class>ID` constructors — internal wiring; consumers reach the
///     surfaces through the entry-point vars, and the exported struct types
///     stay literal-constructible) instead of `<Class>$Nav` / `<Class>$Id`;
///     the builders are `metaChildren<Class>` instead of `_mc_<Class>`; the
///     cycle helper is `metaCx`. Unexported constructors keep an idiomatic
///     `New<X>` facade constructor (e.g. the real model's
///     `NewOrganizationStructure` class) from colliding with a Nav
///     constructor; a generation-time guard still fails loudly when any
///     remaining meta identifier collides with a facade-owned identifier
///     derived from the same model.
///   * exported = uppercase, so dot-notation getters are the **Pascal-cased**
///     member names (the facade accessor convention, DR1d); ID-tree getters
///     keep the section id verbatim (`-` → `_` — the model's ids are
///     uppercase, hence exported). A digit-leading id would gain an `ID`
///     prefix (the Go analogue of the TS `$` prefix; a generation-time safety
///     net — the model carries none).
///   * package-level `var` initialization is dependency-ordered in Go, and
///     `NewSomMetaTree` returns an error, so the per-root trees are built
///     through a generated `mustMetaTree` panic-on-error wrapper (the
///     generated data is correct by construction; a panic marks an emitter
///     bug, not a runtime condition).
///   * optional ints (`SerializationOrder` / `Min`) are `*int` in the runtime,
///     populated through a generated `metaIntPtr` helper.
///
/// The generated source is **gofmt-stable by construction**: node values are
/// single-line composite literals (gofmt aligns multi-line key/value cells,
/// which a string emitter cannot reproduce), function literals are always
/// multi-line, and `+` concatenations follow gofmt's depth-based spacing
/// (spaced inside composite-literal values, unspaced inside call arguments).
///
/// Per document root the module tail declares `<RootType>MetaTree` (the wired
/// tree), the dot-notation entry `<RootType>Meta`, and the ID-tree entry
/// `<ROOT-SEGMENT>` (`SBP`, `CLA`, …). Element accessors of lists are wired as
/// **factory functions** `func(t, p) ref` (the runtime's generic
/// `SomMetaRefFactory[T]`).
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Annotation names with a dedicated `SomMetaNode` slot — everything else is
/// captured into `Extra`. Must stay identical to the bridge's set.
const Set<String> _slottedAnnotations = {
  'SectionId',
  'SectionIdPattern',
  'SerializationOrder',
  'Min',
  'Unused',
  'ContentType',
  'ContentHelp',
  'Headline',
  'Comment',
  'Form',
  'Document',
  'MapsTo',
  'DetailedIn',
  'SecondLevelSectionId',
};

/// Accessor method names a generated Nav/ID struct must never emit: the
/// promoted members of the embedded runtime `SomMetaRef` (`Tree` / `Path`
/// fields, the `Meta()` method), `Item` (the list accessor, reserved
/// uniformly like the TS port), and `SomMetaRef` itself (a method may not
/// share the embedded field's name). Collisions fail generation loudly.
const Set<String> _reservedAccessorNames = {
  'Tree',
  'Path',
  'Meta',
  'Item',
  'SomMetaRef',
};

/// Emits the Go source of the generated metadata module (see the library doc
/// above) for [model].
class SomGoMetaEmitter {
  /// The domain-qualified module path of the generic runtime — must match the
  /// facade emitter's import so both files share the one `som` package.
  static const String _runtimeModulePath =
      'github.com/al-the-bear/tom_ai_build/tom_som_go_runtime';

  final SpecModel model;
  final String versionLabel;
  final List<String> documentRoots;

  /// The Go package name — must equal the facade's package clause, the two
  /// generated files form one package.
  final String packageName;

  SomGoMetaEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
    this.packageName = 'somv0',
  });

  List<SpecRoot> get _roots {
    if (documentRoots.isEmpty) return model.roots;
    final wanted = documentRoots.toSet();
    return model.roots.where((r) => wanted.contains(r.type)).toList();
  }

  /// The complete generated metadata module source.
  String generateLibrary() {
    final classNames = model.classes.keys.toList()..sort();
    final idClasses = _idReachableClasses();
    _guardPackageCollisions(classNames, idClasses);

    final b = StringBuffer()
      ..writeln('// GENERATED by tom_specs_clitool SomGoMetaEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('//')
      ..writeln('// The populated SOM metadata trees (DR1 §3.2) and the two')
      ..writeln('// generated access surfaces of DR1 §4: the dot-notation '
          'tree')
      ..writeln('// (model member names) and the ID-tree (section ids). Both')
      ..writeln('// resolve to the same SomMetaNode and byte-identical path')
      ..writeln('// strings; the flat path-constant holders are retired.')
      ..writeln('package $packageName')
      ..writeln()
      ..writeln('import som "$_runtimeModulePath"')
      ..writeln();

    _emitHelpers(b);

    // ── metadata children builders ─────────────────────────────────────────
    b
      ..writeln('// ── metadata tree builders (DR1 §3.2) '
          '─────────────────────────────────────')
      ..writeln();
    for (final name in classNames) {
      _emitMetaChildrenBuilder(b, model.classes[name]!);
    }

    // ── dot-notation accessor structs ──────────────────────────────────────
    b
      ..writeln('// ── dot-notation accessor structs (DR1 §4.1) '
          '──────────────────────────────')
      ..writeln();
    for (final name in classNames) {
      _emitNavStruct(b, model.classes[name]!);
    }

    // ── ID-tree accessor structs ───────────────────────────────────────────
    b
      ..writeln('// ── ID-tree accessor structs (DR1 §4.2) '
          '───────────────────────────────────')
      ..writeln();
    for (final name in idClasses) {
      _emitIdStruct(b, model.classes[name]!);
    }

    // ── per-root trees + access-surface entry points ───────────────────────
    b
      ..writeln('// ── document-root metadata trees + access surface roots '
          '───────────────────')
      ..writeln();
    for (final root in _roots) {
      _emitRoot(b, root);
    }

    return '${b.toString().trimRight()}\n';
  }

  // ── generation-time collision guard ────────────────────────────────────────

  /// Fails generation loudly when a meta-module package identifier collides
  /// with a facade-owned identifier (both derive deterministically from the
  /// same model, and the two generated files share one flat Go package
  /// namespace). The TS port is collision-free via `$`; Go has no such
  /// character, so this guard is the safety net (the model is verified clean).
  void _guardPackageCollisions(
      List<String> classNames, List<String> idClasses) {
    final facade = <String>{'Version'};
    for (final name in classNames) {
      facade
        ..add(name)
        ..add('New$name');
      final cls = model.classes[name]!;
      for (final f in cls.fields) {
        if (f.kind == SpecFieldKind.form) {
          final form = '$name${_pascal(f.name)}Form';
          facade
            ..add(form)
            ..add('New$form');
        }
        if (f.kind == SpecFieldKind.enumValue && f.enumType != null) {
          facade.add('parse${f.enumType!}');
          for (final v in f.enumValues) {
            facade.add('${f.enumType!}${_pascal(v)}');
          }
        }
      }
    }
    for (final root in _roots) {
      facade
        ..add('${root.type}ModelVersion')
        ..add('LoadYaml${root.type}')
        ..add('LoadFile${root.type}');
    }

    final meta = <String>{'metaCx', 'metaIntPtr', 'mustMetaTree'};
    for (final name in classNames) {
      meta
        ..add('metaChildren$name')
        ..add('${name}Nav')
        ..add('new${name}Nav');
    }
    for (final name in idClasses) {
      meta
        ..add('${name}ID')
        ..add('new${name}ID');
    }
    for (final root in _roots) {
      meta
        ..add('${root.type}MetaTree')
        ..add('${root.type}Meta')
        ..add(_idName(_rootSegment(root)));
    }

    final clash = meta.intersection(facade).toList()..sort();
    if (clash.isNotEmpty) {
      throw StateError('generated meta-module identifiers collide with '
          'facade identifiers in package $packageName: ${clash.join(', ')}');
    }
    if (meta.length !=
        3 +
            classNames.length * 3 +
            idClasses.length * 2 +
            _roots.length * 3) {
      throw StateError(
          'generated meta-module identifiers collide with each other');
    }
  }

  // ── shared helpers ─────────────────────────────────────────────────────────

  void _emitHelpers(StringBuffer b) {
    b
      ..writeln('// metaCx builds a complex/section (or list-element) node '
          "with the bridge's")
      ..writeln('// cycle rule: a class already on the descent stack becomes '
          'a terminal')
      ..writeln('// re-entry node (Recursive: true, no children).')
      ..writeln('func metaCx(cls string, stack map[string]bool, kids '
          'func(map[string]bool) []*som.SomMetaNode, build func(bool, '
          '[]*som.SomMetaNode) *som.SomMetaNode) *som.SomMetaNode {')
      ..writeln('\tif stack[cls] {')
      ..writeln('\t\treturn build(true, nil)')
      ..writeln('\t}')
      ..writeln('\tstack[cls] = true')
      ..writeln('\tc := kids(stack)')
      ..writeln('\tdelete(stack, cls)')
      ..writeln('\treturn build(false, c)')
      ..writeln('}')
      ..writeln()
      ..writeln('// metaIntPtr widens an optional-int literal into the '
          "runtime's *int slots")
      ..writeln('// (SerializationOrder, Min).')
      ..writeln('func metaIntPtr(v int) *int {')
      ..writeln('\treturn &v')
      ..writeln('}')
      ..writeln()
      ..writeln('// mustMetaTree wires a generated root node into its '
          'SomMetaTree. The generated')
      ..writeln('// data is correct by construction, so a wiring error marks '
          'an emitter bug and')
      ..writeln('// panics instead of surfacing as a runtime condition.')
      ..writeln('func mustMetaTree(root *som.SomMetaNode) *som.SomMetaTree {')
      ..writeln('\tt, err := som.NewSomMetaTree(root)')
      ..writeln('\tif err != nil {')
      ..writeln('\t\tpanic(err)')
      ..writeln('\t}')
      ..writeln('\treturn t')
      ..writeln('}')
      ..writeln();
  }

  /// The fields of [cls] in emission order: `@SerializationOrder` ascending,
  /// declaration index as tiebreaker/fallback — identical to the bridge.
  List<SpecField> _orderedFields(SpecClass cls) {
    final indexed = cls.fields.asMap().entries.toList()
      ..sort((a, b) {
        const fallback = 1 << 30;
        final oa = a.value.serializationOrder ?? fallback;
        final ob = b.value.serializationOrder ?? fallback;
        return oa != ob ? oa.compareTo(ob) : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  String _fieldSegment(SpecField f) => f.sectionId ?? f.name;

  String _rootSegment(SpecRoot root) => root.sectionId ?? root.type;

  /// The Go `SomMetaKind*` constant for a [SpecFieldKind].
  String _kindConst(SpecFieldKind kind) {
    switch (kind) {
      case SpecFieldKind.list:
        return 'som.SomMetaKindList';
      case SpecFieldKind.form:
        return 'som.SomMetaKindForm';
      case SpecFieldKind.section:
        return 'som.SomMetaKindSection';
      case SpecFieldKind.content:
        return 'som.SomMetaKindContent';
      case SpecFieldKind.enumValue:
        return 'som.SomMetaKindEnumValue';
      case SpecFieldKind.complex:
        return 'som.SomMetaKindComplex';
      case SpecFieldKind.scalar:
        return 'som.SomMetaKindScalar';
    }
  }

  /// A Go double-quoted string literal for [s] (full control-character
  /// escaping — doc comments and descriptions carry newlines).
  String _str(String s) => '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r').replaceAll('\t', '\\t')}"';

  /// A Go literal for a JSON-shaped annotation-argument [value], typed as the
  /// runtime's `interface{}` argument shapes.
  String _lit(Object? value) {
    if (value == null) return 'nil';
    if (value is String) return _str(value);
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return '$value';
    if (value is List) {
      return '[]interface{}{${value.map(_lit).join(', ')}}';
    }
    if (value is Map) {
      final entries = value.entries
          .map((e) => '${_str('${e.key}')}: ${_lit(e.value)}')
          .join(', ');
      return 'map[string]interface{}{$entries}';
    }
    throw StateError('unsupported annotation argument literal: '
        '${value.runtimeType} ($value)');
  }

  String _pascal(String s) {
    final parts = s.split(RegExp(r'[_\s]+')).where((p) => p.isNotEmpty);
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  // ── metadata builders ──────────────────────────────────────────────────────

  void _emitMetaChildrenBuilder(StringBuffer b, SpecClass cls) {
    b
      ..writeln('func metaChildren${cls.name}(s map[string]bool) '
          '[]*som.SomMetaNode {')
      ..writeln('\treturn []*som.SomMetaNode{');
    for (final f in _orderedFields(cls)) {
      _emitFieldNode(b, cls, f);
    }
    b
      ..writeln('\t}')
      ..writeln('}')
      ..writeln();
  }

  /// Writes the element expression building the `SomMetaNode` for field [f]
  /// of [owner] — value-for-value the bridge's `bridgeFieldNode`.
  void _emitFieldNode(StringBuffer b, SpecClass owner, SpecField f) {
    final isComplexLike =
        f.kind == SpecFieldKind.complex || f.kind == SpecFieldKind.section;
    final target = isComplexLike ? model.classNamed(f.type ?? '') : null;

    final args = <String>[];
    void add(String name, String? expr) {
      if (expr != null) args.add('$name: $expr');
    }

    add('ClassName', _str(target?.name ?? owner.name));
    add('MemberName', _str(f.name));
    if (f.sectionId != null) add('SectionID', _str(f.sectionId!));
    if (target?.sectionId != null) {
      add('ClassSectionID', _str(target!.sectionId!));
    }
    if (f.sectionIdPattern != null) {
      add('SectionIDPattern', _str(f.sectionIdPattern!));
    }
    add('Kind', _kindConst(f.kind));
    add('TypeName', _str(f.type ?? f.elementType ?? f.enumType ?? 'String'));
    if (f.serializationOrder != null) {
      add('SerializationOrder', 'metaIntPtr(${f.serializationOrder})');
    }
    if (f.min != null) add('Min', 'metaIntPtr(${f.min})');
    if (f.annotation('Unused') != null) add('Unused', 'true');
    if (f.contentType != null) {
      final desc =
          '${f.annotation('ContentType')?.argument('description') ?? ''}';
      add(
          'ContentType',
          '&som.SomContentTypeMeta{Type: ${_str(f.contentType!)}, '
              'Description: ${_str(desc)}}');
    }
    if (f.help != null) add('ContentHelp', _str(f.help!));
    final headline = f.headline ?? target?.headline;
    if (headline != null) add('Headline', _str(headline));
    final comment = '${f.annotation('Comment')?.argument('text') ?? ''}';
    if (comment.isNotEmpty) add('Comment', _str(comment));
    final docComment = f.doc ?? target?.doc;
    if (docComment != null) add('DocComment', _str(docComment));
    if (target?.doc != null) add('ClassDocComment', _str(target!.doc!));
    if (f.kind == SpecFieldKind.form) {
      final fields = <String>[];
      for (var i = 0; i < f.formFields.length; i++) {
        final ff = f.formFields[i];
        final ffArgs = <String>[
          'Name: ${_str(ff.name)}',
          'TypeName: ${_str(ff.type)}',
          'Description: ${_str(ff.label)}',
          if (ff.required) 'Required: true',
          if (ff.hint != null) 'Hint: ${_str(ff.hint!)}',
          'Order: $i',
          if (ff.enumValues.isNotEmpty)
            'EnumValues: []string{${ff.enumValues.map(_str).join(', ')}}',
        ];
        fields.add('{${ffArgs.join(', ')}}');
      }
      add(
          'Form',
          '&som.SomFormMeta{Fields: []*som.SomFormFieldMeta{'
              '${fields.join(', ')}}}');
    }
    if (target?.mapsTo != null) add('MapsTo', _str(target!.mapsTo!));
    if (target?.detailedIn != null) {
      add('DetailedIn', _str(target!.detailedIn!));
    }
    final secondLevel = _secondLevelIdsExpr(f.annotations);
    if (secondLevel != null) add('SecondLevelIds', secondLevel);
    final extra = _extrasExpr(f.annotations);
    if (extra != null) add('Extra', extra);

    if (target != null) {
      // Complex/section: Recursive/Children resolved by the cycle helper.
      b
        ..writeln('\t\tmetaCx(${_str(target.name)}, s, '
            'metaChildren${target.name}, func(r bool, c []*som.SomMetaNode) '
            '*som.SomMetaNode {')
        ..writeln('\t\t\treturn &som.SomMetaNode{${args.join(', ')}, '
            'Recursive: r, Children: c}')
        ..writeln('\t\t}),');
      return;
    }

    // Element subtree of a complex-element list: assigned in a generated
    // closure so the element's multi-line cycle-helper call never sits inside
    // a keyed composite literal (gofmt stability, see the library doc).
    final element = f.kind == SpecFieldKind.list && f.elementIsComplex
        ? model.classNamed(f.elementType ?? '')
        : null;
    if (element != null) {
      final elemArgs = <String>[
        'ClassName: ${_str(element.name)}',
        if (element.sectionId != null)
          'ClassSectionID: ${_str(element.sectionId!)}',
        'Kind: som.SomMetaKindComplex',
        'TypeName: ${_str(element.name)}',
        if (element.headline != null)
          'Headline: ${_str(element.headline!)}',
        if (element.doc != null) 'DocComment: ${_str(element.doc!)}',
        if (element.doc != null) 'ClassDocComment: ${_str(element.doc!)}',
        if (element.mapsTo != null) 'MapsTo: ${_str(element.mapsTo!)}',
        if (element.detailedIn != null)
          'DetailedIn: ${_str(element.detailedIn!)}',
        'Recursive: r',
        'Children: c',
      ];
      b
        ..writeln('\t\tfunc() *som.SomMetaNode {')
        ..writeln('\t\t\tn := &som.SomMetaNode{${args.join(', ')}}')
        ..writeln('\t\t\tn.ElementNode = metaCx(${_str(element.name)}, s, '
            'metaChildren${element.name}, func(r bool, c []*som.SomMetaNode) '
            '*som.SomMetaNode {')
        ..writeln('\t\t\t\treturn &som.SomMetaNode{${elemArgs.join(', ')}}')
        ..writeln('\t\t\t})')
        ..writeln('\t\t\treturn n')
        ..writeln('\t\t}(),');
      return;
    }

    b.writeln('\t\t{${args.join(', ')}},');
  }

  String? _secondLevelIdsExpr(List<SpecAnnotation> annotations) {
    final entries = [
      for (final a in annotations)
        if (a.name == 'SecondLevelSectionId')
          '{DocumentClass: '
              "${_str('${a.argument('documentClass') ?? ''}')}, "
              "ID: ${_str('${a.argument('id') ?? ''}')}}",
    ];
    return entries.isEmpty
        ? null
        : '[]*som.SomSecondLevelId{${entries.join(', ')}}';
  }

  String? _extrasExpr(List<SpecAnnotation> annotations) {
    final entries = [
      for (final a in annotations)
        if (!_slottedAnnotations.contains(a.name))
          '{Annotation: ${_str(a.name)}, Args: ${_lit(a.arguments)}}',
    ];
    return entries.isEmpty ? null : '[]*som.SomMetaExtra{${entries.join(', ')}}';
  }

  // ── per-root emission ──────────────────────────────────────────────────────

  /// Emits the tree + entry-point vars of [root] (tree, dot-notation root,
  /// ID-tree root).
  void _emitRoot(StringBuffer b, SpecRoot root) {
    final cls = model.classNamed(root.type);
    final seg = _rootSegment(root);
    final idSymbol = _idName(seg);

    final args = <String>['ClassName: ${_str(root.type)}'];
    final sectionId = root.sectionId ?? cls?.sectionId;
    if (sectionId != null) args.add('SectionID: ${_str(sectionId)}');
    if (cls?.sectionId != null) {
      args.add('ClassSectionID: ${_str(cls!.sectionId!)}');
    }
    args
      ..add('Kind: som.SomMetaKindSection')
      ..add('TypeName: ${_str(root.type)}');
    if (cls?.headline != null) {
      args.add('Headline: ${_str(cls!.headline!)}');
    }
    final doc = root.doc ?? cls?.doc;
    if (doc != null) args.add('DocComment: ${_str(doc)}');
    if (cls?.doc != null) args.add('ClassDocComment: ${_str(cls!.doc!)}');
    if (cls?.mapsTo != null) args.add('MapsTo: ${_str(cls!.mapsTo!)}');
    if (cls?.detailedIn != null) {
      args.add('DetailedIn: ${_str(cls!.detailedIn!)}');
    }
    final basedOn = _basedOn(cls);
    args.add('Document: &som.SomDocMeta{Name: ${_str(root.title)}, '
        'Description: ${_str(root.description ?? '')}'
        '${basedOn.isEmpty ? '' : ', BasedOn: []string{${basedOn.map(_str).join(', ')}}'}}');
    final secondLevel = _secondLevelIdsExpr(cls?.annotations ?? const []);
    if (secondLevel != null) args.add('SecondLevelIds: $secondLevel');
    final extra = _extrasExpr(cls?.annotations ?? const []);
    if (extra != null) args.add('Extra: $extra');
    if (cls != null) {
      args.add('Children: metaChildren${root.type}(map[string]bool{'
          '${_str(root.type)}: true})');
    }

    b
      ..writeln('// ${root.type}MetaTree is the populated metadata tree of '
          'the `${root.type}`')
      ..writeln('// document root (DR1 §3.2).')
      ..writeln('var ${root.type}MetaTree = mustMetaTree(&som.SomMetaNode{'
          '${args.join(', ')}})')
      ..writeln()
      ..writeln('// ${root.type}Meta is the dot-notation access root of '
          '`${root.type}` (DR1 §4.1):')
      ..writeln('// `${root.type}Meta.<Member>()….Path` / `.Meta()`.')
      ..writeln('var ${root.type}Meta = new${root.type}Nav('
          '${root.type}MetaTree, ${_str(seg)})')
      ..writeln()
      ..writeln('// $idSymbol is the ID-tree access root of `${root.type}` '
          '(DR1 §4.2):')
      ..writeln('// `$idSymbol.<SECTION_ID>()….Path` / `.Meta()`.')
      ..writeln('var $idSymbol = new${root.type}ID(${root.type}MetaTree, '
          '${_str(seg)})')
      ..writeln();
  }

  List<String> _basedOn(SpecClass? cls) {
    final raw = cls?.annotation('Document')?.argument('basedOn');
    if (raw is List) return raw.map((e) => '$e').toList();
    return const [];
  }

  // ── dot-notation accessor structs (§4.1) ───────────────────────────────────

  void _emitNavStruct(StringBuffer b, SpecClass cls) {
    b
      ..writeln('// ${cls.name}Nav holds the dot-notation accessors of '
          '`${cls.name}` (DR1 §4.1).')
      ..writeln('// Every method is one navigable position: `.Path` is the '
          'absolute document')
      ..writeln('// path, `.Meta()` the metadata node. Past a recursive '
          're-entry `.Path` chains')
      ..writeln('// remain valid document positions while `.Meta()` returns '
          'an error (the')
      ..writeln('// metadata tree ends there).')
      ..writeln('type ${cls.name}Nav struct {')
      ..writeln('\tsom.SomMetaRef')
      ..writeln('}')
      ..writeln()
      ..writeln('// new${cls.name}Nav binds a ${cls.name}Nav accessor to a '
          'tree and a path.')
      ..writeln('func new${cls.name}Nav(tree *som.SomMetaTree, path string) '
          '*${cls.name}Nav {')
      ..writeln('\treturn &${cls.name}Nav{SomMetaRef: som.SomMetaRef{Tree: '
          'tree, Path: path}}')
      ..writeln('}');
    final used = <String>{};
    for (final f in _orderedFields(cls)) {
      final acc = _navAccessor(used, cls, f);
      final seg = _fieldSegment(f);
      final getter = _navGetter(f, seg);
      b
        ..writeln()
        ..writeln('func (x *${cls.name}Nav) $acc() ${getter.type} {');
      for (final line in getter.body) {
        b.writeln('\t$line');
      }
      b.writeln('}');
    }
    b.writeln();
  }

  /// The Pascal-cased accessor name of a member — the facade convention
  /// (DR1d; Go exports by capitalization). Reserved names fail generation
  /// loudly (the TS blueprint behavior); Pascal-case collisions within a
  /// struct dedupe with a numeric suffix.
  String _navAccessor(Set<String> used, SpecClass cls, SpecField f) {
    var base = _pascal(f.name);
    if (base.isEmpty) base = 'Field';
    if (_reservedAccessorNames.contains(base)) {
      throw StateError('model field ${cls.name}.${f.name} collides with a '
          'reserved accessor member name');
    }
    var cand = base;
    var n = 2;
    while (!used.add(cand)) {
      cand = '$base$n';
      n++;
    }
    return cand;
  }

  _TypedBody _navGetter(SpecField f, String seg) {
    final rel = 'x.Tree, x.Path+"/${_gseg(seg)}"';
    switch (f.kind) {
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = model.classNamed(f.type ?? '');
        if (target != null) {
          return _TypedBody('*${target.name}Nav',
              ['return new${target.name}Nav($rel)']);
        }
        return _leafBody(seg);
      case SpecFieldKind.list:
        final element =
            f.elementIsComplex ? model.classNamed(f.elementType ?? '') : null;
        if (element != null) {
          return _TypedBody('*som.SomListMetaRef[*${element.name}Nav]', [
            'return som.NewSomListMetaRef($rel, func(t *som.SomMetaTree, '
                'p string) *${element.name}Nav {',
            '\treturn new${element.name}Nav(t, p)',
            '})',
          ]);
        }
        return _scalarListBody(rel);
      case SpecFieldKind.form:
      case SpecFieldKind.content:
      case SpecFieldKind.enumValue:
      case SpecFieldKind.scalar:
        return _leafBody(seg);
    }
  }

  _TypedBody _leafBody(String seg) => _TypedBody('*som.SomMetaRef', [
        'return &som.SomMetaRef{Tree: x.Tree, Path: x.Path + '
            '"/${_gseg(seg)}"}',
      ]);

  _TypedBody _scalarListBody(String rel) =>
      _TypedBody('*som.SomListMetaRef[*som.SomMetaRef]', [
        'return som.NewSomListMetaRef($rel, func(t *som.SomMetaTree, '
            'p string) *som.SomMetaRef {',
        '\treturn &som.SomMetaRef{Tree: t, Path: p}',
        '})',
      ]);

  /// Escapes a path segment for inclusion inside a double-quoted generated
  /// string literal (segments are ids/identifiers — quotes unexpected,
  /// guarded anyway).
  String _gseg(String seg) =>
      seg.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

  // ── ID-tree accessor structs (§4.2) ────────────────────────────────────────

  /// The classes needing a `<Class>ID` accessor struct: the selected roots
  /// plus every class reachable as an ID-node target (through id-bearing
  /// complex/section fields, id-bearing complex-element lists, and hoisting
  /// through id-less complex/section members).
  List<String> _idReachableClasses() {
    final reachable = <String>{};
    final queue = <String>[for (final r in _roots) r.type];
    while (queue.isNotEmpty) {
      final name = queue.removeLast();
      final cls = model.classNamed(name);
      if (cls == null || !reachable.add(name)) continue;
      for (final child in _idChildren(cls)) {
        if (child.targetClass != null) queue.add(child.targetClass!);
      }
    }
    final sorted = reachable.toList()..sort();
    return sorted;
  }

  void _emitIdStruct(StringBuffer b, SpecClass cls) {
    b
      ..writeln('// ${cls.name}ID holds the ID-tree accessors of '
          '`${cls.name}` (DR1 §4.2): methods')
      ..writeln('// named by section id (`-` → `_`), hoisted through id-less '
          'members so every')
      ..writeln('// reachable id is one step. `.Path` and `.Meta()` agree '
          'with the dot-notation')
      ..writeln('// surface.')
      ..writeln('type ${cls.name}ID struct {')
      ..writeln('\tsom.SomMetaRef')
      ..writeln('}')
      ..writeln()
      ..writeln('// new${cls.name}ID binds a ${cls.name}ID accessor to a '
          'tree and a path.')
      ..writeln('func new${cls.name}ID(tree *som.SomMetaTree, path string) '
          '*${cls.name}ID {')
      ..writeln('\treturn &${cls.name}ID{SomMetaRef: som.SomMetaRef{Tree: '
          'tree, Path: path}}')
      ..writeln('}');
    for (final child in _idChildren(cls)) {
      if (_reservedAccessorNames.contains(child.name)) {
        throw StateError('section id ${child.name} of ${cls.name} collides '
            'with a reserved accessor member name');
      }
      final rel = 'x.Tree, x.Path+"/${_gseg(child.relPath)}"';
      final String type;
      final List<String> body;
      if (child.isList) {
        final elem = child.targetClass;
        if (elem != null) {
          type = '*som.SomListMetaRef[*${elem}ID]';
          body = [
            'return som.NewSomListMetaRef($rel, func(t *som.SomMetaTree, '
                'p string) *${elem}ID {',
            '\treturn new${elem}ID(t, p)',
            '})',
          ];
        } else {
          type = '*som.SomListMetaRef[*som.SomMetaRef]';
          body = [
            'return som.NewSomListMetaRef($rel, func(t *som.SomMetaTree, '
                'p string) *som.SomMetaRef {',
            '\treturn &som.SomMetaRef{Tree: t, Path: p}',
            '})',
          ];
        }
      } else if (child.targetClass != null) {
        type = '*${child.targetClass}ID';
        body = ['return new${child.targetClass}ID($rel)'];
      } else {
        type = '*som.SomMetaRef';
        body = [
          'return &som.SomMetaRef{Tree: x.Tree, Path: x.Path + '
              '"/${_gseg(child.relPath)}"}',
        ];
      }
      b
        ..writeln()
        ..writeln('func (x *${cls.name}ID) ${child.name}() $type {');
      for (final line in body) {
        b.writeln('\t$line');
      }
      b.writeln('}');
    }
    b.writeln();
  }

  /// The ID-children of [cls]: one entry per id-bearing position reachable
  /// without crossing another id (hoisting through id-less complex/section
  /// members, with a cycle guard). Id-less lists and id-less leaves carry no
  /// id and are skipped (list items are dynamic — no static hoist through
  /// them). Identical to the Dart reference implementation.
  List<_IdChild> _idChildren(SpecClass cls) {
    final children = <_IdChild>[];
    final used = <String>{};

    void walk(SpecClass c, String prefix, Set<String> stack) {
      for (final f in _orderedFields(c)) {
        final isComplexLike = f.kind == SpecFieldKind.complex ||
            f.kind == SpecFieldKind.section;
        if (f.sectionId != null) {
          var name = _idName(f.sectionId!);
          var n = 2;
          while (!used.add(name)) {
            name = '${_idName(f.sectionId!)}_$n';
            n++;
          }
          final rel = '$prefix${f.sectionId!}';
          if (f.kind == SpecFieldKind.list) {
            final elem = f.elementIsComplex
                ? model.classNamed(f.elementType ?? '')?.name
                : null;
            children.add(_IdChild(
                name: name, relPath: rel, targetClass: elem, isList: true));
          } else if (isComplexLike) {
            children.add(_IdChild(
                name: name,
                relPath: rel,
                targetClass: model.classNamed(f.type ?? '')?.name));
          } else {
            children.add(_IdChild(name: name, relPath: rel));
          }
        } else if (isComplexLike) {
          final target = model.classNamed(f.type ?? '');
          if (target != null && !stack.contains(target.name)) {
            stack.add(target.name);
            walk(target, '$prefix${f.name}/', stack);
            stack.remove(target.name);
          }
        }
      }
    }

    walk(cls, '', <String>{cls.name});
    return children;
  }

  /// A section id as a Go identifier: `-` → `_`, digit-leading ids prefixed
  /// with `ID` (the Go analogue of the TS `$` prefix; the model currently
  /// carries no digit-leading ids — this is a generation-time safety net).
  String _idName(String id) {
    final name = id.replaceAll('-', '_');
    return RegExp(r'^[0-9]').hasMatch(name) ? 'ID$name' : name;
  }
}

/// A generated accessor method's Go return type + body lines.
class _TypedBody {
  final String type;
  final List<String> body;
  const _TypedBody(this.type, this.body);
}

/// One ID-tree child position of a class (see `_idChildren`).
class _IdChild {
  final String name;
  final String relPath;
  final String? targetClass;
  final bool isList;

  const _IdChild({
    required this.name,
    required this.relPath,
    this.targetClass,
    this.isList = false,
  });
}
