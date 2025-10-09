# Unit tests for database.R
# Tests database query and data processing functions

suppressPackageStartupMessages(library(testthat))
suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(purrr))

# Source dependencies if not already loaded (for standalone test runs)
if (!exists("get_raw_data_from_db")) {
  # Try to source from tests/setup.R first
  if (file.exists("tests/setup.R")) {
    source("tests/setup.R")
  } else if (file.exists("../../R/parsers.R")) {
    # If running from tests/testthat directory
    suppressPackageStartupMessages(library(jsonlite))
    source("../../R/parsers.R")
    source("../../R/database.R")
    source("../../R/preprocessing.R")
  } else {
    # If running from project root
    suppressPackageStartupMessages(library(jsonlite))
    source("R/parsers.R")
    source("R/database.R")
    source("R/preprocessing.R")
  }
}

# Helper function to create a minimal test database
create_test_db <- function() {
  db_path <- tempfile(fileext = ".sqlite3")
  conn <- dbConnect(RSQLite::SQLite(), db_path)

  # Create parameters table
  dbExecute(conn, "CREATE TABLE parameters (
    id INTEGER PRIMARY KEY,
    label TEXT,
    parameters TEXT
  )")

  # Create parameter_relations table
  dbExecute(conn, "CREATE TABLE parameter_relations (
    from_id INTEGER,
    to_id INTEGER
  )")

  # Create benchmark_log table
  dbExecute(conn, "CREATE TABLE benchmark_log (
    parameter_object_id INTEGER,
    log TEXT
  )")

  # Insert test data
  # Base parameter
  dbExecute(conn, "INSERT INTO parameters VALUES (1, 'budget-ground', '[0.1, 0.2, 0.3]')")
  # Truthy parameter (identical)
  dbExecute(conn, "INSERT INTO parameters VALUES (2, 'truthy', '[0.1, 0.2, 0.3]')")
  # Random parameter
  dbExecute(conn, "INSERT INTO parameters VALUES (3, 'random', '[0.4, 0.5, 0.6]')")

  # Relations
  dbExecute(conn, "INSERT INTO parameter_relations VALUES (1, 2)")
  dbExecute(conn, "INSERT INTO parameter_relations VALUES (1, 3)")

  # Logs with proper format (header, keys, values)
  base_log <- "header\nagent_time_enableds collisionTimes agent_distance_traveleds agent_ple_energys\n(10.5,11.5,12.5) (20,21,22) (30.1,31.1,32.1) (40.2,41.2,42.2)"
  truthy_log <- "header\nagent_time_enableds collisionTimes agent_distance_traveleds agent_ple_energys\n(13.5,14.5,15.5) (23,24,25) (33.1,34.1,35.1) (43.2,44.2,45.2)"
  random_log <- "header\nagent_time_enableds collisionTimes agent_distance_traveleds agent_ple_energys\n(16.5,17.5,18.5) (26,27,28) (36.1,37.1,38.1) (46.2,47.2,48.2)"

  dbExecute(conn, "INSERT INTO benchmark_log VALUES (1, ?)", params = list(base_log))
  dbExecute(conn, "INSERT INTO benchmark_log VALUES (2, ?)", params = list(truthy_log))
  dbExecute(conn, "INSERT INTO benchmark_log VALUES (3, ?)", params = list(random_log))

  dbDisconnect(conn)
  return(db_path)
}

# Test get_raw_data_from_db function
test_that("get_raw_data_from_db retrieves data from valid database", {
  db_path <- create_test_db()

  result <- get_raw_data_from_db(db_path)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1) # One complete set of base, truthy, random
  expect_true("baseParameters" %in% names(result))
  expect_true("truthyParameters" %in% names(result))
  expect_true("randomParameters" %in% names(result))
  expect_true("baseLog" %in% names(result))
  expect_true("truthyLog" %in% names(result))
  expect_true("randomLog" %in% names(result))

  unlink(db_path)
})

test_that("get_raw_data_from_db throws error for non-existent file", {
  expect_error(
    get_raw_data_from_db("nonexistent_file.sqlite3"),
    "not found"
  )
})

