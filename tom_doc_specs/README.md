# Tom Doc Specs

Document schema validation for structured markdown. Extends
[`tom_doc_scanner`](https://pub.dev/packages/tom_doc_scanner)'s document trees
with typed sections, schema resolution, and validation — so a markdown document
that declares a schema (`<!-- docspec: schema-id/version -->`) can be checked
for required sections, section types, and structural rules, and accessed
programmatically through typed section models.

## Features

- **Schema declarations in markdown** — a document names its schema in an HTML
  comment; schemas are resolved from `.docspec-schemas/` folders up the
  directory tree.
- **Typed section access** — `SpecDoc` / `SpecSection` wrap the raw
  `tom_doc_scanner` tree with the schema's section types.
- **Validation** — missing required sections, unknown sections, and
  type violations are reported with locations.
- **`docspecs` CLI** — validate documents from the command line or scripts.

## Usage

```dart
import 'package:tom_doc_specs/tom_doc_specs.dart';

final doc = await DocSpecs.scanDocument(path: 'quest_overview.docspec.md');
if (!doc.isValid) {
  print('Errors: ${doc.validationErrors}');
}
```

### CLI

```bash
dart pub global activate tom_doc_specs
docspecs validate path/to/document.md
```

## License

BSD 3-Clause — see [LICENSE](LICENSE).
