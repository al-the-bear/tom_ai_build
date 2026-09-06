// TomSpecs sample — building tooling ON a specification.
//
// Run:  dart pub get && dart run
//
// For the reader who is not authoring specifications but writing programs that
// read them: an editor, a linter, a report, an importer, a migration. That
// reader needs four things, and this sample walks them in the order they are
// needed:
//
//   1. REFLECTION   — what the model CAN hold, read from the metadata tree
//   2. GENERIC      — what a document DOES hold, with no compile-time knowledge
//                     of its shape
//   3. SCHEMA       — the generated schema, where it comes from and what it is
//   4. VALIDATION   — the two runtime tiers, and the third that is not here
//   5. A TOOL       — a completeness report built on all four
//
// The individual APIs are already demonstrated one at a time in the facade's
// own examples, and this sample links them rather than restating them:
//
//   tom_som_dart_v0/example/b_generic_document.dart     generic read/write
//   tom_som_dart_v0/example/c_reflection_metadata.dart   the meta surface
//   tom_som_dart_v0/example/f_sample_hybrid_access.dart  the typed→path bridge
//
// The first two run from a hosted install. The third is worth READING for its
// header — it states the two safe ways to obtain a path better than step 2
// below does — but it does not run: it, and `d_`/`e_` beside it, load a
// document from `tom_som_conformance`, which is not published. See the README.
//
// What is here instead is how they compose, and the one distinction a tooling
// author has to get right before writing any of it — see the README, and step 4.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

Future<void> main() async {
  final model = await _loadModel();
  final schema = await _loadSchema();

  final doc = SpecDocument();
  _authorFixture(D00SolutionBlueprint(doc));

  _section(0, 'The document this run inspects');
  print('A Solution Blueprint with a handful of sections written and the');
  print('rest left blank — small enough that every number below can be');
  print('checked by reading `_authorFixture` in this file.');
  print('');
  print('  content leaves written : ${doc.contentPaths.length}');
  print('  form sections written  : ${doc.formPaths.length}');
  print('  lists with items       : ${doc.listPaths.length}');

  _reflection(model);
  _genericAccess(model, doc);
  _theSchema(schema);
  _validation(model, schema, doc);
  _theTool(model, schema, doc);
}

// ===========================================================================
// 1. Reflection — what the model CAN hold
// ===========================================================================

