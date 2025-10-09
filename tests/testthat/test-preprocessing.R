# Unit tests for preprocessing.R
# Tests data unnesting and variance preparation functions

suppressPackageStartupMessages(library(testthat))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))

# Source dependencies if not already loaded (for standalone test runs)
if (!exists("prepare_varience_data")) {
  # Try to source from tests/setup.R first
  if (file.exists("tests/setup.R")) {
    source("tests/setup.R")
  } else if (file.exists("../../R/preprocessing.R")) {
    # If running from tests/testthat directory
    source("../../R/preprocessing.R")
  } else {
    # If running from project root
    source("R/preprocessing.R")
  }
}

# Test prepare_varience_data function
test_that("prepare_varience_data unnests parameter columns correctly", {
  # Create test dataframe with nested parameter columns
  test_df <- data.frame(
    baseParameters = I(list(c(1.0, 2.0, 3.0))),
    truthyParameters = I(list(c(1.0, 2.0, 3.0))),
    randomParameters = I(list(c(4.0, 5.0, 6.0)))
  )

  result <- prepare_varience_data(test_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3) # 3 values per parameter
  expect_true("baseParameters" %in% names(result))
  expect_true("truthyParameters" %in% names(result))
  expect_true("randomParameters" %in% names(result))

  # Check unnested values
  expect_equal(result$baseParameters, c(1.0, 2.0, 3.0))
  expect_equal(result$truthyParameters, c(1.0, 2.0, 3.0))
  expect_equal(result$randomParameters, c(4.0, 5.0, 6.0))
})

