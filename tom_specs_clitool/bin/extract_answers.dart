/// Extracts a review round's answers, comments, open questions and inline
/// marks from TomSpecs documents into a step folder's `answers.md`.
///
/// Exit codes: `0` written, `1` an unreadable document or a malformed
/// annotation, `2` bad usage. The command lives in
/// `lib/src/extract_answers_cli.dart` so the tests run it in-process.
library;

// entrypoint-options: lib/src/extract_answers_cli.dart

import 'dart:io';

import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  exit(await runExtractAnswers(arguments));
}
