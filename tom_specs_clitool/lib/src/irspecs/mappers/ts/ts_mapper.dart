/// The TypeScript mappers (`irspecs_ir.md` §11): the IR written as an npm
/// workspace — `ts-shared` (the shared package), `ts-react-client` (a React web
/// client, plain `fetch`), `ts-react-native-client` (an Expo React Native
/// client with React Navigation, `irspecs_ir.md` §11.2) and `ts-hono-server` (a Hono server,
/// Drizzle ORM over PostgreSQL). Like the Dart + Tom mapper the
/// output is a skeleton: it type-checks with `tsc --noEmit` and executes
/// nothing — a body the specification gives no steps for throws
/// `not implemented`.
library;

import 'dart:convert';

import '../../../codespecs/cs_model.dart';
import '../../emitters/emit_common.dart';
import '../../emitters/openapi_emitter.dart';
import '../../ir_model.dart';
import '../../ir_steps.dart';
import '../dart_tom/dart_tom_mapper.dart' show IrMapException;
import '../mapper_common.dart';
import '../mapper_keys.dart';

/// The shared package's mapper.
const String kTsSharedMapper = 'ts-shared';

/// The React web client's mapper.
const String kTsReactClientMapper = 'ts-react-client';

/// The React Native (Expo) client's mapper (`irspecs_ir.md` §11.2).
const String kTsReactNativeClientMapper = 'ts-react-native-client';

/// The Hono server's mapper.
const String kTsHonoServerMapper = 'ts-hono-server';

/// The TypeScript mappers and the locus each writes. Both client mappers write
/// the client locus: a project with a web and a mobile client declares two
/// client units, one mapping each (`irspecs_ir.md` §8.1).
const Map<String, CsLocus> kTsMappers = {
  kTsSharedMapper: CsLocus.shared,
  kTsReactClientMapper: CsLocus.client,
  kTsReactNativeClientMapper: CsLocus.client,
  kTsHonoServerMapper: CsLocus.server,
};

/// The versions the workspace's `package.json` files pin.
const Map<String, String> kTsDependencyVersions = {
  'typescript': '5.9.3',
  'react': '^19.3.0',
  '@types/react': '^19.3.0',
  'hono': '^4.13.0',
  'drizzle-orm': '^0.45.0',
  // The mobile client: Expo SDK 58 and the React Native and native-module
  // versions it pins (its bundledNativeModules.json), React Navigation 7.
  'expo': '~58.0.25',
  'react-native': '0.88.1',
  'react-native/react': '19.3.0',
  '@react-navigation/native': '^7.5.1',
  '@react-navigation/native-stack': '^7.21.0',
  'react-native-screens': '~4.30.1',
  'react-native-safe-area-context': '~5.11.1',
};

/// The files [mapper] writes for [share] — the package of its locus — plus the
/// workspace root's `package.json` and `tsconfig.json`; `<path>` → text, the
/// package's files under its package name. [all] is the whole IR folder the
/// share was taken from: the client's API calls and the server's routes come
/// from its OpenAPI document (`irspecs_ir.md` §10), which needs the operation
/// catalogue whichever unit is written.
Map<String, String> mapTypeScript(
  List<IrDocument> share,
  String mapper, {
  List<IrDocument>? all,
}) {
  final locus = kTsMappers[mapper];
  if (locus == null) {
    throw IrMapException('no TypeScript mapper `$mapper`');
  }
  final everything = all ?? share;
  final symbols = _Symbols(everything, share);
  final package = _packageName(share, locus) ?? _packageName(everything, locus);
  if (package == null) return const {};
  final out = <String, String>{};
  final modules = <String>[];
  final tom = _TomTypes();

  for (final d in share) {
    for (final f in d.files) {
      if (f.locus != locus) continue;
      if (d.area == kIrPackageArea) continue; // the barrel is ours to write
      final module = _modulePath(f.file.path);
      final text = _FileWriter(
        file: f,
        area: d.area,
        locus: locus,
        package: package,
        module: module,
        symbols: symbols,
        tom: tom,
      ).render();
      out['$package/$module'] = text;
      modules.add(module);
    }
  }

  // The API client (client) and the routes (server), from the OpenAPI
  // document of the whole folder.
  final openApi =
      jsonDecode(emitOpenApi(everything).files[kOpenApiFile]!)
          as Map<String, dynamic>;
  if (locus == CsLocus.client) {
    const module = 'src/api/api_client.ts';
    out['$package/$module'] = _apiClient(openApi, symbols, package, module);
    modules.add(module);
  }
  if (locus == CsLocus.server) {
    const module = 'src/app.ts';
    out['$package/$module'] = _honoApp(
      openApi,
      everything,
      symbols,
      package,
      module,
    );
    modules.add(module);
  }
  final native = mapper == kTsReactNativeClientMapper;
  if (native) {
    const module = 'src/navigation/app_navigator.ts';
    out['$package/$module'] = _appNavigator(share);
    modules.add(module);
    out['$package/src/main.ts'] = _banner([
      "import { registerRootComponent } from 'expo';",
      "import { AppNavigator } from './navigation/app_navigator.ts';",
      '',
      '// The Expo entry: the app is its navigator.',
      'registerRootComponent(AppNavigator);',
    ]);
    out['$package/app.json'] = irJson({
      'expo': {'name': package, 'slug': package, 'version': '0.0.0'},
    });
  }
  if (!tom.isEmpty || locus == CsLocus.server) {
    const module = 'src/tom/tom.ts';
    out['$package/$module'] = tom.render(server: locus == CsLocus.server);
    modules.add(module);
  }

  out['$package/src/index.ts'] = _banner([
    for (final m in modules..sort()) "export * from './${m.substring(4)}';",
  ]);
  final shared = _packageName(everything, CsLocus.shared);
  final v = kTsDependencyVersions;
  out['$package/package.json'] = irJson({
    'name': package,
    'version': '0.0.0',
    'private': true,
    'type': 'module',
    if (native) 'main': 'src/main.ts',
    'exports': {'.': './src/index.ts'},
    'dependencies': {
      if (locus != CsLocus.shared && shared != null) shared: '*',
      if (native) ...{
        'expo': v['expo'],
        'react': v['react-native/react'],
        'react-native': v['react-native'],
        '@react-navigation/native': v['@react-navigation/native'],
        '@react-navigation/native-stack': v['@react-navigation/native-stack'],
        'react-native-screens': v['react-native-screens'],
        'react-native-safe-area-context': v['react-native-safe-area-context'],
      } else if (locus == CsLocus.client)
        'react': kTsDependencyVersions['react'],
      if (locus == CsLocus.server) ...{
        'hono': kTsDependencyVersions['hono'],
        'drizzle-orm': kTsDependencyVersions['drizzle-orm'],
      },
    },
    if (locus == CsLocus.client)
      'devDependencies': {
        '@types/react': kTsDependencyVersions['@types/react'],
      },
  });
  // A unit's package carries the unit's id (`irspecs_ir.md` §8.1).
  out.addAll(
    tsWorkspaceRoot(IrIndex(everything).title, [
      for (final l in CsLocus.values)
        ?(_packageName(share, l) ?? _packageName(everything, l)),
    ]),
  );
  return out;
}

