/// Emits the generated C++ typed object model (`tom_som_cpp_v0`) from a resolved
/// [SpecModel].
///
/// The generated classes are an **editing facade** over the generic
/// `tom_som_cpp_runtime` `som::SpecDocument`: every typed accessor delegates to
/// the path-keyed memory representation, so a typed mutation is visible through
/// the generic path and vice-versa (SOM §6). Each document-root class performs
/// the **instantiation-time version check** (`som::checkSomModelVersion`)
/// against the document's authoring stamp (SOM §4.2) and exposes its own
/// generated model version (SOM §4.2).
///
/// This is the C++ counterpart of [SomDartEmitter] / `SomJavaEmitter` /
/// `SomCEmitter` — the same reachability walk, the same deterministic ordering,
/// the same field-kind mapping. C++ has classes, methods and namespaces, so the
/// surface is idiomatic RAII classes (`class <Class> : public som::SomNode`),
/// **not** the flat accessor-function API the C port needs. Because every
/// generated type lives in the `tom_som_v0` namespace and every accessor is a
/// member function, **no global function de-duplication is required** (unlike C):
/// only generated **type names** (form classes vs. model classes vs. enums) need
/// to stay collision-free, which they are kept by allocating form-class names
/// against the set of already-used model-class and enum names.
///
/// C++ forbids using an incomplete type by value, and the generated classes
/// reference each other by value (a complex accessor returns a child facade, a
/// form accessor returns a generated form class). The artefact is therefore a
/// **header/source pair**: [generateHeader] forward-declares every class, then
/// defines each class with **method declarations only**; [generateSource]
/// defines every method out-of-line, where all referenced types are complete.
/// Both share one deterministic name allocation, so re-running over an unchanged
/// model is byte-for-byte stable.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The header include-guard macro and the generated file basenames.
const String _headerGuard = 'TOM_SOM_CPP_V0_HPP';
const String _headerBasename = 'tom_som_cpp_v0.hpp';

/// The generated metadata-module header (populated SomMetaTrees + the two access
/// surfaces). The facade's load functions thread the per-root tree from it into
/// the generic runtime decoder.
const String _metaHeaderBasename = 'tom_som_cpp_v0_meta.hpp';

/// The C++ namespace every generated type lives in.
const String _namespace = 'tom_som_v0';

/// The namespace the generated metadata module lives in (mirrors
/// `SomCppMetaEmitter._namespace`).
const String _metaNamespace = 'tom_som_v0_meta';

/// Generates the `tom_som_cpp_v0` header + source for a [SpecModel].
class SomCppEmitter {
  final SpecModel model;
  final SpecReflection _ref;

  /// The version label of the generated project (`v0`, `v1`, …).
  final String versionLabel;

  /// The document-root type names to generate. Empty ⇒ every root in the model.
  final List<String> documentRoots;

  SomCppEmitter(
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

  /// Reserved C++ keywords (C++17, plus the literals). A field name that is a
  /// keyword cannot be a member-function name, so its accessor gains a trailing
  /// underscore. The document path segment and the stored enum token are derived
  /// independently and stay byte-identical, so cross-language documents remain
  /// compatible.
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
    'static_assert', 'static_cast', 'struct', 'switch', 'template', 'this',
    'thread_local', 'throw', 'true', 'try', 'typedef', 'typeid', 'typename',
    'union', 'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t',
    'while', 'xor', 'xor_eq',
  };

  // --- generated type names (kept collision-free) --------------------------

  /// All generated type names — model classes plus enums plus form classes.
  /// Seeded with model-class + enum names so allocated form-class names never
  /// collide with a class or enum (C++'s one-definition rule is strict).
  final Set<String> _typeNames = {};

  /// Per-class emission plan, keyed by class name.
  final Map<String, _ClassPlan> _classPlans = {};

  /// Form plans in deterministic (class-name) order.
  final List<_FormPlan> _formPlans = [];

