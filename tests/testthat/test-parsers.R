# Unit tests for parsers.R
# Tests parsing functions for log data, JSON, and parenthesis-enclosed values

suppressPackageStartupMessages(library(testthat))

# Source dependencies if not already loaded (for standalone test runs)
if (!exists("parse_log")) {
  # Try to source from tests/setup.R first
  if (file.exists("tests/setup.R")) {
    source("tests/setup.R")
  } else if (file.exists("../../R/parsers.R")) {
    # If running from tests/testthat directory
    suppressPackageStartupMessages(library(jsonlite))
    source("../../R/parsers.R")
  } else {
    # If running from project root
    suppressPackageStartupMessages(library(jsonlite))
    source("R/parsers.R")
  }
}

# Test parse_log function
test_that("parse_log correctly parses well-formed log strings", {
  # Test basic log format
  log_str <- "header line\nkey1 key2 key3\nval1 val2 val3"
  result <- parse_log(log_str)
  
  expect_type(result, "list")
  expect_named(result, c("key1", "key2", "key3"))
  expect_equal(result$key1, "val1")
  expect_equal(result$key2, "val2")
  expect_equal(result$key3, "val3")
})

test_that("parse_log handles different whitespace patterns", {
  # Test with tabs and multiple spaces
  log_str <- "header\nkey1\tkey2  key3\nval1\tval2  val3"
  result <- parse_log(log_str)
  
  expect_named(result, c("key1", "key2", "key3"))
  expect_equal(result$key1, "val1")
  expect_equal(result$key2, "val2")
  expect_equal(result$key3, "val3")
})

test_that("parse_log handles numeric-looking values as strings", {
  log_str <- "header\ntime distance energy\n10.5 23.4 99.9"
  result <- parse_log(log_str)
  
  expect_type(result, "list")
  expect_named(result, c("time", "distance", "energy"))
  # Values are stored as strings
  expect_equal(result$time, "10.5")
  expect_equal(result$distance, "23.4")
  expect_equal(result$energy, "99.9")
})

test_that("parse_log throws error for insufficient lines", {
  # Less than 3 lines
  log_str_1_line <- "only one line"
  log_str_2_lines <- "line1\nline2"
  
  expect_error(parse_log(log_str_1_line), "must have at least 3 lines")
  expect_error(parse_log(log_str_2_lines), "must have at least 3 lines")
})

test_that("parse_log handles extra lines beyond the first three", {
  # Should only use first 3 lines
  log_str <- "header\nkey1 key2\nval1 val2\nextra line\nanother extra"
  result <- parse_log(log_str)
  
  expect_named(result, c("key1", "key2"))
  expect_equal(result$key1, "val1")
  expect_equal(result$key2, "val2")
})

test_that("parse_log fails fast on mismatched key-value counts", {
  # More keys than values - should fail fast
  log_str <- "header\nkey1 key2 key3\nval1 val2"
  
  expect_error(
    parse_log(log_str),
    "must be the same length"
  )
})

# Test parse_json_floats function
test_that("parse_json_floats correctly parses JSON array of floats", {
  json_str <- "[1.5, 2.7, 3.9]"
  result <- parse_json_floats(json_str)
  
  expect_type(result, "double")
  expect_equal(length(result), 3)
  expect_equal(result, c(1.5, 2.7, 3.9))
})

test_that("parse_json_floats handles integers in JSON", {
  json_str <- "[1, 2, 3]"
  result <- parse_json_floats(json_str)
  
  expect_type(result, "double")
  expect_equal(result, c(1.0, 2.0, 3.0))
})

test_that("parse_json_floats handles negative numbers", {
  json_str <- "[-1.5, 0, 2.5]"
  result <- parse_json_floats(json_str)
  
  expect_equal(result, c(-1.5, 0, 2.5))
})

test_that("parse_json_floats handles scientific notation", {
  json_str <- "[1.5e-3, 2.7e2, 3.9e+1]"
  result <- parse_json_floats(json_str)
  
  expect_equal(result[1], 0.0015, tolerance = 1e-10)
  expect_equal(result[2], 270, tolerance = 1e-10)
  expect_equal(result[3], 39, tolerance = 1e-10)
})

test_that("parse_json_floats handles single element array", {
  json_str <- "[42.0]"
  result <- parse_json_floats(json_str)
  
  expect_equal(length(result), 1)
  expect_equal(result, 42.0)
})

test_that("parse_json_floats handles empty array", {
  json_str <- "[]"
  result <- parse_json_floats(json_str)
  
  expect_equal(length(result), 0)
  expect_type(result, "double")
})

test_that("parse_json_floats throws error for NA, NULL, or empty string", {
  expect_error(parse_json_floats(NA), "NA, NULL, or empty")
  expect_error(parse_json_floats(NULL), "NA, NULL, or empty")
  expect_error(parse_json_floats(""), "NA, NULL, or empty")
})

