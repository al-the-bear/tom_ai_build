/// Emits the generated **metadata module** of the Java `v0` facade (DR24, the
/// Java counterpart of `som_go_meta_emitter.dart` /
/// `som_typescript_meta_emitter.dart` / `som_python_meta_emitter.dart` /
/// `som_dart_meta_emitter.dart`): the populated `SomMetaTree`s as generated
/// static data structures in code (DR1 §3.2) plus the two discoverable access
/// surfaces of DR1 §4 — the **dot-notation tree** (model member names, §4.1)
/// and the **ID-tree** (section ids, §4.2). This module replaces the retired
/// flat path-constant holders (`Pd00Paths.…`) in the Java facade.
///
/// The emitted node values mirror `tom_som_java_runtime`'s
/// `SomMetaBridge.buildSomMetaTree` (the meta-JSON bridge) **field for
/// field**, sourced from the same [SpecModel], so the generated trees and the
/// bridge-built trees are structurally identical — the facade test suite
/// asserts this exhaustively with `SpecMetaDiff.somMetaNodeDiff`. Cycle
/// handling matches the bridge: a class already on the descent stack becomes
/// a terminal re-entry node (`recursive = true`), which the generated
/// `metaCx` helper reproduces at tree-construction time.
///
/// Java divergences from the Go blueprint (all packaging/naming — the emitted
/// node values and path strings are byte-identical):
///
///   * Java's one-public-class-per-file rule is honoured the same way the
///     facade honours it: one outer class `TomSomV0Meta` (a sibling of the
///     facade's `TomSomV0` in the same `tom_som_java_v0` package) whose every
///     accessor class is a `public static final` nested type. The outer class
///     is its own namespace, so — unlike Go's flat package — the meta module
///     cannot collide with facade identifiers; a generation-time guard still
///     fails loudly when meta identifiers collide with *each other*.
///   * accessor types are `<Class>Nav` / `<Class>Id` with plain public
///     `(SomMetaTree, String)` constructors — Java constructors carry the
///     class name, so no `new<X>` wiring functions are needed;
///   * dot-notation getters keep the **verbatim member names** (the facade
///     accessor convention — Java needs no export capitalisation); ID-tree
///     getters keep the section id verbatim (`-` → `_`). Java keywords gain
///     the facade's trailing-underscore sanitisation; a digit-leading id
///     would gain an `ID` prefix (the Go convention; a generation-time safety
///     net — the model carries none).
///   * a Java class file caps its constant pool at 64k entries, so the
///     per-class metadata builders (`metaChildren`, holding every doc-comment
///     string literal of that class) live **inside their `<Class>Nav` nested
///     class** — one constant pool per model class — instead of all sharing
///     the outer class file the way Go's flat package shares one namespace;
///   * `SomMetaNode` has no named constructor arguments: nodes are built by
///     constructing the `(className, kind, typeName)` triple and assigning
///     the remaining (public, defaulted) fields, exactly the bridge's shape.
///
/// Per document root the module tail declares `<RootType>MetaTree` (the wired
/// tree, built by a `build<RootType>MetaTree` method), the dot-notation entry
/// `<RootType>Meta`, and the ID-tree entry `<ROOT-SEGMENT>` (`SBP`, `CLA`,
/// …). Element accessors of lists are wired as **factory lambdas**
/// `(t, p) -> ref` (the runtime's `SomMetaRefFactory<T>`).
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Annotation names with a dedicated `SomMetaNode` slot — everything else is
/// captured into `extra`. Must stay identical to the bridge's set.
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

/// Accessor method names a generated Nav/Id class must never emit: the
/// members of the extended runtime `SomMetaRef` (`tree` / `path` fields, the
/// `meta()` method), `item` (the list accessor, reserved uniformly like the
/// Go/TS ports), and `java.lang.Object`'s zero-arg methods a generated
/// zero-arg accessor would illegally override or shadow (`getClass` /
/// `notify` / `notifyAll` / `wait` are `final`; `hashCode` / `toString` /
/// `clone` / `finalize` clash on return type). Collisions fail generation
/// loudly.
const Set<String> _reservedAccessorNames = {
  'tree',
  'path',
  'meta',
  'item',
  'getClass',
  'hashCode',
  'toString',
  'clone',
  'finalize',
  'notify',
  'notifyAll',
  'wait',
};

