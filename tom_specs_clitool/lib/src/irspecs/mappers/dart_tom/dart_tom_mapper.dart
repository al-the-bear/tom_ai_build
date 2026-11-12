/// The Dart + Tom mapper (`irspecs_ir.md` §7): an IR document set to the
/// `<app>_codespec_shared` / `_client` / `_server` sources CodeSpecs writes,
/// following `codespecs_derivation_contract.md`.
///
/// The mapper decides *what* is written — every token, every blank line,
/// every comment — and `dart format` decides the layout, which is the form
/// `codespecs_derivation_contract.md` §2.7 requires of a generated file. So
/// the mapper
/// prints each file as one long, unbroken stream of tokens, keeps the blank
/// lines Dart style puts between declarations and between import groups, and
/// leaves line breaking, indentation and trailing commas to the formatter.
///
/// What it prints from:
///
/// * a form-3b body from its **steps** (`irspecs_ir.md` §4.7), not from its
///   statement text — that is what makes a non-Dart mapper possible;
/// * a form-3a body from its thrown type and explication;
/// * markers, `@CodeSpec` and `@DocSpec` from their values;
/// * what the IR keeps as written because it is Dart by nature — a type, an
///   initialiser, a non-`Cs*` annotation, a string's literal — as written.
///
/// A construct it has no rule for — a constructor, a mixin, a top-level
/// function, a comment that is neither a banner nor a doc comment — is
/// refused with an [IrMapException], never printed approximately.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../codespecs/cs_model.dart';
import '../../ir_model.dart';
import '../../ir_steps.dart';

/// The mapper's id, as `irspecs map --mapper` names it.
const String kDartTomMapper = 'dart-tom';

/// Raised when the IR holds something the mapper has no rule to print.
class IrMapException implements Exception {
  /// What could not be printed, and where.
  final String message;

  /// Creates the exception.
  const IrMapException(this.message);

  @override
  String toString() => 'IrMapException: $message';
}

/// The sources [documents] describe, unformatted: `<package>/<path>` →
/// source text. Run [formatDartFiles] over them once written.
Map<String, String> mapDartTom(List<IrDocument> documents) {
  final out = <String, String>{};
  for (final document in documents) {
    final names = {
      for (final project in document.projects)
        project.locus: project.packageName,
    };
    for (final entry in document.files) {
      final key = '${names[entry.locus]}/${entry.file.path}';
      out[key] = _File(entry).render();
    }
  }
  return out;
}

/// Runs `dart format` over [paths]; throws [IrMapException] when it fails.
///
/// The formatter is the SDK's own binary — the one the trio is held to — so
/// the mapper and a developer formatting by hand agree by construction.
Future<void> formatDartFiles(List<String> paths) async {
  if (paths.isEmpty) return;
  final result = await Process.run(Platform.resolvedExecutable, [
    'format',
    '--output=write',
    ...paths,
  ]);
  if (result.exitCode != 0) {
    throw IrMapException('dart format failed: ${result.stderr}');
  }
}

/// Writes [documents]' sources under [outDir] and formats them; returns the
/// written paths.
///
/// Every project of the trio gets its folder, `<outDir>/<package>`, files or
/// not: Phase 4 always emits three projects (`codespecs_mapping.md` §4.2).
Future<List<String>> writeDartTom(
  List<IrDocument> documents,
  String outDir,
) async {
  for (final document in documents.take(1)) {
    for (final project in document.projects) {
      Directory(
        p.join(outDir, project.packageName),
      ).createSync(recursive: true);
    }
  }
  final written = <String>[];
  for (final MapEntry(key: key, value: source) in mapDartTom(
    documents,
  ).entries) {
    final file = File(p.joinAll([outDir, ...key.split('/')]))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(source);
    written.add(file.path);
  }
  await formatDartFiles(written);
  return written;
}

/// One file being printed.
class _File {
  final IrFile entry;
  final CsFile file;
  final Map<String, IrBodySteps> steps;
  final _out = StringBuffer();

  _File(this.entry)
    : file = entry.file,
      steps = {for (final r in entry.steps) '${r.owner}.${r.body}': r};

  String render() {
    for (final comment in file.comments) {
      if (comment.isBanner) {
        _out.writeln(comment.text);
      } else if (!comment.isDocumentation) {
        throw IrMapException(
          '${file.path}:${comment.location.line}: a comment that is neither '
          'the banner nor a doc comment (codespecs_derivation_contract.md '
          '§2.8 C6)',
        );
      }
    }
    _directives('import', file.imports);
    _directives('export', file.exports);
    for (final d in file.declarations.where((d) => d.isTopLevel)) {
      _blank();
      _topLevel(d);
    }
    return _out.toString();
  }

