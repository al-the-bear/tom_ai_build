/// Shared groundwork for packaging the nine SOM language libraries (SOM §17).
///
/// The per-language SOM projects (`tom_som_<lang>_runtime` +
/// `tom_som_<lang>_v0`) must be integratable through each ecosystem's native
/// package tooling. This library holds the **language-agnostic** machinery the
/// per-language descriptors build on:
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
/// Nothing here hard-codes a language; [packagingDescriptorFor] is the registry
/// each language's descriptor is entered in, at which point the generator hook
/// activates for that language.
library;

import 'dart:convert';
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
  /// Declares one integration route.
  ///
  /// Both parts are required: a heading with no body documents nothing, and a
  /// body with no heading cannot be placed among the other routes.
  const PackagingRoute({required this.heading, required this.body});

  /// The route's sub-heading (e.g. `'From the package registry'`).
  final String heading;

  /// The route's markdown body (commands / snippet).
  final String body;
}

/// The per-language data the shared renderers and hooks consume. Each SOM
/// language supplies one of these (SOM §17.3) and registers it in
/// [packagingDescriptorFor]; everything else is language-agnostic.
class PackagingDescriptor {
  /// Declares one language's packaging facts.
  ///
  /// Every argument is required, deliberately: this is the *only* per-language
  /// input the shared renderers get, so a field left to a default would be a
  /// field silently wrong for eight of the nine languages. A new field added
  /// here breaks all nine descriptors at compile time, which is the point —
  /// the compiler asks each language for its answer rather than inventing one.
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
    required this.manifestDescription,
    required this.manifestDescriptionFile,
    required this.whereThisFitsSentence,
    required this.tutorialSentence,
    required this.exampleDirName,
    required this.examples,
    required this.usageSections,
    required this.verifyCommand,
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

  /// The facade manifest's own `description`, reproduced verbatim as the
  /// README's one-line description
  /// (`tom_specs_documentation_standard.md` §2.1 row 3).
  ///
  /// Held here rather than re-derived because the manifests are written by the
  /// nine per-language emitters, each in its own syntax; [manifestDescriptionFile]
  /// is what keeps the two from drifting apart silently.
  final String manifestDescription;

  /// The file inside the facade package that carries [manifestDescription] —
  /// the package manifest for the registry languages, the pkg-config
  /// `Description:` line in the `Makefile` for C and C++, the package doc
  /// comment for Go. Read by `packaging_test.dart`, which asserts the
  /// description still occurs there, so a manifest reworded by an emitter
  /// fails a test rather than leaving the README asserting the old wording.
  final String manifestDescriptionFile;

  /// The language-specific closing sentence of the README's "Where this fits"
  /// paragraph (`tom_specs_documentation_standard.md` §2.3) — what this
  /// ecosystem's reader most needs to know about how the facade behaves here.
  final String whereThisFitsSentence;

  /// One sentence describing this language's hand-written `doc/tutorial.md`,
  /// rendered into the README's cross-link block.
  ///
  /// Mandatory, and mandatory *per descriptor*: `tom_specs_documentation_standard.md`
  /// §4.2 puts the tutorial link in the template precisely so that no
  /// regeneration can lose it, and requiring the sentence here means a tenth
  /// language cannot be registered without one.
  final String tutorialSentence;

  /// The examples directory's name — `example` where the ecosystem's tooling
  /// expects the singular (Dart/pub), `examples` elsewhere.
  final String exampleDirName;

  /// The runnable samples, rendered as the README's Examples table. Each entry
  /// must name a file that exists (asserted by `packaging_test.dart`).
  final List<PackagingExample> examples;

  /// The README's `## Usage` sub-sections, in order.
  final List<PackagingUsage> usageSections;

  /// The command(s) that build and verify the facade package against the
  /// shared conformance corpus — the README's `## Status` answer in place of a
  /// fixed test count a generated file could never keep true.
  final String verifyCommand;
}

const String _generatedBanner =
    '<!-- GENERATED by tom_specs_clitool generate_som — do not edit by hand. -->';

