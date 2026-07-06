/// Emits the generated Rust typed object model (`tom_som_rust_v0`) from a
/// resolved [SpecModel].
///
/// The generated structs are an **editing facade** over the generic
/// `tom_som_rust_runtime` `SpecDocument`: every typed accessor delegates to the
/// path-keyed memory representation, so a typed mutation is visible through the
/// generic path and vice-versa (spec §3). Each document-root struct performs the
/// **instantiation-time version check** (`som::check_som_model_version`) against
/// the document's authoring stamp (§2.2) and exposes its own generated model
/// version (§2.1).
///
/// This is the Rust counterpart of [SomDartEmitter] / `SomPythonEmitter` /
/// `SomJavaEmitter` / `SomJavaScriptEmitter` / `SomTypeScriptEmitter` /
/// `SomGoEmitter` — the same reachability walk, the same deterministic ordering,
/// the same field-kind mapping. Rust has ownership, `Result`, and reserved
/// keywords, so the surface is idiomatic:
///
///   * each model class becomes a `struct` holding a `som::SomNode`, with an
///     `impl` block of **snake-cased method accessors** (`vision()` /
///     `set_vision(&str)`);
///   * the bound document/path are reached through the held node's `doc()` /
///     `path()` methods — a generated accessor named `doc` or `path` cannot
///     shadow them (it is a method on a different value), so **no name guard is
///     needed** (unlike the Go/TypeScript ports);
///   * Rust **keyword collisions** (`type`, `match`, `move`, `ref`, `self`, …)
///     are resolved with a trailing underscore (`type_`, `match_`, …);
///   * enums become module-level `&str` constants + a `parse_<enum>` helper (the
///     stored token stays byte-identical across languages);
///   * the version check returns `Result<_, som::SomVersionError>`, so root
///     constructors return `Result<Self, som::SomVersionError>`.
///
/// The generated crate depends on the runtime through a **fixed crate name**
/// (`tom_som_rust_runtime`); the generator wires resolution by writing a
/// `Cargo.toml` with a relative `path` dependency, so the emitted source carries
/// no on-disk path and stays layout-independent / golden-stable.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// Generates the `tom_som_rust_v0` crate-root source for a [SpecModel].
class SomRustEmitter {
  final SpecModel model;
  final SpecReflection _ref;

  /// The version label of the generated project (`v0`, `v1`, …); names the
  /// `tom_som_<slug>_<label>` output project. It no longer drives the reported
  /// model version — see [modelVersionString].
  final String versionLabel;

  /// The document-root type names to generate. Empty ⇒ every root in the model.
  final List<String> documentRoots;