  /// Reachable enums, sorted by name.
  final List<_EnumType> _enums = [];

  String _allocTypeName(String base) {
    if (_typeNames.add(base)) return base;
    var n = 2;
    while (!_typeNames.add('$base$n')) {
      n++;
    }
    return '$base$n';
  }

  bool _prepared = false;

  /// Resolves every name once; idempotent. Both [generateHeader] and
  /// [generateSource] call it so they emit identical, collision-free names.
  void _prepare() {
    if (_prepared) return;
    _typeNames.clear();
    _classPlans.clear();
    _formPlans.clear();
    _enums.clear();

    final rootTypes = _selectedRoots.map((r) => r.type).toSet();
    final reachable = _reachableClasses(rootTypes);
    final sortedClasses = reachable.toList()..sort();

    // 1. enums (their names share the type namespace) ----------------------
    _enums.addAll(_reachableEnums(reachable));
    for (final e in _enums) {
      _typeNames.add(e.name);
    }

    // 2. model class type names (verbatim) ---------------------------------
    for (final n in sortedClasses) {
      _typeNames.add(n);
    }

    // 3. per-class plans + form-class allocation (after class names) --------
    final pendingForms = <_PendingForm>[];
    for (final n in sortedClasses) {
      final cls = model.classNamed(n);
      if (cls == null) continue;
      final isRoot = rootTypes.contains(n);
      final plan = _ClassPlan(cls, isRoot);
      if (isRoot) {
        final root = model.roots.firstWhere((r) => r.type == n);
        plan.rootSeg = _ref.rootSegment(root);
      }
      _classPlans[n] = plan;
      for (final f in cls.fields) {
        if (f.kind == SpecFieldKind.form) {
          final typeName = _allocTypeName('$n${_pascal(f.name)}Form');
          pendingForms.add(_PendingForm(n, f, typeName));
          plan.formTypeFor[f.name] = typeName;
        }
      }
    }

    // 4. form plans, in deterministic (type-name) order --------------------
    pendingForms.sort((a, b) => a.typeName.compareTo(b.typeName));
    for (final pf in pendingForms) {
      _formPlans.add(_FormPlan(pf.typeName, pf.field));
    }

    _prepared = true;
  }

  // --- header --------------------------------------------------------------

  /// Builds the generated header (`tom_som_cpp_v0.hpp`).
  String generateHeader() {
    _prepare();
    final b = StringBuffer();
    _fileBanner(b, 'header');
    b
      ..writeln('#ifndef $_headerGuard')
      ..writeln('#define $_headerGuard')
      ..writeln()
      ..writeln('#include <optional>')
      ..writeln('#include <string>')
      ..writeln()
      ..writeln('#include "tom_som_cpp_runtime.hpp"')
      ..writeln()
      ..writeln('namespace $_namespace {')
      ..writeln();

    final typeOrder = _classPlans.keys.toList()..sort();
    // (meta module header referenced only from the source translation unit; see
    // generateSource.)

    // enum structs (token constants + parse declaration)
    for (final e in _enums) {
      _declEnum(b, e);
      b.writeln();
    }

    // forward declarations (classes then form classes) so by-value member
    // declarations can reference any generated class.
    b.writeln('// Forward declarations (classes reference each other by value).');
    for (final n in typeOrder) {
      b.writeln('class $n;');
    }
    for (final fp in _formPlans) {
      b.writeln('class ${fp.typeName};');
    }
    b.writeln();

    // class definitions (method declarations only)
    for (final n in typeOrder) {
      _declClass(b, _classPlans[n]!);
      b.writeln();
    }
    for (final fp in _formPlans) {
      _declForm(b, fp);
      b.writeln();
    }

    b
      ..writeln('}  // namespace $_namespace')
      ..writeln()
      ..writeln('#endif  // $_headerGuard');
    return b.toString().replaceAll('\t', '  ');
  }

