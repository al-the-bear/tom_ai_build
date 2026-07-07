/// Shared groundwork for packaging the nine SOM language libraries (PGK1).
///
/// The per-language SOM projects (`tom_som_<lang>_runtime` +
/// `tom_som_<lang>_v0`) must be integratable through each ecosystem's native
/// package tooling. This library holds the **language-agnostic** machinery the
/// per-language work (PGK2..PGK10) builds on:
///
///   * [packageVersionFromModel] — the single version rule: every package's
///     version is derived from the TomSpecs *model version*, never maintained
///     independently.
///   * [PackagingDescriptor] / [PackagingRoute] — the per-language data a
///     language target supplies; the renderers below turn it into committed
///     docs.
///   * [renderFacadeReadme] / [renderHowToIntegrate] — the shared README
///     short-form "how to use" block and the separate `readme_howtointegrate.md`
///     full guide. Structurally identical across languages; only the
///     ecosystem-specific commands differ.
///   * [rewriteManifestVersion] — realigns a runtime manifest's own version
///     field to the model version (the runtime is hand-authored and not
///     regenerated, so only its version is touched).
///   * [ensureGitignoreContent] — the built-artifact ignore policy: emitted
///     packaging never checks in binaries (wheels, jars, `.crate`, `dist/`, …).
///   * [writeFacadePackaging] / [alignRuntimeManifestVersion] — the IO hooks
///     `generate_som.dart` invokes per target (via [packagingDescriptorFor]).
///
/// Nothing here hard-codes a language; [packagingDescriptorFor] is the empty
/// registry each per-language todo fills in, at which point the generator hook
/// activates for that language.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'spec_object_model_config.dart' show SomLanguage;

/// The manifest a runtime package uses to declare its own version.
enum ManifestFormat {
  /// `pubspec.yaml` — `version: X.Y.Z`.
  pubspec,

  /// `pyproject.toml` — `version = "X.Y.Z"` (PEP 621 `[project]`).
  pyproject,

  /// `package.json` — `"version": "X.Y.Z"`.
  packageJson,

  /// `Cargo.toml` — `version = "X.Y.Z"` in `[package]`.
  cargoToml,

  /// A Go source version constant — `Version = "vX.Y.Z"` (Go versions live in
  /// VCS tags, so the module carries an in-source constant instead).
  goVersionConst,

  /// A `Makefile` variable — `VERSION := X.Y.Z` (C / C++, no registry).
  makefileVar,

  /// A Maven `pom.xml` — the project `<version>X.Y.Z</version>` element.
  pomXml,
}

/// The canonical package version derived from the TomSpecs [modelVersion]
/// string (`major.minor`, e.g. `'1.0'`).
///
/// Normalises to a three-component semver (`major.minor.patch`), padding missing
/// components with `0` and coercing non-numeric components to `0`:
///
///   * `'1.0'`   → `'1.0.0'`
///   * `'2'`     → `'2.0.0'`
///   * `'1.4.7'` → `'1.4.7'`
///   * `''`      → `'0.0.0'`
///
/// This is the one place the version mapping lives, so every package (runtime +
/// facade, all nine languages) reports exactly the same version.
String packageVersionFromModel(String modelVersion) {
  final parts = modelVersion.trim().split('.');
  final nums = <String>[
    for (final part in parts) (int.tryParse(part.trim()) ?? 0).toString(),
  ];
  while (nums.length < 3) {
    nums.add('0');
  }
  return nums.take(3).join('.');
}

/// One documented way to add the library as a dependency (registry, git, path,
/// vendored, …) rendered into `readme_howtointegrate.md`.
class PackagingRoute {
  const PackagingRoute({required this.heading, required this.body});

  /// The route's sub-heading (e.g. `'From the package registry'`).
  final String heading;

  /// The route's markdown body (commands / snippet).
  final String body;
}

/// The per-language data the shared renderers and hooks consume. Each SOM
/// language supplies one of these (PGK2..PGK10) and registers it in
/// [packagingDescriptorFor]; everything else is language-agnostic.
class PackagingDescriptor {
  const PackagingDescriptor({
    required this.language,
    required this.displayName,
    required this.runtimePackageName,
    required this.facadePackageName,
    required this.codeFence,
    required this.installShort,
    required this.usageSnippet,
    required this.integrateRoutes,
    required this.buildFromSource,
    required this.buildArtifactIgnores,
    required this.runtimeManifestFileName,
    required this.runtimeManifestFormat,
  });

  /// The SOM language this describes.
  final SomLanguage language;

  /// Human-readable language name for prose (e.g. `'Dart'`, `'C++'`).
  final String displayName;

  /// The runtime package's ecosystem name (e.g. `'tom_som_dart_runtime'`).
  final String runtimePackageName;

  /// The generated facade package's ecosystem name.
  final String facadePackageName;

  /// The fenced-code-block language tag for snippets (e.g. `'dart'`, `'bash'`).
  final String codeFence;

