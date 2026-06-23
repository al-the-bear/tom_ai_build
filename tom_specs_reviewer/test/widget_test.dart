import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_reviewer/src/model/review_store.dart';
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
  "classCount": 4,
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
}
