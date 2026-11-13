/// The C# + ASP.NET Core server mapper (`irspecs_ir.md` §14): the Meridian
/// IR's server written as a .NET 8 solution that `dotnet build` builds with no
/// warning, whose server answers every operation as `codespecs_mapping.md` §7
/// asks, whose back-links are the Dart trio's file by file and whose wire
/// types agree with the JSON Schema.
///
/// Needs a .NET 8 SDK (on the PATH, `DOTNET_ROOT`, or the per-user `~/.dotnet`
/// som_toolchains.md describes) and nuget.org or the NuGet cache; without the
/// SDK the building tests are skipped with the reason stated.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

import 'support/dotnet_toolchain.dart';

final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
const _unit = 'meridian_codespec_server';
const _root = 'MeridianCodespecServer';

final String? _dotnet = findDotnet8();

List<IrDocument> _ir() {
  CsLocusProject read(CsLocus locus) => readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: 'meridian_codespec_${locus.name}',
    root: p.join(_meridian, 'meridian_codespec_${locus.name}'),
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
  return [for (final d in documents) readIrYaml(writeIrYaml(d))];
}

void _write(Directory root, Map<String, String> files) {
  for (final MapEntry(key: path, value: text) in files.entries) {
    File(p.joinAll([root.path, ...path.split('/')]))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }
}

/// `dotnet build` of the solution in [dir]: it must succeed with no warning.
void _build(String dir) {
  final r = Process.runSync(
    _dotnet!,
    ['build', '-nologo'],
    workingDirectory: dir,
    environment: dotnetEnvironment(_dotnet!),
  );
  final out = '${r.stdout}${r.stderr}';
  expect(r.exitCode, 0, reason: out);
  expect(out, contains('0 Warning(s)'), reason: out);
  expect(out, contains('0 Error(s)'), reason: out);
}

/// The back-link lines of a Dart file's declarations and members.
List<String> _expectedBackLinks(IrFile f) => [
  for (final d in f.file.declarations) ...[
    if (d.codeSpec case final cs?)
      'codeSpec ${cs.id}${cs.source.isEmpty ? '' : ' source: ${cs.source.join(', ')}'}',
    for (final r in d.docSpec ?? const <CsDocRef>[]) 'docSpec ${r.sectionId}',
  ],
];

List<String> _csharpBackLinks(String cs) => [
  for (final m in RegExp(r'CodeSpec\(("[^)]*)\)\]').allMatches(cs))
    () {
      final args = [
        for (final s in RegExp(r'"([^"]*)"').allMatches(m.group(1)!))
          s.group(1)!,
      ];
      final source = args.skip(1).toList();
      return 'codeSpec ${args.first}${source.isEmpty ? '' : ' source: ${source.join(', ')}'}';
    }(),
  for (final m in RegExp(r'DocSpec\("([^"]*)"').allMatches(cs))
    'docSpec ${m.group(1)!}',
];

IrFile _relocated(IrFile f, CsLocus locus) =>
    IrFile(locus, f.file, f.steps, f.units);

String _camel(String s) => '${s[0].toLowerCase()}${s.substring(1)}';

