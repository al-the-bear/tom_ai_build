// TomSpecs sample — a complete Phase 4 CodeSpecs run.
//
// Run:  dart pub get && dart run
//
// Phase 4 turns a specification into a compiling code skeleton. It runs in TWO
// PASSES with a hard boundary between them, and that boundary is the single
// thing readers get wrong — so every step below is marked [MECHANICAL] or
// [JUDGMENT]:
//
//   stage 1  the starting prompt's quality gate   [MECHANICAL]
//   stage 2  the extract generator                [MECHANICAL]
//   stage 3  the authoring agent                  [JUDGMENT]
//   stage 4  validating the emitted trio          [MECHANICAL]
//
// The extract generator may copy and index. It may not summarise, rephrase,
// compose a sentence from field values, or choose a name — each of those is the
// authoring agent's, which is what makes stage 3 a prompt pass rather than a
// compiler pass.
//
// codespecs_mapping.md §1.1.1 is the production contract; codespecs_prompt.md
// is the gate stage 1 runs; codespecs_derivation_contract.md is what stage 3 is
// held to and what stage 4 checks.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

Future<void> main() async {
  final inputs = await _Inputs.load();

  _rule('A Phase 4 CodeSpecs run, stage by stage');
  print('Every step is marked [MECHANICAL] or [JUDGMENT].');
  print('');

  final extracts = _variantA(inputs);
  _variantB(inputs);

  print('');
  print('Extracts written to build/codespecs_extracts/ '
      '(${extracts.length * 2} files).');
}

// ---------------------------------------------------------------------------
// Variant A — a document that passes, taken all the way to validated code.
// ---------------------------------------------------------------------------

List<CodeSpecsExtract> _variantA(_Inputs inputs) {
  final doc = SpecDocument();
  _authorSpecification(D00SolutionBlueprint(doc), aggregateRoots: true);

  _rule('Variant A — a sufficient specification');
  print('0. The document under Phase 4                 [input]');
  print('   a Solution Blueprint whose information model holds 2 entities');
  print('   and 3 stored attributes; every other section is unwritten.');
  print('');

  final gate = _runGate(inputs, doc);
  if (!gate.passed) {
    stderr.writeln('variant A was supposed to pass the gate');
    exit(1);
  }
  print('   gate verdict             : PASS — the run may begin');
  print('');

  final extracts = gate.extracts!;
  _stage2(extracts);
  _stage3(extracts);
  _stage4();
  return extracts;
}

// ---------------------------------------------------------------------------
// Variant B — the same document with one required field cleared.
// ---------------------------------------------------------------------------

void _variantB(_Inputs inputs) {
  final doc = SpecDocument();
  _authorSpecification(D00SolutionBlueprint(doc), aggregateRoots: false);

  _rule('Variant B — the same document, one required field cleared');
  print('Both entities keep their `DAENT-CLAS` section and its `category`, and');
  print('both have `aggregateRoot` cleared. Nothing else changed.');
  print('');

  final gate = _runGate(inputs, doc);
  if (gate.passed) {
    stderr.writeln('variant B was supposed to be rejected');
    exit(1);
  }
  print('   gate verdict             : REJECTED — the run may not begin');
  print('');
  print('   What A1 names, per violation:');
  for (final v in gate.a1) {
    print('     line ${v.line}: ${v.rule.name} [${v.sectionId}] ${v.message}');
  }
  print('');
  print('   A2 did not move: ${gate.a2.length} violations, the same as');
  print('   variant A. Clearing a required field REMOVES a value, and a');
  print('   validator that checks values has nothing left to object to. That');
  print('   is why the gate runs both tiers and not either one');
  print('   (codespecs_prompt.md §4.1/§4.2 and its §10.2 fixture).');
  print('');
}

// ---------------------------------------------------------------------------
// Stage 1 — the mechanical gate (codespecs_prompt.md §4).
// ---------------------------------------------------------------------------

/// What one run of the mechanical tier produced.
class _GateResult {
  /// A1's violations — the document's markdown against its DocSpecs schema.
  final List<DocSpecsViolation> a1;

  /// A2's violations — the instance tier over the document's own values.
  final List<SpecValidationError> a2;

  /// A3's failure, or `null` when the routing walk was total.
  final CodeSpecsExtractError? a3;

  /// The per-area extracts, present only when all three tiers passed.
  final List<CodeSpecsExtract>? extracts;

  const _GateResult(this.a1, this.a2, this.a3, this.extracts);

