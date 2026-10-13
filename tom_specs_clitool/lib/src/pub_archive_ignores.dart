/// Which checked-in files `dart pub publish` leaves out of a package archive
/// because a `.gitignore` excludes them.
///
/// git and pub do not evaluate ignore rules the same way. A repository-root
/// `**/doc/api/**` with `!**/doc/api/api_summary_*.md` re-included the
/// hand-written API summaries for git, so they were tracked, while pub still
/// dropped them, so no archive carried them and every link to one was dead on
/// pub.dev. Only pub can say what pub will ship, so this asks pub — through
/// `dart pub publish --dry-run`, which validates the archive without
/// uploading it and names every file it excludes that git tracks.
///
/// A file deliberately kept out of an archive belongs in the package's
/// `.pubignore`, which pub reports nothing about; a tracked file a
/// `.gitignore` drops is therefore always an accident.
library;

import 'dart:io';

/// The outcome of one dry run over one package.
class PubArchiveIgnores {
  /// Creates the outcome for [packageDir].
  const PubArchiveIgnores({
    required this.packageDir,
    required this.ran,
    required this.ignoredFiles,
    required this.output,
  });

  /// The package directory the dry run was made in.
  final String packageDir;

  /// Whether the dry run got as far as listing the archive. When it did not,
  /// [ignoredFiles] being empty means nothing — the question was never asked.
  final bool ran;

  /// Package-relative paths pub named as checked in yet gitignored.
  final List<String> ignoredFiles;

  /// The dry run's combined output, for a failure message.
  final String output;
}

final _warning = RegExp(r'checked-in files? (?:is|are) ignored by a');
const _listHeader = 'Files that are checked in while gitignored:';

/// Extracts the checked-in-but-gitignored paths from the [output] of
/// `dart pub publish --dry-run`.
///
/// pub prints a warning line, a header, and one indented path per line; the
/// list ends at the first line that is not an indented path.
List<String> parseCheckedInIgnored(String output) {
  final lines = output.split('\n');
  final found = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (!_warning.hasMatch(lines[i])) continue;
    var j = i + 1;
    if (j < lines.length && lines[j].trim() == _listHeader) j++;
    for (; j < lines.length; j++) {
      final line = lines[j];
      if (!line.startsWith('  ') || line.trim().isEmpty) break;
      final path = line.trim();
      if (path.startsWith('*')) break;
      found.add(path);
    }
  }
  return found;
}

/// Runs `dart pub publish --dry-run` in [packageDir] and reports which
/// checked-in files the archive would leave out.
///
/// [packageName] is the pubspec name; the run counts as made only when pub
/// announced it was publishing that package, which is printed after the
/// archive has been assembled.
Future<PubArchiveIgnores> checkPubArchiveIgnores(
  String packageDir, {
  required String packageName,
  String dartExecutable = 'dart',
}) async {
  final result = await Process.run(dartExecutable, [
    'pub',
    'publish',
    '--dry-run',
  ], workingDirectory: packageDir);
  final output = '${result.stdout}\n${result.stderr}';
  return PubArchiveIgnores(
    packageDir: packageDir,
    ran: output.contains('Publishing $packageName '),
    ignoredFiles: parseCheckedInIgnored(output),
    output: output,
  );
}
