/// Keeps `README.md`'s `bin/` entrypoint table and the entrypoints themselves
/// in correspondence, in both directions.
///
/// Every other claim this package makes about itself is held by something: the
/// `codespecs_derivation_contract.md` §6 check count by `cs_check_table.dart`,
/// the
/// `tom_specs_model_rules.md` §10.2 invariant list by
/// `invariant_correspondence_test.dart`, the nine-language surface by
/// `model_freshness.dart`, three families of inline citation by three gates. A
/// README sentence saying *what inputs a tool takes* was held by nothing, so it
/// decayed exactly as silently as a citation does — and it is the first thing a
/// reader of the package meets.
///
/// The row *set* was never the problem: every `bin/*.dart` already had a row, so
/// a coverage check alone would have passed over two wrong rows. It is the row
/// *content* that drifts, and the mechanical anchor for it is each entrypoint's
/// own `ArgParser`. So this gate holds both:
///
/// - **the set** — every `bin/*.dart` has a row, every row names a real file;
/// - **the content** — every option an entrypoint declares is named in its row,
///   and every `--flag` a row cites is an option that entrypoint declares.
///
/// The one option excluded is `--help`. It is boilerplate every entrypoint
/// carries and naming it fifteen times documents nothing — but the carve-out is
/// itself held: [compareEntrypointOptions] reports an entrypoint that does *not*
/// declare it, so "excluded because universal" cannot quietly stop being true.
library;

/// One option, flag or multi-option an entrypoint's `ArgParser` declares.
class EntrypointOption {
  /// The option name, without leading dashes.
  final String name;

  /// Whether it was declared with `addFlag` rather than `addOption` /
  /// `addMultiOption`.
  final bool isFlag;

  /// Whether `--no-<name>` is also a valid spelling — true for an `addFlag`
  /// that is not `negatable: false`.
  final bool negatable;

  /// Whether the declaration is `mandatory: true`.
  final bool mandatory;

  /// Creates an option.
  const EntrypointOption({
    required this.name,
    required this.isFlag,
    required this.negatable,
    required this.mandatory,
  });

  /// The spellings a row may legitimately use for this option.
  Set<String> get spellings => {
        '--$name',
        if (isFlag && negatable) '--no-$name',
      };

  @override
  String toString() => '--$name';
}

/// One row of `README.md`'s `bin/` entrypoint table.
class EntrypointRow {
  /// The `<name>.dart` files the first cell names. Exactly one is expected;
  /// [compareEntrypointOptions] reports a row that names several, because such
  /// a row cannot say which of them takes which option.
  final List<String> entrypoints;

  /// Every `--flag` spelling the row cites, from any of its cells.
  final Set<String> citedFlags;

  /// Creates a row.
  const EntrypointRow({required this.entrypoints, required this.citedFlags});

  @override
  String toString() => entrypoints.join(' / ');
}

/// The outcome of one comparison.
class EntrypointCorrespondence {
  /// The rows the README declares, in table order.
  final List<EntrypointRow> rows;

  /// Everything wrong, one line each; empty when the two agree.
  final List<String> problems;

  /// Creates the outcome.
  const EntrypointCorrespondence({required this.rows, required this.problems});

  /// Whether the table and the entrypoints agree.
  bool get isConsistent => problems.isEmpty;
}

/// The option `--help` carries, excluded from the correspondence because every
/// entrypoint declares it and the README documents it once in prose.
const String kUniversalOption = 'help';

final RegExp _addCall =
    RegExp(r"add(Option|Flag|MultiOption)\(\s*'([^']+)'");

/// Parses the options an entrypoint declares out of its Dart [source].
///
/// The parse is textual rather than analyzer-based: every entrypoint builds a
/// plain chained `ArgParser()` with literal option names, so the names are
/// readable without resolving the file, and a gate that needs a resolved
/// element model would cost more than the drift it catches. A declaration whose
/// name is not a literal would go unseen — none exists, and one introduced later
/// would surface as a `--flag` the row cites and the parse cannot find.
List<EntrypointOption> parseEntrypointOptions(String source) {
  final matches = _addCall.allMatches(source).toList();
  final options = <EntrypointOption>[];

  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final kind = match.group(1)!;
    final name = match.group(2)!;
    // The named arguments of this call end where the next chained `..add…`
    // begins; for the last call, the rest of the source is a safe upper bound
    // because `negatable:` / `mandatory:` can only precede its own closing
    // paren, and no later text can reintroduce them without another match.
    final bodyEnd =
        i + 1 < matches.length ? matches[i + 1].start : source.length;
    final body = source.substring(match.end, bodyEnd);

    options.add(
      EntrypointOption(
        name: name,
        isFlag: kind == 'Flag',
        negatable: kind == 'Flag' && !body.contains('negatable: false'),
        mandatory: body.contains('mandatory: true'),
      ),
    );
  }
  return options;
}

