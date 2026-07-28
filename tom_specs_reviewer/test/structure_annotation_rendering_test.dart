// The reviewer's half of the cross-surface divergence guard.
//
// `tom_specs_reviewer` and `tom_forge/tom_specs_editor` share the annotation
// *readers* and the *display semantics* (`SpecChip` / `SpecRowExtras`, in
// `tom_som_dart_runtime`) but each owns its own *rendering*. Nothing in the type
// system stops one tree from quietly ceasing to show what the other shows, so
// both apps render `kAnnotationShowcaseJson` — a fixture covering every
// annotation in `kRenderedAnnotations` — and assert that every label the shared
// descriptors produce for it actually reaches the screen.
//
// The expectations are *derived from the shared descriptor functions*, never
// written out: a chip the display layer starts producing therefore fails here
// until this tree renders it. This file is the deliberate twin of
// `tom_specs_editor/test/structure_annotation_rendering_test.dart` — the two
// differ only in which tree they pump.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tom_som_dart_runtime/spec_display_fixture.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_reviewer/src/model/review_store.dart';
import 'package:tom_specs_reviewer/src/ui/spec_tree.dart';

/// Expands every collapsed node, so a chip cannot pass by being unreachable.
Future<void> _expandAll(WidgetTester tester) async {
  // Bounded rather than `while (true)`: a rendering bug that re-collapses a node
  // must fail the test, not hang the suite.
  for (var pass = 0; pass < 8; pass++) {
    final collapsed = find.byIcon(Icons.chevron_right);
    if (collapsed.evaluate().isEmpty) return;
    for (var i = collapsed.evaluate().length - 1; i >= 0; i--) {
      final target = find.byIcon(Icons.chevron_right);
      if (i >= target.evaluate().length) continue;
      await tester.tap(target.at(i), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  late Directory dir;
  late ReviewStore store;
  final model = SpecModel.fromJson(kAnnotationShowcaseJson());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('specs_reviewer_annotations_');
    store = ReviewStore(File('${dir.path}/review.yaml'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pumpTree(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpecTree(
          model: model,
          root: model.roots.single,
          store: store,
          showSerializationOrder: true,
          onHandoffTap: (_, _) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _expandAll(tester);
  }

  testWidgets('RAR1: every shared chip descriptor reaches the reviewer tree',
      (tester) async {
    await pumpTree(tester);

    final expected = expectedShowcaseChipLabels(model);
    expect(expected, isNotEmpty);
    final missing = [
      for (final label in expected)
        if (find.text(label).evaluate().isEmpty) label,
    ];
    expect(missing, isEmpty,
        reason: 'the shared display layer produces these chips but the '
            'reviewer tree does not render them');
  });

  testWidgets('RAR2: the non-chip row extras reach the reviewer tree',
      (tester) async {
    await pumpTree(tester);

    // `@Headline` — the authored section title, distinct from the member name.
    expect(find.text('“$kShowcaseHeadline”'), findsOneWidget);
    // `@Comment` — carries the `codespecs_mapping.md` §4.2 `locus:` grouping,
    // so it is structural.
    expect(find.text('← $kShowcaseComment'), findsOneWidget);
    // `@SectionIdPattern` — independent of `@SectionId`, never a fallback for
    // it: the list row must show both its own id and the per-item pattern.
    expect(find.text(kShowcaseSectionIdPattern), findsOneWidget);
    // `@SerializationOrder`, behind the toggle this tree was pumped with.
    expect(find.text('#$kShowcaseSerializationOrder'), findsOneWidget);
  });

  testWidgets('RAR3: the references panel opens on demand', (tester) async {
    await pumpTree(tester);

    // Closed by default — the standards are prose and would drown the tree.
    expect(find.text(kShowcaseConnotation), findsNothing);
    await tester.tap(find.text(referencesChip.label).first);
    await tester.pumpAndSettle();
    expect(find.text(kShowcaseConnotation), findsOneWidget);
    expect(find.text('• $kShowcaseStandard'), findsOneWidget);
    expect(find.text('→ references $kShowcaseReference'), findsOneWidget);
  });

  testWidgets('RAR4: a @SectionIdPattern list also shows its own section id',
      (tester) async {
    // The regression this pins: a tree that renders
    // `sectionId ?? sectionIdPattern` makes the pattern unreachable on every
    // list that carries both — and in the real model, all of them do.
    final doc = model.classNamed('ShowcaseDoc')!;
    final items = doc.fields.firstWhere((f) => f.name == 'items');
    expect(items.sectionIdPattern, isNotNull);

    await pumpTree(tester);
    expect(find.text(kShowcaseSectionIdPattern), findsOneWidget);
  });
}
