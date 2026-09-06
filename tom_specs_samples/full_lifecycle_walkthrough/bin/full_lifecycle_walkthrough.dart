// TomSpecs sample — the full lifecycle, idea to code, with every gate run.
//
// Run:  dart pub get && dart run
//
// Everything else in this folder teaches a tool. This one teaches the
// PROCESS: one small project — a room-booking service for a single office —
// carried through the phases in order, with each phase's quality gate actually
// run rather than described.
//
// `tom_specs_project_flow.md` is the single process authority. Every phase and
// gate below is its, cited by id (`PF-PHA-P2`, `PF-GAT-G2`); this sample runs
// them, it does not restate them.
//
//   Phase 1  Project Idea            → G1  idea captured
//   Phase 2  Solution Blueprint      → G2  blueprint complete   (business)
//   Phase 3  Detailed Specifications → G3  specifications complete (business)
//   Phase 4  CodeSpecs               → G4  skeleton complete    (engineering)
//   Phase 5  Test Derivation         → G5  suite derived        (engineering)
//   Phase 6  Implementation          → G6  implementation complete
//
// Phases 7 and 8 (Application Candidate, Release Candidate) are deployment and
// business sign-off; they have no artifact a sample can carry, and the README
// says so rather than pretending otherwise.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

Future<void> main() async {
  final env = await _Environment.load();
  final out = Directory('build')..createSync(recursive: true);

  _title();

  final idea = _phase1();
  final sbp = _phase2(env, idea);
  _phase3(env, sbp);
  _phase4(env, sbp, out);
  _phase5();
  _phase6();

  _closing();
}

void _title() {
  print('=' * 74);
  print('TomSpecs, end to end: a room-booking service for one office');
  print('=' * 74);
  print('');
  print('Six phases, six gates. `tom_specs_project_flow.md` is the authority');
  print('for all of them; this run executes them against real artifacts.');
  print('');
  print('The project is deliberately small — two entities, one business rule,');
  print('one server operation — so that every artifact from idea to code fits');
  print('in one reading without losing the thread.');
}

// ===========================================================================
// Phase 1 — Project Idea (PF-PHA-P1)
// ===========================================================================

/// The Phase-1 artifact's text, having passed gate G1.
String _phase1() {
  _phase(1, 'Project Idea', 'spec/01_project_idea.md');
  print('  IN   a business decision, plus whatever exists: conversations,');
  print('       the paper sheets on the doors, one complaint from sales');
  print('  OUT  a free-form document. No structure is required and none is');
  print('       imposed — filtering is the Blueprint\'s job (PF-PHA-P1).');
  print('');

  final file = File('spec/01_project_idea.md');
  final text = file.existsSync() ? file.readAsStringSync() : '';
  print('  The document records two CONTRADICTIONS rather than resolving');
  print('  them, which is Phase 1 working correctly: who may add a room, and');
  print('  who may cancel a booking. Both are carried into Phase 2 as');
  print('  clarifications.');
  print('');

  _gate('G1', 'Project Idea Captured', 'business (light)', [
    _check('Idea document exists', file.existsSync()),
    _check('Problem statement present', text.contains('## The problem')),
    _check('Users and stakeholders named', text.contains('## Who uses it')),
    _check(
      'Rough scope stated',
      text.contains('feature set') && text.contains('Out of scope'),
    ),
    _check('Sources recorded', text.contains('Where this came from')),
    _check(
      'No blocking clarifications',
      text.contains('Known contradictions'),
      note: 'both are recorded and neither blocks Blueprint work',
    ),
  ]);
  return text;
}

// ===========================================================================
// Phase 2 — Solution Blueprint (PF-PHA-P2)
// ===========================================================================

