# Tom Specs CLI Tool - Copilot Guidelines

**Project:** `tom_specs_clitool`
**Type:** Dart Package (`publish_to: none`)

## Applicable Guidelines

### Global Guidelines

| Document | Purpose |
|----------|---------|
| [Coding Guidelines](../../../../_copilot_guidelines/dart/coding_guidelines.md) | Naming conventions, error handling, patterns |
| [Unit Tests](../../../../_copilot_guidelines/dart/unit_tests.md) | Test structure, matchers, mocking patterns |
| [Tool Dependencies](../../../../_copilot_guidelines/tool_dependencies.md) | `tom_build_base`-first policy for CLI infrastructure |

## Project-Specific Guidelines

| Document | Purpose |
|----------|---------|
| [SOM Regeneration](som_regeneration.md) | When and how to regenerate the nine committed `tom_som_<slug>_v0` packages, and the freshness gate that catches a stale one |

## Quick Reference

The subject-matter documentation lives with the model, in
`../tom_specs_model/doc/` — `som_multiplatform_spec_model.md` (the SOM
authority), `som_generator_config.md` (the config block), `som_toolchains.md`
(per-language build/verify), and `tom_specs_model_meta_schema.md` (the emitted
meta). This folder holds only the *workflow* rules for working in this package.
