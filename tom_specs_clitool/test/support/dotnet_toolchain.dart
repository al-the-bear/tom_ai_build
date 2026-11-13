/// Where the tests find a .NET 8 SDK.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// A `dotnet` that carries an 8.x SDK: the PATH first, then `DOTNET_ROOT`,
/// the per-user install `dotnet-install.sh` writes (`~/.dotnet`,
/// som_toolchains.md) and the system installs. `null` when there is none.
String? findDotnet8() {
  final home = Platform.environment['HOME'] ?? '';
  final candidates = [
    for (final dir in (Platform.environment['PATH'] ?? '').split(':'))
      if (dir.isNotEmpty) p.join(dir, 'dotnet'),
    if (Platform.environment['DOTNET_ROOT'] case final root?)
      p.join(root, 'dotnet'),
    if (home.isNotEmpty) p.join(home, '.dotnet', 'dotnet'),
    '/usr/local/share/dotnet/dotnet',
    '/usr/share/dotnet/dotnet',
    '/usr/lib/dotnet/dotnet',
  ];
  for (final c in candidates) {
    if (!File(c).existsSync()) continue;
    final r = Process.runSync(c, ['--list-sdks']);
    if (r.exitCode == 0 &&
        RegExp(r'^8\.', multiLine: true).hasMatch('${r.stdout}')) {
      return c;
    }
  }
  return null;
}

/// The environment a test runs [dotnet] in: its root, and no telemetry or
/// first-run banner.
Map<String, String> dotnetEnvironment(String dotnet) => {
  'DOTNET_ROOT': p.dirname(dotnet),
  'DOTNET_CLI_TELEMETRY_OPTOUT': '1',
  'DOTNET_NOLOGO': '1',
  'DOTNET_SKIP_FIRST_TIME_EXPERIENCE': '1',
};