  /// The one-line "add the dependency" command shown in the README short block.
  final String installShort;

  /// A minimal usage snippet (loads a document, reads a section).
  final String usageSnippet;

  /// The dependency routes rendered into `readme_howtointegrate.md`.
  final List<PackagingRoute> integrateRoutes;

  /// The command(s) that build/pack the library from source.
  final String buildFromSource;

  /// The build-artifact globs to keep out of version control.
  final List<String> buildArtifactIgnores;

  /// The runtime manifest file whose version is realigned to the model version.
  final String runtimeManifestFileName;

  /// The runtime manifest's format (drives [rewriteManifestVersion]).
  final ManifestFormat runtimeManifestFormat;
}

const String _generatedBanner =
    '<!-- GENERATED by tom_specs_clitool generate_som — do not edit by hand. -->';

/// The workspace-standard proprietary license text, identical for every SOM
/// package (runtime + facade, all nine languages) so a published package always
/// carries a `LICENSE` file — an ecosystem publish requirement (e.g. pub.dev
/// rejects a package with no `LICENSE`). Matches the sibling Tom packages.
const String licenseText = '''
Copyright (c) 2024-2026 Peter Nicolai Alexis Kyaw. All rights reserved.

This code is proprietary and confidential. Unauthorized copying, modification,
distribution, or use of this software, via any medium, is strictly prohibited.

For licensing inquiries, find me on LinkedIn under "Alexis Kyaw".
''';

/// The facade `CHANGELOG.md`: a single entry at the model [version]. Package
/// registries (pub.dev, npm) recommend a changelog; the SOM facade is fully
/// regenerated per model version, so the changelog is a one-line statement of
/// that fact rather than a hand-maintained history.
String renderChangelog(PackagingDescriptor d, {required String version}) {
  final b = StringBuffer()
    ..writeln('# Changelog')
    ..writeln()
    ..writeln(_generatedBanner)
    ..writeln()
    ..writeln('## $version')
    ..writeln()
    ..writeln('- Generated `${d.facadePackageName}` at TomSpecs model version '
        '`$version`.')
    ..writeln('- Regenerated wholesale from the model by '
        '`tom_specs_clitool/bin/generate_som.dart`; the version tracks the '
        'TomSpecs model version.');
  return b.toString();
}

/// The short-form facade `README.md`: a "How to use" block at the very top
/// (install one-liner + minimal snippet) plus a pointer to the full guide.
String renderFacadeReadme(PackagingDescriptor d, {required String version}) {
  final b = StringBuffer()
    ..writeln('# ${d.facadePackageName}')
    ..writeln()
    ..writeln(_generatedBanner)
    ..writeln()
    ..writeln('Generated typed TomSpecs object model (v$version) for '
        '${d.displayName}. An editing facade over the generic '
        '`${d.runtimePackageName}`; regenerate with '
        '`tom_specs_clitool/bin/generate_som.dart`.')
    ..writeln()
    ..writeln('## How to use')
    ..writeln()
    ..writeln(d.installShort)
    ..writeln()
    ..writeln('```${d.codeFence}')
    ..writeln(d.usageSnippet.trimRight())
    ..writeln('```')
    ..writeln()
    ..writeln('See **readme_howtointegrate.md** for full integration '
        'instructions — every dependency route and how to pin the version.');
  return b.toString();
}

/// The separate `readme_howtointegrate.md`: the full integration guide (all
/// dependency routes, version pinning to the model version, build-from-source).
String renderHowToIntegrate(PackagingDescriptor d, {required String version}) {
  final b = StringBuffer()
    ..writeln('# Integrating ${d.facadePackageName}')
    ..writeln()
    ..writeln(_generatedBanner)
    ..writeln()
    ..writeln('`${d.facadePackageName}` is the typed TomSpecs object-model '
        'facade for ${d.displayName}. It depends on `${d.runtimePackageName}`. '
        'Both are versioned to the TomSpecs **model version** (currently '
        '`$version`) — pin to that version so your document reads and writes '
        'match the model the facade was generated from.')
    ..writeln()
    ..writeln('## Quick start')
    ..writeln()
    ..writeln(d.installShort)
    ..writeln()
    ..writeln('```${d.codeFence}')
    ..writeln(d.usageSnippet.trimRight())
    ..writeln('```')
    ..writeln()
    ..writeln('## Dependency routes')
    ..writeln();
  for (final route in d.integrateRoutes) {
    b
      ..writeln('### ${route.heading}')
      ..writeln()
      ..writeln(route.body.trimRight())
      ..writeln();
  }
  b
    ..writeln('## Pinning the version')
    ..writeln()
    ..writeln('Both `${d.runtimePackageName}` and `${d.facadePackageName}` '
        'carry version `$version`, taken from the TomSpecs model version. When '
        'you upgrade the model, regenerate and move to the new matching '
        'version so the facade and your stored documents stay in step.')
    ..writeln()
    ..writeln('## Building from source')
    ..writeln()
    ..writeln(d.buildFromSource.trimRight());
  return b.toString();
}

