/// The Phase-4 mechanical gate — Stage A of `codespecs_prompt.md` §4, all five
/// checks run as one, over (model, document, catalogue, schema).
///
/// Every check runs; none stops the others. A project fixing one wants to see
/// the rest, and a gate that stopped at the first failure would report a
/// different set of problems on every run (`codespecs_prompt.md` §4).
///
/// A check that could not run is reported as **not run**, with its reason, and
/// the gate does not pass: a skipped check must never read as a passed one.
library;

import 'docspecs_validator.dart';
import 'spec_codespecs_extract.dart';
import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_validator.dart';

/// The five Stage-A checks.
enum CodeSpecsGateCheck {
  /// The document is complete against its DocSpecs schema.
  a1,

  /// The document's values are valid (`validateDocument`).
  a2,

  /// Every section the walk reaches carries a routing verdict (ROUTE-TOTAL).
  a3,

  /// Every required marker argument of a used area has a populated source.
  a4,

  /// The model still offers every structured carrier.
  a5;

  /// `A1` … `A5`, as `codespecs_prompt.md` §4 names them.
  String get label => name.toUpperCase();
}

/// One thing a check found wrong.
class CodeSpecsGateFinding {
  /// The check that found it.
  final CodeSpecsGateCheck check;

  /// What kind of finding — the DocSpecs rule (A1), the validation code (A2),
  /// `unrouted` / `root` (A3), `missingSource` / `unresolvedReference` (A4),
  /// `missingCarrier` (A5).
  final String code;

  /// Where: a section id or document path (A1–A4), or the carrier
  /// `Class.member[.formField]` (A5).
  final String location;

  /// One sentence a user acts on.
  final String message;

  /// Creates a finding.
  const CodeSpecsGateFinding({
    required this.check,
    required this.code,
    required this.location,
    required this.message,
  });

  @override
  String toString() => '${check.label} $code $location: $message';
}

/// One check's outcome.
class CodeSpecsGateCheckResult {
  /// Which check.
  final CodeSpecsGateCheck check;

  /// Whether it ran. A check that did not run never passes.
  final bool ran;

  /// Why it did not run; `null` when it ran.
  final String? notRunReason;

  /// What it found, in the order found.
  final List<CodeSpecsGateFinding> findings;

  /// Creates a result.
  const CodeSpecsGateCheckResult({
    required this.check,
    this.ran = true,
    this.notRunReason,
    this.findings = const [],
  });

  /// Ran and found nothing.
  bool get passed => ran && findings.isEmpty;
}

/// The gate's report: one result per check, A1 to A5.
class CodeSpecsGateReport {
  /// The five results, in check order.
  final List<CodeSpecsGateCheckResult> results;

  /// The extraction run's extracts, when A3 passed (A4 reads them; Stage B
  /// is handed them). `null` when the walk could not complete.
  final List<CodeSpecsExtract>? extracts;

  /// Creates a report.
  const CodeSpecsGateReport(this.results, this.extracts);

  /// The result of [check].
  CodeSpecsGateCheckResult operator [](CodeSpecsGateCheck check) =>
      results.firstWhere((r) => r.check == check);

  /// Every check ran and found nothing — the run may begin.
  bool get passed => results.every((r) => r.passed);

  /// Every finding, in check order.
  List<CodeSpecsGateFinding> get findings => [
    for (final r in results) ...r.findings,
  ];
}

/// Stage A of `codespecs_prompt.md` §4.
class CodeSpecsGate {
  /// The resolved object model.
  final SpecModel model;

  /// The document under Phase 4.
  final SpecDocument document;

  /// The area catalogue — its `gate` tables drive A4 and A5.
  final CodeSpecsAreaCatalog catalog;

  /// The DocSpecs schema of the document's root; A1 does not run without it.
  final DocSpecsSchema? schema;

  /// The document root to walk — type name or section id; defaults to the
  /// document's single populated root, as the extractor does.
  final String? rootType;

  /// Holds the inputs; [run] does the work.
  const CodeSpecsGate({
    required this.model,
    required this.document,
    required this.catalog,
    this.schema,
    this.rootType,
  });

  /// Runs all five checks.
  CodeSpecsGateReport run() {
    final a1 = _a1();
    final a2 = _a2();
    final (a3, extracts) = _a3();
    final a4 = !catalog.hasGateTables
        ? _noTables(CodeSpecsGateCheck.a4)
        : extracts == null
        ? const CodeSpecsGateCheckResult(
            check: CodeSpecsGateCheck.a4,
            ran: false,
            notRunReason:
                'A3 did not complete, so there is no extraction run to read '
                'the used areas from',
          )
        : _a4(extracts);
    final a5 = catalog.hasGateTables ? _a5() : _noTables(CodeSpecsGateCheck.a5);
    return CodeSpecsGateReport([a1, a2, a3, a4, a5], extracts);
  }

  static CodeSpecsGateCheckResult _noTables(CodeSpecsGateCheck check) =>
      CodeSpecsGateCheckResult(
        check: check,
        ran: false,
        notRunReason:
            'the catalogue carries no gate tables (written before '
            '`codespecs_prompt.md` §4.4/§4.5 were transcribed)',
      );

  CodeSpecsGateCheckResult _a1() {
    final s = schema;
    if (s == null) {
      return const CodeSpecsGateCheckResult(
        check: CodeSpecsGateCheck.a1,
        ran: false,
        notRunReason: 'no DocSpecs schema was supplied',
      );
    }
    final markdown = document.toMarkdown(model, rootType: rootType);
    return CodeSpecsGateCheckResult(
      check: CodeSpecsGateCheck.a1,
      findings: [
        for (final v in DocSpecsValidator(s).validateMarkdown(markdown))
          CodeSpecsGateFinding(
            check: CodeSpecsGateCheck.a1,
            code: v.rule.name,
            location: v.sectionId ?? v.path ?? 'line ${v.line}',
            message: 'line ${v.line}: ${v.message}',
          ),
      ],
    );
  }

