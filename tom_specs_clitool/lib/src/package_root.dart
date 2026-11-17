/// Where this package's files are, for the tools that read its committed
/// files (manifests, the sibling packages of `tom_ai/ai_build`).
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// The root folder of `tom_specs_clitool`: resolved through the package
/// config (`package:tom_specs_clitool/` is its `lib/`), so it is right under
/// `dart run`, `dart test` and the `tomspecs` binary run with a package
/// config. A compiled binary has none; there it is the folder above the
/// script's folder (`bin/..`), as the tools have always taken it.
String clitoolPackageRoot() {
  final lib = Isolate.resolvePackageUriSync(
    Uri.parse('package:tom_specs_clitool/'),
  );
  if (lib != null && lib.scheme == 'file') {
    return p.normalize(p.dirname(p.fromUri(lib)));
  }
  return p.normalize(p.dirname(p.dirname(p.fromUri(Platform.script))));
}