/// The workspace-standard release license text (BSD 3-Clause, per the release-1
/// licence decision), identical for every SOM package (runtime + facade, all
/// nine languages) so a published package always carries a `LICENSE` file — an
/// ecosystem publish requirement (e.g. pub.dev rejects a package with no
/// `LICENSE`). Matches the published sibling Tom packages (`tom_build_base`).
const String licenseText = '''
BSD 3-Clause License

Copyright (c) 2024-2026, Peter Nicolai Alexis Kyaw
Find me on LinkedIn under Alexis Kyaw
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

/// One runnable sample in the facade package's hand-written examples tree,
/// rendered as a row of the README's Examples table
/// (`tom_specs_documentation_standard.md` §2.1 row 9).
class PackagingExample {
  /// Declares one sample row of the README's Examples table.
  const PackagingExample({required this.file, required this.demonstrates});

  /// The sample's path relative to the examples directory (e.g.
  /// `'a_typed_access.dart'`). `packaging_test.dart` asserts it exists, so a
  /// renamed sample fails a test rather than emitting a dead link.
  final String file;

  /// What the sample shows — the table's second column.
  final String demonstrates;
}

/// One `## Usage` sub-section: a capability, one sentence of context, and a
/// short runnable block (`tom_specs_documentation_standard.md` §2.1 row 10).
///
/// Per-language because the code is per-language; every snippet here is lifted
/// from the package's own examples tree, which its test suite compiles and
/// runs, so the README cannot show code that does not work.
class PackagingUsage {
  /// Declares one `## Usage` sub-section.
  ///
  /// All three parts are required because a snippet without its heading and
  /// intro is a code block a reader has to reverse-engineer the purpose of.
  const PackagingUsage({
    required this.heading,
    required this.intro,
    required this.snippet,
  });

  /// The sub-section heading (e.g. `'The generic store underneath'`).
  final String heading;

  /// One or two sentences placing the snippet.
  final String intro;

  /// The runnable block, rendered in the descriptor's [PackagingDescriptor.codeFence].
  final String snippet;
}

/// One `@Document` root of the generated facade, read back from the meta-data
/// file the emitter has just written.
class FacadeDocumentRoot {
  /// Records one root as read back from the emitted meta-data.
  ///
  /// Constructed only by `readFacadeSurface`, never hand-written: these are
  /// model facts, and hand-writing one would reintroduce the drift that
  /// reading the meta-data exists to prevent.
  const FacadeDocumentRoot({
    required this.type,
    required this.sectionId,
    required this.title,
  });

  /// The generated root type's name (`D00SolutionBlueprint`). Identical in all
  /// nine languages — the emitters transliterate members, not type names.
  final String type;

  /// The root's section id, the first segment of every path beneath it.
  final String sectionId;

  /// The document's human title.
  final String title;
}

/// The generated surface a facade README reports: its document roots and its
/// class count.
///
/// **Read from the emitted `meta/spec_model.meta.json` (SOM §5.3), never
/// carried on a descriptor.** These are *model* facts, not per-language ones —
/// nine hand-kept copies would be nine things to keep current, and drift would
/// show up as a README quietly describing a model the package no longer
/// implements. The meta-data file is the same thing every runtime already
/// loads, so reading it here is reading the package's own answer.
class FacadeSurface {
  /// Records the surface read back from one emitted facade.
  const FacadeSurface({required this.roots, required this.classCount});

  /// Every `@Document` root the facade generates, in model order.
  final List<FacadeDocumentRoot> roots;

  /// The number of generated classes across all roots.
  final int classCount;
}

/// Reads the [FacadeSurface] from the `meta/spec_model.meta.json` under
/// [outputRoot].
///
/// Throws [StateError] when the file is absent or malformed. That is
/// deliberate: [writeFacadePackaging] runs *after* the language emitter has
/// written the meta-data file, so a missing one means the emit order broke —
/// and a README silently missing its document-roots table would hide that.
FacadeSurface readFacadeSurface(String outputRoot) {
  final metaFile = File(p.join(outputRoot, 'meta', 'spec_model.meta.json'));
  if (!metaFile.existsSync()) {
    throw StateError(
        'facade meta-data not found: ${metaFile.path} — the packaging hook '
        'runs after the language emitter, so this file must already exist.');
  }
  final Object? decoded = jsonDecode(metaFile.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('facade meta-data is not a JSON object: ${metaFile.path}');
  }
  final rawRoots = decoded['roots'];
  if (rawRoots is! List) {
    throw StateError('facade meta-data has no `roots` list: ${metaFile.path}');
  }
  final roots = <FacadeDocumentRoot>[
    for (final raw in rawRoots)
      if (raw is Map<String, dynamic>)
        FacadeDocumentRoot(
          type: (raw['type'] as String?) ?? '',
          sectionId: (raw['sectionId'] as String?) ?? '',
          title: (raw['title'] as String?) ?? '',
        ),
  ];
  return FacadeSurface(
    roots: roots,
    classCount: (decoded['classCount'] as num?)?.toInt() ?? 0,
  );
}

/// Substitutes the descriptor bodies' `VERSION` placeholder with the real
/// [version].
///
/// The route bodies are authored with a literal `VERSION` so one descriptor
/// serves every model version; every emitted document must show the constraint
/// a reader can actually paste
/// (`tom_specs_documentation_standard.md` §8, "Installation shows a real
/// version constraint"). `packaging_test.dart` asserts no emitted document
/// still carries the placeholder.
String _withVersion(String body, String version) =>
    body.replaceAll('VERSION', version);

/// The facade `README.md` — the `tom_specs_documentation_standard.md` §2
/// template, emitted rather than hand-written.
///
/// The whole file is regenerated on every `generate_som.dart` run, so anything
/// a reader needs must come from either the shared template here or the
/// language's [PackagingDescriptor]; there is no third place, and a hand edit
/// is destroyed by the next run. Per-language nuance is a descriptor field, not
/// a branch on [PackagingDescriptor.language]
/// (`tom_specs_documentation_standard.md` §4.2).
String renderFacadeReadme(
  PackagingDescriptor d, {
  required String version,
  required FacadeSurface surface,
}) {
  const doc = '../tom_specs_model/doc';
  final runtime = '../${d.runtimePackageName}';
  final b = StringBuffer()
    ..writeln('# ${d.facadePackageName} — typed TomSpecs object model for '
        '${d.displayName}')
    ..writeln()
    ..writeln(_generatedBanner)
    ..writeln()
    // §2.2. Every `§` here is the `SOM §N` short form, which carries its own
    // document name, so no citation depends on a qualifier surviving a line
    // break across the `>` marker.
    ..writeln('> **Cross-references.**')
    ..writeln('> [`tom_specs_model/doc/som_multiplatform_spec_model.md`]'
        '($doc/som_multiplatform_spec_model.md)')
    ..writeln('> is the SOM authority: `SOM §6` decides the split between this')
    ..writeln('> typed access path and the generic one, `SOM §8` decides what')
    ..writeln('> this generated surface contains, `SOM §4.2` decides the model')
    ..writeln('> version stamp and the editing rules it enforces, and')
    ..writeln('> `SOM §17` decides how the package is built and published.')
    ..writeln('> [`tom_specs_model/doc/index.md`]($doc/index.md) catalogues '
        'every')
    ..writeln('> TomSpecs subject-matter document and owns the `§` citation')
    ..writeln('> convention. This README says how to **use this package\'s '
        'code**;')
    ..writeln('> those documents own the model, the formats and the rules, and')
    ..writeln('> nothing here restates them.')
    ..writeln()
    ..writeln(d.manifestDescription)
    ..writeln()
    // §2.3.
    ..writeln('## Where this fits')
    ..writeln()
    ..writeln('`${d.facadePackageName}` is the **generated typed face** of the '
        'TomSpecs object model for ${d.displayName}: one type per document '
        'section, so a specification is read and written through named members '
        'rather than through string paths. It exists because a string path is '
        'checked only at run time — a mistyped one reads as an absent value '
        'instead of an error — and a specification is exactly the kind of '
        'document where that failure is silent and expensive. It is one half '
        'of a pair: the hand-written [`${d.runtimePackageName}`]($runtime) '
        'holds everything identical in every language (the sparse document '
        'store, the codecs, the validator) and this half holds only what '
        'changes when the model changes, so a regeneration rewrites the typed '
        'types and touches nothing else. The same pair exists for all nine SOM '
        'languages, generated from one model, so a document written through '
        'any of them reads identically through the other eight. '
        '${d.whereThisFitsSentence}')
    ..writeln()
    // §2.1 row 5.
    ..writeln('## Overview')
    ..writeln()
    ..writeln('A TomSpecs document is **sparse and path-keyed**: a value lives '
        'under the globally-unique section-id path it belongs to, and an '
        'absent key means "no value" rather than an empty one. This package '
        'holds none of those values — `SpecDocument`, in the runtime, does. '
        'What it holds is a typed **view**: each generated type wraps a '
        'document together with the path prefix it is rooted at, and its '
        'members resolve to the paths beneath that prefix. Constructing a '
        'document root also runs the model-version check (`SOM §4.2`), so a '
        'document stamped by a different model version is refused rather than '
        'silently misread.')
    ..writeln()
    ..writeln('Everything generated here is derived from the `tom_specs_model` '
        'Dart model and rewritten wholesale on every run of '
        '`tom_specs_clitool/bin/generate_som.dart`. Beside the typed types the '
        'package ships the lossless meta-data file '
        '(`meta/spec_model.meta.json`, `SOM §5.3`), the generated DocSpecs '
        'schemas (`schemas/`, `SOM §13`), and the metadata trees that drive '
        'the dot-notation and id-tree access surfaces (`SOM §8`). The '
        'hand-written trees beside them — `${d.exampleDirName}/`, the tests, '
        '`doc/` — are preserved across regeneration; the generator writes '
        'files, it never wipes the output root.')
    ..writeln()
    // §2.1 row 6.
    ..writeln('## Installation')
    ..writeln();
  if (d.integrateRoutes.isNotEmpty) {
    b
      ..writeln(_withVersion(d.integrateRoutes.first.body.trimRight(), version))
      ..writeln();
  }
  b
    ..writeln('`${d.facadePackageName}` and `${d.runtimePackageName}` both '
        'carry version `$version`, taken from the TomSpecs model version — '
        'pin them together. Every other dependency route (git, path, vendored, '
        'build-from-source) is in '
        '[readme_howtointegrate.md](readme_howtointegrate.md).')
    ..writeln()
    // §2.1 row 7.
    ..writeln('## Features')
    ..writeln()
    ..writeln('### Document roots')
    ..writeln()
    ..writeln('Each root is a whole TomSpecs document, and the first segment '
        'of every path beneath it is its section id. Construct the root you '
        'need over a `SpecDocument`; the ${surface.classCount} generated types '
        'are reached through it.')
    ..writeln()
    ..writeln('| Section id | Document | Generated root type |')
    ..writeln('| ---------- | -------- | ------------------- |');
  for (final root in surface.roots) {
    b.writeln('| `${root.sectionId}` | ${root.title} | `${root.type}` |');
  }
  b
    ..writeln()
    // §2.1 row 8.
    ..writeln('## Quick start')
    ..writeln()
    ..writeln(_withVersion(d.installShort, version))
    ..writeln()
    ..writeln('```${d.codeFence}')
    ..writeln(d.usageSnippet.trimRight())
    ..writeln('```')
    ..writeln()
    ..writeln('Prints `A platform that unifies our fragmented order systems.` '
        '— the value just written, read back through the typed getter.')
    ..writeln();
  // §2.1 row 9.
  if (d.examples.isNotEmpty) {
    b
      ..writeln('## Examples')
      ..writeln()
      ..writeln('| Sample | Demonstrates |')
      ..writeln('| ------ | ------------ |');
    for (final example in d.examples) {
      b.writeln('| [`${example.file}`](${d.exampleDirName}/${example.file}) '
          '| ${example.demonstrates} |');
    }
    b
      ..writeln()
      ..writeln('[`${d.exampleDirName}/README.md`]'
          '(${d.exampleDirName}/README.md) gives the run command for each.')
      ..writeln();
  }
  // §2.1 row 10.
  b
    ..writeln('## Usage')
    ..writeln();
  for (final usage in d.usageSections) {
    b
      ..writeln('### ${usage.heading}')
      ..writeln()
      ..writeln(usage.intro)
      ..writeln()
      ..writeln('```${d.codeFence}')
      ..writeln(usage.snippet.trimRight())
      ..writeln('```')
      ..writeln();
  }
  b
    ..writeln('### Regenerating')
    ..writeln()
    ..writeln('This package is output. When the model changes, regenerate it '
        'rather than editing it — every file carrying the '
        '`GENERATED … do not edit by hand` banner is overwritten:')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart run tom_specs_clitool/bin/generate_som.dart')
    ..writeln('```')
    ..writeln()
    // §2.1 row 11.
    ..writeln('## Architecture')
    ..writeln()
    ..writeln('```')
    ..writeln('  ${d.facadePackageName}          the typed path — this package')
    ..writeln('    D00SolutionBlueprint …        one type per document root')
    ..writeln('            │  extends')
    ..writeln('            ▼')
    ..writeln('     SomNode / SomScalar / SomList     editing-facade bases')
    ..writeln('            │  bound to')
    ..writeln('            ▼')
    ..writeln('      SpecDocument                sparse, path-keyed value store')
    ..writeln('            │                     (${d.runtimePackageName})')
    ..writeln('            ▼')
    ..writeln('  SpecReflection · SpecValidator · YAML + Markdown codecs')
    ..writeln('            ▲')
    ..writeln('            │  described by')
    ..writeln('      SomMetaTree  ◀── meta/spec_model.meta.json')
    ..writeln('```')
    ..writeln()
    ..writeln('| Type | Responsibility |')
    ..writeln('| ---- | -------------- |')
    ..writeln('| `D00SolutionBlueprint` … | The generated document roots — one '
        'per row of the table above, each the typed entry point to a whole '
        'document. |')
    ..writeln('| `SomNode` | The base every generated section type extends: a '
        'document plus the path prefix this section is rooted at. |')
    ..writeln('| `SomScalar` | A typed leaf — parse and format at the store '
        'boundary, so `int` / `bool` / enum members read as themselves. |')
    ..writeln('| `SomList` | A typed repeated section — append, index and '
        'enumerate items whose paths the store generates. |')
    ..writeln('| `SomMetaTree` / `SomMetaNode` | The generated metadata trees '
        '(`SOM §7`): the model\'s shape as data, behind the dot-notation and '
        'id-tree access surfaces. |')
    ..writeln('| `SomEditability` | The `SOM §4.2` version-check outcome — '
        'whether a stamped document may be edited by this facade. |')
    ..writeln('| `SpecDocument` | The value store itself. Lives in '
        '`${d.runtimePackageName}`; every type above is a view onto it. |')
    ..writeln()
    // §2.1 row 12.
    ..writeln('## Ecosystem')
    ..writeln()
    ..writeln('```')
    ..writeln('  tom_specs_model          the Dart model — the source of truth')
    ..writeln('         │')
    ..writeln('         ▼  generate_som')
    ..writeln('  tom_specs_clitool        the generator')
    ..writeln('         │')
    ..writeln('         ▼  emits')
    ..writeln('  ${d.facadePackageName}   ← this package (typed)')
    ..writeln('         │')
    ..writeln('         ▼  depends on')
    ..writeln('  ${d.runtimePackageName}  (generic, hand-written)')
    ..writeln('         │')
    ..writeln('         ▼  validated against')
    ..writeln('  tom_som_conformance      the shared cross-language corpus')
    ..writeln('```')
    ..writeln()
    ..writeln('The same shape repeats for all nine languages; the corpus at '
        'the bottom is shared, which is what makes "identical in every '
        'language" a measured claim rather than an intention (`SOM §19`).')
    ..writeln()
    // §2.4.
    ..writeln('## Further documentation')
    ..writeln()
    ..writeln('**TomSpecs subject matter** — the authorities this package '
        'implements:')
    ..writeln()
    ..writeln('| Document | Authority for |')
    ..writeln('|----------|---------------|')
    ..writeln('| [index.md]($doc/index.md) | The catalogue of every TomSpecs '
        'subject-matter document, and the `§` citation convention. |')
    ..writeln('| [som_multiplatform_spec_model.md]'
        '($doc/som_multiplatform_spec_model.md) | The two access paths, what '
        'this generated surface contains, the version stamp and editing '
        'rules, the `*.md` and `*.docspecs.yaml` formats, and the conformance '
        'corpus. |')
    ..writeln('| [som_toolchains.md]($doc/som_toolchains.md) | This language '
        'plane\'s build and verify toolchain, and the reference host. |')
    ..writeln('| [tom_specs_model_meta_schema.md]'
        '($doc/tom_specs_model_meta_schema.md) | The on-disk schema of '
        '`meta/spec_model.meta.json`. |')
    ..writeln()
    ..writeln('**This package** — its own guides:')
    ..writeln()
    ..writeln('| Guide | Covers |')
    ..writeln('|-------|--------|')
    ..writeln('| [doc/tutorial.md](doc/tutorial.md) | ${d.tutorialSentence} |')
    ..writeln('| [readme_howtointegrate.md](readme_howtointegrate.md) | Every '
        'dependency route, how to pin the version, and building from '
        'source. |')
    ..writeln('| [${d.exampleDirName}/README.md](${d.exampleDirName}/README.md)'
        ' | The runnable samples and how to run each. |')
    ..writeln()
    ..writeln('**Siblings** — packages you will reach for next:')
    ..writeln()
    ..writeln('| Package | What it is |')
    ..writeln('|---------|-----------|')
    ..writeln('| [${d.runtimePackageName}]($runtime) | The generic runtime '
        'this facade is a view over — reach for it directly to drive a '
        'document by path. |')
    ..writeln('| [tom_som_conformance](../tom_som_conformance) | The shared '
        'corpus and the cross-language drivers that run every port against '
        'it. |')
    ..writeln('| [tom_specs_clitool](../tom_specs_clitool) | The generator '
        'that writes this package. |')
    ..writeln()
    // §2.5.
    ..writeln('## Status')
    ..writeln()
    ..writeln('Version **$version**, tracking the TomSpecs model version and '
        'matching `${d.runtimePackageName}`. Generated surface: '
        '${surface.roots.length} document roots, ${surface.classCount} types. '
        'Verify the package with:')
    ..writeln()
    ..writeln('```bash')
    ..writeln(d.verifyCommand.trimRight())
    ..writeln('```')
    ..writeln()
    ..writeln('A generated README states no fixed test count: the count moves '
        'with the model, and a number this file could not update would go '
        'stale the first time the model did. The command above is the '
        'standing answer — it runs this package against the shared '
        'cross-language corpus (`SOM §19`).');
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
    ..writeln(_withVersion(d.installShort, version))
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
      ..writeln(_withVersion(route.body.trimRight(), version))
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
    ..writeln(_withVersion(d.buildFromSource.trimRight(), version))
    ..writeln()
    ..writeln('## Further documentation')
    ..writeln()
    ..writeln('| Document | Covers |')
    ..writeln('|----------|--------|')
    ..writeln('| [README.md](README.md) | What this package is, its document '
        'roots, and how to use them. |')
    ..writeln('| [doc/tutorial.md](doc/tutorial.md) | ${d.tutorialSentence} |')
    ..writeln('| [${d.exampleDirName}/README.md]'
        '(${d.exampleDirName}/README.md) | The runnable samples. |')
    ..writeln('| [tom_specs_model/doc/som_multiplatform_spec_model.md]'
        '(../tom_specs_model/doc/som_multiplatform_spec_model.md) | The SOM '
        'authority: the model, the formats, and `SOM §17` — the packaging '
        'rules this guide implements. |')
    ..writeln('| [tom_specs_model/doc/index.md]'
        '(../tom_specs_model/doc/index.md) | The catalogue of every TomSpecs '
        'subject-matter document. |')
    ..writeln('| [${d.runtimePackageName}](../${d.runtimePackageName}) | The '
        'generic runtime this facade depends on. |');
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
  File(p.join(outputRoot, 'README.md')).writeAsStringSync(renderFacadeReadme(
    descriptor,
    version: version,
    surface: readFacadeSurface(outputRoot),
  ));
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
/// A language's [PackagingDescriptor] entry here immediately activates
/// [writeFacadePackaging] + [alignRuntimeManifestVersion] for that language on
/// the next `generate_som.dart` run. All nine ecosystems of the SOM §17.3 table
/// are registered: Dart (pub); Python (PEP 517); Java (Maven); JavaScript
/// (npm); TypeScript (npm + compiled `dist/`); Go (module path + in-source
/// version constant / VCS tag scheme); Rust (Cargo crate — versioned `path`
/// dependency + crate metadata); C and C++ (Makefile — static + shared library,
/// pkg-config `.pc`, `make install` / `make dist`).
const Map<SomLanguage, PackagingDescriptor> _packagingDescriptors = {
  SomLanguage.dart: _dartDescriptor,
  SomLanguage.python: _pythonDescriptor,
  SomLanguage.java: _javaDescriptor,
  SomLanguage.javascript: _javaScriptDescriptor,
  SomLanguage.typescript: _typeScriptDescriptor,
  SomLanguage.go: _goDescriptor,
  SomLanguage.rust: _rustDescriptor,
  SomLanguage.c: _cDescriptor,
  SomLanguage.cpp: _cppDescriptor,
};

/// Dart (pub) packaging descriptor. The facade `tom_som_dart_v0` and the
/// runtime `tom_som_dart_runtime` are both publishable pub packages versioned
/// to the TomSpecs model version.
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
          '      path: tom_som_dart_v0\n'
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
  manifestDescription: 'Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_dart_runtime; see the meta-data file and DocSpecs schemas in this package. Regenerate with tom_specs_clitool/bin/generate_som.dart.',
  manifestDescriptionFile: 'pubspec.yaml',
  whereThisFitsSentence: 'Dart is the reference plane: the model, the generator and the conformance goldens are all authored here, and the other eight languages are transcribed from it.',
  tutorialSentence: 'A Dart walkthrough end to end — add the dependency, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'example',
  examples: [
    PackagingExample(
      file: 'a_typed_access.dart',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.dart',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.dart',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
    PackagingExample(
      file: 'd_sample_typed_access.dart',
      demonstrates: 'The shared cross-language sample document read through typed getters.',
    ),
    PackagingExample(
      file: 'e_sample_generic_access.dart',
      demonstrates: 'The same sample read through raw string paths — identical output to (d).',
    ),
    PackagingExample(
      file: 'f_sample_hybrid_access.dart',
      demonstrates: 'Typed and generic access mixed over a single document.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

final doc = SpecDocument();
doc.setContent(
    'SBP/content', 'A platform that unifies our fragmented order systems.');

// A repeated section: append an item, then fill a content leaf under it.
final item = doc.addListItem('SBP/currentLandscape/CUOPME-OPER-LST');
doc.setContent('\$item/content', 'Average order turnaround: 4.2 days.');

// The whole document serializes to the canonical wire format.
print(SpecDocumentYaml.encode(
    document: doc,
    tree: d00SolutionBlueprintMetaTree,
    modelVersion: '1.0'));
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

final model = SpecModel.fromJson(
    jsonDecode(File('meta/spec_model.meta.json').readAsStringSync())
        as Map<String, dynamic>);
final reflection = SpecReflection(model);

for (final root in reflection.roots) {
  print('\${reflection.rootSegment(root)}  \${root.title}');
}

final res = reflection.resolve('SBP/currentLandscape/content')!;
print('kind=\${res.kind.name}  valueLeaf=\${res.isValueLeaf}');
''',
    ),
  ],
  verifyCommand: '''
dart pub get
dart analyze
./run_tests.sh   # dart test + the three samples''',
);

