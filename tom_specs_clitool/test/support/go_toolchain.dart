/// Where the tests find the Go toolchain.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The `go` binary: the PATH first, then where Homebrew and the official
/// tarball (`/usr/local/go`, `~/.local/go`, som_toolchains.md) put it — the
/// same directories `tom_som_conformance/tool/run_all_suites.sh` adds, since a
/// non-interactive shell carries none of them. `null` when there is none,
/// which the tests report as a skip with that reason.
String? findGoToolchain() {
  final home = Platform.environment['HOME'] ?? '';
  final candidates = [
    for (final dir in (Platform.environment['PATH'] ?? '').split(':'))
      if (dir.isNotEmpty) p.join(dir, 'go'),
    '/opt/homebrew/bin/go',
    '/usr/local/go/bin/go',
    if (home.isNotEmpty) p.join(home, '.local', 'go', 'bin', 'go'),
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  return null;
}
