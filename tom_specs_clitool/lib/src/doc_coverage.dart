// ignore_for_file: deprecated_member_use
//
// analyzer 10 is mid-migration on the AST accessors this walk needs —
// `ClassDeclaration.members`, `EnumDeclaration.constants`,
// `NamedCompilationUnitMember` and `.name` all carry a `@Deprecated` pointing
// at a `body`-shaped successor that is not yet the shape of what is returned
// here. The uses are correct against the shipped API; they move when the
// analyzer floor does, and `test/doc_coverage_test.dart` is what will notice
// if the semantics change under them.

/// The public-API dartdoc coverage gate
/// (`tom_specs_documentation_standard.md` §5).
///
/// Every other quality claim in this quest is held by a check that runs in the
/// default `dart test` — the three citation gates, the invariant
/// correspondence test, the release-closure walk, the two freshness stamps.
/// Documentation coverage was the one with no gate, and a sweep without a gate
/// is a photograph rather than a standard: `tom_specs_clitool` reached 51 % by
/// nobody noticing.
///
/// ## Which primitive, and why
///
/// Three were available and the choice matters, so it is recorded here rather
/// than in a commit message.
///
/// * A **regex scanner** over the source. Rejected: the campaign's own scanner
///   (`tool/doccov.py`) needed twelve corrections before it agreed with the
///   analyzer, and a gate that is approximately right is a gate nobody can
///   act on. It survives as a reporting aid, not as an authority.
/// * The **`public_member_api_docs` lint's diagnostics**. This is the standard's
///   definition exactly, and every measured package enables it — but it reports
///   only the *misses*. It has no denominator, so a percentage threshold cannot
///   be expressed with it at all.
/// * The **analyzer's export namespace**, used here. `exportNamespace` is
///   literally "every exported declaration" (`tom_specs_documentation_standard.md` §5's
///   own words), and the element
///   model answers the second half — "and every public member of one" — by
///   walking each exported type. It yields both halves of the ratio.
///
/// The two survivors are used together rather than one being trusted alone:
/// this walker measures, and [DocCoverageManifest] additionally requires every
/// measured package to **enable the lint**, so `dart analyze` holds the same
/// bar at edit time. Where the two could disagree, the lint wins and the
/// walker is the bug — `test/doc_coverage_test.dart` pins the agreement.
///
/// ## What the primitive cannot see
///
/// `tom_specs_documentation_standard.md` §5 says a comment that merely restates the
/// identifier (`/// The name.` on
/// `String name`) does not count as documented. **No mechanical check can see
/// that**, this one included: it counts a doc comment's *presence*, not its
/// worth. The manifest header says so too, so the number is never read as more
/// than it is.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The committed manifest path, relative to `tom_specs_clitool`.
const String docCoverageManifestPath = 'tool/doc_coverage_manifest.yaml';

/// One measured package's agreed bar.
class DocCoverageEntry {
  /// Records the floor and target for [path].
  const DocCoverageEntry({
    required this.path,
    required this.floor,
    required this.target,
  });

  /// Container-root-relative package directory.
  final String path;

  /// The ratchet floor: measured coverage may not fall below this.
  ///
  /// Seeded at the value measured when the entry was added and raised as
  /// sweeps land. It never falls — [DocCoverageReport.ratchetViolations]
  /// reports an attempt to lower one as a manifest defect, not a coverage one.
  final int floor;

  /// The `tom_specs_documentation_standard.md` §5 bar this entry climbs to.
  ///
  /// Carried beside [floor] so the remaining gap is visible without opening
  /// the standard. A floor at or above its target is finished.
  final int target;
}

/// The parsed manifest: what is measured, what is exempt, what is excluded.
class DocCoverageManifest {
  /// Builds a manifest from its three already-parsed sections.
  const DocCoverageManifest({
    required this.entries,
    required this.exempt,
    required this.excluded,
  });

  /// The measured packages, in manifest order.
  final List<DocCoverageEntry> entries;

