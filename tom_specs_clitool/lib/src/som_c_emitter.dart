/// Emits the generated C typed object model (`tom_som_c_v0`) from a resolved
/// [SpecModel].
///
/// The generated accessors are an **editing facade** over the generic
/// `tom_som_c_runtime` `SpecDocument`: every typed accessor delegates to the
/// path-keyed memory representation, so a typed mutation is visible through the
/// generic path and vice-versa (spec §3). Each document-root performs the
/// **instantiation-time version check** (`check_som_model_version`) against the
/// document's authoring stamp (§2.2) and exposes its own generated model version
/// (§2.1).
///
/// This is the C counterpart of [SomDartEmitter] / `SomPythonEmitter` /
/// `SomJavaEmitter` / `SomJavaScriptEmitter` / `SomTypeScriptEmitter` /
/// `SomGoEmitter` / `SomRustEmitter` — the same reachability walk, the same
/// deterministic ordering, the same field-kind mapping. C has no classes,
/// methods, generics, or namespaces, so the surface is an accessor-function API
/// over the generic runtime structs:
///
///   * each model class becomes a `typedef struct { SomNode node; } <Class>;`
///     plus free functions `<class>_<field>(const <Class>*)` (owned `char*`
///     result for value leaves) and `<class>_set_<field>(<Class>*, const char*)`;
///   * complex/section and `@Form` accessors return a **child facade by value**
///     (binding the same document + the child path); list accessors return a
///     `SomList` by value (path-based — the element type is named in the doc
///     comment and constructed from the item paths it yields);
///   * because C has a single flat namespace, **every emitted function name is
///     globally unique** (deduped with the smallest numeric suffix); type names
///     and value-namespace identifiers (enum `#define` tokens, `parse_<enum>`
///     helpers, per-root `<ROOT>_MODEL_VERSION`) are deduped too;
///   * C keyword collisions (`int`, `for`, `return`, …) on an accessor base gain
///     a trailing underscore;
///   * the root constructor returns `int` (0 == editable) and writes an owned
///     error message through a `char **err` out-parameter on a non-editable
///     stamp (the C analogue of `Result<_, SomVersionError>`).
///
/// The artefact is a header/source pair: [generateHeader] (typedefs, `#define`
/// constants, function declarations) and [generateSource] (function bodies).
/// Both share one deterministic name allocation, so re-running over an unchanged
/// model is byte-for-byte stable.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'spec_path_constants.dart';

/// The header include-guard macro and the generated file basenames.
const String _headerGuard = 'TOM_SOM_C_V0_H';
const String _headerBasename = 'tom_som_c_v0.h';

/// Generates the `tom_som_c_v0` header + source for a [SpecModel].
class SomCEmitter {
  final SpecModel model;
  final SpecReflection _ref;

  /// The version label of the generated project (`v0`, `v1`, …).
  final String versionLabel;

  /// The document-root type names to generate. Empty ⇒ every root in the model.
  final List<String> documentRoots;

  SomCEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
  }) : _ref = SpecReflection(model);

  /// The model version the generated object model reports (§2.1), `major.minor`,
  /// taken from the model's own version stamp (the `tom_specs_model` project
  /// version), not the project [versionLabel] — which only names the `_vN`
  /// output project.
  String get modelVersionString => model.modelVersionString;

  List<SpecRoot> get _selectedRoots {
    if (documentRoots.isEmpty) return model.roots;
    final wanted = documentRoots.toSet();
    return model.roots.where((r) => wanted.contains(r.type)).toList();
  }

  /// Reserved C keywords (C11). A snake-cased accessor matching one of these
  /// gains a trailing underscore so it stays a legal identifier.
  static const Set<String> _cKeywords = {
    'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do',
    'double', 'else', 'enum', 'extern', 'float', 'for', 'goto', 'if', 'inline',
    'int', 'long', 'register', 'restrict', 'return', 'short', 'signed',
    'sizeof', 'static', 'struct', 'switch', 'typedef', 'union', 'unsigned',
    'void', 'volatile', 'while', '_Alignas', '_Alignof', '_Atomic', '_Bool',
    '_Complex', '_Generic', '_Imaginary', '_Noreturn', '_Static_assert',
    '_Thread_local',
  };

  // --- global namespaces (deduped) ----------------------------------------

  /// All module-level type names (struct typedefs) — model classes plus form
  /// structs.
  final Set<String> _typeNames = {};

  /// All value-namespace identifiers (enum `#define`s, `parse_` helpers, the
  /// per-root `<ROOT>_MODEL_VERSION` constants).
  final Set<String> _valueNames = {};

  /// All emitted function names — C has one flat function namespace.
  final Set<String> _funcNames = {};

  /// Per-class emission plan, keyed by class name.
  final Map<String, _ClassPlan> _classPlans = {};

  /// Form plans in deterministic (struct-name) order.
  final List<_FormPlan> _formPlans = [];

  /// Enum constants keyed by enum type, and the `parse_` helper name per enum.
  final Map<String, List<_EnumConst>> _enumConsts = {};
  final Map<String, String> _parseName = {};
  final List<_EnumType> _enums = [];

  String _alloc(Set<String> ns, String base) {
    if (ns.add(base)) return base;
    var n = 2;
    while (!ns.add('${base}_$n')) {
      n++;
    }
    return '${base}_$n';
  }

  bool _prepared = false;

  /// Resolves every name once; idempotent. Both [generateHeader] and
  /// [generateSource] call it so they emit identical, collision-free names.
  void _prepare() {
    if (_prepared) return;
    _typeNames.clear();
    _valueNames.clear();
    _funcNames.clear();
    _classPlans.clear();
    _formPlans.clear();
    _enumConsts.clear();
    _parseName.clear();
    _enums.clear();

    final rootTypes = _selectedRoots.map((r) => r.type).toSet();
    final reachable = _reachableClasses(rootTypes);
    final sortedClasses = reachable.toList()..sort();

    // 1. enums (value namespace) ------------------------------------------
    _enums.addAll(_reachableEnums(reachable));
    for (final e in _enums) {
      _parseName[e.name] = _alloc(_valueNames, 'parse_${_snake(e.name)}');
      final consts = <_EnumConst>[];
      final prefix = _screamingSnake(e.name);
      var idx = 0;
      for (final v in e.values) {
        final tail = _screamingSnake(v);
        final ident = tail.isEmpty ? '${prefix}_VALUE_$idx' : '${prefix}_$tail';
        consts.add(_EnumConst(_alloc(_valueNames, ident), v));
        idx++;
      }
      _enumConsts[e.name] = consts;
    }

    // 2. type names: model classes (verbatim) then form structs (sorted) ---
    for (final n in sortedClasses) {
      _typeNames.add(n);
    }
    final pendingForms = <_PendingForm>[];
    for (final n in sortedClasses) {
      final cls = model.classNamed(n);
      if (cls == null) continue;
      for (final f in cls.fields) {
        if (f.kind == SpecFieldKind.form) {
          final typeName = _alloc(_typeNames, '$n${_pascal(f.name)}Form');
          pendingForms.add(_PendingForm(n, f, typeName));
        }
      }
    }

    // 3. per-root model-version constants (value namespace) ----------------
    final mvConst = <String, String>{};
    for (final n in sortedClasses) {
      if (rootTypes.contains(n)) {
        mvConst[n] =
            _alloc(_valueNames, '${_screamingSnake(n)}_MODEL_VERSION');
      }
    }

    // 4. function names (one flat namespace) ------------------------------
    for (final n in sortedClasses) {
      final cls = model.classNamed(n);
      if (cls == null) continue;
      final isRoot = rootTypes.contains(n);
      final prefix = _snake(n).isEmpty ? 'class' : _snake(n);
      final plan = _ClassPlan(cls, n, isRoot);
      if (isRoot) {
        plan.lifecycleFn = _alloc(_funcNames, '${prefix}_new');
        plan.omvFn = _alloc(_funcNames, '${prefix}_object_model_version');
        plan.editabilityFn = _alloc(_funcNames, '${prefix}_editability_for');
        plan.loadYamlFn = _alloc(_funcNames, '${prefix}_load_yaml');
        plan.loadFileFn = _alloc(_funcNames, '${prefix}_load_file');
        plan.mvConst = mvConst[n];
        final root = model.roots.firstWhere((r) => r.type == n);
        plan.rootSeg = _ref.rootSegment(root);
      } else {
        plan.lifecycleFn = _alloc(_funcNames, '${prefix}_init');
      }
      plan.freeFn = _alloc(_funcNames, '${prefix}_free');
      plan.canHaveContentFn =
          _alloc(_funcNames, '${prefix}_can_have_content');
      for (final f in cls.fields) {
        final acc = _snakeAccessor(f.name);
        final getName = _alloc(_funcNames, '${prefix}_$acc');
        plan.getFn[f.name] = getName;
        if (_hasSetter(f)) {
          plan.setFn[f.name] = _alloc(_funcNames, '${prefix}_set_$acc');
        }
      }
      _classPlans[n] = plan;
    }

    // 5. form function names, after all class functions, sorted by type ----
    pendingForms.sort((a, b) => a.typeName.compareTo(b.typeName));
    for (final pf in pendingForms) {
      final prefix = _snake(pf.typeName);
      final fp = _FormPlan(pf.typeName, pf.field);
      fp.initFn = _alloc(_funcNames, '${prefix}_init');
      fp.freeFn = _alloc(_funcNames, '${prefix}_free');
      for (final ff in pf.field.formFields) {
        final acc = _snakeAccessor(ff.name);
        fp.getFn[ff.name] = _alloc(_funcNames, '${prefix}_$acc');
        fp.setFn[ff.name] = _alloc(_funcNames, '${prefix}_set_$acc');
      }
      _formPlans.add(fp);
      // Record the form type the owning field's accessor returns.
      _classPlans[pf.owner]?.formTypeFor[pf.field.name] = pf.typeName;
    }

    _prepared = true;
  }

  bool _hasSetter(SpecField f) {
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
      case SpecFieldKind.enumValue:
        return true;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
      case SpecFieldKind.list:
      case SpecFieldKind.form:
        return false;
    }
  }

  // --- header --------------------------------------------------------------

  /// Builds the generated header (`tom_som_c_v0.h`).
  String generateHeader() {
    _prepare();
    final b = StringBuffer();
    _fileBanner(b, 'header');
    b
      ..writeln('#ifndef $_headerGuard')
      ..writeln('#define $_headerGuard')
      ..writeln()
      ..writeln('#include "tom_som_c_runtime.h"')
      ..writeln();

    // enum tokens + parse declarations
    for (final e in _enums) {
      final consts = _enumConsts[e.name] ?? const <_EnumConst>[];
      final parse = _parseName[e.name]!;
      b
        ..writeln('// Generated enum tokens for `${e.name}` values. The stored '
            'token is byte-')
        ..writeln('// identical across every language port, so documents stay '
            'cross-compatible.');
      for (final c in consts) {
        b.writeln('#define ${c.ident} "${_cStr(c.token)}"');
      }
      b
        ..writeln('// $parse returns the token (owned) when it is a known '
            '${e.name} value, else "".')
        ..writeln('char *$parse(const char *token);')
        ..writeln();
    }

    // model-version constants
    final roots = _classPlans.values.where((p) => p.isRoot).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (roots.isNotEmpty) {
      for (final r in roots) {
        b
          ..writeln('// ${r.mvConst} is the model version the ${r.name} object '
              'model was generated against (§2.1).')
          ..writeln('#define ${r.mvConst} "$modelVersionString"');
      }
      b.writeln();
    }

    // struct typedefs (all share { SomNode node; }; emit together)
    b.writeln('// Typed facade structs — each binds a node (document + path).');
    final typeOrder = <String>[
      ..._classPlans.keys.toList()
        ..sort(),
    ];
    for (final n in typeOrder) {
      b.writeln('typedef struct { SomNode node; } $n;');
    }
    for (final fp in _formPlans) {
      b.writeln('typedef struct { SomNode node; } ${fp.typeName};');
    }
    b.writeln();

    // class function declarations
    for (final n in typeOrder) {
      final plan = _classPlans[n]!;
      _declClass(b, plan);
      b.writeln();
    }
    for (final fp in _formPlans) {
      _declForm(b, fp);
      b.writeln();
    }

    _emitPathConstants(b);

    b.writeln('#endif /* $_headerGuard */');
    return b.toString().replaceAll('\t', '  ');
  }

  /// § item 11: per-root path constants. C has no namespaces, so each root's
  /// holder becomes a group of `#define` string macros — matching the header's
  /// existing enum-token / model-version `#define` convention (SCREAMING_SNAKE
  /// tokens). Each macro name is `<SCREAMING(holderName)>_<SCREAMING(name)>`
  /// (e.g. `PD00_PATHS_VISION`) and the value is the c-escaped absolute path.
  /// `#define` (not `static const char *`) avoids `-Wunused` on the file-scope
  /// statics the `-Werror` build would reject. List **items** are dynamic and
  /// never earn a constant (only the container), so no element recursion leaks.
  void _emitPathConstants(StringBuffer b) {
    final holders =
        enumerateSpecPathHolders(model, documentRoots: documentRoots);
    for (final holder in holders) {
      if (holder.constants.isEmpty) continue;
      final prefix = _screamingSnake(holder.holderName);
      b
        ..writeln('// Generated path constants for the `${holder.rootSegment}` '
            'document root (§ item 11).')
        ..writeln('// Each macro is the absolute generic path of a fixed '
            'section, for use with the')
        ..writeln('// generic SpecDocument API instead of a raw string '
            'literal.');
      for (final c in holder.constants) {
        b.writeln('#define ${prefix}_${_screamingSnake(c.name)} '
            '"${_cStr(c.path)}"');
      }
      b.writeln();
    }
  }

  void _declClass(StringBuffer b, _ClassPlan plan) {
    final t = plan.typeName;
    _doc(b, plan.cls.doc, '');
    if (plan.isRoot) {
      b
        ..writeln('// Creates the typed facade at the document root and verifies '
            "the document's")
        ..writeln('// authoring version is editable (§2.2). Returns 0 on '
            'success; on a non-editable')
        ..writeln('// stamp returns non-zero and, when `err` is non-NULL, '
            'writes an owned message.')
        ..writeln('int ${plan.lifecycleFn}($t *self, SpecDocument *doc, '
            'const char *document_version, char **err);')
        ..writeln("// Returns this object model's own model version "
            '(major.minor), per §2.1.')
        ..writeln('const char *${plan.omvFn}(const $t *self);')
        ..writeln('// Classifies whether a document authored under '
            '`document_version` is editable')
        ..writeln('// by this object model, without reporting an error '
            "(§ item 8) — the non-erroring")
        ..writeln("// companion to ${plan.lifecycleFn}'s §2.2 check, so a "
            'read-only viewer can branch')
        ..writeln('// instead of handling the constructor error. `document_version`'
            ' may be NULL/"".')
        ..writeln('SomEditability ${plan.editabilityFn}('
            'const char *document_version);')
        ..writeln('// Loads a `*.docspecs.yaml` document in one call: decode the '
            'YAML, populate the')
        ..writeln('// sparse stores, and bind this typed root at the document '
            "root with the document's")
        ..writeln('// retained authoring stamp — one call for the former decode '
            '→ load_json →')
        ..writeln('// thread-`document_version` sequence (§ item 4). The owned '
            'heap document is')
        ..writeln('// written to `*out_doc` (which the facade borrows; free it '
            'with')
        ..writeln('// spec_document_free + free once the root is done). Returns '
            '0 on success; on a')
        ..writeln('// non-editable stamp returns non-zero and, when `err` is '
            'non-NULL, writes an')
        ..writeln('// owned message (and frees the document).')
        ..writeln('int ${plan.loadYamlFn}($t *self, const char *yaml, '
            'SpecDocument **out_doc, char **err);')
        ..writeln('// Loads a `*.docspecs.yaml` document from the file at `path` '
            '— the file companion')
        ..writeln('// to ${plan.loadYamlFn}. Returns non-zero (without writing '
            '`*out_doc`) when the')
        ..writeln('// file cannot be read.')
        ..writeln('int ${plan.loadFileFn}($t *self, const char *path, '
            'SpecDocument **out_doc, char **err);');
    } else {
      b.writeln('// Binds a $t facade to a document and a path (path copied).');
      b.writeln('void ${plan.lifecycleFn}($t *self, SpecDocument *doc, '
          'const char *path);');
    }
    b.writeln('void ${plan.freeFn}($t *self);');
    // § item 10: a per-type structural predicate answering "does this section
    // TYPE declare the standard `content` text leaf?" — "can this section hold
    // body text?" — without probing the document. C has no inheritance or
    // method promotion, so (following the item-8 `editability_for` / item-5
    // `is_empty` per-type C precedent) every generated type emits its own
    // accessor returning the literal answer: 1 for content-bearing types, 0 for
    // container-only ones. It is deliberately distinct from the STATE predicates
    // `spec_document_has_content` ("value present now?") and `som_node_is_empty`
    // ("subtree empty now?"): it describes the model, not the data.
    b.writeln('// Returns 1 iff this section type declares the standard `content`'
        ' text leaf (§ item 10).');
    b.writeln('int ${plan.canHaveContentFn}(const $t *self);');
    for (final f in plan.cls.fields) {
      _declField(b, plan, f);
    }
  }

  /// Whether [cls] declares the standard `content` text leaf — the structural
  /// signal that its generated facade carries a `content` accessor (§ item 10).
  bool _hasContentLeaf(SpecClass cls) => cls.fields
      .any((f) => f.name == 'content' && f.kind == SpecFieldKind.content);

  void _declField(StringBuffer b, _ClassPlan plan, SpecField f) {
    final t = plan.typeName;
    final get = plan.getFn[f.name]!;
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
      case SpecFieldKind.enumValue:
        _doc(b, f.doc, '');
        b.writeln('char *$get(const $t *self);');
        b.writeln('void ${plan.setFn[f.name]}($t *self, const char *value);');
        break;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        if (f.type == null) {
          _doc(b, f.doc, '');
          b.writeln('// (skipped: ${f.name} has no target type)');
        } else {
          _doc(b, f.doc, '');
          b.writeln('${f.type} $get(const $t *self);');
        }
        break;
      case SpecFieldKind.list:
        _doc(b, f.doc, '');
        final elem = (f.elementIsComplex && f.elementType != null)
            ? f.elementType!
            : 'scalar';
        b.writeln('// Returns the list view; element type: $elem '
            '(construct from item paths).');
        b.writeln('SomList $get(const $t *self);');
        break;
      case SpecFieldKind.form:
        final formType = plan.formTypeFor[f.name];
        _doc(b, f.doc, '');
        b.writeln('$formType $get(const $t *self);');
        break;
    }
  }

  void _declForm(StringBuffer b, _FormPlan fp) {
    final t = fp.typeName;
    b
      ..writeln('// $t is the generated form facade for the `${fp.field.name}` '
          '@Form section.')
      ..writeln('void ${fp.initFn}($t *self, SpecDocument *doc, '
          'const char *path);')
      ..writeln('void ${fp.freeFn}($t *self);');
    for (final ff in fp.field.formFields) {
      b.writeln('char *${fp.getFn[ff.name]}(const $t *self);');
      b.writeln(
          'void ${fp.setFn[ff.name]}($t *self, const char *value);');
    }
  }

  // --- source --------------------------------------------------------------

  /// Builds the generated source (`tom_som_c_v0.c`).
  String generateSource() {
    _prepare();
    final b = StringBuffer();
    _fileBanner(b, 'source');
    b
      ..writeln('#include "$_headerBasename"')
      ..writeln()
      ..writeln('#include <stdlib.h>')
      ..writeln('#include <string.h>')
      ..writeln();

    for (final e in _enums) {
      _defineParse(b, e);
      b.writeln();
    }

    final typeOrder = _classPlans.keys.toList()..sort();
    for (final n in typeOrder) {
      _defineClass(b, _classPlans[n]!);
      b.writeln();
    }
    for (final fp in _formPlans) {
      _defineForm(b, fp);
      b.writeln();
    }

    return b.toString().replaceAll('\t', '  ');
  }

  void _defineParse(StringBuffer b, _EnumType e) {
    final consts = _enumConsts[e.name] ?? const <_EnumConst>[];
    final parse = _parseName[e.name]!;
    b.writeln('char *$parse(const char *token) {');
    if (consts.isEmpty) {
      b.writeln('\t(void)token;');
      b.writeln('\treturn som_strdup("");');
    } else {
      final cond =
          consts.map((c) => 'strcmp(token, ${c.ident}) == 0').join(' ||\n\t    ');
      b
        ..writeln('\tif ($cond) {')
        ..writeln('\t\treturn som_strdup(token);')
        ..writeln('\t}')
        ..writeln('\treturn som_strdup("");');
    }
    b.writeln('}');
  }

  void _defineClass(StringBuffer b, _ClassPlan plan) {
    final t = plan.typeName;
    if (plan.isRoot) {
      b
        ..writeln('int ${plan.lifecycleFn}($t *self, SpecDocument *doc, '
            'const char *document_version, char **err) {')
        ..writeln('\tif (check_som_model_version(${plan.mvConst}, '
            'document_version, err) != 0) {')
        ..writeln('\t\treturn 1;')
        ..writeln('\t}')
        ..writeln('\tsom_node_init(&self->node, doc, '
            '"${_cStr(plan.rootSeg!)}");')
        ..writeln('\treturn 0;')
        ..writeln('}')
        ..writeln('const char *${plan.omvFn}(const $t *self) {')
        ..writeln('\t(void)self;')
        ..writeln('\treturn ${plan.mvConst};')
        ..writeln('}')
        ..writeln('SomEditability ${plan.editabilityFn}('
            'const char *document_version) {')
        ..writeln('\treturn som_editability_for(${plan.mvConst}, '
            'document_version);')
        ..writeln('}')
        ..writeln('int ${plan.loadYamlFn}($t *self, const char *yaml, '
            'SpecDocument **out_doc, char **err) {')
        ..writeln('\tSpecDocument *doc = spec_document_from_yaml(yaml);')
        ..writeln('\tif (${plan.lifecycleFn}(self, doc, doc->model_version, err) '
            '!= 0) {')
        ..writeln('\t\tspec_document_free(doc);')
        ..writeln('\t\tfree(doc);')
        ..writeln('\t\treturn 1;')
        ..writeln('\t}')
        ..writeln('\t*out_doc = doc;')
        ..writeln('\treturn 0;')
        ..writeln('}')
        ..writeln('int ${plan.loadFileFn}($t *self, const char *path, '
            'SpecDocument **out_doc, char **err) {')
        ..writeln('\tSpecDocument *doc = spec_document_from_file(path);')
        ..writeln('\tif (doc == NULL) {')
        ..writeln('\t\treturn 1;')
        ..writeln('\t}')
        ..writeln('\tif (${plan.lifecycleFn}(self, doc, doc->model_version, err) '
            '!= 0) {')
        ..writeln('\t\tspec_document_free(doc);')
        ..writeln('\t\tfree(doc);')
        ..writeln('\t\treturn 1;')
        ..writeln('\t}')
        ..writeln('\t*out_doc = doc;')
        ..writeln('\treturn 0;')
        ..writeln('}');
    } else {
      b
        ..writeln('void ${plan.lifecycleFn}($t *self, SpecDocument *doc, '
            'const char *path) {')
        ..writeln('\tsom_node_init(&self->node, doc, path);')
        ..writeln('}');
    }
    b
      ..writeln('void ${plan.freeFn}($t *self) {')
      ..writeln('\tsom_node_free(&self->node);')
      ..writeln('}');
    // § item 10: per-type structural `content`-leaf predicate — a compile-time
    // literal per generated type (see `_declClass`), mirroring the item-8
    // `editability_for` / item-5 `is_empty` per-type C emission.
    final literal = _hasContentLeaf(plan.cls) ? '1' : '0';
    b
      ..writeln('int ${plan.canHaveContentFn}(const $t *self) {')
      ..writeln('\t(void)self;')
      ..writeln('\treturn $literal;')
      ..writeln('}');
    for (final f in plan.cls.fields) {
      _defineField(b, plan, f);
    }
  }

  void _defineField(StringBuffer b, _ClassPlan plan, SpecField f) {
    final t = plan.typeName;
    final get = plan.getFn[f.name]!;
    final seg = _cStr(_ref.fieldSegment(f));
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
        _emitStringGetter(b, t, get, seg);
        _emitStringSetter(b, t, plan.setFn[f.name]!, seg);
        break;
      case SpecFieldKind.enumValue:
        if (f.enumType == null) {
          _emitStringGetter(b, t, get, seg);
        } else {
          final parse = _parseName[f.enumType!]!;
          b
            ..writeln('char *$get(const $t *self) {')
            ..writeln('\tchar *path = spec_path_join(self->node.path, '
                '"$seg");')
            ..writeln('\tconst char *v = spec_document_content('
                'self->node.doc, path);')
            ..writeln('\tchar *out = $parse(v != NULL ? v : "");')
            ..writeln('\tfree(path);')
            ..writeln('\treturn out;')
            ..writeln('}');
        }
        _emitStringSetter(b, t, plan.setFn[f.name]!, seg);
        break;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        if (f.type == null) break;
        final childInit = _classPlans[f.type!]?.lifecycleFn;
        if (childInit == null) break;
        b
          ..writeln('${f.type} $get(const $t *self) {')
          ..writeln('\tchar *path = spec_path_join(self->node.path, "$seg");')
          ..writeln('\t${f.type} out;')
          ..writeln('\t$childInit(&out, self->node.doc, path);')
          ..writeln('\tfree(path);')
          ..writeln('\treturn out;')
          ..writeln('}');
        break;
      case SpecFieldKind.list:
        final pat = _cStr(f.sectionIdPattern ?? '');
        b
          ..writeln('SomList $get(const $t *self) {')
          ..writeln('\tchar *path = spec_path_join(self->node.path, "$seg");')
          ..writeln('\tSomList out;')
          ..writeln('\tsom_list_init_pattern(&out, self->node.doc, path, '
              '"$pat");')
          ..writeln('\tfree(path);')
          ..writeln('\treturn out;')
          ..writeln('}');
        break;
      case SpecFieldKind.form:
        final formType = plan.formTypeFor[f.name]!;
        final fp = _formPlans.firstWhere((p) => p.typeName == formType);
        b
          ..writeln('$formType $get(const $t *self) {')
          ..writeln('\tchar *path = spec_path_join(self->node.path, "$seg");')
          ..writeln('\t$formType out;')
          ..writeln('\t${fp.initFn}(&out, self->node.doc, path);')
          ..writeln('\tfree(path);')
          ..writeln('\treturn out;')
          ..writeln('}');
        break;
    }
  }

  void _emitStringGetter(StringBuffer b, String t, String get, String seg) {
    b
      ..writeln('char *$get(const $t *self) {')
      ..writeln('\tchar *path = spec_path_join(self->node.path, "$seg");')
      ..writeln('\tconst char *v = spec_document_content(self->node.doc, path);')
      ..writeln('\tchar *out = som_strdup(v != NULL ? v : "");')
      ..writeln('\tfree(path);')
      ..writeln('\treturn out;')
      ..writeln('}');
  }

  void _emitStringSetter(StringBuffer b, String t, String set, String seg) {
    b
      ..writeln('void $set($t *self, const char *value) {')
      ..writeln('\tchar *path = spec_path_join(self->node.path, "$seg");')
      ..writeln('\tspec_document_set_content(self->node.doc, path, value);')
      ..writeln('\tfree(path);')
      ..writeln('}');
  }

  void _defineForm(StringBuffer b, _FormPlan fp) {
    final t = fp.typeName;
    b
      ..writeln('void ${fp.initFn}($t *self, SpecDocument *doc, '
          'const char *path) {')
      ..writeln('\tsom_node_init(&self->node, doc, path);')
      ..writeln('}')
      ..writeln('void ${fp.freeFn}($t *self) {')
      ..writeln('\tsom_node_free(&self->node);')
      ..writeln('}');
    for (final ff in fp.field.formFields) {
      final field = _cStr(ff.name);
      b
        ..writeln('char *${fp.getFn[ff.name]}(const $t *self) {')
        ..writeln('\tconst char *v = spec_document_form_field(self->node.doc, '
            'self->node.path, "$field");')
        ..writeln('\treturn som_strdup(v != NULL ? v : "");')
        ..writeln('}')
        ..writeln('void ${fp.setFn[ff.name]}($t *self, const char *value) {')
        ..writeln('\tspec_document_set_form_field(self->node.doc, '
            'self->node.path, "$field", value);')
        ..writeln('}');
    }
  }

  // --- reachability --------------------------------------------------------

  Set<String> _reachableClasses(Set<String> rootTypes) {
    final visited = <String>{};
    final queue = <String>[...rootTypes];
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
    return visited;
  }

  List<_EnumType> _reachableEnums(Set<String> reachable) {
    final byName = <String, _EnumType>{};
    for (final name in reachable) {
      final cls = model.classNamed(name);
      if (cls == null) continue;
      for (final f in cls.fields) {
        if (f.kind == SpecFieldKind.enumValue && f.enumType != null) {
          byName.putIfAbsent(
              f.enumType!, () => _EnumType(f.enumType!, f.enumValues));
        }
      }
    }
    final result = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  // --- text helpers --------------------------------------------------------

  void _fileBanner(StringBuffer b, String which) {
    b
      ..writeln('/* GENERATED by tom_specs_clitool SomCEmitter ($versionLabel) '
          '— do not edit by hand. */')
      ..writeln('/* Typed object-model facade ($which) over the generic '
          'tom_som_c_runtime document. */')
      ..writeln();
  }

  /// Emits a doc block as `//` comment lines at the given indent prefix.
  void _doc(StringBuffer b, String? doc, String indent) {
    if (doc == null || doc.trim().isEmpty) return;
    for (final line in doc.trimRight().split('\n')) {
      final text = line.trimRight();
      b.writeln(text.isEmpty ? '$indent//' : '$indent// $text');
    }
  }

  /// Escapes a value for a double-quoted C string literal.
  String _cStr(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  /// A snake-cased accessor base for [name]; C keywords gain a trailing
  /// underscore. Empty ⇒ `field`.
  String _snakeAccessor(String name) {
    var base = _snake(name);
    if (base.isEmpty) base = 'field';
    if (_cKeywords.contains(base)) base = '${base}_';
    return base;
  }

  String _pascal(String s) {
    final parts = s.split(RegExp(r'[_\s]+')).where((p) => p.isNotEmpty);
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  String _snake(String s) {
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '_' || c == ' ' || c == '-') {
        buf.write('_');
        continue;
      }
      final isUpper = _isUpper(c);
      if (isUpper && i > 0) {
        final prev = s[i - 1];
        if (_isLower(prev) || _isDigit(prev)) buf.write('_');
      }
      buf.write(c.toLowerCase());
    }
    var out = buf.toString().replaceAll(RegExp(r'_+'), '_');
    out = out.replaceAll(RegExp(r'^_+|_+$'), '');
    return out;
  }

  String _screamingSnake(String s) => _snake(s).toUpperCase();

  bool _isUpper(String c) => c.toUpperCase() == c && c.toLowerCase() != c;
  bool _isLower(String c) => c.toLowerCase() == c && c.toUpperCase() != c;
  bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
}