/// Python (PEP 517) packaging descriptor. The facade `tom_som_python_v0` and
/// the runtime `tom_som_python_runtime` are both PEP 517 source distributions
/// (`python -m build` → wheel + sdist) versioned to the TomSpecs model version.
/// The facade is a single top-level module (`py-modules`); the runtime ships
/// the importable `tom_som_runtime` package.
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
          '#subdirectory=tom_som_python_v0"\n'
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
    PackagingRoute(
      heading: 'Shipped data files (meta-data + DocSpecs schemas)',
      body: 'The distribution carries the lossless object-model meta-data '
          '(`spec_model.meta.json`) and the DocSpecs schemas as data '
          'packages inside the wheel. Resolve them through the generated '
          'resolution module — it works both from a source checkout and from '
          'an installed wheel:\n\n'
          '```python\n'
          'from tom_som_python_v0_data import spec_model_meta_path, '
          'schemas_root\n'
          '\n'
          'meta_file = spec_model_meta_path()  # …/spec_model.meta.json\n'
          'schema_dir = schemas_root()         # one subfolder per document '
          'root\n'
          '```',
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
  manifestDescription: 'Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_python_runtime; see the meta-data file and DocSpecs schemas in this package. Regenerate with tom_specs_clitool/bin/generate_som.dart.',
  manifestDescriptionFile: 'pyproject.toml',
  whereThisFitsSentence: 'The facade is a single top-level module and the runtime ships the importable `tom_som_runtime` package, so both resolve from a plain `pip install` with no build step.',
  tutorialSentence: 'A Python walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access.py',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.py',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.py',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
from tom_som_runtime import SpecDocument, yaml_encode
from tom_som_python_v0_meta import d00SolutionBlueprintMetaTree

doc = SpecDocument()
doc.set_content(
    "SBP/content", "A platform that unifies our fragmented order systems."
)

# A repeated section: append an item, then fill a content leaf under it.
item = doc.add_list_item("SBP/currentLandscape/CUOPME-OPER-LST")
doc.set_content(f"{item}/content", "Average order turnaround: 4.2 days.")

# The whole document serializes to the canonical wire format.
print(yaml_encode(doc, d00SolutionBlueprintMetaTree, model_version="1.0"))
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
import json

from tom_som_runtime import SpecModel, SpecReflection
from tom_som_python_v0_data import spec_model_meta_path

with open(spec_model_meta_path(), encoding="utf-8") as fh:
    model = SpecModel.from_json(json.load(fh))
reflection = SpecReflection(model)

for root in reflection.roots:
    print(reflection.root_segment(root), root.title)

res = reflection.resolve("SBP/currentLandscape/content")
print(f"kind={res.kind.value}  value_leaf={res.is_value_leaf}")
''',
    ),
  ],
  verifyCommand: '''
pip install -e ../tom_som_python_runtime -e .
./run_tests.sh   # the per-module suites + the three samples''',
);