test_that("get_raw_data_from_db respects limit parameter", {
  db_path <- create_test_db()
  conn <- dbConnect(RSQLite::SQLite(), db_path)

  # Add more test data
  dbExecute(conn, "INSERT INTO parameters VALUES (4, 'budget-ground', '[0.7, 0.8, 0.9]')")
  dbExecute(conn, "INSERT INTO parameters VALUES (5, 'truthy', '[0.7, 0.8, 0.9]')")
  dbExecute(conn, "INSERT INTO parameters VALUES (6, 'random', '[1.0, 1.1, 1.2]')")
  dbExecute(conn, "INSERT INTO parameter_relations VALUES (4, 5)")
  dbExecute(conn, "INSERT INTO parameter_relations VALUES (4, 6)")

  log2 <- "header\nagent_time_enableds collisionTimes agent_distance_traveleds agent_ple_energys\n(19.5,20.5,21.5) (29,30,31) (39.1,40.1,41.1) (49.2,50.2,51.2)"
  dbExecute(conn, "INSERT INTO benchmark_log VALUES (4, ?)", params = list(log2))
  dbExecute(conn, "INSERT INTO benchmark_log VALUES (5, ?)", params = list(log2))
  dbExecute(conn, "INSERT INTO benchmark_log VALUES (6, ?)", params = list(log2))

  dbDisconnect(conn)

  # Test with limit
  result_limited <- get_raw_data_from_db(db_path, limit = 1)
  expect_equal(nrow(result_limited), 1)

  result_all <- get_raw_data_from_db(db_path)
  expect_equal(nrow(result_all), 2)

  unlink(db_path)
})

test_that("get_raw_data_from_db handles invalid limit parameter", {
  db_path <- create_test_db()

  # Negative limit should be ignored
  result <- get_raw_data_from_db(db_path, limit = -1)
  expect_s3_class(result, "data.frame")

  # Zero limit should be ignored
  result <- get_raw_data_from_db(db_path, limit = 0)
  expect_s3_class(result, "data.frame")

  # Non-numeric limit should work (converted to numeric)
  result <- get_raw_data_from_db(db_path, limit = "1")
  expect_s3_class(result, "data.frame")

  unlink(db_path)
})

test_that("get_raw_data_from_db handles database query errors gracefully", {
  # Create a database with missing tables
  db_path <- tempfile(fileext = ".sqlite3")
  conn <- dbConnect(RSQLite::SQLite(), db_path)
  dbExecute(conn, "CREATE TABLE dummy (id INTEGER)")
  dbDisconnect(conn)

  expect_error(
    get_raw_data_from_db(db_path),
    "Error executing query"
  )

  unlink(db_path)
})

# Test process_parsed_data function
test_that("process_parsed_data correctly parses log columns", {
  # Create a minimal raw dataframe
  raw_df <- data.frame(
    baseLog = "header\nkey1 key2\nval1 val2",
    baseParameters = "[1.0, 2.0]",
    stringsAsFactors = FALSE
  )

  result <- process_parsed_data(raw_df)

  expect_s3_class(result, "data.frame")
  expect_true("baseLog.key1" %in% names(result))
  expect_true("baseLog.key2" %in% names(result))
  expect_equal(result$baseLog.key1, "val1")
  expect_equal(result$baseLog.key2, "val2")
})

test_that("process_parsed_data parses JSON parameter columns", {
  raw_df <- data.frame(
    baseParameters = "[1.5, 2.5, 3.5]",
    truthyParameters = "[4.5, 5.5, 6.5]",
    randomParameters = "[7.5, 8.5, 9.5]",
    stringsAsFactors = FALSE
  )

  result <- process_parsed_data(raw_df)

  expect_s3_class(result, "data.frame")
  # Parameters should be list columns containing numeric vectors
  expect_type(result$baseParameters, "list")
  expect_type(result$baseParameters[[1]], "double")
  expect_equal(result$baseParameters[[1]], c(1.5, 2.5, 3.5))
})

test_that("process_parsed_data parses parenthesis columns correctly", {
  raw_df <- data.frame(
    baseLog = "header\nagent_time_enableds collisionTimes\n(10.5,11.5) (20,21)",
    stringsAsFactors = FALSE
  )

  result <- process_parsed_data(raw_df)

  expect_true("baseLog.agent_time_enableds" %in% names(result))
  expect_true("baseLog.collisionTimes" %in% names(result))

  # These should be list columns
  expect_type(result$baseLog.agent_time_enableds, "list")
  expect_type(result$baseLog.collisionTimes, "list")

  # Check values
  expect_equal(result$baseLog.agent_time_enableds[[1]], c(10.5, 11.5))
  expect_equal(result$baseLog.collisionTimes[[1]], c(20, 21))
})

