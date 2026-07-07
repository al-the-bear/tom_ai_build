# Integrating tom_som_python_runtime

`tom_som_python_runtime` is the generic Python runtime for the TomSpecs object
model. The typed facade `tom_som_python_v0` depends on it; depend on the runtime
directly only when you want the generic `SpecDocument` / meta-model API. The
importable package is **`tom_som_runtime`** (the distribution name is
`tom_som_python_runtime`). Both packages are versioned to the TomSpecs **model
version** — pin to that version so your document reads and writes match the
model.

## Quick start

Install `tom_som_python_runtime` (`pip install tom_som_python_runtime`), then:

```python
from tom_som_runtime import SpecDocument

doc = SpecDocument()
doc.set_content("PD/content", "A platform that unifies our order systems.")
print(doc.content("PD/content"))
```

## Dependency routes

### From PyPI

```bash
pip install tom_som_python_runtime
```

or pin it in your `pyproject.toml` / `requirements.txt`:

```
tom_som_python_runtime>=1.0.0
```

### Git dependency

```bash
pip install "tom_som_python_runtime @ git+https://github.com/al-the-bear/tom_ai_build.git#subdirectory=tom_ai/ai_build/tom_som_python_runtime"
```

### Path / editable (monorepo / vendored)

```bash
pip install -e ../tom_som_python_runtime
```

## Pinning the version

The runtime carries a version taken from the TomSpecs model version, and the
typed `tom_som_python_v0` facade carries the same version. When you upgrade the
model, move both to the new matching version so the facade and your stored
documents stay in step.

## Building from source

```bash
cd tom_som_python_runtime
python -m build
```

This writes a wheel and an sdist under `dist/`.
