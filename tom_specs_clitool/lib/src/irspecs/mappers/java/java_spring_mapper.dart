/// The Java + Spring Boot server mapper (`irspecs_ir.md` §13): the server of
/// the IR written as one Gradle project — Java 21, Spring Boot 3 with Spring
/// Web, Spring Data JPA entities, Flyway migrations and Jakarta Bean
/// Validation, the HTTP interfaces generated at build time by openapi-generator
/// from the IR's OpenAPI document. Like the Dart + Tom mapper the output is a
/// skeleton: `./gradlew compileJava` compiles it, and it executes nothing — a
/// body the specification gives no steps for throws
/// `UnsupportedOperationException`.
library;

import 'dart:convert';

import '../../../codespecs/cs_model.dart';
import '../../emitters/emit_common.dart';
import '../../emitters/openapi_emitter.dart';
import '../../ir_model.dart';
import '../../ir_steps.dart';
import '../dart_tom/dart_tom_mapper.dart' show IrMapException;
import '../mapper_common.dart';

/// The Java + Spring Boot server's mapper.
const String kJavaSpringServerMapper = 'java-spring-server';

/// The versions the project pins: the Java release, the Gradle the wrapper
/// names, and the Gradle plugins (Spring Boot's dependency management pins
/// every library).
const Map<String, String> kJavaSpringVersions = {
  'java': '21',
  'gradle': '8.14',
  'org.springframework.boot': '3.5.16',
  'io.spring.dependency-management': '1.1.7',
  'org.openapi.generator': '7.17.0',
};

/// The project's files for [share]'s server — `<path>` → text, under the
/// project's directory, which is the server package's name. [all] is the
/// whole IR folder the share was taken from: the project carries the shared
/// locus as its `shared` package, and its OpenAPI document is the whole
/// folder's (`irspecs_ir.md` §10).
Map<String, String> mapJavaSpring(
  List<IrDocument> share, {
  List<IrDocument>? all,
}) {
  final everything = all ?? share;
  final project =
      _packageName(share, CsLocus.server) ??
      _packageName(everything, CsLocus.server);
  if (project == null) return const {};
  final base = javaPackageName(project);
  final server = [
    for (final d in share)
      if (d.area != kIrPackageArea)
        for (final f in d.files)
          if (f.locus == CsLocus.server) (area: d.area, file: f),
  ];
  final shared = [
    for (final d in everything)
      if (d.area != kIrPackageArea)
        for (final f in d.files)
          if (f.locus == CsLocus.shared) (area: d.area, file: f),
  ];
  final symbols = _Symbols(base, [
    for (final s in shared) (package: 'shared', area: s.area, file: s.file),
    for (final s in server) (package: 'server', area: s.area, file: s.file),
  ]);
  final application = '${_pascal(project)}Application';
  if (symbols.byName.containsKey(application)) {
    throw IrMapException(
      'the IR declares $application, the name of the Spring Boot application '
      'class',
    );
  }

  final out = <String, String>{};
  final javaRoot = 'src/main/java/${base.replaceAll('.', '/')}';
  for (final (package, files) in [('shared', shared), ('server', server)]) {
    for (final f in files) {
      final writer = _FileWriter(
        file: f.file,
        area: f.area,
        package: '$base.$package',
        base: base,
        symbols: symbols,
      );
      for (final MapEntry(key: name, value: text) in writer.render().entries) {
        out['$project/$javaRoot/$package/$name.java'] = text;
      }
    }
  }
  for (final MapEntry(key: name, value: text) in _codeSpecPackage(
    base,
  ).entries) {
    out['$project/$javaRoot/codespec/$name.java'] = text;
  }
  out['$project/$javaRoot/$application.java'] = _application(base, application);

  final openApiText = emitOpenApi(everything).files[kOpenApiFile]!;
  final openApi = jsonDecode(openApiText) as Map<String, dynamic>;
  out['$project/src/main/resources/openapi/openapi.json'] = openApiText;
  final controllers = _controllers(openApi, server, symbols, base);
  for (final MapEntry(key: name, value: text) in controllers.entries) {
    out['$project/$javaRoot/server/$name.java'] = text;
  }
  if (controllers.isNotEmpty) {
    out['$project/$javaRoot/server/TransportErrors.java'] = _transportErrors(
      base,
    );
  }

  final tables = _tables(server, symbols);
  if (tables.isNotEmpty) {
    out['$project/src/main/resources/db/migration/V1__ce_db_tables.sql'] =
        _migration(tables);
  }

  out['$project/settings.gradle.kts'] =
      '// $_generated\n\nrootProject.name = ${jsonEncode(project)}\n';
  out['$project/build.gradle.kts'] = _buildGradle(
    base,
    _schemaMappings(openApi, symbols),
  );
  out['$project/gradle/wrapper/gradle-wrapper.properties'] = [
    '# $_generated',
    '#',
    '# The Gradle the wrapper runs. `gradle wrapper` (any Gradle) writes the',
    '# wrapper scripts and jar beside it (irspecs_ir.md §13).',
    'distributionBase=GRADLE_USER_HOME',
    'distributionPath=wrapper/dists',
    'distributionUrl=https\\://services.gradle.org/distributions/'
        'gradle-${kJavaSpringVersions['gradle']}-all.zip',
    'zipStoreBase=GRADLE_USER_HOME',
    'zipStorePath=wrapper/dists',
    '',
  ].join('\n');
  return out;
}

