#!/usr/bin/env bash
#
# provision_doc_generators.sh — the eight documentation generators that
# regenerate_api_references.sh drives (som_toolchains.md, "Documentation
# generation"), reported on and, where a host is missing one, installed.
#
# WHY A SCRIPT. Bringing a host up used to be a reading exercise: som_toolchains
# .md records what `mbp` carries and how each generator was obtained, and a
# person had to turn that prose into commands again per host. Two of the eight
# are the only real work — `pdoc` and `doxygen`; the other six ship with a
# toolchain the host already needs, or, in typedoc's case, are deliberately
# never installed (the driver runs `npx --yes typedoc@<pinned>`).
#
# The PDOC SUBTLETY, worth not rediscovering: pdoc *imports* the module rather
# than parsing it, so the interpreter that runs it needs the Python runtime's
# own dependencies (PyYAML) installed FOR THAT INTERPRETER; and it must be
# Python >= 3.10, because the runtime's sources use PEP 604 `X | Y` annotations
# that pdoc evaluates. That is why this reports the interpreter behind pdoc
# rather than just "pdoc 16.0.0" — the version alone cannot tell a working
# install from one that will fail at import.
#
# It reports by default and installs only when asked, because a script that
# changes a host as a side effect of being asked a question is one nobody dares
# run on a server.
#
# Usage:
#   tool/provision_doc_generators.sh              # report; exit 1 if any missing
#   tool/provision_doc_generators.sh --install    # install what is missing
#   tool/provision_doc_generators.sh --install --dry-run   # print the commands
#   tool/provision_doc_generators.sh --markdown   # the som_toolchains.md table
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/doc_toolchain_path.sh"

TYPEDOC_VERSION="${TYPEDOC_VERSION:-0.28.15}"

MODE=report
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --install)  MODE=install ;;
    --markdown) MODE=markdown ;;
    --dry-run)  DRY_RUN=1 ;;
    -h|--help)  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

first_line() { "$@" 2>&1 | head -1; }

# The interpreter that would run pdoc, which is not necessarily `python3`:
# `pdoc` on PATH is a console script with its own shebang, and that shebang is
# the interpreter whose site-packages must hold PyYAML.
pdoc_interpreter() {
  local bin
  bin="$(command -v pdoc 2> /dev/null)" || return 1
  local shebang
  shebang="$(head -1 "$bin" 2> /dev/null)"
  case "$shebang" in
    '#!'*) echo "${shebang#\#!}" | awk '{print $1}' ;;
    *) command -v python3 ;;
  esac
}

# --- the eight generators ----------------------------------------------------
# Each prints: <name>|<status>|<version>|<how obtained>
#   status: present | missing | not-installed-by-design

probe_dart() {
  if command -v dart > /dev/null 2>&1; then
    echo "dart doc|present|ships with Dart $(first_line dart --version | sed 's/^Dart SDK version: //;s/ .*//')|fleet-managed SDK"
  else
    echo "dart doc|missing||the Dart SDK (fleet-managed)"
  fi
}

probe_pdoc() {
  if ! command -v pdoc > /dev/null 2>&1; then
    echo "pdoc|missing||$(pdoc_install_hint)"
    return
  fi
  local interp pyver yaml_ok note
  interp="$(pdoc_interpreter)"
  pyver="$("$interp" -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])' 2>/dev/null)"
  if "$interp" -c 'import yaml' > /dev/null 2>&1; then yaml_ok=yes; else yaml_ok=NO; fi
  note="on $(basename "$interp") $pyver"
  # Both preconditions are checkable, and a failing one is worse than absence:
  # pdoc runs and renders something wrong or dies at import.
  case "$pyver" in
    3.[0-9].*|3.[0-9]) note="$note — TOO OLD, pdoc needs >= 3.10" ;;
  esac
  [ "$yaml_ok" = NO ] && note="$note — PyYAML MISSING for this interpreter"
  echo "pdoc|present|$(first_line pdoc --version | awk '{print $NF}') $note|$(pdoc_install_hint)"
}

probe_typedoc() {
  if command -v npx > /dev/null 2>&1; then
    echo "typedoc|not-installed-by-design|pinned $TYPEDOC_VERSION, run via npx|npx --yes typedoc@$TYPEDOC_VERSION (never installed globally)"
  else
    echo "typedoc|missing|pinned $TYPEDOC_VERSION|needs Node.js for npx"
  fi
}

probe_go() {
  if command -v go > /dev/null 2>&1; then
    echo "go doc|present|ships with $(first_line go version | awk '{print $3}' | sed 's/^go//')|the Go toolchain"
  else
    echo "go doc|missing||the Go toolchain"
  fi
}

probe_cargo() {
  if command -v cargo > /dev/null 2>&1; then
    echo "cargo doc|present|ships with $(first_line cargo --version | awk '{print $2}')|rustup"
  else
    echo "cargo doc|missing||rustup"
  fi
}

probe_javadoc() {
  if command -v javadoc > /dev/null 2>&1; then
    echo "javadoc|present|$(first_line javadoc --version | awk '{print $NF}')|the JDK"
  else
    echo "javadoc|missing||the JDK"
  fi
}

probe_doxygen() {
  if command -v doxygen > /dev/null 2>&1; then
    echo "doxygen|present|$(first_line doxygen --version | awk '{print $1}')|$(doxygen_install_hint)"
  else
    echo "doxygen|missing||$(doxygen_install_hint)"
  fi
}

# --- install hints and commands, per platform --------------------------------

pkg_manager() {
  if command -v apt-get > /dev/null 2>&1; then echo apt
  elif command -v brew > /dev/null 2>&1; then echo brew
  elif command -v dnf > /dev/null 2>&1; then echo dnf
  else echo unknown
  fi
}

