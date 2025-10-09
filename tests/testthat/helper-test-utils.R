# Test helper utilities
# Provides common test fixtures and utility functions

library(RSQLite)

#' Create a comprehensive test database with multiple rows
#'
#' Creates a SQLite database with realistic test data including
#' multiple parameter sets and corresponding logs
#'
#' @param n_rows Number of base parameter rows to create
#' @return Path to the created temporary database file
create_comprehensive_test_db <- function(n_rows = 3) {
  db_path <- tempfile(fileext = ".sqlite3")
  conn <- dbConnect(RSQLite::SQLite(), db_path)

  # Create schema
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

  # Insert test data for each row
  param_id <- 1
  for (i in 1:n_rows) {
    base_id <- param_id
    truthy_id <- param_id + 1
    random_id <- param_id + 2

    # Generate parameters
    base_params <- sprintf(
      "[%.2f, %.2f, %.2f]",
      runif(1), runif(1), runif(1)
    )
    random_params <- sprintf(
      "[%.2f, %.2f, %.2f]",
      runif(1), runif(1), runif(1)
    )

    # Insert parameters
    dbExecute(conn, "INSERT INTO parameters VALUES (?, 'budget-ground', ?)",
      params = list(base_id, base_params)
    )
    dbExecute(conn, "INSERT INTO parameters VALUES (?, 'truthy', ?)",
      params = list(truthy_id, base_params)
    ) # Same as base
    dbExecute(conn, "INSERT INTO parameters VALUES (?, 'random', ?)",
      params = list(random_id, random_params)
    )

    # Insert relations
    dbExecute(conn, "INSERT INTO parameter_relations VALUES (?, ?)",
      params = list(base_id, truthy_id)
    )
    dbExecute(conn, "INSERT INTO parameter_relations VALUES (?, ?)",
      params = list(base_id, random_id)
    )

    # Generate logs
    generate_log <- function() {
      sprintf(
        "header\nagent_time_enableds collisionTimes agent_distance_traveleds agent_ple_energys\n(%.1f,%.1f,%.1f) (%d,%d,%d) (%.2f,%.2f,%.2f) (%.2f,%.2f,%.2f)",
        runif(1, 10, 30), runif(1, 10, 30), runif(1, 10, 30),
        sample(20:40, 1), sample(20:40, 1), sample(20:40, 1),
        runif(1, 15, 35), runif(1, 15, 35), runif(1, 15, 35),
        runif(1, 60, 80), runif(1, 60, 80), runif(1, 60, 80)
      )
    }

    dbExecute(conn, "INSERT INTO benchmark_log VALUES (?, ?)",
      params = list(base_id, generate_log())
    )
    dbExecute(conn, "INSERT INTO benchmark_log VALUES (?, ?)",
      params = list(truthy_id, generate_log())
    )
    dbExecute(conn, "INSERT INTO benchmark_log VALUES (?, ?)",
      params = list(random_id, generate_log())
    )

    param_id <- param_id + 3
  }

  dbDisconnect(conn)
  return(db_path)
}

#' Create a minimal test database with one complete row
#'
#' @return Path to the created temporary database file
create_minimal_test_db <- function() {
  create_comprehensive_test_db(n_rows = 1)
}

#' Create test dataframe with nested list columns
#'
#' Creates a tibble with the structure expected by prepare_varience_data
#'
#' @param n_rows Number of rows
#' @param n_nested Number of nested values per row
#' @return A tibble with nested parameter and log columns
create_nested_test_df <- function(n_rows = 2, n_nested = 3) {
  df <- tibble::tibble(
    baseParameters = replicate(n_rows, runif(n_nested), simplify = FALSE),
    truthyParameters = replicate(n_rows, runif(n_nested), simplify = FALSE),
    randomParameters = replicate(n_rows, runif(n_nested), simplify = FALSE),
    baseLog.agent_time_enableds = replicate(n_rows, runif(n_nested, 10, 30), simplify = FALSE),
    truthyLog.agent_time_enableds = replicate(n_rows, runif(n_nested, 10, 30), simplify = FALSE),
    randomLog.agent_time_enableds = replicate(n_rows, runif(n_nested, 10, 30), simplify = FALSE),
    baseLog.collisionTimes = replicate(n_rows, sample(20:40, n_nested, replace = TRUE), simplify = FALSE),
    truthyLog.collisionTimes = replicate(n_rows, sample(20:40, n_nested, replace = TRUE), simplify = FALSE),
    randomLog.collisionTimes = replicate(n_rows, sample(20:40, n_nested, replace = TRUE), simplify = FALSE),
    baseLog.agent_distance_traveleds = replicate(n_rows, runif(n_nested, 15, 35), simplify = FALSE),
    truthyLog.agent_distance_traveleds = replicate(n_rows, runif(n_nested, 15, 35), simplify = FALSE),
    randomLog.agent_distance_traveleds = replicate(n_rows, runif(n_nested, 15, 35), simplify = FALSE),
    baseLog.agent_ple_energys = replicate(n_rows, runif(n_nested, 60, 80), simplify = FALSE),
    truthyLog.agent_ple_energys = replicate(n_rows, runif(n_nested, 60, 80), simplify = FALSE),
    randomLog.agent_ple_energys = replicate(n_rows, runif(n_nested, 60, 80), simplify = FALSE)
  )

  return(df)
}

#' Validate structure of processed data
#'
#' Checks that a dataframe has the expected structure from get_data_from_db
#'
#' @param df Dataframe to validate
#' @return TRUE if valid, FALSE otherwise with messages
validate_processed_data_structure <- function(df) {
  expected_param_cols <- c("baseParameters", "truthyParameters", "randomParameters")
  expected_log_prefixes <- c("baseLog", "truthyLog", "randomLog")
  expected_measures <- c(
    "agent_time_enableds", "collisionTimes",
    "agent_distance_traveleds", "agent_ple_energys"
  )

  # Check parameter columns exist
  param_check <- all(expected_param_cols %in% names(df))
  if (!param_check) {
    message("Missing parameter columns")
    return(FALSE)
  }

  # Check that some log columns exist
  log_cols <- grep("Log\\.", names(df), value = TRUE)
  if (length(log_cols) == 0) {
    message("No log columns found")
    return(FALSE)
  }

  return(TRUE)
}

#' Validate structure of variance-ready data
#'
#' Checks that unnested data is ready for variance analysis
#'
#' @param df Dataframe to validate
#' @return TRUE if valid, FALSE otherwise
validate_variance_data_structure <- function(df) {
  # Should be unnested (no list columns)
  list_cols <- sapply(df, is.list)
  if (any(list_cols)) {
    message("Found list columns - data not fully unnested")
    return(FALSE)
  }

  # Should have numeric columns
  numeric_cols <- sapply(df, is.numeric)
  if (!any(numeric_cols)) {
    message("No numeric columns found")
    return(FALSE)
  }

  return(TRUE)
}

#' Generate sample log string for testing
#'
#' @param keys Vector of key names
#' @param values Vector of value strings
#' @return Formatted log string
generate_log_string <- function(keys = c("key1", "key2"),
                                values = c("val1", "val2")) {
  header <- "header line"
  keys_line <- paste(keys, collapse = " ")
  values_line <- paste(values, collapse = " ")
  return(paste(header, keys_line, values_line, sep = "\n"))
}

#' Clean up temporary database files
#'
#' @param db_paths Vector of database file paths to remove
cleanup_test_dbs <- function(db_paths) {
  for (path in db_paths) {
    if (file.exists(path)) {
      unlink(path)
    }
  }
}

