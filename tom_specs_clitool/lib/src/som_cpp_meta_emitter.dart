/// Emits the generated **metadata module** of the C++ `v0` facade (the C++
/// counterpart of `som_c_meta_emitter.dart` / `som_go_meta_emitter.dart` / the
/// other language meta emitters): the populated `SomMetaTree`s built as
/// generated code (DR1 §3.2) plus the two discoverable access surfaces of DR1
/// §4 — the **dot-notation tree** (model member names, §4.1) and the **ID-tree**
/// (section ids, §4.2). This module replaces the retired flat path-constant
/// holders (`<Code>Paths`) of the C++ facade.
///
/// The emitted node values mirror `tom_som_cpp_runtime`'s `somBuildMetaTree`
/// (the meta-JSON bridge) **field for field**, sourced from the same
/// [SpecModel], so the generated trees and the bridge-built trees are
/// structurally identical — the facade meta test asserts this with
/// `somMetaNodeDiff`. Cycle handling matches the bridge: a class already on the
/// descent stack becomes a terminal re-entry node (`recursive = true`, no
/// children), reproduced at tree-construction time by the generated builders.
///
/// C++-specific shape (idiomatic RAII, unlike the C port's manual malloc):
///
///   * the runtime `SomMetaNode` owns its children via `std::unique_ptr` and its
///     string/optional fields by value, so a tree is built by generated
///     `build<Class>Children` free functions that `std::make_unique` nodes,
///     populate their value fields, and `addChild` them — then `SomMetaTree`
///     wires parent links + paths. Each root exposes a lazily-cached
///     `const som::SomMetaTree& <root>MetaTree()` (a function-local static /
///     Meyers singleton).
///   * the two access surfaces are structs-over-`som::SomMetaRef` (DR1 §4
///     generated accessor support): `Nav<Class>` / `Id<Class>` each wrap one
///     `SomMetaRef` (tree + absolute path). Every navigable position is one
///     accessor **free function** `nav<Class>_<member>(x)` (dot-notation) /
///     `id<Class>_<sectionId>(x)` (ID-tree) returning the next nav/id struct by
///     value, a `SomMetaRef` for leaves, or a `SomListMetaRef` for lists (whose
///     `element` factory builds the element class's nav/id accessor). Both
///     surfaces resolve to the SAME node and byte-identical `.path`.
///   * everything lives in the `tom_som_v0_meta` namespace, so generated
///     identifiers cannot collide with the facade's `tom_som_v0` types.
///
/// Per document root the module tail declares the tree accessor
/// `<root>MetaTree`, the dot-notation entry `<root>MetaNav` and the ID-tree
/// entry `<root>MetaId`. Both entry points take the tree reference and return
/// the root nav/id struct by value.
library;

import 'dart:convert';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Annotation names with a dedicated `SomMetaNode` slot — everything else is
/// captured into the `extra` list. Must stay identical to the bridge's set.
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

/// Emits the C++ source of the generated metadata module (see the library doc
/// above) for [model]. Produces a header/source pair via [generateHeader] /
/// [generateSource]; both share one deterministic name allocation.
class SomCppMetaEmitter {
  final SpecModel model;
  final String versionLabel;
  final List<String> documentRoots;

  final SpecReflection _ref;

  /// The generated header basename (for the source's `#include`) and guard.
  static const String _headerBasename = 'tom_som_cpp_v0_meta.hpp';
  static const String _headerGuard = 'TOM_SOM_CPP_V0_META_HPP';

  /// The C++ namespace every generated meta identifier lives in.
  static const String _namespace = 'tom_som_v0_meta';

  SomCppMetaEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
  }) : _ref = SpecReflection(model);

  List<SpecRoot> get _roots {
    if (documentRoots.isEmpty) return model.roots;
    final wanted = documentRoots.toSet();
    return model.roots.where((r) => wanted.contains(r.type)).toList();
  }

  /// Reserved C++ keywords (C++17, plus the literals); a section-id-derived
  /// accessor tail matching one gains a trailing underscore so it stays a legal
  /// identifier.
  static const Set<String> _cppKeywords = {
    'alignas', 'alignof', 'and', 'and_eq', 'asm', 'atomic_cancel',
    'atomic_commit', 'atomic_noexcept', 'auto', 'bitand', 'bitor', 'bool',
    'break', 'case', 'catch', 'char', 'char16_t', 'char32_t', 'char8_t',
    'class', 'co_await', 'co_return', 'co_yield', 'compl', 'concept', 'const',
    'const_cast', 'consteval', 'constexpr', 'constinit', 'continue',
    'decltype', 'default', 'delete', 'do', 'double', 'dynamic_cast', 'else',
    'enum', 'explicit', 'export', 'extern', 'false', 'float', 'for', 'friend',
    'goto', 'if', 'inline', 'int', 'long', 'mutable', 'namespace', 'new',
    'noexcept', 'not', 'not_eq', 'nullptr', 'operator', 'or', 'or_eq',
    'private', 'protected', 'public', 'register', 'reinterpret_cast',
    'requires', 'return', 'short', 'signed', 'sizeof', 'static',
    'static_assert', 'struct', 'switch', 'template', 'this',
    'thread_local', 'throw', 'true', 'try', 'typedef', 'typeid', 'typename',
    'union', 'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t',
    'while', 'xor', 'xor_eq',
  };

  // ── class ordering / reachability ───────────────────────────────────────────

  /// The classes reachable from the selected roots (dot-notation surface + tree
  /// builders), sorted.
  List<String> get _navClasses {
    final visited = <String>{};
    final queue = <String>[for (final r in _roots) r.type];
    while (queue.isNotEmpty) {
      final name = queue.removeLast();
      if (!visited.add(name)) continue;
      final cls = model.classNamed(name);
      if (cls == null) continue;
      for (final f in cls.fields) {
        switch (f.kind) {
          case SpecFieldKind.complex:
          case SpecFieldKind.section:
            if (f.type != null) queue.add(f.type!);
            break;
          case SpecFieldKind.list:
            if (f.elementIsComplex && f.elementType != null) {
              queue.add(f.elementType!);
            }
            break;
          case SpecFieldKind.form:
          case SpecFieldKind.content:
          case SpecFieldKind.enumValue:
          case SpecFieldKind.scalar:
            break;
        }
      }
    }
    final sorted = visited.toList()..sort();
    return sorted;
  }

  /// The classes needing an ID-tree accessor struct (roots plus every class
  /// reachable as an ID-node target), sorted.
  List<String> get _idClasses {
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

  // ── header ──────────────────────────────────────────────────────────────────

  /// Builds the generated header (`tom_som_cpp_v0_meta.hpp`).
  String generateHeader() {
    final b = StringBuffer();
    _banner(b, 'header');
    b
      ..writeln('#ifndef $_headerGuard')
      ..writeln('#define $_headerGuard')
      ..writeln()
      ..writeln('#include <string>')
      ..writeln()
      ..writeln('#include "tom_som_cpp_runtime.hpp"')
      ..writeln()
      ..writeln('namespace $_namespace {')
      ..writeln();

    final navClasses = _navClasses;
    final idClasses = _idClasses;

    // Access-surface struct definitions. Each wraps one som::SomMetaRef;
    // accessors take it by value and return the next surface struct / ref by
    // value.
    b
      ..writeln('// ── dot-notation access surface structs (DR1 §4.1) '
          '───────────────────────')
      ..writeln('// Each wraps one som::SomMetaRef (tree + absolute path). '
          'Accessors return the')
      ..writeln('// next navigable position by value; `.ref.path` is the '
          'absolute document path')
      ..writeln('// and `.ref.meta()` the metadata node.');
    for (final n in navClasses) {
      b.writeln('struct ${_navType(n)} { som::SomMetaRef ref; };');
    }
    b.writeln();
    b
      ..writeln('// ── ID-tree access surface structs (DR1 §4.2) '
          '────────────────────────────')
      ..writeln('// The same tree keyed by section id. `.ref.path` and the '
          'metadata node agree')
      ..writeln('// with the dot-notation surface for every position.');
    for (final n in idClasses) {
      b.writeln('struct ${_idType(n)} { som::SomMetaRef ref; };');
    }
    b.writeln();

    // Dot-notation accessor declarations.
    b.writeln('// ── dot-notation accessors (DR1 §4.1) '
        '────────────────────────────────────');
    for (final n in navClasses) {
      final cls = model.classNamed(n)!;
      final used = <String>{};
      for (final f in _orderedFields(cls)) {
        final acc = _navFn(used, n, f);
        b.writeln('${_navReturn(f)} $acc(${_navType(n)} x);');
      }
    }
    b.writeln();

    // ID-tree accessor declarations.
    b.writeln('// ── ID-tree accessors (DR1 §4.2) '
        '─────────────────────────────────────────');
    for (final n in idClasses) {
      final cls = model.classNamed(n)!;
      for (final child in _idChildren(cls)) {
        b.writeln('${_idReturn(child)} ${_idFn(n, child)}(${_idType(n)} x);');
      }
    }
    b.writeln();

    // Per-root entry points.
    b.writeln('// ── document-root metadata trees + access surface entry '
        'points ──────────');
    for (final root in _roots) {
      final treeFn = _treeFn(root.type);
      b
        ..writeln('// The populated `${root.type}` metadata tree (DR1 §3.2), '
            'built + cached on')
        ..writeln('// first call and owned by this module.')
        ..writeln('const som::SomMetaTree& $treeFn();')
        ..writeln('// The dot-notation access root of `${root.type}` (DR1 '
            '§4.1).')
        ..writeln('${_navType(root.type)} ${_rootNavFn(root)}('
            'const som::SomMetaTree& tree);')
        ..writeln('// The ID-tree access root of `${root.type}` (DR1 §4.2).')
        ..writeln('${_idType(root.type)} ${_rootIdFn(root)}('
            'const som::SomMetaTree& tree);');
    }
    b.writeln();

    b
      ..writeln('}  // namespace $_namespace')
      ..writeln()
      ..writeln('#endif  // $_headerGuard');
    return b.toString().replaceAll('\t', '  ');
  }

  // ── source ──────────────────────────────────────────────────────────────────

  /// Builds the generated source (`tom_som_cpp_v0_meta.cpp`).
  String generateSource() {
    _leafFactoryUsed = false;
    _navFactoriesUsed.clear();
    _idFactoriesUsed.clear();

    // Emit accessors into scratch buffers first; this populates the factory sets
    // the factory definitions below depend on.
    final navBuf = StringBuffer();
    for (final n in _navClasses) {
      _emitNavAccessors(navBuf, model.classNamed(n)!);
    }
    final idBuf = StringBuffer();
    for (final n in _idClasses) {
      _emitIdAccessors(idBuf, model.classNamed(n)!);
    }

    final b = StringBuffer();
    _banner(b, 'source');
    b
      ..writeln('#include "$_headerBasename"')
      ..writeln()
      ..writeln('#include <memory>')
      ..writeln('#include <string>')
      ..writeln('#include <vector>')
      ..writeln()
      ..writeln('#include "tom_som_cpp_runtime.hpp"')
      ..writeln()
      ..writeln('namespace $_namespace {')
      ..writeln('namespace {')
      ..writeln();

    _emitHelpers(b);

    // Forward declarations of every children builder (mutual recursion).
    b.writeln('// ── metadata tree builders (DR1 §3.2) — forward decls '
        '───────────────────');
    for (final n in _navClasses) {
      b.writeln('void ${_childrenFn(n)}('
          'som::SomMetaNode& parent, std::vector<std::string>& stack);');
    }
    b.writeln();

    // Children builders.
    b.writeln('// ── metadata tree builders (DR1 §3.2) '
        '────────────────────────────────────');
    for (final n in _navClasses) {
      _emitChildrenBuilder(b, model.classNamed(n)!);
    }

    // Element-accessor factories (used by list accessors).
    _emitFactories(b);

    b.writeln('}  // namespace');
    b.writeln();

    // Per-root tree accessors (lazy cached) + entry points.
    b.writeln('// ── document-root trees + access surface entry points '
        '───────────────────');
    for (final root in _roots) {
      _emitRoot(b, root);
    }

    // Dot-notation accessor definitions.
    b.writeln('// ── dot-notation accessors (DR1 §4.1) '
        '────────────────────────────────────');
    b.write(navBuf.toString());

    // ID-tree accessor definitions.
    b.writeln('// ── ID-tree accessors (DR1 §4.2) '
        '─────────────────────────────────────────');
    b.write(idBuf.toString());

    b.writeln('}  // namespace $_namespace');
    return b.toString().replaceAll('\t', '  ');
  }

  /// Emits the `SomMetaRefFactory` definitions referenced by list accessors: the
  /// shared leaf factory (scalar-element lists) plus one nav/id factory per
  /// complex element class actually referenced.
  void _emitFactories(StringBuffer b) {
    b.writeln('// ── element-accessor factories (som::SomMetaRefFactory) '
        '──────────────────');
    if (_leafFactoryUsed) {
      b
        ..writeln('void* metaLeafFactory(const som::SomMetaTree* tree, '
            'const std::string& path) {')
        ..writeln('\treturn new som::SomMetaRef(tree, path);')
        ..writeln('}');
    }
    final navFacs = _navFactoriesUsed.toList()..sort();
    for (final cls in navFacs) {
      b
        ..writeln('void* ${_navFactoryFn(cls)}(const som::SomMetaTree* tree, '
            'const std::string& path) {')
        ..writeln('\treturn new ${_navType(cls)}{som::SomMetaRef(tree, '
            'path)};')
        ..writeln('}');
    }
    final idFacs = _idFactoriesUsed.toList()..sort();
    for (final cls in idFacs) {
      b
        ..writeln('void* ${_idFactoryFn(cls)}(const som::SomMetaTree* tree, '
            'const std::string& path) {')
        ..writeln('\treturn new ${_idType(cls)}{som::SomMetaRef(tree, '
            'path)};')
        ..writeln('}');
    }
    b.writeln();
  }

  // ── helpers block ───────────────────────────────────────────────────────────

  void _emitHelpers(StringBuffer b) {
    b
      ..writeln('// metaCx applies the bridge cycle rule: a class already on the '
          'descent stack')
      ..writeln('// becomes a terminal re-entry node (recursive = true, no '
          'children). `build`')
      ..writeln('// fills a freshly-allocated node; `kids` appends the class\'s '
          'children when not')
      ..writeln('// recursive.')
      ..writeln('template <typename Build, typename Kids>')
      ..writeln('std::unique_ptr<som::SomMetaNode> metaCx('
          'const std::string& cls,')
      ..writeln('\t\tstd::vector<std::string>& stack, Build build, Kids kids) {')
      ..writeln('\tauto n = std::make_unique<som::SomMetaNode>();')
      ..writeln('\tbuild(*n);')
      ..writeln('\tfor (const auto& s : stack) {')
      ..writeln('\t\tif (s == cls) {')
      ..writeln('\t\t\tn->recursive = true;')
      ..writeln('\t\t\treturn n;')
      ..writeln('\t\t}')
      ..writeln('\t}')
      ..writeln('\tstack.push_back(cls);')
      ..writeln('\tkids(*n, stack);')
      ..writeln('\tstack.pop_back();')
      ..writeln('\treturn n;')
      ..writeln('}')
      ..writeln();
  }

  // ── children builders ───────────────────────────────────────────────────────

  /// The fields of [cls] in emission order: `@SerializationOrder` ascending,
  /// declaration index tiebreaker — identical to the bridge.
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

  void _emitChildrenBuilder(StringBuffer b, SpecClass cls) {
    // Emit the per-field statements into a scratch buffer first so we can tell
    // whether any of them reference the descent `stack` (only complex/section
    // fields and complex-element lists thread it through `metaCx`). A class
    // whose ordered fields are all leaves / scalar-lists never touches `stack`,
    // so we cast it to void to stay `-Wunused-parameter`-clean by construction.
    final fields = StringBuffer();
    for (final f in _orderedFields(cls)) {
      _emitFieldNode(fields, cls, f);
    }
    final body = fields.toString();
    b.writeln('void ${_childrenFn(cls.name)}('
        'som::SomMetaNode& parent, std::vector<std::string>& stack) {');
    // Detect a *real* use of each parameter — a whole-identifier occurrence, not
    // a substring buried in a quoted description (a form-field doc string can
    // legitimately contain the word "stack" or "parent"). Only the metaCx
    // recursion threads `stack`, and only complex/section/element fields add a
    // child via `parent.addChild`, so an all-leaf class touches neither; cast
    // the unused one(s) to void to stay `-Wunused-parameter`-clean.
    if (!_usesIdentifier(body, 'stack')) {
      b.writeln('\t(void)stack;');
    }
    if (!_usesIdentifier(body, 'parent')) {
      b.writeln('\t(void)parent;');
    }
    b
      ..write(body)
      ..writeln('}')
      ..writeln();
  }

  /// Emits the statements adding one child node for field [f] of [owner] —
  /// value-for-value the bridge's field node.
  void _emitFieldNode(StringBuffer b, SpecClass owner, SpecField f) {
    final isComplexLike =
        f.kind == SpecFieldKind.complex || f.kind == SpecFieldKind.section;
    final target = isComplexLike ? model.classNamed(f.type ?? '') : null;

    if (target != null) {
      // Complex/section: node built through the cycle helper.
      b
        ..writeln('\t{')
        ..writeln('\t\tauto n = metaCx("${_cppStr(target.name)}", stack,')
        ..writeln('\t\t\t[](som::SomMetaNode& n) {');
      _emitNodeFields(b, owner, f, target: target, recv: 'n', indent: '\t\t\t\t');
      b
        ..writeln('\t\t\t},')
        ..writeln('\t\t\t${_childrenFn(target.name)});')
        ..writeln('\t\tparent.addChild(std::move(n));')
        ..writeln('\t}');
      return;
    }

    final element = f.kind == SpecFieldKind.list && f.elementIsComplex
        ? model.classNamed(f.elementType ?? '')
        : null;
    if (element != null) {
      // List with complex element: node + element subtree via cycle helper.
      b
        ..writeln('\t{')
        ..writeln('\t\tauto ln = std::make_unique<som::SomMetaNode>();');
      _emitNodeFields(b, owner, f, target: null, recv: '(*ln)', indent: '\t\t');
      b
        ..writeln('\t\tln->elementNode = metaCx("${_cppStr(element.name)}", '
            'stack,')
        ..writeln('\t\t\t[](som::SomMetaNode& n) {');
      _emitElementFields(b, element, recv: 'n', indent: '\t\t\t\t');
      b
        ..writeln('\t\t\t},')
        ..writeln('\t\t\t${_childrenFn(element.name)});')
        ..writeln('\t\tparent.addChild(std::move(ln));')
        ..writeln('\t}');
      return;
    }

    // Leaf / scalar-list node: built inline.
    b
      ..writeln('\t{')
      ..writeln('\t\tauto n = std::make_unique<som::SomMetaNode>();');
    _emitNodeFields(b, owner, f, target: null, recv: '(*n)', indent: '\t\t');
    b
      ..writeln('\t\tparent.addChild(std::move(n));')
      ..writeln('\t}');
  }

  /// Writes the field-population statements for a normal node. [recv] is the
  /// node lvalue expression (`n` / `(*n)` / `(*ln)`); [target] is the
  /// instantiated complex/section class (null for leaves/lists).
  void _emitNodeFields(StringBuffer b, SpecClass owner, SpecField f,
      {required SpecClass? target, required String recv, required String indent}) {
    final className = target?.name ?? owner.name;
    void set(String field, String value) =>
        b.writeln('$indent$recv.$field = "${_cppStr(value)}";');
    set('className', className);
    set('memberName', f.name);
    if (f.sectionId != null) set('sectionId', f.sectionId!);
    if (target?.sectionId != null) set('classSectionId', target!.sectionId!);
    if (f.sectionIdPattern != null) set('sectionIdPattern', f.sectionIdPattern!);
    b.writeln('$indent$recv.kind = ${_kindConst(f.kind)};');
    set('typeName', f.type ?? f.elementType ?? f.enumType ?? 'String');
    if (f.serializationOrder != null) {
      b.writeln('$indent$recv.hasSerializationOrder = true;');
      b.writeln('$indent$recv.serializationOrder = ${f.serializationOrder};');
    }
    if (f.min != null) {
      b.writeln('$indent$recv.hasMin = true;');
      b.writeln('$indent$recv.min = ${f.min};');
    }
    if (f.annotation('Unused') != null) {
      b.writeln('$indent$recv.unused = true;');
    }
    if (f.contentType != null) {
      final desc =
          '${f.annotation('ContentType')?.argument('description') ?? ''}';
      b.writeln('$indent$recv.contentType = som::SomContentTypeMeta{'
          '"${_cppStr(f.contentType!)}", "${_cppStr(desc)}"};');
    }
    if (f.help != null) set('contentHelp', f.help!);
    final headline = f.headline ?? target?.headline;
    if (headline != null) set('headline', headline);
    final comment = '${f.annotation('Comment')?.argument('text') ?? ''}';
    if (comment.isNotEmpty) set('comment', comment);
    final docComment = f.doc ?? target?.doc;
    if (docComment != null) set('docComment', docComment);
    if (target?.doc != null) set('classDocComment', target!.doc!);
    if (f.kind == SpecFieldKind.form) {
      _emitForm(b, f.formFields, recv: recv, indent: indent);
    }
    if (target?.mapsTo != null) set('mapsTo', target!.mapsTo!);
    if (target?.detailedIn != null) set('detailedIn', target!.detailedIn!);
    _emitSecondLevel(b, f.annotations, recv: recv, indent: indent);
    _emitExtras(b, f.annotations, recv: recv, indent: indent);
  }

  /// Writes the field-population statements for a list's complex-element subtree
  /// node.
  void _emitElementFields(StringBuffer b, SpecClass element,
      {required String recv, required String indent}) {
    void set(String field, String value) =>
        b.writeln('$indent$recv.$field = "${_cppStr(value)}";');
    set('className', element.name);
    if (element.sectionId != null) set('classSectionId', element.sectionId!);
    b.writeln('$indent$recv.kind = som::kSomMetaKindComplex;');
    set('typeName', element.name);
    if (element.headline != null) set('headline', element.headline!);
    if (element.doc != null) {
      set('docComment', element.doc!);
      set('classDocComment', element.doc!);
    }
    if (element.mapsTo != null) set('mapsTo', element.mapsTo!);
    if (element.detailedIn != null) set('detailedIn', element.detailedIn!);
  }

  void _emitForm(StringBuffer b, List<FormFieldSpec> fields,
      {required String recv, required String indent}) {
    b.writeln('$indent$recv.form = som::SomFormMeta{};');
    for (var i = 0; i < fields.length; i++) {
      final ff = fields[i];
      // YRD7: enum-typed fields append their value domain as the final
      // aggregate member; non-enum fields let it default to an empty vector.
      final enumArg = ff.enumValues.isEmpty
          ? ''
          : ', std::vector<std::string>{'
              '${ff.enumValues.map((e) => '"${_cppStr(e)}"').join(', ')}}';
      b.writeln('$indent$recv.form->fields.push_back(som::SomFormFieldMeta{'
          '"${_cppStr(ff.name)}", "${_cppStr(ff.type)}", '
          '"${_cppStr(ff.label)}", ${ff.required}, '
          '"${_cppStr(ff.hint ?? '')}", $i, '
          '"${_cppStr(ff.role ?? '')}", "${_cppStr(ff.initial ?? '')}"'
          '$enumArg});');
    }
  }

  void _emitSecondLevel(StringBuffer b, List<SpecAnnotation> annotations,
      {required String recv, required String indent}) {
    final entries = [
      for (final a in annotations)
        if (a.name == 'SecondLevelSectionId')
          [
            '${a.argument('documentClass') ?? ''}',
            '${a.argument('id') ?? ''}',
          ],
    ];
    for (final e in entries) {
      b.writeln('$indent$recv.secondLevelIds.push_back(som::SomSecondLevelId{'
          '"${_cppStr(e[0])}", "${_cppStr(e[1])}"});');
    }
  }

  void _emitExtras(StringBuffer b, List<SpecAnnotation> annotations,
      {required String recv, required String indent}) {
    final entries = [
      for (final a in annotations)
        if (!_slottedAnnotations.contains(a.name)) a,
    ];
    for (final a in entries) {
      // Extra.args mirrors the bridge's parsed constructor arguments (which the
      // bridge *borrows* from the live SpecModel source). The generated tree has
      // no live model to borrow from, so it parses an equivalent JSON literal
      // once; somMetaNodeDiff compares args by value (order-independent for
      // objects), so a byte-for-byte match with the bridge is not required.
      final lit = _cppStr(jsonEncode(a.arguments));
      b.writeln('$indent$recv.extra.push_back(som::SomMetaExtra{'
          '"${_cppStr(a.name)}", som::jsonParse("$lit", nullptr)});');
    }
  }

  // ── per-root emission ───────────────────────────────────────────────────────

  void _emitRoot(StringBuffer b, SpecRoot root) {
    final cls = model.classNamed(root.type);
    final seg = _ref.rootSegment(root);
    final treeFn = _treeFn(root.type);

    // Root node build function (populates a node like a child node, but with
    // @Document metadata and children built directly).
    b.writeln('const som::SomMetaTree& $treeFn() {');
    b.writeln('\tstatic const std::unique_ptr<som::SomMetaTree> cached = []() {');
    b.writeln('\t\tauto n = std::make_unique<som::SomMetaNode>();');
    b.writeln('\t\tn->className = "${_cppStr(root.type)}";');
    final sectionId = root.sectionId ?? cls?.sectionId;
    if (sectionId != null) {
      b.writeln('\t\tn->sectionId = "${_cppStr(sectionId)}";');
    }
    if (cls?.sectionId != null) {
      b.writeln('\t\tn->classSectionId = "${_cppStr(cls!.sectionId!)}";');
    }
    b.writeln('\t\tn->kind = som::kSomMetaKindSection;');
    b.writeln('\t\tn->typeName = "${_cppStr(root.type)}";');
    if (cls?.headline != null) {
      b.writeln('\t\tn->headline = "${_cppStr(cls!.headline!)}";');
    }
    final doc = root.doc ?? cls?.doc;
    if (doc != null) {
      b.writeln('\t\tn->docComment = "${_cppStr(doc)}";');
    }
    if (cls?.doc != null) {
      b.writeln('\t\tn->classDocComment = "${_cppStr(cls!.doc!)}";');
    }
    if (cls?.mapsTo != null) {
      b.writeln('\t\tn->mapsTo = "${_cppStr(cls!.mapsTo!)}";');
    }
    if (cls?.detailedIn != null) {
      b.writeln('\t\tn->detailedIn = "${_cppStr(cls!.detailedIn!)}";');
    }
    // @Document metadata.
    final basedOn = _basedOn(cls);
    b.writeln('\t\tn->document = som::SomDocMeta{};');
    b.writeln('\t\tn->document->name = "${_cppStr(root.title)}";');
    b.writeln('\t\tn->document->description = '
        '"${_cppStr(root.description ?? '')}";');
    for (final base in basedOn) {
      b.writeln('\t\tn->document->basedOn.push_back("${_cppStr(base)}");');
    }
    _emitSecondLevel(b, cls?.annotations ?? const [],
        recv: '(*n)', indent: '\t\t');
    _emitExtras(b, cls?.annotations ?? const [], recv: '(*n)', indent: '\t\t');
    if (cls != null) {
      b
        ..writeln('\t\tstd::vector<std::string> stack;')
        ..writeln('\t\tstack.push_back("${_cppStr(root.type)}");')
        ..writeln('\t\t${_childrenFn(root.type)}(*n, stack);');
    }
    b.writeln('\t\treturn som::SomMetaTree::create(std::move(n));');
    b.writeln('\t}();');
    b.writeln('\treturn *cached;');
    b.writeln('}');

    // Entry points binding the surface roots to the tree + root segment path.
    b
      ..writeln('${_navType(root.type)} ${_rootNavFn(root)}('
          'const som::SomMetaTree& tree) {')
      ..writeln('\treturn ${_navType(root.type)}{'
          'som::SomMetaRef(&tree, "${_cppStr(seg)}")};')
      ..writeln('}')
      ..writeln('${_idType(root.type)} ${_rootIdFn(root)}('
          'const som::SomMetaTree& tree) {')
      ..writeln('\treturn ${_idType(root.type)}{'
          'som::SomMetaRef(&tree, "${_cppStr(seg)}")};')
      ..writeln('}')
      ..writeln();
  }

  List<String> _basedOn(SpecClass? cls) {
    final raw = cls?.annotation('Document')?.argument('basedOn');
    if (raw is List) return raw.map((e) => '$e').toList();
    return const [];
  }

  // ── dot-notation accessors (§4.1) ───────────────────────────────────────────

  void _emitNavAccessors(StringBuffer b, SpecClass cls) {
    final used = <String>{};
    for (final f in _orderedFields(cls)) {
      final acc = _navFn(used, cls.name, f);
      final seg = _ref.fieldSegment(f);
      final ret = _navReturn(f);
      b.writeln('$ret $acc(${_navType(cls.name)} x) {');
      _emitNavBody(b, f, seg);
      b.writeln('}');
    }
  }

  void _emitIdAccessors(StringBuffer b, SpecClass cls) {
    for (final child in _idChildren(cls)) {
      final ret = _idReturn(child);
      b.writeln('$ret ${_idFn(cls.name, child)}(${_idType(cls.name)} x) {');
      _emitIdBody(b, child);
      b.writeln('}');
    }
  }

  /// Emits an accessor body building the child ref/struct at
  /// `x.ref.path + "/" + seg`.
  void _emitNavBody(StringBuffer b, SpecField f, String seg) {
    switch (f.kind) {
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = model.classNamed(f.type ?? '');
        if (target != null) {
          _emitChildStruct(b, _navType(target.name), seg);
          return;
        }
        _emitLeaf(b, seg);
        return;
      case SpecFieldKind.list:
        final element =
            f.elementIsComplex ? model.classNamed(f.elementType ?? '') : null;
        _emitList(b, seg, element == null ? null : _navFactory(element.name));
        return;
      case SpecFieldKind.form:
      case SpecFieldKind.content:
      case SpecFieldKind.enumValue:
      case SpecFieldKind.scalar:
        _emitLeaf(b, seg);
        return;
    }
  }

  void _emitIdBody(StringBuffer b, _IdChild child) {
    if (child.isList) {
      final elem = child.targetClass;
      _emitList(b, child.relPath, elem == null ? null : _idFactory(elem));
      return;
    }
    if (child.targetClass != null) {
      _emitChildStruct(b, _idType(child.targetClass!), child.relPath);
      return;
    }
    _emitLeaf(b, child.relPath);
  }

  void _emitChildStruct(StringBuffer b, String type, String seg) {
    b.writeln('\treturn $type{som::SomMetaRef(x.ref.tree, '
        'som::specPathJoin(x.ref.path, "${_cppStr(seg)}"))};');
  }

  void _emitLeaf(StringBuffer b, String seg) {
    b.writeln('\treturn som::SomMetaRef(x.ref.tree, '
        'som::specPathJoin(x.ref.path, "${_cppStr(seg)}"));');
  }

  void _emitList(StringBuffer b, String seg, String? factory) {
    final fac = factory ?? _leafFactory();
    b.writeln('\treturn som::SomListMetaRef(x.ref.tree, '
        'som::specPathJoin(x.ref.path, "${_cppStr(seg)}"), $fac);');
  }

  // ── factories (som::SomMetaRefFactory) ──────────────────────────────────────

  final Set<String> _navFactoriesUsed = {};
  final Set<String> _idFactoriesUsed = {};
  bool _leafFactoryUsed = false;

  String _leafFactory() {
    _leafFactoryUsed = true;
    return 'metaLeafFactory';
  }

  String _navFactory(String cls) {
    _navFactoriesUsed.add(cls);
    return _navFactoryFn(cls);
  }

  String _idFactory(String cls) {
    _idFactoriesUsed.add(cls);
    return _idFactoryFn(cls);
  }

  String _navFactoryFn(String cls) => 'metaNavFactory${_pascal(cls)}';
  String _idFactoryFn(String cls) => 'metaIdFactory${_pascal(cls)}';

  // ── §4.2 ID-tree children ───────────────────────────────────────────────────

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

  // ── name helpers ────────────────────────────────────────────────────────────

  String _navType(String cls) => 'Nav${_pascal(cls)}';
  /// Whether the emitted children-builder [body] uses [ident] as a real C++
  /// identifier — i.e. a whole-word occurrence *outside* any double-quoted
  /// string literal. Form-field descriptions are emitted as quoted literals and
  /// may legitimately contain words like "stack" or "parent"; those must not
  /// count as a use of the parameter, or the `(void)` guard is skipped and the
  /// build trips `-Wunused-parameter`. Strips string literals first, then does a
  /// word-boundary match on what remains.
  bool _usesIdentifier(String body, String ident) {
    final stripped = body.replaceAll(RegExp(r'"(\\.|[^"\\])*"'), '');
    return RegExp('(?<![A-Za-z0-9_])$ident(?![A-Za-z0-9_])').hasMatch(stripped);
  }

  String _idType(String cls) => 'Id${_pascal(cls)}';
  String _childrenFn(String cls) => 'build${_pascal(cls)}Children';
  String _treeFn(String rootType) => '${_camel(rootType)}MetaTree';
  String _rootNavFn(SpecRoot root) => '${_camel(root.type)}MetaNav';
  String _rootIdFn(SpecRoot root) => '${_camel(root.type)}MetaId';

  String _navFn(Set<String> used, String cls, SpecField f) {
    var base = 'nav${_pascal(cls)}_${_memberTail(f.name)}';
    var cand = base;
    var n = 2;
    while (!used.add(cand)) {
      cand = '${base}_$n';
      n++;
    }
    return cand;
  }

  String _idFn(String cls, _IdChild child) =>
      'id${_pascal(cls)}_${child.name}';

  String _navReturn(SpecField f) {
    switch (f.kind) {
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = model.classNamed(f.type ?? '');
        return target != null ? _navType(target.name) : 'som::SomMetaRef';
      case SpecFieldKind.list:
        return 'som::SomListMetaRef';
      case SpecFieldKind.form:
      case SpecFieldKind.content:
      case SpecFieldKind.enumValue:
      case SpecFieldKind.scalar:
        return 'som::SomMetaRef';
    }
  }

  String _idReturn(_IdChild child) {
    if (child.isList) return 'som::SomListMetaRef';
    if (child.targetClass != null) return _idType(child.targetClass!);
    return 'som::SomMetaRef';
  }

  /// A section id as a C++ identifier tail: `-` → `_`; digit-leading ids
  /// prefixed with `id`; a keyword collision gains a trailing underscore.
  String _idName(String id) {
    var name = id.replaceAll('-', '_');
    if (RegExp(r'^[0-9]').hasMatch(name)) name = 'id$name';
    if (_cppKeywords.contains(name)) name = '${name}_';
    return name;
  }

  /// A member name as a legal C++ identifier tail. Empty ⇒ `field`; keyword
  /// gains a trailing underscore. Non-identifier chars become `_`.
  String _memberTail(String name) {
    var base = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (base.isEmpty) base = 'field';
    if (RegExp(r'^[0-9]').hasMatch(base)) base = 'm$base';
    if (_cppKeywords.contains(base)) base = '${base}_';
    return base;
  }

  // ── text helpers ────────────────────────────────────────────────────────────

  void _banner(StringBuffer b, String which) {
    b
      ..writeln('// GENERATED by tom_specs_clitool SomCppMetaEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('// The populated SOM metadata trees (DR1 §3.2) and the two '
          'access surfaces of')
      ..writeln('// DR1 §4: the dot-notation tree (member names) and the '
          'ID-tree (section ids).')
      ..writeln('// ($which)')
      ..writeln();
  }

  String _cppStr(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  String _kindConst(SpecFieldKind kind) {
    switch (kind) {
      case SpecFieldKind.list:
        return 'som::kSomMetaKindList';
      case SpecFieldKind.form:
        return 'som::kSomMetaKindForm';
      case SpecFieldKind.section:
        return 'som::kSomMetaKindSection';
      case SpecFieldKind.content:
        return 'som::kSomMetaKindContent';
      case SpecFieldKind.enumValue:
        return 'som::kSomMetaKindEnumValue';
      case SpecFieldKind.complex:
        return 'som::kSomMetaKindComplex';
      case SpecFieldKind.scalar:
        return 'som::kSomMetaKindScalar';
    }
  }

  /// PascalCase of an identifier (splitting on `_`, ` `, `-`, and preserving
  /// existing internal capitals). Non-alnum chars are dropped.
  String _pascal(String s) {
    final parts = s.split(RegExp(r'[_\s-]+')).where((p) => p.isNotEmpty);
    final buf = StringBuffer();
    for (final p in parts) {
      buf.write(p[0].toUpperCase());
      buf.write(p.substring(1));
    }
    return buf.toString().replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  }

  /// camelCase — Pascal with a lowercased leading char.
  String _camel(String s) {
    final p = _pascal(s);
    if (p.isEmpty) return p;
    return p[0].toLowerCase() + p.substring(1);
  }
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
