/// Emits the generated **metadata module** of the C `v0` facade (the C
/// counterpart of `som_go_meta_emitter.dart` / `som_dart_meta_emitter.dart` /
/// the other language meta emitters): the populated `SomMetaTree`s built as
/// generated data (SOM §7.2) plus the two discoverable access surfaces of SOM
/// SOM §8 — the **dot-notation tree** (model member names) and the **ID-tree**
/// (section ids, SOM §8). Together they are the facade's **only**
/// path-addressing surface — there is no flat per-root `#define` constant
/// holder, because a constant cannot express a dynamic path (typed prefix
/// plus runtime-computed tail).
///
/// The emitted node values mirror `tom_som_c_runtime`'s `som_build_meta_tree`
/// (the meta-JSON bridge) **field for field**, sourced from the same
/// [SpecModel], so the generated trees and the bridge-built trees are
/// structurally identical — the facade meta test asserts this with
/// `SomMetaNodeDiff`. Cycle handling matches the bridge: a class already on the
/// descent stack becomes a terminal re-entry node (`recursive = 1`), which the
/// generated `meta_cx` helper reproduces at tree-construction time.
///
/// C-specific shape (no classes/methods/generics/namespaces):
///
///   * the runtime `SomMetaNode` owns its string fields (freed by
///     `som_meta_tree_free`), so the tree cannot be a `const` static composite
///     literal; it is **built at first use** by generated `meta_children_<Class>`
///     functions that allocate nodes with `som_meta_node_new()` and populate the
///     owned fields with `som_strdup`, then wired by a `must_meta_tree` helper.
///     Each root exposes a lazily-cached `const SomMetaTree *<root>_meta_tree(void)`.
///   * the two access surfaces are structs-over-`SomMetaRef` (SOM §8 generated
///     accessor support): `som_nav_<Class>` / `som_id_<Class>` each wrap one
///     `SomMetaRef` (tree + absolute path). Every navigable position is one
///     accessor **function** `<class>_nav_<member>(x)` (dot-notation) /
///     `<class>_id_<SECTION_ID>(x)` (ID-tree) returning the next nav/id struct
///     by value, a `SomMetaRef` for leaves, or a `SomListMetaRef` for lists
///     (whose `element` factory builds the element class's nav/id accessor).
///     Both surfaces resolve to the SAME node and byte-identical `.path`.
///   * C has one flat namespace, so every emitted type / function name is
///     globally unique; a generation-time guard fails loudly on any collision
///     with a facade-owned identifier derived from the same model.
///
/// Per document root the module tail declares the tree accessor
/// `<root>_meta_tree`, the dot-notation entry `<root>_meta` and the ID-tree
/// entry `<ROOT_SEGMENT>` (`SBP`, `CLA`, …). Both entry points take the tree
/// pointer and return the root nav/id struct by value.
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
};

/// Emits the C source of the generated metadata module (see the library doc
/// above) for [model]. Produces a header/source pair via [generateHeader] /
/// [generateSource]; both share one deterministic name allocation.
class SomCMetaEmitter {
  final SpecModel model;
  final String versionLabel;
  final List<String> documentRoots;

  final SpecReflection _ref;

  /// The generated header basename (for the source's `#include`).
  static const String _headerBasename = 'tom_som_c_v0_meta.h';
  static const String _headerGuard = 'TOM_SOM_C_V0_META_H';

  SomCMetaEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
  }) : _ref = SpecReflection(model);

  List<SpecRoot> get _roots {
    if (documentRoots.isEmpty) return model.roots;
    final wanted = documentRoots.toSet();
    return model.roots.where((r) => wanted.contains(r.type)).toList();
  }

  /// Reserved C keywords (C11); a section-id-derived accessor tail matching one
  /// gains a trailing underscore so it stays a legal identifier.
  static const Set<String> _cKeywords = {
    'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do',
    'double', 'else', 'enum', 'extern', 'float', 'for', 'goto', 'if', 'inline',
    'int', 'long', 'register', 'restrict', 'return', 'short', 'signed',
    'sizeof', 'static', 'struct', 'switch', 'typedef', 'union', 'unsigned',
    'void', 'volatile', 'while',
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

  /// Builds the generated header (`tom_som_c_v0_meta.h`).
  String generateHeader() {
    final b = StringBuffer();
    _banner(b, 'header');
    b
      ..writeln('#ifndef $_headerGuard')
      ..writeln('#define $_headerGuard')
      ..writeln()
      ..writeln('#include "tom_som_c_runtime.h"')
      ..writeln();

    final navClasses = _navClasses;
    final idClasses = _idClasses;

    // Access-surface struct typedefs. Each wraps one SomMetaRef; accessors take
    // it by value and return the next surface struct / ref by value.
    b
      ..writeln('/* ── dot-notation access surface structs (SOM §8) '
          '───────────────────────── */')
      ..writeln('/* Each wraps one SomMetaRef (tree + absolute path). Accessors '
          'return the next */')
      ..writeln('/* navigable position by value; `.ref.path` is the absolute '
          'document path and */')
      ..writeln('/* som_meta_ref_meta(&x.ref, &err) the metadata node. */');
    for (final n in navClasses) {
      b.writeln('typedef struct { SomMetaRef ref; } ${_navType(n)};');
    }
    b.writeln();
    b
      ..writeln('/* ── ID-tree access surface structs (SOM §8) '
          '─────────────────────────────── */')
      ..writeln('/* The same tree keyed by section id (`-` → `_`). `.ref.path` '
          'and the metadata */')
      ..writeln('/* node agree with the dot-notation surface for every '
          'position. */');
    for (final n in idClasses) {
      b.writeln('typedef struct { SomMetaRef ref; } ${_idType(n)};');
    }
    b.writeln();

    // Dot-notation accessor declarations.
    b.writeln('/* ── dot-notation accessors (SOM §8) '
        '─────────────────────────────────────── */');
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
    b.writeln('/* ── ID-tree accessors (SOM §8) '
        '──────────────────────────────────────────── */');
    for (final n in idClasses) {
      final cls = model.classNamed(n)!;
      for (final child in _idChildren(cls)) {
        b.writeln('${_idReturn(child)} ${_idFn(n, child)}('
            '${_idType(n)} x);');
      }
    }
    b.writeln();

    // Per-root entry points.
    b.writeln('/* ── document-root metadata trees + access surface entry points '
        '─────────── */');
    for (final root in _roots) {
      final treeFn = _treeFn(root.type);
      b
        ..writeln('/* The populated `${root.type}` metadata tree (SOM §7.2), '
            'built + cached on first')
        ..writeln(' * call and owned by this module. */')
        ..writeln('const SomMetaTree *$treeFn(void);')
        ..writeln('/* The dot-notation access root of `${root.type}` (SOM §8): '
            '`<root>_nav_<Member>`. */')
        ..writeln('${_navType(root.type)} ${_rootNavFn(root)}('
            'const SomMetaTree *tree);')
        ..writeln('/* The ID-tree access root of `${root.type}` (SOM §8): '
            '`<root>_id_<SECTION_ID>`. */')
        ..writeln('${_idType(root.type)} ${_rootIdFn(root)}('
            'const SomMetaTree *tree);');
    }
    b.writeln();

    _emitRootRegistryDecl(b);

    b.writeln('#endif /* $_headerGuard */');
    return b.toString().replaceAll('\t', '  ');
  }

  /// Declares the document-root registry: the full root set as generated data.
  ///
  /// Without it every consumer has to hand-list the roots — and a hand-list is
  /// only ever as current as the last person who remembered it. The registry
  /// makes the root set a generated fact, so a new document root reaches every
  /// consumer by regeneration rather than by recollection.
  void _emitRootRegistryDecl(StringBuffer b) {
    b
      ..writeln('/* ── document-root registry (SOM §8) '
          '──────────────────────────────────── */')
      ..writeln('/* One document root: its class name, the path segment its '
          'access roots are */')
      ..writeln('/* bound at, the populated metadata tree (SOM §7.2), and the '
          'two SOM §8 */')
      ..writeln('/* access roots as the common SomMetaRef the accessor structs '
          'wrap. */')
      ..writeln('typedef struct {')
      ..writeln('\tconst char *type;')
      ..writeln('\tconst char *segment;')
      ..writeln('\tconst SomMetaTree *tree;')
      ..writeln('\tSomMetaRef nav;')
      ..writeln('\tSomMetaRef id;')
      ..writeln('} SomMetaRootEntry;')
      ..writeln()
      ..writeln('/* The number of document roots som_meta_roots fills in. '
          'Named so a caller\'s */')
      ..writeln('/* array cannot silently be one short of the registry when a '
          'root is added — */')
      ..writeln('/* C has no bounds check to catch it. */')
      ..writeln('#define SOM_META_ROOT_COUNT ${_roots.length}')
      ..writeln()
      ..writeln('/* Fills `out` with every document root, in model order, and '
          'returns the number */')
      ..writeln('/* written — at most `cap`, so a caller sized to an older '
          'SOM_META_ROOT_COUNT */')
      ..writeln('/* truncates rather than overruns. Generated from the same '
          'root list that */')
      ..writeln('/* produced the trees above, so no consumer needs a hand-kept '
          'copy of the */')
      ..writeln('/* root set. */')
      ..writeln('/* */')
      ..writeln('/* OWNERSHIP: each filled entry\'s `nav` and `id` own their '
          'path buffers — the */')
      ..writeln('/* caller releases both with som_meta_ref_free. `tree` is '
          'static and is not */')
      ..writeln('/* freed. */')
      ..writeln('size_t som_meta_roots(SomMetaRootEntry *out, size_t cap);')
      ..writeln();
  }

  /// Defines the registry declared by [_emitRootRegistryDecl].
  void _emitRootRegistryDef(StringBuffer b) {
    b
      ..writeln('/* ── document-root registry (SOM §8) '
          '──────────────────────────────────── */')
      ..writeln('size_t som_meta_roots(SomMetaRootEntry *out, size_t cap) {')
      ..writeln('\tsize_t i = 0;');
    for (final root in _roots) {
      final seg = _ref.rootSegment(root);
      b
        ..writeln('\tif (i < cap) {')
        ..writeln('\t\tconst SomMetaTree *t = ${_treeFn(root.type)}();')
        ..writeln('\t\tout[i].type = "${_cStr(root.type)}";')
        ..writeln('\t\tout[i].segment = "${_cStr(seg)}";')
        ..writeln('\t\tout[i].tree = t;')
        ..writeln('\t\tout[i].nav = ${_rootNavFn(root)}(t).ref;')
        ..writeln('\t\tout[i].id = ${_rootIdFn(root)}(t).ref;')
        ..writeln('\t\ti++;')
        ..writeln('\t}');
    }
    b
      ..writeln('\treturn i;')
      ..writeln('}')
      ..writeln();
  }

  // ── source ──────────────────────────────────────────────────────────────────

  /// Builds the generated source (`tom_som_c_v0_meta.c`).
  String generateSource() {
    _pendingBuilds.clear();
    _buildFnNames.clear();
    _navFactoriesUsed.clear();
    _idFactoriesUsed.clear();
    _leafFactoryUsed = false;

    // First emit the children-builders + accessors into scratch buffers; this
    // populates the pending build-fn / factory sets that the forward decls and
    // definitions below depend on.
    final buildersBuf = StringBuffer();
    for (final n in _navClasses) {
      _emitChildrenBuilder(buildersBuf, model.classNamed(n)!);
    }
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
      ..writeln('#include <stdlib.h>')
      ..writeln('#include <string.h>')
      ..writeln();

    _emitHelpers(b);

    // Forward declarations of every child builder and node build function
    // (mutual recursion, any emission order).
    b.writeln('/* ── metadata tree builders (SOM §7.2) — forward decls '
        '──────────────────── */');
    for (final n in _navClasses) {
      b.writeln('static SomMetaNode **${_childrenFn(n)}('
          'SomStrList *stack, size_t *len);');
    }
    for (final pb in _pendingBuilds) {
      b.writeln('static void ${pb.fnName}(SomMetaNode *n);');
    }
    b.writeln();

    // Element-accessor factories (used by list accessors).
    _emitFactories(b);

    // Node build functions.
    b.writeln('/* ── node build functions ─────────────────────────────────'
        '────────────────── */');
    for (final pb in _pendingBuilds) {
      b
        ..writeln('static void ${pb.fnName}(SomMetaNode *n) {')
        ..write(pb.body())
        ..writeln('}');
    }
    b.writeln();

    // Children builders.
    b.writeln('/* ── metadata tree builders (SOM §7.2) '
        '───────────────────────────────────── */');
    b.write(buildersBuf.toString());

    // Per-root tree accessors (lazy cached) + entry points.
    b.writeln('/* ── document-root trees + access surface entry points '
        '─────────────────── */');
    for (final root in _roots) {
      _emitRoot(b, root);
    }

    // Dot-notation accessor definitions.
    b.writeln('/* ── dot-notation accessors (SOM §8) '
        '─────────────────────────────────────── */');
    b.write(navBuf.toString());

    // ID-tree accessor definitions.
    b.writeln('/* ── ID-tree accessors (SOM §8) '
        '──────────────────────────────────────────── */');
    b.write(idBuf.toString());

    _emitRootRegistryDef(b);

    return b.toString().replaceAll('\t', '  ');
  }

  /// Emits the `SomMetaRefFactory` definitions referenced by list accessors:
  /// the shared leaf factory (scalar-element lists) plus one nav/id factory per
  /// complex element class actually referenced.
  void _emitFactories(StringBuffer b) {
    b.writeln('/* ── element-accessor factories (SomMetaRefFactory) '
        '─────────────────────── */');
    // Shared leaf factory: an owned SomMetaRef for a scalar list item. Only
    // emitted when a scalar-element list accessor actually references it, so
    // the definition never triggers `-Wunused-function` on models whose list
    // accessors all carry complex-element factories.
    if (_leafFactoryUsed) {
      b
        ..writeln('static void *meta_leaf_factory(const SomMetaTree *tree, '
            'const char *path) {')
        ..writeln('\tSomMetaRef *r = (SomMetaRef *)malloc(sizeof(SomMetaRef));')
        ..writeln('\tsom_meta_ref_init(r, tree, path);')
        ..writeln('\treturn r;')
        ..writeln('}');
    }
    final navFacs = _navFactoriesUsed.toList()..sort();
    for (final cls in navFacs) {
      b
        ..writeln('static void *meta_nav_factory_${_snake(cls)}('
            'const SomMetaTree *tree, const char *path) {')
        ..writeln('\t${_navType(cls)} *r = (${_navType(cls)} *)malloc('
            'sizeof(${_navType(cls)}));')
        ..writeln('\tsom_meta_ref_init(&r->ref, tree, path);')
        ..writeln('\treturn r;')
        ..writeln('}');
    }
    final idFacs = _idFactoriesUsed.toList()..sort();
    for (final cls in idFacs) {
      b
        ..writeln('static void *meta_id_factory_${_snake(cls)}('
            'const SomMetaTree *tree, const char *path) {')
        ..writeln('\t${_idType(cls)} *r = (${_idType(cls)} *)malloc('
            'sizeof(${_idType(cls)}));')
        ..writeln('\tsom_meta_ref_init(&r->ref, tree, path);')
        ..writeln('\treturn r;')
        ..writeln('}');
    }
    b.writeln();
  }

  // ── helpers block ───────────────────────────────────────────────────────────

  void _emitHelpers(StringBuffer b) {
    b
      ..writeln('/* A growable SomMetaNode* array used while building children '
          'lists. */')
      ..writeln('static void meta_push(SomMetaNode ***arr, size_t *len, '
          'size_t *cap, SomMetaNode *n) {')
      ..writeln('\tif (*len == *cap) {')
      ..writeln('\t\t*cap = *cap ? *cap * 2 : 4;')
      ..writeln('\t\t*arr = (SomMetaNode **)realloc(*arr, '
          '*cap * sizeof(SomMetaNode *));')
      ..writeln('\t}')
      ..writeln('\t(*arr)[(*len)++] = n;')
      ..writeln('}')
      ..writeln()
      ..writeln('/* Sets an owned string field (frees the node\'s current "" '
          'placeholder first). */')
      ..writeln('static void meta_set(char **field, const char *value) {')
      ..writeln('\tfree(*field);')
      ..writeln('\t*field = som_strdup(value);')
      ..writeln('}')
      ..writeln()
      ..writeln('/* meta_cx applies the bridge cycle rule: a class already on '
          'the descent stack')
      ..writeln(' * becomes a terminal re-entry node (recursive = 1, no '
          'children). `build` fills a')
      ..writeln(' * freshly-allocated node; `kids` appends the class\'s children '
          'when not recursive. */')
      ..writeln('static SomMetaNode *meta_cx(const char *cls, SomStrList *stack,')
      ..writeln('\t\tSomMetaNode **(*kids)(SomStrList *, size_t *),')
      ..writeln('\t\tvoid (*build)(SomMetaNode *)) {')
      ..writeln('\tSomMetaNode *n = som_meta_node_new();')
      ..writeln('\tbuild(n);')
      ..writeln('\tif (som_strlist_contains(stack, cls)) {')
      ..writeln('\t\tn->recursive = 1;')
      ..writeln('\t\treturn n;')
      ..writeln('\t}')
      ..writeln('\tsom_strlist_push_copy(stack, cls);')
      ..writeln('\tsize_t clen = 0;')
      ..writeln('\tSomMetaNode **c = kids(stack, &clen);')
      ..writeln('\tsom_strlist_remove_at(stack, stack->len - 1);')
      ..writeln('\tfor (size_t i = 0; i < clen; i++) {')
      ..writeln('\t\tsom_meta_node_add_child(n, c[i]);')
      ..writeln('\t}')
      ..writeln('\tfree(c);')
      ..writeln('\treturn n;')
      ..writeln('}')
      ..writeln()
      ..writeln('/* Wires a generated root node into its SomMetaTree. The '
          'generated data is correct')
      ..writeln(' * by construction, so a wiring failure marks an emitter bug '
          '— abort loudly. */')
      ..writeln('static SomMetaTree *must_meta_tree(SomMetaNode *root) {')
      ..writeln('\tchar *err = NULL;')
      ..writeln('\tSomMetaTree *t = som_meta_tree_new(root, &err);')
      ..writeln('\tif (t == NULL) {')
      ..writeln('\t\tabort();')
      ..writeln('\t}')
      ..writeln('\treturn t;')
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
    // fields and complex-element lists thread it through `meta_cx`). A class
    // whose ordered fields are all leaves / scalar-lists never touches `stack`,
    // so we cast it to void to stay `-Wunused-parameter`-clean by construction.
    final fields = StringBuffer();
    for (final f in _orderedFields(cls)) {
      _emitFieldNode(fields, cls, f);
    }
    final body = fields.toString();
    b.writeln('static SomMetaNode **${_childrenFn(cls.name)}('
        'SomStrList *stack, size_t *len) {');
    // `stack` is only *used* when a field threads it into `meta_cx(...)` — the
    // sole call site passes it as the exact ` stack,` argument token. Matching
    // that token (rather than a bare `stack` substring) avoids a false positive
    // when a build-fn identifier merely embeds a class name containing "stack"
    // (e.g. `meta_build_tooling_stack_content`). Leaf-only builders never emit
    // the token, so they get the `(void)stack;` cast → `-Wunused-parameter`-safe.
    if (!body.contains(', stack,')) {
      b.writeln('\t(void)stack;');
    }
    b
      ..writeln('\tSomMetaNode **arr = NULL;')
      ..writeln('\tsize_t cap = 0;')
      ..writeln('\t*len = 0;')
      ..write(body)
      ..writeln('\treturn arr;')
      ..writeln('}')
      ..writeln();
  }

  /// Emits the statements pushing one child node for field [f] of [owner] —
  /// value-for-value the bridge's field node.
  void _emitFieldNode(StringBuffer b, SpecClass owner, SpecField f) {
    final isComplexLike =
        f.kind == SpecFieldKind.complex || f.kind == SpecFieldKind.section;
    final target = isComplexLike ? model.classNamed(f.type ?? '') : null;

    if (target != null) {
      // Complex/section: node built through the cycle helper via a build fn.
      final buildFn = _uniqueBuildFn(owner, f);
      b.writeln('\tmeta_push(&arr, len, &cap, '
          'meta_cx("${_cStr(target.name)}", stack, '
          '${_childrenFn(target.name)}, $buildFn));');
      _pendingBuilds.add(_PendingBuild(buildFn, () {
        final body = StringBuffer();
        _emitNodeFields(body, owner, f, target: target);
        return body.toString();
      }));
      return;
    }

    final element = f.kind == SpecFieldKind.list && f.elementIsComplex
        ? model.classNamed(f.elementType ?? '')
        : null;
    if (element != null) {
      // List with complex element: node + element subtree via cycle helper.
      final nodeBuildFn = _uniqueBuildFn(owner, f);
      final elemBuildFn = '${nodeBuildFn}_elem';
      b
        ..writeln('\t{')
        ..writeln('\t\tSomMetaNode *ln = som_meta_node_new();')
        ..writeln('\t\t$nodeBuildFn(ln);')
        ..writeln('\t\tln->element_node = meta_cx("${_cStr(element.name)}", '
            'stack, ${_childrenFn(element.name)}, $elemBuildFn);')
        ..writeln('\t\tmeta_push(&arr, len, &cap, ln);')
        ..writeln('\t}');
      _pendingBuilds.add(_PendingBuild(nodeBuildFn, () {
        final body = StringBuffer();
        _emitNodeFields(body, owner, f, target: null);
        return body.toString();
      }));
      _pendingBuilds.add(_PendingBuild(elemBuildFn, () {
        final body = StringBuffer();
        _emitElementFields(body, element);
        return body.toString();
      }));
      return;
    }

    // Leaf / scalar-list node: built inline.
    final leafBuildFn = _uniqueBuildFn(owner, f);
    b.writeln('\t{');
    b.writeln('\t\tSomMetaNode *n = som_meta_node_new();');
    b.writeln('\t\t$leafBuildFn(n);');
    b.writeln('\t\tmeta_push(&arr, len, &cap, n);');
    b.writeln('\t}');
    _pendingBuilds.add(_PendingBuild(leafBuildFn, () {
      final body = StringBuffer();
      _emitNodeFields(body, owner, f, target: null);
      return body.toString();
    }));
  }

  /// Emits the `build`-function bodies deferred while walking the children
  /// (each populates a `SomMetaNode *n`). Appended after all builders.
  final List<_PendingBuild> _pendingBuilds = [];

  /// A unique build-function name for the node of [f] in [owner].
  String _uniqueBuildFn(SpecClass owner, SpecField f) {
    final base = 'meta_build_${_snake(owner.name)}_${_snake(f.name)}';
    var cand = base;
    var n = 2;
    while (!_buildFnNames.add(cand)) {
      cand = '${base}_$n';
      n++;
    }
    return cand;
  }

  final Set<String> _buildFnNames = {};

  /// Writes the field-population statements for a normal node (`SomMetaNode *n`
  /// / the parameter named by the caller). [target] is the instantiated
  /// complex/section class (null for leaves/lists).
  void _emitNodeFields(StringBuffer b, SpecClass owner, SpecField f,
      {required SpecClass? target}) {
    final className = target?.name ?? owner.name;
    b.writeln('\tmeta_set(&n->class_name, "${_cStr(className)}");');
    b.writeln('\tmeta_set(&n->member_name, "${_cStr(f.name)}");');
    if (f.sectionId != null) {
      b.writeln('\tmeta_set(&n->section_id, "${_cStr(f.sectionId!)}");');
    }
    if (target?.sectionId != null) {
      b.writeln('\tmeta_set(&n->class_section_id, '
          '"${_cStr(target!.sectionId!)}");');
    }
    if (f.sectionIdPattern != null) {
      b.writeln('\tmeta_set(&n->section_id_pattern, '
          '"${_cStr(f.sectionIdPattern!)}");');
    }
    b.writeln('\tn->kind = ${_kindConst(f.kind)};');
    b.writeln('\tmeta_set(&n->type_name, '
        '"${_cStr(f.type ?? f.elementType ?? f.enumType ?? 'String')}");');
    if (f.serializationOrder != null) {
      b.writeln('\tn->has_serialization_order = 1;');
      b.writeln('\tn->serialization_order = ${f.serializationOrder};');
    }
    if (f.min != null) {
      b.writeln('\tn->has_min = 1;');
      b.writeln('\tn->min = ${f.min};');
    }
    if (f.annotation('Unused') != null) b.writeln('\tn->unused = 1;');
    if (f.contentType != null) {
      final desc =
          '${f.annotation('ContentType')?.argument('description') ?? ''}';
      b
        ..writeln('\tn->content_type = (SomContentTypeMeta *)'
            'calloc(1, sizeof(SomContentTypeMeta));')
        ..writeln('\tn->content_type->type = som_strdup('
            '"${_cStr(f.contentType!)}");')
        ..writeln('\tn->content_type->description = som_strdup('
            '"${_cStr(desc)}");');
    }
    if (f.help != null) {
      b.writeln('\tmeta_set(&n->content_help, "${_cStr(f.help!)}");');
    }
    final headline = f.headline ?? target?.headline;
    if (headline != null) {
      b.writeln('\tmeta_set(&n->headline, "${_cStr(headline)}");');
    }
    final comment = '${f.annotation('Comment')?.argument('text') ?? ''}';
    if (comment.isNotEmpty) {
      b.writeln('\tmeta_set(&n->comment, "${_cStr(comment)}");');
    }
    final docComment = f.doc ?? target?.doc;
    if (docComment != null) {
      b.writeln('\tmeta_set(&n->doc_comment, "${_cStr(docComment)}");');
    }
    if (target?.doc != null) {
      b.writeln('\tmeta_set(&n->class_doc_comment, '
          '"${_cStr(target!.doc!)}");');
    }
    if (f.kind == SpecFieldKind.form) {
      _emitForm(b, f.formFields);
    }
    if (target?.mapsTo != null) {
      b.writeln('\tmeta_set(&n->maps_to, "${_cStr(target!.mapsTo!)}");');
    }
    if (target?.detailedIn != null) {
      b.writeln('\tmeta_set(&n->detailed_in, '
          '"${_cStr(target!.detailedIn!)}");');
    }
    _emitExtras(b, f.annotations);
  }

  /// Writes the field-population statements for a list's complex-element
  /// subtree node.
  void _emitElementFields(StringBuffer b, SpecClass element) {
    b.writeln('\tmeta_set(&n->class_name, "${_cStr(element.name)}");');
    if (element.sectionId != null) {
      b.writeln('\tmeta_set(&n->class_section_id, '
          '"${_cStr(element.sectionId!)}");');
    }
    b.writeln('\tn->kind = SOM_META_KIND_COMPLEX;');
    b.writeln('\tmeta_set(&n->type_name, "${_cStr(element.name)}");');
    if (element.headline != null) {
      b.writeln('\tmeta_set(&n->headline, "${_cStr(element.headline!)}");');
    }
    if (element.doc != null) {
      b.writeln('\tmeta_set(&n->doc_comment, "${_cStr(element.doc!)}");');
      b.writeln('\tmeta_set(&n->class_doc_comment, '
          '"${_cStr(element.doc!)}");');
    }
    if (element.mapsTo != null) {
      b.writeln('\tmeta_set(&n->maps_to, "${_cStr(element.mapsTo!)}");');
    }
    if (element.detailedIn != null) {
      b.writeln('\tmeta_set(&n->detailed_in, '
          '"${_cStr(element.detailedIn!)}");');
    }
  }

  void _emitForm(StringBuffer b, List<FormFieldSpec> fields) {
    b.writeln('\tn->form = (SomFormMeta *)calloc(1, sizeof(SomFormMeta));');
    b.writeln('\tn->form->fields_len = ${fields.length};');
    if (fields.isEmpty) return;
    b.writeln('\tn->form->fields = (SomFormFieldMeta *)calloc('
        '${fields.length}, sizeof(SomFormFieldMeta));');
    for (var i = 0; i < fields.length; i++) {
      final ff = fields[i];
      b
        ..writeln('\tn->form->fields[$i].name = som_strdup('
            '"${_cStr(ff.name)}");')
        ..writeln('\tn->form->fields[$i].type_name = som_strdup('
            '"${_cStr(ff.type)}");')
        ..writeln('\tn->form->fields[$i].description = som_strdup('
            '"${_cStr(ff.label)}");')
        ..writeln('\tn->form->fields[$i].required = '
            '${ff.required ? 1 : 0};')
        ..writeln('\tn->form->fields[$i].hint = som_strdup('
            '"${_cStr(ff.hint ?? '')}");')
        ..writeln('\tn->form->fields[$i].order = $i;');
      // YRD7: enum-typed fields carry their value domain; calloc already
      // zero-inits enum_values/enum_values_len for the non-enum case.
      if (ff.enumValues.isNotEmpty) {
        b
          ..writeln('\tn->form->fields[$i].enum_values_len = '
              '${ff.enumValues.length};')
          ..writeln('\tn->form->fields[$i].enum_values = (char **)calloc('
              '${ff.enumValues.length}, sizeof(char *));');
        for (var j = 0; j < ff.enumValues.length; j++) {
          b.writeln('\tn->form->fields[$i].enum_values[$j] = som_strdup('
              '"${_cStr(ff.enumValues[j])}");');
        }
      }
      // csrb3: reference fields carry their target registry key(s); calloc has
      // already zero-inited refers_to/refers_to_len for the non-reference case.
      if (ff.refersTo.isNotEmpty) {
        b
          ..writeln('\tn->form->fields[$i].refers_to_len = '
              '${ff.refersTo.length};')
          ..writeln('\tn->form->fields[$i].refers_to = (char **)calloc('
              '${ff.refersTo.length}, sizeof(char *));');
        for (var j = 0; j < ff.refersTo.length; j++) {
          b.writeln('\tn->form->fields[$i].refers_to[$j] = som_strdup('
              '"${_cStr(ff.refersTo[j])}");');
        }
      }
    }
  }

  void _emitExtras(StringBuffer b, List<SpecAnnotation> annotations) {
    final entries = [
      for (final a in annotations)
        if (!_slottedAnnotations.contains(a.name)) a,
    ];
    if (entries.isEmpty) return;
    b.writeln('\tn->extra_len = ${entries.length};');
    b.writeln('\tn->extra = (SomMetaExtra *)calloc('
        '${entries.length}, sizeof(SomMetaExtra));');
    for (var i = 0; i < entries.length; i++) {
      final a = entries[i];
      b.writeln('\tn->extra[$i].annotation = som_strdup('
          '"${_cStr(a.name)}");');
      // Extra.args mirrors the bridge's parsed constructor arguments (which the
      // bridge *borrows* from the live SpecModel source). The generated tree has
      // no live model to borrow from, so it parses an equivalent JSON literal
      // once; SomMetaNodeDiff compares args by value (order-independent for
      // objects), so a byte-for-byte match with the bridge is not required. The
      // owned value lives for the process lifetime of the cached static tree and
      // is never freed — som_meta_tree_free treats args as borrowed and skips
      // it, matching the borrowed-args ownership contract.
      b.writeln('\tn->extra[$i].args = som_json_parse('
          '"${_cStr(jsonEncode(a.arguments))}", NULL);');
    }
  }

  // ── per-root emission ───────────────────────────────────────────────────────

  void _emitRoot(StringBuffer b, SpecRoot root) {
    final cls = model.classNamed(root.type);
    final seg = _ref.rootSegment(root);
    final treeFn = _treeFn(root.type);
    final rootBuildFn = 'meta_build_root_${_snake(root.type)}';

    // Root node build function (populates a SomMetaNode *n like a node, but
    // with @Document metadata and children built directly).
    b.writeln('static SomMetaNode *$rootBuildFn(void) {');
    b.writeln('\tSomMetaNode *n = som_meta_node_new();');
    b.writeln('\tmeta_set(&n->class_name, "${_cStr(root.type)}");');
    final sectionId = root.sectionId ?? cls?.sectionId;
    if (sectionId != null) {
      b.writeln('\tmeta_set(&n->section_id, "${_cStr(sectionId)}");');
    }
    if (cls?.sectionId != null) {
      b.writeln('\tmeta_set(&n->class_section_id, "${_cStr(cls!.sectionId!)}");');
    }
    b.writeln('\tn->kind = SOM_META_KIND_SECTION;');
    b.writeln('\tmeta_set(&n->type_name, "${_cStr(root.type)}");');
    if (cls?.headline != null) {
      b.writeln('\tmeta_set(&n->headline, "${_cStr(cls!.headline!)}");');
    }
    final doc = root.doc ?? cls?.doc;
    if (doc != null) {
      b.writeln('\tmeta_set(&n->doc_comment, "${_cStr(doc)}");');
    }
    if (cls?.doc != null) {
      b.writeln('\tmeta_set(&n->class_doc_comment, "${_cStr(cls!.doc!)}");');
    }
    if (cls?.mapsTo != null) {
      b.writeln('\tmeta_set(&n->maps_to, "${_cStr(cls!.mapsTo!)}");');
    }
    if (cls?.detailedIn != null) {
      b.writeln('\tmeta_set(&n->detailed_in, "${_cStr(cls!.detailedIn!)}");');
    }
    // @Document metadata.
    final basedOn = _basedOn(cls);
    b.writeln('\tn->document = (SomDocMeta *)calloc(1, sizeof(SomDocMeta));');
    b.writeln('\tn->document->name = som_strdup("${_cStr(root.title)}");');
    b.writeln('\tn->document->description = som_strdup('
        '"${_cStr(root.description ?? '')}");');
    b.writeln('\tsom_strlist_init(&n->document->based_on);');
    for (final base in basedOn) {
      b.writeln('\tsom_strlist_push_copy(&n->document->based_on, '
          '"${_cStr(base)}");');
    }
    _emitExtras(b, cls?.annotations ?? const []);
    if (cls != null) {
      b
        ..writeln('\tSomStrList stack;')
        ..writeln('\tsom_strlist_init(&stack);')
        ..writeln('\tsom_strlist_push_copy(&stack, "${_cStr(root.type)}");')
        ..writeln('\tsize_t clen = 0;')
        ..writeln('\tSomMetaNode **c = ${_childrenFn(root.type)}('
            '&stack, &clen);')
        ..writeln('\tfor (size_t i = 0; i < clen; i++) {')
        ..writeln('\t\tsom_meta_node_add_child(n, c[i]);')
        ..writeln('\t}')
        ..writeln('\tfree(c);')
        ..writeln('\tsom_strlist_free(&stack);');
    }
    b.writeln('\treturn n;');
    b.writeln('}');

    // Lazily-cached tree accessor.
    b
      ..writeln('const SomMetaTree *$treeFn(void) {')
      ..writeln('\tstatic SomMetaTree *cached = NULL;')
      ..writeln('\tif (cached == NULL) {')
      ..writeln('\t\tcached = must_meta_tree($rootBuildFn());')
      ..writeln('\t}')
      ..writeln('\treturn cached;')
      ..writeln('}');

    // Entry points binding the surface roots to the tree + root segment path.
    b
      ..writeln('${_navType(root.type)} ${_rootNavFn(root)}('
          'const SomMetaTree *tree) {')
      ..writeln('\t${_navType(root.type)} x;')
      ..writeln('\tsom_meta_ref_init(&x.ref, tree, "${_cStr(seg)}");')
      ..writeln('\treturn x;')
      ..writeln('}')
      ..writeln('${_idType(root.type)} ${_rootIdFn(root)}('
          'const SomMetaTree *tree) {')
      ..writeln('\t${_idType(root.type)} x;')
      ..writeln('\tsom_meta_ref_init(&x.ref, tree, "${_cStr(seg)}");')
      ..writeln('\treturn x;')
      ..writeln('}')
      ..writeln();
  }

  List<String> _basedOn(SpecClass? cls) {
    final raw = cls?.annotation('Document')?.argument('basedOn');
    if (raw is List) return raw.map((e) => '$e').toList();
    return const [];
  }

  // ── dot-notation accessors (SOM §8) ─────────────────────────────────────────

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
        _emitList(b, seg, element == null ? null : _navType(element.name),
            element == null ? null : _navFactory(element.name));
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
      _emitList(b, child.relPath, elem == null ? null : _idType(elem),
          elem == null ? null : _idFactory(elem));
      return;
    }
    if (child.targetClass != null) {
      _emitChildStruct(b, _idType(child.targetClass!), child.relPath);
      return;
    }
    _emitLeaf(b, child.relPath);
  }

  void _emitChildStruct(StringBuffer b, String type, String seg) {
    b
      ..writeln('\t$type out;')
      ..writeln('\tchar *path = spec_path_join(x.ref.path, "${_cStr(seg)}");')
      ..writeln('\tsom_meta_ref_init(&out.ref, x.ref.tree, path);')
      ..writeln('\tfree(path);')
      ..writeln('\treturn out;');
  }

  void _emitLeaf(StringBuffer b, String seg) {
    b
      ..writeln('\tSomMetaRef out;')
      ..writeln('\tchar *path = spec_path_join(x.ref.path, "${_cStr(seg)}");')
      ..writeln('\tsom_meta_ref_init(&out, x.ref.tree, path);')
      ..writeln('\tfree(path);')
      ..writeln('\treturn out;');
  }

  void _emitList(
      StringBuffer b, String seg, String? elemType, String? factory) {
    b
      ..writeln('\tSomListMetaRef out;')
      ..writeln('\tchar *path = spec_path_join(x.ref.path, "${_cStr(seg)}");');
    if (factory != null) {
      b.writeln('\tsom_list_meta_ref_init(&out, x.ref.tree, path, $factory);');
    } else {
      _leafFactoryUsed = true;
      b.writeln('\tsom_list_meta_ref_init(&out, x.ref.tree, path, '
          'meta_leaf_factory);');
    }
    b
      ..writeln('\tfree(path);')
      ..writeln('\treturn out;');
  }

  // ── factories (SomMetaRefFactory) ───────────────────────────────────────────

  /// Element-accessor factories: `factory(tree, path)` returns an owned pointer
  /// to the element's nav/id struct (or a leaf `SomMetaRef`). Emitted lazily via
  /// the recorded sets so only referenced factories appear, warning-clean.
  final Set<String> _navFactoriesUsed = {};
  final Set<String> _idFactoriesUsed = {};
  bool _leafFactoryUsed = false;

  String _navFactory(String cls) {
    _navFactoriesUsed.add(cls);
    return 'meta_nav_factory_${_snake(cls)}';
  }

  String _idFactory(String cls) {
    _idFactoriesUsed.add(cls);
    return 'meta_id_factory_${_snake(cls)}';
  }


  // ── SOM §8 ID-tree children ─────────────────────────────────────────────────

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

  String _navType(String cls) => 'som_nav_${_snake(cls)}';
  String _idType(String cls) => 'som_id_${_snake(cls)}';
  String _childrenFn(String cls) => 'meta_children_${_snake(cls)}';
  String _treeFn(String rootType) => '${_snake(rootType)}_meta_tree';
  String _rootNavFn(SpecRoot root) => '${_snake(root.type)}_meta';
  String _rootIdFn(SpecRoot root) => _idName(_ref.rootSegment(root));

  String _navFn(Set<String> used, String cls, SpecField f) {
    var base = '${_snake(cls)}_nav_${_snakeTail(f.name)}';
    var cand = base;
    var n = 2;
    while (!used.add(cand)) {
      cand = '${base}_$n';
      n++;
    }
    return cand;
  }

  String _idFn(String cls, _IdChild child) =>
      '${_snake(cls)}_id_${child.name.toLowerCase()}';

  String _navReturn(SpecField f) {
    switch (f.kind) {
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = model.classNamed(f.type ?? '');
        return target != null ? _navType(target.name) : 'SomMetaRef';
      case SpecFieldKind.list:
        return 'SomListMetaRef';
      case SpecFieldKind.form:
      case SpecFieldKind.content:
      case SpecFieldKind.enumValue:
      case SpecFieldKind.scalar:
        return 'SomMetaRef';
    }
  }

  String _idReturn(_IdChild child) {
    if (child.isList) return 'SomListMetaRef';
    if (child.targetClass != null) return _idType(child.targetClass!);
    return 'SomMetaRef';
  }

  /// A section id as a C identifier: `-` → `_`; digit-leading ids prefixed with
  /// `id`; a C-keyword collision gains a trailing underscore.
  String _idName(String id) {
    var name = id.replaceAll('-', '_');
    if (RegExp(r'^[0-9]').hasMatch(name)) name = 'id$name';
    return name;
  }

  String _snakeTail(String name) {
    var base = _snake(name);
    if (base.isEmpty) base = 'field';
    if (_cKeywords.contains(base)) base = '${base}_';
    return base;
  }

  // ── text helpers ────────────────────────────────────────────────────────────

  void _banner(StringBuffer b, String which) {
    b
      ..writeln('/* GENERATED by tom_specs_clitool SomCMetaEmitter '
          '($versionLabel) — do not edit by hand. */')
      ..writeln('/* The populated SOM metadata trees (SOM §7.2) and the two '
          'access surfaces of */')
      ..writeln('/* SOM §8: the dot-notation tree (member names) and the '
          'ID-tree (section ids). */')
      ..writeln('/* ($which) */')
      ..writeln();
  }

  String _cStr(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  String _kindConst(SpecFieldKind kind) {
    switch (kind) {
      case SpecFieldKind.list:
        return 'SOM_META_KIND_LIST';
      case SpecFieldKind.form:
        return 'SOM_META_KIND_FORM';
      case SpecFieldKind.section:
        return 'SOM_META_KIND_SECTION';
      case SpecFieldKind.content:
        return 'SOM_META_KIND_CONTENT';
      case SpecFieldKind.enumValue:
        return 'SOM_META_KIND_ENUM_VALUE';
      case SpecFieldKind.complex:
        return 'SOM_META_KIND_COMPLEX';
      case SpecFieldKind.scalar:
        return 'SOM_META_KIND_SCALAR';
    }
  }

  String _snake(String s) {
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '_' || c == ' ' || c == '-') {
        buf.write('_');
        continue;
      }
      final isUpper = c.toUpperCase() == c && c.toLowerCase() != c;
      if (isUpper && i > 0) {
        final prev = s[i - 1];
        final prevLower = prev.toLowerCase() == prev && prev.toUpperCase() != prev;
        final prevDigit = prev.codeUnitAt(0) >= 0x30 && prev.codeUnitAt(0) <= 0x39;
        if (prevLower || prevDigit) buf.write('_');
      }
      buf.write(c.toLowerCase());
    }
    var out = buf.toString().replaceAll(RegExp(r'_+'), '_');
    out = out.replaceAll(RegExp(r'^_+|_+$'), '');
    return out;
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

/// A deferred build-function definition (the body populating a `SomMetaNode *n`).
class _PendingBuild {
  final String fnName;
  final String Function() body;
  const _PendingBuild(this.fnName, this.body);
}
