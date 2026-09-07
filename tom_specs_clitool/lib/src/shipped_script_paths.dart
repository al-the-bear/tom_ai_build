/// Every path literal in a shipped, consumer-facing script must resolve inside
/// the package that ships it.
///
/// ## The shape of the defect
///
/// `tom_som_dart_v0` published six examples of which **three could not run**:
/// each read
/// `../../tom_som_conformance/samples/meridian_order_management.docspecs.yaml`,
/// and `tom_som_conformance` is not a published package. From a hosted install
/// that path names a directory that does not exist. Four `tool/` scripts and
/// one shipped `test/` file had the same fault. It was found twice by accident
/// — once per sample that tried to reuse the document — which is the reason
/// this check exists rather than a third accident.
///
/// The failure is silent in the worst way: the package resolves, the code
/// compiles, and the script only fails when a consumer runs the one thing an
/// `example/` folder exists to be run.
///
/// ## Two resolution bases, and why both are checked
///
/// A Dart path literal is resolved against one of two different roots, and
/// which one is not visible from the literal:
///
/// * `File('x')` / `Directory('x')` resolve against the **current directory**,
///   which for `dart run` and `dart test` is the *package root*.
/// * `Platform.script.resolve('x')` resolves against the **script's own
///   directory**.
///
/// The original bug appeared in both forms — `../../…` from `example/` via
/// `Platform.script`, and `../…` from the package root in `tool/`. So a literal
/// is accepted when it resolves inside the package under *either* base, and
/// reported only when neither base lands on something that exists within it.
/// That is deliberately generous: the check is for paths that can be shown to
/// be wrong, not for paths that cannot be shown to be right.
///
/// ## Scope
///
/// Consumer-facing script directories of publishable packages — `example/`,
/// `examples/`, `bin/`, and `tool/` — and only when the directory actually
/// ships (a `.pubignore` entry takes it out of the archive, and an unshipped
/// workspace tool is free to read the workspace).
///
/// `test/` is **not** in scope even though `dart pub publish` ships it, and
/// that is a judgement rather than an oversight: a workspace tool's tests are
/// legitimately workspace-bound, and holding them to this rule would report
/// two dozen violations that are all correct as written. The residue is real
/// and is tracked separately.
///
/// ## The one class of path this cannot see
///
/// A path assembled from *components* — `filepath.Join(root, "pkg", "dir",
/// "file")`, and its Python, Rust and JavaScript equivalents — carries no
/// literal beginning `../`, so nothing here matches it. That is not
/// hypothetical: moving the shared sample missed five such paths in the
/// non-Dart runtimes, and the nine-language conformance suite caught them, not
/// this check.
///
/// It is left uncovered deliberately. Recognising a composed path means
/// evaluating an expression, which is a different tool from a lexical scan;
/// and the language that most needs this check — Dart, where the shipped
/// `example/` folder lives — writes its paths as literals. The check is a
/// lexical gate over the consumer-facing surface, and the conformance suite is
/// what covers the rest. Knowing which one covers what is the point of saying
/// so here.
library;

import 'dart:io';

/// Script directories whose contents a consumer is invited to run.
const List<String> shippedScriptDirs = ['example', 'examples', 'bin', 'tool'];

/// One path literal that resolves nowhere inside its own package.
class EscapingPath {
  /// Package-relative path of the file holding the literal.
  final String file;

  /// 1-based line the literal sits on.
  final int line;

  /// The literal's text, exactly as written.
  final String literal;

  /// Creates a finding.
  const EscapingPath(this.file, this.line, this.literal);

  /// A one-line report naming the file, the line and the literal.
  String describe() => '$file:$line  $literal';
}

/// A `'…'` or `"…"` literal that starts with at least one `../` segment.
///
/// Anchored on the leading `../` rather than on any relative path: a path that
/// never climbs cannot leave the package, so the escape is what is worth
/// scanning for and the false-positive surface stays small.
final RegExp _relativeLiteral = RegExp('''['"]((?:\\.\\./)+[^'"\\n]*)['"]''');

/// Lines that are comments or import/export directives.
///
/// Both are excluded, for different reasons. A comment naming a path is prose,
/// and prose is allowed to mention a neighbour — an early draft of this check
/// reported `../meta/…` out of a doc comment, ellipsis and all. A directive's
/// target is resolved by the compiler, so a wrong one is a build error rather
/// than a silent runtime miss; this check adds nothing there.
bool _isCommentOrDirective(String line) {
  final t = line.trimLeft();
  return t.startsWith('//') ||
      t.startsWith('*') ||
      t.startsWith('/*') ||
      t.startsWith('import ') ||
      t.startsWith('export ') ||
      t.startsWith('part ');
}

/// Directory prefixes `.pubignore` removes from the published archive.
///
/// Only the simple `dir/` form is understood, which is the only form in use.
/// A pattern this cannot read is ignored, so the directory stays *in* scope —
/// failing towards checking too much rather than too little.
Set<String> readPubignoreDirs(Directory packageRoot) {
  final f = File('${packageRoot.path}/.pubignore');
  if (!f.existsSync()) return {};
  return {
    for (final raw in f.readAsLinesSync())
      if (raw.trim().isNotEmpty && !raw.trim().startsWith('#'))
        if (raw.trim().endsWith('/')) raw.trim().replaceAll('/', ''),
  };
}

/// Every escaping path literal in [packageRoot]'s shipped script directories.
List<EscapingPath> findEscapingPaths(Directory packageRoot) {
  final out = <EscapingPath>[];
  if (!packageRoot.existsSync()) return out;
  final rootPath = packageRoot.uri.toFilePath();
  final unshipped = readPubignoreDirs(packageRoot);

  for (final dirName in shippedScriptDirs) {
    if (unshipped.contains(dirName)) continue;
    final dir = Directory('${packageRoot.path}/$dirName');
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_isCommentOrDirective(lines[i])) continue;
        for (final m in _relativeLiteral.allMatches(lines[i])) {
          final literal = m.group(1)!;
          final fileDir = File(entity.path).parent.path;
          // The two bases a Dart path literal can be resolved against.
          final candidates = [
            Uri.file('$fileDir/').resolve(literal).toFilePath(),
            Uri.file('${packageRoot.path}/').resolve(literal).toFilePath(),
          ];
          final ok = candidates.any((c) {
            final normalised = c.endsWith('/')
                ? c.substring(0, c.length - 1)
                : c;
            final within =
                normalised == rootPath.replaceAll(RegExp(r'/$'), '') ||
                normalised.startsWith(rootPath);
            return within &&
                (File(normalised).existsSync() ||
                    Directory(normalised).existsSync());
          });
          if (!ok) {
            final rel = entity.path.startsWith(rootPath)
                ? entity.path.substring(rootPath.length)
                : entity.path;
            out.add(EscapingPath(rel, i + 1, literal));
          }
        }
      }
    }
  }
  return out;
}
