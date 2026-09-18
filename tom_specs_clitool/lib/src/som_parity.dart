/// The nine-plane parity check: a capability the contract names that some
/// language runtime does not carry.
///
/// WHY THIS EXISTS. The conformance corpus proves the nine ports **agree about
/// what they share**. By construction it cannot notice a capability only one of
/// them has: a facility added to Dart alone produces no golden mismatch, no red
/// suite and no coverage finding, because there is nothing in the shared corpus
/// to disagree about. `parity_gate.sh` can prove a specific capability reached
/// all nine, but only by being run BY HAND against a deliberately mutated
/// corpus, so the evidence exists for the one capability somebody thought to
/// check and for nothing else.
///
/// WHAT IT MEASURES, and the two decisions that make it usable:
///
///   * THE VOCABULARY IS THE CONTRACT, not one plane's source. A token counts
///     as a capability when it is lowerCamelCase, appears in the shared
///     conformance corpus (the documents and tables every plane reads), and the
///     reference plane implements it. Taking the vocabulary from Dart's sources
///     alone would report every Dart-local variable name as a missing feature:
///     measured, that is 185 one-plane tokens, and a check whose first run
///     reports 185 things is a check nobody runs twice.
///   * MATCHING IS BY CONTAINMENT over normalised identifiers. Lowercasing and
///     dropping underscores folds `enumValueUnknown`, `ENUM_VALUE_UNKNOWN` and
///     `EnumValueUnknown` together; containment additionally folds C's prefixed
///     spelling (`som_doc_add_list_item` contains `addlistitem`). Without it,
///     26 of the 31 findings on the first run were C naming convention rather
///     than missing capability. Containment trades sensitivity for silence,
///     which is the right trade for a gate: a false alarm gets it switched off,
///     a miss leaves it no worse than the nothing it replaced.
///
/// WHAT IT CANNOT SEE, stated because a check that overstates its reach is
/// worse than none. A capability that never entered the corpus is invisible
/// here for the same reason it is invisible to the golden logs — nothing shared
/// mentions it. This finds capabilities the **contract** names and a plane
/// lacks, which is the case that matters when Dart leads and the ports follow.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';

/// One capability the contract names that at least one plane does not carry.
class ParityFinding {
  /// The contract token, in its corpus spelling.
  final String token;

  /// The planes whose sources do not mention it, in the canonical plane order.
  final List<String> absentFrom;

  /// Creates a finding.
  ParityFinding(this.token, this.absentFrom);

  @override
  String toString() => '$token: absent from ${absentFrom.join(", ")}';
}

/// An acknowledged asymmetry, read from the committed manifest.
class ParityException {
  /// The contract token it covers.
  final String token;

  /// Why the asymmetry is accepted, or what is known to be unported.
  final String reason;

  /// The planes the absence is accepted for; empty means every plane.
  final List<String> planes;

  /// Creates an acknowledged asymmetry.
  ParityException(this.token, this.reason, this.planes);

  /// Whether this entry covers [finding] exactly — never more.
  ///
  /// An entry that named fewer planes than the finding does must NOT silence
  /// it: the same token spreading to a tenth plane is new information, and an
  /// acknowledgement is of a measured state rather than of a name.
  bool covers(ParityFinding finding) {
    if (finding.token != token) return false;
    if (planes.isEmpty) return true;
    return finding.absentFrom.every(planes.contains);
  }
}

/// The nine language planes, in the order every SOM tool lists them.
const somPlanes = <String>[
  'dart',
  'python',
  'javascript',
  'typescript',
  'java',
  'go',
  'rust',
  'c',
  'cpp',
];

/// The plane whose implementation defines what a capability IS.
///
/// Dart leads and the ports follow — that is the observed workflow, and naming
/// it here is what lets the vocabulary be filtered to things somebody actually
/// implemented rather than to every word in the corpus.
const somReferencePlane = 'dart';

const _sourceExtensions = <String, List<String>>{
  'dart': ['.dart'],
  'python': ['.py'],
  'javascript': ['.js'],
  'typescript': ['.ts'],
  'java': ['.java'],
  'go': ['.go'],
  'rust': ['.rs'],
  'c': ['.c', '.h'],
  'cpp': ['.cpp', '.hpp'],
};

/// Directories that are not a plane's implementation.
///
/// `test` is excluded for a reason worth keeping: a port's tests routinely
/// mention a capability they do not implement (they assert it is absent, or
/// they carry a fixture naming it), so counting them would report a plane as
/// carrying what it does not.
const _skipDirectories = <String>{
  'test',
  'tests',
  'node_modules',
  '.dart_tool',
  'target',
  'build',
  'example',
  'examples',
  'doc',
  'golden',
  'generated-doc',
};

final _wordPattern = RegExp(r'[A-Za-z][A-Za-z0-9_]{2,60}');
final _camelPattern = RegExp(r'^[a-z]+(?:[A-Z][a-z0-9]*)+$');

