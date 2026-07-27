import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart'
    show
        SpecObjectModelConfig,
        SpecObjectModelConfigException,
        SomLanguage,
        SomLanguageTarget;

/// Tests for the SOM generator config model + parser (som_generator_config.md).
///
/// The parser turns a decoded `tom-spec-object-model` block (from
/// `tom_specs_clitool`'s own config) into a typed [SpecObjectModelConfig]:
/// target languages, per-language output roots (with defaults), the `v0`
/// version label, and which document roots to generate. The four done-when
/// cases — valid multi-language config, default output paths, duplicate-language
/// rejection, unknown-language rejection — are covered below, plus YAML
/// extraction of the top-level key.
void main() {
  group('SomLanguage.fromToken', () {
    test('resolves canonical tokens for all nine languages', () {
      expect(SomLanguage.fromToken('dart'), SomLanguage.dart);
      expect(SomLanguage.fromToken('java'), SomLanguage.java);
      expect(SomLanguage.fromToken('javascript'), SomLanguage.javascript);
      expect(SomLanguage.fromToken('typescript'), SomLanguage.typescript);
      expect(SomLanguage.fromToken('go'), SomLanguage.go);
      expect(SomLanguage.fromToken('rust'), SomLanguage.rust);
      expect(SomLanguage.fromToken('c'), SomLanguage.c);
      expect(SomLanguage.fromToken('c++'), SomLanguage.cpp);
      expect(SomLanguage.fromToken('python'), SomLanguage.python);
    });

    test('is case-insensitive and accepts common aliases', () {
      expect(SomLanguage.fromToken('JavaScript'), SomLanguage.javascript);
      expect(SomLanguage.fromToken('js'), SomLanguage.javascript);
      expect(SomLanguage.fromToken('ts'), SomLanguage.typescript);
      expect(SomLanguage.fromToken('cpp'), SomLanguage.cpp);
      expect(SomLanguage.fromToken('py'), SomLanguage.python);
    });

    test('returns null for an unknown token', () {
      expect(SomLanguage.fromToken('cobol'), isNull);
    });

    test('every language has a project-safe slug (no "++"/spaces)', () {
      for (final l in SomLanguage.values) {
        expect(RegExp(r'^[a-z0-9]+$').hasMatch(l.slug), isTrue,
            reason: '${l.name} slug "${l.slug}" must be package-name-safe');
      }
      expect(SomLanguage.cpp.slug, 'cpp');
    });
  });

  group('SpecObjectModelConfig.fromMap — valid multi-language config', () {
    final config = SpecObjectModelConfig.fromMap({
      'version-label': 'v0',
      'output-base': 'tom_ai/ai_build',
      'document-roots': ['SolutionBlueprint', 'CurrentLandscapeAssessment'],
      'languages': [
        'dart',
        {'language': 'java', 'output': 'custom/java/tom_som_java'},
        'python',
      ],
    });

    test('parses the version label', () {
      expect(config.versionLabel, 'v0');
    });

    test('parses the requested document roots', () {
      expect(config.documentRoots,
          ['SolutionBlueprint', 'CurrentLandscapeAssessment']);
      expect(config.generatesAllRoots, isFalse);
    });

    test('parses every language target in order', () {
      expect(config.languages.map((t) => t.language),
          [SomLanguage.dart, SomLanguage.java, SomLanguage.python]);
    });

    test('honours a per-language output override', () {
      final java = config.targetFor(SomLanguage.java)!;
      expect(java.outputRoot, 'custom/java/tom_som_java');
    });
  });

  group('SpecObjectModelConfig.fromMap — default output paths', () {
    test('a language without an override gets '
        '<output-base>/tom_som_<slug>_<label>', () {
      final config = SpecObjectModelConfig.fromMap({
        'output-base': 'gen',
        'languages': ['dart', 'c++'],
      });
      expect(config.targetFor(SomLanguage.dart)!.outputRoot,
          p.join('gen', 'tom_som_dart_v0'));
      // c++ resolves to the package-safe slug "cpp" in the default path.
      expect(config.targetFor(SomLanguage.cpp)!.outputRoot,
          p.join('gen', 'tom_som_cpp_v0'));
    });

    test('output-base defaults to "." and version-label to "v0"', () {
      final config = SpecObjectModelConfig.fromMap({
        'languages': ['go'],
      });
      expect(config.versionLabel, 'v0');
      expect(config.targetFor(SomLanguage.go)!.outputRoot,
          p.join('.', 'tom_som_go_v0'));
    });

    test('the version label flows into default output paths', () {
      final config = SpecObjectModelConfig.fromMap({
        'version-label': 'v1',
        'languages': ['rust'],
      });
      expect(config.targetFor(SomLanguage.rust)!.outputRoot,
          p.join('.', 'tom_som_rust_v1'));
    });

    test('absent document-roots means "generate all roots"', () {
      final config = SpecObjectModelConfig.fromMap({
        'languages': ['dart'],
      });
      expect(config.documentRoots, isEmpty);
      expect(config.generatesAllRoots, isTrue);
    });
  });

  group('SpecObjectModelConfig.fromMap — rejections', () {
    test('rejects a duplicate language', () {
      expect(
        () => SpecObjectModelConfig.fromMap({
          'languages': ['dart', 'go', 'dart'],
        }),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
    });

    test('rejects a duplicate language reached via an alias', () {
      expect(
        () => SpecObjectModelConfig.fromMap({
          'languages': ['javascript', 'js'],
        }),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
    });

    test('rejects an unknown language token', () {
      expect(
        () => SpecObjectModelConfig.fromMap({
          'languages': ['dart', 'cobol'],
        }),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
    });

    test('rejects an empty/missing languages list', () {
      expect(
        () => SpecObjectModelConfig.fromMap({'languages': <dynamic>[]}),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
      expect(
        () => SpecObjectModelConfig.fromMap(<dynamic, dynamic>{}),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
    });

    test('rejects a non-string document-root entry', () {
      expect(
        () => SpecObjectModelConfig.fromMap({
          'languages': ['dart'],
          'document-roots': [42],
        }),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
    });
  });

  group('SpecObjectModelConfig.fromYaml — top-level key extraction', () {
    test('reads the tom-spec-object-model block from a YAML document', () {
      const yaml = '''
# tom_specs_clitool config
some-other-tool:
  foo: bar
tom-spec-object-model:
  version-label: v0
  output-base: gen
  languages:
    - dart
    - language: typescript
      output: web/tom_som_ts
''';
      final config = SpecObjectModelConfig.fromYaml(yaml);
      expect(config.versionLabel, 'v0');
      expect(config.languages.map((t) => t.language),
          [SomLanguage.dart, SomLanguage.typescript]);
      expect(config.targetFor(SomLanguage.dart)!.outputRoot,
          p.join('gen', 'tom_som_dart_v0'));
      expect(config.targetFor(SomLanguage.typescript)!.outputRoot,
          'web/tom_som_ts');
    });

    test('throws when the top-level block is absent', () {
      expect(
        () => SpecObjectModelConfig.fromYaml('other-tool:\n  x: 1\n'),
        throwsA(isA<SpecObjectModelConfigException>()),
      );
    });
  });

  group('SomLanguageTarget', () {
    test('exposes the resolved language and output root', () {
      const target = SomLanguageTarget(
          language: SomLanguage.dart, outputRoot: 'gen/tom_som_dart_v0');
      expect(target.language, SomLanguage.dart);
      expect(target.outputRoot, 'gen/tom_som_dart_v0');
    });
  });
}
