/// The gate over the gates: is every TomSpecs file that cites the doc set
/// actually inside a default scan set?
///
/// The three citation gates hold whatever their default scan sets name, and
/// those sets are **closed and enumerated** on purpose — a workspace-wide sweep
/// would pull in projects whose unrelated `§` usage would need exempting one by
/// one. The cost of a closed set is the failure this library exists to prevent:
/// a package documented today and added to the list tomorrow is ungated in
/// between, and nothing says so. The tsdoc series made that concrete — eighteen
/// SOM packages and twenty-five `doc/` folders were written while the sets
/// still named nine READMEs, and the thirty-one violations that surfaced the
/// moment they were listed had been accumulating unseen.
///
/// So this checks the *membership rule* rather than the citations: **a file
/// that cites the doc set must be reachable from a default scan set.** It is
/// deliberately not a check that every package is listed — a package with no
/// citations needs no gate, and listing it would only add files to scan. The
/// rule is *citing*, not *kind*, the same rule
/// [defaultCitedSourceRoots] already states for source trees.
///
/// **The walk covers every source directory a package writes, not only
/// `lib/`.** It used to walk three kinds — `README.md`, `doc/**.md` and
/// `lib/**.dart` — while stating the rule above, and the gap between the two
/// was the more serious half of the defect: a citing `tool/` script is
/// precisely the case the stated rule covers and the implementation did not, so
/// a reader of this comment had no way to learn the hole existed. A hundred and
/// forty-four files were ungated, and listing them surfaced thirty-three
/// dangling citations. [_sourceDirs] now names the directories, and a
/// package that grows a new one is caught by the same argument that motivated
/// this library: the cost of a closed set is that it fixes today and not
/// tomorrow.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'oe_citations.dart' show defaultCitingRoots;
import 'section_citations.dart'
    show
        defaultCitedDocFolders,
        defaultCitedReadmes,
        defaultCitedSourceRoots,
        liftComments,
        listMarkdownSources,
        listScannedSources,
        sectionIdPattern;

/// One file that cites the doc set but no default scan set reaches.
class ScanSetGap {
  /// Records one citing file that no scan set reaches.
  ///
  /// [kind] is required alongside [path] because the repair differs by kind:
  /// the three sets are separate lists, and the gap is only actionable once a
  /// reader knows which one to add the file to.
  const ScanSetGap({required this.path, required this.kind});

  /// The offending file, container-root-relative.
  final String path;

  /// Which set should have held it — `README`, `doc folder` or `source tree`.
  final String kind;

  @override
  String toString() =>
      '$path cites the doc set but no default $kind scan set '
      'reaches it — add it to the matching list in tom_specs_clitool/lib/src/, '
      'or the gates will never see it';
}

/// A `§N` citation anywhere in a file's text.
///
/// Deliberately coarser than the gate's own classifier: this asks only "does
/// this file cite at all", which decides whether it belongs in a scan set. What
/// each citation resolves to is the gate's question, not this one.
final RegExp _anyCitation = RegExp('§\\s?$sectionIdPattern');

bool _cites(File file) {
  try {
    return _anyCitation.hasMatch(file.readAsStringSync());
  } on FileSystemException {
    return false;
  }
}

/// The per-package source directories the walk inspects.
///
/// Enumerated rather than "every directory that is not `doc`", because a
/// package root also holds `build/`, `.dart_tool/` and language-specific output
/// trees whose citations are copies of ones already scanned where they were
/// written. These five are where a person writes source.
const _sourceDirs = ['lib', 'bin', 'test', 'tool', 'example'];

/// Whether [file] cites the doc set from a **comment**.
///
/// Comments only, because that is what the gate reads: a `§` in a string
/// literal or in code is not a citation a reader follows, and reporting the
/// file as an unheld scan-set member would send someone to add a root that then
/// finds nothing. Uses the same per-kind lift the gate uses, so the two cannot
/// disagree about what counts as a comment.
bool _citesInComments(File file) {
  try {
    return _anyCitation.hasMatch(
      liftComments(file.path, file.readAsStringSync()),
    );
  } on FileSystemException {
    return false;
  }
}

