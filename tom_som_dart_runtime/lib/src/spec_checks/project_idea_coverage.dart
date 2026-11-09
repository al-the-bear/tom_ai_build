// Coverage of the Project Idea by the Blueprint's requirements (a gate item
// such as G2-REQ-3: nothing of the Project Idea is lost).
//
// The Project Idea is free-form Markdown, so its ids are read from the shapes it
// writes them in: capability statements `- **C1.1** …` under the areas `### C1`,
// constraints `- **C-1 Title.** …`, non-functional expectations `| N-1 | … |` and
// decisions `| D-01 | … |`. The requirements are the items of the Blueprint's four
// requirement lists; what a requirement cites is read from its `source` and
// `rationale` values, where a citation may be a single id (`C1.2`, `D-306`,
// `N-3`, `C-2`), a range (`C6.1–C6.9`, `D-136–D-143`, `C-1–C-4`), a whole
// capability area (`C18`) or a Blueprint question (`BQ-121`).
//
// Each id ends in one class, the first that applies:
//
// - `covered`   — a requirement cites it, singly or in a range;
// - `area`      — a capability statement whose area a requirement cites as a whole;
// - `via`       — a decision whose content is carried by a covered id (a
//                 capability statement, constraint or expectation that cites it),
//                 or that answers a Blueprint question a requirement cites;
// - `excluded`  — a recorded exclusion: a decision the Project Idea's out-of-scope table
//                 cites, one a later decision supersedes, or an entry of the
//                 exclusion list (the project's
//                 `<spec-root>/checks/project_idea_coverage.yaml`) naming the
//                 record that excludes it;
// - `uncovered` — none of these.
//
// It reads the YAML text directly, as the other Blueprint checks do: the rule is
// about ids and the text that cites them.
import 'package:yaml/yaml.dart';

/// The classes an id can end in, in the order they are tried.
enum CoverageClass {
  /// A requirement cites the id, singly or in a range.
  covered,

  /// A capability statement whose whole area a requirement cites.
  area,

  /// A decision carried by a covered non-decision id that cites it, or one
  /// answering a Blueprint question a requirement cites.
  via,

  /// A recorded exclusion: the exclusion list, the out-of-scope table, or a
  /// superseding decision.
  excluded,

  /// None of the other classes applies.
  uncovered,
}

/// One id of the Project Idea.
class ProjectIdeaItem {
  /// Binds the item's id, kind and text.
  ProjectIdeaItem(this.id, this.kind, this.text);

  /// `C1.1`, `C-1`, `N-1` or `D-01`.
  final String id;

  /// `capability`, `constraint`, `expectation` or `decision`.
  final String kind;

  /// The item's own text (bullet or table row).
  final String text;

  /// For a capability statement: its area, `C1` for `C1.1`.
  String? get area => kind == 'capability' ? id.split('.').first : null;
}

/// What the parse of the Project Idea found.
class ProjectIdea {
  /// Binds the items and the out-of-scope table text.
  ProjectIdea(this.items, this.outOfScopeText);

  /// Every id the Project Idea writes, in document order.
  final List<ProjectIdeaItem> items;

  /// The rows of the Project Idea's out-of-scope table.
  final String outOfScopeText;

  /// The item with [id], or `null` when the Project Idea has none.
  ProjectIdeaItem? operator [](String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }
}

/// A recorded exclusion of the exclusion list.
class CoverageExclusion {
  /// Binds the excluded id, the reason and the record.
  CoverageExclusion(this.id, this.reason, this.record);

  /// The Project Idea id the entry excludes.
  final String id;

  /// Why the id is not carried by a requirement.
  final String reason;

  /// Where the exclusion is recorded: a Blueprint section id, or a Project Idea
  /// decision.
  final String record;
}

/// The result for one id.
class CoverageEntry {
  /// Binds the item, its class and the detail.
  CoverageEntry(this.item, this.cls, this.detail);

  /// The Project Idea item the entry is for.
  final ProjectIdeaItem item;

  /// The class the item ended in.
  final CoverageClass cls;

  /// The requirements that cite it, the id that carries it, or the reason of
  /// its exclusion; `''` for an uncovered id.
  final String detail;
}

/// The measurement.
class ProjectIdeaCoverageReport {
  /// Binds the entries, the requirement count and the unknown exclusions.
  ProjectIdeaCoverageReport(
    this.entries,
    this.requirements,
    this.unknownExclusions,
  );

  /// One entry per Project Idea item, in document order.
  final List<CoverageEntry> entries;

  /// The number of requirements read.
  final int requirements;