doxygen_install_hint() {
  case "$(pkg_manager)" in
    apt) echo "apt install doxygen" ;;
    brew) echo "brew install doxygen" ;;
    dnf) echo "dnf install doxygen" ;;
    *) echo "the host package manager" ;;
  esac
}

pdoc_install_hint() {
  case "$(pkg_manager)" in
    apt|dnf) echo "python3 -m pip install --break-system-packages pdoc PyYAML" ;;
    brew) echo "python3 -m pip install --break-system-packages pdoc PyYAML against the default python3" ;;
    *) echo "pip install pdoc PyYAML" ;;
  esac
}

# The install commands themselves. PyYAML travels with pdoc deliberately: the
# import-not-parse behaviour above makes it a dependency of DOCUMENTING, not
# only of running, the Python runtime.
install_doxygen_cmd() {
  case "$(pkg_manager)" in
    apt) echo "$SUDO apt-get install -y doxygen" ;;
    brew) echo "brew install doxygen" ;;
    dnf) echo "$SUDO dnf install -y doxygen" ;;
    *) echo "" ;;
  esac
}

install_pdoc_cmd() {
  local py
  py="$(command -v python3 || true)"
  [ -n "$py" ] || { echo ""; return; }
  echo "$py -m pip install --break-system-packages pdoc PyYAML"
}

PROBES=(probe_dart probe_pdoc probe_typedoc probe_go probe_cargo probe_javadoc probe_doxygen)

SUDO=""
[ "$(id -u)" = 0 ] || command -v sudo > /dev/null 2>&1 && SUDO="${SUDO:-sudo}"
[ "$(id -u)" = 0 ] && SUDO=""

collect() {
  local p
  ROWS=()
  for p in "${PROBES[@]}"; do ROWS+=("$($p)"); done
}

missing_count() {
  local row n=0
  for row in "${ROWS[@]}"; do
    case "$(echo "$row" | cut -d'|' -f2)" in missing) n=$((n + 1)) ;; esac
  done
  echo "$n"
}

collect

if [ "$MODE" = markdown ]; then
  # The som_toolchains.md "Documentation toolchains on <host>" table, so the
  # document records what the host actually carries rather than what someone
  # remembered installing.
  echo "| Generator | On \`$(hostname -s 2>/dev/null || hostname)\` | How obtained |"
  echo "| --- | --- | --- |"
  for row in "${ROWS[@]}"; do
    name="$(echo "$row" | cut -d'|' -f1)"
    status="$(echo "$row" | cut -d'|' -f2)"
    version="$(echo "$row" | cut -d'|' -f3)"
    how="$(echo "$row" | cut -d'|' -f4)"
    case "$status" in
      missing) version="**MISSING**" ;;
      not-installed-by-design) version="$version, **no host install**" ;;
    esac
    echo "| \`$name\` | $version | $how |"
  done
  exit 0
fi

printf '%-10s %-24s %s\n' GENERATOR STATUS DETAIL
for row in "${ROWS[@]}"; do
  name="$(echo "$row" | cut -d'|' -f1)"
  status="$(echo "$row" | cut -d'|' -f2)"
  version="$(echo "$row" | cut -d'|' -f3)"
  how="$(echo "$row" | cut -d'|' -f4)"
  case "$status" in
    present) printf '%-10s %-24s %s\n' "$name" "present" "$version" ;;
    not-installed-by-design) printf '%-10s %-24s %s\n' "$name" "by design: no install" "$version" ;;
    missing) printf '%-10s %-24s %s\n' "$name" "MISSING" "install: $how" ;;
  esac
done
echo
echo "host: $(hostname -s 2>/dev/null || hostname)  package manager: $(pkg_manager)"

if [ "$MODE" = report ]; then
  n="$(missing_count)"
  if [ "$n" -gt 0 ]; then
    echo "$n generator(s) missing — run with --install, or install by hand from the column above."
    exit 1
  fi
  echo "all eight generators available."
  exit 0
fi

# --- install -----------------------------------------------------------------
# Only the two that are ever a host install. The other six are a toolchain the
# host needs anyway (dart/go/cargo/javadoc), or typedoc, which is never
# installed. A missing one of those is a toolchain gap, not a documentation gap,
# and the status matrix in som_toolchains.md is where it belongs.
status_of() {
  local row
  for row in "${ROWS[@]}"; do
    [ "$(echo "$row" | cut -d'|' -f1)" = "$1" ] && { echo "$row" | cut -d'|' -f2; return; }
  done
}

run_or_show() {
  [ -n "$1" ] || { echo "  (no install command for this platform — install by hand)"; return 1; }
  echo "  \$ $1"
  [ "$DRY_RUN" = 1 ] && return 0
  sh -c "$1"
}

rc=0
if [ "$(status_of pdoc)" = missing ]; then
  echo "installing pdoc (with PyYAML, which pdoc needs because it imports the module):"
  run_or_show "$(install_pdoc_cmd)" || rc=1
else
  echo "pdoc: already present"
fi
if [ "$(status_of doxygen)" = missing ]; then
  echo "installing doxygen:"
  run_or_show "$(install_doxygen_cmd)" || rc=1
else
  echo "doxygen: already present"
fi

if [ "$DRY_RUN" = 1 ]; then
  echo
  echo "dry run: nothing was installed."
  exit 0
fi

echo
echo "re-probing:"
collect
for row in "${ROWS[@]}"; do
  printf '  %-10s %s\n' "$(echo "$row" | cut -d'|' -f1)" "$(echo "$row" | cut -d'|' -f2)"
done
n="$(missing_count)"
[ "$n" -gt 0 ] && { echo "$n still missing."; exit 1; }
echo "all eight generators available."
exit $rc