/// The workspace root of [packages]: the npm workspace and one
/// `tsconfig.json` checking them together; [title] names it.
Map<String, String> tsWorkspaceRoot(String title, List<String> packages) {
  return {
    'package.json': irJson({
      'name': '${title}_workspace',
      'private': true,
      'type': 'module',
      'workspaces': packages,
      'scripts': {'typecheck': 'tsc --noEmit -p .'},
      'devDependencies': {'typescript': kTsDependencyVersions['typescript']},
    }),
    'tsconfig.json': irJson({
      'compilerOptions': {
        'target': 'ES2022',
        'module': 'ESNext',
        'moduleResolution': 'Bundler',
        'allowImportingTsExtensions': true,
        'noEmit': true,
        'strict': true,
        'skipLibCheck': true,
        // Runnable as written by Node's type stripping and by Deno: a type is
        // imported with `import type`, and nothing needs a transform.
        'verbatimModuleSyntax': true,
        'erasableSyntaxOnly': true,
        'lib': ['ES2022', 'DOM'],
      },
      'include': [for (final p in packages) '$p/src/**/*.ts'],
    }),
  };
}

/// [files], a TypeScript mapper's output, with its workspace root merged into
/// the root already written where it goes ([existingPackageJson], or `null`
/// when there is none): the workspace lists every package of both, the
/// existing ones first. Two client units written into one folder — a web and
/// a mobile client of one IR — so share one workspace.
Map<String, String> mergeTsWorkspaceRoot(
  Map<String, String> files,
  String? existingPackageJson,
) {
  if (existingPackageJson == null) return files;
  final existing = jsonDecode(existingPackageJson) as Map<String, dynamic>;
  final mine = jsonDecode(files['package.json']!) as Map<String, dynamic>;
  final title = (mine['name'] as String).replaceFirst(
    RegExp(r'_workspace$'),
    '',
  );
  final packages = <String>[
    ...((existing['workspaces'] as List?) ?? const []).cast<String>(),
  ];
  for (final p in (mine['workspaces'] as List).cast<String>()) {
    if (!packages.contains(p)) packages.add(p);
  }
  return {...files, ...tsWorkspaceRoot(title, packages)};
}

String? _packageName(List<IrDocument> documents, CsLocus locus) {
  for (final d in documents) {
    for (final p in d.projects) {
      if (p.locus == locus) return p.packageName;
    }
  }
  return null;
}

/// `lib/src/data_access/customer.dart` → `src/data_access/customer.ts`.
String _modulePath(String dartPath) {
  var path = dartPath;
  if (path.startsWith('lib/')) path = path.substring(4);
  if (path.endsWith('.dart')) path = path.substring(0, path.length - 5);
  return 'src/${path.startsWith('src/') ? path.substring(4) : path}.ts';
}

String _banner(List<String> lines) =>
    '${['// GENERATED by TomSpecs Phase 4 (CodeSpecs, mapper ts) — do not edit.', '', ...lines].join('\n')}\n';

// ---------------------------------------------------------------------------
// Symbols
// ---------------------------------------------------------------------------

/// What a TypeScript name is: a type only (an interface, a type alias) or a
/// value (a const, a class, a function) — which decides `import type`.
enum _Kind { type, value }

class _Symbol {
  final String package;
  final String module;
  final _Kind kind;
  const _Symbol(this.package, this.module, this.kind);
}

/// Every name the mapped packages declare, with where and what it is.
class _Symbols {
  final Map<String, _Symbol> byName = {};
  final Set<String> entities = {};
  final Set<String> enums = {};

  /// Every `@CsTable` class with its keys and indexes, by class name.
  final Map<String, IrEntityTable> tables = {};

  /// The names [documents] declare; a declaration of a locus [share] writes
  /// lives in the share's package — a unit's id (`irspecs_ir.md` §8.1) —
  /// every other in the package the IR names.
  _Symbols(List<IrDocument> documents, [List<IrDocument> share = const []]) {
    final index = IrIndex(documents);
    for (final e in index.topLevel) {
      final package =
          _packageName(share, e.file.locus) ??
          _packageName(documents, e.file.locus);
      if (package == null) continue;
      final module = _modulePath(e.file.file.path);
      final d = e.declaration;
      final kind = _declarationShape(index, e);
      byName[d.name] = _Symbol(
        package,
        module,
        kind == IrShape.plainData ||
                kind == IrShape.entity ||
                kind == IrShape.contract
            ? _Kind.type
            : _Kind.value,
      );
      if (kind == IrShape.entity) {
        entities.add(d.name);
        tables[d.name] = irEntityTable(index, e)!;
        byName[_tableName(d.name)] = _Symbol(package, module, _Kind.value);
      }
      if (kind == IrShape.catalogue && d.kind == CsDeclarationKind.enumType) {
        enums.add(d.name);
      }
      if (kind == IrShape.layout) {
        byName['${d.name}View'] = _Symbol(package, module, _Kind.value);
      }
    }
  }
}

