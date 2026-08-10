/// Fingerprints `tom_specs_model` — the input every committed artifact
/// `bin/generate_som.dart` writes is generated from — so a model edit that was
/// never followed by a regeneration fails a test instead of shipping.
///
/// That is the nine `tom_som_<slug>_v0` packages **and** the `spec_ops.g.dart`
/// registry inside the model package itself (see `spec_ops_build.dart`). One
/// command produces them from one analyzer pass over one input, so one
/// fingerprint certifies them all.
///
/// ## Why this exists
///
/// The generated artifacts are **generator output that is committed**: nine sets
/// of sources, `meta/spec_model.meta.json` and 14 DocSpecs schemas, plus the
/// registry. Nothing verified that the committed output still described the
/// model. Regeneration happened only when whoever changed `tom_specs_model`
/// remembered to run `bin/generate_som.dart`, so a model change could merge with
/// all nine packages describing the *previous* model and no test would go red.
///
/// That is not hypothetical. The packages were stale from the commit that routed
/// CE-MG into Phase 3 until the next unrelated regeneration, which silently
/// absorbed the catch-up — and in doing so made that later change's diff
/// overstate what it had actually changed.
///
/// ## Why the model source rather than the outputs
///
/// The meta tree is generated **first** and every language derives from it, so
/// one fingerprint over the model covers all nine — and the nine committed metas
/// do in fact carry one identical substantive payload, which
/// [ModelSurface.packages] plus the coverage guard keeps true.
///
/// It covers the registry for a plainer reason: the registry is emitted from the
/// same [ModelReader] file set the fingerprint is taken over, by the same run.
/// The registry's own file is *not* in that set — `lib/src/generated/` is one of
/// [ModelReader.excludedSrcDirs] — which is what makes it an output the stamp
/// certifies rather than an input that would certify itself.
///
/// Fingerprinting the *outputs* would not work at all: `spec_model.meta.json` is
/// generated **from** the model, so a stale package would happily match a stamp
/// taken over its own stale self. The input is the only side that can certify
/// the output.
///
/// ## Why a token stream rather than a file hash
///
/// A hash of raw bytes would never miss a change, but it would fire on
/// `dart format` and on any retouched method body. The remedy for such a false
/// alarm is a full nine-language regeneration that produces no diff, and a gate
/// that costs that much to say "nothing happened" is a gate people learn to
/// re-stamp by hand — which converts a false positive into the *false negative*
/// this guard exists to prevent.
///
/// So the fingerprint is taken over each file's **token stream**:
///
/// - **Formatting** never appears as a token, so `dart format` is free.
/// - **Function bodies** are skipped wholesale. [ModelReader] reads
///   declarations, types and annotations; a body cannot reach the meta.
/// - **Doc comments are rendered, not skipped** — and this is the one place
///   where the model differs from the equivalent guard over the D4rt bridges in
///   `tom_spec_engine`. `ModelJsonExporter` exports every class's and member's
///   doc comment into the meta as `docComment`, so rewording one *does* change
///   all nine packages. Ordinary `//` comments reach nothing and are skipped.
///
/// The parse is **syntactic** (no resolution, no dependency graph), which keeps
/// the whole model under a second — resolving it costs ~10 s, far too much for a
/// check that must live in the default suite.
///
/// The precision given up is private declarations: renaming a private helper in
/// the model moves the fingerprint even though the emitted packages are
/// unaffected. That is a rare, loud, one-regeneration cost, and it is the right
/// side to err on — the alternative failure is silence.
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'serialization_order.dart' show collectModelSourceFiles;
import 'spec_object_model_config.dart';

/// Where the recorded fingerprint lives, relative to the `tom_specs_clitool`
/// project root.
///
/// It sits beside the generator that writes it rather than under `lib/`, because
/// it is build metadata and must never ship in the package's API.
const modelSurfaceStampPath = 'tool/model_surface.stamp.json';

/// The state of `tom_specs_model` at the moment the committed `tom_som_*`
/// packages were generated from it.
class ModelSurface {
  const ModelSurface({
    required this.fingerprint,
    required this.fileCount,
    required this.declarationCount,
    required this.packages,
  });