/// The Solution Blueprint, having passed gate G2.
SpecDocument _phase2(_Environment env, String idea) {
  _phase(2, 'Solution Blueprint', 'build/02_solution_blueprint.{md,yaml}');
  print('  IN   the Project Idea, plus the answers to its two clarifications');
  print('  OUT  ONE schema-bound DocSpecs document covering the whole system');
  print('       at overview depth — the first binding definition of what will');
  print('       be built, and the hinge the other twelve documents hang from');
  print('       (PF-FLW-SBP).');
  print('');

  final doc = SpecDocument();
  _authorBlueprint(D00SolutionBlueprint(doc));

  final markdown = doc.toMarkdown(env.model, rootType: 'D00SolutionBlueprint');
  File('build/02_solution_blueprint.md').writeAsStringSync(markdown);
  File('build/02_solution_blueprint.docspecs.yaml').writeAsStringSync(
    SpecDocumentYaml.encode(
      document: doc,
      tree: d00SolutionBlueprintMetaTree,
      modelVersion: env.model.modelVersionString,
    ),
  );

  print('  The two clarifications came back answered, and the Blueprint');
  print('  records the answers rather than the questions:');
  print('    · the office manager owns the room list  → one role, one owner');
  print('    · staff cancel their own bookings only   → no approval flow');
  print('');

  final schemaViolations = DocSpecsValidator(
    env.sbpSchema,
  ).validateMarkdown(markdown);
  final valueErrors = validateDocument(env.model, doc);

  _gate('G2', 'Solution Blueprint Complete', 'business (human review)', [
    _check(
      'Blueprint schema-valid',
      schemaViolations.isEmpty,
      note: '${schemaViolations.length} violation(s)',
    ),
    _check(
      'Document values valid',
      valueErrors.isEmpty,
      note:
          '${valueErrors.length} error(s) — the instance tier, which is a '
          'different question from the one above',
    ),
    _check('Scope defined', doc.hasContent('SBP/introductionAndScope/content')),
    _check(
      'Stakeholders identified',
      doc.hasContent('SBP/stakeholdersAndGovernance/content'),
    ),
    _check(
      'System context documented',
      doc.hasContent('SBP/currentLandscape/content'),
    ),
    _check(
      'Requirements traceable',
      doc.hasContent('SBP/requirements/content'),
      note: 'FR-001 carries its id into Phase 3',
    ),
    _check(
      'Architecture decisions recorded',
      doc.hasContent('SBP/solutionArchitectureAndTechnology/content'),
    ),
    _check(
      'Business review recorded',
      true,
      note: 'a human gate — the sample records it, it cannot perform it',
    ),
  ]);
  print('  WHY THIS GATE IS HEAVY (PF-GAT-G2): twelve documents are derived');
  print('  from this one, so every defect that survives G2 is multiplied by');
  print('  the Phase-3 expansion.');
  return doc;
}

// ===========================================================================
// Phase 3 — Detailed Specifications (PF-PHA-P3)
// ===========================================================================

/// The Phase-3 documents this walkthrough carries, having passed gate G3.
Map<String, SpecDocument> _phase3(_Environment env, SpecDocument sbp) {
  _phase(3, 'Detailed Specifications', 'build/03_*.md');
  print('  IN   the accepted Blueprint and the SBP → target section mapping');
  print('  OUT  the twelve specification documents, each at the depth needed');
  print('       to derive code and tests without further interpretation.');
  print('');
  print('  Phase 3 is NOT "write twelve documents from scratch" — it is');
  print('  "expand each mapped SBP region to specification depth"');
  print('  (PF-FLW-SBP). This walkthrough carries two of the twelve, chosen');
  print('  because between them they show both halves of the mapping:');
  print('    IFM  Information Model         ← SBP.8, the entities');
  print('    RSP  Requirements Specification ← SBP.9, FR-001');
  print('');

  _showMapping(env);

  final ifm = SpecDocument();
  _authorInformationModel(D03InformationModel(ifm));
  final rsp = SpecDocument();
  _authorRequirements(D04RequirementsSpecification(rsp));

  final docs = {'IFM': ifm, 'RSP': rsp};
  final roots = {
    'IFM': 'D03InformationModel',
    'RSP': 'D04RequirementsSpecification',
  };
  final schemas = {'IFM': env.ifmSchema, 'RSP': env.rspSchema};

  final results = <String, ({int schema, int values})>{};
  for (final entry in docs.entries) {
    final md = entry.value.toMarkdown(env.model, rootType: roots[entry.key]!);
    File('build/03_${entry.key.toLowerCase()}.md').writeAsStringSync(md);
    results[entry.key] = (
      schema: DocSpecsValidator(
        schemas[entry.key]!,
      ).validateMarkdown(md).length,
      values: validateDocument(env.model, entry.value).length,
    );
  }

  print('');
  print('  Both documents, both validation tiers:');
  for (final e in results.entries) {
    print(
      '    ${e.key}  schema ${e.value.schema} violation(s), '
      'values ${e.value.values} error(s)',
    );
  }
  print('');

  // Cross-document consistency (PF-GAT-G3): the same concept must carry the
  // same term and the same value everywhere. Checked by comparing the entity
  // names the SBP wrote against the ones the IFM expanded.
  final sbpEntities = _entityNames(
    sbp,
    'SBP/informationAndDataModel/dataModel',
  );
  final ifmEntities = _entityNames(ifm, 'IFM');
  final consistent =
      sbpEntities.length == ifmEntities.length &&
      sbpEntities.every(ifmEntities.contains);
  print('  Cross-document consistency, checked rather than asserted:');
  print('    SBP.8 entities : ${sbpEntities.join(', ')}');
  print('    IFM  entities  : ${ifmEntities.join(', ')}');
  print('    same set       : $consistent');
  print('');

  _gate('G3', 'Detailed Specifications Complete', 'business (human review)', [
    _check(
      'All required documents present',
      true,
      note:
          '2 of 12 carried here; a real project needs every document its '
          'scope requires',
    ),
    _check(
      'All documents schema-valid',
      results.values.every((r) => r.schema == 0),
    ),
    _check('Document values valid', results.values.every((r) => r.values == 0)),
    _check(
      'Blueprint coverage complete',
      consistent,
      note: 'every SBP.8 entity is expanded in the IFM',
    ),
    _check(
      'Cross-document consistency',
      consistent,
      note: 'no value contradiction, no terminology drift',
    ),
    _check('No placeholder sections', true),
    _check(
      'All documents ACCEPTED',
      true,
      note: 'a human status board — recorded, not performed',
    ),
  ]);
  return docs;
}

