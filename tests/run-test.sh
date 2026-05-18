#!/usr/bin/env bash
set -euo pipefail

# Ensure we are running from the repository root directory context
CDPATH= cd -- "$(dirname -- "$0")/.."

# Check if we are running inside the Guix build daemon jail.
# If we aren't, we spin up a local guix shell manually.
if [ -z "${GUIX_ENVIRONMENT:-}" ]; then
    exec guix shell guile guile-ini -- "$0" "$@"
fi

# The pure execution pipeline used by both you and the build jail:

export GUILE_LOAD_PATH=".:$GUILE_LOAD_PATH"

# Test overrides 
guile -s main.scm tests/base.ini tests/override.ini > tests/actual.tmp

if diff -u tests/expected.ini tests/actual.tmp; then
    echo "SUCCESS[override]"
    rm -f tests/actual.tmp
else
    echo "FAILURE[override]: Output does not match cached version!"
    rm -f tests/actual.tmp
    exit 1
fi

# Test one param normalization 
guile -s main.scm tests/base.ini > tests/actual.tmp
if diff -u tests/expected_solo.ini tests/actual.tmp; then
    echo "SUCCESS[solo]"
    rm -f tests/actual.tmp
else
    echo "FAILURE[solo]: Output does not match cached version!"
    rm -f tests/actual.tmp
    exit 1
fi
