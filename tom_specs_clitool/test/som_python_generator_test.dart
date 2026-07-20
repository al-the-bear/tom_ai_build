@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **Python** `v0` SOM generator (plan item #11). They
/// mirror `som_generator_test.dart`: the real `tom_specs_model` is analysed once
/// (shared via [setUpAll]), then the deterministic write step is exercised and
/// the committed-artefact contract is asserted — a valid meta-data file (which
/// is **byte-identical to the Dart path**, since meta-data is language-agnostic),
/// the typed Python facade module, the 13 DocSpecs schemas, a portable
/// (relative runtime path) `pyproject.toml`, and byte-stable idempotency.
///
/// One Python-specific check beyond the Dart suite: the emitted module must pass
/// `python3 -m py_compile` (skipped cleanly when no `python3` is on PATH), which
/// is the real guard against keyword/identifier collisions across the
/// 3000+ class model.
void main() {
  // Locate the sibling packages relative to this clitool package.
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final dartRuntimeDir = p.join(aiBuild, 'tom_som_dart_runtime');
  final pyRuntimeDir = p.join(aiBuild, 'tom_som_python_runtime');

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

  SomPythonGenerationResult writeInto(Directory dir) => writeSomPythonProject(
        classes: classes,
        runtimePackagePath: pyRuntimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full Python v0 artefact tree with a valid, stamped meta-data',
      () {
    final dir = Directory.systemTemp.createTempSync('som_py_gen_');
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

    // Typed facade module exists and declares the global root class.
    final module = File(result.modulePath).readAsStringSync();
    expect(module, contains('class D00SolutionBlueprint'));
    expect(result.modulePath, endsWith('tom_som_python_v0.py'));

    // The generated metadata module (DR8/DR12) is written alongside the
    // facade and carries the populated trees + access surfaces.
    final metaModule = File(
        p.join(p.dirname(result.modulePath), 'tom_som_python_v0_meta.py'));
    expect(metaModule.existsSync(), isTrue);
    expect(metaModule.readAsStringSync(),
        contains('d00SolutionBlueprintMetaTree = SomMetaTree('));

    // One DocSpecs schema per @Document root (14).
    expect(result.schemaPaths.length, 14);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // pyproject.toml is a publishable PEP 517 manifest (PGK3): it declares a
    // build backend, the facade module as a single top-level py-module, the
    // facade version pinned to the model version, and a hosted runtime
    // dependency. It *also* records a *relative* runtime path (portable across
    // checkouts) for local, unpublished development.
    final pyproject = File(result.pyprojectPath).readAsStringSync();
    expect(pyproject, contains('name = "tom_som_python_v0"'));
    expect(pyproject, contains('[build-system]'),
        reason: 'a PEP 517 dist must declare a build backend');
    expect(pyproject, contains('build-backend = "setuptools.build_meta"'));
    expect(pyproject, contains('version = "1.0.0"'),
        reason: 'facade version is the TomSpecs model version');
    expect(pyproject,
        contains('py-modules = ["tom_som_python_v0", "tom_som_python_v0_meta"]'),
        reason: 'the facade and its generated metadata module must be listed '
            'explicitly so setuptools skips flat-layout auto-discovery');
    expect(pyproject, contains('tom_som_python_runtime>=1.0.0'),
        reason: 'the runtime dep must be pinned to the model version');
    final rtPath =
        RegExp(r'runtime-path\s*=\s*"([^"]+)"').firstMatch(pyproject)!.group(1)!;
    expect(p.isRelative(rtPath), isTrue,
        reason: 'runtime path must be relative, got $rtPath');
    expect(p.normalize(p.join(result.outputRoot, rtPath)),
        p.normalize(p.join(pyRuntimeDir, 'tom_som_runtime')),
        reason: 'relative path must resolve to the python runtime module');
  });

  test('the Python meta-data is byte-identical to the Dart path', () {
    // Both languages share the same language-agnostic meta-data; prove it by
    // writing a Dart tree with the same stamp and comparing the meta bytes.
    final py = Directory.systemTemp.createTempSync('som_py_meta_');
    final dart = Directory.systemTemp.createTempSync('som_dart_meta_');
    addTearDown(() => py.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rp = writeInto(py);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rp.metaJsonPath).readAsStringSync(),
        File(rd.metaJsonPath).readAsStringSync(),
        reason: 'meta-data must be language-agnostic / byte-identical');
  });

  test('regeneration is idempotent (byte-stable output for unchanged input)',
      () {
    final a = Directory.systemTemp.createTempSync('som_py_a_');
    final b = Directory.systemTemp.createTempSync('som_py_b_');
    addTearDown(() => a.deleteSync(recursive: true));
    addTearDown(() => b.deleteSync(recursive: true));
    final ra = writeInto(a);
    final rb = writeInto(b);

    expect(File(rb.modulePath).readAsStringSync(),
        File(ra.modulePath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.pyprojectPath).readAsStringSync(),
        File(ra.pyprojectPath).readAsStringSync());
    expect(rb.schemaPaths.map((s) => p.basename(s)).toList(),
        ra.schemaPaths.map((s) => p.basename(s)).toList());
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the analyze+write path matches the write-only path', () async {
    final viaWrite = Directory.systemTemp.createTempSync('som_py_w_');
    final viaFull = Directory.systemTemp.createTempSync('som_py_f_');
    addTearDown(() => viaWrite.deleteSync(recursive: true));
    addTearDown(() => viaFull.deleteSync(recursive: true));

    final rw = writeInto(viaWrite);
    final rf = await generateSomPythonProject(
      modelPackagePath: modelDir,
      runtimePackagePath: pyRuntimeDir,
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

  test('the emitted module compiles under python3 (py_compile)', () {
    final python3 = _whichPython3();
    if (python3 == null) {
      markTestSkipped('python3 not on PATH');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_py_compile_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final result = writeInto(dir);

    final res = Process.runSync(python3, ['-m', 'py_compile', result.modulePath]);
    expect(res.exitCode, 0,
        reason: 'generated Python module must compile:\n${res.stderr}');
    final metaPath =
        p.join(p.dirname(result.modulePath), 'tom_som_python_v0_meta.py');
    final resMeta = Process.runSync(python3, ['-m', 'py_compile', metaPath]);
    expect(resMeta.exitCode, 0,
        reason: 'generated Python meta module must compile:\n${resMeta.stderr}');
  });
}

/// Resolves a `python3` executable from PATH, or `null` when none is available.
String? _whichPython3() {
  final which = Platform.isWindows ? 'where' : 'which';
  final res = Process.runSync(which, ['python3']);
  if (res.exitCode != 0) return null;
  final out = (res.stdout as String).trim();
  if (out.isEmpty) return null;
  return out.split(RegExp(r'[\r\n]+')).first.trim();
}