/// Rewrites the package's own version field in [content] to [version] for the
/// given [format], returning the updated content. Idempotent — rewriting to the
/// same version leaves the text unchanged. Throws [StateError] if no version
/// field is found (a malformed manifest the caller must fix).
String rewriteManifestVersion(
  String content,
  ManifestFormat format,
  String version,
) {
  final (RegExp pattern, String Function(Match) replace) rule = switch (format) {
    ManifestFormat.pubspec => (
        RegExp(r'^version:\s*.*$', multiLine: true),
        (_) => 'version: $version',
      ),
    ManifestFormat.pyproject => (
        RegExp(r'^version\s*=\s*".*"', multiLine: true),
        (_) => 'version = "$version"',
      ),
    ManifestFormat.packageJson => (
        RegExp(r'"version"\s*:\s*".*?"'),
        (_) => '"version": "$version"',
      ),
    ManifestFormat.cargoToml => (
        RegExp(r'^version\s*=\s*".*"', multiLine: true),
        (_) => 'version = "$version"',
      ),
    ManifestFormat.goVersionConst => (
        RegExp(r'Version\s*=\s*"[^"]*"'),
        (_) => 'Version = "v$version"',
      ),
    ManifestFormat.makefileVar => (
        RegExp(r'^VERSION\s*[:?]?=.*$', multiLine: true),
        (_) => 'VERSION := $version',
      ),
    ManifestFormat.pomXml => (
        RegExp(r'<version>[^<]*</version>'),
        (_) => '<version>$version</version>',
      ),
  };
  if (!rule.$1.hasMatch(content)) {
    throw StateError(
        'no $format version field found to realign to $version');
  }
  // Replace only the first match (the package's own version), leaving later
  // occurrences (e.g. dependency versions) untouched.
  return content.replaceFirstMapped(rule.$1, rule.$2);
}

const String _gitignoreHeader =
    '# --- tom_specs packaging build artifacts (managed) ---';

/// Ensures [existing] `.gitignore` content ignores every glob in [globs],
/// appending the missing ones under a managed header. Idempotent — a file that
/// already ignores all of them is returned unchanged.
String ensureGitignoreContent(String existing, List<String> globs) {
  final lines = existing.split('\n').map((l) => l.trim()).toSet();
  final missing = [for (final g in globs) if (!lines.contains(g.trim())) g];
  if (missing.isEmpty) {
    return existing;
  }
  final b = StringBuffer(existing);
  if (existing.isNotEmpty && !existing.endsWith('\n')) {
    b.writeln();
  }
  if (!existing.contains(_gitignoreHeader)) {
    b
      ..writeln()
      ..writeln(_gitignoreHeader);
  }
  for (final g in missing) {
    b.writeln(g);
  }
  return b.toString();
}

/// Writes the facade's packaging docs (`README.md`, `readme_howtointegrate.md`,
/// `LICENSE`, `CHANGELOG.md`) and ensures its `.gitignore`, all under
/// [outputRoot], stamped with [version]. This is the emit-hook
/// `generate_som.dart` calls per target once the target has a registered
/// [PackagingDescriptor]. `LICENSE` and `CHANGELOG.md` are ecosystem-neutral
/// (every registry benefits from them), so they live here rather than in a
/// per-language generator.
void writeFacadePackaging({
  required String outputRoot,
  required PackagingDescriptor descriptor,
  required String version,
}) {
  File(p.join(outputRoot, 'README.md'))
      .writeAsStringSync(renderFacadeReadme(descriptor, version: version));
  File(p.join(outputRoot, 'readme_howtointegrate.md'))
      .writeAsStringSync(renderHowToIntegrate(descriptor, version: version));
  File(p.join(outputRoot, 'LICENSE')).writeAsStringSync(licenseText);
  File(p.join(outputRoot, 'CHANGELOG.md'))
      .writeAsStringSync(renderChangelog(descriptor, version: version));
  final ignorePath = p.join(outputRoot, '.gitignore');
  final existing =
      File(ignorePath).existsSync() ? File(ignorePath).readAsStringSync() : '';
  final updated =
      ensureGitignoreContent(existing, descriptor.buildArtifactIgnores);
  if (updated != existing) {
    File(ignorePath).writeAsStringSync(updated);
  }
}

/// Realigns the hand-authored runtime package's version to [version]. The
/// runtime source is never regenerated; only its manifest version field is
/// rewritten so runtime and facade stay in lockstep with the model version.
/// No-op (leaves the file untouched) if it already declares [version].
void alignRuntimeManifestVersion({
  required String runtimeDir,
  required PackagingDescriptor descriptor,
  required String version,
}) {
  final manifest = File(p.join(runtimeDir, descriptor.runtimeManifestFileName));
  if (!manifest.existsSync()) {
    throw StateError('runtime manifest not found: ${manifest.path}');
  }
  final content = manifest.readAsStringSync();
  final updated = rewriteManifestVersion(
      content, descriptor.runtimeManifestFormat, version);
  if (updated != content) {
    manifest.writeAsStringSync(updated);
  }
}