/// The shape of [e] as the TypeScript mappers write it: a service unit is a
/// class like any other.
IrShape _declarationShape(IrIndex index, IrEntry e) {
  final shape = irDeclarationShape(index, e, mapper: 'TypeScript mappers');
  return shape == IrShape.serviceUnit ? IrShape.classType : shape;
}

/// The string a catalogue entry stands for: `CsMessageKey('a.b')` → `a.b`.
String? _catalogueValue(CsDeclaration m) => irInitialiserString(m);

String _tableName(String entity) =>
    '${entity[0].toLowerCase()}${entity.substring(1)}Table';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// A Dart type as written, in TypeScript — the JSON Schema mapping of
/// `irspecs_ir.md` §10.1, so the wire types and the schemas agree.
String _tsType(String dart, Set<String> typeParameters, Set<String> used) {
  var t = dart.trim();
  if (t.endsWith('?')) {
    return '${_tsType(t.substring(0, t.length - 1), typeParameters, used)} | null';
  }
  final generic = RegExp(r'^(\w+)<(.*)>$').firstMatch(t);
  if (generic != null) {
    final base = generic.group(1)!;
    final args = [
      for (final a in irSplitTypeArguments(generic.group(2)!))
        _tsType(a, typeParameters, used),
    ];
    String wrap(String a) => a.contains('|') ? '($a)' : a;
    switch (base) {
      case 'Future':
        return 'Promise<${args.single}>';
      case 'List' || 'Iterable' || 'Set':
        return '${wrap(args.single)}[]';
      case 'Map':
        return 'Record<${args[0]}, ${args[1]}>';
    }
    used.add(base);
    return '$base<${args.join(', ')}>';
  }
  switch (t) {
    case 'String' || 'DateTime' || 'Uri' || 'Duration':
      return 'string';
    case 'int' || 'double' || 'num':
      return 'number';
    case 'bool':
      return 'boolean';
    case 'void':
      return 'void';
    case 'Object' || 'dynamic':
      return 'unknown';
  }
  if (typeParameters.contains(t)) return t;
  if (t.startsWith('Cs') &&
      (t.endsWith('Ref') || t.endsWith('Key') || t.endsWith('Code'))) {
    return 'string';
  }
  used.add(t);
  return t;
}

Set<String> _typeParameterNames(String? typeParameters) {
  if (typeParameters == null) return const {};
  final inner = typeParameters.trim();
  if (inner.length < 2) return const {};
  return {
    for (final p in irSplitTypeArguments(inner.substring(1, inner.length - 1)))
      p.split(RegExp(r'\s+')).first,
  };
}

// ---------------------------------------------------------------------------
// Values and the Tom substrate
// ---------------------------------------------------------------------------

/// The interfaces of the `tom_core` constructions a package uses, derived from
/// how the IR uses them: every named argument a property, optional unless every
/// construction of the type writes it; a qualified value of a `Tom…` enum a
/// string literal of its name.
class _TomTypes {
  final Map<String, Map<String, Set<String>>> _props = {};
  final Map<String, int> _counts = {};
  final Map<String, Map<String, int>> _written = {};
  final Map<String, Set<String>> _enums = {};

  bool get isEmpty => _props.isEmpty;

  /// Records [c] and returns its TypeScript literal.
  String construction(CsConstruction c, _Symbols symbols, Set<String> used) {
    _counts[c.type] = (_counts[c.type] ?? 0) + 1;
    final props = _props.putIfAbsent(c.type, () => {});
    final written = _written.putIfAbsent(c.type, () => {});
    if (c.positional.isNotEmpty) {
      throw IrMapException(
        'the construction ${c.type} has positional arguments, which the '
        'TypeScript mappers have no property name for',
      );
    }
    final parts = <String>[];
    for (final MapEntry(key: name, value: v) in c.named.entries) {
      written[name] = (written[name] ?? 0) + 1;
      props.putIfAbsent(name, () => {}).add(_valueType(v));
      parts.add('$name: ${value(v, symbols, used)}');
    }
    return '{ ${parts.join(', ')} }';
  }

  String _valueType(CsValue v) => switch (v) {
    CsStringValue() => 'string',
    CsBoolValue() => 'boolean',
    CsIntValue() => 'number',
    CsNullValue() => 'null',
    CsQualifiedValue(:final prefix, :final name) => _enumType(prefix, name),
    CsListValue(:final values) =>
      values.isEmpty ? 'unknown[]' : '${_valueType(values.first)}[]',
    CsConstructionValue(:final type) => type,
    CsUnknownValue() => 'unknown',
  };

  /// The type of a qualified value: a `Tom…` enum's union, else a string (a
  /// catalogue value of the IR).
  String _enumType(String prefix, String name) {
    if (!prefix.startsWith('Tom')) return 'string';
    _enums.putIfAbsent(prefix, () => {}).add(name);
    return prefix;
  }

  /// [v] as a TypeScript expression.
  String value(CsValue v, _Symbols symbols, Set<String> used) => switch (v) {
    CsStringValue(:final value) => jsonEncode(value),
    CsBoolValue(:final value) => '$value',
    CsIntValue(:final value) => '$value',
    CsNullValue() => 'null',
    CsQualifiedValue(:final prefix, :final name) => _qualified(
      prefix,
      name,
      symbols,
      used,
    ),
    CsListValue(:final values) =>
      '[${values.map((e) => value(e, symbols, used)).join(', ')}]',
    CsConstructionValue(:final named) =>
      '{ ${[for (final MapEntry(:key, value: x) in named.entries) '$key: ${value(x, symbols, used)}'].join(', ')} }',
    CsUnknownValue(:final source) => throw IrMapException(
      'the value `$source` has no TypeScript form',
    ),
  };

