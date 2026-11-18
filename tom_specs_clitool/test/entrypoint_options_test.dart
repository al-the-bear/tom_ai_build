import 'dart:io';

import 'package:test/test.dart';

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
/// commands' declared options in correspondence, both ways.
///
/// It is a test and not a CLI on purpose. The three citation gates ship both
/// because an operator runs them — `tool/regenerate_outlines.sh` does — but
/// nobody runs a README-currency check by hand, so a second entry point would
/// be a surface to maintain with no caller.
///
/// The live case runs against the real README and the real commands, so an option
/// added without a row mention — or a row citing a flag that has been renamed
/// away — fails here. The synthetic cases pin each failure mode independently of
/// the real files, so they keep testing the same thing when the commands
/// change.
void main() {
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
          '| Command | What it does | Options |\n'
          '| --- | --- | --- |\n'
          '| `:a-b` | Does it | `--one` `--two` |\n'
          '| `:c` | Other | — |\n\n'
          '### What each command does\n\n'
          '| `:d` | Not here | `--three` |\n',
        );
        expect(found, {
          'a-b': {'one', 'two'},
          'c': <String>{},
        });
      },
    );
  });
}
