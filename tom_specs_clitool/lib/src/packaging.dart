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

/// Writes the facade's packaging docs (`README.md`, `readme_howtointegrate.md`)
/// and ensures its `.gitignore`, all under [outputRoot], stamped with [version].
/// This is the emit-hook `generate_som.dart` calls per target once the target
/// has a registered [PackagingDescriptor].
void writeFacadePackaging({
  required String outputRoot,
  required PackagingDescriptor descriptor,
  required String version,
}) {
  File(p.join(outputRoot, 'README.md'))
      .writeAsStringSync(renderFacadeReadme(descriptor, version: version));
  File(p.join(outputRoot, 'readme_howtointegrate.md'))
      .writeAsStringSync(renderHowToIntegrate(descriptor, version: version));
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
/// Empty by design after PGK1: the shared mechanism and the generator hook are
/// in place, but no language is configured yet. Each per-language todo
/// (PGK2..PGK10) adds its [PackagingDescriptor] here, which immediately
/// activates [writeFacadePackaging] + [alignRuntimeManifestVersion] for that
/// language on the next `generate_som.dart` run.
const Map<SomLanguage, PackagingDescriptor> _packagingDescriptors = {};

/// The [PackagingDescriptor] for [language], or `null` when none is registered
/// yet (in which case the generator's packaging hook is a no-op for it).
PackagingDescriptor? packagingDescriptorFor(SomLanguage language) =>
    _packagingDescriptors[language];