test_that("parse_json_floats throws error for invalid JSON", {
  expect_error(parse_json_floats("[1, 2, "), "parse error|lexical error")
  expect_error(parse_json_floats("not json"), "parse error|lexical error")
})

test_that("parse_json_floats throws error for non-numeric JSON arrays", {
  json_str <- '["a", "b", "c"]'
  suppressWarnings(expect_error(parse_json_floats(json_str), "Failed to convert"))
})

test_that("parse_json_floats throws error for mixed type arrays", {
  json_str <- '[1, "two", 3]'
  suppressWarnings(expect_error(parse_json_floats(json_str), "Failed to convert"))
})

# Test parse_parenthesis_floats function
test_that("parse_parenthesis_floats correctly parses parenthesis-enclosed floats", {
  paren_str <- "(1.5, 2.7, 3.9)"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_type(result, "double")
  expect_equal(length(result), 3)
  expect_equal(result, c(1.5, 2.7, 3.9))
})

test_that("parse_parenthesis_floats handles integers", {
  paren_str <- "(1, 2, 3)"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_equal(result, c(1, 2, 3))
})

test_that("parse_parenthesis_floats handles negative numbers", {
  paren_str <- "(-1.5, 0, 2.5)"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_equal(result, c(-1.5, 0, 2.5))
})

test_that("parse_parenthesis_floats handles spaces around numbers", {
  paren_str <- "(  1.5  ,  2.7  ,  3.9  )"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_equal(result, c(1.5, 2.7, 3.9))
})

test_that("parse_parenthesis_floats handles no spaces after commas", {
  paren_str <- "(1.5,2.7,3.9)"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_equal(result, c(1.5, 2.7, 3.9))
})

test_that("parse_parenthesis_floats handles single element", {
  paren_str <- "(42.0)"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_equal(length(result), 1)
  expect_equal(result, 42.0)
})

test_that("parse_parenthesis_floats handles scientific notation", {
  paren_str <- "(1.5e-3, 2.7e2)"
  result <- parse_parenthesis_floats(paren_str)
  
  expect_equal(result[1], 0.0015, tolerance = 1e-10)
  expect_equal(result[2], 270, tolerance = 1e-10)
})

test_that("parse_parenthesis_floats throws error for missing parentheses", {
  expect_error(parse_parenthesis_floats("1.5, 2.7, 3.9"), "does not have proper parenthesis format")
  expect_error(parse_parenthesis_floats("(1.5, 2.7, 3.9"), "does not have proper parenthesis format")
  expect_error(parse_parenthesis_floats("1.5, 2.7, 3.9)"), "does not have proper parenthesis format")
})

test_that("parse_parenthesis_floats throws error for NA, NULL, or empty", {
  expect_error(parse_parenthesis_floats(NA), "NA, NULL, or empty")
  expect_error(parse_parenthesis_floats(NULL), "NA, NULL, or empty")
  expect_error(parse_parenthesis_floats(""), "NA, NULL, or empty")
})

test_that("parse_parenthesis_floats throws error for non-numeric content", {
  suppressWarnings(expect_error(parse_parenthesis_floats("(a, b, c)"), "Failed to convert"))
  suppressWarnings(expect_error(parse_parenthesis_floats("(1, two, 3)"), "Failed to convert"))
})

test_that("parse_parenthesis_floats handles empty parentheses", {
  # Empty parentheses: strsplit("", ",")[[1]] returns character(0)
  # which becomes numeric(0) - an empty numeric vector
  # any(is.na(numeric(0))) is FALSE, so no error is thrown
  result <- parse_parenthesis_floats("()")
  expect_equal(length(result), 0)
  expect_type(result, "double")
})

test_that("parse_parenthesis_floats handles nested parentheses by treating them as part of content", {
  # Nested parentheses should fail as they're not valid numbers
  paren_str <- "((1, 2), 3)"
  suppressWarnings(expect_error(parse_parenthesis_floats(paren_str), "Failed to convert"))
})

# Edge cases and integration tests
test_that("parser functions are consistent with their error handling", {
  # All three functions should reject NA
  expect_error(parse_json_floats(NA))
  expect_error(parse_parenthesis_floats(NA))
  
  # All three functions should reject empty strings
  expect_error(parse_json_floats(""))
  expect_error(parse_parenthesis_floats(""))
})

test_that("parser functions handle boundary numeric values", {
  # Very large numbers
  json_large <- "[1e308, 2e308]"
  # This might work or overflow depending on R's limits
  
  # Very small numbers
  json_small <- "[1e-308, 1e-320]"
  result_small <- parse_json_floats(json_small)
  expect_type(result_small, "double")
  
  # Zero
  expect_equal(parse_json_floats("[0, 0.0, -0.0]"), c(0, 0, 0))
  expect_equal(parse_parenthesis_floats("(0, 0.0, -0.0)"), c(0, 0, 0))
})