  /// A qualified value: a reference to a catalogue the IR declares
  /// (`SbpRoles.orderClerk`), else the name as a string literal (a `Tom…`
  /// enum value).
  String _qualified(
    String prefix,
    String name,
    _Symbols symbols,
    Set<String> used,
  ) {
    if (!symbols.byName.containsKey(prefix)) return jsonEncode(name);
    used.add(prefix);
    return '$prefix.$name';
  }

  /// The `tom/tom.ts` module: the construction interfaces, the enum unions,
  /// and on the server the repository contract (`TomRepository`, the methods
  /// of `tom_core_server`'s by name).
  String render({required bool server}) {
    final lines = <String>[];
    for (final MapEntry(key: name, value: values) in _enums.entries) {
      lines.add(
        'export type $name = ${[for (final v in values) jsonEncode(v)].join(' | ')};',
      );
    }
    for (final MapEntry(key: type, value: props) in _props.entries) {
      lines
        ..add('')
        ..add('export interface $type {');
      for (final MapEntry(key: name, value: types) in props.entries) {
        final optional = (_written[type]![name] ?? 0) < _counts[type]!;
        lines.add('  $name${optional ? '?' : ''}: ${types.join(' | ')};');
      }
      lines.add('}');
    }
    if (server) {
      lines.addAll([
        '',
        '/** A page of a query: its index from 0 and its size. */',
        'export interface TomPageRequest {',
        '  page: number;',
        '  size: number;',
        '}',
        '',
        '/** The repository contract of `tom_core_server`, method by method. */',
        'export interface TomRepository<T, K> {',
        '  count(): Promise<number>;',
        '  delete(entity: T): Promise<void>;',
        '  deleteAllById(ids: K[]): Promise<number>;',
        '  deleteById(id: K): Promise<number>;',
        '  existsById(ids: K[]): Promise<boolean>;',
        '  findAll(page?: TomPageRequest): Promise<T[]>;',
        '  findAllById(ids: K[], page?: TomPageRequest): Promise<T[]>;',
        '  findById(id: K): Promise<T | null>;',
        '  save(toSave: T): Promise<T>;',
        '  saveAll(entities: T[]): Promise<T[]>;',
        '}',
      ]);
    }
    return _banner(lines);
  }
}

// ---------------------------------------------------------------------------
// One file
// ---------------------------------------------------------------------------

class _FileWriter {
  final IrFile file;
  final String area;
  final CsLocus locus;
  final String package;
  final String module;
  final _Symbols symbols;
  final _TomTypes tom;
  final Set<String> used = {};
  final Set<String> declared = {};
  final Set<String> external = {};

  _FileWriter({
    required this.file,
    required this.area,
    required this.locus,
    required this.package,
    required this.module,
    required this.symbols,
    required this.tom,
  });

  late final IrIndex _index = IrIndex([
    IrDocument(area: area, projects: const [], files: [file]),
  ]);

  String render() {
    final body = <String>[];
    for (final e in _index.topLevel) {
      body
        ..add('')
        ..addAll(_declaration(e));
    }
    final banner = [
      for (final c in file.file.comments)
        if (c.isBanner) c.text,
    ];
    return '${[...banner, ..._imports(), ...body].join('\n')}\n';
  }

  List<String> _imports() {
    final byModule = <String, ({Set<String> types, Set<String> values})>{};
    for (final name in used.difference(declared)) {
      final s = symbols.byName[name];
      final String from;
      final _Kind kind;
      if (s != null) {
        from = s.package == package ? _relative(module, s.module) : s.package;
        kind = s.kind;
      } else if (name.startsWith('Tom')) {
        from = _relative(module, 'src/tom/tom.ts');
        kind = _Kind.type;
      } else {
        continue;
      }
      final entry = byModule.putIfAbsent(
        from,
        () => (types: <String>{}, values: <String>{}),
      );
      (kind == _Kind.type ? entry.types : entry.values).add(name);
    }
    final lines = <String>[];
    for (final ext in external.toList()..sort()) {
      lines.add(ext);
    }
    for (final from in byModule.keys.toList()..sort()) {
      final e = byModule[from]!;
      if (e.values.isNotEmpty) {
        lines.add(
          "import { ${(e.values.toList()..sort()).join(', ')} } from '$from';",
        );
      }
      if (e.types.isNotEmpty) {
        lines.add(
          "import type { ${(e.types.toList()..sort()).join(', ')} } from '$from';",
        );
      }
    }
    return lines.isEmpty ? const [] : ['', ...lines];
  }

