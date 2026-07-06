import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Unit tests for the SD-2 / item-3 serialization-order library
/// (`src/serialization_order.dart`): the pure AST restamper
/// [stampSerializationOrder] and the pure verifier [unstampedMembers] that the
/// SOM generator runs as its mandatory first step.
///
/// The restamper is exercised over a throw-away temp package (only `lib/src`
/// need exist — it is a pure syntactic rewrite, no `pub get` / resolution), so
/// these tests stay lightweight. The verifier is exercised over synthetic
/// [ModelClass] maps so the offender-detection contract is pinned without
/// analysing a real package.
void main() {
  // ---------------------------------------------------------------------------
  // stampSerializationOrder — pure AST restamper
  // ---------------------------------------------------------------------------

  group('stampSerializationOrder', () {
    /// Writes [content] to `<pkg>/lib/src/<name>` in a fresh temp package and
    /// returns the package root; the caller stamps it.
    Directory makePackage(String name, String content) {
      final dir = Directory.systemTemp.createTempSync('som_stamp_test_');
      final srcDir = Directory(p.join(dir.path, 'lib', 'src'))
        ..createSync(recursive: true);
      File(p.join(srcDir.path, name)).writeAsStringSync(content);
      return dir;
    }

    test('SD2-U1: stamps every instance member 0-based in source order', () {
      final pkg = makePackage('model.dart', '''
class Alpha {
  final String a;
  final int b;
  final bool c;
  Alpha(this.a, this.b, this.c);
}
''');
      addTearDown(() => pkg.deleteSync(recursive: true));

      final result = stampSerializationOrder(packagePath: pkg.path);
      expect(result.filesChanged, 1);
      expect(result.membersStamped, 3);
      expect(result.membersRestamped, 0);

      final out =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();
      expect(out, contains('@SerializationOrder(0)'));
      expect(out, contains('@SerializationOrder(1)'));
      expect(out, contains('@SerializationOrder(2)'));
      // Ordinals follow declaration order: a→0, b→1, c→2.
      expect(out.indexOf('@SerializationOrder(0)'),
          lessThan(out.indexOf('String a')));
      expect(out.indexOf('@SerializationOrder(1)'),
          lessThan(out.indexOf('int b')));
      // The annotation home is imported into a file that had no imports.
      expect(out, contains("import 'package:tom_specs_core/tom_specs_core.dart';"));
    });

    test('SD2-U2: static members are not stamped', () {
      final pkg = makePackage('model.dart', '''
class Beta {
  static const String kind = 'beta';
  final String a;
  Beta(this.a);
}
''');
      addTearDown(() => pkg.deleteSync(recursive: true));

      final result = stampSerializationOrder(packagePath: pkg.path);
      // Only the instance field `a` is stamped, at ordinal 0.
      expect(result.membersStamped, 1);
      final out =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();
      expect(out, contains('@SerializationOrder(0)'));
      expect(out, isNot(contains('@SerializationOrder(1)')));
      // The static field keeps no ordinal.
      final kindLine = out
          .split('\n')
          .firstWhere((l) => l.contains("kind = 'beta'"));
      expect(kindLine, isNot(contains('SerializationOrder')));
    });

    test('SD2-U3: re-run renumbers cleanly (idempotent, restamp counted)', () {
      final pkg = makePackage('model.dart', '''
class Gamma {
  final String a;
  final int b;
  Gamma(this.a, this.b);
}
''');
      addTearDown(() => pkg.deleteSync(recursive: true));

      final first = stampSerializationOrder(packagePath: pkg.path);
      expect(first.membersStamped, 2);
      expect(first.membersRestamped, 0);
      final afterFirst =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();

      // A second run strips the old ordinals and rewrites identical ones.
      final second = stampSerializationOrder(packagePath: pkg.path);
      expect(second.membersRestamped, 2,
          reason: 'the two pre-existing ordinals are removed & rewritten');
      final afterSecond =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();
      expect(afterSecond, afterFirst,
          reason: 'restamping unchanged source is byte-stable');
      // Exactly one ordinal each — no accumulation.
      expect('@SerializationOrder(0)'.allMatches(afterSecond).length, 1);
      expect('@SerializationOrder(1)'.allMatches(afterSecond).length, 1);
    });

    test('SD2-U4: dry-run reports counts without writing', () {
      final pkg = makePackage('model.dart', '''
class Delta {
  final String a;
  Delta(this.a);
}
''');
      addTearDown(() => pkg.deleteSync(recursive: true));

      final before =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();
      final result = stampSerializationOrder(packagePath: pkg.path, dryRun: true);
      expect(result.filesChanged, 1);
      expect(result.membersStamped, 1);
      final after =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();
      expect(after, before, reason: 'dry-run must not touch the file');
    });

    test('SD2-U5: per-class ordinals reset across two classes', () {
      final pkg = makePackage('model.dart', '''
class One {
  final String a;
  final int b;
  One(this.a, this.b);
}
class Two {
  final String x;
  Two(this.x);
}
''');
      addTearDown(() => pkg.deleteSync(recursive: true));

      stampSerializationOrder(packagePath: pkg.path);
      final out =
          File(p.join(pkg.path, 'lib', 'src', 'model.dart')).readAsStringSync();
      // One: a→0, b→1; Two: x→0. So ordinal 0 appears twice, 1 once.
      expect('@SerializationOrder(0)'.allMatches(out).length, 2);
      expect('@SerializationOrder(1)'.allMatches(out).length, 1);
    });

    test('SD2-U6: missing lib/src throws StateError', () {
      final dir = Directory.systemTemp.createTempSync('som_stamp_empty_');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(() => stampSerializationOrder(packagePath: dir.path),
          throwsA(isA<StateError>()));
    });
  });

  // ---------------------------------------------------------------------------
  // unstampedMembers — pure verifier over reflected fields
  // ---------------------------------------------------------------------------

  group('unstampedMembers', () {
    ModelField stamped(String name, int order) => ModelField(
          name: name,
          typeName: 'String',
          annotations: [AnnotationData('SerializationOrder', {'order': order})],
        );
    ModelField bare(String name) =>
        ModelField(name: name, typeName: 'String');

    test('SD2-U7: fully-stamped model reports no offenders', () {
      final classes = {
        'Alpha': ModelClass(
          name: 'Alpha',
          annotations: const [],
          fields: [stamped('a', 0), stamped('b', 1)],
        ),
        'Beta': ModelClass(
          name: 'Beta',
          annotations: const [],
          fields: [stamped('x', 0)],
        ),
      };
      expect(unstampedMembers(classes), isEmpty);
    });

    test('SD2-U8: any un-stamped member is flagged as Class.member, sorted', () {
      final classes = {
        'Beta': ModelClass(
          name: 'Beta',
          annotations: const [],
          fields: [stamped('x', 0), bare('y')],
        ),
        'Alpha': ModelClass(
          name: 'Alpha',
          annotations: const [],
          fields: [bare('a'), stamped('b', 1)],
        ),
      };
      // Offenders are class-then-field sorted: Alpha.a before Beta.y.
      expect(unstampedMembers(classes), ['Alpha.a', 'Beta.y']);
    });
  });
}
