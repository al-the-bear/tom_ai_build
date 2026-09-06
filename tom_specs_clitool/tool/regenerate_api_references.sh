#!/usr/bin/env bash
#
# regenerate_api_references.sh — the generated API reference for every SOM
# language package (tom_specs_documentation_standard.md §5).
#
# Eighteen targets: the nine hand-written `tom_som_<lang>_runtime` packages and
# the nine generated `tom_som_<lang>_v0` facades. Each language has its own
# documentation generator, and each writes into `<package>/doc/api/reference/`.
#
# The output is DELIBERATELY GITIGNORED. See som_toolchains.md,
# "Documentation generation", for the reason: a dartdoc tree alone is ~7 MB, the
# eighteen together are well over a hundred, and every byte of it regenerates
# from source in seconds — so committing it would trade a large, unreviewable
# diff on every source edit for nothing a reader cannot rebuild.
#
# A toolchain that is not installed produces a SKIP with the reason stated,
# never a silent pass — the same discipline `tom_som_conformance`'s
# `run_all_suites.sh` uses, and for the same reason: on a partially-provisioned
# host a skip that reads as a pass is worse than no gate.
#
# Usage:
#   tool/regenerate_api_references.sh [--strict] [--list] [target ...]
#
#   --strict   A skipped target is a failure. Use on a host claiming full
#              coverage.
#   --list     Print every target name and exit.
#   target...  Package names without the `tom_som_` prefix, e.g.
#              `dart_runtime rust_v0`. With none given, all eighteen run.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"      # tom_specs_clitool/tool
CLITOOL="$(dirname "$HERE")"                # tom_specs_clitool
ROOT="$(dirname "$CLITOOL")"                # ai_build (holds every SOM project)

# rustup and the Go tarball wire themselves into the *interactive* shell profile
# only, so a non-interactive run would skip languages this host can perfectly
# well document. Same prepend as run_all_suites.sh and regenerate_golden.sh.
for extra in "$HOME/.cargo/bin" "/usr/local/go/bin" "$HOME/.local/go/bin" "/opt/homebrew/bin"; do
  case ":$PATH:" in *":$extra:"*) ;; *) [ -d "$extra" ] && PATH="$PATH:$extra" ;; esac
done
if ! command -v javadoc > /dev/null 2>&1 && [ -x /usr/libexec/java_home ]; then
  JH="$(/usr/libexec/java_home 2>/dev/null || true)"
  [ -n "$JH" ] && [ -x "$JH/bin/javadoc" ] && PATH="$JH/bin:$PATH"
fi
export PATH

# The typedoc version is pinned so every host renders the same reference; an
# unpinned `npx typedoc` would silently follow the registry's latest.
TYPEDOC_VERSION="${TYPEDOC_VERSION:-0.28.15}"

LANGS=(dart python javascript typescript go rust java c cpp)
TARGETS=()
for lang in "${LANGS[@]}"; do
  TARGETS+=("${lang}_runtime" "${lang}_v0")
done

STRICT=0
SELECTED=()
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --list)   printf '%s\n' "${TARGETS[@]}"; exit 0 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *)  SELECTED+=("$1") ;;
  esac
  shift
