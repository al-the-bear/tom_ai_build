/// Emits the generated Go typed object model (`tom_som_go_v0`) from a resolved
/// [SpecModel].
///
/// The generated structs are an **editing facade** over the generic
/// `tom_som_go_runtime` `SpecDocument`: every typed accessor delegates to the
/// path-keyed memory representation, so a typed mutation is visible through the
/// generic path and vice-versa (spec §3). Each document-root struct performs the
/// **instantiation-time version check** (`som.CheckSomModelVersion`) against the
/// document's authoring stamp (§2.2) and exposes its own generated model version
/// (§2.1).
///
/// This is the Go counterpart of [SomDartEmitter] / `SomPythonEmitter` /
/// `SomJavaEmitter` / `SomJavaScriptEmitter` / `SomTypeScriptEmitter` — the same
/// reachability walk, the same deterministic ordering, the same field-kind
/// mapping. Go has no classes, exceptions, or enums, so the surface is idiomatic:
///
///   * each model class becomes a `struct` embedding `som.SomNode`, with
///     **exported (Pascal-cased) method accessors** (`Vision()` /
///     `SetVision(string)`);
///   * the bound document/path are reached through the embedded node's exported
///     `Doc()` / `Path()` methods — so a model field that Pascal-cases to `Doc`
///     or `Path` would *shadow* those promoted methods and self-recurse, and is
///     therefore reserved (the Go analogue of the TS `doc`/`path` guard);
///   * enums become exported string constants + an unexported `parse<Enum>`
///     helper (the stored token stays byte-identical across languages);
///   * the version check returns `*som.SomVersionError`, so root constructors
///     return `(*T, error)`.
///
/// The generated module imports the runtime through a **fixed import path**
/// (`tom_som_go_runtime`); the generator wires resolution by writing a `go.mod`
/// with a `require` + relative `replace` directive, so the emitted source carries
/// no on-disk path and stays layout-independent / golden-stable.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Generates the `tom_som_go_v0` module source for a [SpecModel].
class SomGoEmitter {
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

  /// The model version the generated object model reports (§2.1), `major.minor`,
  /// taken from the model's own version stamp (the `tom_specs_model` project
  /// version), not the project [versionLabel] — which only names the `_vN`
  /// output project.
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

    _allocatePackageNames(sortedClasses, enums, rootTypes);