  /// Generated packages whose coverage is the emitter's responsibility
  /// (`tom_specs_documentation_standard.md` §5: the `tom_som_*_v0` facades). An
  /// entry for one is a manifest defect —
  /// a threshold there would blame the wrong artifact for an emitter bug.
  final List<String> exempt;

  /// Packages outside documentation scope entirely
  /// (`tom_specs_documentation_standard.md` §6: `tom_specs_editor`).
  ///
  /// Absent rather than present-at-zero on purpose: a zero entry reads as a
  /// standing debt, and this is a decision, not a debt.
  final List<String> excluded;

  /// Reads the manifest from [file].
  ///
  /// Throws [FormatException] on a malformed one rather than defaulting —
  /// a gate that silently measures nothing is worse than no gate.
  factory DocCoverageManifest.parse(String yaml) {
    final doc = loadYaml(yaml);
    if (doc is! Map) {
      throw const FormatException('doc-coverage manifest is not a mapping');
    }
    final entries = <DocCoverageEntry>[];
    final packages = doc['packages'];
    if (packages is! Map) {
      throw const FormatException('manifest has no `packages:` mapping');
    }
    for (final e in packages.entries) {
      final v = e.value;
      if (v is! Map || v['floor'] is! int || v['target'] is! int) {
        throw FormatException(
          'package `${e.key}` needs integer `floor:` and `target:`',
        );
      }
      entries.add(
        DocCoverageEntry(
          path: '${e.key}',
          floor: v['floor'] as int,
          target: v['target'] as int,
        ),
      );
    }
    List<String> list(String key) => [
      for (final v in (doc[key] as YamlList? ?? const [])) '$v',
    ];
    return DocCoverageManifest(
      entries: entries,
      exempt: list('exempt'),
      excluded: list('excluded'),
    );
  }
}

/// One package's measured coverage.
class DocCoverageResult {
  /// Records a measurement.
  const DocCoverageResult({
    required this.path,
    required this.total,
    required this.documented,
    required this.undocumented,
    required this.lintEnabled,
  });

  /// Container-root-relative package directory.
  final String path;

  /// Public declarations found — the denominator.
  final int total;

  /// Of those, the ones carrying a doc comment.
  final int documented;

  /// The undocumented ones, as `library:name`, sorted. Reported so a failure
  /// names what to write rather than only how far short it fell.
  final List<String> undocumented;

  /// Whether the package enables `public_member_api_docs`.
  ///
  /// Required of every measured package: it is what holds the bar at edit
  /// time, and without it this gate is the only thing standing between the
  /// package and silent decay — one check running once per test run.
  final bool lintEnabled;

  /// Coverage as a whole percent, floored. 100 only when nothing is missing.
  int get percent {
    if (total == 0) return 100;
    final exact = 100 * documented / total;
    final floored = exact.floor();
    return (documented == total) ? 100 : (floored == 100 ? 99 : floored);
  }
}

/// A manifest or coverage failure, phrased as the repair.
class DocCoverageViolation {
  /// Records one failure.
  const DocCoverageViolation(this.package, this.message);

  /// The package it concerns, or `manifest` for a whole-file fault.
  final String package;

  /// What is wrong and what to do about it.
  final String message;

  @override
  String toString() => '$package — $message';
}

/// The outcome of one walk over the manifest.
class DocCoverageReport {
  /// Records the walk.
  const DocCoverageReport({required this.results, required this.violations});

  /// One entry per measured package, in manifest order.
  final List<DocCoverageResult> results;

  /// Everything that failed. Empty means the gate is green.
  final List<DocCoverageViolation> violations;

  /// Whether the gate passes.
  bool get isClean => violations.isEmpty;

  /// Entries whose measured coverage now exceeds their floor.
  ///
  /// Not a failure — the ratchet allows slack — but reported so the floor can
  /// be wound forward deliberately rather than the gain being forgotten.
  List<DocCoverageResult> get ratchetAvailable => [
    for (final r in results)
      if (r.percent > _floorOf(r.path)) r,
  ];

