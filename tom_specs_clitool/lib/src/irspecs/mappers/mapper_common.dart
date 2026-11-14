/// What the language mappers share (`irspecs_ir.md` §11–§14): how a top-level
/// declaration of the IR is classified, and how a Dart type's arguments are
/// split. Each mapper writes the shapes in its own language.
library;

import 'dart:convert';

import '../../codespecs/cs_model.dart';
import '../emitters/emit_common.dart';
import '../ir_model.dart';
import 'dart_tom/dart_tom_mapper.dart' show IrMapException;

/// What a top-level IR declaration is, whatever the language it is written in.
enum IrShape {
  /// An enum, or a class of `static const` string catalogue entries.
  catalogue,

  /// A class of instance fields only, not abstract: a wire type, the envelope.
  plainData,

  /// A `@CsTable` class.
  entity,

  /// A `@CsLayout` class.
  layout,

  /// A `@CsServiceUnit` class.
  serviceUnit,

  /// A collaborator or repository (`@CsCollaborator`, `@CsRepository`).
  contract,

  /// Any other class with members or bodies.
  classType,

  /// A top-level variable.
  variable,
}

/// The shape of [e], a top-level declaration of [index]. Throws
/// [IrMapException] for a declaration kind no mapper has a rule for (a mixin,
/// a top-level function), naming [mapper] and the file.
IrShape irDeclarationShape(IrIndex index, IrEntry e, {required String mapper}) {
  final d = e.declaration;
  if (d.kind == CsDeclarationKind.enumType) return IrShape.catalogue;
  if (d.kind == CsDeclarationKind.topLevelVariable) return IrShape.variable;
  if (d.kind != CsDeclarationKind.classType) {
    throw IrMapException(
      '${e.file.file.path}: ${d.name} is a ${d.kind.name}, which the '
      '$mapper have no rule for',
    );
  }
  if (irMarker(d, 'CsTable') != null) return IrShape.entity;
  if (irMarker(d, 'CsLayout') != null) return IrShape.layout;
  if (irMarker(d, 'CsServiceUnit') != null) return IrShape.serviceUnit;
  if (irMarker(d, 'CsCollaborator') != null ||
      irMarker(d, 'CsRepository') != null) {
    return IrShape.contract;
  }
  final members = index.membersOf(e);
  final fields = members.where((m) => m.kind == CsDeclarationKind.field);
  final methods = members.where((m) => m.kind == CsDeclarationKind.method);
  if (methods.isEmpty &&
      fields.isNotEmpty &&
      fields.every(
        (m) => m.isStatic && m.isConst && irInitialiserString(m) != null,
      )) {
    return IrShape.catalogue;
  }
  if (methods.isEmpty &&
      !d.isAbstract &&
      fields.isNotEmpty &&
      fields.every((m) => !m.isStatic)) {
    return IrShape.plainData;
  }
  return IrShape.classType;
}

/// The index of one file of [area], as a mapper writes one file at a time.
IrIndex irFileIndex(String area, IrFile file) => IrIndex([
  IrDocument(area: area, projects: const [], files: [file]),
]);

/// The top-level arguments of a type argument list as written:
/// `String, Map<String, int>` → `[String, Map<String, int>]`.
List<String> irSplitTypeArguments(String s) {
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '<') depth++;
    if (s[i] == '>') depth--;
    if (s[i] == ',' && depth == 0) {
      out.add(s.substring(start, i).trim());
      start = i + 1;
    }
  }
  out.add(s.substring(start).trim());
  return out;
}

/// The names of a type parameter list as written: `<T, U>` → `{T, U}`.
/// A bounded parameter (`T extends X`) is refused: no mapper has a rule for
/// it yet.
Set<String> irTypeParameterNames(String? typeParameters, String where) {
  if (typeParameters == null) return const {};
  final inner = typeParameters.trim();
  if (inner.length < 2) return const {};
  final names = <String>{};
  for (final p in irSplitTypeArguments(inner.substring(1, inner.length - 1))) {
    final parts = p.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      throw IrMapException(
        '$where: the bounded type parameter `$p` has no rule',
      );
    }
    names.add(parts.single);
  }
  return names;
}

/// `CamelCase` → `camel_case`.
String irSnake(String s) => s
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toLowerCase();

