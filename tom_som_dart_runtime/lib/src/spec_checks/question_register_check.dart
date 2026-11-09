// Keeps a project's question index (a markdown file with an `## Index` table
// and a `## Not in the Blueprint` table) in step with the question blocks in
// the Blueprint. Which id prefixes it counts, the count columns of its status
// table and the statuses it knows are the project's
// (`<spec-root>/checks/question_register.yaml`, [QuestionRegisterConfig]).
//
// The index is maintained by hand while answers are applied: a row's status
// changes, an answered question moves to "Not in the Blueprint", a new
// question gets a row. This check reads the Blueprint's `**❓ BQ-nn —` blocks
// and the index and reports where they disagree; it recomputes the status
// counts and the sentence below them, and with `write` rewrites them.
//
// The question blocks are read by the runtime's review-annotation API
// (`SpecReviewAnnotations`, SOM §11.9.2), not parsed here. It reads the YAML
// text as one markdown value: the blocks of the YAML's values are blockquotes
// whose indentation the runtime ignores, and a block's line is then its line
// in the file. A question header the runtime cannot read is a finding.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:yaml/yaml.dart';

final RegExp _pipe = RegExp(r'(?<!\\)\|');

/// One count column of the status table: the ids of [prefix] numbered from
/// [from] to [to] (each bound optional).
class QuestionRegisterGroup {
  /// Binds the column's [label], the ids it counts and its [key].
  const QuestionRegisterGroup({
    required this.key,
    required this.label,
    required this.prefix,
    this.from,
    this.to,
  });

  /// The column's key, as the counts address it.
  final String key;

  /// The column header; `{max}` stands for the highest number of [prefix]
  /// in the index (`BQ-78 to BQ-{max}`).
  final String label;

  /// The id prefix the column counts (`BQ`).
  final String prefix;

  /// The lowest number the column counts, or null for no lower bound.
  final int? from;

  /// The highest number the column counts, or null for no upper bound.
  final int? to;

  /// Whether the id [prefix]-[number] falls in this column.
  bool holds(String idPrefix, int number) =>
      idPrefix == prefix &&
      (from == null || number >= from!) &&
      (to == null || number <= to!);
}

/// One status of the index: its [key] (the status's first word), the [label]
/// the index and the table write, and whether a question in it still [waiting]
/// for an answer keeps its block in the Blueprint.
class QuestionRegisterStatus {
  /// Binds the status.
  const QuestionRegisterStatus(this.key, this.label, {this.waiting = false});

  /// The status's first word, as the counts group it.
  final String key;

  /// The status as the index writes it (`implemented on WA`).
  final String label;

  /// Whether a question in this status waits for an answer: its block must
  /// be in the Blueprint, and the table counts it with its ★.
  final bool waiting;
}

/// A project's conventions for its question index
/// (`<spec-root>/checks/question_register.yaml`).
class QuestionRegisterConfig {
  /// Binds the id [prefixes], the table's [groups] and the [statuses].
  const QuestionRegisterConfig({
    required this.prefixes,
    required this.groups,
    required this.statuses,
  });

  /// What a project without a configuration gets: every upper-case prefix,
  /// one column per prefix the index uses, and the statuses `open`
  /// (waiting), `answered`, `obsolete` and `duplicate`.
  static const QuestionRegisterConfig defaults = QuestionRegisterConfig(
    prefixes: [],
    groups: [],
    statuses: [
      QuestionRegisterStatus('open', 'open', waiting: true),
      QuestionRegisterStatus('answered', 'answered'),
      QuestionRegisterStatus('obsolete', 'obsolete'),
      QuestionRegisterStatus('duplicate', 'duplicate'),
    ],
  );

  /// Reads a configuration: `prefixes` (a list), `groups` (a list of
  /// `{key, label, prefix, from?, to?}`) and `statuses` (a list of
  /// `{key, label, waiting?}`); each missing key keeps its default.
  factory QuestionRegisterConfig.parse(String yamlText) {
    final root = loadYaml(yamlText);
    if (root is! YamlMap) return defaults;
    final prefixes = root['prefixes'] is YamlList
        ? [for (final p in root['prefixes'] as YamlList) '$p']
        : defaults.prefixes;
    final groups = root['groups'] is YamlList
        ? [
            for (final g in root['groups'] as YamlList)
              QuestionRegisterGroup(
                key: '${(g as YamlMap)['key']}',
                label: '${g['label']}',
                prefix: '${g['prefix']}',
                from: g['from'] as int?,
                to: g['to'] as int?,
              ),
          ]
        : defaults.groups;
    final statuses = root['statuses'] is YamlList
        ? [
            for (final st in root['statuses'] as YamlList)
              QuestionRegisterStatus(
                '${(st as YamlMap)['key']}',
                '${st['label'] ?? st['key']}',
                waiting: st['waiting'] == true,
              ),
          ]
        : defaults.statuses;
    return QuestionRegisterConfig(
      prefixes: prefixes,
      groups: groups,
      statuses: statuses,
    );
  }