void _reflection(SpecModel model) {
  _section(1, 'Reflection — what the model CAN hold');
  print('`SpecModel` is the exported class graph; `SpecReflection` is the');
  print('value-free query surface over it. No document is involved here.');
  print('');

  print('THE TWO VERSION STAMPS. They answer different questions and a tool');
  print('that checks one for the other will accept a file it cannot read:');
  print('  modelVersion      = ${model.modelVersion}'
      '  — WHICH MODEL this snapshot describes');
  print('  metaSchemaVersion = ${model.metaSchemaVersion}'
      '  — the FILE FORMAT the snapshot itself is written in');
  print('  modelVersionLabel = ${model.modelVersionLabel}');
  print('  generatedAt       = ${model.generatedAt?.toIso8601String()}');
  print('');
  print('A tool reads `metaSchemaVersion` to decide whether it can parse the');
  print('file at all, and `modelVersion` to decide whether the documents it');
  print('holds are the ones this model describes. `modelVersionLabel` is a');
  print('build label for humans — never branch on it.');
  print('');

  // A snapshot is a photograph. `checkStamp` compares what the exporter
  // DECLARED against what survived to the reader, and ages the file out.
  // `now:` is passed rather than defaulted so this sample's output does not
  // change with the calendar.
  final stamp = model.checkStamp(now: DateTime.utc(2026, 9, 7));
  print('SNAPSHOT CHECK (`checkStamp`), against a fixed clock:');
  print('  age                 : ${stamp.age?.inDays} days'
      ' (aged: ${stamp.isAged})');
  print('  classes  declared/actual : '
      '${stamp.declaredClassCount}/${stamp.actualClassCount}'
      '  disagrees: ${stamp.classCountDisagrees}');
  print('  roots    declared/actual : '
      '${stamp.declaredRootCount}/${stamp.actualRootCount}'
      '  disagrees: ${stamp.rootCountDisagrees}');
  print('  Declared-vs-actual is not redundant: the declared value is what');
  print('  the exporter recorded, the actual value is what survived to the');
  print('  reader, and a truncated file is exactly where they part.');
  print('');

  final reflection = SpecReflection(model);
  print('SHAPE:');
  print('  document roots : ${reflection.roots.length}');
  print('  classes        : ${reflection.classes.length}');
  print('  container root : ${model.containerRoot}'
      ' — the one true tree root, which is not itself a document');
  print('');

  final root = reflection.rootForSegment('SBP')!;
  final fields = reflection.fieldsOf(root.type);
  print('FIELDS of ${root.type} (${fields.length} total, first 4):');
  for (final f in fields.take(4)) {
    print('  ${f.name.padRight(24)} kind=${f.kind.name.padRight(8)}'
        ' ${f.type ?? ''}');
  }
  print('');

  // A form's slots are on the field itself, not on a separate class — the
  // shape a tool must handle to render or fill one.
  final form = reflection
      .fieldsOf('DataEntityEntry')
      .firstWhere((f) => f.kind == SpecFieldKind.form);
  print('FORM SLOTS of DataEntityEntry.${form.name} '
      '(section id ${form.sectionId}):');
  for (final slot in form.formFields) {
    print('  ${slot.name.padRight(16)} ${slot.label}');
  }
  print('');

  print('ANNOTATIONS the meta carries — the model\'s own metadata, exported');
  print('into the snapshot and therefore visible in ALL NINE language');
  print('runtimes, not just Dart:');
  for (final a in reflection.annotationsOf(root.type)) {
    final args = a.arguments.keys.join(', ');
    print('  @${a.name}${args.isEmpty ? '' : '($args)'}');
  }
  print('  ${kRenderedAnnotations.length} annotation names have declared '
      'display semantics');
  print('  (`kRenderedAnnotations`), so two apps cannot disagree about what');
  print('  a marker means while each renders it in its own idiom.');
  print('');

  print('PATH RESOLUTION — a document path to the model node it lands on:');
  for (final path in [
    'SBP',
    'SBP/content',
    'SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST',
    'SBP/informationAndDataModel/nosuchthing',
  ]) {
    final r = reflection.resolve(path);
    print('  ${path.padRight(50)} '
        '${r == null ? '(unresolved)' : 'kind=${r.kind.name}'
            '  leaf=${r.isValueLeaf}'}');
  }
}

// ===========================================================================
// 2. Generic access — what a document DOES hold
// ===========================================================================

void _genericAccess(SpecModel model, SpecDocument doc) {
  _section(2, 'Generic access — what the document DOES hold');
  print('`SpecDocument` is a sparse, path-keyed store. A tool reads it');
  print('without knowing the document\'s shape, and asks the model what each');
  print('path means. That pairing is the whole of generic access.');
  print('');

  final reflection = SpecReflection(model);
  print('EVERY written content leaf, resolved against the model:');
  for (final path in doc.contentPaths.toList()..sort()) {
    final r = reflection.resolve(path);
    final value = doc.content(path) ?? '';
    print('  ${path.padRight(52)} ${r?.kind.name ?? '?'}');
    print('      ${_clip(value, 66)}');
  }
  print('');

  print('EVERY written form section, slot by slot:');
  for (final path in doc.formPaths.toList()..sort()) {
    print('  $path');
    for (final slot in doc.formFieldNames(path).toList()..sort()) {
      print('      ${slot.padRight(16)} '
          '${_clip(doc.formField(path, slot) ?? '', 52)}');
    }
  }
  print('');

  print('EVERY list, with its items\' section ids:');
  for (final path in doc.listPaths.toList()..sort()) {
    print('  ${path.padRight(52)} ${doc.listItemCount(path)} item(s)');
    for (final id in doc.listItemSectionIds(path)) {
      print('      $id');
    }
  }
  print('');

  print('WHERE PATHS COME FROM. A tool must never hard-code a path literal —');
  print('a literal is undiscoverable and rots silently when the model moves.');
  print('Two safe sources, both compiler-checked '
      '(see example/f_sample_hybrid_access.dart):');
  print('');
  print('  1. the generated metadata refs —');
  print('     d00SolutionBlueprint.informationAndDataModel.dataModel.path');
  print('       = ${d00SolutionBlueprint.informationAndDataModel.dataModel.path}');
  print('  2. the id-keyed metadata tree, for a path known only at runtime —');
  final node = d00SolutionBlueprintMetaTree.byId('DAENT-ENTI-LST');
  print('     d00SolutionBlueprintMetaTree.byId(\'DAENT-ENTI-LST\')');
  print('       = ${node?.path}');
  print('');
  print('  The tree also goes the other way: byPath gives the node, and with');
  print('  it the class, kind and children a generic renderer needs.');
  final byPath = d00SolutionBlueprintMetaTree
      .byPath('SBP/informationAndDataModel/dataModel');
  print('     byPath(\'SBP/informationAndDataModel/dataModel\')');
  print('       class=${byPath?.className} kind=${byPath?.kind.name} '
      'children=${byPath?.children.length}');
}

