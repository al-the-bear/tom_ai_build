@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **Java** `v0` SOM generator (plan item #11). They
/// mirror `som_generator_test.dart` / `som_python_generator_test.dart`: the real
/// `tom_specs_model` is analysed once (shared via [setUpAll]), then the
/// deterministic write step is exercised and the committed-artefact contract is
/// asserted — a valid meta-data file (which is **byte-identical to the Dart /
/// Python path**, since meta-data is language-agnostic), the typed Java facade
/// source, the 13 DocSpecs schemas, a portable (relative runtime path) build
/// manifest, and byte-stable idempotency.
///
/// One Java-specific check beyond the Dart suite: the emitted source must compile
/// under `javac` against the generic runtime (skipped cleanly when no `javac` is
/// on PATH), which is the real guard against keyword/identifier collisions across
/// the 3000+ class model.
void main() {
  // Locate the sibling packages relative to this clitool package.
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final dartRuntimeDir = p.join(aiBuild, 'tom_som_dart_runtime');
  final javaRuntimeDir = p.join(aiBuild, 'tom_som_java_runtime');

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

  SomJavaGenerationResult writeInto(Directory dir) => writeSomJavaProject(
        classes: classes,
        runtimePackagePath: javaRuntimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full Java v0 artefact tree with a valid, stamped meta-data',
      () {
    final dir = Directory.systemTemp.createTempSync('som_java_gen_');
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

    // Typed facade source exists and declares the global root class as a nested
    // type of the single outer class.
    final source = File(result.sourcePath).readAsStringSync();
    expect(source, contains('public final class TomSomV0'));
    expect(source, contains('class ProjectDefinition extends SomNode'));
    expect(result.sourcePath, endsWith(p.join('tom_som_java_v0', 'TomSomV0.java')));

    // One DocSpecs schema per @Document root (13).
    expect(result.schemaPaths.length, 13);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // Build manifest records a *relative* runtime source path (portable across
    // checkouts) that resolves back to the java runtime src.
    final manifest =
        jsonDecode(File(result.manifestPath).readAsStringSync())
            as Map<String, Object?>;
    expect(manifest['package'], 'tom_som_java_v0');
    final rtPath = manifest['runtimeSourcePath'] as String;
    expect(p.isRelative(rtPath), isTrue,
        reason: 'runtime source path must be relative, got $rtPath');
    expect(p.normalize(p.join(result.outputRoot, rtPath)),
        p.normalize(p.join(javaRuntimeDir, 'src')),
        reason: 'relative path must resolve to the java runtime src');
  });

  test('the Java meta-data is byte-identical to the Dart path', () {
    // Both languages share the same language-agnostic meta-data; prove it by
    // writing a Dart tree with the same stamp and comparing the meta bytes.
    final java = Directory.systemTemp.createTempSync('som_java_meta_');
    final dart = Directory.systemTemp.createTempSync('som_dart_meta_');
    addTearDown(() => java.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rj = writeInto(java);
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

  test('the Java DocSpecs schemas are byte-identical to the Dart path', () {
    final java = Directory.systemTemp.createTempSync('som_java_sch_');
    final dart = Directory.systemTemp.createTempSync('som_dart_sch_');
    addTearDown(() => java.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rj = writeInto(java);
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
    final a = Directory.systemTemp.createTempSync('som_java_a_');
    final b = Directory.systemTemp.createTempSync('som_java_b_');
    addTearDown(() => a.deleteSync(recursive: true));
    addTearDown(() => b.deleteSync(recursive: true));
    final ra = writeInto(a);
    final rb = writeInto(b);

    expect(File(rb.sourcePath).readAsStringSync(),
        File(ra.sourcePath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.manifestPath).readAsStringSync(),
        File(ra.manifestPath).readAsStringSync());
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the analyze+write path matches the write-only path', () async {
    final viaWrite = Directory.systemTemp.createTempSync('som_java_w_');
    final viaFull = Directory.systemTemp.createTempSync('som_java_f_');
    addTearDown(() => viaWrite.deleteSync(recursive: true));
    addTearDown(() => viaFull.deleteSync(recursive: true));

    final rw = writeInto(viaWrite);
    final rf = await generateSomJavaProject(
      modelPackagePath: modelDir,
      runtimePackagePath: javaRuntimeDir,
      outputRoot: viaFull.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rf.sourcePath).readAsStringSync(),
        File(rw.sourcePath).readAsStringSync());
    expect(File(rf.metaJsonPath).readAsStringSync(),
        File(rw.metaJsonPath).readAsStringSync());
  });

  test('the emitted source compiles under javac', () {
    final javac = _whichJavac();
    if (javac == null) {
      markTestSkipped('javac not on PATH');
      return;
    }
    if (!Directory(p.join(javaRuntimeDir, 'src')).existsSync()) {
      markTestSkipped('tom_som_java_runtime/src not found');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_java_compile_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final result = writeInto(dir);

    final outDir = Directory(p.join(dir.path, 'out'))..createSync();
    final sep = Platform.isWindows ? ';' : ':';
    final res = Process.runSync(javac, [
      '-d',
      outDir.path,
      '-sourcepath',
      '${p.join(dir.path, 'src')}$sep${p.join(javaRuntimeDir, 'src')}',
      result.sourcePath,
    ]);
    expect(res.exitCode, 0,
        reason: 'generated Java source must compile:\n${res.stderr}');
  });
}

/// Resolves a `javac` executable from PATH, or `null` when none is available.
String? _whichJavac() {
  try {
    final res = Process.runSync('javac', ['-version']);
    if (res.exitCode == 0) return 'javac';
  } on ProcessException {
    // none on PATH
  }
  return null;
}
