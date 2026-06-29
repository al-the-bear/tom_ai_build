@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// End-to-end tests for the **Rust** `v0` SOM generator (plan item #11). They
/// mirror `som_java_generator_test.dart` / `som_go_generator_test.dart`: the real
/// `tom_specs_model` is analysed once (shared via [setUpAll]), then the
/// deterministic write step is exercised and the committed-artefact contract is
/// asserted — a valid meta-data file (which is **byte-identical to the Dart
/// path**, since meta-data is language-agnostic), the typed Rust facade source
/// (`src/lib.rs`), the 13 DocSpecs schemas, a portable (relative runtime path)
/// `Cargo.toml`, and byte-stable idempotency.
///
/// One Rust-specific check beyond the Dart suite: the emitted crate must compile
/// under `cargo build` against the generic runtime (skipped cleanly when no
/// `cargo` toolchain is available), which is the real guard against
/// keyword/identifier collisions across the 3000+ class model.
void main() {
  // Locate the sibling packages relative to this clitool package.
  final clitoolRoot = Directory.current.path;
  final aiBuild = p.dirname(clitoolRoot);
  final modelDir = p.join(aiBuild, 'tom_specs_model');
  final dartRuntimeDir = p.join(aiBuild, 'tom_som_dart_runtime');
  final rustRuntimeDir = p.join(aiBuild, 'tom_som_rust_runtime');

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

  SomRustGenerationResult writeInto(Directory dir) => writeSomRustProject(
        classes: classes,
        runtimePackagePath: rustRuntimeDir,
        outputRoot: dir.path,
        modelVersion: modelVersion,
        modelLabel: modelLabel,
        generatedAt: generatedAt,
      );

  test('writes the full Rust v0 artefact tree with a valid, stamped meta-data',
      () {
    final dir = Directory.systemTemp.createTempSync('som_rust_gen_');
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

    // Typed facade source exists at the crate root and declares the global root
    // struct.
    final source = File(result.libPath).readAsStringSync();
    expect(source, contains('pub struct SolutionBlueprint {'));
    expect(source, contains('use tom_som_rust_runtime as som;'));
    expect(result.libPath, endsWith(p.join('src', 'lib.rs')));

    // One DocSpecs schema per @Document root (13).
    expect(result.schemaPaths.length, 13);
    for (final s in result.schemaPaths) {
      expect(File(s).existsSync(), isTrue);
    }

    // Cargo.toml records a *relative* runtime `path` dependency (portable across
    // checkouts) that resolves back to the rust runtime crate.
    final cargo = File(result.cargoTomlPath).readAsStringSync();
    expect(cargo, contains('name = "tom_som_rust_v0"'));
    final m = RegExp(r'tom_som_rust_runtime = \{ path = "([^"]+)" \}')
        .firstMatch(cargo);
    expect(m, isNotNull, reason: 'Cargo.toml must record a runtime path dep');
    final rtPath = m!.group(1)!;
    expect(p.isRelative(rtPath), isTrue,
        reason: 'runtime path must be relative, got $rtPath');
    expect(p.normalize(p.join(result.outputRoot, rtPath)),
        p.normalize(rustRuntimeDir),
        reason: 'relative path must resolve to the rust runtime crate');
  });

  test('the Rust meta-data is byte-identical to the Dart path', () {
    // Both languages share the same language-agnostic meta-data; prove it by
    // writing a Dart tree with the same stamp and comparing the meta bytes.
    final rust = Directory.systemTemp.createTempSync('som_rust_meta_');
    final dart = Directory.systemTemp.createTempSync('som_dart_meta_');
    addTearDown(() => rust.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rr = writeInto(rust);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(File(rr.metaJsonPath).readAsStringSync(),
        File(rd.metaJsonPath).readAsStringSync(),
        reason: 'meta-data must be language-agnostic / byte-identical');
  });

  test('the Rust DocSpecs schemas are byte-identical to the Dart path', () {
    final rust = Directory.systemTemp.createTempSync('som_rust_sch_');
    final dart = Directory.systemTemp.createTempSync('som_dart_sch_');
    addTearDown(() => rust.deleteSync(recursive: true));
    addTearDown(() => dart.deleteSync(recursive: true));

    final rr = writeInto(rust);
    final rd = writeSomDartProject(
      classes: classes,
      runtimePackagePath: dartRuntimeDir,
      outputRoot: dart.path,
      modelVersion: modelVersion,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
    expect(rr.schemaPaths.map((s) => p.basename(s)).toList(),
        rd.schemaPaths.map((s) => p.basename(s)).toList());
    for (var i = 0; i < rr.schemaPaths.length; i++) {
      expect(File(rr.schemaPaths[i]).readAsStringSync(),
          File(rd.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(rr.schemaPaths[i])} must be '
              'language-agnostic / byte-identical');
    }
  });

  test('regeneration is idempotent (byte-stable output for unchanged input)',
      () {
    final a = Directory.systemTemp.createTempSync('som_rust_a_');
    final b = Directory.systemTemp.createTempSync('som_rust_b_');
    addTearDown(() => a.deleteSync(recursive: true));
    addTearDown(() => b.deleteSync(recursive: true));
    final ra = writeInto(a);
    final rb = writeInto(b);

    expect(File(rb.libPath).readAsStringSync(),
        File(ra.libPath).readAsStringSync());
    expect(File(rb.metaJsonPath).readAsStringSync(),
        File(ra.metaJsonPath).readAsStringSync());
    expect(File(rb.cargoTomlPath).readAsStringSync(),
        File(ra.cargoTomlPath).readAsStringSync());
    for (var i = 0; i < ra.schemaPaths.length; i++) {
      expect(File(rb.schemaPaths[i]).readAsStringSync(),
          File(ra.schemaPaths[i]).readAsStringSync(),
          reason: 'schema ${p.basename(ra.schemaPaths[i])} must be stable');
    }
  });

  test('the analyze+write path matches the write-only path', () async {
    final viaWrite = Directory.systemTemp.createTempSync('som_rust_w_');
    final viaFull = Directory.systemTemp.createTempSync('som_rust_f_');
    addTearDown(() => viaWrite.deleteSync(recursive: true));
    addTearDown(() => viaFull.deleteSync(recursive: true));

    final rw = writeInto(viaWrite);
    final rf = await generateSomRustProject(
      modelPackagePath: modelDir,
      runtimePackagePath: rustRuntimeDir,
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

  test('the emitted crate compiles under cargo build', () {
    final cargo = _cargo();
    if (cargo == null) {
      markTestSkipped('no cargo toolchain found');
      return;
    }
    if (!Directory(rustRuntimeDir).existsSync()) {
      markTestSkipped('tom_som_rust_runtime not found');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('som_rust_compile_');
    addTearDown(() => dir.deleteSync(recursive: true));
    writeInto(dir);

    final build = Process.runSync(cargo, ['build'], workingDirectory: dir.path);
    expect(build.exitCode, 0,
        reason: 'generated Rust crate must compile:\n'
            '${build.stdout}\n${build.stderr}');
  });
}

/// Locates a `cargo` toolchain — on PATH, or the conventional `~/.cargo/bin/cargo`
/// rustup install used on the fleet's build hosts. Returns `null` when none.
String? _cargo() {
  try {
    final r = Process.runSync('cargo', ['--version']);
    if (r.exitCode == 0) return 'cargo';
  } on ProcessException {
    // not on PATH
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    final cand = p.join(home, '.cargo', 'bin', 'cargo');
    if (File(cand).existsSync()) return cand;
  }
  return null;
}
