# Sample — a Phase 4 CodeSpecs run (Python)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** Python, on `tom_som_python_v0` and `tom_som_python_runtime`.

The Python runtime carries the gate (`CodeSpecsGate`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

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

The area catalogue the extractor walks is `tom_specs_model/generated-doc/codespecs/codespecs_areas.json`
in the checkout: the Dart package `tom_specs_model` ships it with an accessor,
and the Python runtime has none.

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): stages 1 and 2 and variant B are
the Dart sample's lines, and stages 3 and 4 are replaced by the note above.
The 54 extract files in `build/codespecs_extracts/` are byte for byte the ones
the Dart sample writes.
