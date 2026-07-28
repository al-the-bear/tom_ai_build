#!/usr/bin/env bash
# Runs everything hand-authored in this package: `dart test` over test/, which
# includes the shared-corpus conformance suite and every unit test.
#
# This is the cross-language uniform entry point the aggregate driver
# (tom_som_conformance/tool/run_all_suites.sh) calls; `testkit :test` remains
# the workspace's tracking runner for day-to-day Dart work.
#
# Exit 0 == all green.
set -euo pipefail
cd "$(dirname "$0")"

dart pub get --offline > /dev/null 2>&1 || dart pub get
dart test
