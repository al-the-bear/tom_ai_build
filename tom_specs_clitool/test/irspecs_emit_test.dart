/// The standard emitters (`irspecs_ir.md` §10): the Meridian IR written as
/// OpenAPI 3.1, JSON Schema 2020-12, an ICU MessageFormat catalogue and
/// AsyncAPI 3, each document valid against its standard's official
/// meta-schema (vendored under `tool/standards/`), and every fact a standard
/// has no form for reported rather than dropped.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
final _validator = p.absolute('tool/standards/validate_standard.py');

/// The IR of a trio whose three packages sit under [root] as
/// `<prefix>_shared` / `_client` / `_server`.
List<IrDocument> _ir(String root, String prefix) {
  CsLocusProject read(CsLocus locus) => readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: '${prefix}_${locus.name}',
    root: p.join(root, '${prefix}_${locus.name}'),
  );
  final documents = irFromCsModel(
    shared: read(CsLocus.shared),
    client: read(CsLocus.client),
    server: read(CsLocus.server),
    areas: IrAreaIndex(
      CodeSpecsAreaCatalog.fromJson(
        jsonDecode(File(_areas).readAsStringSync()) as Map<String, dynamic>,
      ),
    ),
  );
  // Through the file form, so the test proves what an IR folder holds.
  return [for (final d in documents) readIrYaml(writeIrYaml(d))];
}

final String _python = Platform.isWindows ? 'py' : 'python3';

/// Why the vendored validator cannot run here — no Python, or one without
/// `jsonschema` and `referencing` (`tool/standards/README.md`) — or `null`
/// when it can.
final String? _noValidator = () {
  try {
    final r = Process.runSync(_python, [
      if (Platform.isWindows) '-3',
      '-c',
      'import jsonschema, referencing',
    ]);
    return r.exitCode == 0
        ? null
        : 'the validator needs Python with jsonschema and referencing '
              '(tool/standards/README.md): ${'${r.stderr}'.trim().split('\n').last}';
  } on ProcessException {
    return 'the validator needs Python ($_python is not on the PATH)';
  }
}();

/// Runs the vendored validator over [file]; returns its exit code and output.
({int code, String output}) _validate(String standard, String file) {
  final python = _python;
  final result = Process.runSync(python, [
    if (Platform.isWindows) '-3',
    _validator,
    standard,
    file,
  ]);
  return (code: result.exitCode, output: '${result.stdout}${result.stderr}');
}

Map<String, dynamic> _json(IrEmission e) =>
    jsonDecode(e.files.values.single) as Map<String, dynamic>;

/// Every `$ref` in [node], in document order.
Iterable<String> _refs(Object? node) sync* {
  if (node is Map) {
    for (final MapEntry(:key, :value) in node.entries) {
      if (key == r'$ref' && value is String) yield value;
      yield* _refs(value);
    }
  } else if (node is List) {
    for (final v in node) {
      yield* _refs(v);
    }
  }
}

/// Whether the JSON pointer [ref] (`#/a/b`) names a node of [doc].
bool _resolves(Map<String, dynamic> doc, String ref) {
  if (!ref.startsWith('#/')) return false;
  Object? node = doc;
  for (final part in ref.substring(2).split('/')) {
    if (node is! Map || !node.containsKey(part)) return false;
    node = node[part];
  }
  return true;
}

