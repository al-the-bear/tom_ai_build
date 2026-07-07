@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the `v0` SOM generator (plan item #7). They run the
/// real `tom_specs_model` through the analyzer once (shared via [setUpAll]),
/// then exercise the deterministic write step and assert the committed-artefact
/// contract: a valid meta-data file, the typed Dart facade, the 13 DocSpecs
/// schemas, a publishable pubspec (hosted model-version dep) with a local-dev
/// `pubspec_overrides.yaml`, and byte-stable idempotency.
void main() {
  // Locate the sibling packages relative to this clitool package.
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final runtimeDir = p.join(aiBuild, 'tom_som_dart_runtime');

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

  SomGenerationResult writeInto(Directory dir) => writeSomDartProject(
        classes: classes,
        runtimePackagePath: runtimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full v0 artefact tree with a valid, stamped meta-data file',
      () {
    final dir = Directory.systemTemp.createTempSync('som_gen_');
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

    // Typed facade exists and declares the global root.
    final lib = File(result.libPath).readAsStringSync();
    expect(lib, contains('class D00SolutionBlueprint extends SomNode'));
    expect(result.libPath, endsWith('lib/tom_som_dart_v0.dart'));

    // One DocSpecs schema per @Document root (13).
    expect(result.schemaPaths.length, 13);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // Pubspec is publishable (PGK2): the runtime dependency is *hosted* and
    // pinned to the model version, and there is no `publish_to: none`. The
    // relative path that keeps the co-developed runtime resolvable locally lives
    // in a separate `pubspec_overrides.yaml` (excluded from `dart pub publish`).
    final pubspec = File(result.pubspecPath).readAsStringSync();
    expect(pubspec, contains('name: tom_som_dart_v0'));
    expect(pubspec, isNot(contains('publish_to: none')),
        reason: 'a publishable facade must not opt out of publishing');
    expect(pubspec, contains('version: 1.0.0'),
        reason: 'facade version is the TomSpecs model version');
    expect(pubspec, contains('tom_som_dart_runtime: ^1.0.0'),
        reason: 'runtime dep must be a hosted, model-version-pinned constraint');
    expect(RegExp(r'path:\s').hasMatch(pubspec), isFalse,
        reason: 'no path dependency may remain in the publishable pubspec');

    // The local-development override resolves the runtime by a relative path.
    final overrides = File(
        p.join(p.dirname(result.pubspecPath), 'pubspec_overrides.yaml'));
    expect(overrides.existsSync(), isTrue,
        reason: 'generator must emit pubspec_overrides.yaml for local dev');
    final overrideText = overrides.readAsStringSync();
    expect(overrideText, contains('dependency_overrides:'));
    final depPath = RegExp(r'path:\s*(\S+)').firstMatch(overrideText)!.group(1)!;
    expect(p.isRelative(depPath), isTrue,
        reason: 'override runtime dep must be a relative path, got $depPath');
    expect(p.normalize(p.join(result.outputRoot, depPath)),
        p.normalize(runtimeDir),
        reason: 'relative override dep must resolve to tom_som_dart_runtime');
  });

  test('regeneration is idempotent (byte-stable output for unchanged input)',
      () {
    final a = Directory.systemTemp.createTempSync('som_gen_a_');
    final b = Directory.systemTemp.createTempSync('som_gen_b_');
    addTearDown(() => a.deleteSync(recursive: true));
    addTearDown(() => b.deleteSync(recursive: true));
    final ra = writeInto(a);
    final rb = writeInto(b);

    expect(File(rb.libPath).readAsStringSync(),
        File(ra.libPath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.pubspecPath).readAsStringSync(),
        File(ra.pubspecPath).readAsStringSync());
    expect(rb.schemaPaths.map((s) => p.basename(s)).toList(),
        ra.schemaPaths.map((s) => p.basename(s)).toList());
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the analyze+write path matches the write-only path', () async {
    final viaWrite = Directory.systemTemp.createTempSync('som_gen_w_');
    final viaFull = Directory.systemTemp.createTempSync('som_gen_f_');
    addTearDown(() => viaWrite.deleteSync(recursive: true));
    addTearDown(() => viaFull.deleteSync(recursive: true));

    final rw = writeInto(viaWrite);
    final rf = await generateSomDartProject(
      modelPackagePath: modelDir,
      runtimePackagePath: runtimeDir,
      outputRoot: viaFull.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rf.libPath).readAsStringSync(),
        File(rw.libPath).readAsStringSync());
    expect(File(rf.metaJsonPath).readAsStringSync(),
        File(rw.metaJsonPath).readAsStringSync());
  });
}