    final buffer = StringBuffer()
      ..writeln('// GENERATED by tom_specs_clitool SomGoEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('//')
      ..writeln('// Typed object-model facade over the generic '
          '`tom_som_go_runtime` document.')
      ..writeln('//')
      ..writeln('// The generic runtime is imported through a fixed import '
          'path; the generator wires')
      ..writeln('// resolution by writing a `go.mod` with a relative `replace` '
          'directive, so this')
      ..writeln('// module carries no on-disk path of its own.')
      ..writeln('package $packageName')
      ..writeln()
      ..writeln('import som "tom_som_go_runtime"')
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
    return buffer.toString();
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
      b.writeln('const (');
      for (final c in consts) {
        b.writeln('\t${c.ident} = "${_goStr(c.token)}"');
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
        ..writeln('// against (§2.1).')
        ..writeln('const $mvConst = "$modelVersionString"')
        ..writeln()
        ..writeln('// $ctor creates the typed facade at the document '
            'root and verifies the')
        ..writeln("// document's authoring documentVersion is editable (§2.2). "
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
        ..writeln('// per §2.1.')
        ..writeln('func (x *${cls.name}) ObjectModelVersion() string {')
        ..writeln('\treturn $mvConst')
        ..writeln('}')
        ..writeln()
        ..writeln('// EditabilityFor classifies whether a document authored '
            'under documentVersion')
        ..writeln('// is editable by this object model, without returning an '
            'error (§ item 8) — the')
        ..writeln("// non-error-returning companion to $ctor's §2.2 check, so a "
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
            '(§ item 4). Returns a')
        ..writeln('// *som.SomVersionError when the stamp is not editable '
            '(§2.2).')
        ..writeln('func LoadYaml${cls.name}(yaml string) (*${cls.name}, error) '
            '{')
        ..writeln('\tdoc := som.FromYaml(yaml)')
        ..writeln('\treturn $ctor(doc, doc.ModelVersion)')
        ..writeln('}')
        ..writeln()
        ..writeln('// LoadFile${cls.name} loads a `*.docspecs.yaml` document '
            'from the file at path —')
        ..writeln('// the file companion to LoadYaml${cls.name}. A read error '
            'is returned to the')
        ..writeln('// caller.')
        ..writeln('func LoadFile${cls.name}(path string) (*${cls.name}, error) '
            '{')
        ..writeln('\tdoc, err := som.FromFile(path)')
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

    // Per-class accessor-name allocation: Pascal-cased names can collide where
    // the original camelCase ones do not, so dedupe within the struct.
    final usedAcc = <String>{};
    for (final f in cls.fields) {
      b.writeln();
      _writeField(b, cls, f, usedAcc, collectForm);
    }
    return b.toString();
  }

  void _writeField(
    StringBuffer b,
    SpecClass cls,
    SpecField f,
    Set<String> usedAcc,
    void Function(_FormClass) collectForm,
  ) {
    final seg = _ref.fieldSegment(f);
    final childPath = 'x.Path() + "/${_goStr(seg)}"';
    final acc = _allocAccessor(usedAcc, f.name);
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
        _emitStringProperty(b, cls.name, acc, childPath, f.doc);
        break;
      case SpecFieldKind.enumValue:
        if (f.enumType == null) {
          _emitStringProperty(b, cls.name, acc, childPath, f.doc);
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
            ..writeln('\tx.Doc().SetContent($childPath, value)')
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
            ..writeln('\treturn $targetCtor(x.Doc(), $childPath)')
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
            ..writeln('\treturn som.NewSomList(x.Doc(), $childPath, '
                'func(d *som.SpecDocument, p string) *$et {')
            ..writeln('\t\treturn $etCtor(d, p)')
            ..writeln('\t}, $pat)')
            ..writeln('}');
        } else {
          b
            ..writeln('func (x *${cls.name}) $acc() *som.SomList[*som.SomScalar] '
                '{')
            ..writeln('\treturn som.NewSomList(x.Doc(), $childPath, '
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
          ..writeln('\treturn $formCtor(x.Doc(), $childPath)')
          ..writeln('}');
        break;
    }
  }

  void _emitStringProperty(
      StringBuffer b, String owner, String name, String childPath, String? doc) {
    _writeComment(b, doc, '');
    b
      ..writeln('func (x *$owner) $name() string {')
      ..writeln('\treturn x.Doc().ContentOr($childPath)')
      ..writeln('}')
      ..writeln()
      ..writeln('func (x *$owner) Set$name(value string) {')
      ..writeln('\tx.Doc().SetContent($childPath, value)')
      ..writeln('}');
  }

  String _emitFormClass(String name, SpecField f) {
    final ctor = _ctorName[name] ?? 'New$name';
    final b = StringBuffer()
      ..writeln('// $name is the generated form facade for the `${f.name}` '
          '@Form section.')
      ..writeln('type $name struct {')
      ..writeln('\tsom.SomNode')
      ..writeln('}')
      ..writeln()
      ..writeln('// $ctor binds a $name facade to a document and a path.')
      ..writeln('func $ctor(doc *som.SpecDocument, path string) *$name {')
      ..writeln('\treturn &$name{SomNode: som.NewSomNode(doc, path)}')
      ..writeln('}');
    final usedAcc = <String>{};
    for (final ff in f.formFields) {
      final field = '"${_goStr(ff.name)}"';
      final acc = _allocAccessor(usedAcc, ff.name);
      b
        ..writeln()
        ..writeln('func (x *$name) $acc() string {')
        ..writeln('\treturn x.Doc().FormFieldOr(x.Path(), $field)')
        ..writeln('}')
        ..writeln()
        ..writeln('func (x *$name) Set$acc(value string) {')
        ..writeln('\tx.Doc().SetFormField(x.Path(), $field, value)')
        ..writeln('}');
    }
    return b.toString();
  }

  /// Emits a doc block as `//` line comments at [indent].
  void _writeDoc(StringBuffer b, String? doc, String indent) {
    if (doc == null || doc.trim().isEmpty) return;
    for (final line in doc.trimRight().split('\n')) {
      final text = line.trimRight();
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

  /// Allocates a unique exported accessor base name for [name] within [used].
  ///
  /// The base is the Pascal-cased field name. `Doc` / `Path` are reserved — a
  /// generated method of either name would shadow the embedded [SomNode]'s
  /// promoted `Doc()` / `Path()` and self-recurse. `SectionID` / `SetSectionID`
  /// are likewise reserved: they are the structural section-id accessors on the
  /// embedded [SomNode] (AA-6 decision AF-D1, the Go analogue of the Dart/TS
  /// `$sectionId`), and a typed field of that name would shadow them. All gain a
  /// trailing underscore. Both the getter base and its `Set<base>` setter form
  /// are reserved so the getter and setter never collide across fields.
  String _allocAccessor(Set<String> used, String name) {
    var base = _pascal(name);
    if (base.isEmpty) base = 'Field';
    if (base == 'Doc' || base == 'Path' || base == 'SectionID') {
      base = '${base}_';
    }
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
