// Cross-language golden-log generator (roadmap item 7b).
//
// Loads the language-agnostic shared sample
// (`tom_som_conformance/samples/meridian_order_management.docspecs.yaml`) and
// emits a canonical, deterministic log of *essentially every section* read
// through **both** the generic string-path API and the typed facade. The nine
// per-language generators (one per `tom_som_<lang>_v0`) all emit the identical
// byte stream; `tom_som_conformance/tool/compare_golden.dart` then asserts every
// language's log is byte-identical, proving all nine APIs yield exactly the same
// reading of the same specification.
//
// The format is defined once here (the Dart generator is the reference) and
// mirrored verbatim by the other eight. It is intentionally line-oriented,
// LF-terminated, ASCII-path, and value-escaped so it compares byte-for-byte
// across languages regardless of their native string/collection types.
//
// Running this generator is itself a test: it asserts the typed reads equal the
// generic reads before writing, so a facade/runtime divergence aborts with a
// non-zero exit instead of emitting a silently-wrong log.
//
// Usage: dart run tool/golden_log.dart [samplePath] [outputPath]
library;

import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

const _defaultSample =
    '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml';
const _defaultSampleMd =
    '../tom_som_conformance/samples/meridian_order_management.md';
const _defaultSchema =
    'schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml';
const _defaultOutput = '../tom_som_conformance/golden/dart.log';

/// Escapes a value so it occupies exactly one log line: backslash first (so the
/// other escapes are unambiguous), then the three whitespace controls. Paths and
/// field names are ASCII and never contain these, but escaping them too is
/// harmless and keeps the routine uniform.
String esc(String s) => s
    .replaceAll('\\', '\\\\')
    .replaceAll('\n', '\\n')
    .replaceAll('\r', '\\r')
    .replaceAll('\t', '\\t');

