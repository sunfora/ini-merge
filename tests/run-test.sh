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
guile -e main -s src/project-management/ini-merge.scm tests/base.ini tests/override.ini > tests/actual.tmp

echo "Comparing script output against cached expected.ini baseline..."

if diff -u tests/expected.ini tests/actual.tmp; then
    echo "SUCCESS: Output matches cached version perfectly!"
    rm -f tests/actual.tmp
    exit 0
else
    echo "FAILURE: Output does not match cached version!"
    rm -f tests/actual.tmp
    exit 1
fi
