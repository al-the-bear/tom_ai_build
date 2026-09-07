/// Tests for the shipped-script path check (lib/src/shipped_script_paths.dart).
///
/// SSP1 is the live gate: it scans the real publishable packages in the default
/// `dart test` run, so an example that starts reading a sibling project goes
/// red here rather than being found by the next person who tries to reuse the
/// document — which is how it was found the first two times.
/// SSP2 holds the scanner's rules against fixtures.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The publishable set, mirroring `bin/check_shipped_paths.dart`.
const _packages = [
  'tom_ai/ai_build/tom_som_dart_v0',
  'tom_ai/ai_build/tom_som_dart_runtime',
  'tom_ai/ai_build/tom_specs_core',
  'tom_ai/ai_build/tom_specs_model',
  'tom_ai/ai_build/tom_specs_clitool',
  'tom_ai/ai_build/tom_code_specs',
  'tom_ai/ai_build/tom_doc_scanner',
  'tom_ai/ai_build/tom_doc_specs',
  'tom_ai/core/tom_core_codespecs',
];

void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));

  group('SSP1: the live packages', () {
    test('no shipped script reads a path outside its own package', () {
      final findings = <String>[];
      var scanned = 0;
      for (final rel in _packages) {
        final dir = Directory(p.join(containerRoot, rel));
        expect(
          dir.existsSync(),
          isTrue,
          reason: 'package missing: ${dir.path}',
        );
        scanned++;
        findings.addAll(
          findEscapingPaths(dir).map((e) => '$rel/${e.describe()}'),
        );
      }
      expect(scanned, _packages.length);
      expect(
        findings,
        isEmpty,
        reason:
            'a shipped script is the first thing a consumer runs, and from a '
            'hosted install these paths name files that are not there. Ship '
            'the data inside the package, or take the script out of the '
            'archive with a .pubignore entry if it is a workspace tool.',
      );
    });

    test(
      'the Meridian document ships with the package that examples load it from',
      () {
        // The concrete regression: three of six examples could not run because
        // this file lived in an unpublished sibling project.
        final doc = File(
          p.join(
            containerRoot,
            'tom_ai/ai_build/tom_som_dart_v0/documents/'
            'meridian_order_management.docspecs.yaml',
          ),
        );
        expect(doc.existsSync(), isTrue);
        expect(doc.lengthSync(), greaterThan(10000));
      },
    );
  });

  group('SSP2: what counts as an escaping literal', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('shipped_paths_'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String rel, String content) {
      final f = File(p.join(root.path, rel));
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    }

    test('a literal reaching outside the package is reported', () {
      write('example/a.dart', "var f = File('../../elsewhere/thing.yaml');");
      final found = findEscapingPaths(root);
      expect(found, hasLength(1));
      expect(found.single.literal, '../../elsewhere/thing.yaml');
      expect(found.single.line, 1);
    });

    test(
      'a literal resolving inside the package from the SCRIPT dir passes',
      () {
        // `Platform.script.resolve('../documents/x')` from example/ — the shape
        // the three examples now use.
        write('documents/x.yaml', 'a: 1');
        write('example/a.dart', "var f = File('../documents/x.yaml');");
        expect(findEscapingPaths(root), isEmpty);
      },
    );

    test(
      'a literal resolving inside the package from the PACKAGE ROOT passes',
      () {
        // `File('../documents/x')` run with cwd = package root would escape, but
        // the same literal read from bin/ resolves inside. Both bases are tried
        // because which one applies is not visible from the literal.
        write('documents/x.yaml', 'a: 1');
        write('bin/a.dart', "var f = File('../documents/x.yaml');");
        expect(findEscapingPaths(root), isEmpty);
      },
    );

    test(
      'a path that exists nowhere is reported even if it does not climb out',
      () {
        write('example/a.dart', "var f = File('../documents/absent.yaml');");
        expect(findEscapingPaths(root), hasLength(1));
      },
    );

    test('comments and directives are not scanned', () {
      // A doc comment may name a neighbour; an early draft of this check
      // reported `../meta/…` out of one, ellipsis and all. A directive's target
      // is a build error when wrong, so this check adds nothing there.
      write('example/a.dart', '''
// see ../../tom_som_conformance/samples/x.yaml
/// and ../meta/…
import '../../other/lib.dart';
export '../../other/lib.dart';
''');
      expect(findEscapingPaths(root), isEmpty);
    });

    test('a non-climbing literal is not scanned at all', () {
      write('example/a.dart', "var f = File('documents/absent.yaml');");
      expect(
        findEscapingPaths(root),
        isEmpty,
        reason: 'a path that never climbs cannot leave the package',
      );
    });

    test('only the shipped script directories are scanned', () {
      write('test/a.dart', "var f = File('../../elsewhere/thing.yaml');");
      write('lib/a.dart', "var f = File('../../elsewhere/thing.yaml');");
      expect(findEscapingPaths(root), isEmpty);
    });

    test('all four script directories are scanned', () {
      for (final d in shippedScriptDirs) {
        write('$d/a.dart', "var f = File('../../elsewhere/thing.yaml');");
      }
      expect(findEscapingPaths(root), hasLength(shippedScriptDirs.length));
    });

    test('a .pubignore-d directory is out of scope', () {
      write('tool/a.dart', "var f = File('../../elsewhere/thing.yaml');");
      expect(findEscapingPaths(root), hasLength(1));
      write('.pubignore', '# a comment\ntool/\n');
      expect(
        findEscapingPaths(root),
        isEmpty,
        reason: 'an unshipped workspace tool may read the workspace',
      );
    });

    test('reading a .pubignore that is absent yields no exclusions', () {
      expect(readPubignoreDirs(root), isEmpty);
    });

    test('a pattern the reader cannot understand leaves the dir in scope', () {
      // Failing towards checking too much: an unreadable exclusion must not
      // silently remove a directory from the gate.
      write('.pubignore', '*.dart\n');
      expect(readPubignoreDirs(root), isEmpty);
    });

    test('double-quoted literals are scanned too', () {
      write('example/a.dart', 'var f = File("../../elsewhere/thing.yaml");');
      expect(findEscapingPaths(root), hasLength(1));
    });

    test('a missing package yields no findings rather than throwing', () {
      expect(
        findEscapingPaths(Directory(p.join(root.path, 'absent'))),
        isEmpty,
      );
    });
  });
}