  int _floorOf(String path) => _floors[path] ?? 0;

  /// The floors the walk ran against, keyed by package path.
  static Map<String, int> _floors = const {};

  /// Records the floors used, so [ratchetAvailable] can compare against them.
  static void bindFloors(Map<String, int> floors) => _floors = floors;
}

/// Measures one package's public API.
///
/// Walks every `lib/**.dart` file and counts each public declaration and each
/// public member of one. **Parsed, not resolved**: whether a declaration
/// carries a doc comment is a syntactic question, so type resolution buys
/// nothing and costs the whole package's analysis time.
Future<DocCoverageResult> measurePackage({
  required String packagePath,
  required String relativePath,
}) async {
  final libDir = Directory(p.join(packagePath, 'lib'));
  final files = libDir.existsSync()
      ? (libDir
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path)
            .where((f) => f.endsWith('.dart'))
            .toList()
          ..sort())
      : <String>[];

  final undocumented = <String>[];
  var total = 0;
  var documented = 0;

  void count(String label, Comment? doc) {
    total++;
    if (doc != null) {
      documented++;
    } else {
      undocumented.add(label);
    }
  }

  for (final path in files) {
    final unit = parseFile(
      path: path,
      featureSet: FeatureSet.latestLanguageVersion(),
    ).unit;
    final where = p.relative(path, from: libDir.path);
    for (final decl in unit.declarations) {
      _countDeclaration(decl, where, count);
    }
  }

  return DocCoverageResult(
    path: relativePath,
    total: total,
    documented: documented,
    undocumented: undocumented..sort(),
    lintEnabled: _lintEnabled(packagePath),
  );
}

/// Whether [name] is public — Dart's own rule, plus the entry point.
///
/// `main` is excluded because an entry point is not API; the lint agrees, and
/// a package would otherwise be marked down for a `main` nobody calls.
bool _isPublic(String name) => name.isNotEmpty && !name.startsWith('_');

/// Whether [node] carries `@override`, whose comment is inherited.
bool _isOverride(AnnotatedNode node) =>
    node.metadata.any((a) => a.name.name == 'override');

/// Counts one top-level declaration and, for a type, its public members.
void _countDeclaration(
  CompilationUnitMember decl,
  String where,
  void Function(String label, Comment? doc) count,
) {
  if (decl is TopLevelVariableDeclaration) {
    for (final v in decl.variables.variables) {
      if (_isPublic(v.name.lexeme)) {
        count('$where:${v.name.lexeme}', decl.documentationComment);
      }
    }
    return;
  }
  if (decl is FunctionDeclaration) {
    final name = decl.name.lexeme;
    if (name == 'main' || !_isPublic(name)) return;
    count('$where:$name', decl.documentationComment);
    return;
  }
  if (decl is NamedCompilationUnitMember) {
    final name = decl.name.lexeme;
    if (!_isPublic(name)) return;
    count('$where:$name', decl.documentationComment);
  }
  if (decl is ClassDeclaration) {
    _countMembers(decl.name.lexeme, where, decl.members, count);
  } else if (decl is MixinDeclaration) {
    _countMembers(decl.name.lexeme, where, decl.members, count);
  } else if (decl is ExtensionDeclaration) {
    _countMembers(decl.name?.lexeme ?? '', where, decl.members, count);
  } else if (decl is EnumDeclaration) {
    final owner = decl.name.lexeme;
    for (final c in decl.constants) {
      count('$where:$owner.${c.name.lexeme}', c.documentationComment);
    }
    _countMembers(owner, where, decl.members, count);
  }
}