  void _declEnum(StringBuffer b, _EnumType e) {
    b
      ..writeln('// Generated enum tokens for `${e.name}` values. The stored '
          'token is byte-')
      ..writeln('// identical across every language port, so documents stay '
          'cross-compatible.')
      ..writeln('struct ${e.name} {');
    var idx = 0;
    for (final v in e.values) {
      final ident = _enumConstName(v, idx);
      b.writeln('  static constexpr const char* $ident = "${_cppStr(v)}";');
      idx++;
    }
    b
      ..writeln('  // Returns the token when it is a known ${e.name} value, '
          'else std::nullopt.')
      ..writeln('  static std::optional<std::string> parse('
          'const std::string& token);')
      ..writeln('  ${e.name}() = delete;')
      ..writeln('};');
  }

  void _declClass(StringBuffer b, _ClassPlan plan) {
    final t = plan.cls.name;
    _doc(b, plan.cls.doc, '');
    b.writeln('class $t : public som::SomNode {');
    b.writeln(' public:');
    if (plan.isRoot) {
      b
        ..writeln('  // The model version this object model was generated '
            'against (SOM §4.2).')
        ..writeln('  static constexpr const char* kModelVersion = '
            '"$modelVersionString";')
        ..writeln('  // Creates the typed facade at the document root and '
            "verifies the document's")
        ..writeln('  // authoring documentVersion is editable (SOM §4.2); throws '
            'som::SomVersionError')
        ..writeln('  // when it is not.')
        ..writeln('  explicit $t(som::SpecDocument& doc, '
            'const std::string& documentVersion = "");')
        ..writeln('  // Loads a `*.docspecs.yaml` document into the '
            'caller-owned `doc` and')
        ..writeln('  // returns the typed root with the document\'s authoring '
            'stamp already')
        ..writeln('  // applied (SOM §21) — one call for the former decode → '
            'loadJson →')
        ..writeln('  // thread-documentVersion sequence. `doc` is borrowed by '
            'the returned')
        ..writeln('  // root and must outlive it (RAII ownership model).')
        ..writeln('  static $t loadYaml(som::SpecDocument& doc, '
            'const std::string& yaml);')
        ..writeln('  // Loads a `*.docspecs.yaml` document from the file at '
            '`path` into the')
        ..writeln('  // caller-owned `doc` — the file companion to loadYaml.')
        ..writeln('  static $t loadFile(som::SpecDocument& doc, '
            'const std::string& path);')
        ..writeln("  // This object model's own model version (major.minor), "
            'per SOM §4.2.')
        ..writeln('  std::string objectModelVersion() const;')
        ..writeln("  // Classifies a document's editability against this object "
            'model without')
        ..writeln('  // throwing — the non-throwing companion to the '
            'constructor check (SOM §21):')
        ..writeln('  // a read-only viewer can branch on the result instead of '
            'catching')
        ..writeln('  // som::SomVersionError. An empty documentVersion is the '
            'absent-stamp')
        ..writeln('  // sentinel and classifies as editable.')
        ..writeln('  static som::SomEditability editabilityFor('
            'const std::string& documentVersion);');
    } else {
      b.writeln('  $t(som::SpecDocument& doc, std::string path);');
    }
    for (final f in plan.cls.fields) {
      _declField(b, plan, f);
    }

    // SOM §21: a content-bearing section overrides the virtual
    // `som::SomNode::canHaveContent` structural default (`false`) with an
    // inline `true`, so "can this section hold body text?" is answerable at the
    // type level without probing content(). Emitted inline in the header (a
    // trivial constant), matching the base's inline form.
    if (_hasContentLeaf(plan.cls)) {
      b
        ..writeln('  // This section type declares the standard `content` text '
            'leaf (SOM §21):')
        ..writeln('  // a structural, document-independent override of the '
            '`som::SomNode`')
        ..writeln('  // `canHaveContent` default (`false`).')
        ..writeln('  bool canHaveContent() const override { return true; }');
    }

    b.writeln('};');
  }

