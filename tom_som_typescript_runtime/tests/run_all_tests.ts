#!/usr/bin/env node
/**
 * Runs every compiled test of this package (`dist/tests/*.js` but this file),
 * each in its own process, and exits non-zero when any of them fails. This is
 * what `npm test` runs after the build, so a test file added to `tests/` is
 * part of the suite the conformance driver runs without being registered.
 *
 * Build with `tsc`, then run `node dist/tests/run_all_tests.js`.
 */

import { spawnSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

function main(): number {
  const self = path.basename(__filename);
  const tests = fs
    .readdirSync(__dirname)
    .filter((f) => f.endsWith('.js') && f !== self)
    .sort();
  const failed: string[] = [];
  for (const test of tests) {
    const run = spawnSync(process.execPath, [path.join(__dirname, test)], {
      encoding: 'utf8',
    });
    const last = `${run.stdout || ''}${run.stderr || ''}`.trim().split('\n').pop();
    console.log(`${run.status === 0 ? 'ok  ' : 'FAIL'} ${test}: ${last || ''}`);
    if (run.status !== 0) {
      failed.push(test);
      process.stdout.write(run.stdout || '');
      process.stderr.write(run.stderr || '');
    }
  }
  if (failed.length > 0) {
    console.log(`FAIL: ${failed.length}/${tests.length} test files failed`);
    return 1;
  }
  console.log(`OK: ${tests.length} test files passed`);
  return 0;
}

process.exit(main());
