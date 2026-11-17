import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

import '../bin/tomspecs.dart';

/// The `tomspecs` command table of `README.md` (§ The `tomspecs` binary):
/// each row's command and the `--option`s its Options column names.
Map<String, Set<String>> tomspecsTableRows(String markdown) {
  final start = markdown.indexOf('### The `tomspecs` binary');
  if (start < 0) return const {};
  final end = markdown.indexOf('\n### ', start + 1);
  final section = markdown.substring(start, end < 0 ? markdown.length : end);
  final rows = <String, Set<String>>{};
  for (final line in section.split('\n')) {
    final m = RegExp(r'^\| `:([a-z0-9-]+)` \|').firstMatch(line);
    if (m == null) continue;
    final cells = line.split(' | ');
    final options = cells.isEmpty ? '' : cells.last;
    rows[m.group(1)!] = {
      for (final o in RegExp(r'`--([a-z0-9-]+)`').allMatches(options))
        o.group(1)!,
    };
  }
  return rows;
}

/// The gate that keeps `README.md`'s `tomspecs` command table and the
/// commands' declared options in correspondence, both ways; and, until the
/// tools' own `bin/` entrypoints go, its `bin/` entrypoint table and the
/// entrypoints' own `ArgParser`s.
///
/// It is a test and not a CLI on purpose. The three citation gates ship both
/// because an operator runs them — `tool/regenerate_outlines.sh` does — but
/// nobody runs a README-currency check by hand, so a second entry point would
/// be a surface to maintain with no caller.
///
/// The live case runs against the real README and the real `bin/`, so an option
/// added without a row mention — or a row citing a flag that has been renamed
/// away — fails here. The synthetic cases pin each failure mode independently of
/// the real files, so they keep testing the same thing after the package's
/// entrypoints move on.
void main() {
  final binDir = Directory('${Directory.current.path}/bin');
  final readme = File('${Directory.current.path}/README.md');

  group('README tomspecs table ↔ the commands\' declared options', () {
    final rows = tomspecsTableRows(readme.readAsStringSync());

    test('every command has a row, and every row a command', () {
      expect(rows.keys.toSet(), {for (final c in tomspecsCommands) c.name});
      expect(
        {for (final c in tomspecsTool.commands) c.name},
        {for (final c in tomspecsCommands) c.name},
      );
    });

    test('each row names exactly the options its command declares', () {
      final problems = <String>[];
      for (final c in tomspecsTool.commands) {
        final declared = {for (final o in c.options) o.name};
        final named = rows[c.name] ?? const <String>{};
        for (final o in declared.difference(named)) {
          problems.add(':${c.name} declares --$o, which its row does not name');
        }
        for (final o in named.difference(declared)) {
          problems.add(
            ':${c.name}\'s row names --$o, which it does not declare',
          );
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test(
      'the table reader finds rows and options, and only in its section',
      () {
        final found = tomspecsTableRows(
          '### The `tomspecs` binary\n\n'
          '| Command | Replaces | What it does | Options |\n'
          '| --- | --- | --- | --- |\n'
          '| `:a-b` | `x` | Does it | `--one` `--two` |\n'
          '| `:c` | `y` | Other | — |\n\n'
          '### Entrypoints\n\n'
          '| `:d` | `z` | Not here | `--three` |\n',
        );
        expect(found, {
          'a-b': {'one', 'two'},
          'c': <String>{},
        });
      },
    );
  });

  // An entrypoint whose option set lives in a library names that file in an
  // `// entrypoint-options: <path>` line; its text is read as part of the
  // entrypoint, so the correspondence still holds against the real parser.
  String withOptionSource(String source) {
    final m = RegExp(
      r'^// entrypoint-options: (\S+)$',
      multiLine: true,
    ).firstMatch(source);
    if (m == null) return source;
    return '$source\n${File('${Directory.current.path}/${m.group(1)}').readAsStringSync()}';
  }

  // `tomspecs.dart` declares its options through tom_build_base and is held
  // by the group above.
  Map<String, String> realSources() => {
    for (final f in binDir.listSync().whereType<File>())
      if (f.path.endsWith('.dart') && !f.path.endsWith('/tomspecs.dart'))
        f.uri.pathSegments.last: withOptionSource(f.readAsStringSync()),
  };

  group('README bin/ table ↔ entrypoint ArgParser correspondence', () {
    test('the real table and the real entrypoints agree', () {
      final report = compareEntrypointOptions(
        markdown: readme.readAsStringSync(),
        sources: realSources(),
      );

      expect(report.problems, isEmpty, reason: report.problems.join('\n'));
    });

    test('every bin/ entrypoint is covered by a row', () {
      final report = compareEntrypointOptions(
        markdown: readme.readAsStringSync(),
        sources: realSources(),
      );
      final documented = {for (final row in report.rows) ...row.entrypoints};

      expect(documented, containsAll(realSources().keys));
    });

    test('an option with no mention in its row is reported', () {
      final report = compareEntrypointOptions(
        markdown: _tableOf({'demo.dart': 'Does a thing with `--kept`.'}),
        sources: {
          'demo.dart': _parserOf(["'kept'", "'dropped'"]),
        },
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains('declares --dropped and its README row never names it'),
      );
    });

    test(
      'a flag the row cites and the entrypoint does not declare is reported',
      () {
        final report = compareEntrypointOptions(
          markdown: _tableOf({'demo.dart': 'Takes `--kept` and `--vanished`.'}),
          sources: {
            'demo.dart': _parserOf(["'kept'"]),
          },
        );

        expect(report.isConsistent, isFalse);
        expect(
          report.problems.single,
          contains('cites --vanished, which the entrypoint does not declare'),
        );
      },
    );

    test('an entrypoint with no row at all is reported', () {
      final report = compareEntrypointOptions(
        markdown: _tableOf({'demo.dart': 'Does a thing with `--kept`.'}),
        sources: {
          'demo.dart': _parserOf(["'kept'"]),
          'orphan.dart': _parserOf(["'solo'"]),
        },
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains("bin/orphan.dart has no row in README.md's entrypoint table"),
      );
    });

    test('a row for a file that is no longer in bin/ is reported', () {
      final report = compareEntrypointOptions(
        markdown: _tableOf({'gone.dart': 'Did a thing.'}),
        sources: {},
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains('has a row for gone.dart, which is not in bin/'),
      );
    });

    test('a row documenting two entrypoints at once is reported', () {
      final report = compareEntrypointOptions(
        markdown: _tableOf({
          '`one.dart` / `two.dart`': 'Both take `--shared`.',
        }, literalFirstCell: true),
        sources: {
          'one.dart': _parserOf(["'shared'"]),
          'two.dart': _parserOf(["'shared'"]),
        },
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains('gives one row to one.dart and two.dart'),
      );
    });

    test('a wildcard flag reference does not count as naming the family', () {
      final report = compareEntrypointOptions(
        markdown: _tableOf({'demo.dart': 'Takes the two `--out-*` paths.'}),
        sources: {
          'demo.dart': _parserOf(["'out-a'", "'out-b'"]),
        },
      );

      expect(report.isConsistent, isFalse);
      expect(report.problems, hasLength(3));
      expect(report.problems, contains(contains('cites --out,')));
      expect(report.problems, contains(contains('declares --out-a')));
      expect(report.problems, contains(contains('declares --out-b')));
    });

    test('--no-x satisfies a negatable flag, and only a negatable one', () {
      const negatable = '''
final parser = ArgParser()
  ..addFlag('defaults', defaultsTo: true, help: 'x.')
  ..addFlag('help', abbr: 'h', negatable: false);
''';
      final good = compareEntrypointOptions(
        markdown: _tableOf({'demo.dart': '`--no-defaults` turns it off.'}),
        sources: {'demo.dart': negatable},
      );
      expect(good.problems, isEmpty, reason: good.problems.join('\n'));

      final bad = compareEntrypointOptions(
        markdown: _tableOf({'demo.dart': '`--no-strict` turns it off.'}),
        sources: {
          'demo.dart': negatable.replaceFirst(
            "..addFlag('defaults', defaultsTo: true, help: 'x.')",
            "..addFlag('strict', negatable: false, help: 'x.')",
          ),
        },
      );
      expect(bad.isConsistent, isFalse);
      expect(bad.problems, contains(contains('cites --no-strict')));
    });

    test('an entrypoint that declares no --help invalidates the exclusion', () {
      final report = compareEntrypointOptions(
        markdown: _tableOf({'demo.dart': 'Takes `--kept`.'}),
        sources: {
          'demo.dart': "final parser = ArgParser()..addOption('kept');",
        },
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains('declares no --$kUniversalOption'),
      );
    });

    test('the tool/ table below is not parsed as part of the bin/ table', () {
      final report = compareEntrypointOptions(
        markdown:
            '${_tableOf({'demo.dart': 'Takes `--kept`.'})}\n'
            'And in `tool/` — two scripts:\n\n'
            '| Entry | Purpose | Re-run when |\n'
            '| --- | --- | --- |\n'
            '| `regenerate_outlines.sh` | Renders `--everything`. | Always. |\n',
        sources: {
          'demo.dart': _parserOf(["'kept'"]),
        },
      );

      expect(report.rows, hasLength(1));
      expect(report.problems, isEmpty, reason: report.problems.join('\n'));
    });
  });
}

/// A minimal chained `ArgParser` declaring [names] plus the universal `--help`.
String _parserOf(List<String> names) {
  final calls = names.map((n) => "  ..addOption($n, help: 'x.')").join('\n');
  return 'final parser = ArgParser()\n$calls\n'
      "  ..addFlag('help', abbr: 'h', negatable: false);\n";
}

/// A README fragment carrying the anchor sentence and one row per entry of
/// [rows]. Keys are entrypoint file names unless [literalFirstCell] is set, in
/// which case they are written into the first cell as given.
String _tableOf(Map<String, String> rows, {bool literalFirstCell = false}) {
  final buffer = StringBuffer()
    ..writeln('Related entrypoints in `bin/`:')
    ..writeln()
    ..writeln('| Entrypoint | Purpose | Options |')
    ..writeln('| --- | --- | --- |');
  for (final entry in rows.entries) {
    final first = literalFirstCell ? entry.key : '`${entry.key}`';
    buffer.writeln('| $first | ${entry.value} | |');
  }
  return buffer.toString();
}
