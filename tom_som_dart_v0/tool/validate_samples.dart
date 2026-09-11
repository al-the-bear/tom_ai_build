// Instance-tier gate for every shared sample: `validateDocument` must return
// nothing.
//
// The companion to `verify_samples.dart`, which is the DECODE tier only. A
// document can decode cleanly and still name a message key, a role, a route or
// an error code that nothing declares — the instance tier (SOM §9) is where
// those are caught, and until this gate existed only the Meridian document was
// ever held to it, by `build_shared_sample.dart` at build time.
//
// WHY IT EXISTS. `uam_access_hub.docspecs.yaml` carried eleven
// `danglingReference` findings from a check that had existed since csrb3. None
// was new; nobody had run the check against that file. They came in three
// shapes, each a document that read fine and generated wrong code:
//
//   * a field answered as if it meant something else — `aggregateRoot` holds
//     the NAME of the root entity, and the sample wrote `Yes` / `No`;
//   * an id that was never declared — a route written as its URL rather than
//     its route id, a message key written as its copy, a domain enum, a server
//     operation and an error code the registries never listed;
//   * a position written where an id belongs — step `2` where
//     `MNSST-STEP-2` is wanted.
//
// A check that runs only on request is a check that drifts, so this one runs
// on every conformance-suite run (`run_all_suites.sh`, suite
// `sample_validate`).
//
// EVERY SAMPLE, WITH EXCEPTIONS STATED. `verify_samples.dart` documents that
// coverage-oriented samples need not satisfy list minima or `refersTo`
// resolution. That stays true, but an exemption must now be WRITTEN rather than
// implied: [coverageOnly] names each sample excused from this tier and why. It
// is empty today because every sample is clean — so a new sample is validated
// by default, and excusing one is a visible decision in a diff.
//
//   cd tom_som_dart_v0 && dart run tool/validate_samples.dart
//
// Exit code 0 when every non-exempt sample validates clean; 1 otherwise.
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

/// Samples excused from the instance tier, by file name, with the reason.
///
/// Empty on purpose. See the file header.
const Map<String, String> coverageOnly = {};

void main() {
  final samplesDirs = [
    Directory('documents'),
    Directory('../tom_som_conformance/samples'),
  ];
  for (final d in samplesDirs) {
    if (!d.existsSync()) {
      stderr.writeln('samples folder missing: ${d.path}');
      exit(1);
    }
  }
  final files = [
    for (final d in samplesDirs)
      ...d
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.docspecs.yaml')),
  ]..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('no *.docspecs.yaml samples found');
    exit(1);
  }

  // An exemption naming a file that does not exist is itself a finding: it
  // would otherwise survive a rename and quietly excuse nothing, or the wrong
  // thing once the name is reused.
  final names = {for (final f in files) f.uri.pathSegments.last};
  final stale = coverageOnly.keys.where((k) => !names.contains(k)).toList();
  if (stale.isNotEmpty) {
    stderr.writeln('coverageOnly names sample(s) that do not exist: '
        '${stale.join(', ')}');
    exit(1);
  }

  var failures = 0;
  var checked = 0;
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final reason = coverageOnly[name];
    if (reason != null) {
      stdout.writeln('SKIP $name — $reason');
      continue;
    }
    final doc = SpecDocument.fromFile(f.path, d00SolutionBlueprintMetaTree);
    final findings = validateDocument(somSpecModel, doc);
    checked++;
    if (findings.isEmpty) {
      stdout.writeln('OK   $name');
      continue;
    }
    failures++;
    stderr.writeln('FAIL $name — ${findings.length} finding(s)');
    for (final x in findings) {
      stderr.writeln('       [${x.code.name}] ${x.path}: ${x.message}');
    }
  }

  if (failures > 0) {
    stderr.writeln('FAILED: $failures sample(s) do not validate.');
    exit(1);
  }
  stdout.writeln('All $checked sample(s) validate clean '
      '(${coverageOnly.length} exempt).');
}
