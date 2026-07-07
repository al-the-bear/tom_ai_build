/// Runs the full `v0` Spec-Object-Model generation for **Java** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_java_<label>` project (a
/// build manifest + the generated typed `src/` source), the lossless
/// object-model **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the Java counterpart of `som_generator.dart` / `som_python_generator.dart`
/// (plan item #11). The **meta-data file and the DocSpecs schemas are
/// language-agnostic**, so this reuses the exact same [ModelJsonExporter] +
/// [DocSpecsSchemaGenerator] the Dart/Python paths use (byte-identical across
/// languages); only the typed source emitter ([SomJavaEmitter]) and the project
/// manifest differ. Generation is deterministic and idempotency-stabilised (the
/// wall-clock `generatedAt` is overridden with the model build instant), so
/// re-running over an unchanged model is a byte-for-byte no-op.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'analyzer_bootstrap.dart';
import 'docspecs_schema_generator.dart';
import 'model_json_exporter.dart';
import 'model_reader.dart';
import 'packaging.dart' show packageVersionFromModel;
import 'som_java_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the Java generator.
class SomJavaGenerationResult {
  SomJavaGenerationResult({
    required this.outputRoot,
    required this.manifestPath,
    required this.pomPath,
    required this.buildScriptPath,
    required this.sourcePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String manifestPath;

  /// The generator-emitted Maven `pom.xml` for the facade.
  final String pomPath;

  /// The generator-emitted JDK-only `build_jar.sh` fallback for the facade.
  final String buildScriptPath;
  final String sourcePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the Java `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_java_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_java_runtime`; the generated build manifest
///   records its `src/` by a **relative** path (computed from [outputRoot]) so
///   the committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomJavaGenerationResult> generateSomJavaProject({
  required String modelPackagePath,
  required String runtimePackagePath,
  required String outputRoot,
  required int modelVersion,
  required String modelLabel,
  required String generatedAt,
  String versionLabel = 'v0',
  List<String> documentRoots = const [],
}) async {
  final libDir = p.join(modelPackagePath, 'lib');
  if (!Directory(libDir).existsSync()) {
    throw ArgumentError('model lib/ not found at $libDir');
  }

  final driver = createAnalysisDriver(modelPackagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libDir);

  return writeSomJavaProject(
    classes: reader.classes,
    runtimePackagePath: runtimePackagePath,
    outputRoot: outputRoot,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
    generatedAt: generatedAt,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  );
}

/// Writes the Java artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomJavaProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomJavaGenerationResult writeSomJavaProject({
  required Map<String, ModelClass> classes,
  required String runtimePackagePath,
  required String outputRoot,
  required int modelVersion,
  required String modelLabel,
  required String generatedAt,
  String versionLabel = 'v0',
  List<String> documentRoots = const [],
}) {
  final outDir = Directory(outputRoot)..createSync(recursive: true);
  final packageName = 'tom_som_java_$versionLabel';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  // Identical to the Dart/Python path — the meta-data is language-agnostic.
  final meta = ModelJsonExporter(
    classes,
    modelVersion: modelVersion,
    modelVersionLabel: modelLabel,
  ).export();
  meta['generatedAt'] = generatedAt;
  final metaErrors = validateSpecModelMeta(meta);
  if (metaErrors.isNotEmpty) {
    throw StateError('generated meta-data is invalid:\n  '
        '${metaErrors.join('\n  ')}');
  }
  final metaJsonPath = p.join(outputRoot, 'meta', 'spec_model.meta.json');
  final metaFile = File(metaJsonPath)..parent.createSync(recursive: true);
  metaFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(meta)}\n');

  // ── typed Java facade (editing facade over the generic runtime) ────────────
  // A single outer class `TomSomV0` (Java's one-public-class-per-file rule), in
  // package `tom_som_java_v0`, so the source path mirrors the package.
  final model = SpecModel.fromJson(meta);
  final source = SomJavaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final sourcePath =
      p.join(outputRoot, 'src', 'tom_som_java_$versionLabel', 'TomSomV0.java');
  File(sourcePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to the Dart/Python path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── build manifest (relative runtime src for portability) ──────────────────
  // The Java analog of pubspec.yaml / pyproject.toml: zero external deps, so the
  // manifest just records where the generic runtime source lives (relative to
  // this project root) for the compile step to add to the javac source path.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll(r'\\', '/');
  final manifest = <String, Object?>{
    'package': packageName,
    'mainClass': 'tom_som_java_$versionLabel.TomSomV0',
    'generator': 'tom_specs_clitool generate_som',
    'runtimeSourcePath': '$runtimeRel/src',
  };
  final manifestPath = p.join(outputRoot, 'tom_som_build.json');
  File(manifestPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');

  // ── Maven manifest + JDK-only fallback (generator-emitted, versioned) ──────
  // The facade is fully regenerated per model version, so — unlike the runtime,
  // whose hand-authored pom is only version-realigned — the facade's pom.xml and
  // build_jar.sh are emitted here, always carrying the current model version.
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);
  final pomPath = p.join(outputRoot, 'pom.xml');
  File(pomPath).writeAsStringSync(_facadePom(packageName, packageVersion));
  final buildScriptPath = p.join(outputRoot, 'build_jar.sh');
  final buildScript = File(buildScriptPath)
    ..writeAsStringSync(_facadeBuildScript(packageName));
  _makeExecutable(buildScript.path);

  return SomJavaGenerationResult(
    outputRoot: outDir.path,
    manifestPath: manifestPath,
    pomPath: pomPath,
    buildScriptPath: buildScriptPath,
    sourcePath: sourcePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

/// Best-effort `chmod +x` for the emitted shell script on POSIX hosts, so the
/// documented `./build_jar.sh` invocation works. A no-op on Windows and if
/// `chmod` is unavailable — the script is still runnable via `bash build_jar.sh`.
void _makeExecutable(String path) {
  if (Platform.isWindows) return;
  try {
    Process.runSync('chmod', ['+x', path]);
  } on ProcessException {
    // chmod not available — the script is still runnable via `bash`.
  }
}

/// The facade Maven `pom.xml`: coordinates under `com.altbear.tomsom`, the
/// package [version] (= model version), a dependency on the runtime artifact at
/// the same version, and the non-standard flat `src/` source layout.
String _facadePom(String artifactId, String version) => '''
<?xml version="1.0" encoding="UTF-8"?>
<!-- GENERATED by tom_specs_clitool generate_som — do not edit by hand. -->
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.altbear.tomsom</groupId>
  <artifactId>$artifactId</artifactId>
  <!-- Version is the TomSpecs model version — the facade is regenerated per
       model version and always reports it (never maintained independently). -->
  <version>$version</version>
  <packaging>jar</packaging>

  <name>$artifactId</name>
  <description>Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_java_runtime. Regenerate with tom_specs_clitool/bin/generate_som.dart.</description>

  <properties>
    <maven.compiler.release>17</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>com.altbear.tomsom</groupId>
      <artifactId>tom_som_java_runtime</artifactId>
      <version>$version</version>
    </dependency>
  </dependencies>

  <build>
    <!-- Non-standard flat source layout: the generated facade lives in src/. -->
    <sourceDirectory>src</sourceDirectory>
  </build>
</project>
''';

/// The facade JDK-only `build_jar.sh`: the `mvn package` fallback for hosts with
/// only a JDK. Compiles the generic runtime (found via the build manifest's
/// relative `runtimeSourcePath`) together with the generated facade, then jars
/// **only** the facade package (the runtime ships its own jar). The version is
/// read from `pom.xml` so the two never drift.
String _facadeBuildScript(String artifactId) => '''
#!/usr/bin/env bash
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
# JDK-only fallback for `mvn package`: compile the generic runtime + the
# generated typed facade with `javac`, then package *only* the facade classes
# into build/$artifactId-<version>.jar. Build the runtime jar first
# (../tom_som_java_runtime/build_jar.sh) if you need it on the classpath.
#
# The runtime source location is read from tom_som_build.json (runtimeSourcePath,
# relative to this project) and the version from pom.xml, so the script is
# portable across checkouts.
set -euo pipefail

here="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

runtime_rel="\$(grep -o '"runtimeSourcePath"[[:space:]]*:[[:space:]]*"[^"]*"' \\
  "\$here/tom_som_build.json" | sed -E 's/.*"([^"]*)"\$/\\1/')"
runtime="\$(cd "\$here/\$runtime_rel" && pwd)"
version="\$(grep -o '<version>[^<]*</version>' "\$here/pom.xml" | head -1 \\
  | sed -E 's/<version>([^<]*)<\\/version>/\\1/')"

classes="\$here/build/classes"
rm -rf "\$here/build"
mkdir -p "\$classes"

# Compile the facade; javac pulls in the runtime sources it depends on from the
# source path automatically.
javac -d "\$classes" -sourcepath "\$here/src:\$runtime" \\
  "\$here"/src/$artifactId/*.java

# Package only the facade package (the runtime ships its own jar).
jar --create --file "\$here/build/$artifactId-\$version.jar" \\
  -C "\$classes" $artifactId

echo "built \$here/build/$artifactId-\$version.jar"
''';