/// Every citing file under [containerRoot] that no default scan set reaches.
///
/// [packageRoots] are the TomSpecs package directories to inspect,
/// container-root-relative. Empty means the whole set is covered.
List<ScanSetGap> findScanSetGaps({
  required String containerRoot,
  required Iterable<String> packageRoots,
  String docDir = 'tom_ai/ai_build/tom_specs_model/doc',
}) {
  final gaps = <ScanSetGap>[];
  final readmes = defaultCitedReadmes.toSet();
  final sources = defaultCitedSourceRoots.toSet();
  // The doc folder itself is the gate's corpus, and the OE gate carries its own
  // citing roots — both count as coverage.
  final docRoots = <String>{
    docDir,
    ...defaultCitedDocFolders,
    ...defaultCitingRoots.where((r) => !r.endsWith('.md')),
  };

  String rel(String abs) =>
      p.relative(abs, from: containerRoot).replaceAll(r'\', '/');

  for (final packageRoot in packageRoots) {
    final dir = Directory(p.join(containerRoot, packageRoot));
    if (!dir.existsSync()) continue;

    final readme = File(p.join(dir.path, 'README.md'));
    if (readme.existsSync() &&
        _cites(readme) &&
        !readmes.contains(rel(readme.path))) {
      gaps.add(ScanSetGap(path: rel(readme.path), kind: 'README'));
    }

    final doc = Directory(p.join(dir.path, 'doc'));
    if (doc.existsSync()) {
      for (final path in listMarkdownSources(doc.path)) {
        if (!_cites(File(path))) continue;
        final relative = rel(path);
        final held = docRoots.any((root) => relative.startsWith('$root/'));
        if (!held) {
          gaps.add(ScanSetGap(path: relative, kind: 'doc folder'));
          break; // One gap per folder is the actionable unit.
        }
      }
    }

    for (final name in _sourceDirs) {
      final source = Directory(p.join(dir.path, name));
      if (!source.existsSync() || sources.contains(rel(source.path))) continue;
      final citing = listScannedSources(
        source.path,
      ).map(File.new).any(_citesInComments);
      if (citing) {
        gaps.add(ScanSetGap(path: rel(source.path), kind: 'source tree'));
      }
    }
  }
  return gaps;
}

/// The TomSpecs package directories the coverage check inspects.
///
/// Enumerated for the same reason the scan sets are: this is the set of
/// packages the quest owns, and a workspace-wide walk would report every
/// unrelated project that happens to write a `§`.
const tomSpecsPackageRoots = [
  'tom_ai/ai_build/tom_code_specs',
  'tom_ai/ai_build/tom_doc_scanner',
  'tom_ai/ai_build/tom_doc_specs',
  'tom_ai/ai_build/tom_spec_engine',
  'tom_ai/ai_build/tom_som_conformance',
  'tom_ai/ai_build/tom_specs_samples',
  'tom_ai/ai_build/tom_specs_clitool',
  'tom_ai/ai_build/tom_specs_core',
  'tom_ai/ai_build/tom_specs_model',
  'tom_ai/ai_build/tom_specs_reviewer',
  'tom_ai/core/tom_core_codespecs',
  'tom_forge/tom_specs_editor',
  'tom_ai/ai_build/tom_som_c_runtime',
  'tom_ai/ai_build/tom_som_c_v0',
  'tom_ai/ai_build/tom_som_cpp_runtime',
  'tom_ai/ai_build/tom_som_cpp_v0',
  'tom_ai/ai_build/tom_som_dart_runtime',
  'tom_ai/ai_build/tom_som_dart_v0',
  'tom_ai/ai_build/tom_som_go_runtime',
  'tom_ai/ai_build/tom_som_go_v0',
  'tom_ai/ai_build/tom_som_java_runtime',
  'tom_ai/ai_build/tom_som_java_v0',
  'tom_ai/ai_build/tom_som_javascript_runtime',
  'tom_ai/ai_build/tom_som_javascript_v0',
  'tom_ai/ai_build/tom_som_python_runtime',
  'tom_ai/ai_build/tom_som_python_v0',
  'tom_ai/ai_build/tom_som_rust_runtime',
  'tom_ai/ai_build/tom_som_rust_v0',
  'tom_ai/ai_build/tom_som_typescript_runtime',
  'tom_ai/ai_build/tom_som_typescript_v0',
];
