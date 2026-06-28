@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **JavaScript** `v0` SOM generator (plan item #11).
/// They mirror `som_generator_test.dart` / `som_python_generator_test.dart` /
/// `som_java_generator_test.dart`: the real `tom_specs_model` is analysed once
/// (shared via [setUpAll]), then the deterministic write step is exercised and
/// the committed-artefact contract is asserted — a valid meta-data file (which is
/// **byte-identical to the Dart / Python / Java path**, since meta-data is
/// language-agnostic), the typed JS facade module, the 13 DocSpecs schemas, a
/// portable (relative runtime path) `package.json`, and byte-stable idempotency.
///
/// One JavaScript-specific check beyond the Dart suite: the emitted full module
/// must load under `node` against the generic runtime (skipped cleanly when no
/// `node` is on PATH), the real guard against syntax/identifier collisions across
/// the 3000+ class model.
void main() {
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final dartRuntimeDir = p.join(aiBuild, 'tom_som_dart_runtime');
  final jsRuntimeDir = p.join(aiBuild, 'tom_som_javascript_runtime');

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

  SomJavaScriptGenerationResult writeInto(Directory dir) =>
      writeSomJavaScriptProject(
        classes: classes,
        runtimePackagePath: jsRuntimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full JS v0 artefact tree with a valid, stamped meta-data',
      () {
    final dir = Directory.systemTemp.createTempSync('som_js_gen_');
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
    expect(source, contains('class ProjectDefinition extends SomNode'));
    expect(source, contains('module.exports = {'));
    expect(result.modulePath, endsWith('tom_som_javascript_v0.js'));

    // One DocSpecs schema per @Document root (13).
    expect(result.schemaPaths.length, 13);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // package.json records a *relative* runtime path (portable across checkouts)
    // that resolves back to the JS runtime package.
    final manifest = jsonDecode(File(result.packageJsonPath).readAsStringSync())
        as Map<String, Object?>;
    expect(manifest['name'], 'tom_som_javascript_v0');
    expect(manifest['main'], 'tom_som_javascript_v0.js');
    final tomSom = manifest['tomSom'] as Map<String, Object?>;
    final rtPath = tomSom['runtimePath'] as String;
    expect(p.isRelative(rtPath), isTrue,
        reason: 'runtime path must be relative, got $rtPath');
    expect(p.normalize(p.join(result.outputRoot, rtPath)),
        p.normalize(jsRuntimeDir),
        reason: 'relative path must resolve to the JS runtime package');
  });

  test('the JS meta-data is byte-identical to the Dart path', () {
    final js = Directory.systemTemp.createTempSync('som_js_meta_');
    final dart = Directory.systemTemp.createTempSync('som_dart_meta_');
    addTearDown(() => js.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rj = writeInto(js);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rj.metaJsonPath).readAsStringSync(),
        File(rd.metaJsonPath).readAsStringSync(),
        reason: 'meta-data must be language-agnostic / byte-identical');
  });

  test('the JS DocSpecs schemas are byte-identical to the Dart path', () {
    final js = Directory.systemTemp.createTempSync('som_js_sch_');
    final dart = Directory.systemTemp.createTempSync('som_dart_sch_');
    addTearDown(() => js.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rj = writeInto(js);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(rj.schemaPaths.map((s) => p.basename(s)).toList(),
        rd.schemaPaths.map((s) => p.basename(s)).toList());
    for (var i = 0; i < rj.schemaPaths.length; i++) {
      expect(File(rj.schemaPaths[i]).readAsStringSync(),
          File(rd.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(rj.schemaPaths[i])} must be '
              'language-agnostic / byte-identical');
    }
  });

  test('regeneration is idempotent (byte-stable output for unchanged input)',
      () {
    final a = Directory.systemTemp.createTempSync('som_js_a_');
    final b = Directory.systemTemp.createTempSync('som_js_b_');
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
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the analyze+write path matches the write-only path', () async {
    final viaWrite = Directory.systemTemp.createTempSync('som_js_w_');
    final viaFull = Directory.systemTemp.createTempSync('som_js_f_');
    addTearDown(() => viaWrite.deleteSync(recursive: true));
    addTearDown(() => viaFull.deleteSync(recursive: true));

    final rw = writeInto(viaWrite);
    final rf = await generateSomJavaScriptProject(
      modelPackagePath: modelDir,
      runtimePackagePath: jsRuntimeDir,
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

  test('the emitted full module loads under node', () {
    final node = _whichNode();
    if (node == null) {
      markTestSkipped('node not on PATH');
      return;
    }
    if (!Directory(jsRuntimeDir).existsSync()) {
      markTestSkipped('tom_som_javascript_runtime not found');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_js_load_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final result = writeInto(dir);

    final modulePath = result.modulePath.replaceAll(r'\', '/');
    final check = '''
const m = require(${jsonEncode(modulePath)});
const { SpecDocument } = require(${jsonEncode(jsRuntimeDir.replaceAll(r'\', '/'))});
const pd = new m.ProjectDefinition(new SpecDocument());
if (pd.objectModelVersion !== '0.0') throw new Error('version ' + pd.objectModelVersion);
if (typeof pd.path !== 'string' || pd.path.length === 0) throw new Error('root path');
process.stdout.write('OK');
''';
    final r = Process.runSync(node, ['-e', check]);
    expect(r.exitCode, 0,
        reason: 'generated JS module must load under node:\n${r.stderr}');
    expect(r.stdout.toString().trim(), 'OK');
  });
}

/// Resolves a `node` executable from PATH, or `null` when none is available.
String? _whichNode() {
  try {
    final res = Process.runSync('node', ['--version']);
    if (res.exitCode == 0) return 'node';
  } on ProcessException {
    // none on PATH
  }
  return null;
}
