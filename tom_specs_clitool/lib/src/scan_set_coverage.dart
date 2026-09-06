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
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'oe_citations.dart' show defaultCitingRoots;
import 'section_citations.dart'
    show
        defaultCitedDocFolders,
        defaultCitedReadmes,
        defaultCitedSourceRoots,
        listMarkdownSources,
        sectionIdPattern;

/// One file that cites the doc set but no default scan set reaches.
class ScanSetGap {
  const ScanSetGap({required this.path, required this.kind});

  /// The offending file, container-root-relative.
  final String path;

  /// Which set should have held it — `README`, `doc folder` or `source tree`.
  final String kind;

  @override
  String toString() => '$path cites the doc set but no default $kind scan set '
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

bool _citesDartDoc(File file) {
  try {
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('///') && _anyCitation.hasMatch(trimmed)) {
        return true;
      }
    }
  } on FileSystemException {
    return false;
  }
  return false;
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

    final lib = Directory(p.join(dir.path, 'lib'));
    if (lib.existsSync() && !sources.contains(rel(lib.path))) {
      final citing = lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.dart')
          .any(_citesDartDoc);
      if (citing) {
        gaps.add(ScanSetGap(path: rel(lib.path), kind: 'source tree'));
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
