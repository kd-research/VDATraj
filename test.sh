#!/usr/bin/env bash
# Clean test runner that filters out nix-shell messages

nix-shell --quiet --command "Rscript tests/run_unit_tests.R" 2>&1 | \
  grep -v "^warning:" | \
  grep -v "^To start R:" | \
  grep -v "^To load your function:"