const String _generated =
    'Generated by TomSpecs Phase 4 (CodeSpecs, mapper java-spring-server) — '
    'do not edit.';

String? _packageName(List<IrDocument> documents, CsLocus locus) {
  for (final d in documents) {
    for (final p in d.projects) {
      if (p.locus == locus) return p.packageName;
    }
  }
  return null;
}

/// Java's reserved words: no package segment, parameter or field may be one.
const Set<String> _javaReserved = {
  'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', //
  'class', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum',
  'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements',
  'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new',
  'package', 'private', 'protected', 'public', 'return', 'short', 'static',
  'strictfp', 'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
  'transient', 'try', 'void', 'volatile', 'while', 'true', 'false', 'null',
  'var', 'record', 'yield', 'sealed', 'permits',
};

/// The Java package of a package name: lower case, every other character an
/// underscore, a reserved word or a leading digit prefixed with `_`.
String javaPackageName(String name) {
  var p = name.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '_');
  if (p.isEmpty || RegExp('^[0-9]').hasMatch(p) || _javaReserved.contains(p)) {
    p = '_$p';
  }
  return p;
}

String _local(String name) => _javaReserved.contains(name) ? '${name}_' : name;

String _pascal(String s) => [
  for (final part in s.split(RegExp('[^A-Za-z0-9]+')))
    if (part.isNotEmpty) '${part[0].toUpperCase()}${part.substring(1)}',
].join();

