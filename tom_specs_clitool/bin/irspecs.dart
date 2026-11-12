/// Writes the IR Specs intermediate representation of a CodeSpecs trio
/// (`irspecs_ir.md`): `irspecs from-codespecs --shared --client --server
/// --areas --out`.
///
/// Exit codes: `0` written, `2` bad usage. The command lives in
/// `lib/src/irspecs/irspecs_cli.dart` so the tests run it in-process.
library;

// entrypoint-options: lib/src/irspecs/irspecs_cli.dart

import 'dart:io';

import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  exit(await runIrspecs(arguments));
}