void main(List<String> args) {
  final samplePath = args.isNotEmpty ? args[0] : _defaultSample;
  final outputPath = args.length > 1 ? args[1] : _defaultOutput;

  // The shared sample is a hierarchical-v2 `*.docspecs.yaml` (DR9); the
  // one-call loader decodes it against the SBP metadata tree and retains the
  // modelVersion stamp on the document.
  final doc = SpecDocument.fromFile(samplePath, d00SolutionBlueprintMetaTree);
  final sbp = D00SolutionBlueprint(doc, documentVersion: doc.modelVersion);

  final out = <String>[];
  out.add('# TomSpecs SOM golden log — canonical cross-language reading.');
  out.add('# All nine per-language generators must emit byte-identical output.');
  out.add('FORMAT\t5');
  out.add('MODELVERSION\t${esc(doc.modelVersion ?? '')}');

  // --- Generic: every content leaf, sorted by path. ---
  out.add('SECTION\tgeneric-content');
  final contentPaths = doc.contentPaths.toList()..sort();
  for (final p in contentPaths) {
    out.add('C\t$p\t${esc(doc.content(p) ?? '')}');
  }

  // --- Generic: every form section + field, sorted by path then field. ---
  out.add('SECTION\tgeneric-forms');
  final formPaths = doc.formPaths.toList()..sort();
  for (final p in formPaths) {
    final fields = doc.formFieldNames(p).toList()..sort();
    for (final f in fields) {
      out.add('F\t$p\t$f\t${esc(doc.formField(p, f) ?? '')}');
    }
  }

  // --- Generic: every list container + its item paths (document order).
  // FORMAT 3: each item with a *stored* section id additionally emits an
  // `ID` line (item path + stored id); items without one emit no `ID` line. ---
  out.add('SECTION\tgeneric-lists');
  final listPaths = doc.listPaths.toList()..sort();
  for (final p in listPaths) {
    final items = doc.listItems(p);
    out.add('L\t$p\t${items.length}');
    for (final item in items) {
      out.add('I\t$item');
      final id = doc.itemSectionId(item);
      if (id != null) out.add('ID\t$item\t${esc(id)}');
    }
  }

  // --- Generic: every stored headline, sorted by path (FORMAT 3, YRD3). ---
  out.add('SECTION\tgeneric-headlines');
  final headlinePaths = doc.headlinePaths.toList()..sort();
  for (final p in headlinePaths) {
    out.add('H\t$p\t${esc(doc.headline(p) ?? '')}');
  }

  // --- Typed: a curated traversal of the facade that must agree with the
  // generic reads. Every emitted path/value is model-derived, so the lines are
  // identical across languages even though the accessor *names* differ. ---
  out.add('SECTION\ttyped');

  void typedContent(String path, String value) {
    final leaf = '$path/content';
    final generic = doc.content(leaf) ?? '';
    if (value != generic) {
      stderr.writeln('TYPED MISMATCH at $leaf: typed="$value" generic="$generic"');
      exit(2);
    }
    out.add('T\t$leaf\t${esc(value)}');
  }

  typedContent(sbp.path, sbp.content);
  typedContent(sbp.documentControl.path, sbp.documentControl.content);
  typedContent(sbp.introductionAndScope.path, sbp.introductionAndScope.content);
  typedContent(
      sbp.glossaryAndAbbreviations.path, sbp.glossaryAndAbbreviations.content);
  typedContent(sbp.stakeholdersAndGovernance.path,
      sbp.stakeholdersAndGovernance.content);
  typedContent(sbp.currentLandscape.path, sbp.currentLandscape.content);
  typedContent(sbp.assumptionsConstraintsDependencies.path,
      sbp.assumptionsConstraintsDependencies.content);
  typedContent(sbp.targetOperatingModelConcept.path,
      sbp.targetOperatingModelConcept.content);
  typedContent(
      sbp.informationAndDataModel.path, sbp.informationAndDataModel.content);
  typedContent(sbp.requirements.path, sbp.requirements.content);
  typedContent(sbp.solutionArchitectureAndTechnology.path,
      sbp.solutionArchitectureAndTechnology.content);
  typedContent(
      sbp.securityAndAccessModel.path, sbp.securityAndAccessModel.content);
  typedContent(sbp.experienceAndInterfaceDesign.path,
      sbp.experienceAndInterfaceDesign.content);
  typedContent(
      sbp.qualityAndAcceptanceModel.path, sbp.qualityAndAcceptanceModel.content);
  typedContent(sbp.deliveryTransitionAndRollout.path,
      sbp.deliveryTransitionAndRollout.content);

  // Nested section reached through two typed hops.
  typedContent(sbp.introductionAndScope.goals.path,
      sbp.introductionAndScope.goals.content);

  // A typed list traversal: length + each element's content, each asserted
  // against the generic list-item read.
  final metrics = sbp.currentLandscape.operationalMetrics;
  final metricItemPaths = doc.listItems(metrics.listPath);
  if (metrics.length != metricItemPaths.length) {
    stderr.writeln('TYPED LIST LENGTH MISMATCH at ${metrics.listPath}');
    exit(2);
  }
  out.add('TL\t${metrics.listPath}\t${metrics.length}');
  for (var i = 0; i < metrics.length; i++) {
    final elem = metrics[i];
    final leaf = '${elem.path}/content';
    final generic = doc.content(leaf) ?? '';
    if (elem.content != generic) {
      stderr.writeln('TYPED LIST ITEM MISMATCH at $leaf');
      exit(2);
    }
    out.add('TI\t$leaf\t${esc(elem.content)}');
  }

  // --- Typed role fields (FORMAT 5, YRD6): the FRE content form's id-role
  // (`requirementId`) and title-role (`title`) fields are pure views onto the
  // owning list item's stored section id / headline. Each typed read is
  // asserted against the generic itemSectionId/headline read before emission,
  // proving the view binding end-to-end in every language. ---
  final freReqs =
      sbp.introductionAndScope.requirements.functionalRequirements.requirements;
  for (var i = 0; i < freReqs.length; i++) {
    final req = freReqs[i];
    final itemPath = req.path;
    final typedId = req.content.requirementId;
    final typedTitle = req.content.title;
    final genericId = doc.itemSectionId(itemPath) ?? '';
    final genericTitle = doc.headline(itemPath) ?? '';
    if (typedId != genericId) {
      stderr.writeln('TYPED ID-ROLE MISMATCH at $itemPath: '
          'typed="$typedId" generic="$genericId"');
      exit(2);
    }
    if (typedTitle != genericTitle) {
      stderr.writeln('TYPED TITLE-ROLE MISMATCH at $itemPath: '
          'typed="$typedTitle" generic="$genericTitle"');
      exit(2);
    }
    out.add('TR\t$itemPath\trequirementId\t${esc(typedId)}');
    out.add('TR\t$itemPath\ttitle\t${esc(typedTitle)}');
  }

  // --- Meta (FORMAT 2): the generated metadata tree read three ways. Every
  // path and every emitted field is model-derived, so the lines are byte-
  // identical across all nine languages even though the accessor *names* and
  // node *types* differ. The SBP root's static tree is the one the sample is
  // decoded against. ---
  final metaTree = d00SolutionBlueprintMetaTree;

  // Metadata reads: for a curated set of nodes resolved by path, emit the
  // node's kind plus its help / comment / doc-comment. help and comment are
  // empty across the current model, but reading them exercises the accessor;
  // docComment is populated, so the section proves the read path end-to-end.
  out.add('SECTION\tmeta');
  void metaNode(String path) {
    final n = metaTree.byPath(path);
    if (n == null) {
      stderr.writeln('META MISSING at $path');
      exit(3);
    }
    out.add('M\t$path\t${n.kind.name}\t${esc(n.sectionId ?? '')}\t'
        '${esc(n.contentHelp ?? '')}\t${esc(n.comment ?? '')}\t'
        '${esc(n.docComment ?? '')}\t${esc(n.headline ?? '')}');
  }

  metaNode('SBP');
  metaNode('SBP/documentControl');
  metaNode('SBP/documentControl/RVHST-REVS-LST');
  metaNode('SBP/introductionAndScope');
  metaNode('SBP/introductionAndScope/goals');
  metaNode('SBP/introductionAndScope/goals/content');
  metaNode('SBP/currentLandscape');
  metaNode('SBP/currentLandscape/CUOPME-OPER-LST');
  metaNode('SBP/requirements');
  metaNode('SBP/requirements/content');

  // --- Meta form fields (FORMAT 5, YRD6): the FRE list-element content form
  // read through the metadata tree — one MF line per field (declaration
  // order) with type/required/role/initial, plus one MT summary line naming
  // the form's title-role and id-role fields via the titleField/idField
  // accessors. All values are model-derived. ---
  out.add('SECTION\tmeta-form');
  const freListPath =
      'SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST';
  final freListNode = metaTree.byPath(freListPath);
  final freElement = freListNode?.elementNode;
  SomMetaNode? freContentNode;
  for (final child in freElement?.children ?? const <SomMetaNode>[]) {
    if (child.memberName == 'content') freContentNode = child;
  }
  final freForm = freContentNode?.form;
  if (freForm == null) {
    stderr.writeln('META FORM MISSING at $freListPath element content');
    exit(3);
  }
  // Element subtrees have no static document path; use an ASCII marker
  // segment so the log path stays ASCII (mirrored verbatim per language).
  const freFormPath = '$freListPath/#element/content';
  for (final f in freForm.fields) {
    out.add('MF\t$freFormPath\t${esc(f.name)}\t${esc(f.typeName)}\t'
        '${f.required ? 1 : 0}\t${esc(f.role ?? '')}\t${esc(f.initial ?? '')}');
  }
  out.add('MT\t$freFormPath\t${esc(freForm.titleField?.name ?? '')}\t'
      '${esc(freForm.idField?.name ?? '')}');

  // Dot-notation navigation: the typed nav accessors must resolve to exactly
  // the path byPath finds, and to the *same* node instance. The emitted line
  // is just the path — the accessor chain that produced it is language-local.
  out.add('SECTION\tmeta-nav');
  void metaNav(SomMetaRef ref, String expectedPath) {
    if (ref.path != expectedPath) {
      stderr.writeln('META NAV PATH at ${ref.path} expected $expectedPath');
      exit(3);
    }
    final byPath = metaTree.byPath(expectedPath);
    if (byPath == null || !identical(ref.meta, byPath)) {
      stderr.writeln('META NAV NODE mismatch at $expectedPath');
      exit(3);
    }
    out.add('N\t$expectedPath');
  }

  metaNav(d00SolutionBlueprint, 'SBP');
  metaNav(d00SolutionBlueprint.documentControl, 'SBP/documentControl');
  metaNav(d00SolutionBlueprint.introductionAndScope, 'SBP/introductionAndScope');
  metaNav(d00SolutionBlueprint.introductionAndScope.goals,
      'SBP/introductionAndScope/goals');
  metaNav(d00SolutionBlueprint.introductionAndScope.goals.content,
      'SBP/introductionAndScope/goals/content');
  metaNav(d00SolutionBlueprint.currentLandscape, 'SBP/currentLandscape');
  metaNav(d00SolutionBlueprint.requirements, 'SBP/requirements');
  metaNav(d00SolutionBlueprint.requirements.content, 'SBP/requirements/content');

  // ID-tree navigation: the hoisted-id accessors must agree — same path, same
  // node instance — with the dot-notation position, including list elements.
  out.add('SECTION\tmeta-id');
  void metaId(SomMetaRef idRef, SomMetaRef navRef) {
    if (idRef.path != navRef.path || !identical(idRef.meta, navRef.meta)) {
      stderr.writeln('META ID mismatch at ${idRef.path} vs ${navRef.path}');
      exit(3);
    }
    out.add('D\t${idRef.path}');
  }

  metaId(SBP, d00SolutionBlueprint);
  metaId(SBP.RVHST_REVS_LST,
      d00SolutionBlueprint.documentControl.revisionHistory);
  metaId(SBP.RVHST_REVS_LST.item(0),
      d00SolutionBlueprint.documentControl.revisionHistory.item(0));

  // DocSpecs validation: the shared markdown rendering of the sample validates
  // cleanly against the facade's generated Solution-Blueprint schema. root id,
  // warning count, and violation count are all model-derived and identical.
  out.add('SECTION\tdocspecs');
  final schema =
      DocSpecsSchema.fromYamlText(File(_defaultSchema).readAsStringSync());
  final sampleMd = File(_defaultSampleMd).readAsStringSync();
  final violations = DocSpecsValidator(schema).validateMarkdown(sampleMd);
  out.add('DS\troot\t${esc(schema.rootSectionId ?? '')}');
  out.add('DS\twarnings\t${schema.warnings.length}');
  out.add('DS\tviolations\t${violations.length}');
  for (final v in violations) {
    out.add('DV\t${v.rule.name}\t${esc(v.sectionId ?? '')}\t${v.line}');
  }

  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  // Join with LF and terminate with a single trailing LF — fixed regardless of
  // host platform so the bytes match on every machine.
  file.writeAsStringSync('${out.join('\n')}\n');
  stdout.writeln('wrote ${out.length} lines to $outputPath');
}
