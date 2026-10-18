// `SpecDocument.hasValuesUnder` answers from a prefix index rather than a scan
// of every stored key. The markdown emitter, the validator and the query
// engine ask it once per model node, so a scan made rendering a large
// specification quadratic: about 300 s for the tom_uam Solution Blueprint.
//
// VI-1 holds the index to the scan it replaces, across every mutator, so a
// mutation that forgets to drop the index fails here. VI-2 guards the
// complexity itself.
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The predicate the index must reproduce: a stored key equal to the
/// (normalized) [query], or continuing it after a `/` or a `-`.
bool _scan(SpecDocument d, String query) {
  final prefix = d.pathNormalizer?.call(query) ?? query;
  final json = d.toJson();
  for (final store in const [
    'content',
    'forms',
    'lists',
    'headlines',
    'codeSpecs',
  ]) {
    for (final key in (json[store] as Map?)?.keys ?? const []) {
      final k = '$key';
      if (k == prefix || k.startsWith('$prefix/') || k.startsWith('$prefix-')) {
        return true;
      }
    }
  }
  return false;
}

const _probes = [
  'DEMO',
  'DEMO/TTL',
  'DEMO/TT',
  'DEMO/SUM',
  'DEMO/DET',
  'DEMO/items',
  'DEMO/items-1',
  'DEMO/items-1/label',
  'DEMO/items-2',
  'DEMO/items-3',
  'DEMO/REF-LST',
  'DEMO/REF',
  'DEMO/CARD-LST-1',
  'OTHER',
  '',
];

void _expectAgrees(SpecDocument d, String when) {
  for (final p in _probes) {
    expect(d.hasValuesUnder(p), _scan(d, p), reason: '$when: "$p"');
  }
}

void main() {
  test('VI-1: the index agrees with a full scan after every mutator', () {
    final d = SpecDocument();
    _expectAgrees(d, 'empty');
    d.setContent('DEMO/TTL', 'Hello');
    _expectAgrees(d, 'setContent');
    d.setHeadline('DEMO/SUM', 'Summary');
    _expectAgrees(d, 'setHeadline');
    d.setCodeSpec('DEMO/DET', 'a.b');
    _expectAgrees(d, 'setCodeSpec');
    d.setFormField('DEMO/CARD-LST-1/content', 'note', 'x');
    _expectAgrees(d, 'setFormField');
    final item = d.addListItem('DEMO/items');
    d.setContent('$item/label', 'First');
    d.addListItem('DEMO/items');
    _expectAgrees(d, 'addListItem');
    d.setItemSectionId(item, 'ITEM-A');
    _expectAgrees(d, 'setItemSectionId');
    d.setContent('DEMO/TTL', '');
    _expectAgrees(d, 'setContent to empty');
    d.setFormField('DEMO/CARD-LST-1/content', 'note', '');
    _expectAgrees(d, 'setFormField to empty');
    d.removeListItem(item);
    _expectAgrees(d, 'removeListItem');
    d.removeValuesUnder('DEMO/SUM');
    _expectAgrees(d, 'removeValuesUnder');

    final snapshot = d.captureState();
    d.setContent('OTHER/X', 'y');
    _expectAgrees(d, 'before restoreState');
    d.restoreState(snapshot);
    _expectAgrees(d, 'restoreState');

    d.loadJson({
      'content': {'DEMO/REF-LST-1': 'spec'},
      'lists': {
        'DEMO/REF-LST': {
          'seq': 1,
          'items': ['DEMO/REF-LST-1'],
        },
      },
    });
    _expectAgrees(d, 'loadJson');

    d.installPathNormalizer((p) => p.replaceAll('/REF-LST', '/REF'));
    _expectAgrees(d, 'installPathNormalizer');
  });

  test('VI-2: hasValuesUnder is not a scan of every stored key', () {
    // 20,000 stored values and 20,000 queries. A per-query scan costs
    // 4 * 10^8 key comparisons — tens of seconds; the index answers in
    // milliseconds. The bound is generous, so only the complexity class can
    // fail it.
    const n = 20000;
    final d = SpecDocument();
    for (var i = 0; i < n; i++) {
      d.setContent('ROOT/S${i ~/ 100}/F$i', 'v$i');
    }
    final watch = Stopwatch()..start();
    var hits = 0;
    for (var i = 0; i < n; i++) {
      if (d.hasValuesUnder('ROOT/S${i ~/ 100}/F$i')) hits++;
      if (d.hasValuesUnder('ROOT/S${i ~/ 100}/G$i')) hits--;
    }
    watch.stop();
    expect(hits, n);
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