/// The per-language packaging descriptor registry.
///
/// Each per-language todo (PGK2..PGK10) adds its [PackagingDescriptor] here,
/// which immediately activates [writeFacadePackaging] +
/// [alignRuntimeManifestVersion] for that language on the next
/// `generate_som.dart` run. PGK2 registered Dart (pub); PGK3 registered Python
/// (PEP 517); PGK4 registered Java (Maven); PGK5 registered JavaScript (npm);
/// PGK6 registered TypeScript (npm + compiled `dist/`); PGK7 registered Go
/// (module path + in-source version constant / VCS tag scheme); PGK8 registered
/// Rust (Cargo crate — versioned `path` dependency + crate metadata).
const Map<SomLanguage, PackagingDescriptor> _packagingDescriptors = {
  SomLanguage.dart: _dartDescriptor,
  SomLanguage.python: _pythonDescriptor,
  SomLanguage.java: _javaDescriptor,
  SomLanguage.javascript: _javaScriptDescriptor,
  SomLanguage.typescript: _typeScriptDescriptor,
  SomLanguage.go: _goDescriptor,
  SomLanguage.rust: _rustDescriptor,
};

/// Dart (pub) packaging descriptor — PGK2. The facade `tom_som_dart_v0` and the
/// runtime `tom_som_dart_runtime` are both publishable pub packages versioned to
/// the TomSpecs model version.
const PackagingDescriptor _dartDescriptor = PackagingDescriptor(
  language: SomLanguage.dart,
  displayName: 'Dart',
  runtimePackageName: 'tom_som_dart_runtime',
  facadePackageName: 'tom_som_dart_v0',
  codeFence: 'dart',
  installShort: 'Add `tom_som_dart_v0` to your `pubspec.yaml` '
      '(`dart pub add tom_som_dart_v0`), then:',
  usageSnippet: '''
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  // A typed Solution Blueprint over a fresh document.
  final doc = SpecDocument();
  final blueprint = D00SolutionBlueprint(doc);

  blueprint.content = 'A platform that unifies our fragmented order systems.';
  blueprint.currentLandscape.content =
      'Three legacy systems with no shared customer record.';

  print(blueprint.content);
}''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From pub.dev',
      body: 'Add the dependency and let pub resolve it:\n\n'
          '```bash\n'
          'dart pub add tom_som_dart_v0\n'
          '```\n\n'
          'or pin it explicitly in `pubspec.yaml`:\n\n'
          '```yaml\n'
          'dependencies:\n'
          '  tom_som_dart_v0: ^VERSION\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Git dependency',
      body: 'Depend on the package directly from source control:\n\n'
          '```yaml\n'
          'dependencies:\n'
          '  tom_som_dart_v0:\n'
          '    git:\n'
          '      url: https://github.com/al-the-bear/tom_ai_build.git\n'
          '      path: tom_ai/ai_build/tom_som_dart_v0\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Path dependency (monorepo / vendored)',
      body: 'When the SOM projects sit alongside your package, depend by '
          'path:\n\n'
          '```yaml\n'
          'dependencies:\n'
          '  tom_som_dart_v0:\n'
          '    path: ../tom_som_dart_v0\n'
          '```',
    ),
  ],
  buildFromSource: 'Regenerate the facade and dry-run the package from the '
      'workspace:\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_dart_v0 && dart pub get && dart pub publish --dry-run\n'
      '```',
  buildArtifactIgnores: ['.dart_tool/', 'build/', 'doc/api/', '*.tar.gz'],
  runtimeManifestFileName: 'pubspec.yaml',
  runtimeManifestFormat: ManifestFormat.pubspec,
);

/// Python (PEP 517) packaging descriptor — PGK3. The facade `tom_som_python_v0`
/// and the runtime `tom_som_python_runtime` are both PEP 517 source
/// distributions (`python -m build` → wheel + sdist) versioned to the TomSpecs
/// model version. The facade is a single top-level module (`py-modules`); the
/// runtime ships the importable `tom_som_runtime` package.
const PackagingDescriptor _pythonDescriptor = PackagingDescriptor(
  language: SomLanguage.python,
  displayName: 'Python',
  runtimePackageName: 'tom_som_python_runtime',
  facadePackageName: 'tom_som_python_v0',
  codeFence: 'python',
  installShort: 'Install `tom_som_python_v0` (`pip install tom_som_python_v0`), '
      'then:',
  usageSnippet: '''
import tom_som_python_v0 as m
from tom_som_runtime import SpecDocument

# A typed Solution Blueprint over a fresh document.
doc = SpecDocument()
blueprint = m.D00SolutionBlueprint(doc)

blueprint.content = "A platform that unifies our fragmented order systems."
blueprint.currentLandscape.content = (
    "Three legacy systems with no shared customer record."
)

print(blueprint.content)''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From PyPI',
      body: 'Install the facade (it pulls in `tom_som_python_runtime`):\n\n'
          '```bash\n'
          'pip install tom_som_python_v0\n'
          '```\n\n'
          'or pin it in your `pyproject.toml` / `requirements.txt`:\n\n'
          '```\n'
          'tom_som_python_v0>=VERSION\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Git dependency',
      body: 'Install directly from source control (the facade lives in a '
          'sub-directory of the mono-repo):\n\n'
          '```bash\n'
          'pip install "tom_som_python_v0 @ '
          'git+https://github.com/al-the-bear/tom_ai_build.git'
          '#subdirectory=tom_ai/ai_build/tom_som_python_v0"\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Path / editable (monorepo / vendored)',
      body: 'When the SOM projects sit alongside your code, install both the '
          'facade and the runtime editable:\n\n'
          '```bash\n'
          'pip install -e ../tom_som_python_runtime\n'
          'pip install -e ../tom_som_python_v0\n'
          '```\n\n'
          'For a no-install checkout the facade also records the runtime '
          'location under `[tool.tom_som] runtime-path` in its '
          '`pyproject.toml`; add that path to `PYTHONPATH` so '
          '`import tom_som_runtime` resolves.',
    ),
  ],
  buildFromSource: 'Regenerate the facade and build the PEP 517 dists from the '
      'workspace:\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_python_v0 && python -m build\n'
      '```\n\n'
      'This writes a wheel and an sdist under `dist/`.',
  buildArtifactIgnores: [
    'dist/',
    'build/',
    '*.egg-info/',
    '__pycache__/',
    '*.pyc',
    '.venv/',
  ],
  runtimeManifestFileName: 'pyproject.toml',
  runtimeManifestFormat: ManifestFormat.pyproject,
);

