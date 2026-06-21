import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

// ---------------------------------------------------------------------------
// Synthetic-model helpers (mirroring tom_specs_clitool_test.dart)
// ---------------------------------------------------------------------------

AnnotationData _a(String name, [Map<String, Object?> args = const {}]) =>
    AnnotationData(name, args);

ModelField _content(String name, String sectionId, {String? help}) => ModelField(
      name: name,
      typeName: 'String',
      annotations: [
        _a('SectionId', {'id': sectionId}),
        if (help != null) _a('ContentHelp', {'guidance': help}),
      ],
    );

/// A small but representative model: one @Document root with a prose section, a
/// second prose section, a @Form section, and a patterned list of complex rows.
Map<String, ModelClass> _demoModel() {
  final root = ModelClass(
    name: 'DemoDoc',
    annotations: [
      _a('Document', {'name': 'Demo Doc'}),
      _a('SectionId', {'id': 'D00'}),
    ],
    fields: [
      _content('overview', 'D00-OVR', help: 'What the system does and why.'),
      _content('details', 'D00-DET'),
      ModelField(
        name: 'header',
        typeName: 'Header',
        annotations: [_a('SectionId', {'id': 'D00-HDR'})],
        formFields: [
          FormFieldInfo(name: 'title', typeName: 'String', required: true),
          FormFieldInfo(name: 'owner', typeName: 'String'),
        ],
      ),
      ModelField(
        name: 'items',
        typeName: 'List<Item>',
        isList: true,
        listElementTypeName: 'Item',
        listElementIsComplex: true,
        annotations: [
          _a('SectionIdPattern', {'pattern': 'D00-ITM'}),
          _a('Min', {'count': 1}),
          _a('Max', {'count': 4}),
        ],
      ),
    ],
  );
  final item = ModelClass(
    name: 'Item',
    annotations: [_a('SectionId', {'id': 'D00-ITM-ROW'})],
    fields: [_content('label', 'D00-ITM-ROW-LBL')],
  );
  return {'DemoDoc': root, 'Item': item};
}

/// Writes [schema] as YAML to a temp tree and loads it back through the real
/// DocSpecs loader — proving the emitted file is well-formed and its prefixes
/// satisfy the DocSpecs grammar (`^[a-zA-Z0-9_]+$`).
DocSpecSchema _writeAndReload(Directory dir, DocSpecSchema schema) {
  final fileName = DocSpecsSchemaGenerator.fileNameFor(schema);
  final file = File(p.join(dir.path, schema.id, fileName))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(DocSpecsSchemaGenerator.toYamlString(schema));
  return SchemaLoader.loadSync(file.path);
}

