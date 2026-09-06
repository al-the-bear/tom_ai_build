/// Emits the generated C typed object model (`tom_som_c_v0`) from a resolved
/// [SpecModel].
///
/// The generated accessors are an **editing facade** over the generic
/// `tom_som_c_runtime` `SpecDocument`: every typed accessor delegates to the
/// path-keyed memory representation, so a typed mutation is visible through the
/// generic path and vice-versa (SOM §6). Each document-root performs the
/// **instantiation-time version check** (`check_som_model_version`) against the
/// document's authoring stamp (SOM §4.2) and exposes its own generated model
/// version (SOM §4.2).
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

import 'som_structural_accessors.dart';
import 'spec_object_model_config.dart' show SomLanguage;

/// The header include-guard macro and the generated file basenames.
const String _headerGuard = 'TOM_SOM_C_V0_H';
const String _headerBasename = 'tom_som_c_v0.h';
const String _metaHeaderBasename = 'tom_som_c_v0_meta.h';

/// Generates the `tom_som_c_v0` header + source for a [SpecModel].
class SomCEmitter {
  /// The resolved model the emission walks: its `@Document` roots seed the
  /// reachability set, and only the classes, enums and `@Form` fields reachable
  /// from the selected roots are emitted — an unreferenced model class produces
  /// no C at all.
  final SpecModel model;
  final SpecReflection _ref;

  /// The version label of the generated project (`v0`, `v1`, …).
  final String versionLabel;

  /// The document-root type names to generate. Empty ⇒ every root in the model.
  final List<String> documentRoots;

