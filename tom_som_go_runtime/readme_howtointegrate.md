# Integrating tom_som_go_runtime

`tom_som_go_runtime` (package `somruntime`) is the generic, value-free TomSpecs
object-model runtime for Go. It has **zero external dependencies** (Go standard
library only) and is versioned to the TomSpecs **model version** — the same
version the typed facade `tom_som_go_v0` reports. Pin both to that version so
your document reads and writes match the model the facade was generated from.

Most projects depend on the typed facade `tom_som_go_v0` (which `require`s this
runtime) rather than on the runtime directly. Depend on the runtime alone only
when you drive the generic API by section path.

Go has no central package registry: a version is a **VCS tag** on the module,
and the same value is mirrored in the in-source `Version` constant (`doc.go`) so
a build can report the version it was compiled from without VCS access.

## Quick start

```bash
go get github.com/al-the-bear/tom_ai_build/tom_som_go_runtime@v1.0.0
```

```go
import som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"

doc := som.NewSpecDocument()
doc.SetContent("D00/D01", "A unifying order platform.")
fmt.Println(doc.Content("D00/D01"))
```

## Dependency routes

### From `go get`

Add the runtime as a dependency of your module, pinned to a tag:

```bash
go get github.com/al-the-bear/tom_ai_build/tom_som_go_runtime@v1.0.0
```

`go get` resolves the domain-qualified module path via VCS and records it in
your `go.mod`.

### Version tags

Go module versions are VCS tags of the form `vMAJOR.MINOR.PATCH`. Select a
specific one with the `@` suffix (`@v1.0.0`), `@latest`, or a commit
(`@<sha>`). The chosen version must match the in-source `Version` constant of
the runtime and the model version the facade `tom_som_go_v0` was generated
against.

### Path replace (monorepo / vendored)

When the SOM modules sit alongside your code, resolve the runtime from a local
checkout with a `replace` directive in your `go.mod`:

```
require github.com/al-the-bear/tom_ai_build/tom_som_go_runtime v0.0.0

replace github.com/al-the-bear/tom_ai_build/tom_som_go_runtime => ../tom_som_go_runtime
```

This is exactly how `tom_som_go_v0` consumes the runtime — the generator writes
a `require` plus a relative `replace` into the facade `go.mod`, so the generated
source stays path-free and golden-stable while still building in-repo.

## Pinning the version

`tom_som_go_runtime` and `tom_som_go_v0` both carry the TomSpecs model version.
When you upgrade the model, regenerate the facade, tag both modules at the new
matching version, and update the in-source `Version` constants so the runtime,
the facade, and your stored documents stay in step. The runtime is
hand-authored (never regenerated); only its version is realigned to the model
version by `generate_som.dart`.

## Building from source

The runtime builds with the Go toolchain and has no external dependencies:

```bash
go build ./...                       # compile the runtime
go vet ./...                         # static checks
go test ./tests/ -run Conformance    # → "OK: N checks passed"
# or, all-in-one:
./run_conformance.sh
```