// ===========================================================================
// 3. The generated schema
// ===========================================================================

void _theSchema(DocSpecsSchema schema) {
  _section(3, 'The generated schema');
  print('Each of the 14 document roots has a schema GENERATED from the model');
  print('and SHIPPED as data inside the facade package, under');
  print('`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool');
  print('loads one; it never writes one, and never derives one itself.');
  print('');
  print('IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*');
  print('document — headings, their ids, their formats, the form fields a');
  print('section carries and which of them are required. A tool reaching for');
  print('a JSON-Schema validator will not find one, because the artifact the');
  print('schema governs is not JSON.');
  print('');
  print('  root section id : ${schema.rootSectionId}');
  print('  section types   : ${schema.sectionTypes.length}');
  print('');
  print('  That count is large because a Solution Blueprint SEEDS the twelve');
  print('  Phase-3 documents: its own section classes ARE those documents\'');
  print('  types, so its schema covers every section id they define. Step 5');
  print('  meets the same fact from the other side.');
  print('');
  print('  A section type resolves by ID PREFIX, which is how a generated id');
  print('  like `DAENT-ENTI-7` finds its type without the schema listing');
  print('  every instance:');
  for (final id in ['DAENT-IDEN', 'DAENT-ENTI-7', 'NOSUCH-1']) {
    final t = schema.resolveSectionType(id);
    print('    ${id.padRight(16)} -> '
        '${t == null ? '(no type — a tool treats this as unknownSection)' : t.prefix}');
  }
}

// ===========================================================================
// 4. Validation — the tiers
// ===========================================================================