  /// One blank line, unless the output is empty or already ends in one.
  void _blank() {
    final text = _out.toString();
    if (text.isEmpty || text.endsWith('\n\n')) return;
    _out.writeln();
  }

  /// Directives in `dart:`, `package:`, relative groups, a blank line between
  /// groups — the order the files are written in.
  void _directives(String keyword, List<String> uris) {
    final groups = <List<String>>[[], [], []];
    for (final uri in uris) {
      groups[uri.startsWith('dart:')
              ? 0
              : uri.startsWith('package:')
              ? 1
              : 2]
          .add(uri);
    }
    for (final group in groups.where((g) => g.isNotEmpty)) {
      _blank();
      for (final uri in group) {
        _out.writeln("$keyword '$uri';");
      }
    }
  }

  List<CsDeclaration> _members(CsDeclaration owner) => [
    for (final d in file.declarations)
      if (d.owner == owner.name) d,
  ];

  void _topLevel(CsDeclaration d) {
    _lead(d);
    switch (d.kind) {
      case CsDeclarationKind.classType:
        final header = StringBuffer()
          ..write(d.isAbstract ? 'abstract class ' : 'class ')
          ..write(d.name)
          ..write(d.typeParameters ?? '');
        if (d.superclass case final s?) header.write(' extends $s');
        if (d.mixins.isNotEmpty) header.write(' with ${d.mixins.join(', ')}');
        if (d.interfaces.isNotEmpty) {
          header.write(' implements ${d.interfaces.join(', ')}');
        }
        final members = _members(d);
        if (members.isEmpty) {
          _out.writeln('$header {}');
          return;
        }
        _out.writeln('$header {');
        for (final (i, m) in members.indexed) {
          if (i > 0) _out.writeln();
          _member(d, m);
        }
        _out.writeln('}');
      case CsDeclarationKind.enumType:
        _out.writeln('enum ${d.name} {');
        for (final (i, c) in _members(d).indexed) {
          if (i > 0) _out.writeln();
          _lead(c);
          _out.writeln('${c.name}${c.initialiser ?? ''},');
        }
        _out.writeln('}');
      case CsDeclarationKind.topLevelVariable:
        _out.writeln(_variable(d));
      default:
        throw IrMapException(
          '${file.path}:${d.location.line}: no rule to print a '
          '${d.kind.name} (${d.name})',
        );
    }
  }

