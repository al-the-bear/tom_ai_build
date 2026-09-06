# SOM toolchains — per-language build/run requirements

This document records the per-language toolchains needed to **compile and run**
the generated Spec Object Model (SOM) artefacts — the generic
`tom_som_<lang>_runtime` packages and the generated typed `tom_som_<lang>_v0`
projects — on the build/reference host(s), together with the versions in use and
how each toolchain is obtained. It also records the host requirement of the
tools that *produce* those artefacts: the SOM generator and the other
analyzer-backed tools run **without an installed Dart SDK** (see "Dart host"
below).

> **Reference host.** All versions below were captured on **`bomber`**
> (Linux `x86_64`, Ubuntu 24.04, kernel 6.17). `bomber` is the SOM reference
> host: it runs the generator (`tom_specs_clitool/bin/generate_som.dart`) and is
> where the generated trees are built and tested. Other fleet hosts
> (`mbp` macOS, `bigbeast` Linux, `legiondary01` Windows) are secondary; record
> their versions here as the component is brought up on them. `mbp` is fully
> brought up — see the "Secondary host `mbp`" section below.

## Status matrix (reference host `bomber`)

| Language | Toolchain | Version on `bomber` | `v0` project exists? | Verified | How obtained |
| --- | --- | --- | --- | --- | --- |
| **Dart** | Dart SDK | `3.11.4 (stable)` | **yes** (`tom_som_dart_v0`) | **builds + analyzes clean** | Dart SDK on `PATH` (fleet-managed) — the analyzer-backed tools need none, see "Dart host" |
| **Python** | CPython | `3.12.3` | **yes** (`tom_som_python_v0`) | **compiles + imports against runtime** | system `python3` (apt, Ubuntu 24.04) |
| **JavaScript** | Node.js | `22.22.3` (npm `10.9.8`) | **yes** (`tom_som_javascript_v0`) | **builds + runs generated `v0` ✓** (facade loads; behavioural + samples pass) | system `node`/`npm` |
| **TypeScript** | `tsc` (project-local npm) | **pinned `6.0.3`** (Node 22.22.3 / npm 10.9.8) | **yes** (`tom_som_typescript_v0`) | **builds + runs generated `v0` ✓** (facade compiles; behavioural + samples pass) | project-local `npm i -D typescript@6.0.3` |
| **C** | GCC | `gcc 13.3.0` | **yes** (`tom_som_c_v0`) | **builds + runs generated `v0` ✓** (facade compiles; behavioural + samples pass) | apt `build-essential` |
| **C++** | GCC / Clang | `g++ 13.3.0`, `clang++ 18.1.3` | **yes** (`tom_som_cpp_v0`) | **builds + runs generated `v0` ✓** (facade compiles; behavioural + samples pass) | apt `build-essential` / `clang` |
| **Java** | JDK | `javac 21.0.11` (JDK 21.0.11+10) | **yes** (`tom_som_java_v0`) | **builds + runs generated `v0` ✓** (facade compiles; behavioural + samples pass) | apt `openjdk-21-jdk-headless` (compiler only, no AWT/X11) |
| **Go** | Go toolchain | `1.26.4` (official tarball) | **yes** (`tom_som_go_v0`) | **builds + runs generated `v0` ✓** (facade compiles; behavioural + samples pass) | official tarball → `~/.local/go` (per-user, sha256-verified; PATH from `.bashrc`/`.profile`) |
| **Rust** | rustc / cargo | `1.96.0` (stable; rustfmt `1.9.0`) | **yes** (`tom_som_rust_v0`) | **builds + runs generated `v0` ✓** (facade compiles; behavioural + samples pass) | `rustup` (per-user, `~/.cargo`; `~/.cargo/env` sourced from `.bashrc`/`.profile`) |

### Reading the matrix

