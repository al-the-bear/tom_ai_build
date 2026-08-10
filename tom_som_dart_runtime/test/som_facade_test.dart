import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A tiny hand-written facade subclass to exercise the [SomNode] base and the
/// list/scalar wrappers the generated code relies on.
class _Root extends SomNode {
  _Root(super.doc, super.path);

  String get title => doc.content('$path/title') ?? '';
  set title(String v) => doc.setContent('$path/title', v);

  SomList<_Item> get items =>
      SomList<_Item>(doc, '$path/items', (d, p) => _Item(d, p));

  SomList<SomScalar> get tags =>
      SomList<SomScalar>(doc, '$path/tags', (d, p) => SomScalar(d, p));

  /// A pattern-bearing list — mirrors what the emitter generates for a field
  /// carrying a `@SectionIdPattern`.
  SomList<_Item> get risks => SomList<_Item>(
        doc,
        '$path/RISK',
        (d, p) => _Item(d, p),
        pattern: 'RISK-ITEM-xxx',
      );

  /// A content-only element list (the operational-metrics shape) whose element
  /// carries only the standard `content` leaf — exercises [SomList.addContent]
  /// and [SomList.contents] (SOM §21).
  SomList<_Metric> get metrics => SomList<_Metric>(
        doc,
        '$path/METR',
        (d, p) => _Metric(d, p),
        pattern: 'METR-ITEM-xxx',
      );
}

class _Item extends SomNode {
  _Item(super.doc, super.path);

  String get label => doc.content('$path/label') ?? '';
  set label(String v) => doc.setContent('$path/label', v);
}

/// A content-only element facade: its only field is the standard `content`
/// leaf, matching the generated content-element shape (e.g.
/// `CurrentOperationalMetric`).
class _Metric extends SomNode {
  _Metric(super.doc, super.path);

  String get content => doc.content('$path/content') ?? '';
  set content(String v) => doc.setContent('$path/content', v);

  /// A content-bearing section overrides the structural default (SOM §21).
  @override
  bool get canHaveContent => true;
}

/// A node facade that declares no `content` leaf, so it does **not** override
/// [SomNode.canHaveContent] and inherits the `false` default. In the generated
/// facades this shape is a non-section node (a scalar list item): every
/// *section* class carries `content` per `tom_specs_model_rules.md` §10.2.
class _LeaflessNode extends SomNode {
  _LeaflessNode(super.doc, super.path);

  _Item get child => _Item(doc, '$path/child');
}