  /// Whether the run may begin.
  bool get passed => a1.isEmpty && a2.isEmpty && a3 == null;
}

/// Runs the mechanical tier over [doc] and prints each check's verdict.
///
/// All three run unconditionally rather than short-circuiting: a project fixing
/// one wants to see the rest (`codespecs_prompt.md` §4).
_GateResult _runGate(_Inputs inputs, SpecDocument doc) {
  print('1. The starting prompt\'s quality gate        [MECHANICAL]');

  final markdown = doc.toMarkdown(inputs.model, rootType: _kRoot);
  final a1 = DocSpecsValidator(inputs.schema).validateMarkdown(markdown);
  print('   A1 schema completeness   : ${_verdict(a1.length)}');

  final a2 = validateDocument(inputs.model, doc);
  print('   A2 instance-tier values  : ${_verdict(a2.length)}');

  // A3 is not a separate pass over the tree: the extractor's strict walk throws
  // on the first section carrying none of the three routing verdicts, so
  // running the extraction IS the routing-totality check
  // (`tom_specs_model_rules.md` §10.2 ROUTE-TOTAL).
  final extractor = CodeSpecsExtractor(
    model: inputs.model,
    document: doc,
    catalog: inputs.catalog,
    rootType: _kRoot,
  );
  try {
    final extracts = extractor.extractAll();
    print('   A3 routing totality      : pass — '
        '${extractor.routings().length} sections walked, all routed');
    print('   A4 / A5                  : not run here — required-argument');
    print('                              sources and carrier presence are');
    print('                              read off the per-marker argument');
    print('                              table, which the generator owns and');
    print('                              the SOM runtimes do not ship.');
    return _GateResult(a1, a2, null, a1.isEmpty && a2.isEmpty ? extracts : null);
  } on CodeSpecsExtractError catch (e) {
    print('   A3 routing totality      : FAIL — ${e.message}');
    return _GateResult(a1, a2, e, null);
  }
}

// ---------------------------------------------------------------------------
// Stage 2 — the extract generator.
// ---------------------------------------------------------------------------

void _stage2(List<CodeSpecsExtract> extracts) {
  print('2. The extract generator                      [MECHANICAL]');

  final populated = extracts.where((e) => e.entries.isNotEmpty).toList();
  print('   areas in the catalogue   : ${extracts.length}');
  print('   populated                : ${populated.length}');
  for (final e in populated) {
    print('     ${e.area.code.padRight(6)} ${e.entries.length} entries  '
        '→ ${e.projects.join(', ')}');
  }
  print('   empty                    : ${extracts.length - populated.length}');
  print('   Most areas are empty because this document says nothing about');
  print('   screens, jobs, reports or migrations. An empty extract is a');
  print('   CANDIDATE for "not applicable" — never the verdict itself, which');
  print('   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).');

  final dir = Directory('build/codespecs_extracts')..createSync(recursive: true);
  for (final e in extracts) {
    File('${dir.path}/${e.fileStem}.yaml').writeAsStringSync(e.toYaml());
    File('${dir.path}/${e.fileStem}.md').writeAsStringSync(e.toMarkdown());
  }
  print('');
}

// ---------------------------------------------------------------------------
// Stage 3 — the authoring agent.
// ---------------------------------------------------------------------------

void _stage3(List<CodeSpecsExtract> extracts) {
  print('3. The authoring agent                        [JUDGMENT]');
  print('   One prompt pass per area, reading THAT AREA\'S EXTRACT ALONE.');
  print('   Nothing above this line was a choice; everything below it is.');
  print('');

  final db = extracts.firstWhere((e) => e.area.code == 'CE-DB');
  print('   Area ${db.area.code} — ${db.area.canonicalId}');
  print('   built on   : ${db.area.builtOn}');
  print('   may cite   : ${db.citableParts.join(', ')}');
  print('   entries carried to the agent (${db.entries.length}):');
  for (final e in db.entries) {
    print('     ${e.sectionId.padRight(11)} ${e.fieldName.padRight(14)} '
        '${_short(e.value)}');
  }
  print('');
  print('   What the agent wrote from it —');
  print('   codespec/server/lib/src/data_access/customer.dart:');
  print('');
  for (final line in _authoredExample.trimRight().split('\n')) {
    print(line.isEmpty ? '' : '     $line');
  }
  print('');
  print('   CE-API\'s extract holds the same 23 entries and yields NO code');
  print('   here. Its shared wire DTO is derived, not authored: one exists per');
  print('   entity a server operation names, and this document specifies no');
  print('   operations (codespecs_derivation_contract.md §3.2.11 point 1). A');
  print('   NON-empty extract can legitimately produce nothing, exactly as an');
  print('   empty one can be legitimately not applicable. Both are verdicts,');
  print('   and a verdict is judgment.');
  print('');
  print('   Fixed for the agent, not chosen by it: `Customer` is PascalCase of');
  print('   the entity-name field and `customers` is the table field verbatim');
  print('   (codespecs_derivation_contract.md §3.3.1 points 3 and 4); every');
  print('   doc comment is the specification\'s own text (§2.8 C1). Chosen by');
  print('   the agent: that the entity is coding form 1, that the file sits');
  print('   under src/data_access/, and that `late String` — not `String?` —');
  print('   is right where the document authored no storage nullability.');
  print('');
}

