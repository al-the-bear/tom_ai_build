/// Where the tests find a JDK 21 and Gradle.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The home of a JDK 21: `JAVA_HOME` when it is one, else where Homebrew
/// (`openjdk@21`, keg-only, so never on the PATH) and the Linux packages put
/// it. `null` when there is none. A `javac` on the PATH is not enough:
/// som_toolchains.md builds against 21, and on mbp `/usr/bin/javac` is a
/// Corretto 17 shim.
String? findJdk21() {
  final candidates = [
    ?Platform.environment['JAVA_HOME'],
    '/opt/homebrew/opt/openjdk@21',
    '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
    '/usr/lib/jvm/java-21-openjdk-amd64',
    '/usr/lib/jvm/java-21-openjdk-arm64',
    '/usr/lib/jvm/java-21-openjdk',
  ];
  for (final home in candidates) {
    final javac = File(p.join(home, 'bin', 'javac'));
    if (!javac.existsSync()) continue;
    final r = Process.runSync(javac.path, ['-version']);
    if (r.exitCode == 0 && '${r.stdout}${r.stderr}'.contains('javac 21')) {
      return home;
    }
  }
  return null;
}

/// The `javac` the SOM Java tests compile with: JDK 21's when there is one,
/// else whichever the PATH has; `null` when there is none.
String? findJavac() {
  final jdk = findJdk21();
  if (jdk != null) return p.join(jdk, 'bin', 'javac');
  try {
    final r = Process.runSync('javac', ['-version']);
    if (r.exitCode == 0) return 'javac';
  } on ProcessException {
    // none on the PATH
  }
  return null;
}

/// A `gradle` binary: the PATH first, else a distribution the Gradle wrapper
/// has unpacked under `~/.gradle/wrapper/dists` ([version] preferred, else the
/// newest 8.x). `null` when there is none.
String? findGradle({String version = '8.14'}) {
  for (final dir in (Platform.environment['PATH'] ?? '').split(':')) {
    if (dir.isNotEmpty && File(p.join(dir, 'gradle')).existsSync()) {
      return p.join(dir, 'gradle');
    }
  }
  final dists = Directory(
    p.join(Platform.environment['HOME'] ?? '', '.gradle', 'wrapper', 'dists'),
  );
  if (!dists.existsSync()) return null;
  final found = <String, String>{};
  for (final dist in dists.listSync().whereType<Directory>()) {
    final m = RegExp(
      r'^gradle-(8\.[0-9.]+)-(all|bin)$',
    ).firstMatch(p.basename(dist.path));
    if (m == null) continue;
    for (final hash in dist.listSync().whereType<Directory>()) {
      final bin = File(p.join(hash.path, 'gradle-${m[1]}', 'bin', 'gradle'));
      if (bin.existsSync()) found[m[1]!] = bin.path;
    }
  }
  if (found.containsKey(version)) return found[version];
  if (found.isEmpty) return null;
  int part(String v, int i) =>
      int.parse(v.split('.').elementAtOrNull(i) ?? '0');
  final newest = found.keys.reduce(
    (a, b) => part(a, 1) != part(b, 1)
        ? (part(a, 1) > part(b, 1) ? a : b)
        : (part(a, 2) >= part(b, 2) ? a : b),
  );
  return found[newest];
}
