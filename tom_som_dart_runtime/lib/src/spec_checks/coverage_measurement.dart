// How much of the model a document fills, per row of the coverage table the
// project configures (`<spec-root>/checks/coverage_rows.yaml`), and why each
// section left empty is empty (`coverage_reasons.yaml`).
//
// The model's sections are read from the model's full exercise sample
// (`tom_som_conformance/samples/exercise_full_model.docspecs.yaml`):
//
//   * a model section is a key `<ID> <fieldName>` whose value is a block
//     (mapping or empty) — complex, list and form sections; text leaves and the
//     id-less sub-sections are not counted;
//   * its path is the chain of field names, list items being transparent, so
//     all items of one list map onto one path;
//   * a Blueprint path is FILLED when at least one instance of it carries a
//     non-empty string somewhere below it.
//
// A section is a reference expansion (R) when the sample expands a reference
// the Blueprint writes as an id, and an unused variant (V) when it is an arm of
// a one-of section (from the model's metadata) whose sibling arm the Blueprint
// fills; both are outside the eligible count. Every other empty section is
// classified by the first rule of the project's
// `<spec-root>/checks/coverage_reasons.yaml` that matches its id path, or U
// when none does; the rows come from `<spec-root>/checks/coverage_rows.yaml`.
import 'dart:convert';

import 'package:yaml/yaml.dart';

class _ModelSection {
  _ModelSection(this.ids, this.variants, this.referenceExpansion);
  final List<String> ids;
  final List<String> variants;
  final bool referenceExpansion;
}

/// One empty section of the Blueprint, as the TSV lists it.
class UnfilledSection {
  /// Binds the section's row, id path, field path, kind and state; its class
  /// and reason start as unclassified.
  UnfilledSection(this.row, this.idPath, this.fieldPath, this.kind, this.state);

  /// The id of the coverage row whose longest prefix matches [fieldPath].
  final String row;

  /// The section ids from the root down, joined by ` > ` (a list item by its
  /// class id).
  final String idPath;

  /// The field names from the root down, joined by `/` (list items
  /// transparent).
  final String fieldPath;

  /// `R`, `V` or `''`.
  final String kind;

  /// `present-empty` or `absent`.
  final String state;

  /// The section's class: that of the first reason rule matching [idPath],
  /// `R` or `V` for those kinds, `U` when no rule matches.
  String cls = 'U';

  /// Why the section is empty: the matching rule's reason, or the default
  /// text when none matches.
  String reason = 'no reason found in notes, clarifications or Blueprint text';
}

/// The measurement: per row, the model sections, the filled ones, and the
/// classes of the empty ones.
class CoverageReport {
  /// The row ids, in the order of the row table.
  final List<String> rows = [];

  /// Each row's label, by row id.
  final Map<String, String> labels = {};

  /// The number of model sections in each row.
  final Map<String, int> model = {};

  /// The number of each row's model sections the Blueprint fills.
  final Map<String, int> filled = {};

  /// The number of each row's model sections the Blueprint holds as a block
  /// (a mapping or an empty value), filled or not.
  final Map<String, int> block = {};

  /// Like [block], for the old Blueprint; empty when none was given.
  final Map<String, int> oldPresent = {};

  /// Like [filled], for the old Blueprint; empty when none was given.
  final Map<String, int> oldFilled = {};

  /// The number of each row's empty sections that are reference expansions
  /// (`R`).
  final Map<String, int> referenceExpansions = {};

  /// The number of each row's empty sections that are unused variant arms
  /// (`V`).
  final Map<String, int> variants = {};

  /// The number of each row's empty sections per class, by row id and class.
  final Map<String, Map<String, int>> classes = {};

  /// Every empty model section, sorted by row, id path, field path, kind and
  /// state.
  final List<UnfilledSection> unfilled = [];

  /// The number of id-less sub-sections in the sample, which are not counted.
  int idlessSampleSections = 0;

  /// The class columns of the class table, in print order.
  static const classOrder = ['T', 'P3', 'NA', 'D', 'Q', 'F', 'U', 'V'];

