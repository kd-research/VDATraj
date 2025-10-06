# Testing and Extension Guide for Find-Variance Project

This guide provides comprehensive information on testing the project and extending it with new functionality. It's designed for developers who want to contribute to or build upon this codebase.

## Table of Contents
1. [Testing Overview](#testing-overview)
2. [Running Tests](#running-tests)
3. [Understanding the Test Suite](#understanding-the-test-suite)
4. [Writing New Tests](#writing-new-tests)
5. [Extending the Project](#extending-the-project)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Testing Overview

The project uses the `testthat` framework, which is the standard R testing framework. The test suite provides:

- **70+ unit tests** across all core functions
- **Comprehensive coverage** of normal, edge, and error cases
- **Helper utilities** for creating test fixtures
- **Integration tests** for end-to-end workflows
- **Clear documentation** of expected behavior

### Why Testing Matters

1. **Reliability**: Catch bugs before they reach production
2. **Refactoring Safety**: Modify code with confidence
3. **Documentation**: Tests demonstrate how to use functions
4. **Extension**: Easy to add new features without breaking existing ones

## Running Tests

### Quick Start

```bash
# From project root
Rscript tests/run_unit_tests.R
```

### Using Nix (Recommended)

```bash
# With nix flake
nix run . -- tests/run_unit_tests.R

# Or enter nix shell first
nix develop
Rscript tests/run_unit_tests.R
```

### Interactive Testing in R

```r
# Start R in project root
library(testthat)
source("tests/setup.R")

# Run all tests
test_dir("tests/testthat")

# Run specific test file
test_file("tests/testthat/test-parsers.R")

# Run specific test
test_file("tests/testthat/test-parsers.R", 
          filter = "parse_log correctly parses")
```

### Expected Output

```
=======================================================
  Find-Variance Project - Unit Test Suite
=======================================================

Loading dependencies...
✓ Dependencies loaded

Running unit tests...
-------------------------------------------------------

test-parsers.R ................................... ✓ | 40 passed
test-database.R .................................. ✓ | 20 passed  
test-preprocessing.R ............................. ✓ | 15 passed

=======================================================
  Test Summary
=======================================================
✓ All tests passed!

Test suite completed.
```

## Understanding the Test Suite

### Test File Organization

```
tests/testthat/
├── helper-test-utils.R      # Shared test utilities
├── test-parsers.R           # Tests for R/parsers.R
├── test-database.R          # Tests for R/database.R
└── test-preprocessing.R     # Tests for R/preprocessing.R
```

### Test Structure

Each test file follows this pattern:

```r
# 1. Load dependencies
library(testthat)
source("R/module.R")

# 2. Define tests
test_that("function does X correctly", {
  # Arrange: Set up test data
  input <- create_test_input()
  
  # Act: Call the function
  result <- function_under_test(input)
  
  # Assert: Verify results
  expect_equal(result, expected_output)
  expect_type(result, "double")
})

test_that("function handles errors appropriately", {
  expect_error(function_under_test(invalid_input), "error message")
})
```

### Key Testing Concepts

#### Expectations

Common expectations used in tests:

```r
# Value comparisons
expect_equal(actual, expected)
expect_identical(actual, expected)

# Type checks
expect_type(x, "double")
expect_s3_class(df, "data.frame")

# Logical checks
expect_true(condition)
expect_false(condition)

# Error checking
expect_error(code, "error pattern")
expect_warning(code, "warning pattern")

# Length/size checks
expect_length(vector, 5)
```

#### Test Fixtures

Helper utilities in `helper-test-utils.R`:

```r
# Create test database
db <- create_minimal_test_db()
# Use it...
unlink(db)  # Clean up

# Create test dataframe
df <- create_nested_test_df(n_rows = 5, n_nested = 3)

# Validate structure
validate_processed_data_structure(df)
```

## Writing New Tests

### Step-by-Step Process

#### 1. Create Test File

```bash
# Create new test file
touch tests/testthat/test-mymodule.R
```

#### 2. Write Test Template

```r
# tests/testthat/test-mymodule.R
library(testthat)
source("R/mymodule.R")

# Test normal behavior
test_that("my_function works with valid input", {
  input <- list(a = 1, b = 2)
  result <- my_function(input)
  
  expect_type(result, "list")
  expect_equal(result$sum, 3)
})

# Test edge cases
test_that("my_function handles empty input", {
  result <- my_function(list())
  expect_equal(length(result), 0)
})

# Test error conditions
test_that("my_function rejects invalid input", {
  expect_error(my_function(NULL), "input cannot be NULL")
  expect_error(my_function("invalid"), "must be a list")
})
```

#### 3. Run and Iterate

```r
# Test your new tests
test_file("tests/testthat/test-mymodule.R")

# Fix any failures
# Add more tests as needed
```

### Test Writing Checklist

- [ ] Tests for normal/expected behavior
- [ ] Tests for edge cases (empty, single element, large inputs)
- [ ] Tests for error conditions (NULL, NA, wrong types)
- [ ] Tests for boundary values (min, max, zero)
- [ ] Tests for integration with other functions
- [ ] Clear, descriptive test names
- [ ] Appropriate use of helper utilities
- [ ] Cleanup of temporary resources (files, connections)

### Example: Testing a New Parsing Function

Suppose you add a new function `parse_csv_floats(csv_str)`:

```r
# R/parsers.R - Add this function
parse_csv_floats <- function(csv_str) {
  if (is.na(csv_str) || is.null(csv_str) || csv_str == "") {
    stop("CSV string is NA, NULL, or empty")
  }
  
  values <- strsplit(csv_str, ",")[[1]]
  values <- trimws(values)
  result <- as.numeric(values)
  
  if (any(is.na(result))) {
    stop(paste("Failed to convert CSV to numeric:", csv_str))
  }
  
  return(result)
}
```

```r
# tests/testthat/test-parsers.R - Add these tests
test_that("parse_csv_floats parses comma-separated floats", {
  csv_str <- "1.5, 2.7, 3.9"
  result <- parse_csv_floats(csv_str)
  
  expect_type(result, "double")
  expect_equal(result, c(1.5, 2.7, 3.9))
})

test_that("parse_csv_floats handles no spaces", {
  result <- parse_csv_floats("1.5,2.7,3.9")
  expect_equal(result, c(1.5, 2.7, 3.9))
})

test_that("parse_csv_floats handles single value", {
  result <- parse_csv_floats("42.0")
  expect_equal(result, 42.0)
})

test_that("parse_csv_floats rejects NA/NULL/empty", {
  expect_error(parse_csv_floats(NA), "NA, NULL, or empty")
  expect_error(parse_csv_floats(NULL), "NA, NULL, or empty")
  expect_error(parse_csv_floats(""), "NA, NULL, or empty")
})

test_that("parse_csv_floats rejects non-numeric", {
  expect_error(parse_csv_floats("a,b,c"), "Failed to convert")
})
```

## Extending the Project

### Adding New R Modules

#### 1. Create Module File

```r
# R/analysis.R - New module for variance analysis

#' Compute variance decomposition metrics
#' 
#' @param df Data frame with base, truthy, and random measurements
#' @param measure_col Name of the measurement column
#' @return List with variance components
compute_variance_metrics <- function(df, measure_col) {
  # Extract columns
  base <- df[[paste0("base", measure_col)]]
  truthy <- df[[paste0("truthy", measure_col)]]
  random <- df[[paste0("random", measure_col)]]
  
  # Compute differences
  same_diff <- base - truthy
  random_diff <- base - random
  
  # Variance components
  var_same <- var(same_diff)
  var_random <- var(random_diff)
  impact_var <- var_random - var_same
  
  return(list(
    var_same = var_same,
    var_random = var_random,
    impact_variance = impact_var,
    effect_size = impact_var / var_same
  ))
}
```

#### 2. Create Tests

```r
# tests/testthat/test-analysis.R

library(testthat)
source("R/analysis.R")

test_that("compute_variance_metrics calculates correctly", {
  # Create test data
  df <- data.frame(
    baseMeasure = c(10, 20, 30, 40, 50),
    truthyMeasure = c(11, 19, 31, 39, 51),  # Similar to base
    randomMeasure = c(15, 25, 35, 45, 55)   # Different from base
  )
  
  result <- compute_variance_metrics(df, "Measure")
  
  # Check structure
  expect_type(result, "list")
  expect_named(result, c("var_same", "var_random", "impact_variance", "effect_size"))
  
  # Check values are reasonable
  expect_true(result$var_same > 0)
  expect_true(result$var_random > result$var_same)
  expect_true(result$impact_variance > 0)
})

test_that("compute_variance_metrics handles no parameter effect", {
  # When random is same as truthy, impact should be near zero
  df <- data.frame(
    baseMeasure = c(10, 20, 30),
    truthyMeasure = c(11, 19, 31),
    randomMeasure = c(10.5, 20.5, 29.5)
  )
  
  result <- compute_variance_metrics(df, "Measure")
  
  # Impact should be small
  expect_true(abs(result$impact_variance) < result$var_same)
})

test_that("compute_variance_metrics errors on missing columns", {
  df <- data.frame(baseMeasure = c(1, 2, 3))
  
  expect_error(compute_variance_metrics(df, "Measure"))
})
```

#### 3. Update Setup

```r
# tests/setup.R - Add new module
source("R/analysis.R")
```

#### 4. Document in README

Update `tests/README.md` to include the new module's test coverage.

### Adding New Data Sources

If adding support for a new database format or data source:

```r
# R/database.R - Add new function

#' Load data from CSV file
#' 
#' @param filename Path to CSV file
#' @return Data frame with parsed data
get_data_from_csv <- function(filename) {
  if (!file.exists(filename)) {
    stop(paste("File", filename, "not found."))
  }
  
  df <- read.csv(filename, stringsAsFactors = FALSE)
  
  # Apply same processing as database data
  processed_df <- process_parsed_data(df)
  
  return(processed_df)
}
```

```r
# tests/testthat/test-database.R - Add tests

test_that("get_data_from_csv loads CSV files", {
  # Create temporary CSV
  csv_file <- tempfile(fileext = ".csv")
  write.csv(data.frame(
    baseLog = "header\nkey1\nval1",
    baseParameters = "[1.0, 2.0]"
  ), csv_file, row.names = FALSE)
  
  result <- get_data_from_csv(csv_file)
  
  expect_s3_class(result, "data.frame")
  expect_true("baseLog.key1" %in% names(result))
  
  unlink(csv_file)
})
```

## Best Practices

### Test Design

1. **One Concept Per Test**: Each test should verify one behavior
   ```r
   # Good
   test_that("parse_log handles whitespace", { ... })
   test_that("parse_log throws error for short input", { ... })
   
   # Bad
   test_that("parse_log works", {
     # Tests 10 different things
   })
   ```

2. **Descriptive Names**: Test names should explain what's being tested
   ```r
   # Good
   test_that("get_data_from_db respects limit parameter", { ... })
   
   # Bad
   test_that("test1", { ... })
   ```

3. **Independent Tests**: Tests shouldn't depend on each other
   ```r
   # Good - Each test creates its own data
   test_that("test A", {
     data <- create_test_data()
     # ...
   })
   
   # Bad - Test B depends on test A
   test_that("test A", {
     global_data <<- create_test_data()
   })
   test_that("test B", {
     # Uses global_data
   })
   ```

4. **Clean Up Resources**: Always clean up temporary files
   ```r
   test_that("function uses temp file", {
     temp_file <- tempfile()
     # ... use temp_file ...
     unlink(temp_file)  # Clean up
   })
   ```

### Code Organization

1. **Keep Functions Small**: Functions should do one thing well
2. **Use Type Checking**: Validate inputs early
3. **Document with roxygen2**: Use `#'` comments for function documentation
4. **Handle Errors Gracefully**: Use `tryCatch` for predictable errors

### Testing Strategy

1. **Test Public Functions**: Focus on exported/user-facing functions
2. **Test Edge Cases**: Empty inputs, single elements, large inputs
3. **Test Error Paths**: Invalid inputs, missing data, type mismatches
4. **Test Integration**: How functions work together

## Troubleshooting

### Common Issues

#### Tests Fail to Run

```
Error: could not find function "test_that"
```

**Solution**: Make sure testthat is installed and loaded
```r
install.packages("testthat")
library(testthat)
```

#### Can't Find Source Files

```
Error: cannot open file 'R/parsers.R': No such file or directory
```

**Solution**: Make sure you're running from project root
```bash
cd /path/to/find-variance
Rscript tests/run_unit_tests.R
```

#### Database Tests Fail

```
Error: database disk image is malformed
```

**Solution**: Clean up old test databases
```bash
rm -f /tmp/*.sqlite3
```

#### Tests Pass Individually But Fail Together

**Issue**: Tests are interfering with each other (not independent)

**Solution**: 
- Check for shared global state
- Ensure each test creates its own data
- Clean up resources in each test

### Debugging Tests

#### Run Tests Verbosely

```r
test_file("tests/testthat/test-parsers.R", reporter = "location")
```

#### Use Browser for Debugging

```r
test_that("my test", {
  data <- create_data()
  browser()  # Stops here for inspection
  result <- my_function(data)
  expect_equal(result, expected)
})
```

#### Print Intermediate Values

```r
test_that("complex calculation", {
  x <- compute_x()
  print(paste("x =", x))  # Debug output
  
  y <- compute_y(x)
  print(paste("y =", y))
  
  expect_equal(y, expected)
})
```

## Getting Help

### Resources

- [testthat documentation](https://testthat.r-lib.org/)
- [R Packages book - Testing chapter](https://r-pkgs.org/testing-basics.html)
- Project-specific: `tests/README.md`
- Theory documentation: `docs/theory.org`

### Contributing

When contributing tests:

1. Follow existing patterns in test files
2. Use helper utilities where appropriate
3. Write clear test descriptions
4. Ensure tests are independent
5. Clean up resources
6. Update documentation

### Contact

For questions about testing or extending this project:
- Open an issue on the project repository
- Review existing tests for examples
- Consult the theory documentation for domain context

## Summary

This testing framework provides:
- ✓ Comprehensive test coverage
- ✓ Easy-to-use test utilities
- ✓ Clear patterns for extension
- ✓ Good documentation

Follow these guidelines to maintain code quality and make the project easy to extend for future development!