  /// Ids of the exclusion list that the Project Idea does not hold.
  final List<String> unknownExclusions;

  /// The entries that ended in class [c].
  Iterable<CoverageEntry> of(CoverageClass c) =>
      entries.where((e) => e.cls == c);
}

final RegExp _capability = RegExp(r'^- \*\*(C\d+\.\d+)\*\*');
final RegExp _constraint = RegExp(r'^- \*\*(C-\d+)\b');
final RegExp _row = RegExp(r'^\|\s*((?:N|D)-\d+)\s*\|');

/// Reads the ids of the Project Idea Markdown in [md].
ProjectIdea parseProjectIdea(String md) {
  final lines = md.split('\n');
  final items = <ProjectIdeaItem>[];
  final outOfScope = StringBuffer();
  var inOutOfScope = false;
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];
    if (l.startsWith('#')) inOutOfScope = l.startsWith('### 6.2');
    if (inOutOfScope && l.startsWith('|')) outOfScope.writeln(l);
    final c = _capability.firstMatch(l) ?? _constraint.firstMatch(l);
    if (c != null) {
      final text = StringBuffer(l);
      var j = i + 1;
      while (j < lines.length &&
          lines[j].startsWith('  ') &&
          lines[j].trim().isNotEmpty) {
        text.write(' ${lines[j].trim()}');
        j++;
      }
      final id = c.group(1)!;
      items.add(
        ProjectIdeaItem(
          id,
          id.startsWith('C-') ? 'constraint' : 'capability',
          '$text',
        ),
      );
      continue;
    }
    final r = _row.firstMatch(l);
    if (r != null && !inOutOfScope) {
      final id = r.group(1)!;
      items.add(
        ProjectIdeaItem(
          id,
          id.startsWith('N-') ? 'expectation' : 'decision',
          l,
        ),
      );
    }
  }
  return ProjectIdea(items, '$outOfScope');
}

final RegExp _citation = RegExp(
  r'\b(BQ-\d+|C-\d+(?:\s*[–-]\s*C-\d+)?|[DN]-\d+(?:\s*[–-]\s*[DN]-\d+)?|'
  r'C\d+(?:\.\d+(?:\s*[–-]\s*C\d+\.\d+)?)?)\b',
);

/// The ids a text cites, ranges expanded; whole areas as `C18`.
Set<String> citations(String text) {
  final out = <String>{};
  for (final m in _citation.allMatches(text)) {
    final t = m.group(1)!.replaceAll(RegExp(r'\s'), '');
    final parts = t.split(RegExp('[–]|(?<=\\d)-(?=[CDN])'));
    if (parts.length == 2) {
      out.addAll(_expand(parts[0], parts[1]));
    } else {
      out.add(t);
    }
  }
  return out;
}

Iterable<String> _expand(String a, String b) sync* {
  final cap = RegExp(r'^C(\d+)\.(\d+)$');
  final ca = cap.firstMatch(a), cb = cap.firstMatch(b);
  if (ca != null && cb != null) {
    if (ca.group(1) != cb.group(1)) {
      yield a;
      yield b;
      return;
    }
    for (var n = int.parse(ca.group(2)!); n <= int.parse(cb.group(2)!); n++) {
      yield 'C${ca.group(1)}.$n';
    }
    return;
  }
  final pre = RegExp(r'^([A-Z]+)-(\d+)$');
  final pa = pre.firstMatch(a), pb = pre.firstMatch(b);
  if (pa != null && pb != null && pa.group(1) == pb.group(1)) {
    final width = pa.group(2)!.length;
    for (var n = int.parse(pa.group(2)!); n <= int.parse(pb.group(2)!); n++) {
      yield '${pa.group(1)}-${'$n'.padLeft(width, '0')}';
    }
    return;
  }
  yield a;
  yield b;
}

const _requirementLists = [
  'FRE-REQU-LST',
  'TERQ-REQU-LST',
  'SECRQ-REQU-LST',
  'ORRQ-REQU-LST',
];

