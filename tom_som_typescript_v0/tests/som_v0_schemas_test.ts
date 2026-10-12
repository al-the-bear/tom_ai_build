/**
 * The DocSpecs schema accessor (`tom_som_typescript_v0_schemas.ts`, SOM §10.3).
 *
 *   1. AGREEMENT — every id the accessor offers matches a shipped
 *      `schemas/<id>/…docspecs-schema.yaml` file byte for byte, and the id sets
 *      are equal, so the embedded copy can never drift from the files.
 *   2. ACCESSOR — `somDocSpecsSchema(id)` parses, caches, and refuses an unknown
 *      id instead of returning an empty schema that would validate anything.
 *   3. EXPORTS — the package's own `exports` map resolves `./schemas` and a
 *      schema file through the package name (Node self-reference), which is how
 *      a consumer reaches them without a path into this checkout.
 *
 * Compiled to `dist/tests/` by `npm run build`; exit code 0 == all green.
 */

import * as fs from 'fs';
import * as path from 'path';

import * as s from '../tom_som_typescript_v0_schemas';

const _PROJECT = path.dirname(path.dirname(__dirname)); // tom_som_typescript_v0

let _passed = 0;
const _failed: string[] = [];
function check(name: string, condition: boolean, detail?: string): void {
  if (condition) _passed += 1;
  else _failed.push(`${name}${detail ? ': ' + detail : ''}`);
}

// 1. Agreement with the shipped tree.
const schemasDir = path.join(_PROJECT, 'schemas');
const dirs = fs
  .readdirSync(schemasDir)
  .filter((d) => fs.statSync(path.join(schemasDir, d)).isDirectory())
  .sort();
check(
  'ids == schemas/ directories',
  JSON.stringify([...s.somDocSpecsSchemaIds]) === JSON.stringify(dirs),
  `${s.somDocSpecsSchemaIds.join(',')} vs ${dirs.join(',')}`,
);
for (const id of dirs) {
  const files = fs
    .readdirSync(path.join(schemasDir, id))
    .filter((f) => f.endsWith('.docspecs-schema.yaml'));
  check(`schemas/${id} holds one schema file`, files.length === 1, files.join(','));
  if (files.length !== 1) continue;
  const shipped = fs.readFileSync(path.join(schemasDir, id, files[0]), 'utf8');
  check(`embedded ${id} == shipped file`, s.somDocSpecsSchemaYaml[id] === shipped);
}

// 2. The accessor.
const sbp = s.somDocSpecsSchema('solution-blueprint');
check('solution-blueprint parses into section types', sbp.sectionTypes.length > 0);
check('a second call returns the cached schema', s.somDocSpecsSchema('solution-blueprint') === sbp);
let refused = false;
try {
  s.somDocSpecsSchema('no-such-schema');
} catch (e) {
  refused = /unknown schema id 'no-such-schema'/.test(String((e as Error).message));
}
check('an unknown id is refused, naming it', refused);

// 3. The package's exports map (resolved by package name, as a consumer would).
// eslint-disable-next-line @typescript-eslint/no-var-requires
const pkgName: string = require(path.join(_PROJECT, 'package.json')).name;
try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const viaExports = require(`${pkgName}/schemas`);
  check(
    'exports ./schemas is the accessor module',
    typeof viaExports.somDocSpecsSchema === 'function' &&
      viaExports.somDocSpecsSchemaIds.length === s.somDocSpecsSchemaIds.length,
  );
} catch (e) {
  check('exports ./schemas resolves', false, String((e as Error).message));
}
try {
  const file = require.resolve(
    `${pkgName}/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml`,
  );
  check('exports ./schemas/* resolves a schema file', fs.existsSync(file));
} catch (e) {
  check('exports ./schemas/* resolves a schema file', false, String((e as Error).message));
}

if (_failed.length > 0) {
  console.log(`FAIL: ${_failed.length}/${_passed + _failed.length} checks failed`);
  for (const f of _failed) console.log(`  - ${f}`);
  process.exit(1);
}
console.log(`OK: ${_passed} checks passed`);