/// `enumValueUnknown`, `ENUM_VALUE_UNKNOWN` and `EnumValueUnknown` all fold here.
String normaliseToken(String token) => token.toLowerCase().replaceAll('_', '');

/// Every normalised identifier in a plane's implementation sources.
Set<String> planeTokens(String packageDirectory, String plane) {
  final extensions = _sourceExtensions[plane];
  final tokens = <String>{};
  if (extensions == null) return tokens;
  final directory = Directory(packageDirectory);
  if (!directory.existsSync()) return tokens;

  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final relative = entity.path.substring(packageDirectory.length);
    final segments = relative.split(Platform.pathSeparator);
    if (segments.any(_skipDirectories.contains)) continue;
    final name = segments.last;
    // A shipped fixture names things it does not implement — `alphaDetail` and
    // `betaDetail` are display fixtures in the Dart runtime's own lib/, and
    // counting them put two invented capabilities into the vocabulary.
    if (name.contains('fixture')) continue;
    if (!extensions.any(name.endsWith)) continue;
    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    for (final match in _wordPattern.allMatches(content)) {
      tokens.add(normaliseToken(match.group(0)!));
    }
  }
  return tokens;
}

/// The contract vocabulary: lowerCamelCase tokens the shared corpus names.
Set<String> contractVocabulary(String conformanceDirectory) {
  final tokens = <String>{};
  final directory = Directory(conformanceDirectory);
  if (!directory.existsSync()) return tokens;

  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final relative = entity.path.substring(conformanceDirectory.length);
    final segments = relative.split(Platform.pathSeparator);
    if (segments.contains('golden')) continue;
    final name = segments.last;
    if (!(name.endsWith('.yaml') ||
        name.endsWith('.md') ||
        name.endsWith('.json'))) {
      continue;
    }
    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    for (final match in _wordPattern.allMatches(content)) {
      final token = match.group(0)!;
      if (_camelPattern.hasMatch(token)) tokens.add(token);
    }
  }
  return tokens;
}

/// Whether [plane]'s sources carry [token], by normalised containment.
bool planeCarries(Set<String> tokens, String joined, String token) {
  final needle = normaliseToken(token);
  return tokens.contains(needle) || joined.contains(needle);
}

/// The capabilities the contract names that some plane does not carry.
///
/// [planeTokenSets] is keyed by plane name. The vocabulary is filtered to what
/// the reference plane implements, so a word that is merely written in a sample
/// document is not mistaken for a capability nobody ported.
List<ParityFinding> checkParity(
  Set<String> vocabulary,
  Map<String, Set<String>> planeTokenSets,
) {
  final joined = <String, String>{
    for (final entry in planeTokenSets.entries)
      entry.key: (entry.value.toList()..sort()).join(' '),
  };
  final reference = planeTokenSets[somReferencePlane] ?? const <String>{};

  final findings = <ParityFinding>[];
  for (final token in vocabulary.toList()..sort()) {
    if (!reference.contains(normaliseToken(token))) continue;
    final absent = <String>[];
    for (final plane in somPlanes) {
      final tokens = planeTokenSets[plane];
      if (tokens == null) continue;
      if (!planeCarries(tokens, joined[plane] ?? '', token)) absent.add(plane);
    }
    if (absent.isNotEmpty) findings.add(ParityFinding(token, absent));
  }
  return findings;
}

/// The findings no committed exception accounts for.
List<ParityFinding> unacknowledged(
  List<ParityFinding> findings,
  List<ParityException> exceptions,
) => findings
    .where((f) => !exceptions.any((e) => e.covers(f)))
    .toList(growable: false);

/// The exceptions that no longer match anything — a fixed gap nobody deleted.
///
/// Reported rather than ignored, for the reason every ratchet in this package
/// states: an acknowledgement that has outlived its defect is a claim about the
/// code that has quietly stopped being true.
List<ParityException> staleExceptions(
  List<ParityFinding> findings,
  List<ParityException> exceptions,
) => exceptions
    .where((e) => !findings.any((f) => f.token == e.token))
    .toList(growable: false);

/// The acknowledged asymmetries, read from the committed manifest.
///
/// Lives here rather than in the entry point so the gate and its test read the
/// manifest through one implementation: two readers of the same file is two
/// notions of what an acknowledgement covers, and the narrower one would be
/// silently wrong.
List<ParityException> readParityExceptions(String path) {
  final file = File(path);
  if (!file.existsSync()) return const [];
  final parsed = loadYaml(file.readAsStringSync());
  if (parsed is! Map) return const [];
  final entries = parsed['exceptions'];
  if (entries is! List) return const [];
  return [
    for (final entry in entries)
      if (entry is Map)
        ParityException(
          entry['token'].toString(),
          (entry['reason'] ?? '').toString(),
          [
            for (final p in (entry['planes'] as List? ?? const []))
              p.toString(),
          ],
        ),
  ];
}
