/// Every section class declares its own `content: String?`, and documents it.
///
/// `tom_specs_model_rules.md` §5.2 makes the `content` override part of what a
/// section *is*: the prose between its headline and the next one, independent
/// of whichever form fields the class also carries. §5.4 grades a missing one
/// as an **error**, so `validator.dart` refuses to generate past it — and
/// grades an *undocumented* one the same way (§5.6).
///
/// This test is the second net. The validator guards the path from model source
/// to meta; this guards the committed meta itself, so a hand-edited artifact or
/// a generator regression surfaces in the default `dart test` run rather than
/// at the next regeneration.
///
/// The single exemption is the container root (T1) — a structural tree node,
/// not a section, so it owns no body text.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final metaPath = p.normalize(p.join(Directory.current.path, '..',
      'tom_som_dart_v0', 'meta', 'spec_model.meta.json'));

  test('every class in the meta declares content, except the container root',
      () {
    final meta = jsonDecode(File(metaPath).readAsStringSync())
        as Map<String, dynamic>;
    final containerRoot = meta['containerRoot'] as String;
    final classes = meta['classes'] as Map<String, dynamic>;

    final missing = <String>[];
    for (final entry in classes.entries) {
      if (entry.key == containerRoot) continue;
      final fields = (entry.value as Map<String, dynamic>)['fields'] as List?;
      final hasContent = (fields ?? const []).any(
          (f) => (f as Map<String, dynamic>)['name'] == 'content');
      if (!hasContent) missing.add(entry.key);
    }

    expect(missing, isEmpty,
        reason: '${missing.length} class(es) lack the `content: String?` '
            'override required by tom_specs_model_rules.md §5.2');
  });

  test('every content field carries one of the four §5.6 annotations', () {
    // The annotation is what a spec author reads beside the input, so an
    // undocumented `content` is a section whose only guidance is its headline.
    // A class-level `@Form` does not count: it documents the form fields, not
    // the prose wrapped around them.
    const documenting = {'ContentHelp', 'ContentType', 'Form', 'Unused'};

    final meta = jsonDecode(File(metaPath).readAsStringSync())
        as Map<String, dynamic>;
    final containerRoot = meta['containerRoot'] as String;
    final classes = meta['classes'] as Map<String, dynamic>;

    final undocumented = <String>[];
    for (final entry in classes.entries) {
      if (entry.key == containerRoot) continue;
      final fields = ((entry.value as Map<String, dynamic>)['fields'] as List?)
          ?.cast<Map<String, dynamic>>();
      final content =
          (fields ?? const []).where((f) => f['name'] == 'content').firstOrNull;
      if (content == null) continue; // covered by the test above
      final names = ((content['annotations'] as List?) ?? const [])
          .map((a) => (a as Map<String, dynamic>)['name'] as String)
          .toSet();
      if (names.intersection(documenting).isEmpty) undocumented.add(entry.key);
    }

    expect(undocumented, isEmpty,
        reason: '${undocumented.length} class(es) have an undocumented '
            '`content` field (tom_specs_model_rules.md §5.6)');
  });

  test('the container root is genuinely exempt, not merely absent', () {
    final meta = jsonDecode(File(metaPath).readAsStringSync())
        as Map<String, dynamic>;
    final containerRoot = meta['containerRoot'] as String;
    final classes = meta['classes'] as Map<String, dynamic>;

    expect(classes, contains(containerRoot),
        reason: 'the exemption only means something if the root is present');
  });
}