- **"Verified"** is the strongest check actually run:
  - *builds + analyzes / compiles + imports / builds + runs generated `v0`* — the
    real `v0` project was built and exercised. **All nine languages** (Dart,
    Python, Java, JavaScript, TypeScript, Go, Rust, C, C++) now have `v0`
    projects (D24/D32/D33/D34/D35/D36/D37/D38).
  - *compiles + runs ✓ / runtime smoke ✓* — a trivial hello-world was compiled
    and/or run to confirm the toolchain works, even though no SOM `v0` project
    exists for that language yet.
- **"`v0` project exists?"** tracks the typed emitters
  ([`som_multiplatform_spec_model.md`](som_multiplatform_spec_model.md) §10).
  All nine exist (Dart, Python, Java, JavaScript, TypeScript, Go, Rust, C, C++);
  no language is emitter-pending.
- **The facade size is one number, not nine.** Every emitter derives its facade
  from the same meta tree and emits one typed declaration per SOM class, so the
  nine `v0` facades are the same size by construction — **3989** typed
  declarations each (Dart/Java/JS/TS/C++ classes, Go/Rust/C structs), beside a
  smaller generated meta module. It is stated here once rather than per row
  precisely because the per-row repetition is what went stale: nine copies of a
  figure that can only ever have one value are eight chances to be wrong. Count
  it off the facade file of any language — they must agree, and a disagreement
  is a generator bug rather than a documentation one.

## Secondary host `mbp` (macOS arm64)

The full nine-language stack is also installed and verified on **`mbp`**
(macOS, Apple Silicon `arm64`). The conformance harness
(`tom_som_conformance/tool/regenerate_golden.sh`) passes end-to-end: all nine
golden logs are byte-identical to `dart.log`. Versions were matched to
`bomber` where the install channel allows pinning; compiler-suite versions
(Dart, Go, Apple clang) follow their own channels and are equal-or-newer.

| Language | Toolchain on `mbp` | Version | vs `bomber` | How obtained |
| --- | --- | --- | --- | --- |
| **Dart** | Dart SDK | `3.12.2 (stable)` | newer (3.11.4) | fleet-managed SDK on `PATH` |
| **Python** | CPython (Homebrew `python@3.12`) | `3.12.13` (PyYAML `6.0.3`) | same minor (3.12.3) | `brew install python@3.12`; PyYAML via `python3.12 -m pip install --user --break-system-packages PyYAML` |
| **JavaScript** | Node.js (nvm) | `22.22.3` (npm `10.9.8`) | **exact** | `nvm install 22.22.3 && nvm alias default 22.22.3` |
| **TypeScript** | project-local `tsc` | pinned `6.0.3` | **exact** (by design) | devDependency of the `v0` project — never a host install |
| **C** | Apple clang (via `cc`) | `17.0.0 (clang-1700.6.3.2)` | different suite (gcc 13.3.0) | Xcode Command Line Tools |
| **C++** | Apple clang (via `c++`/`g++` shims) | `17.0.0 (clang-1700.6.3.2)` | different suite (g++ 13.3.0 / clang++ 18.1.3) | Xcode Command Line Tools |
| **Java** | JDK (Homebrew `openjdk@21`, keg-only) | `javac 21.0.11` | **exact** | `brew install openjdk@21`; `PATH` + `JAVA_HOME` exported in `~/.zshrc` |
| **Go** | Go toolchain (Homebrew) | `1.26.5` | newer (1.26.4) | `brew install go` |
| **Rust** | rustc / cargo (rustup) | `1.96.0` | **exact** | `rustup` per-user (`~/.cargo`); `. "$HOME/.cargo/env"` in `~/.zshrc` |

Packaging tools (SOM §17 parity): **Maven `3.9.16`** (`brew install maven`, runs on
JDK 21 via `JAVA_HOME`; bomber has 3.9.11) and **Python `build 1.5.0`**
(`--user --break-system-packages`, exact match).

macOS-specific notes:

- **`python3` on `mbp` is a framework Python 3.11**, not the 3.12 toolchain.
  The harness and any `python3`-invoking script must run with
  `/opt/homebrew/opt/python@3.12/libexec/bin` prepended to `PATH` so
  unversioned `python3` resolves to 3.12 (bomber parity). The global `python3`
  is deliberately left untouched.
- **`cc`/`g++`/`c++` all resolve to Apple clang** — there is no GNU GCC on the
  host and none is needed; the C/C++ Makefiles use `CC ?= cc` / `CXX ?= g++`
  and build clean under clang.
- **Darwin shared-lib linking** differs from GNU ld: the C/C++ runtime and `v0`
  Makefiles (and the clitool generators that emit them) select
  `-Wl,-install_name` vs `-Wl,-soname` per `uname -s`, and the `v0` facades add
  `-Wl,-undefined,dynamic_lookup` on Darwin because Apple's ld rejects the
  facade's intentionally-undefined runtime symbols that GNU ld permits in a
  `-shared` link.
- Toolchain wiring lives in `~/.zshrc` (nvm block, cargo env, openjdk@21
  `PATH`/`JAVA_HOME`) — the macOS mirror of bomber's `.bashrc`/`.profile`.

## Language coverage

**Every one of the nine target languages is covered:** its toolchain builds its
`v0` project and runs that project's tests. Dart and Python are the reference
pair; Java, JavaScript, TypeScript, Go, Rust, C and C++ stand alongside them. No
language is emitter-pending.

The install path for each toolchain is recorded in the *How obtained* column of
the status matrix above, so a rebuild is a one-liner.

> **Host-install posture.** The **Java** compiler (`openjdk-21-jdk-headless`,
> `javac 21.0.11`), the **Rust** toolchain (`rustup` stable, `rustc`/`cargo`
> `1.96.0`), and the **Go** toolchain (official tarball, `go 1.26.4`) are
> installed on `bomber` as host toolchains. **TypeScript** is the one toolchain
> that is intentionally **not** a host install: its `tsc` is a project-local
> devDependency pinned to `typescript@6.0.3` that lands with the TS `v0`
> project, verified via the fixture smoke below. So **every target language's
> build path is accounted for** — eight host toolchains plus TypeScript's
> project-local `tsc`.

## Dart host: the analyzer without an installed SDK

The Dart row above records what a *developer* host needs. The analyzer-backed
tools have a weaker requirement: **they resolve Dart types, annotations and the
element model with no Dart SDK installed**, from a pre-serialized summary bundle
compiled into the binary. That is what lets the SOM generator run on a host that
carries only, say, a Go toolchain.

Everything that reads `tom_specs_model` through the analyzer goes through one
entry point — `createAnalysisDriver(packagePath)`, exported from the
`tom_specs_clitool` barrel: `serialization_order.dart`, the model reader behind
the outliner / validator / model-JSON exporter, and all nine
`som_<lang>_generator.dart` files.

### How it is put together

| Piece | Where | Role |
| --- | --- | --- |
| Embedded SDK summary | `tom_specs_clitool/lib/src/sdk_summary/` — 69 `chunk_NNN.dart` files plus a `sdk_summary_chunks.dart` barrel | The Dart SDK element model (`dart:core`, `dart:async`, …), base64-encoded and split at 60 000 chars per chunk so it compiles into the binary as ordinary `const` strings. ~3.10 MB raw → ~4.14 MB of base64 |
| Driver bootstrap | `tom_specs_clitool/lib/src/analyzer_bootstrap.dart` | Reassembles the chunks, builds a `SummaryBasedDartSdk` from the bundle, and wires a `SourceFactory` of `DartUriResolver` + `PackageMapUriResolver` + `ResourceUriResolver` |
| Summary generator | `tom_specs_clitool/bin/summaries.dart` | Produces the `sdk_summary.sum` this package's chunk set is split from. `--sdk-only` skips the package bundle, which `tom_specs_clitool` never loads. It is a one-off generator for *this* consumer — the editor's scoped asset set has a different producer (see "The `packages.sum` route") |
| Chunk splitter | `tom_specs_clitool/tool/split_sdk_summary.dart` | Turns a `.sum` file into the chunk set — the only producer of the embedded summary above |
| Shared infrastructure | `tom_analyzer_shared` (`tom_ai/basics/`), constraint `>=0.7.2` | The base-first home of the grouped `packages.sum` builder (`GroupedPackageBundleBuilder`) and the package-config helpers (`readPackageRoots`, `mergePackageRootsForDirs`, `SummaryConfigException`), re-exported from the clitool barrel |