/// A `Cs*` marker as its Dart source reads, `CsEndpoint("amendOrderLine")`:
/// what every language mapper writes into the doc comment of the declaration
/// that carries it.
String irMarkerSource(CsMarker m) {
  String v(CsValue x) => switch (x) {
    CsStringValue(:final value) => jsonEncode(value),
    CsBoolValue(:final value) => '$value',
    CsIntValue(:final value) => '$value',
    CsNullValue() => 'null',
    CsQualifiedValue(:final prefix, :final name) => '$prefix.$name',
    CsListValue(:final values) => '[${values.map(v).join(', ')}]',
    CsConstructionValue(:final type, :final positional, :final named) =>
      '$type(${[...positional.map(v), for (final MapEntry(:key, :value) in named.entries) '$key: ${v(value)}'].join(', ')})',
    CsUnknownValue(:final source) => source,
  };
  return '${m.name}(${[...m.positional.map(v), for (final MapEntry(:key, :value) in m.named.entries) '$key: ${v(value)}'].join(', ')})';
}

// ---------------------------------------------------------------------------
// Server configuration (CE-CF)
// ---------------------------------------------------------------------------

/// One `@CsServerConfig` member of a CE-CF holder: the setting's key and its
/// default, which every server mapper writes into its language's own
/// configuration (`irspecs_ir.md` §11–§14).
class IrServerSetting {
  /// The setting key, `tenancy.isolation`.
  final String key;

  /// The default: a `String`, `int`, `double` or `bool`; `null` for a setting
  /// without one (a secret declares presence and shape only).
  final Object? value;

  /// Whether the setting's content is supplied out of band.
  final bool secret;

  /// The back-links of the member (`@DocSpec`), for the formats that carry a
  /// comment.
  final List<CsDocRef> docSpec;

  /// Creates a setting.
  const IrServerSetting(this.key, this.value, this.secret, this.docSpec);
}

/// Whether every top-level declaration of [file] is a CE-CF holder: a class
/// whose fields are all `@CsServerConfig` members. Such a file is written as
/// configuration ([irServerSettings]), never as a type.
bool irIsServerConfigFile(String area, IrFile file) {
  final index = irFileIndex(area, file);
  final top = index.topLevel.toList();
  if (top.isEmpty) return false;
  for (final e in top) {
    final fields = index
        .membersOf(e)
        .where((m) => m.kind == CsDeclarationKind.field)
        .toList();
    if (fields.isEmpty ||
        !fields.every((m) => irMarker(m, 'CsServerConfig') != null)) {
      return false;
    }
  }
  return true;
}

/// The settings of the CE-CF holders among [server], in file then source
/// order. Throws [IrMapException] for a default no configuration format can
/// carry (anything but a string, number or boolean literal).
List<IrServerSetting> irServerSettings(
  List<({String area, IrFile file})> server,
) {
  final out = <IrServerSetting>[];
  for (final f in server) {
    if (!irIsServerConfigFile(f.area, f.file)) continue;
    final index = irFileIndex(f.area, f.file);
    for (final e in index.topLevel) {
      for (final m in index.membersOf(e)) {
        final marker = irMarker(m, 'CsServerConfig');
        if (marker == null) continue;
        final key = irString(marker.positional.firstOrNull);
        if (key == null) {
          throw IrMapException(
            '${f.file.file.path}: @CsServerConfig on ${m.name} names no key',
          );
        }
        final secret = switch (marker.named['secret']) {
          CsBoolValue(:final value) => value,
          _ => false,
        };
        out.add(
          IrServerSetting(
            key,
            _settingValue(m, f.file.file.path),
            secret,
            m.docSpec ?? const [],
          ),
        );
      }
    }
  }
  return out;
}

Object? _settingValue(CsDeclaration m, String path) {
  final init = m.initialiser?.trim();
  if (init == null) return null;
  final string = RegExp(r'''^(['"])([^'"\\$]*)\1$''').firstMatch(init);
  if (string != null) return string.group(2);
  if (init == 'true' || init == 'false') return init == 'true';
  final number = num.tryParse(init);
  if (number != null) return number;
  throw IrMapException(
    '$path: the default of ${m.name} (`$init`) is no string, number or '
    'boolean literal, which is all a configuration file holds',
  );
}
