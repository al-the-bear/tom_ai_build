import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Raised when the `tom-spec-object-model` config block is malformed — an
/// unknown/duplicate language, an empty target set, a wrong-typed value, or a
/// missing top-level block in a YAML document.
class SpecObjectModelConfigException implements Exception {
  SpecObjectModelConfigException(this.message);

  final String message;

  @override
  String toString() => 'SpecObjectModelConfigException: $message';
}

/// A language the SOM (specification object model) generator can target.
///
/// Each value carries a **package-safe [slug]** (used in the generated project
/// name `tom_som_<slug>_<label>` — note `c++` → `cpp` so the name is a valid
/// directory/package identifier) and the set of **config [tokens]** accepted for
/// it (case-insensitive, with the common aliases `js`/`ts`/`cpp`/`py`).
enum SomLanguage {
  dart('dart', ['dart']),
  java('java', ['java']),
  javascript('javascript', ['javascript', 'js']),
  typescript('typescript', ['typescript', 'ts']),
  go('go', ['go', 'golang']),
  rust('rust', ['rust', 'rs']),
  c('c', ['c']),
  cpp('cpp', ['c++', 'cpp', 'cxx']),
  python('python', ['python', 'py']);

  const SomLanguage(this.slug, this.tokens);

  /// The package-name-safe identifier used in `tom_som_<slug>_<label>`.
  final String slug;

  /// The config tokens (lower-case) that resolve to this language.
  final List<String> tokens;

  /// Resolves a config [token] (case-insensitive, alias-aware) to a language, or
  /// `null` when no language claims it.
  static SomLanguage? fromToken(String token) {
    final t = token.trim().toLowerCase();
    for (final lang in values) {
      if (lang.tokens.contains(t)) return lang;
    }
    return null;
  }
}

/// One generation target: a [language] and the **output root** the generated
/// `tom_som_<slug>_<label>` project is written into (an explicit `output:`
/// override, or the default `<output-base>/tom_som_<slug>_<label>`).
class SomLanguageTarget {
  const SomLanguageTarget({required this.language, required this.outputRoot});

  final SomLanguage language;
  final String outputRoot;

  @override
  String toString() => 'SomLanguageTarget(${language.slug} → $outputRoot)';
}

/// The typed `tom-spec-object-model` config: which languages to generate, where
/// each lands, the version label (`v0`), and which document roots to generate.
///
/// Mirrors how other tom tooling reads a single top-level config key
/// ([configKey]) out of a YAML config; [fromMap] is the pure parser over a
/// decoded block and [fromYaml] extracts the block from a full document first.
class SpecObjectModelConfig {
  const SpecObjectModelConfig({
    required this.versionLabel,
    required this.outputBase,
    required this.languages,
    required this.documentRoots,
  });

  /// The top-level config key this block lives under.
  static const String configKey = 'tom-spec-object-model';

  /// The version label used when the config omits `version-label`.
  static const String defaultVersionLabel = 'v0';

  /// The output base used when the config omits `output-base`.
  static const String defaultOutputBase = '.';

  /// The version-suffix label (`v0`, `v1`, …) the generated projects carry.
  final String versionLabel;

  /// The base directory default per-language output roots are resolved under.
  final String outputBase;

  /// The generation targets, in config order.
  final List<SomLanguageTarget> languages;

  /// The document roots to generate; **empty means "generate all roots"**.
  final List<String> documentRoots;

  /// Whether the config requests every document root (no explicit subset).
  bool get generatesAllRoots => documentRoots.isEmpty;

  /// The target for [language], or `null` when it is not a configured target.
  SomLanguageTarget? targetFor(SomLanguage language) {
    for (final t in languages) {
      if (t.language == language) return t;
    }
    return null;
  }

  /// The default output root for [language] under [outputBase] with this config's
  /// [versionLabel]: `<output-base>/tom_som_<slug>_<label>`.
  String defaultOutputRootFor(SomLanguage language) =>
      p.join(outputBase, 'tom_som_${language.slug}_$versionLabel');