/// Java (Maven) packaging descriptor — PGK4. The facade `tom_som_java_v0` and
/// the runtime `tom_som_java_runtime` are both Maven `jar` artifacts versioned
/// to the TomSpecs model version. The build host here carries only the JDK (no
/// Maven), so each project also ships a `build_jar.sh` fallback that compiles
/// with `javac` and packages with `jar` — producing the same artifact
/// `mvn package` would.
const PackagingDescriptor _javaDescriptor = PackagingDescriptor(
  language: SomLanguage.java,
  displayName: 'Java',
  runtimePackageName: 'tom_som_java_runtime',
  facadePackageName: 'tom_som_java_v0',
  codeFence: 'java',
  installShort: 'Add `tom_som_java_v0` (group `com.altbear.tomsom`) to your '
      'Maven `pom.xml`, then:',
  usageSnippet: '''
import tom_som_runtime.SpecDocument;
import tom_som_java_v0.TomSomV0;

// A typed Solution Blueprint over a fresh document.
SpecDocument doc = new SpecDocument();
TomSomV0.D00SolutionBlueprint blueprint = new TomSomV0.D00SolutionBlueprint(doc);

blueprint.content("A platform that unifies our fragmented order systems.");
blueprint.currentLandscape()
    .content("Three legacy systems with no shared customer record.");

System.out.println(blueprint.content());''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From a Maven repository',
      body: 'Declare the dependency (it pulls in `tom_som_java_runtime`):\n\n'
          '```xml\n'
          '<dependency>\n'
          '  <groupId>com.altbear.tomsom</groupId>\n'
          '  <artifactId>tom_som_java_v0</artifactId>\n'
          '  <version>VERSION</version>\n'
          '</dependency>\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Local install (mvn install)',
      body: 'When the SOM projects sit alongside your build, install both into '
          'your local `~/.m2` repository, runtime first:\n\n'
          '```bash\n'
          'cd ../tom_som_java_runtime && mvn install\n'
          'cd ../tom_som_java_v0 && mvn install\n'
          '```',
    ),
    PackagingRoute(
      heading: 'JAR fallback (no Maven)',
      body: 'On a JDK-only host, build the JARs with the bundled scripts '
          '(runtime first — the facade compiles against it):\n\n'
          '```bash\n'
          'cd ../tom_som_java_runtime && ./build_jar.sh\n'
          'cd ../tom_som_java_v0 && ./build_jar.sh\n'
          '```\n\n'
          'Each writes `build/<artifact>-<version>.jar`. Put both on your '
          '`javac`/`java` classpath.',
    ),
  ],
  buildFromSource: 'Regenerate the facade and build the JARs from the '
      'workspace:\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      '# Maven, if available:\n'
      'cd tom_som_java_v0 && mvn package\n'
      '# or the JDK-only fallback (runtime first):\n'
      'cd tom_som_java_runtime && ./build_jar.sh\n'
      'cd ../tom_som_java_v0 && ./build_jar.sh\n'
      '```',
  buildArtifactIgnores: ['build/', 'build_tool/', '*.class', '*.jar'],
  runtimeManifestFileName: 'pom.xml',
  runtimeManifestFormat: ManifestFormat.pomXml,
);

/// JavaScript (npm) packaging descriptor — PGK5. The facade
/// `tom_som_javascript_v0` and the runtime `tom_som_javascript_runtime` are both
/// npm packages versioned to the TomSpecs model version. The facade is a single
/// CommonJS module plus its `meta/` + `schemas/` payload; the runtime ships the
/// importable `tom_som_runtime/` package. Both are `private` (proprietary), so
/// `npm pack` is the packaging check rather than `npm publish`.
const PackagingDescriptor _javaScriptDescriptor = PackagingDescriptor(
  language: SomLanguage.javascript,
  displayName: 'JavaScript',
  runtimePackageName: 'tom_som_javascript_runtime',
  facadePackageName: 'tom_som_javascript_v0',
  codeFence: 'javascript',
  installShort: 'Add `tom_som_javascript_v0` to your project '
      '(`npm install tom_som_javascript_v0`), then:',
  usageSnippet: '''
const m = require('tom_som_javascript_v0');
const { SpecDocument } = require('tom_som_javascript_runtime');

// A typed Solution Blueprint over a fresh document.
const doc = new SpecDocument();
const blueprint = new m.D00SolutionBlueprint(doc);

blueprint.content = 'A platform that unifies our fragmented order systems.';
blueprint.currentLandscape.content =
    'Three legacy systems with no shared customer record.';

console.log(blueprint.content);''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From npm',
      body: 'Install the facade (it depends on `tom_som_javascript_runtime`):'
          '\n\n'
          '```bash\n'
          'npm install tom_som_javascript_v0\n'
          '```\n\n'
          'or pin it in your `package.json`:\n\n'
          '```json\n'
          '"dependencies": {\n'
          '  "tom_som_javascript_v0": "^VERSION"\n'
          '}\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Git dependency',
      body: 'Depend on the facade directly from source control (it lives in a '
          'sub-directory of the mono-repo):\n\n'
          '```bash\n'
          'npm install '
          '"git+https://github.com/al-the-bear/tom_ai_build.git'
          '#path:tom_ai/ai_build/tom_som_javascript_v0"\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Path / link (monorepo / vendored)',
      body: 'When the SOM projects sit alongside your code, link both the '
          'runtime and the facade (runtime first):\n\n'
          '```bash\n'
          'npm install ../tom_som_javascript_runtime\n'
          'npm install ../tom_som_javascript_v0\n'
          '```\n\n'
          'For a no-install checkout the facade also records the runtime '
          'location under `tomSom.runtimePath` in its `package.json`, so it '
          'resolves the runtime by relative path without a registered '
          'dependency.',
    ),
  ],
  buildFromSource: 'Regenerate the facade and dry-run the packages from the '
      'workspace:\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_javascript_runtime && npm pack --dry-run\n'
      'cd ../tom_som_javascript_v0 && npm pack --dry-run\n'
      '```',
  buildArtifactIgnores: ['node_modules/', '*.tgz'],
  runtimeManifestFileName: 'package.json',
  runtimeManifestFormat: ManifestFormat.packageJson,
);

