# Unit Tests for Find-Variance Project

This directory contains comprehensive unit tests for all R functions in the find-variance project. The test suite is designed to ensure code reliability, facilitate future development, and make the project easy to extend.

## Test Structure

The test suite follows the standard R `testthat` framework conventions:

```
tests/
├── README.md                    # This file
├── setup.R                      # Main setup file (loads dependencies)
├── testthat.R                   # Test runner for R CMD check
├── run_unit_tests.R            # Standalone test runner script
├── generate_test_data.R        # Test data generation
├── test_sample.R               # Sample test data
└── testthat/                   # Test files directory
    ├── helper-test-utils.R     # Test utilities and fixtures
    ├── test-parsers.R          # Tests for R/parsers.R
    ├── test-database.R         # Tests for R/database.R
    └── test-preprocessing.R    # Tests for R/preprocessing.R
```

## Running Tests

### Option 1: Using the test runner script (Recommended)

```bash
# From project root
Rscript tests/run_unit_tests.R

# Or with nix
nix run . -- tests/run_unit_tests.R
```

### Option 2: Using testthat directly in R

```r
# From R console
library(testthat)
source("tests/setup.R")
test_dir("tests/testthat")
```

### Option 3: Running individual test files

```r
library(testthat)
source("tests/setup.R")
test_file("tests/testthat/test-parsers.R")
test_file("tests/testthat/test-database.R")
test_file("tests/testthat/test-preprocessing.R")
```

## Test Coverage

### R/parsers.R
- **`parse_log(log)`**: 10+ test cases
  - Well-formed log strings
  - Different whitespace patterns
  - Numeric-looking values
  - Insufficient lines (error cases)
  - Extra lines beyond first three
  - Mismatched key-value counts

- **`parse_json_floats(json_str)`**: 13+ test cases
  - Valid JSON arrays of floats
  - Integers in JSON
  - Negative numbers
  - Scientific notation
  - Single element arrays
  - Empty arrays
  - NA/NULL/empty string errors
  - Invalid JSON errors
  - Non-numeric arrays errors

- **`parse_parenthesis_floats(paren_str)`**: 12+ test cases
  - Valid parenthesis-enclosed floats
  - Integers
  - Negative numbers
  - Various spacing patterns
  - Single elements
  - Scientific notation
  - Missing parentheses errors
  - NA/NULL/empty errors
  - Non-numeric content errors

### R/database.R
- **`get_raw_data_from_db(filename, limit)`**: 8+ test cases
  - Valid database retrieval
  - Non-existent file errors
  - Limit parameter functionality
  - Invalid limit handling
  - Query error handling gracefully
  - Empty result sets

- **`process_parsed_data(raw_df)`**: 7+ test cases
  - Log column parsing
  - JSON parameter parsing
  - Parenthesis column parsing
  - Multiple log types
  - Error handling with possibly()
  - No log/parameter columns
  - Mixed valid/invalid data

- **`get_data_from_db(filename, limit)`**: 3+ test cases
  - Integration of retrieval and processing
  - Limit parameter propagation
  - Error propagation

### R/preprocessing.R
- **`prepare_varience_data(df)`**: 15+ test cases
  - Parameter column unnesting
  - Log measure column unnesting
  - All four measure types
  - All three log prefixes
  - Column filtering (removing extras)
  - Complete dataset with all columns
  - Multiple rows with nested data
  - Varying nested lengths
  - Single value lists
  - Empty dataframes
  - Missing columns (error handling)
  - Data type preservation
  - NA value handling
  - Integration with process_parsed_data output

## Test Utilities

The `helper-test-utils.R` file provides reusable test fixtures and utilities:

- **`create_comprehensive_test_db(n_rows)`**: Creates a full SQLite test database
- **`create_minimal_test_db()`**: Creates a minimal one-row test database
- **`create_nested_test_df(n_rows, n_nested)`**: Creates test dataframes with nested columns
- **`validate_processed_data_structure(df)`**: Validates dataframe structure
- **`validate_variance_data_structure(df)`**: Validates unnested data structure
- **`generate_log_string(keys, values)`**: Generates sample log strings
- **`cleanup_test_dbs(db_paths)`**: Cleans up temporary database files

## Test Philosophy

The test suite follows these principles:

1. **Comprehensive Coverage**: Tests cover normal cases, edge cases, and error conditions
2. **Isolation**: Each test is independent and doesn't rely on others
3. **Clarity**: Test names clearly describe what is being tested
4. **Maintainability**: Helper utilities reduce duplication
5. **Documentation**: Tests serve as usage examples

## Adding New Tests

When adding new functions to the project:

1. Create a new test file: `tests/testthat/test-yourmodule.R`
2. Follow the naming convention: `test_that("function_name does something", { ... })`
3. Include tests for:
   - Normal/expected behavior
   - Edge cases (empty inputs, single values, large inputs)
   - Error conditions (invalid inputs, type mismatches)
   - Integration with other functions
4. Use helper utilities from `helper-test-utils.R` when appropriate
5. Run the full test suite to ensure no regressions

## Example Test Pattern

```r
test_that("function_name handles valid input correctly", {
  # Arrange
  input <- create_test_input()
  
  # Act
  result <- function_name(input)
  
  # Assert
  expect_type(result, "list")
  expect_equal(result$field, expected_value)
})

test_that("function_name throws error for invalid input", {
  invalid_input <- NA
  
  expect_error(function_name(invalid_input), "expected error message")
})
```

## Continuous Integration

To integrate with CI/CD pipelines:

```bash
# Exit with non-zero status on test failure
Rscript tests/run_unit_tests.R
```

The test runner will return exit code 1 if any tests fail, making it suitable for automated testing.

## Dependencies

Tests require the following R packages:
- `testthat`: Testing framework
- `dplyr`: Data manipulation
- `tidyr`: Data tidying
- `purrr`: Functional programming
- `RSQLite`: SQLite database interface
- `jsonlite`: JSON parsing

All dependencies are loaded via `tests/setup.R`.

## Future Extensions

As the project grows, consider:

1. **Performance Tests**: Benchmark critical functions with large datasets
2. **Integration Tests**: Test complete workflows from database to variance analysis
3. **Property-Based Tests**: Use packages like `hedgehog` for generative testing
4. **Mock Objects**: For more complex database interactions
5. **Code Coverage**: Use `covr` package to track test coverage percentage

## Contributing

When contributing code:
1. Write tests for all new functions
2. Ensure all existing tests pass
3. Add edge case tests
4. Update this README if adding new test utilities or patterns

## Questions or Issues

If you encounter issues with tests:
1. Check that all dependencies are installed
2. Verify R version compatibility (tests developed with R 4.x)
3. Review test output for specific failure details
4. Check that temporary files are being cleaned up properly

For questions about specific tests, refer to the comments in individual test files.

