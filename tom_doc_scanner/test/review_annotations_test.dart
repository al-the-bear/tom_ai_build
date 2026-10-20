import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';

/// Review annotations (SOM §11.9) are text of the section they sit in: they
/// never start a section, and the scanner hands them to its caller verbatim.
void main() {
  final fixture = '${Directory.current.path}/test/fixtures/annotated_form.md';

  test('RAN-1: annotation blocks start no section and stay in the text', () {
    final doc = DocScanner.scanDocumentSync(filepath: fixture);
    final ids = [for (final s in doc.sections ?? const []) s.id];
    expect(ids, ['DET', 'SUM']);
    final det = doc.sections!.first;
    expect(det.text, contains('> **❓ BQ-83 — Owner:** who owns it?'));
    expect(det.text, contains('> # not a heading inside the block'));
    expect(det.text, contains('Owner: Bob {== here ==}{>> really? <<}'));
    expect(det.sections ?? const [], isEmpty);
  });
}