/// Java (Maven) packaging descriptor. The facade `tom_som_java_v0` and the
/// runtime `tom_som_java_runtime` are both Maven `jar` artifacts versioned to
/// the TomSpecs model version. The build host here carries only the JDK (no
/// Maven), so each project also ships a `build_jar.sh` fallback that compiles
/// with `javac` and packages with `jar` — producing the same artifact `mvn
/// package` would.
const PackagingDescriptor _javaDescriptor = PackagingDescriptor(
  language: SomLanguage.java,
  displayName: 'Java',
  runtimePackageName: 'tom_som_java_runtime',
  facadePackageName: 'tom_som_java_v0',
  codeFence: 'java',
  installShort: 'Add `tom_som_java_v0` (group `io.github.al-the-bear`) to your '
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
          '  <groupId>io.github.al-the-bear</groupId>\n'
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
  manifestDescription: 'Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_java_runtime. Regenerate with tom_specs_clitool/bin/generate_som.dart.',
  manifestDescriptionFile: 'pom.xml',
  whereThisFitsSentence: 'Both halves are plain Maven `jar` artifacts with no third-party dependencies, so a JDK alone builds and runs them — `build_jar.sh` produces the same artifact `mvn package` would.',
  tutorialSentence: 'A Java walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'ATypedAccess.java',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'BGenericDocument.java',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'CReflectionMetadata.java',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_java_v0.TomSomV0Meta;

SpecDocument doc = new SpecDocument();
doc.setContent("SBP/content",
    "A platform that unifies our fragmented order systems.");

// A repeated section: append an item, then fill a content leaf under it.
String item = doc.addListItem("SBP/currentLandscape/CUOPME-OPER-LST");
doc.setContent(item + "/content", "Average order turnaround: 4.2 days.");

// The whole document serializes to the canonical wire format.
System.out.println(SpecDocumentYaml.encode(
    doc, TomSomV0Meta.D00SolutionBlueprintMetaTree, "1.0"));
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
import java.nio.file.Files;
import java.nio.file.Path;

import tom_som_runtime.Json;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;

SpecModel model = SpecModel.fromJson(
    Json.parseObject(Files.readString(Path.of("meta/spec_model.meta.json"))));
SpecReflection reflection = new SpecReflection(model);

for (SpecRoot root : reflection.roots()) {
  System.out.println(reflection.rootSegment(root) + "  " + root.title);
}

SpecResolution res = reflection.resolve("SBP/currentLandscape/content");
System.out.println("kind=" + res.kind.value + "  valueLeaf=" + res.isValueLeaf());
''',
    ),
  ],
  verifyCommand: '''
./build_jar.sh
./run_tests.sh   # the per-module suites + the three samples''',
);

