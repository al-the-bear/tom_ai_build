/// The API-signature gate: does every signature an API summary quotes agree
/// with the package's element model?
///
/// ## Why this exists
///
/// The API summaries (`doc/api/api_summary_*.md`) are what a reader consults
/// *instead of* the source, so a stale signature there misleads more directly
/// than anywhere else — and nothing read them. A renamed parameter, a
/// positional argument that became named, a type that changed: each parses
/// perfectly, so a check that only parses the fences proves nothing. Under
/// `tom_ai/core` the first run of this check over six packages found 27 such
/// faults, among them `tom_core_codespecs`'s whole summary, whose 21
/// constructor fences had been cut off before their closing `})`.
///
/// ## How
///
/// It resolves every public library of the package (each `lib/*.dart` but
/// generated `*.b.dart` bridges), parses each
/// ```` ```dart ```` fence as members of the type it documents — the class its
/// constructor names, else the nearest `###`/`####` heading that names an
/// exported type — and compares every member with the element: that it exists,
/// `const` / `factory` / `static`, its return type, and each parameter's kind,
/// type and default. Positional parameters are matched by position, since no
/// caller writes their names; named ones by name. A fence quoting a bare class
/// header (`abstract interface class X`) is held to the class's modifiers; one
/// quoting top-level functions, getters or a `typedef` is held to those
/// exports.
///
/// A fence must parse as declarations. The one parse error tolerated is the
/// one a quoted signature always has, a missing body; anything else — a
/// truncated parameter list, a type parameter on a constructor — is a fault,
/// unless the fence parses as statements, which makes it a usage sample.
///
/// Types are compared structurally, not as text: a typedef with its arguments,
/// a raw generic for its instantiation to bounds, a function type with
/// parameter names and a record with its named fields in any order are each
/// the type the analyzer prints expanded. A default the declaration names bare
/// (`defaultLimit`) may be quoted as `Owner.defaultLimit`; a private default
/// cannot be quoted and is not compared. A fence with a body or a statement is
/// a usage sample and is counted, not compared.
///
/// ## What it does not read
///
/// The `Methods` and `Properties` *tables* quote signatures as inline code in a
/// cell; this reads fences only.
///
/// The design is `tom_ai/core`'s `tool/api_signatures/` program, carried here
/// so that each repository holds its own checks.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Where the manifest of gated packages lives, clitool-relative.
const String apiSignatureSetPath = 'tool/api_signature_set.yaml';

/// The packages whose summaries are gated, container-root-relative, each with
/// the folder its summaries live in.
class ApiSignatureSet {
  /// `(package, summary folder)` pairs, in manifest order.
  final List<({String package, String docs})> entries;

  /// A set of [entries].
  const ApiSignatureSet(this.entries);

  /// Reads the manifest: a `packages:` list of package paths, each optionally
  /// `path: docs-folder` (default `doc/api`).
  factory ApiSignatureSet.parse(String yaml) {
    final doc = loadYaml(yaml) as YamlMap;
    final list = doc['packages'] as YamlList;
    return ApiSignatureSet([
      for (final item in list)
        if (item is String)
          (package: item, docs: 'doc/api')
        else
          for (final e in (item as YamlMap).entries)
            (package: e.key as String, docs: e.value as String),
    ]);
  }
}

/// What one package's check found.
class ApiSignatureReport {
  /// The package directory, as given.
  final String package;

  /// Fences read.
  final int fences;

  /// Fences that were usage samples, counted and not compared.
  final int programs;

  /// Members compared with the element model.
  final int members;

  /// One line per disagreement: `<document>:<line>  <what>`.
  final List<String> faults;

  /// A report of the counts and [faults].
  const ApiSignatureReport({
    required this.package,
    required this.fences,
    required this.programs,
    required this.members,
    required this.faults,
  });
}

