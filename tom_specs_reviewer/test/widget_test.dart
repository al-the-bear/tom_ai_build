import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_reviewer/src/model/review_store.dart';
import 'package:tom_specs_reviewer/src/ui/review_controls.dart';
import 'package:tom_specs_reviewer/src/ui/spec_tree.dart';
import 'package:tom_specs_reviewer/src/ui/start_page.dart';

/// A minimal hand-built model covering each render kind, so tests don't depend
/// on the multi-megabyte generated asset.
const _sampleJson = '''
{
  "classCount": 2,
  "rootCount": 1,
  "roots": [
    {"type": "DemoDoc", "title": "Demo Document", "sectionId": "DM00"}
  ],
  "classes": {
    "DemoDoc": {
      "name": "DemoDoc",
      "sectionId": "DM00",
      "fields": [
        {"name": "intro", "kind": "content", "contentType": "text"},
        {"name": "diagram", "kind": "section", "contentType": "mermaid",
         "sectionType": "DiagramSection"},
        {"name": "priority", "kind": "enum", "enumType": "Priority",
         "enumValues": ["low", "high"]},
        {"name": "label", "kind": "scalar", "type": "String"},
        {"name": "header", "kind": "form", "formFields": [
          {"name": "title", "label": "Title", "type": "String",
           "required": true},
          {"name": "owner", "label": "Owner", "type": "String"}
        ]},
        {"name": "items", "kind": "list", "elementType": "ItemEntry",
         "elementIsComplex": true, "min": 1}
      ]
    },
    "ItemEntry": {
      "name": "ItemEntry",
      "sectionId": "DM01",
      "fields": [
        {"name": "value", "kind": "scalar", "type": "String"}
      ]
    }
  }
}
''';

SpecModel _model() =>
    SpecModel.fromJson(json.decode(_sampleJson) as Map<String, dynamic>);

/// A two-document model with a hand-off: in `MainDoc`, `Handoff` is detailed in
/// `OtherDoc`; `OtherDoc` reaches `Handoff` (whose subsections are the detail).
const _handoffJson = '''
{
  "classCount": 5,
  "rootCount": 2,
  "roots": [
    {"type": "MainDoc", "title": "Main", "sectionId": "MN00"},
    {"type": "OtherDoc", "title": "Other", "sectionId": "OT00"}
  ],
  "classes": {
    "MainDoc": {
      "name": "MainDoc", "sectionId": "MN00",
      "fields": [
        {"name": "handoff", "kind": "complex", "type": "Handoff"}
      ]
    },
    "Handoff": {
      "name": "Handoff", "sectionId": "MN01", "detailedIn": "OtherDoc",
      "fields": [
        {"name": "summary", "kind": "content", "contentType": "text"},
        {"name": "detail", "kind": "complex", "type": "Detail"}
      ]
    },
    "Detail": {
      "name": "Detail", "sectionId": "MN02",
      "fields": [
        {"name": "value", "kind": "scalar", "type": "String"}
      ]
    },
    "OtherDoc": {
      "name": "OtherDoc", "sectionId": "OT00",
      "fields": [
        {"name": "handoff", "kind": "complex", "type": "Handoff"},
        {"name": "mapped", "kind": "complex", "type": "Mapped"}
      ]
    },
    "Mapped": {
      "name": "Mapped", "sectionId": "OT01", "mapsTo": "MainDoc",
      "fields": [
        {"name": "summary", "kind": "content", "contentType": "text"},
        {"name": "detail", "kind": "complex", "type": "Detail"}
      ]
    }
  }
}
''';

SpecModel _handoffModel() =>
    SpecModel.fromJson(json.decode(_handoffJson) as Map<String, dynamic>);

/// [_sampleJson] plus the generation stamp the exporter writes, so the stamp
/// bar has something to render. Defaults describe a healthy snapshot; each
/// parameter exists so a test can spoil exactly one property.
SpecModel _stampedModel({
  String generatedAt = '2026-07-20T08:00:00.000000Z',
  int classCount = 2,
  int rootCount = 1,
}) =>
    SpecModel.fromJson({
      ...json.decode(_sampleJson) as Map<String, dynamic>,
      'modelVersion': 9,
      'modelVersionLabel': '1.0.0+9',
      'generatedAt': generatedAt,
      'metaSchemaVersion': 1,
      'classCount': classCount,
      'rootCount': rootCount,
      'containerRoot': 'DocSpecsProject',
    });

/// A model exercising all three `@CodeSpecKind` states plus the field-level and
/// collapsed-complex cases.
///
/// `KindDoc` is mapped to several kinds; `EmptyKinds` carries the annotation
/// with no kinds (a recorded "maps to nothing"); `NoKinds` carries none at all.
const _kindJson = '''
{
  "classCount": 3,
  "rootCount": 1,
  "roots": [
    {"type": "KindDoc", "title": "Kind Document", "sectionId": "KD00"}
  ],
  "classes": {
    "KindDoc": {
      "name": "KindDoc", "sectionId": "KD00",
      "annotations": [
        {"name": "CodeSpecKind",
         "arguments": {"kinds": ["CodeSpecPart.authorization",
                                 "CodeSpecPart.authentication"],
                       "note": "CE-AZ — access rules"}}
      ],
      "fields": [
        {"name": "flags", "kind": "form",
         "formFields": [{"name": "on", "label": "On", "type": "bool"}],
         "annotations": [
           {"name": "CodeSpecKind",
            "arguments": {"kinds": ["CodeSpecPart.serverConfiguration"]}}
         ]},
        {"name": "plain", "kind": "content", "contentType": "text"},
        {"name": "empty", "kind": "complex", "type": "EmptyKinds"},
        {"name": "none", "kind": "complex", "type": "NoKinds"}
      ]
    },
    "EmptyKinds": {
      "name": "EmptyKinds", "sectionId": "KD01",
      "annotations": [
        {"name": "CodeSpecKind", "arguments": {"kinds": []}}
      ],
      "fields": [
        {"name": "value", "kind": "scalar", "type": "String"}
      ]
    },
    "NoKinds": {
      "name": "NoKinds", "sectionId": "KD02",
      "fields": [
        {"name": "value", "kind": "scalar", "type": "String"}
      ]
    }
  }
}
''';

SpecModel _kindModel() =>
    SpecModel.fromJson(json.decode(_kindJson) as Map<String, dynamic>);

/// Fixture for the `@FollowUpKind` / `@CodeSpecsProjection` split (TSRA3).
///
/// Two roots, because the projection marking is only meaningful next to an
/// ordinary authoring document: `AuthoringDoc` holds a CodeSpecs-mapped section
/// and a follow-up subtree; `ProjectionDoc` is the `@CodeSpecsProjection` root
/// that re-references the former and is therefore *supposed* to be shallow.
const _followUpJson = '''
{
  "classCount": 4,
  "rootCount": 2,
  "roots": [
    {"type": "AuthoringDoc", "title": "Authoring Document", "sectionId": "AD00"},
    {"type": "ProjectionDoc", "title": "Projection Document",
     "sectionId": "PD00"}
  ],
  "classes": {
    "AuthoringDoc": {
      "name": "AuthoringDoc", "sectionId": "AD00",
      "fields": [
        {"name": "rules", "kind": "complex", "type": "MappedSection"},
        {"name": "handbook", "kind": "complex", "type": "MultiProcess"},
        {"name": "training", "kind": "complex", "type": "SingleProcess"}
      ]
    },
    "MappedSection": {
      "name": "MappedSection", "sectionId": "AD01",
      "annotations": [
        {"name": "CodeSpecKind",
         "arguments": {"kinds": ["CodeSpecPart.validation"]}}
      ],
      "fields": [{"name": "value", "kind": "scalar", "type": "String"}]
    },
    "MultiProcess": {
      "name": "MultiProcess", "sectionId": "AD02",
      "annotations": [
        {"name": "FollowUpKind",
         "arguments": {"processes": ["FollowUpProcess.doc",
                                     "FollowUpProcess.cap",
                                     "FollowUpProcess.mig"],
                       "note": "Feeds the data-migration handbook"}}
      ],
      "fields": [{"name": "value", "kind": "scalar", "type": "String"}]
    },
    "SingleProcess": {
      "name": "SingleProcess", "sectionId": "AD03",
      "annotations": [
        {"name": "FollowUpKind",
         "arguments": {"processes": ["FollowUpProcess.trn"]}}
      ],
      "fields": [{"name": "value", "kind": "scalar", "type": "String"}]
    },
    "ProjectionDoc": {
      "name": "ProjectionDoc", "sectionId": "PD00",
      "annotations": [
        {"name": "CodeSpecsProjection"}
      ],
      "fields": [
        {"name": "rules", "kind": "complex", "type": "MappedSection"}
      ]
    }
  }
}
''';