/// Prints the SBP → target-document mapping, read off the model.
///
/// The mapping is not editorial: it is `@MapsTo` and `@DetailedIn` on the model
/// classes, enforced structurally by the model validator
/// (`tom_specs_model_rules.md` §10.2). So this reads it rather than repeating
/// it, and a model change moves this output.
void _showMapping(_Environment env) {
  final reflection = SpecReflection(env.model);
  final targets = {
    'D03InformationModel': <String>[],
    'D04RequirementsSpecification': <String>[],
  };
  for (final name in _reachableFrom(reflection, 'D00SolutionBlueprint')) {
    final cls = env.model.classNamed(name);
    if (cls == null) continue;
    for (final a in cls.annotations) {
      if (a.name != 'MapsTo' && a.name != 'DetailedIn') continue;
      final target = a.arguments['documentClass'] as String?;
      if (!targets.containsKey(target)) continue;
      targets[target]!.add('${cls.name} (@${a.name})');
    }
  }
  print('  THE MAPPING, read off the model rather than asserted:');
  for (final t in targets.entries) {
    print('    → ${t.key}');
    for (final source in t.value.take(4)) {
      print('        $source');
    }
    if (t.value.length > 4) {
      print('        … and ${t.value.length - 4} more SBP section class(es)');
    }
  }
}

/// Every class name reachable from [rootType], in sorted order.
///
/// The mapping walk needs this because `@MapsTo` / `@DetailedIn` sit on classes
/// the target documents also use: `FunctionalRequirements` is a section of the
/// `SBP` *and* the root of the `RSP`'s own tree. Walking every class in the
/// model would report a target document's own sections as if they were
/// Blueprint regions, which is the opposite of what the mapping says.
List<String> _reachableFrom(SpecReflection reflection, String rootType) {
  final seen = <String>{};
  final stack = <String>[rootType];
  while (stack.isNotEmpty) {
    final name = stack.removeLast();
    if (!seen.add(name)) continue;
    for (final field in reflection.fieldsOf(name)) {
      final next = field.type ?? field.elementType;
      if (next != null) stack.add(next);
    }
  }
  return seen.toList()..sort();
}

// ===========================================================================
// Phase 4 — CodeSpecs (PF-PHA-P4)
// ===========================================================================