String _capitalised(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// A Java string literal: JSON's escapes are Java's.
String _string(String s) => jsonEncode(s);

// ---------------------------------------------------------------------------
// Symbols
// ---------------------------------------------------------------------------

class _Symbol {
  final String package;
  final IrShape shape;
  final bool isEnum;
  const _Symbol(this.package, this.shape, {required this.isEnum});
}

class _Symbols {
  final String base;
  final Map<String, _Symbol> byName = {};

  /// `Collaborator.method` → its body, for the steps' calls.
  final Map<String, CsMethodBody> methods = {};

  _Symbols(
    this.base,
    List<({String package, String area, IrFile file})> files,
  ) {
    for (final f in files) {
      final index = irFileIndex(f.area, f.file);
      for (final e in index.topLevel) {
        final shape = _declarationShape(index, e);
        final name = e.declaration.name;
        final previous = byName[name];
        if (previous != null) {
          throw IrMapException(
            '${f.file.file.path}: $name is declared twice in the shared and '
            'server loci; one Java import cannot name both',
          );
        }
        byName[name] = _Symbol(
          '$base.${f.package}',
          shape,
          isEnum: e.declaration.kind == CsDeclarationKind.enumType,
        );
        for (final m in index.membersOf(e)) {
          for (final b in m.bodies) {
            if (b.name == m.name) methods['$name.${m.name}'] = b;
          }
        }
      }
    }
  }
}

/// The shape of [e] as the Java server mapper writes it: a layout is the
/// client's, a top-level variable has no class to live in.
IrShape _declarationShape(IrIndex index, IrEntry e) {
  final shape = irDeclarationShape(index, e, mapper: 'Java mapper');
  if (shape == IrShape.layout) {
    throw IrMapException(
      '${e.file.file.path}: ${e.declaration.name} is a layout; the Java '
      'server mapper writes no client',
    );
  }
  if (shape == IrShape.variable) {
    throw IrMapException(
      '${e.file.file.path}: the top-level variable ${e.declaration.name} has '
      'no Java class to live in',
    );
  }
  return shape;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// The Java form of a Dart type, as written in [package]; [imports] collects
/// the classes it needs. Types follow `irspecs_ir.md` §10.1's JSON Schema
/// mapping, so the wire types and the schemas agree; numbers and booleans are
/// boxed, so a `required` rule can see a missing value.
class _Types {
  final _Symbols symbols;
  final String package;
  final Set<String> typeParameters;
  final Set<String> imports;

  _Types(this.symbols, this.package, this.typeParameters, this.imports);

  String of(String dart) {
    var t = dart.trim();
    if (t.endsWith('?')) t = t.substring(0, t.length - 1);
    final generic = RegExp(r'^(\w+)<(.*)>$').firstMatch(t);
    if (generic != null) {
      final base = generic.group(1)!;
      final args = irSplitTypeArguments(generic.group(2)!);
      switch (base) {
        case 'List' || 'Iterable' || 'Set':
          imports.add('java.util.List');
          return 'List<${of(args.single)}>';
        case 'Map':
          imports.add('java.util.Map');
          return 'Map<${of(args[0])}, ${of(args[1])}>';
        case 'Future' || 'FutureOr':
          throw IrMapException('`$t` is a Future outside a method result');
        case 'TomRepository':
          imports.add('org.springframework.data.jpa.repository.JpaRepository');
          return 'JpaRepository<${args.map(of).join(', ')}>';
      }
      return '${_named(base)}<${args.map(of).join(', ')}>';
    }
    switch (t) {
      case 'String' || 'Uri' || 'Duration':
        return 'String';
      case 'DateTime':
        imports.add('java.time.OffsetDateTime');
        return 'OffsetDateTime';
      case 'int':
        return 'Integer';
      case 'double' || 'num':
        return 'Double';
      case 'bool':
        return 'Boolean';
      case 'Object' || 'dynamic':
        return 'Object';
    }
    if (typeParameters.contains(t)) return t;
    if (t.startsWith('Cs') &&
        (t.endsWith('Ref') || t.endsWith('Key') || t.endsWith('Code'))) {
      return 'String';
    }
    return _named(t);
  }

  String _named(String name) {
    final s = symbols.byName[name];
    if (s == null) throw IrMapException('the type `$name` has no Java form');
    if (s.package != package) imports.add('${s.package}.$name');
    return name;
  }

  /// A method's result: `Future<X>` and `X` → `X`; `void` and
  /// `Future<void>` → `void`.
  String resultOf(String? dart) {
    var t = (dart ?? 'void').trim();
    final future = RegExp(r'^(?:Future|FutureOr)<(.*)>$').firstMatch(t);
    if (future != null) t = future.group(1)!.trim();
    if (t == 'void' || t == 'Future') return 'void';
    return of(t);
  }
}

// ---------------------------------------------------------------------------
// One Dart file: a Java file per top-level declaration
// ---------------------------------------------------------------------------

class _FileWriter {
  final IrFile file;
  final String area;
  final String package;
  final String base;
  final _Symbols symbols;

  _FileWriter({
    required this.file,
    required this.area,
    required this.package,
    required this.base,
    required this.symbols,
  });

  late final IrIndex _index = irFileIndex(area, file);

  /// `<class name>` → the Java file's text.
  Map<String, String> render() => {
    for (final e in _index.topLevel) e.declaration.name: _render(e),
  };

  String _render(IrEntry e) {
    final imports = <String>{};
    final body = _declaration(e, imports);
    final banner = [
      '// $_generated',
      for (final c in file.file.comments)
        if (c.isBanner && !c.text.contains('GENERATED')) c.text,
    ];
    final sorted = imports.where((i) => !_samePackage(i)).toList()..sort();
    final java = sorted.where((i) => i.startsWith('java.')).toList();
    final others = sorted.where((i) => !i.startsWith('java.')).toList();
    return [
      ...banner,
      '',
      'package $package;',
      if (java.isNotEmpty) ...['', for (final i in java) 'import $i;'],
      if (others.isNotEmpty) ...['', for (final i in others) 'import $i;'],
      '',
      ...body,
      '',
    ].join('\n');
  }

  bool _samePackage(String import) =>
      import.substring(0, import.lastIndexOf('.')) == package;

  List<String> _declaration(IrEntry e, Set<String> imports) {
    final d = e.declaration;
    final members = _index.membersOf(e);
    final where = '${file.file.path}: ${d.name}';
    final typeParameters = irTypeParameterNames(d.typeParameters, where);
    final types = _Types(symbols, package, typeParameters, imports);
    final generics = typeParameters.isEmpty
        ? ''
        : '<${typeParameters.join(', ')}>';
    switch (_declarationShape(_index, e)) {
      case IrShape.catalogue:
        return _catalogue(d, members, imports);
      case IrShape.plainData:
        return _record(d, members, types, imports, generics);
      case IrShape.entity:
        return _entity(d, members, types, imports);
      case IrShape.contract:
        final extendsClause = d.superclass == null
            ? ''
            : ' extends ${types.of(d.superclass!)}';
        return [
          ..._doc(d, '', imports),
          'public interface ${d.name}$generics$extendsClause {',
          for (final (i, (m, b)) in _methods(members).indexed) ...[
            if (i > 0) '',
            ..._doc(m, '    ', imports),
            '    ${types.resultOf(b.returnType)} ${m.name}'
                '(${_parameters(b, types)});',
          ],
          '}',
        ];
      case IrShape.serviceUnit:
        if (members.any((m) => m.kind == CsDeclarationKind.field)) {
          throw IrMapException(
            '$where: a service unit with fields has no Java rule',
          );
        }
        imports.add('org.springframework.stereotype.Service');
        return [
          ..._doc(d, '', imports),
          '@Service',
          'public class ${d.name} {',
          for (final (i, (m, b)) in _methods(members).indexed) ...[
            if (i > 0) '',
            ..._doc(m, '    ', imports),
            '    public ${types.resultOf(b.returnType)} ${m.name}'
                '(${_parameters(b, types)}) {',
            '        ${_unsupported(b, m)}',
            '    }',
          ],
          '}',
        ];
      case IrShape.classType:
        return _classType(e, d, members, types, imports, generics);
      case IrShape.layout || IrShape.variable:
        throw StateError('refused by _declarationShape');
    }
  }

  List<(CsDeclaration, CsMethodBody)> _methods(List<CsDeclaration> members) => [
    for (final m in members)
      if (m.kind == CsDeclarationKind.method)
        if (m.bodies.where((b) => b.name == m.name).firstOrNull case final b?)
          (m, b),
  ];

  String _parameters(CsMethodBody b, _Types types) => [
    for (final p in b.parameters)
      '${types.of(p.type ?? 'Object')} ${_local(p.name)}',
  ].join(', ');

  String _unsupported(CsMethodBody b, CsDeclaration m) =>
      'throw new UnsupportedOperationException('
      '${_string(b.thrownMessage ?? b.thrownLiteral ?? m.name)});';

  List<String> _catalogue(
    CsDeclaration d,
    List<CsDeclaration> members,
    Set<String> imports,
  ) {
    if (d.kind == CsDeclarationKind.enumType) {
      final values = [
        for (final m in members)
          if (m.kind == CsDeclarationKind.field) m,
      ];
      return [
        ..._doc(d, '', imports),
        'public enum ${d.name} {',
        for (final (i, m) in values.indexed) ...[
          if (i > 0) '',
          ..._doc(m, '    ', imports),
          '    ${m.name}${i < values.length - 1 ? ',' : ''}',
        ],
        '}',
      ];
    }
    return [
      ..._doc(d, '', imports),
      'public final class ${d.name} {',
      '    private ${d.name}() {}',
      for (final m in members) ...[
        '',
        ..._doc(m, '    ', imports),
        '    public static final String ${m.name} = '
            '${_string(irInitialiserString(m)!)};',
      ],
      '}',
    ];
  }

  void _plainField(CsDeclaration owner, CsDeclaration m) {
    if (m.isStatic ||
        m.hasInitialiser ||
        file.file.constructions.any(
          (c) => c.holder == '${owner.name}.${m.name}',
        )) {
      throw IrMapException(
        '${file.file.path}: ${owner.name}.${m.name} is static or initialised, '
        'which the Java mapper has no rule for in a data class',
      );
    }
  }

  /// A plain data class as a record: a component per field, its
  /// `@CsValidation` rules as Bean Validation constraints, its doc as the
  /// record's `@param`.
  List<String> _record(
    CsDeclaration d,
    List<CsDeclaration> members,
    _Types types,
    Set<String> imports,
    String generics,
  ) {
    final fields = [
      for (final m in members)
        if (m.kind == CsDeclarationKind.field) m,
    ];
    final params = <String>[
      for (final m in fields)
        if ([
              ?irDocText(m)?.replaceAll('\n', ' '),
              for (final k in m.markers) 'Cs: ${irMarkerSource(k)}',
            ]
            case final parts when parts.isNotEmpty)
          '@param ${m.name} ${parts.join(' ')}',
    ];
    final components = <String>[];
    for (final (i, m) in fields.indexed) {
      _plainField(d, m);
      final annotations = [
        ..._backLinks(m, '        ', imports),
        for (final c in _constraints(m, imports)) '        $c',
      ];
      components.addAll([
        ...annotations,
        '        ${types.of(m.declaredType ?? 'Object')} ${_local(m.name)}'
            '${i < fields.length - 1 ? ',' : ''}',
      ]);
    }
    return [
      ..._doc(d, '', imports, extra: params),
      'public record ${d.name}$generics(',
      ...components,
      ') {}',
    ];
  }

  /// The Bean Validation constraints of [m]'s `@CsValidation` rules
  /// (`codespecs_mapping.md` §5.19).
  List<String> _constraints(CsDeclaration m, Set<String> imports) {
    final rules = irString(irMarker(m, 'CsValidation')?.named['rules']);
    if (rules == null || rules.trim().isEmpty) return const [];
    final out = <String>[];
    String? sizeMin;
    String? sizeMax;
    void use(String c) => imports.add('jakarta.validation.constraints.$c');
    for (final raw in rules.split(',')) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      final colon = token.indexOf(':');
      final name = colon < 0 ? token : token.substring(0, colon);
      final arg = colon < 0 ? null : token.substring(colon + 1).trim();
      String number() {
        final n = num.tryParse(arg ?? '');
        if (n == null) {
          throw IrMapException(
            '${file.file.path}: ${m.name}: the rule `$token` has no number',
          );
        }
        return arg!;
      }

      switch (name) {
        case 'required':
          use('NotNull');
          out.add('@NotNull');
        case 'email':
          use('Email');
          out.add('@Email');
        case 'pattern':
          use('Pattern');
          out.add('@Pattern(regexp = ${_string(arg ?? '')})');
        case 'minLength' || 'minItems':
          sizeMin = '${int.parse(number())}';
        case 'maxLength' || 'maxItems':
          sizeMax = '${int.parse(number())}';
        case 'min' || 'max':
          final n = number();
          final isInt = int.tryParse(n) != null;
          final c = isInt
              ? (name == 'min' ? 'Min' : 'Max')
              : (name == 'min' ? 'DecimalMin' : 'DecimalMax');
          use(c);
          out.add(isInt ? '@$c($n)' : '@$c(${_string(n)})');
        default:
          throw IrMapException(
            '${file.file.path}: ${m.name}: the validator `$token` has no Bean '
            'Validation constraint',
          );
      }
    }
    if (sizeMin != null || sizeMax != null) {
      use('Size');
      out.add(
        '@Size(${[if (sizeMin != null) 'min = $sizeMin', if (sizeMax != null) 'max = $sizeMax'].join(', ')})',
      );
    }
    return out;
  }

  List<String> _entity(
    CsDeclaration d,
    List<CsDeclaration> members,
    _Types types,
    Set<String> imports,
  ) {
    imports
      ..add('jakarta.persistence.Column')
      ..add('jakarta.persistence.Entity')
      ..add('jakarta.persistence.Table');
    final table =
        irString(irMarker(d, 'CsTable')?.positional.firstOrNull) ??
        irSnake(d.name);
    final fields = [
      for (final m in members)
        if (m.kind == CsDeclarationKind.field) m,
    ];
    final out = [
      ..._doc(d, '', imports),
      '@Entity',
      '@Table(name = ${_string(table)})',
      'public class ${d.name} {',
    ];
    for (final (i, m) in fields.indexed) {
      _plainField(d, m);
      final dart = (m.declaredType ?? 'String').trim();
      final type = types.of(dart);
      final col = irMarker(m, 'CsColumn');
      final column = irString(col?.named['column']) ?? irSnake(m.name);
      final sqlType = irString(col?.named['columnType']);
      final enumType =
          symbols.byName[dart.replaceAll('?', '')]?.isEnum ?? false;
      if (enumType) {
        imports
          ..add('jakarta.persistence.EnumType')
          ..add('jakarta.persistence.Enumerated');
      }
      if (i > 0) out.add('');
      out.addAll([
        ..._doc(m, '    ', imports),
        if (enumType) '    @Enumerated(EnumType.STRING)',
        '    @Column(${['name = ${_string(column)}', if (sqlType != null) 'columnDefinition = ${_string(sqlType)}', if (!dart.endsWith('?')) 'nullable = false'].join(', ')})',
        '    private $type ${_local(m.name)};',
      ]);
    }
    for (final m in fields) {
      final type = types.of(m.declaredType ?? 'String');
      final name = _local(m.name);
      out.addAll([
        '',
        '    public $type get${_capitalised(m.name)}() {',
        '        return $name;',
        '    }',
        '',
        '    public void set${_capitalised(m.name)}($type $name) {',
        '        this.$name = $name;',
        '    }',
      ]);
    }
    out.add('}');
    return out;
  }

  List<String> _classType(
    IrEntry e,
    CsDeclaration d,
    List<CsDeclaration> members,
    _Types types,
    Set<String> imports,
    String generics,
  ) {
    final fields = [
      for (final m in members)
        if (m.kind == CsDeclarationKind.field) m,
    ];
    for (final m in fields) {
      _plainField(d, m);
    }
    final out = [
      ..._doc(d, '', imports),
      'public ${d.isAbstract ? 'abstract ' : ''}class ${d.name}$generics {',
    ];
    for (final (i, m) in fields.indexed) {
      if (i > 0) out.add('');
      out.addAll([
        ..._doc(m, '    ', imports),
        '    private ${m.isFinal ? 'final ' : ''}'
            '${types.of(m.declaredType ?? 'Object')} ${_local(m.name)};',
      ]);
    }
    if (fields.isNotEmpty) {
      out.addAll([
        '',
        '    public ${d.name}(${[for (final m in fields) '${types.of(m.declaredType ?? 'Object')} ${_local(m.name)}'].join(', ')}) {',
        for (final m in fields)
          '        this.${_local(m.name)} = ${_local(m.name)};',
        '    }',
      ]);
    }
    for (final (m, b) in _methods(members)) {
      final record = file.steps
          .where((r) => r.owner == d.name && r.body == m.name)
          .firstOrNull;
      final result = types.resultOf(b.returnType);
      final List<String> body;
      if (record?.steps case final steps?) {
        final collaborator = fields
            .where((f) => f.name == 'collaborator')
            .firstOrNull
            ?.declaredType;
        if (collaborator == null) {
          throw IrMapException(
            '${file.file.path}: ${d.name}.${m.name} has steps but its class no '
            '`collaborator` field',
          );
        }
        body = _StepWriter(
          collaborator: collaborator.replaceAll('?', ''),
          symbols: symbols,
          isVoid: result == 'void',
        ).write(steps, '        ');
      } else {
        body = ['        ${_unsupported(b, m)}'];
      }
      out.addAll([
        '',
        ..._doc(m, '    ', imports),
        '    public $result ${m.name}(${_parameters(b, types)}) {',
        ...body,
        '    }',
      ]);
    }
    out.add('}');
    return out;
  }

  /// The Javadoc of [d] — its Dart doc text, its markers and other
  /// annotations as text, [extra] lines (`@param`) — and its back-link
  /// annotations.
  List<String> _doc(
    CsDeclaration d,
    String indent,
    Set<String> imports, {
    List<String> extra = const [],
  }) {
    final lines = <String>[
      for (final l in d.docComment?.lines ?? const <String>[])
        _javadocText(l.trimLeft().replaceFirst(RegExp(r'^/// ?'), '').trim()),
    ];
    final notes = <String>[
      for (final m in d.markers) 'Cs: ${_javadocText(irMarkerSource(m))}',
      for (final a in d.annotations) 'Dart: ${_javadocText(a.source)}',
    ];
    final params = [for (final p in extra) _javadocParam(p)];
    final all = <String>[
      ...lines,
      if (lines.isNotEmpty && notes.isNotEmpty) '',
      for (final (i, n) in notes.indexed) i < notes.length - 1 ? '$n<br>' : n,
      if ((lines.isNotEmpty || notes.isNotEmpty) && params.isNotEmpty) '',
      ...params,
    ];
    return [
      if (all.isNotEmpty) ...[
        '$indent/**',
        for (final l in all) l.isEmpty ? '$indent *' : '$indent * $l',
        '$indent */',
      ],
      ..._backLinks(d, indent, imports),
    ];
  }

  String _javadocParam(String p) {
    final space = p.indexOf(' ', '@param '.length);
    return '${p.substring(0, space + 1)}${_javadocText(p.substring(space + 1))}';
  }

  /// Text as Javadoc reads it literally: HTML's special characters escaped, a
  /// leading `@` not a tag, `*/` not the comment's end.
  String _javadocText(String s) {
    var t = s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('*/', '*&#47;');
    if (t.startsWith('@')) t = '{@literal @}${t.substring(1)}';
    return t;
  }

  /// `@CodeSpec(…)` and `@DocSpec({…})` with the Dart trio's section ids
  /// (`irspecs_ir.md` §13).
  List<String> _backLinks(CsDeclaration d, String indent, Set<String> imports) {
    final out = <String>[];
    if (d.codeSpec case final cs?) {
      imports.add('$base.codespec.CodeSpec');
      out.add(
        '$indent@CodeSpec(${[if (cs.id.isNotEmpty) 'id = ${_string(cs.id)}', if (cs.source.isNotEmpty) 'source = {${cs.source.map(_string).join(', ')}}'].join(', ')})',
      );
    }
    final refs = d.docSpec ?? const <CsDocRef>[];
    if (refs.isNotEmpty) {
      imports
        ..add('$base.codespec.DocRef')
        ..add('$base.codespec.DocSpec');
      out.addAll([
        '$indent@DocSpec({',
        for (final r in refs)
          '$indent    @DocRef(sectionId = ${_string(r.sectionId)}, '
              'description = ${_string(r.description)}),',
        '$indent})',
      ]);
    }
    return out;
  }
}

/// A 3b body from its steps (`irspecs_ir.md` §4.7).
class _StepWriter {
  final String collaborator;
  final _Symbols symbols;
  final bool isVoid;

  _StepWriter({
    required this.collaborator,
    required this.symbols,
    required this.isVoid,
  });

  bool _returnsValue(String method) {
    final b = symbols.methods['$collaborator.$method'];
    if (b == null) {
      throw IrMapException(
        'the step calls $collaborator.$method, which the collaborator does '
        'not declare',
      );
    }
    final t = (b.returnType ?? 'void').replaceAll(' ', '');
    return !(t == 'void' || t == 'Future<void>' || t == 'Future');
  }

  String _call(String method, List<String> args) =>
      'collaborator.$method(${args.map(_local).join(', ')})';

  List<String> write(List<IrStep> steps, String indent) => [
    for (final s in steps)
      ...switch (s) {
        IrCallStep(:final method, :final arguments) => [
          '$indent${_call(method, arguments)};',
        ],
        IrReturnStep(:final method, :final arguments) => [
          if (method == null)
            '${indent}return${isVoid ? '' : ' null'};'
          else if (isVoid || !_returnsValue(method)) ...[
            '$indent${_call(method, arguments)};',
            '${indent}return;',
          ] else
            '${indent}return ${_call(method, arguments)};',
        ],
        IrGuardedStep(:final guard, :final arguments, :final steps) => [
          '${indent}if (${_call(guard, arguments)}) {',
          ...write(steps, '$indent    '),
          '$indent}',
        ],
      },
  ];
}

// ---------------------------------------------------------------------------
// The project's other sources
// ---------------------------------------------------------------------------

Map<String, String> _codeSpecPackage(String base) {
  String annotation(String name, String doc, List<String> body) => [
    '// $_generated',
    '',
    'package $base.codespec;',
    '',
    'import java.lang.annotation.ElementType;',
    'import java.lang.annotation.Retention;',
    'import java.lang.annotation.RetentionPolicy;',
    'import java.lang.annotation.Target;',
    '',
    '/** $doc */',
    '@Retention(RetentionPolicy.RUNTIME)',
    '@Target({ElementType.TYPE, ElementType.FIELD, ElementType.METHOD, '
        'ElementType.RECORD_COMPONENT, ElementType.PARAMETER})',
    'public @interface $name {',
    ...body,
    '}',
    '',
  ].join('\n');
  return {
    'CodeSpec': annotation(
      'CodeSpec',
      'The CodeSpec a declaration realises: its id and the section ids it was '
          'written from (irspecs_ir.md §13).',
      [
        '    /** The CodeSpec id, e.g. {@code serviceUnit.OrderService}. */',
        '    String id() default "";',
        '',
        '    /** The section ids it was written from. */',
        '    String[] source() default {};',
      ],
    ),
    'DocSpec': annotation(
      'DocSpec',
      'The specification sections a declaration traces back to.',
      ['    /** One reference per section. */', '    DocRef[] value();'],
    ),
    'DocRef': [
      '// $_generated',
      '',
      'package $base.codespec;',
      '',
      'import java.lang.annotation.Retention;',
      'import java.lang.annotation.RetentionPolicy;',
      'import java.lang.annotation.Target;',
      '',
      '/** One section a declaration traces back to, and what it supplies. */',
      '@Retention(RetentionPolicy.RUNTIME)',
      '@Target({})',
      'public @interface DocRef {',
      '    /** The section id. */',
      '    String sectionId();',
      '',
      '    /** What the section supplies. */',
      '    String description();',
      '}',
      '',
    ].join('\n'),
  };
}

String _application(String base, String name) => [
  '// $_generated',
  '',
  'package $base;',
  '',
  'import org.springframework.boot.SpringApplication;',
  'import org.springframework.boot.autoconfigure.SpringBootApplication;',
  '',
  '/** The Spring Boot application of the server. */',
  '@SpringBootApplication',
  'public class $name {',
  '    public static void main(String[] args) {',
  '        SpringApplication.run($name.class, args);',
  '    }',
  '}',
  '',
].join('\n');

String _transportErrors(String base) => [
  '// $_generated',
  '',
  'package $base.server;',
  '',
  'import org.springframework.http.ResponseEntity;',
  'import org.springframework.http.converter.HttpMessageNotReadableException;',
  'import org.springframework.web.bind.MethodArgumentNotValidException;',
  'import org.springframework.web.bind.annotation.ExceptionHandler;',
  'import org.springframework.web.bind.annotation.RestControllerAdvice;',
  '',
  '/**',
  ' * Only a 5xx status is a transport error (codespecs_mapping.md §7): a',
  ' * request that does not read, or fails its Bean Validation constraints, is',
  ' * answered with a 500 until Phase 6 answers it with the Result envelope\'s',
  ' * error arm. A handler\'s UnsupportedOperationException is a 500 already.',
  ' */',
  '@RestControllerAdvice',
  'public class TransportErrors {',
  '    @ExceptionHandler({MethodArgumentNotValidException.class, '
      'HttpMessageNotReadableException.class})',
  '    public ResponseEntity<Void> unreadableOrInvalid(Exception e) {',
  '        return ResponseEntity.internalServerError().build();',
  '    }',
  '}',
  '',
].join('\n');

/// One controller per service unit with handlers: it implements the
/// interface openapi-generator writes for each of its operations and hands
/// the request to the service unit.
Map<String, String> _controllers(
  Map<String, dynamic> openApi,
  List<({String area, IrFile file})> server,
  _Symbols symbols,
  String base,
) {
  final handlers = <String, ({String owner, CsMethodBody body})>{};
  for (final f in server) {
    final index = irFileIndex(f.area, f.file);
    for (final e in index.topLevel) {
      if (irMarker(e.declaration, 'CsServiceUnit') == null) continue;
      for (final m in index.membersOf(e)) {
        final op = irString(irMarker(m, 'CsEndpoint')?.positional.firstOrNull);
        final b = m.bodies.where((b) => b.name == m.name).firstOrNull;
        if (op != null && b != null) {
          handlers[op] = (owner: e.declaration.name, body: b);
        }
      }
    }
  }
  final byOwner = <String, List<(IrOpenApiOperation, CsMethodBody)>>{};
  for (final o in openApiOperations(openApi)) {
    final h = handlers[o.op];
    if (h == null) continue;
    byOwner.putIfAbsent(h.owner, () => []).add((o, h.body));
  }
  final out = <String, String>{};
  for (final MapEntry(key: owner, value: ops) in byOwner.entries) {
    final imports = <String>{
      'org.springframework.http.ResponseEntity',
      'org.springframework.web.bind.annotation.RestController',
    };
    final types = _Types(symbols, '$base.server', const {}, imports);
    final field = '${owner[0].toLowerCase()}${owner.substring(1)}';
    final interfaces = <String>[];
    final methods = <String>[];
    for (final (o, b) in ops) {
      final api = '${_pascal(o.path)}Api';
      imports.add('$base.api.$api');
      interfaces.add(api);
      if (b.parameters.length > 1) {
        throw IrMapException(
          '$owner.${o.op}: a handler takes at most its request',
        );
      }
      final params = [
        for (final p in b.parameters)
          '${types.of(p.type ?? 'Object')} ${_local(p.name)}',
      ];
      final args = [for (final p in b.parameters) _local(p.name)];
      final result = types.resultOf(b.returnType);
      final call = '$field.${o.op}(${args.join(', ')})';
      final List<String> body;
      final String answer;
      if (o.enveloped) {
        answer = '${_capitalised(o.op)}200Response';
        imports.add('$base.api.model.$answer');
        body = [
          '        $result result = $call;',
          '        return ResponseEntity.ok(new $answer()',
          '                .success(result.success())',
          '                .value(result.value())',
          '                .error(result.error()));',
        ];
      } else if (result == 'void') {
        answer = 'Void';
        body = [
          '        $call;',
          '        return ResponseEntity.ok().build();',
        ];
      } else {
        answer = result;
        body = ['        return ResponseEntity.ok($call);'];
      }
      methods.addAll([
        '',
        '    /** {@code POST ${o.path}}: hands the request to {@link $owner}. */',
        '    @Override',
        '    public ResponseEntity<$answer> ${o.op}(${params.join(', ')}) {',
        ...body,
        '    }',
      ]);
    }
    final sorted = imports.toList()..sort();
    out['${owner}Controller'] = [
      '// $_generated',
      '',
      'package $base.server;',
      '',
      for (final i in sorted) 'import $i;',
      '',
      '/**',
      ' * The operations of {@link $owner} over HTTP: every one a {@code POST} of its',
      ' * request, its answer the Result envelope (codespecs_mapping.md §7). The',
      ' * interfaces are generated by openapi-generator from',
      ' * {@code src/main/resources/openapi/openapi.json}.',
      ' */',
      '@RestController',
      'public class ${owner}Controller implements ${interfaces.join(', ')} {',
      '    private final $owner $field;',
      '',
      '    public ${owner}Controller($owner $field) {',
      '        this.$field = $field;',
      '    }',
      ...methods,
      '}',
      '',
    ].join('\n');
  }
  return out;
}

/// The component schemas openapi-generator is to take from the project
/// rather than generate: every wire type, enum and entity the mapper writes.
Map<String, String> _schemaMappings(
  Map<String, dynamic> openApi,
  _Symbols symbols,
) {
  final schemas =
      (openApi['components'] as Map<String, dynamic>?)?['schemas']
          as Map<String, dynamic>? ??
      const {};
  return {
    for (final name in schemas.keys)
      if (symbols.byName[name] case final s?)
        if (s.shape != IrShape.catalogue || s.isEnum)
          name: '${s.package}.$name',
  };
}

String _buildGradle(String base, Map<String, String> schemaMappings) {
  final v = kJavaSpringVersions;
  String kv(Map<String, String> m, String indent) => [
    for (final MapEntry(:key, :value) in m.entries)
      '$indent${_string(key)} to ${_string(value)},',
  ].join('\n');
  return '''
// $_generated

plugins {
    java
    id("org.springframework.boot") version "${v['org.springframework.boot']}"
    id("io.spring.dependency-management") version "${v['io.spring.dependency-management']}"
    id("org.openapi.generator") version "${v['org.openapi.generator']}"
}

group = "$base"
version = "0.0.0"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(${v['java']})
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")
}

// The HTTP interfaces, from the IR's OpenAPI document (irspecs_ir.md §10, §13):
// one interface per operation; every component schema the project declares is
// taken from the project, so only the per-operation Result envelopes are
// generated models.
openApiGenerate {
    generatorName.set("spring")
    inputSpec.set("\$projectDir/src/main/resources/openapi/openapi.json")
    outputDir.set(layout.buildDirectory.dir("generated/openapi").get().asFile.path)
    apiPackage.set("$base.api")
    modelPackage.set("$base.api.model")
    generateApiTests.set(false)
    generateModelTests.set(false)
    generateApiDocumentation.set(false)
    generateModelDocumentation.set(false)
    schemaMappings.set(
        mapOf(
${kv(schemaMappings, '            ')}
        ),
    )
    configOptions.set(
        mapOf(
            "interfaceOnly" to "true",
            "skipDefaultInterface" to "true",
            "useSpringBoot3" to "true",
            "useJakartaEe" to "true",
            "useBeanValidation" to "true",
            "openApiNullable" to "false",
            "documentationProvider" to "none",
            "annotationLibrary" to "none",
        ),
    )
}

sourceSets {
    main {
        java {
            srcDir(layout.buildDirectory.dir("generated/openapi/src/main/java"))
        }
    }
}

tasks.compileJava {
    dependsOn(tasks.openApiGenerate)
}
''';
}

// ---------------------------------------------------------------------------
// Flyway: the CE-DB tables as the first migration
// ---------------------------------------------------------------------------

class _Table {
  final String table;
  final List<(String, String, bool)> columns;
  const _Table(this.table, this.columns);
}

List<_Table> _tables(
  List<({String area, IrFile file})> server,
  _Symbols symbols,
) {
  final out = <_Table>[];
  for (final f in server) {
    final index = irFileIndex(f.area, f.file);
    for (final e in index.topLevel) {
      final d = e.declaration;
      final cs = irMarker(d, 'CsTable');
      if (cs == null) continue;
      out.add(
        _Table(irString(cs.positional.firstOrNull) ?? irSnake(d.name), [
          for (final m in index.membersOf(e))
            if (m.kind == CsDeclarationKind.field && !m.isStatic)
              (
                irString(irMarker(m, 'CsColumn')?.named['column']) ??
                    irSnake(m.name),
                irString(irMarker(m, 'CsColumn')?.named['columnType']) ??
                    _sqlType(
                      (m.declaredType ?? 'String').replaceAll('?', ''),
                      symbols,
                    ),
                (m.declaredType ?? '').trim().endsWith('?'),
              ),
        ]),
      );
    }
  }
  return out;
}

String _sqlType(String dart, _Symbols symbols) => switch (dart.trim()) {
  'int' => 'integer',
  'double' || 'num' => 'double precision',
  'bool' => 'boolean',
  'DateTime' => 'timestamptz',
  'String' => 'text',
  final t when symbols.byName[t]?.isEnum ?? false => 'text',
  final t => throw IrMapException('the column type `$t` has no SQL type'),
};

String _migration(List<_Table> tables) => [
  '-- $_generated',
  '--',
  '-- The CE-DB tables, one CREATE TABLE each: the schema the cumulative CE-MG',
  '-- migrations converge on (codespecs_derivation_contract.md §6, check 13),',
  '-- as Flyway\'s first migration.',
  for (final t in tables) ...[
    '',
    'CREATE TABLE ${t.table} (',
    for (final (i, (name, type, nullable)) in t.columns.indexed)
      '  $name $type${nullable ? '' : ' NOT NULL'}'
          '${i < t.columns.length - 1 ? ',' : ''}',
    ');',
  ],
  '',
].join('\n');