SpecModel _followUpModel() =>
    SpecModel.fromJson(json.decode(_followUpJson) as Map<String, dynamic>);

/// Fixture for the `@OneOf` / `@Case` closed choice (TSRA4).
///
/// Shaped like the real `ScreenElementEntry`: a `@Form` `content` section
/// carrying the discriminator form-field, one *common* subsection that applies
/// to every case, and two `@Case` alternatives — one of which claims two values,
/// so a reader that took only the first `@Case` would be caught. One
/// discriminator value (`divider`) is deliberately left uncovered, which §8.2
/// makes a warning rather than an error.
const _oneOfJson = '''
{
  "classCount": 4,
  "rootCount": 1,
  "roots": [
    {"type": "ChoiceDoc", "title": "Choice Document", "sectionId": "CD00"}
  ],
  "classes": {
    "ChoiceDoc": {
      "name": "ChoiceDoc", "sectionId": "CD00",
      "fields": [
        {"name": "element", "kind": "complex", "type": "Element"},
        {"name": "plainSection", "kind": "complex", "type": "PlainSection"}
      ]
    },
    "Element": {
      "name": "Element", "sectionId": "CD01",
      "annotations": [
        {"name": "OneOf",
         "arguments": {"discriminator": "elementType",
                       "note": "The element kind selects its facet subsection"}}
      ],
      "fields": [
        {"name": "content", "kind": "form",
         "formFields": [
           {"name": "elementId", "label": "Element id", "type": "String"},
           {"name": "elementType", "label": "Element type",
            "type": "ElementKind",
            "enumValues": ["action", "input", "display", "divider"]}
         ]},
        {"name": "layout", "kind": "form",
         "formFields": [{"name": "width", "label": "Width", "type": "String"}]},
        {"name": "elementAction", "kind": "complex", "type": "ActionFacet",
         "annotations": [
           {"name": "Case", "arguments": {"value": "ElementKind.action"}}
         ]},
        {"name": "fieldSpec", "kind": "complex", "type": "InputFacet",
         "annotations": [
           {"name": "Case", "arguments": {"value": "ElementKind.input"}},
           {"name": "Case", "arguments": {"value": "ElementKind.display"}}
         ]}
      ]
    },
    "ActionFacet": {
      "name": "ActionFacet", "sectionId": "CD02",
      "fields": [{"name": "target", "kind": "scalar", "type": "String"}]
    },
    "InputFacet": {
      "name": "InputFacet", "sectionId": "CD03",
      "fields": [{"name": "dataType", "kind": "scalar", "type": "String"}]
    },
    "PlainSection": {
      "name": "PlainSection", "sectionId": "CD04",
      "fields": [{"name": "value", "kind": "scalar", "type": "String"}]
    }
  }
}
''';

SpecModel _oneOfModel() =>
    SpecModel.fromJson(json.decode(_oneOfJson) as Map<String, dynamic>);

/// The same fixture with `divider` removed from the discriminator enum, so the
/// choice is fully covered.
SpecModel _completeOneOfModel() => SpecModel.fromJson(
      json.decode(_oneOfJson.replaceAll(
        '"action", "input", "display", "divider"',
        '"action", "input", "display"',
      )) as Map<String, dynamic>,
    );

/// A model carrying the annotations TSRA5 renders: the `@Unused` marker, the
/// `@Comment` note at both class and field level (including the `locus:`
/// variant), `@Reference` + `@StandardReferences` provenance, a list field with
/// *both* a `sectionId` and a `@SectionIdPattern`, and serialization ordinals.
const _annotationJson = '''
{
  "classCount": 2,
  "rootCount": 1,
  "roots": [
    {"type": "AnnDoc", "title": "Annotated Document", "sectionId": "AN00"}
  ],
  "classes": {
    "AnnDoc": {
      "name": "AnnDoc",
      "sectionId": "AN00",
      "annotations": [
        {"name": "Comment", "arguments": {"text": "Seeds -> QAP"}},
        {"name": "StandardReferences", "arguments": {
          "standards": ["ISO 21502:2020 -- project management"],
          "connotation": "What the document owns."}}
      ],
      "standardReferences": {
        "standards": ["ISO 21502:2020 -- project management"],
        "connotation": "What the document owns."
      },
      "fields": [
        {"name": "intro", "kind": "content", "contentType": "text",
         "sectionId": "AN01", "serializationOrder": 0,
         "annotations": [
           {"name": "Unused"},
           {"name": "Reference", "arguments": {"description": "objectName"}}
         ]},
        {"name": "notes", "kind": "content", "contentType": "text",
         "sectionId": "AN02", "serializationOrder": 1},
        {"name": "items", "kind": "list", "elementType": "ItemEntry",
         "elementIsComplex": true, "sectionId": "ANIT",
         "sectionIdPattern": "ANIT-ITEM-xxx", "serializationOrder": 2,
         "annotations": [
           {"name": "Comment", "arguments": {"text": "locus: shared -- CE-ER"}}
         ],
         "standardReferences": {
           "standards": ["IEEE 829-2008 -- test documentation"],
           "connotation": "Lists the individual items."
         }}
      ]
    },
    "ItemEntry": {
      "name": "ItemEntry",
      "sectionId": "ANIE",
      "fields": [
        {"name": "value", "kind": "scalar", "type": "String",
         "serializationOrder": 0}
      ]
    }
  }
}
''';

SpecModel _annotationModel() => SpecModel.fromJson(
    json.decode(_annotationJson) as Map<String, dynamic>);

File _tempReviewFile(String name) {
  final dir = Directory(
      '${Directory.current.path}/.dart_tool/specs_reviewer_test');
  dir.createSync(recursive: true);
  return File('${dir.path}/$name');
}