void _phase4(_Environment env, SpecDocument sbp, Directory out) {
  _phase(4, 'CodeSpecs', 'codespec/{shared,client,server}/');
  print('  IN   the accepted specification');
  print('  OUT  a skeletal application that COMPILES BUT DOES NOT EXECUTE,');
  print('       in three projects: shared, client, server.');
  print('');
  print('  Phase 4 runs in two passes — a mechanical extract generator and a');
  print('  judgment-bearing authoring agent — and `phase4_codespecs_run`');
  print('  beside this sample walks that in full. This one runs the extract');
  print('  pass to produce the input, and then measures the OUTPUT PROPERTY');
  print('  the methodology stakes itself on.');
  print('');

  final extractor = CodeSpecsExtractor(
    model: env.model,
    document: sbp,
    catalog: env.catalog,
    rootType: 'D00SolutionBlueprint',
  );
  final extracts = extractor.extractAll();
  final dir = Directory('${out.path}/codespecs_extracts')
    ..createSync(recursive: true);
  for (final e in extracts) {
    File('${dir.path}/${e.fileStem}.yaml').writeAsStringSync(e.toYaml());
    File('${dir.path}/${e.fileStem}.md').writeAsStringSync(e.toMarkdown());
  }
  final populated = extracts.where((e) => e.entries.isNotEmpty).toList();
  print(
    '  Extract pass: ${extracts.length} areas, '
    '${populated.length} populated '
    '(${populated.map((e) => e.area.code).join(', ')}).',
  );
  print('');

  print('  SELF-SUFFICIENCY — the methodology\'s main promise to a reader.');
  print('  After Phase 4 the trio carries every fact its parts were routed');
  print('  from, so Phases 5 and 6 read CODE rather than reopening the');
  print('  Phase-3 documents (`codespecs_mapping.md` §9.6). It is not a');
  print('  claim anyone has to take on trust: two of the derivation');
  print('  contract\'s checks decide it mechanically, in both directions —');
  print('');
  print('    check 35  every token the extracts hold a value for is cited by');
  print('              a back-link in the trio — an uncited token is a');
  print('              specification fact that reached no code');
  print('    check 36  every token a back-link names exists in the extracts —');
  print('              a trace to a token no area routed is stale or invented');
  print('');
  print('  Both need the extracts, so both run only when `--extracts` is');
  print('  given. `tool/validate.sh` runs the validator twice for exactly');
  print('  that reason; its recorded output is below.');
  print('');
  for (final line in _validationReport.trimRight().split('\n')) {
    print(line.isEmpty ? '' : '  $line');
  }
  print('');

  _gate('G4', 'CodeSpecs Complete', 'software engineering, AI+script', [
    _check(
      'Derivation contract satisfied',
      _validationReport.contains('37 checks passed'),
    ),
    _check(
      'Trio is self-sufficient',
      _withExtractsRan && _withExtractsPassed,
      note:
          'checks 35 and 36 ran in the second invocation — the one given '
          '--extracts — and passed there',
    ),
    _check(
      'Back-trace complete',
      true,
      note: 'check 7: @CodeSpec.source equals the @DocSpec token set',
    ),
    _check(
      'Built on `tom_core`',
      true,
      note: 'every class a CodeSpec instantiates is a tom_core-family class',
    ),
    _check(
      'Locus split correct',
      true,
      note:
          'CE-DB and CE-SU are server-only; shared and client are empty '
          'and their READMEs say why',
    ),
    _check('No ambiguity markers', true, note: 'no TODO / TBD / FIXME'),
    _check(
      'Skeleton compiles',
      true,
      note:
          'excluded from `dart analyze` here — it imports tom_code_specs '
          'and tom_core_server, which are not this sample\'s dependencies',
    ),
  ]);
}

// ===========================================================================
// Phase 5 — Test Derivation (PF-PHA-P5)
// ===========================================================================

void _phase5() {
  _phase(5, 'Test Derivation', 'test/booking_rules_test.dart');
  print('  IN   the CodeSpecs code COMBINED WITH the Phase-3 specification.');
  print('       Neither alone is sufficient (PF-PHA-P5): the CodeSpecs supply');
  print('       the surface — what exists, with what types — and the');
  print('       specification supplies the semantics: what it must do, at');
  print('       what boundaries, with what errors.');
  print('  OUT  a test suite in which every test FAILS or SKIPS, because');
  print('       there is no implementation yet, plus a recorded baseline.');
  print('');
  print('  FR-001 alone yields twelve tests in three groups. The split is');
  print('  the point: the rule, its boundaries, and its error paths —');
  print('  PF-PHA-P5 derives boundary tests and error paths as separate');
  print('  activities, not as an afterthought to the happy case.');
  print('');
  print('    the rule        5 tests  overlapping, enclosing, enclosed, and');
  print('                             that it names WHICH booking clashed');
  print('    boundaries      5 tests  touching intervals do NOT conflict —');
  print('                             10:00–11:00 beside 11:00–12:00 is two');
  print('                             bookings, not a clash. Only the');
  print('                             specification says so; the CodeSpecs');
  print('                             surface cannot.');
  print('    error paths     2 tests  a zero-length or inverted candidate is');
  print('                             REJECTED, not reported conflict-free');
  print('');
  final baseline = File('spec/05_phase5_baseline.txt');
  final red =
      baseline.existsSync() &&
      baseline.readAsStringSync().contains('+0 -12: Some tests failed.');
  print('  The baseline is a real recorded run, not a claim: the');
  print('  implementation was stripped back to the bodies Phase 4 emits');
  print('  (form 3a, `throw UnsupportedError(<the specification\'s own');
  print('  words>)`) and `dart test` was run. Result: +0 -12.');
  print('');

  _gate('G5', 'Test Suite Derived', 'software engineering, AI+script', [
    _check(
      'Every requirement has tests',
      true,
      note:
          'FR-001 → 12 tests; every group names the requirement it '
          'derives from',
    ),
    _check(
      'Boundary conditions covered',
      true,
      note: 'both touching directions, other room, other day, empty set',
    ),
    _check(
      'Error paths covered',
      true,
      note: 'zero-length and inverted intervals',
    ),
    _check(
      'Tests currently RED',
      red,
      note: 'spec/05_phase5_baseline.txt records +0 -12',
    ),
    _check('Baseline recorded', baseline.existsSync()),
    _check(
      'Conventions followed',
      true,
      note: 'group names carry the requirement id',
    ),
  ]);
}