test_that("process_parsed_data handles multiple log types", {
  raw_df <- data.frame(
    baseLog = "header\nkey1\nval1",
    truthyLog = "header\nkey2\nval2",
    randomLog = "header\nkey3\nval3",
    stringsAsFactors = FALSE
  )

  result <- process_parsed_data(raw_df)

  expect_true("baseLog.key1" %in% names(result))
  expect_true("truthyLog.key2" %in% names(result))
  expect_true("randomLog.key3" %in% names(result))
})

test_that("process_parsed_data handles errors gracefully with possibly", {
  # Test with malformed log that would cause parse_log to fail
  raw_df <- data.frame(
    baseLog = "only one line", # This will fail parse_log
    stringsAsFactors = FALSE
  )

  result <- process_parsed_data(raw_df)

  # Should handle the error and return a dataframe
  expect_s3_class(result, "data.frame")
  # When parse_log fails and returns empty list(), unnest_wider removes the column entirely
  # So baseLog should not exist in the result
  expect_false("baseLog" %in% names(result))
})

test_that("process_parsed_data handles dataframe with no log or parameter columns", {
  raw_df <- data.frame(
    someColumn = "value",
    anotherColumn = 123,
    stringsAsFactors = FALSE
  )

  result <- process_parsed_data(raw_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
})

# Test get_data_from_db integration
test_that("get_data_from_db integrates retrieval and processing", {
  db_path <- create_test_db()

  result <- get_data_from_db(db_path)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)

  # Check that parameters were parsed to numeric vectors
  expect_type(result$baseParameters, "list")
  expect_type(result$baseParameters[[1]], "double")

  # Check that logs were parsed
  expect_true(any(grepl("^baseLog\\.", names(result))))
  expect_true(any(grepl("^truthyLog\\.", names(result))))
  expect_true(any(grepl("^randomLog\\.", names(result))))

  unlink(db_path)
})

test_that("get_data_from_db handles limit parameter", {
  db_path <- create_test_db()

  result <- get_data_from_db(db_path, limit = 1)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)

  unlink(db_path)
})

test_that("get_data_from_db propagates errors from get_raw_data_from_db", {
  expect_error(
    get_data_from_db("nonexistent.sqlite3"),
    "not found"
  )
})

# Edge cases and integration tests
test_that("database functions handle empty result sets", {
  db_path <- tempfile(fileext = ".sqlite3")
  conn <- dbConnect(RSQLite::SQLite(), db_path)

  # Create tables but don't insert data
  dbExecute(conn, "CREATE TABLE parameters (
    id INTEGER PRIMARY KEY,
    label TEXT,
    parameters TEXT
  )")
  dbExecute(conn, "CREATE TABLE parameter_relations (
    from_id INTEGER,
    to_id INTEGER
  )")
  dbExecute(conn, "CREATE TABLE benchmark_log (
    parameter_object_id INTEGER,
    log TEXT
  )")

  dbDisconnect(conn)

  result <- get_data_from_db(db_path)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)

  unlink(db_path)
})

test_that("process_parsed_data handles mixed valid and invalid data", {
  # Test with invalid log data - should be handled gracefully with possibly()
  raw_df_invalid_log <- data.frame(
    baseLog = "header\nkey1\nval1",
    truthyLog = "invalid", # Will fail parsing but handled by possibly()
    stringsAsFactors = FALSE
  )

  result_log <- process_parsed_data(raw_df_invalid_log)

  expect_s3_class(result_log, "data.frame")
  expect_equal(nrow(result_log), 1)
  # truthyLog should be dropped when parsing fails
  expect_false("truthyLog" %in% names(result_log))

  # Test with invalid parameter data - should fail fast
  raw_df_invalid_param <- data.frame(
    baseParameters = "[1.0, 2.0]",
    randomParameters = "not json", # Will fail parsing - expect error
    stringsAsFactors = FALSE
  )

  expect_error(
    process_parsed_data(raw_df_invalid_param),
    "lexical error"
  )
})
