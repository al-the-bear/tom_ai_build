/// The staleness guard for the generated SOM D4rt bridges.
///
/// The bridges under `lib/src/bridges/` are generated *here* from two path
/// siblings that are edited *elsewhere* (`tom_som_dart_runtime`,
/// `tom_som_dart_v0`). Nothing in those packages' own workflow prompts a regen,
/// so their public surface can move out from under the committed bridges. This
/// suite is the gate that notices.
///
/// See `_copilot_guidelines/bridge_regeneration.md` § "How staleness is caught"
/// for the rule, and `tool/som_surface.dart` for why the fingerprint is taken
/// the way it is.
library;

import 'dart:io';

import 'package:test/test.dart';

import '../tool/som_surface.dart';

void main() {
  final engineRoot = Directory.current.path;

  group('SOM bridge freshness', () {
    test(
      'the fingerprinted packages are exactly the ones buildkit.yaml bridges',
      () {
        // Guards the guard. Adding a third module to the `d4rtgen:` block
        // without adding it to `somPackagePaths` would leave that package
        // unfingerprinted — the freshness test below would keep passing while
        // the surface it is supposed to cover had grown.
        expect(somSurfaceModuleMismatch(engineRoot: engineRoot), isNull);
      },
    );

    test('the committed bridges were generated from the current SOM surface',
        () {
      final stamp = readSomSurfaceStamp(engineRoot: engineRoot);
      expect(
        stamp,
        isNotNull,
        reason: 'No $somSurfaceStampPath found. It is written by '
            '`dart run tool/regenerate_bridges.dart`; run that once to '
            'establish the baseline.',
      );

      final current = computeSomSurface(engineRoot: engineRoot);
      if (current.fingerprint == stamp!.fingerprint) return;

      // Name the package(s) that moved and by how much, so the failure says
      // what to do rather than just that two hex strings differ.
      final moved = <String>[];
      for (final name in current.perPackage.keys) {
        if (current.perPackage[name] == stamp.perPackage[name]) continue;
        final before = stamp.declarationCounts[name];
        final now = current.declarationCounts[name];
        moved.add(
          '  - $name (top-level declarations: $before -> $now)',
        );
      }

      fail(
        'The SOM public surface has changed since the bridges were last '
        'generated:\n${moved.join('\n')}\n\n'
        'The committed bridges in lib/src/bridges/ are therefore stale. '
        'Regenerate them:\n'
        '    dart run tool/regenerate_bridges.dart\n'
        'and commit both the regenerated bridges and the refreshed '
        '$somSurfaceStampPath. If the regen turns out to be a no-op (only the '
        '`// Generated:` header lines differ), discard the bridge diff with '
        '`git checkout -- lib` and commit the stamp alone.\n'
        'See _copilot_guidelines/bridge_regeneration.md.',
      );
    });
  });

  // These prove the fingerprint moves for the right reasons and holds still for
  // the wrong ones. Without them the guard above could be asserting a constant.
  group('surface fingerprint sensitivity', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('som_surface_'));
    tearDown(() => temp.deleteSync(recursive: true));

    String hashOf(String source) {
      final lib = Directory('${temp.path}/lib')
        ..createSync(recursive: true);
      File('${lib.path}/a.dart').writeAsStringSync(source);
      final hash = fingerprintLibrary(lib).hash;
      lib.deleteSync(recursive: true);
      return hash;
    }

    const baseline = '''
/// A doc comment.
class Widget {
  final String name;
  Widget(this.name);
  String describe() {
    return 'widget \$name';
  }
}
''';

    test('an added public member changes the fingerprint', () {
      // The silent-staleness case: nothing else in the workspace goes red for
      // this, because the bridge still compiles — it is just incomplete.
      expect(
        hashOf(baseline.replaceFirst(
          'Widget(this.name);',
          'Widget(this.name);\n  int get width => 0;',
        )),
        isNot(hashOf(baseline)),
      );
    });

    test('a removed public member changes the fingerprint', () {
      expect(
        hashOf(baseline.replaceFirst('  final String name;\n', '')),
        isNot(hashOf(baseline)),
      );
    });

    test('a renamed member changes the fingerprint', () {
      expect(
        hashOf(baseline.replaceFirst('describe()', 'render()')),
        isNot(hashOf(baseline)),
      );
    });

    test('a changed parameter or return type changes the fingerprint', () {
      expect(
        hashOf(baseline.replaceFirst('String describe()', 'Object describe()')),
        isNot(hashOf(baseline)),
      );
    });

    test('rewording a doc comment does not change the fingerprint', () {
      // Comments are `precedingComments` on a token, so a walk along
      // `Token.next` never sees them.
      expect(
        hashOf(baseline.replaceFirst(
          '/// A doc comment.',
          '/// A substantially longer and quite differently worded comment.',
        )),
        hashOf(baseline),
      );
    });

    test('reformatting does not change the fingerprint', () {
      // Whitespace is not tokenised at all.
      expect(
        hashOf(baseline.replaceAll('\n', '\n\n').replaceAll('  ', '    ')),
        hashOf(baseline),
      );
    });

    test('rewriting a method body does not change the fingerprint', () {
      // The generator binds signatures, not implementations.
      expect(
        hashOf(baseline.replaceFirst(
          "    return 'widget \$name';\n",
          "    final parts = ['widget', name];\n    return parts.join(' ');\n",
        )),
        hashOf(baseline),
      );
    });

    test('=> and {} body forms are indistinguishable to the fingerprint', () {
      expect(
        hashOf(baseline.replaceFirst(
          "  String describe() {\n    return 'widget \$name';\n  }\n",
          "  String describe() => 'widget \$name';\n",
        )),
        hashOf(baseline),
      );
    });

    test('a file name change changes the fingerprint', () {
      // The relative path is part of the rendering, so moving a library is a
      // surface change — it moves what the barrel re-exports.
      final lib = Directory('${temp.path}/lib')..createSync(recursive: true);
      File('${lib.path}/a.dart').writeAsStringSync(baseline);
      final before = fingerprintLibrary(lib).hash;
      File('${lib.path}/a.dart').renameSync('${lib.path}/b.dart');
      expect(fingerprintLibrary(lib).hash, isNot(before));
    });
  });
}
