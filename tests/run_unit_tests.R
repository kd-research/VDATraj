#!/usr/bin/env Rscript
# Run all unit tests for the find-variance project
#
# This script runs the complete test suite using testthat
# and provides a summary of results.
#
# Usage:
#   Rscript tests/run_unit_tests.R
#   or
#   nix run . -- tests/run_unit_tests.R

suppressPackageStartupMessages(library(testthat))

cat("=======================================================\n")
cat("  Find-Variance Project - Unit Test Suite\n")
cat("=======================================================\n\n")

# Source setup to load all dependencies
cat("Loading dependencies...\n")
source("tests/setup.R")
cat("✓ Dependencies loaded\n\n")

# Run all tests
cat("Running unit tests...\n")
cat("-------------------------------------------------------\n")

test_results <- test_dir(
  "tests/testthat",
  reporter = "summary",
  stop_on_failure = FALSE
)

cat("\n=======================================================\n")
cat("  Test Summary\n")
cat("=======================================================\n")

# Print summary
if (is.null(test_results)) {
  cat("✓ All tests passed!\n")
} else {
  summary_df <- as.data.frame(test_results)

  # Print concise summary
  total_tests <- sum(summary_df$nb)
  passed <- sum(summary_df$passed)
  failed <- sum(summary_df$failed)
  warnings <- sum(summary_df$warning)
  skipped <- sum(summary_df$skipped)

  cat(sprintf("Total: %d tests\n", total_tests))
  cat(sprintf("✓ Passed: %d\n", passed))
  if (failed > 0) cat(sprintf("✗ Failed: %d\n", failed))
  if (warnings > 0) cat(sprintf("⚠ Warnings: %d\n", warnings))
  if (skipped > 0) cat(sprintf("○ Skipped: %d\n", skipped))

  # Check if any failures
  if (any(summary_df$failed > 0)) {
    cat("\n✗ Some tests failed. Please review the output above.\n")
    quit(status = 1)
  } else if (any(summary_df$warning > 0)) {
    cat("\n⚠ Some tests produced warnings. Please review.\n")
  } else {
    cat("\n✓ All tests passed!\n")
  }
}

cat("\nTest suite completed.\n")
