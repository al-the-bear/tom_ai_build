import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A minimal register document with the same shape as the real §22.
const _register = '''
# Some Specification

## 21. Something Else

Prose that mentions nothing.

## 22. Open-Ends Register (`OE-` ids)

Lead-in prose citing `OE-1` so the reader knows what a row looks like.

| Id | What it names | State |
| --- | --- | --- |
| `OE-1` | The first thing. | shipped |
| `OE-1a` | A sub-item of the first thing. | open — CS-15 |
| `OE-2` | The second thing. | shipped |
| `OE-3` | Subsumed, see `OE-2`. | closed |

## 23. After The Register

Trailing prose.
''';

void main() {
  group('OeRegister.parse', () {
    test('reads an id from the first inline-code span of each table row', () {
      final register = OeRegister.parse(_register, path: 'spec.md');

      expect(register.ids, {'OE-1', 'OE-1a', 'OE-2', 'OE-3'});
      expect(register.length, 4);
      expect(register.duplicates, isEmpty);
    });

    test('stops at the next section heading', () {
      final register = OeRegister.parse('''
## 22. Open-Ends Register

| `OE-1` | In. | shipped |

## 23. Next

| `OE-99` | Out — a table in another section. | shipped |
''', path: 'spec.md');

      expect(register.ids, {'OE-1'});
    });

    test('does not define an id mentioned in prose only', () {
      final register = OeRegister.parse('''
## 22. Open-Ends Register

The register once contained `OE-7`, in a paragraph rather than a row.

| `OE-1` | The only row. | shipped |
''', path: 'spec.md');

      expect(register.ids, {'OE-1'});
    });

    test('does not define an id from a later cell of a row', () {
      final register = OeRegister.parse('''
## 22. Open-Ends Register

| `OE-1` | Superseded with `OE-42`. | superseded |
''', path: 'spec.md');

      expect(register.ids, {'OE-1'});
    });

    test('records a duplicated id — an id names one thing only', () {
      final register = OeRegister.parse('''
## 22. Open-Ends Register

| `OE-1` | One meaning. | shipped |
| `OE-1` | A second meaning. | open |
''', path: 'spec.md');

      expect(register.duplicates, ['OE-1']);
    });

    test('throws when the register heading is absent', () {
      expect(
        () => OeRegister.parse('# Spec\n\n## 1. Intro\n', path: 'spec.md'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Open-Ends Register'),
        )),
      );
    });

    test('finds the heading at any section number', () {
      final register =
          OeRegister.parse('## 7. Open-Ends Register\n\n| `OE-4` | x. | open |',
              path: 'spec.md');

      expect(register.ids, {'OE-4'});
    });
  });

  group('findOeCitations', () {
    final register = OeRegister.parse(_register, path: 'spec.md');

    test('matches a bare id in a source comment', () {
      final citations = findOeCitations(
        '// OE-1a: the drop-in point lands here.\nfinal x = 1;\n',
        path: 'a.dart',
        register: register,
      );

      expect(citations, hasLength(1));
      expect(citations.single.id, 'OE-1a');
      expect(citations.single.line, 1);
      expect(citations.single.defined, isTrue);
      expect(citations.single.isViolation, isFalse);
    });

    test('flags an id with no register row', () {
      final citations = findOeCitations(
        'Marked OE-99 in the code.',
        path: 'a.dart',
        register: register,
      );

      expect(citations.single.isViolation, isTrue);
      expect(citations.single.describe(), contains('UNDEFINED'));
    });

    test('distinguishes a sub-id from its parent', () {
      final citations = findOeCitations(
        'OE-1 and OE-1a are different rows.',
        path: 'a.dart',
        register: register,
      );

      expect([for (final c in citations) c.id], ['OE-1', 'OE-1a']);
    });

    test('does not match an id embedded in a longer token', () {
      final citations = findOeCitations(
        'ROE-1 and OE-1x9 are not citations.',
        path: 'a.dart',
        register: register,
      );

      expect(citations, isEmpty);
    });

    test('in the register document, a row does not cite the id it defines', () {
      final citations = findOeCitations(
        '| `OE-1` | The first thing. | shipped |',
        path: 'spec.md',
        register: register,
        inRegisterDocument: true,
      );

      expect(citations, isEmpty);
    });

    test('in the register document, a row still cites other ids', () {
      final citations = findOeCitations(
        '| `OE-3` | Subsumed, see `OE-2`. | closed |',
        path: 'spec.md',
        register: register,
        inRegisterDocument: true,
      );

      expect([for (final c in citations) c.id], ['OE-2']);
    });

    test('in the register document, prose outside a row is a citation', () {
      final citations = findOeCitations(
        'Lead-in prose citing `OE-1`.',
        path: 'spec.md',
        register: register,
        inRegisterDocument: true,
      );

      expect([for (final c in citations) c.id], ['OE-1']);
    });
  });

  group('checkOeCitations', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('oe_citations'));
    tearDown(() => temp.deleteSync(recursive: true));

    File write(String relative, String content) {
      final file = File(p.join(temp.path, relative));
      file.parent.createSync(recursive: true);
      return file..writeAsStringSync(content);
    }

    test('is clean when every citation resolves', () {
      final spec = write('doc/spec.md', _register);
      write('lib/a.dart', '// OE-2 lands here.\n');

      final report = checkOeCitations(
        roots: [p.join(temp.path, 'lib'), spec.path],
        register: OeRegister.read(spec.path),
      );

      expect(report.isClean, isTrue);
      expect(report.citedIds, containsAll(<String>['OE-1', 'OE-2']));
    });

    test('fails on a citation with no register row', () {
      final spec = write('doc/spec.md', _register);
      write('lib/a.dart', '// OE-2 is fine.\n// OE-88 is not.\n');

      final report = checkOeCitations(
        roots: [p.join(temp.path, 'lib')],
        register: OeRegister.read(spec.path),
      );

      expect(report.isClean, isFalse);
      expect(report.violations, hasLength(1));
      expect(report.violations.single.id, 'OE-88');
      expect(report.violations.single.line, 2);
    });

    test('reads only authored file types', () {
      final spec = write('doc/spec.md', _register);
      write('lib/a.png', 'OE-88 inside a binary-ish blob');
      write('lib/a.dart', '// OE-1\n');

      final report = checkOeCitations(
        roots: [p.join(temp.path, 'lib')],
        register: OeRegister.read(spec.path),
      );

      expect(report.fileCount, 1);
      expect(report.isClean, isTrue);
    });

    test('skips generated and downloaded folders', () {
      final spec = write('doc/spec.md', _register);
      write('lib/build/gen.dart', '// OE-88\n');
      write('lib/.dart_tool/x.json', '{"note": "OE-88"}');
      write('lib/a.dart', '// OE-1\n');

      final report = checkOeCitations(
        roots: [p.join(temp.path, 'lib')],
        register: OeRegister.read(spec.path),
      );

      expect(report.fileCount, 1);
      expect(report.isClean, isTrue);
    });

    test('a duplicated register id fails even with no bad citation', () {
      final spec = write('doc/spec.md', '''
## 22. Open-Ends Register

| `OE-1` | One meaning. | shipped |
| `OE-1` | Another. | open |
''');

      final report = checkOeCitations(
        roots: [spec.path],
        register: OeRegister.read(spec.path),
      );

      expect(report.violations, isEmpty);
      expect(report.isClean, isFalse);
    });

    test('throws on a citing root that does not exist', () {
      final spec = write('doc/spec.md', _register);

      expect(
        () => checkOeCitations(
          roots: [p.join(temp.path, 'nowhere')],
          register: OeRegister.read(spec.path),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('the live corpus', () {
    // `dart test` runs from the package root, so the container is three levels
    // up. Deriving it from `Platform.script` would point at the runner's own
    // temporary entry point.
    final containerRoot =
        p.normalize(p.join(Directory.current.path, '..', '..', '..'));

    File resolve(String posixRelative) =>
        File(p.join(containerRoot, p.joinAll(p.posix.split(posixRelative))));

    test('every OE id cited in the corpus resolves to a register row', () {
      final spec = resolve(oeRegisterDocument);
      // Guards the guard: a moved document would otherwise make the check
      // vacuous rather than red.
      expect(spec.existsSync(), isTrue,
          reason: 'register document not found at $oeRegisterDocument');

      final register = OeRegister.read(spec.path);
      final roots = [
        for (final root in defaultCitingRoots) resolve(root).path,
      ].where((path) =>
          File(path).existsSync() || Directory(path).existsSync()).toList();

      final report = checkOeCitations(roots: roots, register: register);

      expect(report.register.duplicates, isEmpty);
      expect(
        [for (final v in report.violations) v.describe(relativeTo: containerRoot)],
        isEmpty,
      );
      // The register exists because the citations do; an empty corpus would
      // pass silently and mean the roots stopped resolving.
      expect(report.citations, isNotEmpty);
    });
  });
}