void _validation(SpecModel model, DocSpecsSchema schema, SpecDocument doc) {
  _section(4, 'Validation — three tiers, two of them here');
  print('THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one');
  print('tier and calls another gets nothing useful — not an error, just an');
  print('empty list that reads like a pass.');
  print('');
  print('  STATIC tier   — checks the MODEL\'S OWN ANNOTATIONS: field-type');
  print('                  rules, @ContentType compatibility, cycles, the');
  print('                  §10.2 structural invariants. Runs ONCE at');
  print('                  generation time, in');
  print('                  `tom_specs_clitool/lib/src/validator.dart`, and is');
  print('                  deliberately NOT part of the nine-language runtime');
  print('                  surface. Not reachable from this sample, and that');
  print('                  is the point: by the time a document exists, this');
  print('                  tier has already run.');
  print('  INSTANCE tier — checks A DOCUMENT\'S VALUES against the model:');
  print('                  `validateDocument` (SOM §9). In every runtime.');
  print('  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated');
  print('                  schema: `DocSpecsValidator` (SOM §14).');
  print('');
  print('The two runtime tiers ask disjoint questions and neither implies the');
  print('other: `validateDocument` is not a completeness check (an absent');
  print('required field holds no value, so there is nothing invalid to');
  print('report), and the schema validator does not follow a reference it');
  print('sees filled. A tool that wants "is this document good?" runs BOTH.');
  print('');

  final instance = validateDocument(model, doc);
  final document = DocSpecsValidator(schema)
      .validateMarkdown(doc.toMarkdown(model, rootType: _kRoot));
  print('THE FIXTURE, both tiers:');
  print('  instance tier : ${instance.length} error(s)');
  print('  document tier : ${document.length} violation(s)');
  for (final v in document.take(4)) {
    print('    line ${v.line}: ${v.rule.name} [${v.sectionId}] '
        '${_clip(v.message, 54)}');
  }
  if (document.length > 4) {
    print('    … and ${document.length - 4} more');
  }
  print('');

  // A document broken on purpose, to show the instance tier firing where the
  // document tier cannot see anything wrong.
  final broken = SpecDocument();
  _authorFixture(D00SolutionBlueprint(broken));
  broken.setContent('SBP/informationAndDataModel/nosuchsection/content', 'x');
  broken.setFormField(
      'SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN',
      'notAField',
      'x');
  final brokenInstance = validateDocument(model, broken);
  print('A DELIBERATELY BROKEN COPY — one path the model does not have, one');
  print('form slot the form does not declare:');
  for (final e in brokenInstance) {
    print('  ${e.code.name.padRight(20)} ${_clip(e.path, 50)}');
  }
  print('');

  print('THE CLOSED VERDICT SETS. Both are enums, so a tool switches over');
  print('them exhaustively rather than matching on message text:');
  print('  SpecValidationCode  (${SpecValidationCode.values.length}): '
      '${SpecValidationCode.values.map((c) => c.name).join(', ')}');
  print('  DocSpecsViolationRule (${DocSpecsViolationRule.values.length}):');
  for (final chunk in _chunk(
      DocSpecsViolationRule.values.map((r) => r.name).toList(), 4)) {
    print('    ${chunk.join(', ')}');
  }
}

// ===========================================================================
// 5. The tool
// ===========================================================================

void _theTool(SpecModel model, DocSpecsSchema schema, SpecDocument doc) {
  _section(5, 'A tool: the completeness report');
  print('Built on all four surfaces above, and it reports something NEITHER');
  print('validator can. The schema names what is REQUIRED and missing; an');
  print('optional section left blank is perfectly valid and no validator will');
  print('ever mention it. But "which parts of this specification has nobody');
  print('written yet?" is the question a specification author actually has,');
  print('and answering it means walking the model and asking the document.');
  print('');

  final report = specificationCoverage(model, doc, rootSegment: _kRootSegment);
  print('  ${'SECTION'.padRight(_kTitleWidth)} WRITTEN / OFFERED');
  for (final row in report.rows) {
    final bar = row.offered == 0
        ? ''
        : '${(100 * row.written / row.offered).round()}%'.padLeft(6);
    print('  ${row.title.padRight(_kTitleWidth)} '
        '${row.written.toString().padLeft(5)} / '
        '${row.offered.toString().padLeft(5)}$bar');
  }
  print('  ${'-' * _kTitleWidth} ${'-' * 19}');
  print('  ${'TOTAL'.padRight(_kTitleWidth)} '
      '${report.written.toString().padLeft(5)} / '
      '${report.offered.toString().padLeft(5)}'
      '${'${(100 * report.written / report.offered).round()}%'.padLeft(6)}');
  print('');
  print('  SBP.11 offers 2529 positions because a Solution Blueprint SEEDS');
  print('  the twelve Phase-3 documents: its section classes ARE those');
  print('  documents\' types, so the model surface under an SBP root includes');
  print('  everything it seeds. A tool that reports "0 %" against a number');
  print('  like that should say what the denominator is — which is why the');
  print('  report is per section and not one headline figure.');
  print('');
  print('  Required-and-missing, from the schema tier, for contrast:');
  final required = DocSpecsValidator(schema)
      .validateMarkdown(doc.toMarkdown(model, rootType: _kRoot))
      .where((v) => v.rule == DocSpecsViolationRule.missingRequiredField)
      .length;
  print('    $required missing required field(s) — the only gaps a validator');
  print('    will name, out of ${report.offered - report.written} unwritten '
      'positions.');
  print('');
  print('That gap between the two numbers is the tool\'s reason to exist.');
}

/// One row of a [SpecificationCoverage] — a top-level section of the document.
class CoverageRow {
  /// The section's human-readable title, from the model.
  final String title;

