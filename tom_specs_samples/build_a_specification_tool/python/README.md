# Sample — build a specification tool (Python)

**Teaches:** the same as [the Dart sample](../README.md) — reflective access to
the model, generic access to a document, the generated schema, the validation
tiers, and a completeness report built on all of it.
**Phase:** any — tooling.
**Language:** Python, on `tom_som_python_v0` and `tom_som_python_runtime`.

A port of `../bin/build_a_specification_tool.dart`, over the same fixture.

## Prerequisites

* Python 3.9 or later (`python3 --version`), and PyYAML for the runtime.
* A checkout of `tom_ai/ai_build`. The Python packages, `tom_som_python_runtime`
  and `tom_som_python_v0`, are **not on PyPI** (the non-Dart runtimes are not
  published to registries), so this sample runs on the checkout's sources.

Either install them into a virtual environment beside the sample:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip   # editable installs need pip >= 21.3
.venv/bin/pip install -e ../../../tom_som_python_runtime -e ../../../tom_som_python_v0
.venv/bin/python main.py
```

or put them on `PYTHONPATH` (what `tool/run_all_samples.sh` does):

```bash
PYTHONPATH=../../../tom_som_python_runtime:../../../tom_som_python_v0 python3 main.py
```

## What you should see

Five numbered sections; every number is the Dart sample's. The text is in this
port's own [`expected_output.txt`](expected_output.txt), because it differs from
the Dart sample's in four places, each where the Dart text names a Dart-only
surface:

* the fixture function is `_author_fixture` (Python's naming);
* the annotation display semantics (`kRenderedAnnotations`) are in the Dart
  runtime only — they are what the two Flutter apps share — so this port says
  that instead of counting them;
* the metadata tree's lookups are `by_id` / `by_path`;
* the Dart text points at a Dart example (`example/f_sample_hybrid_access.dart`).

The schema is read from the data the facade ships (`tom_som_python_v0_data.schemas_root()`),
the model from `tom_som_python_v0_data.spec_model()`.
