@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **Go** `v0` SOM generator (plan item #11). They
/// mirror `som_java_generator_test.dart` / `som_rust_generator_test.dart`: the
/// real `tom_specs_model` is analysed once (shared via [setUpAll]), then the
/// deterministic write step is exercised and the committed-artefact contract is
/// asserted — a valid meta-data file (which is **byte-identical to the Dart
/// path**, since meta-data is language-agnostic), the typed Go facade module,
/// the generated metadata module (DR8/DR21), the 13 DocSpecs schemas, a
/// portable (relative runtime `replace`) `go.mod`, and byte-stable idempotency.
///
/// One Go-specific check beyond the Dart suite: the emitted module must
/// **`go build` clean** against the generic runtime (skipped cleanly when no
/// `go` toolchain is available), the real guard against identifier collisions
/// across the 3000+ class model — including the meta module's flat-package
/// collision guard.
void main() {
  // Locate the sibling packages relative to this clitool package.
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final dartRuntimeDir = p.join(aiBuild, 'tom_som_dart_runtime');
  final goRuntimeDir = p.join(aiBuild, 'tom_som_go_runtime');

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

  SomGoGenerationResult writeInto(Directory dir) => writeSomGoProject(
        classes: classes,
        runtimePackagePath: goRuntimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full Go v0 artefact tree with a valid, stamped meta-data',
      () {
    final dir = Directory.systemTemp.createTempSync('som_go_gen_');
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

    // Typed facade module exists and declares the global root struct.
    final source = File(result.modulePath).readAsStringSync();
    expect(source, contains('type D00SolutionBlueprint struct {'));
    // The runtime module is imported and bound to `som` — either as a plain
    // single-line import or, when typed `@Form` members pull in `strconv`, as a
    // member of a grouped `import (...)` block. Assert the binding itself so the
    // check is robust to the import grouping.
    expect(
        source,
        contains('som '
            '"github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"'));
    expect(result.modulePath, endsWith('tom_som_go_v0.go'));

    // The generated metadata module (DR8/DR21) is written alongside the
    // facade and carries the populated trees + access surfaces; the facade's
    // one-call loaders thread the trees into the codec.
    final metaModule = File(result.metaModulePath);
    expect(metaModule.existsSync(), isTrue);
    expect(result.metaModulePath, endsWith('tom_som_go_v0_meta.go'));
    final metaSource = metaModule.readAsStringSync();
    expect(metaSource,
        contains('var D00SolutionBlueprintMetaTree = mustMetaTree('));
    expect(metaSource, contains('var SBP = '));
    expect(source,
        contains('som.FromYaml(yaml, D00SolutionBlueprintMetaTree)'));

    // One DocSpecs schema per @Document root (14).
    expect(result.schemaPaths.length, 14);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // go.mod records a *relative* runtime `replace` directive (portable across
    // checkouts) that resolves back to the Go runtime module.
    final goMod = File(result.goModPath).readAsStringSync();
    expect(goMod,
        contains('module github.com/al-the-bear/tom_ai_build/tom_som_go_v0'));
    final m = RegExp(r'replace github\.com/al-the-bear/tom_ai_build/'
            r'tom_som_go_runtime => (\S+)')
        .firstMatch(goMod);
    expect(m, isNotNull, reason: 'go.mod must record a runtime replace');
    final rtPath = m!.group(1)!;
    expect(p.isRelative(rtPath), isTrue,
        reason: 'runtime path must be relative, got $rtPath');
    expect(p.normalize(p.join(result.outputRoot, rtPath)),
        p.normalize(goRuntimeDir),
        reason: 'relative path must resolve to the Go runtime module');
  });

  test('the Go meta-data is byte-identical to the Dart path', () {
    // Both languages share the same language-agnostic meta-data; prove it by
    // writing a Dart tree with the same stamp and comparing the meta bytes.
    final go = Directory.systemTemp.createTempSync('som_go_meta_');
    final dart = Directory.systemTemp.createTempSync('som_dart_meta_');
    addTearDown(() => go.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rg = writeInto(go);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rg.metaJsonPath).readAsStringSync(),
        File(rd.metaJsonPath).readAsStringSync(),
        reason: 'meta-data must be language-agnostic / byte-identical');
  });

  test('regeneration is idempotent (byte-stable output for unchanged input)',
      () {
    final a = Directory.systemTemp.createTempSync('som_go_a_');
    final b = Directory.systemTemp.createTempSync('som_go_b_');
    addTearDown(() => a.deleteSync(recursive: true));
    addTearDown(() => b.deleteSync(recursive: true));
    final ra = writeInto(a);
    final rb = writeInto(b);

    expect(File(rb.modulePath).readAsStringSync(),
        File(ra.modulePath).readAsStringSync());
    expect(File(rb.metaModulePath).readAsStringSync(),
        File(ra.metaModulePath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.goModPath).readAsStringSync(),
        File(ra.goModPath).readAsStringSync());
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the emitted module compiles under go build (facade + meta module)',
      () {
    final go = _go();
    if (go == null) {
      markTestSkipped('no go toolchain found');
      return;
    }
    if (!Directory(goRuntimeDir).existsSync()) {
      markTestSkipped('tom_som_go_runtime not found');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_go_compile_');
    addTearDown(() => dir.deleteSync(recursive: true));
    writeInto(dir);

    final build =
        Process.runSync(go, ['build', './...'], workingDirectory: dir.path);
    expect(build.exitCode, 0,
        reason: 'generated Go module must compile:\n'
            '${build.stdout}\n${build.stderr}');
  });
}

/// Locates a `go` toolchain — on PATH, or the conventional `~/.local/go/bin/go`
/// install used on the fleet's Linux build hosts. Returns `null` when none.
String? _go() {
  try {
    final r = Process.runSync('go', ['version']);
    if (r.exitCode == 0) return 'go';
  } on ProcessException {
    // not on PATH
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    final cand = p.join(home, '.local', 'go', 'bin', 'go');
    if (File(cand).existsSync()) return cand;
  }
  return null;
}