**Only the SDK summary is needed here.** The model's own sources are analyzed
from disk, and the target package's dependencies resolve through its
`.dart_tool/package_config.json`, which `analyzer_bootstrap.dart` parses into a
`PackageMapUriResolver`. The `.sum` bundle supplies type resolution for SDK
types only — so `tom_specs_clitool` never loads a `packages.sum`.

The analyzer's summary APIs are **internal, not public API**. The dependency is
pinned at `analyzer: ^10.0.0` and the version must be moved deliberately. The
`>=0.7.2` floor on `tom_analyzer_shared` is likewise load-bearing: below it the
summary cache is keyed on the analyzer major alone rather than the Dart SDK
version (a point-SDK bundle-format drift then crashes the cached `.sum` reader),
and bundles are not invalidated when a transitive dependency changes version (a
stale closure silently drops classes).

### Regenerating after an SDK change

The chunk files are checked into version control, so they must be rebuilt
whenever the Dart SDK version moves:

```bash
cd tom_ai/ai_build/tom_specs_clitool
dart run bin/summaries.dart --sdk-only --out-dir assets
dart run tool/split_sdk_summary.dart assets/sdk_summary.sum lib/src/sdk_summary/
```

`--sdk-only` skips the `packages.sum`, which this package never loads.

`bin/summaries.dart` locates the SDK itself (`getSdkPath()`) and is covered by
`test/summaries_generator_test.dart`; the intermediate `assets/sdk_summary.sum`
is gitignored, since only the chunk set is committed.

### The `packages.sum` route

`packages.sum` covers every package reachable from a resolved
`package_config.json`. It exists for the **other** consumer of this
infrastructure — `tom_dart_editor`, which analyzes user-entered Dart in the
editor's code-typed fields where no `package_config.json` is available. It is
not part of the `tom_specs_clitool` path.

For that consumer the bundles are produced by
**`tom_forge/tom_dart_editor_bundler`**, not by `summaries.dart`. The bundler is
config-driven from the consuming app's own `buildkit.yaml` and emits a *scoped*
asset set — one shared `sdk_summary.sum` plus `<out-dir>/<scope>/packages.sum`
per scope — together with the `summary_scopes.g.dart` helper that names those
asset keys. Keeping one producer for that set is what makes the helper's paths
and the files on disk the same statement rather than two:

```bash
cd tom_forge/tom_specs_editor
dart run ../tom_dart_editor_bundler/bin/dart_editor_bundler.dart \
  --config buildkit.yaml --verbose
```

`tom_specs_clitool/bin/build.dart --generate-summaries` (SOM §17 step 5) runs
exactly that command; it does not generate the set itself.

Loading one needs a fallback resolver: the standard `InSummaryUriResolver` only
resolves URIs explicitly registered in `uriToSummaryPath`, so deserializing a
package's internal `src/` files fails without one. The implementation is
`PackageSummaryUriResolver` in
`tom_forge/tom_dart_editor/lib/src/analyzer_with_packages.dart` — it resolves an
exact `uriToSummaryPath` hit first, then falls back to the bundle for any URI
whose package is known.

### Key gotchas

