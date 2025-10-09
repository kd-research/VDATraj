# Unit tests for comprehensive_analysis_setup.R
# Tests comprehensive parameter impact analysis functions

suppressPackageStartupMessages(library(testthat))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(RSQLite))

# Source dependencies if not already loaded (for standalone test runs)
if (!exists("extract_param_index")) {
  # Try to source from tests/setup.R first
  if (file.exists("tests/setup.R")) {
    source("tests/setup.R", chdir = TRUE)
  } else if (file.exists("../../examples/comprehensive_analysis_setup.R")) {
    # If running from tests/testthat directory
    source("../../examples/comprehensive_analysis_setup.R", chdir = TRUE)
  } else {
    # If running from project root
    source("examples/comprehensive_analysis_setup.R", chdir = TRUE)
  }
}

# Helper function to create a minimal test database
create_test_db_for_comprehensive <- function(param_idx = 5, sim_type = "heterogeneous", n = 100) {
  db_path <- tempfile(
    pattern = paste0("cog_", param_idx, "_", sim_type, "_"),
    fileext = ".sqlite3"
  )
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

  # Create benchmark_log table with single 'log' column
  dbExecute(conn, "CREATE TABLE benchmark_log (
    parameter_object_id INTEGER,
    log TEXT
  )")

  # Generate synthetic data
  # Use different seed based on param_idx and sim_type to ensure different data
  seed_val <- param_idx * 1000 + ifelse(sim_type == "heterogeneous", 1, 2)
  set.seed(seed_val)
  for (i in 1:n) {
    # Base parameters (original experiment)
    base_param <- runif(1, 0, 1)
    base_params_json <- paste0("[", paste(rep(base_param, 3), collapse = ","), "]")

    # Truthy parameters (identical to base)
    truthy_params_json <- base_params_json

    # Random parameters (different from base)
    random_param <- runif(1, 0, 1)
    random_params_json <- paste0("[", paste(rep(random_param, 3), collapse = ","), "]")

    # Insert base parameter
    dbExecute(conn, "INSERT INTO parameters (label, parameters) VALUES (?, ?)",
      params = list("budget-ground", base_params_json)
    )
    base_id <- dbGetQuery(conn, "SELECT last_insert_rowid() as id")$id

    # Insert truthy parameter
    dbExecute(conn, "INSERT INTO parameters (label, parameters) VALUES (?, ?)",
      params = list("truthy", truthy_params_json)
    )
    truthy_id <- dbGetQuery(conn, "SELECT last_insert_rowid() as id")$id

    # Insert random parameter
    dbExecute(conn, "INSERT INTO parameters (label, parameters) VALUES (?, ?)",
      params = list("random", random_params_json)
    )
    random_id <- dbGetQuery(conn, "SELECT last_insert_rowid() as id")$id

    # Create parameter relations
    dbExecute(conn, "INSERT INTO parameter_relations (from_id, to_id) VALUES (?, ?)",
      params = list(base_id, truthy_id)
    )
    dbExecute(conn, "INSERT INTO parameter_relations (from_id, to_id) VALUES (?, ?)",
      params = list(base_id, random_id)
    )

    # Generate measurements (with parameter effect)
    # Each measurement has 3 values (replications)
    base_time <- rnorm(3, mean = 10 + 5 * base_param, sd = 2)
    base_collision <- rnorm(3, mean = 20 + 8 * base_param, sd = 3)
    base_distance <- rnorm(3, mean = 30 + 10 * base_param, sd = 4)
    base_energy <- rnorm(3, mean = 40 + 12 * base_param, sd = 5)

    truthy_time <- rnorm(3, mean = 10 + 5 * base_param, sd = 2)
    truthy_collision <- rnorm(3, mean = 20 + 8 * base_param, sd = 3)
    truthy_distance <- rnorm(3, mean = 30 + 10 * base_param, sd = 4)
    truthy_energy <- rnorm(3, mean = 40 + 12 * base_param, sd = 5)

    random_time <- rnorm(3, mean = 10 + 5 * random_param, sd = 2)
    random_collision <- rnorm(3, mean = 20 + 8 * random_param, sd = 3)
    random_distance <- rnorm(3, mean = 30 + 10 * random_param, sd = 4)
    random_energy <- rnorm(3, mean = 40 + 12 * random_param, sd = 5)

    # Format as expected by parsers: header\nkeys\nvalues
    # Values are in tuple format: (v1,v2,v3)
    format_log <- function(time, collision, distance, energy) {
      paste0(
        "header\n",
        "agent_time_enableds collisionTimes agent_distance_traveleds agent_ple_energys\n",
        "(", paste(time, collapse = ","), ") ",
        "(", paste(collision, collapse = ","), ") ",
        "(", paste(distance, collapse = ","), ") ",
        "(", paste(energy, collapse = ","), ")"
      )
    }

    base_log <- format_log(base_time, base_collision, base_distance, base_energy)
    truthy_log <- format_log(truthy_time, truthy_collision, truthy_distance, truthy_energy)
    random_log <- format_log(random_time, random_collision, random_distance, random_energy)

    # Insert logs
    dbExecute(conn, "INSERT INTO benchmark_log (parameter_object_id, log) VALUES (?, ?)",
      params = list(base_id, base_log)
    )
    dbExecute(conn, "INSERT INTO benchmark_log (parameter_object_id, log) VALUES (?, ?)",
      params = list(truthy_id, truthy_log)
    )
    dbExecute(conn, "INSERT INTO benchmark_log (parameter_object_id, log) VALUES (?, ?)",
      params = list(random_id, random_log)
    )
  }

  dbDisconnect(conn)
  return(db_path)
}

