// The TomSpecs process checks on any project's specification document:
// `dart run tom_specs_clitool:spec_checks <check> ...`. See
// lib/src/spec_checks_cli.dart for the checks and where their data comes from.
//
// entrypoint-options: lib/src/spec_checks_cli.dart
import 'dart:io';

import 'package:tom_specs_clitool/src/spec_checks_cli.dart';

Future<void> main(List<String> arguments) async {
  final code = runSpecChecks(arguments);
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