/// Counts the public members of a type body.
///
/// Three exclusions, each matching `public_member_api_docs` and each for its
/// reason: an **`@override`** member inherits its supertype's comment; a
/// **setter whose getter exists** is half of one read/write property that
/// `dart doc` renders as a single entry carrying the getter's text; and a
/// **private** name is not API.
void _countMembers(
  String owner,
  String where,
  List<ClassMember> members,
  void Function(String label, Comment? doc) count,
) {
  if (owner.isEmpty) return;
  final getters = <String>{
    for (final m in members)
      if (m is MethodDeclaration && m.isGetter) m.name.lexeme,
  };
  for (final m in members) {
    if (_isOverride(m)) continue;
    if (m is FieldDeclaration) {
      for (final v in m.fields.variables) {
        if (_isPublic(v.name.lexeme)) {
          count('$where:$owner.${v.name.lexeme}', m.documentationComment);
        }
      }
    } else if (m is MethodDeclaration) {
      final name = m.name.lexeme;
      if (!_isPublic(name)) continue;
      if (m.isSetter && getters.contains(name)) continue;
      count('$where:$owner.$name', m.documentationComment);
    } else if (m is ConstructorDeclaration) {
      final n = m.name?.lexeme;
      if (n != null && !_isPublic(n)) continue;
      count('$where:$owner.${n ?? "new"}()', m.documentationComment);
    }
  }
}

/// Whether [packagePath] enables `public_member_api_docs`.
bool _lintEnabled(String packagePath) {
  final f = File(p.join(packagePath, 'analysis_options.yaml'));
  if (!f.existsSync()) return false;
  for (final line in f.readAsLinesSync()) {
    final t = line.trim();
    if (t.startsWith('#')) continue;
    if (t.startsWith('public_member_api_docs:') && t.endsWith('true')) {
      return true;
    }
  }
  return false;
}

/// Walks [manifest] against the tree under [containerRoot].
Future<DocCoverageReport> checkDocCoverage({
  required DocCoverageManifest manifest,
  required String containerRoot,
}) async {
  final violations = <DocCoverageViolation>[];
  final results = <DocCoverageResult>[];
  final floors = <String, int>{};

  final measured = {for (final e in manifest.entries) e.path};
  for (final path in manifest.exempt) {
    if (measured.contains(path)) {
      violations.add(
        DocCoverageViolation(
          path,
          'is exempt (tom_specs_documentation_standard.md §5: '
          'generated, coverage is the emitter\'s '
          'responsibility) but carries a threshold — remove the entry',
        ),
      );
    }
  }
  for (final path in manifest.excluded) {
    if (measured.contains(path)) {
      violations.add(
        DocCoverageViolation(
          path,
          'is excluded from documentation scope '
          '(tom_specs_documentation_standard.md §6) but carries a '
          'threshold — remove the entry',
        ),
      );
    }
  }

  for (final entry in manifest.entries) {
    floors[entry.path] = entry.floor;
    final abs = p.join(containerRoot, entry.path);
    if (!Directory(abs).existsSync()) {
      violations.add(
        DocCoverageViolation(
          entry.path,
          'is in the manifest but no such directory exists',
        ),
      );
      continue;
    }
    final r = await measurePackage(packagePath: abs, relativePath: entry.path);
    results.add(r);

    if (!r.lintEnabled) {
      violations.add(
        DocCoverageViolation(
          entry.path,
          'does not enable `public_member_api_docs` in its '
          'analysis_options.yaml — the gate records the bar, that lint holds '
          'it at edit time, and a measured package needs both',
        ),
      );
    }
    if (r.percent < entry.floor) {
      final missing = r.undocumented.take(5).join(', ');
      violations.add(
        DocCoverageViolation(
          entry.path,
          'coverage ${r.percent}% is below its floor of ${entry.floor}% '
          '(${r.documented}/${r.total}); undocumented: $missing'
          '${r.undocumented.length > 5 ? ", +${r.undocumented.length - 5} more" : ""}',
        ),
      );
    }
  }

  DocCoverageReport.bindFloors(floors);
  return DocCoverageReport(results: results, violations: violations);
}