  /// The id prefixes the check reads; empty for every upper-case prefix.
  final List<String> prefixes;

  /// The count columns of the status table; empty for one per prefix.
  final List<QuestionRegisterGroup> groups;

  /// The statuses, in the table's order.
  final List<QuestionRegisterStatus> statuses;

  String get _prefixPattern =>
      prefixes.isEmpty ? '[A-Z][A-Z0-9]*' : prefixes.join('|');

  /// Whether [id] is a question id of this register.
  bool isQuestionId(String id) =>
      RegExp('^(?:$_prefixPattern)-\\d+\$').hasMatch(id);

  /// An index row's id at the start of [line], or null.
  String? rowId(String line) =>
      RegExp('^\\| ((?:$_prefixPattern)-\\d+) \\|').firstMatch(line)?[1];

  /// The count column of [id], given the prefixes the index uses.
  String groupOf(String id) {
    final dash = id.lastIndexOf('-');
    final prefix = id.substring(0, dash);
    final number = int.parse(id.substring(dash + 1));
    for (final g in groups) {
      if (g.holds(prefix, number)) return g.key;
    }
    return prefix;
  }
}

/// A question block found in the Blueprint.
class QuestionBlock {
  /// Binds the question id, its header line and whether it is answered.
  QuestionBlock(this.id, this.line, {required this.answered});

  /// The question id, `BQ-<n>` or `PR-<n>`.
  final String id;

  /// The 1-based line of the block's header in the YAML file.
  final int line;

  /// Whether an answer is written that is not a pointer (`see ...`).
  final bool answered;
}

/// One row of the index.
class IndexRow {
  /// Binds the row's six cells, in table order.
  IndexRow(this.id, this.star, this.where, this.topic, this.status, this.note);

  /// The question id, `BQ-<n>` or `PR-<n>`.
  final String id;

  /// The ★ cell: non-empty when the question is marked as important.
  final String star;

  /// The where cell: the place the question concerns.
  final String where;

  /// The topic cell.
  final String topic;

  /// The status cell: `open`, `implemented on WA`, `answered`, `obsolete` or
  /// `duplicate → <id>`.
  final String status;

  /// The note cell.
  final String note;

  /// The status's first word (`open`, `implemented`, `answered`, `obsolete`,
  /// `duplicate`), as the counts and the checks group it.
  String get statusKey => status.split(' ').first;
}

/// The check's result: the findings, the figures and the rewritten index.
class RegisterReport {
  /// Every disagreement between the blocks and the index, and every malformed
  /// block or row.
  final List<String> findings = [];

  /// Questions answered in the Blueprint whose answer is not applied yet —
  /// the normal state during a clarification round, so not a finding.
  final List<String> answeredNotApplied = [];

  /// The number of distinct question blocks in the Blueprint.
  int blocks = 0;

  /// The number of distinct rows in the index.
  int rows = 0;

  /// The number of questions and proposals with status `open` or
  /// `implemented on WA`.
  int waiting = 0;

  /// The number of [waiting] questions and proposals marked ★.
  int waitingStarred = 0;

  /// The clarification file with the recomputed counts written in.
  String rewritten = '';
}

/// Orders two ids: by the configured prefix order (else alphabetically), then
/// by number.
int Function(String, String) _idOrder(List<String> prefixes) => (a, b) {
  String p(String id) => id.substring(0, id.lastIndexOf('-'));
  int n(String id) => int.parse(id.substring(id.lastIndexOf('-') + 1));
  final pa = p(a), pb = p(b);
  if (pa != pb) {
    final ia = prefixes.indexOf(pa), ib = prefixes.indexOf(pb);
    if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
    return pa.compareTo(pb);
  }
  return n(a).compareTo(n(b));
};