/// Checks every summary under [docDir] against the public libraries of the
/// package at [packageDir].
///
/// Throws [StateError] when a library does not resolve.
Future<ApiSignatureReport> checkApiSignatures({
  required String packageDir,
  required String docDir,
}) async {
  final package = p.normalize(p.absolute(packageDir));
  final docs = Directory(p.normalize(p.absolute(docDir)));
  // Every public library is API a reader can import, so a summary may document
  // any of them; generated bridge libraries (`*.b.dart`) are not documented.
  final libraries =
      Directory(p.join(package, 'lib'))
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((path) => path.endsWith('.dart') && !path.endsWith('.b.dart'))
          .toList()
        ..sort();
  if (libraries.isEmpty) throw StateError('no library under $package/lib');

  final collection = AnalysisContextCollection(includedPaths: [package]);
  try {
    final namespaces = <Element? Function(String)>[];
    for (final library in libraries) {
      final context = collection.contextFor(library);
      final result = await context.currentSession.getResolvedLibrary(library);
      if (result is! ResolvedLibraryResult) {
        throw StateError('could not resolve $library');
      }
      namespaces.add(result.element.exportNamespace.get2);
    }
    Element? lookUp(String name) {
      for (final namespace in namespaces) {
        final element = namespace(name);
        if (element != null) return element;
      }
      return null;
    }

    final tally = _Tally();
    final documents =
        docs
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final document in documents) {
      final shown = p.isWithin(package, document.path)
          ? p.relative(document.path, from: package)
          : document.path;
      for (final fence in _fences(document.readAsStringSync())) {
        _checkFence(shown, fence, lookUp, tally);
      }
    }
    return ApiSignatureReport(
      package: packageDir,
      fences: tally.fences,
      programs: tally.programs,
      members: tally.members,
      faults: tally.faults,
    );
  } finally {
    await collection.dispose();
  }
}

/// What one run saw.
class _Tally {
  int fences = 0;
  int programs = 0;
  int members = 0;
  final faults = <String>[];
}

/// A ```dart fence, the line it opens on, and the names its headings carry,
/// nearest first -- a `#### Operators` under `### TomInt` names a section, not
/// a type, so the owner is the first of them the package actually exports.
typedef _Fence = ({int line, String body, List<String> headings});

/// The heading that names a type: `### TomBean\<T\>`, `#### TomApi`.
final _typeHeading = RegExp(r'^#{3,4}\s+`?([A-Za-z_]\w*)');

Iterable<_Fence> _fences(String text) sync* {
  final lines = text.split('\n');
  String? h3;
  String? h4;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('## ')) h3 = h4 = null;
    final named = _typeHeading.firstMatch(line);
    if (named != null) {
      if (line.startsWith('### ')) {
        h3 = named.group(1);
        h4 = null;
      } else {
        h4 = named.group(1);
      }
    }
    if (line.trimLeft().startsWith('```dart')) {
      final start = i + 1;
      final body = <String>[];
      for (
        i++;
        i < lines.length && !lines[i].trimLeft().startsWith('```');
        i++
      ) {
        body.add(lines[i]);
      }
      yield (line: start, body: body.join('\n'), headings: [?h4, ?h3]);
    }
  }
}

/// A fence is a program, not a list of signatures, when it carries a body:
/// `=>`, or a `{` that opens a block. A summary quotes declarations without
/// one.
///
/// A line ending in `;` does **not** make a fence a program here, unlike in
/// `tom_ai/core`'s design: the summaries in this repository end every quoted
/// declaration with `;`, so that rule classified all of them as samples and
/// compared nothing. A fence of statements is still recognised — it does not
/// parse as declarations and does parse as statements (see `_unparsed`).
final _program = RegExp(r'=>|\)\s*(async\s*)?\{', multiLine: true);

/// A quoted type header with no body: `abstract interface class TomX`, whose
/// claim is the _modifiers.
final _typeHeader = RegExp(
  r'^\s*((?:abstract\s+|base\s+|final\s+|interface\s+|sealed\s+|mixin\s+)*)'
  r'class\s+([A-Z]\w*)[^\n]*$',
);

/// The type a signature fence quotes the members of: the class its first
/// constructor names, else the heading above it.
final _constructorHead = RegExp(
  r'^\s*(?:const\s+|factory\s+)*([A-Z]\w*)(?:\.\w+)?\s*\(',
);