void main() {
  group('DocSpecsSchemaGenerator — synthetic model', () {
    late Map<String, ModelClass> classes;
    late DocSpecsSchemaGenerator gen;
    late Directory dir;

    setUp(() {
      classes = _demoModel();
      gen = DocSpecsSchemaGenerator(classes);
      dir = Directory.systemTemp.createTempSync('specs_schema_');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('maps @SectionId/@SectionIdPattern to section-types with legal '
        'prefixes', () {
      final schema = gen.generateFor('DemoDoc');
      // Root id (D00) is the document, not a section-type.
      expect(schema.sectionTypes.keys, isNot(contains('D00')));
      expect(
        schema.sectionTypes.keys,
        containsAll(<String>['D00-OVR', 'D00-DET', 'D00-HDR', 'D00-ITM',
            'D00-ITM-ROW', 'D00-ITM-ROW-LBL']),
      );
      // Dashes collapse to underscores so prefixes are DocSpecs-legal.
      expect(schema.sectionTypes['D00-OVR']!.prefix, 'd00_ovr');
      expect(schema.sectionTypes['D00-ITM-ROW']!.prefix, 'd00_itm_row');
    });

    test('prose sections are text-required, carry no format, and cap at one; '
        'list elements take their @Min/@Max cardinality', () {
      final schema = gen.generateFor('DemoDoc');
      final ovr = schema.sectionTypes['D00-OVR']!;
      expect(ovr.textRequired, isTrue);
      expect(ovr.format, isNull);
      expect(ovr.maxCountInDocument, 1);
      // A single field has no document-level minimum.
      expect(ovr.minCountInDocument, isNull);
      expect(ovr.description, 'What the system does and why.');
      // The patterned list element type maps @Min(1)/@Max(4) onto the
      // document-level min/max-count-in-document.
      final itm = schema.sectionTypes['D00-ITM']!;
      expect(itm.minCountInDocument, 1);
      expect(itm.maxCountInDocument, 4);
    });

    test('a patterned list with no @Min/@Max stays uncapped', () {
      // Re-build the model without cardinality annotations on the list.
      final bare = _demoModel();
      final items = bare['DemoDoc']!.fields
          .firstWhere((f) => f.name == 'items');
      items.annotations.removeWhere((a) => a.name == 'Min' || a.name == 'Max');
      final schema = DocSpecsSchemaGenerator(bare).generateFor('DemoDoc');
      final itm = schema.sectionTypes['D00-ITM']!;
      expect(itm.minCountInDocument, isNull);
      expect(itm.maxCountInDocument, isNull);
    });

    test('@Form fields become a form-type and the section format', () {
      final schema = gen.generateFor('DemoDoc');
      expect(schema.sectionTypes['D00-HDR']!.format, 'd00_hdr-form');
      final form = schema.formTypes!['d00_hdr-form']!;
      expect(form.fields.map((f) => f.fieldname), ['title', 'owner']);
      expect(form.fields.firstWhere((f) => f.fieldname == 'title').required,
          isTrue);
    });

    test('document slots reference the field section-types and are optional',
        () {
      final schema = gen.generateFor('DemoDoc');
      expect(schema.document.sections['overview']!.sectionType, 'D00-OVR');
      expect(schema.document.sections['items']!.sectionType, 'D00-ITM');
      expect(
        schema.document.sections.values.every((s) => s.optional == true),
        isTrue,
      );
    });

    test('section-types are ordered by descending prefix length (specific '
        'first)', () {
      final schema = gen.generateFor('DemoDoc');
      final prefixLens = schema.sectionTypes.values
          .map((s) => s.prefix?.length ?? 0)
          .toList();
      final sorted = [...prefixLens]..sort((a, b) => b.compareTo(a));
      expect(prefixLens, sorted);
    });

    test('the emitted YAML reloads through the DocSpecs loader', () {
      final schema = gen.generateFor('DemoDoc');
      final reloaded = _writeAndReload(dir, schema);
      expect(reloaded.fullId, 'demo-doc/1.0');
      expect(reloaded.sectionTypes.length, schema.sectionTypes.length);
      expect(reloaded.formTypes?.length, 1);
    });

    test('DONE: the reloaded schema validates a known-good export', () {
      final schema = gen.generateFor('DemoDoc');
      final reloaded = _writeAndReload(dir, schema);

      // A known-good export: prose sections whose IDs use the generated
      // prefixes, in document order. The items list carries @Min(1), so at
      // least one d00_itm section must be present to satisfy
      // min-count-in-document.
      final docPath = p.join(dir.path, 'known_good.md');
      File(docPath).writeAsStringSync('''
<!-- docspec: ${reloaded.fullId} -->

## [d00_ovr-001] Overview

The system streamlines onboarding for new tenants.

## [d00_det-001] Details

Detailed behaviour, edge cases, and error handling are described here.

## [d00_itm-001] First item
''');

      final factory = DocSpecsFactory(schema: reloaded);
      final doc = DocScanner.scanDocumentSync(
        filepath: docPath,
        factory: factory,
      );
      final errors = DocSpecsValidator(schema: reloaded).validate(doc);
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    test('S2: schema version counts up with the model stamp', () {
      expect(gen.generateFor('DemoDoc', modelVersion: 1).version, '1.0');
      expect(gen.generateFor('DemoDoc', modelVersion: 2).version, '2.0');
      expect(gen.generateFor('DemoDoc', modelVersion: 7).version, '7.0');
    });
  });

  // -------------------------------------------------------------------------
  // End-to-end against the real tom_specs_model (S1: 13 schemas).
  // -------------------------------------------------------------------------

  group('DocSpecsSchemaGenerator — real tom_specs_model', () {
    final modelPath = p.normalize(
      p.join(Directory.current.path, '..', 'tom_specs_model'),
    );
    late Map<String, ModelClass> classes;
    late Directory dir;

    setUpAll(() async {
      final driver = createAnalysisDriver(modelPath);
      final reader = ModelReader(driver);
      await reader.analyzePackage(p.join(modelPath, 'lib'));
      classes = reader.classes;
    });
    setUp(() => dir = Directory.systemTemp.createTempSync('specs_schema_e2e_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('S1: generates exactly 13 schemas (1 global PD + 12 projections)', () {
      final schemas = DocSpecsSchemaGenerator(classes).generateAll();
      expect(schemas.length, 13);
      expect(schemas.keys, contains('project-definition'));
    });

    test('every generated schema round-trips through the DocSpecs loader', () {
      final schemas = DocSpecsSchemaGenerator(classes).generateAll();
      for (final schema in schemas.values) {
        final reloaded = _writeAndReload(dir, schema);
        expect(reloaded.sectionTypes, isNotEmpty,
            reason: '${schema.id} has no section-types');
        expect(reloaded.version, '1.0');
      }
    });
  });
}