  /// The doc comment, then every annotation in the order it is written.
  void _lead(CsDeclaration d) {
    for (final line in d.docComment?.lines ?? const <String>[]) {
      _out.writeln(line);
    }
    final annotations = <(int, String)>[
      if (d.codeSpec case final link?) (link.location.line, _codeSpec(link)),
      if (d.docSpec case final refs?)
        (d.docSpecLocation?.line ?? d.location.line, _docSpec(refs)),
      for (final m in d.markers) (m.location.line, _marker(m)),
      for (final a in d.annotations) (a.location.line, a.source),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, text) in annotations) {
      _out.writeln(text);
    }
  }

  void _member(CsDeclaration owner, CsDeclaration m) {
    _lead(m);
    switch (m.kind) {
      case CsDeclarationKind.field:
        _out.writeln(_variable(m));
      case CsDeclarationKind.method:
        _method(owner, m);
      default:
        throw IrMapException(
          '${file.path}:${m.location.line}: no rule to print a '
          '${m.kind.name} member (${owner.name}.${m.name})',
        );
    }
  }

  String _variable(CsDeclaration d) {
    final words = [
      if (d.isStatic && !d.isTopLevel) 'static',
      if (d.isLate) 'late',
      if (d.isConst)
        'const'
      else if (d.isFinal)
        'final'
      else if (d.declaredType == null)
        'var',
      ?d.declaredType,
      d.name,
    ];
    final initialiser = d.initialiser == null ? '' : ' = ${d.initialiser}';
    return '${words.join(' ')}$initialiser;';
  }

  void _method(CsDeclaration owner, CsDeclaration m) {
    final body = m.bodies.single;
    final head = [
      if (m.isStatic) 'static',
      ?body.returnType,
      ?body.accessor,
      m.name,
    ].join(' ');
    final parameters = body.accessor == 'get' ? '' : _parameters(body);
    final modifier = body.isAsync ? ' async' : '';
    _out.write('$head$parameters$modifier');
    _out.writeln(_body(owner, body));
  }

  String _parameters(CsMethodBody body) {
    String one(CsParameter p) {
      final words = [
        if (p.kind == CsParameterKind.requiredNamed) 'required',
        ?p.type,
        p.name,
      ].join(' ');
      return p.defaultValue == null ? words : '$words = ${p.defaultValue}';
    }

    final required = [
      for (final p in body.parameters)
        if (p.kind == CsParameterKind.requiredPositional) one(p),
    ];
    final optional = [
      for (final p in body.parameters)
        if (p.kind == CsParameterKind.optionalPositional) one(p),
    ];
    final named = [
      for (final p in body.parameters)
        if (p.kind == CsParameterKind.requiredNamed ||
            p.kind == CsParameterKind.optionalNamed)
          one(p),
    ];
    return '(${[...required, if (optional.isNotEmpty) '[${optional.join(', ')}]', if (named.isNotEmpty) '{${named.join(', ')}}'].join(', ')})';
  }

  String _body(CsDeclaration owner, CsMethodBody body) {
    switch (body.shape) {
      case CsBodyShape.none:
        return ';';
      case CsBodyShape.throwOnly:
        final type = body.thrownType;
        if (type == null) {
          throw IrMapException(
            '${file.path}:${body.location.line}: a throw the IR does not hold',
          );
        }
        final argument = body.thrownLiteral ?? _quote(body.thrownMessage ?? '');
        final thrown = 'throw $type($argument)';
        return body.isArrow ? ' => $thrown;' : ' { $thrown; }';
      case CsBodyShape.returnsValue:
      case CsBodyShape.other:
        final record = steps['${owner.name}.${body.name}'];
        if (record?.steps case final steps?) {
          return ' { ${_steps(steps, body.isAsync)} }';
        }
        throw IrMapException(
          '${file.path}:${body.location.line}: ${owner.name}.${body.name} is '
          'a form-3b body without steps'
          '${record?.issue == null ? '' : ' (${record!.issue})'}',
        );
    }
  }

  String _steps(List<IrStep> steps, bool isAsync) {
    final wait = isAsync ? 'await ' : '';
    String call(String method, List<String> arguments) =>
        '$kCollaboratorField.$method(${arguments.join(', ')})';
    return [
      for (final step in steps)
        switch (step) {
          IrCallStep(:final method, :final arguments) =>
            '$wait${call(method, arguments)};',
          IrReturnStep(method: null) => 'return;',
          IrReturnStep(:final method?, :final arguments) =>
            'return ${call(method, arguments)};',
          IrGuardedStep(:final guard, :final arguments, :final steps) =>
            'if ($wait${call(guard, arguments)}) '
                '{ ${_steps(steps, isAsync)} }',
        },
    ].join(' ');
  }

  String _codeSpec(CsCodeSpecLink link) {
    final source = link.source.map(_quote).join(', ');
    return "@CodeSpec(${_quote(link.id)}, source: [$source])";
  }

  String _docSpec(List<CsDocRef> refs) =>
      '@DocSpec([${[for (final r in refs) 'DocRef(${_quote(r.sectionId)}, '
            '${r.descriptionLiteral ?? _quote(r.description)})'].join(', ')}])';

  String _marker(CsMarker m) =>
      '@${m.name}(${_arguments(m.positional, m.named)})';

  String _arguments(List<CsValue> positional, Map<String, CsValue> named) => [
    for (final v in positional) _value(v),
    for (final e in named.entries) '${e.key}: ${_value(e.value)}',
  ].join(', ');

  String _value(CsValue v) => switch (v) {
    CsStringValue(:final value, :final literal) => literal ?? _quote(value),
    CsBoolValue(:final value) => '$value',
    CsIntValue(:final value) => '$value',
    CsNullValue() => 'null',
    CsQualifiedValue(:final path) => path,
    CsConstructionValue(:final type, :final positional, :final named) =>
      '$type(${_arguments(positional, named)})',
    CsListValue(:final values) => '[${values.map(_value).join(', ')}]',
    CsUnknownValue(:final source) => source,
  };
}

/// [text] as a single-quoted Dart string literal.
String _quote(String text) {
  final escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n');
  return "'$escaped'";
}