/// TypeScript (npm + compiled `dist/`) packaging descriptor — PGK6. The facade
/// `tom_som_typescript_v0` and the runtime `tom_som_typescript_runtime` are both
/// npm packages that ship **compiled `dist/`** (`.js` + `.d.ts`) built by a
/// `prepack` step (`tsc`), versioned to the TomSpecs model version. The facade
/// imports the runtime by bare specifier wired through a relative `file:`
/// dependency, so its `prepack` builds the runtime first, then the facade. Both
/// are `private` (proprietary), so `npm pack` is the packaging check rather than
/// `npm publish`.
const PackagingDescriptor _typeScriptDescriptor = PackagingDescriptor(
  language: SomLanguage.typescript,
  displayName: 'TypeScript',
  runtimePackageName: 'tom_som_typescript_runtime',
  facadePackageName: 'tom_som_typescript_v0',
  codeFence: 'typescript',
  installShort: 'Add `tom_som_typescript_v0` to your project '
      '(`npm install tom_som_typescript_v0`), then:',
  usageSnippet: '''
import { SpecDocument } from 'tom_som_typescript_runtime';
import { D00SolutionBlueprint } from 'tom_som_typescript_v0';

// A typed Solution Blueprint over a fresh document.
const doc = new SpecDocument();
const blueprint = new D00SolutionBlueprint(doc);

blueprint.content = 'A platform that unifies our fragmented order systems.';
blueprint.currentLandscape.content =
    'Three legacy systems with no shared customer record.';

console.log(blueprint.content);''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From npm',
      body: 'Install the facade (it depends on `tom_som_typescript_runtime`):'
          '\n\n'
          '```bash\n'
          'npm install tom_som_typescript_v0\n'
          '```\n\n'
          'or pin it in your `package.json`:\n\n'
          '```json\n'
          '"dependencies": {\n'
          '  "tom_som_typescript_v0": "^VERSION"\n'
          '}\n'
          '```\n\n'
          'The published package ships compiled `dist/` (`.js` + `.d.ts`), so '
          'no build step is required to consume it.',
    ),
    PackagingRoute(
      heading: 'Git dependency',
      body: 'Depend on the facade directly from source control (it lives in a '
          'sub-directory of the mono-repo). Because the tarball is built on '
          '`prepack`, a git install compiles `dist/` for you:\n\n'
          '```bash\n'
          'npm install '
          '"git+https://github.com/al-the-bear/tom_ai_build.git'
          '#path:tom_ai/ai_build/tom_som_typescript_v0"\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Path / link (monorepo / vendored)',
      body: 'When the SOM projects sit alongside your code, install both the '
          'runtime and the facade (runtime first — the facade compiles against '
          "the runtime's `dist/`):\n\n"
          '```bash\n'
          'npm install ../tom_som_typescript_runtime\n'
          'npm install ../tom_som_typescript_v0\n'
          '```\n\n'
          'The facade already declares the runtime as a relative `file:` '
          'dependency in its `package.json`, so an in-tree `npm install` links '
          'it and `npm run build` compiles both.',
    ),
  ],
  buildFromSource: 'Regenerate the facade and dry-run the packages from the '
      'workspace (each `prepack` runs `tsc`; the facade builds the runtime '
      'first):\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_typescript_runtime && npm install && npm pack --dry-run\n'
      'cd ../tom_som_typescript_v0 && npm install && npm pack --dry-run\n'
      '```',
  buildArtifactIgnores: ['node_modules/', 'dist/', '*.tgz'],
  runtimeManifestFileName: 'package.json',
  runtimeManifestFormat: ManifestFormat.packageJson,
);

/// Go (module + VCS tag) packaging descriptor — PGK7. The facade `tom_som_go_v0`
/// and the runtime `tom_som_go_runtime` are Go modules with **domain-qualified
/// module paths** (`github.com/al-the-bear/tom_ai_build/tom_som_go_<v>`), so
/// `go get` can resolve them. Go has no registry: distribution is by VCS tag, so
/// each module also carries an **in-source `Version` constant** (`Version =
/// "vX.Y.Z"`) set to the TomSpecs model version, and the documented tag scheme is
/// the matching `vMAJOR.MINOR.PATCH` tag. The runtime's version constant lives in
/// its hand-authored `doc.go`, realigned by [alignRuntimeManifestVersion]. Locally
/// the facade resolves the runtime through a relative `replace` directive; a real
/// `go get` uses the required module path + tag (dependency `replace` directives
/// are ignored, so the `require` names the real remote path).
const PackagingDescriptor _goDescriptor = PackagingDescriptor(
  language: SomLanguage.go,
  displayName: 'Go',
  runtimePackageName: 'tom_som_go_runtime',
  facadePackageName: 'tom_som_go_v0',
  codeFence: 'go',
  installShort: 'Add `tom_som_go_v0` to your module '
      '(`go get github.com/al-the-bear/tom_ai_build/tom_som_go_v0@v1.0.0`), '
      'then:',
  usageSnippet: '''
import (
	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

// A typed Solution Blueprint over a fresh document. The constructor also runs
// the instantiation-time model-version check (an empty stamp is editable).
doc := som.NewSpecDocument()
blueprint, err := somv0.NewD00SolutionBlueprint(doc, "")
if err != nil {
	panic(err)
}

blueprint.SetContent("A platform that unifies our fragmented order systems.")
blueprint.CurrentLandscape().SetContent(
	"Three legacy systems with no shared customer record.")

fmt.Println(blueprint.Content())''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From `go get`',
      body: 'Fetch the facade at a version tag (it pulls in '
          '`tom_som_go_runtime`):\n\n'
          '```bash\n'
          'go get github.com/al-the-bear/tom_ai_build/tom_som_go_v0@vVERSION\n'
          '```\n\n'
          'or pin it in your `go.mod`:\n\n'
          '```\n'
          'require github.com/al-the-bear/tom_ai_build/tom_som_go_v0 vVERSION\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Version tags',
      body: 'Go has no central registry — a module version *is* a VCS tag. Both '
          '`tom_som_go_runtime` and `tom_som_go_v0` are tagged '
          '`vMAJOR.MINOR.PATCH` at the TomSpecs model version (currently '
          '`vVERSION`), matching the in-source `Version` constant each module '
          'exports. Fetch a specific version with '
          '`go get <module-path>@vMAJOR.MINOR.PATCH`.',
    ),
    PackagingRoute(
      heading: 'Path replace (monorepo / vendored)',
      body: 'When the SOM projects sit alongside your code, point Go at the '
          'local checkout with a `replace` directive in your `go.mod` (the '
          'facade already does this for the runtime):\n\n'
          '```\n'
          'require github.com/al-the-bear/tom_ai_build/tom_som_go_v0 v0.0.0\n'
          '\n'
          'replace github.com/al-the-bear/tom_ai_build/tom_som_go_v0 => '
          '../tom_som_go_v0\n'
          'replace github.com/al-the-bear/tom_ai_build/tom_som_go_runtime => '
          '../tom_som_go_runtime\n'
          '```',
    ),
  ],
  buildFromSource: 'Regenerate the facade and build/vet both modules from the '
      'workspace (the facade resolves the runtime through its relative '
      '`replace`):\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_go_runtime && go build ./... && go vet ./...\n'
      'cd ../tom_som_go_v0 && go build ./... && go vet ./...\n'
      '```',
  buildArtifactIgnores: ['*.test', '*.out'],
  runtimeManifestFileName: 'doc.go',
  runtimeManifestFormat: ManifestFormat.goVersionConst,
);

