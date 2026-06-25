# SOM toolchains — per-language build/run requirements

Plan item #12 of `multiplatform_spec_model_plan.md`. This document records the
per-language toolchains needed to **compile and run** the generated Spec Object
Model (SOM) artefacts — the generic `tom_som_<lang>_runtime` packages and the
generated typed `tom_som_<lang>_v0` projects — on the build/reference host(s),
together with the versions in use and how each toolchain is obtained.

> **Reference host.** All versions below were captured on **`bomber`**
> (Linux `x86_64`, Ubuntu 24.04, kernel 6.17). `bomber` is the SOM reference
> host: it runs the generator (`tom_specs_clitool/bin/generate_som.dart`) and is
> where the generated trees are built and tested. Other fleet hosts
> (`mbp` macOS, `bigbeast` Linux, `legiondary01` Windows) are secondary; record
> their versions here as the component is brought up on them.

## Status matrix (reference host `bomber`)

| Language | Toolchain | Version on `bomber` | `v0` project exists? | Verified | How obtained |
| --- | --- | --- | --- | --- | --- |
| **Dart** | Dart SDK | `3.11.4 (stable)` | **yes** (`tom_som_dart_v0`) | **builds + analyzes clean** | Dart SDK on `PATH` (fleet-managed) |
| **Python** | CPython | `3.12.3` | **yes** (`tom_som_python_v0`) | **compiles + imports against runtime** | system `python3` (apt, Ubuntu 24.04) |
| **JavaScript** | Node.js | `22.22.3` (npm `10.9.8`) | no (emitter pending #10) | runtime smoke ✓ | system `node`/`npm` |
| **TypeScript** | `tsc` (via npm) | not installed; `npx` `10.9.8` present | no (emitter pending #10) | n/a | `npm i -g typescript` **or** project-local `npm i -D typescript` |
| **C** | GCC | `gcc 13.3.0` | no (emitter pending #10) | compiles + runs ✓ | apt `build-essential` |
| **C++** | GCC / Clang | `g++ 13.3.0`, `clang++ 18.1.3` | no (emitter pending #10) | compiles + runs ✓ | apt `build-essential` / `clang` |
| **Java** | JDK | `javac 21.0.11` (JDK 21.0.11+10) | no (emitter pending #10) | **compiles + runs ✓** | apt `openjdk-21-jdk-headless` (compiler only, no AWT/X11; followup item 1) |
| **Go** | Go toolchain | **missing** | no (emitter pending #10) | — | `apt install golang-go` **or** the official tarball to `~/go` |
| **Rust** | rustc / cargo | `1.96.0` (stable; rustfmt `1.9.0`) | no (emitter pending #10) | **builds + runs ✓** (`cargo new`+`run`) | `rustup` (per-user, `~/.cargo`; `~/.cargo/env` sourced from `.bashrc`/`.profile`) — followup item 2 |

### Reading the matrix

- **"Verified"** is the strongest check actually run:
  - *builds + analyzes / compiles + imports* — the real `v0` project was built
    and exercised (only **Dart** and **Python** have `v0` projects today, per D24).
  - *compiles + runs ✓ / runtime smoke ✓* — a trivial hello-world was compiled
    and/or run to confirm the toolchain works, even though no SOM `v0` project
    exists for that language yet.
- **"`v0` project exists?"** tracks plan item #10 (typed emitters). Only Dart and
  Python emitters exist; the other seven are **blocked on their emitter**, not on
  the toolchain. The toolchain column is therefore the *forward* requirement: it
  records what will be needed the moment each emitter lands.

## Why only Dart + Python are "Done"

Step 12's done-condition — *each toolchain builds its `v0` project and runs its
tests* — can only be satisfied where a `v0` project exists. Per **D24** that is
Dart and Python alone. Installing JDK-compiler / Go / Rust **now**, with no
generated code for them to build, would be speculative: there is nothing to
compile, no tests to run, and they sit on a shared fleet host. The honest
delivery is therefore:

1. **Verify + record** the two toolchains that have projects (Dart, Python) — done.
2. **Inventory + smoke-verify** the toolchains already present (Node, GCC, Clang,
   JRE) and document their versions/provenance — done.
3. **Document the install path** for the remaining missing toolchain (Go) so
   installation is a one-liner the moment the corresponding emitter (item #10)
   produces a `v0` project to build. Installation itself is deferred to that
   point.

> **Update (followup items 1, 2).** The **Java** compiler
> (`openjdk-21-jdk-headless`, `javac 21.0.11`) and the **Rust** toolchain
> (`rustup` stable, `rustc`/`cargo` `1.96.0`) have since been installed on
> `bomber` ahead of their `v0` projects, per follow-up items 1 and 2 of
> `multiplatform_spec_model_followup.md`. This deliberately moves ahead of the
> D25 "install only when there is code to build" posture for those two languages;
> see `multiplatform_spec_model_decisions.md`. **Go** remains deferred to its own
> follow-up item (3).

## Verification commands

The exact checks used to populate the matrix (re-runnable on any host):

```bash
# Dart v0 — build + analyze
cd tom_ai/ai_build/tom_som_dart_v0 && dart pub get && dart analyze

# Python v0 — compile + import against the generic runtime
cd tom_ai/ai_build
python3 -m py_compile tom_som_python_v0/tom_som_python_v0.py
PYTHONPATH="tom_som_python_runtime:tom_som_python_v0" \
  python3 -c "import tom_som_python_v0 as m; print(hasattr(m,'ProjectDefinition'))"

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
```

## Installing the missing toolchains (when their emitter lands)

```bash
# Java — JDK compiler (adds javac; JRE 21 already present)
#   headless = compiler only, no AWT/X11 — the right choice for a build host.
#   Installed on bomber via the root admin path (sudo needs a password here).
sudo apt-get install -y openjdk-21-jdk-headless   # or openjdk-21-jdk for the full GUI JDK

# Go — apt (system) or the official tarball (per-user, newer)
sudo apt-get install -y golang-go
#   or: curl -fsSL https://go.dev/dl/goX.Y.Z.linux-amd64.tar.gz | tar -C ~/ -xz

# Rust — rustup (per-user, recommended; installs into ~/.cargo). Installed on
#   bomber with --no-modify-path, then `. "$HOME/.cargo/env"` was appended to
#   ~/.bashrc and ~/.profile so the wiring is explicit/auditable rather than a
#   rustup-injected block.
curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
  | sh -s -- -y --no-modify-path --default-toolchain stable --profile default
printf '\n. "$HOME/.cargo/env"\n' >> ~/.bashrc
printf '\n. "$HOME/.cargo/env"\n' >> ~/.profile

# TypeScript — project-local dev dependency (preferred) or global
npm i -D typescript      # in the tom_som_typescript_* project
#   or: npm i -g typescript
```

After installing, re-run the relevant verification command above, update this
matrix with the captured version, and tick the language in plan item #12.
