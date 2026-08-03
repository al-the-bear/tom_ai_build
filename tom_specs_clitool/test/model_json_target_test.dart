/// The guard over the two **committed** `spec_model.json` assets.
///
/// `bin/model_json.dart` writes the same class-graph export to two tracked
/// locations that carry different, frozen version stamps. Nothing used to pair
/// a stamp with its target, so a regeneration pass that re-exported "both
/// assets" with one command rewrote one at the other's version — which is how
/// the editor's copy silently reached `modelVersion: 0`.
///
/// Group 1 pins the target/stamp policy itself. Group 2 checks the assets on
/// disk actually carry it, from the *one* place that can reach both — the
/// reviewer's own suite could only ever see its own copy, which is precisely
/// why the editor's drift went unnoticed.
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
    test('the editor target derives its stamp from the model versioner', () {
      final versioner = readModelVersionStamp(modelDir);
      final stamp = ModelJsonTarget.editor.stampFrom(versioner);
      expect(ModelJsonTarget.editor.pinnedStamp, isNull,
          reason: 'the editor asset tracks the build, so it must not be '
              'pinned to a stamp of its own');
      expect(stamp.version, versioner.majorVersion);
      expect(stamp.label, versioner.label);
    });

    test('the reviewer target is pinned and ignores the versioner', () {
      // Refreshing the snapshot is a re-export of the current model, never a
      // renumbering of it, so the reviewer's stamp must not follow a build.
      const otherBuild = ModelVersionStamp(
          version: '42.7.0', buildNumber: 99, gitCommit: 'deadbee');
      final stamp = ModelJsonTarget.reviewer.stampFrom(otherBuild);
      expect(stamp.version, 9);
      expect(stamp.label, '1.0.0+9');
    });

    test('no two targets share a stamp policy or a path', () {
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
        final expected = target.stampFrom(versioner);
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
}