  List<String> _declaration(IrEntry e) {
    final d = e.declaration;
    final members = _index.membersOf(e);
    declared.add(d.name);
    final typeParameters = _typeParameterNames(d.typeParameters);
    final head = _jsDoc(d, indent: '');
    switch (_declarationShape(_index, e)) {
      case IrShape.catalogue:
        final entries = d.kind == CsDeclarationKind.enumType
            ? [
                for (final m in members)
                  if (m.kind == CsDeclarationKind.field) (m, m.name),
              ]
            : [for (final m in members) (m, _catalogueValue(m)!)];
        return [
          ...head,
          'export const ${d.name} = {',
          for (final (m, v) in entries) ...[
            ..._jsDoc(m, indent: '  '),
            '  ${m.name}: ${jsonEncode(v)},',
          ],
          '} as const;',
          '',
          '/** A value of [${d.name}]. */',
          'export type ${d.name} = (typeof ${d.name})[keyof typeof ${d.name}];',
        ];
      case IrShape.plainData:
        return [
          ...head,
          'export interface ${d.name}${d.typeParameters ?? ''} {',
          for (final m in members)
            if (m.kind == CsDeclarationKind.field) ...[
              ..._jsDoc(m, indent: '  '),
              '  ${m.name}: ${_tsType(m.declaredType ?? 'Object', typeParameters, used)};',
            ],
          '}',
        ];
      case IrShape.entity:
        return _entity(e, members, head);
      case IrShape.layout:
        declared.add('${d.name}View');
        external.add("import type { ReactElement } from 'react';");
        final cs = irMarker(d, 'CsLayout');
        final id = irString(cs?.positional.firstOrNull) ?? d.name;
        return [
          ...head,
          'export class ${d.name} {',
          ..._fields(e, members, typeParameters),
          '}',
          '',
          '/** The React component of [${d.name}]: written in Phase 6. */',
          'export function ${d.name}View(): ReactElement {',
          '  throw new Error(${jsonEncode('not implemented: layout $id')});',
          '}',
        ];
      case IrShape.contract:
        final superclass = d.superclass;
        final extendsClause = superclass == null
            ? ''
            : ' extends ${_tsType(superclass, typeParameters, used)}';
        final methods = [
          for (final m in members)
            if (m.kind == CsDeclarationKind.method)
              for (final b in m.bodies)
                if (b.name == m.name) ...[
                  ..._jsDoc(m, indent: '  '),
                  '  ${m.name}(${_parameters(b, typeParameters)}): '
                      '${_tsType(b.returnType ?? 'void', typeParameters, used)};',
                ],
        ];
        return [
          ...head,
          if (methods.isEmpty)
            'export interface ${d.name}${d.typeParameters ?? ''}$extendsClause {}'
          else ...[
            'export interface ${d.name}${d.typeParameters ?? ''}$extendsClause {',
            ...methods,
            '}',
          ],
        ];
      case IrShape.classType || IrShape.serviceUnit:
        return [
          ...head,
          'export ${d.isAbstract ? 'abstract ' : ''}class ${d.name}'
              '${d.typeParameters ?? ''} {',
          ..._fields(e, members, typeParameters),
          for (final m in members)
            if (m.kind == CsDeclarationKind.method)
              ..._method(e, m, typeParameters),
          '}',
        ];
      case IrShape.variable:
        final c = file.file.constructions
            .where((c) => c.holder == d.name)
            .firstOrNull;
        final type = d.declaredType == null
            ? ''
            : ': ${_tsType(d.declaredType!, typeParameters, used)}';
        final value = c == null
            ? _initialiser(d)
            : tom.construction(c, symbols, used);
        if (c != null) used.add(c.type);
        return [...head, 'export const ${d.name}$type = $value;'];
    }
  }

  List<String> _fields(
    IrEntry e,
    List<CsDeclaration> members,
    Set<String> typeParameters,
  ) => [
    for (final m in members)
      if (m.kind == CsDeclarationKind.field) ...[
        ..._jsDoc(m, indent: '  '),
        _field(e, m, typeParameters),
      ],
  ];

  String _field(IrEntry e, CsDeclaration m, Set<String> typeParameters) {
    final type = _tsType(m.declaredType ?? 'Object', typeParameters, used);
    final c = file.file.constructions
        .where((c) => c.holder == '${e.declaration.name}.${m.name}')
        .firstOrNull;
    final modifiers =
        '${m.isStatic ? 'static ' : ''}${m.isFinal ? 'readonly ' : ''}';
    if (c != null) {
      used.add(c.type);
      return '  $modifiers${m.name}: $type = ${tom.construction(c, symbols, used)};';
    }
    if (m.hasInitialiser) {
      return '  $modifiers${m.name}: $type = ${_initialiser(m)};';
    }
    // `late`: assigned before use, as in the Dart.
    return '  $modifiers${m.name}!: $type;';
  }

  String _initialiser(CsDeclaration d) {
    final s = irInitialiserString(d);
    if (s != null) return jsonEncode(s);
    throw IrMapException(
      '${file.file.path}: the initialiser of ${d.name} '
      '(`${d.initialiser}`) has no TypeScript form',
    );
  }

  String _parameters(CsMethodBody b, Set<String> typeParameters) => [
    for (final p in b.parameters)
      '${p.name}${p.kind == CsParameterKind.optionalPositional || p.kind == CsParameterKind.optionalNamed ? '?' : ''}: '
          '${_tsType(p.type ?? 'Object', typeParameters, used)}',
  ].join(', ');

  List<String> _method(IrEntry e, CsDeclaration m, Set<String> typeParameters) {
    final b = m.bodies.where((b) => b.name == m.name).firstOrNull;
    if (b == null) return const [];
    final record = file.steps
        .where((r) => r.owner == e.declaration.name && r.body == m.name)
        .firstOrNull;
    final returnType = _tsType(b.returnType ?? 'void', typeParameters, used);
    final signature =
        '  ${b.isAsync ? 'async ' : ''}${m.name}(${_parameters(b, typeParameters)}): $returnType {';
    final List<String> body;
    if (record?.steps case final steps?) {
      body = _steps(steps, '    ', b.isAsync);
    } else {
      final message = b.thrownMessage ?? b.thrownLiteral ?? m.name;
      body = [
        '    throw new Error(${jsonEncode('not implemented: $message')});',
      ];
    }
    return ['', ..._jsDoc(m, indent: '  '), signature, ...body, '  }'];
  }

  /// A 3b body from its steps (`irspecs_ir.md` §4.7).
  List<String> _steps(List<IrStep> steps, String indent, bool isAsync) {
    final aw = isAsync ? 'await ' : '';
    String call(String method, List<String> args) =>
        'this.collaborator.$method(${args.join(', ')})';
    return [
      for (final s in steps)
        ...switch (s) {
          IrCallStep(:final method, :final arguments) => [
            '$indent$aw${call(method, arguments)};',
          ],
          IrReturnStep(:final method, :final arguments) => [
            method == null
                ? '${indent}return;'
                : '${indent}return ${call(method, arguments)};',
          ],
          IrGuardedStep(:final guard, :final arguments, :final steps) => [
            '${indent}if ($aw${call(guard, arguments)}) {',
            ..._steps(steps, '$indent  ', isAsync),
            '$indent}',
          ],
        },
    ];
  }

