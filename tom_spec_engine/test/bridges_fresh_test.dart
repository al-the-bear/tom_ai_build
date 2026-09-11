// The committed `*.b.dart` files must match what the generator produces from
// this package's own `buildkit.yaml`.
//
// Nothing regenerates them during `dart test`: they change only when somebody
// regenerates them. Without this check, a generator change or a source change
// that was not followed by a regeneration leaves the rest of the suite green
// and testing stale generated code. The check regenerates into a scratch tree
// under `.dart_tool/` and never writes to the package.
//
// It complements test/som_bridge_freshness_test.dart, which fingerprints the
// SOM surface but cannot see the other input, the generator itself. See
// _copilot_guidelines/bridge_regeneration.md, "How staleness is caught".
//
// When it fails: run `dart run tool/regenerate_bridges.dart` and commit what it
// changes, stamp included.

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_d4rt_generator/tom_d4rt_generator.dart';

void main() {
  test('BRIDGE-FRESH-01: the committed bridges match the generator '
      '[2026-09-11] (PASS)', () async {
    final freshness = await checkBridgeFreshness(Directory.current.path);
    expect(freshness.errors, isEmpty, reason: 'generation failed');
    expect(
      freshness.checked,
      isNotEmpty,
      reason: 'the generator produced nothing, so nothing was compared',
    );
    expect(
      freshness.stale,
      isEmpty,
      reason:
          'run tool/regenerate_bridges.dart and commit:\n  '
          '${freshness.stale.join('\n  ')}',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
