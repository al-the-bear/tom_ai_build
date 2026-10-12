/// Runs the `codespecs_derivation_contract.md` §6 checks over a generated
/// CodeSpecs project trio and exits non-zero on any violation.
///
/// Exit codes: `0` clean, `1` at least one violation, `2` bad usage. `--json`
/// writes the report as one JSON document; `--backlinks` writes the trio's
/// back-link index instead of running the checks. The command lives in
/// `lib/src/codespecs/validate_codespecs_cli.dart` so the tests run it
/// in-process; it compiles with `dart compile exe` into a standalone binary.
library;

// entrypoint-options: lib/src/codespecs/validate_codespecs_cli.dart

import 'dart:io';

import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  exit(await runValidateCodespecs(arguments));
}