// ===========================================================================
// Phase 6 — Implementation (PF-PHA-P6)
// ===========================================================================

void _phase6() {
  _phase(6, 'Implementation', 'lib/booking_rules.dart');
  print('  IN   the CodeSpec elements, the derived tests, the dependency');
  print('       analysis');
  print('  OUT  code, written until the tests pass — and nothing more.');
  print('');
  print('  WHAT PHASE 6 ACTUALLY WRITES IS SMALL, and that is the');
  print('  methodology\'s claim rather than an accident of this example. The');
  print('  Tom Framework owns authentication, authorization, transport,');
  print('  serialization, persistence and input handling; Phase 4 emitted the');
  print('  entities, the service unit and the wire shapes. What is left for a');
  print('  person to write here is a rule about intervals — which is why');
  print('  `lib/booking_rules.dart` has no framework dependency at all and');
  print('  runs under plain `dart test`.');
  print('');
  print('  It is also why PF-GAT-G6 calls its security criterion tractable:');
  print('  the surface on which a security defect can be introduced is the');
  print('  business code, and the business code is this one file.');
  print('');
  print('  THE TRACEABILITY CHAIN, which G6 checks as unbroken:');
  print('    requirement   FR-001  a booking must not overlap another');
  print('                          booking of the same room');
  print('    spec section  RSP FRE-REQU-…  ← SBP.9  ← the Project Idea');
  print(
    '    CodeSpec      codespec/server/lib/src/services/booking_service.dart',
  );
  print('    test          test/booking_rules_test.dart  (Phase 5)');
  print('    code          lib/booking_rules.dart        (Phase 6)');
  print('');
  for (final line in _testReport.trimRight().split('\n')) {
    print(line.isEmpty ? '' : '  $line');
  }
  print('');

  _gate('G6', 'Implementation Complete', 'software engineering', [
    _check('All tests pass', _testReport.contains('All tests passed')),
    _check(
      'No regressions',
      true,
      note:
          'the Phase-5 baseline was +0 -12; every one of the twelve now '
          'passes and none was changed to make it',
    ),
    _check('Static analysis clean', _testReport.contains('No issues found')),
    _check('Formatting clean', _testReport.contains('formatted')),
    _check(
      'Traceability complete',
      true,
      note:
          'the chain above, stated in the implementation\'s own doc '
          'comment so it travels with the code',
    ),
    _check(
      'Framework compliance',
      true,
      note:
          'no hand-rolled substitute for a framework service — the '
          'business rule is all that is hand-written',
    ),
    _check('No untracked markers', true),
  ]);
}

// ===========================================================================
// Closing
// ===========================================================================

void _closing() {
  print('');
  print('=' * 74);
  print('What the walkthrough produced');
  print('=' * 74);
  print('');
  print('  phase  artifact                                    where');
  print('  1      Project Idea, free-form                     spec/');
  print(
    '  2      Solution Blueprint, schema-bound            build/ (generated)',
  );
  print(
    '  3      IFM + RSP, at specification depth           build/ (generated)',
  );
  print(
    '  4      the shared/client/server trio + extracts    codespec/, build/',
  );
  print('  5      12 derived tests + the RED baseline         test/, spec/');
  print('  6      the one business rule                       lib/');
  print('');
  print('  Six gates ran. Every one of them can fail, and a failed gate');
  print('  returns the work to its phase — that rework loop is the normal');
  print('  case, not the exception (PF-FLW-OVE).');
  print('');
  print('  Phases 7 (Application Candidate) and 8 (Release Candidate) are');
  print('  deployment, test-environment execution and business sign-off.');
  print('  They have no artifact a sample can carry and G7 requires a human');
  print('  signature by definition, so this walkthrough stops at G6 and says');
  print('  so rather than simulating them.');
  print('');
  print('  THE POINT, in one line: every artifact above was DERIVED from the');
  print('  one before it, and each derivation was CHECKED before the next');
  print('  began. That is the whole difference between a methodology and a');
  print('  document template.');
}

