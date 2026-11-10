/// The freshness gate over everything `bin/generate_som.dart` commits: the nine
/// `tom_som_<slug>_v0` packages and the model package's own `spec_ops.g.dart`.
///
/// Group 1 is the guard itself: it fails when `tom_specs_model` has moved since
/// `bin/generate_som.dart` last ran, so a model edit cannot ship with those
/// artifacts describing the previous model.
///
/// Group 2 proves the fingerprint moves for the *right* reasons. Without it the
/// guard could be green forever by fingerprinting nothing — group 1 can only
/// assert stability, never reactivity.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final modelDir = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model'));
  final configPath = p.join(clitoolRoot, 'tom_som.yaml');

  group('SOM package freshness', () {
    late SpecObjectModelConfig config;

    setUpAll(() {
      config = SpecObjectModelConfig.fromYaml(
        File(configPath).readAsStringSync(),
      );
    });

    test('every configured language is covered by the stamp and on disk', () {
      final stamp = readModelSurfaceStamp(clitoolRoot: clitoolRoot);
      expect(
        stamp,
        isNotNull,
        reason:
            'no $modelSurfaceStampPath — run '
            '`dart run bin/generate_som.dart` to write it.',
      );

      final mismatch = somPackageCoverageMismatch(
        config: config,
        configDir: p.dirname(configPath),
        stampedPackages: stamp!.packages,
      );
      expect(
        mismatch,
        isNull,
        reason:
            'the set of generated packages has changed without a '
            'regeneration.\n$mismatch',
      );
    });

    test('the committed packages were generated from the current model', () {
      final stamp = readModelSurfaceStamp(clitoolRoot: clitoolRoot);
      expect(
        stamp,
        isNotNull,
        reason:
            'no $modelSurfaceStampPath — run '
            '`dart run bin/generate_som.dart` to write it.',
      );

      final now = computeModelSurface(
        modelPackagePath: modelDir,
        packages: configuredPackageNames(config),
      );
      if (now.fingerprint == stamp!.fingerprint) return;

      fail(
        'tom_specs_model has changed since it was last generated from, so '
        'all ${stamp.packages.length} tom_som_*_v0 packages — sources, '
        'meta/spec_model.meta.json and the DocSpecs schemas — plus the '
        'spec_ops.g.dart registry in the model package describe the '
        'previous model.\n'
        '  files:        ${stamp.fileCount} -> ${now.fileCount}\n'
        '  declarations: ${stamp.declarationCount} -> '
        '${now.declarationCount}\n'
        '\n'
        'Regenerate and commit the result together with the stamp:\n'
        '  cd tom_specs_clitool && dart run bin/generate_som.dart\n'
        '\n'
        'See _copilot_guidelines/som_regeneration.md.',
      );
    });

    test('the fingerprint covers the reader file set, not the versioner', () {
      // The versioner's stamp is generated per host and not committed, so a
      // fingerprint over it could be reproduced only where the model was last
      // built: on a fresh checkout it is absent, on another host it is left
      // from another build. The committed version stands in for it (MF-V1).
      final readerFiles = collectModelSourceFiles(modelDir);
      final surface = computeModelSurface(
        modelPackagePath: modelDir,
        packages: const ['tom_som_dart_v0'],
      );
      expect(surface.fileCount, readerFiles.length);
    });
  });

  group('MF-V1 the committed model version', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('model_version_');
      Directory(p.join(dir.path, 'lib', 'src')).createSync(recursive: true);
      File(
        p.join(dir.path, 'lib', 'src', 'a.dart'),
      ).writeAsStringSync('class A { final int x = 1; }\n');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    String fingerprintAt(String version) {
      File(
        p.join(dir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: m\nversion: $version\n');
      return computeModelSurface(
        modelPackagePath: dir.path,
        packages: const ['tom_som_dart_v0'],
      ).fingerprint;
    }

    test('MF-V1.1 a version bump alone moves the fingerprint', () {
      expect(fingerprintAt('1.8.0'), isNot(fingerprintAt('1.9.0')));
      expect(fingerprintAt('1.8.0'), fingerprintAt('1.8.0'));
    });

    test('MF-V1.2 the versioner stamp does not enter it', () {
      final before = fingerprintAt('1.8.0');
      File(
        p.join(dir.path, 'lib', 'src', 'version.versioner.dart'),
      ).writeAsStringSync("const String version = '1.8.0';\n");
      expect(fingerprintAt('1.8.0'), before);
    });

    test('MF-V1.3 a stamp left from an earlier build is refused', () {
      fingerprintAt('1.8.0');
      File(
        p.join(dir.path, 'lib', 'src', 'version.versioner.dart'),
      ).writeAsStringSync(
        "static const String version = '1.3.2';\n"
        'static const int buildNumber = 1;\n',
      );
      expect(
        () => readModelVersionStamp(dir.path),
        throwsA(
          isA<ModelVersionStampException>().having(
            (e) => e.message,
            'message',
            contains('left from an earlier build'),
          ),
        ),
      );
    });
  });

  group('model surface fingerprint sensitivity', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('model_surface_'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// Writes [content] to `<dir>/<name>` and returns the fingerprint of the
    /// whole directory.
    String hashOf(Map<String, String> files) {
      for (final entry in dir.listSync()) {
        entry.deleteSync(recursive: true);
      }
      final written = <File>[];
      for (final e in files.entries) {
        written.add(File(p.join(dir.path, e.key))..writeAsStringSync(e.value));
      }
      return fingerprintSources(written, rootDir: dir.path).hash;
    }

    const base = '''
/// A section of the blueprint.
@SectionId('AAA')
class Alpha {
  // An ordinary implementation note.

  /// The section's title.
  @SerializationOrder(0)
  String? title;

  String get shout => title!.toUpperCase();
}
''';

    test('is stable for identical input', () {
      expect(hashOf({'a.dart': base}), hashOf({'a.dart': base}));
    });

    test('moves when a member is added', () {
      final changed = base.replaceFirst(
        '  String? title;',
        '  String? title;\n  String? subtitle;',
      );
      expect(hashOf({'a.dart': changed}), isNot(hashOf({'a.dart': base})));
    });

    test('moves when a member is removed', () {
      final changed = base.replaceFirst('  String? title;\n', '');
      expect(hashOf({'a.dart': changed}), isNot(hashOf({'a.dart': base})));
    });

    test('moves when a member is renamed', () {
      final changed = base.replaceFirst('String? title;', 'String? heading;');
      expect(hashOf({'a.dart': changed}), isNot(hashOf({'a.dart': base})));
    });

    test('moves when a declared type changes', () {
      final changed = base.replaceFirst(
        'String? title;',
        'List<String>? title;',
      );
      expect(hashOf({'a.dart': changed}), isNot(hashOf({'a.dart': base})));
    });

    test('moves when an annotation argument changes', () {
      final changed = base.replaceFirst(
        "@SectionId('AAA')",
        "@SectionId('BBB')",
      );
      expect(hashOf({'a.dart': changed}), isNot(hashOf({'a.dart': base})));
    });

    test('moves when a doc comment is reworded', () {
      // The model-specific case: doc comments are exported into every language's
      // meta as `docComment`, so rewording one really does change all nine
      // packages. (The equivalent guard over the D4rt bridges ignores them.)
      final changed = base.replaceFirst(
        "/// The section's title.",
        '/// The headline.',
      );
      expect(hashOf({'a.dart': changed}), isNot(hashOf({'a.dart': base})));
    });

    test('moves when a file is renamed', () {
      expect(hashOf({'b.dart': base}), isNot(hashOf({'a.dart': base})));
    });

    test('ignores reformatting', () {
      final changed = base
          .replaceAll('\n', '\n\n')
          .replaceFirst('class Alpha {', 'class\n    Alpha\n{');
      expect(hashOf({'a.dart': changed}), hashOf({'a.dart': base}));
    });

    test('ignores a rewritten function body', () {
      final changed = base.replaceFirst(
        'String get shout => title!.toUpperCase();',
        'String get shout {\n    return title!.toUpperCase();\n  }',
      );
      expect(hashOf({'a.dart': changed}), hashOf({'a.dart': base}));
    });

    test('ignores an ordinary comment', () {
      final changed = base.replaceFirst(
        '  // An ordinary implementation note.',
        '  // Something else.',
      );
      expect(hashOf({'a.dart': changed}), hashOf({'a.dart': base}));
    });
  });
}
