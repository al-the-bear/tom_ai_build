/// The C# + ASP.NET Core server mapper (`irspecs_ir.md` §14): the server of the
/// IR written as one .NET 8 solution — a shared class library and an ASP.NET
/// Core web project with minimal APIs, EF Core entities with their first
/// migration, and FluentValidation validators. Like the Dart + Tom mapper the
/// output is a skeleton: `dotnet build` builds it, and it executes nothing — a
/// body the specification gives no steps for throws `NotImplementedException`.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../codespecs/cs_model.dart';
import '../../emitters/emit_common.dart';
import '../../emitters/openapi_emitter.dart';
import '../../ir_model.dart';
import '../../ir_steps.dart';
import '../dart_tom/dart_tom_mapper.dart' show IrMapException;
import '../mapper_common.dart';

/// The C# + ASP.NET Core server's mapper.
const String kCsharpAspnetServerMapper = 'csharp-aspnet-server';

/// The versions the solution pins: the target framework, the SDK band
/// `global.json` asks for, and the NuGet packages.
const Map<String, String> kCsharpVersions = {
  'targetFramework': 'net8.0',
  'sdk': '8.0.100',
  'Microsoft.EntityFrameworkCore': '8.0.34',
  'Npgsql.EntityFrameworkCore.PostgreSQL': '8.0.11',
  'FluentValidation': '12.2.0',
  'FluentValidation.DependencyInjectionExtensions': '12.2.0',
};

/// The solution's files for [share]'s server — `<path>` → text, under the
/// solution's directory, which is the server package's name. [all] is the
/// whole IR folder the share was taken from: the solution carries the shared
/// locus as its `Shared` project, and its routes come from the whole folder's
/// OpenAPI document (`irspecs_ir.md` §10).
Map<String, String> mapCsharpAspnet(
  List<IrDocument> share, {
  List<IrDocument>? all,
}) {
  final everything = all ?? share;
  final unit =
      _packageName(share, CsLocus.server) ??
      _packageName(everything, CsLocus.server);
  if (unit == null) return const {};
  final root = csharpNamespaceName(unit);
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
  final symbols = _Symbols([
    for (final s in shared) (project: 'Shared', area: s.area, file: s.file),
    for (final s in server) (project: 'Server', area: s.area, file: s.file),
  ]);
  final dbContext = '${root}DbContext';
  for (final reserved in [dbContext, 'TomRepository', 'TomPageRequest']) {
    if (symbols.byName.containsKey(reserved)) {
      throw IrMapException(
        'the IR declares $reserved, a name the C# mapper writes itself',
      );
    }
  }

  final out = <String, String>{};
  final sharedDir = '$unit/src/$root.Shared';
  final serverDir = '$unit/src/$root.Server';
  final validators = <String>{};
  for (final (project, files, dir) in [
    ('Shared', shared, sharedDir),
    ('Server', server, serverDir),
  ]) {
    for (final f in files) {
      final writer = _FileWriter(
        file: f.file,
        area: f.area,
        namespace: '$root.$project',
        symbols: symbols,
      );
      for (final MapEntry(key: name, value: text) in writer.render().entries) {
        out['$dir/$name.cs'] = text;
      }
      for (final MapEntry(key: name, value: text)
          in writer.validators.entries) {
        out['$dir/Validators/$name.cs'] = text;
        validators.add(name);
      }
    }
  }
  out['$sharedDir/CodeSpec/CodeSpecAttribute.cs'] = _codeSpecAttribute(root);
  out['$sharedDir/CodeSpec/DocSpecAttribute.cs'] = _docSpecAttribute(root);
  out['$sharedDir/GlobalUsings.cs'] = _usings([
    'System.Text.Json.Serialization',
    'FluentValidation',
    '$root.CodeSpec',
  ]);
  out['$serverDir/GlobalUsings.cs'] = _usings([
    'System.ComponentModel.DataAnnotations.Schema',
    'FluentValidation',
    'Microsoft.EntityFrameworkCore',
    '$root.CodeSpec',
    '$root.Shared',
  ]);
  out['$serverDir/Tom/TomRepository.cs'] = _tomRepository(root);

  final tables = _tables(server, symbols);
  out['$serverDir/$dbContext.cs'] = _dbContext(root, dbContext, tables);
  if (tables.isNotEmpty) {
    out['$serverDir/Migrations/00000000000000_CeDbTables.cs'] = _migration(
      root,
      dbContext,
      tables,
    );
  }

  final openApi =
      jsonDecode(emitOpenApi(everything).files[kOpenApiFile]!)
          as Map<String, dynamic>;
  out['$serverDir/Program.cs'] = _program(
    root,
    dbContext,
    openApi,
    server,
    symbols,
  );
  out['$serverDir/ValidationFilter.cs'] = _validationFilter(root);

  final v = kCsharpVersions;
  out['$sharedDir/$root.Shared.csproj'] = _csproj(
    sdk: 'Microsoft.NET.Sdk',
    root: '$root.Shared',
    packages: {'FluentValidation': v['FluentValidation']!},
  );
  out['$serverDir/$root.Server.csproj'] = _csproj(
    sdk: 'Microsoft.NET.Sdk.Web',
    root: '$root.Server',
    packages: {
      for (final p in [
        'Microsoft.EntityFrameworkCore',
        'Npgsql.EntityFrameworkCore.PostgreSQL',
        'FluentValidation.DependencyInjectionExtensions',
      ])
        p: v[p]!,
    },
    references: ['../$root.Shared/$root.Shared.csproj'],
  );
  out['$unit/Directory.Build.props'] = [
    '<!-- $_generated -->',
    '<Project>',
    '  <PropertyGroup>',
    '    <TargetFramework>${v['targetFramework']}</TargetFramework>',
    '    <Nullable>enable</Nullable>',
    '    <ImplicitUsings>enable</ImplicitUsings>',
    '  </PropertyGroup>',
    '</Project>',
    '',
  ].join('\n');
  out['$unit/global.json'] = irJson({
    'sdk': {'version': v['sdk'], 'rollForward': 'latestFeature'},
  });
  out['$unit/$root.sln'] = _solution(root);
  return out;
}

