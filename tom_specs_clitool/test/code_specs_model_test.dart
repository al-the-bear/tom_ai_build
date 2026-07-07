import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

// ---------------------------------------------------------------------------
// End-to-end against the real tom_code_specs package (OE-24).
//
// tom_code_specs carries the two phase-2 document models — CodeSpecs (Phase 4)
// and Implementation (Phase 6) — mirroring `SpecPhase.codeSpecs` /
// `SpecPhase.implementation` in tom_specs_editor. These tests prove the models
// parse through the same analyzer pipeline the editor JSON is built from, that
// their section structure is well-formed, and that they project cleanly to both
// the model JSON and a DocSpecs schema.
// ---------------------------------------------------------------------------

String? _annArg(List<AnnotationData> anns, String name, String key) {
  for (final a in anns) {
    if (a.name == name) return a.arguments[key]?.toString();
  }
  return null;
}

void main() {
  // tom_code_specs lives next to tom_specs_clitool in the same parent folder.
  final modelPath = p.normalize(
    p.join(Directory.current.path, '..', 'tom_code_specs'),
  );

  group('OE-24: tom_code_specs document models', () {
    late Map<String, ModelClass> classes;

    setUpAll(() async {
      final driver = createAnalysisDriver(modelPath);
      final reader = ModelReader(driver);
      await reader.analyzePackage(p.join(modelPath, 'lib'));
      classes = reader.classes;
    });

    test('exposes exactly two @Document roots: CodeSpecs and Implementation',
        () {
      final docRoots = {
        for (final e in classes.entries)
          if (e.value.annotations.any((a) => a.name == 'Document'))
            e.key: _annArg(e.value.annotations, 'Document', 'name'),
      };
      expect(docRoots.keys,
          containsAll(['CodeSpecsDocument', 'ImplementationDocument']));
      expect(docRoots.length, 2);
      expect(docRoots['CodeSpecsDocument'], 'CodeSpecs');
      expect(docRoots['ImplementationDocument'], 'Implementation');
    });

    test('roots carry the chosen non-colliding @SectionId prefixes', () {
      expect(_annArg(classes['CodeSpecsDocument']!.annotations, 'SectionId',
          'id'), 'CDS');
      expect(_annArg(classes['ImplementationDocument']!.annotations,
          'SectionId', 'id'), 'IMPL');
    });

    test('CodeSpecs has the SpecPhase structure: prose + patterned lists', () {
      final root = classes['CodeSpecsDocument']!;
      final byName = {for (final f in root.fields) f.name: f};

      // Prose sections carry a field-level @SectionId.
      expect(_annArg(byName['tagline']!.annotations, 'SectionId', 'id'),
          'CDS-TAG');
      expect(_annArg(byName['phase2Note']!.annotations, 'SectionId', 'id'),
          'CDS-PH2');

      // The four repeated sections are @SectionIdPattern lists.
      for (final entry in {
        'inputs': 'CDS-INP-xxx',
        'produces': 'CDS-PRD-xxx',
        'components': 'CDS-CMP-xxx',
        'exitCriteria': 'CDS-EXT-xxx',
      }.entries) {
        final f = byName[entry.key]!;
        expect(f.isList, isTrue, reason: '${entry.key} must be a list');
        expect(_annArg(f.annotations, 'SectionIdPattern', 'pattern'),
            entry.value);
      }
    });

    test('CodeSpecsComponent is a @Form with name/description/source fields',
        () {
      final comp = classes['CodeSpecsComponent']!;
      final content = comp.fields.firstWhere((f) => f.name == 'content');
      expect(content.formFields.map((f) => f.name),
          ['name', 'description', 'source']);
      expect(
          content.formFields.firstWhere((f) => f.name == 'name').required,
          isTrue);
    });

    test('Implementation mirrors the level-by-level structure', () {
      final root = classes['ImplementationDocument']!;
      final byName = {for (final f in root.fields) f.name: f};
      expect(byName['levels']!.isList, isTrue);
      expect(_annArg(byName['levels']!.annotations, 'SectionIdPattern',
          'pattern'), 'IMPL-LVL-xxx');
      final level = classes['ImplementationLevel']!;
      final content = level.fields.firstWhere((f) => f.name == 'content');
      expect(content.formFields.map((f) => f.name), ['name', 'description']);
    });

    test('structural quality: no duplicate ids, patterns, or uncovered lists',
        () {
      final result = validateStructuralInvariants(classes);
      // The model is intentionally standalone (not a PD projection), so the
      // PD-specific invariants (detail-count, pure-projection) do not apply.
      // The id/pattern/coverage invariants must hold.
      final structural = result.errors
          .where((e) =>
              e.contains('§8.6 @SectionId uniqueness') ||
              e.contains('§8.6 @SectionIdPattern uniqueness') ||
              e.contains('§8.6 @SectionIdPattern list-coverage') ||
              e.contains('§8.6 @SectionId per-class uniqueness') ||
              e.contains('§8.6 @SectionId/@SectionIdPattern pairing'))
          .toList();
      expect(structural, isEmpty, reason: structural.join('\n'));

      final coverage = result.warnings
          .where((w) => w.contains('§8.6 @SectionId coverage'))
          .toList();
      expect(coverage, isEmpty, reason: coverage.join('\n'));
    });

    test('model JSON export surfaces both documents as tree roots and the '
        'component form (the editor-facing path)', () {
      final json = ModelJsonExporter(classes).export();
      final roots = (json['roots'] as List).cast<Map>();
      final titles = roots.map((r) => r['title']).toList();
      expect(titles, containsAll(['CodeSpecs', 'Implementation']));

      // The editor renders forms from the JSON class graph: the component's
      // content field is a form carrying name/description/source.
      final comp = (json['classes'] as Map)['CodeSpecsComponent'] as Map;
      final content = (comp['fields'] as List)
          .cast<Map>()
          .firstWhere((f) => f['name'] == 'content');
      expect(content['kind'], 'form');
      expect((content['formFields'] as List).map((f) => (f as Map)['name']),
          ['name', 'description', 'source']);
    });

    test('DocSpecs schema generation yields a schema per document root', () {
      final schemas = DocSpecsSchemaGenerator(classes).generateAll();
      expect(schemas.length, 2);
      final cds =
          DocSpecsSchemaGenerator(classes).generateFor('CodeSpecsDocument');
      expect(
        cds.sectionTypes.keys,
        containsAll(['cds-tag', 'cds-inp', 'cds-cmp', 'cds-ext']),
      );
    });
  });
}