  /// Whether [cls] declares the standard `content` text leaf — the structural
  /// signal that its generated facade carries a `content()` accessor (SOM §21).
  bool _hasContentLeaf(SpecClass cls) => cls.fields
      .any((f) => f.name == 'content' && f.kind == SpecFieldKind.content);

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

  void _declField(StringBuffer b, _ClassPlan plan, SpecField f) {
    final acc = _accessor(f.name);
    final setAcc = _setter(f.name);
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
        _doc(b, f.doc, '  ');
        b.writeln('  std::string $acc() const;');
        b.writeln('  void $setAcc(const std::string& value);');
        break;
      case SpecFieldKind.enumValue:
        _doc(b, f.doc, '  ');
        if (f.enumType == null) {
          b.writeln('  std::string $acc() const;');
        } else {
          b.writeln('  std::optional<std::string> $acc() const;');
        }
        b.writeln('  void $setAcc(const std::string& value);');
        break;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        _doc(b, f.doc, '  ');
        if (f.type == null) {
          b.writeln('  // (skipped: ${f.name} has no target type)');
        } else {
          b.writeln('  ${f.type} $acc() const;');
        }
        break;
      case SpecFieldKind.list:
        _doc(b, f.doc, '  ');
        final elem = (f.elementIsComplex && f.elementType != null)
            ? f.elementType!
            : 'scalar';
        b.writeln('  // Returns the list view; element type: $elem '
            '(construct from item paths).');
        b.writeln('  som::SomList $acc() const;');
        break;
      case SpecFieldKind.form:
        final formType = plan.formTypeFor[f.name];
        _doc(b, f.doc, '  ');
        b.writeln('  $formType $acc() const;');
        break;
    }
  }

  void _declForm(StringBuffer b, _FormPlan fp) {
    final t = fp.typeName;
    final hasContentMember =
        fp.field.formFields.any((ff) => ff.name == 'content');
    b
      ..writeln('// Generated section facade for the `${fp.field.name}` '
          '@Form section: its own `content` text followed by one typed member '
          'per form field.')
      ..writeln('class $t : public som::SomNode {')
      ..writeln(' public:')
      ..writeln('  $t(som::SpecDocument& doc, std::string path);')
      ..writeln('  bool canHaveContent() const override { return true; }');
    if (!hasContentMember) {
      b
        ..writeln('  // The section\'s own free-text content, before the form '
            'fields.')
        ..writeln('  std::string content() const;')
        ..writeln('  void setContent(const std::string& value);');
    }
    for (final ff in fp.field.formFields) {
      final acc = _accessor(ff.name);
      final setAcc = _setter(ff.name);
      switch (_scalarType(ff.type)) {
        case 'int':
          b.writeln('  std::optional<long> $acc() const;');
          b.writeln('  void $setAcc(std::optional<long> value);');
        case 'double':
        case 'num':
          b.writeln('  std::optional<double> $acc() const;');
          b.writeln('  void $setAcc(std::optional<double> value);');
        case 'bool':
          b.writeln('  std::optional<bool> $acc() const;');
          b.writeln('  void $setAcc(std::optional<bool> value);');
        default:
          b.writeln('  std::string $acc() const;');
          b.writeln('  void $setAcc(const std::string& value);');
      }
    }
    b.writeln('};');
  }

  // --- source --------------------------------------------------------------

  /// Builds the generated source (`tom_som_cpp_v0.cpp`).
  String generateSource() {
    _prepare();
    final b = StringBuffer();
    _fileBanner(b, 'source');
    b
      ..writeln('#include "$_headerBasename"')
      ..writeln()
      ..writeln('#include <optional>')
      ..writeln('#include <utility>')
      ..writeln()
      // The generated metadata module: the per-root SomMetaTree accessors the
      // load functions thread into the generic runtime decoder.
      ..writeln('#include "$_metaHeaderBasename"')
      ..writeln()
      ..writeln('namespace $_namespace {')
      ..writeln();

    for (final e in _enums) {
      _defineEnum(b, e);
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

    b.writeln('}  // namespace $_namespace');
    return b.toString().replaceAll('\t', '  ');
  }

  void _defineEnum(StringBuffer b, _EnumType e) {
    b.writeln('std::optional<std::string> ${e.name}::parse('
        'const std::string& token) {');
    if (e.values.isEmpty) {
      b.writeln('  (void)token;');
      b.writeln('  return std::nullopt;');
    } else {
      var idx = 0;
      for (final v in e.values) {
        final ident = _enumConstName(v, idx);
        b.writeln('  if (token == $ident) {');
        b.writeln('    return token;');
        b.writeln('  }');
        idx++;
      }
      b.writeln('  return std::nullopt;');
    }
    b.writeln('}');
  }

  void _defineClass(StringBuffer b, _ClassPlan plan) {
    final t = plan.cls.name;
    if (plan.isRoot) {
      b
        ..writeln('$t::$t(som::SpecDocument& doc, '
            'const std::string& documentVersion)')
        ..writeln('    : som::SomNode(doc, "${_cppStr(plan.rootSeg!)}") {')
        ..writeln('  som::checkSomModelVersion(kModelVersion, '
            'documentVersion);')
        ..writeln('}')
        ..writeln('$t $t::loadYaml(som::SpecDocument& doc, '
            'const std::string& yaml) {')
        ..writeln('  std::string err;')
        ..writeln('  std::optional<som::SpecDocument> parsed =')
        ..writeln('      som::SpecDocument::fromYaml(yaml, '
            '$_metaNamespace::${_camel(plan.cls.name)}MetaTree(), &err);')
        ..writeln('  if (!parsed) {')
        ..writeln('    throw som::SomVersionError('
            'err.empty() ? "loadYaml: decode failed" : err);')
        ..writeln('  }')
        ..writeln('  doc = std::move(*parsed);')
        ..writeln('  return $t(doc, doc.modelVersion);')
        ..writeln('}')
        ..writeln('$t $t::loadFile(som::SpecDocument& doc, '
            'const std::string& path) {')
        ..writeln('  std::string err;')
        ..writeln('  std::optional<som::SpecDocument> parsed =')
        ..writeln('      som::SpecDocument::fromFile(path, '
            '$_metaNamespace::${_camel(plan.cls.name)}MetaTree(), &err);')
        ..writeln('  if (!parsed) {')
        ..writeln('    throw som::SomVersionError('
            'err.empty() ? "loadFile: decode failed" : err);')
        ..writeln('  }')
        ..writeln('  doc = std::move(*parsed);')
        ..writeln('  return $t(doc, doc.modelVersion);')
        ..writeln('}')
        ..writeln('std::string $t::objectModelVersion() const {')
        ..writeln('  return kModelVersion;')
        ..writeln('}')
        ..writeln('som::SomEditability $t::editabilityFor('
            'const std::string& documentVersion) {')
        ..writeln('  return som::somEditabilityFor(kModelVersion, '
            'documentVersion);')
        ..writeln('}');
    } else {
      b
        ..writeln('$t::$t(som::SpecDocument& doc, std::string path)')
        ..writeln('    : som::SomNode(doc, std::move(path)) {}');
    }
    for (final f in plan.cls.fields) {
      _defineField(b, plan, f);
    }
  }

  void _defineField(StringBuffer b, _ClassPlan plan, SpecField f) {
    final t = plan.cls.name;
    final acc = _accessor(f.name);
    final setAcc = _setter(f.name);
    final seg = _cppStr(_ref.fieldSegment(f));
    final childPath = 'som::joinPath(path(), "$seg")';
    switch (f.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
        _emitStringGetter(b, t, acc, childPath);
        _emitStringSetter(b, t, setAcc, childPath);
        break;
      case SpecFieldKind.enumValue:
        if (f.enumType == null) {
          _emitStringGetter(b, t, acc, childPath);
        } else {
          b
            ..writeln('std::optional<std::string> $t::$acc() const {')
            ..writeln('  return ${f.enumType}::parse(doc().content('
                '$childPath));')
            ..writeln('}');
        }
        _emitStringSetter(b, t, setAcc, childPath);
        break;
      case SpecFieldKind.complex:
      case SpecFieldKind.section:
        if (f.type == null) break;
        b
          ..writeln('${f.type} $t::$acc() const {')
          ..writeln('  return ${f.type}(doc(), $childPath);')
          ..writeln('}');
        break;
      case SpecFieldKind.list:
        final pat = _cppStr(f.sectionIdPattern ?? '');
        b
          ..writeln('som::SomList $t::$acc() const {')
          ..writeln('  return som::SomList(doc(), $childPath, "$pat");')
          ..writeln('}');
        break;
      case SpecFieldKind.form:
        final formType = plan.formTypeFor[f.name]!;
        b
          ..writeln('$formType $t::$acc() const {')
          ..writeln('  return $formType(doc(), $childPath);')
          ..writeln('}');
        break;
    }
  }

  void _emitStringGetter(
      StringBuffer b, String t, String acc, String childPath) {
    b
      ..writeln('std::string $t::$acc() const {')
      ..writeln('  return doc().content($childPath);')
      ..writeln('}');
  }

  void _emitStringSetter(
      StringBuffer b, String t, String setAcc, String childPath) {
    b
      ..writeln('void $t::$setAcc(const std::string& value) {')
      ..writeln('  doc().setContent($childPath, value);')
      ..writeln('}');
  }

  void _defineForm(StringBuffer b, _FormPlan fp) {
    final t = fp.typeName;
    final hasContentMember =
        fp.field.formFields.any((ff) => ff.name == 'content');
    b
      ..writeln('$t::$t(som::SpecDocument& doc, std::string path)')
      ..writeln('    : som::SomNode(doc, std::move(path)) {}');
    if (!hasContentMember) {
      b
        ..writeln('std::string $t::content() const {')
        ..writeln('  return doc().content(path());')
        ..writeln('}')
        ..writeln('void $t::setContent(const std::string& value) {')
        ..writeln('  doc().setContent(path(), value);')
        ..writeln('}');
    }
    for (final ff in fp.field.formFields) {
      final acc = _accessor(ff.name);
      final setAcc = _setter(ff.name);
      final field = _cppStr(ff.name);
      switch (_scalarType(ff.type)) {
        case 'int':
          b
            ..writeln('std::optional<long> $t::$acc() const {')
            ..writeln('  const std::string v = doc().formField(path(), '
                '"$field");')
            ..writeln('  if (v.empty()) return std::nullopt;')
            ..writeln('  try { return std::stol(v); } '
                'catch (...) { return std::nullopt; }')
            ..writeln('}')
            ..writeln('void $t::$setAcc(std::optional<long> value) {')
            ..writeln('  doc().setFormField(path(), "$field", '
                'value.has_value() ? std::to_string(*value) : "");')
            ..writeln('}');
        case 'double':
        case 'num':
          b
            ..writeln('std::optional<double> $t::$acc() const {')
            ..writeln('  const std::string v = doc().formField(path(), '
                '"$field");')
            ..writeln('  if (v.empty()) return std::nullopt;')
            ..writeln('  try { return std::stod(v); } '
                'catch (...) { return std::nullopt; }')
            ..writeln('}')
            ..writeln('void $t::$setAcc(std::optional<double> value) {')
            ..writeln('  doc().setFormField(path(), "$field", '
                'value.has_value() ? std::to_string(*value) : "");')
            ..writeln('}');
        case 'bool':
          b
            ..writeln('std::optional<bool> $t::$acc() const {')
            ..writeln('  const std::string v = doc().formField(path(), '
                '"$field");')
            ..writeln('  if (v.empty()) return std::nullopt;')
            ..writeln('  return v == "true";')
            ..writeln('}')
            ..writeln('void $t::$setAcc(std::optional<bool> value) {')
            ..writeln('  doc().setFormField(path(), "$field", '
                'value.has_value() ? (*value ? "true" : "false") : "");')
            ..writeln('}');
        default:
          b
            ..writeln('std::string $t::$acc() const {')
            ..writeln('  return doc().formField(path(), "$field");')
            ..writeln('}')
            ..writeln('void $t::$setAcc(const std::string& value) {')
            ..writeln('  doc().setFormField(path(), "$field", value);')
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
      ..writeln('// GENERATED by tom_specs_clitool SomCppEmitter '
          '($versionLabel) — do not edit by hand.')
      ..writeln('// Typed object-model facade ($which) over the generic '
          'tom_som_cpp_runtime document.')
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

  /// Escapes a value for a double-quoted C++ string literal.
  String _cppStr(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  /// Member-function names inherited from `som::SomNode` that a generated getter
  /// must not shadow. A field named `doc`/`path` would otherwise produce an
  /// accessor that hides the base accessor — and, because the accessor body
  /// calls `doc()`/`path()`, recurse infinitely. Reserving them (trailing
  /// underscore, like the Go port's Doc/Path guard) keeps the base methods
  /// reachable; the stored path segment / form-field key is derived
  /// independently and stays byte-identical across languages.
  static const Set<String> _reservedMethodNames = {'doc', 'path'};

  /// The member-function name for a getter on [name]; a C++ keyword or an
  /// inherited `som::SomNode` method name gains a trailing underscore. Empty ⇒
  /// `field`.
  String _accessor(String name) {
    var base = name.trim();
    if (base.isEmpty) base = 'field';
    if (_cppKeywords.contains(base) || _reservedMethodNames.contains(base)) {
      base = '${base}_';
    }
    return base;
  }

  /// The member-function name for a setter on [name]: `set` + Pascal(name). The
  /// `set` prefix can never be a keyword, so no sanitising is needed.
  String _setter(String name) {
    final p = _pascal(name);
    return p.isEmpty ? 'setField' : 'set$p';
  }

  /// The enum-constant member name for [value] at [index]: the value itself when
  /// it is a legal identifier tail, keyword-sanitised; a positional fallback for
  /// an empty value. The carried token (the literal) keeps [value] byte-for-byte.
  String _enumConstName(String value, int index) {
    final v = value.trim();
    if (v.isEmpty) return 'value$index';
    return _cppKeywords.contains(v) ? '${v}_' : v;
  }

  String _pascal(String s) {
    final parts = s.split(RegExp(r'[_\s-]+')).where((p) => p.isNotEmpty);
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  /// camelCase — Pascal with a lowercased leading char. Matches
  /// `SomCppMetaEmitter._camel` so the threaded `<camel>MetaTree()` accessor
  /// name resolves to the emitted metadata-module entry point.
  String _camel(String s) {
    final p = _pascal(s);
    if (p.isEmpty) return p;
    return p[0].toLowerCase() + p.substring(1);
  }
}

class _EnumType {
  final String name;
  final List<String> values;
  _EnumType(this.name, this.values);
}

class _PendingForm {
  final String owner;
  final SpecField field;
  final String typeName;
  _PendingForm(this.owner, this.field, this.typeName);
}

class _ClassPlan {
  final SpecClass cls;
  final bool isRoot;
  String? rootSeg;
  final Map<String, String> formTypeFor = {};
  _ClassPlan(this.cls, this.isRoot);
}

class _FormPlan {
  final String typeName;
  final SpecField field;
  _FormPlan(this.typeName, this.field);
}
