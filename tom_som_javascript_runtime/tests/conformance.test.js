'use strict';

/**
 * `node --test` harness wrapping the shared-corpus conformance runner.
 *
 * The canonical conformance check is the plain `conformance_runner.js` script
 * (mirroring the Python/Java runners, which print "OK: N checks passed" and exit
 * 0/1 for cross-language symmetry). This thin wrapper exposes the same run under
 * Node's built-in test runner so `node --test` is also green.
 */

const { test } = require('node:test');
const assert = require('node:assert');

const { main } = require('./conformance_runner');

test('shared-corpus conformance (all golden + behavioural cases)', () => {
  assert.strictEqual(main(), 0, 'conformance runner reported failures');
});