/// JavaScript (npm) packaging descriptor. The facade `tom_som_javascript_v0`
/// and the runtime `tom_som_javascript_runtime` are both npm packages versioned
/// to the TomSpecs model version. The facade is a single CommonJS module plus
/// its `meta/` + `schemas/` payload; the runtime ships the importable
/// `tom_som_runtime/` package. Both are `private` (proprietary), so `npm pack`
/// is the packaging check rather than `npm publish`.
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
      body: 'npm cannot install a sub-directory of a git repository directly, '
          'and the facade lives in a sub-directory of the mono-repo — so '
          'clone first, then install by path (runtime first):\n\n'
          '```bash\n'
          'git clone https://github.com/al-the-bear/tom_ai_build.git\n'
          'npm install ./tom_ai_build/tom_som_javascript_runtime\n'
          'npm install ./tom_ai_build/tom_som_javascript_v0\n'
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
  manifestDescription: 'Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_javascript_runtime; see the meta-data file and DocSpecs schemas in this package. Regenerate with tom_specs_clitool/bin/generate_som.dart.',
  manifestDescriptionFile: 'package.json',
  whereThisFitsSentence: 'Plain CommonJS with no build step and no runtime dependencies — `require` the package and the typed roots are there.',
  tutorialSentence: 'A JavaScript walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access.js',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.js',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.js',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
const m = require('tom_som_javascript_v0');
const { SpecDocument, yamlEncode } = require('tom_som_javascript_runtime');

const doc = new SpecDocument();
doc.setContent(
  'SBP/content', 'A platform that unifies our fragmented order systems.');

// A repeated section: append an item, then fill a content leaf under it.
const item = doc.addListItem('SBP/currentLandscape/CUOPME-OPER-LST');
doc.setContent(`\${item}/content`, 'Average order turnaround: 4.2 days.');

// The whole document serializes to the canonical wire format.
console.log(yamlEncode(doc, m.d00SolutionBlueprintMetaTree, '1.0'));
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
const fs = require('fs');
const { SpecModel, SpecReflection } =
  require('tom_som_javascript_runtime');

const model = SpecModel.fromJson(
  JSON.parse(fs.readFileSync('meta/spec_model.meta.json', 'utf8')));
const reflection = new SpecReflection(model);

for (const root of reflection.roots) {
  console.log(reflection.rootSegment(root), root.title);
}

const res = reflection.resolve('SBP/currentLandscape/content');
console.log(`kind=\${res.kind}  valueLeaf=\${res.isValueLeaf}`);
''',
    ),
  ],
  verifyCommand: '''
npm install
./run_tests.sh   # the per-module suites + the three samples''',
);

/// TypeScript (npm + compiled `dist/`) packaging descriptor. The facade
/// `tom_som_typescript_v0` and the runtime `tom_som_typescript_runtime` are
/// both npm packages that ship **compiled `dist/`** (`.js` + `.d.ts`) built by
/// a `prepack` step (`tsc`), versioned to the TomSpecs model version. The
/// facade imports the runtime by bare specifier wired through a relative
/// `file:` dependency, so its `prepack` builds the runtime first, then the
/// facade. Both are `private` (proprietary), so `npm pack` is the packaging
/// check rather than `npm publish`.
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
      body: 'npm cannot install a sub-directory of a git repository directly, '
          'and the facade lives in a sub-directory of the mono-repo — so '
          'clone first, then install by path (runtime first; the facade '
          "compiles against the runtime's `dist/`):\n\n"
          '```bash\n'
          'git clone https://github.com/al-the-bear/tom_ai_build.git\n'
          'npm install ./tom_ai_build/tom_som_typescript_runtime\n'
          'npm install ./tom_ai_build/tom_som_typescript_v0\n'
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
  manifestDescription: 'Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_typescript_runtime; see the meta-data file and DocSpecs schemas in this package. Regenerate with tom_specs_clitool/bin/generate_som.dart.',
  manifestDescriptionFile: 'package.json',
  whereThisFitsSentence: 'The package ships TypeScript sources and compiles to `dist/`, so consumers get the declaration files and the section types are checked by `tsc` rather than at run time.',
  tutorialSentence: 'A TypeScript walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access.ts',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.ts',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.ts',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
