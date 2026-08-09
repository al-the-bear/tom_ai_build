import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The gate that keeps `tom_specs_core`'s annotation catalogue honest.
///
/// Fourteen annotations were once declared, documented as a live surface, and
/// applied nowhere — eight of them describing validation that no runtime
/// implemented. Nothing could catch it: a construct with no code has no code
/// to diff against. These tests supply the missing diff, from both ends.

AnnotationData _a(String name, [Map<String, Object?> args = const {}]) =>
    AnnotationData(name, args);

Directory get _annotationsDir => Directory(p.join(
      Directory.current.path,
      '..',
      'tom_specs_core',
      'lib',
      'src',
      'annotations',
    ));

/// A model that applies **every** schema-bound annotation at its documented
/// target, so the emitted schema must exercise every declared destination.
///
/// Deliberately one model rather than one per annotation: the realisation
/// check is a totality check, and a per-annotation fixture set is a set
/// someone can forget to extend.
Map<String, ModelClass> _allAnnotationsModel() {
  final root = ModelClass(
    name: 'EveryAnnotationDoc',
    annotations: [
      _a('Document', {'name': 'Every Annotation Doc'}),
      _a('SectionId', {'id': 'EAD'}),
      _a('Headline', {'text': 'Every Annotation'}),
    ],
    fields: [
      // @Prefix, @MaxDepth, @AllowedTags, @ValidationPrompt, @MinLength,
      // @MaxLength, @TextRequired, @ContentHelp, @AccessKey, @Position.
      ModelField(
        name: 'summary',
        typeName: 'Summary',
        annotations: [
          _a('AccessKey', {'key': 'summary-key'}),
          _a('Position', {'position': 'first'}),
          _a('Min', {'count': 1}),
        ],
      ),
      // @Form + @Field + @PatternCheck.
      ModelField(
        name: 'header',
        typeName: 'Header',
        annotations: [_a('SectionId', {'id': 'EAD-HDR'})],
      ),
      // The registry the @ForEach below binds to.
      ModelField(
        name: 'registry',
        typeName: 'List<RegistryEntry>',
        isList: true,
        listElementTypeName: 'RegistryEntry',
        listElementIsComplex: true,
        annotations: [
          _a('SectionId', {'id': 'EAD-REG-LST'}),
          _a('SectionIdPattern', {'pattern': 'EAD-REG-xxx'}),
        ],
      ),
      // @ForEach + @Max.
      ModelField(
        name: 'mirrors',
        typeName: 'List<MirrorEntry>',
        isList: true,
        listElementTypeName: 'MirrorEntry',
        listElementIsComplex: true,
        annotations: [
          _a('SectionId', {'id': 'EAD-MIR-LST'}),
          _a('SectionIdPattern', {'pattern': 'EAD-MIR-xxx'}),
          _a('ForEach', {'registryType': 'EAD-REG', 'key': 'summary-key'}),
          _a('Max', {'count': 9}),
        ],
      ),
      // @Unused: present in the model, absent from the schema.
      ModelField(
        name: 'legacy',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'EAD-OLD'}),
          _a('Unused'),
        ],
      ),
    ],
  );

  final summary = ModelClass(
    name: 'Summary',
    annotations: [
      _a('SectionId', {'id': 'EAD-SUM'}),
      _a('Prefix', {'prefix': 'SUMMARY'}),
      _a('MaxDepth', {'levels': 2}),
      _a('AllowedTags', {
        'tags': ['draft', 'final']
      }),
      _a('ValidationPrompt', {'prompt': 'Is the summary complete?'}),
      _a('ContentHelp', {'guidance': 'One paragraph of intent.'}),
    ],
    fields: [
      ModelField(
        name: 'body',
        typeName: 'String',
        annotations: [
          _a('SectionId', {'id': 'SUM-BOD'}),
          _a('TextRequired'),
          _a('MinLength', {'length': 20}),
          _a('MaxLength', {'length': 400}),
          _a('Position', {'position': 'last'}),
          _a('Min', {'count': 1}),
        ],
      ),
    ],
  );

  final header = ModelClass(
    name: 'Header',
    annotations: [_a('Form')],
    formFields: [
      FormFieldInfo(
        name: 'owner',
        typeName: 'String',
        required: true,
        hint: 'Accountable person',
      ),
    ],
    fields: [
      ModelField(
        name: 'owner',
        typeName: 'String?',
        annotations: [
          _a('PatternCheck',
              {'pattern': r'^[A-Z][a-z]+$', 'errorMessage': 'Name-cased'}),
        ],
      ),
    ],
  );

  final registryEntry = ModelClass(
    name: 'RegistryEntry',
    fields: [
      ModelField(
        name: 'label',
        typeName: 'String',
        annotations: [_a('SectionId', {'id': 'REG-LBL'})],
      ),
    ],
  );

  final mirrorEntry = ModelClass(
    name: 'MirrorEntry',
    // @PatternCheckId overriding the @SectionIdPattern-derived stem check.
    annotations: [
      _a('PatternCheckId',
          {'pattern': r'^EAD-MIR-[0-9]{3}$', 'errorMessage': 'Three digits'}),
    ],
    fields: [
      ModelField(
        name: 'note',
        typeName: 'String',
        annotations: [_a('SectionId', {'id': 'MIR-NOT'})],
      ),
    ],
  );

  return {
    'EveryAnnotationDoc': root,
    'Summary': summary,
    'Header': header,
    'RegistryEntry': registryEntry,
    'MirrorEntry': mirrorEntry,
  };
}

