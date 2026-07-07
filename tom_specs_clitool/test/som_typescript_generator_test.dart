@Timeout(Duration(minutes: 8))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **TypeScript** `v0` SOM generator (plan item #11).
/// They mirror `som_generator_test.dart` / `som_python_generator_test.dart` /
/// `som_java_generator_test.dart` / `som_javascript_generator_test.dart`: the
/// real `tom_specs_model` is analysed once (shared via [setUpAll]), then the
/// deterministic write step is exercised and the committed-artefact contract is
/// asserted — a valid meta-data file (**byte-identical to the Dart path**, since
/// meta-data is language-agnostic), the typed TS facade module, the 13 DocSpecs
/// schemas, a portable (relative `file:` runtime dependency) `package.json` + a
/// `tsconfig.json`, and byte-stable idempotency.
///
/// One TypeScript-specific check beyond the Dart suite: the emitted full module
/// must **`tsc`-compile clean** against the generic runtime types (skipped
/// cleanly when no project-local `tsc` is available), the real guard against
/// type/identifier collisions across the 3000+ class model.
void main() {
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final dartRuntimeDir = p.join(aiBuild, 'tom_som_dart_runtime');
  final tsRuntimeDir = p.join(aiBuild, 'tom_som_typescript_runtime');

  // A fixed model stamp so the output is fully determined by the inputs.
  const modelVersion = 1;
  const modelLabel = '1.0.0+4.410187b';
  const generatedAt = '2026-06-17T07:53:06.319186Z';

  late Map<String, ModelClass> classes;

  setUpAll(() async {
    final driver = createAnalysisDriver(modelDir);
    final reader = ModelReader(driver);
    await reader.analyzePackage(p.join(modelDir, 'lib'));
    classes = reader.classes;
  });

  SomTypeScriptGenerationResult writeInto(Directory dir) =>
      writeSomTypeScriptProject(
        classes: classes,
        runtimePackagePath: tsRuntimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full TS v0 artefact tree with a valid, stamped meta-data',
      () {
    final dir = Directory.systemTemp.createTempSync('som_ts_gen_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final result = writeInto(dir);

    // Meta-data exists, validates, and carries the stable build stamp.
    final metaFile = File(result.metaJsonPath);
    expect(metaFile.existsSync(), isTrue);
    final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, Object?>;
    expect(validateSpecModelMeta(meta), isEmpty);
    expect(meta['generatedAt'], generatedAt,
        reason: 'generatedAt must be the stable model build instant');
    expect(meta['modelVersion'], modelVersion);
    expect(meta['modelVersionLabel'], modelLabel);

    // Typed facade module exists and declares + exports the global root class.
    final source = File(result.modulePath).readAsStringSync();
    expect(source, contains('export class D00SolutionBlueprint extends SomNode'));
    expect(source, contains("from 'tom_som_typescript_runtime';"));
    expect(result.modulePath, endsWith('tom_som_typescript_v0.ts'));

    // One DocSpecs schema per @Document root (13).
    expect(result.schemaPaths.length, 13);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // package.json records a *relative* `file:` runtime dependency (portable
    // across checkouts) that resolves back to the TS runtime package.
    final manifest = jsonDecode(File(result.packageJsonPath).readAsStringSync())
        as Map<String, Object?>;
    expect(manifest['name'], 'tom_som_typescript_v0');
    expect(manifest['main'], 'dist/tom_som_typescript_v0.js');
    final deps = manifest['dependencies'] as Map<String, Object?>;
    final dep = deps['tom_som_typescript_runtime'] as String;
    expect(dep, startsWith('file:'), reason: 'runtime must be a file: dep');
    final rtPath = dep.substring('file:'.length);
    expect(p.isRelative(rtPath), isTrue,
        reason: 'runtime path must be relative, got $rtPath');
    expect(p.normalize(p.join(result.outputRoot, rtPath)),
        p.normalize(tsRuntimeDir),
        reason: 'relative path must resolve to the TS runtime package');

    // tsconfig.json is emitted for the static compile.
    expect(File(result.tsconfigPath).existsSync(), isTrue);
  });

  test('the TS meta-data is byte-identical to the Dart path', () {
    final ts = Directory.systemTemp.createTempSync('som_ts_meta_');
    final dart = Directory.systemTemp.createTempSync('som_dart_meta_');
    addTearDown(() => ts.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rt = writeInto(ts);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rt.metaJsonPath).readAsStringSync(),
        File(rd.metaJsonPath).readAsStringSync(),
        reason: 'meta-data must be language-agnostic / byte-identical');
  });

  test('the TS DocSpecs schemas are byte-identical to the Dart path', () {
    final ts = Directory.systemTemp.createTempSync('som_ts_sch_');
    final dart = Directory.systemTemp.createTempSync('som_dart_sch_');
    addTearDown(() => ts.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rt = writeInto(ts);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(rt.schemaPaths.map((s) => p.basename(s)).toList(),
        rd.schemaPaths.map((s) => p.basename(s)).toList());
    for (var i = 0; i < rt.schemaPaths.length; i++) {
      expect(File(rt.schemaPaths[i]).readAsStringSync(),
          File(rd.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(rt.schemaPaths[i])} must be '
              'language-agnostic / byte-identical');
    }
  });

  test('regeneration is idempotent (byte-stable output for unchanged input)',
      () {
    final a = Directory.systemTemp.createTempSync('som_ts_a_');
    final b = Directory.systemTemp.createTempSync('som_ts_b_');
    addTearDown(() => a.deleteSync(recursive: true));
    addTearDown(() => b.deleteSync(recursive: true));
    final ra = writeInto(a);
    final rb = writeInto(b);

    expect(File(rb.modulePath).readAsStringSync(),
        File(ra.modulePath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.packageJsonPath).readAsStringSync(),
        File(ra.packageJsonPath).readAsStringSync());
    expect(File(rb.tsconfigPath).readAsStringSync(),
        File(ra.tsconfigPath).readAsStringSync());
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the analyze+write path matches the write-only path', () async {
    final viaWrite = Directory.systemTemp.createTempSync('som_ts_w_');
    final viaFull = Directory.systemTemp.createTempSync('som_ts_f_');
    addTearDown(() => viaWrite.deleteSync(recursive: true));
    addTearDown(() => viaFull.deleteSync(recursive: true));

    final rw = writeInto(viaWrite);
    final rf = await generateSomTypeScriptProject(
      modelPackagePath: modelDir,
      runtimePackagePath: tsRuntimeDir,
      outputRoot: viaFull.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rf.modulePath).readAsStringSync(),
        File(rw.modulePath).readAsStringSync());
    expect(File(rf.metaJsonPath).readAsStringSync(),
        File(rw.metaJsonPath).readAsStringSync());
  });

  test('the emitted full module tsc-compiles clean against the runtime types',
      () {
    final tsc = _tsc(tsRuntimeDir);
    if (tsc == null) {
      markTestSkipped('project-local tsc not installed in the runtime');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_ts_compile_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final result = writeInto(dir);

    // Resolve the bare `tom_som_typescript_runtime` specifier to the runtime
    // *source* (index.ts) via a compile-time `paths` mapping — a pure type-check
    // of the full 3000+ class module, no `node_modules` link required.
    final runtimeIndex =
        p.join(tsRuntimeDir, 'src', 'index.ts').replaceAll('\\', '/');
    // The runtime uses Node built-ins (e.g. `fs` in `fromFile`), so the
    // type-check needs `@types/node` just like the real `npm run build` does.
    // Point `typeRoots` at the runtime's own installed `@types` so `node`
    // resolves from the temp dir; `types: []` would fail on those built-ins.
    final runtimeTypes =
        p.join(tsRuntimeDir, 'node_modules', '@types').replaceAll('\\', '/');
    final checkConfig = <String, Object?>{
      'compilerOptions': <String, Object?>{
        'target': 'ES2020',
        'lib': <String>['ES2020'],
        'module': 'commonjs',
        'moduleResolution': 'node',
        'ignoreDeprecations': '6.0',
        'strict': true,
        'esModuleInterop': true,
        'skipLibCheck': true,
        'noEmit': true,
        'baseUrl': '.',
        'paths': <String, Object?>{
          'tom_som_typescript_runtime': <String>[runtimeIndex],
        },
        'typeRoots': <String>[runtimeTypes],
        'types': <String>['node'],
      },
      'include': <String>[p.basename(result.modulePath)],
    };
    final checkPath = p.join(dir.path, 'tsconfig.check.json');
    File(checkPath).writeAsStringSync(jsonEncode(checkConfig));
    final r =
        Process.runSync(tsc, ['-p', 'tsconfig.check.json'], workingDirectory: dir.path);
    expect(r.exitCode, 0,
        reason: 'generated TS module must tsc-compile:\n${r.stdout}\n${r.stderr}');
  });
}

/// The project-local `tsc` binary inside the runtime's `node_modules`, or `null`
/// when the runtime has not been `npm install`ed yet.
String? _tsc(String runtimeDir) {
  final bin = p.join(runtimeDir, 'node_modules', '.bin', 'tsc');
  return File(bin).existsSync() ? bin : null;
}