void main() {
  final skip = _dotnet == null ? 'no .NET 8 SDK on this host' : false;
  final documents = _ir();
  late Map<String, String> files;
  late Directory dir;

  setUpAll(() {
    files = mapCsharpAspnet(documents);
    dir = Directory.systemTemp.createTempSync('irspecs_csharp');
    _write(dir, files);
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  String solution() => p.join(dir.path, _unit);

  test(
    'IRCS1: the solution builds with dotnet build, no warning',
    () {
      _build(solution());
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'IRCS2: the server answers as codespecs_mapping.md §7 asks — a stub '
    'handler, a failed validator, a missing member and an unreadable body '
    'a 500, any other verb a 405',
    () async {
      final dll = p.join(
        solution(),
        'src/$_root.Server/bin/Debug/net8.0/$_root.Server.dll',
      );
      expect(File(dll).existsSync(), isTrue, reason: 'IRCS1 builds it');
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();
      final server = await Process.start(_dotnet!, [
        dll,
        '--urls',
        'http://127.0.0.1:$port',
      ], environment: dotnetEnvironment(_dotnet!));
      final log = StringBuffer();
      server.stdout.transform(utf8.decoder).listen(log.write);
      server.stderr.transform(utf8.decoder).listen(log.write);
      final client = HttpClient();
      Future<(int, String)> send(
        String method,
        String path, [
        String? body,
      ]) async {
        final request = await client.open(method, '127.0.0.1', port, path);
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(body);
        }
        final response = await request.close();
        return (
          response.statusCode,
          await response.transform(utf8.decoder).join(),
        );
      }

      try {
        final deadline = DateTime.now().add(const Duration(seconds: 60));
        while (!log.toString().contains('Now listening')) {
          if (DateTime.now().isAfter(deadline)) fail('no start:\n$log');
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        const valid =
            '{"orderId":"o","lineId":"l","newQuantity":2,"orderVersion":1}';
        final stub = await send('POST', '/amendOrderLine', valid);
        expect(stub.$1, 500);
        expect(stub.$2, startsWith('Applies a quantity change'));
        final invalid = await send(
          'POST',
          '/amendOrderLine',
          '{"orderId":"o","lineId":"l","newQuantity":0,"orderVersion":1}',
        );
        expect(invalid, (500, ''), reason: 'the validator, not the stub');
        final missing = await send(
          'POST',
          '/amendOrderLine',
          '{"orderId":"o","lineId":"l","orderVersion":1}',
        );
        expect(missing.$1, 500);
        expect(missing.$2, contains('Failed to read parameter'));
        expect((await send('POST', '/amendOrderLine', 'nope')).$1, 500);
        expect((await send('GET', '/amendOrderLine')).$1, 405);
      } finally {
        client.close(force: true);
        server.kill();
        await server.exitCode;
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('IRCS3: the back-links name every section the Dart trio does, file '
      'by file', () {
    var checked = 0;
    for (final d in documents) {
      if (d.area == kIrPackageArea) continue;
      for (final f in d.files) {
        if (f.locus == CsLocus.client) continue;
        final project = f.locus == CsLocus.shared ? 'Shared' : 'Server';
        final cs = [
          for (final decl in f.file.declarations)
            if (decl.owner == null)
              files['$_unit/src/$_root.$project/${decl.name}.cs'] ??
                  (throw StateError('no C# file for ${decl.name}')),
        ].join('\n');
        expect(
          _csharpBackLinks(cs)..sort(),
          _expectedBackLinks(f)..sort(),
          reason: f.file.path,
        );
        checked++;
      }
    }
    expect(checked, 23);
  });

  test('IRCS4: the wire types and the entities agree with the JSON Schema, '
      'JsonRequired exactly on its required members', () {
    final schema =
        jsonDecode(emitJsonSchema(documents).files.values.single)
            as Map<String, dynamic>;
    final defs = schema[r'$defs'] as Map<String, dynamic>;
    var compared = 0;
    for (final MapEntry(key: name, value: def) in defs.entries) {
      if ((def as Map)['type'] != 'object') continue;
      final cs = [
        '$_unit/src/$_root.Shared/$name.cs',
        '$_unit/src/$_root.Server/$name.cs',
      ].map((k) => files[k]).nonNulls.single;
      final record = RegExp(
        'public sealed record $name(?:<[^>]*>)?\\(([\\s\\S]*?)\\);',
      ).firstMatch(cs);
      final List<String> names;
      if (record != null) {
        final members = record.group(1)!.split(RegExp(r',\n'));
        names = [];
        final required = <String>[];
        for (final member in members) {
          final last = member.trim().split('\n').last.trim();
          final property = _camel(last.split(' ').last);
          names.add(property);
          if (member.contains('[property: JsonRequired]')) {
            required.add(property);
          }
        }
        expect(required.toSet(), {
          ...(def['required'] as List? ?? const []),
        }, reason: '$name: JsonRequired');
      } else {
        names = [
          for (final m in RegExp(
            r'^ {4}public [\w<>?, ]+ (\w+) \{ get; set; \}',
            multiLine: true,
          ).allMatches(cs))
            _camel(m.group(1)!),
        ];
      }
      expect(names, (def['properties'] as Map).keys.toList(), reason: name);
      compared++;
    }
    expect(compared, 12);
  });

  test('IRCS5: the shapes — records, a FluentValidation validator, enums as '
      'strings, EF Core entities and their migration, a service unit whose '
      'handlers throw, a MapPost per operation', () {
    String file(String path) => files['$_unit/src/$_root.$path']!;
    expect(
      file('Shared/Validators/AmendOrderLineRequestValidator.cs'),
      contains(
        'RuleFor(x => x.NewQuantity).NotNull().GreaterThanOrEqualTo(1);',
      ),
    );
    expect(
      file('Shared/Result.cs'),
      contains('public sealed record Result<T>('),
    );
    expect(
      file('Shared/OrderStatus.cs'),
      contains(
        '[JsonConverter(typeof(JsonStringEnumConverter<OrderStatus>))]\n'
        'public enum OrderStatus',
      ),
    );
    final order = file('Server/Order.cs');
    expect(order, contains('[Table("mom_order")]\npublic class Order'));
    expect(
      order,
      contains(
        '    [Column("channel", TypeName = "varchar(8)")]\n'
        '    public OrderChannel Channel { get; set; }\n',
      ),
    );
    expect(
      file('Server/MeridianCodespecServerDbContext.cs'),
      contains(
        'modelBuilder.Entity<Order>().Property(e => e.Channel)'
        '.HasConversion<string>();',
      ),
    );
    expect(
      file('Server/Migrations/00000000000000_CeDbTables.cs'),
      contains('            CREATE TABLE mom_order ('),
    );
    expect(
      file('Server/OrderRepository.cs'),
      contains(
        'public interface OrderRepository : TomRepository<Order, string>',
      ),
    );
    final service = file('Server/OrderService.cs');
    expect(
      service,
      contains(
        '    public virtual Task<Result<AmendOrderLineResponse>> '
        'AmendOrderLine(AmendOrderLineRequest request)\n'
        '    {\n'
        '        throw new NotImplementedException("Applies',
      ),
    );
    expect(
      file('Server/Program.cs'),
      contains(
        'app.MapPost("/amendOrderLine", (AmendOrderLineRequest request, '
        'OrderService service) =>',
      ),
    );
    final props = files['$_unit/Directory.Build.props']!;
    expect(props, contains('<TargetFramework>net8.0</TargetFramework>'));
    expect(files['$_unit/$_root.sln'], contains('"$_root.Server"'));
    expect(files.keys.where((k) => k.contains('Layout')), isEmpty);
  });

  test('IRCS6: a body with steps is printed from them, and builds', () {
    // Meridian's server bodies are all 3a; its 3b bodies are the client's
    // server calls (CE-SC), read here as if they were the server's.
    final asServer = [
      for (final d in documents)
        if (d.area == 'CE-SC')
          IrDocument(
            area: d.area,
            projects: d.projects,
            files: [for (final f in d.files) _relocated(f, CsLocus.server)],
          )
        else
          d,
    ];
    final mapped = mapCsharpAspnet(asServer);
    expect(
      mapped['$_unit/src/$_root.Server/AmendOrderLineCall.cs'],
      contains(
        '    public async Task AssembleRequest(AmendOrderLineRequest request)\n'
        '    {\n'
        '        await collaborator.AssembleRequestStageTheCoreFields(request);\n'
        '        if (await collaborator.'
        'AssembleRequestAttachTheJustificationApplies(request))\n'
        '        {\n'
        '            await collaborator.AssembleRequestAttachTheJustification('
        'request);\n'
        '        }\n'
        '    }',
      ),
    );
    expect(
      mapped['$_unit/src/$_root.Server/AmendOrderLineCallCollaborator.cs'],
      contains('public interface AmendOrderLineCallCollaborator'),
    );
    if (skip is String) return;
    final steps = Directory.systemTemp.createTempSync('irspecs_csharp_steps');
    try {
      _write(steps, mapped);
      _build(p.join(steps.path, _unit));
    } finally {
      steps.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('IRCS7: a server unit is written, and builds, as the solution of its '
      'id', () {
    const unitId = 'meridian_csharp_server';
    final unit = IrUnit(
      unitId: unitId,
      locus: CsLocus.server,
      mappings: {
        for (final d in documents)
          if (d.area != kIrPackageArea) d.area: kCsharpAspnetServerMapper,
      },
    );
    final unitFiles = mapCsharpAspnet(
      irDocumentsForUnit(documents, unit, mapper: kCsharpAspnetServerMapper),
      all: documents,
    );
    String rename(String k) => k
        .substring(k.indexOf('/') + 1)
        .replaceAll('MeridianCsharpServer', '<Root>')
        .replaceAll(_root, '<Root>');
    expect(unitFiles.keys.map(rename).toSet(), files.keys.map(rename).toSet());
    expect(
      unitFiles['$unitId/MeridianCsharpServer.sln'],
      contains('"MeridianCsharpServer.Server"'),
    );
    if (skip is String) return;
    final unitDir = Directory.systemTemp.createTempSync('irspecs_csharp_unit');
    try {
      _write(unitDir, unitFiles);
      _build(p.join(unitDir.path, unitId));
    } finally {
      unitDir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('IRCS8: a construct with no C# rule is refused, naming the file', () {
    final withLayout = [
      for (final d in documents)
        if (d.area == 'CE-LO')
          IrDocument(
            area: d.area,
            projects: d.projects,
            files: [for (final f in d.files) _relocated(f, CsLocus.shared)],
          )
        else
          d,
    ];
    expect(
      () => mapCsharpAspnet(withLayout),
      throwsA(
        isA<IrMapException>().having(
          (e) => e.message,
          'message',
          allOf(contains('lib/src/layout/'), contains('writes no client')),
        ),
      ),
    );
  });
}