/// The requirements of the Blueprint in [yamlText], each with the text of its
/// `source` and `rationale` values.
Map<String, String> requirementSources(String yamlText) {
  final out = <String, String>{};
  void collect(Object? node, StringBuffer into) {
    if (node is! YamlMap) return;
    for (final e in node.entries) {
      final k = '${e.key}';
      if ((k == 'source' || k == 'rationale') && e.value is! YamlMap) {
        into.writeln('${e.value}');
      } else {
        collect(e.value, into);
      }
    }
  }

  void walk(Object? node) {
    if (node is! YamlMap) return;
    for (final e in node.entries) {
      final k = '${e.key}';
      if (_requirementLists.contains(k.split(' ').first)) {
        final list = e.value;
        if (list is! YamlMap) continue;
        for (final item in list.entries) {
          final id = '${item.key}'.split(' ').first;
          if (!id.contains('-REQU-') || id.endsWith('-LST')) continue;
          final b = StringBuffer();
          collect(item.value, b);
          out[id] = '$b';
        }
      } else {
        walk(e.value);
      }
    }
  }

  walk(loadYaml(yamlText));
  return out;
}

/// Reads the exclusion list (`exclusions: [{id, reason, record}]`).
List<CoverageExclusion> parseExclusions(String yamlText) {
  final doc = loadYaml(yamlText);
  final list = doc is YamlMap ? doc['exclusions'] : null;
  if (list is! YamlList) return [];
  return [
    for (final e in list)
      CoverageExclusion('${e['id']}', '${e['reason']}', '${e['record']}'),
  ];
}

final RegExp _supersedes = RegExp(r'supersedes[^|]*?\b(D-\d+)');
final RegExp _answers = RegExp(r'Answers Blueprint questions?([^|.]*)');

/// Measures the coverage of [idea] by the requirements [sources].
ProjectIdeaCoverageReport measureProjectIdeaCoverage(
  ProjectIdea idea,
  Map<String, String> sources, {
  List<CoverageExclusion> exclusions = const [],
}) {
  final citedBy = <String, List<String>>{};
  for (final r in sources.entries) {
    for (final id in citations(r.value)) {
      (citedBy[id] ??= []).add(r.key);
    }
  }
  final superseded = <String, String>{};
  for (final d in idea.items.where((i) => i.kind == 'decision')) {
    for (final m in _supersedes.allMatches(d.text)) {
      superseded[m.group(1)!] = d.id;
    }
  }
  final outOfScope = citations(idea.outOfScopeText);
  final excluded = {for (final e in exclusions) e.id: e};

  final direct = <String, CoverageEntry>{};
  for (final item in idea.items) {
    final by = citedBy[item.id];
    if (by != null) {
      direct[item.id] = CoverageEntry(
        item,
        CoverageClass.covered,
        by.join(', '),
      );
    } else if (item.area != null && citedBy[item.area] != null) {
      direct[item.id] = CoverageEntry(
        item,
        CoverageClass.area,
        '${item.area} cited by ${citedBy[item.area]!.join(', ')}',
      );
    }
  }

  final entries = <CoverageEntry>[];
  for (final item in idea.items) {
    final d = direct[item.id];
    if (d != null) {
      entries.add(d);
      continue;
    }
    if (item.kind == 'decision') {
      final carriers = [
        for (final c in direct.values)
          if (c.item.kind != 'decision' &&
              citations(c.item.text).contains(item.id))
            c.item.id,
      ];
      if (carriers.isNotEmpty) {
        entries.add(
          CoverageEntry(
            item,
            CoverageClass.via,
            'carried by ${carriers.join(', ')}',
          ),
        );
        continue;
      }
      final answered = [
        for (final m in _answers.allMatches(item.text))
          for (final q in citations(m.group(1)!))
            if (q.startsWith('BQ-') && citedBy[q] != null) q,
      ];
      if (answered.isNotEmpty) {
        entries.add(
          CoverageEntry(
            item,
            CoverageClass.via,
            'answers ${answered.join(', ')}, cited by '
            '${{for (final q in answered) ...citedBy[q]!}.join(', ')}',
          ),
        );
        continue;
      }
    }
    final e = excluded[item.id];
    if (e != null) {
      entries.add(
        CoverageEntry(
          item,
          CoverageClass.excluded,
          '${e.reason} (${e.record})',
        ),
      );
    } else if (item.kind == 'decision' && outOfScope.contains(item.id)) {
      entries.add(
        CoverageEntry(
          item,
          CoverageClass.excluded,
          'cited by the out-of-scope table (Project Idea § 6.2)',
        ),
      );
    } else if (superseded[item.id] != null) {
      entries.add(
        CoverageEntry(
          item,
          CoverageClass.excluded,
          'superseded by ${superseded[item.id]}',
        ),
      );
    } else {
      entries.add(CoverageEntry(item, CoverageClass.uncovered, ''));
    }
  }
  final known = {for (final i in idea.items) i.id};
  return ProjectIdeaCoverageReport(entries, sources.length, [
    for (final e in exclusions)
      if (!known.contains(e.id)) e.id,
  ]);
}
