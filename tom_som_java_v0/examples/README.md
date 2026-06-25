# `tom_som_java_v0` — runnable samples

Three runnable samples covering the three access paths to a TomSpecs Spec
Object Model document (plan item #14, spec §3.1). They are **hand-authored**
and preserved across `generate_som` regeneration (the generator only rewrites
`src/tom_som_java_v0/TomSomV0.java`, `meta/`, `schemas/` and `tom_som_build.json`).

Zero external dependencies — only the JDK (`javac`/`java`). The generic runtime
source path is recorded (relative, for portability) in `tom_som_build.json`.
Compile everything once, then run any sample. From this package directory
(`tom_som_java_v0`):

```bash
runtime="$(sed -nE 's/.*"runtimeSourcePath"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' tom_som_build.json)"
javac -d build -sourcepath "src:$runtime" examples/*.java
java -cp build ATypedAccess
```

| Sample | File | Access path | Run |
| ------ | ---- | ----------- | --- |
| **(a)** Typed object-model | [`ATypedAccess.java`](ATypedAccess.java) | The generated typed facade — named accessors, nested-section navigation, the typed `SomList` collection. | `java -cp build ATypedAccess` |
| **(b)** Generic document | [`BGenericDocument.java`](BGenericDocument.java) | The language-independent generic runtime — string paths into a sparse store, plus JSON / YAML serialization. | `java -cp build BGenericDocument` |
| **(c)** Reflection / meta-data | [`CReflectionMetadata.java`](CReflectionMetadata.java) | The value-free reflection surface — load `meta/spec_model.meta.json` into a `SpecModel`, enumerate roots/fields, resolve paths to model nodes. | `java -cp build CReflectionMetadata` |

All three describe the **same** document shape, and produce output identical to
their Dart counterparts in `tom_som_dart_v0/example/` and Python counterparts in
`tom_som_python_v0/examples/` — illustrating that the typed facade (a) is a thin,
type-safe surface over the exact generic store (b), whose schema is described by
the reflection model (c).

`../run_tests.sh` compiles these samples alongside the behavioural test
(`tests/GeneratedModelTest.java`) and runs the test as the green gate.