const String _generated =
    'Generated by TomSpecs Phase 4 (CodeSpecs, mapper csharp-aspnet-server) '
    '— do not edit.';

String? _packageName(List<IrDocument> documents, CsLocus locus) {
  for (final d in documents) {
    for (final p in d.projects) {
      if (p.locus == locus) return p.packageName;
    }
  }
  return null;
}

/// The root namespace of a package name: its parts in Pascal case,
/// `meridian_codespec_server` → `MeridianCodespecServer`; a leading digit is
/// prefixed with `N`.
String csharpNamespaceName(String name) {
  final pascal = [
    for (final part in name.split(RegExp('[^A-Za-z0-9]+')))
      if (part.isNotEmpty) '${part[0].toUpperCase()}${part.substring(1)}',
  ].join();
  if (pascal.isEmpty) return 'N';
  return RegExp('^[0-9]').hasMatch(pascal) ? 'N$pascal' : pascal;
}

/// C#'s reserved words: an identifier that is one is written with `@`.
const Set<String> _csharpReserved = {
  'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char', //
  'checked', 'class', 'const', 'continue', 'decimal', 'default', 'delegate',
  'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern', 'false',
  'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit',
  'in', 'int', 'interface', 'internal', 'is', 'lock', 'long', 'namespace',
  'new', 'null', 'object', 'operator', 'out', 'override', 'params', 'private',
  'protected', 'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed',
  'short', 'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch',
  'this', 'throw', 'true', 'try', 'typeof', 'uint', 'ulong', 'unchecked',
  'unsafe', 'ushort', 'using', 'virtual', 'void', 'volatile', 'while',
};

String _id(String name) => _csharpReserved.contains(name) ? '@$name' : name;

