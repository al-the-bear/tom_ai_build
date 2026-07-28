@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **Java** `v0` SOM generator (som_multiplatform_spec_model.md §10). They
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
    expect(source, contains('class D00SolutionBlueprint extends SomNode'));
    expect(result.sourcePath, endsWith(p.join('tom_som_java_v0', 'TomSomV0.java')));

    // The metadata module (SOM §8) exists as the facade's package sibling and
    // carries the per-root trees + access-surface entry points; the facade's
    // loaders thread the generated tree into the runtime.
    final metaModule = File(result.metaModulePath);
    expect(metaModule.existsSync(), isTrue);
    expect(result.metaModulePath,
        endsWith(p.join('tom_som_java_v0', 'TomSomV0Meta.java')));
    final metaSource = metaModule.readAsStringSync();
    expect(metaSource, contains('public final class TomSomV0Meta'));
    expect(metaSource, contains('D00SolutionBlueprintMetaTree'));
    expect(metaSource, contains('SBP ='));
    expect(
        source,
        contains('SpecDocument.fromYaml(yaml, '
            'TomSomV0Meta.D00SolutionBlueprintMetaTree)'));

    // One DocSpecs schema per @Document root (14).
    expect(result.schemaPaths.length, 14);
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

    // pom.xml is a publishable Maven manifest (PGK4): it declares the project
    // coordinates under `com.altbear.tomsom`, the facade version pinned to the
    // model version, the non-standard flat `src/` source layout, and a
    // dependency on the runtime artifact at the same version.
    final pom = File(result.pomPath).readAsStringSync();
    expect(result.pomPath, endsWith('pom.xml'));
    expect(pom, contains('<groupId>com.altbear.tomsom</groupId>'));
    expect(pom, contains('<artifactId>tom_som_java_v0</artifactId>'));
    expect(pom, contains('<modelVersion>4.0.0</modelVersion>'),
        reason: 'a Maven POM must declare its schema modelVersion');
    // The first (project) <version> is the model version 1.0.0 (label major).
    final firstVersion =
        RegExp(r'<version>([^<]*)</version>').firstMatch(pom)!.group(1);
    expect(firstVersion, '1.0.0',
        reason: 'the facade version is the TomSpecs model version');
    expect(pom, contains('<sourceDirectory>src</sourceDirectory>'),
        reason: 'the flat facade layout keeps sources under src/');
    expect(
        pom,
        contains('<artifactId>tom_som_java_runtime</artifactId>'),
        reason: 'the facade must depend on the runtime artifact');

    // build_jar.sh is the JDK-only `mvn package` fallback: it reads the runtime
    // location from the build manifest and the version from pom.xml, then jars
    // only the facade package.
    final buildScript = File(result.buildScriptPath).readAsStringSync();
    expect(result.buildScriptPath, endsWith('build_jar.sh'));
    expect(buildScript, contains('runtimeSourcePath'));
    expect(buildScript, contains('tom_som_build.json'));
    expect(buildScript, contains('jar --create'));
    expect(buildScript, contains('tom_som_java_v0-\$version.jar'));
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
    expect(File(rb.metaModulePath).readAsStringSync(),
        File(ra.metaModulePath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.manifestPath).readAsStringSync(),
        File(ra.manifestPath).readAsStringSync());
    expect(File(rb.pomPath).readAsStringSync(),
        File(ra.pomPath).readAsStringSync());
    expect(File(rb.buildScriptPath).readAsStringSync(),
        File(ra.buildScriptPath).readAsStringSync());
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
      result.metaModulePath,
    ]);
    expect(res.exitCode, 0,
        reason: 'generated Java source must compile:\n${res.stderr}');
  });

  test('build_jar.sh produces a facade-only JAR (PGK4 done-criterion)', () {
    // The done-criterion of PGK4: the JAR builds via the build_jar.sh fallback.
    // Skip cleanly on a host without the JDK/shell toolchain.
    if (!_hasTool('bash') || _whichJavac() == null || !_hasTool('jar')) {
      markTestSkipped('bash/javac/jar not all on PATH');
      return;
    }
    if (!Directory(p.join(javaRuntimeDir, 'src')).existsSync()) {
      markTestSkipped('tom_som_java_runtime/src not found');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_java_jar_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final result = writeInto(dir);

    // The emitted manifest's relative runtimeSourcePath resolves from this temp
    // project back to the real runtime src, so build_jar.sh compiles against it.
    final res = Process.runSync('bash', [result.buildScriptPath]);
    expect(res.exitCode, 0,
        reason: 'build_jar.sh must build the facade JAR:\n${res.stderr}');

    final jar = File(p.join(dir.path, 'build', 'tom_som_java_v0-1.0.0.jar'));
    expect(jar.existsSync(), isTrue,
        reason: 'build_jar.sh must write build/tom_som_java_v0-<version>.jar');

    // The facade JAR carries only the facade package (the runtime ships its own
    // JAR), so runtime classes must be absent.
    final listing =
        Process.runSync('jar', ['--list', '--file', jar.path]).stdout as String;
    expect(listing, contains('tom_som_java_v0/'));
    expect(listing, isNot(contains('tom_som_runtime/')),
        reason: 'the facade JAR must exclude the separately-shipped runtime');
  });
}

/// True when [tool] resolves on PATH (via `<tool> --version`, tolerating tools
/// that exit non-zero for `--version` as long as the executable is found).
bool _hasTool(String tool) {
  try {
    Process.runSync(tool, ['--version']);
    return true;
  } on ProcessException {
    return false;
  }
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
