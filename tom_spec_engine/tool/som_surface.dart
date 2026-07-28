/// Fingerprints the **public API surface** of the SOM packages that the
/// generated D4rt bridges (`lib/src/bridges/*.b.dart`) are produced from.
///
/// ## Why this exists
///
/// The bridges are generated *here*, in the engine, from two path siblings that
/// are edited *elsewhere* (`tom_som_dart_runtime`, `tom_som_dart_v0`). Nothing
/// in those packages' own workflow prompts a regen, so an edit to their public
/// surface silently invalidates the committed bridges. Two failure modes follow,
/// and only one of them is self-announcing:
///
/// - **Breaking staleness** — SOM *removes* or *renames* a member the bridge
///   still references. `dart analyze` catches this, because the bridge stops
///   compiling. It is loud, but only for whoever next runs the engine's gates.
/// - **Silent staleness** — SOM *adds* a class or member. The bridge simply
///   does not expose it. Nothing goes red, ever; the D4rt scripting surface is
///   just quietly incomplete.
///
/// Hashing the surface catches both, at the moment the engine's own suite runs,
/// which is the gate that already exists. See
/// `_copilot_guidelines/bridge_regeneration.md`.
///
/// ## Why a syntactic parse rather than a file hash
///
/// A hash of raw file bytes would be simpler and would never miss a change —
/// but it would also fire on a reflowed doc comment or a retouched method body.
/// The remedy for such a false alarm is a full regen (~12 s warm, ~80 s cold)
/// that produces a timestamp-only diff, and a gate that costs that much to say
/// "nothing happened" is a gate people learn to re-stamp by hand. That converts
/// a false positive into a *false negative*, which is the failure this guard
/// exists to prevent.
///
/// So the fingerprint is taken over each library's **token stream**, minus two
/// things that provably cannot reach the bridges:
///
/// - **Comments**, which hang off tokens as `precedingComments` and are simply
///   never visited by a walk along `Token.next`. Reflowing a doc comment or
///   rewording it is therefore free.
/// - **Function bodies**, whose token span is skipped wholesale. The generator
///   binds signatures, not implementations, so a body rewrite cannot change
///   what it emits.
///
/// Whitespace and formatting never appear as tokens at all, so `dart format`
/// is likewise free. Parsing is **syntactic** (no resolution, no dependency
/// graph), which is what keeps it to roughly a second over ~10 MB of Dart.
///
/// ## Why the token stream rather than reconstructed declarations
///
/// An earlier cut of this file rebuilt each declaration from the typed AST
/// (`ClassDeclaration.name`, `.typeParameters`, `.members`, …), which is more
/// selective — it can drop private members too. It was abandoned because that
/// half of the AST is mid-migration: analyzer 10 deprecates `name`,
/// `typeParameters`, `members` and `constants` in favour of `namePart` and
/// `body` to make room for primary constructors, and analyzer 8/9 have no such
/// members. Pinning either way dates the file, and a guard nobody looks at
/// until it fires is exactly the code that must not rot. `Token.next` and
/// `Token.lexeme` have been stable for a decade and span the whole `>=8 <11`
/// range this package allows.
///
/// The precision given up is private declarations: renaming a private helper in
/// a SOM package moves the fingerprint even though the bridges are unaffected.
/// That is a rare, *loud*, one-regen-and-re-stamp cost, and it is the right side
/// to err on — the alternative failure is silence.
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:crypto/crypto.dart';

/// The SOM packages the bridges are generated from, as paths relative to the
/// engine's project root.
///
/// This mirrors the `modules:` list in `buildkit.yaml` — the two must name the
/// same packages, and [somSurfaceModuleMismatch] checks exactly that so a third
/// module added to the generator config cannot go unfingerprinted.
const somPackagePaths = <String, String>{
  'tom_som_dart_runtime': '../tom_som_dart_runtime',
  'tom_som_dart_v0': '../tom_som_dart_v0',
};

/// Where the recorded fingerprint lives, relative to the engine's project root.
///
/// It sits beside the regenerator that writes it rather than under `lib/`,
/// because it is build metadata and must never ship in the engine's API.
const somSurfaceStampPath = 'tool/som_surface.stamp.json';

/// The public surface of the SOM packages at a point in time.
class SomSurface {
  /// Hash over every package's rendering — the single value the guard compares.
  final String fingerprint;

  /// Per-package hashes, so a mismatch report can name which package moved.
  final Map<String, String> perPackage;

  /// Public declaration counts per package, purely so a stamp diff is readable
  /// by a human ("+3 declarations" says more than a changed hex string).
  final Map<String, int> declarationCounts;

  const SomSurface({
    required this.fingerprint,
    required this.perPackage,
    required this.declarationCounts,
  });

  Map<String, Object?> toJson() => {
        'fingerprint': fingerprint,
        'perPackage': perPackage,
        'declarationCounts': declarationCounts,
      };

  static SomSurface fromJson(Map<String, Object?> json) => SomSurface(
        fingerprint: json['fingerprint']! as String,
        perPackage: (json['perPackage']! as Map).cast<String, String>(),
        declarationCounts:
            (json['declarationCounts']! as Map).cast<String, int>(),
      );
}

/// The surface of a single package's `lib/` tree.
class PackageSurface {
  final String hash;
  final int declarationCount;
  const PackageSurface(this.hash, this.declarationCount);
}

