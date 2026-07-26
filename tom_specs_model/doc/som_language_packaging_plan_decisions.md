# SOM language-library packaging — decisions log

Design decisions and deferrals for
[`som_language_packaging_plan.md`](som_language_packaging_plan.md) and the
`PGK1..PGK11` todos. One block per decision or per todo as work proceeds.

---

## D1 — Package both runtime and facade, but only the facade is generator-emitted

Users depend on the typed `tom_som_<lang>_v0` facade, which depends on the
`tom_som_<lang>_runtime`. Both must be resolvable packages. The **facade**
packaging (manifest version, READMEs, descriptors) is **emitted by the
generator** so it refreshes every run; the **runtime** is hand-authored (not
regenerated), so only its manifest **version field** is realigned to the model
version by a generator step. This keeps the pair in lockstep without
regenerating hand-written runtime code.

## D2 — Do not check in built binary artifacts

The generator emits packaging *definitions* (manifests, `pkg-config`/CMake
descriptors, build/pack scripts, READMEs). Actual build outputs — wheels, sdists,
JARs, `.crate` files, npm `.tgz`, TypeScript `dist/`, C/C++ `build/`, Rust
`target/`, shared/static libs — are **gitignored** and produced on demand by a
documented, reproducible `pack`/`build` command. Checking in binaries would bloat
the repo and drift from source. Each per-language todo adds the relevant
`.gitignore` entries.

## D3 — Version single-sources from the model version

Every package (runtime + facade, all nine languages) takes its version from the
same model version the generator already resolves
(`tom_specs_model/lib/src/version.versioner.dart` → `modelVersion` /
`stamp.label`). No package keeps an independent version. Go, whose version lives
in VCS tags, additionally gets an emitted in-source version constant plus a
documented tag scheme so the "version = model version" rule holds there too.

## D4 — README convention: short block at top + separate full guide

`README.md` gains a short "how to use" block at the very top (install one-liner +
minimal snippet); the full integration guide lives in a separate
`readme_howtointegrate.md`. Both are generator-emitted for the facade (with a
"generated — do not edit" banner) and hand-authored for the runtime, using one
shared template mechanism so all nine languages stay structurally identical.

## D5 — No deferrals in scope

This request produces the **plan only** (this doc, the plan doc, and the
`PGK1..PGK11` todos). Implementation happens by iterating the todos. Nothing is
deferred; each todo is written to be implementable without further clarification
per the plan's per-ecosystem table and done-conditions.