  SomRustEmitter(
    this.model, {
    this.versionLabel = 'v0',
    this.documentRoots = const [],
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

  /// Reserved Rust keywords (strict + reserved-for-future). A snake-cased
  /// accessor matching one of these gains a trailing underscore so it stays a
  /// legal identifier. (`self`/`crate`/`super`/`Self` cannot even be raw
  /// identifiers, so the underscore is the only portable escape.)
  static const Set<String> _rustKeywords = {
    'as', 'break', 'const', 'continue', 'crate', 'dyn', 'else', 'enum',
    'extern', 'false', 'fn', 'for', 'if', 'impl', 'in', 'let', 'loop', 'match',
    'mod', 'move', 'mut', 'pub', 'ref', 'return', 'self', 'Self', 'static',
    'struct', 'super', 'trait', 'true', 'type', 'unsafe', 'use', 'where',
    'while', 'async', 'await', 'union', 'abstract', 'become', 'box', 'do',
    'final', 'macro', 'override', 'priv', 'typeof', 'unsized', 'virtual',
    'yield', 'try', 'gen',
  };

  /// All module-level type names (structs) — model classes plus generated form
  /// structs. Form-struct names are deduped against this set.
  final Set<String> _typeNames = {};

  /// All module-level value-namespace identifiers (enum constants + `parse_`
  /// helpers). Deduped against this set with the smallest numeric suffix.
  final Set<String> _valueNames = {};

  /// Generated form-struct name keyed by `'<className>::<fieldName>'`.
  final Map<String, String> _formNameFor = {};

  /// Generated model-version constant name keyed by root type name.
  final Map<String, String> _modelVersionConst = {};

  /// Generated enum constants keyed by enum type name (allocation order = value
  /// order), and the `parse_<enum>` helper name keyed by enum type name.
  final Map<String, List<_EnumConst>> _enumConsts = {};
  final Map<String, String> _parseName = {};

  String _allocType(String base) {
    if (_typeNames.add(base)) return base;
    var n = 2;
    while (!_typeNames.add('$base$n')) {
      n++;
    }
    return '$base$n';
  }

  String _allocValue(String base) {
    if (_valueNames.add(base)) return base;
    var n = 2;
    while (!_valueNames.add('${base}_$n')) {
      n++;
    }
    return '${base}_$n';
  }

  /// Builds the complete generated crate root as a single Rust source string.
  String generateLibrary() {
    _typeNames.clear();
    _valueNames.clear();
    _formNameFor.clear();
    _modelVersionConst.clear();
    _enumConsts.clear();
    _parseName.clear();

    final rootTypes = _selectedRoots.map((r) => r.type).toSet();
    final reachable = _reachableClasses(rootTypes);
    final enums = _reachableEnums(reachable);
    final sortedClasses = reachable.toList()..sort();

    _allocateNames(sortedClasses, enums, rootTypes);

    final buffer = StringBuffer()
      ..writeln('// GENERATED by tom_specs_clitool SomRustEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('//')
      ..writeln('// Typed object-model facade over the generic '
          '`tom_som_rust_runtime` document.')
      ..writeln('//')
      ..writeln('// This file is the crate root; the generator wires the runtime '
          'dependency through a')
      ..writeln('// relative `path` entry in `Cargo.toml`, so the emitted source '
          'carries no on-disk')
      ..writeln('// path of its own.')
      ..writeln('#![allow(dead_code)]')
      ..writeln()
      ..writeln('use tom_som_rust_runtime as som;')
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
    // Emit with idiomatic 4-space indentation. Indentation is built with tab
    // characters internally; the only tabs in the output are this indentation
    // (any tab inside a token is escaped to the two-char `\t` by [_rustStr]), so
    // folding tabs to four spaces is safe and lossless.
    return buffer.toString().replaceAll('\t', '    ');
  }

  /// Allocates every module-level identifier up front so emission can reference
  /// already-resolved, collision-free names. Order is deterministic (sorted),
  /// so the generated crate is byte-stable across runs.
  void _allocateNames(
      List<String> sortedClasses, List<_EnumType> enums, Set<String> roots) {
    // 1. Model class struct names are unique map keys — reserve verbatim.
    for (final n in sortedClasses) {
      _typeNames.add(n);
    }
    // 2. Form-struct type names (unique among themselves *and* model classes).
    for (final n in sortedClasses) {
      final cls = model.classNamed(n);
      if (cls == null) continue;
      for (final f in cls.fields) {
        if (f.kind == SpecFieldKind.form) {
          _formNameFor['$n::${f.name}'] =
              _allocType('$n${_pascal(f.name)}Form');
        }
      }
    }
    // 3. Enum `parse_` helpers and value constants (value namespace).
    for (final e in enums) {
      _parseName[e.name] = _allocValue('parse_${_snake(e.name)}');
      final consts = <_EnumConst>[];
      final prefix = _screamingSnake(e.name);
      var idx = 0;
      for (final v in e.values) {
        final tail = _screamingSnake(v);
        var ident = tail.isEmpty ? '${prefix}_VALUE_$idx' : '${prefix}_$tail';
        consts.add(_EnumConst(_allocValue(ident), v));
        idx++;
      }
      _enumConsts[e.name] = consts;
    }
    // 4. Per-root model-version constants (value namespace).
    for (final n in sortedClasses) {
      if (roots.contains(n)) {
        _modelVersionConst[n] = _allocValue('${_screamingSnake(n)}_MODEL_VERSION');
      }
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
    final parse = _parseName[e.name] ?? 'parse_${_snake(e.name)}';
    final b = StringBuffer()
      ..writeln('/// Generated enum constants for `${e.name}` values. The stored '
          'token is byte-')
      ..writeln('/// identical across every language port, so documents stay '
          'cross-compatible.');
    for (final c in consts) {
      b.writeln('pub const ${c.ident}: &str = "${_rustStr(c.token)}";');
    }
    if (consts.isNotEmpty) b.writeln();
    b
      ..writeln('/// $parse returns token when it is a known ${e.name} '
          'value, else "".')
      ..writeln('pub fn $parse(token: &str) -> String {');
    if (consts.isEmpty) {
      b.writeln('\tString::new()');
    } else {
      b.writeln('\tmatch token {');
      b.writeln('\t\t${consts.map((c) => c.ident).join(' | ')} => '
          'token.to_string(),');
      b.writeln('\t\t_ => String::new(),');
      b.writeln('\t}');
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
    _writeDoc(b, cls.doc);
    b
      ..writeln('pub struct ${cls.name} {')
      ..writeln('\tpub node: som::SomNode,')
      ..writeln('}')
      ..writeln();

    if (isRoot) {
      final root = model.roots.firstWhere((r) => r.type == cls.name);
      final seg = _ref.rootSegment(root);
      final mvConst =
          _modelVersionConst[cls.name] ?? '${_screamingSnake(cls.name)}_MODEL_VERSION';
      b
        ..writeln('/// $mvConst is the model version this object '
            'model was generated against (§2.1).')
        ..writeln('pub const $mvConst: &str = "$modelVersionString";')
        ..writeln()
        ..writeln('impl ${cls.name} {')
        ..writeln('\t/// Creates the typed facade at the document root and '
            'verifies the')
        ..writeln("\t/// document's authoring `document_version` is editable "
            '(§2.2). A non-editable')
        ..writeln('\t/// stamp yields a `som::SomVersionError`.')
        ..writeln('\tpub fn new(doc: som::DocRef, document_version: &str) '
            '-> Result<${cls.name}, som::SomVersionError> {')
        ..writeln('\t\tsom::check_som_model_version($mvConst, '
            'document_version)?;')
        ..writeln('\t\tOk(${cls.name} { node: som::SomNode::new(doc, '
            '"${_rustStr(seg)}".to_string()) })')
        ..writeln('\t}')
        ..writeln()
        ..writeln("\t/// Returns this object model's own model version "
            '(major.minor), per §2.1.')
        ..writeln('\tpub fn object_model_version(&self) -> &\'static str {')
        ..writeln('\t\t$mvConst')
        ..writeln('\t}')
        ..writeln()
        ..writeln('\t/// Classifies whether a document authored under '
            '`document_version` is')
        ..writeln('\t/// editable by this object model **without erroring** (§ '
            'item 8) — the')
        ..writeln("\t/// non-erroring companion to the constructor's §2.2 check, "
            'so a read-only')
        ..writeln('\t/// viewer can branch instead of handling a '
            '`som::SomVersionError`.')
        ..writeln('\tpub fn editability_for(document_version: &str) '
            '-> som::SomEditability {')
        ..writeln('\t\tsom::som_editability_for($mvConst, document_version)')
        ..writeln('\t}')
        ..writeln()
        ..writeln('\t/// Loads a `*.docspecs.yaml` document and returns the '
            'typed root with the')
        ..writeln("\t/// document's authoring stamp already applied (§ item 4) "
            '— one call for')
        ..writeln('\t/// the former decode → load_json → thread-'
            '`document_version` sequence.')
        ..writeln('\tpub fn load_yaml(yaml: &str) '
            '-> Result<${cls.name}, som::SomVersionError> {')
        ..writeln('\t\tlet doc = som::SpecDocument::from_yaml(yaml);')
        ..writeln('\t\tlet version = doc.model_version.clone();')
        ..writeln('\t\t${cls.name}::new(som::doc_ref(doc), &version)')
        ..writeln('\t}')
        ..writeln()
        ..writeln('\t/// Loads a `*.docspecs.yaml` document from the file at '
            '`path` — the file')
        ..writeln('\t/// companion to [`${cls.name}::load_yaml`].')
        ..writeln('\tpub fn load_file(path: &str) '
            '-> Result<${cls.name}, som::SomVersionError> {')
        ..writeln('\t\tlet doc = som::SpecDocument::from_file(path);')
        ..writeln('\t\tlet version = doc.model_version.clone();')
        ..writeln('\t\t${cls.name}::new(som::doc_ref(doc), &version)')
        ..writeln('\t}');
    } else {
      b
        ..writeln('impl ${cls.name} {')
        ..writeln('\t/// Binds a ${cls.name} facade to a document and a path.')
        ..writeln('\tpub fn new(doc: som::DocRef, path: String) '
            '-> ${cls.name} {')
        ..writeln('\t\t${cls.name} { node: som::SomNode::new(doc, path) }')
        ..writeln('\t}');
    }

    final usedAcc = <String>{};
    for (final f in cls.fields) {
      b.writeln();
      _writeField(b, cls.name, f, usedAcc, collectForm);
    }
    b.writeln('}');
    return b.toString();
  }

  void _writeField(
    StringBuffer b,
    String owner,
    SpecField f,
    Set<String> usedAcc,
    void Function(_FormClass) collectForm,
  ) {
    final seg = _ref.fieldSegment(f);
    final acc = _allocAccessor(usedAcc, f.name);
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
        _emitStringProperty(b, acc, seg, f.doc);
        break;
      case SpecFieldKind.enumValue:
        if (f.enumType == null) {
          _emitStringProperty(b, acc, seg, f.doc);
        } else {
          final parse = _parseName[f.enumType!] ?? 'parse_${_snake(f.enumType!)}';
          _writeComment(b, f.doc);
          b
            ..writeln('\tpub fn $acc(&self) -> String {')
            ..writeln('\t\t$parse(&self.node.doc().borrow().content_or'
                '(&${_childPath(seg)}))')
            ..writeln('\t}')
            ..writeln()
            ..writeln('\tpub fn set_$acc(&self, value: &str) {')
            ..writeln('\t\tlet path = ${_childPath(seg)};')
            ..writeln('\t\tself.node.doc().borrow_mut().set_content'
                '(&path, value);')
            ..writeln('\t}');
        }
        break;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        final target = f.type;
        if (target == null) {
          // No resolvable target type ⇒ no accessor is emitted. A `///` doc
          // comment with nothing to document is a hard error in Rust (E0584),
          // so the field's doc is rendered as a plain `//` comment instead.
          _writePlainComment(b, f.doc);
          b.writeln('\t// (skipped: ${f.name} has no target type)');
        } else {
          _writeComment(b, f.doc);
          b
            ..writeln('\tpub fn $acc(&self) -> $target {')
            ..writeln('\t\t$target::new(self.node.doc(), ${_childPath(seg)})')
            ..writeln('\t}');
        }
        break;
      case SpecFieldKind.list:
        _writeComment(b, f.doc);
        final pat = '"${_rustStr(f.sectionIdPattern ?? '')}".to_string()';
        if (f.elementIsComplex && f.elementType != null) {
          final et = f.elementType!;
          b
            ..writeln('\tpub fn $acc(&self) -> som::SomList<$et> {')
            ..writeln('\t\tsom::SomList::new(')
            ..writeln('\t\t\tself.node.doc(),')
            ..writeln('\t\t\t${_childPath(seg)},')
            ..writeln('\t\t\tBox::new(|d, p| $et::new(d, p)),')
            ..writeln('\t\t\t$pat,')
            ..writeln('\t\t)')
            ..writeln('\t}');
        } else {
          b
            ..writeln('\tpub fn $acc(&self) -> som::SomList<som::SomScalar> {')
            ..writeln('\t\tsom::SomList::new(')
            ..writeln('\t\t\tself.node.doc(),')
            ..writeln('\t\t\t${_childPath(seg)},')
            ..writeln('\t\t\tBox::new(|d, p| som::SomScalar::new(d, p)),')
            ..writeln('\t\t\t$pat,')
            ..writeln('\t\t)')
            ..writeln('\t}');
        }
        break;
      case SpecFieldKind.form:
        final formName = _formNameFor['$owner::${f.name}'] ??
            '$owner${_pascal(f.name)}Form';
        collectForm(_FormClass(formName, _emitFormClass(formName, f)));
        _writeComment(b, f.doc);
        b
          ..writeln('\tpub fn $acc(&self) -> $formName {')
          ..writeln('\t\t$formName::new(self.node.doc(), ${_childPath(seg)})')
          ..writeln('\t}');
        break;
    }
  }

  void _emitStringProperty(
      StringBuffer b, String name, String seg, String? doc) {
    _writeComment(b, doc);
    b
      ..writeln('\tpub fn $name(&self) -> String {')
      ..writeln('\t\tself.node.doc().borrow().content_or(&${_childPath(seg)})')
      ..writeln('\t}')
      ..writeln()
      ..writeln('\tpub fn set_$name(&self, value: &str) {')
      ..writeln('\t\tlet path = ${_childPath(seg)};')
      ..writeln('\t\tself.node.doc().borrow_mut().set_content(&path, value);')
      ..writeln('\t}');
  }

  String _emitFormClass(String name, SpecField f) {
    final b = StringBuffer()
      ..writeln('/// $name is the generated form facade for the `${f.name}` '
          '@Form section.')
      ..writeln('pub struct $name {')
      ..writeln('\tpub node: som::SomNode,')
      ..writeln('}')
      ..writeln()
      ..writeln('impl $name {')
      ..writeln('\t/// Binds a $name facade to a document and a path.')
      ..writeln('\tpub fn new(doc: som::DocRef, path: String) -> $name {')
      ..writeln('\t\t$name { node: som::SomNode::new(doc, path) }')
      ..writeln('\t}');
    final usedAcc = <String>{};
    for (final ff in f.formFields) {
      final field = '"${_rustStr(ff.name)}"';
      final acc = _allocAccessor(usedAcc, ff.name);
      b
        ..writeln()
        ..writeln('\tpub fn $acc(&self) -> String {')
        ..writeln('\t\tself.node.doc().borrow().form_field_or'
            '(self.node.path(), $field)')
        ..writeln('\t}')
        ..writeln()
        ..writeln('\tpub fn set_$acc(&self, value: &str) {')
        ..writeln('\t\tlet path = self.node.path().to_string();')
        ..writeln('\t\tself.node.doc().borrow_mut().set_form_field'
            '(&path, $field, value);')
        ..writeln('\t}');
    }
    b.writeln('}');
    return b.toString();
  }

  /// The child-path expression for a section segment: a `format!` with the
  /// segment passed as an argument (not interpolated into the template), so
  /// `{`/`}` in a segment can never break the format string.
  String _childPath(String seg) =>
      'format!("{}/{}", self.node.path(), "${_rustStr(seg)}")';

  /// Emits a doc block as `///` line comments at module/item level.
  void _writeDoc(StringBuffer b, String? doc) {
    if (doc == null || doc.trim().isEmpty) return;
    for (final line in doc.trimRight().split('\n')) {
      final text = line.trimRight();
      b.writeln(text.isEmpty ? '///' : '/// $text');
    }
  }

  /// Emits a field's doc as `///` comment lines (indented one tab) above its
  /// accessor.
  void _writeComment(StringBuffer b, String? doc) {
    if (doc == null || doc.trim().isEmpty) return;
    for (final line in doc.trimRight().split('\n')) {
      final text = line.trimRight();
      b.writeln(text.isEmpty ? '\t///' : '\t/// $text');
    }
  }

  /// Emits a field's doc as plain `//` comment lines (indented one tab). Used
  /// where no documentable item follows (a `///` doc comment with nothing to
  /// document is rejected by `rustc`, E0584).
  void _writePlainComment(StringBuffer b, String? doc) {
    if (doc == null || doc.trim().isEmpty) return;
    for (final line in doc.trimRight().split('\n')) {
      final text = line.trimRight();
      b.writeln(text.isEmpty ? '\t//' : '\t// $text');
    }
  }

  /// Escapes a value for a double-quoted Rust string literal.
  String _rustStr(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  /// Allocates a unique snake-cased accessor base name for [name] within
  /// [used]. Rust keywords gain a trailing underscore; both the getter base and
  /// its `set_<base>` setter form are reserved so they never collide across
  /// fields.
  String _allocAccessor(Set<String> used, String name) {
    var base = _snake(name);
    if (base.isEmpty) base = 'field';
    if (_rustKeywords.contains(base)) base = '${base}_';
    var cand = base;
    var n = 2;
    while (used.contains(cand) || used.contains('set_$cand')) {
      cand = '${base}_$n';
      n++;
    }
    used.add(cand);
    used.add('set_$cand');
    return cand;
  }

  String _pascal(String s) {
    final parts = s.split(RegExp(r'[_\s]+')).where((p) => p.isNotEmpty);
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  /// snake_cases an identifier: splits camelCase/PascalCase boundaries and
  /// separators, lowercases, collapses runs of `_`.
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

class _FormClass {
  final String name;
  final String source;
  _FormClass(this.name, this.source);
}