String _pascal(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// A C# string literal: JSON's escapes are C#'s.
String _string(String s) => jsonEncode(s);

String _usings(List<String> namespaces) => [
  '// $_generated',
  '',
  for (final n in namespaces) 'global using $n;',
  '',
].join('\n');

// ---------------------------------------------------------------------------
// Symbols
// ---------------------------------------------------------------------------

class _Symbol {
  final IrShape shape;
  final bool isEnum;
  const _Symbol(this.shape, {required this.isEnum});
}

class _Symbols {
  final Map<String, _Symbol> byName = {};

  /// `Collaborator.method` → its body, for the steps' calls.
  final Map<String, CsMethodBody> methods = {};

  _Symbols(List<({String project, String area, IrFile file})> files) {
    for (final f in files) {
      final index = irFileIndex(f.area, f.file);
      for (final e in index.topLevel) {
        final name = e.declaration.name;
        if (byName.containsKey(name)) {
          throw IrMapException(
            '${f.file.file.path}: $name is declared twice in the shared and '
            'server loci; the two projects share one set of names',
          );
        }
        byName[name] = _Symbol(
          _declarationShape(index, e),
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

/// The shape of [e] as the C# server mapper writes it: a layout is the
/// client's, a top-level variable has no class to live in.
IrShape _declarationShape(IrIndex index, IrEntry e) {
  final shape = irDeclarationShape(index, e, mapper: 'C# mapper');
  if (shape == IrShape.layout) {
    throw IrMapException(
      '${e.file.file.path}: ${e.declaration.name} is a layout; the C# server '
      'mapper writes no client',
    );
  }
  if (shape == IrShape.variable) {
    throw IrMapException(
      '${e.file.file.path}: the top-level variable ${e.declaration.name} has '
      'no C# class to live in',
    );
  }
  return shape;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// The C# form of a Dart type. Types follow `irspecs_ir.md` §10.1's JSON
/// Schema mapping, so the wire types and the schemas agree.
class _Types {
  final _Symbols symbols;
  final Set<String> typeParameters;

  _Types(this.symbols, this.typeParameters);

  String of(String dart) {
    final t = dart.trim();
    if (t.endsWith('?')) return '${of(t.substring(0, t.length - 1))}?';
    final generic = RegExp(r'^(\w+)<(.*)>$').firstMatch(t);
    if (generic != null) {
      final base = generic.group(1)!;
      final args = irSplitTypeArguments(generic.group(2)!);
      switch (base) {
        case 'List' || 'Iterable' || 'Set':
          return 'List<${of(args.single)}>';
        case 'Map':
          return 'Dictionary<${of(args[0])}, ${of(args[1])}>';
        case 'Future' || 'FutureOr':
          throw IrMapException('`$t` is a Future outside a method result');
        case 'TomRepository':
          return 'TomRepository<${args.map(of).join(', ')}>';
      }
      return '${_named(base)}<${args.map(of).join(', ')}>';
    }
    switch (t) {
      case 'String' || 'Uri' || 'Duration':
        return 'string';
      case 'DateTime':
        return 'DateTimeOffset';
      case 'int':
        return 'int';
      case 'double' || 'num':
        return 'double';
      case 'bool':
        return 'bool';
      case 'Object' || 'dynamic':
        return 'object';
    }
    if (typeParameters.contains(t)) return t;
    if (t.startsWith('Cs') &&
        (t.endsWith('Ref') || t.endsWith('Key') || t.endsWith('Code'))) {
      return 'string';
    }
    return _named(t);
  }

  String _named(String name) {
    if (!symbols.byName.containsKey(name)) {
      throw IrMapException('the type `$name` has no C# form');
    }
    return name;
  }

  /// A method's result: `Future<X>` → `Task<X>`, `Future<void>` → `Task`,
  /// `X` → `X`, `void` → `void`.
  String resultOf(String? dart) {
    final t = (dart ?? 'void').trim();
    final future = RegExp(r'^(?:Future|FutureOr)<(.*)>$').firstMatch(t);
    if (future != null) {
      final inner = future.group(1)!.trim();
      return inner == 'void' ? 'Task' : 'Task<${of(inner)}>';
    }
    if (t == 'Future') return 'Task';
    if (t == 'void') return 'void';
    return of(t);
  }
}

/// Whether a Dart return type is a future.
bool _isFuture(String? dart) =>
    RegExp(r'^(?:Future|FutureOr)(?:<.*>)?$').hasMatch((dart ?? '').trim());

/// Whether a Dart return type yields no value.
bool _isVoid(String? dart) {
  final t = (dart ?? 'void').replaceAll(' ', '');
  return t == 'void' || t == 'Future<void>' || t == 'Future';
}

// ---------------------------------------------------------------------------
// One Dart file: a C# file per top-level declaration
// ---------------------------------------------------------------------------

class _FileWriter {
  final IrFile file;
  final String area;
  final String namespace;
  final _Symbols symbols;

  /// `<Record>Validator` → its file, for each record with `@CsValidation`
  /// rules.
  final Map<String, String> validators = {};

  _FileWriter({
    required this.file,
    required this.area,
    required this.namespace,
    required this.symbols,
  });

  late final IrIndex _index = irFileIndex(area, file);

  /// `<type name>` → the C# file's text.
  Map<String, String> render() => {
    for (final e in _index.topLevel) e.declaration.name: _render(e),
  };

  String _render(IrEntry e) => [
    '// $_generated',
    for (final c in file.file.comments)
      if (c.isBanner && !c.text.contains('GENERATED')) c.text,
    '',
    'namespace $namespace;',
    '',
    ..._declaration(e),
    '',
  ].join('\n');

  List<String> _declaration(IrEntry e) {
    final d = e.declaration;
    final members = _index.membersOf(e);
    final where = '${file.file.path}: ${d.name}';
    final typeParameters = irTypeParameterNames(d.typeParameters, where);
    final types = _Types(symbols, typeParameters);
    final generics = typeParameters.isEmpty
        ? ''
        : '<${typeParameters.join(', ')}>';
    switch (_declarationShape(_index, e)) {
      case IrShape.catalogue:
        return _catalogue(d, members);
      case IrShape.plainData:
        return _record(d, members, types, generics);
      case IrShape.entity:
        return _entity(d, members, types);
      case IrShape.contract:
        final bases = d.superclass == null
            ? ''
            : ' : ${types.of(d.superclass!)}';
        return [
          ..._doc(d, ''),
          'public interface ${d.name}$generics$bases',
          '{',
          for (final (i, (m, b)) in _methods(members).indexed) ...[
            if (i > 0) '',
            ..._doc(m, '    '),
            '    ${types.resultOf(b.returnType)} ${_pascal(m.name)}'
                '(${_parameters(b, types)});',
          ],
          '}',
        ];
      case IrShape.serviceUnit:
        if (members.any((m) => m.kind == CsDeclarationKind.field)) {
          throw IrMapException(
            '$where: a service unit with fields has no C# rule',
          );
        }
        return [
          ..._doc(d, ''),
          'public class ${d.name}',
          '{',
          for (final (i, (m, b)) in _methods(members).indexed) ...[
            if (i > 0) '',
            ..._doc(m, '    '),
            '    public virtual ${types.resultOf(b.returnType)} '
                '${_pascal(m.name)}(${_parameters(b, types)})',
            '    {',
            '        ${_notImplemented(b, m)}',
            '    }',
          ],
          '}',
        ];
      case IrShape.classType:
        return _classType(d, members, types, generics);
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
      '${types.of(p.type ?? 'Object')} ${_id(p.name)}',
  ].join(', ');

  String _notImplemented(CsMethodBody b, CsDeclaration m) =>
      'throw new NotImplementedException('
      '${_string(b.thrownMessage ?? b.thrownLiteral ?? m.name)});';

  List<String> _catalogue(CsDeclaration d, List<CsDeclaration> members) {
    if (d.kind == CsDeclarationKind.enumType) {
      final values = [
        for (final m in members)
          if (m.kind == CsDeclarationKind.field) m,
      ];
      return [
        ..._doc(d, ''),
        '[JsonConverter(typeof(JsonStringEnumConverter<${d.name}>))]',
        'public enum ${d.name}',
        '{',
        for (final (i, m) in values.indexed) ...[
          if (i > 0) '',
          ..._doc(m, '    '),
          '    ${_id(m.name)},',
        ],
        '}',
      ];
    }
    return [
      ..._doc(d, ''),
      'public static class ${d.name}',
      '{',
      for (final (i, m) in members.indexed) ...[
        if (i > 0) '',
        ..._doc(m, '    '),
        '    public const string ${_id(m.name)} = '
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
        'which the C# mapper has no rule for',
      );
    }
  }

  /// A plain data class as a positional record, a parameter per field — its
  /// back-links on the property it declares — and, when a field carries
  /// `@CsValidation` rules, a FluentValidation validator beside it.
  List<String> _record(
    CsDeclaration d,
    List<CsDeclaration> members,
    _Types types,
    String generics,
  ) {
    final fields = [
      for (final m in members)
        if (m.kind == CsDeclarationKind.field) m,
    ];
    final params = <String>[];
    final rules = <String>[];
    for (final (i, m) in fields.indexed) {
      _plainField(d, m);
      final property = _pascal(m.name);
      final dart = (m.declaredType ?? 'Object').trim();
      params.addAll([
        for (final a in _backLinkAttributes(m)) '    [property: $a]',
        // The JSON Schema's `required`: every non-nullable member.
        if (!dart.endsWith('?')) '    [property: JsonRequired]',
        '    ${types.of(m.declaredType ?? 'Object')} ${_id(property)}'
            '${i < fields.length - 1 ? ',' : ');'}',
      ]);
      final rule = _rule(m, property, types);
      if (rule != null) rules.add(rule);
    }
    if (rules.isNotEmpty) {
      if (generics.isNotEmpty) {
        throw IrMapException(
          '${file.file.path}: ${d.name}: a generic record with validation '
          'rules has no C# validator rule',
        );
      }
      validators['${d.name}Validator'] = [
        '// $_generated',
        '',
        'namespace $namespace;',
        '',
        '/// <summary>The <c>@CsValidation</c> rules of <see cref="${d.name}"/> '
            '(codespecs_mapping.md §5.19).</summary>',
        'public sealed class ${d.name}Validator : AbstractValidator<${d.name}>',
        '{',
        '    public ${d.name}Validator()',
        '    {',
        for (final r in rules) '        $r',
        '    }',
        '}',
        '',
      ].join('\n');
    }
    return [
      ..._doc(
        d,
        '',
        params: {for (final m in fields) _pascal(m.name): ?_memberText(m)},
      ),
      'public sealed record ${d.name}$generics(',
      ...params,
    ];
  }

  /// A record member's doc text and its markers, for its `<param>`.
  String? _memberText(CsDeclaration m) {
    final parts = [
      ?irDocText(m)?.replaceAll('\n', ' '),
      for (final k in m.markers) 'Cs: ${irMarkerSource(k)}',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// The FluentValidation rule of [m]'s `@CsValidation` rules
  /// (`codespecs_mapping.md` §5.19), or `null` when it has none.
  String? _rule(CsDeclaration m, String property, _Types types) {
    final rules = irString(irMarker(m, 'CsValidation')?.named['rules']);
    if (rules == null || rules.trim().isEmpty) return null;
    final chain = <String>[];
    for (final raw in rules.split(',')) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      final colon = token.indexOf(':');
      final name = colon < 0 ? token : token.substring(0, colon);
      final arg = colon < 0 ? null : token.substring(colon + 1).trim();
      String number() {
        if (num.tryParse(arg ?? '') == null) {
          throw IrMapException(
            '${file.file.path}: ${m.name}: the rule `$token` has no number',
          );
        }
        return arg!;
      }

      chain.add(switch (name) {
        'required' => 'NotNull()',
        'email' => 'EmailAddress()',
        'pattern' => 'Matches(${_string(arg ?? '')})',
        'minLength' => 'MinimumLength(${int.parse(number())})',
        'maxLength' => 'MaximumLength(${int.parse(number())})',
        'minItems' =>
          'Must(v => v is null || v.Count >= ${int.parse(number())})',
        'maxItems' =>
          'Must(v => v is null || v.Count <= ${int.parse(number())})',
        'min' => 'GreaterThanOrEqualTo(${number()})',
        'max' => 'LessThanOrEqualTo(${number()})',
        _ => throw IrMapException(
          '${file.file.path}: ${m.name}: the validator `$token` has no '
          'FluentValidation rule',
        ),
      });
    }
    return 'RuleFor(x => x.$property).${chain.join('.')};';
  }

  List<String> _entity(
    CsDeclaration d,
    List<CsDeclaration> members,
    _Types types,
  ) {
    final table =
        irString(irMarker(d, 'CsTable')?.positional.firstOrNull) ??
        irSnake(d.name);
    final fields = [
      for (final m in members)
        if (m.kind == CsDeclarationKind.field) m,
    ];
    final out = [
      ..._doc(d, ''),
      '[Table(${_string(table)})]',
      'public class ${d.name}',
      '{',
    ];
    for (final (i, m) in fields.indexed) {
      _plainField(d, m);
      final dart = (m.declaredType ?? 'String').trim();
      final col = irMarker(m, 'CsColumn');
      final column = irString(col?.named['column']) ?? irSnake(m.name);
      final sqlType = irString(col?.named['columnType']);
      final type = types.of(dart);
      // A non-nullable reference type is assigned by EF Core when it reads the
      // row, not by a constructor.
      final isReference =
          !dart.endsWith('?') &&
          !(symbols.byName[dart]?.isEnum ?? false) &&
          !const {'int', 'double', 'num', 'bool', 'DateTime'}.contains(dart);
      if (i > 0) out.add('');
      out.addAll([
        ..._doc(m, '    '),
        '    [Column(${[_string(column), if (sqlType != null) 'TypeName = ${_string(sqlType)}'].join(', ')})]',
        '    public $type ${_pascal(m.name)} { get; set; }'
            '${isReference ? ' = null!;' : ''}',
      ]);
    }
    out.add('}');
    return out;
  }

  List<String> _classType(
    CsDeclaration d,
    List<CsDeclaration> members,
    _Types types,
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
      ..._doc(d, ''),
      'public ${d.isAbstract ? 'abstract ' : ''}class ${d.name}$generics',
      '{',
    ];
    for (final (i, m) in fields.indexed) {
      if (i > 0) out.add('');
      out.addAll([
        ..._doc(m, '    '),
        '    private ${m.isFinal ? 'readonly ' : ''}'
            '${types.of(m.declaredType ?? 'Object')} ${_id(m.name)};',
      ]);
    }
    if (fields.isNotEmpty) {
      out.addAll([
        '',
        '    public ${d.name}(${[for (final m in fields) '${types.of(m.declaredType ?? 'Object')} ${_id(m.name)}'].join(', ')})',
        '    {',
        for (final m in fields) '        this.${_id(m.name)} = ${_id(m.name)};',
        '    }',
      ]);
    }
    for (final (m, b) in _methods(members)) {
      final record = file.steps
          .where((r) => r.owner == d.name && r.body == m.name)
          .firstOrNull;
      final result = types.resultOf(b.returnType);
      final List<String> body;
      var isAsync = false;
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
        isAsync = _isFuture(b.returnType);
        body = _StepWriter(
          collaborator: collaborator.replaceAll('?', ''),
          symbols: symbols,
          isAsync: isAsync,
          isVoid: _isVoid(b.returnType),
        ).write(steps, '        ');
      } else {
        body = ['        ${_notImplemented(b, m)}'];
      }
      out.addAll([
        '',
        ..._doc(m, '    '),
        '    public ${isAsync ? 'async ' : ''}$result ${_pascal(m.name)}'
            '(${_parameters(b, types)})',
        '    {',
        ...body,
        '    }',
      ]);
    }
    out.add('}');
    return out;
  }

  /// The XML doc comment of [d] — its Dart doc text, its markers and other
  /// annotations, [params] as `<param>` — and its back-link attributes.
  List<String> _doc(
    CsDeclaration d,
    String indent, {
    Map<String, String> params = const {},
  }) {
    final lines = <String>[
      for (final l in d.docComment?.lines ?? const <String>[])
        _xml(l.trimLeft().replaceFirst(RegExp(r'^/// ?'), '').trim()),
    ];
    final notes = <String>[
      for (final m in d.markers) 'Cs: ${_xml(irMarkerSource(m))}',
      for (final a in d.annotations) 'Dart: ${_xml(a.source)}',
    ];
    final out = <String>[];
    if (lines.isNotEmpty || notes.isNotEmpty) {
      out
        ..add('$indent/// <summary>')
        ..addAll([
          for (final l in lines) l.isEmpty ? '$indent///' : '$indent/// $l',
        ])
        ..addAll([
          if (lines.isNotEmpty && notes.isNotEmpty) '$indent/// <para>',
          for (final (i, n) in notes.indexed)
            '$indent/// $n${i < notes.length - 1 ? '<br/>' : ''}',
          if (lines.isNotEmpty && notes.isNotEmpty) '$indent/// </para>',
        ])
        ..add('$indent/// </summary>');
    }
    for (final MapEntry(:key, :value) in params.entries) {
      out.add(
        '$indent/// <param name="$key">${_xml(value.replaceAll('\n', ' '))}</param>',
      );
    }
    return [...out, for (final a in _backLinkAttributes(d)) '$indent[$a]'];
  }

  /// Text as an XML doc comment reads it literally.
  String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// `CodeSpec(…)` and one `DocSpec(…)` per section, with the Dart trio's
  /// section ids (`irspecs_ir.md` §14).
  List<String> _backLinkAttributes(CsDeclaration d) => [
    if (d.codeSpec case final cs?)
      'CodeSpec(${[_string(cs.id), ...cs.source.map(_string)].join(', ')})',
    for (final r in d.docSpec ?? const <CsDocRef>[])
      'DocSpec(${_string(r.sectionId)}, ${_string(r.description)})',
  ];
}

/// A 3b body from its steps (`irspecs_ir.md` §4.7).
class _StepWriter {
  final String collaborator;
  final _Symbols symbols;
  final bool isAsync;
  final bool isVoid;

  _StepWriter({
    required this.collaborator,
    required this.symbols,
    required this.isAsync,
    required this.isVoid,
  });

  CsMethodBody _callee(String method) {
    final b = symbols.methods['$collaborator.$method'];
    if (b == null) {
      throw IrMapException(
        'the step calls $collaborator.$method, which the collaborator does '
        'not declare',
      );
    }
    return b;
  }

  String _call(String method, List<String> args) {
    final awaited = isAsync && _isFuture(_callee(method).returnType);
    return '${awaited ? 'await ' : ''}collaborator.${_pascal(method)}'
        '(${args.map(_id).join(', ')})';
  }

  List<String> write(List<IrStep> steps, String indent) => [
    for (final s in steps)
      ...switch (s) {
        IrCallStep(:final method, :final arguments) => [
          '$indent${_call(method, arguments)};',
        ],
        IrReturnStep(:final method, :final arguments) => [
          if (method == null)
            '${indent}return${isVoid ? '' : ' default!'};'
          else if (isVoid || _isVoid(_callee(method).returnType)) ...[
            '$indent${_call(method, arguments)};',
            '${indent}return;',
          ] else
            '${indent}return ${_call(method, arguments)};',
        ],
        IrGuardedStep(:final guard, :final arguments, :final steps) => [
          '${indent}if (${_call(guard, arguments)})',
          '$indent{',
          ...write(steps, '$indent    '),
          '$indent}',
        ],
      },
  ];
}

// ---------------------------------------------------------------------------
// The solution's other sources
// ---------------------------------------------------------------------------

String _codeSpecAttribute(String root) =>
    '''
// $_generated

namespace $root.CodeSpec;

/// <summary>The CodeSpec a declaration realises: its id and the section ids it
/// was written from (irspecs_ir.md §14).</summary>
[AttributeUsage(AttributeTargets.All, AllowMultiple = false)]
public sealed class CodeSpecAttribute(string id, params string[] source) : Attribute
{
    /// <summary>The CodeSpec id, e.g. <c>serviceUnit.OrderService</c>.</summary>
    public string Id { get; } = id;

    /// <summary>The section ids it was written from.</summary>
    public string[] Source { get; } = source;
}
''';

String _docSpecAttribute(String root) =>
    '''
// $_generated

namespace $root.CodeSpec;

/// <summary>One specification section a declaration traces back to, and what
/// it supplies; one attribute per section.</summary>
[AttributeUsage(AttributeTargets.All, AllowMultiple = true)]
public sealed class DocSpecAttribute(string sectionId, string description) : Attribute
{
    /// <summary>The section id.</summary>
    public string SectionId { get; } = sectionId;

    /// <summary>What the section supplies.</summary>
    public string Description { get; } = description;
}
''';

String _tomRepository(String root) =>
    '''
// $_generated

namespace $root.Server;

/// <summary>A page of a query: its index from 0 and its size.</summary>
public sealed record TomPageRequest(int Page, int Size);

/// <summary>The repository contract of tom_core_server, method by method:
/// <typeparamref name="T"/> the entity, <typeparamref name="TKey"/> its
/// key.</summary>
public interface TomRepository<T, TKey>
    where T : class
{
    Task<int> Count();

    Task Delete(T entity);

    Task<int> DeleteAllById(List<TKey> ids);

    Task<int> DeleteById(TKey id);

    Task<bool> ExistsById(List<TKey> ids);

    Task<List<T>> FindAll(TomPageRequest? page = null);

    Task<List<T>> FindAllById(List<TKey> ids, TomPageRequest? page = null);

    Task<T?> FindById(TKey id);

    Task<T> Save(T toSave);

    Task<List<T>> SaveAll(List<T> entities);
}
''';

String _validationFilter(String root) =>
    '''
// $_generated

namespace $root.Server;

/// <summary>Runs the FluentValidation validator of a request, when there is
/// one. A request that fails it is answered with a 500 until Phase 6 answers
/// it with the Result envelope's error arm: only a 5xx status is a transport
/// error (codespecs_mapping.md §7).</summary>
public sealed class ValidationFilter<T> : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        var validator = context.HttpContext.RequestServices.GetService<IValidator<T>>();
        var request = context.Arguments.OfType<T>().FirstOrDefault();
        if (validator is not null && request is not null)
        {
            var result = await validator.ValidateAsync(request);
            if (!result.IsValid)
            {
                return Results.StatusCode(StatusCodes.Status500InternalServerError);
            }
        }
        return await next(context);
    }
}
''';

/// `Program.cs`: the services, and a `MapPost` per operation from the OpenAPI
/// document to its service unit's handler.
String _program(
  String root,
  String dbContext,
  Map<String, dynamic> openApi,
  List<({String area, IrFile file})> server,
  _Symbols symbols,
) {
  final handlers =
      <String, ({String owner, String method, CsMethodBody body})>{};
  final units = <String>{};
  for (final f in server) {
    final index = irFileIndex(f.area, f.file);
    for (final e in index.topLevel) {
      if (irMarker(e.declaration, 'CsServiceUnit') == null) continue;
      units.add(e.declaration.name);
      for (final m in index.membersOf(e)) {
        final op = irString(irMarker(m, 'CsEndpoint')?.positional.firstOrNull);
        final b = m.bodies.where((b) => b.name == m.name).firstOrNull;
        if (op != null && b != null) {
          handlers[op] = (owner: e.declaration.name, method: m.name, body: b);
        }
      }
    }
  }
  final types = _Types(symbols, const {});
  final routes = <String>[];
  for (final o in openApiOperations(openApi)) {
    final h = handlers[o.op];
    if (h == null) continue;
    final params = h.body.parameters;
    if (params.length > 1) {
      throw IrMapException(
        '${h.owner}.${h.method}: a handler takes at most its request',
      );
    }
    final request = params.isEmpty
        ? null
        : types.of(params.single.type ?? 'Object');
    final lambdaParams = [
      if (request != null) '$request request',
      '${h.owner} service',
    ].join(', ');
    routes.addAll([
      'app.MapPost(${_string(o.path)}, ($lambdaParams) =>',
      '        service.${_pascal(h.method)}(${request == null ? '' : 'request'}))',
      if (request != null)
        '    .AddEndpointFilter<ValidationFilter<$request>>();'
      else
        '    ;',
    ]);
  }
  return [
    '// $_generated',
    '',
    'using Microsoft.AspNetCore.Diagnostics;',
    'using $root.Server;',
    '',
    'var builder = WebApplication.CreateBuilder(args);',
    '',
    '// The database is read when a repository first needs it.',
    'builder.Services.AddDbContext<$dbContext>(options =>',
    '    options.UseNpgsql(',
    '        builder.Configuration.GetConnectionString("Default")',
    '            ?? throw new InvalidOperationException('
        '"ConnectionStrings:Default is not set")));',
    for (final u in units.toList()..sort()) 'builder.Services.AddScoped<$u>();',
    'builder.Services.AddValidatorsFromAssemblyContaining<CodeSpecAttribute>();',
    '',
    '// Only a 5xx status is a transport error (codespecs_mapping.md §7): a body',
    '// that does not read is thrown, not answered with a 400, and every',
    '// exception is answered with a 500.',
    'builder.Services.Configure<RouteHandlerOptions>('
        'options => options.ThrowOnBadRequest = true);',
    '',
    'var app = builder.Build();',
    'app.UseExceptionHandler(handler => handler.Run(context =>',
    '{',
    '    context.Response.StatusCode = StatusCodes.Status500InternalServerError;',
    '    var error = context.Features.Get<IExceptionHandlerFeature>()?.Error;',
    '    return context.Response.WriteAsync(error?.Message ?? "transport error");',
    '}));',
    '',
    '// Every operation a POST of its request to its service unit\'s handler,',
    '// its answer the Result envelope (irspecs_ir.md §14).',
    ...routes,
    '',
    'app.Run();',
    '',
  ].join('\n');
}

String _csproj({
  required String sdk,
  required String root,
  required Map<String, String> packages,
  List<String> references = const [],
}) => [
  '<!-- $_generated -->',
  '<Project Sdk="$sdk">',
  '  <PropertyGroup>',
  '    <RootNamespace>$root</RootNamespace>',
  '  </PropertyGroup>',
  '  <ItemGroup>',
  for (final MapEntry(:key, :value) in packages.entries)
    '    <PackageReference Include="$key" Version="$value" />',
  '  </ItemGroup>',
  if (references.isNotEmpty) ...[
    '  <ItemGroup>',
    for (final r in references) '    <ProjectReference Include="$r" />',
    '  </ItemGroup>',
  ],
  '</Project>',
  '',
].join('\n');

/// A GUID derived from [name], so the solution file is the same on every run.
String _guid(String name) {
  final h = md5.convert(utf8.encode(name)).toString().toUpperCase();
  return '{${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20, 32)}}';
}

String _solution(String root) {
  const csharp = '{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}';
  final projects = ['$root.Shared', '$root.Server'];
  return [
    '',
    'Microsoft Visual Studio Solution File, Format Version 12.00',
    '# Visual Studio Version 17',
    'VisualStudioVersion = 17.0.31903.59',
    'MinimumVisualStudioVersion = 10.0.40219.1',
    for (final p in projects) ...[
      'Project("$csharp") = "$p", "src\\$p\\$p.csproj", "${_guid(p)}"',
      'EndProject',
    ],
    'Global',
    '\tGlobalSection(SolutionConfigurationPlatforms) = preSolution',
    '\t\tDebug|Any CPU = Debug|Any CPU',
    '\t\tRelease|Any CPU = Release|Any CPU',
    '\tEndGlobalSection',
    '\tGlobalSection(ProjectConfigurationPlatforms) = postSolution',
    for (final p in projects)
      for (final c in ['Debug', 'Release']) ...[
        '\t\t${_guid(p)}.$c|Any CPU.ActiveCfg = $c|Any CPU',
        '\t\t${_guid(p)}.$c|Any CPU.Build.0 = $c|Any CPU',
      ],
    '\tEndGlobalSection',
    'EndGlobal',
    '',
  ].join('\n');
}

// ---------------------------------------------------------------------------
// EF Core: the context and the CE-DB tables as the first migration
// ---------------------------------------------------------------------------

class _Table {
  final String entity;
  final String table;
  final List<(String, String, bool)> columns;
  final List<String> enumProperties;
  const _Table(this.entity, this.table, this.columns, this.enumProperties);
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
      final fields = [
        for (final m in index.membersOf(e))
          if (m.kind == CsDeclarationKind.field && !m.isStatic) m,
      ];
      out.add(
        _Table(
          d.name,
          irString(cs.positional.firstOrNull) ?? irSnake(d.name),
          [
            for (final m in fields)
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
          ],
          [
            for (final m in fields)
              if (symbols
                      .byName[(m.declaredType ?? '').replaceAll('?', '')]
                      ?.isEnum ??
                  false)
                _pascal(m.name),
          ],
        ),
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

String _dbContext(String root, String name, List<_Table> tables) => [
  '// $_generated',
  '',
  'namespace $root.Server;',
  '',
  '/// <summary>The EF Core context of the CE-DB entities; an enum-typed',
  '/// column is stored as the enum value\'s name.</summary>',
  'public class $name(DbContextOptions<$name> options) : DbContext(options)',
  '{',
  for (final t in tables) ...[
    '    public DbSet<${t.entity}> ${t.entity}Set => Set<${t.entity}>();',
    '',
  ],
  '    protected override void OnModelCreating(ModelBuilder modelBuilder)',
  '    {',
  for (final t in tables)
    for (final p in t.enumProperties)
      '        modelBuilder.Entity<${t.entity}>().Property(e => e.$p)'
          '.HasConversion<string>();',
  '    }',
  '}',
  '',
].join('\n');

String _migration(String root, String context, List<_Table> tables) => [
  '// $_generated',
  '',
  'using Microsoft.EntityFrameworkCore.Infrastructure;',
  'using Microsoft.EntityFrameworkCore.Migrations;',
  '',
  'namespace $root.Server.Migrations;',
  '',
  '/// <summary>The CE-DB tables, one CREATE TABLE each: the schema the',
  '/// cumulative CE-MG migrations converge on (codespecs_derivation_contract.md',
  '/// §6, check 13), as the first migration.</summary>',
  '[DbContext(typeof($context))]',
  '[Migration("00000000000000_CeDbTables")]',
  'public partial class CeDbTables : Migration',
  '{',
  '    protected override void Up(MigrationBuilder migrationBuilder)',
  '    {',
  '        migrationBuilder.Sql("""',
  for (final (n, t) in tables.indexed) ...[
    if (n > 0) '',
    '            CREATE TABLE ${t.table} (',
    for (final (i, (name, type, nullable)) in t.columns.indexed)
      '              $name $type${nullable ? '' : ' NOT NULL'}'
          '${i < t.columns.length - 1 ? ',' : ''}',
    '            );',
  ],
  '            """);',
  '    }',
  '',
  '    protected override void Down(MigrationBuilder migrationBuilder)',
  '    {',
  for (final t in tables.reversed)
    '        migrationBuilder.Sql("DROP TABLE ${t.table};");',
  '    }',
  '}',
  '',
].join('\n');
