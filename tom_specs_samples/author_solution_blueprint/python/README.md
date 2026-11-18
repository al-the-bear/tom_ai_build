# Sample — author a Solution Blueprint (Python)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** Python, on `tom_som_python_v0` and `tom_som_python_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

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

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

The accessors keep the model's member names (`introductionAndScope`,
`operationalMetrics`); the runtime's own calls are Python's (`yaml_encode`,
`validate_document`, `load_file`).
