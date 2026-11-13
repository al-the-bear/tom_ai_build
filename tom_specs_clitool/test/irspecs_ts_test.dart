/// The TypeScript mappers (`irspecs_ir.md` §11): the Meridian IR written as an
/// npm workspace — `ts-shared`, `ts-react-client`, `ts-hono-server` — that
/// type-checks with `tsc --noEmit`, loads under Node's type stripping, and
/// carries the same back-links as the Dart trio, file by file.
///
/// Needs `node`/`npm` on the PATH (`source ~/.nvm/nvm.sh`) and the npm
/// registry or its cache, as the clitool's other TypeScript checks do.
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

ProcessResult _run(String executable, List<String> args, String cwd) =>
    Process.runSync(executable, args, workingDirectory: cwd, runInShell: true);

/// The back-link lines of a declaration and its members, in order:
/// `codeSpec <id> source: <ids>` and `docSpec <section id>`.
List<String> _expectedBackLinks(IrFile f) => [
  for (final d in f.file.declarations) ...[
    if (d.codeSpec case final cs?)
      'codeSpec ${cs.id}${cs.source.isEmpty ? '' : ' source: ${cs.source.join(', ')}'}',
    for (final r in d.docSpec ?? const <CsDocRef>[]) 'docSpec ${r.sectionId}',
  ],
];

List<String> _tsBackLinks(String ts) => [
  for (final m in RegExp(
    r'^\s*\* @codeSpec (.+)$',
    multiLine: true,
  ).allMatches(ts))
    'codeSpec ${m.group(1)!.trimRight()}',
  for (final m in RegExp(
    r'^\s*\* @docSpec (\S+) ',
    multiLine: true,
  ).allMatches(ts))
    'docSpec ${m.group(1)!}',
];

void main() {
  final documents = _ir();
  late Directory out;
  final files = <String, String>{};

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('irspecs_ts');
    // The web workspace: the mobile client writes the client locus too, as a
    // unit of its own (irspecs_ts_native_test.dart).
    for (final mapper in [
      kTsSharedMapper,
      kTsReactClientMapper,
      kTsHonoServerMapper,
    ]) {
      files.addAll(mapTypeScript(documents, mapper));
    }
    for (final MapEntry(key: path, value: text) in files.entries) {
      File(p.joinAll([out.path, ...path.split('/')]))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(text);
    }
  });
  tearDownAll(() => out.deleteSync(recursive: true));

  test('IRTS1: the workspace installs and type-checks', () {
    final install = _run('npm', [
      'install',
      '--no-audit',
      '--no-fund',
      '--loglevel=error',
    ], out.path);
    expect(install.exitCode, 0, reason: '${install.stdout}${install.stderr}');
    final tsc = _run('npx', ['tsc', '--noEmit', '-p', '.'], out.path);
    expect(tsc.exitCode, 0, reason: '${tsc.stdout}${tsc.stderr}');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('IRTS2: each package loads under Node type stripping, executing '
      'nothing', () {
    for (final package in [
      'meridian_codespec_shared',
      'meridian_codespec_client',
      'meridian_codespec_server',
    ]) {
      final load = _run('node', [
        '--experimental-strip-types',
        '--no-warnings',
        '-e',
        "import('./$package/src/index.ts').then(() => console.log('ok'))",
      ], out.path);
      expect(load.exitCode, 0, reason: '$package: ${load.stderr}');
      expect('${load.stdout}'.trim(), 'ok', reason: package);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('IRTS3: the back-links name every section the Dart trio does, file '
      'by file', () {
    var checked = 0;
    for (final d in documents) {
      if (d.area == kIrPackageArea) continue;
      for (final f in d.files) {
        final package = d.projects
            .firstWhere((pr) => pr.locus == f.locus)
            .packageName;
        final path = f.file.path
            .replaceFirst('lib/', '')
            .replaceFirst(RegExp(r'\.dart$'), '.ts');
        final ts = files['$package/$path'];
        expect(ts, isNotNull, reason: '$package/$path');
        final expected = _expectedBackLinks(f)..sort();
        final actual = _tsBackLinks(ts!)..sort();
        expect(actual, expected, reason: '$package/$path');
        checked++;
      }
    }
    expect(checked, 32);
  });

  test('IRTS4: the wire types agree with the JSON Schema', () {
    final schema =
        jsonDecode(emitJsonSchema(documents).files.values.single)
            as Map<String, dynamic>;
    final defs = (schema[r'$defs'] as Map<String, dynamic>);
    final shared = files.entries
        .where((e) => e.key.startsWith('meridian_codespec_shared/'))
        .map((e) => e.value)
        .join('\n');
    var compared = 0;
    for (final MapEntry(key: name, value: def) in defs.entries) {
      if ((def as Map)['type'] != 'object') continue;
      final block = RegExp(
        'export interface $name(?:<[^>]*>)? \\{\\n([\\s\\S]*?)\\n\\}',
      ).firstMatch(shared);
      if (block == null) continue; // an entity: a Drizzle table on the server
      final props = [
        for (final m in RegExp(
          r'^  (\w+): ',
          multiLine: true,
        ).allMatches(block.group(1)!))
          m.group(1)!,
      ];
      expect(props, (def['properties'] as Map).keys.toList(), reason: name);
      compared++;
    }
    expect(compared, 8);
  });

  test('IRTS5: the shapes — a 3b body from its steps, a 3a body throws, the '
      'collaborator an interface, a route a POST', () {
    final call =
        files['meridian_codespec_client/src/server_call/amend_order_line_call.ts']!;
    expect(
      call,
      contains(
        '    if (await this.collaborator.'
        'assembleRequestAttachTheJustificationApplies(request)) {\n'
        '      await this.collaborator.'
        'assembleRequestAttachTheJustification(request);\n'
        '    }',
      ),
    );
    final collaborator =
        files['meridian_codespec_client/src/server_call/'
            'amend_order_line_call_collaborator.ts']!;
    expect(
      collaborator,
      contains('export interface AmendOrderLineCallCollaborator {'),
    );
    final service =
        files['meridian_codespec_server/src/service_unit/order_service.ts']!;
    expect(service, contains('export abstract class OrderService {'));
    expect(service, contains('throw new Error("not implemented: Applies'));
    final app = files['meridian_codespec_server/src/app.ts']!;
    expect(app, contains('app.post("/amendOrderLine"'));
    final client = files['meridian_codespec_client/src/api/api_client.ts']!;
    expect(
      client,
      contains(
        'async amendOrderLine(request: AmendOrderLineRequest): '
        'Promise<Result<AmendOrderLineResponse>>',
      ),
    );
    final table =
        files['meridian_codespec_server/src/data_access/customer.ts']!;
    expect(
      table,
      contains('export const customerTable = pgTable(\n  "mom_customer",'),
    );
    expect(
      table,
      contains(
        '  (t) => [\n'
        '    primaryKey({ name: "pk_customer", columns: [t.customerId] }),\n'
        '  ],',
      ),
    );
    expect(
      table,
      contains(
        'creditLimit: numeric("credit_limit", { precision: 14, scale: 2 }).notNull()',
      ),
    );
  });
}