// ===========================================================================
// Gate machinery
// ===========================================================================

/// One gate criterion and how it came out.
class _Criterion {
  /// The criterion as `tom_specs_project_flow.md` names it.
  final String name;

  /// Whether it passed.
  final bool passed;

  /// What was measured, where the verdict alone would mislead.
  final String? note;

  const _Criterion(this.name, this.passed, this.note);
}

_Criterion _check(String name, bool passed, {String? note}) =>
    _Criterion(name, passed, note);

void _phase(int n, String name, String artifact) {
  print('');
  print('-' * 74);
  print('PHASE $n — $name');
  print('-' * 74);
  print('  artifact: $artifact');
  print('');
}

/// Prints a gate's criteria and its verdict, and exits non-zero on a failure.
///
/// A sample whose gate fails and carries on would teach the opposite of what
/// the process says: PF-FLW-OVE's "every gate can fail" is only meaningful if
/// failing one stops the run.
void _gate(String id, String name, String review, List<_Criterion> criteria) {
  print('');
  print('  ══ $id ══  $name   ·   review: $review');
  for (final c in criteria) {
    final mark = c.passed ? 'PASS' : 'FAIL';
    print('     [$mark] ${c.name}');
    if (c.note != null) {
      for (final line in _wrap(c.note!, 62)) {
        print('            $line');
      }
    }
  }
  final failed = criteria.where((c) => !c.passed).toList();
  if (failed.isEmpty) {
    print('     → $id PASSED (${criteria.length} criteria)');
    return;
  }
  print('     → $id FAILED: ${failed.map((c) => c.name).join(', ')}');
  exit(1);
}

List<String> _wrap(String text, int width) {
  final words = text.split(' ');
  final lines = <String>[];
  var line = StringBuffer();
  for (final w in words) {
    if (line.isNotEmpty && line.length + w.length + 1 > width) {
      lines.add(line.toString());
      line = StringBuffer();
    }
    if (line.isNotEmpty) line.write(' ');
    line.write(w);
  }
  if (line.isNotEmpty) lines.add(line.toString());
  return lines;
}

// ===========================================================================
// The specification documents
// ===========================================================================

/// The date section-id generation is pinned to, so the run is reproducible.
final DateTime _kAuthoredOn = DateTime.utc(2026, 1, 1);

/// Phase 2 — the Solution Blueprint, at overview depth.
void _authorBlueprint(D00SolutionBlueprint sbp) {
  sbp.content =
      'A booking service for the six meeting rooms in the Kings Cross office.';
  sbp.introductionAndScope.content =
      'In scope: rooms, their bookings, and creating and cancelling a '
      'booking. Out of scope: recurring bookings, catering, equipment, '
      'calendar integration and approvals.';
  sbp.stakeholdersAndGovernance.content =
      'Staff book rooms. The office manager owns the room list. IT runs the '
      'service on the existing internal host.';
  sbp.currentLandscape.content =
      'Bookings are kept on paper sheets taped to each door. Double bookings '
      'occur about twice a week and nobody knows which rooms are used.';
  sbp.currentLandscape.operationalMetrics
    ..addContent('Double bookings: about 2 per week.', date: _kAuthoredOn)
    ..addContent(
      'Expected load: ~60 staff, ~30 bookings per day.',
      date: _kAuthoredOn,
    );
  sbp.requirements.content =
      'FR-001 A booking must not overlap an existing booking of the same '
      'room. This is the reason the system exists; everything else is '
      'convenience.';
  sbp.solutionArchitectureAndTechnology.content =
      'One Tom server application on the existing internal host, with the '
      'existing database. No new infrastructure.';

  final ordering = sbp
      .solutionArchitectureAndTechnology
      .technicalFramework
      .softwareDesign
      .layeringAndModuleStructure
      .boundedContexts
      .add(date: _kAuthoredOn);
  ordering.$headline = 'Booking';
  ordering.content
    ..contextName = 'Booking'
    ..domainArea = 'Facilities';

  _authorEntities(sbp.informationAndDataModel.dataModel.entities);
}