void main() {
  final meridian = _ir(_meridian, 'meridian_codespec');
  late Directory scratch;
  setUpAll(() => scratch = Directory.systemTemp.createTempSync('irspecs_emit'));
  tearDownAll(() => scratch.deleteSync(recursive: true));

  group('IRE1: the Meridian IR in each standard, valid against its '
      'meta-schema', () {
    for (final (standard, emit) in [
      ('openapi', emitOpenApi),
      ('jsonschema', emitJsonSchema),
      ('asyncapi', emitAsyncApi),
    ]) {
      test(standard, () {
        final emission = emit(meridian);
        final file = File(p.join(scratch.path, '$standard.json'))
          ..writeAsStringSync(emission.files.values.single);
        final result = _validate(standard, file.path);
        expect(result.code, 0, reason: result.output);
      }, skip: _noValidator ?? false);
    }

    test('icu: every message parses as ICU MessageFormat', () {
      final messages = _json(emitIcu(meridian)).cast<String, String>();
      expect(messages, hasLength(14));
      for (final MapEntry(:key, :value) in messages.entries) {
        expect(icuSyntaxErrors(value), isEmpty, reason: '$key: $value');
      }
    });

    test('the validator rejects what its standard rejects', () {
      final bad = File(p.join(scratch.path, 'bad.json'))
        ..writeAsStringSync(
          jsonEncode({
            'openapi': '3.1.0',
            'info': {'title': 'x'},
            'paths': {
              '/a': {
                'post': {
                  'responses': {
                    '200': {
                      'description': 'ok',
                      'content': {
                        'application/json': {
                          'schema': {'type': 'objectx'},
                        },
                      },
                    },
                  },
                },
              },
            },
          }),
        );
      final result = _validate('openapi', bad.path);
      expect(result.code, 1);
      expect(result.output, contains("'version' is a required property"));
      expect(result.output, contains('objectx'));
    }, skip: _noValidator ?? false);
  });

  group('IRE2: what the documents say', () {
    test('OpenAPI: each operation a POST over the Result envelope', () {
      final doc = _json(emitOpenApi(meridian));
      expect(doc['openapi'], '3.1.0');
      final paths = doc['paths'] as Map<String, dynamic>;
      expect(paths.keys, ['/amendOrderLine', '/fetchOrderWorkList']);
      for (final MapEntry(:key, :value) in paths.entries) {
        final op = value as Map<String, dynamic>;
        expect(op.keys, ['post'], reason: key);
        final post = op['post'] as Map<String, dynamic>;
        final responses = post['responses'] as Map<String, dynamic>;
        expect(responses.keys, ['200', '5XX']);
      }
      final amend = paths['/amendOrderLine']['post'] as Map<String, dynamic>;
      expect(amend['operationId'], 'amendOrderLine');
      expect(amend['requestBody']['content']['application/json']['schema'], {
        r'$ref': '#/components/schemas/AmendOrderLineRequest',
      });
      expect(
        amend['responses']['200']['content']['application/json']['schema'],
        {
          'allOf': [
            {r'$ref': '#/components/schemas/Result'},
            {
              'properties': {
                'value': {
                  r'$ref': '#/components/schemas/AmendOrderLineResponse',
                },
              },
            },
          ],
        },
      );
      for (final ref in _refs(doc)) {
        expect(_resolves(doc, ref), isTrue, reason: ref);
      }
    });

    test('JSON Schema: enums, error codes, entities and their rules', () {
      final doc = _json(emitJsonSchema(meridian));
      expect(doc[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
      final defs = doc[r'$defs'] as Map<String, dynamic>;
      expect(defs['OrderStatus']['enum'], hasLength(9));
      expect(defs['SbpErrorCodes']['enum'], [
        'VALIDATION_FAILED',
        'ORDER_ALREADY_DISPATCHED',
        'ORDER_VERSION_CONFLICT',
      ]);
      expect(defs['Customer']['properties']['creditLimit']['minimum'], 0);
      expect(
        defs['AmendOrderLineRequest']['properties']['newQuantity']['minimum'],
        1,
      );
      expect(defs['FetchOrderWorkListResponse']['properties']['orders'], {
        'type': 'array',
        'items': {r'$ref': r'#/$defs/OrderDto'},
        'description': 'The page of matching orders in queue order.',
      });
      for (final ref in _refs(doc)) {
        expect(_resolves(doc, ref), isTrue, reason: ref);
      }
    });

    test('ICU: key to base copy, a placeholder kept an argument', () {
      final messages = _json(emitIcu(meridian));
      expect(messages['screen.orders.title'], 'Orders');
      expect(messages['screen.order.title'], 'Order {orderId}');
    });

    test('AsyncAPI: Meridian declares no events — the info alone', () {
      expect(_json(emitAsyncApi(meridian)), {
        'asyncapi': '3.0.0',
        'info': {'title': 'meridian_codespec_shared', 'version': 'unversioned'},
      });
    });
  });

  group('IRE3: what a standard cannot express is reported', () {
    test('OpenAPI: severities, storage, authorization, the path prefix', () {
      final lines = emitOpenApi(meridian).notExpressed;
      expect(lines.where((l) => l.contains('the severity')), hasLength(3));
      expect(lines.where((l) => l.contains('the table')), hasLength(4));
      expect(lines.where((l) => l.startsWith('CE-AZ')), hasLength(2));
      expect(lines.where((l) => l.contains('path prefix')), hasLength(1));
    });

    test('ICU: locale and doc comments', () {
      expect(emitIcu(meridian).notExpressed, [
        startsWith('CE-TX: the locale of the base copy'),
      ]);
    });

    test('`irspecs emit` writes the file and lists every line', () async {
      final ir = p.join(scratch.path, 'ir');
      Directory(ir).createSync();
      for (final d in meridian) {
        File(p.join(ir, d.fileName)).writeAsStringSync(writeIrYaml(d));
      }
      final out = StringBuffer();
      final code = await runIrspecs([
        'emit',
        '--standard',
        'openapi',
        '--ir',
        ir,
        '--out',
        p.join(scratch.path, 'emitted'),
      ], out: out);
      expect(code, 0);
      expect(
        File(
          p.join(scratch.path, 'emitted', 'openapi.json'),
        ).readAsStringSync(),
        emitOpenApi(meridian).files['openapi.json'],
      );
      for (final line in emitOpenApi(meridian).notExpressed) {
        expect(out.toString(), contains(line));
      }
    });
  });

  group('IRE4: ICU MessageFormat', () {
    test('a base copy is quoted where ICU would read it', () {
      expect(icuMessageFor('Order {orderId}'), 'Order {orderId}');
      expect(icuMessageFor("Don't {x}"), "Don''t {x}");
      expect(icuMessageFor('a {b c} d'), "a '{'b c'}' d");
      expect(icuMessageFor('}'), "'}'");
      for (final copy in ["Don't", 'a {b c} d', '{', 'x {y}', "it's '{'"]) {
        expect(icuSyntaxErrors(icuMessageFor(copy)), isEmpty, reason: copy);
      }
    });

    test('the parser accepts ICU syntax and names what it rejects', () {
      for (final ok in [
        'Hello {name}',
        '{n, number}',
        '{d, date, short}',
        "{count, plural, offset:1 =0 {none} one {# item} other {# items}}",
        '{g, select, female {She} male {He} other {They}}',
        "It''s '{'literal'}'",
      ]) {
        expect(icuSyntaxErrors(ok), isEmpty, reason: ok);
      }
      for (final (bad, what) in [
        ('Hello {name', 'unclosed'),
        ('Hello }', 'unmatched'),
        ('{n, colour}', 'unknown argument type'),
        ('{n, plural, one {x}}', 'no `other` case'),
        ('{n, select, a {x} a {y} other {z}}', 'twice'),
        ("'{unclosed", 'unclosed quoted literal'),
      ]) {
        expect(icuSyntaxErrors(bad).single, contains(what), reason: bad);
      }
    });
  });

  test('IRE5: AsyncAPI from notifications and event-triggered jobs', () {
    final root = Directory(p.join(scratch.path, 'trio'));
    void write(String path, String text) => File(p.join(root.path, path))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
    write('app_shared/lib/src/notification/order_shipped.dart', '''
import 'package:tom_code_specs/tom_code_specs.dart';

/// Tells the customer the order left the warehouse.
@CsNotification(body: CsMessageKey('notification.order.shipped'))
class OrderShipped {
  late String orderId;
  late DateTime shippedAt;
}

/// Mail to the customer's address.
@CsNotificationChannel()
class EmailChannel {}
''');
    write('app_server/lib/src/background_job/jobs.dart', '''
import 'package:tom_code_specs/tom_code_specs.dart';

/// Releases the reservations of a cancelled order.
@CsJob(trigger: CsJobTrigger.event, event: 'order.cancelled')
class ReleaseReservations {}

/// Closes the day.
@CsJob(trigger: CsJobTrigger.cron, cron: '0 2 * * *')
class CloseTheDay {}
''');
    Directory(
      p.join(root.path, 'app_client', 'lib'),
    ).createSync(recursive: true);

    final emission = emitAsyncApi(_ir(root.path, 'app'));
    final doc = _json(emission);
    expect(doc['channels'], {
      'EmailChannel': {
        'address': 'EmailChannel',
        'description': "Mail to the customer's address.",
      },
      'order.cancelled': {'address': 'order.cancelled'},
    });
    expect(doc['operations'], {
      'ReleaseReservations': {
        'action': 'receive',
        'channel': {r'$ref': '#/channels/order.cancelled'},
        'description': 'Releases the reservations of a cancelled order.',
      },
    });
    expect(doc['components']['messages']['OrderShipped']['payload'], {
      'type': 'object',
      'properties': {
        'orderId': {'type': 'string'},
        'shippedAt': {'type': 'string', 'format': 'date-time'},
      },
    });
    expect(emission.notExpressed, [
      contains('OrderShipped: the channels it goes out on'),
      contains('ReleaseReservations: its retries'),
      contains('CloseTheDay: the cron trigger'),
    ]);
    final file = File(p.join(scratch.path, 'asyncapi_jobs.json'))
      ..writeAsStringSync(emission.files.values.single);
    // The meta-schema check needs the vendored validator; the references
    // resolve whatever the host carries.
    if (_noValidator == null) {
      final result = _validate('asyncapi', file.path);
      expect(result.code, 0, reason: result.output);
    }
    for (final ref in _refs(doc)) {
      expect(_resolves(doc, ref), isTrue, reason: ref);
    }
  });
}
