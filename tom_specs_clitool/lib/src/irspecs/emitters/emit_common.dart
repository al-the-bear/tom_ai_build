/// What the standard emitters share (`irspecs_ir.md` §10): the result of an
/// emission, a read-only index over an IR document set, and the JSON Schema
/// builder the JSON Schema and OpenAPI emitters both write their schemas with.
library;

import 'dart:convert';

import '../../codespecs/cs_model.dart';
import '../ir_model.dart';

/// What an emitter wrote, and what it could not say.
class IrEmission {
  /// The files written, `<path relative to --out>` → text.
  final Map<String, String> files;

  /// Every fact of the IR the standard has no form for, one line each, in the
  /// order met (`irspecs_ir.md` §10.2). Nothing is dropped without a line here.
  final List<String> notExpressed;

  /// Creates an emission.
  const IrEmission(this.files, this.notExpressed);
}

/// A JSON document as the emitters write it: two-space indented, one trailing
/// newline.
String irJson(Object? data) =>
    '${const JsonEncoder.withIndent('  ').convert(data)}\n';

/// One declaration of the IR with the area and file it sits in.
class IrEntry {
  /// The area code of the document it was read from.
  final String area;

  /// The file it is declared in.
  final IrFile file;

  /// The declaration.
  final CsDeclaration declaration;

  /// Creates an entry.
  const IrEntry(this.area, this.file, this.declaration);
}

/// A read-only index over an IR document set.
class IrIndex {
  /// The documents, as read.
  final List<IrDocument> documents;

  /// Every top-level declaration, in document then file then source order.
  final List<IrEntry> topLevel = [];

  final Map<String, List<CsDeclaration>> _members = {};

  /// Indexes [documents].
  IrIndex(this.documents) {
    for (final d in documents) {
      for (final f in d.files) {
        for (final decl in f.file.declarations) {
          if (decl.owner == null) {
            topLevel.add(IrEntry(d.area, f, decl));
          } else {
            _members
                .putIfAbsent('${f.file.path}#${decl.owner}', () => [])
                .add(decl);
          }
        }
      }
    }
  }

  /// The members of [entry]'s declaration, in source order.
  List<CsDeclaration> membersOf(IrEntry entry) =>
      _members['${entry.file.file.path}#${entry.declaration.name}'] ?? const [];

  /// The top-level declarations of [area].
  Iterable<IrEntry> inArea(String area) =>
      topLevel.where((e) => e.area == area);

  /// The documents' title: the shared project's package name, else the first
  /// project's, else `irspecs`.
  String get title {
    for (final d in documents) {
      for (final p in d.projects) {
        if (p.locus == CsLocus.shared) return p.packageName;
      }
    }
    for (final d in documents) {
      if (d.projects.isNotEmpty) return d.projects.first.packageName;
    }
    return 'irspecs';
  }
}

/// The marker named [name] on [d], or `null`.
CsMarker? irMarker(CsDeclaration d, String name) {
  for (final m in d.markers) {
    if (m.name == name) return m;
  }
  return null;
}

/// A marker argument's string value: a string, a qualified name's `name`, a
/// construction's single string argument; `null` otherwise.
String? irString(CsValue? v) => switch (v) {
  CsStringValue(:final value) => value,
  CsQualifiedValue(:final name) => name,
  CsConstructionValue(:final positional) when positional.length == 1 =>
    irString(positional.single),
  _ => null,
};

/// The single string argument of an initialiser such as
/// `CsMessageKey('screen.orders.title')`, or `null`.
String? irInitialiserString(CsDeclaration d) {
  final init = d.initialiser;
  if (init == null) return null;
  final m = RegExp(r'''^\w+\(\s*(['"])(.*)\1\s*\)$''').firstMatch(init);
  return m?.group(2);
}

/// A declaration's `///` doc comment as text: the `///` and one following
/// space removed from each line, the block trimmed; `null` when it has none.
String? irDocText(CsDeclaration d) {
  final c = d.docComment;
  if (c == null) return null;
  final text = [
    for (final l in c.lines) l.trimLeft().replaceFirst(RegExp(r'^/// ?'), ''),
  ].join('\n').trim();
  return text.isEmpty ? null : text;
}

/// The closed `@CsValidation` rule tokens (`codespecs_mapping.md` §5.19)
/// and the JSON Schema keyword each becomes.
const Map<String, String> irValidationKeywords = {
  'email': 'format',
  'minLength': 'minLength',
  'maxLength': 'maxLength',
  'pattern': 'pattern',
  'min': 'minimum',
  'max': 'maximum',
  'minItems': 'minItems',
  'maxItems': 'maxItems',
};