  /// Hash over the model's rendered token stream — the single value the guard
  /// compares.
  final String fingerprint;

  /// Model source files that went into the fingerprint. Carried so a stamp diff
  /// is readable by a human: "a file was added" says more than a changed hex
  /// string.
  final int fileCount;

  /// Top-level declarations across those files, for the same reason.
  final int declarationCount;

  /// The generated package names this fingerprint certifies, sorted. Adding a
  /// tenth language to `tom_som.yaml` must not leave the guard passing while the
  /// thing it guards has grown — see [somPackageCoverageMismatch].
  final List<String> packages;

  Map<String, Object?> toJson() => {
        'fingerprint': fingerprint,
        'fileCount': fileCount,
        'declarationCount': declarationCount,
        'packages': packages,
      };

  static ModelSurface fromJson(Map<String, Object?> json) => ModelSurface(
        fingerprint: json['fingerprint']! as String,
        fileCount: json['fileCount']! as int,
        declarationCount: json['declarationCount']! as int,
        packages: (json['packages']! as List).cast<String>(),
      );
}

/// The fingerprint of one set of Dart source files.
class LibrarySurface {
  const LibrarySurface(this.hash, this.fileCount, this.declarationCount);
  final String hash;
  final int fileCount;
  final int declarationCount;
}

/// Fingerprints [files], rendering each relative to [rootDir].
///
/// Public so the guard's *reactivity* can be tested against a handful of
/// purpose-written files rather than only against the real model, where a test
/// could assert that the fingerprint is stable but never that it moves for the
/// right reasons.
LibrarySurface fingerprintSources(List<File> files, {required String rootDir}) {
  final sorted = [...files]..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer();
  var declarations = 0;
  for (final file in sorted) {
    // Relative, so the hash does not depend on where the workspace is checked
    // out — nor, for the tests, on the temp directory of the day.
    final relative = p.relative(file.path, from: rootDir).replaceAll(r'\', '/');
    final rendered = _renderUnit(file);
    declarations += rendered.declarationCount;
    if (rendered.text.isEmpty) continue;
    buffer
      ..writeln('// $relative')
      ..write(rendered.text);
  }

  return LibrarySurface(_sha256(buffer.toString()), sorted.length, declarations);
}

/// Computes the current model fingerprint.
///
/// [modelPackagePath] is the `tom_specs_model` package root. [packages] are the
/// generated package names the resulting stamp certifies (see
/// [ModelSurface.packages]).
ModelSurface computeModelSurface({
  required String modelPackagePath,
  required List<String> packages,
}) {
  final root = p.join(modelPackagePath, 'lib', 'src');

  // Exactly the file set `ModelReader` reflects, plus the version stamp: three
  // of the meta's fields (`modelVersion`, `modelVersionLabel`, `generatedAt`)
  // are read straight out of `version.versioner.dart`, so a model rebuild that
  // moved them leaves the committed metas claiming an older build.
  final files = collectModelSourceFiles(modelPackagePath);
  final versioner = File(p.join(root, 'version.versioner.dart'));
  if (!versioner.existsSync()) {
    throw StateError('model version stamp not found at ${versioner.path}');
  }

  final surface =
      fingerprintSources([...files, versioner], rootDir: root);

  return ModelSurface(
    fingerprint: surface.hash,
    fileCount: surface.fileCount,
    declarationCount: surface.declarationCount,
    packages: [...packages]..sort(),
  );
}

/// Reads the recorded stamp, or `null` when it has not been written yet.
ModelSurface? readModelSurfaceStamp({required String clitoolRoot}) {
  final file = File(p.join(clitoolRoot, modelSurfaceStampPath));
  if (!file.existsSync()) return null;
  return ModelSurface.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
}

/// Writes [surface] to the stamp file. Called by `bin/generate_som.dart`, never
/// by a test — a test that could re-stamp would only ever agree with itself.
void writeModelSurfaceStamp(
  ModelSurface surface, {
  required String clitoolRoot,
}) {
  final file = File(p.join(clitoolRoot, modelSurfaceStampPath))
    ..parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(surface.toJson())}\n');
}