# Test 1: extract_param_index extracts parameter index correctly
test_that("extract_param_index extracts parameter index from filename", {
  # Test various filename formats
  expect_equal(extract_param_index("data/cog_2_heterogeneous.sqlite3"), 2)
  expect_equal(extract_param_index("data/cog_5_homogeneous.sqlite3"), 5)
  expect_equal(extract_param_index("data/cog_11_heterogeneous.sqlite3"), 11)
  expect_equal(extract_param_index("cog_8_heterogeneous.sqlite3"), 8)
  expect_equal(extract_param_index("/full/path/to/cog_10_homogeneous.sqlite3"), 10)

  # Test that it returns integer type
  result <- extract_param_index("cog_7_heterogeneous.sqlite3")
  expect_type(result, "integer")
})

# Test 2: extract_sim_type extracts simulation type correctly
test_that("extract_sim_type extracts simulation type from filename", {
  # Test heterogeneous
  expect_equal(extract_sim_type("data/cog_2_heterogeneous.sqlite3"), "heterogeneous")
  expect_equal(extract_sim_type("cog_5_heterogeneous.sqlite3"), "heterogeneous")
  expect_equal(extract_sim_type("/path/to/cog_10_heterogeneous.sqlite3"), "heterogeneous")

  # Test homogeneous
  expect_equal(extract_sim_type("data/cog_3_homogeneous.sqlite3"), "homogeneous")
  expect_equal(extract_sim_type("cog_8_homogeneous.sqlite3"), "homogeneous")
  expect_equal(extract_sim_type("/path/to/cog_11_homogeneous.sqlite3"), "homogeneous")

  # Test unknown case
  expect_equal(extract_sim_type("data/cog_5_invalid.sqlite3"), "unknown")
  expect_equal(extract_sim_type("random_file.sqlite3"), "unknown")

  # Test that it returns character type
  result <- extract_sim_type("cog_7_heterogeneous.sqlite3")
  expect_type(result, "character")
})

# Test 3: analyze_single_dataset returns correct structure
test_that("analyze_single_dataset returns htest object with correct components", {
  # Create a test database
  db_path <- create_test_db_for_comprehensive(param_idx = 5, sim_type = "heterogeneous", n = 100)

  # Run analysis with reduced bootstrap iterations for speed
  result <- analyze_single_dataset(
    db_path = db_path,
    measure_column = "baseLog.agent_time_enableds",
    B = 100,
    conf.level = 0.95
  )

  # Check that result is an htest object
  expect_s3_class(result, "htest")

  # Check that all required components exist
  expect_true("impact" %in% names(result))
  expect_true("var_same" %in% names(result))
  expect_true("var_rand" %in% names(result))
  expect_true("effect_size" %in% names(result))
  expect_true("p.value" %in% names(result))
  expect_true("conf.int" %in% names(result))

  # Check that components are numeric
  expect_type(result$impact, "double")
  expect_type(result$var_same, "double")
  expect_type(result$var_rand, "double")
  expect_type(result$effect_size, "double")
  expect_type(result$p.value, "double")

  # Check confidence interval structure
  expect_length(result$conf.int, 2)
  expect_true(result$conf.int[1] < result$conf.int[2] || is.infinite(result$conf.int[2]))

  # Clean up
  unlink(db_path)
})