import { SpecDocument, yamlEncode } from 'tom_som_typescript_runtime';
import { d00SolutionBlueprintMetaTree } from 'tom_som_typescript_v0';

const doc = new SpecDocument();
doc.setContent(
  'SBP/content', 'A platform that unifies our fragmented order systems.');

// A repeated section: append an item, then fill a content leaf under it.
const item = doc.addListItem('SBP/currentLandscape/CUOPME-OPER-LST');
doc.setContent(`\${item}/content`, 'Average order turnaround: 4.2 days.');

// The whole document serializes to the canonical wire format.
console.log(yamlEncode(doc, d00SolutionBlueprintMetaTree, '1.0'));
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
import * as fs from 'fs';
import { SpecModel, SpecReflection } from 'tom_som_typescript_runtime';

const model = SpecModel.fromJson(
  JSON.parse(fs.readFileSync('meta/spec_model.meta.json', 'utf8')));
const reflection = new SpecReflection(model);

for (const root of reflection.roots) {
  console.log(reflection.rootSegment(root), root.title);
}

const res = reflection.resolve('SBP/currentLandscape/content');
console.log(`kind=\${res.kind}  valueLeaf=\${res.isValueLeaf}`);
''',
    ),
  ],
  verifyCommand: '''
npm install
npm run build
./run_tests.sh   # the compiled suites + the three samples''',
);

