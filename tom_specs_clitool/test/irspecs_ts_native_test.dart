/// The React Native client mapper (`irspecs_ir.md` §11.2): one Meridian IR
/// written as two client units — a web client (`ts-react-client`) and a mobile
/// client (`ts-react-native-client`, Expo with React Navigation) — beside the
/// shared package and the server, in one npm workspace that type-checks with
/// `tsc --noEmit`; both clients carry the Dart trio's back-links, file by file.
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
const _web = 'meridian_codespec_client';
const _mobile = 'meridian_codespec_mobile';

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

/// A client unit of [id] mapping every area the IR has to [mapper].
IrUnit _clientUnit(String id, String mapper, List<IrDocument> documents) =>
    IrUnit(
      unitId: id,
      locus: CsLocus.client,
      mappings: {
        for (final d in documents)
          if (d.area != kIrPackageArea) d.area: mapper,
      },
    );

ProcessResult _run(String executable, List<String> args, String cwd) =>
    Process.runSync(executable, args, workingDirectory: cwd, runInShell: true);

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

  /// Every file written into the workspace, as the CLI writes them: each
  /// mapping's root merged into the root before it.
  final files = <String, String>{};

  void add(Map<String, String> mapped) {
    files.addAll(mergeTsWorkspaceRoot(mapped, files['package.json']));
  }

  setUpAll(() {
    add(mapTypeScript(documents, kTsSharedMapper));
    add(
      mapTypeScript(
        irDocumentsForUnit(
          documents,
          _clientUnit(_web, kTsReactClientMapper, documents),
          mapper: kTsReactClientMapper,
        ),
        kTsReactClientMapper,
        all: documents,
      ),
    );
    add(
      mapTypeScript(
        irDocumentsForUnit(
          documents,
          _clientUnit(_mobile, kTsReactNativeClientMapper, documents),
          mapper: kTsReactNativeClientMapper,
        ),
        kTsReactNativeClientMapper,
        all: documents,
      ),
    );
    add(mapTypeScript(documents, kTsHonoServerMapper));
    out = Directory.systemTemp.createTempSync('irspecs_ts_native');
    for (final MapEntry(key: path, value: text) in files.entries) {
      File(p.joinAll([out.path, ...path.split('/')]))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(text);
    }
  });
  tearDownAll(() => out.deleteSync(recursive: true));

  test('IRRN1: one workspace of four packages — shared, the web and the '
      'mobile client, the server — installs and type-checks', () {
    final root = jsonDecode(files['package.json']!) as Map<String, dynamic>;
    // The shared package's root lists the IR's three packages; the mobile
    // client's mapping adds its own after them.
    expect(root['workspaces'], [
      'meridian_codespec_shared',
      _web,
      'meridian_codespec_server',
      _mobile,
    ]);
    final include =
        (jsonDecode(files['tsconfig.json']!) as Map)['include'] as List;
    expect(include, contains('$_mobile/src/**/*.ts'));
    final install = _run('npm', [
      'install',
      '--no-audit',
      '--no-fund',
      '--loglevel=error',
    ], out.path);
    expect(install.exitCode, 0, reason: '${install.stdout}${install.stderr}');
    final tsc = _run('npx', ['tsc', '--noEmit', '-p', '.'], out.path);
    expect(tsc.exitCode, 0, reason: '${tsc.stdout}${tsc.stderr}');
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('IRRN2: both clients carry the Dart client\'s back-links, file by '
      'file, from the one IR', () {
    var checked = 0;
    for (final d in documents) {
      if (d.area == kIrPackageArea) continue;
      for (final f in d.files) {
        if (f.locus != CsLocus.client) continue;
        final module = f.file.path
            .replaceFirst('lib/', '')
            .replaceFirst(RegExp(r'\.dart$'), '.ts');
        final expected = _expectedBackLinks(f)..sort();
        for (final package in [_web, _mobile]) {
          final ts = files['$package/$module'];
          expect(ts, isNotNull, reason: '$package/$module');
          expect(
            _tsBackLinks(ts!)..sort(),
            expected,
            reason: '$package/$module',
          );
        }
        // What the IR says is written the same in both clients.
        expect(files['$_mobile/$module'], files['$_web/$module']);
        checked++;
      }
    }
    expect(checked, 9);
  });

  test('IRRN3: what differs from the web client — the Expo entry and '
      'package, the React Navigation stack of the routes', () {
    final navigator = files['$_mobile/src/navigation/app_navigator.ts']!;
    expect(
      navigator,
      contains(
        'export type RootStackParamList = {\n'
        '  "order-work-list": undefined;\n'
        '  "order-detail": { orderId: string };\n'
        '};',
      ),
    );
    expect(
      navigator,
      contains(
        'createElement(Stack.Screen, { name: "order-detail", component: '
        'OrderDetailScreen }),',
      ),
    );
    expect(
      navigator,
      contains('throw new Error("not implemented: screen order-work-list");'),
    );
    expect(
      files['$_mobile/src/main.ts'],
      contains('registerRootComponent(AppNavigator);'),
    );
    expect((jsonDecode(files['$_mobile/app.json']!) as Map)['expo'], {
      'name': _mobile,
      'slug': _mobile,
      'version': '0.0.0',
    });
    final mobile =
        jsonDecode(files['$_mobile/package.json']!) as Map<String, dynamic>;
    expect(mobile['main'], 'src/main.ts');
    expect(mobile['dependencies'], {
      'meridian_codespec_shared': '*',
      'expo': '~58.0.25',
      'react': '19.3.0',
      'react-native': '0.88.1',
      '@react-navigation/native': '^7.5.1',
      '@react-navigation/native-stack': '^7.21.0',
      'react-native-screens': '~4.30.1',
      'react-native-safe-area-context': '~5.11.1',
    });
    final web =
        jsonDecode(files['$_web/package.json']!) as Map<String, dynamic>;
    expect(web.containsKey('main'), isFalse);
    expect(
      files.keys.where((k) => k.startsWith('$_web/src/navigation/app')),
      isEmpty,
    );
    // The API client is the web client's (plain fetch runs on React Native),
    // and so are the constructions' interfaces.
    for (final module in ['src/api/api_client.ts', 'src/tom/tom.ts']) {
      expect(files['$_mobile/$module'], files['$_web/$module'], reason: module);
    }
  });

  test('IRRN4: merging a workspace root keeps what is there and adds the '
      'new packages', () {
    final first = tsWorkspaceRoot('x', ['x', 'web', 'server']);
    final second = tsWorkspaceRoot('x', ['x', 'mobile', 'server']);
    final merged = mergeTsWorkspaceRoot(second, first['package.json']);
    expect((jsonDecode(merged['package.json']!) as Map)['workspaces'], [
      'x',
      'web',
      'server',
      'mobile',
    ]);
    expect(
      (jsonDecode(merged['tsconfig.json']!) as Map)['include'],
      ['x', 'web', 'server', 'mobile'].map((p) => '$p/src/**/*.ts').toList(),
    );
    expect(mergeTsWorkspaceRoot(second, null), same(second));
  });

  test('IRRN5: the CLI writes each package into the workspace already in '
      '--out', () async {
    final ir = Directory.systemTemp.createTempSync('irspecs_ts_native_ir');
    final cliOut = Directory.systemTemp.createTempSync('irspecs_ts_native_out');
    try {
      for (final d in documents) {
        File(
          p.join(ir.path, '${d.area}.ir.yaml'),
        ).writeAsStringSync(writeIrYaml(d));
      }
      for (final mapper in [kTsSharedMapper, kTsReactNativeClientMapper]) {
        final err = StringBuffer();
        final code = await runIrspecs(
          ['map', '--mapper', mapper, '--ir', ir.path, '--out', cliOut.path],
          out: StringBuffer(),
          err: err,
        );
        expect(code, 0, reason: '$err');
      }
      final root =
          jsonDecode(
                File(p.join(cliOut.path, 'package.json')).readAsStringSync(),
              )
              as Map;
      expect(
        root['workspaces'],
        containsAll([
          'meridian_codespec_shared',
          'meridian_codespec_client',
          'meridian_codespec_server',
        ]),
      );
      expect(
        File(
          p.join(cliOut.path, 'meridian_codespec_client', 'src', 'main.ts'),
        ).existsSync(),
        isTrue,
      );
    } finally {
      ir.deleteSync(recursive: true);
      cliOut.deleteSync(recursive: true);
    }
  });

  test('IRRN6: a mobile client with no route is refused', () {
    final withoutRoutes = [
      for (final d in documents)
        if (d.area != 'CE-NV') d,
    ];
    expect(
      () => mapTypeScript(withoutRoutes, kTsReactNativeClientMapper),
      throwsA(
        isA<IrMapException>().having(
          (e) => e.message,
          'message',
          contains('no route'),
        ),
      ),
    );
  });
}
