#!/usr/bin/env bash
# The memory check of this port: AddressSanitizer + UBSan, then a leak checker
# (see ../../tool/native_memcheck.sh). tool/run_all_samples.sh runs it after the
# output comparison; --strict makes a skip a failure.
cd "$(dirname "$0")/.." && exec ../../tool/native_memcheck.sh "$@"
