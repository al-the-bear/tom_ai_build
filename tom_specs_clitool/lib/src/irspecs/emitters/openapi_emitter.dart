/// The OpenAPI 3.1 emitter (`irspecs_ir.md` §10.1): every operation of the IR
/// as a POST (`codespecs_mapping.md` §7), its request the handler's parameter,
/// its response the `Result` envelope around the handler's value, 5xx the only
/// transport error; the types as `components.schemas`.
library;

import '../../codespecs/cs_model.dart';
import '../ir_model.dart';
import 'emit_common.dart';

/// The OpenAPI version the document is written in.
const String kOpenApiVersion = '3.1.0';

/// The file the OpenAPI emitter writes.
const String kOpenApiFile = 'openapi.json';

/// The name of the envelope type in CE-ER (`codespecs_mapping.md` §7).
const String kResultEnvelope = 'Result';

/// Emits [documents] as one OpenAPI 3.1 document, `openapi.json`.
IrEmission emitOpenApi(List<IrDocument> documents) {
  final index = IrIndex(documents);
  final notExpressed = <String>[];
  final schemas = IrSchemaBuilder(
    index,
    refBase: '#/components/schemas/',
    notExpressed: notExpressed,
  ).build();

  // The handlers (CE-SU) carry the signature; the catalogue (CE-API) the order
  // and the operation's doc comment.
  final handlers = <String, CsDeclaration>{};
  for (final e in index.inArea('CE-SU')) {
    for (final m in index.membersOf(e)) {
      final op = irString(irMarker(m, 'CsEndpoint')?.positional.firstOrNull);
      if (op != null) handlers.putIfAbsent(op, () => m);
    }
  }
  final catalogue = <String, CsDeclaration?>{};
  for (final e in index.inArea('CE-API')) {
    for (final m in index.membersOf(e)) {
      final op = irString(irMarker(m, 'CsEndpoint')?.positional.firstOrNull);
      if (op != null) catalogue.putIfAbsent(op, () => m);
    }
  }
  for (final op in handlers.keys) {
    catalogue.putIfAbsent(op, () => null);
  }

  final paths = <String, Object?>{};
  for (final MapEntry(key: op, value: entry) in catalogue.entries) {
    final handler = handlers[op];
    final body = handler?.bodies
        .where((b) => b.name == handler.name)
        .firstOrNull;
    var request = body?.parameters.firstOrNull?.type;
    var result = irHandlerResult(body?.returnType);
    if (handler == null) {
      // No handler in the IR: the derivation contract's N-rule names.
      final pascal = op[0].toUpperCase() + op.substring(1);
      if (schemas.containsKey('${pascal}Request')) request = '${pascal}Request';
      if (schemas.containsKey('${pascal}Response')) {
        result = (
          type: '${pascal}Response',
          enveloped: schemas.containsKey(kResultEnvelope),
        );
      }
    }
    if (request == null || result == null) {
      notExpressed.add(
        'CE-API $op: the request or response type (no handler signature and '
        'no ${op}Request/Response type in the IR)',
      );
    }
    final roles = _authorization(handler);
    if (roles != null) {
      notExpressed.add(
        'CE-AZ $op: the authorization `$roles` (OpenAPI security needs a '
        'security scheme the IR does not declare)',
      );
    }
    final description =
        (handler == null ? null : irDocText(handler)) ??
        (entry == null ? null : irDocText(entry));
    Map<String, Object?> ref(String type) => schemas.containsKey(type)
        ? {r'$ref': '#/components/schemas/$type'}
        : {};
    final value = result == null ? <String, Object?>{} : ref(result.type);
    final responseSchema =
        result != null &&
            result.enveloped &&
            schemas.containsKey(kResultEnvelope)
        ? {
            'allOf': [
              {r'$ref': '#/components/schemas/$kResultEnvelope'},
              {
                'properties': {'value': value},
              },
            ],
          }
        : value;
    paths['/$op'] = {
      'post': {
        'operationId': op,
        'description': ?description,
        if (request != null)
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {'schema': ref(request)},
            },
          },
        'responses': {
          '200': {
            'description':
                'The operation\'s outcome: its value, or a structured error '
                'in the Result envelope (codespecs_mapping.md §7).',
            'content': {
              'application/json': {'schema': responseSchema},
            },
          },
          '5XX': {
            'description':
                'A transport error: an infrastructure failure, never an '
                'application outcome (codespecs_mapping.md §7).',
          },
        },
      },
    };
  }
  if (catalogue.isNotEmpty) {
    notExpressed.add(
      'CE-API: the path prefix a server mounts the operations under '
      '(the IR names operations, not URLs; each is written as /<operation>)',
    );
  }

  return IrEmission({
    kOpenApiFile: irJson({
      'openapi': kOpenApiVersion,
      'info': {
        'title': index.title,
        // The IR carries no API version.
        'version': 'unversioned',
      },
      'paths': paths,
      'components': {'schemas': schemas},
    }),
  }, notExpressed);
}

/// The roles a handler's `@CsAuthorize` names, as written, or `null`.
String? _authorization(CsDeclaration? handler) {
  if (handler == null) return null;
  final m = irMarker(handler, 'CsAuthorize');
  if (m == null) return null;
  final roles = m.named['roles'];
  if (roles is CsListValue) {
    return roles.values.map(irString).whereType<String>().join(', ');
  }
  return irString(m.named['requirement']) ?? 'authorized';
}

/// One operation of an OpenAPI document written by [emitOpenApi]: its path,
/// operation id, request and response schema names, and whether the response
/// is the Result envelope. What the mappers write the API client and the
/// routes from (`irspecs_ir.md` §11, §12).
typedef IrOpenApiOperation = ({
  String path,
  String op,
  String? request,
  String? response,
  bool enveloped,
});

/// The operations of [openApi], a document [emitOpenApi] wrote, in its order.
List<IrOpenApiOperation> openApiOperations(Map<String, dynamic> openApi) {
  String? refName(Object? schema) {
    if (schema is Map && schema[r'$ref'] is String) {
      return (schema[r'$ref'] as String).split('/').last;
    }
    return null;
  }

  final out = <IrOpenApiOperation>[];
  for (final MapEntry(key: path, value: item)
      in (openApi['paths'] as Map<String, dynamic>).entries) {
    final post = (item as Map<String, dynamic>)['post'] as Map<String, dynamic>;
    final request = refName(
      post['requestBody']?['content']?['application/json']?['schema'],
    );
    final schema =
        post['responses']['200']['content']['application/json']['schema'];
    String? response;
    var enveloped = false;
    if (schema is Map && schema['allOf'] is List) {
      enveloped = true;
      response = refName(
        ((schema['allOf'] as List)[1] as Map)['properties']['value'],
      );
    } else {
      response = refName(schema);
    }
    out.add((
      path: path,
      op: post['operationId'] as String,
      request: request,
      response: response,
      enveloped: enveloped,
    ));
  }
  return out;
}