  /// Content positions the model offers anywhere beneath this section.
  final int offered;

  /// How many of them the document has written.
  final int written;

  /// Creates a row.
  const CoverageRow(this.title, this.offered, this.written);
}

/// What a document has written, against what its model offers.
class SpecificationCoverage {
  /// One row per top-level section, in model order.
  final List<CoverageRow> rows;

  /// Creates a report.
  const SpecificationCoverage(this.rows);

  /// Content positions offered across every row.
  int get offered => rows.fold(0, (a, r) => a + r.offered);

  /// Content positions written across every row.
  int get written => rows.fold(0, (a, r) => a + r.written);
}

/// Walks [model] from [rootSegment] and counts, per top-level section, how many
/// content positions the model offers and how many [doc] has written.
///
/// **Lists count as one position, not as their items.** A list the author left
/// empty offers exactly one thing to write — the first item — and a list with
/// forty items has not made the document forty times more complete. Counting
/// items would make a report that rewards padding, which is the opposite of
/// what a completeness report is for.
///
/// The walk is entirely generic: it knows no class or field name, so it works
/// unchanged against any of the fourteen document roots and survives a model
/// change that adds sections.
SpecificationCoverage specificationCoverage(
  SpecModel model,
  SpecDocument doc, {
  required String rootSegment,
}) {
  final reflection = SpecReflection(model);
  final root = reflection.rootForSegment(rootSegment)!;
  final rows = <CoverageRow>[];

  for (final field in reflection.fieldsOf(root.type)) {
    if (field.kind == SpecFieldKind.content) continue; // the root's own body
    final path = '$rootSegment/${reflection.fieldSegment(field)}';
    final counter = _Counter(doc);
    counter.walk(reflection, field, path, <String>{root.type});
    if (counter.offered == 0) continue;
    rows.add(CoverageRow(
      _rowTitle(field),
      counter.offered,
      counter.written,
    ));
  }
  return SpecificationCoverage(rows);
}

