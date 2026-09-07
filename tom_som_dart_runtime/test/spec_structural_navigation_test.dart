/// The two structural-navigation rules both Flutter surfaces share.
///
/// `pathToType` and `isHandoffAway` were written out twice — once in
/// `tom_specs_reviewer`, once in `tom_forge/tom_specs_editor` — as byte-identical
/// copies inside each app's own `spec_tree.dart`. Neither is paint: one is a
/// breadth-first walk of the class graph, the other reads two model annotations.
/// Two apps computing "the path to this class" differently would disagree about
/// the document's own shape, which is why they belong beside the display
/// semantics rather than in either tree.
library;

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// A small graph: `Root → Mid → Leaf`, with `Root → Side` as a second branch
/// and `Orphan` reachable from nothing.
SpecModel _model() => SpecModel.fromJson({
  'modelVersion': 1,
  'roots': [
    {'type': 'Root', 'title': 'Root', 'sectionId': 'RT'},
  ],
  'classes': {
    'Root': {
      'name': 'Root',
      'fields': [
        {'name': 'mid', 'kind': 'complex', 'type': 'Mid'},
        {'name': 'side', 'kind': 'complex', 'type': 'Side'},
      ],
    },
    'Mid': {
      'name': 'Mid',
      'fields': [
        {'name': 'leaf', 'kind': 'complex', 'type': 'Leaf'},
      ],
    },
    // Reached both directly from Side and through Mid, so the walk has a
    // genuine choice to make and "shortest" is a claim rather than an accident.
    'Side': {
      'name': 'Side',
      'fields': [
        {'name': 'leaf', 'kind': 'complex', 'type': 'Leaf'},
      ],
    },
    'Leaf': {'name': 'Leaf', 'fields': <Object>[]},
    'Orphan': {'name': 'Orphan', 'fields': <Object>[]},
  },
});

SpecClass _classWith({String? detailedIn, String? mapsTo}) =>
    SpecClass.fromJson({
      'name': 'Section',
      'fields': <Object>[],
      if (detailedIn != null) 'detailedIn': detailedIn,
      if (mapsTo != null) 'mapsTo': mapsTo,
    });

void main() {
  group('pathToType', () {
    test('the root is its own path', () {
      expect(pathToType(_model(), 'Root', 'Root'), {'Root'});
    });

    test('returns every class on the chain, both ends included', () {
      expect(pathToType(_model(), 'Root', 'Leaf'), contains('Root'));
      expect(pathToType(_model(), 'Root', 'Leaf'), contains('Leaf'));
    });

    test('the chain is contiguous — every step is a real edge', () {
      // The set is what the tree auto-expands, so a gap would leave a closed
      // node between two open ones and the target unreachable on screen.
      final model = _model();
      final path = pathToType(model, 'Root', 'Leaf');
      expect(path.length, 3, reason: 'Root → (Mid|Side) → Leaf');
      expect(path, contains('Root'));
      expect(path, contains('Leaf'));
      final middle = path.difference({'Root', 'Leaf'}).single;
      expect(['Mid', 'Side'], contains(middle));
    });

    test('an unreachable target yields the empty set, not a partial path', () {
      expect(pathToType(_model(), 'Root', 'Orphan'), isEmpty);
    });

    test('a type the model does not declare yields the empty set', () {
      expect(pathToType(_model(), 'Root', 'NoSuchClass'), isEmpty);
    });

    test('a root the model does not declare yields the empty set', () {
      expect(pathToType(_model(), 'NoSuchRoot', 'Leaf'), isEmpty);
    });
  });

  group('isHandoffAway', () {
    test('a marker pointing at another document is a hand-off', () {
      expect(
        isHandoffAway(
          _classWith(detailedIn: 'D01'),
          'D00',
          cutAtDetails: true,
          cutAtMaps: true,
        ),
        isTrue,
      );
      expect(
        isHandoffAway(
          _classWith(mapsTo: 'D01'),
          'D00',
          cutAtDetails: true,
          cutAtMaps: true,
        ),
        isTrue,
      );
    });

    test('a marker pointing at THIS document is not a hand-off', () {
      // The whole point of the rule: a section detailed within the document
      // being read is not a hand-off, and cutting there would hide material
      // this document owns.
      expect(
        isHandoffAway(
          _classWith(detailedIn: 'D00'),
          'D00',
          cutAtDetails: true,
          cutAtMaps: true,
        ),
        isFalse,
      );
    });

    test('each switch governs only its own marker', () {
      final detail = _classWith(detailedIn: 'D01');
      final maps = _classWith(mapsTo: 'D01');
      expect(
        isHandoffAway(detail, 'D00', cutAtDetails: true, cutAtMaps: false),
        isTrue,
      );
      expect(
        isHandoffAway(detail, 'D00', cutAtDetails: false, cutAtMaps: true),
        isFalse,
        reason: 'the maps switch must not cut at a detail marker',
      );
      expect(
        isHandoffAway(maps, 'D00', cutAtDetails: true, cutAtMaps: false),
        isFalse,
        reason: 'the detail switch must not cut at a maps marker',
      );
      expect(
        isHandoffAway(maps, 'D00', cutAtDetails: false, cutAtMaps: true),
        isTrue,
      );
    });

    test('both switches off never cuts', () {
      expect(
        isHandoffAway(
          _classWith(detailedIn: 'D01', mapsTo: 'D02'),
          'D00',
          cutAtDetails: false,
          cutAtMaps: false,
        ),
        isFalse,
      );
    });

    test('an EMPTY marker is not a hand-off', () {
      // The one deliberate difference from the app code this replaced, which
      // tested `!= null` only. An empty marker names no document, so cutting
      // there would hide a section's subsections for no reason. Equivalent on
      // the real model — measured: 0 of the 134 marker-carrying classes hold
      // an empty one — so this is a guard, not a behaviour change.
      expect(
        isHandoffAway(
          _classWith(detailedIn: '', mapsTo: ''),
          'D00',
          cutAtDetails: true,
          cutAtMaps: true,
        ),
        isFalse,
      );
    });

    test('a class with no marker is never a hand-off', () {
      expect(
        isHandoffAway(_classWith(), 'D00', cutAtDetails: true, cutAtMaps: true),
        isFalse,
      );
    });
  });
}