/// Every YAML key present anywhere in [yaml], at any depth.
Set<String> _allKeys(Object? yaml) {
  final keys = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        keys.add('${entry.key}');
        walk(entry.value);
      }
    } else if (node is Iterable) {
      node.forEach(walk);
    }
  }

  walk(yaml);
  return keys;
}

void main() {
  group('TSAM1 annotation catalogue ↔ DocSpecs destination table', () {
    test('every declared annotation names a destination, and vice versa', () {
      final correspondence = checkAnnotationCatalogue(_annotationsDir);
      expect(
        correspondence.describeMismatch(),
        isNull,
        reason: 'tom_specs_core and docSpecsAnnotationBindings disagree.',
      );
      // Guard the scanner itself: a regex that silently matched nothing would
      // make the diff above pass vacuously.
      expect(correspondence.declared, contains('SectionId'));
      expect(correspondence.declared.length, greaterThan(30));
    });

    test('every binding is exactly one of schema-bound or model-only', () {
      for (final binding in docSpecsAnnotationBindings) {
        expect(
          binding.isSchemaBound,
          binding.modelOnly == null,
          reason: '${binding.annotation} must be one or the other.',
        );
        expect(binding.note.trim(), isNotEmpty,
            reason: '${binding.annotation} must say why.');
      }
    });

    test('@SeedFor is gone — it duplicated @MapsTo/@DetailedIn', () {
      // It named the single document a section seeds, which is exactly what
      // @MapsTo/@DetailedIn say — and those are enforced by the §10.2
      // structural invariants, while @SeedFor was enforced by nothing and had
      // no DocSpecs counterpart to be generated into.
      final correspondence = checkAnnotationCatalogue(_annotationsDir);
      expect(correspondence.declared, isNot(contains('SeedFor')));
      expect(docSpecsAnnotationBindingsByName, isNot(contains('SeedFor')));
    });
  });

  group('TSAM2 declared destinations are actually emitted', () {
    late Map<String, dynamic> yaml;
    late DocSpecSchema schema;

    setUp(() {
      schema = DocSpecsSchemaGenerator(_allAnnotationsModel())
          .generateFor('EveryAnnotationDoc');
      yaml = schema.toYaml();
    });

    test('every schema-bound annotation produces its declared key', () {
      final emitted = _allKeys(yaml);
      final missing = boundDocSpecsSchemaKeys.difference(emitted).toList()
        ..sort();
      expect(
        missing,
        isEmpty,
        reason: 'docSpecsAnnotationBindings claims these DocSpecs keys, but '
            'a model applying every annotation produced none of them. Either '
            'wire the generator or correct the binding.',
      );
    });

    test('the seven newly wired destinations carry the annotated values', () {
      final summary = schema.sectionTypes['ead-sum']!;
      expect(summary.prefix, 'SUMMARY', reason: '@Prefix');
      expect(summary.maxSubsectionLevels, 2, reason: '@MaxDepth');
      expect(summary.allowedTags, ['draft', 'final'], reason: '@AllowedTags');

      final mirror = schema.sectionTypes['ead-mir']!;
      expect(mirror.patternCheckId?.pattern, r'^EAD-MIR-[0-9]{3}$',
          reason: '@PatternCheckId overrides the derived stem check');
      expect(mirror.patternCheckId?.errorMessage, 'Three digits');

      final summarySection = schema.document.sections['ead-sum']!;
      expect(summarySection.accessKey, 'summary-key', reason: '@AccessKey');

      final mirrorSection = schema.document.sections['ead-mir-lst']!;
      expect(mirrorSection.forEach?.sectionType, 'ead-reg', reason: '@ForEach');
      expect(mirrorSection.forEach?.key, 'summary-key');

      expect(
        schema.subsectionDeclarations?['ead-sum']?['sum-bod']?.position,
        'last',
        reason: '@Position on a child of a top-level section',
      );
    });

    test('a @SectionIdPattern with no @PatternCheckId keeps the stem check',
        () {
      final registry = schema.sectionTypes['ead-reg']!;
      expect(registry.patternCheckId?.pattern, r'^EAD-REG-.+$');
    });

    test('the emitted schema round-trips through the DocSpecs loader', () {
      final dir = Directory.systemTemp.createTempSync('tsam-schema-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(
        dir.path,
        schema.id,
        DocSpecsSchemaGenerator.fileNameFor(schema),
      ))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(DocSpecsSchemaGenerator.toYamlString(schema));

      final reloaded = SchemaLoader.loadSync(file.path);
      expect(reloaded.sectionTypes['ead-sum']?.allowedTags, ['draft', 'final']);
      expect(reloaded.sectionTypes['ead-sum']?.maxSubsectionLevels, 2);
      expect(reloaded.document.sections['ead-sum']?.accessKey, 'summary-key');
      expect(
        reloaded.document.sections['ead-mir-lst']?.forEach?.sectionType,
        'ead-reg',
      );
      expect(
        reloaded.subsectionDeclarations?['ead-sum']?['sum-bod']?.position,
        'last',
      );
    });
  });

  group('TSAM4 the SOM metadata carries every catalogued annotation', () {
    // The nine language runtimes are built from the metadata tree, so an
    // annotation the tree drops is an annotation no editor on any runtime can
    // see. Slotted annotations get a named field; everything else rides the
    // lossless `extra` list. Either is fine — vanishing is not.
    test('every annotation reaches MetaNode, slotted or in extra', () {
      // One field per annotation, all on one class, so the check is total by
      // construction rather than by remembering to extend a list.
      const skip = {
        // Structural: they are read to *shape* the tree rather than to sit on
        // a node, and are exercised by meta_tree_test.
        'Document', 'Form', 'Field', 'SectionId', 'SectionIdPattern',
        'Unused', 'OneOf', 'Case',
      };
      final applied = <AnnotationData>[
        for (final binding in docSpecsAnnotationBindings)
          if (!skip.contains(binding.annotation))
            _a(binding.annotation, const {'probe': 'v'}),
      ];
      expect(applied, isNotEmpty);

      final classes = {
        'Probe': ModelClass(
          name: 'Probe',
          annotations: [
            _a('Document', {'name': 'Probe'}),
            _a('SectionId', {'id': 'PRB'}),
          ],
          fields: [
            ModelField(
              name: 'body',
              typeName: 'String',
              annotations: [
                _a('SectionId', {'id': 'PRB-BOD'}),
                ...applied,
              ],
            ),
          ],
        ),
      };

      final tree = MetaTreeBuilder(classes).build('Probe');
      final body = tree.children.single;
      final slotted = MetaTreeBuilder.slottedAnnotationNames;
      final carried = {
        ...body.extra.map((e) => e.name),
        // A slotted annotation is represented by its own field instead.
        ...applied.map((a) => a.name).where(slotted.contains),
      };
      final dropped =
          applied.map((a) => a.name).toSet().difference(carried).toList()
            ..sort();
      expect(dropped, isEmpty,
          reason: 'These annotations reach no runtime through the metadata.');
    });

    test('an unslotted annotation survives serialization with its arguments',
        () {
      final classes = {
        'Probe': ModelClass(
          name: 'Probe',
          annotations: [
            _a('Document', {'name': 'Probe'}),
            _a('SectionId', {'id': 'PRB'}),
            _a('MaxDepth', {'levels': 3}),
            _a('AllowedTags', {
              'tags': ['a', 'b']
            }),
          ],
          fields: [
            ModelField(
              name: 'body',
              typeName: 'String',
              annotations: [_a('SectionId', {'id': 'PRB-BOD'})],
            ),
          ],
        ),
      };
      final json = MetaTreeBuilder(classes).build('Probe').toJson();
      final extra = (json['extra'] as List).cast<Map<String, Object?>>();
      final byName = {for (final e in extra) e['annotation'] as String: e};
      expect((byName['MaxDepth']!['args'] as Map)['levels'], 3);
      expect((byName['AllowedTags']!['args'] as Map)['tags'], ['a', 'b']);
    });
  });

  group('TSAM3 a for-each must bind a reachable registry', () {
    test('a dangling registry reference fails generation', () {
      final classes = _allAnnotationsModel();
      final root = classes['EveryAnnotationDoc']!;
      final mirrors = root.fields.firstWhere((f) => f.name == 'mirrors');
      mirrors.annotations
        ..removeWhere((a) => a.name == 'ForEach')
        ..add(_a('ForEach', {'registryType': 'NO-SUCH', 'key': 'k'}));

      expect(
        () => DocSpecsSchemaGenerator(classes).generateFor('EveryAnnotationDoc'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('no-such'),
        )),
      );
    });
  });
}