/// Builds JSON Schema 2020-12 schemas from IR declarations
/// (`irspecs_ir.md` §10.1): enums from CE-EN, the error-code catalogue and the
/// envelope from CE-ER, the wire types from CE-API, the entities from CE-DB,
/// with the `@CsValidation` rules of their fields.
class IrSchemaBuilder {
  /// Where a reference points: `#/$defs/` for a JSON Schema document,
  /// `#/components/schemas/` for an OpenAPI document.
  final String refBase;

  /// The index the schemas are built from.
  final IrIndex index;

  /// Every fact a schema could not carry (`IrEmission.notExpressed`).
  final List<String> notExpressed;

  /// The schemas, by declaration name, in the order built.
  final Map<String, Map<String, Object?>> defs = {};

  final Set<String> _typeParameters = {};

  /// Creates a builder over [index].
  IrSchemaBuilder(
    this.index, {
    required this.refBase,
    required this.notExpressed,
  });

  /// The declaration names a schema is built for, by area, in this order.
  static const List<String> areas = ['CE-EN', 'CE-ER', 'CE-API', 'CE-DB'];

  /// Builds every schema; returns [defs].
  Map<String, Map<String, Object?>> build() {
    final names = <String>{
      for (final area in areas)
        for (final e in index.inArea(area))
          if (_isSchemaType(e)) e.declaration.name,
    };
    for (final area in areas) {
      for (final e in index.inArea(area)) {
        if (!_isSchemaType(e)) continue;
        defs[e.declaration.name] = _schemaOf(e, names);
      }
    }
    return defs;
  }

  /// The schema of one field type as written, outside any `$defs`: a named
  /// type it cannot reference is reported in [notExpressed].
  Map<String, Object?> fieldSchema(String type, String where) =>
      _typeSchema(type, const {}, where);

  /// Whether [e] becomes a schema: an enum, a class with fields, or the
  /// error-code catalogue — never an operation catalogue, a repository or a
  /// role catalogue.
  bool _isSchemaType(IrEntry e) {
    final d = e.declaration;
    if (d.kind == CsDeclarationKind.enumType) return true;
    if (d.kind != CsDeclarationKind.classType) return false;
    final members = index.membersOf(e);
    if (members.any((m) => irMarker(m, 'CsEndpoint') != null)) return false;
    if (irMarker(d, 'CsRepository') != null) return false;
    if (irMarker(d, 'CsError') != null) return true;
    return members.any((m) => m.kind == CsDeclarationKind.field && !m.isStatic);
  }

  Map<String, Object?> _schemaOf(IrEntry e, Set<String> names) {
    final d = e.declaration;
    final members = index.membersOf(e);
    final doc = irDocText(d);
    if (d.kind == CsDeclarationKind.enumType) {
      return {
        'title': d.name,
        'description': ?doc,
        'enum': [
          for (final m in members)
            if (m.kind == CsDeclarationKind.field) m.name,
        ],
      };
    }
    if (irMarker(d, 'CsError') != null) {
      final codes = <String>[];
      for (final m in members) {
        final code = irInitialiserString(m);
        if (code == null) continue;
        codes.add(code);
        final severity = irString(irMarker(m, 'CsError')?.named['severity']);
        if (severity != null) {
          notExpressed.add(
            '${e.area} ${d.name}.${m.name}: the severity `$severity` of error '
            'code $code (an enum value carries no attributes)',
          );
        }
      }
      return {
        'title': d.name,
        'description': ?doc,
        'type': 'string',
        'enum': codes,
      };
    }
    _typeParameters
      ..clear()
      ..addAll(_parameterNames(d.typeParameters));
    final properties = <String, Object?>{};
    final required = <String>[];
    for (final m in members) {
      if (m.kind != CsDeclarationKind.field || m.isStatic) continue;
      final type = m.declaredType;
      if (type == null) {
        notExpressed.add('${e.area} ${d.name}.${m.name}: no declared type');
        continue;
      }
      final schema = _typeSchema(type, names, '${e.area} ${d.name}.${m.name}');
      final mDoc = irDocText(m);
      if (mDoc != null) schema['description'] = mDoc;
      if (_rules(m, schema, '${e.area} ${d.name}.${m.name}') ||
          !type.endsWith('?')) {
        required.add(m.name);
      }
      properties[m.name] = schema;
    }
    if (irMarker(d, 'CsTable') != null) {
      notExpressed.add(
        '${e.area} ${d.name}: the table, its columns\' SQL types and their '
        'sensitivity (storage, not wire shape)',
      );
    }
    return {
      'title': d.name,
      'description': ?doc,
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }

  /// Applies [m]'s `@CsValidation` rules to [schema]; returns whether they
  /// make the field required.
  bool _rules(CsDeclaration m, Map<String, Object?> schema, String where) {
    final rules = irString(irMarker(m, 'CsValidation')?.named['rules']);
    if (rules == null || rules.trim().isEmpty) return false;
    final target = schema.containsKey('anyOf')
        ? (schema['anyOf'] as List).first as Map<String, Object?>
        : schema;
    var required = false;
    for (final raw in rules.split(',')) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      final colon = token.indexOf(':');
      final name = colon < 0 ? token : token.substring(0, colon);
      final arg = colon < 0 ? null : token.substring(colon + 1);
      if (name == 'required') {
        required = true;
        continue;
      }
      final keyword = irValidationKeywords[name];
      if (keyword == null) {
        notExpressed.add(
          '$where: the validator `$token` (not a JSON Schema rule)',
        );
        continue;
      }
      if (name == 'email') {
        target['format'] = 'email';
      } else if (name == 'pattern') {
        target['pattern'] = arg ?? '';
      } else {
        final n = num.tryParse(arg ?? '');
        if (n == null) {
          notExpressed.add(
            '$where: the rule `$token` (its argument is no number)',
          );
          continue;
        }
        // A length or a count is an integer; a bound keeps the number written.
        target[keyword] = keyword == 'minimum' || keyword == 'maximum'
            ? n
            : n.toInt();
      }
    }
    return required;
  }