void main() {
  group('SpecModel parsing', () {
    test('classifies field kinds', () {
      final model = _model();
      expect(model.roots, hasLength(1));
      expect(model.roots.single.title, 'Demo Document');
      final doc = model.classNamed('DemoDoc')!;
      final byName = {for (final f in doc.fields) f.name: f};
      expect(byName['intro']!.kind, SpecFieldKind.content);
      expect(byName['diagram']!.kind, SpecFieldKind.section);
      expect(byName['diagram']!.contentType, 'mermaid');
      expect(byName['priority']!.kind, SpecFieldKind.enumValue);
      expect(byName['priority']!.enumValues, ['low', 'high']);
      expect(byName['label']!.kind, SpecFieldKind.scalar);
      expect(byName['header']!.kind, SpecFieldKind.form);
      expect(byName['header']!.formFields, hasLength(2));
      expect(byName['header']!.formFields.first.required, isTrue);
      expect(byName['items']!.kind, SpecFieldKind.list);
      expect(byName['items']!.elementIsComplex, isTrue);
      expect(byName['items']!.min, 1);
    });
  });

  group('ReviewStore', () {
    test('persists and reloads entries via YAML', () {
      final file = _tempReviewFile('roundtrip.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      store.update('DemoDoc/intro', (e) {
        e.scope = ReviewScope.globalWithAdaptations;
        e.addDetails = true;
        e.comment = 'Needs an "example" here\nsecond line';
      });
      expect(file.existsSync(), isTrue);

      final reloaded = ReviewStore(file)..load();
      final entry = reloaded.entryFor('DemoDoc/intro')!;
      expect(entry.scope, ReviewScope.globalWithAdaptations);
      expect(entry.addDetails, isTrue);
      expect(entry.comment, 'Needs an "example" here\nsecond line');
      file.deleteSync();
    });

    test('removes an entry when cleared to empty', () {
      final file = _tempReviewFile('clear.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      store.update('p', (e) => e.scope = ReviewScope.global);
      expect(store.count, 1);
      store.update('p', (e) => e.scope = ReviewScope.none);
      expect(store.count, 0);
      file.deleteSync();
    });

    test('round-trips structure flags and the reviewed checkmark', () {
      final file = _tempReviewFile('flags.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      store.update('DemoDoc/items', (e) {
        e.mustBeList = true;
        e.singleEntry = true;
        e.mustBeContentString = true;
        e.convertFormToContent = true;
        e.reviewed = true;
      });

      final reloaded = ReviewStore(file)..load();
      final entry = reloaded.entryFor('DemoDoc/items')!;
      expect(entry.mustBeList, isTrue);
      expect(entry.singleEntry, isTrue);
      expect(entry.mustBeContentString, isTrue);
      expect(entry.convertFormToContent, isTrue);
      expect(entry.reviewed, isTrue);
      file.deleteSync();
    });

    test('reviewed-only entry is persisted (not treated as empty)', () {
      final file = _tempReviewFile('reviewed_only.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      store.update('DemoDoc/intro', (e) => e.reviewed = true);
      expect(store.count, 1);
      final reloaded = ReviewStore(file)..load();
      expect(reloaded.entryFor('DemoDoc/intro')?.reviewed, isTrue);
      file.deleteSync();
    });
  });

  group('pathToType (navigation chain)', () {
    test('finds the shortest chain root→target', () {
      final model = _handoffModel();
      expect(pathToType(model, 'OtherDoc', 'Detail'),
          {'OtherDoc', 'Handoff', 'Detail'});
    });

    test('returns just the root when target equals root', () {
      final model = _handoffModel();
      expect(pathToType(model, 'MainDoc', 'MainDoc'), {'MainDoc'});
    });

    test('returns empty when the target is unreachable', () {
      final model = _handoffModel();
      expect(pathToType(model, 'Detail', 'MainDoc'), isEmpty);
    });
  });

  group('Hand-off cut (2b)', () {
    testWidgets('hides detailed subsections but keeps the section content',
        (tester) async {
      final file = _tempReviewFile('cut.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _handoffModel();
      final mainRoot = model.roots.firstWhere((r) => r.type == 'MainDoc');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: mainRoot,
            store: store,
            cutAtDetails: true,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      // Expand the Handoff complex node.
      await tester.tap(find.text('handoff'));
      await tester.pumpAndSettle();

      // The section's own content stays visible…
      expect(find.text('summary'), findsOneWidget);
      // …but the descending complex subsection is suppressed.
      expect(find.text('detail'), findsNothing);
      // The cut marker is shown.
      expect(find.text('cut'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the maps switch does not cut a detail-only hand-off',
        (tester) async {
      final file = _tempReviewFile('detailonly.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _handoffModel();
      final mainRoot = model.roots.firstWhere((r) => r.type == 'MainDoc');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: mainRoot,
            store: store,
            cutAtMaps: true, // only maps; Handoff is a detail hand-off
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.tap(find.text('handoff'));
      await tester.pumpAndSettle();

      // Detail hand-off is untouched by the maps switch.
      expect(find.text('detail'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the maps switch cuts a @MapsTo hand-off (2d)',
        (tester) async {
      final file = _tempReviewFile('mapscut.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _handoffModel();
      // OtherDoc contains "Mapped" (mapsTo MainDoc) with a "detail" subsection.
      final otherRoot = model.roots.firstWhere((r) => r.type == 'OtherDoc');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: otherRoot,
            store: store,
            cutAtMaps: true,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.tap(find.text('mapped'));
      await tester.pumpAndSettle();

      // Section content stays, subsection is suppressed.
      expect(find.text('summary'), findsOneWidget);
      expect(find.text('detail'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('shows subsections when cut is off', (tester) async {
      final file = _tempReviewFile('nocut.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _handoffModel();
      final mainRoot = model.roots.firstWhere((r) => r.type == 'MainDoc');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: mainRoot,
            store: store,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.tap(find.text('handoff'));
      await tester.pumpAndSettle();

      expect(find.text('summary'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('List section content', () {
    testWidgets('an expanded list shows its own intro content part',
        (tester) async {
      final file = _tempReviewFile('listcontent.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _model();
      final root = model.roots.single;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: SpecRoot(type: root.type, title: root.title),
            store: store,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      // The DemoDoc root is expanded by default; expand the `items` list.
      await tester.tap(find.text('items'));
      await tester.pumpAndSettle();

      // The list now exposes a 'content' node for its section intro, alongside
      // the three element instances.
      expect(find.text('content'), findsOneWidget);
      expect(find.text('Item 1'), findsWidgets);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('Merged complex node (collapse field + type)', () {
    testWidgets('a complex field renders as a single node carrying the '
        'variable name and the type, with one section id', (tester) async {
      final file = _tempReviewFile('merged.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _handoffModel();
      final mainRoot = model.roots.firstWhere((r) => r.type == 'MainDoc');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: mainRoot,
            store: store,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      // MainDoc is expanded by default; its `handoff` complex field collapses
      // with the Handoff class into one row.
      // Variable (field) name appears exactly once — not duplicated by a
      // separate class row.
      expect(find.text('handoff'), findsOneWidget);
      // The type name is shown alongside the variable name.
      expect(find.text('Handoff'), findsOneWidget);
      // The merged node carries a single section id (the field's id falling
      // back to the class id), not two rows each showing it.
      expect(find.text('MN01'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('Section content injection', () {
    testWidgets('a section with subsections but no content field gets an '
        'injected content node', (tester) async {
      final file = _tempReviewFile('inject.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      final model = _handoffModel();
      // MainDoc has only the `handoff` subsection and no content field, so an
      // intro content part is injected.
      final mainRoot = model.roots.firstWhere((r) => r.type == 'MainDoc');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: mainRoot,
            store: store,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      // Root expanded by default; the injected content node is visible while
      // `handoff` is still collapsed (so no other 'content' label competes).
      expect(find.text('content'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('StartPage widget', () {
    testWidgets('shows roots and renders a tree on selection', (tester) async {
      final file = _tempReviewFile('widget.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      await tester.pumpWidget(MaterialApp(
        home: StartPage(model: _model(), store: store),
      ));
      expect(find.text('Document Structures'), findsOneWidget);
      expect(find.text('Demo Document'), findsWidgets);

      await tester.tap(find.text('Demo Document').first);
      await tester.pumpAndSettle();

      // Root expands by default → its content field is visible.
      expect(find.text('intro'), findsOneWidget);
      expect(find.text('header'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('@CodeSpecKind rendering (TSRA2)', () {
    Future<File> pumpTree(WidgetTester tester, String name) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      final model = _kindModel();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: model.roots.single,
            store: ReviewStore(file),
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      return file;
    }

    testWidgets('a mapped class shows one chip per kind, not just the first',
        (tester) async {
      final file = await pumpTree(tester, 'kind_multi.yaml');
      // The root is expanded by default, so its own chips are on screen.
      expect(find.text('cs:authorization'), findsOneWidget);
      expect(find.text('cs:authentication'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the mapping note is available as a tooltip', (tester) async {
      final file = await pumpTree(tester, 'kind_note.yaml');
      final tooltip = tester.widget<Tooltip>(find.ancestor(
        of: find.text('cs:authorization'),
        matching: find.byType(Tooltip),
      ));
      expect(tooltip.message, 'CE-AZ — access rules');
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a field carries its own mapping, independent of its class',
        (tester) async {
      final file = await pumpTree(tester, 'kind_field.yaml');
      expect(find.text('cs:serverConfiguration'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('an unmapped node shows the unmapped marker, not a blank',
        (tester) async {
      final file = await pumpTree(tester, 'kind_unmapped.yaml');
      // `plain`, `empty`'s and `none`'s rows are all unannotated in their own
      // right; the marker must be present rather than the row simply going
      // quiet.
      expect(find.text('cs?'), findsWidgets);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('an empty kind list is distinct from an absent annotation',
        (tester) async {
      final file = await pumpTree(tester, 'kind_empty.yaml');
      // EmptyKinds collapses into the `empty` field row and states "no part";
      // NoKinds collapses into `none` and states "not mapped yet".
      expect(find.text('cs:none'), findsOneWidget);
      expect(find.text('cs?'), findsWidgets);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a class without the annotation renders no kind chips',
        (tester) async {
      final file = await pumpTree(tester, 'kind_absent.yaml');
      expect(find.textContaining('cs:authorization'), findsOneWidget);
      // Nothing invented for the unannotated classes.
      expect(find.text('cs:validation'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('@FollowUpKind rendering (TSRA3)', () {
    Future<File> pumpTree(WidgetTester tester, String name) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      final model = _followUpModel();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: model.rootByType('AuthoringDoc'),
            store: ReviewStore(file),
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return file;
    }

    testWidgets('a follow-up subtree shows every process code, not just the '
        'first', (tester) async {
      final file = await pumpTree(tester, 'fu_multi.yaml');
      expect(find.text('fu:doc'), findsOneWidget);
      expect(find.text('fu:cap'), findsOneWidget);
      expect(find.text('fu:mig'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a single-process subtree shows its one code', (tester) async {
      final file = await pumpTree(tester, 'fu_single.yaml');
      expect(find.text('fu:trn'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the follow-up note is available as a tooltip', (tester) async {
      final file = await pumpTree(tester, 'fu_note.yaml');
      final tooltip = tester.widget<Tooltip>(find.ancestor(
        of: find.text('fu:doc'),
        matching: find.byType(Tooltip),
      ));
      expect(tooltip.message, 'Feeds the data-migration handbook');
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a follow-up subtree is not also reported as unmapped '
        'CodeSpecs', (tester) async {
      // The §8.3 split: a subtree tagged for a follow-up process *has* been
      // classified. Showing "cs?" beside "fu:doc" would state the opposite and
      // invite a reviewer to chase a mapping that must not exist.
      final file = await pumpTree(tester, 'fu_split.yaml');
      final row = find.ancestor(
        of: find.text('fu:doc'),
        matching: find.byType(Wrap),
      );
      expect(find.descendant(of: row.first, matching: find.text('cs?')),
          findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a CodeSpecs-mapped section carries no follow-up chip',
        (tester) async {
      final file = await pumpTree(tester, 'fu_none.yaml');
      expect(find.text('cs:validation'), findsOneWidget);
      final row = find.ancestor(
        of: find.text('cs:validation'),
        matching: find.byType(Wrap),
      );
      expect(find.descendant(of: row.first, matching: find.textContaining('fu:')),
          findsNothing);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('@CodeSpecsProjection marking (TSRA3)', () {
    Future<File> pumpStart(WidgetTester tester, String name) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      await tester.pumpWidget(MaterialApp(
        home: StartPage(model: _followUpModel(), store: ReviewStore(file)),
      ));
      await tester.pumpAndSettle();
      return file;
    }

    testWidgets('the projection root is labelled in the root list',
        (tester) async {
      final file = await pumpStart(tester, 'proj_list.yaml');
      // Exactly one of the two roots is a projection.
      expect(find.text('projection'), findsOneWidget);
      final tile = find.ancestor(
        of: find.text('Projection Document'),
        matching: find.byType(ListTile),
      );
      expect(find.descendant(of: tile, matching: find.text('projection')),
          findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the projection root is labelled in the tree it opens',
        (tester) async {
      final file = await pumpStart(tester, 'proj_tree.yaml');
      await tester.tap(find.text('Projection Document'));
      await tester.pumpAndSettle();
      // Once in the tree, both the root list badge and the root node chip say
      // so — the reviewer sees it whichever they are looking at.
      expect(find.text('projection'), findsNWidgets(2));
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the detail review controls are caveated inside a projection',
        (tester) async {
      final file = await pumpStart(tester, 'proj_caveat.yaml');
      await tester.tap(find.text('Projection Document'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('CodeSpecs projection'), findsOneWidget);
      expect(find.textContaining('Detail belongs on the source section'),
          findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('an authoring document keeps the ordinary detail controls',
        (tester) async {
      final file = await pumpStart(tester, 'proj_authoring.yaml');
      await tester.tap(find.text('Authoring Document'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note).first);
      await tester.pumpAndSettle();

      expect(find.text('This node needs further specification'), findsOneWidget);
      expect(find.textContaining('CodeSpecs projection'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('@OneOf / @Case rendering (TSRA4)', () {
    Future<File> pumpTree(WidgetTester tester, String name,
        {SpecModel? model}) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      final m = model ?? _oneOfModel();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: m,
            root: m.roots.single,
            store: ReviewStore(file),
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // `element` collapses the field and its class into one row, closed by
      // default; the choice lives inside it.
      await tester.tap(find.text('element'));
      await tester.pumpAndSettle();
      return file;
    }

    /// The left indent of the tree row whose headline is [label], as rendered
    /// by `_NodeRow` (`16 * depth`).
    double indentOf(WidgetTester tester, String label) {
      final padding = tester.widget<Padding>(find
          .ancestor(of: find.text(label), matching: find.byType(Padding))
          .first);
      return (padding.padding as EdgeInsets).left;
    }

    testWidgets('the closed choice renders as its own node naming the '
        'discriminator', (tester) async {
      final file = await pumpTree(tester, 'oneof_group.yaml');
      expect(find.text('one of: elementType'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the alternatives sit inside the group, the common sections '
        'outside it', (tester) async {
      // This is the whole point: exclusivity has to be visible as *structure*,
      // not inferred from a chip on an otherwise ordinary sibling row.
      final file = await pumpTree(tester, 'oneof_indent.yaml');
      final group = indentOf(tester, 'one of: elementType');
      expect(indentOf(tester, 'layout'), group,
          reason: 'a common section is a sibling of the group');
      expect(indentOf(tester, 'elementAction'), greaterThan(group));
      expect(indentOf(tester, 'fieldSpec'), greaterThan(group));
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('each alternative shows every case value, not just the first',
        (tester) async {
      // `@Case` is repeatable; `fieldSpec` claims two kinds.
      final file = await pumpTree(tester, 'oneof_cases.yaml');
      expect(find.text('case:action'), findsOneWidget);
      expect(find.text('case:input'), findsOneWidget);
      expect(find.text('case:display'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a common section carries no case chip', (tester) async {
      final file = await pumpTree(tester, 'oneof_common.yaml');
      final row =
          find.ancestor(of: find.text('layout'), matching: find.byType(Wrap));
      expect(
          find.descendant(of: row.first, matching: find.textContaining('case:')),
          findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the group states its coverage against the discriminator enum',
        (tester) async {
      final file = await pumpTree(tester, 'oneof_coverage.yaml');
      expect(find.text('covers 3/4'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('uncovered discriminator values are named, not merely counted',
        (tester) async {
      // "Is this set complete?" is unanswerable unless the gap is spelled out.
      final file = await pumpTree(tester, 'oneof_uncovered.yaml');
      expect(find.text('uncovered: divider'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a fully covered choice shows no uncovered chip',
        (tester) async {
      final file = await pumpTree(tester, 'oneof_complete.yaml',
          model: _completeOneOfModel());
      expect(find.text('covers 3/3'), findsOneWidget);
      expect(find.textContaining('uncovered:'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the @OneOf note is shown on the group', (tester) async {
      final file = await pumpTree(tester, 'oneof_note.yaml');
      expect(find.text('The element kind selects its facet subsection'),
          findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the closure decision is itself reviewable', (tester) async {
      // The group gets its own path so "is closure right here?" can be
      // answered without hijacking one of the alternatives' entries — which
      // keep their existing paths.
      final file = await pumpTree(tester, 'oneof_path.yaml');
      final paths = tester
          .widgetList<ReviewControls>(find.byType(ReviewControls))
          .map((c) => c.path)
          .toList();
      expect(paths, contains('ChoiceDoc/element/§oneof'));
      expect(paths, contains('ChoiceDoc/element/elementAction'));
      expect(paths, contains('ChoiceDoc/element/fieldSpec'));
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a class without @OneOf renders no group', (tester) async {
      final file = await pumpTree(tester, 'oneof_absent.yaml');
      expect(find.textContaining('one of:'), findsOneWidget);
      final row = find.ancestor(
          of: find.text('plainSection'), matching: find.byType(Wrap));
      expect(
          find.descendant(of: row.first, matching: find.textContaining('one of')),
          findsNothing);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('@OneOf / @Case against the shipped model (TSRA4)', () {
    // Asserted against the real `assets/spec_model.json` rather than a fixture,
    // because the risk this guards is precisely that the renderer handles the
    // hand-made shape and not the shipped one. Every expectation is derived
    // from the snapshot, so refreshing it cannot make these tests wrong — only
    // a renderer that stops covering the model can.
    final model = SpecModel.fromJson(
        json.decode(File('assets/spec_model.json').readAsStringSync())
            as Map<String, dynamic>);
    final choiceClasses = [
      for (final c in model.classes.values)
        if (c.oneOf != null) c,
    ];

    test('the shipped model declares closed choices at all', () {
      // Without this the rendering tests below would pass vacuously.
      expect(choiceClasses, isNotEmpty);
    });

    for (final cls in choiceClasses) {
      testWidgets('${cls.name} renders as a choice group with every case',
          (tester) async {
        final group = cls.oneOf!;
        final file = _tempReviewFile('asset_${cls.name}.yaml');
        if (file.existsSync()) file.deleteSync();
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SpecTree(
              model: model,
              root: SpecRoot(type: cls.name, title: cls.name),
              store: ReviewStore(file),
              onHandoffTap: (_, _) {},
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('one of: ${group.discriminator}'), findsOneWidget);
        expect(
            find.text('covers ${group.coveredValues.length}/'
                '${group.discriminatorValues.length}'),
            findsOneWidget);
        expect(find.text('discriminator not found'), findsNothing,
            reason: 'every shipped discriminator must resolve');

        // Every `@Case` on every alternative reaches the screen — the count is
        // what catches a reader that stopped at the first repeated annotation.
        var cases = 0;
        for (final f in group.caseFields) {
          for (final value in f.caseValues) {
            cases++;
            expect(find.text('case:$value'), findsOneWidget);
          }
        }
        expect(find.textContaining('case:'), findsNWidgets(cases));

        if (file.existsSync()) file.deleteSync();
      });
    }
  });

  group('Marker, comment and reference rendering (TSRA5)', () {
    Future<File> pumpTree(WidgetTester tester, String name) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      final m = _annotationModel();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: m,
            root: m.roots.single,
            store: ReviewStore(file),
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return file;
    }

    testWidgets('@Unused marks the field with a chip', (tester) async {
      final file = await pumpTree(tester, 'ann_unused.yaml');
      expect(find.text(kUnusedChipLabel), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('@Unused also strikes the label through', (tester) async {
      // A chip alone reads like the other seven; the strike-through is what
      // makes a keep-or-drop candidate legible while scrolling.
      final file = await pumpTree(tester, 'ann_unused_label.yaml');
      final unused = tester.widget<Text>(find.text('intro'));
      expect(unused.style?.decoration, TextDecoration.lineThrough);
      final used = tester.widget<Text>(find.text('notes'));
      expect(used.style?.decoration, isNot(TextDecoration.lineThrough));
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('@Comment renders inline at class and field level',
        (tester) async {
      final file = await pumpTree(tester, 'ann_comment.yaml');
      expect(find.text('← Seeds -> QAP'), findsOneWidget);
      // The `locus:` variant drives the §4.2 project split, so it has to be
      // readable without opening anything.
      expect(find.text('← locus: shared -- CE-ER'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('references are collapsed behind a chip by default',
        (tester) async {
      final file = await pumpTree(tester, 'ann_refs_collapsed.yaml');
      // Three nodes carry provenance: the root class and the `items` list via
      // `@StandardReferences`, `intro` via `@Reference`.
      expect(find.text(kReferencesChipLabel), findsNWidgets(3));
      expect(find.textContaining('ISO 21502:2020'), findsNothing);
      expect(find.textContaining('IEEE 829-2008'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('tapping the references chip reveals standards and '
        'connotation', (tester) async {
      final file = await pumpTree(tester, 'ann_refs_open.yaml');
      await tester.tap(find.text(kReferencesChipLabel).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('ISO 21502:2020 -- project management'),
          findsOneWidget);
      expect(find.textContaining('What the document owns.'), findsOneWidget);
      // Opening one node must not open the other.
      expect(find.textContaining('IEEE 829-2008'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the references panel closes again', (tester) async {
      final file = await pumpTree(tester, 'ann_refs_toggle.yaml');
      await tester.tap(find.text(kReferencesChipLabel).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(kReferencesChipLabel).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('ISO 21502:2020'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('@Reference appears in the references panel', (tester) async {
      final file = await pumpTree(tester, 'ann_reference.yaml');
      // `intro` carries only a `@Reference`, no `@StandardReferences` — the
      // affordance must appear for it too.
      expect(find.text(kReferencesChipLabel), findsNWidgets(3));
      await tester.tap(find.descendant(
        of: find.ancestor(
            of: find.text('intro'), matching: find.byType(Column)).first,
        matching: find.text(kReferencesChipLabel),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('objectName'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('@SectionIdPattern shows alongside the sectionId',
        (tester) async {
      // Every one of the shipped 578 patterns sits on a field that *also* has
      // a sectionId, so the old `sectionId ?? pattern` fallback never showed
      // a single one of them.
      final file = await pumpTree(tester, 'ann_pattern.yaml');
      expect(find.text('ANIT'), findsOneWidget);
      expect(find.text('ANIT-ITEM-xxx'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('@SerializationOrder is hidden by default', (tester) async {
      final file = await pumpTree(tester, 'ann_order_off.yaml');
      expect(find.text('#0'), findsNothing);
      expect(find.text('#1'), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('@SerializationOrder shows when the tree is asked for it',
        (tester) async {
      final file = _tempReviewFile('ann_order_on.yaml');
      if (file.existsSync()) file.deleteSync();
      final m = _annotationModel();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: m,
            root: m.roots.single,
            store: ReviewStore(file),
            showSerializationOrder: true,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('#0'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('Serialization-order toggle persistence (TSRA5)', () {
    testWidgets('the toggle keeps its state when the document is switched',
        (tester) async {
      final file = _tempReviewFile('order_toggle.yaml');
      if (file.existsSync()) file.deleteSync();
      // `_handoffModel` has two roots, so switching documents rebuilds the
      // whole tree — the toggle must live above it, not inside it.
      final model = _handoffModel();
      await tester.pumpWidget(MaterialApp(
        home: StartPage(model: model, store: ReviewStore(file)),
      ));
      await tester.tap(find.text('Main').first);
      await tester.pumpAndSettle();
      expect(find.text(kSerializationOrderToggleLabel), findsOneWidget);

      // The toolbar's third switch is the serialization-order one; the two
      // before it are the hand-off cuts.
      Switch orderSwitch() =>
          tester.widget<Switch>(find.byType(Switch).at(2));
      expect(orderSwitch().value, isFalse);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();
      expect(orderSwitch().value, isTrue);

      await tester.tap(find.text('Other').first);
      await tester.pumpAndSettle();
      expect(orderSwitch().value, isTrue,
          reason: 'the toggle must survive a document switch');
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('Annotation coverage against the shipped model (TSRA5)', () {
    // The acceptance test for "every annotation present in spec_model.json is
    // reachable through the UI": rather than eyeballing the tree, enumerate the
    // snapshot's annotation names and require each to be accounted for by a
    // named renderer. A model that grows a new annotation fails here until a
    // decision is recorded about how to show it.
    final model = SpecModel.fromJson(
        json.decode(File('assets/spec_model.json').readAsStringSync())
            as Map<String, dynamic>);

    test('every annotation name in the snapshot has a renderer', () {
      final present = <String>{};
      for (final cls in model.classes.values) {
        present.addAll(cls.annotations.map((a) => a.name));
        for (final f in cls.fields) {
          present.addAll(f.annotations.map((a) => a.name));
        }
      }
      expect(present, isNotEmpty);
      expect(present.difference(kRenderedAnnotations), isEmpty,
          reason: 'unrendered annotations must be added to '
              'kRenderedAnnotations with a rendering');
    });

    testWidgets('a shipped document root shows no ordinals until asked',
        (tester) async {
      // The readability guarantee, stated against the real model rather than a
      // fixture: 4936 members carry an ordinal, and none of them may reach the
      // default view.
      final root = model.roots.first;
      Future<void> pump({required bool showOrder}) async {
        final file = _tempReviewFile('asset_order_$showOrder.yaml');
        if (file.existsSync()) file.deleteSync();
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SpecTree(
              model: model,
              root: root,
              store: ReviewStore(file),
              showSerializationOrder: showOrder,
              onHandoffTap: (_, _) {},
            ),
          ),
        ));
        await tester.pumpAndSettle();
        if (file.existsSync()) file.deleteSync();
      }

      await pump(showOrder: false);
      expect(find.textContaining(RegExp(r'^#\d+$')), findsNothing);
      await pump(showOrder: true);
      expect(find.textContaining(RegExp(r'^#\d+$')), findsWidgets);
    });

    testWidgets('a shipped section with provenance offers the references '
        'affordance', (tester) async {
      final cls = model.classes.values.firstWhere((c) =>
          c.standardReferences != null &&
          c.fields.any((f) => f.sectionIdPattern != null));
      final file = _tempReviewFile('asset_refs_${cls.name}.yaml');
      if (file.existsSync()) file.deleteSync();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: SpecRoot(type: cls.name, title: cls.name),
            store: ReviewStore(file),
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(kReferencesChipLabel), findsWidgets);
      // The pattern of the first patterned list field must be on screen next
      // to its own section id.
      final patterned =
          cls.fields.firstWhere((f) => f.sectionIdPattern != null);
      expect(find.text(patterned.sectionIdPattern!), findsOneWidget);
      expect(find.text(patterned.sectionId!), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('ModelStampBar (TSRA1)', () {
    // One day after the fixture's generatedAt — well inside the threshold.
    final fresh = DateTime.utc(2026, 7, 21, 8);
    // Sixty days after it — well outside.
    final longAfter = DateTime.utc(2026, 9, 18, 8);

    Future<File> pumpStart(
      WidgetTester tester, {
      required String name,
      required SpecModel model,
      DateTime? now,
    }) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      await tester.pumpWidget(MaterialApp(
        home: StartPage(model: model, store: ReviewStore(file), now: now),
      ));
      return file;
    }

    testWidgets('names the model, its export time and its size', (tester) async {
      final file = await pumpStart(tester,
          name: 'stamp_ok.yaml', model: _stampedModel(), now: fresh);

      expect(find.textContaining('Model 1.0'), findsOneWidget);
      expect(find.textContaining('(1.0.0+9)'), findsOneWidget);
      expect(find.textContaining('generated 2026-07-20 08:00 UTC'),
          findsOneWidget);
      expect(find.textContaining('1 day ago'), findsOneWidget);
      expect(find.textContaining('2 classes'), findsOneWidget);
      expect(find.textContaining('1 roots'), findsOneWidget);
      expect(find.textContaining('container DocSpecsProject'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a fresh, self-consistent snapshot raises no warning',
        (tester) async {
      final file = await pumpStart(tester,
          name: 'stamp_fresh.yaml', model: _stampedModel(), now: fresh);

      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('an artificially aged snapshot warns', (tester) async {
      final file = await pumpStart(tester,
          name: 'stamp_aged.yaml', model: _stampedModel(), now: longAfter);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('60 days old'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a snapshot edited after export warns about the count',
        (tester) async {
      // The exporter derives classCount from the payload, so a disagreement can
      // only mean the file was changed by hand afterwards.
      final file = await pumpStart(tester,
          name: 'stamp_edited.yaml',
          model: _stampedModel(classCount: 99),
          now: fresh);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
          find.textContaining('declares 99 classes but the snapshot carries 2'),
          findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a snapshot without the stamp keys still renders, degraded',
        (tester) async {
      final file = await pumpStart(tester,
          name: 'stamp_absent.yaml', model: _model(), now: longAfter);

      // No generatedAt means no age can be computed — and therefore no aged
      // warning, rather than a false alarm.
      expect(find.textContaining('generated: unknown'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('CodeSpecs-mapping feedback vocabulary (TSRA6)', () {
    test('the kind vocabulary is the canonical CodeSpecPart enum', () {
      expect(kCodeSpecPartTokens,
          {for (final part in CodeSpecPart.values) part.name});
      expect(kCodeSpecPartTokens, hasLength(28));
      // Deferred kinds are part of the vocabulary: a reviewer proposing one is
      // exactly the case that needs recording.
      expect(kCodeSpecPartTokens,
          containsAll(['workflow', 'notification', 'auditLog', 'reporting']));
    });

    test('normalization accepts both the bare and the prefixed token form', () {
      expect(normalizeCodeSpecKindToken('form'), 'form');
      expect(normalizeCodeSpecKindToken('CodeSpecPart.dataAccess'),
          'dataAccess');
      expect(normalizeCodeSpecKindToken('  serverApi  '), 'serverApi');
    });

    test('an invalid kind token is rejected at entry', () {
      expect(() => normalizeCodeSpecKindToken('formm'), throwsArgumentError);
      expect(() => ReviewEntry(suggestedCodeSpecKinds: const ['nope']),
          throwsArgumentError);
      final entry = ReviewEntry();
      expect(() => entry.suggestedCodeSpecKinds = ['form', 'bogus'],
          throwsArgumentError);
      expect(() => entry.toggleSuggestedCodeSpecKind('bogus'),
          throwsArgumentError);
      // A rejected assignment leaves the entry untouched.
      expect(entry.suggestedCodeSpecKinds, isEmpty);
    });

    test('the suggested-kind list cannot be mutated behind the validator', () {
      final entry = ReviewEntry(suggestedCodeSpecKinds: const ['form']);
      expect(() => entry.suggestedCodeSpecKinds.add('bogus'),
          throwsUnsupportedError);
    });

    test('toggling adds and removes a kind', () {
      final entry = ReviewEntry();
      entry.toggleSuggestedCodeSpecKind('form');
      entry.toggleSuggestedCodeSpecKind('CodeSpecPart.dataAccess');
      expect(entry.suggestedCodeSpecKinds, ['form', 'dataAccess']);
      entry.toggleSuggestedCodeSpecKind('form');
      expect(entry.suggestedCodeSpecKinds, ['dataAccess']);
    });

    test('the new fields round-trip through YAML', () {
      final file = _tempReviewFile('codespecs_feedback.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      store.update('DemoDoc/header', (e) {
        e.codeSpecKindMissing = true;
        e.codeSpecKindWrong = true;
        e.notCodeSpecs = true;
        e.suggestedCodeSpecKinds = ['form', 'validation'];
      });

      final reloaded = ReviewStore(file)..load();
      final entry = reloaded.entryFor('DemoDoc/header')!;
      expect(entry.codeSpecKindMissing, isTrue);
      expect(entry.codeSpecKindWrong, isTrue);
      expect(entry.notCodeSpecs, isTrue);
      expect(entry.suggestedCodeSpecKinds, ['form', 'validation']);
      file.deleteSync();
    });

    test('each new field alone keeps the entry non-empty', () {
      final file = _tempReviewFile('codespecs_nonempty.yaml');
      for (final mutate in <void Function(ReviewEntry)>[
        (e) => e.codeSpecKindMissing = true,
        (e) => e.codeSpecKindWrong = true,
        (e) => e.notCodeSpecs = true,
        (e) => e.suggestedCodeSpecKinds = ['form'],
      ]) {
        if (file.existsSync()) file.deleteSync();
        final store = ReviewStore(file)..update('p', mutate);
        expect(store.count, 1);
        // …and clearing it again removes the entry.
        store.update('p', (e) {
          e.codeSpecKindMissing = false;
          e.codeSpecKindWrong = false;
          e.notCodeSpecs = false;
          e.suggestedCodeSpecKinds = const [];
        });
        expect(store.count, 0);
      }
      if (file.existsSync()) file.deleteSync();
    });

    test('the store writes the bumped file version', () {
      final file = _tempReviewFile('codespecs_version.yaml');
      if (file.existsSync()) file.deleteSync();
      ReviewStore(file).update('p', (e) => e.notCodeSpecs = true);
      expect(file.readAsStringSync(), contains('version: $kReviewFileVersion'));
      expect(kReviewFileVersion, greaterThan(1));
      file.deleteSync();
    });

    test('a version-1 file still loads unchanged', () {
      final file = _tempReviewFile('codespecs_v1.yaml');
      file.writeAsStringSync('''
# TomSpecs structure review.
version: 1
entries:
  "DemoDoc/intro":
    scope: global
    add_details: true
    comment: "written by an earlier session"
''');
      final store = ReviewStore(file)..load();
      final entry = store.entryFor('DemoDoc/intro')!;
      expect(entry.scope, ReviewScope.global);
      expect(entry.addDetails, isTrue);
      expect(entry.comment, 'written by an earlier session');
      // The CodeSpecs axis is simply unset, not defaulted to a judgement.
      expect(entry.codeSpecKindMissing, isFalse);
      expect(entry.codeSpecKindWrong, isFalse);
      expect(entry.notCodeSpecs, isFalse);
      expect(entry.suggestedCodeSpecKinds, isEmpty);
      file.deleteSync();
    });

    test('a hand-edited file with a bad token drops it rather than failing',
        () {
      final file = _tempReviewFile('codespecs_badtoken.yaml');
      file.writeAsStringSync('''
version: 2
entries:
  "DemoDoc/intro":
    scope: none
    suggested_code_spec_kinds: ["form", "typo", "CodeSpecPart.validation"]
''');
      final store = ReviewStore(file)..load();
      expect(store.entryFor('DemoDoc/intro')!.suggestedCodeSpecKinds,
          ['form', 'validation']);
      file.deleteSync();
    });
  });

  group('CodeSpecs-mapping controls (TSRA6)', () {
    Future<File> pumpTree(WidgetTester tester, String name) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      final model = _model();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: model.roots.single,
            store: ReviewStore(file),
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return file;
    }

    testWidgets('the dialog offers the CodeSpecs axis on a class node',
        (tester) async {
      final file = await pumpTree(tester, 'controls_class.yaml');
      await tester.tap(find.byIcon(Icons.edit_note).first);
      await tester.pumpAndSettle();

      expect(find.text('CodeSpecs mapping'), findsOneWidget);
      // The axis lives in a collapsible section, collapsed while it is empty.
      await tester.ensureVisible(find.text(kCodeSpecsSectionLabel));
      await tester.tap(find.text(kCodeSpecsSectionLabel));
      await tester.pumpAndSettle();
      expect(find.text(kCodeSpecKindMissingLabel), findsOneWidget);
      expect(find.text(kCodeSpecKindWrongLabel), findsOneWidget);
      expect(find.text(kNotCodeSpecsLabel), findsOneWidget);
      expect(find.text(kSuggestedKindsLabel), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('the axis is reachable on a form-field node too',
        (tester) async {
      final file = await pumpTree(tester, 'controls_field.yaml');
      // The last edit control on screen belongs to a nested field row, not the
      // root class row.
      await tester.tap(find.byIcon(Icons.edit_note).last);
      await tester.pumpAndSettle();
      expect(find.text('CodeSpecs mapping'), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('checking a CodeSpecs flag persists it to the store',
        (tester) async {
      final file = await pumpTree(tester, 'controls_persist.yaml');
      await tester.tap(find.byIcon(Icons.edit_note).first);
      await tester.pumpAndSettle();

      // The CodeSpecs section sits below the fold of the scrollable dialog and
      // starts collapsed while it holds nothing.
      await tester.ensureVisible(find.text(kCodeSpecsSectionLabel));
      await tester.tap(find.text(kCodeSpecsSectionLabel));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(kCodeSpecKindMissingLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kCodeSpecKindMissingLabel));
      await tester.pumpAndSettle();

      // The root class row is keyed by the root class name.
      final reloaded = ReviewStore(file)..load();
      expect(reloaded.count, 1);
      expect(reloaded.entryFor('DemoDoc')!.codeSpecKindMissing, isTrue);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('Destination axis (TSRA7)', () {
    test('unset is distinct from neither', () {
      expect(ReviewDestination.unset, isNot(ReviewDestination.neither));
      // Unset means "no judgement recorded"; neither is a judgement.
      expect(ReviewEntry().destination, ReviewDestination.unset);
      expect(ReviewEntry().isEmpty, isTrue);
      expect(
          ReviewEntry(destination: ReviewDestination.neither).isEmpty, isFalse);
    });

    test('every destination round-trips through YAML', () {
      final file = _tempReviewFile('destination.yaml');
      for (final destination in ReviewDestination.values) {
        if (file.existsSync()) file.deleteSync();
        final store = ReviewStore(file)
          ..update('p', (e) => e.destination = destination);
        if (destination == ReviewDestination.unset) {
          // Nothing recorded, so nothing persisted.
          expect(store.count, 0);
          continue;
        }
        final reloaded = ReviewStore(file)..load();
        expect(reloaded.entryFor('p')!.destination, destination);
      }
      if (file.existsSync()) file.deleteSync();
    });

    test('an unreadable destination token degrades to unset', () {
      expect(ReviewDestination.parse('not_a_destination'),
          ReviewDestination.unset);
      expect(ReviewDestination.parse(null), ReviewDestination.unset);
    });
  });

  group('Follow-up feedback vocabulary (TSRA7)', () {
    test('the known vocabulary is the FollowUpProcess enum', () {
      expect(kFollowUpProcessTokens,
          {for (final process in FollowUpProcess.values) process.name});
      expect(kFollowUpProcessTokens, hasLength(9));
      expect(kFollowUpProcessTokens,
          containsAll(['doc', 'trn', 'org', 'ops', 'cap', 'cmp', 'mig',
            'l10n', 'acc']));
    });

    test('an unknown code is warned about, not rejected', () {
      // The taxonomy is explicitly extensible, so a reviewer proposing a new
      // code must be able to record it — unlike a CodeSpecPart typo.
      final entry = ReviewEntry(suggestedFollowUpKinds: const ['doc', 'sec']);
      expect(entry.suggestedFollowUpKinds, ['doc', 'sec']);
      expect(entry.unknownFollowUpKinds, ['sec']);
      expect(entry.hasUnknownFollowUpKind, isTrue);

      final known = ReviewEntry(suggestedFollowUpKinds: const ['doc']);
      expect(known.unknownFollowUpKinds, isEmpty);
      expect(known.hasUnknownFollowUpKind, isFalse);
    });

    test('tokens are normalised but a blank one is rejected', () {
      expect(normalizeFollowUpKindToken('  DOC '), 'doc');
      expect(normalizeFollowUpKindToken('FollowUpProcess.l10n'), 'l10n');
      expect(normalizeFollowUpKindToken('L10N'), 'l10n');
      expect(() => normalizeFollowUpKindToken('   '), throwsArgumentError);
      expect(() => ReviewEntry(suggestedFollowUpKinds: const ['']),
          throwsArgumentError);
    });

    test('toggling adds and removes, including an extension code', () {
      final entry = ReviewEntry();
      entry.toggleSuggestedFollowUpKind('doc');
      entry.toggleSuggestedFollowUpKind('sec');
      expect(entry.suggestedFollowUpKinds, ['doc', 'sec']);
      entry.toggleSuggestedFollowUpKind('DOC');
      expect(entry.suggestedFollowUpKinds, ['sec']);
    });

    test('the suggested list cannot be mutated behind the normaliser', () {
      final entry = ReviewEntry(suggestedFollowUpKinds: const ['doc']);
      expect(() => entry.suggestedFollowUpKinds.add('x'),
          throwsUnsupportedError);
    });

    test('an unknown code survives a YAML round-trip', () {
      final file = _tempReviewFile('followup_unknown.yaml');
      if (file.existsSync()) file.deleteSync();
      ReviewStore(file)
          .update('p', (e) => e.suggestedFollowUpKinds = ['mig', 'sec']);
      final reloaded = ReviewStore(file)..load();
      final entry = reloaded.entryFor('p')!;
      expect(entry.suggestedFollowUpKinds, ['mig', 'sec']);
      expect(entry.unknownFollowUpKinds, ['sec']);
      file.deleteSync();
    });
  });

  group('Structural feedback axes (TSRA7)', () {
    test('every new boolean axis round-trips through YAML', () {
      final file = _tempReviewFile('tsra7_flags.yaml');
      if (file.existsSync()) file.deleteSync();
      final store = ReviewStore(file);
      store.update('DemoDoc/items', (e) {
        e.followUpKindMissing = true;
        e.followUpKindWrong = true;
        e.shouldBeOneOf = true;
        e.caseSetIncomplete = true;
        e.idPatternWrong = true;
        e.handoffWrong = true;
        e.contentTypeWrong = true;
        e.standardRefWrong = true;
        e.standardRefMissing = true;
        e.unusedConfirmed = true;
        e.destination = ReviewDestination.both;
        e.suggestedFollowUpKinds = ['doc', 'ops'];
      });

      final entry = (ReviewStore(file)..load()).entryFor('DemoDoc/items')!;
      expect(entry.followUpKindMissing, isTrue);
      expect(entry.followUpKindWrong, isTrue);
      expect(entry.shouldBeOneOf, isTrue);
      expect(entry.caseSetIncomplete, isTrue);
      expect(entry.idPatternWrong, isTrue);
      expect(entry.handoffWrong, isTrue);
      expect(entry.contentTypeWrong, isTrue);
      expect(entry.standardRefWrong, isTrue);
      expect(entry.standardRefMissing, isTrue);
      expect(entry.unusedConfirmed, isTrue);
      expect(entry.unusedRejected, isFalse);
      expect(entry.destination, ReviewDestination.both);
      expect(entry.suggestedFollowUpKinds, ['doc', 'ops']);
      file.deleteSync();
    });

    test('each new axis alone keeps the entry non-empty', () {
      final file = _tempReviewFile('tsra7_nonempty.yaml');
      final mutations = <String, void Function(ReviewEntry)>{
        'followUpKindMissing': (e) => e.followUpKindMissing = true,
        'followUpKindWrong': (e) => e.followUpKindWrong = true,
        'shouldBeOneOf': (e) => e.shouldBeOneOf = true,
        'caseSetIncomplete': (e) => e.caseSetIncomplete = true,
        'idPatternWrong': (e) => e.idPatternWrong = true,
        'handoffWrong': (e) => e.handoffWrong = true,
        'contentTypeWrong': (e) => e.contentTypeWrong = true,
        'standardRefWrong': (e) => e.standardRefWrong = true,
        'standardRefMissing': (e) => e.standardRefMissing = true,
        'unusedConfirmed': (e) => e.unusedConfirmed = true,
        'unusedRejected': (e) => e.unusedRejected = true,
        'destination': (e) => e.destination = ReviewDestination.neither,
        'suggestedFollowUpKinds': (e) => e.suggestedFollowUpKinds = ['doc'],
      };
      mutations.forEach((name, mutate) {
        if (file.existsSync()) file.deleteSync();
        final store = ReviewStore(file)..update('p', mutate);
        expect(store.count, 1, reason: '$name should be persisted');
      });
      if (file.existsSync()) file.deleteSync();
    });

    test('the @Unused verdict is one decision, not two independent flags', () {
      final entry = ReviewEntry()..unusedConfirmed = true;
      entry.unusedRejected = true;
      expect(entry.unusedConfirmed, isFalse);
      expect(entry.unusedRejected, isTrue);
      entry.unusedConfirmed = true;
      expect(entry.unusedRejected, isFalse);

      // The invariant holds through a hand-edited file that states both.
      final loaded = ReviewEntry.fromMap(
          {'unused_confirmed': true, 'unused_rejected': true});
      expect(loaded.unusedConfirmed && loaded.unusedRejected, isFalse);
    });

    test('a version-1 file loads with every new axis unset', () {
      final file = _tempReviewFile('tsra7_v1.yaml');
      file.writeAsStringSync('''
version: 1
entries:
  "DemoDoc/intro":
    scope: global
    must_be_list: true
''');
      final entry = (ReviewStore(file)..load()).entryFor('DemoDoc/intro')!;
      expect(entry.scope, ReviewScope.global);
      expect(entry.mustBeList, isTrue);
      expect(entry.destination, ReviewDestination.unset);
      expect(entry.followUpKindMissing, isFalse);
      expect(entry.shouldBeOneOf, isFalse);
      expect(entry.idPatternWrong, isFalse);
      expect(entry.unusedConfirmed, isFalse);
      expect(entry.suggestedFollowUpKinds, isEmpty);
      file.deleteSync();
    });
  });

  group('TSRA7 controls', () {
    Future<File> pumpDialog(WidgetTester tester, String name,
        {void Function(ReviewEntry)? seed}) async {
      final file = _tempReviewFile(name);
      if (file.existsSync()) file.deleteSync();
      final model = _model();
      final store = ReviewStore(file);
      if (seed != null) store.update('DemoDoc', seed);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpecTree(
            model: model,
            root: model.roots.single,
            store: store,
            onHandoffTap: (_, _) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note).first);
      await tester.pumpAndSettle();
      return file;
    }

    testWidgets('the destination choice is offered without expanding anything',
        (tester) async {
      final file = await pumpDialog(tester, 'dest_visible.yaml');
      expect(find.text(kDestinationLabel), findsOneWidget);
      // Scoped to the destination group: scope and destination both offer an
      // "Undecided" option, and both are legitimately worded that way.
      final group = find.byKey(const ValueKey('destination-options'));
      expect(group, findsOneWidget);
      for (final destination in ReviewDestination.values) {
        expect(find.descendant(of: group, matching: find.text(destination.label)),
            findsOneWidget);
      }
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('every axis has a control once its section is expanded',
        (tester) async {
      final file = await pumpDialog(tester, 'all_axes.yaml');
      for (final section in [
        kStructureSectionLabel,
        kAnnotationsSectionLabel,
        kCodeSpecsSectionLabel,
        kFollowUpSectionLabel,
      ]) {
        await tester.ensureVisible(find.text(section));
        await tester.pumpAndSettle();
        await tester.tap(find.text(section));
        await tester.pumpAndSettle();
      }

      for (final label in [
        // Structure.
        kShouldBeOneOfLabel, kCaseSetIncompleteLabel,
        // Annotations.
        kIdPatternWrongLabel, kHandoffWrongLabel, kContentTypeWrongLabel,
        kStandardRefWrongLabel, kStandardRefMissingLabel,
        kUnusedConfirmedLabel, kUnusedRejectedLabel,
        // CodeSpecs (TSRA6, now sectioned).
        kCodeSpecKindMissingLabel, kCodeSpecKindWrongLabel, kNotCodeSpecsLabel,
        kSuggestedKindsLabel,
        // Follow-up.
        kFollowUpKindMissingLabel, kFollowUpKindWrongLabel,
        kSuggestedFollowUpKindsLabel,
      ]) {
        await tester.ensureVisible(find.text(label));
        expect(find.text(label), findsOneWidget, reason: 'missing: $label');
      }
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('a section that already carries feedback starts expanded',
        (tester) async {
      // Collapsing a section that holds a recorded judgement would hide it —
      // the one failure mode a collapsible dialog must not have.
      final file = await pumpDialog(tester, 'section_expanded.yaml',
          seed: (e) => e.idPatternWrong = true);
      await tester.ensureVisible(find.text(kIdPatternWrongLabel));
      expect(find.text(kIdPatternWrongLabel), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('an empty section starts collapsed', (tester) async {
      final file = await pumpDialog(tester, 'section_collapsed.yaml');
      expect(find.text(kIdPatternWrongLabel), findsNothing);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('checking a structural axis persists it', (tester) async {
      final file = await pumpDialog(tester, 'tsra7_persist.yaml');
      await tester.ensureVisible(find.text(kAnnotationsSectionLabel));
      await tester.tap(find.text(kAnnotationsSectionLabel));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(kHandoffWrongLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kHandoffWrongLabel));
      await tester.pumpAndSettle();

      final reloaded = ReviewStore(file)..load();
      expect(reloaded.entryFor('DemoDoc')!.handoffWrong, isTrue);
      if (file.existsSync()) file.deleteSync();
    });

    testWidgets('an unknown follow-up code is flagged in the summary',
        (tester) async {
      final file = await pumpDialog(tester, 'followup_warn.yaml',
          seed: (e) => e.suggestedFollowUpKinds = ['doc', 'sec']);
      // The dialog names the extension code as unrecognised rather than
      // silently accepting or dropping it.
      await tester.ensureVisible(find.text(kUnknownFollowUpWarning));
      expect(find.text(kUnknownFollowUpWarning), findsOneWidget);
      if (file.existsSync()) file.deleteSync();
    });
  });

  group('README snapshot baseline (TSRA8)', () {
    // The README documents the shipped snapshot's stamp so the next refresh
    // has something to diff against. A baseline nobody maintains is worse than
    // none, so these tests pin it to the asset: refreshing to a model of a
    // different size fails here until the README is updated with it.
    final readme = File('README.md').readAsStringSync();
    final stamp = json.decode(File('assets/spec_model.json').readAsStringSync())
        as Map<String, dynamic>;
    final model = SpecModel.fromJson(stamp);

    /// The value cell of the `| \`key\` | value |` row documenting [key].
    String? documented(String key) => RegExp('`$key`[^|]*\\|\\s*([^|]+?)\\s*\\|')
        .firstMatch(readme)
        ?.group(1);

    test('records the shipped class and root counts', () {
      expect(documented('classCount'), '${stamp['classCount']}');
      expect(documented('rootCount'), '${stamp['rootCount']}');
      expect(documented('containerRoot'), '`${stamp['containerRoot']}`');
    });

    test('the documented refresh command pins the shipped model version', () {
      // The refresh must re-export the model, never renumber it — so the
      // command in the README carries the version the asset already declares.
      expect(readme, contains('--model-version ${stamp['modelVersion']}'));
      expect(
          readme, contains('--model-label "${stamp['modelVersionLabel']}"'));
    });

    test('lists every document root the snapshot carries', () {
      for (final root in model.roots) {
        expect(readme, contains('| ${root.sectionId} | ${root.title} |'),
            reason: '${root.sectionId} is missing from the README root table');
      }
    });
  });
}
