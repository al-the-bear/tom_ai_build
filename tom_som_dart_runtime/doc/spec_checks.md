# The process checks library

`package:tom_som_dart_runtime/spec_checks.dart` holds the TomSpecs process
checks as functions over a document's text, the project's own data passed in
as text. It is a library of its own: a document reader imports
`tom_som_dart_runtime.dart` alone and does not carry the checks.
`tom_specs_clitool`'s `spec_checks` command is the CLI over it; its
[`process_checks.md`](../../tom_specs_clitool/doc/process_checks.md) describes
the checks and the `<spec-root>/checks/` files.

## A document root, without a facade

The checks that decode, render or validate take a `SpecRootDefinition`: the
model, the root's metadata tree and type, and its DocSpecs schema. A generated
facade supplies them, so the library needs none:

```dart
import 'package:tom_som_dart_runtime/spec_checks.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_schemas.dart';

final sbp = SpecRootDefinition(
  model: somSpecModel,
  tree: buildSomMetaTree(somSpecModel, rootType: 'D00SolutionBlueprint'),
  rootType: 'D00SolutionBlueprint',
  schema: somDocSpecsSchema('solution-blueprint'),
);
final doc = sbp.decode(yamlText);
final validation = sbp.validate(doc); // validation.markdown, .isClean
```

## The functions

| Function | Returns |
|----------|---------|
| `AnswerImporter.forYaml(type, yamlText).plan(markdown)` | An `ImportPlan`: the answers (and, allowed, other values) the edited rendition carries, the rewritten YAML, or the refusals |
| `acceptMarksInPlace(yamlText, tree, under:)` | A `MarksInPlaceResult`: the YAML with the marks accepted in place, verified value for value |
| `checkRequiredFields(yamlText, metaJson)` | Missing required fields and mistyped values |
| `checkQuestionRegister(yamlText, index, config:)` | The index against the question blocks; `QuestionRegisterConfig.parse` reads the project's prefixes, groups and statuses |
| `checkFeatureRegister(yamlText)` | The feature register's findings |
| `measureProjectIdeaCoverage(idea, sources, exclusions:)` | Each Project Idea id's coverage class (`parseProjectIdea`, `requirementSources`, `parseExclusions` read the inputs) |
| `crossCheckAuthorization(yamlText, roleModelYaml)` | The authorization cross-check's findings per check |
| `measureCoverage(...)` | The model coverage table |
| `locateValues` / `rewriteValues` | The layout-keeping YAML value rewrite the import uses |
