/// Validates one project's TomSpecs document on all three tiers — decode, the
/// DocSpecs schema over its rendition, and the instance tier.
///
/// Exit codes: `0` clean, `1` at least one finding, `2` bad usage. The command
/// lives in `lib/src/validate_spec_cli.dart` so the tests run it in-process.
library;

// entrypoint-options: lib/src/validate_spec_cli.dart

import 'dart:io';

import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  exit(await runValidateSpec(arguments));
}
