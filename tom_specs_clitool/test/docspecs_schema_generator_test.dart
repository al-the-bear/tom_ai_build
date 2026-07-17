import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show somModelVersionString;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

// ---------------------------------------------------------------------------
// Synthetic-model helpers (mirroring tom_specs_clitool_test.dart)
// ---------------------------------------------------------------------------

AnnotationData _a(String name, [Map<String, Object?> args = const {}]) =>
    AnnotationData(name, args);

/// A DR1 §5-exercising model: a @Document root with a required prose section
/// (@Min(1)), an optional prose section with text-length bounds, a class-based
/// @Form section (with a @PatternCheck member), a patterned list of complex
/// rows, a container with a nested content child, and an @Unused section.
Map<String, ModelClass> _demoModel() {
  final root = ModelClass(
    name: 'DemoDoc',
    annotations: [
      _a('Document', {'name': 'Demo Doc'}),
      _a('SectionId', {'id': 'D00'}),
    ],
    fields: [
      ModelField(
        name: 'overview',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'D00-OVR'}),
          _a('ContentHelp', {'guidance': 'What the system does and why.'}),
          _a('Min', {'count': 1}),
        ],
      ),
      ModelField(
        name: 'details',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'D00-DET'}),
          _a('MinLength', {'length': 10}),
          _a('MaxLength', {'length': 500}),
        ],
      ),
      ModelField(
        name: 'header',
        typeName: 'Header',
        annotations: [_a('SectionId', {'id': 'D00-HDR'})],
      ),
      ModelField(
        name: 'items',
        typeName: 'List<Item>',
        isList: true,
        listElementTypeName: 'Item',
        listElementIsComplex: true,
        annotations: [
          _a('SectionIdPattern', {'pattern': 'D00-ITM-xxx'}),
          _a('Min', {'count': 1}),
          _a('Max', {'count': 4}),
        ],
      ),
      ModelField(
        name: 'notes',
        typeName: 'Notes',
        annotations: [],
      ),
      ModelField(
        name: 'legacy',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'D00-OLD'}),
          _a('Unused'),
        ],
      ),
    ],
  );
  final header = ModelClass(
    name: 'Header',
    annotations: [_a('Form')],
    formFields: [
      FormFieldInfo(
          name: 'title', typeName: 'String', required: true,
          hint: 'e.g. My System'),
      FormFieldInfo(name: 'approvedBy', typeName: 'String'),
    ],
    fields: [
      ModelField(name: 'title', typeName: 'String?'),
      ModelField(
        name: 'approvedBy',
        typeName: 'String?',
        annotations: [
          _a('PatternCheck',
              {'pattern': r'^[A-Z][a-z]+$', 'errorMessage': 'Name-cased'}),
        ],
      ),
    ],
  );
  final item = ModelClass(
    name: 'Item',
    annotations: [],
    fields: [
      ModelField(
        name: 'label',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'ITMR-LBL'}),
          _a('TextRequired'),
        ],
      ),
    ],
  );
  final notes = ModelClass(
    name: 'Notes',
    annotations: [
      _a('SectionId', {'id': 'D00-NOTE'}),
      _a('ValidationPrompt', {'prompt': 'Check the notes are actionable.'}),
    ],
    fields: [
      ModelField(
        name: 'remark',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'NOTE-RMK'}),
        ],
        docComment: 'A single remark line.',
      ),
    ],
  );
  return {
    'DemoDoc': root,
    'Header': header,
    'Item': item,
    'Notes': notes,
  };
}

/// Writes [schema] as YAML to a temp tree and loads it back through the real
/// DocSpecs loader — proving the emitted file is well-formed, its prefixes
/// satisfy the DocSpecs grammar (`^[a-zA-Z0-9_]+$`), and every construct the
/// generator emits (subsection-types, pattern checks, forms, custom tags)
/// parses (DR1 §5 rule 7 — DR3's acceptance criterion).
DocSpecSchema _writeAndReload(Directory dir, DocSpecSchema schema) {
  final fileName = DocSpecsSchemaGenerator.fileNameFor(schema);
  final file = File(p.join(dir.path, schema.id, fileName))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(DocSpecsSchemaGenerator.toYamlString(schema));
  return SchemaLoader.loadSync(file.path);
}