done
[ ${#SELECTED[@]} -gt 0 ] && TARGETS=("${SELECTED[@]}")

RESULTS=()
fail=0
skipped=0

record() { RESULTS+=("$1 $2 $3"); }

# --- per-language generators -------------------------------------------------
#
# Each takes the absolute package directory and writes into <pkg>/doc/api/
# reference/. Each returns 0 on success, 1 on failure, 3 when the toolchain is
# absent (the caller turns 3 into SKIP, or into FAIL under --strict).

need() { command -v "$1" > /dev/null 2>&1; }

gen_dart() {
  need dart || { echo "dart not on PATH"; return 3; }
  # Resolve ONLY when there is no resolution. An unconditional `dart pub get`
  # here was observed to disturb a *sibling* package's resolution — these
  # packages share a pub cache and resolve each other by path override, and
  # afterwards `tom_specs_clitool` failed to compile the analyzer until it was
  # re-resolved. Generating a reference must not have side effects on packages
  # it is not documenting.
  ( cd "$1" \
    && { [ -f .dart_tool/package_config.json ] || dart pub get > /dev/null 2>&1; } \
    && dart doc --output "doc/api/reference" > /dev/null 2>&1 )
}

gen_python() {
  need pdoc || { echo "pdoc not installed (pip install pdoc)"; return 3; }
  # The importable name is not the directory name: the runtime ships the
  # package `tom_som_runtime/`, the facade the module `tom_som_python_v0.py`.
  # Discover it rather than assume, and skip the build/test trees.
  local mods=()
  local d f
  for d in "$1"/*/; do
    [ -f "$d/__init__.py" ] || continue
    case "$(basename "$d")" in build|tests|dist|*.egg-info) continue ;; esac
    mods+=("$(basename "$d")")
  done
  for f in "$1"/tom_som_*.py; do
    [ -f "$f" ] || continue
    mods+=("$(basename "${f%.py}")")
  done
  [ ${#mods[@]} -gt 0 ] || { echo "no importable python module found"; return 1; }
  # The facade imports the runtime, so both roots have to be on the path.
  ( cd "$1" \
    && PYTHONPATH="$1:$ROOT/tom_som_python_runtime:${PYTHONPATH:-}" \
       pdoc -o doc/api/reference "${mods[@]}" > /dev/null 2>&1 )
}

gen_typedoc() {   # javascript + typescript
  need npx || { echo "npx not on PATH (Node.js not installed)"; return 3; }
  # The entry point is whatever `package.json` declares as `main`, falling back
  # to the conventional layouts. Reading the manifest first is what makes this
  # work for both npm packages here: the TypeScript runtime's entry is
  # `src/index.ts`, the JavaScript runtime's is `tom_som_runtime/index.js`.
  local entry=""
  local allow_js=""
  if [ -f "$1/package.json" ]; then
    entry="$(sed -n 's/.*"main"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
             "$1/package.json" | head -1)"
    # `main` points at built output for a TS package; prefer the source twin.
    case "$entry" in
      dist/*) [ -f "$1/${entry#dist/}" ] && entry="${entry#dist/}"
              entry="${entry%.js}.ts"
              [ -f "$1/$entry" ] || entry="" ;;
    esac
    [ -n "$entry" ] && [ -f "$1/$entry" ] || entry=""
  fi
  if [ -z "$entry" ]; then
    for candidate in src/index.ts src/index.js index.ts index.js; do
      [ -f "$1/$candidate" ] && { entry="$candidate"; break; }
    done
  fi
  if [ -z "$entry" ]; then
    for candidate in "$1"/tom_som_*.js "$1"/tom_som_*.ts; do
      [ -f "$candidate" ] && { entry="$(basename "$candidate")"; break; }
    done
  fi
  [ -n "$entry" ] || { echo "no entry point found"; return 1; }
  # A plain-JavaScript package needs `allowJs`, which is a *TypeScript compiler*
  # option and so cannot be a typedoc flag — it has to arrive through a
  # tsconfig, and that tsconfig must `include` the entry point or typedoc
  # reports "unable to find any entry points". Written next to the entry so the
  # relative include resolves, and removed afterwards.
  local tscfg="" entry_dir
  if [ "${entry##*.}" = js ]; then
    entry_dir="$1/$(dirname "$entry")"
    tscfg="$entry_dir/.typedoc-tsconfig.json"
    cat > "$tscfg" <<'TSCFG'
{ "compilerOptions": { "allowJs": true, "checkJs": false, "noEmit": true,
  "target": "ES2022", "module": "CommonJS", "moduleResolution": "node" },
  "include": ["**/*.js"] }
TSCFG
    allow_js="--tsconfig $(dirname "$entry")/.typedoc-tsconfig.json"
  fi
  ( cd "$1" && rm -rf doc/api/reference \
      && npx --yes "typedoc@$TYPEDOC_VERSION" \
           --out doc/api/reference --skipErrorChecking --excludePrivate \
           $allow_js "$entry" > /dev/null 2>&1
    # typedoc exits non-zero on *warnings* as well as errors, and the SOM
    # sources warn routinely (doc links to built-in types it does not export).
    # The question that matters is whether a reference was rendered, so ask
    # that directly rather than reading a status that conflates the two.
    [ -f doc/api/reference/index.html ] )
  local rc=$?
  [ -n "$tscfg" ] && rm -f "$tscfg"
  return $rc
}

gen_go() {
  need go || { echo "go not on PATH"; return 3; }
  # `go doc` renders text, not an HTML tree — it is what the Go ecosystem has
  # locally (pkg.go.dev is the hosted equivalent), so the reference here is one
  # rendered text file rather than a site.
  ( cd "$1" && mkdir -p doc/api/reference \
      && go doc -all . > doc/api/reference/index.txt 2>/dev/null )
}

gen_rust() {
  need cargo || { echo "cargo not on PATH"; return 3; }
  # cargo insists on writing into a target dir; copy the rendered tree out so
  # the reference sits where every other language's does.
  ( cd "$1" && cargo doc --no-deps --quiet > /dev/null 2>&1 \
      && rm -rf doc/api/reference && mkdir -p doc/api \
      && cp -R target/doc doc/api/reference )
}

gen_java() {
  need javadoc || { echo "javadoc not on PATH (no JDK)"; return 3; }
  [ -d "$1/src" ] || { echo "no src/ directory"; return 1; }
  # The runtime ships `tom_som_runtime`, the facade `tom_som_java_v0`; naming
  # both would fail on whichever package the target does not have, so read the
  # package name off the source tree instead of assuming it.
  local pkgs sourcepath="src"
  pkgs="$(cd "$1/src" && ls -d */ 2>/dev/null | tr -d '/' | paste -sd: -)"
  [ -n "$pkgs" ] || { echo "no java package under src/"; return 1; }
  # The facade's sources reference the runtime's types, so the runtime's src
  # has to be on the sourcepath — without it javadoc reports a hundred
  # unresolved symbols and writes nothing. Only the named subpackages are
  # documented, so adding it widens resolution without widening output.
  if [ -d "$1/../tom_som_java_runtime/src" ] && [ "$(basename "$1")" != tom_som_java_runtime ]; then
    sourcepath="src:../tom_som_java_runtime/src"
  fi
  # -Xdoclint:none because the reference is generated from the same sources the
  # dartdoc-coverage gate already measures; a doclint failure here would be a
  # second, weaker verdict on the same question.
  ( cd "$1" && rm -rf doc/api/reference && mkdir -p doc/api/reference \
      && javadoc -d doc/api/reference -quiet -Xdoclint:none \
           -sourcepath "$sourcepath" -subpackages "$pkgs" \
           > /dev/null 2>&1 )
}

gen_doxygen() {   # c + cpp
  need doxygen || { echo "doxygen not installed (brew install doxygen)"; return 3; }
  # INPUT is the public headers only, not `src`. A reference is the public
  # surface, and the generated `*_v0` implementation files run to tens of
  # thousands of lines: including them took doxygen many minutes and produced a
  # 120 MB tree for tom_som_c_v0 alone — a source browser, not a reference.
  [ -d "$1/include" ] || { echo "no include/ directory"; return 1; }
  ( cd "$1" && mkdir -p doc/api \
      && { cat <<DOXY
PROJECT_NAME    = "$(basename "$1")"
OUTPUT_DIRECTORY = doc/api
HTML_OUTPUT     = reference
GENERATE_LATEX  = NO
RECURSIVE       = YES
INPUT           = include
QUIET           = YES
WARNINGS        = NO
SOURCE_BROWSER  = NO
VERBATIM_HEADERS = NO
DOXY
      } | doxygen - > /dev/null 2>&1 )
}

generate_for() {
  local target="$1" lang="${1%_*}" dir="$ROOT/tom_som_$1" reason
  [ -d "$dir" ] || { record "$target" MISSING "no such package"; fail=1; return; }
  case "$lang" in
    dart)                 reason="$(gen_dart "$dir")"    ;;
    python)               reason="$(gen_python "$dir")"  ;;
    javascript|typescript) reason="$(gen_typedoc "$dir")" ;;
    go)                   reason="$(gen_go "$dir")"      ;;
    rust)                 reason="$(gen_rust "$dir")"    ;;
    java)                 reason="$(gen_java "$dir")"    ;;
    c|cpp)                reason="$(gen_doxygen "$dir")" ;;
    *) record "$target" MISSING "unknown language"; fail=1; return ;;
  esac
  local rc=$?
  case $rc in
    0) record "$target" OK "doc/api/reference" ;;
    3) if [ "$STRICT" = 1 ]; then
         record "$target" FAIL "toolchain absent: ${reason:-unknown}"; fail=1
       else
         record "$target" SKIP "${reason:-toolchain absent}"; skipped=$((skipped+1))
       fi ;;
    *) record "$target" FAIL "${reason:-generator exited $rc}"; fail=1 ;;
  esac
}

for t in "${TARGETS[@]}"; do
  echo "== $t =="
  generate_for "$t"
done

echo
echo "== api reference summary =="
for row in "${RESULTS[@]}"; do
  set -- $row
  printf '  %-4s %-22s %s\n' "$2" "$1" "${*:3}"
done
echo
echo "  output: <package>/doc/api/reference/  (gitignored — see som_toolchains.md)"

if [ "$fail" = 1 ]; then
  echo "FAILED: at least one target could not be generated."
  exit 1
fi
if [ "$skipped" -gt 0 ]; then
  echo "OK — generated what this host can; $skipped target(s) skipped with a reason above."
else
  echo "OK — every target generated."
fi
