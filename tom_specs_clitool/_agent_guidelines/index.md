# Tom Specs CLI Tool - Copilot Guidelines

**Project:** `tom_specs_clitool`
**Type:** Dart Package (`publish_to: none`)

## Applicable Guidelines

### Global Guidelines

| Document | Purpose |
|----------|---------|
| [Coding Guidelines](../../../../_agent_guidelines/dart/coding_guidelines.md) | Naming conventions, error handling, patterns |
| [Unit Tests](../../../../_agent_guidelines/dart/unit_tests.md) | Test structure, matchers, mocking patterns |
| [Tool Dependencies](../../../../_agent_guidelines/tool_dependencies.md) | `tom_build_base`-first policy for CLI infrastructure |

## Project-Specific Guidelines

| Document | Purpose |
|----------|---------|
| [SOM Regeneration](som_regeneration.md) | When and how to regenerate the nine committed `tom_som_<slug>_v0` packages, and the freshness gate that catches a stale one |
| [Working on the TomSpecs stack](working_on_tomspecs.md) | The model-change cascade in order, accessors in all nine runtimes, generated text changed in its emitter, a failing gate that may not be yours, commit scoping, the dart_style pin moving with the SDK |

## Quick Reference

**One entrypoint: `bin/tomspecs.dart`, on `tom_build_base`.** Every tool of the
package is a command of it. A new tool is a new command, never a new file in
`bin/`: its run function and `ArgParser` go in `lib/src/commands/` (or the CLI
library of its subject), the command is declared in `bin/tomspecs.dart` with
its options read from that parser, and it gets a row in the README's `tomspecs`
command table, which `test/entrypoint_options_test.dart` holds against the
declared options. A command runs other commands' functions in process, never as
a process.

The subject-matter documentation lives with the model, in
`../tom_specs_model/doc/` — `som_multiplatform_spec_model.md` (the SOM
authority), `som_generator_config.md` (the config block), `som_toolchains.md`
(per-language build/verify), and `tom_specs_model_meta_schema.md` (the emitted
meta). This folder holds only the *workflow* rules for working in this package.