void _checkFence(
  String document,
  _Fence fence,
  Element? Function(String) lookUp,
  _Tally tally,
) {
  tally.fences++;
  final where = '$document:${fence.line}';
  // An annotation shown in use -- `@TomX(...)` with nothing under it -- is a
  // usage sample like any other.
  final annotationOnly =
      fence.body.trimLeft().startsWith('@') &&
      _afterAnnotations(fence.body).isEmpty;
  if (annotationOnly || _program.hasMatch(fence.body)) {
    tally.programs++;
    return;
  }
  final header = _typeHeader.firstMatch(fence.body.trim());
  if (header != null && !fence.body.trim().contains('\n')) {
    tally.members++;
    final element = lookUp(header.group(2)!);
    if (element is! ClassElement) {
      tally.faults.add(
        '$where  `${header.group(2)}` is not a class the '
        'package exports',
      );
      return;
    }
    final quoted = header.group(1)!.split(RegExp(r'\s+'))
      ..removeWhere((m) => m.isEmpty);
    final real = _modifiers(element);
    if (quoted.join(' ') != real.join(' ')) {
      tally.faults.add(
        '$where  ${header.group(2)}: is `${[...real, 'class'].join(' ')}`, '
        'quoted as `${[...quoted, 'class'].join(' ')}`',
      );
    }
    return;
  }
  final named = _constructorHead.firstMatch(fence.body)?.group(1);
  final owner =
      named ??
      fence.headings.where((h) => lookUp(h) is InterfaceElement).firstOrNull;
  if (owner == null) {
    _checkTopLevel(where, fence.body, lookUp, tally);
    return;
  }
  final element = lookUp(owner);
  if (element is! InterfaceElement) {
    tally.faults.add('$where  `$owner` is not a type the package exports');
    return;
  }

  // A summary writes declarations without bodies. Terminate each so it parses
  // as a member of its owner: a declaration ends where a line closes its last
  // open bracket and the next non-blank line starts another.
  final source = 'abstract class $owner {\n${_terminate(fence.body)}\n}\n';
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  if (!_parsesAsSignatures(
    parsed.errors.map((e) => e.diagnosticCode.lowerCaseName),
  )) {
    _unparsed(where, fence.body, tally);
    return;
  }
  final unit = parsed.unit;
  final declaration = unit.declarations.whereType<ClassDeclaration>().first;
  final members = declaration.body is BlockClassBody
      ? (declaration.body as BlockClassBody).members
      : const <ClassMember>[];
  if (members.isEmpty) {
    tally.faults.add(
      '$where  quotes nothing that reads as a member of `$owner`',
    );
    return;
  }
  for (final member in members) {
    tally.members++;
    final problems = _compare(member, element);
    for (final problem in problems) {
      tally.faults.add('$where  $owner${_memberLabel(member)}: $problem');
    }
  }
}

/// Whether a fence's parse errors are only the one a quoted signature always
/// has: a declaration without its body. Anything else means the fence is not a
/// list of declarations as written -- a truncated parameter list, a type
/// parameter on a constructor -- or is not a declaration at all.
bool _parsesAsSignatures(Iterable<String> codes) =>
    codes.every((code) => code == 'missing_function_body');

/// A fence that does not parse as declarations: a usage sample if it parses
/// as statements, otherwise a fault -- a quote nobody can _compare is a quote
/// nobody can trust.
void _unparsed(String where, String body, _Tally tally) {
  final asStatements = parseString(
    content: 'void _sample() {\n$body;\n}\n',
    throwIfDiagnostics: false,
  );
  if (asStatements.errors.isEmpty) {
    tally.programs++;
    return;
  }
  tally.faults.add('$where  does not parse as a signature');
}

/// What follows the leading annotations of `body`: each `@name` and, when it
/// has one, its balanced argument list.
String _afterAnnotations(String body) {
  var rest = body.trimLeft();
  while (rest.startsWith('@')) {
    final head = RegExp(r'^@[\w.]+').firstMatch(rest);
    if (head == null) return rest;
    rest = rest.substring(head.end);
    if (rest.startsWith('(')) {
      var depth = 0;
      var i = 0;
      for (; i < rest.length; i++) {
        if (rest[i] == '(') depth++;
        if (rest[i] == ')' && --depth == 0) break;
      }
      rest = rest.substring(i + 1);
    }
    rest = rest.trimLeft();
  }
  return rest;
}