// ---------------------------------------------------------------------------
// Stage 4 — validating the trio.
// ---------------------------------------------------------------------------

void _stage4() {
  print('4. Validating the emitted trio                [MECHANICAL]');
  print('   `validate_codespecs.dart` runs the derivation contract\'s §6');
  print('   checks over the shared / client / server trio. It reads emitted');
  print('   Dart with the analyzer\'s parser and never resolves it, so it runs');
  print('   on a tree that has never been through `pub get` — which is what');
  print('   lets a generator validate its own output before anything fetches');
  print('   a dependency.');
  print('');
  print('   Four questions cannot be answered from the trio alone, and each');
  print('   brings its own corroborating input. When one is absent the tool');
  print('   NAMES on stdout the checks it left unrun — so a skipped check');
  print('   never reads as a passed one. Below, recorded by tool/validate.sh,');
  print('   the same trio validated twice: once without the extracts and once');
  print('   with them.');
  print('');
  for (final line in _validationReport.trimRight().split('\n')) {
    print(line.isEmpty ? '' : '   $line');
  }
  print('');
  print('   Supplying --extracts moved six checks from "not run" to "ran".');
  print('   That is the whole reason the extract is an artifact of record and');
  print('   not a transient buffer: it is the only place the specification\'s');
  print('   own sentences survive, and checks 32-34 hold every emitted doc');
  print('   comment against them. No reading of the code alone can tell a');
  print('   copied sentence from a composed one.');
  print('');
}

// ---------------------------------------------------------------------------
// The specification.
// ---------------------------------------------------------------------------

/// The one `@Document` root this run extracts from (`codespecs_prompt.md` §5).
const String _kRoot = 'D00SolutionBlueprint';

/// The creation date section-id generation is pinned to.
///
/// `SomList.add` derives a new item's id from the current date, so an unpinned
/// run would emit different ids every day and `expected_output.txt` would be a
/// record of the day it was taken rather than of the pipeline.
final DateTime _kAuthoredOn = DateTime.utc(2026, 1, 1);