void main() {
  group('SomNode', () {
    test('holds the document and its path', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      expect(root.doc, same(doc));
      expect(root.path, 'PD00');
    });

    test('a typed leaf mutation is visible through the generic path', () {
      final doc = SpecDocument();
      _Root(doc, 'PD00').title = 'Hello';
      expect(doc.content('PD00/title'), 'Hello');
    });

    test('a generic mutation is visible through the typed leaf', () {
      final doc = SpecDocument();
      doc.setContent('PD00/title', 'World');
      expect(_Root(doc, 'PD00').title, 'World');
    });
  });

  group(r'SomNode.$codeSpec (codespecs_mapping.md §9.2 forward link)', () {
    test('unset on a fresh node — the store is sparse like the headline', () {
      final doc = SpecDocument();
      expect(_Root(doc, 'PD00').$codeSpec, isNull);
    });

    test('a typed write is visible through the generic path', () {
      final doc = SpecDocument();
      _Root(doc, 'PD00').$codeSpec = 'CsOrder,CsOrderRepository';
      expect(doc.codeSpec('PD00'), 'CsOrder,CsOrderRepository');
    });

    test('a generic write is visible through the typed accessor', () {
      final doc = SpecDocument();
      doc.setCodeSpec('PD00', 'CsOrder');
      expect(_Root(doc, 'PD00').$codeSpec, 'CsOrder');
    });

    test('null and the empty string both clear the mapping', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.$codeSpec = 'CsOrder';
      root.$codeSpec = null;
      expect(root.$codeSpec, isNull);
      expect(doc.codeSpecPaths, isEmpty);

      root.$codeSpec = 'CsOrder';
      root.$codeSpec = '';
      expect(root.$codeSpec, isNull);
      expect(doc.codeSpecPaths, isEmpty);
    });

    test('it is keyed by path, so it is available on any node', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.risks.add(date: DateTime(2026, 1, 2));
      item.$codeSpec = 'CsOrder.captureFromEdi';
      expect(item.$codeSpec, 'CsOrder.captureFromEdi');
      expect(doc.codeSpec(item.path), 'CsOrder.captureFromEdi');
      // Independent of the node's own section id and of the parent's link.
      expect(item.$sectionId, 'RISK-ITEM-AB1');
      expect(root.$codeSpec, isNull);
    });
  });

  group('SomList', () {
    test('add appends an item reachable both ways', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.items.add();
      item.label = 'first';
      expect(root.items.length, 1);
      expect(root.items[0].label, 'first');
      // Visible through the generic document.
      expect(doc.listItemCount('PD00/items'), 1);
      expect(doc.content('${doc.listItems('PD00/items').single}/label'),
          'first');
    });

    test('removeAt drops the item and its nested values', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.items.add().label = 'a';
      root.items.add().label = 'b';
      expect(root.items.length, 2);
      root.items.removeAt(0);
      expect(root.items.length, 1);
      expect(root.items[0].label, 'b');
    });

    test('scalar list items carry a string value', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.tags.add().value = 'x';
      expect(root.tags[0].value, 'x');
      expect(doc.listItemCount('PD00/tags'), 1);
    });
  });

  group('SomList section ids (AA1 criteria 3–6)', () {
    final date = DateTime(2026, 1, 2); // AB

    test('add generates a section id from the pattern (criteria 3, 4)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.risks.add(date: date);
      expect(item.$sectionId, 'RISK-ITEM-AB1');
      // Visible both ways.
      expect(doc.itemSectionId(item.path), 'RISK-ITEM-AB1');
    });

    test('add accepts a section-id override, validated unique (criterion 5)',
        () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.risks.add(sectionId: 'RISK-ITEM-CUSTOM');
      expect(root.risks.sectionIds, ['RISK-ITEM-CUSTOM']);
      expect(
        () => root.risks.add(sectionId: 'RISK-ITEM-CUSTOM'),
        throwsA(isA<SpecSectionIdCollision>()),
      );
    });

    test(r'overriding an item id via SomNode.$sectionId (criterion 5)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final item = root.risks.add(date: date);
      item.$sectionId = 'RISK-ITEM-OVR';
      expect(root.risks.sectionIds, ['RISK-ITEM-OVR']);
    });

    test('delete-last then same-day add reuses the freed id (criterion 6)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.risks.add(date: date); // AB1
      root.risks.add(date: date); // AB2
      root.risks.removeAt(1); // delete last
      final reused = root.risks.add(date: date);
      expect(reused.$sectionId, 'RISK-ITEM-AB2');
    });

    test('delete-middle keeps ids, numbering non-consecutive (criterion 6)', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.risks.add(date: date); // AB1
      root.risks.add(date: date); // AB2
      root.risks.add(date: date); // AB3
      root.risks.removeAt(1); // delete AB2
      expect(root.risks.sectionIds, ['RISK-ITEM-AB1', 'RISK-ITEM-AB3']);
      final next = root.risks.add(date: date);
      expect(next.$sectionId, 'RISK-ITEM-AB4');
    });
  });

  group('SomList content-only convenience (SOM §21)', () {
    final date = DateTime(2026, 1, 2); // AB

    test('addContent appends the item and sets its content leaf in one call',
        () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final metric = root.metrics.addContent('99.9% uptime', date: date);
      // Returns the element facade, content readable both ways.
      expect(metric.content, '99.9% uptime');
      expect(root.metrics.length, 1);
      expect(root.metrics[0].content, '99.9% uptime');
      expect(doc.content('${metric.path}/content'), '99.9% uptime');
    });

    test('addContent honours the section-id pattern like add', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      final m = root.metrics.addContent('x', date: date);
      expect(m.$sectionId, 'METR-ITEM-AB1');
    });

    test('addContent accepts a section-id override', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.metrics.addContent('x', sectionId: 'METR-ITEM-CUSTOM');
      expect(root.metrics.sectionIds, ['METR-ITEM-CUSTOM']);
    });

    test('contents yields every item content leaf in order', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.metrics.addContent('first', date: date);
      root.metrics.addContent('second', date: date);
      root.metrics.addContent('third', date: date);
      expect(root.metrics.contents.toList(), ['first', 'second', 'third']);
    });

    test('contents coalesces a missing content leaf to the empty string', () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.metrics.add(date: date); // no content written
      root.metrics.addContent('has', date: date);
      expect(root.metrics.contents.toList(), ['', 'has']);
    });

    test('contents parity: contents == items mapped through the typed getter',
        () {
      final doc = SpecDocument();
      final root = _Root(doc, 'PD00');
      root.metrics.addContent('a', date: date);
      root.metrics.addContent('b', date: date);
      expect(root.metrics.contents.toList(),
          root.metrics.items.map((m) => m.content).toList());
    });
  });

  group('canHaveContent (structural content-slot predicate, SOM §21)', () {
    test('the SomNode base defaults to false (no `content` leaf)', () {
      final doc = SpecDocument();
      expect(_LeaflessNode(doc, 'PD00').canHaveContent, isFalse);
    });

    test('a content-bearing section overrides it to true', () {
      final doc = SpecDocument();
      expect(_Metric(doc, 'PD00/METR-ITEM-AB1').canHaveContent, isTrue);
    });

    test('a scalar list item inherits the false default', () {
      final doc = SpecDocument();
      expect(SomScalar(doc, 'PD00/tags-1').canHaveContent, isFalse);
    });

    test('it is structural, not state — independent of any stored value', () {
      final doc = SpecDocument();
      final leafless = _LeaflessNode(doc, 'PD00');
      final metric = _Metric(doc, 'PD00/METR-ITEM-AB1');
      // Empty vs filled makes no difference to the schema-level answer.
      expect(leafless.canHaveContent, isFalse);
      expect(metric.canHaveContent, isTrue);
      metric.content = 'filled';
      expect(metric.canHaveContent, isTrue);
      expect(leafless.canHaveContent, isFalse);
    });
  });

  group('checkSomModelVersion', () {
    test('a null/empty document stamp is always accepted', () {
      expect(() => checkSomModelVersion('0.0', null), returnsNormally);
      expect(() => checkSomModelVersion('0.0', ''), returnsNormally);
    });

    test('an older or equal same-major document is editable', () {
      expect(() => checkSomModelVersion('1.3', '1.0'), returnsNormally);
      expect(() => checkSomModelVersion('1.3', '1.3'), returnsNormally);
    });

    test('a newer same-major document is rejected', () {
      expect(() => checkSomModelVersion('1.2', '1.5'),
          throwsA(isA<SomVersionException>()));
    });

    test('a different major version is rejected', () {
      expect(() => checkSomModelVersion('1.0', '2.0'),
          throwsA(isA<SomVersionException>()));
      expect(() => checkSomModelVersion('1.0', '0.9'),
          throwsA(isA<SomVersionException>()));
    });

    test('an unparseable document stamp is rejected', () {
      expect(() => checkSomModelVersion('1.0', 'not-a-version'),
          throwsA(isA<SomVersionException>()));
    });
  });

  group('somEditabilityFor (non-throwing SOM §4.2 classification)', () {
    test('a null/empty document stamp is editable', () {
      expect(somEditabilityFor('0.0', null), SomEditability.editable);
      expect(somEditabilityFor('0.0', ''), SomEditability.editable);
    });

    test('an older or equal same-major document is editable', () {
      expect(somEditabilityFor('1.3', '1.0'), SomEditability.editable);
      expect(somEditabilityFor('1.3', '1.3'), SomEditability.editable);
    });

    test('a newer same-major document is rejectedNewerMinor', () {
      expect(somEditabilityFor('1.2', '1.5'),
          SomEditability.rejectedNewerMinor);
    });

    test('a different major version is readOnlyCrossMajor', () {
      expect(somEditabilityFor('1.0', '2.0'),
          SomEditability.readOnlyCrossMajor);
      expect(somEditabilityFor('1.0', '0.9'),
          SomEditability.readOnlyCrossMajor);
    });

    test('an unparseable document stamp is invalidVersion', () {
      expect(somEditabilityFor('1.0', 'not-a-version'),
          SomEditability.invalidVersion);
    });

    test('never throws where checkSomModelVersion would throw', () {
      for (final stamp in ['1.5', '2.0', '0.9', 'not-a-version']) {
        expect(() => somEditabilityFor('1.0', stamp), returnsNormally);
        expect(() => checkSomModelVersion('1.0', stamp),
            throwsA(isA<SomVersionException>()));
      }
    });

    test('classification agrees with the throwing checker', () {
      for (final stamp in [null, '', '1.0', '0.5', '1.5', '2.0', 'bad']) {
        final editable =
            somEditabilityFor('1.0', stamp) == SomEditability.editable;
        var threw = false;
        try {
          checkSomModelVersion('1.0', stamp);
        } on SomVersionException {
          threw = true;
        }
        expect(editable, !threw,
            reason: 'stamp "$stamp": editable=$editable threw=$threw');
      }
    });
  });
}
