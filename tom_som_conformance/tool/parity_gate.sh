#!/usr/bin/env bash
#
# parity_gate.sh — prove that a corpus table is actually load-bearing.
#
# A green suite in nine languages proves nothing about a corpus table unless
# every runner genuinely reads it: a runner that never reaches the table passes
# exactly as loudly as one that replays it correctly. Check counts cannot settle
# it either — each runner's base count differs, so two matching numbers are a
# coincidence, not evidence.
#
# So: flip one expectation the reference genuinely produces, and require the
# named suites to ALL go red. Any suite that stays green is not reading the
# table. Restores the corpus unconditionally on exit.
#
# Usage:
#   tool/parity_gate.sh --corpus <file> --from <regex> --to <text> [suite ...]
#
#   --corpus  Corpus file to mutate, relative to corpus/ (or an absolute path).
#   --from    Perl regex matched against the whole file. Must match EXACTLY
#             once — a mutation that hits two places, or none, is not a
#             controlled experiment, so the script refuses to run.
#   --to      Replacement text.
#   suite...  Suites that must go red. Defaults to the nine *_runtime suites.
#
# Example — the editor tier's integral-double rule (`2.0`, never `2`), the one
# a single-numeric-type port gets wrong by default:
#
#   tool/parity_gate.sh --corpus editor_cases.json \
#     --from '"expect": "2\.0"' --to '"expect": "2"'
#
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$HERE/.." && pwd)"

CORPUS_ARG=""
FROM=""
TO=""
SUITES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --corpus) CORPUS_ARG="$2"; shift 2 ;;
    --from)   FROM="$2";       shift 2 ;;
    --to)     TO="$2";         shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *)  SUITES+=("$1"); shift ;;
  esac
done

if [ -z "$CORPUS_ARG" ] || [ -z "$FROM" ] || [ -z "$TO" ]; then
  echo "usage: $0 --corpus <file> --from <regex> --to <text> [suite ...]" >&2
  exit 2
fi

if [ ${#SUITES[@]} -eq 0 ]; then
  SUITES=(dart_runtime python_runtime javascript_runtime typescript_runtime
          java_runtime go_runtime rust_runtime c_runtime cpp_runtime)
fi

case "$CORPUS_ARG" in
  /*) CORPUS="$CORPUS_ARG" ;;
  *)  CORPUS="$PROJECT/corpus/$CORPUS_ARG" ;;
esac

if [ ! -f "$CORPUS" ]; then
  echo "FATAL: no such corpus file: $CORPUS" >&2
  exit 2
fi

BACKUP="$(mktemp "${TMPDIR:-/tmp}/parity_gate.XXXXXX")"
cleanup() {
  if [ -f "$BACKUP" ]; then
    cp "$BACKUP" "$CORPUS"
    rm -f "$BACKUP"
    echo "corpus restored"
  fi
}
trap cleanup EXIT INT TERM
cp "$CORPUS" "$BACKUP"

# The mutation must be unique: a controlled experiment changes one thing.
hits=$(FROM="$FROM" perl -0ne '$n++ while /$ENV{FROM}/g; END{print $n+0}' "$CORPUS")
if [ "$hits" != "1" ]; then
  echo "FATAL: --from matched $hits times in $(basename "$CORPUS"); expected exactly 1." >&2
  exit 2
fi

FROM="$FROM" TO="$TO" perl -0pi -e 's/$ENV{FROM}/$ENV{TO}/' "$CORPUS"
echo "corpus mutated: $(basename "$CORPUS")  /$FROM/ -> $TO"
echo

LOGS="$(mktemp -d "${TMPDIR:-/tmp}/parity_gate_logs.XXXXXX")"
"$HERE/run_all_suites.sh" --log-dir "$LOGS" "${SUITES[@]}" > "$LOGS/driver.log" 2>&1
status=$?

echo "== driver exit status: $status (non-zero is REQUIRED here) =="
echo
echo "== per-suite outcome (every one must be FAIL) =="
grep -E '^\s*(PASS|FAIL|SKIP)' "$LOGS/driver.log" || tail -40 "$LOGS/driver.log"
echo

green=$(grep -cE '^\s*(PASS|SKIP)' "$LOGS/driver.log")
if [ "$green" != "0" ]; then
  echo "GATE FAILED: $green suite(s) stayed green — they are not reading $(basename "$CORPUS")."
  echo "logs: $LOGS"
  exit 1
fi

echo "GATE PASSED: all ${#SUITES[@]} suites went red on the mutated corpus."
rm -rf "$LOGS"