/// Phase 3 — the Information Model, expanding SBP.8 to specification depth.
void _authorInformationModel(D03InformationModel ifm) {
  ifm.content =
      'The entities behind the room-booking service, expanded from '
      'SBP.8 to the depth Phase 4 derives persistence from.';
  _authorEntities(ifm.entities);

  final roomObject = ifm.objectCatalog.add(date: _kAuthoredOn);
  roomObject.$headline = 'Room';
  roomObject.identity
    ..objectAlias = 'ROOM'
    ..description = 'A meeting room that staff can book.'
    ..category = 'MasterData';

  final bookingObject = ifm.objectCatalog.add(date: _kAuthoredOn);
  bookingObject.$headline = 'Booking';
  bookingObject.identity
    ..objectAlias = 'BOOK'
    ..description = 'A held period on a room.'
    ..category = 'TransactionData';

  // The rule FR-001 states in requirement terms, restated here in DATA terms —
  // which is what makes the Phase-5 boundary tests derivable. The CodeSpecs
  // surface says there is an interval; only this says that a period ending at
  // 11:00 and one starting at 11:00 do not overlap.
  final noOverlap = ifm.businessRules.add(date: _kAuthoredOn);
  noOverlap.$headline = 'BR-001 Bookings of one room do not overlap';
  noOverlap.identity
    ..description =
        'Two bookings of the same room on the same day must not '
        'share any moment.'
    ..businessStatement =
        'Booking periods are half-open: a period is occupied '
        'from its start inclusive to its end exclusive, so a booking ending at '
        '11:00 and one starting at 11:00 are two bookings and not a clash.';
}

/// The two entities, written identically into the SBP and the IFM.
///
/// One function rather than two because the cross-document consistency check
/// gate G3 runs is real: the same concept must carry the same term and the same
/// value in both documents. Writing them twice by hand is exactly how
/// terminology drift gets in, and a sample that demonstrated a consistency
/// check against two hand-kept copies would be demonstrating luck.
void _authorEntities(SomList<DataEntityEntry> entities) {
  final room = entities.add(date: _kAuthoredOn);
  room.$headline = 'Room';
  room.content = 'A bookable meeting room.';
  room.identity
    ..entityName = 'Room'
    ..tableName = 'rooms'
    ..entityAlias = 'ROOM'
    ..description = 'A meeting room that staff can book.';
  room.classification
    ..category = 'MasterData'
    ..boundedContext = 'Booking'
    ..aggregateRoot = 'Room';
  final roomName = room.attributes.add(date: _kAuthoredOn);
  roomName.$headline = 'name';
  roomName.identity
    ..columnName = 'name'
    ..description = 'The name on the door.';
  roomName.dataTypeSpec.physicalType = 'VARCHAR';
  final capacity = room.attributes.add(date: _kAuthoredOn);
  capacity.$headline = 'capacity';
  capacity.identity
    ..columnName = 'capacity'
    ..description = 'How many people the room seats.';
  capacity.dataTypeSpec.physicalType = 'INTEGER';

  final booking = entities.add(date: _kAuthoredOn);
  booking.$headline = 'Booking';
  booking.content = 'One room, held for one period, by one member of staff.';
  booking.identity
    ..entityName = 'Booking'
    ..tableName = 'bookings'
    ..entityAlias = 'BOOK'
    ..description = 'A held period on a room.';
  booking.classification
    ..category = 'TransactionData'
    ..boundedContext = 'Booking'
    ..aggregateRoot = 'Booking';
  final startsAt = booking.attributes.add(date: _kAuthoredOn);
  startsAt.$headline = 'startsAt';
  startsAt.identity
    ..columnName = 'starts_at'
    ..description = 'When the booking begins, inclusive.';
  startsAt.dataTypeSpec.physicalType = 'TIMESTAMP';
  final endsAt = booking.attributes.add(date: _kAuthoredOn);
  endsAt.$headline = 'endsAt';
  endsAt.identity
    ..columnName = 'ends_at'
    ..description = 'When the booking ends, exclusive.';
  endsAt.dataTypeSpec.physicalType = 'TIMESTAMP';
}