class _EnumType {
  final String name;
  final List<String> values;
  _EnumType(this.name, this.values);
}

class _EnumConst {
  final String ident;
  final String token;
  _EnumConst(this.ident, this.token);
}

class _PendingForm {
  final String owner;
  final SpecField field;
  final String typeName;
  _PendingForm(this.owner, this.field, this.typeName);
}

class _ClassPlan {
  final SpecClass cls;
  final String typeName;
  final String name;
  final bool isRoot;
  late String lifecycleFn; // `_init` (non-root) or `_new` (root)
  late String freeFn;
  late String canHaveContentFn; // `_can_have_content` (every type)
  String? omvFn;
  String? editabilityFn; // `_editability_for` (root only)
  String? mvConst;
  String? rootSeg;
  String? loadYamlFn; // `_load_yaml` (root only)
  String? loadFileFn; // `_load_file` (root only)
  final Map<String, String> getFn = {};
  final Map<String, String> setFn = {};
  final Map<String, String> formTypeFor = {};
  _ClassPlan(this.cls, this.name, this.isRoot) : typeName = cls.name;
}

class _FormPlan {
  final String typeName;
  final SpecField field;
  late String initFn;
  late String freeFn;
  final Map<String, String> getFn = {};
  final Map<String, String> setFn = {};
  _FormPlan(this.typeName, this.field);
}
