import 'package:tom_specs_clitool/tom_specs_clitool.dart';
import 'package:test/test.dart';

/// A representative descriptor for the shared-mechanism tests. It is *not* a
/// registered language (it is not in the SOM §17.3 registry); it only
/// exercises the language-agnostic renderers and rewriters.
PackagingDescriptor _sampleDescriptor() => const PackagingDescriptor(
      language: SomLanguage.dart,
      displayName: 'Dart',
      runtimePackageName: 'tom_som_dart_runtime',
      facadePackageName: 'tom_som_dart_v0',
      codeFence: 'dart',
      installShort: 'Add `tom_som_dart_v0` to your `pubspec.yaml`.',
      usageSnippet: "final doc = SpecDocument()..loadJson(decoded.document);",
      integrateRoutes: [
        PackagingRoute(heading: 'From pub.dev', body: 'dart pub add tom_som_dart_v0'),
        PackagingRoute(heading: 'Git dependency', body: 'use a `git:` dep'),
      ],
      buildFromSource: 'dart pub get && dart pub publish --dry-run',
      buildArtifactIgnores: ['.dart_tool/', 'doc/api/'],
      runtimeManifestFileName: 'pubspec.yaml',
      runtimeManifestFormat: ManifestFormat.pubspec,
    );

void main() {
  group('packageVersionFromModel (SOM §17)', () {
    test('pads major.minor to three components', () {
      expect(packageVersionFromModel('1.0'), '1.0.0');
    });

    test('pads a bare major', () {
      expect(packageVersionFromModel('2'), '2.0.0');
    });

    test('keeps a full three-component version', () {
      expect(packageVersionFromModel('1.4.7'), '1.4.7');
    });

    test('coerces non-numeric and empty to zeros', () {
      expect(packageVersionFromModel(''), '0.0.0');
      expect(packageVersionFromModel('x.y'), '0.0.0');
    });

    test('truncates beyond three components', () {
      expect(packageVersionFromModel('1.2.3.4'), '1.2.3');
    });
  });

  group('rewriteManifestVersion (SOM §17)', () {
    test('pubspec version line', () {
      const src = 'name: foo\nversion: 0.0.0\n\nenvironment:\n  sdk: ^3.11.4\n';
      final out = rewriteManifestVersion(src, ManifestFormat.pubspec, '1.0.0');
      expect(out, contains('version: 1.0.0'));
      expect(out, isNot(contains('0.0.0')));
    });

    test('pyproject version', () {
      const src = '[project]\nname = "foo"\nversion = "0.0.0"\n';
      final out = rewriteManifestVersion(src, ManifestFormat.pyproject, '1.0.0');
      expect(out, contains('version = "1.0.0"'));
    });

    test('package.json version', () {
      const src = '{\n  "name": "foo",\n  "version": "0.0.0"\n}\n';
      final out =
          rewriteManifestVersion(src, ManifestFormat.packageJson, '1.0.0');
      expect(out, contains('"version": "1.0.0"'));
    });

    test('Cargo.toml rewrites the package version, not later ones', () {
      const src = '[package]\nname = "foo"\nversion = "0.0.0"\n\n'
          '[dependencies]\nserde = { version = "1.0" }\n';
      final out = rewriteManifestVersion(src, ManifestFormat.cargoToml, '2.0.0');
      expect(out, contains('name = "foo"\nversion = "2.0.0"'));
      // The dependency version is untouched (replaceFirst).
      expect(out, contains('serde = { version = "1.0" }'));
    });

    test('go version constant gets a v-prefix', () {
      const src = 'package somv0\n\nconst Version = "v0.0.0"\n';
      final out =
          rewriteManifestVersion(src, ManifestFormat.goVersionConst, '1.0.0');
      expect(out, contains('Version = "v1.0.0"'));
    });

    test('Makefile VERSION variable', () {
      const src = 'VERSION := 0.0.0\nCC := gcc\n';
      final out =
          rewriteManifestVersion(src, ManifestFormat.makefileVar, '1.0.0');
      expect(out, contains('VERSION := 1.0.0'));
    });

    test('is idempotent', () {
      const src = 'name: foo\nversion: 1.0.0\n';
      final out = rewriteManifestVersion(src, ManifestFormat.pubspec, '1.0.0');
      expect(out, src);
    });

    test('throws when no version field exists', () {
      expect(
        () => rewriteManifestVersion('name: foo\n', ManifestFormat.pubspec, '1.0.0'),
        throwsStateError,
      );
    });
  });

  group('renderFacadeReadme (SOM §17)', () {
    test('leads with the how-to block and the version', () {
      final md = renderFacadeReadme(_sampleDescriptor(), version: '1.0.0');
      expect(md, startsWith('# tom_som_dart_v0'));
      expect(md, contains('do not edit by hand'));
      expect(md, contains('## How to use'));
      expect(md, contains('Add `tom_som_dart_v0`'));
      expect(md, contains('(v1.0.0)'));
      expect(md, contains('```dart'));
      expect(md, contains('readme_howtointegrate.md'));
    });
  });

  group('renderHowToIntegrate (SOM §17)', () {
    test('renders every route and the version-pin section', () {
      final md = renderHowToIntegrate(_sampleDescriptor(), version: '1.0.0');
      expect(md, contains('# Integrating tom_som_dart_v0'));
      expect(md, contains('### From pub.dev'));
      expect(md, contains('### Git dependency'));
      expect(md, contains('## Pinning the version'));
      expect(md, contains('`1.0.0`'));
      expect(md, contains('## Building from source'));
      expect(md, contains('dart pub publish --dry-run'));
    });
  });

  group('ensureGitignoreContent (SOM §17)', () {
    test('appends missing globs under a managed header', () {
      final out = ensureGitignoreContent('build/\n', ['*.tgz', 'dist/']);
      expect(out, contains('build/'));
      expect(out, contains('packaging build artifacts (managed)'));
      expect(out, contains('*.tgz'));
      expect(out, contains('dist/'));
    });

    test('is idempotent when all globs already present', () {
      const existing = 'build/\n*.tgz\ndist/\n';
      final out = ensureGitignoreContent(existing, ['*.tgz', 'dist/']);
      expect(out, existing);
    });

    test('handles an empty starting file', () {
      final out = ensureGitignoreContent('', ['dist/']);
      expect(out, contains('dist/'));
    });
  });

  group('renderChangelog (SOM §17)', () {
    test('renders a single model-version entry', () {
      final md = renderChangelog(_sampleDescriptor(), version: '1.0.0');
      expect(md, startsWith('# Changelog'));
      expect(md, contains('## 1.0.0'));
      expect(md, contains('tom_som_dart_v0'));
      expect(md, contains('do not edit by hand'));
    });
  });

  group('licenseText (SOM §17)', () {
    test('is the workspace release license (BSD 3-Clause)', () {
      expect(licenseText, contains('BSD 3-Clause License'));
      expect(licenseText, contains('Peter Nicolai Alexis Kyaw'));
      expect(licenseText, contains('Redistribution and use in source'));
    });
  });

  group('packagingDescriptorFor — Dart (SOM §17.3)', () {
    test('Dart is registered with the pub package names', () {
      final d = packagingDescriptorFor(SomLanguage.dart);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_dart_runtime');
      expect(d.facadePackageName, 'tom_som_dart_v0');
      expect(d.codeFence, 'dart');
      expect(d.runtimeManifestFormat, ManifestFormat.pubspec);
      expect(d.runtimeManifestFileName, 'pubspec.yaml');
      // pub.dev / git / path routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
    });

    test('languages without a descriptor yet return null', () {
      const registered = {
        SomLanguage.dart,
        SomLanguage.python,
        SomLanguage.java,
        SomLanguage.javascript,
        SomLanguage.typescript,
        SomLanguage.go,
        SomLanguage.rust,
        SomLanguage.c,
        SomLanguage.cpp,
      };
      for (final lang in SomLanguage.values) {
        if (registered.contains(lang)) continue;
        expect(packagingDescriptorFor(lang), isNull,
            reason: 'no descriptor should be registered yet for $lang');
      }
    });
  });

  group('packagingDescriptorFor — Python (SOM §17.3)', () {
    test('Python is registered with the PEP 517 package names', () {
      final d = packagingDescriptorFor(SomLanguage.python);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_python_runtime');
      expect(d.facadePackageName, 'tom_som_python_v0');
      expect(d.codeFence, 'python');
      expect(d.runtimeManifestFormat, ManifestFormat.pyproject);
      expect(d.runtimeManifestFileName, 'pyproject.toml');
      // PyPI / git / editable routes plus the shipped-data-files route are
      // all documented.
      expect(d.integrateRoutes, hasLength(4));
      expect(d.integrateRoutes.last.heading, contains('data files'),
          reason: 'the 4th route documents the wheel-shipped meta/schemas '
              'data resolution (tom_som_python_v0_data)');
    });
  });

  group('packagingDescriptorFor — Java (SOM §17.3)', () {
    test('Java is registered with the Maven package names', () {
      final d = packagingDescriptorFor(SomLanguage.java);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_java_runtime');
      expect(d.facadePackageName, 'tom_som_java_v0');
      expect(d.codeFence, 'java');
      expect(d.runtimeManifestFormat, ManifestFormat.pomXml);
      expect(d.runtimeManifestFileName, 'pom.xml');
      // Maven repo / local install / JDK-only JAR routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
    });
  });

  group('packagingDescriptorFor — JavaScript (SOM §17.3)', () {
    test('JavaScript is registered with the npm package names', () {
      final d = packagingDescriptorFor(SomLanguage.javascript);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_javascript_runtime');
      expect(d.facadePackageName, 'tom_som_javascript_v0');
      expect(d.codeFence, 'javascript');
      expect(d.runtimeManifestFormat, ManifestFormat.packageJson);
      expect(d.runtimeManifestFileName, 'package.json');
      // npm / git / path-or-link routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
    });
  });

  group('packagingDescriptorFor — TypeScript (SOM §17.3)', () {
    test('TypeScript is registered with the npm package names', () {
      final d = packagingDescriptorFor(SomLanguage.typescript);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_typescript_runtime');
      expect(d.facadePackageName, 'tom_som_typescript_v0');
      expect(d.codeFence, 'typescript');
      expect(d.runtimeManifestFormat, ManifestFormat.packageJson);
      expect(d.runtimeManifestFileName, 'package.json');
      // npm / git / path-or-link routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
    });
  });

  group('packagingDescriptorFor — Go (SOM §17.3)', () {
    test('Go is registered with the module-path package names', () {
      final d = packagingDescriptorFor(SomLanguage.go);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_go_runtime');
      expect(d.facadePackageName, 'tom_som_go_v0');
      expect(d.codeFence, 'go');
      // Go carries its version in an in-source constant (doc.go), not a manifest.
      expect(d.runtimeManifestFormat, ManifestFormat.goVersionConst);
      expect(d.runtimeManifestFileName, 'doc.go');
      // go get / version tags / path replace routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
    });
  });

  group('packagingDescriptorFor — Rust (SOM §17.3)', () {
    test('Rust is registered with the Cargo crate names', () {
      final d = packagingDescriptorFor(SomLanguage.rust);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_rust_runtime');
      expect(d.facadePackageName, 'tom_som_rust_v0');
      expect(d.codeFence, 'rust');
      expect(d.runtimeManifestFormat, ManifestFormat.cargoToml);
      expect(d.runtimeManifestFileName, 'Cargo.toml');
      // crates.io / git / path routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
      // Cargo build artifacts (target dir + lockfile) stay out of VCS.
      expect(d.buildArtifactIgnores, contains('/target'));
    });
  });

  group('packagingDescriptorFor — C (SOM §17.3)', () {
    test('C is registered with the Makefile / pkg-config package names', () {
      final d = packagingDescriptorFor(SomLanguage.c);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_c_runtime');
      expect(d.facadePackageName, 'tom_som_c_v0');
      expect(d.codeFence, 'c');
      // C carries its version in the Makefile VERSION variable (no registry).
      expect(d.runtimeManifestFormat, ManifestFormat.makefileVar);
      expect(d.runtimeManifestFileName, 'Makefile');
      // pkg-config / source-tarball / in-tree routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
      // The shared library, pkg-config file, and dist tarball stay out of VCS.
      expect(d.buildArtifactIgnores, containsAll(['*.so', '*.pc', '*.tar.gz']));
    });
  });

  group('packagingDescriptorFor — C++ (SOM §17.3)', () {
    test('C++ is registered with the Makefile / pkg-config package names', () {
      final d = packagingDescriptorFor(SomLanguage.cpp);
      expect(d, isNotNull);
      expect(d!.runtimePackageName, 'tom_som_cpp_runtime');
      expect(d.facadePackageName, 'tom_som_cpp_v0');
      expect(d.codeFence, 'cpp');
      // C++ carries its version in the Makefile VERSION variable (no registry).
      expect(d.runtimeManifestFormat, ManifestFormat.makefileVar);
      expect(d.runtimeManifestFileName, 'Makefile');
      // pkg-config / source-tarball / in-tree routes are all documented.
      expect(d.integrateRoutes, hasLength(3));
      // The shared library, pkg-config file, and dist tarball stay out of VCS.
      expect(d.buildArtifactIgnores, containsAll(['*.so', '*.pc', '*.tar.gz']));
    });
  });

  group('rewriteManifestVersion — Maven pom.xml (SOM §17.3)', () {
    test('pom.xml rewrites the project version, not the modelVersion or deps',
        () {
      const src = '<project>\n'
          '  <modelVersion>4.0.0</modelVersion>\n'
          '  <artifactId>foo</artifactId>\n'
          '  <version>0.0.0</version>\n'
          '  <dependencies>\n'
          '    <dependency><version>9.9.9</version></dependency>\n'
          '  </dependencies>\n'
          '</project>\n';
      final out = rewriteManifestVersion(src, ManifestFormat.pomXml, '1.0.0');
      // The project version is rewritten…
      expect(out, contains('<artifactId>foo</artifactId>\n  <version>1.0.0'));
      // …while <modelVersion> (the POM schema version) is left intact…
      expect(out, contains('<modelVersion>4.0.0</modelVersion>'));
      // …and a later dependency version is untouched (replaceFirst).
      expect(out, contains('<dependency><version>9.9.9</version></dependency>'));
    });

    test('is idempotent', () {
      const src =
          '<project>\n  <version>1.0.0</version>\n</project>\n';
      final out = rewriteManifestVersion(src, ManifestFormat.pomXml, '1.0.0');
      expect(out, src);
    });
  });
}