/// Go (module + VCS tag) packaging descriptor. The facade `tom_som_go_v0` and
/// the runtime `tom_som_go_runtime` are Go modules with **domain-qualified
/// module paths** (`github.com/al-the-bear/tom_ai_build/tom_som_go_<v>`), so
/// `go get` can resolve them. Go has no registry: distribution is by VCS tag,
/// so each module also carries an **in-source `Version` constant** (`Version =
/// "vX.Y.Z"`) set to the TomSpecs model version, and the documented tag scheme
/// is the matching `vMAJOR.MINOR.PATCH` tag. The runtime's version constant
/// lives in its hand-authored `doc.go`, realigned by
/// [alignRuntimeManifestVersion]. Locally the facade resolves the runtime
/// through a relative `replace` directive; a real `go get` uses the required
/// module path + tag (dependency `replace` directives are ignored, so the
/// `require` names the real remote path).
const PackagingDescriptor _goDescriptor = PackagingDescriptor(
  language: SomLanguage.go,
  displayName: 'Go',
  runtimePackageName: 'tom_som_go_runtime',
  facadePackageName: 'tom_som_go_v0',
  codeFence: 'go',
  installShort: 'Add `tom_som_go_v0` to your module '
      '(`go get github.com/al-the-bear/tom_ai_build/tom_som_go_v0@vVERSION`), '
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
  manifestDescription: 'Typed object-model facade over the generic `tom_som_go_runtime` document.',
  manifestDescriptionFile: 'tom_som_go_v0.go',
  whereThisFitsSentence: 'Go versions live in VCS tags rather than a manifest, so each module also carries an in-source `Version` constant, and the generator writes a `require` plus a local `replace` so the module builds both standalone and in-repo.',
  tutorialSentence: 'A Go walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
import (
	"fmt"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

doc := som.NewSpecDocument()
doc.SetContent("SBP/content",
	"A platform that unifies our fragmented order systems.")

// A repeated section: append an item, then fill a content leaf under it.
item := doc.AddListItem("SBP/currentLandscape/CUOPME-OPER-LST")
doc.SetContent(item+"/content", "Average order turnaround: 4.2 days.")

// The whole document serializes to the canonical wire format.
yaml, err := som.EncodeYaml(doc, somv0.D00SolutionBlueprintMetaTree, "1.0")
if err != nil {
	panic(err)
}
fmt.Print(yaml)
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
data, err := os.ReadFile("meta/spec_model.meta.json")
if err != nil {
	panic(err)
}
model, err := som.SpecModelFromJSON(data)
if err != nil {
	panic(err)
}
reflection := som.NewSpecReflection(model)

for _, root := range reflection.Roots() {
	fmt.Println(reflection.RootSegment(root), root.Title)
}

res := reflection.Resolve("SBP/currentLandscape/content")
fmt.Printf("kind=%s  valueLeaf=%v\n", res.Kind, res.IsValueLeaf())
''',
    ),
  ],
  verifyCommand: '''
go build ./...
go vet ./...
./run_tests.sh   # go test + the three samples''',
);

/// Rust (Cargo crate) packaging descriptor. The facade `tom_som_rust_v0` and
/// the runtime `tom_som_rust_runtime` are Cargo crates versioned to the
/// TomSpecs model version. Both are `publish = false` (proprietary), so `cargo
/// package --no-verify` is the packaging check rather than `cargo publish`. The
/// facade resolves the runtime by a fixed crate name through a relative `path`
/// dependency; because `cargo package` requires every dependency to carry a
/// version, that dependency also pins `version = <model version>` (the `path`
/// is stripped from the packaged manifest, leaving the version).
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
  manifestDescription: 'Generated typed TomSpecs object-model facade (Rust).',
  manifestDescriptionFile: 'Cargo.toml',
  whereThisFitsSentence: 'The crate has no third-party dependencies — only the runtime crate — and because `cargo package` requires every dependency to carry a version, the `path` dependency on the runtime also pins the model version.',
  tutorialSentence: 'A Rust walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access.rs',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.rs',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.rs',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
    PackagingExample(
      file: 'golden_log.rs',
      demonstrates: 'The cross-language golden-log generator (`SOM §19`) — reads essentially every section both ways and asserts typed equals generic.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
use tom_som_rust_runtime as som;
use tom_som_rust_v0::meta;

let mut doc = som::SpecDocument::new();
doc.set_content(
    "SBP/content",
    "A platform that unifies our fragmented order systems.",
);

// A repeated section: append an item, then fill a content leaf under it.
let item = doc.add_list_item("SBP/currentLandscape/CUOPME-OPER-LST");
doc.set_content(&format!("{}/content", item), "Average order turnaround: 4.2 days.");

// The whole document serializes to the canonical wire format.
let tree = meta::d00_solution_blueprint_meta_tree();
print!("{}", som::encode_yaml(&doc, &tree, "1.0").expect("encode_yaml"));
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
use std::fs;

use tom_som_rust_runtime as som;

let data = fs::read_to_string("meta/spec_model.meta.json").expect("read meta");
let model = som::SpecModel::from_json_str(&data).expect("parse meta-data");
let reflection = som::SpecReflection::new(&model);

for root in reflection.roots() {
    println!("{}  {}", reflection.root_segment(root), root.title);
}

let res = reflection
    .resolve("SBP/currentLandscape/content")
    .expect("resolve");
println!("kind={}  value_leaf={}", res.kind, res.is_value_leaf());
''',
    ),
  ],
  verifyCommand: '''
cargo build
cargo test
./run_tests.sh   # cargo test + the three samples''',
);

/// C (Makefile + pkg-config) packaging descriptor. The facade `tom_som_c_v0`
/// and the runtime `tom_som_c_runtime` are built by a `Makefile` into a static
/// (`.a`) and a shared (`.so`) library. C has no package registry, so
/// distribution is by installed **library + headers + pkg-config file** or by
/// **source tarball** — both `Makefile`s emit a `tom_som_<name>.pc` (`Version`
/// = the model version; the facade's `Requires: tom_som_c_runtime`) and carry
/// `make install` / `make dist` targets. The runtime's own version lives in its
/// hand-authored `Makefile` `VERSION` variable, realigned by
/// [alignRuntimeManifestVersion]; the facade resolves the runtime through a
/// relative `RUNTIME_DIR` include/link path (built on demand), so the emitted
/// source stays path-free and golden-stable. `make && make dist` is the
/// packaging check for both.
const PackagingDescriptor _cDescriptor = PackagingDescriptor(
  language: SomLanguage.c,
  displayName: 'C',
  runtimePackageName: 'tom_som_c_runtime',
  facadePackageName: 'tom_som_c_v0',
  codeFence: 'c',
  installShort: 'Build and install `tom_som_c_v0` (and `tom_som_c_runtime`), '
      'then compile against it with `pkg-config`:',
  usageSnippet: '''
#include "tom_som_c_v0.h"

int main(void) {
  // A typed Solution Blueprint over a fresh document. The constructor also runs
  // the instantiation-time model-version check (an empty stamp is editable).
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint bp;
  d00_solution_blueprint_new(&bp, &doc, "", NULL);

  d00_solution_blueprint_set_content(
      &bp, "A platform that unifies our fragmented order systems.");

  CurrentLandscape cl = d00_solution_blueprint_current_landscape(&bp);
  current_landscape_set_content(
      &cl, "Three legacy systems with no shared customer record.");

  char *content = d00_solution_blueprint_content(&bp);
  printf("%s\\n", content);
  free(content);

  current_landscape_free(&cl);
  d00_solution_blueprint_free(&bp);
  spec_document_free(&doc);
  return 0;
}''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'pkg-config (installed)',
      body: 'C has no package registry. Install the facade and the runtime '
          '(runtime first — the facade links against it), then let `pkg-config` '
          'supply the compile and link flags:\n\n'
          '```bash\n'
          'make -C ../tom_som_c_runtime install\n'
          'make install\n'
          'cc myapp.c \$(pkg-config --cflags --libs tom_som_c_v0) -o myapp\n'
          '```\n\n'
          'The facade `.pc` declares `Requires: tom_som_c_runtime`, so a single '
          '`pkg-config tom_som_c_v0` pulls in the runtime flags too. Both '
          '`.pc` files report `Version VERSION`.',
    ),
    PackagingRoute(
      heading: 'Source tarball (vendored)',
      body: 'Produce versioned source tarballs and vendor them into your '
          'build:\n\n'
          '```bash\n'
          'make -C ../tom_som_c_runtime dist   # tom_som_c_runtime-VERSION.tar.gz\n'
          'make dist                           # tom_som_c_v0-VERSION.tar.gz\n'
          '```\n\n'
          'Unpack both alongside your project and add each `include/` to your '
          'include path plus the built libraries to your link line.',
    ),
    PackagingRoute(
      heading: 'In-tree (monorepo)',
      body: 'When the SOM projects sit alongside your code, build the facade in '
          "place; its `Makefile` builds the runtime on demand through a relative "
          '`RUNTIME_DIR`:\n\n'
          '```bash\n'
          'make                                # builds runtime + facade libs\n'
          'cc myapp.c -Iinclude -I../tom_som_c_runtime/include \\\n'
          '   build/libtom_som_c_v0.a ../tom_som_c_runtime/build/libtom_som_c_runtime.a \\\n'
          '   -o myapp\n'
          '```',
    ),
  ],
  buildFromSource: 'Regenerate the facade, then build and package both projects '
      'from the workspace (runtime first — the facade builds it on demand '
      'through its relative `RUNTIME_DIR`):\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_c_runtime && make && make dist\n'
      'cd ../tom_som_c_v0 && make && make dist\n'
      '```\n\n'
      'Each `make` builds the static + shared library and the pkg-config file; '
      'each `make dist` writes `build/<name>-<version>.tar.gz`.',
  buildArtifactIgnores: [
    'build/',
    '*.o',
    '*.a',
    '*.so',
    '*.so.*',
    '*.pc',
    '*.tar.gz',
  ],
  runtimeManifestFileName: 'Makefile',
  runtimeManifestFormat: ManifestFormat.makefileVar,
  manifestDescription: 'Generated typed TomSpecs object-model facade (C).',
  manifestDescriptionFile: 'Makefile',
  whereThisFitsSentence: 'There is no registry: both halves build to a static and a shared library with a pkg-config `.pc` file, so `make install` and `pkg-config --cflags --libs` are the integration surface.',
  tutorialSentence: 'A C walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access.c',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.c',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.c',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
#include "tom_som_c_runtime.h"
#include "tom_som_c_v0_meta.h"

SpecDocument doc;
spec_document_init(&doc);
spec_document_set_content(
    &doc, "SBP/content",
    "A platform that unifies our fragmented order systems.");

/* A repeated section: each append returns the new item's OWNED path. */
char *item = spec_document_add_list_item(
    &doc, "SBP/currentLandscape/CUOPME-OPER-LST");
char *leaf = spec_path_join(item, "content");
spec_document_set_content(&doc, leaf, "Average order turnaround: 4.2 days.");
free(leaf);
free(item);

/* encode_yaml also returns an owned buffer the caller frees. */
char *err = NULL;
char *yaml = encode_yaml(&doc, d00_solution_blueprint_meta_tree(), "1.0", &err);
printf("%s", yaml);
free(yaml);
spec_document_free(&doc);
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
#include "tom_som_c_runtime.h"

char *err = NULL;
SpecModel *model = spec_model_from_json_str(data, &err);
SpecReflection ref = spec_reflection_make(model);

/* The roots are model data; the reflection resolves paths against them. */
for (size_t i = 0; i < model->roots_len; i++) {
  const SpecRoot *root = &model->roots[i];
  printf("%s  %s\n", spec_reflection_root_segment(root), root->title);
}

SpecResolution res;
if (spec_reflection_resolve(&ref, "SBP/currentLandscape/content", &res)) {
  printf("kind=%s  value_leaf=%d\n", res.kind,
         spec_resolution_is_value_leaf(&res));
  spec_resolution_free(&res);
}
spec_model_free(model);
''',
    ),
  ],
  verifyCommand: '''
make -C ../tom_som_c_runtime
make
./run_tests.sh   # the behavioural suites + the three samples''',
);