/// A fence that quotes top-level declarations -- a function, a getter -- each
/// looked up by its own name in the package's exports.
void _checkTopLevel(
  String where,
  String body,
  Element? Function(String) lookUp,
  _Tally tally,
) {
  final parsed = parseString(
    content: _terminate(body),
    throwIfDiagnostics: false,
  );
  if (!_parsesAsSignatures(
    parsed.errors.map((e) => e.diagnosticCode.lowerCaseName),
  )) {
    _unparsed(where, body, tally);
    return;
  }
  final unit = parsed.unit;
  final functions = unit.declarations.whereType<FunctionDeclaration>().toList();
  final aliases = unit.declarations.whereType<GenericTypeAlias>().toList();
  for (final alias in aliases) {
    tally.members++;
    final name = alias.name.lexeme;
    final real = lookUp(name);
    if (real is! TypeAliasElement) {
      tally.faults.add('$where  $name: is not a typedef the package exports');
    } else if (!_matches(alias.type, real.aliasedType)) {
      tally.faults.add(
        '$where  $name: aliases `${_display(real.aliasedType)}`, '
        'quoted as `${alias.type.toSource()}`',
      );
    }
  }
  if (functions.isEmpty && aliases.isNotEmpty) return;
  if (functions.isEmpty) {
    tally.faults.add(
      '$where  names no type and declares no top-level '
      'function: no constructor leads the fence and no heading above it '
      'names an exported type',
    );
    return;
  }
  for (final function in functions) {
    tally.members++;
    final name = function.name.lexeme;
    final real = lookUp(name);
    final problems = <String>[];
    if (function.isGetter) {
      if (real is! GetterElement) {
        problems.add('is not a top-level getter the package exports');
      } else if (!_matches(function.returnType, real.returnType)) {
        problems.add(
          'returns `${_display(real.returnType)}`, quoted as '
          '`${function.returnType?.toSource()}`',
        );
      }
    } else if (real is! TopLevelFunctionElement) {
      problems.add('is not a top-level function the package exports');
    } else {
      if (!_matches(function.returnType, real.returnType)) {
        problems.add(
          'returns `${_display(real.returnType)}`, quoted as '
          '`${function.returnType?.toSource()}`',
        );
      }
      problems.addAll(
        _compareParameters(
          function.functionExpression.parameters,
          real.formalParameters,
        ),
      );
    }
    for (final problem in problems) {
      tally.faults.add('$where  $name: $problem');
    }
  }
}

/// Adds the `;` a body-less declaration needs to parse.
String _terminate(String body) {
  final lines = body.split('\n');
  final out = <String>[];
  var depth = 0;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    final code = line.replaceAll(RegExp(r'//.*$'), '');
    for (final char in code.split('')) {
      if ('([{<'.contains(char)) depth++;
      if (')]}>'.contains(char)) depth--;
    }
    final trimmed = code.trimRight();
    // An annotation line belongs to the declaration below it.
    if (trimmed.trimLeft().startsWith('@') && depth <= 0) {
      out.add(line);
      continue;
    }
    if (depth <= 0 &&
        trimmed.isNotEmpty &&
        !trimmed.endsWith(';') &&
        !trimmed.endsWith(',')) {
      final comment = line.length > code.length
          ? line.substring(code.length)
          : '';
      line = '${trimmed.trimRight()};$comment';
      depth = 0;
    }
    out.add(line);
  }
  return out.join('\n');
}

/// A class's _modifiers in source order.
List<String> _modifiers(ClassElement element) => [
  if (element.isAbstract && !element.isInterface && !element.isSealed ||
      element.isAbstract && element.isInterface)
    'abstract',
  if (element.isBase) 'base',
  if (element.isFinal) 'final',
  if (element.isInterface) 'interface',
  if (element.isSealed) 'sealed',
  if (element.isMixinClass) 'mixin',
];

String _memberLabel(ClassMember member) => switch (member) {
  ConstructorDeclaration(:final name) =>
    name == null ? '()' : '.${name.lexeme}',
  MethodDeclaration(:final name) => '.${name.lexeme}',
  FieldDeclaration(:final fields) => '.${fields.variables.first.name.lexeme}',
  _ => '',
};

