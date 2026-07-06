// Cross-language golden comparison (roadmap item 7b).
//
// Each `tom_som_<lang>_v0` golden generator writes a canonical reading of the
// shared sample to `tom_som_conformance/golden/<lang>.log` (see
// `tom_som_dart_v0/tool/golden_log.dart` for the reference format). This script
// asserts every language's log is **byte-identical** — the proof that all nine
// language APIs yield exactly the same reading of the same specification.
//
// It compares raw bytes (not decoded text) so a stray CR, BOM, or trailing-
// newline difference is caught. On a mismatch it reports the first differing
// line against the Dart reference and exits non-zero.
//
// Usage: dart tool/compare_golden.dart [goldenDir]
//   goldenDir defaults to ../golden relative to this script's package, i.e.
//   tom_som_conformance/golden.
library;

import 'dart:io';
import 'dart:typed_data';

/// The nine languages whose logs must all agree. Dart is the reference.
const _languages = <String>[
  'dart',
  'python',
  'java',
  'javascript',
  'typescript',
  'go',
  'rust',
  'c',
  'cpp',
];

void main(List<String> args) {
  final goldenDir = args.isNotEmpty ? args[0] : 'golden';

  final reference = File('$goldenDir/dart.log');
  if (!reference.existsSync()) {
    stderr.writeln('reference log missing: ${reference.path}');
    stderr.writeln('run the Dart generator first '
        '(dart run tool/golden_log.dart in tom_som_dart_v0).');
    exit(1);
  }
  final refBytes = reference.readAsBytesSync();
  final refLines = utf8Lines(refBytes);

  var failures = 0;
  var checked = 0;
  for (final lang in _languages) {
    if (lang == 'dart') continue; // reference compares against itself trivially
    final file = File('$goldenDir/$lang.log');
    if (!file.existsSync()) {
      stderr.writeln('MISSING  $lang.log — generator not run for $lang');
      failures++;
      continue;
    }
    checked++;
    final bytes = file.readAsBytesSync();
    if (bytesEqual(bytes, refBytes)) {
      stdout.writeln('OK       $lang.log  (${bytes.length} bytes) == dart.log');
      continue;
    }
    failures++;
    stderr.writeln('MISMATCH $lang.log differs from dart.log '
        '(${bytes.length} vs ${refBytes.length} bytes)');
    final lines = utf8Lines(bytes);
    final firstDiff = firstDifferingLine(refLines, lines);
    if (firstDiff >= 0) {
      final refLine = firstDiff < refLines.length ? refLines[firstDiff] : '<eof>';
      final gotLine = firstDiff < lines.length ? lines[firstDiff] : '<eof>';
      stderr.writeln('  first diff at line ${firstDiff + 1}:');
      stderr.writeln('    dart : $refLine');
      stderr.writeln('    $lang : $gotLine');
    }
  }

  if (failures > 0) {
    stderr.writeln('\nFAILED: $failures language log(s) differ from the '
        'Dart reference.');
    exit(1);
  }
  stdout.writeln('\nPASSED: all $checked language logs are byte-identical to '
      'dart.log.');
}

bool bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Splits raw bytes into UTF-8 lines (for diagnostics only — equality is on
/// raw bytes).
List<String> utf8Lines(Uint8List bytes) {
  final text = String.fromCharCodes(bytes);
  final lines = text.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  return lines;
}

int firstDifferingLine(List<String> a, List<String> b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    if (a[i] != b[i]) return i;
  }
  if (a.length != b.length) return n;
  return -1;
}