/// The generated package name for each target in [config] — the basename of its
/// output root, so an explicit `output:` override is honoured.
List<String> configuredPackageNames(SpecObjectModelConfig config) =>
    [for (final t in config.languages) p.basename(t.outputRoot)]..sort();

/// Returns a description of any disagreement between the languages configured in
/// `tom_som.yaml` and the packages a stamp certifies, or `null` when they match.
///
/// Two ways the fingerprint alone would not notice a problem, both covered here:
/// a language added to the config but never generated (the stamp certifies eight
/// packages while nine are configured), and a configured package whose directory
/// is not on disk at all.
///
/// [configDir] is the directory the config's `output-base` resolves against —
/// the config file's own directory, matching `bin/generate_som.dart`.
String? somPackageCoverageMismatch({
  required SpecObjectModelConfig config,
  required String configDir,
  required List<String> stampedPackages,
}) {
  final configured = configuredPackageNames(config).toSet();
  final stamped = stampedPackages.toSet();

  final missing = configured.difference(stamped);
  if (missing.isNotEmpty) {
    return 'tom_som.yaml configures ${_list(missing)} but the stamp does not '
        'certify it — the package was never generated from the stamped model';
  }
  final extra = stamped.difference(configured);
  if (extra.isNotEmpty) {
    return 'the stamp certifies ${_list(extra)} but tom_som.yaml no longer '
        'configures it';
  }

  for (final target in config.languages) {
    final dir = Directory(p.normalize(p.join(configDir, target.outputRoot)));
    if (!dir.existsSync()) {
      return 'configured package ${p.basename(target.outputRoot)} has no '
          'directory at ${dir.path}';
    }
  }
  return null;
}

String _list(Set<String> names) => (names.toList()..sort()).join(', ');

String _sha256(String text) => sha256.convert(utf8.encode(text)).toString();

class _RenderedUnit {
  const _RenderedUnit(this.text, this.declarationCount);

  /// The canonical token rendering of the file.
  final String text;

  /// Top-level declarations in the file.
  final int declarationCount;
}

/// Renders [file]'s token stream: doc comments in, ordinary comments and
/// function bodies out.
_RenderedUnit _renderUnit(File file) {
  final unit = parseFile(
    path: file.absolute.path,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  ).unit;

  // Offset of each function body's first token -> the token that follows the
  // body. Walking the stream then skips the body in one hop.
  final bodySkips = <int, Token>{};
  unit.accept(_FunctionBodyCollector(bodySkips));

  final buffer = StringBuffer();
  var token = unit.beginToken;
  while (true) {
    // Comments hang off tokens as `precedingComments` and are never reached by a
    // walk along `Token.next`, so they have to be rendered explicitly. Only doc
    // comments are: they are exported into the meta verbatim, whereas an
    // ordinary `//` comment reaches no generated artefact.
    for (Token? c = token.precedingComments; c != null; c = c.next) {
      if (_isDocComment(c.lexeme)) buffer.write('${c.lexeme} ');
    }
    if (token.isEof) break;

    final skipTo = bodySkips[token.offset];
    if (skipTo != null) {
      // A body is opaque to the reader; record only that one was present, so
      // that `=> x;` becoming `{ return x; }` is not itself a model change.
      buffer.write('<body> ');
      token = skipTo;
      continue;
    }
    buffer.write('${token.lexeme} ');
    token = token.next!;
  }

  return _RenderedUnit(buffer.toString(), unit.declarations.length);
}

bool _isDocComment(String lexeme) =>
    lexeme.startsWith('///') || lexeme.startsWith('/**');

/// Records the token span of every function body in the unit.
///
/// All four body forms are collected. `EmptyFunctionBody` (`;`) is deliberately
/// included so that giving an abstract member an implementation — which the
/// reader does not care about — does not move the fingerprint either.
class _FunctionBodyCollector extends RecursiveAstVisitor<void> {
  _FunctionBodyCollector(this.skips);

  final Map<int, Token> skips;

  void _record(FunctionBody body) {
    final next = body.endToken.next;
    if (next != null) skips[body.beginToken.offset] = next;
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _record(node);
    // Not descending: nested closures live inside a body that is already being
    // skipped, so collecting them would be wasted work.
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) => _record(node);

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) => _record(node);

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) => _record(node);
}
