/// Derives the registry part of an application's test suite from its
/// specification — operations by role, error code and control; screens by
/// role — and cross-checks the registries (`tom_specs_project_flow.md`,
/// Phase 5). The command lives in
/// `lib/src/registry_tests/registry_tests_cli.dart`.
library;

// entrypoint-options: lib/src/registry_tests/registry_tests_cli.dart

import 'dart:io';

import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  exit(await runGenerateRegistryTests(arguments));
}