final RegExp _backticked = RegExp(r'`([^`]+)`');

/// A flag citation. Segments are alphanumeric, so a wildcard like
/// `` `--regenerated-*` `` yields `--regenerated` and is then reported as a flag
/// nothing declares. That is deliberate: a row that gestures at a family of
/// options instead of naming them is exactly the vagueness the two drifted rows
/// hid behind — one of them summarised nine inputs as "two".
final RegExp _flagToken = RegExp(r'--[a-z0-9]+(?:-[a-z0-9]+)*');
final RegExp _dartFile = RegExp(r'`([A-Za-z0-9_]+\.dart)`');

/// Parses the `bin/` entrypoint table out of the README in [markdown].
///
/// The parse is anchored on the sentence that introduces the table rather than
/// on the table shape, so the `tool/` table below it — which documents scripts
/// with no `ArgParser` of their own — is not mistaken for this one.
List<EntrypointRow> parseEntrypointRows(String markdown) {
  const anchor = 'Related entrypoints in `bin/`';
  final lines = markdown.split('\n');
  final start = lines.indexWhere((l) => l.contains(anchor));
  if (start < 0) return const [];

  final rows = <EntrypointRow>[];
  var seenTable = false;
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (!line.startsWith('|')) {
      if (seenTable) break;
      continue;
    }
    seenTable = true;

    final cells = line.split('|').map((c) => c.trim()).toList();
    if (cells.length < 3) continue;

    final entrypoints = _dartFile
        .allMatches(cells[1])
        .map((m) => m.group(1)!)
        .toList();
    // The header row and its `| --- |` separator name no `.dart` file, so they
    // fall out here rather than needing a shape rule of their own.
    if (entrypoints.isEmpty) continue;

    final cited = <String>{};
    for (final cell in cells.skip(2)) {
      for (final span in _backticked.allMatches(cell)) {
        cited.addAll(
          _flagToken.allMatches(span.group(1)!).map((m) => m.group(0)!),
        );
      }
    }
    rows.add(EntrypointRow(entrypoints: entrypoints, citedFlags: cited));
  }
  return rows;
}

/// Compares the README's `bin/` table in [markdown] against the entrypoint
/// sources in [sources], keyed by file name (`outliner.dart`).
EntrypointCorrespondence compareEntrypointOptions({
  required String markdown,
  required Map<String, String> sources,
}) {
  final rows = parseEntrypointRows(markdown);
  final problems = <String>[];

  if (rows.isEmpty) {
    problems.add(
      'README.md declared no entrypoint rows — the parser looks for a markdown '
      'table under the sentence "Related entrypoints in `bin/`"',
    );
    return EntrypointCorrespondence(rows: rows, problems: problems);
  }

  final documented = <String, EntrypointRow>{};
  for (final row in rows) {
    if (row.entrypoints.length > 1) {
      problems.add(
        'README.md gives one row to ${row.entrypoints.join(' and ')} — a shared '
        'row cannot say which of them takes which option, and that blur is how '
        'two rows drifted unnoticed in the first place',
      );
    }
    for (final entrypoint in row.entrypoints) {
      documented[entrypoint] = row;
    }
  }

  for (final entrypoint in documented.keys) {
    if (sources.containsKey(entrypoint)) continue;
    problems.add(
      'README.md has a row for $entrypoint, which is not in bin/ — a row for a '
      'file that is gone still reads as a tool a reader can run',
    );
  }

  for (final entry in sources.entries) {
    final entrypoint = entry.key;
    final options = parseEntrypointOptions(entry.value);

    if (!options.any((o) => o.name == kUniversalOption)) {
      problems.add(
        'bin/$entrypoint declares no --$kUniversalOption — that option is left '
        'out of this correspondence because every entrypoint carries it, so an '
        'entrypoint without one invalidates the exclusion rather than being '
        'excused by it',
      );
    }

    final row = documented[entrypoint];
    if (row == null) {
      problems.add(
        'bin/$entrypoint has no row in README.md\'s entrypoint table — an '
        'undocumented entrypoint is one nobody knows to run, and the table is '
        'the first thing a reader of the package meets',
      );
      continue;
    }

    for (final option in options) {
      if (option.name == kUniversalOption) continue;
      if (row.citedFlags.intersection(option.spellings).isNotEmpty) continue;
      problems.add(
        'bin/$entrypoint declares --${option.name} and its README row never '
        'names it — a reader who trusts the row runs the tool with part of its '
        'input surface and gets a clean-looking result over work it skipped',
      );
    }

    final declared = {for (final o in options) ...o.spellings};
    for (final cited in row.citedFlags) {
      if (declared.contains(cited)) continue;
      problems.add(
        'README.md\'s $entrypoint row cites $cited, which the entrypoint does '
        'not declare — the row describes a tool it no longer documents',
      );
    }
  }

  return EntrypointCorrespondence(rows: rows, problems: problems);
}