/// Emits the Java source of the generated metadata module (see the library
/// doc above) for [model].
class SomJavaMetaEmitter {
  final SpecModel model;
  final String versionLabel;
  final List<String> documentRoots;

  SomJavaMetaEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
  });

  // Indentation mirrors the facade emitter: outer class body at 2 spaces,
  // nested-type members at 4, their bodies at 6, lambda bodies at 8.
  static const String _i1 = '  ';
  static const String _i2 = '    ';
  static const String _i3 = '      ';
  static const String _i4 = '        ';

  List<SpecRoot> get _roots {
    if (documentRoots.isEmpty) return model.roots;
    final wanted = documentRoots.toSet();
    return model.roots.where((r) => wanted.contains(r.type)).toList();
  }

  /// The complete generated metadata module source (`TomSomV0Meta.java`).
  String generateLibrary() {
    final classNames = model.classes.keys.toList()..sort();
    final idClasses = _idReachableClasses();
    _guardIdentifierCollisions(classNames, idClasses);

    final b = StringBuffer()
      ..writeln('// GENERATED by tom_specs_clitool SomJavaMetaEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('//')
      ..writeln('// The populated SOM metadata trees (DR1 §3.2) and the two')
      ..writeln('// generated access surfaces of DR1 §4: the dot-notation '
          'tree')
      ..writeln('// (model member names) and the ID-tree (section ids). Both')
      ..writeln('// resolve to the same SomMetaNode and byte-identical path')
      ..writeln('// strings; the flat path-constant holders are retired.')
      ..writeln('package tom_som_java_v0;')
      ..writeln()
      ..writeln('import java.util.ArrayList;')
      ..writeln('import java.util.Arrays;')
      ..writeln('import java.util.HashSet;')
      ..writeln('import java.util.LinkedHashMap;')
      ..writeln('import java.util.List;')
      ..writeln('import java.util.Map;')
      ..writeln('import java.util.Set;')
      ..writeln('import java.util.function.BiFunction;')
      ..writeln('import java.util.function.Function;')
      ..writeln()
      ..writeln('import tom_som_runtime.SomContentTypeMeta;')
      ..writeln('import tom_som_runtime.SomDocMeta;')
      ..writeln('import tom_som_runtime.SomFormFieldMeta;')
      ..writeln('import tom_som_runtime.SomFormMeta;')
      ..writeln('import tom_som_runtime.SomListMetaRef;')
      ..writeln('import tom_som_runtime.SomMetaExtra;')
      ..writeln('import tom_som_runtime.SomMetaKind;')
      ..writeln('import tom_som_runtime.SomMetaNode;')
      ..writeln('import tom_som_runtime.SomMetaRef;')
      ..writeln('import tom_som_runtime.SomMetaTree;')
      ..writeln('import tom_som_runtime.SomSecondLevelId;')
      ..writeln()
      ..writeln('/** The generated SOM metadata module: populated metadata '
          'trees plus the dot-notation and ID-tree access surfaces. */')
      ..writeln('public final class TomSomV0Meta {')
      ..writeln('${_i1}private TomSomV0Meta() {}')
      ..writeln();

    _emitHelpers(b);

    // ── dot-notation accessor classes + per-class metadata builders ─────────
    b
      ..writeln('$_i1// ── dot-notation accessor classes (DR1 §4.1) + '
          'metadata builders (§3.2) ──')
      ..writeln();
    for (final name in classNames) {
      _emitNavClass(b, model.classes[name]!);
    }

    // ── ID-tree accessor classes ─────────────────────────────────────────────
    b
      ..writeln('$_i1// ── ID-tree accessor classes (DR1 §4.2) '
          '──────────────────────────────────')
      ..writeln();
    for (final name in idClasses) {
      _emitIdClass(b, model.classes[name]!);
    }

    // ── per-root trees + access-surface entry points ─────────────────────────
    b
      ..writeln('$_i1// ── document-root metadata trees + access surface '
          'roots ──────────────────')
      ..writeln();
    for (final root in _roots) {
      _emitRoot(b, root);
    }

    b.writeln('}');
    return b.toString();
  }

  // ── generation-time collision guard ────────────────────────────────────────

  /// Fails generation loudly when generated meta-module identifiers collide
  /// with each other. The outer `TomSomV0Meta` class is its own namespace (no
  /// facade collisions are possible, unlike Go's flat package), but nested
  /// type names, static field names and static method names must each stay
  /// unique within it (all derive deterministically from the same model).
  void _guardIdentifierCollisions(
      List<String> classNames, List<String> idClasses) {
    final types = <String>{};
    final typeClashes = <String>[];
    for (final name in classNames) {
      if (!types.add('${name}Nav')) typeClashes.add('${name}Nav');
    }
    for (final name in idClasses) {
      if (!types.add('${name}Id')) typeClashes.add('${name}Id');
    }

    final fields = <String>{};
    final fieldClashes = <String>[];
    for (final root in _roots) {
      for (final f in [
        '${root.type}MetaTree',
        '${root.type}Meta',
        _idName(_rootSegment(root)),
      ]) {
        if (!fields.add(f)) fieldClashes.add(f);
      }
    }

    final methods = <String>{'metaCx', 'metaArgs'};
    final methodClashes = <String>[];
    for (final root in _roots) {
      final m = 'build${root.type}MetaTree';
      if (!methods.add(m)) methodClashes.add(m);
    }

    final clashes = [...typeClashes, ...fieldClashes, ...methodClashes]
      ..sort();
    if (clashes.isNotEmpty) {
      throw StateError('generated meta-module identifiers collide within '
          'TomSomV0Meta: ${clashes.join(', ')}');
    }
  }

  // ── shared helpers ─────────────────────────────────────────────────────────

  void _emitHelpers(StringBuffer b) {
    b
      ..writeln("$_i1// metaCx builds a complex/section (or list-element) "
          "node with the bridge's")
      ..writeln('$_i1// cycle rule: a class already on the descent stack '
          'becomes a terminal')
      ..writeln('$_i1// re-entry node (recursive = true, no children).')
      ..writeln('${_i1}private static SomMetaNode metaCx(')
      ..writeln('${_i3}String cls,')
      ..writeln('${_i3}Set<String> stack,')
      ..writeln('${_i3}Function<Set<String>, List<SomMetaNode>> kids,')
      ..writeln('${_i3}BiFunction<Boolean, List<SomMetaNode>, SomMetaNode> '
          'build) {')
      ..writeln('${_i2}if (stack.contains(cls)) {')
      ..writeln('${_i3}return build.apply(true, new ArrayList<>());')
      ..writeln('$_i2}')
      ..writeln('${_i2}stack.add(cls);')
      ..writeln('${_i2}List<SomMetaNode> c = kids.apply(stack);')
      ..writeln('${_i2}stack.remove(cls);')
      ..writeln('${_i2}return build.apply(false, c);')
      ..writeln('$_i1}')
      ..writeln()
      ..writeln("$_i1// metaArgs builds an extra annotation's insertion-"
          'ordered argument map from')
      ..writeln('$_i1// alternating key/value pairs.')
      ..writeln('${_i1}private static Map<String, Object> metaArgs('
          'Object... kv) {')
      ..writeln('${_i2}Map<String, Object> m = new LinkedHashMap<>();')
      ..writeln('${_i2}for (int i = 0; i < kv.length; i += 2) {')
      ..writeln('${_i3}m.put((String) kv[i], kv[i + 1]);')
      ..writeln('$_i2}')
      ..writeln('${_i2}return m;')
      ..writeln('$_i1}')
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

  /// The Java `SomMetaKind.*` constant for a [SpecFieldKind].
  String _kindConst(SpecFieldKind kind) {
    switch (kind) {
      case SpecFieldKind.list:
        return 'SomMetaKind.LIST';
      case SpecFieldKind.form:
        return 'SomMetaKind.FORM';
      case SpecFieldKind.section:
        return 'SomMetaKind.SECTION';
      case SpecFieldKind.content:
        return 'SomMetaKind.CONTENT';
      case SpecFieldKind.enumValue:
        return 'SomMetaKind.ENUM_VALUE';
      case SpecFieldKind.complex:
        return 'SomMetaKind.COMPLEX';
      case SpecFieldKind.scalar:
        return 'SomMetaKind.SCALAR';
    }
  }

  /// A Java double-quoted string literal for [s] (full control-character
  /// escaping — doc comments and descriptions carry newlines).
  String _str(String s) => '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r').replaceAll('\t', '\\t')}"';

  /// A Java literal for a JSON-shaped annotation-argument [value], typed as
  /// the runtime's `Object` argument shapes.
  String _lit(Object? value) {
    if (value == null) return 'null';
    if (value is String) return _str(value);
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return '$value';
    if (value is List) {
      return 'Arrays.asList(${value.map(_lit).join(', ')})';
    }
    if (value is Map) {
      final entries = value.entries
          .map((e) => '${_str('${e.key}')}, ${_lit(e.value)}')
          .join(', ');
      return 'metaArgs($entries)';
    }
    throw StateError('unsupported annotation argument literal: '
        '${value.runtimeType} ($value)');
  }

  // ── metadata builders ──────────────────────────────────────────────────────

  /// Emits the `metaChildren` static builder of [cls] — nested inside the
  /// class's Nav accessor so every class's string constants live in their own
  /// class file (see the library doc's constant-pool note).
  void _emitMetaChildrenBuilder(StringBuffer b, SpecClass cls) {
    b
      ..writeln('$_i2// The metadata children of `${cls.name}` (DR1 §3.2), '
          'bridge-identical.')
      ..writeln('${_i2}static List<SomMetaNode> metaChildren(Set<String> s) '
          '{')
      ..writeln('${_i3}List<SomMetaNode> out = new ArrayList<>();');
    for (final f in _orderedFields(cls)) {
      _emitFieldNode(b, cls, f);
    }
    b
      ..writeln('${_i3}return out;')
      ..writeln('$_i2}');
  }

  /// Writes the statements building the `SomMetaNode` for field [f] of
  /// [owner] — value-for-value the bridge's `fieldNode`.
  void _emitFieldNode(StringBuffer b, SpecClass owner, SpecField f) {
    final isComplexLike =
        f.kind == SpecFieldKind.complex || f.kind == SpecFieldKind.section;
    final target = isComplexLike ? model.classNamed(f.type ?? '') : null;

    final assigns = <String>[];
    void add(String field, String? expr) {
      if (expr != null) assigns.add('n.$field = $expr;');
    }

    final className = _str(target?.name ?? owner.name);
    final typeName =
        _str(f.type ?? f.elementType ?? f.enumType ?? 'String');
    add('memberName', _str(f.name));
    if (f.sectionId != null) add('sectionId', _str(f.sectionId!));
    if (target?.sectionId != null) {
      add('classSectionId', _str(target!.sectionId!));
    }
    if (f.sectionIdPattern != null) {
      add('sectionIdPattern', _str(f.sectionIdPattern!));
    }
    if (f.serializationOrder != null) {
      add('serializationOrder', '${f.serializationOrder}');
    }
    if (f.min != null) add('min', '${f.min}');
    if (f.annotation('Unused') != null) add('unused', 'true');
    if (f.contentType != null) {
      final desc =
          '${f.annotation('ContentType')?.argument('description') ?? ''}';
      add('contentType',
          'new SomContentTypeMeta(${_str(f.contentType!)}, ${_str(desc)})');
    }
    if (f.help != null) add('contentHelp', _str(f.help!));
    final headline = f.headline ?? target?.headline;
    if (headline != null) add('headline', _str(headline));
    final comment = '${f.annotation('Comment')?.argument('text') ?? ''}';
    if (comment.isNotEmpty) add('comment', _str(comment));
    final docComment = f.doc ?? target?.doc;
    if (docComment != null) add('docComment', _str(docComment));
    if (target?.doc != null) add('classDocComment', _str(target!.doc!));
    if (f.kind == SpecFieldKind.form) {
      final fields = <String>[];
      for (var i = 0; i < f.formFields.length; i++) {
        final ff = f.formFields[i];
        // YRD6: role/initial fields use the extended constructor; ordinary
        // fields keep the compact one.
        final roleArgs = ff.role != null || ff.initial != null
            ? '${ff.role != null ? _str(ff.role!) : 'null'}, '
                '${ff.initial != null ? _str(ff.initial!) : 'null'}, '
            : '';
        fields.add('new SomFormFieldMeta(${_str(ff.name)}, ${_str(ff.type)}, '
            '${_str(ff.label)}, ${ff.required ? 'true' : 'false'}, '
            '${ff.hint != null ? _str(ff.hint!) : 'null'}, $roleArgs$i)');
      }
      add('form',
          'new SomFormMeta(Arrays.asList(\n'
              '$_i4$_i2${fields.join(',\n$_i4$_i2')}))');
    }
    if (target?.mapsTo != null) add('mapsTo', _str(target!.mapsTo!));
    if (target?.detailedIn != null) {
      add('detailedIn', _str(target!.detailedIn!));
    }
    final secondLevel = _secondLevelIdsExpr(f.annotations);
    if (secondLevel != null) add('secondLevelIds', secondLevel);
    final extra = _extrasExpr(f.annotations);
    if (extra != null) add('extra', extra);

    if (target != null) {
      // Complex/section: recursive/children resolved by the cycle helper.
      b.writeln('${_i3}out.add(metaCx(${_str(target.name)}, s, '
          '${target.name}Nav::metaChildren, (r, c) -> {');
      b.writeln('${_i4}SomMetaNode n = new SomMetaNode($className, '
          '${_kindConst(f.kind)}, $typeName);');
      for (final line in assigns) {
        b.writeln('$_i4$line');
      }
      b
        ..writeln('${_i4}n.recursive = r;')
        ..writeln('${_i4}n.children = c;')
        ..writeln('${_i4}return n;')
        ..writeln('$_i3}));');
      return;
    }

    b
      ..writeln('$_i3{')
      ..writeln('$_i2${_i2}SomMetaNode n = new SomMetaNode($className, '
          '${_kindConst(f.kind)}, $typeName);');
    for (final line in assigns) {
      b.writeln('$_i2$_i2$line');
    }

    // Element subtree of a complex-element list: built through the cycle
    // helper, mirroring the bridge's element expansion.
    final element = f.kind == SpecFieldKind.list && f.elementIsComplex
        ? model.classNamed(f.elementType ?? '')
        : null;
    if (element != null) {
      b.writeln('$_i2${_i2}n.elementNode = metaCx(${_str(element.name)}, s, '
          '${element.name}Nav::metaChildren, (r, c) -> {');
      b.writeln('$_i2$_i3'
          'SomMetaNode e = new SomMetaNode(${_str(element.name)}, '
          'SomMetaKind.COMPLEX, ${_str(element.name)});');
      if (element.sectionId != null) {
        b.writeln('$_i2${_i3}e.classSectionId = ${_str(element.sectionId!)};');
      }
      if (element.headline != null) {
        b.writeln('$_i2${_i3}e.headline = ${_str(element.headline!)};');
      }
      if (element.doc != null) {
        b
          ..writeln('$_i2${_i3}e.docComment = ${_str(element.doc!)};')
          ..writeln('$_i2${_i3}e.classDocComment = ${_str(element.doc!)};');
      }
      if (element.mapsTo != null) {
        b.writeln('$_i2${_i3}e.mapsTo = ${_str(element.mapsTo!)};');
      }
      if (element.detailedIn != null) {
        b.writeln('$_i2${_i3}e.detailedIn = ${_str(element.detailedIn!)};');
      }
      b
        ..writeln('$_i2${_i3}e.recursive = r;')
        ..writeln('$_i2${_i3}e.children = c;')
        ..writeln('$_i2${_i3}return e;')
        ..writeln('$_i2$_i2});');
    }
    b
      ..writeln('$_i2${_i2}out.add(n);')
      ..writeln('$_i3}');
  }

  String? _secondLevelIdsExpr(List<SpecAnnotation> annotations) {
    final entries = [
      for (final a in annotations)
        if (a.name == 'SecondLevelSectionId')
          'new SomSecondLevelId('
              "${_str('${a.argument('documentClass') ?? ''}')}, "
              "${_str('${a.argument('id') ?? ''}')})",
    ];
    return entries.isEmpty ? null : 'Arrays.asList(${entries.join(', ')})';
  }

  String? _extrasExpr(List<SpecAnnotation> annotations) {
    final entries = [
      for (final a in annotations)
        if (!_slottedAnnotations.contains(a.name))
          'new SomMetaExtra(${_str(a.name)}, ${_lit(a.arguments)})',
    ];
    return entries.isEmpty ? null : 'Arrays.asList(${entries.join(', ')})';
  }

  // ── per-root emission ──────────────────────────────────────────────────────

  /// Emits the tree + entry-point statics of [root] (tree, dot-notation root,
  /// ID-tree root).
  void _emitRoot(StringBuffer b, SpecRoot root) {
    final cls = model.classNamed(root.type);
    final seg = _rootSegment(root);
    final idSymbol = _idName(seg);

    b
      ..writeln('$_i1// ${root.type}MetaTree is the populated metadata tree '
          'of the `${root.type}`')
      ..writeln('$_i1// document root (DR1 §3.2).')
      ..writeln('${_i1}public static final SomMetaTree ${root.type}MetaTree '
          '= build${root.type}MetaTree();')
      ..writeln()
      ..writeln('${_i1}private static SomMetaTree build${root.type}MetaTree'
          '() {')
      ..writeln('${_i2}SomMetaNode n = new SomMetaNode(${_str(root.type)}, '
          'SomMetaKind.SECTION, ${_str(root.type)});');
    final sectionId = root.sectionId ?? cls?.sectionId;
    if (sectionId != null) {
      b.writeln('${_i2}n.sectionId = ${_str(sectionId)};');
    }
    if (cls?.sectionId != null) {
      b.writeln('${_i2}n.classSectionId = ${_str(cls!.sectionId!)};');
    }
    if (cls?.headline != null) {
      b.writeln('${_i2}n.headline = ${_str(cls!.headline!)};');
    }
    final doc = root.doc ?? cls?.doc;
    if (doc != null) b.writeln('${_i2}n.docComment = ${_str(doc)};');
    if (cls?.doc != null) {
      b.writeln('${_i2}n.classDocComment = ${_str(cls!.doc!)};');
    }
    if (cls?.mapsTo != null) {
      b.writeln('${_i2}n.mapsTo = ${_str(cls!.mapsTo!)};');
    }
    if (cls?.detailedIn != null) {
      b.writeln('${_i2}n.detailedIn = ${_str(cls!.detailedIn!)};');
    }
    final basedOn = _basedOn(cls);
    final basedOnExpr = basedOn.isEmpty
        ? 'null'
        : 'Arrays.asList(${basedOn.map(_str).join(', ')})';
    b.writeln('${_i2}n.document = new SomDocMeta(${_str(root.title)}, '
        '${_str(root.description ?? '')}, $basedOnExpr);');
    final secondLevel = _secondLevelIdsExpr(cls?.annotations ?? const []);
    if (secondLevel != null) {
      b.writeln('${_i2}n.secondLevelIds = $secondLevel;');
    }
    final extra = _extrasExpr(cls?.annotations ?? const []);
    if (extra != null) b.writeln('${_i2}n.extra = $extra;');
    if (cls != null) {
      b
        ..writeln('${_i2}Set<String> stack = new HashSet<>();')
        ..writeln('${_i2}stack.add(${_str(root.type)});')
        ..writeln('${_i2}n.children = ${root.type}Nav.metaChildren(stack);');
    }
    b
      ..writeln('${_i2}return new SomMetaTree(n);')
      ..writeln('$_i1}')
      ..writeln()
      ..writeln('$_i1// ${root.type}Meta is the dot-notation access root of '
          '`${root.type}` (DR1 §4.1):')
      ..writeln('$_i1// `${root.type}Meta.<member>()….path` / `.meta()`.')
      ..writeln('${_i1}public static final ${root.type}Nav ${root.type}Meta '
          '=')
      ..writeln('${_i3}new ${root.type}Nav(${root.type}MetaTree, '
          '${_str(seg)});')
      ..writeln()
      ..writeln('$_i1// $idSymbol is the ID-tree access root of '
          '`${root.type}` (DR1 §4.2):')
      ..writeln('$_i1// `$idSymbol.<SECTION_ID>()….path` / `.meta()`.')
      ..writeln('${_i1}public static final ${root.type}Id $idSymbol =')
      ..writeln('${_i3}new ${root.type}Id(${root.type}MetaTree, '
          '${_str(seg)});')
      ..writeln();
  }

  List<String> _basedOn(SpecClass? cls) {
    final raw = cls?.annotation('Document')?.argument('basedOn');
    if (raw is List) return raw.map((e) => '$e').toList();
    return const [];
  }

  // ── dot-notation accessor classes (§4.1) ───────────────────────────────────

  void _emitNavClass(StringBuffer b, SpecClass cls) {
    b
      ..writeln('$_i1// ${cls.name}Nav holds the dot-notation accessors of '
          '`${cls.name}` (DR1 §4.1).')
      ..writeln('$_i1// Every method is one navigable position: `.path` is '
          'the absolute document')
      ..writeln('$_i1// path, `.meta()` the metadata node. Past a recursive '
          're-entry `.path` chains')
      ..writeln('$_i1// remain valid document positions while `.meta()` '
          'throws (the metadata tree')
      ..writeln('$_i1// ends there).')
      ..writeln('${_i1}public static final class ${cls.name}Nav extends '
          'SomMetaRef {')
      ..writeln('${_i2}public ${cls.name}Nav(SomMetaTree tree, String path) '
          '{')
      ..writeln('${_i3}super(tree, path);')
      ..writeln('$_i2}')
      ..writeln();
    _emitMetaChildrenBuilder(b, cls);
    final used = <String>{};
    for (final f in _orderedFields(cls)) {
      final acc = _navAccessor(used, cls, f);
      final seg = _fieldSegment(f);
      final getter = _navGetter(f, seg);
      b
        ..writeln()
        ..writeln('${_i2}public ${getter.type} $acc() {');
      for (final line in getter.body) {
        b.writeln('$_i3$line');
      }
      b.writeln('$_i2}');
    }
    b
      ..writeln('$_i1}')
      ..writeln();
  }

  /// The verbatim member name as accessor — the facade convention (Java
  /// keywords gain the facade's trailing underscore). Reserved names fail
  /// generation loudly (the Go/TS blueprint behavior); sanitisation
  /// collisions within a class dedupe with a numeric suffix.
  String _navAccessor(Set<String> used, SpecClass cls, SpecField f) {
    var base = _acc(f.name);
    if (base.isEmpty) base = 'field';
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
    final rel = 'tree, path + "/${_gseg(seg)}"';
    switch (f.kind) {
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = model.classNamed(f.type ?? '');
        if (target != null) {
          return _TypedBody(
              '${target.name}Nav', ['return new ${target.name}Nav($rel);']);
        }
        return _leafBody(rel);
      case SpecFieldKind.list:
        final element =
            f.elementIsComplex ? model.classNamed(f.elementType ?? '') : null;
        if (element != null) {
          return _TypedBody('SomListMetaRef<${element.name}Nav>', [
            'return new SomListMetaRef<>($rel, '
                '(t, p) -> new ${element.name}Nav(t, p));',
          ]);
        }
        return _scalarListBody(rel);
      case SpecFieldKind.form:
      case SpecFieldKind.content:
      case SpecFieldKind.enumValue:
      case SpecFieldKind.scalar:
        return _leafBody(rel);
    }
  }

  _TypedBody _leafBody(String rel) =>
      _TypedBody('SomMetaRef', ['return new SomMetaRef($rel);']);

  _TypedBody _scalarListBody(String rel) =>
      _TypedBody('SomListMetaRef<SomMetaRef>', [
        'return new SomListMetaRef<>($rel, '
            '(t, p) -> new SomMetaRef(t, p));',
      ]);

  /// Escapes a path segment for inclusion inside a double-quoted generated
  /// string literal (segments are ids/identifiers — quotes unexpected,
  /// guarded anyway).
  String _gseg(String seg) =>
      seg.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

  // ── ID-tree accessor classes (§4.2) ────────────────────────────────────────

  /// The classes needing a `<Class>Id` accessor class: the selected roots
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

  void _emitIdClass(StringBuffer b, SpecClass cls) {
    b
      ..writeln('$_i1// ${cls.name}Id holds the ID-tree accessors of '
          '`${cls.name}` (DR1 §4.2): methods')
      ..writeln('$_i1// named by section id (`-` → `_`), hoisted through '
          'id-less members so every')
      ..writeln('$_i1// reachable id is one step. `.path` and `.meta()` '
          'agree with the dot-notation')
      ..writeln('$_i1// surface.')
      ..writeln('${_i1}public static final class ${cls.name}Id extends '
          'SomMetaRef {')
      ..writeln('${_i2}public ${cls.name}Id(SomMetaTree tree, String path) '
          '{')
      ..writeln('${_i3}super(tree, path);')
      ..writeln('$_i2}');
    for (final child in _idChildren(cls)) {
      if (_reservedAccessorNames.contains(child.name)) {
        throw StateError('section id ${child.name} of ${cls.name} collides '
            'with a reserved accessor member name');
      }
      final rel = 'tree, path + "/${_gseg(child.relPath)}"';
      final String type;
      final List<String> body;
      if (child.isList) {
        final elem = child.targetClass;
        if (elem != null) {
          type = 'SomListMetaRef<${elem}Id>';
          body = [
            'return new SomListMetaRef<>($rel, '
                '(t, p) -> new ${elem}Id(t, p));',
          ];
        } else {
          type = 'SomListMetaRef<SomMetaRef>';
          body = [
            'return new SomListMetaRef<>($rel, '
                '(t, p) -> new SomMetaRef(t, p));',
          ];
        }
      } else if (child.targetClass != null) {
        type = '${child.targetClass}Id';
        body = ['return new ${child.targetClass}Id($rel);'];
      } else {
        type = 'SomMetaRef';
        body = ['return new SomMetaRef($rel);'];
      }
      b
        ..writeln()
        ..writeln('${_i2}public $type ${child.name}() {');
      for (final line in body) {
        b.writeln('$_i3$line');
      }
      b.writeln('$_i2}');
    }
    b
      ..writeln('$_i1}')
      ..writeln();
  }

  /// The ID-children of [cls]: one entry per id-bearing position reachable
  /// without crossing another id (hoisting through id-less complex/section
  /// members, with a cycle guard). Id-less lists and id-less leaves carry no
  /// id and are skipped (list items are dynamic — no static hoist through
  /// them). Identical to the Dart/Go reference implementation.
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

  /// A section id as a Java identifier: `-` → `_`, digit-leading ids prefixed
  /// with `ID` (the Go convention; the model currently carries no
  /// digit-leading ids — this is a generation-time safety net), keywords
  /// sanitised with the facade's trailing underscore.
  String _idName(String id) {
    final name = id.replaceAll('-', '_');
    if (RegExp(r'^[0-9]').hasMatch(name)) return 'ID$name';
    return _acc(name);
  }

  /// The Java reserved keywords (plus the boolean/null literals) — identical
  /// to the facade emitter's sanitiser set.
  static const Set<String> _javaKeywords = {
    'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char',
    'class', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum',
    'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements',
    'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new',
    'package', 'private', 'protected', 'public', 'return', 'short', 'static',
    'strictfp', 'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
    'transient', 'try', 'void', 'volatile', 'while',
    'true', 'false', 'null',
  };

  /// Returns a Java-safe identifier for [name] (`for` → `for_`), mirroring
  /// the facade emitter — only the emitted Java identifier changes, the
  /// document path segment stays byte-identical.
  String _acc(String name) => _javaKeywords.contains(name) ? '${name}_' : name;
}

/// A generated accessor method's Java return type + body lines.
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
