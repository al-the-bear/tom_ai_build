/// Reads emitted CodeSpecs Dart into the [CsLocusProject] model the
/// `codespecs_derivation_contract.md` §6 checks run over.
///
/// **Why the syntax tree and not the element model.** The validation pass runs
/// where the generator's does: immediately after emission, on a tree that has
/// never been through `pub get` and whose `tom_core`-family dependencies may not
/// be resolvable at all. Resolution would put a package fetch inside the
/// generation pipeline. It is also unnecessary — §2.7 fixes the shape of an
/// emitted file, and every value the checks read is written inline as a literal,
/// an enum access or a `Cs*Ref` const, so the constant surface is exactly what
/// the syntax carries.
///
/// The one thing this costs is a marker written through a const alias
/// (`@myTrigger`); §2.7 point 4 emits markers inline, so no generated file has
/// one, and a hand-written one reads as a marker-less declaration rather than as
/// a wrong one.
library;

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'cs_model.dart';

/// The annotations that are not part markers and are read separately.
const _backLinkAnnotations = {'CodeSpec', 'DocSpec'};

/// Reads one locus project from in-memory sources — path → Dart source.
CsLocusProject readCsLocusProject({
  required CsLocus locus,
  required String packageName,
  required Map<String, String> sources,
}) {
  final files = <CsFile>[];
  final paths = sources.keys.toList()..sort();
  for (final path in paths) {
    files.add(_readFile(locus, path, sources[path]!));
  }
  return CsLocusProject(locus: locus, packageName: packageName, files: files);
}

/// Reads one locus project from a directory tree, taking every `.dart` file
/// under `lib/`.
CsLocusProject readCsLocusProjectFromDirectory({
  required CsLocus locus,
  required String packageName,
  required String root,
}) {
  final libDir = io.Directory(p.join(root, 'lib'));
  final sources = <String, String>{};
  if (libDir.existsSync()) {
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is io.File && entity.path.endsWith('.dart')) {
        sources[p.relative(entity.path, from: root)] =
            entity.readAsStringSync();
      }
    }
  }
  return readCsLocusProject(
    locus: locus,
    packageName: packageName,
    sources: sources,
  );
}

CsFile _readFile(CsLocus locus, String path, String source) {
  final parsed = parseString(
    content: source,
    path: path,
    throwIfDiagnostics: false,
  );
  final lines = parsed.lineInfo;
  final unit = parsed.unit;

  final imports = <String>[];
  for (final directive in unit.directives) {
    if (directive is ImportDirective) {
      imports.add(directive.uri.stringValue ?? '');
    }
  }

  final declarations = <CsDeclaration>[];
  final constructions = <CsConstruction>[];

  for (final member in unit.declarations) {
    switch (member) {
      case ClassDeclaration():
        final name = member.namePart.typeName;
        final members = _membersOf(member.body);
        declarations.add(
          _declaration(
            locus: locus,
            path: path,
            lines: lines,
            name: name.lexeme,
            kind: CsDeclarationKind.classType,
            metadata: member.metadata,
            offset: name.offset,
            bodies: _bodies(path, lines, members),
            isAbstract: member.abstractKeyword != null,
          ),
        );
        declarations.addAll(
          _classMembers(locus, path, lines, name.lexeme, members),
        );
        constructions.addAll(
          _constructions(path, lines, name.lexeme, members),
        );
      case EnumDeclaration():
        final name = member.namePart.typeName;
        declarations.add(
          _declaration(
            locus: locus,
            path: path,
            lines: lines,
            name: name.lexeme,
            kind: CsDeclarationKind.enumType,
            metadata: member.metadata,
            offset: name.offset,
          ),
        );
      case MixinDeclaration():
        declarations.add(
          _declaration(
            locus: locus,
            path: path,
            lines: lines,
            name: member.name.lexeme,
            kind: CsDeclarationKind.mixinType,
            metadata: member.metadata,
            offset: member.name.offset,
            bodies: _bodies(path, lines, member.body.members),
          ),
        );
      case TopLevelVariableDeclaration():
        for (final variable in member.variables.variables) {
          declarations.add(
            _declaration(
              locus: locus,
              path: path,
              lines: lines,
              name: variable.name.lexeme,
              kind: CsDeclarationKind.topLevelVariable,
              metadata: member.metadata,
              offset: variable.name.offset,
              hasInitialiser: variable.initializer != null,
              declaredType: member.variables.type?.toSource(),
            ),
          );
          final construction = _constructionOf(
            path,
            lines,
            variable.name.lexeme,
            variable.initializer,
          );
          if (construction != null) constructions.add(construction);
        }
      case FunctionDeclaration():
        declarations.add(
          _declaration(
            locus: locus,
            path: path,
            lines: lines,
            name: member.name.lexeme,
            kind: CsDeclarationKind.topLevelFunction,
            metadata: member.metadata,
            offset: member.name.offset,
            bodies: [
              _body(path, lines, member.name.lexeme,
                  member.functionExpression.body),
            ],
          ),
        );
      default:
        break;
    }
  }

  return CsFile(
    path: path,
    imports: imports,
    declarations: declarations,
    constructions: constructions,
  );
}

