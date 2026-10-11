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
    // SCE30 / scf12: a committed generated file no run writes any more is
    // invisible to the stale comparison above, which only looks at what a run
    // produces; it can only rot, or be hand-edited in the belief that a
    // regeneration will keep the edit. And an empty list from a scan that
    // never ran would read as a clean package, so that is asserted first.
    expect(
      freshness.orphanScanSkipped,
      isNull,
      reason: 'the orphan scan did not run, so its result means nothing',
    );
    expect(
      freshness.orphaned,
      isEmpty,
      reason:
          'committed generated files that no run writes. d4rtgen never '
          'deletes them; decide and remove by hand:\n  '
          '${freshness.orphaned.join('\n  ')}',
    );
    // The budget is wall-clock, not part of the claim: the assertions above are
    // what the test holds. It is sized from a measurement, because the work is a
    // full regeneration into a scratch tree. Since tom_d4rt_generator 1.51 emits
    // formatted output the SOM bridges run to ~973k lines, and on mbp the test
    // alone took 5m39s (2026-10-11). Inside the full suite, sharing the CPU with
    // the memory-tier tests, it overran the old 10-minute budget and timed out
    // without ever reaching a comparison — a red that said nothing about the
    // bridges. Twenty minutes is ~3.5x the uncontended run.
  }, timeout: const Timeout(Duration(minutes: 20)));
}