  /// Binds the emitter to [model] — the one required argument, because every
  /// name, path segment and version string is derived from it.
  ///
  /// Both named arguments default to the whole-model case: [versionLabel] `v0`
  /// names the output project only (the reported model version comes from the
  /// model's own stamp), and an empty [documentRoots] means "every root in the
  /// model". Narrowing [documentRoots] shrinks the reachability set, so it
  /// changes which classes are emitted — not just which roots get a
  /// constructor.
  SomCEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
  }) : _ref = SpecReflection(model);

  /// The model version the generated object model reports (SOM §4.2),
  /// `major.minor`, taken from the model's own version stamp (the
  /// `tom_specs_model` project version), not the project [versionLabel] — which
  /// only names the `_vN` output project.
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
      if (!fp.hasContentMember) {
        fp.contentGetFn = _alloc(_funcNames, '${prefix}_content');
        fp.contentSetFn = _alloc(_funcNames, '${prefix}_set_content');
      }
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

  /// True when any reachable `@Form` field projects to a non-`String` typed
  /// member (`int`/`double`/`num`/`bool`) — which pulls in `<stdbool.h>` for the
  /// header's `bool` returns and `<stdio.h>` for the source's `snprintf`.
  bool _hasTypedFormMember() {
    for (final fp in _formPlans) {
      for (final ff in fp.field.formFields) {
        if (_scalarType(ff.type) != 'String') return true;
      }
    }
    return false;
  }

  /// Maps a `@Form` field's declared type name to the primitive scalar kind the
  /// facade should expose, or `'String'` for any non-primitive (enums, `List`,
  /// unresolved types) so the generated code always compiles.
  static String _scalarType(String typeName) {
    final base = typeName.endsWith('?')
        ? typeName.substring(0, typeName.length - 1)
        : typeName;
    switch (base) {
      case 'int':
      case 'double':
      case 'num':
      case 'bool':
        return base;
      default:
        return 'String';
    }
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
      // The generated metadata surface (SOM §8: the dot-notation / ID-tree
      // access trees and the per-root `<root>_meta_tree()` entry points) is
      // part of this facade's public API, so a single facade include exposes
      // both the typed editing structs and the structural navigation surface.
      ..writeln('#include "$_metaHeaderBasename"');
    if (_hasTypedFormMember()) {
      // Typed `@Form` members expose `bool` returns for boolean form fields.
      b.writeln('#include <stdbool.h>');
    }
    b.writeln();

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
              'model was generated against (SOM §4.2).')
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

    b.writeln('#endif /* $_headerGuard */');
    return b.toString().replaceAll('\t', '  ');
  }

  void _declClass(StringBuffer b, _ClassPlan plan) {
    final t = plan.typeName;
    _doc(b, plan.cls.doc, '');
    if (plan.isRoot) {
      b
        ..writeln('// Creates the typed facade at the document root and verifies '
            "the document's")
        ..writeln('// authoring version is editable (SOM §4.2). Returns 0 on '
            'success; on a non-editable')
        ..writeln('// stamp returns non-zero and, when `err` is non-NULL, '
            'writes an owned message.')
        ..writeln('int ${plan.lifecycleFn}($t *self, SpecDocument *doc, '
            'const char *document_version, char **err);')
        ..writeln("// Returns this object model's own model version "
            '(major.minor), per SOM §4.2.')
        ..writeln('const char *${plan.omvFn}(const $t *self);')
        ..writeln('// Classifies whether a document authored under '
            '`document_version` is editable')
        ..writeln('// by this object model, without reporting an error '
            "(SOM §21) — the non-erroring")
        ..writeln("// companion to ${plan.lifecycleFn}'s SOM §4.2 check, so a "
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
        ..writeln('// thread-`document_version` sequence (SOM §21). The owned '
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
    // SOM §21: a per-type structural predicate answering "does this TYPE
    // declare the standard `content` text leaf?" — "can this node hold
    // body text?" — without probing the document. C has no inheritance or
    // method promotion, so (following the `editability_for` / `is_empty`
    // per-type C precedent) every generated type emits its own
    // accessor returning the literal answer: 1 for a type carrying a `content`
    // leaf, 0 for one that declares none. Since `tom_specs_model_rules.md`
    // §10.2 requires `content: String?` on every section class, every emitted
    // type currently takes the 1 branch. It is deliberately distinct from the STATE
    // predicates `spec_document_has_content` ("value present now?") and
    // `som_node_is_empty` ("subtree empty now?"): it describes the model, not
    // the data.
    b.writeln('// Returns 1 iff this section type declares the standard `content`'
        ' text leaf (SOM §21).');
    b.writeln('int ${plan.canHaveContentFn}(const $t *self);');
    for (final f in plan.cls.fields) {
      _declField(b, plan, f);
    }
  }

  /// Whether [cls] declares the standard `content` text leaf — the structural
  /// signal that its generated facade carries a `content` accessor (SOM §21).
  /// A `@Unused()` on the member does **not** make this `false`: that
  /// annotation says no prose is *expected* (`tom_specs_model_rules.md`
  /// §5.6), not that the slot is absent.
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
      ..writeln('// $t is the generated section facade for the '
          '`${fp.field.name}` @Form section: its own `content` text followed '
          'by one typed member per form field.')
      ..writeln('void ${fp.initFn}($t *self, SpecDocument *doc, '
          'const char *path);')
      ..writeln('void ${fp.freeFn}($t *self);');
    if (fp.contentGetFn != null) {
      b
        ..writeln('// The section\'s own free-text content, before the form '
            'fields (owned).')
        ..writeln('char *${fp.contentGetFn}(const $t *self);')
        ..writeln('void ${fp.contentSetFn}($t *self, const char *value);');
    }
    for (final ff in fp.field.formFields) {
      switch (_scalarType(ff.type)) {
        case 'int':
          b.writeln('long ${fp.getFn[ff.name]}(const $t *self);');
          b.writeln('void ${fp.setFn[ff.name]}($t *self, long value);');
        case 'double':
        case 'num':
          b.writeln('double ${fp.getFn[ff.name]}(const $t *self);');
          b.writeln('void ${fp.setFn[ff.name]}($t *self, double value);');
        case 'bool':
          b.writeln('bool ${fp.getFn[ff.name]}(const $t *self);');
          b.writeln('void ${fp.setFn[ff.name]}($t *self, bool value);');
        default:
          b.writeln('char *${fp.getFn[ff.name]}(const $t *self);');
          b.writeln(
              'void ${fp.setFn[ff.name]}($t *self, const char *value);');
      }
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
      ..writeln('#include "$_metaHeaderBasename"')
      ..writeln()
      ..writeln('#include <stdlib.h>')
      ..writeln('#include <string.h>');
    if (_hasTypedFormMember()) {
      // Typed `@Form` member setters format scalar values with `snprintf`.
      b.writeln('#include <stdio.h>');
    }
    b.writeln();

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
        ..writeln('\tSpecDocument *doc = spec_document_from_yaml(yaml, '
            '${_treeFnName(plan)}(), err);')
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
        ..writeln('}')
        ..writeln('int ${plan.loadFileFn}($t *self, const char *path, '
            'SpecDocument **out_doc, char **err) {')
        ..writeln('\tSpecDocument *doc = spec_document_from_file(path, '
            '${_treeFnName(plan)}(), err);')
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
    // SOM §21: per-type structural `content`-leaf predicate — a compile-time
    // literal per generated type (see `_declClass`), mirroring the
    // `editability_for` / `is_empty` per-type C emission.
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
    if (fp.contentGetFn != null) {
      b
        ..writeln('char *${fp.contentGetFn}(const $t *self) {')
        ..writeln('\tconst char *v = spec_document_content(self->node.doc, '
            'self->node.path);')
        ..writeln('\treturn som_strdup(v != NULL ? v : "");')
        ..writeln('}')
        ..writeln('void ${fp.contentSetFn}($t *self, const char *value) {')
        ..writeln('\tspec_document_set_content(self->node.doc, '
            'self->node.path, value);')
        ..writeln('}');
    }
    for (final ff in fp.field.formFields) {
      final field = _cStr(ff.name);
      final get = fp.getFn[ff.name]!;
      final set = fp.setFn[ff.name]!;
      switch (_scalarType(ff.type)) {
        case 'int':
          b
            ..writeln('long $get(const $t *self) {')
            ..writeln('\tconst char *v = spec_document_form_field('
                'self->node.doc, self->node.path, "$field");')
            ..writeln('\treturn (v != NULL && *v) ? atol(v) : 0;')
            ..writeln('}')
            ..writeln('void $set($t *self, long value) {')
            ..writeln('\tchar buf[32];')
            ..writeln('\tsnprintf(buf, sizeof(buf), "%ld", value);')
            ..writeln('\tspec_document_set_form_field(self->node.doc, '
                'self->node.path, "$field", buf);')
            ..writeln('}');
        case 'double':
        case 'num':
          b
            ..writeln('double $get(const $t *self) {')
            ..writeln('\tconst char *v = spec_document_form_field('
                'self->node.doc, self->node.path, "$field");')
            ..writeln('\treturn (v != NULL && *v) ? strtod(v, NULL) : 0.0;')
            ..writeln('}')
            ..writeln('void $set($t *self, double value) {')
            ..writeln('\tchar buf[32];')
            ..writeln('\tsnprintf(buf, sizeof(buf), "%g", value);')
            ..writeln('\tspec_document_set_form_field(self->node.doc, '
                'self->node.path, "$field", buf);')
            ..writeln('}');
        case 'bool':
          b
            ..writeln('bool $get(const $t *self) {')
            ..writeln('\tconst char *v = spec_document_form_field('
                'self->node.doc, self->node.path, "$field");')
            ..writeln('\treturn v != NULL && strcmp(v, "true") == 0;')
            ..writeln('}')
            ..writeln('void $set($t *self, bool value) {')
            ..writeln('\tspec_document_set_form_field(self->node.doc, '
                'self->node.path, "$field", value ? "true" : "false");')
            ..writeln('}');
        default:
          b
            ..writeln('char *$get(const $t *self) {')
            ..writeln('\tconst char *v = spec_document_form_field('
                'self->node.doc, self->node.path, "$field");')
            ..writeln('\treturn som_strdup(v != NULL ? v : "");')
            ..writeln('}')
            ..writeln('void $set($t *self, const char *value) {')
            ..writeln('\tspec_document_set_form_field(self->node.doc, '
                'self->node.path, "$field", value);')
            ..writeln('}');
      }
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

  /// The structural `SomNode` members a generated accessor must not take
  /// (`som_structural_accessors.dart`).
  ///
  /// This set is **empty for C** and is read from the shared table anyway: the C
  /// facade has no type to inherit from, and every emitted function name is
  /// allocated as `<type>_<accessor>` from one flat, deduplicated namespace — so
  /// a field named `can_have_content` is renamed rather than silently overriding
  /// anything. Consulting the table costs nothing and means the guard is already
  /// wired if C's shape ever changes.
  static final Set<String> _structural = somReservedAccessorNames(SomLanguage.c);

  /// A snake-cased accessor base for [name]; C keywords and structural member
  /// names gain a trailing underscore. Empty ⇒ `field`.
  String _snakeAccessor(String name) {
    var base = _snake(name);
    if (base.isEmpty) base = 'field';
    if (_cKeywords.contains(base) || _structural.contains(base)) {
      base = '${base}_';
    }
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

  /// The generated per-root meta-tree accessor name of a root plan — must match
  /// `SomCMetaEmitter._treeFn` (`<snake(rootType)>_meta_tree`).
  String _treeFnName(_ClassPlan plan) => '${_snake(plan.name)}_meta_tree';

  bool _isUpper(String c) => c.toUpperCase() == c && c.toLowerCase() != c;
  bool _isLower(String c) => c.toLowerCase() == c && c.toUpperCase() != c;
  bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
}

class _EnumType {
  /// The model enum's type name. C emits no enum type — the name only seeds the
  /// SCREAMING_SNAKE `#define` prefix and the `parse_<snake>` helper name.
  final String name;

  /// The stored document tokens, in model declaration order. They are emitted
  /// verbatim as the `#define` values, so they are the on-disk encoding shared
  /// with every other language port — not display labels.
  final List<String> values;
  _EnumType(this.name, this.values);
}

class _EnumConst {
  /// The `#define` identifier (`<ENUM>_<VALUE>`, or `<ENUM>_VALUE_<n>` when the
  /// token snake-cases to nothing). Allocated from the shared value namespace,
  /// so it may carry a `_2` suffix if the obvious name was already taken.
  final String ident;

  /// The document token the identifier expands to — the literal string stored
  /// in the YAML, which must stay byte-identical across language ports.
  final String token;
  _EnumConst(this.ident, this.token);
}

class _PendingForm {
  /// The model class declaring the `@Form` field. Kept so the allocated struct
  /// name can be written back into that class's `formTypeFor` map after the
  /// forms have been sorted.
  final String owner;

  /// The `@Form` field itself: its `formFields` are the emitted typed members
  /// and its name is the document segment they hang off.
  final SpecField field;

  /// The struct name already allocated from the shared type namespace. Forms
  /// are sorted by it before any function name is allocated, so the flat C
  /// function namespace fills in an order independent of model declaration
  /// order — which is what makes re-runs byte-stable.
  final String typeName;
  _PendingForm(this.owner, this.field, this.typeName);
}

class _ClassPlan {
  /// The resolved model class being emitted — the field list walked by both the
  /// header and the source pass, so the two stay in the same order.
  final SpecClass cls;

  /// The emitted struct typedef name. Model class names are taken verbatim, so
  /// this is the one generated type name that is never allocated; form struct
  /// names are allocated around it.
  final String typeName;

  /// The model class name under which the plan is registered. Also the stem of
  /// every emitted function prefix and of the metadata module's
  /// `<snake>_meta_tree` accessor this facade calls into, so it must match the
  /// name `SomCMetaEmitter` derived its tree function from.
  final String name;

  /// Whether the class is one of the selected `@Document` roots. Roots get the
  /// version-checking constructor, the load helpers and a per-root model-version
  /// constant (SOM §4.2); non-roots get only a path-binding initialiser.
  final bool isRoot;

  /// The binding function: `<prefix>_new` on a root, which checks the document's
  /// authoring stamp (SOM §4.2) and returns non-zero with an owned message
  /// through `char **err` when the stamp is not editable; `<prefix>_init` on a
  /// child facade, which returns `void` because binding a child cannot fail.
  late String lifecycleFn; // `_init` (non-root) or `_new` (root)

  /// The `<prefix>_free` releasing the bound node. Emitted for every type so a
  /// caller can pair it with the binder without knowing whether it holds a root.
  late String freeFn;

  /// The `<prefix>_can_have_content` **schema** predicate (SOM §21) — "does this
  /// section type declare the standard `content` leaf?", compiled in as a
  /// literal. Deliberately distinct from the runtime state queries
  /// (`spec_document_has_content`, `som_node_is_empty`): it describes the model,
  /// not the data.
  late String canHaveContentFn; // `_can_have_content` (every type)

  /// The root's `<prefix>_object_model_version` accessor, returning the model
  /// version the generated facade reports (SOM §4.2). `null` on a non-root —
  /// only a document root carries a version.
  String? omvFn;

  /// The root's `<prefix>_editability_for`: the read-only companion to the
  /// SOM §4.2 check in `lifecycleFn`, so a caller can classify a document stamp
  /// without constructing (and failing). `null` on a non-root.
  String? editabilityFn; // `_editability_for` (root only)

  /// The `<ROOT>_MODEL_VERSION` `#define` name holding the generated model
  /// version string that the constructor compares the document stamp against.
  /// `null` on a non-root.
  String? mvConst;

  /// The document path segment the root binds at. Every accessor path below the
  /// facade is built from it, so it has to be the same segment the generic
  /// runtime and the other language ports store — it is read from the model, not
  /// derived from the class name. `null` on a non-root.
  String? rootSeg;

  /// The root's `<prefix>_load_yaml`: parses YAML through the generic runtime
  /// (threading this root's metadata tree into the decoder) and binds the
  /// result, failing on a non-editable stamp. `null` on a non-root.
  String? loadYamlFn; // `_load_yaml` (root only)

  /// The root's `<prefix>_load_file` — `loadYamlFn` over a file's contents,
  /// reporting through the same `char **err` out-parameter when the file cannot
  /// be read. `null` on a non-root.
  String? loadFileFn; // `_load_file` (root only)

  /// Getter function name per model field name; every field has an entry. The
  /// C return type follows the field kind — owned `char *` for a value leaf, a
  /// child facade or form struct by value, `SomList` for a list.
  final Map<String, String> getFn = {};

  /// Setter function name per model field name, present only for the kinds the
  /// facade can write (value leaves, enums, content). A missing key therefore
  /// means "this accessor is read-only", not "not allocated yet" — the field
  /// emitter dereferences it unconditionally for the writable kinds.
  final Map<String, String> setFn = {};

  /// Form struct name per `@Form` field name, filled only after the form plans
  /// have been sorted and named. It is what tells the field emitter which struct
  /// the owning class's accessor returns by value.
  final Map<String, String> formTypeFor = {};
  _ClassPlan(this.cls, this.name, this.isRoot) : typeName = cls.name;
}

class _FormPlan {
  /// The generated struct name for this form section (`<Owner><Field>Form`),
  /// allocated against the shared type namespace so it cannot shadow a model
  /// class or an enum helper.
  final String typeName;

  /// The owning `@Form` field. Its `formFields` list fixes the emission order of
  /// the typed members, and each member is read back out of the document by
  /// name, not by position.
  final SpecField field;

  /// `<prefix>_init`, binding the struct to a document and an absolute path. A
  /// form is always a child facade, so binding cannot fail and it returns
  /// `void`.
  late String initFn;

  /// `<prefix>_free`, releasing the bound node's path storage. Pairing it with
  /// `initFn` is the caller's job — the struct is returned by value and owns
  /// heap state.
  late String freeFn;

  /// The form section's own `content` text getter — the prose that precedes the
  /// form fields. `null` exactly when [hasContentMember] is true, because the
  /// form's own field of that name would otherwise claim the same accessor name.
  String? contentGetFn;

  /// The setter paired with [contentGetFn], and `null` under the same
  /// condition; the two are always allocated together.
  String? contentSetFn;

  /// Getter function name per form-field name. The C return type follows the
  /// declared scalar type (`long`, `double`, `int` for bool, owned `char *` for
  /// text), and a missing or unparsable stored value yields the type's zero
  /// rather than an error.
  final Map<String, String> getFn = {};

  /// Setter function name per form-field name. Every form field is writable, so
  /// this map always has the same keys as [getFn].
  final Map<String, String> setFn = {};

  _FormPlan(this.typeName, this.field);

  /// True when the form declares a field literally named `content`, which
  /// shadows the section's own body text: the generated struct then omits the
  /// `_content` / `_set_content` pair so a single C name cannot mean two things.
  bool get hasContentMember => field.formFields.any((ff) => ff.name == 'content');
}