/// The members of a class body — empty for a body-less primary-constructor
/// class, which carries no members to read.
List<ClassMember> _membersOf(ClassBody body) =>
    body is BlockClassBody ? body.members : const <ClassMember>[];

List<CsDeclaration> _classMembers(
  CsLocus locus,
  String path,
  LineInfo lines,
  String owner,
  List<ClassMember> members,
) {
  final out = <CsDeclaration>[];
  for (final member in members) {
    switch (member) {
      case FieldDeclaration():
        for (final variable in member.fields.variables) {
          out.add(
            _declaration(
              locus: locus,
              path: path,
              lines: lines,
              name: variable.name.lexeme,
              kind: CsDeclarationKind.field,
              owner: owner,
              metadata: member.metadata,
              offset: variable.name.offset,
              hasInitialiser: variable.initializer != null,
              declaredType: member.fields.type?.toSource(),
              isStatic: member.isStatic,
            ),
          );
        }
      case MethodDeclaration():
        out.add(
          _declaration(
            locus: locus,
            path: path,
            lines: lines,
            name: member.name.lexeme,
            kind: CsDeclarationKind.method,
            owner: owner,
            metadata: member.metadata,
            offset: member.name.offset,
            bodies: [_body(path, lines, member.name.lexeme, member.body)],
            isStatic: member.isStatic,
          ),
        );
      // A constructor is read for its *presence*: check 24 rejects one on a
      // `@CsCollaborator` class, which is otherwise invisible to a model that
      // only records fields and methods. An unnamed constructor is recorded
      // under the class name, matching how it is written.
      case ConstructorDeclaration():
        final name = member.name?.lexeme ?? owner;
        out.add(
          _declaration(
            locus: locus,
            path: path,
            lines: lines,
            name: name,
            kind: CsDeclarationKind.constructor,
            owner: owner,
            metadata: member.metadata,
            offset: (member.name ?? member.beginToken).offset,
            bodies: [_body(path, lines, name, member.body)],
          ),
        );
      default:
        break;
    }
  }
  return out;
}

CsDeclaration _declaration({
  required CsLocus locus,
  required String path,
  required LineInfo lines,
  required String name,
  required CsDeclarationKind kind,
  required NodeList<Annotation> metadata,
  required int offset,
  String? owner,
  bool hasInitialiser = false,
  String? declaredType,
  List<CsMethodBody> bodies = const [],
  bool isAbstract = false,
  bool isStatic = false,
}) {
  final markers = <CsMarker>[];
  CsCodeSpecLink? codeSpec;
  List<CsDocRef>? docSpec;

  for (final annotation in metadata) {
    final annotationName = annotation.name.name;
    final location = _at(path, lines, annotation.offset);
    if (annotationName == 'CodeSpec') {
      codeSpec = _codeSpecLink(annotation, location);
    } else if (annotationName == 'DocSpec') {
      docSpec = _docRefs(annotation);
    } else if (annotationName.startsWith('Cs') &&
        !_backLinkAnnotations.contains(annotationName)) {
      final (positional, named) = _arguments(annotation.arguments);
      markers.add(CsMarker(annotationName, positional, named, location));
    }
  }

  return CsDeclaration(
    locus: locus,
    name: name,
    kind: kind,
    owner: owner,
    markers: markers,
    codeSpec: codeSpec,
    docSpec: docSpec,
    hasInitialiser: hasInitialiser,
    declaredType: declaredType,
    bodies: bodies,
    isAbstract: isAbstract,
    isStatic: isStatic,
    location: _at(path, lines, offset),
  );
}

CsCodeSpecLink? _codeSpecLink(Annotation annotation, CsLocation location) {
  final (positional, named) = _arguments(annotation.arguments);
  final id = positional.isEmpty ? null : positional.first;
  final source = named['source'];
  return CsCodeSpecLink(
    id is CsStringValue ? id.value : '',
    source is CsListValue
        ? [
            for (final value in source.values)
              if (value is CsStringValue) value.value,
          ]
        : const [],
    location,
  );
}