/// Authors the specification this run operates on.
///
/// Deliberately small: two entities and three attributes populate one area and
/// leave the rest empty, which is what puts stage 2's "most areas are empty,
/// and that is not yet a verdict" on one screen.
///
/// [aggregateRoots] `false` clears the one required field variant B gutss —
/// `DAENT-CLAS.aggregateRoot` — and changes nothing else.
void _authorSpecification(
  D00SolutionBlueprint sbp, {
  required bool aggregateRoots,
}) {
  sbp.content = 'Order intake for a single region.';

  // The bounded context CE-SU's required `boundedContext` argument resolves
  // against: `DAENT-CLAS.boundedContext` carries `refersTo: ['BCE.contextName']`,
  // so an unauthored registry would make the reference dangle at A2.
  final ordering = sbp.solutionArchitectureAndTechnology.technicalFramework
      .softwareDesign.layeringAndModuleStructure.boundedContexts
      .add(date: _kAuthoredOn);
  ordering.$headline = 'Ordering';
  ordering.content
    ..contextName = 'Ordering'
    ..domainArea = 'Order management';

  final entities = sbp.informationAndDataModel.dataModel.entities;

  final customer = entities.add(date: _kAuthoredOn);
  customer.$headline = 'Customer';
  customer.content = 'A party that places orders.';
  customer.identity
    ..entityName = 'Customer'
    ..tableName = 'customers'
    ..entityAlias = 'CUST'
    ..description = 'A person or organisation that places orders.';
  customer.classification
    ..category = 'MasterData'
    ..boundedContext = 'Ordering';
  if (aggregateRoots) customer.classification.aggregateRoot = 'Customer';

  final email = customer.attributes.add(date: _kAuthoredOn);
  email.$headline = 'email';
  email.identity
    ..columnName = 'email'
    ..description = 'The address order confirmations are sent to.';
  email.dataTypeSpec.physicalType = 'VARCHAR';

  final displayName = customer.attributes.add(date: _kAuthoredOn);
  displayName.$headline = 'displayName';
  displayName.identity
    ..columnName = 'display_name'
    ..description = 'The name the customer trades under.';
  displayName.dataTypeSpec.physicalType = 'VARCHAR';

  final order = entities.add(date: _kAuthoredOn);
  order.$headline = 'Order';
  order.content = 'One accepted customer order.';
  order.identity
    ..entityName = 'Order'
    ..tableName = 'orders'
    ..entityAlias = 'ORD'
    ..description = 'A single order placed by a customer.';
  order.classification
    ..category = 'TransactionData'
    ..boundedContext = 'Ordering';
  if (aggregateRoots) order.classification.aggregateRoot = 'Order';

  final placedAt = order.attributes.add(date: _kAuthoredOn);
  placedAt.$headline = 'placedAt';
  placedAt.identity
    ..columnName = 'placed_at'
    ..description = 'The moment the order was accepted.';
  placedAt.dataTypeSpec.physicalType = 'TIMESTAMP';
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

/// The stage-3 output, read from the trio beside this sample.
///
/// Read rather than inlined so the printed listing and the file the validator
/// checks cannot drift apart: a sample that prints one thing and validates
/// another teaches the wrong lesson twice.
final String _authoredExample =
    File('codespec/server/lib/src/data_access/customer.dart').readAsStringSync();

/// The stage-4 output, recorded by `tool/validate.sh`.
///
/// Recorded rather than run here for the same reason `expected_output.txt`
/// exists at all: `tom_specs_clitool` is a development tool and not a
/// dependency of the emitted code, so shelling out to it would make this
/// program's output depend on whether the workspace happens to be beside it.
/// `tool/validate.sh` re-runs both invocations and fails if this file has gone
/// stale, which is what keeps it a record rather than a claim.
final String _validationReport =
    File('codespec/validation_report.txt').readAsStringSync();

String _verdict(int violations) =>
    violations == 0 ? 'pass — 0 violations' : 'FAIL — $violations violations';

String _short(String value) =>
    value.length <= 44 ? value : '${value.substring(0, 41)}...';

void _rule(String title) {
  print('=' * 72);
  print(title);
  print('=' * 72);
}

/// The three data inputs a Phase 4 run needs, all from published packages.
class _Inputs {
  _Inputs(this.model, this.schema, this.catalog);

  /// The resolved object model — `toMarkdown` and the A2 validator take it.
  final SpecModel model;

  /// The DocSpecs schema A1 checks the markdown rendition against.
  final DocSpecsSchema schema;

  /// The 27-area catalogue the extractor walks
  /// (`codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6).
  final CodeSpecsAreaCatalog catalog;

  /// Loads all three out of the published packages.
  ///
  /// All three ship as data rather than as Dart, so each is reached through its
  /// package URI.
  static Future<_Inputs> load() async {
    final v0 = await _packageDir('tom_som_dart_v0');
    final specsModel = await _packageDir('tom_specs_model');

    final model = SpecModel.fromJson(
      jsonDecode(File.fromUri(v0.resolve('meta/spec_model.meta.json'))
          .readAsStringSync()) as Map<String, dynamic>,
    );

    final schema = DocSpecsSchema.fromYamlText(
      File.fromUri(v0.resolve('schemas/solution-blueprint/'
              'solution-blueprint.1.0.docspecs-schema.yaml'))
          .readAsStringSync(),
    );

    final catalog = CodeSpecsAreaCatalog.fromJson(
      jsonDecode(File.fromUri(specsModel
                  .resolve('generated-doc/codespecs/codespecs_areas.json'))
              .readAsStringSync())
          as Map<String, dynamic>,
    );

    return _Inputs(model, schema, catalog);
  }

  /// The root directory of [package], wherever pub put it.
  static Future<Uri> _packageDir(String package) async {
    final lib = await Isolate.resolvePackageUri(
        Uri.parse('package:$package/$package.dart'));
    if (lib == null) {
      throw StateError('cannot resolve package:$package — run dart pub get');
    }
    return lib.resolve('../');
  }
}