List<String> _compare(ClassMember member, InterfaceElement owner) {
  switch (member) {
    case ConstructorDeclaration():
      final name = member.name?.lexeme ?? 'new';
      final real =
          owner.getNamedConstructor(name) ??
          (name == 'new' ? owner.unnamedConstructor : null);
      if (real == null) return ['no such constructor'];
      return [
        if ((member.factoryKeyword != null) != real.isFactory)
          real.isFactory
              ? 'is a factory, quoted as generative'
              : 'is generative, quoted as a factory',
        if ((member.constKeyword != null) != real.isConst)
          real.isConst ? 'is const, quoted without it' : 'is not const',
        ..._compareParameters(member.parameters, real.formalParameters),
      ];
    case MethodDeclaration():
      final name = member.name.lexeme;
      final ExecutableElement? real = member.isGetter
          ? owner.getGetter(name)
          : member.isSetter
          ? owner.getSetter(name)
          : owner.getMethod(name);
      if (real == null) {
        return [
          'no such ${member.isGetter
              ? 'getter'
              : member.isSetter
              ? 'setter'
              : 'method'} on the type',
        ];
      }
      final quoted = member.returnType;
      return [
        if (member.isStatic != real.isStatic)
          real.isStatic
              ? 'is static, quoted as an instance member'
              : 'is an instance member, quoted as static',
        if (!_matches(quoted, real.returnType))
          'returns `${_display(real.returnType)}`, quoted as '
              '`${quoted?.toSource()}`',
        if (!member.isGetter)
          ..._compareParameters(member.parameters, real.formalParameters),
      ];
    case FieldDeclaration():
      final name = member.fields.variables.first.name.lexeme;
      final real = owner.getGetter(name);
      if (real == null) return ['no such field or getter'];
      final quoted = member.fields.type;
      return [
        if (!_matches(quoted, real.returnType))
          'is `${_display(real.returnType)}`, quoted as `${quoted?.toSource()}`',
      ];
    default:
      return ['is not a declaration this check reads'];
  }
}

List<String> _compareParameters(
  FormalParameterList? quoted,
  List<FormalParameterElement> real,
) {
  if (quoted == null) return const [];
  final problems = <String>[];
  final doc = quoted.parameters;
  // A positional parameter's name is not part of the API -- no caller writes
  // it -- so positional parameters are matched by position. A named one is
  // matched by name, which is the whole of its identity.
  final docPositional = [
    for (final p in doc)
      if (!p.isNamed) p,
  ];
  final realPositional = [
    for (final p in real)
      if (!p.isNamed) p,
  ];
  final docNamed = {
    for (final p in doc)
      if (p.isNamed) p.name?.lexeme ?? '': p,
  };
  final realNamed = {
    for (final p in real)
      if (p.isNamed) p.name ?? '': p,
  };

  if (docPositional.length != realPositional.length) {
    problems.add(
      'takes ${realPositional.length} positional parameter(s), '
      'quoted with ${docPositional.length}',
    );
  }
  for (var i = 0; i < docPositional.length && i < realPositional.length; i++) {
    problems.addAll(
      _compareOne(
        docPositional[i],
        realPositional[i],
        'positional parameter ${i + 1}',
      ),
    );
  }
  for (final name in realNamed.keys) {
    if (!docNamed.containsKey(name)) problems.add('omits `$name`');
  }
  for (final entry in docNamed.entries) {
    final r = realNamed[entry.key];
    if (r == null) {
      problems.add('has no named parameter `${entry.key}`');
      continue;
    }
    problems.addAll(_compareOne(entry.value, r, '`${entry.key}`'));
  }
  return problems;
}

List<String> _compareOne(
  FormalParameter d,
  FormalParameterElement r,
  String label,
) {
  final type = _declaredType(d);
  final quotedDefault = _defaultOf(d);
  final realDefault = r.defaultValueCode;
  return [
    if (_kind(d) != _kindOf(r))
      '$label is ${_kindOf(r)}, quoted as ${_kind(d)}',
    if (!_matches(type, r.type))
      '$label is `${_display(r.type)}`, quoted as `${type?.toSource()}`',
    if (quotedDefault != null &&
        realDefault != null &&
        !_sameDefault(quotedDefault, realDefault))
      '$label defaults to `$realDefault`, quoted as `$quotedDefault`',
  ];
}