  /// The sum of [m]'s counts over all rows.
  int total(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

  /// The model sections of [row] that count towards coverage: all of them
  /// less its `V` and `R` sections.
  int eligible(String row) =>
      (model[row] ?? 0) - (classes[row]?['V'] ?? 0) - (classes[row]?['R'] ?? 0);

  /// The sum of [eligible] over all rows.
  int get totalEligible => rows.fold(0, (n, r) => n + eligible(r));

  /// The report as `spec_checks coverage` prints it: the counts table, the
  /// id-less count and the class table, one line per row plus a total.
  String render() {
    final b = StringBuffer();
    String l(String s, int w) => s.padRight(w);
    String r(Object n, int w) => '$n'.padLeft(w);
    b.writeln(
      '${l('row', 9)} ${r('model', 5)} ${r('filledNow', 9)} ${r('blockNow', 8)} '
      '${r('oldPresent', 10)} ${r('oldFilled', 9)} ${r('refExp', 6)} ${r('variant', 7)}',
    );
    for (final g in rows) {
      b.writeln(
        '${l(g, 9)} ${r(model[g] ?? 0, 5)} ${r(filled[g] ?? 0, 9)} ${r(block[g] ?? 0, 8)} '
        '${r(oldPresent[g] ?? 0, 10)} ${r(oldFilled[g] ?? 0, 9)} '
        '${r(referenceExpansions[g] ?? 0, 6)} ${r(variants[g] ?? 0, 7)}',
      );
    }
    b.writeln(
      '${l('TOTAL', 9)} ${r(total(model), 5)} ${r(total(filled), 9)} ${r(total(block), 8)} '
      '${r(total(oldPresent), 10)} ${r(total(oldFilled), 9)} '
      '${r(total(referenceExpansions), 6)} ${r(total(variants), 7)}',
    );
    b.writeln(
      'id-less sample sub-sections (not counted, T-4): $idlessSampleSections',
    );
    b.writeln();
    b.writeln(
      '${l('row', 9)} ${classOrder.map((c) => r(c, 3)).join(' ')}  eligible  filled%elig',
    );
    for (final g in rows) {
      final el = eligible(g);
      final pct = el == 0 ? 0.0 : 100 * (filled[g] ?? 0) / el;
      b.writeln(
        '${l(g, 9)} ${classOrder.map((c) => r(classes[g]?[c] ?? 0, 3)).join(' ')}'
        '  ${r(el, 8)}  ${r(pct.toStringAsFixed(1), 5)}',
      );
    }
    final tot = <String, int>{};
    for (final g in rows) {
      classes[g]?.forEach((c, n) => tot[c] = (tot[c] ?? 0) + n);
    }
    b.writeln(
      '${l('TOTAL', 9)} ${classOrder.map((c) => r(tot[c] ?? 0, 3)).join(' ')}',
    );
    return b.toString();
  }

  /// The empty sections as tab-separated values.
  String renderTsv() {
    final b = StringBuffer(
      'path\trow\tclass\treason_parent_bq\tfield_path\tstate\n',
    );
    for (final u in unfilled) {
      b.writeln(
        [
          u.idPath,
          labels[u.row],
          u.cls,
          u.reason,
          u.fieldPath,
          u.state,
        ].join('\t'),
      );
    }
    return b.toString();
  }
}

YamlMap _document(String yamlText) =>
    ((loadYaml(yamlText) as YamlMap)['document'] as YamlMap).values.first
        as YamlMap;

bool _nonEmpty(Object? v) {
  if (v == null) return false;
  if (v is String) return v.trim().isNotEmpty;
  if (v is YamlMap) return v.values.any(_nonEmpty);
  if (v is YamlList) return v.any(_nonEmpty);
  return true;
}

bool _isBlock(Object? v) => v is YamlMap || v == null;

/// Measures [blueprintYaml] against the model sample [sampleYaml] and the model
/// metadata [metaJson], with the row table [rowsYaml] and the reason rules
/// [reasonsYaml]; [oldBlueprintYaml], when given, fills the "old" columns.
CoverageReport measureCoverage({
  required String sampleYaml,
  required String metaJson,
  required String blueprintYaml,
  required String rowsYaml,
  required String reasonsYaml,
  String? oldBlueprintYaml,
}) {
  // One-of case arms, from the model metadata.
  final meta =
      (jsonDecode(metaJson) as Map<String, dynamic>)['classes']
          as Map<String, dynamic>;
  final caseKeys = <String>{};
  meta.forEach((_, c) {
    final cls = c as Map<String, dynamic>;
    final annotations = (cls['annotations'] as List?) ?? const [];
    if (!annotations.any((a) => (a as Map)['name'] == 'OneOf')) return;
    for (final f in (cls['fields'] as List)) {
      final fm = f as Map<String, dynamic>;
      if (!((fm['annotations'] as List?) ?? const []).any(
        (a) => (a as Map)['name'] == 'Case',
      )) {
        continue;
      }
      final sid =
          fm['sectionId'] ??
          ((meta[fm['type']] as Map<String, dynamic>?)?['sectionId']);
      caseKeys.add('$sid\u0000${fm['name']}');
    }
  });

  // The model's sections, from the sample.
  final model = <String, _ModelSection>{};
  var idless = 0;
  void walkSample(
    Object? node,
    List<String> fpath,
    List<String> ipath,
    bool inList,
    List<String> variant,
    bool refexp,
  ) {
    if (node is! YamlMap) return;
    node.forEach((key, v) {
      final k = '$key';
      if (k == 'content' || k == 'headline') return;
      if (!k.contains(' ')) {
        if (inList) {
          // An item is named by its class id: the sample numbers its items
          // `<class>-<kind>-<n>`, and a reason rule names the class.
          final classId = k.split('-').first;
          walkSample(v, fpath, [...ipath, classId], false, variant, refexp);
        } else if (k[0].toLowerCase() == k[0] && k[0].toUpperCase() != k[0]) {
          idless++;
        }
        return;
      }
      final space = k.indexOf(' ');
      final sid = k.substring(0, space);
      final name = k.substring(space + 1);
      final fp = [...fpath, name];
      final ip = [...ipath, sid];
      final fpKey = fp.join('/');
      final variants = [
        ...variant,
        if (caseKeys.contains('$sid\u0000$name')) fpKey,
      ];
      if (_isBlock(v)) model[fpKey] = _ModelSection(ip, variants, refexp);
      walkSample(
        v,
        fp,
        ip,
        sid.endsWith('-LST'),
        variants,
        refexp || sid.endsWith('-REF'),
      );
    });
  }

  walkSample(_document(sampleYaml), const [], const [], false, const [], false);

  // The Blueprint's paths.
  ({Set<String> present, Set<String> filled, Set<String> block}) walkBlueprint(
    String text,
  ) {
    final present = <String>{}, filled = <String>{}, block = <String>{};
    void w(Object? node, List<String> fpath, bool inList) {
      if (node is! YamlMap) return;
      node.forEach((key, v) {
        final k = '$key';
        if (k == 'content' || k == 'headline') return;
        if (!k.contains(' ')) {
          if (inList) w(v, fpath, false);
          return;
        }
        final space = k.indexOf(' ');
        final sid = k.substring(0, space);
        final fp = [...fpath, k.substring(space + 1)];
        final fpKey = fp.join('/');
        present.add(fpKey);
        if (_isBlock(v)) block.add(fpKey);
        if (_nonEmpty(v)) filled.add(fpKey);
        w(v, fp, sid.endsWith('-LST'));
      });
    }

    w(_document(text), const [], false);
    return (present: present, filled: filled, block: block);
  }

  final bp = walkBlueprint(blueprintYaml);
  final old = oldBlueprintYaml == null ? null : walkBlueprint(oldBlueprintYaml);

  // Rows and rules.
  final report = CoverageReport();
  final prefixes = <String, List<String>>{};
  for (final row in (loadYaml(rowsYaml) as YamlMap)['rows'] as YamlList) {
    final id = '${row['id']}';
    report.rows.add(id);
    report.labels[id] = '${row['label']}';
    prefixes[id] = [for (final p in row['prefixes'] as YamlList) '$p'];
  }
  String owner(String path) {
    String? best;
    var bestLength = -1;
    prefixes.forEach((g, list) {
      for (final pre in list) {
        if ((path == pre || path.startsWith('$pre/')) &&
            pre.length > bestLength) {
          best = g;
          bestLength = pre.length;
        }
      }
    });
    return best!;
  }

  final rules = [
    for (final r in (loadYaml(reasonsYaml) as YamlMap)['rules'] as YamlList)
      (RegExp('${r['pattern']}'), '${r['class']}', '${r['reason']}'),
  ];

  void inc(Map<String, int> m, String g) => m[g] = (m[g] ?? 0) + 1;
  model.forEach((fp, m) {
    final g = owner(fp);
    inc(report.model, g);
    if (bp.filled.contains(fp)) inc(report.filled, g);
    if (bp.block.contains(fp)) inc(report.block, g);
    if (old != null) {
      if (old.block.contains(fp)) inc(report.oldPresent, g);
      if (old.filled.contains(fp)) inc(report.oldFilled, g);
    }
    if (bp.filled.contains(fp)) return;
    var kind = '';
    if (m.referenceExpansion) {
      inc(report.referenceExpansions, g);
      kind = 'R';
    } else if (m.variants.any((a) {
      final parent = a.contains('/') ? a.substring(0, a.lastIndexOf('/')) : '';
      return !bp.filled.contains(a) && bp.filled.contains(parent);
    })) {
      inc(report.variants, g);
      kind = 'V';
    }
    report.unfilled.add(
      UnfilledSection(
        g,
        m.ids.join(' > '),
        fp,
        kind,
        bp.present.contains(fp) ? 'present-empty' : 'absent',
      ),
    );
  });

  int cmp(UnfilledSection a, UnfilledSection b) {
    for (final pair in [
      (a.row, b.row),
      (a.idPath, b.idPath),
      (a.fieldPath, b.fieldPath),
      (a.kind, b.kind),
      (a.state, b.state),
    ]) {
      final c = pair.$1.compareTo(pair.$2);
      if (c != 0) return c;
    }
    return 0;
  }

  report.unfilled.sort(cmp);
  for (final u in report.unfilled) {
    for (final (pattern, cls, why) in rules) {
      if (pattern.hasMatch(u.idPath)) {
        u.cls = cls;
        u.reason = why;
        break;
      }
    }
    if (u.kind == 'R') {
      u.cls = 'R';
      u.reason = 'sample-only reference expansion';
    }
    if (u.kind == 'V') {
      u.cls = 'V';
      u.reason = 'variant arm (OneOf case) unused by any item; ${u.reason}';
    }
    final counts = report.classes.putIfAbsent(u.row, () => {});
    counts[u.cls] = (counts[u.cls] ?? 0) + 1;
  }
  report.idlessSampleSections = idless;
  return report;
}