/// A section's title for the report — its model doc comment's first sentence,
/// falling back to the field name where the model carries no doc.
///
/// The `Seeds → TOM` tails are dropped: they say where a section's content goes
/// next, which is a fact about the process and not about this document's
/// completeness.
String _rowTitle(SpecField field) {
  var text = field.doc?.split('\n').first.trim() ?? '';
  final stop = text.indexOf('. ');
  if (stop >= 0) text = text.substring(0, stop);
  while (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  text = text.trim();
  if (text.isEmpty) return field.name;
  return text.length <= _kTitleWidth
      ? text
      : '${text.substring(0, _kTitleWidth - 1)}…';
}

/// The report's title column width. Titles are clipped to it rather than
/// wrapped: a completeness report is scanned down its numbers, and a wrapped
/// title puts a row's two halves on different lines.
const int _kTitleWidth = 38;

/// Accumulates offered/written positions over one subtree.
class _Counter {
  _Counter(this.doc);

  /// The document being measured.
  final SpecDocument doc;

  /// Content positions the model offers in the subtree walked so far.
  int offered = 0;

  /// How many of them are written.
  int written = 0;

  /// Adds every content position under [field] at [path].
  ///
  /// [seen] carries the class names already on this branch; the model is a
  /// graph rather than a tree, and a section type that can contain itself would
  /// otherwise recurse forever.
  void walk(
    SpecReflection reflection,
    SpecField field,
    String path,
    Set<String> seen,
  ) {
    switch (field.kind) {
      case SpecFieldKind.content:
      case SpecFieldKind.scalar:
      case SpecFieldKind.enumValue:
        offered++;
        if (doc.hasContent(path)) written++;
      case SpecFieldKind.form:
        for (final slot in field.formFields) {
          offered++;
          if ((doc.formField(path, slot.name) ?? '').isNotEmpty) written++;
        }
      case SpecFieldKind.list:
        offered++;
        if (doc.listItemCount(path) > 0) written++;
      case SpecFieldKind.section:
      case SpecFieldKind.complex:
        final type = field.type;
        if (type == null || seen.contains(type)) return;
        for (final child in reflection.fieldsOf(type)) {
          walk(reflection, child, '$path/${reflection.fieldSegment(child)}',
              {...seen, type});
        }
    }
  }
}

// ===========================================================================
// The fixture
// ===========================================================================

/// The document root this sample inspects.
const String _kRoot = 'D00SolutionBlueprint';

/// That root's addressable segment — the first element of every path in it.
const String _kRootSegment = 'SBP';

/// The creation date section-id generation is pinned to.
///
/// `SomList.add` derives an item's id from the current date, so an unpinned run
/// would emit different ids every day and `expected_output.txt` would record
/// the day it was taken rather than the pipeline.
final DateTime _kAuthoredOn = DateTime.utc(2026, 1, 1);

/// Writes the small, deliberately incomplete document this run inspects.
///
/// A sample authors its own specification: the shared documents live in the
/// unpublished `tom_som_conformance`, and a sample takes hosted dependencies
/// only (`tom_specs_documentation_standard.md` §7.1). Incomplete on purpose —
/// step 5's whole subject is the sections nobody has written.
void _authorFixture(D00SolutionBlueprint sbp) {
  sbp.content = 'A platform that unifies our fragmented order systems.';
  sbp.introductionAndScope.content =
      'Replace three regional order desks with one intake service.';
  sbp.currentLandscape.content =
      'Three legacy systems with no shared customer record.';

  final metrics = sbp.currentLandscape.operationalMetrics;
  metrics.addContent('Average order turnaround: 4.2 days.',
      date: _kAuthoredOn);
  metrics.addContent('Manual reconciliation: ~12 hours per week.',
      date: _kAuthoredOn);

  final customer =
      sbp.informationAndDataModel.dataModel.entities.add(date: _kAuthoredOn);
  customer.$headline = 'Customer';
  customer.identity
    ..entityName = 'Customer'
    ..tableName = 'customers'
    ..description = 'A party that places orders.';
  // `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
  // REQUIRED — so the schema tier has one real violation to report in step 4
  // and step 5 has a real number to contrast its own against. Writing `category` is
  // what makes the gap visible at all: clearing the section's only field would
  // remove the section, and a schema never checks a section that is not there.
  customer.classification.category = 'MasterData';
}

// ===========================================================================
// Loading, and small helpers
// ===========================================================================

/// Loads the exported class graph shipped in `tom_som_dart_v0`.
///
/// The meta ships as **data**, not as Dart, so it is reached through the
/// package URI. `Platform.script.resolve` — which the facade's own
/// `c_reflection_metadata.dart` uses — works only for a script running inside
/// that package, and silently resolves to nothing from a consuming project.
Future<SpecModel> _loadModel() async {
  final root = await _packageRoot('tom_som_dart_v0');
  return SpecModel.fromJson(
    jsonDecode(File.fromUri(root.resolve('meta/spec_model.meta.json'))
        .readAsStringSync()) as Map<String, dynamic>,
  );
}

/// Loads the generated DocSpecs schema for the Solution Blueprint root.
Future<DocSpecsSchema> _loadSchema() async {
  final root = await _packageRoot('tom_som_dart_v0');
  return DocSpecsSchema.fromYamlText(
    File.fromUri(root.resolve('schemas/solution-blueprint/'
            'solution-blueprint.1.0.docspecs-schema.yaml'))
        .readAsStringSync(),
  );
}

/// The root directory of [package], wherever pub put it.
Future<Uri> _packageRoot(String package) async {
  final lib = await Isolate.resolvePackageUri(
      Uri.parse('package:$package/$package.dart'));
  if (lib == null) {
    throw StateError('cannot resolve package:$package — run dart pub get');
  }
  return lib.resolve('../');
}

void _section(int n, String title) {
  print('');
  print('=' * 74);
  print('$n. $title');
  print('=' * 74);
}

String _clip(String s, int width) {
  final flat = s.replaceAll('\n', ' ');
  return flat.length <= width ? flat : '${flat.substring(0, width - 1)}…';
}

Iterable<List<T>> _chunk<T>(List<T> items, int size) sync* {
  for (var i = 0; i < items.length; i += size) {
    yield items.sublist(i, i + size > items.length ? items.length : i + size);
  }
}
