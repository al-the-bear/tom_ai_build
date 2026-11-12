/// The forty-one CodeSpecs checks on the IR: every fixture of
/// `codespecs_validator_test.dart`, written as IR documents, read back and
/// checked (`irspecs_ir.md` §7) — each check fires on its red fixture and
/// passes its green one exactly as it does on the Dart.
library;

import 'codespecs_validator_test.dart' as fixtures;

void main() => fixtures.defineCodeSpecsFixtures(throughIr: true);