  CodeSpecsGateCheckResult _a2() => CodeSpecsGateCheckResult(
    check: CodeSpecsGateCheck.a2,
    findings: [
      for (final e in validateDocument(model, document))
        CodeSpecsGateFinding(
          check: CodeSpecsGateCheck.a2,
          code: e.code.name,
          location: e.path,
          message: e.message,
        ),
    ],
  );

  /// A3 collects **every** unrouted class over the non-strict walk, rather
  /// than the first one the strict walk throws on; only when there is none
  /// does it run the extraction itself.
  (CodeSpecsGateCheckResult, List<CodeSpecsExtract>?) _a3() {
    final CodeSpecsExtractor extractor;
    try {
      extractor = CodeSpecsExtractor(
        model: model,
        document: document,
        catalog: catalog,
        rootType: rootType,
      );
    } on CodeSpecsExtractError catch (e) {
      return (
        CodeSpecsGateCheckResult(
          check: CodeSpecsGateCheck.a3,
          findings: [
            CodeSpecsGateFinding(
              check: CodeSpecsGateCheck.a3,
              code: 'root',
              location: e.path,
              message: e.message,
            ),
          ],
        ),
        null,
      );
    }
    final unrouted = [
      for (final r in extractor.routings())
        if (r.verdict == CodeSpecsRoutingVerdict.unrouted)
          CodeSpecsGateFinding(
            check: CodeSpecsGateCheck.a3,
            code: 'unrouted',
            location: r.path,
            message:
                '${r.className} carries no @CodeSpecKind, @FollowUpKind or '
                '@NoArtifact — its content would reach no extract',
          ),
    ];
    if (unrouted.isNotEmpty) {
      return (
        CodeSpecsGateCheckResult(
          check: CodeSpecsGateCheck.a3,
          findings: unrouted,
        ),
        null,
      );
    }
    return (
      const CodeSpecsGateCheckResult(check: CodeSpecsGateCheck.a3),
      extractor.extractAll(),
    );
  }

  /// A4 over the extraction run: for each obligation whose area's extract is
  /// non-empty, every instance of the obligation's class that the extract
  /// carries must carry the source value, populated (non-blank); a
  /// `resolvesTo` obligation's value must also equal a value the run carries
  /// at the target.
  CodeSpecsGateCheckResult _a4(List<CodeSpecsExtract> extracts) {
    final findings = <CodeSpecsGateFinding>[];
    final all = [for (final x in extracts) ...x.entries];
    for (final o in catalog.requiredArguments) {
      final extract = extracts.where((x) => x.area.code == o.area).firstOrNull;
      if (extract == null || extract.entries.isEmpty) continue;
      // The instances the extract carries of the obligation's class, in
      // document order, each with the populated source value it holds.
      final instances = <String, String?>{};
      final applies = <String>{};
      final when = o.when;
      for (final e in extract.entries) {
        if (e.className != o.className) continue;
        final instance = _parentPath(e.path);
        instances.putIfAbsent(instance, () => null);
        if (when != null &&
            e.fieldName == when.member &&
            e.formField == when.formField &&
            e.value == o.whenEquals) {
          applies.add(instance);
        }
        if (e.fieldName == o.member &&
            e.formField == o.formField &&
            e.value.trim().isNotEmpty) {
          instances[instance] = e.value;
        }
      }
      for (final MapEntry(key: instance, value: value) in instances.entries) {
        if (when != null && !applies.contains(instance)) continue;
        if (value == null) {
          findings.add(
            CodeSpecsGateFinding(
              check: CodeSpecsGateCheck.a4,
              code: 'missingSource',
              location: instance,
              message:
                  '${o.marker}.${o.argument} (${o.area}) is required, and '
                  'its source ${o.source} is empty here',
            ),
          );
          continue;
        }
        final target = o.resolvesTo;
        if (target == null) continue;
        final known = all.any(
          (e) =>
              e.className == target.className &&
              e.fieldName == target.member &&
              e.formField == target.formField &&
              e.value == value,
        );
        if (!known) {
          findings.add(
            CodeSpecsGateFinding(
              check: CodeSpecsGateCheck.a4,
              code: 'unresolvedReference',
              location: instance,
              message:
                  '${o.source} names `$value`, which no ${target.source} '
                  'in this document carries — ${o.marker}.${o.argument} '
                  '(${o.area}) has nothing to resolve against',
            ),
          );
        }
      }
    }
    return CodeSpecsGateCheckResult(
      check: CodeSpecsGateCheck.a4,
      findings: findings,
    );
  }

  /// A5 against the model, not the document: each carrier's class, member
  /// and form field must still exist.
  CodeSpecsGateCheckResult _a5() {
    final findings = <CodeSpecsGateFinding>[];
    for (final c in catalog.carriers) {
      final cls = model.classNamed(c.className);
      final field = cls?.fieldNamed(c.member);
      final present =
          field != null &&
          (c.formField == null ||
              field.formFields.any((f) => f.name == c.formField));
      if (!present) {
        findings.add(
          CodeSpecsGateFinding(
            check: CodeSpecsGateCheck.a5,
            code: 'missingCarrier',
            location: c.source,
            message:
                'the model no longer offers ${c.source} '
                '(${c.introducedBy}) — a project with that structured fact '
                'would have to write prose again',
          ),
        );
      }
    }
    return CodeSpecsGateCheckResult(
      check: CodeSpecsGateCheck.a5,
      findings: findings,
    );
  }
}

String _parentPath(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i);
}