/// Checks [clarifications] (the index file's text) against the question blocks
/// of [blueprintYaml], by the project's [config] (default:
/// [QuestionRegisterConfig.defaults]).
RegisterReport checkQuestionRegister(
  String blueprintYaml,
  String clarifications, {
  QuestionRegisterConfig config = QuestionRegisterConfig.defaults,
}) {
  final report = RegisterReport();
  final idOrder = _idOrder(config.prefixes);

  // --- blocks in the Blueprint --------------------------------------------
  final annotations = SpecReviewAnnotations(
    SpecDocument()..setContent('blueprint', blueprintYaml),
  );
  for (final e in annotations.validate()) {
    if (e.code == SpecValidationCode.annotationMalformed &&
        e.message.contains('question header')) {
      report.findings.add('malformed question block: ${e.message}');
    }
  }
  final blocks = <String, QuestionBlock>{};
  for (final a in annotations.list()) {
    final id = a.id;
    if (a.kind != SpecReviewAnnotationKind.question ||
        !config.isQuestionId(id!)) {
      continue;
    }
    if (blocks.containsKey(id)) {
      report.findings.add(
        'duplicate block: $id at lines ${blocks[id]!.line} and ${a.line + 1}',
      );
    }
    blocks[id] = QuestionBlock(
      id,
      a.line + 1,
      answered: a.answer.isNotEmpty && !a.answer.startsWith('see '),
    );
  }
  report.blocks = blocks.length;
  for (final b in blocks.values) {
    if (b.answered) report.answeredNotApplied.add('${b.id} (line ${b.line})');
  }

  // --- the index ---------------------------------------------------------
  String section(String from, String to) {
    final a = clarifications.indexOf(from);
    final b = clarifications.indexOf(to, a < 0 ? 0 : a);
    if (a < 0) return '';
    return clarifications.substring(a, b < 0 ? clarifications.length : b);
  }

  final index = <String, IndexRow>{};
  final order = <String>[];
  for (final line in section(
    '## Index',
    '## Not in the Blueprint',
  ).split('\n')) {
    if (config.rowId(line) == null) continue;
    final cells = line.trim().split(_pipe).map((c) => c.trim()).toList();
    // A row is `| id | ★ | where | topic | status | note |`: seven pieces
    // around the six cells, the first and last empty.
    if (cells.length != 8 || cells.first.isNotEmpty || cells.last.isNotEmpty) {
      report.findings.add(
        'malformed index row: ${line.length > 80 ? line.substring(0, 80) : line}…',
      );
      continue;
    }
    final row = IndexRow(
      cells[1],
      cells[2],
      cells[3],
      cells[4],
      cells[5],
      cells[6],
    );
    if (index.containsKey(row.id)) {
      report.findings.add('index row twice: ${row.id}');
    }
    final known = config.statuses.any(
      (st) => st.key == 'duplicate'
          ? (row.status.startsWith('${st.label} → ') &&
                config.isQuestionId(row.status.substring(st.label.length + 3)))
          : row.status == st.label,
    );
    if (!known) {
      report.findings.add('${row.id}: unknown status "${row.status}"');
    }
    index[row.id] = row;
    order.add(row.id);
  }
  for (var i = 1; i < order.length; i++) {
    if (idOrder(order[i - 1], order[i]) > 0) {
      report.findings.add(
        'index out of order: ${order[i - 1]} before ${order[i]}',
      );
    }
  }
  report.rows = index.length;

  final notInBlueprint = <String, String>{};
  for (final line in section('## Not in the Blueprint', '\n## ').split('\n')) {
    if (config.rowId(line) == null) continue;
    final cells = line.trim().split(_pipe).map((c) => c.trim()).toList();
    notInBlueprint[cells[1]] = cells.length > 2 ? cells[2] : '';
  }

  // --- the two against each other -----------------------------------------
  for (final id in blocks.keys) {
    if (!index.containsKey(id)) {
      report.findings.add('$id: block in the Blueprint, no index row');
    }
  }
  index.forEach((id, row) {
    final inBlueprint = blocks.containsKey(id);
    final waiting = config.statuses.any(
      (st) => st.key == row.statusKey && st.waiting,
    );
    switch (waiting ? 'waiting' : row.statusKey) {
      case 'waiting':
        if (!inBlueprint) {
          report.findings.add(
            '$id: ${row.status} in the index, but no block in the Blueprint',
          );
        }
      case 'duplicate':
        if (!inBlueprint && notInBlueprint[id] != row.status) {
          report.findings.add(
            '$id: duplicate without a pointer block, and not under "Not in the Blueprint"',
          );
        }
      default:
        if (inBlueprint) {
          report.findings.add(
            '$id: ${row.status} in the index, but its block is still in the Blueprint',
          );
        }
        if (notInBlueprint[id] != row.status) {
          report.findings.add(
            '$id: ${row.status} in the index, but "Not in the Blueprint" '
            '${notInBlueprint.containsKey(id) ? 'says ${notInBlueprint[id]}' : 'lacks it'}',
          );
        }
    }
  });
  notInBlueprint.forEach((id, status) {
    if (!index.containsKey(id)) {
      report.findings.add(
        '$id: under "Not in the Blueprint" but not in the index',
      );
    }
  });

  // --- the counts ----------------------------------------------------------
  final maxOf = <String, int>{};
  for (final id in index.keys) {
    final dash = id.lastIndexOf('-');
    final prefix = id.substring(0, dash);
    final number = int.parse(id.substring(dash + 1));
    if (number > (maxOf[prefix] ?? 0)) maxOf[prefix] = number;
  }
  final groups = config.groups.isNotEmpty
      ? config.groups
      : [
          for (final prefix
              in (maxOf.keys.toList()..sort((x, y) => idOrder('$x-0', '$y-0'))))
            QuestionRegisterGroup(
              key: prefix,
              label: '$prefix-01 to $prefix-{max}',
              prefix: prefix,
            ),
        ];
  String labelOf(QuestionRegisterGroup g) =>
      g.label.replaceAll('{max}', '${maxOf[g.prefix] ?? 0}');
  final count = <String, int>{};
  final star = <String, int>{};
  for (final row in index.values) {
    final key = '${row.statusKey}/${config.groupOf(row.id)}';
    count[key] = (count[key] ?? 0) + 1;
    if (row.star.isNotEmpty) {
      star[row.statusKey] = (star[row.statusKey] ?? 0) + 1;
    }
  }
  int c(String s, String g) => count['$s/$g'] ?? 0;
  final header =
      '| Status | ${[for (final g in groups) labelOf(g)].join(' | ')} | All | ★ |';
  final table = <String>[
    header,
    '|--------|${[for (final _ in groups) '------:'].join('|')}|----:|--:|',
  ];
  final totals = List<int>.filled(groups.length, 0);
  var ts = 0;
  for (final st in config.statuses) {
    final cells = [for (final g in groups) c(st.key, g.key)];
    for (var i = 0; i < cells.length; i++) {
      totals[i] += cells[i];
    }
    ts += star[st.key] ?? 0;
    final starCell = st.waiting ? '${star[st.key] ?? 0}' : '—';
    table.add(
      '| ${st.label} | ${cells.join(' | ')} | ${cells.fold(0, (x, y) => x + y)} | $starCell |',
    );
  }
  table.add(
    '| **all** | ${[for (final t in totals) '**$t**'].join(' | ')} | '
    '**${totals.fold(0, (x, y) => x + y)}** | **$ts** |',
  );
  final waitingKeys = [
    for (final st in config.statuses)
      if (st.waiting) st.key,
  ];
  report.waiting = [
    for (final s in waitingKeys)
      for (final g in groups) c(s, g.key),
  ].fold(0, (a, b) => a + b);
  report.waitingStarred = waitingKeys.fold(0, (a, s) => a + (star[s] ?? 0));

  // Write the counts into the file, then compare with what it said.
  var out = clarifications;
  final tableStart = groups.isEmpty
      ? -1
      : out.indexOf('| Status | ${labelOf(groups.first).split('{max}').first}');
  if (tableStart < 0) {
    report.findings.add('the status table is missing');
  } else {
    var tableEnd = tableStart;
    for (var n = 0; n < table.length; n++) {
      tableEnd = out.indexOf('\n', tableEnd) + 1;
    }
    out = out.replaceRange(tableStart, tableEnd, '${table.join('\n')}\n');
  }
  out = out.replaceFirstMapped(
    RegExp(
      r'\d+ questions and proposals wait for an answer, \d+ of them marked ★;\n\d+ blocks are in the Blueprint',
    ),
    (_) =>
        '${report.waiting} questions and proposals wait for an answer, '
        '${report.waitingStarred} of them marked ★;\n${report.blocks} blocks are in the Blueprint',
  );
  maxOf.forEach((prefix, max) {
    out = out.replaceAll(
      RegExp(
        '${RegExp.escape(prefix)}-01 to ${RegExp.escape(prefix)}-\\d+\\*\\*',
      ),
      '$prefix-01 to $prefix-$max**',
    );
  });
  report.rewritten = out;
  if (out != clarifications) {
    report.findings.add(
      'the status counts, the sentence below them or the id range are out of date '
      '(run with --write)',
    );
  }
  return report;
}