  /// The schema of a Dart type as written.
  Map<String, Object?> _typeSchema(
    String type,
    Set<String> names,
    String where,
  ) {
    var t = type.trim();
    if (t.endsWith('?')) {
      final inner = _typeSchema(t.substring(0, t.length - 1), names, where);
      if (inner.length == 1 && inner['type'] is String) {
        return {
          'type': [inner['type'], 'null'],
        };
      }
      return {
        'anyOf': [
          inner,
          {'type': 'null'},
        ],
      };
    }
    final generic = RegExp(r'^(\w+)<(.*)>$').firstMatch(t);
    if (generic != null) {
      final base = generic.group(1)!;
      final args = _splitTypeArguments(generic.group(2)!);
      if ((base == 'List' || base == 'Iterable') && args.length == 1) {
        return {'type': 'array', 'items': _typeSchema(args[0], names, where)};
      }
      if (base == 'Set' && args.length == 1) {
        return {
          'type': 'array',
          'uniqueItems': true,
          'items': _typeSchema(args[0], names, where),
        };
      }
      if (base == 'Map' && args.length == 2 && args[0].trim() == 'String') {
        return {
          'type': 'object',
          'additionalProperties': _typeSchema(args[1], names, where),
        };
      }
      notExpressed.add('$where: the type `$type`');
      return {};
    }
    switch (t) {
      case 'String':
        return {'type': 'string'};
      case 'int':
        return {'type': 'integer'};
      case 'double' || 'num':
        return {'type': 'number'};
      case 'bool':
        return {'type': 'boolean'};
      case 'DateTime':
        return {'type': 'string', 'format': 'date-time'};
      case 'Uri':
        return {'type': 'string', 'format': 'uri'};
      case 'Duration':
        return {'type': 'string', 'format': 'duration'};
      case 'Object' || 'dynamic' || 'Object?':
        return {};
    }
    if (_typeParameters.contains(t)) return {};
    if (names.contains(t)) return {r'$ref': '$refBase$t'};
    if (t.startsWith('Cs') &&
        (t.endsWith('Ref') || t.endsWith('Key') || t.endsWith('Code'))) {
      return {'type': 'string'};
    }
    notExpressed.add('$where: the type `$type` (no schema in the IR)');
    return {};
  }
}

/// The names of a class's type parameters (`<T, E extends Object>` → T, E).
List<String> _parameterNames(String? typeParameters) {
  if (typeParameters == null) return const [];
  final inner = typeParameters.trim();
  if (!inner.startsWith('<') || !inner.endsWith('>')) return const [];
  return [
    for (final p in _splitTypeArguments(inner.substring(1, inner.length - 1)))
      p.trim().split(RegExp(r'\s+')).first,
  ];
}

/// Splits `A, Map<B, C>` at its top-level commas.
List<String> _splitTypeArguments(String s) {
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '<') depth++;
    if (c == '>') depth--;
    if (c == ',' && depth == 0) {
      out.add(s.substring(start, i).trim());
      start = i + 1;
    }
  }
  out.add(s.substring(start).trim());
  return out;
}

/// The response type of a handler's `Future<Result<X>>` (or `Result<X>`,
/// `Future<X>`) return type: `X`, with whether it was wrapped in `Result`.
({String type, bool enveloped})? irHandlerResult(String? returnType) {
  if (returnType == null) return null;
  var t = returnType.trim();
  final future = RegExp(r'^Future<(.*)>$').firstMatch(t);
  if (future != null) t = future.group(1)!.trim();
  final result = RegExp(r'^Result<(.*)>$').firstMatch(t);
  if (result != null) return (type: result.group(1)!.trim(), enveloped: true);
  return (type: t, enveloped: false);
}