  /// Parses an already-decoded `tom-spec-object-model` block.
  ///
  /// Recognised keys: `version-label` (String, default `v0`), `output-base`
  /// (String, default `.`), `languages` (required non-empty list of either a
  /// language token or a `{language, output}` map), and `document-roots`
  /// (optional list of root type names; absent ⇒ all roots).
  factory SpecObjectModelConfig.fromMap(Map<dynamic, dynamic> block) {
    final versionLabel =
        _stringField(block, 'version-label') ?? defaultVersionLabel;
    if (versionLabel.trim().isEmpty) {
      throw SpecObjectModelConfigException('version-label must not be empty');
    }
    final outputBase =
        _stringField(block, 'output-base') ?? defaultOutputBase;

    final documentRoots = _parseDocumentRoots(block['document-roots']);
    final languages =
        _parseLanguages(block['languages'], versionLabel, outputBase);

    return SpecObjectModelConfig(
      versionLabel: versionLabel,
      outputBase: outputBase,
      languages: List.unmodifiable(languages),
      documentRoots: List.unmodifiable(documentRoots),
    );
  }

  /// Loads a full YAML document and parses its [configKey] block.
  ///
  /// Throws [SpecObjectModelConfigException] when the document is not a map or
  /// the top-level [configKey] block is absent.
  factory SpecObjectModelConfig.fromYaml(String yamlText) {
    final doc = loadYaml(yamlText);
    if (doc is! Map) {
      throw SpecObjectModelConfigException(
          'config document must be a YAML mapping at the top level');
    }
    final block = doc[configKey];
    if (block == null) {
      throw SpecObjectModelConfigException(
          'no `$configKey` block found in the config document');
    }
    if (block is! Map) {
      throw SpecObjectModelConfigException(
          '`$configKey` must be a mapping, got ${block.runtimeType}');
    }
    return SpecObjectModelConfig.fromMap(block);
  }

  static String? _stringField(Map<dynamic, dynamic> block, String key) {
    final value = block[key];
    if (value == null) return null;
    if (value is! String) {
      throw SpecObjectModelConfigException(
          '`$key` must be a string, got ${value.runtimeType}');
    }
    return value;
  }

  static List<String> _parseDocumentRoots(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw SpecObjectModelConfigException(
          '`document-roots` must be a list, got ${raw.runtimeType}');
    }
    final roots = <String>[];
    for (final entry in raw) {
      if (entry is! String) {
        throw SpecObjectModelConfigException(
            '`document-roots` entries must be strings, got '
            '${entry.runtimeType} ($entry)');
      }
      roots.add(entry);
    }
    return roots;
  }

  static List<SomLanguageTarget> _parseLanguages(
      Object? raw, String versionLabel, String outputBase) {
    if (raw is! List || raw.isEmpty) {
      throw SpecObjectModelConfigException(
          '`languages` must be a non-empty list of target languages');
    }
    final targets = <SomLanguageTarget>[];
    final seen = <SomLanguage>{};
    for (final entry in raw) {
      final (language, override) = _parseLanguageEntry(entry);
      if (!seen.add(language)) {
        throw SpecObjectModelConfigException(
            'duplicate language `${language.slug}` in `languages`');
      }
      final outputRoot = override ??
          p.join(outputBase, 'tom_som_${language.slug}_$versionLabel');
      targets.add(
          SomLanguageTarget(language: language, outputRoot: outputRoot));
    }
    return targets;
  }

  /// Resolves a single `languages` entry to its language + optional output
  /// override. Accepts a bare token string or a `{language, output}` map.
  static (SomLanguage, String?) _parseLanguageEntry(Object? entry) {
    if (entry is String) {
      return (_resolveToken(entry), null);
    }
    if (entry is Map) {
      final token = entry['language'];
      if (token is! String) {
        throw SpecObjectModelConfigException(
            'a `languages` map entry needs a string `language` key');
      }
      final output = entry['output'];
      if (output != null && output is! String) {
        throw SpecObjectModelConfigException(
            '`output` must be a string, got ${output.runtimeType}');
      }
      return (_resolveToken(token), output as String?);
    }
    throw SpecObjectModelConfigException(
        '`languages` entries must be a token string or a {language, output} '
        'map, got ${entry.runtimeType}');
  }

  static SomLanguage _resolveToken(String token) {
    final language = SomLanguage.fromToken(token);
    if (language == null) {
      throw SpecObjectModelConfigException(
          'unknown language `$token`; supported: '
          '${SomLanguage.values.map((l) => l.slug).join(', ')}');
    }
    return language;
  }
}
