# This file is used by R CMD check to run the tests.
# It loads the testthat package and runs all tests in the testthat/ subdirectory.

library(testthat)

# Source the main setup file
source("tests/setup.R")

# Run all tests
test_dir("tests/testthat", reporter = "progress")