| Issue | Cause | Solution |
|-------|-------|----------|
| `package:` URIs not found | `addBundle()` registers file URIs, not `package:` URIs | Manually register via `uriToSummaryPath[uriStr] = 'packages'` loop |
| Null check error on deserialization | Internal `src/` files missing from bundle | List files **recursively** with `listSync(recursive: true)` |
| Unresolved `package:X/src/...` at runtime | Standard resolver doesn't know internal files | Use `PackageSummaryUriResolver` fallback for known packages |
| SDK path needed | Only for building the summary, not at runtime | Use `Platform.resolvedExecutable` parent to find SDK during build |
| Base64 overhead | ~33% size increase over raw binary | Acceptable for ~3 MB SDK summary; consider gzip if needed |

### Reference implementation

- `tom_dart_editor`: `tom_forge/tom_dart_editor/` — reference for summary-based analysis
  - `lib/src/analyzer_with_packages.dart` — summary driver setup
  - `lib/src/summary_analysis_adapter.dart` — adapter layer
  - `doc/dart_editor_usage_guide.md` — usage guide
- `tom_dart_editor_test`: `tom_forge/tom_dart_editor_test/`
  - `assets/sdk_summary.sum` (~3 MB) — pre-built SDK summary
  - `assets/packages.sum` (~31 MB) — pre-built packages summary
  - `tool/build_packages_summary.dart` — build tool
  - `tool/check_sdk_sum.dart`, `tool/diagnose_packages_sum.dart` — diagnostics tools

## Packaging build tools (SOM §17 sign-off)

The **compile/run** matrix above covers each language's compiler/runtime. The
**packaging** sign-off sweep (SOM §17) additionally exercises each
ecosystem's build/pack command (`dart pub publish --dry-run`, `python3 -m build`,
`mvn package`, `npm pack`, `go build`, `cargo package`, `make dist`). Two of
those need a packaging tool beyond the bare compiler; both install per-user with
no root and are the only host gaps a fresh sign-off run hits:

- **Java — Maven.** `javac` compiles, but `mvn package` needs Maven, which is not
  in the base image. Install per-user from the official tarball (mirrors the Go
  route): download `apache-maven-<ver>-bin.tar.gz` (dlcdn, or archive.apache.org
  for older versions), extract to `~/.local/apache-maven-<ver>`, and put its
  `bin/` on `PATH`. Verified `3.9.11`.
- **Python — `build`.** `python3 -m build` needs the `build` PEP 517 front-end,
  which is not in the base image. On externally-managed Ubuntu 24.04 install it
  with `python3 -m pip install --user --break-system-packages build`. Verified
  `build 1.5.0`.

