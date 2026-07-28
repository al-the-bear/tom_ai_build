/// Emits the generated Go typed object model (`tom_som_go_v0`) from a resolved
/// [SpecModel].
///
/// The generated structs are an **editing facade** over the generic
/// `tom_som_go_runtime` `SpecDocument`: every typed accessor delegates to the
/// path-keyed memory representation, so a typed mutation is visible through the
/// generic path and vice-versa (SOM §6). Each document-root struct performs
/// the **instantiation-time version check** (`som.CheckSomModelVersion`)
/// against the document's authoring stamp (SOM §4.2) and exposes its own
/// generated model version (SOM §4.2).
///
/// This is the Go counterpart of [SomDartEmitter] / `SomPythonEmitter` /
/// `SomJavaEmitter` / `SomJavaScriptEmitter` / `SomTypeScriptEmitter` — the same
/// reachability walk, the same deterministic ordering, the same field-kind
/// mapping. Go has no classes, exceptions, or enums, so the surface is idiomatic:
///
///   * each model class becomes a `struct` embedding `som.SomNode`, with
///     **exported (Pascal-cased) method accessors** (`Vision()` /
///     `SetVision(string)`);
///   * the bound document/path, the section id, the headline, the CodeSpecs
///     link and the two content predicates are reached through the embedded
///     node's promoted methods — so a model field that Pascal-cases onto any of
///     them would *shadow* the promoted method silently. The whole structural
///     surface is reserved, from the one table in
///     `som_structural_accessors.dart` that all nine emitters share;
///   * enums become exported string constants + an unexported `parse<Enum>`
///     helper (the stored token stays byte-identical across languages);
///   * the version check returns `*som.SomVersionError`, so root constructors
///     return `(*T, error)`.
///
/// The generated module imports the runtime through its **domain-qualified
/// module path** (`github.com/al-the-bear/tom_ai_build/tom_som_go_runtime`); the
/// generator wires local resolution by writing a `go.mod` with a `require` +
/// local `replace` directive, so the emitted source carries no on-disk path and
/// stays layout-independent / golden-stable while still resolving under an
/// external `go get`.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'som_structural_accessors.dart';
import 'spec_object_model_config.dart' show SomLanguage;

import 'packaging.dart' show packageVersionFromModel;

/// Generates the `tom_som_go_v0` module source for a [SpecModel].
class SomGoEmitter {
  /// The domain-qualified module path of the generic runtime the facade imports.
  /// External `go get` resolves this path via VCS; local builds resolve it via
  /// the `replace` directive the generator writes into the facade `go.mod`.
  static const String _runtimeModulePath =
      'github.com/al-the-bear/tom_ai_build/tom_som_go_runtime';

  final SpecModel model;
  final SpecReflection _ref;

  /// The version label of the generated project (`v0`, `v1`, …); names the
  /// `tom_som_<slug>_<label>` output project. It no longer drives the reported
  /// model version — see [modelVersionString].
  final String versionLabel;

  /// The document-root type names to generate. Empty ⇒ every root in the model.
  final List<String> documentRoots;

  /// The Go package name of the generated module (the emitted `package` clause).
  final String packageName;

  SomGoEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
    this.packageName = 'somv0',
  }) : _ref = SpecReflection(model);

  /// The model version the generated object model reports (SOM §4.2),
  /// `major.minor`, taken from the model's own version stamp (the
  /// `tom_specs_model` project version), not the project [versionLabel] — which
  /// only names the `_vN` output project.
  String get modelVersionString => model.modelVersionString;

  /// The roots to generate, resolved against [documentRoots] (empty ⇒ all).
  List<SpecRoot> get _selectedRoots {
    if (documentRoots.isEmpty) return model.roots;
    final wanted = documentRoots.toSet();
    return model.roots.where((r) => wanted.contains(r.type)).toList();
  }

  /// Every package-level identifier allocated in the current [generateLibrary]
  /// run. Go has a **single, flat package namespace** shared by types,
  /// functions, and constants — so a type `NewX` and a constructor `func NewX`
  /// collide. This registry is the authority that keeps all of them unique;
  /// names that collide gain the smallest numeric suffix (`2`, `3`, …).
  final Set<String> _packageIdents = {};

  /// Constructor function name for each generated type (model class *or* form
  /// class), e.g. `OrganizationStructure → NewOrganizationStructure2` when the
  /// idiomatic `NewOrganizationStructure` is already a type name.
  final Map<String, String> _ctorName = {};

  /// Generated form-struct name keyed by `'<className>::<fieldName>'`.
  final Map<String, String> _formNameFor = {};

  /// Generated model-version constant name keyed by root type name.
  final Map<String, String> _modelVersionConst = {};

  /// Generated enum constants keyed by enum type name (allocation order = value
  /// order), and the `parse<Enum>` helper name keyed by enum type name.
  final Map<String, List<_EnumConst>> _enumConsts = {};
  final Map<String, String> _parseName = {};

  /// Reserves [base] as a package-level identifier, appending the smallest
  /// numeric suffix that keeps it unique across the whole module.
  String _alloc(String base) {
    if (_packageIdents.add(base)) return base;
    var n = 2;
    while (!_packageIdents.add('$base$n')) {
      n++;
    }
    return '$base$n';
  }

  /// Builds the complete generated module as a single Go source string.
  String generateLibrary() {
    _packageIdents.clear();
    _ctorName.clear();
    _formNameFor.clear();
    _modelVersionConst.clear();
    _enumConsts.clear();
    _parseName.clear();

    final rootTypes = _selectedRoots.map((r) => r.type).toSet();
    final reachable = _reachableClasses(rootTypes);
    final enums = _reachableEnums(reachable);
    final sortedClasses = reachable.toList()..sort();
    // YRB2: typed `@Form` members parse their stored text via `strconv`, so the
    // module imports it only when at least one non-String scalar member exists.
    final needsStrconv = _hasTypedFormMember(reachable);

    _allocatePackageNames(sortedClasses, enums, rootTypes);

    final buffer = StringBuffer()
      ..writeln('// GENERATED by tom_specs_clitool SomGoEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('//')
      ..writeln('// Typed object-model facade over the generic '
          '`tom_som_go_runtime` document.')
      ..writeln('//')
      ..writeln('// The generic runtime is imported through its domain-qualified '
          'module path; the')
      ..writeln('// generator wires local resolution by writing a `go.mod` with a '
          '`require` + local')
      ..writeln('// `replace` directive, so this module builds both standalone '
          '(`go get`) and in-repo.')
      ..writeln('//')
      ..writeln('// The generated metadata module (SOM §8) — the populated '
          'SomMetaTrees plus the')
      ..writeln('// dot-notation and ID-tree access surfaces — lives in the '
          'sibling `_meta.go` file')
      ..writeln('// of this same package, so one import surfaces both access '
          'styles.')
      ..writeln('package $packageName')
      ..writeln();
    if (needsStrconv) {
      buffer
        ..writeln('import (')
        ..writeln('\t"strconv"')
        ..writeln()
        ..writeln('\tsom "$_runtimeModulePath"')
        ..writeln(')');
    } else {
      buffer.writeln('import som "$_runtimeModulePath"');
    }
    buffer
      ..writeln()
      ..writeln('// Version is the semantic version of this generated facade '
          'module, matching the')
      ..writeln('// object-model version it was generated against '
          '(vMAJOR.MINOR.PATCH). It is the')
      ..writeln('// in-source counterpart of the VCS tag used to pin the module '
          '(SOM §4.2).')
      ..writeln('const Version = "v${packageVersionFromModel(modelVersionString)}"')
      ..writeln();

    for (final e in enums) {
      buffer
        ..write(_emitEnum(e))
        ..writeln();
    }

    final formClasses = <_FormClass>[];
    for (final name in sortedClasses) {
      final cls = model.classNamed(name);
      if (cls == null) continue;
      buffer
        ..write(_emitClass(cls,
            isRoot: rootTypes.contains(name),
            collectForm: (fc) => formClasses.add(fc)))
        ..writeln();
    }
    for (final fc in formClasses..sort((a, b) => a.name.compareTo(b.name))) {
      buffer
        ..write(fc.source)
        ..writeln();
    }

    // gofmt strips trailing blank lines — end with exactly one newline.
    return '${buffer.toString().trimRight()}\n';
  }

  /// Allocates every package-level identifier up front so emission can reference
  /// already-resolved, collision-free names. Order is deterministic (sorted),
  /// so the generated module is byte-stable across runs.
  void _allocatePackageNames(
      List<String> sortedClasses, List<_EnumType> enums, Set<String> roots) {
    // 1. Type names for model classes are unique map keys — reserve verbatim.
    for (final n in sortedClasses) {
      _packageIdents.add(n);
    }
    // 2. Form-struct type names (unique among themselves *and* model classes).
    for (final n in sortedClasses) {
      final cls = model.classNamed(n);
      if (cls == null) continue;
      for (final f in cls.fields) {
        if (f.kind == SpecFieldKind.form) {
          _formNameFor['$n::${f.name}'] = _alloc('$n${_pascal(f.name)}Form');
        }
      }
    }
    // 3. Enum `parse` helpers and value constants.
    for (final e in enums) {
      _parseName[e.name] = _alloc('parse${e.name}');
      final consts = <_EnumConst>[];
      var idx = 0;
      for (final v in e.values) {
        var ident = '${e.name}${_pascal(v)}';
        if (_pascal(v).isEmpty || ident == e.name) {
          ident = '${e.name}Value$idx';
        }
        consts.add(_EnumConst(_alloc(ident), v));
        idx++;
      }
      _enumConsts[e.name] = consts;
    }
    // 4. Per-root model-version constants.
    for (final n in sortedClasses) {
      if (roots.contains(n)) {
        _modelVersionConst[n] = _alloc('${n}ModelVersion');
      }
    }
    // 5. Constructor functions — `New<Type>` for every model class then every
    //    form class, deduped against all identifiers reserved above.
    for (final n in sortedClasses) {
      _ctorName[n] = _alloc('New$n');
    }
    for (final fn in _formNameFor.values.toList()..sort()) {
      _ctorName[fn] = _alloc('New$fn');
    }
  }

  // --- reachability -------------------------------------------------------

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

  /// The distinct enum types referenced by reachable classes, with their values.
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

  // --- emit ---------------------------------------------------------------

  String _emitEnum(_EnumType e) {
    final consts = _enumConsts[e.name] ?? const <_EnumConst>[];
    final parse = _parseName[e.name] ?? 'parse${e.name}';
    final b = StringBuffer()
      ..writeln('// Generated enum constants for `${e.name}` values. The stored '
          'token is byte-')
      ..writeln('// identical across every language port, so documents stay '
          'cross-compatible.');
    if (consts.isNotEmpty) {
      // gofmt column-aligns the `=` of a const group — pad to the widest name
      // so the emitted block is gofmt-stable.
      final width =
          consts.map((c) => c.ident.length).reduce((a, b) => a > b ? a : b);
      b.writeln('const (');
      for (final c in consts) {
        b.writeln('\t${c.ident.padRight(width)} = "${_goStr(c.token)}"');
      }
      b.writeln(')');
      b.writeln();
    }
    b
      ..writeln('// $parse returns token when it is a known ${e.name} '
          'value, else "".')
      ..writeln('func $parse(token string) string {');
    if (consts.isEmpty) {
      b.writeln('\treturn ""');
    } else {
      b.writeln('\tswitch token {');
      b.writeln('\tcase ${consts.map((c) => c.ident).join(', ')}:');
      b.writeln('\t\treturn token');
      b.writeln('\t}');
      b.writeln('\treturn ""');
    }
    b.writeln('}');
    return b.toString();
  }

  String _emitClass(
    SpecClass cls, {
    required bool isRoot,
    required void Function(_FormClass) collectForm,
  }) {
    final b = StringBuffer();
    _writeDoc(b, cls.doc, '');
    b
      ..writeln('type ${cls.name} struct {')
      ..writeln('\tsom.SomNode')
      ..writeln('}')
      ..writeln();

    final ctor = _ctorName[cls.name] ?? 'New${cls.name}';
    if (isRoot) {
      final root = model.roots.firstWhere((r) => r.type == cls.name);
      final seg = _ref.rootSegment(root);
      final mvConst = _modelVersionConst[cls.name] ?? '${cls.name}ModelVersion';
      b
        ..writeln('// $mvConst is the model version this object '
            'model was generated')
        ..writeln('// against (SOM §4.2).')
        ..writeln('const $mvConst = "$modelVersionString"')
        ..writeln()
        ..writeln('// $ctor creates the typed facade at the document '
            'root and verifies the')
        ..writeln("// document's authoring documentVersion is editable (SOM §4.2). "
            'A non-editable')
        ..writeln('// stamp yields a *som.SomVersionError.')
        ..writeln('func $ctor(doc *som.SpecDocument, documentVersion '
            'string) (*${cls.name}, error) {')
        ..writeln('\tif err := som.CheckSomModelVersion($mvConst,'
            ' documentVersion); err != nil {')
        ..writeln('\t\treturn nil, err')
        ..writeln('\t}')
        ..writeln('\treturn &${cls.name}{SomNode: som.NewSomNode(doc, '
            '"${_goStr(seg)}")}, nil')
        ..writeln('}')
        ..writeln()
        ..writeln("// ObjectModelVersion returns this object model's own model "
            'version (major.minor),')
        ..writeln('// per SOM §4.2.')
        ..writeln('func (x *${cls.name}) ObjectModelVersion() string {')
        ..writeln('\treturn $mvConst')
        ..writeln('}')
        ..writeln()
        ..writeln('// EditabilityFor classifies whether a document authored '
            'under documentVersion')
        ..writeln('// is editable by this object model, without returning an '
            'error (SOM §21) — the')
        ..writeln("// non-error-returning companion to $ctor's SOM §4.2 check, so a "
            'read-only viewer')
        ..writeln('// can branch instead of handling the constructor error.')
        ..writeln('func (x *${cls.name}) EditabilityFor(documentVersion '
            'string) som.SomEditability {')
        ..writeln('\treturn som.SomEditabilityFor($mvConst, documentVersion)')
        ..writeln('}')
        ..writeln()
        ..writeln('// LoadYaml${cls.name} loads a `*.docspecs.yaml` document in '
            'one call: decode the')
        ..writeln('// YAML, populate the sparse stores, and construct the typed '
            'root at the document')
        ..writeln("// root with the document's retained authoring stamp — one "
            'call for the former')
        ..writeln('// decode → loadJson → thread-documentVersion sequence '
            '(SOM §21). Returns a')
        ..writeln('// *som.SomVersionError when the stamp is not editable '
            '(SOM §4.2). Decoding runs')
        ..writeln('// against the generated ${cls.name}MetaTree, so v2 '
            'hierarchical documents')
        ..writeln('// resolve their section paths through the metadata tree '
            '(SOM §8).')
        ..writeln('func LoadYaml${cls.name}(yaml string) (*${cls.name}, error) '
            '{')
        ..writeln('\tdoc, err := som.FromYaml(yaml, ${cls.name}MetaTree)')
        ..writeln('\tif err != nil {')
        ..writeln('\t\treturn nil, err')
        ..writeln('\t}')
        ..writeln('\treturn $ctor(doc, doc.ModelVersion)')
        ..writeln('}')
        ..writeln()
        ..writeln('// LoadFile${cls.name} loads a `*.docspecs.yaml` document '
            'from the file at path —')
        ..writeln('// the file companion to LoadYaml${cls.name}. A read or '
            'decode error is returned')
        ..writeln('// to the caller.')
        ..writeln('func LoadFile${cls.name}(path string) (*${cls.name}, error) '
            '{')
        ..writeln('\tdoc, err := som.FromFile(path, ${cls.name}MetaTree)')
        ..writeln('\tif err != nil {')
        ..writeln('\t\treturn nil, err')
        ..writeln('\t}')
        ..writeln('\treturn $ctor(doc, doc.ModelVersion)')
        ..writeln('}');
    } else {
      b
        ..writeln('// $ctor binds a ${cls.name} facade to a document '
            'and a path.')
        ..writeln('func $ctor(doc *som.SpecDocument, path string) '
            '*${cls.name} {')
        ..writeln('\treturn &${cls.name}{SomNode: som.NewSomNode(doc, path)}')
        ..writeln('}');
    }

    // SOM §21: a content-bearing section shadows the promoted
    // `som.SomNode.CanHaveContent` structural default (`false`) with a per-type
    // method returning `true`, so "can this section hold body text?" is
    // answerable at the type level without probing Content(). This is the Go
    // analogue of the Dart/TypeScript `canHaveContent` override — an embedding
    // struct's method of the same name shadows the promoted base method.
    if (_hasContentLeaf(cls)) {
      b
        ..writeln()
        ..writeln('// CanHaveContent reports that this section type declares the '
            'standard `content`')
        ..writeln('// text leaf (SOM §21) — it shadows the embedded '
            'som.SomNode false default.')
        ..writeln('func (x *${cls.name}) CanHaveContent() bool {')
        ..writeln('\treturn true')
        ..writeln('}');
    }

    // Per-class accessor-name allocation: Pascal-cased names can collide where
    // the original camelCase ones do not, so dedupe within the struct.
    final usedAcc = <String>{};
    for (final f in cls.fields) {
      b.writeln();
      _writeField(b, cls, f, usedAcc, collectForm);
    }
    return b.toString();
  }

  /// Whether [cls] declares the standard `content` text leaf — the structural
  /// signal that its generated facade carries a Content() accessor (SOM §21).
  bool _hasContentLeaf(SpecClass cls) => cls.fields
      .any((f) => f.name == 'content' && f.kind == SpecFieldKind.content);

  void _writeField(
    StringBuffer b,
    SpecClass cls,
    SpecField f,
    Set<String> usedAcc,
    void Function(_FormClass) collectForm,
  ) {
    final seg = _ref.fieldSegment(f);
    // gofmt's spacing heuristic is context-sensitive: the concat keeps spaces
    // around `+` as a lone call argument, but is tightened when it sits among
    // multiple arguments. Emit both forms so the output is gofmt-stable.
    final childPath = 'x.Path() + "/${_goStr(seg)}"';
    final childPathTight = 'x.Path()+"/${_goStr(seg)}"';
    final acc = _allocAccessor(usedAcc, f.name);
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
        _emitStringProperty(b, cls.name, acc, childPath, childPathTight, f.doc);
        break;
      case SpecFieldKind.enumValue:
        if (f.enumType == null) {
          _emitStringProperty(
              b, cls.name, acc, childPath, childPathTight, f.doc);
        } else {
          final et = f.enumType!;
          final parse = _parseName[et] ?? 'parse$et';
          _writeComment(b, f.doc, '');
          b
            ..writeln('func (x *${cls.name}) $acc() string {')
            ..writeln('\treturn $parse(x.Doc().ContentOr($childPath))')
            ..writeln('}')
            ..writeln()
            ..writeln('func (x *${cls.name}) Set$acc(value string) {')
            ..writeln('\tx.Doc().SetContent($childPathTight, value)')
            ..writeln('}');
        }
        break;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = f.type;
        _writeComment(b, f.doc, '');
        if (target == null) {
          b.writeln('// (skipped: ${f.name} has no target type)');
        } else {
          final targetCtor = _ctorName[target] ?? 'New$target';
          b
            ..writeln('func (x *${cls.name}) $acc() *$target {')
            ..writeln('\treturn $targetCtor(x.Doc(), $childPathTight)')
            ..writeln('}');
        }
        break;
      case SpecFieldKind.list:
        _writeComment(b, f.doc, '');
        final pat = '"${_goStr(f.sectionIdPattern ?? '')}"';
        if (f.elementIsComplex && f.elementType != null) {
          final et = f.elementType!;
          final etCtor = _ctorName[et] ?? 'New$et';
          b
            ..writeln('func (x *${cls.name}) $acc() *som.SomList[*$et] {')
            ..writeln('\treturn som.NewSomList(x.Doc(), $childPathTight, '
                'func(d *som.SpecDocument, p string) *$et {')
            ..writeln('\t\treturn $etCtor(d, p)')
            ..writeln('\t}, $pat)')
            ..writeln('}');
        } else {
          b
            ..writeln('func (x *${cls.name}) $acc() *som.SomList[*som.SomScalar] '
                '{')
            ..writeln('\treturn som.NewSomList(x.Doc(), $childPathTight, '
                'func(d *som.SpecDocument, p string) *som.SomScalar {')
            ..writeln('\t\treturn som.NewSomScalar(d, p)')
            ..writeln('\t}, $pat)')
            ..writeln('}');
        }
        break;
      case SpecFieldKind.form:
        final formName = _formNameFor['${cls.name}::${f.name}'] ??
            '${cls.name}${_pascal(f.name)}Form';
        final formCtor = _ctorName[formName] ?? 'New$formName';
        collectForm(_FormClass(formName, _emitFormClass(formName, f)));
        _writeComment(b, f.doc, '');
        b
          ..writeln('func (x *${cls.name}) $acc() *$formName {')
          ..writeln('\treturn $formCtor(x.Doc(), $childPathTight)')
          ..writeln('}');
        break;
    }
  }

  void _emitStringProperty(StringBuffer b, String owner, String name,
      String childPath, String childPathTight, String? doc) {
    _writeComment(b, doc, '');
    b
      ..writeln('func (x *$owner) $name() string {')
      ..writeln('\treturn x.Doc().ContentOr($childPath)')
      ..writeln('}')
      ..writeln()
      ..writeln('func (x *$owner) Set$name(value string) {')
      ..writeln('\tx.Doc().SetContent($childPathTight, value)')
      ..writeln('}');
  }

  /// Emits the typed **section class** for a `@Form` field (YRB2): the section's
  /// own `content` text FIRST, then one correctly-typed member per `@Form`
  /// `Field(name, Type, …)` entry, in declaration order. A member's declared
  /// scalar type (`int` → `*int`, `double`/`num` → `*float64`, `bool` →
  /// `*bool`) becomes its parsed Go return type; any non-primitive (enums,
  /// `List`, …) falls back to `string`. Members read/write through the generic
  /// form store, so the on-disk markdown format and the conformance golden stay
  /// byte-identical.
  String _emitFormClass(String name, SpecField f) {
    final ctor = _ctorName[name] ?? 'New$name';
    final hasContentMember = f.formFields.any((ff) => ff.name == 'content');
    final b = StringBuffer()
      ..writeln('// $name is the generated section facade for the `${f.name}` '
          '@Form section: its own')
      ..writeln('// content text followed by one typed member per form field.')
      ..writeln('type $name struct {')
      ..writeln('\tsom.SomNode')
      ..writeln('}')
      ..writeln()
      ..writeln('// $ctor binds a $name facade to a document and a path.')
      ..writeln('func $ctor(doc *som.SpecDocument, path string) *$name {')
      ..writeln('\treturn &$name{SomNode: som.NewSomNode(doc, path)}')
      ..writeln('}')
      ..writeln()
      ..writeln('// CanHaveContent reports that this @Form section holds body '
          'text before its')
      ..writeln('// form fields (SOM §21) — it shadows the embedded '
          'som.SomNode false default.')
      ..writeln('func (x *$name) CanHaveContent() bool {')
      ..writeln('\treturn true')
      ..writeln('}');
    final usedAcc = <String>{};
    if (!hasContentMember) {
      usedAcc..add('Content')..add('SetContent');
      b
        ..writeln()
        ..writeln("// Content is the section's own free-text content, before "
            'the form fields.')
        ..writeln('func (x *$name) Content() string {')
        ..writeln('\treturn x.Doc().ContentOr(x.Path())')
        ..writeln('}')
        ..writeln()
        ..writeln('func (x *$name) SetContent(value string) {')
        ..writeln('\tx.Doc().SetContent(x.Path(), value)')
        ..writeln('}');
    }
    for (final ff in f.formFields) {
      _writeFormMember(b, name, usedAcc, ff);
    }
    return b.toString();
  }

  /// Emits a single typed `@Form` member accessor pair backed by the generic
  /// form store, so the on-disk format and the generic reading are unchanged;
  /// only the Go return type mirrors the declared form-field type.
  void _writeFormMember(
      StringBuffer b, String name, Set<String> usedAcc, FormFieldSpec ff) {
    final field = '"${_goStr(ff.name)}"';
    final acc = _allocAccessor(usedAcc, ff.name);
    b.writeln();
    switch (_scalarType(ff.type)) {
      case 'int':
        b
          ..writeln('func (x *$name) $acc() *int {')
          ..writeln('\tv := x.Doc().FormFieldOr(x.Path(), $field)')
          ..writeln('\tif v == "" {')
          ..writeln('\t\treturn nil')
          ..writeln('\t}')
          ..writeln('\tn, err := strconv.Atoi(v)')
          ..writeln('\tif err != nil {')
          ..writeln('\t\treturn nil')
          ..writeln('\t}')
          ..writeln('\treturn &n')
          ..writeln('}')
          ..writeln()
          ..writeln('func (x *$name) Set$acc(value *int) {')
          ..writeln('\tif value == nil {')
          ..writeln('\t\tx.Doc().SetFormField(x.Path(), $field, "")')
          ..writeln('\t\treturn')
          ..writeln('\t}')
          ..writeln('\tx.Doc().SetFormField(x.Path(), $field, '
              'strconv.Itoa(*value))')
          ..writeln('}');
      case 'double':
      case 'num':
        b
          ..writeln('func (x *$name) $acc() *float64 {')
          ..writeln('\tv := x.Doc().FormFieldOr(x.Path(), $field)')
          ..writeln('\tif v == "" {')
          ..writeln('\t\treturn nil')
          ..writeln('\t}')
          ..writeln('\tf, err := strconv.ParseFloat(v, 64)')
          ..writeln('\tif err != nil {')
          ..writeln('\t\treturn nil')
          ..writeln('\t}')
          ..writeln('\treturn &f')
          ..writeln('}')
          ..writeln()
          ..writeln('func (x *$name) Set$acc(value *float64) {')
          ..writeln('\tif value == nil {')
          ..writeln('\t\tx.Doc().SetFormField(x.Path(), $field, "")')
          ..writeln('\t\treturn')
          ..writeln('\t}')
          ..writeln('\tx.Doc().SetFormField(x.Path(), $field, '
              "strconv.FormatFloat(*value, 'g', -1, 64))")
          ..writeln('}');
      case 'bool':
        b
          ..writeln('func (x *$name) $acc() *bool {')
          ..writeln('\tv := x.Doc().FormFieldOr(x.Path(), $field)')
          ..writeln('\tif v == "" {')
          ..writeln('\t\treturn nil')
          ..writeln('\t}')
          ..writeln('\tresult := v == "true"')
          ..writeln('\treturn &result')
          ..writeln('}')
          ..writeln()
          ..writeln('func (x *$name) Set$acc(value *bool) {')
          ..writeln('\tif value == nil {')
          ..writeln('\t\tx.Doc().SetFormField(x.Path(), $field, "")')
          ..writeln('\t\treturn')
          ..writeln('\t}')
          ..writeln('\tif *value {')
          ..writeln('\t\tx.Doc().SetFormField(x.Path(), $field, "true")')
          ..writeln('\t} else {')
          ..writeln('\t\tx.Doc().SetFormField(x.Path(), $field, "false")')
          ..writeln('\t}')
          ..writeln('}');
      default:
        b
          ..writeln('func (x *$name) $acc() string {')
          ..writeln('\treturn x.Doc().FormFieldOr(x.Path(), $field)')
          ..writeln('}')
          ..writeln()
          ..writeln('func (x *$name) Set$acc(value string) {')
          ..writeln('\tx.Doc().SetFormField(x.Path(), $field, value)')
          ..writeln('}');
    }
  }

  /// Whether any reachable class declares a `@Form` field with at least one
  /// non-String scalar member — the signal that the module must import
  /// `strconv` to parse typed member text.
  bool _hasTypedFormMember(Iterable<String> classNames) {
    for (final n in classNames) {
      final cls = model.classNamed(n);
      if (cls == null) continue;
      for (final f in cls.fields) {
        if (f.kind != SpecFieldKind.form) continue;
        for (final ff in f.formFields) {
          if (_scalarType(ff.type) != 'String') return true;
        }
      }
    }
    return false;
  }

  /// Maps a `@Form` field's declared type name to the primitive scalar kind the
  /// facade should expose, or `'String'` for any non-primitive (enums, `List`,
  /// unresolved types) so the generated code always round-trips as text.
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

  /// Emits a doc block as `//` line comments at [indent].
  void _writeDoc(StringBuffer b, String? doc, String indent) {
    if (doc == null || doc.trim().isEmpty) return;
    // Consecutive blank lines collapse to one — gofmt folds repeated empty
    // `//` comment lines, so emitting them would not be gofmt-stable.
    var lastEmpty = false;
    for (final line in doc.trimRight().split('\n')) {
      final text = line.trimRight();
      if (text.isEmpty && lastEmpty) continue;
      lastEmpty = text.isEmpty;
      b.writeln(text.isEmpty ? '$indent//' : '$indent// $text');
    }
  }

  /// Emits a field's doc as `//` comment lines above its accessor.
  void _writeComment(StringBuffer b, String? doc, String indent) =>
      _writeDoc(b, doc, indent);

  /// Escapes a value for a double-quoted Go string literal.
  String _goStr(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  /// The promoted members of the embedded `som.SomNode` — see
  /// [somStructuralAccessorNames]. Go embeds rather than inherits, so a
  /// generated method of the same name shadows the promoted one **silently**.
  static final Set<String> _structural =
      somReservedAccessorNames(SomLanguage.go);

  /// Allocates a unique exported accessor base name for [name] within [used].
  ///
  /// The base is the Pascal-cased field name. The structural accessors of the
  /// embedded `som.SomNode` are reserved and gain a trailing underscore; the
  /// set is not maintained here but in [somStructuralAccessorNames], so adding
  /// a structural accessor to the runtime reaches all nine emitters at once.
  /// Both the getter base and its `Set<base>` setter form are reserved so the
  /// getter and setter never collide across fields.
  String _allocAccessor(Set<String> used, String name) {
    var base = _pascal(name);
    if (base.isEmpty) base = 'Field';
    if (_structural.contains(base)) base = '${base}_';
    var cand = base;
    var n = 2;
    while (used.contains(cand) || used.contains('Set$cand')) {
      cand = '$base$n';
      n++;
    }
    used.add(cand);
    used.add('Set$cand');
    return cand;
  }

  String _pascal(String s) {
    final parts = s.split(RegExp(r'[_\s]+')).where((p) => p.isNotEmpty);
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
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

class _FormClass {
  final String name;
  final String source;
  _FormClass(this.name, this.source);
}