# Test 4: analyze_single_dataset detects parameter influence
test_that("analyze_single_dataset detects parameter influence in synthetic data", {
  # Create a test database with known parameter effect
  db_path <- create_test_db_for_comprehensive(param_idx = 8, sim_type = "heterogeneous", n = 200)

  # Run analysis
  result <- analyze_single_dataset(
    db_path = db_path,
    measure_column = "baseLog.agent_time_enableds",
    B = 100,
    conf.level = 0.95
  )

  # With our synthetic data generation (parameter effect = 5 * param),
  # we expect to detect significant parameter influence
  expect_gt(result$impact, 0) # Impact should be positive
  expect_lt(result$p.value, 0.05) # Should be statistically significant
  expect_gt(result$var_rand, result$var_same) # Random var should exceed same var

  # Clean up
  unlink(db_path)
})

# Test 5: analyze_single_dataset handles missing measurement columns
test_that("analyze_single_dataset handles missing columns gracefully", {
  # Create a test database
  db_path <- create_test_db_for_comprehensive(param_idx = 3, sim_type = "homogeneous", n = 50)

  # Try to analyze with non-existent measurement column
  result <- analyze_single_dataset(
    db_path = db_path,
    measure_column = "baseLog.nonexistent_measure",
    B = 100,
    conf.level = 0.95
  )

  # Should return error data frame
  expect_true("error" %in% names(result))
  expect_equal(result$error, "Measurement columns not found")

  # Clean up
  unlink(db_path)
})

# Test 6: analyze_all_parameters returns correct data frame structure
test_that("analyze_all_parameters returns data frame with correct columns", {
  # Create a temporary directory for test databases
  test_dir <- tempfile()
  dir.create(test_dir)

  # Create multiple test databases (simulating parameters 2, 3, 4)
  for (param_idx in c(2, 3, 4)) {
    db_path <- file.path(test_dir, paste0("cog_", param_idx, "_heterogeneous.sqlite3"))
    test_db <- create_test_db_for_comprehensive(param_idx = param_idx, sim_type = "heterogeneous", n = 50)
    file.copy(test_db, db_path)
    unlink(test_db)
  }

  # Run analysis
  result <- analyze_all_parameters(
    sim_type = "heterogeneous",
    measure_column = "baseLog.agent_time_enableds",
    data_dir = test_dir,
    B = 100,
    conf.level = 0.95
  )

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3) # Should have 3 rows (parameters 2, 3, 4)

  # Check column names
  expected_cols <- c("Parameter", "Impact", "Var_Same", "Var_Rand",
                     "Effect_Size", "P_Value", "CI_Lower", "CI_Upper")
  expect_true(all(expected_cols %in% names(result)))

  # Check parameter indices are correct
  expect_equal(sort(result$Parameter), c(2, 3, 4))

  # Check all values are numeric (except Parameter)
  expect_type(result$Impact, "double")
  expect_type(result$Var_Same, "double")
  expect_type(result$Var_Rand, "double")
  expect_type(result$Effect_Size, "double")
  expect_type(result$P_Value, "double")

  # Clean up
  unlink(test_dir, recursive = TRUE)
})

# Test 7: analyze_all_parameters sorts by parameter index
test_that("analyze_all_parameters sorts results by parameter index", {
  # Create a temporary directory for test databases
  test_dir <- tempfile()
  dir.create(test_dir)

  # Create test databases in non-sequential order (5, 2, 8)
  for (param_idx in c(5, 2, 8)) {
    db_path <- file.path(test_dir, paste0("cog_", param_idx, "_homogeneous.sqlite3"))
    test_db <- create_test_db_for_comprehensive(param_idx = param_idx, sim_type = "homogeneous", n = 50)
    file.copy(test_db, db_path)
    unlink(test_db)
  }

  # Run analysis
  result <- analyze_all_parameters(
    sim_type = "homogeneous",
    measure_column = "baseLog.collisionTimes",
    data_dir = test_dir,
    B = 100,
    conf.level = 0.95
  )

  # Check that results are sorted by parameter index
  expect_equal(result$Parameter, c(2, 5, 8))
  expect_true(all(diff(result$Parameter) > 0)) # Should be monotonically increasing

  # Clean up
  unlink(test_dir, recursive = TRUE)
})