/// Fingerprints one `lib/` tree.
///
/// Public so the guard's *reactivity* can be tested against a handful of
/// purpose-written files rather than only against the real ~10 MB tree, where a
/// test could assert that the fingerprint is stable but never that it moves for
/// the right reasons.
PackageSurface fingerprintLibrary(Directory libDir) {
  // Sorted, so the rendering does not depend on filesystem order.
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer();
  var declarations = 0;
  for (final file in files) {
    // Relative, so the hash does not depend on where the workspace is checked
    // out — nor, for the tests, on the temp directory of the day.
    final relative = file.path.substring(libDir.path.length + 1);
    final rendered = _renderUnit(file);
    declarations += rendered.declarationCount;
    if (rendered.text.isEmpty) continue;
    buffer
      ..writeln('// $relative')
      ..write(rendered.text);
  }

  return PackageSurface(_sha256(buffer.toString()), declarations);
}

/// Computes the current SOM public-API fingerprint.
///
/// [engineRoot] is the `tom_spec_engine` project root; the package paths are
/// resolved relative to it so the function works from a test's CWD as well as
/// from the regenerator.
SomSurface computeSomSurface({required String engineRoot}) {
  final perPackage = <String, String>{};
  final counts = <String, int>{};

  for (final entry in somPackagePaths.entries) {
    // Normalized, because the package paths are siblings (`../tom_som_…`) and
    // the analyzer's `parseFile` rejects a path that still carries `..`
    // segments. Lexical normalization only — resolving symlinks would make the
    // rendered relative paths depend on how the workspace is mounted.
    final libDir = Directory(
      Uri.file('$engineRoot/${entry.value}/lib').normalizePath().toFilePath(),
    );
    if (!libDir.existsSync()) {
      throw StateError(
        'SOM package "${entry.key}" not found at ${libDir.path}. The '
        'fingerprint cannot be computed without it.',
      );
    }

    final surface = fingerprintLibrary(libDir);
    perPackage[entry.key] = surface.hash;
    counts[entry.key] = surface.declarationCount;
  }

  // Hash the per-package hashes rather than the concatenated text: the combined
  // value then changes if and only if some package's own value changed.
  final combined = (perPackage.keys.toList()..sort())
      .map((k) => '$k=${perPackage[k]}')
      .join('\n');

  return SomSurface(
    fingerprint: _sha256(combined),
    perPackage: perPackage,
    declarationCounts: counts,
  );
}

/// Reads the recorded stamp, or `null` when it has not been written yet.
SomSurface? readSomSurfaceStamp({required String engineRoot}) {
  final file = File('$engineRoot/$somSurfaceStampPath');
  if (!file.existsSync()) return null;
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return SomSurface.fromJson(json);
}

/// Writes [surface] to the stamp file. Called by the regenerator, never by a
/// test — a test that could re-stamp would only ever agree with itself.
void writeSomSurfaceStamp(SomSurface surface, {required String engineRoot}) {
  final file = File('$engineRoot/$somSurfaceStampPath');
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(surface.toJson())}\n');
}

/// Returns a description of any disagreement between [somPackagePaths] and the
/// `modules:` in `buildkit.yaml`, or `null` when they name the same packages.
///
/// Without this, adding a third module to the generator config would leave that
/// package's surface unfingerprinted — the guard would go on passing while the
/// thing it guards had grown.
String? somSurfaceModuleMismatch({required String engineRoot}) {
  final config = File('$engineRoot/buildkit.yaml');
  if (!config.existsSync()) return 'buildkit.yaml not found at ${config.path}';

  // Deliberately a line scan rather than a YAML parse: the only thing needed is
  // the set of bridged package names, and they appear verbatim in the
  // `barrelImport:` lines. This keeps the guard free of a yaml dependency.
  final bridged = <String>{};
  for (final line in config.readAsLinesSync()) {
    final match =
        RegExp(r'barrelImport:\s*package:([a-z0-9_]+)/').firstMatch(line);
    if (match != null) bridged.add(match.group(1)!);
  }

  final fingerprinted = somPackagePaths.keys.toSet();
  if (bridged.isEmpty) return 'no `barrelImport:` entries found in buildkit.yaml';
  if (bridged.difference(fingerprinted).isNotEmpty) {
    return 'buildkit.yaml bridges ${bridged.difference(fingerprinted)} but '
        'somPackagePaths does not fingerprint it';
  }
  if (fingerprinted.difference(bridged).isNotEmpty) {
    return 'somPackagePaths fingerprints ${fingerprinted.difference(bridged)} '
        'but buildkit.yaml no longer bridges it';
  }
  return null;
}

String _sha256(String text) => sha256.convert(utf8.encode(text)).toString();

class _RenderedUnit {
  /// The canonical token rendering of the library.
  final String text;

  /// Top-level declarations in the library. Carried only so a stamp diff reads
  /// as "+3 declarations" rather than as a changed hex string.
  final int declarationCount;

  const _RenderedUnit(this.text, this.declarationCount);
}

/// Renders [file]'s token stream, minus comments and minus function bodies.
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
  while (!token.isEof) {
    final skipTo = bodySkips[token.offset];
    if (skipTo != null) {
      // A body is opaque to the generator; record only that one was present, so
      // that `=> x;` becoming `{ return x; }` is not itself a surface change.
      buffer.write('<body> ');
      token = skipTo;
      continue;
    }
    buffer.write('${token.lexeme} ');
    token = token.next!;
  }

  return _RenderedUnit(buffer.toString(), unit.declarations.length);
}

/// Records the token span of every function body in the unit.
///
/// All four body forms are collected. `EmptyFunctionBody` (`;`) is deliberately
/// included so that giving an abstract method an implementation — which the
/// generator does not care about — does not move the fingerprint either.
class _FunctionBodyCollector extends RecursiveAstVisitor<void> {
  final Map<int, Token> skips;

  _FunctionBodyCollector(this.skips);

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