  List<String> _entity(
    IrEntry e,
    List<CsDeclaration> members,
    List<String> head,
  ) {
    final d = e.declaration;
    final shape = symbols.tables[d.name]!;
    final table = shape.table;
    final builders = <String>{};
    final columns = <String>[];
    final pk = shape.primaryKey;
    if (pk != null) shape.keyColumns(pk);
    final singlePk = pk != null && pk.columns.length == 1
        ? pk.columns.single
        : null;
    for (final m in members) {
      if (m.kind != CsDeclarationKind.field || m.isStatic) continue;
      final col = irMarker(m, 'CsColumn');
      final name = irString(col?.named['column']) ?? irSnake(m.name);
      final sqlType = irString(col?.named['columnType']);
      final type = m.declaredType ?? 'String';
      final (builder, call) = _column(name, sqlType, type);
      builders.add(builder);
      var chain = call;
      final dartType = type.endsWith('?')
          ? type.substring(0, type.length - 1)
          : type;
      if (symbols.enums.contains(dartType)) {
        used.add(dartType);
        chain += '.\$type<$dartType>()';
      }
      if (!type.endsWith('?')) chain += '.notNull()';
      if (name == singlePk) chain += _generation(pk!, builder);
      columns
        ..addAll(_jsDoc(m, indent: '  '))
        ..add('  ${m.name}: $chain,');
    }
    final constraints = _constraints(shape, builders);
    builders.add('pgTable');
    external.add(
      "import { ${(builders.toList()..sort()).join(', ')} } from 'drizzle-orm/pg-core';",
    );
    final tableConst = _tableName(d.name);
    declared
      ..add(tableConst)
      ..add(d.name);
    return [
      ...head,
      'export const $tableConst = pgTable(',
      '  ${jsonEncode(table)},',
      '  {',
      for (final c in columns) '  $c',
      if (constraints.isEmpty)
        '  },'
      else ...[
        '  },',
        '  (t) => [',
        for (final c in constraints) '    $c,',
        '  ],',
      ],
      ');',
      '',
      '/** A row of [$tableConst]. */',
      'export type ${d.name} = typeof $tableConst.\$inferSelect;',
    ];
  }

  /// The column default of a single-column primary key's generation
  /// (codespecs_derivation_contract.md §3.3.11): `defaultRandom()` for `uuid`, an identity for `auto`, the
  /// sequence for `sequence`; `ulid`, `custom` and `natural` are the
  /// application's.
  String _generation(IrTableKey pk, String builder) {
    switch (pk.generation) {
      case 'uuid' when builder == 'uuid':
        return '.defaultRandom()';
      case 'auto':
        return '.generatedByDefaultAsIdentity()';
      case 'sequence' when pk.sequenceName != null:
        external.add("import { sql } from 'drizzle-orm';");
        return ".default(sql`nextval('${pk.sequenceName}')`)";
      default:
        return '';
    }
  }

  /// The table-level entries of [t]: the named primary key, the alternate
  /// keys as unique constraints, the foreign keys and the indexes
  /// (codespecs_derivation_contract.md §3.3.11). Drizzle has no deferrable constraint, no covering index and
  /// no clustering: the migration DDL the other server mappers write carries
  /// those.
  List<String> _constraints(IrEntityTable t, Set<String> builders) {
    String props(List<IrColumn> cs) =>
        cs.map((c) => 't.${c.member.name}').join(', ');
    final out = <String>[];
    final pk = t.primaryKey;
    if (pk != null) {
      builders.add('primaryKey');
      out.add(
        'primaryKey({ name: ${jsonEncode(pk.name)}, '
        'columns: [${props(t.keyColumns(pk))}] })',
      );
    }
    for (final k in t.alternateKeys) {
      builders.add('unique');
      out.add('unique(${jsonEncode(k.name)}).on(${props(t.keyColumns(k))})');
    }
    for (final k in t.foreignKeys) {
      final target = irReferencedTable(t, k, symbols.tables.values);
      final referenced = irReferencedColumns(t, k, symbols.tables.values);
      final targetConst = _tableName(target.entity);
      if (target.entity != t.entity) used.add(targetConst);
      final foreign = [
        for (final c in referenced)
          '${target.entity == t.entity ? 't' : targetConst}.'
              '${(target.column(c) ?? (throw IrMapException("@CsTableKey('${k.name}') of ${t.entity} references column '$c' of ${target.entity}, which no @CsColumn declares"))).member.name}',
      ];
      builders.add('foreignKey');
      out.add(
        'foreignKey({ name: ${jsonEncode(k.name)}, '
        'columns: [${props(t.keyColumns(k))}], '
        'foreignColumns: [${foreign.join(', ')}] })'
        '${k.onDelete == null ? '' : ".onDelete('${_action(k.onDelete!)}')"}'
        '${k.onUpdate == null ? '' : ".onUpdate('${_action(k.onUpdate!)}')"}',
      );
    }
    for (final x in t.indexes) {
      final columns = [
        for (final (i, c) in x.columns.indexed)
          't.${(t.column(c) ?? (throw IrMapException("@CsTableIndex('${x.name}') of ${t.entity} names column '$c', which no @CsColumn of ${t.entity} declares"))).member.name}'
              '${x.isDescending(i) ? '.desc()' : ''}',
      ];
      final builder = x.isUnique == true ? 'uniqueIndex' : 'index';
      builders.add(builder);
      var chain = '$builder(${jsonEncode(x.name)})';
      chain += x.indexType == null
          ? '.on(${columns.join(', ')})'
          : ".using('${irSqlIndexMethod(x.indexType!)}', ${columns.join(', ')})";
      if (x.filterCondition != null) {
        external.add("import { sql } from 'drizzle-orm';");
        chain += '.where(sql`${x.filterCondition}`)';
      }
      out.add(chain);
    }
    return out;
  }

  /// Drizzle's spelling of a `CsReferentialAction`.
  String _action(String action) => switch (action) {
    'cascade' => 'cascade',
    'setNull' => 'set null',
    'restrict' => 'restrict',
    'noAction' => 'no action',
    'setDefault' => 'set default',
    _ => throw IrMapException('the referential action `$action` has no rule'),
  };

