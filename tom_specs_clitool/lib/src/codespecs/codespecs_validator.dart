/// Runs the `codespecs_derivation_contract.md` §6 checks over an emitted
/// CodeSpecs tree.
///
/// **Where this runs.** Phase 4 emits no code from a program: an authoring
/// agent writes the trio from a per-area extract (`codespecs_mapping.md`
/// §1.1.1). So this is the pass that stands where a generator's own validation
/// would have stood — the step that decides whether what the agent wrote is
/// admissible, run after each authoring step and at gate G4. It lives beside
/// the SOM generator and the SOM model validator because the extract it reads
/// is emitted there.
///
/// **Failure mode.** A violation is a failure, never a warning:
/// [runCodeSpecsChecks] returns every breach it finds and
/// [CodeSpecsValidationReport.passed] is false if there is even one. The CLI
/// turns that into a non-zero exit.
library;

import 'cs_checks.dart';
import 'cs_model.dart';
import 'cs_reader.dart';

/// The outcome of one validation pass.
class CodeSpecsValidationReport {
  /// Every violation found, in check order then discovery order.
  final List<CodeSpecsViolation> violations;

  /// The checks that ran, in `codespecs_derivation_contract.md` §6 table order.
  final List<CodeSpecsCheck> checks;

  /// Creates a report.
  const CodeSpecsValidationReport({
    required this.violations,
    required this.checks,
  });

  /// Whether generation may proceed.
  bool get passed => violations.isEmpty;

  /// The violations of one `codespecs_derivation_contract.md` §6 check number.
  List<CodeSpecsViolation> forCheck(int number) =>
      violations.where((v) => v.check == number).toList();

  /// The report as lines, one per violation, each naming its rule.
  List<String> get lines => [for (final v in violations) '$v'];

  /// A one-line summary naming how many of the checks failed.
  String get summary {
    if (passed) {
      return 'codespecs: ${checks.length} checks passed';
    }
    final failed = violations.map((v) => v.check).toSet().length;
    return 'codespecs: ${violations.length} violation(s) '
        'across $failed of ${checks.length} checks';
  }
}

/// Runs [checks] (by default all thirty-seven) over [input].
///
/// Every check runs even when an earlier one fails — an author fixing a
/// generated tree wants the whole list, not the first breach.
CodeSpecsValidationReport runCodeSpecsChecks(
  CodeSpecsValidationInput input, {
  List<CodeSpecsCheck> checks = codeSpecsChecks,
}) {
  final violations = <CodeSpecsViolation>[];
  for (final check in checks) {
    violations.addAll(check.run(input));
  }
  return CodeSpecsValidationReport(violations: violations, checks: checks);
}

/// Pairs the `Cs*` catalogues in [csSources] with their `tom_core` counterparts
/// in [coreSources], for check 9.
///
/// This is the "third party that may see both" the mirror check needs: it reads
/// the two packages as source text, so neither has to depend on the other —
/// which is why `tom_code_specs` can keep its catalogues as deliberate local
/// mirrors and still have them checked.
///
/// An enum the sources do not declare yields an empty value list, which the
/// check reports as a mismatch rather than passing silently.
List<CsEnumMirror> readCsEnumMirrors({
  required Iterable<String> csSources,
  required Iterable<String> coreSources,
  Map<String, String> pairs = csMirroredEnumPairs,
}) {
  List<String> find(Iterable<String> sources, String name) {
    for (final source in sources) {
      final values = readEnumValues(source, name);
      if (values != null) return values;
    }
    return const [];
  }

  return [
    for (final entry in pairs.entries)
      CsEnumMirror(
        csEnumName: entry.key,
        coreEnumName: entry.value,
        csValues: find(csSources, entry.key),
        coreValues: find(coreSources, entry.value),
      ),
  ];
}

/// Thrown when a validation pass fails, so a caller that treats generation as a
/// single operation can let the failure propagate.
class CodeSpecsValidationException implements Exception {
  /// The failing report.
  final CodeSpecsValidationReport report;

  /// Creates the exception.
  const CodeSpecsValidationException(this.report);

  @override
  String toString() =>
      ['${report.summary}:', ...report.lines].join('\n  ');
}

/// Runs the checks and throws [CodeSpecsValidationException] on any violation.
///
/// This is the shape the generator calls: generation *fails*, it does not warn.
void assertCodeSpecsValid(
  CodeSpecsValidationInput input, {
  List<CodeSpecsCheck> checks = codeSpecsChecks,
}) {
  final report = runCodeSpecsChecks(input, checks: checks);
  if (!report.passed) throw CodeSpecsValidationException(report);
}
