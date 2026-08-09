/// Every section class declares its own `content: String?`.
///
/// `tom_specs_model_rules.md` §5.2 makes the `content` override part of what a
/// section *is*: the prose between its headline and the next one, independent
/// of whichever form fields the class also carries. §5.4 grades a missing one
/// as an **error**, so `validator.dart` refuses to generate past it.
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

  test('the container root is genuinely exempt, not merely absent', () {
    final meta = jsonDecode(File(metaPath).readAsStringSync())
        as Map<String, dynamic>;
    final containerRoot = meta['containerRoot'] as String;
    final classes = meta['classes'] as Map<String, dynamic>;

    expect(classes, contains(containerRoot),
        reason: 'the exemption only means something if the root is present');
  });
}