Sweep order matters for the two facades whose manifests name their runtime as a
registry dependency (SOM §17.3's ecosystem notes): `mvn package` in
`tom_som_java_v0` needs `mvn install` run in `tom_som_java_runtime` first (local
`~/.m2` resolution), and `cargo package` of `tom_som_rust_v0` is runnable only
once `tom_som_rust_runtime` is on crates.io — until then the facade's pack
verification is its `run_tests.sh` build + suite.

## Exercising every toolchain at once

Two drivers in `tom_som_conformance/tool/` reach every language
([`som_multiplatform_spec_model.md`](som_multiplatform_spec_model.md) §19.1):
`regenerate_golden.sh` (the nine golden logs) and `run_all_suites.sh` (the
eighteen hand-authored suites — nine runtime + nine `v0` packages, each behind
that package's uniform `run_tests.sh`). Together they are the fastest way to
confirm a host's whole nine-language stack actually works:

```bash
cd tom_ai/ai_build/tom_som_conformance
./tool/run_all_suites.sh --strict     # every suite must run and pass
./tool/regenerate_golden.sh           # nine logs, then the byte-identity compare
```

`--strict` turns a *skipped* suite into a failure, which is what you want on a
host that claims full coverage: without it a missing toolchain is reported as a
skip with its reason, so the driver stays usable on partially-provisioned hosts.
Both drivers add `~/.cargo/bin` to `PATH` when needed, because rustup wires
cargo into the interactive profile only.

## Documentation generation

`tom_specs_documentation_standard.md` §5 puts a **generated API reference** in
every SOM package's `doc/api/reference/`, and names a generator per language.
This section records the eight tools, how each is obtained, the exact
invocation, and what happens when one is absent.

**One driver reaches all eighteen packages**
([`tom_specs_clitool/tool/regenerate_api_references.sh`](../../tom_specs_clitool/tool/regenerate_api_references.sh)):

```bash
cd tom_ai/ai_build/tom_specs_clitool
./tool/regenerate_api_references.sh                    # every available language
./tool/regenerate_api_references.sh --strict           # a skip is a failure
./tool/regenerate_api_references.sh dart_runtime rust_v0
./tool/regenerate_api_references.sh --list             # the eighteen target names
```

It lives beside the generator rather than in `tom_som_conformance` because its
subject is the *eighteen packages*, which is `tom_specs_clitool`'s subject
already — the conformance package's subject is the corpus. Its shape is
deliberately `run_all_suites.sh`'s: one entry point, per-target selection, and a
**skip with the reason stated** when a toolchain is missing, never a silent
pass. `--strict` turns a skip into a failure, which is what a host claiming full
coverage should use. The driver prepends `~/.cargo/bin`, the Go tarball
locations and `JAVA_HOME/bin` when those are not already resolvable, for the
same reason the conformance drivers do: rustup and the Go tarball wire
themselves into the *interactive* profile only.

### The generated reference is **gitignored**, deliberately

`**/doc/api/**` is excluded in `tom_ai/ai_build/.gitignore` and
`tom_ai/core/.gitignore`, with `api_summary_*.md` / `api_reference_*.md`
re-included — the hand-written summaries are source, the rendered reference is
output.

The quest's own precedent cuts both ways: `generated-doc/` is committed because
the outlines are *read in review*, while `testlog/` is fully ignored because an
artefact nothing updates cannot be told from a current one. The reference falls
on the second side, for three measured reasons:

- **Size.** The eighteen trees together measure **1.8 GB** on this host — not an
  estimate, a `du -shc` over a full run. The distribution is lopsided, and not
  where intuition puts it: the *runtime* trees are small (dartdoc over
  `tom_som_dart_runtime` is ~7 MB), while the generated **facades** dominate —
  `tom_som_dart_v0` alone is 670 MB, `tom_som_rust_v0` 262 MB, `tom_som_c_v0`
  96 MB — because a facade declares roughly 1250 types and every generator
  writes a page per entity.
- **Reviewability.** It is HTML, so every source edit would produce a large diff
  nobody reads — the opposite of the outlines, whose whole value is that a
  reviewer *can* read them.
- **Reproducibility.** Every byte regenerates from source in seconds to minutes
  by the command above, so nothing is lost by not holding it.

Because the folder is not committed,
[`tom_specs_documentation_standard.md`](tom_specs_documentation_standard.md)
§3.1 and §8 say so explicitly — a checklist line asking for a folder the repo
refuses to hold is a line nobody can satisfy.

### Per-language generators

| Language | Tool | Obtain it with | Output |
| --- | --- | --- | --- |
| **Dart** | `dart doc` | Ships with the Dart SDK | HTML tree (~7 MB) |
| **Python** | `pdoc` | `python3 -m pip install pdoc` — **on Python ≥ 3.10** | HTML tree |
| **JavaScript** | `typedoc` | `npx typedoc@<pinned>` (no host install) | HTML tree |
| **TypeScript** | `typedoc` | `npx typedoc@<pinned>` (no host install) | HTML tree |
| **Go** | `go doc` | Ships with the Go toolchain | One rendered **text** file |
| **Rust** | `cargo doc` | Ships with rustup | HTML tree (~7.7 MB) |
| **Java** | `javadoc` | Ships with the JDK | HTML tree |
| **C** | `doxygen` | `apt-get install doxygen` / `brew install doxygen` | HTML tree |
| **C++** | `doxygen` | Same | HTML tree |

The exact invocations are in the driver, one `gen_<tool>` function each. Six of
them needed a non-obvious adjustment, and each is worth knowing before invoking
the tool by hand:

| Language | The adjustment, and why |
| --- | --- |
| **Python** | The importable name is **not** the directory name — the runtime ships the package `tom_som_runtime/`, the facade the module `tom_som_python_v0.py` — so the driver discovers it. And **pdoc imports the module rather than parsing it**, so the interpreter running pdoc needs the runtime's own dependencies (`pyyaml`) installed *for that interpreter*. |
| **Python** | It must run on **Python ≥ 3.10**. The sources use PEP 604 `X \| Y` annotations, which pdoc evaluates; on 3.9 it warns and degrades the types. On a host whose default `python3` is 3.9 (macOS), install pdoc into a newer interpreter. |
| **JavaScript** | `allowJs` is a *TypeScript compiler* option, so it cannot be a typedoc flag — it has to arrive through a `tsconfig`, and that tsconfig must `include` the entry point or typedoc reports "unable to find any entry points". The driver writes a scoped one beside the entry and removes it afterwards. |
| **JS / TS** | typedoc exits **non-zero on warnings** as well as errors, and these sources warn routinely (doc links to built-in types they do not export). The driver asks whether `index.html` was rendered instead of reading a status that conflates the two. |
| **Java** | The facade's sources reference the runtime's types, so `tom_som_java_runtime/src` must be on the `-sourcepath` — without it javadoc reports a hundred unresolved symbols and writes nothing. Only the named subpackages are documented, so this widens resolution without widening output. |
| **C / C++** | `INPUT` is the **public headers only**, never `src`. The generated `*_v0` implementation files run to tens of thousands of lines: including them took doxygen many minutes and produced a tree far larger still — a source browser, not a reference. Even headers-only the two C/C++ facades are among the slowest targets. |
| **Go** | `go doc` renders **text**, not an HTML tree; `pkg.go.dev` is the hosted equivalent and there is no local site generator. The reference is therefore one `index.txt` per package, which is what the Go ecosystem actually offers locally. |
| **Rust** | `cargo doc` insists on writing into the crate's target directory, so the driver copies the rendered tree out to `doc/api/reference/` — the same location every other language uses. |

### When a toolchain is absent

The driver reports `SKIP <target> <reason>` and continues; the closing line
names how many were skipped. Nothing is reported as generated that was not. On a
host that claims full coverage, run with `--strict`, which turns every such skip
into a `FAIL`.

The reasons are specific enough to act on — `pdoc not installed (pip install
pdoc)`, `doxygen not installed (brew install doxygen)`, `javadoc not on PATH (no
JDK)` — because a skip whose reason is "unavailable" tells an operator nothing
they did not already know.

## Verification commands

The exact checks used to populate the matrix (re-runnable on any host):

```bash
# Dart v0 — build + analyze
cd tom_ai/ai_build/tom_som_dart_v0 && dart pub get && dart analyze

# Python v0 — compile + import against the generic runtime
cd tom_ai/ai_build
python3 -m py_compile tom_som_python_v0/tom_som_python_v0.py
PYTHONPATH="tom_som_python_runtime:tom_som_python_v0" \
  python3 -c "import tom_som_python_v0 as m; print(hasattr(m,'D00SolutionBlueprint'))"

# Present-but-projectless toolchains — trivial smoke
node -e "console.log(1+1)"
echo 'int main(){return 0;}' | gcc   -x c   - -o /tmp/a && /tmp/a
echo 'int main(){return 0;}' | g++   -x c++ - -o /tmp/a && /tmp/a
echo 'int main(){return 0;}' | clang++ -x c++ - -o /tmp/a && /tmp/a

# Java — javac present (compiler smoke: compile + run)
javac -version
printf 'public class S{public static void main(String[] a){System.out.println("ok");}}\n' > S.java \
  && javac S.java && java S && rm -f S.java S.class

# Rust — toolchain present (cargo smoke: build + run)
. "$HOME/.cargo/env"      # rustup is per-user; not on PATH until env is sourced
rustc --version && cargo --version
cargo new --quiet --bin rust_smoke && (cd rust_smoke && cargo run --quiet) && rm -rf rust_smoke

# Go — toolchain present (go smoke: build + run)
export PATH="$HOME/.local/go/bin:$PATH"   # per-user SDK; PATH set from .bashrc/.profile
go version
mkdir go_smoke && cd go_smoke && printf 'package main\nimport "fmt"\nfunc main(){fmt.Println("ok")}\n' > main.go \
  && go mod init smoke >/dev/null && go run . && cd .. && rm -rf go_smoke

# TypeScript — project-local tsc (no host install; the v0 project will own the
#   devDependency). Smoke: install pinned tsc into a throwaway project, compile a
#   fixture exercising interfaces + generics + classes, run the emitted JS.
mkdir ts_smoke && cd ts_smoke && npm init -y >/dev/null \
  && npm i -D typescript@6.0.3 >/dev/null \
  && printf 'interface SomNode { id: string }\nclass SomScalar<T> implements SomNode {\n  constructor(public id: string, public value: T) {}\n}\nconst n = new SomScalar<string>("SBP", "hello");\nconsole.log(`ts OK: ${n.id}/content=${n.value}`);\n' > probe.ts \
  && ./node_modules/.bin/tsc --strict --target ES2020 --module commonjs probe.ts \
  && node probe.js && cd .. && rm -rf ts_smoke
```

## Installing the missing toolchains (when their emitter lands)

```bash
# Java — JDK compiler (adds javac; JRE 21 already present)
#   headless = compiler only, no AWT/X11 — the right choice for a build host.
#   Installed on bomber via the root admin path (sudo needs a password here).
sudo apt-get install -y openjdk-21-jdk-headless   # or openjdk-21-jdk for the full GUI JDK

# Go — official tarball, per-user (newer than apt's 1.22; no root). Installed on
#   bomber to ~/.local/go (NOT ~/go, which is the default GOPATH), sha256-verified
#   against go.dev's published checksum, with PATH wired in .bashrc/.profile.
GOVER=go1.26.4; T=${GOVER}.linux-amd64.tar.gz
curl -fsSLO "https://go.dev/dl/${T}"          # verify sha256 vs go.dev/dl/?mode=json
rm -rf ~/.local/go && tar -C ~/.local -xzf "$T" && rm -f "$T"
printf '\nexport PATH="$HOME/.local/go/bin:$PATH"\n' >> ~/.bashrc
printf '\nexport PATH="$HOME/.local/go/bin:$PATH"\n' >> ~/.profile
#   apt alternative (older 1.22, system-wide, needs root): sudo apt-get install -y golang-go

# Rust — rustup (per-user, recommended; installs into ~/.cargo). Installed on
#   bomber with --no-modify-path, then `. "$HOME/.cargo/env"` was appended to
#   ~/.bashrc and ~/.profile so the wiring is explicit/auditable rather than a
#   rustup-injected block.
curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
  | sh -s -- -y --no-modify-path --default-toolchain stable --profile default
printf '\n. "$HOME/.cargo/env"\n' >> ~/.bashrc
printf '\n. "$HOME/.cargo/env"\n' >> ~/.profile

# TypeScript — project-local dev dependency (the route used; NOT a host install).
#   The version is pinned so every host compiles the v0 project identically.
npm i -D typescript@6.0.3   # in the tom_som_typescript_v0 project (when emitter lands)
#   global (npm i -g typescript) is deliberately avoided — it leaks a host-wide,
#   unpinned tsc that the generated project would not control.
```

After installing, re-run the relevant verification command above and update this
matrix with the captured version — the matrix is the tracker.
