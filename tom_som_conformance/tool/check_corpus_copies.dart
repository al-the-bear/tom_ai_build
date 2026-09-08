// Checks that every committed COPY of a corpus file still matches the original.
//
// WHY A COPY EXISTS AT ALL. `dart pub publish` ships `test/`, so a shipped test
// that reads a sibling workspace project names files a consumer does not have
// `tom_som_dart_runtime` is published, and two of its tests read
// this corpus, so those two fixtures were copied into the package — 15 KB, and
// the test is then runnable from a hosted install.
//
// WHY THE CHECK LIVES HERE AND NOT THERE. The comparison has to read the
// original, which means reaching across the workspace — exactly what the copy
// exists to avoid. This package is source-only (never published), so it is
// allowed to. Put the other way round: the owner of a file is the right place
// to ask whether its copies still agree with it.
//
// Run:  dart tool/check_corpus_copies.dart [conformance-root]
// Exit: 0 when every copy matches, 1 on drift, 2 when a copy is missing.
import 'dart:io';

/// Copies to hold, as (package-relative destination, corpus-relative source).
///
/// A list rather than a scan: a copy is a deliberate act, so its registration
/// here is the record that it was deliberate. A scan would also silently stop
/// checking a file that got renamed.
const List<(String, String)> _copies = [
  (
    '../tom_som_dart_runtime/test/fixtures/corpus/model.meta.json',
    'model.meta.json',
  ),
  ('../tom_som_dart_runtime/test/fixtures/corpus/expected.md', 'expected.md'),
];

void main(List<String> args) {
  exit(_run(args));
}

/// The check itself, returning the exit code so `main` can hand it to [exit].
///
/// `int main` is IGNORED by the Dart VM — a non-zero return leaves the process
/// exiting 0, which is a gate that cannot fail. The split keeps the code path
/// testable and the exit explicit.
int _run(List<String> args) {
  final confRoot = args.isEmpty ? '.' : args.first;
  final corpus = Directory('$confRoot/corpus');
  if (!corpus.existsSync()) {
    stderr.writeln('check_corpus_copies: no corpus at ${corpus.path}');
    return 2;
  }

  var drifted = 0, missing = 0;
  for (final (dest, source) in _copies) {
    final copy = File('$confRoot/$dest');
    final original = File('${corpus.path}/$source');
    if (!original.existsSync()) {
      stderr.writeln('check_corpus_copies: corpus file gone: $source');
      missing++;
      continue;
    }
    if (!copy.existsSync()) {
      stderr.writeln('check_corpus_copies: copy gone: $dest');
      missing++;
      continue;
    }
    if (copy.readAsStringSync() != original.readAsStringSync()) {
      stderr.writeln('check_corpus_copies: DRIFTED: $dest');
      stderr.writeln(
        '  re-copy from corpus/$source, and check what changed '
        'in the corpus while you are there',
      );
      drifted++;
    }
  }

  if (drifted > 0 || missing > 0) {
    stderr.writeln(
      'check_corpus_copies: ${_copies.length} copy(ies) checked, '
      '$drifted drifted, $missing missing',
    );
    return missing > 0 ? 2 : 1;
  }
  stdout.writeln(
    'check_corpus_copies: ${_copies.length} copy(ies) match the corpus',
  );
  return 0;
}
