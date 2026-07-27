import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
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
}
