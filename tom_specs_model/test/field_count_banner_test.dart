/// The `// <Name> (N fields)` group banners must agree with the `@Form` they
/// head.
///
/// The banners are the first thing an author reads when judging whether a band
/// needs decomposing under `tom_specs_model_rules.md` §6.3 — "is this section
/// carrying too much?" is answered by the count before it is answered by
/// reading the fields. A wrong count sends that judgement the wrong way, and
/// because they are `//` comments nothing reaches the meta and nothing ever
/// contradicted them.
///
/// Twelve of the thirty-seven had drifted when this was written, up to a factor
/// of two (`Constraints and Validation` claimed 8 and had 4). Correcting them
/// was a snapshot; this test is what makes the correction hold, and it is the
/// reason the count is worth keeping at all rather than deleting. A comment
/// nothing checks decays back to wrong.
library;

import 'dart:io';

import 'package:test/test.dart';

/// `// Some Name (4 fields)`, optionally followed by ` — a trailing clause`.
///
/// Anchored at both ends so prose that merely mentions a count — the doc
/// comment reading `**Per Relationship (29 fields):**` — is not mistaken for a
/// banner. The trailing-clause branch is not decoration: one real banner
/// carries one, and a pattern without it silently skipped that banner rather
/// than failing on it, which is the failure mode a checker must not have.
final RegExp _banner = RegExp(r'^\s*// (.+?) \((\d+) fields?\)(\s+—.*)?$');

/// One banner and what it claims.
class _Banner {
  _Banner(this.file, this.line, this.name, this.claimed, this.actual);

  final String file;
  final int line;
  final String name;
  final int claimed;
  final int actual;

  @override
  String toString() =>
      '$file:$line  "$name" claims $claimed, the @Form below it has $actual';
}

/// Counts `Field(` entries inside the `@Form([...])` that follows [from].
///
/// Scans forward to the first `@Form([` and consumes to its balanced close.
/// Returns `null` when no `@Form` follows, which is itself a finding: a banner
/// that heads nothing counts nothing.
int? _formFieldCountAfter(List<String> lines, int from) {
  var i = from;
  while (i < lines.length && !lines[i].contains('@Form([')) {
    i++;
  }
  if (i >= lines.length) return null;

  var depth = 0;
  var count = 0;
  for (var k = i; k < lines.length; k++) {
    count += RegExp(r'\bField\(').allMatches(lines[k]).length;
    for (final ch in lines[k].split('')) {
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
      }
    }
    if (depth <= 0) return count;
  }
  return count;
}

void main() {
  test('every `(N fields)` banner matches the @Form it heads', () {
    // Joined by hand rather than through `package:path`: `tom_specs_model` is
    // a release-set package, and adding a dependency for a test would widen
    // the closure `check_release_closure.dart` holds.
    final root = Directory.current.path;
    final libSrc = Directory('$root/lib/src');
    expect(
      libSrc.existsSync(),
      isTrue,
      reason: 'run from the tom_specs_model package root',
    );

    final drifted = <_Banner>[];
    var checked = 0;

    for (final entity in libSrc.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.startsWith('$root/')
          ? entity.path.substring(root.length + 1)
          : entity.path;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final m = _banner.firstMatch(lines[i]);
        if (m == null) continue;
        checked++;
        final claimed = int.parse(m.group(2)!);
        final actual = _formFieldCountAfter(lines, i) ?? 0;
        if (actual != claimed) {
          drifted.add(_Banner(rel, i + 1, m.group(1)!, claimed, actual));
        }
      }
    }

    // Anti-vacuity: a regex that stopped matching would make this test pass by
    // checking nothing, which is the one outcome a hygiene gate must not have.
    expect(
      checked,
      greaterThanOrEqualTo(30),
      reason:
          'the banner pattern matched only $checked banners — it has stopped '
          'recognising them, so this test is passing without checking',
    );

    expect(
      drifted.map((b) => b.toString()),
      isEmpty,
      reason:
          'correct the count, or drop the banner. The count exists to answer '
          '"is this band too large?" (tom_specs_model_rules.md §6.3) before a '
          'reader counts by hand, so a wrong one is worse than none.',
    );
  });
}
