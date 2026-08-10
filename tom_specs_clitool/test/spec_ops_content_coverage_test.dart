/// The committed `spec_ops.g.dart` carries every class the model declares, and
/// carries each one's `content` prose.
///
/// `spec_ops.g.dart` is generated code that is committed *into the model
/// package*, and it is data as far as the compiler is concerned — a registry of
/// closures. A registry that has fallen behind the model therefore does not fail
/// to build; it fails to carry a field. A campaign that gave 116 section classes
/// the `tom_specs_model_rules.md` §5.2 `content: String?` override shipped with
/// all 116 missing their `..content = n.content` (a copy-on-write clone dropped
/// the section's prose) and missing `yamlScalar` entirely (the prose did not
/// serialize), and every suite stayed green throughout.
///
/// `test/model_freshness_test.dart` now guards the artifact's *currency*: the
/// registry is emitted by `bin/generate_som.dart`, whose stamp fails when the
/// model has moved. This is the second net, and it guards something the
/// fingerprint cannot see — that the emitter, given a current model, actually
/// emitted the two members `content` depends on. Both inputs are committed
/// artifacts, so it runs without the analyzer.
///
/// The exemptions are the two hand-written leaves that adopt the contract by
/// mixing in `SpecNode` and are therefore deliberately absent from the registry.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The leaves that adopt `SpecNode` directly — the resolver's `is SpecNode`
/// fast-path serves them, so the codegen skips them. Same set as
/// `SpecOpsGenerator._mixinLeaves`; stated here so a third exemption has to be
/// argued for in a test rather than added to a private constant.
const _mixinLeaves = {'DocumentHeader', 'SectionMeta'};

void main() {
  final clitoolRoot = Directory.current.path;
  final metaPath = p.normalize(p.join(
      clitoolRoot, '..', 'tom_som_dart_v0', 'meta', 'spec_model.meta.json'));
  final registryPath = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model',
      'lib', 'src', 'generated', 'spec_ops.g.dart'));

  group('the committed spec-ops registry matches the committed meta', () {
    late Map<String, dynamic> metaClasses;
    late String containerRoot;
    late Map<String, String> registrations;

    setUpAll(() {
      final meta =
          jsonDecode(File(metaPath).readAsStringSync()) as Map<String, dynamic>;
      metaClasses = meta['classes'] as Map<String, dynamic>;
      containerRoot = meta['containerRoot'] as String;
      registrations = _readRegistrations(File(registryPath).readAsStringSync());
    });

    test('the registry parses into a plausible number of registrations', () {
      // Guards the guard: every assertion below is vacuous if the emitted shape
      // has moved and the regexes now match nothing.
      expect(registrations, hasLength(greaterThan(1000)),
          reason: 'parsed ${registrations.length} registrations out of '
              '$registryPath — the emitted shape has probably changed');
    });

    test('every model class in the meta is registered', () {
      final missing = [
        for (final name in metaClasses.keys)
          if (!_mixinLeaves.contains(name) && !registrations.containsKey(name))
            name,
      ];
      expect(missing, isEmpty,
          reason: '${missing.length} class(es) the meta declares have no '
              'SpecClassOps, so the engine cannot snapshot or serialize them:\n'
              '${missing.take(20).join('\n')}\n'
              'Regenerate: cd tom_specs_clitool && '
              'dart run bin/generate_som.dart');
    });

    test('every class that declares content carries it in cloneShallow', () {
      // The exact failure that shipped: the clone copies every *other* field, so
      // the object looks intact and only the prose is gone.
      final missing = <String>[];
      for (final name in _contentClasses(metaClasses, containerRoot)) {
        final block = registrations[name];
        if (block == null) continue; // covered by the registration test above
        if (!block.contains('..content = n.content')) missing.add(name);
      }
      expect(missing, isEmpty,
          reason: '${missing.length} class(es) declare `content` but their '
              'cloneShallow drops it — a copy-on-write edit loses the '
              "section's prose:\n${missing.take(20).join('\n')}");
    });

    test('every class that declares content exposes it as the yamlScalar', () {
      final missing = <String>[];
      for (final name in _contentClasses(metaClasses, containerRoot)) {
        final block = registrations[name];
        if (block == null) continue;
        if (!block.contains('yamlScalar: (o) => (o as $name).content,')) {
          missing.add(name);
        }
      }
      expect(missing, isEmpty,
          reason: '${missing.length} class(es) declare `content` but have no '
              'yamlScalar, so their prose does not serialize at all:\n'
              '${missing.take(20).join('\n')}');
    });

    test('the SpecNode leaves are exempt, and the exemption is load-bearing',
        () {
      // Stated as a test rather than a comment: the mixin fast-path is the only
      // reason a model class may be absent from the registry, so a third
      // absence has to be argued for here.
      for (final leaf in _mixinLeaves) {
        expect(registrations, isNot(contains(leaf)),
            reason: '$leaf adopts SpecNode by mixin; registering it too would '
                'give it two contradictory contracts');
      }
      // At least one leaf must actually reach the meta, or the exemption the
      // registration test above applies would be excusing nothing.
      expect(metaClasses.keys.toSet().intersection(_mixinLeaves), isNotEmpty,
          reason: 'no SpecNode leaf is in the meta, so the exemption is dead '
              'weight — drop it rather than leave a rule nothing exercises');
    });
  });
}

/// The meta classes that declare a `content` field, minus the container root —
/// a structural tree node rather than a section, so it owns no body text
/// (`tom_specs_model_rules.md` §5.2).
Iterable<String> _contentClasses(
  Map<String, dynamic> classes,
  String containerRoot,
) sync* {
  for (final entry in classes.entries) {
    if (entry.key == containerRoot) continue;
    if (_mixinLeaves.contains(entry.key)) continue;
    final fields = (entry.value as Map<String, dynamic>)['fields'] as List?;
    final declaresContent = (fields ?? const [])
        .any((f) => (f as Map<String, dynamic>)['name'] == 'content');
    if (declaresContent) yield entry.key;
  }
}

/// The body of each emitted `SpecRegistry.register(<Class>, SpecClassOps(…))`,
/// keyed by class name.
///
/// The closing `\n  ));` is only ever produced at a registration's end — every
/// line inside one is indented further — so a non-greedy match to it splits the
/// file exactly at the registration boundaries.
Map<String, String> _readRegistrations(String source) => {
      for (final m in _registrationPattern.allMatches(source))
        m.group(1)!: m.group(2)!,
    };

final RegExp _registrationPattern = RegExp(
    r'  SpecRegistry\.register\((\w+), SpecClassOps\(\n(.*?)\n  \)\);',
    dotAll: true);
