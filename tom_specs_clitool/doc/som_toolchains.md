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
| **JavaScript** | Node.js | `22.22.3` (npm `10.9.8`) | **yes** (`tom_som_javascript_v0`) | **builds + runs generated `v0` ✓** (3079 classes load; behavioural + samples pass) | system `node`/`npm` |
| **TypeScript** | `tsc` (project-local npm) | **pinned `6.0.3`** (Node 22.22.3 / npm 10.9.8) | **yes** (`tom_som_typescript_v0`) | **builds + runs generated `v0` ✓** (3079 classes compile; behavioural + samples pass) | project-local `npm i -D typescript@6.0.3` — followup items 4 + 7 |
| **C** | GCC | `gcc 13.3.0` | **yes** (`tom_som_c_v0`) | **builds + runs generated `v0` ✓** (3079 classes compile; behavioural + samples pass) | apt `build-essential` — followup item 10 |
| **C++** | GCC / Clang | `g++ 13.3.0`, `clang++ 18.1.3` | **yes** (`tom_som_cpp_v0`) | **builds + runs generated `v0` ✓** (3079 classes compile; behavioural + samples pass) | apt `build-essential` / `clang` — followup item 11 |
| **Java** | JDK | `javac 21.0.11` (JDK 21.0.11+10) | **yes** (`tom_som_java_v0`) | **builds + runs generated `v0` ✓** (3079 classes compile; behavioural + samples pass) | apt `openjdk-21-jdk-headless` (compiler only, no AWT/X11; followup item 1) |
| **Go** | Go toolchain | `1.26.4` (official tarball) | **yes** (`tom_som_go_v0`) | **builds + runs generated `v0` ✓** (3079 classes compile; behavioural + samples pass) | official tarball → `~/.local/go` (per-user, sha256-verified; PATH from `.bashrc`/`.profile`) — followup items 3 + 8 |
| **Rust** | rustc / cargo | `1.96.0` (stable; rustfmt `1.9.0`) | **yes** (`tom_som_rust_v0`) | **builds + runs generated `v0` ✓** (3079 classes compile; behavioural + samples pass) | `rustup` (per-user, `~/.cargo`; `~/.cargo/env` sourced from `.bashrc`/`.profile`) — followup items 2 + 9 |

### Reading the matrix

- **"Verified"** is the strongest check actually run:
  - *builds + analyzes / compiles + imports / builds + runs generated `v0`* — the
    real `v0` project was built and exercised. **All nine languages** (Dart,
    Python, Java, JavaScript, TypeScript, Go, Rust, C, C++) now have `v0`
    projects (D24/D32/D33/D34/D35/D36/D37/D38).
  - *compiles + runs ✓ / runtime smoke ✓* — a trivial hello-world was compiled
    and/or run to confirm the toolchain works, even though no SOM `v0` project
    exists for that language yet.
- **"`v0` project exists?"** tracks plan item #10 (typed emitters). All nine
  emitters now exist (Dart, Python, Java, JavaScript, TypeScript, Go, Rust, C,
  C++); no language remains emitter-pending.

## All nine languages are "Done"

Step 12's done-condition — *each toolchain builds its `v0` project and runs its
tests* — is now satisfied for **all nine languages**. Per
**D24/D32/D33/D34/D35/D36/D37/D38** the `v0` projects landed one per follow-up
item: Java (item 5), JavaScript (6), TypeScript (7), Go (8), Rust (9), C (10),
and C++ (11), alongside the Dart + Python references. No language remains
emitter-pending. The historical honest-delivery sequence was:

1. **Verify + record** the two toolchains that have projects (Dart, Python) — done.
2. **Inventory + smoke-verify** the toolchains already present (Node, GCC, Clang,
   JRE) and document their versions/provenance — done.
3. **Document the install path** for each toolchain so a rebuild is a one-liner.
   All language compilers/runtimes are now present on `bomber`, and **TypeScript**'s
   project-local `tsc` route is pinned (`typescript@6.0.3`) and fixture-verified
   (followup item 4). TypeScript stays a project-local devDependency that lands
   with the TS `v0` project, not a host toolchain — so no host gaps remain.

> **Update (followup items 1, 2, 3, 4).** The **Java** compiler
> (`openjdk-21-jdk-headless`, `javac 21.0.11`), the **Rust** toolchain
> (`rustup` stable, `rustc`/`cargo` `1.96.0`), and the **Go** toolchain
> (official tarball, `go 1.26.4`) have all since been installed on `bomber` ahead
> of their `v0` projects, per follow-up items 1–3 of
> `multiplatform_spec_model_followup.md`. This deliberately moves ahead of the
> D25 "install only when there is code to build" posture for those languages;
> see `multiplatform_spec_model_decisions.md`. **TypeScript** (followup item 4) is
> the one toolchain that is intentionally **not** a host install: its `tsc` is a
> project-local devDependency pinned to `typescript@6.0.3`, verified via the
> fixture smoke below. With that, **every target language's build path is
> accounted for** — eight host toolchains plus TypeScript's project-local `tsc`.

## Packaging build tools (PGK sign-off)

The **compile/run** matrix above covers each language's compiler/runtime. The
**packaging** sign-off sweep (roadmap item PGK11) additionally exercises each
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

After installing, re-run the relevant verification command above, update this
matrix with the captured version, and tick the language in plan item #12.
