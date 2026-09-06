/// Drives the `spec_ops.g.dart` generation: model in, committed registry out.
///
/// [SpecOpsGenerator] is pure — resolved model classes in, source text out.
/// This is the I/O half around it: it reads `tom_specs_model` with the analyzer
/// and writes the registry to its one committed home.
///
/// ## Why this is a library function and not only a CLI
///
/// `spec_ops.g.dart` is the **third** artifact generated out of
/// `tom_specs_model`, beside the nine `tom_som_<slug>_v0` packages and the D4rt
/// bridges in `tom_spec_engine`. It is generated code that is committed *into
/// the model package itself*, and it is data as far as the compiler is
/// concerned — a registry of closures — so a stale one does not fail to build.
/// It fails to *carry* something, silently.
///
/// While it could only be produced by its own CLI, it was regenerated only when
/// the editor's app build (`bin/build.dart`) ran. A model change follows the
/// regeneration chain in `_copilot_guidelines/som_regeneration.md`, which
/// nothing connected to this artifact, so the registry could sit a whole
/// campaign behind the model: a campaign that gave 116 section classes a
/// `content: String?` override left every one of them with no
/// `..content = n.content` in its `cloneShallow` (a copy-on-write clone dropped
/// the section's prose) and no `yamlScalar` at all (the prose did not
/// serialize). Nothing went red.
///
/// Exposing generation as a call is what lets `bin/generate_som.dart` — the
/// canonical regeneration command, which already reads the model with the same
/// analyzer — produce this artifact too, so one command leaves the whole tree
/// consistent and the model fingerprint that command stamps certifies all
/// three.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'analyzer_bootstrap.dart';
import 'model_reader.dart';
import 'spec_ops_generator.dart';

/// The registry's committed home, as path segments relative to the
/// `tom_specs_model` package root.
///
/// Named once because three entry points write it — `bin/generate_som.dart`,
/// `bin/spec_ops.dart` and the editor build's step 2 — and a registry written
/// to two different paths is a registry nothing loads.
const specOpsPathSegments = ['lib', 'src', 'generated', 'spec_ops.g.dart'];

/// The registry's absolute path inside the model package at
/// [modelPackagePath].
String specOpsOutputFor(String modelPackagePath) =>
    p.normalize(p.joinAll([modelPackagePath, ...specOpsPathSegments]));

/// What one [generateSpecOpsRegistry] run produced.
class SpecOpsResult {
  /// Records what one generation run produced.
  ///
  /// [changed] is carried separately from the counts because a run that
  /// regenerated an identical file and one that rewrote it are the same size
  /// and mean different things to a build that stages its output.
  const SpecOpsResult({
    required this.outputPath,
    required this.classCount,
    required this.changed,
  });

  /// Where the registry was written.
  final String outputPath;

  /// Model classes the reader resolved — the registry's input size.
  final int classCount;

  /// Whether the emitted source differs from what was already on disk.
  ///
  /// Generation is idempotent, so `false` is the ordinary outcome of a re-run
  /// against an unchanged model; a `true` on a run nobody expected to change
  /// anything is the signal that the committed registry had gone stale.
  final bool changed;
}

/// Regenerates the `spec_ops.g.dart` registry from the model package at
/// [modelPackagePath], writing it to [specOpsOutputFor] unless [outputPath]
/// names somewhere else.
///
/// Throws a [StateError] when the model package has no `lib/`.
Future<SpecOpsResult> generateSpecOpsRegistry({
  required String modelPackagePath,
  String? outputPath,
}) async {
  final packageRoot = p.normalize(p.absolute(modelPackagePath));
  final libPath = p.join(packageRoot, 'lib');
  if (!Directory(libPath).existsSync()) {
    throw StateError('lib/ directory not found at $libPath');
  }
  final target = p.normalize(
      p.absolute(outputPath ?? specOpsOutputFor(packageRoot)));

  final reader = ModelReader(createAnalysisDriver(packageRoot));
  await reader.analyzePackage(libPath);
  final source = SpecOpsGenerator(reader.classes).generate();

  final file = File(target)..parent.createSync(recursive: true);
  final changed = !file.existsSync() || file.readAsStringSync() != source;
  if (changed) file.writeAsStringSync(source);

  return SpecOpsResult(
    outputPath: target,
    classCount: reader.classes.length,
    changed: changed,
  );
}
