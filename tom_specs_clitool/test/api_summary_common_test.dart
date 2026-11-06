/// Holds `tom_specs_model/doc/api/api_summary_common.md` to the common module
/// it documents.
///
/// The page is hand-written, so nothing regenerates it when an enum or a class
/// is added to `lib/src/common/` or removed from it. It has drifted both ways:
/// it once documented 7 of the module's 19 enums, and went on documenting a
/// `SectionType` enum for weeks after the model deleted it. This test reads the
/// declarations from the source and the `###` sections from the page and
/// requires the two sets, and the counts the page's overview states, to agree.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  // tom_specs_model sits beside tom_specs_clitool; `dart test` runs from the
  // package root.
  final modelRoot = p.normalize(
    p.join(Directory.current.path, '..', 'tom_specs_model'),
  );
  final commonDir = Directory(p.join(modelRoot, 'lib', 'src', 'common'));
  final page = File(
    p.join(modelRoot, 'doc', 'api', 'api_summary_common.md'),
  ).readAsStringSync();

  final enumPattern = RegExp(r'^enum (\w+)\b', multiLine: true);
  final classPattern = RegExp(
    r'^(?:abstract |sealed |final |base )*class ([A-Z]\w*)\b',
    multiLine: true,
  );

  final sources = commonDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('common.dart'))
      .map((f) => f.readAsStringSync())
      .toList();
  final enums = {
    for (final s in sources) ...enumPattern.allMatches(s).map((m) => m[1]!),
  };
  final classes = {
    for (final s in sources) ...classPattern.allMatches(s).map((m) => m[1]!),
  };
  final sections = {
    for (final m in RegExp(r'^### (\w+)$', multiLine: true).allMatches(page))
      m[1]!,
  };

  test('the source scan found the module', () {
    // Guards against a moved folder making every assertion below vacuous.
    expect(enums, isNotEmpty);
    expect(classes, isNotEmpty);
  });

  test('every enum and class of the common module has a section', () {
    expect(
      {...enums, ...classes}.difference(sections),
      isEmpty,
      reason: 'declared in lib/src/common/ but not documented on the page',
    );
  });

  test('the page documents nothing the module does not declare', () {
    expect(
      sections.difference({...enums, ...classes}),
      isEmpty,
      reason: 'a section names a declaration lib/src/common/ no longer has',
    );
  });

  test("the overview's counts are the module's", () {
    final overview = RegExp(
      r'declares \*\*(\d+) classes\*\* and \*\*(\d+) enums\*\*',
    ).firstMatch(page);
    expect(overview, isNotNull, reason: 'the overview count sentence is gone');
    expect(int.parse(overview![1]!), classes.length, reason: 'class count');
    expect(int.parse(overview[2]!), enums.length, reason: 'enum count');
  });
}