  /// The Drizzle column builder for a SQL type as written, else for the Dart
  /// type.
  (String, String) _column(String name, String? sqlType, String dartType) {
    final n = jsonEncode(name);
    final sql = sqlType?.trim().toLowerCase();
    if (sql != null) {
      final varchar = RegExp(r'^varchar\((\d+)\)$').firstMatch(sql);
      if (varchar != null) {
        return ('varchar', 'varchar($n, { length: ${varchar.group(1)} })');
      }
      final numeric = RegExp(
        r'^(?:numeric|decimal)\((\d+),\s*(\d+)\)$',
      ).firstMatch(sql);
      if (numeric != null) {
        return (
          'numeric',
          'numeric($n, { precision: ${numeric.group(1)}, scale: ${numeric.group(2)} })',
        );
      }
      switch (sql) {
        case 'uuid':
          return ('uuid', 'uuid($n)');
        case 'text':
          return ('text', 'text($n)');
        case 'integer' || 'int' || 'int4':
          return ('integer', 'integer($n)');
        case 'bigint' || 'int8':
          return ('bigint', "bigint($n, { mode: 'number' })");
        case 'boolean' || 'bool':
          return ('boolean', 'boolean($n)');
        case 'date':
          return ('date', 'date($n)');
        case 'jsonb':
          return ('jsonb', 'jsonb($n)');
        case 'timestamptz' || 'timestamp with time zone':
          return ('timestamp', 'timestamp($n, { withTimezone: true })');
        case 'timestamp':
          return ('timestamp', 'timestamp($n)');
      }
      throw IrMapException('the column type `$sqlType` has no Drizzle builder');
    }
    final t = dartType.replaceAll('?', '');
    return switch (t) {
      'int' => ('integer', 'integer($n)'),
      'double' || 'num' => ('doublePrecision', 'doublePrecision($n)'),
      'bool' => ('boolean', 'boolean($n)'),
      'DateTime' => ('timestamp', 'timestamp($n, { withTimezone: true })'),
      _ => ('text', 'text($n)'),
    };
  }

  /// The JSDoc of [d]: its doc comment, then its back-links and markers as
  /// tags (`irspecs_ir.md` §11) — the same section ids the Dart trio carries.
  List<String> _jsDoc(CsDeclaration d, {required String indent}) {
    final lines = <String>[
      for (final l in d.docComment?.lines ?? const <String>[])
        l.trimLeft().replaceFirst(RegExp(r'^/// ?'), ''),
    ];
    final tags = <String>[
      if (d.codeSpec case final cs?)
        '@codeSpec ${cs.id}${cs.source.isEmpty ? '' : ' source: ${cs.source.join(', ')}'}',
      for (final r in d.docSpec ?? const <CsDocRef>[])
        '@docSpec ${r.sectionId} — ${r.description}',
      for (final m in d.markers) '@cs ${irMarkerSource(m)}',
      for (final a in d.annotations) '@dart ${a.source}',
    ];
    if (lines.isEmpty && tags.isEmpty) return const [];
    final all = [
      ...lines,
      if (lines.isNotEmpty && tags.isNotEmpty) '',
      ...tags,
    ];
    return [
      '$indent/**',
      for (final l in all)
        l.isEmpty ? '$indent *' : '$indent * ${l.replaceAll('*/', '*\\/')}',
      '$indent */',
    ];
  }
}

String _relative(String from, String to) {
  final fromDir = from.split('/')..removeLast();
  final toParts = to.split('/');
  var common = 0;
  while (common < fromDir.length &&
      common < toParts.length - 1 &&
      fromDir[common] == toParts[common]) {
    common++;
  }
  final ups = fromDir.length - common;
  final rest = toParts.sublist(common).join('/');
  return ups == 0 ? './$rest' : '${'../' * ups}$rest';
}

// ---------------------------------------------------------------------------
// The API client and the routes, from the OpenAPI document
// ---------------------------------------------------------------------------

String _apiClient(
  Map<String, dynamic> openApi,
  _Symbols symbols,
  String package,
  String module,
) {
  final used = <String>{};
  final methods = <String>[];
  for (final o in openApiOperations(openApi)) {
    final request = o.request ?? 'unknown';
    final value = o.response ?? 'unknown';
    if (o.request != null) used.add(o.request!);
    if (o.response != null) used.add(o.response!);
    if (o.enveloped) used.add(kResultEnvelope);
    final result = o.enveloped ? '$kResultEnvelope<$value>' : value;
    methods.addAll([
      '',
      '  /** `POST ${o.path}` (`${o.op}`). */',
      '  async ${o.op}(request: $request): Promise<$result> {',
      '    return this.post(${jsonEncode(o.path)}, request) as Promise<$result>;',
      '  }',
    ]);
  }
  return _banner([
    ..._importLines(used, symbols, package, module),
    '',
    '/**',
    ' * The server\'s operations as calls (`irspecs_ir.md` §11): every one a',
    ' * `POST` of its request, its answer the Result envelope; only a 5xx status',
    ' * is a transport error (codespecs_mapping.md §7).',
    ' */',
    'export class ApiClient {',
    '  readonly baseUrl: string;',
    '  readonly fetchImpl: typeof fetch;',
    '',
    '  constructor(baseUrl: string, fetchImpl: typeof fetch = fetch) {',
    '    this.baseUrl = baseUrl;',
    '    this.fetchImpl = fetchImpl;',
    '  }',
    '',
    '  private async post(path: string, body: unknown): Promise<unknown> {',
    '    const response = await this.fetchImpl(`\${this.baseUrl}\${path}`, {',
    "      method: 'POST',",
    "      headers: { 'content-type': 'application/json' },",
    '      body: JSON.stringify(body),',
    '    });',
    '    if (response.status >= 500) {',
    '      throw new Error(`transport error \${response.status} on \${path}`);',
    '    }',
    '    return response.json();',
    '  }',
    ...methods,
    '}',
  ]);
}