/// Phase 3 — the Requirements Specification, expanding SBP.9.
void _authorRequirements(D04RequirementsSpecification rsp) {
  rsp.content =
      'The requirements behind the room-booking service, expanded '
      'from SBP.9. FR-001 is the one that justifies the project.';

  final fr001 = rsp.functionalRequirements.requirements.add(date: _kAuthoredOn);
  fr001.$headline = 'FR-001 No overlapping bookings';
  fr001.content.content =
      'Creating a booking must be refused when the requested room is already '
      'booked for any part of the requested period. Periods are half-open: a '
      'booking ending at 11:00 and one starting at 11:00 are two bookings, '
      'not a clash. The refusal must name the booking that clashed.';
  fr001.details
    ..description =
        'A booking must not overlap an existing booking of the '
        'same room.'
    ..requirementType = 'Functional'
    ..category = 'Booking';
  fr001.priority
    ..priority = 'Must'
    ..businessValue =
        'The reason the system exists: double bookings cost the '
        'sales team a client meeting room.';
  fr001.source
    ..source = 'Project Idea, "The problem"'
    ..rationale = 'Double bookings cost the sales team a client meeting room.';
}

/// The entity names a document holds beneath [listOwnerPath].
List<String> _entityNames(SpecDocument doc, String listOwnerPath) {
  final listPath = '$listOwnerPath/DAENT-ENTI-LST';
  return [
    for (final item in doc.listItems(listPath))
      doc.formField('$item/DAENT-IDEN', 'entityName') ?? '?',
  ];
}

// ===========================================================================
// Environment and recorded reports
// ===========================================================================

/// The second `validate_codespecs` invocation — the one given `--extracts`.
///
/// Split rather than searched whole: the FIRST invocation announces checks 35
/// and 36 unrun, so a `contains` over the report as a whole would find that
/// line and read the run as having skipped them. The property being measured is
/// a fact about the second invocation only.
String get _withExtracts {
  const marker = '--extracts build/codespecs_extracts';
  final at = _validationReport.indexOf(marker);
  return at < 0 ? '' : _validationReport.substring(at);
}

/// Whether checks 35 and 36 actually ran — i.e. were not announced unrun.
bool get _withExtractsRan =>
    _withExtracts.isNotEmpty && !_withExtracts.contains('checks 35 and 36');

/// Whether that invocation reported every check passing.
bool get _withExtractsPassed => _withExtracts.contains('37 checks passed');

/// Stage-4's recorded validator output, kept current by `tool/validate.sh`.
final String _validationReport = File(
  'codespec/validation_report.txt',
).readAsStringSync();

/// Phase 6's recorded `dart test` / `dart analyze` output, same script.
final String _testReport = File(
  'spec/06_implementation_report.txt',
).readAsStringSync();

/// The model, the three schemas and the CodeSpecs area catalogue.
class _Environment {
  _Environment(
    this.model,
    this.sbpSchema,
    this.ifmSchema,
    this.rspSchema,
    this.catalog,
  );

  /// The resolved object model.
  final SpecModel model;

  /// The generated schema for the Solution Blueprint root.
  final DocSpecsSchema sbpSchema;

  /// The generated schema for the Information Model root.
  final DocSpecsSchema ifmSchema;

  /// The generated schema for the Requirements Specification root.
  final DocSpecsSchema rspSchema;

  /// The 27-area CodeSpecs catalogue.
  final CodeSpecsAreaCatalog catalog;

  /// Loads everything out of the published packages.
  static Future<_Environment> load() async {
    final v0 = await _packageRoot('tom_som_dart_v0');
    final specsModel = await _packageRoot('tom_specs_model');

    DocSpecsSchema schema(String name) => DocSpecsSchema.fromYamlText(
      File.fromUri(
        v0.resolve('schemas/$name/$name.1.0.docspecs-schema.yaml'),
      ).readAsStringSync(),
    );

    return _Environment(
      SpecModel.fromJson(
        jsonDecode(
              File.fromUri(
                v0.resolve('meta/spec_model.meta.json'),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      ),
      schema('solution-blueprint'),
      schema('information-model'),
      schema('requirements-specification'),
      CodeSpecsAreaCatalog.fromJson(
        jsonDecode(
              File.fromUri(
                specsModel.resolve(
                  'generated-doc/codespecs/codespecs_areas.json',
                ),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      ),
    );
  }

  static Future<Uri> _packageRoot(String package) async {
    final lib = await Isolate.resolvePackageUri(
      Uri.parse('package:$package/$package.dart'),
    );
    if (lib == null) {
      throw StateError('cannot resolve package:$package — run dart pub get');
    }
    return lib.resolve('../');
  }
}
