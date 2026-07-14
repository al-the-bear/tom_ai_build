# tom_som_python_runtime

Python port of the **generic TomSpecs object-model runtime** — the value-free,
generated-code-free half of the multi-platform spec model (`tom_som`). It is a
faithful transcription of the Dart reference, `tom_som_dart_runtime`.

## How to use

This package is the generic runtime — most callers depend on it indirectly via a
typed facade (`tom_som_python_v0`). To use it directly, install it
(`pip install tom_som_python_runtime`) and drive a sparse document:

```python
from tom_som_runtime import SpecDocument

doc = SpecDocument()
doc.set_content("SBP/content", "A platform that unifies our order systems.")
print(doc.content("SBP/content"))
```

See **readme_howtointegrate.md** for the full integration guide (PyPI / git /
editable routes and how to pin the version to the TomSpecs model version).


## What it is

The package `tom_som_runtime` mirrors the seven portable Dart modules:

| Module | Responsibility |
| ------ | -------------- |
| `spec_paths` | The section-path grammar (root / child / list-item segments). |
| `spec_model` | The meta-data loader — the exported class graph (`SpecModel`). |
| `spec_reflection` | Value-free enumeration + path resolution (`SpecReflection`). |
| `spec_document` | A sparse in-memory document — values keyed by section path. |
| `spec_validator` | Validates a document's values against the model. |
| `spec_document_yaml` | Byte-stable `*.docspecs.yaml` codec. |
| `spec_document_markdown` | Meta-data-driven Markdown import/export codec. |

It holds **no document values of its own** and contains **no generated typed
classes** — those belong to the per-language `tom_som_<lang>_v0` packages.

## Conformance

Correctness is defined by the shared, language-agnostic conformance corpus in
`../tom_som_conformance/corpus`, generated from the Dart reference. The Python
port is validated against the exact same goldens every other port uses:

```bash
python3 tests/conformance_runner.py
```

This asserts byte-for-byte equality of the YAML and Markdown encodings, the
document round-trips, and the reflection / validation / operations behaviour.

## Requirements

* Python ≥ 3.9
* PyYAML ≥ 6.0 (the YAML decoder + the encoder's self-verification, mirroring
  Dart's `package:yaml`).