# Test 8: analyze_all_parameters filters by simulation type correctly
test_that("analyze_all_parameters filters by simulation type", {
  # Create a temporary directory for test databases
  test_dir <- tempfile()
  dir.create(test_dir)

  # Create databases for both heterogeneous and homogeneous
  for (param_idx in c(2, 3)) {
    # Heterogeneous
    db_path_hetero <- file.path(test_dir, paste0("cog_", param_idx, "_heterogeneous.sqlite3"))
    test_db_hetero <- create_test_db_for_comprehensive(param_idx = param_idx, sim_type = "heterogeneous", n = 50)
    file.copy(test_db_hetero, db_path_hetero)
    unlink(test_db_hetero)

    # Homogeneous
    db_path_homo <- file.path(test_dir, paste0("cog_", param_idx, "_homogeneous.sqlite3"))
    test_db_homo <- create_test_db_for_comprehensive(param_idx = param_idx, sim_type = "homogeneous", n = 50)
    file.copy(test_db_homo, db_path_homo)
    unlink(test_db_homo)
  }

  # Analyze heterogeneous only
  result_hetero <- analyze_all_parameters(
    sim_type = "heterogeneous",
    measure_column = "baseLog.agent_time_enableds",
    data_dir = test_dir,
    B = 100,
    conf.level = 0.95
  )

  # Analyze homogeneous only
  result_homo <- analyze_all_parameters(
    sim_type = "homogeneous",
    measure_column = "baseLog.agent_time_enableds",
    data_dir = test_dir,
    B = 100,
    conf.level = 0.95
  )

  # Both should have 2 parameters
  expect_equal(nrow(result_hetero), 2)
  expect_equal(nrow(result_homo), 2)

  # Both should have same parameter indices
  expect_equal(result_hetero$Parameter, c(2, 3))
  expect_equal(result_homo$Parameter, c(2, 3))

  # Results should be different (different random data)
  expect_false(all(result_hetero$Impact == result_homo$Impact))

  # Clean up
  unlink(test_dir, recursive = TRUE)
})

# Test 9: analyze_all_parameters handles different measurement columns
test_that("analyze_all_parameters works with different measurement columns", {
  # Create a temporary directory for test databases
  test_dir <- tempfile()
  dir.create(test_dir)

  # Create a test database
  db_path <- file.path(test_dir, "cog_5_heterogeneous.sqlite3")
  test_db <- create_test_db_for_comprehensive(param_idx = 5, sim_type = "heterogeneous", n = 100)
  file.copy(test_db, db_path)
  unlink(test_db)

  # Test different measurement columns
  measures <- c(
    "baseLog.agent_time_enableds",
    "baseLog.collisionTimes",
    "baseLog.agent_distance_traveleds",
    "baseLog.agent_ple_energys"
  )

  for (measure in measures) {
    result <- analyze_all_parameters(
      sim_type = "heterogeneous",
      measure_column = measure,
      data_dir = test_dir,
      B = 100,
      conf.level = 0.95
    )

    # Each should return valid results
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 1)
    expect_equal(result$Parameter, 5)

    # Should have positive variances
    expect_gt(result$Var_Same, 0)
    expect_gt(result$Var_Rand, 0)
  }

  # Clean up
  unlink(test_dir, recursive = TRUE)
})

# Test 10: analyze_all_parameters respects confidence level parameter
test_that("analyze_all_parameters respects confidence level", {
  # Create a temporary directory for test databases
  test_dir <- tempfile()
  dir.create(test_dir)

  # Create a test database
  db_path <- file.path(test_dir, "cog_7_homogeneous.sqlite3")
  test_db <- create_test_db_for_comprehensive(param_idx = 7, sim_type = "homogeneous", n = 100)
  file.copy(test_db, db_path)
  unlink(test_db)

  # Test with 90% confidence
  result_90 <- analyze_all_parameters(
    sim_type = "homogeneous",
    measure_column = "baseLog.agent_time_enableds",
    data_dir = test_dir,
    B = 100,
    conf.level = 0.90
  )

  # Test with 99% confidence
  result_99 <- analyze_all_parameters(
    sim_type = "homogeneous",
    measure_column = "baseLog.agent_time_enableds",
    data_dir = test_dir,
    B = 100,
    conf.level = 0.99
  )

  # Both should return valid results
  expect_s3_class(result_90, "data.frame")
  expect_s3_class(result_99, "data.frame")

  # Impact should be the same (point estimate)
  expect_equal(result_90$Impact, result_99$Impact)

  # But confidence intervals should differ
  # 99% CI should be wider than 90% CI
  ci_width_90 <- result_90$CI_Upper - result_90$CI_Lower
  ci_width_99 <- result_99$CI_Upper - result_99$CI_Lower

  # If both are finite, 99% should be wider
  if (is.finite(ci_width_90) && is.finite(ci_width_99)) {
    expect_gt(ci_width_99, ci_width_90)
  }

  # Clean up
  unlink(test_dir, recursive = TRUE)
})