String _honoApp(
  Map<String, dynamic> openApi,
  List<IrDocument> documents,
  _Symbols symbols,
  String package,
  String module,
) {
  // The service unit holding each operation's handler (CE-SU).
  final handlerOwner = <String, String>{};
  final index = IrIndex(documents);
  for (final e in index.inArea('CE-SU')) {
    for (final m in index.membersOf(e)) {
      final op = irString(irMarker(m, 'CsEndpoint')?.positional.firstOrNull);
      if (op != null) handlerOwner[op] = e.declaration.name;
    }
  }
  final used = <String>{};
  final services = <String>{};
  final routes = <String>[];
  for (final o in openApiOperations(openApi)) {
    final owner = handlerOwner[o.op];
    if (owner == null) continue;
    services.add(owner);
    final request = o.request ?? 'unknown';
    if (o.request != null) used.add(o.request!);
    routes.addAll([
      '  app.post(${jsonEncode(o.path)}, async (c) =>',
      '    c.json(await services.${_lower(owner)}.${o.op}(await c.req.json<$request>())),',
      '  );',
    ]);
  }
  used.addAll(services);
  return _banner([
    "import { Hono } from 'hono';",
    ..._importLines(used, symbols, package, module),
    '',
    '/** The service units the routes call, one each. */',
    'export interface Services {',
    for (final s in services.toList()..sort()) '  ${_lower(s)}: $s;',
    '}',
    '',
    '/**',
    ' * The Hono app: every operation a `POST` to its service unit\'s handler',
    ' * (`irspecs_ir.md` §11, codespecs_mapping.md §7).',
    ' */',
    'export function createApp(services: Services): Hono {',
    '  const app = new Hono();',
    ...routes,
    '  return app;',
    '}',
  ]);
}

String _lower(String s) => '${s[0].toLowerCase()}${s.substring(1)}';

List<String> _importLines(
  Set<String> used,
  _Symbols symbols,
  String package,
  String module,
) {
  final byFrom = <String, ({Set<String> types, Set<String> values})>{};
  for (final name in used) {
    final s = symbols.byName[name];
    if (s == null) continue;
    final from = s.package == package ? _relative(module, s.module) : s.package;
    final e = byFrom.putIfAbsent(
      from,
      () => (types: <String>{}, values: <String>{}),
    );
    (s.kind == _Kind.type || s.package != package ? e.types : e.values).add(
      name,
    );
  }
  return [
    for (final from in byFrom.keys.toList()..sort()) ...[
      if (byFrom[from]!.values.isNotEmpty)
        "import { ${(byFrom[from]!.values.toList()..sort()).join(', ')} } from '$from';",
      if (byFrom[from]!.types.isNotEmpty)
        "import type { ${(byFrom[from]!.types.toList()..sort()).join(', ')} } from '$from';",
    ],
  ];
}

// ---------------------------------------------------------------------------
// The mobile client's navigator (irspecs_ir.md §11.2)
// ---------------------------------------------------------------------------

/// The routes of the client locus of [share]: every top-level
/// `TomRouteDefinition` construction, in IR order, with the module that
/// declares it.
List<({String name, String routeId, String path, List<String> parameters})>
_routes(List<IrDocument> share) => [
  for (final d in share)
    for (final f in d.files)
      if (f.locus == CsLocus.client)
        for (final c in f.file.constructions)
          if (c.type == 'TomRouteDefinition')
            if (c.holder case final holder? when !holder.contains('.'))
              (
                name: holder,
                routeId:
                    irString(c.named['routeId']) ??
                    (throw IrMapException(
                      '${f.file.path}: the route ${c.holder} has no routeId',
                    )),
                path: irString(c.named['path']) ?? '',
                parameters: [
                  if (c.named['parameters'] case CsListValue(:final values))
                    for (final v in values) ?irString(v),
                ],
              ),
];

/// `orderWorkListRoute` → `OrderWorkListScreen`.
String _screenName(String route) {
  final base = route.endsWith('Route')
      ? route.substring(0, route.length - 'Route'.length)
      : route;
  return '${base[0].toUpperCase()}${base.substring(1)}Screen';
}

/// `navigation/app_navigator.ts`: the React Navigation stack of the routes —
/// the param list (a route's parameters as strings), a screen per route that
/// throws until Phase 6 writes it, and the navigator — written with
/// `createElement`, so the package needs no JSX transform.
String _appNavigator(List<IrDocument> share) {
  final routes = _routes(share);
  if (routes.isEmpty) {
    throw IrMapException(
      'the React Native client has no route (CE-NV `TomRouteDefinition`) to '
      'make a screen of',
    );
  }
  return _banner([
    "import { createElement, type ReactElement } from 'react';",
    "import { NavigationContainer } from '@react-navigation/native';",
    "import { createNativeStackNavigator } from '@react-navigation/native-stack';",
    '',
    '/** The screens\' parameters, one entry per route (CE-NV). */',
    'export type RootStackParamList = {',
    for (final r in routes)
      r.parameters.isEmpty
          ? '  ${jsonEncode(r.routeId)}: undefined;'
          : '  ${jsonEncode(r.routeId)}: { ${[for (final p in r.parameters) '$p: string'].join('; ')} };',
    '};',
    '',
    'const Stack = createNativeStackNavigator<RootStackParamList>();',
    for (final r in routes) ...[
      '',
      '/** The screen of `${r.name}` (`${r.path}`): written in Phase 6. */',
      'export function ${_screenName(r.name)}(): ReactElement {',
      '  throw new Error(${jsonEncode('not implemented: screen ${r.routeId}')});',
      '}',
    ],
    '',
    '/** The app: a native stack of the screens, the first route first. */',
    'export function AppNavigator(): ReactElement {',
    '  return createElement(',
    '    NavigationContainer,',
    '    null,',
    '    createElement(',
    '      Stack.Navigator,',
    '      null,',
    for (final r in routes)
      '      createElement(Stack.Screen, { name: ${jsonEncode(r.routeId)}, component: ${_screenName(r.name)} }),',
    '    ),',
    '  );',
    '}',
  ]);
}
