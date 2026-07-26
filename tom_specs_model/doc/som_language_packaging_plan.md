# SOM language-library packaging plan

Goal: make every SOM language library **easy to integrate** into a downstream
project via that language's native package tooling. Nine languages, each with a
hand-authored `tom_som_<lang>_runtime` (generic base) and a generated
`tom_som_<lang>_v0` facade (typed, emitted by
`tom_specs_clitool/bin/generate_som.dart`). Users depend on the **v0 facade**,
which in turn depends on the **runtime**, so both must be resolvable packages.

The work is planned as todos `PGK1..PGK11` in
`todos.tom_specs.todo.yaml`. `PGK1` lays the shared groundwork; `PGK2..PGK10`
implement one language each (in `tom_som.yaml` order); `PGK11` is the
cross-cutting verification sweep. Design decisions and any deferrals go in
[`som_language_packaging_plan_decisions.md`](som_language_packaging_plan_decisions.md).

## The four required elements (per language)

Every per-language todo must deliver all four, for **both** the runtime and the
v0 facade unless noted:

1. **Create the native package.** Produce the packaging *definition* in the
   ecosystem's idiom so a downstream consumer can add the library as a normal
   dependency (see the per-ecosystem table below). Built binary artifacts
   (wheels, jars, `.crate`, `.tgz`, `.so`/`.a`, `dist/`) are **not** checked in
   — they are gitignored build outputs produced by a documented `pack`/`build`
   command. What is checked in is the manifest + descriptors + a reproducible
   build/pack command.
2. **README how-to (short) + `readme_howtointegrate.md` (full).** The very top
   of `README.md` gets a short "how to use" block: the one-line install/add-dep
   command and a minimal usage snippet. A separate `readme_howtointegrate.md`
   holds the full integration guide (every route: package registry, git dep,
   local path / vendored copy, and how to pin the version).
3. **Generator-integrated + checked in.** For the **v0 facade**, the packaging
   files (manifest version, `README.md`, `readme_howtointegrate.md`, and any
   ecosystem descriptor the facade owns) are **emitted by the generator** so
   they are refreshed on every `generate_som.dart` run and committed alongside
   the generated code. The **runtime** packaging is hand-authored (it is not
   regenerated), but its manifest **version is realigned to the model version**
   by a generator step so runtime and facade stay in lockstep.
4. **Version = general model version.** Both the runtime and the facade carry the
   same model version the generator already resolves from
   `tom_specs_model/lib/src/version.versioner.dart` (`modelVersion` /
   `stamp.label` in `generate_som.dart`). No independently-maintained package
   version.

## Per-ecosystem packaging approach

| Lang | Package form | Add-dependency route | Pack/verify command |
| ---- | ------------ | -------------------- | ------------------- |
| Dart | pub package (`pubspec.yaml`) | pub.dev / git / path dep | `dart pub publish --dry-run` |
| Python | PEP 517 dist (`pyproject.toml`) → wheel + sdist | `pip install` (wheel / git / path) | `python -m build` |
| Java | Maven artifact (`pom.xml`) + JAR | Maven/Gradle coordinates; JAR drop-in | `mvn -q package` (fallback `build_jar.sh` via `jar`) |
| JavaScript | npm package (`package.json`) | `npm install` (registry / git / tarball) | `npm pack --dry-run` |
| TypeScript | npm package w/ compiled `dist/` + `.d.ts` | `npm install`; `prepack` builds | `npm pack --dry-run` |
| Go | Go module (`go.mod`) + version tag | `go get <module>@<tag>` | `go build ./... && go vet ./...` |
| Rust | Cargo crate (`Cargo.toml`) | crates.io / git dep | `cargo package --no-verify` |
| C | static+shared lib + headers + `pkg-config` `.pc` + `make dist` | `pkg-config` / vendored headers+lib | `make && make dist` |
| C++ | static+shared lib + headers + CMake package-config (or `.pc`) + `make dist` | `find_package` / `pkg-config` / vendored | `make && make dist` |

Notes:
- **Go** versions live in VCS tags, not the manifest; the module packaging step
  documents the tag scheme mapping the model version → `vMAJOR.MINOR.PATCH` and
  ensures the module path + `doc.go` are correct. The "version = model version"
  requirement is satisfied by the documented tag + an in-source version constant
  emitted by the generator.
- **Java v0** currently has **no manifest at all** — this plan adds one.
- **C / C++** have no universal registry; "package" means a clean, versioned,
  installable artifact (lib + headers + a discovery file) plus a `make dist`
  tarball, which is the realistic integration path for those consumers.

## Generation-integration design (PGK1)

- Extend each `generateSom<Lang>Project` (or a shared post-step) to emit the
  short-form `README.md`, `readme_howtointegrate.md`, and any facade-owned
  packaging descriptor, all stamped with the resolved model version. Emitted
  files carry a "generated — do not edit" banner.
- Add a **runtime-version-alignment** step to `generate_som.dart` (a small,
  idempotent rewrite of each `tom_som_<lang>_runtime` manifest's version field to
  the model version). Runtime source is not regenerated; only its version field
  is realigned.
- Provide **one shared README/howto template mechanism** in the clitool so the
  nine languages produce structurally-identical docs (same headings, same
  version-pin section) — differing only in the ecosystem-specific commands.
- `.gitignore` the built artifacts in every project (wheels, jars, `.crate`,
  `*.tgz`, `dist/`, `build/`, `target/`, `*.so`, `*.a`, `*.pc` output dir).

## Done-condition for the sweep (PGK11)

`generate_som.dart` runs clean; every v0 facade's packaging files are
regenerated at the current model version and committed; all nine libraries
build/pack with the documented command; every one of the 18 projects has a
short-form README how-to block and a `readme_howtointegrate.md`; runtime and
facade versions match the model version everywhere; `dart analyze`, the
`tom_specs_clitool` suite, and the nine language suites stay green; golden
byte-identity is unaffected (packaging touches no rendered output).