/// Rust (Cargo crate) packaging descriptor — PGK8. The facade `tom_som_rust_v0`
/// and the runtime `tom_som_rust_runtime` are Cargo crates versioned to the
/// TomSpecs model version. Both are `publish = false` (proprietary), so
/// `cargo package --no-verify` is the packaging check rather than `cargo
/// publish`. The facade resolves the runtime by a fixed crate name through a
/// relative `path` dependency; because `cargo package` requires every dependency
/// to carry a version, that dependency also pins `version = <model version>`
/// (the `path` is stripped from the packaged manifest, leaving the version).
const PackagingDescriptor _rustDescriptor = PackagingDescriptor(
  language: SomLanguage.rust,
  displayName: 'Rust',
  runtimePackageName: 'tom_som_rust_runtime',
  facadePackageName: 'tom_som_rust_v0',
  codeFence: 'rust',
  installShort: 'Add `tom_som_rust_v0` to your `Cargo.toml` '
      '(`cargo add tom_som_rust_v0`), then:',
  usageSnippet: '''
use tom_som_rust_runtime as som;
use tom_som_rust_v0::D00SolutionBlueprint;

fn main() {
    // A typed Solution Blueprint over a fresh document. The constructor also
    // runs the instantiation-time model-version check (an empty stamp is
    // editable).
    let doc = som::doc_ref(som::SpecDocument::new());
    let pd = D00SolutionBlueprint::new(doc, "").expect("new D00SolutionBlueprint");

    pd.set_content("A platform that unifies our fragmented order systems.");
    pd.current_landscape()
        .set_content("Three legacy systems with no shared customer record.");

    println!("{}", pd.content());
}''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'From crates.io',
      body: 'These are proprietary (`publish = false`) crates, so they are not '
          'on crates.io. When published to a private registry, add the facade '
          '(it pulls in `tom_som_rust_runtime`):\n\n'
          '```bash\n'
          'cargo add tom_som_rust_v0\n'
          '```\n\n'
          'or pin it in your `Cargo.toml`:\n\n'
          '```toml\n'
          '[dependencies]\n'
          'tom_som_rust_v0 = "VERSION"\n'
          '```',
    ),
    PackagingRoute(
      heading: 'Git dependency',
      body: 'Depend on the facade directly from source control (it lives in a '
          'sub-directory of the mono-repo):\n\n'
          '```toml\n'
          '[dependencies]\n'
          'tom_som_rust_v0 = { git = '
          '"https://github.com/al-the-bear/tom_ai_build.git", branch = "main" }\n'
          '```\n\n'
          'Cargo resolves the crate by name within the repository, so the '
          'sub-directory is discovered automatically.',
    ),
    PackagingRoute(
      heading: 'Path dependency (monorepo / vendored)',
      body: 'When the SOM crates sit alongside your crate, depend by path (the '
          'facade already does this for the runtime):\n\n'
          '```toml\n'
          '[dependencies]\n'
          'tom_som_rust_v0 = { path = "../tom_som_rust_v0", version = "VERSION" }\n'
          '```',
    ),
  ],
  buildFromSource: 'Regenerate the facade, then build/package from the '
      'workspace (runtime first — the facade compiles against it through its '
      'relative `path` dependency):\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_rust_runtime && cargo package --no-verify\n'
      'cd ../tom_som_rust_v0 && cargo build\n'
      '```\n\n'
      'The runtime `cargo package`s standalone. The facade depends on the '
      '`publish = false` runtime, and `cargo package` requires every dependency '
      'to resolve from a registry — so the facade is packaged only when the '
      'runtime is available in one (e.g. a private registry / workspace '
      'publish). Locally the facade builds against the runtime by path, which is '
      'the correctness check.',
  buildArtifactIgnores: ['/target', '/Cargo.lock'],
  runtimeManifestFileName: 'Cargo.toml',
  runtimeManifestFormat: ManifestFormat.cargoToml,
);

/// The [PackagingDescriptor] for [language], or `null` when none is registered
/// yet (in which case the generator's packaging hook is a no-op for it).
PackagingDescriptor? packagingDescriptorFor(SomLanguage language) =>
    _packagingDescriptors[language];
