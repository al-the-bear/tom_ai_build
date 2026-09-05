// Phase-4 stage 1 — the extract run over the shared Meridian sample.
//
// Runs the `codespecs_prompt.md` §4 mechanical gate over the committed sample
// document, then produces one extract pair per active CodeSpecs area
// (`codespecs_mapping.md` §1.1.1 item 1) via the Dart runtime's
// `spec_codespecs_extract` surface, writing to the §1.1.1 location:
// `tom_som_conformance/generated-doc/codespecs_extracts/` — the spec-root of
// the Meridian sample being the `tom_som_conformance` project that holds it.
//
// Gate tiers reported (all must pass before extracts are written):
//   A1 — DocSpecs schema completeness of the committed markdown rendition
//   A2 — instance-tier values (`validateDocument`, SOM §9)
//   A3 — routing totality: the extractor's strict walk throws on any section
//        carrying none of the three §8.3 verdicts (`ROUTE-TOTAL`)
//   A4 — DOMEN closed-choice completeness (`codespecs_prompt.md` §4): every
//        stored attribute of kind `enumeration` names, via
//        `DAATT-DTEN.domainEnum`, an authored `DMENE` entry. A miss is a hard
//        rejection naming the attribute and the register section (DOMEN) that
//        should have carried the entry — never a degraded emission.
//
// Re-run after the sample or the model changes:
//
//   dart run tool/build_meridian_extracts.dart
import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart'
    show d00SolutionBlueprintMetaTree;

void main() {
  File at(String relative) => File.fromUri(Platform.script.resolve(relative));

  // --- Load the three inputs ------------------------------------------------
  final sampleFile = at('../../tom_som_conformance/samples/'
      'meridian_order_management.docspecs.yaml');
  final doc =
      SpecDocument.fromFile(sampleFile.path, d00SolutionBlueprintMetaTree);

  final model = SpecModel.fromJson(
      jsonDecode(at('../meta/spec_model.meta.json').readAsStringSync())
          as Map<String, dynamic>);

  final catalog = CodeSpecsAreaCatalog.fromJson(jsonDecode(
          at('../../tom_specs_model/generated-doc/codespecs/'
                  'codespecs_areas.json')
              .readAsStringSync()) as Map<String, dynamic>);

  // --- Gate, tier A1 — schema completeness ----------------------------------
  final markdown =
      at('../../tom_som_conformance/samples/meridian_order_management.md')
          .readAsStringSync();
  final schema = DocSpecsSchema.fromYamlText(at(
          '../schemas/solution-blueprint/'
          'solution-blueprint.1.0.docspecs-schema.yaml')
      .readAsStringSync());
  final a1 = DocSpecsValidator(schema).validateMarkdown(markdown);
  if (a1.isNotEmpty) {
    stderr.writeln('gate A1 FAILS — DocSpecs schema violations:');
    for (final v in a1) {
      stderr.writeln('  $v');
    }
    exit(1);
  }

  // --- Gate, tier A2 — instance values --------------------------------------
  final a2 = validateDocument(model, doc);
  if (a2.isNotEmpty) {
    stderr.writeln('gate A2 FAILS — ${a2.length} instance-tier violations:');
    for (final e in a2) {
      stderr.writeln('  [${e.code.name}] ${e.path}: ${e.message}');
    }
    exit(1);
  }

  // --- Gate, tier A3 + extraction -------------------------------------------
  // The strict walk IS the A3 check: extractAll throws CodeSpecsExtractError
  // on the first section carrying none of the three routing verdicts.
  final extractor = CodeSpecsExtractor(
    model: model,
    document: doc,
    catalog: catalog,
    rootType: 'D00SolutionBlueprint',
  );
  final routings = extractor.routings();
  final List<CodeSpecsExtract> extracts;
  try {
    extracts = extractor.extractAll();
  } on CodeSpecsExtractError catch (e) {
    stderr.writeln('gate A3 FAILS — $e');
    exit(1);
  }

  // --- Gate, tier A4 — DOMEN closed-choice completeness ---------------------
  // An enumeration-kind attribute's column value type IS the generated enum
  // type, so an unresolvable (or absent) enum name blocks the run outright
  // (codespecs_prompt.md §4 — a hard A4 rejection, never a degraded emission).
  final authoredEnums = <String>{};
  for (final r in routings) {
    if (r.className != 'DomainEnumEntry') continue;
    final name = doc.formField('${r.path}/content', 'enumName');
    if (name != null && name.isNotEmpty) authoredEnums.add(name);
  }
  final a4 = <String>[];
  for (final r in routings) {
    if (r.className != 'DataAttributeEntry') continue;
    final kind = doc.formField('${r.path}/DAATT-DATA', 'dataType');
    if (kind != 'enumeration') continue;
    final enumName = doc.formField('${r.path}/DAATT-DTEN', 'domainEnum');
    if (enumName == null || enumName.isEmpty) {
      a4.add('${r.path}: enumeration attribute carries no '
          'DAATT-DTEN.domainEnum — DOMEN cannot type its column');
    } else if (!authoredEnums.contains(enumName)) {
      a4.add('${r.path}: DAATT-DTEN.domainEnum "$enumName" resolves to no '
          'authored DMENE entry — DOMEN should carry it');
    }
  }
  if (a4.isNotEmpty) {
    stderr.writeln('gate A4 FAILS — ${a4.length} enumeration attribute(s) '
        'without a resolvable domain enum:');
    for (final v in a4) {
      stderr.writeln('  $v');
    }
    exit(1);
  }

  // --- Write the extract pairs ----------------------------------------------
  final outDir = Directory.fromUri(Platform.script
      .resolve('../../tom_som_conformance/generated-doc/codespecs_extracts'));
  outDir.createSync(recursive: true);
  for (final x in extracts) {
    File('${outDir.path}/${x.fileStem}.yaml').writeAsStringSync(x.toYaml());
    File('${outDir.path}/${x.fileStem}.md').writeAsStringSync(x.toMarkdown());
  }

  // --- Report ---------------------------------------------------------------
  final byVerdict = <String, int>{};
  for (final r in routings) {
    byVerdict.update(r.verdict.name, (n) => n + 1, ifAbsent: () => 1);
  }
  final total = extracts.fold<int>(0, (n, x) => n + x.entries.length);
  final populated = extracts.where((x) => x.entries.isNotEmpty).toList();

  stdout.writeln('gate A1 passes — markdown validates against '
      'solution-blueprint/1.0');
  stdout.writeln('gate A2 passes — 0 instance-tier violations');
  stdout.writeln('gate A3 passes — ${routings.length} class nodes walked, '
      'every one routed');
  stdout.writeln('gate A4 passes — every enumeration attribute resolves to '
      'an authored DMENE entry (${authoredEnums.length} authored)');
  stdout.writeln('  verdicts: $byVerdict');
  stdout.writeln('Wrote ${extracts.length} extract pairs to '
      '${outDir.absolute.path}');
  stdout.writeln('  $total entries across ${populated.length} populated '
      'areas (${extracts.length - populated.length} empty):');
  for (final x in extracts) {
    stdout.writeln('    ${x.area.code}: ${x.entries.length}');
  }
}
