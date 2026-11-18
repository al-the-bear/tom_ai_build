/**
 * DELIBERATELY WRONG — this file must NOT compile.
 *
 * The typed facade gives every section its own class, so a section passed
 * where another one belongs is a compile error, not a document that silently
 * holds values in the wrong place. A dynamic port (JavaScript, Python) runs
 * the same mistake and writes the wrong section. `tool/validate.sh` compiles
 * this file and passes only while `tsc` rejects it with the errors recorded
 * in `expected_tsc_output.txt`.
 */
import { SpecDocument } from 'tom_som_typescript_runtime';
import { CurrentLandscape, D00SolutionBlueprint } from 'tom_som_typescript_v0';

/** Writes the current-landscape narrative — it takes that section only. */
function describeLandscape(landscape: CurrentLandscape): void {
  landscape.content = 'Three systems, no shared customer record.';
}

const sbp = new D00SolutionBlueprint(new SpecDocument());

// 1. The wrong section: an IntroductionAndScope is not a CurrentLandscape.
describeLandscape(sbp.introductionAndScope);

// 2. A section is not a value: the accessor has no setter.
sbp.currentLandscape = sbp.currentLandscape;

// 3. A content leaf holds text, not a number.
sbp.currentLandscape.content = 4.2;
