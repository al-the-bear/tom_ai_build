/// The guard over the two **committed** `spec_model.json` assets.
///
/// `bin/model_json.dart` writes the same class-graph export to two tracked
/// locations. Nothing used to pair a stamp with its target, so a regeneration
/// pass that re-exported "both assets" with one command rewrote one at the
/// other's version — which is how the editor's copy silently reached
/// `modelVersion: 0`.
///
/// Group 1 pins the target/stamp policy itself. Group 2 checks the assets on
/// disk actually carry it, from the *one* place that can reach both — the
/// reviewer's own suite could only ever see its own copy, which is precisely
/// why the editor's drift went unnoticed. Group 3 checks each stamp against
/// *itself*: `modelVersion` is the major of `modelVersionLabel`, so a stamp
/// that was typed rather than derived is caught even when no second artifact
/// is present to disagree with it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot =
      p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final modelDir = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model'));

  group('committed asset target/stamp policy', () {
    test('the stamp is derived from the model versioner', () {
      final versioner = readModelVersionStamp(modelDir);
      final stamp = ModelJsonStamp.from(versioner);
      expect(stamp.version, versioner.majorVersion);
      expect(stamp.label, versioner.label);
    });

    test('the derived stamp takes the major, never the build number', () {
      // The defect this replaced: `1.0.0+9` was stamped as version 9 — the
      // build number lifted into the major slot — so the asset disagreed with
      // its own label about which model it described. A build that differs in
      // every component makes the confusion impossible to pass by accident.
      const build = ModelVersionStamp(
          version: '42.7.0', buildNumber: 99, gitCommit: 'deadbee');
      final stamp = ModelJsonStamp.from(build);
      expect(stamp.version, 42);
      expect(stamp.label, '42.7.0+99.deadbee');
      expect(stamp.version, modelMajorOfLabel(stamp.label));
    });

    test('both committed assets take the same stamp', () {
      // They are one export of one model, so they can only honestly claim one
      // version. A per-target pin is what let them disagree.
      final versioner = readModelVersionStamp(modelDir);
      final expected = ModelJsonStamp.from(versioner);
      for (final target in ModelJsonTarget.values) {
        expect(ModelJsonStamp.from(versioner).version, expected.version,
            reason: '${target.id} must not carry a stamp of its own');
      }
    });

    test('no two targets share an id or a path', () {
      final paths = ModelJsonTarget.values.map((t) => t.containerRelativePath);
      expect(paths.toSet(), hasLength(ModelJsonTarget.values.length));
      expect(ModelJsonTarget.values.map((t) => t.id).toSet(),
          hasLength(ModelJsonTarget.values.length));
    });

    test('every committed asset path is recognised as its own target', () {
      for (final target in ModelJsonTarget.values) {
        expect(targetForOutputPath(target.outputPathIn(containerRoot)), target);
        expect(ModelJsonTarget.byId(target.id), target);
      }
    });

    test('an ad-hoc export path is governed by no target', () {
      // The recognition is a suffix match, so it must not be so loose that any
      // path ending in `spec_model.json` counts as committed.
      expect(targetForOutputPath(p.join(containerRoot, 'ztmp', 'scratch.json')),
          isNull);
      expect(
          targetForOutputPath(
              p.join(containerRoot, 'ztmp', 'assets', 'spec_model.json')),
          isNull);
      expect(ModelJsonTarget.byId('nonesuch'), isNull);
    });
  });

  group('committed assets on disk carry their target stamp', () {
    final versioner = readModelVersionStamp(modelDir);

    for (final target in ModelJsonTarget.values) {
      final path = target.outputPathIn(containerRoot);
      final file = File(path);

      test('${target.id}: ${target.containerRelativePath}', () {
        if (!file.existsSync()) {
          // The editor lives in a sibling repo (tom_forge); a code-only
          // checkout legitimately lacks it. Skipping beats a false red, but
          // only with the reason stated.
          markTestSkipped('$path is not present in this checkout');
          return;
        }
        final asset =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final expected = ModelJsonStamp.from(versioner);
        expect(asset['modelVersion'], expected.version,
            reason: 'refresh it with `dart run bin/model_json.dart '
                '--target ${target.id}`');
        expect(asset['modelVersionLabel'], expected.label,
            reason: 'refresh it with `dart run bin/model_json.dart '
                '--target ${target.id}`');
        expect(asset['metaSchemaVersion'], specModelMetaSchemaVersion);
        expect(validateSpecModelMeta(asset), isEmpty);
      });
    }

    test('the two assets export the same class graph', () {
      // They differ only by stamp and emission time. If the graphs diverge,
      // one of them was not re-exported and the mismatch is a stale asset, not
      // a stamp problem — worth separating so the failure names the cause.
      final loaded = <ModelJsonTarget, Map<String, dynamic>>{};
      for (final target in ModelJsonTarget.values) {
        final file = File(target.outputPathIn(containerRoot));
        if (file.existsSync()) {
          loaded[target] =
              json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        }
      }
      if (loaded.length < 2) {
        markTestSkipped('needs both committed assets present');
        return;
      }
      final assets = loaded.values.toList();
      for (final key in const ['classCount', 'rootCount', 'containerRoot']) {
        expect(assets.map((a) => a[key]).toSet(), hasLength(1),
            reason: '$key differs between the committed assets — one of them '
                'was not re-exported against the current model');
      }
    });
  });

  group('every committed stamp agrees with its own label', () {
    // The invariant that catches a hand-typed stamp with no second artifact to
    // disagree with it: `modelVersion` is the major of `modelVersionLabel`
    // (SOM §4.2), so any artifact can be checked in isolation. Every historical
    // defect here violates it — `0` (no derivation ran at all) and `8`/`9` (the
    // build *number* lifted into the model *major* slot, beside a label whose
    // major was 1 the whole time).
    final artifacts = <String, String>{
      for (final target in ModelJsonTarget.values)
        target.id: target.outputPathIn(containerRoot),
      for (final lang in const [
        'c', 'cpp', 'dart', 'go', 'java',
        'javascript', 'python', 'rust', 'typescript',
      ])
        'som:$lang': p.join(containerRoot, 'tom_ai', 'ai_build',
            'tom_som_${lang}_v0', 'meta', 'spec_model.meta.json'),
    };

    artifacts.forEach((name, path) {
      test(name, () {
        final file = File(path);
        if (!file.existsSync()) {
          markTestSkipped('$path is not present in this checkout');
          return;
        }
        final stamped =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final label = stamped['modelVersionLabel'] as String?;
        expect(label, isNotNull,
            reason: '$name carries no label, so its counter cannot be checked '
                'against anything');
        expect(stamped['modelVersion'], modelMajorOfLabel(label),
            reason: '$name stamps modelVersion ${stamped['modelVersion']} '
                'beside label "$label" — the counter is the label\'s major, so '
                'these describe two different models');
      });
    });

    test('all committed artifacts carry one model version', () {
      // They are all generated from one model, so a divergence means one of
      // them was not regenerated — separated from the per-artifact check so the
      // failure names staleness rather than a malformed stamp.
      final seen = <String, Set<Object?>>{};
      artifacts.forEach((name, path) {
        final file = File(path);
        if (!file.existsSync()) return;
        final stamped =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        seen.putIfAbsent(name, () => {stamped['modelVersionLabel']});
      });
      final labels = seen.values.expand((s) => s).toSet();
      expect(labels, hasLength(1),
          reason: 'committed artifacts disagree on the model build: $labels');
    });
  });
}