String _kind(FormalParameter p) => p.isRequiredNamed
    ? 'required named'
    : p.isNamed
    ? 'optional named'
    : p.isOptionalPositional
    ? 'optional positional'
    : 'required positional';

String _kindOf(FormalParameterElement p) => p.isRequiredNamed
    ? 'required named'
    : p.isNamed
    ? 'optional named'
    : p.isOptionalPositional
    ? 'optional positional'
    : 'required positional';

// analyzer 14 folds the default value into the parameter itself (its
// `defaultClause`), so there is no wrapping node to look through.
TypeAnnotation? _declaredType(FormalParameter p) => p.type;

String? _defaultOf(FormalParameter p) => p.defaultClause?.value.toSource();

String _display(DartType type) => type.getDisplayString();

String _squash(String text) => text.replaceAll(RegExp(r'\s+'), '');

/// Whether a quoted type annotation names the real type.
///
/// Compared structurally rather than as text, because the summaries write a
/// type the way its declaration does and the analyzer prints it expanded.
/// Three spellings are therefore the same type: a typedef's name with its
/// arguments for the function type it aliases (`ValueChanged<String>`), a raw
/// generic for its instantiation to bounds (`List<TomCompositeStep>`), and a
/// function type with parameter names for the same type without them. An
/// absent annotation claims nothing.
bool _matches(TypeAnnotation? quoted, DartType real) {
  if (quoted == null) return true;
  final nullable = real.nullabilitySuffix == NullabilitySuffix.question;
  switch (quoted) {
    case NamedType(:final name, :final typeArguments, :final question):
      final args = typeArguments?.arguments;
      final text = name.lexeme;
      if (text == 'dynamic') return real is DynamicType;
      if ((question != null) != nullable && real is! DynamicType) return false;
      final alias = real.alias;
      if (alias != null && alias.element.name == text) {
        return args == null || _sameAll(args, alias.typeArguments);
      }
      if (text == 'Function') return real is FunctionType;
      return switch (real) {
        InterfaceType(:final element, :final typeArguments) =>
          element.name == text &&
              (args == null || _sameAll(args, typeArguments)),
        TypeParameterType(:final element) => element.name == text,
        VoidType() => text == 'void',
        NeverType() => text == 'Never',
        _ => _squash(quoted.toSource()) == _squash(_display(real)),
      };
    case GenericFunctionType(
      :final returnType,
      :final parameters,
      :final question,
    ):
      if (real is! FunctionType) return false;
      if ((question != null) != nullable) return false;
      if (!_matches(returnType, real.returnType)) return false;
      return _compareParameters(parameters, real.formalParameters).isEmpty;
    case RecordTypeAnnotation(:final positionalFields, :final namedFields):
      if (real is! RecordType) return false;
      if ((quoted.question != null) != nullable) return false;
      if (positionalFields.length != real.positionalFields.length) return false;
      for (var i = 0; i < positionalFields.length; i++) {
        if (!_matches(
          positionalFields[i].type,
          real.positionalFields[i].type,
        )) {
          return false;
        }
      }
      // Named fields are a set: the analyzer prints them sorted.
      final quotedNamed = {
        for (final f
            in namedFields?.fields ?? const <RecordTypeAnnotationNamedField>[])
          f.name.lexeme: f.type,
      };
      if (quotedNamed.length != real.namedFields.length) return false;
      for (final field in real.namedFields) {
        final type = quotedNamed[field.name];
        if (type == null || !_matches(type, field.type)) return false;
      }
      return true;
  }
}

bool _sameAll(List<TypeAnnotation> quoted, List<DartType> real) {
  if (quoted.length != real.length) return false;
  for (var i = 0; i < quoted.length; i++) {
    if (!_matches(quoted[i], real[i])) return false;
  }
  return true;
}

/// Whether a quoted default is the declared one. A constant the declaration
/// names bare (`defaultLimit`) is `Owner.defaultLimit` to everyone outside the
/// class, which is how a summary has to write it; and a private default cannot
/// be quoted at all, so there is nothing to hold it to.
bool _sameDefault(String quoted, String real) {
  final q = _squash(quoted);
  final r = _squash(real);
  if (q == r) return true;
  if (r.startsWith('_')) return true;
  return RegExp(r'^\w+$').hasMatch(r) && q.endsWith('.$r');
}