List<CsDocRef> _docRefs(Annotation annotation) {
  final (positional, _) = _arguments(annotation.arguments);
  final list = positional.isEmpty ? null : positional.first;
  if (list is! CsListValue) return const [];
  final out = <CsDocRef>[];
  for (final value in list.values) {
    if (value is CsConstructionValue && value.type == 'DocRef') {
      final args = value.positional;
      final sectionId = args.isNotEmpty && args[0] is CsStringValue
          ? (args[0] as CsStringValue).value
          : '';
      final description = args.length > 1 && args[1] is CsStringValue
          ? (args[1] as CsStringValue).value
          : '';
      out.add(CsDocRef(sectionId, description));
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Bodies
// ---------------------------------------------------------------------------

List<CsMethodBody> _bodies(
  String path,
  LineInfo lines,
  List<ClassMember> members,
) {
  final out = <CsMethodBody>[];
  for (final member in members) {
    if (member is MethodDeclaration) {
      out.add(_body(path, lines, member.name.lexeme, member.body));
    }
  }
  return out;
}

CsMethodBody _body(
  String path,
  LineInfo lines,
  String name,
  FunctionBody body,
) {
  final location = _at(path, lines, body.offset);
  final isAsync = body.isAsynchronous;
  final calls = _calls(path, lines, body);

  if (body is EmptyFunctionBody) {
    return CsMethodBody(
      name: name,
      shape: CsBodyShape.none,
      location: location,
      isAsync: isAsync,
    );
  }
  if (body is ExpressionFunctionBody) {
    // `String get name => throw UnsupportedError('…');` is the idiomatic getter
    // stub, so an arrow body is only a value-returning body when it is not a
    // throw.
    final expression = body.expression;
    if (expression is ThrowExpression) {
      return _throwBody(name, location, expression, isAsync: isAsync);
    }
    return CsMethodBody(
      name: name,
      shape: CsBodyShape.returnsValue,
      location: location,
      calls: calls,
      isAsync: isAsync,
    );
  }
  if (body is BlockFunctionBody) {
    final statements = body.block.statements;
    if (statements.length == 1 && statements.first is ExpressionStatement) {
      final expression = (statements.first as ExpressionStatement).expression;
      if (expression is ThrowExpression) {
        return _throwBody(name, location, expression, isAsync: isAsync);
      }
    }
    final returnsValue = statements.any(
      (s) => s is ReturnStatement && s.expression != null,
    );
    return CsMethodBody(
      name: name,
      shape: returnsValue ? CsBodyShape.returnsValue : CsBodyShape.other,
      location: location,
      calls: calls,
      isAsync: isAsync,
    );
  }
  return CsMethodBody(
    name: name,
    shape: CsBodyShape.other,
    location: location,
    calls: calls,
    isAsync: isAsync,
  );
}

/// Every method invocation inside [body], in source order.
///
/// Recursive rather than statement-level, because a form-3b call is routinely
/// nested — inside an `await`, a `return`, or an argument list — and a
/// statement-level scan would miss exactly the calls check 23 exists to
/// resolve.
List<CsCall> _calls(String path, LineInfo lines, FunctionBody body) {
  final collector = _CallCollector(path, lines);
  body.accept(collector);
  return collector.calls;
}

class _CallCollector extends RecursiveAstVisitor<void> {
  _CallCollector(this._path, this._lines);

  final String _path;
  final LineInfo _lines;
  final calls = <CsCall>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls.add(
      CsCall(
        receiver: node.target?.toSource(),
        method: node.methodName.name,
        location: _at(_path, _lines, node.offset),
      ),
    );
    super.visitMethodInvocation(node);
  }
}

/// Classifies a body whose whole content is [expression].
///
/// The explication is the thrown construction's first positional argument. An
/// argument-less throw carries a definitely-empty explication (`''`) rather
/// than an unread one (`null`), because §2.4's requirement is that the throw
/// *state* something — `throw UnsupportedError()` states nothing.
CsMethodBody _throwBody(
  String name,
  CsLocation location,
  ThrowExpression expression, {
  required bool isAsync,
}) {
  final thrown = _value(expression.expression);
  if (thrown is! CsConstructionValue) {
    return CsMethodBody(
      name: name,
      shape: CsBodyShape.throwOnly,
      location: location,
      isAsync: isAsync,
    );
  }
  final String? message;
  if (thrown.positional.isEmpty) {
    message = '';
  } else if (thrown.positional.first case final CsStringValue literal) {
    message = literal.value;
  } else {
    message = null;
  }
  return CsMethodBody(
    name: name,
    shape: CsBodyShape.throwOnly,
    location: location,
    thrownType: thrown.type,
    thrownMessage: message,
    isAsync: isAsync,
  );
}

// ---------------------------------------------------------------------------
// Constructions
// ---------------------------------------------------------------------------

List<CsConstruction> _constructions(
  String path,
  LineInfo lines,
  String owner,
  List<ClassMember> members,
) {
  final out = <CsConstruction>[];
  for (final member in members) {
    if (member is! FieldDeclaration) continue;
    for (final variable in member.fields.variables) {
      final construction = _constructionOf(
        path,
        lines,
        '$owner.${variable.name.lexeme}',
        variable.initializer,
      );
      if (construction != null) out.add(construction);
      // A catalogue member is often a list of constructions.
      final initializer = variable.initializer;
      if (initializer is ListLiteral) {
        for (final element in initializer.elements) {
          if (element is Expression) {
            final nested = _constructionOf(
              path,
              lines,
              '$owner.${variable.name.lexeme}',
              element,
            );
            if (nested != null) out.add(nested);
          }
        }
      }
    }
  }
  return out;
}

CsConstruction? _constructionOf(
  String path,
  LineInfo lines,
  String holder,
  Expression? initializer,
) {
  if (initializer == null) return null;
  final value = _value(initializer);
  if (value is! CsConstructionValue) return null;
  return CsConstruction(
    type: value.type,
    positional: value.positional,
    named: value.named,
    holder: holder,
    location: _at(path, lines, initializer.offset),
  );
}

// ---------------------------------------------------------------------------
// Values
// ---------------------------------------------------------------------------

(List<CsValue>, Map<String, CsValue>) _arguments(ArgumentList? arguments) {
  final positional = <CsValue>[];
  final named = <String, CsValue>{};
  if (arguments == null) return (positional, named);
  for (final argument in arguments.arguments) {
    if (argument is NamedExpression) {
      named[argument.name.label.name] = _value(argument.expression);
    } else {
      positional.add(_value(argument));
    }
  }
  return (positional, named);
}

CsValue _value(Expression expression) {
  switch (expression) {
    case SimpleStringLiteral():
      return CsStringValue(expression.value);
    case AdjacentStrings():
      final buffer = StringBuffer();
      for (final part in expression.strings) {
        if (part is SimpleStringLiteral) {
          buffer.write(part.value);
        } else {
          return CsUnknownValue('$expression');
        }
      }
      return CsStringValue(buffer.toString());
    case BooleanLiteral():
      return CsBoolValue(expression.value);
    case IntegerLiteral():
      final value = expression.value;
      return value == null ? CsUnknownValue('$expression') : CsIntValue(value);
    case NullLiteral():
      return const CsNullValue();
    case ListLiteral():
      final values = <CsValue>[];
      for (final element in expression.elements) {
        values.add(
          element is Expression
              ? _value(element)
              : CsUnknownValue('$element'),
        );
      }
      return CsListValue(values);
    case PrefixedIdentifier():
      return CsQualifiedValue(
        expression.prefix.name,
        expression.identifier.name,
      );
    case SimpleIdentifier():
      return CsUnknownValue(expression.name);
    case InstanceCreationExpression():
      final (positional, named) = _arguments(expression.argumentList);
      return CsConstructionValue(
        expression.constructorName.type.name.lexeme,
        positional,
        named,
      );
    case MethodInvocation() when expression.target == null:
      // Unresolved parsing renders `CsOperationRef('x')` as an invocation; the
      // capitalised name is what tells it apart from a real function call.
      final name = expression.methodName.name;
      if (name.isNotEmpty && name[0] == name[0].toUpperCase()) {
        final (positional, named) = _arguments(expression.argumentList);
        return CsConstructionValue(name, positional, named);
      }
      return CsUnknownValue('$expression');
    default:
      return CsUnknownValue('$expression');
  }
}

CsLocation _at(String path, LineInfo lines, int offset) =>
    CsLocation(path, lines.getLocation(offset).lineNumber);

// ---------------------------------------------------------------------------
// Enum mirrors
// ---------------------------------------------------------------------------

/// Reads the value names of [enumName] from [source], in declaration order.
///
/// Returns `null` when the source declares no such enum — which the mirror
/// check reports rather than treating as an empty catalogue.
List<String>? readEnumValues(String source, String enumName) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  for (final declaration in unit.declarations) {
    if (declaration is EnumDeclaration &&
        declaration.namePart.typeName.lexeme == enumName) {
      return [for (final c in declaration.body.constants) c.name.lexeme];
    }
  }
  return null;
}
