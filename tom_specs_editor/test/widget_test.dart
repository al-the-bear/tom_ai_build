import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tom_specs_editor/src/model/review_store.dart';
import 'package:tom_specs_editor/src/model/spec_model.dart';
import 'package:tom_specs_editor/src/ui/start_page.dart';

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

File _tempReviewFile(String name) {
  final dir = Directory(
      '${Directory.current.path}/.dart_tool/specs_editor_test');
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