/// C++ (Makefile + pkg-config) packaging descriptor. The facade
/// `tom_som_cpp_v0` and the runtime `tom_som_cpp_runtime` are built by a
/// `Makefile` into a static (`.a`) and a shared (`.so`) library. C++ has no
/// universal package registry, so distribution is by installed **library +
/// headers + pkg-config file** or by **source tarball** — both `Makefile`s emit
/// a `tom_som_<name>.pc` (`Version` = the model version; the facade's
/// `Requires: tom_som_cpp_runtime`) and carry `make install` / `make dist`
/// targets. The runtime's own version lives in its hand-authored `Makefile`
/// `VERSION` variable, realigned by [alignRuntimeManifestVersion]; the facade
/// resolves the runtime through a relative `RUNTIME_DIR` include/link path
/// (built on demand), so the emitted source stays path-free and golden-stable.
/// `make && make dist` is the packaging check for both.
const PackagingDescriptor _cppDescriptor = PackagingDescriptor(
  language: SomLanguage.cpp,
  displayName: 'C++',
  runtimePackageName: 'tom_som_cpp_runtime',
  facadePackageName: 'tom_som_cpp_v0',
  codeFence: 'cpp',
  installShort: 'Build and install `tom_som_cpp_v0` (and '
      '`tom_som_cpp_runtime`), then compile against it with `pkg-config`:',
  usageSnippet: '''
#include "tom_som_cpp_v0.hpp"

#include <iostream>

int main() {
  // A typed Solution Blueprint over a fresh document. The constructor also runs
  // the instantiation-time model-version check (an empty stamp is editable).
  // RAII: the document is a value that must outlive every facade bound to it;
  // getters return std::string by value, so there is nothing to free.
  som::SpecDocument doc;
  tom_som_v0::D00SolutionBlueprint bp(doc);

  bp.setContent("A platform that unifies our fragmented order systems.");

  tom_som_v0::CurrentLandscape cl = bp.currentLandscape();
  cl.setContent("Three legacy systems with no shared customer record.");

  std::cout << bp.content() << "\\n";
  return 0;
}''',
  integrateRoutes: [
    PackagingRoute(
      heading: 'pkg-config (installed)',
      body: 'C++ has no universal package registry. Install the facade and the '
          'runtime (runtime first — the facade links against it), then let '
          '`pkg-config` supply the compile and link flags:\n\n'
          '```bash\n'
          'make -C ../tom_som_cpp_runtime install\n'
          'make install\n'
          'c++ myapp.cpp \$(pkg-config --cflags --libs tom_som_cpp_v0) -o myapp\n'
          '```\n\n'
          'The facade `.pc` declares `Requires: tom_som_cpp_runtime`, so a '
          'single `pkg-config tom_som_cpp_v0` pulls in the runtime flags too. '
          'Both `.pc` files report `Version VERSION`.',
    ),
    PackagingRoute(
      heading: 'Source tarball (vendored)',
      body: 'Produce versioned source tarballs and vendor them into your '
          'build:\n\n'
          '```bash\n'
          'make -C ../tom_som_cpp_runtime dist   # tom_som_cpp_runtime-VERSION.tar.gz\n'
          'make dist                             # tom_som_cpp_v0-VERSION.tar.gz\n'
          '```\n\n'
          'Unpack both alongside your project and add each `include/` to your '
          'include path plus the built libraries to your link line.',
    ),
    PackagingRoute(
      heading: 'In-tree (monorepo)',
      body: 'When the SOM projects sit alongside your code, build the facade in '
          "place; its `Makefile` builds the runtime on demand through a relative "
          '`RUNTIME_DIR`:\n\n'
          '```bash\n'
          'make                                  # builds runtime + facade libs\n'
          'c++ myapp.cpp -Iinclude -I../tom_som_cpp_runtime/include \\\n'
          '   build/libtom_som_cpp_v0.a ../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a \\\n'
          '   -o myapp\n'
          '```',
    ),
  ],
  buildFromSource: 'Regenerate the facade, then build and package both projects '
      'from the workspace (runtime first — the facade builds it on demand '
      'through its relative `RUNTIME_DIR`):\n\n'
      '```bash\n'
      'dart run tom_specs_clitool/bin/generate_som.dart\n'
      'cd tom_som_cpp_runtime && make && make dist\n'
      'cd ../tom_som_cpp_v0 && make && make dist\n'
      '```\n\n'
      'Each `make` builds the static + shared library and the pkg-config file; '
      'each `make dist` writes `build/<name>-<version>.tar.gz`.',
  buildArtifactIgnores: [
    'build/',
    '*.o',
    '*.a',
    '*.so',
    '*.so.*',
    '*.pc',
    '*.tar.gz',
  ],
  runtimeManifestFileName: 'Makefile',
  runtimeManifestFormat: ManifestFormat.makefileVar,
  manifestDescription: 'Generated typed TomSpecs object-model facade (C++).',
  manifestDescriptionFile: 'Makefile',
  whereThisFitsSentence: 'Idiomatic C++17 with RAII throughout — the document is a value that must outlive every facade bound to it, and getters return `std::string` by value, so there is nothing to free.',
  tutorialSentence: 'A C++ walkthrough end to end — install, open a document, read and edit a section, validate it, and serialize to `*.docspecs.yaml` and Markdown.',
  exampleDirName: 'examples',
  examples: [
    PackagingExample(
      file: 'a_typed_access.cpp',
      demonstrates: 'The generated typed facade — named members, nested-section navigation, and the typed `SomList` collection.',
    ),
    PackagingExample(
      file: 'b_generic_document.cpp',
      demonstrates: 'The generic runtime underneath — string paths into a sparse store, plus JSON and YAML serialization.',
    ),
    PackagingExample(
      file: 'c_reflection_metadata.cpp',
      demonstrates: 'The value-free reflection surface — load `meta/spec_model.meta.json`, enumerate roots and fields, resolve a path to the model node it lands on.',
    ),
  ],
  usageSections: [
    PackagingUsage(
      heading: 'The generic store underneath',
      intro: 'A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.',
      snippet: '''
#include "tom_som_cpp_runtime.hpp"
#include "tom_som_cpp_v0_meta.hpp"

som::SpecDocument doc;
doc.setContent("SBP/content",
               "A platform that unifies our fragmented order systems.");

// A repeated section: append an item, then fill a content leaf under it.
const std::string item =
    doc.addListItem("SBP/currentLandscape/CUOPME-OPER-LST");
doc.setContent(som::joinPath(item, "content"),
               "Average order turnaround: 4.2 days.");

// The whole document serializes to the canonical wire format.
std::string err;
std::optional<std::string> yaml = som::encodeYaml(
    doc, tom_som_v0_meta::d00SolutionBlueprintMetaTree(), "1.0", &err);
std::cout << *yaml;
''',
    ),
    PackagingUsage(
      heading: 'Metadata and reflection',
      intro: 'The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).',
      snippet: '''
#include "tom_som_cpp_runtime.hpp"

std::string err;
std::unique_ptr<som::SpecModel> model = som::SpecModel::fromJsonStr(data, &err);
som::SpecReflection ref(*model);

// The roots are model data; the reflection resolves paths against them.
for (const som::SpecRoot& root : model->roots) {
  std::cout << som::SpecReflection::rootSegment(root) << "  " << root.title
            << "\n";
}

std::optional<som::SpecResolution> res =
    ref.resolve("SBP/currentLandscape/content");
std::cout << "kind=" << res->kind << "  valueLeaf=" << res->isValueLeaf()
          << "\n";
''',
    ),
  ],
  verifyCommand: '''
make -C ../tom_som_cpp_runtime
make
./run_tests.sh   # the behavioural suites + the three samples''',
);

/// The [PackagingDescriptor] for [language], or `null` when none is registered
/// yet (in which case the generator's packaging hook is a no-op for it).
PackagingDescriptor? packagingDescriptorFor(SomLanguage language) =>
    _packagingDescriptors[language];
