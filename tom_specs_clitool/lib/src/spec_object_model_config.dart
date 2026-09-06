import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Raised when the `tom-spec-object-model` config block is malformed — an
/// unknown/duplicate language, an empty target set, a wrong-typed value, or a
/// missing top-level block in a YAML document.
class SpecObjectModelConfigException implements Exception {
  /// Reports a malformed config block, describing the fault in [message].
  SpecObjectModelConfigException(this.message);

  /// What is wrong with the block, phrased for someone editing the YAML.
  ///
  /// It names the offending key and value rather than the parser state: the
  /// reader is an author who mistyped a language token, not a maintainer of
  /// this parser.
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
  /// Dart — the model's own language, and the only target whose generated
  /// facade the rest of this package can itself consume.
  dart('dart', ['dart']),

  /// Java.
  java('java', ['java']),

  /// JavaScript. Accepts `js`, which is what most configs write.
  javascript('javascript', ['javascript', 'js']),

  /// TypeScript. Accepts `ts`. Distinct from [javascript] despite sharing a
  /// registry: the two emit different facades and are separate targets.
  typescript('typescript', ['typescript', 'ts']),

  /// Go. Accepts `golang`, the spelling the toolchain itself uses.
  go('go', ['go', 'golang']),

  /// Rust. Accepts `rs`, matching the file extension.
  rust('rust', ['rust', 'rs']),

  /// C.
  c('c', ['c']),

  /// C++. The slug is `cpp`, not `c++` — the slug becomes a directory and
  /// package name, and `+` is legal in neither. `c++` is still accepted as a
  /// config token, since that is what an author writes.
  cpp('cpp', ['c++', 'cpp', 'cxx']),

  /// Python. Accepts `py`.
  python('python', ['python', 'py']);

  /// Binds a language to its package-safe [slug] and the config [tokens] that
  /// resolve to it.
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
  /// Pairs a [language] with the [outputRoot] its generated project lands in.
  ///
  /// Both are required and neither is derivable from the other: the language
  /// alone does not fix a path, and a path alone does not say which emitter
  /// writes into it.
  const SomLanguageTarget({required this.language, required this.outputRoot});

  /// The language to generate.
  final SomLanguage language;

  /// The directory the generated `tom_som_<slug>_<label>` project is written
  /// into — already resolved, so a consumer never re-applies `output-base`.
  ///
  /// It is either an explicit `output:` override from the config or the
  /// default `<output-base>/tom_som_<slug>_<label>`; by the time a target
  /// exists the distinction has been made and is no longer recoverable.
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
  /// Builds a config from already-validated parts.
  ///
  /// Every argument is required because a partially specified config has no
  /// sensible completion here — the defaults belong to the parsers
  /// ([fromMap] / [fromYaml]), which know which keys the author omitted.
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