void main() {
  group('DocSpecsSchemaGenerator — synthetic model (DR1 §5)', () {
    late Map<String, ModelClass> classes;
    late DocSpecsSchemaGenerator gen;
    late Directory dir;

    setUp(() {
      classes = _demoModel();
      gen = DocSpecsSchemaGenerator(classes);
      dir = Directory.systemTemp.createTempSync('specs_schema_');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('§5.2: section-types are named by lower-cased section id with the '
        'exact id (dashes → underscores) as prefix', () {
      final schema = gen.generateFor('DemoDoc');
      // Root id (D00) is the document, not a section-type.
      expect(schema.sectionTypes.keys, isNot(contains('d00')));
      expect(
        schema.sectionTypes.keys,
        containsAll(<String>[
          'd00-ovr', 'd00-det', 'd00-hdr', 'd00-itm', 'd00-note',
          'itmr-lbl', 'note-rmk',
        ]),
      );
      // The exact TomSpecs id survives modulo the parser's prefix grammar
      // (`^[a-zA-Z0-9_]+$` forbids dashes): case preserved, `-` → `_`.
      expect(schema.sectionTypes['d00-ovr']!.prefix, 'D00_OVR');
      // List-element types use the pattern stem, trailing dash included.
      expect(schema.sectionTypes['d00-itm']!.prefix, 'D00_ITM_');
    });

    test('§5.2: subsection-types carry nearest section-bearing children with '
        'min/max cardinality', () {
      final schema = gen.generateFor('DemoDoc');
      // The list element's child content section is its subsection.
      final itm = schema.sectionTypes['d00-itm']!;
      expect(itm.subsectionTypes!.keys, ['itmr-lbl']);
      expect(itm.subsectionTypes!['itmr-lbl']!.maxCount, 1);
      // The container section carries its nested content child.
      final note = schema.sectionTypes['d00-note']!;
      expect(note.subsectionTypes!.keys, ['note-rmk']);
      // Leaf content sections have no subsection-types at all.
      expect(schema.sectionTypes['d00-ovr']!.subsectionTypes, isNull);
    });

    test('§5.2: list-element pattern-check-id compiles the exact '
        '@SectionIdPattern with xxx → .+ (YRD3 stem check)', () {
      final schema = gen.generateFor('DemoDoc');
      final check = schema.sectionTypes['d00-itm']!.patternCheckId;
      expect(check, isNotNull);
      expect(check!.pattern, r'^D00-ITM-.+$');
      expect(RegExp(check.pattern).hasMatch('D00-ITM-001'), isTrue);
      // YRD3: stored (AA1 / override) ids are surfaced in md, so the schema
      // checks only the stem — non-numeric suffixes are valid.
      expect(RegExp(check.pattern).hasMatch('D00-ITM-GN1'), isTrue);
      expect(RegExp(check.pattern).hasMatch('D00-ITM-'), isFalse);
      // Single (non-pattern) sections carry no id pattern-check.
      expect(schema.sectionTypes['d00-ovr']!.patternCheckId, isNull);
      expect(schema.sectionTypes['d00-hdr']!.patternCheckId, isNull);
    });

    test('§5.2: text-required from @TextRequired or @Min(1) on content; '
        'min/max-text-length from @MinLength/@MaxLength', () {
      final schema = gen.generateFor('DemoDoc');
      // @Min(1) on the overview content member → text-required.
      expect(schema.sectionTypes['d00-ovr']!.textRequired, isTrue);
      // Explicit @TextRequired on the item label.
      expect(schema.sectionTypes['itmr-lbl']!.textRequired, isTrue);
      // Neither applies to the plain optional prose section.
      expect(schema.sectionTypes['d00-det']!.textRequired, isNull);
      expect(schema.sectionTypes['d00-det']!.minTextLength, 10);
      expect(schema.sectionTypes['d00-det']!.maxTextLength, 500);
    });

    test('§5.2: description from @ContentHelp first, doc comment fallback; '
        'validation-prompt from @ValidationPrompt', () {
      final schema = gen.generateFor('DemoDoc');
      expect(schema.sectionTypes['d00-ovr']!.description,
          'What the system does and why.');
      expect(schema.sectionTypes['note-rmk']!.description,
          'A single remark line.');
      expect(schema.sectionTypes['d00-note']!.validationPrompt,
          'Check the notes are actionable.');
    });

    test('toYamlString escapes embedded double quotes so a description with '
        'inline quotes round-trips (json2yaml 3.0.1 does not escape)', () {
      // Regression: json2yaml double-quotes a scalar containing a comma but
      // leaves embedded `"` unescaped, producing invalid YAML. A free-text
      // @ContentHelp such as `... (e.g., "orders", "payments").` must survive.
      const guidance = 'Create a flowchart and label edges with data flow '
          'descriptions (e.g., "orders", "payments", "notifications").';
      final model = <String, ModelClass>{
        'QuoteDoc': ModelClass(
          name: 'QuoteDoc',
          annotations: [
            _a('Document', {'name': 'Quote Doc'}),
            _a('SectionId', {'id': 'Q00'}),
          ],
          fields: [
            ModelField(
              name: 'diagram',
              typeName: 'String',
              annotations: [
                _a('SectionId', {'id': 'Q00-DIAG'}),
                _a('ContentHelp', {'guidance': guidance}),
              ],
            ),
          ],
        ),
      };
      final schema = DocSpecsSchemaGenerator(model).generateFor('QuoteDoc');
      final reloaded = _writeAndReload(dir, schema);
      expect(reloaded.sectionTypes['q00-diag']!.description, guidance);
    });

    test('§5.3: @Form sections get format <type>-form; fields keep model '
        'field names with required/description/pattern-check', () {
      final schema = gen.generateFor('DemoDoc');
      expect(schema.sectionTypes['d00-hdr']!.format, 'd00-hdr-form');
      final form = schema.formTypes!['d00-hdr-form']!;
      expect(form.fields.map((f) => f.fieldname), ['title', 'approvedBy']);
      final title = form.fields.first;
      expect(title.required, isTrue);
      expect(title.description, 'e.g. My System');
      final approvedBy = form.fields.last;
      expect(approvedBy.patternCheck, isNotNull);
      expect(approvedBy.patternCheck!.pattern, r'^[A-Z][a-z]+$');
      expect(approvedBy.patternCheck!.errorMessage, 'Name-cased');
    });

    test('§5.4: document lists top-level sections keyed by type name; '
        '@Min ≥ 1 makes a slot required; title-format is a custom tag', () {
      final schema = gen.generateFor('DemoDoc');
      // Required sections (@Min(1)): optional is unset (defaults to false).
      expect(schema.document.sections['d00-ovr']!.optional, isNull);
      expect(schema.document.sections['d00-itm']!.optional, isNull);
      // Optional sections are marked explicitly.
      expect(schema.document.sections['d00-det']!.optional, isTrue);
      expect(schema.document.sections['d00-hdr']!.optional, isTrue);
      // The id-less Notes container bubbles its section-bearing self up.
      expect(schema.document.sections['d00-note']!.sectionType, 'd00-note');
      // §5 rule 4 title format rides as a custom tag.
      expect(schema.customTags['title-format'], '# <!--[D00]--> Demo Doc');
    });

    test('YRD4: a root-class @Headline wins the title-format doc name over '
        '@Document name', () {
      final model = <String, ModelClass>{
        'HeadDoc': ModelClass(
          name: 'HeadDoc',
          annotations: [
            _a('Document', {'name': 'Head Doc'}),
            _a('SectionId', {'id': 'HD00'}),
            _a('Headline', {'text': 'Headlined Document'}),
          ],
          fields: [
            ModelField(
              name: 'overview',
              typeName: 'String',
              annotations: [
                _a('SectionId', {'id': 'HD00-OVR'}),
              ],
            ),
          ],
        ),
      };
      final schema = DocSpecsSchemaGenerator(model).generateFor('HeadDoc');
      expect(schema.customTags['title-format'],
          '# <!--[HD00]--> Headlined Document');
    });

    test('§5.5: @Unused nodes are omitted from the schema entirely', () {
      final schema = gen.generateFor('DemoDoc');
      expect(schema.sectionTypes.keys, isNot(contains('d00-old')));
      expect(schema.document.sections.keys, isNot(contains('d00-old')));
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

    test('§5.7: the emitted YAML reloads through the DocSpecs loader with all '
        'constructs intact', () {
      final schema = gen.generateFor('DemoDoc');
      final reloaded = _writeAndReload(dir, schema);
      expect(reloaded.fullId, 'demo-doc/1.0');
      expect(reloaded.sectionTypes.length, schema.sectionTypes.length);
      expect(reloaded.formTypes?.length, 1);
      // Subsection constraints survive the round-trip.
      final itm = reloaded.sectionTypes['d00-itm']!;
      expect(itm.subsectionTypes!['itmr-lbl']!.maxCount, 1);
      expect(itm.patternCheckId!.pattern, r'^D00-ITM-.+$');
      // Form field description + pattern-check survive.
      final form = reloaded.formTypes!['d00-hdr-form']!;
      expect(form.fields.first.description, 'e.g. My System');
      expect(form.fields.last.patternCheck!.pattern, r'^[A-Z][a-z]+$');
      // The title-format custom tag survives.
      expect(reloaded.customTags['title-format'], '# <!--[D00]--> Demo Doc');
      // Document requiredness survives.
      expect(reloaded.document.sections['d00-ovr']!.optional, isNull);
      expect(reloaded.document.sections['d00-det']!.optional, isTrue);
    });

    test('S2: schema version counts up with the model stamp', () {
      expect(gen.generateFor('DemoDoc', modelVersion: 1).version, '1.0');
      expect(gen.generateFor('DemoDoc', modelVersion: 2).version, '2.0');
      expect(gen.generateFor('DemoDoc', modelVersion: 7).version, '7.0');
    });

    test('CS2-D7: a non-zero-minor stamp makes the in-file schema version track '
        'the full major.minor, matching the _v0 facade modelVersionString', () {
      // A model authored with a genuine minor (label 1.3.0+5.abc) must surface
      // 1.3 as the in-file schema version — the *same* string the _v0 facades
      // report via SpecModel.modelVersionString — not the int-major-only 1.0.
      const label = '1.3.0+5.abc1234';
      final schema =
          gen.generateFor('DemoDoc', modelVersion: 1, modelLabel: label);

      // Single-sourced with the facades: identical to the runtime helper.
      expect(schema.version, somModelVersionString(1, label));
      expect(schema.version, '1.3');
      // fullId (and the in-file `version:`) carry the minor.
      expect(schema.fullId, 'demo-doc/1.3');

      // The on-disk filename stays keyed off the integer major (minor pinned to
      // 0), so a minor bump does not churn the committed schema-tree filenames.
      expect(
        DocSpecsSchemaGenerator.fileNameFor(schema),
        'demo-doc.1.0.docspecs-schema.yaml',
      );

      // An unstamped model still falls back to <major>.0.
      final unstamped = gen.generateFor('DemoDoc', modelVersion: 1);
      expect(unstamped.version, '1.0');
      expect(DocSpecsSchemaGenerator.fileNameFor(unstamped),
          'demo-doc.1.0.docspecs-schema.yaml');
    });

    test('CS2-D7: generateAll threads the label to every schema', () {
      final schemas = DocSpecsSchemaGenerator(classes)
          .generateAll(modelVersion: 1, modelLabel: '2.5.0+9.deadbee');
      expect(schemas.values, isNotEmpty);
      for (final schema in schemas.values) {
        expect(schema.version, '2.5');
        // Filename still keyed off the integer major → `2.0`.
        expect(DocSpecsSchemaGenerator.fileNameFor(schema),
            '${schema.id}.2.0.docspecs-schema.yaml');
      }
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

    test('S1: generates exactly 13 schemas (1 global SBP + 12 projections)', () {
      final schemas = DocSpecsSchemaGenerator(classes).generateAll();
      expect(schemas.length, 13);
      expect(schemas.keys, contains('solution-blueprint'));
    });

    test('DR3: the generated SBP schema is §5-structured — lower-cased type '
        'names, legal prefixes, subsection-types, title-format', () {
      final schema =
          DocSpecsSchemaGenerator(classes).generateFor('D00SolutionBlueprint');
      expect(schema.id, 'solution-blueprint');
      expect(schema.sectionTypes, isNotEmpty);
      // All type names are lower-cased ids; all prefixes satisfy the DocSpecs
      // prefix grammar.
      for (final entry in schema.sectionTypes.entries) {
        expect(entry.key, equals(entry.key.toLowerCase()),
            reason: 'type name ${entry.key} must be lower-cased');
        expect(RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(entry.value.prefix!), isTrue,
            reason: 'prefix ${entry.value.prefix} must be DocSpecs-legal');
      }
      // At least one section-bearing container carries subsection-types.
      expect(
        schema.sectionTypes.values.any(
            (t) => t.subsectionTypes != null && t.subsectionTypes!.isNotEmpty),
        isTrue,
      );
      // Every pattern check compiles and is anchored.
      for (final t in schema.sectionTypes.values) {
        final check = t.patternCheckId;
        if (check == null) continue;
        expect(() => RegExp(check.pattern), returnsNormally);
        expect(check.pattern, startsWith('^'));
        expect(check.pattern, endsWith(r'$'));
      }
      // §5 rule 4 title format.
      expect(schema.customTags['title-format'], startsWith('# <!--['));
      // The document lists top-level slots referencing existing types.
      expect(schema.document.sections, isNotEmpty);
      for (final s in schema.document.sections.values) {
        expect(schema.sectionTypes, contains(s.sectionType));
      }
    });

    test('§5.7: every generated schema round-trips through the DocSpecs '
        'loader (the existing consumer can parse them)', () {
      final schemas = DocSpecsSchemaGenerator(classes).generateAll();
      for (final schema in schemas.values) {
        final reloaded = _writeAndReload(dir, schema);
        expect(reloaded.sectionTypes, isNotEmpty,
            reason: '${schema.id} has no section-types');
        expect(reloaded.version, '1.0');
        expect(reloaded.sectionTypes.length, schema.sectionTypes.length);
      }
    });
  });
}