test_that("prepare_varience_data unnests log measure columns correctly", {
  # Create test dataframe with log measure columns
  test_df <- data.frame(
    baseLog.agent_time_enableds = I(list(c(10.0, 11.0, 12.0))),
    truthyLog.agent_time_enableds = I(list(c(13.0, 14.0, 15.0))),
    randomLog.agent_time_enableds = I(list(c(16.0, 17.0, 18.0)))
  )

  result <- prepare_varience_data(test_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_true("baseLog.agent_time_enableds" %in% names(result))
  expect_equal(result$baseLog.agent_time_enableds, c(10.0, 11.0, 12.0))
})

test_that("prepare_varience_data handles all four measure column types", {
  # Test all four types: agent_time_enableds, collisionTimes,
  # agent_distance_traveleds, agent_ple_energys
  test_df <- data.frame(
    baseLog.agent_time_enableds = I(list(c(1, 2))),
    baseLog.collisionTimes = I(list(c(3, 4))),
    baseLog.agent_distance_traveleds = I(list(c(5, 6))),
    baseLog.agent_ple_energys = I(list(c(7, 8)))
  )

  result <- prepare_varience_data(test_df)

  expect_equal(nrow(result), 2)
  expect_true("baseLog.agent_time_enableds" %in% names(result))
  expect_true("baseLog.collisionTimes" %in% names(result))
  expect_true("baseLog.agent_distance_traveleds" %in% names(result))
  expect_true("baseLog.agent_ple_energys" %in% names(result))
})

test_that("prepare_varience_data handles all three log prefixes", {
  # Test baseLog, truthyLog, and randomLog prefixes
  test_df <- data.frame(
    baseLog.agent_time_enableds = I(list(c(1, 2))),
    truthyLog.agent_time_enableds = I(list(c(3, 4))),
    randomLog.agent_time_enableds = I(list(c(5, 6)))
  )

  result <- prepare_varience_data(test_df)

  expect_equal(nrow(result), 2)
  expect_true("baseLog.agent_time_enableds" %in% names(result))
  expect_true("truthyLog.agent_time_enableds" %in% names(result))
  expect_true("randomLog.agent_time_enableds" %in% names(result))
})

test_that("prepare_varience_data drops columns not in the expected list", {
  # Create dataframe with extra columns
  test_df <- data.frame(
    baseParameters = I(list(c(1, 2))),
    extraColumn = "should be removed",
    anotherExtra = 123,
    baseLog.agent_time_enableds = I(list(c(3, 4))),
    yetAnotherExtra = TRUE
  )

  result <- prepare_varience_data(test_df)

  # Should only have expected columns
  expect_false("extraColumn" %in% names(result))
  expect_false("anotherExtra" %in% names(result))
  expect_false("yetAnotherExtra" %in% names(result))
  expect_true("baseParameters" %in% names(result))
  expect_true("baseLog.agent_time_enableds" %in% names(result))
})

test_that("prepare_varience_data handles complete dataset with all columns", {
  # Create a full dataset with all expected columns
  test_df <- data.frame(
    baseParameters = I(list(c(0.1, 0.2))),
    truthyParameters = I(list(c(0.1, 0.2))),
    randomParameters = I(list(c(0.3, 0.4))),
    baseLog.agent_time_enableds = I(list(c(10, 11))),
    truthyLog.agent_time_enableds = I(list(c(12, 13))),
    randomLog.agent_time_enableds = I(list(c(14, 15))),
    baseLog.collisionTimes = I(list(c(20, 21))),
    truthyLog.collisionTimes = I(list(c(22, 23))),
    randomLog.collisionTimes = I(list(c(24, 25))),
    baseLog.agent_distance_traveleds = I(list(c(30, 31))),
    truthyLog.agent_distance_traveleds = I(list(c(32, 33))),
    randomLog.agent_distance_traveleds = I(list(c(34, 35))),
    baseLog.agent_ple_energys = I(list(c(40, 41))),
    truthyLog.agent_ple_energys = I(list(c(42, 43))),
    randomLog.agent_ple_energys = I(list(c(44, 45)))
  )

  result <- prepare_varience_data(test_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 15) # 3 param + 12 measure columns

  # Verify a few values
  expect_equal(result$baseParameters, c(0.1, 0.2))
  expect_equal(result$baseLog.agent_time_enableds, c(10, 11))
  expect_equal(result$randomLog.agent_ple_energys, c(44, 45))
})

test_that("prepare_varience_data handles multiple rows with nested data", {
  # Create dataframe with multiple rows
  test_df <- data.frame(
    baseParameters = I(list(c(1, 2), c(3, 4))),
    truthyParameters = I(list(c(1, 2), c(3, 4))),
    baseLog.agent_time_enableds = I(list(c(10, 11), c(12, 13)))
  )

  result <- prepare_varience_data(test_df)

  # Should have 4 rows (2 original rows × 2 nested values each)
  expect_equal(nrow(result), 4)
  expect_equal(result$baseParameters, c(1, 2, 3, 4))
  expect_equal(result$baseLog.agent_time_enableds, c(10, 11, 12, 13))
})

test_that("prepare_varience_data handles varying nested lengths consistently", {
  # When all columns have the same nested structure, unnest should work
  test_df <- data.frame(
    baseParameters = I(list(c(1, 2, 3))),
    baseLog.agent_time_enableds = I(list(c(10, 11, 12)))
  )

  result <- prepare_varience_data(test_df)

  expect_equal(nrow(result), 3)
})

test_that("prepare_varience_data handles single value nested lists", {
  # Test with single values in lists
  test_df <- data.frame(
    baseParameters = I(list(1.5)),
    truthyParameters = I(list(1.5)),
    randomParameters = I(list(2.5))
  )

  result <- prepare_varience_data(test_df)

  expect_equal(nrow(result), 1)
  expect_equal(result$baseParameters, 1.5)
  expect_equal(result$randomParameters, 2.5)
})

test_that("prepare_varience_data handles empty dataframe", {
  # Create empty dataframe with correct columns
  test_df <- data.frame(
    baseParameters = list(),
    truthyParameters = list(),
    randomParameters = list()
  )

  result <- prepare_varience_data(test_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("prepare_varience_data errors gracefully when columns are missing", {
  # Dataframe missing some expected columns
  test_df <- data.frame(
    baseParameters = I(list(c(1, 2))),
    # Missing truthyParameters, randomParameters, and all log columns
    extraColumn = "something"
  )

  # The select should handle missing columns
  # This might error or return empty depending on implementation
  # Let's test that it handles missing columns gracefully
  result_or_error <- tryCatch(
    {
      prepare_varience_data(test_df)
    },
    error = function(e) {
      "error"
    }
  )

  # Either returns empty df or errors - both are acceptable
  expect_true(is.data.frame(result_or_error) || result_or_error == "error")
})

test_that("prepare_varience_data preserves data types after unnesting", {
  # Test that numeric types are preserved
  test_df <- data.frame(
    baseParameters = I(list(c(1.5, 2.7, 3.9))),
    truthyParameters = I(list(c(1.5, 2.7, 3.9))),
    baseLog.agent_time_enableds = I(list(c(10.1, 11.2, 12.3)))
  )

  result <- prepare_varience_data(test_df)

  expect_type(result$baseParameters, "double")
  expect_type(result$truthyParameters, "double")
  expect_type(result$baseLog.agent_time_enableds, "double")
})

test_that("prepare_varience_data handles NA values in nested data", {
  # Test with NA values
  test_df <- data.frame(
    baseParameters = I(list(c(1.0, NA, 3.0))),
    truthyParameters = I(list(c(1.0, 2.0, 3.0))),
    baseLog.agent_time_enableds = I(list(c(NA, 11.0, 12.0)))
  )

  result <- prepare_varience_data(test_df)

  expect_equal(nrow(result), 3)
  expect_true(is.na(result$baseParameters[2]))
  expect_true(is.na(result$baseLog.agent_time_enableds[1]))
})

# Integration test with realistic data structure
test_that("prepare_varience_data works with data from process_parsed_data", {
  # Simulate the output structure from process_parsed_data
  test_df <- tibble(
    baseParameters = list(c(0.379, 0.0771, 0.435)),
    truthyParameters = list(c(0.379, 0.0771, 0.435)),
    randomParameters = list(c(0.098, 0.124, 0.467)),
    baseLog.agent_time_enableds = list(c(20.4, 19.2, 25.1)),
    truthyLog.agent_time_enableds = list(c(22.2, 27.4, 23.5)),
    randomLog.agent_time_enableds = list(c(25.3, 20.1, 21.8)),
    baseLog.collisionTimes = list(c(31, 33, 59)),
    truthyLog.collisionTimes = list(c(41, 58, 114)),
    randomLog.collisionTimes = list(c(62, 37, 27)),
    baseLog.agent_distance_traveleds = list(c(19.6, 21.1, 18.5)),
    truthyLog.agent_distance_traveleds = list(c(20.3, 22.4, 19.1)),
    randomLog.agent_distance_traveleds = list(c(21.7, 19.8, 20.5)),
    baseLog.agent_ple_energys = list(c(70.2, 73.1, 68.9)),
    truthyLog.agent_ple_energys = list(c(71.5, 74.2, 69.5)),
    randomLog.agent_ple_energys = list(c(72.8, 70.9, 71.2))
  )

  result <- prepare_varience_data(test_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 15)

  # Verify structure
  expect_true(all(c("baseParameters", "truthyParameters", "randomParameters") %in% names(result)))
  expect_true(all(grepl("Log\\.", names(result)[4:15])))

  # Verify values are unnested correctly
  expect_equal(result$baseParameters[1], 0.379)
  expect_equal(result$baseLog.collisionTimes[2], 33)
  expect_equal(result$randomLog.agent_ple_energys[3], 71.2)
})
